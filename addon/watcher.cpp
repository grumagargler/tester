#include "files.h"
#include "transform.h"
#include <atomic>
#include <cstdint>
#include <nlohmann/json.hpp>
#include <nlohmann/json_fwd.hpp>
#include <optional>
#include <thread>
#include <unordered_map>
#include <unordered_set>
#ifdef __linux__
#include "chars.h"
#include "inotify.h"
#elif _WIN32
#include <filesystem>
#endif
#include "watcher.h"

Watcher::Watcher ()
		: Extender ( L"Watcher" ), Active ( false ), Paused ( false ),
			Thread ( nullptr ) {
	addProcedure ( L"Start", L"Старт", 2,
								 [ & ] ( tVariant* Params ) { return watch ( Params ); } );
	addProcedure ( L"Pause", L"Пауза", 0,
								 [ & ] ( tVariant* Params ) { return pause (); } );
	addProcedure ( L"Resume", L"Продолжать", 0,
								 [ & ] ( tVariant* Params ) { return resume (); } );
	addProcedure ( L"Stop", L"Стоп", 0, [ & ] ( tVariant* Params ) {
		stopWatching ();
		return true;
	} );
	addFunction (
			L"GetChanges", L"ПолучитьИзменения", 0,
			[ & ] ( tVariant*, tVariant* Result ) { return getChanges ( Result ); } );
}

Watcher::~Watcher () {
	stopWatching ();
}

void Watcher::stopWatching () {
	if ( Thread && Active ) {
		deactivate ();
#ifdef __linux__
		Notifier.Stop ();
#elif _WIN32
		CancelIoEx ( FolderID, nullptr );
		CloseHandle ( FolderID );
#endif
		Thread->detach ();
		delete Thread;
		Thread = nullptr;
		files.clear ();
	}
}

bool Watcher::watch ( tVariant* Params ) {
	stopWatching ();
	return startWatching ( Params );
}

bool Watcher::startWatching ( tVariant* Params ) {
	std::wstring folder;
	if ( !readWideString ( Params [ 0 ], folder, "folder" ) ) {
		return false;
	}
	watchingFolder = folder;
	++Params;
	if ( Params->bVal ) {
		Thread = new std::thread ( startObserver, this );
	}
	return true;
}

void Watcher::startObserver ( Watcher* Parent ) {
	Observer resident { Parent };
	resident.Start ();
}

Watcher::Observer::Observer ( Watcher* Parent ) : Parent ( Parent ) {
	Folder = Parent->watchingFolder;
}

void Watcher::Observer::Start () {
#if _WIN32
	Buffer.resize ( watcherBuffer );
	auto folderID = CreateFileW (
			Folder.c_str (), FILE_LIST_DIRECTORY,
			FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
			OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, nullptr );
	if ( folderID == INVALID_HANDLE_VALUE ) {
		Parent->SendError (
				std::system_error ( GetLastError (), std::system_category () )
						.what () );
		return;
	}
	Parent->FolderID = folderID;
#endif
	Parent->activate ();
	observing ();
}

#ifdef __linux__
void Watcher::Observer::observing () const {
	using namespace Inotify;
	EventObserver handler = [ & ] ( const Notification& notification ) {
		if ( Parent->Paused ) {
			return;
		}
		sendMessage ( &notification );
	};
	auto events = { Action::create,
									Action::create | Action::isDir,
									Action::modify,
									Action::modify | Action::isDir,
									Action::remove,
									Action::remove | Action::isDir,
									Action::movedFrom,
									Action::movedFrom | Action::isDir,
									Action::movedTo,
									Action::movedTo | Action::isDir,
									Action::removeSelf | Action::isDir,
									Action::moveSelf | Action::isDir,
									Action::unmount,
									Action::ignored,
									Action::overflow };
	auto& runner = Parent->Notifier;
	try {
		runner.Watch ( Folder );
		runner.Subscribe ( events, handler );
	} catch ( std::exception& E ) {
		Parent->SendError ( E.what () );
	}
	while ( true ) {
		try {
			runner.Go ();
			break;
		} catch ( std::exception& E ) {
			Parent->SendError ( E.what () );
		}
	}
}
#elif _WIN32
void Watcher::Observer::observing () {
	DWORD returned;
	auto data = Buffer.data ();
	auto size = Buffer.size ();
	auto id = Parent->FolderID;
	auto filter = FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_DIR_NAME |
								FILE_NOTIFY_CHANGE_SIZE | FILE_NOTIFY_CHANGE_LAST_WRITE;
	while ( Parent->Active ) {
		if ( ReadDirectoryChangesW ( id, data, size, true, filter, &returned,
																 nullptr, nullptr ) ) {
			if ( !Parent->Paused ) {
				sendMessage ();
			}
		}
	}
}
#endif

#ifdef __linux__
void Watcher::Observer::sendMessage (
		const Inotify::Notification* Notification ) const {
	auto connector = Parent->getBaseConnector ();
	connector->ExternalEvent (
			Parent->getExtensionID (), actionToName ( Notification->Event ),
			Chars::toWchar ( Notification->File.string ().data () ).get () );
}

bool Watcher::Observer::hasEvent ( const Inotify::Action& Source,
																	 const Inotify::Action& Event ) {
	return static_cast<std::uint32_t> ( Event & Source );
}

#elif _WIN32
void Watcher::Observer::sendMessage ( DWORD Offset ) {
	info = reinterpret_cast<FILE_NOTIFY_INFORMATION*> ( &Buffer [ Offset ] );
	File = Folder / std::wstring ( info->FileName, 0,
																 info->FileNameLength / sizeof ( wchar_t ) );
	if ( auto connector = Parent->getBaseConnector () ) {
		connector->ExternalEvent ( Parent->getExtensionID (), actionToName (),
															 Chars::toWchar ( File.c_str () ).get () );
	}
	if ( info->NextEntryOffset )
		sendMessage ( Offset + info->NextEntryOffset );
}
#endif

#ifdef __linux__
const WCHAR_T*
Watcher::Observer::actionToName ( const Inotify::Action& Event ) {
	using namespace Inotify;
	auto directory = hasEvent ( Event, Action::isDir );
	if ( hasEvent ( Event, Action::movedFrom ) )
		return directory ? Actions::FolderRenamedOld : Actions::RenamedOld;
	if ( hasEvent ( Event, Action::movedTo ) )
		return directory ? Actions::FolderRenamedNew : Actions::RenamedNew;
	if ( hasEvent ( Event, Action::create ) )
		return directory ? Actions::FolderAdded : Actions::Added;
	if ( hasEvent ( Event, Action::remove ) )
		return directory ? Actions::FolderRemoved : Actions::Removed;
	if ( hasEvent ( Event, Action::removeSelf ) )
		return Actions::WatcherEntryRemoved;
	if ( hasEvent ( Event, Action::modify ) )
		return directory ? Actions::FolderChanged : Actions::Changed;
	if ( hasEvent ( Event, Action::moveSelf ) )
		return Actions::WatcherEntryMoved;
	if ( hasEvent ( Event, Action::unmount ) )
		return Actions::VolumeUnmounted;
	if ( hasEvent ( Event, Action::overflow ) )
		return Actions::WatcherOverflow;
	if ( hasEvent ( Event, Action::ignored ) )
		return Actions::WatcherDisconnected;
	return nullptr;
}

#elif _WIN32
const WCHAR_T* Watcher::Observer::actionToName () const {
	auto Directory = std::filesystem::is_directory ( File );
	switch ( info->Action ) {
	case 1:
		return Directory ? Actions::FolderAdded : Actions::Added;
	case 2:
		return Directory ? Actions::FolderRemoved : Actions::Removed;
	case 3:
		return Directory ? Actions::FolderChanged : Actions::Changed;
	case 4:
		return Directory ? Actions::FolderRenamedOld : Actions::RenamedOld;
	case 5:
		return Directory ? Actions::FolderRenamedNew : Actions::RenamedNew;
	}
	return nullptr;
}
#endif

bool Watcher::pause () {
	if ( !checkActivity () ) {
		return false;
	}
	Paused = true;
	return true;
}

bool Watcher::checkActivity () {
	if ( Active ) {
		return true;
	}
	SetError ( L"Watcher is not yet started" );
	return false;
}

bool Watcher::resume () {
	if ( !checkActivity () ) {
		return false;
	}
	Paused = false;
	return true;
}

void Watcher::activate () {
	Active = true;
	Paused = false;
}

void Watcher::deactivate () {
	Active = false;
	Paused = false;
}

std::optional<std::pair<uint64_t, uint64_t>>
Watcher::storeInfo ( auto& entry ) {
	const auto& path = entry->path ();
	std::error_code error;
	const auto size = entry->file_size ( error );
	if ( error ) {
		return std::nullopt;
	}
	error.clear ();
	const auto changed = entry->last_write_time ( error );
	if ( error ) {
		return std::nullopt;
	}
	const auto pathText = files::pathToUtf8 ( path );
	const auto id = strings::toHash ( pathText );
	const auto found = files.find ( id );
	const auto newFile = found == files.end ();
	File next = newFile ? File {} : found->second;
	const auto sizeChanged = newFile || next.size != size;
	const auto dateChanged = newFile || next.changed != changed;
	const auto rescan =
			newFile || sizeChanged || dateChanged || changed == previousCheck;
	auto content = next.content;
	auto contentChanged = false;
	if ( rescan ) {
		try {
			content = files::toHash ( path );
		} catch ( ... ) {
			return std::nullopt;
		}
		contentChanged = newFile || content != next.content;
	}
	next.name = pathText;
	next.size = size;
	next.changed = changed;
	next.content = content;
	files [ id ] = next;
	if ( newFile || sizeChanged || contentChanged ) {
		return { { id, content } };
	} else {
		return std::nullopt;
	}
}

bool Watcher::getChanges ( tVariant* Result ) {
	try {
		previousCheck = lastCheck;
		lastCheck = std::filesystem::file_time_type::clock::now ();
		auto changed = nlohmann::json::array ();
		std::error_code error;
		std::filesystem::recursive_directory_iterator entry (
				watchingFolder,
				std::filesystem::directory_options::skip_permission_denied, error );
		if ( error ) {
			SetError ( "Failed to scan folder: " + error.message () );
			return false;
		}
		const std::filesystem::recursive_directory_iterator end;
		for ( ; entry != end; ) {
			const auto& path = entry->path ();

			error.clear ();
			const auto isDirectory = entry->is_directory ( error );
			if ( error ) {
				entry.disable_recursion_pending ();
			} else if ( isDirectory ) {
				if ( path.filename () == ".git" ) {
					entry.disable_recursion_pending ();
				}
			} else if ( path.filename () != ".git" ) {
				error.clear ();
				if ( entry->is_regular_file ( error ) ) {
					if ( auto info = storeInfo ( entry ) ) {
						auto& [ id, content ] = *info;
						changed.push_back ( { { "path", files::pathToUtf8 ( path ) },
																	{ "id", id },
																	{ "content", content } } );
					}
				}
			}
			error.clear ();
			entry.increment ( error );
		}
		returnString ( Result, Chars::stringToWide ( changed.dump () ) );
		return true;
	} catch ( const std::exception& error ) {
		SetError ( error.what () );
		return false;
	} catch ( ... ) {
		SetError ( "Unspecified error" );
		return false;
	}
}

Watcher::Path& Watcher::Path::operator= ( const std::wstring& folder ) {
	path = Chars::wideToPath ( folder );
	return *this;
}

Watcher::Path::operator const std::filesystem::path&() const& {
	return path;
}

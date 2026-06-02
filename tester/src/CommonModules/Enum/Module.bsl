
#region Messages

&atclient
function MessageSaveAll () export
	
	return "1";
	
endfunction 

&atclient
function MessageActivateError () export
	
	return "2";
	
endfunction 

&atclient
function MessageMainScenarioChanged () export
	
	return "3";
	
endfunction 

&atclient
function MessageUserGroupCreated () export
	
	return "4";
	
endfunction 

&atclient
function MessageUserRightsChanged () export
	
	return "5";
	
endfunction 

&atclient
function MessageUserGroupModified () export
	
	return "6";
	
endfunction 

&atclient
function MessageSave () export
	
	return "7";
	
endfunction 

&atclient
function MessageReload () export
	
	return "8";
	
endfunction 

&atclient
function MessageLocked () export
	
	return "9";
	
endfunction 

&atclient
function MessageStored () export
	
	return "10";
	
endfunction 

&atclient
function MessageApplicationSettingsSaved () export
	
	return "11";
	
endfunction 

&atclient
function MessageDebugger () export
	
	return "12";
	
endfunction 

&atclient
function MessageApplicationChanged () export
	
	return "13";
	
endfunction 

&atclient
function MessageRunExternally () export
	
	return "14";
	
endfunction 

#endregion

#region Settings

&atserver
function SettingsShowSettingsButtonState () export
	
	return "ShowSettingsButtonState";
	
endfunction 

function SettingsWorkplaceFilter () export
	
	return "WorkplaceFilter";
	
endfunction 

#endregion

#region Debugger

&atclient
function DebuggerStop () export
	
	return "DebuggerStop";
	
endfunction 

&atclient
function DebuggerContinue () export
	
	return "DebuggerContinue";
	
endfunction 

&atclient
function DebuggerStepInto () export
	
	return "DebuggerStepInto";
	
endfunction 

&atclient
function DebuggerStepOver () export
	
	return "DebuggerStepOver";
	
endfunction 

&atclient
function DebuggerOpenScenario () export
	
	return "DebuggerOpenScenario";
	
endfunction 

&atclient
function DebuggerEval () export
	
	return "DebuggerEval";
	
endfunction 

#endregion

#region ExternalRequests

&atclient
function ExternalRequestsSaveFile () export
	
	return "SaveFile";
	
endfunction 

&atclient
function ExternalRequestsNewFile () export
	
	return "NewFile";
	
endfunction 

&atclient
function ExternalRequestsRenaming () export
	
	return "Renaming";
	
endfunction 

&atclient
function ExternalRequestsRemoving () export
	
	return "Removing";
	
endfunction 

&atclient
function ExternalRequestsRun () export
	
	return "Run";
	
endfunction 

&atclient
function ExternalRequestsCheckSyntax () export
	
	return "CheckSyntax";
	
endfunction 

&atclient
function ExternalRequestsSaveBeforeCheckSyntax () export
	
	return "SaveBeforeCheckSyntax";
	
endfunction 

&atclient
function ExternalRequestsSaveBeforeRun () export
	
	return "SaveBeforeRun";
	
endfunction 

&atclient
function ExternalRequestsSetMain () export
	
	return "SetMain";
	
endfunction 

&atclient
function ExternalRequestsSaveBeforeRunSelected () export
	
	return "SaveBeforeRunSelected";
	
endfunction 

&atclient
function ExternalRequestsRunSelected () export
	
	return "RunSelected";
	
endfunction 

&atclient
function ExternalRequestsSaveBeforeAssigning () export
	
	return "SaveBeforeAssigning";
	
endfunction 

&atclient
function ExternalRequestsPickField () export
	
	return "PickField";
	
endfunction 

&atclient
function ExternalRequestsPickScenario () export
	
	return "PickScenario";
	
endfunction 

&atclient
function ExternalRequestsGenerateID () export
	
	return "GenerateID";
	
endfunction 

#endregion

#region ExternalStatuses

&atclient
function ExternalStatusesCompleted () export
	
	return "Completed";
	
endfunction 

#endregion

#region MessageTypes

&atclient
function MessageTypesInfo () export
	
	return "I";
	
endfunction 

&atclient
function MessageTypesError () export
	
	return "E";
	
endfunction 

&atclient
function MessageTypesWarning () export
	
	return "W";
	
endfunction 

&atclient
function MessageTypesHint () export
	
	return "H";
	
endfunction 

&atclient
function MessageTypesPopup () export
	
	return "P";
	
endfunction 

&atclient
function MessageTypesPopupWarning () export
	
	return "PW";
	
endfunction 

#endregion

#region Framework

&atclient
function FrameworkManagedForm () export
	
	if ( Framework.VersionLess ( "8.3.14" ) ) then
		return "ManagedForm";
	else
		return "ClientApplicationForm";
	endif;
	
endfunction

#endregion

#region Others

&atserver
function OthersVersionPrefix () export
	
	return "v.";
	
endfunction

#endregion

#region ReportCommands

function ReportCommandsOpenModule () export
	
	return "ReportCommandsOpenModule";
	
endfunction

#endregion

#region FSUserActions

&atserver
function FSUserActionsCreate () export
	
	return 1;
	
endfunction

&atserver
function FSUserActionsChange () export
	
	return 2;
	
endfunction

&atserver
function FSUserActionsRename () export
	
	return 3;
	
endfunction

&atserver
function FSUserActionsDelete () export
	
	return 4;
	
endfunction

#endregion

#region ShowMessages

&atclient
function ShowMessagesInParentWindow () export
	
	return 0;

endfunction

&atclient
function ShowMessagesInSeparateWindow () export
	
	return 1;

endfunction

#endregion

#region MCPServerCommands

&atclient
function MCPExecuteScript () export

	return "execute_script";

endfunction

&atclient
function httpServerExecute () export
	
	return MCPExecuteScript ();
	
endfunction

#endregion

#region Constants

function ConstantsFormatVersion () export
	
	return "1.3.4.6";
	
endfunction

&atclient
function ConstantsTableContentLimit () export
	
	return 100;
	
endfunction

&atclient
function ConstantsSavingXMLWaitTime () export

	return 15;

endfunction

&atclient
function ConstantsEntityInfoMark () export

	return "___info___";

endfunction

#endregion

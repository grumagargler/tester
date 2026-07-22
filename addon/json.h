#ifndef __json_h__
#define __json_h__
#include <memory>
#include <string>
#include <vector>

namespace JSON {
const char Hex [ 16 ] = { '0', '1', '2', '3', '4', '5', '6', '7',
													'8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };
std::wstring toHex ( wchar_t Value );
void escape ( std::wstring* Result, const std::wstring& s );

class Value {
public:
	Value () = default;
	explicit Value ( std::wstring Name );
	virtual void Presentation ( std::wstring* Result );

protected:
	std::wstring Name;
};

class [[maybe_unused]] String : public Value {
public:
	using Value::Value;
	void Set ( const std::wstring& Value );
	void Presentation ( std::wstring* Result ) override;

private:
	std::wstring Storage;
};

class [[maybe_unused]] Number : public Value {
public:
	using Value::Value;
	[[maybe_unused]] void Set ( int Value );
	void Presentation ( std::wstring* Result ) override;

private:
	std::wstring Storage;
};

class [[maybe_unused]] Null : public Value {
public:
	using Value::Value;
	void Presentation ( std::wstring* Result ) override;
};

class Container {
public:
	template <class ValueType> ValueType* Add () {
		auto item = new ValueType ();
		Items.push_back ( std::shared_ptr<ValueType> ( item ) );
		return static_cast<ValueType*> ( item );
	}

	template <class ValueType>
	[[maybe_unused]]
	ValueType* Add ( const std::wstring& Name ) {
		auto item = new ValueType ( Name );
		Items.push_back ( std::shared_ptr<ValueType> ( item ) );
		return static_cast<ValueType*> ( item );
	}

	void ItemsPresentation ( std::wstring* Result );

private:
	std::vector<std::shared_ptr<Value>> Items;
};

class [[maybe_unused]] Object : public Value, public Container {
public:
	using Container::Container;
	using Value::Value;
	void Presentation ( std::wstring* Result ) override;
};

class [[maybe_unused]] Array : public Value, public Container {
public:
	using Container::Container;
	using Value::Value;
	void Presentation ( std::wstring* Result ) override;
};

std::string compare ( const std::string& firstJSON, const std::string& secondJSON );
}
#endif

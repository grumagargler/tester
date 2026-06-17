The scenario script code is executed on the client in Thin Client mode. Client-server procedures and functions can be created within scenario code. To interact with the application under test, Tester provides a small number of wrappers over the tested application objects of the 1C:Enterprise 8.3 platform.

# Exported Global Variables

## App

The application under test, a 1C `TestedApplication` object. Can be used by scenario code to call platform methods. When a test starts, this variable is undefined. The variable is set when the [Connect](#connect) method is executed.

Example:

    Connect ();
    window = App.GetActiveWindow ();
    window.Close ();

## AppName

The application ID of the launched test. Can be used by scenario code to identify the configuration being tested.

    if ( AppName = "ERP20" ) then
        Message ( "Testing ERP" );
    endif;

## AppData

A structure of properties for the application under test. It is initialized before launch and is available in the scenario code. It contains the following fields:

| Field                        | Description                                                                                                                                                                                                                                                                                                                                      |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Scenario                     | Reference to the scenario being launched                                                                                                                                                                                                                                                                                                         |
| Application                  | Reference to the application                                                                                                                                                                                                                                                                                                                     |
| Computer                     | Name of the computer where the connection to the application under test is made                                                                                                                                                                                                                                                                  |
| Port                         | Testing client port, taking into account the port that may be specified for a particular session (see [Applications](applications.md))                                                                                                                                                                                                           |
| ClientID                     | Web client identifier, when testing a web client                                                                                                                                                                                                                                                                                                 |
| Connected                    | Boolean flag indicating connection to the application under test                                                                                                                                                                                                                                                                                 |

| Localhost                    | String with the IP address of the local network adapter in case the connection is being proxied                                                                                                                                                                                                                                                  |
| Version                      | String with the platform version, if the connection is being proxied and the version is specified                                                                                                                                                                                                                                                |
| ConnectedHost, ConnectedPort | These fields are populated at the moment of connection to the application under test and contain the actual computer and port values after connecting. These values may differ from the Computer and Port fields when the address and port were passed directly to the [Connect](#connect) method of the running scenario.                         |

## DialogsTitle

The title of the dialog windows of the application under test. Not used by Tester directly, but can be used to develop tests that analyze dialog window titles, such as questions and messages, for example:

    question = App.FindObject ( Type ( "TestedForm" ), DialogsTitle );
    if ( question <> undefined ) then
        Click ( "Yes", question );
    endif;

## MainWindow

The main application window, type TestedClientApplicationWindow.

Can be used by scenario code to call platform methods.

    MainWindow.NavigateToStartPage ();

When a test starts, this variable is undefined.

It is set when the [Connect](#connect) method is executed.

## CurrentSource

An internal variable that specifies the current visual object of the application under test. The variable is used by Tester methods that retrieve values of tested fields, for example [Get](#get), [Fetch](#fetch).

Each value retrieval method has a `Source` parameter in its parameter list. By default, this parameter is `undefined`, which means the CurrentSource variable is used as the source.

The source can be any visual object of the application under test that contains subordinate visual elements within it. Examples: Form, Form Groups, Table.

Setting this variable manually is not recommended. Use the [With](#with) method for such purposes.

## __ (double underscore)

A global user variable that is available to all scenarios. Each scenario developer can use this variable at their own discretion.

## this

A local structure of the scenario scope, passed to the server.

Example:

    this.Insert ( "Product", "Logitech Keyboard" );
    printProduct ();
    
    &AtClient
    Procedure printProduct ()
    
        Message ( this.Product );
    
    EndProcedure
    
## StandardProcessing

A variable that defines the standard behavior of a scenario. The variable is set at the level of each scenario and is automatically set to `true` before each scenario run.

If `StandardProcessing` = `true`, then after each scenario finishes executing, Tester performs the following actions:

1.  Checks for user messages. If there are messages, it is considered that an error has occurred. Tester throws an exception.
2.  Restores the [CurrentSource](#currentsource) that was set before the current scenario was called.

Examples of when it makes sense to set `StandardProcessing` to `false`.

Example 1.

For auxiliary tests that do not perform interactive actions, standard processing can be disabled. In this case, there is a slight speedup in scenario execution.

Example 2.

The tested form displays informational messages to the user. If standard processing is not disabled, upon completion of such a scenario, Tester will consider the testing to have completed with an error.

!!! warning "Attention!"
    `StandardProcessing` = `false` only disables the check for user messages at the end of scenario execution. Handling of other errors (posting errors, write errors, runtime errors, and others) continues even when standard processing is disabled. See the [IgnoreErrors](#ignoreerrors) flag to disable all checks performed by Tester.

## IgnoreErrors

A global flag responsible for checking scenario execution errors. By default, it is set to `false` before the first scenario run.

During the execution of scenario code, Tester implicitly checks for testing errors after every line of code. For example, if the scenario code clicks the `Post` button, Tester will check whether any errors occurred after that action.

    Click ( "Post" );
    // Here Tester will implicitly check for errors

In some scenarios, it is necessary to deliberately test for the presence of an error. For example, a scenario deliberately writes off more product quantity from a warehouse in order to verify that inventory control triggers and a user message is displayed.

In this case, the [IgnoreErrors](#ignoreerrors) flag needs to be set to `true`, post the document, check for error messages, and then set [IgnoreErrors](#ignoreerrors) back to `false`:

    // Disable error checking
    IgnoreErrors = true;
    
    // Post a document with a deliberately erroneous situation
    Click ( "Post" );
    
    // Look for messages: 1) Dialog window 2) Messages directly
    if ( FindMessages ( "Cannot post*" ).Count () = 0 ) then
        Stop ( "<Cannot post*> dialog window should have been shown" );
    endif;
    
    Click ( "OK", Forms.Get1C () ); // Close the standard 1C window
    
    if ( FindMessages ( "Insufficient product * in warehouse *" ).Count () <> 1 ) then
        Stop ( "<" + _ + "> error message should have been shown once" );
    endif;
    
    // Restore error checking
    IgnoreErrors = false;

For more details on the specifics of the `Commando` method when the `IgnoreErrors` = `true` flag is enabled, read [here](#commando)

## SpecialFields

A global structure for defining synonyms of special columns that depend on the configuration language. You can use this structure to set your own values.

This structure is also used in some internal Tester functions for automatic navigation. For example, when activating a table part, Tester analyzes whether the table has an active row, and if not, tries to activate the first row of the table. For such activation, Tester uses the [SpecialFields](#specialfields) structure to determine the name of the row number column. In a Russian configuration this would be `N`, in an English one `#`.

# Methods

## Connect
`Connect ( ClearErrors = true, Port = undefined, Computer = undefined )`

| Parameter   | Type    | Description                                                                                                                                                                                           |
| ----------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ClearErrors | Boolean | Value that specifies whether to close all windows when connecting to the application under test if errors have already occurred at the time of connection (e.g., a previous test has crashed).          |
| Port        | Number  | Port number for connecting to the application under test. If not specified, the port from the [Applications](applications.md) catalog will be used.                                                    |
| Computer    | String  | IP address or network name of the computer where the application under test is running. If not specified, the value from the [Applications](applications.md) catalog will be used.                     |

Connects Tester to the application under test. Connection settings are specified in the [Applications](applications.md) catalog. When connecting, the platform checks for an exact match of the platform version between the manager (where Tester is running) and the application under test. If the versions do not match, the platform will issue a corresponding warning.

After connecting to the application under test, Tester will check the current state of the application, and if it is in an error state, Tester will attempt to close all windows in the application under test. An error state is when the application under test window contains a document posting error, data saving error, or other errors at the time of connection.

If you need to connect to the application without such analysis, the connection method can be called directly:

    Test.ConnectClient ( false );


## Disconnect

`Disconnect ( Close = false )`

| Parameter     | Type    | Description                                                                                                                                                                              |
| ------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Close         | Boolean | If True, the application under test will be closed.                                                                                                                                      |

Disconnects from the application under test.

## CloseAll

`CloseAll ()`

Closes all windows in the application under test. If there are windows with unsaved data, Tester will attempt to answer `No` to any system questions that arise.

If you are testing an application and/or using a platform interface localization language other than Russian or English, for this method to work, you may need to make adjustments at the configuration level in the `Forms.CloseWindows ()` module. The changes involve finding the window with the data save question and the `No` button caption in the localized language.

## Close

`Close ( Form = undefined )`

| Parameter | Type                      | Description                                                                                                                                                        |
| --------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Form      | String \| TestedForm      | A window title or the form itself to be closed can be passed. If the parameter is not specified, the [CurrentSource](#currentsource) will be closed.                |

Closes a form. This method does not analyze the form's modified flag and does not attempt to answer the data save question.

## With

`Object = With ( Name = undefined, Activate = true )`

| Parameter | Type                         | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| --------- | ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Object    | Tested object                | The found object according to the `Name` parameter passed                                                                                                                                                                                                                                                                                                                                                                                                             |
| Name      | String \| Tested object      | If a string is passed, the method will search for objects of the following types: `TestedClientApplicationWindow`, `TestedForm`. The `*` and `?` wildcard characters can be used in the string for pattern matching. If an object is passed, the method will set [CurrentSource](#currentsource) equal to the passed object. If the parameter is omitted, the currently active form will be set as the current source.                                                    |
| Activate  | Boolean                      | If true, the found object will be activated. The parameter can be used to switch between open non-blocking forms.                                                                                                                                                                                                                                                                                                                                                     |

Sets the value of the global variable [CurrentSource](#currentsource) according to the found visual object.

Examples:

    // Tester will search for a form with the title "Products"
    With ( "Products" );
    
    // Call using wildcards
    form = With ( "Customer order (cre*" );

    // Current form
    With ();

## OpenMenu

`OpenMenu ( Path )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Path|String|Path to the object, separated by the `/` character|

Opens a link to an object in the global command interface.

!!! warning "Attention!"
    This method has the following specificity: if the object being opened contains a programming error that occurs before the object's main form opens, such an error cannot be intercepted by Tester and handled programmatically by scenario code (e.g., via try/except). Thus, if you use your own error message interception mechanism in the scenario code, you should use [Commando](#commando) instead of `OpenMenu` to open objects.

Example:

    // Opens the Sales subsystem and "clicks" on Customer Orders
    OpenMenu ( "Sales / Customer Orders" );

## Get

`Object = Get ( Name, Source = undefined, Type = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Object|Tested object|The found tested object according to the provided parameters.|
|Name|String|Identifier or Title of an object. The name can be specified with a `!` or `#` prefix. In this case, the Tester will treat the name as an identifier of the target field. The full path to the target field can be specified in the name.<br/><br/>Examples: `Products / Amount`, or `Additionally / !Code`. <br/><br/>Applies to objects: `Button`, `CommandBar`, `CommandInterface`, `ContextMenu`, `Decoration`, `Field`, `Form`, `Group`, `CIButton`, `CIGroup`, `Table`, `Window`|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|

Returns a tested object.

Examples:

    // Get the Amount field. The field label will be used when searching for the object
    field = Get ( "Amount" );
    
    // Same thing, but the field identifier will be used for the search.
    // This method of getting fields can be used for multilingual configurations
    field = Get ( "!Amount" );
    
    // First the Products object will be found, then the Total field will be found inside it.
    // The "!", "#" prefixes can be used in any part of the expression
    field = Get ( "Products / Total" );
    
    // Returns a spreadsheet document field cell
    field = Get ( "!SpreadsheetDocument [R1C1]" );
    
    // Returns the Quantity field in the second row of the Products table
    table = Activate ( "!Products" );
    field = Get ( "!ProductsQuantity [ 2 ]", table );

## Fetch

`Presentation = Fetch ( Name, Source = undefined, Type = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Presentation|String|String representation of the object value|
|Name|String|Identifier or Title of an object. The name can be specified with a `!` or `#` prefix. In this case, the Tester will treat the name as an identifier of the target field. The full path to the target field can be specified in the name.<br/><br/>Examples: `Products / Amount`, or `Additionally / !Code`. <br/><br/>Applies to objects: `Field`|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|

Returns the string representation of an object's value.

Examples:

    code = Fetch ( "Additional / Code" );
    
    // Returns the value in this cell
    text = Fetch ( "!SpreadsheetDocument [R1C1]" );
    
    // Returns the quantity value in the second row of the Products table.
    // Note! The returned value will be formatted according to
    // the regional settings of the infobase and session
    table = Activate ( "!Products" );
    field = Fetch ( "!ProductsQuantity [ 2 ]", table );

!!! note "Note"
    This method has a behavioral specificity when retrieving cell values from tables of inactive object forms. For more details, see [here](faqtesting.md#fetchdoesnotwork).

## Set

`Object = Set ( Name, Value, Source = undefined, Type = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Object|Tested object|The found tested object according to the provided parameters.|
|Value|String|The value to be set in the field|
|Name|String|Identifier or Title of an object. The name can be specified with a `!` or `#` prefix. In this case, the Tester will treat the name as an identifier of the target field. The full path to the target field can be specified in the name.<br/><br/>Examples: `Products / Amount`, or `Additionally / !Code`. <br/><br/>Applies to objects: `Field`|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|

Activates and sets a value in a field. If the field type is RadioButton, the SelectVariant method will be used. In all other cases, EnterText is used (these are 1C platform methods for working with the tested application).

!!! note "Note"
    When setting values in table fields, you need to consider what mode the table row is in. If the row is not in edit mode, you need to pass the editable table in the `Source` parameter. In this case, Tester will be able to switch the table row to edit mode itself, set the value in the required column, and end edit mode.

Examples:

    // Sets a value in a field
    Set ( "#Comment", "Important comment" );
    
    // Sets quantity in a new table row
    Click ( "!ProductsAdd" );
    Set ( "!ProductsQuantity", 7 );
    
    // Sets quantity in the second row, example 1
    table = Activate ( "!Products" );
    Set ( "!ProductsQuantity [ 2 ]", 15, table );
    
    // Sets quantity in the second row, example 2
    Set ( "!ProductsQuantity [ 2 ]", 15, Get ( "!Products" ) );
    
    // Sets a value in a spreadsheet document cell
    Set ( "!PrintDocument [R1C1]", "Hello world" );

## Put

`Object = Put ( Name, Value, Source = undefined, Type = undefined, CheckValue = false )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Object|Tested object|The found tested object according to the provided parameters.|
|Name|String|Identifier or Title of an object. The name can be specified with a `!` or `#` prefix. In this case, the Tester will treat the name as an identifier of the target field. The full path to the target field can be specified in the name.<br/><br/>Examples: `Products / Amount`, or `Additionally / !Code`. <br/><br/>Applies to objects: `Field`|
|Value|String|The value to be set in the field|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|
|CheckValue|Boolean|Flag that determines whether the set value should be compared against the value passed to this method|

The method works similarly to the [Set](#set) method (see above), with the difference that for reference values, this method will wait for the dropdown list of values suggested by the platform and select the first value from that list, **if it is found there**.

It is important to consider that this method cannot fully verify the correctness of the selected value. For example, with this method you enter a value in a reference field of type DocumentRef. You pass a document number as the value. After the method finishes, the found document will be selected in the field. However, if no such document is found, a value will still be selected in the field — the first one from the list.

Comparing the value displayed in the field with the value passed to the method is not possible in the general case. The presentation of the object selected in the field may differ from the passed parameter. However, if these values can be verified, you can use the `CheckValue` parameter. In this case, the method will check for exact equality between the value selected in the field and the value passed to the method (the `Value` parameter).

In some cases, using this method is the only solution due to the specific behavior of the [Set](#set) method when the focus transitions between a field and a table, or a field in a table row. The specificity is that in some cases, the platform skips the value set by the [Set](#set) method, which leads to unplanned behavior. In such cases, you can use the `Put` method, which will reliably force the platform to select a value in the field.

## EnterValue

`Object = EnterValue ( Name, Value )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Object|Tested object|The found tested object according to the provided parameters.|
|Name|String|Identifier or title of a field in the current form|
|Value|String|The value to enter|

Short form for entering a value in a field of the current form. The method waits for a dropdown choice and checks the resulting value. After calling this method, analyze the window state again, for example with `GetActiveWindowChanges`.

## Clear

`Object = Clear ( Name, Source = undefined, Type = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Object|Tested object|The found tested object according to the provided parameters.|
|Name|String|Identifier or Title of an object. The name can be specified with a `!` or `#` prefix. In this case, the Tester will treat the name as an identifier of the target field. The full path to the target field can be specified in the name.<br/><br/>Examples: `Products / Amount`, or `Additionally / !Code`. <br/><br/>Applies to objects: `Field`|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|

Clears a field.

## Pick

`Object = Pick ( Name, Value, Source = undefined, Type = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Object|Tested object|The found tested object according to the provided parameters.|
|Name|String|Identifier or Title of an object. The name can be specified with a `!` or `#` prefix. In this case, the Tester will treat the name as an identifier of the target field. The full path to the target field can be specified in the name.<br/><br/>Examples: `Products / Amount`, or `Additionally / !Code`. <br/><br/>Applies to objects: `Field`|
|Value|String|The value to be set in the field|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|

Selects a value from a selection list.

Examples:

    table = Activate ( "!Products" );
    Pick ( "!ProductsType [ 2 ]", "Service", table );

## Choose

`Object = Choose ( Name, Source = undefined, Type = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Object|Tested object|The found tested object according to the provided parameters.|
|Name|String|Identifier or Title of an object. The name can be specified with a `!` or `#` prefix. In this case, the Tester will treat the name as an identifier of the target field. The full path to the target field can be specified in the name.<br/><br/>Examples: `Products / Amount`, or `Additionally / !Code`. <br/><br/>Applies to objects: `Field`|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|

Initiates the value selection process in an input field.

Examples:

    // Equivalent to clicking the selection button in the Customer field
    Choose ( "Customer" );
    
    table = Activate ( "!Products" );
    Choose ( "!ProductsProduct [ 3 ]", table );

## Activate

`Object = Activate ( Name, Source = undefined, Type = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Object|Tested object|The found tested object according to the provided parameters.|
|Name|String|Identifier or Title of an object. The name can be specified with a `!` or `#` prefix. In this case, the Tester will treat the name as an identifier of the target field. The full path to the target field can be specified in the name.<br/><br/>Examples: `Products / Amount`, or `Additionally / !Code`. <br/><br/>Applies to objects: `Button`, `CommandBar`, `Decoration`, `Field`, `Form`, `Group`, `Table`, `Window`|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|

Activates a field.

Examples:

    Activate ( "!SpreadsheetDoc [R1C1]" );
    
    table = Activate ( "!Products" );
    Activate ( "!ProductsQuantity [ 2 ]", table );

## Click

`Object = Click ( Name, Source = undefined, Type = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Object|Tested object|The found tested object according to the provided parameters.|
|Name|String|Identifier or Title of an object. The name can be specified with a `!` or `#` prefix. In this case, the Tester will treat the name as an identifier of the target field. The full path to the target field can be specified in the name.<br/><br/>Examples: `Products / Amount`, or `Additionally / !Code`. <br/><br/>Applies to objects: `Button`, `Decoration`, `Field`, `CIButton`|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|

Activates and clicks on a field. Can also be used to click on a hyperlink in a decoration (starting with platform version `8.3.13`) and a collapsible group.

Examples:

    // Click the checkbox if the Product is not a Service
    click = ? ( service, "Yes", "No" ) <> Fetch ( "!IsService" );
    if ( click ) then
        Click ( "!IsService" );
    endif;
    
    // Click in a table part
    table = Activate ( "!Products" );
    Click ( "!ProductsReserve [ 2 ]", table );
    
    // Click on a hyperlink in a decoration
    Click ( "!DocumentBasis" );
    
    // Click on the second hyperlink in a decoration
    Click ( "!Links[2]" );
    
    // Click on a specific hyperlink in a decoration.
    // Note:
    // 1. To click a link by title, you need to use the exact presentation,
    //    wildcard characters are not allowed
    // 2. To correctly pass the caption, slashes are escaped with backslashes
    Click ( "!Links[Goods Receipt №123456 dated 01\/\/01\/2019]" );

## Check

`Check ( Name, Value, Source = undefined, Type = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Name|String|Identifier or Title of an object. The name can be specified with a `!` or `#` prefix. In this case, the Tester will treat the name as an identifier of the target field. The full path to the target field can be specified in the name.<br/><br/>Examples: `Products / Amount`, or `Additionally / !Code`. <br/><br/>Applies to objects: `Field`|
|Value|String \| Number \| Date | Value that will be compared with the value stored in the field being checked.|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|

Compares a field value with the passed value. If the values do not match, an exception will be thrown.

Examples:

    Set ( "Quantity", 3 );
    Set ( "Price", 10 );
    Check ( "Amount", "30.00" );
    
    // In the fifth row of the Accruals table
    Check ( "#Accruals / Result [ 5 ]", 1000 );

## CheckTable

`CheckTable ( Table, Parameters = undefined, Options = undefined, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Table|String| A multiline string of a special format with a table description (see table format below).|
|Parameters|Structure|A structure of parameter values in case of checking a parameterized table.|
|Options|Structure|A structure with comparison settings. Contains one Boolean field `Strictly`. If the field value is `true`, the program will check the identity of the table structures, which includes the column composition and their order.|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|

Compares a text description of a reference table with a tested application field. The tested field can be a table part, a value list presented as a table, a table field, or a dynamic list. If the specified table does not match the tested one, an exception will be thrown. The method has a server-side equivalent that allows checking value tables.

During comparison, the number of rows in the tables is taken into account and must match. If the reference table does not specify rows, the tested table will be checked for the absence of rows. By default, the values of the tested table are checked against the column composition of the reference table. This means that the tested table can have more columns than the reference table, and this will not be considered an error. This approach allows testing only the significant data from the test logic perspective. If you need the tables to match completely, use the `Strictly` flag by passing comparison options as the third parameter of this method.

The check cycle is based on a row-by-row traversal of the compared tables. This process stops at the first difference found between the reference and the tested field, leaving the row and cell of the table that failed the check active in the tested application interface.

### Text Description of the Table

The table description consists of several mandatory parts:

- The first line specifies the name or presentation of the target table being checked. The name can be specified with the `!` or `#` prefix. In this case, Tester will treat the name as the identifier of the target field. The name can include the full path to the target field.
- The second line defines the table columns, where the first column must be the row number column. A comma `,` or pipe `|` is used to separate columns. The column name can be a column header, a column identifier, or a named parameter (wildcard characters `*`, `?` are not supported for column names). An identifier is specified with the `!` or `#` prefix, a parameter is specified with the `%` prefix. For example: `%ParameterName`, where `ParameterName` must be passed as a structure in the second parameter of this method.
- The third and subsequent lines are optional and define the table body. In addition to actual values, named parameters and/or wildcard characters `*`, `?` can also be passed. If a cell value consists of only one parameter, Tester will attempt to convert the tested field value to the type of the parameter. This feature allows testing numeric values without regard to the regional settings of the environment.

!!!tip "Tip"
    Sometimes you need to test tables without headers, or headers with identical names. In this case, instead of the column header text, you can specify its identifier.

Example of defining a simple table:

    reference = "
    |!Materials
    |#, Name, Quantity, Amount
    |1, Marking tag, 250, 8000.00
    |";

!!!note "Note"
    As a rule, the table is formed by reading the reference table directly from the application under test. For this, you can use the field selection feature (which is also available during scenario recording). In this case, the table will be formatted and special characters will be escaped.

If the table header or value contains significant spaces at the edges, such values should be wrapped in single quotes `'`:

    reference = "
    |!Materials
    |#, ' Name '
    |1, ' Marking tag '
    |";

Escaping of special characters `, | \ % ' * ?` is performed with a backslash `\`, for example:

    reference = "
    |!Materials
    |#, \'Name\'
    |1, Marking tag\, steel
    |";

The following example shows the use of parameters and identifiers:

    reference = "
    |!Materials
    |#, !EmployeesFullName, %SalaryColumn
    |1, %FirstName %LastName, %Salary
    |";
    this.Insert ( "SalaryColumn", "Salary" );
    this.Insert ( "Salary", 5000 );
    CheckTable ( reference, this );

!!!tip "Note"
    When passing a parameter, the program will attempt to convert the test value to the type of the passed parameter at the comparison stage. Thus, by passing the salary as the number 5000, the tested value, which will likely be represented as the string `5 000.00`, will be considered equal to the number 5000. In other cases, when values are specified in the table text itself, type conversion does not occur (except when a value table is passed as the tested table, see example below).


The following example demonstrates the ability to compare a reference with a value table:

    checkRegister ();

    &AtServer
    Procedure checkRegister ()

        connector = new COMObject ( "V83.COMConnector" );
        database = "File='C:\Users\Dmitry\Documents\1C\DemoEnterprise20'";
        //database = "Srvr='localhost';Ref='DemoEnterprise20'"; // for a server database
        user = "Administrator (OrlovAV)";
        connection = connector.Connect ( database + ";Usr='" + user + "'" );
        source = connection.NewObject ( "Query" );
        source.Text = "
        |select Records.AmountExclVAT as Amount, Records.VAT as VAT
        |from AccumulationRegister.VATSalesBookRecords as Records
        |where Records.Recorder refs Document.SalesOfGoodsServices
        |and cast ( Records.Recorder as Document.SalesOfGoodsServices ).Number = &Number
        |";
        number = "DS00-000002";
        source.SetParameter ( "Number", number );
        data = source.Execute ().Unload ();
        reference = "
        |!Register
        |# | !Amount    | !VAT
        |1 | 52190     | 9394.2
        |2 | 172271.19 | 31008.81
        |";
        
        // Debug - a service variable for passing the server stack
        // data - obtained data, Tester will convert this COM object
        //          into a value table by itself
        // reference - the reference table, specified values will be
        //          automatically converted to the type of the tested value (number)
        CheckTable ( Debug, data, reference );

    EndProcedure


## CheckState

`CheckState ( Name, Value, Flag = true, Source = undefined, Type = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Name|String|Identifier or Title of an object. The name can be specified with a `!` or `#` prefix. In this case, the Tester will treat the name as an identifier of the target field. The full path to the target field can be specified in the name.<br/><br/>Examples: `Products / Amount`, or `Additionally / !Code`. <br/><br/>Applies to objects: `Button`, `CommandBar`, `Decoration`, `Field`, `Group`, `CIButton`, `CIGroup`, `Table`<br/><br/>Multiple fields can be passed for checking, separated by commas.|
|Value|String|Can take one of the following values: `Visible`, `Enable`, `ReadOnly`|
|Flag|Boolean|Specifies the required state of the value. For example, `Visible` `false` or `true`|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|

Checks the appearance of a field. If the appearance does not match the expected one, an exception will be thrown. 

Examples:

    // The specified fields should be enabled, otherwise, an exception will be thrown
    CheckState ( "Hourly rate, Time, Project amount", "Enable" );
    
    // Checking table columns
    table = Activate ( "!Products" );
    CheckState ( "!ProductsPackageQuantity [2]", "Enable", , table );

    // Currency should not be visible
    CheckState ( "!Currency", "Visible", false );

## CheckErrors

`CheckErrors ()`

Checks for messages. If messages are present, Tester will throw an exception.

## Stop

`Stop ( Reason = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Reason|String|Text description of the reason for stopping the scenario|

Terminates scenario execution.

## Waiting

`Result = Waiting ( Name, Timeout = 3, Type = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Result|Boolean|`true` if the object appeared, `false` otherwise|
|Name|String|Form title. The `*` and `?` wildcard characters can be used in the string for pattern matching.<br/><br/>Applies to objects: `Form`, `Window`|
|Timeout|Number|Time in seconds during which Tester will wait for the requested object to appear|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|

Pauses scenario execution until the requested object appears, for example — a window.

Examples:

    if ( not Waiting ( "Wizard*" ) ) then
        Stop ( "The wizard window should have appeared" );
    endif;

## GetWindow

`Window = GetWindow ( Form = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Window|TestedClientApplicationWindow|The tested client application window|
|Form|TestedForm|If the value is not specified, an attempt will be made to get the window for the [CurrentSource](#currentsource) value|

Returns an object of type `TestedClientApplicationWindow` for the passed or current form.

Examples:

    form = With ( "Clients" );
    window = GetWindow ();
    window.Close ();

## FindForm

`Form = FindForm ( Name )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Form|TestedForm|The tested form|
|Name|String|Form title. The `*` and `?` wildcard characters can be used in the string for pattern matching.<br/><br/>Applies to objects: `Form`|

Finds and returns a form by the passed title. Unlike the [With](#with) method, this function does not set [CurrentSource](#currentsource).

Examples:

    form = FindForm ( "Important information" );
    Click ( "OK", form );
    
    // Also, a shorter notation is possible; in this case, FindForm will be called implicitly:
    Click ( "OK", "Important information" );

## GetLinks

`Links = GetLinks ( Form = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Links|TestedWindowCommandInterface|The tested window command interface|
|Form|TestedForm|If the value is not specified, an attempt will be made to get the window for the [CurrentSource](#currentsource) value|

Returns the form's command interface.

Examples:

    MainWindow.ExecuteCommand ( "e1cib/command/Catalog.Partners.Create" );
    
    form = With ( "Partner (cre*" );
    Set ( "!FullCompanyName", "Test partner" );
    Click ( "Supplier" );
    Set ( "!AccessGroup", "Suppliers" );
    Click ( "!FormWrite" );
    
    // Creating a counterparty
    Click ( "Counterparties", GetLinks () ); // Example of method usage
    With ( "Counterparties*" );

## GetActiveWindowControls

`controls = GetActiveWindowControls ()`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|controls|Structure|Hierarchical structure of visual controls from the active window|

Returns a tree of controls from only the active window of the tested application. The top-level result is usually the form structure. Elements contain the standard fields `Type`, `Name`, `TitleText`; child controls are stored in `Items`, and table columns are stored in `Columns`.

When tested-client data and form metadata are available, elements can also contain `ToolTip`, `DataType`, `Value`, `Mandatory`, `ReadOnly`, `InputHint`, `WarningOnEdit`, `DropList`, `Rows`, `RowCount`, `CurrentRowData`, `CurrentColumn`, `TableIsTree`, `TableIsHierarchicalList`, and other form state fields.

Example:

    controls = GetActiveWindowControls ();
    return controls;

## GetActiveWindowChanges

`changes = GetActiveWindowChanges ()`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|changes|Structure|Changes in active-window controls since the previous snapshot|

Returns active-window changes after the previous `GetActiveWindowControls` or `GetActiveWindowChanges` call. If this is the first snapshot or the active form changed completely, returns the full control tree. The element format is the same as in `GetActiveWindowControls`.

Example:

    Click ( "#FormCreate" );
    return GetActiveWindowChanges ();

## GetMainMenu

`menu = GetMainMenu ()`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|menu|Array|List of subsystems and commands from the main menu|

Returns the main menu structure as an array of subsystems. Each subsystem element contains the `Subsystem` field and the `Items` array.

!!! note "Note"
    For this method to work, the Sections panel must be enabled in the application command interface.

Example:

    menu = GetMainMenu ();
    return menu;

## GetTableContent

`data = GetTableContent ( Name, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|data|Array|Rows of the active form table|
|Name|String|Identifier or title of a table|
|Source|String \| TestedObject|String with the form title or the form object itself. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|

Returns the visible table content as an array of structures. If the table is too large, filter it first or export it to a spreadsheet document.

## GetSpreadsheetContent

`file = GetSpreadsheetContent ( Name, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|file|String|Path to a temporary xlsx file|
|Name|String|Identifier or title of a spreadsheet document field|
|Source|String \| TestedObject|String with the form title or the form object itself. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|

Saves a spreadsheet document to a temporary xlsx file and returns its path. The method is unavailable in the web client.

## GetMessages

`Messages = GetMessages ()`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Messages|FixedArray|Array of found messages|

Returns a fixed array of messages from the active window. The method can be used for message analysis.

Example:

    Click ( "!FormPost" );
    if ( GetMessages ().Count () = 0 ) then
        Stop ( "An error message was expected" );
    endif;

## FindMessages

`Messages = FindMessages ( Pattern )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Messages|Array|Array of found messages|
|Pattern|String|Message text to be found. Regular expressions can be used in the string. The use of `*` and `?` characters has a slight deviation from standard regular expression rules. These characters will be transformed into `[\s\S\]+` and `[\s\S\]` respectively. For additional information on regular expressions, see [http://userguide.icu-project.org/strings/regexp](http://userguide.icu-project.org/strings/regexp) 

Returns an array of found messages.

Examples:

    if ( FindMessages ( "Cannot post*" ).Count () = 0 ) then
        Stop ( "<Cannot post*> dialog window should have been shown" );
    endif;
    
    Click ( "OK", Forms.Get1C () ); // Close the standard 1C window
    
    if ( FindMessages ( "Write-off quantity exceeds *" ).Count () <> 1 ) then
        Stop ( "Error message should have been shown once" );
    endif;

## Pause

`Pause ( Seconds )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Seconds|Number|Number of seconds|

Pauses the scenario execution process for the specified number of seconds.

Example:

    Pause ( 5 ); // The system will wait here for 5 seconds

## CurrentTab

`CurrentTab ( Name, Source = undefined, Type = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Name|String|Identifier or Title of an object. The name can be specified with a `!` or `#` prefix. In this case, the Tester will treat the name as an identifier of the target field. The full path to the target field can be specified in the name.<br/><br/>Examples: `Products / Amount`, or `Additionally / !Code`. <br/><br/>Applies to objects: `Group`|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|
|Type|String|Filter by type. The following string values are available: `Field` (`Field`), `Group` (`Group`), `Button` (`Button`), `Table` (`Table`), `Decoration` (`Decoration`)<br/><br/>If the type is not specified, no type filter will be applied.|

Example:

    // Get the title of the current tab
    CurrentTab ( "!GroupPages" ).TitleText;

## Next

`Next ()`

Navigates to the next field according to the element layout.

## GotoRow
`Navigated = GotoRow ( Table, Column, Value, FromBeginning = true, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Navigated|Boolean|Navigation result|
|Table|String \| TestedFormTable|Identifier, title, or object of the table. The name can be specified with the `!` or `#` prefix. In this case, Tester will treat the name as the identifier of the target field. The name can include the full path to the target field. Examples: `GroupProducts / Products`, or `Additional / !ItemTable`|
|Column|String| String with the column name (**not identifier**) where the value search for navigation will be performed|
|Value|String|The value to search for in the specified column. The value must **fully match** the target; you cannot specify only part of the search string or use wildcard characters.|
|FromBeginning|Boolean|Value that specifies the search starting point. By default, the value is `true`. This means the method will first move to the beginning of the table and only then start searching. If `false` is passed, the search will start from the current table row.|
|Source|String \| TestedObject|String with the form title or the form object itself. The characters `*` and `?` can be used in the string for pattern matching. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|

Navigates to a table row. The method is **not intended for searching rows**; it is intended for navigating to the desired row.

Extra attention should be paid when using this method for navigation through rows of linked tables. The specificity is that if the second table is linked to the first through a wait handler, the rows in the second table may appear later than when the `GotoRow` method finishes, which will lead to an error and the test stopping. To avoid such situations, use the [Pause](#pause) method before navigating to the linked table.

Examples:

    With ( "Purchase order *" );
    
    // Will navigate to the third row of the Products table part
    // (if there are at least three rows)
    GotoRow ( "!Products", "N", 3 );
    
    // Navigation through linked table rows
    With ( "Internal documents" );
    GotoRow ( "!Folders", "Name", "Memos" );
    Pause ( 1 );
    GotoRow ( "!List", "Name", "On allocating a personal telephone set" );

## GotoFirstRow

`GotoFirstRow ( Table, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Table|String \| TestedFormTable|Identifier, title, or object of the table|
|Source|String \| TestedObject|String with the form title or the form object itself. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|

Navigates to the first table row.

## GotoLastRow

`GotoLastRow ( Table, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Table|String \| TestedFormTable|Identifier, title, or object of the table|
|Source|String \| TestedObject|String with the form title or the form object itself. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|

Navigates to the last table row.

## GotoNextRow

`GotoNextRow ( Table, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Table|String \| TestedFormTable|Identifier, title, or object of the table|
|Source|String \| TestedObject|String with the form title or the form object itself. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|

Navigates to the next table row. Throws an exception if navigation is impossible.

## GotoPreviousRow

`GotoPreviousRow ( Table, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Table|String \| TestedFormTable|Identifier, title, or object of the table|
|Source|String \| TestedObject|String with the form title or the form object itself. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|

Navigates to the previous table row. Throws an exception if navigation is impossible.

## ExpandTreeRow

`ExpandTreeRow ( Table, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Table|String \| TestedFormTable|Identifier, title, or object of a tree table|
|Source|String \| TestedObject|String with the form title or the form object itself. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|

Expands the current tree-table row without changing the current row.

## CollapseTreeRow

`CollapseTreeRow ( Table, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Table|String \| TestedFormTable|Identifier, title, or object of a tree table|
|Source|String \| TestedObject|String with the form title or the form object itself. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|

Collapses the current tree-table row without changing the current row.

## GoOneLevelDown

`GoOneLevelDown ( Table, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Table|String \| TestedFormTable|Identifier, title, or object of a hierarchical table|
|Source|String \| TestedObject|String with the form title or the form object itself. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|

Goes one level down from the current row of a hierarchical list or tree table.

## GoOneLevelUp

`GoOneLevelUp ( Table, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Table|String \| TestedFormTable|Identifier, title, or object of a hierarchical table|
|Source|String \| TestedObject|String with the form title or the form object itself. If no value is specified, the global variable [CurrentObject](#currentsource) will be used as the source.|

Goes one level up in a hierarchical list or tree table.

## OpenValueInInputField

`Object = OpenValueInInputField ( Name, Source = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Object|Tested object|The opened form, set as [CurrentSource](#currentsource)|
|Name|String|Identifier or title of the input field. The name can use the `!` or `#` prefix to search by field identifier. A full path to the field can be specified.|
|Source|String \| TestedObject|String with the form title or the form object itself. If no value is specified, the global variable [CurrentSource](#currentsource) will be used as the source.|

Opens the value stored in an input field using the standard platform action and sets the opened form as current. This method is applicable only to input fields. If the found control is not an input field, it throws an exception.

## Commando

`Object = Commando ( Action, Activate = true )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Object|TestedForm|The opened form after navigating via the navigation link|
|Action|String|Navigation link|
|Activate|Boolean|Flag responsible for automatically setting the opened form as the current one|

Executes a system navigation command using the passed string parameter.

> Starting with version `1.3.3.1`, the method also sets the opened form as current. Thus, the call to the With method can be omitted if it is performed immediately after executing the navigation command.

If the `Activate` flag = `true`, the method, after navigating to the specified navigation link, calls the [With](#with) method. It is important to consider the specifics of the method's behavior when using the [IgnoreErrors](#ignoreerrors) flag = true. The specificity is that in case of an unsuccessful navigation (for example, the navigation link in the Action parameter is incorrect, or an error occurs during the object form opening), the platform generates an exception as a modal dialog. At the same time, Tester cannot determine whether this window is the target object form or the result of an opening exception. In any case, if the Activate parameter = true, Tester attempts to activate the displayed window, and if it is an error window, a system exception "Object cannot be found" (1C:Enterprise) is generated, which can cause confusion during problem analysis. Therefore, if you need to set the [IgnoreErrors](#ignoreerrors) flag = true, you should consider setting the Activate parameter to `false` (and accordingly you will need to call the [With](#with) method yourself).

Examples:

    // Opens the standard list form
    Commando ( "e1cib/list/Catalog.Products" );
    
    // Opens the standard new object form
    Commando ( "e1cib/command/Catalog.Products.Create" );
    
    // Opens a non-parameterized catalog command
    Commando ( "e1cib/command/Catalog.Products.Command.NewItem" );
    
    // Opens a report
    Commando ( "e1cib/app/Report.InventoryBalance" );
    
    // Opens a data processor
    Commando ( "e1cib/app/DataProcessor.MyDataProcessorName" );
    
    // Opens a common command
    Commando ( "e1cib/command/CommonCommand.PurchaseReportsPanel" );
    
    // Opens a common form
    Commando ( "e1cib/data/CommonForm.Settings" ); // Note: if an error occurs when opening the form, it cannot be handled by Tester
    
    // Opens a document journal
    Commando ( "e1cib/list/DocumentJournal.GoodsTransfersReturnsBetweenOrganizations" );

## Call

`Result = Call ( Scenario, Parameters = undefined, Application = undefined )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Result|Any|The return value of the called scenario|
|Scenario|String|The full path to the scenario to be executed (each scenario in the system has a unique path within the application).|
|Parameters|Any|Value that will be passed to the called scenario. The called scenario can access the passed parameters via the `_` variable. A string in JSON format is also accepted as a parameter. In this case, the string will be converted to a structure and the called scenario will receive the parameter structure in the `_` variable.|
|Application|String|The application name for searching the scenario to be executed. If the name is not specified, the scenario search will be performed in the scenario set of the application that called the scenario. If the scenario is not found, the search will continue in the application set as default in the environment settings of the current user. If the scenario is still not found, an attempt will be made to search for the scenario in the global scenario set, for which no application is specified. If the scenario is not found, the Tester will throw an exception.|

Launches a scenario for execution.

Example:

    // Example 1
    Call ( "Common.OpenList", Meta.Catalogs.Products );
    
    // Example 2
    p = new Structure ();
    p.Insert ( "Product", "Bushing" );
    p.Insert ( "Price", "150" );
    Call ( "MyTest", p );
    
    // In the body of MyTest, access to passed parameters is through _
    Message ( _.Product ); // Bushing
    
    // Example 3. Same as Example 2, but via a JSON string
    Call ( "MyTest", "{'Product': 'Bushing', 'Price': '150'}" );
    
    // In the body of MyTest, access to passed parameters is through _
    Message ( _.Product ); // Bushing
    
## Run

`Result = Run ( Scenario, Parameters = undefined, Application = undefined )`

Launches a scenario in the current scenario folder. The method is analogous to the [Call](#call) method, with the difference that the scenario search will be performed starting from the folder where the calling scenario is located. Thus, the Run method is a shorthand for the [Call](#call) method.

Example:

    // Full path
    Call ( "Catalog.Products.Create.Parameters" );

    // Will work if the calling test is inside "Catalog.Products"
    Run ( "Create.Parameters" );

## RunTest

`RunTest ( Scenario, Application = undefined, IgnoreLocked = false )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Scenario|String|The full path to the scenario to be executed (each scenario in the system has a unique path within the application).|
|Application|String|The application name for searching the scenario to be executed. If the name is not specified, the scenario search will be performed in the scenario set of the application that called the scenario. If the scenario is not found, the search will continue in the application set as default in the environment settings of the current user. If the scenario is still not found, an attempt will be made to search for the scenario in the global scenario set, for which no application is specified. If the scenario is not found, the Tester will throw an exception.|
|IgnoreLocked|Boolean|If the scenario being launched is locked by another user, then by default, Tester will execute the latest version of the scenario. If `IgnoreLocked = true`, then the locked scenario will be executed.|

Launches a scenario for execution. Unlike the [Call](#call) and [Run](#run) methods, this method launches the scenario with full initialization of the environment and global variables. The method works the same way as if the user manually launched the selected scenario in the scenario tree.

The method can be used for running tests on a schedule or launching a group of unrelated tests.

Example:

    RunTest ( "Invoice.Create" );
    RunTest ( "Invoice.Post" );

## LogError

`LogError ( Text )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Text|String|Error text|

Adds a message to the error log from the scenario code without stopping scenario execution.

Example:

    try
        Call ( "SomeTest", p );
    except
        error = ErrorDescription ();
        LogError ( error );
    endtry;

## RegisterEnvironment

`RegisterEnvironment ( ID )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|ID|String|Environment identifier|

Saves the test environment identifier in the Tester's internal database. For more details on the approach to organizing the test environment, see the [Scenario Structure](implementation.md#TestStructure) section.

## EnvironmentExists

`Exists = EnvironmentExists ( ID )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|ID|String|Environment identifier|

Checks for the existence of a previously created test environment by the passed identifier. For more details on the approach to organizing the test environment, see the [Scenario Structure](implementation.md#TestStructure) section.

## MaximizeWindow

`MaximizeWindow ( Title = "" )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Title|String|A regular expression for searching the main window of the tested application. If the parameter is not specified, the Tester will search for the application by the title specified in the tested application's profile.|

Maximizes an application window by the passed title. The method's operation may depend on access rights to the process of the handled window. If the window maximization method does not work, try restarting Tester with administrator privileges.

## MinimizeWindow

`MinimizeWindow ( Title = "" )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Title|String|A regular expression for searching the main window of the tested application. If the parameter is not specified, the Tester will search for the application by the title specified in the tested application's profile.|

Minimizes an application window by the passed title. The method's operation may depend on access rights to the process of the handled window. If the window minimization method does not work, try restarting Tester with administrator privileges.

## SystemVariable

`Value = SystemVariable ( Name )`

| Parameter | Type | Value |
| --------- | ---- | ----- |
|Value|String|Variable value|
|Name|String|Name of the requested environment parameter|

The function returns the value of a system environment parameter.

Example:

    folder = SystemVariable ( "USERPROFILE" );
    Message ( folder );

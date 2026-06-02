#if ( not webclient ) then

procedure Init () export

	settings = MCPServerSrv.Settings ();
	if ( settings = undefined ) then
		return;
	elsif ( not settings.EditScenarios ) then
		Output.MCPServerWrongAccess ();
	endif;
	MCPD = new ( "AddIn.Extender.MCPServer" );
	try
		MCPD.Start ( settings.Address, Number ( settings.Port ) );
	except
		Output.MCPServerError ( new Structure ( "Server, Error",
			"" + settings.Address + ":" + settings.Port, MCPD.Problem () ) );
	endtry;

endprocedure

procedure Proceed ( Request ) export
	
	requestID = undefined;
	toolName = "";
	try
		params = prepareParams ( Request, requestID, toolName );
	except
		sendProtocolError ( requestID,
			ErrorProcessing.BriefErrorDescription ( ErrorInfo () ), -32600 );
		return;
	endtry;
	if ( toolName = Enum.MCPExecuteScript () ) then
		try
			RepositoryFiles.Sync ( new CallbackDescription ( "RunScenario", ThisObject, params ) );
		except
			sendProtocolError ( requestID,
				ErrorProcessing.BriefErrorDescription ( ErrorInfo () ), -32601 );
		endtry;
	else
		sendProtocolError ( requestID, Output.WrongCommand ( new Structure ( "Tool, List",
			toolName, toolList () ) ), -32601 );
	endif;
	
endprocedure

function prepareParams ( Request, RequestID, ToolName )

	params = Conversion.FromJSON ( Request );
	if ( params = undefined ) then
		raise Output.WrongRequest ();
	endif;
	if ( not Params.Property ( "id", RequestID )
		or not Params.Property ( "name", ToolName )
		or not ValueIsFilled ( ToolName ) ) then
		raise Output.WrongRequest ();
	endif;
	return params;

endfunction

procedure sendProtocolError ( RequestID, Message, Code )

	error = new Structure ( "code, message", Code, Message );
	reply = new Structure ( "id, error", ? ( RequestID = undefined, "<absent>", RequestID ), error );
	sendReply ( reply );
	
endprocedure

procedure sendToolError ( RequestID, Message, ExtraContent = undefined )

	content = new Structure ( "success, error", false, Message );
	if ( ExtraContent <> undefined ) then
		for each item in ExtraContent do
			content.Insert ( item.Key, item.Value );
		enddo;
	endif;
	sendToolResult ( RequestID, content, true );

endprocedure

procedure sendToolResult ( RequestID, Content, IsError = false )

	result = new Structure ( "content", buildResultContent ( Content, IsError ) );
	if ( Content <> undefined ) then
		result.Insert ( "structuredContent", Content );
	endif;
	if ( IsError ) then
		result.Insert ( "isError", true );
	endif;
	sendReply ( new Structure ( "id, result", RequestID, result ) );
	
endprocedure

procedure sendReply ( Reply )

	result = Conversion.ToJSON ( Reply, false );
	try
		MCPD.Send ( result );
	except
		Message ( MCPD.Problem () );
	endtry
	
endprocedure

function buildResultContent ( StructuredContent, IsError )

	text = ? ( IsError, errorText ( StructuredContent ), resultText ( StructuredContent ) );
	content = new Array ();
	content.Add ( new Structure ( "type, text", "text", text ) );
	return content;

endfunction

function resultText ( StructuredContent )

	if ( StructuredContent = undefined ) then
		return "";
	endif;
	if ( StructuredContent.Count () = 1
		and StructuredContent.Property ( "success" ) ) then
		return "Scenario executed successfully";
	endif;
	return Conversion.ToJSON ( StructuredContent, false );

endfunction

function errorText ( StructuredContent )

	message = "";
	if ( StructuredContent <> undefined
		and StructuredContent.Property ( "error", message )
		and ValueIsFilled ( message ) ) then
		return message;
	endif;
	return Conversion.ToJSON ( StructuredContent, false );

endfunction

function toolList ()

	list = new Array ();
	list.Add ( Enum.MCPExecuteScript () );
	return StrConcat ( list, ", " );

endfunction

procedure RunScenario ( Result, Params ) export
	
	Watcher.FetchChanges ();
	requestID = Params.id;
	LastScenarioReturn = undefined;
	file = undefined;
	args = prepareArguments ( Params );
	if ( not args.Property ( "script_path", file )
		or not ValueIsFilled ( file ) ) then
		sendToolError ( requestID, Output.SrenarioNotProvided () );
		return;
	endif;
	scenario = findScenario ( requestID, file );
	if ( scenario = undefined ) then
		return;
	endif;
	TesterServerMode = true;
	MCPRequestProcessing = true;
	try
		Test.Exec ( Scenario );
	except
	endtry;
	messages = Watcher.FlushServerMessages ();
	TesterServerMode = false;
	MCPRequestProcessing = false;
	failed = hasRuntimeErrors ( messages );
	content = new Structure ( "success", not failed );
	for each item in messages do
		content.Insert ( item.Key, item.Value );
	enddo;
	if ( LastScenarioReturn <> undefined ) then
		content.Insert ( "script_return_value", LastScenarioReturn.Result );
	endif;
	sendToolResult ( requestID, content, failed );

endprocedure

function prepareArguments ( Params )

	args = undefined;
	if ( not Params.Property ( "args", args )
		or args = undefined ) then
		return new Structure ();
	endif;
	return args;

endfunction

function hasRuntimeErrors ( Messages )

	runtimeMessages = undefined;
	if ( not Messages.Property ( "runtime_messages", runtimeMessages )
		or runtimeMessages = undefined ) then
		return false;
	endif;
	for each message in runtimeMessages do
		if ( message.Severity = "Error" ) then
			return true;
		endif;
	enddo;
	return false;

endfunction

function findScenario ( RequestID, File )
	
	if ( FileSystem.Extension ( File ) <> RepositoryFiles.BSLFile () ) then
		sendToolError ( RequestID, Output.WrongScenarioExtension (
			new Structure ( "Path", File ) ), new Structure ( "script_path", File ) );
		return undefined;
	endif;
	TesterExternalRequestsApplication = Watcher.FindApplication ( File );
	if ( TesterExternalRequestsApplication = undefined ) then
		sendToolError ( RequestID, Output.RequestedScenarioNotMapped (
			new Structure ( "File", File ) ), new Structure ( "script_path", File ) );
		return undefined;
	endif;
	context = Watcher.SyncingContext ( File, true );
	scenario = WatcherSrv.FindScenario ( context );
	if ( scenario = undefined ) then
		sendToolError ( RequestID, Output.RequestedScriptNotFound (
			new Structure ( "File", File ) ), new Structure ( "script_path", File ) );
		return undefined;
	endif;
	return scenario;

endfunction

#endif


function Sformat ( Str, Params ) export
	
	if ( Params = undefined
		or StrFind ( Str, "%" ) = 0 ) then
		return Str;
	endif; 
	result = Str;
	p = new Array ();
	for each parameter in Params do
		p.Add ( parameter.Key );
	enddo;
	indexOfMax = 0;
	while ( true ) do
		i = 0;
		max = 0;
		for each param in p do
			a = StrLen ( param );
			if ( a > max ) then
				max = a;
				indexOfMax = i;
			endif; 
			i = i + 1;
		enddo;
		k = p [ indexOfMax ];
		p.Delete ( indexOfMax );
		result = StrReplace ( result, "%" + k, Params [ k ] );
		if ( p.UBound () = -1 ) then
			break;
		endif; 
	enddo; 
	return result;
	
endfunction

procedure PutMessage ( Text, Params, Field, DataKey, DataPath, Form = undefined ) export
	
	msg = new UserMessage ();
	s = Output.Sformat ( Text, Params );
	interactive = ( Params = undefined  ) or not Params.Property ( "_Interactive" ) or Params._Interactive;
	if ( interactive ) then
		msg.DataPath = DataPath;
		msg.Field = Field;
		msg.DataKey = DataKey;
	else
		prefix = new Array ();
		if ( ValueIsFilled ( DataKey ) ) then
			prefix.Add ( String ( DataKey ) );
			table = getTable ( Field );
			if ( table <> undefined ) then
				name = DataKey.Metadata ().TabularSections [ table.Name ].Presentation ();
				prefix.Add ( Output.TableAndRow ( new Structure ( "Table, Row", name, table.Row ) ) );
			endif; 
		endif; 
		if ( prefix.Count () > 0 ) then
			s = StrConcat ( prefix, ", " ) + ": " + s;
		endif; 
	endif;
	if ( Form <> undefined ) then
		msg.TargetID = Form; 
	endif;
	msg.Text = s;
	msg.Message ();
	
endprocedure

&atclient
procedure openMessageBox ( Text, Params, ProcName, Module, CallbackParams, Timeout, Title )
	
	if ( Module = undefined ) then
		handler = undefined;
	else
		handler = new NotifyDescription ( ProcName, Module, CallbackParams );
	endif; 
	if ( handler = undefined ) then // Bug workaround 8.3.3.658 for WebClient: it doesn't understand "Undefined" in first paramer
		ShowMessageBox ( , Output.Sformat ( Text, Params ), Timeout, ? ( Title = "", MetadataPresentation (), Title ) );
	else
		ShowMessageBox ( handler, Output.Sformat ( Text, Params ), Timeout, ? ( Title = "", MetadataPresentation (), Title ) );
	endif; 
	
endprocedure

&atclient
procedure openQueryBox ( Text, Params, ProcName, Module, CallbackParams, Buttons, Timeout, DefaultButton, Title )
	
	ShowQueryBox ( new NotifyDescription ( ProcName, Module, CallbackParams ), Output.Sformat ( Text, Params ), Buttons, Timeout, DefaultButton, ? ( Title = "", MetadataPresentation (), Title ) );
	
endprocedure

&atclient
procedure putUserNotification ( Text, Params, NavigationLink, Explanation, Picture )
	
	ShowUserNotification ( Output.SFormat ( Text, Params ), NavigationLink, Output.SFormat ( Explanation, Params ), Picture );
	
endprocedure

&atclient
function AskUser ( Text, Params, Buttons, Timeout, DefaultButton, Title ) export

	return DoQueryBoxAsync ( Output.Sformat ( Text, Params ), Buttons, Timeout, DefaultButton, ? ( Title = "", MetadataPresentation (), Title ) );

endfunction

function Row ( Table, LineNumber, Field ) export
	
	return Table + "[" + Format ( LineNumber - 1, "NG=;NZ=" ) + "]." + Field;
	
endfunction 

function TableAndRow ( Params ) export

	text = NStr ( "en='table %Table [%Row]';ru='таблица %Table [%Row]'" );
	return Output.Sformat ( text, Params );

endfunction

&atclient
function MetadataPresentation () export

	text = NStr ( "en='Tester';ru='Тестер'" );
	return text;

endfunction

function getTable ( Field )
	
	i = StrFind ( Field, "[" );
	j = StrFind ( Field, "]", , i );
	if ( i = 0 or j = 0 ) then
		return undefined;
	endif; 
	name = TrimAll ( Left ( Field, i - 1 ) );
	row = 1 + Number ( Mid ( Field, i + 1, j - i - 1 ) );
	return new Structure ( "Name, Row", name, row );
	
endfunction 

#region ExchangeData

&atclient
procedure MasterNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Main node selected. Data exchange must be made from subordinate nodes!';ru='Выбран главный узел. Обмен данными должен производиться из подчиненных узлов!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ExchangeDataItemAlreadyExist ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Element with node code: %Code already exists! To modify or add node data, you must open an existing directory item.';ru='Элемент с кодом узла: %Code уже существует! Для изменения или добавления данных узла необходимо открыть уже существующий элемент справочника.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atclient
procedure ChangePrefixFileName ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='The prefix of the data exchange file name has been changed! This operation must be performed carefully! For further correct work of data exchange, it is necessary to make similar changes in the corresponding nodes of the distributed information base.';ru='Был изменён префикс имени файла обмена данными! Данную операцию необходимо выполнять осмотрительно! Для дальнейшей корректной работы обмена данными, необходимо произвести подобные изменения в соответствующих узлах распределённой информационной базы.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure AlreadyRunExchangeFull ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Background job ""Exchange"" is currently running. Please try again later.';ru='Фоновое задание ""Exchange"" в данный момент запущено. Повторите попытку позже.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atclient
procedure LoadingCompleteNotification ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export
	
	text = NStr ( "en='Load data';ru='Загрузка данных'" );
	explanation = NStr ( "en = 'Loading is complete!'; ru = 'Загрузка завершена!'" );
	putUserNotification ( text, Params, NavigationLink, explanation, PictureLib.Exchange );
	
endprocedure

&atclient
procedure UnloadingCompleteNotification ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export
	
	text = NStr ( "en='Unload data';ru='Выгрузка данных'" );
	explanation = NStr ( "en = 'Unloading is complete!'; ru = 'Выгрузка завершена!'" );
	putUserNotification ( text, Params, NavigationLink, explanation, PictureLib.Exchange );
	
endprocedure

&atserver
function NotDefineThisNode () export
	
	p = new Structure ();
	p.Insert ( "Node", ExchangePlans.Full.ThisNode () );
	s = NStr ( "en = 'No setting created for exchange data for node - ""%Node"".'; ru = 'Не создана настройка обмена данными для узла - ""%Node"".'" );
	return Sformat ( s, p );
	
endfunction

&atserver
procedure WritingChanges ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='... write data to file.';ru='... запись данных в файл.'" );
	putMessage ( text, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure WritingChangesComplete ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... data successfully written to file.';ru='... данные успешно записаны в файл.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ConnectToWS ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	s = NStr ( "en='... connecting to a web service';ru='... подключение к веб-сервису'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ReadWS ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... receiving data through a web service';ru='... получение данных через веб-сервис'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure WriteWS ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... data recording via web service';ru='... запись данных через веб-сервис'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure CheckPreviousFileExchange ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Search for an existing exchange file.';ru='Поиск существующего файла обмена.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ItWasFoundFileExchange ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='An unread exchange file was found for the %Node node (the file name is %File). Node will not be unloaded for %Node.';ru='Для узла %Node был обнаружен непрочитанный файл обмена (имя файла - %File). Для узла %Node не будет произведена выгрузка.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure FTPConnectionError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='There were errors connecting to the FTP server! Error description - ""%Error"".';ru='Возникли ошибки при соединении с FTP сервером! Описание ошибки - ""%Error"".'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure WillBeRunRereadFileExchange ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='The exchange file will be read again after updating the configuration.';ru='Файл обмена будет прочитан повторно, после обновления конфигурации.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ExchangeReceivedFromNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Exchange data from host ""%Node "" accepted!';ru='Данные обмена от узла ""%Node"" приняты!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ErrorReceivingData ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Error getting exchange data! %Error. Exchange file %FileXml..';ru='Ошибка при получении данных обмена! %Error. Файл обмена %FileXml.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure LockBase ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Infobase locked for configuration update.';ru='Информационная база заблокирована для обновления конфигурации.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure UnlockBase ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='The base lock is removed. Time - %Date.';ru='Снята блокировка базы. Время - %Date.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure FinishedRereadFileExchange ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Finishing reading the exchange file after updating the configuration.';ru='Завершение дочитывания файла обмена после обновления конфигурации.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure LoadDataFromNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Retrieving data from node ""%Node"" ...';ru='Получение данных от узла ""%Node"" ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure UnloadBegin ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Unload data for node ""%Node"" ...';ru='Выгрузка данных для узла ""%Node"" ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure UnloadFinish ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... unload data for node ""%Node"" completed.';ru='... выгрузка данных для узла ""%Node"" завершена.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure LoadDataFromNodeOver ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... receiving data from node ""%Node"" completed.';ru='... получение данных от узла ""%Node"" завершено.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure LoadFromEmail ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Load from email ...';ru='Загрузка данных из электронной почты ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure LoadFromFTP ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Load from ftp ...';ru='Загрузка данных с ftp ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure LoadFromWS ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Load data from web service ...';ru='Загрузка данных через веб-сервис ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure UnLoadToEmail ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Unload data to email ...';ru='Выгрузка данных на электронную почту ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure UnLoadToFTP ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Unload data to ftp ...';ru='Выгрузка данных на ftp ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure UnloadToDisk ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Unload data to disk ...';ru='Выгрузка данных на диск ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure UnloadToWebService ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='Unload data through web service ...';ru='Выгрузка данных через веб-сервис ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure LogonToServerMail ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Connection to the mail server ...';ru='Соединение с почтовым сервером ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

procedure LogonSuccess ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... connection to the server is established.';ru='... соединение с сервером установлено.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

procedure ErrorConnectEmailProfile ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Error connecting to mail profile! Exchange failed! Error Description:%Error';ru='Ошибка при подключении к почтовому профилю! Обмен не выполнен! Описание ошибки: %Error'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure MailReceived ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Message is received.';ru='Сообщение получено.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure SendingMail ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Sending email ...';ru='Отправка эл. почты ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure MessageSent ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Exchange message for node ""%Node"" sent successfully';ru='Сообщение обмена для узла ""%Node"" успешно отправлено.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure NoNewExchangeFiles ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='No new messages!';ru='Отсутствуют новые сообщения!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ErrorLogonInternetMail ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='Error connecting to internet mail. Error description - %ErrorDescription.';ru='Ошибка при подключении к интернет-почте. Описание ошибки - %ErrorDescription.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure FileDeletionError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='Error deleting file (%File)! %Error';ru='Ошибка при удалении файла (%File)! %Error'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure UnLoadFromWS ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='... started uploading data through a web service';ru='... стартовала выгрузка данных через веб-сервис'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure LoadFromNetworkDisk ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='... started loading data from a network drive';ru='... стартовала загрузка данных с сетевого диска'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ReadingChanges ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='... reading data from file.';ru='... чтение данных из файла.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ReadingChangesComplete ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... data from node ""%Node"" was successfully read from the file.';ru='... данные от узла ""%Node"" успешно прочитаны из файла.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ReceivedFromNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='Exchange data from host ""%Node"" accepted!';ru='Данные обмена от узла ""%Node"" приняты!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ReadChangesConfiguration ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='Changes that contain configuration changes were read. The configuration will be updated.';ru='Были прочитаны изменения, которые содержат изменения в конфигурации. Конфигурация будет обновлена.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
function SubjectErrorReport ( Params ) export

	s = NStr ("en='Errors while loading data from exchange node ""%Node"". The data load date is %CurrentDate.';ru='Ошибки при загрузке данных от узла-обмена ""%Node"". Дата загрузки данных - %CurrentDate.'" );
	return Sformat ( s, Params );

endfunction

&atserver
function TextMessageEmailErrorReport ( Params ) export 

	s = NStr ( "en='Exchange data with node ""%Node""."
	"Exceeded the maximum number of errors while loading data from the file-sharing."
	"The number of allowed errors is %MaximumErrors."
	"The date of the last failed download is %CurrentDate."
	"Error Description - %Error."
	"You need to resolve the cause of the error for further successful data exchange.';ru='Обмен данными с узлом ""%Node""."
	"Превышено максимальное количество ошибок при загрузке данных из файла-обмена."
	"Количество допустимых ошибок - %MaximumErrors."
	"Дата последней неудачной загрузки - %CurrentDate."
	"Описание ошибки - %Error."
	"Необходимо устранить причину ошибку для дальнейшего успешного обмена данными.'" );
	return Sformat ( s, Params );

endfunction

&atserver
function TextMessageEmailErrorReportNoNewExchangeFiles ( Params ) export

	s = NStr ( "en='Exchange data with node ""%Node""."
	"Exceeded the maximum number of errors while loading data from the file-sharing."
	"The number of allowed errors is %MaximumErrors."
	"The date of the last failed download is %CurrentDate."
	"The cause of the problem is the lack of file-sharing."
	"The cause of the error must be eliminated for further successful data exchange.';ru='Обмен данными с узлом ""%Node""."
	"Превышено максимальное количество ошибок при загрузке данных из файла-обмена."
	"Количество допустимых ошибок - %MaximumErrors."
	"Дата последней неудачной загрузки - %CurrentDate."
	"Причина проблемы - отсутствие файлов-обмена."
	"Необходимо устранить причину ошибку для дальнейшего успешного обмена данными.'" );
	return Sformat ( s, Params );

endfunction

&atclient
procedure ThisNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	s = NStr ( "en='The data exchange node corresponding to this information base has been selected. You must select a node to exchange data.';ru='Выбран узел обмена данными, соответствующей данной информационной базе. Необходимо выбрать узел для обмена данными.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure IncorrectRecipients ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Exchange with the node - ""%Node"". Failed to send email mail ""%EMailUnLoad""! Error - ""%Error""!';ru='Обмен с узлом - ""%Node"". Не удалось отправить письмо на эл. почту ""%EMailUnLoad""! Описание ошибки - ""%Error""!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure IncorrectReportRecipients ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Send error report. Failed to send email mail ""%EMailUnLoad""! Error - ""%Error""!';ru='Отправка уведомления об ошибках обмена. Не удалось отправить письмо на эл. почту ""%EMailUnLoad""! Описание ошибки - ""%Error""!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atclient
procedure SelectThisNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	s = NStr ( "en='This node is selected. Settings for this node are not specified.';ru='Выбран этот узел. Настройки для этого узла не указываются.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
function ExchangeReadDataError ( Params ) export

	s = NStr ( "en='User %User does not have permissions to exchange data.';ru='У пользователя %User нет прав на обмен данными.'" );
	return Sformat ( s, Params );

endfunction

&atserver
function UnknownNode ( Params ) export

	s = NStr ( "en='No node found. Node Code - %Code.';ru='Не найден узел. Код узла - %Code.'" );
	return Sformat ( s, Params );

endfunction

&atserver
procedure StartUpdateScriptProcedure ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Start procedure for updating the configuration';ru='Старт процедуры по обновлению конфигурации.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure NotFoundExecuteFile1C ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='The executable file 1cv8.exe was not found!';ru='Не найден исполняемый файл 1cv8.exe!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
function InfobaseUpdateMessage ( Params ) export

	s = NStr ( "en='The infobase was blocked for %Period min starting with %Date.';ru='Информационная база была заблокирована на %Period мин начиная с %Date.'" );
	return Sformat ( s, Params );

endfunction

&atserver
procedure StartReReadData ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Processing reading file.';ru='Стартовала процедура дочитывания файла обмена.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ExchangeLoadingAgain ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='The exchange data will be read again from the %Node node (ID = %ID).';ru='Будет произведено повторное чтение данных обмена из узла %Node (ID = %ID).'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ReReadLoad ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Data loading started after update.';ru='Началась загрузка данных после обновления.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure ReReadUnLoad ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Unloading of data after updating has begun.';ru='Началась выгрузка данных после обновления.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure CloseCurrentSession ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Ending the current session (processing reading data after update) ...';ru='Завершение текущего сеанса (дочитывание данных после обновления конфигурации) ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure SaveRereadExchange ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Saved file processing read file exchange. The file is %File.';ru='Сохранили файл обработки дочитывания файла обмена. Файл - %File.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

&atserver
procedure NotDefineLanguageForUser ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='For user %User is not set to the default language.';ru='Для пользователя %User не установлен язык по умолчанию.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

endprocedure

#endregion

&atserver
function RuntimeMessage ( Params = undefined ) export

	text = NStr ( "en='%Message {%Stack}';ru='%Message {%Stack}'" );
	return Output.Sformat ( text, Params );

endfunction

&atserver
function RuntimeMessagePrefix ( Params = undefined ) export

	text = "%Line: ";
	return Output.Sformat ( text, Params );

endfunction

&atserver
function RuntimeMessageCutPrefix () export

	text = "...";
	return text;

endfunction

&atclient
function CheckError ( Params ) export

	text = NStr ( "en='%Form: %Title. Field ""%Field"" <> ""%Value"". The actual value is ""%Result""';ru='%Form: %Title. Поле ""%Field"" <> ""%Value"". Текущее значение ""%Result""'" );
	return Output.Sformat ( text, Params );

endfunction

function ScenarioError () export

	text = NStr ( "en='Scenario error';ru='Ошибка сценария'" );
	return text;

endfunction

function CallError ( Params ) export

	text = NStr ( "en='Scenario ""%Scenario"" not found';ru='Сценарий ""%Scenario"" не найден'" );
	return Output.Sformat ( text, Params );

endfunction

&atclient
procedure TestComlete ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = Output.TestComleteMessage ();
	PutMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
function TestComleteMessage () export
	
	text = NStr ( "en='Test complete!';ru='Тест завершен!'" );
	return text;
	
endfunction

function CompilationError () export

	text = NStr ( "en='Compilation error';ru='Ошибка компиляции'" );
	return text;

endfunction

&atclient
function CheckAppearanceIncorrect ( Params ) export

	text = NStr ( "en='CheckAppearance error: Status ""%Value"" is unknown';ru='CheckAppearance ошибка: Статус ""%Value"" не определен'" );
	return Output.Sformat ( text, Params );

endfunction

&atclient
function CheckAppearanceError ( Params ) export

	text = NStr ( "en='Field ""%Field"" state ""%Value"" should be ""%Flag"". Actual state is ""%State""';ru='У поля ""%Field"" состояние ""%Value"" должно быть ""%Flag"", а реальное состояние ""%State""'" );
	return Output.Sformat ( text, Params );

endfunction

&atclient
function FieldNotFound ( Params ) export

	text = NStr ( "en='Field ""%Field"" is not found';ru='Поле ""%Field"" не найдено'" );
	return Output.Sformat ( text, Params );

endfunction

&atclient
function ManyPlaces ( Params ) export

	text = NStr ( "en='Field ""%Field"" found many times: %Places';ru='Поле ""%Field"" найдено в нескольких местах: %Places'" );
	return Output.Sformat ( text, Params );

endfunction

&atclient
function StopMessage () export

	text = NStr ( "en='Scenario stopped';ru='Сценарий остановлен'" );
	return text;

endfunction

&atclient
function NewScenario () export

	text = NStr ( "en='New Scenario';ru='Новый сценарий'" );
	return text;

endfunction

&atclient
function TemplateEmpty () export

	text = NStr ( "en='Template is empty';ru='Шаблон пустой'" );
	return text;

endfunction

&atclient
function AreaComparisonError ( Params ) export

	text = NStr ( "en='Cell [%Area] correct value [%Original] is not equal actual value [%Actual]';ru='Ячейка [%Area] правильное значение [%Original] не соответствует текущему значению [%Actual]'" );
	return Output.Sformat ( text, Params );

endfunction

function TemplateCaption () export

	text = NStr ( "en='Template';ru='Шаблон'" );
	return text;

endfunction

&atclient
procedure MainScenarioUndefined ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "MainScenarioUndefined" ) export
	
	text = NStr ( "en='Main Scenario is not yet defined';ru='Основной сценарий еще не определен'" );
	title = NStr ( "en=''; ru=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

&atserver
procedure UserNameAlreadyExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Duplicate user name detected';ru='Такое имя пользователя уже существует'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
procedure SelectAccessRights ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Check the boxes to set access rights';ru='Отметьте флажками права доступа'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
procedure ConfirmAccessRights ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Confirm or revert changes in access rights';ru='Принять или отменить изменения в правах доступа'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
procedure SelectUsersGroup ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Assign user to the group or assign individual rights';ru='Назначить пользователю группу или индивидуальные права'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
procedure RightsConfirmation ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "BPNotFound" ) export
	
	text = NStr ( "en='Selected right has dependencies on other system rights."
"They should be added or removed as well."
"Please review changes, then Accept or Cancel them';ru='Выбранное право имеет зависимости от других прав системы."
"Они должны быть добавлены или удалены соответственно."
"Пожалуйста, просмотрите изменения и примите или отмените их'" );
	title = NStr ( "en=''; ru=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

&atclient
procedure ClearLogConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ClearLogConfirmation" ) export
	
	text = NStr ( "en='Do you want to remove all records?';ru='Удалить все записи?'" );
	title = NStr ( "en=''; ru=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
endprocedure

&atserver
procedure AdministratorNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='No users with administrative rights left in the system. You need to have at least one user with administrative rights in the database for service efficiency';ru='В системе не осталось пользователей с административными правами. Для работы сервиса требуется как минимум один администратор приложения'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
procedure AccessDenied ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "AccessDenied" ) export
	
	text = NStr ( "en='Access denied';ru='Доступ запрещен'" );
	title = NStr ( "en=''; ru=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

&atserver
function ApplicationNotFound ( Params ) export

	text = NStr ( "en='""%Name"" application is not found';ru='""%Name"" приложение не найдено'" );
	return Sformat ( text, Params );

endfunction

function ScenarioNotFound ( Params ) export

	text = NStr ( "en='""%Name"" scenario is not found';ru='""%Name"" сценарий не найден'" );
	return Sformat ( text, Params );

endfunction

&atclient
procedure DownloadCompleted ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "DownloadCompleted" ) export
	
	text = NStr ( "en='Download completed!';ru='Загрузка завершена!'" );
	title = NStr ( "en=''; ru=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

&atserver
function ParametersCountError ( Params ) export

	text = NStr ( "en='%Name (): Count of parameters cannot be more than %Limit';ru='%Name (): Количество параметров не может быть больше %Limit'" );
	return Sformat ( text, Params );

endfunction

&atserver
procedure ScenarioAlreadyExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = '""%Name"" scenario is already exists'; ru = '""%Name"" сценарий уже существует'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

procedure LockError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = Output.LockingError ();
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

function LockingError ( Params = undefined ) export

	text = NStr ( "en='Scenario ""%Scenario"" has already been locked by %User';ru='Сценарий ""%Scenario"" уже захватил %User'" );
	return Sformat ( text, Params );

endfunction

&atserver
procedure ScenarioNotLocked ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Scenario ""%Scenario"" has not been locked'; ru = 'Сценарий ""%Scenario"" не захвачен для редактирования'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
procedure UnlockConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UnlockConfirmation" ) export
	
	text = NStr ( "en = 'Selected scenarios will be replaced on the previous versions!
                  |Do you want to continue?'; ru = 'Выбранные сценарии будут заменены на предыдущие версии!
                  |Продолжить операцию?'" );
	title = NStr ( "en=''; ru=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
endprocedure

&atclient
procedure EnrollmentError ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "EnrollmentError" ) export
	
	text = NStr ( "ru='Центральный узел не может быть использован';en='The main node cannot be used'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

&atclient
procedure EnrollNode ( Module, CallbackParams = undefined, Params = undefined, ProcName = "EnrollNode" ) export
	
	text = NStr ( "en = 'For this User, all scenarios will be marked as changed!
                   |Would you like to continue?'; ru = 'Для данного пользователя все сценарии будут помечены как измененные!
                   |Продолжить?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
endprocedure

&atclient
procedure EnrollmentCompleted ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "EnrollmentCompleted" ) export
	
	text = NStr ( "ru='Регистрация завершена!';en='Enrollment is completed!'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

&atserver
procedure ColumnIsEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "ru='Не заполнена колонка ""%Column"" в строке %LineNumber списка ""%Table""';en='Row ""%Column"" in line %LineNumber of list ""%Table"" is empty'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
procedure FieldIsEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "ru='Поле ""%Field"" не заполнено';en='Field ""%Field"" is empty'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
procedure ScenariosProcessed ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ScenariosProcessed" ) export
	
	text = NStr ( "en = 'Operation completed!
                   |Scenarios Processed: %Counter'; ru = 'Операция завершена!
                   |Обработано сценариев: %Counter'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

&atclient
procedure ScenariosProcessedNotification ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export
	
	text = NStr ( "en='Unloading scenarios';ru='Выгрузка сценариев'" );
	explanation = NStr ( "en = 'Operation completed!
                   |Scenarios Processed: %Counter'; ru = 'Операция завершена!
                   |Обработано сценариев: %Counter'" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );
	
endprocedure

function CommonApplicationName () export

	text = NStr ( "en='<Common>';ru='<Общее>'" );
	return text;

endfunction

&atserver
function CommonApplicationCode () export

	text = NStr ( "en='COMM';ru='ОБЩЕ'" );
	return text;

endfunction

&atserver
procedure RepositoryNotSelected ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Select at least one repository for processing'; ru = 'Выберите хотя бы один репозиторий для обработки'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
procedure ScenarioIDError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Scenario ID should not contain special characters'; ru = 'ID сценария не должен содержать специальные символы'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
function UserAdmin () export

	text = NStr ( "en='Administrator';ru='Администратор'" );
	return text;

endfunction

&atclient
procedure SetupMainScenario ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SetupMainScenario" ) export
	
	text = NStr ( "en = 'Main Scenario is not yet defined.
                  |Would you like to install current scenario as main?'; ru = 'Основной сценарий еще не определен.
                  |Установить запускаемый сценарий как основной?'" );
	title = NStr ( "en=''; ru=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
endprocedure

&atclient
procedure UndefinedMainScenario ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "UndefinedMainScenario" ) export
	
	title = NStr ( "en=''; ru=''" );
	text = NStr ( "en = 'Main scenario is undefined'; ru = 'Основной сценарий не определен'" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

&atserver
function LoadingProcessVersionMemo () export

	text = NStr ( "en = 'Automatically created scenario version during files loading process'; ru = 'Автоматически созданная версия перед загрузкой сценария из файла'" );
	return text;

endfunction

&atclient
procedure AssistantBuiltin ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "AssistantBuiltin" ) export
	
	text = NStr ( "en = 'Built-in functions cannot be changed'; ru = 'Встроенные функции не могут быть изменены'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

&atclient
function RecordingSenario () export

	text = NStr ( "en = 'Recording...'; ru = 'Идет запись...'" );
	return text;

endfunction

&atclient
function PauseScenario () export

	text = NStr ( "en = 'Pause'; ru = 'Пауза'" );
	return text;

endfunction

function RecordSenario () export

	text = NStr ( "en = 'Record: no connection'; ru = 'Запись: нет подключения'" );
	return text;

endfunction

&atclient
function WrongFieldValue ( Params ) export

	text = NStr ( "en = 'Entered value was not found. The closest match found in the system is ""%NewValue"". Please provide an unambiguous value or select it from the list. If the value does not exist, consider creating it';ru = 'Введённое значение не найдено. Ближайшее совпадение, найденное в системе: ""%NewValue"". Пожалуйста, введите однозначное значение или выберите его из списка. Если значение не существует, рассмотрите возможность его создания'" );
	return Sformat ( text, Params );

endfunction

&atserver
procedure CommonReportOpenError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'This report is an official report and it cannot be opened interactively';ru = 'Данный отчет является служебным и не предназначен для интерактивного открытия'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
function ClickGenerateReport () export
	
	text = NStr ( "en='Press the button ""Generate"" to create a report';ru='Нажмите кнопку Сформировать для формирования отчета'" );
	return text;
	
endfunction

&atclient
procedure ReportVariantModified2 ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReportVariantModified2" ) export
	
	text = NStr ( "en='Current report version was modified."
"Would you like to save changes?';ru='Текущий вариант отчета модифицирован."
"Сохранить изменения?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Yes, title );
	
endprocedure

&atserver
procedure ReportSchedulingIncorrectPeriod ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Selection by period is set to specific date. You cannot use the schedule because you set strict selection mode and the report will be delivered with the same data all the time. Try to set predefined value as a selection, not a specific date.';ru='Отбор по периоду установлен на конкретную дату. Использовать расписание нельзя, так как вы установили строгий отбор и будете каждый раз получать этот отчет с одними и теме же данными. Попробуйте указать в качестве отбора, не конкретную дату(ы), а предопределенное значение'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
procedure ReportVariantModified1 ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReportVariantModified1" ) export
	
	text = NStr ( "en='Current report version has been modified."
"Would you like to save current changes before loading the new version?';ru='Текущий вариант отчета модифицирован."
"Перед загрузкой нового варианта отчета, произвести сохранение текущих изменений?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Yes, title );
	
endprocedure

&atserver
function LoadReportSettings () export
	
	text = NStr ( "en='Report settings';ru='Настройки отчета'" );
	return text;
	
endfunction

&atserver
function LoadReportVariant () export
	
	text = NStr ( "en='Report variants';ru='Варианты отчета'" );
	return text;
	
endfunction

&atclient
procedure ReplaceReportVariant ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReplaceReportVariant" ) export
	
	text = NStr ( "en='Overwrite the existing report settings?';ru='Перезаписать существующие настройки отчета?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
endprocedure

&atserver
procedure SendingReportsByScheduleAddingError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Scheduled reports can be created and sent from specific form. Interactive access denied';ru='Создание графиков отправки осуществляется из форм конкретных отчетов. Интерактивное добавление недоступно'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
procedure ScheduleDateError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Start the schedule from the date greater than current date';ru='Начните расписание с даты большей, чем текущая дата'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
procedure WeekDaySelectionError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Please select at least one week day';ru='Выберите хотя бы один день недели'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
procedure ReportScheduleRemovingConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReportScheduleRemovingConfirmation" ) export
	
	text = NStr ( "en='Are you sure you want to delete the schedule?';ru='Удалить расписание?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
endprocedure

&atserver
function ReportByEmailBody ( Params ) export
	
	text = NStr ( "en='Hello,"
"You received scheduled report %ReportPresentation. Report is attached to this e-mail."
""
"To change the schedule you can go to:"
"%ScheduleSettingsURL"
""
"Sincerely,"
"%Website';ru='Доброго времени суток!"
"Вы получили по расписанию отчет %ReportPresentation. Отчет во вложении к письму."
""
"Для изменения расписания, вы можете перейти по ссылке:"
"%ScheduleSettingsURL"
""
"С уважением, команда специалистов %Website'" );
	return Output.Sformat ( text, Params );
	
endfunction

&atserver
function PageFooter () export
	
	text = NStr ( "en='[&PageNumber] from [&PagesTotal]';ru='[&PageNumber] from [&PagesTotal]'" );
	return text;
	
endfunction

&atclient
procedure SetCurrentVersion ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SetCurrentVersion" ) export
	
	text = NStr ( "en = 'Selected version %Version will be used as current application version for your profile.
                  |Would you like to continue?'; ru = 'Для вашего профиля, версия %Version будет установлена как текущая.
                  |Продолжить?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
endprocedure

&atserver
function ExpressionError () export
	
	text = NStr ( "en = 'Expression error'; ru = 'Ошибка в выражении'" );
	return text;
	
endfunction

&atserver
function CurrentVersionUndefined () export
	
	text = NStr ( "en = 'Current version is not defined'; ru = 'Текущая версия не определена'" );
	return text;
	
endfunction

&atserver
function VersionNotFound ( Params ) export
	
	text = NStr ( "en = 'Version <%Version> is not found'; ru = 'Версия <%Version> не найдена'" );
	return Output.Sformat ( text, Params );
	
endfunction

function StopDebugging () export

	text = NStr ( "en = 'Debugging stopped'; ru = 'Отладка остановлена'" );
	return text;

endfunction

&atclient
procedure ApplicationChangingError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Application changing error. Scenario: %Scenario, Error: %Error'; ru = 'Не удалось изменить приложение для сценария %Scenario. Ошибка: %Error'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

function OptionsLabelShow () export

	text = NStr ( "en = 'Options'; ru = 'Опции'" );
	return text;

endfunction

function OptionsLabelHide () export

	text = NStr ( "en = 'Hide'; ru = 'Скрыть'" );
	return text;

endfunction

function FilterLabelShow () export

	text = NStr ( "en = 'Filter: '; ru = 'Отбор: '" );
	return text;

endfunction

function LockedLabel () export

	text = NStr ( "en = 'Filtered by Locked'; ru = 'Отобраны захваченные'" );
	return text;

endfunction

function UnlockedLabel () export

	text = NStr ( "en = 'Filtered by Unlocked'; ru = 'Отобраны незахваченные'" );
	return text;

endfunction

function TagsFilter () export

	text = NStr ( "en = 'Tags'; ru = 'Теги'" );
	return text;

endfunction

&atclient
function SourceNotFound () export

	text = NStr ( "en = 'Source not found '; ru = 'Источник не найден'" );
	return text;

endfunction

&atserver
function NewTag () export

	text = NStr ( "en = 'New Tag'; ru = 'Новый тег'" );
	return text;

endfunction

&atserver
procedure ObjectNotOriginal ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = '%Value already exists!'; ru = '%Value уже существует!'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
procedure TagRemovingConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "TagRemovingConfirmation" ) export
	
	text = NStr ( "en='Do you want to remove the tag?';ru='Удалить тег?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
endprocedure

&atclient
procedure TagsListEmpty ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "TagsListEmpty" ) export
	
	text = NStr ( "en = 'Tags list is empty. For creating new tags please contact your administrator'; ru = 'Список тегов не задан. Для создания новых тегов, обратитесь к администратору за получением соответствующих прав доступа'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

&atclient
function UndefinedExternalRequest () export

	text = NStr ( "en = 'Undefined request'; ru = 'Неопознанный запрос'" );
	return text;

endfunction

&atclient
function FileReadingError ( Params ) export

	text = NStr ( "en = 'File reading timeout error: %File'; ru = 'Превышен таймаут ожидания для чтения файла: %File'" );
	return Output.Sformat ( text, Params );

endfunction

&atclient
function ErrorsNotFound () export

	text = NStr ( "en = 'No syntax errors found!'; ru = 'Синтаксических ошибок не обнаружено!'" );
	return text;

endfunction

function UndefinedScenario ( Params ) export

	text = NStr ( "en = 'Cannot find scenario by file: %File'; ru = 'Не удалось найти сценарий согласно файла: %File'" );
	return Sformat ( text, Params );

endfunction

function ScenarioApplicationUnmapped ( Params ) export

	text = NStr ( "en = 'Scenario <%Path> is not mapped to the folder of the file system'; ru = 'Сценарий <%Path> не синхронизирован с папкой файловой системы'" );
	return Sformat ( text, Params );

endfunction

&atserver
procedure WrongRepoFolder1 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'One folder cannot be specified twice'; ru = 'Одна папка не может использоваться дважды'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
procedure WrongRepoFolder2 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Repository folders cannot be inside of each other: %Folder1 <-> %Folder2. Use another folder path'; ru = 'Папки репозиториев не могут включать друг друга: %Folder1 <-> %Folder2. Укажите другой путь к папке'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
procedure AgentAccessDenied ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = '%Creator cannot delegate tasks for the Agent: Access Denied'; ru = '%Creator не может делегировать задачи для этого агента: Отказано в доступе'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
function OpenErrorsLog () export

	text = NStr ( "en = 'Open Errors Log'; ru = 'Открыть журнал ошибок'" );
	return text;

endfunction

&atclient
function OpenError () export

	text = NStr ( "en = 'Error: '; ru = 'Ошибка: '" );
	return text;

endfunction

&atclient
function OpenLog () export

	text = NStr ( "en = 'Open Execution Log'; ru = 'Открыть журнал запуска'" );
	return text;

endfunction

&atclient
function OpenScenario () export

	text = NStr ( "en = 'Open Scenario'; ru = 'Открыть сценарий'" );
	return text;

endfunction

&atclient
procedure DeleteJob ( Module, CallbackParams = undefined, Params = undefined, ProcName = "DeleteJob" ) export
	
	text = NStr ( "en = 'Would you like to remove this job?'; ru = 'Удалить задание?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
endprocedure

function JobCanceled () export

	text = NStr ( "en = 'Job canceled'; ru = 'Задание отменено'" );
	return text;

endfunction

&atclient
function TestedApplicationOffline () export

	text = NStr ( "en = 'Tested application is offline'; ru = 'Нет подключения к тестируемому приложению'" );
	return text;

endfunction

&atserver
function AgentNotFound ( Params ) export

	text = NStr ( "en = 'Agent ""%Agent"" not found'; ru = 'Агент ""%Agent"" не найден'" );
	return Sformat ( text, Params );

endfunction

&atserver
function ComputerNotFound ( Params ) export

	text = NStr ( "en = 'Computer ""%Computer"" not found'; ru = 'Компьютер ""%Computer"" не найден'" );
	return Sformat ( text, Params );

endfunction

&atclient
function OSNotSupported () export
	
	text = NStr ( "en = 'The extended functions library supports Windows OS only. Other operating systems are not currently supported'; ru = 'Библиотека расширенных функций поддерживает работу в операционной системе Windows. Другие операционные системы в настоящий момент не поддерживаются'" );
	return text;
	
endfunction

&atserver
procedure SourcesFolderError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'At least one folder should be defined'; ru = 'Как минимум одна папка должна быть определена'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
function UnableToClick ( Params ) export

	text = NStr ( "en = 'Unable to click %Field'; ru = 'Не удалось нажать на %Field'" );
	return Sformat ( text, Params );

endfunction

&atserver
function CheckAppearanceError ( Params ) export

	text = NStr ( "en='Field ""%Field"" state ""%Value"" should be ""%Flag"". Actual state is ""%State""';ru='У поля ""%Field"" состояние ""%Value"" должно быть ""%Flag"", а реальное состояние ""%State""'" );
	return Output.Sformat ( text, Params );

endfunction

&atserver
function ShouldBe () export
	
	text = NStr ( "en = 'should be'; ru = 'должно быть'");
	return text;
	
endfunction

&atserver
function ShouldNotBe () export
	
	text = NStr ( "en = 'should not be'; ru = 'не должно быть'");
	return text;
	
endfunction

&atserver
function Filled () export
	
	text = NStr ( "en = 'filled'; ru = 'заполненным'");
	return text;
	
endfunction

&atserver
function Empty () export
	
	text = NStr ( "en = 'empty'; ru = 'пустым'");
	return text;
	
endfunction

&atserver
function Existed () export
	
	text = NStr ( "en = 'existed'; ru = 'существующим'");
	return text;
	
endfunction

&atserver
function Between ( Params ) export
	
	text = NStr ( "en = 'between %Start and %Finish'; ru = 'между %Start и %Finish'");
	return Output.Sformat ( text, Params );
	
endfunction

&atserver
function ShouldContain () export
	
	text = NStr ( "en = 'should contain'; ru = 'должно содержать'");
	return text;
	
endfunction

&atserver
function ShouldNotContain () export
	
	text = NStr ( "en = 'should not contain'; ru = 'не должно содержать'");
	return text;
	
endfunction

&atserver
function ShouldHave () export
	
	text = NStr ( "en = 'should have size'; ru = 'должно иметь размер'");
	return text;
	
endfunction

&atserver
function ShouldNotHave () export
	
	text = NStr ( "en = 'should not have size'; ru = 'не должно иметь размер'");
	return text;
	
endfunction

&atserver
function Value () export
	
	text = NStr ( "en = 'Value'; ru = 'Значение'");
	return text;
	
endfunction

&atserver
function YesNo () export
	
	text = NStr ( "en = 'BF=False; BT=True'; ru = 'BF=Ложь; BT=Истина'");
	return text;
	
endfunction

&atclient
procedure NoStepsInChronograph ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export
	
	text = NStr ( "en='Chronograph';ru='Хронограф'" );
	explanation = NStr ( "en = 'There are no steps for the selected direction'; ru = 'Нет шагов для перехода в указанном направлении'" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );
	
endprocedure

&atserver
function SessionAccessError () export
	
	text = NStr ( "en = 'You don’t have access to the tested session'; ru = 'Нет доступа к тестируемой сессии'");
	return text;
	
endfunction

&atserver
function ScenarioNotFilmed () export
	
	text = NStr ( "en = 'Scenario wasn’t filmed'; ru = 'Сценарий не записывался в хронограф'");
	return text;
	
endfunction

&atclient
procedure WrongFolder ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'The folder is referencing to itself'; ru = 'Папка ссылается на саму себя'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
function CopyingError () export
	
	text = NStr ( "en = 'Selected item causes levels looping!'; ru = 'Выбранный элемент приводит к зацикливанию уровней!'" );
	return text;
	
endfunction

&atclient
procedure CopyMoveConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "CopyMoveConfirmation" ) export
	
	text = NStr ( "en = 'During the process system will change applications of transferred scenarios to %Application'; ru = 'При помещении сценариев в выбранную папку будет произведена замена приложения помещаемых сценариев на %Application'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
endprocedure

&atclient
procedure ErrorNotLocated ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ErrorNotLocated" ) export
	
	text = NStr ( "en = 'Selected error has not been found in the list. Check filters in the list which can prevent locating the error'; ru = 'Не удалось перейти к строке с ошибкой. Проверьте установленные отборы, возможно они не позволяют найти выбранную в списке ошибку'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

&atclient
function WebClientDoesNotSupport () export
	
	text = NStr ( "en = 'Web client does not support this functionality'; ru = 'Веб-клиент не поддерживает данную функциональность'" );
	return text;
	
endfunction

&atclient
function ClientDoesNotSupport () export
	
	text = NStr ( "en = 'This application does not support this functionality'; ru = 'Это приложение не поддерживает данную функциональность'" );
	return text;
	
endfunction

&atserver
function WatcherRenamingError ( Params ) export

	text = NStr ( "en = 'Scenario renaming error: %Scenario (%File). %Error'; ru = 'Ошибка переименования сценария: %Scenario (%File). %Error'" );
	return Sformat ( text, Params );

endfunction

&atserver
function WatcherRenamingChildrenError ( Params ) export

	text = NStr ( "en = 'Error on changing the path of subordinate scenarios for the %Scenario';ru = 'Ошибка при изменении пути подчиненных сценариев для %Scenario'" );
	return Sformat ( text, Params );

endfunction

&atserver
function WatcherDeletingChildrenError ( Params ) export

	text = NStr ( "en = 'Error on deleting subordinate scripts in %Scenario group';ru = 'Ошибка при изменении пути подчиненных сценариев для %Scenario'" );
	return Sformat ( text, Params );

endfunction

&atserver
function WatcherUpdatingError ( Params ) export

	text = NStr ( "en = 'Scenario updating error: %Scenario. %Error'; ru = 'Ошибка обновления сценария: %Scenario. %Error'" );
	return Sformat ( text, Params );

endfunction

&atserver
function WatcherParentNotFound ( Params ) export

	text = NStr ( "en = 'Parent scenario for the %File is not found'; ru = 'Родительский сценарий для %File не найден'" );
	return Sformat ( text, Params );

endfunction

&atserver
function WatcherCreatingError ( Params ) export

	text = NStr ( "en = 'Scenario creating error. Folder: %Parent (%File). %Error'; ru = 'Ошибка создания сценария. Папка: %Parent (%File). %Error'" );
	return Sformat ( text, Params );

endfunction

&atserver
function WatcherRestorationError ( Params ) export

	text = NStr ( "en = 'Restoration of %Scenario (%File) caused an error: %Error'; ru = 'Ошибка восстановления сценария %Scenario (%File). %Error'" );
	return Sformat ( text, Params );

endfunction

&atserver
function WatcherRemovingError ( Params ) export

	text = NStr ( "en = 'Scenario removing error: %Scenario. %Error'; ru = 'Ошибка удаления сценария: %Scenario. %Error'" );
	return Sformat ( text, Params );

endfunction

&atserver
function WatcherTemplateRemovingError ( Params ) export

	text = NStr ( "en = 'Scenario template removing error: %Scenario. %Error'; ru = 'Ошибка удаления шаблона сценария: %Scenario. %Error'" );
	return Sformat ( text, Params );

endfunction

&atserver
function WatcherScriptRemovingError ( Params ) export

	text = NStr ( "en = 'Scenario script removing error: %Scenario. %Error'; ru = 'Ошибка удаления программного кода сценария: %Scenario. %Error'" );
	return Sformat ( text, Params );

endfunction

&atclient
function WatcherRenamingFolderError ( Params ) export

	text = NStr ( "en = 'You renamed the file (%File) responsible for the current folder which can cause synchronization issues. Please, use Tester for renaming folders and test-libraries';ru = 'Вы переименовали файл (%File) ответственный за именование текущей папки. Это может привести к ошибкам синхронизации. Пожалуйста, используйте Тестер для переименования папок и библиотек с тестами'" );
	return Sformat ( text, Params );

endfunction

function WatcherFileNameError ( Params = undefined ) export
	
	text = NStr ( "en = 'File (%File) should not contain special characters'; ru = 'Файл (%File) не должен содержать специальные символы'" );
	return Sformat ( text, Params );
	
endfunction

&atclient
procedure SyntaxError ( Form, Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = '%Error'; ru = '%Error'" );
	putMessage ( text, Params, Field, DataKey, DataPath, Form );
	
endprocedure

&atclient
procedure ContinueStoring ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ContinueStoring" ) export
	
	text = NStr ( "en = 'Syntax errors have been found!
				  |Would you like to continue?';ru = 'Обнаружены синтаксические ошибки!
				  |Продолжить?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
endprocedure

&atclient
function VSCodeWorkspace ( Params ) export

	text = NStr ( "en = 'Visual Studio Code Workspace (*%Extension)|*%Extension';ru = 'Рабочая область Visual Studio Code (*%Extension)|*%Extension'" );
	return Sformat ( text, Params );

endfunction

&atclient
function SelectWorkspace () export

	text = NStr ( "en = 'Select Workspace';ru = 'Выберите рабочую область'" );
	return text;

endfunction

&atclient
procedure VSCodeWorkspaceUndefined ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "VSCodeWorkspaceUndefined" ) export
	
	text = NStr ( "en = 'Workspace is not defined!
				  |Please, open Repositories and specify Visual Studio Code workspace
				  |for application %Application';ru = 'Рабочая область не задана!
				  |Откройте пожалуйста Репозитории и задайте
				  |для приложения %Application
				  |рабочую область Visual Studio Code'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

&atclient
function WatcherListeningEvents () export

	text = NStr ( "en = 'Listening repository changes...';ru = 'Получение событий от репозитория...'" );
	return text;

endfunction

&atclient
function WatcherSyncingMessage () export

	text = NStr ( "en = 'Syncing with repository';ru = 'Синхронизация с репозиторием'" );
	return text;

endfunction

&atclient
procedure WorkspaceCreated ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export
	
	text = NStr ( "en='Tester';ru='Тестер'" );
	explanation = NStr ( "en = 'Workspace has been created: %Path'; ru = 'Создана рабочая область: %Path'" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );
	
endprocedure

&atclient
procedure MarkForDeletion ( Module, CallbackParams = undefined, Params = undefined, ProcName = "MarkForDeletion" ) export
	
	text = NStr ( "en = 'Mark for deletion?';ru = 'Пометить на удаление?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
endprocedure

&atclient
procedure UnmarkForDeletion ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UnmarkForDeletion" ) export
	
	text = NStr ( "en = 'Do you want to remove the deletion mark for selected elements?';ru = 'Снять пометку на удаление?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
endprocedure

&atclient
procedure ShowError ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ShowError" ) export
	
	text = "%Error";
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
endprocedure

function SpreadsheedTotalCount ( Params ) export

	text = NStr ( "en='Count: %Count'; ru='Кол-во: %Count'" );
	return Sformat ( text, Params );

endfunction

function SpreadsheedTotal ( Params ) export

	text = NStr ( "en='Avg: %Average   Count: %Count   Sum: %Sum'; ru='Среднее: %Average   Кол-во: %Count   Сумма: %Sum'" );
	return Sformat ( text, Params );

endfunction

&atclient
function CalculationAreaTooBig () export

	text = NStr ( "en='The selected area is too large. Click on the button on the right for manual calculation'; ru='Выделена большая область. Нажмите кнопку справа для расчета'" );
	return text;

endfunction

function SpreadsheedAreaNotSelected () export

	text = NStr ( "en='Area not defined'; ru='Область не задана'" );
	return text;

endfunction

&atserver
function DataSetColumnNotFound ( Params ) export

	text = "Field not found, DataPath: %Path. Might be the field no longer exists in the source report or Mobile application (or mobile reports) is not up to date";
	return Sformat ( text, Params );

endfunction

&atserver
procedure SyncingBackRequred ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Common scenario <%Folder> has been changed. Syncing back is required for the following applications: %Apps';ru = 'Был изменен общий сценарий <%Folder>, требуется обратная синхронизация изменений для приложений: %Apps'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atserver
function LoadingError () export

	text = NStr ( "en = 'Data loading error occurred';ru = 'Произошла ошибка во время загрузки данных'" );
	return text;

endfunction

&atserver
function ScenarioPropertiesNotJSON () export

	text = NStr ( "en = 'Scenario properties must be a valid JSON object'; ru = 'Свойства сценария должны быть заданы в виде корректного JSON-объекта'" );
	return text;

endfunction

&atserver
function ScenarioPropertiesMissingRequiredFields ( Params ) export

	text = NStr ( "en = 'Scenario properties JSON is missing required fields: %Fields'; ru = 'В JSON свойств сценария отсутствуют обязательные поля: %Fields'" );
	return Sformat ( text, Params );

endfunction

&atserver
function ScenarioPropertiesTreeMustBeBoolean () export

	text = NStr ( "en = 'Scenario properties field ""Tree"" must be boolean (true/false)'; ru = 'Поле ""Tree"" в свойствах сценария должно быть булевым (true/false)'" );
	return text;

endfunction

&atserver
function ScenarioPropertiesWrongType ( Params ) export

	text = NStr ( "en = 'Scenario properties field ""Type"" must match Enums.Scenarios. Received: %Value'; ru = 'Поле ""Type"" в свойствах сценария должно соответствовать Enums.Scenarios. Получено: %Value'" );
	return Sformat ( text, Params );

endfunction

&atserver
function ScenarioPropertiesWrongSeverity ( Params ) export

	text = NStr ( "en = 'Scenario properties field ""Severity"" must match Enums.Severity. Received: %Value'; ru = 'Поле ""Severity"" в свойствах сценария должно соответствовать Enums.Severity. Получено: %Value'" );
	return Sformat ( text, Params );

endfunction

&atserver
function ScenarioPropertiesLoadingError ( Params ) export

	text = NStr ( "en = 'Scenario properties loading error in file %File. %Error'; ru = 'Ошибка загрузки свойств сценария из файла %File. %Error'" );
	return Sformat ( text, Params );

endfunction

function TableValuesDifferent ( Params ) export

	text = NStr ( "en = 'In the row %Row of %Table table, in the %Column column, the value should be ""%Standard"", not ""%Tested""'; ru = 'В строке %Row таблицы %Table, в колонке %Column должно быть ""%Standard"", а не ""%Tested""'" );
	return Output.Sformat ( text, Params );

endfunction

function TableFormatErrorStandard () export

	text = NStr ( "en = 'Standard Table'; ru = 'Эталонная таблица'" );
	return text;

endfunction

function TableFormatErrorTesting () export

	text = NStr ( "en = 'Testing Table'; ru = 'Тестируемая таблица'" );
	return text;

endfunction

function TableFormatErrorFormatting () export

	text = NStr ( "en = 'Formatting Table'; ru = 'Форматируемая таблица'" );
	return text;

endfunction

function TableFormatErrorColumns ( Params ) export

	text = NStr ( "en = '%Table Format Error: incorrect number of colums in the row #%Row'; ru = 'Ошибка формата, %Table: неверное количество колонок в строке #%Row'" );
	return Output.Sformat ( text, Params );

endfunction

function TableFormatErrorName ( Params ) export

	text = NStr ( "en = '%Table Format Error: table name is not defined'; ru = 'Ошибка формата, %Table: не определено имя таблицы'" );
	return Output.Sformat ( text, Params );

endfunction

function TableFormatErrorHeader ( Params ) export

	text = NStr ( "en = '%Table Format Error: table columns are not defined'; ru = 'Ошибка формата, %Table: не заданы колонки'" );
	return Output.Sformat ( text, Params );

endfunction

function TableColumnNotFound ( Params ) export

	text = NStr ( "en = 'There''s no <%Column> column in the %Table table, but the standard has'; ru = 'В таблице %Table нет колонки <%Column>, а в эталоне есть'" );
	return Output.Sformat ( text, Params );

endfunction

function TableHasManyColumns ( Params ) export

	text = NStr ( "en = '%Table table has more columns than standard'; ru = 'В таблице %Table больше колонок чем в эталоне'" );
	return Output.Sformat ( text, Params );

endfunction

function TableHasFewerColumns ( Params ) export

	text = NStr ( "en = '%Table table has fewer columns than standard'; ru = 'В таблице %Table меньше колонок чем в эталоне'" );
	return Output.Sformat ( text, Params );

endfunction

function TableHasManyRows ( Params ) export

	text = NStr ( "en = '%Table table has more rows than standard (%TestedRows > %StandardRows)'; ru = 'В таблице %Table больше строк чем в эталоне (%TestedRows > %StandardRows)'" );
	return Output.Sformat ( text, Params );

endfunction

function TableHasFewerRows ( Params ) export

	text = NStr ( "en = '%Table table has fewer rows than standard (%TestedRows < %StandardRows)'; ru = 'В таблице %Table меньше строк чем в эталоне (%TestedRows < %StandardRows)'" );
	return Output.Sformat ( text, Params );

endfunction

&atserver
procedure ColumnsNotSelected ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Select testing columns please'; ru = 'Выберите пожалуйста тестируемые колонки'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
function ErrorObtainingTableParameters () export

	text = NStr ( "en = 'An error occurred in obtaining the table parameters';ru = 'Произошла ошибка получения параметров таблицы'" );
	return text;

endfunction

&atclient
function Standard () export

	text = NStr ( "en = 'standard';ru = 'эталон'" );
	return text;

endfunction

&atclient
function TableDefinitionNotFound () export

	text = NStr ( "en = 'Table Definition Not Found';ru = 'Не удалось найти определение таблицы'" );
	return text;

endfunction

&atserver
procedure ScenarioTemplateLoadingError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en = 'Scenario template loading error: %Error. Scenario: %Scenario';ru = 'Произошла системная ошибка при загрузке шаблона сценария %Scenario: %Error'" );
	putMessage ( text, Params, Field, DataKey, DataPath );

endprocedure

&atclient
function LinuxVSCode () export

	return "code";

endfunction

procedure WrongExternalLibrary ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en = 'Wrong or missing library in the %File.
                   |Internal library will be used instead'; ru = 'Не удалось загрузить библиотеку из файла %File. Будет использована внутренняя компонента'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

endprocedure

function LibraryFailed () export

	text = NStr ( "en = 'Failed to connect an external library. Operation of the system is not possible';ru = 'Не удалось подключить внешнюю компоненту. Корректная работа системы невозможна'" );
	return text;

endfunction

&atclient
procedure AgentRunnerError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Failed to proceed %Job: %Error';ru = 'Возникла ошибка при обработке задания %Job: %Error'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
function DebuggerLabel () export

	text = NStr ( "en = 'DebugStart ();';ru = 'ОтладкаСтарт ();'" );
	return text;

endfunction

function WrongPeriod () export

	text = NStr ( "en='Period is incorrect'; ru='Некорректно задан период'" );
	return text;

endfunction

&atserver
function ShowingReportSettings () export

	text = NStr ( "en='Report settings'; ro='Setări raport'; ru='Настройки отчета'" );
	return text;

endfunction

&atserver
function ShowingReportVariants () export

	text = NStr ( "en='Report variants'; ro='Opţiuni raport'; ru='Варианты отчета'" );
	return text;

endfunction

&atclient
function NewReportAccessDefinition ( Params = undefined ) export

	text = NStr ( "en = 'Would you like to define an access for storing item?
				  |(you can do this later)';ro = 'Doriți să definiți accesul pentru elementul salvat?
				  |(puteți face acest lucru mai târziu)';ru = 'Определить доступ для сохраняемого элемента?
				  |(вы можете сделать это позже)'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	return Output.AskUser ( text, Params, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

endfunction

function Processing () export

	text = NStr ( "en='Processing...'; ru='Обработка...'" );
	return text;

endfunction

function JobFailed () export

	text = NStr ( "en='An exception has occurred during the execution of a background job'; ru='Произошло исключение во время выполнения фонового задания'" );
	return SFormat ( text, undefined );

endfunction

&atclient
function ErrorTitle () export

	text = NStr ( "en='Error'; ru='Ошибка'" );
	return text;

endfunction

&atclient
function InfoDetected () export

	text = NStr ( "en='Information messages were detected'; ru='Найдены информационные сообщения'" );
	return text;

endfunction

&atclient
procedure MCPServerError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Failed to start MCP server %Server: %Error';ru = 'Не удалось запустить MCP сервер %Server: %Error'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
procedure MCPServerWrongAccess ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Failed to start MCP server: the user doesn''t have access to edit scenarios'; ru = 'Не удалось запустить MCP сервер: у пользователя нет доступа к редактированию сценариев.'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
endprocedure

&atclient
procedure HTTPDError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	MCPServerError ( Params, Field, DataKey, DataPath );

endprocedure

&atclient
function WrongRequest () export

	return "MCP request body is not correct. It should have JSON format and include the 'id' and 'name' fields.";

endfunction

&atclient
function WrongCommand ( Params = undefined ) export

	text = "MCP tool '%Tool' is not found. The following tools are available: %List";
	return Sformat ( text, Params );

endfunction

&atclient
function SrenarioNotProvided () export

	return "The tool arguments were not found. You should provide the full path to the bsl-file in the 'args.script_path' value. The file should be inside a Tester repository folder configured for the current session. Path examples: /home/user/project/path/to/file.bsl for Linux, or C:\Users\user\project\path\to\file.bsl for Windows.";

endfunction

&atclient
function RequestedScenarioNotMapped ( Params ) export

	text = "Cannot determine which application the file %File belongs to. It looks like the folder from which you are trying to execute scripts is not mapped in the Tester";
	return Sformat ( text, Params );

endfunction

&atclient
function WrongScenarioExtension ( Params ) export

	text = "The scenario '%Path' extension should be 'bsl'";
	return Sformat ( text, Params );

endfunction

&atclient
function RequestedScriptNotFound ( Params ) export

	text = "Cannot determine the associated scenario for the file %File. A synchronization error has probably occurred";
	return Sformat ( text, Params );

endfunction

&atclient
function RequestedTestComleted () export
	
	text = "Scenario successfully completed!";
	return text;
	
endfunction

&atclient
function TableNotFound () export
	
	return NStr ( "en = 'Table not found';ru = 'Таблица не найдена'" );
	
endfunction

&atclient
function SpreadsheetNotFound () export
	
	return NStr ( "en = 'Spreadsheet not found';ru = 'Табличный документ не найден'" );
	
endfunction

&atclient
function TableIsTooBig () export
	
	return NStr ( "en = 'The table is too big. You can try to filter it, or, if applicable, export the table to a spreadsheet document and then use the method GetSpreadsheetContent to get the data as a Microsoft Excel file';ru = 'Таблица слишком большая. Вы можете попробовать отфильтровать данные или, если применимо, экспортировать таблицу в документ электронной таблицы, а затем использовать метод ПолучитьСодержимоеТабличногоДокумента для получения данных в виде файла Microsoft Excel'" );
	
endfunction

&atclient
function SectionsPanelNotFound () export
	
	return NStr ( "en = 'Please enable the display of the Sections panel in the command interface. Otherwise, the application menu cannot be accessed';ru = 'Включите отображение панели разделов в командном интерфейсе. Иначе доступ к главному меню приложения невозможен'" );
	
endfunction

&atclient
function SpreadsheetControlHint ( Params ) export

	text = NStr ( "en = 'Use GetSpreadsheetContent( ""%Name"" ) to get the xlsx file of this spreadsheet';ru = 'Используйте GetSpreadsheetContent ( ""%Name"" ) для получения xlsx-файла этого табличного документа'" );
	return Sformat ( text, Params );

endfunction

&atclient
function SetValueFailed () export

	return NStr ( "en = 'Probably the input field contains a complex type. Try to choose a value instead of setting it directly';ru = 'Вероятно, поле ввода содержит сложный тип. Попробуйте выбрать значение вместо того, чтобы устанавливать его напрямую'" );

endfunction

&atclient
function FieldIsReadOnly() export

	return NStr ( "en = 'The field is read-only';ru = 'Поле доступно только для чтения'" );

endfunction

&atclient
function WrongNextUse() export

	return NStr ( "en = 'Did you use With ( [<""Caption"">] ) ? Because the current source does not support the Next () method';ru = 'Вы использовали Здесь ( [<""Заголовок"">]  ) ? Потому что текущий источник не поддерживает метод Далее ()'" );

endfunction

&atclient
function WrongParameterType ( Params ) export

	text = NStr ( "en = 'Wrong parameter type #%Parameter in the function `%Function`';ru = 'Неверный тип параметра №%Parameter в функции `%Function`'" );
	return Sformat ( text, Params );

endfunction

&atclient
function CannotGotoRow ( Params ) export

	text = NStr ( "en = 'Failed to navigate to the row, the specified value ""%Value"" is probably absent in the ""%Column"" column of the table/list ""%Table""';ru = 'Не удалось перейти к строке, вероятно указанное значение ""%Value"" отсутствует в колонке ""%Column"" таблицы/списка ""%Table""'" );
	return Sformat ( text, Params );

endfunction

&atclient
function NameAndType ( Params ) export

	text = NStr ( "en = 'Name: %Name; Type: %Type';ru = 'Имя: %Name; Тип: %Type'" );
	return Sformat ( text, Params );

endfunction

&atclient
function AvoidAmbiguity () export

	return NStr ( "en = 'Use a name with the prefix ''#'' instead of a title to avoid ambiguity';ru = 'Используйте имя с префиксом ''!'' вместо заголовка, чтобы избежать неоднозначности'" );

endfunction

&atclient
function NoActiveWindowFound () export

	return NStr ( "en = 'No active window found';ru = 'Нет активных окон'" );

endfunction

&atclient
function NoWindows () export

	return NStr ( "en = 'There are no more windows to close'; ru = 'Больше нет окон, которые можно закрыть'" );

endfunction

&atclient
function CollapsibleGroup () export

	return NStr ( "en = 'Collapsible'; ru = 'Свертываемая'" );

endfunction

&atclient
function CollapsibleGroupSystemHint ( Params ) export

	text = NStr ( "en = 'This group is collapsed. To work with the items in this group, you need to expand it. To expand this group, use `Click ( ""%Name"" )`';ru = 'Эта группа свернута. Чтобы работать с элементами в этой группе, её необходимо развернуть. Чтобы развернуть эту группу, используйте `Click ( ""%Name"" )`'" );
	return Sformat ( text, Params );

endfunction

&atclient
function LoadingFilesCheckFillingError () export

	return NStr ( "en = 'CheckFilling() of data processor Load returned an error. Please try to sync files manually'; ru = 'ПроверкаЗаполнения() обработчика данных Загрузка вернул ошибку. Пожалуйста, попробуйте синхронизировать файлы вручную'" );

endfunction

&atclient
function UnloadingFilesCheckFillingError () export

	return NStr ( "en = 'CheckFilling() of data processor Unload returned an error. Please try to sync files manually'; ru = 'ПроверкаЗаполнения() обработчика данных Выгрузка вернул ошибку. Пожалуйста, попробуйте синхронизировать файлы вручную'" );

endfunction

function ValuesListFieldHint ( Params ) export

	text = NStr ( "en = 'This field represents a list of values. To change the list of values, use the Choose(""%Name"") method';ru = 'Это поле представляет собой список значений. Для изменения списка значений используйте метод Выбрать(""%Name"").'" );
	return Sformat ( text, Params );

endfunction

&atclient
function GotoNextRowFailed () export

	return NStr ( "en = 'Failed to navigate to the next table row. The current row is probably already the last, or the table is empty or inaccessible';ru = 'Не удалось перейти к следующей строке таблицы. Вероятно, текущая строка уже является последней, либо таблица пуста или недоступна'" );

endfunction

&atclient
function GotoPreviousRowFailed () export

	return NStr ( "en = 'Failed to navigate to the previous table row. The current row is probably already the first, or the table is empty or inaccessible';ru = 'Не удалось перейти к предыдущей строке таблицы. Вероятно, текущая строка уже является первой, либо таблица пуста или недоступна'" );

endfunction

&atclient
function TableRowIsNotExpandable () export

	return NStr ( "en = 'The current table row is not expandable';ru = 'Текущая строка таблицы не является раскрываемой'" );

endfunction

&atclient
function GoOneLevelDownFailed () export

	return NStr ( "en = 'Failed to go to the lower level. The current row is probably already the innermost, or the table is empty or inaccessible';ru = 'Не удалось перейти на уровень ниже. Текущая строка, вероятно, уже является самой вложенной, либо таблица пуста или недоступна'" );

endfunction

&atclient
function GoOneLevelUpFailed () export

	return NStr ( "en = 'Failed to move to the upper level. The current row is probably already the root, or the table is empty or unavailable';ru = 'Не удалось перейти на уровень выше. Текущая строка, вероятно, уже корневая, либо таблица пуста или недоступна'" );

endfunction

&atclient
function FailedToOpenValue () export

	return NStr ( "en = 'The specified control is not an input field';ru = 'Указанный элемент управления не является полем ввода'" );

endfunction

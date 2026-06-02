function Perform ( Log, Lang, SmartMode, AlreadyConnected ) export
	
	obj = Create ();
	obj.Log = Log;
	obj.Lang = Lang;
	obj.SmartMode = SmartMode;
	obj.AlreadyConnected = AlreadyConnected;
	return obj.Perform ();
	
endfunction 
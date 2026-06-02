function Perform ( Log, Lang, AlreadyConnected ) export
	
	obj = Create ();
	obj.Log = Log;
	obj.Lang = Lang;
	obj.AlreadyConnected = AlreadyConnected;
	return obj.Perform ();
	
endfunction 
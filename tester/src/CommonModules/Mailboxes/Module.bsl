
function SystemProfile () export
	
	profile = new InternetMailProfile ();
	profile.SMTPServerAddress = Cloud.SMTPServer ();
	profile.SMTPUser = Cloud.SMTPUser ();
	profile.SMTPPassword = Cloud.SMTPPassword ();
	profile.SMTPUseSSL = Cloud.SMTPSSL ();
	profile.SMTPPort = Cloud.SMTPPort ();
	return profile;
	
endfunction 

procedure Post ( Profile, Message ) export
	
	mail = new InternetMail ();
	mail.Logon ( Profile );
	mail.Send ( Message );
	mail.Logoff ();
	
endprocedure 

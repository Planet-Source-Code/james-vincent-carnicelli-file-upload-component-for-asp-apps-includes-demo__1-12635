<%

  Server.ScriptTimeout = 60 * 60  '60 minutes

  Set Upload = Server.CreateObject("Carnicelli.FileUpload")
  Upload.Save "C:\Temp", False

  Response.Redirect "file_upload_demo.asp?Message=Successfully+uploaded+" & Upload.FileCount & "&Text_1=" & _
   Server.URLEncode( Upload.Form("Text_1") )

%>
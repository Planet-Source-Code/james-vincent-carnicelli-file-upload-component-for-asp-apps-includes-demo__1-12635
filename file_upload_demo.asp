<TITLE>File Upload Demo</TITLE>

<H2>File Upload Demo</H2>

<B><%= Request("Message") %></B>
<BR><B><%= Request("Text_1") %></B>

<FORM METHOD="POST" ENCTYPE="multipart/form-data" ACTION="file_upload_demo2.asp">
<P><INPUT TYPE="FILE" NAME="File_1" SIZE="40">
<BR><INPUT TYPE="FILE" NAME="File_2" SIZE="40">
<BR>Type in anything: <INPUT NAME="Text_1">
<BR><INPUT TYPE="SUBMIT" VALUE="Upload">
</FORM>

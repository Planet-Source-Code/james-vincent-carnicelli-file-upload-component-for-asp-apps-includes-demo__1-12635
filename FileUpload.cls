VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 1  'NoTransaction
END
Attribute VB_Name = "FileUpload"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'################################################################
' Purpose: Library to manage web-based file uploads for ASP
' Created: 6 November 2000 by James Vincent Carnicelli
'################################################################

Option Explicit
Option Compare Text
Implements ObjectControl

'--------------------- Private Declarations ---------------------

Private propTotalBytes As Long
Private propPath As String
Private propForm As Object
Private propFile As Collection
Private ObjContext As ObjectContext


'----------------------- Public Properties ----------------------

'################################################################
'Purpose: How many bytes were downloaded
'################################################################
Public Property Get TotalBytes() As Long
    TotalBytes = propTotalBytes
End Property


'################################################################
'Purpose: Return the value of the form field
'################################################################
'Public Property Get Form() As Scripting.Dictionary
Public Property Get Form() As Object
    Set Form = propForm
End Property


'################################################################
'Purpose: Return the array of keys in the Form dictionary
'################################################################
Public Property Get FormKeys()
    FormKeys = propForm.Keys
End Property


'################################################################
'Purpose: Return the number of items in the Form dictionary
'################################################################
Public Property Get FormCount() As Integer
    FormCount = propForm.Count
End Property


'################################################################
'Purpose: Return the specified File object from the list
'################################################################
Public Property Get File(Index) As Object
    Set File = propFile(Index)
End Property


'################################################################
'Purpose: Return the number of files in the list
'################################################################
Public Property Get FileCount() As Long
    FileCount = propFile.Count
End Property


'------------------------ Public Methods ------------------------

'################################################################
'Purpose: Add a file definition to the list of files
'################################################################
Public Sub DefineFile(Path As String, MimeType As String)
    Dim CurrentFile As Carnicelli.File
    Set CurrentFile = New File
    CurrentFile.Init Me, propFile, "", Path, MimeType
    propFile.Add CurrentFile
End Sub


'################################################################
'Purpose: Import the MIME contents, including files
'################################################################
Public Sub Save(Path As String, AllowOverwrite As Boolean)
    Dim Buffer, Temp, Mode As String, Line As String, i As Long, j As Long
    Dim TotalBytes As Long, BytesLeft As Long, Pos As Long
    Dim Key As String, Value As String
    Dim MimeSeparator, MimeSeparatorAsString As String, FileHandle As Integer
    Dim Properties As Scripting.Dictionary, ByteArray() As Byte
    Dim Request As Object, FileSys
'    Dim CurrentFile As AgeNetWww_FileUpload_Test.File
    Dim CurrentFile As Carnicelli.File
    
    On Error GoTo RaiseError
    
    Class_Initialize
    
    Set ObjContext = GetObjectContext
    If ObjContext Is Nothing Then Err.Raise vbObjectError, "FileUpload.Save()", "Couldn't get object context, so couldn't get Request object"
    If IsEmpty(ObjContext.Item("Request")) Then Err.Raise vbObjectError, "FileUpload.Save()", _
      "This object is meant to be called by ASP pages only"

    Set Request = ObjContext.Item("Request")
    Set FileSys = CreateObject("Scripting.FileSystemObject")
    
    Buffer = Array()
    propPath = FileSys.GetAbsolutePathName(Path)
    If Right(propPath, 1) <> "\" Then propPath = propPath & "\"
    TotalBytes = Request.TotalBytes
    BytesLeft = TotalBytes
    
    
'Dim DH As Integer
'DH = FreeFile
'Open "C:\Temp\Mime_Output.txt" For Binary As DH
    
    
    Mode = "Start"
    Do Until Mode = "Done" Or BytesLeft = 0
    
        'Fetch more data
        If BytesLeft = 1 Then
            Temp = Request.BinaryRead(1)
            BytesLeft = 0
        ElseIf BytesLeft < 1024 Then
            Temp = Request.BinaryRead(BytesLeft - 1)
            BytesLeft = 1
        Else
            Temp = Request.BinaryRead(1024)
            BytesLeft = BytesLeft - 1024
        End If
        ArrayConcatenate Buffer, Temp
        
'Put #DH, , Temp

        'Process what's already available
        Do Until Mode = "Done"
        
            Select Case Mode
                
                Case "Start"
                    'Look for the end of the first line
                    Pos = ArrayFind(Buffer, 10)  'Search for <LF>
                    If Pos = 0 Then Exit Do
                    
                    'Get the first line, which is the separator
                    ArrayCopy MimeSeparator, Buffer, 0, Pos - 1
                    ArrayTrim Buffer, Pos + 1
                    MimeSeparatorAsString = ByteArrayToText(MimeSeparator)
                    'We'll need to prefix the MIME boundary separator with a
                    '<CR><LF> combination to help strip out the trailing new-line
                    ArrayInsert MimeSeparator, 0, 13
                    ArrayInsert MimeSeparator, 1, 10
                    
                    'Switch to get-field-header mode
                    Mode = "HeaderLine1"
            
                Case "Boundary"
                    If UBound(Buffer) < UBound(MimeSeparator) Then Exit Do
                    
                    'Look for the end of the next line
                    Pos = ArrayFind(Buffer, 10, 2)  'Search for <LF>
                    If BytesLeft = 0 Then
                        If Pos = 0 Then Pos = UBound(Buffer) + 2
                    Else
                        If Pos = 0 Then Exit Do
                    End If
                    
                    'Get the first line, which is the separator
                    ArrayCopy Temp, Buffer, 0, Pos - 1
                    ArrayTrim Buffer, Pos + 1
                    Line = ByteArrayToText(Temp)
                    
                    If Line = vbCrLf & MimeSeparatorAsString & "--" Then
                        'Indicate that we're done processing MIME stream
                        Mode = "Done"
                    ElseIf Line = vbCrLf & MimeSeparatorAsString Then
                        'Switch to get-field-header mode
                        Mode = "HeaderLine1"
                    Else
                        Err.Raise vbObjectError, "FileUpload.Save()", "Invalid MIME format: Unexpected end of stream"
                    End If
                    
                Case "HeaderLine1"
                    Pos = ArrayFind(Buffer, 10)  'Search for <LF>
                    If Pos = 0 Then Exit Do
                    
                    'Get the next line
                    ArrayCopy Temp, Buffer, 0, Pos - 1
                    ArrayTrim Buffer, Pos + 1
                    Line = ByteArrayToText(Temp)
                    
                    'Validate the line
                    If UCase(Left(Line, 21)) <> "CONTENT-DISPOSITION: " Then
                        Err.Raise vbObjectError, "FileUpload.Save()", "Invalid MIME format: Expecting ""Content-Disposition:"", but found """ & Left(Line, 25) & "..."""
                    End If
                    
                    Line = Mid(Line, 22)
                    Temp = Split(Line, "; ")
                    Set Properties = New Dictionary
                    Properties("ContentDisposition") = Temp(0)
                    For i = 1 To UBound(Temp)
                        Value = Temp(i)
                        Pos = InStr(1, Value, "=")
                        If Pos <> 0 Then
                            Key = Trim(Left(Value, Pos - 1))
                            Value = Trim(Mid(Value, Pos + 1))
                            'Strip away double-quotes
                            If Left(Value, 1) = """" Then Value = Mid(Value, 2, Len(Value) - 2)
                        End If
                        Properties(Key) = Value
                    Next
                    
                    'Switch to rest-of-header mode
                    Mode = "RestOfHeader"
                
                Case "RestOfHeader"
                    Pos = ArrayFind(Buffer, 10)  'Search for <LF>
                    If Pos = 0 Then Exit Do
                    
                    'Get the next line
                    ArrayCopy Temp, Buffer, 0, Pos - 1
                    ArrayTrim Buffer, Pos + 1
                    Line = ByteArrayToText(Temp)
                    
                    'Have we reached the end of the header?
                    If Line = "" Then
                        
                        'If this form field was for a file, let's have the value indicate this
                        If Properties.Exists("filename") Then
                            If Properties("filename") = "" Then
                                Value = "<FILE_NOT_UPLOADED>"
                            Else
                                Value = "<FILE_UPLOADED>"
                            End If
                        Else
                            Value = ""
                        End If
                        
                        If Properties("filename") = "" Then
                            Mode = "Value"
                        Else
                            Mode = "File"

                            'Determine the new file's name
                            Properties("SourcePath") = Properties("filename")
                            Temp = Split(Properties("filename"), "\")
                            Properties("FileName") = Temp(UBound(Temp))
                            
                            Temp = Split(Temp(UBound(Temp)), ".")
                            If Not AllowOverwrite Then
                                If FileSys.FileExists(propPath & Join(Temp, ".")) Then
                                    'Find a unique file name
                                    i = 1
                                    ArrayInsert Temp, UBound(Temp), i
                                    Do While FileSys.FileExists(propPath & Join(Temp, "."))
                                        i = i + 1
                                        Temp(UBound(Temp) - 1) = i
                                    Loop
                                End If
                            End If
                            Temp = Join(Temp, ".")
                            
                            Set CurrentFile = New File
                            CurrentFile.Init Me, propFile, Properties("SourcePath"), propPath & Temp, Properties("content-type")
                            propFile.Add CurrentFile
                            
                            'Create or empty the file and open it for output
                            FileHandle = FreeFile
                            Open propPath & Temp For Output As FileHandle:  Close #FileHandle
                            Open propPath & Temp For Binary As FileHandle
                        
                        End If
                    Else
                        Temp = Split(Line, ": ")
                        Properties(Temp(0)) = Temp(1)
                    End If
                
                Case "File", "Value"
                    If UBound(Buffer) < 0 Then Exit Do
                    Pos = ArrayFind(Buffer, 10, 2)  'Search for <LF>
                    If Pos = 0 Then
                        'Check for the MIME boundary separator
                        If ArrayBeginsWith(Buffer, MimeSeparator) Then
                            If FileHandle <> 0 Then
                                Close #FileHandle
                                FileHandle = 0
                            End If
                            propForm(Properties("name")) = Value
                            Mode = "Boundary"
                        ElseIf UBound(Buffer) < UBound(MimeSeparator) Then
                            Exit Do
                        Else
                            If Mode = "File" Then
                                ArrayCopy ByteArray, Buffer
                                Buffer = Array()
                                Put #FileHandle, , ByteArray
                            Else
                                ArrayCopy Temp, Buffer
                                Buffer = Array()
                                Value = Value & ByteArrayToText(Temp)
                            End If
                        End If
                    Else
                        'Check for the MIME boundary separator
                        If UBound(Buffer) >= UBound(MimeSeparator) Then
                            If ArrayBeginsWith(Buffer, MimeSeparator) Then
                                If FileHandle <> 0 Then
                                    Close #FileHandle
                                    FileHandle = 0
                                End If
                                propForm(Properties("name")) = Value
                                'Switch to item-boundary mode
                                Mode = "Boundary"
                            Else
                                If Mode = "File" Then
                                    ArrayCopy ByteArray, Buffer, 0, Pos - 1
                                    ArrayTrim Buffer, Pos - 1
                                    Put #FileHandle, , ByteArray
                                Else
                                    ArrayCopy Temp, Buffer, 0, Pos - 1
                                    ArrayTrim Buffer, Pos - 1
                                    Value = Value & ByteArrayToText(Temp)
                                End If
                            End If
                        Else
                            If ArrayBeginsWith(MimeSeparator, Buffer) Then
                                If FileHandle <> 0 Then
                                    Close #FileHandle
                                    FileHandle = 0
                                End If
                                propForm(Properties("name")) = Value
                                Mode = "Boundary"
                            Else
                                If Mode = "File" Then
                                    ArrayCopy ByteArray, Buffer
                                    Buffer = Array()
                                    Put #FileHandle, , ByteArray
                                Else
                                    ArrayCopy Temp, Buffer
                                    Buffer = Array()
                                    Value = Value & ByteArrayToText(Temp)
                                End If
                            End If
                        End If
                    End If
                
            End Select
        Loop
    
    Loop

Exit Sub
RaiseError:
    If FileHandle <> 0 Then
        Close #FileHandle
        CurrentFile.Delete
    End If
    Err.Raise Err.Number, Err.Source, Err.Description
End Sub


'------------------------ Private Methods -----------------------


'-------------------- Private Event Handlers --------------------

'################################################################
'Purpose: Initialize the class
'################################################################
Private Sub Class_Initialize()
    Set propFile = New Collection
    Set propForm = New Dictionary
End Sub


'################################################################
'Purpose: Deal with ObjectControl interface
'
'Based on sample found at:
'  http://msdn.microsoft.com/workshop/server/components/vbmtsiis.asp
'################################################################
Private Sub ObjectControl_Activate()
'    Set ObjContext = GetObjectContext
'    If ObjContext Is Nothing Then Err.Raise 91  'Error if failed
End Sub
Private Function ObjectControl_CanBePooled() As Boolean
    ObjectControl_CanBePooled = False  'don't pool for now
End Function
Private Sub ObjectControl_Deactivate()
'    Set ObjContext = Nothing 'release
End Sub




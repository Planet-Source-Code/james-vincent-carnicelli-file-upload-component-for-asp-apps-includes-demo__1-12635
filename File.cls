VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 1  'NoTransaction
END
Attribute VB_Name = "File"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'################################################################
' Purpose: Interface to uploaded file
' Created: 6 November 2000 by James Vincent Carnicelli
'################################################################

Option Explicit

'--------------------- Private Declarations ---------------------

Private Parent As FileUpload
Private Files As Collection

Private propPath As String
Private propSourcePath As String
Private propMimeType As String


'----------------------- Public Properties ----------------------

'################################################################
'Purpose: Return the path to the file
'################################################################
Public Property Get Path() As String
    Path = propPath
End Property


'################################################################
'Purpose: Return the path to the file
'################################################################
Public Property Get PathSansFile() As String
    Dim Temp
    Temp = Split(propPath, "\")
    ArrayTrim Temp, , 1
    PathSansFile = Join(Temp, "\") & "\"
End Property


'################################################################
'Purpose: Return the path to the file
'################################################################
Public Property Get SourcePath() As String
    SourcePath = propSourcePath
End Property


'################################################################
'Purpose: Return the MIME content type
'################################################################
Public Property Get MimeType() As String
    MimeType = propMimeType
End Property


'################################################################
'Purpose: Return the file's size
'################################################################
Public Property Get Size() As Long
    Dim File As Scripting.File, FileSys
    Set FileSys = CreateObject("Scripting.FileSystemObject")
    Set File = FileSys.GetFile(propPath)
    Size = File.Size
End Property


'################################################################
'Purpose: Get the path to the file
'################################################################
Public Property Get FileName() As String
    Dim Pos As Long
    Pos = InStrRev(propPath, "\")
    If Pos = 0 Then
        FileName = propPath
    Else
        FileName = Mid(propPath, Pos + 1)
    End If
End Property


'################################################################
'Purpose: Get the path to the file
'################################################################
Public Property Get Extension() As String
    Dim Pos As Long
    Pos = InStrRev(propPath, ".")
    If Pos = 0 Then Exit Property  'No extension
    Extension = Mid(propPath, Pos + 1)
End Property


'------------------------ Public Methods ------------------------

'################################################################
'Purpose: Load the file into memory and return as a plain-text
'  string
'################################################################
Public Function LoadAsText() As String
    LoadAsText = ReadFile(Path)
End Function


'################################################################
'Purpose: Delete this file and remove it from the file list
'################################################################
Public Sub Delete()
    Dim File As Scripting.File, FileSys, i As Long
    Set FileSys = CreateObject("Scripting.FileSystemObject")
    Set File = FileSys.GetFile(propPath)
    File.Delete True
    For i = 1 To Files.Count
        If Files(i).Path = propPath Then
            Files.Remove i
            Exit Sub
        End If
    Next
End Sub


'################################################################
'Purpose: Rename this file
'################################################################
Public Sub Rename(NewFileName, Optional AllowOverwrite As Boolean = False)
    Dim File As Scripting.File, FileSys, Temp
    Set FileSys = CreateObject("Scripting.FileSystemObject")
    Set File = FileSys.GetFile(propPath)
    Temp = Split(propPath, "\")
    Temp(UBound(Temp)) = NewFileName
    propPath = Join(Temp, "\")
    If AllowOverwrite And FileSys.FileExists(propPath) Then
        FileSys.DeleteFile propPath, True
    End If
    File.Move propPath
End Sub


'################################################################
'Purpose: Move this file and/or give it a new name
'################################################################
Public Sub Move(NewPath, Optional AllowOverwrite As Boolean = False)
    Dim File As Scripting.File, FileSys
    Set FileSys = CreateObject("Scripting.FileSystemObject")
    Set File = FileSys.GetFile(propPath)
    propPath = NewPath
    If AllowOverwrite And FileSys.FileExists(propPath) Then
        FileSys.DeleteFile propPath, True
    End If
    File.Move propPath
End Sub


'------------------------ Hidden Methods ------------------------

'################################################################
'Purpose: Initialize this object
'################################################################
Public Sub Init(newParent As FileUpload, newFiles As Collection, newSourcePath As String, NewPath As String, newMimeType)
Attribute Init.VB_MemberFlags = "40"
    Set Parent = newParent
    Set Files = newFiles
    propPath = NewPath
    propSourcePath = newSourcePath
    propMimeType = newMimeType
End Sub


'------------------------ Private Methods -----------------------


'-------------------- Private Event Handlers --------------------

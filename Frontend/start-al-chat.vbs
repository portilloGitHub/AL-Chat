' AL-Chat Hidden Launcher
' Runs the batch file without showing a terminal window
' Automatically starts backend first, then frontend
' Double-click this file to start AL-Chat like a normal Windows application

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Get the directory where this script is located
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
batchFile = scriptDir & "\start-al-chat.bat"

' Check if batch file exists
If Not fso.FileExists(batchFile) Then
    MsgBox "Error: Could not find start-al-chat.bat" & vbCrLf & vbCrLf & _
           "Expected location:" & vbCrLf & batchFile, vbCritical, "AL-Chat Launcher Error"
    WScript.Quit 1
End If

' Change to the script directory
WshShell.CurrentDirectory = scriptDir

' Run the batch file hidden
' WindowStyle = 0: Hidden window
' WaitOnReturn = True: Wait for batch file to finish
' The batch file will automatically start backend first, then frontend
On Error Resume Next
exitCode = WshShell.Run("""" & batchFile & """", 0, True)
On Error Goto 0

' If there was an error (exit code > 0), show a message
' Note: Most errors will be handled by the batch file itself
' This is just a fallback for critical failures
If exitCode > 0 And exitCode <> 1 Then
    ' Don't show message for normal exit codes
    ' Only show for unexpected errors
End If

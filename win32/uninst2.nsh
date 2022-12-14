# NSIS installer script for Nonpareil
# Code to uninstall only installed files: part 2 of 2
# Copyright 2008 Eric Smith <eric@brouhaha.com>
# $Id$

# This script was derived from one in the NSIS wiki, retrieved
# on 31-JUL-2008:
#   http://nsis.sourceforge.net/Uninstall_only_installed_files

# This script should be included after the normal sections in main script,
# but before the Uninstall section.  The function un.UninstallFiles should be
# called from the Uninstall section.

Section -closelogfile
 FileClose $UninstLog
 SetFileAttributes "$INSTDIR\${UninstLog}" READONLY|SYSTEM|HIDDEN
SectionEnd
 
function un.UninstallFiles
 ; Can't uninstall if uninstall log is missing!
 IfFileExists "$INSTDIR\${UninstLog}" +3
  MessageBox MB_OK|MB_ICONSTOP "$(UninstLogMissing)"
   Abort
 
 Push $R0
 Push $R1
 Push $R2
 SetFileAttributes "$INSTDIR\${UninstLog}" NORMAL
 FileOpen $UninstLog "$INSTDIR\${UninstLog}" r
 StrCpy $R1 0
 
 GetLineCount:
  ClearErrors
   FileRead $UninstLog $R0
   IntOp $R1 $R1 + 1
   IfErrors 0 GetLineCount
 
 LoopRead:
  FileSeek $UninstLog 0 SET
  StrCpy $R2 0
  FindLine:
   FileRead $UninstLog $R0
   IntOp $R2 $R2 + 1
   StrCmp $R1 $R2 0 FindLine
 
   StrCpy $R0 $R0 -2
   IfFileExists "$R0\*.*" 0 +3
    RMDir $R0  #is dir
   Goto +3
   IfFileExists $R0 0 +2
    Delete $R0 #is file
 
  IntOp $R1 $R1 - 1
  StrCmp $R1 0 LoopDone
  Goto LoopRead
 LoopDone:
 FileClose $UninstLog
 Delete "$INSTDIR\${UninstLog}"
 RMDir "$INSTDIR"
 Pop $R2
 Pop $R1
 Pop $R0
FunctionEnd

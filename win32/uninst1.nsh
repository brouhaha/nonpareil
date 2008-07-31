# NSIS installer script for Nonpareil
# Code to uninstall only installed files: part 1 of 2
# Copyright 2008 Eric Smith <eric@brouhaha.com>
# $Id$

# This script was derived from one in the NSIS wiki, retrieved
# on 31-JUL-2008:
#   http://nsis.sourceforge.net/Uninstall_only_installed_files

# This script should be included before sections in main script.

# Instead of using SetOutPath, CreateDirectory, File, CopyFiles and Rename
# instructions in your sections, use ${SetOutPath}, ${CreateDirectory},
# ${File}, ${CopyFiles} and ${Rename} instead.
#
# When using ${SetOutPath} to create more than one upper level directory,
# e.g.:
#     ${SetOutPath} "$INSTDIR\dir1\dir2\dir3"
# you need to add entries for each lower level directory for them all to be
# deleted:
#    ${AddItem} "$INSTDIR\dir1"
#    ${AddItem} "$INSTDIR\dir1\dir2"
#    ${SetOutPath} "$INSTDIR\dir1\dir2\dir3"
#
# This is an example of what your sections may now look like:
#
#    Section "Install Main"
#    SectionIn RO
#      ${SetOutPath} $INSTDIR
#      ${WriteUninstaller} "uninstall.exe"
#      ${File} "dir1\" "file1.ext"
#      ${File} "dir1\" "file2.ext"
#      ${File} "dir1\" "file3.ext"
#    SectionEnd
#
#    Section "Install Other"
#      ${AddItem} "$INSTDIR\Other"
#      ${SetOutPath} "$INSTDIR\Other\Temp"
#      ${File} "dir2\" "file4.ext"
#      ${File} "dir2\" "file5.ext"
#      ${File} "dir2\" "file6.ext"
#    SectionEnd
# 
#    Section "Copy Files & Rename"
#      ${CreateDirectory} "$INSTDIR\backup"
#      ${CopyFiles} "$INSTDIR\file1.ext" "$INSTDIR\backup\file1.ext"
#      ${Rename} "$INSTDIR\file2.ext" "$INSTDIR\file1.ext"
#    SectionEnd

!define UninstLog "uninstall.log"
Var UninstLog
 
; Uninstall log file missing.
LangString UninstLogMissing ${LANG_ENGLISH} "${UninstLog} not found!$\r$\nUninstallation cannot proceed!"
 
; AddItem macro
!macro AddItem Path
 FileWrite $UninstLog "${Path}$\r$\n"
!macroend
!define AddItem "!insertmacro AddItem"
 
; File macro
!macro File FilePath FileName SrcFilePathName
 FileWrite $UninstLog "$OUTDIR\${FilePath}${FileName}$\r$\n"
 File "${SrcFilePathName}"
!macroend
!define File "!insertmacro File"

; CreateShortCut macro
!macro CreateShortCut FileName Target
 FileWrite $UninstLog "$OUTDIR\${FileName}$\r$\n"
 CreateShortCut "${FileName}" "${Target}"
!macroend
!define CreateShortCut "!insertmacro CreateShortCut"
 
; Copy files macro
!macro CopyFiles SourcePath DestPath
 IfFileExists "${DestPath}" +2
  FileWrite $UninstLog "${DestPath}$\r$\n"
 CopyFiles "${SourcePath}" "${DestPath}"
!macroend
!define CopyFiles "!insertmacro CopyFiles"
 
; Rename macro
!macro Rename SourcePath DestPath
 IfFileExists "${DestPath}" +2
  FileWrite $UninstLog "${DestPath}$\r$\n"
 Rename "${SourcePath}" "${DestPath}"
!macroend
!define Rename "!insertmacro Rename"
 
; CreateDirectory macro
!macro CreateDirectory Path
 CreateDirectory "${Path}"
 FileWrite $UninstLog "${Path}$\r$\n"
!macroend
!define CreateDirectory "!insertmacro CreateDirectory"
 
; SetOutPath macro
!macro SetOutPath Path
 SetOutPath "${Path}"
 FileWrite $UninstLog "${Path}$\r$\n"
!macroend
!define SetOutPath "!insertmacro SetOutPath"
 
; WriteUninstaller macro
!macro WriteUninstaller Path
 WriteUninstaller "${Path}"
 FileWrite $UninstLog "${Path}$\r$\n"
!macroend
!define WriteUninstaller "!insertmacro WriteUninstaller"
 
Section -openlogfile
 CreateDirectory "$INSTDIR"
 IfFileExists "$INSTDIR\${UninstLog}" +3
  FileOpen $UninstLog "$INSTDIR\${UninstLog}" w
 Goto +4
  SetFileAttributes "$INSTDIR\${UninstLog}" NORMAL
  FileOpen $UninstLog "$INSTDIR\${UninstLog}" a
  FileSeek $UninstLog 0 END
SectionEnd

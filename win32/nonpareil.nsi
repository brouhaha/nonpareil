# NSIS installer script for Nonpareil
# Copyright 2008 Eric Smith <eric@brouhaha.com>
# $Id$

# This NSIS script is loosely based on one originally generated by
# Christoph Giesselink using the HM NIS Edit Script Wizard.

# some variables must be defined on the makensis command line:
#     RELEASE
#     BUILD_DIR
#     LICENSE_FILE

# We're invoked in the the win32 directory, but we need to be at the top
!cd ..

; HM NIS Edit Wizard helper defines
!define PRODUCT_NAME "Nonpareil"
!define PRODUCT_VERSION ${RELEASE}
!define PRODUCT_WEB_SITE "http://nonpareil.brouhaha.com/"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\${PRODUCT_NAME}.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define PRODUCT_STARTMENU_REGVAL "StartMenuDir"

SetCompress auto
SetCompressor lzma

Name "${PRODUCT_NAME} ${RELEASE}"
OutFile "${BUILD_DIR}/${PRODUCT_NAME}-${RELEASE}-setup.exe"
InstallDir "$PROGRAMFILES\${PRODUCT_NAME}"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
BrandingText "nonpareil.brouhaha.com"
;ShowInstDetails show
;ShowUnInstDetails show
CRCCheck force

; installation file properties
VIProductVersion "${RELEASE}.0.0"
VIAddVersionKey "CompanyName" "Eric Smith"
VIAddVersionKey "FileDescription" "Nonpareil Calculator Simulator Installation"
VIAddVersionKey "FileVersion" "${RELEASE}"
VIAddVersionKey "InternalName" "${PRODUCT_NAME}-${RELEASE}-Setup"
VIAddVersionKey "LegalCopyright" "Copyright � 2008"
VIAddVersionKey "OriginalFilename" "${PRODUCT_NAME}-${RELEASE}-Setup.exe"
VIAddVersionKey "ProductName" "${PRODUCT_NAME}-${RELEASE}-Setup"
VIAddVersionKey "ProductVersion" "${RELEASE}"

; MUI 1.67 compatible ------
!include "MUI.nsh"
!include "FileFunc.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install-blue.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall-blue.ico"

; Welcome page
!insertmacro MUI_PAGE_WELCOME

; License page
;!insertmacro MUI_PAGE_LICENSE ${LICENSE_FILE}

; Components page
!insertmacro MUI_PAGE_COMPONENTS

; Directory page
!insertmacro MUI_PAGE_DIRECTORY

; Start menu page
var ICONS_GROUP
!define MUI_STARTMENUPAGE_NODISABLE
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "${PRODUCT_NAME}"
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "${PRODUCT_UNINST_ROOT_KEY}"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "${PRODUCT_UNINST_KEY}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "${PRODUCT_STARTMENU_REGVAL}"
!insertmacro MUI_PAGE_STARTMENU Application $ICONS_GROUP

; Instfiles page
!insertmacro MUI_PAGE_INSTFILES

; Finish page
;!define MUI_FINISHPAGE_NOAUTOCLOSE
;!define MUI_FINISHPAGE_RUN "$INSTDIR\${PRODUCT_NAME}.exe"
;!define MUI_FINISHPAGE_RUN_NOTCHECKED
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
!define MUI_FINISHPAGE_LINK_COLOR 0000FF
!define MUI_FINISHPAGE_LINK "Visit the Nonpareil site for the latest news."
!define MUI_FINISHPAGE_LINK_LOCATION "${PRODUCT_WEB_SITE}"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Delete Simulator State Files"
!define MUI_FINISHPAGE_RUN_FUNCTION un.DeleteStateFiles
;!define MUI_FINISHPAGE_RUN_NOTCHECKED
!insertmacro MUI_UNPAGE_FINISH

; Language files
!insertmacro MUI_LANGUAGE "English"

; Reserve files
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

; MUI end ------

# include part 1 of code to automatically uninstall only installed files
!include "win32/uninst1.nsh"

InstType "Full"

Section "Program Files" SecMain
  SetDetailsPrint textonly
  DetailPrint "Installing Nonpareil Core Files..."
  SetDetailsPrint listonly

  SectionIn 1 2 3 4 5 6 RO
  SetOutPath "$INSTDIR"
  SetOverwrite on
  
  # File commands automatically generated
  !include "${BUILD_DIR}/inst_file_cmds.nsh"

; Shortcuts
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
  ${CreateDirectory} "$SMPROGRAMS\$ICONS_GROUP"
  ${CreateShortCut} "$SMPROGRAMS\$ICONS_GROUP\Nonpareil.lnk" "$INSTDIR\nonpareil.exe"
  ${CreateShortCut} "$DESKTOP\Nonpareil.lnk" "$INSTDIR\nonpareil.exe"
  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

Section -AdditionalIcons
  SetDetailsPrint textonly
  DetailPrint "Creating Shortcuts..."
  SetDetailsPrint listonly

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
  ${CreateShortCut} "$SMPROGRAMS\$ICONS_GROUP\Readme.lnk" "$INSTDIR\README"
  ${CreateShortCut} "$SMPROGRAMS\$ICONS_GROUP\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
  ${CreateShortCut} "$SMPROGRAMS\$ICONS_GROUP\Uninstall.lnk" "$INSTDIR\uninst.exe"
  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

Section -Post
  ${WriteUninstaller} "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\nonpareil.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\nonpareil.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
SectionEnd

; Section descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain}    "The main program files with documentation."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

# include part 2 of code to automatically uninstall only installed files
!include "win32/uninst2.nsh"

; delete application settings
Function un.DeleteStateFiles
  StrCmp $PROFILE "" noprofile
    Delete "$PROFILE\nonpareil\*.*"
    RMDir "$PROFILE\nonpareil"
  noprofile:
FunctionEnd

Section Uninstall
  !insertmacro MUI_STARTMENU_GETFOLDER "Application" $ICONS_GROUP
  
  SetDetailsPrint textonly
  DetailPrint "Deleting Files..."
  SetDetailsPrint listonly

  Call un.UninstallFiles

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  SetAutoClose true
SectionEnd

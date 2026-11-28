# The Windows installer of an OpenModelica install tree. Build it with
# .CI/scripts/windows-installer.sh, which generates FILES with files.py.
#
# Several versions can be installed side by side: the version is part of the
# registry keys, the OPENMODELICAHOME_<version> environment variable, the
# default directory and the start menu folder. The component "Default
# installation" makes this installation the one OPENMODELICAHOME points to and
# the one that opens .mo and .onb files.
#
# Command line options, in addition to /S and /D=<directory>:
#   /DEFAULT=0        do not make this installation the default one
#   /REMOVENIGHTLIES  with /S: uninstall the other nightly builds
#
# The uninstaller does not depend on FILES, so it can be signed before the
# installer is built: with UNINSTALLER_ONLY, OUTFILE only writes Uninstall.exe
# next to itself, and UNINSTALLER=<that file> installs it instead of writing one.

Unicode true
SetCompressor /SOLID /FINAL lzma
SetCompressorDictSize 64

!ifndef OMVERSION
  !error "Define OMVERSION, the version without the leading v, e.g. 1.28.0 or 1.28.0-dev-2179-g7fab34bdf5"
!endif
!ifndef PRODUCTVERSION
  !error "Define PRODUCTVERSION, the version as X.X.X.X"
!endif
!ifndef FILES
  !error "Define FILES, the output of files.py"
!endif
!ifndef OUTFILE
  !error "Define OUTFILE, the installer to write"
!endif
!ifdef UNINSTALLER
  # MultiUser.nsh defines un. functions whether or not there is an uninstaller.
  !pragma warning disable 6020
!endif

Name "OpenModelica ${OMVERSION}"
!define VERSION "${OMVERSION}"
# A sibling of SOFTWARE\OpenModelica and not a subkey of it: the uninstallers
# of the older releases delete the entire SOFTWARE\OpenModelica key.
!define REGKEY "SOFTWARE\OpenModelica ${VERSION}"
!searchreplace OMVERSION_ENV "${OMVERSION}" "." "_"
!searchreplace OMVERSION_ENV "${OMVERSION_ENV}" "-" "_"
!searchreplace OMVERSION_ENV "${OMVERSION_ENV}" "+" "_"
!searchreplace OMVERSION_ENV "${OMVERSION_ENV}" "~" "_"
!define ENV_OMHOME_VERSION "OPENMODELICAHOME_${OMVERSION_ENV}"
!ifdef OMNIGHTLY
  !define NIGHTLY 1
!else
  !define NIGHTLY 0
!endif
!define COMPANY "Open Source Modelica Consortium (OSMC) and Linköping University (LiU)."
!define URL "https://openmodelica.org/"
BrandingText "OpenModelica ${OMVERSION}"

!define MULTIUSER_EXECUTIONLEVEL Highest
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_DEFAULT_CURRENTUSER
!define MULTIUSER_INSTALLMODE_COMMANDLINE

!define MUI_ICON "${__FILEDIR__}/../../OMEdit/OMEditLIB/Resources/icons/omedit.ico"
!define MUI_UNICON "${MUI_ICON}"
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_WELCOMEPAGE_TEXT "The installer will guide you through the steps required to install $(^Name) on your computer.$\r$\n$\r$\n$\r$\nThe package includes OpenModelica, a Modelica modeling, compilation and simulation environment based on free software."
!define MUI_STARTMENUPAGE_REGISTRY_ROOT SHCTX
!define MUI_STARTMENUPAGE_NODISABLE
!define MUI_STARTMENUPAGE_REGISTRY_KEY "${REGKEY}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME StartMenuGroup
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "OpenModelica ${OMVERSION}"
!define MUI_FINISHPAGE_TITLE_3LINES
!include "${FILES}"
!ifdef OM_HAVE_OMEDIT
  !define MUI_FINISHPAGE_RUN
  !define MUI_FINISHPAGE_RUN_TEXT "Start OpenModelica Connection Editor (OMEdit)"
  !define MUI_FINISHPAGE_RUN_FUNCTION "LaunchOMEdit"
!endif
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

!define SHCNE_ASSOCCHANGED 0x08000000
!define SHCNF_FLUSH        0x1000

!include MultiUser.nsh
!include Sections.nsh
!include MUI2.nsh
!include LogicLib.nsh
!include FileFunc.nsh
!include WinMessages.nsh

!define ENV_HKLM 'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
!define ENV_HKCU 'HKCU "Environment"'

Var StartMenuGroup
Var RemoveNightlies ; 1 if a silent install should remove the other nightly builds
Var UninstLog
!ifndef UNINSTALLER
Var un.WasDefault   ; 1 if OPENMODELICAHOME pointed to the installation that is removed
Var un.HadFileAssoc ; 1 if the .mo files were opened by the installation that is removed
Var un.NewDefault   ; the installation that takes over as default, if any
!endif

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuGroup
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!ifndef UNINSTALLER
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
!endif
!insertmacro MUI_LANGUAGE English

OutFile "${OUTFILE}"
CRCCheck on
XPStyle on
ShowInstDetails hide
ShowUninstDetails hide
VIProductVersion ${PRODUCTVERSION}
VIAddVersionKey ProductName "OpenModelica"
VIAddVersionKey ProductVersion "${VERSION}"
VIAddVersionKey CompanyName "${COMPANY}"
VIAddVersionKey CompanyWebsite "${URL}"
VIAddVersionKey FileVersion "${VERSION}"
VIAddVersionKey FileDescription ""
VIAddVersionKey LegalCopyright ""

!define UNINSTALL_ROOT "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
; the name of the key used by the releases that could not be installed side by side
!define UNINSTALL_NAME_LEGACY "OpenModelica"
!define UNINSTALL_NAME "OpenModelica ${VERSION}"
!define UNINSTALL_PATH "${UNINSTALL_ROOT}\${UNINSTALL_NAME}"

## The uninstall log ############################################################
# Everything the installer creates is written to uninstall.log, and the
# uninstaller removes what the log lists, so files the user added are kept.
!define UninstLog "uninstall.log"
LangString UninstLogMissing ${LANG_ENGLISH} "${UninstLog} not found!$\r$\nUninstallation cannot proceed!"

!macro AddItem Path
  FileWrite $UninstLog "${Path}$\r$\n"
!macroend
!define AddItem "!insertmacro AddItem"

!macro File LocalFileName InstalledFileName
  IfFileExists "$OUTDIR\${InstalledFileName}" +2
  FileWrite $UninstLog "$OUTDIR\${InstalledFileName}$\r$\n"
  File "${LocalFileName}"
!macroend
!define File "!insertmacro File"

!macro CreateShortcut FilePath FilePointer Parameters Icon IconIndex
  FileWrite $UninstLog "${FilePath}$\r$\n"
  CreateShortcut "${FilePath}" "${FilePointer}" "${Parameters}" "${Icon}" "${IconIndex}"
!macroend
!define CreateShortcut "!insertmacro CreateShortcut"

!macro CreateDirectory Path
  CreateDirectory "${Path}"
  FileWrite $UninstLog "${Path}$\r$\n"
!macroend
!define CreateDirectory "!insertmacro CreateDirectory"

!macro SetOutPath Path
  SetOutPath "${Path}"
  FileWrite $UninstLog "${Path}$\r$\n"
!macroend
!define SetOutPath "!insertmacro SetOutPath"

!macro WriteUninstaller Path
  WriteUninstaller "${Path}"
  FileWrite $UninstLog "${Path}$\r$\n"
!macroend
!define WriteUninstaller "!insertmacro WriteUninstaller"

!macro WriteIniStr IniFile SectionName EntryName NewValue
  IfFileExists "${IniFile}" +2
  FileWrite $UninstLog "${IniFile}$\r$\n"
  WriteIniStr "${IniFile}" "${SectionName}" "${EntryName}" "${NewValue}"
!macroend
!define WriteIniStr "!insertmacro WriteIniStr"

!macro WriteRegStr RegRoot UnInstallPath Key Value
  FileWrite $UninstLog "${RegRoot} ${UnInstallPath}$\r$\n"
  WriteRegStr "${RegRoot}" "${UnInstallPath}" "${Key}" "${Value}"
!macroend
!define WriteRegStr "!insertmacro WriteRegStr"

!macro WriteRegDWORD RegRoot UnInstallPath Key Value
  FileWrite $UninstLog "${RegRoot} ${UnInstallPath}$\r$\n"
  WriteRegDWORD "${RegRoot}" "${UnInstallPath}" "${Key}" "${Value}"
!macroend
!define WriteRegDWORD "!insertmacro WriteRegDWORD"

## File associations ############################################################
# Per user or for all users like the rest of the installation: SHCTX is HKCU or
# HKLM, and HKCR is the merged view of their Software\Classes.
!macro RegisterExtension EXE EXT DESC
  WriteRegStr SHCTX "Software\Classes\${EXT}" "" "${DESC}"
  WriteRegStr SHCTX "Software\Classes\${DESC}" "" "${DESC}"
  WriteRegStr SHCTX "Software\Classes\${DESC}\DefaultIcon" "" "${EXE},0"
  WriteRegStr SHCTX "Software\Classes\${DESC}\shell\open\command" "" '"${EXE}" "%1"'
!macroend

!macro UnregisterExtension EXT DESC
  ReadRegStr $R0 SHCTX "Software\Classes\${EXT}" ""
  ${If} $R0 == "${DESC}"
    DeleteRegKey SHCTX "Software\Classes\${EXT}"
  ${EndIf}
  DeleteRegKey SHCTX "Software\Classes\${DESC}"
!macroend

!macro UpdateFileAssociations
  System::Call "shell32::SHChangeNotify(i,i,i,i) (${SHCNE_ASSOCCHANGED}, ${SHCNF_FLUSH}, 0, 0)"
!macroend

!macro RegisterExtensions OMHOME
  ${If} ${FileExists} "${OMHOME}\bin\OMEdit.exe"
    !insertmacro RegisterExtension "${OMHOME}\bin\OMEdit.exe" ".mo" "OpenModelica Connection Editor"
  ${EndIf}
  ${If} ${FileExists} "${OMHOME}\bin\OMNotebook.exe"
    !insertmacro RegisterExtension "${OMHOME}\bin\OMNotebook.exe" ".onb" "OpenModelica Notebook"
  ${EndIf}
  !insertmacro UpdateFileAssociations
!macroend

## Installer sections ###########################################################
Section -openlogfile
  CreateDirectory "$INSTDIR"
  IfFileExists "$INSTDIR\${UninstLog}" +3
    FileOpen $UninstLog "$INSTDIR\${UninstLog}" w
  Goto +4
    SetFileAttributes "$INSTDIR\${UninstLog}" NORMAL
    FileOpen $UninstLog "$INSTDIR\${UninstLog}" a
    FileSeek $UninstLog 0 END
SectionEnd

Section "OpenModelica" SectionCore
  SectionIn RO
  SetOverwrite on
  !insertmacro OM_INSTALL_FILES
SectionEnd

!ifdef OM_HAVE_USERSGUIDE
Section "User's Guide" SectionUsersGuide
  SetOverwrite on
  !insertmacro OM_INSTALL_USERSGUIDE_FILES
SectionEnd
!endif

Section -Main
  ${AddItem} "$INSTDIR\InstallMode.txt"
  FileOpen $4 "$INSTDIR\InstallMode.txt" w
  FileWrite $4 $MultiUser.InstallMode
  FileClose $4
  # BUILTIN\Users get full access, inherited by everything below $INSTDIR.
  nsExec::ExecToLog 'icacls "$INSTDIR" /grant *S-1-5-32-545:(OI)(CI)F /Q'
  Pop $0
  DeleteRegValue ${ENV_HKCU} OPENMODELICALIBRARY
  DeleteRegValue ${ENV_HKLM} OPENMODELICALIBRARY
  ${If} $MultiUser.InstallMode == "AllUsers"
    WriteRegExpandStr ${ENV_HKLM} "${ENV_OMHOME_VERSION}" "$INSTDIR\"
  ${Else}
    WriteRegExpandStr ${ENV_HKCU} "${ENV_OMHOME_VERSION}" "$INSTDIR\"
  ${EndIf}
SectionEnd

Section -post
  ${WriteRegStr} SHCTX "${REGKEY}" Path $INSTDIR
  !ifdef UNINSTALLER
    SetOutPath "\\?\$INSTDIR"
    ${File} "${UNINSTALLER}" "Uninstall.exe"
  !else
    ${WriteUninstaller} $INSTDIR\Uninstall.exe
  !endif
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
  # The shortcuts start in the directory SetOutPath sets.
  SetOutPath "\\?\$TEMP"
  ${CreateDirectory} "$SMPROGRAMS\$StartMenuGroup"
  !ifdef OM_HAVE_OMEDIT
    ${CreateShortcut} "$SMPROGRAMS\$StartMenuGroup\OpenModelica Connection Editor.lnk" "$INSTDIR\bin\OMEdit.exe" "" "$INSTDIR\bin\OMEdit.exe" 0
  !endif
  !ifdef OM_HAVE_OMNOTEBOOK
    ${CreateShortcut} "$SMPROGRAMS\$StartMenuGroup\OpenModelica Notebook.lnk" "$INSTDIR\bin\OMNotebook.exe" "" "$INSTDIR\bin\OMNotebook.exe" 0
  !endif
  !ifdef OM_HAVE_OMSHELL
    ${CreateShortcut} "$SMPROGRAMS\$StartMenuGroup\OpenModelica Shell.lnk" "$INSTDIR\bin\OMShell.exe" "" "$INSTDIR\bin\OMShell.exe" 0
  !endif
  ${WriteIniStr} "$SMPROGRAMS\$StartMenuGroup\OpenModelica Website.url" "InternetShortcut" "URL" "${URL}"
  SetOutPath "\\?\$INSTDIR\"
  ${CreateShortcut} "$SMPROGRAMS\$StartMenuGroup\Uninstall OpenModelica.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0
  !ifdef OM_HAVE_DOCS
    ${CreateDirectory} "$SMPROGRAMS\$StartMenuGroup\Documentation"
    SetOutPath ""
    !insertmacro OM_DOC_SHORTCUTS
  !endif
  !insertmacro MUI_STARTMENU_WRITE_END
  ${WriteRegStr} SHCTX "${REGKEY}" InstallMode $MultiUser.InstallMode
  ${WriteRegStr} SHCTX "${REGKEY}" Version "${VERSION}"
  ${WriteRegStr} SHCTX "${REGKEY}" Nightly "${NIGHTLY}"
  ${WriteRegStr} SHCTX "${UNINSTALL_PATH}" DisplayName "$(^Name)"
  ${WriteRegStr} SHCTX "${UNINSTALL_PATH}" DisplayVersion "${VERSION}"
  ${WriteRegStr} SHCTX "${UNINSTALL_PATH}" Publisher "${COMPANY}"
  ${WriteRegStr} SHCTX "${UNINSTALL_PATH}" URLInfoAbout "${URL}"
  ${WriteRegStr} SHCTX "${UNINSTALL_PATH}" DisplayIcon $INSTDIR\Uninstall.exe
  ${WriteRegStr} SHCTX "${UNINSTALL_PATH}" UninstallString $INSTDIR\Uninstall.exe
  ${WriteRegDWORD} SHCTX "${UNINSTALL_PATH}" NoModify 1
  ${WriteRegDWORD} SHCTX "${UNINSTALL_PATH}" NoRepair 1
SectionEnd

Section "Default installation" SectionDefault
  ${If} $MultiUser.InstallMode == "AllUsers"
    WriteRegExpandStr ${ENV_HKLM} OPENMODELICAHOME "$INSTDIR\"
  ${Else}
    WriteRegExpandStr ${ENV_HKCU} OPENMODELICAHOME "$INSTDIR\"
  ${EndIf}
  !insertmacro RegisterExtensions "$INSTDIR"
SectionEnd

Section -environment
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
SectionEnd

LangString DESC_SectionCore ${LANG_ENGLISH} "OpenModelica ${VERSION}."
LangString DESC_SectionDefault ${LANG_ENGLISH} "Make this the default OpenModelica: set OPENMODELICAHOME to it and open the .mo and .onb files with it."
!ifdef OM_HAVE_USERSGUIDE
LangString DESC_SectionUsersGuide ${LANG_ENGLISH} "The OpenModelica User's Guide, in HTML and PDF."
!endif
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SectionCore} $(DESC_SectionCore)
  !ifdef OM_HAVE_USERSGUIDE
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionUsersGuide} $(DESC_SectionUsersGuide)
  !endif
  !insertmacro MUI_DESCRIPTION_TEXT ${SectionDefault} $(DESC_SectionDefault)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

## Uninstaller ##################################################################
!ifndef UNINSTALLER
Section "Uninstall"
  FileOpen $4 "$INSTDIR\InstallMode.txt" r
  FileSeek $4 0
  FileRead $4 $1
  FileClose $4
  # OPENMODELICAHOME and the file associations are only changed if they belong
  # to this installation.
  ${If} $1 == "AllUsers"
    SetShellVarContext all
    DeleteRegValue ${ENV_HKLM} "${ENV_OMHOME_VERSION}"
    ReadRegStr $R3 ${ENV_HKLM} OPENMODELICAHOME
  ${Else}
    SetShellVarContext current
    DeleteRegValue ${ENV_HKCU} "${ENV_OMHOME_VERSION}"
    ReadRegStr $R3 ${ENV_HKCU} OPENMODELICAHOME
  ${EndIf}
  StrCpy $un.WasDefault 0
  ${If} $R3 == "$INSTDIR\"
  ${OrIf} $R3 == "$INSTDIR"
    StrCpy $un.WasDefault 1
  ${EndIf}
  StrCpy $un.HadFileAssoc 0
  ReadRegStr $R3 HKCR "OpenModelica Connection Editor\shell\open\command" ""
  ${If} $R3 == '"$INSTDIR\bin\OMEdit.exe" "%1"'
    StrCpy $un.HadFileAssoc 1
  ${EndIf}

  IfFileExists "$INSTDIR\${UninstLog}" +3
    MessageBox MB_OK|MB_ICONSTOP "$(UninstLogMissing)"
      Abort

  Push $R0
  Push $R1
  Push $R2
  SetFileAttributes "$INSTDIR\${UninstLog}" NORMAL
  FileOpen $UninstLog "$INSTDIR\${UninstLog}" r
  StrCpy $R1 -1

  DetailPrint "Reading $INSTDIR\${UninstLog}"

  GetLineCount:
    ClearErrors
    FileRead $UninstLog $R0
    IntOp $R1 $R1 + 1
    StrCpy $R0 $R0 -2
    Push $R0
    IfErrors 0 GetLineCount

  Pop $R0

  # The log is read back to front: files before the directories that hold them.
  LoopRead:
    StrCmp $R1 0 LoopDone
    Pop $R0

    IfFileExists "$R0\*.*" 0 +3
      RMDir $R0  #is dir
    Goto +9
    IfFileExists $R0 0 +3
      Delete $R0 #is file
    Goto +6
    StrCmp $R0 "SHCTX ${REGKEY}" 0 +3
      DeleteRegKey SHCTX "${REGKEY}" #is Reg Element
    Goto +3
    StrCmp $R0 "SHCTX ${UNINSTALL_PATH}" 0 +2
      DeleteRegKey SHCTX "${UNINSTALL_PATH}" #is Reg Element

    IntOp $R1 $R1 - 1
    Goto LoopRead
  LoopDone:
  FileClose $UninstLog
  Delete "$INSTDIR\${UninstLog}"
  RMDir "$INSTDIR"
  Pop $R2
  Pop $R1
  Pop $R0

  # Another installation takes over as the default one: the keys are enumerated
  # in alphabetical order, so the last one that still has an omc.exe is the
  # highest version string.
  StrCpy $un.NewDefault ""
  StrCpy $R3 0
  ${Do}
    ClearErrors
    EnumRegKey $R4 SHCTX "SOFTWARE" $R3
    ${If} ${Errors}
      ${ExitDo}
    ${EndIf}
    ${If} $R4 == ""
      ${ExitDo}
    ${EndIf}
    IntOp $R3 $R3 + 1
    StrCpy $R5 $R4 13
    ${If} $R5 == "OpenModelica "
      ReadRegStr $R6 SHCTX "SOFTWARE\$R4" "Path"
      ${If} $R6 != ""
      ${AndIf} ${FileExists} "$R6\bin\omc.exe"
        StrCpy $un.NewDefault $R6
      ${EndIf}
    ${EndIf}
  ${Loop}
  ${If} $un.WasDefault == 1
    ${If} $un.NewDefault != ""
      ${If} $1 == "AllUsers"
        WriteRegExpandStr ${ENV_HKLM} OPENMODELICAHOME "$un.NewDefault\"
      ${Else}
        WriteRegExpandStr ${ENV_HKCU} OPENMODELICAHOME "$un.NewDefault\"
      ${EndIf}
    ${ElseIf} $1 == "AllUsers"
      DeleteRegValue ${ENV_HKLM} OPENMODELICAHOME
    ${Else}
      DeleteRegValue ${ENV_HKCU} OPENMODELICAHOME
    ${EndIf}
  ${EndIf}
  ${If} $un.HadFileAssoc == 1
    ${If} $un.NewDefault != ""
      !insertmacro RegisterExtensions "$un.NewDefault"
    ${Else}
      !insertmacro UnregisterExtension ".mo" "OpenModelica Connection Editor"
      !insertmacro UnregisterExtension ".onb" "OpenModelica Notebook"
      !insertmacro UpdateFileAssociations
    ${EndIf}
  ${EndIf}
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
SectionEnd
!endif

## Functions ####################################################################

; Goes through the OpenModelica installations registered in ROOT (HKCU or HKLM).
;  - the same version is removed before it is installed again, the setup quits otherwise
;  - a release from before the side by side installations: offer to remove it
;  - another nightly build, when a nightly build is installed: offer to remove it
;  - any other version is kept
; Uses $R0 and $R2-$R7.
!macro HandleInstalledVersions ROOT
  StrCpy $R3 0
  ${Do}
    ClearErrors
    EnumRegKey $R4 ${ROOT} "${UNINSTALL_ROOT}" $R3
    ${If} ${Errors}
      ${ExitDo}
    ${EndIf}
    ${If} $R4 == ""
      ${ExitDo}
    ${EndIf}
    IntOp $R3 $R3 + 1
    StrCpy $R5 $R4 13
    ${If} $R4 != "${UNINSTALL_NAME_LEGACY}"
    ${AndIf} $R5 != "${UNINSTALL_NAME_LEGACY} "
      ${Continue}
    ${EndIf}
    ReadRegStr $R2 ${ROOT} "${UNINSTALL_ROOT}\$R4" "UninstallString"
    ${IfNot} ${FileExists} "$R2"
      ${Continue}
    ${EndIf}
    ReadRegStr $R7 ${ROOT} "${UNINSTALL_ROOT}\$R4" "DisplayName"
    StrCpy $R6 0 ; 1 = remove it
    ${If} $R4 == "${UNINSTALL_NAME}"
      ${If} ${Silent}
        StrCpy $R6 1
      ${ElseIf} ${Cmd} `MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "$R7 is already installed on your machine.$\n$\nClick 'OK' to uninstall and install again.$\nClick 'Cancel' to quit the setup." IDOK`
        StrCpy $R6 1
      ${Else}
        Quit
      ${EndIf}
    ${ElseIf} $R4 == "${UNINSTALL_NAME_LEGACY}"
      ${If} ${Silent}
        StrCpy $R6 1
      ${ElseIf} ${Cmd} `MessageBox MB_YESNO|MB_ICONQUESTION "$R7 is installed on your machine.$\n$\nBoth versions can be kept, but uninstalling $R7 later on will remove the OPENMODELICAHOME environment variable and the .mo file association of this version.$\n$\nDo you want to uninstall $R7 now?" IDYES`
        StrCpy $R6 1
      ${EndIf}
    ${Else}
!ifdef OMNIGHTLY
      ReadRegStr $R5 ${ROOT} "SOFTWARE\$R4" "Nightly"
      ${If} $R5 == "1"
        ${If} ${Silent}
          StrCpy $R6 $RemoveNightlies
        ${ElseIf} ${Cmd} `MessageBox MB_YESNO|MB_ICONQUESTION "Another OpenModelica nightly build is installed on your machine:$\n$R7$\n$\nDo you want to uninstall it?$\nClick 'No' to keep both." IDYES`
          StrCpy $R6 1
        ${EndIf}
      ${EndIf}
!endif
    ${EndIf}
    ${If} $R6 == 1
      ${GetParent} "$R2" $R0
      ; _? makes ExecWait block until the uninstall is done. It must be last and unquoted.
      ${If} ${Silent}
        ExecWait '"$R2" /S _?=$R0'
      ${Else}
        ExecWait '"$R2" _?=$R0'
      ${EndIf}
      ClearErrors
      ReadRegStr $R5 ${ROOT} "${UNINSTALL_ROOT}\$R4" "UninstallString"
      ${If} $R5 == ""
        ; with _? the uninstaller cannot delete itself
        Delete "$R2"
        RMDir "$R0"
        ; the key is gone, the next one has moved to its index
        IntOp $R3 $R3 - 1
      ${EndIf}
    ${EndIf}
  ${Loop}
!macroend

Function .onInit
  !ifdef UNINSTALLER_ONLY
    WriteUninstaller "$EXEDIR\Uninstall.exe"
    SetErrorLevel 0
    Quit
  !endif
  SetRegView 64
  ${GetParameters} $R8
  StrCpy $RemoveNightlies 0
  ClearErrors
  ${GetOptions} $R8 "/REMOVENIGHTLIES" $R9
  ${IfNot} ${Errors}
    StrCpy $RemoveNightlies 1
  ${EndIf}
  ClearErrors
  ${GetOptions} $R8 "/DEFAULT=" $R9
  ${IfNot} ${Errors}
  ${AndIf} $R9 == "0"
    !insertmacro UnselectSection ${SectionDefault}
  ${EndIf}
  !insertmacro HandleInstalledVersions HKCU
  !insertmacro HandleInstalledVersions HKLM
  ; the older releases installed with /D registered in the 32-bit view of the registry
  SetRegView 32
  !insertmacro HandleInstalledVersions HKLM
  SetRegView 64
  InitPluginsDir
  !insertmacro MULTIUSER_INIT
  ${If} $INSTDIR == ""
    StrCpy $INSTDIR "$PROGRAMFILES64\OpenModelica${OMVERSION}"
  ${EndIf}
  ${If} ${Silent}
    StrCpy $MultiUser.InstallMode "AllUsers"
    SetShellVarContext all
  ${Else}
    StrCpy $MultiUser.InstallMode "CurrentUser"
    SetShellVarContext current
  ${EndIf}
FunctionEnd

!ifdef OM_HAVE_OMEDIT
Function LaunchOMEdit
  ; The installer process does not see the environment it just wrote.
  System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("OPENMODELICAHOME", "$INSTDIR\").r0'
  System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("OPENMODELICALIBRARY", NULL).r0'
  ; Through explorer, so OMEdit does not inherit the installer's elevation,
  ; which would disable drag and drop.
  Exec '"$WINDIR\explorer.exe" "$INSTDIR\bin\OMEdit.exe"'
FunctionEnd
!endif

!ifndef UNINSTALLER
Function un.onInit
  SetRegView 64
  !insertmacro MULTIUSER_UNINIT
FunctionEnd
!endif

; include Modern UI
!include "MUI.nsh"

; standard NSIS includes
!include "LogicLib.nsh"
!include "WinVer.nsh"

; include nsProcess
!addincludedir "nsProcess"
!addplugindir "nsProcess"
!include "nsProcess.nsh"

; include SimpleSC
!addplugindir "SimpleSC"

; include GetTime
!include "FileFunc.nsh"
!insertmacro GetTime

; output file
!ifndef OutFile
    !define OutFile "openarmor-win32-agent.exe"
!endif

; general
!define MUI_ICON favicon.ico
!define MUI_UNICON openarmor-uninstall.ico
!define VERSION "3.8.0"
!define NAME "openarmor HIDS"
!define SERVICE "openarmorSvc"

Name "${NAME} Windows Agent v${VERSION}"
BrandingText "Copyright (C) 2003 - 2014 Trend Micro Inc."
OutFile "${OutFile}"

InstallDir "$PROGRAMFILES\openarmor-agent"
InstallDirRegKey HKLM Software\openarmor ""

; show (un)installation details
ShowInstDetails show
ShowUninstDetails show

; do not close details pages immediately
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

; interface settings
!define MUI_ABORTWARNING

; pages
!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the install of ${Name}.\r\n\r\nClick next to continue."
!define MUI_FINISHPAGE_TITLE_3LINES
!define MUI_FINISHPAGE_RUN "$INSTDIR\win32ui.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Run openarmor Agent Manager"

; page for choosing components
!define MUI_COMPONENTSPAGE_TEXT_TOP "Select the options you want to be executed. Click next to continue."
!define MUI_COMPONENTSPAGE_NODESC

; pages to display to user
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; these have to be defined again to work with the uninstall pages
!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_FINISHPAGE_TITLE_3LINES
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; languages
!insertmacro MUI_LANGUAGE "English"

; function to stop openarmor service if running
Function .onInit
    ; stop service
    SimpleSC::ExistsService "${SERVICE}"
    Pop $0
    ${If} $0 = 0
        SimpleSC::ServiceIsStopped "${SERVICE}"
        Pop $0
        Pop $1
        ${If} $0 = 0
            ${If} $1 <> 1
                MessageBox MB_OKCANCEL "${NAME} is already installed and the ${SERVICE} service is running. \
                    It will be stopped before continuing." /SD IDOK IDOK ServiceStop
                SetErrorLevel 2
                Abort

                ServiceStop:
                    SimpleSC::StopService "${SERVICE}" 1 30
                    Pop $0
                    ${If} $0 <> 0
                        MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP "$\r$\n\
                            Failure stopping the ${SERVICE} service ($0).$\r$\n$\r$\n\
                            Click Abort to stop the installation,$\r$\n\
                            Retry to try again, or$\r$\n\
                            Ignore to skip this file." /SD IDABORT IDIGNORE ServiceStopped IDRETRY ServiceStop

                        SetErrorLevel 2
                        Abort
                    ${EndIf}
            ${EndIf}
        ${Else}
            MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP "$\r$\n\
                Failure checking status of the ${SERVICE} service ($0).$\r$\n$\r$\n\
                Click Abort to stop the installation,$\r$\n\
                Retry to try again, or$\r$\n\
                Ignore to skip this file." /SD IDABORT IDIGNORE ServiceStopped IDRETRY ServiceStop

            SetErrorLevel 2
            Abort
        ${EndIf}
    ${EndIf}
    ServiceStopped:
FunctionEnd

; main install section
Section "openarmor Agent (required)" MainSec
    ; set install type and cwd
    SectionIn RO
    SetOutPath $INSTDIR

    ; clear any errors
    ClearErrors

    ; use real date modified times
    SetDateSave off

    ; overwrite existing files
    SetOverwrite on

    ; create necessary directories
    CreateDirectory "$INSTDIR\bookmarks"
    CreateDirectory "$INSTDIR\rids"
    CreateDirectory "$INSTDIR\syscheck"
    CreateDirectory "$INSTDIR\shared"
    CreateDirectory "$INSTDIR\active-response"
    CreateDirectory "$INSTDIR\active-response\bin"
    CreateDirectory "$INSTDIR\tmp"

    ; install files
    ;File openarmor-lua.exe
    ;File openarmor-luac.exe
    File openarmor-agent.exe
    File openarmor-agent-eventchannel.exe
    File agent-auth.exe
    File default-openarmor.conf
    File manage_agents.exe
    File /oname=win32ui.exe os_win32ui.exe
    File openarmor-rootcheck.exe
    File internal_options.conf
    File default-local_internal_options.conf
    File setup-windows.exe
    File setup-syscheck.exe
    File setup-iis.exe
    File doc.html
    File /oname=shared\rootkit_trojans.txt ../rootcheck/db/rootkit_trojans.txt
    File /oname=shared\rootkit_files.txt ../rootcheck/db/rootkit_files.txt
    File add-localfile.exe
    File LICENSE.txt
    File /oname=shared\win_applications_rcl.txt ../rootcheck\db\win_applications_rcl.txt
    File /oname=shared\win_malware_rcl.txt ../rootcheck\db\win_malware_rcl.txt
    File /oname=shared\win_audit_rcl.txt ../rootcheck\db\win_audit_rcl.txt
    File help.txt
    File vista_sec.txt
    File /oname=active-response\bin\route-null.cmd route-null.cmd
    File /oname=active-response\bin\restart-openarmor.cmd restart-openarmor.cmd

    ; use appropriate version of "openarmor-agent.exe"
    ${If} ${AtLeastWinVista}
        Delete "$INSTDIR\openarmor-agent.exe"
        Rename "$INSTDIR\openarmor-agent-eventchannel.exe" "$INSTDIR\openarmor-agent.exe"
    ${Else}
        Delete "$INSTDIR\openarmor-agent-eventchannel.exe"
    ${Endif}

    ; write registry keys
    WriteRegStr HKLM SOFTWARE\openarmor "Install_Dir" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\openarmor" "DisplayName" "${NAME} ${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\openarmor" "DisplayVersion" "${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\openarmor" "DisplayIcon" "${MUI_ICON}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\openarmor" "HelpLink" "http://www.theopenarmor.org/main/support/"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\openarmor" "URLInfoAbout" "http://www.theopenarmor.org"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\openarmor" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\openarmor" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\openarmor" "NoRepair" 1
    WriteUninstaller "uninstall.exe"

    ; get current local time
    ${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
    var /global CURRENTTIME
    StrCpy $CURRENTTIME "$2-$1-$0 $4:$5:$6"

    ; write version and install information
    VersionInstall:
        FileOpen $0 "$INSTDIR\VERSION.txt" w
        FileWrite $0 "${NAME} v${VERSION} - Installed on $CURRENTTIME"
        FileClose $0
        IfErrors VersionError VersionComplete
    VersionError:
        MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP "$\r$\n\
            Failure saving version to file.$\r$\n$\r$\n\
            File:$\r$\n$\r$\n$INSTDIR\VERSION.txt$\r$\n$\r$\n\
            Click Abort to stop the installation,$\r$\n\
            Retry to try again, or$\r$\n\
            Ignore to skip this file." /SD IDABORT IDIGNORE VersionComplete IDRETRY VersionInstall

        SetErrorLevel 2
        Abort
    VersionComplete:
        ClearErrors

    ; create log file
    LogInstall:
        ClearErrors
        IfFileExists "$INSTDIR\openarmor.log" LogComplete
        FileOpen $0 "$INSTDIR\openarmor.log" w
        FileClose $0
        IfErrors LogError LogComplete
    LogError:
        MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP "$\r$\n\
            Failure creating the openarmor.log file.$\r$\n$\r$\n\
            File:$\r$\n$\r$\n$INSTDIR\openarmor.log$\r$\n$\r$\n\
            Click Abort to stop the installation,$\r$\n\
            Retry to try again, or$\r$\n\
            Ignore to skip this file." /SD IDABORT IDIGNORE LogComplete IDRETRY LogInstall

        SetErrorLevel 2
        Abort
    LogComplete:
        ClearErrors

    ; rename local_internal_options.conf if it does not already exist
    ConfInstallInternal:
        ClearErrors
        IfFileExists "$INSTDIR\local_internal_options.conf" ConfPresentInternal
        Rename "$INSTDIR\default-local_internal_options.conf" "$INSTDIR\local_internal_options.conf"
        IfErrors ConfErrorInternal ConfPresentInternal
    ConfErrorInternal:
        MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP "$\r$\n\
            Failure renaming configuration file.$\r$\n$\r$\n\
            From:$\r$\n$\r$\n\
            $INSTDIR\default-local_internal_options.conf$\r$\n$\r$\n\
            To:$\r$\n$\r$\n\
            $INSTDIR\local_internal_options.conf$\r$\n$\r$\n\
            Click Abort to stop the installation,$\r$\n\
            Retry to try again, or$\r$\n\
            Ignore to skip this file." /SD IDABORT IDIGNORE ConfPresentInternal IDRETRY ConfInstallInternal

        SetErrorLevel 2
        Abort
    ConfPresentInternal:
        ClearErrors

    ; rename openarmor.conf if it does not already exist
    ConfInstallopenarmor:
        ClearErrors
        IfFileExists "$INSTDIR\openarmor.conf" ConfPresentopenarmor
        Rename "$INSTDIR\default-openarmor.conf" "$INSTDIR\openarmor.conf"
        IfErrors ConfErroropenarmor ConfPresentopenarmor
    ConfErroropenarmor:
        MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP "$\r$\n\
            Failure renaming configuration file.$\r$\n$\r$\n\
            From:$\r$\n$\r$\n\
            $INSTDIR\default-openarmor.conf$\r$\n$\r$\n\
            To:$\r$\n$\r$\n\
            $INSTDIR\openarmor.conf$\r$\n$\r$\n\
            Click Abort to stop the installation,$\r$\n\
            Retry to try again, or$\r$\n\
            Ignore to skip this file." /SD IDABORT IDIGNORE ConfPresentopenarmor IDRETRY ConfInstallopenarmor

        SetErrorLevel 2
        Abort
    ConfPresentopenarmor:
        ClearErrors

    ; handle shortcuts
    ; http://nsis.sourceforge.net/Shortcuts_removal_fails_on_Windows_Vista
    SetShellVarContext all

    ; remove shortcuts
    Delete "$SMPROGRAMS\openarmor\Edit.lnk"
    Delete "$SMPROGRAMS\openarmor\Uninstall.lnk"
    Delete "$SMPROGRAMS\openarmor\Documentation.lnk"
    Delete "$SMPROGRAMS\openarmor\Edit Config.lnk"
    Delete "$SMPROGRAMS\openarmor\*.*"
    RMDir "$SMPROGRAMS\openarmor"

    ; create shortcuts
    CreateDirectory "$SMPROGRAMS\openarmor"
    CreateShortCut "$SMPROGRAMS\openarmor\Manage Agent.lnk" "$INSTDIR\win32ui.exe" "" "$INSTDIR\win32ui.exe" 0
    CreateShortCut "$SMPROGRAMS\openarmor\Documentation.lnk" "$INSTDIR\doc.html" "" "$INSTDIR\doc.html" 0
    CreateShortCut "$SMPROGRAMS\openarmor\Edit Config.lnk" "$INSTDIR\openarmor.conf" "" "$INSTDIR\openarmor.conf" 0
    CreateShortCut "$SMPROGRAMS\openarmor\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0

    ; install openarmor service
    ServiceInstall:
        nsExec::ExecToLog '"$INSTDIR\openarmor-agent.exe" install-service'
        Pop $0
        ${If} $0 <> 1
            MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP "$\r$\n\
                Failure setting up the ${SERVICE} service.$\r$\n$\r$\n\
                Check the details for information about the error.$\r$\n$\r$\n\
                Click Abort to stop the installation,$\r$\n\
                Retry to try again, or$\r$\n\
                Ignore to skip this file." /SD IDABORT IDIGNORE ServiceInstallComplete IDRETRY ServiceInstall

            SetErrorLevel 2
            Abort
        ${EndIf}
    ServiceInstallComplete:

    ; install files
    Setup:
        nsExec::ExecToLog '"$INSTDIR\setup-windows.exe" "$INSTDIR"'
        Pop $0
        ${If} $0 <> 1
            MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP "$\r$\n\
                Failure running setup-windows.exe.$\r$\n$\r$\n\
                Check the details for information about the error.$\r$\n$\r$\n\
                Click Abort to stop the installation,$\r$\n\
                Retry to try again, or$\r$\n\
                Ignore to skip this file." /SD IDABORT IDIGNORE SetupComplete IDRETRY Setup

            SetErrorLevel 2
            Abort
        ${EndIf}
    SetupComplete:
SectionEnd

; add IIS logs
Section "Scan and monitor IIS logs (recommended)" IISLogs
    nsExec::ExecToLog '"$INSTDIR\setup-iis.exe" "$INSTDIR"'
SectionEnd

; add integrity checking
Section "Enable integrity checking (recommended)" IntChecking
    nsExec::ExecToLog '"$INSTDIR\setup-syscheck.exe" "$INSTDIR" "enable"'
SectionEnd

; uninstall section
Section "Uninstall"
    ; uninstall the services
    ; this also stops the service as well so it should be done early
    ServiceUninstall:
        nsExec::ExecToLog '"$INSTDIR\openarmor-agent.exe" uninstall-service'
        Pop $0
        ${If} $0 <> 1
            MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP "$\r$\n\
                Failure uninstalling the ${SERVICE} service.$\r$\n$\r$\n\
                Check the details for information about the error.$\r$\n$\r$\n\
                Click Abort to stop the installation,$\r$\n\
                Retry to try again, or$\r$\n\
                Ignore to skip this file." /SD IDABORT IDIGNORE ServiceUninstallComplete IDRETRY ServiceUninstall

            SetErrorLevel 2
            Abort
        ${EndIf}
    ServiceUninstallComplete:

    ; make sure manage_agents.exe is not running
    ManageAgents:
        ${nsProcess::FindProcess} "manage_agents.exe" $0
        ${If} $0 = 0
            MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP "$\r$\n\
                Found manage_agents.exe is still running.$\r$\n$\r$\n\
                Please close it before continuing.$\r$\n$\r$\n\
                Click Abort to stop the installation,$\r$\n\
                Retry to try again, or$\r$\n\
                Ignore to skip this file." /SD IDABORT IDIGNORE ManageAgentsClosed IDRETRY ManageAgents

            ${nsProcess::Unload}
            SetErrorLevel 2
            Abort
        ${EndIf}
    ManageAgentsClosed:

    ; make sure win32ui.exe is not running
    win32ui:
        ${nsProcess::FindProcess} "win32ui.exe" $0
        ${If} $0 = 0
            MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP "$\r$\n\
                Found win32ui.exe is still running.$\r$\n$\r$\n\
                Please close it before continuing.$\r$\n$\r$\n\
                Click Abort to stop the installation,$\r$\n\
                Retry to try again, or$\r$\n\
                Ignore to skip this file." /SD IDABORT IDIGNORE win32uiClosed IDRETRY win32ui

            ${nsProcess::Unload}
            SetErrorLevel 2
            Abort
        ${EndIf}
    win32uiClosed:

    ; unload nsProcess
    ${nsProcess::Unload}

    ; remove registry keys
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\openarmor"
    DeleteRegKey HKLM SOFTWARE\openarmor

    ; remove files and uninstaller
    Delete "$INSTDIR\openarmor-agent.exe"
    ;Delete "$INSTDIR\openarmor-lua.exe"
    ;Delete "$INSTDIR\openarmor-luac.exe"
    Delete "$INSTDIR\manage_agents.exe"
    Delete "$INSTDIR\openarmor.conf"
    Delete "$INSTDIR\uninstall.exe"
    Delete "$INSTDIR\*"
    Delete "$INSTDIR\bookmarks\*"
    Delete "$INSTDIR\rids\*"
    Delete "$INSTDIR\syscheck\*"
    Delete "$INSTDIR\shared\*"
    Delete "$INSTDIR\active-response\bin\*"
    Delete "$INSTDIR\active-response\*"
    Delete "$INSTDIR\tmp\*"
    Delete "$INSTDIR"

    ; remove shortcuts
    SetShellVarContext all
    Delete "$SMPROGRAMS\openarmor\*.*"
    Delete "$SMPROGRAMS\openarmor\*"
    RMDir "$SMPROGRAMS\openarmor"

    ; remove directories used
    RMDir "$INSTDIR\shared"
    RMDir "$INSTDIR\syscheck"
    RMDir "$INSTDIR\bookmarks"
    RMDir "$INSTDIR\rids"
    RMDir "$INSTDIR\active-response\bin"
    RMDir "$INSTDIR\active-response"
    RMDir "$INSTDIR\tmp"
    RMDir "$INSTDIR"
SectionEnd

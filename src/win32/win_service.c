/* Copyright (C) 2009 Trend Micro Inc.
 * All rights reserved.
 *
 * This program is a free software; you can redistribute it
 * and/or modify it under the terms of the GNU General Public
 * License (version 2) as published by the FSF - Free Software
 * Foundation.
 */

#ifdef WIN32

#include "shared.h"
#include "os_win.h"
#include <winsvc.h>

#ifndef ARGV0
#define ARGV0 "openarmor-agent"
#endif

static LPTSTR g_lpszServiceName        = "openarmorSvc";
static LPTSTR g_lpszServiceDisplayName = "openarmor HIDS";
static LPTSTR g_lpszServiceDescription = "openarmor HIDS Windows Agent";

static SERVICE_STATUS          openarmorServiceStatus;
static SERVICE_STATUS_HANDLE   openarmorServiceStatusHandle;

void WINAPI openarmorServiceStart (DWORD argc, LPTSTR *argv);


/* Start openarmor-HIDS service */
int os_start_service()
{
    int rc = 0;
    SC_HANDLE schSCManager, schService;

    /* Start the database */
    schSCManager = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
    if (schSCManager) {
        schService = OpenService(schSCManager, g_lpszServiceName,
                                 SC_MANAGER_ALL_ACCESS);
        if (schService) {
            if (StartService(schService, 0, NULL)) {
                rc = 1;
            } else {
                if (GetLastError() == ERROR_SERVICE_ALREADY_RUNNING) {
                    rc = -1;
                }
            }

            CloseServiceHandle(schService);
        }

        CloseServiceHandle(schSCManager);
    }

    return (rc);
}

/* Stop openarmor-HIDS service */
int os_stop_service()
{
    int rc = 0;
    SC_HANDLE schSCManager, schService;

    /* Stop the service database */
    schSCManager = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
    if (schSCManager) {
        schService = OpenService(schSCManager, g_lpszServiceName,
                                 SC_MANAGER_ALL_ACCESS);
        if (schService) {
            SERVICE_STATUS lpServiceStatus;

            if (ControlService(schService, SERVICE_CONTROL_STOP, &lpServiceStatus)) {
                rc = 1;
            }

            CloseServiceHandle(schService);
        }

        CloseServiceHandle(schSCManager);
    }

    return (rc);
}

/* Check if the openarmor-HIDS agent service is running
 * Returns 1 on success (running) or 0 if not running
 */
int CheckServiceRunning()
{
    int rc = 0;
    SC_HANDLE schSCManager, schService;

    /* Check service status */
    schSCManager = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
    if (schSCManager) {
        schService = OpenService(schSCManager, g_lpszServiceName,
                                 SC_MANAGER_ALL_ACCESS);
        if (schService) {
            /* Check status */
            SERVICE_STATUS lpServiceStatus;

            if (QueryServiceStatus(schService, &lpServiceStatus)) {
                if (lpServiceStatus.dwCurrentState == SERVICE_RUNNING) {
                    rc = 1;
                }
            }
            CloseServiceHandle(schService);
        }

        CloseServiceHandle(schSCManager);
    }

    return (rc);
}

/* Install the openarmor-HIDS agent service */
int InstallService(char *path)
{
    int ret;
    SC_HANDLE schSCManager, schService;
    LPCTSTR lpszBinaryPathName = NULL;
    SERVICE_DESCRIPTION sdBuf;

    /* Uninstall service (if it exists) */
    if (!UninstallService()) {
        verbose("%s: ERROR: Failure running UninstallService().", ARGV0);
        return (0);
    }

    /* Executable path -- it must be called with the full path */
    lpszBinaryPathName = path;

    /* Opening the service database */
    schSCManager = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);

    if (schSCManager == NULL) {
        goto install_error;
    }

    /* Create the service */
    schService = CreateService(schSCManager,
                               g_lpszServiceName,
                               g_lpszServiceDisplayName,
                               SERVICE_ALL_ACCESS,
                               SERVICE_WIN32_OWN_PROCESS,
                               SERVICE_AUTO_START,
                               SERVICE_ERROR_NORMAL,
                               lpszBinaryPathName,
                               NULL, NULL, NULL, NULL, NULL);

    if (schService == NULL) {
        CloseServiceHandle(schSCManager);
        goto install_error;
    }

    /* Set description */
    sdBuf.lpDescription = g_lpszServiceDescription;
    ret = ChangeServiceConfig2(schService, SERVICE_CONFIG_DESCRIPTION, &sdBuf);

    CloseServiceHandle(schService);
    CloseServiceHandle(schSCManager);

    /* Check for errors */
    if (!ret) {
        goto install_error;
    }

    verbose("%s: INFO: Successfully added to the service database.", ARGV0);
    return (1);

install_error: {
        char local_msg[1025];
        LPVOID lpMsgBuf;

        memset(local_msg, 0, 1025);

        FormatMessage( FORMAT_MESSAGE_ALLOCATE_BUFFER |
                       FORMAT_MESSAGE_FROM_SYSTEM |
                       FORMAT_MESSAGE_IGNORE_INSERTS,
                       NULL,
                       GetLastError(),
                       MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                       (LPTSTR) &lpMsgBuf,
                       0,
                       NULL);

        verbose("%s: ERROR: Unable to create service entry: %s", ARGV0, (LPCTSTR)lpMsgBuf);
        return (0);
    }
}

/* Uninstall the openarmor-HIDS agent service */
int UninstallService()
{
    int ret;
    int rc = 0;
    SC_HANDLE schSCManager, schService;
    SERVICE_STATUS lpServiceStatus;

    /* Remove from the service database */
    schSCManager = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
    if (schSCManager) {
        schService = OpenService(schSCManager, g_lpszServiceName, SERVICE_STOP | DELETE);
        if (schService) {
            if (CheckServiceRunning()) {
                verbose("%s: INFO: Found (%s) service is running going to try and stop it.", ARGV0, g_lpszServiceName);
                ret = ControlService(schService, SERVICE_CONTROL_STOP, &lpServiceStatus);
                if (!ret) {
                    verbose("%s: ERROR: Failure stopping service (%s) before removing it (%ld).", ARGV0, g_lpszServiceName, GetLastError());
                } else {
                    verbose("%s: INFO: Successfully stopped (%s).", ARGV0, g_lpszServiceName);
                }
            } else {
                verbose("%s: INFO: Found (%s) service is not running.", ARGV0, g_lpszServiceName);
                ret = 1;
            }

            if (ret && DeleteService(schService)) {
                verbose("%s: INFO: Successfully removed (%s) from the service database.", ARGV0, g_lpszServiceName);
                rc = 1;
            }
            CloseServiceHandle(schService);
        } else {
            verbose("%s: INFO: Service does not exist (%s) nothing to remove.", ARGV0, g_lpszServiceName);
            rc = 1;
        }
        CloseServiceHandle(schSCManager);
    }

    if (!rc) {
        verbose("%s: ERROR: Failure removing (%s) from the service database.", ARGV0, g_lpszServiceName);
    }

    return (rc);
}

/* "Signal" handler */
VOID WINAPI openarmorServiceCtrlHandler(DWORD dwOpcode)
{
    switch (dwOpcode) {
        case SERVICE_CONTROL_STOP:
            openarmorServiceStatus.dwCurrentState           = SERVICE_STOPPED;
            openarmorServiceStatus.dwWin32ExitCode          = 0;
            openarmorServiceStatus.dwCheckPoint             = 0;
            openarmorServiceStatus.dwWaitHint               = 0;

            verbose("%s: INFO: Received exit signal.", ARGV0);
            SetServiceStatus (openarmorServiceStatusHandle, &openarmorServiceStatus);
            verbose("%s: INFO: Exiting...", ARGV0);
            return;
        default:
            break;
    }
    return;
}

/* Set the error code in the service */
void WinSetError()
{
    openarmorServiceCtrlHandler(SERVICE_CONTROL_STOP);
}

/* Initialize openarmor-HIDS dispatcher */
int os_WinMain(__attribute__((unused)) int argc, __attribute__((unused)) char **argv)
{
    SERVICE_TABLE_ENTRY   steDispatchTable[] = {
        { g_lpszServiceName, openarmorServiceStart },
        { NULL,       NULL                     }
    };

    if (!StartServiceCtrlDispatcher(steDispatchTable)) {
        verbose("%s: INFO: Unable to set service information.", ARGV0);
        return (1);
    }

    return (1);
}

/* Start openarmor service */
void WINAPI openarmorServiceStart (__attribute__((unused)) DWORD argc, __attribute__((unused)) LPTSTR *argv)
{
    openarmorServiceStatus.dwServiceType            = SERVICE_WIN32;
    openarmorServiceStatus.dwCurrentState           = SERVICE_START_PENDING;
    openarmorServiceStatus.dwControlsAccepted       = SERVICE_ACCEPT_STOP;
    openarmorServiceStatus.dwWin32ExitCode          = 0;
    openarmorServiceStatus.dwServiceSpecificExitCode = 0;
    openarmorServiceStatus.dwCheckPoint             = 0;
    openarmorServiceStatus.dwWaitHint               = 0;

    openarmorServiceStatusHandle =
        RegisterServiceCtrlHandler(g_lpszServiceName,
                                   openarmorServiceCtrlHandler);

    if (openarmorServiceStatusHandle == (SERVICE_STATUS_HANDLE)0) {
        verbose("%s: INFO: RegisterServiceCtrlHandler failed.", ARGV0);
        return;
    }

    openarmorServiceStatus.dwCurrentState = SERVICE_RUNNING;
    openarmorServiceStatus.dwCheckPoint = 0;
    openarmorServiceStatus.dwWaitHint = 0;

    if (!SetServiceStatus(openarmorServiceStatusHandle, &openarmorServiceStatus)) {
        verbose("%s: INFO: SetServiceStatus error.", ARGV0);
        return;
    }

#ifdef openarmorHIDS
    /* Start process */
    local_start();
#endif
}

#endif /* WIN32 */

/* Copyright (C) 2019 openarmor Foundation
 * All rights reserved.
 *
 * This program is a free software; you can redistribute it
 * and/or modify it under the terms of the GNU General Public
 * License (version 2) as published by the FSF - Free Software
 * Foundation
 */

#include "manage_agents.h"
#include <stdlib.h>

/* Prototypes */
static void helpmsg(void) __attribute__((noreturn));
static void print_banner(void);
#ifndef WIN32
static void manage_shutdown(int sig) __attribute__((noreturn));
#endif

int willchroot;

#if defined(__MINGW32__)
static int setenv(const char *name, const char *val, __attribute__((unused)) int overwrite)
{
    int len = strlen(name) + strlen(val) + 2;
    char *str = (char *)malloc(len);
    if(str == NULL) {
        merror("%s: malloc failed", ARGV0);
        exit(errno);
    }
    snprintf(str, len, "%s=%s", name, val);
    putenv(str);
    return 0;
}
#endif

static void helpmsg()
{
    print_header();
    print_out("  %s: -[Vhlj] [-a <ip> -n <name>] [-d sec] [-e id] [-r id] [-i id] [-f file]", ARGV0);
    print_out("    -V          Version and license message");
    print_out("    -h          This help message");
    print_out("    -j          Use JSON output");
    print_out("    -l          List available agents.");
    print_out("    -a <ip>     Add new agent");

    print_out("    -e <id>     Extracts key for an agent (Manager only)");
    print_out("    -r <id>     Remove an agent (Manager only)");
    print_out("    -i <id>     Import authentication key (Agent only)");
    print_out("    -n <name>   Name for new agent");
    print_out("    -F <sec>    Remove agents with duplicated IP if disconnected since <sec> seconds");
    print_out("    -f <file>   Bulk generate client keys from file (Manager only)");
    print_out("                <file> contains lines in IP,NAME format");
    print_out("                <file> should also exist within /var/openarmor due to manage_agents chrooting");
    exit(1);
}

static void print_banner()
{
    printf("\n");
    printf(BANNER, __openarmor_name, __openarmor_version);

#ifdef CLIENT
    printf(BANNER_CLIENT);
#else
    printf(BANNER_OPT);
#endif

    return;
}

#ifndef WIN32
/* Clean shutdown on kill */
static void manage_shutdown(__attribute__((unused)) int sig)
{
    /* Checking if restart message is necessary */
    if (restart_necessary) {
        printf(MUST_RESTART);
    } else {
        printf("\n");
    }
    printf(EXIT);

    exit(0);
}
#endif

int main(int argc, char **argv)
{
    char *user_msg;
    int c = 0, cmdlist = 0, json_output = 0;
    int force_antiquity;
    char *end;
    const char *cmdexport = NULL;
    const char *cmdimport = NULL;
    const char *cmdbulk = NULL;
#ifndef WIN32
    const char *dir = DEFAULTDIR;
    const char *group = GROUPGLOBAL;
    gid_t gid;
#else
    FILE *fp;
    TCHAR path[2048];
    DWORD last_error;
    int ret;
#endif

    extern int willchroot;
    willchroot = 1;

    /* Set the name */
    OS_SetName(ARGV0);

    while ((c = getopt(argc, argv, "Vhle:r:i:f:ja:n:F:")) != -1) {
        switch (c) {
            case 'V':
                print_version();
                break;
            case 'h':
                helpmsg();
                break;
            case 'e':
#ifdef CLIENT
                ErrorExit("%s: Key export only available on a master.", ARGV0);
#endif
                if (!optarg) {
                    ErrorExit("%s: -e needs an argument.", ARGV0);
                }
                cmdexport = optarg;
                break;
            case 'r':
#ifdef CLIENT
                ErrorExit("%s: Key removal only available on a master.", ARGV0);
#endif
                if (!optarg) {
                    ErrorExit("%s: -r needs an argument.", ARGV0);
                }

                /* Use environment variables already available to remove_agent() */
                setenv("openarmor_ACTION", "r", 1);
                setenv("openarmor_AGENT_ID", optarg, 1);
                setenv("openarmor_ACTION_CONFIRMED", "y", 1);
                break;
            case 'i':
#ifndef CLIENT
                ErrorExit("%s: Key import only available on an agent.", ARGV0);
#endif
                if (!optarg) {
                    ErrorExit("%s: -i needs an argument.", ARGV0);
                }
                cmdimport = optarg;
                break;
            case 'f':
#ifdef CLIENT
                ErrorExit("%s: Bulk generate keys only available on a master.", ARGV0);
#endif
                if (!optarg) {
                    ErrorExit("%s: -f needs an argument.", ARGV0);
                }
                cmdbulk = optarg;
                willchroot = 0;
                printf("Bulk load file: %s\n", cmdbulk);
                break;
            case 'l':
                cmdlist = 1;
                break;
            case 'j':
                json_output = 1;
                break;
            case 'a':
#ifdef CLIENT
                ErrorExit("%s: Agent adding only available on a master.", ARGV0);
#endif
                if (!optarg)
                    ErrorExit("%s: -a needs an argument.", ARGV0);
                setenv("openarmor_ACTION", "a", 1);
                setenv("openarmor_ACTION_CONFIRMED", "y", 1);
                setenv("openarmor_AGENT_IP", optarg, 1);
                setenv("openarmor_AGENT_ID", "0", 1);
            break;
            case 'n':
                if (!optarg)
                    ErrorExit("%s: -n needs an argument.", ARGV0);
                setenv("openarmor_AGENT_NAME", optarg, 1);
                break;
            case 'F':
                if (!optarg)
                    ErrorExit("%s: -d needs an argument.", ARGV0);

                force_antiquity = strtol(optarg, &end, 10);

                if (optarg == end || force_antiquity < 0)
                    ErrorExit("%s: Invalid number for -d", ARGV0);

                setenv("openarmor_REMOVE_DUPLICATED", optarg, 1);
                break;
            default:
                helpmsg();
                break;
        }
    }

    /* Get current time */
    time1 = time(0);
    restart_necessary = 0;

    /* Before chroot */
    srandom_init();

#ifndef WIN32
    /* Get the group name */
    gid = Privsep_GetGroup(group);
    if (gid == (gid_t) - 1) {
        ErrorExit(USER_ERROR, ARGV0, "", group);
    }

    /* Set the group */
    if (Privsep_SetGroup(gid) < 0) {
        ErrorExit(SETGID_ERROR, ARGV0, group, errno, strerror(errno));
    }

    /* Inside chroot now */
    if(willchroot > 0) {

        /* Chroot to the default directory */
        if (Privsep_Chroot(dir) < 0) {
            ErrorExit(CHROOT_ERROR, ARGV0, dir, errno, strerror(errno));
        }

        nowChroot();
    }

    /* Start signal handler */
    StartSIG2(ARGV0, manage_shutdown);
#else
    /* Get full path to the directory this executable lives in */
    ret = GetModuleFileName(NULL, path, sizeof(path));

    /* Check for errors */
    if (!ret) {
        ErrorExit(GMF_ERROR);
    }

    /* Get last error */
    last_error = GetLastError();

    /* Look for errors */
    if (last_error != ERROR_SUCCESS) {
        if (last_error == ERROR_INSUFFICIENT_BUFFER) {
            ErrorExit(GMF_BUFF_ERROR, ret, sizeof(path));
        } else {
            ErrorExit(GMF_UNKN_ERROR, last_error);
        }
    }

    /* Remove file name from path */
    PathRemoveFileSpec(path);

    /* Move to correct directory */
    if (chdir(path)) {
        ErrorExit(CHDIR_ERROR, ARGV0, path, errno, strerror(errno));
    }

    /* Check permissions */
    fp = fopen(openarmorCONF, "r");
    if (fp) {
        fclose(fp);
    } else {
        ErrorExit(CONF_ERROR, openarmorCONF);
    }
#endif

    if (cmdlist == 1) {
        list_agents(cmdlist);
        exit(0);
    } else if (cmdimport) {
        k_import(cmdimport);
        exit(0);
    } else if (cmdexport) {
        k_extract(cmdexport, json_output);
        exit(0);
    } else if (cmdbulk) {
        k_bulkload(cmdbulk);
        exit(0);
    }

    /* Little shell */
    while (1) {
        int leave_s = 0;

        if (!json_output)
            print_banner();


        /* Get ACTION from the environment. If ACTION is specified,
         * we must set leave_s = 1 to ensure that the loop will end */
        user_msg = getenv("openarmor_ACTION");
        if (user_msg == NULL) {
            user_msg = read_from_user();
        } else {
            leave_s = 1;
        }

        /* All the allowed actions */
        switch (user_msg[0]) {
            case 'A':
            case 'a':
#ifdef CLIENT
                printf("\n ** Agent adding only available on a master ** \n\n");
                break;
#endif
                add_agent(json_output);
                break;
            case 'e':
            case 'E':
#ifdef CLIENT
                printf("\n ** Key export only available on a master ** \n\n");
                break;
#endif
                k_extract(NULL, json_output);
                break;
            case 'i':
            case 'I':
#ifndef CLIENT
                printf("\n ** Key import only available on an agent ** \n\n");
                break;
#else //CLIENT
                k_import(NULL);
                break;
#endif
            case 'l':
            case 'L':
                list_agents(0);
                break;
            case 'r':
            case 'R':
#ifdef CLIENT
                printf("\n ** Key removal only available on a master ** \n\n");
                break;
#endif
                remove_agent(json_output);
                break;
            case 'q':
            case 'Q':
                leave_s = 1;
                break;
            case 'V':
                print_version();
                break;
            default:
                printf("\n ** Invalid Action ** \n\n");
                break;
        }

        if (leave_s) {
            break;
        }

        continue;
    }

    if (!json_output) {
        if (restart_necessary) {
            printf(MUST_RESTART);
        } else {
            printf("\n");
        }

        printf(EXIT);
    }
    printf(EXIT);

    return (0);
}

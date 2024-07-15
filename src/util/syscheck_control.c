/* Copyright (C) 2019 openarmor Foundation
 * All right reserved.
 *
 * This program is a free software; you can redistribute it
 * and/or modify it under the terms of the GNU General Public
 * License (version 2) as published by the FSF - Free Software
 * Foundation
 */

#include "addagent/manage_agents.h"
#include "sec.h"

#undef ARGV0
#define ARGV0 "syscheck_control"

/* Prototypes */
static void helpmsg(void) __attribute__((noreturn));


static void helpmsg()
{
    printf("\nopenarmor HIDS %s: Manages the integrity checking database.\n",
           ARGV0);
    printf("Available options:\n");
    printf("\t-h          This help message.\n");
    printf("\t-l          List available (active or inactive) agents.\n");
    printf("\t-lc         List only active agents.\n");
    printf("\t-u <id>     Updates (clears) the database for the agent.\n");
    printf("\t-u all      Updates (clears) the database for all agents.\n");
    printf("\t-i <id>     List modified files for the agent.\n");
    printf("\t-r -i <id>  List modified registry entries for the agent "
           "(Windows only).\n");
    printf("\t-f <file>   Prints information about a modified file.\n");
    printf("\t            Must be used with -i <id>.\n");
    printf("\t-z          Used with -f, zeroes the auto-ignore counter.\n");
    printf("\t-d          Used with -f, ignores that file.\n");
    printf("\t-s          Changes the output to CSV (comma delimited).\n");
    printf("\t-j          Changes the output to JSON.\n");
    printf("\n");
    printf("\tExamples:\n");
    printf("\n");
    printf("\t'Show information about /etc/passwd from agent with ID 019'\n");
    printf("\t%s -i 019 -f /etc/passwd\n", ARGV0);
    exit(1);
}

int main(int argc, char **argv)
{
    const char *dir = DEFAULTDIR;
    const char *group = GROUPGLOBAL;
    const char *user = USER;
    const char *agent_id = NULL;
    const char *fname = NULL;

    gid_t gid;
    uid_t uid;
    int c = 0, info_agent = 0, update_syscheck = 0,
        list_agents = 0, zero_counter = 0,
        registry_only = 0;
    int active_only = 0, csv_output = 0, json_output = 0;

    char shost[512];
    cJSON *json_root;

    /* Set the name */
    OS_SetName(ARGV0);

    /* User arguments */
    if (argc < 2) {
        helpmsg();
    }

    while ((c = getopt(argc, argv, "VhzrDdlcsju:i:f:")) != -1) {
        switch (c) {
            case 'V':
                print_version();
                break;
            case 'h':
                helpmsg();
                break;
            case 'D':
                nowDebug();
                break;
            case 'l':
                list_agents++;
                break;
            case 'z':
                zero_counter = 1;
                break;
            case 'd':
                zero_counter = 2;
                break;
            case 's':
                csv_output = 1;
                break;
            case 'j':
                json_output = 1;
                break;
            case 'c':
                active_only++;
                break;
            case 'r':
                registry_only = 1;
                break;
            case 'i':
                info_agent++;
                if (!optarg) {
                    merror("%s: -u needs an argument", ARGV0);
                    helpmsg();
                }
                agent_id = optarg;
                break;
            case 'f':
                if (!optarg) {
                    merror("%s: -u needs an argument", ARGV0);
                    helpmsg();
                }
                fname = optarg;
                break;
            case 'u':
                if (!optarg) {
                    merror("%s: -u needs an argument", ARGV0);
                    helpmsg();
                }
                agent_id = optarg;
                update_syscheck = 1;
                break;
            default:
                helpmsg();
                break;
        }
    }

    /* Get the group name */
    gid = Privsep_GetGroup(group);
    uid = Privsep_GetUser(user);
    if (uid == (uid_t) - 1 || gid == (gid_t) - 1) {
        ErrorExit(USER_ERROR, ARGV0, user, group);
    }

    /* Set the group */
    if (Privsep_SetGroup(gid) < 0) {
        ErrorExit(SETGID_ERROR, ARGV0, group, errno, strerror(errno));
    }

    /* Chroot to the default directory */
    if (Privsep_Chroot(dir) < 0) {
        ErrorExit(CHROOT_ERROR, ARGV0, dir, errno, strerror(errno));
    }

    /* Inside chroot now */
    nowChroot();

    /* Set the user */
    if (Privsep_SetUser(uid) < 0) {
        ErrorExit(SETUID_ERROR, ARGV0, user, errno, strerror(errno));
    }

    /* Get server hostname */
    memset(shost, '\0', 512);
    if (gethostname(shost, 512 - 1) != 0) {
        strncpy(shost, "localhost", 32);
        return (0);
    }

    if (json_output)
        json_root = cJSON_CreateObject();

    /* List available agents */
    if (list_agents) {
        cJSON *json_agents = NULL;

        if (json_output) {
            cJSON *first = cJSON_CreateObject();
            json_agents = cJSON_CreateArray();
            cJSON_AddNumberToObject(json_root, "error", 0);
            cJSON_AddStringToObject(first, "id", "000");
            cJSON_AddStringToObject(first, "name", shost);
            cJSON_AddStringToObject(first, "ip", "127.0.0.1");
            cJSON_AddStringToObject(first, "status", "Active");
            cJSON_AddItemToArray(json_agents, first);
        } else if (csv_output)
            printf("000,%s (server),127.0.0.1,Active/Local,\n", shost);
        else {
            printf("\nopenarmor HIDS %s. List of available agents:", ARGV0);
            printf("\n   ID: 000, Name: %s (server), IP: 127.0.0.1, "
                   "Active/Local\n", shost);
        }

        print_agents(1, active_only, csv_output, json_agents);

        if (json_output) {
            cJSON_AddItemToObject(json_root, "response", json_agents);
            printf("%s", cJSON_PrintUnformatted(json_root));
        } else
            printf("\n");

        exit(0);
    }

    /* Update syscheck database */
    if (update_syscheck) {
        /* Clean all agents (and server) db */
        if (strcmp(agent_id, "all") == 0) {
            DIR *sys_dir;
            struct dirent *entry;

            sys_dir = opendir(SYSCHECK_DIR);
            if (!sys_dir) {
                if (json_output) {
                    char buffer[1024];
                    cJSON_AddNumberToObject(json_root, "error", 31);
                    snprintf(buffer, 1023, "%s: Unable to open: '%s'", ARGV0, SYSCHECK_DIR);
                    cJSON_AddStringToObject(json_root, "description", buffer);
                    printf("%s", cJSON_PrintUnformatted(json_root));
                    exit(1);
                } else
                    ErrorExit("%s: Unable to open: '%s'", ARGV0, SYSCHECK_DIR);
            }

            while ((entry = readdir(sys_dir)) != NULL) {
                FILE *fp;
                char full_path[OS_MAXSTR + 1];

                /* Do not even attempt to delete . and .. :) */
                if ((strcmp(entry->d_name, ".") == 0) ||
                        (strcmp(entry->d_name, "..") == 0)) {
                    continue;
                }

                snprintf(full_path, OS_MAXSTR, "%s/%s", SYSCHECK_DIR,
                         entry->d_name);

                fp = fopen(full_path, "w");
                if (fp) {
                    fclose(fp);
                } else {
                    ErrorExit("%s: ERROR: Cannot open %s: %s", ARGV0, full_path, strerror(errno));
                }
                if (entry->d_name[0] == '.') {
                    if ((unlink(full_path)) != 0) {
                        ErrorExit("%s: ERROR: Cannot delete %s: %s", ARGV0, full_path, strerror(errno));
                    }
                }
            }

            closedir(sys_dir);

            if (json_output) {
                cJSON_AddNumberToObject(json_root, "error", 0);
                cJSON_AddStringToObject(json_root, "response", "Integrity check database updated");
                printf("%s", cJSON_PrintUnformatted(json_root));
            } else
                printf("\n** Integrity check database updated.\n\n");

            exit(0);
        }

        else if ((strcmp(agent_id, "000") == 0) ||
                 (strcmp(agent_id, "local") == 0)) {
            char final_dir[1024];
            FILE *fp;
            snprintf(final_dir, 1020, "/%s/syscheck", SYSCHECK_DIR);

            fp = fopen(final_dir, "w");
            if (fp) {
                fclose(fp);
            } else {
                ErrorExit("%s: ERROR: Cannot open %s: %s", ARGV0, final_dir, strerror(errno));
            }
            if ((unlink(final_dir)) != 0) {
                ErrorExit("%s: ERROR: Cannot delete %s: %s", ARGV0, final_dir, strerror(errno));
            }


            /* Deleting cpt file */
            snprintf(final_dir, 1020, "/%s/.syscheck.cpt", SYSCHECK_DIR);

            fp = fopen(final_dir, "w");
            if (fp) {
                fclose(fp);
            } else {
                ErrorExit("%s: ERROR: Cannot open %s: %s", ARGV0, final_dir, strerror(errno));
            }
            if ((unlink(final_dir)) != 0) {
                ErrorExit("%s: ERROR: Cannot delete %s: %s", ARGV0, final_dir, strerror(errno));
            }

            if (json_output) {
                cJSON_AddNumberToObject(json_root, "error", 0);
                cJSON_AddStringToObject(json_root, "response", "Integrity check database updated");
                printf("%s", cJSON_PrintUnformatted(json_root));
            } else
                printf("\n** Integrity check database updated.\n\n");

            exit(0);
        }

        /* Database from remote agents */
        else {
            int i;
            keystore keys;

            OS_ReadKeys(&keys);

            i = OS_IsAllowedID(&keys, agent_id);
            if (i < 0) {
                if (json_output) {
                    char buffer[1024];
                    cJSON_AddNumberToObject(json_root, "error", 33);
                    snprintf(buffer, 1023, "Invalid agent id '%s'.", agent_id);
                    cJSON_AddStringToObject(json_root, "description", buffer);
                    printf("%s", cJSON_PrintUnformatted(json_root));
                    exit(1);
                } else {
                    printf("\n** Invalid agent id '%s'.\n", agent_id);
                    helpmsg();
                }
            }

            /* Delete syscheck */
            delete_syscheck(keys.keyentries[i]->name,
                            keys.keyentries[i]->ip->ip, 0);

            if (json_output) {
                cJSON_AddNumberToObject(json_root, "error", 0);
                cJSON_AddStringToObject(json_root, "response", "Integrity check database updated");
                printf("%s", cJSON_PrintUnformatted(json_root));
            } else
                printf("\n** Integrity check database updated.\n\n");

            exit(0);
        }
    }

    /* Print information from an agent */
    if (info_agent) {
        int i;
        char final_ip[IPSIZE + 4];
        keystore keys;
        cJSON *json_entries = NULL;

        if (json_output)
            json_entries = cJSON_CreateArray();

        if ((strcmp(agent_id, "000") == 0) ||
                (strcmp(agent_id, "local") == 0)) {
            if (!(csv_output || json_output)) {
                printf("\nIntegrity checking changes for local system '%s - %s':\n",
                       shost, "127.0.0.1");
                if (fname) {
                    printf("Detailed information for entries matching: '%s'\n",
                           fname);
                }
            }

            print_syscheck(NULL, NULL, fname, 0, 0, csv_output, json_entries, zero_counter);
        } else if (strchr(agent_id, '@')) {
            if (fname && ! (csv_output || json_output)) {
                printf("Detailed information for entries matching: '%s'\n",
                       fname);
            }
            print_syscheck(agent_id, NULL, fname, registry_only, 0,
                           csv_output, json_entries, zero_counter);
        } else {

            OS_ReadKeys(&keys);

            i = OS_IsAllowedID(&keys, agent_id);
            if (i < 0) {
                if (json_output) {
                    char buffer[1024];
                    cJSON_AddNumberToObject(json_root, "error", 32);
                    snprintf(buffer, 1023, "Invalid agent id '%s'.", agent_id);
                    cJSON_AddStringToObject(json_root, "description", buffer);
                    printf("%s", cJSON_PrintUnformatted(json_root));
                    exit(1);
                } else {
                    printf("\n** Invalid agent id '%s'.\n", agent_id);
                    helpmsg();
                }
            }

            /* Getting full address/prefix length from ip. */
            final_ip[(sizeof final_ip) - 1] = '\0';
            snprintf(final_ip, sizeof final_ip, "%s/%u",
                     keys.keyentries[i]->ip->ip,
                     keys.keyentries[i]->ip->prefixlength);

            if (!(csv_output || json_output)) {
                if (registry_only) {
                    printf("\nIntegrity changes for 'Windows Registry' of"
                           " agent '%s (%s) - %s':\n",
                           keys.keyentries[i]->name, keys.keyentries[i]->id,
                           final_ip);
                } else {
                    printf("\nIntegrity changes for agent "
                           "'%s (%s) - %s':\n",
                           keys.keyentries[i]->name, keys.keyentries[i]->id,
                           final_ip);
                }

                if (fname) {
                    printf("Detailed information for entries matching: '%s'\n",
                           fname);
                }
            }

            print_syscheck(keys.keyentries[i]->name, keys.keyentries[i]->ip->ip, fname,
                           registry_only, 0, csv_output, json_entries, zero_counter);
        }

        if (json_output) {
            cJSON_AddNumberToObject(json_root, "error", 0);
            cJSON_AddItemToObject(json_root, "response", json_entries);
            printf("%s", cJSON_PrintUnformatted(json_root));
        }

        exit(0);
    }

    if (json_output) {
        cJSON_AddNumberToObject(json_root, "error", 30);
        cJSON_AddStringToObject(json_root, "description", "Invalid argument combination");
        printf("%s", cJSON_PrintUnformatted(json_root));
        exit(1);
    } else {
        printf("\n** Invalid argument combination.\n");
        helpmsg();
    }

    return (0);
}

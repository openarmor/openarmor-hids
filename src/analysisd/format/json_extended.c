/* Copyright (C) 2015 Wazuh Inc
 * All rights reserved.
 *
 */

#include "json_extended.h"
#include <stddef.h>

#define MAX_MATCHES 10
#define MAX_STRING 1024
#define MAX_STRING_LESS 30

void W_ParseJSON(cJSON* root, const Eventinfo* lf)
{

    // Parse hostname & Parse AGENTIP
    if(lf->hostname) {
        W_JSON_ParseHostname(root, lf->hostname);
        W_JSON_ParseAgentIP(root, lf);
    }
    // Parse timestamp
    if(lf->year && (strnlen(lf->mon, 3) > 0) && lf->day && (strnlen(lf->hour, 2) > 0)) {
        W_JSON_ParseTimestamp(root, lf);
    }
    // Parse Location
    if(lf->location) {
        W_JSON_ParseLocation(root, lf, 0);
    }
    // Parse groups && Parse PCIDSS && Parse CIS
    if(lf->generated_rule->group) {
        W_JSON_ParseGroups(root, lf, 1);
    }
    // Parse CIS and PCIDSS rules from rootcheck .txt benchmarks
    if(lf->full_log && W_isRootcheck(root, 1)) {
        W_JSON_ParseRootcheck(root, lf, 1);
    }
}


// Detect if the alert is coming from rootcheck controls.

int W_isRootcheck(cJSON* root, int nested)
{
    cJSON* groups;
    cJSON* group;
    cJSON* rule;
    char* group_json;

    int totalGroups, i;

    if(!nested)
        rule = root;
    else
        rule = cJSON_GetObjectItem(root, "rule");

    groups = cJSON_GetObjectItem(rule, "groups");
    totalGroups = cJSON_GetArraySize(groups);
    for(i = 0; i < totalGroups; i++) {
        group = cJSON_GetArrayItem(groups, i);
        group_json = cJSON_Print(group);
        if(strcmp(group_json, "\"rootcheck\"") == 0) {
            free(group_json);
            return 1;
        }
        free(group_json);
    }
    return 0;
}


// Getting security compliance field from rootcheck rules benchmarks .txt
void W_JSON_ParseRootcheck(cJSON* root, const Eventinfo* lf, int nested)
{
    regex_t r;
    cJSON* rule;
    cJSON* compliance;
    const char* regex_text;
    const char* find_text;
    char* token;
    char* token2;
    char* results[MAX_MATCHES];
    int matches, i, j;
    const char delim[2] = ":";
    const char delim2[2] = ",";
    char fullog[MAX_STRING];

    // Allocate memory
    for(i = 0; i < MAX_MATCHES; i++)
        results[i] = malloc((MAX_STRING_LESS) * sizeof(char));

    // Getting groups object JSON
    if(!nested)
        rule = root;
    else
        rule = cJSON_GetObjectItem(root, "rule");

    // Getting full log string
    strncpy(fullog, lf->full_log, MAX_STRING - 1);
    // Searching regex
    regex_text = "\\{([A-Za-z0-9_]*: [A-Za-z0-9_., ]*)\\}";
    find_text = fullog;
    compile_regex(&r, regex_text);
    matches = match_regex(&r, find_text, results);

    if(matches > 0) {
        for(i = 0; i < matches; i++) {
            token = strtok(results[i], delim);

            trim(token);
            cJSON_AddItemToObject(rule, token, compliance = cJSON_CreateArray());
            for(j = 0; token[j]; j++) {
                token[j] = tolower(token[j]);
            }
            if(token) {
                token = strtok(0, delim);
                trim(token);
                token2 = strtok(token, delim2);
                while(token2) {

                    trim(token2);
                    cJSON_AddItemToArray(compliance, cJSON_CreateString(token2));
                    token2 = strtok(0, delim2);
                }
            }
        }
     }
    regfree(&r);
    for(i = 0; i < MAX_MATCHES; i++)
         free(results[i]);
}



// STRTOK every "-" delimiter to get differents groups to our json array.
void W_JSON_ParseGroups(cJSON* root, const Eventinfo* lf, int nested)
{
    cJSON* groups;
    cJSON* rule;
    int firstPCI, firstCIS, foundCIS, foundPCI;
    char delim[2];
    char buffer[MAX_STRING];
    char* token;

    firstPCI = firstCIS = 1;
    foundPCI = foundCIS = 0;
    delim[0] = ',';
    delim[1] = 0;

    if(!nested)
        rule = root;
    else
        rule = cJSON_GetObjectItem(root, "rule");

    cJSON_AddItemToObject(rule, "groups", groups = cJSON_CreateArray());
    strncpy(buffer, lf->generated_rule->group, sizeof(buffer) - 1);

    token = strtok(buffer, delim);
    while(token) {
        foundPCI = foundCIS = 0;
        foundPCI = add_groupPCI(rule, token, firstPCI);
        if(!foundPCI)
            foundCIS = add_groupCIS(rule, token, firstCIS);

        if(foundPCI && firstPCI)
            firstPCI = 0;
        if(foundCIS && firstCIS)
            firstCIS = 0;

        if(!foundPCI && !foundCIS) {
            cJSON_AddItemToArray(groups, cJSON_CreateString(token));
        }
        token = strtok(0, delim);
    }
}


 // Parse groups PCI
int add_groupPCI(cJSON* rule, char* group, int firstPCI)
{
    //char* len = NULL;
    cJSON* pci;
    char aux[strlen(group)];
    // If group begin with pci_dss_ we have a PCI group
    if((startsWith("pci_dss_", group)) == 1) {
        // Once we add pci_dss group and create array for PCI_DSS requirements
        if(firstPCI == 1) {
            pci = cJSON_CreateArray();
            cJSON_AddItemToObject(rule, "PCI_DSS", pci);
        } else {
            pci = cJSON_GetObjectItem(rule, "PCI_DSS");
        }
        // Prepare string and add it to PCI dss array
        strncpy(aux, group, strlen(group) - 1 );
        str_cut(aux, 0, 8);
        cJSON_AddItemToArray(pci, cJSON_CreateString(aux));
        return 1;
    }
    return 0;
}


int add_groupCIS(cJSON* rule, char* group, int firstCIS)
{
    //char* len = NULL;
    cJSON* cis;
    char aux[strlen(group)];
    if((startsWith("cis_", group)) == 1) {
        if(firstCIS == 1) {
            cis = cJSON_CreateArray();
            cJSON_AddItemToObject(rule, "CIS", cis);
        } else {
            cis = cJSON_GetObjectItem(rule, "CIS");
        }
        strncpy(aux, group, strlen(group) - 1);
        str_cut(aux, 0, 4);
        cJSON_AddItemToArray(cis, cJSON_CreateString(aux));
        return 1;
    }
    return 0;
}


// If hostname being with "(" means that alerts came from an agent, so we will remove the brakets
// ** TODO ** Regex instead str_cut
void W_JSON_ParseHostname(cJSON* root, char* hostname)
{
    if(hostname[0] == '(') {
        char* search;
        char string[MAX_STRING];
        strncpy(string, hostname, MAX_STRING - 1);
        int index;
        search = strchr(string, ')');
        if(search) {
            index = (int)(search - string);
            str_cut(string, index, -1);
            str_cut(string, 0, 1);
            cJSON_AddStringToObject(root, "agent_name", string);
        }
    } else {
        cJSON_AddStringToObject(root, "agent_name", hostname);
    }
}
// Parse timestamp
void W_JSON_ParseTimestamp(cJSON* root, const Eventinfo* lf)
{
    char* dateTimestamp = malloc(21);
    sprintf(dateTimestamp, "%d %s %02d %s", lf->year, lf->mon, lf->day, lf->hour);
    cJSON_AddStringToObject(root, "timestamp", dateTimestamp);
    free(dateTimestamp);
}


// The IP of an agent usually comes in "hostname" field, we will extract it.
// ** TODO ** Regex instead str_cut
void W_JSON_ParseAgentIP(cJSON* root, const Eventinfo* lf)
{
    if(lf->hostname[0] == '(') {
        char* search;
        char string[MAX_STRING];
        strncpy(string, lf->hostname, MAX_STRING - 1);
        int index;
        search = strchr(string, ')');
        if(search) {
            index = (int)(search - string);
            str_cut(string, 0, index);
            str_cut(string, 0, 2);
            search = strchr(string, '-');
            index = (int)(search - string);
            str_cut(string, index, -1);
            cJSON_AddStringToObject(root, "agentip", string);
        }

    }
}
 // The file location usually comes with more information about the alert (like hostname or ip) we will extract just the "/var/folder/file.log".
void W_JSON_ParseLocation(cJSON* root, const Eventinfo* lf, int archives)
{
    if (archives != 0) {
        debug1("openarmor-analysisd: DEBUG: archives != 0");
    }
    if(lf->location[0] == '(') {
        char* search;
        char string[MAX_STRING];
        strncpy(string, lf->location, MAX_STRING - 1);
        int index;
        search = strchr(string, '>');
        if(search) {
            index = (int)(search - string);
            str_cut(string, 0, index);
            str_cut(string, 0, 1);

            cJSON_AddStringToObject(root, "logfile", string);
        }
    } else {
        cJSON_AddStringToObject(root, "logfile", lf->location);
    }
}


#define MAX_ERROR_MSG 0x1000
// Regex compilator
int compile_regex(regex_t* r, const char* regex_text)
{
    int status = regcomp(r, regex_text, REG_EXTENDED | REG_NEWLINE);
    if(status != 0) {
        char error_message[MAX_ERROR_MSG];
        regerror(status, r, error_message, MAX_ERROR_MSG);
        debug1("Regex error compiling '%s': %s\n", regex_text, error_message);
        return 1;
    }
    return 0;
}

int match_regex(regex_t* r, const char* to_match, char* results[MAX_MATCHES])
{
    const char* p = to_match;
    const int n_matches = 10;
    regmatch_t m[n_matches];
    int totalResults = 0;
    while(1) {
        int i = 0;
        int nomatch = regexec(r, p, n_matches, m, 0);
        if(nomatch) {
            //printf ("No more matches.\n");
            return totalResults;
        }
        for(i = 0; i < n_matches; i++) {
            int start;
            int finish;
            if(m[i].rm_so == -1) {

                break;
            }
            start = m[i].rm_so + (p - to_match);
            finish = m[i].rm_eo + (p - to_match);
            if(i > 0) {
                sprintf(results[totalResults], "%.*s", (finish - start), to_match + start);
                totalResults = totalResults + 1;
            }

        }
        p += m[0].rm_eo;
    }
    return 0;
}

int str_cut(char* str, int begin, int len)
{
    int l = strlen(str);

    if(len < 0)
        len = l - begin;
    if(begin + len > l)
        len = l - begin;
    memmove(str + begin, str + begin + len, l - len + 1);

    return len;
}

void trim(char* s)
{
    char* p = s;
    int l = strlen(p);

    while(isspace(p[l - 1]))
        p[--l] = 0;
    while(*p && isspace(*p))
        ++p, --l;

    memmove(s, p, l + 1);
}

int startsWith(const char *pre, const char *str)
{
    size_t lenpre = strlen(pre),
           lenstr = strlen(str);
    return lenstr < lenpre ? 0 : strncmp(pre, str, lenpre) == 0;
}


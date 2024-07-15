/* Copyright (C) 2009 Trend Micro Inc.
 * All rights reserved.
 *
 * This program is a free software; you can redistribute it
 * and/or modify it under the terms of the GNU General Public
 * License (version 2) as published by the FSF - Free Software
 * Foundation.
 */

#ifndef __DECODER_H
#define __DECODER_H

#include "shared.h"
#include "os_regex/os_regex.h"

#define AFTER_PARENT    0x001   /* 1   */
#define AFTER_PREMATCH  0x002   /* 2   */
#define AFTER_PREVREGEX 0x004   /* 4   */
#define AFTER_ERROR     0x010

struct _Eventinfo;


/* Decoder structure */
typedef struct {
    u_int8_t  get_next;
    u_int8_t  type;
    u_int8_t  use_own_name;

    u_int16_t id;
    u_int16_t regex_offset;
    u_int16_t prematch_offset;

    int fts;
    int accumulate;
    char *parent;
    char *name;
    char *ftscomment;
    char **fields;



    OSRegex *regex;
    OSRegex *prematch;
    OSMatch *program_name;

    OSPcre2 *pcre2;
    OSPcre2 *prematch_pcre2;
    OSPcre2 *program_name_pcre2;

    void (*plugindecoder)(void *lf);
    void* (**order)(struct _Eventinfo *, char *, int);
} OSDecoderInfo;

/* List structure */
typedef struct _OSDecoderNode {
    struct _OSDecoderNode *next;
    struct _OSDecoderNode *child;
    OSDecoderInfo *osdecoder;
} OSDecoderNode;

/* Functions to Create the list, add a osdecoder to the
 * list and to get the first osdecoder
 */
void OS_CreateOSDecoderList(void);
int OS_AddOSDecoder(OSDecoderInfo *pi);
OSDecoderNode *OS_GetFirstOSDecoder(const char *pname);
int getDecoderfromlist(const char *name);
char *GetGeoInfobyIP(char *ip_addr);
int SetDecodeXML(void);
void HostinfoInit(void);
void SyscheckInit(void);
void RootcheckInit(void);

int ReadDecodeXML(const char *file);

#endif


/*
 *
 * $Id: chkseq.h,v 1.2 2000/01/12 15:19:36 kenji Exp $
 *
 * joy 5.0 release $Name:  $
 */
#ifndef __chkseq
#define __chkseq

int chkseq(ALIFAM *, PSA *, SST *, HBD *);
int isgap(char);
char *throne (int, char **);
int toLowerCase(ALIFAM *);

#endif

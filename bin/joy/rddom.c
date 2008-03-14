/*
 *
 * $Id: rddom.c,v 1.2 2000/05/17 18:20:33 kenji Exp $
 *
 * joy 5.0 release $Name:  $
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <parse.h>

#include "rdali.h"
#include "rdpsa.h"
#include "rdsst.h"
#include "rdhbd.h"
#include "tem.h"
#include "gen_html.h"
#include "utility.h"
#include "rddom.h"

domain dom[MAXDOMAIN],domtmp[MAXDOMAIN];

int rddomain(ALIFAM *alifam) {   /* contribution by Jiye Shi */
  char *dom_filename;
  FILE *fp;
  int i, j, k;
  int domainno;
  int lastposition;

  char domainline[3000];

  dom_filename = mstrcat(alifam->code, DOM_SUFFIX);
  fp = fopen(dom_filename, "r");
  if (fp == NULL) {
    return (-1);
  }
  fprintf(stderr, "Domain assignment read in from %s\n", dom_filename);

/* Initialize the domain structure */

  for(i=0;i<MAXDOMAIN;i++) {
    dom[i].id=0;
    dom[i].segno=0;
  }

/* Read in domain definition */

  fscanf(fp,"%*s%d  ",&domainno);
  lastposition=0;
  for(i=0;i<domainno;i++) {
    fscanf(fp,"{%d:%d:",&dom[i].id,&dom[i].segno);
    for(j=1;j<=dom[i].segno;j++) {
      fscanf(fp,"(%d,%c,%d,%c)",&dom[i].seg[j].startno,
	     &dom[i].seg[j].startchain,&dom[i].seg[j].endno,
	     &dom[i].seg[j].endchain);
/* Get a line for domain definition */
      for(k=dom[i].seg[j].startno-1;k<=dom[i].seg[j].endno-1;k++)
	domainline[k]='1'+dom[i].id-1;
      if(lastposition<dom[i].seg[j].endno) lastposition=dom[i].seg[j].endno;
    }
    fscanf(fp,"}  ");
  }
  fclose(fp);
  domainline[lastposition]='\0';

/* debug -- print out the definition
   for(i=0;i<MAXDOMAIN;i++) {
     if(dom[i].id!=0) {
       printf("  {%d:%d:",dom[i].id,dom[i].segno);
       for(j=1;j<=dom[i].segno;j++) {
	 printf("(%d,%c,%d,%c)",dom[i].seg[j].startno,
		dom[i].seg[j].startchain,dom[i].seg[j].endno,dom[i].seg[j].endchain);
       }
       printf("}");
     }
   }
  printf("\n");

  debug -- end */

  return domainno;
}

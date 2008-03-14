/*
 *
 * $Id: tag.c,v 1.7 2000/12/18 10:00:54 kenji Exp $
 *
 * joy 5.0 release $Name:  $
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>

#include <parse.h>
#include "typeset.h"

#include "utility.h"
#include "rdali.h"
#include "rdpsa.h"
#include "rdsst.h"
#include "rdhbd.h"
#include "tem.h"
#include "tag.h"
#include "gen_html.h"
#include "gen_rtf.h"
#include "analysis.h"
#include "rddom.h"

html_style *set_default(html_style *tagged_style, html_style *notag_style,
			int nt, int ns) {
  html_style *style;
  int i;

  style = (html_style *)malloc((size_t) ((nt + ns) * sizeof(html_style)));

  if (style == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(-1);
  }
  if (strcmp(VS(V_FEATURE_SET), "default") != 0) {
    fprintf(stderr, "Error: inconsistency between .tem and .html files\n");
    fprintf(stderr, "       A non-default feature set has been specified, but the\n");
    fprintf(stderr, "       HTML typesetting code is for the default feature set.\n");
    fprintf(stderr, "       You must supply your own joytypeset file.\n");
    return NULL;
  }
  for (i=0; i<nt; i++) {
    style[i].feature = tagged_style[i].feature;
    style[i].value = tagged_style[i].value;
    style[i].num = tagged_style[i].num;
    style[i].name = strdup(tagged_style[i].name);
    style[i].description = strdup(tagged_style[i].description);
  }
  for (i=0; i<ns; i++) {
    style[i+nt].feature = notag_style[i].feature;
    style[i+nt].value = notag_style[i].value;
    style[i+nt].num = notag_style[i].num;
    style[i+nt].name = strdup(notag_style[i].name);
    style[i+nt].description = strdup(notag_style[i].description);
  }
  return style;
}

void freeTag(TagAll *alltag, int nstr, int alilen) {
  int i, j;
  Tag *tags;

  for (i=0; i<nstr; i++) {
    tags = alltag[i].tags;
    for (j=0; j<alilen; j++) {
      free(tags[j].begin);
      free(tags[j].end);
    }
    free(alltag[i].tags);
  }
  free(alltag);
}

Tag *assignTag(int nf, int alilen, int istr,
	       TEM *temall, html_style *style, int nwidth) {
  Tag *tags;
  char assign;
  int i, j, k;
  int ib, strt, end;
  int *prev;
  int *curr;
  char *endlst;
  char *beglst;
  int *lenlst;
  int nb;   /* number of tags starting (<..>) at a particular position */
  int ne;   /* number of tags ending (</..>) at a particular position */
  char isEnd;
  int maxlen;

  tags = (Tag *) malloc(sizeof(Tag) * alilen);
  if (tags == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(-1);
  }

  if (nf <= 0) {
    fprintf(stderr, "Error: no of structural feature used is %d\n", nf);
    return NULL;
  }
  curr = ivector(nf);
  prev = ivector(nf);
  endlst = cvector(nf);
  beglst = cvector(nf);
  lenlst = ivector(nf);

  for (j=0; j<alilen; j++) {
    tags[j].nb = 0;
    tags[j].ne = 0;
  }

  ib = 0;
  while (1) {
    strt = nwidth * ib;
    if (strt >= alilen) break;

    end = strt + nwidth;
    if (end >= alilen) end = alilen;

    /* initialization */
  
    nb = 0;
    for (i=0; i<nf; i++) {
      assign = temall[istr].feature[style[i].feature].assign[strt];
      if (assign == style[i].value) {
	prev[i] = 1;
	nb++;
      }
      else {
	prev[i] = 0;
      }
    }
    tags[strt].nb = nb;
    if (nb > 0) {
      tags[strt].begin = cvector(nb);
      k = 0;
      for (i=0; i<nf; i++) {
	if (prev[i] == 1) {
	  tags[strt].begin[k] = i;  /* stores style numbers */
	  k++;
	}
      }
    }

    /* Loop */

    for (j=strt+1; j<end; j++) {

      /* first see if any tag ends here */

      isEnd = 0;
      maxlen = -1;
      for (i=0; i<nf; i++) {
	assign = temall[istr].feature[style[i].feature].assign[j];

	if (assign == style[i].value) {
	  curr[i] = 1;
	}
	else {
	  curr[i] = 0;
	}
	if (curr[i] == 0 && prev[i] > 0) {  /* end of a tag at j-1 */
	  isEnd = 1;
	  if (prev[i] > maxlen) maxlen = prev[i];
	}
      }
      if (isEnd == 1) { /* all tags being 'on' for less then 'maxlen' have to end */
	ne = 0;
	for (i=nf-1; i>=0; i--) {   /* a trick to avoid <u><b>A</u></b>
				    (the correct order is <u><b> </b></u> */

	  if ((prev[i] > 0 && curr[i]==0) ||
	      (prev[i] > 0 && prev[i] <= maxlen)) { /* end this tag */
	    endlst[ne] = i;
	    lenlst[ne] = prev[i];
	    prev[i] = 0;     /* clear on flags */
	    ne++;
	  }
	}

	/* sort endlst in ascending order according to lenlst */
	sortLst(endlst, 0, ne-1, lenlst);

	/* store this info at j-1*/

	tags[j-1].ne = ne;

	/* isEnd = 1 meaning at least one tag ends at j-1
           therefore ne must be >0, but in case things went wrong... */

	if (ne > 0) {
	  tags[j-1].end = cvector(ne);
	  for (k=0; k<ne; k++) {
	    tags[j-1].end[k] = endlst[k];
	  }
	}
	else {
	  fprintf(stderr, "Warning: Some structural features seem to ");
	  fprintf(stderr, "change states at position %d of %dth structure\n",
		  j-1, istr);
	  fprintf(stderr, "but the program failed to interpret this information ");
	  fprintf(stderr, "properly and the HTML format around this position ");
	  fprintf(stderr, "is likely to be incorrect.\n");
	}
      }

      /* second, see if any tag begins here */

      nb = 0;
      for (i=0; i<nf; i++) {
	if (curr[i] == 1 && prev[i] == 0) {
	  beglst[nb] = i;
	  nb++;	  
	}
	else if (curr[i] == 1 && prev[i] > 0) {  /* continuation of the 'on' state */
	  curr[i] = prev[i] + 1;
	}
	prev[i] = curr[i];   /* for the next step */
      }

      /* store this info  at j */
      tags[j].nb = nb;
      if (nb > 0) {
	tags[j].begin = cvector(nb);
	for (k=0; k<nb; k++) {
	  tags[j].begin[k] = beglst[k];
	}
      }
    }

    /* finishing */
    ne = 0;
    for (i=nf-1; i>=0; i--) {
      /* every on state has to terminate */

      if (prev[i] > 0) { /* end this tag */
	endlst[ne] = i;
	lenlst[ne] = prev[i];
	ne++;
      }
    }

    if (ne > 0) {
      /* sort @index in ascending order according to @len */
      sortLst(endlst, 0, ne-1, lenlst);

      /* store this info at end-1*/
      tags[end-1].ne = ne;
      tags[end-1].end = cvector(ne);
      for (k=0; k<ne; k++) {
	tags[end-1].end[k] = endlst[k];
      }
    }

    ib++;
  }
  free(curr);
  free(prev);
  free(endlst);
  free(beglst);
  free(lenlst);

/* debugging */
/*
  for (i=0; i<alilen; i++) {
    if (tags[i].nb > 0) {
      printf("pos %d nb %d (", i, tags[i].nb);
      for (j=0; j<tags[i].nb; j++) {
	printf("%d ", tags[i].begin[j]);
      }
      printf(")\n");
    }
    if (tags[i].ne > 0) {
      printf("pos %d ne %d (", i, tags[i].ne);
      for (j=0; j<tags[i].ne; j++) {
	printf("%d ", tags[i].end[j]);
      }
      printf(")\n");
    }
  }
*/
  return (tags);
}

/* sort idx[left],...idx[right] */

void sortLst(char *idx, int left, int right, int *val) {
  int i, last;

  if (left >= right) /* the number of elements in the subset < 2 */
    return;          /* finish */

  swap(idx, val, left, (left+right)/2);
  last = left;                /* pick up one element from the middle
				 and put it in idx[0] */

  for (i=left+1; i<=right; i++) {
    if (val[i] < val[left] ||     /* first sort by val[] */
	(val[i] == val[left] && idx[i] > idx[left]))  /* then by idx */
      swap(idx, val, ++last, i);

  }
  swap(idx, val, left, last);   /* restore the original element */

  sortLst(idx, left, last-1, val);
  sortLst(idx, last+1, right, val);
}

void swap(char *a, int *b, int i, int j) {
  int tmp;
  tmp = a[i];
  a[i] = a[j];
  a[j] = tmp;

  tmp = b[i];
  b[i] = b[j];
  b[j] = tmp;
}

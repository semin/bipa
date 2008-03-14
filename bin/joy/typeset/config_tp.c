#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "typeset.h"

extern FILE *tpin;

config *Conf;

int read_conf(char *filename) {
  FILE *conf;

  conf = fopen(filename, "r");
  tpin = conf;
  Conf = (config *)malloc((size_t) (MAXCONF * sizeof(config)));
  if (Conf == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(-1);
  }

  tpparse();
  fclose(conf);
}  

int set_config(int n, char *feature, char *value, int style, char *description) {

  Conf[n].feature = strdup(feature);
  Conf[n].value = value[0];
  Conf[n].style = style;
  Conf[n].description = strdup(description);

}
  
int show_config() {
  int i;
  for (i=0; i<nlines; i++) {
    printf("%s %c %d %s\n", Conf[i].feature, Conf[i].value, Conf[i].style, Conf[i].description);
  }
}

# Makefile for subst
#
# Kenji Mizuguchi
# 16 Apr 1999
#
CC=cc
#CFLAGS=-O -I. -I/user1/kenji/include
CFLAGS=-O -I. -I/user1/kenji/include -DDMALLOC_DISABLE
LDFLAGS=-L. -L/user1/kenji/lib
#LIBS= -lm -ldmalloc -ldmalloclp
LIBS= -lm
OBJECTS=main.o classdef.o subst.o count.o indel.o rdtem.o utility.o \
	rdlist.o analysis.o options.o getopt.o slink.o \
	combination.o smooth.o

subst: $(OBJECTS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o subst $(OBJECTS) $(LIBS)

clean:
	rm -f $(OBJECTS) subst

install:
	list='$(PROGRAMS)'; for file in $$list; do \
          cp $$file $(DESTDIR) ;\
        done

distrib:
	mkdir tmp$$$$;\
	list='$(PROGRAMS) $(DATAFILE) $(DOC)/*'; \
	for file in $$list; do\
	  newlist=$$newlist' '`basename $$file`;\
	  cp $$file tmp$$$$;\
	done;\
	cd tmp$$$$;\
	echo $$newlist;\
	tar cvf $(ARCHIVE) $$newlist;\
	mv $(ARCHIVE) ../;\
	cd ..;\
	rm -rf tmp$$$$

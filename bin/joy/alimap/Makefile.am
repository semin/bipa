noinst_LIBRARIES = libalimap.a
libalimap_a_SOURCES = gen.c read_pdb.c read_seq.c compseq.c chnbrk.c alimap.c runalimap.c\
	alimap.h    api_AM.h	chnbrk.h     compseq.h	gen.h  gen_func.h  memdebug.h\
	read_pdb.h  read_seq.h	runalimap.h

bin_PROGRAMS = alimap atm2ali

alimap_SOURCES =gen.c read_pdb.c read_seq.c compseq.c chnbrk.c alimap.c runalimap.c main.c \
	alimap.h    api_AM.h	chnbrk.h     compseq.h	gen.h  gen_func.h  memdebug.h \
	read_pdb.h  read_seq.h	runalimap.h

atm2ali_SOURCES = gen.c read_pdb.c read_seq.c compseq.c chnbrk.c alimap.c runalimap.c atm2ali.c \
	alimap.h    api_AM.h	chnbrk.h     compseq.h	gen.h  gen_func.h  memdebug.h \
	read_pdb.h  read_seq.h	runalimap.h

alimap_LDADD = -lm
atm2ali_LDADD = -lm

noinst_LIBRARIES = libpsa.a
libpsa_a_SOURCES = gen.c read_RadiiLib.c read_pdb.c assign_radius.c contact.c output.c resacc.c\
	 psa.c \
	assign_radius.h  contact.h  gen.h memdebug.h  mklib.h   output.h \
	psa.h psarun.h   read_RadiiLib.h  read_pdb.h  resacc.h

bin_PROGRAMS = psa

psa_SOURCES = gen.c read_RadiiLib.c read_pdb.c assign_radius.c contact.c output.c resacc.c \
	psa.c psarun.c \
	assign_radius.h  contact.h  gen.h memdebug.h  mklib.h   output.h \
	psa.h psarun.h   read_RadiiLib.h  read_pdb.h  resacc.h

psa_LDADD = -lm
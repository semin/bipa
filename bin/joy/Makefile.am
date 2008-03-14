SUBDIRS = psa alimap typeset wyg
bin_PROGRAMS = joy
joy_SOURCES = main.c findfile.c atm2data.c rdali.c rdsst.c rdpsa.c rdhbd.c \
	      tem_default.c tem_j4.c tem_j216.c tem_ext.c create_tem.c gen_html.c \
	gen_rtf.c gen_ps.c tag.c utility.c analysis.c rddom.c chkseq.c \
        afm.h   analysis.h  atm2data.h  chkseq.h   findfile.h  gen_html.h\
	gen_ps.h   gen_rtf.h   joy.h	   rdali.h    rddom.h	  rdhbd.h\
	rdpsa.h    rdsst.h     release.h   tag.h      tem.h	  tem_default.h\
	tem_ext.h  tem_j216.h  tem_j4.h    utility.h

INCLUDES = -I$(srcdir)/wyg -I$(srcdir)/typeset -I$(srcdir)/psa

EXTRA_DIST = perl/mkjoyf perl/joyfeature.default \
	perl/joyfeature.ext perl/joyfeature.j4 perl/joyfeature.j216 \
	wyg/wyg.conf

joy_LDADD = ./wyg/libwyg.a ./typeset/libtp.a \
	./psa/libpsa.a ./alimap/libalimap.a \
	-lm

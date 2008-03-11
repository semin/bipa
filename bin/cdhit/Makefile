CC = g++
CCFLAGS = -O2
#LDFLAGS = -static -o
LDFLAGS = -o

PROGS = mcd-hit cd-hit cd-hit-est cd-hit-2d cd-hit-div cd-hit-est-2d


.c++.o:
	$(CC) $(CCFLAGS) -c $<

all: $(PROGS)
clean:
	rm *.o $(PROGS)

# programs
cd-hit: cd-hit.o cd-hi-class.o
	$(CC) $(CCFLAGS) cd-hit.o cd-hi-class.o $(LDFLAGS) cd-hit

mcd-hit: mcd-hit.o cd-hi-class.o
	$(CC) $(CCFLAGS) mcd-hit.o cd-hi-class.o $(LDFLAGS) mcd-hit

cd-hit-est: cd-hit-est.o cd-hi-class.o
	$(CC) $(CCFLAGS) cd-hit-est.o cd-hi-class.o $(LDFLAGS) cd-hit-est

cd-hit-2d: cd-hit-2d.o cd-hi-class.o
	$(CC) $(CCFLAGS) cd-hit-2d.o cd-hi-class.o $(LDFLAGS) cd-hit-2d

cd-hit-est-2d: cd-hit-est-2d.o cd-hi-class.o
	$(CC) $(CCFLAGS) cd-hit-est-2d.o cd-hi-class.o $(LDFLAGS) cd-hit-est-2d

cd-hit-div: cd-hit-div.o cd-hi-class.o
	$(CC) $(CCFLAGS) cd-hit-div.o cd-hi-class.o $(LDFLAGS) cd-hit-div

# objects
cd-hit.o: cd-hit.c++ cd-hi.h cd-hi-init.h
	$(CC) $(CCFLAGS) cd-hit.c++ -c

mcd-hit.o: mcd-hit.c++ cd-hi.h cd-hi-init.h
	$(CC) $(CCFLAGS) mcd-hit.c++ -c

cd-hit-est.o: cd-hit-est.c++ cd-hi.h cd-hi-init.h
	$(CC) $(CCFLAGS) cd-hit-est.c++ -c

cd-hit-2d.o: cd-hit-2d.c++ cd-hi.h cd-hi-init.h
	$(CC) $(CCFLAGS) cd-hit-2d.c++ -c

cd-hit-est-2d.o: cd-hit-est-2d.c++ cd-hi.h cd-hi-init.h
	$(CC) $(CCFLAGS) cd-hit-est-2d.c++ -c

cd-hit-div.o: cd-hit-div.c++ cd-hi.h cd-hi-init.h
	$(CC) $(CCFLAGS) cd-hit-div.c++ -c

cd-hi-class.o: cd-hi-class.c++ cd-hi.h
	$(CC) $(CCFLAGS) cd-hi-class.c++ -c

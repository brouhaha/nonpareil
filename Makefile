YACC = bison
YFLAGS = -d -y

# YACC = yacc
# YFLAGS = -d

LEX = flex

CC = gcc
CFLAGS = -g -Dstricmp=strcasecmp -DUSE_TIMER -DENTER_KEY_MOD

PROGRAMS = casm csim
MISC_TARGETS = hp45 hp55

HEADERS = casm.h symtab.h xio.h
SOURCES = casm.c casm.l casm.y symtab.c csim.c xio.c
MISC = COPYING README
ROMS =  hp45.asm hp55.asm

CASM_OBJECTS = casm.o y.tab.o lex.yy.o symtab.o
CSIM_OBJECTS = csim.o xio.o

OBJECT = $(CASM_OBJECTS) $(CSIM_OBJECTS)

SIM_LIBS = -L/usr/X11/lib -lX11

INTERMEDIATE = lex.yy.c lex.yy.o y.tab.h y.tab.c y.tab.o

DISTRIB = $(MISC) Makefile $(HEADERS) $(SOURCES) $(ROMS)

.SUFFIXES:

all: $(PROGRAMS) $(MISC_TARGETS)

casm:	$(CASM_OBJECTS)
	$(CC) -o $@ $(CASM_OBJECTS)

casm.o: casm.c casm.h
	$(CC) -c $(CFLAGS) -o $@ $<

lex.yy.o: lex.yy.c casm.h symtab.h y.tab.h
	$(CC) -c $(CFLAGS) -o $@ $<

lex.yy.c: casm.l
	$(LEX) $(LFLAGS) $<

y.tab.o: y.tab.c casm.h symtab.h
	$(CC) -c $(CFLAGS) -o $@ $<

y.tab.c: casm.y
	$(YACC) $(YFLAGS) $<

symtab.o: symtab.c symtab.h
	$(CC) -c $(CFLAGS) -o $@ $<

hp45:	csim hp45.obj
	rm -f hp45
	ln -s csim hp45

hp55:	csim hp55.obj
	rm -f hp55
	ln -s csim hp55

hp45.obj:	casm hp45.asm
	./casm hp45.asm

hp55.obj:	casm hp55.asm
	./casm hp55.asm

csim:	$(CSIM_OBJECTS)
	$(CC) -o $@ $(CSIM_OBJECTS) $(SIM_LIBS) 

csim.o:	csim.c xio.h
	$(CC) -c $(CFLAGS) -o $@ $<

xio.o:	xio.c xio.h
	$(CC) -c $(CFLAGS) -o $@ $<

casmsim.tar.gz:	$(DISTRIB)
	tar -cvzf $@ $(DISTRIB)
	ls -l $@

clean:
	rm -f $(PROGRAMS) $(MISC_TARGETS) $(OBJECTS) $(INTERMEDIATE)

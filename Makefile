YACC = bison
YFLAGS = -d -y

# YACC = yacc
# YFLAGS = -d

LEX = flex

CC = gcc
CFLAGS = -g -Dstricmp=strcasecmp

HEADERS = casm.h symtab.h
SOURCES = casm.c casm.l casm.y symtab.c
MISC = COPYING README
ROMS =  hp45.asm hp55.asm

OBJECTS = casm.o y.tab.o lex.yy.o symtab.o
LIBS = -lc
# LIBS = -ly -ll

INTERMEDIATE = lex.yy.c lex.yy.o y.tab.h y.tab.c y.tab.o

DISTRIB = $(MISC) Makefile $(HEADERS) $(SOURCES) $(ROMS)

.SUFFIXES:

all: casm

casm:	$(OBJECTS)
	$(CC) -o $@ $(OBJECTS)
#	$(LD) -o $@ ${LIBS} $(OBJECTS)

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

casm.tar.gz:	$(DISTRIB)
	tar -cvzf $@ $(DISTRIB)
	ls -l $@

clean:
	rm -f casm $(OBJECTS) $(INTERMEDIATE)
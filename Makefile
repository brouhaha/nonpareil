# YACC = bison
# YFLAGS = -d -y

YACC = yacc
YFLAGS = -d

LEX = flex
# LEX = lex

CC = gcc
CFLAGS = -g -Dstricmp=strcasecmp

HEADERS = casm.h symtab.h
SOURCES = casm.c casm.l casm.y symtab.c
MISC = COPYING README
ROMS =  hp55_00.asm hp55_01.asm hp55_02.asm hp55_03.asm \
	hp55_04.asm hp55_05.asm hp55_06.asm hp55_07.asm \
	hp55_10.asm hp55_11.asm hp55_12.asm hp55_13.asm

OBJECTS = casm.o y.tab.o lex.yy.o symtab.o
LIBS = -lc
# LIBS = -ly -ll

DISTRIB = $(MISC) Makefile $(HEADERS) $(SOURCES) $(ROMS)

.SUFFIXES:

all: casm

casm:	$(OBJECTS)
	$(CC) -o $@ $(OBJECTS)
#	$(LD) -o $@ ${LIBS} $(OBJECTS)

casm.o: casm.c casm.h
	$(CC) -c $(CFLAGS) -o $@ $<

lex.yy.o: lex.yy.c casm.h y.tab.h
	$(CC) -c $(CFLAGS) -o $@ $<

lex.yy.c: casm.l
	$(LEX) $(LFLAGS) $<

y.tab.o: y.tab.c casm.h symtab.h
	$(CC) -c $(CFLAGS) -o $@ $<

y.tab.c: casm.y
	$(YACC) $(YFLAGS) $<

symtab.o: symtab.c symtab.h casm.h
	$(CC) -c $(CFLAGS) -o $@ $<

casm.tar.gz:	$(DISTRIB)
	tar -cvzf $@ $(DISTRIB)
	ls -l $@

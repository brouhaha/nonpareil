# YACC = bison
# YFLAGS = -d -y

YACC = yacc
YFLAGS = -d

LEX = flex
# LEX = lex

CC = gcc
CFLAGS = -g -Dstricmp=strcasecmp

OBJECTS = casm.o y.tab.o lex.yy.o symtab.o
LIBS = -lc
# LIBS = -ly -ll

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

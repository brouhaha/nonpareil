YFLAGS = -d

OBJECTS = casm.o y.tab.o lex.yy.o symtab.o
LIBS = -lc
# LIBS = -ly -ll

all: casm

casm:	$(OBJECTS)
	$(CC) -o $@ $(OBJECTS)
#	$(LD) -o $@ ${LIBS} $(OBJECTS)

casm.o: casm.c
	$(CC) -c $(CFLAGS) -o $@ $<

lex.yy.o: lex.yy.c
	$(CC) -c $(CFLAGS) -o $@ $<

lex.yy.c: casm.l y.tab.c
	$(LEX) $(LFLAGS) $<

y.tab.o: y.tab.c casm.h
	$(CC) -c $(CFLAGS) -o $@ $<

y.tab.c: casm.y symtab.h
	$(YACC) $(YFLAGS) $<

symtab.o: symtab.c symtab.h casm.h
	$(CC) -c $(CFLAGS) -o $@ $<

# Makefile for CASMSIM package
# Copyright 1995 Eric L. Smith
# $Header: /home/svn/casmsim/Makefile,v 1.17 1995/03/30 00:22:59 eric Exp $
#
# CASMSIM is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.  Note that I am not granting permission to redistribute
# or modify CASMSIM under the terms of any later version of the General Public
# License.
# 
# These programs are distributed in the hope that they will be useful (or at
# least amusing), but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# these programs (in the file "COPYING"); if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# $Header: /home/svn/casmsim/Makefile,v 1.17 1995/03/30 00:22:59 eric Exp $


# -----------------------------------------------------------------------------
# You may need to change the following definitions.  In particular you will
# need to remove the -DUSE_TIMER if you don't have the setitimer() system
# call, and you may need to chage X11LIBS and X11INCS if X isn't in /usr/X11.
#
# If you are using a version of Flex later than 2.4.1 you can optionally
# remove the "-DOLD_FLEX" from CFLAGS, resulting in a completely imperceptible
# performance improvement in CASM.
# -----------------------------------------------------------------------------

CC = gcc
CFLAGS = -g -Dstricmp=strcasecmp -DUSE_TIMER -DENTER_KEY_MOD -DOLD_FLEX

YACC = bison
YFLAGS = -d -y

# YACC = yacc
# YFLAGS = -d

LEX = flex

X11LIBS = -L/usr/X11/lib -lX11
X11INCS = -I/usr/X11/include


# -----------------------------------------------------------------------------
# You shouldn't have to change anything below this point, but if you do please
# let me know why so I can improve this Makefile.
# -----------------------------------------------------------------------------

PROGRAMS = casm csim
MISC_TARGETS = hp45 hp55

HEADERS = casm.h symtab.h xio.h
SOURCES = casm.c casml.l casmy.y symtab.c csim.c xio.c
MISC = COPYING README CHANGELOG
ROMS =  hp45.asm hp55.asm
LISTINGS = hp45.lst hp55.lst

CASM_OBJECTS = casm.o symtab.o lex.yy.o y.tab.o
CSIM_OBJECTS = csim.o xio.o

OBJECTS = $(CASM_OBJECTS) $(CSIM_OBJECTS)

SIM_LIBS = $(X11LIBS)

INTERMEDIATE = lex.yy.c y.tab.c y.tab.h

DISTRIB = $(MISC) Makefile $(HEADERS) $(SOURCES) $(ROMS)

all: $(PROGRAMS) $(MISC_TARGETS)

casm:	$(CASM_OBJECTS)
	$(CC) -o $@ $(CASM_OBJECTS)

casm.o: casm.c casm.h
	$(CC) -c $(CFLAGS) -o $@ $<

lex.yy.o: lex.yy.c casm.h symtab.h y.tab.h
	$(CC) -c $(CFLAGS) -o $@ $<

lex.yy.c: casml.l
	$(LEX) $(LFLAGS) $<

y.tab.o: y.tab.c casm.h symtab.h
	$(CC) -c $(CFLAGS) -o $@ $<

y.tab.c y.tab.h: casmy.y
	$(YACC) $(YFLAGS) $<

symtab.o: symtab.c symtab.h
	$(CC) -c $(CFLAGS) -o $@ $<

hp45:	csim hp45.lst
	rm -f hp45
	ln -s csim hp45

hp55:	csim hp55.lst
	rm -f hp55
	ln -s csim hp55

hp45.obj hp45.lst:	casm hp45.asm
	./casm hp45.asm

hp55.obj hp55.lst:	casm hp55.asm
	./casm hp55.asm

csim:	$(CSIM_OBJECTS)
	$(CC) -o $@ $(CSIM_OBJECTS) $(SIM_LIBS) 

csim.o:	csim.c xio.h
	$(CC) -c $(CFLAGS) -o $@ $<

xio.o:	xio.c xio.h
	$(CC) -c $(CFLAGS) $(X11INCS) -o $@ $<

casmsim.tar.gz:	$(DISTRIB)
	tar -cvzf $@ $(DISTRIB)
	ls -l $@

listings.tar.gz: $(LISTINGS)
	tar -cvzf $@ $(LISTINGS)
	ls -l $@

clean:
	rm -f $(PROGRAMS) $(MISC_TARGETS) $(OBJECTS) $(INTERMEDIATE) $(LISTINGS)

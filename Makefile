# Makefile for CASMSIM package
# Copyright 1995, 2003 Eric L. Smith
# $Header: /home/svn/casmsim/Makefile,v 1.19 2003/05/30 07:36:38 eric Exp $
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


# -----------------------------------------------------------------------------
# You may need to change the following definitions.  In particular you will
# need to remove the -DUSE_TIMER if you don't have the setitimer() system
# call, and you may need to chage X11LIBS and X11INCS if X isn't in
# /usr/X11R6.
#
# If you are using Flex version 2.4.1 or earlier, you will need to add
# -DOLD_FLEX to CFLAGS.
# -----------------------------------------------------------------------------

CC = gcc
CFLAGS = -g -Dstricmp=strcasecmp -DUSE_TIMER -DENTER_KEY_MOD

YACC = bison
YFLAGS = -d -v

LEX = flex

X11LIBS = -L/usr/X11R6/lib -lX11
X11INCS = -I/usr/X11R6/include


# -----------------------------------------------------------------------------
# You shouldn't have to change anything below this point, but if you do please
# let me know why so I can improve this Makefile.
# -----------------------------------------------------------------------------

PACKAGE = casmsim
VERSION = 0.12
DISTNAME = $(PACKAGE)-$(VERSION)

TARGETS = casm csim
MISC_TARGETS = hp45 hp55

HDRS = casm.h symtab.h xio.h
CSRCS = casm.c symtab.c csim.c xio.c
OSRCS = casml.l casmy.y 
MISC = COPYING README ChangeLog

AUTO_CSRCS = casml.c casmy.tab.c
AUTO_HDRS = casmy.tab.h
AUTO_MISC = casmy.output

CASM_OBJECTS = casm.o symtab.o casml.o casmy.tab.o
CSIM_OBJECTS = csim.o xio.o

OBJECTS = $(CASM_OBJECTS) $(CSIM_OBJECTS)

SIM_LIBS = $(X11LIBS)

ROM_SRCS =  hp45.asm hp55.asm
ROM_LISTINGS = $(ROM_SRCS:.asm=.lst)
ROM_OBJS = $(ROM_SRCS:.asm=.obj)

DIST_FILES = $(MISC) Makefile $(HDRS) $(CSRCS) $(OSRCS) $(ROM_SRCS)


%.tab.c %.tab.h %.output: %.y
	$(YACC) $(YFLAGS) $<


all: $(TARGETS) $(MISC_TARGETS)

casm:	$(CASM_OBJECTS)
	$(CC) -o $@ $(CASM_OBJECTS)

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

dist:	$(DIST_FILES)
	-rm -rf $(DISTNAME) $(DISTNAME).tar.gz
	mkdir $(DISTNAME)
	for f in $(DIST_FILES); do ln $$f $(DISTNAME)/$$f; done
	tar --gzip -chf $(DISTNAME).tar.gz $(DISTNAME)
	-rm -rf $(DISTNAME)

listings.tar.gz: $(LISTINGS)
	tar -cvzf $@ $(LISTINGS)
	ls -l $@

clean:
	rm -f $(TARGETS) $(MISC_TARGETS) $(OBJECTS) \
	$(AUTO_CSRCS) $(AUTO_HDRS) $(AUTO_MISC) \
	$(ROM_LISTINGS) $(ROM_OBJS)\

ALL_CSRCS = $(CSRCS) $(AUTO_CSRCS)

DEPENDS = $(ALL_CSRCS:.c=.d)

%.d: %.c
	$(CC) -M -MG $(CFLAGS) $< | sed -e 's@ /[^ ]*@@g' -e 's@^\(.*\)\.o:@\1.d \1.o:@' > $@

include $(DEPENDS)

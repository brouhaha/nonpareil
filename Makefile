# Makefile for CASMSIM package
# Copyright 1995, 2003 Eric L. Smith
# $Id$
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


#HAS_DEBUGGER=1
ifdef HAS_DEBUGGER
HAS_DEBUGGER_CLI=1
ifdef HAS_DEBUGGER_CLI
USE_TCL=1
USE_READLINE=1
endif
endif


YACC = bison
YFLAGS = -d -v

LEX = flex

LDFLAGS = -g


# -----------------------------------------------------------------------------
# You shouldn't have to change anything below this point, but if you do please
# let me know why so I can improve this Makefile.
# -----------------------------------------------------------------------------

PACKAGE = casmsim
RELEASE = 0.24
DISTNAME = $(PACKAGE)-$(RELEASE)

PACKAGES = gtk+-2.0 gdk-2.0 gdk-pixbuf-2.0 glib-2.0 gthread-2.0
ifdef HAS_DEBUGGER_CLI
PACKAGES += vte
endif

CFLAGS = -g -Wall `pkg-config $(PACKAGES) --cflags`
LOADLIBES = `pkg-config $(PACKAGES) --libs` -lutil

ifdef HAS_DEBUGGER
  CFLAGS += -DHAS_DEBUGGER
endif

ifdef HAS_DEBUGGER_CLI
  CFLAGS += -DHAS_DEBUGGER_CLI
endif

ifdef USE_TCL
  CFLAGS += -DUSE_TCL
  LOADLIBES += -ltcl
endif

ifdef USE_READLINE
  CFLAGS += -DUSE_READLINE
  LOADLIBES += -lreadline -lhistory -ltermcap
endif

CALCS = hp25 hp35 hp45 hp55 hp80

TARGETS = csim asm

HDRS = asm.h symtab.h util.h proc.h kml.h debugger.h \
	arch.h platform.h model.h
CSRCS = asm.c symtab.c csim.c util.c proc.c kml.c debugger.c \
	arch.c platform.c model.c
LSRCS = asml.l casml.l wasml.l kmll.l
YSRCS = asmy.y casmy.y wasmy.y kmly.y
MISC = COPYING README ChangeLog

KML = $(CALCS:=.kml)
IMAGES = $(CALCS:=.png)

AUTO_CSRCS = $(LSRCS:.l=.c) $(YSRCS:.y=.tab.c)
AUTO_HDRS = $(YSRCS:.y=.tab.h)
AUTO_MISC = $(YSRCS:.y=.output)

ASM_OBJECTS = asm.o symtab.o asml.o asmy.tab.o casml.o casmy.tab.o wasml.o wasmy.tab.o util.o arch.o

CSIM_OBJECTS = csim.o util.o proc.o kmll.o kmly.tab.o kml.o \
	platform.o model.o
ifdef HAS_DEBUGGER_CLI
  CSIM_OBJECTS += debugger.o
endif

OBJECTS = $(ASM_OBJECTS) $(CSIM_OBJECTS)

SIM_LIBS = $(LOADLIBES)

ROM_SRCS =  $(CALCS:=.asm)
ROM_LISTINGS = $(ROM_SRCS:.asm=.lst)
ROM_OBJS = $(ROM_SRCS:.asm=.obj)

DIST_FILES = $(MISC) Makefile $(HDRS) $(CSRCS) $(LSRCS) $(YSRCS) $(ROM_SRCS) \
	$(KML) $(IMAGES)

CFLAGS += -DCASMSIM_RELEASE=$(RELEASE)

%.tab.c %.tab.h %.output: %.y
	$(YACC) $(YFLAGS) $<

%.obj %.lst: %.asm csim
	./asm $<

hp%: hp%.lst csim
	rm -f $@
	ln -s csim $@


all: $(TARGETS) $(CALCS) $(ROM_LISTINGS)


csim:	$(CSIM_OBJECTS)
	$(CC) -o $@ $(CSIM_OBJECTS) $(SIM_LIBS) 

asm:	$(ASM_OBJECTS)
	$(CC) -o $@ $(ASM_OBJECTS)

dist:	$(DIST_FILES)
	-rm -rf $(DISTNAME) $(DISTNAME).tar.gz
	mkdir $(DISTNAME)
	for f in $(DIST_FILES); do ln $$f $(DISTNAME)/$$f; done
	tar --gzip -chf $(DISTNAME).tar.gz $(DISTNAME)
	-rm -rf $(DISTNAME)

listings.tar.gz: $(LISTINGS)
	tar -cvzf $@ $(LISTINGS)
	ls -l $@


hp35.jpg:
	wget http://www.hpmuseum.org/35first.jpg -O hp35.jpg

hp45.jpg:
	wget http://www.hpmuseum.org/45.jpg -O hp45.jpg

hp55.jpg:
	wget http://www.hpmuseum.org/55.jpg -O hp55.jpg

hp80.jpg:
	wget http://www.hpmuseum.org/80.jpg -O hp80.jpg

clean:
	rm -f $(TARGETS) $(MISC_TARGETS) $(OBJECTS) \
	$(AUTO_CSRCS) $(AUTO_HDRS) $(AUTO_MISC) \
	$(ROM_LISTINGS) $(ROM_OBJS)\

ALL_CSRCS = $(CSRCS) $(AUTO_CSRCS)

DEPENDS = $(ALL_CSRCS:.c=.d)

%.d: %.c
	$(CC) -M -MG $(CFLAGS) $(CDEFINES) $< | sed -e 's@ /[^ ]*@@g' -e 's@^\(.*\)\.o:@\1.d \1.o:@' > $@

include $(DEPENDS)

.SUFFIXES: .bin .prg 
.PRECIOUS:	%.ngd %.ncd %.twx

COPT=	-Wall -g -std=c99
CC=	gcc

CA65=  ca65 --cpu 4510
LD65=  ld65 -t none

ASSETS=		assets
SRCDIR=		src
BINDIR=		bin

MEGABASICOBJS=	$(SRCDIR)/mega-basic64.o

TOOLDIR=	$(SRCDIR)/tools
TOOLS=	$(TOOLDIR)/pngtoscreens

all:	$(TOOLS) $(BINDIR)/megabasic64.prg

# c-programs
tools:	$(TOOLS)

%.o:	%.s
	$(CA65) $< -l $*.list

$(BINDIR)/megabasic64.prg:       $(MEGABASICOBJS)
	$(LD65) $< --mapfile $*.map -o $(BINDIR)/megabasic64.prg

$(TOOLDIR)/pngtoscreens:	$(TOOLDIR)/pngtoscreens.c Makefile
	$(CC) $(COPT) -I/usr/local/include -L/usr/local/lib -o $(TOOLDIR)/pngtoscreens $(TOOLDIR)/pngtoscreens.c -lpng

clean:
	rm -f $(TOOLDIR)/pngtoscreens $(BINDIR)/megabasic64.prg src/*.o

cleangen:


.SUFFIXES: .bin .prg 
.PRECIOUS:	%.ngd %.ncd %.twx

COPT=	-Wall -g -std=c99
CC=	gcc

CA65=  ca65 --cpu 4510
LD65=  ld65 -t none

ASSETS=		assets
SRCDIR=		src
BINDIR=		bin

BINARIES=	$(BINDIR)/megabasic64.prg \
		$(BINDIR)/megabanner.tiles

MEGABASICOBJS=	$(SRCDIR)/mega-basic64.o

TOOLDIR=	$(SRCDIR)/tools
TOOLS=	$(TOOLDIR)/pngtoscreens

all:	$(TOOLS) $(BINDIR)/MEGABAS.D81

# c-programs
tools:	$(TOOLS)

%.o:	%.s
	$(CA65) $< -l $*.list

$(BINDIR)/megabasic64.prg:       $(MEGABASICOBJS)
	mkdir -p $(BINDIR)
	$(LD65) $< --mapfile $*.map -o $(BINDIR)/megabasic64.prg

$(TOOLDIR)/pngtoscreens:	$(TOOLDIR)/pngtoscreens.c Makefile
	$(CC) $(COPT) -I/usr/local/include -L/usr/local/lib -o $(TOOLDIR)/pngtoscreens $(TOOLDIR)/pngtoscreens.c -lpng

$(BINDIR)/megabanner.tiles:	$(TOOLDIR)/pngtoscreens $(ASSETS)/mega65_320x64.png
	$(TOOLDIR)/pngtoscreens $(BINDIR)/megabanner.tiles $(ASSETS)/mega65_320x64.png

$(BINDIR)/MEGABAS.D81:	$(BINARIES)
	rm -f $(BINDIR)/MEGABAS.D81
	cbmconvert -D8 $(BINDIR)/MEGABAS.D81 $(BINARIES)

clean:
	rm -f $(TOOLDIR)/pngtoscreens $(BINDIR)/* src/*.o

cleangen:


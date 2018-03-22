.SUFFIXES: .bin .prg 
.PRECIOUS:	%.ngd %.ncd %.twx

COPT=	-Wall -g -std=c99
CC=	gcc
OPHIS=	../Ophis/bin/ophis -4

CA65=  ca65 --cpu 4510
LD65=  ld65 -t none

ASSETS=		assets
SRCDIR=		src
BINDIR=		bin

VEHICLE_ASSETS=	\
		$(ASSETS)/vehicle_console_cluster.svg.png \
		$(ASSETS)/0.png \
		$(ASSETS)/1.png \
		$(ASSETS)/2.png \
		$(ASSETS)/3.png \
		$(ASSETS)/4.png \
		$(ASSETS)/5.png \
		$(ASSETS)/6.png \
		$(ASSETS)/7.png \
		$(ASSETS)/8.png \
		$(ASSETS)/9.png \

BINARIES=	$(BINDIR)/megabasic64.prg \
		$(BINDIR)/megabanner.tiles \
		$(BINDIR)/vehicle_console.tiles

MEGABASICOBJS=	$(SRCDIR)/mega-basic64.o

TOOLDIR=	$(SRCDIR)/tools
TOOLS=	$(TOOLDIR)/pngtoscreens

all:	$(TOOLS) $(BINDIR)/MEGABAS.D81

# c-programs
tools:	$(TOOLS)

%.o:	%.s	$(BINDIR)/megabanner.tiles	$(BINDIR)/vehicle_console.tiles
	$(CA65) $< -l $*.list

$(BINDIR)/megabanner.tiles:	$(TOOLDIR)/mktileset $(ASSETS)/mega65_320x64.png
	$(TOOLDIR)/mktileset $(BINDIR)/megabanner.tiles c64palette $(ASSETS)/mega65_320x64.png

$(BINDIR)/vehicle_console.tiles:	$(TOOLDIR)/mktileset $(VEHICLE_ASSETS)
	$(TOOLDIR)/mktileset $(BINDIR)/vehicle_console.tiles c64palette $(VEHICLE_ASSETS) /usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf:0:16:41-57,20

$(BINDIR)/megabasic64.prg:       $(MEGABASICOBJS) $(BINDIR)/megabanner.tiles
	mkdir -p $(BINDIR)
	$(LD65) $< --mapfile $*.map -o $(BINDIR)/megabasic64.prg

$(BINDIR)/vehicle-console.prg:	src/vehicle-console.a65 $(BINDIR)/vehicle_console.tiles
	$(OPHIS) src/vehicle-console.a65

MKTILESET_SRCS=	$(TOOLDIR)/mktileset.c \
		$(TOOLDIR)/mktileset_png.c \
		$(TOOLDIR)/mktileset_ttf.c

MKTILESET_HDRS=	$(TOOLDIR)/mktileset.h

$(TOOLDIR)/mktileset:	$(MKTILESET_SRCS) $(MKTILESET_HDRS) Makefile
	$(CC) $(COPT) `pkg-config --cflags freetype2` -I/usr/local/include -L/usr/local/lib -o $(TOOLDIR)/mktileset $(MKTILESET_SRCS) -lpng `pkg-config --libs freetype2`

$(BINDIR)/MEGABAS.D81:	$(BINARIES)
	rm -f $(BINDIR)/MEGABAS.D81
	cbmconvert -D8 $(BINDIR)/MEGABAS.D81 $(BINARIES)

clean:
	rm -f $(TOOLDIR)/mktileset $(BINDIR)/* src/*.o src/tools/*.o

cleangen:


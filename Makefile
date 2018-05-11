.SUFFIXES: .bin .prg 
.PRECIOUS:	%.ngd %.ncd %.twx

COPT=	-Wall -g -std=c99
CC=	gcc
OPHIS=	../Ophis/bin/ophis -4

CA65=  ca65 --cpu 4510
LD65=  ld65 --config ./c64asm.cfg

ASSETS=		assets
SRCDIR=		src
BINDIR=		bin

DIALER_ASSETS= \
		$(ASSETS)/dial0.png \
		$(ASSETS)/dial1.png \
		$(ASSETS)/dial2.png \
		$(ASSETS)/dial3.png \
		$(ASSETS)/dial4.png \
		$(ASSETS)/dial5.png \
		$(ASSETS)/dial6.png \
		$(ASSETS)/dial7.png \
		$(ASSETS)/dial8.png \
		$(ASSETS)/dial9.png \
		$(ASSETS)/dialhash.png \
		$(ASSETS)/dialstar.png \
		$(ASSETS)/dialdivide.png \
		$(ASSETS)/dialminus.png \
		$(ASSETS)/dialplus.png \
		$(ASSETS)/dialequal.png \
		$(ASSETS)/erase.png \
		$(ASSETS)/phone_green.png \
		$(ASSETS)/phone_red.png \
		$(ASSETS)/satellite.png \
		$(ASSETS)/dial0_pressed.png \
		$(ASSETS)/dial1_pressed.png \
		$(ASSETS)/dial2_pressed.png \
		$(ASSETS)/dial3_pressed.png \
		$(ASSETS)/dial4_pressed.png \
		$(ASSETS)/dial5_pressed.png \
		$(ASSETS)/dial6_pressed.png \
		$(ASSETS)/dial7_pressed.png \
		$(ASSETS)/dial8_pressed.png \
		$(ASSETS)/dial9_pressed.png \
		$(ASSETS)/dialhash_pressed.png \
		$(ASSETS)/dialstar_pressed.png \
		$(ASSETS)/dialdivide_pressed.png \
		$(ASSETS)/dialminus_pressed.png \
		$(ASSETS)/dialplus_pressed.png \
		$(ASSETS)/dialequal_pressed.png \
		$(ASSETS)/erase_pressed.png \
		$(ASSETS)/phone_blue.png \
		$(ASSETS)/phone_blue.png \
		$(ASSETS)/satellite_pressed.png \
		$(ASSETS)/signal0_24x16-s.png \
		$(ASSETS)/signal1_24x16-s.png \
		$(ASSETS)/signal2_24x16-s.png \
		$(ASSETS)/signal3_24x16-s.png \
		$(ASSETS)/signal4_24x16-s.png \
		$(ASSETS)/signal5_24x16-s.png \
		$(ASSETS)/dualsim.png \
		$(ASSETS)/dualsim_pressed.png \
		$(ASSETS)/battery0.png \
		$(ASSETS)/battery10.png \
		$(ASSETS)/battery20.png \
		$(ASSETS)/battery30.png \
		$(ASSETS)/battery40.png \
		$(ASSETS)/battery50.png \
		$(ASSETS)/battery60.png \
		$(ASSETS)/battery70.png \
		$(ASSETS)/battery80.png \
		$(ASSETS)/battery90.png \
		$(ASSETS)/battery100.png \
		$(ASSETS)/arrow_back.png \
		$(ASSETS)/cog.png \
		$(ASSETS)/trash_bin.png \
		$(ASSETS)/globe.png \
		$(ASSETS)/message_1.png \
		$(ASSETS)/send_1.png \
		$(ASSETS)/search-s.png \
		$(ASSETS)/contact_new.png \
		$(ASSETS)/contact_new_pressed.png \

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

# Order is important, as some have line numbers.
# Specifically, main must be first, and autopsy last
DIALERSRCS=	\
		telephony_main.bas \
		telephony_phonebook.bas \
		telephony_setup.bas \
		telephony_helpers.bas \
		telephony_message_senders.bas \
		telephony_screen_drawers.bas \
		telephony_parser.bas \
		telephony_screen_handlers.bas \
		telephony_message_handlers.bas \
		telephony_autopsy.bas


BINARIES=	$(BINDIR)/megabasic64.prg \
		$(BINDIR)/dialer.prg \
		$(BINDIR)/megabanner.tiles \
		$(BINDIR)/vehicle_console.tiles \
		$(BINDIR)/fonttest.tiles \
		$(BINDIR)/dialer.tiles

MEGABASICOBJS=	$(SRCDIR)/mega-basic64.o

TOOLDIR=	$(SRCDIR)/tools
TOOLS=	$(TOOLDIR)/pngtoscreens

all:	$(TOOLS) $(BINDIR)/MEGABAS.D81

# c-programs
tools:	$(TOOLS)

%.o:	%.s	$(BINDIR)/megabanner.tiles	$(BINDIR)/dialer.tiles
	$(CA65) $< -l $*.list

$(BINDIR)/megabanner.tiles:	$(TOOLDIR)/mktileset $(ASSETS)/mega65_320x64.png
	$(TOOLDIR)/mktileset $(BINDIR)/megabanner.tiles c64palette $(ASSETS)/mega65_320x64.png

$(BINDIR)/vehicle_console.tiles:	$(TOOLDIR)/mktileset $(VEHICLE_ASSETS)
	$(TOOLDIR)/mktileset $(BINDIR)/vehicle_console.tiles c64palette $(VEHICLE_ASSETS)

$(BINDIR)/fonttest.tiles:	$(TOOLDIR)/mktileset
	$(TOOLDIR)/mktileset $(BINDIR)/fonttest.tiles c64palette /usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf:0:16:41-5A,61-7A,20

$(BINDIR)/dialer.tiles:	$(TOOLDIR)/mktileset	$(DIALER_ASSETS)
	$(TOOLDIR)/mktileset $(BINDIR)/dialer.tiles c64palette $(DIALER_ASSETS)

$(BINDIR)/megabasic64.prg:       $(MEGABASICOBJS) $(BINDIR)/megabanner.tiles
	mkdir -p $(BINDIR)
	$(LD65) $< --mapfile $*.map -o $(BINDIR)/megabasic64.prg

$(BINDIR)/dialer.bas:	$(DIALERSRCS) $(TOOLDIR)/bpp
	$(TOOLDIR)/bpp $(DIALERSRCS) > $(BINDIR)/dialer.bas

$(BINDIR)/dialer.prg:	$(BINDIR)/dialer.bas
	$(TOOLDIR)/hatoucan.py > $(BINDIR)/dialer.prg < $(BINDIR)/dialer.bas

$(BINDIR)/vehicle-console.prg:	src/vehicle-console.a65 $(BINDIR)/vehicle_console.tiles
	$(OPHIS) src/vehicle-console.a65

$(TOOLDIR)/bpp:	$(TOOLDIR)/bpp.c Makefile
	$(CC) $(COPT) -o $(TOOLDIR)/bpp $(TOOLDIR)/bpp.c

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
	rm -f $(TOOLDIR)/mktileset $(BINDIR)/* $(SRCDIR)/*.o $(TOOLDIR)/*.o

cleangen:


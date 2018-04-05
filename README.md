MEGA65 Extended BASIC
-------------------

This extended BASIC is intended as a starting point, not a finished product.
For convenience, I have created it by extending the relatively simple starting point
that is the C64's BASIC 2.  It would of course be better to extend BASIC 7 or BASIC 10,
but for now this is what we have.

The purpose of this extended BASIC more specifically is to provide a convenient testbed
for the 256-colour text mode graphics and 16-colour sprite capabilities of the MEGA65.
But more than just being a tool for the development team, it is intended to be easy and
fun for end users to create their own programs with.

Considerable effort is being put into making the syntax as human readable as possible,
compared with the very terse syntax of BASIC 7 and BASIC 10.


Requirements
------------

To compile this repository, you'll need the `freetype2` library and the `cbmconvert` tool.
* freetype2
    ```bash
    sudo apt install libfreetype6-dev
    ```
* cbmconvert
    ```bash
    git clone https://github.com/sasq64/cbmconvert.git
    make -f Makefile.unix
    sudo ln -s ~/dev/cbmconvert/cbmconvert /usr/bin/cbmconvert  # add the executable to path
    ```

To execute the helper scripts, you'll need the `csh` script interpreter:
    ```bash
    sudo apt install csh
    ```


Command reference
-----------------

* FAST - Set CPU to full speed
* SLOW - Disable MEGA65 fast CPU (C128 style and C65 style 2MHz and 3.5MHz selection is unaffected)
* COLOUR TEXT <0-255> - Select text foreground colour (16 colours only). Upper 4 bits are VIC-III extended attributes (this command might get extended to allow easier setting of attributes. 16 = BLINK, 128 = UNDERLINE, 32 = REVERSE, 64 = BOLD (selects colours 32-47 instead of colours 0 - 15).
* COLOUR BORDER <0-255> - Set border colour
* COLOUR SCREEN <0-255> - Set screen background colour
* COLOUR SPRITE <sprite number> COLOUR <colour index in sprite>> = <0-255>,<0-255>,<0-255> - Set the R,G,B values of a sprite colour
* TILE SET LOAD <"filename"> [, device] - Load a set of tiles and pre-prepared canvases from the specified device. These load into the graphics memory, leaving the full 38911 program bytes free. Loading a tile set replaces any existing tile set and canvases.  Any currently displayed graphics will be disabled before loading, to prevent screen glitches. Loading a tile set also loads the associated palette.
* CANVAS <0-255> <NEW <width>,<height>> - Create a new canvas with the specified ID. Canvases are rectangular arrangements of tiles. A FILE EXISTS ERROR will be generated if the canvas already exists.
* CANVAS <0-255> DELETE - Delete the specified canvas. Canvas 0 is special, and cannot be deleted.
* CANVAS <0-255> CLR [FROM <x1>,<y1> TO <x2>,<y2>] - Erase the contents of the specifed canvas, filling it with tile number 0.
* CANVAS <0-255> STAMP [FROM <x1>,<y1> TO <x2,y2>] ON CANVAS <0-255> [AT <x>,<y>]> - Copy the whole or part of one canvas onto the whole or part of another canvas.  This is a very versatile command, and can be used to display a canvas (by STAMPing it onto canvas 0, the display canvas), or to compose scenes using various elements. Because tile number 0 is transparent, such compositions can use complex shaped objects, the only limitation being that the objects consist of 8x8 tiles, i.e., you can't select pixels to be part of a composition with finer than 8x8 granularity (this may be relaxed in a future version through the use of a transparent colour and complex tile compositing algorithms, but such composing of tiles together will require the creation of additional tiles with the combined data, thus increasing memory usage.)
* CANVAS <0-255> SET TILE <x>,<y> = <tile number> - Set the specified tile on the specified canvas to display the specified tile number. Tile number 0 is reserved as the "transparent tile", i.e., tile zero will not STAMP over an existing tile in another canvas, and will show the screen colour behind.


Memory Layout
-------------

For now, the memory layout is a bit sub-optimal, because the C65 DOS sits in BANK 1, meaning we have only 56KB free there
(in fact 54KB, because the last 2KB are colour RAM).

We also need to have screen RAM for the current screen.  We use this to take over the BASIC screen, so that tiles and text
can happily coexist.  A raster IRQ reads the C64 screen (at 50MHz) and composes this onto the contents of CANVAS 0, to
produce the actual display screen.  Any character on the BASIC screen at $0400 that is not a space will overwrite the
tile otherwise being displayed at that screen position.

We allow enough space in CANVAS 0 for an 80x50 screen, thus requiring 80 x 50 x 2 bytes = 8000 bytes. We hide that under
the C64 KERNAL.  Because of the compositing of the BASIC screen on this, we need another 8000 bytes, which we hide under
the C64 BASIC ROM.  This buffering of screen 0 is required so that you can freely type and clear the BASIC screen, and
the tile-based graphics screen from behind will update magically.  This makes programs MUCH easier to write and debug.
You can even POKE to $0400, and thanks to the raster interrupt, the changes will magically appear on the next frame.

There will eventually be an option to tell BASIC that the screen is bigger, so that 80 column and 50 rows of text in
BASIC become possible. The cost will simply be the loss of 3000 bytes of BASIC program space.

8000 bytes of colour RAM are also required to be reserved for CANVAS 0's off-screen buffer, and also the on-screen buffer.
These are at $0800 and $2800 in the colour RAM, leaving from $4800-$7FFF in colour RAM free. It would be nice to make that
14KB available for storing other CANVASes, to effectively increase the available graphics memory.

The video mode will be set to use a virtual row length of 80, regardless of 40 or 80 column mode, so that it is possible to
switch between the two freely.  For the memory frugal, it is of course possible to STAMP into and out of the off-display
portions of CANVAS 0, thus reducing the effective overhead.  Thus the 8000 bytes of CANVAS 0 are in effect in addition to
the headline 54KB of graphics memory. Similarly, the use of the 32KB colour RAM is not counted.

In summary, the VIC-IV will be set to show:

* 40x25 - 80x50 screen, with screen RAM at $A000-$BFFF, colour RAM at $FF80800-$FF827FF.
* virtual row length = 80 characters.
* 16-bit colour mode enabled.
* multi-colour mode off.

And the raster interrupt will read from $E000-$FFFF, $FF82800-$FF847FF and $0400-$07E7 to dynamically generate
the screen and colour RAM data at $A000 and $FF80800.  This will be done by first copying the CANVAS 0 contents,
and then stepping through the C64 screen, and for characters that are not space, copy the screen and colour RAM
contents to the correct address in the VIC-IV screen and colour RAM at $A000 and $FF80800.

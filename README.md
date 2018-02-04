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

Command reference
-------------

* FAST - Set CPU to full speed
* SLOW - Disable MEGA65 fast CPU (C128 style and C65 style 2MHz and 3.5MHz selection is unaffected)
* COLOUR TEXT <0-255> - Select text foreground colour
* COLOUR BORDER <0-255> - Set border colour
* COLOUR SCREEN <0-255> - Set screen background colour
* COLOUR SPRITE <sprite number> COLOUR <colour index in sprite>> = <0-255>,<0-255>,<0-255> - Set the R,G,B values of a sprite colour
* TILE SET LOAD <"filename"> [, device] - Load a set of tiles and pre-prepared canvases from the specified device. These load into the graphics memory, leaving the full 38911 program bytes free. Loading a tile set replaces any existing tile set and canvases.  Any currently displayed graphics will be disabled before loading, to prevent screen glitches. Loading a tile set also loads the associated palette.
* CANVAS <0-255> <NEW <width>,<height>> - Create a new canvas with the specified ID. Canvases are rectangular arrangements of tiles. If canvas 0 exists, it will be displayed behind any text on the BASIC screen.
* CANVAS <0-255> DELETE - Delete the specified canvas.
* CANVAS <0-255> CLR - Erase the contents of the specifed canvas, filling it with tile number 0.
* CANVAS <0-255> STAMP [REGION <x1>,<y1> TO <x2,y2>] ON TO CANVAS <0-255> [AT <x>,<y>]> - Copy the whole or part of one canvas onto the whole or part of another canvas.  This is a very versatile command, and can be used to display a canvas (by STAMPing it onto canvas 0, the display canvas), or to compose scenes using various elements. Because tile number 0 is transparent, such compositions can use complex shaped objects, the only limitation being that the objects consist of 8x8 tiles, i.e., you can't select pixels to be part of a composition with finer than 8x8 granularity (this may be relaxed in a future version through the use of a transparent colour and complex tile compositing algorithms, but such composing of tiles together will require the creation of additional tiles with the combined data, thus increasing memory usage.)
* CANVAS <0-255> SET TILE <x>,<y> = <tile number> - Set the specified tile on the specified canvas to display the specified tile number. Tile number 0 is reserved as the "transparent tile", i.e., tile zero will not STAMP over an existing tile in another canvas, and will show the screen colour behind.

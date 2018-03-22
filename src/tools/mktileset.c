/*
 * Copyright 2002-2010 Guillaume Cottenceau.
 * Copyright 2015-2018 Paul Gardner-Stephen.
 *
 * This software may be freely redistributed under the terms
 * of the X11 license.
 *
 */

/* ============================================================= */

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <stdarg.h>

#include "mktileset.h"

struct tile_set *ts=NULL;
struct screen *screen_list[256];
int screen_count=0;


/* ============================================================= */

int colour_mask=0xf0;

int palette_lookup(struct tile_set *ts,int r,int g, int b)
{
  int i;

  // Do we know this colour already?
  for(i=0;i<ts->colour_count;i++) {
    if ((r&colour_mask)==(ts->colours[i].r&colour_mask)
	&&(g&colour_mask)==(ts->colours[i].g&colour_mask)
	&&(b&colour_mask)==(ts->colours[i].b&colour_mask)) {
      // It's a colour we have seen before, so return the index
      return i;
    }
  }
  
  // new colour, check if palette has space
  if (ts->colour_count>255) {
    fprintf(stderr,"Too many colours in image: Must be <= %d\n",256);
    exit(-1);
  }

  // allocate the new colour
  ts->colours[ts->colour_count].r=r;
  ts->colours[ts->colour_count].g=g;
  ts->colours[ts->colour_count].b=b;
  return ts->colour_count++;  
}

unsigned char nyblswap(unsigned char in)
{
  return ((in&0xf)<<4)+((in&0xf0)>>4);
}

struct tile_set *new_tileset(int max_tiles)
{
  struct tile_set *ts=calloc(sizeof(struct tile_set),1);
  if (!ts) { perror("calloc() failed"); exit(-3); }
  ts->tiles=calloc(sizeof(struct tile),max_tiles);
  if (!ts->tiles) { perror("calloc() failed"); exit(-3); }
  ts->max_tiles=max_tiles;
  return ts;  
}

struct screen *new_screen(int id,struct tile_set *tiles,int width,int height)
{
  struct screen *s=calloc(sizeof(struct screen),1);
  if (!s) {
    perror("calloc() failed");
    exit(-3);
  }

  if ((width<1)||(width>255)||(height<1)|(height>255)) {
    fprintf(stderr,"Illegal screen dimensions, must be 1-255 x 1-255 characters.\n");
    exit(-3);
  }
  
  s->screen_id=id;
  s->tiles=tiles;
  s->width=width;
  s->height=height;
  s->screen_rows=calloc(sizeof(unsigned char *),height);
  s->colourram_rows=calloc(sizeof(unsigned char *),height);
  if ((!s->screen_rows)||(!s->colourram_rows)) {
    perror("calloc() failed");
    exit(-3);
  }
  for(int i=0;i<height;i++) {
    s->screen_rows[i]=calloc(sizeof(unsigned char)*2,width);
    s->colourram_rows[i]=calloc(sizeof(unsigned char)*2,width);
    if ((!s->screen_rows[i])||(!s->colourram_rows[i])) {
      perror("calloc() failed");
      exit(-3);
    }
  }
  
  return s;
}

int tile_lookup(struct tile_set *ts,struct tile *t)
{
  // See if tile matches any that we have already stored.
  // (Also check if it matches flipped in either or both X,Y
  // axes.
  for(int i=0;i<ts->tile_count;i++)
    {
      int matches=1;
      // Compare unflipped
      for(int y=0;y<8;y++)
	for(int x=0;x<8;x++)
	  if (ts->tiles[i].bytes[x][y]!=t->bytes[x][y]) {
	    matches=0; break;
	  }
      if (matches) return i;
      // Compare with flipped X
      for(int y=0;y<8;y++)
	for(int x=0;x<8;x++)
	  if (ts->tiles[i].bytes[x][y]!=t->bytes[7-x][y]) {
	    matches=0; break;
	  }
      if (matches) return i|0x4000;
      // Compare with flipped Y
      for(int y=0;y<8;y++)
	for(int x=0;x<8;x++)
	  if (ts->tiles[i].bytes[x][y]!=t->bytes[x][7-y]) {
	    matches=0; break;
	  }
      if (matches) return i|0x8000;
      // Compare with flipped X and Y
      for(int y=0;y<8;y++)
	for(int x=0;x<8;x++)
	  if (ts->tiles[i].bytes[x][y]!=t->bytes[7-x][7-y]) {
	    matches=0; break;
	  }
      if (matches) return i|0xC000;           
    }

  // The tile is new.
  if (ts->tile_count>=ts->max_tiles) {
    fprintf(stderr,"ERROR: Used up all %d tiles.\n",
	    ts->max_tiles);
    exit(-3);
  }

  // Allocate new tile and return
  for(int y=0;y<8;y++)
    for(int x=0;x<8;x++)
      ts->tiles[ts->tile_count].bytes[x][y]=t->bytes[x][y];
  return ts->tile_count++;
}

int print_spaces(FILE *f,int n)
{
  return 0;
}

int dump_bytes(int col, char *msg,unsigned char *bytes,int length)
{
  print_spaces(stderr,col);
  fprintf(stderr,"%s:\n",msg);
  for(int i=0;i<length;i+=16) {
    print_spaces(stderr,col);
    fprintf(stderr,"%04X: ",i);
    for(int j=0;j<16;j++) if (i+j<length) fprintf(stderr," %02X",bytes[i+j]);
    fprintf(stderr,"\n");
  }
  return 0;
}

/* ============================================================= */

int raw_tile_count=0;
int screen_num=1;


int main(int argc, char **argv)
{
  int i,x,y;
  
  if (argc <3) {
    fprintf(stderr,"Usage: mktileset <output file> [c64palette] <png file|font spec ...>\n");
    fprintf(stderr,"        png file - Specifies a PNG file to be converted to a canvas in the tileset.\n");
    fprintf(stderr,"       font spec - Specifies a TTF font file, the type face, size and set of characters to be converted into a font canvas in the tileset:\n");
    fprintf(stderr,"                   file.ttf:typeface:size:unicode point, ...\n");
    
    exit(-1);
  }

  FILE *outfile=fopen(argv[1],"w");
  if (!outfile) {
    perror("Could not open output file");
    exit(-3);
  }

  // Allow upto 128KB of tiles (we will complain later when
  // saving out, if the whole thing is too big).
  ts=new_tileset(2048);

  if (argc>255) {
    fprintf(stderr,"ERROR: Too many input files. Maximum of 250 PNG and/or font specifications.\n");
    exit(-3);
  }
  
  for(int i=2;i<argc;i++) {
    printf("Reading %s\n",argv[i]);
    if ((i==2)&&(!strcmp(argv[i],"c64palette"))) {
      printf("Putting C64 palette in slots 0 - 15\n");
      // Pre-populate with C64 palette
      palette_lookup(ts,0,0,0); // black 0
      palette_lookup(ts,0xff,0xff,0xff); // white 1
      palette_lookup(ts,0xab,0x31,0x26); // red 2
      palette_lookup(ts,0x66,0xda,0xff); // cyan 3
      palette_lookup(ts,0xbb,0x3f,0xb8); // pur 4
      palette_lookup(ts,0x55,0xce,0x58); // green 5
      palette_lookup(ts,0x1d,0x0e,0x97); // blue 6
      palette_lookup(ts,0xea,0xf5,0x7c); // yel 7
      palette_lookup(ts,0xb9,0x74,0x18); // org 8
      palette_lookup(ts,0x78,0x73,0x00); // brown 9
      palette_lookup(ts,0xdd,0x93,0x87); // pink 10
      palette_lookup(ts,0x5b,0x5b,0x5b); // dark gray 11
      palette_lookup(ts,0x8b,0x8b,0x8b); // med gray 12
      palette_lookup(ts,0xb0,0xf4,0xac); // light green 13
      palette_lookup(ts,0xaa,0x9d,0xef); // light blue 14
      palette_lookup(ts,0xb8,0xb8,0xb8); // light grey 15
    }
    else {
      if (!strstr(argv[i],":"))
	process_png(ts,argv[i]);
      else
	process_ttf(ts,argv[i]);
    }
  }

  printf("Images consists of %d tiles (%d unique) and %d unique colours found.\n",
	 raw_tile_count,ts->tile_count,ts->colour_count);

  // Write out tile set structure
  /*
    Tile set consists of:
    64 byte header
    header + 0-15 = magic string "MEGA65 TILESET00" [becomes tokenised ID after loading]
    header + 16,17 = tile count
    header + 18 = number of palette slots used
    [ header + 19,20 = first tile number (set only when loaded) ]
    
    header + 61-63 = size of section in bytes
    3x256 bytes palette values
    Tiles, 64 bytes each.
  */
  printf("Writing headers...\n");
  unsigned char header[64];
  bzero(header,sizeof(header));
  snprintf((char *)header,64,"MEGA65 TILESET00");
  header[16]=ts->tile_count&0xff;
  header[17]=(ts->tile_count>>8)&0xff;
  header[18]=ts->colour_count;
  unsigned size = 64 + 256 + 256 + 256 + (ts->tile_count * 64);
  header[61]=(size>>00)&0xff;
  header[62]=(size>>8)&0xff;
  header[63]=(size>>16)&0xff;
  fwrite(header,64,1,outfile);
  unsigned char paletteblock[256];
  for(i=0;i<256;i++) paletteblock[i]=nyblswap(ts->colours[i].r);
  fwrite(paletteblock,256,1,outfile);
  for(i=0;i<256;i++) paletteblock[i]=nyblswap(ts->colours[i].g);
  fwrite(paletteblock,256,1,outfile);
  for(i=0;i<256;i++) paletteblock[i]=nyblswap(ts->colours[i].b);
  fwrite(paletteblock,256,1,outfile);

  printf("Writing tiles"); fflush(stdout);
  for(i=0;i<ts->tile_count;i++) {
    unsigned char tile[64];
    for(y=0;y<8;y++)
      for(x=0;x<8;x++)
	tile[y*8+x]=ts->tiles[i].bytes[x][y];
    fwrite(tile,64,1,outfile);
    printf("."); fflush(stdout);
  }
  printf("\n");

  // Write out screen structures
  /* 
    Screen consists of
    64 byte header
    header + 0-14 = magic string "MEGA65 SCREEN00"
    header + 15 = screen ID number
    header + 16 = width
    header + 17 = height
    
    header + 18-20 = offset of screenram rows
    header + 21-24 = offset of colourram rows

    header + 25-26 = length of screenram/colourram row slabs

    header + 61-63 = size of section in bytes

    screenram bytes (2 bytes x width) x height [get resolved to absolute tile numbers after loading]
    colourram bytes (2 bytes x width) x height     
  */
  printf("Writing screens"); fflush(stdout);
  for(i=0;i<screen_count;i++)
    {
      unsigned char header[64];
      bzero(header,sizeof(header));
      snprintf((char *)header,64,"MEGA65 SCREEN00");
      header[15]=screen_list[i]->screen_id;
      header[16]=screen_list[i]->width;
      header[17]=screen_list[i]->height;
      unsigned int screenram_rows_offset
	= 64;
      unsigned int slab_size=(2*screen_list[i]->width)*screen_list[i]->height;
      header[25]=(slab_size>>0)&0xff;
      header[26]=(slab_size>>8)&0xff;
      unsigned int colourram_rows_offset=screenram_rows_offset + slab_size;
      // Screen RAM follows immediately from header block
      header[18]=(64>>0)&0xff;
      header[19]=(64>>8)&0xff;
      header[20]=(64>>16)&0xff;
      // Colour RAM follows screen RAM
      header[21]=(colourram_rows_offset>>0)&0xff;
      header[22]=(colourram_rows_offset>>8)&0xff;
      header[23]=(colourram_rows_offset>>16)&0xff;
      // XXX - Pointer to list of code points and character widths for font canvasses
      // header[28]=
      // header[29]=
      // header[30]=
      
      unsigned int size = colourram_rows_offset + slab_size;
      header[61]=(size>>0)&0xff;
      header[62]=(size>>8)&0xff;
      header[63]=(size>>16)&0xff;
      fwrite(header,64,1,outfile);

      // Write out screen RAM rows
      for(y=0;y<screen_list[i]->height;y++) {
	char msg[80];
	snprintf(msg,80,"screen_rows[%d]",y);
	dump_bytes(0,msg,screen_list[i]->screen_rows[y],2*screen_list[i]->width);
	fwrite(screen_list[i]->screen_rows[y],2*screen_list[i]->width,1,outfile);
      }
      // Write out colour RAM rows
      for(y=0;y<screen_list[i]->height;y++)
	fwrite(screen_list[i]->colourram_rows[y],2*screen_list[i]->width,1,outfile);
      // Write out font info
      if (screen_list[i]->isFont) {
	
      }
      
      printf("."); fflush(stdout);
    }
  printf("\n");

  /* Finish off with a null header */
  printf("Adding end of file marker.\n");
  bzero(header,sizeof(header));
  fwrite(header,64,1,outfile);
  
  long length = ftell(outfile);
  printf("Wrote %d bytes\n",(int)length);
  
  if (outfile != NULL) {
    fclose(outfile);
    outfile = NULL;
  }

  return 0;
}

/* ============================================================= */

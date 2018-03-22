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

#define PNG_DEBUG 3
#include <png.h>

#include "mktileset.h"

/* ============================================================= */

int x, y;

int width, height;
png_byte color_type;
png_byte bit_depth;

png_structp png_ptr;
png_infop info_ptr;
int number_of_passes;
png_bytep * row_pointers;
int multiplier;

/* ============================================================= */

void abort_(const char * s, ...)
{
  va_list args;
  va_start(args, s);
  vfprintf(stderr, s, args);
  fprintf(stderr, "\n");
  va_end(args);
  abort();
}

/* ============================================================= */

struct screen *png_to_screen(int id,struct tile_set *ts)
{
  int x,y;

  if (height%8||width%8) {
    fprintf(stderr,"ERROR: PNG image dimensions must be a multiple of 8.\n");
    exit(-3);
  }

  struct screen *s=new_screen(id,ts,width/8,height/8);
  
  for(y=0;y<height;y+=8)
    for(x=0;x<width;x+=8)
      {
	int transparent_tile=1;
	struct tile t;
	for(int yy=0;yy<8;yy++) {
	  png_byte* row = row_pointers[yy+y];
	  for(int xx=0;xx<8;xx++)
	    {
	      png_byte* ptr = &(row[(xx+x)*multiplier]);	      
	      int r,g,b,a,c;
	      r=ptr[0];
	      g=ptr[1];
	      b=ptr[2];
	      if (multiplier==4) a=ptr[3]; else a=0xff;
	      if (a) {
		transparent_tile=0;
		c=palette_lookup(ts,r,g,b);
	      } else c=0;
	      t.bytes[xx][yy]=c;
	    }
	}
	if (transparent_tile) {
	  //	  printf("Tile [%d,%d] is transparent (x*2+0 = %d)\n",x/8,y/8,x*2+1);
	  // Set screen and colour bytes to all $FF to indicate
	  // non-set block.
	  s->screen_rows[y/8][x/8*2+0]=0xFF;
	  s->screen_rows[y/8][x/8*2+1]=0xFF;
	  s->colourram_rows[y/8][x/8*2+0]=0xFF;
	  s->colourram_rows[y/8][x/8*2+1]=0xFF;
	} else {
	  // Block has non-transparent pixels, so add to tileset,
	  // or lookup to see if it is already there.
	  int tile_number=tile_lookup(ts,&t);
	  // Add $100 to tile number to mark it as non-text
	  tile_number+=0x100;
	  // Then store it
	  s->screen_rows[y/8][x/8*2+0]=tile_number&0xff;
	  s->screen_rows[y/8][x/8*2+1]=(tile_number>>8)&0xff;
	  s->colourram_rows[y/8][x/8*2+0]=0x00; // Extended attributes
	  s->colourram_rows[y/8][x/8*2+1]=0; // =0xff; // FG colour (only works if extended fg mode enabled?)
	}
      }
  return s;
}


void read_png_file(char* file_name)
{
  unsigned char header[8];    // 8 is the maximum size that can be checked

  /* open file and test for it being a png */
  FILE *infile = fopen(file_name, "rb");
  if (infile == NULL)
    abort_("[read_png_file] File %s could not be opened for reading", file_name);

  fread(header, 1, 8, infile);
  if (png_sig_cmp(header, 0, 8))
    abort_("[read_png_file] File %s is not recognized as a PNG file", file_name);

  /* initialize stuff */
  png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

  if (!png_ptr)
    abort_("[read_png_file] png_create_read_struct failed");

  info_ptr = png_create_info_struct(png_ptr);
  if (!info_ptr)
    abort_("[read_png_file] png_create_info_struct failed");

  if (setjmp(png_jmpbuf(png_ptr)))
    abort_("[read_png_file] Error during init_io");

  png_init_io(png_ptr, infile);
  png_set_sig_bytes(png_ptr, 8);

  // Convert palette to RGB values
  png_set_expand(png_ptr);

  png_read_info(png_ptr, info_ptr);

  width = png_get_image_width(png_ptr, info_ptr);
  height = png_get_image_height(png_ptr, info_ptr);
  color_type = png_get_color_type(png_ptr, info_ptr);
  bit_depth = png_get_bit_depth(png_ptr, info_ptr);

  printf("Input-file is: width=%d, height=%d.\n", width, height);

  number_of_passes = png_set_interlace_handling(png_ptr);
  png_read_update_info(png_ptr, info_ptr);

  /* read file */
  if (setjmp(png_jmpbuf(png_ptr)))
    abort_("[read_png_file] Error during read_image");

  row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * height);
  for (y=0; y<height; y++)
    row_pointers[y] = (png_byte*) malloc(png_get_rowbytes(png_ptr,info_ptr));

  png_read_image(png_ptr, row_pointers);

  if (infile != NULL) {
    fclose(infile);
    infile = NULL;
  }

  if (png_get_color_type(png_ptr, info_ptr) == PNG_COLOR_TYPE_RGB)
    multiplier=3;
  else if (png_get_color_type(png_ptr, info_ptr) == PNG_COLOR_TYPE_RGBA)
    multiplier=4;
  else {
    fprintf(stderr,"Could not convert file to RGB or RGBA\n");
    exit(-3);
  }

  return;
}

void process_png(struct tile_set *ts,char *filename)
{
  read_png_file(filename);
  raw_tile_count+=width*height/64;
  // We start with screen ID 1, as screen ID 0 is reserved to refer to the
  // current displayed screen.
  struct screen *s = png_to_screen(screen_num++,ts);
  screen_list[screen_count++]=s;
  return;
}

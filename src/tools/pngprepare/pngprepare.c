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

/* ============================================================= */

int x, y;

int width, height;
png_byte color_type;
png_byte bit_depth;

png_structp png_ptr;
png_infop info_ptr;
int number_of_passes;
png_bytep * row_pointers;

FILE *infile;
FILE *outfile;

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

void read_png_file(char* file_name)
{
  unsigned char header[8];    // 8 is the maximum size that can be checked

  /* open file and test for it being a png */
  infile = fopen(file_name, "rb");
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

  printf("Input-file is read and now closed\n");
}

/* ============================================================= */

struct rgb {
  int r;
  int g;
  int b;
};

struct rgb palette[256];
int palette_first=16;
int palette_index=16; // only use upper half of palette

int palette_lookup(int r,int g, int b)
{
  int i;

  // Do we know this colour already?
  for(i=palette_first;i<palette_index;i++) {
    if (r==palette[i].r&&g==palette[i].g&&b==palette[i].b) {
      return i;
    }
  }
  
  // new colour
  if (palette_index>255) {
    fprintf(stderr,"Too many colours in image: Must be <= %d\n",
	    256-palette_first);
    exit(-1);
  }

  // allocate it
  palette[palette_index].r=r;
  palette[palette_index].g=g;
  palette[palette_index].b=b;
  return palette_index++;
  
}

unsigned char nyblswap(unsigned char in)
{
  return ((in&0xf)<<4)+((in&0xf0)>>4);
}

void process_file(int mode, int do_reverse, char *outputfilename)
{
  int multiplier=-1;
  if (png_get_color_type(png_ptr, info_ptr) == PNG_COLOR_TYPE_RGB)
    multiplier=3;

  if (png_get_color_type(png_ptr, info_ptr) == PNG_COLOR_TYPE_RGBA)
    multiplier=4;

  if (multiplier==-1) {
    fprintf(stderr,"Could not convert file to RGB or RGBA\n");
  }

  outfile=fopen(outputfilename,"w");
  if (outfile == NULL) {
    // could not open output file, so close all and exit
    if (infile != NULL) {
      fclose(infile);
      infile = NULL;
    }
    abort_("[process_file] File %s could not be opened for writing", outputfilename);
  }


  /* ============================ */

  unsigned char first_half[1024];
  
  // charrom mode

  int bytes=0;
  if (width!=8) {
    fprintf(stderr,"Fonts must be 8 pixels wide\n");
  }

  fprintf(stderr,"Parsing PNG pixels to bytes...\n");
  
  for (y=0; y<height; y++) {
    png_byte* row = row_pointers[y];
    int byte=0;
    
    for (x=0; x<width; x++) {
      png_byte* ptr = &(row[x*multiplier]);
      int r=ptr[0],g=ptr[1],b=ptr[2]; //, a=ptr[3];
      
      if (x<8) {
	if (r>0x7f||g>0x7f||b>0x7f) {
	  byte|=(1<<(7-x));
	}
      }
    }
    fflush(stdout);
    if (bytes<1024) {
      first_half[bytes]=byte;
    }
    bytes++;            
  }

  fprintf(stderr,"Writing font (%d bytes read)...\n",bytes);

  // Reorder the font layout so that PRINTing ASCII characters in
  // C64 mode causes the correct thing to show on the screen
  unsigned char fixed[1024];

  for(int i=0;i<1024;i++) fixed[i]=first_half[i];

  // Copy upper case chars from 0x40+ to 0x00+
  int o;
  o=0x00;
  for(int c=0x40;c<0x5b;c++) {
    for(int i=0;i<8;i++) {
      fixed[o*8+i]=first_half[c*8+i];
    }
    o++;
  }

  // Lower case to upper case position
  o=0x40;
  for(int c=0x60;c<0x7b;c++) {
    for(int i=0;i<8;i++) {
      fixed[o*8+i]=first_half[c*8+i];
    }
    o++;
  }

  // Write out the 128 characters normal and reverse, twice each
  // to make a complete 256 char ROM.
  for(int i=0;i<1024;i++) fputc(fixed[i],outfile);
  for(int i=0;i<1024;i++) fputc(fixed[i]^0xff,outfile);
  for(int i=0;i<1024;i++) fputc(fixed[i],outfile);
  for(int i=0;i<1024;i++) fputc(fixed[i]^0xff,outfile);
}

/* ============================================================= */

int main(int argc, char **argv)
{
  if (argc != 4) {
    fprintf(stderr,"Usage: program_name <logo|charrom|charrom+reverse|hires|sprite16> <file_in> <file_out>\n");
    exit(-1);
  }

  int mode=-1;
  int do_reverse=0;

  if (!strcasecmp("logo",argv[1])) mode=0;
  if (!strcasecmp("charrom",argv[1])) mode=1;
  if (!strcasecmp("charrom+reverse",argv[1])) { mode=1; do_reverse=1; }
  if (!strcasecmp("hires",argv[1])) mode=2;
  if (!strcasecmp("sprite16",argv[1])) mode=3;
  if (mode==-1) {
    fprintf(stderr,"Usage: program_name <logo|charrom|hires|sprite16> <file_in> <file_out>\n");
    exit(-1);
  }

  printf("argv[0]=%s\n", argv[0]);
  printf("argv[1]=%s\n", argv[1]);
  printf("argv[2]=%s\n", argv[2]);
  printf("argv[3]=%s\n", argv[3]);

  printf("Reading %s\n",argv[2]);
  read_png_file(argv[2]);

  printf("Processing with mode=%d and output=%s\n", mode, argv[3]);
  process_file(mode,do_reverse,argv[3]);

  printf("done\n");

  if (infile != NULL) {
    fclose(infile);
    infile = NULL;
  }

  if (outfile != NULL) {
    fclose(outfile);
    outfile = NULL;
  }

  return 0;
}

/* ============================================================= */

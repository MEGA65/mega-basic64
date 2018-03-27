#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <math.h>

#include "mktileset.h"

#include <ft2build.h>
#include FT_FREETYPE_H

#define MAX_POINTS 1024
int unicode_points[MAX_POINTS]={
  0
};
int glyph_count=0;
int rendered=0;

int encode_card(struct tile_set *ts,
		FT_GlyphSlot  slot,int card_x, int card_y);

void process_ttf(struct tile_set *ts,char *font_spec)
{
  // Initialise unicode points we want to render.
  FT_Library    library;
  FT_Face       face;

  FT_GlyphSlot  slot;
  FT_Error      error;

  char          filename[8192];
  int           face_id;
  char          point_spec[8192];

  int           n;
  
  int           font_points=16; // Height of face

  if (strlen(font_spec)>8191) {
    fprintf(stderr,"Font spec too long. Must not exceed 8192 characters in length.\n");
    exit(-3);
  }
  
  if (sscanf(font_spec,"%[^:]:%d:%d:%s",filename,&face_id,&font_points,point_spec)!=4) {
    fprintf(stderr,"Could not parse font spec: %s\n",font_spec);
    exit(-3);
  }

  char *hex=strtok(point_spec,",");
  while(hex) {
    unsigned int lo,hi;
    unsigned int code_point = strtoll(hex,NULL,16);
    if (sscanf(hex,"%x-%x",&lo,&hi)==2) {
      for(unsigned int code_point=lo;code_point<=hi;code_point++) {
	if (glyph_count<MAX_GLYPHS_PER_CANVAS) {
	  unicode_points[glyph_count++]=code_point;
	} else {
	  fprintf(stderr,"Too many code points in font definition. Limit is %d.\n",
		  MAX_GLYPHS_PER_CANVAS-1);
	  exit(-3);
	}
      }
    } else {
      //    printf("Code point #%d is 0x%x from \"%s\"\n",glyph_count,code_point,hex);
      if (glyph_count<MAX_GLYPHS_PER_CANVAS) {
	unicode_points[glyph_count++]=code_point;
      } else {
	fprintf(stderr,"Too many code points in font definition. Limit is %d.\n",
		MAX_GLYPHS_PER_CANVAS);
	exit(-3);
      }
    }
    hex=strtok(NULL,",");
  }

  printf("Defined %d unicode points\n",glyph_count);
  

  error = FT_Init_FreeType( &library );              /* initialize library */
  /* error handling omitted */

  error = FT_New_Face( library, filename, 0, &face );/* create face object */
  /* error handling omitted */

  error = FT_Set_Pixel_Sizes( face, font_points,font_points);
  /* error handling omitted */

  slot = face->glyph;

  int max_char_columns=0;
  int max_char_rows=0;
  int max_char_underhang=0;
  
  // Work out size of the largest glyph, so that we can dimension things correctly.
  for ( n = 0; n < glyph_count; n++ )
  {
    /* load glyph image into the slot (erase previous one) */

    // Convert unicode point to glyph index
    int glyph_index = FT_Get_Char_Index( face, unicode_points[n] );
    // read glyph by index
    error = FT_Load_Glyph( face, glyph_index, FT_LOAD_RENDER );

    if ( error ) {
      fprintf(stderr,"Could not load glyph #%d, derived from unicode point 0x%x of face #%d of '%s'\n",
	      glyph_index,unicode_points[n],face_id,filename);
      exit(-3);
    }

    /* now, draw to our target surface (convert position) */
    // printf("Sizing U+%04x\n",unicode_points[n]);
    int char_rows=0,char_columns=0;
    int under_rows=0,under_columns=0;
    int blank_pixels_to_left=slot->bitmap_left;
    if (blank_pixels_to_left<0) blank_pixels_to_left=0;
    if (slot->bitmap_top>=0) {
      char_rows=(slot->bitmap_top+1)/8;
      if ((slot->bitmap_top+1)%8) char_rows++;
      char_columns=(slot->bitmap_left+slot->bitmap.width+1)/8;
      if ((slot->bitmap_left+slot->bitmap.width+1)%8) char_columns++;
      if (!char_columns) { char_columns=1; char_rows=1; }
    }
    if (slot->bitmap_top-slot->bitmap.rows<0) {
      // Character has underhang as well
      int underhang=slot->bitmap.rows-slot->bitmap_top;
      under_rows=underhang/8;
      if (underhang%8) under_rows++;
      under_columns=(slot->bitmap_left+slot->bitmap.width+1)/8;
      if ((slot->bitmap_left+slot->bitmap.width)%8) under_columns++;
    }

    if (char_rows> max_char_rows) max_char_rows=char_rows;
    if (under_rows > max_char_underhang) max_char_underhang=under_rows;
    if (char_columns>max_char_columns) max_char_columns=char_columns;
    
  }  
  printf("max y range = %d..%d, x width = %d\n",max_char_rows-1,-max_char_underhang,max_char_columns);

  // How big does our screen need to be, to fit everything?
  int glyph_rows_in_canvas=255/glyph_count;
  int screen_width_required=max_char_rows*glyph_count;
  if (screen_width_required>255) screen_width_required=255;
  int screen_height_required=glyph_rows_in_canvas*(max_char_rows+max_char_underhang);
  printf("Canvas will be %d,%d\n",screen_width_required,screen_height_required);
  
  struct screen *s=new_screen(screen_num++,ts,screen_width_required,screen_height_required);
  screen_list[screen_count++]=s;
    
  // Start in upper left of canvas when placing rendered glyphs.
  int yy=0;
  int xx=0;
  
  for ( n = 0; n < glyph_count; n++ )
  {
    /* load glyph image into the slot (erase previous one) */

    // Convert unicode point to glyph index
    int glyph_index = FT_Get_Char_Index( face, unicode_points[n] );
    // read glyph by index
    error = FT_Load_Glyph( face, glyph_index, FT_LOAD_RENDER );

    if ( error ) {
      fprintf(stderr,"Could not load glyph #%d, derived from unicode point 0x%x of face #%d of '%s'\n",
	      glyph_index,unicode_points[n],face_id,filename);
      exit(-3);
    }

    /* now, draw to our target surface (convert position) */
    printf("Rendering U+%04x\n",unicode_points[n]);
    printf("bitmap_left=%d, bitmap_top=%d\n", slot->bitmap_left, slot->bitmap_top);
    printf("bitmap_width=%d, bitmap_rows=%d\n", slot->bitmap.width, slot->bitmap.rows);
    int char_rows=0,char_columns=0;
    int under_rows=0,under_columns=0;
    int blank_pixels_to_left=slot->bitmap_left;
    if (blank_pixels_to_left<0) blank_pixels_to_left=0;
    if (slot->bitmap_top>=0) {
      char_rows=(slot->bitmap_top+1)/8;
      if ((slot->bitmap_top+1)%8) char_rows++;
      char_columns=(slot->bitmap_left+slot->bitmap.width+1)/8;
      if ((slot->bitmap_left+slot->bitmap.width+1)%8) char_columns++;
      if (!char_columns) { char_columns=1; char_rows=1; }
      if (1) printf("Character is %dx%d cards above, and includes %d pixels to the left. bitmap_top=%d\n",
		    char_columns,char_rows,blank_pixels_to_left,slot->bitmap_top);
    }
    if (slot->bitmap_top-slot->bitmap.rows<0) {
      // Character has underhang as well
      int underhang=slot->bitmap.rows-slot->bitmap_top;
      under_rows=underhang/8;
      if (underhang%8) under_rows++;
      under_columns=(slot->bitmap_left+slot->bitmap.width+1)/8;
      if ((slot->bitmap_left+slot->bitmap.width)%8) under_columns++;
      if (1) printf("Character is %dx%d cards under, and includes %d pixels to the left.\n",
	     under_columns,under_rows,blank_pixels_to_left);
    }

    int x,y;

    printf("y range = %d..%d\n",char_rows-1,-under_rows);
    
    // Work out horizontal width of the glyph
    int glyph_display_width=slot->bitmap_left+slot->bitmap.width;
    if (glyph_display_width==0)
      glyph_display_width=(slot->metrics.horiAdvance/64);
    printf("glyph display width = %d\n",glyph_display_width);
    printf("horiAdvance = %d, char_columns=%d\n",
	   (int)slot->metrics.horiAdvance,char_columns);
    
    // Record number of pixels to trim from right-most tile
    int right_trim=(~glyph_display_width)&7;  

    // Now build the glyph map

    int write_y=yy;
    
    for(y=char_rows-1;y>=-under_rows;y--) {
      int write_x=xx;
      for(x=0;x<char_columns;x++)
	{
	  int tile_number=encode_card(ts,slot,x,y);
	  if (tile_number<0||tile_number>(4095-0x100)) {
	    printf("Ran out of tiles.\n");
	    exit(-1);
	  } else {
	    printf("  encoding tile (%d,%d) using card #%d\n",x,y,tile_number);

	    // Record tile number in screen_row
	    tile_number+=0x100;
	    s->screen_rows[write_y][write_x*2+0]=tile_number&0xff;
	    s->screen_rows[write_y][write_x*2+1]=(tile_number>>8)&0xff;
	    // XXX - We should allow for canvases to lack colour RAM data when not required to
	    // save space.
	    s->colourram_rows[write_y][write_x*2+0]=0x00; // Extended attributes
	    s->colourram_rows[write_y][write_x*2+1]=0; // =0xff; // FG colour (only works if extended fg mode enabled?)

	    if (x==(char_columns-1)) {
	      // Right-most column, so apply right_trim to reduce width of card when rendered
	      s->screen_rows[write_y][write_x*2+1]|=(right_trim<<5)&0xe0;
	    }
	    
	  }
	  // Update canvas write column ready for next iteration
	  write_x++;
	}
      // Update canvas write row ready for next iteration
      write_y++;
    }

    // Record the unicode point and x,y position
    // XXX - We should deduplicate code points that point to the same visible rendering
    // so that we don't waste canvas bytes.

    // Write unicode point into the list
    for(int i=0;i<4;i++) s->code_point_info[n*8+i]=(unicode_points[n]>>(i*8))&0xff;
    // Write (x,y) position and (width,height) also
    s->code_point_info[n*8+4]=xx;
    s->code_point_info[n*8+5]=yy;
    s->code_point_info[n*8+6]=char_columns;
    s->code_point_info[n*8+7]=char_rows-under_rows;
    // Update length of code point info structure
    s->code_point_info_bytes=n*8+8;
    
    // work out where to write the next glyph in the canvas, if there is a next glyph
    // (we tile them horizontally and vertically, so that we can fit as many as possible)
    if (n<glyph_count) {
      xx+=max_char_columns;
      if (x>=(255-max_char_columns)) {
	xx=0;
	yy+=max_char_rows-max_char_underhang;
      }
      if (yy>=255) {
	fprintf(stderr,"Cannot fit glyph #%d (unicode point 0x%x) into canvas.\n",
		n+1,unicode_points[n+1]);
	exit(-3);
      }
    }
    
    rendered++;
  }

#if 0
  // $00A0-$00BF - style (eg bold, italic, condensed) of font
  if (face->style_name) {
    for(i=0;i<32;i++)
      if (face->style_name[i]) font_data[0xa0+i]=face->style_name[i];
      else break;
  }

  // $00c0 - $00ff - name of font (upto 64 bytes)
  if (face->family_name) {
    for(i=0;i<64;i++)
      if (face->family_name[i]) font_data[0xc0+i]=face->family_name[i];
      else break;
  }
#endif
  
  FT_Done_Face    ( face );
  FT_Done_FreeType( library );

  return;
}

int encode_card(struct tile_set *ts,
		FT_GlyphSlot  slot,int card_x, int card_y)
{
  int min_x=slot->bitmap_left;
  if (min_x<0) min_x=0;
  int max_x=slot->bitmap.width+min_x;

  int max_y=slot->bitmap_top-1;
  int min_y=slot->bitmap_top-1-slot->bitmap.rows;

  int base_x=card_x*8;
  int base_y=card_y*8;

  if (1) printf("x=%d..%d, y=%d..%d, base=(%d,%d)\n",
		min_x,max_x,min_y,max_y,base_x,base_y);
  
  unsigned char card[64];

  struct tile t;
  
  int x,y;
  for(y=0;y<8;y++) {
      for(x=0;x<8;x++)
	{
	  int pixel=0;
	  int x_pos=x+base_x-min_x;
	  int y_pos=slot->bitmap_top-((7-y)+base_y);
	  // printf("pixel (%d,%d) will be in bitmap (%d,%d)\n",
	  // x,y,x_pos,y_pos);
	  if ((x_pos>=0&&x_pos<slot->bitmap.width)
	      &&(y_pos>=0&&y_pos<slot->bitmap.rows)) {
	    // Pixel is in bitmap
	    pixel=slot->bitmap.buffer[x_pos+y_pos*slot->bitmap.width];
	  } else {
	    // Pixel is not in bitmap, so blank pixel
	    pixel=0;
	  }

	  // Use 4-bit resolution for anti-aliasing, so that we
	  // don't too easily fill the palette.
	  int r,g,b,a,c;
	  r=pixel&0xf0;
	  g=(pixel>>8)&0xf0;
	  b=(pixel>>16)&0xf0;
	  r=r|(r>>4);
	  g=g|(b>>4);
	  b=b|(b>>4);
	  
	  a=0xff; // Alpha channel not used in fonts
	  if (a) c=palette_lookup(ts,r,g,b);
	  else c=0;
	  // printf("%c",c?'X':' ');
	  t.bytes[x][y]=c;
	}
      // printf("\n");
  }

  if (0) {
    printf("card (%d,%d) is:\n",card_x,card_y);
    for(y=0;y<8;y++) {
      for(x=0;x<8;x++)
	{
	  if (card[x+y*8]==0) 
	    printf(".");
	  else if (card[x+y*8]<128) 
	    printf("+");
	  else
	    printf("*");
	}
      printf("\n");
    }
  }

  raw_tile_count++;

  return tile_lookup(ts,&t);
}

/* EOF */

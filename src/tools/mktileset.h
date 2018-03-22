struct tile {
  unsigned char bytes[8][8];
};

struct rgb {
  int r;
  int g;
  int b;
};

struct tile_set {
  struct tile *tiles;
  int tile_count;
  int max_tiles;

  // Palette
  struct rgb colours[256];
  int colour_count;
  
  struct tile_set *next;
};

struct glyph_info {
  unsigned int unicode_codepoint;
  unsigned char width;
};

struct screen {
  // Unique identifier
  unsigned char screen_id;
  // Which tile set the screen uses
  struct tile_set *tiles;
  unsigned char width,height;
  unsigned char **screen_rows;
  unsigned char **colourram_rows;

  // For rasterised fonts, we need to know which glyphs we have stored
  unsigned char isFont;
  unsigned char glyph_count;
  struct glyph_info glyphs[256];
  
  struct screen *next;
};

extern int screen_num;
extern int raw_tile_count;
extern struct screen *screen_list[256];
extern int screen_count;

int palette_lookup(struct tile_set *ts,int r,int g, int b);
unsigned char nyblswap(unsigned char in);
struct tile_set *new_tileset(int max_tiles);
struct screen *new_screen(int id,struct tile_set *tiles,int width,int height);
int tile_lookup(struct tile_set *ts,struct tile *t);
int print_spaces(FILE *f,int n);
int dump_bytes(int col, char *msg,unsigned char *bytes,int length);
struct screen *png_to_screen(int id,struct tile_set *ts);
void read_png_file(char* file_name);
void process_png(struct tile_set *ts,char *filename);



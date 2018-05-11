/*
  Simple C64 BASIC pre-processor to make it easier to write
  complex programs.

  Each file is read in order.
  Lines beginning with a TAB get given the next free line number.
  Lines beginning with A-Z+ get given next free line number, and
  the label takes the line number as value, so that it can be used
  as an argument to GOTO, GOSUB etc elsewhere in the program.

  The first file read is assumed to be the one requiring the lowest line number.

  The resolved output is then written out as a single C64 BASIC program
  text (untokenised).

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#define MAX_LABELS 16384
char *label_names[MAX_LABELS];
int label_lines[MAX_LABELS];
int label_count=0;

int resolve_symbol(char *s,char *o,int *olen)
{
	for(int i=0;i<label_count;i++) {
		if (!strcmp(s,label_names[i])) {
			snprintf(&o[*olen],1023-*olen,"%d",label_lines[i]);
			*olen=strlen(o);
			return 0;
		}
	}
	return -1;
}

void compact_line(char *l)
{
  char out[1024];
  int len=0;
  int i;
  int quoteMode=0;

  for(i=0;l[i];i++) {
    if (l[i]=='\"') quoteMode^=1;
    if (l[i]==' '&&(!quoteMode)) {
      // Remove spaces that aren't in strings
    } else {
      out[len++]=l[i];
    }
    // Skip what follows a REM statement
    if ((!quoteMode)&&(!strncmp("rem",&l[i],3))) {
      out[len++]='e'; out[len++]='m';
      break;
    }
    // And delete entirely any :rem...
    if ((!quoteMode)&&(!strncmp(":rem",&l[i],4))) {
      len--;
    }
  }
  out[len]=0;
  strcpy(l,out);
  return;
}

int main(int argc,char **argv)
{
	int i;
	char line[1024];

	int errors=0;

	// Pass 1 - find all labels
	int line_number=0;
	fprintf(stderr,"Pass 1: Find and resolve labels\n");
	for(i=1;i<argc;i++) {
		fprintf(stderr,"  Reading %s\n",argv[i]);
		FILE *f=fopen(argv[i],"r");
		if (!f) {
			fprintf(stderr,"Could not open '%s'\n",argv[1]);
			perror("fopen");
			exit(-3);
		}
		int fl=1;
		line[0]=0; fgets(line,1024,f);
		while(line[0]) {
			if (line[0]=='#') goto skipline1;
			if (line[0]=='\t' || (line[0]>='a' && line[0]<='z')) {
				// Line starts with TAB, so allocate line number
				line_number++;
			} else if (line[0]>='0' && line[0]<='9') {
				// Line with number
				line_number=atoi(line);
				if (line_number>65535) {
					fprintf(stderr,"%s:%d:ERROR Illegal line number\n",argv[i],fl);
					errors++;
				}
			} else if (line[0]>='A' && line[0]<='Z') {
				// Line starts with a label, so record and allocate line number.
				char label[1024]="";
				sscanf(line,"%[A-Z0-9_+-]* ",label);
				if (!label[0]) {
					fprintf(stderr,"%s:%d: Could not parse label at start of line.\n",argv[i],fl);
					errors++;
				}
				line_number++;
				if (label_count>=MAX_LABELS) {
					fprintf(stderr,"%s:%d:ERROR: Too many unique labels.\n",argv[i],fl);
					exit(-3);
				}
				label_names[label_count]=strdup(label);
				label_lines[label_count++]=line_number;
			}
skipline1:
			line[0]=0; fgets(line,1024,f);
			fl++;
		}
		fclose(f);
	}
	
	fprintf(stderr,"%d labels found. Max line number is %d\n",label_count,line_number);
	for(int i=0;i<label_count;i++)
		fprintf(stderr,"  %s = %d\n",label_names[i],label_lines[i]);
	
	
	// Pass 2 - resolve line numbers
	fprintf(stderr,"Pass 2: Resolve line numbers.\n");
	line_number=0;
	for(i=1;i<argc;i++) {
		fprintf(stderr,"  Reading %s\n",argv[i]);
		FILE *f=fopen(argv[i],"r");
		if (!f) {
			fprintf(stderr,"Could not open '%s'\n",argv[1]);
			perror("fopen");
			exit(-3);
		}
		int fl=1;
		line[0]=0; fgets(line,1024,f);
		while(line[0]) {
		  if (line[0]=='#') goto skipline2;
			int outlen=0;
			char lineout[1024];
			int quote_mode=0;
			char symbol[1024];
			int symbol_len=0;
			
			if (line[0]>='0' && line[0]<='9') {
				// Line with number
				line_number=atoi(line);
			} else if (line[0]>=' '){
				// Line with any other printable character (TAB/HT is excluded)
				line_number++;
			}
			
			int j;
			for(j=0;line[j];j++) {
				if (
					(!j)
					&& (
						(line[j]=='\t')
						|| ((line[0]>'9')
							&& (!(line[0]>='A' && line[0]<='Z'))
						)
					)
				) {
					snprintf(lineout,1024,"%d ",line_number);
					outlen=strlen(lineout);
					if (line[j]!='\t') lineout[outlen++]=line[j];
				} else if (line[j]=='\"') {
					if (symbol_len) {
						// Replace symbol with line number
						if (resolve_symbol(symbol,lineout,&outlen)) {
							fprintf(stderr,"%s:%d:ERROR undefined label '%s'\n",argv[i],fl,symbol);
							errors++;
						}
						symbol_len=0;
					}
					lineout[outlen++]=line[j];
					quote_mode^=1;
				} else if ((
						(!j)
						|| (line[j-1]==' ')
						|| symbol_len
					)
					&& (!quote_mode)
					&& (
						(line[j]>='A' && line[j]<='Z')
						|| (symbol_len && (line[j]>='0' && line[j]<='9'))
						|| (symbol_len && line[j]=='_')
						|| (symbol_len && line[j]=='+')
						|| (symbol_len && line[j]=='-')
					)
				) {
					// beginning or continuation of symbol
					symbol[symbol_len++]=line[j];
					symbol[symbol_len]=0;
				} else {
					if (line[j]=='\t') line[j]=' ';
					if (symbol_len) {
						// Replace symbol with line number
						if (resolve_symbol(symbol,lineout,&outlen)) {
							fprintf(stderr,"%s:%d:ERROR undefined label '%s'\n",argv[i],fl,symbol);
							errors++;
						}
						symbol_len=0;
					}
					lineout[outlen++]=line[j];
				}
			}
			
			if (symbol_len) {
				// Replace symbol with line number
				if (resolve_symbol(symbol,lineout,&outlen)) {
					fprintf(stderr,"%s:%d:ERROR undefined label '%s'\n",argv[i],fl,symbol);
					errors++;
				}
			}

			lineout[outlen]=0;
			compact_line(lineout);
			outlen=strlen(lineout);
			
			printf("%s",lineout);
			if (outlen>0) if (lineout[outlen-1]>=' ') printf("\n");
			
	skipline2:
			line[0]=0; fgets(line,1024,f);
			fl++;
		}
		fclose(f);
		
	}
	
	
	if (errors) {
		fprintf(stderr,"ERROR: %d errors occurred.\n",errors);
		exit(-3);
	}
	
	return 0;
	
}

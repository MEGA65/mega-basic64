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
#include <strings.h>
#include <string.h>
#include <malloc.h>
#include <ctype.h>
#include <unistd.h>

#define MAX_LABELS 16384
char *label_names[MAX_LABELS];
int label_lines[MAX_LABELS];
int label_count=0;

#define MAX_VARIABLES 16384
char *variable_names[MAX_VARIABLES];
char *short_names[MAX_VARIABLES];
int variable_count=0;

char *current_file="(none)";
int line_number=0;
int errors=0;

int check_variable(char *sv,char *v)
{
  int i;
  for(i=0;i<variable_count;i++) {
    // We already have this variable? If so, nothing to do
    if (!strcmp(v,variable_names[i])) return 0;

    // Do we have one that has the same first two characters?
    if (!strcmp(sv,short_names[i])) {
      if (strcmp(v,variable_names[i])) {
	fprintf(stderr,"%s:%d:ERROR Conflicting variable names '%s' and '%s' both resolve to '%s'\n",
		current_file,line_number,v,variable_names[i],sv);
	errors++;
	return -1;
      }
    }
  }

  if (variable_count>MAX_VARIABLES) {
    fprintf(stderr,"Too many variables.\n");
    exit(-3);
  }
  short_names[variable_count]=strdup(sv);
  variable_names[variable_count++]=strdup(v);
  return 0;
  
}

int resolve_symbol(char *s,char *o,int *olen)
{
	for(int i=0;i<label_count;i++) {
		if (!strcmp(s,label_names[i])) {
		  if (olen&&(!(*olen))) {
		    if (label_lines[i]<line_number) {
		      fprintf(stderr,"unknown:unknown:ERROR Line numbers went backwards (from %d to %d) at %s\n",
			      line_number,label_lines[i],s);
		      errors++;		      
		    }
		  }
		  
			snprintf(&o[*olen],1023-*olen,"%d",label_lines[i]);
			*olen=strlen(o);
			return 0;
		}
	}
	return -1;
}

int notKeyword(char *s)
{
	if (!strcmp(s,"for")) return 0;
	if (!strcmp(s,"let")) return 0;
	if (!strcmp(s,"left")) return 0;
	if (!strcmp(s,"len")) return 0;
	if (!strcmp(s,"next")) return 0;
	if (!strcmp(s,"right")) return 0;
	if (!strcmp(s,"str")) return 0;
	if (!strcmp(s,"to")) return 0;
	if (!strcmp(s,"print")) return 0;
	if (!strcmp(s,"poke")) return 0;
	if (!strcmp(s,"peek")) return 0;
	if (!strcmp(s,"canvas")) return 0;
	if (!strcmp(s,"stamp")) return 0;
	if (!strcmp(s,"on")) return 0;
	if (!strcmp(s,"stop")) return 0;
	if (!strcmp(s,"rem")) return 0;
	if (!strcmp(s,"return")) return 0;
	if (!strcmp(s,"goto")) return 0;
	if (!strcmp(s,"gosub")) return 0;
	if (!strcmp(s,"then")) return 0;
	if (!strcmp(s,"clr")) return 0;
	if (!strcmp(s,"int")) return 0;
	if (!strcmp(s,"chr")) return 0;
	if (!strcmp(s,"and")) return 0;
	if (!strcmp(s,"or")) return 0;
	if (!strcmp(s,"dim")) return 0;
	if (!strcmp(s,"data")) return 0;
	if (!strcmp(s,"restore")) return 0;
	if (!strcmp(s,"def")) return 0;
	if (!strcmp(s,"fn")) return 0;
	if (!strcmp(s,"sin")) return 0;
	if (!strcmp(s,"cos")) return 0;
	if (!strcmp(s,"tan")) return 0;
	if (!strcmp(s,"atn")) return 0;
	if (!strcmp(s,"mid")) return 0;
	if (!strcmp(s,"val")) return 0;
	if (!strcmp(s,"get")) return 0;
	if (!strcmp(s,"input")) return 0;
	if (!strcmp(s,"open")) return 0;
	if (!strcmp(s,"close")) return 0;
	if (!strcmp(s,"cmd")) return 0;
	if (!strcmp(s,"end")) return 0;
	if (!strcmp(s,"new")) return 0;
	if (!strcmp(s,"asc")) return 0;
	if (!strcmp(s,"from")) return 0;
	if (!strcmp(s,"slow")) return 0;
	if (!strcmp(s,"fast")) return 0;
	if (!strcmp(s,"step")) return 0;

	return 1;
}

void compact_line(char *l)
{
	char out[1024];
	int len=0;
	int i;
	int quoteMode=0;

	for(i=0;l[i];i++) {
		if (l[i]=='\"') quoteMode^=1;

		// Shorten long variable names
		if ((!quoteMode)&&((!i)||(!isalpha(l[i-1])))) {
			if (isalpha(l[i])) {
			// Look for end of current string
				int j;
				char s[1024];
				s[0]=l[i];
				for(j=i+1;isalnum(l[j]);j++) { s[j-i]=l[j]; continue; }
				s[j-i]=0;
				if (notKeyword(s)) {
				  // If the next character is %, $, ( or %( or $(, then we need to attach
				  // that tag to the variable name, as each of those has a unique name space.
				  char v[255];
				  char sv[255];
				  for(int i=0;i<=strlen(s);i++) v[i]=s[i];
				  for(int i=0;i<=strlen(s);i++) sv[i]=s[i]; sv[2]=0;
				  int svlen=strlen(sv);
				  int old_j=j;
				  while (l[j]=='%'||l[j]=='$'||l[j]=='(') {
				    v[j-i]=l[j]; v[j-i+1]=0;
				    sv[svlen]=l[j]; sv[++svlen]=0;
				    j++;
				  }
				  check_variable(sv,v);
				  j=old_j;
				}
				if (strlen(s)>2) {
					// Candidate for shortening

					// But don't shorten keywords, as that would be BAD!

					if (notKeyword(s)) {
						// fprintf(stderr,"Trimming long variable name '%s'\n",s);
						// fprintf(stderr,"  Source line: '%s'\n",l);
						// Output the two characters we need, and that's all.
						out[len++]=l[i];
						out[len++]=l[i+1];

						i=j;
					}

				}
			}
		}

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
		if (i&&(!quoteMode)&&(!strncmp(":rem",&l[i-1],4))) {
			len--; break;
		}
		if (i&&(!quoteMode)&&(!strncmp(": rem",&l[i-1],5))) {
			len--; break;
		}

		// Remove any # comment
		if (i&&(!quoteMode)&&(!strncmp(" #",&l[i-1],2))) {
			len--; break;
		}
		// Remove any ' comment
		if (i&&(!quoteMode)&&(!strncmp(" \'",&l[i-1],2))) {
			len--; break;
		}

	}
	out[len]=0;
	strcpy(l,out);
	return;
}

int normalise_line(char *line)
{
  // Trim leading spaces from line
  int i;
  for(i=0;line[i]&&((line[i]==' ')||(line[i]=='\t'));i++) continue;
  //  if (i) fprintf(stderr,"Line '%s' has %d leading spaces that need to be removed\n",line,i);
  strcpy(line,&line[i]);
  return 0;
  
}

int main(int argc,char **argv)
{
	int i;
	char line[1024];

	// Pass 1 - find all labels
	fprintf(stderr,"Pass 1: Find and resolve labels\n");
	for(i=1;i<argc;i++) {
		fprintf(stderr,"  Reading %s\n",argv[i]);
		current_file=argv[i];
		FILE *f=fopen(argv[i],"r");
		if (!f) {
			fprintf(stderr,"Could not open '%s'\n",argv[1]);
			perror("fopen");
			exit(-3);
		}
		int fl=1;
		line[0]=0; fgets(line,1024,f);
		while(line[0]) {
		  normalise_line(line);
		  
			if (line[0]=='#') goto skipline1;
			if (line[0]=='\'') goto skipline1;
			if (line[0]=='\t' || (line[0]>='a' && line[0]<='z')) {
				// Line starts with TAB, so allocate line number			  
				line_number++;
				if (0) fprintf(stderr,"%s:%d:Advanced to line number %d due to leading tab or a-z\n",argv[i],fl,
					line_number);
				
			} else if (line[0]>='0' && line[0]<='9') {
				// Line with number
			  int previous_line=line_number;
				line_number=atoi(line);
				if (line_number<previous_line) {
				  fprintf(stderr,"%s:%d:ERROR Line numbers went backwards (from %d to %d)\n",argv[i],fl,
					  previous_line,line_number);
					errors++;
				}
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
				if (0) fprintf(stderr,"%s:%d:Advanced to line number %d due to leading label\n",argv[i],fl,
					line_number);
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
		current_file=argv[i];
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
		  normalise_line(line);
			if (line[0]=='#') goto skipline2;
			if (line[0]=='\'') goto skipline2;
			int outlen=0;
			char lineout[1024];
			int quote_mode=0;
			int comment_mode=0;
			char symbol[1024];
			int symbol_len=0;
			
			if (line[0]>='0' && line[0]<='9') {
				// Line with number
			  int previous_line=line_number;
				if (line_number<previous_line) {
				  fprintf(stderr,"%s:%d:ERROR Line numbers went backwards (from %d to %d)\n",argv[i],fl,
					  previous_line,line_number);
					errors++;
				}
				line_number=atoi(line);
			} else if (line[0]>=' '){
				// Line with any other printable character (TAB/HT is excluded)
				line_number++;
				if (0) fprintf(stderr,"%s:%d:Advanced to line number %d due to leading printable character\n",argv[i],fl,
					line_number);
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
				} else if (line[j]=='\"' || line[j]=='\'') {
					if (symbol_len) {
						// Replace symbol with line number
						if (resolve_symbol(symbol,lineout,&outlen)) {
							fprintf(stderr,"%s:%d:ERROR undefined label '%s'\n",argv[i],fl,symbol);
							errors++;
						}
						symbol_len=0;
					}
					lineout[outlen++]=line[j];
					if(line[j]=='\"') quote_mode^=1;	// toggle quote mode
					if(line[j]=='\'') comment_mode=1;	// still a comment after a second '
				} else if ((
						(!j)
						|| (line[j-1]==' ')
						|| symbol_len
					)
					&& (!quote_mode)
					&& (!comment_mode)
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

			if (strlen(lineout)&&(lineout[0]>=' ')) {
				int j;
				for(j=0;lineout[j];j++) if ((lineout[j]<'0'||lineout[j]>'9')&&(lineout[j]>=' ')) break;
				if (!lineout[j]) {
					fprintf(stderr,"%s:%d:ERROR Line consists only of label or line number\n",argv[i],fl);
					errors++;
				}
			}
			
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

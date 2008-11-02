%{
/* rml2sig: Generates signature for RML files.
   BEDNARSKI Andrzej
   SALDAMLI Levon
   Last update: 13 June, 2003
*/

#include <stdio.h>

static char *file_name;
%}

%x sig
%%
"(*"        {
              register int c;

	      for ( ; ; ) {
		while ( (c = input()) != '*' && c != EOF )
		  ;    /* eat up text of comment */

		if ( c == '*' ) {
		  while ( (c = input()) == '*' )
		    ;
		  if ( c == ')' )
		    break;    /* found the end */
		}
		if ( c == EOF ) {
		  printf( "EOF in comment\n" );
		  exit(1);
		}
	      }
            }


[ \t\n]+"module"[ \t\n]+	ECHO; BEGIN (sig);
\n		/* ignore */
.		/* ignore */

<sig>{
"(*"        {
              register int c;

	      for ( ; ; ) {
		while ( (c = input()) != '*' && c != EOF )
		  ;    /* eat up text of comment */

		if ( c == '*' ) {
		  while ( (c = input()) == '*' )
		    ;
		  if ( c == ')' )
		    break;    /* found the end */
		}
		if ( c == EOF ) {
		  printf( "EOF in comment\n" );
		  exit(1);
		}
	      }
            }
 [ \t\n]+       ECHO;
 [ \t\n]+"end"[ \t\n]+		ECHO; return;
 .		ECHO;
}

%%

int main(int argc, char **argv)
{
  if(argc < 2) {
    return -1;
  } else {
    file_name = argv[1];
    yyin = fopen(file_name, "r");
  }
  yylex();
  return 0;
}

/* Glue to call parser (and thus scanner) from RML */
 
#include <stdio.h>
#include <errno.h>
#include "rml.h"
 

extern void rmlLexerInit(void);

char* yyThisFileName;

/* Provide error reporting function for yacc */
yyerror(char *s)
{
  extern int yylineno;
  fprintf(stderr,"Error: bad syntax\n%s:%d Error:%s\n", yyThisFileName, yylineno, s);
}
 
/* The yacc parser will deposit the syntax tree here */
 
void *absyntree;
 
/* No init for this module */

extern int aarmldbdebug;
 
void ScanParse_5finit(void) 
{
   /* un-comment this if you want to debug the program database parser 
      loading of the .rdb files 
   */
   /* aarmldbdebug = 1; */
}

extern int yydebug;

RML_BEGIN_LABEL(ScanParse__debug_5fon)
{
  yydebug = 1;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ScanParse__debug_5foff)
{
  yydebug = 0;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


/* The glue function */ 
RML_BEGIN_LABEL(ScanParse__scanparse)
{
    void *a0 = rmlA0;
    char* fileStr = RML_STRINGDATA(a0);
    yyThisFileName = (char*)malloc(strlen(fileStr)+1);

    strcpy(yyThisFileName, fileStr);
	/* printf("Parsing: %s\n", fileStr); */

    if( !freopen(fileStr, "r", stdin) ) 
	{
		fprintf(stderr, "freopen %s failed: %s\n",
		RML_STRINGDATA(a0), strerror(errno));
		RML_TAILCALLK(rmlFC);
    }

	/* reinit the damn lexer */
	rmlLexerInit();
	/* parse the damn stuff */
    if( yyparse() != 0 )  
	{
		fprintf(stderr,"Fatal: parsing failed!\n");
		RML_TAILCALLK(rmlFC);
	}
	rmlA0=absyntree;
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL



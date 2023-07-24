/* Glue to call parser (and thus scanner) from RML */

#include <stdio.h>
#include "rml.h"

/* Provide error reporting function for yacc */

yyerror(char *s)
{
  extern int yylineno;
  fprintf(stderr,"Error: bad syntax on line %d.\n",yylineno);
}

/* The yacc parser will deposit the syntax tree here */

void *absyntree;

/* No init for this module */

void ScanParse_5finit(void) {}

/* The glue function */

RML_BEGIN_LABEL(ScanParse__scanparse)
{
  if (yyparse() !=0)
  {
    fprintf(stderr,"Fatal: parsing failed!\n");
    RML_TAILCALLK(rmlFC);
  }

  rmlA0=absyntree;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

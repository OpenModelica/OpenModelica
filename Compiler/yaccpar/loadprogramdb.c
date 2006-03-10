/*

(*
   Copyright 2005, Adrian Pop, adrpo@ida.liu.se and PELAB, Linköping University
*)

*/
/**************************************************
[ loadprogramdb.c ] 
- creation: adrpo 2005-03-01
- last modified:  2005-03-01
***************************************************/

#include <stdio.h>
#include <errno.h>
#include "rml.h"
#include "rml-db-parse.h"

/* Glue to call program database parser (and thus scanner) from RML */
 
/* The yacc parser will deposit the program database absyn tree here */
 
void *yyrmldb_absyntree;
 
/* program database stream */
extern FILE *yyrmldbin; /* the stream we need to parse */
extern int yyrmldberror(char*);
extern int yyrmldbparse(void);
extern int yyrmldbdebug;
extern char* yyrmldbfilename;

/* No init for this module */
void LoadProgramDB_5finit(void) 
{
   yyrmldbdebug = 0;
}

/* The glue function */ 
RML_BEGIN_LABEL(LoadProgramDB__parse)
{
    void *a0 = rmlA0;
    yyrmldbfilename = (char*)malloc(strlen(RML_STRINGDATA(a0))+1);

    strcpy(yyrmldbfilename, RML_STRINGDATA(a0));

    yyrmldbin = fopen(yyrmldbfilename, "r"); 
    if(yyrmldbin==NULL) 
    {
		fprintf(stderr, "fopen %s failed: %s\n",
		RML_STRINGDATA(a0), strerror(errno));
		RML_TAILCALLK(rmlFC);
    }
    if( yyrmldbparse() != 0 )  
	{
		fprintf(stderr,"Fatal: parsing failed!\n");
		RML_TAILCALLK(rmlFC);
	}
	yyrmldbrestart();
	rmlA0=yyrmldb_absyntree;
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(LoadProgramDB__debug_5fon)
{
  yyrmldbdebug = 1;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(LoadProgramDB__debug_5foff)
{
  yyrmldbdebug = 0;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


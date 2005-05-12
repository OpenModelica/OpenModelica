#ifndef _DEFS_H
#define _DEFS_H

#define LEXER_COMMENT_MAXLENGTH  2000
#define LEXER_IDENT_MAXLENGTH    31

extern char yyCommentBuffer[LEXER_COMMENT_MAXLENGTH+100];
extern int  yyCommentLength;

typedef void *rml_t;
extern rml_t *absyntree;

struct Token
{
#ifdef LEXER_SAVE_TOKENCODE
  int   code;
#endif
  union
  {
    long    number;
    double  realnumber;
    char   *ident;
    char   *string;
  } u;
#ifdef LEXER_TOKEN_POSITION
  char *file;
  int   firstline, firstcol; /* start position of this token */
  int   lastline, lastcol;   /* end position of this token */
#endif
};

#endif

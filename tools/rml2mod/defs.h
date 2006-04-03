#ifndef _DEFS_H
#define _DEFS_H

#define LEXER_TOKEN_POSITION

#define LEXER_COMMENT_MAXLENGTH  2000
#define LEXER_STRING_MAXLENGTH   2000
#define LEXER_IDENT_MAXLENGTH    100
#define MAX_COMMENTINFO 6500

extern char yyCommentBuffer[LEXER_COMMENT_MAXLENGTH+100];
extern int  yyCommentLength;

typedef void* rml_t;
#define YYSTYPE rml_t
extern rml_t absyntree;

//added
struct CommentInfo
{
  int   bound;
  int   firstline, firstcol; /* start position of this comment */
  int   lastline, lastcol;   /* end position of this comment */
  char buffer[LEXER_COMMENT_MAXLENGTH+100];
};

extern struct CommentInfo commentInfo[MAX_COMMENTINFO];
//end added

struct Token
{
#ifdef LEXER_SAVE_TOKENCODE
  int   code;
#endif
  union
  {
    long   number;
    double realnumber;
    char   *ident;
    char   *string;
  } u;
  #ifdef LEXER_TOKEN_POSITION 
  char  *file;
  int   firstline, firstcol; /* start position of this token */
  int   lastline, lastcol;   /* end position of this token */
  #endif 
};

#endif

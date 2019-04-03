/* lexer.c */
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include "parsutil.h"
#include "parser.h"
#include "lexerPetrol.h"

#ifdef RML
#include "yacclib.h"
#else
#include "meta/meta_modelica.h"
#endif

int yylineno = 1;

void lexerror(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "Line %d: ", yylineno);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    exit(1);
}

const char *lex_token_to_string(int token)
{
    struct my_yytoktype {
  const char *t_name; int t_val;
    };
    static const struct my_yytoktype my_yytoks[] = {
  { "T_AMPER", T_AMPER },
  { "T_AND", T_AND },
  { "T_ARRAY", T_ARRAY },
  { "T_ASSIGN", T_ASSIGN },
  { "T_BEGIN", T_BEGIN },
  { "T_CARET", T_CARET },
  { "T_CAST", T_CAST },
  { "T_COLON", T_COLON },
  { "T_COMMA", T_COMMA },
  { "T_CONST", T_CONST },
  { "T_DO", T_DO },
  { "T_DOT", T_DOT },
  { "T_ELSE", T_ELSE },
  { "T_ELSIF", T_ELSIF },
  { "T_END", T_END },
  { "T_EQ", T_EQ },
  { "T_EXTERN", T_EXTERN },
  { "T_FUNCTION", T_FUNCTION },
  { "T_GE", T_GE },
  { "T_GT", T_GT },
  { "T_ICON", T_ICON },
  { "T_IDENT", T_IDENT },
  { "T_IDIV", T_IDIV },
  { "T_IF", T_IF },
  { "T_IMOD", T_IMOD },
  { "T_LBRACK", T_LBRACK },
  { "T_LE", T_LE },
  { "T_LPAREN", T_LPAREN },
  { "T_LT", T_LT },
  { "T_MINUS", T_MINUS },
  { "T_MUL", T_MUL },
  { "T_NE", T_NE },
  { "T_NOT", T_NOT },
  { "T_OF", T_OF },
  { "T_OR", T_OR },
  { "T_PLUS", T_PLUS },
  { "T_PROCEDURE", T_PROCEDURE },
  { "T_PROGRAM", T_PROGRAM },
  { "T_RBRACK", T_RBRACK },
  { "T_RCON", T_RCON },
  { "T_RDIV", T_RDIV },
  { "T_RECORD", T_RECORD },
  { "T_RETURN", T_RETURN },
  { "T_RPAREN", T_RPAREN },
  { "T_SEMI", T_SEMI },
  { "T_THEN", T_THEN },
  { "T_TYPE", T_TYPE },
  { "T_VAR", T_VAR },
  { "T_WHILE", T_WHILE },
  { 0, -1 }  /* ends search */
    };
    const struct my_yytoktype *p;
    int token2;

    if( token == 0 )
  return "end-of-file";
    if( token < 0 )
  return "-none-";
    for(p = my_yytoks; (token2 = p->t_val) >= 0; ++p)
  if( token2 == token )
      return p->t_name;
    {
  static char buf[32];
  sprintf(buf, "(unknown %d)", token);
  return buf;
    }
}

#ifdef  LEXDEBUG
int lexdebug;

static int lex_log_token(int token)
{
    if( lexdebug ) {
  fprintf(stderr, "Lexer: line %d, token %s",
    yylineno, lex_token_to_string(token));
  if( token == T_ICON ) {
      fprintf(stderr, ", value ");
      print_icon(stderr, yylval.voidp);
  } else if( token == T_RCON ) {
      fprintf(stderr, ", value ");
    print_rcon(stderr, yylval.voidp);
  } else if( token == T_IDENT ) {
      fprintf(stderr, ", value \"");
      print_scon(stderr, yylval.voidp);
      fputc('"', stderr);
  }
  fputc('\n', stderr);
    }
    return token;
}
#else
#define lex_log_token(TOKEN) (TOKEN)
#endif

static const struct {
    char *name;  int token;
} kwds[] = {
  {  "and",    T_AND    },
  {  "array",  T_ARRAY    },
  {  "begin",  T_BEGIN    },
  {  "cast",    T_CAST    },
  {  "const",  T_CONST    },
  {  "div",    T_IDIV    },
  {  "do",    T_DO    },
  {  "else",    T_ELSE    },
  {  "elsif",  T_ELSIF    },
  {  "end",    T_END    },
  {  "extern",  T_EXTERN  },
  {  "function",  T_FUNCTION  },
  {  "if",    T_IF    },
  {  "mod",    T_IMOD    },
  {  "not",    T_NOT    },
  {  "of",    T_OF    },
  {  "or",    T_OR    },
  {  "procedure",  T_PROCEDURE  },
  {  "program",  T_PROGRAM  },
  {  "record",  T_RECORD  },
  {  "return",  T_RETURN  },
  {  "then",    T_THEN    },
  {  "type",    T_TYPE    },
  {  "var",    T_VAR    },
  {  "while",  T_WHILE    },
};

static void strlower(char *s)
{
    int c;
    while( (c = *s) != '\0' )
  *s++ = tolower(c);
}

static int lex_kwd_or_ident(char *s)
{
    int low = 0;
    int high = (sizeof kwds) / (sizeof kwds[0]) - 1;

    strlower(s);
    while( low <= high ) {
  int mid = (low + high) / 2;
  int cmp = strcmp(kwds[mid].name, s);
  if( cmp == 0 )
      return kwds[mid].token;
  else if( cmp < 0 )
      low = mid + 1;
  else
      high = mid - 1;
    }
    yylval.voidp = mmc_mk_scon(s);
    return T_IDENT;
}

static int lex_alpha_ident(int ch)
{
    char s[128];
    int i = 0;

    do {
  s[i++] = ch;
  ch = getchar();
    } while( isalnum(ch) || ch == '_' );
    s[i] = '\0';
    ungetc(ch, stdin);
    return lex_kwd_or_ident(s);
}

static int lex_number(int ch)
{
    char s[128];
    int i = 0, isreal = 0;

    for(; isdigit(ch); ch = getchar())
  s[i++] = ch;
    if( ch == '.' ) {
  isreal = 1;
  do {
      s[i++] = ch;
      ch = getchar();
  } while( isdigit(ch) );
    }
    if( ch == 'e' || ch == 'E' ) {
  isreal = 1;
  s[i++] = ch;
  ch = getchar();
  if( ch == '-' ) {
      s[i++] = ch;
      ch = getchar();
  } else if( ch == '+' ) {
      s[i++] = ch;
      ch = getchar();
  }
  if( !isdigit(ch) )
      lexerror("Bad exponent: expected digit, got %03o", ch);
  do {
      s[i++] = ch;
      ch = getchar();
  } while( isdigit(ch) );
    }
    s[i] = '\0';
    ungetc(ch, stdin);
    if( isreal ) {
  yylval.voidp = mmc_mk_rcon(atof(s));
  return T_RCON;
    } else {
  yylval.voidp = mmc_mk_icon(atoi(s));
  return T_ICON;
    }
}

int yylex(void)
{
    int ch;

    for(;;) {
  ch = getchar();
  switch( ch ) {
    case EOF:
      return 0;
    case '\n':
      ++yylineno;
      continue;
    case '\t': case ' ':
      continue;
    case '{':
      do {
    ch = getchar();
      } while( ch != '}' && ch != EOF );
      continue;
    case ':':  /* ASSIGN or COLON */
      ch = getchar();
      switch( ch ) {
        case '=':
    return lex_log_token(T_ASSIGN);
        default:
    ungetc(ch, stdin);
    return lex_log_token(T_COLON);
      }
    case ',':
      return lex_log_token(T_COMMA);
    case '.':  /* RCON or DOT */
      ch = getchar();
      ungetc(ch, stdin);
      if( isdigit(ch) )
    return lex_log_token(lex_number('.'));
      else
    return lex_log_token(T_DOT);
    case '[':
      return lex_log_token(T_LBRACK);
    case ']':
      return lex_log_token(T_RBRACK);
    case '(':
      return lex_log_token(T_LPAREN);
    case ')':
      return lex_log_token(T_RPAREN);
    case '<':  /* NE, LE, or LT */
      ch = getchar();
      switch( ch ) {
        case '>':
    return lex_log_token(T_NE);
        case '=':
    return lex_log_token(T_LE);
        default:
    ungetc(ch, stdin);
    return lex_log_token(T_LT);
      }
    case '=':
      return lex_log_token(T_EQ);
    case '>':  /* GE or GT */
      ch = getchar();
      switch( ch ) {
        case '=':
    return lex_log_token(T_GE);
        default:
    ungetc(ch, stdin);
    return lex_log_token(T_GT);
      }
    case '-':
      return lex_log_token(T_MINUS);
    case '*':
      return lex_log_token(T_MUL);
    case '+':
      return lex_log_token(T_PLUS);
    case '/':
      return lex_log_token(T_RDIV);
    case ';':
      return lex_log_token(T_SEMI);
    case '&':
      return lex_log_token(T_AMPER);
    case '^':
      return lex_log_token(T_CARET);
    default:
      if( isalpha(ch) || ch == '_' )
    return lex_log_token(lex_alpha_ident(ch));
      else if( isdigit(ch) )
    return lex_log_token(lex_number(ch));
      else
    lexerror("Illegal character %03o", ch);
  }
    }
}

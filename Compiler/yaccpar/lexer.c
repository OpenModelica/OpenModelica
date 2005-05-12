#include <stdio.h>
#include <string.h>
#include "parser.h"
#include "defs.h"

char yyCommentBuffer[LEXER_COMMENT_MAXLENGTH+100];
int  yyCommentLength = 0;
int  yyRealNumber;

extern rml_t *yylval;

int yylineno = 1, columnno = 0;

static struct keyword
{
  char *name;
  int   code;
}
keywords[] =
{
#if 1
  /* Generic keywords (both RML and Modelica) */
  { "and",          KW_AND },
  { "end",          KW_END },
  { "not",          KW_NOT },
  { "type",         KW_TYPE },
#endif

#if 1
  /* RML keywords */
  { "abstype",      KW_ABSTYPE },
  { "as",           KW_AS },
  { "axiom",        KW_AXIOM },
  { "datatype",     KW_DATATYPE },
/*
  { "exists",       KW_EXISTS },
*/
  { "let",          KW_LET },
  { "module",       KW_MODULE },
  { "of",           KW_OF },
  { "relation",     KW_RELATION },
  { "rule",         KW_RULE },
  { "val",          KW_VAL },
  { "with",         KW_WITH },
  { "withtype",     KW_WITHTYPE },
  { "_",            '_' },
#endif

#if 1
  /* Modelica keywords */
  { "algorithm",    KW_ALGORITHM },
  { "annotation",   KW_ANNOTATION },
  { "block",        KW_BLOCK },
  { "class",        KW_CLASS },
  { "code",         KW_CODE },
  { "connect",      KW_CONNECT },
  { "connector",    KW_CONNECTOR },
  { "const",        KW_CONST },
  { "discrete",     KW_DISCRETE },
  { "else",         KW_ELSE },
  { "elseif",       KW_ELSEIF },
  { "elsewhen",     KW_ELSEWHEN },
  { "encapsulated", KW_ENCAPSULATED },
  { "enumeration",  KW_ENUMERATION },
  { "equation",     KW_EQUATION },
  { "extends",      KW_EXTENDS },
  { "external",     KW_EXTERNAL },
  { "flow",         KW_FLOW },
  { "for",          KW_FOR },
  { "function",     KW_FUNCTION },
  { "if",           KW_IF },
  { "import",       KW_IMPORT },
  { "in",           KW_IN },
  { "initial",      KW_INITIAL },
  { "inner",        KW_INNER },
  { "input",        KW_INPUT },
  { "loop",         KW_LOOP },
  { "model",        KW_MODEL },
  { "or",           KW_OR },
  { "outer",        KW_OUTER },
  { "output",       KW_OUTPUT },
  { "overload",     KW_OVERLOAD },
  { "package",      KW_PACKAGE },
  { "parameter",    KW_PARAMETER },
  { "partial",      KW_PARTIAL },
  { "protected",    KW_PROTECTED },
  { "public",       KW_PUBLIC },
  { "record",       KW_RECORD },
  { "redeclare",    KW_REDECLARE },
  { "replaceable",  KW_REPLACEABLE },
  { "type",         KW_TYPE },
  { "when",         KW_WHEN },
  { "while",        KW_WHILE },
  { "within",       KW_WITHIN },
#endif

  { 0, 0 }
};

static int back_ch = 0;
static int last_ch = 0;

static int keywords_sorted = 0;

static int cmpkw(struct keyword *k1, struct keyword *k2)
{
  return strcmp(k1->name, k2->name);
}

static int init_sort_keywords()
{
  int n;

  for(n = 0; keywords[n].name; ++n);

  qsort(keywords, n, sizeof(struct keyword), cmpkw);
}

static int get()
{
  if (back_ch)
    { back_ch = 0; return last_ch;}

  last_ch = fgetc(stdin);
  if (last_ch == '\n')
    { ++yylineno; columnno = 0;}
  else if (last_ch == '\t')
    { while (++columnno % 8 != 0);}
  else
    ++columnno;

  return last_ch;
}

static void unget()
{
  back_ch = 1;
}

static int esc_char(int in_char_literal)
{
  int c = get();
  int v, i;

  switch (c)
  {
    case 'b':
      return '\b';
    case 'e':
      return 033;
    case 'f':
      return '\f';
    case 'n':
      return '\n';
    case 't':
      return '\t';
    default:
      if (c >= '0' && c <= '7')
      {
        for(v = i = 0; i < 3 && c >= '0' && c <= '7'; c = get())
          v = v*8 + c-'0';
        unget();
        return v;
      }
      return c;
  }
}

static int yylex0()
{
  int i, c, d, token;

  struct Token *val;
 
  static char ident[100];
  static char string[4100];

  val = (struct Token *) malloc(sizeof(struct Token));
  if (!val)
    yyerror("!out of memory");
  memset(val, 0, sizeof(struct Token));

  yylval = (void *) val;

  c = get();

#ifdef LEXER_TOKEN_POSITION
  val->file      = yyThisFileName;
  val->firstline = yylineno;
  val->firstcol  = columnno;
  val->lastline  = yylineno;
  val->lastcol   = columnno;
#endif

  switch (c)
  {
    case '\n': case ' ': case '\t':
      return yylex0();

    case EOF: case 0:
      return EOF;

    case '=': /* '=' or '=>' */
      d = get();
      if (d == '>')
        { token = YIELDS; break;}
      unget();
      return '=';

    case ':': /* ':' or '::' */
      d = get();
      if (d == ':')
        { token = YIELDS; break;}
      unget();
      return ':';

    case '(': /* '(' or '(*...comment...*)' */
      d = get();
      if (d == '*')
      {
        if (yyCommentLength > 0 && yyCommentLength < LEXER_COMMENT_MAXLENGTH)
        {
          yyCommentBuffer[yyCommentLength++] = '\n';
          yyCommentBuffer[yyCommentLength++] = '\n';
        }

        while (d != EOF)
        {
          d = get();
          if (d != '*')
          {
            if (yyCommentLength < LEXER_COMMENT_MAXLENGTH)
              yyCommentBuffer[yyCommentLength++] = d;
            continue;
          }
          d = get();
          if (d == ')')
            break;
          if (yyCommentLength < LEXER_COMMENT_MAXLENGTH)
            yyCommentBuffer[yyCommentLength++] = '*';
          unget();
        }
        return yylex0(); /* comment: skip and return next token */
      }
      unget();
      return '(';

    case '-': /* '-' or horizontal bar */
      d = get();
      if (d == '-')
      {
        while (d == '-')
          d = get();
        unget();
        token = DASHES;
        break;
      }
      unget();
      return '-';

    case '"': /* string constant */
      i = 0;
      while (1)
      {
        c = get();
        if (c == '"')
          break;
        if (c == '\\')
          c = esc_char(0);
        if (i < 4096)
          string[i++] = c;
        else
          yyerror("string buffer overflow");
      }
      string[i] = 0;
      token = STRING_LITERAL;
      val->u.string = strdup(string);
      break;

    case '#':
      c = get();
      if (c != '"')
        yyerror("invalid character constant");
      c = get();
      if (c == '\\')
        c = esc_char(1);
      d = get();
      if (d != '"')
        yyerror("invalid character constant");
      val->u.number = c;
      token = CHAR_LITERAL;
      break;

    case ',': case '*': case '|': case '&': case ')': case '.':
    case '[': case ']':
      /* plain separator/operator tokens */
      return c;

    default:
      if (isalpha(c) || c == '\'' || c == '_')
      {
        i = 0;
        do
        {
          if (i < 50)
          {
            ident[i++] = c;
#ifdef LEXER_TOKEN_POSITION
            val->lastline = yylineno;
            val->lastcol  = columnno;
#endif
          }
          c = get();
        }
        while (isalnum(c) || c == '\'' || c == '_');

        unget();
        ident[i] = 0;

      	if (!keywords_sorted)
      	{
      	  init_sort_keywords();
      	  keywords_sorted = 1;
      	}

        for(i = 0; keywords[i].name; ++i)
          if (!strcmp(ident, keywords[i].name))
            return keywords[i].code;

        val->u.ident = strdup(ident);
        return ident[0] == '\'' ? TYVARIDENT : IDENT;
      }
      else if (isdigit(c))
      {
        int is_float = 0;

        i = 0;

        for(val->u.number = 0; isdigit(c); c = get())
        {
          val->u.number = val->u.number*10 + c-'0';
          if (i < LEXER_IDENT_MAXLENGTH)
             ident[i++] = c;
        };
        if (c == '.')
        {
          do
          {
            if (i < LEXER_IDENT_MAXLENGTH)
              ident[i++] = c;
            c = get();
          } while (isdigit(c));
          is_float = 1;
        };
        if (c == 'e')
        {
          do
          {
            if (i < LEXER_IDENT_MAXLENGTH)
              ident[i++] = c;
            c = get();
          } while (isdigit(c) || c == '+' || c == '-');
          is_float = 1;
        };

        unget();

        if (is_float)
        {
          ident[i] = 0;
          if (sscanf(ident, "%lf", &(val->u.realnumber)) == 1)
          {
            token = REAL_LITERAL;
            break;
          }
          yyerror("invalid real number");
        }

        token = INTEGER_LITERAL;
        break;
      }
      else
        yyerror("invalid input character");
  }

#ifdef LEXER_TOKEN_POSITION
  val->lastline = yylineno;
  val->lastcol  = columnno;
#endif

  return token;
}


int yylex()
{
  int token = yylex0();
  int i;

#ifdef LEXER_SAVE_TOKENCODE
  ((struct Token *)yylval)->code = token; 
#endif

  yyCommentBuffer[yyCommentLength] = 0; /* ensure NUL termination */

#ifdef DEBUG
  /* for debugging */
  switch (token)
  {
    case IDENT:
      fprintf(stderr, "[IDENT %s]", ((struct Token *)yylval)->ident);
      return token;

    case T_YIELDS:
      fprintf(stderr, "[=>]");
      return token;

    case T_HBAR:
      fprintf(stderr, "[---]");
      return token;

    default:
     if (token > 0 && token < 256)
     {
       fprintf(stderr, "['%c']", token);
       return token;
     }       
     for(i = 0; keywords[i].name; ++i)
       if (keywords[i].code == token)
       {
         fprintf(stderr, "[KW %s]", keywords[i].name);
         return token;
       }
     fprintf(stderr, "[TOKEN %d]", token);
  }
#endif

  return token;
}

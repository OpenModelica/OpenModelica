
#include <stdio.h>
#include "stdpccts.h"

int zzcr_attr(Attrib *attr, int type, char *text)
{
  int l;
  attr->type = type;
  switch (type)
  {
  case UNSIGNED_INTEGER:
    attr->u.ival = atoi(text); break;
  case UNSIGNED_REAL:
    attr->u.realval = atof(text); break;
  case IDENT:
    attr->u.stringval = strdup(text);
    break;
  case STRING:
    l = strlen(text);
    attr->u.stringval = (char *)malloc(l-1);
    memcpy(attr->u.stringval, text+1, l-2);
    attr->u.stringval[l-2] = 0;
    break;
  default:
    /*    fprintf("No data in attrib is set."); break; */
    break;
  }
}

void zzd_attr(Attrib *attr)
{
  switch(attr->type)
  {
  case IDENT:
  case STRING:
    /* MEMORY LEAK! */
/*     free(attr->u.stringval); */
    break;
  }
}

Attrib *copy_attr(Attrib *attr)
{
  int l;
  Attrib *a = (Attrib*)malloc(sizeof(Attrib));
  if(!a)
  {
    fprintf(stderr, "Out of memory!\n");
    abort();
  }
  memcpy(a, attr, sizeof(Attrib));
  switch(attr->type)
  {
  case IDENT:
  case STRING:
    a->u.stringval = strdup(attr->u.stringval);
    break;
  }
  return a;
}

#define tokprinter(t) case t: fprintf(f, #t); break

void print_attr(Attrib *attr, FILE *f)
{
  switch (attr->type)
  {
  case UNSIGNED_INTEGER:
    fprintf(f, "%d", attr->u.ival); break;
  case UNSIGNED_REAL:
    fprintf(f, "%.2f", attr->u.realval); break;
  case IDENT:
    fprintf(f, "'%s'", attr->u.stringval); break;
  case STRING:
    fprintf(f, "\"%s\"", attr->u.stringval); break;

  tokprinter(IMPORT);		/* 3 */
  tokprinter(CLASS_);		/* 4 */
  tokprinter(MODEL);		/* 6 */
  tokprinter(FUNCTION);		/* 7 */
  tokprinter(PACKAGE);		/* 8 */
  tokprinter(RECORD);		/* 9 */
  tokprinter(BLOCK);		/* 10 */
  tokprinter(CONNECTOR);	/* 11 */
  tokprinter(TYPE);		/* 12 */
  tokprinter(EXTENDS);		/* 16 */
  tokprinter(PARAMETER);	/* 17 */
  tokprinter(CONSTANT);		/* 18 */
  tokprinter(PARTIAL);		/* 20 */
  tokprinter(INPUT);		/* 22 */
  tokprinter(OUTPUT);		/* 23 */
  tokprinter(FLOW);		/* 24 */
  tokprinter(EQUATION);		/* 25 */
  tokprinter(ALGORITHM);	/* 27 */
  tokprinter(FINAL);		/* 28 */
  tokprinter(PUBLIC);		/* 29 */
  tokprinter(PROTECTED);	/* 30 */
  tokprinter(LPAR);		/* 31 */
  tokprinter(RPAR);		/* 32 */
  tokprinter(LBRACK);		/* 33 */
  tokprinter(RBRACK);		/* 34 */
  tokprinter(IF);		/* 36 */
  tokprinter(THEN);		/* 37 */
  tokprinter(ELSE);		/* 38 */
  tokprinter(ELSEIF);		/* 39 */
  tokprinter(WHEN);
  tokprinter(DO);
  tokprinter(AND);		/* 40 */
  tokprinter(NOT);		/* 42 */
  tokprinter(CONNECT);
  tokprinter(IN);
  tokprinter(FOR);
  tokprinter(WHILE);
  tokprinter(EQUALS);		/* 49 */
  tokprinter(ASSIGN);		/* 50 */
  tokprinter(PLUS);		/* 51 */
  tokprinter(MINUS);		/* 52 */
  tokprinter(MULT);		/* 53 */
  tokprinter(DIV);		/* 54 */
  tokprinter(DOT);		/* 55 */
  tokprinter(LESS);
  tokprinter(LESSEQ);		/* 57 */
  tokprinter(GREATER);		/* 59 */
  tokprinter(GREATEREQ);	/* 60 */
  tokprinter(COMPONENTS);	/* 66 */
  tokprinter(TYPE_PREFIX);	/* 67 */
  tokprinter(FUNCALL);		/* 68 */
  tokprinter(ELEMENT);		/* 70 */
  tokprinter(MODIFICATION);	/* 71 */
  tokprinter(SUBSCRIPT);	/* 72 */
  tokprinter(ROW);
  tokprinter(COLUMN);

  case zzEOF_TOKEN:
  default:
    fprintf(f, "TOKEN_%d", attr->type); break;
  }
}


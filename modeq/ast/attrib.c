
#include <stdio.h>
#include "stdpccts.h"

int zzcr_attr(Attrib *attr, int type, char *text)
{
  attr->type = type;
  switch (type)
  {
  case UNSIGNED_NUMBER:
    attr->u.floatval = atof(text); break;
  case IDENT:
  case STRING:
    attr->u.stringval = strdup(text); break;
  default:
    break;
  }
}

void zzd_attr(Attrib *attr)
{
  switch(attr->type)
  {
  case IDENT:
  case STRING:
    free(attr->u.stringval); break;
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
    a->u.stringval = strdup(attr->u.stringval); break;
  case STRING:
    l = strlen(attr->u.stringval);
    a->u.stringval = (char *)malloc(l-1);
    memcpy(a->u.stringval, attr->u.stringval+1, l-2);
    a->u.stringval[l-2] = 0;
    break;
  }
  return a;
}

#define tokprinter(t) case t: fprintf(f, #t); break

void print_attr(Attrib *attr, FILE *f)
{
  switch (attr->type)
  {
  case UNSIGNED_NUMBER:
    fprintf(f, "%.2f", attr->u.floatval); break;
  case IDENT:
    fprintf(f, "%s", attr->u.stringval); break;
  case STRING:
    fprintf(f, "\"%s\"", attr->u.stringval); break;

  tokprinter(IMPORT);
  tokprinter(CLASS_);
  tokprinter(BOUNDARY);
  tokprinter(MODEL);
  tokprinter(PARTIAL);
  tokprinter(INPUT);
  tokprinter(OUTPUT);
  tokprinter(FLOW);
  tokprinter(PARAMETER);
  tokprinter(CONSTANT);
  tokprinter(EQUATION);
  tokprinter(LPAR);
  tokprinter(RPAR);
  tokprinter(COMPONENTS);
  tokprinter(TYPE_PREFIX);
  tokprinter(FUNCALL);
  tokprinter(EQUALS);

  case zzEOF_TOKEN:
  default:
    fprintf(f, "TOKEN_%d", attr->type); break;
  }
}


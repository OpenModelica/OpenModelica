
#ifndef _MODAST_H_

#define _MODAST_H_

/* #include "ASTBase.h" */
/* #include "tokens.h" */
/* #include "AToken.h" */
/* #include "ATokPtr.h" */
#include "parser.h"


/* ostream &operator<<(ostream &, AST *); */

typedef enum {
  EP_FINAL,
  EP_PARAMETER,
  EP_CONSTANT,
  EP_COMPLEX
} PropertyBits;

typedef enum {
  OP_NONE,
  OP_PREFIX,			/* -argument           */
  OP_POSTFIX,			/* argument	       */
  OP_INFIX,			/* term + term	       */
  OP_BALANCED,			/* { argument }	       */
  OP_FUNCTION,			/* function(arguments) */
  OP_ARRAYDECL,			/* [[ (tokens)... ]]   */
  OP_ARRAYRANGE			/* ident[[tokens...]]  */
} opType;

typedef enum {
  NO_SPECIAL,
  ELEMENT_MOD,
  ELEMENT_REDECLARE,
  IMPORT_STATEMENT,
  CLASSDEF,
  ET_NONE,
  ET_INHERIT,
  ET_COMPONENT,
  ET_EQUATION,
  ET_ALGORITHM,
  ET_ANNOTATION,
  ET_EXTCLASS,
  ET_FUNCTION,
  ET_TYPE
} NodeType;

#endif

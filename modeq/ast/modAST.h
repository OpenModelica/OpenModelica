
#ifndef _MODAST_H_

#define _MODAST_H_

#include "ASTBase.h"
#include "tokens.h"
#include "AToken.h"
#include "ATokPtr.h"
#include "parser.h"


ostream &operator<<(ostream &, AST *);

typedef enum {
  EP_FINAL,
  EP_PARAMETER,
  EP_CONSTANT,
  EP_COMPLEX
} PropertyBits;

typedef enum {
  OP_NONE,
  OP_PREFIX,			// -argument
  OP_POSTFIX,			// argument
  OP_INFIX,			// term + term
  OP_BALANCED,			// { argument }
  OP_FUNCTION,			// function(arguments)
  OP_ARRAYDECL,			// [[ (tokens)... ]]
  OP_ARRAYRANGE			// ident[[tokens...]]
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

typedef enum {
  CLASS_VIRTUAL = (1<<0),
  ELEMENT_PROTECTED = (1<<1),
  CLASS_PARTIAL = (1<<2),
  IS_FINAL = (1<<3),
  FUNCTION_EXTERNAL = (1<<4)
} NodeProperties;

class NodeInfo {
  // A collection of extra information that can be attached
  // to a node in the AST to help the code generator.
public:
  NodeType type;
  unsigned long properties;
};


class AST : public ASTBase {

  char * expr_trans;
  opType optype;
  char opbalancer;

public:
  NodeInfo              ni;
  char *classType;

  /* constructor */	AST();
  /* constructor */	AST(ANTLRTokenPtr t);
  /* constructor */     AST(ANTLRTokenType);
  //  /* constructor */     AST(ANTLRTokenType,opType);
  /* constructor */     AST(ANTLRTokenType,char *,opType,char);
  /* constructor */     AST(ANTLRTokenType,char *);
  /* constructor */     AST(ANTLRTokenType,char *,opType);

  /* destructor */ virtual	~AST();
  /* copy constructor */	AST(const AST &);	   // new copy of token
  AST &			operator = (const AST &);  // new copy of token
//  virtual void		dumpNode(const char * s=0);
  virtual void		preorder_action();
  virtual void preorder_before_action() { printf("["); }
  virtual void preorder_after_action() { printf("]"); }
  
  ANTLRTokenPtr         pToken;
  
  AST *			ASTdown() {return (AST *)_down;};
  AST *			ASTright() {return (AST *)_right;};
  void setTranslation(char *t) { expr_trans=t; }
  char *getTranslation() { return expr_trans; }
  void dumpTree();
  void setOpType(opType);
  void setOpType(opType,char);
  opType getOpType();
  char getBalancer();
};

char *replaceUnderscore(char *s);

#endif

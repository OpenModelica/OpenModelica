
#include "ast/stdpccts.h"
#include "rml.h"
#include "dae.h"
#include "exp.h"
#include "yacclib.h"
#include <errno.h>

/* Also see rml-1.3.6/examples/etc/ccall.c */

void Parser_5finit(void)
{
}

void print_token(AST *ast)
{
  print_attr(ast->attr, stderr);

  if(ast->rml)
    fprintf(stderr,"*");

  if(zzchild(ast))
    fprintf(stderr,"(");
  else if(zzsibling(ast))
    fprintf(stderr,",");
}

void print_lpar(AST *ast)
{
  /* fprintf(stderr, "·"); */
}

void print_rpar(AST *ast)
{
  if(zzsibling(ast))
    fprintf(stderr, "),");
  else
    fprintf(stderr, ")");
}

void *sibling_list(AST *ast)
{
  if(ast == NULL)
  {
/*     printf("sibling_list -> []\n"); */
    return mk_nil();
  }
  else
  {
/*     printf("sibling_list -> x :: _\n"); */
    return mk_cons(ast->rml,sibling_list(ast->right));
  }
}

int parse_failed;

RML_BEGIN_LABEL(Parser__parse)
{
  AST *root = NULL;
  void *a0 = rmlA0;
  if( !freopen(RML_STRINGDATA(a0), "r", stdin) ) {
    fprintf(stderr, "freopen %s failed: %s\n",
	    RML_STRINGDATA(a0), strerror(errno));
    RML_TAILCALLK(rmlFC);
  } else {
    int fail;
    parse_failed = 0;
    ANTLR(model_definition(&root/*, &fail*/), stdin);
    printf("fail = %d\n", fail);
    if(parse_failed) {
      fprintf(stderr, "parse erro\n");
      RML_TAILCALLK(rmlFC);
    } else {
      /* fprintf(stderr, "root = %p\n", root); */
      /* fprintf(stderr, "\n"); */
      /* zzpre_ast(root, &print_token, &print_lpar, &print_rpar); */
      fprintf(stderr, "\n\n");
      
      /* if( !root )
       *   RML_TAILCALLK(rmlFC); */
      
      rmlA0 = sibling_list(root);
      
      RML_TAILCALLK(rmlSC);
    }
  }
}
RML_END_LABEL


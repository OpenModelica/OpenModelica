
#include "ast/stdpccts.h"
#include "rml.h"
#include "dae.h"
#include "exp.h"
#include "class.h"
#include <errno.h>

/* Also see rml-1.3.6/examples/etc/ccall.c */

void Parser_5finit(void)
{
}

void print_token(AST *ast)
{
#ifdef STRING_AST
  fprintf(stderr, "%s", ast->t);
#else
  print_attr(ast->attr, stderr);
#endif

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

RML_BEGIN_LABEL(Parser__parse)
{
  AST *root;
  void *a0, *a0hdr;
  RML_INSPECTBOX(a0, a0hdr, rmlA0);
  if( a0hdr == RML_IMMEDIATE(RML_UNBOUNDHDR) )
    RML_TAILCALLK(rmlFC);
  if( !freopen(RML_STRINGDATA(a0), "r", stdin) ) {
    fprintf(stderr, "freopen %s failed: %s\n",
	    RML_STRINGDATA(a0), strerror(errno));
    RML_TAILCALLK(rmlFC);
  }
  
  ANTLR(model_specification(&root), stdin);	/* start first rule */
  fprintf(stderr, "root = %p\n", root);
  fprintf(stderr, "\n");
  zzpre_ast(root, &print_token, &print_lpar, &print_rpar);
  fprintf(stderr, "\n\n");
  
  rmlA0 = mk_cons(Class__CLASS(Class__CL_5fMODEL,mk_nil()), mk_nil());
  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


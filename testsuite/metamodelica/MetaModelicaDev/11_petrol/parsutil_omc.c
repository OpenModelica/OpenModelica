/* parsutil.c */
#include <stdio.h>
#include "meta/meta_modelica.h"
#include "parsutil.h"

/* Exp */
extern struct record_description Absyn_Exp_INT__desc;
extern struct record_description Absyn_Exp_REAL__desc;
extern struct record_description Absyn_Exp_IDENT__desc;
extern struct record_description Absyn_Exp_CAST__desc;
extern struct record_description Absyn_Exp_FIELD__desc;
extern struct record_description Absyn_Exp_UNARY__desc;
extern struct record_description Absyn_Exp_BINARY__desc;
extern struct record_description Absyn_Exp_RELATION__desc;
extern struct record_description Absyn_Exp_EQUALITY__desc;
extern struct record_description Absyn_Exp_FCALL__desc;

/* RelOp */
extern struct record_description Absyn_RelOp_LT__desc;
extern struct record_description Absyn_RelOp_LE__desc;

/* Constant */
extern struct record_description Absyn_Constant_INTcon__desc;
extern struct record_description Absyn_Constant_REALcon__desc;
extern struct record_description Absyn_Constant_IDENTcon__desc;

/* ConBnd */
extern struct record_description Absyn_ConBnd_CONBND__desc;

/* Ty */
extern struct record_description Absyn_Ty_NAME__desc;
extern struct record_description Absyn_Ty_PTR__desc;
extern struct record_description Absyn_Ty_ARR__desc;
extern struct record_description Absyn_Ty_REC__desc;

/* VarBnd */
extern struct record_description Absyn_VarBnd_VARBND__desc;

/* TyBnd */
extern struct record_description Absyn_TyBnd_TYBND__desc;

/* UnOp */
extern struct record_description Absyn_UnOp_ADDR__desc;
extern struct record_description Absyn_UnOp_INDIR__desc;
extern struct record_description Absyn_UnOp_NOT__desc;

/* BinOp */
extern struct record_description Absyn_BinOp_ADD__desc;
extern struct record_description Absyn_BinOp_SUB__desc;
extern struct record_description Absyn_BinOp_MUL__desc;
extern struct record_description Absyn_BinOp_RDIV__desc;
extern struct record_description Absyn_BinOp_IDIV__desc;
extern struct record_description Absyn_BinOp_IMOD__desc;
extern struct record_description Absyn_BinOp_IAND__desc;
extern struct record_description Absyn_BinOp_IOR__desc;

/* Stmt */
extern struct record_description Absyn_Stmt_ASSIGN__desc;
extern struct record_description Absyn_Stmt_PCALL__desc;
extern struct record_description Absyn_Stmt_FRETURN__desc;
extern struct record_description Absyn_Stmt_PRETURN__desc;
extern struct record_description Absyn_Stmt_WHILE__desc;
extern struct record_description Absyn_Stmt_IF__desc;
extern struct record_description Absyn_Stmt_SEQ__desc;
extern struct record_description Absyn_Stmt_SKIP__desc;

/* SubBnd */
extern struct record_description Absyn_SubBnd_FUNCBND__desc;
extern struct record_description Absyn_SubBnd_PROCBND__desc;

/* Block */
extern struct record_description Absyn_Block_BLOCK__desc;

/* Prog */
extern struct record_description Absyn_Prog_PROG__desc;

void *pu_Constant_INTcon(void *icon)    /* Absyn.INTcon=BOX1 */
{
  return mmc_mk_box2(3, &Absyn_Constant_INTcon__desc, icon);
}

void *pu_Constant_REALcon(void *rcon)    /* Absyn.REALcon=BOX1 */
{
  return mmc_mk_box2(4, &Absyn_Constant_REALcon__desc, rcon);
}

void *pu_Constant_IDENTcon(void *id)    /* Absyn.IDENTcon=BOX1 */
{
  return mmc_mk_box2(5, &Absyn_Constant_IDENTcon__desc, id);
}

void *pu_CONBND(void *id, void *con)  /* Absyn.CONBND=BOX2 */
{
  return mmc_mk_box3(3, &Absyn_ConBnd_CONBND__desc, id, con);
}

void *pu_Ty_NAME(void *id)  /* Absyn.NAME=BOX1 */
{
  return mmc_mk_box2(3, &Absyn_Ty_NAME__desc, id);
}

void *pu_Ty_PTR(void *ty)  /* Absyn.PTR=BOX1 */
{
  return mmc_mk_box2(4, &Absyn_Ty_PTR__desc, ty);
}

void *pu_Ty_ARR(void *con, void *ty)  /* Absyn.ARR=BOX2 */
{
  return mmc_mk_box3(5, &Absyn_Ty_ARR__desc, con, ty);
}

void *pu_Ty_REC(void *varbnds)    /* Absyn.REC=BOX1 */
{
  return mmc_mk_box2(6, &Absyn_Ty_REC__desc, varbnds);
}

void *pu_VARBND(void *id, void *ty)  /* Absyn.VARBND=BOX2 */
{
  return mmc_mk_box3(3, &Absyn_VarBnd_VARBND__desc, id, ty);
}

void *pu_TYBND(void *id, void *ty)  /* Absyn.TYBND=BOX2 */
{
  return mmc_mk_box3(3, &Absyn_TyBnd_TYBND__desc, id, ty);
}

void *pu_Exp_INT(void *icon)  /* Absyn.INT=BOX1 */
{
  return mmc_mk_box2(3, &Absyn_Exp_INT__desc, icon);
}

void *pu_Exp_REAL(void *rcon)  /* Absyn.REAL=BOX1 */
{
  return mmc_mk_box2(4, &Absyn_Exp_REAL__desc, rcon);
}

void *pu_Exp_IDENT(void *id)  /* Absyn.IDENT=BOX1 */
{
  return mmc_mk_box2(5, &Absyn_Exp_IDENT__desc, id);
}

void *pu_Exp_CAST(void *ty, void *exp)  /* Absyn.CAST=BOX2 */
{
  return mmc_mk_box3(6, &Absyn_Exp_CAST__desc, ty, exp);
}

void *pu_Exp_FIELD(void *exp, void *id)  /* Absyn.FIELD=BOX2 */
{
  return mmc_mk_box3(7, &Absyn_Exp_FIELD__desc, exp, id);
}

void *pu_Exp_UNARY(enum uop uop, void *exp)  /* Absyn.UNARY=BOX2 */
{
  void* unop;
  switch( uop ) {
  case UOP_ADDR:  unop = mmc_mk_box1(3, &Absyn_UnOp_ADDR__desc); break;
  case UOP_INDIR: unop = mmc_mk_box1(4, &Absyn_UnOp_INDIR__desc); break;
  case UOP_NOT:    unop = mmc_mk_box1(5, &Absyn_UnOp_NOT__desc); break;
  case UOP_PLUS:  return exp;
  case UOP_MINUS: return pu_Exp_BINARY(pu_Exp_INT(mmc_mk_icon(0)), BOP_SUB, exp);
  }
  return mmc_mk_box3(8, &Absyn_Exp_UNARY__desc, unop, exp);
}

void *pu_Exp_BINARY(void *exp1, enum bop bop, void *exp2) /* Absyn.BINARY=BOX3 */
{
    void* binop;
    switch( bop ) {
    case BOP_ADD:  binop = mmc_mk_box1(3, &Absyn_BinOp_ADD__desc); break;
    case BOP_SUB:  binop = mmc_mk_box1(4, &Absyn_BinOp_SUB__desc); break;
    case BOP_MUL:  binop = mmc_mk_box1(5, &Absyn_BinOp_MUL__desc); break;
    case BOP_RDIV: binop = mmc_mk_box1(6, &Absyn_BinOp_RDIV__desc); break;
    case BOP_IDIV: binop = mmc_mk_box1(7, &Absyn_BinOp_IDIV__desc); break;
    case BOP_IMOD: binop = mmc_mk_box1(8, &Absyn_BinOp_IMOD__desc); break;
    case BOP_IAND: binop = mmc_mk_box1(9, &Absyn_BinOp_IAND__desc); break;
    case BOP_IOR:  binop = mmc_mk_box1(10, &Absyn_BinOp_IOR__desc); break;
    }
    return mmc_mk_box4(9, &Absyn_Exp_BINARY__desc, exp1, binop, exp2);
}

void *pu_Exp_RELATION(void *exp1, enum rop rop, void *exp2) /* Absyn.RELATION=BOX3 */
{
  void *lhs, *rhs, *relop;
  switch( rop ) {
  case ROP_LT: relop = mmc_mk_box1(3, &Absyn_RelOp_LT__desc); lhs = exp1; rhs = exp2; break;
  case ROP_LE: relop = mmc_mk_box1(4, &Absyn_RelOp_LE__desc); lhs = exp1; rhs = exp2; break;
  case ROP_GE: relop = mmc_mk_box1(4, &Absyn_RelOp_LE__desc); lhs = exp2; rhs = exp1; break;
  case ROP_GT: relop = mmc_mk_box1(3, &Absyn_RelOp_LT__desc); lhs = exp2; rhs = exp1; break;
  }
  return mmc_mk_box4(10, &Absyn_Exp_RELATION__desc, lhs, relop, rhs);
}

void *pu_Exp_EQUALITY(void *exp1, enum eop eop, void *exp2) /* Absyn.EQUALITY=BOX2 */
{
  void *exp = mmc_mk_box3(11, &Absyn_Exp_EQUALITY__desc, exp1, exp2);
  if( eop == EOP_NE )
    exp = pu_Exp_UNARY(UOP_NOT, exp);
  return exp;
}

void *pu_Exp_FCALL(void *id, void *args)  /* Absyn.FCALL=BOX2 */
{
  return mmc_mk_box3(12, &Absyn_Exp_FCALL__desc, id, args);
}

void *pu_Stmt_ASSIGN(void *lhs, void *rhs)  /* Absyn.ASSIGN=BOX2 */
{
  return mmc_mk_box3(3, &Absyn_Stmt_ASSIGN__desc, lhs, rhs);
}

void *pu_Stmt_PCALL(void *id, void *args)  /* Absyn.PCALL=BOX2 */
{
  return mmc_mk_box3(4, &Absyn_Stmt_PCALL__desc, id, args);
}

void *pu_Stmt_FRETURN(void *exp)  /* Absyn.FRETURN=BOX1 */
{
  return mmc_mk_box2(5, &Absyn_Stmt_FRETURN__desc, exp);
}

void *pu_Stmt_PRETURN(void)  /* Absyn.PRETURN=BOX0 */
{
  return mmc_mk_box1(6, &Absyn_Stmt_PRETURN__desc);
}

void *pu_Stmt_WHILE(void *exp, void *stmt)  /* Absyn.WHILE=BOX2 */
{
  return mmc_mk_box3(7, &Absyn_Stmt_WHILE__desc, exp, stmt);
}

void *pu_Stmt_IF(void *exp, void *stmt1, void *stmt2)  /* Absyn.IF=BOX3 */
{
  return mmc_mk_box4(8, &Absyn_Stmt_IF__desc, exp, stmt1, stmt2);
}

void *pu_Stmt_SEQ(void *stmt1, void *stmt2)  /* Absyn.SEQ=BOX2 */
{
  return mmc_mk_box3(9, &Absyn_Stmt_SEQ__desc, stmt1, stmt2);
}

void *pu_Stmt_SKIP(void)  /* Absyn.SKIP=BOX0 */
{
  return mmc_mk_box1(10, &Absyn_Stmt_SKIP__desc);
}

void *pu_SubBnd_FUNCBND(void *id, void *varbnds, void *ty, void *block_opt) /* Absyn.FUNCBND=BOX4 */
{
  return mmc_mk_box5(3, &Absyn_SubBnd_FUNCBND__desc, id, varbnds, ty, block_opt);
}

void *pu_SubBnd_PROCBND(void *id, void *varbnds, void *block_opt)  /* Absyn.PROCBND=BOX3 */
{
  return mmc_mk_box4(4, &Absyn_SubBnd_PROCBND__desc, id, varbnds, block_opt);
}

void *pu_BLOCK(void *conbnds, void *tybnds, void *varbnds, void *subbnds, void *stmt)  /* Absyn.BLOCK=BOX5 */
{
  return mmc_mk_box6(3, &Absyn_Block_BLOCK__desc, conbnds, tybnds, varbnds, subbnds, stmt);
}

void *pu_PROG(void *id, void *block)  /* Absyn.PROG=BOX2 */
{
  return mmc_mk_box3(3, &Absyn_Prog_PROG__desc, id, block);
}

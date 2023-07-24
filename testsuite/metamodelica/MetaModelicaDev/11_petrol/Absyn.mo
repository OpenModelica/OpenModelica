package Absyn "Absyn.mo
  concrete syntax rewritings:
   exp1{exp2}  ==> (exp1 + exp2)^
   -exp    ==> 0 - exp
   +exp    ==> exp
   exp1 <> exp2  ==> not(exp1 = exp2)
   exp1 >= exp2  ==> exp2 <= exp1
   exp1 > exp2  ==> exp2 < exp1
"

type Ident = String;

uniontype Constant
  record INTcon
    Integer integer;
  end INTcon;

  record REALcon
    Real real;
  end REALcon;

  record IDENTcon
    Ident ident;
  end IDENTcon;
end Constant;

uniontype ConBnd
  record CONBND
    Ident ident;
    Constant constant_;
  end CONBND;

end ConBnd;

uniontype Ty
  record NAME
    Ident ident;
  end NAME;

  record PTR
    Ty ty;
  end PTR;

  record ARR
    Constant constant_;
    Ty ty;
  end ARR;

  record REC
    list<VarBnd> varBndLst;
  end REC;

end Ty;

uniontype VarBnd
  record VARBND
    Ident ident;
    Ty ty;
  end VARBND;

end VarBnd;

uniontype TyBnd
  record TYBND
    Ident ident;
    Ty ty;
  end TYBND;

end TyBnd;

uniontype UnOp
  record ADDR end ADDR;
  record INDIR end INDIR;
  record NOT end NOT;
end UnOp;

uniontype BinOp
  record ADD end ADD;
  record SUB end SUB;
  record MUL end MUL;
  record RDIV end RDIV;
  record IDIV end IDIV;
  record IMOD end IMOD;
  record IAND end IAND;
  record IOR end IOR;
end BinOp;

uniontype RelOp
  record LT end LT;
  record LE end LE;
end RelOp;

uniontype Exp
  record INT
    Integer integer;
  end INT;

  record REAL
    Real real;
  end REAL;

  record IDENT
    Ident ident;
  end IDENT;

  record CAST
    Ty ty;
    Exp exp;
  end CAST;

  record FIELD
    Exp exp;
    Ident ident;
  end FIELD;

  record UNARY
    UnOp unOp;
    Exp exp;
  end UNARY;

  record BINARY
    Exp exp1;
    BinOp binOp2;
    Exp exp3;
  end BINARY;

  record RELATION
    Exp exp1;
    RelOp relOp2;
    Exp exp3;
  end RELATION;

  record EQUALITY
    Exp exp1;
    Exp exp2;
  end EQUALITY;

  record FCALL
    Ident ident;
    list<Exp> expLst;
  end FCALL;

end Exp;

uniontype Stmt
  record ASSIGN
    Exp exp1;
    Exp exp2;
  end ASSIGN;

  record PCALL
    Ident ident;
    list<Exp> expLst;
  end PCALL;

  record FRETURN
    Exp exp;
  end FRETURN;

  record PRETURN end PRETURN;

  record WHILE
    Exp exp;
    Stmt stmt;
  end WHILE;

  record IF
    Exp exp1;
    Stmt stmt2;
    Stmt stmt3;
  end IF;

  record SEQ
    Stmt stmt1;
    Stmt stmt2;
  end SEQ;

  record SKIP end SKIP;

end Stmt;

uniontype SubBnd
  record FUNCBND
    Ident ident;
    list<VarBnd> varBndLst;
    Ty ty;
    Option<Block> blockOption;
  end FUNCBND;

  record PROCBND
    Ident ident;
    list<VarBnd> varBndLst;
    Option<Block> blockOption;
  end PROCBND;
end SubBnd;

uniontype Block
  record BLOCK
    list<ConBnd> conBndLst;
    list<TyBnd> tyBndLst;
    list<VarBnd> varBndLst;
    list<SubBnd> subBndLst;
    Stmt stmt;
  end BLOCK;
end Block;

uniontype Prog
  record PROG
    Ident ident;
    Block block_;
  end PROG;
end Prog;
end Absyn;


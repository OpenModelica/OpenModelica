package Absyn

type Ident = String;

uniontype BinOp
  record ADD end ADD;

  record SUB end SUB;

  record MUL end MUL;

  record DIV end DIV;

end BinOp;

uniontype UnOp
  record NEG end NEG;
end UnOp;

uniontype RelOp
  record EQ end EQ;
  record GT end GT;
  record LT end LT;
  record LE end LE;
  record GE end GE;
  record NE end NE;
end RelOp;

uniontype Expr
  record INTCONST
    Integer integer;
  end INTCONST;

  record REALCONST
    Real real;
  end REALCONST;

  record BINARY
    Expr expr1;
    BinOp binOp2;
    Expr expr3;
  end BINARY;

  record UNARY
    UnOp unOp;
    Expr expr;
  end UNARY;

  record RELATION
    Expr expr1;
    RelOp relOp2;
    Expr expr3;
  end RELATION;

  record VARIABLE
    Ident ident;
  end VARIABLE;

end Expr;

type StmtLst = list<Stmt>;

uniontype Stmt
  record ASSIGN
    Ident ident;
    Expr expr;
  end ASSIGN;

  record WRITE
    Expr expr;
  end WRITE;

  record NOOP end NOOP;

  record IF
    Expr expr1;
    StmtLst stmtLst2;
    StmtLst stmtLst3;
  end IF;

  record WHILE
    Expr expr;
    StmtLst stmtLst;
  end WHILE;

end Stmt;

type StmtList = list<Stmt>;

uniontype Decl
  record NAMEDECL
    Ident ident1;
    Ident ident2;
  end NAMEDECL;

end Decl;

type DeclList = list<Decl>;

uniontype Prog
  record PROG
    DeclList declList;
    StmtList stmtList;
  end PROG;

end Prog;
end Absyn;


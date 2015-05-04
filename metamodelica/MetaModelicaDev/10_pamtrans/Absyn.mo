package Absyn "Semantics oriented abstract syntax for the PAM language"

type Ident = String;

uniontype BinOp
  record ADD end ADD;

  record SUB end SUB;

  record MUL end MUL;

  record DIV end DIV;

end BinOp;






uniontype RelOp
  record EQ end EQ;
  record GT end GT;
  record LT end LT;
  record LE end LE;
  record GE end GE;
  record NE end NE;
end RelOp;

uniontype Exp
  record INT
    Integer integer;
  end INT;

  record IDENT
    Ident ident;
  end IDENT;

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

end Exp;

type Comparison = Exp;

type IdentLst = list<Ident>;

uniontype Stmt
  record ASSIGN
    Ident ident;
    Exp id "Id := Exp";
  end ASSIGN;

  record IF
    Exp exp;
    Stmt stmt;
    Stmt if_ "if Exp then Stmt..";
  end IF;

  record WHILE
    Exp exp;
    Stmt while_ "while Exp do Stmt";
  end WHILE;

  record TODO
    Exp exp;
    Stmt to "to Exp do Stmt...";
  end TODO;

  record READ
    IdentLst read "read id1,id2,...";
  end READ;

  record WRITE
    IdentLst write "write id1,id2,..";
  end WRITE;

  record SEQ
    Stmt stmt;
    Stmt stmt1 "Stmt1; Stmt2";
  end SEQ;

  record SKIP "; empty stmt" end SKIP;

end Stmt;
end Absyn;


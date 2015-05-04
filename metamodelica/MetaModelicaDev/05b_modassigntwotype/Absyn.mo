package Absyn " file: Absyn.mo
   Semantics oriented abstract syntax of the AssignTwoType language "

type Ident = String;

uniontype BinOp "binary operators"
  record ADD "addition" end ADD;
  record SUB "subtraction" end SUB;
  record MUL "multiplication" end MUL;
  record DIV "division" end DIV;
end BinOp;

uniontype UnOp "unary operators"
  record NEG "negation" end NEG;
end UnOp;

uniontype Exp "expressions"
  record INT "literal integers"
    Integer x1;
  end INT;
  record REAL "literal reals"
    Real x1;
  end REAL;
  record BINARY "binary expressions"
    Exp x1;
    BinOp x2;
    Exp x3;
  end BINARY;
  record UNARY "unary expressions"
    UnOp x1;
    Exp x2;
  end UNARY;
  record ASSIGN "assignment expressions"
    Ident x1;
    Exp x2;
  end ASSIGN;
  record IDENT "identifiers"
    Ident x1;
  end IDENT;
end Exp;
end Absyn;


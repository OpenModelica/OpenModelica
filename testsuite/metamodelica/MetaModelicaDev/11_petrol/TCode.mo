package TCode "tcode.rml"

type Ident = String;

type Stamp = Integer;

uniontype Ty
  record CHAR end CHAR;

  record INT end INT;

  record REAL end REAL;

  record PTR
    Ty ty;
  end PTR;

  record ARR
    Integer integer;
    Ty ty;
  end ARR;

  record REC
    Record record_;
  end REC;

  record UNFOLD
    Stamp stamp;
  end UNFOLD;

end Ty;

uniontype Record
  record RECORD
    Stamp stamp;
    list<Var> varLst;
  end RECORD;

end Record;

uniontype Var
  record VAR
    Ident ident;
    Ty ty;
  end VAR;

end Var;

uniontype UnOp
  record CtoI end CtoI;

  record ItoR end ItoR;

  record RtoI end RtoI;

  record ItoC end ItoC;

  record TOPTR
    Ty ty;
  end TOPTR;

  record PtoI end PtoI;

  record LOAD
    Ty ty;
  end LOAD;

  record OFFSET
    Record record_;
    Ident ident;
  end OFFSET;

end UnOp;

uniontype BinOp
  record IADD end IADD;

  record ISUB end ISUB;

  record IMUL end IMUL;

  record IDIV end IDIV;

  record IMOD end IMOD;

  record IAND end IAND;

  record IOR end IOR;

  record ILT end ILT;

  record ILE end ILE;

  record IEQ end IEQ;

  record RADD end RADD;

  record RSUB end RSUB;

  record RMUL end RMUL;

  record RDIV end RDIV;

  record RLT end RLT;

  record RLE end RLE;

  record REQ end REQ;

  record PADD
    Ty ty;
  end PADD;

  record PSUB
    Ty ty;
  end PSUB;

  record PDIFF
    Ty ty;
  end PDIFF;

  record PLT
    Ty ty;
  end PLT;

  record PLE
    Ty ty;
  end PLE;

  record PEQ
    Ty ty;
  end PEQ;

end BinOp;

uniontype Exp
  record ICON
    Integer integer;
  end ICON;

  record RCON
    Real real;
  end RCON;

  record ADDR
    Ident ident;
  end ADDR;

  record UNARY
    UnOp unOp;
    Exp exp;
  end UNARY;

  record BINARY
    Exp exp1;
    BinOp binOp2;
    Exp exp3;
  end BINARY;

  record FCALL
    Ident ident;
    list<Exp> expLst;
  end FCALL;

end Exp;

uniontype Stmt
  record STORE
    Ty ty1;
    Exp exp2;
    Exp exp3;
  end STORE;

  record PCALL
    Ident ident;
    list<Exp> expLst;
  end PCALL;

  record RETURN
    Option<tuple<Ty, Exp>> tplTyExpOption;
  end RETURN;

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

uniontype Proc
  record PROC
    Ident ident;
    list<Var> varLst;
    Option<Ty> tyOption;
    Option<Block> blockOption;
  end PROC;

end Proc;

uniontype Block
  record BLOCK
    list<Var> varLst;
    list<Proc> procLst;
    Stmt stmt;
  end BLOCK;

end Block;

uniontype Prog
  record PROG
    Ident ident;
    Block block_;
  end PROG;

end Prog;
end TCode;


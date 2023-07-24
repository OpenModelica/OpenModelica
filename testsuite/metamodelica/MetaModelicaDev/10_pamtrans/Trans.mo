package Trans

import Absyn;
import Mcode;

function transExpr "Arithmetic expression translation
  Evaluation of expressions in the current environment"
  input Absyn.Exp inExp;
  output Mcode_MCodeLst outMcodeMCodeLst;
  type Mcode_MCodeLst = list<Mcode.MCode>;
algorithm
  outMcodeMCodeLst:=
  matchcontinue (inExp)
    local
      Integer v;
      String id;
      Mcode_MCodeLst cod1,cod3,cod2;
      Mcode.MOperand operand2,t1,t2;
      Mcode.MBinOp opcode;
      Absyn.Exp e1,e2;
      Absyn.BinOp binop;
    /* integer constant */
    case (Absyn.INT(integer = v)) then {Mcode.MLOAD(Mcode.N(v))};
    /* identifier id */
    case (Absyn.IDENT(ident = id)) then {Mcode.MLOAD(Mcode.I(id))};
    /* Arith binop: simple case, expr2 is just an identifier or constant expr1 binop expr2 */
    case (Absyn.BINARY(exp1 = e1,binOp2 = binop,exp3 = e2))
      equation
        cod1 = transExpr(e1);
        {Mcode.MLOAD(mOperand = operand2)} = transExpr(e2);
        opcode = transBinop(binop) "expr2 simple";
        cod3 = listAppend(cod1, {Mcode.MB(opcode,operand2)}); then cod3;
    case (Absyn.BINARY(exp1 = e1,binOp2 = binop,exp3 = e2)) "Arith binop: general case, expr2 is a more complicated expr expr1 binop expr2"
      equation
        cod1 = transExpr(e1);
        cod2 = transExpr(e2);
        opcode = transBinop(binop);
        t1 = gentemp();
        t2 = gentemp();
        cod3 = listAppend6(cod1, {Mcode.MSTO(t1)}, cod2, {Mcode.MSTO(t2)},
          {Mcode.MLOAD(t1)}, {Mcode.MB(opcode,t2)}) "code for expr1 store expr1 code for expr2 store expr2 load expr1 value into Acc Do arith operation"; then cod3;
  end matchcontinue;
end transExpr;

function transBinop
  input Absyn.BinOp inBinOp;
  output Mcode.MBinOp outMBinOp;
algorithm
  outMBinOp:=
  matchcontinue (inBinOp)
    case (Absyn.ADD()) then Mcode.MADD();
    case (Absyn.SUB()) then Mcode.MSUB();
    case (Absyn.MUL()) then Mcode.MMULT();
    case (Absyn.DIV()) then Mcode.MDIV();
  end matchcontinue;
end transBinop;

function gentemp
  output Mcode.MOperand outMOperand;
protected
  Integer no;
algorithm
  no := tick();
  outMOperand := Mcode.T(no);
end gentemp;

function genlabel
  output Mcode.MOperand outMOperand;
protected
  Integer no;
algorithm
  no := tick();
  outMOperand := Mcode.L(no);
end genlabel;

function listAppend3<Type_a>
  input VType_aLst l1;
  input VType_aLst l2;
  input VType_aLst l3;
  output VType_aLst l13;
  type VType_aLst = list<Type_a>;
protected
  VType_aLst l12;
algorithm
  l12 := listAppend(l1, l2);
  l13 := listAppend(l12, l3);
end listAppend3;

function listAppend5<Type_a>
  input VType_aLst l1;
  input VType_aLst l2;
  input VType_aLst l3;
  input VType_aLst l4;
  input VType_aLst l5;
  output VType_aLst l15;
  type VType_aLst = list<Type_a>;
protected
  VType_aLst l13;
algorithm
  l13 := listAppend3(l1, l2, l3);
  l15 := listAppend3(l13, l4, l5);
end listAppend5;

function listAppend6<Type_a>
  input VType_aLst l1;
  input VType_aLst l2;
  input VType_aLst l3;
  input VType_aLst l4;
  input VType_aLst l5;
  input VType_aLst l6;
  output VType_aLst l16;
  type VType_aLst = list<Type_a>;
protected
  VType_aLst l13,l46;
algorithm
  l13 := listAppend3(l1, l2, l3);
  l46 := listAppend3(l4, l5, l6);
  l16 := listAppend(l13, l46);
end listAppend6;

function listAppend10<Type_a>
  input VType_aLst l1;
  input VType_aLst l2;
  input VType_aLst l3;
  input VType_aLst l4;
  input VType_aLst l5;
  input VType_aLst l6;
  input VType_aLst l7;
  input VType_aLst l8;
  input VType_aLst l9;
  input VType_aLst l10;
  output VType_aLst l110;
  type VType_aLst = list<Type_a>;
protected
  VType_aLst l15;
algorithm
  l15 := listAppend5(l1, l2, l3, l4, l5);
  l110 := listAppend6(l15, l6, l7, l8, l9, l10);
end listAppend10;

function transComparison
  input Absyn.Comparison inComparison;
  input Mcode.MOperand inMOperand;
  output Mcode_MCodeLst outMcodeMCodeLst;
  type Mcode_MCodeLst = list<Mcode.MCode>;
algorithm
  outMcodeMCodeLst:=
  matchcontinue (inComparison,inMOperand)
    local
      Mcode_MCodeLst cod1,cod3,cod2;
      Mcode.MOperand operand2,lab,t1;
      Mcode.MCondJmp jmpop;
      Absyn.Exp e1,e2;
      Absyn.RelOp relop;
    case (Absyn.RELATION(exp1 = e1,relOp2 = relop,exp3 = e2),lab) "translation of a comparison:  expr1 function expr2
  Example call:  trans_comparisonRELATIONINDENTx), GT, INT5)), L10))

  Use a simple code pattern the first rule), when expr2 is  a simple
  identifier or constant:
    code for expr1
    SUB operand2
    conditional jump to lab

  or a general code pattern second rule), which is needed when expr2
  is more complicated than a simple identifier or constant:
    code for expr1
    STO temp1
    code for expr2
    SUB temp1
    conditional jump to lab
 expr1 relop expr2"
      equation
        cod1 = transExpr(e1);
        {Mcode.MLOAD(mOperand = operand2)} = transExpr(e2);
        jmpop = transRelop(relop);
        cod3 = listAppend3(cod1, {Mcode.MB(Mcode.MSUB(),operand2)},
          {Mcode.MJ(jmpop,lab)}); then cod3;
    case (Absyn.RELATION(exp1 = e1,relOp2 = relop,exp3 = e2),lab) "expr1 relop expr2"
      equation
        cod1 = transExpr(e1);
        cod2 = transExpr(e2);
        jmpop = transRelop(relop);
        t1 = gentemp();
        cod3 = listAppend5(cod1, {Mcode.MSTO(t1)}, cod2, {Mcode.MB(Mcode.MSUB(),t1)},
          {Mcode.MJ(jmpop,lab)}); then cod3;
  end matchcontinue;
end transComparison;

function transRelop
  input Absyn.RelOp inRelOp;
  output Mcode.MCondJmp outMCondJmp;
algorithm
  outMCondJmp:=
  matchcontinue (inRelOp)
    case (Absyn.EQ()) then Mcode.MJNP();  /* Jump on Negative or Positive */
    case (Absyn.LE()) then Mcode.MJP();  /* Jump on Positive */
    case (Absyn.LT()) then Mcode.MJPZ();  /* Jump on Positive or Zero */
    case (Absyn.GT()) then Mcode.MJNZ();  /* Jump on Negative or Zero */
    case (Absyn.GE()) then Mcode.MJN();  /* Jump on Negative */
    case (Absyn.NE()) then Mcode.MJZ();  /* Jump on Zero */
  end matchcontinue;
end transRelop;

function transStmt "Statement translation"
  input Absyn.Stmt inStmt;
  output Mcode_MCodeLst outMcodeMCodeLst;
  type Mcode_MCodeLst = list<Mcode.MCode>;
algorithm
  outMcodeMCodeLst:=
  matchcontinue (inStmt)
    local
      Mcode_MCodeLst cod1,cod2,s1cod,compcod,cod3,s2cod,bodycod,tocod;
      String id;
      Absyn.Exp e1,comp;
      Mcode.MOperand l1,l2,t1;
      Absyn.Stmt s1,s2,stmt1,stmt2;
      list<String> idlist_rest;
    case (Absyn.ASSIGN(ident = id,id = e1)) "Statement translation: map the current state into a new state correct?? Assignment"
      equation
        cod1 = transExpr(e1);
        cod2 = listAppend(cod1, {Mcode.MSTO(Mcode.I(id))}); then cod2;
    case (Absyn.SKIP()) then {};  /* empty statement */
    case (Absyn.IF(exp = comp,stmt = s1,if_ = Absyn.SKIP())) /* IF comp then s1 */
      equation
        s1cod = transStmt(s1);
        l1 = genlabel();
        compcod = transComparison(comp, l1);
        cod3 = listAppend3(compcod, s1cod, {Mcode.MLABEL(l1)}); then cod3;
    case (Absyn.IF(exp = comp,stmt = s1,if_ = s2)) "IF comp then s1 else s2"
      equation
        s1cod = transStmt(s1);
        s2cod = transStmt(s2);
        l1 = genlabel();
        l2 = genlabel();
        compcod = transComparison(comp, l1);
        cod3 = listAppend6(compcod, s1cod, {Mcode.MJMP(l2)}, {Mcode.MLABEL(l1)},
          s2cod, {Mcode.MLABEL(l2)}); then cod3;
    case (Absyn.WHILE(exp = comp,while_ = s1)) "WHILE ..."
      equation
        bodycod = transStmt(s1);
        l1 = genlabel();
        l2 = genlabel();
        compcod = transComparison(comp, l2);
        cod3 = listAppend5({Mcode.MLABEL(l1)}, compcod, bodycod, {Mcode.MJMP(l1)}, {Mcode.MLABEL(l2)});
      then cod3;
    case (Absyn.TODO(exp = e1,to = s1)) "TO e1 DO s1 .."
      equation
        tocod = transExpr(e1);
        bodycod = transStmt(s1);
        t1 = gentemp();
        l1 = genlabel();
        l2 = genlabel();
        cod3 = listAppend10(tocod, {Mcode.MSTO(t1)}, {Mcode.MLABEL(l1)},
          {Mcode.MLOAD(t1)}, {Mcode.MB(Mcode.MSUB(),Mcode.N(1))}, {Mcode.MJ(Mcode.MJN(),l2)},
          {Mcode.MSTO(t1)}, bodycod, {Mcode.MJMP(l1)}, {Mcode.MLABEL(l2)}); then cod3;
    case (Absyn.READ(read = {})) then {};  /* READ {} */
    case (Absyn.READ(read = id :: idlist_rest))
      equation
        cod2 = transStmt(Absyn.READ(idlist_rest)); then Mcode.MGET(Mcode.I(id)) :: cod2;
    case (Absyn.WRITE(write = {})) then {};  /* WRITE {} */
    case (Absyn.WRITE(write = id :: idlist_rest))
      equation
        cod2 = transStmt(Absyn.WRITE(idlist_rest)); then Mcode.MPUT(Mcode.I(id)) :: cod2;
    case (Absyn.SEQ(stmt = stmt1,stmt1 = stmt2)) /* stmt1 ; stmt2 */
      equation
        cod1 = transStmt(stmt1);
        cod2 = transStmt(stmt2);
        cod3 = listAppend(cod1, cod2); then cod3;
  end matchcontinue;
end transStmt;

function transProgram
  input Absyn.Stmt progbody;
  output Mcode_MCodeLst programcode;
  type Mcode_MCodeLst = list<Mcode.MCode>;
protected
  Mcode_MCodeLst cod1;
algorithm
  cod1 := transStmt(progbody);
  programcode := listAppend(cod1, {Mcode.MHALT()});
end transProgram;
end Trans;


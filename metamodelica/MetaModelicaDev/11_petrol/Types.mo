package Types "types.rml"

import Absyn;
import TCode "import RelOp and BinOp" ;

type Ident = String;

type Stamp = Integer;

uniontype ATy
  record CHAR end CHAR;

  record INT end INT;

  record REAL end REAL;

end ATy;

uniontype Ty
  record ARITH
    ATy aTy;
  end ARITH;

  record PTR
    Ty ty;
  end PTR;

  record PTRNIL end PTRNIL;

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
    list<tuple<Ident, Ty>> an "An lvalue type (lty) can be any type, except PTRNIL.
       PTR, ARR, and REC can only refer to lvalue types.
       UNFOLD is an internal placeholder that should never
       occur outside of a REC. inspect a record by unfolding it one level" ;
  end RECORD;

end Record;

function unfoldTy "Inspect a record by unfolding it one level
"
  input Ty inTy;
  input Record inRecord;
  output Ty outTy;
algorithm
  outTy:=
  matchcontinue (inTy,inRecord)
    local
      Ty ty,ty_1;
      Record r;
      Stamp sz,stamp,stamp_1;
      list<tuple<Ident, Ty>> bnds_1,bnds;
      Record r;
    case ((ty as ARITH(_)),_) then ty;
    case ((ty as PTRNIL()),_) then ty;
    case (PTR(ty),r)
      equation
        ty_1 = unfoldTy(ty, r);
      then
        PTR(ty_1);
    case (ARR(sz,ty),r)
      equation
        ty_1 = unfoldTy(ty, r);
      then
        ARR(sz,ty_1);
    case (REC(RECORD(stamp,bnds)),r)
      equation
        bnds_1 = unfoldBnds(r, bnds, {});
      then
        REC(RECORD(stamp,bnds_1));
    case (ty as UNFOLD(stamp),(r as RECORD(stamp_1,_)))
      then if stamp == stamp_1 then REC(r) else ty;
  end matchcontinue;
end unfoldTy;

function unfoldBnds
  input Record inRecord1;
  input list<tuple<String, Ty>> inTplStringTyLst2;
  input list<tuple<String, Ty>> inTplStringTyLst3;
  output list<tuple<String, Ty>> outTplStringTyLst;
algorithm
  outTplStringTyLst:=
  matchcontinue (inRecord1,inTplStringTyLst2,inTplStringTyLst3)
    local
      list<tuple<String, Ty>> bnds_2,bnds_1;
      Ty ty_1;
      Record r;
      String id;
      Ty ty;
      list<tuple<String, Ty>> bnds;
    case (_,{},bnds_1)
      equation
        bnds_2 = listReverse(bnds_1);
      then
        bnds_2;
    case (r,((id,ty) :: bnds),bnds_1)
      equation
        ty_1 = unfoldTy(ty, r);
        bnds_2 = unfoldBnds(r, bnds, ((id,ty_1) :: bnds_1));
      then
        bnds_2;
  end matchcontinue;
end unfoldBnds;

function unfoldRec
  input Record inRecord;
  output list<tuple<String, Ty>> outTplStringTyLst;
algorithm
  outTplStringTyLst:=
  matchcontinue (inRecord)
    local
      list<tuple<Ident, Ty>> bnds_1,bnds;
      Record r;
      Stamp stamp;
    case ((r as RECORD(stamp,bnds)))
      equation
        bnds_1 = unfoldBnds(r, bnds, {});
      then
        bnds_1;
  end matchcontinue;
end unfoldRec;

function tyCnv "Convert one of our types to a TCode type.
  PTRNIL is intentionally excluded.
"
  input Ty inTy;
  output TCode.Ty outTy;
algorithm
  outTy:=
  matchcontinue (inTy)
    local
      TCode.Ty ty_1;
      Ty ty;
      Stamp sz,stamp;
      TCode.Record r_1;
      Record r;
    case (ARITH(CHAR())) then TCode.CHAR();
    case (ARITH(INT())) then TCode.INT();
    case (ARITH(REAL())) then TCode.REAL();
    case (PTR(ty))
      equation
        ty_1 = tyCnv(ty);
      then
        TCode.PTR(ty_1);
    case (ARR(sz,ty))
      equation
        ty_1 = tyCnv(ty);
      then
        TCode.ARR(sz,ty_1);
    case (REC(r))
      equation
        r_1 = recCnv(r);
      then
        TCode.REC(r_1);
    case (UNFOLD(stamp)) then TCode.UNFOLD(stamp);
  end matchcontinue;
end tyCnv;

function recCnv
  input Record inRecord;
  output TCode.Record outRecord;
algorithm
  outRecord:=
  matchcontinue (inRecord)
    local
      list<TCode.Var> bnds_1;
      Stamp stamp;
      list<tuple<Ident, Ty>> bnds;
    case (RECORD(stamp,bnds))
      equation
        bnds_1 = bndsCnv(bnds, {});
      then
        TCode.RECORD(stamp,bnds_1);
  end matchcontinue;
end recCnv;

function bndsCnv
  input list<tuple<String, Ty>> inTplStringTyLst;
  input list<TCode.Var> inTCodeVarLst;
  output list<TCode.Var> outTCodeVarLst;
algorithm
  outTCodeVarLst:=
  matchcontinue (inTplStringTyLst,inTCodeVarLst)
    local
      list<TCode.Var> bnds_2,bnds_1;
      TCode.Ty ty_1;
      Ident var;
      Ty ty;
      list<tuple<Ident, Ty>> bnds;
    case ({},bnds_1)
      equation
        bnds_2 = listReverse(bnds_1);
      then
        bnds_2;
    case (((var,ty) :: bnds),bnds_1)
      equation
        ty_1 = tyCnv(ty);
        bnds_2 = bndsCnv(bnds, (TCode.VAR(var,ty_1) :: bnds_1));
      then
        bnds_2;
  end matchcontinue;
end bndsCnv;

function decay "Apply the usual CHAR->INT and ARR->PTR decay
  to an rvalue.
"
  input TCode.Exp inExp;
  input Ty inTy;
  output TCode.Exp outExp;
  output Ty outTy;
algorithm
  (outExp,outTy):=
  matchcontinue (inExp,inTy)
    local
      TCode.Exp exp;
      Ty ty;
      TCode.Ty ty_1;
    case (exp,ARITH(CHAR())) then (TCode.UNARY(TCode.CtoI(),exp),ARITH(INT()));
    case (exp,(ty as ARITH(INT()))) then (exp,ty);
    case (exp,(ty as ARITH(REAL()))) then (exp,ty);
    case (exp,(ty as PTR(_))) then (exp,ty);
    case (exp,(ty as REC(_))) then (exp,ty);
    case (exp,(ty as PTRNIL())) then (exp,ty);
    case (exp,ARR(_,ty))
      equation
        ty_1 = tyCnv(ty);
      then
        (TCode.UNARY(TCode.TOPTR(ty_1),exp),PTR(ty));
  end matchcontinue;
end decay;

function asgCnv1 "Convert the rhs of an assignment to the type of the lhs.
  Ditto for return <exp>.
  Arithmetic types are widened or narrowed as necessary.
  The generic null pointer is made type-specific.
"
  input TCode.Exp inExp1;
  input ATy inATy2;
  input ATy inATy3;
  output TCode.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inATy2,inATy3)
    local
      TCode.Exp rhs;
    case (rhs,CHAR(),CHAR()) then rhs;
    case (rhs,CHAR(),INT())
      then
        TCode.UNARY(TCode.CtoI(),rhs);
    case (rhs,CHAR(),REAL())
      then
        TCode.UNARY(TCode.ItoR(),TCode.UNARY(TCode.CtoI(),rhs));
    case (rhs,INT(),CHAR())
      then
        TCode.UNARY(TCode.ItoC(),rhs);
    case (rhs,INT(),INT()) then rhs;
    case (rhs,INT(),REAL()) then TCode.UNARY(TCode.ItoR(),rhs);
    case (rhs,REAL(),CHAR()) then TCode.UNARY(TCode.ItoC(),TCode.UNARY(TCode.RtoI(),rhs));
    case (rhs,REAL(),INT()) then TCode.UNARY(TCode.RtoI(),rhs);
    case (rhs,REAL(),REAL()) then rhs;
  end matchcontinue;
end asgCnv1;

function asgCnv
  input TCode.Exp inExp1;
  input Ty inTy2;
  input Ty inTy3;
  output TCode.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inTy2,inTy3)
    local
      TCode.Exp rhs_1,rhs;
      ATy aty1,aty2;
      Ty ty1,ty2,ty;
      TCode.Ty ty_1;
      Stamp stamp1,stamp2;
    case (rhs,ARITH(aty1),ARITH(aty2)) /* rhs, rty, lty => rhs\' */
      equation
        rhs_1 = asgCnv1(rhs, aty1, aty2);
      then
        rhs_1;
    case (rhs,PTR(ty1),PTR(ty2))
      equation
        true = valueEq(ty1, ty2);
      then
        rhs;
    case (rhs,ARR(_,ty1),PTR(ty2))
      equation
        true = valueEq(ty1, ty2);
      then
        rhs;
    case (_,PTRNIL(),PTR(ty))
      equation
        ty_1 = tyCnv(ty);
      then
        TCode.UNARY(TCode.TOPTR(ty_1),TCode.ICON(0));
    case (rhs,REC(RECORD(stamp1,_)),REC(RECORD(stamp2,_)))
      equation
        true = valueEq(stamp1, stamp2);
      then
        rhs;
  end matchcontinue;
end asgCnv;

function castCnv
  input TCode.Exp inExp1;
  input Ty inTy2;
  input Ty inTy3;
  output TCode.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inTy2,inTy3)
    local
      TCode.Exp exp_1,exp;
      ATy aty1,aty2,aty;
      TCode.Ty ty2_1,ty_1;
      Ty ty2,ty;
    case (exp,ARITH(aty1),ARITH(aty2))
      equation
        exp_1 = asgCnv1(exp, aty1, aty2);
      then
        exp_1;
    case (exp,PTR(_),ARITH(aty))
      equation
        exp_1 = asgCnv1(TCode.UNARY(TCode.PtoI(),exp), INT(), aty);
      then
        exp_1;
    case (_,PTRNIL(),ARITH(aty))
      equation
        exp = asgCnv1(TCode.ICON(0), INT(), aty);
      then
        exp;
    case (exp,ARITH(aty1),PTR(ty2))
      equation
        exp_1 = asgCnv1(exp, aty1, INT());
        ty2_1 = tyCnv(ty2);
      then
        TCode.UNARY(TCode.TOPTR(ty2_1),exp_1);
    case (exp,PTR(_),PTR(ty))
      equation
        ty_1 = tyCnv(ty);
      then
        TCode.UNARY(TCode.TOPTR(ty_1),exp);
    case (_,PTRNIL(),PTR(ty))
      equation
        ty_1 = tyCnv(ty);
      then
        TCode.UNARY(TCode.TOPTR(ty_1),TCode.ICON(0));
  end matchcontinue;
end castCnv;

function condCnv "Convert a decayed rvalue to a boolean:
  reals are compared with zero: x != 0.0, i.e. (x == 0.0) == 0
  pointers are compared with null: p != <nil>, i.e. (p == <nil>) == 0
"
  input TCode.Exp inExp;
  input Ty inTy;
  output TCode.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inTy)
    local
      TCode.Exp exp;
      TCode.Ty ty_1;
      Ty ty;
    case (_,PTRNIL()) then TCode.ICON(0);
    case (exp,ARITH(INT())) then exp;
    case (exp,ARITH(REAL())) then TCode.BINARY(TCode.BINARY(exp,TCode.REQ(),TCode.RCON(0.0)),TCode.IEQ(),
          TCode.ICON(0));
    case (exp,PTR(ty))
      equation
        ty_1 = tyCnv(ty);
      then
        TCode.BINARY(
          TCode.BINARY(exp,TCode.PEQ(ty_1),
          TCode.UNARY(TCode.TOPTR(ty_1),TCode.ICON(0))),TCode.IEQ(),TCode.ICON(0));
  end matchcontinue;
end condCnv;

function arithLub "Compute the least upper bound of two decayed arithmetic rvalue types
"
  input ATy inATy1;
  input ATy inATy2;
  output ATy outATy;
algorithm
  outATy:=
  matchcontinue (inATy1,inATy2)
    local
      ATy y;
    case (INT(),y) then y;
    case (REAL(),_) then REAL();
  end matchcontinue;
end arithLub;

function arithWiden "Widen a decayed arithmetic rvalue
"
  input TCode.Exp inExp1;
  input ATy inATy2;
  input ATy inATy3;
  output TCode.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inATy2,inATy3)
    local
      TCode.Exp exp;
    case (exp,INT(),INT()) then exp;
    case (exp,INT(),REAL()) then TCode.UNARY(TCode.ItoR(),exp);
    case (exp,REAL(),REAL()) then exp;
  end matchcontinue;
end arithWiden;

function arithCnv "Usual arithmetic conversions.
  Widen two decayed arithmetic rvalues to their lub.
"
  input TCode.Exp inExp1;
  input ATy inATy2;
  input TCode.Exp inExp3;
  input ATy inATy4;
  output TCode.Exp outExp1;
  output TCode.Exp outExp2;
  output ATy outATy3;
algorithm
  (outExp1,outExp2,outATy3):=
  matchcontinue (inExp1,inATy2,inExp3,inATy4)
    local
      ATy raty3,raty1,raty2;
      TCode.Exp exp1_1,exp2_1,exp1,exp2;
    case (exp1,raty1,exp2,raty2)
      equation
        raty3 = arithLub(raty1, raty2);
        exp1_1 = arithWiden(exp1, raty1, raty3);
        exp2_1 = arithWiden(exp2, raty2, raty3);
      then
        (exp1_1,exp2_1,raty3);
  end matchcontinue;
end arithCnv;

function chooseIntReal<Type_a> "Elaborate an equality expression.
  The arguments are already elaborated as decayed rvalues.
  Make arguments compatible, if necessary by arithmetic widening
  or instantiation of the polymorphic nil pointer.
  Return elaborated expression. Result type always int.
  Equality of records is not defined.
"
  input ATy inATy1;
  input Type_a inTypeA2;
  input Type_a inTypeA3;
  output Type_a outTypeA;
algorithm
  outTypeA:=
  matchcontinue (inATy1,inTypeA2,inTypeA3)
    local Type_a x,y;
    case (INT(),x,_) then x;
    case (REAL(),_,y) then y;
  end matchcontinue;
end chooseIntReal;

function ptrEqNull
  input TCode.Exp exp;
  input Ty ty;
  output TCode.Exp outExp;
protected
  TCode.Ty ty_1;
algorithm
  ty_1 := tyCnv(ty);
  outExp := TCode.BINARY(exp,TCode.PEQ(ty_1),
          TCode.UNARY(TCode.TOPTR(ty_1),TCode.ICON(0)));
end ptrEqNull;

function eqCnv
  input TCode.Exp inExp1;
  input Ty inTy2;
  input TCode.Exp inExp3;
  input Ty inTy4;
  output TCode.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inTy2,inExp3,inTy4)
    local
      TCode.Ty ty_1;
      TCode.Exp exp1,exp2,exp_1,exp,exp1_1,exp2_1;
      Ty ty1,ty2,ty;
      ATy raty3,raty1,raty2;
      TCode.BinOp bop;
    case (exp1,PTR(ty1),exp2,PTR(ty2))
      equation
        true = valueEq(ty1, ty2);
        ty_1 = tyCnv(ty1);
      then
        TCode.BINARY(exp1,TCode.PEQ(ty_1),exp2);
    case (exp,PTR(ty),_,PTRNIL())
      equation
        exp_1 = ptrEqNull(exp, ty);
      then
        exp_1;
    case (_,PTRNIL(),exp,PTR(ty))
      equation
        exp_1 = ptrEqNull(exp, ty);
      then
        exp_1;
    case (exp1,ARITH(raty1),exp2,ARITH(raty2))
      equation
        (exp1_1,exp2_1,raty3) = arithCnv(exp1, raty1, exp2, raty2);
        bop = chooseIntReal(raty3, TCode.IEQ(), TCode.REQ());
      then
        TCode.BINARY(exp1_1,bop,exp2_1);
  end matchcontinue;
end eqCnv;

function ptrRelop "Elaborate a function expression.
  The arguments are already elaborated as decayed rvalues.
  Make arguments compatible, if necessary by arithmetic widening.
  Choose int, real, or ptr/ptr version of function operator.
  Return elaborated expression. Result type always int.
"
  input Absyn.RelOp inRelOp;
  input TCode.Ty inTy;
  output TCode.BinOp outBinOp;
algorithm
  outBinOp:=
  matchcontinue (inRelOp,inTy)
    local TCode.Ty ty;
    case (Absyn.LT(),ty) then TCode.PLT(ty);
    case (Absyn.LE(),ty) then TCode.PLE(ty);
  end matchcontinue;
end ptrRelop;

function intRelop
  input Absyn.RelOp inRelOp;
  output TCode.BinOp outBinOp;
algorithm
  outBinOp := matchcontinue (inRelOp)
    case Absyn.LT() then TCode.ILT();
    case Absyn.LE() then TCode.ILE();
  end matchcontinue;
end intRelop;

function realRelop
  input Absyn.RelOp inRelOp;
  output TCode.BinOp outBinOp;
algorithm
  outBinOp:=
  matchcontinue (inRelOp)
    case Absyn.LT() then TCode.RLT();
    case Absyn.LE() then TCode.RLE();
  end matchcontinue;
end realRelop;

function intOrRealRelop
  input ATy inATy;
  input Absyn.RelOp inRelOp;
  output TCode.BinOp outBinOp;
algorithm
  outBinOp:=
  matchcontinue (inATy,inRelOp)
    local
      TCode.BinOp bop;
      Absyn.RelOp rop;
    case (INT(),rop)
      equation
        bop = intRelop(rop);
      then
        bop;
    case (REAL(),rop)
      equation
        bop = realRelop(rop);
      then
        bop;
  end matchcontinue;
end intOrRealRelop;

function relCnv
  input TCode.Exp inExp1;
  input Ty inTy2;
  input Absyn.RelOp inRelOp3;
  input TCode.Exp inExp4;
  input Ty inTy5;
  output TCode.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inTy2,inRelOp3,inExp4,inTy5)
    local
      TCode.Ty ty_1;
      TCode.BinOp bop;
      TCode.Exp exp1,exp2,exp1_1,exp2_1;
      Ty ty1,ty2;
      Absyn.RelOp rop;
      ATy raty3,raty1,raty2;
    case (exp1,PTR(ty1),rop,exp2,PTR(ty2))
      equation
        true = valueEq(ty1, ty2);
        ty_1 = tyCnv(ty1);
        bop = ptrRelop(rop, ty_1);
      then
        TCode.BINARY(exp1,bop,exp2);
    case (exp1,ARITH(raty1),rop,exp2,ARITH(raty2))
      equation
        (exp1_1,exp2_1,raty3) = arithCnv(exp1, raty1, exp2, raty2);
        bop = intOrRealRelop(raty3, rop);
      then
        TCode.BINARY(exp1_1,bop,exp2_1);
  end matchcontinue;
end relCnv;

function ptrAddIntCnv<Type_a> "Elaborate an addition expression.
  The arguments are already elaborated as decayed rvalues.
  Make arguments compatible, if necessary by arithmetic widening.
  Choose int, real, or ptr/int version of the addition operator.
  Return elaborated expression and its type.
"
  input TCode.Exp inExp1;
  input Type_a inTypeA2;
  input Ty inTy3;
  input TCode.Exp inExp4;
  output TCode.Exp outExp;
  output Type_a outTypeA;
algorithm
  (outExp,outTypeA):=
  matchcontinue (inExp1,inTypeA2,inTy3,inExp4)
    local
      TCode.Ty ty1_1;
      TCode.Exp exp1,exp2;
      Type_a ty;
      Ty ty1;
    case (exp1,ty,ty1,exp2)
      equation
        ty1_1 = tyCnv(ty1);
      then
        (TCode.BINARY(exp1,TCode.PADD(ty1_1),exp2),ty);
  end matchcontinue;
end ptrAddIntCnv;

function addCnv
  input TCode.Exp inExp1;
  input Ty inTy2;
  input TCode.Exp inExp3;
  input Ty inTy4;
  output TCode.Exp outExp;
  output Ty outTy;
algorithm
  (outExp,outTy) := matchcontinue (inExp1,inTy2,inExp3,inTy4)
    local
      TCode.Exp exp3,exp1,exp2,exp1_1,exp2_1;
      Ty ty3,ty,ty1,ty2;
      ATy raty3,raty1,raty2;
      TCode.BinOp bop;
    case (exp1,(ty as PTR(ty1)),exp2,ARITH(INT()))
      equation
        (exp3,ty3) = ptrAddIntCnv(exp1, ty, ty1, exp2);
      then
        (exp3,ty3);
    case (exp1,ARITH(INT()),exp2,(ty as PTR(ty2)))
      equation
        (exp3,ty3) = ptrAddIntCnv(exp2, ty, ty2, exp1);
      then
        (exp3,ty3);
    case (exp1,ARITH(raty1),exp2,ARITH(raty2))
      equation
        (exp1_1,exp2_1,raty3) = arithCnv(exp1, raty1, exp2, raty2);
        bop = chooseIntReal(raty3, TCode.IADD(), TCode.RADD());
      then
        (TCode.BINARY(exp1_1,bop,exp2_1),ARITH(raty3));
  end matchcontinue;
end addCnv;

function subCnv "Elaborate a subtraction expression.
  The arguments are already elaborated as decayed rvalues.
  Make arguments compatible, if necessary by arithmetic widening.
  Choose int, real, ptr/int, or ptr/ptr version of the subtraction operator.
  Return elaborated expression and its type.
"
  input TCode.Exp inExp1;
  input Ty inTy2;
  input TCode.Exp inExp3;
  input Ty inTy4;
  output TCode.Exp outExp;
  output Ty outTy;
algorithm
  (outExp,outTy):=
  matchcontinue (inExp1,inTy2,inExp3,inTy4)
    local
      TCode.Ty ty1_1;
      TCode.Exp exp1,exp2,exp1_1,exp2_1;
      Ty ty1,ty2,ty;
      ATy raty3,raty1,raty2;
      TCode.BinOp bop;
    case (exp1,PTR(ty1),exp2,PTR(ty2))
      equation
        true = valueEq(ty1, ty2);
        ty1_1 = tyCnv(ty1);
      then
        (TCode.BINARY(exp1,TCode.PDIFF(ty1_1),exp2),ARITH(INT()));
    case (exp1,(ty as PTR(ty1)),exp2,ARITH(INT()))
      equation
        ty1_1 = tyCnv(ty1);
      then
        (TCode.BINARY(exp1,TCode.PSUB(ty1_1),exp2),ty);
    case (exp1,ARITH(raty1),exp2,ARITH(raty2))
      equation
        (exp1_1,exp2_1,raty3) = arithCnv(exp1, raty1, exp2, raty2);
        bop = chooseIntReal(raty3, TCode.ISUB(), TCode.RSUB());
      then
        (TCode.BINARY(exp1_1,bop,exp2_1),ARITH(raty3));
  end matchcontinue;
end subCnv;

function mulCnv "Elaborate a multiplication expression.
  The arguments are already elaborated as decayed rvalues.
  Make arguments compatible, if necessary by arithmetic widening.
  Choose int or real version of the multiplication operator.
  Return elaborated expression and its type.
"
  input TCode.Exp inExp1;
  input Ty inTy2;
  input TCode.Exp inExp3;
  input Ty inTy4;
  output TCode.Exp outExp;
  output Ty outTy;
algorithm
  (outExp,outTy):=
  matchcontinue (inExp1,inTy2,inExp3,inTy4)
    local
      TCode.Exp exp1_1,exp2_1,exp1,exp2;
      ATy raty3,raty1,raty2;
      TCode.BinOp bop;
    case (exp1,ARITH(raty1),exp2,ARITH(raty2))
      equation
        (exp1_1,exp2_1,raty3) = arithCnv(exp1, raty1, exp2, raty2);
        bop = chooseIntReal(raty3, TCode.IMUL(), TCode.RMUL());
      then
        (TCode.BINARY(exp1_1,bop,exp2_1),ARITH(raty3));
  end matchcontinue;
end mulCnv;

function rdivCnv "Elaborate a real division expression.
  The arguments are already elaborated as decayed rvalues.
  Widen both arguments to reals.
  Return elaborated expression and its type (always real).
"
  input TCode.Exp inExp1;
  input Ty inTy2;
  input TCode.Exp inExp3;
  input Ty inTy4;
  output TCode.Exp outExp;
  output Ty outTy;
algorithm
  (outExp,outTy):=
  matchcontinue (inExp1,inTy2,inExp3,inTy4)
    local
      TCode.Exp exp1_1,exp2_1,exp1,exp2;
      ATy raty1,raty2;
    case (exp1,ARITH(raty1),exp2,ARITH(raty2))
      equation
        exp1_1 = arithWiden(exp1, raty1, REAL());
        exp2_1 = arithWiden(exp2, raty2, REAL());
      then
        (TCode.BINARY(exp1_1,TCode.RDIV(),exp2_1),ARITH(REAL()));
  end matchcontinue;
end rdivCnv;

function intopCnv "Elaborate an integer operator expression.
  The arguments are already elaborated as decayed rvalues.
  Verify arguments. Return elaborated expression and its type (always int).
"
  input TCode.Exp inExp1;
  input Ty inTy2;
  input TCode.BinOp inBinOp3;
  input TCode.Exp inExp4;
  input Ty inTy5;
  output TCode.Exp outExp;
  output Ty outTy;
algorithm
  (outExp,outTy):=
  matchcontinue (inExp1,inTy2,inBinOp3,inExp4,inTy5)
    local
      TCode.Exp exp1,exp2;
      TCode.BinOp bop;
    case (exp1,ARITH(INT()),bop,exp2,ARITH(INT())) then (TCode.BINARY(exp1,bop,exp2),ARITH(INT()));
  end matchcontinue;
end intopCnv;

function binCnv "Elaborate a binary operator expression.
  The arguments are already elaborated as decayed rvalues.
  Return elaborated expression and its type.
"
  input TCode.Exp inExp1;
  input Ty inTy2;
  input Absyn.BinOp inBinOp3;
  input TCode.Exp inExp4;
  input Ty inTy5;
  output TCode.Exp outExp;
  output Ty outTy;
algorithm
  (outExp,outTy):=
  matchcontinue (inExp1,inTy2,inBinOp3,inExp4,inTy5)
    local
      TCode.Exp exp3,exp1,exp2;
      Ty rty3,rty1,rty2;
    case (exp1,rty1,Absyn.ADD(),exp2,rty2)
      equation
        (exp3,rty3) = addCnv(exp1, rty1, exp2, rty2);
      then
        (exp3,rty3);
    case (exp1,rty1,Absyn.SUB(),exp2,rty2)
      equation
        (exp3,rty3) = subCnv(exp1, rty1, exp2, rty2);
      then
        (exp3,rty3);
    case (exp1,rty1,Absyn.MUL(),exp2,rty2)
      equation
        (exp3,rty3) = mulCnv(exp1, rty1, exp2, rty2);
      then
        (exp3,rty3);
    case (exp1,rty1,Absyn.RDIV(),exp2,rty2)
      equation
        (exp3,rty3) = rdivCnv(exp1, rty1, exp2, rty2);
      then
        (exp3,rty3);
    case (exp1,rty1,Absyn.IDIV(),exp2,rty2)
      equation
        (exp3,rty3) = intopCnv(exp1, rty1, TCode.IDIV(), exp2, rty2);
      then
        (exp3,rty3);
    case (exp1,rty1,Absyn.IMOD(),exp2,rty2)
      equation
        (exp3,rty3) = intopCnv(exp1, rty1, TCode.IMOD(), exp2, rty2);
      then
        (exp3,rty3);
    case (exp1,rty1,Absyn.IAND(),exp2,rty2)
      equation
        (exp3,rty3) = intopCnv(exp1, rty1, TCode.IAND(), exp2, rty2);
      then
        (exp3,rty3);
    case (exp1,rty1,Absyn.IOR(),exp2,rty2)
      equation
        (exp3,rty3) = intopCnv(exp1, rty1, TCode.IOR(), exp2, rty2);
      then
        (exp3,rty3);
  end matchcontinue;
end binCnv;
end Types;


package Exp "
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 Exp.rml
  module:      Exp
  description: Expressions
 
  This file contains the module `Exp\', which contains data types for
  describing expressions, after they have been examined by the
  static analyzer in the module `StaticExp\'.  There are of course
  great similarities with the expression types in the `Absyn\'
  module, but there are also several important differences.
 
  No overloading of operators occur, and subscripts have been
  checked to see if they are slices.  All expressions are also type
  consistent, and all implicit type conversions in the AST are made
  explicit here.
 
  Some expression simplification and solving is also done here. This is used
  for symbolic transformations before simulation, in order to rearrange
  equations into a form needed by simulation tools. simplify, solve,
  exp_contains, exp_equal are part of this code.
 
  This module also contains functions for printing expressions, to io or to
  strings. Also graphviz output is supported.
"

public import OpenModelica.Compiler.Absyn;

public import OpenModelica.Compiler.Graphviz;

public 
type Ident = String "- Identifiers 
    Define `Ident\' as an alias for `string\' and use it for all 
    identifiers in Modelica." ;

public 
uniontype Type "- Basic types
    These types are not used as expression types (see the `Types\'
    module for expression types).  They are used to parameterize
    operators which may work on several simple types."
  record INT end INT;

  record REAL end REAL;

  record BOOL end BOOL;

  record STRING end STRING;

  record ENUM end ENUM;

  record OTHER "e.g. complex types, etc." end OTHER;

  record T_ARRAY
    Type ty;
    list<Integer> arrayDimensions "arrayDimensions" ;
  end T_ARRAY;

end Type;

public 
uniontype Exp "Expressions
    The `Exp\' datatype closely corresponds to the `Absyn.Exp\'
    datatype, but is used for statically analyzed expressions.  It
    includes explicit type promotions and typed (non-overloaded)
    operators. It also contains expression indexing with the `ASUB\'
    constructor.  Indexing arbitrary array expressions is currently
    not supported in Modelica, but it is needed here."
  record ICONST
    Integer integer "Integer constants" ;
  end ICONST;

  record RCONST
    Real real "Real constants" ;
  end RCONST;

  record SCONST
    String string "String constants" ;
  end SCONST;

  record BCONST
    Boolean bool "Bool constants" ;
  end BCONST;

  record CREF "component references, e.g. a.b{2}.c{1}"
    ComponentRef componentRef;
    Type ty;
  end CREF;

  record BINARY "Binary operations, e.g. a+4" 
    Exp exp1;
    Operator operator;
    Exp exp2; 
  end BINARY;

  record UNARY "Unary operations, -(4x)"
    Operator operator;
    Exp exp; 
  end UNARY;

  record LBINARY "Logical binary operations: and, or"
    Exp exp1;
    Operator operator;
    Exp exp2; 
  end LBINARY;

  record LUNARY "Logical unary operations: not"
    Operator operator;
    Exp exp; 
  end LUNARY;

  record RELATION "Relation, e.g. a <= 0"
    Exp exp1;
    Operator operator;
    Exp exp2; 
  end RELATION;

  record IFEXP "If expressions" 
    Exp expCond;
    Exp expThen;
    Exp expElse;
  end IFEXP;

  record CALL
    Absyn.Path path;
    list<Exp> expLst;
    Boolean tuple_ "tuple" ;
    Boolean builtin "builtin Function call" ;
  end CALL;

  record ARRAY
    Type ty;
    Boolean scalar "scalar for codegen" ;
    list<Exp> array "Array constructor, e.g. {1,3,4}" ;
  end ARRAY;

  record MATRIX
    Type ty;
    Integer integer;
    list<list<tuple<Exp, Boolean>>> scalar "scalar Matrix constructor. e.g. {1,0;0,1}" ;
  end MATRIX;

  record RANGE
    Type ty;
    Exp exp;
    Option<Exp> expOption;
    Exp range "Range constructor, e.g. 1:0.5:10" ;
  end RANGE;

  record TUPLE
    list<Exp> PR "PR. Tuples, used in func calls returning several 
								  arguments" ;
  end TUPLE;

  record CAST "Cast operator"
    Type ty;
    Exp exp;
  end CAST;

  record ASUB "Array subscripts"
    Exp exp;
    Integer sub;
  end ASUB;

  record SIZE "The size operator"
    Exp exp;
    Option<Exp> sz;
  end SIZE;

  record CODE "Modelica AST constructor"
    Absyn.Code code;
    Type ty;
  end CODE;

  record REDUCTION
    Absyn.Path path;
    Exp expr "expr" ;
    Ident ident;
    Exp range "range Reduction expression" ;
  end REDUCTION;

  record END "array index to last element, e.g. a{end}:=1;" end END;

end Exp;

public 
uniontype Operator "Operators which are overloaded in the abstract syntax are here
    made type-specific.  The integer addition operator (`ADD(INT)\')
    and the real addition operator (`ADD(REAL)\') are two distinct
    operators."
  record ADD
    Type ty;
  end ADD;

  record SUB
    Type ty;
  end SUB;

  record MUL
    Type ty;
  end MUL;

  record DIV
    Type ty;
  end DIV;

  record POW
    Type ty;
  end POW;

  record UMINUS
    Type ty;
  end UMINUS;

  record UPLUS
    Type ty;
  end UPLUS;

  record UMINUS_ARR
    Type ty;
  end UMINUS_ARR;

  record UPLUS_ARR
    Type ty;
  end UPLUS_ARR;

  record ADD_ARR
    Type ty;
  end ADD_ARR;

  record SUB_ARR
    Type ty;
  end SUB_ARR;

  record MUL_SCALAR_ARRAY
    Type ty "a  { b, c }" ;
  end MUL_SCALAR_ARRAY;

  record MUL_ARRAY_SCALAR
    Type ty "{a, b}  c" ;
  end MUL_ARRAY_SCALAR;

  record MUL_SCALAR_PRODUCT
    Type ty "{a, b}  {c, d}" ;
  end MUL_SCALAR_PRODUCT;

  record MUL_MATRIX_PRODUCT
    Type ty "{{..},..}  {{..},{..}}" ;
  end MUL_MATRIX_PRODUCT;

  record DIV_ARRAY_SCALAR
    Type ty "{a, b} / c" ;
  end DIV_ARRAY_SCALAR;

  record POW_ARR
    Type ty;
  end POW_ARR;

  record AND end AND;

  record OR end OR;

  record NOT end NOT;

  record LESS
    Type ty;
  end LESS;

  record LESSEQ
    Type ty;
  end LESSEQ;

  record GREATER
    Type ty;
  end GREATER;

  record GREATEREQ
    Type ty;
  end GREATEREQ;

  record EQUAL
    Type ty;
  end EQUAL;

  record NEQUAL
    Type ty;
  end NEQUAL;

  record USERDEFINED
    Absyn.Path fqName "The FQ name of the overloaded operator function" ;
  end USERDEFINED;

end Operator;

public 
uniontype ComponentRef "- Component references
    CREF_QUAL(...) is used for qualified component names, e.g. a.b.c
    CREF_IDENT(..) is used for non-qualifed component names, e.g. x 
"
  record CREF_QUAL
    Ident ident;
    list<Subscript> subscriptLst;
    ComponentRef componentRef;
  end CREF_QUAL;

  record CREF_IDENT
    Ident ident;
    list<Subscript> subscriptLst;
  end CREF_IDENT;

end ComponentRef;

public 
uniontype Subscript "The `Subscript\' and `ComponentRef\' datatypes are simple
  translations of the corresponding types in the `Absyn\' module."
  record WHOLEDIM "a{:,1}" end WHOLEDIM;

  record SLICE
    Exp exp "a{1:3,1}, a{1:2:10,2}" ;
  end SLICE;

  record INDEX
    Exp exp "a[i+1]" ;
  end INDEX;

end Subscript;

protected import OpenModelica.Compiler.RTOpts;

protected import OpenModelica.Compiler.Util;

protected import OpenModelica.Compiler.Print;

protected import OpenModelica.Compiler.ModUtil;

protected import OpenModelica.Compiler.Derive;

protected import OpenModelica.Compiler.Dump;

protected import OpenModelica.Compiler.Error;

protected import OpenModelica.Compiler.Debug;

protected constant Exp rconstone=RCONST(1.0);

public function crefToPath "function: crefToPath
 
  This function converts a `ComponentRef\' to a `Path\', if possible.
  If the component reference contains subscripts, it will silently
  fail.
"
  input ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm 
  outPath:=
  matchcontinue (inComponentRef)
    local
      Ident i;
      Absyn.Path p;
      ComponentRef c;
    case CREF_IDENT(ident = i,subscriptLst = {}) then Absyn.IDENT(i); 
    case CREF_QUAL(ident = i,subscriptLst = {},componentRef = c)
      equation 
        p = crefToPath(c);
      then
        Absyn.QUALIFIED(i,p);
  end matchcontinue;
end crefToPath;

public function pathToCref "function: pathToCref
 
  This function converts a `Absyn.Path\' to a `ComponentRef\'.
"
  input Absyn.Path inPath;
  output ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inPath)
    local
      Ident i;
      ComponentRef c;
      Absyn.Path p;
    case Absyn.IDENT(name = i) then CREF_IDENT(i,{}); 
    case Absyn.QUALIFIED(name = i,path = p)
      equation 
        c = pathToCref(p);
      then
        CREF_QUAL(i,{},c);
  end matchcontinue;
end pathToCref;

public function crefStr "function: crefStr
 
  This function simply converts a `ComponentRef\' to a `string\'.
"
  input ComponentRef inComponentRef;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef)
    local
      Ident s,ns,s1,ss;
      ComponentRef n;
    case (CREF_IDENT(ident = s)) then s; 
    case (CREF_QUAL(ident = s,componentRef = n))
      equation 
        ns = crefStr(n);
        s1 = stringAppend(s, ".");
        ss = stringAppend(s1, ns);
      then
        ss;
  end matchcontinue;
end crefStr;

public function crefModelicaStr "function: crefModelicaStr
 
  Same as cre_str, but uses \'_\' instead of \'.\' 
"
  input ComponentRef inComponentRef;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef)
    local
      Ident s,ns,s1,ss;
      ComponentRef n;
    case (CREF_IDENT(ident = s)) then s; 
    case (CREF_QUAL(ident = s,componentRef = n))
      equation 
        ns = crefModelicaStr(n);
        s1 = stringAppend(s, "_");
        ss = stringAppend(s1, ns);
      then
        ss;
  end matchcontinue;
end crefModelicaStr;

public function crefLastIdent "function: crefLastIdent
  author: PA
 
  Returns the last identfifier of a \'ComponentRef\'.
"
  input ComponentRef inComponentRef;
  output Ident outIdent;
algorithm 
  outIdent:=
  matchcontinue (inComponentRef)
    local
      Ident id,res;
      ComponentRef cr;
    case (CREF_IDENT(ident = id)) then id; 
    case (CREF_QUAL(componentRef = cr))
      equation 
        res = crefLastIdent(cr);
      then
        res;
  end matchcontinue;
end crefLastIdent;

public function crefLastSubs "function: crefLastSubs
 
  Return the last subscripts of a ComponentRef
"
  input ComponentRef inComponentRef;
  output list<Subscript> outSubscriptLst;
algorithm 
  outSubscriptLst:=
  matchcontinue (inComponentRef)
    local
      Ident id;
      list<Subscript> subs,res;
      ComponentRef cr;
    case (CREF_IDENT(ident = id,subscriptLst = subs)) then subs; 
    case (CREF_QUAL(componentRef = cr))
      equation 
        res = crefLastSubs(cr);
      then
        res;
  end matchcontinue;
end crefLastSubs;

public function crefStripLastSubs "function: crefStripLastSubs
 
  Strips the last subscripts of a ComponentRef
"
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inComponentRef)
    local
      Ident id;
      list<Subscript> subs,s;
      ComponentRef cr_1,cr;
    case (CREF_IDENT(ident = id,subscriptLst = subs)) then CREF_IDENT(id,{}); 
    case (CREF_QUAL(ident = id,subscriptLst = s,componentRef = cr))
      equation 
        cr_1 = crefStripLastSubs(cr);
      then
        CREF_QUAL(id,s,cr_1);
  end matchcontinue;
end crefStripLastSubs;

public function crefStripLastSubsStringified "function crefStripLastSubsStringified
  author: PA
 
  Same as cref_strip_last_subs but works on a stringified component ref
  instead.
"
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inComponentRef)
    local
      list<Ident> lst,lst_1;
      Ident id_1,id;
      ComponentRef cr;
    case (CREF_IDENT(ident = id,subscriptLst = {}))
      equation 
        lst = Util.stringSplitAtChar(id, "[");
        lst_1 = Util.listStripLast(lst);
        id_1 = Util.stringDelimitList(lst_1, "[");
      then
        CREF_IDENT(id_1,{});
    case (cr) then cr; 
  end matchcontinue;
end crefStripLastSubsStringified;

public function crefContainedIn "function: crefContainedIn
  author: PA
 
  Returns true if y is a sub component ref of x.
  For instance, b.c. is a sub_component of a.b.c.
"
  input ComponentRef inComponentRef1;
  input ComponentRef inComponentRef2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef1,inComponentRef2)
    local
      ComponentRef x,y,cr2;
      Boolean res;
    case (x,y) /* x y */ 
      equation 
        true = crefEqual(x, y);
      then
        true;
    case (CREF_QUAL(componentRef = cr2),y)
      equation 
        res = crefContainedIn(y, cr2);
      then
        res;
    case (_,_) then false; 
  end matchcontinue;
end crefContainedIn;

public function crefPrefixOf "function: crefPrefixOf
  author: PA
  
  Returns true if y is a prefix of x
  For example, a.b is a prefix of a.b.c
"
  input ComponentRef inComponentRef1;
  input ComponentRef inComponentRef2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef1,inComponentRef2)
    local
      ComponentRef cr1,cr2;
      Boolean res;
      Ident id1,id2;
      list<Subscript> ss1,ss2;
    case (cr1,cr2) /* x y */ 
      equation 
        true = crefEqual(cr1, cr2);
      then
        true;
    case (CREF_QUAL(ident = id1,subscriptLst = ss1,componentRef = cr1),CREF_QUAL(ident = id2,subscriptLst = ss2,componentRef = cr2))
      equation 
        equality(id1 = id2);
        true = subscriptEqual(ss1, ss2);
        res = crefPrefixOf(cr1, cr2);
      then
        res;
    case (CREF_IDENT(ident = id1,subscriptLst = ss1),CREF_QUAL(ident = id2,subscriptLst = ss2))
      equation 
        equality(id1 = id2);
        res = subscriptEqual(ss1, ss2);
      then
        res;
    case (_,_) then false; 
  end matchcontinue;
end crefPrefixOf;

public function identEqual "function: identEqual
  author: PA
 
  Compares two \'Ident\'.
"
  input Ident inIdent1;
  input Ident inIdent2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inIdent1,inIdent2)
    local Ident id1,id2;
    case (id1,id2)
      equation 
        equality(id1 = id2);
      then
        true;
    case (_,_) then false; 
  end matchcontinue;
end identEqual;

public function isRange "function: isRange
 
  Returns true if expression is a range expression.
"
  input Exp inExp;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp)
    case RANGE(ty = _) then true; 
    case _ then false; 
  end matchcontinue;
end isRange;

public function isOne "function: isOne
 
  Returns true íf an expression is constant and has the value one, 
  otherwise false
"
  input Exp inExp;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp)
    local
      Integer ival;
      Real rzero,rval;
      Boolean res;
      Type t;
      Exp e;
    case (ICONST(integer = ival))
      equation 
        (ival == 1) = true;
      then
        true;
    case (RCONST(real = rval))
      equation 
        rzero = intReal(1) "Due to bug in rml, go trough a cast from int" ;
        (rzero ==. rval) = true;
      then
        true;
    case (CAST(ty = t,exp = e))
      equation 
        res = isOne(e) "Casting to zero is still zero" ;
      then
        res;
    case (_) then false; 
  end matchcontinue;
end isOne;

public function isZero "function: isZero
 
  Returns true íf an expression is constant and has the value zero, 
  otherwise false
"
  input Exp inExp;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp)
    local
      Integer ival;
      Real rzero,rval;
      Boolean res;
      Type t;
      Exp e;
    case (ICONST(integer = ival))
      equation 
        (ival == 0) = true;
      then
        true;
    case (RCONST(real = rval))
      equation 
        rzero = intReal(0) "Due to bug in rml, go trough a cast from int" ;
        (rzero ==. rval) = true;
      then
        true;
    case (CAST(ty = t,exp = e))
      equation 
        res = isZero(e) "Casting to zero is still zero" ;
      then
        res;
    case (_) then false; 
  end matchcontinue;
end isZero;

public function isConst "function: isConst
 
  Returns true íf an expression is constant 
  otherwise false
"
  input Exp inExp;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp)
    local
      Integer ival;
      Real rval;
      Boolean bval,res;
      Ident sval;
      Operator op;
      Exp e;
      Type t;
    case (ICONST(integer = ival)) then true; 
    case (RCONST(real = rval)) then true; 
    case (BCONST(bool = bval)) then true; 
    case (SCONST(string = sval)) then true; 
    case (UNARY(operator = op,exp = e))
      equation 
        res = isConst(e);
      then
        res;
    case (CAST(ty = t,exp = e)) /* Casting to zero is still zero */ 
      equation 
        res = isConst(e);
      then
        res;
    case (_) then false; 
  end matchcontinue;
end isConst;

public function isNotConst "function isNotConst
  author: PA
 
  Check if expression is not constant.
"
  input Exp e;
  output Boolean nb;
  Boolean b;
algorithm 
  b := isConst(e);
  nb := boolNot(b);
end isNotConst;

public function isRelation "function: isRelation
 
  Returns true if expression is a function expression.
"
  input Exp inExp;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp)
    local
      Boolean b1,b2,res;
      Exp e1,e2;
    case (RELATION(exp1 = _)) then true; 
    case (LUNARY(exp = RELATION(exp1 = _))) then true; 
    case (LBINARY(exp1 = e1,exp2 = e2))
      equation 
        b1 = isRelation(e1);
        b2 = isRelation(e2);
        res = boolOr(b1, b2);
      then
        res;
    case (_) then false; 
  end matchcontinue;
end isRelation;

public function getRelations "function: getRelations
 
  Retrieve all function sub expressions in an expression.
"
  input Exp inExp;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inExp)
    local
      Exp e,e1,e2,cond,tb,fb;
      list<Exp> rellst1,rellst2,rellst,rellst3,rellst4,xs;
      Type t;
      Boolean sc;
    case ((e as RELATION(exp1 = _))) then {e}; 
    case (LBINARY(exp1 = e1,exp2 = e2))
      equation 
        rellst1 = getRelations(e1);
        rellst2 = getRelations(e2);
        rellst = listAppend(rellst1, rellst2);
      then
        rellst;
    case (LUNARY(exp = e))
      equation 
        rellst = getRelations(e);
      then
        rellst;
    case (BINARY(exp1 = e1,exp2 = e2))
      equation 
        rellst1 = getRelations(e1);
        rellst2 = getRelations(e2);
        rellst = listAppend(rellst1, rellst2);
      then
        rellst;
    case (IFEXP(expCond = cond,expThen = tb,expElse = fb))
      equation 
        rellst1 = getRelations(cond);
        rellst2 = getRelations(tb);
        rellst3 = getRelations(fb);
        rellst4 = listAppend(rellst1, rellst2);
        rellst = listAppend(rellst3, rellst4);
      then
        rellst;
    case (ARRAY(array = {e}))
      equation 
        rellst = getRelations(e);
      then
        rellst;
    case (ARRAY(ty = t,scalar = sc,array = (e :: xs)))
      equation 
        rellst1 = getRelations(ARRAY(t,sc,xs));
        rellst2 = getRelations(e);
        rellst = listAppend(rellst1, rellst2);
      then
        rellst;
    case (UNARY(exp = e))
      equation 
        rellst = getRelations(e);
      then
        rellst;
    case (_) then {}; 
  end matchcontinue;
end getRelations;

public function joinCrefs "function: joinCrefs
 
  Join two component references by concatenating them.
"
  input ComponentRef inComponentRef1;
  input ComponentRef inComponentRef2;
  output ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inComponentRef1,inComponentRef2)
    local
      Ident id;
      list<Subscript> sub;
      ComponentRef cr2,cr_1,cr;
    case (CREF_IDENT(ident = id,subscriptLst = sub),cr2) then CREF_QUAL(id,sub,cr2); 
    case (CREF_QUAL(ident = id,subscriptLst = sub,componentRef = cr),cr2)
      equation 
        cr_1 = joinCrefs(cr, cr2);
      then
        CREF_QUAL(id,sub,cr_1);
  end matchcontinue;
end joinCrefs;

public function crefEqual "function: crefEqual
 
  Returns true if two component references are equal
"
  input ComponentRef inComponentRef1;
  input ComponentRef inComponentRef2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef1,inComponentRef2)
    local
      Ident n1,n2,s1,s2;
      list<Subscript> idx1,idx2;
      ComponentRef cr1,cr2;
    case (CREF_IDENT(ident = n1,subscriptLst = idx1),CREF_IDENT(ident = n2,subscriptLst = idx2))
      equation 
        equality(n1 = n2);
        true = subscriptEqual(idx1, idx2);
      then
        true;
    case (CREF_QUAL(ident = n1,subscriptLst = idx1,componentRef = cr1),CREF_QUAL(ident = n2,subscriptLst = idx2,componentRef = cr2))
      equation 
        equality(n1 = n2);
        true = crefEqual(cr1, cr2);
        true = subscriptEqual(idx1, idx2);
      then
        true;
    case (cr1,cr2)
      equation 
        s1 = printComponentRefStr(cr1) "There is a bug here somewhere or in RML.
	  Therefore as a last resort, print the strings and compare.
	" ;
        s2 = printComponentRefStr(cr2);
        equality(s1 = s2);
      then
        true;
    case (_,_) then false; 
  end matchcontinue;
end crefEqual;

public function crefEqualReturn "function: crefEqualReturn
  author: PA
 
  Checks if two crefs are equal and if so returns the cref,
  otherwise fail.
"
  input ComponentRef cr;
  input ComponentRef cr2;
  output ComponentRef cr;
algorithm 
  true := crefEqual(cr, cr2);
end crefEqualReturn;

public function subscriptExp "function: subscriptExp
 
  Returns the expression in a subscript index. If the subscript is not 
  an index the function fails.x
"
  input Subscript inSubscript;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inSubscript)
    local Exp e;
    case (INDEX(exp = e)) then e; 
  end matchcontinue;
end subscriptExp;

protected function subscriptEqual "function: subscriptEqual
  
  Returns true if two subscript lists are equal.
"
  input list<Subscript> inSubscriptLst1;
  input list<Subscript> inSubscriptLst2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inSubscriptLst1,inSubscriptLst2)
    local
      Boolean res;
      list<Subscript> xs1,xs2;
      Exp e1,e2;
    case ({},{}) then true; 
    case ((WHOLEDIM() :: xs1),(WHOLEDIM() :: xs2))
      equation 
        res = subscriptEqual(xs1, xs2);
      then
        res;
    case ((SLICE(exp = e1) :: xs1),(SLICE(exp = e2) :: xs2))
      equation 
        true = expEqual(e1, e2);
        res = subscriptEqual(xs1, xs2);
      then
        res;
    case ((INDEX(exp = e1) :: xs1),(INDEX(exp = e2) :: xs2))
      equation 
        true = expEqual(e1, e2);
        res = subscriptEqual(xs1, xs2);
      then
        res;
    case (_,_) then false; 
  end matchcontinue;
end subscriptEqual;

public function prependStringCref "function: prependStringCref
 
  Prepend a string to a component reference.
  For qualified named, this means prepending a string to the 
  first identifier.
"
  input String inString;
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inString,inComponentRef)
    local
      Ident i_1,p,i;
      list<Subscript> s;
      ComponentRef c;
    case (p,CREF_QUAL(ident = i,subscriptLst = s,componentRef = c))
      equation 
        i_1 = stringAppend(p, i);
      then
        CREF_QUAL(i_1,s,c);
    case (p,CREF_IDENT(ident = i,subscriptLst = s))
      equation 
        i_1 = stringAppend(p, i);
      then
        CREF_IDENT(i_1,s);
  end matchcontinue;
end prependStringCref;

public function extendCref "function: extendCref
 
  The `extend_cref\' function extends a `ComponentRef\' by appending
  an identifier and a (possibly empty) list of subscripts.  Adding
  the identifier `a\' to the component reference `x.y{10}\' would
  produce the component reference `x.y{10}.a\', for instance.
"
  input ComponentRef inComponentRef;
  input Ident inIdent;
  input list<Subscript> inSubscriptLst;
  output ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inComponentRef,inIdent,inSubscriptLst)
    local
      Ident i1,i;
      list<Subscript> s1,s;
      ComponentRef c_1,c;
    case (CREF_IDENT(ident = i1,subscriptLst = s1),i,s) then CREF_QUAL(i1,s1,CREF_IDENT(i,s)); 
    case (CREF_QUAL(ident = i1,subscriptLst = s1,componentRef = c),i,s)
      equation 
        c_1 = extendCref(c, i, s);
      then
        CREF_QUAL(i1,s1,c_1);
  end matchcontinue;
end extendCref;

public function subscriptCref "function: subscriptCref
 
  The \'subscript_cref\' function adds a subscript to the \'ComponentRef\'
  For instance \'a.b\' with subscript 10 becomes \'a.b{10} and \'c.d{1,2} with subscript 
  3,4 becomes \'c.d{1,2,3,4}\' 
"
  input ComponentRef inComponentRef;
  input list<Subscript> inSubscriptLst;
  output ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inComponentRef,inSubscriptLst)
    local
      list<Subscript> newsub_1,sub,newsub;
      Ident id;
      ComponentRef cref_1,cref;
    case (CREF_IDENT(ident = id,subscriptLst = sub),newsub)
      equation 
        newsub_1 = listAppend(sub, newsub);
      then
        CREF_IDENT(id,newsub_1);
    case (CREF_QUAL(ident = id,subscriptLst = sub,componentRef = cref),newsub)
      equation 
        cref_1 = subscriptCref(cref, newsub);
      then
        CREF_QUAL(id,sub,cref_1);
  end matchcontinue;
end subscriptCref;

public function intSubscripts "- Utility functions
 
  These are utility functions used in some of the other
  functions.
  function: intSubscripts
 
  This function describes the function between a list of integers
  and a list of `Exp.Subscript\' where each integer is converted to
  an integer indexing expression.
"
  input list<Integer> inIntegerLst;
  output list<Subscript> outSubscriptLst;
algorithm 
  outSubscriptLst:=
  matchcontinue (inIntegerLst)
    local
      list<Subscript> xs_1;
      Integer x;
      list<Integer> xs;
    case {} then {}; 
    case (x :: xs)
      equation 
        xs_1 = intSubscripts(xs);
      then
        (INDEX(ICONST(x)) :: xs_1);
  end matchcontinue;
end intSubscripts;

public function subscriptsInt "function: subscriptsInt
  author: PA
 
  This function creates a list of ints from a subscript list,
  see also int_subscripts.
"
  input list<Subscript> inSubscriptLst;
  output list<Integer> outIntegerLst;
algorithm 
  outIntegerLst:=
  matchcontinue (inSubscriptLst)
    local
      list<Integer> xs_1;
      Integer x;
      list<Subscript> xs;
    case {} then {}; 
    case (INDEX(exp = ICONST(integer = x)) :: xs)
      equation 
        xs_1 = subscriptsInt(xs);
      then
        (x :: xs_1);
  end matchcontinue;
end subscriptsInt;

public function simplify "function: simplify
 
  This function does some very basic simplification on expressions.
  It is not intended to be used to simplify expressions provided by
  the model, but to simplify unnecessarily complex expressions
  constructed during instantiation. 
  PA. Added rules for binary, unary operations
  and multiplication with zero, addition with zero, etc. Useful when deriving 
  equations and then want to simplify
"
  input Exp inExp;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp)
    local
      Real v,rv;
      Integer n,i_1,i;
      Exp e,res,exp,c,f,t_1,f_1,e1_1,exp_1,e1,e_1,e2,e2_1,exp_2,exp_3,e3_1,e3;
      Type t,tp_1,tp,tp1,tp2,t1;
      Boolean b,remove_if;
      list<Exp> exps,exps_1,expl_1;
      list<tuple<Exp, Boolean>> expl;
      list<Boolean> bls;
      list<Subscript> s,s_1;
      ComponentRef c_1;
      Operator op;
      String before, after;
    case (CAST(ty = REAL(),exp = RCONST(real = v))) then RCONST(v); 
    case (CAST(ty = REAL(),exp = e))
      local Integer v;
      equation 
        ICONST(v) = simplify(e);
        rv = intReal(v);
      then
        RCONST(rv);
    case (CAST(ty = tp,exp = e)) /* cast of array */ 
      equation 
        ARRAY(t,b,exps) = simplify(e);
        tp_1 = unliftArray(tp);
        exps_1 = Util.listMap1(exps, addCast, tp_1);
        res = simplify(ARRAY(t,b,exps_1));
      then
        res;
    case (CAST(ty = tp,exp = e))
      local list<list<tuple<Exp, Boolean>>> exps,exps_1;
      equation 
        MATRIX(t,n,exps) = simplify(e);
        tp1 = unliftArray(tp);
        tp2 = unliftArray(tp);
        exps_1 = matrixExpMap1(exps, addCast, tp2);
        res = simplify(MATRIX(t,n,exps_1));
      then
        res;
    case ASUB(exp = e,sub = i) /* Array and Matrix stuff */ 
      equation 
        ARRAY(t,b,exps) = simplify(e);
        i_1 = i - 1;
        exp = listNth(exps, i_1);
      then
        exp;
    case ASUB(exp = e,sub = i)
      local list<list<tuple<Exp, Boolean>>> exps;
      equation 
        MATRIX(t,n,exps) = simplify(e);
        t1 = unliftArray(t);
        i_1 = i - 1;
        (expl) = listNth(exps, i_1);
        (expl_1,bls) = Util.splitTuple2List(expl);
        b = Util.boolAndList(bls);
      then
        ARRAY(t1,b,expl_1);
    case ASUB(exp = e,sub = i)
      local Exp t;
      equation 
        IFEXP(c,t,f) = simplify(e);
        t_1 = simplify(ASUB(t,i));
        f_1 = simplify(ASUB(f,i));
      then
        IFEXP(c,t_1,f_1);
    case ASUB(exp = e,sub = i)
      local Ident n;
      equation 
        CREF(CREF_IDENT(n,s),t) = simplify(e);
        s_1 = subscriptsAppend(s, i);
      then
        CREF(CREF_IDENT(n,s_1),t);
    case ASUB(exp = e,sub = i)
      local
        Ident n;
        ComponentRef c;
      equation 
        CREF(CREF_QUAL(n,s,c),t) = simplify(e);
        CREF(c_1,t) = simplify(ASUB(CREF(c,t),i));
      then
        CREF(CREF_QUAL(n,s,c_1),t);
    case ASUB(exp = e,sub = i)
      equation 
        e = simplifyAsub(e, i) "For arbitrary vector operations, e.g (a+b-c){1} => a{1}+b{1}-c{1}" ;
      then
        e;
    case ((exp as UNARY(operator = op,exp = e1))) /* Operations */ 
      equation 
        e1_1 = simplify(e1);
        exp_1 = UNARY(op,e1_1);
        e = simplifyUnary(exp_1, op, e1_1);
      then
        e;
    case ((exp as BINARY(exp1 = e1,operator = op,exp2 = e2))) /* binary array and matrix expressions */ 
      equation 
        e_1 = simplifyBinaryArray(e1, op, e2);
      then
        e_1;
    case ((exp as BINARY(exp1 = e1,operator = op,exp2 = e2))) /* binary scalar simplifications */ 
      equation
        e1_1 = simplify(e1);
        e2_1 = simplify(e2);        
        exp_1 = BINARY(e1_1,op,e2_1);
        exp_2 = simplifyBinarySortConstants(exp_1);
        exp_3 = trySimplifyBinary(exp_2);        
        e_1 = simplifyBinaryCoeff(exp_3);        
      then
        e_1;
    case ((exp as RELATION(exp1 = e1,operator = op,exp2 = e2)))
      equation 
        e1_1 = simplify(e1);
        e2_1 = simplify(e2);
        exp_1 = RELATION(e1_1,op,e2_1);
        e = simplifyBinary(exp_1, op, e1_1, e2_1);
      then
        e;
    case ((exp as LUNARY(operator = op,exp = e1)))
      equation 
        e1_1 = simplify(e1);
        exp_1 = LUNARY(op,e1_1);
        e = simplifyUnary(exp_1, op, e1_1);
      then
        e;
    case ((exp as LBINARY(exp1 = e1,operator = op,exp2 = e2)))
      equation 
        e1_1 = simplify(e1);
        e2_1 = simplify(e2);
        exp_1 = LBINARY(e1_1,op,e2_1);
        e = simplifyBinary(exp_1, op, e1_1, e2_1);
      then
        e;
    case (IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation 
        e1_1 = simplify(e1);
        e2_1 = simplify(e2);
        e3_1 = simplify(e3);
        remove_if = expEqual(e2, e3);
        res = Util.if_(remove_if, e2_1, IFEXP(e1,e2_1,e3_1));
      then
        res;
    case e then e; 
  end matchcontinue;
end simplify;

protected function simplifyBinaryArray "function: simplifyBinaryArray
 
  Simplifies binary array expressions, e.g. matrix multiplication, etc.
"
  input Exp inExp1;
  input Operator inOperator2;
  input Exp inExp3;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inOperator2,inExp3)
    local
      Exp e_1,e1,e2,res,s1,a1;
      Type tp;
    case (e1,MUL_MATRIX_PRODUCT(ty = tp),e2)
      equation 
        e_1 = simplifyMatrixProduct(e1, e2);
      then
        e_1;
    case (e1,ADD_ARR(ty = _),e2)
      equation 
        tp = typeof(e1);
        res = simplifyVectorBinary(e1, ADD(tp), e2);
      then
        res;
    case (e1,SUB_ARR(ty = _),e2)
      equation 
        tp = typeof(e1);
        res = simplifyVectorBinary(e1, SUB(tp), e2);
      then
        res;
    case (s1,MUL_SCALAR_ARRAY(ty = tp),a1)
      equation 
        tp = typeof(s1);
        res = simplifyVectorScalar(s1, MUL(tp), a1);
      then
        res;
    case (a1,MUL_ARRAY_SCALAR(ty = tp),s1)
      equation 
        tp = typeof(s1);
        res = simplifyVectorScalar(s1, MUL(tp), a1);
      then
        res;
    case (a1,DIV_ARRAY_SCALAR(ty = tp),s1)
      equation 
        tp = typeof(s1);
        res = simplifyVectorScalar(s1, DIV(tp), a1);
      then
        res;
    case (e1,MUL_SCALAR_PRODUCT(ty = tp),e2)
      equation 
        res = simplifyScalarProduct(e1, e2);
      then
        res;
    case (e1,MUL_MATRIX_PRODUCT(ty = tp),e2)
      equation 
        res = simplifyScalarProduct(e1, e2);
      then
        res;
  end matchcontinue;
end simplifyBinaryArray;

protected function simplifyScalarProduct "function: simplifyScalarProduct
  author: PA
  
  Simplifies scalar product: v1v2, M  v1 and v1  M 
  for vectors v1,v2 and matrix M.
"
  input Exp inExp1;
  input Exp inExp2;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inExp2)
    local
      list<Exp> expl,expl1,expl2,expl_1;
      Exp exp;
      Type tp1,tp2,tp;
      Boolean sc1,sc2,sc;
      Integer size1,size;
    case (ARRAY(ty = tp1,scalar = sc1,array = expl1),ARRAY(ty = tp2,scalar = sc2,array = expl2)) /* v1  v2 */ 
      equation 
        expl = Util.listThreadMap(expl1, expl2, expMul);
        exp = Util.listReduce(expl, expAdd);
      then
        exp;
    case (MATRIX(ty = tp,integer = size1,scalar = expl1),ARRAY(ty = tp2,scalar = sc,array = expl2))
      local list<list<tuple<Exp, Boolean>>> expl1;
      equation 
        expl_1 = simplifyScalarProductMatrixVector(expl1, expl2);
      then
        ARRAY(tp2,sc,expl_1);
    case (ARRAY(ty = tp1,scalar = sc,array = expl1),MATRIX(ty = tp2,integer = size,scalar = expl2))
      local list<list<tuple<Exp, Boolean>>> expl2;
      equation 
        expl_1 = simplifyScalarProductVectorMatrix(expl1, expl2);
      then
        ARRAY(tp2,sc,expl_1);
  end matchcontinue;
end simplifyScalarProduct;

protected function simplifyScalarProductMatrixVector "function: simplifyScalarProductMatrixVector
 
  
  Simplifies scalar product of matrix  vector.
"
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst;
  input list<Exp> inExpLst;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inTplExpBooleanLstLst,inExpLst)
    local
      list<Exp> row_1,expl,res,v1;
      Exp exp;
      list<tuple<Exp, Boolean>> row;
      list<list<tuple<Exp, Boolean>>> rows;
    case ({},_) then {}; 
    case ((row :: rows),v1)
      equation 
        row_1 = Util.listMap(row, Util.tuple21);
        expl = Util.listThreadMap(row_1, v1, expMul);
        exp = Util.listReduce(expl, expAdd);
        res = simplifyScalarProductMatrixVector(rows, v1);
      then
        (exp :: res);
  end matchcontinue;
end simplifyScalarProductMatrixVector;

protected function simplifyScalarProductVectorMatrix "function: simplifyScalarProductVectorMatrix
 
  
  Simplifies scalar product of vector  matrix 
"
  input list<Exp> inExpLst;
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inExpLst,inTplExpBooleanLstLst)
    local
      list<Exp> row_1,expl,res,v1;
      Exp exp;
      list<tuple<Exp, Boolean>> row;
      list<list<tuple<Exp, Boolean>>> rows;
    case ({},_) then {}; 
    case (v1,(row :: rows))
      equation 
        row_1 = Util.listMap(row, Util.tuple21);
        expl = Util.listThreadMap(v1, row_1, expMul);
        exp = Util.listReduce(expl, expAdd);
        res = simplifyScalarProductVectorMatrix(v1, rows);
      then
        (exp :: res);
  end matchcontinue;
end simplifyScalarProductVectorMatrix;

protected function simplifyVectorScalar "function: simplifyVectorScalar
 
  Simplifies vector scalar operations.
"
  input Exp inExp1;
  input Operator inOperator2;
  input Exp inExp3;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inOperator2,inExp3)
    local
      Exp s1,e1;
      Operator op;
      Type tp;
      Boolean sc;
      list<Exp> es_1,es;
    case (s1,op,ARRAY(ty = tp,scalar = sc,array = {e1})) then ARRAY(tp,sc,{BINARY(s1,op,e1)});  /* scalar resulting operator array */ 
    case (s1,op,ARRAY(ty = tp,scalar = sc,array = (e1 :: es)))
      equation 
        ARRAY(_,_,es_1) = simplifyVectorScalar(s1, op, ARRAY(tp,sc,es));
      then
        ARRAY(tp,sc,(BINARY(s1,op,e1) :: es_1));
  end matchcontinue;
end simplifyVectorScalar;

protected function simplifyVectorBinary "function: simlify_binary_array
  author: PA
 
  Simplifies vector addition and subtraction
"
  input Exp inExp1;
  input Operator inOperator2;
  input Exp inExp3;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inOperator2,inExp3)
    local
      Type tp1,tp2;
      Boolean scalar1,scalar2;
      Exp e1,e2;
      Operator op;
      list<Exp> es_1,es1,es2;
    case (ARRAY(ty = tp1,scalar = scalar1,array = {e1}),op,ARRAY(ty = tp2,scalar = scalar2,array = {e2})) then ARRAY(tp1,scalar1,{BINARY(e1,op,e2)});  /* resulting operator */ 
    case (ARRAY(ty = tp1,scalar = scalar1,array = (e1 :: es1)),op,ARRAY(ty = tp2,scalar = scalar2,array = (e2 :: es2)))
      equation 
        ARRAY(_,_,es_1) = simplifyVectorBinary(ARRAY(tp1,scalar1,es1), op, ARRAY(tp2,scalar2,es2));
      then
        ARRAY(tp1,scalar1,(BINARY(e1,op,e2) :: es_1));
  end matchcontinue;
end simplifyVectorBinary;

protected function simplifyMatrixProduct "function: simplifyMatrixProduct
  author: PA
  
  Simplifies matrix products A  B for matrices A and B.
"
  input Exp inExp1;
  input Exp inExp2;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inExp2)
    local
      list<list<tuple<Exp, Boolean>>> expl_1,expl1,expl2;
      Type tp1,tp2;
      Integer size1,size2;
    case (MATRIX(ty = tp1,integer = size1,scalar = expl1),MATRIX(ty = tp2,integer = size2,scalar = expl2)) /* A B */ 
      equation 
        expl_1 = simplifyMatrixProduct2(expl1, expl2);
      then
        MATRIX(tp1,size1,expl_1);
  end matchcontinue;
end simplifyMatrixProduct;

protected function simplifyMatrixProduct2 "function: simplifyMatrixProduct2
  author: PA
  
  Helper function to simplify_matrix_product.
"
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst1;
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst2;
  output list<list<tuple<Exp, Boolean>>> outTplExpBooleanLstLst;
algorithm 
  outTplExpBooleanLstLst:=
  matchcontinue (inTplExpBooleanLstLst1,inTplExpBooleanLstLst2)
    local
      list<tuple<Exp, Boolean>> res1,e1lst;
      list<list<tuple<Exp, Boolean>>> res2,rest1,m2;
    case ((e1lst :: rest1),m2)
      equation 
        res1 = simplifyMatrixProduct3(e1lst, m2);
        res2 = simplifyMatrixProduct2(rest1, m2);
      then
        (res1 :: res2);
    case ({},_) then {}; 
  end matchcontinue;
end simplifyMatrixProduct2;

protected function simplifyMatrixProduct3 "function: simplifyMatrixProduct3
  author: PA
 
  Helper function to simplify_matrix_product2. Extract each column at
  a time from the second matrix to calculate vector products with the first
  argument.
"
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst;
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst;
  output list<tuple<Exp, Boolean>> outTplExpBooleanLst;
algorithm 
  outTplExpBooleanLst:=
  matchcontinue (inTplExpBooleanLst,inTplExpBooleanLstLst)
    local
      list<tuple<Exp, Boolean>> first_col,es,expl;
      list<list<tuple<Exp, Boolean>>> mat_1,mat;
      Exp e_1;
      Type tp;
      Boolean builtin;
    case ({},_) then {}; 
    case (expl,mat)
      equation 
        first_col = Util.listMap(mat, Util.listFirst);
        mat_1 = Util.listMap(mat, Util.listRest);
        e_1 = simplifyMatrixProduct4(expl, first_col);
        tp = typeof(e_1);
        builtin = typeBuiltin(tp);
        es = simplifyMatrixProduct3(expl, mat_1);
      then
        ((e_1,builtin) :: es);
    case (_,_) then {}; 
  end matchcontinue;
end simplifyMatrixProduct3;

protected function simplifyMatrixProduct4 "function simplifyMatrixProduct4 
  author: PA
 
  Helper function to simplify_matrix3, performs a scalar mult of vectors
"
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst1;
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst2;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inTplExpBooleanLst1,inTplExpBooleanLst2)
    local
      Type tp,tp_1;
      Exp e1,e2,e,res;
      list<tuple<Exp, Boolean>> es1,es2;
    case ({(e1,_)},{(e2,_)})
      equation 
        tp = typeof(e1);
        tp_1 = arrayEltType(tp);
      then
        BINARY(e1,MUL(tp_1),e2);
    case (((e1,_) :: es1),((e2,_) :: es2))
      equation 
        e = simplifyMatrixProduct4(es1, es2);
        tp = typeof(e);
        tp_1 = arrayEltType(tp);
        res = simplify(BINARY(BINARY(e1,MUL(tp_1),e2),ADD(tp_1),e));
      then
        res;
  end matchcontinue;
end simplifyMatrixProduct4;

protected function addCast "function: addCast
 
  Adds a cast of a Type to an expression.
"
  input Exp inExp;
  input Type inType;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp,inType)
    local
      Exp e;
      Type tp;
    case (e,tp) then CAST(tp,e); 
  end matchcontinue;
end addCast;

protected function simplifyBinarySortConstants "function: simplifyBinarySortConstants
  author: PA
 
  Sorts all constants of a sum or product to the beginning of the expression.
  Also combines expressions like 2a+4a and aaa+3a^3.
"
  input Exp inExp;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp)
    local
      list<Exp> e_lst,e_lst_1,const_es1,notconst_es1,const_es1_1,e_lst_2;
      Exp res,e,e1,e2;
      Type tp;
    case ((e as BINARY(exp1 = e1,operator = MUL(ty = tp),exp2 = e2)))
      equation 
        e_lst = factors(e);
        e_lst_1 = Util.listMap(e_lst, simplify);
        const_es1 = Util.listSelect(e_lst_1, isConst);
        notconst_es1 = Util.listSelect(e_lst_1, isNotConst);
        const_es1_1 = simplifyBinaryMulConstants(const_es1);
        e_lst_2 = listAppend(const_es1_1, notconst_es1);
        res = makeProduct(e_lst_2);
      then
        res;
    case ((e as BINARY(exp1 = e1,operator = ADD(ty = tp),exp2 = e2)))
      equation 
        e_lst = terms(e);
        e_lst_1 = Util.listMap(e_lst, simplify);
        const_es1 = Util.listSelect(e_lst_1, isConst);
        notconst_es1 = Util.listSelect(e_lst_1, isNotConst);
        const_es1_1 = simplifyBinaryAddConstants(const_es1);
        e_lst_2 = listAppend(const_es1_1, notconst_es1);
        res = makeSum(e_lst_2);
      then
        res;
    case (e) then e; 
  end matchcontinue;
end simplifyBinarySortConstants;

protected function simplifyBinaryCoeff "function: simplifyBinaryCoeff
  author: PA
 
  Combines expressions like 2a+4a and aaa+3a^3, etc
"
  input Exp inExp;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp)
    local
      list<Exp> e_lst,e_lst_1,e1_lst,e2_lst,e2_lst_1;
      Exp res,e,e1,e2;
      Type tp;
    case ((e as BINARY(exp1 = e1,operator = MUL(ty = tp),exp2 = e2)))
      equation 
        e_lst = factors(e);
        e_lst_1 = simplifyMul(e_lst);
        res = makeProduct(e_lst_1);
      then
        res;
    case ((e as BINARY(exp1 = e1,operator = DIV(ty = tp),exp2 = e2)))
      equation 
        e1_lst = factors(e1);
        e2_lst = factors(e2);
        e2_lst_1 = inverseFactors(e2_lst);
        e_lst = listAppend(e1_lst, e2_lst_1);
        e_lst_1 = simplifyMul(e_lst);
        res = makeProduct(e_lst_1);
      then
        res;
    case ((e as BINARY(exp1 = e1,operator = ADD(ty = tp),exp2 = e2)))
      equation 
        e_lst = terms(e);
        e_lst_1 = simplifyAdd(e_lst);
        res = makeSum(e_lst_1);
      then
        res;
    case (e) then e; 
  end matchcontinue;
end simplifyBinaryCoeff;

protected function trySimplifyBinary "function: trySimplifyBinary
  author: PA
 
  Helper function to simplify. Tries to call simplify binary.
"
  input Exp inExp;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp)
    local
      Exp res,e,e1,e2;
      Operator op;
    case ((e as BINARY(exp1 = e1,operator = op,exp2 = e2)))
      equation 
        res = simplifyBinary(e, op, e1, e2);
      then
        res;
    case (e) then e; 
  end matchcontinue;
end trySimplifyBinary;

protected function simplifyBinaryAddConstants "function: simplifyBinaryAddConstants
  author: PA
 
  Adds all expressions in the list, given that they are constant.
"
  input list<Exp> inExpLst;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inExpLst)
    local
      Exp e,e_1,e1;
      list<Exp> es;
    case ({}) then {}; 
    case ({e}) then {e}; 
    case ((e1 :: es))
      equation 
        {e} = simplifyBinaryAddConstants(es);
        e_1 = simplifyBinaryConst(ADD(REAL()), e1, e);
      then
        {e_1};
    case (_)
      equation 
        print("simplify_binary_add_constants failed\n");
      then
        fail();
  end matchcontinue;
end simplifyBinaryAddConstants;

protected function simplifyBinaryMulConstants "function: simplify_binary_add_constants
  author: PA
 
  Multiplies all expressions in the list, given that they are constant.
"
  input list<Exp> inExpLst;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inExpLst)
    local
      Exp e,e_1,e1;
      list<Exp> es;
    case ({}) then {}; 
    case ({e}) then {e}; 
    case ((e1 :: es))
      equation 
        {e} = simplifyBinaryMulConstants(es);
        e_1 = simplifyBinaryConst(MUL(REAL()), e1, e);
      then
        {e_1};
  end matchcontinue;
end simplifyBinaryMulConstants;

protected function simplifyMul "function: simplifyMul
  author: PA
 
  Simplifies expressions like aaababa
"
  input list<Exp> expl;
  output list<Exp> expl_1;
  list<Ident> sl;
  Ident s;
  list<tuple<Exp, Real>> exp_const,exp_const_1;
  list<Exp> expl_1;
algorithm 
  sl := Util.listMap(expl, printExpStr);
  s := Util.stringDelimitList(sl, ", ");
  exp_const := simplifyMul2(expl);
  exp_const_1 := simplifyMulJoinFactors(exp_const);
  expl_1 := simplifyMulMakePow(exp_const_1);
end simplifyMul;

protected function simplifyMul2 "function: simplifyMul2
  author: PA
  
  Helper function to simplify_mul.
"
  input list<Exp> inExpLst;
  output list<tuple<Exp, Real>> outTplExpRealLst;
algorithm 
  outTplExpRealLst:=
  matchcontinue (inExpLst)
    local
      Exp e_1,e;
      Real coeff;
      list<tuple<Exp, Real>> rest;
      list<Exp> es;
    case ({}) then {}; 
    case ((e :: es))
      equation 
        (e_1,coeff) = simplifyBinaryMulCoeff2(e);
        rest = simplifyMul2(es);
      then
        ((e_1,coeff) :: rest);
  end matchcontinue;
end simplifyMul2;

protected function simplifyMulJoinFactors "function: simplifyMulJoinFactors
 author: PA
 
  Helper function to simplify_mul. Joins expressions that have the same
  base. E.g. {(a,2), (a,4),(b,2)} => {(a,6),(b,2)}
"
  input list<tuple<Exp, Real>> inTplExpRealLst;
  output list<tuple<Exp, Real>> outTplExpRealLst;
algorithm 
  outTplExpRealLst:=
  matchcontinue (inTplExpRealLst)
    local
      Real coeff2,coeff_1,coeff;
      list<tuple<Exp, Real>> rest_1,res,rest;
      Exp e;
    case ({}) then {}; 
    case (((e,coeff) :: rest))
      equation 
        (coeff2,rest_1) = simplifyMulJoinFactorsFind(e, rest);
        res = simplifyMulJoinFactors(rest_1);
        coeff_1 = coeff +. coeff2;
      then
        ((e,coeff_1) :: res);
  end matchcontinue;
end simplifyMulJoinFactors;

protected function simplifyMulJoinFactorsFind "function: simplifyMulJoinFactorsFind
  author: PA
 
  Helper function to simplify_mul_join_factors. Searches rest of list
  to find all occurences of a base.
"
  input Exp inExp;
  input list<tuple<Exp, Real>> inTplExpRealLst;
  output Real outReal;
  output list<tuple<Exp, Real>> outTplExpRealLst;
algorithm 
  (outReal,outTplExpRealLst):=
  matchcontinue (inExp,inTplExpRealLst)
    local
      Real coeff2,coeff3,coeff;
      list<tuple<Exp, Real>> res,rest;
      Exp e,e2,e1;
      Type tp;
    case (_,{}) then (0.0,{}); 
    case (e,((e2,coeff) :: rest)) /* e1 == e2 */ 
      equation 
        true = expEqual(e, e2);
        (coeff2,res) = simplifyMulJoinFactorsFind(e, rest);
        coeff3 = coeff +. coeff2;
      then
        (coeff3,res);
    case (e,((BINARY(exp1 = e1,operator = SUB(ty = tp),exp2 = e2),coeff) :: rest)) /* e11-e12 and e12-e11, negative -1.0 factor */ 
      equation 
        true = expEqual(e, BINARY(e2,SUB(tp),e1));
        (coeff2,res) = simplifyMulJoinFactorsFind(e, rest);
        coeff3 = coeff -. coeff2;
      then
        (coeff3,res);
    case (e,((e2,coeff) :: rest)) /* not exp_equal */ 
      equation 
        (coeff2,res) = simplifyMulJoinFactorsFind(e, rest);
      then
        (coeff2,((e2,coeff) :: res));
  end matchcontinue;
end simplifyMulJoinFactorsFind;

protected function simplifyMulMakePow "function: simplifyMulMakePow
  author: PA
  
  Helper function to simplify_mul. Makes each item in the list into
  a pow expression, except when exponent is 1.0.
"
  input list<tuple<Exp, Real>> inTplExpRealLst;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inTplExpRealLst)
    local
      list<Exp> res;
      Exp e;
      Real r;
      list<tuple<Exp, Real>> xs;
    case ({}) then {}; 
    case (((e,r) :: xs))
      equation 
        (r ==. 1.0) = true;
        res = simplifyMulMakePow(xs);
      then
        (e :: res);
    case (((e,r) :: xs))
      equation 
        res = simplifyMulMakePow(xs);
      then
        (BINARY(e,POW(REAL()),RCONST(r)) :: res);
  end matchcontinue;
end simplifyMulMakePow;

protected function simplifyAdd "function: simplifyAdd
  author: PA
 
  Simplifies ters like 2a+4b+2a+a+b
"
  input list<Exp> inExpLst;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inExpLst)
    local
      list<tuple<Exp, Real>> exp_const,exp_const_1;
      list<Exp> expl_1,expl;
    case (expl)
      equation 
        exp_const = simplifyAdd2(expl);
        exp_const_1 = simplifyAddJoinTerms(exp_const);
        expl_1 = simplifyAddMakeMul(exp_const_1);
      then
        expl_1;
    case (_)
      equation 
        print("-simplify_add failed\n");
      then
        fail();
  end matchcontinue;
end simplifyAdd;

protected function simplifyAdd2 "function: simplifyAdd2
  author: PA
  
  Helper function to simplify_add
"
  input list<Exp> inExpLst;
  output list<tuple<Exp, Real>> outTplExpRealLst;
algorithm 
  outTplExpRealLst:=
  matchcontinue (inExpLst)
    local
      Exp e_1,e;
      Real coeff;
      list<tuple<Exp, Real>> rest;
      list<Exp> es;
    case ({}) then {}; 
    case ((e :: es))
      equation 
        (e_1,coeff) = simplifyBinaryAddCoeff2(e);
        rest = simplifyAdd2(es);
      then
        ((e_1,coeff) :: rest);
    case (_)
      equation 
        print("simplify_add2 failed\n");
      then
        fail();
  end matchcontinue;
end simplifyAdd2;

protected function simplifyAddJoinTerms "function: simplifyAddJoinTerms
  author: PA
 
  Helper function to simplify_add. Join all terms with the same expression.
  i.e. 2a+4a gives an element  (a,6) in the list.
"
  input list<tuple<Exp, Real>> inTplExpRealLst;
  output list<tuple<Exp, Real>> outTplExpRealLst;
algorithm 
  outTplExpRealLst:=
  matchcontinue (inTplExpRealLst)
    local
      Real coeff2,coeff3,coeff;
      list<tuple<Exp, Real>> rest_1,res,rest;
      Exp e;
    case ({}) then {}; 
    case (((e,coeff) :: rest))
      equation 
        (coeff2,rest_1) = simplifyAddJoinTermsFind(e, rest);
        res = simplifyAddJoinTerms(rest_1);
        coeff3 = coeff +. coeff2;
      then
        ((e,coeff3) :: res);
  end matchcontinue;
end simplifyAddJoinTerms;

protected function simplifyAddJoinTermsFind "function: simplifyAddJoinTermsFind
  author: PA
  
  Helper function to simplify_add_join_terms, finds all occurences of exp.
"
  input Exp inExp;
  input list<tuple<Exp, Real>> inTplExpRealLst;
  output Real outReal;
  output list<tuple<Exp, Real>> outTplExpRealLst;
algorithm 
  (outReal,outTplExpRealLst):=
  matchcontinue (inExp,inTplExpRealLst)
    local
      Real coeff2,coeff3,coeff;
      list<tuple<Exp, Real>> res,rest;
      Exp e,e2;
    case (_,{}) then (0.0,{}); 
    case (e,((e2,coeff) :: rest))
      equation 
        true = expEqual(e, e2);
        (coeff2,res) = simplifyAddJoinTermsFind(e, rest);
        coeff3 = coeff +. coeff2;
      then
        (coeff3,res);
    case (e,((e2,coeff) :: rest)) /* not exp_equal */ 
      equation 
        (coeff2,res) = simplifyAddJoinTermsFind(e, rest);
      then
        (coeff2,((e2,coeff) :: res));
  end matchcontinue;
end simplifyAddJoinTermsFind;

protected function simplifyAddMakeMul "function: simplifyAddMakeMul
  author: PA
 
  Makes multiplications of each element in the list, except for 
  coefficient 1.0
"
  input list<tuple<Exp, Real>> inTplExpRealLst;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inTplExpRealLst)
    local
      list<Exp> res;
      Exp e;
      Real r;
      list<tuple<Exp, Real>> xs;
    case ({}) then {}; 
    case (((e,r) :: xs))
      equation 
        (r ==. 1.0) = true;
        res = simplifyAddMakeMul(xs);
      then
        (e :: res);
    case (((e,r) :: xs))
      equation 
        res = simplifyAddMakeMul(xs);
      then
        (BINARY(RCONST(r),MUL(REAL()),e) :: res);
  end matchcontinue;
end simplifyAddMakeMul;

protected function makeFactorDivision "function: makeFactorDivision
  author: PA
 
  Takes two expression lists (factors) and makes a division of the two
  If the second list is empty, no division node is created.
"
  input list<Exp> inExpLst1;
  input list<Exp> inExpLst2;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExpLst1,inExpLst2)
    local
      list<Exp> const_es1,notconst_es1,es1_1,es1,const_es2,notconst_es2,es2_1,es2;
      Exp res,res_1,e1,q,q_1,p,p_1;
    case ({},{}) then RCONST(1.0); 
    case (es1,{})
      equation 
        const_es1 = Util.listSelect(es1, isConst);
        notconst_es1 = Util.listSelect(es1, isNotConst);
        es1_1 = listAppend(const_es1, notconst_es1);
        res = makeProduct(es1_1);
        res_1 = simplify(res);
      then
        res_1;
    case (es1,{e1}) /* e1...en / 1.0 => e1...en */ 
      equation 
        true = isConstOne(e1);
        res = makeProduct(es1);
      then
        res;
    case ({},es2)
      equation 
        const_es2 = Util.listSelect(es2, isConst);
        notconst_es2 = Util.listSelect(es2, isNotConst);
        es2_1 = listAppend(const_es2, notconst_es2);
        q = makeProduct(es2_1);
        q_1 = simplify(q);
      then
        BINARY(RCONST(1.0),DIV(REAL()),q_1);
    case (es1,es2)
      equation 
        const_es1 = Util.listSelect(es1, isConst);
        notconst_es1 = Util.listSelect(es1, isNotConst);
        es1_1 = listAppend(const_es1, notconst_es1);
        const_es2 = Util.listSelect(es2, isConst);
        notconst_es2 = Util.listSelect(es2, isNotConst);
        es2_1 = listAppend(const_es2, notconst_es2);
        p = makeProduct(es1_1);
        q = makeProduct(es2_1);
        p_1 = simplify(p);
        q_1 = simplify(q);
      then
        BINARY(p_1,DIV(REAL()),q_1);
  end matchcontinue;
end makeFactorDivision;

protected function removeCommonFactors "function: removeCommonFactors
  author: PA
 
  Takes two lists of expressions (factors) and removes the factors common
  to both lists. The special case of the ident^exp is treated by subtraction 
  of the exponentials.
"
  input list<Exp> inExpLst1;
  input list<Exp> inExpLst2;
  output list<Exp> outExpLst1;
  output list<Exp> outExpLst2;
algorithm 
  (outExpLst1,outExpLst2):=
  matchcontinue (inExpLst1,inExpLst2)
    local
      Exp e2,pow_e,e1,e;
      list<Exp> es2_1,es1_1,es2_2,es1,es2;
      ComponentRef cr;
      Type tp;
    case ((BINARY(exp1 = CREF(componentRef = cr,ty = tp),operator = POW(ty = _),exp2 = e1) :: es1),es2)
      equation 
        (BINARY(_,POW(_),e2),es2_1) = findPowFactor(cr, es2);
        (es1_1,es2_2) = removeCommonFactors(es1, es2_1);
        pow_e = simplify(BINARY(CREF(cr,tp),POW(REAL()),BINARY(e1,SUB(REAL()),e2)));
      then
        ((pow_e :: es1_1),es2_2);
    case ((e :: es1),es2)
      equation 
        _ = Util.listGetmemberP(e, es2, expEqual);
        es2_1 = Util.listDeletememberP(es2, e, expEqual);
        (es1_1,es2_2) = removeCommonFactors(es1, es2_1);
      then
        (es1_1,es2_2);
    case ((e :: es1),es2)
      equation 
        (es1_1,es2_1) = removeCommonFactors(es1, es2);
      then
        ((e :: es1_1),es2_1);
    case ({},es2) then ({},es2); 
  end matchcontinue;
end removeCommonFactors;

protected function findPowFactor "function findPowFactor
  author: PA
  
  Helper function to remove_common_factors. Finds a POW expression in
  a list of factors.
"
  input ComponentRef inComponentRef;
  input list<Exp> inExpLst;
  output Exp outExp;
  output list<Exp> outExpLst;
algorithm 
  (outExp,outExpLst):=
  matchcontinue (inComponentRef,inExpLst)
    local
      ComponentRef cr,cr2;
      Exp e,pow_e;
      list<Exp> es;
    case (cr,((e as BINARY(exp1 = CREF(componentRef = cr2),operator = POW(ty = _))) :: es))
      equation 
        true = crefEqual(cr, cr2);
      then
        (e,es);
    case (cr,(e :: es))
      equation 
        (pow_e,es) = findPowFactor(cr, es);
      then
        (pow_e,(e :: es));
  end matchcontinue;
end findPowFactor;

protected function simplifyBinaryAddCoeff2 "function: simplifyBinaryAddCoeff2
 
  This function checks for x+x+x+x and returns (x,4.0)
"
  input Exp inExp;
  output Exp outExp;
  output Real outReal;
algorithm 
  (outExp,outReal):=
  matchcontinue (inExp)
    local
      Exp exp,e1,e2,e;
      Real coeff,coeff_1;
      Type tp;
    case ((exp as CREF(componentRef = _))) then (exp,1.0); 
    case (BINARY(exp1 = RCONST(real = coeff),operator = MUL(ty = _),exp2 = e1)) then (e1,coeff); 
    case (BINARY(exp1 = e1,operator = MUL(ty = _),exp2 = RCONST(real = coeff))) then (e1,coeff); 
    case (BINARY(exp1 = e1,operator = MUL(ty = _),exp2 = ICONST(integer = coeff)))
      local Integer coeff;
      equation 
        coeff_1 = intReal(coeff);
      then
        (e1,coeff_1);
    case (BINARY(exp1 = ICONST(integer = coeff),operator = MUL(ty = _),exp2 = e1))
      local Integer coeff;
      equation 
        coeff_1 = intReal(coeff);
      then
        (e1,coeff_1);
    case (BINARY(exp1 = e1,operator = ADD(ty = tp),exp2 = e2))
      equation 
        true = expEqual(e1, e2);
      then
        (e1,2.0);
    case (e) then (e,1.0); 
  end matchcontinue;
end simplifyBinaryAddCoeff2;

protected function simplifyBinaryMulCoeff2 "function: simplifyBinaryMulCoeff2
 
  This function takes an expression XXXXX and return (X,5.0)
  to be used for X^5.
"
  input Exp inExp;
  output Exp outExp;
  output Real outReal;
algorithm 
  (outExp,outReal):=
  matchcontinue (inExp)
    local
      Exp e,e1,e2;
      ComponentRef cr;
      Real coeff,coeff_1,coeff_2;
      Type tp;
    case ((e as CREF(componentRef = cr))) then (e,1.0); 
    case (BINARY(exp1 = e1,operator = POW(ty = _),exp2 = RCONST(real = coeff))) then (e1,coeff); 
    case (BINARY(exp1 = e1,operator = POW(ty = _),exp2 = UNARY(operator = UMINUS(ty = tp),exp = RCONST(real = coeff))))
      equation 
        coeff_1 = 0.0 -. coeff;
      then
        (e1,coeff_1);
    case (BINARY(exp1 = e1,operator = POW(ty = _),exp2 = ICONST(integer = coeff)))
      local Integer coeff;
      equation 
        coeff_1 = intReal(coeff);
      then
        (e1,coeff_1);
    case (BINARY(exp1 = e1,operator = POW(ty = _),exp2 = UNARY(operator = UMINUS(ty = tp),exp = ICONST(integer = coeff))))
      local Integer coeff;
      equation 
        coeff_1 = intReal(coeff);
        coeff_2 = 0.0 -. coeff_1;
      then
        (e1,coeff_1);
    case (BINARY(exp1 = ICONST(integer = coeff),operator = POW(ty = _),exp2 = e1))
      local Integer coeff;
      equation 
        coeff_1 = intReal(coeff);
      then
        (e1,coeff_1);
    case (BINARY(exp1 = e1,operator = MUL(ty = tp),exp2 = e2))
      equation 
        true = expEqual(e1, e2);
      then
        (e1,2.0);
    case (e) then (e,1.0); 
  end matchcontinue;
end simplifyBinaryMulCoeff2;

protected function simplifyAsub "function: simplifyAsub
 
  This function simplifies array subscripts on vector operations
"
  input Exp inExp;
  input Integer inInteger;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp,inInteger)
    local
      Exp e_1,e,e1_1,e2_1,e1,e2,exp;
      Type t,t_1;
      Integer indx,i_1,n;
      Operator op;
      Boolean b;
      list<Exp> exps,expl_1;
      list<tuple<Exp, Boolean>> expl;
      list<Boolean> bls;
      ComponentRef cr;
    case (UNARY(operator = UMINUS_ARR(ty = t),exp = e),indx)
      equation 
        e_1 = simplifyAsub(e, indx);
      then
        UNARY(UMINUS_ARR(t),e_1);
    case (UNARY(operator = UPLUS_ARR(ty = t),exp = e),indx)
      equation 
        e_1 = simplifyAsub(e, indx);
      then
        UNARY(UPLUS_ARR(t),e_1);
    case (BINARY(exp1 = e1,operator = SUB_ARR(ty = t),exp2 = e2),indx)
      equation 
        e1_1 = simplifyAsub(e1, indx);
        e2_1 = simplifyAsub(e2, indx);
      then
        BINARY(e1_1,SUB_ARR(t),e2_1);
    case (BINARY(exp1 = e1,operator = MUL_SCALAR_ARRAY(ty = t),exp2 = e2),indx)
      equation 
        e2_1 = simplifyAsub(e2, indx);
        e1_1 = simplify(e1);
        op = simplifyAsubOperator(e2_1, MUL(t), MUL_SCALAR_ARRAY(t));
      then
        BINARY(e1_1,op,e2_1);
    case (BINARY(exp1 = e1,operator = MUL_ARRAY_SCALAR(ty = t),exp2 = e2),indx)
      equation 
        e1_1 = simplifyAsub(e1, indx);
        e2_1 = simplify(e2);
        op = simplifyAsubOperator(e2_1, MUL(t), MUL_SCALAR_ARRAY(t));
      then
        BINARY(e1_1,op,e2_1);
    case (BINARY(exp1 = e1,operator = DIV_ARRAY_SCALAR(ty = t),exp2 = e2),indx)
      equation 
        e1_1 = simplifyAsub(e1, indx);
        e2_1 = simplify(e2);
      then
        BINARY(e1_1,DIV(t),e2_1);
    case (BINARY(exp1 = e1,operator = ADD_ARR(ty = t),exp2 = e2),indx)
      equation 
        e1_1 = simplifyAsub(e1, indx);
        e2_1 = simplifyAsub(e2, indx);
      then
        BINARY(e1_1,ADD_ARR(t),e2_1);
    case (BINARY(exp1 = e1,operator = SUB_ARR(ty = t),exp2 = e2),indx)
      equation 
        e1_1 = simplifyAsub(e1, indx);
        e2_1 = simplifyAsub(e2, indx);
      then
        BINARY(e1_1,SUB_ARR(t),e2_1);
    case (ARRAY(ty = t,scalar = b,array = exps),indx)
      equation 
        i_1 = indx - 1;
        exp = listNth(exps, i_1);
      then
        exp;
    case (MATRIX(ty = t,integer = n,scalar = exps),indx)
      local list<list<tuple<Exp, Boolean>>> exps;
      equation 
        i_1 = indx - 1;
        (expl) = listNth(exps, i_1);
        (expl_1,bls) = Util.splitTuple2List(expl);
        t_1 = unliftArray(t);
        b = Util.boolAndList(bls);
      then
        ARRAY(t_1,b,expl_1);
    case ((e as CREF(componentRef = cr,ty = t)),indx)
      equation 
        e_1 = simplify(ASUB(e,indx));
      then
        e_1;
  end matchcontinue;
end simplifyAsub;

protected function simplifyAsubOperator
  input Exp inExp1;
  input Operator inOperator2;
  input Operator inOperator3;
  output Operator outOperator;
algorithm 
  outOperator:=
  matchcontinue (inExp1,inOperator2,inOperator3)
    local Operator sop,aop;
    case (ARRAY(ty = _),sop,aop) then aop; 
    case (MATRIX(ty = _),sop,aop) then aop; 
    case (RANGE(ty = _),sop,aop) then aop; 
    case (_,sop,aop) then sop; 
  end matchcontinue;
end simplifyAsubOperator;

protected function divide "function: divide
  author: PA
 
  divides two expressions.
"
  input Exp inExp1;
  input Exp inExp2;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inExp2)
    local Exp e1,e2;
    case (e1,e2) then BINARY(e1,DIV(REAL()),e2); 
  end matchcontinue;
end divide;

protected function removeFactor "function: removeFactor
 
  Remove the factor from the expression (factorize it out)
"
  input Exp inExp1;
  input Exp inExp2;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inExp2)
    local
      Exp e1,factor1,expr1,one,factor,expr,exp;
      list<Exp> rest,e2s,e1s,factors_1;
      Type tp;
      Ident fs,es,factorsstr;
      list<Ident> elst;
    case (factor,expr) /* factor expr updated expr factor = expr, return one */ 
      equation 
        (e1 :: rest) = factors(factor);
        e2s = factors(expr);
        factor1 = makeProduct((e1 :: rest));
        expr1 = makeProduct(e2s);
        {} = Util.listSetdifferenceP(e2s, (e1 :: rest), expEqual);
        tp = typeof(e1);
        one = makeConstOne(tp);
      then
        one;
    case (factor,expr)
      equation 
        e1s = factors(factor);
        e2s = factors(expr);
        factors_1 = Util.listSetdifferenceP(e2s, e1s, expEqual);
        exp = makeProduct(factors_1);
      then
        exp;
    case (factor,expr)
      equation 
        fs = printExpStr(factor);
        es = printExpStr(expr);
        print("remove_factor failed, factor:");
        print(fs);
        print(" expr:");
        print(es);
        print("\n");
        e2s = factors(expr);
        elst = Util.listMap(e2s, printExpStr);
        factorsstr = Util.stringDelimitList(elst, ", ");
        print(" factors:");
        print(factorsstr);
        print("\n");
      then
        fail();
  end matchcontinue;
end removeFactor;

protected function gcd "function: gcd
 
  Return the greatest common divisor expression from two expressions.
  If no common divisor besides a numerical expression can be found, the 
  function fails.
"
  input Exp e1;
  input Exp e2;
  output Exp product;
  list<Exp> e1s,e2s,factor;
algorithm 
  e1s := factors(e1);
  e2s := factors(e2);
  ((factor as (_ :: _))) := Util.listIntersectionP(e1s, e2s, expEqual);
  product := makeProduct(factor);
end gcd;

protected function noFactors "function noFactors
 
  Helper function to factors.
  If a factor list is empty, the expression has no subfactors.
  But the complete expression is then a factor for larger expressions,
  returned by this function.
"
  input list<Exp> inExpLst;
  input Exp inExp;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inExpLst,inExp)
    local
      Exp e;
      list<Exp> lst;
    case ({},e) then {e}; 
    case (lst,_) then lst; 
  end matchcontinue;
end noFactors;

protected function negate "function: negate
  author: PA
 
  Negates an expression.
"
  input Exp e;
  output Exp outExp;
  Type t;
algorithm 
  t := typeof(e);
  outExp := UNARY(UMINUS(t),e);
end negate;

public function terms "function: terms
  author: PA
 
  Returns the terms of the expression if any as a list of expressiosn
"
  input Exp inExp;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inExp)
    local
      list<Exp> f1,f2,res,f2_1;
      Exp e1,e2,e;
      ComponentRef cr;
    case (BINARY(exp1 = e1,operator = ADD(ty = _),exp2 = e2))
      equation 
        f1 = terms(e1);
        f2 = terms(e2);
        res = listAppend(f1, f2);
      then
        res;
    case (BINARY(exp1 = e1,operator = SUB(ty = _),exp2 = e2))
      equation 
        f1 = terms(e1);
        f2 = terms(e2);
        f2_1 = Util.listMap(f2, negate);
        res = listAppend(f1, f2_1);
      then
        res;
    case ((e as BINARY(operator = MUL(ty = _)))) then {e}; 
    case ((e as BINARY(operator = DIV(ty = _)))) then {e}; 
    case ((e as BINARY(operator = POW(ty = _)))) then {e}; 
    case ((e as CREF(componentRef = cr))) then {e}; 
    case ((e as ICONST(integer = _))) then {e}; 
    case ((e as RCONST(real = _))) then {e}; 
    case ((e as SCONST(string = _))) then {e}; 
    case ((e as UNARY(operator = _))) then {e}; 
    case ((e as IFEXP(expCond = _))) then {e}; 
    case ((e as CALL(path = _))) then {e}; 
    case ((e as ARRAY(ty = _))) then {e}; 
    case ((e as MATRIX(ty = _))) then {e}; 
    case ((e as RANGE(ty = _))) then {e}; 
    case ((e as CAST(ty = _))) then {e}; 
    case ((e as ASUB(exp = _))) then {e}; 
    case ((e as SIZE(exp = _))) then {e}; 
    case ((e as REDUCTION(path = _))) then {e}; 
    case (_) then {}; 
  end matchcontinue;
end terms;

public function quotient "function: quotient
  author: PA
 
  Returns the quotient of an expression.
  For instance e = p/q returns (p,q) for nominator p and denominator q.
"
  input Exp inExp;
  output Exp outExp1;
  output Exp outExp2;
algorithm 
  (outExp1,outExp2):=
  matchcontinue (inExp)
    local
      Exp e1,e2,p,q;
      Type tp;
    case (BINARY(exp1 = e1,operator = DIV(ty = _),exp2 = e2)) then (e1,e2);  /* nominator denominator */ 
    case (BINARY(exp1 = e1,operator = MUL(ty = _),exp2 = e2))
      equation 
        (p,q) = quotient(e1);
        tp = typeof(p);
      then
        (BINARY(e2,MUL(tp),p),q);
    case (BINARY(exp1 = e1,operator = MUL(ty = _),exp2 = e2))
      equation 
        (p,q) = quotient(e2);
        tp = typeof(p);
      then
        (BINARY(e1,MUL(tp),p),q);
  end matchcontinue;
end quotient;

public function factors "function: factors
 
  Returns the factors of the expression if any as a list of expressions
"
  input Exp inExp;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inExp)
    local
      list<Exp> f1,f2,f1_1,f2_1,res,f2_2;
      Exp e1,e2,e;
      ComponentRef cr;
    case (BINARY(exp1 = e1,operator = MUL(ty = _),exp2 = e2))
      equation 
        f1 = factors(e1) "Both subexpression has factors" ;
        f2 = factors(e2);
        f1_1 = noFactors(f1, e1);
        f2_1 = noFactors(f2, e2);
        res = listAppend(f1_1, f2_1);
      then
        res;
    case (BINARY(exp1 = e1,operator = DIV(ty = REAL()),exp2 = e2))
      equation 
        f1 = factors(e1);
        f2 = factors(e2);
        f1_1 = noFactors(f1, e1);
        f2_1 = noFactors(f2, e2);
        f2_2 = inverseFactors(f2_1);
        res = listAppend(f1_1, f2_2);
      then
        res;
    case ((e as CREF(componentRef = cr))) then {e}; 
    case ((e as BINARY(exp1 = _))) then {e}; 
    case ((e as ICONST(integer = _))) then {e}; 
    case ((e as RCONST(real = _))) then {e}; 
    case ((e as SCONST(string = _))) then {e}; 
    case ((e as UNARY(operator = _))) then {e}; 
    case ((e as IFEXP(expCond = _))) then {e}; 
    case ((e as CALL(path = _))) then {e}; 
    case ((e as ARRAY(ty = _))) then {e}; 
    case ((e as MATRIX(ty = _))) then {e}; 
    case ((e as RANGE(ty = _))) then {e}; 
    case ((e as CAST(ty = _))) then {e}; 
    case ((e as ASUB(exp = _))) then {e}; 
    case ((e as SIZE(exp = _))) then {e}; 
    case ((e as REDUCTION(path = _))) then {e}; 
    case (_) then {}; 
  end matchcontinue;
end factors;

protected function inverseFactors "function inverseFactors
 
  Takes a list of expressions and returns each expression in the list 
  inversed.
  For example inverse_factors {a,3+b} => {1/a, 1/3+b}
"
  input list<Exp> inExpLst;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inExpLst)
    local
      list<Exp> es_1,es;
      Type tp2,tp;
      Exp e1,e2,e;
    case ({}) then {}; 
    case ((BINARY(exp1 = e1,operator = POW(ty = tp),exp2 = e2) :: es))
      equation 
        es_1 = inverseFactors(es);
        tp2 = typeof(e2);
      then
        (BINARY(e1,POW(tp),UNARY(UMINUS(tp2),e2)) :: es_1);
    case ((e :: es))
      equation 
        REAL() = typeof(e);
        es_1 = inverseFactors(es);
      then
        (BINARY(RCONST(1.0),DIV(REAL()),e) :: es_1);
    case ((e :: es))
      equation 
        INT() = typeof(e);
        es_1 = inverseFactors(es);
      then
        (BINARY(ICONST(1),DIV(INT()),e) :: es_1);
  end matchcontinue;
end inverseFactors;

protected function makeProduct "function: makeProduct
 
  Takes a list of expressions an makes a product expression multiplying all 
  elements in the list.
"
  input list<Exp> inExpLst;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExpLst)
    local
      Exp e1,res,e,e2,p1;
      list<Exp> es,rest,lst;
      Type tp;
      list<Ident> explst;
      Ident str;
    case ({}) then RCONST(1.0); 
    case ({e1}) then e1; 
    case ((e :: es)) /* to prevent infinite recursion, disregard constant 1. */ 
      equation 
        true = isConstOne(e);
        res = makeProduct(es);
      then
        res;
    case ({BINARY(exp1 = e1,operator = DIV(ty = tp),exp2 = e),e2})
      equation 
        true = isConstOne(e1);
      then
        BINARY(e2,DIV(tp),e);
    case ({e1,e2})
      equation 
        tp = typeof(e1) "Take type info from e1, ok since type checking already performed." ;
      then
        BINARY(e1,MUL(tp),e2);
    case ((BINARY(exp1 = e1,operator = DIV(ty = tp),exp2 = e) :: es))
      equation 
        true = isConstOne(e1);
        p1 = makeProduct(es);
      then
        BINARY(p1,DIV(tp),e);
    case ((e1 :: rest))
      equation 
        e2 = makeProduct(rest);
        tp = typeof(e2);
      then
        BINARY(e1,MUL(tp),e2);
    case (lst)
      equation 
        print("-make_product failed, exp lst:");
        explst = Util.listMap(lst, printExpStr);
        str = Util.stringDelimitList(explst, ", ");
        print(str);
        print("\n");
      then
        fail();
  end matchcontinue;
end makeProduct;

public function makeSum "function: makeSum
 
  Takes a list of expressions an makes a sum expression adding all 
  elements in the list.
"
  input list<Exp> inExpLst;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExpLst)
    local
      Exp e1,e2;
      Type tp;
      list<Exp> rest,lst;
      list<Ident> explst;
      Ident str;
    case ({}) then RCONST(0.0); 
    case ({e1}) then e1; 
    case ({e1,e2})
      equation 
        tp = typeof(e1) "Take type info from e1, ok since type checking already performed." ;
      then
        BINARY(e1,ADD(tp),e2);
    case ((e1 :: rest))
      equation 
        e2 = makeSum(rest);
        tp = typeof(e2);
      then
        BINARY(e1,ADD(tp),e2);
    case (lst)
      equation 
        print("-make_sum failed, exp lst:");
        explst = Util.listMap(lst, printExpStr);
        str = Util.stringDelimitList(explst, ", ");
        print(str);
        print("\n");
      then
        fail();
  end matchcontinue;
end makeSum;

public function abs "function: abs
  author: PA
 
  Makes the expression absolute. i.e. non-negative.
"
  input Exp inExp;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp)
    local
      Integer i2,i;
      Real r2,r;
      Exp e_1,e,e1_1,e2_1,e1,e2;
      Type tp;
      Operator op;
    case (ICONST(integer = i))
      equation 
        i2 = intAbs(i);
      then
        ICONST(i2);
    case (RCONST(real = r))
      equation 
        r2 = realAbs(r);
      then
        RCONST(r2);
    case (UNARY(operator = UMINUS(ty = tp),exp = e))
      equation 
        e_1 = abs(e);
      then
        e_1;
    case (BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = abs(e1);
        e2_1 = abs(e2);
      then
        BINARY(e1_1,op,e2_1);
    case (e) then e; 
  end matchcontinue;
end abs;

public function typeBuiltin "function: typeBuiltin
 
  Returns true if type is one of the builtin types.
"
  input Type inType;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inType)
    case (INT()) then true; 
    case (REAL()) then true; 
    case (STRING()) then true; 
    case (BOOL()) then true; 
    case (_) then false; 
  end matchcontinue;
end typeBuiltin;

public function arrayEltType "function: arrayEltType
 
  Returns the element type of an array expression.
"
  input Type inType;
  output Type outType;
algorithm 
  outType:=
  matchcontinue (inType)
    local Type t;
    case (T_ARRAY(ty = t)) then t; 
    case (t) then t; 
  end matchcontinue;
end arrayEltType;

protected function unliftArray "function: unliftArray
 
  Converts an array type into its element type.
"
  input Type inType;
  output Type outType;
algorithm 
  outType:=
  matchcontinue (inType)
    local
      Type tp,t;
      Integer d;
      list<Integer> ds;
    case (T_ARRAY(ty = tp,arrayDimensions = {_})) then tp; 
    case (T_ARRAY(ty = tp,arrayDimensions = (d :: ds))) then T_ARRAY(tp,ds); 
    case (t) then t; 
  end matchcontinue;
end unliftArray;

public function typeof "function typeof
 
  Retrieves the Type of the Expression
"
  input Exp inExp;
  output Type outType;
algorithm 
  outType:=
  matchcontinue (inExp)
    local
      Type tp;
      Operator op;
      Exp e1,e2,e3,e;
    case (ICONST(integer = _)) then INT(); 
    case (RCONST(real = _)) then REAL(); 
    case (SCONST(string = _)) then STRING(); 
    case (BCONST(bool = _)) then BOOL(); 
    case (CREF(ty = tp)) then tp; 
    case (BINARY(operator = op))
      equation 
        tp = typeofOp(op);
      then
        tp;
    case (UNARY(operator = op))
      equation 
        tp = typeofOp(op);
      then
        tp;
    case (LBINARY(operator = op))
      equation 
        tp = typeofOp(op);
      then
        tp;
    case (LUNARY(operator = op))
      equation 
        tp = typeofOp(op);
      then
        tp;
    case (RELATION(operator = op))
      equation 
        tp = typeofOp(op);
      then
        tp;
    case (IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation 
        tp = typeof(e2);
      then
        tp;
    case (CALL(path = _)) then OTHER();  /* Not always true */ 
    case (ARRAY(ty = tp)) then tp; 
    case (MATRIX(ty = tp)) then tp; 
    case (RANGE(ty = tp)) then tp; 
    case (CAST(ty = tp)) then tp; 
    case (ASUB(exp = e))
      equation 
        tp = typeof(e);
      then
        tp;
    case (CODE(ty = tp)) then tp; 
    case (REDUCTION(expr = e))
      equation 
        tp = typeof(e);
      then
        tp;
    case (END()) then OTHER();  /* Can be any type. */ 
  end matchcontinue;
end typeof;

protected function typeofOp "function: typeofOp
 
  Helper function to typeof
"
  input Operator inOperator;
  output Type outType;
algorithm 
  outType:=
  matchcontinue (inOperator)
    local Type t;
    case (ADD(ty = t)) then t; 
    case (SUB(ty = t)) then t; 
    case (MUL(ty = t)) then t; 
    case (DIV(ty = t)) then t; 
    case (POW(ty = t)) then t; 
    case (UMINUS(ty = t)) then t; 
    case (UPLUS(ty = t)) then t; 
    case (UMINUS_ARR(ty = t)) then t; 
    case (UPLUS_ARR(ty = t)) then t; 
    case (ADD_ARR(ty = t)) then t; 
    case (SUB_ARR(ty = t)) then t; 
    case (MUL_SCALAR_ARRAY(ty = t)) then t; 
    case (MUL_SCALAR_PRODUCT(ty = t)) then t; 
    case (MUL_MATRIX_PRODUCT(ty = t)) then t; 
    case (DIV_ARRAY_SCALAR(ty = t)) then t; 
    case (POW_ARR(ty = t)) then t; 
    case (AND()) then BOOL(); 
    case (OR()) then BOOL(); 
    case (NOT()) then BOOL(); 
    case (LESS(ty = t)) then t; 
    case (LESSEQ(ty = t)) then t; 
    case (GREATER(ty = t)) then t; 
    case (GREATEREQ(ty = t)) then t; 
    case (EQUAL(ty = t)) then t; 
    case (NEQUAL(ty = t)) then t; 
    case (USERDEFINED(fqName = t))
      local Absyn.Path t;
      then
        OTHER();
  end matchcontinue;
end typeofOp;

protected function isConstOne "function: isConstOne
  
  Return true if expression is 1
"
  input Exp inExp;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp)
    local
      Real rval;
      Exp e;
    case e
      equation 
        rval = intReal(1);
        equality(e = RCONST(rval));
      then
        true;
    case ICONST(integer = 1) then true; 
    case (_) then false; 
  end matchcontinue;
end isConstOne;

protected function isConstMinusOne "function: isConstMinusOne
 
  Return true if expression is -1
"
  input Exp inExp;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp)
    local Real rval,v;
    case RCONST(real = v)
      equation 
        rval = intReal(-1);
        (v ==. rval) = true;
      then
        true;
    case ICONST(integer = -1) then true; 
    case (_) then false; 
  end matchcontinue;
end isConstMinusOne;

protected function isConstZero "function: isConstZero
 
  Return true if expression is 0
"
  input Exp inExp;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp)
    local
      Real rval;
      Exp e;
    case e
      equation 
        rval = intReal(0);
        equality(e = RCONST(rval));
      then
        true;
    case ICONST(integer = 0) then true; 
    case (_) then false; 
  end matchcontinue;
end isConstZero;

public function makeIntegerExp "creates an integer constant expression given the integer input."
  input Integer i;
  output Exp e;
algorithm
  e:=ICONST(i);
end makeIntegerExp;

protected function makeConstOne "function makeConstOne
  author: PA
 
  Create the constant value one, given a type that is INT or REAL
"
  input Type inType;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inType)
    case (INT()) then ICONST(1); 
    case (REAL()) then RCONST(1.0); 
  end matchcontinue;
end makeConstOne;

protected function simplifyBinaryConst "function: simplifyBinaryConst
 
  This function evaluates constant binary expressions.
"
  input Operator inOperator1;
  input Exp inExp2;
  input Exp inExp3;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inOperator1,inExp2,inExp3)
    local
      Integer e3,e1,e2;
      Real e2_1,e1_1;
      Operator op;
    case (ADD(ty = _),ICONST(integer = e1),ICONST(integer = e2))
      equation 
        e3 = e1 + e2;
      then
        ICONST(e3);
    case (ADD(ty = _),RCONST(real = e1),RCONST(real = e2))
      local Real e3,e1,e2;
      equation 
        e3 = e1 +. e2;
      then
        RCONST(e3);
    case (ADD(ty = _),RCONST(real = e1),ICONST(integer = e2))
      local Real e3,e1;
      equation 
        e2_1 = intReal(e2);
        e3 = e1 +. e2_1;
      then
        RCONST(e3);
    case (ADD(ty = _),ICONST(integer = e1),RCONST(real = e2))
      local Real e3,e2;
      equation 
        e1_1 = intReal(e1);
        e3 = e1_1 +. e2;
      then
        RCONST(e3);
    case (SUB(ty = _),ICONST(integer = e1),ICONST(integer = e2))
      equation 
        e3 = e1 - e2;
      then
        ICONST(e3);
    case (SUB(ty = _),RCONST(real = e1),RCONST(real = e2))
      local Real e3,e1,e2;
      equation 
        e3 = e1 -. e2;
      then
        RCONST(e3);
    case (SUB(ty = _),RCONST(real = e1),ICONST(integer = e2))
      local Real e3,e1;
      equation 
        e2_1 = intReal(e2);
        e3 = e1 -. e2_1;
      then
        RCONST(e3);
    case (SUB(ty = _),ICONST(integer = e1),RCONST(real = e2))
      local Real e3,e2;
      equation 
        e1_1 = intReal(e1);
        e3 = e1_1 -. e2;
      then
        RCONST(e3);
    case (MUL(ty = _),ICONST(integer = e1),ICONST(integer = e2))
      equation 
        e3 = e1*e2;
      then
        ICONST(e3);
    case (MUL(ty = _),RCONST(real = e1),RCONST(real = e2))
      local Real e3,e1,e2;
      equation 
        e3 = e1*.e2;
      then
        RCONST(e3);
    case (MUL(ty = _),RCONST(real = e1),ICONST(integer = e2))
      local Real e3,e1;
      equation 
        e2_1 = intReal(e2);
        e3 = e1*.e2_1;
      then
        RCONST(e3);
    case (MUL(ty = _),ICONST(integer = e1),RCONST(real = e2))
      local Real e3,e2;
      equation 
        e1_1 = intReal(e1);
        e3 = e1_1*.e2;
      then
        RCONST(e3);
    case (DIV(ty = _),ICONST(integer = e1),ICONST(integer = e2))
      equation 
        e3 = e1/e2;
      then
        ICONST(e3);
    case (DIV(ty = _),RCONST(real = e1),RCONST(real = e2))
      local Real e3,e1,e2;
      equation 
        e3 = e1/.e2;
      then
        RCONST(e3);
    case (DIV(ty = _),RCONST(real = e1),ICONST(integer = e2))
      local Real e3,e1;
      equation 
        e2_1 = intReal(e2);
        e3 = e1/.e2_1;
      then
        RCONST(e3);
    case (DIV(ty = _),ICONST(integer = e1),RCONST(real = e2))
      local Real e3,e2;
      equation 
        e1_1 = intReal(e1);
        e3 = e1_1/.e2;
      then
        RCONST(e3);
    /* 2006-05-14 adrpo added simplification for constant1 ^ constant2 */
    case (POW(ty = _),ICONST(integer = e1),ICONST(integer = e2))
      local Real e1r,e2r,e3;
      equation
        e1r = intReal(e1);
        e2r = intReal(e2);
        e3 = e1r ^. e2r;
      then
        RCONST(e3);
    case (POW(ty = _),RCONST(real = e1),RCONST(real = e2))
      local Real e3,e1,e2;
      equation 
        e3 = e1 ^. e2;
      then
        RCONST(e3);
    case (POW(ty = _),RCONST(real = e1),ICONST(integer = e2))
      local Real e3,e1;
      equation 
        e2_1 = intReal(e2);
        e3 = e1 ^. e2_1;
      then
        RCONST(e3);
    case (POW(ty = _),ICONST(integer = e1),RCONST(real = e2))
      local Real e3,e2;
      equation 
        e1_1 = intReal(e1);
        e3 = e1_1 ^. e2;
      then
        RCONST(e3);
    /* end adrpo added */    
    case (op,e1,e2)
      local Exp e1,e2;
      then
        fail();
  end matchcontinue;
end simplifyBinaryConst;

protected function simplifyBinary "function: simplifyBinary
  
  This function simplifies binary expressions.
"
  input Exp inExp1;
  input Operator inOperator2;
  input Exp inExp3;
  input Exp inExp4;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inOperator2,inExp3,inExp4)
    local
      Exp e1_1,e2_1,e3,e,e1,e2,res,e_1,one;
      Operator oper;
      Type ty,ty2,tp,tp2,ty1;
      Ident s1,s2;
      list<Exp> exp_lst,exp_lst_1;
    case (e,oper,e1,e2)
      equation 
        e1_1 = simplify(e1);
        e2_1 = simplify(e2);
        true = isConst(e1_1);
        true = isConst(e2_1);
        e3 = simplifyBinaryConst(oper, e1_1, e2_1);
      then
        e3;

    case (_,DIV(ty = ty),BINARY(exp1 = e1,operator = ADD(ty = ty2),exp2 = e2),e3) /* (a+b)/c1 => a/c1+b/c1, for constant c1 */ 
      equation 
        true = isConst(e3);
        res = simplify(
          BINARY(BINARY(e1,DIV(ty),e3),ADD(ty2),BINARY(e2,DIV(ty),e3)));
      then
        res;

    case (_,DIV(ty = ty),BINARY(exp1 = e1,operator = SUB(ty = ty2),exp2 = e2),e3) /* (a-b)/c1 => a/c1-b/c1, for constant c1 */ 
      equation 
        true = isConst(e3);
        res = simplify(
          BINARY(BINARY(e1,DIV(ty),e3),SUB(ty2),BINARY(e2,DIV(ty),e3)));
      then
        res;

    case (_,MUL(ty = ty),BINARY(exp1 = e1,operator = ADD(ty = ty2),exp2 = e2),e3) /* (a+b)c1 => ac1+bc1, for constant c1 */ 
      equation 
        true = isConst(e3);
        res = simplify(
          BINARY(BINARY(e1,MUL(ty),e3),ADD(ty2),BINARY(e2,MUL(ty),e3)));
      then
        res;

    case (_,MUL(ty = ty),BINARY(exp1 = e1,operator = SUB(ty = ty2),exp2 = e2),e3) /* (a-b)c1 => a/c1-b/c1, for constant c1 */ 
      equation 
        true = isConst(e3);
        res = simplify(
          BINARY(BINARY(e1,MUL(ty),e3),SUB(ty2),BINARY(e2,MUL(ty),e3)));
      then
        res;

    case (_,ADD(ty = tp),e1,UNARY(operator = UMINUS(ty = tp2),exp = e2)) /* a+(-b) */ 
      equation 
        e = simplify(BINARY(e1,SUB(tp),e2));
      then
        e;

    /* adrpo - here was a copy paste error!, the case was just like the one above ---> fixed */
    case (_,ADD(ty = tp),UNARY(operator = UMINUS(ty = tp2),exp = e2), e1) /* (-b)+a */ 
      equation 
        e1 = simplify(BINARY(e1,SUB(tp),e2));
      then
        e1;

    case (_,DIV(ty = tp),e1,BINARY(exp1 = e2,operator = DIV(ty = tp2),exp2 = e3))
      equation 
        e = simplify(BINARY(BINARY(e1,MUL(tp),e3),DIV(tp2),e2)) "a/b/c => (ac)/b)" ;
      then
        e;

    case (_,DIV(ty = tp),BINARY(exp1 = e1,operator = DIV(ty = tp2),exp2 = e2),e3)
      equation 
        e = simplify(BINARY(e1,DIV(tp2),BINARY(e2,MUL(tp),e3))) "(a/b)/c => a/(bc))" ;
      then
        e;

    case (_,ADD(ty = ty),e1,e2)
      equation 
        true = isConstZero(e1);
        e2_1 = simplify(e2);
      then
        e2_1;

    case (_,ADD(ty = ty),e1,e2)
      equation 
        true = isConstZero(e2);
        e1_1 = simplify(e1);
      then
        e1_1;

    case (_,SUB(ty = ty),e1,e2)
      equation 
        true = isConstZero(e1);
        e = UNARY(UMINUS(ty),e2);
        e_1 = simplify(e);
      then
        e_1;

    case (_,SUB(ty = ty),e1,e2)
      equation 
        true = isConstZero(e2);
        e1_1 = simplify(e1);
      then
        e1_1;

    case (_,SUB(ty = ty),e1,e2)
      equation 
        true = isConstZero(e2);
        e1_1 = simplify(e1);
      then
        e1_1;

    case (_,SUB(ty = ty),e1,UNARY(operator = UMINUS(ty = ty2),exp = e2))
      equation 
        e = simplify(BINARY(e1,ADD(ty),e2)) "a-(-b) = a+b" ;
      then
        e;

    case (_,MUL(ty = tp),BINARY(exp1 = e1,operator = DIV(ty = tp2),exp2 = e2),e3) /* (e1/e2)e3 => (e1e3)/e2 */ 
      equation 
        res = simplify(BINARY(BINARY(e1,MUL(tp),e3),DIV(tp2),e2));
      then
        res;

    case (_,MUL(ty = tp),e1,BINARY(exp1 = e2,operator = DIV(ty = tp2),exp2 = e3)) /* e1(e2/e3) => (e1e2)/e3 */ 
      equation 
        res = simplify(BINARY(BINARY(e1,MUL(tp),e2),DIV(tp2),e3));
      then
        res;

    case (_,MUL(ty = ty),e1,e2)
      equation 
        true = isConstZero(e1);
      then
        e1;

    case (_,MUL(ty = ty),e1,e2)
      equation 
        true = isConstZero(e2);
      then
        e2;

    case (_,MUL(ty = ty),e1,e2)
      equation 
        true = isConstOne(e1);
        e2_1 = simplify(e2);
      then
        e2_1;

    case (_,MUL(ty = ty),e1,e2)
      equation 
        true = isConstOne(e2);
        e1_1 = simplify(e1);
      then
        e1_1;

    case (_,MUL(ty = ty),e1,e2)
      equation 
        true = isConstMinusOne(e1);
        e = simplify(UNARY(UMINUS(ty),e2));
      then
        e;

    case (_,MUL(ty = ty),e1,e2)
      equation 
        true = isConstMinusOne(e2);
        e1_1 = simplify(e1);
      then
        UNARY(UMINUS(ty),e1_1);

    case (_,MUL(ty = ty),UNARY(operator = UMINUS(ty = ty1),exp = e1),UNARY(operator = UMINUS(ty = ty2),exp = e2))
      equation 
        e = simplify(BINARY(e1,MUL(ty),e2));
      then
        e;

    case (_,MUL(ty = ty),e1,UNARY(operator = UMINUS(ty = ty2),exp = e2))
      equation 
        e1_1 = simplify(UNARY(UMINUS(ty),e1)) "e1  -e2 => -e1  e2" ;
        e2_1 = simplify(e2);
      then
        BINARY(e1_1,MUL(ty),e2_1);

    case (_,DIV(ty = ty),e1,e2)
      equation 
        true = isConstZero(e1);
      then
        RCONST(0.0);

    case (_,DIV(ty = ty),e1,e2)
      equation 
        true = isConstZero(e2);
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        Error.addMessage(Error.DIVISION_BY_ZERO, {s1,s2});
      then
        fail();

    case (_,DIV(ty = ty),e1,e2)
      equation 
        true = isConstOne(e2);
        e1_1 = simplify(e1);
      then
        e1_1;

    case (_,DIV(ty = ty),e1,e2)
      equation 
        true = isConstMinusOne(e2);
        e1_1 = simplify(e1);
      then
        UNARY(UMINUS(ty),e1_1);

    case (_,DIV(ty = ty),UNARY(operator = UMINUS(ty = ty1),exp = e1),UNARY(operator = UMINUS(ty = ty2),exp = e2))
      equation 
        e1_1 = simplify(e1);
        e2_1 = simplify(e2);
      then
        BINARY(e1_1,DIV(ty),e2_1);

    case (_,DIV(ty = ty),e1,UNARY(operator = UMINUS(ty = ty2),exp = e2))
      equation 
        e1_1 = simplify(UNARY(UMINUS(ty),e1)) "e1 / -e2  => -e1 / e2" ;
        e2_1 = simplify(e2);
      then
        BINARY(e1_1,DIV(ty),e2_1);

    case (_,DIV(ty = tp2),BINARY(exp1 = e2,operator = MUL(ty = tp),exp2 = e3),e1)
      equation 
        true = isConst(e3) "(c1x)/c2" ;
        true = isConst(e1);
        e = simplify(BINARY(BINARY(e1,DIV(tp2),e3),MUL(tp),e2));
      then
        e;

    case (_,DIV(ty = tp2),BINARY(exp1 = e2,operator = MUL(ty = tp),exp2 = e3),e1)
      equation 
        true = isConst(e3) "(xc1)/c2" ;
        true = isConst(e2);
        e = simplify(BINARY(BINARY(e2,DIV(tp2),e3),MUL(tp),e1));
      then
        e;

    case (_,POW(ty = _),e1,e)
      equation 
        e_1 = simplify(e) "e1^e2, where e2 is one" ;
        e1_1 = simplify(e1);
        true = isConstOne(e_1);
      then
        e1_1;

    case (_,POW(ty = tp),e2,e)
      equation 
        e2_1 = simplify(e2) "e1^e2, where e2 is minus one" ;
        e_1 = simplify(e);
        true = isConstMinusOne(e_1);
        one = makeConstOne(tp);
      then
        BINARY(one,DIV(REAL()),e2_1);

    case (_,POW(ty = _),e1,e)
      equation 
        e_1 = simplify(e) "e1^e2, where e2 is zero" ;
        tp = typeof(e1);
        true = isZero(e_1);
        res = createConstOne(tp);
      then
        res;

    /* 2006-05-15 -> adrpo added */
    case (_,POW(ty = _),e1,e)
      equation 
        e_1 = simplify(e1) "e1^e2, where e1 is one" ;
        true = isConstOne(e_1);
      then
        e_1;
    /* 2006-05-15 -> end adrpo added */        

    case (_,POW(ty = _),e1,e2) /* (a1a2...an)^e2 => a1^e2a2^e2..an^e2 */ 
      equation 
        ((exp_lst as (_ :: (_ :: _)))) = factors(e1);
        exp_lst_1 = simplifyBinaryDistributePow(exp_lst, e2);
        res = makeProduct(exp_lst_1);
      then
        res;

    case (e,_,_,_) then e; 
  end matchcontinue;
end simplifyBinary;

protected function simplifyBinaryDistributePow "function simplifyBinaryDistributePow
  author: PA
 
  Distributes the pow operator over a list of expressions.
  ({e1,e2,..,en} , pow_e) =>  {e1^pow_e, e2^pow_e,..,en^pow_e}
"
  input list<Exp> inExpLst;
  input Exp inExp;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inExpLst,inExp)
    local
      list<Exp> es_1,es;
      Type tp;
      Exp e,pow_e;
    case ({},_) then {}; 
    case ((e :: es),pow_e)
      equation 
        es_1 = simplifyBinaryDistributePow(es, pow_e);
        tp = typeof(e);
      then
        (BINARY(e,POW(tp),pow_e) :: es_1);
  end matchcontinue;
end simplifyBinaryDistributePow;

protected function createConstOne "function: createConstOne
  Creates a constant value one, given a type INT or REAL
"
  input Type inType;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inType)
    local Real realv;
    case (REAL())
      equation 
        realv = intReal(1);
      then
        RCONST(realv);
    case (INT()) then ICONST(1); 
  end matchcontinue;
end createConstOne;

protected function simplifyUnary "function: simplifyUnary
 
  Simplifies unary expressions.
"
  input Exp inExp1;
  input Operator inOperator2;
  input Exp inExp3;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inOperator2,inExp3)
    local
      Type ty,ty1;
      Exp e1,e1_1,e_1,e2,e;
      Integer i_1,i;
      Real r_1,r;
    case (_,UPLUS(ty = ty),e1) then e1; 
    case (_,UMINUS(ty = ty),ICONST(integer = i))
      equation 
        i_1 = 0 - i;
      then
        ICONST(i_1);
    case (_,UMINUS(ty = ty),RCONST(real = r))
      equation 
        r_1 = 0.0 -. r;
      then
        RCONST(r_1);
    case (_,UMINUS(ty = ty),e1)
      equation 
        e1_1 = simplify(e1);
        true = isConstZero(e1_1);
      then
        e1_1;
    case (_,UMINUS(ty = ty),BINARY(exp1 = e1,operator = SUB(ty = ty1),exp2 = e2))
      equation 
        e_1 = simplify(BINARY(e2,SUB(ty1),e1)) "-(a-b) => b-a" ;
      then
        e_1;

    case (_,UMINUS(ty = ty),BINARY(exp1 = e1,operator = ADD(ty = ty1),exp2 = e2))
      equation 
        e_1 = simplify(BINARY(UNARY(UMINUS(ty),e1),ADD(ty1),UNARY(UMINUS(ty),e2))) "-(a+b) => -b-a" ;
      then
        e_1;
    case (_,UMINUS(ty = ty),BINARY(exp1 = e1,operator = DIV(ty = ty1),exp2 = e2))
      equation 
        e_1 = simplify(BINARY(UNARY(UMINUS(ty),e1),DIV(ty1),e2)) "-(a/b) => -a/b" ;
      then
        e_1;
    case (_,UMINUS(ty = ty),BINARY(exp1 = e1,operator = MUL(ty = ty1),exp2 = e2))
      equation 
        e_1 = simplify(BINARY(UNARY(UMINUS(ty),e1),MUL(ty1),e2)) "-(ab) => -ab" ;
      then
        e_1;
    case (_,UMINUS(ty = _),UNARY(operator = UMINUS(ty = _),exp = e1)) /* --a => a */ 
      equation 
        e1_1 = simplify(e1);
      then
        e1_1;
    case (e,_,_) then e; 
  end matchcontinue;
end simplifyUnary;

public function containFunctioncall "function: containFunctioncall
  Returns true if expression or subexpression is a functioncall.
  otherwise false.
  Note: the \'der\' operator is represented as a function call but still return 
  false.
"
  input Exp inExp;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp)
    local
      Exp e1,e2,e,e3;
      Boolean res;
      list<Boolean> blst;
      list<Exp> elst;
      list<tuple<Exp, Boolean>> flatexplst;
      list<list<tuple<Exp, Boolean>>> explst;
      Option<Exp> optexp;
    case (CALL(path = Absyn.IDENT(name = "der"))) then false; 
    case (CALL(path = _)) then true; 
    case (BINARY(exp1 = e1,exp2 = e2)) /* Binary */ 
      equation 
        true = containFunctioncall(e1);
      then
        true;
    case (BINARY(exp1 = e1,exp2 = e2))
      equation 
        true = containFunctioncall(e2);
      then
        true;
    case (UNARY(exp = e)) /* Unary */ 
      equation 
        res = containFunctioncall(e);
      then
        res;
    case (LBINARY(exp1 = e1,exp2 = e2)) /* LBinary */ 
      equation 
        true = containFunctioncall(e1);
      then
        true;
    case (LBINARY(exp1 = e1,exp2 = e2))
      equation 
        true = containFunctioncall(e2);
      then
        true;
    case (LUNARY(exp = e)) /* LUnary */ 
      equation 
        res = containFunctioncall(e);
      then
        res;
    case (RELATION(exp1 = e1,exp2 = e2)) /* Relation */ 
      equation 
        true = containFunctioncall(e1);
      then
        true;
    case (RELATION(exp1 = e1,exp2 = e2))
      equation 
        true = containFunctioncall(e2);
      then
        true;
    case (IFEXP(expCond = e1,expThen = e2,expElse = e3)) /* If exp */ 
      equation 
        true = containFunctioncall(e1);
      then
        true;
    case (IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation 
        true = containFunctioncall(e2);
      then
        true;
    case (IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation 
        true = containFunctioncall(e3);
      then
        true;
    case (ARRAY(array = elst)) /* Array */ 
      equation 
        blst = Util.listMap(elst, containFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    case (MATRIX(scalar = explst)) /* Matrix */ 
      equation 
        flatexplst = Util.listFlatten(explst);
        elst = Util.listMap(flatexplst, Util.tuple21);
        blst = Util.listMap(elst, containFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    case (RANGE(exp = e1,expOption = optexp,range = e2)) /* Range */ 
      equation 
        true = containFunctioncall(e1);
      then
        true;
    case (RANGE(exp = e1,expOption = optexp,range = e2))
      equation 
        true = containFunctioncall(e2);
      then
        true;
    case (RANGE(exp = e1,expOption = SOME(e),range = e2))
      equation 
        true = containFunctioncall(e);
      then
        true;
    case (TUPLE(PR = _)) then true;  /* Tuple */ 
    case (CAST(exp = e))
      equation 
        res = containFunctioncall(e);
      then
        res;
    case (SIZE(exp = e1,sz = e2)) /* Size */ 
      local Option<Exp> e2;
      equation 
        true = containFunctioncall(e1);
      then
        true;
    case (SIZE(exp = e1,sz = SOME(e2)))
      equation 
        true = containFunctioncall(e2);
      then
        true;
    case (_) then false; 
  end matchcontinue;
end containFunctioncall;

public function unelabExp "function: unelabExp
 
  Transform an Exp into Absyn.Exp. 
  Note: This function currently only works for constants and component 
  references.
"
  input Exp inExp;
  output Absyn.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp)
    local
      Integer i;
      Real r;
      Ident s;
      Boolean b;
      Absyn.ComponentRef cr_1;
      ComponentRef cr;
      Type t,tp;
      list<Absyn.Exp> expl_1;
      list<Exp> expl;
    case (ICONST(integer = i)) then Absyn.INTEGER(i); 
    case (RCONST(real = r)) then Absyn.REAL(r); 
    case (SCONST(string = s)) then Absyn.STRING(s); 
    case (BCONST(bool = b)) then Absyn.BOOL(b); 
    case (CREF(componentRef = cr,ty = t))
      equation 
        cr_1 = unelabCref(cr);
      then
        Absyn.CREF(cr_1);
    case (ARRAY(ty = tp,scalar = b,array = expl))
      equation 
        expl_1 = Util.listMap(expl, unelabExp);
      then
        Absyn.ARRAY(expl_1);
  end matchcontinue;
end unelabExp;

public function unelabCref "function: unelabCref
 
  Helper function to unelab_exp, handles component references.
"
  input ComponentRef inComponentRef;
  output Absyn.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inComponentRef)
    local
      list<Absyn.Subscript> subs_1;
      Ident id;
      list<Subscript> subs;
      Absyn.ComponentRef cr_1;
      ComponentRef cr;
    case (CREF_IDENT(ident = id,subscriptLst = subs))
      equation 
        subs_1 = unelabSubscripts(subs);
      then
        Absyn.CREF_IDENT(id,subs_1);
    case (CREF_QUAL(ident = id,subscriptLst = subs,componentRef = cr))
      equation 
        cr_1 = unelabCref(cr);
        subs_1 = unelabSubscripts(subs);
      then
        Absyn.CREF_QUAL(id,subs_1,cr_1);
  end matchcontinue;
end unelabCref;

protected function unelabSubscripts "function: unelabSubscripts
 
  Helper function to unelab_cref, handles subscripts.
"
  input list<Subscript> inSubscriptLst;
  output list<Absyn.Subscript> outAbsynSubscriptLst;
algorithm 
  outAbsynSubscriptLst:=
  matchcontinue (inSubscriptLst)
    local
      list<Absyn.Subscript> xs_1;
      list<Subscript> xs;
      Absyn.Exp e_1;
      Exp e;
    case ({}) then {}; 
    case ((WHOLEDIM() :: xs))
      equation 
        xs_1 = unelabSubscripts(xs);
      then
        (Absyn.NOSUB() :: xs_1);
    case ((SLICE(exp = e) :: xs))
      equation 
        xs_1 = unelabSubscripts(xs);
        e_1 = unelabExp(e);
      then
        (Absyn.SUBSCRIPT(e_1) :: xs_1);
    case ((INDEX(exp = e) :: xs))
      equation 
        xs_1 = unelabSubscripts(xs);
        e_1 = unelabExp(e);
      then
        (Absyn.SUBSCRIPT(e_1) :: xs_1);
  end matchcontinue;
end unelabSubscripts;

public function toExpCref "function: toExpCref
 
  Translate an Absyn.ComponentRef into a ComponentRef.
  Note: Only support for indexed subscripts of integers
"
  input Absyn.ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inComponentRef)
    local
      list<Subscript> subs_1;
      Ident id;
      list<Absyn.Subscript> subs;
      ComponentRef cr_1;
      Absyn.ComponentRef cr;
    case (Absyn.CREF_IDENT(name = id,subscripts = subs))
      equation 
        subs_1 = toExpCrefSubs(subs);
      then
        CREF_IDENT(id,subs_1);
    case (Absyn.CREF_QUAL(name = id,subScripts = subs,componentRef = cr))
      equation 
        cr_1 = toExpCref(cr);
        subs_1 = toExpCrefSubs(subs);
      then
        CREF_QUAL(id,subs_1,cr_1);
  end matchcontinue;
end toExpCref;

protected function toExpCrefSubs "function: toExpCrefSubs
 
  Helper function to to_exp_cref.
"
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  output list<Subscript> outSubscriptLst;
algorithm 
  outSubscriptLst:=
  matchcontinue (inAbsynSubscriptLst)
    local
      list<Subscript> xs_1;
      Integer i;
      list<Absyn.Subscript> xs;
      ComponentRef cr_1;
      Absyn.ComponentRef cr;
      Ident s,str;
      Absyn.Subscript e;
    case ({}) then {}; 
    case ((Absyn.SUBSCRIPT(subScript = Absyn.INTEGER(value = i)) :: xs))
      equation 
        xs_1 = toExpCrefSubs(xs);
      then
        (INDEX(ICONST(i)) :: xs_1);
    case ((Absyn.SUBSCRIPT(subScript = Absyn.CREF(componentReg = cr)) :: xs)) /* Assumes index is INTEGER. TODO: what about if index
         is an array? */ 
      equation 
        cr_1 = toExpCref(cr);
        xs_1 = toExpCrefSubs(xs);
      then
        (INDEX(CREF(cr_1,INT())) :: xs_1);
    case ((e :: xs))
      equation 
        s = Dump.printSubscriptsStr({e});
        str = Util.stringAppendList({"#Error converting subscript: ",s," to Exp.\n"});
        Print.printErrorBuf(str);
        xs_1 = toExpCrefSubs(xs);
      then
        xs_1;
  end matchcontinue;
end toExpCrefSubs;

protected function subscriptsAppend "function: subscriptsAppend
 
  This function takes a subscript list and adds a new subscript.
  But there are a few special cases.  When the last existing
  subscript is a slice, it is replaced by the slice indexed by the
  new subscript.
"
  input list<Subscript> inSubscriptLst;
  input Integer inInteger;
  output list<Subscript> outSubscriptLst;
algorithm 
  outSubscriptLst:=
  matchcontinue (inSubscriptLst,inInteger)
    local
      Integer i;
      Exp e_1,e;
      Subscript s;
      list<Subscript> ss_1,ss;
    case ({},i) then {INDEX(ICONST(i))}; 
    case ({WHOLEDIM()},i) then {INDEX(ICONST(i))}; 
    case ({SLICE(exp = e)},i)
      equation 
        e_1 = simplify(ASUB(e,i));
      then
        {INDEX(e_1)};
    case ({(s as INDEX(exp = _))},i) then {s,INDEX(ICONST(i))}; 
    case ((s :: ss),i)
      equation 
        ss_1 = subscriptsAppend(ss, i);
      then
        (s :: ss_1);
  end matchcontinue;
end subscriptsAppend;

public function typeString "
  - Printing expressions
 
  This module provides some functions to print data to the standard
  output.  This is used for error messages, and for debugging the
  semantic description.
"
  input Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType)
    local
      list<Ident> ss;
      Ident s1,ts,res;
      Type t;
      list<Integer> dims;
    case INT() then "INT"; 
    case REAL() then "REAL"; 
    case BOOL() then "BOOL"; 
    case STRING() then "STRING"; 
    case OTHER() then "OTHER"; 
    case (T_ARRAY(ty = t,arrayDimensions = dims))
      equation 
        ss = Util.listMap(dims, int_string);
        s1 = Util.stringDelimitList(ss, ", ");
        ts = typeString(t);
        res = Util.stringAppendList({"/tp:",ts,"[",s1,"]/"});
      then
        res;
  end matchcontinue;
end typeString;

public function printComponentRef "function: printComponentRef
 
  Print a `ComponentRef\'.
"
  input ComponentRef inComponentRef;
algorithm 
  _:=
  matchcontinue (inComponentRef)
    local
      Ident s;
      list<Subscript> subs;
      ComponentRef cr;
    case CREF_IDENT(ident = s,subscriptLst = subs)
      equation 
        printComponentRef2(s, subs);
      then
        ();
    case CREF_QUAL(ident = s,subscriptLst = subs,componentRef = cr) /* Does not handle names with underscores */ 
      equation 
        true = RTOpts.modelicaOutput();
        printComponentRef2(s, subs);
        Print.printBuf("__");
        printComponentRef(cr);
      then
        ();
    case CREF_QUAL(ident = s,subscriptLst = subs,componentRef = cr)
      equation 
        false = RTOpts.modelicaOutput();
        printComponentRef2(s, subs);
        Print.printBuf(".");
        printComponentRef(cr);
      then
        ();
  end matchcontinue;
end printComponentRef;

protected function printComponentRef2 "function: printComponentRef2
 
  Helper function to print_component_ref
"
  input String inString;
  input list<Subscript> inSubscriptLst;
algorithm 
  _:=
  matchcontinue (inString,inSubscriptLst)
    local
      Ident s;
      list<Subscript> l;
    case (s,{})
      equation 
        Print.printBuf(s);
      then
        ();
    case (s,l)
      equation 
        true = RTOpts.modelicaOutput();
        Print.printBuf(s);
        Print.printBuf("_L");
        printList(l, printSubscript, ",");
        Print.printBuf("_R");
      then
        ();
    case (s,l)
      equation 
        false = RTOpts.modelicaOutput();
        Print.printBuf(s);
        Print.printBuf("[");
        printList(l, printSubscript, ",");
        Print.printBuf("]");
      then
        ();
  end matchcontinue;
end printComponentRef2;

public function printSubscript "function: printSubscript
 
  Print a `Subscript\'.
"
  input Subscript inSubscript;
algorithm 
  _:=
  matchcontinue (inSubscript)
    local Exp e1;
    case (WHOLEDIM())
      equation 
        Print.printBuf(":");
      then
        ();
    case (INDEX(exp = e1))
      equation 
        printExp(e1);
      then
        ();
    case (SLICE(exp = e1))
      equation 
        printExp(e1);
      then
        ();
  end matchcontinue;
end printSubscript;

public function printExp "function: printExp
 
  This function prints a complete expression.
"
  input Exp e;
algorithm 
  printExp2(e, 0);
end printExp;

protected function printExp2 "function: printExp2
 
  Helper function to print_exp.
"
  input Exp inExp;
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inExp,inInteger)
    local
      Ident s,sym,fs,rstr,str;
      Integer x,pri2_1,pri2,pri3,pri1,i;
      Real r;
      ComponentRef c;
      Exp e1,e2,e21,e22,e,t,f,start,stop,step,cr,dim,exp,iterexp;
      Operator op;
      Type ty,ty2;
      Absyn.Path fcn;
      list<Exp> args,es;
    case (ICONST(integer = x),_)
      equation 
        s = intString(x);
        Print.printBuf(s);
      then
        ();
    case (RCONST(real = x),_)
      local Real x;
      equation 
        s = realString(x);
        Print.printBuf(s);
      then
        ();
    case (SCONST(string = s),_)
      equation 
        Print.printBuf("\"");
        Print.printBuf(s);
        Print.printBuf("\"");
      then
        ();
    case (BCONST(bool = false),_)
      equation 
        Print.printBuf("false");
      then
        ();
    case (BCONST(bool = true),_)
      equation 
        Print.printBuf("true");
      then
        ();
    case (CREF(componentRef = c),_)
      equation 
        printComponentRef(c);
      then
        ();
    case (BINARY(exp1 = e1,operator = (op as SUB(ty = ty)),exp2 = (e2 as BINARY(exp1 = e21,operator = SUB(ty = ty2),exp2 = e22))),pri1)
      equation 
        sym = binopSymbol(op);
        pri2_1 = binopPriority(op);
        pri2 = pri2_1 + 1;
        pri3 = printLeftpar(pri1, pri2) "binary minus have higher priority than itself" ;
        printExp2(e1, pri3);
        Print.printBuf(sym);
        printExp2(e2, pri2);
        printRightpar(pri1, pri2);
      then
        ();
    case (BINARY(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation 
        sym = binopSymbol(op);
        pri2 = binopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e1, pri3);
        Print.printBuf(sym);
        printExp2(e2, pri2);
        printRightpar(pri1, pri2);
      then
        ();
    case (UNARY(operator = op,exp = e),pri1)
      equation 
        sym = unaryopSymbol(op);
        pri2 = unaryopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        Print.printBuf(sym);
        printExp2(e, pri3);
        printRightpar(pri1, pri2);
      then
        ();
    case (LBINARY(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation 
        sym = lbinopSymbol(op);
        pri2 = lbinopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e1, pri3);
        Print.printBuf(sym);
        printExp2(e2, pri2);
        printRightpar(pri1, pri2);
      then
        ();
    case (LUNARY(operator = op,exp = e),pri1)
      equation 
        sym = lunaryopSymbol(op);
        pri2 = lunaryopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        Print.printBuf(sym);
        printExp2(e, pri3);
        printRightpar(pri1, pri2);
      then
        ();
    case (RELATION(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation 
        sym = relopSymbol(op);
        pri2 = relopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e1, pri3);
        Print.printBuf(sym);
        printExp2(e2, pri2);
        printRightpar(pri1, pri2);
      then
        ();
    case (IFEXP(expCond = c,expThen = t,expElse = f),pri1)
      local Exp c;
      equation 
        Print.printBuf("if ");
        printExp2(c, 0);
        Print.printBuf(" then ");
        printExp2(t, 0);
        Print.printBuf(" else ");
        printExp2(f, 0);
      then
        ();
    case (CALL(path = fcn,expLst = args),_)
      equation 
        fs = Absyn.pathString(fcn);
        Print.printBuf(fs);
        Print.printBuf("(");
        printList(args, printExp, ",");
        Print.printBuf(")");
      then
        ();
    case (ARRAY(array = es),_)
      equation 
        Print.printBuf("{") "Print.printBuf \"This an array: \" &" ;
        printList(es, printExp, ",");
        Print.printBuf("}");
      then
        ();
    case (TUPLE(PR = es),_) /* PR. */ 
      equation 
        Print.printBuf("(");
        printList(es, printExp, ",");
        Print.printBuf(")");
      then
        ();
    case (MATRIX(scalar = es),_)
      local list<list<tuple<Exp, Boolean>>> es;
      equation 
        Print.printBuf("<matrix>[");
        printList(es, printRow, ";");
        Print.printBuf("]");
      then
        ();
    case (RANGE(exp = start,expOption = NONE,range = stop),pri1)
      equation 
        pri2 = 41;
        pri3 = printLeftpar(pri1, pri2);
        printExp2(start, pri3);
        Print.printBuf(":");
        printExp2(stop, pri3);
        printRightpar(pri1, pri2);
      then
        ();
    case (RANGE(exp = start,expOption = SOME(step),range = stop),pri1)
      equation 
        pri2 = 41;
        pri3 = printLeftpar(pri1, pri2);
        printExp2(start, pri3);
        Print.printBuf(":");
        printExp2(step, pri3);
        Print.printBuf(":");
        printExp2(stop, pri3);
        printRightpar(pri1, pri2);
      then
        ();
    case (CAST(ty = REAL(),exp = ICONST(integer = i)),_)
      equation 
        false = RTOpts.modelicaOutput();
        r = intReal(i);
        rstr = realString(r);
        Print.printBuf(rstr);
      then
        ();
    case (CAST(ty = REAL(),exp = e),_)
      equation 
        false = RTOpts.modelicaOutput();
        Print.printBuf("Real(");
        printExp(e);
        Print.printBuf(")");
      then
        ();
    case (CAST(ty = REAL(),exp = e),_)
      equation 
        true = RTOpts.modelicaOutput();
        printExp(e);
      then
        ();
    case (ASUB(exp = e,sub = i),pri1)
      equation 
        pri2 = 51;
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e, pri3);
        printRightpar(pri1, pri2);
        Print.printBuf("<asub>[");
        s = intString(i);
        Print.printBuf(s);
        Print.printBuf("]");
      then
        ();
    case ((e as SIZE(exp = cr,sz = SOME(dim))),_)
      equation 
        str = printExpStr(e);
        Print.printBuf(str);
      then
        ();
    case ((e as SIZE(exp = cr,sz = NONE)),_)
      equation 
        str = printExpStr(e);
        Print.printBuf(str);
      then
        ();
    case ((e as REDUCTION(path = fcn,expr = exp,ident = i,range = iterexp)),_)
      local Ident i;
      equation 
        str = printExpStr(e);
        Print.printBuf(str);
      then
        ();
    case (_,_)
      equation 
        Print.printBuf("#UNKNOWN EXPRESSION# ----eee ");
      then
        ();
  end matchcontinue;
end printExp2;

protected function printLeftpar "function: printLeftpar
 
  Print a left paranthesis if priorities require it.
"
  input Integer inInteger1;
  input Integer inInteger2;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inInteger1,inInteger2)
    local Integer x,y,pri1,pri2;
    case (x,y) /* prio1 prio2 */ 
      equation 
        (x > y) = true;
        Print.printBuf("(");
      then
        0;
    case (pri1,pri2) then pri2; 
  end matchcontinue;
end printLeftpar;

protected function printRightpar "function: print_leftpar
 
  Print a left paranthesis if priorities require it.
"
  input Integer inInteger1;
  input Integer inInteger2;
algorithm 
  _:=
  matchcontinue (inInteger1,inInteger2)
    local Integer x,y;
    case (x,y) /* prio1 prio2 */ 
      equation 
        (x > y) = true;
        Print.printBuf(")");
      then
        ();
    case (_,_) then (); 
  end matchcontinue;
end printRightpar;

public function binopPriority "function: binopPriority
 
  Returns a priority number for each operator. Used to determine when
  parenthesis in expressions is required.
  priorities:
 
    and, or		10
    not		11
    <, >, =, != etc.	21
    bin +		32
    bin -		33
    			35
    /			36
    unary +, unary -	37
    ^			38
    :			41
    {}		51
 
  LS: Changed precedence for unary +-
   which must be higher than binary operators but lower than power
   according to e.g. matlab 
 
  LS: Changed precedence for binary - , should be higher than + and also
   itself, but this is specially handled in print_exp2 and print_exp2_str 
"
  input Operator inOperator;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inOperator)
    case (ADD(ty = _)) then 32; 
    case (SUB(ty = _)) then 33; 
    case (ADD_ARR(ty = _)) then 32; 
    case (SUB_ARR(ty = _)) then 33; 
    case (MUL(ty = _)) then 35; 
    case (MUL_SCALAR_ARRAY(ty = _)) then 35; 
    case (MUL_ARRAY_SCALAR(ty = _)) then 35; 
    case (MUL_SCALAR_PRODUCT(ty = _)) then 35; 
    case (MUL_MATRIX_PRODUCT(ty = _)) then 35; 
    case (DIV(ty = _)) then 36; 
    case (DIV_ARRAY_SCALAR(ty = _)) then 36; 
    case (POW(ty = _)) then 38; 
  end matchcontinue;
end binopPriority;

public function unaryopPriority "function: unaryopPriority
 
  Determine unary operator priorities, see binop_priority.
"
  input Operator inOperator;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inOperator)
    case (UMINUS(ty = _)) then 37; 
    case (UPLUS(ty = _)) then 37; 
    case (UMINUS_ARR(ty = _)) then 37; 
    case (UPLUS_ARR(ty = _)) then 37; 
  end matchcontinue;
end unaryopPriority;

public function lbinopPriority "function: lbinopPriority
 
  Determine logical binary operator priorities, see binop_priority.
"
  input Operator inOperator;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inOperator)
    case (AND()) then 10; 
    case (OR()) then 10; 
  end matchcontinue;
end lbinopPriority;

public function lunaryopPriority "function: lunaryopPriority
 
  Determine logical unary operator priorities, see binop_priority.
"
  input Operator inOperator;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inOperator)
    case (NOT()) then 11; 
  end matchcontinue;
end lunaryopPriority;

public function relopPriority "function: relopPriority
 
  Determine function operator priorities, see binop_priority.
"
  input Operator inOperator;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inOperator)
    case (LESS(ty = _)) then 21; 
    case (LESSEQ(ty = _)) then 21; 
    case (GREATER(ty = _)) then 21; 
    case (GREATEREQ(ty = _)) then 21; 
    case (EQUAL(ty = _)) then 21; 
    case (NEQUAL(ty = _)) then 21; 
  end matchcontinue;
end relopPriority;

public function makeRealAdd "function: makeRealAdd
  Construct an add node of the two expressions of type REAL
"
  input Exp inExp1;
  input Exp inExp2;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inExp2)
    local Exp e1,e2;
    case (e1,e2) then BINARY(e1,ADD(REAL()),e2); 
  end matchcontinue;
end makeRealAdd;

public function makeRealArray "function: makeRealArray
 
  Construct an array node of an Exp list of type REAL
"
  input list<Exp> inExpLst;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExpLst)
    local list<Exp> expl;
    case (expl) then ARRAY(REAL(),false,expl); 
  end matchcontinue;
end makeRealArray;

public function binopSymbol "function: binopSymbol
 
  Return a string representation of the Operator.
"
  input Operator inOperator;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inOperator)
    local
      Ident s;
      Operator op;
    case op
      equation 
        false = RTOpts.typeinfo();
        s = binopSymbol1(op);
      then
        s;
    case op
      equation 
        true = RTOpts.typeinfo();
        s = binopSymbol2(op);
      then
        s;
  end matchcontinue;
end binopSymbol;

public function binopSymbol1 "function: binopSymbol1
 
  Helper function to binop_symbol
"
  input Operator inOperator;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inOperator)
    case (ADD(ty = _)) then " + "; 
    case (SUB(ty = _)) then " - "; 
    case (MUL(ty = _)) then " * "; 
    case (DIV(ty = _)) then " / "; 
    case (POW(ty = _)) then " ^ "; 
    case (ADD_ARR(ty = _)) then " + "; 
    case (SUB_ARR(ty = _)) then " - "; 
    case (MUL_SCALAR_ARRAY(ty = _)) then " * "; 
    case (MUL_ARRAY_SCALAR(ty = _)) then " * "; 
    case (MUL_SCALAR_PRODUCT(ty = _)) then " * "; 
    case (MUL_MATRIX_PRODUCT(ty = _)) then " * "; 
    case (DIV_ARRAY_SCALAR(ty = _)) then " / "; 
  end matchcontinue;
end binopSymbol1;

protected function binopSymbol2 "function: binopSymbol2
 
  Helper function to binop_symbol.
"
  input Operator inOperator;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inOperator)
    local
      Ident ts,s,s_1;
      Type t;
    case (ADD(ty = t))
      equation 
        ts = typeString(t);
        s = stringAppend(" +<", ts);
        s_1 = stringAppend(s, "> ");
      then
        s_1;
    case (SUB(ty = t)) then " - "; 
    case (MUL(ty = t)) then " * "; 
    case (DIV(ty = t))
      equation 
        ts = typeString(t);
        s = stringAppend(" /<", ts);
        s_1 = stringAppend(s, "> ");
      then
        s_1;
    case (POW(ty = t)) then " ^ "; 
    case (ADD_ARR(ty = _)) then " + "; 
    case (SUB_ARR(ty = _)) then " - "; 
    case (MUL_SCALAR_ARRAY(ty = _)) then " * "; 
    case (MUL_ARRAY_SCALAR(ty = _)) then " * "; 
    case (MUL_SCALAR_PRODUCT(ty = _)) then " * "; 
    case (MUL_MATRIX_PRODUCT(ty = _)) then " * "; 
    case (DIV_ARRAY_SCALAR(ty = _)) then " / "; 
  end matchcontinue;
end binopSymbol2;

public function unaryopSymbol "function: unaryopSymbol
 
  Return string representation of unary operators.
"
  input Operator inOperator;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inOperator)
    case (UMINUS(ty = _)) then "-"; 
    case (UPLUS(ty = _)) then "+"; 
    case (UMINUS_ARR(ty = _)) then "-"; 
    case (UPLUS_ARR(ty = _)) then "+"; 
  end matchcontinue;
end unaryopSymbol;

public function lbinopSymbol "function: lbinopSymbol
 
  Return string representation of logical binary operator.
"
  input Operator inOperator;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inOperator)
    case (AND()) then " AND "; 
    case (OR()) then " OR "; 
  end matchcontinue;
end lbinopSymbol;

public function lunaryopSymbol "function: lunaryopSymbol
 
  Return string representation of logical unary operator.
"
  input Operator inOperator;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inOperator)
    case (NOT()) then " NOT "; 
  end matchcontinue;
end lunaryopSymbol;

public function relopSymbol "function: relopSymbol
 
  Return string representation of function operator.
"
  input Operator inOperator;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inOperator)
    case (LESS(ty = _)) then " < "; 
    case (LESSEQ(ty = _)) then " <= "; 
    case (GREATER(ty = _)) then " > "; 
    case (GREATEREQ(ty = _)) then " >= "; 
    case (EQUAL(ty = _)) then " == "; 
    case (NEQUAL(ty = _)) then " <> "; 
  end matchcontinue;
end relopSymbol;

public function printList "function: printList
 
  Print a list of values given a print-function and a separator
  string.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input String inString;
  replaceable type Type_a;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm 
  _:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo,inString)
    local
      Type_a h;
      FuncTypeType_aTo r;
      list<Type_a> t;
      Ident sep;
    case ({},_,_) then (); 
    case ({h},r,_)
      equation 
        r(h);
      then
        ();
    case ((h :: t),r,sep)
      equation 
        r(h);
        Print.printBuf(sep);
        printList(t, r, sep);
      then
        ();
  end matchcontinue;
end printList;

protected function printRow "function: printRow
 
  Print a list of expressions to the Print buffer.
"
  input list<tuple<Exp, Boolean>> es;
  list<Exp> es_1;
algorithm 
  es_1 := Util.listMap(es, Util.tuple21);
  printList(es_1, printExp, ",");
end printRow;

public function printComponentRefStr "function: print_component_ref
 
  Print a `ComponentRef\'.
 
 
  LS: print functions that return a string instead of printing 
  Had to duplicate the huge print_exp2 and modify              
  An alternative would be to implement \"sprint\" somehow        
  which would need internal state, with reset and              
  get_string methods                                           
                                                               
  Once these are tested and ok, the print_exp above can be    
  replaced by a call to these _str functions and printing      
  the result.                                                  
 
"
  input ComponentRef inComponentRef;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef)
    local
      Ident s,str,strrest,str_1,str_2;
      list<Subscript> subs;
      ComponentRef cr;
    case (CREF_IDENT(ident = s,subscriptLst = {})) then s;  /* optimize */ 
    case CREF_IDENT(ident = s,subscriptLst = subs)
      equation 
        str = printComponentRef2Str(s, subs);
      then
        str;
    case CREF_QUAL(ident = s,subscriptLst = subs,componentRef = cr) /* Does not handle names with underscores */ 
      equation 
        true = RTOpts.modelicaOutput();
        str = printComponentRef2Str(s, subs);
        strrest = printComponentRefStr(cr);
        str_1 = stringAppend(str, "__");
        str_2 = stringAppend(str_1, strrest);
      then
        str_2;
    case CREF_QUAL(ident = s,subscriptLst = subs,componentRef = cr)
      equation 
        false = RTOpts.modelicaOutput();
        str = printComponentRef2Str(s, subs);
        strrest = printComponentRefStr(cr);
        str_1 = stringAppend(str, ".");
        str_2 = stringAppend(str_1, strrest);
      then
        str_2;
  end matchcontinue;
end printComponentRefStr;

protected function printComponentRef2Str "function: printComponentRef2Str
 
  Helper function to print_component_ref_str.
"
  input Ident inIdent;
  input list<Subscript> inSubscriptLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inIdent,inSubscriptLst)
    local
      Ident s,str,str_1,str_2,str_3;
      list<Subscript> l;
    case (s,{}) then s; 
    case (s,l)
      equation 
        true = RTOpts.modelicaOutput();
        str = printListStr(l, printSubscriptStr, ",");
        str_1 = stringAppend(s, "_L");
        str_2 = stringAppend(str_1, str);
        str_3 = stringAppend(str_2, "_R");
      then
        str_3;
    case (s,l)
      equation 
        false = RTOpts.modelicaOutput();
        str = printListStr(l, printSubscriptStr, ",");
        str_1 = stringAppend(s, "[");
        str_2 = stringAppend(str_1, str);
        str_3 = stringAppend(str_2, "]");
      then
        str_3;
  end matchcontinue;
end printComponentRef2Str;

public function printListStr "function: printListStr
 
  Same as print_list, except it returns a string
  instead of printing
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  input String inString;
  output String outString;
  replaceable type Type_a;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm 
  outString:=
  matchcontinue (inTypeALst,inFuncTypeTypeAToString,inString)
    local
      Ident s,srest,s_1,s_2,sep;
      Type_a h;
      FuncTypeType_aToString r;
      list<Type_a> t;
    case ({},_,_) then ""; 
    case ({h},r,_)
      equation 
        s = r(h);
      then
        s;
    case ((h :: t),r,sep)
      equation 
        s = r(h);
        srest = printListStr(t, r, sep);
        s_1 = stringAppend(s, sep);
        s_2 = stringAppend(s_1, srest);
      then
        s_2;
  end matchcontinue;
end printListStr;

public function printSubscriptStr "function: printSubscriptStr
 
  Print a `Subscript\'.
"
  input Subscript inSubscript;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inSubscript)
    local
      Ident s;
      Exp e1;
    case (WHOLEDIM()) then ":"; 
    case (INDEX(exp = e1))
      equation 
        s = printExpStr(e1);
      then
        s;
    case (SLICE(exp = e1))
      equation 
        s = printExpStr(e1);
      then
        s;
  end matchcontinue;
end printSubscriptStr;

public function printExpStr "function: printExpStr
 
  This function prints a complete expression.
"
  input Exp e;
  output String s;
algorithm 
  s := printExp2Str(e, 0);
end printExpStr;

protected function printExp2Str "function: printExp2Str
 
  Helper function to print_exp_str.
"
  input Exp inExp;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExp,inInteger)
    local
      Ident s,s_1,s_2,sym,s1,s2,s3,s4,s_3,ifstr,thenstr,elsestr,res,fs,argstr,s5,s_4,s_5,res2,str,crstr,dimstr,expstr,iterstr,id;
      Integer x,pri2_1,pri2,pri3,pri1,ival,i;
      Real rval;
      ComponentRef c;
      Type t,ty,ty2,tp;
      Exp e1,e2,e21,e22,e,f,start,stop,step,cr,dim,exp,iterexp;
      Operator op;
      Absyn.Path fcn;
      list<Exp> args,es;
    case (END(),_) then "end"; 
    case (ICONST(integer = x),_)
      equation 
        s = intString(x);
      then
        s;
    case (RCONST(real = x),_)
      local Real x;
      equation 
        s = realString(x);
      then
        s;
    case (SCONST(string = s),_)
      equation 
        s_1 = stringAppend("\"", s);
        s_2 = stringAppend(s_1, "\"");
      then
        s_2;
    case (BCONST(bool = false),_) then "false"; 
    case (BCONST(bool = true),_) then "true"; 
    case (CREF(componentRef = c,ty = t),_)
      equation 
        s = printComponentRefStr(c);
      then
        s;
    case (BINARY(exp1 = e1,operator = (op as SUB(ty = ty)),exp2 = (e2 as BINARY(exp1 = e21,operator = SUB(ty = ty2),exp2 = e22))),pri1)
      equation 
        sym = binopSymbol(op);
        pri2_1 = binopPriority(op);
        pri2 = pri2_1 + 1;
        (s1,pri3) = printLeftparStr(pri1, pri2) "binary minus have higher priority than itself" ;
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, sym);
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;
    case (BINARY(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation 
        sym = binopSymbol(op);
        pri2 = binopPriority(op);
        (s1,pri3) = printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, sym);
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;
    case (UNARY(operator = op,exp = e),pri1)
      equation 
        sym = unaryopSymbol(op);
        pri2 = unaryopPriority(op);
        (s1,pri3) = printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e, pri3);
        s3 = printRightparStr(pri1, pri2);
        s = stringAppend(sym, s1);
        s_1 = stringAppend(s, s2);
        s_2 = stringAppend(s_1, s3);
      then
        s_2;
    case (LBINARY(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation 
        sym = lbinopSymbol(op);
        pri2 = lbinopPriority(op);
        (s1,pri3) = printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, sym);
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;
    case (LUNARY(operator = op,exp = e),pri1)
      equation 
        sym = lunaryopSymbol(op);
        pri2 = lunaryopPriority(op);
        (s1,pri3) = printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e, pri3);
        s3 = printRightparStr(pri1, pri2);
        s = stringAppend(s1, sym);
        s_1 = stringAppend(s, s2);
        s_2 = stringAppend(s_1, s3);
      then
        s_2;
    case (RELATION(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation 
        sym = relopSymbol(op);
        pri2 = relopPriority(op);
        (s1,pri3) = printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, sym);
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;
    case (IFEXP(expCond = c,expThen = t,expElse = f),_)
      local Exp c,t;
      equation 
        ifstr = printExp2Str(c, 0);
        thenstr = printExp2Str(t, 0);
        elsestr = printExp2Str(f, 0);
        res = Util.stringAppendList({"if ",ifstr," then ",thenstr," else ",elsestr});
      then
        res;
    case (CALL(path = fcn,expLst = args),_)
      equation 
        fs = Absyn.pathString(fcn);
        argstr = printListStr(args, printExpStr, ",");
        s = stringAppend(fs, "(");
        s_1 = stringAppend(s, argstr);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;
    case (ARRAY(array = es),_)
      equation 
        s = printListStr(es, printExpStr, ",");
        s_1 = stringAppend("{", s);
        s_2 = stringAppend(s_1, "}");
      then
        s_2;
    case (TUPLE(PR = es),_)
      equation 
        s = printListStr(es, printExpStr, ",");
        s_1 = stringAppend("(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;
    case (MATRIX(scalar = es),_)
      local list<list<tuple<Exp, Boolean>>> es;
      equation 
        s = printListStr(es, printRowStr, "},{");
        s_1 = stringAppend("{{", s);
        s_2 = stringAppend(s_1, "}}");
      then
        s_2;
    case (RANGE(exp = start,expOption = NONE,range = stop),pri1)
      equation 
        pri2 = 41;
        (s1,pri3) = printLeftparStr(pri1, pri2);
        s2 = printExp2Str(start, pri3);
        s3 = printExp2Str(stop, pri3);
        s4 = printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, ":");
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;
    case (RANGE(exp = start,expOption = SOME(step),range = stop),pri1)
      equation 
        pri2 = 41;
        (s1,pri3) = printLeftparStr(pri1, pri2);
        s2 = printExp2Str(start, pri3);
        s3 = printExp2Str(step, pri3);
        s4 = printExp2Str(stop, pri3);
        s5 = printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, ":");
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, ":");
        s_4 = stringAppend(s_3, s4);
        s_5 = stringAppend(s_4, s5);
      then
        s_5;
    case (CAST(ty = REAL(),exp = ICONST(integer = ival)),_)
      equation 
        false = RTOpts.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
      then
        res;
    case (CAST(ty = REAL(),exp = UNARY(operator = UMINUS(ty = _),exp = ICONST(integer = ival))),_)
      equation 
        false = RTOpts.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
        res2 = stringAppend("-", res);
      then
        res2;
    case (CAST(ty = REAL(),exp = e),_)
      equation 
        false = RTOpts.modelicaOutput();
        s = printExpStr(e);
        s_1 = stringAppend("Real(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;
    case (CAST(ty = REAL(),exp = e),_)
      equation 
        true = RTOpts.modelicaOutput();
        s = printExpStr(e);
      then
        s;
    case (CAST(ty = tp,exp = e),_)
      equation 
        str = typeString(tp);
        s = printExpStr(e);
        res = Util.stringAppendList({"CAST(",str,", ",s,")"});
      then
        res;
    case (ASUB(exp = e,sub = i),pri1)
      equation 
        pri2 = 51;
        (s1,pri3) = printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e, pri3);
        s3 = printRightparStr(pri1, pri2);
        s4 = intString(i);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, s3);
        s_2 = stringAppend(s_1, "[");
        s_3 = stringAppend(s_2, s4);
        s_4 = stringAppend(s_3, "]");
      then
        s_4;
    case (SIZE(exp = cr,sz = SOME(dim)),_)
      equation 
        crstr = printExpStr(cr);
        dimstr = printExpStr(dim);
        str = Util.stringAppendList({"size(",crstr,",",dimstr,")"});
      then
        str;
    case (SIZE(exp = cr,sz = NONE),_)
      equation 
        crstr = printExpStr(cr);
        str = Util.stringAppendList({"size(",crstr,")"});
      then
        str;
    case (REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp),_)
      equation 
        fs = Absyn.pathString(fcn);
        expstr = printExpStr(exp);
        iterstr = printExpStr(iterexp);
        str = Util.stringAppendList({"<reduction>",fs,"(",expstr," for ",id," in ",iterstr,")"});
      then
        str;
    case (_,_) then "#UNKNOWN EXPRESSION# ----eee "; 
  end matchcontinue;
end printExp2Str;

public function printRowStr "function: printRowStr
 
  Prints a list of expressions to a string.
"
  input list<tuple<Exp, Boolean>> es;
  output String s;
  list<Exp> es_1;
algorithm 
  es_1 := Util.listMap(es, Util.tuple21);
  s := printListStr(es_1, printExpStr, ",");
end printRowStr;

public function printLeftparStr "function: printLeftparStr
 
  Print a left parenthesis to a string if priorities require it.
"
  input Integer inInteger1;
  input Integer inInteger2;
  output String outString;
  output Integer outInteger;
algorithm 
  (outString,outInteger):=
  matchcontinue (inInteger1,inInteger2)
    local Integer x,y,pri1,pri2;
    case (x,y) /* prio1 prio2 */ 
      equation 
        (x > y) = true;
      then
        ("(",0);
    case (pri1,pri2) then ("",pri2); 
  end matchcontinue;
end printLeftparStr;

public function printRightparStr "function: printRightparStr
 
  Print a right parenthesis to a string if priorities require it.
"
  input Integer inInteger1;
  input Integer inInteger2;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger1,inInteger2)
    local Integer x,y;
    case (x,y)
      equation 
        (x > y) = true;
      then
        ")";
    case (_,_) then ""; 
  end matchcontinue;
end printRightparStr;

public function expEqual "function: expEqual
 
  Returns true if the two expressions are equal.
"
  input Exp inExp1;
  input Exp inExp2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp1,inExp2)
    local
      Integer c1,c2,i1,i2;
      Ident id1,id2;
      Boolean b1,c1_1,c2_1,b2,res,b3;
      Exp e11,e12,e21,e22,e1,e2,e13,e23,r1,r2;
      Operator op1,op2;
      list<Boolean> bs;
      Absyn.Path path1,path2;
      list<Exp> expl1,expl2;
      Type tp1,tp2;
    case (ICONST(integer = c1),ICONST(integer = c2)) then (c1 == c2); 
    case (RCONST(real = c1),RCONST(real = c2))
      local Real c1,c2;
      then
        (c1 ==. c2);
    case (SCONST(string = c1),SCONST(string = c2))
      local Ident c1,c2;
      equation 
        equality(c1 = c2);
      then
        true;
    case (BCONST(bool = c1),BCONST(bool = c2))
      local Boolean c1,c2;
      equation 
        b1 = boolAnd(c1, c2);
        c1_1 = boolNot(c1);
        c2_1 = boolNot(c2);
        b2 = boolAnd(c1_1, c2_1);
        res = boolOr(b1, b2);
      then
        res;
    case (CREF(componentRef = c1),CREF(componentRef = c2))
      local ComponentRef c1,c2;
      equation 
        res = crefEqual(c1, c2);
      then
        res;
    case (BINARY(exp1 = e11,operator = op1,exp2 = e12),BINARY(exp1 = e21,operator = op2,exp2 = e22))
      equation 
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    case (LBINARY(exp1 = e11,operator = op1,exp2 = e12),
          LBINARY(exp1 = e21,operator = op2,exp2 = e22))
      equation 
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    case (UNARY(operator = op1,exp = e1),UNARY(operator = op2,exp = e2))
      equation 
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e1, e2);
        res = boolAnd(b1, b2);
      then
        res;
    case (LUNARY(operator = op1,exp = e1),LUNARY(operator = op2,exp = e2))
      equation 
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e1, e2);
        res = boolAnd(b1, b2);
      then
        res;
    case (RELATION(exp1 = e11,operator = op1,exp2 = e12),RELATION(exp1 = e21,operator = op2,exp2 = e22))
      equation 
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    case (IFEXP(expCond = e11,expThen = e12,expElse = e13),IFEXP(expCond = e21,expThen = e22,expElse = e23))
      equation 
        b1 = expEqual(e13, e23);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    case (CALL(path = path1,expLst = expl1),CALL(path = path2,expLst = expl2))
      equation 
        b1 = ModUtil.pathEqual(path1, path2);
        bs = Util.listThreadMap(expl1, expl2, expEqual);
        res = Util.boolAndList((b1 :: bs));
      then
        res;
    case (ARRAY(ty = tp1,array = expl1),ARRAY(ty = tp2,array = expl2))
      equation 
        equality(tp1 = tp2);
        bs = Util.listThreadMap(expl1, expl2, expEqual);
        res = Util.boolAndList(bs);
      then
        res;
    case (MATRIX(ty = _),MATRIX(ty = _))
      equation 
        print("exp_equal for MATRIX not impl. yet.\n");
      then
        false;
    case (RANGE(ty = tp1,exp = e11,expOption = NONE,range = e13),RANGE(ty = tp2,exp = e21,expOption = NONE,range = e23))
      equation 
        b1 = expEqual(e13, e23);
        b2 = expEqual(e11, e21);
        res = Util.boolAndList({b1,b2});
      then
        res;
    case (RANGE(ty = tp1,exp = e11,expOption = SOME(e12),range = e13),RANGE(ty = tp2,exp = e21,expOption = SOME(e22),range = e23))
      equation 
        b1 = expEqual(e13, e23);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    case (TUPLE(PR = expl1),TUPLE(PR = expl2))
      equation 
        bs = Util.listThreadMap(expl1, expl2, expEqual);
        res = Util.boolAndList(bs);
      then
        res;
    case (CAST(ty = tp1,exp = e1),CAST(ty = tp2,exp = e2))
      equation 
        equality(tp1 = tp2);
        res = expEqual(e1, e2);
      then
        res;
    case (ASUB(exp = e1,sub = i1),ASUB(exp = e2,sub = i2))
      equation 
        b1 = (i1 == i2);
        b2 = expEqual(e1, e2);
        res = boolAnd(b1, b2);
      then
        res;
    case (SIZE(exp = e1,sz = NONE),SIZE(exp = e2,sz = NONE))
      equation 
        res = expEqual(e1, e2);
      then
        res;
    case (SIZE(exp = e1,sz = SOME(e11)),SIZE(exp = e2,sz = SOME(e22)))
      equation 
        b1 = expEqual(e1, e2);
        b2 = expEqual(e11, e22);
        res = boolAnd(b1, b2);
      then
        res;
    case (CODE(code = _),CODE(code = _))
      equation 
        print("exp_equal on CODE not impl.\n");
      then
        false;
    case (REDUCTION(path = path1,expr = e1,ident = id1,range = r1),REDUCTION(path = path2,expr = e2,ident = id2,range = r2))
      equation 
        equality(id1 = id2);
        b1 = ModUtil.pathEqual(path1, path2);
        b2 = expEqual(e1, e2);
        b3 = expEqual(r1, r2);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    case (END(),END()) then true; 
    case (_,_) then false; 
  end matchcontinue;
end expEqual;

protected function operatorEqual "function: operatorEqual
 
  Helper function to exp_equal.
"
  input Operator inOperator1;
  input Operator inOperator2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inOperator1,inOperator2)
    local
      Boolean res;
      Absyn.Path p1,p2;
    case (ADD(ty = _),ADD(ty = _)) then true; 
    case (SUB(ty = _),SUB(ty = _)) then true; 
    case (MUL(ty = _),MUL(ty = _)) then true; 
    case (DIV(ty = _),DIV(ty = _)) then true; 
    case (POW(ty = _),POW(ty = _)) then true; 
    case (UMINUS(ty = _),UMINUS(ty = _)) then true; 
    case (UMINUS_ARR(ty = _),UMINUS_ARR(ty = _)) then true; 
    case (UPLUS_ARR(ty = _),UPLUS_ARR(ty = _)) then true; 
    case (ADD_ARR(ty = _),ADD_ARR(ty = _)) then true; 
    case (SUB_ARR(ty = _),SUB_ARR(ty = _)) then true; 
    case (MUL_SCALAR_ARRAY(ty = _),MUL_SCALAR_ARRAY(ty = _)) then true; 
    case (MUL_ARRAY_SCALAR(ty = _),MUL_ARRAY_SCALAR(ty = _)) then true; 
    case (MUL_SCALAR_PRODUCT(ty = _),MUL_SCALAR_PRODUCT(ty = _)) then true; 
    case (MUL_MATRIX_PRODUCT(ty = _),MUL_MATRIX_PRODUCT(ty = _)) then true; 
    case (DIV_ARRAY_SCALAR(ty = _),DIV_ARRAY_SCALAR(ty = _)) then true; 
    case (POW_ARR(ty = _),POW_ARR(ty = _)) then true; 
    case (AND(),AND()) then true; 
    case (OR(),OR()) then true; 
    case (NOT(),NOT()) then true; 
    case (LESS(ty = _),LESS(ty = _)) then true; 
    case (LESSEQ(ty = _),LESSEQ(ty = _)) then true; 
    case (GREATER(ty = _),GREATER(ty = _)) then true; 
    case (GREATEREQ(ty = _),GREATEREQ(ty = _)) then true; 
    case (EQUAL(ty = _),EQUAL(ty = _)) then true; 
    case (NEQUAL(ty = _),NEQUAL(ty = _)) then true; 
    case (USERDEFINED(fqName = p1),USERDEFINED(fqName = p2))
      equation 
        res = ModUtil.pathEqual(p1, p2);
      then
        res;
    case (_,_) then false; 
  end matchcontinue;
end operatorEqual;

public function replaceExpList "function: replaceExpList.
 
  Replaces an expression with a list of several expressions. 
  NOTE: Not repreteadly applied, so the source and target lists must be 
  disjunct Useful for instance when replacing several variables at once 
  in an expression. 
"
  input Exp inExp1;
  input list<Exp> inExpLst2;
  input list<Exp> inExpLst3;
  output Exp outExp;
  output Integer outInteger;
algorithm 
  (outExp,outInteger):=
  matchcontinue (inExp1,inExpLst2,inExpLst3)
    local
      Exp e,e_1,e_2,s1,t1;
      Integer c1,c2,c;
      list<Exp> sr,tr;
    case (e,{},{}) then (e,0);  /* expr, source list, target list */ 
    case (e,(s1 :: sr),(t1 :: tr))
      equation 
        (e_1,c1) = replaceExp(e, s1, t1);
        (e_2,c2) = replaceExpList(e_1, sr, tr);
        c = c1 + c2;
      then
        (e_2,c);
  end matchcontinue;
end replaceExpList;

public function replaceExp "function: replaceExp
 
  Helper function to replace_exp_list.
"
  input Exp inExp1;
  input Exp inExp2;
  input Exp inExp3;
  output Exp outExp;
  output Integer outInteger;
algorithm 
  (outExp,outInteger):=
  matchcontinue (inExp1,inExp2,inExp3)
    local
      Exp expr,source,target,e1_1,e2_1,e1,e2,e3_1,e3,e_1,r_1,e,r,s;
      Integer c1,c2,c,c3,cnt_1,b,i;
      Operator op;
      list<Exp> expl_1,expl;
      list<Integer> cnt;
      Absyn.Path path,p;
      Boolean t;
      Type tp;
      Absyn.Code a;
      Ident id;
    case (expr,source,target) /* expr source expr target expr */ 
      equation 
        true = expEqual(expr, source);
      then
        (target,1);
    case (BINARY(exp1 = e1,operator = op,exp2 = e2),source,target)
      equation 
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (BINARY(e1_1,op,e2_1),c);
    case (LBINARY(exp1 = e1,operator = op,exp2 = e2),source,target)
      equation 
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (LBINARY(e1_1,op,e2_1),c);
    case (UNARY(operator = op,exp = e1),source,target)
      equation 
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (UNARY(op,e1_1),c);
    case (LUNARY(operator = op,exp = e1),source,target)
      equation 
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (LUNARY(op,e1_1),c);
    case (RELATION(exp1 = e1,operator = op,exp2 = e2),source,target)
      equation 
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (RELATION(e1_1,op,e2_1),c);
    case (IFEXP(expCond = e1,expThen = e2,expElse = e3),source,target)
      equation 
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        (e3_1,c3) = replaceExp(e3, source, target);
        c = Util.listReduce({c1,c2,c3}, int_add);
      then
        (IFEXP(e1_1,e2_1,e3_1),c);
    case (CALL(path = path,expLst = expl,tuple_ = t,builtin = c),source,target)
      local Boolean c;
      equation 
        expl_1 = Util.listMap22(expl, replaceExp, source, target);
        (expl_1,cnt) = Util.splitTuple2List(expl_1);
        cnt_1 = Util.listReduce(cnt, int_add);
      then
        (CALL(path,expl_1,t,c),cnt_1);
    case (ARRAY(ty = tp,scalar = c,array = expl),source,target)
      local Boolean c;
      equation 
        expl_1 = Util.listMap22(expl, replaceExp, source, target);
        (expl_1,cnt) = Util.splitTuple2List(expl_1);
        cnt_1 = Util.listReduce(cnt, int_add);
      then
        (ARRAY(tp,c,expl_1),cnt_1);
    case (MATRIX(ty = t,integer = b,scalar = expl),source,target)
      local
        list<list<tuple<Exp, Boolean>>> expl_1,expl;
        Integer cnt;
        Type t;
      equation 
        (expl_1,cnt) = replaceExpMatrix(expl, source, target);
      then
        (MATRIX(t,b,expl_1),cnt);
    case (RANGE(ty = tp,exp = e1,expOption = NONE,range = e2),source,target)
      equation 
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (RANGE(tp,e1_1,NONE,e2_1),c);
    case (RANGE(ty = tp,exp = e1,expOption = SOME(e3),range = e2),source,target)
      equation 
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        (e3_1,c3) = replaceExp(e3, source, target);
        c = Util.listReduce({c1,c2,c3}, int_add);
      then
        (RANGE(tp,e1_1,SOME(e3_1),e2_1),c);
    case (TUPLE(PR = expl),source,target)
      equation 
        expl_1 = Util.listMap22(expl, replaceExp, source, target);
        (expl_1,cnt) = Util.splitTuple2List(expl_1);
        cnt_1 = Util.listReduce(cnt, int_add);
      then
        (TUPLE(expl_1),cnt_1);
    case (CAST(ty = tp,exp = e1),source,target)
      equation 
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (CAST(tp,e1_1),c);
    case (ASUB(exp = e1,sub = i),source,target)
      equation 
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (ASUB(e1_1,i),c);
    case (SIZE(exp = e1,sz = NONE),source,target)
      equation 
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (SIZE(e1_1,NONE),c);
    case (SIZE(exp = e1,sz = SOME(e2)),source,target)
      equation 
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (SIZE(e1_1,SOME(e2_1)),c);
    case (CODE(code = a,ty = b),source,target)
      local Type b;
      equation 
        print("replace_exp on CODE not impl.\n");
      then
        (CODE(a,b),0);
    case (REDUCTION(path = p,expr = e,ident = id,range = r),source,target)
      equation 
        (e_1,c1) = replaceExp(e, source, target);
        (r_1,c2) = replaceExp(r, source, target);
        c = c1 + c2;
      then
        (REDUCTION(p,e_1,id,r_1),c);
    case (e,s,_) then (e,0); 
  end matchcontinue;
end replaceExp;

protected function replaceExpMatrix "function: replaceExpMatrix
  author: PA
 
  Helper function to replace_exp, traverses Matrix expression list.
"
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst1;
  input Exp inExp2;
  input Exp inExp3;
  output list<list<tuple<Exp, Boolean>>> outTplExpBooleanLstLst;
  output Integer outInteger;
algorithm 
  (outTplExpBooleanLstLst,outInteger):=
  matchcontinue (inTplExpBooleanLstLst1,inExp2,inExp3)
    local
      Exp str,dst,src;
      list<tuple<Exp, Boolean>> e_1,e;
      Integer c1,c2,c;
      list<list<tuple<Exp, Boolean>>> es_1,es;
    case ({},str,dst) then ({},0); 
    case ((e :: es),src,dst)
      equation 
        (e_1,c1) = replaceExpMatrix2(e, src, dst);
        (es_1,c2) = replaceExpMatrix(es, src, dst);
        c = c1 + c2;
      then
        ((e_1 :: es_1),c);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "-replace_exp_matrix failed\n");
      then
        fail();
  end matchcontinue;
end replaceExpMatrix;

protected function replaceExpMatrix2 "function: replaceExpMatrix2
  author: PA
 
  Helper function to replace_exp_matrix
"
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst1;
  input Exp inExp2;
  input Exp inExp3;
  output list<tuple<Exp, Boolean>> outTplExpBooleanLst;
  output Integer outInteger;
algorithm 
  (outTplExpBooleanLst,outInteger):=
  matchcontinue (inTplExpBooleanLst1,inExp2,inExp3)
    local
      list<tuple<Exp, Boolean>> es_1,es;
      Integer c1,c2,c;
      Exp e_1,e,src,dst;
      Boolean b;
    case ({},_,_) then ({},0); 
    case (((e,b) :: es),src,dst)
      equation 
        (es_1,c1) = replaceExpMatrix2(es, src, dst);
        (e_1,c2) = replaceExp(e, src, dst);
        c = c1 + c2;
      then
        (((e_1,b) :: es_1),c);
  end matchcontinue;
end replaceExpMatrix2;

public function crefIsFirstArrayElt "function: crefIsFirstArrayElt
 
  This function returns true for component references that
  are arrays and references the first element of the array.
  like for instance a.b{1,1} and a{1} returns true but
  a.b{1,2} or a{2} returns false.
"
  input ComponentRef inComponentRef;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef)
    local
      list<Subscript> subs;
      list<Exp> exps;
      list<Boolean> bools;
      ComponentRef cr;
    case (cr)
      equation 
        ((subs as (_ :: _))) = crefLastSubs(cr);
        exps = Util.listMap(subs, subscriptExp);
        bools = Util.listMap(exps, isOne);
        true = Util.boolAndList(bools);
      then
        true;
    case (_) then false; 
  end matchcontinue;
end crefIsFirstArrayElt;

public function stringifyComponentRef "function: stringifyComponentRef
 
  Translates a ComponentRef into a CREF_IDENT by putting the string
  representation of the ComponentRef into it.
  
  See also stringigy_crefs.
"
  input ComponentRef cr;
  output ComponentRef outComponentRef;
  list<Subscript> subs;
  ComponentRef cr_1;
  Ident crs;
algorithm 
  subs := crefLastSubs(cr);
  cr_1 := crefStripLastSubs(cr) "PA" ;
  crs := printComponentRefStr(cr_1);
  outComponentRef := CREF_IDENT(crs,subs);
end stringifyComponentRef;

public function stringifyCrefs "function: stringifyCrefs
 
  This function takes an expression and transforms all component reference 
  names contained in the expression to a simpler form.
  For instance CREF_QUAL(\"a\",{}, CREF_IDENT(\"b\",{})) becomes
  CREF_IDENT(\"a.b\",{})
"
  input Exp inExp;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp)
    local
      Exp e,e1_1,e2_1,e1,e2,e_1,e3_1,e3;
      ComponentRef cr_1,cr;
      Type t;
      Operator op;
      list<Exp> expl_1,expl;
      Absyn.Path p;
      Boolean b;
      Integer i;
      Ident id;
    case ((e as ICONST(integer = _))) then e; 
    case ((e as RCONST(real = _))) then e; 
    case ((e as SCONST(string = _))) then e; 
    case ((e as BCONST(bool = _))) then e; 
    case (CREF(componentRef = cr,ty = t))
      equation 
        cr_1 = stringifyComponentRef(cr);
      then
        CREF(cr_1,t);
    case (BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
      then
        BINARY(e1_1,op,e2_1);
    case (UNARY(operator = op,exp = e))
      equation 
        e_1 = stringifyCrefs(e);
      then
        UNARY(op,e_1);
    case (LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
      then
        LBINARY(e1_1,op,e2_1);
    case (LUNARY(operator = op,exp = e))
      equation 
        e_1 = stringifyCrefs(e);
      then
        LUNARY(op,e_1);
    case (RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
      then
        RELATION(e1_1,op,e2_1);
    case (IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation 
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
        e3_1 = stringifyCrefs(e3);
      then
        IFEXP(e1_1,e2_1,e3_1);
    case (CALL(path = p,expLst = expl,tuple_ = t,builtin = b))
      local Boolean t;
      equation 
        expl_1 = Util.listMap(expl, stringifyCrefs);
      then
        CALL(p,expl_1,t,b);
    case (ARRAY(ty = t,scalar = b,array = expl))
      equation 
        expl_1 = Util.listMap(expl, stringifyCrefs);
      then
        ARRAY(t,b,expl_1);
    case ((e as MATRIX(ty = t,integer = b,scalar = expl)))
      local
        list<list<tuple<Exp, Boolean>>> expl_1,expl;
        Integer b;
      equation 
        expl_1 = stringifyCrefsMatrix(expl);
      then
        MATRIX(t,b,expl_1);
    case (RANGE(ty = t,exp = e1,expOption = SOME(e2),range = e3))
      equation 
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
        e3_1 = stringifyCrefs(e3);
      then
        RANGE(t,e1_1,SOME(e2_1),e3_1);
    case (RANGE(ty = t,exp = e1,expOption = NONE,range = e3))
      equation 
        e1_1 = stringifyCrefs(e1);
        e3_1 = stringifyCrefs(e3);
      then
        RANGE(t,e1_1,NONE,e3_1);
    case (TUPLE(PR = expl))
      equation 
        expl_1 = Util.listMap(expl, stringifyCrefs);
      then
        TUPLE(expl_1);
    case (CAST(ty = t,exp = e1))
      equation 
        e1_1 = stringifyCrefs(e1);
      then
        CAST(t,e1_1);
    case (ASUB(exp = e1,sub = i))
      equation 
        e1_1 = stringifyCrefs(e1);
      then
        ASUB(e1_1,i);
    case (SIZE(exp = e1,sz = SOME(e2)))
      equation 
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
      then
        SIZE(e1_1,SOME(e2_1));
    case (SIZE(exp = e1,sz = NONE))
      equation 
        e1_1 = stringifyCrefs(e1);
      then
        SIZE(e1_1,NONE);
    case ((e as CODE(code = _))) then e; 
    case (REDUCTION(path = p,expr = e1,ident = id,range = e2))
      equation 
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
      then
        REDUCTION(p,e1_1,id,e2_1);
    case END() then END(); 
    case (e) then e; 
  end matchcontinue;
end stringifyCrefs;

protected function stringifyCrefsMatrix "function: stringifyCrefsMatrix
  author: PA
 
  Helper function to stringify_crefs. Handles matrix expresion list.
"
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst;
  output list<list<tuple<Exp, Boolean>>> outTplExpBooleanLstLst;
algorithm 
  outTplExpBooleanLstLst:=
  matchcontinue (inTplExpBooleanLstLst)
    local
      list<tuple<Exp, Boolean>> e_1,e;
      list<list<tuple<Exp, Boolean>>> es_1,es;
    case ({}) then {}; 
    case ((e :: es))
      equation 
        e_1 = stringifyCrefsMatrix2(e);
        es_1 = stringifyCrefsMatrix(es);
      then
        (e_1 :: es_1);
  end matchcontinue;
end stringifyCrefsMatrix;

protected function stringifyCrefsMatrix2 "function: stringifyCrefsMatrix2
  author: PA
 
  Helper function to stringify_crefs_matrix
"
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst;
  output list<tuple<Exp, Boolean>> outTplExpBooleanLst;
algorithm 
  outTplExpBooleanLst:=
  matchcontinue (inTplExpBooleanLst)
    local
      Exp e_1,e;
      list<tuple<Exp, Boolean>> es_1,es;
      Boolean b;
    case ({}) then {}; 
    case (((e,b) :: es))
      equation 
        e_1 = stringifyCrefs(e);
        es_1 = stringifyCrefsMatrix2(es);
      then
        ((e_1,b) :: es_1);
  end matchcontinue;
end stringifyCrefsMatrix2;

public function dumpExpGraphviz "function: dumpExpGraphviz
 
  Creates a Graphviz Node from an Expression.
"
  input Exp inExp;
  output Graphviz.Node outNode;
algorithm 
  outNode:=
  matchcontinue (inExp)
    local
      Ident s,s_1,s_2,sym,fs,tystr,istr,id;
      Integer x,i;
      ComponentRef c;
      Graphviz.Node lt,rt,ct,tt,ft,t1,t2,t3,crt,dimt,expt,itert;
      Exp e1,e2,e,t,f,start,stop,step,cr,dim,exp,iterexp;
      Operator op;
      list<Graphviz.Node> argnodes,nodes;
      Absyn.Path fcn;
      list<Exp> args,es;
      Type ty;
    case (END()) then Graphviz.NODE("END",{},{}); 
    case (ICONST(integer = x))
      equation 
        s = intString(x);
      then
        Graphviz.LNODE("ICONST",{s},{},{});
    case (RCONST(real = x))
      local Real x;
      equation 
        s = realString(x);
      then
        Graphviz.LNODE("RCONST",{s},{},{});
    case (SCONST(string = s))
      equation 
        s_1 = stringAppend("\"", s);
        s_2 = stringAppend(s_1, "\"");
      then
        Graphviz.LNODE("SCONST",{s_2},{},{});
    case (BCONST(bool = false)) then Graphviz.LNODE("BCONST",{"false"},{},{}); 
    case (BCONST(bool = true)) then Graphviz.LNODE("BCONST",{"true"},{},{}); 
    case (CREF(componentRef = c))
      equation 
        s = printComponentRefStr(c);
      then
        Graphviz.LNODE("CREF",{s},{},{});
    case (BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        sym = binopSymbol(op);
        lt = dumpExpGraphviz(e1);
        rt = dumpExpGraphviz(e2);
      then
        Graphviz.LNODE("BINARY",{sym},{},{lt,rt});
    case (UNARY(operator = op,exp = e))
      equation 
        sym = unaryopSymbol(op);
        ct = dumpExpGraphviz(e);
      then
        Graphviz.LNODE("UNARY",{sym},{},{ct});
    case (LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        sym = lbinopSymbol(op);
        lt = dumpExpGraphviz(e1);
        rt = dumpExpGraphviz(e2);
      then
        Graphviz.LNODE("LBINARY",{sym},{},{lt,rt});
    case (LUNARY(operator = op,exp = e))
      equation 
        sym = lunaryopSymbol(op);
        ct = dumpExpGraphviz(e);
      then
        Graphviz.LNODE("LUNARY",{sym},{},{ct});
    case (RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation 
        sym = relopSymbol(op);
        lt = dumpExpGraphviz(e1);
        rt = dumpExpGraphviz(e2);
      then
        Graphviz.LNODE("RELATION",{sym},{},{lt,rt});
    case (IFEXP(expCond = c,expThen = t,expElse = f))
      local Exp c;
      equation 
        ct = dumpExpGraphviz(c);
        tt = dumpExpGraphviz(t);
        ft = dumpExpGraphviz(f);
      then
        Graphviz.NODE("IFEXP",{},{ct,tt,ft});
    case (CALL(path = fcn,expLst = args))
      equation 
        fs = Absyn.pathString(fcn);
        argnodes = Util.listMap(args, dumpExpGraphviz);
      then
        Graphviz.LNODE("CALL",{fs},{},argnodes);
    case (ARRAY(array = es))
      equation 
        nodes = Util.listMap(es, dumpExpGraphviz);
      then
        Graphviz.NODE("ARRAY",{},nodes);
    case (TUPLE(PR = es))
      equation 
        nodes = Util.listMap(es, dumpExpGraphviz);
      then
        Graphviz.NODE("TUPLE",{},nodes);
    case (MATRIX(scalar = es))
      local list<list<tuple<Exp, Boolean>>> es;
      equation 
        s = printListStr(es, printRowStr, "},{");
        s_1 = stringAppend("{{", s);
        s_2 = stringAppend(s_1, "}}");
      then
        Graphviz.LNODE("MATRIX",{s_2},{},{});
    case (RANGE(exp = start,expOption = NONE,range = stop))
      equation 
        t1 = dumpExpGraphviz(start);
        t2 = Graphviz.NODE(":",{},{});
        t3 = dumpExpGraphviz(stop);
      then
        Graphviz.NODE("RANGE",{},{t1,t2,t3});
    case (RANGE(exp = start,expOption = SOME(step),range = stop))
      equation 
        t1 = dumpExpGraphviz(start);
        t2 = dumpExpGraphviz(step);
        t3 = dumpExpGraphviz(stop);
      then
        Graphviz.NODE("RANGE",{},{t1,t2,t3});
    case (CAST(ty = ty,exp = e))
      equation 
        tystr = typeString(ty);
        ct = dumpExpGraphviz(e);
      then
        Graphviz.LNODE("CAST",{tystr},{},{ct});
    case (ASUB(exp = e,sub = i))
      equation 
        ct = dumpExpGraphviz(e);
        istr = intString(i);
        s = Util.stringAppendList({"[",istr,"]"});
      then
        Graphviz.LNODE("ASUB",{s},{},{ct});
    case (SIZE(exp = cr,sz = SOME(dim)))
      equation 
        crt = dumpExpGraphviz(cr);
        dimt = dumpExpGraphviz(dim);
      then
        Graphviz.NODE("SIZE",{},{crt,dimt});
    case (SIZE(exp = cr,sz = NONE))
      equation 
        crt = dumpExpGraphviz(cr);
      then
        Graphviz.NODE("SIZE",{},{crt});
    case (REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp))
      equation 
        fs = Absyn.pathString(fcn);
        expt = dumpExpGraphviz(exp);
        itert = dumpExpGraphviz(iterexp);
      then
        Graphviz.LNODE("REDUCTION",{fs},{},{expt,itert});
    case (_) then Graphviz.NODE("#UNKNOWN EXPRESSION# ----eeestr ",{},{}); 
  end matchcontinue;
end dumpExpGraphviz;

protected function genStringNTime "function:get_string_n_time
 
  Appends the string to itself n times.
"
  input String inString;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inString,inInteger)
    local
      Ident str,new_str,res_str;
      Integer new_level,level;
    case (str,0) then "";  /* n */ 
    case (str,level)
      equation 
        new_level = level + (-1);
        new_str = genStringNTime(str, new_level);
        res_str = stringAppend(str, new_str);
      then
        res_str;
  end matchcontinue;
end genStringNTime;

public function dumpExpStr "function: dumpExpStr
 
  Dumps expression to a string.
"
  input Exp inExp;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExp,inInteger)
    local
      Ident gen_str,res_str,s,s_1,s_2,sym,lt,rt,ct,tt,ft,fs,argnodes_1,nodes_1,t1,t2,t3,tystr,istr,crt,dimt,expt,itert,id;
      Integer level,x,new_level1,new_level2,new_level3,i;
      ComponentRef c;
      Exp e1,e2,e,t,f,start,stop,step,cr,dim,exp,iterexp;
      Operator op;
      list<Ident> argnodes,nodes;
      Absyn.Path fcn;
      list<Exp> args,es;
      Type ty;
    case (END(),level)
      equation 
        gen_str = genStringNTime("   |", level);
        res_str = Util.stringAppendList({gen_str,"END","\n"});
      then
        res_str;
    case (ICONST(integer = x),level) /* Graphviz.LNODE(\"ICONST\",{s},{},{}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        s = intString(x);
        res_str = Util.stringAppendList({gen_str,"ICONST ",s,"\n"});
      then
        res_str;
    case (RCONST(real = x),level) /* Graphviz.LNODE(\"RCONST\",{s},{},{}) */ 
      local Real x;
      equation 
        gen_str = genStringNTime("   |", level);
        s = realString(x);
        res_str = Util.stringAppendList({gen_str,"RCONST ",s,"\n"});
      then
        res_str;
    case (SCONST(string = s),level) /* Graphviz.LNODE(\"SCONST\",{s\'\'},{},{}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        s_1 = stringAppend("\"", s);
        s_2 = stringAppend(s_1, "\"");
        res_str = Util.stringAppendList({gen_str,"SCONST ",s_2,"\n"});
      then
        res_str;
    case (BCONST(bool = false),level) /* Graphviz.LNODE(\"BCONST\",{\"false\"},{},{}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        res_str = Util.stringAppendList({gen_str,"BCONST ","false","\n"});
      then
        res_str;
    case (BCONST(bool = true),level) /* Graphviz.LNODE(\"BCONST\",{\"true\"},{},{}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        res_str = Util.stringAppendList({gen_str,"BCONST ","true","\n"});
      then
        res_str;
    case (CREF(componentRef = c),level) /* Graphviz.LNODE(\"CREF\",{s},{},{}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        s = printComponentRefStr(c);
        res_str = Util.stringAppendList({gen_str,"CREF ",s,"\n"});
      then
        res_str;
    case (BINARY(exp1 = e1,operator = op,exp2 = e2),level) /* Graphviz.LNODE(\"BINARY\",{sym},{},{lt,rt}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        sym = binopSymbol(op);
        lt = dumpExpStr(e1, new_level1);
        rt = dumpExpStr(e2, new_level2);
        res_str = Util.stringAppendList({gen_str,"BINARY ",sym,"\n",lt,rt,""});
      then
        res_str;
    case (UNARY(operator = op,exp = e),level) /* Graphviz.LNODE(\"UNARY\",{sym},{},{ct}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        sym = unaryopSymbol(op);
        ct = dumpExpStr(e, new_level1);
        res_str = Util.stringAppendList({gen_str,"UNARY ",sym,"\n",ct,""});
      then
        res_str;
    case (LBINARY(exp1 = e1,operator = op,exp2 = e2),level) /* Graphviz.LNODE(\"LBINARY\",{sym},{},{lt,rt}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        sym = lbinopSymbol(op);
        lt = dumpExpStr(e1, new_level1);
        rt = dumpExpStr(e2, new_level2);
        res_str = Util.stringAppendList({gen_str,"LBINARY ",sym,"\n",lt,rt,""});
      then
        res_str;
    case (LUNARY(operator = op,exp = e),level) /* Graphviz.LNODE(\"LUNARY\",{sym},{},{ct}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        sym = lunaryopSymbol(op);
        ct = dumpExpStr(e, new_level1);
        res_str = Util.stringAppendList({gen_str,"LUNARY ",sym,"\n",ct,""});
      then
        res_str;
    case (RELATION(exp1 = e1,operator = op,exp2 = e2),level) /* Graphviz.LNODE(\"RELATION\",{sym},{},{lt,rt}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        sym = relopSymbol(op);
        lt = dumpExpStr(e1, new_level1);
        rt = dumpExpStr(e2, new_level2);
        res_str = Util.stringAppendList({gen_str,"RELATION ",sym,"\n",lt,rt,""});
      then
        res_str;
    case (IFEXP(expCond = c,expThen = t,expElse = f),level) /* Graphviz.NODE(\"IFEXP\",{},{ct,tt,ft}) */ 
      local Exp c;
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        new_level3 = level + 1;
        ct = dumpExpStr(c, new_level1);
        tt = dumpExpStr(t, new_level2);
        ft = dumpExpStr(f, new_level3);
        res_str = Util.stringAppendList({gen_str,"IFEXP ","\n",ct,tt,ft,""});
      then
        res_str;
    case (CALL(path = fcn,expLst = args),level) /* Graphviz.LNODE(\"CALL\",{fs},{},argnodes) Graphviz.NODE(\"ARRAY\",{},nodes) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        fs = Absyn.pathString(fcn);
        new_level1 = level + 1;
        argnodes = Util.listMap1(args, dumpExpStr, new_level1);
        argnodes_1 = Util.stringAppendList(argnodes);
        res_str = Util.stringAppendList({gen_str,"CALL ",fs,"\n",argnodes_1,""});
      then
        res_str;
    case (ARRAY(array = es),level)
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        nodes = Util.listMap1(es, dumpExpStr, new_level1);
        nodes_1 = Util.stringAppendList(nodes);
        res_str = Util.stringAppendList({gen_str,"ARRAY ",nodes_1,"\n"});
      then
        res_str;
    case (TUPLE(PR = es),level) /* Graphviz.NODE(\"TUPLE\",{},nodes) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        nodes = Util.listMap1(es, dumpExpStr, new_level1);
        nodes_1 = Util.stringAppendList(nodes);
        res_str = Util.stringAppendList({gen_str,"TUPLE ",nodes_1,"\n"});
      then
        res_str;
    case (MATRIX(scalar = es),level) /* Graphviz.LNODE(\"MATRIX\",{s\'\'},{},{}) */ 
      local list<list<tuple<Exp, Boolean>>> es;
      equation 
        gen_str = genStringNTime("   |", level);
        s = printListStr(es, printRowStr, "},{");
        s_1 = stringAppend("{{", s);
        s_2 = stringAppend(s_1, "}}");
        res_str = Util.stringAppendList({gen_str,"MATRIX ","\n",s_2,"","\n"});
      then
        res_str;
    case (RANGE(exp = start,expOption = NONE,range = stop),level) /* Graphviz.NODE(\"RANGE\",{},{t1,t2,t3}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        t1 = dumpExpStr(start, new_level1);
        t2 = ":";
        t3 = dumpExpStr(stop, new_level2);
        res_str = Util.stringAppendList({gen_str,"RANGE ","\n",t1,t2,t3,""});
      then
        res_str;
    case (RANGE(exp = start,expOption = SOME(step),range = stop),level) /* Graphviz.NODE(\"RANGE\",{},{t1,t2,t3}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        new_level3 = level + 1;
        t1 = dumpExpStr(start, new_level1);
        t2 = dumpExpStr(step, new_level2);
        t3 = dumpExpStr(stop, new_level3);
        res_str = Util.stringAppendList({gen_str,"RANGE ","\n",t1,t2,t3,""});
      then
        res_str;
    case (CAST(ty = ty,exp = e),level) /* Graphviz.LNODE(\"CAST\",{tystr},{},{ct}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        tystr = typeString(ty);
        ct = dumpExpStr(e, new_level1);
        res_str = Util.stringAppendList({gen_str,"CAST ","\n",ct,""});
      then
        res_str;
    case (ASUB(exp = e,sub = i),level) /* Graphviz.LNODE(\"ASUB\",{s},{},{ct}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        ct = dumpExpStr(e, new_level1);
        istr = intString(i);
        s = Util.stringAppendList({"[",istr,"]"});
        res_str = Util.stringAppendList({gen_str,"ASUB ","\n",s,ct,""});
      then
        res_str;
    case (SIZE(exp = cr,sz = SOME(dim)),level) /* Graphviz.NODE(\"SIZE\",{},{crt,dimt}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        crt = dumpExpStr(cr, new_level1);
        dimt = dumpExpStr(dim, new_level2);
        res_str = Util.stringAppendList({gen_str,"SIZE ","\n",crt,dimt,""});
      then
        res_str;
    case (SIZE(exp = cr,sz = NONE),level) /* Graphviz.NODE(\"SIZE\",{},{crt}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        crt = dumpExpStr(cr, new_level1);
        res_str = Util.stringAppendList({gen_str,"SIZE ","\n",crt,""});
      then
        res_str;
    case (REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp),level) /* Graphviz.LNODE(\"REDUCTION\",{fs},{},{expt,itert}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        fs = Absyn.pathString(fcn);
        expt = dumpExpStr(exp, new_level1);
        itert = dumpExpStr(iterexp, new_level2);
        res_str = Util.stringAppendList({gen_str,"REDUCTION ","\n",expt,itert,""});
      then
        res_str;
    case (_,level) /* Graphviz.NODE(\"#UNKNOWN EXPRESSION# ----eeestr \",{},{}) */ 
      equation 
        gen_str = genStringNTime("   |", level);
        res_str = Util.stringAppendList({gen_str," UNKNOWN EXPRESSION ","\n"});
      then
        res_str;
  end matchcontinue;
end dumpExpStr;

public function solve "function: solve
 
  Solves an equation consisting of a right hand side (rhs) and a left hand 
  side (lhs), with respect to the expression given as third argument, 
  usually a variable. 
"
  input Exp inExp1;
  input Exp inExp2;
  input Exp inExp3;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inExp2,inExp3)
    local
      Exp crexp,rhs,lhs,res,res_1,cr,e1,e2,e3;
      ComponentRef cr1,cr2;
    case ((crexp as CREF(componentRef = cr1)),rhs,CREF(componentRef = cr2)) /* lhs, rhs, solve for Special case when already solved, cr1 = rhs
	    otherwise division by zero when dividing with derivative */ 
      equation 
        true = crefEqual(cr1, cr2);
        false = expContains(rhs, crexp);
      then
        rhs;
    case (lhs,(crexp as CREF(componentRef = cr1)),CREF(componentRef = cr2)) /* Special case when already solved, lhs = cr1
 	  otherwise division by zero  when dividing with derivative */ 
      equation 
        true = crefEqual(cr1, cr2);
        false = expContains(lhs, crexp);
      then
        lhs;
    case (lhs,rhs,(cr as CREF(componentRef = _)))
      equation 
        res = solve2(lhs, rhs, cr);
        res_1 = simplify(res);
      then
        res_1;
    case (e1,e2,e3)
      equation 
        Debug.fprint("failtrace", "solve failed\n");
      then
        fail();
  end matchcontinue;
end solve;

protected function solve2 "function: solve2
 
  This function solves an equation e1 = e2 with respect to the variable
  given as an expression e3 
"
  input Exp inExp1;
  input Exp inExp2;
  input Exp inExp3;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inExp2,inExp3)
    local
      Exp lhs,lhsder,lhsder_1,lhszero,lhszero_1,rhs,rhs_1,e1,e2,crexp;
      ComponentRef cr;
    case (e1,e2,(crexp as CREF(componentRef = cr))) /* e1 e2 e3 */ 
      equation 
        lhs = BINARY(e1,SUB(REAL()),e2);
        lhsder = Derive.differentiateExp(lhs, cr);
        lhsder_1 = simplify(lhsder);
        false = expContains(lhsder_1, crexp);
        (lhszero,_) = replaceExp(lhs, crexp, RCONST(0.0));
        lhszero_1 = simplify(lhszero);
        rhs = UNARY(UMINUS(REAL()),BINARY(lhszero_1,DIV(REAL()),lhsder_1));
        rhs_1 = simplify(rhs) "
	& dump_exp_graphviz lhs => lhsnode 
	& Print.printBuf \"------------------ LHS -----------------\\n\"
	& Graphviz.dump lhsnode
	& Print.printBuf \"------------------ /LHS -----------------\\n\"
	" ;
      then
        rhs_1;
    case (e1,e2,(crexp as CREF(componentRef = cr)))
      equation 
        lhs = BINARY(e1,SUB(REAL()),e2);
        lhsder = Derive.differentiateExp(lhs, cr);
        lhsder_1 = simplify(lhsder);
        true = expContains(lhsder_1, crexp);
        Print.printBuf("solve2 failed: Not linear: ");
        printExp(e1);
        Print.printBuf(" = ");
        printExp(e2);
        Print.printBuf("\nsolving for: ");
        printExp(crexp);
        Print.printBuf("\n");
        Print.printBuf("derivative: ");
        printExp(lhsder);
        Print.printBuf("\n");
      then
        fail();
    case (e1,e2,(crexp as CREF(componentRef = cr)))
      equation 
        lhs = BINARY(e1,SUB(REAL()),e2);
        lhsder = Derive.differentiateExp(lhs, cr);
        lhsder_1 = simplify(lhsder);
        Print.printBuf("solve2 failed: ");
        printExp(e1);
        Print.printBuf(" = ");
        printExp(e2);
        Print.printBuf("\nsolving for: ");
        printExp(crexp);
        Print.printBuf("\nDerivative :");
        printExp(lhsder_1);
        Print.printBuf("\n");
      then
        fail();
  end matchcontinue;
end solve2;

protected function getTermsContainingX "function getTermsContainingX
 
  Retrieves all terms of an expression containng a variable, given
  as second argument (in the form of an Exp)
"
  input Exp inExp1;
  input Exp inExp2;
  output Exp outExp1;
  output Exp outExp2;
algorithm 
  (outExp1,outExp2):=
  matchcontinue (inExp1,inExp2)
    local
      Exp xt1,nonxt1,xt2,nonxt2,xt,nonxt,e1,e2,cr,e;
      Type ty;
      Boolean res;
    case (BINARY(exp1 = e1,operator = ADD(ty = ty),exp2 = e2),(cr as CREF(componentRef = _)))
      equation 
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = BINARY(xt1,ADD(ty),xt2);
        nonxt = BINARY(nonxt1,ADD(ty),nonxt2);
      then
        (xt,nonxt);
    case (BINARY(exp1 = e1,operator = SUB(ty = ty),exp2 = e2),(cr as CREF(componentRef = _)))
      equation 
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = BINARY(xt1,SUB(ty),xt2);
        nonxt = BINARY(nonxt1,SUB(ty),nonxt2);
      then
        (xt,nonxt);
    case (UNARY(operator = UPLUS(ty = ty),exp = e),(cr as CREF(componentRef = _)))
      equation 
        (xt1,nonxt1) = getTermsContainingX(e, cr);
        xt = UNARY(UPLUS(ty),xt1);
        nonxt = UNARY(UPLUS(ty),nonxt1);
      then
        (xt,nonxt);
    case (UNARY(operator = UMINUS(ty = ty),exp = e),(cr as CREF(componentRef = _)))
      equation 
        (xt1,nonxt1) = getTermsContainingX(e, cr);
        xt = UNARY(UMINUS(ty),xt1);
        nonxt = UNARY(UMINUS(ty),nonxt1);
      then
        (xt,nonxt);
    case (e,(cr as CREF(componentRef = _)))
      equation 
        res = expContains(e, cr);
        xt = Util.if_(res, e, RCONST(0.0));
        nonxt = Util.if_(res, RCONST(0.0), e);
      then
        (xt,nonxt);
    case (e,cr)
      equation 
        Print.printBuf("get_terms_containing_x failed: ");
        printExp(e);
        Print.printBuf("\nsolving for: ");
        printExp(cr);
        Print.printBuf("\n");
      then
        fail();
  end matchcontinue;
end getTermsContainingX;

public function expContains "function: expContains
  
  Returns true if first expression contains the second one as a sub
  expression.
  Only component references can be checked so far,
   i.e. check whether an expression contains a given component reference 
"
  input Exp inExp1;
  input Exp inExp2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp1,inExp2)
    local
      Integer i;
      Exp cr,c1,c2,e1,e2,e,c,t,f,cref;
      Ident s,str;
      Boolean res,res1,res2,res3;
      list<Boolean> reslist;
      list<Exp> explist,expl_2,args;
      list<tuple<Exp, Boolean>> expl_1;
      list<list<tuple<Exp, Boolean>>> expl;
      ComponentRef cr1,cr2;
      Operator op;
      Absyn.Path fcn;
    case (ICONST(integer = i),(cr as CREF(componentRef = _))) then false; 
    case (RCONST(real = i),(cr as CREF(componentRef = _)))
      local Real i;
      then
        false;
    case (SCONST(string = i),(cr as CREF(componentRef = _)))
      local Ident i;
      then
        false;
    case (BCONST(bool = i),(cr as CREF(componentRef = _)))
      local Boolean i;
      then
        false;
    case (ARRAY(array = explist),cr)
      equation 
        reslist = Util.listMap1(explist, expContains, cr);
        res = Util.boolOrList(reslist);
      then
        res;
    case (MATRIX(scalar = expl),cr)
      equation 
        expl_1 = Util.listFlatten(expl);
        expl_2 = Util.listMap(expl_1, Util.tuple21);
        reslist = Util.listMap1(expl_2, expContains, cr);
        res = Util.boolOrList(reslist);
      then
        res;
    case ((c1 as CREF(componentRef = cr1)),(c2 as CREF(componentRef = cr2)))
      equation 
        res = crefEqual(cr1, cr2);
      then
        res;
    case (BINARY(exp1 = e1,operator = op,exp2 = e2),(cr as CREF(componentRef = _)))
      equation 
        res1 = expContains(e1, cr);
        res2 = expContains(e2, cr);
        res = boolOr(res1, res2);
      then
        res;
    case (UNARY(operator = op,exp = e),(cr as CREF(componentRef = _)))
      equation 
        res = expContains(e, cr);
      then
        res;
    case (LBINARY(exp1 = e1,operator = op,exp2 = e2),(cr as CREF(componentRef = _)))
      equation 
        res1 = expContains(e1, cr);
        res2 = expContains(e2, cr);
        res = boolOr(res1, res2);
      then
        res;
    case (LUNARY(operator = op,exp = e),(cr as CREF(componentRef = _)))
      equation 
        res = expContains(e, cr);
      then
        res;
    case (RELATION(exp1 = e1,operator = op,exp2 = e2),(cr as CREF(componentRef = _)))
      equation 
        res1 = expContains(e1, cr);
        res2 = expContains(e2, cr);
        res = boolOr(res1, res2);
      then
        res;
    case (IFEXP(expCond = c,expThen = t,expElse = f),(cr as CREF(componentRef = _)))
      equation 
        res1 = expContains(c, cr);
        res2 = expContains(t, cr);
        res3 = expContains(f, cr);
        res = Util.boolOrList({res1,res2,res3});
      then
        res;
    case (CALL(path = Absyn.IDENT(name = "pre"),expLst = {cref}),cr) then false;  /* pre(v) does not contain variable v */ 
    case (CALL(expLst = {}),_) then false;  /* special rule for no arguments */ 
    case (CALL(path = fcn,expLst = args),(cr as CREF(componentRef = _))) /* general case for arguments */ 
      equation 
        reslist = Util.listMap1(args, expContains, cr);
        res = Util.boolOrList(reslist);
      then
        res;
    case (CAST(ty = REAL(),exp = ICONST(integer = i)),(cr as CREF(componentRef = _))) then false; 
    case (CAST(ty = REAL(),exp = e),(cr as CREF(componentRef = _)))
      equation 
        res = expContains(e, cr);
      then
        res;
    case (ASUB(exp = e,sub = i),(cr as CREF(componentRef = _)))
      equation 
        res = expContains(e, cr);
      then
        res;
    case (e,cr)
      equation 
        Debug.fprint("failtrace", "-exp_contains failed\n");
        s = printExpStr(e);
        str = Util.stringAppendList({"exp = ",s,"\n"});
        Debug.fprint("failtrace", str);
      then
        fail();
  end matchcontinue;
end expContains;

public function getCrefFromExp "function: getCrefFromExp
 
  Return a list of all component references occuring in the
  expression.
"
  input Exp inExp;
  output list<ComponentRef> outComponentRefLst;
algorithm 
  outComponentRefLst:=
  matchcontinue (inExp)
    local
      ComponentRef cr;
      list<ComponentRef> l1,l2,res,res1,l3,res2;
      Exp e1,e2,e3,e;
      Operator op;
      list<Exp> farg,expl,expl_2;
      list<tuple<Exp, Boolean>> expl_1;
    case (ICONST(integer = _)) then {}; 
    case (RCONST(real = _)) then {}; 
    case (SCONST(string = _)) then {}; 
    case (BCONST(bool = _)) then {}; 
    case (CREF(componentRef = cr)) then {cr}; 
    case (BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        l1 = getCrefFromExp(e1);
        l2 = getCrefFromExp(e2);
        res = listAppend(l1, l2);
      then
        res;
    case (UNARY(operator = op,exp = e1))
      equation 
        res = getCrefFromExp(e1);
      then
        res;
    case (LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        l1 = getCrefFromExp(e1);
        l2 = getCrefFromExp(e2);
        res = listAppend(l1, l2);
      then
        res;
    case (LUNARY(operator = op,exp = e1))
      equation 
        res = getCrefFromExp(e1);
      then
        res;
    case (RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation 
        l1 = getCrefFromExp(e1);
        l2 = getCrefFromExp(e2);
        res = listAppend(l1, l2);
      then
        res;
    case (IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation 
        l1 = getCrefFromExp(e1);
        l2 = getCrefFromExp(e2);
        res1 = listAppend(l1, l2);
        l3 = getCrefFromExp(e3);
        res = listAppend(res1, l3);
      then
        res;
    case (CALL(expLst = farg))
      local list<list<ComponentRef>> res;
      equation 
        res = Util.listMap(farg, getCrefFromExp);
        res2 = Util.listFlatten(res);
      then
        res2;
    case (ARRAY(array = expl))
      local list<list<ComponentRef>> res1;
      equation 
        res1 = Util.listMap(expl, getCrefFromExp);
        res = Util.listFlatten(res1);
      then
        res;
    case (MATRIX(scalar = expl))
      local
        list<list<ComponentRef>> res1;
        list<list<tuple<Exp, Boolean>>> expl;
      equation 
        expl_1 = Util.listFlatten(expl);
        expl_2 = Util.listMap(expl_1, Util.tuple21);
        res1 = Util.listMap(expl_2, getCrefFromExp);
        res = Util.listFlatten(res1);
      then
        res;
    case (RANGE(exp = e1,expOption = SOME(e3),range = e2))
      equation 
        l1 = getCrefFromExp(e1);
        l2 = getCrefFromExp(e2);
        res1 = listAppend(l1, l2);
        l3 = getCrefFromExp(e3);
        res = listAppend(res1, l3);
      then
        res;
    case (RANGE(exp = e1,expOption = NONE,range = e2))
      equation 
        l1 = getCrefFromExp(e1);
        l2 = getCrefFromExp(e2);
        res = listAppend(l1, l2);
      then
        res;
    case (TUPLE(PR = expl))
      equation 
        Print.printBuf("Not implemented yet\n") "Util.list_map(expl,get_cref_from_exp) => res" ;
      then
        {};
    case (CAST(exp = e))
      equation 
        res = getCrefFromExp(e);
      then
        res;
    case (ASUB(exp = e))
      equation 
        res = getCrefFromExp(e);
      then
        res;
    case (_) then {}; 
  end matchcontinue;
end getCrefFromExp;

public function getFunctionCallsList "function: getFunctionCallsList
 
  calls get_function_calls for a list of exps
"
  input list<Exp> exps;
  output list<Exp> res;
  list<list<Exp>> explists;
algorithm 
  explists := Util.listMap(exps, getFunctionCalls);
  res := Util.listFlatten(explists);
end getFunctionCallsList;

public function getFunctionCalls "function: getFunctionCalls
 
  Return all exps that are function calls.
  Inner call exps are returned separately but not extracted from the exp they
  are in, e.g. CALL(foo, {CALL(bar)}) will return
  {CALL(foo, {CALL(bar)}), CALL(bar,{})}
"
  input Exp inExp;
  output list<Exp> outExpLst;
algorithm 
  outExpLst:=
  matchcontinue (inExp)
    local
      list<Exp> argexps,exps,args,a,b,res,elts,elst,elist;
      Exp e,e1,e2,e3;
      Absyn.Path path;
      Boolean tuple_,builtin;
      list<tuple<Exp, Boolean>> flatexplst;
      list<list<tuple<Exp, Boolean>>> explst;
      Option<Exp> optexp;
    case ((e as CALL(path = path,expLst = args,tuple_ = tuple_,builtin = builtin)))
      equation 
        argexps = getFunctionCallsList(args);
        exps = listAppend({e}, argexps);
      then
        exps;
    case (BINARY(exp1 = e1,exp2 = e2)) /* Binary */ 
      equation 
        a = getFunctionCalls(e1);
        b = getFunctionCalls(e2);
        res = listAppend(a, b);
      then
        res;
    case (UNARY(exp = e)) /* Unary */ 
      equation 
        res = getFunctionCalls(e);
      then
        res;
    case (LBINARY(exp1 = e1,exp2 = e2)) /* LBinary */ 
      equation 
        a = getFunctionCalls(e1);
        b = getFunctionCalls(e2);
        res = listAppend(a, b);
      then
        res;
    case (LUNARY(exp = e)) /* LUnary */ 
      equation 
        res = getFunctionCalls(e);
      then
        res;
    case (RELATION(exp1 = e1,exp2 = e2)) /* Relation */ 
      equation 
        a = getFunctionCalls(e1);
        b = getFunctionCalls(e2);
        res = listAppend(a, b);
      then
        res;
    case (IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation 
        res = getFunctionCallsList({e1,e2,e3});
      then
        res;
    case (ARRAY(array = elts)) /* Array */ 
      equation 
        res = getFunctionCallsList(elts);
      then
        res;
    case (MATRIX(scalar = explst)) /* Matrix */ 
      equation 
        flatexplst = Util.listFlatten(explst);
        elst = Util.listMap(flatexplst, Util.tuple21);
        res = getFunctionCallsList(elst);
      then
        res;
    case (RANGE(exp = e1,expOption = optexp,range = e2)) /* Range */ 
      local list<Exp> e3;
      equation 
        e3 = Util.optionToList(optexp);
        elist = listAppend({e1,e2}, e3);
        res = getFunctionCallsList(elist);
      then
        res;
    case (TUPLE(PR = exps)) /* Tuple */ 
      equation 
        res = getFunctionCallsList(exps);
      then
        res;
    case (CAST(exp = e))
      equation 
        res = getFunctionCalls(e);
      then
        res;
    case (SIZE(exp = e1,sz = e2)) /* Size */ 
      local Option<Exp> e2;
      equation 
        a = Util.optionToList(e2);
        elist = listAppend(a, {e1});
        res = getFunctionCallsList(elist);
      then
        res;
    case (_) then {}; 
  end matchcontinue;
end getFunctionCalls;

public function nthArrayExp "function: nthArrayExp
  author: PA
 
  Returns the nth expression of an array expression.
"
  input Exp inExp;
  input Integer inInteger;
  output Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp,inInteger)
    local
      Exp e;
      list<Exp> expl;
      Integer indx;
    case (ARRAY(array = expl),indx)
      equation 
        e = listNth(expl, indx);
      then
        e;
  end matchcontinue;
end nthArrayExp;

public function expAdd "function: expAdd
  author: PA
  
  Adds two scalar expressions.
"
  input Exp e1;
  input Exp e2;
  output Exp outExp;
  Type tp;
algorithm 
  tp := typeof(e1);
  true := typeBuiltin(tp) "	array_elt_type(tp) => tp\'" ;
  outExp := BINARY(e1,ADD(tp),e2);
end expAdd;

protected function expMul "function: expMul
  author: PA
  
  Multiplies two scalar expressions.
"
  input Exp e1;
  input Exp e2;
  output Exp outExp;
  Type tp;
algorithm 
  tp := typeof(e1);
  true := typeBuiltin(tp) "	array_elt_type(tp) => tp\'" ;
  outExp := BINARY(e1,MUL(tp),e2);
end expMul;

public function expCref "function: expCref
 
  Returns the componentref is exp is a CREF,
"
  input Exp inExp;
  output ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inExp)
    local ComponentRef cr;
    case (CREF(componentRef = cr)) then cr; 
  end matchcontinue;
end expCref;

public function traverseExp "function traverseExp
 
  Traverses all subexpressions of an expression.
  Takes a function and an extra argument passed through the traversal.
"
  input Exp inExp;
  input FuncTypeTplExpType_aToTplExpType_a inFuncTypeTplExpTypeAToTplExpTypeA;
  input Type_a inTypeA;
  output tuple<Exp, Type_a> outTplExpTypeA;
  partial function FuncTypeTplExpType_aToTplExpType_a
    input tuple<Exp, Type_a> inTplExpTypeA;
    output tuple<Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a;
  end FuncTypeTplExpType_aToTplExpType_a;
  replaceable type Type_a;
algorithm 
  outTplExpTypeA:=
  matchcontinue (inExp,inFuncTypeTplExpTypeAToTplExpTypeA,inTypeA)
    local
      Exp e1_1,e,e1,e2_1,e2,e3_1,e_1,e3;
      Type_a ext_arg_1,ext_arg_2,ext_arg,ext_arg_3,ext_arg_4;
      Operator op_1,op;
      FuncTypeTplExpType_aToTplExpType_a rel;
      list<Exp> expl_1,expl;
      Absyn.Path fn_1,fn,path_1,path;
      Boolean t_1,b_1,t,b,scalar_1,scalar;
      Type tp_1,tp;
      Integer i_1,i;
      Ident id_1,id;
    case ((e as UNARY(operator = op,exp = e1)),rel,ext_arg) /* unary */ 
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((UNARY(op_1,_),ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((UNARY(op_1,e1_1),ext_arg_2));
    case ((e as BINARY(exp1 = e1,operator = op,exp2 = e2)),rel,ext_arg) /* binary */ 
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((BINARY(_,op_1,_),ext_arg_3)) = rel((e,ext_arg_2));
      then
        ((BINARY(e1_1,op_1,e2_1),ext_arg_3));
    case ((e as LUNARY(operator = op,exp = e1)),rel,ext_arg) /* logic unary */ 
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((LUNARY(op_1,_),ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((LUNARY(op_1,e1_1),ext_arg_2));
    case ((e as LBINARY(exp1 = e1,operator = op,exp2 = e2)),rel,ext_arg) /* logic binary */ 
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((LBINARY(_,op_1,_),ext_arg_3)) = rel((e,ext_arg_2));
      then
        ((LBINARY(e1_1,op_1,e2_1),ext_arg_3));
    case ((e as RELATION(exp1 = e1,operator = op,exp2 = e2)),rel,ext_arg) /* RELATION */ 
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((RELATION(_,op_1,_),ext_arg_3)) = rel((e,ext_arg_2));
      then
        ((RELATION(e1_1,op_1,e2_1),ext_arg_3));
    case ((e as IFEXP(expCond = e1,expThen = e2,expElse = e3)),rel,ext_arg) /* if expression */ 
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e3_1,ext_arg_3)) = traverseExp(e3, rel, ext_arg_2);
        ((e_1,ext_arg_4)) = rel((e,ext_arg_3));
      then
        ((IFEXP(e1_1,e2_1,e3_1),ext_arg_4));
    case ((e as CALL(path = fn,expLst = expl,tuple_ = t,builtin = b)),rel,ext_arg)
      equation 
        (expl_1,ext_arg_1) = Util.listFoldMap(expl, rel, ext_arg);
        ((CALL(fn_1,_,t_1,b_1),ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((CALL(fn_1,expl_1,t_1,b_1),ext_arg_2));
    case ((e as ARRAY(ty = tp,scalar = scalar,array = expl)),rel,ext_arg)
      equation 
        (expl_1,ext_arg_1) = Util.listFoldMap(expl, rel, ext_arg);
        ((ARRAY(tp_1,scalar_1,_),ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((ARRAY(tp_1,scalar_1,expl_1),ext_arg_2));
    case ((e as MATRIX(ty = tp,integer = scalar,scalar = expl)),rel,ext_arg)
      local
        list<list<tuple<Exp, Boolean>>> expl_1,expl;
        Integer scalar_1,scalar;
      equation 
        (expl_1,ext_arg_1) = traverseExpMatrix(expl, rel, ext_arg);
        ((MATRIX(tp_1,scalar_1,_),ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((MATRIX(tp,scalar,expl_1),ext_arg_2));
    case ((e as RANGE(ty = tp,exp = e1,expOption = NONE,range = e2)),rel,ext_arg)
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((RANGE(tp_1,_,_,_),ext_arg_3)) = rel((e,ext_arg_2));
      then
        ((RANGE(tp_1,e1_1,NONE,e2_1),ext_arg_3));
    case ((e as RANGE(ty = tp,exp = e1,expOption = SOME(e2),range = e3)),rel,ext_arg)
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e3_1,ext_arg_3)) = traverseExp(e3, rel, ext_arg_2);
        ((RANGE(tp_1,_,_,_),ext_arg_4)) = rel((e,ext_arg_3));
      then
        ((RANGE(tp_1,e1_1,SOME(e3),e2_1),ext_arg_4));
    case ((e as TUPLE(PR = expl)),rel,ext_arg)
      equation 
        (expl_1,ext_arg_1) = Util.listFoldMap(expl, rel, ext_arg);
        ((e_1,ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((TUPLE(expl_1),ext_arg_2));
    case ((e as CAST(ty = tp,exp = e1)),rel,ext_arg)
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((CAST(tp_1,_),ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((CAST(tp,e1_1),ext_arg_2));
    case ((e as ASUB(exp = e1,sub = i)),rel,ext_arg)
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((ASUB(_,i_1),ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((ASUB(e1_1,i_1),ext_arg_2));
    case ((e as SIZE(exp = e1,sz = NONE)),rel,ext_arg)
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e_1,ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((SIZE(e1_1,NONE),ext_arg_2));
    case ((e as SIZE(exp = e1,sz = SOME(e2))),rel,ext_arg)
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e_1,ext_arg_3)) = rel((e,ext_arg_2));
      then
        ((SIZE(e1_1,SOME(e2_1)),ext_arg_3));
    case ((e as REDUCTION(path = path,expr = e1,ident = id,range = e2)),rel,ext_arg)
      equation 
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((REDUCTION(path_1,_,id_1,_),ext_arg_3)) = rel((e,ext_arg_2));
      then
        ((REDUCTION(path_1,e1_1,id_1,e2_1),ext_arg_3));
    case (e,rel,ext_arg)
      equation 
        ((e_1,ext_arg_1)) = rel((e,ext_arg));
      then
        ((e_1,ext_arg_1));
  end matchcontinue;
end traverseExp;

protected function traverseExpMatrix "function: traverseExpMatrix
  author: PA
  
   Helper function to traverse_exp, traverses matrix expressions.
"
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst;
  input FuncTypeTplExpType_aToTplExpType_a inFuncTypeTplExpTypeAToTplExpTypeA;
  input Type_a inTypeA;
  output list<list<tuple<Exp, Boolean>>> outTplExpBooleanLstLst;
  output Type_a outTypeA;
  partial function FuncTypeTplExpType_aToTplExpType_a
    input tuple<Exp, Type_a> inTplExpTypeA;
    output tuple<Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a;
  end FuncTypeTplExpType_aToTplExpType_a;
  replaceable type Type_a;
algorithm 
  (outTplExpBooleanLstLst,outTypeA):=
  matchcontinue (inTplExpBooleanLstLst,inFuncTypeTplExpTypeAToTplExpTypeA,inTypeA)
    local
      FuncTypeTplExpType_aToTplExpType_a rel;
      Type_a e_arg,e_arg_1,e_arg_2;
      list<tuple<Exp, Boolean>> row_1,row;
      list<list<tuple<Exp, Boolean>>> rows_1,rows;
    case ({},rel,e_arg) then ({},e_arg); 
    case ((row :: rows),rel,e_arg)
      equation 
        (row_1,e_arg_1) = traverseExpMatrix2(row, rel, e_arg);
        (rows_1,e_arg_2) = traverseExpMatrix(rows, rel, e_arg_1);
      then
        ((row_1 :: rows_1),e_arg_2);
  end matchcontinue;
end traverseExpMatrix;

protected function traverseExpMatrix2 "function: traverseExpMatrix2
  author: PA
 
  Helper function to traverse_exp_matrix.
"
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst;
  input FuncTypeTplExpType_aToTplExpType_a inFuncTypeTplExpTypeAToTplExpTypeA;
  input Type_a inTypeA;
  output list<tuple<Exp, Boolean>> outTplExpBooleanLst;
  output Type_a outTypeA;
  partial function FuncTypeTplExpType_aToTplExpType_a
    input tuple<Exp, Type_a> inTplExpTypeA;
    output tuple<Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a;
  end FuncTypeTplExpType_aToTplExpType_a;
  replaceable type Type_a;
algorithm 
  (outTplExpBooleanLst,outTypeA):=
  matchcontinue (inTplExpBooleanLst,inFuncTypeTplExpTypeAToTplExpTypeA,inTypeA)
    local
      Type_a e_arg,e_arg_1,e_arg_2;
      Exp e_1,e;
      list<tuple<Exp, Boolean>> rest_1,rest;
      Boolean b;
      FuncTypeTplExpType_aToTplExpType_a rel;
    case ({},_,e_arg) then ({},e_arg); 
    case (((e,b) :: rest),rel,e_arg)
      equation 
        ((e_1,e_arg_1)) = traverseExp(e, rel, e_arg);
        (rest_1,e_arg_2) = traverseExpMatrix2(rest, rel, e_arg_1);
      then
        (((e_1,b) :: rest_1),e_arg_2);
  end matchcontinue;
end traverseExpMatrix2;

protected function matrixExpMap1 "function: matrixExpMap1
  author: PA
  
  Maps a function, taking one extra argument over a MATRIX expression
  list.
"
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst;
  input FuncTypeExpType_bToExp inFuncTypeExpTypeBToExp;
  input Type_b inTypeB;
  output list<list<tuple<Exp, Boolean>>> outTplExpBooleanLstLst;
  partial function FuncTypeExpType_bToExp
    input Exp inExp;
    input Type_b inTypeB;
    output Exp outExp;
    replaceable type Type_b;
  end FuncTypeExpType_bToExp;
  replaceable type Type_b;
algorithm 
  outTplExpBooleanLstLst:=
  matchcontinue (inTplExpBooleanLstLst,inFuncTypeExpTypeBToExp,inTypeB)
    local
      list<tuple<Exp, Boolean>> e_1,e;
      list<list<tuple<Exp, Boolean>>> es_1,es;
      FuncTypeExpType_bToExp rel;
      Type_b arg;
    case ({},_,_) then {}; 
    case ((e :: es),rel,arg)
      equation 
        e_1 = matrixExpMap1Help(e, rel, arg);
        es_1 = matrixExpMap1(es, rel, arg);
      then
        (e_1 :: es_1);
  end matchcontinue;
end matrixExpMap1;

protected function matrixExpMap1Help "function: matrixExpMap1Help
 
  Helper function to matrix_exp_map_1.
"
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst;
  input FuncTypeExpType_bToExp inFuncTypeExpTypeBToExp;
  input Type_b inTypeB;
  output list<tuple<Exp, Boolean>> outTplExpBooleanLst;
  partial function FuncTypeExpType_bToExp
    input Exp inExp;
    input Type_b inTypeB;
    output Exp outExp;
    replaceable type Type_b;
  end FuncTypeExpType_bToExp;
  replaceable type Type_b;
algorithm 
  outTplExpBooleanLst:=
  matchcontinue (inTplExpBooleanLst,inFuncTypeExpTypeBToExp,inTypeB)
    local
      Exp e_1,e;
      list<tuple<Exp, Boolean>> es_1,es;
      Boolean b;
      FuncTypeExpType_bToExp rel;
      Type_b arg;
    case ({},_,_) then {}; 
    case (((e,b) :: es),rel,arg)
      equation 
        e_1 = rel(e, arg);
        es_1 = matrixExpMap1Help(es, rel, arg);
      then
        ((e_1,b) :: es_1);
  end matchcontinue;
end matrixExpMap1Help;
end Exp;


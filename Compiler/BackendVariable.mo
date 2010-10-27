/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package BackendVariable
" file:	       BackendVariable.mo
  package:     BackendVariable
  description: BackendVariables contains the function that deals with the datytypes
							 BackendDAE.VAR BackendDAE.Variables and BackendVariablesArray.

"

public import BackendDAE;
public import DAE;

protected import Absyn;
protected import BackendDAEUtil;
protected import ComponentReference;
protected import DAELow;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import HashTable2;
protected import SCode;
protected import System;
protected import RTOpts;
protected import Values;
protected import Util;

/* =======================================================
 *
 *  Section for functions that deals with Var 
 *
 * =======================================================
 */

public function isVarKnown "function: isVarKnown
  author: PA

  Returns true if the the variable is present in the variable list.
  This is done by traversing the list, searching for a matching variable
  name.
"
  input list<BackendDAE.Var> inVarLst;
  input DAE.ComponentRef inComponentRef;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVarLst,inComponentRef)
    local
      DAE.ComponentRef var_name,cr;
      BackendDAE.Var variable;
      BackendDAE.Value indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<BackendDAE.Var> rest;
      Boolean res;
    case ({},var_name) then false;
    case (((variable as BackendDAE.VAR(varName = cr,index = indx,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix,streamPrefix = streamPrefix)) :: rest),var_name)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, var_name);
      then
        true;
    case (((variable as BackendDAE.VAR(varName = cr,index = indx,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix,streamPrefix = streamPrefix)) :: rest),var_name)
      equation
        res = isVarKnown(rest, var_name);
      then
        res;
  end matchcontinue;
end isVarKnown;




public function varEqual
"function: varEqual
  author: PA
  Returns true if two Vars are equal."
  input BackendDAE.Var inVar1;
  input BackendDAE.Var inVar2;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar1,inVar2)
    local
      Boolean res;
      DAE.ComponentRef cr1,cr2;
    case (BackendDAE.VAR(varName = cr1),BackendDAE.VAR(varName = cr2))
      equation
        res = ComponentReference.crefEqualNoStringCompare(cr1, cr2) "A BackendDAE.Var is identified by its component reference" ;
      then
        res;
  end matchcontinue;
end varEqual;



public function setVarFixed
"function: setVarFixed
  author: PA
  Sets the fixed attribute of a variable."
  input BackendDAE.Var inVar;
  input Boolean inBoolean;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVar,inBoolean)
    local
      DAE.ComponentRef a;
      BackendDAE.VarKind b;
      DAE.VarDirection c;
      BackendDAE.Type d;
      Option<DAE.Exp> e,h;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      BackendDAE.Value i;
      list<Absyn.Path> k;
      DAE.ElementSource source "the element source";
      Option<DAE.Exp> l,m,n;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> o;
      Option<DAE.Exp> p,q;
      Option<DAE.StateSelect> r;
      Option<SCode.Comment> s;
      DAE.Flow t;
      DAE.Stream streamPrefix;
      Boolean fixed;
      Option<DAE.StateSelect> stateSelectOption;
      Option<DAE.Exp> equationBound;
      Option<Boolean> isProtected;
      Option<Boolean> finalPrefix;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(DAE.VAR_ATTR_REAL(l,m,n,o,p,_,q,r,equationBound,isProtected,finalPrefix)),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
    then BackendDAE.VAR(a,b,c,d,e,f,g,i,source,
             SOME(DAE.VAR_ATTR_REAL(l,m,n,o,p,SOME(DAE.BCONST(fixed)),q,r,equationBound,isProtected,finalPrefix)),
             s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(DAE.VAR_ATTR_INT(l,o,n,_,equationBound,isProtected,finalPrefix)),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,d,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_INT(l,o,n,SOME(DAE.BCONST(fixed)),equationBound,isProtected,finalPrefix)),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(DAE.VAR_ATTR_BOOL(l,m,_,equationBound,isProtected,finalPrefix)),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,d,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_BOOL(l,m,SOME(DAE.BCONST(fixed)),equationBound,isProtected,finalPrefix)),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(DAE.VAR_ATTR_ENUMERATION(l,o,n,_,equationBound,isProtected,finalPrefix)),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,d,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_ENUMERATION(l,o,n,SOME(DAE.BCONST(fixed)),equationBound,isProtected,finalPrefix)),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = BackendDAE.REAL(),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE(),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,BackendDAE.REAL(),e,f,g,i,source,
            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(fixed)),NONE(),NONE(),NONE(),NONE(),NONE())),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = BackendDAE.INT(),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE(),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,BackendDAE.REAL(),e,f,g,i,source,
            SOME(DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(fixed)),NONE(),NONE(),NONE())),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = BackendDAE.BOOL(),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE(),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,BackendDAE.REAL(),e,f,g,i,source,
            SOME(DAE.VAR_ATTR_BOOL(NONE(),NONE(),SOME(DAE.BCONST(fixed)),NONE(),NONE(),NONE())),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = BackendDAE.ENUMERATION(_),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE(),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,BackendDAE.REAL(),e,f,g,i,source,
            SOME(DAE.VAR_ATTR_ENUMERATION(NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(fixed)),NONE(),NONE(),NONE())),
            s,t,streamPrefix);
  end matchcontinue;
end setVarFixed;

public function varFixed
"function: varFixed
  author: PA
  Extacts the fixed attribute of a variable.
  The default fixed value is used if not found. Default is true for parameters
  (and constants) and false for variables."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local
      Boolean fixed;
      BackendDAE.Var v;
    case (v as BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,SOME(DAE.BCONST(fixed)),_,_,_,_,_)))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_INT(_,_,_,SOME(DAE.BCONST(fixed)),_,_,_)))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_BOOL(_,_,SOME(DAE.BCONST(fixed)),_,_,_)))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_ENUMERATION(_,_,_,SOME(DAE.BCONST(fixed)),_,_,_)))) then fixed;
    case (v) /* param is fixed */
      equation
        BackendDAE.PARAM() = varKind(v);
      then
        true;
    case (v) /* states are by default fixed. */
      equation
        BackendDAE.STATE() = varKind(v);
      then
        true;
    case (_) then false;  /* rest defaults to false*/
  end matchcontinue;
end varFixed;

public function varStartValue
"function varStartValue
  author: PA
  Returns the DAE.StartValue of a variable."
  input BackendDAE.Var v;
  output DAE.Exp sv;
algorithm
  sv := matchcontinue(v)
    local
      Option<DAE.VariableAttributes> attr;
    case (BackendDAE.VAR(values = attr))
      equation
        sv=DAEUtil.getStartAttr(attr);
      then sv;
   end matchcontinue;
end varStartValue;

public function varStateSelect
"function varStateSelect
  author: PA
  Extacts the state select attribute of a variable. If no stateselect explicilty set, return
  StateSelect.default"
  input BackendDAE.Var inVar;
  output DAE.StateSelect outStateSelect;
algorithm
  outStateSelect:=
  matchcontinue (inVar)
    local
      DAE.StateSelect stateselect;
      BackendDAE.Var v;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,_,SOME(stateselect),_,_,_)))) then stateselect;
    case (_) then DAE.DEFAULT();
  end matchcontinue;
end varStateSelect;

public function varType "function: varType
  author: PA

  extracts the type of a variable.
"
  input BackendDAE.Var inVar;
  output BackendDAE.Type outType;
algorithm
  outType:=
  matchcontinue (inVar)
    local BackendDAE.Type tp;
    case (BackendDAE.VAR(varType = tp)) then tp;
  end matchcontinue;
end varType;

public function varKind "function: varKind
  author: PA

  extracts the kind of a variable.
"
  input BackendDAE.Var inVar;
  output BackendDAE.VarKind outVarKind;
algorithm
  outVarKind:=
  matchcontinue (inVar)
    local BackendDAE.VarKind kind;
    case (BackendDAE.VAR(varKind = kind)) then kind;
  end matchcontinue;
end varKind;

public function varIndex "function: varIndex
  author: PA

  extracts the index in the implementation vector of a Var
"
  input BackendDAE.Var inVar;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inVar)
    local BackendDAE.Value i;
    case (BackendDAE.VAR(index = i)) then i;
  end matchcontinue;
end varIndex;

public function varNominal "function: varNominal
  author: PA

  Extacts the nominal attribute of a variable. If the variable has no
  nominal value, the function fails.
"
  input BackendDAE.Var inVar;
  output Real outReal;
algorithm
  outReal := matchcontinue (inVar)
    local
      Real nominal;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,SOME(DAE.RCONST(nominal)),_,_,_,_)))) then nominal;
  end matchcontinue;
end varNominal;

public function varCref
"function: varCref
  author: PA
  extracts the ComponentRef of a variable."
  input BackendDAE.Var inVar;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inVar)
    local
      DAE.ComponentRef cr;
      DAE.Flow flowPrefix;
    case (BackendDAE.VAR(varName = cr,flowPrefix = flowPrefix)) then cr;
  end matchcontinue;
end varCref;

public function isStateVar
"function: isStateVar
  Returns true for state variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.STATE())) then true;
    case (_) then false;
  end matchcontinue;
end isStateVar;

public function isNonStateVar
"function: isNonStateVar
  this equation checks if the the varkind is state of variable
  used both in build_equation and generate_compute_state"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (inVar)
		equation
      failIfNonState(inVar);
 	  then true;
    case (_) then false;
  end matchcontinue;
end isNonStateVar;

protected function failIfNonState
"Fails if the given variable kind is state."
  input BackendDAE.Var inVar;
algorithm
  _ :=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE())) then ();
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER())) then ();
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE())) then ();
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE())) then ();
    case (BackendDAE.VAR(varKind = BackendDAE.STATE_DER())) then ();
  end matchcontinue;
end failIfNonState;

public function isDummyStateVar
"function isDummyStateVar
  Returns true for dummy state variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE())) then true;
    case (_) then false;
  end matchcontinue;
end isDummyStateVar;

public function isVarDiscrete
" This functions checks if BackendDAE.Var is discrete"
	input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean := 
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE())) then true;
    case (BackendDAE.VAR(varType = BackendDAE.INT())) then true;
    case (BackendDAE.VAR(varType = BackendDAE.BOOL())) then true;
    case (BackendDAE.VAR(varType = BackendDAE.ENUMERATION(_))) then true;
    case (_) then false;
  end matchcontinue;
end isVarDiscrete;

/* TODO: Is this correct? */
public function isVarAlg
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.VarKind kind;
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* bool variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as BackendDAE.BOOL()))
      then false;
    /* int variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as BackendDAE.INT()))
      then false;
    /* string variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as BackendDAE.STRING()))
      then false;
    /* non-string variable */
    case (BackendDAE.VAR(varKind = kind))
      equation
        kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DISCRETE(), BackendDAE.DUMMY_DER(),
                    BackendDAE.DUMMY_STATE()};
        _ = Util.listGetMember(kind, kind_lst);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarAlg;

/* TODO: Is this correct? */
public function isVarStringAlg
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.VarKind kind;
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* string variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as BackendDAE.STRING()))
      equation
        kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DISCRETE(), BackendDAE.DUMMY_DER(),
                    BackendDAE.DUMMY_STATE()};
        _ = Util.listGetMember(kind, kind_lst);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarStringAlg;

public function isVarIntAlg
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.VarKind kind;
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* int variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as BackendDAE.INT()))
      equation

        kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DISCRETE(), BackendDAE.DUMMY_DER(),
                    BackendDAE.DUMMY_STATE()};
        _ = Util.listGetMember(kind, kind_lst);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarIntAlg;

public function isVarBoolAlg
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.VarKind kind;
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* int variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as BackendDAE.BOOL()))
      equation

        kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DISCRETE(), BackendDAE.DUMMY_DER(),
                    BackendDAE.DUMMY_STATE()};
        _ = Util.listGetMember(kind, kind_lst);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarBoolAlg;

/* TODO: Is this correct? */
public function isVarParam
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* bool variable */
    case (BackendDAE.VAR(varType = typeVar as BackendDAE.BOOL()))
      then false;
    /* int variable */
    case (BackendDAE.VAR(varType = typeVar as BackendDAE.INT()))
      then false;
    /* string variable */
    case (BackendDAE.VAR(varType = typeVar as BackendDAE.STRING()))
      then false;
    /* non-string variable */
    case (var)
      equation
        true = isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarParam;

public function isVarStringParam
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* string variable */
    case (BackendDAE.VAR(varType = typeVar as BackendDAE.STRING()))
      equation
        true = isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarStringParam;

public function isVarIntParam
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* int variable */
    case (BackendDAE.VAR(varType = typeVar as BackendDAE.INT()))
      equation
        true = isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarIntParam;

public function isVarBoolParam
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* string variable */
    case (BackendDAE.VAR(varType = typeVar as BackendDAE.BOOL()))
      equation
        true = isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarBoolParam;

public function varIndexComparer
  input BackendDAE.Var lhs;
  input BackendDAE.Var rhs;
  output Boolean res;
algorithm
  res :=
  matchcontinue (lhs, rhs)
      local
      Integer lhsIndex;
      Integer rhsIndex;
    case (BackendDAE.VAR(index=lhsIndex), BackendDAE.VAR(index=rhsIndex))
      then rhsIndex < lhsIndex;
  end matchcontinue;
end varIndexComparer;

public function isParam
"function: isParam
  Return true if variable is a parameter."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case BackendDAE.VAR(varKind = BackendDAE.PARAM()) then true;
    case (_) then false;
  end matchcontinue;
end isParam;

public function isIntParam
"function: isIntParam
  Return true if variable is a parameter and integer."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = BackendDAE.INT())) then true;
    case (_) then false;
  end matchcontinue;
end isIntParam;

public function isBoolParam
"function: isBoolParam
  Return true if variable is a parameter and boolean."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = BackendDAE.BOOL())) then true;
    case (_) then false;
  end matchcontinue;
end isBoolParam;

public function isStringParam
"function: isStringParam
  Return true if variable is a parameter."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = BackendDAE.STRING())) then true;
    case (_) then false;
  end matchcontinue;
end isStringParam;

public function isExtObj
"function: isExtObj
  Return true if variable is an external object."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.EXTOBJ(_))) then true;
    case (_) then false;
  end matchcontinue;
end isExtObj;

public function isRealParam
"function: isParam
  Return true if variable is a parameter of real-type"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = BackendDAE.REAL())) then true;
    case (_) then false;
  end matchcontinue;
end isRealParam;

public function isNonRealParam
"function: isNonRealParam
  Return true if variable is NOT a parameter of real-type"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := not isRealParam(inVar);
end isNonRealParam;

/* NOT USED */
public function isOutputVar
"function: isOutputVar
  Return true if variable is declared as output. Note that the output
  attribute sticks with a variable even if it is originating from a sub
  component, which is not the case for Dymola."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varDirection = DAE.OUTPUT())) then true;
    case (_) then false;
  end matchcontinue;
end isOutputVar;

public function setVarKind
"function setVarKind
  author: PA
  Sets the BackendDAE.VarKind of a variable"
  input BackendDAE.Var inVar;
  input BackendDAE.VarKind inVarKind;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVar,inVarKind)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind,new_kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind,st;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      BackendDAE.Value i;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case (BackendDAE.VAR(varName = cr,
              varKind = kind,
              varDirection = dir,
              varType = tp,
              bindExp = bind,
              bindValue = v,
              arryDim = dim,
              index = i,
              source = source,
              values = attr,
              comment = comment,
              flowPrefix = flowPrefix,
              streamPrefix = streamPrefix),new_kind)
    then BackendDAE.VAR(cr,new_kind,dir,tp,bind,v,dim,i,source,attr,comment,flowPrefix,streamPrefix);
  end matchcontinue;
end setVarKind;

public function setVarIndex
"function setVarKind
  author: PA
  Sets the BackendDAE.VarKind of a variable"
  input BackendDAE.Var inVar;
  input BackendDAE.Value inVarIndex;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVar,inVarIndex)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind,new_kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind,st;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      BackendDAE.Value i,new_i;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case (BackendDAE.VAR(varName = cr,
              varKind = kind,
              varDirection = dir,
              varType = tp,
              bindExp = bind,
              bindValue = v,
              arryDim = dim,
              index = i,
              source = source,
              values = attr,
              comment = comment,
              flowPrefix = flowPrefix,
              streamPrefix = streamPrefix),new_i)
    then BackendDAE.VAR(cr,kind,dir,tp,bind,v,dim,new_i,source,attr,comment,flowPrefix,streamPrefix);
  end matchcontinue;
end setVarIndex;

public function isVarOnTopLevelAndOutput
"function isVarOnTopLevelAndOutput
  this function checks if the provided cr is from a var that is on top model
  and has the DAE.VarDirection = OUTPUT
  The check for top-model is done by spliting the name at \'.\' and
  check if the list-length is 1"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.Flow flowPrefix;
    case (BackendDAE.VAR(varName = cr,varDirection = dir,flowPrefix = flowPrefix))
      equation
        topLevelOutput(cr, dir, flowPrefix);
      then
        true;
    case (_) then false;
  end matchcontinue;
end isVarOnTopLevelAndOutput;

public function isVarOnTopLevelAndInput
"function isVarOnTopLevelAndInput
  this function checks if the provided cr is from a var that is on top model
  and has the DAE.VarDirection = INPUT
  The check for top-model is done by spliting the name at \'.\' and
  check if the list-length is 1"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.Flow flowPrefix;
    case (BackendDAE.VAR(varName = cr,varDirection = dir,flowPrefix = flowPrefix))
      equation
        topLevelInput(cr, dir, flowPrefix);
      then
        true;
    case (_) then false;
  end matchcontinue;
end isVarOnTopLevelAndInput;

public function topLevelInput
"function: topLevelInput
  author: PA
  Succeds if variable is input declared at the top level of the model,
  or if it is an input in a connector instance at top level."
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
algorithm
  _ := matchcontinue (inComponentRef,inVarDirection,inFlow)
    local
      DAE.ComponentRef cr;
      String name;
    case ((cr as DAE.CREF_IDENT(ident = name)),DAE.INPUT(),_)
      equation
        {_} = Util.stringSplitAtChar(name, ".") "top level ident, no dots" ;
      then
        ();
    case (DAE.CREF_IDENT(ident = name),DAE.INPUT(),DAE.NON_FLOW()) /* Connector input variables at top level for crefs that are stringified */
      equation
        {_,_} = Util.stringSplitAtChar(name, ".");
      then
        ();
    case (DAE.CREF_IDENT(ident = name),DAE.INPUT(),DAE.FLOW())
      equation
        {_,_} = Util.stringSplitAtChar(name, ".");
      then
        ();
    /* For crefs that are not yet stringified, e.g. lower_known_var */
    case (DAE.CREF_QUAL(ident = name,componentRef = DAE.CREF_IDENT(ident = _)),DAE.INPUT(),DAE.FLOW()) then ();
    case ((cr as DAE.CREF_QUAL(ident = name,componentRef = DAE.CREF_IDENT(ident = _))),DAE.INPUT(),DAE.NON_FLOW()) then ();
  end matchcontinue;
end topLevelInput;

protected function topLevelOutput
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
algorithm
  _ := matchcontinue(inComponentRef, inVarDirection, inFlow)
  local 
    DAE.ComponentRef cr;
    String name;
    case ((cr as DAE.CREF_IDENT(ident = name)),DAE.OUTPUT(),_)
      equation
        {_} = Util.stringSplitAtChar(name, ".") "top level ident, no dots" ;
      then
        ();
    case (DAE.CREF_IDENT(ident = name),DAE.OUTPUT(),DAE.NON_FLOW()) /* Connector input variables at top level for crefs that are stringified */
      equation
        {_,_} = Util.stringSplitAtChar(name, ".");
      then
        ();
    case (DAE.CREF_IDENT(ident = name),DAE.OUTPUT(),DAE.FLOW())
      equation
        {_,_} = Util.stringSplitAtChar(name, ".");
      then
        ();
    /* For crefs that are not yet stringified, e.g. lower_known_var */
    case (DAE.CREF_QUAL(ident = name,componentRef = DAE.CREF_IDENT(ident = _)),DAE.OUTPUT(),DAE.FLOW()) then ();
    case ((cr as DAE.CREF_QUAL(ident = name,componentRef = DAE.CREF_IDENT(ident = _))),DAE.OUTPUT(),DAE.NON_FLOW()) then ();
  end matchcontinue;
end topLevelOutput;  



/* =======================================================
 *
 *  Section for functions that deals with VariablesArray 
 *
 * =======================================================
 */

protected function vararrayLength
"function: vararrayLength
  author: PA
  Returns the number of variable in the BackendDAE.VariableArray"
  input BackendDAE.VariableArray inVariableArray;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inVariableArray)
    local BackendDAE.Value n;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n)) then n;
  end matchcontinue;
end vararrayLength;

protected function vararrayAdd
"function: vararrayAdd
  author: PA
  Adds a variable last to the BackendDAE.VariableArray, increasing array size
  if no space left by factor 1.4"
  input BackendDAE.VariableArray inVariableArray;
  input BackendDAE.Var inVar;
  output BackendDAE.VariableArray outVariableArray;
algorithm
  outVariableArray := matchcontinue (inVariableArray,inVar)
    local
      BackendDAE.Value n_1,n,size,expandsize,expandsize_1,newsize;
      array<Option<BackendDAE.Var>> arr_1,arr,arr_2;
      BackendDAE.Var v;
      Real rsize,rexpandsize;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),v)
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(v));
      then
        BackendDAE.VARIABLE_ARRAY(n_1,size,arr_1);
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),v)
      equation
        (n < size) = false "Do NOT have splace to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize*. 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr,NONE());
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(v));
      then
        BackendDAE.VARIABLE_ARRAY(n_1,newsize,arr_2);
    case (_,_)
      equation
        print("-vararray_add failed\n");
      then
        fail();
  end matchcontinue;
end vararrayAdd;

protected function vararraySetnth
"function: vararraySetnth
  author: PA
  Set the n:th variable in the BackendDAE.VariableArray to v.
 inputs:  (BackendDAE.VariableArray, int /* n */, BackendDAE.Var /* v */)
 outputs: BackendDAE.VariableArray ="
  input BackendDAE.VariableArray inVariableArray;
  input Integer inInteger;
  input BackendDAE.Var inVar;
  output BackendDAE.VariableArray outVariableArray;
algorithm
  outVariableArray := matchcontinue (inVariableArray,inInteger,inVar)
    local
      array<Option<BackendDAE.Var>> arr_1,arr;
      BackendDAE.Value n,size,pos;
      BackendDAE.Var v;

    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),pos,v)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(v));
      then
        BackendDAE.VARIABLE_ARRAY(n,size,arr_1);

    case (_,_,_)
      equation
        print("-vararray_setnth failed\n");
      then
        fail();
  end matchcontinue;
end vararraySetnth;

public function vararrayNth
"function: vararrayNth
 author: PA
 Retrieve the n:th BackendDAE.Var from BackendDAE.VariableArray, index from 0..n-1.
 inputs:  (BackendDAE.VariableArray, int /* n */)
 outputs: Var"
  input BackendDAE.VariableArray inVariableArray;
  input Integer inInteger;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVariableArray,inInteger)
    local
      BackendDAE.Var v;
      BackendDAE.Value n,pos,len;
      array<Option<BackendDAE.Var>> arr;
      String ps,lens,ns;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,varOptArr = arr),pos)
      equation
        (pos < n) = true;
        SOME(v) = arr[pos + 1];
      then
        v;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,varOptArr = arr),pos)
      equation
        (pos < n) = true;
        NONE() = arr[pos + 1];
        print("vararray_nth has NONE!!!\n");
      then
        fail();
  end matchcontinue;
end vararrayNth;


/* =======================================================
 *
 *  Section for functions that deals with Variables
 *
 * =======================================================
 */

public function varsSize "function: varsSize
  author: PA

  Returns the number of variables
"
  input BackendDAE.Variables inVariables;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inVariables)
    local BackendDAE.Value n;
    case (BackendDAE.VARIABLES(numberOfVars = n)) then n;
  end matchcontinue;
end varsSize;



public function isVariable
"function: isVariable

  This function takes a DAE.ComponentRef and two Variables. It searches
  the two sets of variables and succeed if the variable is STATE or
  VARIABLE. Otherwise it fails.
  Note: An array variable is currently assumed that each scalar element has
  the same type.
  inputs:  (DAE.ComponentRef,
              Variables, /* vars */
              Variables) /* known vars */
  outputs: ()"
  input DAE.ComponentRef inComponentRef1;
  input BackendDAE.Variables inVariables2;
  input BackendDAE.Variables inVariables3;
algorithm
  _:=
  matchcontinue (inComponentRef1,inVariables2,inVariables3)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables vars,knvars;
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE()) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.STATE()) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE()) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER()) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,_,knvars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE()) :: _),_) = getVar(cr, knvars);
      then
        ();
    case (cr,_,knvars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE()) :: _),_) = getVar(cr, knvars);
      then
        ();
    case (cr,_,knvars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER()) :: _),_) = getVar(cr, knvars);
      then
        ();
  end matchcontinue;
end isVariable;

public function moveVariables
"function: moveVariables
  This function takes the two variable lists of a dae (states+alg) and
  known vars and moves a set of variables from the first to the second set.
  This function is needed to manage this in complexity O(n) by only
  traversing the set once for all variables.
  inputs:  (algAndState: Variables, /* alg+state */
              known: Variables,       /* known */
              binTree: BinTree)       /* vars to move from first7 to second */
  outputs:  (Variables,        /* updated alg+state vars */
               Variables)             /* updated known vars */
"
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
  input BackendDAE.BinTree inBinTree3;
  output BackendDAE.Variables outVariables1;
  output BackendDAE.Variables outVariables2;
algorithm
  (outVariables1,outVariables2):=
  matchcontinue (inVariables1,inVariables2,inBinTree3)
    local
      list<BackendDAE.Var> lst1,lst2,lst1_1,lst2_1;
      BackendDAE.Variables v1,v2,vars,knvars,vars1,vars2;
      BackendDAE.BinTree mvars;
    case (vars1,vars2,mvars)
      equation
        lst1 = BackendDAEUtil.varList(vars1);
        lst2 = BackendDAEUtil.varList(vars2);
        (lst1_1,lst2_1) = moveVariables2(lst1, lst2, mvars);
        v1 = BackendDAEUtil.emptyVars();
        v2 = BackendDAEUtil.emptyVars();
        vars = addVars(lst1_1, v1);
        knvars = addVars(lst2_1, v2);
      then
        (vars,knvars);
  end matchcontinue;
end moveVariables;

protected function moveVariables2
"function: moveVariables2
  helper function to move_variables.
  inputs:  (Var list,  /* alg+state vars as list */
              BackendDAE.Var list,  /* known vars as list */
              BinTree)  /* move-variables as BackendDAE.BinTree */
  outputs: (Var list,  /* updated alg+state vars as list */
              BackendDAE.Var list)  /* update known vars as list */"
  input list<BackendDAE.Var> inVarLst1;
  input list<BackendDAE.Var> inVarLst2;
  input BackendDAE.BinTree inBinTree3;
  output list<BackendDAE.Var> outVarLst1;
  output list<BackendDAE.Var> outVarLst2;
algorithm
  (outVarLst1,outVarLst2):=
  matchcontinue (inVarLst1,inVarLst2,inBinTree3)
    local
      list<BackendDAE.Var> knvars,vs_1,knvars_1,vs;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      BackendDAE.BinTree mvars;
    case ({},knvars,_) then ({},knvars);
    case (((v as BackendDAE.VAR(varName = cr)) :: vs),knvars,mvars)
      equation
        _ = BackendDAEUtil.treeGet(mvars, cr) "alg var moved to known vars" ;
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        (vs_1,(v :: knvars_1));
    case (((v as BackendDAE.VAR(varName = cr)) :: vs),knvars,mvars)
      equation
        failure(_ = BackendDAEUtil.treeGet(mvars, cr)) "alg var not moved to known vars" ;
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        ((v :: vs_1),knvars_1);
  end matchcontinue;
end moveVariables2;



public function isTopLevelInputOrOutput
"function isTopLevelInputOrOutput
  author: LP

  This function checks if the provided cr is from a var that is on top model
  and is an input or an output, and returns true for such variables.
  It also returns true for input/output connector variables, i.e. variables
  instantiated from a  connector class, that are instantiated on the top level.
  The check for top-model is done by spliting the name at \'.\' and
  check if the list-length is 1.
  Note: The function needs the known variables to search for input variables
  on the top level.
  inputs:  (cref: DAE.ComponentRef,
              vars: Variables, /* BackendDAE.Variables */
              knownVars: BackendDAE.Variables /* Known BackendDAE.Variables */)
  outputs: bool"
  input DAE.ComponentRef inComponentRef1;
  input BackendDAE.Variables inVariables2;
  input BackendDAE.Variables inVariables3;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef1,inVariables2,inVariables3)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables vars,knvars;
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varName = DAE.CREF_IDENT(ident = _), varDirection = DAE.OUTPUT()) :: _),_) = getVar(cr, vars);
      then
        true;
    case (cr,vars,knvars)
      equation
        ((BackendDAE.VAR(varDirection = DAE.INPUT()) :: _),_) = getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
      then
        true;
    case (_,_,_) then false;
  end matchcontinue;
end isTopLevelInputOrOutput;



public function deleteVar
"function: deleteVar
  author: PA
  Deletes a variable from Variables. This is an expensive operation
  since we need to create a new binary tree with new indexes as well
  as a new compacted vector of variables."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inComponentRef,inVariables)
    local
      list<BackendDAE.Var> varlst,varlst_1;
      BackendDAE.Variables newvars,newvars_1;
      DAE.ComponentRef cr;
      array<list<BackendDAE.CrefIndex>> hashvec;
      array<list<BackendDAE.StringIndex>> oldhashvec;
      BackendDAE.VariableArray varr;
      BackendDAE.Value bsize,n;
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        varlst = BackendDAEUtil.vararrayList(varr);
        varlst_1 = deleteVar2(cr, varlst);
        newvars = BackendDAEUtil.emptyVars();
        newvars_1 = addVars(varlst_1, newvars);
      then
        newvars_1;
  end matchcontinue;
end deleteVar;

protected function deleteVar2
"function: deleteVar2
  author: PA
  Helper function to deleteVar.
  Deletes the var named DAE.ComponentRef from the BackendDAE.Variables list."
  input DAE.ComponentRef inComponentRef;
  input list<BackendDAE.Var> inVarLst;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := matchcontinue (inComponentRef,inVarLst)
    local
      DAE.ComponentRef cr1,cr2;
      list<BackendDAE.Var> vs,vs_1;
      BackendDAE.Var v;
    case (_,{}) then {};
    case (cr1,(BackendDAE.VAR(varName = cr2) :: vs))
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr1, cr2);
      then
        vs;
    case (cr1,(v :: vs))
      equation
        vs_1 = deleteVar2(cr1, vs);
      then
        (v :: vs_1);
  end matchcontinue;
end deleteVar2;




public function existsVar
"function: existsVar
  author: PA
  Return true if a variable exists in the vector"
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef,inVariables)
    local
      BackendDAE.Value hval,hashindx,indx,bsize,n;
      list<BackendDAE.CrefIndex> indexes;
      BackendDAE.Var v;
      DAE.ComponentRef cr2,cr;
      array<list<BackendDAE.CrefIndex>> hashvec;
      array<list<BackendDAE.StringIndex>> oldhashvec;
      BackendDAE.VariableArray varr;
      String str;
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        hval = HashTable2.hashFunc(cr);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes);
        ((v as BackendDAE.VAR(varName = cr2))) = vararrayNth(varr, indx);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      then
        true;
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        hval = HashTable2.hashFunc(cr);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes);
        failure((_) = vararrayNth(varr, indx));
        print("could not found variable, cr:");
        str = ComponentReference.printComponentRefStr(cr);
        print(str);
        print("\n");
      then
        false;
    case (_,_) then false;
  end matchcontinue;
end existsVar;



public function addVars "function: addVars
  author: PA

  Adds a list of \'Var\' to \'Variables\'
"
  input list<BackendDAE.Var> varlst;
  input BackendDAE.Variables vars;
  output BackendDAE.Variables vars_1;
  BackendDAE.Variables vars_1;
algorithm
  vars_1 := Util.listFold(varlst, addVar, vars);
end addVars;

public function addVar
"function: addVar
  author: PA
  Add a variable to Variables.
  If the variable already exists, the function updates the variable."
  input BackendDAE.Var inVar;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVar,inVariables)
    local
      BackendDAE.Value hval,indx,newpos,n_1,hvalold,indxold,bsize,n,indx_1;
      BackendDAE.VariableArray varr_1,varr;
      list<BackendDAE.CrefIndex> indexes;
      array<list<BackendDAE.CrefIndex>> hashvec_1,hashvec;
      String name_str;
      list<BackendDAE.StringIndex> indexexold;
      array<list<BackendDAE.StringIndex>> oldhashvec_1,oldhashvec;
      BackendDAE.Var v,newv;
      DAE.ComponentRef cr,name;
      DAE.Flow flowPrefix;
      BackendDAE.Variables vars;
    /* adrpo: ignore records!
    case ((v as BackendDAE.VAR(varName = cr,origVarName = name,flowPrefix = flowPrefix, varType = DAE.COMPLEX(_,_))),
          (vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
    then
      vars;
    */
    case ((v as BackendDAE.VAR(varName = cr,flowPrefix = flowPrefix)),(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        failure((_,_) = getVar(cr, vars)) "adding when not existing previously" ;
        hval = HashTable2.hashFunc(cr);
        indx = intMod(hval, bsize);
        newpos = vararrayLength(varr);
        varr_1 = vararrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, (BackendDAE.CREFINDEX(cr,newpos) :: indexes));
        n_1 = vararrayLength(varr_1);
        name_str = ComponentReference.printComponentRefStr(cr);
        hvalold = System.hash(name_str);
        indxold = intMod(hvalold, bsize);
        indexexold = oldhashvec[indxold + 1];
        oldhashvec_1 = arrayUpdate(oldhashvec, indxold + 1,
          (BackendDAE.STRINGINDEX(name_str,newpos) :: indexexold));
      then
        BackendDAE.VARIABLES(hashvec_1,oldhashvec_1,varr_1,bsize,n_1);

    case ((newv as BackendDAE.VAR(varName = cr,flowPrefix = flowPrefix)),(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        (_,{indx}) = getVar(cr, vars) "adding when already present => Updating value" ;
        indx_1 = indx - 1;
        varr_1 = vararraySetnth(varr, indx_1, newv);
      then
        BackendDAE.VARIABLES(hashvec,oldhashvec,varr_1,bsize,n);

    case (_,_)
      equation
        print("-add_var failed\n");
      then
        fail();
  end matchcontinue;
end addVar;

public function getVarAt
"function: getVarAt
  author: PA
  Return variable at a given position, enumerated from 1..n"
  input BackendDAE.Variables inVariables;
  input Integer inInteger;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVariables,inInteger)
    local
      BackendDAE.Value pos,n;
      BackendDAE.Var v;
      BackendDAE.VariableArray vararr;
    case (BackendDAE.VARIABLES(varArr = vararr),n)
      equation
        pos = n - 1;
        v = vararrayNth(vararr, pos);
      then
        v;
    case (BackendDAE.VARIABLES(varArr = vararr),n)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "BackendVariable.getVarAt failed to get the variable at index:" +& intString(n));
      then
        fail();
  end matchcontinue;
end getVarAt;

public function getVar
"function: getVar
  author: PA
  Return a variable(s) and its index(es) in the vector.
  The indexes is enumerated from 1..n
  Normally a variable has only one index, but in case of an array variable
  it may have several indexes and several scalar variables,
  therefore a list of variables and a list of  indexes is returned.
  inputs:  (DAE.ComponentRef, BackendDAE.Variables)
  outputs: (Var list, int list /* indexes */)"
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := matchcontinue (inComponentRef,inVariables)
    local
      BackendDAE.Var v;
      BackendDAE.Value indx;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      list<BackendDAE.Value> indxs;
      list<BackendDAE.Var> vLst;

    case (cr,vars)
      equation
        (v,indx) = getVar2(cr, vars) "if scalar found, return it" ;
      then
        ({v},{indx});
    case (cr,vars) /* check if array */
      equation
        (vLst,indxs) = getArrayVar(cr, vars);
      then
        (vLst,indxs);
    /* failure
    case (cr,vars)
      equation
        Debug.fprintln("daelow", "- BackendVariable.getVar failed on component reference: " +& ComponentReference.printComponentRefStr(cr));
      then
        fail();
    */
  end matchcontinue;
end getVar;

protected function getVar2
"function: getVar2
  author: PA
  Helper function to getVar, checks one scalar variable"
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Var outVar;
  output Integer outInteger;
algorithm
  (outVar,outInteger) := matchcontinue (inComponentRef,inVariables)
    local
      BackendDAE.Value hval,hashindx,indx,indx_1,bsize,n;
      list<BackendDAE.CrefIndex> indexes;
      BackendDAE.Var v;
      DAE.ComponentRef cr2,cr;
      DAE.Flow flowPrefix;
      array<list<BackendDAE.CrefIndex>> hashvec;
      array<list<BackendDAE.StringIndex>> oldhashvec;
      BackendDAE.VariableArray varr;
      String str;
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        hval = HashTable2.hashFunc(cr);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes);
        ((v as BackendDAE.VAR(varName = cr2, flowPrefix = flowPrefix))) = vararrayNth(varr, indx);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        indx_1 = indx + 1;
      then
        (v,indx_1);
  end matchcontinue;
end getVar2;

protected function getVar3
"function: getVar3
  author: PA
  Helper function to getVar"
  input DAE.ComponentRef inComponentRef;
  input list<BackendDAE.CrefIndex> inCrefIndexLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inComponentRef,inCrefIndexLst)
    local
      DAE.ComponentRef cr,cr2;
      BackendDAE.Value v,res;
      list<BackendDAE.CrefIndex> vs;
    case (cr,{})
      equation
        //Debug.fprint("failtrace", "-BackendVariable.getVar3 failed on:" +& ComponentReference.printComponentRefStr(cr) +& "\n");
      then
        fail();
    case (cr,(BackendDAE.CREFINDEX(cref = cr2,index = v) :: _))
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      then
        v;
    case (cr,(v :: vs))
      local BackendDAE.CrefIndex v;
      equation
        res = getVar3(cr, vs);
      then
        res;
  end matchcontinue;
end getVar3;



protected function getArrayVar
"function: getArrayVar
  author: PA
  Helper function to get_var, checks one array variable.
  I.e. get_array_var(v,<vars>) will for an array v{3} return
  { v{1},v{2},v{3} }"
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := matchcontinue (inComponentRef,inVariables)
    local
      DAE.ComponentRef cr_1,cr2,cr;
      BackendDAE.Value hval,hashindx,indx,bsize,n;
      list<BackendDAE.CrefIndex> indexes;
      BackendDAE.Var v;
      list<DAE.Subscript> instdims;
      DAE.Flow flowPrefix;
      list<BackendDAE.Var> vs;
      list<BackendDAE.Value> indxs;
      BackendDAE.Variables vars;
      array<list<BackendDAE.CrefIndex>> hashvec;
      array<list<BackendDAE.StringIndex>> oldhashvec;
      BackendDAE.VariableArray varr;
    case (cr,(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        cr_1 = ComponentReference.subscriptCref(cr, {DAE.INDEX(DAE.ICONST(1))}) "one dimensional arrays" ;
        hval = HashTable2.hashFunc(cr_1);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr_1, indexes);
        ((v as BackendDAE.VAR(varName = cr2, arryDim = instdims, flowPrefix = flowPrefix))) = vararrayNth(varr, indx);
        true = ComponentReference.crefEqualNoStringCompare(cr_1, cr2);
        (vs,indxs) = getArrayVar2(instdims, cr, vars);
      then
        (vs,indxs);
    case (cr,(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))) /* two dimensional arrays */
      equation
        cr_1 = ComponentReference.subscriptCref(cr, {DAE.INDEX(DAE.ICONST(1)),DAE.INDEX(DAE.ICONST(1))});
        hval = HashTable2.hashFunc(cr_1);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr_1, indexes);
        ((v as BackendDAE.VAR(varName = cr2, arryDim = instdims, flowPrefix = flowPrefix))) = vararrayNth(varr, indx);
        true = ComponentReference.crefEqualNoStringCompare(cr_1, cr2);
        (vs,indxs) = getArrayVar2(instdims, cr, vars);
      then
        (vs,indxs);
  end matchcontinue;
end getArrayVar;

protected function getArrayVar2
"function: getArrayVar2
  author: PA
  Helper function to getArrayVar.
  Note: Only implemented for arrays of dimension 1 and 2.
  inputs:  (DAE.InstDims, /* array_inst_dims */
              DAE.ComponentRef, /* array_var_name */
              Variables)
  outputs: (Var list /* arrays scalar vars */,
              int list /* arrays scalar indxs */)"
  input DAE.InstDims inInstDims;
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := matchcontinue (inInstDims,inComponentRef,inVariables)
    local
      list<BackendDAE.Value> indx_lst,indxs_1,indx_lst1,indx_lst2;
      list<list<BackendDAE.Value>> indx_lstlst,indxs,indx_lstlst1,indx_lstlst2;
      list<list<DAE.Subscript>> subscripts_lstlst,subscripts_lstlst1,subscripts_lstlst2,subscripts;
      list<BackendDAE.Key> scalar_crs;
      list<list<BackendDAE.Var>> vs;
      list<BackendDAE.Var> vs_1;
      BackendDAE.Value i1,i2;
      DAE.ComponentRef arr_cr;
      BackendDAE.Variables vars;
    case ({DAE.INDEX(exp = DAE.ICONST(integer = i1))},arr_cr,vars)
      equation
        indx_lst = Util.listIntRange(i1);
        indx_lstlst = Util.listMap(indx_lst, Util.listCreate);
        subscripts_lstlst = Util.listMap(indx_lstlst, Expression.intSubscripts);
        scalar_crs = Util.listMap1r(subscripts_lstlst, ComponentReference.subscriptCref, arr_cr);
        (vs,indxs) = Util.listMap12(scalar_crs, getVar, vars);
        vs_1 = Util.listFlatten(vs);
        indxs_1 = Util.listFlatten(indxs);
      then
        (vs_1,indxs_1);
    case ({DAE.INDEX(exp = DAE.ICONST(integer = i1)),DAE.INDEX(exp = DAE.ICONST(integer = i2))},arr_cr,vars)
      equation
        indx_lst1 = Util.listIntRange(i1);
        indx_lstlst1 = Util.listMap(indx_lst1, Util.listCreate);
        subscripts_lstlst1 = Util.listMap(indx_lstlst1, Expression.intSubscripts);
        indx_lst2 = Util.listIntRange(i2);
        indx_lstlst2 = Util.listMap(indx_lst2, Util.listCreate);
        subscripts_lstlst2 = Util.listMap(indx_lstlst2, Expression.intSubscripts);
        subscripts = BackendDAEUtil.subscript2dCombinations(subscripts_lstlst1, subscripts_lstlst2) "make all possbible combinations to get all 2d indexes" ;
        scalar_crs = Util.listMap1r(subscripts, ComponentReference.subscriptCref, arr_cr);
        (vs,indxs) = Util.listMap12(scalar_crs, getVar, vars);
        vs_1 = Util.listFlatten(vs);
        indxs_1 = Util.listFlatten(indxs);
      then
        (vs_1,indxs_1);
    // adrpo: cr can be of form cr.cr.cr[2].cr[3] which means that it has type dimension [2,3] but we only need to walk [3]
    case ({_,DAE.INDEX(exp = DAE.ICONST(integer = i1))},arr_cr,vars)
      equation
        // see if cr contains ANY array dimensions. if it doesn't this case is not valid!
        true = ComponentReference.crefHaveSubs(arr_cr);
        indx_lst = Util.listIntRange(i1);
        indx_lstlst = Util.listMap(indx_lst, Util.listCreate);
        subscripts_lstlst = Util.listMap(indx_lstlst, Expression.intSubscripts);
        scalar_crs = Util.listMap1r(subscripts_lstlst, ComponentReference.subscriptCref, arr_cr);
        (vs,indxs) = Util.listMap12(scalar_crs, getVar, vars);
        vs_1 = Util.listFlatten(vs);
        indxs_1 = Util.listFlatten(indxs);
      then
        (vs_1,indxs_1);
  end matchcontinue;
end getArrayVar2;

public function mergeVariables
"function: mergeVariables
  author: PA
  Takes two sets of BackendDAE.Variables and merges them. The variables of the
  first argument takes precedence over the second set, i.e. if a
  variable name exists in both sets, the variable definition from
  the first set is used."
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVariables1,inVariables2)
    local
      list<BackendDAE.Var> varlst;
      BackendDAE.Variables vars1_1,vars1,vars2;
    case (vars1,vars2)
      equation
        varlst = BackendDAEUtil.varList(vars2);
        vars1_1 = Util.listFold(varlst, addVar, vars1);
      then
        vars1_1;
    case (_,_)
      equation
        print("-merge_variables failed\n");
      then
        fail();
  end matchcontinue;
end mergeVariables;




end BackendVariable;

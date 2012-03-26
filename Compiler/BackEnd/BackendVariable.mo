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

encapsulated package BackendVariable
" file:        BackendVariable.mo
  package:     BackendVariable
  description: BackendVariables contains the function that deals with the datytypes
               BackendDAE.VAR BackendDAE.Variables and BackendVariablesArray.
  
  RCS: $Id$
"

public import BackendDAE;
public import DAE;
public import Values;

protected import Absyn;
protected import BackendDAEUtil;
protected import ClassInf;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import ExpressionSimplify;
protected import Flags;
protected import HashTable2;
protected import List;
protected import SCode;
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
  name."
  input list<BackendDAE.Var> inVarLst;
  input DAE.ComponentRef inComponentRef;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVarLst,inComponentRef)
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
  match (inVar1,inVar2)
    local
      Boolean res;
      DAE.ComponentRef cr1,cr2;
    case (BackendDAE.VAR(varName = cr1),BackendDAE.VAR(varName = cr2))
      equation
        res = ComponentReference.crefEqualNoStringCompare(cr1, cr2) "A BackendDAE.Var is identified by its component reference" ;
      then
        res;
  end match;
end varEqual;



public function setVarFixed
"function: setVarFixed
  author: PA
  Sets the fixed attribute of a variable."
  input BackendDAE.Var inVar;
  input Boolean inBoolean;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,inBoolean)
    local
      DAE.ComponentRef a;
      BackendDAE.VarKind b;
      DAE.VarDirection c;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      BackendDAE.Value i;
      DAE.ElementSource source;
      DAE.VariableAttributes attr;
      Option<DAE.VariableAttributes> oattr;
      Option<SCode.Comment> s;
      DAE.Flow t;
      DAE.Stream streamPrefix;
      Boolean fixed;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(attr),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      equation
        oattr = DAEUtil.setFixedAttr(SOME(attr),SOME(DAE.BCONST(fixed)));
      then BackendDAE.VAR(a,b,c,d,e,f,g,i,source,oattr,s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = DAE.T_REAL(source = _),
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
        BackendDAE.VAR(a,b,c,DAE.T_REAL_DEFAULT,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(fixed)),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = DAE.T_INTEGER(source = _),
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
        BackendDAE.VAR(a,b,c,DAE.T_REAL_DEFAULT,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(fixed)),NONE(),NONE(),NONE(),NONE())),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = DAE.T_BOOL(source = _),
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
        BackendDAE.VAR(a,b,c,DAE.T_REAL_DEFAULT,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_BOOL(NONE(),NONE(),SOME(DAE.BCONST(fixed)),NONE(),NONE(),NONE())),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = DAE.T_ENUMERATION(source = _),
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
        BackendDAE.VAR(a,b,c,DAE.T_REAL_DEFAULT,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_ENUMERATION(NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(fixed)),NONE(),NONE(),NONE())),
            s,t,streamPrefix);
  end match;
end setVarFixed;

public function varFixed
"function: varFixed
  author: PA
  Extracts the fixed attribute of a variable.
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
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(fixed=SOME(DAE.BCONST(fixed)))))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_INT(fixed=SOME(DAE.BCONST(fixed)))))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_BOOL(fixed=SOME(DAE.BCONST(fixed)))))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_ENUMERATION(fixed=SOME(DAE.BCONST(fixed)))))) then fixed;
    case (v) /* params are by default fixed */
      equation
        BackendDAE.PARAM() = varKind(v);
      then
        true;
/*  See Modelica Spec 3.2 page 88: 
    For constants and parameters, the attribute fixed is by default true. For other variables
    fixed is by default false. For all variables declared as constant it is an error to have "fixed = false".      
  case (v) // states are by default fixed. 
      equation
        BackendDAE.STATE() = varKind(v);
        fixes = Flags.isSet(Flags.INIT_DLOW_DUMP);
      then
        not fixed;
*/
    case (_) then false;  /* rest defaults to false*/
  end matchcontinue;
end varFixed;

public function setVarStartValue
"function: setVarStartValue
  author: Frenkel TUD
  Sets the start value attribute of a variable."
  input BackendDAE.Var inVar;
  input DAE.Exp inExp;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,inExp)
    local
      DAE.ComponentRef a;
      BackendDAE.VarKind b;
      DAE.VarDirection c;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      BackendDAE.Value i;
      DAE.ElementSource source;
      DAE.VariableAttributes attr;
      Option<DAE.VariableAttributes> oattr,oattr1;
      Option<SCode.Comment> s;
      DAE.Flow t;
      DAE.Stream streamPrefix;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(attr),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),inExp)
      equation
        oattr1 = DAEUtil.setStartAttr(SOME(attr),inExp);
    then BackendDAE.VAR(a,b,c,d,e,f,g,i,source,oattr1,s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = DAE.T_REAL(source = _),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE(),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),inExp)
      then
        BackendDAE.VAR(a,b,c,DAE.T_REAL_DEFAULT,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),SOME(inExp),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = DAE.T_INTEGER(source = _),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE(),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),inExp)
      then
        BackendDAE.VAR(a,b,c,DAE.T_REAL_DEFAULT,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),SOME(inExp),NONE(),NONE(),NONE(),NONE(),NONE())),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = DAE.T_BOOL(source = _),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE(),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),inExp)
      then
        BackendDAE.VAR(a,b,c,DAE.T_REAL_DEFAULT,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_BOOL(NONE(),SOME(inExp),NONE(),NONE(),NONE(),NONE())),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = DAE.T_ENUMERATION(source = _),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE(),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),inExp)
      then
        BackendDAE.VAR(a,b,c,DAE.T_REAL_DEFAULT,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_ENUMERATION(NONE(),(NONE(),NONE()),SOME(inExp),NONE(),NONE(),NONE(),NONE())),
            s,t,streamPrefix);
  end match;
end setVarStartValue;

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

public function varStartValueFail
"function varStartValueFail
  author: Frenkel TUD
  Returns the DAE.StartValue of a variable if there is one. 
  Otherwise fail"
  input BackendDAE.Var v;
  output DAE.Exp sv;
algorithm
  sv := match(v)
    local
      Option<DAE.VariableAttributes> attr;
    case (BackendDAE.VAR(values = attr))
      equation
        sv=DAEUtil.getStartAttrFail(attr);
      then sv;
   end match;
end varStartValueFail;

public function varStartValueOption
"function varStartValueOption
  author: Frenkel TUD
  Returns the DAE.StartValue of a variable if there is one. 
  Otherwise fail"
  input BackendDAE.Var v;
  output Option<DAE.Exp> sv;
algorithm
  sv := matchcontinue(v)
    local
      Option<DAE.VariableAttributes> attr;
      DAE.Exp exp;
    case (BackendDAE.VAR(values = attr))
      equation
        exp=DAEUtil.getStartAttrFail(attr);
      then SOME(exp);
    else NONE();
   end matchcontinue;
end varStartValueOption;

public function varBindExp
"function varBindExp
  author: Frenkel TUD 2010-12
  Returns the bindExp of a variable."
  input BackendDAE.Var v;
  output DAE.Exp sv;
algorithm
  sv := match(v)
    local DAE.Exp e;
    case (BackendDAE.VAR(bindExp = SOME(e))) then e;
   end match;
end varBindExp;


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
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption=SOME(stateselect))))) then stateselect;
    case (_) then DAE.DEFAULT();
  end matchcontinue;
end varStateSelect;

public function setVarMinMax
"function: setVarMinMax
  author: Frenkel TUD
  Sets the minmax attribute of a variable."
  input BackendDAE.Var inVar;
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,minMax)
    local
      DAE.ComponentRef a;
      BackendDAE.VarKind b;
      DAE.VarDirection c;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      BackendDAE.Value i;
      DAE.ElementSource source;
      DAE.VariableAttributes attr;
      Option<DAE.VariableAttributes> oattr,oattr1;
      Option<SCode.Comment> s;
      DAE.Flow t;
      DAE.Stream streamPrefix;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(attr),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),minMax)
      equation
        oattr1 = DAEUtil.setMinMax(SOME(attr),minMax);
    then BackendDAE.VAR(a,b,c,d,e,f,g,i,source,oattr1,s,t,streamPrefix);
  end match;
end setVarMinMax;

public function varNominalValue
"function varHasNominal
  author: Frenkel TUD"
  input BackendDAE.Var inVar;
  output DAE.Exp outExp;
algorithm
  outExp:=
  match (inVar)
    local DAE.Exp e;
      DAE.StateSelect stateselect;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(nominal=SOME(e))))) then e;
  end match;
end varNominalValue;

public function setVarNominalValue
"function: setVarNominalValue
  author: Frenkel TUD
  Sets the nominal value attribute of a variable."
  input BackendDAE.Var inVar;
  input DAE.Exp inExp;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,inExp)
    local
      DAE.ComponentRef a;
      BackendDAE.VarKind b;
      DAE.VarDirection c;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      BackendDAE.Value i;
      DAE.ElementSource source;
      DAE.VariableAttributes attr;
      Option<DAE.VariableAttributes> oattr,oattr1;
      Option<SCode.Comment> s;
      DAE.Flow t;
      DAE.Stream streamPrefix;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(attr),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),inExp)
      equation
        oattr1 = DAEUtil.setNominalAttr(SOME(attr),inExp);
    then BackendDAE.VAR(a,b,c,d,e,f,g,i,source,oattr1,s,t,streamPrefix);
  end match;
end setVarNominalValue;

public function varType "function: varType
  author: PA

  extracts the type of a variable.
"
  input BackendDAE.Var inVar;
  output BackendDAE.Type outType;
algorithm
  outType:=
  match (inVar)
    local BackendDAE.Type tp;
    case (BackendDAE.VAR(varType = tp)) then tp;
  end match;
end varType;

public function varKind "function: varKind
  author: PA

  extracts the kind of a variable.
"
  input BackendDAE.Var inVar;
  output BackendDAE.VarKind outVarKind;
algorithm
  outVarKind:=
  match (inVar)
    local BackendDAE.VarKind kind;
    case (BackendDAE.VAR(varKind = kind)) then kind;
  end match;
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
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,SOME(DAE.RCONST(nominal)),_,_,_,_,_)))) then nominal;
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
  match (inVar)
    local
      DAE.ComponentRef cr;
    case (BackendDAE.VAR(varName = cr)) then cr;
  end match;
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

public function isState
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inVars;
  output Boolean outBool;
algorithm
  outBool:=
  matchcontinue(inCref,inVars)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
    case(cr,vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.STATE()) :: _),_) = getVar(cr, vars);
      then 
        true;
    case(_,_) then false;
  end matchcontinue;
end isState;

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

  public function varHasUncertainValueRefine
"
  author: Daniel Hedberg, 2011-01
  modified by: Leonardo Laguna, 2012-01
  
  Returns true if the specified variable has the attribute uncertain and the
  value of it is Uncertainty.refine, false otherwise.
"
  input BackendDAE.Var var;
  output Boolean b;
algorithm 
  b := matchcontinue (var)
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(uncertainOption = SOME(DAE.REFINE()))))) then true;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_INT(uncertainOption = SOME(DAE.REFINE()))))) then true;
    case (_) then false;
  end matchcontinue;
end varHasUncertainValueRefine;

protected function failIfNonState
"Fails if the given variable kind is state."
  input BackendDAE.Var inVar;
algorithm
  _ :=
  match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE())) then ();
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER())) then ();
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE())) then ();
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE())) then ();
    case (BackendDAE.VAR(varKind = BackendDAE.STATE_DER())) then ();
  end match;
end failIfNonState;

public function isDummyStateVar
"function isDummyStateVar
  Returns true for dummy state variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE())) then true;
  else
   then false;
  end match;
end isDummyStateVar;

public function isDummyDerVar
"function isDummyDerVar
  Returns true for dummy state variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER())) then true;
  else
   then false;
  end match;
end isDummyDerVar;

public function isStateorStateDerVar
"function: isStateorStateDerVar
  Returns true for state and der(state) variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.STATE())) then true;
    case (BackendDAE.VAR(varKind = BackendDAE.STATE_DER())) then true;
  else
   then false;
  end match;
end isStateorStateDerVar;

public function isVarDiscrete
" This functions checks if BackendDAE.Var is discrete"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean := 
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE())) then true;
    case (BackendDAE.VAR(varType = DAE.T_INTEGER(source = _))) then true;
    case (BackendDAE.VAR(varType = DAE.T_BOOL(source = _))) then true;
    case (BackendDAE.VAR(varType = DAE.T_ENUMERATION(source = _))) then true;
    case (_) then false;
  end matchcontinue;
end isVarDiscrete;

public function hasDiscreteVar
"Returns true if var list contains a discrete time variable."
  input list<BackendDAE.Var> inBackendDAEVarLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inBackendDAEVarLst)
    local
      Boolean res;
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;
    case ((v :: vs))
      equation
        true = isVarDiscrete(v);
      then
        true;
    case ((v :: vs))
      equation
        res = hasDiscreteVar(vs);
      then
        res;
    case ({}) then false;
  end matchcontinue;
end hasDiscreteVar;

public function hasContinousVar
"Returns true if var list contains a continous time variable."
  input list<BackendDAE.Var> inBackendDAEVarLst;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inBackendDAEVarLst)
    local
      Boolean res;
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;
    case ((BackendDAE.VAR(varKind=BackendDAE.VARIABLE(),varType = DAE.T_INTEGER(source = _)) :: _)) then false;
    case ((BackendDAE.VAR(varKind=BackendDAE.VARIABLE(),varType = DAE.T_BOOL(source = _)) :: _)) then false;
    case ((BackendDAE.VAR(varKind=BackendDAE.VARIABLE(),varType = DAE.T_ENUMERATION(source = _)) :: _)) then false;            
    case ((BackendDAE.VAR(varKind=BackendDAE.VARIABLE()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.STATE()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.STATE_DER()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.DUMMY_DER()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.DUMMY_STATE()) :: _)) then true;
    case ((v :: vs))
      equation
        res = hasContinousVar(vs);
      then
        res;
    case ({}) then false;
  end match;
end hasContinousVar;

/* TODO: Is this correct? */
public function isVarAlg
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result := match (var)
    local
      BackendDAE.VarKind kind;
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* bool variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as DAE.T_BOOL(source = _)))
      then false;
    /* int variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as DAE.T_INTEGER(source = _)))
      then false;
    /* string variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as DAE.T_STRING(source = _)))
      then false;
    /* non-string variable */
    case (BackendDAE.VAR(varKind = kind))
      equation
        kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DISCRETE(), BackendDAE.DUMMY_DER(),
                    BackendDAE.DUMMY_STATE()};
      then listMember(kind, kind_lst);
  end match;
end isVarAlg;

/* TODO: Is this correct? */
public function isVarStringAlg
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result := match (var)
    local
      BackendDAE.VarKind kind;
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* string variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as DAE.T_STRING(source = _)))
      equation
        kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DISCRETE(), BackendDAE.DUMMY_DER(),
                    BackendDAE.DUMMY_STATE()};
      then listMember(kind, kind_lst);
    else false;
  end match;
end isVarStringAlg;

public function isVarIntAlg
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result := match (var)
    local
      BackendDAE.VarKind kind;
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* int variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as DAE.T_INTEGER(source = _)))
      equation

        kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DISCRETE(), BackendDAE.DUMMY_DER(),
                    BackendDAE.DUMMY_STATE()};
      then listMember(kind, kind_lst);
    else false;
  end match;
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
                     varType = typeVar as DAE.T_BOOL(source = _)))
      equation
        kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DISCRETE(), BackendDAE.DUMMY_DER(),
                    BackendDAE.DUMMY_STATE()};
      then listMember(kind, kind_lst);
    else false;
  end matchcontinue;
end isVarBoolAlg;

public function isVarConst
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    /* bool variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_BOOL(source = _)))
      then false;
    /* int variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_INTEGER(source = _)))
      then false;
    /* string variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_STRING(source = _)))
      then false;
    /* non-string variable */
    case (var)
      equation
        true = isConst(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarConst;

public function isVarStringConst
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    /* string variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_STRING(source = _)))
      equation
        true = isConst(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarStringConst;

public function isVarIntConst
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    /* int variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_INTEGER(source = _)))
      equation
        true = isConst(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarIntConst;

public function isVarBoolConst
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    /* string variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_BOOL(source = _)))
      equation
        true = isConst(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarBoolConst;

/* TODO: Is this correct? */
public function isVarParam
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    /* bool variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_BOOL(source = _)))
      then false;
    /* int variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_INTEGER(source = _)))
      then false;
    /* string variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_STRING(source = _)))
      then false;
    /* enum variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_ENUMERATION(source = _)))
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
    /* string variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_STRING(source = _)))
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
    // int variable 
    case (BackendDAE.VAR(varType = typeVar as DAE.T_INTEGER(source = _)))
      equation
        true = isParam(var);
      then true;
    // enum is also mapped to long 
    case (BackendDAE.VAR(varType = typeVar as DAE.T_ENUMERATION(source = _)))
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
    /* string variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_BOOL(source = _)))
      equation
        true = isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarBoolParam;

public function isVarConnector
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  match (var)
    case (BackendDAE.VAR(flowPrefix = DAE.FLOW())) then true;
    case (BackendDAE.VAR(flowPrefix = DAE.NON_FLOW())) then true;
    case (BackendDAE.VAR(streamPrefix = DAE.STREAM())) then true;
    case (BackendDAE.VAR(streamPrefix = DAE.NON_STREAM())) then true;
    case (_)
      then false;
  end match;
end isVarConnector;

public function varIndexComparer
  input BackendDAE.Var lhs;
  input BackendDAE.Var rhs;
  output Boolean res;
algorithm
  res :=
  match (lhs, rhs)
      local
      Integer lhsIndex;
      Integer rhsIndex;
    case (BackendDAE.VAR(index=lhsIndex), BackendDAE.VAR(index=rhsIndex))
      then rhsIndex < lhsIndex;
  end match;
end varIndexComparer;

public function isConst
"function: isConst
  Return true if variable is a constant."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case BackendDAE.VAR(varKind = BackendDAE.CONST()) then true;
    case (_) then false;
  end matchcontinue;
end isConst;

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
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = DAE.T_INTEGER(source = _))) then true;
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
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = DAE.T_BOOL(source = _))) then true;
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
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = DAE.T_STRING(source = _))) then true;
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
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = DAE.T_REAL(source = _))) then true;
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

public function isInput
"function: isInput
  Returns true if variable is declared as input.
  See also is_ouput above"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varDirection = DAE.INPUT())) then true;
    case (_) then false;
  end matchcontinue;
end isInput;


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

public function createpDerVar
"function creatVarpDerCVar
  author: wbraun
  Create variable with $pDER.v as cref for jacobian variables."
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      BackendDAE.Value i;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      BackendDAE.Var oVar;

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
              streamPrefix = streamPrefix))
    equation
      cr = ComponentReference.makeCrefQual(BackendDAE.partialDerivativeNamePrefix, DAE.T_REAL_DEFAULT, {}, cr);
      oVar = BackendDAE.VAR(cr,BackendDAE.JAC_DIFF_VAR(),dir,tp,bind,v,dim,i,source,attr,comment,flowPrefix,streamPrefix); // referenceUpdate(inVar, 8, new_i);
    then
      oVar; 
  end match;
end createpDerVar;

public function setVarKind
"function setVarKind
  author: PA
  Sets the BackendDAE.VarKind of a variable"
  input BackendDAE.Var inVar;
  input BackendDAE.VarKind inVarKind;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,inVarKind)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind,new_kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      BackendDAE.Value i;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      BackendDAE.Var oVar;

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
    equation
      oVar = BackendDAE.VAR(cr,new_kind,dir,tp,bind,v,dim,i,source,attr,comment,flowPrefix,streamPrefix); // referenceUpdate(inVar, 2, new_kind);
    then 
      oVar; 
  end match;
end setVarKind;

public function setVarIndex
"function setVarKind
  author: PA
  Sets the BackendDAE.VarKind of a variable"
  input BackendDAE.Var inVar;
  input BackendDAE.Value inVarIndex;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,inVarIndex)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      BackendDAE.Value i,new_i;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      BackendDAE.Var oVar;

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
    equation
      oVar = BackendDAE.VAR(cr,kind,dir,tp,bind,v,dim,new_i,source,attr,comment,flowPrefix,streamPrefix); // referenceUpdate(inVar, 8, new_i);
    then
      oVar; 
  end match;
end setVarIndex;

public function setBindExp
"function setBindExp
  author: Frenkel TUD 2010-12
  Sets the BackendDAE.Var.bindExp of a variable"
  input BackendDAE.Var inVar;
  input DAE.Exp inBindExp;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,inBindExp)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      BackendDAE.Value i;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      BackendDAE.Var oVar;

    case (BackendDAE.VAR(varName = cr,
              varKind = kind,
              varDirection = dir,
              varType = tp,
              bindValue = v,
              arryDim = dim,
              index = i,
              source = source,
              values = attr,
              comment = comment,
              flowPrefix = flowPrefix,
              streamPrefix = streamPrefix),
          inBindExp)
    equation
      oVar = BackendDAE.VAR(cr,kind,dir,tp,SOME(inBindExp),v,dim,i,source,attr,comment,flowPrefix,streamPrefix); // referenceUpdate(inVar, 5, SOME(inBindExp));
    then 
      oVar;
  end match;
end setBindExp;

public function setBindValue
"function setBindExp
  author: Frenkel TUD 2010-12
  Sets the BackendDAE.Var.bindExp of a variable"
  input BackendDAE.Var inVar;
  input Values.Value inBindValue;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,inBindValue)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      list<DAE.Subscript> dim;
      BackendDAE.Value i;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      BackendDAE.Var oVar;

    case (BackendDAE.VAR(varName = cr,
              varKind = kind,
              varDirection = dir,
              varType = tp,
              bindExp = bind,
              bindValue = NONE(),
              arryDim = dim,
              index = i,
              source = source,
              values = attr,
              comment = comment,
              flowPrefix = flowPrefix,
              streamPrefix = streamPrefix),inBindValue)
    equation
      oVar = BackendDAE.VAR(cr,kind,dir,tp,bind,SOME(inBindValue),dim,i,source,attr,comment,flowPrefix,streamPrefix); // referenceUpdate(inVar, 6, SOME(inBindValue));
    then 
      oVar;
  end match;
end setBindValue;

public function setVarDirection
"function setVarDirection
  author: Frenkel TUD 17-03-11
  Sets the DAE.VarDirection of a variable"
  input BackendDAE.Var inVar;
  input DAE.VarDirection varDirection;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,varDirection)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      BackendDAE.Value i;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      BackendDAE.Var oVar;

    case (BackendDAE.VAR(varName = cr,
              varKind = kind,
              varType = tp,
              bindExp = bind,
              bindValue = v,
              arryDim = dim,
              index = i,
              source = source,
              values = attr,
              comment = comment,
              flowPrefix = flowPrefix,
              streamPrefix = streamPrefix),varDirection)
    equation
      oVar = BackendDAE.VAR(cr,kind,varDirection,tp,bind,v,dim,i,source,attr,comment,flowPrefix,streamPrefix); // referenceUpdate(inVar, 3, varDirection);
    then 
      oVar; 
  end match;
end setVarDirection;

public function getVarDirection
"function getVarDirection
  author: wbraun
  Get the DAE.VarDirection of a variable"
  input BackendDAE.Var inVar;
  output DAE.VarDirection varDirection;
algorithm
  varDirection := match (inVar)
    case (BackendDAE.VAR(varDirection = varDirection)) then  varDirection; 
  end match;
end getVarDirection;


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


public function isFinalVar
"function isFinalVar
  author: Frenkel TUD
  Returns true if var is final."
  input BackendDAE.Var v;
  output Boolean b;
algorithm
  b := match(v)
    local
      Option<DAE.VariableAttributes> attr;
    case (BackendDAE.VAR(values = attr))
      equation
        b=DAEUtil.getFinalAttr(attr);
      then b;
   end match;
end isFinalVar;

protected function getVariableAttributes
"function getVariableAttributes
  author: Frenkel TUD 2011-04
  returns the DAE.VariableAttributes of a variable"
  input BackendDAE.Var inVar;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr := match (inVar)
    local
      Option<DAE.VariableAttributes> attr;
    case BackendDAE.VAR(values = attr) then attr;
  end match;
end getVariableAttributes;

public function getVarSource
"function getVarSource
  author: Frenkel TUD 2011-04
  returns the DAE.ElementSource of a variable"
  input BackendDAE.Var inVar;
  output DAE.ElementSource outSource;
algorithm
  outSource := match (inVar)
    local
      DAE.ElementSource source;
    case BackendDAE.VAR(source = source) then source;
  end match;
end getVarSource;

public function getMinMaxAsserts
"Author: Frenkel TUD 2011-03"
  input Option<DAE.VariableAttributes> attr;
  input DAE.ComponentRef name;
  input DAE.ElementSource source;
  input BackendDAE.VarKind kind;
  input BackendDAE.Type vartype;
  output list<DAE.Algorithm> minmax;
algorithm
  minmax :=
  matchcontinue (attr,name,source,kind,vartype)
    local
      DAE.Exp e,cond,msg;
      list<Option<DAE.Exp>> ominmax;
      String str;
      DAE.Type tp;
    case(_,_,_,BackendDAE.CONST(),_) then {};
    case (attr,name,source,_,vartype)
      equation 
        ominmax = DAEUtil.getMinMax(attr);
        str = ComponentReference.crefStr(name);
        str = stringAppendList({"Variable ",str," out of limit"});
        msg = DAE.SCONST(str);
        e = Expression.crefExp(name);
        tp = BackendDAEUtil.makeExpType(vartype);
        cond = getMinMaxAsserts1(ominmax,e,tp);
        (cond,_) = ExpressionSimplify.simplify(cond);
        // do not add if const true
        false = Expression.isConstTrue(cond);
        BackendDAEUtil.checkAssertCondition(cond,msg);
      then 
        {DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond,msg,source)})};
    case(_,_,_,_,_) then {};
  end matchcontinue;
end getMinMaxAsserts;

protected function getMinMaxAsserts1
"Author: Frenkel TUD 2011-03"
  input list<Option<DAE.Exp>> ominmax;
  input DAE.Exp e;
  input DAE.Type tp;
  output DAE.Exp cond;
algorithm
  cond :=
  match (ominmax,e,tp)
    local
      DAE.Exp min,max;
    case (SOME(min)::(SOME(max)::{}),e,tp)
      then DAE.LBINARY(DAE.RELATION(e,DAE.GREATEREQ(tp),min,-1,NONE()),
                            DAE.AND(DAE.T_BOOL_DEFAULT),
                            DAE.RELATION(e,DAE.LESSEQ(tp),max,-1,NONE()));
    case (SOME(min)::(NONE()::{}),e,tp)
      then DAE.RELATION(e,DAE.GREATEREQ(tp),min,-1,NONE());
    case (NONE()::(SOME(max)::{}),e,tp)
      then DAE.RELATION(e,DAE.LESSEQ(tp),max,-1,NONE());
  end match;
end getMinMaxAsserts1;

public function getNominalAssert
"Author: Frenkel TUD 2011-03"
  input Option<DAE.VariableAttributes> attr;
  input DAE.ComponentRef name;
  input DAE.ElementSource source;
  input BackendDAE.VarKind kind;
  input BackendDAE.Type vartype;
  output list<DAE.Algorithm> nominal;
algorithm
  nominal :=
  matchcontinue (attr,name,source,kind,vartype)
    local
      DAE.Exp e,cond,msg;
      list<Option<DAE.Exp>> ominmax;
      String str;
      DAE.Type tp;
      Boolean b;
    case(_,_,_,BackendDAE.CONST(),_) then {};
    case (attr as SOME(DAE.VAR_ATTR_REAL(nominal=SOME(e))),name,source,_,vartype)
      equation 
        ominmax = DAEUtil.getMinMax(attr);
        str = ComponentReference.crefStr(name);
        str = stringAppendList({"Nominal ",str," out of limit"});
        msg = DAE.SCONST(str);
        tp = BackendDAEUtil.makeExpType(vartype);
        cond = getMinMaxAsserts1(ominmax,e,tp);
        (cond,_) = ExpressionSimplify.simplify(cond);
        // do not add if const true
        false = Expression.isConstTrue(cond);
        BackendDAEUtil.checkAssertCondition(cond,msg);
      then 
        {DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond,msg,source)})};
    case(_,_,_,_,_) then {};
  end matchcontinue;
end getNominalAssert;


/* =======================================================
 *
 *  Section for functions that deals with VariablesArray 
 *
 * =======================================================
 */

public function numVariables
  input BackendDAE.Variables vars;
  output Integer n;
algorithm
  BackendDAE.VARIABLES(varArr=BackendDAE.VARIABLE_ARRAY(numberOfElements = n)) := vars;
end numVariables;

protected function vararrayLength
"function: vararrayLength
  author: PA
  Returns the number of variable in the BackendDAE.VariableArray"
  input BackendDAE.VariableArray inVariableArray;
  output Integer outInteger;
algorithm
  outInteger := match (inVariableArray)
    local BackendDAE.Value n;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n)) then n;
  end match;
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
        print("- BackendVariable.vararrayAdd failed\n");
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
        print("- BackendVariable.vararraySetnth failed\n");
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
      BackendDAE.Value n,pos;
      array<Option<BackendDAE.Var>> arr;
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
        print("- BackendVariable.vararrayNth has NONE!!!\n");
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


public function calculateIndexes "function: calculateIndexes
  author: PA modified by Frenkel TUD

  Helper function to translate_dae. Calculates the indexes for each variable
  in one of the arrays. x, xd, y and extobjs.
  To ensure that arrays(matrix,vector) are in a continuous memory block
  the indexes from vars, knvars and extvars has to be calculate at the same time.
  To seperate them after that they are stored in a list with
  the information about the type(vars=0,knvars=1,extvars=2) and the place at the
  original list."
  input list<list<BackendDAE.Var>> inVarLst1;
  input list<BackendDAE.Var> inVarLst2;
  input list<BackendDAE.Var> inVarLst3;

  output list<list<BackendDAE.Var>> outVarLst1;
  output list<BackendDAE.Var> outVarLst2;
  output list<BackendDAE.Var> outVarLst3;
algorithm
  (outVarLst1,outVarLst2,outVarLst3) := matchcontinue (inVarLst1,inVarLst2,inVarLst3)
    local
      list<list<BackendDAE.Var>> varsLst,vars_2;
      list<BackendDAE.Var> knvars_2,extvars_2,extvars,vars,knvars;
      list< tuple<BackendDAE.Var,Integer> > knvars_1,extvars_1;
      list<list< tuple<BackendDAE.Var,Integer> >> vars_1;
      list< tuple<BackendDAE.Var,Integer,Integer> > vars_map,knvars_map,extvars_map,all_map,all_map1,noScalar_map,noScalar_map1,scalar_map,all_map2,mergedvar_map,sort_map;
      BackendDAE.Value x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType;
    case (varsLst,knvars,extvars)
      equation
        // store vars,knvars,extvars in the list
        vars_map = fillListListConst(varsLst,0,{});
        knvars_map = fillListConst(knvars,-1,0,{});
        extvars_map = fillListConst(extvars,-2,0,{});
        // connect the lists
        all_map = listAppend(vars_map,knvars_map);
        all_map1 = listAppend(all_map,extvars_map);
        // seperate scalars and non scalars
        (noScalar_map,scalar_map) = getNoScalarVars(all_map1);

        noScalar_map1 = getAllElements(noScalar_map);
        sort_map = sortNoScalarList(noScalar_map1);
        //print("\nsort_map:\n");
        //dumpSortMap(sort_map);
        // connect scalars and sortet non scalars
        mergedvar_map = listAppend(scalar_map,sort_map);
        // calculate indexes
        (all_map2,x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType) = calculateIndexes2(mergedvar_map,0,0,0,0,0,0,0,0,0,0,0,{});
        // seperate vars,knvars,extvas
        vars_1 = List.map1r(List.intRange2(0,listLength(varsLst)-1),getListConst,all_map2);
        knvars_1 = getListConst(all_map2,-1);
        extvars_1 =  getListConst(all_map2,-2);
        // arrange lists in original order
        vars_2 = List.map1(vars_1,sortList,0);
        knvars_2 = sortList(knvars_1,0);
        extvars_2 =  sortList(extvars_1,0);
      then
        (vars_2,knvars_2,extvars_2);
    case (_,_,_)
      equation
        print("- BackendVariable.calculateIndexes failed\n");
      then
        fail();
  end matchcontinue;
end calculateIndexes;

protected function fillListConst
"function: fillListConst
author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list, a type value an a start place and store all elements
  of the list in a list of tuples (element,type,place)"
  input list<Type_a> inTypeALst;
  input Integer inType;
  input Integer inPlace;
  input list< tuple<Type_a,Integer,Integer> > inAcc;
  output list< tuple<Type_a,Integer,Integer> > outlist;
  replaceable type Type_a subtypeof Any;
algorithm
  outlist := match (inTypeALst,inType,inPlace,inAcc)
    local
      list<Type_a> rest;
      Type_a item;
      Integer value,place;
      list< tuple<Type_a,Integer,Integer> > out_lst,val_lst,acc;
      
    case ({},value,place,acc) then acc;
    case (item::rest,value,place,acc)
      equation
        /* recursive */
        acc = fillListConst(rest,value,place+1,(item,value,place)::acc);
      then
        acc;
  end match;
end fillListConst;

protected function fillListListConst
"function: fillListConst
author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list, a type value an a start place and store all elements
  of the list in a list of tuples (element,type,place)"
  input list<list<Type_a>> inTypeALst;
  input Integer inType;
  input list< tuple<Type_a,Integer,Integer> > inAcc;
  output list< tuple<Type_a,Integer,Integer> > outlist;
  replaceable type Type_a subtypeof Any;
algorithm
  outlist := match (inTypeALst,inType,inAcc)
    local
      list<list<Type_a>> rest;
      list<Type_a> item;
      Integer value,place;
      list< tuple<Type_a,Integer,Integer> > out_lst,val_lst,acc;
    case ({},value,acc) then acc;
    case (item::rest,value,acc)
      equation
        /* recursive */
        acc = fillListConst(item,value,0,acc);
      then fillListListConst(rest,value+1,acc);
  end match;
end fillListListConst;

protected function getListConst
"function: getListConst
  author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list of tuples (element,type,place) and a type value
  and pitch on all elements with the same type value.
  The output is a list of tuples (element,place)."
  input list< tuple<Type_a,Integer,Integer> > inTypeALst;
  input Integer inValue;
  output list<tuple<Type_a,Integer>> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst :=
  match (inTypeALst,inValue)
    local
      list<tuple<Type_a,Integer,Integer>> rest;
      Type_a item;
      Integer value, itemvalue,place;
      list<tuple<Type_a,Integer>> out_lst,val_lst,val_lst1;
    case ({},value) then {};
    case ((item,itemvalue,place)::rest,value)
      equation
        /* recursive */
        val_lst = getListConst(rest,value);
        /* fill  */
        val_lst1 = Util.if_(itemvalue == value,{(item,place)},{});
        out_lst = listAppend(val_lst1,val_lst);
      then
        out_lst;
  end match;
end getListConst;

protected function sortList
"function: sortList
  author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list of tuples (element,place)and generate a
  list of elements with the order given by the place value."
  input list< tuple<Type_a,Integer> > inTypeALst;
  input Integer inPlace;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst := matchcontinue (inTypeALst,inPlace)
    local
      list<tuple<Type_a,Integer>> itemlst,rest;
      Type_a outitem;
      Integer place;
      list<Type_a> out_lst,val_lst;
    case ({},place) then {};
    case (itemlst,place)
      equation
        /* get item */
        (outitem,rest) = sortList1(itemlst,place);
        /* recursive */
        val_lst = sortList(rest,place+1);
        /* append  */
        out_lst = listAppend({outitem},val_lst);
      then
        out_lst;
  end matchcontinue;
end sortList;

protected function sortList1
"function: sortList1
  author: Frenkel TUD
  Helper function for sortList"
  input list< tuple<Type_a,Integer> > inTypeALst;
  input Integer inPlace;
  output Type_a outType;
  output list< tuple<Type_a,Integer> > outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  (outType,outTypeALst) :=
  matchcontinue (inTypeALst,inPlace)
    local
      list<tuple<Type_a,Integer>> rest,out_itemlst;
      Type_a item;
      Integer place,itemplace;
      Type_a out_item;
    case ({},_)
      equation
        print("- BackendVariable.sortList1 failed\n");
      then
        fail();
    case ((item,itemplace)::rest,place)
      equation
        /* compare */
        (place == itemplace) = true;
        /* ok */
        then
          (item,rest);
    case ((item,itemplace)::rest,place)
      equation
        /* recursive */
        (out_item,out_itemlst) = sortList1(rest,place);
      then
        (out_item,(item,itemplace)::out_itemlst);
  end matchcontinue;
end sortList1;

protected function getNoScalarVars
"function: getNoScalarVars
  author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a List of variables and seperate them
  in two lists. One for scalars and one for non scalars"
  input list< tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outnoScalarlist;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outScalarlist;
algorithm
  (outnoScalarlist,outScalarlist) := matchcontinue (inlist)
    local
      list< tuple<BackendDAE.Var,Integer,Integer> > noScalarlst,scalarlst,rest,noScalarlst1,scalarlst1,noScalarlst2,scalarlst2;
      BackendDAE.Var var;
      Integer typ,place;
    case {} then ({},{});
    case ((var,typ,place) :: rest)
      equation
        /* recursive */
        (noScalarlst,scalarlst) = getNoScalarVars(rest);
        /* check  */
        (noScalarlst1,scalarlst1) = checkVarisNoScalar(var,typ,place);
        noScalarlst2 = listAppend(noScalarlst1,noScalarlst);
        scalarlst2 = listAppend(scalarlst1,scalarlst);
      then
        (noScalarlst2,scalarlst2);
    case (_)
      equation
        print("- BackendVariable.getNoScalarVars fails\n");
      then
        fail();
  end matchcontinue;
end getNoScalarVars;

protected function checkVarisNoScalar
"function: checkVarisNoScalar
  author: Frenkel TUD
  Helper function for getNoScalarVars.
  Take a variable and push them in a list
  for scalars ore non scalars"
  input BackendDAE.Var invar;
  input Integer inTyp;
  input Integer inPlace;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outlist;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outlist1;
algorithm
  (outlist,outlist1) :=
  matchcontinue (invar,inTyp,inPlace)
    local
      DAE.InstDims dimlist;
      BackendDAE.Var var;
      Integer typ,place;
    case (var as (BackendDAE.VAR(arryDim = {})),typ,place) then ({},{(var,typ,place)});
    case (var as (BackendDAE.VAR(arryDim = dimlist)),typ,place) then ({(var,typ,place)},{});
  end matchcontinue;
end checkVarisNoScalar;

protected function getAllElements
"function: getAllElements
  author: Frenkel TUD
  Takes a list of unsortet noScalarVars
  and returns a sorted list"
  input list<tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist;
algorithm
  outlist:=
  match (inlist)
    local
      list<tuple<BackendDAE.Var,Integer,Integer>> rest,var_lst,var_lst1,var_lst2,out_lst;
      BackendDAE.Var var;
      Integer typ,place;
    case {} then {};
    case ((var,typ,place) :: rest)
      equation
        (var_lst,var_lst1) = getAllElements1((var,typ,place),rest);
        var_lst2 = getAllElements(var_lst1);
        out_lst = listAppend(var_lst,var_lst2);
      then
        out_lst;
  end match;
end getAllElements;

protected function getAllElements1
"function: getAllElements1
  author: Frenkel TUD
  Helper function for getAllElements."
  input tuple<BackendDAE.Var,Integer,Integer>  inVar;
  input list<tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist1;
algorithm
  (outlist,outlist1) := match (inVar,inlist)
    local
      list<tuple<BackendDAE.Var,Integer,Integer>> rest,var_lst,var_lst1,var_lst2,var_lst3;
      DAE.ComponentRef varName1, varName2,c2,c1;
      BackendDAE.Var var1,var2;
      Boolean ins;
      Integer typ1,typ2,place1,place2;
    case ((var1,typ1,place1),{}) then ({(var1,typ1,place1)},{});
    case ((var1 as BackendDAE.VAR(varName = varName1), typ1, place1), (var2 as BackendDAE.VAR(varName = varName2), typ2, place2) :: rest)
      equation
        (var_lst, var_lst1) = getAllElements1((var1, typ1, place1), rest);
        c1 = ComponentReference.crefStripLastSubs(varName1);
        c2 = ComponentReference.crefStripLastSubs(varName2);
        ins = ComponentReference.crefEqualNoStringCompare(c1, c2);
        var_lst2 = listAppendTyp(ins, (var2, typ2, place2), var_lst);
        var_lst3 = listAppendTyp(boolNot(ins), (var2, typ2, place2), var_lst1);
      then
        (var_lst2, var_lst3);
  end match;
end getAllElements1;

protected function sortNoScalarList
"function: sortNoScalarList
  author: Frenkel TUD
  Takes a list of unsortet noScalarVars
  and returns a sorted list"
  input list<tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist;
algorithm
  outlist:=
  match (inlist)
    local
      list<tuple<BackendDAE.Var,Integer,Integer>> rest,var_lst,var_lst1,out_lst;
      BackendDAE.Var var;
      Boolean ins;
      Integer typ,place;
    case {} then {};
    case ((var,typ,place) :: rest)
      equation
        var_lst = sortNoScalarList(rest);
        (var_lst1,ins) = sortNoScalarList1((var,typ,place),var_lst);
        out_lst = listAppendTyp(boolNot(ins),(var,typ,place),var_lst1);
      then
        out_lst;
  end match;
end sortNoScalarList;

protected function listAppendTyp
"function: listAppendTyp
  author: Frenkel TUD
  Takes a list of unsortet noScalarVars
  and returns a sorted list"
  input Boolean append;
  input Type_a  invar;
  input list<Type_a > inlist;
  output list<Type_a > outlist;
  replaceable type Type_a subtypeof Any;
algorithm
  (outlist) := match (append,invar,inlist)
    local
      list<Type_a> var_lst, out_lst;
      Type_a var;

    case (false,_,var_lst) then var_lst;
    
    case (true,var,var_lst)
      equation
        out_lst = var::var_lst;
      then
        out_lst;
  end match;
end listAppendTyp;

protected function sortNoScalarList1
"function: sortNoScalarList1
  author: Frenkel TUD
  Helper function for sortNoScalarList"
  input tuple<BackendDAE.Var,Integer,Integer>  invar;
  input list<tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist;
  output Boolean insert;
algorithm
  (outlist,insert) := match (invar,inlist)
    local
      list<tuple<BackendDAE.Var,Integer,Integer>> rest,var_lst,var_lst1;
      BackendDAE.Var var,var1;
      Boolean ins,ins1;
      Integer typ,typ1,place,place1;
    
    case (_,{}) then ({},false);
    
    case ((var,typ,place),(var1,typ1,place1)::rest)
      equation
        (var_lst,ins) = sortNoScalarList1((var,typ,place),rest);
        (var_lst1,ins1) = sortNoScalarList2(ins,(var,typ,place),(var1,typ1,place1),var_lst);
      then
        (var_lst1,ins1);
  end match;
end sortNoScalarList1;

protected function sortNoScalarList2
"function: sortNoScalarList2
  author: Frenkel TUD
  Helper function for sortNoScalarList
  Takes a list of unsortet noScalarVars
  and returns a sorte list"
  input Boolean ininsert;
  input tuple<BackendDAE.Var,Integer,Integer>  invar;
  input tuple<BackendDAE.Var,Integer,Integer>  invar1;
  input list< tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outlist;
  output Boolean outinsert;
algorithm
  (outlist,outinsert):=
  match (ininsert,invar,invar1,inlist)
    local
      list< tuple<BackendDAE.Var,Integer,Integer> > var_lst,var_lst1,var_lst2;
      BackendDAE.Var var,var1;
      Integer typ,typ1,place,place1;
      Boolean ins;
    case (false,(var,typ,place),(var1,typ1,place1),var_lst)
      equation
        ins = comparingNonScalars(var,var1);
        var_lst1 = Util.if_(ins,{(var1,typ1,place1),(var,typ,place)},{(var1,typ1,place1)});
        var_lst2 = listAppend(var_lst1,var_lst);
      then
        (var_lst2,ins);
    case (true,(var,typ,place),(var1,typ1,place1),var_lst)
      equation
        var_lst1 = listAppend({(var1,typ1,place1)},var_lst);
      then
        (var_lst1,true);
  end match;
end sortNoScalarList2;

protected function comparingNonScalars
"function: comparingNonScalars
  author: Frenkel TUD
  Helper function for sortNoScalarList2
  Takes two NonScalars an returns
  it in right order
  Example1:  A[2,2],A[1,1] -> {A[1,1],A[2,2]}
  Example2:  A[2,2],B[1,1] -> {A[2,2],B[1,1]}"
  input BackendDAE.Var invar1;
  input BackendDAE.Var invar2;
  output Boolean outval;
algorithm
  outval:=
  matchcontinue (invar1,invar2)
    local
      DAE.ComponentRef varName1, varName2,c1,c2;
      list<DAE.Subscript> arryDim, arryDim1;
      list<DAE.Subscript> subscriptLst, subscriptLst1;
      Boolean out_val;
    case (BackendDAE.VAR(varName = varName1,arryDim = arryDim),BackendDAE.VAR(varName = varName2,arryDim = arryDim1))
      equation
        c1 = ComponentReference.crefStripLastSubs(varName1);
        c2 = ComponentReference.crefStripLastSubs(varName2);
        true = ComponentReference.crefEqualNoStringCompare(c1, c2);
        subscriptLst = ComponentReference.crefLastSubs(varName1);
        subscriptLst1 = ComponentReference.crefLastSubs(varName2);
        out_val = comparingNonScalars1(subscriptLst,subscriptLst1,arryDim,arryDim1);
      then
        out_val;
    case (_,_) then false;
  end matchcontinue;
end comparingNonScalars;

protected function comparingNonScalars1
"function: comparingNonScalars1
  author: Frenkel TUD
  Helper function for comparingNonScalars.
  Check if a element of a non scalar has his place
  before or after another element in a one
  dimensional array."
  input list<DAE.Subscript> inlist;
  input list<DAE.Subscript> inlist1;
  input list<DAE.Subscript> inarryDim;
  input list<DAE.Subscript> inarryDim1;
  output Boolean outval;
algorithm
  outval:=
  matchcontinue (inlist, inlist1, inarryDim, inarryDim1)
    local
      list<DAE.Subscript> arryDim, arryDim1;
      list<DAE.Subscript> subscriptLst, subscriptLst1;
      list<Integer> dim_lst,dim_lst1,dim_lst_1,dim_lst1_1;
      list<Integer> index,index1;
      Integer val1,val2;
    case (subscriptLst,subscriptLst1,arryDim,arryDim1)
      equation
        dim_lst = getArrayDim(arryDim);
        dim_lst1 = getArrayDim(arryDim1);
        index = getArrayDim(subscriptLst);
        index1 = getArrayDim(subscriptLst1);
        dim_lst_1 = List.stripFirst(dim_lst);
        dim_lst1_1 = List.stripFirst(dim_lst1);
        val1 = calcPlace(index,dim_lst_1);
        val2 = calcPlace(index1,dim_lst1_1);
        (val1 > val2) = true;
      then
       true;
    case (_,_,_,_) then false;
  end matchcontinue;
end comparingNonScalars1;

protected function calcPlace
"function: calcPlace
  author: Frenkel TUD
  Helper function for comparingNonScalars1.
  Calculate based on the dimensions and the
  indexes the place of the element in a one
  dimensional array."
  input list<Integer> inindex;
  input list<Integer> dimlist;
  output Integer value;
algorithm
  value:=
  matchcontinue (inindex,dimlist)
    local
      list<Integer> index_lst,dim_lst;
      Integer value1,index,dim;
    case ({},{}) then 0;
    case (index::{},_) then index;
    case (index::index_lst,dim::dim_lst)
      equation
        value = calcPlace(index_lst,dim_lst);
        value1 = value + (index*dim);
      then
        value1;
     case (_,_)
      equation
        print("- BackendVariable.calcPlace failed\n");
      then
        fail();
  end matchcontinue;
end calcPlace;

protected function getArrayDim
"function: getArrayDim
  author: Frenkel TUD
  Helper function for comparingNonScalars1.
  Return the dimension of an array in a list."
  input list<DAE.Subscript> inarryDim;
  output list<Integer> dimlist;
algorithm
  dimlist:=
  match (inarryDim)
    local
      list<DAE.Subscript> rest;
      DAE.Subscript arryDim;
      list<Integer> dim_lst,dim_lst1;
      Integer dim;
    case {} then {};
    case ((arryDim as DAE.INDEX(DAE.ICONST(dim)))::rest)
      equation
        dim_lst = getArrayDim(rest);
        dim_lst1 = dim::dim_lst;
      then
        dim_lst1;
  end match;
end getArrayDim;

protected function calculateIndexes2
"function: calculateIndexes2
  author: PA
  Helper function to calculateIndexes"
  input list< tuple<BackendDAE.Var,Integer,Integer> > inVarLst1;
  input Integer inInteger2; //X
  input Integer inInteger3; //xd
  input Integer inInteger4; //y
  input Integer inInteger5; //p
  input Integer inInteger6; //dummy
  input Integer inInteger7; //ext

  input Integer inInteger8; //X_str
  input Integer inInteger9; //xd_str
  input Integer inInteger10; //y_str
  input Integer inInteger11; //p_str
  input Integer inInteger12; //dummy_str
  input list<tuple<BackendDAE.Var,Integer,Integer> > inAcc;

  output list<tuple<BackendDAE.Var,Integer,Integer> > outVarLst1;
  output Integer outInteger2;
  output Integer outInteger3;
  output Integer outInteger4;
  output Integer outInteger5;
  output Integer outInteger6;
  output Integer outInteger7;

  output Integer outInteger8; //x_str
  output Integer outInteger9; //xd_str
  output Integer outInteger10; //y_str
  output Integer outInteger11; //p_str
  output Integer outInteger12; //dummy_str
algorithm
  (outVarLst1,outInteger2,outInteger3,outInteger4,outInteger5,outInteger6,outInteger7,outInteger8,outInteger9,outInteger10,outInteger11,outInteger12):=
  match (inVarLst1,inInteger2,inInteger3,inInteger4,inInteger5,inInteger6,inInteger7,inInteger8,inInteger9,inInteger10,inInteger11,inInteger12,inAcc)
    local
      BackendDAE.Value x,xd,y,p,dummy,y_1,x1,xd1,y1,p1,dummy1,x_1,p_1,ext,ext1,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType,y_1_strType,x_1_strType,p_1_strType;
      BackendDAE.Value x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1;
      list< tuple<BackendDAE.Var,Integer,Integer> > vars_1,vs,acc;
      DAE.ComponentRef cr;
      DAE.VarDirection d;
      BackendDAE.Type tp;
      Option<DAE.Exp> b;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Integer typ,place;
      Absyn.Path path;
      tuple<BackendDAE.Var,Integer,Integer> fst;
    
    case ({},x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      then (listReverse(acc),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.VARIABLE(),
               varDirection = d,
               varType = tp as DAE.T_STRING(source = _),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        y_1_strType = y_strType + 1;
        fst = (BackendDAE.VAR(cr,BackendDAE.VARIABLE(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.VARIABLE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place)::vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        y_1 = y + 1;
        fst = (BackendDAE.VAR(cr,BackendDAE.VARIABLE(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.STATE(),
               varDirection = d,
               varType = tp as DAE.T_STRING(source = _),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place)::vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        x_1_strType = x_strType + 1;
        fst = (BackendDAE.VAR(cr,BackendDAE.STATE(),d,tp,b,value,dim,x_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_1_strType,xd_strType,y_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.STATE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        x_1 = x + 1;
        fst = (BackendDAE.VAR(cr,BackendDAE.STATE(),d,tp,b,value,dim,x,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x_1, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DUMMY_DER(),
               varDirection = d,
               varType = tp as DAE.T_STRING(source = _),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        y_1_strType = y_strType + 1 "Dummy derivatives become algebraic variables" ;
        fst = (BackendDAE.VAR(cr,BackendDAE.DUMMY_DER(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DUMMY_DER(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        y_1 = y + 1 "Dummy derivatives become algebraic variables" ;
        fst = (BackendDAE.VAR(cr,BackendDAE.DUMMY_DER(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DUMMY_STATE(),
               varDirection = d,
               varType = tp as DAE.T_STRING(source = _),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        y_1_strType = y_strType + 1 "Dummy state become algebraic variables" ;
        fst = (BackendDAE.VAR(cr,BackendDAE.DUMMY_STATE(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DUMMY_STATE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        y_1 = y + 1 "Dummy state become algebraic variables" ;
        fst = (BackendDAE.VAR(cr,BackendDAE.DUMMY_STATE(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DISCRETE(),
               varDirection = d,
               varType = tp as DAE.T_STRING(source = _),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        y_1_strType = y_strType + 1;
        fst = (BackendDAE.VAR(cr,BackendDAE.DISCRETE(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DISCRETE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        y_1 = y + 1;
        fst = (BackendDAE.VAR(cr,BackendDAE.DISCRETE(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.PARAM(),
               varDirection = d,
               varType = tp as DAE.T_STRING(source = _),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        p_1_strType = p_strType + 1;
        fst = (BackendDAE.VAR(cr,BackendDAE.PARAM(),d,tp,b,value,dim,p_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_1_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.PARAM(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        p_1 = p + 1;
        fst = (BackendDAE.VAR(cr,BackendDAE.PARAM(),d,tp,b,value,dim,p,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p_1, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.CONST(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
         //IS THIS A BUG??
         // THE INDEX FOR const IS SET TO p (=last parameter index)
        fst = (BackendDAE.VAR(cr,BackendDAE.CONST(),d,tp,b,value,dim,p,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.EXTOBJ(path),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType,acc)
      equation
        ext_1 = ext+1;
        fst = (BackendDAE.VAR(cr,BackendDAE.EXTOBJ(path),d,tp,b,value,dim,ext,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place);
        (acc,x1,xd1,y1,p1,dummy,ext1,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType,fst::acc);
      then
        (acc,x1,xd1,y1,p1,dummy,ext1,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
  end match;
end calculateIndexes2;

public function equationSystemsVarsLst
  input BackendDAE.EqSystems systs;
  input list<BackendDAE.Var> inVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := match (systs,inVars)
    local
      BackendDAE.EqSystems rest;
      list<BackendDAE.Var> vars,systvars,vars1;
      BackendDAE.Variables v;
      case ({},_) then inVars;
      case (BackendDAE.EQSYSTEM(orderedVars = v)::rest,_)
        equation
          vars = BackendDAEUtil.varList(v);
          vars1 = listAppend(inVars,vars);
        then
          equationSystemsVarsLst(rest,vars1);
    end match;
end equationSystemsVarsLst;


public function daeVars
  input BackendDAE.EqSystem syst;
  output BackendDAE.Variables vars;
algorithm
  BackendDAE.EQSYSTEM(orderedVars = vars) := syst;
end daeVars;

public function daeKnVars
  input BackendDAE.Shared shared;
  output BackendDAE.Variables vars;
algorithm
  BackendDAE.SHARED(knownVars = vars) := shared;
end daeKnVars;

public function daeAliasVars
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.Variables vars;
algorithm
  vars := match (inBackendDAE)
    local BackendDAE.Variables vars;
    case (BackendDAE.DAE(shared=BackendDAE.SHARED(aliasVars = BackendDAE.ALIASVARS(aliasVars = vars))))
      then vars;
  end match;
end daeAliasVars;

public function varsSize "function: varsSize
  author: PA

  Returns the number of variables
"
  input BackendDAE.Variables inVariables;
  output Integer outInteger;
algorithm
  outInteger:=
  match (inVariables)
    local BackendDAE.Value n;
    case (BackendDAE.VARIABLES(numberOfVars = n)) then n;
  end match;
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
      BackendDAE.VarKind kind;
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varKind = kind) :: _),_) = getVar(cr, vars);
        isVarKindVariable(kind);
      then
        ();
    case (cr,_,knvars)
      equation
        ((BackendDAE.VAR(varKind = kind) :: _),_) = getVar(cr, knvars);
        isVarKindVariable(kind);
      then
        ();
  end matchcontinue;
end isVariable;

public function isVarKindVariable
"function: isVarKindVariable

  This function takes a DAE.ComponentRef and two Variables. It searches
  the two sets of variables and succeed if the variable is STATE or
  VARIABLE. Otherwise it fails.
  Note: An array variable is currently assumed that each scalar element has
  the same type.
  inputs:  (DAE.ComponentRef,
              Variables, /* vars */
              Variables) /* known vars */
  outputs: ()"
  input BackendDAE.VarKind inVarKind;
algorithm
  _:=
  match (inVarKind)
    case (BackendDAE.VARIABLE()) then ();
    case (BackendDAE.STATE()) then ();
    case (BackendDAE.DUMMY_STATE()) then ();
    case (BackendDAE.DUMMY_DER()) then ();
    case (BackendDAE.DISCRETE()) then ();
  end match;
end isVarKindVariable;

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
  match (inVariables1,inVariables2,inBinTree3)
    local
      BackendDAE.Variables v1,vars,knvars,vars1,vars2;
      BackendDAE.BinTree mvars;
    case (vars1,vars2,mvars)
      equation
        v1 = BackendDAEUtil.emptyVars();
        ((vars,knvars,_)) = traverseBackendDAEVars(vars1,moveVariables2,(v1,vars2,mvars));
      then
        (vars,knvars);
  end match;
end moveVariables;

protected function moveVariables2
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, tuple<BackendDAE.Variables,BackendDAE.Variables,BackendDAE.BinTree>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendDAE.Variables,BackendDAE.Variables,BackendDAE.BinTree>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      BackendDAE.Variables vars1,vars2,newvars;
      BackendDAE.BinTree mvars;
      DAE.ComponentRef cr;
    case ((v as BackendDAE.VAR(varName = cr),(vars1,vars2,mvars)))
      equation
        _ = BackendDAEUtil.treeGet(mvars, cr) "alg var moved to known vars" ;
        newvars = addVar(v,vars2);
      then
        ((v,(vars1,newvars,mvars)));
    case ((v as BackendDAE.VAR(varName = cr),(vars1,vars2,mvars)))
      equation
        failure(_ = BackendDAEUtil.treeGet(mvars, cr)) "alg var not moved to known vars" ;
        newvars = addVar(v,vars1);
      then
        ((v,(newvars,vars2,mvars)));
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

public function deleteCrefs
"function: deleteCrefs
  author: wbraun
  Deletes a list of DAE.ComponentRef from BackendDAE.Variables"
  input list<DAE.ComponentRef> varlst;
  input BackendDAE.Variables vars;
  output BackendDAE.Variables vars_1;
algorithm
  vars_1 := List.fold(varlst, deleteVar, vars);
end deleteCrefs;

public function deleteVars
"function: deleteVars
  author: Frenkel TUD 2011-04
  Deletes variables from Variables. This is an expensive operation
  since we need to create a new binary tree with new indexes as well
  as a new compacted vector of variables."
  input BackendDAE.BinTree inVars;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVars,inVariables)
    local
      BackendDAE.Variables v,newvars,newvars_1;
      BackendDAE.BinTree vars;
    case (vars,v)
      equation
        newvars = BackendDAEUtil.emptyVars();
        ((_,newvars_1)) = traverseBackendDAEVars(v,deleteVars2,(vars,newvars));
      then
        newvars_1;
  end matchcontinue;
end deleteVars;

protected function deleteVars2
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, tuple<BackendDAE.BinTree,BackendDAE.Variables>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendDAE.BinTree,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      BackendDAE.Variables vars,vars1;
      BackendDAE.BinTree delvars;
      DAE.ComponentRef cr;
    case ((v as BackendDAE.VAR(varName = cr),(delvars,vars)))
      equation
        _ = BackendDAEUtil.treeGet(delvars, cr) "alg var deleted" ;
      then
        ((v,(delvars,vars)));
    case ((v as BackendDAE.VAR(varName = cr),(delvars,vars)))
      equation
        failure(_ = BackendDAEUtil.treeGet(delvars, cr)) "alg var not deleted" ;
        vars1 = addVar(v,vars);
      then
        ((v,(delvars,vars1)));
  end matchcontinue;
end deleteVars2;

public function deleteVar
"function: deleteVar
  author: PA
  Deletes a variable from Variables."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inComponentRef,inVariables)
    local
      BackendDAE.Variables v,newvars,newvars_1;
      DAE.ComponentRef cr;
    case (cr,v)
      equation
        newvars = BackendDAEUtil.emptyVars();
        ((_,newvars_1)) = traverseBackendDAEVars(v,deleteVar2,(cr,newvars));
      then
        newvars_1;
  end matchcontinue;
end deleteVar;

protected function deleteVar2
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, tuple<DAE.ComponentRef,BackendDAE.Variables>> inTpl;
 output tuple<BackendDAE.Var, tuple<DAE.ComponentRef,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr,dcr;
    case ((v as BackendDAE.VAR(varName = cr),(dcr,vars)))
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, dcr);
      then
        ((v,(dcr,vars)));
    case ((v as BackendDAE.VAR(varName = cr),(dcr,vars)))
      equation
        vars1 = addVar(v,vars);
      then
        ((v,(dcr,vars1)));
  end matchcontinue;
end deleteVar2;

public function removeVar
"function: removeVar
  author: Frenkel TUD 2011-04
  Removes a var from the vararray but does not scaling down the array"
  input Integer inVarPos;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
  output BackendDAE.Var outVar;
algorithm
  (outVariables,outVar):=
  matchcontinue (inVarPos,inVariables)
    local
      Integer pos,pos_1;
      BackendDAE.Value hval,hashindx,indx,bsize,n,hvalold,indxold;
      list<BackendDAE.CrefIndex> indexes,indexes1;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      array<list<BackendDAE.CrefIndex>> hashvec,hashvec_1;
      BackendDAE.VariableArray varr,varr1;
      String name_str;
    case (pos,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        (v as BackendDAE.VAR(varName = cr),varr1) = removeVar1(varr, pos);
        pos_1 = pos-1;
        hashindx = HashTable2.hashFunc(cr, bsize);
        indexes = hashvec[hashindx + 1];
        (indexes1,_) = List.deleteMemberOnTrue(BackendDAE.CREFINDEX(cr,pos_1),indexes,removeVar2);
        hashvec_1 = arrayUpdate(hashvec, hashindx + 1, indexes1);
      then
        (BackendDAE.VARIABLES(hashvec_1,varr1,bsize,n),v);
    case (pos,_)
      equation
        print("- BackendVariable.removeVar failed for var ");
        print(intString(pos));
        print("\n");
      then
        fail();
  end matchcontinue;
end removeVar;

protected function removeVar1
"function: removeVar1
  author: Frenkel TUD
  Helper for removeVar"
  input BackendDAE.VariableArray inVariableArray;
  input Integer inInteger;
  output BackendDAE.Var outVar;
  output BackendDAE.VariableArray outVariableArray;
algorithm
  (outVar,outVariableArray) := matchcontinue (inVariableArray,inInteger)
    local
      array<Option<BackendDAE.Var>> arr_1,arr;
      BackendDAE.Value n,size,pos;
      BackendDAE.Var v;

    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),pos)
      equation
        (pos < size) = true;
        SOME(v) = arr[pos];
        arr_1 = arrayUpdate(arr, pos, NONE());
      then
        (v,BackendDAE.VARIABLE_ARRAY(n,size,arr_1));
    case (_,_)
      equation
        print("- BackendVariable.removeVar1 failed\n");
      then
        fail();
  end matchcontinue;
end removeVar1;

protected function removeVar2
"Helper function to getVar"
  input BackendDAE.CrefIndex cri1;
  input BackendDAE.CrefIndex cri2;
  output Boolean matches;
algorithm
  matches := match (cri1,cri2)
    local
      Integer i1,i2;
    case (BackendDAE.CREFINDEX(index = i1),BackendDAE.CREFINDEX(index = i2))
      then intEq(i1,i2);
  end match;
end removeVar2;

public function existsVar
"function: existsVar
  author: PA
  Return true if a variable exists in the vector"
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  input Boolean skipDiscrete;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef,inVariables,skipDiscrete)
    local
      BackendDAE.Value hval,hashindx,indx,bsize,n;
      list<BackendDAE.CrefIndex> indexes;
      BackendDAE.Var v;
      DAE.ComponentRef cr2,cr;
      array<list<BackendDAE.CrefIndex>> hashvec;
      BackendDAE.VariableArray varr;
      String str;
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n),false)
      equation
        hashindx = HashTable2.hashFunc(cr, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes, getVar4(cr, indexes));
        ((v as BackendDAE.VAR(varName = cr2))) = vararrayNth(varr, indx);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      then
        true;
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n),true)
      equation
        hashindx = HashTable2.hashFunc(cr, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes, getVar4(cr, indexes));
        ((v as BackendDAE.VAR(varName = cr2))) = vararrayNth(varr, indx);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        false = isVarDiscrete(v);
      then
        true;        
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n),_)
      equation
        hashindx = HashTable2.hashFunc(cr, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes, getVar4(cr, indexes));
        failure((_) = vararrayNth(varr, indx));
        print("- BackendVariable.existsVar could not found variable, cr:");
        str = ComponentReference.printComponentRefStr(cr);
        print(str);
        print("\n");
      then
        false;
    case (_,_,_) then false;
  end matchcontinue;
end existsVar;

public function addVarDAE
"function: addVarDAE
  author: Frenkel TUD 2011-04
  Add a variable to Variables of a BackendDAE.
  If the variable already exists, the function updates the variable."
  input BackendDAE.Var inVar;
  input BackendDAE.EqSystem syst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (inVar,syst)
    local
      BackendDAE.Var var;
      BackendDAE.Variables ordvars,knvars,exobj,ordvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.Shared shared;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Matching matching;
    case (var,BackendDAE.EQSYSTEM(ordvars,eqns,m,mT,matching))
      equation
        ordvars1 = addVar(var,ordvars);
      then BackendDAE.EQSYSTEM(ordvars1,eqns,m,mT,matching);
  end match;
end addVarDAE;

public function addKnVarDAE
"function: addKnVarDAE
  author: Frenkel TUD 2011-04
  Add a variable to Variables of a BackendDAE.
  If the variable already exists, the function updates the variable."
  input BackendDAE.Var inVar;
  input BackendDAE.Shared shared;
  output BackendDAE.Shared oshared;
algorithm
  oshared := match (inVar,shared)
    local
      BackendDAE.Var var;
      BackendDAE.Variables ordvars,knvars,exobj,knvars1;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      array<BackendDAE.ComplexEquation> complEqs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.EqSystems eqs;
      BackendDAE.BackendDAEType btp;
    case (var,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,arreqns,algorithms,complEqs,einfo,eoc,btp))
      equation
        knvars1 = addVar(var,knvars);
      then BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,arreqns,algorithms,complEqs,einfo,eoc,btp);
  end match;
end addKnVarDAE;

public function addVars "function: addVars
  author: PA
  Adds a list of BackendDAE.Var to BackendDAE.Variables"
  input list<BackendDAE.Var> varlst;
  input BackendDAE.Variables vars;
  output BackendDAE.Variables vars_1;
algorithm
  vars_1 := List.fold(varlst, addVar, vars);
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
      BackendDAE.Var v,newv;
      DAE.ComponentRef cr;
      DAE.Flow flowPrefix;
      BackendDAE.Variables vars;
    /* adrpo: ignore records!
    case ((v as BackendDAE.VAR(varName = cr,origVarName = name,flowPrefix = flowPrefix, varType = DAE.COMPLEX(_,_))),
          (vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
    then
      vars;
    */
    case ((v as BackendDAE.VAR(varName = cr,flowPrefix = flowPrefix)),(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        failure((_,_) = getVar(cr, vars));
        // print("adding when not existing previously\n");
        indx = HashTable2.hashFunc(cr, bsize);
        newpos = vararrayLength(varr);
        varr_1 = vararrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, (BackendDAE.CREFINDEX(cr,newpos) :: indexes));
        n_1 = vararrayLength(varr_1);
      then
        BackendDAE.VARIABLES(hashvec_1,varr_1,bsize,n_1);

    case ((newv as BackendDAE.VAR(varName = cr,flowPrefix = flowPrefix)),(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        (_,{indx}) = getVar(cr, vars);
        // print("adding when already present => Updating value\n");
        indx_1 = indx - 1;
        varr_1 = vararraySetnth(varr, indx_1, newv);
      then
        BackendDAE.VARIABLES(hashvec,varr_1,bsize,n);

    case (_,_)
      equation
        print("- BackendVariable.addVar failed\n");
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
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "getVarAt failed to get the variable at index:" +& intString(n));
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
    case (cr,vars) /* check if record */
      equation
        (vLst,indxs) = getRecordVar(cr, vars);
      then
        (vLst,indxs);
    /* failure
    case (cr,vars)
      equation
        Debug.fprintln(Flags.DAE_LOW, "- getVar failed on component reference: " +& ComponentReference.printComponentRefStr(cr));
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
  (outVar,outInteger) := match (inComponentRef,inVariables)
    local
      BackendDAE.Value hval,hashindx,indx,indx_1,bsize,n;
      list<BackendDAE.CrefIndex> indexes;
      BackendDAE.Var v;
      DAE.ComponentRef cr2,cr;
      array<list<BackendDAE.CrefIndex>> hashvec;
      BackendDAE.VariableArray varr;
    
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        hashindx = HashTable2.hashFunc(cr, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes, getVar4(cr,indexes));
        ((v as BackendDAE.VAR(varName = cr2))) = vararrayNth(varr, indx);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        indx_1 = indx + 1;
      then
        (v,indx_1);
    
  end match;
end getVar2;

protected function getVar3
"Helper function to getVar"
  input DAE.ComponentRef cr;
  input list<BackendDAE.CrefIndex> ivs;
  input Boolean firstMatches;
  output Integer outInteger;
algorithm
  outInteger := match (cr,ivs,firstMatches)
    local
      BackendDAE.Value v; list<BackendDAE.CrefIndex> vs;
    case (cr,BackendDAE.CREFINDEX(index = v)::_,true) then v;
    case (cr,_::vs,false) then getVar3(cr,vs,getVar4(cr,vs));
  end match;
end getVar3;

protected function getVar4
"Helper function to getVar"
  input DAE.ComponentRef inComponentRef;
  input list<BackendDAE.CrefIndex> inCrefIndexLst;
  output Boolean firstMatches;
algorithm
  firstMatches := match (inComponentRef,inCrefIndexLst)
    local
      DAE.ComponentRef cr,cr2;
    case (cr,BackendDAE.CREFINDEX(cref = cr2)::_)
      then ComponentReference.crefEqualNoStringCompare(cr, cr2);
  end match;
end getVar4;

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
      BackendDAE.VariableArray varr;
    
    // one dimensional arrays
    case (cr,(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        cr_1 = ComponentReference.subscriptCref(cr, {DAE.INDEX(DAE.ICONST(1))});
        hashindx = HashTable2.hashFunc(cr_1, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr_1, indexes, getVar4(cr_1, indexes));
        ((v as BackendDAE.VAR(varName = cr2, arryDim = instdims, flowPrefix = flowPrefix))) = vararrayNth(varr, indx);
        true = ComponentReference.crefEqualNoStringCompare(cr_1, cr2);
        (vs,indxs) = getArrayVar2(instdims, cr, vars);
      then
        (vs,indxs);
    
    // two dimensional arrays
    case (cr,(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        cr_1 = ComponentReference.subscriptCref(cr, {DAE.INDEX(DAE.ICONST(1)),DAE.INDEX(DAE.ICONST(1))});
        hashindx = HashTable2.hashFunc(cr_1, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr_1, indexes, getVar4(cr_1, indexes));
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
        indx_lst = List.intRange(i1);
        indx_lstlst = List.map(indx_lst, List.create);
        subscripts_lstlst = List.map(indx_lstlst, Expression.intSubscripts);
        scalar_crs = List.map1r(subscripts_lstlst, ComponentReference.subscriptCref, arr_cr);
        (vs,indxs) = List.map1_2(scalar_crs, getVar, vars);
        vs_1 = List.flatten(vs);
        indxs_1 = List.flatten(indxs);
      then
        (vs_1,indxs_1);
    case ({DAE.INDEX(exp = DAE.ICONST(integer = i1)),DAE.INDEX(exp = DAE.ICONST(integer = i2))},arr_cr,vars)
      equation
        indx_lst1 = List.intRange(i1);
        indx_lstlst1 = List.map(indx_lst1, List.create);
        subscripts_lstlst1 = List.map(indx_lstlst1, Expression.intSubscripts);
        indx_lst2 = List.intRange(i2);
        indx_lstlst2 = List.map(indx_lst2, List.create);
        subscripts_lstlst2 = List.map(indx_lstlst2, Expression.intSubscripts);
        subscripts = BackendDAEUtil.subscript2dCombinations(subscripts_lstlst1, subscripts_lstlst2) "make all possbible combinations to get all 2d indexes" ;
        scalar_crs = List.map1r(subscripts, ComponentReference.subscriptCref, arr_cr);
        (vs,indxs) = List.map1_2(scalar_crs, getVar, vars);
        vs_1 = List.flatten(vs);
        indxs_1 = List.flatten(indxs);
      then
        (vs_1,indxs_1);
    // adrpo: cr can be of form cr.cr.cr[2].cr[3] which means that it has type dimension [2,3] but we only need to walk [3]
    case ({_,DAE.INDEX(exp = DAE.ICONST(integer = i1))},arr_cr,vars)
      equation
        // see if cr contains ANY array dimensions. if it doesn't this case is not valid!
        true = ComponentReference.crefHaveSubs(arr_cr);
        indx_lst = List.intRange(i1);
        indx_lstlst = List.map(indx_lst, List.create);
        subscripts_lstlst = List.map(indx_lstlst, Expression.intSubscripts);
        scalar_crs = List.map1r(subscripts_lstlst, ComponentReference.subscriptCref, arr_cr);
        (vs,indxs) = List.map1_2(scalar_crs, getVar, vars);
        vs_1 = List.flatten(vs);
        indxs_1 = List.flatten(indxs);
      then
        (vs_1,indxs_1);
  end matchcontinue;
end getArrayVar2;

protected function getRecordVar
"function: getRecordVar
  author: Frenkel TUD
  Helper function to get_var, checks one record variable.
  I.e. getrecord_var(v,<vars>) will for an record r(x,y) return
  { r.x,r.y}"
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := match (inComponentRef,inVariables)
    local
      DAE.ComponentRef cr;
      list<DAE.Var> varLst;
      list<DAE.ComponentRef> crefs,crefs1;
      list<list<BackendDAE.Var>> varslst;
      list<list<Integer>> ilstlst;
      list<BackendDAE.Var> vars;
      list<Integer> ilst;
    case (cr,inVariables)
      equation
        DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_)) = ComponentReference.crefTypeConsiderSubs(cr);
        crefs =  List.map(varLst,ComponentReference.creffromVar);
        crefs1 = List.map1r(crefs,ComponentReference.joinCrefs,cr);
        (varslst,ilstlst) = List.map1_2(crefs1,getVar,inVariables);
        vars = List.flatten(varslst);
        ilst = List.flatten(ilstlst);
      then
        (vars,ilst);
  end match;
end getRecordVar;

public function getVarIndexFromVariables
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inVariables2;
  output list<Integer> v_lst;
algorithm
  ((_,v_lst)) := traverseBackendDAEVars(inVariables,traversingisVarIndexVarFinder,(inVariables2,{}));
end getVarIndexFromVariables;

protected function traversingisVarIndexVarFinder
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, tuple<BackendDAE.Variables, list<Integer>>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendDAE.Variables, list<Integer>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      list<Integer> v_lst;
      DAE.ComponentRef cr;
      list<Integer> indxlst;
    case ((v,(vars,v_lst)))
      equation   
        cr = varCref(v);
       (_,indxlst) = getVar(cr, vars);
        v_lst = listAppend(v_lst,indxlst);
      then ((v,(vars,v_lst)));
    case inTpl then inTpl;
  end matchcontinue;
end traversingisVarIndexVarFinder;

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
        vars1_1 = List.fold(varlst, addVar, vars1);
      then
        vars1_1;
    case (_,_)
      equation
        print("- BackendVariable.mergeVariables failed\n");
      then
        fail();
  end matchcontinue;
end mergeVariables;

public function traverseBackendDAEVars "function: traverseBackendDAEVars
  author: Frenkel TUD

  traverse all vars of a BackenDAE.Variables array.
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Variables inVariables;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Var, Type_a> inTpl;
    output tuple<BackendDAE.Var, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA:=
  matchcontinue (inVariables,func,inTypeA)
    local
      array<Option<BackendDAE.Var>> varOptArr;
      Type_a ext_arg_1;
    case (BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr)),func,inTypeA)
      equation
        ext_arg_1 = BackendDAEUtil.traverseBackendDAEArrayNoCopy(varOptArr,func,traverseBackendDAEVar,1,arrayLength(varOptArr),inTypeA);
      then
        ext_arg_1;
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendVariable.traverseBackendDAEVars failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEVars;

protected function traverseBackendDAEVar "function: traverseBackendDAEVar
  author: Frenkel TUD
  Helper traverseBackendDAEVars."
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Var> inVar;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Var, Type_a> inTpl;
    output tuple<BackendDAE.Var, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA:=
  matchcontinue (inVar,func,inTypeA)
    local
      BackendDAE.Var v;
      Type_a ext_arg;
    case (NONE(),func,inTypeA) then inTypeA;
    case (SOME(v),func,inTypeA)
      equation
        ((_,ext_arg)) = func((v,inTypeA));
      then
        ext_arg;
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendVariable.traverseBackendDAEVar failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEVar;

public function traverseBackendDAEVarsWithUpdate "function: traverseBackendDAEVarsWithUpdate
  author: Frenkel TUD

  traverse all vars of a BackenDAE.Variables array.
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Variables inVariables;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.Variables outVariables;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Var, Type_a> inTpl;
    output tuple<BackendDAE.Var, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outVariables,outTypeA):=
  matchcontinue (inVariables,func,inTypeA)
    local
      array<list<BackendDAE.CrefIndex>> crefIdxLstArr;
      BackendDAE.VariableArray varArr;
      Integer bucketSize,numberOfVars,numberOfElements,arrSize;
      array<Option<BackendDAE.Var>> varOptArr,varOptArr1;
      Type_a ext_arg_1;
    case (BackendDAE.VARIABLES(crefIdxLstArr=crefIdxLstArr,varArr = BackendDAE.VARIABLE_ARRAY(numberOfElements=numberOfElements,arrSize=arrSize,varOptArr=varOptArr),bucketSize=bucketSize,numberOfVars=numberOfVars),func,inTypeA)
      equation
        (varOptArr1,ext_arg_1) = BackendDAEUtil.traverseBackendDAEArrayNoCopyWithUpdate(varOptArr,func,traverseBackendDAEVarWithUpdate,1,arrayLength(varOptArr),inTypeA);
      then
        (BackendDAE.VARIABLES(crefIdxLstArr,BackendDAE.VARIABLE_ARRAY(numberOfElements,arrSize,varOptArr1),bucketSize,numberOfVars),ext_arg_1);
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendVariable.traverseBackendDAEVarsWithUpdate failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEVarsWithUpdate;

protected function traverseBackendDAEVarWithUpdate "function: traverseBackendDAEVarWithUpdate
  author: Frenkel TUD
  Helper traverseBackendDAEVarsWithUpdate."
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Var> inVar;
  input FuncExpType func;
  input Type_a inTypeA;
  output Option<BackendDAE.Var> outVar;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Var, Type_a> inTpl;
    output tuple<BackendDAE.Var, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outVar,outTypeA):=
  matchcontinue (inVar,func,inTypeA)
    local
      Option<BackendDAE.Var> ovar;
      BackendDAE.Var v,v1;
      Type_a ext_arg;
    case (ovar as NONE(),func,inTypeA) then (ovar,inTypeA);
    case (ovar as SOME(v),func,inTypeA)
      equation
        ((v1,ext_arg)) = func((v,inTypeA));
        ovar = Util.if_(referenceEq(v,v1),ovar,SOME(v1));
      then
        (ovar,ext_arg);
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendVariable.traverseBackendDAEVar failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEVarWithUpdate;

public function getAllCrefFromVariables
  input BackendDAE.Variables inVariables;
  output list<DAE.ComponentRef> cr_lst;
algorithm
  cr_lst := traverseBackendDAEVars(inVariables,traversingVarCrefFinder,{});
end getAllCrefFromVariables;

protected function traversingVarCrefFinder
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, list<DAE.ComponentRef>> inTpl;
 output tuple<BackendDAE.Var, list<DAE.ComponentRef>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      list<DAE.ComponentRef> cr_lst;
      DAE.ComponentRef cr;
    case ((v,cr_lst))
      equation
        cr = varCref(v);
      then ((v,cr::cr_lst));
    case inTpl then inTpl;
  end matchcontinue;
end traversingVarCrefFinder;

public function getAllDiscreteVarFromVariables
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> v_lst;
algorithm
  v_lst := traverseBackendDAEVars(inVariables,traversingisisVarDiscreteFinder,{});
end getAllDiscreteVarFromVariables;

protected function traversingisisVarDiscreteFinder
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, list<BackendDAE.Var>> inTpl;
 output tuple<BackendDAE.Var, list<BackendDAE.Var>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> v_lst;
    case ((v,v_lst))
      equation
        true = BackendDAEUtil.isVarDiscrete(v);
      then ((v,v::v_lst));
    case inTpl then inTpl;
  end matchcontinue;
end traversingisisVarDiscreteFinder;

public function getAllStateVarFromVariables
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> v_lst;
algorithm
  v_lst := traverseBackendDAEVars(inVariables,traversingisStateVarFinder,{});
end getAllStateVarFromVariables;

protected function traversingisStateVarFinder
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, list<BackendDAE.Var>> inTpl;
 output tuple<BackendDAE.Var, list<BackendDAE.Var>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> v_lst;
    case ((v,v_lst))
      equation
        true = isStateVar(v);
      then ((v,v::v_lst));
    case inTpl then inTpl;
  end matchcontinue;
end traversingisStateVarFinder;

public function mergeVariableOperations
  input BackendDAE.Var var;
  input list<DAE.SymbolicOperation> iops;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (var,iops)
    local
      DAE.ComponentRef a;
      BackendDAE.VarKind b;
      DAE.VarDirection c;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      BackendDAE.Value i;
      DAE.ElementSource source;
      DAE.VariableAttributes attr;
      Option<DAE.VariableAttributes> oattr;
      Option<SCode.Comment> s;
      DAE.Flow t;
      DAE.Stream streamPrefix;
      Boolean fixed;
      list<DAE.SymbolicOperation> ops;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = oattr,
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),iops)
      equation
        ops = listReverse(iops);
        source = List.foldr(ops,DAEUtil.addSymbolicTransformation,source);
      then BackendDAE.VAR(a,b,c,d,e,f,g,i,source,oattr,s,t,streamPrefix);
  end match;
end mergeVariableOperations;

public function greater
  input BackendDAE.Var lhs;
  input BackendDAE.Var rhs;
  output Boolean greater;
algorithm
  greater := stringCompare(ComponentReference.printComponentRefStr(varCref(lhs)),ComponentReference.printComponentRefStr(varCref(rhs))) > 0;
end greater;

end BackendVariable;

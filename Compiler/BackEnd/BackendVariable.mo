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
public import Env;
public import Values;

protected import Absyn;
protected import BackendDAEUtil;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import HashTable2;
protected import List;
protected import SCode;
protected import Util;
protected import Types;

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
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      list<BackendDAE.Var> rest;
      Boolean res;
    case ({},var_name) then false;
    case (((variable as BackendDAE.VAR(varName = cr,values = dae_var_attr,comment = comment)) :: rest),var_name)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, var_name);
      then
        true;
    case (((variable as BackendDAE.VAR(varName = cr,values = dae_var_attr,comment = comment)) :: rest),var_name)
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



public function setVarFixed "function setVarFixed
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
      DAE.VarParallelism prl;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      DAE.ElementSource source;
      DAE.VariableAttributes attr;
      Option<DAE.VariableAttributes> oattr;
      Option<SCode.Comment> s;
      DAE.ConnectorType ct;
      Boolean fixed;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varParallelism = prl,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              source = source,
              values = SOME(attr),
              comment = s,
              connectorType = ct),fixed)
      equation
        oattr = DAEUtil.setFixedAttr(SOME(attr),SOME(DAE.BCONST(fixed)));
      then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr,s,ct);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varParallelism = prl,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              source = source,
              values = NONE(),
              comment = s,
              connectorType = ct),fixed)
      equation
        attr = getVariableAttributefromType(d);
        oattr = DAEUtil.setFixedAttr(SOME(attr),SOME(DAE.BCONST(fixed)));
      then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr,s,ct);


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
      DAE.VarParallelism prl;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      DAE.ElementSource source;
      DAE.VariableAttributes attr;
      Option<DAE.VariableAttributes> oattr1;
      Option<SCode.Comment> s;
      DAE.ConnectorType ct;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varParallelism = prl,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              source = source,
              values = SOME(attr),
              comment = s,
              connectorType = ct),_)
      equation
        oattr1 = DAEUtil.setStartAttr(SOME(attr),inExp);
    then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr1,s,ct);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varParallelism = prl,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              source = source,
              values = NONE(),
              comment = s,
              connectorType = ct),_)
      equation
        attr = getVariableAttributefromType(d);
        oattr1 = DAEUtil.setStartAttr(SOME(attr),inExp);
    then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr1,s,ct);
      
  end match;
end setVarStartValue;

public function setVarAttributes 
"sets the variable attributes of a variable.
author: Peter Aronsson (paronsson@wolfram.com)
"
  input BackendDAE.Var v;
  input Option<DAE.VariableAttributes> attr;
  output BackendDAE.Var outV;
algorithm
  outV := match(v,attr)
  local
     DAE.ComponentRef a;
      BackendDAE.VarKind b;
      DAE.VarDirection c;
      DAE.VarParallelism prl;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      DAE.ElementSource source;
      Option<SCode.Comment> s;
      DAE.ConnectorType ct;
      
    case(BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,_,s,ct),_)
      then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,attr,s,ct);  
  end match;
end setVarAttributes; 

public function varStartValue
"function varStartValue
  author: PA
  Returns the DAE.StartValue of a variable."
  input BackendDAE.Var v;
  output DAE.Exp sv;
algorithm
  sv := match(v)
    local
      Option<DAE.VariableAttributes> attr;
    case (BackendDAE.VAR(values = attr))
      equation
        sv=DAEUtil.getStartAttr(attr);
      then sv;
   end match;
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

public function varBindExpStartValue
"function varBindExpStartValue
  author: Frenkel TUD 2010-12
  Returns the bindExp or the start value if no bind is there of a variable."
  input BackendDAE.Var v;
  output DAE.Exp sv;
algorithm
  sv := match(v)
    local DAE.Exp e;
    case (BackendDAE.VAR(bindExp = SOME(e))) then e;
    else
      varStartValueFail(v);      
   end match;
end varBindExpStartValue;

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

public function getVariableAttributefromType
  input DAE.Type inType;
  output DAE.VariableAttributes attr;
algorithm
  attr := match(inType)
    case DAE.T_REAL(source=_) then DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_INTEGER(source=_) then DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_INTEGER(source=_) then DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_BOOL(source=_) then DAE.VAR_ATTR_BOOL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_STRING(source=_) then DAE.VAR_ATTR_STRING(NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_ENUMERATION(source=_) then DAE.VAR_ATTR_ENUMERATION(NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE());
    else
      equation
        // repord a warning on failtrace
        Debug.fprint(Flags.FAILTRACE,"BackendVariable.getVariableAttributefromType called with unsopported Type!\n");
      then
        DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
  end match;
end getVariableAttributefromType;

public function setVarFinal
"function: setVarFinal
  author: Frenkel TUD
  Sets the final attribute of a variable."
  input BackendDAE.Var inVar;
  input Boolean finalPrefix;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,finalPrefix)
    local
      DAE.ComponentRef a;
      BackendDAE.VarKind b;
      DAE.VarDirection c;
      DAE.VarParallelism prl;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      DAE.ElementSource source;
      DAE.VariableAttributes attr;
      Option<DAE.VariableAttributes> oattr1;
      Option<SCode.Comment> s;
      DAE.ConnectorType ct;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varParallelism = prl,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              source = source,
              values = NONE(),
              comment = s,
              connectorType = ct),_)
      equation
        attr = getVariableAttributefromType(d);
        oattr1 = DAEUtil.setFinalAttr(SOME(attr),finalPrefix);
    then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr1,s,ct);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varParallelism = prl,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              source = source,
              values = SOME(attr),
              comment = s,
              connectorType = ct),_)
      equation
        oattr1 = DAEUtil.setFinalAttr(SOME(attr),finalPrefix);
    then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr1,s,ct);
  end match;
end setVarFinal;

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
      DAE.VarParallelism prl;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      DAE.ElementSource source;
      DAE.VariableAttributes attr;
      Option<DAE.VariableAttributes> oattr1;
      Option<SCode.Comment> s;
      DAE.ConnectorType ct;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varParallelism = prl,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              source = source,
              values = NONE(),
              comment = s,
              connectorType = ct),_)
      equation
        attr = getVariableAttributefromType(d);
        oattr1 = DAEUtil.setMinMax(SOME(attr),minMax);
    then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr1,s,ct);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varParallelism = prl,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              source = source,
              values = SOME(attr),
              comment = s,
              connectorType = ct),_)
      equation
        oattr1 = DAEUtil.setMinMax(SOME(attr),minMax);
    then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr1,s,ct);
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
      DAE.VarParallelism prl;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      DAE.ElementSource source;
      DAE.VariableAttributes attr;
      Option<DAE.VariableAttributes> oattr1;
      Option<SCode.Comment> s;
      DAE.ConnectorType ct;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varParallelism = prl,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              source = source,
              values = NONE(),
              comment = s,
              connectorType = ct),_)
      equation
        attr = getVariableAttributefromType(d);
        oattr1 = DAEUtil.setNominalAttr(SOME(attr),inExp);
    then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr1,s,ct);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varParallelism = prl,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              source = source,
              values = SOME(attr),
              comment = s,
              connectorType = ct),_)
      equation
        oattr1 = DAEUtil.setNominalAttr(SOME(attr),inExp);
    then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr1,s,ct);
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

public function varBindValue "function: varBindValue
  author: PA

  extracts the bindValue of a variable.
"
  input BackendDAE.Var inVar;
  output Values.Value outBindValue;
algorithm
  outBindValue:=
  match (inVar)
    local Values.Value bindValue;
    case (BackendDAE.VAR(bindValue = SOME(bindValue))) then bindValue;
  end match;
end varBindValue;

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
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(nominal=SOME(DAE.RCONST(nominal)))))) then nominal;
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
    case _
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

public function varDistribution
"
  author: Peter Aronsson, 2012-05
  
  Returns Distribution record of a variable.
"
  input BackendDAE.Var var;
  output DAE.Distribution d;
algorithm 
  d := match (var)
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(distributionOption = SOME(d))))) then d;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_INT(distributionOption  = SOME(d))))) then d;
  end match;
end varDistribution;

public function varUncertainty
"
  author: Peter Aronsson, 2012-05
  
  Returns Uncertainty of a variable.
"
  input BackendDAE.Var var;
  output DAE.Uncertainty u;
algorithm 
  u := match (var)
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(uncertainOption = SOME(u))))) then u;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_INT(uncertainOption  = SOME(u))))) then u;
  end match;
end varUncertainty;

public function varHasDistributionAttribute
"
  author: Peter Aronsson, 2012-05
  
  Returns true if the specified variable has the attribute distribution set.
"
  input BackendDAE.Var var;
  output Boolean b;
algorithm 
  b := matchcontinue (var)
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(distributionOption = SOME(_))))) then true;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_INT(distributionOption  = SOME(_))))) then true;
    case (_) then false;
  end matchcontinue;
end varHasDistributionAttribute;

public function varHasUncertaintyAttribute
"
  author: Peter Aronsson, 2012-05
  
  Returns true if the specified variable has the attribute uncertain set.
"
  input BackendDAE.Var var;
  output Boolean b;
algorithm 
  b := matchcontinue (var)
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(uncertainOption = SOME(_))))) then true;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_INT(uncertainOption  = SOME(_))))) then true;
    case (_) then false;
  end matchcontinue;
end varHasUncertaintyAttribute;

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

public function isVarNonDiscrete
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean := not isVarDiscrete(inVar);
end isVarNonDiscrete;

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
    case _
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
    case _
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
    case BackendDAE.VAR(connectorType = DAE.NON_CONNECTOR()) then false;
    else true;
  end match;
end isVarConnector;

public function isFlowVar
"function: isFlowVar
  Returns true for flow variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case BackendDAE.VAR(connectorType = DAE.FLOW()) then true;
    else then false;
  end matchcontinue;
end isFlowVar;

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

public function isOutputVar "function: isOutputVar
  Return true if variable is declared as output. Note that the output
  attribute sticks with a variable even if it is originating from a sub
  component, which is not the case for Dymola."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVar)
    case (BackendDAE.VAR(varDirection = DAE.OUTPUT())) then true;
    case (_) then false;
  end matchcontinue;
end isOutputVar;

public function createpDerVar "function createpDerVar
  author: wbraun
  Create variable with $pDER.v as cref for jacobian variables."
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef cr;
algorithm
  cr := varCref(inVar);
  cr := ComponentReference.makeCrefQual(BackendDAE.partialDerivativeNamePrefix, DAE.T_REAL_DEFAULT, {}, cr);
  outVar := copyVarNewName(cr,inVar);
  outVar := setVarKind(outVar,BackendDAE.JAC_DIFF_VAR());
end createpDerVar;

public function copyVarNewName
"function copyVarNewName
  author: Frenkel TUD 2012-5
  Create variable with new name as cref from other var."
  input DAE.ComponentRef cr;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (cr,inVar)
    local
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;

    case (_,BackendDAE.VAR(varKind = kind,
              varDirection = dir,
              varParallelism = prl,
              varType = tp,
              bindExp = bind,
              bindValue = v,
              arryDim = dim,
              source = source,
              values = attr,
              comment = comment,
              connectorType = ct))
    then
      BackendDAE.VAR(cr,kind,dir,prl,tp,bind,v,dim,source,attr,comment,ct); 
  end match;
end copyVarNewName;

public function setVarsKind "function: setVarsKind
  author: lochel
  This function sets the BackendDAE.VarKind of a variable-list."
  input list<BackendDAE.Var> inVars;
  input BackendDAE.VarKind inVarKind;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := List.map1(inVars,setVarKind,inVarKind);
end setVarsKind;

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
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var oVar;

    case (BackendDAE.VAR(varName = cr,
              varKind = kind,
              varDirection = dir,
              varParallelism = prl,
              varType = tp,
              bindExp = bind,
              bindValue = v,
              arryDim = dim,
              source = source,
              values = attr,
              comment = comment,
              connectorType = ct),new_kind)
    equation
      oVar = BackendDAE.VAR(cr,new_kind,dir,prl,tp,bind,v,dim,source,attr,comment,ct); // referenceUpdate(inVar, 2, new_kind);
    then 
      oVar; 
  end match;
end setVarKind;

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
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var oVar;

    case (BackendDAE.VAR(varName = cr,
              varKind = kind,
              varDirection = dir,
              varParallelism = prl,
              varType = tp,
              bindValue = v,
              arryDim = dim,
              source = source,
              values = attr,
              comment = comment,
              connectorType = ct),
          _)
    equation
      oVar = BackendDAE.VAR(cr,kind,dir,prl,tp,SOME(inBindExp),v,dim,source,attr,comment,ct); // referenceUpdate(inVar, 5, SOME(inBindExp));
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
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      list<DAE.Subscript> dim;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var oVar;

    case (BackendDAE.VAR(varName = cr,
              varKind = kind,
              varDirection = dir,
              varParallelism = prl,
              varType = tp,
              bindExp = bind,
              bindValue = NONE(),
              arryDim = dim,
              source = source,
              values = attr,
              comment = comment,
              connectorType = ct),_)
    equation
      oVar = BackendDAE.VAR(cr,kind,dir,prl,tp,bind,SOME(inBindValue),dim,source,attr,comment,ct); // referenceUpdate(inVar, 6, SOME(inBindValue));
    then 
      oVar;
  end match;
end setBindValue;

public function setVarDirectionTpl "function setVarDirectionTpl
  author: "
  input tuple<BackendDAE.Var, DAE.VarDirection> inTpl;
  output tuple<BackendDAE.Var, DAE.VarDirection> outTpl;
algorithm 
  outTpl  := match(inTpl)
    local
      BackendDAE.Var var;
      DAE.VarDirection dir;
      
    case((var, dir)) equation
      var = setVarDirection(var, dir);
    then ((var, dir));
  end match;
end setVarDirectionTpl;

public function setVarDirection "function setVarDirection
  author: Frenkel TUD 17-03-11
  Sets the DAE.VarDirection of a variable"
  input BackendDAE.Var inVar;
  input DAE.VarDirection varDirection;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,varDirection)
    local
      DAE.ComponentRef cr;
      DAE.VarParallelism prl;
      BackendDAE.VarKind kind;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var oVar;

    case (BackendDAE.VAR(varName = cr,
              varKind = kind,
              varParallelism = prl,
              varType = tp,
              bindExp = bind,
              bindValue = v,
              arryDim = dim,
              source = source,
              values = attr,
              comment = comment,
              connectorType = ct),_)
    equation
      oVar = BackendDAE.VAR(cr,kind,varDirection,prl,tp,bind,v,dim,source,attr,comment,ct); // referenceUpdate(inVar, 3, varDirection);
    then 
      oVar; 
  end match;
end setVarDirection;

public function getVarDirection "function getVarDirection
  author: wbraun
  Get the DAE.VarDirection of a variable"
  input BackendDAE.Var inVar;
  output DAE.VarDirection varDirection;
algorithm
  varDirection := match (inVar)
    case (BackendDAE.VAR(varDirection = varDirection)) then  varDirection; 
  end match;
end getVarDirection;


public function isVarOnTopLevelAndOutput "function isVarOnTopLevelAndOutput
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
      DAE.ConnectorType ct;
    case (BackendDAE.VAR(varName = cr,varDirection = dir,connectorType = ct))
      equation
        topLevelOutput(cr, dir, ct);
      then
        true;
    case (_) then false;
  end matchcontinue;
end isVarOnTopLevelAndOutput;

public function isVarOnTopLevelAndInput "function isVarOnTopLevelAndInput
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
      DAE.ConnectorType ct;
    case (BackendDAE.VAR(varName = cr,varDirection = dir,connectorType = ct))
      equation
        topLevelInput(cr, dir, ct);
      then
        true;
    case (_) then false;
  end matchcontinue;
end isVarOnTopLevelAndInput;

public function topLevelInput "function: topLevelInput
  author: PA
  Succeds if variable is input declared at the top level of the model,
  or if it is an input in a connector instance at top level."
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.ConnectorType inConnectorType;
algorithm
  _ := match (inComponentRef,inVarDirection,inConnectorType)
    case (DAE.CREF_IDENT(ident = _), DAE.INPUT(), _) then ();
    case (DAE.CREF_QUAL(componentRef = DAE.CREF_IDENT(ident = _)), DAE.INPUT(), DAE.FLOW()) then ();
    case (DAE.CREF_QUAL(componentRef = DAE.CREF_IDENT(ident = _)), DAE.INPUT(), DAE.POTENTIAL()) then ();
  end match;
end topLevelInput;

protected function topLevelOutput
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.ConnectorType inConnectorType;
algorithm
  _ := match(inComponentRef, inVarDirection, inConnectorType)
    case (DAE.CREF_IDENT(ident = _), DAE.OUTPUT(), _) then ();
    case (DAE.CREF_QUAL(componentRef = DAE.CREF_IDENT(ident = _)), DAE.OUTPUT(), DAE.FLOW()) then ();
    case (DAE.CREF_QUAL(componentRef = DAE.CREF_IDENT(ident = _)), DAE.OUTPUT(), DAE.POTENTIAL()) then ();
  end match;
end topLevelOutput;


public function isFinalVar "function isFinalVar
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

public function getVariableAttributes "function getVariableAttributes
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

public function getVarSource "function getVarSource
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

public function getMinMaxAsserts "function getMinMaxAsserts
  author: Frenkel TUD 2011-03"
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
      String str, format;
      DAE.Type tp;
    
    case(_,_,_,BackendDAE.CONST(),_) then {};
    case (_,_,_,_,_)
      equation 
        ominmax = DAEUtil.getMinMax(attr);
        str = ComponentReference.printComponentRefStr(name);
        str = stringAppendList({"Variable ",str," out of [min, max] interval: "});
        e = Expression.crefExp(name);
        tp = BackendDAEUtil.makeExpType(vartype);
        cond = getMinMaxAsserts1(ominmax,e,tp);
        (cond,_) = ExpressionSimplify.simplify(cond);
        str = str +& ExpressionDump.printExpStr(cond) +& " has value: ";
        // if is real use %g otherwise use %d (ints and enums)
        format = Util.if_(Types.isRealOrSubTypeReal(tp), "g", "d");
        msg = DAE.BINARY(
              DAE.SCONST(str), 
              DAE.ADD(DAE.T_STRING_DEFAULT),
              DAE.CALL(Absyn.IDENT("String"), {e, DAE.SCONST(format)}, DAE.callAttrBuiltinString) 
              );
        // do not add if const true
        false = Expression.isConstTrue(cond);
        BackendDAEUtil.checkAssertCondition(cond,msg,DAE.ASSERTIONLEVEL_WARNING);
      then 
        {DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond,msg,DAE.ASSERTIONLEVEL_WARNING,source)})};
    case(_,_,_,_,_) then {};
  end matchcontinue;
end getMinMaxAsserts;

protected function getMinMaxAsserts1 "function getMinMaxAsserts1
  author: Frenkel TUD 2011-03"
  input list<Option<DAE.Exp>> ominmax;
  input DAE.Exp e;
  input DAE.Type tp;
  output DAE.Exp cond;
algorithm
  cond :=
  match (ominmax,e,tp)
    local
      DAE.Exp min,max;
    case (SOME(min)::(SOME(max)::{}),_,_)
      then DAE.LBINARY(DAE.RELATION(e,DAE.GREATEREQ(tp),min,-1,NONE()),
                            DAE.AND(DAE.T_BOOL_DEFAULT),
                            DAE.RELATION(e,DAE.LESSEQ(tp),max,-1,NONE()));
    case (SOME(min)::(NONE()::{}),_,_)
      then DAE.RELATION(e,DAE.GREATEREQ(tp),min,-1,NONE());
    case (NONE()::(SOME(max)::{}),_,_)
      then DAE.RELATION(e,DAE.LESSEQ(tp),max,-1,NONE());
  end match;
end getMinMaxAsserts1;

public function getNominalAssert "function getNominalAssert
  author: Frenkel TUD 2011-03"
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
      String str, format;
      DAE.Type tp;
    
    case(_,_,_,BackendDAE.CONST(),_) then {};
    case (SOME(DAE.VAR_ATTR_REAL(nominal=SOME(e))),_,_,_,_)
      equation 
        ominmax = DAEUtil.getMinMax(attr);
        str = ComponentReference.printComponentRefStr(name);
        str = stringAppendList({"Nominal ",str," out of [min, max] interval: "});
        tp = BackendDAEUtil.makeExpType(vartype);
        cond = getMinMaxAsserts1(ominmax,e,tp);
        (cond,_) = ExpressionSimplify.simplify(cond);
        str = str +& ExpressionDump.printExpStr(cond) +& " has value: ";
        // if is real use %g otherwise use %d (ints and enums)
        format = Util.if_(Types.isRealOrSubTypeReal(tp), "g", "d");
        msg = DAE.BINARY(
              DAE.SCONST(str), 
              DAE.ADD(DAE.T_STRING_DEFAULT),
              DAE.CALL(Absyn.IDENT("String"), {e, DAE.SCONST(format)}, DAE.callAttrBuiltinString) 
              );
        // do not add if const true
        false = Expression.isConstTrue(cond);
        BackendDAEUtil.checkAssertCondition(cond,msg,DAE.ASSERTIONLEVEL_WARNING);
      then 
        {DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond,msg,DAE.ASSERTIONLEVEL_WARNING,source)})};
    case(_,_,_,_,_) then {};
  end matchcontinue;
end getNominalAssert;


public function varSortFunc "function varSortFun
  A sorting function (greatherThan) for Variables based on crefs"
  input BackendDAE.Var v1;
  input BackendDAE.Var v2;
  output Boolean greaterThan;
algorithm
  greaterThan := ComponentReference.crefSortFunc(varCref(v1), varCref(v2));
end varSortFunc;

/* =======================================================
 *
 *  Section for functions that deals with VariablesArray 
 *
 * =======================================================
 */

public function copyVariables
  input BackendDAE.Variables inVarArray;
  output BackendDAE.Variables outVarArray;
protected
  array<list<BackendDAE.CrefIndex>> crefIdxLstArr,crefIdxLstArr1;
  BackendDAE.VariableArray varArr;
  Integer bucketSize, numberOfVars, n1, size1;
  array<Option<BackendDAE.Var>> varOptArr,varOptArr1;
algorithm
  BackendDAE.VARIABLES(crefIdxLstArr,varArr,bucketSize,numberOfVars) := inVarArray;
  BackendDAE.VARIABLE_ARRAY(n1,size1,varOptArr) := varArr;
  crefIdxLstArr1 := arrayCreate(size1, {});
  crefIdxLstArr1 := Util.arrayCopy(crefIdxLstArr, crefIdxLstArr1);
  varOptArr1 := arrayCreate(size1, NONE());
  varOptArr1 := Util.arrayCopy(varOptArr, varOptArr1);
  outVarArray := BackendDAE.VARIABLES(crefIdxLstArr1,BackendDAE.VARIABLE_ARRAY(n1,size1,varOptArr1),bucketSize,numberOfVars);
end copyVariables;

public function daenumVariables
  input BackendDAE.EqSystem syst;
  output Integer n;
protected
 BackendDAE.Variables vars; 
algorithm
  vars := daeVars(syst);
  n := numVariables(vars);
end daenumVariables;

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
    local Integer n;
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
      Integer n_1,n,size,expandsize,expandsize_1,newsize;
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
        (n < size) = false "Do NOT have space to add array elt. Expand with factor 1.4" ;
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
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),_)
      equation
        print("- BackendVariable.vararrayAdd failed\nn: " +& intString(n) +& ", size: " +& intString(size) +& " arraysize: " +& intString(arrayLength(arr)) +& "\n");
        Debug.execStat("vararrayAdd",BackendDAE.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
      then
        fail();
    case (_,_)
      equation
        print("- BackendVariable.vararrayAdd failed!\n");
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
      Integer n,size,pos;
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
      Integer n,pos;
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

public function equationSystemsVarsLst
  input BackendDAE.EqSystems systs;
  input list<BackendDAE.Var> inVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := match (systs,inVars)
    local
      BackendDAE.EqSystems rest;
      list<BackendDAE.Var> vars,vars1;
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

public function varsSize "function: varsSize
  author: PA

  Returns the number of variables
"
  input BackendDAE.Variables inVariables;
  output Integer outInteger;
algorithm
  outInteger:=
  match (inVariables)
    local Integer n;
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
  input BackendDAE.Variables inDelVars;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inDelVars,inVariables)
    local
      BackendDAE.Variables newvars;
    case (_,_)
      equation
        true = intGt(varsSize(inDelVars),0);
        newvars = traverseBackendDAEVars(inDelVars,deleteVars1,inVariables);
        newvars = BackendDAEUtil.listVar1(BackendDAEUtil.varList(newvars));
      then
        newvars;
    else
      then
        inVariables; 
  end matchcontinue;
end deleteVars;

protected function deleteVars1
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, BackendDAE.Variables> inTpl;
 output tuple<BackendDAE.Var, BackendDAE.Variables> outTpl;
algorithm
  outTpl:= match (inTpl)
    local
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
    case ((v as BackendDAE.VAR(varName = cr),vars))
      equation
        vars = removeCref(cr,vars) "alg var deleted" ;
      then
        ((v,vars));
  end match;
end deleteVars1;

public function deleteVar
"function: deleteVar
  author: PA
  Deletes a variable from Variables."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := match (inComponentRef,inVariables)
    local
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      list<Integer> ilst;
    case (cr,_)
      equation
        (_,ilst) = getVar(cr,inVariables);
        (vars,_) = removeVars(ilst,inVariables,{});
        vars = BackendDAEUtil.listVar1(BackendDAEUtil.varList(vars));
      then
        vars;
  end match;
end deleteVar;

public function removeCref
"function: removeCref
  author: Frenkel TUD 2012-09
  Deletes a variable from Variables."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inComponentRef,inVariables)
    local
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      list<Integer> ilst;
    case (cr,_)
      equation
        (_,ilst) = getVar(cr,inVariables);
        (vars,_) = removeVars(ilst,inVariables,{});
      then
        vars;
    case (cr,_)
//      equation
//        BackendDump.debugStrCrefStr(("var ",cr," not in inVariables\n"));
      then
        inVariables;
  end matchcontinue;
end removeCref;

public function removeVars
"function: removeVar
  author: Frenkel TUD 2012-09
  Removes  vars from the vararray but does not scaling down the array"
  input list<Integer> inVarPos "Position of vars to delete 1 based";
  input BackendDAE.Variables inVariables;
  input list<BackendDAE.Var> iAcc;
  output BackendDAE.Variables outVariables;
  output list<BackendDAE.Var> outVars "deleted vars in reverse order";
algorithm
  (outVariables,outVars) := matchcontinue(inVarPos,inVariables,iAcc)
    local
      BackendDAE.Variables vars;
      list<Integer> ilst;
      Integer i;
      BackendDAE.Var v;
      list<BackendDAE.Var> acc;
    case({},_,_) then (inVariables,iAcc);
    case(i::ilst,_,_)
      equation
        (vars,v) = removeVar(i,inVariables);
        (vars,acc) = removeVars(ilst,vars,v::iAcc);
      then
        (vars,acc);
    case(i::ilst,_,_)
      equation
        (vars,acc) = removeVars(ilst,inVariables,iAcc);
      then
        (vars,acc);      
  end matchcontinue;
end removeVars;
  
public function removeVar
"function: removeVar
  author: Frenkel TUD 2011-04
  Removes a var from the vararray but does not scaling down the array"
  input Integer inVarPos "1 based index";
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
  output BackendDAE.Var outVar;
algorithm
  (outVariables,outVar):=
  matchcontinue (inVarPos,inVariables)
    local
      Integer pos,pos_1;
      Integer hashindx,bsize,n;
      list<BackendDAE.CrefIndex> indexes,indexes1;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      array<list<BackendDAE.CrefIndex>> hashvec,hashvec_1;
      BackendDAE.VariableArray varr,varr1;
    case (pos,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        (v as BackendDAE.VAR(varName = cr),varr1) = removeVar1(varr, pos);
        pos_1 = pos-1;
        hashindx = HashTable2.hashFunc(cr, bsize);
        indexes = hashvec[hashindx + 1];
        (indexes1,_) = List.deleteMemberOnTrue(BackendDAE.CREFINDEX(cr,pos_1),indexes,removeVar2);
        hashvec_1 = arrayUpdate(hashvec, hashindx + 1, indexes1);
        //fastht = BaseHashTable.delete(cr, fastht);
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
      Integer n,size,pos;
      BackendDAE.Var v;

    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),pos)
      equation
        (pos <= size) = true;
        SOME(v) = arr[pos];
        arr_1 = arrayUpdate(arr, pos, NONE());
      then
        (v,BackendDAE.VARIABLE_ARRAY(n,size,arr_1));
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),_)
      equation
        print("- BackendVariable.removeVar1 failed\n Pos " +& intString(inInteger) +& " numberOfElements " +& intString(n) +& " size " +& intString(size) +& " arraySize " +& intString(arrayLength(arr)) +& "\n");
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
protected
  list<BackendDAE.Var> varlst;
algorithm
  (varlst,_) := getVar(inComponentRef,inVariables);
  varlst := Debug.bcallret2(skipDiscrete, List.select, varlst, isVarNonDiscrete, varlst);
  outBoolean:=intGt(listLength(varlst),0);
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
      BackendDAE.Variables ordvars,ordvars1;
      BackendDAE.EquationArray eqns;
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
      BackendDAE.Variables knvars,exobj,knvars1,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.BackendDAEType btp;
    case (var,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs))
      equation
        knvars1 = addVar(var,knvars);
      then BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs);
  end match;
end addKnVarDAE;

public function addAliasVarDAE
"function: addAliasVarDAE
  author: Frenkel TUD 2012-09
  Add a alias variable to Variables of a BackendDAE.Shared
  If the variable already exists, the function updates the variable."
  input BackendDAE.Var inVar;
  input BackendDAE.Shared shared;
  output BackendDAE.Shared oshared;
algorithm
  oshared := match (inVar,shared)
    local
      BackendDAE.Var var;
      BackendDAE.Variables knvars,exobj,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.BackendDAEType btp;
    case (var,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs))
      equation
        aliasVars = addVar(var,aliasVars);
      then BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs);
  end match;
end addAliasVarDAE;

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
      Integer indx,newpos,n_1,bsize,n,indx_1;
      BackendDAE.VariableArray varr_1,varr;
      list<BackendDAE.CrefIndex> indexes;
      array<list<BackendDAE.CrefIndex>> hashvec_1,hashvec;
      BackendDAE.Var v,newv;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
    /* adrpo: ignore records!
    case ((v as BackendDAE.VAR(varName = cr,origVarName = name,flowPrefix = flowPrefix, varType = DAE.COMPLEX(_,_))),
          (vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
    then
      vars;
    */
    case ((v as BackendDAE.VAR(varName = cr)),(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        failure((_,_) = getVar(cr, vars));
        // print("adding when not existing previously\n");
        indx = HashTable2.hashFunc(cr, bsize);
        newpos = vararrayLength(varr);
        varr_1 = vararrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, (BackendDAE.CREFINDEX(cr,newpos) :: indexes));
        n_1 = vararrayLength(varr_1);
        //fastht = BaseHashTable.add((cr,{newpos}),fastht);
      then
        BackendDAE.VARIABLES(hashvec_1,varr_1,bsize,n_1);

    case ((newv as BackendDAE.VAR(varName = cr)),(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
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

public function addNewVar
"function: addNewVar
  author: Frenkel TUD - 2012-07
  Add a variable to Variables.
  Did not check if the variable is already there. Use it only for
  new variables."
  input BackendDAE.Var inVar;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVar,inVariables)
    local
      Integer indx,newpos,n_1,bsize,n;
      BackendDAE.VariableArray varr_1,varr;
      list<BackendDAE.CrefIndex> indexes;
      array<list<BackendDAE.CrefIndex>> hashvec_1,hashvec;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
    case ((v as BackendDAE.VAR(varName = cr)),(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        indx = HashTable2.hashFunc(cr, bsize);
        newpos = vararrayLength(varr);
        varr_1 = vararrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, (BackendDAE.CREFINDEX(cr,newpos) :: indexes));
        n_1 = vararrayLength(varr_1);
      then
        BackendDAE.VARIABLES(hashvec_1,varr_1,bsize,n_1);

    case (_,_)
      equation
        print("- BackendVariable.addNewVar failed\n");
      then
        fail();
  end matchcontinue;
end addNewVar;

public function expandVarsDAE
"function: expandVars
  author: Frenkel TUD 2011-04
  Expand the Variable array."
  input Integer needed;
  input BackendDAE.EqSystem syst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (needed,syst)
    local
      BackendDAE.Variables ordvars,ordvars1;
      BackendDAE.EquationArray eqns;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Matching matching;
    case (_,BackendDAE.EQSYSTEM(ordvars,eqns,m,mT,matching))
      equation
        ordvars1 = expandVars(needed,ordvars);
      then BackendDAE.EQSYSTEM(ordvars1,eqns,m,mT,matching);
  end match;
end expandVarsDAE;

public function expandVars
"function: expandVars
  author: Frenkel TUD - 2012-07
  Expand the variable array"
  input Integer needed;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (needed,inVariables)
    local
      Integer size,noe,bsize,n,size1,expandsize;
      array<list<BackendDAE.CrefIndex>> hashvec;
      BackendDAE.Variables vars;
      array<Option<BackendDAE.Var>> arr,arr_1;
    case (_,(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = BackendDAE.VARIABLE_ARRAY(numberOfElements=noe,arrSize=size,varOptArr=arr),bucketSize = bsize,numberOfVars = n)))
      equation
        size1 = noe + needed;
        true = intGt(size1,size);
        expandsize = size1-size;
        arr_1 = Util.arrayExpand(expandsize, arr, NONE());
      then
        BackendDAE.VARIABLES(hashvec,BackendDAE.VARIABLE_ARRAY(noe,size1,arr_1),bsize,n);

    case (_,(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = BackendDAE.VARIABLE_ARRAY(numberOfElements=noe,arrSize=size,varOptArr=arr),bucketSize = bsize,numberOfVars = n)))
      then
        inVariables;

    case (_,_)
      equation
        print("- BackendVariable.expandVars failed\n");
      then
        fail();
  end matchcontinue;
end expandVars;


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
      Integer pos,n;
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

public function getVarDAE
"function: getVarDAE
  author: Frenkel TUD 2012-05
  return a Variable."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.EqSystem syst;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := match (inComponentRef,syst)
    local
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varlst;
      list<Integer> indxlst;
   case (_,BackendDAE.EQSYSTEM(orderedVars=vars))
      equation
        (varlst,indxlst) = getVar(inComponentRef,vars);
      then 
        (varlst,indxlst);
  end match;
end getVarDAE;

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
  input DAE.ComponentRef cr;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := matchcontinue (cr,inVariables)
    local
      BackendDAE.Var v;
      Integer indx;
      list<Integer> indxs;
      list<BackendDAE.Var> vLst;
      list<DAE.ComponentRef> crlst;    
    case (_,_)
      equation
        (v,indx) = getVar2(cr, inVariables) "if scalar found, return it" ;
      then
        ({v},{indx});
    case (_,_) /* check if array or record */
      equation
        crlst = ComponentReference.expandCref(cr,true);
        (vLst as _::_,indxs) = getVarLst(crlst,inVariables,{},{});
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

public function getVarLst
  input list<DAE.ComponentRef> inComponentRefLst;
  input BackendDAE.Variables inVariables;
  input list<BackendDAE.Var> iVarLst;
  input list<Integer> iIntegerLst; 
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst; 
algorithm
  (outVarLst,outIntegerLst) := matchcontinue(inComponentRefLst,inVariables,iVarLst,iIntegerLst)
    local
      list<DAE.ComponentRef> crlst;
      DAE.ComponentRef cr;
      list<BackendDAE.Var> varlst;
      list<Integer> ilst;
      BackendDAE.Var v;
      Integer indx;
    case ({},_,_,_) then (iVarLst,iIntegerLst);
    case (cr::crlst,_,_,_)
      equation
        (v,indx) = getVar2(cr, inVariables);
        (varlst,ilst) = getVarLst(crlst,inVariables,v::iVarLst,indx::iIntegerLst);
      then
        (varlst,ilst); 
    case (_::crlst,_,_,_)
      equation
        (varlst,ilst) = getVarLst(crlst,inVariables,iVarLst,iIntegerLst);
      then
        (varlst,ilst); 
  end matchcontinue;
end getVarLst;

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
      Integer hashindx,indx,indx_1,bsize,n;
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
      Integer v; list<BackendDAE.CrefIndex> vs;
    case (_,BackendDAE.CREFINDEX(index = v)::_,true) then v;
    case (_,_::vs,false) then getVar3(cr,vs,getVar4(cr,vs));
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
    case _ then inTpl;
  end matchcontinue;
end traversingisVarIndexVarFinder;


public function getVarIndexFromVar
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inVariables2;
  output list<Integer> v_lst;
algorithm
  ((_,v_lst)) := traverseBackendDAEVars(inVariables,traversingVarIndexFinder,(inVariables2,{}));
end getVarIndexFromVar;

protected function traversingVarIndexFinder
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, tuple<BackendDAE.Variables, list<Integer>>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendDAE.Variables, list<Integer>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> vlst;
      BackendDAE.Variables vars;
      list<Integer> v_lst;
      DAE.ComponentRef cr;
      list<Integer> indxlst;
    case ((v,(vars,v_lst)))
      equation   
        cr = varCref(v);
       (vlst,indxlst) = getVar(cr, vars);
       v_lst = listAppend(v_lst,indxlst);
      then ((v,(vars,v_lst)));
    case _ then inTpl;
  end matchcontinue;
end traversingVarIndexFinder;

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
        // to avoid side effects from arrays copy first
        vars1 = copyVariables(vars1);
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
      Integer n;
      Type_a ext_arg_1;
    case (BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(numberOfElements=n,varOptArr=varOptArr)),_,_)
      equation
        ext_arg_1 = BackendDAEUtil.traverseBackendDAEArrayNoCopy(varOptArr,func,traverseBackendDAEVar,1,n,inTypeA);
      then
        ext_arg_1;
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendVariable.traverseBackendDAEVars failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEVars;

public function traverseBackendDAEVarsWithStop "function: traverseBackendDAEVarsWithStop
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
    output tuple<BackendDAE.Var, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA:=
  matchcontinue (inVariables,func,inTypeA)
    local
      array<Option<BackendDAE.Var>> varOptArr;
      Integer n;
      Type_a ext_arg_1;
    case (BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(numberOfElements=n,varOptArr=varOptArr)),_,_)
      equation
        ext_arg_1 = BackendDAEUtil.traverseBackendDAEArrayNoCopyWithStop(varOptArr,func,traverseBackendDAEVarWithStop,1,n,inTypeA);
      then
        ext_arg_1;
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendVariable.traverseBackendDAEVarsWithStop failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEVarsWithStop;

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
    case (NONE(),_,_) then inTypeA;
    case (SOME(v),_,_)
      equation
        ((_,ext_arg)) = func((v,inTypeA));
      then
        ext_arg;
    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendVariable.traverseBackendDAEVar failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEVar;

protected function traverseBackendDAEVarWithStop "function: traverseBackendDAEVarWithStop
  author: Frenkel TUD
  Helper traverseBackendDAEVars."
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Var> inVar;
  input FuncExpType func;
  input Type_a inTypeA;
  output Boolean outBoolean;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Var, Type_a> inTpl;
    output tuple<BackendDAE.Var, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outBoolean,outTypeA):=
  matchcontinue (inVar,func,inTypeA)
    local
      BackendDAE.Var v;
      Type_a ext_arg;
      Boolean b;
    case (NONE(),_,_) then (true,inTypeA);
    case (SOME(v),_,_)
      equation
        ((_,b,ext_arg)) = func((v,inTypeA));
      then
        (b,ext_arg);
    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendVariable.traverseBackendDAEVarWithStop failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEVarWithStop;

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
      Integer bucketSize,numberOfVars,numberOfElements,arrSize;
      array<Option<BackendDAE.Var>> varOptArr,varOptArr1;
      Type_a ext_arg_1;
    case (BackendDAE.VARIABLES(crefIdxLstArr=crefIdxLstArr,varArr = BackendDAE.VARIABLE_ARRAY(numberOfElements=numberOfElements,arrSize=arrSize,varOptArr=varOptArr),bucketSize=bucketSize,numberOfVars=numberOfVars),_,_)
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
    case (ovar as NONE(),func,_) then (ovar,inTypeA);
    case (ovar as SOME(v),_,_)
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
    case _ then inTpl;
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
    case _ then inTpl;
  end matchcontinue;
end traversingisStateVarFinder;

public function getAllStateVarIndexFromVariables
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> v_lst;
  output list<Integer> i_lst;
algorithm
  ((v_lst,i_lst,_)) := traverseBackendDAEVars(inVariables,traversingisStateVarIndexFinder,({},{},1));
end getAllStateVarIndexFromVariables;

protected function traversingisStateVarIndexFinder
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, tuple<list<BackendDAE.Var>,list<Integer>,Integer>> inTpl;
 output tuple<BackendDAE.Var, tuple<list<BackendDAE.Var>,list<Integer>,Integer>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> v_lst;
      list<Integer> i_lst;
      Integer i;
    case ((v,(v_lst,i_lst,i)))
      equation
        true = isStateVar(v);
      then ((v,(v::v_lst,i::i_lst,i+1)));
    case ((v,(v_lst,i_lst,i))) then ((v,(v_lst,i_lst,i+1)));
  end matchcontinue;
end traversingisStateVarIndexFinder;

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
      DAE.VarParallelism p;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> oattr;
      Option<SCode.Comment> s;
      DAE.ConnectorType ct;
      list<DAE.SymbolicOperation> ops;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varParallelism = p,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              source = source,
              values = oattr,
              comment = s,
              connectorType = ct),_)
      equation
        ops = listReverse(iops);
        source = List.foldr(ops,DAEUtil.addSymbolicTransformation,source);
      then BackendDAE.VAR(a,b,c,p,d,e,f,g,source,oattr,s,ct);
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

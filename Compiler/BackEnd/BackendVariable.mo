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
" file:        mo
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
protected import BaseHashSet;
protected import BaseHashTable;
protected import CevalScript;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import HashSet;
protected import List;
protected import SCode;
protected import System;
protected import Util;
protected import Types;

/* =======================================================
 *
 *  Section for type definitions
 *
 * =======================================================
 */

protected constant Real HASHVECFACTOR = 1.4;

/* =======================================================
 *
 *  Section for functions that deals with Var 
 *
 * =======================================================
 */

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
        oattr = DAEUtil.setFixedAttr(SOME(attr),SOME(DAE.BCONST(inBoolean)));
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
              connectorType = ct),_)
      equation
        attr = getVariableAttributefromType(d);
        oattr = DAEUtil.setFixedAttr(SOME(attr),SOME(DAE.BCONST(inBoolean)));
      then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr,s,ct);


  end match;
end setVarFixed;

public function varFixed "function varFixed
  author: PA
  Extracts the fixed attribute of a variable.
  The default fixed value is used if not found. Default is true for parameters
  (and constants) and false for variables."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inVar)
    local
      Boolean fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(fixed=SOME(DAE.BCONST(fixed)))))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_INT(fixed=SOME(DAE.BCONST(fixed)))))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_BOOL(fixed=SOME(DAE.BCONST(fixed)))))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_ENUMERATION(fixed=SOME(DAE.BCONST(fixed)))))) then fixed;
    // params are by default fixed
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),bindExp=SOME(_))) then true;
    case (BackendDAE.VAR(varKind = BackendDAE.CONST(),bindExp=SOME(_))) then true;
/*  See Modelica Spec 3.2 page 88:
    For constants and parameters, the attribute fixed is by default true. For other variables
    fixed is by default false. For all variables declared as constant it is an error to have "fixed = false".
  case (v) // states are by default fixed.
      equation
        BackendDAE.STATE(index=_) = varKind(v);
        fixes = Flags.isSet(Flags.INIT_DLOW_DUMP);
      then
        not fixed;
*/
    case (_) then false;  /* rest defaults to false */
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

public function setVarStartValueOption "function setVarStartValueOption
  author: Frenkel TUD
  Sets the start value attribute of a variable."
  input BackendDAE.Var inVar;
  input Option<DAE.Exp> inExp;
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
        oattr1 = DAEUtil.setStartAttrOption(SOME(attr),inExp);
    then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr1,s,ct);

    case (BackendDAE.VAR(values = NONE()),NONE()) then inVar;

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
        oattr1 = DAEUtil.setStartAttrOption(SOME(attr),inExp);
    then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr1,s,ct);
  end match;
end setVarStartValueOption;

public function setVarStartOrigin
"function: setVarStartOrigin
  author: Frenkel TUD
  Sets the startOrigin attribute of a variable."
  input BackendDAE.Var inVar;
  input Option<DAE.Exp> startOrigin;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,startOrigin)
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
        oattr1 = DAEUtil.setStartOrigin(SOME(attr),startOrigin);
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
        oattr1 = DAEUtil.setStartOrigin(SOME(attr),startOrigin);
    then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr1,s,ct);

  end match;
end setVarStartOrigin;

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
protected
  Option<DAE.VariableAttributes> attr;
algorithm
  BackendDAE.VAR(values = attr) := v;
  sv := DAEUtil.getStartAttr(attr);
end varStartValue;

public function varStartValueFail
"function varStartValueFail
  author: Frenkel TUD
  Returns the DAE.StartValue of a variable if there is one.
  Otherwise fail"
  input BackendDAE.Var v;
  output DAE.Exp sv;
protected
  Option<DAE.VariableAttributes> attr;
algorithm
  BackendDAE.VAR(values = attr) := v;
  sv := DAEUtil.getStartAttrFail(attr);
end varStartValueFail;

public function varStartValueType
"function varStartValueType
  author: Frenkel TUD 2012-11
  Returns the DAE.StartValue of a variable. If nothing is set the type specific one is used"
  input BackendDAE.Var v;
  output DAE.Exp sv;
algorithm
  sv := matchcontinue(v)
    local
      Option<DAE.VariableAttributes> attr;
      DAE.Type ty;
    case (BackendDAE.VAR(values = attr))
      equation
        sv=DAEUtil.getStartAttrFail(attr);
      then sv;
    case BackendDAE.VAR(varType=ty)
      equation
        true = Types.isIntegerOrSubTypeInteger(ty);
      then
        DAE.ICONST(0);
    case BackendDAE.VAR(varType=ty)
      equation
        true = Types.isBooleanOrSubTypeBoolean(ty);
      then
        DAE.BCONST(false);
    case BackendDAE.VAR(varType=ty)
      equation
        true = Types.isStringOrSubTypeString(ty);
      then
        DAE.SCONST("");
    else
      then
        DAE.RCONST(0.0);
   end matchcontinue;
end varStartValueType;

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

public function varStartOrigin
"function varStartOrigin
  author: Frenkel TUD
  Returns the StartOrigin of a variable."
  input BackendDAE.Var v;
  output Option<DAE.Exp> so;
protected
   Option<DAE.VariableAttributes> attr;
algorithm
  BackendDAE.VAR(values = attr) := v;
  so := DAEUtil.getStartOrigin(attr);
end varStartOrigin;

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
  Extracts the state select attribute of a variable. If no stateselect explicilty set, return
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

public function setVarStateSelect
"function setVarStateSelect
  author: Frenkel TUD
  sets the state select attribute of a variable."
  input BackendDAE.Var inVar;
  input DAE.StateSelect stateSelect;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,stateSelect)
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
              connectorType = ct),_)
      equation
        oattr = DAEUtil.setStateSelect(SOME(attr),stateSelect);
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
              connectorType = ct),_)
      equation
        attr = getVariableAttributefromType(d);
        oattr = DAEUtil.setStateSelect(SOME(attr),stateSelect);
      then BackendDAE.VAR(a,b,c,prl,d,e,f,g,source,oattr,s,ct);


  end match;
end setVarStateSelect;

public function varStateDerivative
"function varStateDerivative
  author: Frenkel TUD 2013-01
  Returns the name of the Derivative. Is no Derivative known the function will fail."
  input BackendDAE.Var inVar;
  output DAE.ComponentRef dcr;
algorithm
  BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(dcr))) := inVar;
end varStateDerivative;

public function varHasStateDerivative
"function varHasStateDerivative
  author: Frenkel TUD 2013-01
  Returns the name of the Derivative. Is no Derivative known the function will fail."
  input BackendDAE.Var inVar;
  output Boolean b;
algorithm
  b := match(inVar)
    case BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(_))) then true;
    else then false;
end match;
end varHasStateDerivative;

public function setStateDerivative
"function setStateDerivative
  author: Frenkel TUD
  sets the state derivative."
  input BackendDAE.Var inVar;
  input Option<DAE.ComponentRef> dcr;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar,dcr)
    local
      DAE.ComponentRef a;
      Integer indx;
      DAE.VarDirection c;
      DAE.VarParallelism prl;
      BackendDAE.Type d;
      Option<DAE.Exp> e;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> oattr;
      Option<SCode.Comment> s;
      DAE.ConnectorType ct;

    case (BackendDAE.VAR(varName = a,
              varKind = BackendDAE.STATE(index=indx),
              varDirection = c,
              varParallelism = prl,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              source = source,
              values = oattr,
              comment = s,
              connectorType = ct),_)
      then BackendDAE.VAR(a,BackendDAE.STATE(indx,dcr),c,prl,d,e,f,g,source,oattr,s,ct);
  end match;
end setStateDerivative;

public function getVariableAttributefromType
  input DAE.Type inType;
  output DAE.VariableAttributes attr;
algorithm
  attr := match(inType)
    case DAE.T_REAL(source=_) then DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_INTEGER(source=_) then DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_INTEGER(source=_) then DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_BOOL(source=_) then DAE.VAR_ATTR_BOOL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_STRING(source=_) then DAE.VAR_ATTR_STRING(NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_ENUMERATION(source=_) then DAE.VAR_ATTR_ENUMERATION(NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    else
      equation
        // repord a warning on failtrace
        Debug.fprint(Flags.FAILTRACE,"getVariableAttributefromType called with unsopported Type!\n");
      then
        DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
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
    case (_,(NONE(),NONE())) then inVar;
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
    case (BackendDAE.VAR(varKind = BackendDAE.STATE(index=_))) then true;
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
        ((BackendDAE.VAR(varKind = BackendDAE.STATE(index=_)) :: _),_) = getVar(cr, vars);
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

public function varTryGetDistribution
"
  author: Peter Aronsson, 2012-05

  Returns Distribution record of a variable.
"
  input BackendDAE.Var var;
  output Option<DAE.Distribution> dout;
  protected DAE.Distribution d;
algorithm
  dout := match (var)
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(distributionOption = SOME(d))))) then SOME(d);
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_INT(distributionOption  = SOME(d))))) then SOME(d);
    case (_) then NONE();
  end match;
end varTryGetDistribution;

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
    case (BackendDAE.VAR(varKind = BackendDAE.STATE(index=_))) then true;
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
  match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE())) then true;
    case (BackendDAE.VAR(varType = DAE.T_INTEGER(source = _))) then true;
    case (BackendDAE.VAR(varType = DAE.T_BOOL(source = _))) then true;
    case (BackendDAE.VAR(varType = DAE.T_ENUMERATION(source = _))) then true;
    case (_) then false;
  end match;
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
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;
    case (v :: vs)
      equation
        true = isVarDiscrete(v);
      then
        true;
    case (v :: vs) then hasDiscreteVar(vs);
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
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;
    case ((BackendDAE.VAR(varKind=BackendDAE.VARIABLE(),varType = DAE.T_REAL(source = _)) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.VARIABLE(),varType = DAE.T_ARRAY(ty=DAE.T_REAL(source = _))) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.STATE(index=_)) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.STATE_DER()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.DUMMY_DER()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.DUMMY_STATE()) :: _)) then true;
    case ((v :: vs)) then hasContinousVar(vs);
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
    /* int enumeration */
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as DAE.T_ENUMERATION(source = _)))
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
    case (BackendDAE.VAR(varKind = kind,
                     varType = typeVar as DAE.T_ENUMERATION(source = _)))
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
    /* enum variable */
    case (BackendDAE.VAR(varType = typeVar as DAE.T_ENUMERATION(source = _)))
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
    case (BackendDAE.VAR(varType = typeVar as DAE.T_ENUMERATION(source = _)))
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
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = DAE.T_ENUMERATION(source = _))) then true;
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

public function isProtectedVar
"function isProtectedVar
  author: Frenkel TUD 2013-01
  Returns the DAE.Protected attribute."
  input BackendDAE.Var v;
  output Boolean prot;
protected
  Option<DAE.VariableAttributes> attr;
algorithm
  BackendDAE.VAR(values = attr) := v;
  prot := DAEUtil.getProtectedAttr(attr);
end isProtectedVar;

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

public function createDummyVar "function createDummyVar
  author: wbraun
  Creates variable with $dummy."
  output BackendDAE.Var outVar;
  output DAE.ComponentRef outCr;
algorithm
  outCr := ComponentReference.makeCrefIdent("$dummy",DAE.T_REAL_DEFAULT,{});
  outVar := BackendDAE.VAR(outCr, BackendDAE.STATE(1,NONE()),DAE.BIDIR(),DAE.NON_PARALLEL(),DAE.T_REAL_DEFAULT,NONE(),NONE(),{},
                            DAE.emptyElementSource,
                            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(true)),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())),
                            NONE(),DAE.NON_CONNECTOR());
end createDummyVar;

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

public function setVarKind "function setVarKind
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
  input list<DAE.Algorithm> iMinmax;
  output list<DAE.Algorithm> oMinmax;
algorithm
  oMinmax :=
  matchcontinue (attr,name,source,kind,vartype,iMinmax)
    local
      DAE.Exp e,cond,msg;
      list<Option<DAE.Exp>> ominmax;
      String str, format;
      DAE.Type tp;

    case(_,_,_,BackendDAE.CONST(),_,_) then iMinmax;
    case (_,_,_,_,_,_)
      equation
        ominmax = DAEUtil.getMinMax(attr);
        str = ComponentReference.printComponentRefStr(name);
        str = stringAppendList({"Variable ",str," out of [min, max] interval: "});
        e = Expression.crefExp(name);
        tp = BackendDAEUtil.makeExpType(vartype);
        cond = getMinMaxAsserts1(ominmax,e,tp);
        (cond,_) = ExpressionSimplify.simplify(cond);
        // do not add if const true
        false = Expression.isConstTrue(cond);
        str = str +& ExpressionDump.printExpStr(cond) +& " has value: ";
        // if is real use %g otherwise use %d (ints and enums)
        format = Util.if_(Types.isRealOrSubTypeReal(tp), "g", "d");
        msg = DAE.BINARY(
              DAE.SCONST(str),
              DAE.ADD(DAE.T_STRING_DEFAULT),
              DAE.CALL(Absyn.IDENT("String"), {e, DAE.SCONST(format)}, DAE.callAttrBuiltinString) 
              );
        BackendDAEUtil.checkAssertCondition(cond,msg,DAE.ASSERTIONLEVEL_WARNING,DAEUtil.getElementSourceFileInfo(source));
      then 
        DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond,msg,DAE.ASSERTIONLEVEL_WARNING,source)})::iMinmax;
    else then iMinmax;
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
  input list<DAE.Algorithm> iNominal;
  output list<DAE.Algorithm> oNominal;
algorithm
  oNominal :=
  matchcontinue (attr,name,source,kind,vartype,iNominal)
    local
      DAE.Exp e,cond,msg;
      list<Option<DAE.Exp>> ominmax;
      String str, format;
      DAE.Type tp;

    case(_,_,_,BackendDAE.CONST(),_,_) then iNominal;
    case (SOME(DAE.VAR_ATTR_REAL(nominal=SOME(e))),_,_,_,_,_)
      equation
        ominmax = DAEUtil.getMinMax(attr);
        str = ComponentReference.printComponentRefStr(name);
        str = stringAppendList({"Nominal ",str," out of [min, max] interval: "});
        tp = BackendDAEUtil.makeExpType(vartype);
        cond = getMinMaxAsserts1(ominmax,e,tp);
        (cond,_) = ExpressionSimplify.simplify(cond);
        // do not add if const true
        false = Expression.isConstTrue(cond);
        str = str +& ExpressionDump.printExpStr(cond) +& " has value: ";
        // if is real use %g otherwise use %d (ints and enums)
        format = Util.if_(Types.isRealOrSubTypeReal(tp), "g", "d");
        msg = DAE.BINARY(
              DAE.SCONST(str),
              DAE.ADD(DAE.T_STRING_DEFAULT),
              DAE.CALL(Absyn.IDENT("String"), {e, DAE.SCONST(format)}, DAE.callAttrBuiltinString)
              );
        BackendDAEUtil.checkAssertCondition(cond,msg,DAE.ASSERTIONLEVEL_WARNING,DAEUtil.getElementSourceFileInfo(source));
      then
        DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond,msg,DAE.ASSERTIONLEVEL_WARNING,source)})::iNominal;
    else then iNominal;
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


public function getAlias
" function getAlias
  author: Frenkel TUD 2012-11
  returns the original Varname of an AliasVar"
  input BackendDAE.Var inVar;
  output DAE.ComponentRef outCr;
  output Boolean negated;
protected
  DAE.Exp e;
algorithm
  e := varBindExp(inVar);
  (outCr,negated) := getAlias1(e);
end getAlias;

protected function getAlias1
  input DAE.Exp inExp;
  output DAE.ComponentRef outCr;
  output Boolean negated;
algorithm
  (outCr,negated) :=
  match (inExp)
    local
      DAE.ComponentRef name;

    case DAE.CREF(componentRef=name) then (name,false);
    case DAE.UNARY(operator=DAE.UMINUS(_),exp=DAE.CREF(componentRef=name)) then (name,true);
    case DAE.UNARY(operator=DAE.UMINUS_ARR(_),exp=DAE.CREF(componentRef=name)) then (name,true);
    case DAE.LUNARY(operator=DAE.NOT(_),exp=DAE.CREF(componentRef=name)) then (name,true);
    case DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(componentRef=name)})
      equation
        name = ComponentReference.crefPrefixDer(name);
      then (name,false);
    case DAE.UNARY(operator=DAE.UMINUS(_),exp=DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(componentRef=name)}))
      equation
       name = ComponentReference.crefPrefixDer(name);
    then (name,true);
    case DAE.UNARY(operator=DAE.UMINUS_ARR(_),exp=DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(componentRef=name)}))
      equation
       name = ComponentReference.crefPrefixDer(name);
    then (name,true);
  end match;
end getAlias1;

/* =======================================================
 *
 *  Section for functions that deals with VariablesArray
 *
 * =======================================================
 */

protected function vararrayList
"function: vararrayList
  Transforms a VariableArray to a Var list"
  input BackendDAE.VariableArray inVariableArray;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVariableArray)
    local
      array<Option<BackendDAE.Var>> arr;
      BackendDAE.Var elt;
      Integer n,size;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = 0,varOptArr = arr)) then {};
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = 1,varOptArr = arr))
      equation
        SOME(elt) = arr[1];
      then
        {elt};
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr))
      then
        vararrayList2(arr, n, {});
  end matchcontinue;
end vararrayList;

protected function vararrayList2
"function: vararrayList2
  Helper function to vararrayList"
  input array<Option<BackendDAE.Var>> arr;
  input Integer pos;
  input list<BackendDAE.Var> inVarLst;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (arr,pos,inVarLst)
    local
      BackendDAE.Var v;
    case (_,0,_) then inVarLst;
    case (_,_,_)
      equation
        SOME(v) = arr[pos];
      then
        vararrayList2(arr,pos-1,v::inVarLst);
    case (_,_,_)
      then
        vararrayList2(arr,pos-1,inVarLst);
  end matchcontinue;
end vararrayList2;

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
  crefIdxLstArr1 := arrayCreate(bucketSize, {});
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
        arr_1 = arrayUpdate(arr, n_1, SOME(v));
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
        arr_2 = arrayUpdate(arr_1, n_1, SOME(v));
      then
        BackendDAE.VARIABLE_ARRAY(n_1,newsize,arr_2);
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),_)
      equation
        print("- vararrayAdd failed\nn: " +& intString(n) +& ", size: " +& intString(size) +& " arraysize: " +& intString(arrayLength(arr)) +& "\n");
        Debug.execStat("vararrayAdd",CevalScript.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
      then
        fail();
    case (_,_)
      equation
        print("- vararrayAdd failed!\n");
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
  input Integer pos "1 Based";
  input BackendDAE.Var inVar;
  output BackendDAE.VariableArray outVariableArray;
algorithm
  outVariableArray := matchcontinue (inVariableArray,pos,inVar)
    local
      array<Option<BackendDAE.Var>> arr;
      Integer n,size;

    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),_,_)
      equation
        true = intLe(pos,size);
        arr = arrayUpdate(arr, pos, SOME(inVar));
      then
        BackendDAE.VARIABLE_ARRAY(n,size,arr);

    else
      equation
        print("- vararraySetnth failed at " +& intString(pos)  +& "\n");
      then
        fail();
  end matchcontinue;
end vararraySetnth;

protected function vararrayNth
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
        print("- BackendVariable.vararrayNth " +& intString(pos +1 ) +& " has NONE!!!\n");
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

public function emptyVars "function emptyVars
  author: PA
  Returns a Variable datastructure that is empty.
  Using the bucketsize 10000 and array size 1000."
  output BackendDAE.Variables outVariables;
protected
  array<list<BackendDAE.CrefIndex>> arr;
  list<Option<BackendDAE.Var>> lst;
  array<Option<BackendDAE.Var>> emptyarr;
  Integer bucketSize, arrSize;
algorithm
  bucketSize := BaseHashTable.bigBucketSize;
  arrSize := bucketSize; // BaseHashTable.bucketToValuesSize(bucketSize);
  arr := arrayCreate(bucketSize, {});
  emptyarr := arrayCreate(arrSize, NONE());
  outVariables := BackendDAE.VARIABLES(arr,BackendDAE.VARIABLE_ARRAY(0, arrSize, emptyarr), bucketSize, 0);
end emptyVars;

public function emptyVarsSized "function emptyVarsSized
  author: Frenkel TUD 2013-02
  Returns a Variable datastructure that is empty.
  Using the bucketsize 10000 and array size 1000."
  input Integer size;
  output BackendDAE.Variables outVariables;
protected
  array<list<BackendDAE.CrefIndex>> arr;
  list<Option<BackendDAE.Var>> lst;
  array<Option<BackendDAE.Var>> emptyarr;
  Integer bucketSize, arrSize;
algorithm
  arrSize := intMax(BaseHashTable.lowBucketSize,size);
  bucketSize := realInt(realMul(intReal(arrSize), HASHVECFACTOR));
  arr := arrayCreate(bucketSize, {});
  emptyarr := arrayCreate(arrSize, NONE());
  outVariables := BackendDAE.VARIABLES(arr,BackendDAE.VARIABLE_ARRAY(0, arrSize, emptyarr), bucketSize, 0);
end emptyVarsSized;

public function varList
"function: varList
  Takes BackendDAE.Variables and returns a list of \'Var\', useful for e.g. dumping."
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := match(inVariables)
    local
      list<BackendDAE.Var> varlst;
      BackendDAE.VariableArray vararr;

    case (BackendDAE.VARIABLES(varArr = vararr)) equation
      varlst = vararrayList(vararr);
    then varlst;
  end match;
end varList;

public function listVar
"function: listVar
  author: PA
  Takes Var list and creates a BackendDAE.Variables structure, see also var_list."
  input list<BackendDAE.Var> inVarLst;
  output BackendDAE.Variables outVariables;
protected
  Integer size;
algorithm
  size := listLength(inVarLst);
  outVariables := emptyVarsSized(size);
  outVariables := List.fold(listReverse(inVarLst),addVar,outVariables);
end listVar;

public function listVarSized "function listVarSized
  author: Frenkel TUD 2012-05
  Takes BackendDAE.Var list and creates a BackendDAE.Variables structure, see also var_list."
  input list<BackendDAE.Var> inVarLst;
  input Integer size;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := List.fold(inVarLst,addVar,emptyVarsSized(size));
end listVarSized;

public function listVar1 "function listVar1
  author: Frenkel TUD 2012-05
  ToDo: replace all listVar calls with this function, tailrecursive implementation
  Takes BackendDAE.Var list and creates a BackendDAE.Variables structure, see also var_list."
  input list<BackendDAE.Var> inVarLst;
  output BackendDAE.Variables outVariables;
protected
  Integer size;
algorithm
  size := listLength(inVarLst);
  outVariables := List.fold(inVarLst,addVar,emptyVarsSized(size));
end listVar1;

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
          vars = varList(v);
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
  input BackendDAE.Shared shared;
  output BackendDAE.Variables vars;
algorithm
  BackendDAE.SHARED(aliasVars = vars) := shared;
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
    local Integer n;
    case (BackendDAE.VARIABLES(numberOfVars = n)) then n;
  end match;
end varsSize;

public function resizeVars "function: resizeVars
  author: Frenkel TUD

  check the number of vars and the bucketSize and expand the bucketSize if neccessary.
  (Shure the hashentries also updated)
"
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
protected
 Integer numberOfVars,bucketSize,size;
 BackendDAE.VariableArray varArr;
algorithm
  BackendDAE.VARIABLES(numberOfVars = numberOfVars,bucketSize = bucketSize,varArr=varArr) := inVariables;
  size := realInt(realMul(intReal(numberOfVars), HASHVECFACTOR));
  outVariables := Debug.bcallret2(intGt(numberOfVars,bucketSize),resizeVars1,varArr,numberOfVars,inVariables);
end resizeVars;

protected function resizeVars1 "function: resizeVars
  author: Frenkel TUD

  check the number of vars and the bucketSize and expand the bucketSize if neccessary.
  (Shure the hashentries also updated)
"
  input BackendDAE.VariableArray inVariables;
  input Integer numberOfVars;
  output BackendDAE.Variables outVariables;
protected
  Integer arrSize,bucketSize;
  array<list<BackendDAE.CrefIndex>> arr;
  array<Option<BackendDAE.Var>> varOptArr;
algorithm
  BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr) := inVariables;
  arrSize:=intMax(BaseHashTable.lowBucketSize, numberOfVars);
  bucketSize:=realInt(realMul(intReal(arrSize), HASHVECFACTOR));
  arr:=arrayCreate(bucketSize, {});
  arr := resizeVars2(numberOfVars,varOptArr,bucketSize,arr);
  outVariables := BackendDAE.VARIABLES(arr,inVariables, bucketSize, numberOfVars);
end resizeVars1;

protected function resizeVars2
"function: resizeVars2
  author: Frenkel TUD"
  input Integer index;
  input array<Option<BackendDAE.Var>> varOptArr;
  input Integer bucketSize;
  input array<list<BackendDAE.CrefIndex>> iArr;
  output array<list<BackendDAE.CrefIndex>> oArr;
algorithm
  oArr := match (index,varOptArr,bucketSize,iArr)
    local
      array<list<BackendDAE.CrefIndex>> arr;
    case (0,_,_,_) then iArr;
    case (_,_,_,_)
      equation
        arr = resizeVars3(varOptArr[index],index,bucketSize,iArr);
      then 
        resizeVars2(index-1,varOptArr,bucketSize,arr);
  end match;
end resizeVars2;

protected function resizeVars3
"function: resizeVars3
  author: Frenkel TUD"
  input Option<BackendDAE.Var> inVar;
  input Integer pos;
  input Integer bucketSize;
  input array<list<BackendDAE.CrefIndex>> iArr;
  output array<list<BackendDAE.CrefIndex>> oArr;
algorithm
  oArr := match (inVar,pos,bucketSize,iArr)
    local
      Integer indx,indx_1,pos_1;
      list<BackendDAE.CrefIndex> indexes;
      array<list<BackendDAE.CrefIndex>> hashvec;
      DAE.ComponentRef cr;
    case (NONE(),_,_,_) then iArr;
    case (SOME(BackendDAE.VAR(varName = cr)),_,_,_)
      equation
        indx = ComponentReference.hashComponentRefMod(cr, bucketSize);
        indx_1 = indx + 1;
        indexes = iArr[indx_1];
        pos_1 = pos - 1;
        hashvec = arrayUpdate(iArr, indx_1, (BackendDAE.CREFINDEX(cr,pos_1) :: indexes));
      then
        hashvec;
  end match;
end resizeVars3;

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
    case (BackendDAE.STATE(index=_)) then ();
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

public function deleteCrefs "function deleteCrefs
  author: wbraun
  Removes a list of DAE.ComponentRef from BackendDAE.Variables"
  input list<DAE.ComponentRef> varlst;
  input BackendDAE.Variables vars;
  output BackendDAE.Variables vars_1;
algorithm
  vars_1 := List.fold(varlst, removeCref, vars);
  vars_1 := listVar1(varList(vars_1));
end deleteCrefs;

public function deleteVars "function deleteVars
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
        newvars = listVar1(varList(newvars));
      then
        newvars;
    else
      then
        inVariables;
  end matchcontinue;
end deleteVars;

protected function deleteVars1
"author: Frenkel TUD 2010-11"
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
  outVariables := match(inComponentRef,inVariables)
    local
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      list<Integer> ilst;

    case (cr,_) equation
      (_,ilst) = getVar(cr,inVariables);
      (vars,_) = removeVars(ilst,inVariables,{});
      vars = listVar1(varList(vars));
    then vars;
  end match;
end deleteVar;

public function removeCrefs "function removeCrefs
  author: wbraun
  Removes a list of DAE.ComponentRef from BackendDAE.Variables"
  input list<DAE.ComponentRef> varlst;
  input BackendDAE.Variables vars;
  output BackendDAE.Variables vars_1;
algorithm
  vars_1 := List.fold(varlst, removeCref, vars);
end removeCrefs;

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

public function removeVars "function removeVars
  author: Frenkel TUD 2012-09
  Removes vars from the vararray but does not scaling down the array"
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

public function removeVarDAE
"function: removeVarDAE
  author: Frenkel TUD 2012-11
  Removes a var from the vararray but does not scaling down the array"
  input Integer inVarPos "1 based index";
  input BackendDAE.EqSystem syst;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Var outVar;
algorithm
  (osyst,outVar) := match (inVarPos,syst)
    local
      BackendDAE.Var var;
      BackendDAE.Variables ordvars,ordvars1;
      BackendDAE.EquationArray eqns;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
    case (_,BackendDAE.EQSYSTEM(ordvars,eqns,m,mT,matching,stateSets=stateSets))
      equation
        (ordvars1,outVar) = removeVar(inVarPos,ordvars);
      then (BackendDAE.EQSYSTEM(ordvars1,eqns,m,mT,matching,stateSets),outVar);
  end match;
end removeVarDAE;

public function removeVar "function removeVar
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
        hashindx = ComponentReference.hashComponentRefMod(cr, bsize);
        indexes = hashvec[hashindx + 1];
        (indexes1,_) = List.deleteMemberOnTrue(BackendDAE.CREFINDEX(cr,pos_1),indexes,removeVar2);
        hashvec_1 = arrayUpdate(hashvec, hashindx + 1, indexes1);
        //fastht = BaseHashTable.delete(cr, fastht);
      then
        (BackendDAE.VARIABLES(hashvec_1,varr1,bsize,n),v);
    case (pos,_)
      equation
        print("- removeVar failed for var ");
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
        print("- removeVar1 failed\n Pos " +& intString(inInteger) +& " numberOfElements " +& intString(n) +& " size " +& intString(size) +& " arraySize " +& intString(arrayLength(arr)) +& "\n");
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

public function compressVariables
" function: compressVariables
  author: Frenkel TUD 2012-09
  Closes the gabs "
  input BackendDAE.Variables iVars;
  output BackendDAE.Variables oVars;
algorithm
  oVars := matchcontinue(iVars)
    local
      Integer arrSize,size;
      array<Option<BackendDAE.Var>> varOptArr;
    case(BackendDAE.VARIABLES(varArr=BackendDAE.VARIABLE_ARRAY(numberOfElements=arrSize,varOptArr=varOptArr),numberOfVars=size))
      equation
        oVars = emptyVarsSized(size);
      then
        compressVariables1(1,size,varOptArr,oVars);
    else
      equation
        print("BackendVariable.compressVariables failed\n");
      then
        fail();     
  end matchcontinue;
end compressVariables;

protected function compressVariables1
" function: compressVariables1
  author: Frenkel TUD 2012-09"
  input Integer index;
  input Integer nVars;
  input array<Option<BackendDAE.Var>> varOptArr;
  input BackendDAE.Variables iVars;
  output BackendDAE.Variables oVars;
algorithm
  oVars := matchcontinue(index,nVars,varOptArr,iVars)
    local
      BackendDAE.Var var;
      BackendDAE.Variables vars;
    // found element
    case(_,_,_,_)
      equation
        true = intLe(index,nVars);
        SOME(var) = varOptArr[index];
        vars = addVar(var,iVars);
      then
        compressVariables1(index+1,nVars,varOptArr,vars);
    // found non element
    case(_,_,_,_)
      equation
        true = intLe(index,nVars);
        NONE() = varOptArr[index];
      then
        compressVariables1(index+1,nVars,varOptArr,iVars);
    // at the end
    case(_,_,_,_)
      equation
        false = intLe(index,nVars);
      then
        iVars;
    else
      equation
        print("BackendVariable.compressVariables1 failed for index " +& intString(index) +& " and Number of Variables " +& intString(nVars) +& "\n");
      then
        fail();
  end matchcontinue;
end compressVariables1;

public function existsVar
"function: existsVar
  author: PA
  Return true if a variable exists in the vector"
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  input Boolean skipDiscrete;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inComponentRef,inVariables,skipDiscrete)
    local
      list<BackendDAE.Var> varlst;
    case (_,_,_)
      equation
        (varlst,_) = getVar(inComponentRef,inVariables);
        varlst = Debug.bcallret2(skipDiscrete, List.select, varlst, isVarNonDiscrete, varlst);
      then
        List.isNotEmpty(varlst);
    case (_,_,_)
      equation
        failure((_,_) = getVar(inComponentRef,inVariables));
      then
        false;
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
      BackendDAE.Variables ordvars,ordvars1;
      BackendDAE.EquationArray eqns;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
    case (_,BackendDAE.EQSYSTEM(ordvars,eqns,m,mT,matching,stateSets))
      equation
        ordvars1 = addVar(inVar,ordvars);
      then BackendDAE.EQSYSTEM(ordvars1,eqns,m,mT,matching,stateSets);
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
    case (_,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs))
      equation
        knvars1 = addVar(inVar,knvars);
      then BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs);
  end match;
end addKnVarDAE;

public function addNewKnVarDAE
"function: addNewKnVarDAE
  author: Frenkel TUD 2011-04
  Add a variable to Variables of a BackendDAE.
  No Check if variable already exist. Use only for new variables"
  input BackendDAE.Var inVar;
  input BackendDAE.Shared shared;
  output BackendDAE.Shared oshared;
algorithm
  oshared := match (inVar,shared)
    local
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
    case (_,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs))
      equation
        knvars1 = addNewVar(inVar,knvars);
      then BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs);
  end match;
end addNewKnVarDAE;

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
    case (_,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs))
      equation
        aliasVars = addVar(inVar,aliasVars);
      then BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs);
  end match;
end addAliasVarDAE;

public function addNewAliasVarDAE
"function: addNewAliasVarDAE
  author: Frenkel TUD 2012-09
  Add a alias variable to Variables of a BackendDAE.Shared
  No Check if variable already exist. Use only for new variables"
  input BackendDAE.Var inVar;
  input BackendDAE.Shared shared;
  output BackendDAE.Shared oshared;
algorithm
  oshared := match (inVar,shared)
    local
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
    case (_,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs))
      equation
        aliasVars = addNewVar(inVar,aliasVars);
      then BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs);
  end match;
end addNewAliasVarDAE;

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
        indx = ComponentReference.hashComponentRefMod(cr, bsize);
        indx_1 = indx + 1;
        newpos = vararrayLength(varr);
        varr_1 = vararrayAdd(varr, v);
        indexes = hashvec[indx_1];
        hashvec_1 = arrayUpdate(hashvec, indx_1, (BackendDAE.CREFINDEX(cr,newpos) :: indexes));
        n_1 = vararrayLength(varr_1);
        //fastht = BaseHashTable.add((cr,{newpos}),fastht);
      then
        BackendDAE.VARIABLES(hashvec_1,varr_1,bsize,n_1);

    case ((newv as BackendDAE.VAR(varName = cr)),(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        (_,{indx}) = getVar(cr, vars);
        // print("adding when already present => Updating value\n");
        varr_1 = vararraySetnth(varr, indx, newv);
      then
        BackendDAE.VARIABLES(hashvec,varr_1,bsize,n);

    else
      equation
        print("- addVar failed\n");
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
        indx = ComponentReference.hashComponentRefMod(cr, bsize);
        newpos = vararrayLength(varr);
        varr_1 = vararrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, (BackendDAE.CREFINDEX(cr,newpos) :: indexes));
        n_1 = vararrayLength(varr_1);
      then
        BackendDAE.VARIABLES(hashvec_1,varr_1,bsize,n_1);

    case (_,_)
      equation
        print("- addNewVar failed\n");
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
      BackendDAE.StateSets stateSets;
    case (_,BackendDAE.EQSYSTEM(ordvars,eqns,m,mT,matching,stateSets))
      equation
        ordvars1 = expandVars(needed,ordvars);
      then BackendDAE.EQSYSTEM(ordvars1,eqns,m,mT,matching,stateSets);
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
        print("- expandVars failed\n");
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
      Integer pos;
      BackendDAE.Var v;
      BackendDAE.VariableArray vararr;
    case (BackendDAE.VARIABLES(varArr = vararr),_)
      equation
        pos = inInteger - 1;
        v = vararrayNth(vararr, pos);
      then
        v;
    case (BackendDAE.VARIABLES(varArr = vararr),_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "getVarAt failed to get the variable at index:" +& intString(inInteger));
      then
        fail();
  end matchcontinue;
end getVarAt;

public function setVarAt
"function: setVarAt
  author: Frenkel TUD
  set variable at a given position, enumerated from 1..n"
  input BackendDAE.Variables inVariables;
  input Integer pos;
  input BackendDAE.Var inVar;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVariables,pos,inVar)
    local
      array<list<BackendDAE.CrefIndex>> crefIdxLstArr;
      BackendDAE.VariableArray varArr;
      Integer bucketSize,numberOfVars;
    case (BackendDAE.VARIABLES(crefIdxLstArr=crefIdxLstArr,varArr=varArr,bucketSize=bucketSize,numberOfVars=numberOfVars),_,_)
      equation
        varArr = vararraySetnth(varArr, pos, inVar);
      then
        BackendDAE.VARIABLES(crefIdxLstArr,varArr,bucketSize,numberOfVars);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "setVarAt failed to set the variable at index:" +& intString(pos));
      then
        fail();
  end matchcontinue;
end setVarAt;

public function getVarSharedAt
"function: getVarSharedAt
  author: Frenkel TUD 2012-12
  return a Variable."
  input Integer inInteger;
  input BackendDAE.Shared shared;
  output BackendDAE.Var outVar;
protected
  BackendDAE.Variables vars;
algorithm
  BackendDAE.SHARED(knownVars=vars) := shared;
  outVar := getVarAt(vars,inInteger);
end getVarSharedAt;

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

public function getVarShared
"function: getVarShared
  author: Frenkel TUD 2012-05
  return a Variable."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Shared shared;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := match (inComponentRef,shared)
    local
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varlst;
      list<Integer> indxlst;
   case (_,BackendDAE.SHARED(knownVars=vars))
      equation
        (varlst,indxlst) = getVar(inComponentRef,vars);
      then
        (varlst,indxlst);
  end match;
end getVarShared;

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
      DAE.ComponentRef cr1;
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
    // try again check if variable indexes used
    case (_,_)
      equation
        // replace variables with WHOLEDIM()
        (cr1,true) = replaceVarWithWholeDim(cr, false);
        crlst = ComponentReference.expandCref(cr1,true);
        (vLst as _::_,indxs) = getVarLst(crlst,inVariables,{},{});
      then
        (vLst,indxs);        
    /* failure
    case (_,_)
      equation
        Debug.fprintln(Flags.DAE_LOW, "- getVar failed on component reference: " +& ComponentReference.printComponentRefStr(cr));
      then
        fail();
     */
  end matchcontinue;
end getVar;

protected function replaceVarWithWholeDim
  "Helper function to traverseExp. Traverses any expressions in a
  component reference (i.e. in it's subscripts)."
  input DAE.ComponentRef inCref;
  input Boolean iPerformed;
  output DAE.ComponentRef outCref;
  output Boolean oPerformed;
algorithm
  (outCref, oPerformed) := match(inCref, iPerformed)
    local
      DAE.Ident name;
      DAE.ComponentRef cr,cr_1;
      DAE.Type ty;
      list<DAE.Subscript> subs,subs_1;
      Boolean b;

    case (DAE.CREF_QUAL(ident = name, identType = ty, subscriptLst = subs, componentRef = cr), _)
      equation
        (subs_1, b) = replaceVarWithWholeDimSubs(subs, iPerformed);
        (cr_1, b) = replaceVarWithWholeDim(cr, b);
      then
        (DAE.CREF_QUAL(name, ty, subs_1, cr_1), b);

    case (DAE.CREF_IDENT(ident = name, identType = ty, subscriptLst = subs), _)
      equation
        (subs_1, b) = replaceVarWithWholeDimSubs(subs, iPerformed);
      then
        (DAE.CREF_IDENT(name, ty, subs_1), b);

    case (DAE.CREF_ITER(ident = _), _) then (inCref, iPerformed);
    case (DAE.OPTIMICA_ATTR_INST_CREF(componentRef = _), _) then (inCref, iPerformed);
    case (DAE.WILD(), _) then (inCref, iPerformed);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"BackendVariable.replaceVarWithWholeDim: Unknown cref"});
      then fail();
  end match;
end replaceVarWithWholeDim;

protected function replaceVarWithWholeDimSubs
  input list<DAE.Subscript> inSubscript;
  input Boolean iPerformed;
  output list<DAE.Subscript> outSubscript;
  output Boolean oPerformed;
algorithm
  (outSubscript, oPerformed) := match(inSubscript, iPerformed)
    local
      DAE.Exp sub_exp;
      list<DAE.Subscript> rest,res;
      Boolean b,const;

    case ({}, _) then (inSubscript,iPerformed);
    case (DAE.WHOLEDIM()::rest, _)
      equation
        (res,b) = replaceVarWithWholeDimSubs(rest,iPerformed);
      then (DAE.WHOLEDIM()::rest, b);

    case (DAE.SLICE(exp = sub_exp)::rest, _)
      equation
        (res,b) = replaceVarWithWholeDimSubs(rest,iPerformed);
        const = Expression.isConst(sub_exp);
        res = Util.if_(const,DAE.SLICE(sub_exp)::rest,DAE.WHOLEDIM()::rest);
      then
        (res, b or not const);

    case (DAE.INDEX(exp = sub_exp)::rest, _)
      equation
        (res,b) = replaceVarWithWholeDimSubs(rest,iPerformed);
        const = Expression.isConst(sub_exp);
        res = Util.if_(const,DAE.INDEX(sub_exp)::rest,DAE.WHOLEDIM()::rest);
      then
        (res, b or not const);

    case (DAE.WHOLE_NONEXP(exp = sub_exp)::rest, _)
      equation
        (res,b) = replaceVarWithWholeDimSubs(rest,iPerformed);
        const = Expression.isConst(sub_exp);
        res = Util.if_(const,DAE.WHOLE_NONEXP(sub_exp)::rest,DAE.WHOLEDIM()::rest);
      then
        (res, b or not const);
  end match;
end replaceVarWithWholeDimSubs;

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
        hashindx = ComponentReference.hashComponentRefMod(cr, bsize);
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
"author: Frenkel TUD 2010-11"
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
"author: Frenkel TUD 2010-11"
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
      BackendDAE.Variables vars1_1,vars1,vars2;
    case (vars1,vars2)
      equation
        // to avoid side effects from arrays copy first
        vars1_1 = emptyVarsSized(varsSize(vars1)+varsSize(vars2));
        vars1_1 = traverseBackendDAEVars(vars1, mergeVariables1, vars1_1);
        vars1_1 = traverseBackendDAEVars(vars2, mergeVariables1, vars1_1);
      then
        vars1_1;
    case (_,_)
      equation
        print("- mergeVariables failed\n");
      then
        fail();
  end matchcontinue;
end mergeVariables;

protected function mergeVariables1
"author: Frenkel TUD 2013-02"
 input tuple<BackendDAE.Var, BackendDAE.Variables> inTpl;
 output tuple<BackendDAE.Var, BackendDAE.Variables> outTpl;
protected
 BackendDAE.Var v;
 BackendDAE.Variables vars;
algorithm
  (v,vars) := inTpl;
  vars := addVar(v,vars);
  outTpl := (v,vars);
end mergeVariables1;

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
        Debug.fprintln(Flags.FAILTRACE, "- traverseBackendDAEVars failed");
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
        Debug.fprintln(Flags.FAILTRACE, "- traverseBackendDAEVarsWithStop failed");
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
        Debug.fprintln(Flags.FAILTRACE, "- traverseBackendDAEVar failed");
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
        Debug.fprintln(Flags.FAILTRACE, "- traverseBackendDAEVarWithStop failed");
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
        Debug.fprintln(Flags.FAILTRACE, "- traverseBackendDAEVarsWithUpdate failed");
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
    case (ovar as NONE(),_,_) then (ovar,inTypeA);
    case (ovar as SOME(v),_,_)
      equation
        ((v1,ext_arg)) = func((v,inTypeA));
        ovar = Util.if_(referenceEq(v,v1),ovar,SOME(v1));
      then
        (ovar,ext_arg);
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- traverseBackendDAEVar failed");
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
"author: Frenkel TUD 2010-11"
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
"author: Frenkel TUD 2010-11"
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
    else inTpl;
  end matchcontinue;
end traversingisisVarDiscreteFinder;

public function getAllStateVarFromVariables
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> v_lst;
algorithm
  v_lst := traverseBackendDAEVars(inVariables,traversingisStateVarFinder,{});
end getAllStateVarFromVariables;

protected function traversingisStateVarFinder
"author: Frenkel TUD 2010-11"
  input tuple<BackendDAE.Var, list<BackendDAE.Var>> inTpl;
  output tuple<BackendDAE.Var, list<BackendDAE.Var>> outTpl;
protected
  BackendDAE.Var v;
  list<BackendDAE.Var> v_lst;
algorithm
  (v,v_lst) := inTpl;
  v_lst := List.consOnTrue(isStateVar(v),v,v_lst);
  outTpl := (v,v_lst);
end traversingisStateVarFinder;

public function getAllStateVarIndexFromVariables
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> v_lst;
  output list<Integer> i_lst;
algorithm
  ((v_lst,i_lst,_)) := traverseBackendDAEVars(inVariables,traversingisStateVarIndexFinder,({},{},1));
end getAllStateVarIndexFromVariables;

protected function traversingisStateVarIndexFinder
"author: Frenkel TUD 2010-11"
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

public function mergeAliasVars
"author: Frenkel TUD 2011-04"
  input BackendDAE.Var inVar;
  input BackendDAE.Var inAVar "the alias var";
  input Boolean negate;
  input BackendDAE.Variables knVars "the KnownVars, needd to report Warnings";
  output BackendDAE.Var outVar;
protected
  BackendDAE.Var v,va,v1,v2;
  Boolean fixed,fixeda,f;
  Option<DAE.Exp> sv,sva,so,soa;
  DAE.Exp start;
algorithm
  // get attributes
  // fixed
  fixed := varFixed(inVar);
  fixeda := varFixed(inAVar);
  // start
  sv := varStartValueOption(inVar);
  sva := varStartValueOption(inAVar);
  so := varStartOrigin(inVar);
  soa := varStartOrigin(inAVar);
  v1 := mergeStartFixed(inVar,fixed,sv,so,inAVar,fixeda,sva,soa,negate,knVars);
  // nominal
  v2 := mergeNominalAttribute(inAVar,v1,negate);
  // minmax
  outVar := mergeMinMaxAttribute(inAVar,v2,negate);
end mergeAliasVars;

protected function mergeStartFixed
"author: Frenkel TUD 2011-04"
  input BackendDAE.Var inVar;
  input Boolean fixed;
  input Option<DAE.Exp> sv;
  input Option<DAE.Exp> so;
  input BackendDAE.Var inAVar;
  input Boolean fixeda;
  input Option<DAE.Exp> sva;
  input Option<DAE.Exp> soa;
  input Boolean negate;
  input BackendDAE.Variables knVars "the KnownVars, needd to report Warnings";
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  matchcontinue (inVar,fixed,sv,so,inAVar,fixeda,sva,soa,negate,knVars)
    local
      BackendDAE.Var v,va,v1,v2;
      DAE.ComponentRef cr,cra;
      DAE.Exp sa,sb,e;
      Integer i,ia;
      Option<DAE.Exp> origin;
      DAE.Type ty,tya;
      Option<DAE.VariableAttributes> attr,attra;
    // legal cases one fixed the other one not fixed, use the fixed one
    case (v,true,_,_,_,false,_,_,_,_)
      then v;
    case (v,false,_,_,va,true,SOME(sb),_,_,_)
      equation
        e = Debug.bcallret1(negate,Expression.negate,sb,sb);
        v1 = setVarStartValue(v,e);
        v2 = setVarFixed(v1,true);
      then v2;
    case (v,false,NONE(),_,va,true,NONE(),_,_,_)
      equation
        v1 = setVarFixed(v,true);
      then v1;
    case (v,false,SOME(sa),_,va,true,NONE(),_,_,_)
      equation
        v1 = setVarStartValueOption(v,NONE());
        v1 = setVarFixed(v,true);
      then v1;
    // legal case both fixed=false
    case (v,false,NONE(),_,va,false,NONE(),_,_,_)
      then v;
    case (v,false,SOME(sa),_,va,false,NONE(),_,_,_)
      then v;
    case (v,false,NONE(),_,va,false,SOME(sb),_,_,_)
      equation
        e = Debug.bcallret1(negate,Expression.negate,sb,sb);
        v1 = setVarStartValue(v,e);
      then v1;
    case (v as BackendDAE.VAR(varName=cr,varType=ty,values = attr),false,_,_,va as BackendDAE.VAR(varName=cra,varType=tya,values = attra),false,_,_,_,_)
      equation
        sa = startValueType(sv,ty);
        sb = startValueType(sva,tya);
        e = Debug.bcallret1(negate,Expression.negate,sb,sb);
        (e,origin) = getNonZeroStart(false,sa,so,e,soa,knVars);
        v1 = setVarStartValue(v,e);
        v1 = setVarStartOrigin(v,origin);
      then v1;
    case (v as BackendDAE.VAR(varName=cr,varType=ty),false,_,_,va as BackendDAE.VAR(varName=cra,varType=tya),false,_,_,_,_)
      equation
        sa = startValueType(sv,ty);
        sb = startValueType(sva,tya);
        e = Debug.bcallret1(negate,Expression.negate,sb,sb);
        // according to MSL
        // use the value from the variable that is closer to the top of the
        // hierarchy i.e. A.B value has priority over X.Y.Z value!
        i = ComponentReference.crefDepth(cr);
        ia = ComponentReference.crefDepth(cra);
      then
        mergeStartFixed1(intLt(ia,i),v,cr,sa,cra,e,soa,negate," have start values ");
    // legal case both fixed = true and start exp equal
    case (v,true,NONE(),_,va,true,NONE(),_,_,_)
      then v;
    case (v as BackendDAE.VAR(varName=cr,varType=ty,values = attr),true,_,_,va as BackendDAE.VAR(varName=cra,varType=tya,values = attra),true,_,_,_,_)
      equation
        sa = startValueType(sv,ty);
        sb = startValueType(sva,tya);
        e = Debug.bcallret1(negate,Expression.negate,sb,sb);
        (e,origin) = getNonZeroStart(true,sa,so,e,soa,knVars);
        v1 = setVarStartValue(v,e);
        v1 = setVarStartOrigin(v,origin);
      then v1;
    // not legal case both fixed with unequal start values
    case (v as BackendDAE.VAR(varName=cr,varType=ty,values = attr),true,_,_,va as BackendDAE.VAR(varName=cra,varType=tya,values = attra),true,_,_,_,_)
      equation
        sa = startValueType(sv,ty);
        sb = startValueType(sva,tya);
        e = Debug.bcallret1(negate,Expression.negate,sb,sb);
        // overconstrained system report warning/error
        i = ComponentReference.crefDepth(cr);
        ia = ComponentReference.crefDepth(cra);
      then
        mergeStartFixed1(intLt(ia,i),v,cr,sa,cra,e,soa,negate," both fixed and have start values ");
  end matchcontinue;
end mergeStartFixed;

protected function startValueType
"author: Frenkel TUD 2012-10
  return the start value or the default value in case of NONE()"
  input Option<DAE.Exp> iExp;
  input DAE.Type iTy;
  output DAE.Exp oExp;
algorithm
  oExp := matchcontinue(iExp,iTy)
    local
      DAE.Exp e;
    case(SOME(e),_) then e;
    case(NONE(),_)
      equation
        true = Types.isRealOrSubTypeReal(iTy);
      then
        DAE.RCONST(0.0);
    case(NONE(),_)
      equation
        true = Types.isIntegerOrSubTypeInteger(iTy);
      then
        DAE.ICONST(0);
    case(NONE(),_)
      equation
        true = Types.isBooleanOrSubTypeBoolean(iTy);
      then
        DAE.BCONST(false);
    case(NONE(),_)
      equation
        true = Types.isStringOrSubTypeString(iTy);
      then
        DAE.SCONST("");
    else
      then
        DAE.RCONST(0.0);
  end matchcontinue;
end startValueType;

protected function mergeStartFixed1 "function mergeStartFixed1
  author: Frenkel TUD 2011-04"
  input Boolean b "true if Alias Var have less dots in the name";
  input BackendDAE.Var inVar;
  input DAE.ComponentRef cr;
  input DAE.Exp sv;
  input DAE.ComponentRef cra;
  input DAE.Exp sva;
  input Option<DAE.Exp> soa;
  input Boolean negate;
  input String s4;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  match (b,inVar,cr,sv,cra,sva,soa,negate,s4)
    local
      String s,s1,s2,s3,s5,s6;
      BackendDAE.Var v;
    // alias var has more dots in the name
    case (false,_,_,_,_,_,_,_,_)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = Util.if_(negate," = -"," = ");
        s3 = ComponentReference.printComponentRefStr(cra);
        s5 = ExpressionDump.printExpStr(sv);
        s6 = ExpressionDump.printExpStr(sva);
        s = stringAppendList({"Alias variables ",s1,s2,s3,s4,s5," != ",s6,". Use value from ",s1,"."});
        Error.addMessage(Error.COMPILER_WARNING,{s});
      then
        inVar;
    case (true,_,_,_,_,_,_,_,_)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = Util.if_(negate," = -"," = ");
        s3 = ComponentReference.printComponentRefStr(cra);
        s5 = ExpressionDump.printExpStr(sv);
        s6 = ExpressionDump.printExpStr(sva);
        s = stringAppendList({"Alias variables ",s1,s2,s3,s4,s5," != ",s6,". Use value from ",s3,"."});
        Error.addMessage(Error.COMPILER_WARNING,{s});
        v = setVarStartValue(inVar,sva);
        v = setVarStartOrigin(v,soa);
      then
        v;
  end match;
end mergeStartFixed1;

protected function replaceCrefWithBindExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean,HashSet.HashSet>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean,HashSet.HashSet>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      HashSet.HashSet hs;
    // true if crefs replaced in expression
    case ((DAE.CREF(componentRef=cr), (vars,_,hs)))
      equation
        // check for cyclic bindings in start value
        false = BaseHashSet.has(cr, hs);
        ({BackendDAE.VAR(bindExp = SOME(e))}, _) = getVar(cr, vars);
        hs = BaseHashSet.add(cr,hs);
        ((e, (_,_,hs))) = Expression.traverseExp(e, replaceCrefWithBindExp, (vars,false,hs));
      then
        ((e, (vars,true,hs)));
    // true if crefs in expression
    case ((e as DAE.CREF(componentRef=cr), (vars,_,hs)))
      then
        ((e, (vars,true,hs)));
    else then inTuple;
  end matchcontinue;
end replaceCrefWithBindExp;

protected function getNonZeroStart
"author: Frenkel TUD 2011-04"
  input Boolean mustBeEqual;
  input DAE.Exp exp1;
  input Option<DAE.Exp> so "StartOrigin";
  input DAE.Exp exp2;
  input Option<DAE.Exp> sao "StartOrigin";
  input BackendDAE.Variables knVars "the KnownVars, need to report Warnings";
  output DAE.Exp outExp;
  output Option<DAE.Exp> outStartOrigin;
algorithm
  (outExp,outStartOrigin) :=
  matchcontinue (mustBeEqual,exp1,so,exp2,sao,knVars)
    local
      DAE.Exp exp2_1,exp1_1;
      Integer i,ia;
      Boolean b1,b2;
      Option<DAE.Exp> origin;
    case (_,_,_,_,_,_)
      equation
        true = Expression.expEqual(exp1,exp2);
        // use highest origin
        i = startOriginToValue(so);
        ia = startOriginToValue(sao);
        origin = Util.if_(intGt(ia,i),sao,so);
      then (exp1,origin);
    case (false,_,_,_,_,_)
      equation
        // if one is bound and the other not use the bound one
        i = startOriginToValue(so);
        ia = startOriginToValue(sao);
        false = intEq(i,ia);
        ((exp1_1,origin)) = Util.if_(intGt(ia,i),(exp2,sao),(exp1,so));
      then
        (exp1_1,origin);
    case (_,_,_,_,_,_)
      equation
        // simple evaluation, by replace crefs with bind expressions recursivly
        ((exp1_1, (_,b1,_))) = Expression.traverseExp(exp1, replaceCrefWithBindExp, (knVars,false,HashSet.emptyHashSet()));
        ((exp2_1, (_,b2,_))) = Expression.traverseExp(exp2, replaceCrefWithBindExp, (knVars,false,HashSet.emptyHashSet()));
        (exp1_1,_) = ExpressionSimplify.condsimplify(b1,exp1_1);
        (exp2_1,_) = ExpressionSimplify.condsimplify(b2,exp2_1);
        true = Expression.expEqual(exp1_1, exp2_1);
        exp1_1 = Util.if_(b1,exp1,exp2);
        // use highest origin
        i = startOriginToValue(so);
        ia = startOriginToValue(sao);
        origin = Util.if_(intGt(ia,i),sao,so);
      then
        (exp1_1,origin);
  end matchcontinue;
end getNonZeroStart;

public function startOriginToValue
  input Option<DAE.Exp> startOrigin;
  output Integer i;
algorithm
  i := match(startOrigin)
    case NONE() then 0;
    case SOME(DAE.SCONST("undefined")) then 1;
    case SOME(DAE.SCONST("type")) then 2;
    case SOME(DAE.SCONST("binding")) then 3;
  end match;
end startOriginToValue;

protected function mergeNominalAttribute
  input BackendDAE.Var inAVar;
  input BackendDAE.Var inVar;
  input Boolean negate;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  matchcontinue (inAVar,inVar,negate)
    local
      BackendDAE.Var v,var,var1;
      DAE.Exp e,e_1,e1,esum,eaverage;
    case (v,var,_)
      equation
        // nominal
        e = varNominalValue(v);
        e1 = varNominalValue(var);
        e_1 = Debug.bcallret1(negate,Expression.negate,e,e);
        esum = Expression.makeSum({e_1,e1});
        eaverage = Expression.expDiv(esum,DAE.RCONST(2.0)); // Real is legal because only Reals have nominal attribute
        (eaverage,_) = ExpressionSimplify.simplify(eaverage);
        var1 = setVarNominalValue(var,eaverage);
      then var1;
    case (v,var,_)
      equation
        // nominal
        e = varNominalValue(v);
        e_1 = Debug.bcallret1(negate,Expression.negate,e,e);
        var1 = setVarNominalValue(var,e_1);
      then var1;
    case(_,_,_) then inVar;
  end matchcontinue;
end mergeNominalAttribute;

protected function mergeMinMaxAttribute
  input BackendDAE.Var inAVar;
  input BackendDAE.Var inVar;
  input Boolean negate;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  matchcontinue (inAVar,inVar,negate)
    local
      BackendDAE.Var v,var,var1;
      Option<DAE.VariableAttributes> attr,attr1;
      list<Option<DAE.Exp>> ominmax,ominmax1;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      DAE.ComponentRef cr,cr1;
    case (v as BackendDAE.VAR(values = attr),var as BackendDAE.VAR(values = attr1),_)
      equation
        // minmax
        ominmax = DAEUtil.getMinMax(attr);
        ominmax1 = DAEUtil.getMinMax(attr1);
        cr = varCref(v);
        cr1 = varCref(var);
        minMax = mergeMinMax(negate,ominmax,ominmax1,cr,cr1);
        var1 = setVarMinMax(var,minMax);
      then var1;
    case(_,_,_) then inVar;
  end matchcontinue;
end mergeMinMaxAttribute;

protected function mergeMinMax
  input Boolean negate;
  input list<Option<DAE.Exp>> ominmax;
  input list<Option<DAE.Exp>> ominmax1;
  input DAE.ComponentRef cr;
  input DAE.ComponentRef cr1;
  output tuple<Option<DAE.Exp>, Option<DAE.Exp>> outMinMax;
algorithm
  outMinMax :=
  match (negate,ominmax,ominmax1,cr,cr1)
    local
      Option<DAE.Exp> omin1,omax1,omin2,omax2;
      DAE.Exp min,max,min1,max1;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
    case (false,{omin1,omax1},{omin2,omax2},_,_)
      equation
        minMax = mergeMinMax1({omin1,omax1},{omin2,omax2});
        checkMinMax(minMax,cr,cr1,negate);
      then
        minMax;
    // in case of a=-b, min and max have to be changed and negated
    case (true,{SOME(min),SOME(max)},{omin2,omax2},_,_)
      equation
        min1 = Expression.negate(min);
        max1 = Expression.negate(max);
        minMax = mergeMinMax1({SOME(max1),SOME(min1)},{omin2,omax2});
        checkMinMax(minMax,cr,cr1,negate);
      then
        minMax;
    case (true,{NONE(),SOME(max)},{omin2,omax2},_,_)
      equation
        max1 = Expression.negate(max);
        minMax = mergeMinMax1({SOME(max1),NONE()},{omin2,omax2});
        checkMinMax(minMax,cr,cr1,negate);
      then
        minMax;
    case (true,{SOME(min),NONE()},{omin2,omax2},_,_)
      equation
        min1 = Expression.negate(min);
        minMax = mergeMinMax1({NONE(),SOME(min1)},{omin2,omax2});
        checkMinMax(minMax,cr,cr1,negate);
      then
        minMax;
  end match;
end mergeMinMax;

protected function checkMinMax
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>> minmax;
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Boolean negate;
algorithm
  _ :=
  matchcontinue (minmax,cr1,cr2,negate)
    local
      DAE.Exp min,max;
      String s,s1,s2,s3,s4,s5;
      Real rmin,rmax;
    case ((SOME(min),SOME(max)),_,_,_)
      equation
        rmin = Expression.expReal(min);
        rmax = Expression.expReal(max);
        true = realGt(rmin,rmax);
        s1 = ComponentReference.printComponentRefStr(cr1);
        s2 = Util.if_(negate," = -"," = ");
        s3 = ComponentReference.printComponentRefStr(cr2);
        s4 = ExpressionDump.printExpStr(min);
        s5 = ExpressionDump.printExpStr(max);
        s = stringAppendList({"Alias variables ",s1,s2,s3," with invalid limits min ",s4," > max ",s5});
        Error.addMessage(Error.COMPILER_WARNING,{s});
      then ();
    // no error
    else
      ();
  end matchcontinue;
end checkMinMax;

protected function mergeMinMax1
  input list<Option<DAE.Exp>> ominmax;
  input list<Option<DAE.Exp>> ominmax1;
  output tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
algorithm
  minMax :=
  match (ominmax,ominmax1)
    local
      DAE.Exp min,max,min1,max1,min_2,max_2,smin,smax;
    // (min,max),()
    case ({SOME(min),SOME(max)},{})
      then ((SOME(min),SOME(max)));
    case ({SOME(min),SOME(max)},{NONE(),NONE()})
      then ((SOME(min),SOME(max)));
    // (min,),()
    case ({SOME(min),NONE()},{})
      then ((SOME(min),NONE()));
    case ({SOME(min),NONE()},{NONE(),NONE()})
      then ((SOME(min),NONE()));
    // (,max),()
    case ({NONE(),SOME(max)},{})
      then ((NONE(),SOME(max)));
    case ({NONE(),SOME(max)},{NONE(),NONE()})
      then ((NONE(),SOME(max)));
    // (min,),(min,)
    case ({SOME(min),NONE()},{SOME(min1),NONE()})
      equation
        min_2 = Expression.expMaxScalar(min,min1);
        (smin,_) = ExpressionSimplify.simplify(min_2);
      then ((SOME(smin),NONE()));
    // (,max),(,max)
    case ({NONE(),SOME(max)},{NONE(),SOME(max1)})
      equation
        max_2 = Expression.expMinScalar(max,max1);
        (smax,_) = ExpressionSimplify.simplify(max_2);
      then ((NONE(),SOME(smax)));
    // (min,),(,max)
    case ({SOME(min),NONE()},{NONE(),SOME(max1)})
      then ((SOME(min),SOME(max1)));
    // (,max),(min,)
    case ({NONE(),SOME(max)},{SOME(min1),NONE()})
      then ((SOME(min1),SOME(max)));
    // (,max),(min,max)
    case ({NONE(),SOME(max)},{SOME(min1),SOME(max1)})
      equation
        max_2 = Expression.expMinScalar(max,max1);
        (smax,_) = ExpressionSimplify.simplify(max_2);
      then ((SOME(min1),SOME(smax)));
    // (min,max),(,max)
    case ({SOME(min),SOME(max)},{NONE(),SOME(max1)})
      equation
        max_2 = Expression.expMinScalar(max,max1);
        (smax,_) = ExpressionSimplify.simplify(max_2);
      then ((SOME(min),SOME(smax)));
    // (min,),(min,max)
    case ({SOME(min),NONE()},{SOME(min1),SOME(max1)})
      equation
        min_2 = Expression.expMaxScalar(min,min1);
        (smin,_) = ExpressionSimplify.simplify(min_2);
      then ((SOME(smin),SOME(max1)));
    // (min,max),(min,)
    case ({SOME(min),SOME(max)},{SOME(min1),NONE()})
      equation
        min_2 = Expression.expMaxScalar(min,min1);
        (smin,_) = ExpressionSimplify.simplify(min_2);
      then ((SOME(smin),SOME(max)));
    // (min,max),(min,max)
    case ({SOME(min),SOME(max)},{SOME(min1),SOME(max1)})
      equation
        min_2 = Expression.expMaxScalar(min,min1);
        max_2 = Expression.expMinScalar(max,max1);
        (smin,_) = ExpressionSimplify.simplify(min_2);
        (smax,_) = ExpressionSimplify.simplify(max_2);
      then ((SOME(smin),SOME(smax)));
  end match;
end mergeMinMax1;

protected function mergeDirection
  input BackendDAE.Var inAVar;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  matchcontinue (inAVar,inVar)
    local
      BackendDAE.Var v,var,var1;
      Option<DAE.VariableAttributes> attr,attr1;
      DAE.Exp e,e1;
    case (v as BackendDAE.VAR(varDirection = DAE.INPUT()),var as BackendDAE.VAR(varDirection = DAE.OUTPUT()))
      equation
        var1 = setVarDirection(var,DAE.INPUT());
      then var1;
    case (v as BackendDAE.VAR(varDirection = DAE.INPUT()),var as BackendDAE.VAR(varDirection = DAE.BIDIR()))
      equation
        var1 = setVarDirection(var,DAE.INPUT());
      then var1;
    case (v as BackendDAE.VAR(varDirection = DAE.OUTPUT()),var as BackendDAE.VAR(varDirection = DAE.BIDIR()))
      equation
        var1 = setVarDirection(var,DAE.OUTPUT());
      then var1;
    case(_,_) then inVar;
  end matchcontinue;
end mergeDirection;

public function calcAliasKey "function calcAliasKey
  author Frenkel TUD 2011-04
  helper for selectAlias. This function is
  mainly usable to chose the favorite name
  of the keeped var"
  input BackendDAE.Var var;
  output Integer i;
protected
  DAE.ComponentRef cr;
  Boolean b;
  Integer d;
algorithm
  BackendDAE.VAR(varName=cr) := var;
  // records
  b := ComponentReference.isRecord(cr);
  i := Util.if_(b,-1,0);
  // array elements
  b := ComponentReference.isArrayElement(cr);
  i := intAdd(i,Util.if_(b,-1,0));
  // protected
  b := isProtectedVar(var);
  i := intAdd(i,Util.if_(b,5,0));
  // connectors
  b := isVarConnector(var);
  i := intAdd(i,Util.if_(b,1,0));
  // self generated var
  b := isDummyDerVar(var);
  i := intAdd(i,Util.if_(b,10,0));
  b := selfGeneratedVar(cr);
  i := intAdd(i,Util.if_(b,100,0));
  // length of name (number of dots)
  d := ComponentReference.crefDepth(cr);
  i := i+d;
end calcAliasKey;

public function selfGeneratedVar
  input DAE.ComponentRef inCref;
  output Boolean b;
algorithm
  b := match(inCref)
    local String ident;
    case DAE.CREF_QUAL(ident = "$ZERO") then true;
    case DAE.CREF_QUAL(ident = "$pDER") then true;
    case DAE.CREF_QUAL(ident = "$DER",componentRef=DAE.CREF_QUAL(ident = "$DER")) then true;
    // keep them a while untill we know which are needed
    //case DAE.CREF_QUAL(ident = "$DER") then true;
    case DAE.CREF_IDENT(ident = ident) then intEq(System.strncmp(ident,"$when",5),0);
    else then false;
  end match;
end selfGeneratedVar;

public function varStateSelectPrioAlias "function varStateSelectPrioAlias
  Helper function to calculateVarPriorities.
  Calculates a priority contribution bases on the stateSelect attribute."
  input BackendDAE.Var v;
  output Integer prio;
  protected
  DAE.StateSelect ss;
  Boolean knownDer;
algorithm
  ss := varStateSelect(v);
  prio := stateSelectToInteger(ss);
  knownDer := varHasStateDerivative(v);
  prio := prio*2;
  prio := Util.if_(knownDer,prio+1,prio);
end varStateSelectPrioAlias;

public function stateSelectToInteger "function stateSelectToInteger
  helper function to stateSelectToInteger
  return
  Never: -1
  Avoid: 0
  Default: 1
  Prefer: 2
  Always: 3"
  input DAE.StateSelect ss;
  output Integer prio;
algorithm
  prio := match(ss)
    case (DAE.NEVER()) then -1;
    case (DAE.AVOID()) then 0;
    case (DAE.DEFAULT()) then 1;
    case (DAE.PREFER()) then 2;
    case (DAE.ALWAYS()) then 3;
  end match;
end stateSelectToInteger;

end BackendVariable;

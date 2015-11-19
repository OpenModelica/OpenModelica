/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package InstBinding
" file:        InstBinding.mo
  package:     InstBinding
  description: Binding instantiation

  RCS: $Id: InstBinding.mo 17556 2013-10-05 23:58:57Z adrpo $

  This module is responsible for instantiation of bindings.
"

public import Absyn;
public import ClassInf;
public import DAE;
public import FCore;
public import FGraph;
public import InnerOuter;
public import Mod;
public import Prefix;
public import SCode;
public import Values;

protected type Ident = DAE.Ident "an identifier";
protected type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";
protected type InstDims = list<list<DAE.Dimension>>;

protected import Ceval;
protected import ComponentReference;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import InstUtil;
protected import List;
protected import Flags;
protected import Debug;
protected import DAEUtil;
protected import PrefixUtil;
protected import Types;
protected import InstSection;
protected import ValuesUtil;

public constant DAE.Type stateSelectType =
          DAE.T_ENUMERATION(NONE(),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},
          {
          DAE.TYPES_VAR("never",DAE.dummyAttrParam,
             DAE.T_ENUMERATION(SOME(1),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},{},{},DAE.emptyTypeSource),DAE.UNBOUND(),NONE()),
          DAE.TYPES_VAR("avoid",DAE.dummyAttrParam,
             DAE.T_ENUMERATION(SOME(2),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},{},{},DAE.emptyTypeSource),DAE.UNBOUND(),NONE()),
          DAE.TYPES_VAR("default",DAE.dummyAttrParam,
             DAE.T_ENUMERATION(SOME(3),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},{},{},DAE.emptyTypeSource),DAE.UNBOUND(),NONE()),
          DAE.TYPES_VAR("prefer",DAE.dummyAttrParam,
             DAE.T_ENUMERATION(SOME(4),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},{},{},DAE.emptyTypeSource),DAE.UNBOUND(),NONE()),
          DAE.TYPES_VAR("always",DAE.dummyAttrParam,
             DAE.T_ENUMERATION(SOME(5),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},{},{},DAE.emptyTypeSource),DAE.UNBOUND(),NONE())
          },{},DAE.emptyTypeSource);

public constant DAE.Type uncertaintyType =
          DAE.T_ENUMERATION(NONE(),Absyn.IDENT(""),{"given","sought","refine"},
          {
           DAE.TYPES_VAR("given",DAE.dummyAttrParam,
             DAE.T_ENUMERATION(SOME(1),Absyn.IDENT(""),{"given","sought","refine"},{},{},DAE.emptyTypeSource),DAE.UNBOUND(),NONE()),
           DAE.TYPES_VAR("sought",DAE.dummyAttrParam,
             DAE.T_ENUMERATION(SOME(2),Absyn.IDENT(""),{"given","sought","refine"},{},{},DAE.emptyTypeSource),DAE.UNBOUND(),NONE()),
           DAE.TYPES_VAR("refine",DAE.dummyAttrParam,
             DAE.T_ENUMERATION(SOME(3),Absyn.IDENT(""),{"given","sought","refine"},{},{},DAE.emptyTypeSource),DAE.UNBOUND(),NONE())
          },{},DAE.emptyTypeSource);

public constant DAE.Type distributionType =
  DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("Distribution")),
                {
                  DAE.TYPES_VAR(
                    "name",
                    DAE.ATTR(SCode.POTENTIAL(),SCode.NON_PARALLEL(),SCode.PARAM(),Absyn.BIDIR(),Absyn.NOT_INNER_OUTER(),SCode.PUBLIC()),
                    DAE.T_STRING_DEFAULT,
                    DAE.UNBOUND(), // binding
                    NONE()),
                  DAE.TYPES_VAR(
                    "params",
                    DAE.ATTR(SCode.POTENTIAL(),SCode.NON_PARALLEL(),SCode.PARAM(),Absyn.BIDIR(),Absyn.NOT_INNER_OUTER(),SCode.PUBLIC()),
                    DAE.T_ARRAY_REAL_NODIM,
                    DAE.UNBOUND(), // binding
                    NONE()),
                  DAE.TYPES_VAR(
                    "paramNames",
                    DAE.ATTR(SCode.POTENTIAL(),SCode.NON_PARALLEL(),SCode.PARAM(),Absyn.BIDIR(),Absyn.NOT_INNER_OUTER(),SCode.PUBLIC()),
                    DAE.T_ARRAY_STRING_NODIM,
                    DAE.UNBOUND(), // binding
                    NONE())
                },
                NONE(),
                {});

protected function instBinding
"This function investigates a modification and extracts the
  <...> modification. E.g. Real x(<...>=1+3) => 1+3
  It also handles the case Integer T0[2](final <...>={5,6})={9,10} becomes
  Integer T0[1](<...>=5); Integer T0[2](<...>=6);

   If no modifier is given it also investigates the type to check for binding there.
   I.e. type A = Real(start=1); A a; will set the start attribute since it's found in the type.

  Arg 1 is the modification
  Arg 2 are the type variables.
  Arg 3 is the expected type that the modification should have
  Arg 4 is the index list for the element: for T0{1,2} is {1,2}"
  input DAE.Mod inMod;
  input list<DAE.Var> inVarLst;
  input DAE.Type inType;
  input list<Integer> inIntegerLst;
  input String inString;
  input Boolean useConstValue "if true use constant value present in TYPED (if present)";
  output Option<DAE.Exp> outExpExpOption;
algorithm
  outExpExpOption := matchcontinue (inMod,inVarLst,inType,inIntegerLst,inString)
    local
      DAE.Mod mod2,mod;
      DAE.Exp e,e_1;
      DAE.Type ty2,ty_1,expected_type,etype;
      String bind_name;
      Option<DAE.Exp> result;
      list<Integer> index_list;
      DAE.Binding binding;
      Ident name;
      Option<Values.Value> optVal;
      list<DAE.Var> varLst;

    case (mod,_,expected_type,{},bind_name) /* No subscript/index */
      equation
        mod2 = Mod.lookupCompModification(mod, bind_name);
        SOME(DAE.TYPED(e,optVal,DAE.PROP(ty2,_),_)) = Mod.modEquation(mod2);
        (e_1,_) = Types.matchType(e, ty2, expected_type, true);
        e_1 = InstUtil.checkUseConstValue(useConstValue,e_1,optVal);
      then
        SOME(e_1);

    case (mod,_,etype,index_list,bind_name) /* Have subscript/index */
      equation
        mod2 = Mod.lookupCompModification(mod, bind_name);
        result = instBinding2(mod2, etype, index_list, bind_name, useConstValue);
      then
        result;

    case (mod,_,_,{},bind_name) /* No modifier for this name. */
      equation
        failure(_ = Mod.lookupCompModification(mod, bind_name));
      then
        NONE();

    case (_,DAE.TYPES_VAR(name,binding=binding)::_,_,_,bind_name)
      equation
        true = stringEq(name, bind_name);
      then
        DAEUtil.bindingExp(binding);

    case (mod,_::varLst,etype,index_list,bind_name)
    then instBinding(mod,varLst,etype,index_list,bind_name,useConstValue);

    case (_,{},_,_,_)
    then NONE();
  end matchcontinue;
end instBinding;

protected function instBinding2
"This function investigates a modification and extracts the <...>
  modification if the modification is in array of components.
  Help-function to instBinding"
  input DAE.Mod inMod;
  input DAE.Type inType;
  input list<Integer> inIntegerLst;
  input String inString;
  input Boolean useConstValue "if true, use constant value in TYPED (if present)";
  output Option<DAE.Exp> outExpExpOption;
algorithm
  outExpExpOption:=
  match (inMod,inType,inIntegerLst,inString)
    local
      DAE.Mod mod2,mod;
      DAE.Exp e,e_1;
      DAE.Type ty2,ty_1,etype;
      Integer index;
      String bind_name;
      Option<DAE.Exp> result;
      list<Integer> res;
      Option<Values.Value> optVal;
    case (mod,etype,(index :: {}),_) /* Only one element in the index-list */
      equation
        mod2 = Mod.lookupIdxModification(mod, DAE.ICONST(index));
        SOME(DAE.TYPED(e,optVal,DAE.PROP(ty2,_),_)) = Mod.modEquation(mod2);
        (e_1,_) = Types.matchType(e, ty2, etype, true);
        e_1 = InstUtil.checkUseConstValue(useConstValue,e_1,optVal);
      then
        SOME(e_1);
    case (mod,etype,(index :: res),bind_name) /* Several elements in the index-list */
      equation
        result = matchcontinue()
          case ()
            equation
              mod2 = Mod.lookupIdxModification(mod, DAE.ICONST(index));
              result = instBinding2(mod2, etype, res, bind_name,useConstValue);
            then result;
          else NONE();
        end matchcontinue;
      then
        result;
  end match;
end instBinding2;

public function instStartBindingExp
"This function investigates a modification and extracts the
  start modification. E.g. Real x(start=1+3) => 1+3
  It also handles the case Integer T0{2}(final start={5,6})={9,10} becomes
  Integer T0{1}(start=5); Integer T0{2}(start=6);

  Arg 1 is the start modification
  Arg 2 is the expected type that the modification should have
  Arg 3 is variability of the element"
  input DAE.Mod inMod;
  input DAE.Type inExpectedType;
  input SCode.Variability inVariability;
  output DAE.StartValue outStartValue;
algorithm
  if SCode.isConstant(inVariability) then
    outStartValue := NONE();
  else
    // When instantiating arrays, the array type is passed.
    // But binding is performed on the element type.
    outStartValue := instBinding(inMod, {},
      Types.arrayElementType(inExpectedType), {}, "start", false);
  end if;
end instStartBindingExp;

protected function instStartOrigin
"This function investigates if the start value comes from the modification or the type"
  input DAE.Mod inMod;
  input list<DAE.Var> inVarLst;
  input String inString;
  output Option<DAE.Exp> outExpExpOption;
algorithm
  outExpExpOption := matchcontinue (inMod,inVarLst,inString)
    local
      DAE.Mod mod2,mod;
      String bind_name;
      DAE.Binding binding;
      Ident name;
      list<DAE.Var> varLst;

    case (mod,_,bind_name)
      equation
        mod2 = Mod.lookupCompModification(mod, bind_name);
        SOME(_) = Mod.modEquation(mod2);
      then
        SOME(DAE.SCONST("binding"));

    case (_,DAE.TYPES_VAR(name=name)::_,bind_name)
      equation
        true = stringEq(name, bind_name);
      then
        SOME(DAE.SCONST("type"));

    case (mod,_::varLst,bind_name)
      then instStartOrigin(mod,varLst,bind_name);

    case (_,{},_)
      then NONE();
  end matchcontinue;
end instStartOrigin;

public function instDaeVariableAttributes
"this function extracts the attributes from the modification
  It returns a DAE.VariableAttributes option because
  somtimes a varible does not contain the variable-attr."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Mod inMod;
  input DAE.Type inType;
  input list<Integer> inIntegerLst;
  output FCore.Cache outCache;
  output Option<DAE.VariableAttributes> outDAEVariableAttributesOption;
algorithm
  (outCache,outDAEVariableAttributesOption) :=
  matchcontinue (inCache,inEnv,inMod,inType,inIntegerLst)
    local
      Option<DAE.Exp> quantity_str,unit_str,displayunit_str,nominal_val,fixed_val,exp_bind_select,exp_bind_uncertainty,exp_bind_min,exp_bind_max,exp_bind_start,min_val,max_val,start_val,startOrigin;
      Option<DAE.StateSelect> stateSelect_value;
      Option<DAE.Uncertainty> uncertainty_value;
      Option<DAE.Distribution> distribution_value;
      FCore.Graph env;
      DAE.Mod mod;
      DAE.TypeSource ts;
      list<Integer> index_list;
      DAE.Type enumtype;
      FCore.Cache cache;
      DAE.Type tp;
      list<DAE.Var> varLst;

    // Real
    case (cache,env,mod,DAE.T_REAL(varLst = varLst),index_list)
      equation
        (quantity_str) = instBinding(mod, varLst, DAE.T_STRING_DEFAULT,index_list, "quantity",false);
        (unit_str) = instBinding(mod, varLst, DAE.T_STRING_DEFAULT, index_list, "unit",false);
        (displayunit_str) = instBinding(mod, varLst,DAE.T_STRING_DEFAULT, index_list, "displayUnit",false);
        (min_val) = instBinding(mod, varLst, DAE.T_REAL_DEFAULT,index_list, "min",false);
        (max_val) = instBinding(mod, varLst, DAE.T_REAL_DEFAULT,index_list, "max",false);
        (start_val) = instBinding(mod, varLst, DAE.T_REAL_DEFAULT,index_list, "start",false);
        (fixed_val) = instBinding( mod, varLst, DAE.T_BOOL_DEFAULT,index_list, "fixed",true);
        (nominal_val) = instBinding(mod, varLst, DAE.T_REAL_DEFAULT,index_list, "nominal",false);

        (exp_bind_select) = instEnumerationBinding(mod, varLst, index_list, "stateSelect",stateSelectType,true);
        (stateSelect_value) = InstUtil.getStateSelectFromExpOption(exp_bind_select);

        (exp_bind_uncertainty) = instEnumerationBinding(mod, varLst, index_list, "uncertain",uncertaintyType,true);
        (uncertainty_value) = getUncertainFromExpOption(exp_bind_uncertainty);
        distribution_value = instDistributionBinding(mod, varLst, index_list, "distribution", false);
        startOrigin = instStartOrigin(mod, varLst, "start");

        //TODO: check for protected attribute (here and below matches)
      then
        (cache,SOME(
          DAE.VAR_ATTR_REAL(quantity_str,unit_str,displayunit_str,min_val,max_val,
          start_val,fixed_val,nominal_val,stateSelect_value,uncertainty_value,distribution_value,NONE(),NONE(),NONE(),startOrigin)));

    // Integer
    case (cache,env,mod,DAE.T_INTEGER(varLst = varLst),index_list)
      equation
        (quantity_str) = instBinding(mod, varLst, DAE.T_STRING_DEFAULT, index_list, "quantity",false);
        (min_val) = instBinding(mod, varLst, DAE.T_INTEGER_DEFAULT, index_list, "min",false);
        (max_val) = instBinding(mod, varLst, DAE.T_INTEGER_DEFAULT, index_list, "max",false);
        (start_val) = instBinding(mod, varLst, DAE.T_INTEGER_DEFAULT, index_list, "start",false);
        (fixed_val) = instBinding(mod, varLst, DAE.T_BOOL_DEFAULT,index_list, "fixed",true);
        (exp_bind_uncertainty) = instEnumerationBinding(mod, varLst, index_list, "uncertain",uncertaintyType,true);
        (uncertainty_value) = getUncertainFromExpOption(exp_bind_uncertainty);
        distribution_value = instDistributionBinding(mod, varLst, index_list, "distribution", false);

        startOrigin = instStartOrigin(mod, varLst, "start");
      then
        (cache,SOME(DAE.VAR_ATTR_INT(quantity_str,min_val,max_val,start_val,fixed_val,uncertainty_value,distribution_value,NONE(),NONE(),NONE(),startOrigin)));

    // Boolean
    case (cache,_,mod,tp as DAE.T_BOOL(varLst = varLst),index_list)
      equation
        (quantity_str) = instBinding( mod, varLst, DAE.T_STRING_DEFAULT, index_list, "quantity",false);
        (start_val) = instBinding(mod, varLst, tp, index_list, "start",false);
        (fixed_val) = instBinding(mod, varLst, tp, index_list, "fixed",true);
        startOrigin = instStartOrigin(mod, varLst, "start");
      then
        (cache,SOME(DAE.VAR_ATTR_BOOL(quantity_str,start_val,fixed_val,NONE(),NONE(),NONE(),startOrigin)));

    // BTH Clock
    case (cache,_,_,DAE.T_CLOCK(),_)
      then
        (cache,SOME(DAE.VAR_ATTR_CLOCK(NONE(),NONE())));

    // String
    case (cache,_,mod,tp as DAE.T_STRING(varLst = varLst),index_list)
      equation
        (quantity_str) = instBinding(mod, varLst, tp, index_list, "quantity",false);
        (start_val) = instBinding(mod, varLst, tp, index_list, "start",false);
        startOrigin = instStartOrigin(mod, varLst, "start");
      then
        (cache,SOME(DAE.VAR_ATTR_STRING(quantity_str,start_val,NONE(),NONE(),NONE(),startOrigin)));

    // Enumeration
    case (cache,_,mod,enumtype as DAE.T_ENUMERATION(attributeLst = varLst),index_list)
      equation
        (quantity_str) = instBinding(mod, varLst, DAE.T_STRING_DEFAULT,index_list, "quantity",false);
        (exp_bind_min) = instBinding(mod, varLst, enumtype, index_list, "min",false);
        (exp_bind_max) = instBinding(mod, varLst, enumtype, index_list, "max",false);
        (exp_bind_start) = instBinding(mod, varLst, enumtype, index_list, "start",false);
        (fixed_val) = instBinding(mod, varLst, DAE.T_BOOL_DEFAULT, index_list, "fixed",true);
        startOrigin = instStartOrigin(mod, varLst, "start");
      then
        (cache,SOME(DAE.VAR_ATTR_ENUMERATION(quantity_str,exp_bind_min,exp_bind_max,exp_bind_start,fixed_val,NONE(),NONE(),NONE(),startOrigin)));

    // not a basic type?
    case (cache,_,_,_,_)
      then (cache,NONE());
  end matchcontinue;
end instDaeVariableAttributes;

protected function instEnumerationBinding
"author: LP
  instantiates a enumeration binding and retrieves the value."
  input DAE.Mod inMod;
  input list<DAE.Var> varLst;
  input list<Integer> inIndices;
  input String inName;
  input DAE.Type expected_type;
  input Boolean useConstValue "if true, use constant value in TYPED (if present)";
  output Option<DAE.Exp> outBinding;
algorithm
  try
    outBinding := instBinding(inMod, varLst, expected_type, inIndices, inName, useConstValue);
  else
    Error.addMessage(Error.TYPE_ERROR, {inName, "enumeration type"});
  end try;
end instEnumerationBinding;

protected function instDistributionBinding
"
  Author:Peter Aronsson, 2012

  Instantiates a distribution binding and retrieves the value.
"
  input DAE.Mod inMod;
  input list<DAE.Var> varLst;
  input list<Integer> inIntegerLst;
  input String inString;
  input Boolean useConstValue "if true, use constant value in TYPED (if present)";
  output Option<DAE.Distribution> out;
algorithm
  out := matchcontinue (inMod,inIntegerLst,inString)
    local
      DAE.Mod mod;
      DAE.Exp name,params,paramNames;
      list<Integer> index_list;
      String bind_name;
      DAE.Type ty;
      Integer paramDim;
      DAE.ComponentRef cr,crName,crParams,crParamNames;
      Absyn.Path path;

    //Record constructor
    case (mod, index_list, bind_name)
      equation
        SOME(DAE.CALL(path = path, expLst = {name,params, paramNames})) = instBinding(mod, varLst, distributionType, index_list, bind_name, useConstValue);
        true = Absyn.pathEqual(path, Absyn.IDENT("Distribution"));
      then
        SOME(DAE.DISTRIBUTION(name, params, paramNames));

    case (mod, index_list, bind_name)
      equation
        SOME(DAE.RECORD(path = path, exps = {name,params, paramNames})) = instBinding(mod, varLst, distributionType, index_list, bind_name, useConstValue);
        true = Absyn.pathEqual(path, Absyn.IDENT("Distribution"));
      then
        SOME(DAE.DISTRIBUTION(name, params, paramNames));

    // Cref
    case (mod, index_list, bind_name)
      equation
        SOME(DAE.CREF(cr,ty)) = instBinding(mod, varLst, distributionType, index_list, bind_name, useConstValue);
        true = Types.isRecord(ty);
        DAE.T_COMPLEX(varLst = _::DAE.TYPES_VAR(ty=DAE.T_ARRAY(dims={DAE.DIM_INTEGER(paramDim)}))::_) = ty;

        crName = ComponentReference.crefPrependIdent(cr,"name",{},DAE.T_STRING_DEFAULT);
        crParams = ComponentReference.crefPrependIdent(cr,"params",{},DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(paramDim)},DAE.emptyTypeSource));
        _ = ComponentReference.crefPrependIdent(cr,"params",{},DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_INTEGER(paramDim)},DAE.emptyTypeSource));
        name = Expression.makeCrefExp(crName,DAE.T_STRING_DEFAULT);
        params = Expression.makeCrefExp(crParams,DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(paramDim)},DAE.emptyTypeSource));
        paramNames = Expression.makeCrefExp(crParams,DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_INTEGER(paramDim)},DAE.emptyTypeSource));
      then
         SOME(DAE.DISTRIBUTION(name, params, paramNames));



    else NONE();

  end matchcontinue;
end instDistributionBinding;

protected function getUncertainFromExpOption
"
  Author: Daniel Hedberg 2011-01

  Extracts the uncertainty value, as defined in DAE, from a DAE.Exp.
"
  input Option<DAE.Exp> expOption;
  output Option<DAE.Uncertainty> out;
algorithm
  out := match (expOption)
    case (SOME(DAE.ENUM_LITERAL(name = Absyn.QUALIFIED("Uncertainty", path = Absyn.IDENT("given"))))) then SOME(DAE.GIVEN());
    case (SOME(DAE.ENUM_LITERAL(name = Absyn.QUALIFIED("Uncertainty", path = Absyn.IDENT("sought"))))) then SOME(DAE.SOUGHT());
    case (SOME(DAE.ENUM_LITERAL(name = Absyn.QUALIFIED("Uncertainty", path = Absyn.IDENT("refine"))))) then SOME(DAE.REFINE());
    else NONE();
  end match;
end getUncertainFromExpOption;

public function instModEquation
"This function adds the equation in the declaration
  of a variable, if such an equation exists."
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  input DAE.Mod inMod;
  input DAE.ElementSource inSource "the origin of the element";
  input Boolean inImpl;
  output DAE.DAElist outDae;
algorithm
  outDae:= matchcontinue (inType,inMod)
    local
      DAE.Type t;
      DAE.DAElist dae;
      DAE.Mod mod,m;
      DAE.Exp e,lhs;
      DAE.Properties prop2;
      Boolean impl;
      Absyn.Exp aexp1,aexp2;
      SCode.EEquation scode;
      Absyn.ComponentRef acr;
      SourceInfo info;
      DAE.ElementSource source;

    // Record constructors are different
    // If it's a constant binding, all fields will already be bound correctly. Don't return a DAE.
    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),
          DAE.MOD(binding = SOME(DAE.TYPED(_,SOME(_),DAE.PROP(_,DAE.C_CONST()),_))))
      then DAE.emptyDae;

    // Special case if the dimensions of the expression is 0.
    // If this is true, and it is instantiated normally, matching properties
    // will result in error messages (Real[0] is not Real), so we handle it here.
    case (_, DAE.MOD(binding = SOME(DAE.TYPED(properties = prop2))))
      algorithm
        DAE.T_ARRAY(dims = {DAE.DIM_INTEGER(0)}) := Types.getPropType(prop2);
      then
        DAE.emptyDae;

    // Regular cases
    case (_, DAE.MOD(binding = SOME(DAE.TYPED(e,_,prop2,aexp2)), info = info))
      algorithm
        t := Types.simplifyType(inType);
        lhs := Expression.makeCrefExp(inComponentRef, t);
        acr := ComponentReference.unelabCref(inComponentRef);
        aexp1 := Absyn.CREF(acr);
        scode := SCode.EQ_EQUALS(aexp1,aexp2,SCode.noComment,info);
        source := DAEUtil.addSymbolicTransformation(inSource,DAE.FLATTEN(scode,NONE()));
        dae := InstSection.instEqEquation(lhs, DAE.PROP(inType,DAE.C_VAR()), e, prop2, source, SCode.NON_INITIAL(), inImpl);
      then
        dae;

    case (_, DAE.MOD(binding = NONE())) then DAE.emptyDae;
    case (_, DAE.NOMOD()) then DAE.emptyDae;
    case (_, DAE.REDECL()) then DAE.emptyDae;

    else
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- InstBinding.instModEquation failed\n type: ");
        Debug.trace(Types.printTypeStr(inType));
        Debug.trace("\n  cref: ");
        Debug.trace(ComponentReference.printComponentRefStr(inComponentRef));
        Debug.trace("\n mod:");
        Debug.traceln(Mod.printModStr(inMod));
      then
        fail();
  end matchcontinue;
end instModEquation;

public function makeBinding
"This function looks at the equation part of a modification, and
  if there is a declaration equation builds a DAE.Binding for it."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Attributes inAttributes;
  input DAE.Mod inMod;
  input DAE.Type inType;
  input Prefix.Prefix inPrefix;
  input String componentName;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Binding outBinding;
algorithm
  (outCache,outBinding) := matchcontinue (inCache,inAttributes,inMod,inType)
    local
      DAE.Type tp,e_tp;
      DAE.Exp e_1,e,e_val_exp;
      Option<Values.Value> e_val;
      DAE.Const c;
      String e_tp_str,tp_str,e_str,e_str_1,str,s,pre_str;
      FCore.Cache cache;
      DAE.Properties prop;
      DAE.Binding binding;
      DAE.Mod startValueModification;
      list<DAE.Var> complex_vars;
      Absyn.Path tpath;
      list<DAE.SubMod> sub_mods;
      SourceInfo info;
      Values.Value v;

    // A record might have bindings from the class, use those if there is no modifier!
    case (cache, _, DAE.NOMOD(), _)
      equation
        (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path = tpath),
           varLst = complex_vars)) = Types.arrayElementType(inType);
        true = Types.allHaveBindings(complex_vars);
        binding = makeRecordBinding(cache, inEnv, tpath, inType, complex_vars, {}, inInfo);
      then
        (cache, binding);

    case (cache,_,DAE.NOMOD(),_) then (cache,DAE.UNBOUND());

    case (cache,_,DAE.REDECL(),_) then (cache,DAE.UNBOUND());

    // adrpo: if the binding is missing for a parameter and
    //        the parameter has a start value modification,
    //        use that to create the binding as if we have
    //        a modification from outside it will be re-written.
    //        this fixes:
    //             Modelica.Electrical.Machines.Examples.SMEE_Generator
    //             (BUG: #1156 at https://openmodelica.org:8443/cb/issue/1156)
    //             and maybe a lot others.
    case (cache,SCode.ATTR(variability = SCode.PARAM()),DAE.MOD(binding = NONE()),tp)
      equation
        true = Types.getFixedVarAttributeParameterOrConstant(tp);
        // this always succeeds but return NOMOD if there is no (start = x)
        startValueModification = Mod.lookupCompModification(inMod, "start");
        // make sure is NOT a DAE.NOMOD!
        false = Mod.isEmptyMod(startValueModification);
        (cache,binding) = makeBinding(cache,inEnv,inAttributes,startValueModification,inType,inPrefix,componentName,inInfo);
        binding = DAEUtil.setBindingSource(binding, DAE.BINDING_FROM_START_VALUE());

        // lochel: I moved the warning to the back end for now
        // s = componentName;
        // pre_str = PrefixUtil.printPrefixStr2(inPrefix);
        // s = pre_str + s;
        // str = DAEUtil.printBindingExpStr(binding);
        // Error.addSourceMessage(Error.UNBOUND_PARAMETER_WITH_START_VALUE_WARNING, {s,str}, inInfo);
      then
        (cache,binding);

    // A record might have bindings for each component instead of a single
    // binding for the whole record, in which case we need to assemble them into
    // a binding.
    case (cache, _, DAE.MOD(subModLst = sub_mods as _ :: _), _)
      equation
        (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path = tpath),
           varLst = complex_vars)) = Types.arrayElementType(inType);
        binding = makeRecordBinding(cache, inEnv, tpath, inType, complex_vars, sub_mods, inInfo);
      then
        (cache, binding);

    case (cache,_,DAE.MOD(binding = NONE()),_) then (cache,DAE.UNBOUND());
    /* adrpo: CHECK! do we need this here? numerical values
    case (cache,env,_,DAE.MOD(binding = SOME(DAE.TYPED(e,_,DAE.PROP(e_tp,_)))),tp,_,_)
      equation
        (e_1,_) = Types.matchType(e, e_tp, tp);
        (cache,v,_) = Ceval.ceval(cache,env, e_1, false,NONE(), NONE(), Absyn.NO_MSG(),0);
      then
        (cache,DAE.VALBOUND(v, DAE.BINDING_FROM_DEFAULT_VALUE()));
    */

    case (cache,_,DAE.MOD(binding = SOME(DAE.TYPED(e,SOME(v),prop,_))),e_tp) /* default */
      equation
        c = Types.propAllConst(prop);
        tp = Types.getPropType(prop);
        false = Types.equivtypes(tp,e_tp);
        e_val_exp = ValuesUtil.valueExp(v);
        // Handle bindings of the type Boolean b[Boolean]={true,false}, enumerations, and similar
        // tp = Types.traverseType(tp, 1, Types.makeKnownDimensionsInteger);
        // e_tp = Types.traverseType(e_tp, 1, Types.makeKnownDimensionsInteger);
        (e_1, _) = Types.matchType(e, tp, e_tp, false);
        (e_1,_) = ExpressionSimplify.simplify(e_1);
        (e_val_exp, _) = Types.matchType(e_val_exp, tp, e_tp, false);
        (e_val_exp,_) = ExpressionSimplify.simplify(e_val_exp);
        v = Ceval.cevalSimple(e_val_exp);
        e_val = SOME(v);
      then
        (cache,DAE.EQBOUND(e_1,e_val,c,DAE.BINDING_FROM_DEFAULT_VALUE()));

    case (cache,_,DAE.MOD(binding = SOME(DAE.TYPED(e,e_val,prop,_))),e_tp) /* default */
      equation
        c = Types.propAllConst(prop);
        tp = Types.getPropType(prop);
        // Handle bindings of the type Boolean b[Boolean]={true,false}, enumerations, and similar
        // tp = Types.traverseType(tp, 1, Types.makeKnownDimensionsInteger);
        // e_tp = Types.traverseType(e_tp, 1, Types.makeKnownDimensionsInteger);
        (e_1, _) = Types.matchType(e, tp, e_tp, false);
        (e_1,_) = ExpressionSimplify.simplify(e_1);
      then
        (cache,DAE.EQBOUND(e_1,e_val,c,DAE.BINDING_FROM_DEFAULT_VALUE()));

    case (_,_,DAE.MOD(binding = SOME(DAE.TYPED(e,_,prop,_)), info = info),tp)
      equation
        e_tp = Types.getPropType(prop);
        _ = Types.propAllConst(prop);
        failure((_,_) = Types.matchType(e, e_tp, tp, false));
        e_tp_str = Types.unparseTypeNoAttr(e_tp);
        tp_str = Types.unparseTypeNoAttr(tp);
        e_str = ExpressionDump.printExpStr(e);
        e_str_1 = stringAppend("=", e_str);
        str = PrefixUtil.printPrefixStrIgnoreNoPre(inPrefix) + "." + componentName;
        Types.typeErrorSanityCheck(e_tp_str, tp_str, info);
        Error.addSourceMessage(Error.MODIFIER_TYPE_MISMATCH_ERROR, {str,tp_str,e_str_1,e_tp_str}, info);
      then
        fail();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.makeBinding failed on component:" + PrefixUtil.printPrefixStr(inPrefix) + "." + componentName);
      then
        fail();
  end matchcontinue;
end makeBinding;

public function makeRecordBinding
  "Creates a binding for a record given a list of submodifiers. This is the case
   when a record is given a binding by modifiers, ex:

     record R
       Real x; Real y;
     end R;

     constant R r(x = 2.0, y = 3.0);

  This is translated to:
     constant R r = R(2.0, 3.0);

  This is needed when we assign a record to another record.
  "
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inRecordName;
  input DAE.Type inRecordType;
  input list<DAE.Var> inRecordVars;
  input list<DAE.SubMod> inMods;
  input SourceInfo inInfo;
  output DAE.Binding outBinding;
protected
  list<DAE.Exp> accum_exps = {};
  list<Values.Value> accum_vals = {};
  list<String> accum_names = {};
  list<DAE.SubMod> mods = inMods;
  Option<DAE.SubMod> opt_mod;
  String name = "", scope, ty_str;
  DAE.Type ty, ety;
  DAE.Binding binding;
  list<DAE.Dimension> dims;
  DAE.Exp exp;
  Values.Value val;
algorithm
  dims := Types.getDimensions(inRecordType);

  try
    for var in inRecordVars loop
      DAE.TYPES_VAR(name = name, ty = ty, binding = binding) := var;

      // Try to find a submod with the same name as the variable.
      (mods, opt_mod) := List.deleteMemberOnTrue(name, mods, InstUtil.isSubModNamed);

      if isSome(opt_mod) then
        // Found a submod, use its binding.
        ty := Types.liftArrayListDims(ty, dims);
        (exp, val) := makeRecordBinding3(opt_mod, ty, inInfo);
      elseif DAEUtil.isBound(binding) then
        // Couldn't find a submod, but variable has a binding already.
        DAE.EQBOUND(exp = exp, evaluatedExp = SOME(val)) := binding;
      else
        // Couldn't find a submod, and the variable doesn't have a binding.
        ety := Types.simplifyType(ty);
        ty := Types.liftArrayListDims(ty, dims);
        scope := FGraph.printGraphPathStr(inEnv);
        ty_str := Types.printTypeStr(ty);
        exp := DAE.EMPTY(scope, DAE.CREF_IDENT(name, ety, {}), ety, ty_str);
        val := Values.EMPTY(scope, name, Types.typeToValue(ty), ty_str);
      end if;

      accum_exps := exp :: accum_exps;
      accum_vals := val :: accum_vals;
      accum_names := name :: accum_names;
    end for;

    // Assemble the binding for the record.
    ety := Types.simplifyType(Types.arrayElementType(inRecordType));
    exp := DAE.CALL(inRecordName, listReverse(accum_exps),
      DAE.CALL_ATTR(ety, false, false, false, false, DAE.NORM_INLINE(), DAE.NO_TAIL()));
    val := Values.RECORD(inRecordName, listReverse(accum_vals), listReverse(accum_names), -1);
    (exp, val) := InstUtil.liftRecordBinding(inRecordType, exp, val);
    outBinding := DAE.EQBOUND(exp, SOME(val), DAE.C_CONST(), DAE.BINDING_FROM_DEFAULT_VALUE());
  else
    if Flags.isSet(Flags.FAILTRACE) then
      Debug.traceln("- Inst.makeRecordBinding2 failed for " +
        Absyn.pathString(inRecordName) + "." + name + "\n");
    end if;
    fail();
  end try;
end makeRecordBinding;

protected function makeRecordBinding3
  "Helper function to makeRecordBinding2. Fetches the binding expression and
   value from an optional submod."
  input Option<DAE.SubMod> inSubMod;
  input DAE.Type inType;
  input SourceInfo inInfo;
  output DAE.Exp outExp;
  output Values.Value outValue;
algorithm
  (outExp, outValue) := matchcontinue(inSubMod)
    local
      DAE.Exp exp;
      Values.Value val;
      DAE.Type ty,ty2;
      DAE.Ident ident;
      String binding_str, expected_type_str, given_type_str;

    // Array type and each prefix => return the expression and value.
    case (SOME(DAE.NAMEMOD(mod = DAE.MOD(eachPrefix = SCode.EACH(), binding =
        SOME(DAE.TYPED(modifierAsExp = exp, modifierAsValue = SOME(val)))))))
      then (exp, val);

    // Scalar type and no each prefix => return the expression and value.
    case (SOME(DAE.NAMEMOD(mod = DAE.MOD(eachPrefix = SCode.NOT_EACH(), binding =
        SOME(DAE.TYPED(modifierAsExp = exp, modifierAsValue = SOME(val), properties = DAE.PROP(type_ = ty)))))))
      algorithm
        (exp, ty) := Types.matchType(exp, ty, inType, true);
      then
        (exp, val);

    // Scalar type and no each prefix => bindings given by expressions myRecord(v1 = inV1, v2 = inV2)
    case (SOME(DAE.NAMEMOD(mod = DAE.MOD(eachPrefix = SCode.NOT_EACH(), binding =
        SOME(DAE.TYPED(modifierAsExp = exp, modifierAsValue = NONE(), properties = DAE.PROP(type_ = ty)))))))
      algorithm
        (exp, ty) := Types.matchType(exp, ty, inType, true);
      then
        (exp, Values.OPTION(NONE()));

    case (SOME(DAE.NAMEMOD(ident = ident, mod = DAE.MOD(binding =
        SOME(DAE.TYPED(modifierAsExp = exp, properties = DAE.PROP(type_ = ty)))))))
      equation
        binding_str = ExpressionDump.printExpStr(exp);
        expected_type_str = Types.unparseTypeNoAttr(inType);
        given_type_str = Types.unparseTypeNoAttr(ty);
        Types.typeErrorSanityCheck(given_type_str, expected_type_str, inInfo);
        Error.addSourceMessage(Error.VARIABLE_BINDING_TYPE_MISMATCH,
        {ident, binding_str, expected_type_str, given_type_str}, inInfo);
      then
        fail();

  end matchcontinue;
end makeRecordBinding3;

public function makeVariableBinding
  "Returns a variable's bound expression."
  input DAE.Type inType;
  input DAE.Mod inMod;
  input DAE.Const inConst;
  input Prefix.Prefix inPrefix;
  input String inName;
  output Option<DAE.Exp> outBinding;
protected
  Option<DAE.EqMod> oeq_mod = Mod.modEquation(inMod);
  DAE.Exp e, e2;
  DAE.Properties p;
  SourceInfo info;
  DAE.Const c;
  String e_str, et_str, bt_str;
algorithm
  // No modifier => no binding.
  if isNone(oeq_mod) then
    outBinding := NONE();
    return;
  end if;

  SOME(DAE.TYPED(modifierAsExp = e, properties = p)) := oeq_mod;

  if Types.isExternalObject(inType) then
    // For external objects the binding contains the constructor call. Return it as it is.
    outBinding := SOME(e);
  elseif Types.isEmptyArray(Types.getPropType(p)) then
    // An empty array has unknown type, skip type matching.
    outBinding := NONE();
  else
    info := Mod.getModInfo(inMod);

    // For normal variables, make sure the types match.
    try
      (e2, DAE.PROP(constFlag = c)) :=
        Types.matchProp(e, p, DAE.PROP(inType, inConst), true);
    else
      // The types of the variable and binding are incompatible, print an error.
      e_str := ExpressionDump.printExpStr(e);
      et_str := Types.unparseTypeNoAttr(inType);
      bt_str := Types.unparseTypeNoAttr(Types.getPropType(p));
      Types.typeErrorSanityCheck(et_str, bt_str, info);
      Error.addSourceMessageAndFail(Error.VARIABLE_BINDING_TYPE_MISMATCH,
        {inName, e_str, et_str, bt_str}, info);
    end try;

    // Check that the variability is compatible too.
    InstUtil.checkHigherVariability(inConst, c, inPrefix, inName, e, info);
    outBinding := SOME(e2);
  end if;
end makeVariableBinding;

annotation(__OpenModelica_Interface="frontend");
end InstBinding;

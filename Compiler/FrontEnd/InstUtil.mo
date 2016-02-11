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

encapsulated package InstUtil
" file:        InstUtil.mo
  package:     InstUtil
  description: Instantiation utilities

  RCS: $Id: InstUtil.mo 17556 2013-10-05 23:58:57Z adrpo $

  This package supports Inst*.mo
"

public import Absyn;
public import ClassInf;
public import DAE;
public import FCore;
public import GlobalScript;
public import InnerOuter;
public import InstTypes;
public import Mod;
public import Prefix;
public import SCode;
public import UnitAbsyn;
public import Values;
public import HashTable;
public import HashTable5;

protected import List;
protected import BaseHashTable;
protected import Expression;
protected import Error;
protected import Util;
protected import ComponentReference;
protected import Patternm;
protected import DAEUtil;
protected import DAEDump;
protected import Types;
protected import Debug;
protected import PrefixUtil;
protected import ExpressionDump;
protected import Flags;
protected import FGraph;
protected import FNode;
protected import SCodeDump;
protected import Lookup;
protected import ValuesUtil;
protected import Static;
protected import Ceval;
protected import Dump;
protected import Config;
protected import Inst;
protected import InstFunction;
protected import InstSection;
protected import System;
protected import ErrorExt;
protected import InstExtends;
protected import Graph;
protected import UnitAbsynBuilder;
protected import UnitChecker;
protected import NFSCodeFlatten;
protected import HashSet;
protected import BaseHashSet;

protected type Ident = DAE.Ident "an identifier";
protected type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";
protected type InstDims = list<list<DAE.Dimension>>;

public function newIdent
"This function creates a new, unique identifer.
  The same name is never returned twice."
  output DAE.ComponentRef outComponentRef;
protected
  Integer i;
  String is,s;
algorithm
  i := tick();
  is := intString(i);
  s := stringAppend("__TMP__", is);
  outComponentRef := ComponentReference.makeCrefIdent(s,DAE.T_UNKNOWN_DEFAULT,{});
end newIdent;

protected function isNotFunction
"This function returns true if the Class is not a function."
  input SCode.Element cls;
  output Boolean res;
algorithm
  res := SCode.isFunction(cls);
  res := boolNot(res);
end isNotFunction;

public function scodeFlatten
  input SCode.Program inProgram;
  input Absyn.Path inPath;
  output SCode.Program outProgram;
algorithm
  outProgram := matchcontinue(inProgram, inPath)

    case (_, _)
      equation
        false = Flags.isSet(Flags.DO_SCODE_DEP);
      then
        inProgram;

    case (_, Absyn.IDENT(""))
      equation
        outProgram = scodeFlattenProgram(inProgram);
      then
        outProgram;

    else
      equation
        (outProgram, _) = NFSCodeFlatten.flattenClassInProgram(inPath, inProgram);
      then
        outProgram;

  end matchcontinue;
end scodeFlatten;

protected function scodeFlattenProgram
  input SCode.Program inProgram;
  output SCode.Program outProgram;
algorithm
  outProgram := matchcontinue(inProgram)

    case (_)
      equation
        ErrorExt.setCheckpoint("scodeFlattenProgram");
        outProgram = NFSCodeFlatten.flattenCompleteProgram(inProgram);
        ErrorExt.delCheckpoint("scodeFlattenProgram");
      then
        outProgram;

    else
      equation
        ErrorExt.rollBack("scodeFlattenProgram");
      then
        inProgram;
  end matchcontinue;
end scodeFlattenProgram;

public function reEvaluateInitialIfEqns "
Author BZ
This is a backpatch to fix the case of 'connection.isRoot' in initial if equations.
After the class is instantiated a second sweep is done to check the initial if equations conditions.
If all conditions are constant, we return only the 'correct' branch equations."
  input FCore.Cache cache;
  input FCore.Graph env;
  input DAE.DAElist dae;
  input Boolean isTopCall;
  output DAE.DAElist odae;
algorithm
  odae := match(cache,env,dae,isTopCall)
  local
    list<DAE.Element> elems;
  case(_,_,DAE.DAE(elementLst = elems),true)
    equation
      elems = listReverse(List.fold2r(elems,reEvaluateInitialIfEqns2,cache,env,{}));
    then
      DAE.DAE(elems);
  case(_,_,_,false) then dae;
  end match;
end reEvaluateInitialIfEqns;

protected function reEvaluateInitialIfEqns2 ""
  input list<DAE.Element> acc;
  input DAE.Element elem;
  input FCore.Cache inCache;
  input FCore.Graph env;
  output list<DAE.Element> oelems;
algorithm
  oelems := matchcontinue (acc,elem,inCache,env)
    local
      list<DAE.Exp> conds;
      list<Values.Value> valList;
      list<list<DAE.Element>> tbs;
      list<DAE.Element> fb,selectedBranch;
      DAE.ElementSource source;
      list<Boolean> blist;
      FCore.Cache cache;

    case (_,DAE.INITIAL_IF_EQUATION(condition1 = conds, equations2=tbs, equations3=fb),cache,_)
      equation
        //print(" (Initial if)To ceval: " + stringDelimitList(List.map(conds,ExpressionDump.printExpStr),", ") + "\n");
        (_,valList,_) = Ceval.cevalList(cache,env, conds, true, NONE(), Absyn.NO_MSG(),0);
        //print(" Ceval res: ("+stringDelimitList(List.map(valList,ValuesUtil.printValStr),",")+")\n");

        blist = List.map(valList,ValuesUtil.valueBool);
        selectedBranch = List.findBoolList(blist, tbs, fb);
        selectedBranch = makeDAEElementInitial(selectedBranch);
      then listAppend(selectedBranch,acc);
    else elem::acc;
  end matchcontinue;
end reEvaluateInitialIfEqns2;

protected function makeDAEElementInitial "
Author BZ
Helper function for reEvaluateInitialIfEqns, makes the contenst of an initial if equation initial."
  input list<DAE.Element> inElems;
  output list<DAE.Element> outElems;
algorithm
  outElems := matchcontinue(inElems)
    local
      DAE.Element elem;
      DAE.ComponentRef cr;
      DAE.Exp e1,e2;
      DAE.ElementSource s;
      list<DAE.Exp> expl;
      list<list<DAE.Element>> tbs ;
      list<DAE.Element> fb;
      DAE.Algorithm al;
      DAE.Dimensions dims;
      list<DAE.Element> elems;

    case({}) then {};

    case(DAE.DEFINE(cr,e1,s)::elems)
      equation
        outElems = makeDAEElementInitial(elems);
      then
        DAE.INITIALDEFINE(cr,e1,s)::outElems;

    case(DAE.ARRAY_EQUATION(dims,e1,e2,s)::elems)
      equation
        outElems = makeDAEElementInitial(elems);
      then
        DAE.INITIAL_ARRAY_EQUATION(dims,e1,e2,s)::outElems;

    case(DAE.EQUATION(e1,e2,s)::elems)
      equation
        outElems = makeDAEElementInitial(elems);
      then
        DAE.INITIALEQUATION(e1,e2,s)::outElems;

    case(DAE.IF_EQUATION(expl,tbs,fb,s)::elems)
      equation
        outElems = makeDAEElementInitial(elems);
      then
        DAE.INITIAL_IF_EQUATION(expl,tbs,fb,s)::outElems;

    case(DAE.ALGORITHM(al,s)::elems)
      equation
        outElems = makeDAEElementInitial(elems);
      then
        DAE.INITIALALGORITHM(al,s)::outElems;

    case(DAE.COMPLEX_EQUATION(e1,e2,s)::elems)
      equation
        outElems = makeDAEElementInitial(elems);
      then
        DAE.INITIAL_COMPLEX_EQUATION(e1,e2,s)::outElems;

    case(elem::elems) // safe "last case" since we can not fail in cases above.
      equation
        outElems = makeDAEElementInitial(elems);
      then
        elem::outElems;
  end matchcontinue;
end makeDAEElementInitial;

public function lookupTopLevelClass
  "Looks up a top level class with the given name."
  input String inName;
  input SCode.Program inProgram;
  input Boolean inPrintError;
  output SCode.Element outClass;
algorithm
  outClass := matchcontinue(inName, inProgram, inPrintError)
    local
      SCode.Element cls;

    case (_, _, _)
      equation
        cls = List.getMemberOnTrue(inName, inProgram, SCode.isClassNamed);
      then
        cls;

    case (_, _, true)
      equation
        Error.addMessage(Error.LOAD_MODEL_ERROR, {inName});
      then
        fail();

  end matchcontinue;
end lookupTopLevelClass;

public function fixInstClassType
"Fixes the type of a class if it is uniontype or function reference.
  These are MetaModelica extensions."
  input DAE.Type ty;
  input Boolean isPartialFn;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (ty,isPartialFn)
    local
      String name;
      Absyn.Path path1, path2;
    case (_,_)
      equation
        {path1} = Types.getTypeSource(ty);
        name = Absyn.pathLastIdent(path1);
        path2 = Absyn.stripLast(path1);
        "$Code" = Absyn.pathLastIdent(path2);
        path2 = Absyn.stripLast(path2);
        "OpenModelica" = Absyn.pathLastIdent(path2);
      then Util.assoc(name,{
        ("Expression",    DAE.T_CODE(DAE.C_EXPRESSION(),DAE.emptyTypeSource)),
        ("TypeName",      DAE.T_CODE(DAE.C_TYPENAME(),DAE.emptyTypeSource)),
        ("VariableName",  DAE.T_CODE(DAE.C_VARIABLENAME(),DAE.emptyTypeSource)),
        ("VariableNames", DAE.T_CODE(DAE.C_VARIABLENAMES(),DAE.emptyTypeSource))
        });
    case (_,false) then ty;
    case (_,true) then Types.makeFunctionPolymorphicReference(ty);
  end matchcontinue;
end fixInstClassType;

public function updateEnumerationEnvironment
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Type inType;
  input SCode.Element inClass;
  input ClassInf.State inCi_State;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache,outEnv) := matchcontinue(inCache,inEnv,inType,inClass,inCi_State)
    local
      FCore.Cache cache;
      FCore.Graph env,env_1;
      DAE.Type ty;
      SCode.Element c;
      list<String> names;
      list<DAE.Var> vars;
      Absyn.Path p,pname;

    case (cache,env,DAE.T_ENUMERATION(names = names, literalVarLst = vars, source = {p}),_,ClassInf.ENUMERATION(pname))
      equation
        (cache,env_1) = updateEnumerationEnvironment1(cache,env,Absyn.pathString(pname),names,vars,p);
      then
       (cache,env_1);

    case (cache,env,_,_,_) then (cache,env);

  end matchcontinue;
end updateEnumerationEnvironment;

protected function updateEnumerationEnvironment1
"update enumeration value in environment"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Ident inName;
  input list<String> inNames;
  input list<DAE.Var> inVars;
  input Absyn.Path inPath;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache,outEnv) := match(inCache,inEnv,inName,inNames,inVars,inPath)
    local
      FCore.Cache cache;
      FCore.Graph env,env_1,env_2,compenv;
      String name,nn;
      list<String> names;
      list<DAE.Var> vars;
      DAE.Var var,  new_var;
      DAE.Type ty;
      FCore.Status instStatus;
      Absyn.Path p;
      DAE.Attributes attributes;
      DAE.Binding binding;
      Option<DAE.Const> cnstOpt;

    case (cache,env,_,nn::names,(DAE.TYPES_VAR(ty = ty))::vars,p)
      equation
        // get Var
        (cache,DAE.TYPES_VAR(name,attributes,_,binding,cnstOpt),
          _,_,_,compenv) =
          Lookup.lookupIdentLocal(cache, env, nn);
        // print("updateEnumerationEnvironment1 -> component: " + name + " ty: " + Types.printTypeStr(ty) + "\n");
        // change type
        new_var = DAE.TYPES_VAR(name,attributes,ty,binding,cnstOpt);
        // update
         env_1 = FGraph.updateComp(env, new_var, FCore.VAR_DAE(), compenv);
        // next
        (cache,env_2) = updateEnumerationEnvironment1(cache,env_1,name,names,vars,p);
      then
       (cache,env_2);
    case (cache,env,_,{},_,_) then (cache,env);
  end match;
end updateEnumerationEnvironment1;

public function updateDeducedUnits "updates the deduced units in each DAE.VAR"
  input Boolean callScope;
  input UnitAbsyn.InstStore store;
  input DAE.DAElist dae;
  output DAE.DAElist outDae;
algorithm
  outDae := match (callScope,store,dae)
    local
      HashTable.HashTable ht;
      array<Option<UnitAbsyn.Unit>> vec;
      list<DAE.Element> elts;

      /* Only traverse on top scope */
    case (true,UnitAbsyn.INSTSTORE(UnitAbsyn.STORE(vec,_),ht,_),DAE.DAE(elts))
      equation
        elts = List.map2(elts,updateDeducedUnits2,vec,ht);
      then DAE.DAE(elts);

    else dae;
  end match;
end updateDeducedUnits;

protected function updateDeducedUnits2 "updates the deduced units in each DAE.VAR"
  input DAE.Element elt;
  input array<Option<UnitAbsyn.Unit>> vec;
  input HashTable.HashTable ht;
  output DAE.Element oelt;
algorithm
  oelt := matchcontinue (elt,vec,ht)
    local
      Integer indx;
      String unitStr;
      UnitAbsyn.Unit unit;
      Option<DAE.VariableAttributes> varOpt;
      DAE.ComponentRef cr;

      /* Only traverse on top scope */
    case ((DAE.VAR(componentRef=cr,variableAttributesOption=varOpt as SOME(DAE.VAR_ATTR_REAL(unit = NONE())))),_,_)
      equation
        indx = BaseHashTable.get(cr,ht);
        SOME(unit) = vec[indx];
        unitStr = UnitAbsynBuilder.unit2str(unit);
        varOpt = DAEUtil.setUnitAttr(varOpt,DAE.SCONST(unitStr));
      then DAEUtil.setVariableAttributes(elt,varOpt);

    else elt;
  end matchcontinue;
end updateDeducedUnits2;

public function reportUnitConsistency "reports CONSISTENT or INCOMPLETE error message depending on content of store"
  input Boolean topScope;
  input UnitAbsyn.InstStore store;
algorithm
  _ := matchcontinue(topScope,store)
    local
      Boolean complete; UnitAbsyn.Store st;

    case(_,_)
      equation
        false = Flags.getConfigBool(Flags.UNIT_CHECKING);
      then
        ();

    case(true,UnitAbsyn.INSTSTORE(st,_,SOME(UnitAbsyn.CONSISTENT())))
      equation
        (complete,_) = UnitChecker.isComplete(st);
        Error.addMessage(if complete then Error.CONSISTENT_UNITS else Error.INCOMPLETE_UNITS,{});
      then
        ();

    else ();

  end matchcontinue;
end reportUnitConsistency;

protected function extractConnectorPrefix
"Author: BZ, 2009-09
 Extract the part before the conector ex: a.b.c.connector_d.e would return a.b.c"
  input DAE.ComponentRef connectorRef;
  output DAE.ComponentRef prefixCon;
algorithm
  prefixCon := matchcontinue(connectorRef)
    local
      DAE.ComponentRef child;
      String name;
      list<DAE.Subscript> subs;
      DAE.Type ty;

    // If the bottom var is a connector, then it is not an outside connector. (spec 0.1.2)
    case(DAE.CREF_IDENT(_,_,_))
      equation
        // print(name + " is not a outside connector \n");
      then
        fail();

    case(DAE.CREF_QUAL(name,(ty as DAE.T_COMPLEX(complexClassType=ClassInf.CONNECTOR(_,_))),subs,_))
      then ComponentReference.makeCrefIdent(name,ty,subs);

    case(DAE.CREF_QUAL(name,ty,subs,child))
      equation
        child = extractConnectorPrefix(child);
      then
        ComponentReference.makeCrefQual(name,ty,subs,child);

  end matchcontinue;
end extractConnectorPrefix;

protected function updateCrefTypesWithConnectorPrefix "
Author: BZ, 2009-09
Helper function for updateTypesInUnconnectedConnectors2"
  input DAE.ComponentRef cr1,cr2;
  output DAE.ComponentRef outCref;
algorithm outCref := matchcontinue(cr1,cr2)
  local
    String name,name2;
    DAE.ComponentRef child,child2;
    DAE.Type ty;
    list<DAE.Subscript> subs;
  case (DAE.CREF_IDENT(name,ty,subs),DAE.CREF_QUAL(name2,_,_,child2))
    equation
      true = stringEq(name,name2);
    then
      ComponentReference.makeCrefQual(name,ty,subs,child2);

  case (DAE.CREF_QUAL(name,ty,subs,child),DAE.CREF_QUAL(name2,_,_,child2))
    equation
      true = stringEq(name,name2);
      outCref = updateCrefTypesWithConnectorPrefix(child,child2);
    then
      ComponentReference.makeCrefQual(name,ty,subs,outCref);
  else
    equation
      print(" ***** FAILURE with " + ComponentReference.printComponentRefStr(cr1) + " _and_ " + ComponentReference.printComponentRefStr(cr2) + "\n");
    then fail();
  end matchcontinue;
end updateCrefTypesWithConnectorPrefix;

protected function checkClassEqual
  input SCode.Element c1;
  input SCode.Element c2;
  output Boolean areEqual;
algorithm
  areEqual := matchcontinue(c1, c2)
    local
      SCode.Restriction r;
      list<SCode.AlgorithmSection> normalAlgorithmLst1,normalAlgorithmLst2;
      list<SCode.AlgorithmSection> initialAlgorithmLst1,initialAlgorithmLst2;
      SCode.ClassDef cd1, cd2;

    // when +g=MetaModelica, check class equality!
    case (_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        failure(equality(c1 = c2));
      then
        false;

    // check the types for equality!
    case (SCode.CLASS(restriction = SCode.R_TYPE()),_)
      equation
        failure(equality(c1 = c2));
      then
        false;

    // anything else but functions, do not check equality
    case (SCode.CLASS(restriction = r),_)
      equation
        false = SCode.isFunctionRestriction(r);
      then
        true;

    // check the class equality only for functions, made of parts
    case (SCode.CLASS(classDef=SCode.PARTS(normalAlgorithmLst=normalAlgorithmLst1, initialAlgorithmLst=initialAlgorithmLst1)),
          SCode.CLASS(classDef=SCode.PARTS(normalAlgorithmLst=normalAlgorithmLst2, initialAlgorithmLst=initialAlgorithmLst2)))
      equation
        // only check if algorithm list lengths are the same!
        true = intEq(listLength(normalAlgorithmLst1), listLength(normalAlgorithmLst2));
        true = intEq(listLength(initialAlgorithmLst1), listLength(initialAlgorithmLst2));
      then
        true;
    // check the class equality only for functions, made of derived
    case (SCode.CLASS(classDef=cd1 as SCode.DERIVED()),
          SCode.CLASS(classDef=cd2 as SCode.DERIVED()))
      equation
        // only check class definitions are the same!
        equality(cd1 = cd2);
      then
        true;
    // anything else, false!
    else false;
  end matchcontinue;
end checkClassEqual;

public function prefixEqualUnlessBasicType
"Checks if two prefixes are equal, unless the class is a
 basic type, i.e. all reals, integers, enumerations with
 the same name, etc. are equal."
  input Prefix.Prefix pre1;
  input Prefix.Prefix pre2;
  input SCode.Element cls;
algorithm
  _ := matchcontinue (pre1, pre2, cls)
    local
    // adrpo: TODO! FIXME!, I think here we should have pre1 = Prefix.CLASSPRE(variability1) == pre2 = Prefix.CLASSPRE(variability2)

    // don't care about prefix for:
    // - enumerations
    // - types as they cannot have components
    // - predefined types as they cannot have components
    case (_, _, SCode.CLASS(restriction = SCode.R_ENUMERATION())) then ();
    // case (_, _, SCode.CLASS(restriction = SCode.R_TYPE())) then ();
    case (_, _, SCode.CLASS(restriction = SCode.R_PREDEFINED_ENUMERATION())) then ();
    case (_, _, SCode.CLASS(restriction = SCode.R_PREDEFINED_INTEGER())) then ();
    case (_, _, SCode.CLASS(restriction = SCode.R_PREDEFINED_REAL())) then ();
    case (_, _, SCode.CLASS(restriction = SCode.R_PREDEFINED_STRING())) then ();
    case (_, _, SCode.CLASS(restriction = SCode.R_PREDEFINED_BOOLEAN())) then ();
    // BTH
    case (_, _, SCode.CLASS(restriction = SCode.R_PREDEFINED_CLOCK())) then ();
    // don't care about prefix for:
    // - Real, String, Integer, Boolean
    case (_, _, SCode.CLASS(name = "Real")) then ();
    case (_, _, SCode.CLASS(name = "Integer")) then ();
    case (_, _, SCode.CLASS(name = "String")) then ();
    case (_, _, SCode.CLASS(name = "Boolean")) then ();
    // BTH
    case (_, _, SCode.CLASS(name = "Clock"))
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then ();

    // anything else, check for equality!
    else
      equation
        equality(pre1 = pre2);
      then ();
  end matchcontinue;
end prefixEqualUnlessBasicType;

public function isBuiltInClass "
Author: BZ, this function identifies built in classes."
  input String className;
  output Boolean b;
algorithm
  b := match(className)
    case("Real") then true;
    case("Integer") then true;
    case("String") then true;
    case("Boolean") then true;
    // BTH
    case("Clock") then intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
    else false;
  end match;
end isBuiltInClass;

protected function equalityConstraintOutputDimension
  input list<SCode.Element> inElements;
  output Integer outDimension;
algorithm
  outDimension := matchcontinue(inElements)
  local
    list<SCode.Element> tail;
    Integer dim;
    case({}) equation
      then 0;
    case(SCode.COMPONENT(attributes = SCode.ATTR(
        direction = Absyn.OUTPUT(),
        arrayDims = {Absyn.SUBSCRIPT(Absyn.INTEGER(dim))}
      )) :: _) equation
      then dim;
    case(_ :: tail) equation
      dim = equalityConstraintOutputDimension(tail);
      then dim;
  end matchcontinue;
end equalityConstraintOutputDimension;

public function equalityConstraint
  "  Tests if the given elements contain equalityConstraint function and returns
    corresponding DAE.EqualityConstraint."
  input FCore.Graph inEnv;
  input list<SCode.Element> inCdefelts;
  input SourceInfo info;
  output DAE.EqualityConstraint outResult;
algorithm
  outResult := matchcontinue(inEnv,inCdefelts,info)
  local
      list<SCode.Element> tail, els;
      FCore.Graph env;
      Absyn.Path path;
      Integer dimension;
      DAE.InlineType inlineType;
      SCode.Element el;

    case(_,{},_) then NONE();

    case(env, (el as SCode.CLASS(name = "equalityConstraint", restriction = SCode.R_FUNCTION(_),
         classDef = SCode.PARTS(elementLst = els))) :: _, _)
      equation
        SOME(path) = FGraph.getScopePath(env);
        path = Absyn.joinPaths(path, Absyn.IDENT("equalityConstraint"));
        path = Absyn.makeFullyQualified(path);
        /*(cache, env,_) = implicitFunctionTypeInstantiation(cache, env, classDef);
        (cache, types,_) = Lookup.lookupFunctionsInEnv(cache, env, path, info);
        length = listLength(types);
        print("type count: ");
        print(intString(length));
        print("\n");*/
        dimension = equalityConstraintOutputDimension(els);
        /*print("dimension: ");
        print(intString(dimension));
        print("\n");*/
        // adrpo: get the inline type of the function
        inlineType = isInlineFunc(el);
      then
        SOME((path, dimension, inlineType));

    case(env, _ :: tail, _)
      then
        equalityConstraint(env, tail, info);

  end matchcontinue;
end equalityConstraint;

public function handleUnitChecking
"@author: adrpo
 do this unit checking ONLY if we have the flag!"
  input FCore.Cache cache;
  input FCore.Graph env;
  input UnitAbsyn.InstStore inStore;
  input Prefix.Prefix pre;
  input DAE.DAElist compDAE;
  input list<DAE.DAElist> daes;
  input String className "for debugging";
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output UnitAbsyn.InstStore outStore;
algorithm
  (outCache,outEnv,outStore) := matchcontinue(cache,env,inStore,pre,compDAE,daes,className)
    local
      DAE.DAElist daetemp;
      UnitAbsyn.UnitTerms ut;
      UnitAbsyn.InstStore store;

    // do nothing if we don't have to do unit checking
    case (_,_,store,_,_,_,_)
      equation
        false = Flags.getConfigBool(Flags.UNIT_CHECKING);
      then
        (cache,env,store);

    case (_,_,store,_,_,_,_)
      equation
        // Perform unit checking/dimensional analysis
        //(daetemp,_) = ConnectUtil.equations(csets,pre,false,ConnectionGraph.EMPTY); // ToDO. calculation of connect eqns done twice. remove in future.
        // equations from components (dae1) not considered, they are checked in resp recursive call
        // but bindings on scalar variables must be considered, therefore passing dae1 separately
        //daetemp = DAEUtil.joinDaeLst(daetemp::daes);
        daetemp = DAEUtil.joinDaeLst(daes);
        (store,ut)=  UnitAbsynBuilder.instBuildUnitTerms(env,daetemp,compDAE,store);

        //print("built store for "+className+"\n");
        //UnitAbsynBuilder.printInstStore(store);
        //print("terms for "+className+"\n");
        //UnitAbsynBuilder.printTerms(ut);

        UnitAbsynBuilder.registerUnitWeights(cache,env,compDAE);

        // perform the check
        store = UnitChecker.check(ut,store);

        //print("store for "+className+"\n");
        //UnitAbsynBuilder.printInstStore(store);
        //print("dae1="+DAEDump.dumpDebugDAE(DAE.DAE(dae1))+"\n");
     then
       (cache,env,store);
  end matchcontinue;
end  handleUnitChecking;

protected function checkExtendsRestrictionMatch
"see Modelica Specfification 3.1, 7.1.3 Restrictions on the Kind of Base Class"
  input SCode.Restriction r1;
  input SCode.Restriction r2;
algorithm
  _ := match(r1, r2)
    // package can be extendended by package
    case (SCode.R_PACKAGE(), SCode.R_PACKAGE()) then ();
    // normal function -> normal function
    case (SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(_)), SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(_))) then ();
    // external function -> normal function
    case (SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(_)), SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(_))) then ();
    // operator function -> normal function
    case (SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()), SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(_))) then ();
    // operator function -> operator function
    case (SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()), SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION())) then ();
    // type -> type
    case (SCode.R_TYPE(), SCode.R_TYPE()) then ();
    // record -> record
    case (SCode.R_RECORD(_), SCode.R_RECORD(_)) then ();
    // connector -> type
    case (SCode.R_CONNECTOR(_), SCode.R_TYPE()) then ();
    // connector -> record
    case (SCode.R_CONNECTOR(_), SCode.R_RECORD(_)) then ();
    // connector -> connector
    case (SCode.R_CONNECTOR(_), SCode.R_CONNECTOR(_)) then ();
    // block -> record
    case (SCode.R_BLOCK(), SCode.R_RECORD(false)) then ();
    // block -> block
    case (SCode.R_BLOCK(), SCode.R_BLOCK()) then ();
    // model -> record
    case (SCode.R_MODEL(), SCode.R_RECORD(false)) then ();
    // model -> block
    case (SCode.R_MODEL(), SCode.R_BLOCK()) then ();
    // model -> model
    case (SCode.R_MODEL(), SCode.R_MODEL()) then ();

    // class??? same restrictions as model?
    // model -> class
    case (SCode.R_MODEL(), SCode.R_CLASS()) then ();
    // class -> model
    case (SCode.R_CLASS(), SCode.R_MODEL()) then ();
    // class -> record
    case (SCode.R_CLASS(), SCode.R_RECORD(_)) then ();
    // class -> block
    case (SCode.R_CLASS(), SCode.R_BLOCK()) then ();
    // class -> class
    case (SCode.R_CLASS(), SCode.R_CLASS()) then ();
    // operator -> operator
    case (SCode.R_OPERATOR(), SCode.R_OPERATOR()) then ();
  end match;
end checkExtendsRestrictionMatch;

protected function checkExtendsForTypeRestiction
"@author: adrpo
  This function will check extends for Modelica 3.1 restrictions"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Restriction inRestriction;
  input list<SCode.Element> inSCodeElementLst;
algorithm
  _ := matchcontinue(inCache, inEnv, inIH, inRestriction, inSCodeElementLst)
    local
      Absyn.Path p;
      SCode.Restriction r1, r2, r;
      String id;

    // check the basics ....
    // type or connector can be extended by a type
    case (_, _, _, r, {SCode.EXTENDS(baseClassPath=Absyn.IDENT(id))})
      equation
        true = listMember(r, {SCode.R_TYPE(), SCode.R_CONNECTOR(false), SCode.R_CONNECTOR(true)});
        true = listMember(id, {"Real", "Integer", "Boolean", "String"});
      then ();

    //BTH same as above but extended with Clock type if Flags.SYNCHRONOUS_FEATURES == true
    case (_, _, _, r, {SCode.EXTENDS(baseClassPath=Absyn.IDENT(id))})
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
        true = listMember(r, {SCode.R_TYPE(), SCode.R_CONNECTOR(false), SCode.R_CONNECTOR(true)});
        true = listMember(id, {"Real", "Integer", "Boolean", "String", "Clock"});
      then ();

    // we haven't found the class, do nothing
    case (_, _, _, _, {SCode.EXTENDS(baseClassPath=p)})
      equation
        failure((_, _, _) = Lookup.lookupClass(inCache, inEnv, p));
      then ();

    // we found te class, check the restriction
    case (_, _, _, r1, {SCode.EXTENDS(baseClassPath=p)})
      equation
        (_,SCode.CLASS(restriction=r2),_) = Lookup.lookupClass(inCache,inEnv,p);
        checkExtendsRestrictionMatch(r1, r2);
      then ();

    // make some waves that this is not correct
    case (_, _, _, r1, {SCode.EXTENDS(baseClassPath=p)})
      equation
        (_,SCode.CLASS(restriction=r2),_) = Lookup.lookupClass(inCache, inEnv, p);
        print("Error!: " + SCodeDump.restrString(r1) + " " + FGraph.printGraphPathStr(inEnv) +
              " cannot be extended by " + SCodeDump.restrString(r2) + " " + Absyn.pathString(p) + " due to derived/base class restrictions.\n");
      then fail();
  end matchcontinue;
end checkExtendsForTypeRestiction;

public function checkDerivedRestriction
  input SCode.Restriction parentRestriction;
  input SCode.Restriction childRestriction;
  input SCode.Ident childName;
  output Boolean b;
protected
  Boolean b1, b2, b3, b4;
  list<String> strLst;
  list<SCode.Restriction> rstLst;
algorithm
  // BTH add Clock type to both lists if Flags.SYNCHRONOUS_FEATURES == true
  strLst := if intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33)
      then {"Real", "Integer", "String", "Boolean", "Clock"}
      else {"Real", "Integer", "String", "Boolean"};
  b1 := listMember(childName, strLst);

  rstLst := if intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33)
      then {SCode.R_TYPE(), SCode.R_PREDEFINED_INTEGER(), SCode.R_PREDEFINED_REAL(), SCode.R_PREDEFINED_STRING(), SCode.R_PREDEFINED_BOOLEAN(), SCode.R_PREDEFINED_CLOCK()}
      else {SCode.R_TYPE(), SCode.R_PREDEFINED_INTEGER(), SCode.R_PREDEFINED_REAL(), SCode.R_PREDEFINED_STRING(), SCode.R_PREDEFINED_BOOLEAN()};
  b2 := listMember(childRestriction, rstLst);

  b3 := valueEq(parentRestriction, SCode.R_TYPE());

  //b2 := listMember(childRestriction, {SCode.R_TYPE(), SCode.R_ENUMERATION(), SCode.R_PREDEFINED_INTEGER(), SCode.R_PREDEFINED_REAL(), SCode.R_PREDEFINED_STRING(), SCode.R_PREDEFINED_BOOLEAN(), SCode.R_PREDEFINED_ENUMERATION()});
  //b3 := boolOr(valueEq(parentRestriction, SCode.R_TYPE()), valueEq(parentRestriction, SCode.R_ENUMERATION()));

  b4 := valueEq(parentRestriction, SCode.R_CONNECTOR(false)) or valueEq(parentRestriction, SCode.R_CONNECTOR(true));
  // basically if child or parent is a type or basic type or parent is a connector and child is a type
  b := boolOr(b1, boolOr(b2, boolOr(b3, boolAnd(boolOr(b1,b2), b4))));
end checkDerivedRestriction;

public function addExpandable
  input list<SCode.Equation> inEqs;
  input list<SCode.Equation> inExpandable;
  output list<SCode.Equation> outEqs;
algorithm
  outEqs := match(inEqs, inExpandable)
    // nothing
    case (_, {}) then inEqs;
    // if is only one, don't append!
    case (_, {_}) then inEqs;
    // if is more than one, append
    else listAppend(inEqs, inExpandable);
  end match;
end addExpandable;

public function matchModificationToComponents "
Author: BZ, 2009-05
This function is called from instClassDef, recursivly remove modifers on each component.
What ever is left in modifier is printed as a warning. That means that we have modifiers on a component that does not exist."
  input list<SCode.Element> inElems;
  input DAE.Mod inmod;
  input String callingScope;
algorithm
  _ := matchcontinue(inElems, inmod, callingScope)
    local
      SCode.Element elem;
      String cn,s1,s2;
      list<SCode.Element> elems;
      DAE.Mod mod;

    case(_,DAE.NOMOD(),_) then ();
    case(_,DAE.MOD(subModLst={}),_) then ();

    case({},_,_)
      equation
        s1 = Mod.prettyPrintMod(inmod,0);
        s2 = s1 + " not found in <" + callingScope + ">";
        // Line below can be used for testing test-suite for dangling modifiers when getErrorString() is not called.
        //print(" *** ERROR Unused modifer...: " + s2 + "\n");
        Error.addMessage(Error.UNUSED_MODIFIER,{s2});
      then
        fail();

    case((SCode.COMPONENT(name=cn))::elems,mod,_)
      equation
        mod = Mod.removeMod(mod,cn);
        matchModificationToComponents(elems,mod,callingScope);
      then
        ();

    case((SCode.EXTENDS())::elems,_,_)
      equation matchModificationToComponents(elems,inmod,callingScope); then ();
        //TODO: only remove modifiers on replaceable classes, make special case for redeclaration of local classes

    case((SCode.CLASS(name=cn,prefixes=SCode.PREFIXES()))::elems,mod,_)
      equation
        mod = Mod.removeMod(mod,cn);
        matchModificationToComponents(elems,mod,callingScope);
      then ();

    case((SCode.IMPORT())::elems,_,_)
      equation
        matchModificationToComponents(elems,inmod,callingScope);
      then ();

    case( (SCode.CLASS(prefixes=SCode.PREFIXES(replaceablePrefix=SCode.NOT_REPLACEABLE())))::elems,_,_)
      equation
        matchModificationToComponents(elems,inmod,callingScope);
      then ();
  end matchcontinue;
end matchModificationToComponents;

protected function elementNameMember
"Returns true if the given element is in the list"
  input tuple<SCode.Element, DAE.Mod> inElement;
  input list<SCode.Element> els;
  output Boolean isNamed;
algorithm
  isNamed := match(inElement, els)
    local
      Boolean b;

    case (_, _)
      equation
        b = listMember(Util.tuple21(inElement), els);
      then b;
  end match;
end elementNameMember;

public function extractConstantPlusDepsTpl "
Author: adrpo, see extractConstantPlusDeps for comments"
  input list<tuple<SCode.Element, DAE.Mod>> inComps;
  input Option<DAE.ComponentRef> ocr;
  input list<SCode.Element> allComps;
  input String className;
  input list<SCode.Equation> ieql;
  input list<SCode.Equation> iieql;
  input list<SCode.AlgorithmSection> ialgs;
  input list<SCode.AlgorithmSection> iialgs;
  output list<tuple<SCode.Element, DAE.Mod>> oel;
  output list<SCode.Equation> oeql;
  output list<SCode.Equation> oieql;
  output list<SCode.AlgorithmSection> oalgs;
  output list<SCode.AlgorithmSection> oialgs;
algorithm
  (oel, oeql, oieql, oalgs, oialgs)
    := matchcontinue(inComps, ocr, allComps, className, ieql, iieql, ialgs, iialgs)
    local
      DAE.ComponentRef cr;
      list<SCode.Element> all, lst;

    // handle empty!
     case({}, _, _, _, _, _, _, _) then ({}, ieql, iieql, ialgs, iialgs);

    // handle none
    case (_, NONE(), _, _, _, _, _, _) then (inComps, ieql, iieql, ialgs, iialgs);

    // handle some
    case(_, SOME(_), _, _, _, _, _, _)
      equation
        lst = List.map(inComps, Util.tuple21);
        lst = extractConstantPlusDeps2(lst, ocr, allComps, className, {});
        false = listEmpty(lst);
        lst = listReverse(lst);
        oel = List.filter1OnTrue(inComps, elementNameMember, lst);
      then
        (oel, {}, {}, {}, {});

    case(_, SOME(cr), _, _, _, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- InstUtil.extractConstantPlusDeps failure to find " + ComponentReference.printComponentRefStr(cr) + ", returning \n");
        Debug.trace("- InstUtil.extractConstantPlusDeps elements to instantiate:" + intString(listLength(inComps)) + "\n");
      then fail(); // TODO: This used to return the input only if failtrace was set; should it always succeed?
  end matchcontinue;
end extractConstantPlusDepsTpl;

public function extractConstantPlusDeps "
Author: BZ, 2009-04
This function filters the list of elements to instantiate depending on optional(DAE.ComponentRef), the
optional argument is set in Lookup.lookupVarInPackages.
If it is set, we are only looking for one variable in current scope hence we are not interested in
instantiating more then nescessary.

The actuall action of this function is to compare components to the DAE.ComponentRef name
if it is found return that component and any dependant components(modifiers), this is done by calling the function recursivly.

If the component specified in argument 2 is not found, we return all extend and import statements.
TODO: search import and extends statements for specified variable.
      this includes to check class definitions to so that we do not need to instantiate local class definitions while looking for a constant."
  input list<SCode.Element> inComps;
  input Option<DAE.ComponentRef> ocr;
  input list<SCode.Element> allComps;
  input String className;
  output list<SCode.Element> outComps;
algorithm
  outComps := matchcontinue(inComps, ocr, allComps, className)
    local
      DAE.ComponentRef cr;

    // handle empty!
    // case({}, _, allComps, className) then {};

    // handle none
    case (_,NONE(),_,_) then inComps;

    // handle StateSelect as we will NEVER find it!
    // case(inComps, SOME(DAE.CREF_QUAL(ident="StateSelect")), allComps, className) then inComps;

    // handle some
    case(_, SOME(_), _, _)
      equation
        outComps = extractConstantPlusDeps2(inComps, ocr, allComps, className,{});
        false = listEmpty(outComps);
        outComps = listReverse(outComps);
      then
        outComps;

    case(_, SOME(cr), _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- InstUtil.extractConstantPlusDeps failure to find " + ComponentReference.printComponentRefStr(cr) + ", returning \n");
        Debug.trace("- InstUtil.extractConstantPlusDeps elements to instantiate:" + intString(listLength(inComps)) + "\n");
      then fail(); // TODO: This used to return the input only if failtrace was set; should it always succeed?
  end matchcontinue;
end extractConstantPlusDeps;

protected function extractConstantPlusDeps2 "
Author: BZ, 2009-04
Helper function for extractConstantPlusDeps"
  input list<SCode.Element> inComps;
  input Option<DAE.ComponentRef> ocr;
  input list<SCode.Element> inAllComps;
  input String className;
  input list<String> inExisting;
  output list<SCode.Element> outComps;
algorithm
  outComps := matchcontinue(inComps,ocr,inAllComps,className,inExisting)
    local
      SCode.Element compMod;
      list<SCode.Element> recDeps;
      SCode.Element selem;
      String name,name2;
      SCode.Mod scmod;
      DAE.ComponentRef cr;
      list<Absyn.ComponentRef> crefs;
      Absyn.Path p;
      list<SCode.Element> comps;
      list<SCode.Element> allComps;
      list<String> existing;

    case({},SOME(_),_,_,_)
      equation
        //print(" failure to find: " + ComponentReference.printComponentRefStr(cr) + " in scope: " + className + "\n");
      then {};
    case({},_,_,_,_) then fail();
    case (_,NONE(),_,_,_) then inComps;
      /*
    case( (selem as SCode.CLASS(name=name2))::comps,SOME(DAE.CREF_IDENT(ident=name)),allComps,className,existing)
      equation
        true = stringEq(name,name2);
        outComps = extractConstantPlusDeps2(comps,ocr,allComps,className,existing);
      then
        selem::outComps;
        */
    case( ((selem as SCode.CLASS(name=name2)))::comps,SOME(DAE.CREF_IDENT()),allComps,_,existing)
      equation
        //false = stringEq(name,name2);
        allComps = selem::allComps;
        existing = name2::existing;
        outComps = extractConstantPlusDeps2(comps,ocr,allComps,className,existing);
      then //extractConstantPlusDeps2(comps,ocr,allComps,className,existing);
         selem::outComps;

    case((selem as SCode.COMPONENT(name=name2,modifications=scmod))::comps,SOME(DAE.CREF_IDENT(ident=name)),allComps,_,existing)
      equation
        true = stringEq(name,name2);
        crefs = getCrefFromMod(scmod);
        allComps = listAppend(comps,allComps);
        existing = name2::existing;
        recDeps = extractConstantPlusDeps3(crefs,allComps,className,existing);
      then
        selem::recDeps;

    case( ( (selem as SCode.COMPONENT(name=name2)))::comps,SOME(DAE.CREF_IDENT(ident=name)),allComps,_,existing)
      equation
        false = stringEq(name,name2);
        allComps = selem::allComps;
      then extractConstantPlusDeps2(comps,ocr,allComps,className,existing);

    case((compMod as SCode.EXTENDS())::comps,(SOME(DAE.CREF_IDENT())),allComps,_,existing)
      equation
        allComps = compMod::allComps;
        recDeps = extractConstantPlusDeps2(comps,ocr,allComps,className,existing);
        then
          compMod::recDeps;
    case((compMod as SCode.IMPORT())::comps,(SOME(DAE.CREF_IDENT())),allComps,_,existing)
      equation
        allComps = compMod::allComps;
        recDeps = extractConstantPlusDeps2(comps,ocr,allComps,className,existing);
      then
        compMod::recDeps;

    case((compMod as SCode.DEFINEUNIT())::comps,(SOME(DAE.CREF_IDENT())),allComps,_,existing)
      equation
        allComps = compMod::allComps;
        recDeps = extractConstantPlusDeps2(comps,ocr,allComps,className,existing);
      then
        compMod::recDeps;
    else
      equation
        //debug_print("all",  (inComps, ocr, allComps, className, existing));
        print(" failure in get_Constant_PlusDeps \n");
      then fail();
end matchcontinue;
end extractConstantPlusDeps2;

protected function extractConstantPlusDeps3 "
Author: BZ, 2009-04
Helper function for extractConstantPlusDeps"
  input list<Absyn.ComponentRef> inAcrefs;
  input list<SCode.Element> remainingComps;
  input String className;
  input list<String> inExisting;
  output list<SCode.Element> outComps;
algorithm outComps := matchcontinue(inAcrefs,remainingComps,className,inExisting)
  local
    String s1,s2;
    Absyn.ComponentRef acr;
    list<SCode.Element> localComps;
    list<String> names;
    DAE.ComponentRef cref_;
    list<Absyn.ComponentRef> acrefs;
    list<String> existing;

  case({},_,_,_) then {};

  case (Absyn.CREF_FULLYQUALIFIED(acr) :: acrefs, _, _, existing)
    then extractConstantPlusDeps3(acr :: acrefs, remainingComps, className, existing);

  case(Absyn.CREF_QUAL(s1,_,(acr as Absyn.CREF_IDENT(_,_)))::acrefs,_,_,existing)
    equation
      true = stringEq(className,s1); // in same scope look up.
      acrefs = acr::acrefs;
    then
      extractConstantPlusDeps3(acrefs,remainingComps,className,existing);
  case((Absyn.CREF_QUAL(s1,_,_))::acrefs,_,_,existing)
    equation
      false = stringEq(className,s1);
      outComps = extractConstantPlusDeps3(acrefs,remainingComps,className,existing);
    then
      outComps;
  case(Absyn.CREF_IDENT(s1,_)::acrefs,_,_,existing) // modifer dep already added
    equation
      true = List.isMemberOnTrue(s1,existing,stringEq);
    then
      extractConstantPlusDeps3(acrefs,remainingComps,className,existing);
  case(Absyn.CREF_IDENT(s1,_)::acrefs,_,_,existing)
    equation
      cref_ = ComponentReference.makeCrefIdent(s1,DAE.T_UNKNOWN_DEFAULT,{});
      localComps = extractConstantPlusDeps2(remainingComps,SOME(cref_),{},className,existing);
      names = SCode.componentNamesFromElts(localComps);
      existing = listAppend(names,existing);
      outComps = extractConstantPlusDeps3(acrefs,remainingComps,className,existing);
      outComps = listAppend(localComps,outComps);
    then
      outComps;
  end matchcontinue;
end extractConstantPlusDeps3;

public function removeSelfReference
"@author adrpo
 Removes self reference from a path if it exists.
 Examples:
   removeSelfReference('Icons', 'Icons.BaseLibrary') => 'BaseLibrary'
   removeSelfReference('Icons', 'BlaBla.BaseLibrary') => 'BlaBla.BaseLibrary'"
  input  String     className;
  input  Absyn.Path path;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue (className, path)
    local
      String clsName;
      Absyn.Path p, newPath;
    case(clsName, p) // self reference, remove the first.
      equation
        true = stringEq(clsName, Absyn.pathFirstIdent(p));
        newPath = Absyn.removePrefix(Absyn.IDENT(clsName), p);
      then
        newPath;
    case(clsName, p) // not self reference, return the same.
      equation
        false = stringEq(clsName, Absyn.pathFirstIdent(p));
      then
        p;
  end matchcontinue;
end removeSelfReference;

public function printExtcomps
"prints the tuple of elements and modifiers to stdout"
  input list<tuple<SCode.Element, DAE.Mod>> inElements;
algorithm
  _ := match (inElements)
    local
      String s;
      SCode.Element el;
      DAE.Mod mod;
      list<tuple<SCode.Element, DAE.Mod>> els;
    case ({}) then ();
    case (((el,mod) :: els))
      equation
        s = SCodeDump.unparseElementStr(el,SCodeDump.defaultOptions);
        print(s);
        print(", ");
        print(Mod.printModStr(mod));
        print("\n");
        printExtcomps(els);
      then
        ();
  end match;
end printExtcomps;

public function constantEls
"Returns only elements that are constants or have annotation(Evaluate = true)!
 author: PA & adrpo
 Used buy partialInstClassdef to instantiate constants in packages."
  input list<SCode.Element> elements;
  output list<SCode.Element> outElements;
algorithm
  outElements := matchcontinue (elements)
    local
      SCode.Attributes attr;
      SCode.Element el;
      list<SCode.Element> els,els1;
      SCode.Comment cmt;

    case ({}) then {};

    // constants
    case ((el as SCode.COMPONENT(attributes=attr))::els)
     equation
        true = SCode.isConstant(SCode.attrVariability(attr)); // or SCode.getEvaluateAnnotation(cmt);
        els1 = constantEls(els);
    then (el::els1);

    /*/ final parameters
    case ((el as SCode.COMPONENT(prefixes = SCode.PREFIXES(finalPrefix = SCode.FINAL()), attributes=attr))::els)
     equation
        true = SCode.isParameterOrConst(SCode.attrVariability(attr));
        els1 = constantEls(els);
    then (el::els1);*/

    case (_::els)
      equation
        els1 = constantEls(els);
     then els1;
  end matchcontinue;
end constantEls;

public function constantAndParameterEls
"Returns only elements that are constants.
 author: @adrpo
 Used by partialInstClassdef to instantiate constants and parameters in packages."
  input list<SCode.Element> elements;
  output list<SCode.Element> outElements;
algorithm
  outElements := matchcontinue (elements)
    local
      SCode.Attributes attr;
      SCode.Element el;
      list<SCode.Element> els,els1;

    case ({}) then {};

    case ((el as SCode.COMPONENT(attributes=attr))::els)
     equation
        true = SCode.isParameterOrConst(SCode.attrVariability(attr));
        els1 = constantAndParameterEls(els);
    then (el::els1);

    case (_::els)
      equation
        els1 = constantAndParameterEls(els);
     then els1;
  end matchcontinue;
end constantAndParameterEls;

protected function removeBindings
"remove bindings for all elements if we do partial instantiation"
  input list<SCode.Element> elements;
  output list<SCode.Element> outElements;
algorithm
  outElements := matchcontinue (elements)
    local
      SCode.Element el;
      list<SCode.Element> els,els1;
      SCode.Ident name "the component name";
      SCode.Prefixes prefixes "the common class or component prefixes";
      SCode.Attributes attributes "the component attributes";
      Absyn.TypeSpec typeSpec "the type specification";
      SCode.Mod modifications "the modifications to be applied to the component";
      SCode.Comment comment "this if for extraction of comments and annotations from Absyn";
      Option<Absyn.Exp> condition "the conditional declaration of a component";
      SourceInfo info "this is for line and column numbers, also file name.";

    case ({}) then {};

    case ((SCode.COMPONENT(name, prefixes, attributes, typeSpec, _, comment, condition, info))::els)
      equation
        els1 = removeBindings(els);
      then (SCode.COMPONENT(name, prefixes, attributes, typeSpec, SCode.NOMOD(), comment, condition, info)::els1);

    case (el::els)
      equation
        els1 = removeBindings(els);
      then el::els1;
  end matchcontinue;
end removeBindings;

protected function removeExtBindings
"remove bindings for all elements if we do partial instantiation"
  input list<tuple<SCode.Element, DAE.Mod>> elements;
  output list<tuple<SCode.Element, DAE.Mod>> outElements;
algorithm
  outElements := matchcontinue (elements)
    local
      tuple<SCode.Element, DAE.Mod> el;
      list<tuple<SCode.Element, DAE.Mod>> els,els1;
      SCode.Ident name "the component name";
      SCode.Prefixes prefixes "the common class or component prefixes";
      SCode.Attributes attributes "the component attributes";
      Absyn.TypeSpec typeSpec "the type specification";
      SCode.Mod modifications "the modifications to be applied to the component";
      SCode.Comment comment "this if for extraction of comments and annotations from Absyn";
      Option<Absyn.Exp> condition "the conditional declaration of a component";
      SourceInfo info "this is for line and column numbers, also file name.";

    case ({}) then {};

    case ((SCode.COMPONENT(name, prefixes, attributes, typeSpec, _, comment, condition, info),_)::els)
      equation
        els1 = removeExtBindings(els);
      then ((SCode.COMPONENT(name, prefixes, attributes, typeSpec, SCode.NOMOD(), comment, condition, info),DAE.NOMOD())::els1);

    case (el::els)
      equation
        els1 = removeExtBindings(els);
      then el::els1;
  end matchcontinue;
end removeExtBindings;

public function getModsForDep "
Author: BZ, 2009-08
Extract modifer for dependent variables(dep)."
  input Absyn.ComponentRef inDepCref;
  input list<tuple<SCode.Element, DAE.Mod>> inElems;
  output DAE.Mod omods;
algorithm
  omods := matchcontinue(inDepCref,inElems)
    local
      String name1,name2;
      DAE.Mod cmod;
      tuple<SCode.Element, DAE.Mod> tpl;
      Absyn.ComponentRef dep;
      list<tuple<SCode.Element, DAE.Mod>> elems;

    case(_,{}) then DAE.NOMOD();
    case(dep,((SCode.COMPONENT(),DAE.NOMOD()))::elems)
      then getModsForDep(dep,elems);
    case(dep,((SCode.COMPONENT(name=name1),cmod))::_)
      equation
        name2 = Absyn.printComponentRefStr(dep);
        true = stringEq(name2,name1);
        cmod = DAE.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{DAE.NAMEMOD(name2,cmod)},NONE(), Absyn.dummyInfo);
      then
        cmod;
    case(dep,_::elems)
      equation
        cmod = getModsForDep(dep,elems);
      then
        cmod;
  end matchcontinue;
end getModsForDep;

protected function getOptionArraydim
"Return the Arraydim of an optional arradim.
  Empty list returned if no arraydim present."
  input Option<Absyn.ArrayDim> inAbsynArrayDimOption;
  output Absyn.ArrayDim outArrayDim;
algorithm
  outArrayDim := match (inAbsynArrayDimOption)
    local list<Absyn.Subscript> dim;
    case (SOME(dim)) then dim;
    case (NONE()) then {};
  end match;
end getOptionArraydim;

public function addNomod
"This function takes an SCode.Element list and tranforms it into a
  (SCode.Element Mod) list by inserting DAE.NOMOD() for each element.
  Used to transform elements into a uniform list combined from inherited
  elements and ordinary elements."
  input list<SCode.Element> inElements;
  output list<tuple<SCode.Element, DAE.Mod>> outElements;
algorithm
  outElements := match(inElements)
    local
      list<tuple<SCode.Element, DAE.Mod>> res;
      SCode.Element x;
      list<SCode.Element> xs;
    case {} then {};
    case ((x :: xs))
      equation
        res = addNomod(xs);
      then
        ((x,DAE.NOMOD()) :: res);
  end match;
end addNomod;

public function sortElementList
  "Sorts constants and parameters by dependencies, so that they are instantiated
  before they are used."
  input list<Element> inElements;
  input FCore.Graph inEnv;
  input Boolean isFunctionScope;
  output list<Element> outElements;
  type Element = tuple<SCode.Element, DAE.Mod>;
algorithm
  outElements := matchcontinue(inElements, inEnv, isFunctionScope)
    local
      list<Element> outE,cycleElts;
      list<tuple<Element, list<Element>>> cycles;
      list<tuple<Element, list<Element>>> g;

    // no sorting for meta-modelica!
    case (_, _, _)
      equation
        true = Config.acceptMetaModelicaGrammar();
      then
        inElements;

    // sort the elements according to the dependencies
    else
      equation
        g = Graph.buildGraph(inElements, getElementDependencies, (inElements,isFunctionScope));
        (outE, cycles) = Graph.topologicalSort(g, isElementEqual);
        // printGraph(inEnv, g, outE, cycles);
        // append the elements in the cycles as they might not actually be cycles, but they depend on elements not in the list (i.e. package constants, etc)!
        outE = List.appendNoCopy(outE, List.map(cycles, Util.tuple21));
        checkCyclicalComponents(cycles, inEnv);
      then
        outE;
  end matchcontinue;
end sortElementList;

protected function printGraph
  input FGraph.Graph env;
  input list<tuple<Element, list<Element>>> g;
  input list<Element> order;
  input list<tuple<Element, list<Element>>> cycles;
  type Element = tuple<SCode.Element, DAE.Mod>;
algorithm
  _ := matchcontinue(env, g, order, cycles)
    // nothing for empty graph
    case (_, {}, _, _) then ();
    // show me something!
    case (_, _, _, _)
      equation
        print("Graph for env: " + FGraph.printGraphPathStr(env) + "\n" + Graph.printGraph(g, elementName) + "\n");
        print("Element order:\n\t" + stringDelimitList(List.map(order, elementName), "\n\t") + "\n");
        print("Cycles:\n" + Graph.printGraph(cycles, elementName) + "\n");
      then ();
  end matchcontinue;
end printGraph;

protected function getDepsFromExps
  input list<Absyn.Exp> inExps;
  input list<tuple<SCode.Element, DAE.Mod>> inAllElements;
  input list<tuple<SCode.Element, DAE.Mod>> inDependencies;
  input Boolean isFunction;
  output list<tuple<SCode.Element, DAE.Mod>> outDependencies;
algorithm
  outDependencies := match(inExps, inDependencies)
    local
      list<Absyn.Exp> rest;
      Absyn.Exp e;
      list<tuple<SCode.Element, DAE.Mod>> deps;

    // handle the empty case
    case ({}, _) then inDependencies;
    // handle the normal case
    case (e::rest, deps)
      equation
        //(_, (_, _, (els, deps))) = Absyn.traverseExpBidir(e, (getElementDependenciesTraverserEnter, getElementDependenciesTraverserExit, (inAllElements, deps)));
        //deps = getDepsFromExps(rest, els, deps);
        (_, (_, _, deps, _)) = Absyn.traverseExpBidir(e, getElementDependenciesTraverserEnter, getElementDependenciesTraverserExit, (inAllElements, {}, deps, isFunction));
        deps = getDepsFromExps(rest, inAllElements, deps, isFunction);
      then
        deps;
  end match;
end getDepsFromExps;

protected function removeCurrentElementFromArrayDimDeps
"@author: adrpo
 removes the name from deps (Real A[size(A,1)] dependency)"
  input String name;
  input list<tuple<SCode.Element, DAE.Mod>> inDependencies;
  output list<tuple<SCode.Element, DAE.Mod>> outDependencies;
algorithm
  outDependencies := matchcontinue(name, inDependencies)
    local
      list<tuple<SCode.Element, DAE.Mod>> rest;
      SCode.Element e;
      tuple<SCode.Element, DAE.Mod> dep;

    // handle empty case
    case (_, {}) then {};
    // handle match
    case (_, (e,_)::rest)
      equation
        true = stringEq(name, SCode.elementName(e));
        rest = removeCurrentElementFromArrayDimDeps(name, rest);
      then
        rest;
    // handle rest
    case (_, dep::rest)
      equation
        rest = removeCurrentElementFromArrayDimDeps(name, rest);
      then
        dep::rest;
  end matchcontinue;
end removeCurrentElementFromArrayDimDeps;

public function getExpsFromConstrainClass
  input SCode.Replaceable inRP;
  output list<Absyn.Exp> outBindingExp "the bind exp if any";
  output list<Absyn.Exp> outSubsExps "the expressions from subs";
algorithm
  (outBindingExp, outSubsExps) := match(inRP)
    local
      list<Absyn.Exp> l1, l2;
      SCode.Mod m;

    case (SCode.NOT_REPLACEABLE()) then ({}, {});

    // no cc
    case (SCode.REPLACEABLE(NONE())) then ({}, {});

    // yeha, we have a ccccc :)
    case (SCode.REPLACEABLE(SOME(SCode.CONSTRAINCLASS(modifier = m))))
      equation
        (l1, l2) = getExpsFromMod(m);
      then
        (l1, l2);

  end match;
end getExpsFromConstrainClass;

protected function getExpsFromSubMods
  input list<SCode.SubMod> inSubMods "the component sub modifiers";
  output list<Absyn.Exp> outSubsExps "the expressions from subs";
algorithm
  outSubsExps := match(inSubMods)
    local
      SCode.Mod mod;
      list<SCode.SubMod> rest;
      list<Absyn.Exp> e, exps, sm;


    // handle empty
    case ({}) then {};

    // handle namemod
    case (SCode.NAMEMOD(mod = mod)::rest)
      equation
        (e, sm) = getExpsFromMod(mod);
        exps = getExpsFromSubMods(rest);
        exps = listAppend(e, listAppend(sm, exps));
      then
        exps;

  end match;
end getExpsFromSubMods;

public function getCrefFromMod
  input SCode.Mod inMod "the component modifier";
  output list<Absyn.ComponentRef> outCrefs;
algorithm
  outCrefs := matchcontinue(inMod)
    local
      list<Absyn.Exp> l1, l2;

    case (_)
      equation
        (l1, l2) = getExpsFromMod(inMod);
        outCrefs = List.flatten(List.map2(listAppend(l1, l2), Absyn.getCrefFromExp, true, true));
      then
        outCrefs;

    else
      equation
        print(getInstanceName() + ": could not retrieve crefs from SCode.Mod: " + SCodeDump.printModStr(inMod,SCodeDump.defaultOptions) + "\n");
      then
        fail();

  end matchcontinue;
end getCrefFromMod;

public function getExpsFromMod
  input SCode.Mod inMod "the component modifier";
  output list<Absyn.Exp> outBindingExp "the bind exp if any";
  output list<Absyn.Exp> outSubsExps "the expressions from subs";
algorithm
  (outBindingExp, outSubsExps) := match(inMod)
    local
      list<Absyn.Exp> se, l1, l2, l3, l4;
      Absyn.Exp e;
      list<SCode.SubMod> subs;
      SCode.Element el;
      Option<Absyn.ArrayDim> ado;
      SCode.Mod m;
      Absyn.ArrayDim ad;
      SCode.Replaceable rp;

    // no mods!
    case (SCode.NOMOD()) then ({}, {});
    // the special kind of crappy mods
    case (SCode.MOD(subModLst = {}, binding = NONE())) then ({}, {});

    // mods with binding
    case (SCode.MOD(subModLst = subs, binding = SOME(e)))
      equation
        se = getExpsFromSubMods(subs);
      then
        ({e}, se);

    // mods without binding
    case (SCode.MOD(subModLst = subs, binding = NONE()))
      equation
        se = getExpsFromSubMods(subs);
      then
        ({}, se);

    // redeclare short class, investigate cc mods and own mods/array dims
    case (SCode.REDECL(element = SCode.CLASS(prefixes = SCode.PREFIXES(replaceablePrefix = rp),
                                             classDef = SCode.DERIVED(Absyn.TPATH(_, ado), m, _))))
      equation
        (l1, l2) = getExpsFromConstrainClass(rp);
        (_, se) = Absyn.getExpsFromArrayDimOpt(ado);
        (l3, l4) = getExpsFromMod(m);
        l1 = listAppend(listAppend(se, l1), l3);
        l2 = listAppend(l2, l4);
      then
        (l1, l2);

    // redeclare long class extends class, investigate cc and mods
    case (SCode.REDECL(element = SCode.CLASS(prefixes = SCode.PREFIXES(replaceablePrefix = rp),
                                             classDef = SCode.CLASS_EXTENDS(modifications = m))))
      equation
        (l1, l2) = getExpsFromConstrainClass(rp);
        (l3, l4) = getExpsFromMod(m);
        l1 = listAppend(l1, l3);
        l2 = listAppend(l2, l4);
      then
        (l1, l2);

    // redeclare long class, investigate cc
    case SCode.REDECL(element = SCode.CLASS(prefixes = SCode.PREFIXES(replaceablePrefix = rp)))
      equation
        (l1, l2) = getExpsFromConstrainClass(rp);
      then
        (l1, l2);

    // redeclare component, investigate cc mods and own mods/array dims
    case (SCode.REDECL(element = SCode.COMPONENT(prefixes = SCode.PREFIXES(replaceablePrefix = rp),
                                                 modifications = m, attributes = SCode.ATTR(arrayDims = ad))))
      equation
        (l1, l2) = getExpsFromConstrainClass(rp);
        (_, se) = Absyn.getExpsFromArrayDim(ad);
        (l3, l4) = getExpsFromMod(m);
        l1 = listAppend(listAppend(se, l1), l3);
        l2 = listAppend(l2, l4);
      then
        (l1, l2);

  end match;
end getExpsFromMod;

public function getCrefFromDim
"author: PA
  Similar to getCrefFromMod, but investigates
  array dimensionalitites instead."
  input Absyn.ArrayDim inArrayDim;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm
  outAbsynComponentRefLst := matchcontinue (inArrayDim)
    local
      list<Absyn.ComponentRef> l1,l2,res;
      Absyn.Exp exp;
      list<Absyn.Subscript> rest;
    case ((Absyn.SUBSCRIPT(subscript = exp) :: rest))
      equation
        l1 = getCrefFromDim(rest);
        l2 = Absyn.getCrefFromExp(exp,true,true);
        res = List.union(l1, l2);
      then
        res;
    case ((Absyn.NOSUB() :: rest))
      equation
        res = getCrefFromDim(rest);
      then
        res;
    case ({}) then {};
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- InstUtil.getCrefFromDim failed\n");
      then
        fail();
  end matchcontinue;
end getCrefFromDim;

public function getElementDependencies
  "Returns the dependencies given an element."
  input tuple<SCode.Element, DAE.Mod> inElement;
  input tuple<list<tuple<SCode.Element, DAE.Mod>>, Boolean> inAllElementsAndIsFunctionScope;
  output list<tuple<SCode.Element, DAE.Mod>> outDependencies;
algorithm
  outDependencies := matchcontinue(inElement, inAllElementsAndIsFunctionScope)
    local
      SCode.Variability var;
      Option<Absyn.Exp> cExpOpt;
      list<tuple<SCode.Element, DAE.Mod>> deps;
      DAE.Mod daeMod;
      Absyn.ArrayDim ad;
      list<Absyn.Exp> exps, sexps, bexps;
      SCode.Mod mod;
      String name;
      Boolean hasUnknownDims, isFunctionScope;
      Absyn.Direction direction;
      list<tuple<SCode.Element, DAE.Mod>> inAllElements;
      SCode.Replaceable rp;
      list<SCode.Element> els;
      Option<SCode.ExternalDecl> externalDecl;
      Boolean isFunction;

    // For constants and parameters we check the component conditional, array dimensions, modifiers and binding
    case ((SCode.COMPONENT(name = name, condition = cExpOpt,
                           prefixes = SCode.PREFIXES(replaceablePrefix = rp),
                           attributes = SCode.ATTR(arrayDims = ad, variability = var),
                           modifications = mod), daeMod), (inAllElements, isFunction))
      equation
        true = SCode.isParameterOrConst(var);
        (_, exps) = Absyn.getExpsFromArrayDim(ad);
        (bexps, sexps) = getExpsFromMod(mod);
        exps = listAppend(bexps, listAppend(sexps, exps));
        (bexps, sexps) = getExpsFromConstrainClass(rp);
        exps = listAppend(bexps, listAppend(sexps, exps));
        (bexps, sexps) = getExpsFromMod(Mod.unelabMod(daeMod));
        exps = listAppend(bexps, listAppend(sexps, exps));
        deps = getDepsFromExps(exps, inAllElements, {}, isFunction);
        // remove the current element from the deps as it is usally Real A[size(A,1)]; or self reference FlowModel fm(... blah = fcall(fm.x));
        deps = removeCurrentElementFromArrayDimDeps(name, deps);
        deps = getDepsFromExps(Util.optionList(cExpOpt), inAllElements, deps, isFunction);
        deps = List.union(deps,{});
        // print(name + " deps " + stringDelimitList(list(SCode.elementName(Util.tuple21(e)) for e in deps),",") + "\n");
      then
        deps;

    // For input and output variables in function scope return no dependencies so they stay in order!
    case ((SCode.COMPONENT(attributes = SCode.ATTR(direction = direction)), _), (_, true))
      equation
        true = Absyn.isInputOrOutput(direction);
      then
        {};

    // For other variables we check the condition, since they might be conditional on a constant or parameter.
    case ((SCode.COMPONENT(name = name, condition = cExpOpt,
                           prefixes = SCode.PREFIXES(replaceablePrefix = rp),
                           attributes = SCode.ATTR(arrayDims = ad),
                           modifications = mod), daeMod), (inAllElements, isFunction))
      equation
        (_, exps) = Absyn.getExpsFromArrayDim(ad);
        (bexps, sexps) = getExpsFromMod(mod);
        exps = listAppend(sexps, exps);
        // DO *NOT* ignore the bindings in function scope. We do not want to keep the order!
        exps = listAppend(bexps, exps);
        // exps = if_(hasUnknownDims, listAppend(bexps, exps), exps);
        (bexps, sexps) = getExpsFromConstrainClass(rp);
        exps = listAppend(bexps, listAppend(sexps, exps));
        (bexps, sexps) = getExpsFromMod(Mod.unelabMod(daeMod));
        exps = listAppend(sexps, exps);
        // DO *NOT* ignore the bindings in function scope so we keep the order!
        exps = listAppend(bexps, exps);
        // exps = if_(hasUnknownDims, listAppend(bexps, exps), exps);
        deps = getDepsFromExps(exps, inAllElements, {}, isFunction);
        // remove the current element from the deps as it is usally Real A[size(A,1)];
        deps = removeCurrentElementFromArrayDimDeps(name, deps);
        deps = getDepsFromExps(Util.optionList(cExpOpt), inAllElements, deps, isFunction);
        deps = List.union(deps,{});
        // print(name + " deps " + stringDelimitList(list(SCode.elementName(Util.tuple21(e)) for e in deps),",") + "\n");
      then
        deps;

    // We might actually get packages here, check the modifiers and the array dimensions
    case ((SCode.CLASS(name = name,
                       prefixes = SCode.PREFIXES(replaceablePrefix = rp),
                       classDef = SCode.DERIVED(modifications = mod, attributes = SCode.ATTR(arrayDims = ad))),
                       daeMod), (inAllElements, isFunction))
      equation
        (_, exps) = Absyn.getExpsFromArrayDim(ad);
        (_, sexps) = getExpsFromMod(mod);
        exps = listAppend(sexps, exps);
        (bexps, sexps) = getExpsFromConstrainClass(rp);
        exps = listAppend(bexps, listAppend(sexps, exps));
        (_, sexps) = getExpsFromMod(Mod.unelabMod(daeMod));
        exps = listAppend(sexps, exps);
        deps = getDepsFromExps(exps, inAllElements, {}, isFunction);
        deps = removeCurrentElementFromArrayDimDeps(name, deps);
        deps = List.union(deps,{});
      then
        deps;

    // We might have functions here and their input/output elements can have bindings from the list
    // see reference_X in PartialMedium
    // see ExternalMedia.Media.ExternalTwoPhaseMedium.FluidConstants
    //     which depends on function calls which depend on package constants inside external decl
    case ((SCode.CLASS(name = name,
                       prefixes = SCode.PREFIXES(),
                       classDef = SCode.PARTS(externalDecl = externalDecl)),
           _), (inAllElements, isFunction))
      equation
        exps = getExpsFromExternalDecl(externalDecl);
        /*
        exps = getExpsFromDefaults(els, exps);
        (bexps, sexps) = getExpsFromConstrainClass(rp);
        exps = listAppend(bexps, listAppend(sexps, exps));
        (bexps, sexps) = getExpsFromMod(Mod.unelabMod(daeMod));
        exps = listAppend(bexps, listAppend(sexps, exps));
        */
        deps = getDepsFromExps(exps, inAllElements, {}, isFunction);
        deps = removeCurrentElementFromArrayDimDeps(name, deps);
        deps = List.union(deps,{});
      then
        deps;

    else {};
  end matchcontinue;
end getElementDependencies;

protected function getExpsFromExternalDecl
"get dependencies from external declarations"
  input Option<SCode.ExternalDecl> inExternalDecl;
  output list<Absyn.Exp> outExps;
algorithm
  outExps := match(inExternalDecl)
    local list<Absyn.Exp> exps;
    case (NONE()) then {};
    case (SOME(SCode.EXTERNALDECL(args = exps)))
      then
        exps;
  end match;
end getExpsFromExternalDecl;

protected function getExpsFromDefaults
  input SCode.Program inEls;
  input list<Absyn.Exp> inAcc;
  output list<Absyn.Exp> outExps;
algorithm
  outExps := matchcontinue(inEls, inAcc)
    local
      SCode.Program rest;
      list<Absyn.Exp> exps, sexps, bexps, acc;
      SCode.Mod m;
      SCode.Replaceable rp;

    case ({}, _) then inAcc;

    case (SCode.COMPONENT(
                  prefixes = SCode.PREFIXES(replaceablePrefix = rp),
                  modifications = m)::rest, _)
      equation
        exps = inAcc;
        (bexps, sexps) = getExpsFromConstrainClass(rp);
        exps = listAppend(bexps, listAppend(sexps, exps));
        (bexps, sexps) = getExpsFromMod(m);
        exps = listAppend(bexps, listAppend(sexps, exps));
        exps = getExpsFromDefaults(rest, exps);
      then
        exps;

    case (_::rest, _)
      equation
        exps = getExpsFromDefaults(rest, inAcc);
      then
        exps;
  end matchcontinue;
end getExpsFromDefaults;

protected function getElementDependenciesTraverserEnter
  "Traverse function used by getElementDependencies to collect all dependencies
  for an element. The first ElementList in the input argument is a list of all
  elements, and the second is a list of accumulated dependencies."
  input Absyn.Exp inExp;
  input tuple<ElementList, list<ElementList>, ElementList, Boolean> inTuple;
  output Absyn.Exp outExp;
  output tuple<ElementList, list<ElementList>, ElementList, Boolean> outTuple;
  type ElementList = list<tuple<SCode.Element, DAE.Mod>>;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      Absyn.Exp exp;
      String id;
      ElementList all_el, accum_el;
      list<ElementList> stack;
      tuple<SCode.Element, DAE.Mod> e;
      Absyn.ComponentRef cref;
      Boolean b;

    case (exp as Absyn.CREF(componentRef = cref), (all_el, stack, accum_el, b))
      equation
        id = Absyn.crefFirstIdent(cref);
        e = List.find1(all_el, isElementNamed, id);
      then
        (exp, (all_el, stack, e :: accum_el, b));

    case (exp as Absyn.CALL(function_ = cref), (all_el, stack, accum_el, b))
      equation
        id = Absyn.crefFirstIdent(cref);
        e = List.find1(all_el, isElementNamed, id);
      then
        (exp, (all_el, stack, e :: accum_el, b));

    // The condition expression is always used
    case (exp as Absyn.IFEXP(), (all_el, stack, accum_el, false))
      then (exp,(all_el,accum_el::stack,{},false));

    else (inExp,inTuple);
  end matchcontinue;
end getElementDependenciesTraverserEnter;

protected function getElementDependenciesTraverserExit
  "Dummy traversal function used by getElementDependencies."
  input Absyn.Exp inExp;
  input tuple<ElementList, list<ElementList>, ElementList, Boolean> inTuple;
  output Absyn.Exp outExp;
  output tuple<ElementList, list<ElementList>, ElementList, Boolean> outTuple;
  type ElementList = list<tuple<SCode.Element, DAE.Mod>>;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      ElementList all_el, accum_el, stack_el, deps;
      list<ElementList> rest_stack;
      Absyn.Exp exp,ifExp;
      Boolean b;

    // If a binding contains an if-equation we don't really have any idea which
    // branch will be used, which causes some problems with Fluid. So we just
    // reset everything up to this point and pray that we didn't miss anything
    // important.
    case (exp as Absyn.IFEXP(ifExp = ifExp), (all_el, stack_el::rest_stack, _, false))
      equation
        (_, (_, _, deps, _)) = Absyn.traverseExpBidir(ifExp, getElementDependenciesTraverserEnter, getElementDependenciesTraverserExit, (all_el, {}, {}, false));
        deps = listAppend(deps, stack_el);
      then
        (exp, (all_el, rest_stack, deps, false));

    else (inExp,inTuple);
  end matchcontinue;
end getElementDependenciesTraverserExit;

protected function isElementNamed
  "Returns true if the given element has the same name as the given string,
  otherwise false."
  input tuple<SCode.Element, DAE.Mod> inElement;
  input String inName;
  output Boolean isNamed;
algorithm
  isNamed := match inElement
    local
      String name;

    case (SCode.COMPONENT(name = name), _) then name == inName;
    case (SCode.CLASS(name = name), _) then name == inName;
    else false;
  end match;
end isElementNamed;

protected function isElementEqual
  "Checks that two elements are equal, i.e. has the same name."
  input tuple<SCode.Element, DAE.Mod> inElement1;
  input tuple<SCode.Element, DAE.Mod> inElement2;
  output Boolean isEqual;
algorithm
  isEqual := match(inElement1, inElement2)
    local
      String id1, id2;

    case ((SCode.COMPONENT(name = id1), _),
          (SCode.COMPONENT(name = id2), _))
      then stringEqual(id1, id2);

    // we can also have packages!
    case ((SCode.CLASS(name = id1), _),
          (SCode.CLASS(name = id2), _))
      then stringEqual(id1, id2);

    else stringEq(elementName(inElement1), elementName(inElement2));

  end match;
end isElementEqual;

protected function checkCyclicalComponents
  "Checks the return value from Graph.topologicalSort. If the list of cycles is
  not empty, print an error message and fail, since it's not allowed for
  constants or parameters to have cyclic dependencies."
  input list<tuple<Element, list<Element>>> inCycles;
  input FCore.Graph inEnv;
  type Element = tuple<SCode.Element, DAE.Mod>;
algorithm
  _ := matchcontinue(inCycles, inEnv)
    local
      list<list<Element>> cycles;
      list<list<String>> names;
      list<String> cycles_strs;
      String cycles_str, scope_str;
      list<tuple<Element, list<Element>>> graph;

    case ({}, _) then ();

    case (_, _)
      equation
        graph = Graph.filterGraph(inCycles, isElementParamOrConst);
        {} = Graph.findCycles(graph, isElementEqual);
      then
        ();

    else
      equation
        cycles = Graph.findCycles(inCycles, isElementEqual);
        names = List.mapList(cycles, elementName);
        cycles_strs = List.map1(names, stringDelimitList, ",");
        cycles_str = stringDelimitList(cycles_strs, "}, {");
        cycles_str = "{" + cycles_str + "}";
        scope_str = FGraph.printGraphPathStr(inEnv);
        Error.addMessage(Error.CIRCULAR_COMPONENTS, {scope_str, cycles_str});
      then
        fail();
  end matchcontinue;
end checkCyclicalComponents;

protected function isElementParamOrConst
  input tuple<SCode.Element, DAE.Mod> inElement;
  output Boolean outIsParamOrConst;
algorithm
  outIsParamOrConst := match(inElement)
    local
      SCode.Variability var;

    case ((SCode.COMPONENT(attributes = SCode.ATTR(variability = var)), _))
      then SCode.isParameterOrConst(var);

    else false;
  end match;
end isElementParamOrConst;

protected function elementName
  "Returns the name of the given element."
  input tuple<SCode.Element, DAE.Mod> inElement;
  output String outName;
protected
  SCode.Element elem;
algorithm
  outName := matchcontinue(inElement)
    local
      String str;

    case (_)
      equation
        (elem, _) = inElement;
        outName = SCode.elementName(elem);
      then
        outName;

    case (_)
      equation
        str = SCodeDump.shortElementStr(Util.tuple21(inElement));
      then
        str;
  end matchcontinue;
end elementName;

public function classdefElts2
"author: PA
  This function filters out the class definitions (ElementMod) list."
  input list<tuple<SCode.Element, DAE.Mod>> inElements;
  input SCode.Partial partialPrefix;
  output list<SCode.Element> outClassDefs;
  output list<tuple<SCode.Element, DAE.Mod>> outConstEls;
algorithm
  (outClassDefs, outConstEls) := matchcontinue (inElements, partialPrefix)
    local
      list<SCode.Element> cdefs;
      SCode.Element cdef;
      tuple<SCode.Element, DAE.Mod> el;
      list<tuple<SCode.Element, DAE.Mod>> xs, els;
      SCode.Attributes attr;
    case ({},_) then ({},{});
    case ((cdef as SCode.CLASS(restriction = SCode.R_PACKAGE()),_) :: xs,SCode.PARTIAL())
      equation
        (cdefs,els) = classdefElts2(xs,partialPrefix);
      then
        (cdef::cdefs,els);
    case (((cdef as SCode.CLASS(),_)) :: xs,SCode.NOT_PARTIAL())
      equation
        (cdefs,els) = classdefElts2(xs,partialPrefix);
      then
        (cdef::cdefs,els);
    case((el as (SCode.COMPONENT(attributes=attr),_))::xs,SCode.NOT_PARTIAL())
       equation
        SCode.CONST() = SCode.attrVariability(attr);
         (cdefs,els) = classdefElts2(xs,partialPrefix);
       then (cdefs,el::els);
    case ((_ :: xs),_)
      equation
        (cdefs,els) = classdefElts2(xs,partialPrefix);
      then
        (cdefs,els);
  end matchcontinue;
end classdefElts2;

public function classdefAndImpElts
"author: PA
  This function filters out the class definitions
  and import statements of an Element list."
  input list<SCode.Element> elts;
  output list<SCode.Element> cdefElts;
  output list<SCode.Element> restElts;
algorithm
  (cdefElts,restElts) := matchcontinue (elts)
    local
      list<SCode.Element> res,xs;
      SCode.Element cdef,imp,e;

    case ({}) then ({},{});

    case (((cdef as SCode.CLASS()) :: xs))
      equation
        (_,restElts) = classdefAndImpElts(xs);
      then
        (cdef :: restElts,restElts);

    case (((imp as SCode.IMPORT()) :: xs))
      equation
        (cdefElts,restElts) = classdefAndImpElts(xs);
      then
        (imp :: cdefElts,restElts);

    case ((e :: xs))
      equation
        (cdefElts,restElts) = classdefAndImpElts(xs);
      then
        (cdefElts,e::restElts);
  end matchcontinue;
end classdefAndImpElts;

/*
protected function extendsElts
"author: PA
  This function filters out the extends Element in an Element list"
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm
  outSCodeElementLst := matchcontinue (inSCodeElementLst)
    local
      list<SCode.Element> res,xs;
      SCode.Element cdef;
    case ({}) then {};
    case (((cdef as SCode.EXTENDS(baseClassPath = _)) :: xs))
      equation
        res = extendsElts(xs);
      then
        (cdef :: res);
    case ((_ :: xs))
      equation
        res = extendsElts(xs);
      then
        res;
  end matchcontinue;
end extendsElts;
*/

public function componentElts
"author: PA
  This function filters out the component Element in an Element list"
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm
  outSCodeElementLst := matchcontinue (inSCodeElementLst)
    local
      list<SCode.Element> res,xs;
      SCode.Element cdef;
    case ({}) then {};
    case (((cdef as SCode.COMPONENT()) :: xs))
      equation
        res = componentElts(xs);
      then
        (cdef :: res);
    case ((_ :: xs))
      equation
        res = componentElts(xs);
      then
        res;
  end matchcontinue;
end componentElts;

public function addClassdefsToEnv
  "This function adds class definitions and import statements to the environment."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input list<SCode.Element> inClasses;
  input Boolean inImpl;
  input Option<DAE.Mod> inRedeclareMod;
  output FCore.Cache outCache = inCache;
  output FCore.Graph outEnv = inEnv;
  output InnerOuter.InstHierarchy outIH = inIH;
algorithm
  for c in inClasses loop
    (outCache, outEnv, outIH) :=
      addClassdefToEnv(outCache, outEnv, outIH, inPrefix, c, inImpl, inRedeclareMod);
  end for;
end addClassdefsToEnv;

protected function addClassdefToEnv
"author: PA
  Helper relation to addClassdefsToEnv"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SCode.Element inSCodeElement;
  input Boolean inBoolean;
  input Option<DAE.Mod> redeclareMod;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
algorithm
  (outCache,outEnv,outIH) := matchcontinue (inCache,inEnv,inIH,inPrefix,inSCodeElement,redeclareMod)
    local
      FCore.Cache cache;
      FCore.Graph env,env_1;
      SCode.Element cl2, enumclass, imp;
      SCode.Element sel1,elt;
      list<SCode.Enum> enumLst;
      Boolean impl;
      InstanceHierarchy ih;
      SourceInfo info;
      Prefix.Prefix pre;
      String s;
      SCode.Comment cmt;
      SCode.Replaceable rpp;
      DAE.Mod m;

    // we do have a redeclaration of class.
    case (cache,env,ih,pre,( (sel1 as SCode.CLASS())),SOME(m))
      equation
        m = Mod.lookupCompModification(m, sel1.name);
        false = valueEq(m, DAE.NOMOD());
        env_1 = FGraph.mkClassNode(env, sel1, pre, m);
        // call to redeclareType which calls updateComponents in env wich updates the class frame
        (cache,env_1,ih,cl2) = addClassdefsToEnv3(cache, env_1, ih, pre, redeclareMod, sel1);
        ih = InnerOuter.addClassIfInner(cl2, pre, env_1, ih);
      then
        (cache,env_1,ih);

    // otherwise, extend frame with in class.
    case (cache,env,ih,pre,(sel1 as SCode.CLASS()),_)
      equation
        // Debug.traceln("Extend frame " + FGraph.printGraphPathStr(env) + " with " + SCode.className(cl));
        env_1 = FGraph.mkClassNode(env, sel1, pre, DAE.NOMOD());
        ih = InnerOuter.addClassIfInner(sel1, pre, env_1, ih);
      then
        (cache,env_1,ih);

    // adrpo: we should have no imports after SCodeFlatten!
    // unfortunately we do because of the way we evaluate
    // programs for interactive evaluation
    case (cache,env,ih,_,(imp as SCode.IMPORT()),_)
      equation
        env_1 = FGraph.mkImportNode(env, imp);
      then
        (cache,env_1,ih);

    case(cache,env,ih,_,((elt as SCode.DEFINEUNIT())),_)
      equation
        env_1 = FGraph.mkDefunitNode(env,elt);
      then (cache,env_1,ih);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- InstUtil.addClassdefToEnv2 failed\n");
      then
        fail();
  end matchcontinue;
end addClassdefToEnv;

protected function checkCompEnvPathVsCompTypePath
"fails if the comp env path is NOT a prefix of comp type path"
  input Option<Absyn.Path> inCompEnvPath;
  input Absyn.Path inCompTypePath;
algorithm
  _ := match(inCompEnvPath, inCompTypePath)

    local Absyn.Path ep, tp;

    // if the type path is just an ident, we have a problem!
    case (_, Absyn.IDENT(_)) then ();

    // if env path where the component C resides A.B.P.Z
    // has as prefix the component C type path C say A.B.P.C
    // it means that when we search for component A.B.P.Z.C
    // we might find the type: A.B.P.C instead.
    case (SOME(ep), tp)
      equation
        tp = Absyn.stripLast(tp);
        true = Absyn.pathPrefixOf(tp, ep);
      then
        ();

  end match;
end checkCompEnvPathVsCompTypePath;

public function addComponentsToEnv
"author: PA
  Since Modelica has removed the declare before use limitation, all
  components are intially added untyped to the environment, i.e. the
  SCode.Element is added. This is performed by this function. Later,
  during the second pass of the instantiation of components, the components
  are updated  in the environment. This is done by the function
  update_components_in_env. This function is also responsible for
  changing parameters into structural  parameters if they are affecting
  the number of variables or equations. This is needed because Modelica has
  no language construct for structural parameters, i.e. they must be
  detected by the compiler.

  Structural parameters are identified by investigating array dimension
  sizes of components and by investigating if-equations. If an if-equation
  has a boolean expression controlled by parameter(s), these are structural
  parameters."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input list<tuple<SCode.Element, DAE.Mod>> inComponents;
  input list<tuple<SCode.Element, DAE.Mod>> inAllComponents;
  input list<SCode.Equation> inEquations;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImpl;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
algorithm
  (outCache,outEnv,outIH) := match(inCache,inEnv,inIH,inMod,inPrefix,inState,
      inComponents,inAllComponents,inEquations,inInstDims,inImpl)
    local
      FCore.Graph env;
      tuple<SCode.Element, DAE.Mod> el;
      list<tuple<SCode.Element, DAE.Mod>> xs;
      InstanceHierarchy ih;
      FCore.Cache cache;

    /* no more components. */
    case (cache,env,ih,_,_,_,{},_,_,_,_) then (cache,env,ih);
    case (cache,env,ih,_,_,_,el::xs,_,_,_,_)
      equation
        (cache,env,ih) = addComponentToEnv(cache,env,ih,inMod,inPrefix,inState,el,inAllComponents,inEquations,inInstDims,inImpl);
        (cache,env,ih) = addComponentsToEnv(cache,env,ih,inMod,inPrefix,inState,xs,inAllComponents,inEquations,inInstDims,inImpl);
      then (cache,env,ih);
  end match;
end addComponentsToEnv;

protected function addComponentToEnv
"author: PA
  Since Modelica has removed the declare before use limitation, all
  components are intially added untyped to the environment, i.e. the
  SCode.Element is added. This is performed by this function. Later,
  during the second pass of the instantiation of components, the components
  are updated  in the environment. This is done by the function
  update_components_in_env. This function is also responsible for
  changing parameters into structural  parameters if they are affecting
  the number of variables or equations. This is needed because Modelica has
  no language construct for structural parameters, i.e. they must be
  detected by the compiler.

  Structural parameters are identified by investigating array dimension
  sizes of components and by investigating if-equations. If an if-equation
  has a boolean expression controlled by parameter(s), these are structural
  parameters."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input tuple<SCode.Element, DAE.Mod> inComponent;
  input list<tuple<SCode.Element, DAE.Mod>> inAllComponents;
  input list<SCode.Equation> inEquations;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImpl;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
algorithm
  (outCache,outEnv,outIH) := matchcontinue(inCache,inEnv,inIH,inMod,inPrefix,
      inState,inComponent,inAllComponents,inEquations,inInstDims,inImpl)
    local
      FCore.Graph env,env_1;
      DAE.Mod mod,cmod;
      Prefix.Prefix pre;
      ClassInf.State cistate;
      SCode.Element comp, cl;
      String n, ns;
      SCode.Final finalPrefix;
      Boolean impl;
      SCode.Attributes attr;
      SCode.Mod m;
      SCode.Comment comment;
      list<tuple<SCode.Element, DAE.Mod>> allcomps;
      list<SCode.Equation> eqns;
      InstDims instdims;
      Option<Absyn.Exp> aExp;
      SourceInfo aInfo;
      InstanceHierarchy ih;
      FCore.Cache cache;
      Absyn.TypeSpec tss;
      Absyn.Path tpp;
      SCode.Element selem;
      DAE.Mod smod,compModLocal;
      SCode.Prefixes pf;

    // adrpo: moved this check from instElement here as we should check this as early as possible!
    // Check if component's name is the same as its type's name
    case (_,env,_,_,_,_,
          ((SCode.COMPONENT(name = n,typeSpec = (Absyn.TPATH(tpp, _)), info = aInfo)),_), _, _, _,_)
      equation
        // name is equal with the last ident from type path.
        // this is only a problem if the environment in which the component
        // resides has as prefix the type path (without the last ident)
        // as this would mean that we might find the type instead of the
        // component when we do lookup
        true = stringEq(n, Absyn.pathLastIdent(tpp));

        // this will fail if the type path is a prefix of the env path
        checkCompEnvPathVsCompTypePath(FGraph.getScopePath(env), tpp);

        ns = Absyn.pathString(tpp);
        n = n + " in env: " +  FGraph.printGraphPathStr(env);
        Error.addSourceMessage(Error.COMPONENT_NAME_SAME_AS_TYPE_NAME, {n,ns}, aInfo);
      then
        fail();

    /* A TPATH component */
    case (cache,env,ih,mod,pre,cistate,
        (((comp as SCode.COMPONENT(name = n,
                                   prefixes = pf as SCode.PREFIXES(
                                     finalPrefix = finalPrefix
                                   ),
                                   attributes = attr,
                                   typeSpec = (tss as Absyn.TPATH(tpp, _)),
                                   modifications = m,
                                   comment = comment,
                                   condition = aExp,
                                   info = aInfo)),cmod)),
        _,_,instdims,impl)
      equation
        compModLocal = Mod.lookupModificationP(mod, tpp);
        if SCode.finalBool(finalPrefix) then
          m = traverseModAddFinal(m);
          comp = SCode.COMPONENT(n,pf,attr,tss,m,comment,aExp,aInfo);
        end if;
        (cache,env,ih,selem,smod) = Inst.redeclareType(cache, env, ih, compModLocal, comp, pre, cistate, impl,cmod);
        // Debug.traceln(" adding comp: " + n + " " + Mod.printModStr(mod) + " cmod: " + Mod.printModStr(cmod) + " cmL: " + Mod.printModStr(compModLocal) + " smod: " + Mod.printModStr(smod));
        // print(" \t comp: " + n + " " + "selem: " + SCodeDump.printElementStr(selem) + " smod: " + Mod.printModStr(smod) + "\n");
        (cache,env_1,ih) = addComponentsToEnv2(cache, env, ih, mod, pre, cistate, {(selem,smod)}, instdims, impl);
      then
        (cache,env_1,ih);

    /* A TCOMPLEX component */
    case (cache,env,ih,mod,pre,cistate,
        (((comp as SCode.COMPONENT(name = n,
                                   prefixes = pf as SCode.PREFIXES(
                                     finalPrefix = finalPrefix
                                   ),
                                   attributes = attr,
                                   typeSpec = (tss as Absyn.TCOMPLEX(tpp,_,_)),
                                   modifications = m,
                                   comment = comment,
                                   condition = aExp,
                                   info = aInfo)),cmod)),
        _,_,instdims,impl)
      equation
        // TODO: cmod was enforced to be NOMOD earlier. A problem to change it?
        compModLocal = Mod.lookupModificationP(mod, tpp);
        if SCode.finalBool(finalPrefix) then
          m = traverseModAddFinal(m);
          comp = SCode.COMPONENT(n,pf,attr,tss,m,comment,aExp,aInfo);
        end if;
        (cache,env,ih,selem,smod) = Inst.redeclareType(cache, env, ih, compModLocal, comp, pre, cistate, impl,cmod);
        (cache,env_1,ih) = addComponentsToEnv2(cache, env, ih, mod, pre, cistate, {(selem,cmod)}, instdims, impl);
      then
        (cache,env_1,ih);

    // Import statement
    case (cache,env,ih,_,_,_,(SCode.IMPORT(),_),_,_,_,_)
      then (cache,env,ih);

    // Extends elements
    case (cache,env,ih,_,_,_,(SCode.EXTENDS(),_),_,_,_,_)
      then (cache,env,ih);

    // classes
    case (cache,env,ih,_,_,_,(SCode.CLASS(),_),_,_,_,_)
      equation
      then
        (cache,env,ih);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- " + getInstanceName() + " failed\n");
      then
        fail();
  end matchcontinue;
end addComponentToEnv;

protected function addComponentsToEnv2
"Helper function to addComponentsToEnv.
  Extends the environment with an untyped variable for the component."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input list<tuple<SCode.Element, DAE.Mod>> inElement;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inBoolean;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
algorithm
  (outCache,outEnv,outIH) := matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inState,inElement,inInstDims,inBoolean)
    local
      DAE.Mod compmod,cmod_1,mods,cmod;
      FCore.Graph env_1,env_2,env;
      Prefix.Prefix pre;
      ClassInf.State ci_state;
      SCode.Element comp;
      String n;
      SCode.Final finalPrefix;
      SCode.Replaceable repl;
      SCode.Visibility vis;
      SCode.ConnectorType ct;
      Boolean impl;
      SCode.Redeclare redecl;
      Absyn.InnerOuter io;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad;
      SCode.Parallelism prl;
      SCode.Variability var;
      Absyn.Direction dir;
      Absyn.TypeSpec t;
      SCode.Mod m;
      list<tuple<SCode.Element, DAE.Mod>> xs,comps;
      InstDims inst_dims;
      SourceInfo info;
      Option<Absyn.Exp> condition;
      InstanceHierarchy ih;
      FCore.Cache cache;

    // a component
    case (cache,env,ih,mods,pre,ci_state,
          ((comp as SCode.COMPONENT(name=n,prefixes=SCode.PREFIXES(vis,_,_,io,_),
                                    attributes=SCode.ATTR(_,ct,prl,var,dir)),cmod) :: xs),
          inst_dims,impl)
      equation
        // compmod = Mod.getModifs(mods, n, m);
        compmod = Mod.lookupCompModification(mods, n);
        cmod_1 = Mod.merge(compmod, cmod);

        /*
        print("InstUtil.addCompToEnv: " +
          n + " in env " +
          FGraph.printGraphPathStr(env) + " with mod: " + Mod.printModStr(cmod_1) + " in element: " +
          SCodeDump.printElementStr(comp) + "\n");
        */

        // Debug.traceln("  extendFrameV comp " + n + " m:" + Mod.printModStr(cmod_1) + " compm: " + Mod.printModStr(compmod) + " cm: " + Mod.printModStr(cmod));
        env_1 = FGraph.mkComponentNode(env,
          DAE.TYPES_VAR(
            n,DAE.ATTR(ct,prl,var,dir,io,vis),
            DAE.T_UNKNOWN_DEFAULT,DAE.UNBOUND(),NONE()),
          comp,
          cmod_1,
          FCore.VAR_UNTYPED(),
          FGraph.empty());
        (cache,env_2,ih) = addComponentsToEnv2(cache, env_1, ih, mods, pre, ci_state, xs, inst_dims, impl);
      then
        (cache,env_2,ih);

    // no components in list
    case (cache,env,ih,_,_,_,{},_,_) then (cache,env,ih);

    // failtrace
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- InstUtil.addComponentsToEnv2 failed\n");
      then
        fail();
  end matchcontinue;
end addComponentsToEnv2;

protected function getCrefsFromCompdims
"author: PA
  This function collects all variables from the dimensionalities of
  component elements. These variables are candidates for structural
  parameters."
  input list<tuple<SCode.Element, DAE.Mod>> inComponents;
  output list<Absyn.ComponentRef> outCrefs;
algorithm
  outCrefs := matchcontinue (inComponents)
    local
      list<Absyn.ComponentRef> crefs1,crefs2,crefs;
      list<Absyn.Subscript> arraydim;
      list<tuple<SCode.Element, DAE.Mod>> xs;
    case ({}) then {};
    case (((SCode.COMPONENT(attributes = SCode.ATTR(arrayDims = arraydim)),_) :: xs))
      equation
        crefs1 = getCrefFromDim(arraydim);
        crefs2 = getCrefsFromCompdims(xs);
        crefs = listAppend(crefs1, crefs2);
      then
        crefs;
    case ((_ :: xs))
      equation
        crefs = getCrefsFromCompdims(xs);
      then
        crefs;
  end matchcontinue;
end getCrefsFromCompdims;

protected function memberCrefs
"author: PA
  This function checks if a componentreferece is a member of
  a list of component references, disregarding subscripts."
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ComponentRef> inComponentRefs;
  output Boolean outIsMember;
algorithm
  outIsMember := List.isMemberOnTrue(inComponentRef, inComponentRefs,
    Absyn.crefEqualNoSubs);
end memberCrefs;

public function chainRedeclares "
 if we have an outer modification: redeclare X = Y
 and a component modification redeclare X = Z
 update the component modification to redeclare X = Y"
  input DAE.Mod inModOuter "the outer mod which should overwrite the inner mod";
  input SCode.Mod inModInner "the inner mod";
  output SCode.Mod outMod;
algorithm
  outMod := match(inModOuter,inModInner)
      /*
      case(_, _)
        equation
          outMod = chainRedeclare_dispatch(inModOuter,inModInner);
          false = SCode.modEqual(inModInner, outMod);
          print("Chain:\nO:" + Mod.printModStr(inModOuter) + "\nI:" + SCodeDump.printModStr(inModInner, SCodeDump.defaultOptions) + "\nR:" + SCodeDump.printModStr(outMod, SCodeDump.defaultOptions) + "\n");
        then
          outMod;
      */
      case(_, _)
        equation
          outMod = chainRedeclare_dispatch(inModOuter,inModInner);
        then outMod;
  end match;
end chainRedeclares;

public function chainRedeclare_dispatch "
 if we have an outer modification: redeclare X = Y
 and a component modification redeclare X = Z
 update the component modification to redeclare X = Y"
  input DAE.Mod inModOuter "the outer mod which should overwrite the inner mod";
  input SCode.Mod inModInner "the inner mod";
  output SCode.Mod outMod;
algorithm
  outMod := matchcontinue (inModOuter,inModInner)
    local
      SCode.Final f;
      SCode.Each  e;
      SCode.Element cls;
      String name, nInner, nDerivedInner;
      list<SCode.SubMod> rest, subs;
      Option<Absyn.Exp> b;
      SCode.Mod m,m2;
      SCode.SubMod sm;
      SourceInfo info;

    // outer B(redeclare X = Y), inner B(redeclare Y = Z) -> B(redeclare X = Z)
    case (_,SCode.REDECL(f, e, SCode.CLASS(name = nInner, classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(path = Absyn.IDENT(nDerivedInner))))))
      equation
        // lookup the class mod in the outer
        DAE.REDECL(element = cls) = Mod.lookupModificationP(inModOuter, Absyn.IDENT(nDerivedInner));
        cls = SCode.setClassName(nInner, cls);
      then
        SCode.REDECL(f, e, cls);

    // outer B(redeclare X = Y), inner B(redeclare X = Z) -> B(redeclare X = Z)
    case (_,SCode.REDECL(f, e, SCode.CLASS(name = nInner, classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(path = Absyn.IDENT(_))))))
      equation
        // lookup the class mod in the outer
        DAE.REDECL(element = cls) = Mod.lookupModificationP(inModOuter, Absyn.IDENT(nInner));
      then
        SCode.REDECL(f, e, cls);

    // a mod with a name mod
    case (_, SCode.MOD(f, e, SCode.NAMEMOD(name, m as SCode.REDECL())::rest, b, info))
      equation
        // lookup the class mod in the outer
        m2 = chainRedeclare_dispatch(inModOuter, m);
        SCode.MOD(subModLst = subs) = chainRedeclare_dispatch(inModOuter, SCode.MOD(f, e, rest, b, info));
      then
        SCode.MOD(f, e, SCode.NAMEMOD(name, m2)::subs, b, info);

    // something else, move along!
    case (_, SCode.MOD(f, e, sm::rest, b, info))
      equation
        SCode.MOD(subModLst = subs) = chainRedeclare_dispatch(inModOuter, SCode.MOD(f, e, rest, b, info));
      then
        SCode.MOD(f, e, sm::subs, b, info);

    else inModInner;

  end matchcontinue;
end chainRedeclare_dispatch;

protected function addRecordConstructorsToTheCache
"@author: adrpo
 add the record constructor to the cache if we have
 it as the type of an input component to a function"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input Absyn.Direction inDirection;
  input SCode.Element inClass;
  input list<list<DAE.Dimension>> inInstDims;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
algorithm
  (outCache, outEnv, outIH) := matchcontinue(inCache, inEnv, inIH, inMod, inPrefix, inState, inDirection, inClass, inInstDims)
    local
      FCore.Cache cache;
      FCore.Graph env;
      InstanceHierarchy ih;
      String name;
      Absyn.Path path;

    // add it to the cache if we have a input record component
    case (_, _, _, _, _, ClassInf.FUNCTION(path = path), _,
          SCode.CLASS(name = name, restriction = SCode.R_RECORD(_)), _)
      equation
        print("Depreciated record constructor used: Inst.addRecordConstructorsToTheCache");

        // false = Config.acceptMetaModelicaGrammar();
        true = Absyn.isInputOrOutput(inDirection);
        // TODO, add the env path to the check!
        false = stringEq(Absyn.pathLastIdent(path), name);
        // print("InstFunction.implicitFunctionInstantiation: " + name + " in f:" + Absyn.pathString(path) + " in s:" + FGraph.printGraphPathStr(inEnv) + " m: " + Mod.printModStr(inMod) + "\n");
        (cache, env, ih) = InstFunction.implicitFunctionInstantiation(inCache, inEnv, inIH, inMod, inPrefix, inClass, inInstDims);
      then
        (cache, env, ih);

    // do nothing otherwise!
    else
      then
        (inCache, inEnv, inIH);

  end matchcontinue;
end addRecordConstructorsToTheCache;

public function checkMultiplyDeclared
"Check if variable is multiply declared and
 that all declarations are identical if so."
  input FCore.Cache cache;
  input FCore.Graph env;
  input DAE.Mod mod;
  input Prefix.Prefix prefix;
  input ClassInf.State ciState;
  input tuple<SCode.Element, DAE.Mod> compTuple;
  input list<list<DAE.Dimension>> instDims;
  input Boolean impl;
  output Boolean alreadyDeclared;
algorithm
  alreadyDeclared := matchcontinue(cache,env,mod,prefix,ciState,compTuple,instDims,impl)
    local
      String n,n2;
      SCode.Element oldElt;
      DAE.Mod oldMod;
      tuple<SCode.Element,DAE.Mod> newComp;
      FCore.Status instStatus;
      SCode.Element oldClass,newClass;

    case (_,_,_,_,_,_,_,_) equation /*print(" dupe check setting ");*/ ErrorExt.setCheckpoint("checkMultiplyDeclared"); then fail();


    // If a component definition is replaceable, skip check
    case (_,_,_,_,_,
          ((SCode.COMPONENT(prefixes = SCode.PREFIXES(replaceablePrefix=SCode.REPLACEABLE(_))),_)),_,_)
      equation
        ErrorExt.rollBack("checkMultiplyDeclared");
      then false;

    // If a comopnent definition is redeclaration, skip check
    case (_,_,_,_,_,
          ((SCode.COMPONENT(),DAE.REDECL(_,_,_))),_,_)
      equation
        ErrorExt.rollBack("checkMultiplyDeclared");
      then false;

    // If a variable is declared multiple times, the first is used.
    // If the two variables are not identical, an error is given.
    case (_,_,_,_,_,
          (newComp as (SCode.COMPONENT(name = n),_)),_,_)
      equation
        (_,_,oldElt,oldMod,instStatus,_) = Lookup.lookupIdentLocal(cache, env, n);
        checkMultipleElementsIdentical(cache,env,(oldElt,oldMod),newComp);
        alreadyDeclared = instStatusToBool(instStatus);
        ErrorExt.delCheckpoint("checkMultiplyDeclared");
      then alreadyDeclared;

    // If not multiply declared, return.
    case (_,_,_,_,_,
          ((SCode.COMPONENT(name = n),_)),_,_)
      equation
        failure((_,_,_,_,_,_) = Lookup.lookupIdentLocal(cache, env, n));
        ErrorExt.rollBack("checkMultiplyDeclared");
      then false;


    // If a class definition is replaceable, skip check
    case (_,_,_,_,_,
          ((SCode.CLASS(prefixes = SCode.PREFIXES(replaceablePrefix=SCode.REPLACEABLE(_))),_)),_,_)
      equation
        ErrorExt.rollBack("checkMultiplyDeclared");
      then false;

    // If a class definition is redeclaration, skip check
    case (_,_,_,_,_,
          ((SCode.CLASS(),DAE.REDECL(_,_,_))),_,_)
      equation
        ErrorExt.rollBack("checkMultiplyDeclared");
      then false;

    // If a class definition is a product of InstExtends.instClassExtendsList2, skip check
    case (_,_,_,_,_,
          ((SCode.CLASS(name=n,classDef=SCode.PARTS(elementLst=SCode.EXTENDS(baseClassPath=Absyn.IDENT(n2))::_ )),_)),_,_)
      equation
        n = "$parent" + "." + n;
        0 = System.stringFind(n, n2);
        ErrorExt.rollBack("checkMultiplyDeclared");
      then false;

    // If a class is defined multiple times, the first is used.
    // If the two class definitions are not equivalent, an error is given.
    case (_,_,_,_,_,
          ((newClass as SCode.CLASS(name=n),_)),_,_)
      equation
        (oldClass,_) = Lookup.lookupClassLocal(env, n);
        checkMultipleClassesEquivalent(oldClass,newClass);
        ErrorExt.delCheckpoint("checkMultiplyDeclared");
      then true;

    // If a class not multiply defined, return.
    case (_,_,_,_,_,
          ((SCode.CLASS(name=n),_)),_,_)
      equation
        failure((_,_) = Lookup.lookupClassLocal(env, n));
        ErrorExt.rollBack("checkMultiplyDeclared");
      then false;

    // failure
    else
      equation
        ErrorExt.delCheckpoint("checkMultiplyDeclared");
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("-Inst.checkMultiplyDeclared failed\n");
        end if;
      then fail();
  end matchcontinue;
end checkMultiplyDeclared;

protected function instStatusToBool
"Translates InstStatus to a boolean indicating if component is allready declared."
  input FCore.Status instStatus;
  output Boolean alreadyDeclared;
algorithm
  alreadyDeclared := match(instStatus)
    case (FCore.VAR_DAE()) then true;
    case (FCore.VAR_UNTYPED()) then false;
    case (FCore.VAR_TYPED()) then false;
  end match;
end instStatusToBool;

protected function checkMultipleElementsIdentical
"Checks that the old declaration is identical
 to the new one. If not, give error message"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input tuple<SCode.Element,DAE.Mod> oldComponent;
  input tuple<SCode.Element,DAE.Mod> newComponent;
algorithm
  _ := matchcontinue(inCache,inEnv,oldComponent,newComponent)
    local
      SCode.Element oldElt,newElt;
      DAE.Mod oldMod,newMod;
      String s1,s2,s;
      SCode.Mod smod1, smod2;
      FCore.Graph env, env1, env2;
      FCore.Cache cache;
      SCode.Element c1, c2;
      Absyn.Path tpath1, tpath2;
      SourceInfo old_info, new_info;
      SCode.Prefixes prefixes1, prefixes2;
      SCode.Attributes attr1,attr2;
      Absyn.TypeSpec tp1,tp2;
      String n1, n2;
      Option<Absyn.ArrayDim> ad1, ad2;
      Option<Absyn.Exp> cond1, cond2;

    // try equality first!
    case(_,_,(oldElt,_),(newElt,_))
      equation
        // NOTE: Should be type identical instead? see spec.
        // p.23, check of flattening. "Check that duplicate elements are identical".
        true = SCode.elementEqual(oldElt,newElt);
      then
        ();

    // adrpo: see if they are not syntactically equivalent, but semantically equivalent!
    //        see Modelica Spec. 3.1, page 66.
    // COMPONENT
    case (cache,env,(SCode.COMPONENT(n1, prefixes1, attr1, Absyn.TPATH(tpath1, ad1), smod1, _, cond1, _),_),
                    (SCode.COMPONENT(n2, prefixes2, attr2, Absyn.TPATH(tpath2, ad2), smod2, _, cond2, _),_))
      equation
        // see if the most stuff is the same!
        true = stringEq(n1, n2);
        true = SCode.prefixesEqual(prefixes1, prefixes2);
        true = SCode.attributesEqual(attr1, attr2);
        true = SCode.modEqual(smod1, smod2);
        equality(ad1 = ad2);
        equality(cond1 = cond2);
        // if we lookup tpath1 and tpath2 and reach the same class, we're fine!
        (_, c1, env1) = Lookup.lookupClass(cache, env, tpath1);
        (_, c2, env2) = Lookup.lookupClass(cache, env, tpath2);
        // the class has the same environment
        true = stringEq(FGraph.printGraphPathStr(env1), FGraph.printGraphPathStr(env2));
        // the classes are the same!
        true = SCode.elementEqual(c1, c2);
        /*
        // add a warning and let it continue!
        s1 = SCodeDump.unparseElementStr(oldElt);
        s2 = SCodeDump.unparseElementStr(newElt);
        Error.addMultiSourceMessage(Error.DUPLICATE_ELEMENTS_NOT_SYNTACTICALLY_IDENTICAL, {s1, s2}, {old_info, new_info});
        */
      then
        ();

    // adrpo: handle bug: https://trac.modelica.org/Modelica/ticket/627
    //        TODO! FIXME! REMOVE! remove when the bug is fixed!
    case (cache,env,(oldElt as SCode.COMPONENT(n1, prefixes1, attr1, Absyn.TPATH(tpath1, ad1), smod1, _, cond1, old_info),_),
                    (newElt as SCode.COMPONENT(n2, prefixes2, attr2, Absyn.TPATH(tpath2, ad2), smod2, _, cond2, new_info),_))
      equation
        // see if the most stuff is the same!
        true = stringEq(n1, n2);
        true = stringEq(n1, "m_flow");
        true = SCode.prefixesEqual(prefixes1, prefixes2);
        true = SCode.attributesEqual(attr1, attr2);
        false = SCode.modEqual(smod1, smod2);
        equality(ad1 = ad2);
        equality(cond1 = cond2);
        // if we lookup tpath1 and tpath2 and reach the same class, we're fine!
        (_, c1, env1) = Lookup.lookupClass(cache, env, tpath1);
        (_, c2, env2) = Lookup.lookupClass(cache, env, tpath2);
        // the class has the same environment
        true = stringEq(FGraph.printGraphPathStr(env1), FGraph.printGraphPathStr(env2));
        // the classes are the same!
        true = SCode.elementEqual(c1, c2);
        // add a warning and let it continue!
        s1 = SCodeDump.unparseElementStr(oldElt,SCodeDump.defaultOptions);
        s2 = SCodeDump.unparseElementStr(newElt,SCodeDump.defaultOptions);
        s = "Inherited elements are not identical: bug: https://trac.modelica.org/Modelica/ticket/627\n\tfirst:  " +
            s1 + "\n\tsecond: " + s2 + "\nContinue ....";
        Error.addMultiSourceMessage(Error.COMPILER_WARNING, {s}, {old_info, new_info});
      then ();

    // fail baby and add a source message!
    case (_, _, (oldElt as SCode.COMPONENT(info = old_info),_),
                      (newElt as SCode.COMPONENT(info = new_info),_))
      equation
        s1 = SCodeDump.unparseElementStr(oldElt,SCodeDump.defaultOptions);
        s2 = SCodeDump.unparseElementStr(newElt,SCodeDump.defaultOptions);
        Error.addMultiSourceMessage(Error.DUPLICATE_ELEMENTS_NOT_IDENTICAL,
          {s1, s2}, {old_info, new_info});
      then
        fail();

  end matchcontinue;
end checkMultipleElementsIdentical;

protected function checkMultipleClassesEquivalent
"Checks that the old class definition is equivalent
 to the new one. If not, give error message"
  input SCode.Element oldClass;
  input SCode.Element newClass;
algorithm
  _ := matchcontinue(oldClass,newClass)
    local
      SCode.Element oldCl,newCl;
      String s1,s2;
      list<String> sl1,sl2;
      list<SCode.Enum> enumLst;
      list<SCode.Element> elementLst;
      SourceInfo info1, info2;

    //   Special cases for checking enumerations which can be represented differently
    case(SCode.CLASS(classDef=SCode.ENUMERATION(enumLst=enumLst)), SCode.CLASS(restriction=SCode.R_ENUMERATION(),classDef=SCode.PARTS(elementLst=elementLst)))
      equation
        sl1=List.map(enumLst,SCode.enumName);
        sl2=List.map(elementLst,SCode.elementName);
        List.threadMapAllValue(sl1,sl2,stringEq,true);
      then
        ();

    case(SCode.CLASS(restriction=SCode.R_ENUMERATION(),classDef=SCode.PARTS(elementLst=elementLst)), SCode.CLASS(classDef=SCode.ENUMERATION(enumLst=enumLst)))
      equation
        sl1=List.map(enumLst,SCode.enumName);
        sl2=List.map(elementLst,SCode.elementName);
        List.threadMapAllValue(sl1,sl2,stringEq,true);
      then
        ();

    // try equality first!
    case(oldCl,newCl)
      equation
        true = SCode.elementEqual(oldCl,newCl);
      then ();

    case (oldCl,newCl)
      equation
      s1 = SCodeDump.unparseElementStr(oldCl,SCodeDump.defaultOptions);
      s2 = SCodeDump.unparseElementStr(newCl,SCodeDump.defaultOptions);
      info1 = SCode.elementInfo(oldCl);
      info2 = SCode.elementInfo(newCl);
      Error.addMultiSourceMessage(Error.DUPLICATE_CLASSES_NOT_EQUIVALENT,
        {s1, s2}, {info1, info2});
      //print(" *** error message added *** \n");
      then fail();
  end matchcontinue;
end checkMultipleClassesEquivalent;

public function removeOptCrefFromCrefs
  input list<Absyn.ComponentRef> inCrefs;
  input Option<Absyn.ComponentRef> inCref;
  output list<Absyn.ComponentRef> outCrefs;
algorithm
  outCrefs := match(inCrefs, inCref)
    local
      Absyn.ComponentRef cref;

    case (_, SOME(cref)) then removeCrefFromCrefs(inCrefs, cref);
    else inCrefs;
  end match;
end removeOptCrefFromCrefs;

public function removeCrefFromCrefs
"Removes a variable from a variable list"
  input list<Absyn.ComponentRef> inAbsynComponentRefLst;
  input Absyn.ComponentRef inComponentRef;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm
  outAbsynComponentRefLst := matchcontinue (inAbsynComponentRefLst,inComponentRef)
    local
      String n1,n2;
      list<Absyn.ComponentRef> rest_1,rest;
      Absyn.ComponentRef cr1,cr2;
    case ({},_) then {};
    case ((cr1 :: rest),cr2)
      equation
        Absyn.CREF_IDENT(name = n1,subscripts = {}) = cr1;
        Absyn.CREF_IDENT(name = n2,subscripts = {}) = cr2;
        true = stringEq(n1, n2);
        rest_1 = removeCrefFromCrefs(rest, cr2);
      then
        rest_1;
    case ((cr1 :: rest),cr2) // If modifier like on comp like: T t(x=t.y) => t.y must be removed
      equation
        Absyn.CREF_QUAL(name = n1) = cr1;
        Absyn.CREF_IDENT(name = n2) = cr2;
        true = stringEq(n1, n2);
        rest_1 = removeCrefFromCrefs(rest, cr2);
      then
        rest_1;
    case ((cr1 :: rest),cr2)
      equation
        rest_1 = removeCrefFromCrefs(rest, cr2);
      then
        (cr1 :: rest_1);
  end matchcontinue;
end removeCrefFromCrefs;

public function keepConstrainingTypeModifersOnly
"Author: BZ, 2009-07
 A function for filtering out the modifications on the constraining type class."
  input DAE.Mod inMod;
  input list<SCode.Element> elems;
  output DAE.Mod filteredMod;
algorithm
  filteredMod := matchcontinue(inMod,elems)
    local
      SCode.Final f;
      SCode.Each e;
      Option<DAE.EqMod> oe;
      list<DAE.SubMod> subs;
      list<String> compNames;
      SourceInfo info;

    case (_,{}) then inMod;
    case(DAE.NOMOD(),_ ) then DAE.NOMOD();
    case(DAE.REDECL(_,_,_),_) then inMod;
    case(DAE.MOD(f,e,subs,oe,info),_)
      equation
        compNames = List.map(elems,SCode.elementName);
        subs = keepConstrainingTypeModifersOnly2(subs,compNames);
      then
        DAE.MOD(f,e,subs,oe,info);
  end matchcontinue;
end keepConstrainingTypeModifersOnly;

protected function keepConstrainingTypeModifersOnly2 "
Author BZ
Helper function for keepConstrainingTypeModifersOnly"
  input list<DAE.SubMod> isubs;
  input list<String> elems;
  output list<DAE.SubMod> osubs;
algorithm
  osubs := matchcontinue(isubs,elems)
    local
      DAE.SubMod sub;
      DAE.Mod mod;
      String n;
      list<DAE.SubMod> osubs2,subs;
      Boolean b;

    case({},_) then {};
    case(subs,{}) then subs;
    case((sub as DAE.NAMEMOD(ident=n))::subs,_)
      equation
        osubs = keepConstrainingTypeModifersOnly2(subs,elems);
        b = List.isMemberOnTrue(n,elems,stringEq);
        osubs2 = if b then {sub} else {};
        osubs = listAppend(osubs2,osubs);
      then
        osubs;
    case(_::subs,_) then keepConstrainingTypeModifersOnly2(subs,elems);

  end matchcontinue;
end keepConstrainingTypeModifersOnly2;

public function extractConstrainingComps
"Author: BZ, 2009-07
 This function examines a optional Absyn.ConstrainClass argument.
 If there is a constraining class, lookup the class and return its elements."
  input Option<SCode.ConstrainClass> cc;
  input FCore.Graph env;
  input Prefix.Prefix pre;
  output list<SCode.Element> elems;
algorithm
  elems := matchcontinue(cc,env,pre)
    local
      Absyn.Path path;
      SCode.Element cl;
      String name;
      list<SCode.Element> selems,extendselts,compelts,extcompelts,classextendselts,classes;
      list<tuple<SCode.Element, DAE.Mod>> extcomps;
      SCode.Mod mod;
      SCode.Comment cmt;

    case(NONE(),_,_) then {};
    case(SOME(SCode.CONSTRAINCLASS(constrainingClass = path)),_,_)
      equation
        (_,SCode.CLASS(name = name, classDef = SCode.PARTS(elementLst=selems)), _) = Lookup.lookupClass(FCore.emptyCache(),env,path);
        (classes,classextendselts,extendselts,compelts) = splitElts(selems);
        (_,_,_,_,extcomps,_,_,_,_) = InstExtends.instExtendsAndClassExtendsList(FCore.emptyCache(), env, InnerOuter.emptyInstHierarchy, DAE.NOMOD(),  pre, extendselts, classextendselts, selems, ClassInf.UNKNOWN(Absyn.IDENT("")), name, true, false);
        extcompelts = List.map(extcomps,Util.tuple21);
        compelts = listAppend(classes,listAppend(compelts,extcompelts));
      then
        compelts;
    case (SOME(SCode.CONSTRAINCLASS(path, mod, cmt)), _, _)
      equation
        (_,SCode.CLASS(classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(path = path))),_) = Lookup.lookupClass(FCore.emptyCache(),env,path);
        compelts = extractConstrainingComps(SOME(SCode.CONSTRAINCLASS(path, mod, cmt)),env,pre);
      then
        compelts;
  end matchcontinue;
end extractConstrainingComps;

public function moveBindings
  "This function takes two DAElists, the first with equations generated by
   InstBinding.instModEquation and the second the variables that bindings
   belonged to. The function moves the equations back as bindings for the
   variables, used for fixing record bindings."
  input DAE.DAElist inEquations;
  input DAE.DAElist inVariables;
  output DAE.DAElist outVariables;
protected
  list<DAE.Element> eqs, vars;
algorithm
  DAE.DAE(elementLst = eqs) := inEquations;
  DAE.DAE(elementLst = vars) := inVariables;
  Error.assertion(intEq(listLength(eqs), listLength(vars)),
      "- InstUtil.moveBindings: Mismatched number of equations and variables.", Absyn.dummyInfo);
  vars := List.threadMap(eqs, vars, moveBindings2);
  outVariables := DAE.DAE(vars);
end moveBindings;

protected function moveBindings2
  input DAE.Element inEquation;
  input DAE.Element inVariable;
  output DAE.Element outVariable;
algorithm
  outVariable := matchcontinue(inEquation, inVariable)
    local
      DAE.ComponentRef cref;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      DAE.VarVisibility vis;
      DAE.Type ty;
      DAE.InstDims dims;
      DAE.ConnectorType ct;
      DAE.ElementSource src;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> cmt;
      Absyn.InnerOuter io;
      DAE.Exp bind_exp;

    case (_, DAE.VAR(cref, kind, dir, prl, vis, ty, _, dims, ct, src, attr, cmt, io))
      equation
        bind_exp = moveBindings3(inEquation);
      then
        DAE.VAR(cref, kind, dir, prl, vis, ty, SOME(bind_exp), dims, ct, src, attr, cmt, io);

    case (_, DAE.VAR(componentRef = cref))
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- InstUtil.moveBindings failed on " +
            ComponentReference.printComponentRefStr(cref));
      then
        fail();

  end matchcontinue;
end moveBindings2;

protected function moveBindings3
  input DAE.Element inEquation;
  output DAE.Exp outBinding;
algorithm
  outBinding := match(inEquation)
    local
      DAE.Exp bind_exp;

    case DAE.EQUATION(scalar = bind_exp) then bind_exp;
    case DAE.DEFINE(exp = bind_exp) then bind_exp;

  end match;
end moveBindings3;

public function checkModificationOnOuter
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input String inName;
  input DAE.ComponentRef inCref;
  input DAE.Mod inMod;
  input SCode.Variability inVariability;
  input Absyn.InnerOuter inInnerOuter;
  input Boolean inImpl;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inCache, inEnv, inIH, inPrefix, inName, inCref, inMod,
      inVariability, inInnerOuter, inImpl, inInfo)
    local
    HashSet.HashSet sm;
    DAE.ComponentRef cref;

    case (_, _, _, _, _, _, _, SCode.CONST(), _, _, _)
      then ();

    case (_, _, _, _, _, _, _, SCode.PARAM(), _, _, _)
      then ();

    case (_, _, InnerOuter.TOP_INSTANCE(sm=sm)::_, _, _, _, DAE.MOD(), _, Absyn.OUTER(), _, _)
      equation
        // BTH: we check if the outer variable is in an instance that is
        //      part of a Modelica state machine. In that case we have added
        //      an equation modification, binding the inner variable to
        //      the outer variable (instead of replacing the outer variable
        //      by the inner variable). See InstVar.instVar(..).
        //      Hence, such a modification should not throw an error.
        cref = PrefixUtil.prefixToCref(inPrefix);
        true = BaseHashSet.has(cref, sm);
      then ();

    else
      equation
        // adrpo: we cannot check this here as:
        //        we might have modifications on inner that we copy here
        //        Dymola doesn't report modifications on outer as error!
        //        instead we check here if the modification is not the same
        //        as the one on inner
        false = InnerOuter.modificationOnOuter(inCache, inEnv, inIH, inPrefix,
          inName, inCref, inMod, inInnerOuter, inImpl, inInfo);
      then
        ();
  end matchcontinue;
end checkModificationOnOuter;

public function checkFunctionVar
  "Checks that a function variable is valid."
  input String inName;
  input SCode.Attributes inAttributes;
  input SCode.Prefixes inPrefixes;
  input SourceInfo inInfo;
algorithm
  _ := match(inName, inAttributes, inPrefixes, inInfo)
    // Public non-formal parameters are not allowed, but since they're used in
    // the MSL we just issue a warning for now.
    case (_, SCode.ATTR(direction = Absyn.BIDIR()),
        SCode.PREFIXES(visibility = SCode.PUBLIC()), _)
      equation
        Error.addSourceMessage(Error.NON_FORMAL_PUBLIC_FUNCTION_VAR,
          {inName}, inInfo);
      then
        ();

    // Protected non-formal parameters are ok.
    case (_, SCode.ATTR(direction = Absyn.BIDIR()),
        SCode.PREFIXES(visibility = SCode.PROTECTED()), _)
      then ();

    // Protected formal parameters are not allowed.
    case (_, SCode.ATTR(),
        SCode.PREFIXES(visibility = SCode.PROTECTED()), _)
      equation
        Error.addSourceMessage(Error.PROTECTED_FORMAL_FUNCTION_VAR,
          {inName}, inInfo);
      then
        fail();

    // Everything else, i.e. public formal parameters, are ok.
    else ();
  end match;
end checkFunctionVar;

public function checkFunctionVarType
  input DAE.Type inType;
  input ClassInf.State inState;
  input String inVarName;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inType, inState, inVarName, inInfo)
    local
      String ty_str;

    case (_, _, _, _)
      equation
        true = Types.isValidFunctionVarType(inType);
      then
        ();

    else
      equation
        ty_str = Types.getTypeName(inType);
        Error.addSourceMessage(Error.INVALID_FUNCTION_VAR_TYPE,
          {ty_str, inVarName}, inInfo);
      then
        fail();

  end matchcontinue;
end checkFunctionVarType;

public function liftNonBasicTypes
"Helper functin to instVar2. All array variables should be
 given array types, by lifting the type given a dimensionality.
 An exception are types extending builtin types, since they already
 have array types. This relation performs the lifting for alltypes
 except types extending basic types."
  input DAE.Type tp;
  input DAE.Dimension dimt;
  output DAE.Type outTp;
algorithm
  outTp:= matchcontinue(tp,dimt)
    local DAE.Type ty;
    case (DAE.T_SUBTYPE_BASIC(complexType = ty),_)
      equation
        false = listEmpty(Types.getDimensions(ty));
      then
        tp;
    else Types.liftArray(tp, dimt);
  end matchcontinue;
end liftNonBasicTypes;

public function checkHigherVariability
"If the binding expression has higher variability that the component, generates an error.
Helper to makeVariableBinding. Author -- alleb"
  input DAE.Const compConst;
  input DAE.Const bindConst;
  input Prefix.Prefix pre;
  input String name;
  input DAE.Exp binding;
  input SourceInfo info;
algorithm
  _ := matchcontinue(compConst,bindConst,pre,name,binding,info)
  local
    DAE.Const c,c1;
    Ident n;
    String sc,sc1,se,sn;
    DAE.Exp e;
  case (c,c1,_,_,_,_)
    equation
      equality(c=c1);
    then ();

  // When doing checkModel we might have parameters with variable bindings,
  // for example when the binding depends on the dimensions on an array with
  // unknown dimensions.
  case (DAE.C_PARAM(),DAE.C_UNKNOWN(),_,_,_,_)
    equation
      true = Flags.getConfigBool(Flags.CHECK_MODEL);
    then ();

  // Since c1 is generated by Types.matchProp, it can not be lower that c, so no need to check that it is higher
  case (c,c1,_,n,e,_)
    equation
      sn = PrefixUtil.printPrefixStr2(pre)+n;
      sc = DAEUtil.constStr(c);
      sc1 = DAEUtil.constStr(c1);
      se = ExpressionDump.printExpStr(e);
      Error.addSourceMessage(Error.HIGHER_VARIABILITY_BINDING,{sn,sc,se,sc1}, info);
    then
      fail();
  end matchcontinue;
end checkHigherVariability;

public function makeArrayType
"Creates an array type from the element type
  given as argument and a list of dimensional sizes."
  input DAE.Dimensions inDimensionLst;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inDimensionLst,inType)
    local
      DAE.Type ty,ty_1;
      Integer i;
      DAE.Dimensions xs;
      DAE.TypeSource ts;
      DAE.Type tty;
      DAE.Dimension dim;

    case ({},ty) then ty;

    case (dim :: xs, tty)
      equation
        ty_1 = makeArrayType(xs, tty);
        ts = Types.getTypeSource(tty);
      then
        DAE.T_ARRAY(ty_1, {dim}, ts);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- InstUtil.makeArrayType failed\n");
      then
        fail();
  end matchcontinue;
end makeArrayType;

public function getUsertypeDimensions
"Retrieves the dimensions of a usertype and the innermost class type to instantiate,
  and also any modifications from the base classes of the usertype.
  The builtin types have no dimension, whereas a user defined type might
  have dimensions. For instance, type Point = Real[3];
  has one dimension of size 3 and the class to instantiate is Real"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SCode.Element inClass;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inBoolean;
  output FCore.Cache outCache;
  output DAE.Dimensions outDimensionLst;
  output SCode.Element classToInstantiate;
  output DAE.Mod outMods "modifications from base classes";
algorithm
  (outCache,outDimensionLst,classToInstantiate,outMods) := matchcontinue (inCache,inEnv,inIH,inPrefix,inClass,inInstDims,inBoolean)
    local
      SCode.Element cl;
      FCore.Graph cenv,env;
      Absyn.ComponentRef owncref;
      list<Absyn.Subscript> ad_1;
      DAE.Mod mod_1,type_mods;
      Option<DAE.EqMod> eq;
      DAE.Dimensions dim1,dim2,res;
      Prefix.Prefix pre;
      String id;
      Absyn.Path cn;
      Option<list<Absyn.Subscript>> ad;
      SCode.Mod mod;
      InstDims dims;
      Boolean impl;
      FCore.Cache cache;
      InstanceHierarchy ih;
      SourceInfo info;
      list<SCode.Element> els;
      SCode.Path path;

    case (cache, _, _, _, cl as SCode.CLASS(name = "Real"), _, _) then (cache,{},cl,DAE.NOMOD());
    case (cache, _, _, _, cl as SCode.CLASS(name = "Integer"), _, _) then (cache,{},cl,DAE.NOMOD());
    case (cache, _, _, _, cl as SCode.CLASS(name = "String"), _, _) then (cache,{},cl,DAE.NOMOD());
    case (cache, _, _, _, cl as SCode.CLASS(name = "Boolean"), _, _) then (cache,{},cl,DAE.NOMOD());
    // BTH
    case (cache, _, _, _, cl as SCode.CLASS(name = "Clock"), _, _)
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then (cache,{},cl,DAE.NOMOD());

    case (cache, _, _, _, cl as SCode.CLASS(restriction = SCode.R_RECORD(_),
                                        classDef = SCode.PARTS()), _, _) then (cache,{},cl,DAE.NOMOD());

    //------------------------
    // MetaModelica extension
    case (cache, env, _, pre, cl as SCode.CLASS(name = id, info=info,
                                       classDef = SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT(),_,arrayDim = ad))),
          dims,impl)
      equation
        true=Config.acceptMetaModelicaGrammar();
        owncref = Absyn.CREF_IDENT(id,{});
        ad_1 = getOptionArraydim(ad);
        // Absyn.IDENT("Integer") used as a dummie
        (cache,dim1) = elabArraydim(cache,env, owncref, Absyn.IDENT("Integer"), ad_1,NONE(), impl,NONE(),true, false,pre,info,dims);
      then
        (cache,dim1,cl,DAE.NOMOD());

    // Partial function definitions with no output - stefan
    case (cache, _, _, _,
      cl as SCode.CLASS(restriction = SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(_)),
                        partialPrefix = SCode.PARTIAL()), _, _)
      then
        (cache,{},cl,DAE.NOMOD());

    case (_, _, _, _,
      SCode.CLASS(name = id,info=info,restriction = SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(_)),
                  partialPrefix = SCode.NOT_PARTIAL()),_,_)
      equation
        Error.addSourceMessage(Error.META_FUNCTION_TYPE_NO_PARTIAL_PREFIX, {id}, info);
      then fail();

    // MetaModelica Uniontype. Added 2009-05-11 sjoelund
    case (cache, _, _, _,
      cl as SCode.CLASS(restriction = SCode.R_UNIONTYPE()), _, _)
      then (cache,{},cl,DAE.NOMOD());
      /*----------------------*/

    // Derived classes with restriction type, e.g. type Point = Real[3];
    case (cache, env, ih, pre,
      SCode.CLASS(name = id,restriction = SCode.R_TYPE(),info=info,
                            classDef = SCode.DERIVED(Absyn.TPATH(path = cn, arrayDim = ad),modifications = mod)),
          dims, impl)
      equation
        (cache,cl,cenv) = Lookup.lookupClass(cache, env, cn, SOME(info));
        owncref = Absyn.CREF_IDENT(id,{});
        ad_1 = getOptionArraydim(ad);
        env = addEnumerationLiteralsToEnv(env, cl);

        (cache,mod_1) = Mod.elabMod(cache, env, ih, pre, mod, impl, Mod.DERIVED(cn), info);
        eq = Mod.modEquation(mod_1);
        (cache,dim1,cl,type_mods) = getUsertypeDimensions(cache, cenv, ih, pre, cl, dims, impl);
        (cache,dim2) = elabArraydim(cache, env, owncref, cn, ad_1, eq, impl, NONE(), true, false, pre, info, dims);
        type_mods = Mod.addEachIfNeeded(type_mods, dim2);
        // do not add each to mod_1, it should have it already!
        // mod_1 = Mod.addEachIfNeeded(mod_1, dim2);
        type_mods = Mod.merge(mod_1, type_mods);
        res = listAppend(dim2, dim1);
      then
        (cache,res,cl,type_mods);

    // extended classes type Y = Real[3]; class X extends Y;
    case (cache, env, ih, pre,
      SCode.CLASS(
                  classDef = SCode.PARTS(elementLst=els,
                  normalEquationLst = {},
                  initialEquationLst = {},
                  normalAlgorithmLst = {},
                  initialAlgorithmLst = {})),
          _, impl)
      equation
        (_,_,{SCode.EXTENDS(path, _, mod,_, info)},{}) = splitElts(els); // ONLY ONE extends!
        (cache,mod_1) = Mod.elabModForBasicType(cache, env, ih, pre, mod, impl, Mod.EXTENDS(path), info);
        (cache,cl,_) = Lookup.lookupClass(cache, env, path);
        (cache,res,cl,type_mods) = getUsertypeDimensions(cache,env,ih,pre,cl,{},impl);
        // type_mods = Mod.addEachIfNeeded(type_mods, res);
        type_mods = Mod.merge(mod_1, type_mods);
      then
        (cache,res,cl,type_mods);

    case (cache, _, _, _, cl as SCode.CLASS(), _, _)
      then (cache,{},cl,DAE.NOMOD());

    case (_, _, _, _, SCode.CLASS(), _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        id = SCodeDump.unparseElementStr(inClass,SCodeDump.defaultOptions);
        Debug.traceln("InstUtil.getUsertypeDimensions failed: " + id);
      then
        fail();

  end matchcontinue;
end getUsertypeDimensions;

protected function addEnumerationLiteralsToEnv
  "If the input SCode.Element is an enumeration, this function adds all of it's
   enumeration literals to the environment. This is used in getUsertypeDimensions
   so that the modifiers on an enumeration can be elaborated when the literals
   are used, for example like this:
     type enum1 = enumeration(val1, val2);
     type enum2 = enum1(start = val1); // val1 needs to be in the environment here."
  input FCore.Graph inEnv;
  input SCode.Element inClass;
  output FCore.Graph outEnv;
algorithm
  outEnv := matchcontinue(inEnv, inClass)
    local
      list<SCode.Element> enums;
      FCore.Graph env;
    case (_, SCode.CLASS(restriction = SCode.R_ENUMERATION(), classDef = SCode.PARTS(elementLst = enums)))
      equation
        env = List.fold(enums, addEnumerationLiteralToEnv, inEnv);
      then env;
    else inEnv; // Not an enumeration, no need to do anything.
  end matchcontinue;
end addEnumerationLiteralsToEnv;

protected function addEnumerationLiteralToEnv
  input SCode.Element inEnum;
  input FCore.Graph inEnv;
  output FCore.Graph outEnv;
algorithm
  outEnv := matchcontinue(inEnum, inEnv)
    local
      SCode.Ident lit;
      FCore.Graph env;

    case (SCode.COMPONENT(name = lit), _)
      equation
        env = FGraph.mkComponentNode(inEnv,
          DAE.TYPES_VAR(lit, DAE.dummyAttrVar, DAE.T_UNKNOWN_DEFAULT, DAE.UNBOUND(), NONE()),
          inEnum, DAE.NOMOD(), FCore.VAR_UNTYPED(), FGraph.empty());
      then env;

    else
      equation
        print("InstUtil.addEnumerationLiteralToEnv: Unknown enumeration type!\n");
      then fail();
  end matchcontinue;
end addEnumerationLiteralToEnv;

public function updateClassInfState
  input FCore.Cache inCache;
  input FCore.Graph inNewEnv;
  input FCore.Graph inOldEnv;
  input ClassInf.State inCIState;
  output ClassInf.State outCIState;
algorithm
  outCIState := matchcontinue(inCache, inNewEnv, inOldEnv, inCIState)
    local
      ClassInf.State ci_state;
      FCore.Graph rest;
      Absyn.Ident id;
      SCode.Element cls;

    // top env, return the same ci_state
    case (_, _, _, ci_state)
      equation
        true = FGraph.isTopScope(inNewEnv);
      then
        ci_state;

    // same environment, return the same ci_state
    case (_, _, _, ci_state)
      equation
        true = stringEq(FGraph.getGraphNameStr(inNewEnv),
                        FGraph.getGraphNameStr(inOldEnv));
      then
        ci_state;

    // not the same environment, try to
    // make a ci state from the new env
    case (_, _, _, _)
      equation
        // not top scope
        false = FGraph.isTopScope(inNewEnv);
        id = FNode.refName(FGraph.lastScopeRef(inNewEnv));
        (rest, _) = FGraph.stripLastScopeRef(inNewEnv);
        (_, cls, _) = Lookup.lookupClass(inCache, rest, Absyn.IDENT(id));
        ci_state = ClassInf.start(SCode.getClassRestriction(cls), FGraph.getGraphName(inNewEnv));
      then
        ci_state;

    else inCIState;

  end matchcontinue;
end updateClassInfState;

public function evalEnumAndBoolDim
"function: instDAE.Dimension
  instantiates one dimension expression, See also instDimExpLst."
  input DAE.Dimension inDimension;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match (inDimension)
    local
      Integer i;

    // case (DAE.DIM_ENUM(size = i)) then DAE.DIM_INTEGER(i);
    case (DAE.DIM_BOOLEAN()) then DAE.DIM_INTEGER(2);
    else inDimension;
  end match;
end evalEnumAndBoolDim;

/*TODO: mahge: Remove me*/
public function instDimExpNonSplit
"the vesrion of instDimExp for the case of non-expanded arrays"
  input DAE.Dimension inDimension;
  input Boolean inBoolean;
  output DAE.Subscript outSubscript;
algorithm
  outSubscript := match (inDimension,inBoolean)
    local
      DAE.Exp e;
      Integer i;

    case (DAE.DIM_UNKNOWN(),_) then DAE.WHOLEDIM();
    case (DAE.DIM_INTEGER(integer = i),_) then DAE.WHOLE_NONEXP(DAE.ICONST(i));
    case (DAE.DIM_ENUM(size = i), _) then DAE.WHOLE_NONEXP(DAE.ICONST(i));
    case (DAE.DIM_BOOLEAN(), _) then DAE.WHOLE_NONEXP(DAE.ICONST(2));
    //case (DAE.DIM_EXP(exp = e as DAE.RANGE(exp = _)), _) then DAE.INDEX(e);
    case (DAE.DIM_EXP(exp = e), _) then DAE.WHOLE_NONEXP(e);
  end match;
end instDimExpNonSplit;

public function instWholeDimFromMod
  "Tries to determine the size of a WHOLEDIM dimension by looking at a variables
  modifier."
  input DAE.Dimension dimensionExp;
  input DAE.Mod modifier;
  input String inVarName;
  input SourceInfo inInfo;
  output DAE.Dimension outDimension;
algorithm
  outDimension := matchcontinue(dimensionExp, modifier, inVarName, inInfo)
    local
      DAE.Dimension d;
      DAE.Subscript sub;
      DAE.Exp exp;
      String exp_str;

    case (DAE.DIM_UNKNOWN(), DAE.MOD(binding =
            SOME(DAE.TYPED(modifierAsExp = exp))), _, _)
      equation
        (d :: _) = Expression.expDimensions(exp);
      then d;

    // TODO: We should print an error if we fail to deduce the dimensions from
    // the modifier, but we do not yet handle some cases (such as
    // Modelica.Blocks.Sources.KinematicPTP), so just print a warning for now.
    case (DAE.DIM_UNKNOWN(), DAE.MOD(binding =
            SOME(DAE.TYPED(modifierAsExp = exp))), _, _)
      equation
        exp_str = ExpressionDump.printExpStr(exp);
        Error.addSourceMessage(Error.FAILURE_TO_DEDUCE_DIMS_FROM_MOD,
          {inVarName, exp_str}, inInfo);
      then
        fail();

    case (DAE.DIM_UNKNOWN(), _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- InstUtil.instWholeDimFromMod failed\n");
      then
        fail();
  end matchcontinue;
end instWholeDimFromMod;

public function propagateAttributes
  "Propagates attributes (flow, stream, discrete, parameter, constant, input,
  output) to elements in a structured component."
  input DAE.DAElist inDae;
  input SCode.Attributes inAttributes;
  input SCode.Prefixes inPrefixes;
  input SourceInfo inInfo;
  output DAE.DAElist outDae;
protected
  list<DAE.Element> elts;
algorithm
  DAE.DAE(elementLst = elts) := inDae;
  elts := List.map3(elts, propagateAllAttributes, inAttributes, inPrefixes, inInfo);
  outDae := DAE.DAE(elts);
end propagateAttributes;

protected function propagateAllAttributes
  "Helper function to propagateAttributes. Propagates all attributes if needed."
  input DAE.Element inElement;
  input SCode.Attributes inAttributes;
  input SCode.Prefixes inPrefixes;
  input SourceInfo inInfo;
  output DAE.Element outElement;
algorithm
  outElement := match(inElement, inAttributes, inPrefixes, inInfo)
    local
      DAE.ComponentRef cr;
      DAE.VarKind vk;
      DAE.VarDirection vdir;
      DAE.VarParallelism vprl;
      DAE.VarVisibility vvis;
      DAE.Type ty;
      Option<DAE.Exp> binding;
      DAE.InstDims dims;
      SCode.ConnectorType ct1;
      DAE.ConnectorType ct2;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> var_attrs;
      Option<SCode.Comment> cmt;
      Absyn.InnerOuter io1, io2;
      SCode.Parallelism sprl;
      SCode.Variability var;
      Absyn.Direction dir;
      SCode.Final fp;
      SCode.Ident ident;
      list<DAE.Element> el;
      SCode.Visibility vis;

    // Just return the element if nothing needs to be changed.
    case (_,
        SCode.ATTR(
          connectorType = SCode.POTENTIAL(),
          parallelism = SCode.NON_PARALLEL(),
          variability = SCode.VAR(),
          direction = Absyn.BIDIR()),
        SCode.PREFIXES(
          visibility = SCode.PUBLIC(),
          finalPrefix = SCode.NOT_FINAL(),
          innerOuter = Absyn.NOT_INNER_OUTER()), _)
      then inElement;

    // Normal variable.
    case (
        DAE.VAR(
          componentRef = cr,
          kind = vk,
          direction = vdir,
          parallelism = vprl,
          protection = vvis,
          ty = ty,
          binding = binding,
          dims = dims,
          connectorType = ct2,
          source = source,
          variableAttributesOption = var_attrs,
          comment = cmt,
          innerOuter = io2),
        SCode.ATTR(
          connectorType = ct1,
          parallelism = sprl,
          variability = var,
          direction = dir),
        SCode.PREFIXES(
          visibility = vis,
          finalPrefix = fp,
          innerOuter = io1), _)
      equation
        vdir = propagateDirection(vdir, dir, cr, inInfo);
        vk = propagateVariability(vk, var);
        vprl = propagateParallelism(vprl,sprl,cr,inInfo);
        vvis = propagateVisibility(vvis, vis);
        var_attrs = propagateFinal(var_attrs, fp);
        io2 = propagateInnerOuter(io2, io1);
        ct2 = propagateConnectorType(ct2, ct1, cr, inInfo);
      then
        DAE.VAR(cr, vk, vdir, vprl, vvis, ty, binding, dims, ct2, source, var_attrs, cmt, io2);

    // Structured component.
    case (DAE.COMP(ident = ident, dAElist = el, source = source, comment = cmt), _, _, _)
      equation
        el = List.map3(el, propagateAllAttributes, inAttributes, inPrefixes, inInfo);
      then
        DAE.COMP(ident, el, source, cmt);

    // Everything else.
    else inElement;

  end match;
end propagateAllAttributes;

protected function propagateDirection
  "Helper function to propagateAttributes. Propagates the input/output
  attribute to variables of a structured component."
  input DAE.VarDirection inVarDirection;
  input Absyn.Direction inDirection;
  input DAE.ComponentRef inCref;
  input SourceInfo inInfo;
  output DAE.VarDirection outVarDirection;
algorithm
  outVarDirection := match(inVarDirection, inDirection, inCref, inInfo)
    local
      String s1, s2, s3;

    // Component that is bidirectional does not change direction on subcomponents.
    case (_, Absyn.BIDIR(), _, _) then inVarDirection;

    // Bidirectional variables are changed to input or output if component has
    // such prefix.
    case (DAE.BIDIR(), _, _, _) then absynDirToDaeDir(inDirection);

    // Error when component declared as input or output if the variable already
    // has such a prefix.
    else
      equation
        s1 = Dump.directionSymbol(inDirection);
        s2 = ComponentReference.printComponentRefStr(inCref);
        s3 = DAEDump.dumpDirectionStr(inVarDirection);
        Error.addSourceMessage(Error.COMPONENT_INPUT_OUTPUT_MISMATCH,
          {s1, s2, s3}, inInfo);
      then
        fail();
  end match;
end propagateDirection;

protected function propagateParallelism
  "Helper function to propagateAttributes. Propagates the input/output
  attribute to variables of a structured component."
  input DAE.VarParallelism inVarParallelism;
  input SCode.Parallelism inParallelism;
  input DAE.ComponentRef inCref;
  input SourceInfo inInfo;
  output DAE.VarParallelism outVarParallelism;
algorithm
  outVarParallelism := matchcontinue(inVarParallelism, inParallelism, inCref, inInfo)
    local
      String s1, s2, s3, s4;
      DAE.VarParallelism daeprl1,daeprl2;
      SCode.Parallelism sprl;

    // Component that is non parallel does not change Parallelism on subcomponents.
    case (_, SCode.NON_PARALLEL(), _, _) then inVarParallelism;

    // non_parallel variables are changed to parlocal or parglobal
    // depending on the component
    case (DAE.NON_PARALLEL(), _, _, _) then DAEUtil.scodePrlToDaePrl(inParallelism);

    // if the two parallelisms are equal then it is OK
    case(daeprl1,_,_,_)
      equation
        daeprl2 = DAEUtil.scodePrlToDaePrl(inParallelism);
        true = DAEUtil.daeParallelismEqual(daeprl1,daeprl2);
      then
        daeprl1;

    // Reaches here If the component is declared as parlocal or parglobal
    // and the subcomponent is declared as parglobal or parlocal, respectively.
    // Print a warning and override the subcomponent's parallelism.
    else
      equation
        daeprl2 = DAEUtil.scodePrlToDaePrl(inParallelism);

        s1 = DAEDump.dumpVarParallelismStr(daeprl2);
        s2 = ComponentReference.printComponentRefStr(inCref);
        s3 = DAEDump.dumpVarParallelismStr(inVarParallelism);

        s4 = "\n" +
             "- Component declared as '" + s1 +
             "' when having the variable '" + s2 +
             "' declared as '" + s3 + "' : Subcomponent parallelism modified to." +
             s1
             ;
        Error.addSourceMessage(Error.PARMODELICA_WARNING,
          {s4}, inInfo);
      then
        daeprl2;
  end matchcontinue;
end propagateParallelism;

protected function propagateVisibility
  "Helper function to propagateAttributes. Propagates the visibility (public or
   protected) attribute to variables of a structured component."
  input DAE.VarVisibility inVarVisibility;
  input SCode.Visibility inVisibility;
  output DAE.VarVisibility outVarVisibility;
algorithm
  outVarVisibility := match(inVarVisibility, inVisibility)
    case (_, SCode.PROTECTED()) then DAE.PROTECTED();
    else inVarVisibility;
  end match;
end propagateVisibility;

protected function propagateVariability
  "Helper function to propagateAttributes. Propagates the variability (parameter
  or constant) attribute to variables of a structured component."
  input DAE.VarKind inVarKind;
  input SCode.Variability inVariability;
  output DAE.VarKind outVarKind;
algorithm
  outVarKind := match(inVarKind, inVariability)
    // Component that is VAR does not change variability of subcomponents.
    case (_, SCode.VAR()) then inVarKind;
    // Most restrictive variability is preserved.
    case (DAE.DISCRETE(), _) then inVarKind;
    case (_, SCode.DISCRETE()) then DAE.DISCRETE();
    case (DAE.CONST(), _) then inVarKind;
    case (_, SCode.CONST()) then DAE.CONST();
    case (DAE.PARAM(), _) then inVarKind;
    case (_, SCode.PARAM()) then DAE.PARAM();
    else inVarKind;
  end match;
end propagateVariability;

protected function propagateFinal
  "Helper function to propagateAttributes. Propagates the final attribute to
  variables of a structured component."
  input Option<DAE.VariableAttributes> inVarAttributes;
  input SCode.Final inFinal;
  output Option<DAE.VariableAttributes> outVarAttributes;
algorithm
  outVarAttributes := match(inVarAttributes, inFinal)
    case (_, SCode.FINAL())
      then DAEUtil.setFinalAttr(inVarAttributes, SCode.finalBool(inFinal));
    else inVarAttributes;
  end match;
end propagateFinal;

protected function propagateInnerOuter
  "Helper function to propagateAttributes. Propagates the inner/outer attribute
  to variables of a structured component."
  input Absyn.InnerOuter inVarInnerOuter;
  input Absyn.InnerOuter inInnerOuter;
  output Absyn.InnerOuter outVarInnerOuter;
algorithm
  outVarInnerOuter := match(inVarInnerOuter, inInnerOuter)
    // Component that is unspecified does not change inner/outer on subcomponents.
    case (_, Absyn.NOT_INNER_OUTER()) then inVarInnerOuter;
    // Unspecified variables are changed to the same inner/outer prefix as the
    // component.
    case (Absyn.NOT_INNER_OUTER(), _) then inInnerOuter;
    // If variable already have inner/outer, keep it.
    else inVarInnerOuter;
  end match;
end propagateInnerOuter;

protected function propagateConnectorType
  "Helper function to propagateAttributes. Propagates the flow/stream attribute
   to variables of a structured component."
  input DAE.ConnectorType inVarConnectorType;
  input SCode.ConnectorType inConnectorType;
  input DAE.ComponentRef inCref;
  input SourceInfo inInfo;
  output DAE.ConnectorType outVarConnectorType;
algorithm
  outVarConnectorType :=
  match(inVarConnectorType, inConnectorType, inCref, inInfo)
    local
      String s1, s2, s3;

    case (_, SCode.POTENTIAL(), _, _) then inVarConnectorType;
    case (DAE.POTENTIAL(), SCode.FLOW(), _, _) then DAE.FLOW();
    case (DAE.NON_CONNECTOR(), SCode.FLOW(), _, _) then DAE.FLOW();
    case (DAE.POTENTIAL(), SCode.STREAM(), _, _) then DAE.STREAM();
    case (DAE.NON_CONNECTOR(), SCode.STREAM(), _, _) then DAE.STREAM();

    // Error if the component tries to overwrite the prefix of a subcomponent.
    else
      equation
        s1 = SCodeDump.connectorTypeStr(inConnectorType);
        s2 = ComponentReference.printComponentRefStr(inCref);
        s3 = DAEDump.dumpConnectorType(inVarConnectorType);
        Error.addSourceMessage(Error.INVALID_TYPE_PREFIX,
          {s1, "variable", s2, s3}, inInfo);
      then
        fail();

  end match;
end propagateConnectorType;

protected function absynDirToDaeDir
"Translates Absyn.Direction to DAE.VarDirection.
  Needed so that input, output is transferred to DAE."
  input Absyn.Direction inDirection;
  output DAE.VarDirection outVarDirection;
algorithm
  outVarDirection := match (inDirection)
    case Absyn.INPUT() then DAE.INPUT();
    case Absyn.OUTPUT() then DAE.OUTPUT();
    case Absyn.BIDIR() then DAE.BIDIR();
  end match;
end absynDirToDaeDir;

protected function attrIsParam
"Returns true if attributes contain PARAM"
  input SCode.Attributes inAttributes;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inAttributes)
    case SCode.ATTR(variability = SCode.PARAM()) then true;
    else false;
  end matchcontinue;
end attrIsParam;

public function elabComponentArraydimFromEnv
"author: PA
  Lookup uninstantiated component in env, elaborate its modifiers to
  find arraydimensions and return as DAE.Dimension list.
  Used when components have submodifiers (on e.g. attributes) using
  size to find dimensions of component."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Dimensions outDimensionLst;
algorithm
  (outCache,outDimensionLst) := matchcontinue (inCache,inEnv,inComponentRef,info)
    local
      String id;
      list<Absyn.Subscript> ad;
      SCode.Mod m,m_1;
      DAE.Mod cmod,cmod_1,m_2,mod_2;
      DAE.EqMod eq;
      DAE.Dimensions dims;
      FCore.Graph env;
      DAE.ComponentRef cref;
      FCore.Cache cache;
      list<DAE.Subscript> subs;

    case (cache,env,DAE.CREF_IDENT(ident = id),_)
      equation
        (cache,_,SCode.COMPONENT(modifications = m),cmod,_,_)
          = Lookup.lookupIdent(cache, env, id);
        cmod_1 = Mod.stripSubmod(cmod);
        m_1 = SCode.stripSubmod(m);
        (cache,m_2) = Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), m_1, false, Mod.COMPONENT(id), info);
        mod_2 = Mod.merge(cmod_1, m_2);
        SOME(eq) = Mod.modEquation(mod_2);
        (cache,dims) = elabComponentArraydimFromEnv2(cache,eq, env);
      then
        (cache,dims);

    case (cache,env,DAE.CREF_IDENT(ident = id),_)
      equation
        (cache,_,SCode.COMPONENT(attributes = SCode.ATTR(arrayDims = ad)),_,_,_)
          = Lookup.lookupIdent(cache,env, id);
        (cache, subs, _) = Static.elabSubscripts(cache, env, ad, true, Prefix.NOPRE(), info);
        dims = Expression.subscriptDimensions(subs);
      then
        (cache,dims);

    case (_, _, cref,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- InstUtil.elabComponentArraydimFromEnv failed: " +
          ComponentReference.printComponentRefStr(cref));
      then
        fail();

  end matchcontinue;
end elabComponentArraydimFromEnv;

protected function elabComponentArraydimFromEnv2
"author: PA
  Helper function to elabComponentArraydimFromEnv.
  This function is similar to elabArraydim, but it will only
  investigate binding (DAE.EqMod) and not the component declaration."
  input FCore.Cache inCache;
  input DAE.EqMod inEqMod;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output DAE.Dimensions outDimensionLst;
algorithm
  (outCache,outDimensionLst) := match (inCache,inEqMod,inEnv)
    local
      list<Integer> lst;
      DAE.Dimensions lst_1;
      DAE.Exp e;
      DAE.Type t;
      FCore.Graph env;
      FCore.Cache cache;

    case (cache,DAE.TYPED(properties = DAE.PROP(type_ = t)),_)
      equation
        lst = Types.getDimensionSizes(t);
        lst_1 = List.map(lst, Expression.intDimension);
      then
        (cache,lst_1);

  end match;
end elabComponentArraydimFromEnv2;

public function elabArraydimOpt
"Same functionality as elabArraydim, but takes an optional arraydim.
  In case of NONE(), empty DAE.Dimension list is returned."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Path path "Class of declaration";
  input Option<Absyn.ArrayDim> inAbsynArrayDimOption;
  input Option<DAE.EqMod> inTypesEqModOption;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  input list<list<DAE.Dimension>> inInstDims;
  output FCore.Cache outCache;
  output DAE.Dimensions outDimensionLst;
algorithm
  (outCache,outDimensionLst) :=
  match (inCache,inEnv,inComponentRef,path,inAbsynArrayDimOption,inTypesEqModOption,inBoolean,inST,performVectorization,inPrefix,info,inInstDims)
    local
      DAE.Dimensions res;
      FCore.Graph env;
      Absyn.ComponentRef owncref;
      list<Absyn.Subscript> ad;
      Option<DAE.EqMod> eq;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      FCore.Cache cache;
      Boolean doVect;
      Prefix.Prefix pre;
      InstDims inst_dims;
    case (cache,env,owncref,_,SOME(ad),eq,impl,st,doVect,pre,_,inst_dims)
      equation
        (cache,res) = elabArraydim(cache,env, owncref, path,ad, eq, impl, st,doVect, false,pre,info,inst_dims);
      then
        (cache,res);
    case (cache,_,_,_,NONE(),_,_,_,_,_,_,_) then (cache,{});
  end match;
end elabArraydimOpt;

public function elabArraydim
"This functions examines both an `Absyn.ArrayDim\' and an `DAE.EqMod
  option\' argument to find out the dimensions af a component.  If
  no equation modifications is given, only the declared dimension is
  used.

  When the size of a dimension in the type is undefined, the
  corresponding size in the type of the modification is used.

  All this is accomplished by examining the two arguments separately
  and then using `complete_arraydime\' or `compatible_arraydim\' to
  check that that the dimension sizes are compatible and complete."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Path path "Class of declaration";
  input Absyn.ArrayDim inArrayDim;
  input Option<DAE.EqMod> inTypesEqModOption;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Boolean isFunctionInput;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  input list<list<DAE.Dimension>> inInstDims;
  output FCore.Cache outCache;
  output DAE.Dimensions outDimensionLst;
algorithm
  (outCache,outDimensionLst) :=
  matchcontinue
    (inCache,inEnv,inComponentRef,path,inArrayDim,inTypesEqModOption,inBoolean,inST,performVectorization,isFunctionInput,inPrefix,inInfo,inInstDims)
    local
      DAE.Dimensions dim,dim1,dim2;
      DAE.Dimensions dim3;
      FCore.Graph env;
      Absyn.ComponentRef cref;
      list<Absyn.Subscript> ad;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      DAE.Exp e,e_1;
      DAE.Type t;
      String e_str,t_str,dim_str;
      FCore.Cache cache;
      Boolean doVect;
      DAE.Properties prop;
      Prefix.Prefix pre;
      Absyn.Exp aexp;
      Option<DAE.EqMod> eq;
      InstDims inst_dims;
      SourceInfo info;

    // The size of function input arguments should not be set here, since they
    // may vary depending on the inputs. So we ignore any modifications on input
    // variables here.
    case (cache, env, cref, _, ad, _, _, st, doVect, true, pre, info, _)
      equation
        (cache, dim) = Static.elabArrayDims(cache, env, cref, ad, true, st, doVect, pre, info);
      then
        (cache, dim);

    case (cache,_,_,_,{},_,_,_,_,_,_,_,_) then (cache, {});

    case (cache,env,cref,_,ad,NONE(),impl,st,doVect,_,pre,info,_) /* impl */
      equation
        (cache,dim) = Static.elabArrayDims(cache,env, cref, ad, impl, st,doVect,pre,info);
      then
        (cache,dim);

    case (cache,env,cref,_,ad,SOME(DAE.TYPED(e,_,prop,_)),impl,st,doVect,_ ,pre,info,inst_dims) /* Untyped expressions must be elaborated. */
      equation
        t = Types.getPropType(prop);
        (cache,dim1) = Static.elabArrayDims(cache,env, cref, ad, impl, st,doVect,pre,info);
        dim2 = elabArraydimType(t, ad, e, path, pre, cref, info,inst_dims);
        //Debug.traceln("TYPED: " + ExpressionDump.printExpStr(e) + " s: " + FGraph.printGraphPathStr(env));
        dim3 = List.threadMap(dim1, dim2, compatibleArraydim);
      then
        (cache,dim3);

    case (cache,env,cref,_,ad,SOME(DAE.UNTYPED(aexp)),impl,st,doVect, _,pre,info,inst_dims)
      equation
        (cache,e_1,prop,_) = Static.elabExp(cache,env, aexp, impl, st,doVect,pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl, info);
        t = Types.getPropType(prop);
        (cache,dim1) = Static.elabArrayDims(cache,env, cref, ad, impl, st, doVect ,pre, info);
        dim2 = elabArraydimType(t, ad, e_1, path, pre, cref, info,inst_dims);
        //Debug.traceln("UNTYPED");
        dim3 = List.threadMap(dim1, dim2, compatibleArraydim);
      then
        (cache,dim3);

    case (cache,env,cref,_,ad,SOME(DAE.TYPED(e,_,DAE.PROP(t,_),_)),impl,st,doVect, _,pre,info,inst_dims)
      equation
        // adrpo: do not display error when running checkModel
        //        TODO! FIXME! check if this doesn't actually get rid of useful error messages
        false = Flags.getConfigBool(Flags.CHECK_MODEL);
        (_,dim1) = Static.elabArrayDims(cache, env, cref, ad, impl, st,doVect,pre,info);
        dim2 = elabArraydimType(t, ad, e, path, pre, cref, info,inst_dims);
        failure(_ = List.threadMap(dim1, dim2, compatibleArraydim));
        e_str = ExpressionDump.printExpStr(e);
        t_str = Types.unparseType(t);
        dim_str = printDimStr(dim1);
        Error.addSourceMessage(Error.ARRAY_DIMENSION_MISMATCH, {e_str,t_str,dim_str}, info);
      then
        fail();

    // print some failures
    case (_,_,cref,_,ad,eq,_,_,_,_,_,_,_)
      equation
        // only display when the failtrace flag is on
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- InstUtil.elabArraydim failed on: \n\tcref:");
        Debug.trace(Absyn.pathString(path) + " " + Dump.printComponentRefStr(cref));
        Debug.traceln(Dump.printArraydimStr(ad) + " = " + Types.unparseOptionEqMod(eq));
      then
        fail();
  end matchcontinue;
end elabArraydim;

protected function printDimStr
"This function prints array dimensions.
  The code is not included in the report."
  input DAE.Dimensions inDimensionLst;
  output String outString;
protected
  list<String> dim_strings;
algorithm
  dim_strings := List.map(inDimensionLst, ExpressionDump.dimensionString);
  outString := stringDelimitList(dim_strings, ",");
end printDimStr;

protected function compatibleArraydim
  "Given two, possibly incomplete, array dimension size specifications, this
  function checks whether they are compatible. Being compatible means that they
  have the same number of dimensions, and for every dimension at least one of
  the lists specifies it's size. If both lists specify a dimension size, they
  have to specify the same size."
  input DAE.Dimension inDimension1;
  input DAE.Dimension inDimension2;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match(inDimension1, inDimension2)
    local
      DAE.Dimension x, y;
    case (DAE.DIM_UNKNOWN(), DAE.DIM_UNKNOWN()) then DAE.DIM_UNKNOWN();
    case (_, DAE.DIM_UNKNOWN()) then inDimension1;
    case (DAE.DIM_UNKNOWN(), _) then inDimension2;
    case (_, DAE.DIM_EXP()) then inDimension1;
    case (DAE.DIM_EXP(), _) then inDimension2;
    case (_, _)
      equation
        true = intEq(Expression.dimensionSize(inDimension1),
                     Expression.dimensionSize(inDimension2));
      then
        inDimension1;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- InstUtil.compatibleArraydim failed\n");
      then
        fail();
  end match;
end compatibleArraydim;

protected function elabArraydimType
  "Find out the dimension sizes of a type. The second argument is used to know
   how many dimensions should be extracted from the type."
  input DAE.Type inType;
  input Absyn.ArrayDim inArrayDim;
  input DAE.Exp inExp "User for error messages.";
  input Absyn.Path inPath "Class of declaration, used for error messages.";
  input Prefix.Prefix inPrefix;
  input Absyn.ComponentRef inCref;
  input SourceInfo inInfo;
  input list<list<DAE.Dimension>> inInstDims;
  output DAE.Dimensions outDimensions;
protected
  list<DAE.Dimension> flat_id;
  String ad_str, ty_str, exp_str, name_str;
algorithm
  flat_id := if Config.splitArrays() then {} else List.flatten(inInstDims);

  try
    true := Types.numberOfDimensions(inType) >= listLength(inArrayDim) + listLength(flat_id);
    outDimensions := elabArraydimType2(inType, inArrayDim, flat_id);
  else
    ad_str := Absyn.pathString(inPath) + Dump.printArraydimStr(inArrayDim);
    ty_str := Types.unparseTypeNoAttr(inType);
    exp_str := ExpressionDump.printExpStr(inExp);
    name_str := PrefixUtil.printPrefixStrIgnoreNoPre(inPrefix) +
      Absyn.printComponentRefStr(inCref);
    Error.addSourceMessageAndFail(Error.MODIFIER_DECLARATION_TYPE_MISMATCH_ERROR,
      {name_str, ad_str, exp_str, ty_str}, inInfo);
  end try;
end elabArraydimType;

protected function elabArraydimType2
  "Help function to elabArraydimType."
  input DAE.Type inType;
  input Absyn.ArrayDim inArrayDim;
  input list<DAE.Dimension> inDims;
  output DAE.Dimensions outDimensions;
algorithm
  outDimensions := matchcontinue (inType, inArrayDim, inDims)
    local
      DAE.Dimension d;
      DAE.Dimension dim;
      list<DAE.Dimension> rest_dims;
      DAE.Type t;

    case (DAE.T_ARRAY(dims = {d}, ty = t), _, dim :: rest_dims)
      algorithm
        compatibleArraydim(d, dim);
      then
        elabArraydimType2(t, inArrayDim, rest_dims);

    case (DAE.T_ARRAY(dims = {d}, ty = t), _, {})
      then d :: elabArraydimType2(t, listRest(inArrayDim), {});

    case (_, {}, {}) then {};

    case (_, (_ :: _), _) /* PR, for debugging */
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("Undefined! The type detected: ");
        Debug.traceln(Types.printTypeStr(inType));
      then
        fail();
  end matchcontinue;
end elabArraydimType2;

public function addFunctionsToDAE
"@author: adrpo
 we might need to intantiate partial functions, but we should NOT add them to the DAE!"
  input FCore.Cache inCache;
  input list<DAE.Function> funcs "fully qualified function name";
  input SCode.Partial inPartialPrefix;
  output FCore.Cache outCache;
algorithm
  outCache := match(inCache, funcs, inPartialPrefix)
    local
      FCore.Cache cache;
      SCode.Partial pPrefix;

    /*/ if not meta-modelica and we have a partial function, DO NOT ADD IT TO THE DAE!
    case (cache, funcs, pPrefix as SCode.PARTIAL())
      equation
        false = Config.acceptMetaModelicaGrammar();
        true = System.getPartialInstantiation();
        // if all the functions are complete, add them, otherwise, NO
        fLst = List.select(funcs, DAEUtil.isNotCompleteFunction);
        fLst = if_(listEmpty(fLst), funcs, {});
        cache = FCore.addDaeFunction(cache, fLst);
      then
        cache;*/

    // otherwise add it to the DAE!
    case (cache, _, _)
      equation
        cache = FCore.addDaeFunction(cache, funcs);
      then
        cache;

  end match;
end addFunctionsToDAE;

public function addNameToDerivativeMapping
  input list<DAE.Function> inElts;
  input Absyn.Path path;
  output list<DAE.Function> outElts;
algorithm
  outElts := matchcontinue(inElts,path)
  local
    DAE.Function elt;
    list<DAE.FunctionDefinition> funcs;
    DAE.Type tp;
    Absyn.Path p;
    Boolean part,isImpure;
    DAE.InlineType inlineType;
    DAE.ElementSource source;
    Option<SCode.Comment> cmt;
    list<DAE.Function> elts;
    SCode.Visibility visiblity;

    case({},_) then {};

    case(DAE.FUNCTION(p,funcs,tp,visiblity,part,isImpure,inlineType,source,cmt)::elts,_)
      equation
        elts = addNameToDerivativeMapping(elts,path);
        funcs = addNameToDerivativeMappingFunctionDefs(funcs,path);
      then DAE.FUNCTION(p,funcs,tp,visiblity,part,isImpure,inlineType,source,cmt)::elts;

    case(elt::elts,_)
      equation
        elts = addNameToDerivativeMapping(elts,path);
      then elt::elts;
  end matchcontinue;
end addNameToDerivativeMapping;

protected function addNameToDerivativeMappingFunctionDefs " help function to addNameToDerivativeMappingElts"
  input list<DAE.FunctionDefinition> inFuncs;
  input Absyn.Path path;
  output list<DAE.FunctionDefinition> outFuncs;
algorithm
  outFuncs := matchcontinue(inFuncs,path)
    local
      DAE.FunctionDefinition func;
      Absyn.Path p1,p2;
      Integer do;
      Option<Absyn.Path> dd;
      list<Absyn.Path> lowerOrderDerivatives;
      list<tuple<Integer,DAE.derivativeCond>> conds;
      list<DAE.FunctionDefinition> funcs;

    case({},_) then {};

    case(DAE.FUNCTION_DER_MAPPER(p1,p2,do,conds,dd,lowerOrderDerivatives)::funcs,_)
      equation
        funcs = addNameToDerivativeMappingFunctionDefs(funcs,path);
      then DAE.FUNCTION_DER_MAPPER(p1,p2,do,conds,dd,path::lowerOrderDerivatives)::funcs;

    case(func::funcs,_)
      equation
        funcs = addNameToDerivativeMappingFunctionDefs(funcs,path);
      then func::funcs;

  end matchcontinue;
end addNameToDerivativeMappingFunctionDefs;

public function getDeriveAnnotation "
Authot BZ
helper function for InstFunction.implicitFunctionInstantiation, returns derivative of function, if any."
  input SCode.ClassDef cd;
  input SCode.Comment cmt;
  input Absyn.Path baseFunc;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output list<DAE.FunctionDefinition> element;
algorithm
  element := matchcontinue(cd,cmt,baseFunc,inCache,inEnv,inIH,inPrefix,info)
    local
      list<SCode.Element> elemDecl;
      SCode.Annotation ann;

    case(SCode.PARTS(elementLst = elemDecl, externalDecl=SOME(SCode.EXTERNALDECL(annotation_=SOME(ann)))),_,_,_,_,_,_,_)
    then getDeriveAnnotation2(ann,elemDecl,baseFunc,inCache,inEnv,inIH,inPrefix,info);

    case(SCode.PARTS(elementLst = elemDecl),SCode.COMMENT(annotation_=SOME(ann)),_,_,_,_,_,_)
    then getDeriveAnnotation2(ann,elemDecl,baseFunc,inCache,inEnv,inIH,inPrefix,info);

    else {};

  end matchcontinue;
end getDeriveAnnotation;

protected function getDeriveAnnotation2 "
helper function for getDeriveAnnotation"
  input SCode.Annotation ann;
  input list<SCode.Element> elemDecl;
  input Absyn.Path baseFunc;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output list<DAE.FunctionDefinition> element;
algorithm
  (element) := match(ann,elemDecl,baseFunc,inCache,inEnv,inIH,inPrefix,info)
  local
    list<SCode.SubMod> smlst;
    list<SCode.Annotation> anns;

  case(SCode.ANNOTATION(SCode.MOD(subModLst = smlst)),_,_,_,_,_,_,_)
     then getDeriveAnnotation3(smlst,elemDecl,baseFunc,inCache,inEnv,inIH,inPrefix,info);

end match;
end getDeriveAnnotation2;

protected function getDeriveAnnotation3 "
Author: bjozac
  helper function to getDeriveAnnotation2"
  input list<SCode.SubMod> inSubs;
  input list<SCode.Element> elemDecl;
  input Absyn.Path baseFunc;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output list<DAE.FunctionDefinition> element;
algorithm
  element := matchcontinue inSubs
    local
      Absyn.Exp ae;
      Absyn.ComponentRef acr;
      Absyn.Path deriveFunc;
      Option<Absyn.Path> defaultDerivative;
      SCode.Mod m;
      list<SCode.SubMod> subs2;
      Integer order;
      list<tuple<Integer,DAE.derivativeCond>> conditionRefs;
      DAE.FunctionDefinition mapper;
      list<SCode.SubMod> subs;

    case {} then fail();

    case SCode.NAMEMOD("derivative",(SCode.MOD(subModLst = subs2,binding=SOME(Absyn.CREF(acr))))) :: subs
      equation
        deriveFunc = Absyn.crefToPath(acr);
        (_,deriveFunc) = Inst.makeFullyQualified(inCache,inEnv,deriveFunc);
        order = getDerivativeOrder(subs2);

        ErrorExt.setCheckpoint("getDeriveAnnotation3") "don't report errors on modifers in functions";
        conditionRefs = getDeriveCondition(subs2,elemDecl,inCache,inEnv,inIH,inPrefix,info);
        ErrorExt.rollBack("getDeriveAnnotation3");

        conditionRefs = List.sort(conditionRefs,DAEUtil.derivativeOrder);
        defaultDerivative = getDerivativeSubModsOptDefault(subs,inCache,inEnv,inPrefix);


        /*print("\n adding conditions on derivative count: " + intString(listLength(conditionRefs)) + "\n");
        dbgString = Absyn.optPathString(defaultDerivative);
        dbgString = if_(stringEq(dbgString,""),"", "**** Default Derivative: " + dbgString + "\n");
        print("**** Function derived: " + Absyn.pathString(baseFunc) + " \n");
        print("**** Deriving function: " + Absyn.pathString(deriveFunc) + "\n");
        print("**** Conditions: " + stringDelimitList(DAEDump.dumpDerivativeCond(conditionRefs),", ") + "\n");
        print("**** Order: " + intString(order) + "\n");
        print(dbgString);*/


        mapper = DAE.FUNCTION_DER_MAPPER(baseFunc,deriveFunc,order,conditionRefs,defaultDerivative,{});
      then
        {mapper};

    case _ :: subs
      then getDeriveAnnotation3(subs,elemDecl,baseFunc,inCache,inEnv,inIH,inPrefix,info);
  end matchcontinue;
end getDeriveAnnotation3;

protected function getDeriveCondition "
helper function for getDeriveAnnotation
Extracts conditions for derivative."
  input list<SCode.SubMod> inSubs;
  input list<SCode.Element> elemDecl;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output list<tuple<Integer,DAE.derivativeCond>> outconds;
algorithm
  outconds := matchcontinue(inSubs,elemDecl,inCache,inEnv,inIH,inPrefix,info)
  local
    SCode.Mod m;
    DAE.Mod elabedMod;
    DAE.SubMod sub;
    String name;
    DAE.derivativeCond cond;
    Absyn.ComponentRef acr;
    Integer varPos;
    list<SCode.SubMod> subs;
    FCore.Cache cache;

    case({},_,_,_,_,_,_) then {};

    case(SCode.NAMEMOD("noDerivative",(SCode.MOD(binding = SOME(Absyn.CREF(acr)))))::subs,_,_,_,_,_,_)
    equation
      name = Absyn.printComponentRefStr(acr);
        outconds = getDeriveCondition(subs,elemDecl,inCache,inEnv,inIH,inPrefix,info);
      varPos = setFunctionInputIndex(elemDecl,name,1);
    then
      (varPos,DAE.NO_DERIVATIVE(DAE.ICONST(99)))::outconds;

    case(SCode.NAMEMOD("zeroDerivative",(SCode.MOD(binding =  SOME(Absyn.CREF(acr)))))::subs,_,_,_,_,_,_)
    equation
      name = Absyn.printComponentRefStr(acr);
        outconds = getDeriveCondition(subs,elemDecl,inCache,inEnv,inIH,inPrefix,info);
      varPos = setFunctionInputIndex(elemDecl,name,1);
    then
      (varPos,DAE.ZERO_DERIVATIVE())::outconds;

    case(SCode.NAMEMOD("noDerivative",(m as SCode.MOD()))::subs,_,_,_,_,_,_)
    equation
      (cache,DAE.MOD(subModLst={sub})) = Mod.elabMod(inCache, inEnv, inIH, inPrefix, m, false, Mod.COMPONENT("noDerivative"), info);
      (name,cond) = extractNameAndExp(sub);
      outconds = getDeriveCondition(subs,elemDecl,cache,inEnv,inIH,inPrefix,info);
      varPos = setFunctionInputIndex(elemDecl,name,1);
    then
      (varPos,cond)::outconds;

    case(_::subs,_,_,_,_,_,_)
    then getDeriveCondition(subs,elemDecl,inCache,inEnv,inIH,inPrefix,info);
end matchcontinue;
end getDeriveCondition;

protected function setFunctionInputIndex "
Author BZ"
  input list<SCode.Element> inElemDecl;
  input String str;
  input Integer currPos;
  output Integer index;
algorithm
  index := matchcontinue(inElemDecl,str,currPos)
  local
    String str2;
    list<SCode.Element> elemDecl;

  case({},_,_)
    equation
      print(" failure in setFunctionInputIndex, didn't find any index for: " + str + "\n");
      then fail();

        /* found matching input*/
      case(SCode.COMPONENT(name=str2,attributes =SCode.ATTR(direction=Absyn.INPUT()))::_,_,_)
        equation
          true = stringEq(str2, str);
          then
            currPos;

       /* Non-matching input, increase inputarg pos*/
    case(SCode.COMPONENT(attributes =SCode.ATTR(direction=Absyn.INPUT()))::elemDecl,_,_)
      then setFunctionInputIndex(elemDecl,str,currPos+1);

       /* Other element, do not increaese inputarg pos*/
      case(_::elemDecl,_,_) then setFunctionInputIndex(elemDecl,str,currPos);
  end matchcontinue;
end setFunctionInputIndex;

protected function extractNameAndExp "
Author BZ
could be used by getDeriveCondition, depending on interpretation of spec compared to constructed libraries.
helper function for getDeriveAnnotation"
  input DAE.SubMod m;
  output String inputVar;
  output DAE.derivativeCond cond;
algorithm
  (inputVar,cond) := matchcontinue(m)
  local
    DAE.EqMod eq;
    DAE.Exp e;
  case(DAE.NAMEMOD(inputVar,mod = DAE.MOD(binding = SOME(DAE.TYPED(modifierAsExp=e)))))
    equation
      then (inputVar,DAE.NO_DERIVATIVE(e));
  case(DAE.NAMEMOD(inputVar,mod = DAE.MOD(binding = NONE())))
    equation
    then (inputVar,DAE.NO_DERIVATIVE(DAE.ICONST(1)));
  case(DAE.NAMEMOD(inputVar,mod = DAE.MOD(binding = NONE()))) // zeroderivative
  then (inputVar,DAE.ZERO_DERIVATIVE());

  else ("",DAE.ZERO_DERIVATIVE());
  end matchcontinue;
end extractNameAndExp;

protected function getDerivativeSubModsOptDefault "
helper function for getDeriveAnnotation"
  input list<SCode.SubMod> inSubs;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
output Option<Absyn.Path> defaultDerivative;
algorithm defaultDerivative := matchcontinue(inSubs,inCache,inEnv,inPrefix)
  local
    Absyn.ComponentRef acr;
    Absyn.Path p;
    Absyn.Exp ae;
    SCode.Mod m;
    list<SCode.SubMod> subs;

  case({},_,_,_) then NONE();
  case(SCode.NAMEMOD("derivative",(SCode.MOD(binding =SOME(Absyn.CREF(acr)))))::_,_,_,_)
    equation
      p = Absyn.crefToPath(acr);
      (_,p) = Inst.makeFullyQualified(inCache,inEnv, p);
    then
      SOME(p);
  case(_::subs,_,_,_) then getDerivativeSubModsOptDefault(subs,inCache,inEnv,inPrefix);
  end matchcontinue;
end getDerivativeSubModsOptDefault;

protected function getDerivativeOrder "
helper function for getDeriveAnnotation
Get current derive order"
  input list<SCode.SubMod> inSubs;
  output Integer order;
algorithm order := matchcontinue(inSubs)
  local
    Absyn.Exp ae;
    SCode.Mod m;
    list<SCode.SubMod> subs;
  case({}) then 1;
  case(SCode.NAMEMOD("order",(SCode.MOD(binding= SOME((Absyn.INTEGER(order))))))::_)
  then order;
  case(_::subs) then getDerivativeOrder(subs);
  end matchcontinue;
end getDerivativeOrder;

public function setFullyQualifiedTypename
"This function sets the FQ path given as argument in types that have optional path set.
 (The optional path points to the class the type is built from)"
  input DAE.Type inType;
  input Absyn.Path path;
  output DAE.Type resType;
algorithm
  resType := matchcontinue (inType,path)
    local
      Absyn.Path newPath;
      DAE.Type tp;

    case (tp,_)
      equation
        {} = Types.getTypeSource(tp);
      then
        tp;

    case (tp,newPath)
      equation
        tp = Types.setTypeSource(tp, Types.mkTypeSource(SOME(newPath)));
      then
        tp;
  end matchcontinue;
end setFullyQualifiedTypename;

public function isInlineFunc
  input SCode.Element inClass;
  output DAE.InlineType outInlineType;
algorithm
  outInlineType := matchcontinue(inClass)
    local
      list<SCode.SubMod> smlst;

    case SCode.CLASS(cmt=SCode.COMMENT(annotation_=SOME(SCode.ANNOTATION(SCode.MOD(subModLst = smlst)))))
      then isInlineFunc2(smlst);

    else DAE.NO_INLINE();
  end matchcontinue;
end isInlineFunc;

protected function isInlineFunc2
  input list<SCode.SubMod> inSubModList;
  output DAE.InlineType res;
algorithm
  res := match (inSubModList)
    local
      list<SCode.SubMod> cdr;
    case ({}) then DAE.NO_INLINE();

    case (SCode.NAMEMOD("Inline",SCode.MOD(binding = SOME(Absyn.BOOL(true)))) :: cdr)
      equation
        failure(DAE.AFTER_INDEX_RED_INLINE() = isInlineFunc2(cdr));
      then DAE.NORM_INLINE();

    case(SCode.NAMEMOD("LateInline",SCode.MOD(binding = SOME(Absyn.BOOL(true)))) :: _)
      then DAE.AFTER_INDEX_RED_INLINE();

    case(SCode.NAMEMOD("__MathCore_InlineAfterIndexReduction",SCode.MOD(binding = SOME(Absyn.BOOL(true)))) :: _)
      then DAE.AFTER_INDEX_RED_INLINE();

    case (SCode.NAMEMOD("__Dymola_InlineAfterIndexReduction",SCode.MOD(binding = SOME(Absyn.BOOL(true)))) :: _)
      then DAE.AFTER_INDEX_RED_INLINE();

    case (SCode.NAMEMOD("InlineAfterIndexReduction",SCode.MOD(binding = SOME(Absyn.BOOL(true)))) :: _)
      then DAE.AFTER_INDEX_RED_INLINE();

    case (SCode.NAMEMOD("__OpenModelica_EarlyInline",SCode.MOD(binding = SOME(Absyn.BOOL(true)))) :: _)
      then DAE.EARLY_INLINE();

    case(_ :: cdr) then isInlineFunc2(cdr);
  end match;
end isInlineFunc2;

public function stripFuncOutputsMod "strips the assignment modification of the component declared as output"
  input SCode.Element elem;
  output SCode.Element stripped_elem;
algorithm
  stripped_elem := matchcontinue(elem)
    local
      SCode.Ident id;
      Absyn.InnerOuter inOut;
      SCode.Final finPre;
      SCode.Replaceable repPre;
      SCode.Visibility vis;
      SCode.Redeclare redecl;
      SCode.Attributes attr;
      Absyn.TypeSpec typeSpc;
      SCode.Comment comm;
      Option<Absyn.Exp> cond;
      SourceInfo info;
      SCode.Final modFinPre;
      SCode.Each modEachPre;
      list<SCode.SubMod> modSubML;
      SCode.Element e;
      SCode.Mod modBla;
      SourceInfo mod_info;

    case (      SCode.COMPONENT(
          name = id,
          prefixes = SCode.PREFIXES(
            visibility = vis,
            redeclarePrefix = redecl,
            finalPrefix = finPre,
            innerOuter = inOut,
            replaceablePrefix = repPre),
          attributes = attr as SCode.ATTR(direction = Absyn.OUTPUT()),
          typeSpec = typeSpc,
          modifications = SCode.MOD(finalPrefix = modFinPre, eachPrefix = modEachPre, subModLst = modSubML, binding = SOME(_), info = mod_info),
          comment = comm, condition = cond, info = info))
      equation
        modBla = SCode.MOD(modFinPre,modEachPre,modSubML,NONE(),mod_info);
      then
        SCode.COMPONENT(
          id,
          SCode.PREFIXES(vis,redecl,finPre,inOut,repPre),
          attr,typeSpc,modBla,comm,cond,info);

    case (e) then (e);

  end matchcontinue;
end stripFuncOutputsMod;

public function checkExternalFunction "
  * All in-/outputs are referenced
  * There must be no algorithm section (checked earlier)
  "
  input list<DAE.Element> els;
  input DAE.ExternalDecl decl;
  input String name;
protected
  Integer i;
algorithm
  List.map2_0(els,checkExternalFunctionOutputAssigned,decl,name);
  checkFunctionInputUsed(els,SOME(decl),name);
end checkExternalFunction;

public function checkFunctionInputUsed
  input list<DAE.Element> elts;
  input Option<DAE.ExternalDecl> decl;
  input String name;
protected
  list<DAE.Element> invars,vars,algs;
algorithm
  (vars,_,_,_,algs,_,_,_,_) := DAEUtil.splitElements(elts);
  invars := List.filterOnTrue(vars,DAEUtil.isInputVar);
  invars := List.select(invars,checkInputUsedAnnotation);
  invars := checkExternalDeclInputUsed(invars,decl);
  invars := List.select1(invars,checkVarBindingsInputUsed,vars);
  (_,(_,invars)) := DAEUtil.traverseDAE2(algs,Expression.traverseSubexpressionsHelper,(checkExpInputUsed,invars));
  List.map1_0(invars,warnUnusedFunctionVar,name);
end checkFunctionInputUsed;

public function checkInputUsedAnnotation "
  True if __OpenModelica_UnusedVariable does not exist in the element.
"
  input DAE.Element inElement;
  output Boolean result;
algorithm
  result := match (inElement)
    local
      Option<SCode.Comment> cmt;
      DAE.ComponentRef cr;
    case DAE.VAR(comment = cmt)
      equation
        result = SCode.optCommentHasBooleanNamedAnnotation(cmt, "__OpenModelica_UnusedVariable");
      then not result;
    else true;
  end match;
end checkInputUsedAnnotation;

protected function warnUnusedFunctionVar
  input DAE.Element v;
  input String name;
protected
  DAE.ComponentRef cr;
  DAE.ElementSource source;
  String str;
algorithm
  DAE.VAR(componentRef=cr,source=source) := v;
  str := ComponentReference.printComponentRefStr(cr);
  Error.addSourceMessage(Error.FUNCTION_UNUSED_INPUT,{str,name},DAEUtil.getElementSourceFileInfo(source));
end warnUnusedFunctionVar;

protected function checkExternalDeclInputUsed
  input list<DAE.Element> inames;
  input Option<DAE.ExternalDecl> decl;
  output list<DAE.Element> onames;
algorithm
  onames := match (inames,decl)
    local
      list<DAE.ExtArg> args;
      DAE.ExtArg arg;
      list<DAE.Element> names;
    case (names,NONE()) then names;
    case ({},_) then {};
    case (names,SOME(DAE.EXTERNALDECL(returnArg=arg,args=args)))
      equation
        names = List.select1(names,checkExternalDeclArgs,arg::args);
      then names;
  end match;
end checkExternalDeclInputUsed;

protected function checkExpInputUsed
  input DAE.Exp inExp;
  input list<DAE.Element> inEls;
  output DAE.Exp exp;
  output list<DAE.Element> els;
algorithm
  (exp,els) := matchcontinue (inExp,inEls)
    local
      DAE.ComponentRef cr;
      Absyn.Path path;
    case (exp as DAE.CREF(componentRef=cr),els)
      equation
        els = List.select1(els,checkExpInputUsed3,cr);
      then (exp,els);
    case (exp as DAE.CALL(path=path),els)
      equation
        true = Config.acceptMetaModelicaGrammar();
        cr = ComponentReference.pathToCref(path);
        els = List.select1(els,checkExpInputUsed3,cr);
      then (exp,els);
    else (inExp,inEls);
  end matchcontinue;
end checkExpInputUsed;

protected function checkExpInputUsed3
  input DAE.Element el;
  input DAE.ComponentRef cr2;
  output Boolean noteq;
protected
  DAE.ComponentRef cr1;
algorithm
  DAE.VAR(componentRef=cr1) := el;
  noteq := not ComponentReference.crefEqualNoStringCompare(cr1,cr2);
end checkExpInputUsed3;

protected function checkVarBindingsInputUsed
  input DAE.Element v;
  input list<DAE.Element> els;
  output Boolean notfound;
algorithm
  notfound := not List.isMemberOnTrue(v,els,checkVarBindingInputUsed);
end checkVarBindingsInputUsed;

protected function checkVarBindingInputUsed
  input DAE.Element v;
  input DAE.Element el;
  output Boolean found;
algorithm
  found := match (v,el)
    local
      DAE.Exp exp;
      DAE.ComponentRef cr;
    case (DAE.VAR(),DAE.VAR(direction=DAE.INPUT())) then false;
    case (DAE.VAR(componentRef=cr),DAE.VAR(binding=SOME(exp))) then Expression.expHasCref(exp,cr);
    else false;
  end match;
end checkVarBindingInputUsed;

protected function checkExternalDeclArgs
  input DAE.Element v;
  input list<DAE.ExtArg> args;
  output Boolean notfound;
algorithm
  notfound := not List.isMemberOnTrue(v,args,extArgCrefEq);
end checkExternalDeclArgs;

protected function checkExternalFunctionOutputAssigned
"All outputs must either have a default binding or be used in the external function
declaration as there is no way to make assignments in external functions."
  input DAE.Element v;
  input DAE.ExternalDecl decl;
  input String name;
algorithm
  _ := match (v,decl,name)
    local
      DAE.ExtArg arg;
      list<DAE.ExtArg> args;
      Boolean b;
      Option<DAE.Exp> binding;
      String str;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
    case (DAE.VAR(direction=DAE.OUTPUT(),componentRef=cr,binding=binding,source=source),DAE.EXTERNALDECL(returnArg=arg,args=args),_)
      equation
        // Some weird functions pass the same output twice so we cannot check for exactly 1 occurance
        // Interfacing with LAPACK routines is fun, fun, fun :)
        if not (List.isMemberOnTrue(v,arg::args,extArgCrefEq) or isSome(binding)) then
          str = ComponentReference.printComponentRefStr(cr);
          Error.addSourceMessage(Error.EXTERNAL_NOT_SINGLE_RESULT,{str,name},DAEUtil.getElementSourceFileInfo(source));
          fail();
        end if;
      then ();
    else ();
  end match;
end checkExternalFunctionOutputAssigned;

protected function extArgCrefEq
  "See if an external argument matches a cref"
  input DAE.Element v;
  input DAE.ExtArg arg;
  output Boolean b;
algorithm
  b := match (v,arg)
    local
      DAE.ComponentRef cr1,cr2;
      DAE.Exp exp;

    case (DAE.VAR(componentRef=cr1), DAE.EXTARG(componentRef=cr2))
      equation
        // If the external argument refers to a record member, i.e. a qualified
        // cref, consider the whole record to be used.
        cr2 = ComponentReference.crefFirstCref(cr2);
      then
        ComponentReference.crefEqualNoStringCompare(cr1,cr2);

    case (DAE.VAR(direction=DAE.OUTPUT()), _) then false;

    case (DAE.VAR(componentRef=cr1), DAE.EXTARGSIZE(componentRef=cr2))
      equation
        cr2 = ComponentReference.crefFirstCref(cr2);
      then
        ComponentReference.crefEqualNoStringCompare(cr1,cr2);

    case (DAE.VAR(componentRef=cr1), DAE.EXTARGEXP(exp=exp))
      then Expression.expHasCref(exp,cr1);

    else false;
  end match;
end extArgCrefEq;

public function isExtExplicitCall
"If the external function id is present, then a function call must
  exist, i.e. explicit call was written in the external clause."
  input SCode.ExternalDecl inExternalDecl;
algorithm
  _ := match (inExternalDecl)
    local String id;
    case SCode.EXTERNALDECL(funcName = SOME(_)) then ();
  end match;
end isExtExplicitCall;

public function instExtMakeExternaldecl
"author: LS
   This function generates a default explicit function call,
  when it is omitted. If only one output variable exists,
  the implicit call is equivalent to:
       external \"C\" output_var=func(input_var1, input_var2,...)
  with the input_vars in their declaration order. If several output
  variables exists, the implicit call is equivalent to:
      external \"C\" func(var1, var2, ...)
  where each var can be input or output."
  input String inIdent;
  input list<SCode.Element> inSCodeElementLst;
  input SCode.ExternalDecl inExternalDecl;
  output SCode.ExternalDecl outExternalDecl;
algorithm
  outExternalDecl := matchcontinue (inIdent,inSCodeElementLst,inExternalDecl)
    local
      SCode.Element outvar;
      list<SCode.Element> invars,els,inoutvars;
      list<list<Absyn.Exp>> explists;
      list<Absyn.Exp> exps;
      Absyn.ComponentRef retcref;
      SCode.ExternalDecl extdecl;
      String id;
      Option<String> lang;

    /* the case with only one output var, and that cannot be
     * array, otherwise instExtMakeCrefs outvar will fail
     */
    case (id,els,SCode.EXTERNALDECL(lang = lang))
      equation
        (outvar :: {}) = List.filter(els, isOutputVar);
        invars = List.filter(els, isInputVar);
        explists = List.map(invars, instExtMakeCrefs);
        exps = List.flatten(explists);
        {Absyn.CREF(retcref)} = instExtMakeCrefs(outvar);
        extdecl = SCode.EXTERNALDECL(SOME(id),lang,SOME(retcref),exps,NONE());
      then
        extdecl;
    case (id,els,SCode.EXTERNALDECL(lang = lang))
      equation
        inoutvars = List.filter(els, isInoutVar);
        explists = List.map(inoutvars, instExtMakeCrefs);
        exps = List.flatten(explists);
        extdecl = SCode.EXTERNALDECL(SOME(id),lang,NONE(),exps,NONE());
      then
        extdecl;
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("#-- Inst.instExtMakeExternaldecl failed");
      then
        fail();
  end matchcontinue;
end instExtMakeExternaldecl;

protected function isInoutVar
"Succeds for Elements that are input or output components"
  input SCode.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local SCode.Element e;
    case e equation isOutputVar(e); then ();
    case e equation isInputVar(e); then ();
  end matchcontinue;
end isInoutVar;

protected function isOutputVar
"Succeds for element that is output component"
  input SCode.Element inElement;
algorithm
  _ := match (inElement)
    case SCode.COMPONENT(attributes = SCode.ATTR(direction = Absyn.OUTPUT())) then ();
  end match;
end isOutputVar;

protected function isInputVar
"Succeds for element that is input component"
  input SCode.Element inElement;
algorithm
  _ := match (inElement)
    case SCode.COMPONENT(attributes = SCode.ATTR(direction = Absyn.INPUT())) then ();
  end match;
end isInputVar;

protected function instExtMakeCrefs
"author: LS
  This function is used in external function declarations.
  It collects the component identifier and the dimension
  sizes and returns as a Absyn.Exp list"
  input SCode.Element inElement;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm
  outAbsynExpLst := match (inElement)
    local
      list<Absyn.Exp> sizelist,crlist;
      String id;
      SCode.Final fi;
      SCode.Replaceable re;
      SCode.Visibility pr;
      list<Absyn.Subscript> dims;
      Absyn.TypeSpec path;
      SCode.Mod mod;

    case SCode.COMPONENT(name = id, attributes = SCode.ATTR(arrayDims = dims))
      equation
        sizelist = instExtMakeCrefs2(id, dims, 1);
        crlist = (Absyn.CREF(Absyn.CREF_IDENT(id,{})) :: sizelist);
      then
        crlist;
  end match;
end instExtMakeCrefs;

protected function instExtMakeCrefs2
"Helper function to instExtMakeCrefs, collects array dimension sizes."
  input SCode.Ident inIdent;
  input Absyn.ArrayDim inArrayDim;
  input Integer inInteger;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm
  outAbsynExpLst := match (inIdent,inArrayDim,inInteger)
    local
      String id;
      Integer nextdimno,dimno;
      list<Absyn.Exp> restlist,exps;
      Absyn.Subscript dim;
      list<Absyn.Subscript> restdim;

    case (_,{},_) then {};

    case (id,(_ :: restdim),dimno)
      equation
        nextdimno = dimno + 1;
        restlist = instExtMakeCrefs2(id, restdim, nextdimno);
        exps = (Absyn.CALL(Absyn.CREF_IDENT("size",{}),
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(id,{})),
          Absyn.INTEGER(dimno)},{})) :: restlist);
      then
        exps;

  end match;
end instExtMakeCrefs2;

public function instExtGetFname
"Returns the function name of the externally defined function."
  input SCode.ExternalDecl inExternalDecl;
  input String inIdent;
  output String outIdent;
algorithm
  outIdent := match (inExternalDecl,inIdent)
    local String id,fid;
    case (SCode.EXTERNALDECL(funcName = SOME(id)),_) then id;
    case (SCode.EXTERNALDECL(funcName = NONE()),fid) then fid;
  end match;
end instExtGetFname;

public function instExtGetAnnotation
"author: PA
  Return the annotation associated with an external function declaration.
  If no annotation is found, check the classpart annotations."
  input SCode.ExternalDecl inExternalDecl;
  output Option<SCode.Annotation> outAnnotation;
algorithm
  outAnnotation := match (inExternalDecl)
    local Option<SCode.Annotation> ann;
    case (SCode.EXTERNALDECL(annotation_ = ann)) then ann;
  end match;
end instExtGetAnnotation;

public function instExtGetLang
"Return the implementation language of the external function declaration.
  Defaults to \"C\" if no language specified."
  input SCode.ExternalDecl inExternalDecl;
  output String outString;
algorithm
  outString := match (inExternalDecl)
    local String lang;
    case SCode.EXTERNALDECL(lang = SOME(lang)) then lang;
    case SCode.EXTERNALDECL(lang = NONE()) then "C";
  end match;
end instExtGetLang;

protected function elabExpListExt
"Special elabExp for explicit external calls.
  This special function calls elabExpExt which handles size builtin
  calls specially, and uses the ordinary Static.elab_exp for other
  expressions."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output list<DAE.Properties> outTypesPropertiesLst;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExpExpLst,outTypesPropertiesLst,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inAbsynExpLst,inBoolean,inST,inPrefix,info)
    local
      Boolean impl;
      Option<GlobalScript.SymbolTable> st,st_1,st_2;
      DAE.Exp exp;
      DAE.Properties p;
      list<DAE.Exp> exps;
      list<DAE.Properties> props;
      FCore.Graph env;
      Absyn.Exp e;
      list<Absyn.Exp> rest;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.ComponentRef cr;
    case (cache,_,{},_,st,_,_) then (cache,{},{},st);
    case (cache,env,(e :: rest),impl,st,pre,_)
      equation
        (cache,exp,p,st_1) = elabExpExt(cache,env, e, impl, st,pre,info);
        (cache,exps,props,st_2) = elabExpListExt(cache,env, rest, impl, st_1,pre,info);
      then
        (cache,(exp :: exps),(p :: props),st_2);
  end match;
end elabExpListExt;

protected function elabExpExt
"author: LS
  special elabExp for explicit external calls.
  This special function calls elabExpExt which handles size builtin calls
  specially, and uses the ordinary Static.elab_exp for other expressions."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inST,inPrefix,info)
    local
      DAE.Exp dimp,arraycrefe,exp,e;
      DAE.Type dimty;
      DAE.Properties arraycrprop,prop;
      FCore.Graph env;
      Absyn.Exp call,arraycr,dim;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      FCore.Cache cache;
      Absyn.Exp absynExp;
      Prefix.Prefix pre;

    // special case for  size
    case (cache,env,(Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "size"),
          functionArgs = Absyn.FUNCTIONARGS(args = {arraycr,dim}))),impl,st,pre,_)
      equation
        (cache,dimp,prop as DAE.PROP(_,_),_) = Static.elabExp(cache, env, dim, impl,NONE(),false,pre,info);
        (cache, dimp, prop) = Ceval.cevalIfConstant(cache, env, dimp, prop, impl, info);
        (cache,arraycrefe,arraycrprop,_) = Static.elabExp(cache, env, arraycr, impl,NONE(),false,pre,info);
        (cache, arraycrefe, arraycrprop) = Ceval.cevalIfConstant(cache, env, arraycrefe, arraycrprop, impl, info);
        exp = DAE.SIZE(arraycrefe,SOME(dimp));
      then
        (cache,exp,DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_VAR()),st);
    // For all other expressions, use normal elaboration
    case (cache,env,absynExp,impl,st,pre,_)
      equation
        (cache,e,prop,st) = Static.elabExp(cache, env, absynExp, impl, st,false,pre,info);
        (cache, e, prop) = Ceval.cevalIfConstant(cache, env, e, prop, impl, info);
      then
        (cache,e,prop,st);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("-Inst.elabExpExt failed");
      then
        fail();
  end matchcontinue;
end elabExpExt;

public function instExtGetFargs
"author: LS
  instantiates function arguments, i.e. actual parameters, in external declaration."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.ExternalDecl inExternalDecl;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<DAE.ExtArg> outDAEExtArgLst;
algorithm
  (outCache,outDAEExtArgLst) :=
  matchcontinue (inCache,inEnv,inExternalDecl,inBoolean,inPrefix,info)
    local
      list<DAE.Exp> exps;
      list<DAE.Properties> props;
      list<DAE.ExtArg> extargs;
      FCore.Graph env;
      Option<String> id,lang;
      Option<Absyn.ComponentRef> retcr;
      list<Absyn.Exp> absexps;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;
    case (cache,env,SCode.EXTERNALDECL(lang = lang,args = absexps),impl,pre,_)
      equation
        (cache,exps,props,_) = elabExpListExt(cache,env, absexps, impl,NONE(),pre,info);
        (cache,extargs) = instExtGetFargs2(cache, env, absexps, exps, props, lang, info);
      then
        (cache,extargs);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- InstUtil.instExtGetFargs failed");
      then
        fail();
  end matchcontinue;
end instExtGetFargs;

protected function instExtGetFargs2
"author: LS
  Helper function to instExtGetFargs"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> absynExps;
  input list<DAE.Exp> inExpExpLst;
  input list<DAE.Properties> inTypesPropertiesLst;
  input Option<String> lang;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<DAE.ExtArg> outDAEExtArgLst;
algorithm
  (outCache,outDAEExtArgLst) := match (inCache,inEnv,absynExps,inExpExpLst,inTypesPropertiesLst,lang,info)
    local
      list<DAE.ExtArg> extargs;
      DAE.ExtArg extarg;
      FCore.Graph env;
      DAE.Exp e;
      list<DAE.Exp> exps;
      DAE.Properties p;
      list<DAE.Properties> props;
      FCore.Cache cache;
      Absyn.Exp ae;
      list<Absyn.Exp> aes;
    case (cache,_,_,{},_,_,_) then (cache,{});
    case (cache,env,ae :: aes, e :: exps,p :: props,_,_)
      equation
        (cache,SOME(extarg)) = instExtGetFargsSingle(cache, env, ae, e, p, lang, info);
        (cache,extargs) = instExtGetFargs2(cache, env, aes, exps, props, lang, info);
      then
        (cache,extarg :: extargs);
  end match;
end instExtGetFargs2;

protected function instExtGetFargsSingle
"author: LS
  Helper function to instExtGetFargs2, does the work for one argument."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp absynExp;
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input Option<String> lang;
  input SourceInfo info;
  output FCore.Cache outCache;
  output Option<DAE.ExtArg> outExtArg;
algorithm
  (outCache,outExtArg) := matchcontinue (inCache,inEnv,absynExp,inExp,inProperties,lang,info)
    local
      DAE.Attributes attr, fattr;
      DAE.Type ty,varty;
      DAE.Binding bnd;
      FCore.Graph env;
      DAE.ComponentRef cref, fcr;
      DAE.Type crty;
      DAE.Const cnst;
      String crefstr,scope;
      DAE.Exp dim,exp;
      DAE.Properties prop;
      FCore.Cache cache;
      SCode.Variability variability;
      Values.Value val;
      String str;

    case (_, _, _, DAE.CREF(componentRef = cref as DAE.CREF_QUAL()),
        DAE.PROP(constFlag = DAE.C_VAR()), _, _)
      equation
        (cache, attr, ty,_, _, _, _, _, _) = Lookup.lookupVarLocal(inCache, inEnv, cref);
        // For qualified crefs, copy input/output from the first part of the
        // cref. This is done so that the correct code can be generated when
        // using qualified crefs in external function definitions.
        fcr = ComponentReference.crefFirstCref(cref);
        (cache, fattr, _, _, _, _, _, _, _) = Lookup.lookupVarLocal(cache, inEnv, fcr);
        attr = DAEUtil.setAttrDirection(attr, DAEUtil.getAttrDirection(fattr));
      then
        (cache, SOME(DAE.EXTARG(cref, attr, ty)));

    case (_, _, _, DAE.CREF(componentRef = cref as DAE.CREF_IDENT()),
        DAE.PROP(constFlag = DAE.C_VAR()), _, _)
      equation
        (cache, attr, ty,_, _, _, _, _, _) = Lookup.lookupVarLocal(inCache, inEnv, cref);
      then
        (cache,SOME(DAE.EXTARG(cref, attr, ty)));

    case (cache,env,_,DAE.CREF(componentRef = cref),DAE.PROP(),_,_)
      equation
        failure((_,_,_,_,_,_,_,_,_) = Lookup.lookupVarLocal(cache,env,cref));
        crefstr = ComponentReference.printComponentRefStr(cref);
        scope = FGraph.printGraphPathStr(env);
        Error.addMessage(Error.LOOKUP_VARIABLE_ERROR, {crefstr,scope});
      then
        (cache, NONE());

    case (cache,env,_,DAE.SIZE(exp = DAE.CREF(componentRef = cref),sz = SOME(dim)),DAE.PROP(),_,_)
      equation
        (cache,attr,varty,_,_,_,_,_,_) = Lookup.lookupVarLocal(cache,env, cref);
      then
        (cache,SOME(DAE.EXTARGSIZE(cref,attr,varty,dim)));

    // adrpo: these can be non-local if they are constants or parameters!
    case (cache,env,_,_,DAE.PROP(type_ = ty,constFlag = DAE.C_CONST()),_,_)
      equation
        (cache, exp,_) = Ceval.cevalIfConstant(cache, env, inExp, inProperties, false, info);
        true = Expression.isScalarConst(exp);
      then
        (cache,SOME(DAE.EXTARGEXP(exp, ty)));

    case (cache,_,_,_,DAE.PROP(type_ = ty),SOME("builtin"),_)
      then (cache,SOME(DAE.EXTARGEXP(inExp, ty)));

    case (cache,_,_,DAE.CALL(attr = DAE.CALL_ATTR(builtin = true)),DAE.PROP(type_ = ty),_,_)
      then (cache,SOME(DAE.EXTARGEXP(inExp, ty)));

    case (cache,_,Absyn.CREF(_),_,DAE.PROP(type_ = ty),_,_)
      then (cache,SOME(DAE.EXTARGEXP(inExp, ty)));

    case (cache,_,_,exp,DAE.PROP(),_,_)
      equation
        str = ExpressionDump.printExpStr(exp);
        Error.addSourceMessage(Error.EXTERNAL_ARG_WRONG_EXP,{str},info);
      then
        (cache, NONE());

  end matchcontinue;
end instExtGetFargsSingle;

public function instExtGetRettype
"author: LS
  Instantiates the return type of an external declaration."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.ExternalDecl inExternalDecl;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.ExtArg outExtArg;
algorithm
  (outCache,outExtArg) := matchcontinue (inCache,inEnv,inExternalDecl,inBoolean,inPrefix,info)
    local
      DAE.Exp exp;
      DAE.Properties prop;
      DAE.ExtArg extarg;
      FCore.Graph env;
      Option<String> n,lang;
      Absyn.ComponentRef cref;
      list<Absyn.Exp> args;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Attributes attr;

    case (cache,_,SCode.EXTERNALDECL(output_ = NONE()),_,_,_) then (cache,DAE.NOEXTARG());  /* impl */

    case (cache,env,SCode.EXTERNALDECL(lang = lang,output_ = SOME(cref)),impl,pre,_)
      equation
        (cache,SOME((exp,prop,_))) = Static.elabCref(cache,env,cref,impl,false /* Do NOT vectorize arrays; we require a CREF */,pre,info);
        (cache,SOME(extarg)) = instExtGetFargsSingle(cache,env,Absyn.CREF(cref),exp,prop,lang,info);
        assertExtArgOutputIsCrefVariable(lang,extarg,Types.getPropType(prop),Types.propAllConst(prop),info);
      then
        (cache,extarg);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- InstUtil.instExtRettype failed");
      then
        fail();
  end matchcontinue;
end instExtGetRettype;

protected function assertExtArgOutputIsCrefVariable
  input Option<String> lang;
  input DAE.ExtArg arg;
  input DAE.Type ty;
  input DAE.Const c;
  input SourceInfo info;
algorithm
  _ := match (lang,arg,ty,c,info)
    local
      String str;
    case (SOME("builtin"),_,_,_,_) then ();
    case (_,_,DAE.T_ARRAY(),_,_)
      equation
        str = Types.unparseType(ty);
        Error.addSourceMessage(Error.EXTERNAL_FUNCTION_RESULT_ARRAY_TYPE,{str},info);
      then fail();
    case (_,DAE.EXTARG(),_,DAE.C_VAR(),_) then ();
    case (_,_,_,DAE.C_VAR(),_)
      equation
        str = DAEDump.dumpExtArgStr(arg);
        Error.addSourceMessage(Error.EXTERNAL_FUNCTION_RESULT_NOT_CREF,{str},info);
      then fail();
    else
      equation
        Error.addSourceMessage(Error.EXTERNAL_FUNCTION_RESULT_NOT_VAR,{},info);
      then fail();
  end match;
end assertExtArgOutputIsCrefVariable;

public function makeDaeProt
"Creates a DAE.VarVisibility from a SCode.Visibility"
 input SCode.Visibility visibility;
 output DAE.VarVisibility res;
algorithm
  res := match(visibility)
    case (SCode.PROTECTED()) then DAE.PROTECTED();
    case (SCode.PUBLIC()) then DAE.PUBLIC();
  end match;
end makeDaeProt;

public function makeDaeVariability
  input SCode.Variability inVariability;
  output DAE.VarKind outVariability;
algorithm
  outVariability := match(inVariability)
    case SCode.VAR() then DAE.VARIABLE();
    case SCode.PARAM() then DAE.PARAM();
    case SCode.CONST() then DAE.CONST();
    case SCode.DISCRETE() then DAE.DISCRETE();
  end match;
end makeDaeVariability;

public function makeDaeDirection
  input Absyn.Direction inDirection;
  output DAE.VarDirection outDirection;
algorithm
  outDirection := match(inDirection)
    case Absyn.INPUT() then DAE.INPUT();
    case Absyn.OUTPUT() then DAE.OUTPUT();
    case Absyn.BIDIR() then DAE.BIDIR();
  end match;
end makeDaeDirection;

public function mktype
"From a class typename, its inference state, and a list of subcomponents,
  this function returns DAE.Type.  If the class inference state
  indicates that the type should be a built-in type, one of the
  built-in type constructors is used.  Otherwise, a T_COMPLEX is
  built."
  input Absyn.Path inPath;
  input ClassInf.State inState;
  input list<DAE.Var> inTypesVarLst;
  input Option<DAE.Type> inTypesTypeOption;
  input DAE.EqualityConstraint inEqualityConstraint;
  input SCode.Element inClass;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inPath,inState,inTypesVarLst,inTypesTypeOption,inEqualityConstraint,inClass)
    local
      Option<Absyn.Path> somep;
      Absyn.Path p;
      list<DAE.Var> v,vl,l;
      DAE.Type bc2,functype,enumtype;
      ClassInf.State st;
      DAE.Type bc;
      SCode.Element cl;
      DAE.Type arrayType;
      DAE.Type resType;
      ClassInf.State classState;
      DAE.EqualityConstraint equalityConstraint;
      DAE.FunctionAttributes funcattr;
      DAE.TypeSource ts;
      String pstr;
      SourceInfo info;

    case (p,ClassInf.TYPE_INTEGER(),v,_,_,_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_INTEGER(v, ts);

    case (p,ClassInf.TYPE_REAL(),v,_,_,_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_REAL(v, ts);

    case (p,ClassInf.TYPE_STRING(),v,_,_,_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_STRING(v, ts);

    case (p,ClassInf.TYPE_BOOL(),v,_,_,_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_BOOL(v, ts);

    // BTH
    case (p,ClassInf.TYPE_CLOCK(),v,_,_,_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_CLOCK(v, ts);

    case (p,ClassInf.TYPE_ENUM(),_,_,_,_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_ENUMERATION(NONE(), p, {}, {}, {}, ts);

    // Insert function type construction here after checking input/output arguments? see Types.mo T_FUNCTION
    case (p,(ClassInf.FUNCTION()),vl,_,_,cl)
      equation
        funcattr = getFunctionAttributes(cl,vl);
        functype = Types.makeFunctionType(p, vl, funcattr);
      then
        functype;

    case (_, ClassInf.ENUMERATION(path = p), _, SOME(enumtype), _, _)
      equation
        enumtype = Types.makeEnumerationType(p, enumtype);
      then
        enumtype;

    // Array of type extending from base type, adrpo: WITH NO EQUALITY CONSTRAINT, otherwise we loose it!
    case (_, ClassInf.TYPE(), _, SOME(DAE.T_ARRAY(ty = arrayType)), NONE(), _)
      equation
        classState = arrayTTypeToClassInfState(arrayType);
        resType = mktype(inPath, classState, inTypesVarLst, inTypesTypeOption, inEqualityConstraint, inClass);
      then
        resType;

    // Array of type extending from base type, adrpo: WITH EQUALITY CONSTRAINT, build a T_SUBTYPE_BASIC
    case (p, ClassInf.TYPE(), _, SOME(DAE.T_ARRAY(ty = arrayType)), SOME(_), _)
      equation
        classState = arrayTTypeToClassInfState(arrayType);
        resType = mktype(inPath, classState, inTypesVarLst, inTypesTypeOption, inEqualityConstraint, inClass);
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
        resType = DAE.T_SUBTYPE_BASIC(inState,{},resType,inEqualityConstraint,ts);
      then
        resType;

    /* MetaModelica extension */
    case (_,ClassInf.META_TUPLE(_),_,SOME(bc2),_,_) then bc2;
    case (_,ClassInf.META_OPTION(_),_,SOME(bc2),_,_) then bc2;
    case (_,ClassInf.META_LIST(_),_,SOME(bc2),_,_) then bc2;
    case (_,ClassInf.META_POLYMORPHIC(_),_,SOME(bc2),_,_) then bc2;
    case (_,ClassInf.META_ARRAY(_),_,SOME(bc2),_,_) then bc2;
    case (_,ClassInf.META_UNIONTYPE(_),_,SOME(bc2),_,_) then bc2;
    case (p,ClassInf.META_UNIONTYPE(_),_,_,_,_)
      equation
        pstr = Absyn.pathString(p);
        info = SCode.elementInfo(inClass);
        Error.addSourceMessage(Error.META_UNIONTYPE_ALIAS_MODS, {pstr}, info);
      then fail();
    /*------------------------*/

    // not extending
    case (p,st,l,NONE(),equalityConstraint,_)
      equation
        failure(ClassInf.META_UNIONTYPE(_) = st);
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_COMPLEX(st,l,equalityConstraint,ts);

    // extending
    case (p,st,l,SOME(bc),equalityConstraint,_)
      equation
        failure(ClassInf.META_UNIONTYPE(_) = st);
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_SUBTYPE_BASIC(st,l,bc,equalityConstraint,ts);
  end matchcontinue;
end mktype;

protected function arrayTTypeToClassInfState
  input DAE.Type arrayType;
  output ClassInf.State classInfState;
algorithm
  classInfState := match(arrayType)
    local
      DAE.Type t;
      ClassInf.State cs;

    case (DAE.T_INTEGER()) then ClassInf.TYPE_INTEGER(Absyn.IDENT(""));
    case (DAE.T_REAL()) then ClassInf.TYPE_REAL(Absyn.IDENT(""));
    case (DAE.T_STRING()) then ClassInf.TYPE_STRING(Absyn.IDENT(""));
    case (DAE.T_BOOL()) then ClassInf.TYPE_BOOL(Absyn.IDENT(""));
    // BTH FIXME Dont understand for what this function is good to. Just adding clock anyway
    case (DAE.T_CLOCK()) then ClassInf.TYPE_CLOCK(Absyn.IDENT(""));
    case (DAE.T_ARRAY(ty = t))
      equation
        cs = arrayTTypeToClassInfState(t);
      then cs;
  end match;
end arrayTTypeToClassInfState;

public function mktypeWithArrays
"author: PA
  This function is similar to mktype with the exception
  that it will create array types based on the last argument,
  which indicates wheter the class extends from a basictype.
  It is used only in the inst_class_basictype function."
  input Absyn.Path inPath;
  input ClassInf.State inState;
  input list<DAE.Var> inTypesVarLst;
  input Option<DAE.Type> inTypesTypeOption;
  input SCode.Element inClass;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inPath,inState,inTypesVarLst,inTypesTypeOption,inClass)
    local
      Absyn.Path p;
      ClassInf.State ci,st;
      list<DAE.Var> vs,v,vl,l;
      DAE.Type tp,functype,enumtype;
      Option<Absyn.Path> somep;
      SCode.Element cl;
      DAE.Type bc;
      DAE.FunctionAttributes funcattr;
      DAE.TypeSource ts;

    case (_,ci,_,SOME(tp),_)
      equation
        true = Types.isArray(tp);
        failure(ClassInf.isConnector(ci));
      then
        tp;

    case (p,ClassInf.TYPE_INTEGER(),v,_,_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_INTEGER(v, ts);

    case (p,ClassInf.TYPE_REAL(),v,_,_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_REAL(v, ts);

    case (p,ClassInf.TYPE_STRING(),v,_,_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_STRING(v, ts);

    case (p,ClassInf.TYPE_BOOL(),v,_,_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_BOOL(v, ts);

    // BTH
    case (p,ClassInf.TYPE_CLOCK(),v,_,_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_CLOCK(v, ts);

    case (p,ClassInf.TYPE_ENUM(),_,_,_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_ENUMERATION(NONE(), p,{},{},{}, ts);

    // Insert function type construction here after checking input/output arguments? see Types.mo T_FUNCTION
    case (p,(ClassInf.FUNCTION()),vl,_,cl)
      equation
        funcattr = getFunctionAttributes(cl,vl);
        functype = Types.makeFunctionType(p, vl, funcattr);
      then
        functype;

    case (p, ClassInf.ENUMERATION(), _, SOME(enumtype), _)
      equation
        enumtype = Types.makeEnumerationType(p, enumtype);
      then
        enumtype;

    // not extending basic type!
    case (p,st,l,NONE(),_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_COMPLEX(st,l,NONE(),ts); // adrpo: TODO! check equalityConstraint!

    case (p,st,l,SOME(bc),_)
      equation
        somep = getOptPath(p);
        ts = Types.mkTypeSource(somep);
      then
        DAE.T_SUBTYPE_BASIC(st,l,bc,NONE(),ts);

    else
      equation
        print("InstUtil.mktypeWithArrays failed\n");
      then fail();

  end matchcontinue;
end mktypeWithArrays;

protected function getOptPath
"Helper function to mktype
  Transforms a Path into a Path option."
  input Absyn.Path inPath;
  output Option<Absyn.Path> outAbsynPathOption;
algorithm
  outAbsynPathOption := matchcontinue (inPath)
    local Absyn.Path p;
    case Absyn.IDENT(name = "") then NONE();
    case p then SOME(p);
  end matchcontinue;
end getOptPath;

protected function checkProt
"This function is used to check that a
  protected element is not modified."
  input SCode.Visibility inVisibility;
  input DAE.Mod inMod;
  input DAE.ComponentRef inComponentRef;
  input SourceInfo info;
algorithm
  _ := matchcontinue (inVisibility,inMod,inComponentRef,info)
    local
      DAE.ComponentRef cref;
      String str1, str2;
    case (SCode.PUBLIC(),_,_,_) then ();
    case (_,DAE.NOMOD(),_,_) then ();
    case (_,DAE.MOD(_, _, {}, NONE()),_,_) then ();
    case (SCode.PROTECTED(),_,cref,_)
      equation
        str1 = ComponentReference.printComponentRefStr(cref);
        str2 = Mod.prettyPrintMod(inMod, 0);
        Error.addSourceMessage(Error.MODIFY_PROTECTED, {str1, str2}, info);
      then
        ();
  end matchcontinue;
end checkProt;

public function getStateSelectFromExpOption
"author: LP
  Retrieves the stateSelect value, as defined in DAE,  from an Expression option."
  input Option<DAE.Exp> inExpExpOption;
  output Option<DAE.StateSelect> outDAEStateSelectOption;
algorithm
  outDAEStateSelectOption:=
  matchcontinue (inExpExpOption)
    case (SOME(DAE.ENUM_LITERAL(name = Absyn.QUALIFIED("StateSelect", path = Absyn.IDENT("never"))))) then SOME(DAE.NEVER());
    case (SOME(DAE.ENUM_LITERAL(name = Absyn.QUALIFIED("StateSelect", path = Absyn.IDENT("avoid"))))) then SOME(DAE.AVOID());
    case (SOME(DAE.ENUM_LITERAL(name = Absyn.QUALIFIED("StateSelect", path = Absyn.IDENT("default"))))) then SOME(DAE.DEFAULT());
    case (SOME(DAE.ENUM_LITERAL(name = Absyn.QUALIFIED("StateSelect", path = Absyn.IDENT("prefer"))))) then SOME(DAE.PREFER());
    case (SOME(DAE.ENUM_LITERAL(name = Absyn.QUALIFIED("StateSelect", path = Absyn.IDENT("always"))))) then SOME(DAE.ALWAYS());
    case (NONE()) then NONE();
    else NONE();
  end matchcontinue;
end getStateSelectFromExpOption;

public function isSubModNamed
  "Returns true if the given submod is a namemod with the same name as the given
  name, otherwise false."
  input String inName;
  input DAE.SubMod inSubMod;
  output Boolean isNamed;
algorithm
  isNamed := matchcontinue(inName, inSubMod)
    local
      String submod_name;

    case (_, DAE.NAMEMOD(ident = submod_name))
      then stringEqual(inName, submod_name);

    else false;
  end matchcontinue;
end isSubModNamed;

public function liftRecordBinding
  "If the type is an array type this function creates an array of the given
  record, otherwise it just returns the input arguments."
  input DAE.Type inType;
  input DAE.Exp inExp;
  input Values.Value inValue;
  output DAE.Exp outExp;
  output Values.Value outValue;
algorithm
  (outExp, outValue) := matchcontinue(inType, inExp, inValue)
    local
      DAE.Dimension dim;
      DAE.Type ty;
      DAE.Exp exp;
      Values.Value val;
      DAE.Type ety;
      Integer int_dim;
      list<DAE.Exp> expl;
      list<Values.Value> vals;

    case (DAE.T_ARRAY(dims = {dim}, ty = ty), _, _)
      equation
        int_dim = Expression.dimensionSize(dim);
        (exp, val) = liftRecordBinding(ty, inExp, inValue);
        ety = Types.simplifyType(inType);
        expl = List.fill(exp, int_dim);
        vals = List.fill(val, int_dim);
        exp = DAE.ARRAY(ety, true, expl);
        val = Values.ARRAY(vals, {int_dim});
      then
        (exp, val);

    else
      equation
        false = Types.isArray(inType);
      then
        (inExp, inValue);
  end matchcontinue;
end liftRecordBinding;

public function isTopCall
"author: PA
  The topmost instantiation call is treated specially with for instance unconnected connectors.
  This function returns true if the CallingScope indicates the top call."
  input InstTypes.CallingScope inCallingScope;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inCallingScope)
    case InstTypes.TOP_CALL() then true;
    else false;
  end match;
end isTopCall;

public function extractCurrentName
" Extracts SCode.Element name."
  input SCode.Element sele;
  output String ostring;
  output SourceInfo oinfo;
algorithm
  (ostring ,oinfo) := match(sele)
    local
      Absyn.Path path;
      String name,ret;
      Absyn.Import imp;
      SourceInfo info;

    case(SCode.CLASS(name = name, info = info)) then (name, info);
    case(SCode.COMPONENT(name = name, info=info)) then (name, info);
    case(SCode.EXTENDS(baseClassPath=path, info = info))
      equation
        ret = Absyn.pathString(path);
      then
        (ret, info);
    case(SCode.IMPORT(imp = imp, info = info))
      equation
        name = Absyn.printImportString(imp);
      then
        (name, info);
  end match;
end extractCurrentName;

public function splitConnectEquationsExpandable
"@author: adrpo
  Reorder the connect equations to have non-expandable connect first:
    connect(non_expandable, non_expandable);
    connect(non_expandable, expandable);
    connect(expandable, non_expandable);
    connect(expandable, expandable);"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPre;
  input list<SCode.Equation> inEquations;
  input Boolean impl;
  input list<SCode.Equation> inAccumulatorNonExpandable;
  input list<SCode.Equation> inAccumulatorExpandable;
  output FCore.Cache outCache;
  output list<SCode.Equation> outEquations;
  output list<SCode.Equation> outExpandableEquations;
algorithm
  (outCache,outEquations,outExpandableEquations) := matchcontinue(inCache, inEnv, inIH, inPre, inEquations, impl, inAccumulatorNonExpandable, inAccumulatorExpandable)
    local
      list<SCode.Equation>  rest, eEq, nEq;
      SCode.Equation eq;
      Absyn.ComponentRef crefLeft, crefRight;
      FCore.Cache cache;
      FCore.Graph env;
      SourceInfo info;
      DAE.Type ty1,ty2;
      DAE.ComponentRef c1_1,c2_1;

    // if we have no expandable connectors, return the same
    case (cache, _, _, _, _::_, _, _, _)
      equation
        false = System.getHasExpandableConnectors();
      then
        (cache, inEquations, {});

    // handle empty case
    case (cache, _, _, _, {}, _, eEq, nEq) then (cache, listReverse(eEq), listReverse(nEq));

    // connect, both expandable
    case (cache, env, _, _, (eq as SCode.EQUATION(SCode.EQ_CONNECT(crefLeft, crefRight, _, info)))::rest, _, eEq, nEq)
      equation
        (cache,SOME((DAE.CREF(),DAE.PROP(ty1,_),_))) = Static.elabCref(cache, env, crefLeft, impl, false, inPre, info);
        (cache,SOME((DAE.CREF(),DAE.PROP(ty2,_),_))) = Static.elabCref(cache, env, crefRight, impl, false, inPre, info);

        // type of left var is an expandable connector!
        true = InstSection.isExpandableConnectorType(ty1);
        // type of right left var is an expandable connector!
        true = InstSection.isExpandableConnectorType(ty2);
        (cache, eEq, nEq) = splitConnectEquationsExpandable(cache, env, inIH, inPre, rest, impl, eEq, eq::nEq);
      then
        (cache, eEq, nEq);

    // anything else, put at the begining (keep the order)
    case (cache, _, _, _, eq::rest, _, eEq, nEq)
      equation
        (cache, eEq, nEq) = splitConnectEquationsExpandable(cache, inEnv, inIH, inPre, rest, impl, eq::eEq, nEq);
      then
        (cache, eEq, nEq);
  end matchcontinue;
end splitConnectEquationsExpandable;

public function sortInnerFirstTplLstElementMod
"@author: adrpo
  This function will move all the *inner*
  elements first in the given list of elements"
  input list<tuple<SCode.Element, DAE.Mod>> inTplLstElementMod;
  output list<tuple<SCode.Element, DAE.Mod>> outTplLstElementMod;
algorithm
  outTplLstElementMod := matchcontinue(inTplLstElementMod)
    local
      list<tuple<SCode.Element, DAE.Mod>> innerElts, innerouterElts, otherElts, sorted, innerModelicaServices, innerModelica, innerOthers;

    // no sorting if we don't have any inner/outer in the model
    case _
      equation
        false = System.getHasInnerOuterDefinitions();
      then
        inTplLstElementMod;

    // do sorting only if we have inner-outer
    case _
      equation
        // split into inner, inner outer and other elements
        (innerElts, innerouterElts, otherElts) = splitInnerAndOtherTplLstElementMod(inTplLstElementMod);
        // sort the inners to put Modelica types first!
        (innerModelicaServices, innerModelica, innerOthers) = splitInners(innerElts, {}, {}, {});

        sorted = listAppend(innerModelicaServices, innerModelica);
        sorted = listAppend(sorted, innerOthers);
        // put the inner elements first
        sorted = listAppend(sorted, innerouterElts);
        // put the innerouter elements second
        sorted = listAppend(sorted, otherElts);
      then
        sorted;
  end matchcontinue;
end sortInnerFirstTplLstElementMod;

protected function splitInners
"@author: adrpo
  This function will sort inner into 3 lists:
  *inner* ModelicaServices.*
  *inner* Modelica.*
  *inner* Other.*"
  input list<tuple<SCode.Element, DAE.Mod>> inTplLstElementMod;
  input list<tuple<SCode.Element, DAE.Mod>> inAcc1;
  input list<tuple<SCode.Element, DAE.Mod>> inAcc2;
  input list<tuple<SCode.Element, DAE.Mod>> inAcc3;
  output list<tuple<SCode.Element, DAE.Mod>> outModelicaServices;
  output list<tuple<SCode.Element, DAE.Mod>> outModelica;
  output list<tuple<SCode.Element, DAE.Mod>> outOthers;
algorithm
  (outModelicaServices, outModelica, outOthers) :=
  matchcontinue(inTplLstElementMod, inAcc1, inAcc2, inAcc3)
    local
      list<tuple<SCode.Element, DAE.Mod>> rest, acc1, acc2, acc3;
      SCode.Element e;
      DAE.Mod m;
      tuple<SCode.Element, DAE.Mod> em;
      Absyn.Path p;

    case ({}, _, _, _)
      then (listReverse(inAcc1), listReverse(inAcc2), listReverse(inAcc3));

    case (em::rest, _, _, _)
      equation
        e = Util.tuple21(em);
        Absyn.TPATH(p, _) = SCode.getComponentTypeSpec(e);
        true = stringEq("ModelicaServices", Absyn.pathFirstIdent(p));
        (acc1, acc2, acc3) = splitInners(rest, em::inAcc1, inAcc2, inAcc3);
      then
        (acc1, acc2, acc3);

    case (em::rest, _, _, _)
      equation
        e = Util.tuple21(em);
        Absyn.TPATH(p, _) = SCode.getComponentTypeSpec(e);
        true = stringEq("Modelica", Absyn.pathFirstIdent(p));
        (acc1, acc2, acc3) = splitInners(rest, inAcc1, em::inAcc2, inAcc3);
      then
        (acc1, acc2, acc3);

    case ((em as (_, _))::rest, _, _, _)
      equation
        (acc1, acc2, acc3) = splitInners(rest, inAcc1, inAcc2, em::inAcc3);
      then
        (acc1, acc2, acc3);
  end matchcontinue;
end splitInners;

public function splitInnerAndOtherTplLstElementMod
"@author: adrpo
  Split the elements into inner, inner outer and others"
  input list<tuple<SCode.Element, DAE.Mod>> inTplLstElementMod;
  output list<tuple<SCode.Element, DAE.Mod>> outInnerTplLstElementMod;
  output list<tuple<SCode.Element, DAE.Mod>> outInnerOuterTplLstElementMod;
  output list<tuple<SCode.Element, DAE.Mod>> outOtherTplLstElementMod;
algorithm
  (outInnerTplLstElementMod, outInnerOuterTplLstElementMod, outOtherTplLstElementMod) := matchcontinue (inTplLstElementMod)
    local
      list<tuple<SCode.Element, DAE.Mod>> rest,innerComps,innerouterComps,otherComps;
      tuple<SCode.Element, DAE.Mod> comp;
      Absyn.InnerOuter io;

    // empty case
    case ({}) then ({},{},{});

    // inner components
    case ( ( comp as (SCode.COMPONENT(prefixes=SCode.PREFIXES(innerOuter = io)), _) ) :: rest)
      equation
        true = Absyn.isInner(io);
        false = Absyn.isOuter(io);
        (innerComps,innerouterComps,otherComps) = splitInnerAndOtherTplLstElementMod(rest);
      then
        (comp::innerComps,innerouterComps,otherComps);

    // inner outer components
    case ( ( comp as (SCode.COMPONENT(prefixes=SCode.PREFIXES(innerOuter = io)), _) ) :: rest)
      equation
        true = Absyn.isInner(io);
        true = Absyn.isOuter(io);
        (innerComps,innerouterComps,otherComps) = splitInnerAndOtherTplLstElementMod(rest);
      then
        (innerComps,comp::innerouterComps,otherComps);

    // any other components
    case (comp :: rest)
      equation
        (innerComps,innerouterComps,otherComps) = splitInnerAndOtherTplLstElementMod(rest);
      then
        (innerComps,innerouterComps,comp::otherComps);
  end matchcontinue;
end splitInnerAndOtherTplLstElementMod;

public function splitEltsOrderInnerOuter "
This function splits the Element list into four lists
1. Class definitions , imports and defineunits
2. Class-extends class definitions
3. Extends elements
4. Components which are ordered by inner/outer, inner first"
  input list<SCode.Element> elts;
  output list<SCode.Element> cdefImpElts;
  output list<SCode.Element> classextendsElts;
  output list<SCode.Element> extElts;
  output list<SCode.Element> compElts;
algorithm
  (cdefImpElts,classextendsElts,extElts,compElts) := match (elts)
    local
      list<SCode.Element> innerComps,otherComps,comps;
      SCode.Element cdef,imp,ext;
      Absyn.InnerOuter io;

    case _
      equation
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(elts);
        // put inner elements first in the list of
        // elements so they are instantiated first!
        comps = listAppend(innerComps, otherComps);
      then
        (cdefImpElts,classextendsElts,extElts,comps);
  end match;
end splitEltsOrderInnerOuter;

public function splitElts "
This function splits the Element list into four lists
1. Class definitions , imports and defineunits
2. Class-extends class definitions
3. Extends elements
4. Components"
  input list<SCode.Element> elts;
  output list<SCode.Element> cdefImpElts;
  output list<SCode.Element> classextendsElts;
  output list<SCode.Element> extElts;
  output list<SCode.Element> compElts;
algorithm
  (cdefImpElts,classextendsElts,extElts,compElts) := match (elts)
    local
      list<SCode.Element> comps,xs;
      SCode.Element cdef,imp,ext,comp;

    // empty case
    case ({}) then ({},{},{},{});

    // class definitions with class extends
    case ((cdef as SCode.CLASS(classDef = SCode.CLASS_EXTENDS()))::xs)
      equation
        (cdefImpElts,classextendsElts,extElts,comps) = splitElts(xs);
      then
        (cdefImpElts,cdef :: classextendsElts,extElts,comps);

    // class definitions without class extends
    case (((cdef as SCode.CLASS()) :: xs))
      equation
        (cdefImpElts,classextendsElts,extElts,comps) = splitElts(xs);
      then
        (cdef :: cdefImpElts,classextendsElts,extElts,comps);

    // imports
    case (((imp as SCode.IMPORT()) :: xs))
      equation
        (cdefImpElts,classextendsElts,extElts,comps) = splitElts(xs);
      then
        (imp :: cdefImpElts,classextendsElts,extElts,comps);

    // units
    case (((imp as SCode.DEFINEUNIT()) :: xs))
      equation
        (cdefImpElts,classextendsElts,extElts,comps) = splitElts(xs);
      then
        (imp :: cdefImpElts,classextendsElts,extElts,comps);

    // extends elements
    case((ext as SCode.EXTENDS())::xs)
      equation
        (cdefImpElts,classextendsElts,extElts,comps) = splitElts(xs);
      then
        (cdefImpElts,classextendsElts,ext::extElts,comps);

    // components
    case ((comp as SCode.COMPONENT()) :: xs)
      equation
        (cdefImpElts,classextendsElts,extElts,comps) = splitElts(xs);
      then
        (cdefImpElts,classextendsElts,extElts,comp::comps);
  end match;
end splitElts;

public function splitEltsNoComponents "
This function splits the Element list into these categories:
1. Imports
2. Define units and class definitions
3. Class-extends class definitions
4. Filtered class extends and imports"
  input list<SCode.Element> elts;
  output list<SCode.Element> impElts;
  output list<SCode.Element> defElts;
  output list<SCode.Element> classextendsElts;
  output list<SCode.Element> filtered;
algorithm
  (impElts,defElts,classextendsElts,filtered) := matchcontinue (elts)
    local
      list<SCode.Element> xs;
      SCode.Element elt;

    // empty case
    case ({}) then ({},{},{},{});

    // class definitions with class extends
    case ((elt as SCode.CLASS(classDef = SCode.CLASS_EXTENDS()))::xs)
      equation
        (impElts,defElts,classextendsElts,filtered) = splitEltsNoComponents(xs);
      then
        (impElts,defElts,elt::classextendsElts,filtered);

    // class definitions without class extends
    case (((elt as SCode.CLASS()) :: xs))
      equation
        (impElts,defElts,classextendsElts,filtered) = splitEltsNoComponents(xs);
      then
        (impElts,elt::defElts,classextendsElts,elt::filtered);

    // imports
    case (((elt as SCode.IMPORT()) :: xs))
      equation
        (impElts,defElts,classextendsElts,filtered) = splitEltsNoComponents(xs);
      then
        (elt::impElts,defElts,classextendsElts,filtered);

    // units
    case (((elt as SCode.DEFINEUNIT()) :: xs))
      equation
        (impElts,defElts,classextendsElts,filtered) = splitEltsNoComponents(xs);
      then
        (impElts,elt::defElts,classextendsElts,elt::filtered);

    // extends and components elements
    case (elt::xs)
      equation
        (impElts,defElts,classextendsElts,filtered) = splitEltsNoComponents(xs);
      then
        (impElts,defElts,classextendsElts,elt::filtered);

  end matchcontinue;
end splitEltsNoComponents;

public function splitEltsInnerAndOther "
 @author: adrpo
  Splits elements into these categories:
  1. Class definitions, imports and defineunits
  2. Class-extends class definitions
  3. Extends elements
  4. Inner Components
  5. Any Other Components"
  input list<SCode.Element> elts;
  output list<SCode.Element> cdefImpElts;
  output list<SCode.Element> classextendsElts;
  output list<SCode.Element> extElts;
  output list<SCode.Element> innerCompElts;
  output list<SCode.Element> otherCompElts;
algorithm
  (cdefImpElts,classextendsElts,extElts,innerCompElts,otherCompElts) := matchcontinue (elts)
    local
      list<SCode.Element> res,xs,innerComps,otherComps;
      SCode.Element cdef,imp,ext,comp;
      Absyn.InnerOuter io;

    // empty case
    case ({}) then ({},{},{},{},{});

    // class definitions with class extends
    case ((cdef as SCode.CLASS(classDef = SCode.CLASS_EXTENDS()))::xs)
      equation
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then
        (cdefImpElts,cdef :: classextendsElts,extElts,innerComps,otherComps);

    // class definitions without class extends
    case (((cdef as SCode.CLASS()) :: xs))
      equation
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then
        (cdef :: cdefImpElts,classextendsElts,extElts,innerComps,otherComps);

    // imports
    case (((imp as SCode.IMPORT()) :: xs))
      equation
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then
        (imp :: cdefImpElts,classextendsElts,extElts,innerComps,otherComps);

    // units
    case (((imp as SCode.DEFINEUNIT()) :: xs))
      equation
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then
        (imp :: cdefImpElts,classextendsElts,extElts,innerComps,otherComps);

    // extends elements
    case((ext as SCode.EXTENDS())::xs)
      equation
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then
        (cdefImpElts,classextendsElts,ext::extElts,innerComps,otherComps);

    // inner components
    case ((comp as SCode.COMPONENT(prefixes = SCode.PREFIXES(innerOuter = io))) :: xs)
      equation
        true = Absyn.isInner(io);
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then
        (cdefImpElts,classextendsElts,extElts,comp::innerComps,otherComps);

    // any other components
    case ((comp as SCode.COMPONENT() ):: xs)
      equation
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then
        (cdefImpElts,classextendsElts,extElts,innerComps,comp::otherComps);
  end matchcontinue;
end splitEltsInnerAndOther;

protected function orderComponents
"@author: adrpo
 this functions puts the component in front of the list if
 is inner or innerouter and at the end of the list otherwise"
  input SCode.Element inComp;
  input list<SCode.Element> inCompElts;
  output list<SCode.Element> outCompElts;
algorithm
  outCompElts := matchcontinue(inComp, inCompElts)
    local
      list<SCode.Element> compElts;

    // input/output come first!
    case (SCode.COMPONENT(attributes = SCode.ATTR(direction = Absyn.INPUT())), _)
      then inComp::inCompElts;
    case (SCode.COMPONENT(attributes = SCode.ATTR(direction = Absyn.OUTPUT())), _)
      then inComp::inCompElts;
    // put inner/outer in front.
    case (SCode.COMPONENT(prefixes = SCode.PREFIXES(innerOuter = Absyn.INNER())), _)
      then inComp::inCompElts;
    case (SCode.COMPONENT(prefixes = SCode.PREFIXES(innerOuter = Absyn.INNER_OUTER())), _)
      then inComp::inCompElts;
    // put constants in front
    case (SCode.COMPONENT(attributes = SCode.ATTR(variability = SCode.CONST())), _)
      then inComp::inCompElts;
    // put parameters in front
    case (SCode.COMPONENT(attributes = SCode.ATTR(variability = SCode.PARAM())), _)
      then inComp::inCompElts;
    // all other append to the end.
    case (SCode.COMPONENT(), _)
      equation
        compElts = listAppend(inCompElts, {inComp});
      then compElts;
  end matchcontinue;
end orderComponents;

protected function splitClassExtendsElts
"This function splits the Element list into two lists
1. Class-extends class definitions
2. Any other element"
  input list<SCode.Element> elts;
  output list<SCode.Element> classextendsElts;
  output list<SCode.Element> outElts;
algorithm
  (classextendsElts,outElts) := matchcontinue (elts)
    local
      list<SCode.Element> res,xs;
      SCode.Element cdef;
    case ({}) then ({},{});

    case ((cdef as SCode.CLASS(classDef = SCode.CLASS_EXTENDS()))::xs)
      equation
        (classextendsElts,res) = splitClassExtendsElts(xs);
      then
        (cdef :: classextendsElts, res);

    case cdef::xs
      equation
        (classextendsElts,res) = splitClassExtendsElts(xs);
      then
        (classextendsElts, cdef :: res);

  end matchcontinue;
end splitClassExtendsElts;

protected function addClassdefsToEnv3
"function: addClassdefsToEnv3 "
  input FCore.Cache inCache;
  input FCore.Graph env;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input Option<DAE.Mod> inMod;
  input SCode.Element sele;
  output FCore.Cache outCache;
  output FCore.Graph oenv;
  output InnerOuter.InstHierarchy outIH;
  output SCode.Element osele;
algorithm
  (outCache,oenv,outIH,osele) := match(inCache,env,inIH,inPrefix,inMod,sele)
    local
      DAE.Mod mo,mo2;
      SCode.Element sele2;
      FCore.Cache cache;
      FCore.Graph env2;
      String str;
      InstanceHierarchy ih;
      list<DAE.SubMod> lsm,lsm2;
      Prefix.Prefix pre;

    case(_,_,_,_,NONE(),_) then fail();

    case(cache, _, ih, pre, SOME(DAE.MOD(subModLst = lsm)), SCode.CLASS(name=str))
      equation
        // fprintln(Flags.INST_TRACE, "Mods in addClassdefsToEnv3: " + Mod.printModStr(mo) + " class name: " + str);
        (mo2,_) = extractCorrectClassMod2(lsm,str,{});
        // fprintln(Flags.INST_TRACE, "Mods in addClassdefsToEnv3 after extractCorrectClassMod2: " + Mod.printModStr(mo2) + " class name: " + str);
        // TODO: classinf below should be FQ
        (cache, env2, ih, sele2 as SCode.CLASS() , _) =
        Inst.redeclareType(cache, env, ih, mo2, sele, pre, ClassInf.MODEL(Absyn.IDENT(str)), true, DAE.NOMOD());
      then
        (cache,env2,ih,sele2);

  end match;
end addClassdefsToEnv3;

protected function extractCorrectClassMod2
" This function extracts a modifier on a specific component.
 Referenced by the name."
  input list<DAE.SubMod> smod;
  input String name;
  input list<DAE.SubMod> premod;
  output DAE.Mod omod;
  output list<DAE.SubMod> restmods;
algorithm (omod,restmods) := matchcontinue( smod , name , premod)
  local
    DAE.Mod mod;
    DAE.SubMod sub;
    String id;
    list<DAE.SubMod> rest,rest2;

    case({},_,_) then (DAE.NOMOD(),premod);

  case(DAE.NAMEMOD(id, mod) :: rest, _, _)
    equation
        true = stringEq(id, name);
    rest2 = listAppend(premod,rest);
    then
      (mod, rest2);

  case(sub::rest,_,_)
    equation
    (mod,rest2) = extractCorrectClassMod2(rest,name,premod);
    then
      (mod, sub::rest2);

  else
    equation
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.trace("- extract_Correct_Class_Mod_2 failed\n");
    then
      fail();
  end matchcontinue;
end extractCorrectClassMod2;

public function traverseModAddFinal
"Helper function for traverseModAddFinal"
  input SCode.Mod mod;
  output SCode.Mod mod2;
algorithm
  mod2 := matchcontinue(mod)
    local
      SCode.Element element;
      SCode.Each each_;
      list<SCode.SubMod> subs;
      Option<Absyn.Exp> eq;
      SourceInfo info;

    case(SCode.NOMOD()) then SCode.NOMOD();

    case(SCode.REDECL(eachPrefix = each_, element = element))
      equation
        element = traverseModAddFinal3(element);
      then
        SCode.REDECL(SCode.FINAL(),each_,element);

    case(SCode.MOD(_,each_,subs,eq,info))
      equation
        subs = traverseModAddFinal4(subs);
      then
        SCode.MOD(SCode.FINAL(),each_,subs,eq,info);

    else
      equation
        Error.addInternalError(getInstanceName(), sourceInfo());
      then fail();

  end matchcontinue;
end traverseModAddFinal;

protected function traverseModAddFinal3
"Helper function for traverseModAddFinal2"
  input SCode.Element inElement;
  output SCode.Element outElement;
algorithm
  outElement := matchcontinue(inElement)
    local
      SCode.Attributes attr;
      Absyn.TypeSpec tySpec;
      SCode.Mod mod, oldmod;
      Ident name;
      SCode.Visibility vis;
      SCode.Prefixes prefixes;
      SCode.Comment cmt;
      Option<Absyn.Exp> cond;
      Absyn.Path p;
      Option<SCode.Annotation> ann;
      SourceInfo info;

    case SCode.COMPONENT(name,prefixes,attr,tySpec,oldmod,cmt,cond,info)
      equation
        mod = traverseModAddFinal(oldmod);
      then
        SCode.COMPONENT(name,prefixes,attr,tySpec,mod,cmt,cond,info);

    case SCode.IMPORT() then inElement;
    case SCode.CLASS() then inElement;

    case SCode.EXTENDS(p,vis,mod,ann,info)
      equation
        mod = traverseModAddFinal(mod);
      then SCode.EXTENDS(p,vis,mod,ann,info);

    else
      equation
        print(" we failed with traverseModAddFinal3\n");
      then
        fail();

  end matchcontinue;
end traverseModAddFinal3;

protected function traverseModAddFinal4
"Helper function for traverseModAddFinal2"
  input list<SCode.SubMod> subs;
  output list<SCode.SubMod> osubs;
algorithm osubs:= matchcontinue(subs)
  local
    String ident;
    SCode.Mod mod;
    list<Absyn.Subscript> intList;
    list<SCode.SubMod> rest;
  case({}) then {};
  case((SCode.NAMEMOD(ident,mod))::rest )
    equation
      rest = traverseModAddFinal4(rest);
      mod = traverseModAddFinal(mod);
    then
      SCode.NAMEMOD(ident,mod)::rest;
  else
    equation print(" we failed with traverseModAddFinal4\n");
    then fail();
end matchcontinue;
end traverseModAddFinal4;

public function traverseModAddDims
"The function used to modify modifications for non-expanded arrays"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  input SCode.Mod inMod;
  input list<list<DAE.Dimension>> inInstDims;
  input list<Absyn.Subscript> inDecDims;
  output SCode.Mod outMod;
algorithm
  outMod := matchcontinue(inCache,inEnv,inPrefix,inMod,inInstDims,inDecDims)
  local
    FCore.Cache cache;
    FCore.Graph env;
    Prefix.Prefix pre;
    SCode.Mod mod, mod2;
    InstDims inst_dims;
    list<Absyn.Subscript> decDims;
    list<list<DAE.Exp>> exps;
    list<list<Absyn.Exp>> aexps;
    list<Option<Absyn.Exp>> adims;

  case (_,_,_,mod,_,_) //If arrays are expanded, no action is needed
    equation
      true = Config.splitArrays();
    then
      mod;
/*  case (_,_,_,mod,inst_dims,decDims)
    equation
      subs = List.flatten(inst_dims);
      exps = List.map(subs,Expression.subscriptNonExpandedExp);
      aexps = List.map(exps, Expression.unelabExp);
      adims = List.map(decDims, Absyn.subscriptExpOpt);
      mod2 = traverseModAddDims2(mod, aexps, adims, true);

    then
      mod2;*/
  case (cache,env,pre,mod,inst_dims,decDims)
    equation
      exps = List.map1(inst_dims,Expression.dimensionsToExps,{});
      aexps = List.mapList(exps, Expression.unelabExp);
      adims = List.map(decDims, Absyn.subscriptExpOpt);
      mod2 = traverseModAddDims4(cache,env,pre,mod, aexps, adims, true);

    then
      mod2;
  end matchcontinue;
end traverseModAddDims;

protected function traverseModAddDims4
"Helper function  for traverseModAddDims"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  input SCode.Mod inMod;
  input list<list<Absyn.Exp>> inExps;
  input list<Option<Absyn.Exp>> inExpOpts;
  input Boolean inIsTop;
  output SCode.Mod outMod;
algorithm
  outMod := match(inCache,inEnv,inPrefix,inMod,inExps,inExpOpts,inIsTop)
  local
    FCore.Cache cache;
    FCore.Graph env;
    Prefix.Prefix pre;
    SCode.Mod mod;
    SCode.Final f;
    list<SCode.SubMod> submods,submods2;
    Option<Absyn.Exp> binding;
    list<list<Absyn.Exp>> exps;
    list<Option<Absyn.Exp>> expOpts;
    SourceInfo info;

    case (_,_,_,SCode.NOMOD(),_,_,_) then SCode.NOMOD();
    case (_,_,_,mod as SCode.REDECL(),_,_,_) then mod;  // Though redeclarations may need some processing as well
    case (cache,env,pre,SCode.MOD(f, SCode.NOT_EACH(),submods, binding, info),exps,expOpts,_)
      equation
        submods2 = traverseModAddDims5(cache,env,pre,submods,exps,expOpts);
        binding = insertSubsInBinding(binding, exps);
      then
        SCode.MOD(f, SCode.NOT_EACH(),submods2, binding, info);
  end match;
end traverseModAddDims4;

protected function traverseModAddDims5
"Helper function  for traverseModAddDims2"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  input list<SCode.SubMod> inMods;
  input list<list<Absyn.Exp>> inExps;
  input list<Option<Absyn.Exp>> inExpOpts;
  output list<SCode.SubMod> outMods;
algorithm
  outMods := match(inCache,inEnv,inPrefix,inMods,inExps,inExpOpts)
  local
    FCore.Cache cache;
    FCore.Graph env;
    Prefix.Prefix pre;
    SCode.Mod mod,mod2;
    list<SCode.SubMod> smods,smods2;
    Ident n;
    case (_,_,_,{},_,_) then {};
    case (cache,env,pre,SCode.NAMEMOD(n,mod)::smods,_,_)
      equation
        mod2 = traverseModAddDims4(cache,env,pre,mod,inExps,inExpOpts,false);
        smods2 = traverseModAddDims5(cache,env,pre,smods,inExps,inExpOpts);
      then
        SCode.NAMEMOD(n,mod2)::smods2;
  end match;
end traverseModAddDims5;

protected function insertSubsInBinding
input Option<Absyn.Exp> inOpt;
input list<list<Absyn.Exp>> inExps;
output Option<Absyn.Exp> outOpt;
algorithm
  outOpt := match(inOpt,inExps)
  local
    list<list<Absyn.Exp>> exps;
    Absyn.Exp e,e2;
    list<list<Absyn.Subscript>> subs;
    list<list<Absyn.Ident>> vars;

    case (NONE(),_) then NONE();
    case (SOME(e), exps)
      equation
        vars = generateUnusedNamesLstCall(e,exps);
        subs = List.mapList(vars,stringSub);
        (e2,_) = Absyn.traverseExp(e,Absyn.crefInsertSubscriptLstLst, subs);
        e2 = wrapIntoForLst(e2,vars,exps);
      then
        SOME(e2);
  end match;
end insertSubsInBinding;

protected function generateUnusedNames
"Generates a list of variable names which are not used in any of expressions.
The number of variables is the same as the length of input list.
TODO: Write the REAL function!"
input Absyn.Exp inExp;
input list<Absyn.Exp> inList;
output list<String> outNames;
algorithm
  (outNames,_) := generateUnusedNames2(inList,1);
end generateUnusedNames;

protected function generateUnusedNames2
input list<Absyn.Exp> inList;
input Integer inInt;
output list<String> outNames;
output Integer outInt;
algorithm
  (outNames,outInt) := match(inList,inInt)
  local
    Integer i,i1,i2;
    String s;
    list<String> names;
    list<Absyn.Exp> exps;
    case ({},i) then ({},i);
    case (_::exps,i)
      equation
        s = intString(i);
        s = "i" + s;
        i1 = i + 1;
        (names,i2) = generateUnusedNames2(exps,i1);
      then
        (s::names,i2);
  end match;
end generateUnusedNames2;

protected function generateUnusedNamesLst
input list<list<Absyn.Exp>> inList;
input Integer inInt;
output list<list<String>> outNames;
output Integer outInt;
algorithm
  (outNames,outInt) := match(inList,inInt)
  local
    Integer i,i1,i2;
    list<list<String>> names;
    list<String> ns;
    list<list<Absyn.Exp>> exps;
    list<Absyn.Exp> e0;
    case ({},i) then ({},i);
    case (e0::exps,i)
      equation
        (ns,i1) = generateUnusedNames2(e0,i);
        (names,i2) = generateUnusedNamesLst(exps,i1);
      then
        (ns::names,i2);
  end match;
end generateUnusedNamesLst;

protected function generateUnusedNamesLstCall
"Generates a list of lists of variable names which are not used in any of expressions.
The structure of lsis of lists is the same as of input list of lists.
TODO: Write the REAL function!"
input Absyn.Exp inExp;
input list<list<Absyn.Exp>> inList;
output list<list<String>> outNames;
algorithm
  (outNames,_) := generateUnusedNamesLst(inList,1);
end generateUnusedNamesLstCall;

protected function stringsSubs
input list<String> inNames;
output list<Absyn.Subscript> outSubs;
algorithm
  outSubs := match(inNames)
  local
    String n;
    list<String> names;
    list<Absyn.Subscript> subs;
    case {} then {};
    case n::names
      equation
        subs = stringsSubs(names);
      then
        Absyn.SUBSCRIPT(Absyn.CREF(Absyn.CREF_IDENT(n,{})))::subs;
  end match;
end stringsSubs;

protected function stringSub
input String inName;
output Absyn.Subscript outSub;
algorithm
  outSub := match(inName)
  local
    String n;
    case n
      then
        Absyn.SUBSCRIPT(Absyn.CREF(Absyn.CREF_IDENT(n,{})));
  end match;
end stringSub;

protected function wrapIntoFor
input Absyn.Exp inExp;
input list<String> inNames;
input list<Absyn.Exp> inRanges;
output Absyn.Exp outExp;
algorithm
  outExp := match(inExp,inNames,inRanges)
  local
    Absyn.Exp e,e2,r;
    String n;
    list<String> names;
    list<Absyn.Exp> ranges;
    case (e,{},{}) then e;
    case (e,n::names,r::ranges)
      equation
        e2 = wrapIntoFor(e, names, ranges);
      then Absyn.CALL(Absyn.CREF_IDENT("array",{}), Absyn.FOR_ITER_FARG(e2, Absyn.COMBINE() ,{Absyn.ITERATOR(n,NONE(),SOME(Absyn.RANGE(Absyn.INTEGER(1),NONE(),r)))}));
  end match;
end wrapIntoFor;

protected function wrapIntoForLst
input Absyn.Exp inExp;
input list<list<String>> inNames;
input list<list<Absyn.Exp>> inRanges;
output Absyn.Exp outExp;
algorithm
  outExp := match(inExp,inNames,inRanges)
  local
    Absyn.Exp e,e2,e3;
    list<String> n;
    list<list<String>> names;
    list<Absyn.Exp> r;
    list<list<Absyn.Exp>> ranges;
    case (e,{},{}) then e;
    case (e,n::names,r::ranges)
      equation
        e2 = wrapIntoForLst(e, names, ranges);
        e3 = wrapIntoFor(e2, n, r);
      then
        e3;
  end match;
end wrapIntoForLst;

public function componentHasCondition
  input tuple<SCode.Element, DAE.Mod> component;
  output Boolean hasCondition;
algorithm
  hasCondition := match(component)
    case ((SCode.COMPONENT(condition = SOME(_)), _)) then true;
    else false;
  end match;
end componentHasCondition;

public function instElementCondExp
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Element component;
  input Prefix.Prefix prefix;
  input SourceInfo info;
  output Option<Boolean> outCondValue;
  output FCore.Cache outCache;
algorithm
  (outCondValue, outCache) := matchcontinue(component)
    local
      String name;
      Absyn.Exp cond_exp;
      Boolean cond_val;
      FCore.Cache cache;

    case SCode.COMPONENT(condition = SOME(cond_exp))
      equation
        (cond_val, cache) = instConditionalDeclaration(inCache, inEnv, cond_exp, prefix, info);
      then
        (SOME(cond_val), cache);

    case SCode.COMPONENT(condition = SOME(_)) then (NONE(), inCache);
    else (SOME(true), inCache);
  end matchcontinue;
end instElementCondExp;

protected function instConditionalDeclaration
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inCondition;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output Boolean outIsConditional;
  output FCore.Cache outCache;
protected
  FCore.Cache cache;
  DAE.Exp e;
  DAE.Type t;
  DAE.Const c;
  Boolean is_bool, is_param, b;
  Values.Value val;
algorithm
  // Elaborate the conditional expression.
  (outCache, e, DAE.PROP(type_ = t, constFlag = c), _) :=
    Static.elabExp(inCache, inEnv, inCondition, false, NONE(), false, inPrefix, inInfo);

  // The expression must be of boolean type.
  if not Types.isBoolean(t) then
    Error.addSourceMessageAndFail(Error.IF_CONDITION_TYPE_ERROR,
      {Dump.printExpStr(inCondition), Types.unparseTypeNoAttr(t)}, inInfo);
  end if;

  // The expression must be a parameter expression that can be evaluated at compile-time.
  if not Types.isParameterOrConstant(c) then
    Error.addSourceMessageAndFail(Error.COMPONENT_CONDITION_VARIABILITY,
      {Dump.printExpStr(inCondition)}, inInfo);
  end if;

  // If it is a boolean parameter expression, try to evaluate it.
  (outCache, val, _) := Ceval.ceval(outCache, inEnv, e, false, NONE(), Absyn.MSG(inInfo), 0);

  outIsConditional := match(val)
    case Values.BOOL(b) then b;
    case Values.EMPTY(__) // Print an error if the expression has no value.
      equation
        Error.addSourceMessage(Error.CONDITIONAL_EXP_WITHOUT_VALUE,
          {Dump.printExpStr(inCondition)}, inInfo);
      then
        fail();
    else
      equation
        Error.addInternalError("InstUtil.instConditionalDeclaration got unexpected value " + ValuesUtil.valString(val), sourceInfo());
      then
        fail();
  end match;
end instConditionalDeclaration;

public function propagateClassPrefix
"Propagate ClassPrefix, i.e. variability to a component.
 This is needed to make sure that e.g. a parameter does
 not generate an equation but a binding."
  input SCode.Attributes attr;
  input Prefix.Prefix pre;
  output SCode.Attributes outAttr;
algorithm
  outAttr := matchcontinue(attr,pre)
    local
      Absyn.ArrayDim ad;
      SCode.ConnectorType ct;
      Absyn.Direction dir;
      SCode.Parallelism prl;
      SCode.Variability vt;
      Absyn.IsField isf;

    // if classprefix is variable, keep component variability
    case (_,Prefix.PREFIX(_,Prefix.CLASSPRE(SCode.VAR()))) then attr;
    // if variability is constant, do not override it!
    case(SCode.ATTR(variability = SCode.CONST()),_) then attr;
    // if classprefix is parameter or constant, override component variability
    case(SCode.ATTR(ad,ct,prl,_,dir,isf),Prefix.PREFIX(_,Prefix.CLASSPRE(vt)))
      then SCode.ATTR(ad,ct,prl,vt,dir,isf);
    // anything else
    else attr;
  end matchcontinue;
end propagateClassPrefix;

public function checkUseConstValue
"help function to instBinding.
 If first arg is true, it returns the constant expression found in Value option.
 This is used to ensure that e.g. stateSelect attribute gets a constant value
 and not a parameter expression."
  input Boolean useConstValue;
  input DAE.Exp ie;
  input Option<Values.Value> v;
  output DAE.Exp outE;
algorithm
  outE := matchcontinue(useConstValue,ie,v)
    local
      Values.Value val;
      DAE.Exp e;

    case(false,e,_) then e;
    case(true,_,SOME(val)) equation
      e = ValuesUtil.valueExp(val);
    then e;
    case(_,e,_) then e;
  end matchcontinue;
end checkUseConstValue;

public function propagateAbSCDirection
  input SCode.Variability inVariability;
  input SCode.Attributes inAttributes;
  input Option<SCode.Attributes> inClassAttributes;
  input SourceInfo inInfo;
  output SCode.Attributes outAttributes;
algorithm
  outAttributes := match(inVariability, inAttributes, inClassAttributes, inInfo)
    local
      Absyn.Direction dir;

    case (SCode.CONST(), _, _, _) then inAttributes;
    case (SCode.PARAM(), _, _, _) then inAttributes;
    else
      equation
        SCode.ATTR(direction = dir) = inAttributes;
        dir = propagateAbSCDirection2(dir, inClassAttributes, inInfo);
      then
        SCode.setAttributesDirection(inAttributes, dir);
  end match;
end propagateAbSCDirection;

public function propagateAbSCDirection2 "
Author BZ 2008-05
This function merged derived SCode.Attributes with the current input SCode.Attributes."
  input Absyn.Direction v1;
  input Option<SCode.Attributes> optDerAttr;
  input SourceInfo inInfo;
  output Absyn.Direction v3;
algorithm
  v3 := match(v1, optDerAttr, inInfo)
    local
      Absyn.Direction v2;

    case (_,NONE(), _) then v1;
    case(Absyn.BIDIR(),SOME(SCode.ATTR(direction=v2)), _) then v2;
    case (_,SOME(SCode.ATTR(direction=Absyn.BIDIR())), _) then v1;
    case(_,SOME(SCode.ATTR(direction=v2)), _)
      equation
        equality(v1 = v2);
      then v1;

    else
      equation
        print(" failure in propagateAbSCDirection2, Absyn.DIRECTION mismatch");
        Error.addSourceMessage(Error.COMPONENT_INPUT_OUTPUT_MISMATCH, {"",""}, inInfo);
      then
        fail();

  end match;
end propagateAbSCDirection2;

public function makeCrefBaseType
  input DAE.Type inBaseType;
  input list<list<DAE.Dimension>>inDimensions;
  output DAE.Type outType;
algorithm
  outType := Types.simplifyType(makeCrefBaseType2(inBaseType, inDimensions));
end makeCrefBaseType;

protected function makeCrefBaseType2
  input DAE.Type inBaseType;
  input list<list<DAE.Dimension>>inDimensions;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inBaseType, inDimensions)
    local
      DAE.Type ty;
      DAE.Dimensions dims;

    // Types extending basic type has dimensions already added
    // adrpo: not true, see PowerSystems library for example
    // type ReferenceAngle extends .Modelica.SIunits.Angle; some equalityConstraint function end ReferenceAngle;
    // used like: ReferenceAngle[x] theta in a connector
    case (DAE.T_SUBTYPE_BASIC(complexType = ty), _)
      equation
        // check if it has any dimensions
        false = listEmpty(Types.getDimensions(ty));
      then
        ty;

    case (_, {}) then inBaseType;

    else
      equation
        dims = List.last(inDimensions);
        ty = Expression.liftArrayLeftList(inBaseType, dims);
      then
        ty;

  end matchcontinue;
end makeCrefBaseType2;

public function getCrefFromCompDim
"Author: BZ, 2009-07
  Get Absyn.ComponentRefs from dimension in SCode.COMPONENT"
  input SCode.Element inEle;
  output list<Absyn.ComponentRef> cref;
algorithm
  cref := matchcontinue(inEle)
    local
      list<Absyn.Subscript> ads;

    case(SCode.COMPONENT(attributes = SCode.ATTR(arrayDims = ads)))
      then
        Absyn.getCrefsFromSubs(ads,true,true);

    else {};

  end matchcontinue;
end getCrefFromCompDim;

public function getCrefFromCond "
  author: PA
  Return all variables in a conditional component clause.
  Done to instantiate components referenced in other components, See also getCrefFromMod and
  updateComponentsInEnv."
  input Option<Absyn.Exp> cond;
  output list<Absyn.ComponentRef> crefs;
algorithm
  crefs := match(cond)
    local  Absyn.Exp e;
    case(NONE()) then {};
    case SOME(e) then Absyn.getCrefFromExp(e,true,true);
  end match;
end getCrefFromCond;

protected function checkVariabilityOfUpdatedComponent "
For components that already have been visited by updateComponentsInEnv, they must be instantiated without
modifiers to prevent infinite recursion. However, parameters and constants may not have recursive definitions.
So we print errors for those instead."
  input SCode.Variability variability;
  input Absyn.ComponentRef cref;
algorithm
  _ := match (variability,cref)
    local
    case (SCode.VAR(),_) then ();
    case (SCode.DISCRETE(),_) then ();
    else
      equation
        /* Doesn't work anyway right away
        crefStr = Absyn.printComponentRefStr(cref);
        varStr = SCodeDump.variabilityString(variability);
        Error.addMessage(Error.CIRCULAR_PARAM,{crefStr,varStr});*/
      then fail();
  end match;
end checkVariabilityOfUpdatedComponent;

public function propagateBinding "
This function modifies equations into bindings for parameters"
  input DAE.DAElist inVarsDae;
  input DAE.DAElist inEquationsDae "Note: functions from here are not considered";
  output DAE.DAElist outVarsDae;
algorithm
  outVarsDae := matchcontinue(inVarsDae,inEquationsDae)
  local
    list<DAE.Element> vars, vars1, equations;
    DAE.Element var;
    DAE.Exp e;
    DAE.ComponentRef componentRef;
    DAE.VarKind kind;
    DAE.VarDirection direction;
    DAE.VarParallelism parallelism;
    DAE.VarVisibility protection;
    DAE.Type ty;
    DAE.InstDims  dims;
    DAE.ConnectorType ct;
    Option<DAE.VariableAttributes> variableAttributesOption;
    Option<SCode.Comment> absynCommentOption;
    Absyn.InnerOuter innerOuter;
    DAE.ElementSource source "the origin of the element";
    case (DAE.DAE(vars),DAE.DAE({})) then DAE.DAE(vars);
    case (DAE.DAE({}),_) then DAE.DAE({});
    case (DAE.DAE(DAE.VAR(componentRef,kind,direction,parallelism,protection,ty,NONE(),
                          dims,ct,source,variableAttributesOption,
                          absynCommentOption,innerOuter)::vars), DAE.DAE(equations))
      equation
        SOME(e)=findCorrespondingBinding(componentRef, equations);
        DAE.DAE(vars1) = propagateBinding(DAE.DAE(vars),DAE.DAE(equations));
      then
        DAE.DAE(DAE.VAR(componentRef,kind,direction,parallelism,protection,ty,SOME(e),dims,
                ct,source,variableAttributesOption, absynCommentOption,innerOuter)::vars1);

    case (DAE.DAE(var::vars), DAE.DAE(equations))
      equation
        DAE.DAE(vars1)=propagateBinding(DAE.DAE(vars),DAE.DAE(equations));
      then
        DAE.DAE(var::vars1);
  end matchcontinue;
end propagateBinding;

protected function findCorrespondingBinding "
Helper function for propagateBinding"
  input DAE.ComponentRef inCref;
  input list<DAE.Element> inEquations;
  output Option<DAE.Exp> outExp;
algorithm
  outExp:=matchcontinue(inCref, inEquations)
    local
      DAE.ComponentRef cref,cref2,cref3;
      DAE.Exp e;
      list<DAE.Element> equations;

    case (_, {}) then NONE();

    case (cref, DAE.DEFINE(componentRef=cref2, exp=e)::_)
      equation
        true = ComponentReference.crefEqual(cref,cref2);
      then
        SOME(e);

    case (cref, DAE.EQUATION(exp=DAE.CREF(cref2,_),scalar=e)::_)
      equation
        true = ComponentReference.crefEqual(cref,cref2);
      then
        SOME(e);

    case (cref, DAE.EQUEQUATION(cr1=cref2,cr2=cref3)::_)
      equation
        true = ComponentReference.crefEqual(cref,cref2);
        e = Expression.crefExp(cref3);
      then
        SOME(e);

    case (cref, DAE.COMPLEX_EQUATION(lhs=DAE.CREF(cref2,_),rhs=e)::_)
      equation
        true = ComponentReference.crefEqual(cref,cref2);
      then
        SOME(e);

    case (cref, _::equations)
      then
        findCorrespondingBinding(cref,equations);

  end matchcontinue;
end findCorrespondingBinding;

public function isPartial
  input SCode.Partial partialPrefix;
  input DAE.Mod mods;
  output SCode.Partial outPartial;
algorithm
  outPartial := matchcontinue (partialPrefix,mods)
    case (SCode.PARTIAL(),DAE.NOMOD()) then SCode.PARTIAL();
    else SCode.NOT_PARTIAL();
  end matchcontinue;
end isPartial;

public function isFunctionInput
  input ClassInf.State classState;
  input Absyn.Direction direction;
  output Boolean functionInput;
algorithm
  functionInput := matchcontinue(classState, direction)
    case (ClassInf.FUNCTION(), Absyn.INPUT()) then true;
    else false;
  end matchcontinue;
end isFunctionInput;

public function extractClassDefComment
  "This function extracts the comment section from a class definition."
  input FCore.Cache cache;
  input FCore.Graph env;
  input SCode.ClassDef classDef;
  input SCode.Comment inComment;
  input SourceInfo inInfo;
  output SCode.Comment comment;
algorithm
  comment := matchcontinue classDef
    local
      list<SCode.Annotation> al;
      Absyn.Path p;
      SCode.ClassDef cd;
      SCode.Comment cmt;

    case SCode.DERIVED(typeSpec = Absyn.TPATH(path = p))
      equation
        (_, SCode.CLASS(cmt=cmt), _) = Lookup.lookupClass(cache, env, p, SOME(inInfo));
        cmt = mergeClassComments(inComment, cmt);
      then cmt;

    else inComment;
  end matchcontinue;
end extractClassDefComment;

protected function mergeClassComments
  "This function merges two comments together. The rule is that the string
  comment is taken from the first comment, and the annotations from both
  comments are merged."
  input SCode.Comment comment1;
  input SCode.Comment comment2;
  output SCode.Comment outComment;
algorithm
  outComment := matchcontinue(comment1, comment2)
    local
      Option<SCode.Annotation> ann1,ann2,ann;
      Option<String> str1,str2,str;
      Option<SCode.Comment> cmt;
      list<SCode.SubMod> mods1,mods2,mods;
      SourceInfo info;
    case (SCode.COMMENT(SOME(SCode.ANNOTATION(SCode.MOD(subModLst=mods1,info=info))),str1),SCode.COMMENT(SOME(SCode.ANNOTATION(SCode.MOD(subModLst=mods2))),str2))
      equation
        str = if isSome(str1) then str1 else str2;
        mods = listAppend(mods1,mods2);
      then SCode.COMMENT(SOME(SCode.ANNOTATION(SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),mods,NONE(),info))),str);
    case (SCode.COMMENT(ann1,str1),SCode.COMMENT(ann2,str2))
      equation
        str = if isSome(str1) then str1 else str2;
        ann = if isSome(ann1) then ann1 else ann2;
      then SCode.COMMENT(ann,str);
  end matchcontinue;
end mergeClassComments;

public function makeNonExpSubscript
  input DAE.Subscript inSubscript;
  output DAE.Subscript outSubscript;
algorithm
  outSubscript := match (inSubscript)
  local
    DAE.Exp e;
    DAE.Subscript subscript;
    case DAE.INDEX(e)
      then DAE.WHOLE_NONEXP(e);
    case (subscript as DAE.WHOLE_NONEXP(_))
      then subscript;
  end match;
end makeNonExpSubscript;

protected function getFunctionAttributes
"Looks at the annotations of an SCode.Element to create the function attributes,
i.e. Inline and Purity"
  input SCode.Element cl;
  input list<DAE.Var> vl;
  output DAE.FunctionAttributes attr;
algorithm
  attr := matchcontinue (cl,vl)
    local
      SCode.Restriction restriction;
      Boolean isOpenModelicaPure, isImpure, hasOutVars;
      DAE.FunctionBuiltin isBuiltin;
      DAE.InlineType inlineType;
      String name;
      list<DAE.Var> inVars,outVars;

    case (SCode.CLASS(restriction=SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(isImpure))),_)
      equation
        inVars = List.select(vl,Types.isInputVar);
        outVars = List.select(vl,Types.isOutputVar);
        name = SCode.isBuiltinFunction(cl,List.map(inVars,Types.varName),List.map(outVars,Types.varName));
        inlineType = isInlineFunc(cl);
        isOpenModelicaPure = not SCode.hasBooleanNamedAnnotationInClass(cl,"__OpenModelica_Impure");
      then (DAE.FUNCTION_ATTRIBUTES(inlineType,isOpenModelicaPure,isImpure,false,DAE.FUNCTION_BUILTIN(SOME(name)),DAE.FP_NON_PARALLEL()));

    //parallel functions: There are some builtin functions.
    case (SCode.CLASS(restriction=SCode.R_FUNCTION(SCode.FR_PARALLEL_FUNCTION())),_)
      equation
        inVars = List.select(vl,Types.isInputVar);
        outVars = List.select(vl,Types.isOutputVar);
        name = SCode.isBuiltinFunction(cl,List.map(inVars,Types.varName),List.map(outVars,Types.varName));
        inlineType = isInlineFunc(cl);
        isOpenModelicaPure = not SCode.hasBooleanNamedAnnotationInClass(cl,"__OpenModelica_Impure");
      then (DAE.FUNCTION_ATTRIBUTES(inlineType,isOpenModelicaPure,false,false,DAE.FUNCTION_BUILTIN(SOME(name)),DAE.FP_PARALLEL_FUNCTION()));

    //parallel functions: non-builtin
    case (SCode.CLASS(restriction=SCode.R_FUNCTION(SCode.FR_PARALLEL_FUNCTION())),_)
      equation
        inlineType = isInlineFunc(cl);
        isBuiltin = if SCode.hasBooleanNamedAnnotationInClass(cl,"__OpenModelica_BuiltinPtr") then DAE.FUNCTION_BUILTIN_PTR() else DAE.FUNCTION_NOT_BUILTIN();
        isOpenModelicaPure = not SCode.hasBooleanNamedAnnotationInClass(cl,"__OpenModelica_Impure");
      then DAE.FUNCTION_ATTRIBUTES(inlineType,isOpenModelicaPure,false,false,isBuiltin,DAE.FP_PARALLEL_FUNCTION());

    //kernel functions: never builtin and never inlined.
    case (SCode.CLASS(restriction=SCode.R_FUNCTION(SCode.FR_KERNEL_FUNCTION())),_)
      then DAE.FUNCTION_ATTRIBUTES(DAE.NO_INLINE(), true, false, false, DAE.FUNCTION_NOT_BUILTIN(),DAE.FP_KERNEL_FUNCTION());

    case (SCode.CLASS(restriction=restriction),_)
      equation
        inlineType = isInlineFunc(cl);
        hasOutVars = List.exist(vl,Types.isOutputVar);
        isBuiltin = if SCode.hasBooleanNamedAnnotationInClass(cl,"__OpenModelica_BuiltinPtr") then DAE.FUNCTION_BUILTIN_PTR() else DAE.FUNCTION_NOT_BUILTIN();
        isOpenModelicaPure = not SCode.hasBooleanNamedAnnotationInClass(cl,"__OpenModelica_Impure");
        // In Modelica 3.2 and before, external functions with side-effects are not marked
        isImpure = SCode.isRestrictionImpure(restriction,hasOutVars or Config.languageStandardAtLeast(Config.LanguageStandard.'3.3'));
      then DAE.FUNCTION_ATTRIBUTES(inlineType,isOpenModelicaPure,isImpure,false,isBuiltin,DAE.FP_NON_PARALLEL());
  end matchcontinue;
end getFunctionAttributes;

public function checkFunctionElement
"Verifies that an element of a function is correct, i.e.
public input/output, protected variable/parameter/constant or algorithm section"
  input DAE.Element elt;
  input Boolean isExternal;
  input SourceInfo info;
algorithm
  _ := match (elt,isExternal,info)
    local
      String str;

    // Variables have already been checked in checkFunctionVar.
    case (DAE.VAR(), _, _) then ();

    case (DAE.ALGORITHM(algorithm_= DAE.ALGORITHM_STMTS({DAE.STMT_ASSIGN(
        exp = DAE.METARECORDCALL())})), _, _)
      equation
        // We need to know the inlineType to make a good notification
        // Error.addSourceMessage(true,Error.COMPILER_NOTIFICATION, {"metarecordcall"}, info);
      then ();

    case (DAE.ALGORITHM(), false, _) then ();

    else
      equation
        str = DAEDump.dumpElementsStr({elt});
        Error.addSourceMessage(Error.FUNCTION_ELEMENT_WRONG_KIND,{str},info);
      then fail();
  end match;
end checkFunctionElement;

public function printElementAndModList
  input list<tuple<SCode.Element, DAE.Mod>> inLstElAndMod;
  output String outStr;
algorithm
  outStr := match(inLstElAndMod)
    local
      SCode.Element e;
      DAE.Mod m;
      list<tuple<SCode.Element, DAE.Mod>> rest;
      String s1, s2, s3, s;

    case ({}) then "";

    case ((e,m)::rest)
      equation
        s1 = SCodeDump.unparseElementStr(e,SCodeDump.defaultOptions);
        s2 = Mod.printModStr(m);
        s3 = printElementAndModList(rest);
        s = "Element:\n" + s1 + "\nModifier: " + s2 + "\n" + s3;
      then
        s;

  end match;
end printElementAndModList;

protected function splitClassDefsAndComponents
  input list<tuple<SCode.Element, DAE.Mod>> inLstElAndMod;
  output list<tuple<SCode.Element, DAE.Mod>> outClassDefs;
  output list<tuple<SCode.Element, DAE.Mod>> outComponentDefs;
algorithm
  (outClassDefs, outComponentDefs) := matchcontinue(inLstElAndMod)
    local
      SCode.Element e;
      DAE.Mod m;
      list<tuple<SCode.Element, DAE.Mod>> rest, clsdefs, compdefs;
      String s1, s2, s3, s;

    case ({}) then ({},{});

    // components
    case ((e as SCode.COMPONENT(),m)::rest)
      equation
        (clsdefs, compdefs) = splitClassDefsAndComponents(rest);
      then
        (clsdefs, (e,m)::compdefs);

    // classes and others
    case ((e,m)::rest)
      equation
        (clsdefs, compdefs) = splitClassDefsAndComponents(rest);
      then
        ((e,m)::clsdefs, compdefs);

  end matchcontinue;
end splitClassDefsAndComponents;

public function selectModifiers
"this function selects the correct modifiers for class/binding
 i.e.
 fromMerging: redeclare constant Boolean standardOrderComponents = tru
 fromRedeclareType: = true
 take binding to be the second and the other one you make NOMOD
 as it doesn't belong in the Boolean class.
 Weird Modelica.Media stuff"
  input DAE.Mod fromMerging;
  input DAE.Mod fromRedeclareType;
  input Absyn.Path typePath;
  output DAE.Mod bindingMod;
  output DAE.Mod classMod;
algorithm
  (bindingMod, classMod) := matchcontinue(fromMerging, fromRedeclareType, typePath)
    local
      DAE.Mod mod;
    // if the thing we got from merging is a redeclare
    // for a component of a basic type, skip it!
    case (_, _, _)
      equation
        true = redeclareBasicType(fromMerging);
      then
        (fromRedeclareType, fromRedeclareType);

    // any other is fine!
    else
      then
        (fromMerging, fromRedeclareType);
  end matchcontinue;
end selectModifiers;

public function redeclareBasicType
  input DAE.Mod mod;
  output Boolean isRedeclareOfBasicType;
algorithm
  isRedeclareOfBasicType := matchcontinue mod
    local
      String name;
      Absyn.Path path;
    // you cannot redeclare a basic type, only the properties and the binding, i.e.
    // redeclare constant Boolean standardOrderComponents = true
    case DAE.REDECL(element = SCode.COMPONENT(typeSpec=Absyn.TPATH(path=path))) equation
      true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);

        name = Absyn.pathFirstIdent(path);
      // BTH
      true = listMember(name, {"Real", "Integer", "Boolean", "String", "Clock"});
    then true;

    case DAE.REDECL(element = SCode.COMPONENT(typeSpec=Absyn.TPATH(path=path))) equation
      false = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);

      name = Absyn.pathFirstIdent(path);
      // BTH
        true = listMember(name, {"Real", "Integer", "Boolean", "String"});
    then true;

    else false;
  end matchcontinue;
end redeclareBasicType;

public function optimizeFunctionCheckForLocals
  "* Does tail recursion optimization"
  input Absyn.Path path;
  input list<DAE.Element> inElts;
  input Option<DAE.Element> oalg;
  input list<DAE.Element> acc;
  input list<String> invars;
  input list<String> outvars;
  output list<DAE.Element> outElts;
algorithm
  outElts := match (path,inElts,oalg,acc,invars,outvars)
    local
      list<DAE.Statement> stmts;
      DAE.Element elt,elt1,elt2;
      DAE.ElementSource source;
      String str,name;
      list<DAE.Element> elts;
    // No algorithm section; allowed
    case (_,{},NONE(),_,_,_) then listReverse(acc);
    case (_,{},SOME(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),source)),_,_,_)
      equation
        // Adding tail recursion optimization
        stmts = optimizeLastStatementTail(path,stmts,listReverse(invars),listReverse(outvars),{});
      then listReverse(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),source)::acc);
      // Remove empty sections
    case (_,(DAE.ALGORITHM(algorithm_=DAE.ALGORITHM_STMTS({})))::elts,_,_,_,_)
      then optimizeFunctionCheckForLocals(path,elts,oalg,acc,invars,outvars);
    case (_,(elt1 as DAE.ALGORITHM(source=source))::elts,SOME(elt2),_,_,_)
      equation
        str = Absyn.pathString(path);
        Error.addSourceMessage(Error.FUNCTION_MULTIPLE_ALGORITHM,{str},DAEUtil.getElementSourceFileInfo(source));
      then optimizeFunctionCheckForLocals(path,elts,SOME(elt1),elt2::acc,invars,outvars);
    case (_,(elt as DAE.ALGORITHM())::elts,NONE(),_,_,_)
      then optimizeFunctionCheckForLocals(path,elts,SOME(elt),acc,invars,outvars);
    case (_,(elt as DAE.VAR(componentRef=DAE.CREF_IDENT(ident=name),direction=DAE.OUTPUT()))::elts,_,_,_,_)
      then optimizeFunctionCheckForLocals(path,elts,oalg,elt::acc,invars,name::outvars);
    case (_,(elt as DAE.VAR(componentRef=DAE.CREF_IDENT(ident=name),direction=DAE.INPUT()))::elts,_,_,_,_)
      then optimizeFunctionCheckForLocals(path,elts,oalg,elt::acc,name::invars,outvars);
    case (_,elt::elts,_,_,_,_) then optimizeFunctionCheckForLocals(path,elts,oalg,elt::acc,invars,outvars);
  end match;
end optimizeFunctionCheckForLocals;

protected function optimizeLastStatementTail
  input Absyn.Path path;
  input list<DAE.Statement> inStmts;
  input list<String> invars;
  input list<String> outvars;
  input list<DAE.Statement> acc;
  output list<DAE.Statement> ostmts;
algorithm
  ostmts := match (path,inStmts,invars,outvars,acc)
    local
      DAE.Statement stmt;
      list<DAE.Statement> stmts;

    case (_,{stmt},_,_,_)
      equation
        stmt = optimizeStatementTail(path,stmt,invars,outvars);
      then listReverse(stmt::acc);
    case (_,stmt::stmts,_,_,_) then optimizeLastStatementTail(path,stmts,invars,outvars,stmt::acc);
  end match;
end optimizeLastStatementTail;

protected function optimizeStatementTail
  input Absyn.Path path;
  input DAE.Statement inStmt;
  input list<String> invars;
  input list<String> outvars;
  output DAE.Statement ostmt;
algorithm
  ostmt := matchcontinue (path,inStmt,invars,outvars)
    local
      DAE.Type tp;
      DAE.Exp lhs,rhs,cond;
      list<DAE.Exp> lhsLst;
      String name;
      list<String> lhsNames;
      list<DAE.Statement> stmts;
      DAE.ElementSource source;
      DAE.Statement stmt;
      DAE.Else else_;

    case (_,DAE.STMT_ASSIGN(tp,lhs,rhs,source),_,_)
      equation
        name = Expression.simpleCrefName(lhs);
        rhs = optimizeStatementTail2(path,rhs,{name},invars,outvars,source);
        stmt = if Expression.isTailCall(rhs) then DAE.STMT_NORETCALL(rhs,source) else DAE.STMT_ASSIGN(tp,lhs,rhs,source);
      then stmt;
    case (_,DAE.STMT_TUPLE_ASSIGN(tp,lhsLst,rhs,source),_,_)
      equation
        lhsNames = List.map(lhsLst,Expression.simpleCrefName);
        rhs = optimizeStatementTail2(path,rhs,lhsNames,invars,outvars,source);
        stmt = if Expression.isTailCall(rhs) then DAE.STMT_NORETCALL(rhs,source) else DAE.STMT_TUPLE_ASSIGN(tp,lhsLst,rhs,source);
      then stmt;
    case (_,DAE.STMT_IF(cond,stmts,else_,source),_,_)
      equation
        stmts = optimizeLastStatementTail(path,stmts,invars,outvars,{});
        else_ = optimizeElseTail(path,else_,invars,outvars);
      then DAE.STMT_IF(cond,stmts,else_,source);
    case (_,DAE.STMT_NORETCALL(rhs,source),_,{})
      equation
        rhs = optimizeStatementTail2(path,rhs,{},invars,{},source);
        stmt = DAE.STMT_NORETCALL(rhs,source);
      then stmt;
    else inStmt;
  end matchcontinue;
end optimizeStatementTail;

protected function optimizeElseTail
  input Absyn.Path path;
  input DAE.Else inElse;
  input list<String> invars;
  input list<String> outvars;
  output DAE.Else outElse;
algorithm
  outElse := matchcontinue (path,inElse,invars,outvars)
    local
      DAE.Exp cond;
      list<DAE.Statement> stmts;
      DAE.Else else_;

    case (_,DAE.ELSEIF(cond,stmts,else_),_,_)
      equation
        stmts = optimizeLastStatementTail(path,stmts,invars,outvars,{});
        else_ = optimizeElseTail(path,else_,invars,outvars);
      then DAE.ELSEIF(cond,stmts,else_);

    case (_,DAE.ELSE(stmts),_,_)
      equation
        stmts = optimizeLastStatementTail(path,stmts,invars,outvars,{});
      then DAE.ELSE(stmts);

    else inElse;
  end matchcontinue;
end optimizeElseTail;

protected function optimizeStatementTail2
  input Absyn.Path path;
  input DAE.Exp rhs;
  input list<String> lhsVars;
  input list<String> invars;
  input list<String> outvars;
  input DAE.ElementSource source;
  output DAE.Exp orhs;
algorithm
  true:=valueEq(lhsVars,outvars);
  (orhs,true) := optimizeStatementTail3(path,rhs,invars,source);
end optimizeStatementTail2;

protected function optimizeStatementTail3
  input Absyn.Path path;
  input DAE.Exp rhs;
  input list<String> vars;
  input DAE.ElementSource source;
  output DAE.Exp orhs;
  output Boolean isTailRecursive;
algorithm
  (orhs,isTailRecursive) := matchcontinue (path,rhs,vars,source)
    local
      Absyn.Path path1,path2;
      String str;
      DAE.InlineType i;
      Boolean b1,b2,b3,b4;
      DAE.Type tp,et;
      list<DAE.Exp> es,inputs;
      DAE.Exp e1,e2,e3;
      list<DAE.Element> localDecls;
      DAE.MatchType matchType;
      list<DAE.MatchCase> cases;
      list<list<String>> aliases;
    case (path1,DAE.CALL(path=path2,expLst=es,attr=DAE.CALL_ATTR(tp,b1,b2,b3,b4,i,DAE.NO_TAIL())),_,_)
      equation
        true = Absyn.pathEqual(path1,path2);
        str = "Tail recursion of: " + ExpressionDump.printExpStr(rhs) + " with input vars: " + stringDelimitList(vars,",");
        if Flags.isSet(Flags.TAIL) then
          Error.addSourceMessage(Error.COMPILER_NOTIFICATION,{str},DAEUtil.getElementSourceFileInfo(source));
        end if;
      then (DAE.CALL(path2,es,DAE.CALL_ATTR(tp,b1,b2,b3,b4,i,DAE.TAIL(vars))),true);
    case (_,DAE.IFEXP(e1,e2,e3),_,_)
      equation
        (e2,b1) = optimizeStatementTail3(path,e2,vars,source);
        (e3,b2) = optimizeStatementTail3(path,e3,vars,source);
        true = b1 or b2;
      then (DAE.IFEXP(e1,e2,e3),true);
    case (_,DAE.MATCHEXPRESSION(matchType as DAE.MATCH(_) /*TODO:matchcontinue*/,inputs,aliases,localDecls,cases,et),_,_)
      equation
        cases = optimizeStatementTailMatchCases(path,cases,false,{},vars,source);
      then (DAE.MATCHEXPRESSION(matchType,inputs,aliases,localDecls,cases,et),true);
    else (rhs,false);
  end matchcontinue;
end optimizeStatementTail3;

protected function optimizeStatementTailMatchCases
  input Absyn.Path path;
  input list<DAE.MatchCase> inCases;
  input Boolean changed;
  input list<DAE.MatchCase> inAcc;
  input list<String> vars;
  input DAE.ElementSource source;
  output list<DAE.MatchCase> ocases;
algorithm
  ocases := matchcontinue (path,inCases,changed,inAcc,vars,source)
    local
      list<DAE.Pattern> patterns;
      list<DAE.Element> localDecls;
      list<DAE.Statement> body;
      Option<DAE.Exp> patternGuard;
      SourceInfo resultInfo,info;
      Integer jump;
      DAE.MatchCase case_;
      DAE.Exp exp,exp1;
      list<DAE.MatchCase> cases,acc;
      DAE.ElementSource sourceStmt;

    case (_,{},true,acc,_,_) then listReverse(acc);
    case (_,DAE.CASE(patterns,patternGuard,localDecls,body,SOME(exp),resultInfo,jump,info)::cases,_,acc,_,_)
      equation
        (exp,true) = optimizeStatementTail3(path,exp,vars,source);
        case_ = DAE.CASE(patterns,patternGuard,localDecls,body,SOME(exp),resultInfo,jump,info);
      then optimizeStatementTailMatchCases(path,cases,true,case_::acc,vars,source);
    case (_,DAE.CASE(patterns,patternGuard,localDecls,body,SOME(DAE.TUPLE({})),resultInfo,jump,info)::cases,_,acc,_,_)
      equation
        DAE.STMT_NORETCALL(exp,sourceStmt) = List.last(body);
        (exp,true) = optimizeStatementTail3(path,exp,vars,source);
        body = List.set(body,listLength(body),DAE.STMT_NORETCALL(exp,sourceStmt));
        case_ = DAE.CASE(patterns,patternGuard,localDecls,body,SOME(DAE.TUPLE({})),resultInfo,jump,info);
      then optimizeStatementTailMatchCases(path,cases,true,case_::acc,vars,source);
    case (_,case_::cases,_,acc,_,_)
      then optimizeStatementTailMatchCases(path,cases,changed,case_::acc,vars,source);
  end matchcontinue;
end optimizeStatementTailMatchCases;

public function pushStructuralParameters
  "Cannot be part of Env due to RML issues"
  input FCore.Cache cache;
  output FCore.Cache ocache;
algorithm
  ocache := match cache
    local
      Option<FCore.Graph> ie;
      array<DAE.FunctionTree> f;
      HashTable.HashTable ht;
      list<list<DAE.ComponentRef>> crs;
      Absyn.Path p;
      Absyn.Program program;
    case FCore.CACHE(ie,f,(ht,crs),p,program) then FCore.CACHE(ie,f,(ht,{}::crs),p,program);
    else cache;
  end match;
end pushStructuralParameters;

public function popStructuralParameters
  "Cannot be part of Env due to RML issues"
  input FCore.Cache cache;
  input Prefix.Prefix pre;
  output FCore.Cache ocache;
algorithm
  ocache := match (cache,pre)
    local
      Option<FCore.Graph> ie;
      array<DAE.FunctionTree> f;
      HashTable.HashTable ht;
      list<DAE.ComponentRef> crs;
      list<list<DAE.ComponentRef>> crss;
      Absyn.Path p;
      Absyn.Program program;
    case (FCore.CACHE(ie,f,(ht,crs::crss),p,program),_)
      equation
        ht = prefixAndAddCrefsToHt(cache,ht,pre,crs);
      then FCore.CACHE(ie,f,(ht,crss),p,program);
    case (FCore.NO_CACHE(),_) then cache;
  end match;
end popStructuralParameters;

protected function prefixAndAddCrefsToHt
  "Cannot be part of Env due to RML issues"
  input FCore.Cache cache;
  input HashTable.HashTable iht;
  input Prefix.Prefix pre;
  input list<DAE.ComponentRef> icrs;
  output HashTable.HashTable oht;
algorithm
  oht := match (cache,iht,pre,icrs)
    local
      DAE.ComponentRef cr;
      HashTable.HashTable ht;
      list<DAE.ComponentRef> crs;

    case (_,ht,_,{}) then ht;
    case (_,ht,_,cr::_)
      equation
        (_,cr) = PrefixUtil.prefixCref(cache, FGraph.empty(), InnerOuter.emptyInstHierarchy, pre, cr);
        ht = BaseHashTable.add((cr,1),ht);
      then ht;
  end match;
end prefixAndAddCrefsToHt;

protected function numStructuralParameterScopes
  input FCore.Cache cache;
  output Integer i;
protected
  list<list<DAE.ComponentRef>> lst;
algorithm
  FCore.CACHE(evaluatedParams=(_,lst)) := cache;
  i := listLength(lst);
end numStructuralParameterScopes;

public function checkFunctionDefUse
  "Finds any variable that might be used without first being defined"
  input list<DAE.Element> elts;
  input SourceInfo info;
algorithm
  _ := matchcontinue (elts,info)
    local
    case (_,_)
      equation
        _ = checkFunctionDefUse2(elts,NONE(),{},{},info);
      then ();
    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"InstUtil.checkFunctionDefUse failed"}, info);
      then ();
  end matchcontinue;
end checkFunctionDefUse;

protected function checkFunctionDefUse2
  "Finds any variable that might be used without first being defined"
  input list<DAE.Element> elts;
  input Option<list<DAE.Statement>> alg "NONE() in first iteration";
  input list<String> inUnbound "{} in first iteration";
  input list<String> inOutputs "List of variables that are also used, when returning";
  input SourceInfo inInfo;
  output list<String> outUnbound;
algorithm
  outUnbound := match (elts,alg,inUnbound,inOutputs,inInfo)
    local
      list<DAE.Element> rest;
      list<DAE.Statement> stmts;
      list<String> unbound,outputs,names,outNames;
      String name;
      DAE.InstDims dims;
      DAE.VarDirection dir;
      list<DAE.Var> vars;
    case ({},NONE(),_,_,_)
      // This would run also for partial function inst... So let's skip it
      // equation
      //  unbound = List.fold1(outputs, checkOutputDefUse, inInfo, unbound);
      then inUnbound;
    case ({},SOME(stmts),unbound,outputs,_)
      equation
        ((_,_,unbound)) = List.fold1(stmts, checkFunctionDefUseStmt, false, (false,false,unbound));
        unbound = List.fold1(outputs, checkOutputDefUse, inInfo, unbound);
      then unbound;
    case (DAE.VAR(direction=DAE.INPUT())::rest,_,unbound,_,_)
      equation
        unbound = checkFunctionDefUse2(rest,alg,unbound,inOutputs,inInfo);
      then unbound;
    case (DAE.VAR(direction=dir,componentRef=DAE.CREF_IDENT(ident=name),ty=DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_),varLst=vars),dims=dims,binding=NONE())::rest,_,unbound,_,_)
      equation
        vars = List.filterOnTrue(vars, Types.varIsVariable);
        // TODO: We filter out parameters at the moment. I'm unsure if this is correct. Might be that this is an automatic error...
        names = List.map1r(List.map(vars, Types.varName), stringAppend, name + ".");
        // print("for record: " + stringDelimitList(names,",") + "\n");
        // Arrays with unknown bounds (size(cr,1), etc) are treated as initialized because they may have 0 dimensions checked for in the code
        outNames = if DAEUtil.varDirectionEqual(dir,DAE.OUTPUT()) then names else {};
        names = if Expression.dimensionsKnownAndNonZero(dims) then names else {};
        unbound = listAppend(names,unbound);
        outputs = listAppend(outNames,inOutputs);
        unbound = checkFunctionDefUse2(rest,alg,unbound,outputs,inInfo);
      then unbound;
    case (DAE.VAR(direction=dir,componentRef=DAE.CREF_IDENT(ident=name),dims=dims,binding=NONE())::rest,_,unbound,_,_)
      equation
        // Arrays with unknown bounds (size(cr,1), etc) are treated as initialized because they may have 0 dimensions checked for in the code
        unbound = List.consOnTrue(Expression.dimensionsKnownAndNonZero(dims),name,unbound);
        outputs = List.consOnTrue(DAEUtil.varDirectionEqual(dir,DAE.OUTPUT()),name,inOutputs);
        unbound = checkFunctionDefUse2(rest,alg,unbound,outputs,inInfo);
      then unbound;
    case (DAE.ALGORITHM(algorithm_=DAE.ALGORITHM_STMTS(stmts))::rest,NONE(),unbound,_,_)
      equation
        unbound = checkFunctionDefUse2(rest,SOME(stmts),unbound,inOutputs,inInfo);
      then unbound;
    case (_::rest,_,unbound,_,_)
      equation
        unbound = checkFunctionDefUse2(rest,alg,unbound,inOutputs,inInfo);
      then unbound;
  end match;
end checkFunctionDefUse2;

protected function checkOutputDefUse
  input String name;
  input SourceInfo info;
  input list<String> inUnbound;
  output list<String> outUnbound;
protected
  Boolean b;
algorithm
  b := listMember(name,inUnbound);
  Error.assertionOrAddSourceMessage(not b, Error.WARNING_DEF_USE, {name}, info);
  outUnbound := List.filter1OnTrue(inUnbound,Util.stringNotEqual,name);
end checkOutputDefUse;

protected function checkFunctionDefUseStmt
  "Find any variable that might be used in the statement without prior definition. Any defined variables are removed from undefined."
  input DAE.Statement inStmt;
  input Boolean inLoop;
  input tuple<Boolean,Boolean,list<String>> inUnbound "Return or Break ; Returned for sure ; Unbound";
  output tuple<Boolean,Boolean,list<String>> outUnbound "";
algorithm
  outUnbound := match (inStmt,inLoop,inUnbound)
    local
      DAE.ElementSource source;
      String str,iter;
      DAE.ComponentRef cr;
      DAE.Exp exp,lhs,rhs,exp1,exp2;
      list<DAE.Exp> lhss;
      list<String> unbound;
      Boolean b,b1,b2;
      DAE.Else else_;
      list<DAE.Statement> stmts;
      SourceInfo info;

    case (_,_,(true,_,_)) then inUnbound;
    case (_,_,(false,true,_))
      equation
        info = DAEUtil.getElementSourceFileInfo(DAEUtil.getStatementSource(inStmt));
        Error.addSourceMessage(Error.INTERNAL_ERROR,
          {"InstUtil.checkFunctionDefUseStmt failed"}, info);
      then fail();
    case (DAE.STMT_ASSIGN(exp1=lhs,exp=rhs,source=source),_,(_,_,unbound))
      equation
        info = DAEUtil.getElementSourceFileInfo(source);
        (_,(unbound,_)) = Expression.traverseExpTopDown(rhs,findUnboundVariableUse,(unbound,info));
        // Traverse subs too! arr[x] := ..., x unbound
        unbound = traverseCrefSubs(lhs,info,unbound);
        unbound = crefFiltering(lhs,unbound);
      then ((false,false,unbound));
    case (DAE.STMT_TUPLE_ASSIGN(expExpLst=lhss,exp=rhs,source=source),_,(_,_,unbound))
      equation
        info = DAEUtil.getElementSourceFileInfo(source);
        (_,(unbound,_)) = Expression.traverseExpTopDown(rhs,findUnboundVariableUse,(unbound,info));
        // Traverse subs too! arr[x] := ..., x unbound
        unbound = List.fold1(lhss,traverseCrefSubs,info,unbound);
        unbound = List.fold(lhss,crefFiltering,unbound);
      then ((false,false,unbound));
    case (DAE.STMT_ASSIGN_ARR(lhs=lhs,exp=rhs,source=source),_,(_,_,unbound))
      equation
        info = DAEUtil.getElementSourceFileInfo(source);
        (_,(unbound,_)) = Expression.traverseExpTopDown(rhs,findUnboundVariableUse,(unbound,info));
        // Traverse subs too! arr[x] := ..., x unbound
        unbound = traverseCrefSubs(lhs,info,unbound);
        unbound = crefFiltering(lhs,unbound);
      then ((false,false,unbound));
    case (DAE.STMT_IF(exp,stmts,else_,source),_,(_,_,unbound))
      equation
        info = DAEUtil.getElementSourceFileInfo(source);
        ((b1,b2,unbound)) = checkFunctionDefUseElse(DAE.ELSEIF(exp,stmts,else_),unbound,inLoop,info);
      then ((b1,b2,unbound));
    case (DAE.STMT_FOR(iter=iter,range=exp,statementLst=stmts,source=source),_,(_,_,unbound))
      equation
        info = DAEUtil.getElementSourceFileInfo(source);
        unbound = List.filter1OnTrue(unbound,Util.stringNotEqual,iter) "TODO: This is not needed if all references are tagged CREF_ITER";
        (_,(unbound,_)) = Expression.traverseExpTopDown(exp,findUnboundVariableUse,(unbound,info));
        ((_,b,unbound)) = List.fold1(stmts, checkFunctionDefUseStmt, true, (false,false,unbound));
      then ((b,b,unbound));
    case (DAE.STMT_PARFOR(iter=iter,range=exp,statementLst=stmts,source=source),_,(_,_,unbound))
      equation
        info = DAEUtil.getElementSourceFileInfo(source);
        unbound = List.filter1OnTrue(unbound,Util.stringNotEqual,iter) "TODO: This is not needed if all references are tagged CREF_ITER";
        (_,(unbound,_)) = Expression.traverseExpTopDown(exp,findUnboundVariableUse,(unbound,info));
        ((_,b,unbound)) = List.fold1(stmts, checkFunctionDefUseStmt, true, (false,false,unbound));
      then ((b,b,unbound));
    case (DAE.STMT_WHILE(exp=exp,statementLst=stmts,source=source),_,(_,_,unbound))
      equation
        info = DAEUtil.getElementSourceFileInfo(source);
        (_,(unbound,_)) = Expression.traverseExpTopDown(exp,findUnboundVariableUse,(unbound,info));
        ((_,b,unbound)) = List.fold1(stmts, checkFunctionDefUseStmt, true, (false,false,unbound));
      then ((b,b,unbound));
    case (DAE.STMT_ASSERT(cond=DAE.BCONST(false),source=source),_,(_,_,_)) // TODO: Re-write these earlier from assert(false,msg) to terminate(msg)
      then ((true,true,{}));
    case (DAE.STMT_ASSERT(cond=exp1,msg=exp2,source=source),_,(_,_,unbound))
      equation
        info = DAEUtil.getElementSourceFileInfo(source);
        (_,(unbound,_)) = Expression.traverseExpTopDown(exp1,findUnboundVariableUse,(unbound,info));
        (_,(unbound,_)) = Expression.traverseExpTopDown(exp2,findUnboundVariableUse,(unbound,info));
      then ((false,false,unbound));
    case (DAE.STMT_TERMINATE(msg=exp,source=source),_,(_,_,unbound))
      equation
        info = DAEUtil.getElementSourceFileInfo(source);
        (_,(unbound,_)) = Expression.traverseExpTopDown(exp,findUnboundVariableUse,(unbound,info));
      then ((true,true,unbound));
    case (DAE.STMT_NORETCALL(exp=DAE.CALL(path=Absyn.IDENT("fail"),expLst={}),source=source),_,(_,_,unbound))
      then ((true,true,{}));
    case (DAE.STMT_NORETCALL(exp=exp,source=source),_,(_,_,unbound))
      equation
        info = DAEUtil.getElementSourceFileInfo(source);
        (_,(unbound,_)) = Expression.traverseExpTopDown(exp,findUnboundVariableUse,(unbound,info));
      then ((false,false,unbound));
    case (DAE.STMT_BREAK(),_,(_,_,unbound)) then ((true,false,unbound));
    case (DAE.STMT_RETURN(),_,(_,_,unbound)) then ((true,true,unbound));
    case (DAE.STMT_CONTINUE(),_,(_,_,unbound)) then ((false,false,unbound));
    case (DAE.STMT_ARRAY_INIT(),_,_) then inUnbound;
    case (DAE.STMT_FAILURE(body=stmts),_,(_,_,unbound))
      equation
        ((_,b,unbound)) = List.fold1(stmts, checkFunctionDefUseStmt, inLoop, (false,false,unbound));
      then ((b,b,unbound));

    // STMT_WHEN not in functions
    // STMT_REINIT not in functions
    else
      equation
        str = DAEDump.ppStatementStr(inStmt);
        str = "InstUtil.checkFunctionDefUseStmt failed: " + str;
        info = DAEUtil.getElementSourceFileInfo(DAEUtil.getStatementSource(inStmt));
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then fail();
  end match;
end checkFunctionDefUseStmt;

protected function checkFunctionDefUseElse
  input DAE.Else inElse;
  input list<String> inUnbound;
  input Boolean inLoop;
  input SourceInfo info;
  output tuple<Boolean,Boolean,list<String>> outUnbound;
algorithm
  outUnbound := match (inElse,inUnbound,inLoop,info)
    local
      DAE.Exp exp;
      list<DAE.Statement> stmts;
      DAE.Else else_;
      list<String> unbound,unboundBranch;
      Boolean b1,b2,b3,b4,iloop;
    case (DAE.NOELSE(),_,_,_) then ((false,false,inUnbound));
    case (DAE.ELSEIF(exp,stmts,else_),unbound,iloop,_)
      equation
        (_,(unbound,_)) = Expression.traverseExpTopDown(exp,findUnboundVariableUse,(unbound,info));
        ((b1,b2,unboundBranch)) = checkFunctionDefUseElse(else_,unbound,inLoop,info);
        ((b3,b4,unbound)) = List.fold1(stmts, checkFunctionDefUseStmt, inLoop, (false,false,unbound));
        iloop = true "We find a few false positives if we are too conservative, so let's do it non-exact";
        unbound = if iloop then List.intersectionOnTrue(unboundBranch, unbound, stringEq) else unbound;
        unbound = if not (iloop or b1) then List.union(unboundBranch, unbound) else unbound;
        /* Merge the state of the two branches. Either they can break/return or not */
        b1 = b1 and b3;
        b2 = b2 and b4;
      then ((b1,b2,unbound));
    case (DAE.ELSE(stmts),unbound,_,_)
      equation
        ((b1,b2,unbound)) = List.fold1(stmts, checkFunctionDefUseStmt, inLoop, (false,false,unbound));
      then ((b1,b2,unbound));
  end match;
end checkFunctionDefUseElse;

protected function crefFiltering
  "If the expression is a cref, remove it from the unbound variables"
  input DAE.Exp inExp;
  input list<String> inUnbound;
  output list<String> outUnbound;
algorithm
  outUnbound := match (inExp,inUnbound)
    local
      list<String> unbound;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      DAE.Pattern pattern;
      String id1,id2;
    case (DAE.CREF(componentRef=DAE.WILD()),_) then inUnbound;
      // Assignment to part of a record
    case (DAE.CREF(componentRef=DAE.CREF_QUAL(ident=id1,componentRef=DAE.CREF_IDENT(ident=id2))),unbound)
      equation
        unbound = List.filter1OnTrue(unbound,Util.stringNotEqual,id1 + "." + id2);
      then unbound;
      // Assignment to the whole record - filter out everything it is prefix of
    case (DAE.CREF(componentRef=DAE.CREF_IDENT(ident=id1),ty=DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_))),unbound)
      equation
        id1 = id1 + ".";
        unbound = List.filter2OnTrue(unbound,Util.notStrncmp,id1,stringLength(id1));
      then unbound;
    case (DAE.CREF(componentRef=cr),unbound)
      equation
        unbound = List.filter1OnTrue(unbound,Util.stringNotEqual,ComponentReference.crefFirstIdent(cr));
      then unbound;
    case (DAE.ASUB(exp=exp),unbound) then crefFiltering(exp,unbound);
    case (DAE.PATTERN(pattern=pattern),unbound)
      equation
        ((_,unbound)) = Patternm.traversePattern((pattern,unbound),patternFiltering);
      then unbound;
    else inUnbound;
  end match;
end crefFiltering;

protected function patternFiltering
  input tuple<DAE.Pattern,list<String>> inTpl;
  output tuple<DAE.Pattern,list<String>> outTpl;
algorithm
  outTpl := match inTpl
    local
      list<String> unbound;
      String id;
      DAE.Pattern pattern;
    case ((pattern as DAE.PAT_AS(id=id),unbound))
      equation
        unbound = List.filter1OnTrue(unbound,Util.stringNotEqual,id);
      then ((pattern,unbound));
    case ((pattern as DAE.PAT_AS_FUNC_PTR(id=id),unbound))
      equation
        unbound = List.filter1OnTrue(unbound,Util.stringNotEqual,id);
      then ((pattern,unbound));
    else inTpl;
  end match;
end patternFiltering;

protected function traverseCrefSubs
  input DAE.Exp exp;
  input SourceInfo info;
  input list<String> inUnbound;
  output list<String> outUnbound;
algorithm
  outUnbound := match (exp,info,inUnbound)
    local
      list<String> unbound;
      DAE.ComponentRef cr;
    case (DAE.CREF(componentRef=cr),_,unbound)
      equation
        (_,(unbound,_)) = Expression.traverseExpTopDownCrefHelper(cr,findUnboundVariableUse,(unbound,info));
      then unbound;
    else inUnbound;
  end match;
end traverseCrefSubs;

protected function findUnboundVariableUse "Check if the expression is used before it is defined"
  input DAE.Exp inExp;
  input tuple<list<String>,SourceInfo> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<list<String>,SourceInfo> outTpl;
algorithm
  (outExp,cont,outTpl) := match (inExp,inTpl)
    local
      DAE.Exp exp;
      list<String> unbound,unboundLocal;
      SourceInfo info;
      String str,name;
      DAE.ComponentRef cr;
      Boolean b;
      tuple<list<String>,SourceInfo> arg;
      list<DAE.Exp> inputs;
      list<DAE.Element> localDecls;
      list<DAE.MatchCase> cases;
      list<list<String>> unbounds;
    case (exp as DAE.SIZE(),arg) then (exp,false,arg);
    case (exp as DAE.CREF(componentRef=cr),(unbound,info))
      equation
        b = listMember(ComponentReference.crefFirstIdent(cr),unbound);
        str = ComponentReference.crefFirstIdent(cr);
        Error.assertionOrAddSourceMessage(not b, Error.WARNING_DEF_USE, {str}, info);
        unbound = List.filter1OnTrue(unbound,Util.stringNotEqual,str);
      then (exp,true,(unbound,info));
    case (exp as DAE.CALL(path=Absyn.IDENT(name)),(unbound,info))
      equation
        b = listMember(name,unbound);
        Error.assertionOrAddSourceMessage(not b, Error.WARNING_DEF_USE, {name}, info);
        unbound = List.filter1OnTrue(unbound,Util.stringNotEqual,name);
      then (exp,true,(unbound,info));
    case (exp as DAE.MATCHEXPRESSION(inputs=inputs,localDecls=localDecls,cases=cases),(unbound,info))
      equation
        (_,(unbound,_)) = Expression.traverseExpTopDown(DAE.LIST(inputs),findUnboundVariableUse,(unbound,info));
        unboundLocal = checkFunctionDefUse2(localDecls,NONE(),unbound,{},info);
        unbounds = List.map1(cases,findUnboundVariableUseInCase,unboundLocal);
        // Find variables assigned in a case, like: _ = match () case () equation o = 1.5; then ();
        unbound = List.fold1r(unbounds, List.intersectionOnTrue, stringEq, unbound);
      then (exp,false,(unbound,info));
    case (exp,arg) then (exp,true,arg);
  end match;
end findUnboundVariableUse;

protected function findUnboundVariableUseInCase "Check if the expression is used before it is defined"
  input DAE.MatchCase case_;
  input list<String> inUnbound;
  output list<String> unbound;
algorithm
  unbound := match (case_,inUnbound)
    local
      SourceInfo info,resultInfo;
      Option<DAE.Exp> patternGuard,result;
      list<DAE.Pattern> patterns;
      list<DAE.Statement> body;
    case (DAE.CASE(patterns=patterns,patternGuard=patternGuard,body=body,result=result,info=info,resultInfo=resultInfo),unbound)
      equation
        ((_,unbound)) = Patternm.traversePattern((DAE.PAT_META_TUPLE(patterns),unbound),patternFiltering);
        (_,(unbound,_)) = Expression.traverseExpTopDown(DAE.META_OPTION(patternGuard),findUnboundVariableUse,(unbound,info));
        ((_,_,unbound)) = List.fold1(body, checkFunctionDefUseStmt, true, (false,false,unbound));
        (_,(unbound,_)) = Expression.traverseExpTopDown(DAE.META_OPTION(result),findUnboundVariableUse,(unbound,resultInfo));
      then unbound;
  end match;
end findUnboundVariableUseInCase;

public function checkParallelismWRTEnv
  input FCore.Graph inEnv;
  input String inName;
  input SCode.Attributes inAttr;
  input SourceInfo inInfo;
  output Boolean isValid;
algorithm
  isValid := matchcontinue(inEnv,inName,inAttr,inInfo)
    local
      String errorString,scopeName;
      Absyn.Direction dir;
      SCode.Parallelism prl;
      Boolean isparglobal;
      Boolean hasnodir;
      FCore.Ref r;

    case(_, _, SCode.ATTR(parallelism = prl, direction = dir), _)
      equation
        r = FGraph.lastScopeRef(inEnv);
        false = FNode.isRefTop(r);
        scopeName = FNode.refName(r);
        true = FGraph.checkScopeType({r}, SOME(FCore.PARALLEL_SCOPE()));
        isparglobal = SCode.parallelismEqual(prl, SCode.PARGLOBAL());
        hasnodir = not Absyn.isInputOrOutput(dir);
        true = isparglobal and hasnodir;

        errorString = "\n" +
        "- local parglobal component '" + inName +
        "' is declared in parallel/parkernel function '" + scopeName + "'. \n" +
        "- parglobal variables can be declared only in normal functions. \n";

        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then false;

    else true;

 end matchcontinue;
end checkParallelismWRTEnv;

public function instDimsHasZeroDims
  input list<list<DAE.Dimension>> inInstDims;
  output Boolean outHasZeroDims;
algorithm
  outHasZeroDims := matchcontinue(inInstDims)
    local
      list<DAE.Dimension> dims;
      InstDims rest_dims;

    case (dims :: _)
      equation
        true = List.exist(dims, Expression.dimensionIsZero);
      then
        true;

    case (_ :: rest_dims) then instDimsHasZeroDims(rest_dims);

    else false;
  end matchcontinue;
end instDimsHasZeroDims;

public function noModForUpdatedComponents "help function for updateComponentInEnv,
For components that already have been visited by updateComponentsInEnv, they must be instantiated without
modifiers to prevent infinite recursion"
  input SCode.Variability variability;
  input HashTable5.HashTable updatedComps;
  input Absyn.ComponentRef cref;
  input  DAE.Mod mods;
  input  DAE.Mod cmod;
  input  SCode.Mod m;
  output DAE.Mod outMods;
  output DAE.Mod outCmod;
  output SCode.Mod outM;
algorithm
  (outMods,outCmod,outM) := matchcontinue(variability,updatedComps,cref,mods,cmod,m)
    case (_,_,_,_,_,_)
      equation
        _ = BaseHashTable.get(cref,updatedComps);
        checkVariabilityOfUpdatedComponent(variability,cref);
      then (DAE.NOMOD(),DAE.NOMOD(),SCode.NOMOD());

    else (mods,cmod,m);
  end matchcontinue;
end noModForUpdatedComponents;

public function propagateModFinal
  "Takes a component's modifier and final attribute, and return FINAL if either
   of them is final, otherwise NOT_FINAL."
  input DAE.Mod inMod;
  input SCode.Final inFinal;
  output SCode.Final outFinal;
algorithm
  outFinal := match(inMod, inFinal)
    local
      SCode.Final fp;

    // If the component is already final, keep it.
    case (_, SCode.FINAL()) then inFinal;
    // If we got a modifier, use its final prefix instead.
    case (DAE.MOD(finalPrefix = fp), _) then fp;
    // Otherwise, do nothing.
    else inFinal;

  end match;
end propagateModFinal;

//------------------------------
//------  PDE extension:  ------
//------------------------------

public type DomainFieldsLst = list<tuple<DAE.ComponentRef,list<Absyn.ComponentRef>>>;

public function elabField
//For field variables: finds the "domain" modifier,
//finds domain.N - length of discretized field array
//and removes "domain" from the modifiers list.
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String name;
  input SCode.Attributes attr;
  input DAE.Dimensions inDims;
  input DAE.Mod inMod;
  input SourceInfo inInfo;
  output DAE.Dimensions outDims;
  output DAE.Mod outMod;
  output Option<tuple<Absyn.ComponentRef,DAE.ComponentRef>> outFieldDomOpt;

algorithm
  (outDims, outMod, outFieldDomOpt) := match(attr, inMod)
    local
      DAE.Dimension dim_f;
      SCode.Final finalPrefix;
      SCode.Each  eachPrefix;
      list<DAE.SubMod> subModLst;
      Option<DAE.EqMod> binding;
      DAE.SourceInfo info;
      Integer N;
      DAE.ComponentRef dcr;
    case(SCode.ATTR(isField=Absyn.NONFIELD()),_)
      //TODO: check that the domain attribute (modifier) is not present.
      then
        (inDims,inMod,NONE());
    case(SCode.ATTR(isField=Absyn.FIELD()),DAE.MOD(finalPrefix = finalPrefix, eachPrefix = eachPrefix, subModLst = subModLst, binding = binding, info = info))
      equation
//        DAE.MOD(finalPrefix = finalPrefix, eachPrefix = eachPrefix, subModLst = subModLst, eqModOption = eqModOption) = inMod;
        //get N from the domain and remove domain from the subModLst:
        (N, subModLst, SOME(dcr)) = List.fold30(subModLst,domainSearchFun,-1,{},NONE());
        if (N == -1) then Error.addSourceMessageAndFail(Error.PDEModelica_ERROR,
            {"Domain of the field variable '", name, "' not found."}, inInfo);
        end if;
        subModLst = listReverse(subModLst);
        subModLst = List.map(subModLst,addEach);
        outMod = DAE.MOD(finalPrefix, eachPrefix, subModLst, binding, info);
        dim_f = DAE.DIM_INTEGER(N);
      then
        (dim_f::inDims, outMod, SOME((Absyn.CREF_IDENT(name, {}),dcr)));
  end match;
end elabField;

protected function domainSearchFun
"fold function to find domain modifier in modifiers list"
//TODO: simplify this function, perhaps not use fold
  input DAE.SubMod subMod;
  input Integer inN;
  input list<DAE.SubMod> inSubModLst;
  input Option<DAE.ComponentRef> inCrOpt;
  output Integer outN;
  output list<DAE.SubMod> outSubModLst;
  output Option<DAE.ComponentRef> outCrOpt;

  algorithm
    (outSubModLst,outN,outCrOpt) := matchcontinue subMod
    local
      DAE.Mod mod;
      list<DAE.SubMod>  subModLst;
      Option<DAE.EqMod> eqModOption;
//      list<Values.Value> values;
//      list<String> names;
      list<DAE.Var> varLst;
      Integer N;
      DAE.ComponentRef cr;
    case DAE.NAMEMOD(ident="domain", mod=DAE.MOD(binding=SOME(
          DAE.TYPED(
            modifierAsExp=DAE.CREF(
              componentRef = cr,
              ty=DAE.T_COMPLEX(
                complexClassType=ClassInf.RECORD(
                  path=Absyn.FULLYQUALIFIED(
                    path=Absyn.IDENT(name="DomainLineSegment1D")
                  )
                )
              )
            )
          )
        )))
      equation
        DAE.CREF_IDENT(identType = DAE.T_COMPLEX(varLst = varLst)) = cr;
        N = List.findSome(varLst,findN);
      then (inSubModLst,N,SOME(cr));
    case DAE.NAMEMOD(ident="domain")
      equation
        print("cant find N in the domain");
      then
        fail();
    else (subMod::inSubModLst,inN,inCrOpt);
    end matchcontinue;
end domainSearchFun;

protected function findN
"a map function to find N in domain class modifiers"
  input DAE.Var inVar;
  output Option<Integer> optN;
algorithm
  optN := match inVar
    local
      Integer N;
    case DAE.TYPES_VAR(name="N",binding=DAE.EQBOUND(evaluatedExp=SOME(Values.INTEGER(N))))
    then SOME(N);
    else NONE();
  end match;
end findN;

protected function addEach
"map function that adds each prefix to given modifier"
  input DAE.SubMod inSubMod;
  output DAE.SubMod outSubMod;
  protected DAE.Ident ident;
  protected SCode.Final finalPrefix;
  protected SCode.Each eachPrefix;
  protected list<DAE.SubMod> subModLst;
  protected Option<DAE.EqMod> binding;
  protected DAE.SourceInfo info;

/*  equation
    DAE.NAMEMOD(ident, DAE.MOD(finalPrefix, _, subModLst, eqModOption)) = inSubMod;
    outSubMod = DAE.NAMEMOD(ident, DAE.MOD(finalPrefix, SCode.EACH(), subModLst, eqModOption));*/
  algorithm
    outSubMod := match inSubMod
      case DAE.NAMEMOD(ident, DAE.MOD(finalPrefix, _, subModLst, binding, info))
      then DAE.NAMEMOD(ident, DAE.MOD(finalPrefix, SCode.EACH(), subModLst, binding, info));
    end match;
end addEach;

//----end elabField and sub funs

public function optAppendField
  input DomainFieldsLst inDomFieldsLst;
  input Option<tuple<Absyn.ComponentRef,DAE.ComponentRef>> fieldDomOpt;
  output DomainFieldsLst outDomFieldsLst;
algorithm
  outDomFieldsLst := matchcontinue fieldDomOpt
  local
    Absyn.ComponentRef fieldCr;
    DAE.ComponentRef domainCr;
    Boolean found;
    case NONE()
      then inDomFieldsLst;
    case SOME((fieldCr,domainCr))
      equation
        (outDomFieldsLst, found) = List.map2Fold(inDomFieldsLst,optAppendFieldMapFun,domainCr,fieldCr,false);
        if not found then
          outDomFieldsLst = (domainCr,{fieldCr})::inDomFieldsLst;
        end if;
      then
        outDomFieldsLst;
  end matchcontinue;
end optAppendField;

protected function optAppendFieldMapFun
  input tuple<DAE.ComponentRef,List<Absyn.ComponentRef>> inDomainFields;
  input DAE.ComponentRef domainCrToAdd;
  input Absyn.ComponentRef fieldCrToAdd;
  input Boolean inFound;
  output tuple<DAE.ComponentRef,List<Absyn.ComponentRef>> outDomainFields;
  output Boolean outFound;
algorithm
  (outDomainFields, outFound) := matchcontinue (inDomainFields,inFound)
  local
    DAE.ComponentRef domainCr;
    List<Absyn.ComponentRef> fieldCrLst;
  case ((domainCr,fieldCrLst),false)
    equation
      true = ComponentReference.crefEqual(domainCr,domainCrToAdd);
    then
      ((domainCr,fieldCrToAdd::fieldCrLst),true);
    else
      (inDomainFields,inFound);
  end matchcontinue;
end optAppendFieldMapFun;

//----end optAppendField and sub funs

public function discretizePDE
//main discretization function, converts PDE into set of ODEs
  input SCode.Equation inEQ;
  input DomainFieldsLst inDomFieldLst;
//  input list<tuple<String,Integer>> domainNLst;
  input List<SCode.Equation> inDiscretizedEQs;
  output List<SCode.Equation> outDiscretizedEQs;
  protected List<SCode.Equation> newDiscretizedEQs;
algorithm
    newDiscretizedEQs := {inEQ};
    //TODO: fix:

    newDiscretizedEQs := matchcontinue inEQ
      local
        Absyn.Exp lhs_exp, rhs_exp;
        Absyn.ComponentRef domainCr, domainCr1, fieldCr;
        SCode.Comment comment;
        SCode.SourceInfo info;
        Integer N;
        List<Absyn.ComponentRef> fieldLst;
        Absyn.Ident name;
        list<Absyn.Subscript> subscripts;
      //Normal equation withhout domain specified, no field variables present:
      case SCode.EQUATION(SCode.EQ_EQUALS())
      then {inEQ};
      //PDE with domain specified, allow for field variables:
      case SCode.EQUATION(SCode.EQ_PDE(expLeft = lhs_exp, expRight = rhs_exp,
                  domain = domainCr as Absyn.CREF_IDENT(), comment = comment, info = info))
        equation
          (N,fieldLst) = getDomNFields(inDomFieldLst,domainCr,info);
//        then list(newEQFun(i, lhs_exp, rhs_exp, domainCr, comment, info, fieldLst) for i in 2:N-1);
        then creatFieldEqs(lhs_exp, rhs_exp, domainCr, N, comment, info, fieldLst);
      //same as previous but with ".interior"
      case SCode.EQUATION(SCode.EQ_PDE(expLeft = lhs_exp, expRight = rhs_exp,
                  domain = domainCr as Absyn.CREF_QUAL(name, subscripts, Absyn.CREF_IDENT(name="interior")),
                  comment = comment, info = info))
        equation
          domainCr1 = Absyn.CREF_IDENT(name, subscripts);
          (N,fieldLst) = getDomNFields(inDomFieldLst,domainCr1,info);
//        then list(newEQFun(i, lhs_exp, rhs_exp, domainCr1, comment, info, fieldLst) for i in 2:N-1);
        then creatFieldEqs(lhs_exp, rhs_exp, domainCr, N, comment, info, fieldLst);

      //left boundary extrapolation
      case SCode.EQUATION(SCode.EQ_PDE(expLeft = lhs_exp, expRight = rhs_exp,
                  domain = domainCr as Absyn.CREF_QUAL(name, subscripts, Absyn.CREF_IDENT(name="left")),
                  comment = comment, info = info))
        equation
//          Absyn.CALL(function_ = Absyn.CREF_IDENT(name="extrapolateField", subscripts={}), functionArgs = Absyn.FUNCTIONARGS(args = {})) = rhs_exp;
//          Absyn.CREF(fieldCr as Absyn.CREF_IDENT()) = lhs_exp;
          fieldCr = matchExtrapAndField(lhs_exp, rhs_exp);
          domainCr1 = Absyn.CREF_IDENT(name, subscripts);
          (N,fieldLst) = getDomNFields(inDomFieldLst,domainCr1,info);
        then
          {extrapolateFieldEq(false, fieldCr, domainCr1, N, comment, info, fieldLst)};

      //right boundary extrapolation
      case SCode.EQUATION(SCode.EQ_PDE(expLeft = lhs_exp, expRight = rhs_exp,
                  domain = domainCr as Absyn.CREF_QUAL(name, subscripts, Absyn.CREF_IDENT(name="right")),
                  comment = comment, info = info))
        equation
//          Absyn.CALL(function_ = Absyn.CREF_IDENT(name="extrapolateField", subscripts={}), functionArgs = Absyn.FUNCTIONARGS(args = {})) = rhs_exp;
//          Absyn.CREF(fieldCr as Absyn.CREF_IDENT()) = lhs_exp;
          fieldCr = matchExtrapAndField(lhs_exp, rhs_exp);
          domainCr1 = Absyn.CREF_IDENT(name, subscripts);
          (N,fieldLst) = getDomNFields(inDomFieldLst,domainCr1,info);
        then
          {extrapolateFieldEq(true, fieldCr, domainCr1, N, comment, info, fieldLst)};
      //left boundary condition
      case SCode.EQUATION(SCode.EQ_PDE(expLeft = lhs_exp, expRight = rhs_exp,
                  domain = domainCr as Absyn.CREF_QUAL(name, subscripts, Absyn.CREF_IDENT(name="left")),
                  comment = comment, info = info))
        equation
          domainCr1 = Absyn.CREF_IDENT(name, subscripts);
          (N,fieldLst) = getDomNFields(inDomFieldLst,domainCr1,info);
        then
          {newEQFun(1, lhs_exp, rhs_exp, domainCr1, comment, info, fieldLst)};
      //right boundary condition
      case SCode.EQUATION(SCode.EQ_PDE(expLeft = lhs_exp, expRight = rhs_exp,
                  domain = domainCr as Absyn.CREF_QUAL(name, subscripts, Absyn.CREF_IDENT(name="right")),
                  comment = comment, info = info))
        equation
          domainCr1 = Absyn.CREF_IDENT(name, subscripts);
          (N,fieldLst) = getDomNFields(inDomFieldLst,domainCr1,info);
        then
          {newEQFun(N, lhs_exp, rhs_exp, domainCr1, comment, info, fieldLst)};

    end matchcontinue;

  outDiscretizedEQs := listAppend(inDiscretizedEQs, newDiscretizedEQs);
end discretizePDE;

protected function matchExtrapAndField
  input Absyn.Exp lhs_exp;
  input Absyn.Exp rhs_exp;
  output Absyn.ComponentRef fieldCr;
algorithm
  fieldCr := match (lhs_exp, rhs_exp)
    local
      Absyn.ComponentRef fcr;
    case (Absyn.CALL(function_ = Absyn.CREF_IDENT(name="extrapolateField", subscripts={}), functionArgs = Absyn.FUNCTIONARGS(args = {})), Absyn.CREF(fcr as Absyn.CREF_IDENT()))
    then
      fcr;
    case (Absyn.CREF(fcr as Absyn.CREF_IDENT()),Absyn.CALL(function_ = Absyn.CREF_IDENT(name="extrapolateField", subscripts={}), functionArgs = Absyn.FUNCTIONARGS(args = {})))
    then
      fcr;
  end match;

end matchExtrapAndField;

protected function getDomNFields
  input DomainFieldsLst inDomFieldLst;
  input Absyn.ComponentRef inDomainCr;
  input SCode.SourceInfo info;
  output Integer outN;
  output List<Absyn.ComponentRef> outFieldLst;
algorithm
  try
    (outN,outFieldLst) := List.findSome1(inDomFieldLst,domNFieldsFindFun,inDomainCr);
  else
    Error.addSourceMessageAndFail(Error.COMPILER_ERROR,{"There are no fields defined within the domain of this equation."}, info);
  end try;
end getDomNFields;

protected function domNFieldsFindFun
  input tuple<DAE.ComponentRef,List<Absyn.ComponentRef>> inDomFields;
  input Absyn.ComponentRef inDomainCr;
  output Option<tuple<Integer,List<Absyn.ComponentRef>>> outOptNFields;
algorithm
  outOptNFields := matchcontinue inDomFields
  local
    DAE.ComponentRef domainCr;
    List<Absyn.ComponentRef> fieldCrLst;
    list<DAE.Var> varLst;
    Integer N;
    case (domainCr, fieldCrLst)
      equation
      true = absynDAECrefEqualName(inDomainCr,domainCr);
      DAE.CREF_IDENT(identType = DAE.T_COMPLEX(varLst = varLst)) = domainCr;
      N = List.findSome(varLst,findN);
    then
      SOME((N,fieldCrLst));
    else
      NONE();
  end matchcontinue;
end domNFieldsFindFun;

protected function absynDAECrefEqualName
  input Absyn.ComponentRef domainCr1;
  input DAE.ComponentRef domainCr2;
  output Boolean equal;
  protected String name1, name2;
  algorithm
    //TODO: implement
  equal := matchcontinue (domainCr1, domainCr2)
    case (Absyn.CREF_IDENT(name = name1), DAE.CREF_IDENT(ident = name2))
      equation
        true = stringEqual(name1,name2);
    then
      true;
    else
      false;
  end matchcontinue;
end absynDAECrefEqualName;


protected function extrapolateFieldEq
//extrapolateFieldEq(false,lhs_exp, rhs_exp, domainCr1, comment, info, fieldLst)
  input Boolean isRight; //otherwise is left
  input Absyn.ComponentRef fieldCr;
  input Absyn.ComponentRef domainCr;
  input Integer N;
  input SCode.Comment comment;
  input SCode.SourceInfo info;
  input List<Absyn.ComponentRef> fieldLst;
  output SCode.Equation outEQ;
  protected Absyn.Ident name;
  protected list<Absyn.Subscript> subscripts;
  protected Integer i1 = 1, i2 = 2, i3 = 3;
algorithm
  if List.isMemberOnTrue(fieldCr,fieldLst,Absyn.crefEqual) then
    (name, subscripts) := match fieldCr
      case Absyn.CREF_IDENT(name = name, subscripts = subscripts)
      then
        (name, subscripts);
    end match;
     //left eq:   u_1 = 2*u_2 - u_3
     //right eq:  u_N = 2*u_{N-1} - u_{N-2}
    if isRight then
      i1 := N;
      i2 := N - 1;
      i3 := N - 2;
    end if;
    outEQ := SCode.EQUATION(SCode.EQ_EQUALS(Absyn.CREF(Absyn.CREF_IDENT(name, Absyn.SUBSCRIPT(Absyn.INTEGER(i1))::subscripts)),Absyn.BINARY(
               Absyn.BINARY(
                 Absyn.INTEGER(2),
                 Absyn.MUL(),
                 Absyn.CREF(Absyn.CREF_IDENT(name, Absyn.SUBSCRIPT(Absyn.INTEGER(i2))::subscripts))
               ),
               Absyn.SUB(),
               Absyn.CREF(Absyn.CREF_IDENT(name, Absyn.SUBSCRIPT(Absyn.INTEGER(i3))::subscripts))
             ), comment, info));
  else
   fail();
  end if;
end extrapolateFieldEq;

protected function creatFieldEqs "creates list of equations for fields. If the equation contains pder it spans 2:N-1, otherwise 1:N"
  input Absyn.Exp lhs_exp;
  input Absyn.Exp rhs_exp;
  input Absyn.ComponentRef domainCr;
  input Integer N;
  input SCode.Comment comment;
  input SCode.SourceInfo info;
  input List<Absyn.ComponentRef> fieldLst;
  output List<SCode.Equation> outDiscretizedEQs;
  protected Boolean bl, br;
algorithm
  (_,bl) := Absyn.traverseExp(lhs_exp, hasPderTraverseFun, false);
  (_,br) := Absyn.traverseExp(rhs_exp, hasPderTraverseFun, false);
  //outDiscretizedEQs := match (Absyn.traverseExp(lhs_exp, hasPderTraverseFun, false),Absyn.traverseExp(rhs_exp, hasPderTraverseFun, false))
  outDiscretizedEQs := match (bl, br)
    //case ((_,false),(_,false)) //no pder()
    case (false,false) //no pder()
    then
      list(newEQFun(i, lhs_exp, rhs_exp, domainCr, comment, info, fieldLst) for i in 1:N);
    else  //contains some pder()
      list(newEQFun(i, lhs_exp, rhs_exp, domainCr, comment, info, fieldLst) for i in 2:N-1);
  end match;
end creatFieldEqs;

protected function hasPderTraverseFun
  input Absyn.Exp inExp;
  input Boolean inHasPder;
  output Absyn.Exp outExp = inExp;
  output Boolean outHasPder;
algorithm
  outHasPder := match (inExp,inHasPder)
    case (_,true)
      then true;
    case (Absyn.CALL(function_ = Absyn.CREF_IDENT(name="pder")),_)
      then true;
  else false;
  end match;
end hasPderTraverseFun;

protected function newEQFun
  input Integer i;
  input Absyn.Exp inLhs_exp;
  input Absyn.Exp inRhs_exp;
  input Absyn.ComponentRef domainCr;
  input SCode.Comment comment;
  input SCode.SourceInfo info;
  input list<Absyn.ComponentRef> fieldLst;
  output SCode.Equation outEQ;
  protected Absyn.Exp outLhs_exp, outRhs_exp;
algorithm
  (outLhs_exp, _) := Absyn.traverseExpTopDown(inLhs_exp,discretizeTraverseFun,(i,fieldLst,domainCr,info,false));
  (outRhs_exp, _) := Absyn.traverseExpTopDown(inRhs_exp,discretizeTraverseFun,(i,fieldLst,domainCr,info,false));
  outEQ := SCode.EQUATION(SCode.EQ_EQUALS(outLhs_exp, outRhs_exp, comment, info));
end newEQFun;

protected function discretizeTraverseFun
  input Absyn.Exp inExp;
  input tuple<Integer, list<Absyn.ComponentRef>, Absyn.ComponentRef, SCode.SourceInfo,Boolean> inTup;
  output Absyn.Exp outExp;
  output tuple<Integer, list<Absyn.ComponentRef>, Absyn.ComponentRef, SCode.SourceInfo,Boolean> outTup;
  protected Integer i;
//   protected String eqDomainName;
  protected list<Absyn.ComponentRef> fieldLst;
  protected SCode.SourceInfo info;
  protected Boolean skip, failVar;
  protected Absyn.ComponentRef domainCr;
  protected Absyn.Ident domName;
algorithm
  failVar := false;
  (i, fieldLst, domainCr, info, skip) := inTup;
  Absyn.CREF_IDENT(name = domName) := domainCr;
  if skip then
    outExp := inExp;
    outTup := inTup;
    return;
  end if;
  outExp := matchcontinue inExp
    local
      Absyn.Ident name, fieldDomainName;
      list<Absyn.Subscript> subscripts;
      Absyn.ComponentRef fieldCr;
    case  Absyn.CREF(Absyn.CREF_QUAL(name = domName, subscripts = {}, componentRef=Absyn.CREF_IDENT(name="x",subscripts={})))
    //coordinate x
    then
      Absyn.CREF(Absyn.CREF_QUAL(name = domName, subscripts = {}, componentRef=Absyn.CREF_IDENT(name="x",subscripts = {Absyn.SUBSCRIPT(Absyn.INTEGER(i))})));
    case Absyn.CREF(fieldCr as Absyn.CREF_IDENT(name, subscripts))
    //field
      equation
        true = List.isMemberOnTrue(fieldCr,fieldLst,Absyn.crefEqual);
      then
        Absyn.CREF(Absyn.CREF_IDENT(name, Absyn.SUBSCRIPT(Absyn.INTEGER(i))::subscripts));
    case Absyn.CALL(Absyn.CREF_IDENT("pder",subscripts),Absyn.FUNCTIONARGS({Absyn.CREF(fieldCr as Absyn.CREF_IDENT(name, subscripts)),Absyn.CREF(Absyn.CREF_IDENT(name="x"))},_))
    //pder
      equation
        if not List.isMemberOnTrue(fieldCr,fieldLst,Absyn.crefEqual) then
          failVar = true;
          Error.addSourceMessageAndFail(Error.COMPILER_ERROR,{"Field variable '" +  name + "' has different domain than the equation or is not a field." }, info);
        end if;
          skip = true;
        then
          Absyn.BINARY(
            Absyn.BINARY(
              Absyn.CREF(Absyn.CREF_IDENT(name, Absyn.SUBSCRIPT(Absyn.INTEGER(i+1))::subscripts)),
              Absyn.SUB(),
              Absyn.CREF(Absyn.CREF_IDENT(name, Absyn.SUBSCRIPT(Absyn.INTEGER(i-1))::subscripts))
            ),
            Absyn.DIV(),
            Absyn.BINARY(
              Absyn.INTEGER(2),
              Absyn.MUL(),
              Absyn.CREF(Absyn.CREF_QUAL(domName,{},Absyn.CREF_IDENT("dx",{})))
            )
          );
    case Absyn.CALL(Absyn.CREF_IDENT("pder",subscripts),Absyn.FUNCTIONARGS({Absyn.CREF(_),_},_))
    //pder with differentiating wrt wrong variable
      equation
        Error.addSourceMessageAndFail(Error.COMPILER_ERROR,{"You are differentiating with respect to variable that is not a coordinate."}, info);
      then
        inExp;
    case Absyn.CALL(Absyn.CREF_IDENT("pder",subscripts),Absyn.FUNCTIONARGS({_,_},_))
      equation
        Error.addSourceMessageAndFail(Error.COMPILER_ERROR,{"Unsupported partial derivative."}, info);
      then
        inExp;
      else
        inExp;
  end matchcontinue;
  if failVar then
    fail();
  end if;
  outTup := (i, fieldLst, domainCr, info, skip);
end discretizeTraverseFun;

protected function findDomF<T>
  input tuple<String,T> inTup;
  input String name;
  output Boolean found;
algorithm
  found := matchcontinue inTup
    local String nameLoc;
    case (nameLoc,_)
      equation
        true = stringEqual(nameLoc,name);
    then true;
    else false;
  end matchcontinue;
end findDomF;
/*
public function findDomains
  input SCode.Element el;
  input list<tuple<String,Integer>> domainLstIn;
  output list<tuple<String,Integer>> domainLstOut;
algorithm
//TODO: rewrite to use instantiated domain elements
  domainLstOut := match el
    local
      String name;
      list<SCode.SubMod> subModLst;
      Integer N;
    case SCode.COMPONENT(typeSpec=Absyn.TPATH(path=Absyn.IDENT(name="DomainLineSegment1D")), name = name,
      modifications = SCode.MOD(subModLst = subModLst))
      then
        (name,findDomains1(subModLst))::domainLstIn;
      else
      domainLstIn;
  end match;
end findDomains;


protected function findDomains1
  input list<SCode.SubMod> subModLst;
  output Integer N;
algorithm
  try
    N := match List.find(subModLst,findDomains2)
    local
      Integer n;
    case SCode.NAMEMOD("N",SCode.MOD(binding = SOME(Absyn.INTEGER(n))))
    then
      n;
    end match;
  else
    print("\nError: Variable N not found in the domain.\n");
    fail();
  end try;
end findDomains1;

protected function findDomains2
  input SCode.SubMod subMod;
  output Boolean found;
algorithm
  found := match subMod
    case SCode.NAMEMOD(ident = "N")
      then
        true;
      else
        false;
  end match;
end findDomains2;
*/
annotation(__OpenModelica_Interface="frontend");
end InstUtil;

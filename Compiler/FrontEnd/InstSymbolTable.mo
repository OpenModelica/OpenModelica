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

encapsulated package InstSymbolTable
" file:        InstSymbolTable.mo
  package:     InstSymbolTable
  description: Symboltable for SCodeInst.

  RCS: $Id$

  A symboltable type and utility functions used by SCodeInst.
"

public import Absyn;
public import DAE;
public import InstTypes;
public import SCode;

protected import BaseHashTable;
protected import ComponentReference;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import Graph;
protected import InstUtil;
protected import List;
protected import System;
protected import Util;

public type Element = InstTypes.Element;
public type Equation = InstTypes.Equation;
public type Class = InstTypes.Class;
public type Dimension = InstTypes.Dimension;
public type Binding = InstTypes.Binding;
public type Component = InstTypes.Component;
public type Modifier = InstTypes.Modifier;
public type Prefixes = InstTypes.Prefixes;
public type Prefix = InstTypes.Prefix;
public type SymbolTable = InstSymbolTable.SymbolTable;
public type Key = Absyn.Path;
public type Value = InstTypes.Component;


public type HashTableFunctionsType = tuple<FuncHashKey, FuncKeyEqual, FuncKeyStr, FuncValueStr>;

public type SymbolTable = list<HashTable>;

public type HashTable = tuple<
  array<list<tuple<Key, Integer>>>,
  tuple<Integer, Integer, array<Option<tuple<Key, Value>>>>,
  Integer,
  Integer,
  HashTableFunctionsType
>;

partial function FuncHashKey
  input Key inKey;
  input Integer inMod;
  output Integer outHash;
end FuncHashKey;

partial function FuncKeyEqual
  input Key inKey1;
  input Key inKey2;
  output Boolean outEqual;
end FuncKeyEqual;

partial function FuncKeyStr
  input Key inKey;
  output String outString;
end FuncKeyStr;

partial function FuncValueStr
  input Value inValue;
  output String outString;
end FuncValueStr;

protected function hashFunc
  input Key inKey;
  input Integer inMod;
  output Integer outHash;
protected
  String str;
algorithm
  str := Absyn.pathString(inKey);
  outHash := System.stringHashDjb2Mod(str, inMod);
end hashFunc;

protected constant DAE.Var BUILTIN_TIME_QUANTITY = DAE.TYPES_VAR(
  "quantity", DAE.dummyAttrVar, SCode.PUBLIC(), DAE.T_STRING_DEFAULT,
  DAE.EQBOUND(DAE.SCONST("Time"), NONE(), DAE.C_CONST(),
  DAE.BINDING_FROM_DEFAULT_VALUE()), NONE());

protected constant DAE.Var BUILTIN_TIME_UNIT = DAE.TYPES_VAR(
  "unit", DAE.dummyAttrVar, SCode.PUBLIC(), DAE.T_STRING_DEFAULT,
  DAE.EQBOUND(DAE.SCONST("s"), NONE(), DAE.C_CONST(),
  DAE.BINDING_FROM_DEFAULT_VALUE()), NONE());

protected constant Component BUILTIN_TIME_COMP = InstTypes.TYPED_COMPONENT(
  Absyn.IDENT("time"), DAE.T_REAL({BUILTIN_TIME_QUANTITY, BUILTIN_TIME_UNIT},
  DAE.emptyTypeSource), InstTypes.NO_PREFIXES(), InstTypes.UNBOUND(),
  Absyn.dummyInfo);

public function create
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := createSized(BaseHashTable.defaultBucketSize);
end create;

public function createSized
  input Integer inSize;
  output SymbolTable outSymbolTable;
protected
  HashTable table;
algorithm
  table := BaseHashTable.emptyHashTableWork(inSize,
    (hashFunc, Absyn.pathEqual, Absyn.pathString, InstUtil.printComponent));
  outSymbolTable := {table};
end createSized;

public function build
  input Class inClass;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass)
    local
      SymbolTable symtab;
      Integer comp_size, bucket_size;
      Class cls;

    case (_)
      equation
        // Set the bucket size to the nearest prime of the number of components
        // multiplied with 4/3, to get ~75% occupancy. +1 to make space for time.
        comp_size = InstUtil.countElementsInClass(inClass);
        bucket_size = Util.nextPrime(intDiv((comp_size * 4), 3)) + 1;
        symtab = createSized(bucket_size);
        (cls, symtab) = addClass(inClass, symtab);
        (symtab, _) = addOptionalComponent(Absyn.IDENT("time"),
          BUILTIN_TIME_COMP, NONE(), symtab);
      then
        (cls, symtab);

  end match;
end build;

protected function add
  input Absyn.Path inName;
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
protected
  HashTable ht;
  SymbolTable rest_st;
algorithm
  ht :: rest_st := inSymbolTable;
  ht := BaseHashTable.add((inName, inComponent), ht);
  outSymbolTable := ht :: rest_st;
end add;

protected function addUnique
  input Absyn.Path inName;
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
protected
  HashTable ht;
  SymbolTable rest_st;
algorithm
  ht :: rest_st := inSymbolTable;
  ht := BaseHashTable.addUnique((inName, inComponent), ht);
  outSymbolTable := ht :: rest_st;
end addUnique;

protected function addNoUpdCheck
  input Absyn.Path inName;
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
protected
  HashTable ht;
  SymbolTable rest_st;
algorithm
  ht :: rest_st := inSymbolTable;
  ht := BaseHashTable.addNoUpdCheck((inName, inComponent), ht);
  outSymbolTable := ht :: rest_st;
end addNoUpdCheck;

protected function get
  input Absyn.Path inName;
  input SymbolTable inSymbolTable;
  output Component outComponent;
algorithm
  outComponent := matchcontinue(inName, inSymbolTable)
    local
      HashTable ht;
      SymbolTable rest_st;

    case (_, ht :: rest_st) then BaseHashTable.get(inName, ht);
    case (_, _ :: rest_st) then get(inName, rest_st);
    
  end matchcontinue;
end get;

public function addClass
  input Class inClass;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inSymbolTable)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;
      SymbolTable st;

    case (InstTypes.BASIC_TYPE(), st) then (inClass, st);

    case (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), st)
      equation
        (comps, st) = addElements(comps, st);
      then
        (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), st);

  end match;
end addClass;

public function addElements
  input list<Element> inElements;
  input SymbolTable inSymbolTable;
  output list<Element> outElements;
  output SymbolTable outSymbolTable;
algorithm
  (outElements, outSymbolTable) :=
    addElements2(inElements, inSymbolTable, {});
end addElements;

protected function addElements2
  input list<Element> inElements;
  input SymbolTable inSymbolTable;
  input list<Element> inAccumEl;
  output list<Element> outElements;
  output SymbolTable outSymbolTable;
algorithm
  (outElements, outSymbolTable) := match(inElements, inSymbolTable, inAccumEl)
    local
      Element el;
      list<Element> rest_el, accum_el;
      Boolean added;
      SymbolTable st;

    case ({}, st, _) then (inAccumEl, st);

    case (el :: rest_el, st, _)
      equation
        (el, st, added) = addElement(el, st);
        accum_el = List.consOnTrue(added, el, inAccumEl);
        (rest_el, st) = addElements2(rest_el, st, accum_el);
      then
        (rest_el, st);

  end match;
end addElements2;

public function addElement
  input Element inElement;
  input SymbolTable inSymbolTable;
  output Element outElement;
  output SymbolTable outSymbolTable;
  output Boolean outAdded;
algorithm
  (outElement, outSymbolTable, outAdded) := matchcontinue(inElement, inSymbolTable)
    local
      Component comp;
      Class cls;
      SymbolTable st;
      Boolean added;
      Absyn.Path bc;
      DAE.Type ty;

    case (InstTypes.ELEMENT(comp, cls), st)
      equation
        (st, added) = addComponent(comp, st);
        (cls, st) = addClassOnTrue(cls, st, added);
      then
        (InstTypes.ELEMENT(comp, cls), st, added);

    case (InstTypes.CONDITIONAL_ELEMENT(comp), st)
      equation
        (st, added) = addComponent(comp, st);
      then
        (InstTypes.CONDITIONAL_ELEMENT(comp), st, added);

    case (InstTypes.EXTENDED_ELEMENTS(bc, cls, ty), st)
      equation
        (cls, st) = addClass(cls, st);
      then
        (InstTypes.EXTENDED_ELEMENTS(bc, cls, ty), st, true);

  end matchcontinue;
end addElement;

public function addClassOnTrue
  input Class inClass;
  input SymbolTable inSymbolTable;
  input Boolean inCondition;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inSymbolTable, inCondition)
    local
      Class cls;
      SymbolTable st;

    case (cls, st, false) then (cls, st);
    case (cls, st, true)
      equation
        (cls, st) = addClass(cls, st);
      then
        (cls, st);

  end match;
end addClassOnTrue;

public function addComponent
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
  output Boolean outAdded;
algorithm
  (outSymbolTable, outAdded) := matchcontinue(inComponent, inSymbolTable) 
    local
      Absyn.Path name;
      Option<Component> comp;
      SymbolTable st;
      Boolean added;

    case (InstTypes.PACKAGE(name = _), st)
      then (st, true);

    case (_, st)
      equation
        name = InstUtil.getComponentName(inComponent);
        comp = lookupNameOpt(name, st);
        (st, added) = addOptionalComponent(name, inComponent, comp, st);
      then
        (st, added);

    else
      equation
        print("InstSymbolTable.addComponent failed!\n");
      then
        (inSymbolTable, false);

  end matchcontinue;
end addComponent;

protected function addOptionalComponent
  input Absyn.Path inName;
  input Component inNewComponent;
  input Option<Component> inOldComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
  output Boolean outAdded;
algorithm
  (outSymbolTable, outAdded) :=
  match(inName, inNewComponent, inOldComponent, inSymbolTable)
    local
      Component comp;
      SymbolTable st;

    case (_, comp, NONE(), st)
      equation
        st = addNoUpdCheck(inName, comp, st);
      then
        (st, true);

    case (_, _, SOME(comp), st)
      equation
        //checkEqualComponents
      then
        (inSymbolTable, false);

  end match;
end addOptionalComponent;

public function addIterator
  input Absyn.Path inName;
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := matchcontinue(inName, inComponent, inSymbolTable)
    local
      HashTable ht;
      SymbolTable st;
      
    case (_, _, _ :: _ :: _)
      then addUnique(inName, inComponent, inSymbolTable);

    else
      equation
        ht = BaseHashTable.emptyHashTableWork(11,
          (hashFunc, Absyn.pathEqual, Absyn.pathString, InstUtil.printComponent));
        st = ht :: inSymbolTable;
        st = add(inName, inComponent, st);
      then
        st;

  end matchcontinue;
end addIterator;

public function updateComponent
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := matchcontinue(inComponent, inSymbolTable)
    local
      Absyn.Path name;
      SymbolTable st;

    case (_, st)
      equation
        name = InstUtil.getComponentName(inComponent);
        st = add(name, inComponent, st);
      then
        st;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- InstSymbolTable.updateComponent failed.");
      then
        fail();

  end matchcontinue;
end updateComponent;

public function addInstCondElement
  input Element inElement;
  input SymbolTable inSymbolTable;
  output Element outElement;
  output SymbolTable outSymbolTable;
  output Boolean outAdded;
algorithm
  (outElement, outSymbolTable, outAdded) := match(inElement, inSymbolTable)
    local
      Component comp;
      Class cls;
      Absyn.Path name;
      Option<Component> opt_comp;
      Boolean added;
      SymbolTable st;

    case (InstTypes.ELEMENT(comp, cls), st)
      equation
        name = InstUtil.getComponentName(comp);
        opt_comp = lookupNameOpt(name, st);
        (st, added) = addInstCondComponent(name, comp, opt_comp, st);
        (cls, st) = addClassOnTrue(cls, st, added);
      then
        (InstTypes.ELEMENT(comp, cls), st, added);

  end match;
end addInstCondElement;
    
protected function addInstCondComponent
  input Absyn.Path inName;
  input Component inNewComponent;
  input Option<Component> inOldComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
  output Boolean outAdded;
algorithm
  (outSymbolTable, outAdded) :=
  match(inName, inNewComponent, inOldComponent, inSymbolTable)
    local
      Component comp;
      SymbolTable st;

    case (_, _, SOME(InstTypes.CONDITIONAL_COMPONENT(name = _)), st)
      equation
        st = addNoUpdCheck(inName, inNewComponent, st);
      then
        (st, true);

    case (_, _, SOME(comp), st)
      equation
        //checkEqualComponents
      then
        (st, false);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"InstSymbolTable.addInstCondElement couldn't find existing conditional component!\n"});
      then
        fail();
  end match;
end addInstCondComponent;

public function lookupCref
  input DAE.ComponentRef inCref;
  input SymbolTable inSymbolTable;
  output Component outComponent;
protected
  Absyn.Path path;
algorithm
  path := ComponentReference.crefToPathIgnoreSubs(inCref);
  outComponent := get(path, inSymbolTable);
end lookupCref;

public function lookupName
  input Absyn.Path inName;
  input SymbolTable inSymbolTable;
  output Component outComponent;
algorithm
  outComponent := get(inName, inSymbolTable);
end lookupName;

public function lookupNameOpt
  input Absyn.Path inName;
  input SymbolTable inSymbolTable;
  output Option<Component> outComponent;
algorithm
  outComponent := matchcontinue(inName, inSymbolTable)
    local
      Component comp;

    case (_, _)
      equation
        comp = get(inName, inSymbolTable);
      then
        SOME(comp);

    else NONE();
  end matchcontinue;
end lookupNameOpt;

public function updateInnerReference
  input Component inOuterComponent;
  input SymbolTable inSymbolTable;
  output Absyn.Path outInnerName;
  output Option<Component> outInnerComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outInnerName, outInnerComponent, outSymbolTable) :=
  match(inOuterComponent, inSymbolTable)
    local
      Absyn.Path outer_name, inner_name;
      Component outer_comp, inner_comp;
      SymbolTable st;

    case (InstTypes.OUTER_COMPONENT(name = outer_name, innerName = NONE()), st)
      equation
        (inner_name, inner_comp) = findInnerComponent(outer_name, st); 
        outer_comp = InstTypes.OUTER_COMPONENT(outer_name, SOME(inner_name));
        st = add(outer_name, outer_comp, st);
      then
        (inner_name, SOME(inner_comp), st);
        
    case (InstTypes.OUTER_COMPONENT(innerName = SOME(inner_name)), st)
      then (inner_name, NONE(), st);

  end match;
end updateInnerReference;

protected function findInnerComponent
  input Absyn.Path inOuterName;
  input SymbolTable inSymbolTable;
  output Absyn.Path outInnerName;
  output Component outInnerComponent;
algorithm
  (outInnerName, outInnerComponent) := matchcontinue(inOuterName, inSymbolTable)
    local
      list<String> pathl;
      String comp_name;
      Absyn.Path prefix, inner_name, path;
      Component comp;

    case (_, _)
      equation
        pathl = Absyn.pathToStringList(inOuterName);
        comp_name :: _ :: pathl = listReverse(pathl);
        (inner_name, comp) = findInnerComponent2(comp_name, pathl, inSymbolTable);
      then
        (inner_name, comp);

    case (Absyn.IDENT(name = _), _)
      equation
        print("Outer component at top level\n");
      then
        fail();

    else
      equation
        print("Couldn't find corresponding inner component for " +&
            Absyn.pathString(inOuterName) +& "\n");
      then
        fail();

  end matchcontinue;
end findInnerComponent;

protected function findInnerComponent2
  input String inComponentName;
  input list<String> inPrefix;
  input SymbolTable inSymbolTable;
  output Absyn.Path outInnerPath;
  output Component outInnerComponent;
algorithm
  (outInnerPath, outInnerComponent) :=
  matchcontinue(inComponentName, inPrefix, inSymbolTable)
    local
      list<String> pathl;
      Absyn.Path path;
      Component comp;

    case (_, {}, _)
      equation
        path = Absyn.IDENT(inComponentName);
        comp = get(path, inSymbolTable);
        true = InstUtil.isInnerComponent(comp);
      then
        (path, comp);

    case (_, _ :: _, _)
      equation
        pathl = inComponentName :: inPrefix;
        path = Absyn.stringListPathReversed(pathl);
        comp = get(path, inSymbolTable);
        true = InstUtil.isInnerComponent(comp);
      then
        (path, comp);
        
    case (_, _ :: pathl, _)
      equation
        (path, comp) = findInnerComponent2(inComponentName, pathl, inSymbolTable);
      then
        (path, comp);

  end matchcontinue;
end findInnerComponent2;

public function showCyclicDepError
  input SymbolTable inSymbolTable;
algorithm
  _ := matchcontinue(inSymbolTable)
    local
      list<DAE.Exp> deps;
      String dep_str;

    case (_)
      equation
        deps = findCyclicDependencies(inSymbolTable);
        dep_str = 
          stringDelimitList(List.map(deps, ExpressionDump.printExpStr), ", ");
        dep_str = "{" +& dep_str +& "}";
        // TODO: The "in scope" part of this error message should be removed, since
        // we check for global cycles and not scope-local cycles like the old Inst.
        Error.addMessage(Error.CIRCULAR_COMPONENTS, {"", dep_str});
      then
        ();

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Found cyclic dependencies, but failed to show error."});
      then
        fail();
  
  end matchcontinue;
end showCyclicDepError;

protected function findCyclicDependencies
  input SymbolTable inSymbolTable;
  output list<DAE.Exp> outDeps;
protected
  list<tuple<Absyn.Path, Component>> hash_list;
  list<tuple<DAE.Exp, list<DAE.Exp>>> dep_graph;
  list<DAE.Exp> deps;
  HashTable ht;
algorithm
  ht :: _ := inSymbolTable;
  hash_list := BaseHashTable.hashTableList(ht);
  dep_graph := buildDependencyGraph(hash_list, {});
  (_, dep_graph) := Graph.topologicalSort(dep_graph, nodeEqual);
  {outDeps} := Graph.findCycles(dep_graph, nodeEqual);
end findCyclicDependencies;
  
protected function buildDependencyGraph
  input list<tuple<Absyn.Path, Component>> inComponents;
  input list<tuple<DAE.Exp, list<DAE.Exp>>> inAccumGraph;
  output list<tuple<DAE.Exp, list<DAE.Exp>>> outGraph;
algorithm
  outGraph := match(inComponents, inAccumGraph)
    local
      list<tuple<Absyn.Path, Component>> rest_comps;
      list<tuple<DAE.Exp, list<DAE.Exp>>> accum;
      Binding binding;
      array<Dimension> dims;
      list<Dimension> dimsl;
      Absyn.Path name;

    case ({}, _) then inAccumGraph;

    case ((name, InstTypes.UNTYPED_COMPONENT(binding = binding, dimensions = dims)) ::
        rest_comps, accum)
      equation
        accum = addBindingDependency(binding, name, accum);
        dimsl = arrayList(dims);
        //accum = List.fold(dimsl, addDimensionDependency, accum);
        accum = buildDependencyGraph(rest_comps, accum);
      then
        accum;

    case (_ :: rest_comps, accum)
      then buildDependencyGraph(rest_comps, accum);

  end match;
end buildDependencyGraph;
  
public function addBindingDependency
  input Binding inBinding;
  input Absyn.Path inComponentName;
  input list<tuple<DAE.Exp, list<DAE.Exp>>> inAccumGraph;
  output list<tuple<DAE.Exp, list<DAE.Exp>>> outGraph;
algorithm
  outGraph := match(inBinding, inComponentName, inAccumGraph)
    local
      DAE.Exp bind_exp;
      list<DAE.Exp> deps;
      DAE.ComponentRef cref;
      tuple<DAE.Exp, list<DAE.Exp>> dep;

    case (InstTypes.UNTYPED_BINDING(bindingExp = bind_exp, isProcessing = true), _, _)
      equation
        deps = getDependenciesFromExp(bind_exp);
        cref = ComponentReference.pathToCref(inComponentName);
        dep = (DAE.CREF(cref, DAE.T_UNKNOWN_DEFAULT), deps);
      then
        dep :: inAccumGraph;

    else inAccumGraph;
  end match;
end addBindingDependency;

protected function getDependenciesFromExp
  input DAE.Exp inExp;
  output list<DAE.Exp> outDeps;
algorithm
  ((_, outDeps)) := Expression.traverseExp(inExp, expDependencyTraverser, {});
end getDependenciesFromExp;

protected function expDependencyTraverser
  input tuple<DAE.Exp, list<DAE.Exp>> inTuple;
  output tuple<DAE.Exp, list<DAE.Exp>> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      DAE.Exp exp;
      list<DAE.Exp> deps;

    case ((exp as DAE.CREF(componentRef = _), deps))
      then ((exp, exp :: deps));

    else inTuple;

  end match;
end expDependencyTraverser;

protected function nodeEqual
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match(inExp1, inExp2)
    local
      DAE.ComponentRef cref1, cref2;

    case (DAE.CREF(componentRef = cref1), DAE.CREF(componentRef = cref2))
      then ComponentReference.crefEqualNoStringCompare(cref1, cref2);

    else false;

  end match;
end nodeEqual;

public function dumpSymbolTableKeys
  input SymbolTable inSymbolTable;
algorithm
  _ := matchcontinue(inSymbolTable)
    local
      list<Absyn.Path> keys;
      HashTable ht;
      SymbolTable rest_st;

    case (ht :: rest_st)
      equation
        keys = BaseHashTable.hashTableKeyList(ht);
        print(stringDelimitList(List.map(keys, Absyn.pathString), "\n") +& "\n");
        dumpSymbolTableKeys(rest_st);
      then
        ();

    else ();
  end matchcontinue;
end dumpSymbolTableKeys;
  
end InstSymbolTable;

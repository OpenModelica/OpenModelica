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

protected import BaseHashTable;
protected import ComponentReference;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import Graph;
protected import InstDump;
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
public type Statement = InstTypes.Statement;
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
  "quantity", DAE.dummyAttrVar, DAE.T_STRING_DEFAULT,
  DAE.EQBOUND(DAE.SCONST("Time"), NONE(), DAE.C_CONST(),
  DAE.BINDING_FROM_DEFAULT_VALUE()), NONE());

protected constant DAE.Var BUILTIN_TIME_UNIT = DAE.TYPES_VAR(
  "unit", DAE.dummyAttrVar, DAE.T_STRING_DEFAULT,
  DAE.EQBOUND(DAE.SCONST("s"), NONE(), DAE.C_CONST(),
  DAE.BINDING_FROM_DEFAULT_VALUE()), NONE());

protected constant Component BUILTIN_TIME_COMP = InstTypes.TYPED_COMPONENT(
  Absyn.IDENT("time"), DAE.T_REAL({BUILTIN_TIME_QUANTITY, BUILTIN_TIME_UNIT},
  DAE.emptyTypeSource), InstTypes.NO_DAE_PREFIXES(), InstTypes.UNBOUND(),
  Absyn.dummyInfo);

public function create
  "Creates an empty symboltable with a default bucket size."
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := createSized(BaseHashTable.defaultBucketSize);
end create;

public function createSized
  "Creates an empty symboltable of the given size."
  input Integer inSize;
  output SymbolTable outSymbolTable;
protected
  HashTable table;
algorithm
  table := BaseHashTable.emptyHashTableWork(inSize,
    (hashFunc, Absyn.pathEqual, Absyn.pathString, InstDump.componentStr));
  outSymbolTable := {table};
end createSized;

public function build
  "Creates a new symboltable and populates it with the elements from a given
   class. Duplicate elements from extends are removed during this phase, so the
   class with the duplicate elements removed is returned along with the new
   symboltable."
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
        // Add the special variable time to the symboltable.
        (symtab, _) = addOptionalComponent(Absyn.IDENT("time"),
          BUILTIN_TIME_COMP, NONE(), symtab);
      then
        (cls, symtab);

  end match;
end build;

protected function add
  "Adds a component to the symboltable, or updates an already existing component."
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
  "Adds a component to the symboltable. Fails if the component is already
   present in the symboltable."
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
  "Adds a component to the symboltable, without checking if it already exists.
   This makes this function more efficient than add if you already know that the
   component hasn't been added to the symboltable already."
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
  "Fetches a component from the symboltable based on it's name."
  input Absyn.Path inName;
  input SymbolTable inSymbolTable;
  output Component outComponent;
algorithm
  outComponent := matchcontinue(inName, inSymbolTable)
    local
      HashTable ht;
      SymbolTable rest_st;

    // Search the first scope.
    case (_, ht :: rest_st) then BaseHashTable.get(inName, ht);
    // Search the next scope if it wasn't found in the first.
    case (_, _ :: rest_st) then get(inName, rest_st);
    
  end matchcontinue;
end get;

public function addClass
  "Adds the elements of a given class to the symboltable."
  input Class inClass;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inSymbolTable)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      list<list<Statement>> al, ial;
      SymbolTable st;

    // A basic type doesn't have any elements, nothing to add.
    case (InstTypes.BASIC_TYPE(), st) then (inClass, st);

    // A complex class, add it's elements to the symboltable.
    case (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), st)
      equation
        (comps, st) = addElements(comps, st);
      then
        (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), st);

  end match;
end addClass;

public function addElements
  "Adds a list of elements to the symboltable. Returns a list of the elements
   that was added to the symboltable, with duplicate elements from extends
   removed, as well as the updated symboltable."
  input list<Element> inElements;
  input SymbolTable inSymbolTable;
  output list<Element> outElements;
  output SymbolTable outSymbolTable;
algorithm
  (outElements, outSymbolTable) :=
    addElements2(inElements, inSymbolTable, {});
end addElements;

protected function addElements2
  "Tail-recursive implementation of addElements."
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
        // Try to add the element to the symboltable.
        (el, st, added) = addElement(el, st);
        // Add the element to the accumulation list if it was added.
        accum_el = List.consOnTrue(added, el, inAccumEl);
        // Add the rest of the elements.
        (rest_el, st) = addElements2(rest_el, st, accum_el);
      then
        (rest_el, st);

  end match;
end addElements2;

public function addElement
  "Adds an element to the symboltable. Returns the element with duplicate
   elements from extends removed, the updated symboltable and a boolean which
   tells if the element was added to the symboltable or not."
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
        // Try to add the component.
        (st, added) = addComponent(comp, st);
        // Add the component's class if the component was added.
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
  "If the condition is true, adds the given class to the symboltable. Otherwise
   does nothing."
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
  "Tries to add a component to the symboltable. Returns the updated symboltable
   and a boolean which tells whether the component was added or not."
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
      HashTable scope;

    // PACKAGE isn't really a component, so we don't add it. But it's class
    // should be added, so return true anyway.
    case (InstTypes.PACKAGE(name = _), st)
      then (st, true);

    // For any other type of component, try to add it.
    case (_, st as scope::_)
      equation
        // Try to find the component in the symboltable.
        name = InstUtil.getComponentName(inComponent);
        comp = lookupNameOpt(name, {scope});
        // Let addOptionalComponent handle the rest.
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
  "Adds a component to the symboltable, if it doesn't already exist in the
   symboltable. This is indicated by inOldComponent, which is NONE if it doesn't
   already exist, otherwise SOME."
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

    // The component doesn't already exist, add it to the symboltable.
    case (_, comp, NONE(), st)
      equation
        st = addNoUpdCheck(inName, comp, st);
      then
        (st, true);

    // The component already exists. Check that it's equivalent with the old
    // component, and return the symboltable unchanged.
    case (_, _, SOME(comp), st)
      equation
        //checkEqualComponents
      then
        (inSymbolTable, false);

  end match;
end addOptionalComponent;

public function addIterator
  "Opens a new scope, or reuses an old iterator scope, and adds the given
  component to that scope. This is used for e.g. adding for loop iterators."
  input Absyn.Path inName;
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := matchcontinue(inName, inComponent, inSymbolTable)
    local
      HashTable ht;
      SymbolTable st;
      
    // The symboltable consists of at least two scopes, try to add the component
    // to the symboltable with addUnique. This means that we reuse iterator
    // scopes as long as we don't get any conflicting iterator names, to avoid
    // having a lot of unnecessary scopes.
    case (_, _, _ :: _ :: _)
      then addUnique(inName, inComponent, inSymbolTable);

    // If the previous case failed, add a new scope and add the component to it.
    else
      equation
        ht = BaseHashTable.emptyHashTableWork(11,
          (hashFunc, Absyn.pathEqual, Absyn.pathString, InstDump.componentStr));
        st = ht :: inSymbolTable;
        st = add(inName, inComponent, st);
      then
        st;

  end matchcontinue;
end addIterator;

public function addFunctionScope
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
protected
  HashTable ht;
algorithm
  ht := BaseHashTable.emptyHashTableWork(257,
    (hashFunc, Absyn.pathEqual, Absyn.pathString, InstDump.componentStr));
  outSymbolTable := ht :: inSymbolTable;
end addFunctionScope;

public function updateComponent
  "Updates a component in the symboltable, or adds the component if it doesn't
   already exists."
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
  "Adds an instantiated conditional elements to the symboltable. Returns the
   element with any duplicate elements from extends removed, the updated
   symboltable and a boolean which tells if the element was added or not."
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
        // Look up the component in the symboltable.
        name = InstUtil.getComponentName(comp);
        opt_comp = lookupNameOpt(name, st);
        // Try to add the component to the symboltable.
        (st, added) = addInstCondComponent(name, comp, opt_comp, st);
        // Add the element's class if the component was added.
        (cls, st) = addClassOnTrue(cls, st, added);
      then
        (InstTypes.ELEMENT(comp, cls), st, added);

  end match;
end addInstCondElement;
    
protected function addInstCondComponent
  "Adds an instantiated conditional component to the symboltable. inOldComponent
   is optionally the already existing component, or NONE if the component didn't
   already exist."
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

    // The component already exists in the symboltable as a conditional
    // component, in which case we should replace it with the instantiated
    // component.
    case (_, _, SOME(InstTypes.CONDITIONAL_COMPONENT(name = _)), st)
      equation
        st = addNoUpdCheck(inName, inNewComponent, st);
      then
        (st, true);

    // The component already exists in the symboltable, but not as a conditional
    // component. This means that it's already been updated due to a duplicate
    // element from an extends. In that case we should make sure that the new
    // component is equivalent to the old one, and return the symboltable
    // unchagned.
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
  "Looks up a component reference in the symboltable and returns the referenced
   component. Note that subscripts are ignored."
  input DAE.ComponentRef inCref;
  input SymbolTable inSymbolTable;
  output Component outComponent;
protected
  Absyn.Path path;
algorithm
  path := ComponentReference.crefToPathIgnoreSubs(inCref);
  outComponent := get(path, inSymbolTable);
end lookupCref;

public function lookupCrefResolveOuter
  "Looks up a component reference in the symboltable and returns the referenced
   component. It also resolves outer references, so that in the case of an outer
   reference the inner component is returned."
  input DAE.ComponentRef inCref;
  input SymbolTable inSymbolTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) := matchcontinue(inCref, inSymbolTable)
    local
      Component comp;
      SymbolTable st;
      DAE.ComponentRef cref;

    // Try to find the cref as a normal component.
    case (_, st)
      equation
        comp = lookupCref(inCref, st);
      then
        (comp, st);

    // Previous case failed, try to look it up as an outer reference.
    else 
      equation
        (cref, st) = InstUtil.replaceCrefOuterPrefix(inCref, inSymbolTable);
        comp = lookupCref(cref, st);
      then
        (comp, st);

  end matchcontinue;
end lookupCrefResolveOuter;

public function lookupName
  "Looks up a name in the symboltable."
  input Absyn.Path inName;
  input SymbolTable inSymbolTable;
  output Component outComponent;
algorithm
  outComponent := get(inName, inSymbolTable);
end lookupName;

public function lookupNameOpt
  "Looks up a name in the symboltable. Return SOME if the component could be
   found, otherwise NONE."
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

public function resolveOuterRef
  "Returns the inner component referenced by an outer component. Only works if
  the outer component has an inner reference, i.e. after typing."
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output Component outComponent;
algorithm
  outComponent := match(inComponent, inSymbolTable)
    local
      Absyn.Path path;

    case (InstTypes.OUTER_COMPONENT(innerName = SOME(path)), _)
      then lookupName(path, inSymbolTable);

    else inComponent;
  end match;
end resolveOuterRef;

public function updateInnerReference
  "Updates the reference to an inner component for an outer component. Returns
  the name of the inner component, the inner component itself if the inner
  reference was updated, and the updated symboltable."
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

    // No inner reference set, find the inner component and set the reference.
    case (InstTypes.OUTER_COMPONENT(name = outer_name, innerName = NONE()), st)
      equation
        (inner_name, inner_comp) = findInnerComponent(outer_name, st); 
        outer_comp = InstTypes.OUTER_COMPONENT(outer_name, SOME(inner_name));
        st = add(outer_name, outer_comp, st);
      then
        (inner_name, SOME(inner_comp), st);
        
    // Reference already set, just return the name of it.
    case (InstTypes.OUTER_COMPONENT(innerName = SOME(inner_name)), st)
      then (inner_name, NONE(), st);

  end match;
end updateInnerReference;

protected function findInnerComponent
  "Finds the corresponding inner component for an outer component in the
   symboltable, and returns the name and component for the inner component."
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

    // Try to find the inner component in the symboltable.
    case (_, _)
      equation
        // Split the name into a list of strings.
        pathl = Absyn.pathToStringList(inOuterName);
        // Reverse the list. The first element is now the component's name, the
        // rest is the enclosing scopes in the instance hierarchy. We ignore the
        // first scope, since otherwise we'll just find the outer component again.
        comp_name :: _ :: pathl = listReverse(pathl);
        (inner_name, comp) = findInnerComponent2(comp_name, pathl, inSymbolTable);
      then
        (inner_name, comp);

    // A non-qualified name means that the outer component is at the top level,
    // so no inner component can exist. When checking a model we should somehow
    // add dummy inner components, otherwise this is an error.
    case (Absyn.IDENT(name = _), _)
      equation
        print("Outer component at top level\n");
      then
        fail();

    // Couldn't find the inner component, print an error.
    else
      equation
        print("Couldn't find corresponding inner component for " +&
            Absyn.pathString(inOuterName) +& "\n");
      then
        fail();

  end matchcontinue;
end findInnerComponent;

protected function findInnerComponent2
  "Helper function to findInnerComponent. Tries to find an inner component with
   the name inComponentName and a subprefix of inPrefix. The search is done by
   shortening the prefix until a match is found or the search fails. E.g. for an
   outer component a.b.c.d we will search for a.b.d, a.d and d, until we find an
   inner component."
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

    // Empty prefix, see if there's an inner component with a non-qualified name.
    case (_, {}, _)
      equation
        path = Absyn.IDENT(inComponentName);
        comp = get(path, inSymbolTable);
        true = InstUtil.isInnerComponent(comp);
      then
        (path, comp);

    // Some prefix, join the prefix with the component name and see if it
    // corresponds to an inner component.
    case (_, _ :: _, _)
      equation
        pathl = inComponentName :: inPrefix;
        path = Absyn.stringListPathReversed(pathl);
        comp = get(path, inSymbolTable);
        // TODO: If we find a component with this name that's not inner, is that
        // an error?
        true = InstUtil.isInnerComponent(comp);
      then
        (path, comp);
        
    // Previous case failed, but we have some prefix. Remove the first part of
    // the prefix and try again.
    case (_, _ :: pathl, _)
      equation
        (path, comp) = findInnerComponent2(inComponentName, pathl, inSymbolTable);
      then
        (path, comp);

  end matchcontinue;
end findInnerComponent2;

public function showCyclicDepError
  "Used to print an error message in case we detect any cyclic dependencies
   during typing."
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
  "Helper function to showCyclicDepError. Uses the graph algorithms to find all
   expressions that are cyclically dependent."
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
  "Helper function to findCyclicDependencies. Used to build the dependency graph."
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
  "Helper function to buildDependencyGraph. Adds a dependency for a binding."
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
  "Helper function to addBindingDependency. Extracts all dependencies from an
   expression."
  input DAE.Exp inExp;
  output list<DAE.Exp> outDeps;
algorithm
  ((_, outDeps)) := Expression.traverseExp(inExp, expDependencyTraverser, {});
end getDependenciesFromExp;

protected function expDependencyTraverser
  "Traversal function used by getDependenciesFromExp."
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
  "Checks if two nodes in the dependency graph are equal."
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
  "Prints all keys in the symboltable to the standard output."
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
  
public function dumpSymbolTable
  "Prints the symboltable to standard output."
  input SymbolTable inSymbolTable;
algorithm
  _ := match(inSymbolTable)
    local
      HashTable ht;
      SymbolTable rest_st;

    case (ht :: rest_st)
      equation
        print("SymbolTable: ");
        BaseHashTable.dumpHashTable(ht);
        dumpSymbolTable(rest_st);
      then
        ();

    else ();
  end match;
end dumpSymbolTable;

end InstSymbolTable;

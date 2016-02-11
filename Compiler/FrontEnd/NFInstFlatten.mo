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

encapsulated package NFInstFlatten
" file:        NFInstFlatten.mo
  package:     NFInstFlatten
  description: Functionality for flattening the instantiated structure.



"

public import Absyn;
public import NFInstTypes;

protected import BaseHashTable;
protected import DAE;
protected import Debug;
protected import Flags;
protected import NFInstDump;
protected import NFInstUtil;
protected import List;
protected import System;
protected import Types;
protected import Util;

public type Element = NFInstTypes.Element;
public type Equation = NFInstTypes.Equation;
public type Class = NFInstTypes.Class;
public type Dimension = NFInstTypes.Dimension;
public type Binding = NFInstTypes.Binding;
public type Component = NFInstTypes.Component;
public type Modifier = NFInstTypes.Modifier;
public type Prefixes = NFInstTypes.Prefixes;
public type Statement = NFInstTypes.Statement;

protected type Key = String;
protected type Value = tuple<Component, list<Absyn.Path>>;

protected type HashTableFunctionsType = tuple<FuncHashKey, FuncKeyEqual, FuncKeyStr, FuncValueStr>;

protected type SymbolTable = tuple<
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

protected function valueStr
  input Value inValue;
  output String outString;
protected
  Component comp;
algorithm
  (comp, _) := inValue;
  outString := NFInstDump.componentStr(comp);
end valueStr;

protected function newSymbolTable
  input Integer inSize;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := BaseHashTable.emptyHashTableWork(inSize,
    (System.stringHashDjb2Mod, stringEq, Util.id, valueStr));
end newSymbolTable;

public type Elements = list<Element>;
public type Equations = list<Equation>;
public type Algorithms = list<list<Statement>>;

public function flattenClass
  input Class inClass;
  input Boolean inContainsExtends;
  output Class outFlatClass;
algorithm
  outFlatClass := matchcontinue(inClass, inContainsExtends)
    local
      Absyn.Path name;
      Elements el;
      Equations eq, ieq;
      Algorithms alg, ialg;
      list<Class> sections;
      Integer el_count;
      Class cls;

    // If we have no extends then we don't need to do anything.
    case (_, false) then inClass;

    case (NFInstTypes.COMPLEX_CLASS(name, el, eq, ieq, alg, ialg), _)
      equation
        (sections, el_count) =
          List.accumulateMapFold(el, collectInheritedSections, 0);
        el = flattenElements(el, el_count, name);
        cls = NFInstTypes.COMPLEX_CLASS(name, el, eq, ieq, alg, ialg);
        cls = List.fold(sections, flattenSections, cls);
      then
        cls;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFInstFlatten.flattenClass failed for " +
          Absyn.pathString(NFInstUtil.getClassName(inClass)) + "\n");
      then
        fail();

  end matchcontinue;
end flattenClass;

protected function collectInheritedSections
  input Element inElements;
  input Integer inElementCount;
  input list<Class> inAccumSections;
  output list<Class> outSections;
  output Integer outElementCount;
algorithm
  (outSections, outElementCount) :=
  match(inElements, inElementCount, inAccumSections)
    local
      Integer el_count;
      Elements el;
      Class cls;

    case (NFInstTypes.EXTENDED_ELEMENTS(cls = cls as NFInstTypes.COMPLEX_CLASS(
        components = el)), _, _)
      equation
        el_count = listLength(el) + inElementCount;
      then
        (cls :: inAccumSections, el_count);

    else (inAccumSections, inElementCount + 1);

  end match;
end collectInheritedSections;

protected function flattenSections
  input Class inSections;
  input Class inAccumSections;
  output Class outSections;
algorithm
  outSections := match(inSections, inAccumSections)
    local
      Elements el;
      Equations eq1, eq2, ieq1, ieq2;
      Algorithms alg1, alg2, ialg1, ialg2;
      Absyn.Path name;

    case (NFInstTypes.COMPLEX_CLASS(_, _, eq1, ieq1, alg1, ialg1),
        NFInstTypes.COMPLEX_CLASS(name, el, eq2, ieq2, alg2, ialg2))
      equation
        eq1 = listAppend(eq1, eq2);
        ieq1 = listAppend(ieq1, ieq2);
        alg1 = listAppend(alg1, alg2);
        ialg1 = listAppend(ialg1, ialg2);
      then
        NFInstTypes.COMPLEX_CLASS(name, el, eq1, ieq1, alg1, ialg1);

  end match;
end flattenSections;

public function flattenElements
  input list<Element> inElements;
  input Integer inElementCount;
  input Absyn.Path inClassPath;
  output list<Element> outElements;
algorithm
  outElements := matchcontinue(inElements, inElementCount, inClassPath)
    local
      SymbolTable st;
      list<Element> flat_el;

    case (_, _, _)
      equation
        st = newSymbolTable(intDiv(inElementCount * 4, 3) + 1);
        (flat_el, _) = flattenElements2(inElements, st, {}, inClassPath, {});
      then
        flat_el;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFInstFlatten.flattenElements failed for " +
            Absyn.pathString(inClassPath) + "\n");
      then
        fail();

  end matchcontinue;
end flattenElements;

protected function flattenElements2
  input list<Element> inElements;
  input SymbolTable inSymbolTable;
  input list<Absyn.Path> inExtendPath;
  input Absyn.Path inClassPath;
  input list<Element> inAccumEl;
  output list<Element> outElements;
  output SymbolTable outSymbolTable;
algorithm
  (outElements, outSymbolTable) :=
  match(inElements, inSymbolTable, inExtendPath, inClassPath, inAccumEl)
    local
      Element el;
      list<Element> rest_el, accum_el;
      SymbolTable st;

    case (el :: rest_el, st, _, _, accum_el)
      equation
        (accum_el, st) = flattenElement(el, st, inExtendPath, inClassPath, accum_el);
        (accum_el, st) = flattenElements2(rest_el, st, inExtendPath, inClassPath, accum_el);
      then
        (accum_el, st);

    case ({}, st, _, _, accum_el) then (listReverse(accum_el), st);

  end match;
end flattenElements2;

protected function flattenElement
  input Element inElement;
  input SymbolTable inSymbolTable;
  input list<Absyn.Path> inExtendPath;
  input Absyn.Path inClassPath;
  input list<Element> inAccumEl;
  output list<Element> outElements;
  output SymbolTable outSymbolTable;
algorithm
  (outElements, outSymbolTable) :=
  match(inElement, inSymbolTable, inExtendPath, inClassPath, inAccumEl)
    local
      Element el;
      list<Element> ext_el, accum_el;
      Component comp;
      SymbolTable st;
      String name;
      Boolean add_el;
      list<DAE.Var> vars;
      list<String> var_names;
      Absyn.Path bc;

    // Extending from a class with no components, no elements to flatten.
    case (NFInstTypes.EXTENDED_ELEMENTS(
        cls = NFInstTypes.COMPLEX_CLASS(components = {})), st, _, _, accum_el)
      then (accum_el, st);

    case (NFInstTypes.EXTENDED_ELEMENTS(cls = NFInstTypes.BASIC_TYPE()),
        st, _, _, accum_el)
      then (inElement :: accum_el, st);

    case (NFInstTypes.EXTENDED_ELEMENTS(baseClass = bc,
        cls = NFInstTypes.COMPLEX_CLASS(components = ext_el),
        ty = DAE.T_COMPLEX(varLst = vars)), st, _, _, accum_el)
      equation
        // For extended elements we can use the names from the type, which are
        // already the last identifiers.
        var_names = List.mapReverse(vars, Types.getVarName);
        (accum_el, st) = flattenExtendedElements(ext_el, var_names,
          bc :: inExtendPath, inClassPath, st, accum_el);
      then
        (accum_el, st);

    case (el, st, _, _, accum_el)
      equation
        comp = NFInstUtil.getElementComponent(el);
        name = Absyn.pathLastIdent(NFInstUtil.getComponentName(comp));
        (add_el, st) =
          flattenElement2(name, comp, inExtendPath, inClassPath, st, accum_el);
        accum_el = List.consOnTrue(add_el, el, accum_el);
      then
        (accum_el, st);

  end match;
end flattenElement;

protected function flattenElement2
  input String inName;
  input Component inComponent;
  input list<Absyn.Path> inExtendPath;
  input Absyn.Path inClassPath;
  input SymbolTable inSymbolTable;
  input list<Element> inAccumEl;
  output Boolean outShouldAdd;
  output SymbolTable outSymbolTable;
algorithm
  (outShouldAdd, outSymbolTable) :=
  matchcontinue(inName, inComponent, inExtendPath, inClassPath, inSymbolTable, inAccumEl)
    local
      list<Element> accum_el;
      SymbolTable st;

    // Try to add the component to the symbol table.
    case (_, _, _, _, st, _)
      equation
        st = BaseHashTable.addUnique((inName, (inComponent, inExtendPath)), st);
      then
        (true, st);

    // If we couldn't add the component to the symbol table it means it already
    // exists, so we need to check that it's identical to the already existing
    // component.
    case (_, _, _, _, st, _)
      equation
        /**********************************************************************/
        // TODO: Look up the already existing component here and check that they
        // are equal.
        /**********************************************************************/
      then
        (false, st);

  end matchcontinue;
end flattenElement2;

protected function flattenExtendedElements
  input list<Element> inElements;
  input list<String> inNames;
  input list<Absyn.Path> inExtendPath;
  input Absyn.Path inClassPath;
  input SymbolTable inSymbolTable;
  input list<Element> inAccumEl;
  output list<Element> outElements;
  output SymbolTable outSymbolTable;
algorithm
  (outElements, outSymbolTable) :=
  match(inElements, inNames, inExtendPath, inClassPath, inSymbolTable, inAccumEl)
    local
      Element el;
      list<Element> rest_el, accum_el;
      Component comp;
      String name;
      list<String> rest_names;
      SymbolTable st;
      Boolean add_el;

    // Extended elements should not contain nested extended elements, since they
    // should have been flattened in instElementList. So we can assume that we
    // only have normal elements here.
    case (el :: rest_el, name :: rest_names, _, _, st, accum_el)
      equation
        comp = NFInstUtil.getElementComponent(el);
        (add_el, st) =
          flattenElement2(name, comp, inExtendPath, inClassPath, st, accum_el);
        accum_el = List.consOnTrue(add_el, el, accum_el);
        (accum_el, st) = flattenExtendedElements(rest_el, rest_names,
          inExtendPath, inClassPath, st, accum_el);
      then
        (accum_el, st);

    case ({}, {}, _, _, st, accum_el) then (accum_el, st);

  end match;
end flattenExtendedElements;

annotation(__OpenModelica_Interface="frontend");
end NFInstFlatten;

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


encapsulated package NFSCodeHashTable
" file:        NFSCodeHashTable.mo
  package:     NFSCodeHashTable
  description: NFSCodeHashTable deals with hashing the elements in SCode


  NFSCodeHashTable deals with hashing the elements
  in SCode (Absyn.ComponentRef -> SCode.Element)
  and to flatting the extends/derived clauses.

  Structures (elements/sections) are classified into where they come from:
  - local
  - extends
  - derived
  A hashtable is created for each top class and elements/sections are added
  to it togheter with a sequence number to know what order are they in the class.
  When an extends is found the extended class is looked up and its elements are
  added to the top hashtable togheter with the extends/derived clauses (if there
  are multiple extends/derived along the line). If there is an element with the
  same name already int the hashtable, the item is updated. All history of this
  collapsing of extends is rememebered, i.e.

  class C
    Real a;
  end C;

  class B
    Real a;
    extends C(modC);
  end B;

  class A
    extends B(modB);
    Real a;
    Real b;
  end A;

  HashTable Top is created containing
    HashTable A in which elements of A are added/updated in order
      - add    a -> VALUE(1, {EXTENDS_ELEMENT(A, B, a, {extends B(modB)})})
      - update a -> VALUE(1, {EXTENDS_ELEMENT(A, B, a, {extends B(modB)}), EXTENDS_ELEMENTS(B, C, a, {{extends B(modB), extends C(modC)})})
      - update a -> VALUE(1, {EXTENDS_ELEMENT(A, B, a, extends B(modB)), EXTENDS_ELEMENTS(B, C, a, {{extends B(modB), extends C(modC)}), LOCAL_ELEMENT(SOME(A), a)})
      - add    b -> VALUE(2, {LOCAL_ELEMENT(A, b)})
  Note that the extends modifier is sent to ALL the elements in the base class,
  i.e. if B has an element Real x, then EXTENDS_ELEMENT(A, B, x, extends B(modB))
  is added to the AggregatedStructures even if modB contains no modifier for element
  x. This might make it a bit harder to detect modifiers that have no target but is
  possible to check this too.

  Class extends is handled such as:
  {LOCAL_ELEMENT(Parent, classExtends),
   EXTENDS_ELEMENT(Parent, BaseClass, class, {classExtends, extends Base(modBase)})}

  Sections are added with child name $sections and are updated accordingly with the
  local sections and sections from derived classes. There is only one $sections in a
  hashtable.

  There are two phases to flatten extends:
  1. create hashtable from ORIGINAL program
  2. merge the modifiers (check for non-equivalent duplicate elements), only LOCAL_ELEMENT remains
  3. create NEW program from hashtable.

  More phases might be added in the future, i.e. alias removal:
  type X = Y(modY)[arrDimY];
  X x; ->  Y(modY)[arrDimY] x;

  "

/* Below is the instance specific code. For each hashtable the user must define:
Key       - The key used to uniquely define elements in a hashtable
Value     - The data to associate with each key
hashFunc   - A function that maps a key to a positive integer.
keyEqual   - A comparison function between two keys, returns true if equal.
*/
/* HashTable instance specific code */

public import Absyn;
public import SCode;
public import NFSCodeEnv;

protected import BaseHashTable;
protected import Dump;
protected import List;
protected import SCodeDump;
protected import NFSCodeLookup;
protected import System;

public
uniontype Section
  record SECTION "sections of a class"
    list<SCode.Equation>             normalEquationLst   "the list of equations";
    list<SCode.Equation>             initialEquationLst  "the list of initial equations";
    list<SCode.AlgorithmSection>     normalAlgorithmLst  "the list of algorithms";
    list<SCode.AlgorithmSection>     initialAlgorithmLst "the list of initial algorithms";
    list<SCode.ConstraintSection>    constraintLst       "the list of constraints for optimization";
    Option<SCode.ExternalDecl>       externalDecl        "used by external functions";
  end SECTION;
end Section;

uniontype FlatStructure "represents elements or sections (eqs/alg/external)"

  record LOCAL_ELEMENT
    Option<SCode.Element> parentOpt "the parent of this local element (the class), NONE for top level classes";
    SCode.Element         element "the local element";
  end LOCAL_ELEMENT;

  record EXTENDS_ELEMENT
    SCode.Element       parent "the parent of this local element (the class containing the extends)";
    SCode.Element       base   "the parent of this local element the class containing the actual element";
    SCode.Element       element "the local element in the extends class";
    list<SCode.Element> modifiers "the modifiers for this element, i.e. the entire hierarchy of extends from top to now";
  end EXTENDS_ELEMENT;

  record DERIVED_ELEMENT
    SCode.Element       parent "the parent of this local element the class containing the derived element";
    SCode.Element       base   "the parent of this local element the class containing the actual element";
    SCode.Element       element "the local element in the derived class";
    list<SCode.Element> modifiers "the modifiers for this element (the entire classes containing the derived form)";
  end DERIVED_ELEMENT;

  record LOCAL_SECTION
    SCode.Element parent "the parent of these sections (the class)";
    Section       section "the sections present in the class";
  end LOCAL_SECTION;

  record EXTENDS_SECTION
    SCode.Element parent "the parent of these sections the class containing the extends";
    SCode.Element base   "the base class containing the element";
    Section       section "the sections present in the class";
  end EXTENDS_SECTION;

  record DERIVED_SECTION
    SCode.Element parent "the parent of these sections the class containing the derived element";
    SCode.Element base   "the base class containing the element";
    Section       section "the sections present in the class";
  end DERIVED_SECTION;

end FlatStructure;

type AggregatedStructures = list<FlatStructure> "list of flatten structures";

uniontype HashValue
  record VALUE
    list<Integer> seqNumbers "the structure numbers inside the class";
    AggregatedStructures structures "the aggregated structures";
    Option<HashTable> optChildren;
  end VALUE;
end HashValue;

public type Key = Absyn.ComponentRef;
public type Value = HashValue;

protected function enterScope
  input NFSCodeEnv.Env inEnv;
  input SCode.Ident inName;
  input NFSCodeEnv.ClassType inClassType;
  output NFSCodeEnv.Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv, inName, inClassType)
    local
      NFSCodeEnv.Env env;
      NFSCodeEnv.Frame cls_env;
      NFSCodeEnv.ClassType cls_ty;

    // builtin class, do not enter!
    case (env, _, NFSCodeEnv.BUILTIN()) then env;

    // builtin, do not enter!
    case (env, _, _)
      equation
        (NFSCodeEnv.CLASS(env = {cls_env}, classType = cls_ty), _) =
          NFSCodeLookup.lookupInClass(inName, env);

        // make sure is builtin!
        true = valueEq(cls_ty, NFSCodeEnv.BUILTIN());
      then
        env;

    // not builtin
    case (env, _, _)
      equation
        (NFSCodeEnv.CLASS(env = {cls_env}, classType = cls_ty), _) =
          NFSCodeLookup.lookupInClass(inName, env);

        // make sure is NOT builtin!
        false = valueEq(cls_ty, NFSCodeEnv.BUILTIN());

        env = NFSCodeEnv.enterFrame(cls_env, env);
      then
        env;

    // failure
    case (env, _, _)
      equation
        print("- NFSCodeHashTable.enterScope failed on: " + inName + " in scope: " + NFSCodeEnv.getEnvName(env) + "\n");
      then
        fail();
  end matchcontinue;
end enterScope;

public function programFromHashTable
  input HashTable inHash;
  output SCode.Program outProgram;
algorithm
  outProgram := matchcontinue(inHash)
    local
      SCode.Program program;
      list<HashValue> els;

    case _
      equation
        els = BaseHashTable.hashTableValueList(inHash);
        els = List.sort(els, compare);
        program = List.map(els, getHasValueElement);
      then
        program;
  end matchcontinue;
end programFromHashTable;

public function hashTableFromProgram
  "Flattens a program."
  input SCode.Program inProgram;
  input NFSCodeEnv.Env inEnv;
  input Option<HashTable> inHashTable;
  input Integer seqNumber;
  output Option<HashTable> outHashTable;
algorithm
  outHashTable := matchcontinue(inProgram, inEnv, inHashTable, seqNumber)
    local
      NFSCodeEnv.Env env;
      SCode.Element cl, newCls;
      SCode.Program rest;
      Option<HashTable> hashTable;

    case ({}, env, hashTable, _) then hashTable;
    case (cl::rest, env, hashTable, _)
      equation
        hashTable = hashTableFromTopClass(Absyn.CREF_IDENT(".", {}), cl, env, hashTable, seqNumber);
        hashTable = hashTableFromProgram(rest, env, hashTable, seqNumber + 1);
      then
        hashTable;
  end matchcontinue;
end hashTableFromProgram;

protected function hashTableFromTopClass
  "Flattens a program."
  input Absyn.ComponentRef inParentCref;
  input SCode.Element inClass;
  input NFSCodeEnv.Env inEnv;
  input Option<HashTable> inHashTable;
  input Integer seqNumber;
  output Option<HashTable> outHashTable;
algorithm
  outHashTable := matchcontinue(inParentCref, inClass, inEnv, inHashTable, seqNumber)
    local
      NFSCodeEnv.Env env;
      SCode.Element cl, newCls;
      SCode.Program rest;
      Option<HashTable> hashTable;
      SCode.Element element;
      SCode.Ident className;
      Absyn.ComponentRef fullCref;
      Option<HashTable> optHT;
      SCode.ClassDef cDef;
      SourceInfo info;

    case (_, cl as SCode.CLASS(classDef = cDef, info = info), env, hashTable, _)
      equation
        className = SCode.className(cl);
        element = cl;
        fullCref = joinCrefs(inParentCref, Absyn.CREF_IDENT(className, {}));

        env = enterScope(env, className, NFSCodeEnv.USERDEFINED());

        (optHT, _) = hashTableFromClassDef(fullCref, cl, {}, NONE(), cDef, env, NONE(), 1, info);
        hashTable =
          add(
            (fullCref, VALUE({seqNumber}, {LOCAL_ELEMENT(NONE(), element)}, optHT)),
            hashTable);
      then
        hashTable;
  end matchcontinue;
end hashTableFromTopClass;

protected function createSectionStructure
  input list<SCode.Element> modifiers;
  input SCode.Element parent;
  input Section section;
  output FlatStructure structure;
algorithm
  structure := matchcontinue(modifiers, parent, section)
    local
      SCode.Element element;

    case ({}, _, _)
      then LOCAL_SECTION(parent, section);

    case ({element as SCode.EXTENDS(baseClassPath = _)}, _, _)
      then EXTENDS_SECTION(parent, element, section);

    case ({element as SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = _))}, _, _)
      then EXTENDS_SECTION(parent, element, section);

    case ({element as SCode.CLASS(classDef = SCode.DERIVED(typeSpec = _))}, _, _)
      then DERIVED_SECTION(parent, element, section);

    case ({element}, _, _)
      equation
        // something is wrong!
        // print("wrong: " + SCodeDump.printElementStr(element) + "\n");
      then
        LOCAL_SECTION(parent, section);

    case (_::_, _, _)
      equation
        element = List.last(modifiers);
      then createSectionStructure({element}, parent, section);
  end matchcontinue;
end createSectionStructure;

protected function createElementStructure
  input list<SCode.Element> modifiers;
  input Option<SCode.Element> parentOpt;
  input Option<SCode.Element> baseOpt;
  input SCode.Element element;
  output FlatStructure structure;
algorithm
  structure := matchcontinue(modifiers, parentOpt, baseOpt, element)
    local
      SCode.Element mod;
      SCode.Element parent, base;

    case ({}, _, _, _)
      then LOCAL_ELEMENT(parentOpt, element);

    case (SCode.EXTENDS(baseClassPath = _)::_, SOME(parent), SOME(base), _)
      then EXTENDS_ELEMENT(parent, base, element, modifiers);

    case (SCode.EXTENDS(baseClassPath = _)::_, SOME(parent), NONE(), _)
      then EXTENDS_ELEMENT(parent, parent, element, modifiers);

    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = _))::_, SOME(parent), SOME(base), _)
      then EXTENDS_ELEMENT(parent, base, element, modifiers);

    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = _))::_, SOME(parent), NONE(), _)
      then EXTENDS_ELEMENT(parent, parent, element, modifiers);

    case (SCode.CLASS(classDef = SCode.DERIVED(typeSpec = _))::_, SOME(parent), SOME(base), _)
      then DERIVED_ELEMENT(parent, base, element, modifiers);

    case (SCode.CLASS(classDef = SCode.DERIVED(typeSpec = _))::_, SOME(parent), NONE(), _)
      then DERIVED_ELEMENT(parent, parent, element, modifiers);

    else
      equation
        print("- NFSCodeHashTable.createElementStructure failed on: " +
          " modifiers:" + stringDelimitList(List.map(modifiers, SCodeDump.shortElementStr), ", ") +
          " element: " + SCodeDump.shortElementStr(element) + "\n"
        );
      then
        fail();
  end matchcontinue;
end createElementStructure;

protected function addRedeclaresAndClassExtendsToModifiers
  input list<SCode.Element> inModifiers;
  input list<SCode.Element> elements;
  output list<SCode.Element> outModifiers;
algorithm
  outModifiers := matchcontinue(inModifiers, elements)
    local
      SCode.Element el;
      list<SCode.Element> modifiers, rest;
    // handle empty
    case (modifiers, {}) then modifiers;
    // handle class extends
    case (modifiers, (el as SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = _)))::rest)
      equation
        modifiers = listAppend(modifiers, {el});
        modifiers = addRedeclaresAndClassExtendsToModifiers(modifiers, rest);
      then
        modifiers;
    // handle redeclare-as-element classes
    case (modifiers, (el as SCode.CLASS(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())))::rest)
      equation
        modifiers = listAppend(modifiers, {el});
        modifiers = addRedeclaresAndClassExtendsToModifiers(modifiers, rest);
      then
        modifiers;
    // handle redeclare-as-element components
    case (modifiers, (el as SCode.COMPONENT(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())))::rest)
      equation
        modifiers = listAppend(modifiers, {el});
        modifiers = addRedeclaresAndClassExtendsToModifiers(modifiers, rest);
      then
        modifiers;
    // handle others
    case (modifiers, _::rest)
      equation
        modifiers = addRedeclaresAndClassExtendsToModifiers(modifiers, rest);
      then
        modifiers;
  end matchcontinue;
end addRedeclaresAndClassExtendsToModifiers;

protected function hashTableFromClassDef
  "Flattens a classdef."
  input Absyn.ComponentRef inParentCref;
  input SCode.Element inElementParent;
  input list<SCode.Element> inModifiers;
  input Option<SCode.Element> inBaseClassOpt;
  input SCode.ClassDef inClassDef;
  input NFSCodeEnv.Env inEnv;
  input Option<HashTable> inHashTable;
  input Integer inSeqNumber;
  input SourceInfo inInfo;
  output Option<HashTable> outHashTable;
  output Integer outSeqNumber;
algorithm
  (outHashTable, outSeqNumber) := matchcontinue(inParentCref, inElementParent, inModifiers, inBaseClassOpt, inClassDef, inEnv, inHashTable, inSeqNumber, inInfo)
    local
      NFSCodeEnv.Env env;
      SCode.Element cl, newCls, parentElement;
      NFSCodeEnv.ClassType cls_ty;
      SCode.Program rest;
      Option<HashTable> hashTable, optHT;
      SCode.Element el;
      SCode.Ident className, baseClassName, name;
      Absyn.ComponentRef fullCref;
      Absyn.Path path;
      NFSCodeEnv.ClassType classType;
      list<SCode.Element> els, modifiers;
      list<SCode.Equation> ne "the list of equations";
      list<SCode.Equation> ie "the list of initial equations";
      list<SCode.AlgorithmSection> na "the list of algorithms";
      list<SCode.AlgorithmSection> ia "the list of initial algorithms";
      list<SCode.ConstraintSection> co "the list of constraints for optimization";
      list<Absyn.NamedArg> clats "the list of class attributes. Currently for Optimica extensions";
      Option<SCode.ExternalDecl> ed "used by external functions";
      list<SCode.Annotation> al "the list of annotations found in between class elements, equations and algorithms";
      Option<SCode.Comment> c "the class comment";
      SCode.ClassDef cDef;
      Option<SCode.Element> baseClassOpt;
      FlatStructure structure;
      Integer seqNumber;
      SourceInfo info;

    // handle parts
    case (_, parentElement, modifiers, baseClassOpt, SCode.PARTS(els, ne, ie, na, ia, co, _, ed), env, hashTable, seqNumber, info)
      equation
        modifiers = addRedeclaresAndClassExtendsToModifiers(modifiers, els);
        (hashTable, seqNumber) = hashTableAddElements(inParentCref, parentElement, modifiers, baseClassOpt, els, env, hashTable, seqNumber);
        fullCref = joinCrefs(inParentCref, Absyn.CREF_IDENT("$sections", {}));
        structure = createSectionStructure(modifiers, parentElement, SECTION(ne, ie, na, ia, co, ed));
        hashTable = add((fullCref, VALUE({seqNumber}, {structure}, NONE())), hashTable);
      then (hashTable, seqNumber + 1);

    // handle class extends
    case (_, parentElement, modifiers, baseClassOpt, SCode.CLASS_EXTENDS(baseClassName = baseClassName), env, hashTable, seqNumber, info)
      equation
        fullCref = joinCrefs(inParentCref, Absyn.CREF_IDENT(baseClassName, {}));

        structure = createElementStructure(modifiers, SOME(parentElement), baseClassOpt, parentElement);

        hashTable = add((fullCref, VALUE({seqNumber}, {structure}, NONE())), hashTable);
      then (hashTable, seqNumber + 1);

    // handle derived!
    case (_, parentElement, modifiers, baseClassOpt, SCode.DERIVED(typeSpec = Absyn.TPATH(path = path)), env, hashTable, seqNumber, info)
      equation
        // Remove the extends from the local scope before flattening the derived
        // type, because the type should not be looked up via itself.
        env = NFSCodeEnv.removeExtendsFromLocalScope(env);

        (NFSCodeEnv.CLASS(cls = el as SCode.CLASS(classDef = cDef, info = info), classType = cls_ty), path, env) =
          NFSCodeLookup.lookupBaseClassName(path, env, info);

        // entering the base class
        env = enterScope(env, Absyn.pathLastIdent(path), cls_ty);

        //print("Adding derived modif: " + SCodeDump.printElementStr(parentElement) + " in parent: " + Dump.printComponentRefStr(inParentCref) +
        //" in scope: " + NFSCodeEnv.getEnvName(env) + "\n");

        modifiers = listAppend(modifiers, {parentElement});

        (hashTable, seqNumber) =
          hashTableFromClassDef(inParentCref,
            el,
            modifiers,
            SOME(el),
            cDef,
            env,
            inHashTable,
            seqNumber,
            info);
      then (hashTable, seqNumber);

    // handle enumeration
    case (_, parentElement, modifiers, baseClassOpt, SCode.ENUMERATION(enumLst = _), env, hashTable, seqNumber, info)
      then (hashTable, seqNumber + 1);

    // handle overload
    case (_, parentElement, modifiers, baseClassOpt, SCode.OVERLOAD(pathLst = _), env, hashTable, seqNumber, info)
      then (hashTable, seqNumber + 1);

    // handle pder
    case (_, parentElement, modifiers, baseClassOpt, SCode.PDER(functionPath = _), env, hashTable, seqNumber, info)
      then (hashTable, seqNumber + 1);
  end matchcontinue;
end hashTableFromClassDef;

protected function hashTableAddElements
  "adds elements to hashtable"
  input Absyn.ComponentRef inParentCref;
  input SCode.Element inElementParent;
  input list<SCode.Element> inModifiers;
  input Option<SCode.Element> inBaseClassOpt;
  input list<SCode.Element> inElements;
  input NFSCodeEnv.Env inEnv;
  input Option<HashTable> inHashTable;
  input Integer inSeqNumber;
  output Option<HashTable> outHashTable;
  output Integer outSeqNumber;
algorithm
  (outHashTable, outSeqNumber) := matchcontinue(inParentCref, inElementParent, inModifiers, inBaseClassOpt, inElements, inEnv, inHashTable, inSeqNumber)
    local
      NFSCodeEnv.Env env;
      Option<HashTable> hashTable;
      SCode.Element el;
      list<SCode.Element> rest;
      FlatStructure structure;
      SourceInfo info;
      Absyn.ComponentRef fullCref;
      Integer seqNumber;

    // handle classes without elements!
    case (_, _, _, _, {}, env, hashTable, seqNumber)
      equation
        fullCref = joinCrefs(inParentCref, Absyn.CREF_IDENT("$noElements", {}));

        info = SCode.elementInfo(inElementParent);

        structure =
          createElementStructure(
            inModifiers,
            SOME(inElementParent),
            inBaseClassOpt,
            SCode.COMPONENT(
              "$noElements",
              SCode.defaultPrefixes,
              SCode.defaultConstAttr,
              Absyn.TPATH(Absyn.IDENT("$noType"), NONE()),
              SCode.NOMOD(),
              SCode.noComment,
              NONE(),
              info));

        hashTable = add((fullCref,
                         VALUE({seqNumber},
                               {structure},
                               NONE())),
                         hashTable);
      then
        (hashTable, seqNumber + 1);

    // handle 1 element
    case (_, _, _, _, {el}, env, hashTable, seqNumber)
      equation
        (hashTable, seqNumber) = hashTableAddElement(inParentCref, inElementParent, inModifiers, inBaseClassOpt, el, env, hashTable, seqNumber);
      then
        (hashTable, seqNumber);

    // handle rest
    case (_, _, _, _, el::rest, env, hashTable, seqNumber)
      equation
        (hashTable, seqNumber) = hashTableAddElement(inParentCref, inElementParent, inModifiers, inBaseClassOpt, el, env, hashTable, seqNumber);
        (hashTable, seqNumber) = hashTableAddElements(inParentCref, inElementParent, inModifiers, inBaseClassOpt, rest, env, hashTable, seqNumber);
      then
        (hashTable, seqNumber);

  end matchcontinue;
end hashTableAddElements;

protected function hashTableAddElement
  "adds elements to hashtable"
  input Absyn.ComponentRef inParentCref;
  input SCode.Element inElementParent;
  input list<SCode.Element> inModifiers;
  input Option<SCode.Element> inBaseClassOpt;
  input SCode.Element inElement;
  input NFSCodeEnv.Env inEnv;
  input Option<HashTable> inHashTable;
  input Integer inSeqNumber;
  output Option<HashTable> outHashTable;
  output Integer outSeqNumber;
algorithm
  (outHashTable, outSeqNumber) := matchcontinue(inParentCref, inElementParent, inModifiers, inBaseClassOpt, inElement, inEnv, inHashTable, inSeqNumber)
    local
      NFSCodeEnv.Env env;
      NFSCodeEnv.ClassType cls_ty;
      Option<HashTable> hashTable;
      Absyn.ComponentRef fullCref;
      Option<HashTable> optHT;
      SCode.Ident name;
      Absyn.Path path;
      SCode.Element el, cl, parentElement;
      Absyn.Import imp;
      SourceInfo info;
      NFSCodeEnv.Item item;
      SCode.Mod mod;
      SCode.Visibility vis;
      SCode.ClassDef cDef;
      Option<SCode.Element> baseClassOpt;
      list<SCode.Element> modifiers;
      FlatStructure structure;
      Integer seqNumber;

    // handle extends
    case (_, parentElement, modifiers, _, el as SCode.EXTENDS(baseClassPath = path, modifications = mod, visibility = vis, info = info), env, hashTable, seqNumber)
      equation
        // Remove the extends from the local scope before flattening the extends
        // type, because the type should not be looked up via itself.
        env = NFSCodeEnv.removeExtendsFromLocalScope(env);

        // print("Looking up: " + Absyn.pathString(path) + " in parent: " + Dump.printComponentRefStr(inParentCref) + "\n");

        (NFSCodeEnv.CLASS(cls = cl as SCode.CLASS(classDef = cDef, info = info), classType = cls_ty), path, env) =
          NFSCodeLookup.lookupBaseClassName(path, env, info);

        // entering the base class
        env = enterScope(env, Absyn.pathLastIdent(path), cls_ty);

        //print("Adding extends modif: " + SCodeDump.printElementStr(el) + " in parent: " + Dump.printComponentRefStr(inParentCref) +
        //" in scope: " + NFSCodeEnv.getEnvName(env) + "\n");

        modifiers = listAppend(modifiers, {el});

        (hashTable, seqNumber) =
          hashTableFromClassDef(inParentCref,
            parentElement,
            modifiers,
            SOME(cl),
            cDef,
            env,
            inHashTable,
            seqNumber,
            info);
      then
        (hashTable, seqNumber);

    // handle classdef
    case (_, parentElement, modifiers, _, el as SCode.CLASS(name = name, classDef = cDef, info = info), env, hashTable, seqNumber)
      equation
        fullCref = joinCrefs(inParentCref, Absyn.CREF_IDENT(name, {}));

        // print("Entering: " + name + " in parent: " + Dump.printComponentRefStr(inParentCref) + " in scope: " + NFSCodeEnv.getEnvName(env) + "\n");

        env = enterScope(env, name, NFSCodeEnv.USERDEFINED());

        (optHT,_) = hashTableFromClassDef(fullCref, el, modifiers, inBaseClassOpt, cDef, env, NONE(), 1, info);

        structure = createElementStructure(modifiers,SOME(parentElement),inBaseClassOpt,el);

        hashTable =
          add(
            (fullCref, VALUE({seqNumber}, {structure}, optHT)),
            hashTable);
      then
        (hashTable, seqNumber + 1);

    // handle import, WE SHOULD NOT HAVE ANY!
    case (_, parentElement, modifiers, _, el as SCode.IMPORT(imp = imp), env, hashTable, seqNumber)
      equation
        name = Dump.unparseImportStr(imp);
        fullCref = joinCrefs(inParentCref, Absyn.CREF_QUAL("$import", {}, Absyn.CREF_IDENT(name, {})));

        structure = createElementStructure(modifiers,SOME(parentElement),inBaseClassOpt,el);

        hashTable =
          add(
            (fullCref, VALUE({seqNumber}, {structure}, NONE())),
            hashTable);
      then
        (hashTable, seqNumber + 1);

    // handle component
    case (_, parentElement, modifiers, _, el as SCode.COMPONENT(name = name), env, hashTable, seqNumber)
      equation
        fullCref = joinCrefs(inParentCref, Absyn.CREF_IDENT(name, {}));

        structure = createElementStructure(modifiers,SOME(parentElement),inBaseClassOpt,el);

        hashTable =
          add(
            (fullCref, VALUE({seqNumber}, {structure}, NONE())),
            hashTable);
      then
        (hashTable, seqNumber + 1);

    // handle defineunit
    case (_, parentElement, modifiers, _, el as SCode.DEFINEUNIT(name = name), env, hashTable, seqNumber)
      equation
        fullCref = joinCrefs(inParentCref, Absyn.CREF_IDENT(name, {}));

        structure = createElementStructure(modifiers,SOME(parentElement),inBaseClassOpt,el);

        hashTable =
          add(
            (fullCref, VALUE({seqNumber}, {structure}, NONE())),
            hashTable);
      then
        (hashTable, seqNumber + 1);

     case (_, parentElement, modifiers, _, el, env, hashTable, seqNumber)
       equation
         print("- NFSCodeHashTable.hashTableAddElement failed on element: " + SCodeDump.shortElementStr(el) + "\n");
       then
         fail();

  end matchcontinue;
end hashTableAddElement;

public function lookup
  input Option<HashTable> inHashTable;
  input Key key;
  output HashValue outHashValue;
algorithm
  outHashValue := matchcontinue(inHashTable, key)
    local
      HashTable hashTable;
      HashValue hashValue;

    // found something
    case (SOME(hashTable), _)
      then BaseHashTable.get(key, hashTable);

    // found nothing!
    else
      equation
        print("Lookup failed for: " +  Dump.printComponentRefStr(key) + "\n");
      then
        fail();
  end matchcontinue;
end lookup;

public type HashTableCrefFunctionsType = tuple<FuncHashCref,FuncCrefEqual,FuncCrefStr,FuncExpStr>;
public type HashTable = tuple<
  array<list<tuple<Key,Integer>>>,
  tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>,
  Integer,
  Integer,
  HashTableCrefFunctionsType
>;

partial function FuncHashCref
  input Key cr;
  input Integer mod;
  output Integer res;
end FuncHashCref;

partial function FuncCrefEqual
  input Key cr1;
  input Key cr2;
  output Boolean res;
end FuncCrefEqual;

partial function FuncCrefStr
  input Key cr;
  output String res;
end FuncCrefStr;

partial function FuncExpStr
  input Value exp;
  output String res;
end FuncExpStr;

protected function hashFunc
"Calculates a hash value for Key"
  input Key cr;
  input Integer mod;
  output Integer res;
protected
  String crstr;
algorithm
  crstr := Dump.printComponentRefStr(cr);
  res := System.stringHashDjb2Mod(crstr,mod);
end hashFunc;

protected function printStructuresStr
  input AggregatedStructures inStructures;
  output String outStr;
algorithm
  outStr := stringDelimitList(List.map(inStructures,printStructureStr), ", ");
end printStructuresStr;

protected function printStructureStr
  input FlatStructure inStructure;
  output String outStr;
algorithm
  outStr := matchcontinue(inStructure)
    local
      String str;
      SCode.Element el, parent, base;
      Option<SCode.Element> parentOpt;
      list<SCode.Element> modifiers;
      Section sec;

    case (LOCAL_ELEMENT(parentOpt, el))
      equation
        str = "local[" + SCodeDump.shortElementStr(el) + "]";
      then
        str;

    case (EXTENDS_ELEMENT(parent, base, el, modifiers))
      equation
        str = "extends[" + SCodeDump.shortElementStr(el) +
               ", parent: " + SCodeDump.shortElementStr(parent) +
               ", base: " + SCodeDump.shortElementStr(base) +
               ", modifiers:" + stringDelimitList(List.map(modifiers, SCodeDump.shortElementStr), ", ") +
               "]";
      then
        str;

    case (DERIVED_ELEMENT(parent, base, el, modifiers))
      equation
        str = "derived[" + SCodeDump.shortElementStr(el) +
               ", parent: " + SCodeDump.shortElementStr(parent) +
               ", base: " + SCodeDump.shortElementStr(base) +
               ", modifiers:" + stringDelimitList(List.map(modifiers, SCodeDump.shortElementStr), ", ") +
               "]";
      then
        str;

    case (LOCAL_SECTION(el, sec))
      equation
        str = "local section[" + SCodeDump.shortElementStr(el) + ", " + printSectionStr(sec) + "]";
      then
        str;

    case (EXTENDS_SECTION(el, base, sec))
      equation
        str = "extends section[" + SCodeDump.shortElementStr(el) + ", base: " + SCodeDump.shortElementStr(base) + ", " + printSectionStr(sec) + "]";
      then
        str;

    case (DERIVED_SECTION(el, base, sec))
      equation
        str = "derived section[" + SCodeDump.shortElementStr(el) + ", base: " + SCodeDump.shortElementStr(base) + ", " + printSectionStr(sec) + "]";
      then
        str;

  end matchcontinue;
end printStructureStr;

protected function printSectionStr
  input Section inSection;
  output String outStr;
algorithm
  outStr := matchcontinue(inSection)
    local
      String str;
      list<SCode.Equation>             normalEquationLst   "the list of equations";
      list<SCode.Equation>             initialEquationLst  "the list of initial equations";
      list<SCode.AlgorithmSection>     normalAlgorithmLst  "the list of algorithms";
      list<SCode.AlgorithmSection>     initialAlgorithmLst "the list of initial algorithms";
      list<SCode.ConstraintSection>    constraintLst       "the list of constraints for optimization";
      Option<SCode.ExternalDecl>       externalDecl        "used by external functions";
      list<SCode.Annotation>           annotationLst       "the list of annotations found in between class elements, equations and algorithms";
      Option<SCode.Comment>            comment             "the class comment";

    case (SECTION(normalEquationLst, initialEquationLst, normalAlgorithmLst, initialAlgorithmLst, constraintLst, externalDecl))
      equation
        str = "$section";
      then
        str;
  end matchcontinue;
end printSectionStr;

protected function hashValueString
  input HashValue inHashValue;
  output String outString;
algorithm
  outString := matchcontinue(inHashValue)
    local
      String str;
      list<Integer> seqNumbers;
      AggregatedStructures structures;
      HashTable hashTable;

    case (VALUE(seqNumbers = seqNumbers, structures = structures, optChildren = NONE()))
      equation
        str = "[" + stringDelimitList(List.map(seqNumbers, intString), ", ") +
              "], " + printStructuresStr(structures) + "\n";
      then
        str;

    case (VALUE(seqNumbers = seqNumbers,  structures = structures, optChildren = SOME(hashTable)))
      equation
        str = "[" + stringDelimitList(List.map(seqNumbers, intString), ", ") +
              "], " + printStructuresStr(structures) +
              ", \n\tKids: (\n\t" +
              stringDelimitList(
                List.map(BaseHashTable.hashTableList(hashTable),
                hashItemString), "\n\t") + ")";
      then
        str;
  end matchcontinue;
end hashValueString;

public function hashItemString
  input tuple<Key,Value> tpl;
  output String str;
protected
  Key k;
  Value v;
algorithm
  (k, v) := tpl;
  str := "{" + Dump.printComponentRefStr(k) + ",{" + hashValueString(v) + "}}";
end hashItemString;

public function emptyHashTable
"Returns an empty HashTable.
 Using the default bucketsize.."
  output HashTable hashTable;
algorithm
  hashTable := emptyHashTableSized(BaseHashTable.defaultBucketSize);
end emptyHashTable;

public function emptyHashTableSized
"Returns an empty HashTable.
 Using the bucketsize size."
  input Integer size;
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(size,(hashFunc,Absyn.crefEqual,Dump.printComponentRefStr,hashValueString));
end emptyHashTableSized;

public function getHasValueElement
  input HashValue inValue;
  output SCode.Element el;
algorithm
  VALUE(structures = {LOCAL_ELEMENT(element = el)}) := inValue;
end getHasValueElement;

public function compare
  input HashValue inValue1;
  input HashValue inValue2;
  output Boolean isGreater;
algorithm
  isGreater := matchcontinue(inValue1, inValue2)
    local
      Integer sq1, sq2;
    case (VALUE(seqNumbers = sq1::_), VALUE(seqNumbers = sq2::_))
      then intGt(sq1, sq2);
  end matchcontinue;
end compare;

public function createSomeHash
  input Option<HashTable> inOptHashTable;
  output Option<HashTable> outOptHashTable;
algorithm
  outOptHashTable := matchcontinue(inOptHashTable)
    local
      HashTable h;

    case (NONE())
      equation
        h = emptyHashTable();
      then SOME(h);

    case (SOME(_)) then inOptHashTable;

  end matchcontinue;
end createSomeHash;

public function add
  input tuple<Key,Value> inKeyValue;
  input Option<HashTable> inOptHashTable;
  output Option<HashTable> outOptHashTable;
algorithm
  outOptHashTable := matchcontinue(inKeyValue, inOptHashTable)
    local
      HashTable hashTable;
      Option<HashTable> optHashTable;
      HashValue hashValue;
      Key key;
      Value newValue;

    // not there, add it
    case ((key, _), optHashTable)
      equation
        SOME(hashTable) = createSomeHash(optHashTable);
        failure((_) = BaseHashTable.get(key, hashTable));
        hashTable = BaseHashTable.addNoUpdCheck(inKeyValue, hashTable);
      then
        SOME(hashTable);

    // there, update it
    case ((key, newValue), optHashTable)
      equation
        SOME(hashTable) = createSomeHash(optHashTable);
        hashValue = BaseHashTable.get(key, hashTable);
        hashValue = updateValue(hashValue, newValue);
        hashTable = BaseHashTable.addNoUpdCheck((key, hashValue), hashTable);
      then
        SOME(hashTable);
  end matchcontinue;
end add;

protected function updateValue
  input HashValue hashValueOld;
  input HashValue hashValueNew;
  output HashValue newHashValue;
algorithm
  newHashValue := matchcontinue(hashValueOld, hashValueNew)
    local
      list<Integer> seqNumbers, seqNumbers1, seqNumbers2;
      AggregatedStructures structures, structures1, structures2;
      Option<HashTable> optChildren, optChildren1, optChildren2;

    case (VALUE(seqNumbers1, structures1, optChildren1), VALUE(seqNumbers2, structures2, optChildren2))
      equation
        seqNumbers = listAppend(seqNumbers1, seqNumbers2);
        structures = listAppend(structures1, structures2);
        // we take only the kids from the first!
        optChildren = optChildren1;
      then
        VALUE(seqNumbers, structures, optChildren);
  end matchcontinue;
end updateValue;

protected function joinCrefs
  "do not join if ident is top (.)"
  input Absyn.ComponentRef inCrefPrefix;
  input Absyn.ComponentRef inCrefSuffix;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCrefPrefix, inCrefSuffix)
    local
      Absyn.ComponentRef cref;

    // handle "", return the suffix
    case (Absyn.CREF_IDENT(name = "."), _)
      then inCrefSuffix;

    // handle != "", return the joined prefix.suffix
    else
      equation
        cref = Absyn.joinCrefs(inCrefPrefix, inCrefSuffix);
      then cref;
  end matchcontinue;
end joinCrefs;

annotation(__OpenModelica_Interface="frontend");
end NFSCodeHashTable;

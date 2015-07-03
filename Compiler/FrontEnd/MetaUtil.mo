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

encapsulated package MetaUtil
" file:        MetaUtil.mo
  package:     MetaUtil
  description: Different MetaModelica extension functions.
"

public import Absyn;
public import ClassInf;
public import DAE;
public import SCode;

protected import Config;
protected import Flags;
protected import List;
protected import Types;

public function createMetaClassesInProgram
  "This function goes through a program and changes all records inside of
   uniontype into metarecords. It also makes a copy of them outside of the
   uniontype where they are found so that they can be used without prefixing
   with the uniontype name."
  input Absyn.Program inProgram;
  output Absyn.Program outProgram = inProgram;
protected
  list<Absyn.Class> classes = {}, meta_classes;
algorithm
  if not Config.acceptMetaModelicaGrammar() then
    return;
  end if;

  _ := match outProgram
    case Absyn.PROGRAM()
      algorithm
        for c in outProgram.classes loop
          (c, meta_classes) := createMetaClasses(c);
          classes := c :: listAppend(meta_classes, classes);
        end for;

        outProgram.classes := listReverse(classes);
      then
        ();

    else ();
  end match;
end createMetaClassesInProgram;

protected function createMetaClasses
  "Takes a class, and if it's a uniontype it converts all records inside it into
   metarecords and returns the updated uniontype and a list of all metarecords.
   It then recursively applies the same operation to all subclasses."
  input Absyn.Class inClass;
  output Absyn.Class outClass = inClass;
  output list<Absyn.Class> outMetaClasses = {};
protected
  Absyn.ClassDef body;
  list<Absyn.ClassPart> parts;
algorithm
  _ := match outClass
    case Absyn.CLASS(restriction = Absyn.R_UNIONTYPE(),
        body = body as Absyn.PARTS(classParts = parts))
      algorithm
        (parts, outMetaClasses) := fixClassParts(parts, outClass.name);
        body.classParts := parts;
        outClass.body := body;
      then
        ();

    case Absyn.CLASS(restriction = Absyn.R_UNIONTYPE(),
        body = body as Absyn.CLASS_EXTENDS(parts = parts))
      algorithm
        (parts, outMetaClasses) := fixClassParts(parts, outClass.name);
        body.parts := parts;
        outClass.body := body;
      then
        ();

    else ();
  end match;

  _ := match outClass
    case Absyn.CLASS(body = body as Absyn.PARTS())
      algorithm
        body.classParts := createMetaClassesFromClassParts(body.classParts);
        outClass.body := body;
      then
        ();

    case Absyn.CLASS(body = body as Absyn.CLASS_EXTENDS())
      algorithm
        body.parts := createMetaClassesFromClassParts(body.parts);
        outClass.body := body;
      then
        ();

    else ();
  end match;
end createMetaClasses;

protected function createMetaClassesFromClassParts
  input list<Absyn.ClassPart> inClassParts;
  output list<Absyn.ClassPart> outClassParts;
algorithm
  outClassParts := list(match p
    case Absyn.PUBLIC()
      algorithm
        p.contents := createMetaClassesFromElementItems(p.contents);
      then
        p;

    case Absyn.PROTECTED()
      algorithm
        p.contents := createMetaClassesFromElementItems(p.contents);
      then
        p;

    else p;
  end match for p in inClassParts);
end createMetaClassesFromClassParts;

protected function createMetaClassesFromElementItems
  input list<Absyn.ElementItem> inElementItems;
  output list<Absyn.ElementItem> outElementItems = {};
protected
  Absyn.Class cls;
  list<Absyn.Class> meta_classes;
  list<Absyn.ElementItem> els;
algorithm
  for e in listReverse(inElementItems) loop
    e := match e
      case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
          Absyn.CLASSDEF(class_ = cls)))
        algorithm
          (cls, meta_classes) := createMetaClasses(cls);
          els := list(setElementItemClass(e, c) for c in meta_classes);
          outElementItems := listAppend(els, outElementItems);
        then
          setElementItemClass(e, cls);

      else e;
    end match;

    outElementItems := e :: outElementItems;
  end for;
end createMetaClassesFromElementItems;

protected function setElementItemClass
  input Absyn.ElementItem inElementItem;
  input Absyn.Class inClass;
  output Absyn.ElementItem outElementItem = inElementItem;
algorithm
  outElementItem := match outElementItem
    local
      Absyn.Element e;
      Absyn.ElementSpec es;

    case Absyn.ELEMENTITEM(element = e as Absyn.ELEMENT(specification = es as Absyn.CLASSDEF()))
      algorithm
        es.class_ := inClass;
        e.specification := es;
        outElementItem.element := e;
      then
        outElementItem;

    else outElementItem;
  end match;
end setElementItemClass;

protected function convertElementToClass
  input Absyn.ElementItem inElementItem;
  output Absyn.Class outClass;
algorithm
  Absyn.ELEMENTITEM(element = Absyn.ELEMENT(
    specification = Absyn.CLASSDEF(class_ = outClass))) := inElementItem;
end convertElementToClass;

protected function fixClassParts
  input list<Absyn.ClassPart> inClassParts;
  input Absyn.Ident inClassName;
  output list<Absyn.ClassPart> outClassParts = {};
  output list<Absyn.Class> outMetaClasses = {};
protected
  list<Absyn.Class> meta_classes;
  list<Absyn.ElementItem> els;
algorithm
  outClassParts := list(match p
    case Absyn.PUBLIC()
      algorithm
        (els, meta_classes) := fixElementItems(p.contents, inClassName);
        p.contents := els;
        outMetaClasses := listAppend(meta_classes, outMetaClasses);
      then
        p;

    case Absyn.PROTECTED()
      algorithm
        (els, meta_classes) := fixElementItems(p.contents, inClassName);
        p.contents := els;
        outMetaClasses := listAppend(meta_classes, outMetaClasses);
      then
        p;

    else p;
  end match for p in inClassParts);
end fixClassParts;

protected function fixElementItems
  input list<Absyn.ElementItem> inElementItems;
  input String inName;
  output list<Absyn.ElementItem> outElementItems;
  output list<Absyn.Class> outMetaClasses = {};
protected
  Integer index = 0;
  Boolean singleton = listLength(inElementItems) == 1;
  Absyn.Class c;
  Absyn.Restriction r;
algorithm
  outElementItems := list(match e
    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
        Absyn.CLASSDEF(class_ = c as Absyn.CLASS(restriction = Absyn.R_RECORD()))))
      algorithm
        // Change the record into a metarecord and add it to the list of metaclasses.
        r := Absyn.R_METARECORD(Absyn.IDENT(inName), index, singleton, true);
        c.restriction := r;
        outMetaClasses := c :: outMetaClasses;
        // Change the record into a metarecord and update the original class.
        r := Absyn.R_METARECORD(Absyn.IDENT(inName), index, singleton, false);
        c.restriction := r;
        index := index + 1;
      then
        setElementItemClass(e, c);

    else e;
  end match for e in inElementItems);
end fixElementItems;

public function fixUniontype
  input ClassInf.State inState;
  input SCode.ClassDef inClassDef;
  output Option<DAE.Type> outType;
algorithm
  outType := match (inState, inClassDef)
    local
      Boolean b;
      Absyn.Path p;
      list<Absyn.Path> paths;
      list<String> names, singletonFields;
      DAE.TypeSource ts;

    case (ClassInf.META_UNIONTYPE(), SCode.PARTS())
      algorithm
        p := Absyn.makeFullyQualified(inState.path);
        names := SCode.elementNames(inClassDef.elementLst);
        paths := list(Absyn.pathReplaceIdent(p, n) for n in names);
        b := listLength(paths)==1;
        if b then
          singletonFields := SCode.componentNames(listGet(inClassDef.elementLst, 1));
        else
          singletonFields := {};
        end if;
        ts := Types.mkTypeSource(SOME(p));
      then
        SOME(DAE.T_METAUNIONTYPE(paths,b,singletonFields,ts));

    else NONE();
  end match;
end fixUniontype;

public function checkArrayType
  "Checks that an array type is valid."
  input DAE.Type inType;
protected
  DAE.Type el_ty;
algorithm
  el_ty := Types.arrayElementType(inType);
  false := (not Types.isString(el_ty) and Types.isBoxedType(el_ty)) or
    Flags.isSet(Flags.RML);
end checkArrayType;

public function transformArrayNodesToListNodes
  input list<Absyn.Exp> inList;
  output list<Absyn.Exp> outList;
algorithm
  outList := list(match e
    case Absyn.ARRAY({}) then Absyn.LIST({});
    case Absyn.ARRAY()
      then Absyn.LIST(transformArrayNodesToListNodes(e.arrayExp));
    else e;
  end match for e in inList);
end transformArrayNodesToListNodes;

annotation(__OpenModelica_Interface="frontend");
end MetaUtil;

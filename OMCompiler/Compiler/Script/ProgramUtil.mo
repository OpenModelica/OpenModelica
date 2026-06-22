/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package ProgramUtil
" file:        ProgramUtil.mo
  package:     ProgramUtil
  description: Absyn program-tree navigation and manipulation helpers, factored
               out of InteractiveUtil so lower layers (backend/SimCode) can use
               them without depending on the interactive/scripting layer."

import Absyn;

protected
import AbsynUtil;
import DoubleEnded;
import Dump;
import Error;
import FBuiltin;
import List;
import Print;
import Util;
import Testsuite;
import System;
import Settings;
import Autoconf;

public
public function buildWithin
" From a fully qualified model name, build a suitable within clause"
  input Absyn.Path inPath;
  output Absyn.Within outWithin;
algorithm
  outWithin := match inPath
    local Absyn.Path w_path,path;
    case Absyn.IDENT() then Absyn.TOP();
    case Absyn.FULLYQUALIFIED(path) // handle fully qual also!
      then
        buildWithin(path);
    case path
      algorithm
        w_path := AbsynUtil.stripLast(path);
      then
        Absyn.WITHIN(w_path);
  end match;
end buildWithin;
public function updateProgram
" This function takes an old program (second argument), i.e. the old
   symboltable, and a new program (first argument), i.e. a new set of
   classes and updates the old program with the definitions in the new one.
   It also takes in the current symboltable and returns a new one with any
   replaced functions cache cleared."
  input Absyn.Program inNewProgram;
  input Absyn.Program inOldProgram;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Program outProgram;
protected
  list<Absyn.Class> cs;
  Absyn.Within w;
algorithm
  Absyn.PROGRAM(classes=cs,within_=w) := inNewProgram;
  outProgram := updateProgram2(listReverse(cs),w,inOldProgram, mergeAST);
end updateProgram;
public function updateProgram2
" This function takes an old program (second argument), i.e. the old
   symboltable, and a new program (first argument), i.e. a new set of
   classes and updates the old program with the definitions in the new one.
   It also takes in the current symboltable and returns a new one with any
   replaced functions cache cleared."
  input list<Absyn.Class> inNewClasses;
  input Absyn.Within w;
  input Absyn.Program inOldProgram;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Program outProgram;
algorithm
  outProgram := match (inNewClasses,w,inOldProgram)
    local
      Absyn.Program prg,newp,p2,newp_1;
      Absyn.Class c1;
      String name;
      list<Absyn.Class> c2,c3;
      Absyn.Within w2;

    case ({},_,prg) then prg;

    case ((c1 as Absyn.CLASS(name = name)) :: c2,Absyn.TOP(), (p2 as Absyn.PROGRAM(classes = c3,within_ = w2)))
      algorithm
        if classInProgram(name, p2) then
          newp := replaceClassInProgram(c1, p2, mergeAST);
        else
          newp := Absyn.PROGRAM((c1 :: c3),w2);
        end if;
      then updateProgram2(c2,w,newp, mergeAST);

    case ((c1 :: c2),Absyn.WITHIN(),p2)
      algorithm
        newp := insertClassInProgram(c1, w, p2, mergeAST);
        newp_1 := updateProgram2(c2,w,newp, mergeAST);
      then newp_1;

  end match;
end updateProgram2;
public function getClassnamesInParts
"Helper function to getClassnamesInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynClassPartLst,inShowProtected,includeConstants)
    local
      list<String> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      Boolean b,c;

    case ({},_,_) then {};

    case ((Absyn.PUBLIC(contents = elts) :: rest),b,c)
      algorithm
        l1 := getClassnamesInElts(elts,c);
        l2 := getClassnamesInParts(rest,b,c);
        res := listAppend(l1, l2);
      then
        res;

    // adeas31 2012-01-25: Also check the protected sections.
    case ((Absyn.PROTECTED(contents = elts) :: rest), true, c)
      algorithm
        l1 := getClassnamesInElts(elts,c);
        l2 := getClassnamesInParts(rest,true,c);
        res := listAppend(l1, l2);
      then
        res;

    case ((_ :: rest),b,c)
      algorithm
        res := getClassnamesInParts(rest,b,c);
      then
        res;

  end matchcontinue;
end getClassnamesInParts;
public function getClassnamesInElts
"Helper function to getClassnamesInParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Boolean includeConstants;
  output list<String> outStringLst;
protected
  DoubleEnded.MutableList<String> delst;
algorithm
  delst := DoubleEnded.fromList({});
  for elt in inAbsynElementItemLst loop
  () := match elt
    local
      String id;
      list<Absyn.ComponentItem> lst;

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ =
                 Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = id)))))
      algorithm
        DoubleEnded.push_back(delst, id);
      then ();

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ =
                 Absyn.CLASS(name = id))))
      algorithm
        DoubleEnded.push_back(delst, id);
      then ();

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(attributes = Absyn.ATTR(variability = Absyn.CONST()),
                 components = lst))) guard includeConstants
      algorithm
        DoubleEnded.push_list_back(delst, getComponentItemsName(lst,false));
      then ();

    else ();
  end match;
  end for;
  outStringLst := DoubleEnded.toListAndClear(delst);
end getClassnamesInElts;
public function getComponentItemsName
" separated list of all component names."
  input list<Absyn.ComponentItem> inComponents;
  input Boolean inQuoteNames "Adds quotes around the component names if true.";
  output list<String> outStrings = {};
protected
  String name;
algorithm
  for comp in listReverse(inComponents) loop
    () := match comp
      case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name))
        algorithm
          outStrings := (if inQuoteNames then
            stringAppendList({"\"", name, "\""}) else
            stringAppendList({name})) :: outStrings;
        then
          ();

      else ();
    end match;
  end for;
end getComponentItemsName;
public function replaceClassInProgram2
  input Absyn.Class inClass;
  input String inClassName;
  output Boolean outReplace;
protected
  String cls_name;
algorithm
  Absyn.CLASS(name = cls_name) := inClass;
  outReplace := cls_name == inClassName;
end replaceClassInProgram2;
public function replaceClassInProgram
" This function takes a Class and a Program and replaces the class
   definition at the top level in the program by the class definition of
   the Class. It also updates the functionlist for the symboltable if needed."
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Program outProgram;
protected
  String cls_name1;
  list<Absyn.Class> clst, clsFilter;
  Absyn.Within w;
  Boolean replaced;
  Absyn.Class cls;
algorithm
  Absyn.CLASS(name = cls_name1) := inClass;
  Absyn.PROGRAM(classes = clst, within_ = w) := inProgram;
  if mergeAST then
    clsFilter := List.filterOnTrue(clst, function replaceClassInProgram2(inClassName = cls_name1));
    if listEmpty(clsFilter)
    then
      cls := inClass;
    else
      cls::_ := clsFilter;
      cls := mergeClasses(inClass, cls);
    end if;
  else
   cls := inClass;
  end if;
  (clst, replaced) := List.replaceOnTrue(cls, clst,
    function replaceClassInProgram2(inClassName = cls_name1));

  if not replaced then
    clst := List.appendElt(inClass, clst);
  end if;

  outProgram := Absyn.PROGRAM(clst, w);
end replaceClassInProgram;
public function insertClassInProgram
" This function inserts the class into the Program at the scope given by
   the within argument. If the class referenced by the within argument is
   not defined, the function prints an error message and fails."
  input Absyn.Class inClass;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inClass,inWithin,inProgram)
    local
      Absyn.Class c2,c3,c1;
      Absyn.Program pnew,p;
      Absyn.Within w;
      String n1,s1,s2,name;
      list<Absyn.Path> paths;

    case (c1,(w as Absyn.WITHIN(path = Absyn.QUALIFIED(name = n1))),p as Absyn.PROGRAM())
      algorithm
        c2 := getClassInProgram(n1, p);
        c3 := insertClassInClass(c1, w, c2, mergeAST);
        pnew := updateProgram(Absyn.PROGRAM({c3},Absyn.TOP()), p, mergeAST);
      then
        pnew;

    case (c1,(w as Absyn.WITHIN(path = Absyn.IDENT(name = n1))),p as Absyn.PROGRAM())
      algorithm
        c2 := getClassInProgram(n1, p);
        c3 := insertClassInClass(c1, w, c2, mergeAST);
        pnew := updateProgram(Absyn.PROGRAM({c3},Absyn.TOP()), p, mergeAST);
      then
        pnew;

    case (_,Absyn.WITHIN(path=Absyn.QUALIFIED(name="OpenModelica")),p) then p;

    case ((Absyn.CLASS(name = name)),w,p)
      algorithm
        s1 := Dump.unparseWithin(w);
        /* adeas31 2012-01-25: false indicates that the classnamesrecursive doesn't look into protected sections */
        /* adeas31 2016-11-29: false indicates that the classnamesrecursive doesn't look for constants */
        (_, paths) := getClassNamesRecursive(NONE(), p, false, false, {});
        s2 := stringAppendList(List.map1r(list(AbsynUtil.pathString(p) for p in paths),stringAppend,"\n  "));
        Error.addMessage(Error.INSERT_CLASS, {name,s1,s2});
      then
        fail();

  end matchcontinue;
end insertClassInProgram;
public function insertClassInClass "
   This function takes a class to update (the first argument)  and an inner
   class (which is either replacing
   an earlier class or is a new inner definition) and a within statement
   pointing inside the class (including the class itself in the reference),
   and updates the class with the inner class.
"
  input Absyn.Class inClass1;
  input Absyn.Within inWithin2;
  input Absyn.Class inClass3;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Class outClass;
algorithm
  outClass := match (inClass1,inWithin2,inClass3)
    local
      Absyn.Class cnew,c1,c2,cinner;
      String name2;
      Absyn.Path path;

    case (c1,Absyn.WITHIN(path = Absyn.IDENT()),c2)
      then replaceInnerClass(c1, c2, mergeAST);

    case (c1,Absyn.WITHIN(path = Absyn.QUALIFIED(path = path)),c2)
      algorithm
        name2 := AbsynUtil.pathFirstIdent(path);
        cinner := getInnerClass(c2, name2);
        cnew := insertClassInClass(c1, Absyn.WITHIN(path), cinner, mergeAST);
      then replaceInnerClass(cnew, c2, mergeAST);

  end match;
end insertClassInClass;
public function replaceInnerClass
"This function takes two class definitions. The first one is
  inserted/replaced as a local class inside the second one."
  input Absyn.Class inClass1;
  input Absyn.Class inClass2;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass1,inClass2)
    local
      list<Absyn.ElementItem> publst,publst2,prolst,prolst2;
      list<Absyn.ClassPart> parts2,parts;
      Absyn.Class c1;
      String bcname;
      Option<String> cmt;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    // a class with parts - we can find the element in the public list
    case (c1,outClass as Absyn.CLASS(body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann=ann,comment = cmt)))
      algorithm
        publst := getPublicList(parts);
        (publst2, true) := replaceClassInElementitemlist(publst, c1, mergeAST);
        parts2 := replacePublicList(parts, publst2);
        outClass.body := Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;

    // a class with parts - we can find the element in the protected list
    case (c1,outClass as Absyn.CLASS(
                         body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann=ann,comment = cmt)))
      algorithm
        prolst := getProtectedList(parts);
        (prolst2, true) := replaceClassInElementitemlist(prolst, c1, mergeAST);
        parts2 := replaceProtectedList(parts, prolst2);
        outClass.body := Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;

    // a class with parts - we cannot find the element in the public or protected list, add it to the public list
    case (c1,outClass as Absyn.CLASS(
                         body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann=ann,comment = cmt)))
      algorithm
        publst := getPublicList(parts);
        publst := addClassInElementitemlist(publst, c1);
        parts2 := replacePublicList(parts, publst);
        outClass.body := Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;

    // an extended class with parts: model extends M end M; - we can find the element in the public list
    case (c1,outClass as Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications = modif,parts = parts,ann=ann,comment = cmt)))
      algorithm
        publst := getPublicList(parts);
        (publst2, true) := replaceClassInElementitemlist(publst, c1, mergeAST);
        parts2 := replacePublicList(parts, publst2);
        outClass.body := Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann);
      then
        outClass;

    // an extended class with parts: model extends M end M; - we can find the element in the protected list
    case (c1,outClass as Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications = modif,parts = parts,ann=ann,comment = cmt)))
      algorithm
        prolst := getProtectedList(parts);
        (prolst2, true) := replaceClassInElementitemlist(prolst, c1, mergeAST);
        parts2 := replaceProtectedList(parts, prolst2);
        outClass.body := Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann);
      then
        outClass;

    // an extended class with parts: model extends M end M; - we cannot find the element in the public or protected list, add it to the public list
    case (c1,outClass as Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications = modif,parts = parts,ann=ann,comment = cmt)))
      algorithm
        publst := getPublicList(parts);
        publst := addClassInElementitemlist(publst, c1);
        parts2 := replacePublicList(parts, publst);
        outClass.body := Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann);
      then
        outClass;

    else
      algorithm
        Print.printBuf("Failed in replaceInnerClass\n");
      then
        fail();
  end matchcontinue;
end replaceInnerClass;
public function replaceClassInElementitemlist
"This function takes an Element list and a Class and returns a modified
  element list where the class definition of the class is updated or added."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Class inClass;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output list<Absyn.ElementItem> outAbsynElementItemLst;
  output Boolean replaced "true signals a replacement, false nothing changed!";
algorithm
  (outAbsynElementItemLst, replaced) := match (inAbsynElementItemLst,inClass)
    local
      list<Absyn.ElementItem> res,xs;
      Absyn.ElementItem e1;
      Absyn.Class c, c1, c2;
      String name1,name;
      Boolean a,e;
      Option<Absyn.RedeclareKeywords> b;
      SourceInfo info;
      Option<Absyn.ConstrainClass> h;
      Absyn.InnerOuter io;

    case (((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = a,redeclareKeywords = b,innerOuter = io,specification = Absyn.CLASSDEF(replaceable_ = e,class_ = c1 as Absyn.CLASS(name = name1)),constrainClass = h))) :: xs),(c2 as Absyn.CLASS(name = name)))
      guard stringEq(name1, name)
      algorithm
        c := if mergeAST then mergeClasses(c2, c1) else c2;
        Absyn.CLASS(info = info) := c;
      then
        (Absyn.ELEMENTITEM(Absyn.ELEMENT(a,b,io,Absyn.CLASSDEF(e,c),info /* The new CLASS might have update info */,h)) :: xs, true);

    case ((e1 :: xs),c)
      algorithm
        (res, replaced) := replaceClassInElementitemlist(xs, c, mergeAST);
      then
        (e1 :: res, replaced);

    else ({}, false);

  end match;
end replaceClassInElementitemlist;
public function addClassInElementitemlist
"This function takes an Element list and a Class and returns a modified
  element list where the class definition of the class is updated or added."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Class inClass;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
protected
  Absyn.Info info;
algorithm
  Absyn.CLASS(info=info) := inClass;
  outAbsynElementItemLst := listAppend(inAbsynElementItemLst,
          {Absyn.ELEMENTITEM(
             Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),Absyn.CLASSDEF(false,inClass),
             info,NONE()))});
end addClassInElementitemlist;
public function getInnerClass
"This function takes a class name and a class and
  returns the inner class definition having that name."
  input Absyn.Class inClass;
  input Absyn.Ident inIdent;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,inIdent)
    local
      list<Absyn.ElementItem> publst,prolst;
      Absyn.Class c1;
      list<Absyn.ClassPart> parts;
      String name;

    // class found in public
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),name)
      algorithm
        publst := getPublicList(parts);
        c1 := getClassFromElementitemlist(publst, name);
      then
        c1;

    // class found in protected
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),name)
      algorithm
        prolst := getProtectedList(parts);
        c1 := getClassFromElementitemlist(prolst, name);
      then
        c1;

    // class found in public
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),name)
      algorithm
        publst := getPublicList(parts);
        c1 := getClassFromElementitemlist(publst, name);
      then
        c1;

    // class found in protected
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),name)
      algorithm
        prolst := getProtectedList(parts);
        c1 := getClassFromElementitemlist(prolst, name);
      then
        c1;

/* Does nothing
    case (c as Absyn.CLASS(),name)
      algorithm
        handle = Print.saveAndClearBuf();
        Print.printBuf("getInnerClass failed, c:");
        Dump.dump(Absyn.PROGRAM({c},Absyn.TOP()));
        Print.printBuf("name :");
        Print.printBuf(name);
        Print.clear(); // Print.getString();
        Print.restoreBuf(handle);
      then
        fail();
*/
  end matchcontinue;
end getInnerClass;
public function replacePublicList
" This function replaces the ElementItem list in
   the ClassPart list, and returns the updated list.
   If no public list is available, one is created."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst := match (inAbsynClassPartLst,inAbsynElementItemLst)
    local
      list<Absyn.ClassPart> rest_1,rest,ys,xs;
      Absyn.ClassPart x;
      list<Absyn.ElementItem> newpublst,new,newpublist;

    case (((Absyn.PUBLIC()) :: rest),newpublst)
      algorithm
        rest_1 := deletePublicList(rest);
      then
        (Absyn.PUBLIC(newpublst) :: rest_1);

    case ((x :: xs),new)
      algorithm
        ys := replacePublicList(xs, new);
      then
        (x :: ys);

    case ({},newpublist) then {Absyn.PUBLIC(newpublist)};

  end match;
end replacePublicList;
public function replaceProtectedList "
  This function replaces the `ElementItem\' list in the `ClassPart\' list,
  and returns the updated list.
  If no protected list is available, one is created.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst := match (inAbsynClassPartLst,inAbsynElementItemLst)
    local
      list<Absyn.ClassPart> rest_1,rest,ys,xs;
      Absyn.ClassPart x;
      list<Absyn.ElementItem> newprotlist,new;

    case (((Absyn.PROTECTED()) :: rest),newprotlist)
      algorithm
        rest_1 := deleteProtectedList(rest);
      then
        (Absyn.PROTECTED(newprotlist) :: rest_1);

    case ((x :: xs),new)
      algorithm
        ys := replaceProtectedList(xs, new);
      then
        (x :: ys);

    case ({},newprotlist) then {Absyn.PROTECTED(newprotlist)};

  end match;
end replaceProtectedList;
public function deletePublicList "
  Deletes all PULIC classparts from the list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  match inAbsynClassPartLst
    local
      list<Absyn.ClassPart> res,xs;
      Absyn.ClassPart x;
    case {} then {};
    case Absyn.PUBLIC() :: xs
      algorithm
        res := deletePublicList(xs);
      then
        res;
    case x :: xs
      algorithm
        res := deletePublicList(xs);
      then
        (x :: res);
  end match;
end deletePublicList;
public function deleteProtectedList "
  Deletes all PROTECTED classparts from the list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  match inAbsynClassPartLst
    local
      list<Absyn.ClassPart> res,xs;
      Absyn.ClassPart x;
    case {} then {};
    case Absyn.PROTECTED() :: xs
      algorithm
        res := deleteProtectedList(xs);
      then
        res;
    case x :: xs
      algorithm
        res := deleteProtectedList(xs);
      then
        (x :: res);
  end match;
end deleteProtectedList;
public function getPublicList "
  This function takes a ClassPart List and returns an appended list of
  all public lists.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  match inAbsynClassPartLst
    local
      list<Absyn.ElementItem> res2,res,res1,ys;
      list<Absyn.ClassPart> rest,xs;
    case {} then {};
    case Absyn.PUBLIC(contents = res1) :: rest
      algorithm
        res2 := getPublicList(rest);
        res := listAppend(res1, res2);
      then
        res;
    case _ :: xs
      algorithm
        ys := getPublicList(xs);
      then
        ys;
  end match;
end getPublicList;
public function getProtectedList "
  This function takes a ClassPart List and returns an appended list of
  all protected lists."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  match inAbsynClassPartLst
    local
      list<Absyn.ElementItem> res2,res,res1,ys;
      list<Absyn.ClassPart> rest,xs;
    case {} then {};
    case Absyn.PROTECTED(contents = res1) :: rest
      algorithm
        res2 := getProtectedList(rest);
        res := listAppend(res1, res2);
      then
        res;
    case _ :: xs
      algorithm
        ys := getProtectedList(xs);
      then
        ys;
  end match;
end getProtectedList;
public function getClassFromElementitemlist "
  This function takes an ElementItem list and an Ident and returns the
  class definition among the element list having that identifier.
"
  input list<Absyn.ElementItem> inElements;
  input Absyn.Ident inIdent;
  output Absyn.Class outClass;
protected
  Absyn.ElementItem elem;
algorithm
  elem := List.getMemberOnTrue(inIdent, inElements, classElementItemIsNamed);
  Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
    Absyn.CLASSDEF(class_ = outClass))) := elem;
end getClassFromElementitemlist;
public function classInProgram
"This function takes a name and a Program and returns
  true if the name exists as a top class in the program."
  input String name;
  input Absyn.Program p;
  output Boolean b;
algorithm
  b := match p
    local
      String str;
    case Absyn.PROGRAM()
      algorithm
        for cl in p.classes loop
          Absyn.CLASS(name=str) := cl;
          if str == name then
            b := true;
            return;
          end if;
        end for;
      then false;
  end match;
end classInProgram;
public function getPathedClassInProgram
"This function takes a Path and a Program and retrieves the
  class definition referenced by the Path from the Program.
  If enclOnErr is true and such class doesn't exist return enclosing class."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Boolean enclOnErr = false;
  input Boolean showError = false;
  output Absyn.Class outClass;
algorithm
  outClass := matchcontinue ()
    case () then getPathedClassInProgramWork(inPath, inProgram, enclOnErr);
    case () then getPathedClassInProgramWork(inPath, FBuiltin.getInitialFunctions(), enclOnErr);

    else
      algorithm
        if showError then
          Error.addMessage(Error.LOOKUP_ERROR,
            {AbsynUtil.pathString(inPath), "<TOP>"});
        end if;
      then
        fail();

  end matchcontinue;
end getPathedClassInProgram;
public function getPathedClassInProgramWork
  "This function takes a Path and a Program and retrieves the class definition
   referenced by the Path from the Program.
   If enclOnErr is true and such class doesn't exist return enclosing class."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Boolean enclOnErr = false;
  output Absyn.Class outClass;
algorithm
  outClass := match inPath
    local
      Absyn.Class c;

    case Absyn.IDENT()
      then getClassInProgram(inPath.name, inProgram);

    case Absyn.QUALIFIED()
      algorithm
        c := getClassInProgram(inPath.name, inProgram);
      then
        getPathedClassInClass(inPath.path, c, enclOnErr);

    case Absyn.FULLYQUALIFIED()
      then
        getPathedClassInProgramWork(inPath.path, inProgram, enclOnErr);

  end match;
end getPathedClassInProgramWork;
public function getPathedClassInClass
  "Retrieves the class definition referenced by the Path in the given class.
   If such class doesn't exist return the class itself if enclOnError = true, otherwise fail."
  input Absyn.Path inPath;
  input Absyn.Class inClass;
  input Boolean enclOnError;
  output Absyn.Class outClass;
algorithm
  outClass := matchcontinue inPath
    local
      Absyn.Class c;
      String str;
      Absyn.Path path;

    case Absyn.IDENT(name = str)
      then
        getClassInClass(str, inClass);

    case Absyn.FULLYQUALIFIED(path)
      then
        getPathedClassInClass(path, inClass, enclOnError);

    case Absyn.QUALIFIED(name = str, path = path)
      algorithm
        c := getClassInClass(str, inClass);
      then
        getPathedClassInClass(path, c, enclOnError);

    case _ guard enclOnError then inClass;
  end matchcontinue;
end getPathedClassInClass;
public function getClassInClass
  "Looks up a named class in the given class. Fails if the class can't be found."
  input String name;
  input Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm
  for part in AbsynUtil.getClassPartsInClass(inClass) loop
    for item in AbsynUtil.getElementItemsInClassPart(part) loop
      if AbsynUtil.isElementItemClassNamed(name, item) then
        outClass := AbsynUtil.elementItemClass(item);
        return;
      end if;
    end for;
  end for;

  fail();
end getClassInClass;
public function getClassInProgram
  "Looks up a function with the given name in a program, or fails if the class doesn't exist."
  input String name;
  input Absyn.Program program;
  output Absyn.Class cls;
algorithm
  cls := List.find(program.classes, function AbsynUtil.isClassNamed(inName = name));
end getClassInProgram;
public function getClassnamesInClassList
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  output list<String> outString;
algorithm
  outString:=
  match (inClass, inShowProtected, includeConstants)
    local
      list<String> strlist;
      list<Absyn.ClassPart> parts;
      Boolean b,c;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)), b, c)
      algorithm
        strlist := getClassnamesInParts(parts,b,c);
      then
        strlist;

    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)), b, c)
      algorithm
        strlist := getClassnamesInParts(parts,b,c);
      then strlist;

    case (Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH())), _, _)
      algorithm
        //(cdef,newpath) = lookupClassdef(path, inmodel, p);
        //res = getClassnamesInClassList(newpath, p, cdef);
      then
        {};//res;

    case (Absyn.CLASS(body = Absyn.OVERLOAD()), _, _)
      algorithm
      then {};

    case (Absyn.CLASS(body = Absyn.ENUMERATION()), _, _)
      algorithm
      then {};

    case (Absyn.CLASS(body = Absyn.PDER()), _, _)
      algorithm
      then {};

  end match;
end getClassnamesInClassList;
public function getClassNamesRecursive
"Returns a string with all the classes for a given path."
  input Option<Absyn.Path> inPath;
  input Absyn.Program inProgram;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  input list<Absyn.Path> inAcc;
  output Option<Absyn.Path> opath;
  output list<Absyn.Path> paths;
algorithm
  (opath,paths) := matchcontinue (inPath,inProgram,inShowProtected,includeConstants,inAcc)
    local
      Absyn.Class cdef;
      String s1;
      list<String> strlst;
      Absyn.Path pp;
      Absyn.Program p;
      list<Absyn.Class> classes;
      list<Option<Absyn.Path>> result_path_lst;
      list<Absyn.Path> acc;
      Boolean b,c;

    case (SOME(pp),p,b,c,acc)
      algorithm
        acc := pp::acc;
        cdef := getPathedClassInProgram(pp, p);
        strlst := getClassnamesInClassList(pp, p, cdef, b, c);
        result_path_lst := List.map(List.map1(strlst, joinPaths, pp),Util.makeOption);
        (_,acc) := List.map3Fold(result_path_lst, getClassNamesRecursive, p, b, c, acc);
      then (inPath,acc);
    case (NONE(),p as Absyn.PROGRAM(classes=classes),b,c,acc)
      algorithm
        strlst := List.map(classes, AbsynUtil.getClassName);
        result_path_lst := List.mapMap(strlst, AbsynUtil.makeIdentPathFromString, Util.makeOption);
        (_,acc) := List.map3Fold(result_path_lst, getClassNamesRecursive, p, b, c, acc);
      then (inPath,acc);
    case (SOME(pp),_,_,_,_)
      algorithm
        s1 := AbsynUtil.pathString(pp);
        Error.addMessage(Error.LOOKUP_ERROR, {s1,"<TOP>"});
      then (inPath,{});
  end matchcontinue;
end getClassNamesRecursive;
public function mergeClasses
"@author adrpo
 merge two classes cNew and cOld in the following way:
 1. get all the inner class definitions from cOld that were loaded from a different file than itself
 2. append all elements from step 1 to class cNew public list!"
   input  Absyn.Class cNew;
   input  Absyn.Class cOld;
   output Absyn.Class c;
algorithm
  c := matchcontinue(cNew, cOld)
    local
      list<Absyn.ClassPart> partsC1, partsC2;
      list<Absyn.ElementItem> pubElementsC1, pubElementsC2;
      String file;
      list<String> typeVars1;
      list<Absyn.NamedArg> classAttrs1;
      list<Absyn.Annotation> ann1;
      Option<String> cmt1;


    // if cOld has no parts then just return cNew
    case (_, Absyn.CLASS(body = Absyn.PARTS(classParts = {}))) then cNew;
    case (_, Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {}))) then cNew;

    // if cNew and cOld has parts, get the foreign elements (loaded from other file) from cOld
    // and append them to the public list of cNew
    case (c as Absyn.CLASS(body=Absyn.PARTS(typeVars1,classAttrs1,partsC1,ann1,cmt1)),
          Absyn.CLASS(body = Absyn.PARTS(classParts = partsC2), info = SOURCEINFO(fileName = file)))
      algorithm
        pubElementsC2 := getPublicList(partsC2);
        pubElementsC2 := excludeElementsFromFile(file, pubElementsC2);
        pubElementsC1 := getPublicList(partsC1);
        pubElementsC1 := mergeElements(pubElementsC1, pubElementsC2);
        partsC1 := replacePublicList(partsC1, pubElementsC1);
        c.body := Absyn.PARTS(typeVars1,classAttrs1,partsC1,ann1,cmt1);
      then c;

    // TODO! FIXME! handle also CLASS_EXTENDS!
    // if the class cNew or cOld is not containing parts then don't bother, just replace the entire class!
    case (_, _) then cNew;
  end matchcontinue;
end mergeClasses;
public function mergeElement
"@author adrpo
 merge the element given as second argument with the element from the first list with same name.
  if no such elements are in the first list, just append it at the end"
  input  list<Absyn.ElementItem> inEls;
  input  Absyn.ElementItem inEl;
  output list<Absyn.ElementItem> outEls;
algorithm
  outEls := matchcontinue(inEls, inEl)
    local
      String n1,n2;
      list<Absyn.ElementItem> rest, filtered;
      Absyn.ElementItem e1,e2;
      Boolean r;
      Boolean f;
      Option<Absyn.RedeclareKeywords> redecl;
      Absyn.InnerOuter innout ;
      String name;
      Absyn.Info i;
      Option<Absyn.ConstrainClass> cc;
      Absyn.Class c1, c2;
    case ({}, _) then inEl::{};
    // not found put it at the end
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(f, redecl, innout, Absyn.CLASSDEF(r, c1 as Absyn.CLASS(name = n1)), i, cc)) :: rest,
          Absyn.ELEMENTITEM(Absyn.ELEMENT(specification = Absyn.CLASSDEF(_,c2 as Absyn.CLASS(name = n2)))))
      algorithm
        true := stringEqual(n1, n2);
         // element found, merge it!
        c1 := mergeClasses(c1, c2);
      then
        Absyn.ELEMENTITEM(Absyn.ELEMENT(f, redecl, innout, Absyn.CLASSDEF(r, c1), i, cc)) :: rest;
    case (e1 :: rest, e2)
      algorithm
        // try the second from the first list
        filtered := mergeElement(rest, e2);
      then
         e1::filtered;
  end matchcontinue;
end mergeElement;
public function mergeElements
  "@author adrpo see merge element"
   input  list<Absyn.ElementItem> inEls1;
   input  list<Absyn.ElementItem> inEls2;
   output list<Absyn.ElementItem> outEls;
  algorithm
    outEls := match(inEls1, inEls2)
    local
      list<Absyn.ElementItem> rest, merged;
      Absyn.ElementItem e2;
      case ({}, _) then inEls2;
      case (_, {}) then inEls1;
      case (_, e2::rest)
        algorithm
          merged := mergeElement(inEls1, e2);
          merged := mergeElements(merged, rest);
        then merged;
    end match;
end mergeElements;
public function excludeElementsFromFile
"exclude all elements which are part of the given file"
  input  String inFile;
  input  list<Absyn.ElementItem> inEls;
  output list<Absyn.ElementItem> outEls;
algorithm
  outEls := match (inFile,inEls)
    local
      Absyn.ElementItem e;
      list<Absyn.ElementItem> rest, filtered;
      String f,file;
      Boolean b = false;

    case (_,{}) then {};
    // elements can come from different files
    case (file,(e as Absyn.ELEMENTITEM(Absyn.ELEMENT(info = SOURCEINFO(fileName = f))))::rest)
      algorithm
        b := stringEqual(file, f); // not from this file, use it, else discard!
        filtered := excludeElementsFromFile(file, rest);
      then if not b then e::filtered else filtered;
    // lexer comments can only be from this file, exclude
    case (file,(Absyn.LEXER_COMMENT(_))::rest)
      algorithm
        filtered := excludeElementsFromFile(file, rest);
      then filtered;
  end match;
end excludeElementsFromFile;
public function getClassnamesInClass
" This function takes a `Class\' definition and a Path identifying the
   class.
   It returns a string containing comma separated package names found
   in the class definition.
   The list also contains proctected classes if inShowProtected is true."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  output list<Absyn.Path> paths;
algorithm
  paths := match (inClass, inShowProtected, includeConstants)
    local
      list<String> strlist;
      list<Absyn.ClassPart> parts;
      Boolean b,c;
    /* a class with parts */
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)), b, c)
      algorithm
        strlist := ProgramUtil.getClassnamesInParts(parts,b,c);
      then List.map(strlist,AbsynUtil.makeIdentPathFromString);
    /* an extended class with parts: model extends M end M; */
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)), b, c)
      algorithm
        strlist := ProgramUtil.getClassnamesInParts(parts,b,c);
      then List.map(strlist,AbsynUtil.makeIdentPathFromString);
    /* a derived class */
    case (Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(_, _))), _, _)
      algorithm
        /* adrpo 2009-10-27: we sholdn't dive into derived classes!
        (cdef,newpath) = lookupClassdef(path, inmodel, p);
        res = getClassnamesInClass(newpath, p, cdef);
        */
      then {};
  end match;
end getClassnamesInClass;
public function classElementItemIsNamed
  input String inClassName;
  input Absyn.ElementItem inElement;
  output Boolean outIsNamed;
algorithm
  outIsNamed := match inElement
    local
      String name;

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
        Absyn.CLASSDEF(class_ = (Absyn.CLASS(name = name)))))
      then inClassName == name;

    else false;
  end match;
end classElementItemIsNamed;
public function joinPaths
  input String child;
  input Absyn.Path parent;
  output Absyn.Path outPath;
algorithm
  outPath := match (child, parent)
    local
      Absyn.Path r, res;
      String c;
    case (c, r)
      algorithm
        res := AbsynUtil.joinPaths(r, Absyn.IDENT(c));
      then res;
  end match;
end joinPaths;
public function getDefaultComponentPrefixesModStr "Extractor function for defaultComponentPrefixes modifier"
  input Option<Absyn.Modification> mod;
  output String docStr;
algorithm
  docStr := matchcontinue mod
    local Absyn.Exp e;
    case SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=e))) algorithm
      docStr := Dump.printExpStr(e);
    then docStr;
    else "";
  end matchcontinue;
end getDefaultComponentPrefixesModStr;
public function getNamedAnnotationExp
"This function takes a Path and a Program and returns a comma separated
  string of values for the Documentation annotation for the class named by the
  first argument."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Path id;
  input Option<T> default;
  input ModFunc f;
  partial function ModFunc
    input Option<Absyn.Modification> mod;
    output T docStr;
  end ModFunc;
  output T outString;
  replaceable type T subtypeof Any;
algorithm
  outString := matchcontinue (inPath, inProgram, default)
    local
      Absyn.Class cdef;
      T str;
      Absyn.Path modelpath;
      Absyn.Program p;

    case (modelpath, p, _)
      algorithm
        cdef := getPathedClassInProgram(modelpath, p);
        SOME(str) := AbsynUtil.getNamedAnnotationInClass(cdef,id,f);
      then
        str;

    case (_, _, SOME(str)) then str;
  end matchcontinue;
end getNamedAnnotationExp;
public function getFileDir "author: x02lucpo
  returns the dir where class file (.mo) was saved or
  $OPENMODELICAHOME/work if the file was not saved yet"
  input Absyn.ComponentRef inComponentRef "class";
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      String filename,pd,dir_1,omhome,omhome_1;
      String pd_1;
      list<String> filename_1,dir;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (class_,p)
      algorithm
        p_class := AbsynUtil.crefToPath(class_) "change to the saved files directory" ;
        cdef := getPathedClassInProgram(p_class, p);
        filename := AbsynUtil.classFilename(cdef);
        pd := Autoconf.pathDelimiter;
        pd_1 :: _ := stringListStringChar(pd);
        filename_1 := Util.stringSplitAtChar(filename, pd_1);
        dir := List.stripLast(filename_1);
        dir_1 := stringDelimitList(dir, pd);
      then
        dir_1;
    case (_,_)
      algorithm
        omhome := Settings.getInstallationDirectoryPath() "model not yet saved! change to $OPENMODELICAHOME/work" ;
        omhome_1 := System.trim(omhome, "\"");
        pd := Autoconf.pathDelimiter;
        dir_1 := stringAppendList({"\"",omhome_1,pd,"work","\""});
      then
        dir_1;
    else "";  /* this function should never fail */
  end matchcontinue;
end getFileDir;
public function getFullPathFromUri
  input Absyn.Program program;
  input String uri;
  input Boolean printError;
  output String path;
protected
  String str1,str2,str3;
algorithm
  (str1,str2,str3) := System.uriToClassAndPath(uri);
  path := getBasePathFromUri(str1,str2,program,Settings.getModelicaPath(Testsuite.isRunning()),printError) + str3;
end getFullPathFromUri;
public function getBasePathFromUri "Handle modelica:// URIs"
  input String scheme;
  input String iname;
  input Absyn.Program program;
  input String modelicaPath;
  input Boolean printError;
  output String basePath;
algorithm
  basePath := matchcontinue (scheme, iname, modelicaPath, printError)
    local
      Boolean isDir;
      list<String> mps,names;
      String gd,mp,bp,str,name,fileName;
    case ("modelica://", name, _, _)
      algorithm
        name::names := System.strtok(name,".");
        Absyn.CLASS(info=SOURCEINFO(fileName=fileName)) := getPathedClassInProgram(Absyn.IDENT(name),program);
        mp := System.dirname(fileName);
        bp := findModelicaPath2(mp,names,"",true);
      then bp;
    case ("modelica://", name, mp, _)
      algorithm
        name::names := System.strtok(name,".");
        failure(getPathedClassInProgram(Absyn.IDENT(name),program));
        gd := Autoconf.groupDelimiter;
        mps := System.strtok(mp, gd);
        (mp,name,isDir) := System.getLoadModelPath(name, {"default"}, mps);
        mp := if isDir then mp + name else mp;
        bp := findModelicaPath2(mp,names,"",true);
      then bp;
    case ("file://", _, _, _) then "";
    case ("modelica://", name, mp, true)
      algorithm
        name::_ := System.strtok(name,".");
        str := "Could not resolve modelica://" + name + " with MODELICAPATH: " + mp;
        Error.addMessage(Error.COMPILER_ERROR,{str});
      then fail();
  end matchcontinue;
end getBasePathFromUri;
public function findModelicaPath "Handle modelica:// URIs"
  input list<String> imps;
  input list<String> names;
  input String version;
  output String basePath;
algorithm
  basePath := matchcontinue imps
    local
      String mp;
      list<String> mps;

    case mp::_
      then findModelicaPath2(mp,names,version,false);
    case _::mps
      then findModelicaPath(mps,names,version);
  end matchcontinue;
end findModelicaPath;
public function findModelicaPath2 "Handle modelica:// URIs"
  input String mp;
  input list<String> inames;
  input String version;
  input Boolean b;
  output String basePath;
algorithm
  basePath := matchcontinue (inames, b)
    local
      list<String> names;
      String name,file;

    case (name::names, _)
      algorithm
        false := stringEq(version,"");
        file := mp + "/" + name + " " + version;
        true := System.directoryExists(file);
        // print("Found file 1: " + file + "\n");
      then findModelicaPath2(file,names,"",true);
    case (name::_, _)
      algorithm
        false := stringEq(version,"");
        file := mp + "/" + name + " " + version + ".mo";
        true := System.regularFileExists(file);
        // print("Found file 2: " + file + "\n");
      then mp;

    case (name::names, _)
      algorithm
        file := mp + "/" + name;
        true := System.directoryExists(file);
        // print("Found file 3: " + file + "\n");
      then findModelicaPath2(file,names,"",true);
    case (name::_, _)
      algorithm
        file := mp + "/" + name + ".mo";
        true := System.regularFileExists(file);
        // print("Found file 4: " + file + "\n");
      then mp;

      // This class is part of the current package.mo, or whatever...
    case (_, true)
      algorithm
        // print("Did not find file 5: " + mp + " - " + name + "\n");
      then mp;
  end matchcontinue;
end findModelicaPath2;
annotation(__OpenModelica_Interface="program_util");
end ProgramUtil;

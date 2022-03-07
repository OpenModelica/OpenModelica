
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

encapsulated package SCodeUtil
" file:        SCodeUtil.mo
  package:     SCodeUtil
  description: Utility functions for the SCodeUtil.intermediate form"

import SCode;

protected
import Absyn;
import AbsynUtil;
import Error;
import List;
import Util;

public

replaceable type Argument subtypeof Any;
constant SourceInfo dummyInfo = SOURCEINFO("", false, 0, 0, 0, 0, 0.0);

function stripSubmod
  "Removes all submodifiers from the Mod."
  input SCode.Mod inMod;
  output SCode.Mod outMod;
algorithm
  outMod := match(inMod)
    local
      SCode.Final fp;
      SCode.Each ep;
      Option<Absyn.Exp> binding;
      SourceInfo info;

    case SCode.MOD(fp, ep, _, binding, info)
      then SCode.MOD(fp, ep, {}, binding, info);
    else inMod;
  end match;
end stripSubmod;

function filterSubMods
  "Removes submods from a modifier based on a filter function."
  input output SCode.Mod mod;
  input FilterFunc filter;

  partial function FilterFunc
    input SCode.SubMod submod;
    output Boolean keep;
  end FilterFunc;
algorithm
  mod := match mod
    case SCode.MOD()
      algorithm
        mod.subModLst := list(m for m guard filter(m) in mod.subModLst);
      then
        match mod
          case SCode.MOD(subModLst = {}, binding = NONE()) then SCode.NOMOD();
          else mod;
        end match;

    else mod;
  end match;
end filterSubMods;

function filterGivenSubModNames
  input SCode.SubMod submod;
  input list<String> namesToKeep;
  output Boolean keep;
algorithm
  keep := listMember(submod.ident, namesToKeep);
end filterGivenSubModNames;

function removeGivenSubModNames
  input SCode.SubMod submod;
  input list<String> namesToRemove;
  output Boolean keep;
algorithm
  keep := not listMember(submod.ident, namesToRemove);
end removeGivenSubModNames;

function getElementNamed
"Return the Element with the name given as first argument from the Class."
  input SCode.Ident inIdent;
  input SCode.Element inClass;
  output SCode.Element outElement;
algorithm
  outElement := match (inIdent,inClass)
    local
      SCode.Element elt;
      String id;
      list<SCode.Element> elts;

    case (id,SCode.CLASS(classDef = SCode.PARTS(elementLst = elts)))
      equation
        elt = getElementNamedFromElts(id, elts);
      then
        elt;

    /* adrpo: handle also the case model extends X then X; */
    case (id,SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = SCode.PARTS(elementLst = elts))))
      equation
        elt = getElementNamedFromElts(id, elts);
      then
        elt;
  end match;
end getElementNamed;

function getElementNamedFromElts
"Helper function to getElementNamed."
  input SCode.Ident inIdent;
  input list<SCode.Element> inElementLst;
  output SCode.Element outElement;
algorithm
  outElement := matchcontinue (inIdent,inElementLst)
    local
      SCode.Element elt,comp,cdef;
      String id2,id1;
      list<SCode.Element> xs;

    case (id2,((comp as SCode.COMPONENT(name = id1)) :: _))
      equation
        true = stringEq(id1, id2);
      then
        comp;

    case (id2,(SCode.COMPONENT(name = id1) :: xs))
      equation
        false = stringEq(id1, id2);
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;

    case (id2,(SCode.CLASS(name = id1) :: xs))
      equation
        false = stringEq(id1, id2);
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;

    case (id2,(SCode.EXTENDS() :: xs))
      equation
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;

    case (id2,((cdef as SCode.CLASS(name = id1)) :: _))
      equation
        true = stringEq(id1, id2);
      then
        cdef;

    // Try next.
    case (id2, _:: xs)
      equation
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;
  end matchcontinue;
end getElementNamedFromElts;

function isElementExtends "
Author BZ, 2009-01
check if an element is of type EXTENDS or not."
  input SCode.Element ele;
  output Boolean isExtend;
algorithm
  isExtend := match(ele)
    case SCode.EXTENDS() then true;
    else false;
  end match;
end isElementExtends;

function isElementExtendsOrClassExtends
  "Check if an element extends another class."
  input SCode.Element ele;
  output Boolean isExtend;
algorithm
  isExtend := match(ele)
    case SCode.EXTENDS() then true;
    else false;
  end match;
end isElementExtendsOrClassExtends;

function isNotElementClassExtends "
check if an element is not of type CLASS_EXTENDS."
  input SCode.Element ele;
  output Boolean isExtend;
algorithm
  isExtend := match(ele)
    case SCode.CLASS(classDef = SCode.CLASS_EXTENDS()) then false;
    else true;
  end match;
end isNotElementClassExtends;

function isParameterOrConst
"Returns true if Variability indicates a parameter or constant."
  input SCode.Variability inVariability;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVariability)
    case SCode.PARAM() then true;
    case SCode.CONST() then true;
    else false;
  end match;
end isParameterOrConst;

function isConstant
"Returns true if Variability is constant, otherwise false"
  input SCode.Variability inVariability;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVariability)
    case SCode.CONST() then true;
    else false;
  end match;
end isConstant;

function countParts
"Counts the number of ClassParts of a Class."
  input SCode.Element inClass;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inClass)
    local
      Integer res;
      list<SCode.Element> elts;

    case SCode.CLASS(classDef = SCode.PARTS(elementLst = elts))
      equation
        res = listLength(elts);
      then
        res;

    /* adrpo: handle also model extends X ... parts ... end X; */
    case SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = SCode.PARTS(elementLst = elts)))
      equation
        res = listLength(elts);
      then
        res;

    else 0;

  end matchcontinue;
end countParts;

function componentNames
  "Return a string list of all component names of a class."
  input SCode.Element inClass;
  output list<String> outStringLst;
algorithm
  outStringLst := match (inClass)
    local list<String> res; list<SCode.Element> elts;

    case (SCode.CLASS(classDef = SCode.PARTS(elementLst = elts)))
      equation
        res = componentNamesFromElts(elts);
      then
        res;

    /* adrpo: handle also the case model extends X end X;*/
    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = SCode.PARTS(elementLst = elts))))
      equation
        res = componentNamesFromElts(elts);
      then
        res;

    else {};

  end match;
end componentNames;

function componentNamesFromElts
  "Helper function to componentNames."
  input list<SCode.Element> inElements;
  output list<String> outComponentNames;
algorithm
  outComponentNames := List.filterMap(inElements, componentName);
end componentNamesFromElts;

function componentName
  input SCode.Element inComponent;
  output String outName;
algorithm
  SCode.COMPONENT(name = outName) := inComponent;
end componentName;

function elementInfo "retrieves the element info"
  input SCode.Element e;
  output SourceInfo info;
algorithm
  info := match(e)
    local
      SourceInfo i;

    case(SCode.COMPONENT(info = i)) then i;
    case(SCode.CLASS(info = i)) then i;
    case(SCode.EXTENDS(info = i)) then i;
    case(SCode.IMPORT(info = i)) then i;
    else AbsynUtil.dummyInfo;

  end match;
end elementInfo;

function elementName ""
  input SCode.Element e;
  output String s;
algorithm
  s := match(e)
    case (SCode.COMPONENT(name = s)) then s;
    case (SCode.CLASS(name = s)) then s;
  end match;
end elementName;

function elementNameInfo
  input SCode.Element inElement;
  output String outName;
  output SourceInfo outInfo;
algorithm
  (outName, outInfo) := match(inElement)
    local
      String name;
      SourceInfo info;

    case SCode.COMPONENT(name = name, info = info) then (name, info);
    case SCode.CLASS(name = name, info = info) then (name, info);

  end match;
end elementNameInfo;

function elementNames "Gets all elements that have an element name from the list"
  input list<SCode.Element> elts;
  output list<String> names;
algorithm
  names := List.fold(elts,elementNamesWork,{});
end elementNames;

protected function elementNamesWork "Gets all elements that have an element name from the list"
  input SCode.Element e;
  input list<String> acc;
  output list<String> out;
algorithm
  out := match(e,acc)
    local
      String s;
    case (SCode.COMPONENT(name = s),_) then s::acc;
    case (SCode.CLASS(name = s),_) then s::acc;
    else acc;
  end match;
end elementNamesWork;

public function renameElement
  input SCode.Element inElement;
  input String inName;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement, inName)
    local
      SCode.Prefixes pf;
      SCode.Encapsulated ep;
      SCode.Partial pp;
      SCode.Restriction res;
      SCode.ClassDef cdef;
      SourceInfo i;
      SCode.Attributes attr;
      Absyn.TypeSpec ty;
      SCode.Mod mod;
      SCode.Comment cmt;
      Option<Absyn.Exp> cond;

    case (SCode.CLASS(_, pf, ep, pp, res, cdef, cmt, i), _)
      then SCode.CLASS(inName, pf, ep, pp, res, cdef, cmt, i);

    case (SCode.COMPONENT(_, pf, attr, ty, mod, cmt, cond, i), _)
      then SCode.COMPONENT(inName, pf, attr, ty, mod, cmt, cond, i);

  end match;
end renameElement;

public function elementNameEqual
  input SCode.Element inElement1;
  input SCode.Element inElement2;
  output Boolean outEqual;
algorithm
  outEqual := match (inElement1, inElement2)
    case (SCode.CLASS(), SCode.CLASS()) then inElement1.name == inElement2.name;
    case (SCode.COMPONENT(), SCode.COMPONENT()) then inElement1.name == inElement2.name;
    case (SCode.DEFINEUNIT(), SCode.DEFINEUNIT()) then inElement1.name == inElement2.name;
    case (SCode.EXTENDS(), SCode.EXTENDS())
      then AbsynUtil.pathEqual(inElement1.baseClassPath, inElement2.baseClassPath);
    case (SCode.IMPORT(), SCode.IMPORT())
      then AbsynUtil.importEqual(inElement1.imp, inElement2.imp);
    else false;
  end match;
end elementNameEqual;

public function enumName ""
  input SCode.Enum e;
  output String s;
algorithm
  s := match(e)
    case(SCode.ENUM(literal = s)) then s;
  end match;
end enumName;

public function isRecord
"Return true if Class is a record."
  input SCode.Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inClass)
    case SCode.CLASS(restriction = SCode.R_RECORD()) then true;
    else false;
  end match;
end isRecord;

public function isTypeVar
"Return true if Class is a type"
  input SCode.Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inClass)
    case SCode.CLASS(restriction = SCode.R_TYPE()) then true;
    else false;
  end match;
end isTypeVar;

public function isPolymorphicTypeVar
  input SCode.Element cls;
  output Boolean res;
algorithm
  res := match cls
    case SCode.CLASS(restriction = SCode.R_TYPE(),
                     classDef = SCode.DERIVED(
                       typeSpec = Absyn.TCOMPLEX(
                         path = Absyn.IDENT(name = "polymorphic")))) then true;

    else false;
  end match;
end isPolymorphicTypeVar;

public function isOperatorRecord
"Return true if Class is a operator record."
  input SCode.Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inClass)
    case SCode.CLASS(restriction = SCode.R_RECORD(true)) then true;
    else false;
  end match;
end isOperatorRecord;

public function isFunction
"Return true if Class is a function."
  input SCode.Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inClass)
    case SCode.CLASS(restriction = SCode.R_FUNCTION()) then true;
    else false;
  end match;
end isFunction;

public function isUniontype
"Return true if Class is a uniontype."
  input SCode.Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inClass)
    case SCode.CLASS(restriction = SCode.R_UNIONTYPE()) then true;
    else false;
  end match;
end isUniontype;

public function isFunctionRestriction
"Return true if restriction is a function."
  input SCode.Restriction inRestriction;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inRestriction)
    case SCode.R_FUNCTION() then true;
    else false;
  end match;
end isFunctionRestriction;

public function isFunctionOrExtFunctionRestriction
"restriction is function or external function.
  Otherwise false is returned."
  input SCode.Restriction r;
  output Boolean res;
algorithm
  res := match(r)
    case (SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION())) then true;
    case (SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION())) then true;
    else false;
  end match;
end isFunctionOrExtFunctionRestriction;

public function isOperator
"restriction is operator or operator function.
  Otherwise false is returned."
  input SCode.Element el;
  output Boolean res;
algorithm
  res := match(el)
    case (SCode.CLASS(restriction=SCode.R_OPERATOR())) then true;
    case (SCode.CLASS(restriction=SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()))) then true;
    else false;
  end match;
end isOperator;

public function className
  "Returns the class name of a Class."
  input SCode.Element inClass;
  output String outName;
algorithm
  SCode.CLASS(name = outName) := inClass;
end className;

public function classSetPartial
"author: PA
  Sets the partial attribute of a Class"
  input SCode.Element inClass;
  input SCode.Partial inPartial;
  output SCode.Element outClass;
algorithm
  outClass := match (inClass,inPartial)
    local
      String id;
      SCode.Encapsulated enc;
      SCode.Partial partialPrefix;
      SCode.Restriction restr;
      SCode.ClassDef def;
      SourceInfo info;
      SCode.Prefixes prefixes;
      SCode.Comment cmt;

    case (SCode.CLASS(name = id,
                prefixes = prefixes,
                encapsulatedPrefix = enc,
                restriction = restr,
                classDef = def,
                cmt = cmt,
                info = info),partialPrefix)
      then SCode.CLASS(id,prefixes,enc,partialPrefix,restr,def,cmt,info);
  end match;
end classSetPartial;

public function elementEqual
"returns true if two elements are equal,
  i.e. for a component have the same type,
  name, and attributes, etc."
   input SCode.Element element1;
   input SCode.Element element2;
   output Boolean equal;
 algorithm
   equal := matchcontinue(element1,element2)
     local
      SCode.Ident name1,name2;
      SCode.Prefixes prefixes1, prefixes2;
      SCode.Encapsulated en1, en2;
      SCode.Partial p1,p2;
      SCode.Restriction restr1, restr2;
      SCode.Attributes attr1,attr2;
      SCode.Mod mod1,mod2;
      Absyn.TypeSpec tp1,tp2;
      Absyn.Import im1,im2;
      Absyn.Path path1,path2;
      Option<String> os1,os2;
      Option<Real> or1,or2;
      Option<Absyn.Exp> cond1, cond2;
      SCode.ClassDef cd1,cd2;

    case (SCode.CLASS(name1,prefixes1,en1,p1,restr1,cd1,_,_),SCode.CLASS(name2,prefixes2,en2,p2,restr2,cd2,_,_))
       equation
         true = stringEq(name1,name2);
         true = prefixesEqual(prefixes1,prefixes2);
         true = valueEq(en1,en2);
         true = valueEq(p1,p2);
         true = restrictionEqual(restr1,restr2);
         true = classDefEqual(cd1,cd2);
       then
         true;

    case (SCode.COMPONENT(name1,prefixes1,attr1,tp1,mod1,_,cond1,_),
          SCode.COMPONENT(name2,prefixes2,attr2,tp2,mod2,_,cond2,_))
       equation
         equality(cond1 = cond2);
         true = stringEq(name1,name2);
         true = prefixesEqual(prefixes1,prefixes2);
         true = attributesEqual(attr1,attr2);
         true = modEqual(mod1,mod2);
         true = AbsynUtil.typeSpecEqual(tp1,tp2);
       then
         true;

     case (SCode.EXTENDS(path1,_,mod1,_,_), SCode.EXTENDS(path2,_,mod2,_,_))
       equation
         true = AbsynUtil.pathEqual(path1,path2);
         true = modEqual(mod1,mod2);
       then
         true;

    case (SCode.IMPORT(imp = im1), SCode.IMPORT(imp = im2))
       equation
         true = AbsynUtil.importEqual(im1,im2);
       then
         true;

     case (SCode.DEFINEUNIT(name1,_,os1,or1), SCode.DEFINEUNIT(name2,_,os2,or2))
       equation
         true = stringEq(name1,name2);
         equality(os1 = os2);
         equality(or1 = or2);
       then
         true;

     // otherwise false
     else false;
   end matchcontinue;
 end elementEqual;

// stefan
public function annotationEqual
"returns true if 2 annotations are equal"
  input SCode.Annotation annotation1;
  input SCode.Annotation annotation2;
  output Boolean equal;
protected
  SCode.Mod mod1, mod2;
algorithm
  SCode.ANNOTATION(modification = mod1) := annotation1;
  SCode.ANNOTATION(modification = mod2) := annotation2;
  equal := modEqual(mod1, mod2);
end annotationEqual;

public function restrictionEqual "Returns true if two Restriction's are equal."
  input SCode.Restriction restr1;
  input SCode.Restriction restr2;
  output Boolean equal;
algorithm
  equal := match(restr1,restr2)
    local
      SCode.FunctionRestriction funcRest1,funcRest2;

    case (SCode.R_CLASS(),SCode.R_CLASS()) then true;
    case (SCode.R_OPTIMIZATION(),SCode.R_OPTIMIZATION()) then true;
    case (SCode.R_MODEL(),SCode.R_MODEL()) then true;
    case (SCode.R_RECORD(true),SCode.R_RECORD(true)) then true; // operator record
    case (SCode.R_RECORD(false),SCode.R_RECORD(false)) then true;
    case (SCode.R_BLOCK(),SCode.R_BLOCK()) then true;
    case (SCode.R_CONNECTOR(true),SCode.R_CONNECTOR(true)) then true; // expandable connectors
    case (SCode.R_CONNECTOR(false),SCode.R_CONNECTOR(false)) then true; // non expandable connectors
    case (SCode.R_OPERATOR(),SCode.R_OPERATOR()) then true; // operator
    case (SCode.R_TYPE(),SCode.R_TYPE()) then true;
    case (SCode.R_PACKAGE(),SCode.R_PACKAGE()) then true;
    case (SCode.R_FUNCTION(funcRest1),SCode.R_FUNCTION(funcRest2)) then funcRestrictionEqual(funcRest1,funcRest2);
    case (SCode.R_ENUMERATION(),SCode.R_ENUMERATION()) then true;
    case (SCode.R_PREDEFINED_INTEGER(),SCode.R_PREDEFINED_INTEGER()) then true;
    case (SCode.R_PREDEFINED_REAL(),SCode.R_PREDEFINED_REAL()) then true;
    case (SCode.R_PREDEFINED_STRING(),SCode.R_PREDEFINED_STRING()) then true;
    case (SCode.R_PREDEFINED_BOOLEAN(),SCode.R_PREDEFINED_BOOLEAN()) then true;
    // BTH
    case (SCode.R_PREDEFINED_CLOCK(),SCode.R_PREDEFINED_CLOCK()) then true;
    case (SCode.R_PREDEFINED_ENUMERATION(),SCode.R_PREDEFINED_ENUMERATION()) then true;
    case (SCode.R_UNIONTYPE(),SCode.R_UNIONTYPE()) then min(t1==t2 threaded for t1 in restr1.typeVars, t2 in restr2.typeVars);
    else false;
   end match;
end restrictionEqual;

public function funcRestrictionEqual
  input SCode.FunctionRestriction funcRestr1;
  input SCode.FunctionRestriction funcRestr2;
  output Boolean equal;
algorithm
  equal := match(funcRestr1,funcRestr2)
    local Boolean b1, b2;
    case (SCode.FR_NORMAL_FUNCTION(b1),SCode.FR_NORMAL_FUNCTION(b2)) then boolEq(b1, b2);
    case (SCode.FR_EXTERNAL_FUNCTION(b1),SCode.FR_EXTERNAL_FUNCTION(b2)) then boolEq(b1, b2);
    case (SCode.FR_OPERATOR_FUNCTION(),SCode.FR_OPERATOR_FUNCTION()) then true;
    case (SCode.FR_RECORD_CONSTRUCTOR(),SCode.FR_RECORD_CONSTRUCTOR()) then true;
    case (SCode.FR_PARALLEL_FUNCTION(),SCode.FR_PARALLEL_FUNCTION()) then true;
    case (SCode.FR_KERNEL_FUNCTION(),SCode.FR_KERNEL_FUNCTION()) then true;
    else false;
  end match;
end funcRestrictionEqual;

function enumEqual
  input SCode.Enum e1;
  input SCode.Enum e2;
  output Boolean isEqual;
algorithm
  isEqual := match(e1, e2)
    local
      String s1, s2;
      Boolean b1;

    case (SCode.ENUM(s1,_), SCode.ENUM(s2,_))
      equation
        b1 = stringEq(s1, s2);
        // ignore comments here.
      then b1;
  end match;
end enumEqual;

protected function classDefEqual
"Returns true if Two ClassDef's are equal"
 input SCode.ClassDef cdef1;
 input SCode.ClassDef cdef2;
 output Boolean equal;
 algorithm
   equal := match(cdef1,cdef2)
     local
       list<SCode.Element> elts1,elts2;
       list<SCode.Equation> eqns1,eqns2;
       list<SCode.Equation> ieqns1,ieqns2;
       list<SCode.AlgorithmSection> algs1,algs2;
       list<SCode.AlgorithmSection> ialgs1,ialgs2;
       list<SCode.ConstraintSection> cons1,cons2;
       SCode.Attributes attr1,attr2;
       Absyn.TypeSpec tySpec1, tySpec2;
       Absyn.Path p1, p2;
       SCode.Mod mod1,mod2;
       list<SCode.Enum> elst1,elst2;
       list<SCode.Ident> ilst1,ilst2;
       list<Absyn.NamedArg> clsttrs1,clsttrs2;

     case(SCode.PARTS(elts1,eqns1,ieqns1,algs1,ialgs1,_,_,_),
          SCode.PARTS(elts2,eqns2,ieqns2,algs2,ialgs2,_,_,_))
       equation
         List.threadMapAllValue(elts1,elts2,elementEqual,true);
         List.threadMapAllValue(eqns1,eqns2,equationEqual,true);
         List.threadMapAllValue(ieqns1,ieqns2,equationEqual,true);
         List.threadMapAllValue(algs1,algs2,algorithmEqual,true);
         List.threadMapAllValue(ialgs1,ialgs2,algorithmEqual,true);
       then true;

     case (SCode.DERIVED(tySpec1,mod1,attr1),
           SCode.DERIVED(tySpec2,mod2,attr2))
       equation
         true = AbsynUtil.typeSpecEqual(tySpec1, tySpec2);
         true = modEqual(mod1,mod2);
         true = attributesEqual(attr1, attr2);
       then
         true;

     case (SCode.ENUMERATION(elst1),SCode.ENUMERATION(elst2))
       equation
         List.threadMapAllValue(elst1,elst2,enumEqual,true);
       then
         true;

     case (SCode.CLASS_EXTENDS(mod1,SCode.PARTS(elts1,eqns1,ieqns1,algs1,ialgs1,_,_,_)),
           SCode.CLASS_EXTENDS(mod2,SCode.PARTS(elts2,eqns2,ieqns2,algs2,ialgs2,_,_,_)))
       equation
         List.threadMapAllValue(elts1,elts2,elementEqual,true);
         List.threadMapAllValue(eqns1,eqns2,equationEqual,true);
         List.threadMapAllValue(ieqns1,ieqns2,equationEqual,true);
         List.threadMapAllValue(algs1,algs2,algorithmEqual,true);
         List.threadMapAllValue(ialgs1,ialgs2,algorithmEqual,true);
         true = modEqual(mod1,mod2);
       then
         true;

     case (SCode.PDER(_,ilst1),SCode.PDER(_,ilst2))
       equation
         List.threadMapAllValue(ilst1,ilst2,stringEq,true);
       then
         true;

    /* adrpo: TODO! FIXME! are these below really needed??!!
    // as far as I can tell we handle all the cases.
    case(cdef1, cdef2)
      equation
        equality(cdef1=cdef2);
      then true;

    case(cdef1, cdef2)
      equation
        failure(equality(cdef1=cdef2));
      then false;*/

    else fail();
  end match;
end classDefEqual;

protected function arraydimOptEqual
"Returns true if two Option<ArrayDim> are equal"
   input Option<Absyn.ArrayDim> adopt1;
   input Option<Absyn.ArrayDim> adopt2;
   output Boolean equal;
 algorithm
  equal := matchcontinue(adopt1,adopt2)
    local
      list<Absyn.Subscript> lst1,lst2;
      list<Boolean> blst;
    case(NONE(),NONE()) then true;
    case(SOME(lst1),SOME(lst2))
      equation
        List.threadMapAllValue(lst1,lst2,subscriptEqual,true);
      then
        true;
    // oth. false
    case(SOME(_),SOME(_)) then false;
  end matchcontinue;
end arraydimOptEqual;

protected function subscriptEqual
  "Returns true if two Absyn.Subscript are equal"
  input Absyn.Subscript sub1;
  input Absyn.Subscript sub2;
  output Boolean equal;
algorithm
  equal := match(sub1,sub2)
    local
      Absyn.Exp e1,e2;

    case(Absyn.NOSUB(),Absyn.NOSUB()) then true;
    case(Absyn.SUBSCRIPT(e1),Absyn.SUBSCRIPT(e2))
      then AbsynUtil.expEqual(e1,e2);

  end match;
end subscriptEqual;

protected function algorithmEqual
"Returns true if two Algorithm's are equal."
  input SCode.AlgorithmSection alg1;
  input SCode.AlgorithmSection alg2;
  output Boolean equal;
algorithm
  equal := matchcontinue(alg1,alg2)
    local
      list<SCode.Statement> a1,a2;

    case(SCode.ALGORITHM(a1),SCode.ALGORITHM(a2))
      equation
        List.threadMapAllValue(a1,a2,algorithmEqual2,true);
      then
        true;

    // false otherwise!
    else false;
  end matchcontinue;
end algorithmEqual;

protected function algorithmEqual2
"Returns true if two Absyn.Algorithm are equal."
  input SCode.Statement ai1;
  input SCode.Statement ai2;
  output Boolean equal;
algorithm
  equal := matchcontinue(ai1,ai2)
    local
      Absyn.Algorithm alg1,alg2;
      SCode.Statement a1,a2;
      Absyn.ComponentRef cr1,cr2;
      Absyn.Exp e1,e2,e11,e12,e21,e22;
      Boolean b1,b2;

    case(SCode.ALG_ASSIGN(assignComponent = Absyn.CREF(cr1), value = e1),
        SCode.ALG_ASSIGN(assignComponent = Absyn.CREF(cr2), value = e2))
      equation
        b1 = AbsynUtil.crefEqual(cr1,cr2);
        b2 = AbsynUtil.expEqual(e1,e2);
        equal = boolAnd(b1,b2);
      then equal;
    case(SCode.ALG_ASSIGN(assignComponent = e11 as Absyn.TUPLE(_), value = e12),SCode.ALG_ASSIGN(assignComponent = e21 as Absyn.TUPLE(_), value = e22))
      equation
        b1 = AbsynUtil.expEqual(e11,e21);
        b2 = AbsynUtil.expEqual(e12,e22);
        equal = boolAnd(b1,b2);
      then equal;
    // base it on equality for now as the ones below are not implemented!
    case(a1, a2)
      equation
        Absyn.ALGORITHMITEM(algorithm_ = alg1) = statementToAlgorithmItem(a1);
        Absyn.ALGORITHMITEM(algorithm_ = alg2) = statementToAlgorithmItem(a2);
        // Don't compare comments and line numbers
        equality(alg1 = alg2);
      then
        true;
    // maybe replace failure/equality with these:
    //case(Absyn.ALG_IF(_,_,_,_),Absyn.ALG_IF(_,_,_,_)) then false; // TODO: SCode.ALG_IF
    //case (Absyn.ALG_FOR(_,_),Absyn.ALG_FOR(_,_)) then false; // TODO: SCode.ALG_FOR
    //case (Absyn.ALG_WHILE(_,_),Absyn.ALG_WHILE(_,_)) then false; // TODO: SCode.ALG_WHILE
    //case(Absyn.ALG_WHEN_A(_,_,_),Absyn.ALG_WHEN_A(_,_,_)) then false; //TODO: SCode.ALG_WHILE
    //case (Absyn.ALG_NORETCALL(_,_),Absyn.ALG_NORETCALL(_,_)) then false; //TODO: SCode.ALG_NORETCALL
    else false;
  end matchcontinue;
end algorithmEqual2;

public function equationEqual
"Returns true if two equations are equal."
  input SCode.Equation eqn1;
  input SCode.Equation eqn2;
  output Boolean equal;
protected
  SCode.EEquation eq1, eq2;
algorithm
  SCode.EQUATION(eEquation = eq1) := eqn1;
  SCode.EQUATION(eEquation = eq2) := eqn2;
  equal := equationEqual2(eq1, eq2);
end equationEqual;

protected function equationEqual2
"Helper function to equationEqual"
  input SCode.EEquation eq1;
  input SCode.EEquation eq2;
  output Boolean equal;
algorithm
  equal := matchcontinue(eq1,eq2)
    local
      list<list<SCode.EEquation>> tb1,tb2;
      Absyn.Exp cond1,cond2;
      list<Absyn.Exp> ifcond1,ifcond2;
      Absyn.Exp e11,e12,e21,e22,exp1,exp2,c1,c2,m1,m2,e1,e2;
      Absyn.ComponentRef cr11,cr12,cr21,cr22,cr1,cr2;
      Absyn.Ident id1,id2;
      list<SCode.EEquation> fb1,fb2,eql1,eql2,elst1,elst2;

    case (SCode.EQ_IF(condition = ifcond1, thenBranch = tb1, elseBranch = fb1),SCode.EQ_IF(condition = ifcond2, thenBranch = tb2, elseBranch = fb2))
      equation
        true = equationEqual22(tb1,tb2);
        List.threadMapAllValue(fb1,fb2,equationEqual2,true);
        List.threadMapAllValue(ifcond1,ifcond2,AbsynUtil.expEqual,true);
      then
        true;

    case(SCode.EQ_EQUALS(expLeft = e11, expRight = e12),SCode.EQ_EQUALS(expLeft = e21, expRight = e22))
      equation
        true = AbsynUtil.expEqual(e11,e21);
        true = AbsynUtil.expEqual(e12,e22);
      then
        true;

    case(SCode.EQ_PDE(expLeft = e11, expRight = e12, domain = cr1),SCode.EQ_PDE(expLeft = e21, expRight = e22, domain = cr2))
      equation
        true = AbsynUtil.expEqual(e11,e21);
        true = AbsynUtil.expEqual(e12,e22);
        true = AbsynUtil.crefEqual(cr1,cr2);
      then
        true;

    case(SCode.EQ_CONNECT(crefLeft = cr11, crefRight = cr12),SCode.EQ_CONNECT(crefLeft = cr21, crefRight = cr22))
      equation
        true = AbsynUtil.crefEqual(cr11,cr21);
        true = AbsynUtil.crefEqual(cr12,cr22);
      then
        true;

    case (SCode.EQ_FOR(index = id1, range = SOME(exp1), eEquationLst = eql1),SCode.EQ_FOR(index = id2, range = SOME(exp2), eEquationLst = eql2))
      equation
        List.threadMapAllValue(eql1,eql2,equationEqual2,true);
        true = AbsynUtil.expEqual(exp1,exp2);
        true = stringEq(id1,id2);
      then
        true;

    case (SCode.EQ_FOR(index = id1, range = NONE(), eEquationLst = eql1),SCode.EQ_FOR(index = id2, range = NONE(), eEquationLst = eql2))
      equation
        List.threadMapAllValue(eql1,eql2,equationEqual2,true);
        true = stringEq(id1,id2);
      then
        true;

    case (SCode.EQ_WHEN(condition = cond1, eEquationLst = elst1),SCode.EQ_WHEN(condition = cond2, eEquationLst = elst2)) // TODO: elsewhen not checked yet.
      equation
        List.threadMapAllValue(elst1,elst2,equationEqual2,true);
        true = AbsynUtil.expEqual(cond1,cond2);
      then
        true;

    case (SCode.EQ_ASSERT(condition = c1, message = m1),SCode.EQ_ASSERT(condition = c2, message = m2))
      equation
        true = AbsynUtil.expEqual(c1,c2);
        true = AbsynUtil.expEqual(m1,m2);
      then
        true;

    case (SCode.EQ_REINIT(), SCode.EQ_REINIT())
      equation
        true = AbsynUtil.expEqual(eq1.cref, eq2.cref);
        true = AbsynUtil.expEqual(eq1.expReinit, eq2.expReinit);
      then
        true;

    case (SCode.EQ_NORETCALL(exp = e1), SCode.EQ_NORETCALL(exp = e2))
      equation
        true = AbsynUtil.expEqual(e1,e2);
      then
        true;

    // otherwise false
    else false;
  end matchcontinue;
end equationEqual2;

protected function equationEqual22
"Author BZ
 Helper function for equationEqual2, does compare list<list<equation>> (else ifs in ifequations.)"
  input list<list<SCode.EEquation>> inTb1;
  input list<list<SCode.EEquation>> inTb2;
  output Boolean bOut;
algorithm
  bOut := matchcontinue(inTb1,inTb2)
    local
      list<SCode.EEquation> tb_1,tb_2;
      list<list<SCode.EEquation>> tb1,tb2;

    case({},{}) then true;
    case(_,{}) then false;
    case({},_) then false;
    case(tb_1::tb1,tb_2::tb2)
      equation
        List.threadMapAllValue(tb_1,tb_2,equationEqual2,true);
        true = equationEqual22(tb1,tb2);
      then
        true;
    case(_::_,_::_) then false;

  end matchcontinue;
end equationEqual22;

public function modEqual
"Return true if two Mod:s are equal"
  input SCode.Mod mod1;
  input SCode.Mod mod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(mod1,mod2)
    local
      SCode.Final f1,f2;
      SCode.Each each1,each2;
      list<SCode.SubMod> submodlst1,submodlst2;
      Absyn.Exp e1,e2;
      SCode.Element elt1,elt2;

    case (SCode.MOD(f1,each1,submodlst1,SOME(e1),_),SCode.MOD(f2,each2,submodlst2,SOME(e2),_))
      equation
        true = valueEq(f1,f2);
        true = eachEqual(each1,each2);
        true = subModsEqual(submodlst1,submodlst2);
        true = AbsynUtil.expEqual(e1,e2);
      then
        true;

    case (SCode.MOD(f1,each1,submodlst1,NONE(),_),SCode.MOD(f2,each2,submodlst2,NONE(),_))
      equation
        true = valueEq(f1,f2);
        true = eachEqual(each1,each2);
        true = subModsEqual(submodlst1,submodlst2);
      then
        true;

    case (SCode.NOMOD(),SCode.NOMOD()) then true;

    case (SCode.REDECL(f1,each1,elt1),SCode.REDECL(f2,each2,elt2))
      equation
        true = valueEq(f1,f2);
        true = eachEqual(each1,each2);
        true = elementEqual(elt1, elt2);
      then
        true;

    else false;

  end matchcontinue;
end modEqual;

protected function subModsEqual
"Return true if two subModifier lists are equal"
  input list<SCode.SubMod>  inSubModLst1;
  input list<SCode.SubMod>  inSubModLst2;
  output Boolean equal;
algorithm
  equal := matchcontinue(inSubModLst1,inSubModLst2)
    local
      SCode.Ident id1,id2;
      SCode.Mod mod1,mod2;
      list<SCode.Subscript> ss1,ss2;
      list<SCode.SubMod>  subModLst1,subModLst2;

    case ({},{}) then true;

    case (SCode.NAMEMOD(id1,mod1)::subModLst1,SCode.NAMEMOD(id2,mod2)::subModLst2)
        equation
          true = stringEq(id1,id2);
          true = modEqual(mod1,mod2);
          true = subModsEqual(subModLst1,subModLst2);
        then
          true;

    else false;
  end matchcontinue;
end subModsEqual;

protected function subscriptsEqual
"Returns true if two subscript lists are equal"
  input list<SCode.Subscript> inSs1;
  input list<SCode.Subscript> inSs2;
  output Boolean equal;
algorithm
  equal := matchcontinue(inSs1,inSs2)
    local
      Absyn.Exp e1,e2;
      list<SCode.Subscript> ss1,ss2;

    case({},{}) then true;

    case(Absyn.NOSUB()::ss1,Absyn.NOSUB()::ss2)
      then subscriptsEqual(ss1,ss2);

    case(Absyn.SUBSCRIPT(e1)::ss1,Absyn.SUBSCRIPT(e2)::ss2)
      equation
        true = AbsynUtil.expEqual(e1,e2);
        true = subscriptsEqual(ss1,ss2);
      then
        true;

    else false;
  end matchcontinue;
end subscriptsEqual;

public function attributesEqual
"Returns true if two Atributes are equal"
   input SCode.Attributes attr1;
   input SCode.Attributes attr2;
   output Boolean equal;
algorithm
  equal:= matchcontinue(attr1,attr2)
    local
      SCode.Parallelism prl1,prl2;
      SCode.Variability var1,var2;
      SCode.ConnectorType ct1, ct2;
      Absyn.ArrayDim ad1,ad2;
      Absyn.Direction dir1,dir2;
      Absyn.IsField if1,if2;

    case(SCode.ATTR(ad1,ct1,prl1,var1,dir1,if1),SCode.ATTR(ad2,ct2,prl2,var2,dir2,if2))
      equation
        true = arrayDimEqual(ad1,ad2);
        true = valueEq(ct1, ct2);
        true = parallelismEqual(prl1,prl2);
        true = variabilityEqual(var1,var2);
        true = AbsynUtil.directionEqual(dir1,dir2);
        true = AbsynUtil.isFieldEqual(if1,if2);
      then
        true;

    else false;
  end matchcontinue;
end attributesEqual;

public function parallelismEqual
"Returns true if two Parallelism prefixes are equal"
  input SCode.Parallelism prl1;
  input SCode.Parallelism prl2;
  output Boolean equal;
algorithm
  equal := match(prl1,prl2)
    case(SCode.PARGLOBAL(),SCode.PARGLOBAL()) then true;
    case(SCode.PARLOCAL(),SCode.PARLOCAL()) then true;
    case(SCode.NON_PARALLEL(),SCode.NON_PARALLEL()) then true;
    else false;
  end match;
end parallelismEqual;

public function variabilityEqual
"Returns true if two Variablity prefixes are equal"
  input SCode.Variability var1;
  input SCode.Variability var2;
  output Boolean equal;
algorithm
  equal := match(var1,var2)
    case(SCode.VAR(),SCode.VAR()) then true;
    case(SCode.DISCRETE(),SCode.DISCRETE()) then true;
    case(SCode.PARAM(),SCode.PARAM()) then true;
    case(SCode.CONST(),SCode.CONST()) then true;
    else false;
  end match;
end variabilityEqual;

protected function arrayDimEqual
"Return true if two arraydims are equal"
 input Absyn.ArrayDim iad1;
 input Absyn.ArrayDim iad2;
 output Boolean equal;
 algorithm
   equal := matchcontinue(iad1,iad2)
     local
       Absyn.Exp e1,e2;
       Absyn.ArrayDim ad1,ad2;

     case({},{}) then true;

     case (Absyn.NOSUB()::ad1, Absyn.NOSUB()::ad2)
       equation
         true = arrayDimEqual(ad1,ad2);
       then
         true;

     case (Absyn.SUBSCRIPT(e1)::ad1,Absyn.SUBSCRIPT(e2)::ad2)
       equation
         true = AbsynUtil.expEqual(e1,e2);
         true =  arrayDimEqual(ad1,ad2);
       then
         true;

     else false;
   end matchcontinue;
end arrayDimEqual;

public function setClassRestriction "Sets the restriction of a SCode Class"
  input SCode.Restriction r;
  input SCode.Element cl;
  output SCode.Element outCl;
algorithm
  outCl := matchcontinue(r, cl)
    local
      SCode.ClassDef parts;
      SCode.Partial p;
      SCode.Encapsulated e;
      SCode.Ident id;
      SourceInfo info;
      SCode.Prefixes prefixes;
      SCode.Restriction oldR;
      SCode.Comment cmt;

    // check if restrictions are equal, so you can return the same thing!
    case(_, SCode.CLASS(restriction = oldR))
      equation
        true = restrictionEqual(r, oldR);
      then cl;

    // not equal, change
    case(_, SCode.CLASS(id,prefixes,e,p,_,parts,cmt,info))
      then SCode.CLASS(id,prefixes,e,p,r,parts,cmt,info);
  end matchcontinue;
end setClassRestriction;

public function setClassName "Sets the name of a SCode Class"
  input SCode.Ident name;
  input SCode.Element cl;
  output SCode.Element outCl;
algorithm
  outCl := matchcontinue(name, cl)
    local
      SCode.ClassDef parts;
      SCode.Partial p;
      SCode.Encapsulated e;
      SourceInfo info;
      SCode.Prefixes prefixes;
      SCode.Restriction r;
      SCode.Ident id;
      SCode.Comment cmt;

    // check if restrictions are equal, so you can return the same thing!
    case(_, SCode.CLASS(name = id))
      equation
        true = stringEqual(name, id);
      then
        cl;

    // not equal, change
    case(_, SCode.CLASS(_,prefixes,e,p,r,parts,cmt,info))
      then SCode.CLASS(name,prefixes,e,p,r,parts,cmt,info);
  end matchcontinue;
end setClassName;

public function makeClassPartial
  input SCode.Element inClass;
  output SCode.Element outClass = inClass;
algorithm
  outClass := match outClass
    case SCode.CLASS(partialPrefix = SCode.NOT_PARTIAL())
      algorithm
        outClass.partialPrefix := SCode.PARTIAL();
      then
        outClass;

    else outClass;
  end match;
end makeClassPartial;

public function setClassPartialPrefix "Sets the partial prefix of a SCode Class"
  input SCode.Partial partialPrefix;
  input SCode.Element cl;
  output SCode.Element outCl;
algorithm
  outCl := matchcontinue(partialPrefix, cl)
    local
      SCode.ClassDef parts;
      SCode.Encapsulated e;
      SCode.Ident id;
      SourceInfo info;
      SCode.Restriction restriction;
      SCode.Prefixes prefixes;
      SCode.Partial oldPartialPrefix;
      SCode.Comment cmt;

    // check if partial prefix are equal, so you can return the same thing!
    case(_,SCode.CLASS(partialPrefix = oldPartialPrefix))
      equation
        true = valueEq(partialPrefix, oldPartialPrefix);
      then
        cl;

    // not the same, change
    case(_,SCode.CLASS(id,prefixes,e,_,restriction,parts,cmt,info))
      then SCode.CLASS(id,prefixes,e,partialPrefix,restriction,parts,cmt,info);
  end matchcontinue;
end setClassPartialPrefix;

public function findIteratorIndexedCrefsInEEquations
  input list<SCode.EEquation> inEqs;
  input String inIterator;
  input list<AbsynUtil.IteratorIndexedCref> inCrefs = {};
  output list<AbsynUtil.IteratorIndexedCref> outCrefs;
algorithm
  outCrefs := List.fold1(inEqs, findIteratorIndexedCrefsInEEquation, inIterator,
    inCrefs);
end findIteratorIndexedCrefsInEEquations;

public function findIteratorIndexedCrefsInEEquation
  input SCode.EEquation inEq;
  input String inIterator;
  input list<AbsynUtil.IteratorIndexedCref> inCrefs = {};
  output list<AbsynUtil.IteratorIndexedCref> outCrefs;
algorithm
  outCrefs := foldEEquationsExps(inEq,
    function AbsynUtil.findIteratorIndexedCrefs(inIterator = inIterator), inCrefs);
end findIteratorIndexedCrefsInEEquation;

public function findIteratorIndexedCrefsInStatements
  input list<SCode.Statement> inStatements;
  input String inIterator;
  input list<AbsynUtil.IteratorIndexedCref> inCrefs = {};
  output list<AbsynUtil.IteratorIndexedCref> outCrefs;
algorithm
  outCrefs := List.fold1(inStatements, findIteratorIndexedCrefsInStatement,
      inIterator, inCrefs);
end findIteratorIndexedCrefsInStatements;

public function findIteratorIndexedCrefsInStatement
  input SCode.Statement inStatement;
  input String inIterator;
  input list<AbsynUtil.IteratorIndexedCref> inCrefs = {};
  output list<AbsynUtil.IteratorIndexedCref> outCrefs;
algorithm
  outCrefs := foldStatementsExps(inStatement,
    function AbsynUtil.findIteratorIndexedCrefs(inIterator = inIterator), inCrefs);
end findIteratorIndexedCrefsInStatement;

protected function filterComponents
  "Filters out the components from the given list of elements, as well as their names."
  input list<SCode.Element> inElements;
  output list<SCode.Element> outComponents;
  output list<String> outComponentNames;
algorithm
  (outComponents, outComponentNames) := List.map_2(inElements, filterComponents2);
end filterComponents;

protected function filterComponents2
  input SCode.Element inElement;
  output SCode.Element outComponent;
  output String outName;
algorithm
  SCode.COMPONENT(name = outName) := inElement;
  outComponent := inElement;
end filterComponents2;

public function getClassComponents
"This function returns the components from a class"
  input SCode.Element cl;
  output list<SCode.Element> compElts;
  output list<String> compNames;
algorithm
  (compElts,compNames) := match (cl)
    local
      list<SCode.Element> elts, comps;
      list<String> names;

    case (SCode.CLASS(classDef = SCode.PARTS(elementLst = elts)))
      equation
        (comps, names) = filterComponents(elts);
      then (comps,names);
    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = SCode.PARTS(elementLst = elts))))
      equation
        (comps, names) = filterComponents(elts);
      then (comps,names);
  end match;
end getClassComponents;

public function getClassElements
"This function returns the components from a class"
  input SCode.Element cl;
  output list<SCode.Element> elts;
algorithm
  elts := match (cl)
    case (SCode.CLASS(classDef = SCode.PARTS(elementLst = elts)))
      then elts;
    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = SCode.PARTS(elementLst = elts))))
      then elts;
    else {};
  end match;
end getClassElements;

public function makeEnumType
  "Creates an EnumType element from an enumeration literal and an optional
  comment."
  input SCode.Enum inEnum;
  input SourceInfo inInfo;
  output SCode.Element outEnumType;
protected
  String literal;
  SCode.Comment comment;
algorithm
  SCode.ENUM(literal = literal, comment = comment) := inEnum;
  checkValidEnumLiteral(literal, inInfo);
  outEnumType := SCode.COMPONENT(literal, SCode.defaultPrefixes, SCode.defaultConstAttr,
    Absyn.TPATH(Absyn.IDENT("EnumType"), NONE()),
    SCode.NOMOD(), comment, NONE(), inInfo);
end makeEnumType;

public function variabilityOr
  "Returns the more constant of two Variabilities
   (considers VAR() < DISCRETE() < PARAM() < CONST()),
   similarly to Types.constOr."
  input SCode.Variability inConst1;
  input SCode.Variability inConst2;
  output SCode.Variability outConst;
algorithm
  outConst := match(inConst1, inConst2)
    case (SCode.CONST(),_) then SCode.CONST();
    case (_,SCode.CONST()) then SCode.CONST();
    case (SCode.PARAM(),_) then SCode.PARAM();
    case (_,SCode.PARAM()) then SCode.PARAM();
    case (SCode.DISCRETE(),_) then SCode.DISCRETE();
    case (_,SCode.DISCRETE()) then SCode.DISCRETE();
    else SCode.VAR();
  end match;
end variabilityOr;

public function statementToAlgorithmItem
"Transforms SCode.Statement back to Absyn.AlgorithmItem. Discards the comment.
Only to be used to unparse statements again."
  input SCode.Statement stmt;
  output Absyn.AlgorithmItem algi;
algorithm
  algi := match stmt
    local
      Absyn.ComponentRef functionCall;
      Absyn.Exp assignComponent;
      Absyn.Exp boolExpr;
      Absyn.Exp value;
      String iterator;
      Option<Absyn.Exp> range;
      Absyn.FunctionArgs functionArgs;
      SourceInfo info;
      list<Absyn.Exp> conditions;
      list<list<SCode.Statement>> stmtsList;
      list<SCode.Statement> body,trueBranch,elseBranch;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> branches;
      Option<SCode.Comment> comment;
      list<Absyn.AlgorithmItem> algs1,algs2;
      list<list<Absyn.AlgorithmItem>> algsLst;
      list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> abranches;

    case SCode.ALG_ASSIGN(assignComponent,value,_,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(assignComponent,value),NONE(),info);

    case SCode.ALG_IF(boolExpr,trueBranch,branches,elseBranch,_,info)
      equation
        algs1 = List.map(trueBranch,statementToAlgorithmItem);

        conditions = List.map(branches, Util.tuple21);
        stmtsList = List.map(branches, Util.tuple22);
        algsLst = List.mapList(stmtsList, statementToAlgorithmItem);
        abranches = List.zip(conditions,algsLst);

        algs2 = List.map(elseBranch,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_IF(boolExpr,algs1,abranches,algs2),NONE(),info);

    case SCode.ALG_FOR(iterator,range,body,_,info)
      equation
        algs1 = List.map(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_FOR({Absyn.ITERATOR(iterator,NONE(),range)},algs1),NONE(),info);

    case SCode.ALG_PARFOR(iterator,range,body,_,info)
      equation
        algs1 = List.map(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_PARFOR({Absyn.ITERATOR(iterator,NONE(),range)},algs1),NONE(),info);

    case SCode.ALG_WHILE(boolExpr,body,_,info)
      equation
        algs1 = List.map(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_WHILE(boolExpr,algs1),NONE(),info);

    case SCode.ALG_WHEN_A(branches,_,info)
      equation
        (boolExpr::conditions) = List.map(branches, Util.tuple21);
        stmtsList = List.map(branches, Util.tuple22);
        (algs1::algsLst) = List.mapList(stmtsList, statementToAlgorithmItem);
        abranches = List.zip(conditions,algsLst);
      then Absyn.ALGORITHMITEM(Absyn.ALG_WHEN_A(boolExpr,algs1,abranches),NONE(),info);

    case SCode.ALG_ASSERT()
      then Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("assert", {}),
        Absyn.FUNCTIONARGS({stmt.condition, stmt.message, stmt.level}, {})), NONE(), stmt.info);

    case SCode.ALG_TERMINATE()
      then Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("terminate", {}),
        Absyn.FUNCTIONARGS({stmt.message}, {})), NONE(), stmt.info);

    case SCode.ALG_REINIT()
      then Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("reinit", {}),
        Absyn.FUNCTIONARGS({stmt.cref, stmt.newValue}, {})), NONE(), stmt.info);

    case SCode.ALG_NORETCALL(Absyn.CALL(function_=functionCall,functionArgs=functionArgs),_,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(functionCall,functionArgs),NONE(),info);

    case SCode.ALG_RETURN(_,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_RETURN(),NONE(),info);

    case SCode.ALG_BREAK(_,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_BREAK(),NONE(),info);

    case SCode.ALG_CONTINUE(_,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_CONTINUE(),NONE(),info);

    case SCode.ALG_FAILURE(body,_,info)
      equation
        algs1 = List.map(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_FAILURE(algs1),NONE(),info);
  end match;
end statementToAlgorithmItem;

public function equationFileInfo
  input SCode.EEquation eq;
  output SourceInfo info;
algorithm
  info := match eq
    case SCode.EQ_IF(info=info) then info;
    case SCode.EQ_EQUALS(info=info) then info;
    case SCode.EQ_PDE(info=info) then info;
    case SCode.EQ_CONNECT(info=info) then info;
    case SCode.EQ_FOR(info=info) then info;
    case SCode.EQ_WHEN(info=info) then info;
    case SCode.EQ_ASSERT(info=info) then info;
    case SCode.EQ_TERMINATE(info=info) then info;
    case SCode.EQ_REINIT(info=info) then info;
    case SCode.EQ_NORETCALL(info=info) then info;
  end match;
end equationFileInfo;

public function emptyModOrEquality
"Checks if a Mod is empty (or only an equality binding is present)"
  input SCode.Mod mod;
  output Boolean b;
algorithm
  b := match(mod)
    case SCode.NOMOD() then true;
    case SCode.MOD(subModLst={}) then true;
    else false;
  end match;
end emptyModOrEquality;

public function isComponentWithDirection
  input SCode.Element elt;
  input Absyn.Direction dir1;
  output Boolean b;
algorithm
  b := match(elt,dir1)
    local
      Absyn.Direction dir2;

    case (SCode.COMPONENT(attributes = SCode.ATTR(direction = dir2)),_)
      then AbsynUtil.directionEqual(dir1,dir2);

    else false;
  end match;
end isComponentWithDirection;

public function isComponent
  input SCode.Element elt;
  output Boolean b;
algorithm
  b := match(elt)
    case SCode.COMPONENT() then true;
    else false;
  end match;
end isComponent;

public function isNotComponent
  input SCode.Element elt;
  output Boolean b;
algorithm
  b := match(elt)
    case SCode.COMPONENT() then false;
    else true;
  end match;
end isNotComponent;

public function isClassOrComponent
  input SCode.Element inElement;
  output Boolean outIsClassOrComponent;
algorithm
  outIsClassOrComponent := match(inElement)
    case SCode.CLASS() then true;
    case SCode.COMPONENT() then true;
  end match;
end isClassOrComponent;

public function isClass
  input SCode.Element inElement;
  output Boolean outIsClass;
algorithm
  outIsClass := match inElement
    case SCode.CLASS() then true;
    else false;
  end match;
end isClass;

public function foldEEquations<ArgT>
  "Calls the given function on the equation and all its subequations, and
   updates the argument for each call."
  input SCode.EEquation inEquation;
  input FoldFunc inFunc;
  input ArgT inArg;
  output ArgT outArg;

  partial function FoldFunc
    input SCode.EEquation inEquation;
    input ArgT inArg;
    output ArgT outArg;
  end FoldFunc;
algorithm
  outArg := inFunc(inEquation, inArg);

  outArg := match inEquation
    local
      list<SCode.EEquation> eql;

    case SCode.EQ_IF()
      algorithm
        outArg := List.foldList1(inEquation.thenBranch, foldEEquations, inFunc, outArg);
      then
        List.fold1(inEquation.elseBranch, foldEEquations, inFunc, outArg);

    case SCode.EQ_FOR()
      then List.fold1(inEquation.eEquationLst, foldEEquations, inFunc, outArg);

    case SCode.EQ_WHEN()
      algorithm
        outArg := List.fold1(inEquation.eEquationLst, foldEEquations, inFunc, outArg);

        for branch in inEquation.elseBranches loop
          (_, eql) := branch;
          outArg := List.fold1(eql, foldEEquations, inFunc, outArg);
        end for;
      then
        outArg;

  end match;
end foldEEquations;

public function foldEEquationsExps<ArgT>
  "Calls the given function on all expressions inside the equation, and updates
   the argument for each call."
  input SCode.EEquation inEquation;
  input FoldFunc inFunc;
  input ArgT inArg;
  output ArgT outArg = inArg;

  partial function FoldFunc
    input Absyn.Exp inExp;
    input ArgT inArg;
    output ArgT outArg;
  end FoldFunc;
algorithm
  outArg := match inEquation
    local
      Absyn.Exp exp;
      list<SCode.EEquation> eql;

    case SCode.EQ_IF()
      algorithm
        outArg := List.fold(inEquation.condition, inFunc, outArg);
        outArg := List.foldList1(inEquation.thenBranch, foldEEquationsExps, inFunc, outArg);
      then
        List.fold1(inEquation.elseBranch, foldEEquationsExps, inFunc, outArg);

    case SCode.EQ_EQUALS()
      algorithm
        outArg := inFunc(inEquation.expLeft, outArg);
        outArg := inFunc(inEquation.expRight, outArg);
      then
        outArg;

    case SCode.EQ_PDE()
      algorithm
        outArg := inFunc(inEquation.expLeft, outArg);
        outArg := inFunc(inEquation.expRight, outArg);
      then
        outArg;

    case SCode.EQ_CONNECT()
      algorithm
        outArg := inFunc(Absyn.CREF(inEquation.crefLeft), outArg);
        outArg := inFunc(Absyn.CREF(inEquation.crefRight), outArg);
      then
        outArg;

    case SCode.EQ_FOR()
      algorithm
        if isSome(inEquation.range) then
          SOME(exp) := inEquation.range;
          outArg := inFunc(exp, outArg);
        end if;
      then
        List.fold1(inEquation.eEquationLst, foldEEquationsExps, inFunc, outArg);

    case SCode.EQ_WHEN()
      algorithm
        outArg := List.fold1(inEquation.eEquationLst, foldEEquationsExps, inFunc, outArg);

        for branch in inEquation.elseBranches loop
          (exp, eql) := branch;
          outArg := inFunc(exp, outArg);
          outArg := List.fold1(eql, foldEEquationsExps, inFunc, outArg);
        end for;
      then
        outArg;

    case SCode.EQ_ASSERT()
      algorithm
        outArg := inFunc(inEquation.condition, outArg);
        outArg := inFunc(inEquation.message, outArg);
        outArg := inFunc(inEquation.level, outArg);
      then
        outArg;

    case SCode.EQ_TERMINATE()
      then inFunc(inEquation.message, outArg);

    case SCode.EQ_REINIT()
      algorithm
        outArg := inFunc(inEquation.cref, outArg);
        outArg := inFunc(inEquation.expReinit, outArg);
      then
        outArg;

    case SCode.EQ_NORETCALL()
      then inFunc(inEquation.exp, outArg);

  end match;
end foldEEquationsExps;

public function foldStatementsExps<ArgT>
  "Calls the given function on all expressions inside the statement, and updates
   the argument for each call."
  input SCode.Statement inStatement;
  input FoldFunc inFunc;
  input ArgT inArg;
  output ArgT outArg = inArg;

  partial function FoldFunc
    input Absyn.Exp inExp;
    input ArgT inArg;
    output ArgT outArg;
  end FoldFunc;
algorithm
  outArg := match inStatement
    local
      Absyn.Exp exp;
      list<SCode.Statement> stmts;

    case SCode.ALG_ASSIGN()
      algorithm
        outArg := inFunc(inStatement.assignComponent, outArg);
        outArg := inFunc(inStatement.value, outArg);
      then
        outArg;

    case SCode.ALG_IF()
      algorithm
        outArg := inFunc(inStatement.boolExpr, outArg);
        outArg := List.fold1(inStatement.trueBranch, foldStatementsExps, inFunc, outArg);

        for branch in inStatement.elseIfBranch loop
          (exp, stmts) := branch;
          outArg := inFunc(exp, outArg);
          outArg := List.fold1(stmts, foldStatementsExps, inFunc, outArg);
        end for;
      then
        outArg;

    case SCode.ALG_FOR()
      algorithm
        if isSome(inStatement.range) then
          SOME(exp) := inStatement.range;
          outArg := inFunc(exp, outArg);
        end if;
      then
        List.fold1(inStatement.forBody, foldStatementsExps, inFunc, outArg);

    case SCode.ALG_PARFOR()
      algorithm
        if isSome(inStatement.range) then
          SOME(exp) := inStatement.range;
          outArg := inFunc(exp, outArg);
        end if;
      then
        List.fold1(inStatement.parforBody, foldStatementsExps, inFunc, outArg);

    case SCode.ALG_WHILE()
      algorithm
        outArg := inFunc(inStatement.boolExpr, outArg);
      then
        List.fold1(inStatement.whileBody, foldStatementsExps, inFunc, outArg);

    case SCode.ALG_WHEN_A()
      algorithm
        for branch in inStatement.branches loop
          (exp, stmts) := branch;
          outArg := inFunc(exp, outArg);
          outArg := List.fold1(stmts, foldStatementsExps, inFunc, outArg);
        end for;
      then
        outArg;

    case SCode.ALG_ASSERT()
      algorithm
        outArg := inFunc(inStatement.condition, outArg);
        outArg := inFunc(inStatement.message, outArg);
        outArg := inFunc(inStatement.level, outArg);
      then
        outArg;

    case SCode.ALG_TERMINATE()
      then inFunc(inStatement.message, outArg);

    case SCode.ALG_REINIT()
      algorithm
        outArg := inFunc(inStatement.cref, outArg);
      then
        inFunc(inStatement.newValue, outArg);

    case SCode.ALG_NORETCALL()
      then inFunc(inStatement.exp, outArg);

    case SCode.ALG_FAILURE()
      then List.fold1(inStatement.stmts, foldStatementsExps, inFunc, outArg);

    case SCode.ALG_TRY()
      algorithm
        outArg := List.fold1(inStatement.body, foldStatementsExps, inFunc, outArg);
      then
        List.fold1(inStatement.elseBody, foldStatementsExps, inFunc, outArg);

    // No else case, to make this function break if a new statement is added to SCode.
    case SCode.ALG_RETURN() then outArg;
    case SCode.ALG_BREAK() then outArg;
    case SCode.ALG_CONTINUE() then outArg;
  end match;
end foldStatementsExps;

public function mapFoldEEquationsList<ArgT>
  "Traverses a list of SCode.EEquations, calling mapFoldEEquations on each SCode.EEquation
  in the list."
  input output list<SCode.EEquation> eql;
  input TraverseFunc traverser;
  input output ArgT arg;

  partial function TraverseFunc
    input output SCode.EEquation eq;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (eql, arg) := List.mapFold(eql, function mapFoldEEquations(traverser = traverser), arg);
end mapFoldEEquationsList;

public function mapFoldEEquations<ArgT>
  "Traverses an SCode.EEquation. For each SCode.EEquation it finds it calls the given
  function with the SCode.EEquation and an extra argument which is passed along."
  input output SCode.EEquation eq;
  input TraverseFunc traverser;
  input output ArgT arg;

  partial function TraverseFunc
    input output SCode.EEquation eq;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (eq, arg) := traverser(eq, arg);

  (eq, arg) := match eq
    local
      Absyn.Exp e1;
      list<Absyn.Exp> expl1;
      list<list<SCode.EEquation>> then_branch;
      list<SCode.EEquation> else_branch, eql;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> else_when;
      SCode.Comment comment;
      SourceInfo info;

    case SCode.EQ_IF(expl1, then_branch, else_branch, comment, info)
      equation
        (then_branch, arg) = List.mapFold(then_branch,
          function mapFoldEEquationsList(traverser = traverser), arg);
        (else_branch, arg) = mapFoldEEquationsList(else_branch, traverser, arg);
      then
        (SCode.EQ_IF(expl1, then_branch, else_branch, comment, info), arg);

    case SCode.EQ_FOR()
      algorithm
        (eql, arg) := mapFoldEEquationsList(eq.eEquationLst, traverser, arg);
        eq.eEquationLst := eql;
      then
        (eq, arg);

    case SCode.EQ_WHEN(e1, eql, else_when, comment, info)
      equation
        (eql, arg) = mapFoldEEquationsList(eql, traverser, arg);
        (else_when, arg) = List.mapFold(else_when,
           function mapFoldElseWhenEEquations(traverser = traverser), arg);
      then
        (SCode.EQ_WHEN(e1, eql, else_when, comment, info), arg);

    else (eq, arg);
  end match;
end mapFoldEEquations;

protected function mapFoldElseWhenEEquations<ArgT>
  "Traverses all SCode.EEquations in an else when branch, calling the given function
  on each SCode.EEquation."
  input output tuple<Absyn.Exp, list<SCode.EEquation>> elseWhen;
  input TraverseFunc traverser;
  input output ArgT arg;

  partial function TraverseFunc
    input output SCode.EEquation eq;
    input output ArgT arg;
  end TraverseFunc;

protected
  Absyn.Exp exp;
  list<SCode.EEquation> eql;
algorithm
  (exp, eql) := elseWhen;
  (eql, arg) := mapFoldEEquationsList(eql, traverser, arg);
  elseWhen := (exp, eql);
end mapFoldElseWhenEEquations;

public function mapFoldEEquationListExps<ArgT>
  "Traverses a list of SCode.EEquations, calling the given function on each Absyn.Exp
  it encounters."
  input list<SCode.EEquation> inEEquations;
  input TraverseFunc traverser;
  input Argument inArg;
  output list<SCode.EEquation> outEEquations;
  output Argument outArg;

  partial function TraverseFunc
    input output Absyn.Exp exp;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (outEEquations, outArg) := List.map1Fold(inEEquations, mapFoldEEquationExps, traverser, inArg);
end mapFoldEEquationListExps;

public function mapFoldEEquationExps<ArgT>
  "Traverses an SCode.EEquation, calling the given function on each Absyn.Exp it
  encounters. This funcion is intended to be used together with
  mapFoldEEquations, and does NOT descend into sub-EEquations."
  input output SCode.EEquation eq;
  input TraverseFunc traverser;
  input output ArgT arg;

  partial function TraverseFunc
    input output Absyn.Exp exp;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (eq, arg) := match eq
    local
      Absyn.Exp e1, e2, e3;
      list<Absyn.Exp> expl1;
      list<list<SCode.EEquation>> then_branch;
      list<SCode.EEquation> else_branch, eql;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> else_when;
      SCode.Comment comment;
      SourceInfo info;
      Absyn.ComponentRef cr1, cr2, domain;
      SCode.Ident index;

    case SCode.EQ_IF(expl1, then_branch, else_branch, comment, info)
      equation
        (expl1, arg) = AbsynUtil.traverseExpList(expl1, traverser, arg);
      then
        (SCode.EQ_IF(expl1, then_branch, else_branch, comment, info), arg);

    case SCode.EQ_EQUALS(e1, e2, comment, info)
      equation
        (e1, arg) = traverser(e1, arg);
        (e2, arg) = traverser(e2, arg);
      then
        (SCode.EQ_EQUALS(e1, e2, comment, info), arg);

    case SCode.EQ_PDE(e1, e2, domain, comment, info)
      equation
        (e1, arg) = traverser(e1, arg);
        (e2, arg) = traverser(e2, arg);
      then
        (SCode.EQ_PDE(e1, e2, domain, comment, info), arg);

    case SCode.EQ_CONNECT(cr1, cr2, comment, info)
      equation
        (cr1, arg) = mapFoldComponentRefExps(cr1, traverser, arg);
        (cr2, arg) = mapFoldComponentRefExps(cr2, traverser, arg);
      then
        (SCode.EQ_CONNECT(cr1, cr2, comment, info), arg);

    case SCode.EQ_FOR(index, SOME(e1), eql, comment, info)
      equation
        (e1, arg) = traverser(e1, arg);
      then
        (SCode.EQ_FOR(index, SOME(e1), eql, comment, info), arg);

    case SCode.EQ_WHEN(e1, eql, else_when, comment, info)
      equation
        (e1, arg) = traverser(e1, arg);
        (else_when, arg) = List.map1Fold(else_when, mapFoldElseWhenExps, traverser, arg);
      then
        (SCode.EQ_WHEN(e1, eql, else_when, comment, info), arg);

    case SCode.EQ_ASSERT(e1, e2, e3, comment, info)
      equation
        (e1, arg) = traverser(e1, arg);
        (e2, arg) = traverser(e2, arg);
        (e3, arg) = traverser(e3, arg);
      then
        (SCode.EQ_ASSERT(e1, e2, e3, comment, info), arg);

    case SCode.EQ_TERMINATE(e1, comment, info)
      equation
        (e1, arg) = traverser(e1, arg);
      then
        (SCode.EQ_TERMINATE(e1, comment, info), arg);

    case SCode.EQ_REINIT(e1, e2, comment, info)
      equation
        (e1, arg) = traverser(e1, arg);
        (e2, arg) = traverser(e2, arg);
      then
        (SCode.EQ_REINIT(e1, e2, comment, info), arg);

    case SCode.EQ_NORETCALL(e1, comment, info)
      equation
        (e1, arg) = traverser(e1, arg);
      then
        (SCode.EQ_NORETCALL(e1, comment, info), arg);

    else (eq, arg);
  end match;
end mapFoldEEquationExps;

protected function mapFoldComponentRefExps<ArgT>
  "Traverses the subscripts of a component reference and calls the given
  function on the subscript expressions."
  input Absyn.ComponentRef inCref;
  input TraverseFunc inFunc;
  input ArgT inArg;
  output Absyn.ComponentRef outCref;
  output ArgT outArg;

  partial function TraverseFunc
    input output Absyn.Exp exp;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (outCref, outArg) := match(inCref, inFunc, inArg)
    local
      Absyn.Ident name;
      list<Absyn.Subscript> subs;
      Absyn.ComponentRef cr;
      ArgT arg;

    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cr), _, _)
      equation
        (cr, arg) = mapFoldComponentRefExps(cr, inFunc, inArg);
      then
        (AbsynUtil.crefMakeFullyQualified(cr), arg);

    case (Absyn.CREF_QUAL(name = name, subscripts = subs, componentRef = cr), _, _)
      equation
        (cr, arg) = mapFoldComponentRefExps(cr, inFunc, inArg);
        (subs, arg) = List.map1Fold(subs, mapFoldSubscriptExps, inFunc, arg);
      then
        (Absyn.CREF_QUAL(name, subs, cr), arg);

    case (Absyn.CREF_IDENT(name = name, subscripts = subs), _, _)
      equation
        (subs, arg) = List.map1Fold(subs, mapFoldSubscriptExps, inFunc, inArg);
      then
        (Absyn.CREF_IDENT(name, subs), arg);

    case (Absyn.WILD(), _, _) then (inCref, inArg);
  end match;
end mapFoldComponentRefExps;

protected function mapFoldSubscriptExps<ArgT>
  "Calls the given function on the subscript expression."
  input Absyn.Subscript inSubscript;
  input TraverseFunc inFunc;
  input ArgT inArg;
  output Absyn.Subscript outSubscript;
  output ArgT outArg;

  partial function TraverseFunc
    input output Absyn.Exp exp;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (outSubscript, outArg) := match(inSubscript, inFunc, inArg)
    local
      Absyn.Exp sub_exp;
      TraverseFunc traverser;
      ArgT arg;

    case (Absyn.SUBSCRIPT(subscript = sub_exp), traverser, arg)
      equation
        (sub_exp, arg) = traverser(sub_exp, arg);
      then
        (Absyn.SUBSCRIPT(sub_exp), arg);

    case (Absyn.NOSUB(), _, _) then (inSubscript, inArg);
  end match;
end mapFoldSubscriptExps;

protected function mapFoldElseWhenExps<ArgT>
  "Traverses the expressions in an else when branch, and calls the given
  function on the expressions."
  input tuple<Absyn.Exp, list<SCode.EEquation>> inElseWhen;
  input TraverseFunc traverser;
  input ArgT inArg;
  output tuple<Absyn.Exp, list<SCode.EEquation>> outElseWhen;
  output ArgT outArg;

  partial function TraverseFunc
    input output Absyn.Exp exp;
    input output ArgT arg;
  end TraverseFunc;
protected
  Absyn.Exp exp;
  list<SCode.EEquation> eql;
algorithm
  (exp, eql) := inElseWhen;
  (exp, outArg) := traverser(exp, inArg);
  outElseWhen := (exp, eql);
end mapFoldElseWhenExps;

protected function mapFoldForIteratorExps<ArgT>
  "Calls the given function on the expression associated with a for iterator."
  input Absyn.ForIterator inIterator;
  input TraverseFunc inFunc;
  input ArgT inArg;
  output Absyn.ForIterator outIterator;
  output ArgT outArg;

  partial function TraverseFunc
    input output Absyn.Exp exp;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (outIterator, outArg) := match(inIterator, inFunc, inArg)
    local
      TraverseFunc traverser;
      ArgT arg;
      Absyn.Ident ident;
      Absyn.Exp guardExp,range;

    case (Absyn.ITERATOR(ident, NONE(), NONE()), _, arg)
      then
        (Absyn.ITERATOR(ident, NONE(), NONE()), arg);

    case (Absyn.ITERATOR(ident, NONE(), SOME(range)), traverser, arg)
      equation
        (range, arg) = traverser(range, arg);
      then
        (Absyn.ITERATOR(ident, NONE(), SOME(range)), arg);

    case (Absyn.ITERATOR(ident, SOME(guardExp), SOME(range)), traverser, arg)
      equation
        (guardExp, arg) = traverser(guardExp, arg);
        (range, arg) = traverser(range, arg);
      then
        (Absyn.ITERATOR(ident, SOME(guardExp), SOME(range)), arg);

    case (Absyn.ITERATOR(ident, SOME(guardExp), NONE()), traverser, arg)
      equation
        (guardExp, arg) = traverser(guardExp, arg);
      then
        (Absyn.ITERATOR(ident, SOME(guardExp), NONE()), arg);

  end match;
end mapFoldForIteratorExps;

public function mapFoldStatementsList<ArgT>
  "Calls traverseStatement on each statement in the given list."
  input output list<SCode.Statement> statements;
  input TraverseFunc traverser;
  input output ArgT arg;

  partial function TraverseFunc
    input output SCode.Statement stmt;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (statements, arg) :=
    List.mapFold(statements, function mapFoldStatements(traverser = traverser), arg);
end mapFoldStatementsList;

public function mapFoldStatements<ArgT>
  "Traverses all statements in the given statement in a top-down approach where
  the given function is applied to each statement found, beginning with the given
  statement."
  input output SCode.Statement stmt;
  input TraverseFunc traverser;
  input output ArgT arg;

  partial function TraverseFunc
    input output SCode.Statement stmt;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (stmt, arg) := traverser(stmt, arg);

  (stmt, arg) := match stmt
    local
      Absyn.Exp e;
      list<SCode.Statement> stmts1, stmts2;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> branches;
      SCode.Comment comment;
      SourceInfo info;
      String iter;
      Option<Absyn.Exp> range;

    case SCode.ALG_IF(e, stmts1, branches, stmts2, comment, info)
      equation
        (stmts1, arg) = mapFoldStatementsList(stmts1, traverser, arg);
        (branches, arg) = List.mapFold(branches,
          function mapFoldBranchStatements(traverser = traverser), arg);
        (stmts2, arg) = mapFoldStatementsList(stmts2, traverser, arg);
      then
        (SCode.ALG_IF(e, stmts1, branches, stmts2, comment, info), arg);

    case SCode.ALG_FOR(iter, range, stmts1, comment, info)
      equation
        (stmts1, arg) = mapFoldStatementsList(stmts1, traverser, arg);
      then
        (SCode.ALG_FOR(iter, range, stmts1, comment, info), arg);

    case SCode.ALG_PARFOR(iter, range, stmts1, comment, info)
      equation
        (stmts1, arg) = mapFoldStatementsList(stmts1, traverser, arg);
      then
        (SCode.ALG_PARFOR(iter, range, stmts1, comment, info), arg);

    case SCode.ALG_WHILE(e, stmts1, comment, info)
      equation
        (stmts1, arg) = mapFoldStatementsList(stmts1, traverser, arg);
      then
        (SCode.ALG_WHILE(e, stmts1, comment, info), arg);

    case SCode.ALG_WHEN_A(branches, comment, info)
      equation
        (branches, arg) = List.mapFold(branches,
           function mapFoldBranchStatements(traverser = traverser), arg);
      then
        (SCode.ALG_WHEN_A(branches, comment, info), arg);

    case SCode.ALG_FAILURE(stmts1, comment, info)
      equation
        (stmts1, arg) = mapFoldStatementsList(stmts1, traverser, arg);
      then
        (SCode.ALG_FAILURE(stmts1, comment, info), arg);

    else (stmt, arg);
  end match;
end mapFoldStatements;

protected function mapFoldBranchStatements<ArgT>
  "Helper function to traverseStatements2. Calls traverseStatement each
  statement in a given branch."
  input output tuple<Absyn.Exp, list<SCode.Statement>> branch;
  input TraverseFunc traverser;
  input output ArgT arg;

  partial function TraverseFunc
    input output SCode.Statement stmt;
    input output ArgT arg;
  end TraverseFunc;
protected
  Absyn.Exp exp;
  list<SCode.Statement> stmts;
algorithm
  (exp, stmts) := branch;
  (stmts, arg) := mapFoldStatementsList(stmts, traverser, arg);
  branch := (exp, stmts);
end mapFoldBranchStatements;

public function mapFoldStatementListExps<ArgT>
  "Traverses a list of statements and calls the given function on each
  expression found."
  input list<SCode.Statement> inStatements;
  input TraverseFunc inFunc;
  input Argument inArg;
  output list<SCode.Statement> outStatements;
  output Argument outArg;

  partial function TraverseFunc
    input output SCode.Statement stmt;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (outStatements, outArg) := List.map1Fold(inStatements, mapFoldStatementExps, inFunc, inArg);
end mapFoldStatementListExps;

public function mapFoldStatementExps<ArgT>
  "Applies the given function to each expression in the given statement. This
  function is intended to be used together with mapFoldStatements, and does NOT
  descend into sub-statements."
  input SCode.Statement inStatement;
  input TraverseFunc inFunc;
  input ArgT inArg;
  output SCode.Statement outStatement;
  output ArgT outArg;

  partial function TraverseFunc
    input output Absyn.Exp exp;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (outStatement, outArg) := match(inStatement, inFunc, inArg)
    local
      TraverseFunc traverser;
      ArgT arg;
      tuple<TraverseFunc, Argument> tup;
      String iterator;
      Absyn.Exp e1, e2, e3;
      list<SCode.Statement> stmts1, stmts2;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> branches;
      SCode.Comment comment;
      SourceInfo info;
      Absyn.ComponentRef cref;

    case (SCode.ALG_ASSIGN(e1, e2, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
        (e2, arg) = traverser(e2, arg);
      then
        (SCode.ALG_ASSIGN(e1, e2, comment, info), arg);

    case (SCode.ALG_IF(e1, stmts1, branches, stmts2, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
        (branches, arg) = List.map1Fold(branches, mapFoldBranchExps, traverser, arg);
      then
        (SCode.ALG_IF(e1, stmts1, branches, stmts2, comment, info), arg);

    case (SCode.ALG_FOR(iterator, SOME(e1), stmts1, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
      then
        (SCode.ALG_FOR(iterator, SOME(e1), stmts1, comment, info), arg);


    case (SCode.ALG_PARFOR(iterator, SOME(e1), stmts1, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
      then
        (SCode.ALG_PARFOR(iterator, SOME(e1), stmts1, comment, info), arg);

    case (SCode.ALG_WHILE(e1, stmts1, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
      then
        (SCode.ALG_WHILE(e1, stmts1, comment, info), arg);

    case (SCode.ALG_WHEN_A(branches, comment, info), traverser, arg)
      equation
        (branches, arg) = List.map1Fold(branches, mapFoldBranchExps, traverser, arg);
      then
        (SCode.ALG_WHEN_A(branches, comment, info), arg);

    case (SCode.ALG_ASSERT(), traverser, arg)
      algorithm
        (e1, arg) := traverser(inStatement.condition, arg);
        (e2, arg) := traverser(inStatement.message, arg);
        (e3, arg) := traverser(inStatement.level, arg);
      then
        (SCode.ALG_ASSERT(e1, e2, e3, inStatement.comment, inStatement.info), arg);

    case (SCode.ALG_TERMINATE(), traverser, arg)
      algorithm
        (e1, arg) := traverser(inStatement.message, arg);
      then
        (SCode.ALG_TERMINATE(e1, inStatement.comment, inStatement.info), arg);

    case (SCode.ALG_REINIT(), traverser, arg)
      algorithm
        (e1, arg) := traverser(inStatement.cref, arg);
        (e2, arg) := traverser(inStatement.newValue, arg);
      then
        (SCode.ALG_REINIT(e1, e2, inStatement.comment, inStatement.info), arg);

    case (SCode.ALG_NORETCALL(e1, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1,  arg);
      then
        (SCode.ALG_NORETCALL(e1, comment, info), arg);

    else (inStatement, inArg);
  end match;
end mapFoldStatementExps;

protected function mapFoldBranchExps<ArgT>
  "Calls the given function on each expression found in an if or when branch."
  input tuple<Absyn.Exp, list<SCode.Statement>> inBranch;
  input TraverseFunc traverser;
  input ArgT inArg;
  output tuple<Absyn.Exp, list<SCode.Statement>> outBranch;
  output ArgT outArg;

  partial function TraverseFunc
    input output Absyn.Exp exp;
    input output ArgT arg;
  end TraverseFunc;
protected
  ArgT arg;
  Absyn.Exp exp;
  list<SCode.Statement> stmts;
algorithm
  (exp, stmts) := inBranch;
  (exp, outArg) := traverser(exp, inArg);
  outBranch := (exp, stmts);
end mapFoldBranchExps;

public function elementIsClass
  input SCode.Element el;
  output Boolean b;
algorithm
  b := match el
    case SCode.CLASS() then true;
    else false;
  end match;
end elementIsClass;

public function elementIsImport
  input SCode.Element inElement;
  output Boolean outIsImport;
algorithm
  outIsImport := match inElement
    case SCode.IMPORT() then true;
    else false;
  end match;
end elementIsImport;

public function elementIsPublicImport
  input SCode.Element el;
  output Boolean b;
algorithm
  b := match el
    case SCode.IMPORT(visibility=SCode.PUBLIC()) then true;
    else false;
  end match;
end elementIsPublicImport;

public function elementIsProtectedImport
  input SCode.Element el;
  output Boolean b;
algorithm
  b := match el
    case SCode.IMPORT(visibility=SCode.PROTECTED()) then true;
    else false;
  end match;
end elementIsProtectedImport;

public function getElementClass
  input SCode.Element el;
  output SCode.Element cl;
algorithm
  cl := match(el)
    case SCode.CLASS() then el;
    else fail();
  end match;
end getElementClass;

public constant list<String> knownExternalCFunctions = {"sin","cos","tan","asin","acos","atan","atan2","sinh","cosh","tanh","exp","log","log10","sqrt"};

public function isBuiltinFunction
  input SCode.Element cl;
  input list<String> inVars;
  input list<String> outVars;
  output String name;
algorithm
  name := match (cl,inVars,outVars)
    local
      String outVar1,outVar2;
      list<String> argsStr;
      list<Absyn.Exp> args;
    case (SCode.CLASS(name=name,restriction=SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION()),classDef=SCode.PARTS(externalDecl=SOME(SCode.EXTERNALDECL(funcName=NONE(),lang=SOME("builtin"))))),_,_)
      then name;
    case (SCode.CLASS(restriction=SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION()),classDef=SCode.PARTS(externalDecl=SOME(SCode.EXTERNALDECL(funcName=SOME(name),lang=SOME("builtin"))))),_,_)
      then name;
    case (SCode.CLASS(name=name,restriction=SCode.R_FUNCTION(SCode.FR_PARALLEL_FUNCTION()),classDef=SCode.PARTS(externalDecl=SOME(SCode.EXTERNALDECL(funcName=NONE(),lang=SOME("builtin"))))),_,_)
      then name;
    case (SCode.CLASS(restriction=SCode.R_FUNCTION(SCode.FR_PARALLEL_FUNCTION()),classDef=SCode.PARTS(externalDecl=SOME(SCode.EXTERNALDECL(funcName=SOME(name),lang=SOME("builtin"))))),_,_)
      then name;
    case (SCode.CLASS(restriction=SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION()), classDef=SCode.PARTS(externalDecl=SOME(SCode.EXTERNALDECL(funcName=SOME(name),lang=SOME("C"),output_=SOME(Absyn.CREF_IDENT(outVar2,{})),args=args)))),_,{outVar1})
      equation
        true = listMember(name,knownExternalCFunctions);
        true = outVar2 == outVar1;
        argsStr = List.mapMap(args, AbsynUtil.expCref, AbsynUtil.crefIdent);
        equality(argsStr = inVars);
      then name;
    case (SCode.CLASS(name=name,
      restriction=SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION()),
      classDef=SCode.PARTS(externalDecl=SOME(SCode.EXTERNALDECL(funcName=NONE(),lang=SOME("C"))))),_,_)
      equation
        true = listMember(name,knownExternalCFunctions);
      then name;
  end match;
end isBuiltinFunction;

public function getEEquationInfo
  "Extracts the SourceInfo from an SCode.EEquation."
  input SCode.EEquation inEEquation;
  output SourceInfo outInfo;
algorithm
  outInfo := match(inEEquation)
    local
      SourceInfo info;

    case SCode.EQ_IF(info = info) then info;
    case SCode.EQ_EQUALS(info = info) then info;
    case SCode.EQ_PDE(info = info) then info;
    case SCode.EQ_CONNECT(info = info) then info;
    case SCode.EQ_FOR(info = info) then info;
    case SCode.EQ_WHEN(info = info) then info;
    case SCode.EQ_ASSERT(info = info) then info;
    case SCode.EQ_TERMINATE(info = info) then info;
    case SCode.EQ_REINIT(info = info) then info;
    case SCode.EQ_NORETCALL(info = info) then info;
  end match;
end getEEquationInfo;

public function getStatementInfo
  "Extracts the SourceInfo from a Statement."
  input SCode.Statement inStatement;
  output SourceInfo outInfo;
algorithm
  outInfo := match inStatement
    case SCode.ALG_ASSIGN() then inStatement.info;
    case SCode.ALG_IF() then inStatement.info;
    case SCode.ALG_FOR() then inStatement.info;
    case SCode.ALG_PARFOR() then inStatement.info;
    case SCode.ALG_WHILE() then inStatement.info;
    case SCode.ALG_WHEN_A() then inStatement.info;
    case SCode.ALG_ASSERT() then inStatement.info;
    case SCode.ALG_TERMINATE() then inStatement.info;
    case SCode.ALG_REINIT() then inStatement.info;
    case SCode.ALG_NORETCALL() then inStatement.info;
    case SCode.ALG_RETURN() then inStatement.info;
    case SCode.ALG_BREAK() then inStatement.info;
    case SCode.ALG_FAILURE() then inStatement.info;
    case SCode.ALG_TRY() then inStatement.info;
    case SCode.ALG_CONTINUE() then inStatement.info;
    else
      equation
        Error.addInternalError("SCodeUtil.getStatementInfo failed", sourceInfo());
      then AbsynUtil.dummyInfo;
  end match;
end getStatementInfo;

public function prependSubModToMod
  input SCode.SubMod subMod;
  input output SCode.Mod mod;
algorithm
  mod := match mod
    case SCode.NOMOD()
      then SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), {subMod}, NONE(), Error.dummyInfo);
    case SCode.MOD()
      algorithm
        mod.subModLst := subMod :: mod.subModLst;
      then mod;
  end match;
end prependSubModToMod;

public function addElementToClass
  "Adds a given element to a class definition. Only implemented for PARTS."
  input SCode.Element inElement;
  input SCode.Element inClassDef;
  output SCode.Element outClassDef;
protected
  SCode.ClassDef cdef;
algorithm
  SCode.CLASS(classDef = cdef) := inClassDef;
  cdef := addElementToCompositeClassDef(inElement, cdef);
  outClassDef := setElementClassDefinition(cdef, inClassDef);
end addElementToClass;

public function addElementToCompositeClassDef
  "Adds a given element to a PARTS class definition."
  input SCode.Element inElement;
  input SCode.ClassDef inClassDef;
  output SCode.ClassDef outClassDef;
protected
  list<SCode.Element> el;
  list<SCode.Equation> nel, iel;
  list<SCode.AlgorithmSection> nal, ial;
  list<SCode.ConstraintSection> nco;
  Option<SCode.ExternalDecl> ed;
  list<Absyn.NamedArg> clsattrs;
algorithm
  SCode.PARTS(el, nel, iel, nal, ial, nco, clsattrs, ed) := inClassDef;
  outClassDef := SCode.PARTS(inElement :: el, nel, iel, nal, ial, nco, clsattrs, ed);
end addElementToCompositeClassDef;

public function setElementClassDefinition
  input SCode.ClassDef inClassDef;
  input SCode.Element inElement;
  output SCode.Element outElement;
protected
  SCode.Ident n;
  SCode.Prefixes pf;
  SCode.Partial pp;
  SCode.Encapsulated ep;
  SCode.Restriction r;
  SourceInfo i;
  SCode.Comment cmt;
algorithm
  SCode.CLASS(n, pf, ep, pp, r, _, cmt, i) := inElement;
  outElement := SCode.CLASS(n, pf, ep, pp, r, inClassDef, cmt, i);
end setElementClassDefinition;

public function visibilityBool
  "returns true for PUBLIC and false for PROTECTED"
  input SCode.Visibility inVisibility;
  output Boolean bVisibility;
algorithm
  bVisibility := match(inVisibility)
    case (SCode.PUBLIC()) then true;
    case (SCode.PROTECTED()) then false;
  end match;
end visibilityBool;

public function boolVisibility
  "returns for PUBLIC true and for PROTECTED false"
  input Boolean inBoolVisibility;
  output SCode.Visibility outVisibility;
algorithm
  outVisibility := match(inBoolVisibility)
    case (true) then SCode.PUBLIC();
    case (false) then SCode.PROTECTED();
  end match;
end boolVisibility;

public function visibilityEqual
  input SCode.Visibility inVisibility1;
  input SCode.Visibility inVisibility2;
  output Boolean outEqual;
algorithm
  outEqual := match(inVisibility1, inVisibility2)
    case (SCode.PUBLIC(), SCode.PUBLIC()) then true;
    case (SCode.PROTECTED(), SCode.PROTECTED()) then true;
    else false;
  end match;
end visibilityEqual;

public function eachBool
  input SCode.Each inEach;
  output Boolean bEach;
algorithm
  bEach := match(inEach)
    case (SCode.EACH()) then true;
    case (SCode.NOT_EACH()) then false;
  end match;
end eachBool;

public function boolEach
  input Boolean inBoolEach;
  output SCode.Each outEach;
algorithm
  outEach := match(inBoolEach)
    case (true) then SCode.EACH();
    case (false) then SCode.NOT_EACH();
  end match;
end boolEach;

public function prefixesRedeclare
  input SCode.Prefixes inPrefixes;
  output SCode.Redeclare outRedeclare;
algorithm
  SCode.PREFIXES(redeclarePrefix = outRedeclare) := inPrefixes;
end prefixesRedeclare;

public function prefixesSetRedeclare
  input SCode.Prefixes inPrefixes;
  input SCode.Redeclare inRedeclare;
  output SCode.Prefixes outPrefixes;
protected
  SCode.Visibility v;
  SCode.Final f;
  Absyn.InnerOuter io;
  SCode.Replaceable rp;
algorithm
  SCode.PREFIXES(v, _, f, io, rp) := inPrefixes;
  outPrefixes := SCode.PREFIXES(v, inRedeclare, f, io, rp);
end prefixesSetRedeclare;

public function prefixesSetReplaceable
  input SCode.Prefixes inPrefixes;
  input SCode.Replaceable inReplaceable;
  output SCode.Prefixes outPrefixes;
protected
  SCode.Visibility v;
  SCode.Final f;
  Absyn.InnerOuter io;
  SCode.Redeclare rd;
algorithm
  SCode.PREFIXES(v, rd, f, io, _) := inPrefixes;
  outPrefixes := SCode.PREFIXES(v, rd, f, io, inReplaceable);
end prefixesSetReplaceable;

public function redeclareBool
  input SCode.Redeclare inRedeclare;
  output Boolean bRedeclare;
algorithm
  bRedeclare := match(inRedeclare)
    case (SCode.REDECLARE()) then true;
    case (SCode.NOT_REDECLARE()) then false;
  end match;
end redeclareBool;

public function boolRedeclare
  input Boolean inBoolRedeclare;
  output SCode.Redeclare outRedeclare;
algorithm
  outRedeclare := match(inBoolRedeclare)
    case (true) then SCode.REDECLARE();
    case (false) then SCode.NOT_REDECLARE();
  end match;
end boolRedeclare;

public function replaceableBool
  input SCode.Replaceable inReplaceable;
  output Boolean bReplaceable;
algorithm
  bReplaceable := match(inReplaceable)
    case (SCode.REPLACEABLE()) then true;
    case (SCode.NOT_REPLACEABLE()) then false;
  end match;
end replaceableBool;

public function replaceableOptConstraint
  input SCode.Replaceable inReplaceable;
  output Option<SCode.ConstrainClass> outOptConstrainClass;
algorithm
  outOptConstrainClass := match(inReplaceable)
    local Option<SCode.ConstrainClass> cc;
    case (SCode.REPLACEABLE(cc)) then cc;
    case (SCode.NOT_REPLACEABLE()) then NONE();
  end match;
end replaceableOptConstraint;

public function boolReplaceable
  input Boolean inBoolReplaceable;
  input Option<SCode.ConstrainClass> inOptConstrainClass;
  output SCode.Replaceable outReplaceable;
algorithm
  outReplaceable := match(inBoolReplaceable, inOptConstrainClass)
    case (true, _) then SCode.REPLACEABLE(inOptConstrainClass);
    case (false, SOME(_))
      equation
        print("Ignoring constraint class because replaceable prefix is not present!\n");
      then SCode.NOT_REPLACEABLE();
    case (false, _) then SCode.NOT_REPLACEABLE();
  end match;
end boolReplaceable;

public function encapsulatedBool
  input SCode.Encapsulated inEncapsulated;
  output Boolean bEncapsulated;
algorithm
  bEncapsulated := match(inEncapsulated)
    case (SCode.ENCAPSULATED()) then true;
    case (SCode.NOT_ENCAPSULATED()) then false;
  end match;
end encapsulatedBool;

public function boolEncapsulated
  input Boolean inBoolEncapsulated;
  output SCode.Encapsulated outEncapsulated;
algorithm
  outEncapsulated := match(inBoolEncapsulated)
    case (true) then SCode.ENCAPSULATED();
    case (false) then SCode.NOT_ENCAPSULATED();
  end match;
end boolEncapsulated;

public function partialBool
  input SCode.Partial inPartial;
  output Boolean bPartial;
algorithm
  bPartial := match(inPartial)
    case (SCode.PARTIAL()) then true;
    case (SCode.NOT_PARTIAL()) then false;
  end match;
end partialBool;

public function boolPartial
  input Boolean inBoolPartial;
  output SCode.Partial outPartial;
algorithm
  outPartial := match(inBoolPartial)
    case (true) then SCode.PARTIAL();
    case (false) then SCode.NOT_PARTIAL();
  end match;
end boolPartial;

public function prefixesFinal
  input SCode.Prefixes inPrefixes;
  output SCode.Final outFinal;
algorithm
  SCode.PREFIXES(finalPrefix = outFinal) := inPrefixes;
end prefixesFinal;

public function finalBool
  input SCode.Final inFinal;
  output Boolean bFinal;
algorithm
  bFinal := match(inFinal)
    case (SCode.FINAL()) then true;
    case (SCode.NOT_FINAL()) then false;
  end match;
end finalBool;

public function finalEqual
  input SCode.Final inFinal1;
  input SCode.Final inFinal2;
  output Boolean bFinal;
algorithm
  bFinal := match(inFinal1,inFinal2)
    case (SCode.FINAL(),SCode.FINAL()) then true;
    case (SCode.NOT_FINAL(),SCode.NOT_FINAL()) then true;
    else false;
  end match;
end finalEqual;

public function boolFinal
  input Boolean inBoolFinal;
  output SCode.Final outFinal;
algorithm
  outFinal := if inBoolFinal then SCode.FINAL() else SCode.NOT_FINAL();
end boolFinal;

public function connectorTypeEqual
  input SCode.ConnectorType inConnectorType1;
  input SCode.ConnectorType inConnectorType2;
  output Boolean outEqual;
algorithm
  outEqual := match(inConnectorType1, inConnectorType2)
    case (SCode.POTENTIAL(), SCode.POTENTIAL()) then true;
    case (SCode.FLOW(), SCode.FLOW()) then true;
    case (SCode.STREAM(), SCode.STREAM()) then true;
  end match;
end connectorTypeEqual;

public function potentialBool
  input SCode.ConnectorType inConnectorType;
  output Boolean outPotential;
algorithm
  outPotential := match(inConnectorType)
    case SCode.POTENTIAL() then true;
    else false;
  end match;
end potentialBool;

public function flowBool
  input SCode.ConnectorType inConnectorType;
  output Boolean outFlow;
algorithm
  outFlow := match(inConnectorType)
    case SCode.FLOW() then true;
    else false;
  end match;
end flowBool;

public function boolFlow
  input Boolean inBoolFlow;
  output SCode.ConnectorType outFlow;
algorithm
  outFlow := match(inBoolFlow)
    case true then SCode.FLOW();
    else SCode.POTENTIAL();
  end match;
end boolFlow;

public function streamBool
  input SCode.ConnectorType inStream;
  output Boolean bStream;
algorithm
  bStream := match(inStream)
    case SCode.STREAM() then true;
    else false;
  end match;
end streamBool;

public function boolStream
  input Boolean inBoolStream;
  output SCode.ConnectorType outStream;
algorithm
  outStream := match(inBoolStream)
    case true then SCode.STREAM();
    else SCode.POTENTIAL();
  end match;
end boolStream;

public function mergeAttributesFromClass
  input SCode.Attributes inAttributes;
  input SCode.Element inClass;
  output SCode.Attributes outAttributes;
algorithm
  outAttributes := match(inAttributes, inClass)
    local
      SCode.Attributes cls_attr, attr;

    case (_, SCode.CLASS(classDef = SCode.DERIVED(attributes = cls_attr)))
      equation
        SOME(attr) = mergeAttributes(inAttributes, SOME(cls_attr));
      then
        attr;

    else inAttributes;
  end match;
end mergeAttributesFromClass;

public function mergeAttributes
"@author: adrpo
 Function that is used with Derived classes,
 merge the derived Attributes with the optional Attributes returned from ~instClass~."
  input SCode.Attributes ele;
  input Option<SCode.Attributes> oEle;
  output Option<SCode.Attributes> outoEle;
algorithm
  outoEle := match(ele, oEle)
    local
      SCode.Parallelism p1,p2,p;
      SCode.Variability v1,v2,v;
      Absyn.Direction d1,d2,d;
      Absyn.IsField isf1, isf2, isf;
      Absyn.ArrayDim ad1,ad2,ad;
      SCode.ConnectorType ct1, ct2, ct;

    case (_,NONE()) then SOME(ele);
    case(SCode.ATTR(ad1,ct1,p1,v1,d1,isf1), SOME(SCode.ATTR(_,ct2,p2,v2,d2,isf2)))
      equation
        ct = propagateConnectorType(ct1, ct2);
        p = propagateParallelism(p1,p2);
        v = propagateVariability(v1,v2);
        d = propagateDirection(d1,d2);
        isf = propagateIsField(isf1,isf2);
        ad = ad1; // TODO! CHECK if ad1 == ad2!
      then
        SOME(SCode.ATTR(ad,ct,p,v,d,isf));
  end match;
end mergeAttributes;

public function prefixesVisibility
  input SCode.Prefixes inPrefixes;
  output SCode.Visibility outVisibility;
algorithm
  SCode.PREFIXES(visibility = outVisibility) := inPrefixes;
end prefixesVisibility;

public function prefixesSetVisibility
  input SCode.Prefixes inPrefixes;
  input SCode.Visibility inVisibility;
  output SCode.Prefixes outPrefixes;
protected
  SCode.Redeclare rd;
  SCode.Final f;
  Absyn.InnerOuter io;
  SCode.Replaceable rp;
algorithm
  SCode.PREFIXES(_, rd, f, io, rp) := inPrefixes;
  outPrefixes := SCode.PREFIXES(inVisibility, rd, f, io, rp);
end prefixesSetVisibility;

public function eachEqual "Returns true if two each attributes are equal"
  input SCode.Each each1;
  input SCode.Each each2;
  output Boolean equal;
algorithm
  equal := match(each1,each2)
    case (SCode.NOT_EACH(), SCode.NOT_EACH()) then true;
    case (SCode.EACH(), SCode.EACH()) then true;
    else false;
  end match;
end eachEqual;

public function replaceableEqual "Returns true if two replaceable attributes are equal"
  input SCode.Replaceable r1;
  input SCode.Replaceable r2;
  output Boolean equal;
algorithm
  equal := matchcontinue(r1,r2)
    local
      Absyn.Path p1, p2;
      SCode.Mod m1, m2;

    case(SCode.NOT_REPLACEABLE(),SCode.NOT_REPLACEABLE()) then true;

    case(SCode.REPLACEABLE(SOME(SCode.CONSTRAINCLASS(constrainingClass = p1, modifier = m1))),
         SCode.REPLACEABLE(SOME(SCode.CONSTRAINCLASS(constrainingClass = p2, modifier = m2))))
      equation
        true = AbsynUtil.pathEqual(p1, p2);
        true = modEqual(m1, m2);
      then
        true;

    case(SCode.REPLACEABLE(NONE()),SCode.REPLACEABLE(NONE())) then true;

    else false;

  end matchcontinue;
end replaceableEqual;

public function prefixesEqual "Returns true if two prefixes are equal"
  input SCode.Prefixes prefixes1;
  input SCode.Prefixes prefixes2;
  output Boolean equal;
algorithm
  equal := matchcontinue(prefixes1,prefixes2)
    local
      SCode.Visibility v1,v2;
      SCode.Redeclare rd1,rd2;
      SCode.Final f1,f2;
      Absyn.InnerOuter io1,io2;
      SCode.Replaceable rpl1,rpl2;
    case(SCode.PREFIXES(v1,rd1,f1,io1,rpl1),SCode.PREFIXES(v2,rd2,f2,io2,rpl2))
      guard valueEq(v1, v2) and valueEq(rd1, rd2)
                            and valueEq(f1, f2)
                            and AbsynUtil.innerOuterEqual(io1, io2)
                            and replaceableEqual(rpl1, rpl2)
      then
        true;
    else false;
  end matchcontinue;
end prefixesEqual;

public function prefixesReplaceable "Returns the replaceable part"
  input SCode.Prefixes prefixes;
  output SCode.Replaceable repl;
algorithm
  SCode.PREFIXES(replaceablePrefix = repl) := prefixes;
end prefixesReplaceable;

public function elementPrefixes
  input SCode.Element inElement;
  output SCode.Prefixes outPrefixes;
algorithm
  outPrefixes := match(inElement)
    local
      SCode.Prefixes pf;

    case SCode.CLASS(prefixes = pf) then pf;
    case SCode.COMPONENT(prefixes = pf) then pf;
  end match;
end elementPrefixes;

public function isElementReplaceable
  input SCode.Element inElement;
  output Boolean isReplaceable;
protected
  SCode.Prefixes pf;
algorithm
  pf := elementPrefixes(inElement);
  isReplaceable := replaceableBool(prefixesReplaceable(pf));
end isElementReplaceable;

public function isElementRedeclare
  input SCode.Element inElement;
  output Boolean isRedeclare;
protected
  SCode.Prefixes pf;
algorithm
  pf := elementPrefixes(inElement);
  isRedeclare := redeclareBool(prefixesRedeclare(pf));
end isElementRedeclare;

public function prefixesInnerOuter
  input SCode.Prefixes inPrefixes;
  output Absyn.InnerOuter outInnerOuter;
algorithm
  SCode.PREFIXES(innerOuter = outInnerOuter) := inPrefixes;
end prefixesInnerOuter;

public function prefixesSetInnerOuter
  input output SCode.Prefixes prefixes;
  input Absyn.InnerOuter innerOuter;
algorithm
  prefixes.innerOuter := innerOuter;
end prefixesSetInnerOuter;

public function removeAttributeDimensions
  input SCode.Attributes inAttributes;
  output SCode.Attributes outAttributes;
protected
  SCode.ConnectorType ct;
  SCode.Variability v;
  SCode.Parallelism p;
  Absyn.Direction d;
  Absyn.IsField isf;
algorithm
  SCode.ATTR(_, ct, p, v, d, isf) := inAttributes;
  outAttributes := SCode.ATTR({}, ct, p, v, d, isf);
end removeAttributeDimensions;

public function setAttributesDirection
  input output SCode.Attributes attributes;
  input Absyn.Direction direction;
algorithm
  attributes.direction := direction;
end setAttributesDirection;

public function attrVariability
"Return the variability attribute from Attributes"
  input SCode.Attributes attr;
  output SCode.Variability var;
algorithm
  var := match (attr)
    local SCode.Variability v;
    case  SCode.ATTR(variability = v) then v;
  end match;
end attrVariability;

public function setAttributesVariability
  input output SCode.Attributes attributes;
  input SCode.Variability variability;
algorithm
  attributes.variability := variability;
end setAttributesVariability;

public function isDerivedClassDef
  input SCode.ClassDef inClassDef;
  output Boolean isDerived;
algorithm
  isDerived := match(inClassDef)
    case SCode.DERIVED() then true;
    else false;
  end match;
end isDerivedClassDef;

public function isConnector
  input SCode.Restriction inRestriction;
  output Boolean isConnector;
algorithm
  isConnector := match(inRestriction)
    case (SCode.R_CONNECTOR()) then true;
    else false;
  end match;
end isConnector;

public function removeBuiltinsFromTopScope
  input SCode.Program inProgram;
  output SCode.Program outProgram;
algorithm
  outProgram := List.filterOnTrue(inProgram, isNotBuiltinClass);
end removeBuiltinsFromTopScope;

protected function isNotBuiltinClass
  input SCode.Element inClass;
  output Boolean b;
algorithm
  b := match(inClass)
    case SCode.CLASS(classDef = SCode.PARTS(externalDecl =
      SOME(SCode.EXTERNALDECL(lang = SOME("builtin"))))) then false;
    else true;
  end match;
end isNotBuiltinClass;

public function getElementNamedAnnotation
  "Returns the annotation with the given name in the element, or fails if no
   such annotation could be found."
  input SCode.Element element;
  input String name;
  output Absyn.Exp exp;
protected
  SCode.Annotation ann;
algorithm
  ann := match element
    case SCode.EXTENDS(ann = SOME(ann)) then ann;
    case SCode.CLASS(cmt = SCode.COMMENT(annotation_ = SOME(ann))) then ann;
    case SCode.COMPONENT(comment = SCode.COMMENT(annotation_ = SOME(ann))) then ann;
  end match;

  exp := getNamedAnnotation(ann, name);
end getElementNamedAnnotation;

public function getNamedAnnotation
  "Checks if the given annotation contains an entry with the given name with the
   value true."
  input SCode.Annotation inAnnotation;
  input String inName;
  output Absyn.Exp exp;
  output SourceInfo info;
protected
  list<SCode.SubMod> submods;
algorithm
  SCode.ANNOTATION(modification = SCode.MOD(subModLst = submods)) := inAnnotation;
  SCode.NAMEMOD(mod = SCode.MOD(info = info, binding = SOME(exp))) := List.find1(submods, hasNamedAnnotation, inName);
end getNamedAnnotation;

protected function hasNamedAnnotation
  "Checks if a submod has the same name as the given name, and if its binding
   in that case is true."
  input SCode.SubMod inSubMod;
  input String inName;
  output Boolean outIsMatch;
algorithm
  outIsMatch := match(inSubMod, inName)
    local
      String id;

    case (SCode.NAMEMOD(ident = id, mod = SCode.MOD(binding = SOME(_))), _)
      then stringEq(id, inName);

    else false;
  end match;
end hasNamedAnnotation;

public function lookupNamedAnnotation
  "Returns the modifier with the given name if it can be found in the
   annotation, otherwise an empty modifier."
  input SCode.Annotation ann;
  input String name;
  output SCode.Mod mod;
protected
  list<SCode.SubMod> submods;
  String id;
algorithm
  mod := match ann
    case SCode.ANNOTATION(modification = SCode.MOD(subModLst = submods))
      algorithm
        for sm in submods loop
          SCode.NAMEMOD(id, mod) := sm;

          if id == name then
            return;
          end if;
        end for;
      then
        SCode.NOMOD();

    else SCode.NOMOD();
  end match;
end lookupNamedAnnotation;

public function lookupNamedAnnotations
  "Returns a list of modifiers with the given name found in the annotation."
  input SCode.Annotation ann;
  input String name;
  output list<SCode.Mod> mods = {};
protected
  list<SCode.SubMod> submods;
  String id;
  SCode.Mod mod;
algorithm
  mods := match ann
    case SCode.ANNOTATION(modification = SCode.MOD(subModLst = submods))
      algorithm
        for sm in submods loop
          SCode.NAMEMOD(id, mod) := sm;

          if id == name then
            mods := mod :: mods;
          end if;
        end for;
      then
        mods;

    else {};
  end match;
end lookupNamedAnnotations;

public function hasBooleanNamedAnnotationInClass
  input SCode.Element inClass;
  input String namedAnnotation;
  output Boolean hasAnn;
algorithm
  hasAnn := match(inClass,namedAnnotation)
    local
      SCode.Annotation ann;
    case(SCode.CLASS(cmt=SCode.COMMENT(annotation_ = SOME(ann))), _)
      then hasBooleanNamedAnnotation(ann, namedAnnotation);
    else false;
  end match;
end hasBooleanNamedAnnotationInClass;

public function hasBooleanNamedAnnotationInComponent
  input SCode.Element inComponent;
  input String namedAnnotation;
  output Boolean hasAnn;
algorithm
  hasAnn := match(inComponent,namedAnnotation)
    local
      SCode.Annotation ann;
    case (SCode.COMPONENT(comment = SCode.COMMENT(annotation_ = SOME(ann))), _)
      then hasBooleanNamedAnnotation(ann, namedAnnotation);
    else false;
  end match;
end hasBooleanNamedAnnotationInComponent;

public function optCommentHasBooleanNamedAnnotation
"check if the named annotation is present and has value true"
  input Option<SCode.Comment> comm;
  input String annotationName;
  output Boolean outB;
algorithm
  outB := match (comm,annotationName)
    local
      SCode.Annotation ann;
    case (SOME(SCode.COMMENT(annotation_=SOME(ann))),_)
      then hasBooleanNamedAnnotation(ann,annotationName);
    else false;
  end match;
end optCommentHasBooleanNamedAnnotation;

public function commentHasBooleanNamedAnnotation
"check if the named annotation is present and has value true"
  input SCode.Comment comm;
  input String annotationName;
  output Boolean outB;
algorithm
  outB := match (comm,annotationName)
    local
      SCode.Annotation ann;
    case (SCode.COMMENT(annotation_=SOME(ann)),_)
      then hasBooleanNamedAnnotation(ann,annotationName);
    else false;
  end match;
end commentHasBooleanNamedAnnotation;

public function hasBooleanNamedAnnotation
  "Checks if the given annotation contains an entry with the given name with the
   value true."
  input SCode.Annotation inAnnotation;
  input String inName;
  output Boolean outHasEntry;
protected
  list<SCode.SubMod> submods;
algorithm
  SCode.ANNOTATION(modification = SCode.MOD(subModLst = submods)) := inAnnotation;
  outHasEntry := List.exist1(submods, hasBooleanNamedAnnotation2, inName);
end hasBooleanNamedAnnotation;

protected function hasBooleanNamedAnnotation2
  "Checks if a submod has the same name as the given name, and if its binding
   in that case is true."
  input SCode.SubMod inSubMod;
  input String inName;
  output Boolean outIsMatch;
algorithm
  outIsMatch := match inSubMod
    local
      String id;

    case SCode.NAMEMOD(ident = id, mod = SCode.MOD(binding = SOME(Absyn.BOOL(value = true))))
      then stringEq(id, inName);

    else false;
  end match;
end hasBooleanNamedAnnotation2;

public function getEvaluateAnnotation
"@author: adrpo
 returns true if annotation(Evaluate = true) is present,
 otherwise false"
  input Option<SCode.Comment> inCommentOpt;
  output Boolean evalIsTrue;
algorithm
  evalIsTrue := match (inCommentOpt)
    local
      SCode.Annotation ann;
    case (SOME(SCode.COMMENT(annotation_ = SOME(ann))))
      then hasBooleanNamedAnnotation(ann, "Evaluate");
    else false;
  end match;
end getEvaluateAnnotation;

public function getInlineTypeAnnotationFromCmt
  input SCode.Comment inComment;
  output Option<SCode.Annotation> outAnnotation;
algorithm
  outAnnotation := match(inComment)
    local
      SCode.Annotation ann;

    case SCode.COMMENT(annotation_ = SOME(ann)) then getInlineTypeAnnotation(ann);
    else NONE();
  end match;
end getInlineTypeAnnotationFromCmt;

protected function getInlineTypeAnnotation
  input SCode.Annotation inAnnotation;
  output Option<SCode.Annotation> outAnnotation;
algorithm
  outAnnotation := matchcontinue(inAnnotation)
    local
      list<SCode.SubMod> submods;
      SCode.SubMod inline_mod;
      SCode.Final fp;
      SCode.Each ep;
      SourceInfo info;

    case SCode.ANNOTATION(SCode.MOD(fp, ep, submods, _, info))
      equation
        inline_mod = List.find(submods, isInlineTypeSubMod);
      then
        SOME(SCode.ANNOTATION(SCode.MOD(fp, ep, {inline_mod}, NONE(), info)));

    else NONE();
  end matchcontinue;
end getInlineTypeAnnotation;

protected function isInlineTypeSubMod
  input SCode.SubMod inSubMod;
  output Boolean outIsInlineType;
algorithm
  outIsInlineType := match(inSubMod)
    case SCode.NAMEMOD(ident = "Inline") then true;
    case SCode.NAMEMOD(ident = "LateInline") then true;
    case SCode.NAMEMOD(ident = "InlineAfterIndexReduction") then true;
  end match;
end isInlineTypeSubMod;

public function appendAnnotationToComment
  input SCode.Annotation inAnnotation;
  input SCode.Comment inComment;
  output SCode.Comment outComment;
algorithm
  outComment := match(inAnnotation, inComment)
    local
      Option<String> cmt;
      SCode.Final fp;
      SCode.Each ep;
      list<SCode.SubMod> mods1, mods2;
      Option<Absyn.Exp> b;
      SourceInfo info;

    case (_, SCode.COMMENT(NONE(), cmt))
      then SCode.COMMENT(SOME(inAnnotation), cmt);

    case (SCode.ANNOTATION(modification = SCode.MOD(subModLst = mods1)),
          SCode.COMMENT(SOME(SCode.ANNOTATION(SCode.MOD(fp, ep, mods2, b, info))), cmt))
      equation
        mods2 = listAppend(mods1, mods2);
      then
        SCode.COMMENT(SOME(SCode.ANNOTATION(SCode.MOD(fp, ep, mods2, b, info))), cmt);

  end match;
end appendAnnotationToComment;

public function getModifierInfo
  input SCode.Mod inMod;
  output SourceInfo outInfo;
algorithm
  outInfo := match(inMod)
    local
      SourceInfo info;
      SCode.Element el;

    case SCode.MOD(info = info) then info;
    case SCode.REDECL(element = el) then elementInfo(el);
    else AbsynUtil.dummyInfo;
  end match;
end getModifierInfo;

public function getModifierBinding
  input SCode.Mod inMod;
  output Option<Absyn.Exp> outBinding;
algorithm
  outBinding := match(inMod)
    local
      Absyn.Exp binding;

    case SCode.MOD(binding = SOME(binding)) then SOME(binding);
    else NONE();
  end match;
end getModifierBinding;

function getComponentCondition
  input SCode.Element element;
  output Option<Absyn.Exp> condition;
algorithm
  condition := match element
    case SCode.COMPONENT() then element.condition;
    else NONE();
  end match;
end getComponentCondition;

public function removeComponentCondition
  input SCode.Element inElement;
  output SCode.Element outElement;
protected
  SCode.Ident name;
  SCode.Prefixes pf;
  SCode.Attributes attr;
  Absyn.TypeSpec ty;
  SCode.Mod mod;
  SCode.Comment cmt;
  SourceInfo info;
algorithm
  SCode.COMPONENT(name, pf, attr, ty, mod, cmt, _, info) := inElement;
  outElement := SCode.COMPONENT(name, pf, attr, ty, mod, cmt, NONE(), info);
end removeComponentCondition;

public function isInnerComponent
  "Returns true if the given element is an element with the inner prefix,
   otherwise false."
  input SCode.Element inElement;
  output Boolean outIsInner;
algorithm
  outIsInner := match(inElement)
    local
      Absyn.InnerOuter io;

    case SCode.COMPONENT(prefixes = SCode.PREFIXES(innerOuter = io))
      then AbsynUtil.isInner(io);

    else false;

  end match;
end isInnerComponent;

public function makeElementProtected
  input SCode.Element inElement;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement)
    local
      SCode.Ident name;
      SCode.Attributes attr;
      Absyn.TypeSpec ty;
      SCode.Mod mod;
      SCode.Comment cmt;
      Option<Absyn.Exp> cnd;
      SourceInfo info;
      SCode.Redeclare rdp;
      SCode.Final fp;
      Absyn.InnerOuter io;
      SCode.Replaceable rpp;
      SCode.Path bc;
      Option<SCode.Annotation> ann;

    case SCode.COMPONENT(prefixes = SCode.PREFIXES(visibility = SCode.PROTECTED()))
      then inElement;

    case SCode.COMPONENT(name, SCode.PREFIXES(_, rdp, fp, io, rpp), attr, ty, mod, cmt, cnd, info)
      then SCode.COMPONENT(name, SCode.PREFIXES(SCode.PROTECTED(), rdp, fp, io, rpp),
        attr, ty, mod, cmt, cnd, info);

    case SCode.EXTENDS(visibility = SCode.PROTECTED())
      then inElement;

    case SCode.EXTENDS(bc, _, mod, ann, info)
      then SCode.EXTENDS(bc, SCode.PROTECTED(), mod, ann, info);

    else inElement;

  end match;
end makeElementProtected;

public function isElementPublic
  input SCode.Element inElement;
  output Boolean outIsPublic;
algorithm
  outIsPublic := visibilityBool(prefixesVisibility(elementPrefixes(inElement)));
end isElementPublic;

public function isElementProtected
  input SCode.Element inElement;
  output Boolean outIsProtected;
algorithm
  outIsProtected := not visibilityBool(prefixesVisibility(elementPrefixes(inElement)));
end isElementProtected;

public function isElementEncapsulated
  input SCode.Element inElement;
  output Boolean outIsEncapsulated;
algorithm
  outIsEncapsulated := match(inElement)
    case SCode.CLASS(encapsulatedPrefix = SCode.ENCAPSULATED()) then true;
    else false;
  end match;
end isElementEncapsulated;

public function replaceOrAddElementInProgram
"replace the element in program at the specified path (includes the element name).
 if the element does not exist at that location then it fails.
 this function will fail if any of the path prefixes
 to the element are not found in the given program"
  input SCode.Program inProgram;
  input SCode.Element inElement;
  input Absyn.Path inClassPath;
  output SCode.Program outProgram;
algorithm
  outProgram := match(inProgram, inElement, inClassPath)
    local
      SCode.Program sp;
      SCode.Element c, e;
      Absyn.Path p;
      Absyn.Ident i;

    case (_, _, Absyn.QUALIFIED(i, p))
      equation
        e = getElementWithId(inProgram, i);
        sp = getElementsFromElement(inProgram, e);
        sp = replaceOrAddElementInProgram(sp, inElement, p);
        e = replaceElementsInElement(inProgram, e, sp);
        sp = replaceOrAddElementWithId(inProgram, e, i);
      then
        sp;

    case (_, _, Absyn.IDENT(i))
      equation
        sp = replaceOrAddElementWithId(inProgram, inElement, i);
      then
        sp;

    case (_, _, Absyn.FULLYQUALIFIED(p))
      equation
        sp = replaceOrAddElementInProgram(inProgram, inElement, p);
      then
        sp;
  end match;
end replaceOrAddElementInProgram;

public function replaceOrAddElementWithId
"replace the class in program at the specified id.
 if the class does not exist at that location then is is added"
  input SCode.Program inProgram;
  input SCode.Element inElement;
  input SCode.Ident inId;
  output SCode.Program outProgram;
algorithm
  outProgram := matchcontinue(inProgram, inElement, inId)
    local
      SCode.Program sp, rest;
      SCode.Element c, e;
      Absyn.Path p;
      Absyn.Ident i, n;

    case (SCode.CLASS(name = n)::rest, _, i)
      equation
        true = stringEq(n, i);
      then
        inElement::rest;

    case (SCode.COMPONENT(name = n)::rest, _, i)
      equation
        true = stringEq(n, i);
      then
        inElement::rest;

    case (SCode.EXTENDS(baseClassPath = p)::rest, _, i)
      equation
        true = stringEq(AbsynUtil.pathString(p), i);
      then
        inElement::rest;

    case (e::rest, _, i)
      equation
        sp = replaceOrAddElementWithId(rest, inElement, i);
      then
        e::sp;

    // not found, add it
    case ({}, _, _)
      equation
        sp = {inElement};
      then
        sp;
  end matchcontinue;
end replaceOrAddElementWithId;

public function getElementsFromElement
  input SCode.Program inProgram;
  input SCode.Element inElement;
  output SCode.Program outProgram;
algorithm
  outProgram := match(inProgram, inElement)
    local
      SCode.Program els;
      SCode.Element e;
      Absyn.Path p;
      Absyn.Ident i;

    // a class with parts
    case (_, SCode.CLASS(classDef = SCode.PARTS(elementLst = els))) then els;
    // a class extends
    case (_, SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = SCode.PARTS(elementLst = els)))) then els;
    // a derived class
    case (_, SCode.CLASS(classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(path = p))))
      equation
        e = getElementWithPath(inProgram, p);
        els = getElementsFromElement(inProgram, e);
      then
        els;
  end match;
end getElementsFromElement;

public function replaceElementsInElement
"replaces elements in element, it will search for elements pointed by derived"
  input SCode.Program inProgram;
  input SCode.Element inElement;
  input SCode.Program inElements;
  output SCode.Element outElement;
algorithm
  outElement := matchcontinue(inProgram, inElement, inElements)
    local
      SCode.Program els;
      SCode.Element e;
      Absyn.Path p;
      Absyn.Ident i;
      SCode.Ident name "the name of the class";
      SCode.Prefixes prefixes "the common class or component prefixes";
      SCode.Encapsulated encapsulatedPrefix "the encapsulated prefix";
      SCode.Partial partialPrefix "the partial prefix";
      SCode.Restriction restriction "the restriction of the class";
      SCode.ClassDef classDef "the class specification";
      SourceInfo info "the class information";
      SCode.Comment cmt;

    // a class with parts, non derived
    case (_, SCode.CLASS(name, prefixes, encapsulatedPrefix, partialPrefix, restriction, classDef, cmt, info), _)
      equation
        (classDef, NONE()) = replaceElementsInClassDef(inProgram, classDef, inElements);
      then
        SCode.CLASS(name, prefixes, encapsulatedPrefix, partialPrefix, restriction, classDef, cmt, info);

    // a class derived
    case (_, SCode.CLASS(classDef = classDef), _)
      equation
        (classDef, SOME(e)) = replaceElementsInClassDef(inProgram, classDef, inElements);
      then
        e;

  end matchcontinue;
end replaceElementsInElement;

public function replaceElementsInClassDef
"replaces the elements in class definition.
 if derived a SOME(element) is returned,
 otherwise the modified class def and NONE()"
  input SCode.Program inProgram;
  input output SCode.ClassDef classDef;
  input SCode.Program inElements;
        output Option<SCode.Element> outElementOpt;
algorithm
  outElementOpt := match classDef
    local
      SCode.Element e;
      Absyn.Path p;
      SCode.ClassDef composition;

    // a derived class
    case SCode.DERIVED(typeSpec = Absyn.TPATH(path = p))
      algorithm
        e := getElementWithPath(inProgram, p);
        e := replaceElementsInElement(inProgram, e, inElements);
      then
        SOME(e);

    // a parts
    case SCode.PARTS()
      algorithm
        classDef.elementLst := inElements;
      then
        NONE();

    // a class extends
    case SCode.CLASS_EXTENDS(composition = composition)
      algorithm
        (composition, outElementOpt) := replaceElementsInClassDef(inProgram, composition, inElements);

        if isNone(outElementOpt) then
          classDef.composition := composition;
        end if;
      then
        outElementOpt;

  end match;
end replaceElementsInClassDef;

protected function getElementWithId
"returns the element from the program having the name as the id.
 if the element does not exist it fails"
  input SCode.Program inProgram;
  input String inId;
  output SCode.Element outElement;
algorithm
  outElement := match(inProgram, inId)
    local
      SCode.Program sp, rest;
      SCode.Element c, e;
      Absyn.Path p;
      Absyn.Ident i, n;

    case ((e as SCode.CLASS(name = n))::_, i)
      guard stringEq(n, i)
      then
        e;

    case ((e as SCode.COMPONENT(name = n))::_, i)
      guard stringEq(n, i)
      then
        e;

    case ((e as SCode.EXTENDS(baseClassPath = p))::_, i)
      guard stringEq(AbsynUtil.pathString(p), i)
      then
        e;

    case (_::rest, i)
      then getElementWithId(rest, i);

  end match;
end getElementWithId;

public function getElementWithPath
"returns the element from the program having the name as the id.
 if the element does not exist it fails"
  input SCode.Program inProgram;
  input Absyn.Path inPath;
  output SCode.Element outElement;
algorithm
  outElement := match (inProgram, inPath)
    local
      SCode.Program sp, rest;
      SCode.Element c, e;
      Absyn.Path p;
      Absyn.Ident i, n;

    case (_, Absyn.FULLYQUALIFIED(p))
      then getElementWithPath(inProgram, p);

    case (_, Absyn.IDENT(i))
      equation
        e = getElementWithId(inProgram, i);
      then
        e;

    case (_, Absyn.QUALIFIED(i, p))
      equation
        e = getElementWithId(inProgram, i);
        sp = getElementsFromElement(inProgram, e);
        e = getElementWithPath(sp, p);
      then
        e;
  end match;
end getElementWithPath;

public function getElementName ""
  input SCode.Element e;
  output String s;
algorithm
  s := match(e)
    local Absyn.Path p;
    case (SCode.COMPONENT(name = s)) then s;
    case (SCode.CLASS(name = s)) then s;
    case (SCode.EXTENDS(baseClassPath = p)) then AbsynUtil.pathString(p);
  end match;
end getElementName;

public function setBaseClassPath
"@auhtor: adrpo
 set the base class path in extends"
  input SCode.Element inE;
  input Absyn.Path inBcPath;
  output SCode.Element outE;
protected
  SCode.Path bc;
  SCode.Visibility v;
  SCode.Mod m;
  Option<SCode.Annotation> a;
  SourceInfo i;
algorithm
  SCode.EXTENDS(bc, v, m, a, i) := inE;
  outE := SCode.EXTENDS(inBcPath, v, m, a, i);
end setBaseClassPath;

public function getBaseClassPath
"@auhtor: adrpo
 return the base class path in extends"
  input SCode.Element inE;
  output Absyn.Path outBcPath;
protected
  SCode.Path bc;
  SCode.Visibility v;
  SCode.Mod m;
  Option<SCode.Annotation> a;
  SourceInfo i;
algorithm
  SCode.EXTENDS(baseClassPath = outBcPath) := inE;
end getBaseClassPath;

public function setComponentTypeSpec
"@auhtor: adrpo
 set the typespec path in component"
  input SCode.Element inE;
  input Absyn.TypeSpec inTypeSpec;
  output SCode.Element outE;
protected
  SCode.Ident n;
  SCode.Prefixes pr;
  SCode.Attributes atr;
  Absyn.TypeSpec ts;
  SCode.Comment cmt;
  Option<Absyn.Exp> cnd;
  SCode.Path bc;
  SCode.Visibility v;
  SCode.Mod m;
  Option<SCode.Annotation> a;
  SourceInfo i;
algorithm
  SCode.COMPONENT(n, pr, atr, ts, m, cmt, cnd, i) := inE;
  outE := SCode.COMPONENT(n, pr, atr, inTypeSpec, m, cmt, cnd, i);
end setComponentTypeSpec;

public function getComponentTypeSpec
"@auhtor: adrpo
 get the typespec path in component"
  input SCode.Element inE;
  output Absyn.TypeSpec outTypeSpec;
protected
algorithm
  SCode.COMPONENT(typeSpec = outTypeSpec) := inE;
end getComponentTypeSpec;

public function setComponentMod
"@auhtor: adrpo
 set the modification in component"
  input SCode.Element inE;
  input SCode.Mod inMod;
  output SCode.Element outE;
protected
  SCode.Ident n;
  SCode.Prefixes pr;
  SCode.Attributes atr;
  Absyn.TypeSpec ts;
  SCode.Comment cmt;
  Option<Absyn.Exp> cnd;
  SCode.Path bc;
  SCode.Visibility v;
  SCode.Mod m;
  Option<SCode.Annotation> a;
  SourceInfo i;
algorithm
  SCode.COMPONENT(n, pr, atr, ts, m, cmt, cnd, i) := inE;
  outE := SCode.COMPONENT(n, pr, atr, ts, inMod, cmt, cnd, i);
end setComponentMod;

public function getComponentMod
"@auhtor: adrpo
 get the modification in component"
  input SCode.Element inE;
  output SCode.Mod outMod;
algorithm
  SCode.COMPONENT(modifications = outMod) := inE;
end getComponentMod;

public function isDerivedClass
  input SCode.Element inClass;
  output Boolean isDerived;
algorithm
  isDerived := match(inClass)
    case SCode.CLASS(classDef = SCode.DERIVED()) then true;
    else false;
  end match;
end isDerivedClass;

public function isClassExtends
  input SCode.Element cls;
  output Boolean isCE;
algorithm
  isCE := match cls
    case SCode.CLASS(classDef = SCode.CLASS_EXTENDS()) then true;
    else false;
  end match;
end isClassExtends;

public function setDerivedTypeSpec
"@auhtor: adrpo
 set the base class path in extends"
  input SCode.Element inE;
  input Absyn.TypeSpec inTypeSpec;
  output SCode.Element outE;
protected
  SCode.Ident n;
  SCode.Prefixes pr;
  SCode.Attributes atr;
  SCode.Encapsulated ep;
  SCode.Partial pp;
  SCode.Restriction res;
  SCode.ClassDef cd;
  SourceInfo i;
  Absyn.TypeSpec ts;
  Option<SCode.Annotation> ann;
  SCode.Comment cmt;
  SCode.Mod m;
algorithm
  SCode.CLASS(n, pr, ep, pp, res, cd, cmt, i) := inE;
  SCode.DERIVED(ts, m, atr) := cd;
  cd := SCode.DERIVED(inTypeSpec, m, atr);
  outE := SCode.CLASS(n, pr, ep, pp, res, cd, cmt, i);
end setDerivedTypeSpec;

public function getDerivedTypeSpec
"@auhtor: adrpo
 set the base class path in extends"
  input SCode.Element inE;
  output Absyn.TypeSpec outTypeSpec;
protected
algorithm
  SCode.CLASS(classDef=SCode.DERIVED(typeSpec = outTypeSpec)) := inE;
end getDerivedTypeSpec;

public function getDerivedMod
"@auhtor: adrpo
 set the base class path in extends"
  input SCode.Element inE;
  output SCode.Mod outMod;
protected
algorithm
  SCode.CLASS(classDef=SCode.DERIVED(modifications = outMod)) := inE;
end getDerivedMod;

public function setClassPrefixes
  input SCode.Prefixes inPrefixes;
  input SCode.Element cl;
  output SCode.Element outCl;
algorithm
  outCl := match(inPrefixes, cl)
    local
      SCode.ClassDef parts;
      SCode.Encapsulated e;
      SCode.Ident id;
      SourceInfo info;
      SCode.Restriction restriction;
      SCode.Prefixes prefixes;
      SCode.Partial pp;
      SCode.Comment cmt;

    // not the same, change
    case(_,SCode.CLASS(id,_,e,pp,restriction,parts,cmt,info))
      then SCode.CLASS(id,inPrefixes,e,pp,restriction,parts,cmt,info);
  end match;
end setClassPrefixes;

public function makeEquation
  input SCode.EEquation inEEq;
  output SCode.Equation outEq;
algorithm
  outEq := SCode.EQUATION(inEEq);
end makeEquation;

public function getClassDef
  input SCode.Element inClass;
  output SCode.ClassDef outCdef;
algorithm
  outCdef := match(inClass)
    case SCode.CLASS(classDef = outCdef) then outCdef;
  end match;
end getClassDef;

public function equationsContainReinit
"@author:
 returns true if equations contains reinit"
  input list<SCode.EEquation> inEqs;
  output Boolean hasReinit;
algorithm
  hasReinit := match(inEqs)
    local Boolean b;
    case _
      equation
        b = List.applyAndFold(inEqs, boolOr, equationContainReinit, false);
      then
        b;
  end match;
end equationsContainReinit;

public function equationContainReinit
"@author:
 returns true if equation contains reinit"
  input SCode.EEquation inEq;
  output Boolean hasReinit;
algorithm
  hasReinit := match(inEq)
    local
      Boolean b;
      list<SCode.EEquation> eqs;
      list<list<SCode.EEquation>> eqs_lst;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> tpl_el;

    case SCode.EQ_REINIT() then true;
    case SCode.EQ_WHEN(eEquationLst = eqs, elseBranches = tpl_el)
      equation
        b = equationsContainReinit(eqs);
        eqs_lst = List.map(tpl_el, Util.tuple22);
        b = List.applyAndFold(eqs_lst, boolOr, equationsContainReinit, b);
      then
        b;

    case SCode.EQ_IF(thenBranch = eqs_lst, elseBranch = eqs)
      equation
        b = equationsContainReinit(eqs);
        b = List.applyAndFold(eqs_lst, boolOr, equationsContainReinit, b);
      then
        b;

    case SCode.EQ_FOR(eEquationLst = eqs)
      equation
        b = equationsContainReinit(eqs);
      then
        b;

    else false;

  end match;
end equationContainReinit;

public function algorithmsContainReinit
"@author:
 returns true if statements contains reinit"
  input list<SCode.Statement> inAlgs;
  output Boolean hasReinit;
algorithm
  hasReinit := match(inAlgs)
    local Boolean b;
    case _
      equation
        b = List.applyAndFold(inAlgs, boolOr, algorithmContainReinit, false);
      then
        b;
  end match;
end algorithmsContainReinit;

public function algorithmContainReinit
"@author:
 returns true if statement contains reinit"
  input SCode.Statement inAlg;
  output Boolean hasReinit;
algorithm
  hasReinit := match(inAlg)
    local
      Boolean b, b1, b2, b3;
      list<SCode.Statement> algs, algs1, algs2;
      list<list<SCode.Statement>> algs_lst;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> tpl_alg;

    case SCode.ALG_REINIT() then true;

    case SCode.ALG_WHEN_A(branches = tpl_alg)
      equation
        algs_lst = List.map(tpl_alg, Util.tuple22);
        b = List.applyAndFold(algs_lst, boolOr, algorithmsContainReinit, false);
      then
        b;

    case SCode.ALG_IF(trueBranch = algs1, elseIfBranch = tpl_alg, elseBranch = algs2)
      equation
        b1 = algorithmsContainReinit(algs1);
        algs_lst = List.map(tpl_alg, Util.tuple22);
        b2 = List.applyAndFold(algs_lst, boolOr, algorithmsContainReinit, b1);
        b3 = algorithmsContainReinit(algs2);
        b = boolOr(b1, boolOr(b2, b3));
      then
        b;

    case SCode.ALG_FOR(forBody = algs)
      equation
        b = algorithmsContainReinit(algs);
      then
        b;

    case SCode.ALG_WHILE(whileBody = algs)
      equation
        b = algorithmsContainReinit(algs);
      then
        b;

    else false;

  end match;
end algorithmContainReinit;

public function getClassPartialPrefix
  input SCode.Element inElement;
  output SCode.Partial outPartial;
algorithm
  SCode.CLASS(partialPrefix = outPartial) := inElement;
end getClassPartialPrefix;

public function getClassRestriction
  input SCode.Element inElement;
  output SCode.Restriction outRestriction;
algorithm
  SCode.CLASS(restriction = outRestriction) := inElement;
end getClassRestriction;

public function isRedeclareSubMod
  input SCode.SubMod inSubMod;
  output Boolean outIsRedeclare;
algorithm
  outIsRedeclare := match(inSubMod)
    case SCode.NAMEMOD(mod = SCode.REDECL()) then true;
    else false;
  end match;
end isRedeclareSubMod;

public function componentMod
  input SCode.Element inElement;
  output SCode.Mod outMod;
algorithm
  outMod := match(inElement)
    local
      SCode.Mod mod;

    case SCode.COMPONENT(modifications = mod) then mod;
    else SCode.NOMOD();

  end match;
end componentMod;

public function elementMod
  input SCode.Element inElement;
  output SCode.Mod outMod;
algorithm
  outMod := match(inElement)
    local
      SCode.Mod mod;

    case SCode.COMPONENT(modifications = mod) then mod;
    case SCode.CLASS(classDef = SCode.DERIVED(modifications = mod)) then mod;
    case SCode.CLASS(classDef = SCode.CLASS_EXTENDS(modifications = mod)) then mod;
    case SCode.EXTENDS(modifications = mod) then mod;

  end match;
end elementMod;

public function setElementMod
  "Sets the modifier of an element, or fails if the element is not capable of
   having a modifier."
  input SCode.Element inElement;
  input SCode.Mod inMod;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement, inMod)
    local
      SCode.Ident n;
      SCode.Prefixes pf;
      SCode.Attributes attr;
      Absyn.TypeSpec ty;
      SCode.Comment cmt;
      Option<Absyn.Exp> cnd;
      SourceInfo i;
      SCode.Encapsulated ep;
      SCode.Partial pp;
      SCode.Restriction res;
      SCode.ClassDef cdef;
      Absyn.Path bc;
      SCode.Visibility vis;
      Option<SCode.Annotation> ann;

    case (SCode.COMPONENT(n, pf, attr, ty, _, cmt, cnd, i), _)
      then SCode.COMPONENT(n, pf, attr, ty, inMod, cmt, cnd, i);

    case (SCode.CLASS(n, pf, ep, pp, res, cdef, cmt, i), _)
      equation
        cdef = setClassDefMod(cdef, inMod);
      then
        SCode.CLASS(n, pf, ep, pp, res, cdef, cmt, i);

    case (SCode.EXTENDS(bc, vis, _, ann, i), _)
      then SCode.EXTENDS(bc, vis, inMod, ann, i);

  end match;
end setElementMod;

protected function setClassDefMod
  input SCode.ClassDef inClassDef;
  input SCode.Mod inMod;
  output SCode.ClassDef outClassDef;
algorithm
  outClassDef := match(inClassDef, inMod)
    local
      SCode.Ident bc;
      SCode.ClassDef cdef;
      Absyn.TypeSpec ty;
      SCode.Attributes attr;

    case (SCode.DERIVED(ty, _, attr), _) then SCode.DERIVED(ty, inMod, attr);
    case (SCode.CLASS_EXTENDS(_, cdef), _) then SCode.CLASS_EXTENDS(inMod, cdef);
    else inClassDef;

  end match;
end setClassDefMod;

public function isBuiltinElement
  input SCode.Element inElement;
  output Boolean outIsBuiltin;
algorithm
  outIsBuiltin := match(inElement)
    local
      SCode.Annotation ann;

    case SCode.CLASS(classDef = SCode.PARTS(externalDecl =
      SOME(SCode.EXTERNALDECL(lang = SOME("builtin"))))) then true;
    case SCode.CLASS(cmt = SCode.COMMENT(annotation_ = SOME(ann)))
      then hasBooleanNamedAnnotation(ann, "__OpenModelica_builtin");
    else false;
  end match;
end isBuiltinElement;

public function partitionElements
  input list<SCode.Element> inElements;
  output list<SCode.Element> outComponents;
  output list<SCode.Element> outClasses;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outImports;
  output list<SCode.Element> outDefineUnits;
algorithm
  (outComponents, outClasses, outExtends, outImports, outDefineUnits) :=
    partitionElements2(inElements, {}, {}, {}, {}, {});
end partitionElements;

protected function partitionElements2
  input list<SCode.Element> inElements;
  input list<SCode.Element> inComponents;
  input list<SCode.Element> inClasses;
  input list<SCode.Element> inExtends;
  input list<SCode.Element> inImports;
  input list<SCode.Element> inDefineUnits;
  output list<SCode.Element> outComponents;
  output list<SCode.Element> outClasses;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outImports;
  output list<SCode.Element> outDefineUnits;
algorithm
  (outComponents, outClasses, outExtends, outImports, outDefineUnits) :=
  match(inElements, inComponents, inClasses, inExtends, inImports, inDefineUnits)
    local
      SCode.Element el;
      list<SCode.Element> rest_el, comp, cls, ext, imp, def;

    case ((el as SCode.COMPONENT()) :: rest_el, comp, cls, ext, imp, def)
      equation
        (comp, cls, ext, imp, def) =
          partitionElements2(rest_el, el :: comp, cls, ext, imp, def);
      then
        (comp, cls, ext, imp, def);

    case ((el as SCode.CLASS()) :: rest_el, comp, cls, ext, imp, def)
      equation
        (comp, cls, ext, imp, def) =
          partitionElements2(rest_el, comp, el :: cls, ext, imp, def);
      then
        (comp, cls, ext, imp, def);

    case ((el as SCode.EXTENDS()) :: rest_el, comp, cls, ext, imp, def)
      equation
        (comp, cls, ext, imp, def) =
          partitionElements2(rest_el, comp, cls, el :: ext, imp, def);
      then
        (comp, cls, ext, imp, def);

    case ((el as SCode.IMPORT()) :: rest_el, comp, cls, ext, imp, def)
      equation
        (comp, cls, ext, imp, def) =
          partitionElements2(rest_el, comp, cls, ext, el :: imp, def);
      then
        (comp, cls, ext, imp, def);

    case ((el as SCode.DEFINEUNIT()) :: rest_el, comp, cls, ext, imp, def)
      equation
        (comp, cls, ext, imp, def) =
          partitionElements2(rest_el, comp, cls, ext, imp, el :: def);
      then
        (comp, cls, ext, imp, def);

    case ({}, comp, cls, ext, imp, def)
      then (listReverse(comp), listReverse(cls), listReverse(ext),
            listReverse(imp), listReverse(def));

  end match;
end partitionElements2;

public function isExternalFunctionRestriction
  input SCode.FunctionRestriction inRestr;
  output Boolean isExternal;
algorithm
  isExternal := match(inRestr)
    case (SCode.FR_EXTERNAL_FUNCTION()) then true;
    else false;
  end match;
end isExternalFunctionRestriction;

public function isImpureFunctionRestriction
  input SCode.FunctionRestriction inRestr;
  output Boolean isExternal;
algorithm
  isExternal := match(inRestr)
    case (SCode.FR_EXTERNAL_FUNCTION(true)) then true;
    case (SCode.FR_NORMAL_FUNCTION(true)) then true;
    else false;
  end match;
end isImpureFunctionRestriction;

public function isRestrictionImpure
  input SCode.Restriction inRestr;
  input Boolean hasZeroOutputPreMSL3_2;
  output Boolean isExternal;
algorithm
  isExternal := match(inRestr,hasZeroOutputPreMSL3_2)
    case (SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(true)),_) then true;
    case (SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(true)),_) then true;
    case (SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(false)),false) then true;
    else false;
  end match;
end isRestrictionImpure;

public function setElementVisibility
  input SCode.Element inElement;
  input SCode.Visibility inVisibility;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement, inVisibility)
    local
      SCode.Ident name;
      SCode.Prefixes prefs;
      SCode.Attributes attr;
      Absyn.TypeSpec ty;
      SCode.Mod mod;
      SCode.Comment cmt;
      Option<Absyn.Exp> cond;
      SourceInfo info;
      SCode.Encapsulated ep;
      SCode.Partial pp;
      SCode.Restriction res;
      SCode.ClassDef cdef;
      Absyn.Path bc;
      Option<SCode.Annotation> ann;
      Absyn.Import imp;
      Option<String> unit;
      Option<Real> weight;

    case (SCode.COMPONENT(name, prefs, attr, ty, mod, cmt, cond, info), _)
      equation
        prefs = prefixesSetVisibility(prefs, inVisibility);
      then
        SCode.COMPONENT(name, prefs, attr, ty, mod, cmt, cond, info);

    case (SCode.CLASS(name, prefs, ep, pp, res, cdef, cmt, info), _)
      equation
        prefs = prefixesSetVisibility(prefs, inVisibility);
      then
        SCode.CLASS(name, prefs, ep, pp, res, cdef, cmt, info);

    case (SCode.EXTENDS(bc, _, mod, ann, info), _)
      then SCode.EXTENDS(bc, inVisibility, mod, ann, info);

    case (SCode.IMPORT(imp, _, info), _)
      then SCode.IMPORT(imp, inVisibility, info);

    case (SCode.DEFINEUNIT(name, _, unit, weight, info), _)
      then SCode.DEFINEUNIT(name, inVisibility, unit, weight, info);

  end match;
end setElementVisibility;

public function isClassNamed
  "Returns true if the given element is a class with the given name, otherwise false."
  input SCode.Ident inName;
  input SCode.Element inClass;
  output Boolean outIsNamed;
algorithm
  outIsNamed := match(inName, inClass)
    local
      SCode.Ident name;

    case (_, SCode.CLASS(name = name)) then stringEq(inName, name);
    else false;
  end match;
end isClassNamed;

public function getElementComment
  "Returns the comment of an element."
  input SCode.Element inElement;
  output Option<SCode.Comment> outComment;
algorithm
  outComment := match(inElement)
    local
      SCode.Comment cmt;
      SCode.ClassDef cdef;

    case SCode.COMPONENT(comment = cmt) then SOME(cmt);
    case SCode.CLASS(cmt = cmt) then SOME(cmt);
    else NONE();

  end match;
end getElementComment;

public function stripAnnotationFromComment
  "Removes the annotation from a comment."
  input Option<SCode.Comment> inComment;
  output Option<SCode.Comment> outComment;
algorithm
  outComment := match(inComment)
    local
      Option<String> str;
      Option<SCode.Comment> cmt;

    case SOME(SCode.COMMENT(_, str)) then SOME(SCode.COMMENT(NONE(), str));
    else NONE();

  end match;
end stripAnnotationFromComment;

public function isOverloadedFunction
  input SCode.Element inElement;
  output Boolean isOverloaded;
algorithm
  isOverloaded := match(inElement)
    case SCode.CLASS(classDef = SCode.OVERLOAD()) then true;
    else false;
  end match;
end isOverloadedFunction;

public function mergeWithOriginal
"@author: adrpo
 this function merges the original declaration with the redeclared declaration, see 7.3.2 in Spec.
 - modifiers from the constraining class on derived classes are merged into the new declaration
 - modifiers from the original derived classes are merged into the new declaration
 - if the original declaration has no constraining type the derived declaration is used
 - prefixes and attributes are merged
 same with components
 TODO! how about non-short class definitions with constrained by with modifications?"
  input SCode.Element inNew;
  input SCode.Element inOld;
  output SCode.Element outNew;
algorithm
  outNew := matchcontinue(inNew, inOld)
    local
      SCode.Element n, o;
      SCode.Ident name1,name2;
      SCode.Prefixes prefixes1, prefixes2;
      SCode.Encapsulated en1, en2;
      SCode.Partial p1,p2;
      SCode.Restriction restr1, restr2;
      SCode.Attributes attr1,attr2;
      SCode.Mod mod1,mod2;
      Absyn.TypeSpec tp1,tp2;
      Absyn.Import im1,im2;
      Absyn.Path path1,path2;
      Option<String> os1,os2;
      Option<Real> or1,or2;
      Option<Absyn.Exp> cond1, cond2;
      SCode.ClassDef cd1,cd2;
      SCode.Comment cm;
      SourceInfo i;
      SCode.Mod mCCNew, mCCOld;

    // for functions return the new one!
    case (_, _)
      equation
        true = isFunction(inNew);
      then
        inNew;

    case (SCode.CLASS(name1,prefixes1,en1,p1,restr1,cd1,cm,i),SCode.CLASS(_,prefixes2,_,_,_,cd2,_,_))
      equation
        mCCNew = getConstrainedByModifiers(prefixes1);
        mCCOld = getConstrainedByModifiers(prefixes2);
        cd1 = mergeClassDef(cd1, cd2, mCCNew, mCCOld);
        prefixes1 = propagatePrefixes(prefixes2, prefixes1);
        n = SCode.CLASS(name1,prefixes1,en1,p1,restr1,cd1,cm,i);
      then
        n;

    else inNew;

  end matchcontinue;
end mergeWithOriginal;

public function getConstrainedByModifiers
  input SCode.Prefixes inPrefixes;
  output SCode.Mod outMod;
algorithm
  outMod := match(inPrefixes)
    local SCode.Mod m;
    case (SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(SOME(SCode.CONSTRAINCLASS(modifier = m)))))
      then m;
    else SCode.NOMOD();
  end match;
end getConstrainedByModifiers;

public function mergeClassDef
"@author: adrpo
 see mergeWithOriginal"
  input SCode.ClassDef inNew;
  input SCode.ClassDef inOld;
  input SCode.Mod inCCModNew;
  input SCode.Mod inCCModOld;
  output SCode.ClassDef outNew;
algorithm
  outNew := match(inNew, inOld, inCCModNew, inCCModOld)
    local
      SCode.ClassDef n, o;
      Absyn.TypeSpec ts1, ts2;
      SCode.Mod m1, m2;
      SCode.Attributes a1, a2;

    case (SCode.DERIVED(ts1,m1,a1),
          SCode.DERIVED(_,m2,a2), _, _)
      equation
        m2 = mergeModifiers(m2, inCCModOld);
        m1 = mergeModifiers(m1, inCCModNew);
        m2 = mergeModifiers(m1, m2);
        a2 = propagateAttributes(a2, a1);
        n = SCode.DERIVED(ts1,m2,a2);
      then
        n;

  end match;
end mergeClassDef;

public function mergeModifiers
  input SCode.Mod inNewMod;
  input SCode.Mod inOldMod;
  output SCode.Mod outMod;
algorithm
  outMod := matchcontinue(inNewMod, inOldMod)
    local
      SCode.Final f1, f2;
      SCode.Each e1, e2;
      list<SCode.SubMod> sl1, sl2, sl;
      Option<Absyn.Exp> b1, b2, b;
      SourceInfo i1, i2;
      SCode.Mod m;

    case (_, SCode.NOMOD()) then inNewMod;
    case (SCode.NOMOD(), _) then inOldMod;
    case (SCode.REDECL(), _) then inNewMod;

    case (SCode.MOD(f1, e1, sl1, b1, i1),
          SCode.MOD(f2, e2, sl2, b2, _))
      equation
        b = mergeBindings(b1, b2);
        sl = mergeSubMods(sl1, sl2);
        if referenceEq(b, b1) and referenceEq(sl, sl1) then
          m = inNewMod;
        elseif referenceEq(b, b2) and referenceEq(sl, sl2) and valueEq(f1, f2) and valueEq(e1, e2) then
          m = inOldMod;
        else
          m = SCode.MOD(f1, e1, sl, b, i1);
        end if;
      then
        m;

    else inNewMod;

  end matchcontinue;
end mergeModifiers;

protected function mergeBindings
  input Option<Absyn.Exp> inNew;
  input Option<Absyn.Exp> inOld;
  output Option<Absyn.Exp> outBnd;
algorithm
  outBnd := match(inNew, inOld)
    case (SOME(_), _) then inNew;
    case (NONE(), _) then inOld;
  end match;
end mergeBindings;

protected function mergeSubMods
  input list<SCode.SubMod> inNew;
  input list<SCode.SubMod> inOld;
  output list<SCode.SubMod> outSubs;
algorithm
  outSubs := matchcontinue(inNew, inOld)
    local
      list<SCode.SubMod> sl, rest, old;
      SCode.SubMod s;

    case ({}, _) then inOld;

    case (s::rest, _)
      equation
        old = removeSub(s, inOld);
        sl = mergeSubMods(rest, old);
      then
        s::sl;

     else inNew;
  end matchcontinue;
end mergeSubMods;

protected function removeSub
  input SCode.SubMod inSub;
  input list<SCode.SubMod> inOld;
  output list<SCode.SubMod> outSubs;
algorithm
  outSubs := matchcontinue(inSub, inOld)
    local
      list<SCode.SubMod> rest;
      SCode.Ident id1, id2;
      list<SCode.Subscript> idxs1, idxs2;
      SCode.SubMod s;

    case (_, {}) then inOld;

    case (SCode.NAMEMOD(ident = id1), SCode.NAMEMOD(ident = id2)::rest)
      equation
        true = stringEqual(id1, id2);
      then
        rest;

    case (_, s::rest)
      equation
        rest = removeSub(inSub, rest);
      then
        s::rest;
  end matchcontinue;
end removeSub;

public function mergeComponentModifiers
  input SCode.Element inNewComp;
  input SCode.Element inOldComp;
  output SCode.Element outComp;
algorithm
  outComp := match(inNewComp, inOldComp)
    local
      SCode.Ident n1,n2;
      SCode.Prefixes p1,p2;
      SCode.Attributes a1,a2;
      Absyn.TypeSpec t1,t2;
      SCode.Mod m1,m2,m;
      SCode.Comment c1,c2;
      Option<Absyn.Exp> cnd1,cnd2;
      SourceInfo i1,i2;
      SCode.Element c;

    case (SCode.COMPONENT(n1, p1, a1, t1, m1, c1, cnd1, i1),
          SCode.COMPONENT(_, _, _, _, m2, _, _, _))
      equation
        m = mergeModifiers(m1, m2);
        c = SCode.COMPONENT(n1, p1, a1, t1, m, c1, cnd1, i1);
      then
        c;

  end match;
end mergeComponentModifiers;

public function propagateAttributes
  input SCode.Attributes inOriginalAttributes;
  input SCode.Attributes inNewAttributes;
  input Boolean inNewTypeIsArray = false;
  output SCode.Attributes outNewAttributes;
protected
  Absyn.ArrayDim dims1, dims2;
  SCode.ConnectorType ct1, ct2;
  SCode.Parallelism prl1,prl2;
  SCode.Variability var1, var2;
  Absyn.Direction dir1, dir2;
  Absyn.IsField if1, if2;
algorithm
  SCode.ATTR(dims1, ct1, prl1, var1, dir1, if1) := inOriginalAttributes;
  SCode.ATTR(dims2, ct2, prl2, var2, dir2, if2) := inNewAttributes;

  // If the new component has an array type, don't propagate the old dimensions.
  // E.g. type Real3 = Real[3];
  //      replaceable Real x[:];
  //      comp(redeclare Real3 x) => Real[3] x
  if not inNewTypeIsArray then
    dims2 := propagateArrayDimensions(dims1, dims2);
  end if;

  ct2 := propagateConnectorType(ct1, ct2);
  prl2 := propagateParallelism(prl1,prl2);
  var2 := propagateVariability(var1, var2);
  dir2 := propagateDirection(dir1, dir2);
  if2 := propagateIsField(if1,if2);
  outNewAttributes := SCode.ATTR(dims2, ct2, prl2, var2, dir2, if2);
end propagateAttributes;

public function propagateArrayDimensions
  input Absyn.ArrayDim inOriginalDims;
  input Absyn.ArrayDim inNewDims;
  output Absyn.ArrayDim outNewDims;
algorithm
  outNewDims := match(inOriginalDims, inNewDims)
    case (_, {}) then inOriginalDims;
    else inNewDims;
  end match;
end propagateArrayDimensions;

public function propagateConnectorType
  input SCode.ConnectorType inOriginalConnectorType;
  input SCode.ConnectorType inNewConnectorType;
  output SCode.ConnectorType outNewConnectorType;
algorithm
  outNewConnectorType := match(inOriginalConnectorType, inNewConnectorType)
    case (_, SCode.POTENTIAL()) then inOriginalConnectorType;
    else inNewConnectorType;
  end match;
end propagateConnectorType;

public function propagateParallelism
  input SCode.Parallelism inOriginalParallelism;
  input SCode.Parallelism inNewParallelism;
  output SCode.Parallelism outNewParallelism;
algorithm
  outNewParallelism := match(inOriginalParallelism, inNewParallelism)
    case (_, SCode.NON_PARALLEL()) then inOriginalParallelism;
    else inNewParallelism;
  end match;
end propagateParallelism;

public function propagateVariability
  input SCode.Variability inOriginalVariability;
  input SCode.Variability inNewVariability;
  output SCode.Variability outNewVariability;
algorithm
  outNewVariability := match(inOriginalVariability, inNewVariability)
    case (_, SCode.VAR()) then inOriginalVariability;
    else inNewVariability;
  end match;
end propagateVariability;

public function propagateDirection
  input Absyn.Direction inOriginalDirection;
  input Absyn.Direction inNewDirection;
  output Absyn.Direction outNewDirection;
algorithm
  outNewDirection := match(inOriginalDirection, inNewDirection)
    case (_, Absyn.BIDIR()) then inOriginalDirection;
    else inNewDirection;
  end match;
end propagateDirection;

public function propagateIsField
  input Absyn.IsField inOriginalIsField;
  input Absyn.IsField inNewIsField;
  output Absyn.IsField outNewIsField;
algorithm
  outNewIsField := match (inOriginalIsField, inNewIsField)
    case (_, Absyn.NONFIELD()) then inOriginalIsField;
    else inNewIsField;
  end match;
end propagateIsField;


public function propagateAttributesVar
  input SCode.Element inOriginalVar;
  input SCode.Element inNewVar;
  input Boolean inNewTypeIsArray;
  output SCode.Element outNewVar;
protected
  SCode.Ident name;
  SCode.Prefixes pref1, pref2;
  SCode.Attributes attr1, attr2;
  Absyn.TypeSpec ty;
  SCode.Mod mod;
  SCode.Comment cmt;
  Option<Absyn.Exp> cond;
  SourceInfo info;
algorithm
  SCode.COMPONENT(prefixes = pref1, attributes = attr1) := inOriginalVar;
  SCode.COMPONENT(name, pref2, attr2, ty, mod, cmt, cond, info) := inNewVar;
  pref2 := propagatePrefixes(pref1, pref2);
  attr2 := propagateAttributes(attr1, attr2, inNewTypeIsArray);
  outNewVar := SCode.COMPONENT(name, pref2, attr2, ty, mod, cmt, cond, info);
end propagateAttributesVar;

public function propagateAttributesClass
  input SCode.Element inOriginalClass;
  input SCode.Element inNewClass;
  output SCode.Element outNewClass;
protected
  SCode.Ident name;
  SCode.Prefixes pref1, pref2;
  SCode.Encapsulated ep;
  SCode.Partial pp;
  SCode.Restriction res;
  SCode.ClassDef cdef;
  SCode.Comment cmt;
  SourceInfo info;
algorithm
  SCode.CLASS(prefixes = pref1) := inOriginalClass;
  SCode.CLASS(name, pref2, ep, pp, res, cdef, cmt, info) := inNewClass;
  pref2 := propagatePrefixes(pref1, pref2);
  outNewClass := SCode.CLASS(name, pref2, ep, pp, res, cdef, cmt, info);
end propagateAttributesClass;

public function propagatePrefixes
  input SCode.Prefixes inOriginalPrefixes;
  input SCode.Prefixes inNewPrefixes;
  output SCode.Prefixes outNewPrefixes;
protected
  SCode.Visibility vis1, vis2;
  Absyn.InnerOuter io1, io2;
  SCode.Redeclare rdp;
  SCode.Final fp;
  SCode.Replaceable rpp;
algorithm
  SCode.PREFIXES(visibility = vis1, innerOuter = io1) := inOriginalPrefixes;
  SCode.PREFIXES(vis2, rdp, fp, io2, rpp) := inNewPrefixes;
  io2 := propagatePrefixInnerOuter(io1, io2);
  outNewPrefixes := SCode.PREFIXES(vis2, rdp, fp, io2, rpp);
end propagatePrefixes;

public function propagatePrefixInnerOuter
  input Absyn.InnerOuter inOriginalIO;
  input Absyn.InnerOuter inIO;
  output Absyn.InnerOuter outIO;
algorithm
  outIO := match(inOriginalIO, inIO)
    case (_, Absyn.NOT_INNER_OUTER()) then inOriginalIO;
    else inIO;
  end match;
end propagatePrefixInnerOuter;

public function isPackage
"Return true if Class is a partial."
  input SCode.Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inClass)
    case SCode.CLASS(restriction = SCode.R_PACKAGE()) then true;
    else false;
  end match;
end isPackage;

public function isPartial
"Return true if Class is a partial."
  input SCode.Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inClass)
    case SCode.CLASS(partialPrefix = SCode.PARTIAL()) then true;
    else false;
  end match;
end isPartial;

public function isValidPackageElement
  "Return true if the given element is allowed in a package, i.e. if it's a
   constant or non-component element. Otherwise returns false."
  input SCode.Element inElement;
  output Boolean outIsValid;
algorithm
  outIsValid := match(inElement)
    case SCode.COMPONENT(attributes = SCode.ATTR(variability = SCode.CONST())) then true;
    case SCode.COMPONENT() then false;
    else true;
  end match;
end isValidPackageElement;


public function classIsExternalObject
"returns true if a Class fulfills the requirements of an external object"
  input SCode.Element cl;
  output Boolean res;
algorithm
  res := match(cl)
    local
      list<SCode.Element> els;

    case SCode.CLASS(classDef=SCode.PARTS(elementLst=els))
      then isExternalObject(els);

    else false;
  end match;
end classIsExternalObject;

public function isExternalObject
"Returns true if the element list fulfills the condition of an External Object.
An external object extends the builtinClass ExternalObject, and has two local
functions, destructor and constructor. "
  input  list<SCode.Element> els;
  output Boolean res;
algorithm
  res := if listLength(els) == 3 then
           hasExtendsOfExternalObject(els)
     and hasExternalObjectDestructor(els)
     and hasExternalObjectConstructor(els)
         else
     false;
end isExternalObject;

protected function hasExtendsOfExternalObject
"returns true if element list contains 'extends ExternalObject;'"
  input list<SCode.Element> inEls;
  output Boolean res;
algorithm
  res:= match (inEls)
    local
      list<SCode.Element> els;
      Absyn.Path path;
    case {} then false;
    case SCode.EXTENDS(baseClassPath = path)::_
      guard( AbsynUtil.pathEqual(path, Absyn.IDENT("ExternalObject")) ) then true;
    case _::els then hasExtendsOfExternalObject(els);
  end match;
end hasExtendsOfExternalObject;

protected function hasExternalObjectDestructor
"returns true if element list contains 'function destructor .. end destructor'"
  input list<SCode.Element> inEls;
  output Boolean res;
algorithm
  res:= match(inEls)
    local list<SCode.Element> els;
    case SCode.CLASS(name="destructor")::_ then true;
    case _::els then hasExternalObjectDestructor(els);
    else false;
  end match;
end hasExternalObjectDestructor;

protected function hasExternalObjectConstructor
"returns true if element list contains 'function constructor ... end constructor'"
  input list<SCode.Element> inEls;
  output Boolean res;
algorithm
  res:= match(inEls)
    local list<SCode.Element> els;
    case SCode.CLASS(name="constructor")::_ then true;
    case _::els then hasExternalObjectConstructor(els);
    else false;
  end match;
end hasExternalObjectConstructor;

public function getExternalObjectDestructor
"returns the class 'function destructor .. end destructor' from element list"
  input list<SCode.Element> inEls;
  output SCode.Element cl;
algorithm
  cl:= match(inEls)
    local list<SCode.Element> els;
    case ((cl as SCode.CLASS(name="destructor"))::_) then cl;
    case (_::els) then getExternalObjectDestructor(els);
  end match;
end getExternalObjectDestructor;

public function getExternalObjectConstructor
"returns the class 'function constructor ... end constructor' from element list"
input list<SCode.Element> inEls;
output SCode.Element cl;
algorithm
  cl:= match(inEls)
    local list<SCode.Element> els;
    case ((cl as SCode.CLASS(name="constructor"))::_) then cl;
    case (_::els) then getExternalObjectConstructor(els);
  end match;
end getExternalObjectConstructor;

public function isInstantiableClassRestriction
  input SCode.Restriction inRestriction;
  output Boolean outIsInstantiable;
algorithm
  outIsInstantiable := match(inRestriction)
    case SCode.R_CLASS() then true;
    case SCode.R_MODEL() then true;
    case SCode.R_RECORD() then true;
    case SCode.R_BLOCK() then true;
    case SCode.R_CONNECTOR() then true;
    case SCode.R_TYPE() then true;
    case SCode.R_ENUMERATION() then true;
    else false;
  end match;
end isInstantiableClassRestriction;

public function isInitial
  input SCode.Initial inInitial;
  output Boolean isIn;
algorithm
  isIn := match inInitial
    case SCode.INITIAL() then true;
    else false;
  end match;
end isInitial;

public function checkSameRestriction
"check if the restrictions are the same for redeclared classes"
  input SCode.Restriction inResNew;
  input SCode.Restriction inResOrig;
  input SourceInfo inInfoNew;
  input SourceInfo inInfoOrig;
  output SCode.Restriction outRes;
  output SourceInfo outInfo;
algorithm
  (outRes, outInfo) := match(inResNew, inResOrig, inInfoNew, inInfoOrig)
    case (_, _, _, _)
      equation
        // todo: check if the restrictions are the same for redeclared classes
      then
        (inResNew, inInfoNew);
  end match;
end checkSameRestriction;

public function setComponentName
"@auhtor: adrpo
 set the name of the component"
  input SCode.Element inE;
  input SCode.Ident inName;
  output SCode.Element outE;
protected
  SCode.Ident n;
  SCode.Prefixes pr;
  SCode.Attributes atr;
  Absyn.TypeSpec ts;
  SCode.Comment cmt;
  Option<Absyn.Exp> cnd;
  SCode.Path bc;
  SCode.Visibility v;
  SCode.Mod m;
  Option<SCode.Annotation> a;
  SourceInfo i;
algorithm
  SCode.COMPONENT(n, pr, atr, ts, m, cmt, cnd, i) := inE;
  outE := SCode.COMPONENT(inName, pr, atr, ts, m, cmt, cnd, i);
end setComponentName;

public function isArrayComponent
  input SCode.Element inElement;
  output Boolean outIsArray;
algorithm
  outIsArray := match inElement
    case SCode.COMPONENT(attributes = SCode.ATTR(arrayDims = _ :: _)) then true;
    else false;
  end match;
end isArrayComponent;

public function isEmptyMod
  input SCode.Mod mod;
  output Boolean isEmpty;
algorithm
  isEmpty := match mod
    case SCode.NOMOD() then true;
    else false;
  end match;
end isEmptyMod;

function getConstrainingMod
  input SCode.Element element;
  output SCode.Mod mod;
algorithm
  mod := match element
    case SCode.CLASS(prefixes = SCode.Prefixes.PREFIXES(replaceablePrefix =
      SCode.Replaceable.REPLACEABLE(cc = SOME(SCode.CONSTRAINCLASS(modifier = mod))))) then mod;
    case SCode.CLASS(classDef = SCode.DERIVED(modifications = mod)) then mod;
    case SCode.COMPONENT(prefixes = SCode.Prefixes.PREFIXES(replaceablePrefix =
      SCode.Replaceable.REPLACEABLE(cc = SOME(SCode.CONSTRAINCLASS(modifier = mod))))) then mod;
    case SCode.COMPONENT(modifications = mod) then mod;
    else SCode.NOMOD();
  end match;
end getConstrainingMod;

function isEmptyClassDef
  input SCode.ClassDef cdef;
  output Boolean isEmpty;
algorithm
  isEmpty := match cdef
    case SCode.PARTS()
      then listEmpty(cdef.elementLst) and
           listEmpty(cdef.normalEquationLst) and
           listEmpty(cdef.initialEquationLst) and
           listEmpty(cdef.normalAlgorithmLst) and
           listEmpty(cdef.initialAlgorithmLst) and
           isNone(cdef.externalDecl);

    case SCode.CLASS_EXTENDS() then isEmptyClassDef(cdef.composition);
    case SCode.ENUMERATION() then listEmpty(cdef.enumLst);
    else true;
  end match;
end isEmptyClassDef;

function stripCommentsFromProgram
  "Strips all annotations and/or comments from a program."
  input output SCode.Program program;
  input Boolean stripAnnotations;
  input Boolean stripComments;
algorithm
  program := list(stripCommentsFromElement(e, stripAnnotations, stripComments) for e in program);
end stripCommentsFromProgram;

function stripCommentsFromElement
  input output SCode.Element element;
  input Boolean stripAnn;
  input Boolean stripCmt;
algorithm
  () := match element
    case SCode.EXTENDS()
      algorithm
        if stripAnn then
          element.ann := NONE();
        end if;

        element.modifications := stripCommentsFromMod(element.modifications, stripAnn, stripCmt);
      then
        ();

    case SCode.CLASS()
      algorithm
        element.classDef := stripCommentsFromClassDef(element.classDef, stripAnn, stripCmt);
        element.cmt := stripCommentsFromComment(element.cmt, stripAnn, stripCmt);
      then
        ();

    case SCode.COMPONENT()
      algorithm
        element.modifications := stripCommentsFromMod(element.modifications, stripAnn, stripCmt);
        element.comment := stripCommentsFromComment(element.comment, stripAnn, stripCmt);
      then
        ();

    else ();
  end match;
end stripCommentsFromElement;

function stripCommentsFromMod
  input output SCode.Mod mod;
  input Boolean stripAnn;
  input Boolean stripCmt;
algorithm
  () := match mod
    case SCode.MOD()
      algorithm
        mod.subModLst := list(stripCommentsFromSubMod(m, stripAnn, stripCmt) for m in mod.subModLst);
      then
        ();

    case SCode.REDECL()
      algorithm
        mod.element := stripCommentsFromElement(mod.element, stripAnn, stripCmt);
      then
        ();

    else ();
  end match;
end stripCommentsFromMod;

function stripCommentsFromSubMod
  input output SCode.SubMod submod;
  input Boolean stripAnn;
  input Boolean stripCmt;
algorithm
  submod.mod := stripCommentsFromMod(submod.mod, stripAnn, stripCmt);
end stripCommentsFromSubMod;

function stripCommentsFromClassDef
  input output SCode.ClassDef cdef;
  input Boolean stripAnn;
  input Boolean stripCmt;
algorithm
  cdef := match cdef
    local
      list<SCode.Element> el;
      list<SCode.Equation> eql, ieql;
      list<SCode.AlgorithmSection> alg, ialg;
      Option<SCode.ExternalDecl> ext;

    case SCode.PARTS()
      algorithm
        el := list(stripCommentsFromElement(e, stripAnn, stripCmt) for e in cdef.elementLst);
        eql := list(stripCommentsFromEquation(eq, stripAnn, stripCmt) for eq in cdef.normalEquationLst);
        ieql := list(stripCommentsFromEquation(ieq, stripAnn, stripCmt) for ieq in cdef.initialEquationLst);
        alg := list(stripCommentsFromAlgorithm(a, stripAnn, stripCmt) for a in cdef.normalAlgorithmLst);
        ialg := list(stripCommentsFromAlgorithm(ia, stripAnn, stripCmt) for ia in cdef.initialAlgorithmLst);
        ext := stripCommentsFromExternalDecl(cdef.externalDecl, stripAnn, stripCmt);
      then
        SCode.PARTS(el, eql, ieql, alg, ialg, cdef.constraintLst, cdef.clsattrs, ext);

    case SCode.CLASS_EXTENDS()
      algorithm
        cdef.modifications := stripCommentsFromMod(cdef.modifications, stripAnn, stripCmt);
        cdef.composition := stripCommentsFromClassDef(cdef.composition, stripAnn, stripCmt);
      then
        cdef;

    case SCode.DERIVED()
      algorithm
        cdef.modifications := stripCommentsFromMod(cdef.modifications, stripAnn, stripCmt);
      then
        cdef;

    case SCode.ENUMERATION()
      algorithm
        cdef.enumLst := list(stripCommentsFromEnum(e, stripAnn, stripCmt) for e in cdef.enumLst);
      then
        cdef;

    else cdef;
  end match;
end stripCommentsFromClassDef;

function stripCommentsFromEnum
  input output SCode.Enum enum;
  input Boolean stripAnn;
  input Boolean stripCmt;
algorithm
  enum.comment := stripCommentsFromComment(enum.comment, stripAnn, stripCmt);
end stripCommentsFromEnum;

function stripCommentsFromComment
  input output SCode.Comment cmt;
  input Boolean stripAnn;
  input Boolean stripCmt;
algorithm
  if stripAnn then
    cmt.annotation_ := NONE();
  end if;

  if stripCmt then
    cmt.comment := NONE();
  end if;
end stripCommentsFromComment;

function stripCommentsFromExternalDecl
  input output Option<SCode.ExternalDecl> extDecl;
  input Boolean stripAnn;
  input Boolean stripCmt;
protected
  SCode.ExternalDecl ext_decl;
algorithm
  if isSome(extDecl) and stripAnn then
    SOME(ext_decl) := extDecl;
    ext_decl.annotation_ := NONE();
    extDecl := SOME(ext_decl);
  end if;
end stripCommentsFromExternalDecl;

function stripCommentsFromEquation
  input output SCode.Equation eq;
  input Boolean stripAnn;
  input Boolean stripCmt;
algorithm
  eq.eEquation := stripCommentsFromEEquation(eq.eEquation, stripAnn, stripCmt);
end stripCommentsFromEquation;

function stripCommentsFromEEquation
  input output SCode.EEquation eq;
  input Boolean stripAnn;
  input Boolean stripCmt;
algorithm
  () := match eq
    case SCode.EQ_IF()
      algorithm
        eq.thenBranch := list(
            list(stripCommentsFromEEquation(e, stripAnn, stripCmt) for e in branch)
          for branch in eq.thenBranch);
        eq.elseBranch := list(stripCommentsFromEEquation(e, stripAnn, stripCmt) for e in eq.elseBranch);
        eq.comment := stripCommentsFromComment(eq.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.EQ_EQUALS()
      algorithm
        eq.comment := stripCommentsFromComment(eq.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.EQ_PDE()
      algorithm
        eq.comment := stripCommentsFromComment(eq.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.EQ_CONNECT()
      algorithm
        eq.comment := stripCommentsFromComment(eq.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.EQ_FOR()
      algorithm
        eq.eEquationLst := list(stripCommentsFromEEquation(e, stripAnn, stripCmt) for e in eq.eEquationLst);
        eq.comment := stripCommentsFromComment(eq.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.EQ_WHEN()
      algorithm
        eq.eEquationLst := list(stripCommentsFromEEquation(e, stripAnn, stripCmt) for e in eq.eEquationLst);
        eq.elseBranches := list(stripCommentsFromWhenEqBranch(b, stripAnn, stripCmt) for b in eq.elseBranches);
        eq.comment := stripCommentsFromComment(eq.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.EQ_ASSERT()
      algorithm
        eq.comment := stripCommentsFromComment(eq.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.EQ_TERMINATE()
      algorithm
        eq.comment := stripCommentsFromComment(eq.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.EQ_REINIT()
      algorithm
        eq.comment := stripCommentsFromComment(eq.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.EQ_NORETCALL()
      algorithm
        eq.comment := stripCommentsFromComment(eq.comment, stripAnn, stripCmt);
      then
        ();

  end match;
end stripCommentsFromEEquation;

function stripCommentsFromWhenEqBranch
  input output tuple<Absyn.Exp, list<SCode.EEquation>> branch;
  input Boolean stripAnn;
  input Boolean stripCmt;
protected
  Absyn.Exp cond;
  list<SCode.EEquation> body;
algorithm
  (cond, body) := branch;
  body := list(stripCommentsFromEEquation(e, stripAnn, stripCmt) for e in body);
  branch := (cond, body);
end stripCommentsFromWhenEqBranch;

function stripCommentsFromAlgorithm
  input output SCode.AlgorithmSection alg;
  input Boolean stripAnn;
  input Boolean stripCmt;
algorithm
  alg.statements := list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in alg.statements);
end stripCommentsFromAlgorithm;

function stripCommentsFromStatement
  input output SCode.Statement stmt;
  input Boolean stripAnn;
  input Boolean stripCmt;
algorithm
  () := match stmt
    case SCode.ALG_ASSIGN()
      algorithm
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_IF()
      algorithm
        stmt.trueBranch := list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.trueBranch);
        stmt.elseIfBranch := list(stripCommentsFromStatementBranch(b, stripAnn, stripCmt) for b in stmt.elseIfBranch);
        stmt.elseBranch := list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.elseBranch);
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_FOR()
      algorithm
        stmt.forBody := list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.forBody);
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_PARFOR()
      algorithm
        stmt.parforBody := list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.parforBody);
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_WHILE()
      algorithm
        stmt.whileBody := list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.whileBody);
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_WHEN_A()
      algorithm
        stmt.branches := list(stripCommentsFromStatementBranch(b, stripAnn, stripCmt) for b in stmt.branches);
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.Statement.ALG_ASSERT()
      algorithm
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_TERMINATE()
      algorithm
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_REINIT()
      algorithm
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_NORETCALL()
      algorithm
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_RETURN()
      algorithm
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_BREAK()
      algorithm
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_FAILURE()
      algorithm
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_TRY()
      algorithm
        stmt.body := list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.body);
        stmt.elseBody := list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.elseBody);
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.ALG_CONTINUE()
      algorithm
        stmt.comment := stripCommentsFromComment(stmt.comment, stripAnn, stripCmt);
      then
        ();

  end match;
end stripCommentsFromStatement;

function stripCommentsFromStatementBranch
  input output tuple<Absyn.Exp, list<SCode.Statement>> branch;
  input Boolean stripAnn;
  input Boolean stripCmt;
protected
  Absyn.Exp cond;
  list<SCode.Statement> body;
algorithm
  (cond, body) := branch;
  body := list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in body);
  branch := (cond, body);
end stripCommentsFromStatementBranch;

function checkValidEnumLiteral
  input String inLiteral;
  input SourceInfo inInfo;
algorithm
  if listMember(inLiteral, {"quantity", "min", "max", "start", "fixed"}) then
    Error.addSourceMessage(Error.INVALID_ENUM_LITERAL, {inLiteral}, inInfo);
    fail();
  end if;
end checkValidEnumLiteral;

public function isRedeclareElement
"get the redeclare-as-element elements"
  input SCode.Element element;
  output Boolean isElement;
algorithm
  isElement := match element
    // redeclare-as-element component
    case SCode.COMPONENT(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE()))
      then true;
    // not redeclare class extends
    case SCode.CLASS(classDef = SCode.CLASS_EXTENDS())
      then false;
    // redeclare-as-element class!, not class extends
    case SCode.CLASS(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE()))
      then true;
    else false;
  end match;
end isRedeclareElement;


public function mergeSCodeOptAnn
  input Option<SCode.Annotation> inModOuter;
  input Option<SCode.Annotation> inModInner;
  output Option<SCode.Annotation> outMod;
algorithm
  outMod := match (inModOuter, inModInner)
    local
      SCode.Mod mod1, mod2, mod;

    case (NONE(),_) then inModInner;
    case (_,NONE()) then inModOuter;
    case (SOME(SCode.ANNOTATION(mod1)),SOME(SCode.ANNOTATION(mod2)))
      equation
        mod = mergeSCodeMods(mod1,mod2);
      then SOME(SCode.ANNOTATION(mod));
  end match;
end mergeSCodeOptAnn;

public function mergeSCodeMods
  input SCode.Mod inModOuter;
  input SCode.Mod inModInner;
  output SCode.Mod outMod;
algorithm
  outMod := match (inModOuter, inModInner)
    local
      SCode.Final f1, f2;
      SCode.Each e1, e2;
      list<SCode.SubMod> subMods1, subMods2;
      Option<Absyn.Exp> b1, b2;
      SourceInfo info;

    case (SCode.NOMOD(), _) then inModInner;
    case (_, SCode.NOMOD()) then inModOuter;

    case (SCode.MOD(f1, e1, subMods1, b1, info),
          SCode.MOD(_, _, subMods2, b2, _))
      equation
        subMods2 = listAppend(subMods1, subMods2);
        b1 = if isSome(b1) then b1 else b2;
      then
        SCode.MOD(f1, e1, subMods2, b1, info);

  end match;
end mergeSCodeMods;

function hasNamedExternalCall
  input String name;
  input SCode.ClassDef def;
  output Boolean hasCall;
algorithm
  hasCall := match def
    local
      String fn_name;

    case SCode.PARTS(externalDecl = SOME(SCode.EXTERNALDECL(funcName = SOME(fn_name))))
      then fn_name == name;
    case SCode.CLASS_EXTENDS() then hasNamedExternalCall(name, def.composition);
    else false;
  end match;
end hasNamedExternalCall;

function classDefHasSections
  "Returns true if the class definition directly contains any sections,
   otherwise false."
  input SCode.ClassDef cdef;
  input Boolean checkExternal;
  output Boolean res;
algorithm
  res := match cdef
    case SCode.ClassDef.PARTS()
      then not (listEmpty(cdef.normalEquationLst) and
                listEmpty(cdef.initialEquationLst) and
                listEmpty(cdef.normalAlgorithmLst) and
                listEmpty(cdef.initialAlgorithmLst) and
                (if checkExternal then isNone(cdef.externalDecl) else true));

    case SCode.ClassDef.CLASS_EXTENDS()
      then classDefHasSections(cdef.composition, checkExternal);

    else false;
  end match;
end classDefHasSections;

function mapElements
  "Applies a function to all elements in a list of elements, and recursively to
   all elements in those elements."
  input output list<SCode.Element> elements;
  input Func func;

  partial function Func
    input output SCode.Element element;
  end Func;
algorithm
  elements := list(mapElement(e, func) for e in elements);
end mapElements;

function mapElement
  input output SCode.Element element;
  input Func func;

  partial function Func
    input output SCode.Element element;
  end Func;
protected
  SCode.ClassDef def;
algorithm
  () := match element
    case SCode.Element.CLASS()
      algorithm
        def := mapElementsClassDef(element.classDef, func);

        if not referenceEq(def, element.classDef) then
          element.classDef := def;
        end if;
      then
        ();

    else ();
  end match;

  element := func(element);
end mapElement;

function mapElementsClassDef
  input output SCode.ClassDef classDef;
  input Func func;

  partial function Func
    input output SCode.Element element;
  end Func;
protected
  SCode.ClassDef def;
algorithm
  () := match classDef
    case SCode.ClassDef.PARTS()
      algorithm
        classDef.elementLst := list(mapElement(e, func) for e in classDef.elementLst);
      then
        ();

    case SCode.ClassDef.CLASS_EXTENDS()
      algorithm
        def := mapElementsClassDef(classDef.composition, func);

        if not referenceEq(def, classDef.composition) then
          classDef.composition := def;
        end if;
      then
        ();

    else ();
  end match;
end mapElementsClassDef;

function mapEquationsList
  "Applies a function to all equations in a list of equations, and recursively
   to all equations in those equations."
  input output list<SCode.Equation> eql;
  input Func func;

  partial function Func
    input output SCode.EEquation eq;
  end Func;
algorithm
  eql := list(mapEquations(e, func) for e in eql);
end mapEquationsList;

function mapEquations
  input output SCode.Equation eq;
  input Func func;

  partial function Func
    input output SCode.EEquation eq;
  end Func;
algorithm
  eq.eEquation := mapEEquations(eq.eEquation, func);
end mapEquations;

function mapEEquationsList
  input output list<SCode.EEquation> eql;
  input Func func;

  partial function Func
    input output SCode.EEquation eq;
  end Func;
algorithm
  eql := list(mapEEquations(e, func) for e in eql);
end mapEEquationsList;

function mapEEquations
  input output SCode.EEquation eq;
  input Func func;

  partial function Func
    input output SCode.EEquation eq;
  end Func;
algorithm
  () := match eq
    case SCode.EEquation.EQ_IF()
      algorithm
        eq.thenBranch := list(mapEEquationsList(b, func) for b in eq.thenBranch);
        eq.elseBranch := mapEEquationsList(eq.elseBranch, func);
      then
        ();

    case SCode.EEquation.EQ_FOR()
      algorithm
        eq.eEquationLst := mapEEquationsList(eq.eEquationLst, func);
      then
        ();

    case SCode.EEquation.EQ_WHEN()
      algorithm
        eq.eEquationLst := mapEEquationsList(eq.eEquationLst, func);
        eq.elseBranches := list(
          (Util.tuple21(b), mapEEquationsList(Util.tuple22(b), func)) for b in eq.elseBranches);
      then
        ();

    else ();
  end match;

  eq := func(eq);
end mapEEquations;

function mapEquationExps
  "Applies a function to all expressions in an equation."
  input output SCode.Equation eq;
  input Func func;

  partial function Func
    input output Absyn.Exp exp;
  end Func;
algorithm
  eq.eEquation := mapEEquationExps(eq.eEquation, func);
end mapEquationExps;

function mapEEquationExps
  input output SCode.EEquation eq;
  input Func func;

  partial function Func
    input output Absyn.Exp exp;
  end Func;
algorithm
  () := match eq
    case SCode.EEquation.EQ_IF()
      algorithm
        eq.condition := list(func(e) for e in eq.condition);
      then
        ();

    case SCode.EEquation.EQ_EQUALS()
      algorithm
        eq.expLeft := func(eq.expLeft);
        eq.expRight := func(eq.expRight);
      then
        ();

    case SCode.EEquation.EQ_PDE()
      algorithm
        eq.expLeft := func(eq.expLeft);
        eq.expRight := func(eq.expRight);
        eq.domain := AbsynUtil.mapCrefExps(eq.domain, func);
      then
        ();

    case SCode.EEquation.EQ_CONNECT()
      algorithm
        eq.crefLeft := AbsynUtil.mapCrefExps(eq.crefLeft, func);
        eq.crefRight := AbsynUtil.mapCrefExps(eq.crefRight, func);
      then
        ();

    case SCode.EEquation.EQ_FOR()
      algorithm
        if isSome(eq.range) then
          eq.range := SOME(func(Util.getOption(eq.range)));
        end if;
      then
        ();

    case SCode.EEquation.EQ_WHEN()
      algorithm
        eq.condition := func(eq.condition);
        eq.elseBranches := list(Util.applyTuple21(b, func) for b in eq.elseBranches);
      then
        ();

    case SCode.EEquation.EQ_ASSERT()
      algorithm
        eq.condition := func(eq.condition);
        eq.message := func(eq.message);
        eq.level := func(eq.level);
      then
        ();

    case SCode.EEquation.EQ_TERMINATE()
      algorithm
        eq.message := func(eq.message);
      then
        ();

    case SCode.EEquation.EQ_REINIT()
      algorithm
        eq.cref := func(eq.cref);
        eq.expReinit := func(eq.expReinit);
      then
        ();

    case SCode.EEquation.EQ_NORETCALL()
      algorithm
        eq.exp := func(eq.exp);
      then
        ();

  end match;
end mapEEquationExps;

function mapAlgorithmStatements
  "Applies a function to all statements in algorithm section, and recursively
   to all statements in those statements."
  input output SCode.AlgorithmSection alg;
  input Func func;

  partial function Func
    input output SCode.Statement stmt;
  end Func;
algorithm
  alg.statements := mapStatementsList(alg.statements, func);
end mapAlgorithmStatements;

function mapStatementsList
  input output list<SCode.Statement> statements;
  input Func func;

  partial function Func
    input output SCode.Statement stmt;
  end Func;
algorithm
  statements := list(mapStatements(s, func) for s in statements);
end mapStatementsList;

function mapStatements
  input output SCode.Statement stmt;
  input Func func;

  partial function Func
    input output SCode.Statement stmt;
  end Func;
algorithm
  () := match stmt
    case SCode.Statement.ALG_IF()
      algorithm
        stmt.trueBranch := mapStatementsList(stmt.trueBranch, func);
        stmt.elseIfBranch :=
          list((Util.tuple21(b), mapStatementsList(Util.tuple22(b), func)) for b in stmt.elseIfBranch);
        stmt.elseBranch := mapStatementsList(stmt.elseBranch, func);
      then
        ();

    case SCode.Statement.ALG_FOR()
      algorithm
        stmt.forBody := mapStatementsList(stmt.forBody, func);
      then
        ();

    case SCode.Statement.ALG_PARFOR()
      algorithm
        stmt.parforBody := mapStatementsList(stmt.parforBody, func);
      then
        ();

    case SCode.Statement.ALG_WHILE()
      algorithm
        stmt.whileBody := mapStatementsList(stmt.whileBody, func);
      then
        ();

    case SCode.Statement.ALG_WHEN_A()
      algorithm
        stmt.branches :=
          list((Util.tuple21(b), mapStatementsList(Util.tuple22(b), func)) for b in stmt.branches);
      then
        ();

    case SCode.Statement.ALG_FAILURE()
      algorithm
        stmt.stmts := mapStatementsList(stmt.stmts, func);
      then
        ();

    case SCode.Statement.ALG_TRY()
      algorithm
        stmt.body := mapStatementsList(stmt.body, func);
        stmt.elseBody := mapStatementsList(stmt.body, func);
      then
        ();

    else ();
  end match;

  stmt := func(stmt);
end mapStatements;

function mapStatementExps
  "Applies a function to all expressions in a statement."
  input output SCode.Statement stmt;
  input Func func;

  partial function Func
    input output Absyn.Exp exp;
  end Func;
algorithm
  () := match stmt
    case SCode.Statement.ALG_ASSIGN()
      algorithm
        stmt.assignComponent := func(stmt.assignComponent);
        stmt.value := func(stmt.value);
      then
        ();

    case SCode.Statement.ALG_IF()
      algorithm
        stmt.boolExpr := func(stmt.boolExpr);
        stmt.elseIfBranch := list((func(Util.tuple21(b)), Util.tuple22(b)) for b in stmt.elseIfBranch);
      then
        ();

    case SCode.Statement.ALG_FOR()
      algorithm
        if isSome(stmt.range) then
          stmt.range := SOME(func(Util.getOption(stmt.range)));
        end if;
      then
        ();

    case SCode.Statement.ALG_PARFOR()
      algorithm
        if isSome(stmt.range) then
          stmt.range := SOME(func(Util.getOption(stmt.range)));
        end if;
      then
        ();

    case SCode.Statement.ALG_WHILE()
      algorithm
        stmt.boolExpr := func(stmt.boolExpr);
      then
        ();

    case SCode.Statement.ALG_WHEN_A()
      algorithm
        stmt.branches := list((func(Util.tuple21(b)), Util.tuple22(b)) for b in stmt.branches);
      then
        ();

    case SCode.Statement.ALG_ASSERT()
      algorithm
        stmt.condition := func(stmt.condition);
        stmt.message := func(stmt.message);
        stmt.level := func(stmt.level);
      then
        ();

    case SCode.Statement.ALG_TERMINATE()
      algorithm
        stmt.message := func(stmt.message);
      then
        ();

    case SCode.Statement.ALG_REINIT()
      algorithm
        stmt.cref := func(stmt.cref);
        stmt.newValue := func(stmt.newValue);
      then
        ();

    case SCode.Statement.ALG_NORETCALL()
      algorithm
        stmt.exp := func(stmt.exp);
      then
        ();

    else ();
  end match;
end mapStatementExps;

function lookupModInMod
  "Looks up a modifier with the given name in the given modifier, or returns
   NOMOD() if no modifier is found."
  input String name;
  input SCode.Mod mod;
  output SCode.Mod outMod;
algorithm
  outMod := match mod
    case SCode.Mod.MOD()
      algorithm
        for m in mod.subModLst loop
          if m.ident == name then
            outMod := m.mod;
            return;
          end if;
        end for;
      then
        SCode.Mod.NOMOD();

    else SCode.Mod.NOMOD();
  end match;
end lookupModInMod;

annotation(__OpenModelica_Interface="frontend");
end SCodeUtil;

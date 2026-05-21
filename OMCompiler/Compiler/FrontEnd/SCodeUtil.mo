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
  input output SCode.Mod mod;
algorithm
  () := match mod
    case SCode.MOD()
      algorithm
        mod.subModLst := {};
      then
        ();

    else ();
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
      algorithm
        elt := getElementNamedFromElts(id, elts);
      then
        elt;

    /* adrpo: handle also the case model extends X then X; */
    case (id,SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = SCode.PARTS(elementLst = elts))))
      algorithm
        elt := getElementNamedFromElts(id, elts);
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
      algorithm
        true := stringEq(id1, id2);
      then
        comp;

    case (id2,(SCode.COMPONENT(name = id1) :: xs))
      algorithm
        false := stringEq(id1, id2);
        elt := getElementNamedFromElts(id2, xs);
      then
        elt;

    case (id2,(SCode.CLASS(name = id1) :: xs))
      algorithm
        false := stringEq(id1, id2);
        elt := getElementNamedFromElts(id2, xs);
      then
        elt;

    case (id2,(SCode.EXTENDS() :: xs))
      algorithm
        elt := getElementNamedFromElts(id2, xs);
      then
        elt;

    case (id2,((cdef as SCode.CLASS(name = id1)) :: _))
      algorithm
        true := stringEq(id1, id2);
      then
        cdef;

    // Try next.
    case (id2, _:: xs)
      algorithm
        elt := getElementNamedFromElts(id2, xs);
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
      algorithm
        res := listLength(elts);
      then
        res;

    /* adrpo: handle also model extends X ... parts ... end X; */
    case SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = SCode.PARTS(elementLst = elts)))
      algorithm
        res := listLength(elts);
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
      algorithm
        res := componentNamesFromElts(elts);
      then
        res;

    /* adrpo: handle also the case model extends X end X;*/
    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = SCode.PARTS(elementLst = elts))))
      algorithm
        res := componentNamesFromElts(elts);
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
    else Absyn.dummyInfo;

  end match;
end elementInfo;

function setElementName
  input output SCode.Element e;
  input String name;
algorithm
  () := match e
    case SCode.CLASS()      algorithm e.name := name; then ();
    case SCode.COMPONENT()  algorithm e.name := name; then ();
    case SCode.DEFINEUNIT() algorithm e.name := name; then ();
    else ();
  end match;
end setElementName;

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
  input SCode.Element element;
  output String name;
  output SourceInfo info;
algorithm
  (name, info) := match element
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
  input output SCode.Element element;
  input String name;
algorithm
  () := match element
    case SCode.CLASS()     algorithm element.name := name; then ();
    case SCode.COMPONENT() algorithm element.name := name; then ();
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

public function isEnumeration
  input SCode.Element el;
  output Boolean res;
algorithm
  res := match el
    case SCode.CLASS(restriction = SCode.R_ENUMERATION()) then true;
    else false;
  end match;
end isEnumeration;

public function className
  "Returns the class name of a Class."
  input SCode.Element inClass;
  output String outName;
algorithm
  SCode.CLASS(name = outName) := inClass;
end className;

public function classSetPartial
  "Sets the partial attribute of a class element."
  input output SCode.Element cls;
  input SCode.Partial inPartial;
algorithm
  () := match cls
    case SCode.CLASS()
      algorithm
        cls.partialPrefix := inPartial;
      then
        ();
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
   equal := matchcontinue (element1, element2)
    case (SCode.CLASS(), SCode.CLASS())
       then stringEq(element1.name, element2.name) and
            prefixesEqual(element1.prefixes, element2.prefixes) and
            valueEq(element1.encapsulatedPrefix, element2.encapsulatedPrefix) and
            valueEq(element1.partialPrefix, element2.partialPrefix) and
            restrictionEqual(element1.restriction, element2.restriction) and
            classDefEqual(element1.classDef, element2.classDef);

    case (SCode.COMPONENT(), SCode.COMPONENT())
       then stringEq(element1.name, element2.name) and
            prefixesEqual(element1.prefixes, element2.prefixes) and
            attributesEqual(element1.attributes, element2.attributes) and
            modEqual(element1.modifications, element2.modifications) and
            AbsynUtil.typeSpecEqual(element1.typeSpec, element2.typeSpec) and
            valueEq(element1.condition, element2.condition);

     case (SCode.EXTENDS(), SCode.EXTENDS())
       then AbsynUtil.pathEqual(element1.baseClassPath, element2.baseClassPath) and
            modEqual(element1.modifications, element2.modifications);

    case (SCode.IMPORT(), SCode.IMPORT())
      then AbsynUtil.importEqual(element1.imp, element2.imp);

     case (SCode.DEFINEUNIT(), SCode.DEFINEUNIT())
       then stringEq(element1.name, element2.name) and
            valueEq(element1.exp, element2.exp) and
            valueEq(element1.weight, element2.weight);

     // otherwise false
     else false;
   end matchcontinue;
 end elementEqual;

// stefan
public function annotationEqual
"returns true if 2 annotations are equal"
  input SCode.Annotation annotation1;
  input SCode.Annotation annotation2;
  output Boolean equal = modEqual(annotation1.modification, annotation2.modification);
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
    case (SCode.FR_NORMAL_FUNCTION(),SCode.FR_NORMAL_FUNCTION())
      then AbsynUtil.purityEqual(funcRestr1.purity, funcRestr2.purity);
    case (SCode.FR_EXTERNAL_FUNCTION(),SCode.FR_EXTERNAL_FUNCTION())
      then AbsynUtil.purityEqual(funcRestr1.purity, funcRestr2.purity);
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
  output Boolean isEqual = e1.literal == e2.literal;
end enumEqual;

protected function classDefEqual
"Returns true if Two ClassDef's are equal"
  input SCode.ClassDef cdef1;
  input SCode.ClassDef cdef2;
  output Boolean equal;
algorithm
  equal := match(cdef1,cdef2)
    case (SCode.PARTS(), SCode.PARTS())
      then List.isEqualOnTrue(cdef1.elementLst, cdef2.elementLst, elementEqual) and
           List.isEqualOnTrue(cdef1.normalEquationLst, cdef2.normalEquationLst, equationEqual) and
           List.isEqualOnTrue(cdef1.initialEquationLst, cdef2.initialEquationLst, equationEqual) and
           List.isEqualOnTrue(cdef1.normalAlgorithmLst, cdef2.normalAlgorithmLst, algorithmEqual) and
           List.isEqualOnTrue(cdef1.initialAlgorithmLst, cdef2.initialAlgorithmLst, algorithmEqual);

    case (SCode.DERIVED(), SCode.DERIVED())
      then AbsynUtil.typeSpecEqual(cdef1.typeSpec, cdef2.typeSpec) and
           modEqual(cdef1.modifications, cdef2.modifications) and
           attributesEqual(cdef1.attributes, cdef2.attributes);

    case (SCode.ENUMERATION(), SCode.ENUMERATION())
      then List.isEqualOnTrue(cdef1.enumLst, cdef2.enumLst, enumEqual);

    case (SCode.CLASS_EXTENDS(), SCode.CLASS_EXTENDS())
      then modEqual(cdef1.modifications, cdef2.modifications) and
           classDefEqual(cdef1.composition, cdef2.composition);

    case (SCode.PDER(), SCode.PDER())
      then List.isEqualOnTrue(cdef1.derivedVariables, cdef2.derivedVariables, stringEq);

    else false;
  end match;
end classDefEqual;

protected function arraydimOptEqual
"Returns true if two Option<ArrayDim> are equal"
   input Option<Absyn.ArrayDim> adopt1;
   input Option<Absyn.ArrayDim> adopt2;
   output Boolean equal;
 algorithm
  equal := match(adopt1,adopt2)
    local
      list<Absyn.Subscript> lst1,lst2;
    case (NONE(), NONE()) then true;
    case (SOME(lst1), SOME(lst2)) then List.isEqualOnTrue(lst1,lst2,subscriptEqual);
    else false;
  end match;
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
  equal := List.isEqualOnTrue(alg1.statements, alg2.statements, statementEqual);
end algorithmEqual;

protected function statementEqual
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
      algorithm
        b1 := AbsynUtil.crefEqual(cr1,cr2);
        b2 := AbsynUtil.expEqual(e1,e2);
        equal := boolAnd(b1,b2);
      then equal;
    case(SCode.ALG_ASSIGN(assignComponent = e11 as Absyn.TUPLE(_), value = e12),SCode.ALG_ASSIGN(assignComponent = e21 as Absyn.TUPLE(_), value = e22))
      algorithm
        b1 := AbsynUtil.expEqual(e11,e21);
        b2 := AbsynUtil.expEqual(e12,e22);
        equal := boolAnd(b1,b2);
      then equal;
    // base it on equality for now as the ones below are not implemented!
    case(a1, a2)
      algorithm
        Absyn.ALGORITHMITEM(algorithm_ = alg1) := statementToAlgorithmItem(a1);
        Absyn.ALGORITHMITEM(algorithm_ = alg2) := statementToAlgorithmItem(a2);
        // Don't compare comments and line numbers
      then valueEq(alg1, alg2);
    // maybe replace failure/equality with these:
    //case(Absyn.ALG_IF(_,_,_,_),Absyn.ALG_IF(_,_,_,_)) then false; // TODO: SCode.ALG_IF
    //case (Absyn.ALG_FOR(_,_),Absyn.ALG_FOR(_,_)) then false; // TODO: SCode.ALG_FOR
    //case (Absyn.ALG_WHILE(_,_),Absyn.ALG_WHILE(_,_)) then false; // TODO: SCode.ALG_WHILE
    //case(Absyn.ALG_WHEN_A(_,_,_),Absyn.ALG_WHEN_A(_,_,_)) then false; //TODO: SCode.ALG_WHILE
    //case (Absyn.ALG_NORETCALL(_,_),Absyn.ALG_NORETCALL(_,_)) then false; //TODO: SCode.ALG_NORETCALL
    else false;
  end matchcontinue;
end statementEqual;

protected function equationEqual
  "Returns true if two equations are equal."
  input SCode.Equation eq1;
  input SCode.Equation eq2;
  output Boolean equal;
algorithm
  equal := matchcontinue(eq1,eq2)
    local
      list<list<SCode.Equation>> tb1,tb2;
      Absyn.Exp cond1,cond2;
      list<Absyn.Exp> ifcond1,ifcond2;
      Absyn.Exp e11,e12,e21,e22,exp1,exp2,c1,c2,m1,m2,e1,e2;
      Absyn.ComponentRef cr11,cr12,cr21,cr22,cr1,cr2;
      Absyn.Ident id1,id2;
      list<SCode.Equation> fb1,fb2,eql1,eql2,elst1,elst2;

    case (SCode.EQ_IF(condition = ifcond1, thenBranch = tb1, elseBranch = fb1),SCode.EQ_IF(condition = ifcond2, thenBranch = tb2, elseBranch = fb2))
      algorithm
        true := equationEqual2(tb1,tb2);
        true := List.isEqualOnTrue(fb1,fb2,equationEqual);
        true := List.isEqualOnTrue(ifcond1,ifcond2,AbsynUtil.expEqual);
      then
        true;

    case(SCode.EQ_EQUALS(expLeft = e11, expRight = e12),SCode.EQ_EQUALS(expLeft = e21, expRight = e22))
      algorithm
        true := AbsynUtil.expEqual(e11,e21);
        true := AbsynUtil.expEqual(e12,e22);
      then
        true;

    case(SCode.EQ_PDE(expLeft = e11, expRight = e12, domain = cr1),SCode.EQ_PDE(expLeft = e21, expRight = e22, domain = cr2))
      algorithm
        true := AbsynUtil.expEqual(e11,e21);
        true := AbsynUtil.expEqual(e12,e22);
        true := AbsynUtil.crefEqual(cr1,cr2);
      then
        true;

    case(SCode.EQ_CONNECT(crefLeft = cr11, crefRight = cr12),SCode.EQ_CONNECT(crefLeft = cr21, crefRight = cr22))
      algorithm
        true := AbsynUtil.crefEqual(cr11,cr21);
        true := AbsynUtil.crefEqual(cr12,cr22);
      then
        true;

    case (SCode.EQ_FOR(index = id1, range = SOME(exp1), eEquationLst = eql1),SCode.EQ_FOR(index = id2, range = SOME(exp2), eEquationLst = eql2))
      algorithm
        true := List.isEqualOnTrue(eql1,eql2,equationEqual);
        true := AbsynUtil.expEqual(exp1,exp2);
        true := stringEq(id1,id2);
      then
        true;

    case (SCode.EQ_FOR(index = id1, range = NONE(), eEquationLst = eql1),SCode.EQ_FOR(index = id2, range = NONE(), eEquationLst = eql2))
      algorithm
        true := List.isEqualOnTrue(eql1,eql2,equationEqual);
        true := stringEq(id1,id2);
      then
        true;

    case (SCode.EQ_WHEN(condition = cond1, eEquationLst = elst1),SCode.EQ_WHEN(condition = cond2, eEquationLst = elst2)) // TODO: elsewhen not checked yet.
      algorithm
        true := List.isEqualOnTrue(elst1,elst2,equationEqual);
        true := AbsynUtil.expEqual(cond1,cond2);
      then
        true;

    case (SCode.EQ_ASSERT(condition = c1, message = m1),SCode.EQ_ASSERT(condition = c2, message = m2))
      algorithm
        true := AbsynUtil.expEqual(c1,c2);
        true := AbsynUtil.expEqual(m1,m2);
      then
        true;

    case (SCode.EQ_REINIT(), SCode.EQ_REINIT())
      algorithm
        true := AbsynUtil.expEqual(eq1.cref, eq2.cref);
        true := AbsynUtil.expEqual(eq1.expReinit, eq2.expReinit);
      then
        true;

    case (SCode.EQ_NORETCALL(exp = e1), SCode.EQ_NORETCALL(exp = e2))
      algorithm
        true := AbsynUtil.expEqual(e1,e2);
      then
        true;

    // otherwise false
    else false;
  end matchcontinue;
end equationEqual;

protected function equationEqual2
"Author BZ
 Helper function for equationEqual2, does compare list<list<equation>> (else ifs in ifequations.)"
  input list<list<SCode.Equation>> inTb1;
  input list<list<SCode.Equation>> inTb2;
  output Boolean bOut;
algorithm
  bOut := matchcontinue(inTb1,inTb2)
    local
      list<SCode.Equation> tb_1,tb_2;
      list<list<SCode.Equation>> tb1,tb2;

    case({},{}) then true;
    case(_,{}) then false;
    case({},_) then false;
    case(tb_1::tb1,tb_2::tb2)
      algorithm
        true := List.isEqualOnTrue(tb_1,tb_2,equationEqual);
        true := equationEqual2(tb1,tb2);
      then
        true;
    case(_::_,_::_) then false;

  end matchcontinue;
end equationEqual2;

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
      algorithm
        true := valueEq(f1,f2);
        true := eachEqual(each1,each2);
        true := subModsEqual(submodlst1,submodlst2);
        true := AbsynUtil.expEqual(e1,e2);
      then
        true;

    case (SCode.MOD(f1,each1,submodlst1,NONE(),_),SCode.MOD(f2,each2,submodlst2,NONE(),_))
      algorithm
        true := valueEq(f1,f2);
        true := eachEqual(each1,each2);
        true := subModsEqual(submodlst1,submodlst2);
      then
        true;

    case (SCode.NOMOD(),SCode.NOMOD()) then true;

    case (SCode.REDECL(f1,each1,elt1),SCode.REDECL(f2,each2,elt2))
      algorithm
        true := valueEq(f1,f2);
        true := eachEqual(each1,each2);
        true := elementEqual(elt1, elt2);
      then
        true;

    case (SCode.BREAK_COMPONENT(), SCode.BREAK_COMPONENT()) then true;

    case (SCode.BREAK_CONNECT(), SCode.BREAK_CONNECT())
      then AbsynUtil.crefEqual(mod1.lhs, mod2.lhs) and AbsynUtil.crefEqual(mod1.rhs, mod2.lhs);

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
        algorithm
          true := stringEq(id1,id2);
          true := modEqual(mod1,mod2);
          true := subModsEqual(subModLst1,subModLst2);
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
      algorithm
        true := AbsynUtil.expEqual(e1,e2);
        true := subscriptsEqual(ss1,ss2);
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
  equal := arrayDimEqual(attr1.arrayDims, attr2.arrayDims) and
           valueEq(attr1.connectorType, attr2.connectorType) and
           parallelismEqual(attr1.parallelism, attr2.parallelism) and
           variabilityEqual(attr1.variability, attr2.variability) and
           AbsynUtil.directionEqual(attr1.direction, attr2.direction) and
           AbsynUtil.isFieldEqual(attr1.isField, attr2.isField);
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
       algorithm
         true := arrayDimEqual(ad1,ad2);
       then
         true;

     case (Absyn.SUBSCRIPT(e1)::ad1,Absyn.SUBSCRIPT(e2)::ad2)
       algorithm
         true := AbsynUtil.expEqual(e1,e2);
         true :=  arrayDimEqual(ad1,ad2);
       then
         true;

     else false;
   end matchcontinue;
end arrayDimEqual;

public function setClassRestriction "Sets the restriction of a SCode Class"
  input SCode.Restriction r;
  input output SCode.Element cl;
algorithm
  () := match cl
    case SCode.CLASS()
      algorithm
        cl.restriction := r;
      then
        ();
  end match;
end setClassRestriction;

public function setClassName "Sets the name of a SCode Class"
  input SCode.Ident name;
  input output SCode.Element cl;
algorithm
  () := match cl
    case SCode.CLASS()
      algorithm
        if name <> cl.name then
          cl.name := name;
        end if;
      then
        ();
  end match;
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
  input output SCode.Element cl;
algorithm
  () := match cl
    case SCode.CLASS()
      algorithm
        if not valueEq(partialPrefix, cl.partialPrefix) then
          cl.partialPrefix := partialPrefix;
        end if;
      then
        ();
  end match;
end setClassPartialPrefix;

public function findIteratorIndexedCrefsInEquations
  input list<SCode.Equation> inEqs;
  input String inIterator;
  input list<AbsynUtil.IteratorIndexedCref> inCrefs = {};
  output list<AbsynUtil.IteratorIndexedCref> outCrefs;
algorithm
  outCrefs := List.fold1(inEqs, findIteratorIndexedCrefsInEquation, inIterator,
    inCrefs);
end findIteratorIndexedCrefsInEquations;

public function findIteratorIndexedCrefsInEquation
  input SCode.Equation inEq;
  input String inIterator;
  input list<AbsynUtil.IteratorIndexedCref> inCrefs = {};
  output list<AbsynUtil.IteratorIndexedCref> outCrefs;
algorithm
  outCrefs := foldEquationsExps(inEq,
    function AbsynUtil.findIteratorIndexedCrefs(inIterator = inIterator), inCrefs);
end findIteratorIndexedCrefsInEquation;

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
      algorithm
        (comps, names) := filterComponents(elts);
      then (comps,names);
    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = SCode.PARTS(elementLst = elts))))
      algorithm
        (comps, names) := filterComponents(elts);
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
      algorithm
        algs1 := List.map(trueBranch,statementToAlgorithmItem);

        conditions := List.map(branches, Util.tuple21);
        stmtsList := List.map(branches, Util.tuple22);
        algsLst := List.mapList(stmtsList, statementToAlgorithmItem);
        abranches := List.zip(conditions,algsLst);

        algs2 := List.map(elseBranch,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_IF(boolExpr,algs1,abranches,algs2),NONE(),info);

    case SCode.ALG_FOR(iterator,range,body,_,info)
      algorithm
        algs1 := List.map(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_FOR({Absyn.ITERATOR(iterator,NONE(),range)},algs1),NONE(),info);

    case SCode.ALG_PARFOR(iterator,range,body,_,info)
      algorithm
        algs1 := List.map(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_PARFOR({Absyn.ITERATOR(iterator,NONE(),range)},algs1),NONE(),info);

    case SCode.ALG_WHILE(boolExpr,body,_,info)
      algorithm
        algs1 := List.map(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_WHILE(boolExpr,algs1),NONE(),info);

    case SCode.ALG_WHEN_A(branches,_,info)
      algorithm
        (boolExpr::conditions) := List.map(branches, Util.tuple21);
        stmtsList := List.map(branches, Util.tuple22);
        (algs1::algsLst) := List.mapList(stmtsList, statementToAlgorithmItem);
        abranches := List.zip(conditions,algsLst);
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
      algorithm
        algs1 := List.map(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_FAILURE(algs1),NONE(),info);
  end match;
end statementToAlgorithmItem;

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

public function isImport
  input SCode.Element element;
  output Boolean isImport;
algorithm
  isImport := match element
    case SCode.IMPORT() then true;
    else false;
  end match;
end isImport;

public function foldEquations<ArgT>
  "Calls the given function on the equation and all its subequations, and
   updates the argument for each call."
  input SCode.Equation inEquation;
  input FoldFunc inFunc;
  input ArgT inArg;
  output ArgT outArg;

  partial function FoldFunc
    input SCode.Equation inEquation;
    input ArgT inArg;
    output ArgT outArg;
  end FoldFunc;
algorithm
  outArg := inFunc(inEquation, inArg);

  outArg := match inEquation
    local
      list<SCode.Equation> eql;

    case SCode.EQ_IF()
      algorithm
        outArg := List.foldList(inEquation.thenBranch, function foldEquations(inFunc = inFunc), outArg);
      then
        List.fold1(inEquation.elseBranch, foldEquations, inFunc, outArg);

    case SCode.EQ_FOR()
      then List.fold1(inEquation.eEquationLst, foldEquations, inFunc, outArg);

    case SCode.EQ_WHEN()
      algorithm
        outArg := List.fold1(inEquation.eEquationLst, foldEquations, inFunc, outArg);

        for branch in inEquation.elseBranches loop
          (_, eql) := branch;
          outArg := List.fold1(eql, foldEquations, inFunc, outArg);
        end for;
      then
        outArg;

  end match;
end foldEquations;

public function foldEquationsExps<ArgT>
  "Calls the given function on all expressions inside the equation, and updates
   the argument for each call."
  input SCode.Equation inEquation;
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
      list<SCode.Equation> eql;

    case SCode.EQ_IF()
      algorithm
        outArg := List.fold(inEquation.condition, inFunc, outArg);
        outArg := List.foldList(inEquation.thenBranch, function foldEquationsExps(inFunc = inFunc), outArg);
      then
        List.fold1(inEquation.elseBranch, foldEquationsExps, inFunc, outArg);

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
        List.fold1(inEquation.eEquationLst, foldEquationsExps, inFunc, outArg);

    case SCode.EQ_WHEN()
      algorithm
        outArg := List.fold1(inEquation.eEquationLst, foldEquationsExps, inFunc, outArg);

        for branch in inEquation.elseBranches loop
          (exp, eql) := branch;
          outArg := inFunc(exp, outArg);
          outArg := List.fold1(eql, foldEquationsExps, inFunc, outArg);
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
end foldEquationsExps;

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

public function mapFoldEquationsList<ArgT>
  "Traverses a list of SCode.Equations, calling mapFoldEquations on each SCode.Equation
  in the list."
  input output list<SCode.Equation> eql;
  input TraverseFunc traverser;
  input output ArgT arg;

  partial function TraverseFunc
    input output SCode.Equation eq;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (eql, arg) := List.mapFold(eql, function mapFoldEquations(traverser = traverser), arg);
end mapFoldEquationsList;

public function mapFoldEquations<ArgT>
  "Traverses an SCode.Equation. For each SCode.Equation it finds it calls the given
  function with the SCode.Equation and an extra argument which is passed along."
  input output SCode.Equation eq;
  input TraverseFunc traverser;
  input output ArgT arg;

  partial function TraverseFunc
    input output SCode.Equation eq;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (eq, arg) := traverser(eq, arg);

  (eq, arg) := match eq
    local
      Absyn.Exp e1;
      list<Absyn.Exp> expl1;
      list<list<SCode.Equation>> then_branch;
      list<SCode.Equation> else_branch, eql;
      list<tuple<Absyn.Exp, list<SCode.Equation>>> else_when;
      SCode.Comment comment;
      SourceInfo info;

    case SCode.EQ_IF(expl1, then_branch, else_branch, comment, info)
      algorithm
        (then_branch, arg) := List.mapFold(then_branch,
          function mapFoldEquationsList(traverser = traverser), arg);
        (else_branch, arg) := mapFoldEquationsList(else_branch, traverser, arg);
      then
        (SCode.EQ_IF(expl1, then_branch, else_branch, comment, info), arg);

    case SCode.EQ_FOR()
      algorithm
        (eql, arg) := mapFoldEquationsList(eq.eEquationLst, traverser, arg);
        eq.eEquationLst := eql;
      then
        (eq, arg);

    case SCode.EQ_WHEN(e1, eql, else_when, comment, info)
      algorithm
        (eql, arg) := mapFoldEquationsList(eql, traverser, arg);
        (else_when, arg) := List.mapFold(else_when,
           function mapFoldElseWhenEquations(traverser = traverser), arg);
      then
        (SCode.EQ_WHEN(e1, eql, else_when, comment, info), arg);

    else (eq, arg);
  end match;
end mapFoldEquations;

protected function mapFoldElseWhenEquations<ArgT>
  "Traverses all SCode.Equations in an else when branch, calling the given function
  on each SCode.Equation."
  input output tuple<Absyn.Exp, list<SCode.Equation>> elseWhen;
  input TraverseFunc traverser;
  input output ArgT arg;

  partial function TraverseFunc
    input output SCode.Equation eq;
    input output ArgT arg;
  end TraverseFunc;

protected
  Absyn.Exp exp;
  list<SCode.Equation> eql;
algorithm
  (exp, eql) := elseWhen;
  (eql, arg) := mapFoldEquationsList(eql, traverser, arg);
  elseWhen := (exp, eql);
end mapFoldElseWhenEquations;

public function mapFoldEquationListExps<ArgT>
  "Traverses a list of SCode.Equations, calling the given function on each Absyn.Exp
  it encounters."
  input list<SCode.Equation> inEquations;
  input TraverseFunc traverser;
  input Argument inArg;
  output list<SCode.Equation> outEquations;
  output Argument outArg;

  partial function TraverseFunc
    input output Absyn.Exp exp;
    input output ArgT arg;
  end TraverseFunc;
algorithm
  (outEquations, outArg) := List.map1Fold(inEquations, mapFoldEquationExps, traverser, inArg);
end mapFoldEquationListExps;

public function mapFoldEquationExps<ArgT>
  "Traverses an SCode.Equation, calling the given function on each Absyn.Exp it
  encounters. This funcion is intended to be used together with
  mapFoldEquations, and does NOT descend into sub-Equations."
  input output SCode.Equation eq;
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
      list<list<SCode.Equation>> then_branch;
      list<SCode.Equation> else_branch, eql;
      list<tuple<Absyn.Exp, list<SCode.Equation>>> else_when;
      SCode.Comment comment;
      SourceInfo info;
      Absyn.ComponentRef cr1, cr2, domain;
      SCode.Ident index;

    case SCode.EQ_IF(expl1, then_branch, else_branch, comment, info)
      algorithm
        (expl1, arg) := AbsynUtil.traverseExpList(expl1, traverser, arg);
      then
        (SCode.EQ_IF(expl1, then_branch, else_branch, comment, info), arg);

    case SCode.EQ_EQUALS(e1, e2, comment, info)
      algorithm
        (e1, arg) := traverser(e1, arg);
        (e2, arg) := traverser(e2, arg);
      then
        (SCode.EQ_EQUALS(e1, e2, comment, info), arg);

    case SCode.EQ_PDE(e1, e2, domain, comment, info)
      algorithm
        (e1, arg) := traverser(e1, arg);
        (e2, arg) := traverser(e2, arg);
      then
        (SCode.EQ_PDE(e1, e2, domain, comment, info), arg);

    case SCode.EQ_CONNECT(cr1, cr2, comment, info)
      algorithm
        (cr1, arg) := mapFoldComponentRefExps(cr1, traverser, arg);
        (cr2, arg) := mapFoldComponentRefExps(cr2, traverser, arg);
      then
        (SCode.EQ_CONNECT(cr1, cr2, comment, info), arg);

    case SCode.EQ_FOR(index, SOME(e1), eql, comment, info)
      algorithm
        (e1, arg) := traverser(e1, arg);
      then
        (SCode.EQ_FOR(index, SOME(e1), eql, comment, info), arg);

    case SCode.EQ_WHEN(e1, eql, else_when, comment, info)
      algorithm
        (e1, arg) := traverser(e1, arg);
        (else_when, arg) := List.map1Fold(else_when, mapFoldElseWhenExps, traverser, arg);
      then
        (SCode.EQ_WHEN(e1, eql, else_when, comment, info), arg);

    case SCode.EQ_ASSERT(e1, e2, e3, comment, info)
      algorithm
        (e1, arg) := traverser(e1, arg);
        (e2, arg) := traverser(e2, arg);
        (e3, arg) := traverser(e3, arg);
      then
        (SCode.EQ_ASSERT(e1, e2, e3, comment, info), arg);

    case SCode.EQ_TERMINATE(e1, comment, info)
      algorithm
        (e1, arg) := traverser(e1, arg);
      then
        (SCode.EQ_TERMINATE(e1, comment, info), arg);

    case SCode.EQ_REINIT(e1, e2, comment, info)
      algorithm
        (e1, arg) := traverser(e1, arg);
        (e2, arg) := traverser(e2, arg);
      then
        (SCode.EQ_REINIT(e1, e2, comment, info), arg);

    case SCode.EQ_NORETCALL(e1, comment, info)
      algorithm
        (e1, arg) := traverser(e1, arg);
      then
        (SCode.EQ_NORETCALL(e1, comment, info), arg);

    else (eq, arg);
  end match;
end mapFoldEquationExps;

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
      algorithm
        (cr, arg) := mapFoldComponentRefExps(cr, inFunc, inArg);
      then
        (AbsynUtil.crefMakeFullyQualified(cr), arg);

    case (Absyn.CREF_QUAL(name = name, subscripts = subs, componentRef = cr), _, _)
      algorithm
        (cr, arg) := mapFoldComponentRefExps(cr, inFunc, inArg);
        (subs, arg) := List.map1Fold(subs, mapFoldSubscriptExps, inFunc, arg);
      then
        (Absyn.CREF_QUAL(name, subs, cr), arg);

    case (Absyn.CREF_IDENT(name = name, subscripts = subs), _, _)
      algorithm
        (subs, arg) := List.map1Fold(subs, mapFoldSubscriptExps, inFunc, inArg);
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
      algorithm
        (sub_exp, arg) := traverser(sub_exp, arg);
      then
        (Absyn.SUBSCRIPT(sub_exp), arg);

    case (Absyn.NOSUB(), _, _) then (inSubscript, inArg);
  end match;
end mapFoldSubscriptExps;

protected function mapFoldElseWhenExps<ArgT>
  "Traverses the expressions in an else when branch, and calls the given
  function on the expressions."
  input tuple<Absyn.Exp, list<SCode.Equation>> inElseWhen;
  input TraverseFunc traverser;
  input ArgT inArg;
  output tuple<Absyn.Exp, list<SCode.Equation>> outElseWhen;
  output ArgT outArg;

  partial function TraverseFunc
    input output Absyn.Exp exp;
    input output ArgT arg;
  end TraverseFunc;
protected
  Absyn.Exp exp;
  list<SCode.Equation> eql;
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
      algorithm
        (range, arg) := traverser(range, arg);
      then
        (Absyn.ITERATOR(ident, NONE(), SOME(range)), arg);

    case (Absyn.ITERATOR(ident, SOME(guardExp), SOME(range)), traverser, arg)
      algorithm
        (guardExp, arg) := traverser(guardExp, arg);
        (range, arg) := traverser(range, arg);
      then
        (Absyn.ITERATOR(ident, SOME(guardExp), SOME(range)), arg);

    case (Absyn.ITERATOR(ident, SOME(guardExp), NONE()), traverser, arg)
      algorithm
        (guardExp, arg) := traverser(guardExp, arg);
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
      algorithm
        (stmts1, arg) := mapFoldStatementsList(stmts1, traverser, arg);
        (branches, arg) := List.mapFold(branches,
          function mapFoldBranchStatements(traverser = traverser), arg);
        (stmts2, arg) := mapFoldStatementsList(stmts2, traverser, arg);
      then
        (SCode.ALG_IF(e, stmts1, branches, stmts2, comment, info), arg);

    case SCode.ALG_FOR(iter, range, stmts1, comment, info)
      algorithm
        (stmts1, arg) := mapFoldStatementsList(stmts1, traverser, arg);
      then
        (SCode.ALG_FOR(iter, range, stmts1, comment, info), arg);

    case SCode.ALG_PARFOR(iter, range, stmts1, comment, info)
      algorithm
        (stmts1, arg) := mapFoldStatementsList(stmts1, traverser, arg);
      then
        (SCode.ALG_PARFOR(iter, range, stmts1, comment, info), arg);

    case SCode.ALG_WHILE(e, stmts1, comment, info)
      algorithm
        (stmts1, arg) := mapFoldStatementsList(stmts1, traverser, arg);
      then
        (SCode.ALG_WHILE(e, stmts1, comment, info), arg);

    case SCode.ALG_WHEN_A(branches, comment, info)
      algorithm
        (branches, arg) := List.mapFold(branches,
           function mapFoldBranchStatements(traverser = traverser), arg);
      then
        (SCode.ALG_WHEN_A(branches, comment, info), arg);

    case SCode.ALG_FAILURE(stmts1, comment, info)
      algorithm
        (stmts1, arg) := mapFoldStatementsList(stmts1, traverser, arg);
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
      algorithm
        (e1, arg) := traverser(e1, arg);
        (e2, arg) := traverser(e2, arg);
      then
        (SCode.ALG_ASSIGN(e1, e2, comment, info), arg);

    case (SCode.ALG_IF(e1, stmts1, branches, stmts2, comment, info), traverser, arg)
      algorithm
        (e1, arg) := traverser(e1, arg);
        (branches, arg) := List.map1Fold(branches, mapFoldBranchExps, traverser, arg);
      then
        (SCode.ALG_IF(e1, stmts1, branches, stmts2, comment, info), arg);

    case (SCode.ALG_FOR(iterator, SOME(e1), stmts1, comment, info), traverser, arg)
      algorithm
        (e1, arg) := traverser(e1, arg);
      then
        (SCode.ALG_FOR(iterator, SOME(e1), stmts1, comment, info), arg);


    case (SCode.ALG_PARFOR(iterator, SOME(e1), stmts1, comment, info), traverser, arg)
      algorithm
        (e1, arg) := traverser(e1, arg);
      then
        (SCode.ALG_PARFOR(iterator, SOME(e1), stmts1, comment, info), arg);

    case (SCode.ALG_WHILE(e1, stmts1, comment, info), traverser, arg)
      algorithm
        (e1, arg) := traverser(e1, arg);
      then
        (SCode.ALG_WHILE(e1, stmts1, comment, info), arg);

    case (SCode.ALG_WHEN_A(branches, comment, info), traverser, arg)
      algorithm
        (branches, arg) := List.map1Fold(branches, mapFoldBranchExps, traverser, arg);
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
      algorithm
        (e1, arg) := traverser(e1,  arg);
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
      algorithm
        true := listMember(name,knownExternalCFunctions);
        true := outVar2 == outVar1;
        argsStr := List.mapMap(args, AbsynUtil.expCref, AbsynUtil.crefIdent);
        true := valueEq(argsStr, inVars);
      then name;
    case (SCode.CLASS(name=name,
      restriction=SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION()),
      classDef=SCode.PARTS(externalDecl=SOME(SCode.EXTERNALDECL(funcName=NONE(),lang=SOME("C"))))),_,_)
      algorithm
        true := listMember(name,knownExternalCFunctions);
      then name;
  end match;
end isBuiltinFunction;

public function getEquationInfo
  "Extracts the SourceInfo from an SCode.Equation."
  input SCode.Equation inEquation;
  output SourceInfo info;
algorithm
  info := match inEquation
    case SCode.EQ_IF()        then inEquation.info;
    case SCode.EQ_EQUALS()    then inEquation.info;
    case SCode.EQ_PDE()       then inEquation.info;
    case SCode.EQ_CONNECT()   then inEquation.info;
    case SCode.EQ_FOR()       then inEquation.info;
    case SCode.EQ_WHEN()      then inEquation.info;
    case SCode.EQ_ASSERT()    then inEquation.info;
    case SCode.EQ_TERMINATE() then inEquation.info;
    case SCode.EQ_REINIT()    then inEquation.info;
    case SCode.EQ_NORETCALL() then inEquation.info;
  end match;
end getEquationInfo;

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
      algorithm
        Error.addInternalError("SCodeUtil.getStatementInfo failed", sourceInfo());
      then Absyn.dummyInfo;
  end match;
end getStatementInfo;

public function prependSubModToMod
  input SCode.SubMod subMod;
  input output SCode.Mod mod;
algorithm
  mod := match mod
    case SCode.NOMOD()
      then SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), {subMod}, NONE(), NONE(), Error.dummyInfo);
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
  outClassDef := setClassDef(cdef, inClassDef);
end addElementToClass;

public function addElementToCompositeClassDef
  "Adds a given element to a PARTS class definition."
  input SCode.Element element;
  input output SCode.ClassDef classDef;
algorithm
  () := match classDef
    case SCode.PARTS()
      algorithm
        classDef.elementLst := element :: classDef.elementLst;
      then
        ();
  end match;
end addElementToCompositeClassDef;

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
  input output SCode.Prefixes prefixes;
  input SCode.Redeclare inRedeclare;
algorithm
  prefixes.redeclarePrefix := inRedeclare;
end prefixesSetRedeclare;

public function prefixesSetReplaceable
  input output SCode.Prefixes prefixes;
  input SCode.Replaceable inReplaceable;
algorithm
  prefixes.replaceablePrefix := inReplaceable;
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
      algorithm
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
      algorithm
        SOME(attr) := mergeAttributes(inAttributes, SOME(cls_attr));
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
      algorithm
        ct := propagateConnectorType(ct1, ct2);
        p := propagateParallelism(p1,p2);
        v := propagateVariability(v1,v2);
        d := propagateDirection(d1,d2);
        isf := propagateIsField(isf1,isf2);
        ad := ad1; // TODO! CHECK if ad1 == ad2!
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
  input output SCode.Prefixes prefixes;
  input SCode.Visibility inVisibility;
algorithm
  prefixes.visibility := inVisibility;
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
      algorithm
        true := AbsynUtil.pathEqual(p1, p2);
        true := modEqual(m1, m2);
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
  equal := valueEq(prefixes1.visibility, prefixes2.visibility) and
           valueEq(prefixes1.redeclarePrefix, prefixes2.redeclarePrefix) and
           valueEq(prefixes1.finalPrefix, prefixes2.finalPrefix) and
           AbsynUtil.innerOuterEqual(prefixes1.innerOuter, prefixes2.innerOuter) and
           replaceableEqual(prefixes1.replaceablePrefix, prefixes2.replaceablePrefix);
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
    case SCode.CLASS() then inElement.prefixes;
    case SCode.COMPONENT() then inElement.prefixes;
  end match;
end elementPrefixes;

public function setElementPrefixes
  input SCode.Prefixes prefixes;
  input output SCode.Element element;
algorithm
  () := match element
    case SCode.CLASS()     algorithm element.prefixes := prefixes; then ();
    case SCode.COMPONENT() algorithm element.prefixes := prefixes; then ();
  end match;
end setElementPrefixes;

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
  input output SCode.Attributes attributes;
algorithm
  attributes.arrayDims := {};
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

public function getElementAnnotation
  input SCode.Element element;
  input String name;
  output Option<SCode.Annotation> outAnnotation;
algorithm
  outAnnotation := match element
    case SCode.EXTENDS() then element.ann;
    case SCode.CLASS() then element.cmt.annotation_;
    case SCode.COMPONENT() then element.comment.annotation_;
    else NONE();
  end match;
end getElementAnnotation;

public function lookupAnnotation
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
end lookupAnnotation;

public function lookupAnnotationBinding
  input SCode.Annotation ann;
  input String name;
  output Option<Absyn.Exp> binding;
algorithm
  binding := getModifierBinding(lookupAnnotation(ann, name));
end lookupAnnotationBinding;

public function lookupBooleanAnnotation
  input SCode.Annotation ann;
  input String name;
  output Option<Boolean> value;
protected
  Option<Absyn.Exp> binding;
  Boolean bval;
algorithm
  binding := lookupAnnotationBinding(ann, name);

  value := match binding
    case SOME(Absyn.Exp.BOOL(value = bval)) then SOME(bval);
    else NONE();
  end match;
end lookupBooleanAnnotation;

public function lookupBooleanAnnotationMod
  input SCode.Mod mod;
  output Option<Boolean> value;
protected
  Option<Absyn.Exp> binding;
  Boolean bval;
algorithm
  binding := getModifierBinding(mod);

  value := match binding
    case SOME(Absyn.Exp.BOOL(value = bval)) then SOME(bval);
    else NONE();
  end match;
end lookupBooleanAnnotationMod;

public function lookupAnnotations
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
end lookupAnnotations;

public function lookupElementAnnotation
  "Returns the modifier with the given name if it can be found in the annotation
   of the given element, otherwise an empty modifier."
  input SCode.Element element;
  input String name;
  output SCode.Mod mod;
protected
  Option<SCode.Annotation> ann;
algorithm
  ann := getElementAnnotation(element, name);
  mod := if isSome(ann) then lookupAnnotation(Util.getOption(ann), name) else SCode.Mod.NOMOD();
end lookupElementAnnotation;

public function lookupElementAnnotationBinding
  input SCode.Element element;
  input String name;
  output Option<Absyn.Exp> binding;
algorithm
  binding := getModifierBinding(lookupElementAnnotation(element, name));
end lookupElementAnnotationBinding;

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

public function commentAnnotation
  input SCode.Comment cmt;
  output Option<SCode.Annotation> ann = cmt.annotation_;
end commentAnnotation;

public function optCommentAnnotation
  input Option<SCode.Comment> cmt;
  output Option<SCode.Annotation> ann;
algorithm
  ann := match cmt
    case SOME(SCode.COMMENT(annotation_ = ann)) then ann;
    else NONE();
  end match;
end optCommentAnnotation;

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
  Option<Absyn.Exp> binding;
algorithm
  binding := lookupAnnotationBinding(inAnnotation, inName);

  outHasEntry := match binding
    case SOME(Absyn.BOOL(value = true)) then true;
    else false;
  end match;
end hasBooleanNamedAnnotation;

public function optCommentHasBooleanNamedAnnotationFalse
"check if the named annotation is present and has value false"
  input Option<SCode.Comment> comm;
  input String annotationName;
  output Boolean outB;
algorithm
  outB := match (comm,annotationName)
    local
      SCode.Annotation ann;
    case (SOME(SCode.COMMENT(annotation_=SOME(ann))),_)
      then hasBooleanNamedAnnotationFalse(ann, annotationName);
    else false;
  end match;
end optCommentHasBooleanNamedAnnotationFalse;

public function hasBooleanNamedAnnotationFalse
  "Checks if the given annotation contains an entry with the given name with the
   value False."
  input SCode.Annotation inAnnotation;
  input String inName;
  output Boolean outHasEntry;
protected
  Option<Absyn.Exp> binding;
algorithm
  binding := lookupAnnotationBinding(inAnnotation, inName);

  outHasEntry := match binding
    case SOME(Absyn.BOOL(value = false)) then true;
  else false;
  end match;
end hasBooleanNamedAnnotationFalse;

public function getEvaluateAnnotation
  "Looks up the Evaluate annotation and returns the value if the annotation
   exists and has a boolean value, otherwise NONE()."
  input SCode.Comment cmt;
  output Option<Boolean> value;
protected
  SCode.Annotation ann;
  Option<Absyn.Exp> binding;
algorithm
  value := match cmt
    case SCode.COMMENT(annotation_ = SOME(ann))
      then lookupBooleanAnnotation(ann, "Evaluate");
    else NONE();
  end match;
end getEvaluateAnnotation;

public function appendAnnotationToCommentOption
  input SCode.Annotation inAnnotation;
  input Option<SCode.Comment> inComment;
  input Boolean check_replace = false;
  output Option<SCode.Comment> outComment;
algorithm
  outComment := match inComment
    local
      SCode.Comment comment;
    case SOME(comment) then SOME(appendAnnotationToComment(inAnnotation, comment, check_replace));
    else SOME(SCode.COMMENT(SOME(inAnnotation), NONE()));
  end match;
end appendAnnotationToCommentOption;

public function appendAnnotationToComment
  input SCode.Annotation inAnnotation;
  input SCode.Comment inComment;
  input Boolean check_replace = false;
  output SCode.Comment outComment;
protected
  function isNotElem
    input SCode.SubMod mod;
    input list<SCode.SubMod> mods;
    output Boolean b = true;
  algorithm
    for m in mods loop
      if (mod.ident == m.ident) then
        b := false;
        return;
      end if;
    end for;
  end isNotElem;
algorithm
  outComment := match(inAnnotation, inComment)
    local
      Option<String> cmt;
      list<SCode.SubMod> mods1;
      SCode.Mod mod;

    case (_, SCode.COMMENT(NONE(), cmt))
      then SCode.COMMENT(SOME(inAnnotation), cmt);

    case (SCode.ANNOTATION(modification = SCode.MOD(subModLst = mods1)),
          SCode.COMMENT(SOME(SCode.ANNOTATION(modification = mod as SCode.MOD())), cmt))
      algorithm
        if not check_replace then
          mod.subModLst := listAppend(mods1, mod.subModLst);
        else
          mod.subModLst := listAppend(mods1, List.filterOnTrue(mod.subModLst, function isNotElem(mods = mods1)));
        end if;
      then
        SCode.COMMENT(SOME(SCode.ANNOTATION(mod)), cmt);

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
    case SCode.BREAK_COMPONENT() then inMod.info;
    case SCode.BREAK_CONNECT() then inMod.info;
    else Absyn.dummyInfo;
  end match;
end getModifierInfo;

public function getModifierBinding
  input SCode.Mod inMod;
  output Option<Absyn.Exp> outBinding;
algorithm
  outBinding := match(inMod)
    case SCode.MOD() then inMod.binding;
    else NONE();
  end match;
end getModifierBinding;

public function setModifierBinding
  input Option<Absyn.Exp> binding;
  input output SCode.Mod mod;
algorithm
  () := match mod
    case SCode.Mod.MOD() algorithm mod.binding := binding; then ();
    else ();
  end match;
end setModifierBinding;

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
  input output SCode.Element element;
algorithm
  () := match element
    case SCode.COMPONENT()
      algorithm
        element.condition := NONE();
      then
        ();
  end match;
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
  input output SCode.Element element;
protected
  SCode.Prefixes prefixes;
algorithm
  () := match element
    case SCode.COMPONENT(prefixes = prefixes as SCode.PREFIXES(visibility = SCode.PUBLIC()))
      algorithm
        prefixes.visibility := SCode.PROTECTED();
        element.prefixes := prefixes;
      then
        ();

    case SCode.EXTENDS(visibility = SCode.PUBLIC())
      algorithm
        element.visibility := SCode.PROTECTED();
      then
        ();

    else ();
  end match;
end makeElementProtected;

public function isElementPublic
  input SCode.Element inElement;
  output Boolean outIsPublic;
algorithm
  outIsPublic := visibilityBool(elementVisibility(inElement));
end isElementPublic;

public function isElementProtected
  input SCode.Element inElement;
  output Boolean outIsProtected;
algorithm
  outIsProtected := not visibilityBool(elementVisibility(inElement));
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
      algorithm
        e := getElementWithPath(inProgram, p);
        els := getElementsFromElement(inProgram, e);
      then
        els;
  end match;
end getElementsFromElement;

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
      algorithm
        e := getElementWithId(inProgram, i);
      then
        e;

    case (_, Absyn.QUALIFIED(i, p))
      algorithm
        e := getElementWithId(inProgram, i);
        sp := getElementsFromElement(inProgram, e);
        e := getElementWithPath(sp, p);
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

public function getElementTypePath
  input SCode.Element element;
  output Absyn.Path path;
algorithm
  path := match element
    case SCode.COMPONENT() then AbsynUtil.typeSpecPath(element.typeSpec);
    case SCode.EXTENDS() then element.baseClassPath;
  end match;
end getElementTypePath;

public function setBaseClassPath
"@auhtor: adrpo
 set the base class path in extends"
  input output SCode.Element element;
  input Absyn.Path inBcPath;
algorithm
  () := match element
    case SCode.EXTENDS()
      algorithm
        element.baseClassPath := inBcPath;
      then
        ();
  end match;
end setBaseClassPath;

public function getBaseClassPath
"@auhtor: adrpo
 return the base class path in extends"
  input SCode.Element inE;
  output Absyn.Path outBcPath;
algorithm
  SCode.EXTENDS(baseClassPath = outBcPath) := inE;
end getBaseClassPath;

public function setComponentTypeSpec
  "Sets the typespec of a component element."
  input output SCode.Element element;
  input Absyn.TypeSpec typeSpec;
algorithm
  () := match element
    case SCode.COMPONENT()
      algorithm
        element.typeSpec := typeSpec;
      then
        ();
  end match;
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
  "Sets the modification in a component element."
  input output SCode.Element element;
  input SCode.Mod mod;
algorithm
  () := match element
    case SCode.COMPONENT()
      algorithm
        element.modifications := mod;
      then
        ();
  end match;
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
  input SCode.Prefixes prefixes;
  input output SCode.Element cl;
algorithm
  () := match cl
    case SCode.CLASS()
      algorithm
        cl.prefixes := prefixes;
      then
        ();
  end match;
end setClassPrefixes;

public function getClassDef
  input SCode.Element inClass;
  output SCode.ClassDef outCdef;
algorithm
  outCdef := match(inClass)
    case SCode.CLASS(classDef = outCdef) then outCdef;
  end match;
end getClassDef;

public function setClassDef
  input SCode.ClassDef classDef;
  input output SCode.Element cls;
algorithm
  () := match cls
    case SCode.CLASS()
      algorithm
        cls.classDef := classDef;
      then
        ();
  end match;
end setClassDef;

public function getClassBody
  "Returns the body of a class, which for a class extends is the definition it
   contains and otherwise just the immediate definition of the class."
  input SCode.Element inClass;
  output SCode.ClassDef outCdef;
algorithm
  outCdef := getClassDef(inClass);

  outCdef := match outCdef
    case SCode.ClassDef.CLASS_EXTENDS() then outCdef.composition;
    else outCdef;
  end match;
end getClassBody;

public function equationsContainReinit
"@author:
 returns true if equations contains reinit"
  input list<SCode.Equation> inEqs;
  output Boolean hasReinit;
algorithm
  hasReinit := match(inEqs)
    local Boolean b;
    case _
      algorithm
        b := List.applyAndFold(inEqs, boolOr, equationContainReinit, false);
      then
        b;
  end match;
end equationsContainReinit;

public function equationContainReinit
"@author:
 returns true if equation contains reinit"
  input SCode.Equation inEq;
  output Boolean hasReinit;
algorithm
  hasReinit := match(inEq)
    local
      Boolean b;
      list<SCode.Equation> eqs;
      list<list<SCode.Equation>> eqs_lst;
      list<tuple<Absyn.Exp, list<SCode.Equation>>> tpl_el;

    case SCode.EQ_REINIT() then true;
    case SCode.EQ_WHEN(eEquationLst = eqs, elseBranches = tpl_el)
      algorithm
        b := equationsContainReinit(eqs);
        eqs_lst := List.map(tpl_el, Util.tuple22);
        b := List.applyAndFold(eqs_lst, boolOr, equationsContainReinit, b);
      then
        b;

    case SCode.EQ_IF(thenBranch = eqs_lst, elseBranch = eqs)
      algorithm
        b := equationsContainReinit(eqs);
        b := List.applyAndFold(eqs_lst, boolOr, equationsContainReinit, b);
      then
        b;

    case SCode.EQ_FOR(eEquationLst = eqs)
      algorithm
        b := equationsContainReinit(eqs);
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
      algorithm
        b := List.applyAndFold(inAlgs, boolOr, algorithmContainReinit, false);
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
      algorithm
        algs_lst := List.map(tpl_alg, Util.tuple22);
        b := List.applyAndFold(algs_lst, boolOr, algorithmsContainReinit, false);
      then
        b;

    case SCode.ALG_IF(trueBranch = algs1, elseIfBranch = tpl_alg, elseBranch = algs2)
      algorithm
        b1 := algorithmsContainReinit(algs1);
        algs_lst := List.map(tpl_alg, Util.tuple22);
        b2 := List.applyAndFold(algs_lst, boolOr, algorithmsContainReinit, b1);
        b3 := algorithmsContainReinit(algs2);
        b := boolOr(b1, boolOr(b2, b3));
      then
        b;

    case SCode.ALG_FOR(forBody = algs)
      algorithm
        b := algorithmsContainReinit(algs);
      then
        b;

    case SCode.ALG_WHILE(whileBody = algs)
      algorithm
        b := algorithmsContainReinit(algs);
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

public function isBreakSubMod
  input SCode.SubMod subMod;
  output Boolean isBreak;
algorithm
  isBreak := match subMod.mod
    case SCode.Mod.BREAK_COMPONENT() then true;
    case SCode.Mod.BREAK_CONNECT() then true;
    else false;
  end match;
end isBreakSubMod;

public function isBreakComponentSubMod
  input SCode.SubMod subMod;
  output Boolean isBreak;
algorithm
  isBreak := match subMod
    case SCode.NAMEMOD(mod = SCode.Mod.BREAK_COMPONENT()) then true;
    else false;
  end match;
end isBreakComponentSubMod;

public function isBreakConnectSubMod
  input SCode.SubMod subMod;
  output Boolean isBreak;
algorithm
  isBreak := match subMod
    case SCode.NAMEMOD(mod = SCode.Mod.BREAK_CONNECT()) then true;
    else false;
  end match;
end isBreakConnectSubMod;

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
    else SCode.NOMOD();

  end match;
end elementMod;

public function setElementMod
  "Sets the modifier of an element, or fails if the element is not capable of
   having a modifier."
  input output SCode.Element element;
  input SCode.Mod mod;
algorithm
  () := match element
    case SCode.COMPONENT() algorithm element.modifications := mod; then ();
    case SCode.CLASS()     algorithm element.classDef := setClassDefMod(element.classDef, mod); then ();
    case SCode.EXTENDS()   algorithm element.modifications := mod; then ();
  end match;
end setElementMod;

protected function setClassDefMod
  input output SCode.ClassDef classDef;
  input SCode.Mod inMod;
algorithm
  () := match classDef
    case SCode.DERIVED()       algorithm classDef.modifications := inMod; then ();
    case SCode.CLASS_EXTENDS() algorithm classDef.modifications := inMod; then ();
    else ();
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
  isExternal := match inRestr
    case SCode.FR_EXTERNAL_FUNCTION(purity = Absyn.FunctionPurity.IMPURE()) then true;
    case SCode.FR_NORMAL_FUNCTION(purity = Absyn.FunctionPurity.IMPURE()) then true;
    else false;
  end match;
end isImpureFunctionRestriction;

public function isRestrictionImpure
  input SCode.Restriction inRestr;
  input Boolean hasZeroOutputPreMSL3_2;
  output Boolean isImpure;
algorithm
  isImpure := match inRestr
    // Any function explicitly declared impure is impure.
    case SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(purity = Absyn.FunctionPurity.IMPURE())) then true;
    case SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(purity = Absyn.FunctionPurity.IMPURE())) then true;
    // External functions with no pure/impure prefix are impure by default since Modelica 3.3.
    case SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(purity = Absyn.FunctionPurity.NO_PURITY()))
      then not hasZeroOutputPreMSL3_2;
    else false;
  end match;
end isRestrictionImpure;

public function getFunctionRestrictionPurity
  input SCode.FunctionRestriction restr;
  output Absyn.FunctionPurity purity;
algorithm
  purity := match restr
    case SCode.FR_NORMAL_FUNCTION(purity = purity) then purity;
    case SCode.FR_EXTERNAL_FUNCTION(purity = purity) then purity;
    else Absyn.FunctionPurity.NO_PURITY();
  end match;
end getFunctionRestrictionPurity;

public function elementInnerOuter
  input SCode.Element element;
  output Absyn.InnerOuter io;
algorithm
  io := match element
    case SCode.Element.CLASS() then prefixesInnerOuter(element.prefixes);
    case SCode.Element.COMPONENT() then prefixesInnerOuter(element.prefixes);
    else Absyn.InnerOuter.NOT_INNER_OUTER();
  end match;
end elementInnerOuter;

public function elementVisibility
  input SCode.Element element;
  output SCode.Visibility visibility;
algorithm
  visibility := match element
    case SCode.Element.IMPORT() then element.visibility;
    case SCode.Element.EXTENDS() then element.visibility;
    case SCode.Element.CLASS() then prefixesVisibility(element.prefixes);
    case SCode.Element.COMPONENT() then prefixesVisibility(element.prefixes);
    case SCode.Element.DEFINEUNIT() then element.visibility;
  end match;
end elementVisibility;

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

public function isElementNamed
  input SCode.Ident name;
  input SCode.Element element;
  output Boolean res;
algorithm
  res := match element
    case SCode.CLASS() then element.name == name;
    case SCode.COMPONENT() then element.name == name;
    else false;
  end match;
end isElementNamed;

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
    case SCode.EXTENDS() then SOME(SCode.Comment.COMMENT(inElement.ann, NONE()));
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
  input output SCode.Element newClass;
  input SCode.Element oldClass;
algorithm
  () := matchcontinue(newClass, oldClass)
    local
      SCode.Prefixes prefixes1, prefixes2;
      SCode.ClassDef cd1,cd2;
      SCode.Mod mCCNew, mCCOld;

    // for functions return the new one!
    case (_, _)
      algorithm
        true := isFunction(newClass);
      then
        ();

    case (SCode.CLASS(prefixes = prefixes1, classDef = cd1),
          SCode.CLASS(prefixes = prefixes2, classDef = cd2))
      algorithm
        mCCNew := getConstrainedByModifiers(prefixes1);
        mCCOld := getConstrainedByModifiers(prefixes2);
        newClass.classDef := mergeClassDef(cd1, cd2, mCCNew, mCCOld);
        newClass.prefixes := propagatePrefixes(prefixes1, prefixes2);
      then
        ();

    else ();
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
      algorithm
        m2 := mergeModifiers(m2, inCCModOld);
        m1 := mergeModifiers(m1, inCCModNew);
        m2 := mergeModifiers(m1, m2);
        a2 := propagateAttributes(a2, a1);
        n := SCode.DERIVED(ts1,m2,a2);
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
      Option<String> cmt;

    case (_, SCode.NOMOD()) then inNewMod;
    case (SCode.NOMOD(), _) then inOldMod;
    case (SCode.REDECL(), _) then inNewMod;

    case (SCode.MOD(f1, e1, sl1, b1, cmt, i1),
          SCode.MOD(f2, e2, sl2, b2, _))
      algorithm
        b := if isSome(b1) then b1 else b2;
        sl := mergeSubMods(sl1, sl2);
        if referenceEq(b, b1) and referenceEq(sl, sl1) then
          m := inNewMod;
        elseif referenceEq(b, b2) and referenceEq(sl, sl2) and valueEq(f1, f2) and valueEq(e1, e2) then
          m := inOldMod;
        else
          m := SCode.MOD(f1, e1, sl, b, cmt, i1);
        end if;
      then
        m;

    else inNewMod;

  end matchcontinue;
end mergeModifiers;

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
      algorithm
        old := removeSub(s, inOld);
        sl := mergeSubMods(rest, old);
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
      algorithm
        true := stringEqual(id1, id2);
      then
        rest;

    case (_, s::rest)
      algorithm
        rest := removeSub(inSub, rest);
      then
        s::rest;
  end matchcontinue;
end removeSub;

public function mergeComponentModifiers
  input output SCode.Element newComp;
  input SCode.Element oldComp;
algorithm
  () := match (newComp, oldComp)
    case (SCode.COMPONENT(), SCode.COMPONENT())
      algorithm
        newComp.modifications := mergeModifiers(newComp.modifications, oldComp.modifications);
      then
        ();
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
  outNewConnectorType := match inNewConnectorType
    case SCode.POTENTIAL() then inOriginalConnectorType;
    else inNewConnectorType;
  end match;
end propagateConnectorType;

public function propagateParallelism
  input SCode.Parallelism inOriginalParallelism;
  input SCode.Parallelism inNewParallelism;
  output SCode.Parallelism outNewParallelism;
algorithm
  outNewParallelism := match inNewParallelism
    case SCode.NON_PARALLEL() then inOriginalParallelism;
    else inNewParallelism;
  end match;
end propagateParallelism;

public function propagateVariability
  input SCode.Variability inOriginalVariability;
  input SCode.Variability inNewVariability;
  output SCode.Variability outNewVariability;
algorithm
  outNewVariability := match inNewVariability
    case SCode.VAR() then inOriginalVariability;
    else inNewVariability;
  end match;
end propagateVariability;

public function propagateDirection
  input Absyn.Direction inOriginalDirection;
  input Absyn.Direction inNewDirection;
  output Absyn.Direction outNewDirection;
algorithm
  outNewDirection := match inNewDirection
    case Absyn.BIDIR() then inOriginalDirection;
    else inNewDirection;
  end match;
end propagateDirection;

public function propagateIsField
  input Absyn.IsField inOriginalIsField;
  input Absyn.IsField inNewIsField;
  output Absyn.IsField outNewIsField;
algorithm
  outNewIsField := match inNewIsField
    case Absyn.NONFIELD() then inOriginalIsField;
    else inNewIsField;
  end match;
end propagateIsField;

public function propagateAttributesVar
  input SCode.Element originalVar;
  input output SCode.Element newVar;
  input Boolean isNewTypeArray;
algorithm
  () := match (originalVar, newVar)
    case (SCode.COMPONENT(), SCode.COMPONENT())
      algorithm
        newVar.prefixes := propagatePrefixes(originalVar.prefixes, newVar.prefixes);
        newVar.attributes := propagateAttributes(originalVar.attributes, newVar.attributes, isNewTypeArray);
      then
        ();
  end match;
end propagateAttributesVar;

public function propagateAttributesClass
  input SCode.Element originalClass;
  input output SCode.Element newClass;
algorithm
  () := match (originalClass, newClass)
    case (SCode.CLASS(), SCode.CLASS())
      algorithm
        newClass.prefixes := propagatePrefixes(originalClass.prefixes, newClass.prefixes);
      then
        ();
  end match;
end propagateAttributesClass;

public function propagatePrefixes
  input SCode.Prefixes originalPrefixes;
  input output SCode.Prefixes newPrefixes;
algorithm
  () := match (originalPrefixes, newPrefixes)
    case (SCode.PREFIXES(), SCode.PREFIXES())
      algorithm
        newPrefixes.innerOuter := propagatePrefixInnerOuter(originalPrefixes.innerOuter, newPrefixes.innerOuter);
      then
        ();
  end match;
end propagatePrefixes;

public function propagatePrefixInnerOuter
  input Absyn.InnerOuter inOriginalIO;
  input Absyn.InnerOuter inIO;
  output Absyn.InnerOuter outIO;
algorithm
  outIO := match inIO
    case Absyn.NOT_INNER_OUTER() then inOriginalIO;
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
      algorithm
        // todo: check if the restrictions are the same for redeclared classes
      then
        (inResNew, inInfoNew);
  end match;
end checkSameRestriction;

public function setComponentName
  "Sets the name of a component element."
  input output SCode.Element element;
  input SCode.Ident name;
algorithm
  () := match element
    case SCode.COMPONENT()
      algorithm
        element.name := name;
      then
        ();
  end match;
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
  () := match eq
    case SCode.EQ_IF()
      algorithm
        eq.thenBranch := list(
            list(stripCommentsFromEquation(e, stripAnn, stripCmt) for e in branch)
          for branch in eq.thenBranch);
        eq.elseBranch := list(stripCommentsFromEquation(e, stripAnn, stripCmt) for e in eq.elseBranch);
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
        eq.eEquationLst := list(stripCommentsFromEquation(e, stripAnn, stripCmt) for e in eq.eEquationLst);
        eq.comment := stripCommentsFromComment(eq.comment, stripAnn, stripCmt);
      then
        ();

    case SCode.EQ_WHEN()
      algorithm
        eq.eEquationLst := list(stripCommentsFromEquation(e, stripAnn, stripCmt) for e in eq.eEquationLst);
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
end stripCommentsFromEquation;

function stripCommentsFromWhenEqBranch
  input output tuple<Absyn.Exp, list<SCode.Equation>> branch;
  input Boolean stripAnn;
  input Boolean stripCmt;
protected
  Absyn.Exp cond;
  list<SCode.Equation> body;
algorithm
  (cond, body) := branch;
  body := list(stripCommentsFromEquation(e, stripAnn, stripCmt) for e in body);
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
      algorithm
        mod := mergeSCodeMods(mod1,mod2);
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
      list<SCode.SubMod> subMods;
      Option<Absyn.Exp> binding;

    case (SCode.NOMOD(), _) then inModInner;
    case (_, SCode.NOMOD()) then inModOuter;

    case (SCode.MOD(),
          SCode.MOD())
      algorithm
        subMods := listAppend(inModOuter.subModLst, inModInner.subModLst);
        binding := if isSome(inModOuter.binding) then inModOuter.binding else inModInner.binding;
      then
        SCode.MOD(inModOuter.finalPrefix, inModOuter.eachPrefix, subMods,
          binding, inModOuter.comment, inModOuter.info);

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
    input output SCode.Equation eq;
  end Func;
algorithm
  eql := list(mapEquations(e, func) for e in eql);
end mapEquationsList;

function mapEquations
  input output SCode.Equation eq;
  input Func func;

  partial function Func
    input output SCode.Equation eq;
  end Func;
algorithm
  () := match eq
    case SCode.Equation.EQ_IF()
      algorithm
        eq.thenBranch := list(mapEquationsList(b, func) for b in eq.thenBranch);
        eq.elseBranch := mapEquationsList(eq.elseBranch, func);
      then
        ();

    case SCode.Equation.EQ_FOR()
      algorithm
        eq.eEquationLst := mapEquationsList(eq.eEquationLst, func);
      then
        ();

    case SCode.Equation.EQ_WHEN()
      algorithm
        eq.eEquationLst := mapEquationsList(eq.eEquationLst, func);
        eq.elseBranches := list(
          (Util.tuple21(b), mapEquationsList(Util.tuple22(b), func)) for b in eq.elseBranches);
      then
        ();

    else ();
  end match;

  eq := func(eq);
end mapEquations;

function mapEquationExps
  input output SCode.Equation eq;
  input Func func;

  partial function Func
    input output Absyn.Exp exp;
  end Func;
algorithm
  () := match eq
    case SCode.Equation.EQ_IF()
      algorithm
        eq.condition := list(func(e) for e in eq.condition);
      then
        ();

    case SCode.Equation.EQ_EQUALS()
      algorithm
        eq.expLeft := func(eq.expLeft);
        eq.expRight := func(eq.expRight);
      then
        ();

    case SCode.Equation.EQ_PDE()
      algorithm
        eq.expLeft := func(eq.expLeft);
        eq.expRight := func(eq.expRight);
        eq.domain := AbsynUtil.mapCrefExps(eq.domain, func);
      then
        ();

    case SCode.Equation.EQ_CONNECT()
      algorithm
        eq.crefLeft := AbsynUtil.mapCrefExps(eq.crefLeft, func);
        eq.crefRight := AbsynUtil.mapCrefExps(eq.crefRight, func);
      then
        ();

    case SCode.Equation.EQ_FOR()
      algorithm
        if isSome(eq.range) then
          eq.range := SOME(func(Util.getOption(eq.range)));
        end if;
      then
        ();

    case SCode.Equation.EQ_WHEN()
      algorithm
        eq.condition := func(eq.condition);
        eq.elseBranches := list(Util.applyTuple21(b, func) for b in eq.elseBranches);
      then
        ();

    case SCode.Equation.EQ_ASSERT()
      algorithm
        eq.condition := func(eq.condition);
        eq.message := func(eq.message);
        eq.level := func(eq.level);
      then
        ();

    case SCode.Equation.EQ_TERMINATE()
      algorithm
        eq.message := func(eq.message);
      then
        ();

    case SCode.Equation.EQ_REINIT()
      algorithm
        eq.cref := func(eq.cref);
        eq.expReinit := func(eq.expReinit);
      then
        ();

    case SCode.Equation.EQ_NORETCALL()
      algorithm
        eq.exp := func(eq.exp);
      then
        ();

  end match;
end mapEquationExps;

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

function isNonEmptyAlgorithm
  input SCode.AlgorithmSection alg;
  output Boolean res = not listEmpty(alg.statements);
end isNonEmptyAlgorithm;

function onlyLiteralsInMod
  "Checks if the bindings in a modifier only contains literal expressions."
  input SCode.Mod mod;
  output Boolean onlyLiterals;
protected
  list<Absyn.Exp> lst;
algorithm
  onlyLiterals := match mod
    case SCode.Mod.MOD()
      algorithm
        if isSome(mod.binding) then
          onlyLiterals := AbsynUtil.onlyLiteralsInExp(Util.getOption(mod.binding));
        else
          onlyLiterals := true;
        end if;

        if onlyLiterals then
          for m in mod.subModLst loop
            onlyLiterals := onlyLiteralsInMod(m.mod);

            if not onlyLiterals then
              break;
            end if;
          end for;
        end if;
      then
        onlyLiterals;

    else true;
  end match;
end onlyLiteralsInMod;

function transformPathedElementInProgram
  input Absyn.Path path;
  input Func func;
  input output SCode.Program program;
        output Boolean success;

  partial function Func
    input output SCode.Element element;
  end Func;
algorithm
  (program, success) := List.findMap(program,
    function transformPathedElementInElement(path = path, func = func));
end transformPathedElementInProgram;

function transformPathedElementInElement
  input Absyn.Path path;
  input Func func;
  input output SCode.Element element;
        output Boolean success;

  partial function Func
    input output SCode.Element element;
  end Func;
protected
  SCode.ClassDef cdef;
algorithm
  success := isElementNamed(AbsynUtil.pathFirstIdent(path), element);

  if success then
    if AbsynUtil.pathIsIdent(path) then
      element := func(element);
    elseif isClass(element) then
      (cdef, success) := transformPathedElementInClassDef(AbsynUtil.pathRest(path), func, getClassDef(element));

      if success then
        element := setClassDef(cdef, element);
      end if;
    end if;
  end if;
end transformPathedElementInElement;

function transformPathedElementInClassDef
  input Absyn.Path path;
  input Func func;
  input output SCode.ClassDef cls;
        output Boolean success;

  partial function Func
    input output SCode.Element element;
  end Func;
protected
  list<SCode.Element> elems;
  SCode.ClassDef cdef;
algorithm
  success := match cls
    case SCode.ClassDef.PARTS()
      algorithm
        (elems, success) := transformPathedElementInProgram(path, func, cls.elementLst);

        if success then
          cls.elementLst := elems;
        end if;
      then
        success;

    case SCode.ClassDef.CLASS_EXTENDS()
      algorithm
        (cdef, success) := transformPathedElementInClassDef(path, func, cls.composition);

        if success then
          cls.composition := cdef;
        end if;
      then
        success;

    else false;
  end match;
end transformPathedElementInClassDef;

public function makeMod
  input Boolean isFinal = false;
  input Boolean isEach = false;
  input list<SCode.SubMod> subMods = {};
  input Option<Absyn.Exp> binding = NONE();
  input Option<String> comment = NONE();
  input SourceInfo info = Absyn.dummyInfo;
  output SCode.Mod mod;
algorithm
  mod := SCode.Mod.MOD(
    if isFinal then SCode.Final.FINAL() else SCode.Final.NOT_FINAL(),
    if isEach then SCode.Each.EACH() else SCode.Each.NOT_EACH(),
    subMods,
    binding,
    comment,
    info
  );
end makeMod;

public function makeSingleAnnotation
  "Creates an annotation(name = value) annotation."
  input String name;
  input Absyn.Exp value;
  output SCode.Annotation ann;
algorithm
  ann := SCode.Annotation.ANNOTATION(SCode.Mod.MOD(
    SCode.Final.NOT_FINAL(),
    SCode.Each.NOT_EACH(),
    {
      SCode.SubMod.NAMEMOD(
        name,
        SCode.Mod.MOD(
          SCode.Final.NOT_FINAL(),
          SCode.Each.NOT_EACH(),
          {},
          SOME(value),
          NONE(),
          Absyn.dummyInfo
        )
      )
    },
    NONE(),
    NONE(),
    Absyn.dummyInfo
  ));
end makeSingleAnnotation;

public function setAnnotationInComment
  "Sets the value of an annotation in a comment. If the annotation doesn't already exist it's added."
  input String name;
  input Absyn.Exp value;
  input output SCode.Comment cmt;
  input Boolean replace = true "Whether to replace the value of an existing annotation or not";
protected
  SCode.Annotation ann;
  SCode.Mod mod;
algorithm
  if isNone(cmt.annotation_) then
    cmt.annotation_ := SOME(makeSingleAnnotation(name, value));
    return;
  else
    cmt.annotation_ := SOME(setAnnotationValue(name, value, Util.getOption(cmt.annotation_), replace));
  end if;
end setAnnotationInComment;

public function setAnnotationValue
  "Sets the value of an annotation. If the annotation doesn't already exist it's added."
  input String name;
  input Absyn.Exp value;
  input output SCode.Annotation ann;
  input Boolean replace = true "Whether to replace the value of an existing annotation or not";
protected
  SCode.Mod mod;
  list<SCode.SubMod> submods;
  Boolean found;

  function replace_mod
    input String name;
    input Absyn.Exp value;
    input Boolean replace;
    input output SCode.SubMod mod;
          output Boolean found;
  algorithm
    found := mod.ident == name;
    if found and replace then
      mod.mod := setModifierBinding(SOME(value), mod.mod);
    end if;
  end replace_mod;
algorithm
  () := match ann
    case SCode.Annotation.ANNOTATION(modification = mod as SCode.Mod.MOD())
      algorithm
        (submods, found) := List.findMap(mod.subModLst,
          function replace_mod(name = name, value = value, replace = replace));

        if not found then
          submods := SCode.SubMod.NAMEMOD(name, makeMod(binding = SOME(value))) :: submods;
        end if;

        mod.subModLst := submods;
        ann.modification := mod;
      then
        ();

    else ();
  end match;
end setAnnotationValue;

annotation(__OpenModelica_Interface="frontend");
end SCodeUtil;

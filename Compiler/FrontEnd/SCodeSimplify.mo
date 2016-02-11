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

encapsulated package SCodeSimplify
" file:        SCodeSimplify.mo
  package:     SCodeSimplify
  description: SCodeSimplify is used to further simplify SCode


  For now SCodeSimplify has the following simplifications:
  - removes extends *Icons*
  - *add more things here if needed*
"

public import Absyn;
public import SCode;

public function simplifyProgram
 "transforms scode to scode simplified"
  input SCode.Program inSCodeProgram;
  output SCode.Program outSCodeProgram;
algorithm
  outSCodeProgram := match(inSCodeProgram)
    local
      SCode.Element c, el;
      SCode.Program rest, acc;

    // handle empty
    case ({}) then {};

    // handle something
    case (el::rest)
      equation
        c = simplifyClass(el);
        acc = simplifyProgram(rest);
      then
        c::acc;

  end match;
end simplifyProgram;

protected function simplifyClass
"simplifies a class."
  input SCode.Element inClass;
  output SCode.Element outClass;
algorithm
  outClass := match(inClass)
    local
      SCode.ClassDef cDef, ncDef;
      SourceInfo info;
      SCode.Ident n;
      SCode.Prefixes pref;
      SCode.Encapsulated ecpf;
      SCode.Partial ppf;
      SCode.Restriction res;
      SCode.Comment cmt;

    case (SCode.CLASS(n, pref, ecpf, ppf, res, cDef, cmt, info))
      equation
        ncDef = simplifyClassDef(cDef);
      then
        SCode.CLASS(n, pref, ecpf, ppf, res, ncDef, cmt, info);

  end match;
end simplifyClass;

protected function simplifyClassDef
"simplifies a classdef."
  input SCode.ClassDef inClassDef;
  output SCode.ClassDef outClassDef;
algorithm
  outClassDef := match(inClassDef)
    local
      SCode.Ident  baseClassName;
      list<SCode.Element> els;
      list<SCode.Equation> ne "the list of equations";
      list<SCode.Equation> ie "the list of initial equations";
      list<SCode.AlgorithmSection> na "the list of algorithms";
      list<SCode.AlgorithmSection> ia "the list of initial algorithms";
      list<SCode.ConstraintSection> nc "the list of constraints for optimization";
      list<Absyn.NamedArg> clats "class attributes. currently for optimica extensions";
      Option<SCode.ExternalDecl> ed "used by external functions";
      list<SCode.Annotation> al "the list of annotations found in between class elements, equations and algorithms";
      Option<SCode.Comment> c "the class comment";
      SCode.ClassDef cDef;
      SCode.Mod mod;
      SCode.Attributes attr;
      Option<SCode.Comment> cmt;
      Absyn.TypeSpec typeSpec;

    // handle parts
    case (SCode.PARTS(els, ne, ie, na, ia, nc, clats, ed))
      equation
        els = simplifyElements(els);
      then
        SCode.PARTS(els, ne, ie, na, ia, nc, clats, ed);

    // handle class extends
    case (SCode.CLASS_EXTENDS(baseClassName, mod, cDef))
      equation
        cDef = simplifyClassDef(cDef);
      then
        SCode.CLASS_EXTENDS(baseClassName, mod, cDef);

    // handle derived!
    case (SCode.DERIVED(_, _, _))
      then
        inClassDef;

    // handle enumeration, just return the same
    case (SCode.ENUMERATION())
      then
        inClassDef;

    // handle overload
    case (SCode.OVERLOAD())
      then
        inClassDef;

    // handle pder
    case (SCode.PDER())
      then
        inClassDef;

  end match;
end simplifyClassDef;

protected function simplifyElements
"simplify elements"
  input list<SCode.Element> inElements;
  output list<SCode.Element> outElements;
algorithm
  outElements := matchcontinue(inElements)
    local
      SCode.Element el,el2;
      list<SCode.Element> rest, els;
      Absyn.Path bcp;

    // handle classes without elements!
    case ({}) then {};

    // handle extends Modelica.Icons.*
    case (SCode.EXTENDS(baseClassPath = bcp)::rest)
      equation
        true = Absyn.pathContains(bcp, Absyn.IDENT("Icons"));
        els = simplifyElements(rest);
      then
        els;

    // remove Modelica.Icons -> not working yet because of Modelica.Mechanics.MultiBody.Types uses it !/
    //case (SCode.CLASS(name = "Icons", restriction = SCode.R_PACKAGE())::rest)
    //  equation
    //    els = simplifyElements(rest);
    //  then
    //    els;

    // handle classes
    case ((el as SCode.CLASS())::rest)
      equation
        el2 = simplifyClass(el);
        els = simplifyElements(rest);
      then
        el2::els;

    // handle rest
    case (el::rest)
      equation
        els = simplifyElements(rest);
      then
        el::els;
  end matchcontinue;
end simplifyElements;

annotation(__OpenModelica_Interface="frontend");
end SCodeSimplify;

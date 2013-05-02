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

encapsulated package SCodeFlat
" file:        SCodeFlat.mo
  package:     SCodeFlat
  description: SCodeFlat is a flattened form of SCode

  RCS: $Id: SCodeFlat.mo 8980 2011-05-13 09:12:21Z perost $

  The SCodeFlat representation is used to simplify the models even further.

Flattening:
-----------

Idea: *everything in Modelica can be reduced to components*
- components: Type c[AD](mods);
  + encoded as Type[AD](mods) c;
- classes:    class Type ... end Type;
  + encoded as Type Type;
- extends:    class A extends B(mods); end A;
  + encoded as A.B(mods) A.$e(B);
- derived:    class A = B[AD](mods);
  + encoded as A.B[AD](mods) A.$e(B);
- equations:  equation  eq1; eq2; eq3;
  + encoded as Type.$eq Type.$eq{eq1,eq2,eq3};
- algorithms: algorithm al1; al2; al3;
  + encoded as Type.$al Type.$al{al1,al2,al3}; "

public import Absyn;
public import SCode;
public import NFSCodeEnv;

constant String extendsName    = "$ex";
constant String derivedName    = "$de";
constant String classExName    = "$ce";
constant String componentName  = "$co";
constant String algorithmsName = "$al";
constant String equationsName  = "$eq";
constant String externalName   = "$ed";
constant String defineunitName = "$ut";

public
uniontype Kind
  record CLASS      end CLASS;
  record EXTENDS    end EXTENDS;
  record DERIVED    end DERIVED;
  record COMPONENT  end COMPONENT;
  record ALGORITHMS end ALGORITHMS;
  record EQUATIONS  end EQUATIONS;
  record EXTERNAL   end EXTERNAL;
end Kind;

type Joined = list<SCode.Element>;

uniontype Type "the type of a component or class"
  record T "the type of a component or class"
    SCode.Ident   name         "the type name, for derived/extends we use the predefined constants above: extendsName and derivedName";
    SCode.Element origin       "the element from which the construct originates (for extends is the element itself, for derived is the class containing the derived";
    Joined        joined       "the scopes that were joined since the top; a scope is joined at component declaration, extends and derived";
    SCode.Mod     mod          "the modification of this type";
    Kind          kind         "what kind of type it is";
    TypePath      prefix       "the full prefix (path until now)";
    TypePath      suffix       "the full suffix (path from now to leafs)";
  end T;
end Type;

type TypePath = list<Type>
  "a type path is used to represent the type of a component or type component
   Example:
     package N = P (redeclare package R = P_R);
     will be represented as (the left hand side is a type path), the right hand side is a component reference:
     RP.N                                                       RP.N;
     RP.N.$d(P(redeclare R = P_R))                              RP.N.$d(P);";

uniontype Component "a component"
  record C "a component"
    SCode.Ident   name         "the type name, for derived/extends we use the predefined constants above: extendsName and derivedName";
    SCode.Element origin       "the element from which the component originates";
    Kind          kind         "what kind of component it is";
    TypePath      ty           "the full type path for this component";
    CompPath      prefix       "the full prefix (path until now)";
    CompPath      suffix       "the full suffix (path from now to leafs)";
  end C;
end Component;

type CompPath = list<Component> "a qualifed component is a list of components";

type FlatProgram = list<CompPath> "a flat program is a list of qualified components";

uniontype Extra "extra information that is passed along for the ride to all the functions, updated and returned back, like a hitchhiker"
  record EXTRA "the extra info"
    NFSCodeEnv.Env        env "the environment";
    TypePath            ctp "the current type scope (accumulated prefix)";
    CompPath            ccp "the current component scope (accumulated prefix)";
    Joined              cjo "the current joined scopes until now (accumulated join)";
    FlatProgram         cfp "the current flat program";
    Absyn.Info          nfo "the absyn info";
  end EXTRA;
end Extra;

protected import NFSCodeLookup;
protected import SCodeDump;
//protected import Util;

public function flattenProgram
  "transforms scode to scode flat"
  input SCode.Program inSCodeProgram;
  input Extra inExtra;
  output FlatProgram outFlatProgram;
  output Extra outExtra;
algorithm
  (outFlatProgram, outExtra) := matchcontinue(inSCodeProgram, inExtra)
    local
      NFSCodeEnv.Env env;
      SCode.Program rest;
      SCode.Element el;
      Absyn.Info info;
      TypePath ctp;
      CompPath ccp;
      Joined cjo;
      FlatProgram cfp;
      Extra iExtra, oExtra;

    // handle empty
    case ({}, iExtra as EXTRA(cfp = cfp)) then (listReverse(cfp), iExtra);

    // handle something
    case (el::rest, iExtra as EXTRA(env = env, ctp = ctp, ccp = ccp, cjo = cjo, nfo = info))
      equation
        // ignore the extra here and ...
        (cfp, _) = flattenClass(el, iExtra);
        // send the old one with the updated flat program
        (cfp, oExtra) = flattenProgram(rest, EXTRA(env, ctp, ccp, cjo, cfp, info));
      then
        (cfp, oExtra);

  end matchcontinue;
end flattenProgram;

protected function flattenClass
  "simplifies a class."
  input SCode.Element inClass;
  input Extra inExtra;
  output FlatProgram outFlatProgram;
  output Extra outExtra;
algorithm
  (outFlatProgram, outExtra) := matchcontinue(inClass, inExtra)
    local
      NFSCodeEnv.Env env;
      SCode.Element c;
      SCode.ClassDef cDef;
      Absyn.Info info;
      SCode.Ident n;
      TypePath ctp;
      CompPath ccp;
      Joined cjo;
      FlatProgram cfp;
      Extra oExtra;

    case (c as SCode.CLASS(name = n, classDef = cDef, info = info), EXTRA(env = env, ctp = ctp, ccp = ccp, cjo = cjo, cfp = cfp))
      equation
        _ = NFSCodeLookup.lookupBuiltinType(n);
      then
        (cfp, inExtra);

    case (c as SCode.CLASS(name = n, classDef = cDef, info = info), EXTRA(env = env, ctp = ctp, ccp = ccp, cjo = cjo, cfp = cfp))
      equation
        failure(_ = NFSCodeLookup.lookupBuiltinType(n));
        //print("Flattening: " +& SCodeDump.printElementStr(c) +& "\n");

        // add class to the type path and component path
        ctp = T(n, c, cjo, SCode.NOMOD(), CLASS(), ctp, {})::ctp; // the suffix will be added at the end.
        ccp = C(n, c, COMPONENT(), ctp, ccp, {})::ccp;       // the suffix will be added at the end.
        // add comp to the flatten program
        cfp = ccp::cfp;
        // dive in
        env = NFSCodeEnv.enterScope(env, n);
        (cfp, oExtra) = flattenClassDef(cDef, EXTRA(env, ctp, ccp, cjo, cfp, info));
      then
        (cfp, oExtra);
  end matchcontinue;
end flattenClass;

protected function diveIntoIfNotBasicType
"dive into the cdef if is not basic type!"
  input NFSCodeEnv.Env inEnv;
  input SCode.Ident  inName;
  input SCode.ClassDef inClassDef;
  input Extra inExtra;
  output FlatProgram outFlatProgram;
  output Extra outExtra;
algorithm
  (outFlatProgram, outExtra) := matchcontinue(inEnv, inName, inClassDef, inExtra)
    local
      NFSCodeEnv.Env env;
      Absyn.Info info;
      TypePath ctp;
      CompPath ccp;
      Joined cjo;
      FlatProgram cfp;
      Extra iExtra, oExtra;

    // do not dive into a basic type
    case (inEnv, inName, inClassDef, inExtra as EXTRA(cfp = cfp))
      equation
        _ = NFSCodeLookup.lookupBuiltinType(inName);
      then
        (cfp, inExtra);

    // dive into if is not a basic type
    case (inEnv, inName, inClassDef, inExtra as EXTRA(env = _, ctp = ctp, ccp = ccp, cjo = cjo, cfp = cfp, nfo = info))
      equation
        failure(_ = NFSCodeLookup.lookupBuiltinType(inName));
        env = NFSCodeEnv.enterScope(inEnv, inName);
        (cfp, oExtra) = flattenClassDef(inClassDef, EXTRA(env, ctp, ccp, cjo, cfp, info));
      then
        (cfp, oExtra);
  end matchcontinue;
end diveIntoIfNotBasicType;

protected function getRedeclaresAndClassExtends
  input list<SCode.Element> inElements;
  input list<SCode.Element> inAcc;
  output list<SCode.Element> outElements;
algorithm
  outElements := matchcontinue(inElements, inAcc)
    local
      SCode.Element el;
      list<SCode.Element> rest, acc;

    // handle empty
    case ({}, acc) then listReverse(acc);

    // handle class extends
    case ((el as SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = _)))::rest, acc)
      equation
        acc = el::acc;
        acc = getRedeclaresAndClassExtends(rest, acc);
      then
        acc;

    // handle redeclare-as-element classes
    case ((el as SCode.CLASS(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())))::rest, acc)
      equation
        acc = el::acc;
        acc = getRedeclaresAndClassExtends(rest, acc);
      then
        acc;

    // handle redeclare-as-element components
    case ((el as SCode.COMPONENT(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())))::rest, acc)
      equation
        acc = el::acc;
        acc = getRedeclaresAndClassExtends(rest, acc);
      then
        acc;

    // handle others
    case (_::rest, acc)
      equation
        acc = getRedeclaresAndClassExtends(rest, acc);
      then
        acc;
  end matchcontinue;
end getRedeclaresAndClassExtends;

protected function flattenClassDef
  "Flattens a classdef."
  input SCode.ClassDef inClassDef;
  input Extra inExtra;
  output FlatProgram outFlatProgram;
  output Extra outExtra;
algorithm
  (outFlatProgram, outExtra) := matchcontinue(inClassDef, inExtra)
    local
      NFSCodeEnv.Env env;
      SCode.Element cl, newCls, parentElement;
      NFSCodeEnv.ClassType cls_ty;
      SCode.Program rest;
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
      list<SCode.ConstraintSection> nc "the list of constraints for optimization";
      list<Absyn.NamedArg> clats "class attributes. currently for optimica extensions";
      Option<SCode.ExternalDecl> ed "used by external functions";
      list<SCode.Annotation> al "the list of annotations found in between class elements, equations and algorithms";
      Option<SCode.Comment> c "the class comment";
      SCode.ClassDef cDef;
      Option<SCode.Element> baseClassOpt;
      Absyn.Info info;
      SCode.Mod mod;
      SCode.Attributes attr;
      Option<SCode.Comment> cmt;
      TypePath ctp;
      CompPath ccp;
      Joined cjo;
      FlatProgram cfp;
      Extra iExtra, oExtra;
      SCode.Mod redeclareAsElementMods;

    // handle parts
    case (SCode.PARTS(els, ne, ie, na, ia, nc, clats, ed, al, c), iExtra)
      equation
        // collect the modifiers!
        modifiers = getRedeclaresAndClassExtends(els, {});
        // redeclares are send down to extends
        //redeclareAsElementMods = Util.if_(valueEq({}, modifiers), SCode.NOMOD(), SCode.REDECL(SCode.NOT_FINAL(), SCode.NOT_EACH(), modifiers));
        redeclareAsElementMods = SCode.NOMOD();
        (cfp, oExtra) = flattenElements(els, redeclareAsElementMods, iExtra);
        //(cfp, oExtra) = flattenEqs(ne, oExtra, false); // non initial
        //(cfp, oExtra) = flattenEqs(ie, oExtra, true);  // initial
        //(cfp, oExtra) = flattenAlg(ne, oExtra, false); // non initial
        //(cfp, oExtra) = flattenAlg(ne, oExtra, true);  // initial
        //(cfp, oExtra) = flattenExt(ed, oExtra);
      then
        (cfp, oExtra);

    // handle class extends
    case (SCode.CLASS_EXTENDS(baseClassName, mod, cDef), iExtra as EXTRA(env = env, ctp = ctp as T(origin=el)::_, ccp = ccp, cjo = cjo, cfp = cfp, nfo = info))
      equation
        // add class to the type path and component path
        ctp = T(classExName, el, cjo, SCode.NOMOD(), CLASS(), ctp, {})::ctp; // the suffix will be added at the end.
        ccp = C(baseClassName, el, COMPONENT(), ctp, ccp, {})::ccp;          // the suffix will be added at the end.
        // add comp to the flatten program
        cfp = ccp::cfp;
        // dive into
        oExtra = EXTRA(env, ctp, ccp, cjo, cfp, info); // (cfp, oExtra) = flattenClassDef(cDef, EXTRA(env, ctp, ccp, cjo, cfp, info));
      then
        (cfp, oExtra);

    // handle derived!
    case (SCode.DERIVED(Absyn.TPATH(path, _), mod, attr, cmt), iExtra as EXTRA(env = env, ctp = ctp as T(origin = el)::_, ccp = ccp, cjo = cjo, cfp = cfp, nfo = info))
      equation
        // Remove the extends from the local scope before flattening the derived
        // type, because the type should not be looked up via itself.
        env = NFSCodeEnv.removeExtendsFromLocalScope(env);
        (NFSCodeEnv.CLASS(cls = cl as SCode.CLASS(classDef = cDef, info = info), classType = cls_ty), path, env) =
          NFSCodeLookup.lookupBaseClassName(path, env, info);

        // add class to the type path and component path
        ctp = T(derivedName, el, cl::cjo, SCode.NOMOD(), DERIVED(), ctp, {})::ctp; // the suffix will be added at the end.
        ccp = C(derivedName, el, COMPONENT(), ctp, ccp, {})::ccp;                  // the suffix will be added at the end.
        // add comp to the flatten program
        cfp = ccp::cfp;

        //(cfp, oExtra) = flattenClass(cl, EXTRA(env, ctp, ccp, cjo, cfp, info));
        oExtra = EXTRA(env, ctp, ccp, cjo, cfp, info);
      then
        (cfp, oExtra);

    // handle enumeration, just return the same
    case (SCode.ENUMERATION(enumLst = _), iExtra as EXTRA(cfp = cfp))
      then
        (cfp, iExtra);

    // handle overload
    case (SCode.OVERLOAD(pathLst = _), iExtra as EXTRA(cfp = cfp))
      then
        (cfp, iExtra);

    // handle pder
    case (SCode.PDER(functionPath = _), iExtra as EXTRA(cfp = cfp))
      then
        (cfp, iExtra);
  end matchcontinue;
end flattenClassDef;

protected function flattenElements
  "flatten elements"
  input list<SCode.Element> inElements;
  input SCode.Mod inRedeclareAsElementMod;
  input Extra inExtra;
  output FlatProgram outFlatProgram;
  output Extra outExtra;
algorithm
  (outFlatProgram, outExtra) := matchcontinue(inElements, inRedeclareAsElementMod, inExtra)
    local
      NFSCodeEnv.Env env;
      SCode.Element el;
      list<SCode.Element> rest;
      Absyn.Info info;
      TypePath ctp;
      CompPath ccp;
      Joined cjo;
      FlatProgram cfp;
      Extra iExtra, oExtra;

    // handle classes without elements!
    case ({}, _, iExtra as EXTRA(cfp = cfp)) then (cfp, iExtra);

    // handle rest
    case (el::rest, inRedeclareAsElementMod, iExtra as EXTRA(env = env, ctp = ctp, ccp = ccp, cjo = cjo, cfp = cfp, nfo = info))
      equation
        // collect only the flat program not the other info!
        (cfp, _) = flattenElement(el, inRedeclareAsElementMod, iExtra);
        // send in the input extra with the flat program changed
        (cfp, oExtra) = flattenElements(rest, inRedeclareAsElementMod, EXTRA(env, ctp, ccp, cjo, cfp, info));
      then
        (cfp, oExtra);
  end matchcontinue;
end flattenElements;

protected function flattenElement
  "flatten an element"
  input SCode.Element inElement;
  input SCode.Mod inRedeclareAsElementMod;
  input Extra inExtra;
  output FlatProgram outFlatProgram;
  output Extra outExtra;
algorithm
  (outFlatProgram, outExtra) := matchcontinue(inElement, inRedeclareAsElementMod, inExtra)
    local
      NFSCodeEnv.Env env;
      NFSCodeEnv.ClassType cls_ty;
      Absyn.ComponentRef fullCref;
      SCode.Ident name, clsName;
      Absyn.Path path;
      SCode.Element el, cl, parentElement;
      Absyn.Import imp;
      Absyn.Info info;
      NFSCodeEnv.Item item;
      SCode.Visibility vis;
      SCode.ClassDef cDef;
      Option<SCode.Annotation> ann;
      SCode.Mod mod;
      TypePath ctp;
      CompPath ccp;
      Joined cjo;
      FlatProgram cfp;
      Extra iExtra, oExtra;

    // handle extends
    case (el as SCode.EXTENDS(path, vis, mod, ann, info), inRedeclareAsElementMod, iExtra as EXTRA(env = env, ctp = ctp, ccp = ccp, cjo = cjo, cfp = cfp))
      equation
        // Remove the extends from the local scope before flattening the extends
        // type, because the type should not be looked up via itself.
        env = NFSCodeEnv.removeExtendsFromLocalScope(env);
        (NFSCodeEnv.CLASS(cls = cl as SCode.CLASS(classDef = cDef, info = info), classType = cls_ty), path, env) =
          NFSCodeLookup.lookupBaseClassName(path, env, info);

        // add class to the type path and component path
        ctp = T(extendsName, el, cl::cjo, inRedeclareAsElementMod, EXTENDS(), ctp, {})::ctp; // the suffix will be added at the end.
        ccp = C(extendsName, el, COMPONENT(), ctp, ccp, {})::ccp;         // the suffix will be added at the end.
        // add comp to the flatten program
        cfp = ccp::cfp;

        oExtra = EXTRA(env, ctp, ccp, cjo, cfp, info); //(cfp, oExtra) = flattenClass(cl, EXTRA(env, ctp, ccp, cjo, cfp, info));
      then
        (cfp, oExtra);

    // handle classdef
    case (el as SCode.CLASS(info = info), inRedeclareAsElementMod, iExtra)
      equation
        (cfp, oExtra) = flattenClass(el, iExtra);
      then
        (cfp, oExtra);

    // handle import, WE SHOULD NOT HAVE ANY!
    case (el as SCode.IMPORT(imp = imp), inRedeclareAsElementMod, iExtra as EXTRA(env = env, ctp = ctp, ccp = ccp, cjo = cjo, cfp = cfp, nfo = info))
      equation
        print("Import found! We should not have any!");
      then
        (cfp, iExtra);

    // handle user defined component
    case (el as SCode.COMPONENT(name = name, typeSpec = Absyn.TPATH(path = path)), inRedeclareAsElementMod, iExtra as EXTRA(env = env, ctp = ctp, ccp = ccp, cjo = cjo, cfp = cfp, nfo = info))
      equation
        (NFSCodeEnv.CLASS(cls = cl as SCode.CLASS(name = clsName, classDef = cDef, info = info), classType = cls_ty), path, env) =
          NFSCodeLookup.lookupClassName(path, env, info);

        // add class to the type path and component path
        ctp = T(componentName, el, cl::cjo, SCode.NOMOD(), CLASS(), ctp, {})::ctp; // the suffix will be added at the end.
        ccp = C(name, el, COMPONENT(), ctp, ccp, {})::ccp;                         // the suffix will be added at the end.
        // add comp to the flatten program
        cfp = ccp::cfp;

        // dive into the component type if is not basic
        //(cfp, oExtra) = flattenClass(cl, EXTRA(env, ctp, ccp, cjo, cfp, info));
        oExtra = EXTRA(env, ctp, ccp, cjo, cfp, info);
      then
        (cfp, oExtra);

    // handle defineunit
    case (el as SCode.DEFINEUNIT(name = name), inRedeclareAsElementMod, iExtra as EXTRA(env = env, ctp = ctp, ccp = ccp, cjo = cjo, cfp = cfp, nfo = info))
      equation
        // add class to the type path and component path
        ctp = T(defineunitName, el, cjo, SCode.NOMOD(), CLASS(), ctp, {})::ctp; // the suffix will be added at the end.
        ccp = C(defineunitName, el, COMPONENT(), ctp, ccp, {})::ccp;       // the suffix will be added at the end.
        // add comp to the flatten program
        cfp = ccp::cfp;

        oExtra = EXTRA(env, ctp, ccp, cjo, cfp, info);
      then
        (cfp, oExtra);

     case (el, inRedeclareAsElementMod, iExtra as EXTRA(env = env, ctp = ctp, ccp = ccp, cjo = cjo, cfp = cfp, nfo = info))
       equation
         print("- SCodeFlat.flattenElement failed on element: " +& SCodeDump.shortElementStr(el) +& "\n");
       then
         fail();
  end matchcontinue;
end flattenElement;

end SCodeFlat;


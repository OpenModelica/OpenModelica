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

encapsulated package SCodeAnalyseRedeclare
" file:        SCodeAnalyseRedeclare.mo
  package:     SCodeAnalyseRedeclare
  description: SCode analysis of redeclares 

  RCS: $Id: SCodeAnalyseRedeclare.mo 13614 2012-10-25 00:03:02Z perost $

  This module will do a dryrun of instantiation and find out
  where the redeclares are applied. This information is used
  by SCodeApplyRedeclare to apply the redeclares to the SCode.
"

public import Absyn;
public import DAE;
public import InstTypes;
public import SCode;
public import SCodeEnv;
public import SCodeFlattenRedeclare;

protected import ClassInf;
protected import Debug;
protected import Error;
protected import Flags;
protected import InstUtil;
protected import List;
protected import SCodeCheck;
protected import SCodeDump;
protected import SCodeLookup;
protected import SCodeMod;
protected import SCodeInst;
protected import Util;
protected import System;

public type Binding = InstTypes.Binding;
public type Dimension = InstTypes.Dimension;
public type Element = SCode.Element;
public type Program = SCode.Program;
public type Env = SCodeEnv.Env;
public type Modifier = InstTypes.Modifier;
public type ParamType = InstTypes.ParamType;
public type Prefix = InstTypes.Prefix;
public type Scope = Absyn.Within;
public type Item = SCodeEnv.Item;
public type Redeclarations = list<SCodeEnv.Redeclaration>;
public type Replacements = SCodeFlattenRedeclare.Replacements;
public type Replacement = SCodeFlattenRedeclare.Replacement;

public type InstStack = list<Absyn.Path>; 
public constant InstStack emptyInstStack = {};

public constant Integer tmpTickIndex = 3;

public uniontype Info

  record RP "redeclare info"
    Replacements replacements;
  end RP;
  
  record RI "redeclared info, previous item before redeclare"
    Item item "previous item";
    Env env "the env where we looked it up";
  end RI;
  
  record EI "iscope info"
    Element element;
    Env env;
  end EI;
  
end Info;

type Infos = list<Info>;

public uniontype Kind
  record CL "class node"
    Absyn.Path name;
  end CL;

  record CO "component node"
    Prefix prefix;
    Absyn.Path scope;
  end CO;

  record EX "extends node"
    Absyn.Path name;
  end EX;

  record RE "redeclared node"
    Absyn.Path name;
  end RE;
end Kind;

public 
uniontype IScope

  record IS
    Kind kind;
    Infos infos;
    IScopes parts;
  end IS;
    
end IScope;

public type IScopes = list<IScope>;

public constant IScopes emptyIScopes = {};

public function analyse
"analysis of where the redeclares are applied"
  input Absyn.Path inClassPath;
  input Env inEnv;
  output IScopes outIScopes;
algorithm
  outIScopes := matchcontinue(inClassPath, inEnv)
    local 
      IScopes islist;
      String name;
      Program classes;
      Env env;
      Item item;
      Absyn.Path path;
    
    case (_, _)
      equation
        //print("Starting the new redeclare analysis phase ...\n");
        name = Absyn.pathLastIdent(inClassPath);
        
        (item, path, env) = SCodeLookup.lookupClassName(inClassPath, inEnv, Absyn.dummyInfo);
        
        (islist, _) = analyseItem(
                       item, 
                       env, 
                       InstTypes.NOMOD(), 
                       InstTypes.EMPTY_PREFIX(SOME(path)), 
                       emptyIScopes,
                       emptyInstStack);        
        
        // sort so classes are first in the childs
        islist = sortParts(islist);        
        
        //print("Number of IScopes: " +& intString(iScopeSize(islist)) +& "\n");
        //print("Max Inst Scope: " +& intString(instScopesDepth(islist)) +& "\n");
        
        islist = filterRedeclareIScopes(islist, {});
        
        //print("Filtered Number of IScopes: " +& intString(iScopeSize(islist)) +& "\n");
        //print("Filtered Max Inst Scope: " +& intString(instScopesDepth(islist)) +& "\n");
        
        islist = collapseDerivedClassChain(islist, {});
        
        //print("After derived colapse Number of IScopes: " +& intString(iScopeSize(islist)) +& "\n");
        //print("After derived colapse Filtered Max Inst Scope: " +& intString(instScopesDepth(islist)) +& "\n");
        
        islist = fixpointCleanRedeclareIScopes(islist);
        
        //print("After fixpoint clean Number of IScopes: " +& intString(iScopeSize(islist)) +& "\n");
        //print("After fixpoint clean Filtered Max Inst Scope: " +& intString(instScopesDepth(islist)) +& "\n");        
        
        printIScopes(islist);
      then
        islist;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = Absyn.pathString(inClassPath);
        Debug.traceln("SCodeAnalyseRedeclare.analyse failed on: " +& name);
      then
        fail();

  end matchcontinue;
end analyse;

protected function analyseItem
  input Item inItem;
  input Env inEnv;
  input Modifier inMod;
  input Prefix inPrefix;
  input IScopes inIScopesAcc;
  input InstStack inInstStack;
  output IScopes outIScopes;
  output InstStack outInstStack;
algorithm
  (outIScopes, outInstStack) :=
  matchcontinue(inItem, inEnv, inMod, inPrefix, inIScopesAcc, inInstStack)
    local
      list<Element> el;
      list<tuple<Element, Modifier>> mel;
      Absyn.TypeSpec dty, ts, tsFull;
      Option<Absyn.ArrayDim> ad;
      Item item;
      Env env, envDerived;
      Absyn.Info info;
      SCode.Mod smod;
      Modifier mod;
      SCodeEnv.AvlTree cls_and_vars;
      String name, tname, name1, name2;
      list<SCode.Equation> eq, ieq;
      list<SCode.AlgorithmSection> alg, ialg;
      DAE.Type ty;
      Absyn.ArrayDim dims;
      list<DAE.Var> vars;
      list<SCode.Enum> enums;
      Absyn.Path path;
      list<Element> elems;
      Boolean cse, ice;
      Element scls, scls2, cls;
      SCode.ClassDef cdef;
      Integer dim_count;
      list<SCodeEnv.Extends> exts;
      SCode.Restriction res;
      ClassInf.State state;
      SCode.Attributes attr;
      Prefix prefix;
      SCode.Prefixes sprefs;
      SCode.Encapsulated ep;
      SCode.Partial pp;
      list<SCode.ConstraintSection> cs;
      list<Absyn.NamedArg> clsattr;
      Option<SCode.ExternalDecl> ed;
      list<SCode.Annotation> al;
      Option<SCode.Comment> cmt;
      InstStack ii;
      IScopes islist;
      IScope is;
      list<SCodeEnv.Redeclaration> redeclares;
      Replacements replacements;
      list<tuple<Item, Env>> previousItem;
      Infos infos;
      Absyn.Path fullName;

    // filter out some classes!
    case (SCodeEnv.CLASS(
            cls = scls as SCode.CLASS(name = name, restriction = res),  
            env = env), 
          _, _, _, _, _)
      equation
        true = listMember(name, {"equalityConstraint", "Orientation"});
        //is = mkIScope(CL(Absyn.IDENT(name)), {EI(scls, env)}, {});
        //islist = is::inIScopesAcc;
        islist = inIScopesAcc;
      then 
        (islist, inInstStack);

    // extending basic type
    case (SCodeEnv.CLASS(
            cls = SCode.CLASS(name = name),  
            classType = SCodeEnv.BASIC_TYPE()), 
          _, _, _, _, _)
      equation
        //is = mkIScope(CL(Absyn.IDENT(name)),{}, {});
        //islist = is::inIScopesAcc;
        islist = inIScopesAcc;
      then 
        (islist, inInstStack);

    // enumerations
    case (SCodeEnv.CLASS(
            cls = SCode.CLASS(name = name, classDef = SCode.ENUMERATION(enumLst = _))), 
          _, _, _, _, _)
      equation
        //is = mkIScope(CL(Absyn.IDENT(name)),{}, {});
        //islist = is::inIScopesAcc;
        islist = inIScopesAcc;
      then 
        (islist, inInstStack);

    // a derived class from basic type.
    case (SCodeEnv.CLASS(
            cls = scls as SCode.CLASS(name = name, classDef = SCode.DERIVED(dty, smod, attr, cmt), info = info)), 
          _, _, _, _, _)
      equation
        // Look up the inherited class.
        (item as SCodeEnv.CLASS(classType = SCodeEnv.BASIC_TYPE()), _, env) =
          SCodeLookup.lookupTypeSpec(dty, inEnv, info);
        
        //is = mkIScope(CL(Absyn.IDENT(name)),{EI(scls, env)}, {});
        //islist = is::inIScopesAcc;
        islist = inIScopesAcc;
      then 
        (islist, inInstStack);

    // a derived class, look up the inherited class and instantiate it.
    case (SCodeEnv.CLASS(
            cls = scls as SCode.CLASS(name = name, classDef = SCode.DERIVED(dty, smod, attr, cmt), info = info),
            env = envDerived), 
          _, _, _, _, _)
      equation
        // Look up the inherited class.
        (item, ts, env) = SCodeLookup.lookupTypeSpec(dty, inEnv, info);
        tsFull = SCodeEnv.mergeTypeSpecWithEnvPath(ts, env);
        (item, env, previousItem) = SCodeEnv.resolveRedeclaredItem(item, env);
                
        // Merge the modifiers and instantiate the inherited class.
        dims = Absyn.typeSpecDimensions(dty);
        dim_count = listLength(dims);
        mod = SCodeMod.translateMod(smod, "", dim_count, inPrefix, inEnv);
        mod = SCodeMod.mergeMod(inMod, mod);
        
        // Apply the redeclarations from the derived environment!!!!
        // print("getting redeclares: item: " +& SCodeEnv.itemStr(item) +& "\n");
        redeclares = listAppend(
          SCodeEnv.getDerivedClassRedeclares(name, ts, envDerived), 
          SCodeFlattenRedeclare.extractRedeclaresFromModifier(smod));
        (item, env, replacements) = SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redeclares, item, env, inEnv, inPrefix);
        
        (islist, ii) = analyseItem(item, env, mod, inPrefix, emptyIScopes, inInstStack);
        
        scls = SCode.setDerivedTypeSpec(scls, tsFull);
        infos = mkInfos(previousItem, {RP(replacements), EI(scls, env)});
        
        fullName = SCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
        is = mkIScope(CL(fullName), infos, islist);
        islist = is::inIScopesAcc;
      then
        (islist, ii);

    // a class with parts, instantiate all elements in it.
    case (SCodeEnv.CLASS(
            cls = scls as SCode.CLASS(name = name, classDef = SCode.PARTS(elementLst = el), info = info),
            env = {SCodeEnv.FRAME(clsAndVars = cls_and_vars)}), 
          _, _, _, _, _)
      equation
        
        // Enter the class scope and look up all class elements.
        env = SCodeEnv.mergeItemEnv(inItem, inEnv);
        
        // Apply modifications to the elements and instantiate them.
        mel = SCodeMod.applyModifications(inMod, el, inPrefix, env);
        exts = SCodeEnv.getEnvExtendsFromTable(env);
        
        (islist, ii) = analyseElementList(mel, exts, env, inPrefix, emptyIScopes, inInstStack);
        
        fullName = SCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
        
        is = mkIScope(CL(fullName), {EI(scls, inEnv)}, islist);
        islist = is::inIScopesAcc;
      then
        (islist, ii);
    
    // a class extends
    case (SCodeEnv.CLASS(
            cls = scls as SCode.CLASS(name = name), classType = SCodeEnv.CLASS_EXTENDS(), env = env),
          _, _, _, _, _)
      equation
        //(islist, ii) = analyseClassExtends(scls, inMod, env, inEnv, inPrefix, inIScopesAcc/*emptyIScopes*/, inInstStack);
        
        //fullName = SCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
        //is = mkIScope(CL(fullName), {EI(scls, env)}, islist);
        //islist = is::inIScopesAcc;
        islist = inIScopesAcc;
        ii = inInstStack;
      then
        (islist, ii);
    
    // a redeclared item
    case (SCodeEnv.REDECLARED_ITEM(item = item, declaredEnv = env), _, _, _, _, _)
      equation
        name = SCodeEnv.getItemName(item);        
        (islist, ii) = analyseItem(item, env, inMod, inPrefix, emptyIScopes, inInstStack);
        
        fullName = SCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), env);
        is = mkIScope(RE(fullName), {RI(item, inEnv)}, islist);
        islist = is::inIScopesAcc;
      then
        (islist, ii);
    
    // failure
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeAnalyseRedeclare.instClassItem failed on unknown class.\n");
      then
        fail();

  end matchcontinue;
end analyseItem;
        
protected function analyseElementList
"Helper function to analyseItem."
  input list<tuple<Element, Modifier>> inElements;
  input list<SCodeEnv.Extends> inExtends;
  input Env inEnv;
  input Prefix inPrefix;
  input IScopes inIScopesAcc;
  input InstStack inInstStack;
  output IScopes outIScopes;
  output InstStack outInstStack;
algorithm
  (outIScopes, outInstStack) :=
  match(inElements, inExtends, inEnv, inPrefix, inIScopesAcc, inInstStack)
    local
      tuple<Element, Modifier> elem;
      list<tuple<Element, Modifier>> rest_el;
      Boolean cse;
      list<Element> accum_el;
      list<SCodeEnv.Extends> exts;
      InstStack ii;
      Env env;
      IScopes islist;
      IScope is;
      String str;
      list<tuple<Item, Env>> previousItem;

    case (elem :: rest_el, exts, _, _, islist, _)
      equation
        (elem, env, previousItem) = SCodeInst.resolveRedeclaredElement(elem, inEnv);
        (islist, exts, ii) = analyseElement_dispatch(elem, exts, env, inPrefix, islist, inInstStack, previousItem);
        (islist, ii) = analyseElementList(rest_el, exts, inEnv, inPrefix, islist, ii);
      then
        (islist, ii);

    case ({}, {}, _, _, _, _) then (inIScopesAcc, inInstStack);

    // analyseElementList takes a list of Extends, which contains the extends
    // information from the environment. We should have one Extends element for
    // each extends clause, so if we have any left when we've run out of
    // elements something has gone very wrong.
    case ({}, _ :: _, _, _, _, _)
      equation
        str = "SCodeAnalyseRedeclare.analyseElementList has extends left! \n\t" +& 
              stringDelimitList(List.map(inExtends, SCodeEnv.printExtendsStr), "\n\t");
        Error.addMessage(Error.INTERNAL_ERROR, {str});
        print(str);
      then
        fail();

  end match;
end analyseElementList;

protected function analyseElement_dispatch
"Helper function to analyseElementList. 
 Dispatches the given element to the correct function for transformation."
  input tuple<Element, Modifier> inElement;
  input list<SCodeEnv.Extends> inExtends;
  input Env inEnv;
  input Prefix inPrefix;
  input IScopes inIScopesAcc;
  input InstStack inInstStack;
  input list<tuple<Item, Env>> inPreviousItem;
  output IScopes outIScopes;
  output list<SCodeEnv.Extends> outExtends;
  output InstStack outInstStack;
algorithm
  (outIScopes, outExtends, outInstStack) :=
  matchcontinue(inElement, inExtends, inEnv, inPrefix, inIScopesAcc, inInstStack, inPreviousItem)
    local
      Element elem;
      Modifier mod;
      list<Element> res;
      Option<Element> ores;
      Boolean cse;
      list<Element> accum_el;
      Redeclarations redecls;
      list<SCodeEnv.Extends> rest_exts;
      String name;
      Prefix prefix;
      Env env;
      Element cls;
      Item item;
      InstStack ii;
      Absyn.Info info;
      IScopes islist;
      IScope is;
      Integer i;

    // A component 
    case ((elem as SCode.COMPONENT(name = _), mod), _, _, _, _, _, _)
      equation
        (islist, ii) = analyseElement(elem, mod, inEnv, inPrefix, inIScopesAcc, inInstStack, inPreviousItem); 
      then
        (islist, inExtends, ii);

    // A class 
    case ((elem as SCode.CLASS(name = _), mod), _, _, _, _, _, _)
      equation
        (islist, ii) = analyseElement(elem, mod, inEnv, inPrefix, inIScopesAcc, inInstStack, inPreviousItem); 
      then
        (islist, inExtends, ii);

    // An extends clause. Transform it it together with the next Extends element from the environment.
    case ((elem as SCode.EXTENDS(baseClassPath = _), mod),
          SCodeEnv.EXTENDS(redeclareModifiers = redecls) :: rest_exts, _, _, _, _, _)
      equation
        (islist, ii) = analyseExtends(elem, mod, redecls, inEnv, inPrefix, inIScopesAcc, inInstStack);
      then
        (islist, rest_exts, ii);
    
    // We should have one Extends element for each extends clause in the class.
    // If we get an extends clause but don't have any Extends elements left,
    // something has gone very wrong.
    case ((SCode.EXTENDS(baseClassPath = _), _), _, {}, _, _, _, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SCodeAnalyseRedeclare.analyseElement_dispatch ran out of extends!."});
      then
        fail();
    
    // Ignore any other kind of elements (class definitions, etc.).
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        (elem, _) = inElement;
        print("Ignoring: " +& SCodeDump.unparseElementStr(elem) +& "\n\t" +&
        "in env: " +& SCodeEnv.getEnvName(inEnv) +& "\n\t" +&
        "inst stack: " +& stringDelimitList(List.map(inInstStack, Absyn.pathString), "\n\t") +& "\n\t" +&
        "prefix:" +& Absyn.pathString(InstUtil.prefixToPath(inPrefix)) +& "\n");
      then
        (inIScopesAcc, inExtends, inInstStack);
  end matchcontinue;
end analyseElement_dispatch;

protected function analyseElement
  input Element inElement;
  input Modifier inClassMod;
  input Env inEnv;
  input Prefix inPrefix;
  input IScopes inIScopesAcc;
  input InstStack inInstStack;
  input list<tuple<Item, Env>> inPreviousItem;
  output IScopes outIScopes;
  output InstStack outInstStack;
algorithm
  (outIScopes, outInstStack) := 
  matchcontinue(inElement, inClassMod, inEnv, inPrefix, inIScopesAcc, inInstStack, inPreviousItem)
    local
      Absyn.Info info;
      Absyn.Path path, tpath, newpath;
      Element comp;
      DAE.Type ty;
      Env env;
      Item item, itemOld;
      Redeclarations redecls;
      Binding binding;
      Prefix prefix;
      SCode.Mod smod;
      Modifier mod, cmod;
      String name, tname, newname;
      list<DAE.Dimension> dims;
      array<Dimension> dim_arr;
      Element cls;
      list<Element> classes;
      Integer dim_count;
      Absyn.Exp cond_exp;
      DAE.Exp inst_exp;
      ParamType pty;
      SCode.Prefixes sprefs;
      SCode.Attributes attributes;
      Absyn.TypeSpec typeSpec;
      Option<SCode.Comment> cmt;
      Option<Absyn.Exp> condition;
      InstStack ii;
      Boolean sameEnv, isBasic, isCompInsideType;
      Option<Absyn.ArrayDim> ad;
      IScopes islist;
      IScope is;
      SCodeFlattenRedeclare.Replacements replacements;
      list<tuple<Item, Env>> previousItem;
      Infos infos;
      Absyn.Path fullName;

    // A component, look up it's type and instantiate that class.
    case (SCode.COMPONENT(
            name = name, 
            typeSpec = Absyn.TPATH(tpath, ad),
            modifications = smod,
            info = info), _, _, _, _, _, _)
      equation 
        // Look up the class of the component.        
        (item, tpath, env) = SCodeLookup.lookupClassName(tpath, inEnv, info);
        tpath = SCodeEnv.mergePathWithEnvPath(tpath, env);
        false = listMember(tpath, inInstStack);
        (item, env, previousItem) = SCodeEnv.resolveRedeclaredItem(item, env);
        
        prefix = InstUtil.addPrefix(name, {}, inPrefix);
        
        // Check that it's legal to instantiate the class.
        SCodeCheck.checkInstanceRestriction(item, prefix, info);

        // Merge the class modifications with this element's modifications.
        mod = SCodeMod.translateMod(smod, name, 0, inPrefix, inEnv);
        mod = SCodeMod.mergeMod(inClassMod, mod);

        // Apply redeclarations to the class definition and instantiate it.
        redecls = SCodeFlattenRedeclare.extractRedeclaresFromModifier(smod);
        (item, env, replacements) = SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, item, env, inEnv, inPrefix);
        
        (islist, ii) = analyseItem(item, env, mod, prefix, emptyIScopes, inInstStack);
        
        comp = inElement;
        comp = SCode.setComponentTypeSpec(comp, Absyn.TPATH(tpath, ad));
        infos = mkInfos(listAppend(previousItem,inPreviousItem), {RP(replacements),EI(comp, env)});
        
        fullName = SCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv); 
        
        is = mkIScope(CO(prefix,fullName), infos, islist);
        islist = Util.if_(List.isEmpty(islist),inIScopesAcc, is::inIScopesAcc);
      then
        (islist, ii);

    case (SCode.CLASS(
            name = name, 
            info = info,
            classDef = SCode.CLASS_EXTENDS(baseClassName = _) 
            ), _, _, _, _, _, _)
      equation
      then
        (inIScopesAcc,inInstStack);

    // only replaceable?? functions, packages, classes
    case (SCode.CLASS(
            name = name, 
            info = info, 
            prefixes = SCode.PREFIXES(replaceablePrefix = _ /*SCode.REPLACEABLE(_)*/)), _, _, _, _, _, _)
      equation
        fullName = SCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
        false = listMember(fullName, inInstStack);
        // add it
        ii = fullName::inInstStack;
        
        (item, env) = SCodeLookup.lookupInClass(name, inEnv);
        (item, env, previousItem) = SCodeEnv.resolveRedeclaredItem(item, env);
                
        (islist, ii) = analyseItem(item, env, inClassMod, inPrefix, {}, ii);
        
        // remove it
        ii = inInstStack;        
        
        infos = mkInfos(listAppend(previousItem,inPreviousItem), {EI(inElement, env)});
        
        // for debugging 
        // fullName = Absyn.joinPaths(fullName, Absyn.IDENT("$local"));
        is = mkIScope(CL(fullName), infos, islist);
        islist = is::inIScopesAcc;
      then
        (islist, ii);

   // for debugging
   case (_, _, _, _, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeAnalyseRedeclare.instElement ignored element:" +& SCodeDump.unparseElementStr(inElement) +& "\n");
      then
        fail();

    else (inIScopesAcc, inInstStack);

  end matchcontinue;
end analyseElement;

protected function analyseExtends
  input Element inExtends;
  input Modifier inClassMod;
  input Redeclarations inRedeclares;
  input Env inEnv;
  input Prefix inPrefix;
  input IScopes inIScopesAcc;
  input InstStack inInstStack;
  output IScopes outIScopes;
  output InstStack outInstStack;
algorithm
  (outIScopes, outInstStack) :=
  match(inExtends, inClassMod, inRedeclares, inEnv, inPrefix, inIScopesAcc, inInstStack)
    local
      Absyn.Path path;
      SCode.Mod smod;
      Absyn.Info info;
      Item item, itemOld;
      Env env;
      Modifier mod;
      Element cls, scls;
      list<Element> classes;
      DAE.Type ty;
      Boolean cse;
      String name, tname;
      SCode.Visibility visibility;
      Option<SCode.Annotation> ann;
      InstStack ii;
      Boolean isBasic;
      IScopes islist;
      IScope is;
      Replacements replacements;
      Infos infos;

    case (SCode.EXTENDS(path, visibility, smod, ann, info),
          _, _, _, _, _, _)
      equation
        // Look up the base class in the environment.
        (item, path, env) = SCodeLookup.lookupBaseClassName(path, inEnv, info);
        itemOld = item;
        
        path = SCodeEnv.mergePathWithEnvPath(path, env);
        SCodeInst.checkRecursiveExtends(path, inEnv, info);

        // Instantiate the class.
        mod = SCodeMod.translateMod(smod, "", 0, inPrefix, inEnv);
        mod = SCodeMod.mergeMod(inClassMod, mod);

        // Apply the redeclarations.
        (item, env, replacements) = SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(inRedeclares, item, env, inEnv, inPrefix);
        
        (islist, ii) = analyseItem(item, env, mod, inPrefix, emptyInstStack, inInstStack);
        
        infos = mkInfos({}, {RP(replacements),EI(inExtends, inEnv)});
        is = mkIScope(EX(path), infos, islist);
        islist = is::inIScopesAcc;
      then
        (islist, ii);        
        
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeAnalyseRedeclare.instExtends failed on unknown element.\n");
      then
        fail();

  end match;
end analyseExtends;

protected function analyseClassExtends
  input Element inClassExtends;
  input Modifier inMod;
  input Env inClassEnv;
  input Env inEnv;
  input Prefix inPrefix;
  input IScopes inIScopesAcc;
  input InstStack inInstStack;
  output IScopes outIScopes;
  output InstStack outInstStack;
algorithm
  (outIScopes, outInstStack) := 
  matchcontinue(inClassExtends, inMod, inClassEnv, inEnv, inPrefix, inIScopesAcc, inInstStack)
    local
      SCode.ClassDef cdef;
      SCode.Mod mod;
      Element scls, ext;
      Absyn.Path bc_path, fullName;
      Absyn.Info info;
      String name;
      Item item;
      Env base_env, ext_env;
      Element base_cls, ext_cls, comp_cls;
      list<Element> classes;
      InstStack ii;
      IScopes islist;
      IScope is;

    case (SCode.CLASS(
            name = name, 
            classDef = SCode.CLASS_EXTENDS(modifications = mod,composition = cdef)), 
          _, _, _, _, _, _)
      equation
        (bc_path, info) = getClassExtendsBaseClass(inClassEnv);
        ext = SCode.EXTENDS(bc_path, SCode.PUBLIC(), mod, NONE(), info);
        cdef = SCode.addElementToCompositeClassDef(ext, cdef);
        scls = SCode.setElementClassDefinition(cdef, inClassExtends);
        item = SCodeEnv.CLASS(scls, inClassEnv, SCodeEnv.CLASS_EXTENDS());        
        (islist, ii) = analyseItem(item, inEnv, inMod, inPrefix, emptyIScopes, inInstStack);
        
        fullName = SCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
        is = mkIScope(CL(fullName), {EI(scls, inEnv)}, islist);
        islist = is::inIScopesAcc;
      then
        (islist, ii);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = SCode.elementName(inClassExtends);
        Debug.traceln("SCodeAnalyseRedeclare.instClassExtends failed on " +& name);
      then
        fail();

  end matchcontinue;
end analyseClassExtends;

protected function getClassExtendsBaseClass
  input Env inClassEnv;
  output Absyn.Path outPath;
  output Absyn.Info outInfo;
algorithm
  (outPath, outInfo) := matchcontinue(inClassEnv)
    local
      Absyn.Path bc;
      Absyn.Info info;
      String name;

    case (SCodeEnv.FRAME(extendsTable = SCodeEnv.EXTENDS_TABLE(
            baseClasses = SCodeEnv.EXTENDS(baseClass = bc, info = info) :: _)) :: _)
      then (bc, info);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = SCodeEnv.getEnvName(inClassEnv);
        Debug.traceln("SCodeAnalyseRedeclare.getClassExtendsBaseClass failed on " +& name);
      then
        fail();

  end matchcontinue;
end getClassExtendsBaseClass;

protected function mkInfos
  input list<tuple<Item, Env>> inPreviousItems;
  input Infos inInfosAcc;
  output Infos outInfos;
algorithm
  outInfos := matchcontinue(inPreviousItems, inInfosAcc)
    local 
      list<tuple<Item, Env>> rest;
      Item i; Env e;
    
    case ({}, _) then filterInfos(inInfosAcc, {});
    
    case ((i, e)::rest, _) then mkInfos(rest, RI(i, e)::inInfosAcc);
  
  end matchcontinue;
end mkInfos;

protected function filterInfos
"remove  RP({})"
  input Infos inInfos;
  input Infos inInfosAcc;
  output Infos outInfos;
algorithm
  outInfos := matchcontinue(inInfos, inInfosAcc)
    local 
      Infos rest;
      Info i;
    
    case ({}, _) then inInfosAcc;
    
    case (RP({})::rest, _)
      then filterInfos(rest, inInfosAcc);
  
    case (i::rest, _) 
      then filterInfos(rest, i::inInfosAcc);  
  
  end matchcontinue;
end filterInfos;

public function cleanRedeclareIScopes
  input IScopes inIScopes;
  input IScopes inIScopesAcc;
  output IScopes outIScopes;
  output Boolean hasChanged;
algorithm
  (outIScopes, hasChanged) := matchcontinue(inIScopes, inIScopesAcc)
    local 
      IScope s;
      Kind k;
      Infos i, i1, i2;
      IScopes p, rest, acc, p1, p2;
      Boolean b, b1, b2;
      Absyn.Path n1, n2;
      Element c, e;
      Env env;
      Absyn.TypeSpec ts;
      
    
    case ({}, _) then (listReverse(inIScopesAcc), false);
    
    // extends with no kids has no meaning
    case (IS(kind = EX(_), parts = {})::rest, acc)
      equation
        (acc, b) = cleanRedeclareIScopes(rest, acc);
      then
        (acc, true);
    
    // component targeting a local replaceable derived class
    // replaceable HeatTransfer = Blah.Blah.IdealHeatTransfer;
    // HeatTransfer heatTransfer(redeclare Medium = Medium)
    case (IS(k as CO(_,n1), i1, {IS(CL(n2), i2, p2)})::rest, acc)
      equation
        // same scope!
        //n1 = Absyn.stripLast(n1);
        //n2 = Absyn.stripLast(n2);
        //true = Absyn.pathEqual(n1, n2);
        EI(e, env) = getEIFromInfos(i1);
        EI(c, _) = getEIFromInfos(i2);
        ts = SCode.getDerivedTypeSpec(c);
        e = SCode.setComponentTypeSpec(e, ts);
        i1 = listAppend(i1, i2);
        i1 = {EI(e, env)}; //::i1;
        s = IS(k, i1, p2);
        (acc, b) = cleanRedeclareIScopes(rest, s::acc);
      then
        (acc, true);
        
    // components with no kids, check the redeclares
    case (IS(k as CO(_,_), i, {})::rest, acc)
      equation
        i = replaceCompEIwithRI(i);
        (acc, b) = cleanRedeclareIScopes(rest, IS(k, i, {})::acc);
      then
        (acc, false);
    
    // class with no kids, check the redeclares
    case (IS(k as CL(_), i, {})::rest, acc)
      equation
        i = replaceClassEIwithRI(i);
        (acc, b) = cleanRedeclareIScopes(rest, IS(k, i, {})::acc);
      then
        (acc, false);    
    
    /*/ classes with no kids, and no redeclares have no meaning
    case (IS(k as CL(_), i, {})::rest, acc)
      equation
        {} = getRIsFromInfos(i, {});
        (acc, b) = cleanRedeclareIScopes(rest, acc);
      then
        (acc, true);*/
            
    // the kids got cleaned, try the parent again
    case (IS(k, i, p)::rest, acc)
      equation
        (p, b1) = cleanRedeclareIScopes(p, {});
        s = IS(k, i, p);
        (acc, b2) = cleanRedeclareIScopes(rest, s::acc);
        b = boolOr(b1, b2);
      then
        (acc, b);
    
  end matchcontinue;
end cleanRedeclareIScopes;

public function fixpointCleanRedeclareIScopes
  input IScopes inIScopes;
  output IScopes outIScopes;
algorithm
  outIScopes := matchcontinue(inIScopes)
    local IScopes i;
    
    // no more changes
    case (_)
      equation
        (i, false) = cleanRedeclareIScopes(inIScopes, {});
      then 
        i;

    // some changes, try again
    case (_)
      equation
        (i, true) = cleanRedeclareIScopes(inIScopes, {});
        i = fixpointCleanRedeclareIScopes(i);
      then 
        i;    

  end matchcontinue;
end fixpointCleanRedeclareIScopes;

public function replaceCompEIwithRI
  input Infos inInfos;
  output Infos outInfos;
algorithm
  outInfos := matchcontinue(inInfos)
    local Infos infos; Info info; Env env, denv; Element e,c; Absyn.TypeSpec ts;
    // use the component from the redeclare
    case (_)
      equation
        EI(e, env) = getEIFromInfos(inInfos);
        RI(SCodeEnv.REDECLARED_ITEM(SCodeEnv.VAR(e, _), denv), env) = getRIFromInfos(inInfos);
        infos = EI(e, env)::inInfos;
      then
        infos;
    // use the type from the redeclare
    case (_)
      equation
        EI(e, env) = getEIFromInfos(inInfos);
        RI(SCodeEnv.REDECLARED_ITEM(SCodeEnv.CLASS(c, _, _), denv), _) = getRIFromInfos(inInfos);
        ts = SCode.getDerivedTypeSpec(c);
        (_, ts, denv) = SCodeLookup.lookupTypeSpec(ts, denv, SCode.elementInfo(e));
        ts = SCodeEnv.mergeTypeSpecWithEnvPath(ts, denv);
        e = SCode.setComponentTypeSpec(e, ts);
        infos = EI(e, env)::inInfos;
      then
        infos;
  end matchcontinue;
end replaceCompEIwithRI;

public function replaceClassEIwithRI
  input Infos inInfos;
  output Infos outInfos;
algorithm
  outInfos := matchcontinue(inInfos)
    local 
      Infos infos; 
      Info info; 
      Env env, denv; 
      Element e,c;
      SCode.Prefixes p;
      Absyn.TypeSpec ts;

    // use the class from the redeclare, fully qualify derived
    case (_)
      equation
        EI(e, env) = getEIFromInfos(inInfos);
        RI(SCodeEnv.REDECLARED_ITEM(SCodeEnv.CLASS(e, _, _), denv), env) = getRIFromInfos(inInfos);
        true = SCode.isDerivedClass(e);
        ts = SCode.getDerivedTypeSpec(e);
        (_, ts, denv) = SCodeLookup.lookupTypeSpec(ts, denv, SCode.elementInfo(e));
        ts = SCodeEnv.mergeTypeSpecWithEnvPath(ts, denv);
        e = SCode.setDerivedTypeSpec(e, ts);
        p = SCode.elementPrefixes(e);
        p = SCode.prefixesSetRedeclare(p, SCode.NOT_REDECLARE());
        e = SCode.setClassPrefixes(p, e);
        infos = EI(e, env)::inInfos;
      then
        infos;

    // use the class from the redeclare
    case (_)
      equation
        EI(e, env) = getEIFromInfos(inInfos);
        RI(SCodeEnv.REDECLARED_ITEM(SCodeEnv.CLASS(e, denv, _), _), env) = getRIFromInfos(inInfos);
        p = SCode.elementPrefixes(e);
        p = SCode.prefixesSetRedeclare(p, SCode.NOT_REDECLARE());
        e = SCode.setClassPrefixes(p, e);
        infos = EI(e, env)::inInfos;
      then
        infos;
  
  end matchcontinue;
end replaceClassEIwithRI;

public function filterRedeclareIScopes
  input IScopes inIScopes;
  input IScopes inIScopesAcc;
  output IScopes outIScopes;
algorithm
  outIScopes := matchcontinue(inIScopes, inIScopesAcc)
    local 
      IScope s;
      Kind k;
      Infos i;
      IScopes p, rest, acc;
    
    case ({}, _) then listReverse(inIScopesAcc);
    
    case (IS(k, i, p)::rest, acc)
      equation
        // maybe we should keep all childrens if there is a redeclare on the path?
        p = filterRedeclareIScopes(p, {});
        s = IS(k, i, p);
        acc = Util.if_(hasRedeclares(s), s::acc, acc);
        acc = filterRedeclareIScopes(rest, acc);
      then
        acc;
    
  end matchcontinue;
end filterRedeclareIScopes;

public function hasRedeclares
  input IScope inIScope;
  output Boolean hasRedecl;
algorithm
  hasRedecl := matchcontinue(inIScope)
    local 
      IScope rest; 
      Boolean b, b1, b2; 
      IScopes p;
      Absyn.Path n;
      Infos infos;
    
    case (IS(kind = RE(_))) then true;
    case (IS(kind = EX(n)))
      equation
        true = intNe(System.stringFind(Absyn.pathLastIdent(n), "$base"), -1);
      then
        true;
    case (IS(parts = p, infos = infos))
      equation
        b1 = hasRedeclareInfos(infos);
        b2 = List.applyAndFold(p, boolOr, hasRedeclares, false);
        b = boolOr(b1, b2); 
      then 
        b;
    
    else false;
  
  end matchcontinue;
end hasRedeclares;

protected function hasRedeclareInfos
"searches for RP(_) or RI(_)"
  input Infos inInfos;
  output Boolean hasRedeclares;
algorithm
  hasRedeclares := matchcontinue(inInfos)
    local 
      Infos rest;
    
    case ({}) then false;
    
    case (RP(_::_)::rest) then true;
    case (RI(_,_)::rest) then true;
  
    case (_::rest) 
      then hasRedeclareInfos(rest);  
  
  end matchcontinue;
end hasRedeclareInfos;

public function collapseDerivedClassChain
"@author:adrpo 
 CL(replaceable X = X)
  CL(redeclare X = X)
   CL(redeclare X = Y)
    CL(Y class with parts) 
 is collapsed to:
 CL(X=Y) and element prefixes are merged"
  input IScopes inIScopes;
  input IScopes inIScopesAcc;
  output IScopes outIScopes;
algorithm
  outIScopes := matchcontinue(inIScopes, inIScopesAcc)
    local 
      IScope s;
      Kind k;
      Infos i;
      IScopes p, rest, acc;
    
    case ({}, _) then listReverse(inIScopesAcc);
    
    case ((s as IS(k, i, p))::rest, acc)
      equation
        true = SCode.isDerivedClass(getElementFromIScope(s));
        s = mergeDerivedClasses(s::p);
        acc = collapseDerivedClassChain(rest, s::acc);
      then
        acc;
    
    case ((s as IS(k, i, p))::rest, acc)
      equation
        p = collapseDerivedClassChain(p, {});
        acc = collapseDerivedClassChain(rest, IS(k, i, p)::acc);
      then
        acc;
    
  end matchcontinue;
end collapseDerivedClassChain;

public function mergeDerivedClasses
  input IScopes inIScopes;
  output IScope outIScope;
algorithm
  outIScope := matchcontinue(inIScopes)
    local 
      IScope s, last;
      Element e, eLast;
      IScopes ilist, p, rest;
      Program elements;
      Absyn.Path derivedPath;
      Kind k;
      Infos i, ni;
      Env env, envLast;
    
    case ((s as IS(k, i, p))::rest)
      equation
        EI(e, env) = getEIFromIScope(s);
        true = SCode.isDerivedClass(e);
        // at least one
        (ilist as _::_) = getDerivedIScopes(rest, {});
        // start with original and fold derived prefixes on to it.
        e = List.applyAndFold(ilist, SCodeFlattenRedeclare.propagateAttributesClass, getElementFromIScope, e);
        last = List.last(ilist);
        EI(eLast,envLast) = getEIFromIScope(last);
        // a = a, a = c, c = d, d = e -> a = e 
        // TODO FIXME do we need to merge also mods and array dims??!!
        e = SCode.setDerivedTypeSpec(e, SCode.getDerivedTypeSpec(eLast));
        e = removeRedeclareMods(e);
        ni = List.applyAndFold(ilist, listAppend, iScopeInfos, i);
        ni = listReverse(ni);
        ni = EI(e, env)::ni;
        // replace parts with the last one
        p = iScopeParts(last);
        p = collapseDerivedClassChain(p, {});
        s = IS(k, ni, p);
      then
        s;
          
  end matchcontinue;
end mergeDerivedClasses;

public function removeRedeclareMods
  input Element inElement;
  output Element outElement;
algorithm
  outElement := matchcontinue(inElement)
    local
      Element e;
      String n;
      SCode.Prefixes p;
      SCode.Encapsulated ep;
      SCode.Partial pp;
      SCode.Restriction rp;
      SCode.ClassDef cd;
      Absyn.Info i;
      SCode.Attributes a;
      Absyn.TypeSpec t;
      SCode.Mod m;
      Option<SCode.Comment> cmt;
      Option<Absyn.Exp> cnd;
      SCode.Visibility v;
      Option<SCode.Annotation> ann;
      Prefix prefix;
      Absyn.Path bcp;
    
    case (SCode.CLASS(n, p, ep, pp, rp, cd, i))
      equation
        //p = SCode.prefixesSetRedeclare(p, SCode.NOT_REDECLARE());
        //p = SCode.prefixesSetReplaceable(p, SCode.NOT_REPLACEABLE());
        cd = removeRedeclareModsFromClassDef(cd);
        e = SCode.CLASS(n, p, ep, pp, rp, cd, i);
      then
        e;
        
    case (SCode.COMPONENT(n, p, a, t, m, cmt, cnd, i))
      equation
        p = SCode.prefixesSetRedeclare(p, SCode.NOT_REDECLARE());
        //p = SCode.prefixesSetReplaceable(p, SCode.NOT_REPLACEABLE());
        m = SCodeMod.removeRedeclaresFromMod(m);
        e = SCode.COMPONENT(n, p, a, t, m, cmt, cnd, i);
      then
        e;
    
    case (SCode.EXTENDS(bcp, v, m, ann, i))
      equation
        m = SCodeMod.removeRedeclaresFromMod(m);
        e = SCode.EXTENDS(bcp, v, m, ann, i);
      then
        e;
                
  end matchcontinue;
end removeRedeclareMods;

protected function removeRedeclareModsFromClassDef
  input SCode.ClassDef inClassDef;
  output SCode.ClassDef outClassDef;
algorithm
  outClassDef := matchcontinue(inClassDef)
    local
      list<Element> el;
      list<SCode.Equation> eq;
      list<SCode.Equation> ieq;
      list<SCode.AlgorithmSection> alg;
      list<SCode.AlgorithmSection> ialg;
      list<SCode.ConstraintSection> cs;
      list<Absyn.NamedArg> clsattr;
      Option<SCode.ExternalDecl> ed;
      list<SCode.Annotation> al;
      Option<SCode.Comment> cmt;
      SCode.ClassDef cd;
      Absyn.TypeSpec t;
      SCode.Mod m;
      SCode.Attributes a;
      Absyn.Path p;
      String n;
      Boolean b;
      list<Program> els;
      
    case (SCode.PARTS(el, eq, ieq, alg, ialg, cs, clsattr, ed, al, cmt))
      equation
        cd = SCode.PARTS(el, eq, ieq, alg, ialg, cs, clsattr, ed, al, cmt);
      then
        cd;
        
    case (SCode.CLASS_EXTENDS(n, m, cd))
      equation
        m = SCodeMod.removeRedeclaresFromMod(m);
        cd = removeRedeclareModsFromClassDef(cd);
        cd = SCode.CLASS_EXTENDS(n, m, cd);
      then
        cd;

    case (SCode.DERIVED(t, m, a, cmt))
      equation
        m = SCodeMod.removeRedeclaresFromMod(m);
        cd = SCode.DERIVED(t, m, a, cmt);
      then
        cd;

    case (cd as SCode.ENUMERATION(enumLst = _))
      then
        cd;
        
    case (cd as SCode.OVERLOAD(pathLst = _))
      then
        cd;

    case (cd as SCode.PDER(functionPath = _))
      then
        cd;
  end matchcontinue;
end removeRedeclareModsFromClassDef;

public function getDerivedIScopes
  input IScopes inIScopes;
  input IScopes inIScopesAcc;
  output IScopes outIScopes;
algorithm
  outIScopes := matchcontinue(inIScopes, inIScopesAcc)
    local 
      IScope s;
      Element e;
      IScopes ilist, acc;
    
    // this might be an error!
    case ({}, _) then listReverse(inIScopesAcc);
    
    case ({s}, acc)
      equation
        e = getElementFromIScope(s);
        true = SCode.isDerivedClass(e);
        acc = getDerivedIScopes(iScopeParts(s), s::acc);
      then
        acc;

    case ({s}, _)
      equation
        e = getElementFromIScope(s);
        false = SCode.isDerivedClass(e);
      then
        listReverse(inIScopesAcc);

    else inIScopes;
  
  end matchcontinue;
end getDerivedIScopes;

public function iScopeInfos
  input IScope inIScope;
  output Infos outInfos;
algorithm
  outInfos := matchcontinue(inIScope)
    local Infos infos;
    case (IS(infos = infos)) then infos;    
  end matchcontinue;
end iScopeInfos;

public function iScopeParts
  input IScope inIScope;
  output IScopes outIScopes;
algorithm
  outIScopes := matchcontinue(inIScope)
    local IScopes parts;
    case (IS(parts = parts)) then parts;    
  end matchcontinue;
end iScopeParts;

public function iScopeKind
  input IScope inIScope;
  output Kind outKind;
algorithm
  outKind := matchcontinue(inIScope)
    local Kind kind;
    case (IS(kind = kind)) then kind;    
  end matchcontinue;
end iScopeKind;

protected function printIScopes
  input IScopes inIScopes;
algorithm
  _ := matchcontinue(inIScopes)
    local
      IScopes rest;
      IScope is;
    
    
    case (_)
      equation
        false = Flags.isSet(Flags.SHOW_REDECLARE_ANALYSIS); 
      then ();
    
    case ({})
      equation
        print("\n"); 
      then ();
    
    case (is::rest)
      equation
        printIScopeIndent(is, 1);
        printIScopes(rest);
      then 
        ();
        
    else equation 
      print("Left: " +& intString(listLength(inIScopes)) +& "\n");
    then ();
  
  end matchcontinue;
end printIScopes;

public function iScopesStrNoParts
  input IScopes inIScopes;
  output String outStr;
algorithm
  outStr := stringDelimitList(List.map(inIScopes, iScopeStrNoParts), ".");  
end iScopesStrNoParts;

protected function iScopeStrNoParts
  input IScope inIScope;
  output String outStr;
algorithm
  outStr := matchcontinue(inIScope)
    local
      Infos i;
      Kind k;
      IScopes p;
      String si, sk, ski, s, str;
    
    case (IS(k, i, p))
      equation
        {sk, ski} = kindStr(k);
        str = sk +& "(" +& ski +& ")";
      then
        str;
    
  end matchcontinue; 
end iScopeStrNoParts;

public function kindStr
  input Kind inKind;
  output list<String> outStrings;
algorithm
  outStrings := match(inKind)
    local
      Absyn.Path n;
      Prefix p;
      String s;

    case (CL(n)) 
      equation 
        s = Absyn.pathString(n); 
      then {"CL",s};
        
    case (CO(p,n)) 
      equation 
        s = InstUtil.prefixToStrNoEmpty(p) +& "/" +& Absyn.pathString(n); 
      then {"CO",s};
    
    case (EX(n)) 
      equation 
        s = Absyn.pathString(n); 
      then 
        {"EX",s};
    
    case (RE(n)) 
      equation 
        s = Absyn.pathString(n); 
      then {"RE",s};
    
  end match;
end kindStr;

public function iScopeStr
  input IScope inIScope;
  output String outStr;
algorithm
  outStr := matchcontinue(inIScope)
    local
      Infos i;
      Kind k;
      IScopes p;
      String si, sk, ski, s, str;
    
    case (IS(k, i, p))
      equation
        si = infosStr(i);
        si = Util.if_(stringEq(si, ""), "", ", " +& si);
        {sk, ski} = kindStr(k);
        str = sk +& "(" +& ski +& si +& ")\n\t";
        str = str +& stringDelimitList(List.map(p, iScopeStr), "\n\t");
      then
        str;
    
  end matchcontinue;
end iScopeStr;

protected function iScopeStrIndent
  input IScope inIScope;
  input Integer inIncrement;
  output String outStr;
algorithm
  outStr := matchcontinue(inIScope, inIncrement)
    local
      Infos i;
      Kind k;
      IScopes p;
      String si, sk, ski, indent, str;
    
    case (IS(k, i, p as {}), _)
      equation
        indent = stringAppendList(List.fill(" ", inIncrement));
        si = infosStr(i);
        si = Util.if_(stringEq(si, ""), "", ", " +& si);
        {sk, ski} = kindStr(k);
        str = indent +& sk +& "(" +& ski +& si +& ")";
      then
        str;
  
    case (IS(k, i, p), _)
      equation
        indent = stringAppendList(List.fill(" ", inIncrement));
        si = infosStr(i);
        si = Util.if_(stringEq(si, ""), "", ", " +& si);
        {sk, ski} = kindStr(k);
        str = indent +& sk +& "(" +& ski +& si +& ")" +& "\n" +& indent +&
              stringDelimitList(
                List.map1(p, iScopeStrIndent, inIncrement + 1), 
                "\n" +& indent);
      then
        str;
  
  end matchcontinue;
end iScopeStrIndent;

public function infosStr
  input Infos inInfos;
  output String outStr;
algorithm
  outStr := matchcontinue(inInfos)
    local
      Absyn.Path n;
      Prefix p;
      Infos rest;
      String str;
      Replacements replacements;
      Env env;
      Element e;
      Item i;
    
    case ({}) then "";
    case (RP(replacements as _::_)::rest)
      equation
        str = stringDelimitList(List.map(replacements, replacementStr), "/") +& " ";
        str = str +& infosStr(rest);
      then 
        str;
    case (EI(e, env)::rest)
      equation
        // str = "EI(" +& SCodeEnv.getEnvName(env) +& "/" +& SCodeDump.unparseElementStr(e) +& ") ";
        str = "EI(" +& SCodeEnv.getEnvName(env) +& "/" +& SCodeDump.shortElementStr(e) +& ") ";
        str = str +& infosStr(rest);
      then 
        str;
    case (RI(i, env)::rest)
      equation
        str = redeclareInfoStr(i, env) +& " ";
        str = str +& infosStr(rest);
      then 
        str;
    case (_::rest) then infosStr(rest);
    
  end matchcontinue;
end infosStr;

public function getElementFromInfos
  input Infos inInfos;
  output Element outElement;
algorithm
  outElement := matchcontinue(inInfos)
    local
      Infos rest;
      Element e;
    
    case (EI(e, _)::rest) then e;
    case (_::rest) then getElementFromInfos(rest);
    
  end matchcontinue;
end getElementFromInfos;

public function getElementFromIScope
  input IScope inScope;
  output Element outElement;
algorithm
  outElement := getElementFromInfos(iScopeInfos(inScope));
end getElementFromIScope;

public function getEnvFromIScope
  input IScope inScope;
  output Env outEnv;
algorithm
  outEnv := getEnvFromInfos(iScopeInfos(inScope));
end getEnvFromIScope;

public function getEnvFromInfos
  input Infos inInfos;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inInfos)
    local
      Infos rest;
      Env e;
    
    case (EI(_, e)::rest) then e;
    case (_::rest) then getEnvFromInfos(rest);
    
  end matchcontinue;
end getEnvFromInfos;

public function getEIFromIScope
  input IScope inScope;
  output Info outInfo;
algorithm
  outInfo := getEIFromInfos(iScopeInfos(inScope));
end getEIFromIScope;

public function getEIFromInfos
  input Infos inInfos;
  output Info outInfo;
algorithm
  outInfo := matchcontinue(inInfos)
    local
      Infos rest;
      Info i;
    
    case ((i as EI(env = _))::rest) then i;
    case (_::rest) then getEIFromInfos(rest);
    
  end matchcontinue;
end getEIFromInfos;

public function getEIsFromInfos
  input Infos inInfos;
  input Infos inInfosAcc;
  output Infos outInfos;
algorithm
  outInfos := matchcontinue(inInfos, inInfosAcc)
    local
      Infos rest, infos;
      Info i;
    
    case ({}, _) then listReverse(inInfosAcc);
    
    case ((i as EI(env = _))::rest, _)
      equation
        infos = getEIsFromInfos(rest, i::inInfosAcc);
      then 
        infos;
    
    case (_::rest, _) 
      then getEIsFromInfos(rest, inInfosAcc);
    
  end matchcontinue;
end getEIsFromInfos;

public function getRIsFromInfos
  input Infos inInfos;
  input Infos inInfosAcc;
  output Infos outInfos;
algorithm
  outInfos := matchcontinue(inInfos, inInfosAcc)
    local
      Infos rest, infos;
      Info i;
    
    case ({}, _) then listReverse(inInfosAcc);
    
    case ((i as RI(env = _))::rest, _)
      equation
        infos = getRIsFromInfos(rest, i::inInfosAcc);
      then 
        infos;
    
    case (_::rest, _) 
      then getRIsFromInfos(rest, inInfosAcc);
    
  end matchcontinue;
end getRIsFromInfos;

public function getRIFromIScope
  input IScope inScope;
  output Info outInfo;
algorithm
  outInfo := getRIFromInfos(iScopeInfos(inScope));
end getRIFromIScope;

public function getRIFromInfos
  input Infos inInfos;
  output Info outInfo;
algorithm
  outInfo := matchcontinue(inInfos)
    local
      Infos rest;
      Info i;
    
    case ((i as RI(env = _))::rest) then i;
    case (_::rest) then getRIFromInfos(rest);
    
  end matchcontinue;
end getRIFromInfos;

protected function replacementStr
  input Replacement inReplacement;
  output String outStr;
algorithm
  outStr := matchcontinue(inReplacement)
    local
      SCode.Ident nm;
      Item o;
      Item n;
      Env e;
      list<Absyn.Path> bc;
      SCodeEnv.ExtendsTable eto;
      SCodeEnv.ExtendsTable etn;
      String str;
      
    case (SCodeFlattenRedeclare.REPLACED(nm, o, n, e))
      equation
        str = "E(" +& SCodeEnv.getEnvName(e) +& ")." +&
              "Old(" +& itemShortStr(o) +& ").E(" +& SCodeEnv.getEnvName(SCodeEnv.getItemEnvNoFail(o)) +& ")/" +&
              "New(" +& itemShortStr(n) +& ").E(" +& SCodeEnv.getEnvName(SCodeEnv.getItemEnvNoFail(n)) +& ")"; 
      then
        str;
    
    case (SCodeFlattenRedeclare.PUSHED(nm, n, bc, eto, etn, e))
      equation
        str = "New(" +& itemShortStr(n) +& ").E(" +& SCodeEnv.getEnvName(SCodeEnv.getItemEnvNoFail(n)) +& ")." +& 
              "BC(" +& stringDelimitList(List.map(bc, Absyn.pathString), "|") +& ").E(" +& SCodeEnv.getEnvName(e) +& ")";
      then
        str;
  
  end matchcontinue;
end replacementStr;

protected function redeclareInfoStr
  input Item inItem;
  input Env inEnv;
  output String outStr;
algorithm
  outStr := matchcontinue(inItem, inEnv)
    local
      Item i;
      Env de;
      String str;
      
    case (SCodeEnv.REDECLARED_ITEM(i, de), _)
      equation
        str = "REDECLARED(" +& itemShortStr(i) +& ").DECL_ENV(" +& SCodeEnv.getEnvName(de) +& ")." +&
              "LOOKUP_ENV(" +& SCodeEnv.getEnvName(inEnv) +& ")"; 
      then
        str;
    
    case (i, _)
      equation
        str = "REDECLARED(" +& itemShortStr(i) +& ").LOOKUP_ENV(" +& SCodeEnv.getEnvName(inEnv) +& ")"; 
      then
        str;
      
  end matchcontinue;
end redeclareInfoStr;

public function itemShortStr
"Returns more info on an environment item."
  input Item inItem;
  output String outName;
algorithm
  outName := matchcontinue(inItem)
    local 
      String name, alias_str;
      SCode.Element el;
      Absyn.Path path;
      Item item;

    case SCodeEnv.VAR(var = el) 
      then List.first(System.strtok(SCodeDump.unparseElementStr(el), "\n"));
    case SCodeEnv.CLASS(cls = el) 
      then List.first(System.strtok(SCodeDump.unparseElementStr(el), "\n"));
    case SCodeEnv.ALIAS(name = name, path = SOME(path))
      equation
        alias_str = Absyn.pathString(path);
      then
        "alias " +& name +& " -> (" +& alias_str +& "." +& name +& ")";
    case SCodeEnv.ALIAS(name = name, path = NONE())
      then "alias " +& name +& " -> ()";
    case SCodeEnv.REDECLARED_ITEM(item = item)
      equation
        name = itemShortStr(item);
      then
        "redeclared " +& name;
    
    else "UNHANDLED ITEM";
      
  end matchcontinue;
end itemShortStr;

public function mkIScope
  input Kind k;
  input Infos i;
  input IScopes p;
  output IScope iscope;
algorithm
  iscope := IS(k, i, p);
end mkIScope;

public function instScopesDepth
  input IScopes inIScopes;
  output Integer depth;
algorithm
  depth := List.applyAndFold(inIScopes, intMax, iScopeDepth, 0);
end instScopesDepth;

public function iScopeDepth
  input IScope inIScope;
  output Integer depth;
algorithm
  depth := match(inIScope)
    local
      IScopes p;
      Integer n;
      
    case (IS(parts = {})) then 0;
    case (IS(parts = p))
      equation
        n = 1 + List.applyAndFold(p, intMax, iScopeDepth, 0);
      then
        n; 
  end match;
end iScopeDepth;

public function iScopeSize
  input IScopes inIScopes;
  output Integer depth;
algorithm
  depth := match(inIScopes)
    local
      IScopes p, rest;
      Integer n;
      
    case ({}) then 1;
    case (IS(parts = p)::rest)
      equation
        n = iScopeSize(p) + iScopeSize(rest);
      then
        n; 
  end match;
end iScopeSize;

protected function printIScopeIndent
  input IScope inIScope;
  input Integer inIncrement;
algorithm
  _ := matchcontinue(inIScope, inIncrement)
    local
      Infos i;
      Kind k;
      IScopes p;
      String si, sk, ski, indent, str;
    
    case (IS(k, i, p as {}), _)
      equation
        indent = stringAppendList(List.fill(" ", inIncrement));
        si = infosStr(i);
        si = Util.if_(stringEq(si, ""), "", ", " +& si);
        {sk, ski} = kindStr(k);
        str = indent +& sk +& "(" +& ski +& si +& ")";
        print(str);
      then
        ();
  
    case (IS(k, i, p), _)
      equation
        indent = stringAppendList(List.fill(" ", inIncrement));
        si = infosStr(i);
        si = Util.if_(stringEq(si, ""), "", ", " +& si);
        {sk, ski} = kindStr(k);
        str = indent +& sk +& "(" +& ski +& si +& ")" +& "\n" +& indent;
        print(str);
        printIScopesIndent(p, inIncrement + 1, "\n" +& indent);
      then
        ();
  
  end matchcontinue;
end printIScopeIndent;

protected function printIScopesIndent
  input IScopes inIScopes;
  input Integer inIncrement;
  input String delimiter;
algorithm
  _ := matchcontinue(inIScopes, inIncrement, delimiter)
    local
      IScopes p;
      IScope s;
    
    case ({}, _, _) then ();

    case ({s}, _, _)
      equation
        printIScopeIndent(s, inIncrement);
      then ();
    
    case (s::p, _, _)
      equation
        printIScopeIndent(s, inIncrement);
        print(delimiter);
        printIScopesIndent(p, inIncrement, delimiter);
      then
        ();
        
  end matchcontinue;
end printIScopesIndent;

protected function sortParts
  input IScopes inScopes;
  output IScopes outScopes;
protected
  IScopes cl, co, ex;
algorithm
  (cl, co, ex) := splitParts(inScopes, {}, {}, {}); 
  outScopes := listAppend(cl, listAppend(co, ex)); 
end sortParts;

protected function splitParts
  input IScopes inScopes;
  input IScopes inScopesAccCL;
  input IScopes inScopesAccCO;
  input IScopes inScopesAccEX;
  output IScopes outScopesCL;
  output IScopes outScopesCO;
  output IScopes outScopesEX;
algorithm
  (outScopesCL, outScopesCO, outScopesEX) := matchcontinue(inScopes, inScopesAccCL, inScopesAccCO, inScopesAccEX)
    local
      IScopes rest, cl, co, ex;
      IScope i;    
    
    case ({}, _, _, _) then (listReverse(inScopesAccCL), listReverse(inScopesAccCO), listReverse(inScopesAccEX));
    
    // class put it in CL list
    case ((i as IS(kind = CL(_)))::rest, _, _, _)
      equation
        (cl, co, ex) = splitParts(rest, i::inScopesAccCL, inScopesAccCO, inScopesAccEX);
      then
        (cl, co, ex);
    
    // component put it co list
    case ((i as IS(kind = CO(_,_)))::rest, _, _, _)
      equation
        (cl, co, ex) = splitParts(rest, inScopesAccCL, i::inScopesAccCO, inScopesAccEX);
      then
        (cl, co, ex);

    // extend sput it in ex list
    case ((i as IS(kind = EX(_)))::rest, _, _, _)
      equation
        (cl, co, ex) = splitParts(rest, inScopesAccCL, inScopesAccCO, i::inScopesAccEX);
      then
        (cl, co, ex);
  end matchcontinue;
end splitParts;

public function isLocal
  input IScopes inParentIScopes;
  output Boolean isL;
algorithm
  isL := match(inParentIScopes)
    // if parent scope is a class then the declaration is local
    case ({_}) then false;
    case (_::IS(kind = CL(_))::_) then true;
    else false;
  end match;
end isLocal;

public function isReferenced
"true if the scope is referenced from extends or component type"
  input IScopes inParentIScopes;
  output Boolean isRef;
algorithm
  isRef := match(inParentIScopes)
    // if parent scope is a component or extends
    case ({_}) then true;
    case (_::IS(kind = CO(_,_))::_) then true;
    case (_::IS(kind = EX(_))::_) then true;
    else false;
  end match;
end isReferenced;


end SCodeAnalyseRedeclare;

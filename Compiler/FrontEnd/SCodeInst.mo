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

encapsulated package SCodeInst
" file:        SCodeInst.mo
  package:     SCodeInst
  description: SCode instantiation

  RCS: $Id$

  Prototype SCode instantiation, enable with +d=scodeInst.
"

public import Absyn;
public import SCodeEnv;

protected import Dump;
protected import List;
protected import SCode;
protected import SCodeDump;
protected import SCodeLookup;
protected import SCodeFlattenRedeclare;
protected import System;
protected import Util;

public type Env = SCodeEnv.Env;
protected type Item = SCodeEnv.Item;

protected type Prefix = list<tuple<String, Absyn.ArrayDim>>;

public function instClass
  "Flattens a class and prints out an estimate of how many variables there are."
  input Absyn.Path inClassPath;
  input Env inEnv;
protected
algorithm
  _ := match(inClassPath, inEnv)
    local
      Item item;
      Absyn.Path path;
      Env env; 
      String name;
      Integer var_count;

    case (_, _)
      equation
        System.startTimer();
        name = Absyn.pathLastIdent(inClassPath);
        print("class " +& name +& "\n");
        (item, path, env) = 
          SCodeLookup.lookupClassName(inClassPath, inEnv, Absyn.dummyInfo);
        var_count = instClassItem(item, env, {});
        print("end " +& name +& ";\n");
        System.stopTimer();
        print("SCodeInst took " +& realString(System.getTimerIntervalTime()) +&
          " seconds.\n");
        print("Found at least " +& intString(var_count) +& " variables.\n");
      then
        ();

  end match;
end instClass;

protected function instClassItem
  input Item inItem;
  input Env inEnv;
  input Prefix inPrefix;
  output Integer outVarCount;
algorithm
  outVarCount := match(inItem, inEnv, inPrefix)
    local
      list<SCode.Element> el;
      list<Integer> var_counts;
      Integer var_count;
      Absyn.TypeSpec ty;
      Item item;
      Env env;
      Absyn.Info info;
      SCodeEnv.AvlTree cls_and_vars;
      String name;

    // A class with parts, instantiate all elements in it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name, classDef = SCode.PARTS(elementLst = el)), 
        env = {SCodeEnv.FRAME(clsAndVars = cls_and_vars)}), _, _)
      equation
        env = SCodeEnv.mergeItemEnv(inItem, inEnv);
        el = List.map1(el, lookupElement, cls_and_vars);
        var_counts = List.map2(el, instElement, env, inPrefix);
        var_count = List.fold(var_counts, intAdd, 0);
      then
        var_count;

    // A derived class, look up the inherited class and instantiate it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef =
        SCode.DERIVED(typeSpec = ty), info = info)), _, _)
      equation
        (item, env) = SCodeLookup.lookupTypeSpec(ty, inEnv, info);
      then
        instClassItem(item, env, inPrefix);

    else 0;
  end match;
end instClassItem;

protected function lookupElement
  "This functions might seem a little odd, why look up elements in the
   environment when we already have them? This is because they might have been
   redeclared, and redeclares are only applied to the environment and not the
   SCode itself. So we need to look them up in the environment to make sure we
   have the right elements."
  input SCode.Element inElement;
  input SCodeEnv.AvlTree inEnv;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement, inEnv)
    local
      String name;
      SCode.Element el;

    case (SCode.COMPONENT(name = name), _)
      equation
        SCodeEnv.VAR(var = el) = SCodeEnv.avlTreeGet(inEnv, name);
      then
        el;

    // Only components need to be looked up. Extends are not allowed to be
    // redeclared, while classes are not instantiated by instElement.
    else inElement;
  end match;
end lookupElement;
        
protected function instElement
  input SCode.Element inVar;
  input Env inEnv;
  input Prefix inPrefix;
  output Integer outVarCount;
algorithm
  outVarCount := match(inVar, inEnv, inPrefix)
    local
      String name,str;
      Absyn.TypeSpec ty;
      Absyn.Info info;
      Item item;
      Env env;
      Absyn.Path path;
      Absyn.ArrayDim ad;
      Prefix prefix;
      Integer var_count, dim_count;
      SCode.Mod mod;
      list<SCodeEnv.Redeclaration> redecls;
      SCodeEnv.ExtendsTable exts;

    // A component, look up it's type and instantiate that class.
    case (SCode.COMPONENT(name = name, attributes = SCode.ATTR(arrayDims = ad),
            typeSpec = Absyn.TPATH(path = path), modifications = mod, info = info), _, _)
      equation
        //print("Component: " +& name +& "\n");
        //print("Modifier: " +& printMod(mod) +& "\n");
        (item, path, env) = SCodeLookup.lookupClassName(path, inEnv, info);
        // Apply the redeclarations.
        redecls = SCodeFlattenRedeclare.extractRedeclaresFromModifier(mod, inEnv);
        (item, env) =
          SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, item, env, inEnv);
        prefix = (name, ad) :: inPrefix;
        var_count = instClassItem(item, env, prefix);
        // Print the variable if it's a basic type.
        printVar(prefix, inVar, path, var_count);
        dim_count = countVarDims(ad);

        // Set var_count to one if it's zero, since it counts as an element by
        // itself if it doesn't contain any components.
        var_count = intMax(1, var_count);
        var_count = var_count * dim_count;
        //showProgress(var_count, name, inPrefix, path);
      then
        var_count;

    // An extends, look up the extended class and instantiate it.
    case (SCode.EXTENDS(baseClassPath = path, modifications = mod, info = info),
        SCodeEnv.FRAME(extendsTable = exts) :: _, _)
      equation
        (item, path, env) = SCodeLookup.lookupClassName(path, inEnv, info);
        path = SCodeEnv.mergePathWithEnvPath(path, env);
        // Apply the redeclarations.
        redecls = SCodeFlattenRedeclare.lookupExtendsRedeclaresInTable(path, exts);
        (item, env) =
          SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, item, env, inEnv);
        var_count = instClassItem(item, env, inPrefix);
      then
        var_count;
        
    else 0;
  end match;
end instElement;

protected function printMod
  input SCode.Mod inMod;
  output String outString;
algorithm
  outString := match(inMod)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<SCode.SubMod> submods;
      Option<tuple<Absyn.Exp, Boolean>> binding;
      list<SCode.Element> el;
      String fstr, estr, submod_str, bind_str, el_str;

    case SCode.MOD(fp, ep, submods, binding)
      equation
        fstr = SCodeDump.finalStr(fp);
        estr = SCodeDump.eachStr(ep);
        submod_str = stringDelimitList(List.map(submods, printSubMod), ", ");
        bind_str = printBinding(binding);
      then
        "MOD(" +& fstr +& estr +& "{" +& submod_str +& "})" +& bind_str;

    case SCode.REDECL(fp, ep, el)
      equation
        fstr = SCodeDump.finalStr(fp);
        estr = SCodeDump.eachStr(ep);
        el_str = stringDelimitList(List.map(el, SCodeDump.unparseElementStr), ", ");
      then
        "REDECL(" +& fstr +& estr +& "{" +& el_str +& "})";

    case SCode.NOMOD() then "NOMOD()";
  end match;
end printMod;

protected function printSubMod
  input SCode.SubMod inSubMod;
  output String outString;
algorithm
  outString := match(inSubMod)
    local
      SCode.Mod mod;
      list<SCode.Subscript> subs;
      String id, mod_str, subs_str;

    case SCode.NAMEMOD(ident = id, A = mod)
      equation
        mod_str = printMod(mod);
      then
        "NAMEMOD(" +& id +& " = " +& mod_str +& ")";

    case SCode.IDXMOD(subscriptLst = subs, an = mod)
      equation
        subs_str = Dump.printSubscriptsStr(subs);
        mod_str = printMod(mod);
      then
        "IDXMOD(" +& subs_str +& ", " +& mod_str +& ")";

  end match;
end printSubMod;

protected function printBinding
  input Option<tuple<Absyn.Exp, Boolean>> inBinding;
  output String outString;
algorithm
  outString := match(inBinding)
    local
      Absyn.Exp exp;

    case SOME((exp, _)) then " = " +& Dump.printExpStr(exp);
    else "";
  end match;
end printBinding;
        
protected function showProgress
  input Integer count;
  input String name;
  input Prefix prefix;
  input Absyn.Path path;
algorithm
  _ := matchcontinue(count, name, prefix, path)
    // show only top level components!
    case(count, name, {}, path)
      equation
        print("done: " +& Absyn.pathString(path) +& " " +& name +& "; " +& intString(count) +& " containing variables.\n");
      then ();
    else 
      then ();  
  end matchcontinue;
end showProgress;

protected function printVar
  input Prefix inName;
  input SCode.Element inVar;
  input Absyn.Path inClassPath;
  input Integer inVarCount;
algorithm
  _ := match(inName, inVar, inClassPath, inVarCount)
    local
      String name, cls;
      SCode.Element var;
      SCode.Prefixes pf;
      SCode.Flow fp;
      SCode.Stream sp;
      SCode.Variability vp;
      Absyn.Direction dp;
      SCode.Mod mod;
      Option<SCode.Comment> cmt;
      Option<Absyn.Exp> cond;
      Absyn.Info info;

    // Only print the variable if it doesn't contain any components, i.e. if
    // it's of basic type. This needs to be better checked, since some models
    // might be empty.
    case (_, SCode.COMPONENT(_, pf, 
        SCode.ATTR(_, fp, sp, vp, dp), _, mod, cmt, cond, info), _, 0)
      equation
        name = printPrefix(inName);
        var = SCode.COMPONENT(name, pf, SCode.ATTR({}, fp, sp, vp, dp), 
          Absyn.TPATH(inClassPath, NONE()), mod, cmt, cond, info);
        print("  " +& SCodeDump.unparseElementStr(var) +& ";\n");
      then
        ();

    else ();
  end match;
end printVar;

protected function printPrefix
  input Prefix inPrefix;
  output String outString;
algorithm
  outString := match(inPrefix)
    local
      String id;
      Absyn.ArrayDim dims;
      Prefix rest_pre;

    case {} then "";
    case {(id, dims)} then id +& Dump.printArraydimStr(dims);
    case ((id, dims) :: rest_pre)
      then printPrefix(rest_pre) +& "." +& id +& Dump.printArraydimStr(dims);

  end match;
end printPrefix;

protected function countVarDims
  "Make an attempt at counting the number of components a variable contains."
  input Absyn.ArrayDim inDims;
  output Integer outVarCount;
algorithm
  outVarCount := match(inDims)
    local
      Integer int_dim;
      Absyn.ArrayDim rest_dims;

    // A scalar.
    case ({}) then 1;
    // An array with constant integer subscript.
    case (Absyn.SUBSCRIPT(subscript = Absyn.INTEGER(int_dim)) :: rest_dims)
      then int_dim * countVarDims(rest_dims);
    // Skip everything else for now, were only estimating how many variables
    // there are.
    case (_ :: rest_dims)
      then countVarDims(rest_dims);

  end match;
end countVarDims;
      
end SCodeInst;

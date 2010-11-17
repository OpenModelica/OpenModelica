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

package SCodeFlatten
" file:        SCodeFlatten.mo
  package:     SCodeFlatten
  description: SCode flattening

  RCS: $Id$

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names."

public import Absyn;
public import Env;
public import SCode;

protected import Debug;
protected import Error;
protected import Util;

protected type Import = tuple<String, Absyn.Path>;
protected type ImportTable = list<Import>;

protected uniontype GlobalImport
  record GLOBAL_IMPORT
    String ident;
    Option<Absyn.Path> path;
    list<GlobalImport> imports;
  end GLOBAL_IMPORT;
end GlobalImport;

protected uniontype ImportCache
  record IMPORT_CACHE
    list<Import> cachedImports;
    list<GlobalImport> globalImports;
  end IMPORT_CACHE;
end ImportCache;

public function flatten
  input SCode.Program inSCode;
  output SCode.Program outSCode;

  Env.Env env;
algorithm
  env := Env.extendFrameClasses(Env.newEnvironment(), inSCode);
  (outSCode, _) := flattenProgram(inSCode, env, emptyImportTable(), emptyImportCache());
end flatten;

protected function flattenProgram
  input list<SCode.Class> inClasses;
  input Env.Env inEnv;
  input ImportTable inImportTable;
  input ImportCache inCache;
  output list<SCode.Class> outClasses;
  output ImportCache outCache;
algorithm
  (outClasses, outCache) := match(inClasses, inEnv, inImportTable, inCache)
    local
      ImportTable imports;
      ImportCache cache;
      SCode.Class cls;
      list<SCode.Class> rest_cl;

    case ({}, _, _, _) then ({}, inCache);

    case (cls :: rest_cl, _, _, _)
      equation
        (cls, cache) = flattenClass(cls, inEnv, inImportTable, inCache);
        (rest_cl, cache) = flattenProgram(rest_cl, inEnv, inImportTable, cache);
      then
        (cls :: rest_cl, cache);
  end match;
end flattenProgram;

protected function flattenClass
  input SCode.Class inClass;
  input Env.Env inEnv;
  input ImportTable inImportTable;
  input ImportCache inImportCache;
  output SCode.Class outClass;
  output ImportCache outImportCache;

  SCode.Ident name;
  Boolean part_pre, encap_pre;
  SCode.Restriction restriction;
  SCode.ClassDef cdef;
  Absyn.Info info;
  Env.Env env;
algorithm
  SCode.CLASS(name, part_pre, encap_pre, restriction, cdef, info) := inClass;
  env := Env.openScope(inEnv, true, SOME(name), SOME(Env.CLASS_SCOPE()));
  (cdef, outImportCache) := flattenClassDef(cdef, env, inImportTable, inImportCache);
  outClass := SCode.CLASS(name, part_pre, encap_pre, restriction, cdef, info);
end flattenClass;
   
protected function flattenClassDef
  input SCode.ClassDef inClassDef;
  input Env.Env inEnv;
  input ImportTable inImportTable;
  input ImportCache inImportCache;
  output SCode.ClassDef outClassDef;
  output ImportCache outImportCache;
algorithm
  (outClassDef, outImportCache) := matchcontinue(inClassDef, inEnv,
      inImportTable, inImportCache)
    local
      list<SCode.Element> el, ex, cl, im, co, ud;
      list<SCode.Equation> neql, ieql;
      list<SCode.AlgorithmSection> nal, ial;
      Option<Absyn.ExternalDecl> extdecl;
      list<SCode.Annotation> annl;
      Option<SCode.Comment> cmt;
      ImportTable imports;
      ImportCache cache;
    case (SCode.PARTS(el, neql, ieql, nal, ial, extdecl, annl, cmt), _, _, _)
      equation
        (ex, cl, im, co, ud) = sortElements(el);
        (imports, cache) = addImports(im, inEnv, inImportTable, inImportCache);
        co = Util.listMap2(co, replaceImportsInComponent, imports, cache);
        (cl, cache) = flattenClassDefElements(cl, inEnv, imports, cache);
        el = Util.listReduce({ex, cl, co, ud}, listAppend);
      then
        (SCode.PARTS(el, neql, ieql, nal, ial, extdecl, annl, cmt), cache);
    else then (inClassDef, inImportCache);
  end matchcontinue;
end flattenClassDef;

protected function flattenClassDefElements
  input list<SCode.Element> inClassDefElements;
  input Env.Env inEnv;
  input ImportTable inImportTable;
  input ImportCache inCache;
  output list<SCode.Element> outClassDefElements;
  output ImportCache outCache;
algorithm
  (outClassDefElements, outCache) := matchcontinue(inClassDefElements, inEnv,
      inImportTable, inCache)
    local
      SCode.Element e;
      list<SCode.Element> el;
      ImportCache cache;
      SCode.Ident name;

    case ({}, _, _, _) then ({}, inCache);

    case (e :: el, _, _, _)
      equation
        (e, cache) = flattenClassDefElement(e, inEnv, inImportTable, inCache);
        (el, cache) = flattenClassDefElements(el, inEnv, inImportTable, cache);
      then
        (e :: el, cache);

    case (SCode.CLASSDEF(name = name) :: _, _, _, _)
      equation
        Debug.fprintln("failtrace", "- SCodeFlatten.flattenClassDefElements
          failed for element " +& name +& "\n");
      then
        fail();
  end matchcontinue;
end flattenClassDefElements;

protected function flattenClassDefElement
  input SCode.Element inClassDefElement;
  input Env.Env inEnv;
  input ImportTable inImportTable;
  input ImportCache inCache;
  output SCode.Element outClassDefElement;
  output ImportCache outCache;

  SCode.Ident name;
  Boolean fp, rp;
  SCode.Class cls;
  Option<Absyn.ConstrainClass> cc;
algorithm
  SCode.CLASSDEF(name, fp, rp, cls, cc) := inClassDefElement;
  (cls, outCache) := flattenClass(cls, inEnv, inImportTable, inCache);
  outClassDefElement := SCode.CLASSDEF(name, fp, rp, cls, cc);
end flattenClassDefElement;

protected function sortElements
  input list<SCode.Element> inElements;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outClassdefs;
  output list<SCode.Element> outImports;
  output list<SCode.Element> outComponents;
  output list<SCode.Element> outUnitDefinitions;
algorithm
  (outExtends, outClassdefs, outImports, outComponents, outUnitDefinitions) :=
  match(inElements)
    local
      SCode.Element e;
      list<SCode.Element> rest_el, ex, cl, im, co, ud;

    case ({}) then ({}, {}, {}, {}, {});

    case ((e as SCode.EXTENDS(baseClassPath = _)) :: rest_el)
      equation
        (ex, cl, im, co, ud) = sortElements(rest_el);
      then
        (e :: ex, cl, im, co, ud);

    case ((e as SCode.CLASSDEF(name = _)) :: rest_el)
      equation
        (ex, cl, im, co, ud) = sortElements(rest_el);
      then
        (ex, e :: cl, im, co, ud);

    case ((e as SCode.IMPORT(imp = _)) :: rest_el)
      equation
        (ex, cl, im, co, ud) = sortElements(rest_el);
      then
        (ex, cl, e :: im, co, ud);

    case ((e as SCode.COMPONENT(component = _)) :: rest_el)
      equation
        (ex, cl, im, co, ud) = sortElements(rest_el);
      then
        (ex, cl, im, e :: co, ud);

    case ((e as SCode.DEFINEUNIT(name = _)) :: rest_el)
      equation
        (ex, cl, im, co, ud) = sortElements(rest_el);
      then
        (ex, cl, im, co, e :: ud);
  end match;
end sortElements;
    
protected function replaceImportsInComponent
  input SCode.Element inComponent;
  input ImportTable inImportTable;
  input ImportCache inCache;
  output SCode.Element outComponent;
algorithm
  outComponent := matchcontinue(inComponent, inImportTable, inCache)
    local
      SCode.Ident name;
      Absyn.InnerOuter io;
      Boolean fp, rp, pp;
      SCode.Attributes attr;
      Absyn.TypeSpec type_spec;
      SCode.Mod mod;
      Option<SCode.Comment> cmt;
      Option<Absyn.Exp> cond;
      Option<Absyn.Info> info;
      Option<Absyn.ConstrainClass> cc;

    case (SCode.COMPONENT(name, io, fp, rp, pp, attr, type_spec, mod, 
        cmt, cond, info, cc), _, _)
      equation
        type_spec = replaceImportsInTypeSpec(type_spec, inImportTable, inCache);
        //mod = replaceImportsInMod(mod, inImportTable, inCache);
      then
        SCode.COMPONENT(name, io, fp, rp, pp, attr, type_spec, mod, 
          cmt, cond, info, cc);

    case (_, _, _) then inComponent;
  end matchcontinue;
end replaceImportsInComponent;

protected function replaceImportsInTypeSpec
  input Absyn.TypeSpec inTypeSpec;
  input ImportTable inImportTable;
  input ImportCache inCache;
  output Absyn.TypeSpec outTypeSpec;
algorithm
  outTypeSpec := matchcontinue(inTypeSpec, inImportTable, inCache)
    local
      Absyn.Ident old_prefix;
      Absyn.Path path, new_prefix;
      Option<Absyn.ArrayDim> array_dim;
    case (Absyn.TPATH(path, array_dim), _, _)
      equation
        old_prefix = Absyn.pathFirstIdent(path);
        new_prefix = lookupImport(old_prefix, inImportTable);
        path = Absyn.pathReplaceFirstIdent(path, new_prefix);
      then
        Absyn.TPATH(path, array_dim);
    case (Absyn.TPATH(path, array_dim), _, _)
      equation
        path = lookupGlobalImport(path, inCache);
      then
        Absyn.TPATH(path, array_dim);
  end matchcontinue;
end replaceImportsInTypeSpec;
        
protected function replaceImportsInMod
  input SCode.Mod inMod;
  input ImportTable inImportTable;
  input ImportCache inCache;
  output SCode.Mod outMod;
algorithm
  /*outMod := matchcontinue(inMod, inImportTable, inCache)
    local
      Boolean fp;
      Absyn.Each ep;
      list<SCode.SubMod> sub_mods;
      Option<tuple<Absyn.Exp, Boolean>> opt_exp;
    case (SCode.MOD(fp, ep, sub_mods, opt_exp) */
  outMod := inMod;
end replaceImportsInMod;

protected function emptyImportTable
  output ImportTable outImportTable;
algorithm
  outImportTable := {};
end emptyImportTable;

protected function emptyImportCache
  output ImportCache outImportCache;
algorithm
  outImportCache := IMPORT_CACHE({}, {});
end emptyImportCache;

protected function addImportToTable
  input Import inImport;
  input ImportTable inImportTable;
  output ImportTable outImportTable;
algorithm
  outImportTable := inImport :: inImportTable;
end addImportToTable;

protected function addImports
  input list<SCode.Element> inImport;
  input Env.Env inEnv;
  input ImportTable inImportTable;
  input ImportCache inCache;
  output ImportTable outImportTable;
  output ImportCache outCache;
algorithm
  (outImportTable, outCache) := match(inImport, inEnv, inImportTable, inCache)
    local
      ImportTable imports;
      ImportCache cache;
      SCode.Element imp;
      list<SCode.Element> rest_imps;

    case ({}, _, _, _) then (inImportTable, inCache);

    case (imp :: rest_imps, _, _, _)
      equation
        (imports, cache) = addImport(imp, inEnv, inImportTable, inCache);
        (imports, cache) = addImports(rest_imps, inEnv, imports, cache);
      then
        (imports, cache);
  end match;
end addImports;

protected function addImport
  input SCode.Element inImportElement;
  input Env.Env inEnv;
  input ImportTable inImportTable;
  input ImportCache inCache;
  output ImportTable outImportTable;
  output ImportCache outCache;

  Absyn.Import imp;
algorithm
  SCode.IMPORT(imp = imp) := inImportElement;
  (outImportTable, outCache) := addImport_impl(imp, inEnv, inImportTable, inCache);
end addImport;

protected function addGlobalImport
  input Absyn.Path inImportName;
  input Absyn.Path inImportPath;
  input ImportCache inCache;
  output ImportCache outCache;

  list<Import> cached_imports;
  list<GlobalImport> global_imports;
algorithm
  IMPORT_CACHE(cached_imports, global_imports) := inCache;
  global_imports := addGlobalImport2(inImportName, inImportPath, global_imports);
  outCache := IMPORT_CACHE(cached_imports, global_imports);
end addGlobalImport;

protected function addGlobalImport2
  input Absyn.Path inImportName;
  input Absyn.Path inImportPath;
  input list<GlobalImport> inImports;
  output list<GlobalImport> outImports;
algorithm
  outImports := matchcontinue(inImportName, inImportPath, inImports)
    local
      Absyn.Ident name, id;
      Absyn.Path path;
      Option<Absyn.Path> opt_path;
      GlobalImport imp;
      list<GlobalImport> rest_imps, imps;
      String import_str1, import_str2;

    // End of import name and no branches left => create new leaf.
    case (Absyn.IDENT(name = name), _, {})
      then 
        {GLOBAL_IMPORT(name, SOME(inImportPath), {})};

    // No branches left => create new branch.
    case (Absyn.QUALIFIED(name = name, path = path), _, {})
      equation
        imps = addGlobalImport2(path, inImportPath, {});
      then
        {GLOBAL_IMPORT(name, NONE(), imps)};

    // End of import name, leaf not set => set leaf.
    case (Absyn.IDENT(name = name), _, 
        GLOBAL_IMPORT(ident = id, path = NONE(), imports = imps) :: rest_imps)
      equation
        true = stringEq(name, id);
      then
        GLOBAL_IMPORT(id, SOME(inImportPath), imps) :: rest_imps;

    // Matching prefix, continue searching with the rest of the import name.
    case (Absyn.QUALIFIED(name = name, path = path), _,
      GLOBAL_IMPORT(ident = id, path = opt_path, imports = imps) :: rest_imps)
      equation
        true = stringEq(name, id);
        imps = addGlobalImport2(path, inImportPath, imps);
      then
        GLOBAL_IMPORT(id, opt_path, imps) :: rest_imps;

    // No match, search in the rest of the list.
    case (_, _, imp :: rest_imps)
      equation
        rest_imps = addGlobalImport2(inImportName, inImportPath, rest_imps);
      then
        imp :: rest_imps;
  end matchcontinue;
end addGlobalImport2;

protected function addImport_impl
  input Absyn.Import inImport;
  input Env.Env inEnv;
  input ImportTable inImportTable;
  input ImportCache inCache;
  output ImportTable outImportTable;
  output ImportCache outCache;
algorithm
  (outImportTable, outCache) := matchcontinue(inImport, inEnv, inImportTable, inCache)
    local
      String name;
      Absyn.Path path, global_path;
      SCode.Class cls;
      ImportCache cache;
      ImportTable imports;

    // Check if the import is cached
    //case (_, _, _)
    //  then fail();

    case (Absyn.NAMED_IMPORT(name = name, path = path), _, _, _)
      equation
        global_path = Absyn.joinPaths(Env.getEnvName(inEnv), Absyn.IDENT(name));
        cache = addGlobalImport(global_path, path, inCache);
        imports = addImportToTable((name, path), inImportTable);
      then 
        (imports, cache);

    case (Absyn.QUAL_IMPORT(path = path), _, _, _)
      equation
        name = Absyn.pathLastIdent(path);
        global_path = Absyn.joinPaths(Env.getEnvName(inEnv), Absyn.IDENT(name));
        cache = addGlobalImport(global_path, path, inCache);
        imports = addImportToTable((name, path), inImportTable);
      then
        (imports, cache);

    case (Absyn.UNQUAL_IMPORT(path = path), _, _, _)
      equation
        cls = lookupClass(path, inEnv);
      then
       fail();
  end matchcontinue;
end addImport_impl;

protected function lookupImport
  input Absyn.Ident inOldPrefix;
  input ImportTable inImportTable;
  output Absyn.Path outNewPrefix;
algorithm
  ((_, outNewPrefix)) := Util.listGetMemberOnTrue(inOldPrefix, inImportTable,
    importEqualPrefix);
end lookupImport;

protected function lookupGlobalImport
  input Absyn.Path inPath;
  input ImportCache inCache;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath, inCache)
    local
      Absyn.Ident name;
      list<GlobalImport> imps;
      Absyn.Path path;
    case (_, IMPORT_CACHE(globalImports = imps))
      equation
        path = lookupGlobalImport2(inPath, imps);
      then
        path;
  end matchcontinue;
end lookupGlobalImport;

protected function lookupGlobalImport2
  input Absyn.Path inName;
  input list<GlobalImport> inImports;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inName, inImports)
    local
      String ident, name;
      Absyn.Path path, imp_path;
      list<GlobalImport> imps, rest_imps;

    // Ident input path, return import path if name matches. 
    case (Absyn.IDENT(name = name), 
        GLOBAL_IMPORT(ident = ident, path = SOME(imp_path)) :: _)
      equation 
        true = stringEq(name, ident);
      then
        imp_path;

    // Qualified input path, search deeper if name matches.
    case (Absyn.QUALIFIED(name = name, path = path),
        GLOBAL_IMPORT(ident = ident, imports = imps) :: _)
      equation
        true = stringEq(name, ident);
        path = lookupGlobalImport2(path, imps);
      then
        path;

    // Qualified input path, no match found deeper in tree. Return current
    // import path.
    case (Absyn.QUALIFIED(name = name, path = path),
        GLOBAL_IMPORT(ident = ident, path = SOME(imp_path)) :: _)
      equation
        true = stringEq(name, ident);
        path = Absyn.joinPaths(imp_path, path);
      then
        path;

    // No matches, search the rest of the import list.
    case (_, _ :: rest_imps)
      equation
        path = lookupGlobalImport2(inName, rest_imps);
      then
        path;
  end matchcontinue;
end lookupGlobalImport2;
  
protected function importEqualPrefix
  input Absyn.Ident inPrefix;
  input Import inImport;
  output Boolean isEqual;

  Absyn.Ident imp;
algorithm
  (imp, _) := inImport;
  isEqual := stringEq(imp, inPrefix);
end importEqualPrefix;

protected function lookupClass
  input Absyn.Path inClassPath;
  input Env.Env inEnv;
  output SCode.Class outClass;
algorithm
  outClass := matchcontinue(inClassPath, inEnv)
    local
      Absyn.Ident name;
      SCode.Class cls;
      Env.Env rest_env;
      Env.AvlTree tree;

    case (Absyn.IDENT(name = name), Env.FRAME(clsAndVars = tree) :: rest_env)
      equation
        Env.CLASS(class_ = cls) = Env.avlTreeGet(tree, name);
      then
        cls;
  end matchcontinue;
end lookupClass;

end SCodeFlatten;

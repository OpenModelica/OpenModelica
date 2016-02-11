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

encapsulated package NFEnvExtends
" file:        NFEnvExtends.mo
  package:     NFEnvExtends
  description: Utility functions for extends in the environment.


  This package contains functions for handling extends in the environment.
  Extends are added to the environment while the environment is built, and we
  can't do any lookup at that time since we don't have a complete environment.

  There are several important things done by this package:

  QUALIFYING EXTENDS:
  All base class names in the environment are fully qualified by the qualify
  function. This is to avoid potential exponential complexity during lookup with
  regards to the nesting depth of classes. One such case is the pattern used in
  the MSL, where every class extends from a a class in Modelica.Icons:

    package Modelica
      package Icons end Icons;

      package A
        extends Modelica.Icons.foo;
        package B
          extends Modelica.Icons.bar;
          package C
            ...
          end C;
        end B;
      end A;
    end Modelica;

  To look a name up in C that references a name in the top scope we need to
  first look up in C. When the name is not found there we look in B, which
  extends Modelica.Icons.bar. We then need to look for Modelica in B, and then
  Modelica in A, which extends Modelica.Icons.foo. We then need to follow that
  extends, and look for Modelica in A, etc. This means that we need to look up
  2^n extends to find a relative name in the top scope. By fully qualifying the
  base class names we avoid these problems.

  To avoid qualifying an extends multiple times we store them in an array which
  is updated during the qualifying phase. Each extends is given a unique index
  for this purpose when it's added to the environment by
  NFSCodeEnv.extendEnvWithExtends, which is used to index the array.

  When errors are found in this phase, such as missing base classes, we want to
  only report errors for models which are actually used. We therefore delay the
  error messages until the extends are used. This is done by returning special
  error paths instead of the fully qualified paths, see checkExtendsPart for
  details. When e.g. NFSCodeLookup.lookupBaseClassName encounters such a path it
  uses printExtendsError to print the appropriate error.

  INSERT ELEMENT REDECLARES INTO EXTENDS:
  The update function goes through all the scopes and insert element redeclares
  into the appropriate extends with addElementRedeclarationsToEnv from
  NFSCodeFlattenRedeclare. See the comment in SCodeFlattenRedeclare for more
  information about this.

  UPDATE CLASS EXTENDS:
  Class extends are handled by initially adding them to the environment with
  NFSCodeEnv.extendEnvWithClassExtends. This function add the given class as a
  normal class to the environment, and sets the class extends information field
  in the class's environment. This information is later used when the extends
  are updated with the update function, and updateClassExtends is called.
  updateClassExtends looks the base class up and makes sure it is replaceable,
  and adds an extends clause to the extending class and the environment. The
  base class will be prefixed with $ce so that the lookup knows that it should
  look among the inherited elements of the scope above when looking for a class
  extends base class.

  However, since it's possible to redeclare the base class of a class extends
  it's possible that the base class is replaced with a class that extends from
  it. If the base class were to be replaced with this class it would mean that
  the class extends from itself, causing a loop. To avoid this an alias for the
  base class is added instead, and the base class itself is added with the
  BASE_CLASS_SUFFIX defined in NFSCodeEnv. The alias can then be safely redeclared
  while preserving the base class for the class extends to extend from. It's
  somewhat difficault to only add aliases for classes that are used by class
  extends though, so an alias is currently added for all replaceable classes in
  NFSCodeEnv.extendEnvWithClassDef for simplicity's sake. The function
  NFSCodeLookup.resolveAlias is then used to resolve any alias items to the real
  items whenever an item is looked up in the environment.

  So a class extends on the form 'class extends X' is thus translated to
  'class X extends $ce.X$base', and then mostly handled like a normal class
  since the lookup knows how to handle the base class. Some care is needed in
  the dependency analysis to make sure that nothing important is removed, see
  the comment in SCodeDependency.analyseClassExtends.
"

public import Absyn;
public import SCode;
public import NFSCodeEnv;

protected import Debug;
protected import Error;
protected import Flags;
protected import List;
protected import NFSCodeCheck;
protected import SCodeDump;
protected import NFSCodeFlattenRedeclare;
protected import NFSCodeLookup;
protected import System;
protected import Util;

public type Env = NFSCodeEnv.Env;

protected type AvlTree = NFSCodeEnv.AvlTree;
protected type AvlTreeValue = NFSCodeEnv.AvlTreeValue;
protected type ClassType = NFSCodeEnv.ClassType;
protected type Extends = NFSCodeEnv.Extends;
protected type Frame = NFSCodeEnv.Frame;
protected type FrameType = NFSCodeEnv.FrameType;
protected type Import = Absyn.Import;
protected type Item = NFSCodeEnv.Item;

protected type ExtendsTableArray = array<ExtendsWrapper>;

public constant String BASECLASS_NOT_FOUND_ERROR = "$1";
public constant String BASECLASS_INHERITED_ERROR = "$2";
public constant String BASECLASS_REPLACEABLE_ERROR = "$3";
public constant String BASECLASS_IS_VAR_ERROR = "$4";
public constant String BASECLASS_UNKNOWN_ERROR = "$5";

protected uniontype ExtendsWrapper
  record UNQUALIFIED_EXTENDS
    Extends ext;
  end UNQUALIFIED_EXTENDS;

  record QUALIFIED_EXTENDS
    Extends ext;
  end QUALIFIED_EXTENDS;

  record NO_EXTENDS end NO_EXTENDS;
end ExtendsWrapper;

public function update
  "While building the environment some extends information is stored that needs
   to be updated once the environment is complete, since we can't reliably look
   things up in an incomplete environment. This includes fully qualifying the
   names of the extended classes, updating the class extends base classes and
   inserting element redeclares into the proper extends."
  input Env inEnv;
  output Env outEnv;
protected
  Env env;
algorithm
  //System.startTimer();
  env := qualify(inEnv);
  outEnv := update2(env);
  //System.stopTimer();
  //print("Updating extends took " + realString(System.getTimerIntervalTime()) + " seconds.\n");
end update;

public function qualify
  "Fully qualified all base class names using in extends clauses. This is done
   to avoid some cases where the lookup might exhibit exponential complexity
   with regards to the nesting depth of classes. One such case is the pattern
   used in the MSL, where every class extends from a class in Modelica.Icons:

     package Modelica
       package Icons end Icons;

       package A
         extends Modelica.Icons.foo;
         package B
           extends Modelica.Icons.bar;
           package C
             ...
           end C;
        end B;
      end A;

   To look a name up in C that references a name in the top scope we need to
   first look in C. When the name is not found there we look in B, which extends
   Modelica.Icons.bar. We then need to look for Modelica in B, and then Modelica
   in A, which extends Modelica.Icons.foo. We then need to follow that extends,
   and look for Modelica in A, etc. This means that we need to look up 2^n
   extends to find a relative name at the top scope. By fully qualifying the
   base class names we avoid these problems."
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv)
    local
      Integer ext_count;
      ExtendsTableArray ext_table;

    case (_)
      equation
        ext_count = System.tmpTickIndex(NFSCodeEnv.extendsTickIndex);
        ext_table = createExtendsTable(ext_count);
      then
        qualify2(inEnv, NFSCodeEnv.USERDEFINED(), ext_table);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFEnvExtends.qualify failed.");
      then
        fail();

  end matchcontinue;
end qualify;

protected function qualify2
  input Env inEnv;
  input ClassType inClassType;
  input ExtendsTableArray inExtendsTable;
  output Env outEnv;
protected
  list<Extends> exts;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
  Env env;
  AvlTree tree;
algorithm
  // Qualify the extends in this scope.
  env := qualifyLocalScope(inEnv, inClassType, inExtendsTable);

  // Recurse down the tree.
  NFSCodeEnv.FRAME(clsAndVars = tree) :: _ := env;
  SOME(tree) := qualify3(SOME(tree), env, inExtendsTable);
  outEnv := NFSCodeEnv.setEnvClsAndVars(tree, env);
end qualify2;

protected function qualify3
  input Option<AvlTree> inTree;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  output Option<AvlTree> outTree;
algorithm
  outTree := match(inTree, inEnv, inExtendsTable)
    local
      String name;
      SCode.Element cls;
      Frame cls_env;
      ClassType cls_ty;
      Integer h;
      Option<AvlTree> left, right;
      Env env, rest_env;
      Item item;
      Option<AvlTreeValue> value;

    // Empty leaf, do nothing.
    case (NONE(), _, _) then inTree;

    case (SOME(NFSCodeEnv.AVLTREENODE(SOME(NFSCodeEnv.AVLTREEVALUE(
        name, NFSCodeEnv.CLASS(cls, {cls_env}, cls_ty))), h, left, right)), _, _)
      equation
        env = NFSCodeEnv.enterFrame(cls_env, inEnv);
        cls_env :: rest_env = qualify2(env, cls_ty, inExtendsTable);
        left = qualify3(left, rest_env, inExtendsTable);
        right = qualify3(right, rest_env, inExtendsTable);
        item = NFSCodeEnv.CLASS(cls, {cls_env}, cls_ty);
        value = SOME(NFSCodeEnv.AVLTREEVALUE(name, item));
      then
        SOME(NFSCodeEnv.AVLTREENODE(value, h, left, right));

     case (SOME(NFSCodeEnv.AVLTREENODE(value, h, left, right)), _, _)
       equation
         left = qualify3(left, inEnv, inExtendsTable);
         right = qualify3(right, inEnv, inExtendsTable);
       then
         SOME(NFSCodeEnv.AVLTREENODE(value, h, left, right));

  end match;
end qualify3;

protected function qualifyLocalScope
  input Env inEnv;
  input ClassType inClassType;
  input ExtendsTableArray inExtendsTable;
  output Env outEnv;
protected
  list<Extends> exts;
  list<SCode.Element> re;
  Option<SCode.Element> cei;
algorithm
  NFSCodeEnv.EXTENDS_TABLE(exts, re, cei) := NFSCodeEnv.getEnvExtendsTable(inEnv);
  exts := qualifyExtendsList(exts, inClassType, inEnv, inExtendsTable);
  outEnv := NFSCodeEnv.setEnvExtendsTable(NFSCodeEnv.EXTENDS_TABLE(exts, re, cei), inEnv);
end qualifyLocalScope;

protected function qualifyExtendsList
  input list<Extends> inExtends;
  input ClassType inClassType;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  output list<Extends> outExtends;
algorithm
  outExtends := match(inExtends, inClassType, inEnv, inExtendsTable)
    local
      Extends ext;
      list<Extends> extl;

    // Skip the first extends in a class extends, since it's added by the
    // compiler itself and shouldn't be qualified.
    case (ext :: extl, NFSCodeEnv.CLASS_EXTENDS(), _, _)
      equation
        extl = List.map2Reverse(extl, qualifyExtends, inEnv, inExtendsTable);
      then
        ext :: extl;

    // Otherwise, qualify all the extends.
    else
      equation
        extl = List.map2Reverse(inExtends, qualifyExtends, inEnv, inExtendsTable);
      then
        extl;

  end match;
end qualifyExtendsList;

protected function qualifyExtends
  input Extends inExtends;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  output Extends outExtends;
algorithm
  outExtends := matchcontinue(inExtends, inEnv, inExtendsTable)
    local
      Absyn.Ident id;
      Extends ext;
      Absyn.Path bc;

    // Check if the base class is a built in type such as Real, then we don't
    // need to do anything.
    case (NFSCodeEnv.EXTENDS(baseClass = Absyn.IDENT(name = id)), _, _)
      equation
        _ = NFSCodeLookup.lookupBuiltinType(id);
      then
        inExtends;

    case (_, _, _)
      equation
        SOME(ext) = qualifyExtends2(inExtends, inEnv, inExtendsTable);
      then
        ext;

    case (NFSCodeEnv.EXTENDS(baseClass = bc), _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFEnvExtends.qualifyExtends failed on " +
          Absyn.pathString(bc) + "\n");
      then
        fail();

  end matchcontinue;
end qualifyExtends;

protected function qualifyExtends2
  input Extends inExtends;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  output Option<Extends> outExtends;
algorithm
  outExtends := matchcontinue(inExtends, inEnv, inExtendsTable)
    local
      Absyn.Path bc;
      list<NFSCodeEnv.Redeclaration> rl;
      Integer index;
      SourceInfo info;
      Extends ext;
      Env env;

    case (NFSCodeEnv.EXTENDS(index = index), _, _)
      then lookupQualifiedExtends(index, inExtendsTable);

    case (NFSCodeEnv.EXTENDS(bc, rl, index, info), _, _)
      equation
        addUnqualifiedToTable(inExtends, index, inExtendsTable);
        env = NFSCodeEnv.removeExtendFromLocalScope(bc, inEnv);
        bc = qualifyExtends3(bc, env, inExtendsTable, true, bc, info, NONE());
        /*********************************************************************/
        // TODO: Convert this check to the delayed error system.
        /*********************************************************************/
        List.map2_0(rl, NFSCodeCheck.checkRedeclareModifier, bc, inEnv);
        ext = NFSCodeEnv.EXTENDS(bc, rl, index, info);
        updateQualifiedInTable(ext, index, inExtendsTable);
      then
        SOME(ext);

  end matchcontinue;
end qualifyExtends2;

protected function qualifyExtends3
  input Absyn.Path inBaseClass;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  input Boolean inIsFirst;
  input Absyn.Path inFullPath;
  input SourceInfo inInfo;
  input Option<Absyn.Path> inErrorPath;
  output Absyn.Path outBaseClass;
algorithm
  outBaseClass := match(inBaseClass, inEnv, inExtendsTable, inIsFirst,
      inFullPath, inInfo, inErrorPath)
    local
      String name;
      Absyn.Path bc, rest_path;
      Env env;
      Option<Absyn.Path> ep, opath;

    case (_, _, _, _, _, _, SOME(bc)) then bc;

    case (Absyn.IDENT(name = name), _, _, _, _, _, _)
      equation
        (opath, env, ep) = qualifyExtendsPart(name, inEnv, inExtendsTable, inIsFirst,
          inFullPath, inInfo);
      then
        makeExtendsPath(opath, NONE(), env, ep, inIsFirst);

    case (Absyn.QUALIFIED(name = name, path = rest_path), _, _, _, _, _, _)
      equation
        (opath, env, ep) = qualifyExtendsPart(name, inEnv, inExtendsTable, inIsFirst,
          inFullPath, inInfo);
        rest_path = qualifyExtends3(rest_path, env, inExtendsTable, false, inFullPath, inInfo, ep);
      then
        makeExtendsPath(opath, SOME(rest_path), env, ep, inIsFirst);

    case (Absyn.FULLYQUALIFIED(path = rest_path), _, _, _, _, _, _)
      equation
        env = NFSCodeEnv.getEnvTopScope(inEnv);
      then
        qualifyExtends3(rest_path, env, inExtendsTable, inIsFirst, rest_path,
          inInfo, NONE());

  end match;
end qualifyExtends3;

protected function makeExtendsPath
  input Option<Absyn.Path> inFirstPath;
  input Option<Absyn.Path> inRestPath;
  input Env inEnv;
  input Option<Absyn.Path> inErrorPath;
  input Boolean inIsFirst;
  output Absyn.Path outPath;
algorithm
  outPath := match(inFirstPath, inRestPath, inEnv, inErrorPath, inIsFirst)
    local
      Absyn.Path path;

    // If an error has occured, return the error path.
    case (_, _, _, SOME(path), _) then path;
    case (_, SOME(path as Absyn.QUALIFIED(name = "$E")), _, _, _) then path;

    // If the rest of the path is fully qualified it overwrites everything before.
    case (_, SOME(path as Absyn.FULLYQUALIFIED()), _, _, _) then path;

    // If inFirstPath is the very first part of the path, use the environment to
    // get the whole path.
    case (_, _, _, _, true)
      equation
        path = NFSCodeEnv.getEnvPath(inEnv);
        path = Absyn.joinPathsOptSuffix(path, inRestPath);
        path = Absyn.makeFullyQualified(path);
      then
        path;

    // Otherwise, just join them.
    case (SOME(path), _, _, _, _) then Absyn.joinPathsOptSuffix(path, inRestPath);

  end match;
end makeExtendsPath;

protected function qualifyExtendsPart
  input String inName;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  input Boolean inIsFirst;
  input Absyn.Path inFullPath;
  input SourceInfo inInfo;
  output Option<Absyn.Path> outPath;
  output Env outEnv;
  output Option<Absyn.Path> outErrorPath;
protected
  Option<Item> oitem;
  Option<Env> oenv;
  Boolean fe;
algorithm
  (oitem, outPath, oenv, fe) := lookupSimpleName(inName, inEnv, inExtendsTable);
  (outEnv, outErrorPath) := qualifyExtendsPart2(Absyn.IDENT(inName), oitem,
    oenv, inEnv, inIsFirst, fe, inFullPath);
end qualifyExtendsPart;

protected function qualifyExtendsPart2
  input Absyn.Path inPartName;
  input Option<Item> inItem;
  input Option<Env> inFoundEnv;
  input Env inOriginEnv;
  input Boolean inIsFirst;
  input Boolean inFromExtends;
  input Absyn.Path inFullPath;
  output Env outEnv;
  output Option<Absyn.Path> outErrorPath;
algorithm
  (outEnv, outErrorPath) := match(inPartName, inItem, inFoundEnv, inOriginEnv,
      inIsFirst, inFromExtends, inFullPath)
    local
      Item item;
      Env env;
      Option<Absyn.Path> ep;

    case (_, SOME(item), SOME(env), _, _, _, _)
      equation
        ep = checkExtendsPart(inIsFirst, inFromExtends, inPartName, item,
          inFullPath, env, inOriginEnv);
        env = NFSCodeEnv.mergeItemEnv(item, env);
      then
        (env, ep);

    else (NFSCodeEnv.emptyEnv,
          makeExtendsError(inFullPath, inPartName, BASECLASS_NOT_FOUND_ERROR));
  end match;
end qualifyExtendsPart2;

protected function makeExtendsError
  input Absyn.Path inBaseClass;
  input Absyn.Path inPart;
  input String inError;
  output Option<Absyn.Path> outError;
algorithm
  outError := match(inBaseClass, inPart, inError)
    local
      Absyn.Path path;

    case (_, _, _)
      equation
        path = Absyn.joinPaths(inPart, Absyn.QUALIFIED("$bc", inBaseClass));
        path = Absyn.QUALIFIED("$E", Absyn.QUALIFIED(inError, path));
      then
        SOME(path);

  end match;
end makeExtendsError;

protected function checkExtendsPart
  "This function checks that part of a base class name is correct. If it is not
   correct it returns an error path on the form $E.$N.part_path.$bc.base_class.
   $N, where N is an integer, defined the actual error as defined by the error
   constants at the beginning of this file. part_path is the path of the part
   which the error occured in, and base_class is the path of the base class as
   declared in the code. This is used by printExtendsError to print an
   appropriate error when needed."
  input Boolean inIsFirst;
  input Boolean inFromExtends;
  input Absyn.Path inPartName;
  input Item inItem;
  input Absyn.Path inBaseClass;
  input Env inFoundEnv;
  input Env inOriginEnv;
  output Option<Absyn.Path> outErrorPath;
algorithm
  outErrorPath := matchcontinue(inIsFirst, inFromExtends, inPartName, inItem,
      inBaseClass, inFoundEnv, inOriginEnv)
    local
      Absyn.Path part;

    // The first part of the base class name may not be inherited.
    case (true, true, _, _, _, _, _)
      then makeExtendsError(inBaseClass, inPartName, BASECLASS_INHERITED_ERROR);

    // Not inherited class, ok!
    case (_, _, _, NFSCodeEnv.CLASS(), _, _, _)
      then NONE();

    // The base class part is actually not a class but a component, which is not
    // allowed either.
    case (_, _, _, NFSCodeEnv.VAR(), _, _, _)
      equation
        part = NFSCodeEnv.mergePathWithEnvPath(inPartName, inFoundEnv);
      then
        makeExtendsError(inBaseClass, part, BASECLASS_IS_VAR_ERROR);

    // We shouldn't get here.
    else makeExtendsError(inBaseClass, inPartName, BASECLASS_UNKNOWN_ERROR);
  end matchcontinue;
end checkExtendsPart;

protected function splitExtendsErrorPath
  input Absyn.Path inPath;
  output Absyn.Path outBaseClass;
  output Absyn.Path outPartPath;
algorithm
  (outBaseClass, outPartPath) := match(inPath)
    local
      String part_str;
      Absyn.Path part, bc;

    case Absyn.QUALIFIED(part_str, Absyn.QUALIFIED("$bc", bc))
      then (bc, Absyn.IDENT(part_str));

    case Absyn.QUALIFIED(part_str, part)
      equation
        (bc, part) = splitExtendsErrorPath(part);
      then
        (bc, Absyn.QUALIFIED(part_str, part));

  end match;
end splitExtendsErrorPath;

public function printExtendsError
  input Absyn.Path inErrorPath;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inErrorPath, inEnv, inInfo)
    local
      String err_str;
      Absyn.Path bc, part;
      Env env;

    case (Absyn.QUALIFIED(name = "$E",
        path = Absyn.QUALIFIED(name = err_str, path = bc)), _, _)
      equation
        (bc, part) = splitExtendsErrorPath(bc);
        env = NFSCodeEnv.removeExtendFromLocalScope(inErrorPath, inEnv);
        printExtendsError2(err_str, bc, part, env, inInfo);
      then
        ();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFEnvExtends.printExtendsError failed to print error " +
          Absyn.pathString(inErrorPath));
      then
        fail();

  end matchcontinue;
end printExtendsError;

public function printExtendsError2
  input String inError;
  input Absyn.Path inBaseClass;
  input Absyn.Path inPartPath;
  input Env inEnv;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inError, inBaseClass, inPartPath, inEnv, inInfo)
    local
      String bc_str, env_str, part;
      list<Extends> exts;
      Error.Message msg;
      SourceInfo info;

    case (_, _, _, _, _)
      equation
        true = stringEq(inError, BASECLASS_NOT_FOUND_ERROR);

        bc_str = Absyn.pathString(inBaseClass);
        env_str = NFSCodeEnv.getEnvName(inEnv);
        Error.addSourceMessage(Error.LOOKUP_BASECLASS_ERROR,
          {bc_str, env_str}, inInfo);
      then
        ();

    case (_, _, Absyn.IDENT(part), _, _)
      equation
        true = stringEq(inError, BASECLASS_INHERITED_ERROR);

        bc_str = Absyn.pathString(inBaseClass);
        Error.addSourceMessage(Error.INHERITED_EXTENDS, {bc_str}, inInfo);
        exts = NFSCodeEnv.getEnvExtendsFromTable(inEnv);
        printInheritedExtendsError(part, exts, inEnv);
      then
        ();

    case (_, _, _, _, _)
      equation
        true = stringEq(inError, BASECLASS_REPLACEABLE_ERROR);

        (NFSCodeEnv.CLASS(cls = SCode.CLASS(name = part, info = info)), _, _) =
          NFSCodeLookup.lookupFullyQualified(inPartPath, inEnv);
        bc_str = Absyn.pathString(inBaseClass);
        msg = if bc_str==part
          then Error.REPLACEABLE_BASE_CLASS_SIMPLE
          else Error.REPLACEABLE_BASE_CLASS;
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        Error.addSourceMessage(msg, {part, bc_str}, info);
      then
        ();

    case (_, _, _, _, _)
      equation
        true = stringEq(inError, BASECLASS_IS_VAR_ERROR);

        (NFSCodeEnv.VAR(var = SCode.COMPONENT(name = part, info = info)), _, _) =
          NFSCodeLookup.lookupFullyQualified(inPartPath, inEnv);
        bc_str = Absyn.pathString(inBaseClass);
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, info);
        Error.addSourceMessage(Error.EXTEND_THROUGH_COMPONENT,
          {part, bc_str}, inInfo);
      then
        ();

  end matchcontinue;
end printExtendsError2;

protected function printInheritedExtendsError
  input String inName;
  input list<Extends> inExtends;
  input Env inEnv;
algorithm
  _ := matchcontinue(inName, inExtends, inEnv)
    local
      list<Extends> rest_ext;
      Extends ext;
      Item item;
      SourceInfo info1, info2;
      Absyn.Path bc;
      String bc_str;

    case (_, (ext as NFSCodeEnv.EXTENDS(baseClass = bc, info = info2)) :: rest_ext, _)
      equation
        (SOME(item), _, _) = NFSCodeLookup.lookupInBaseClasses3(inName, ext,
          inEnv, inEnv, NFSCodeLookup.IGNORE_REDECLARES(), {});
        info1 = NFSCodeEnv.getItemInfo(item);
        NFSCodeEnv.EXTENDS(baseClass = bc, info = info2) = ext;
        bc = Absyn.makeNotFullyQualified(bc);
        bc_str = Absyn.pathString(bc);
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, info1);
        Error.addSourceMessage(Error.EXTENDS_INHERITED_FROM_LOCAL_EXTENDS,
          {inName, bc_str}, info2);
        printInheritedExtendsError(inName, rest_ext, inEnv);
      then
        ();

    case (_, _ :: rest_ext, _)
      equation
        printInheritedExtendsError(inName, rest_ext, inEnv);
      then
        ();

    case (_, {}, _) then ();

  end matchcontinue;
end printInheritedExtendsError;

protected function lookupSimpleName
  input String inName;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
  output Boolean outFromExtends;
algorithm
  (outItem, outPath, outEnv, outFromExtends) :=
  matchcontinue(inName, inEnv, inExtendsTable)
    local
      FrameType frame_type;
      Env env;
      Option<Item> opt_item;
      Option<Env> opt_env;
      Option<Absyn.Path> opt_path;
      Boolean fe;

    case (_, _, _)
      equation
        (opt_item, opt_path, opt_env, fe) = lookupInLocalScope(inName, inEnv, inExtendsTable);
      then
        (opt_item, opt_path, opt_env, fe);

    case (_, NFSCodeEnv.FRAME(frameType = frame_type) :: env, _)
      equation
        NFSCodeLookup.frameNotEncapsulated(frame_type);
        (opt_item, opt_path, opt_env, _) = lookupSimpleName(inName, env, inExtendsTable);
      then
        (opt_item, opt_path, opt_env, false);

    else (NONE(), NONE(), NONE(), false);

  end matchcontinue;
end lookupSimpleName;

protected function lookupInLocalScope
  input String inName;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
  output Boolean outFromExtends;
algorithm
  (outItem, outPath, outEnv, outFromExtends) :=
  matchcontinue(inName, inEnv, inExtendsTable)
    local
      Item item;
      Env env;
      Option<Item> oitem;
      Option<Absyn.Path> opath;
      Option<Env> oenv;
      list<Extends> bcl;
      list<Import> imps;

    case (_, _, _)
      equation
        (item, env) = NFSCodeLookup.lookupInClass(inName, inEnv);
      then
        (SOME(item), SOME(Absyn.IDENT(inName)), SOME(env), false);

    case (_, NFSCodeEnv.FRAME(extendsTable = NFSCodeEnv.EXTENDS_TABLE(
        baseClasses = bcl as _ :: _)) :: _, _)
      equation
        (oitem, oenv) = lookupInBaseClasses(inName, bcl, inEnv, inExtendsTable);
      then
        (oitem, SOME(Absyn.IDENT(inName)), oenv, true);

    case (_, NFSCodeEnv.FRAME(importTable =
        NFSCodeEnv.IMPORT_TABLE(hidden = false, qualifiedImports = imps)) :: _, _)
      equation
        (oitem, opath, oenv) =
          lookupInQualifiedImports(inName, imps, inEnv, inExtendsTable);
      then
        (oitem, opath, oenv, false);

    case (_, NFSCodeEnv.FRAME(importTable =
        NFSCodeEnv.IMPORT_TABLE(hidden = false, unqualifiedImports = imps)) :: _, _)
      equation
        (oitem, opath, oenv) =
          lookupInUnqualifiedImports(inName, imps, inEnv, inExtendsTable);
      then
        (oitem, opath, oenv, false);

  end matchcontinue;
end lookupInLocalScope;

protected function lookupInBaseClasses
  input String inName;
  input list<Extends> inExtends;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  output Option<Item> outItem;
  output Option<Env> outEnv;
algorithm
  (outItem, outEnv) :=
  matchcontinue(inName, inExtends, inEnv, inExtendsTable)
    local
      Extends ext;
      list<Extends> rest_ext;
      Option<Extends> opt_ext;
      Option<Item> opt_item;
      Option<Env> opt_env;
      Env env;

    case (_, ext :: _, _, _)
      equation
        // Unhide the imports, otherwise we might not be able to find the base
        // classes.
        env = NFSCodeEnv.setImportTableHidden(inEnv, false);
        opt_ext = qualifyExtends2(ext, env, inExtendsTable);
        (opt_item, opt_env) =
          lookupInBaseClasses2(inName, opt_ext, env, inExtendsTable);
      then
        (opt_item, opt_env);

    case (_, _ :: rest_ext, _, _)
      equation
        (opt_item, opt_env) =
          lookupInBaseClasses(inName, rest_ext, inEnv, inExtendsTable);
      then
        (opt_item, opt_env);

  end matchcontinue;
end lookupInBaseClasses;

protected function lookupInBaseClasses2
  input String inName;
  input Option<Extends> inExtends;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  output Option<Item> outItem;
  output Option<Env> outEnv;
algorithm
  (outItem, outEnv) := match(inName, inExtends, inEnv, inExtendsTable)
    local
      Absyn.Path bc;
      Item item;
      Env env;
      Option<Item> opt_item;
      Option<Env> opt_env;

    case (_, SOME(NFSCodeEnv.EXTENDS(baseClass = Absyn.FULLYQUALIFIED(bc))), _, _)
      equation
        (item, env) = lookupFullyQualified(bc, inEnv, inExtendsTable);
        env = NFSCodeEnv.mergeItemEnv(item, env);
        // Hide the imports to make sure we don't find any elements through
        // them, since imports are not inherited.
        env = NFSCodeEnv.setImportTableHidden(env, true);
        (opt_item, _, opt_env, _) = lookupInLocalScope(inName, env, inExtendsTable);
      then
        (opt_item, opt_env);

  end match;
end lookupInBaseClasses2;

protected function lookupInQualifiedImports
  input String inName;
  input list<Import> inImports;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inImports, inEnv, inExtendsTable)
    local
      Absyn.Ident name;
      Absyn.Path path;
      Item item;
      list<Import> rest_imps;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      Option<Env> opt_env;
      Env env;

    case (_, Absyn.NAMED_IMPORT(name = name) :: rest_imps, _, _)
      equation
        false = stringEqual(inName, name);
        (opt_item, opt_path, opt_env) =
          lookupInQualifiedImports(inName, rest_imps, inEnv, inExtendsTable);
      then
        (opt_item, opt_path, opt_env);

    case (_, Absyn.NAMED_IMPORT(name = name, path = path) :: _, _, _)
      equation
        true = stringEqual(inName, name);
        (item, env) = lookupFullyQualified(path, inEnv, inExtendsTable);
        path = NFSCodeEnv.prefixIdentWithEnv(inName, env);
        path = Absyn.makeFullyQualified(path);
      then
        (SOME(item), SOME(path), SOME(env));

    case (_, Absyn.NAMED_IMPORT(name = name) :: _, _, _)
      equation
        true = stringEqual(inName, name);
      then
        (NONE(), NONE(), NONE());

  end matchcontinue;
end lookupInQualifiedImports;

protected function lookupInUnqualifiedImports
  input Absyn.Ident inName;
  input list<Import> inImports;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inImports, inEnv, inExtendsTable)
    local
      Item item;
      Absyn.Path path;
      list<Import> rest_imps;
      Env env;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      Option<Env> opt_env;

    case (_, Absyn.UNQUAL_IMPORT(path = path) :: _, _, _)
      equation
        (item, env) = lookupFullyQualified(path, inEnv, inExtendsTable);
        env = NFSCodeEnv.mergeItemEnv(item, env);
        (item, env) = lookupFullyQualified2(Absyn.IDENT(inName), env, inExtendsTable);
        path = NFSCodeEnv.prefixIdentWithEnv(inName, env);
        path = Absyn.makeFullyQualified(path);
      then
        (SOME(item), SOME(path), SOME(env));

    case (_, _ :: rest_imps, _, _)
      equation
        (opt_item, opt_path, opt_env) =
          lookupInUnqualifiedImports(inName, rest_imps, inEnv, inExtendsTable);
      then
        (opt_item, opt_path, opt_env);

  end matchcontinue;
end lookupInUnqualifiedImports;

protected function lookupFullyQualified
  input Absyn.Path inName;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  output Item outItem;
  output Env outEnv;
protected
  Env env;
algorithm
  env := NFSCodeEnv.getEnvTopScope(inEnv);
  (outItem, outEnv) := lookupFullyQualified2(inName, env, inExtendsTable);
end lookupFullyQualified;

protected function lookupFullyQualified2
  input Absyn.Path inName;
  input Env inEnv;
  input ExtendsTableArray inExtendsTable;
  output Item outItem;
  output Env outEnv;
algorithm
  (outItem, outEnv) := match(inName, inEnv, inExtendsTable)
    local
      String name;
      Absyn.Path rest_path;
      Item item;
      Env env;

    case (Absyn.IDENT(name = name), _, _)
      equation
        (SOME(item), _, SOME(env), _) =
          lookupInLocalScope(name, inEnv, inExtendsTable);
      then
        (item, env);

    case (Absyn.QUALIFIED(name = name, path = rest_path), _, _)
      equation
        (SOME(item), _, SOME(env), _) =
          lookupInLocalScope(name, inEnv, inExtendsTable);
        env = NFSCodeEnv.mergeItemEnv(item, env);
        (item, env) = lookupFullyQualified2(rest_path, env, inExtendsTable);
      then
        (item, env);

  end match;
end lookupFullyQualified2;

protected function createExtendsTable
  input Integer inSize;
  output ExtendsTableArray outTable;
algorithm
  outTable := arrayCreate(inSize, NO_EXTENDS());
end createExtendsTable;

protected function lookupQualifiedExtends
  input Integer inIndex;
  input ExtendsTableArray inExtendsTable;
  output Option<Extends> outExtends;
protected
  ExtendsWrapper ext;
algorithm
  ext := arrayGet(inExtendsTable, inIndex);
  outExtends := lookupQualifiedExtends2(ext, inExtendsTable);
end lookupQualifiedExtends;

protected function lookupQualifiedExtends2
  input ExtendsWrapper inExtends;
  input ExtendsTableArray inExtendsTable;
  output Option<Extends> outExtends;
algorithm
  outExtends := match(inExtends, inExtendsTable)
    local
      Extends ext;
      Absyn.Path bc;

    case (QUALIFIED_EXTENDS(ext = ext), _) then SOME(ext);

    case (UNQUALIFIED_EXTENDS(ext = NFSCodeEnv.EXTENDS()), _)
      then NONE();

  end match;
end lookupQualifiedExtends2;

protected function addUnqualifiedToTable
  input Extends inExtends;
  input Integer inIndex;
  input ExtendsTableArray inExtendsTable;
algorithm
  _ := arrayUpdate(inExtendsTable, inIndex, UNQUALIFIED_EXTENDS(inExtends));
end addUnqualifiedToTable;

protected function updateQualifiedInTable
  input Extends inExtends;
  input Integer inIndex;
  input ExtendsTableArray inExtendsTable;
algorithm
  _ := arrayUpdate(inExtendsTable, inIndex, QUALIFIED_EXTENDS(inExtends));
end updateQualifiedInTable;

protected function update2
  input Env inEnv;
  output Env outEnv;
protected
  Env env, rest_env;
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  list<Extends> bcl;
  list<SCode.Element> re;
  NFSCodeEnv.ImportTable imps;
  Option<Util.StatefulBoolean> iu;
algorithm
  NFSCodeEnv.FRAME(name, ty, tree,
    NFSCodeEnv.EXTENDS_TABLE(bcl, re, _), imps, iu) :: rest_env := inEnv;
  SOME(tree) := update3(SOME(tree), inEnv);
  env := NFSCodeEnv.FRAME(name, ty, tree,
    NFSCodeEnv.EXTENDS_TABLE(bcl, {}, NONE()), imps, iu) :: rest_env;
  outEnv := NFSCodeFlattenRedeclare.addElementRedeclarationsToEnv(re, env);
end update2;

protected function update3
  input Option<AvlTree> inTree;
  input Env inEnv;
  output Option<AvlTree> outTree;
algorithm
  outTree := match(inTree, inEnv)
    local
      String name;
      Integer h;
      Option<AvlTree> left, right;
      Env rest_env, env;
      SCode.Element cls;
      Frame cls_env;
      Option<NFSCodeEnv.AvlTreeValue> value;
      Item item;
      ClassType cls_ty;

    case (NONE(), _) then inTree;

    case (SOME(NFSCodeEnv.AVLTREENODE(SOME(NFSCodeEnv.AVLTREEVALUE(
        name, NFSCodeEnv.CLASS(cls, {cls_env}, cls_ty))), h, left, right)), _)
      equation
        // Enter the class' frame and update the class extends in it.
        env = NFSCodeEnv.enterFrame(cls_env, inEnv);
        (cls, env) = updateClassExtends(cls, env, cls_ty);
        // Call update2 on the class' environment to update the extends.
        cls_env :: rest_env = update2(env);
        // Recurse into left and right branch of the tree.
        left = update3(left, rest_env);
        right = update3(right, rest_env);
        // Rebuild the class item with the updated information.
        item = NFSCodeEnv.CLASS(cls, {cls_env}, cls_ty);
        value = SOME(NFSCodeEnv.AVLTREEVALUE(name, item));
      then
        SOME(NFSCodeEnv.AVLTREENODE(value, h, left, right));

    case (SOME(NFSCodeEnv.AVLTREENODE(value, h, left, right)), _)
      equation
        // Recurse into left and right branch of the tree.
        left = update3(left, inEnv);
        right = update3(right, inEnv);
      then
        SOME(NFSCodeEnv.AVLTREENODE(value, h, left, right));

  end match;
end update3;

protected function updateClassExtends
  input SCode.Element inClass;
  input Env inEnv;
  input ClassType inClassType;
  output SCode.Element outClass;
  output Env outEnv;
algorithm
  (outClass, outEnv) := match(inClass, inEnv, inClassType)
    local
      String name;
      Env env;
      SCode.Mod mods;
      SourceInfo info;
      SCode.Element cls, ext;

    case (_, NFSCodeEnv.FRAME(name = SOME(name),
        extendsTable = NFSCodeEnv.EXTENDS_TABLE(classExtendsInfo = SOME(ext))) :: _,
        NFSCodeEnv.CLASS_EXTENDS())
      equation
        SCode.EXTENDS(modifications = mods, info = info) = ext;
        (cls, env) = updateClassExtends2(inClass, name, mods, info, inEnv);
      then
        (cls, env);

    else (inClass, inEnv);
  end match;
end updateClassExtends;

protected function updateClassExtends2
  input SCode.Element inClass;
  input String inName;
  input SCode.Mod inMods;
  input SourceInfo inInfo;
  input Env inEnv;
  output SCode.Element outClass;
  output Env outEnv;
algorithm
  (outClass, outEnv) := matchcontinue(inClass, inName, inMods, inInfo, inEnv)
    local
      SCode.Element ext;
      Frame cls_frame;
      Env env;
      SCode.Element cls;
      Item item;
      Absyn.Path path;

    case (_, _, _, _, cls_frame :: env)
      equation
        (path,_) = lookupClassExtendsBaseClass(inName, env, inInfo);
        ext = SCode.EXTENDS(path, SCode.PUBLIC(), inMods, NONE(), inInfo);
        {cls_frame} = NFSCodeEnv.extendEnvWithExtends(ext, {cls_frame});
        cls = SCode.addElementToClass(ext, inClass);
      then
        (cls, cls_frame :: env);

    else (inClass, inEnv);
  end matchcontinue;
end updateClassExtends2;

protected function lookupClassExtendsBaseClass
  "This function takes the name of a base class and looks up that name suffixed
   with the base class suffix defined in NFSCodeEnv. I.e. it looks up the real base
   class of a class extends, and not the alias introduced when adding replaceable
   classes to the environment in NFSCodeEnv.extendEnvWithClassDef. It returns the
   path and the item for that base class."
  input String inName;
  input Env inEnv;
  input SourceInfo inInfo;
  output Absyn.Path outPath;
  output Item outItem;
algorithm
  (outPath, outItem) := matchcontinue(inName, inEnv, inInfo)
    local
      Absyn.Path path;
      Item item;
      String basename;

    // Add the base class suffix to the name and try to look it up.
    case (_, _, _)
      equation
        basename = inName + NFSCodeEnv.BASE_CLASS_SUFFIX;
        (item, _) = NFSCodeLookup.lookupInheritedName(basename, inEnv);
        // Use a special $ce qualified so that we can find the correct class
        // with NFSCodeLookup.lookupBaseClassName.
        path = Absyn.QUALIFIED("$ce", Absyn.IDENT(basename));
      then
        (path, item);

    // The previous case will fail if we try to class extend a
    // non-replaceable class, because they don't have aliases. To get the
    // correct error message later we look the class up via the non-alias name
    // instead and return that result if found.
    case (_, _, _)
      equation
        (item, _) = NFSCodeLookup.lookupInheritedName(inName, inEnv);
        path = Absyn.IDENT(inName);
      then
        (path, item);

    // If the class doesn't even exist, show an error.
    else
      equation
        Error.addSourceMessage(Error.INVALID_REDECLARATION_OF_CLASS,
          {inName}, inInfo);
      then
        fail();

  end matchcontinue;
end lookupClassExtendsBaseClass;

public function extendEnvWithClassExtends
  "Extends the environment with the given class extends element."
  input SCode.Element inClassExtends;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClassExtends, inEnv)
    local
      SCode.Ident bc;
      SCode.Partial pp;
      SCode.Encapsulated ep;
      SCode.Restriction res;
      SCode.Prefixes prefixes;
      SourceInfo info;
      Env env, cls_env;
      SCode.Mod mods;
      SCode.ClassDef cdef;
      SCode.Element cls, ext;
      String el_str, env_str, err_msg;
      SCode.Comment cmt;

    // When a 'class extends X' is encountered we insert a 'class X extends
    // BaseClass.X' into the environment, with the same elements as the class
    // extends clause. BaseClass is the class that class X is inherited from.
    // This allows us to look up elements in class extends, because lookup can
    // handle normal extends. This is the first phase where the CLASS_EXTENDS is
    // converted to a PARTS and added to the environment, and the extends is
    // added to the class environment's extends table. The rest of the work is
    // done later in updateClassExtends when we have a complete environment.
    case (SCode.CLASS(
        prefixes = prefixes,
        encapsulatedPrefix = ep,
        partialPrefix = pp,
        restriction = res,
        classDef = SCode.CLASS_EXTENDS(
          baseClassName = bc,
          modifications = mods,
          composition = cdef),
        cmt=cmt, info = info), _)
      equation
        // Construct a new PARTS class with the data from the class extends.
        cls = SCode.CLASS(bc, prefixes, ep, pp, res, cdef, cmt, info);

        // Construct the class environment and add the new extends to it.
        cls_env = NFSCodeEnv.makeClassEnvironment(cls, false);
        ext = SCode.EXTENDS(Absyn.IDENT(bc), SCode.PUBLIC(), mods, NONE(), info);
        cls_env = addClassExtendsInfoToEnv(ext, cls_env);

        // Finally add the class to the environment.
        env = NFSCodeEnv.extendEnvWithItem(
          NFSCodeEnv.newClassItem(cls, cls_env, NFSCodeEnv.CLASS_EXTENDS()), inEnv, bc);
      then env;

    case (_, _)
      equation
        info = SCode.elementInfo(inClassExtends);
        el_str = SCodeDump.unparseElementStr(inClassExtends,SCodeDump.defaultOptions);
        env_str = NFSCodeEnv.getEnvName(inEnv);
        err_msg = "NFSCodeFlattenRedeclare.extendEnvWithClassExtends failed on unknown element " +
          el_str + " in " + env_str;
        Error.addSourceMessage(Error.INTERNAL_ERROR, {err_msg}, info);
      then
        fail();

  end match;
end extendEnvWithClassExtends;

protected function addClassExtendsInfoToEnv
  "Adds a class extends to the environment."
  input SCode.Element inClassExtends;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inClassExtends, inEnv)
    local
      list<Extends> bcl;
      list<SCode.Element> re;
      String estr;
      NFSCodeEnv.ExtendsTable ext;

    case (_, _)
      equation
        NFSCodeEnv.EXTENDS_TABLE(bcl, re, NONE()) =
          NFSCodeEnv.getEnvExtendsTable(inEnv);
        ext = NFSCodeEnv.EXTENDS_TABLE(bcl, re, SOME(inClassExtends));
      then
        NFSCodeEnv.setEnvExtendsTable(ext, inEnv);

    else
      equation
        estr = "- NFEnvExtends.addClassExtendsInfoToEnv: Trying to overwrite " +
               "existing class extends information, this should not happen!.";
        Error.addMessage(Error.INTERNAL_ERROR, {estr});
      then
        fail();

  end matchcontinue;
end addClassExtendsInfoToEnv;

annotation(__OpenModelica_Interface="frontend");
end NFEnvExtends;

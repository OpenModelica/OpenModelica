/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

encapsulated package Conversion
protected
  import Absyn;
  import AbsynUtil;
  import Dump;
  import Error;
  import Flags;
  import GlobalScript;
  import GlobalScriptDump;
  import List;
  import Parser;
  import System;
  import UnorderedMap;
  import Util;
  import MetaModelica.Dangerous.*;

  uniontype ConversionRule
    record CLASS
      array<String> oldPath;
      Absyn.Path newPath;
    end CLASS;

    record CLASS_IF

    end CLASS_IF;

    record ELEMENT
      array<String> oldPath;
      String oldName;
      String newName;
    end ELEMENT;

    record MODIFIERS
      list<Absyn.ElementArg> oldMods;
      list<Absyn.ElementArg> newMods;
      SourceInfo info;
    end MODIFIERS;

    record MESSAGE
      String message;
    end MESSAGE;
  end ConversionRule;

  uniontype ConversionRules
    "Structure used to store conversion rules. Each node corresponds to one
     element, and each node has a map of child nodes and a list of rules. So
     e.g. convertClass('A.B', 'A.C') becomes
     A(nodes = {B(nodes = {}, rules = {convertClass(A.C)})}, rules = {})"
    record CONVERSION_RULES
      UnorderedMap<String, ConversionRules> nodes;
      list<ConversionRule> rules;
    end CONVERSION_RULES;

    function newNode
      output ConversionRules node;
    algorithm
      node := CONVERSION_RULES(UnorderedMap.new<ConversionRules>(System.stringHashDjb2Mod, stringEq), {});
    end newNode;
  end ConversionRules;

  type RuleList = list<ConversionRule>;
  type RuleTable = UnorderedMap<String, RuleList>;

  // Used to specify which arguments to the conversion functions can be vectorized.
  type ArgType = enumeration(SCALAR, ARRAY);
  constant list<ArgType> CONVERT_CLASS_TYPE    = {ArgType.SCALAR, ArgType.SCALAR};
  constant list<ArgType> CONVERT_CLASS_IF_TYPE = {ArgType.SCALAR, ArgType.SCALAR, ArgType.SCALAR, ArgType.SCALAR};
  constant list<ArgType> CONVERT_ELEMENT_TYPE  = {ArgType.SCALAR, ArgType.SCALAR, ArgType.SCALAR};
  constant list<ArgType> CONVERT_MODIFIER_TYPE = {ArgType.SCALAR, ArgType.ARRAY,  ArgType.ARRAY,  ArgType.SCALAR};
  constant list<ArgType> CONVERT_MESSAGE_TYPE  = {ArgType.SCALAR, ArgType.SCALAR, ArgType.SCALAR};

public
  function convertPackage
    "Converts a package using the given conversion script file."
    input output Absyn.Class cls;
    input String scriptFile;
  protected
    ConversionRules rules;
    list<GlobalScript.Statement> stmts;
  algorithm
    stmts := loadScript(scriptFile);
    rules := ConversionRules.newNode();
    rules := parseRules(stmts, rules);

    if Flags.isSet(Flags.DUMP_CONVERSION_RULES) then
      dumpRules(rules);
    end if;

    cls := convertClass(cls, rules, {});
  end convertPackage;

protected
  function loadScript
    "Loads and parses a script file into a list of statements."
    input String scriptFile;
    output list<GlobalScript.Statement> stmts;
  protected
    String script;
  algorithm
    script := System.readFile(scriptFile);
    script := System.stringReplace(script, ")\n", ");\n");
    GlobalScript.Statements.ISTMTS(interactiveStmtLst = stmts) :=
      Parser.parsestringexp(script, infoFilename = scriptFile);
  end loadScript;

  function parseRules
    "Converts a list of statements into conversion rules and inserts them in the
     conversion rules structure."
    input list<GlobalScript.Statement> stmts;
    input output ConversionRules rules;
  algorithm
    for stmt in stmts loop
      rules := parseRule(stmt, rules);
    end for;
  end parseRules;

  function parseRule
    "Converts a statement into a conversion rule and insert it in the conversion
     rules structure."
    input GlobalScript.Statement stmt;
    input output ConversionRules rules;
  protected
    partial function ParseFn
      input list<Absyn.Exp> args;
      input SourceInfo info;
      input output ConversionRules rules;
    end ParseFn;

    String fn_name;
    list<Absyn.Exp> args;
    ParseFn parse_fn;
    list<ArgType> fn_type;
  algorithm
    () := match stmt
      case GlobalScript.Statement.IEXP(exp = Absyn.Exp.CALL(
          function_ = Absyn.ComponentRef.CREF_IDENT(name = fn_name),
          functionArgs = Absyn.FunctionArgs.FUNCTIONARGS(args = args, argNames = {})))
        algorithm
          (parse_fn, fn_type) := match fn_name
            case "convertClass"     then (parseConvertClass,     CONVERT_CLASS_TYPE);
            case "convertClassIf"   then (parseConvertClassIf,   CONVERT_CLASS_IF_TYPE);
            case "convertElement"   then (parseConvertElement,   CONVERT_ELEMENT_TYPE);
            case "convertModifiers" then (parseConvertModifiers, CONVERT_MODIFIER_TYPE);
            case "convertMessage"   then (parseConvertMessage,   CONVERT_MESSAGE_TYPE);
            else
              algorithm
                printConversionRuleError(stmt);
              then
                fail();
          end match;

          args := list(expandArg(a) for a in args);

          for a in vectorizeArgs(args, fn_type, stmt) loop
            rules := parse_fn(a, stmt.info, rules);
          end for;
        then
          ();

      else
        algorithm
          printConversionRuleError(stmt);
        then
          fail();

    end match;
  end parseRule;

  function expandArg
    "Converts fill(0, _) into {}."
    input Absyn.Exp exp;
    output Absyn.Exp outExp;
  algorithm
    outExp := match exp
      case Absyn.Exp.CALL(function_ = Absyn.ComponentRef.CREF_IDENT(name = "fill"),
                          functionArgs = Absyn.FunctionArgs.FUNCTIONARGS(args =
                            {_, Absyn.Exp.INTEGER(value = 0)}))
        then Absyn.Exp.ARRAY({});

      else exp;
    end match;
  end expandArg;

  function vectorizeArgs
    "Vectorizes a list of function arguments using the vectorization rules."
    input list<Absyn.Exp> args;
    input list<ArgType> fnType;
    input GlobalScript.Statement stmt;
    output list<list<Absyn.Exp>> vargs;
  protected
    Integer vdim = -1, dim;
    list<ArgType> fn_ty = fnType;
    ArgType arg_ty;
    list<Boolean> is_varg = {};
    list<Absyn.Exp> expl;
  algorithm
    if listLength(args) > listLength(fnType) then
      printConversionRuleError(stmt);
    end if;

    // Get the dimension to vectorize along, if any.
    for arg in args loop
      arg_ty :: fn_ty := fn_ty;

      (vdim, is_varg) := match (arg, arg_ty)
        // Got array, expected scalar => vectorize.
        case (Absyn.Exp.ARRAY(), ArgType.SCALAR)
          algorithm
            dim := listLength(arg.arrayExp);

            if vdim >= 0 and dim <> vdim then
              printConversionRuleError(stmt);
            end if;
          then
            (dim, true :: is_varg);

        // Got array, expected array => do nothing.
        case (Absyn.Exp.ARRAY(), ArgType.ARRAY)
          then (vdim, false :: is_varg);

        // Got scalar, expected array => error.
        case (_, ArgType.ARRAY)
          algorithm
            printConversionRuleError(stmt);
          then
            fail();

        // Got scalar, expected scalar => do nothing.
        else (vdim, false :: is_varg);
      end match;
    end for;

    if vdim == 0 then
      // Empty array arguments => ignore call
      vargs := {};
    elseif vdim == -1 then
      // No array arguments => scalar call
      vargs := {args};
    else
      // Array arguments => vectorize call
      vargs := {};

      for arg in listReverse(args) loop
        if listHead(is_varg) then
          Absyn.Exp.ARRAY(arrayExp = expl) := arg;
          vargs := expl :: vargs;
        else
          vargs := List.fill(arg, vdim) :: vargs;
        end if;

        is_varg := listRest(is_varg);
      end for;

      vargs := List.transposeList(vargs);
    end if;
  end vectorizeArgs;

  function statementInfo
    "Returns the SourceInfo contained in a statement."
    input GlobalScript.Statement stmt;
    output SourceInfo info;
  algorithm
    info := match stmt
      case GlobalScript.Statement.IEXP() then stmt.info;
      else AbsynUtil.dummyInfo;
    end match;
  end statementInfo;

  function printConversionRuleError
    "Prints a generic error for invalid conversion rules and fails."
    input GlobalScript.Statement stmt;
  algorithm
    Error.addSourceMessage(Error.INVALID_CONVERSION_RULE,
      {GlobalScriptDump.printIstmtStr(stmt)}, statementInfo(stmt));
    fail();
  end printConversionRuleError;

  function parseConvertClass
    "Converts a convertClass statement into a conversion rule and inserts it
     into the conversion rules structure."
    input list<Absyn.Exp> args;
    input SourceInfo info;
    input output ConversionRules rules;
  algorithm
    () := match args
      local
        String old_cls, new_cls;
        list<String> old_path;
        ConversionRule rule;

      case {Absyn.Exp.STRING(value = old_cls), Absyn.Exp.STRING(value = new_cls)}
        algorithm
          old_path := parsePathList(old_cls);
          rule := ConversionRule.CLASS(listArray(old_path), parsePath(new_cls));
          rules := addRule(old_path, rule, rules);
        then
          ();

      else
        algorithm
          Error.addSourceMessage(Error.INVALID_CONVERSION_RULE,
            {List.toString(args, Dump.dumpExpStr, "convertClass", "(", ", ", ")", true)}, info);
        then
          fail();

    end match;
  end parseConvertClass;

  function parseConvertClassIf
    "Converts a conertClassIf statement into a conversion rule and inserts it
     into the conversion rules structure."
    input list<Absyn.Exp> args;
    input SourceInfo info;
    input output ConversionRules rules;
  algorithm
    Error.assertion(false, getInstanceName() + ": not implemented", info);
  end parseConvertClassIf;

  function parseConvertElement
    "Converts a convertElement statement into a conversion rule and inserts it
     into the conversion rules structure."
    input list<Absyn.Exp> args;
    input SourceInfo info;
    input output ConversionRules rules;
  algorithm
    () := match args
      local
        String cls_name, old_name, new_name;
        list<String> old_path;
        ConversionRule rule;

      case {Absyn.Exp.STRING(value = cls_name),
            Absyn.Exp.STRING(value = old_name),
            Absyn.Exp.STRING(value = new_name)}
        algorithm
          old_path := parsePathList(cls_name);
          rule := ConversionRule.ELEMENT(listArray(old_path), old_name, new_name);
          rules := addRule(old_path, rule, rules);
        then
          ();

      else
        algorithm
          Error.addSourceMessage(Error.INVALID_CONVERSION_RULE,
            {List.toString(args, Dump.dumpExpStr, "convertElement", "(", ", ", ")", true)}, info);
        then
          fail();

    end match;
  end parseConvertElement;

  function parseConvertModifiers
    "Converts a convertModifiers statement into a conversion rule and inserts it
     into the conversion rules structure."
    input list<Absyn.Exp> args;
    input SourceInfo info;
    input output ConversionRules rules;
  algorithm
    rules := matchcontinue args
      local
        String cls_name;
        list<Absyn.Exp> old_mods, new_mods;
        Boolean simplify;

      case {Absyn.Exp.STRING(value = cls_name),
            Absyn.Exp.ARRAY(arrayExp = old_mods),
            Absyn.Exp.ARRAY(arrayExp = new_mods)}
        then parseConvertModifiers2(cls_name, old_mods, new_mods, false, info, rules);

      case {Absyn.Exp.STRING(value = cls_name),
            Absyn.Exp.ARRAY(arrayExp = old_mods),
            Absyn.Exp.ARRAY(arrayExp = new_mods),
            Absyn.Exp.BOOL(value = simplify)}
        then parseConvertModifiers2(cls_name, old_mods, new_mods, simplify, info, rules);

      else
        algorithm
          Error.addSourceMessage(Error.INVALID_CONVERSION_RULE,
            {List.toString(args, Dump.dumpExpStr, "convertModifiers", "(", ", ", ")", true)}, info);
        then
          fail();

    end matchcontinue;
  end parseConvertModifiers;

  function parseConvertModifiers2
    input String className;
    input list<Absyn.Exp> oldMods;
    input list<Absyn.Exp> newMods;
    input Boolean simplify;
    input SourceInfo info;
    input output ConversionRules rules;
  protected
    list<String> cls_path;
    list<Absyn.ElementArg> old_mods, new_mods;
  algorithm
    cls_path := parsePathList(className);
    old_mods := list(parseModifier(m, info) for m in oldMods);
    new_mods := list(parseModifier(m, info) for m in newMods);
    rules := addRule(cls_path, ConversionRule.MODIFIERS(old_mods, new_mods, info), rules);
  end parseConvertModifiers2;

  function parseModifier
    "Parses a string expression into an Absyn modifier. Fails if the given
     expressions isn't a string or not a syntactically valid modifier."
    input Absyn.Exp mod;
    input SourceInfo info;
    output Absyn.ElementArg outMod;
  protected
    String str;
  algorithm
    Absyn.Exp.STRING(value = str) := mod;
    outMod := Parser.stringMod(quotePlaceholders(str, info));
  end parseModifier;

  function quotePlaceholders
    "Quotes placeholder names in conversion modifiers, i.e. %name% => '%name%',
     so they can be parsed by the normal Modelica parser."
    input output String str;
    input SourceInfo info;
  protected
    list<String> strl, res = {};
    Boolean in_ident = false;
  algorithm
    strl := System.strtokIncludingDelimiters(str, "%");

    if listLength(strl) <= 1 then
      return;
    end if;

    for s in strl loop
      if s == "%" then
        s := if in_ident then "%'" else "'%";
        in_ident := not in_ident;
      end if;

      res := s :: res;
    end for;

    if in_ident then
      Error.addSourceMessage(Error.CONVERSION_MISMATCHED_PLACEHOLDER, {str}, info);
      fail();
    end if;

    str := stringAppendList(listReverseInPlace(res));
  end quotePlaceholders;

  function parseConvertMessage
    "Converts a convertMessage statement into a conversion rule and inserts it
     into the conversion rules structure."
    input list<Absyn.Exp> args;
    input SourceInfo info;
    input output ConversionRules rules;
  algorithm
    () := match args
      local
        String cls_name, msg;
        ConversionRule rule;

      case {Absyn.Exp.STRING(value = cls_name), Absyn.Exp.STRING(value = msg)}
        algorithm
          rule := ConversionRule.MESSAGE(msg);
          rules := addRule(parsePathList(cls_name), rule, rules);
        then
          ();

      else
        algorithm
          Error.addSourceMessage(Error.INVALID_CONVERSION_RULE,
            {List.toString(args, Dump.dumpExpStr, "convertMessage", "(", ", ", ")", true)}, info);
        then
          fail();

    end match;
  end parseConvertMessage;

  function parsePath
    "Converts a string into an Absyn path."
    input String str;
    output Absyn.Path path = AbsynUtil.stringPath(str);
  end parsePath;

  function parsePathList
    "Splits a string into a list of strings using . as delimiter."
    input String str;
    output list<String> path = Util.stringSplitAtChar(str, ".");
  end parsePathList;

  function addRule
    "Inserts a rule into the conversion rules structure using the given path."
    input list<String> path;
    input ConversionRule rule;
    input output ConversionRules rules;
  algorithm
    updateNode(SOME(rules), path, rule);
  end addRule;

  function updateNode
    "Adds the given rule to an existing node in the conversion rules structure,
     or to a new node if there's no existing node."
    input Option<ConversionRules> onode;
    input list<String> path;
    input ConversionRule rule;
    output ConversionRules node;
  algorithm
    if isSome(onode) then
      SOME(node) := onode;
    else
      node := ConversionRules.newNode();
    end if;

    if listEmpty(path) then
      node.rules := rule :: node.rules;
    else
      UnorderedMap.addUpdate(listHead(path),
        function updateNode(path = listRest(path), rule = rule), node.nodes);
    end if;
  end updateNode;

  function lookupRuleNode
    "Looks up a node in the conversion rules structure."
    input Absyn.Path path;
    input ConversionRules rules;
    output Option<ConversionRules> outNode;
  protected
    ConversionRules node = rules;
  algorithm
    for name in AbsynUtil.pathToStringList(path) loop
      outNode := UnorderedMap.get(name, node.nodes);

      if isNone(outNode) then
        return;
      end if;

      SOME(node) := outNode;
    end for;
  end lookupRuleNode;

  function lookupRules
    "Returns the rules for each identifier in a path with the rules for the last
     identifier that could be found first. If an identifier can't be found the
     lookup stops and returns the rules found so far, with an empty list added
     to the beginning of the list to indicate that the lookup stopped early."
    input Absyn.Path path;
    input ConversionRules rules;
    output list<list<ConversionRule>> outRules = {};
  protected
    Option<ConversionRules> onode;
    ConversionRules node = rules;
  algorithm
    for name in AbsynUtil.pathToStringList(path) loop
      onode := UnorderedMap.get(name, node.nodes);

      if isNone(onode) then
        outRules := {} :: outRules;
        return;
      end if;

      SOME(node) := onode;

      if not listEmpty(node.rules) then
        outRules := node.rules :: outRules;
      end if;
    end for;
  end lookupRules;

  function lookupTypeRules
    "Looks up the conversion rules associated with the given type name."
    input Absyn.Path ty;
    input ConversionRules rules;
    output Option<ConversionRule> typeRule = NONE();
    output RuleTable localRules = newRuleTable();
    output list<ConversionRule> modifierRules = {};
  protected
    list<list<ConversionRule>> found_rules;
  algorithm
    found_rules := lookupRules(ty, rules);

    if listEmpty(found_rules) then
      return;
    end if;

    // The rules at the head of the list applies to the referenced type.
    modifierRules := sortLocalRules(listHead(found_rules), localRules);

    // Also try to find a convertClass rule, which might be for a prefix of the
    // type name. The rule for the longest prefix is used.
    for rl in found_rules loop
      for r in rl loop
        () := match r
          case ConversionRule.CLASS()
            algorithm
              if isNone(typeRule) then
                typeRule := SOME(r);
              end if;
            then
              ();

          else ();
        end match;
      end for;
    end for;
  end lookupTypeRules;

  function newRuleTable
    output RuleTable table;
  algorithm
    table := UnorderedMap.new<RuleList>(System.stringHashDjb2Mod, stringEq);
  end newRuleTable;

  function sortLocalRules
    "Sorts a list of local rules, inserting element rules into the given table
     and returning a list of modifier rules."
    input list<ConversionRule> rules;
    input RuleTable localRules;
    output list<ConversionRule> modifierRules = {};
  algorithm
    for rule in rules loop
      () := match rule
        case ConversionRule.ELEMENT()
          algorithm
            UnorderedMap.addUpdate(rule.oldName,
              function mergeRuleList(newRule = rule), localRules);
          then
            ();

        case ConversionRule.MODIFIERS()
          algorithm
            modifierRules := rule :: modifierRules;
          then
            ();

        else ();
      end match;
    end for;
  end sortLocalRules;

  function mergeRuleList
    "Merges a rule into an existing list of rules, or creates a new list with
     the rule if there's no existing list."
    input Option<list<ConversionRule>> oldRules;
    input ConversionRule newRule;
    output list<ConversionRule> outRules;
  algorithm
    if isNone(oldRules) then
      outRules := {newRule};
    else
      SOME(outRules) := oldRules;
      outRules := newRule :: outRules;
    end if;
  end mergeRuleList;

  function lookupClassExtendsRules
    "Looks up the conversion rules for a class extends name."
    input String name;
    input list<ConversionRules> extendsRules;
    output RuleTable localRules = newRuleTable();
    output list<ConversionRule> modificationRules = {};
  protected
    Option<ConversionRules> onode;
    ConversionRules node;
  algorithm
    for ext in extendsRules loop
      onode := UnorderedMap.get(name, ext.nodes);

      if isSome(onode) then
        SOME(node) := onode;
        modificationRules := sortLocalRules(node.rules, localRules);
        return;
      end if;
    end for;
  end lookupClassExtendsRules;

  function dumpRules
    "Dumps a ConversionRules structure in a needlessly elaborate manner for debugging."
    input ConversionRules rules;
    input String indent = "";
  protected
    array<String> keys;
    array<ConversionRules> values;
    ConversionRule rule;
    list<ConversionRule> rest_rules = rules.rules;
  algorithm
    keys := UnorderedMap.keyArray(rules.nodes);
    values := UnorderedMap.valueArray(rules.nodes);

    while not listEmpty(rest_rules) loop
      rule :: rest_rules := rest_rules;

      if listEmpty(rest_rules) and arrayEmpty(keys) then
        dumpRule(rule, indent + "└─");
      else
        dumpRule(rule, indent + "├─");
      end if;
    end while;

    for i in 1:arrayLength(keys) loop
      if i == arrayLength(keys) then
        print(indent + "└─");
        print(keys[i]);
        print("\n");
        dumpRules(values[i], indent + "  ");
      else
        print(indent + "├─");
        print(keys[i]);
        print("\n");
        dumpRules(values[i], indent + "│ ");
      end if;
    end for;
  end dumpRules;

  function dumpRule
    "Dumps a single conversion rule."
    input ConversionRule rule;
    input String indent;
  algorithm
    print(indent);

    () := match rule
      case ConversionRule.CLASS()
        algorithm
          print("convertClass: ");
          print(AbsynUtil.pathString(rule.newPath));
        then
          ();

      case ConversionRule.CLASS_IF()
        algorithm
          print("convertClassIf: ");
        then
          ();

      case ConversionRule.ELEMENT()
        algorithm
          print("convertElement: ");
          print(rule.oldName);
          print(" => ");
          print(rule.newName);
        then
          ();

      case ConversionRule.MODIFIERS()
        algorithm
          print("convertModifiers: ");
          print(List.toString(rule.oldMods, Dump.unparseElementArgStr, "", "{", ", ", "}", true));
          print(" => ");
          print(List.toString(rule.newMods, Dump.unparseElementArgStr, "", "{", ", ", "}", true));
        then
          ();

      case ConversionRule.MESSAGE()
        algorithm
          print("convertMessage: \"");
          print(rule.message);
          print("\"");
        then
          ();

    end match;

    print("\n");
  end dumpRule;

  function convertProgram
    "Converts an Absyn.Program."
    input output Absyn.Program program;
    input ConversionRules rules;
  algorithm
    program.classes := list(convertClass(c, rules, {}) for c in program.classes);
  end convertProgram;

  function convertClass
    "Converts an Absyn.Class."
    input output Absyn.Class cls;
    input ConversionRules rules;
    input list<ConversionRules> extendsRules;
  algorithm
    cls.body := convertClassDef(cls.body, rules, extendsRules, cls.info);
  end convertClass;

  function convertClassDef
    "Converts an Absyn.ClassDef."
    input output Absyn.ClassDef cdef;
    input ConversionRules rules;
    input list<ConversionRules> extendsRules;
    input SourceInfo info;
  algorithm
    () := match cdef
      local
        Option<ConversionRule> ty_rule;
        RuleTable local_rules;
        list<ConversionRule> mod_rules;

      case Absyn.ClassDef.PARTS()
        algorithm
          cdef.classParts := convertClassParts(cdef.classParts, newRuleTable(), rules, info);
        then
          ();

      case Absyn.ClassDef.DERIVED()
        algorithm
          (ty_rule, local_rules, mod_rules) := lookupTypeRules(AbsynUtil.typeSpecPath(cdef.typeSpec), rules);
          cdef.typeSpec := convertTypeSpec(cdef.typeSpec, ty_rule, local_rules, rules, info);
          cdef.arguments := convertModification2(mod_rules, cdef.arguments);
          cdef.arguments := convertElementArgs(cdef.arguments, local_rules, rules);
        then
          ();

      case Absyn.ClassDef.CLASS_EXTENDS()
        algorithm
          (local_rules, mod_rules) := lookupClassExtendsRules(cdef.baseClassName, extendsRules);
          cdef.modifications := convertModification2(mod_rules, cdef.modifications);
          cdef.modifications := convertElementArgs(cdef.modifications, local_rules, rules);
          cdef.parts := convertClassParts(cdef.parts, local_rules, rules, info);
        then
          ();

      else ();
    end match;
  end convertClassDef;

  function convertClassParts
    "Converts a list of Absyn.ClassParts."
    input output list<Absyn.ClassPart> parts;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  protected
    list<ConversionRules> extends_rules;
  algorithm
    extends_rules := getExtendsRules(parts, rules);
    parts := list(convertClassPart(p, localRules, rules, extends_rules, info) for p in parts);
  end convertClassParts;

  function convertClassPart
    "Converts an Absyn.ClassPart."
    input output Absyn.ClassPart part;
    input RuleTable localRules;
    input ConversionRules rules;
    input list<ConversionRules> extendsRules;
    input SourceInfo info;
  algorithm
    () := match part
      case Absyn.ClassPart.PUBLIC()
        algorithm
          part.contents := convertElementItems(part.contents, rules, extendsRules);
        then
          ();

      case Absyn.ClassPart.PROTECTED()
        algorithm
          part.contents := convertElementItems(part.contents, rules, extendsRules);
        then
          ();

      case Absyn.ClassPart.EQUATIONS()
        algorithm
          part.contents := convertEquationItems(part.contents, localRules, rules);
        then
          ();

      case Absyn.ClassPart.INITIALEQUATIONS()
        algorithm
          part.contents := convertEquationItems(part.contents, localRules, rules);
        then
          ();

      case Absyn.ClassPart.ALGORITHMS()
        algorithm
          part.contents := convertAlgorithmItems(part.contents, localRules, rules);
        then
          ();

      case Absyn.ClassPart.INITIALALGORITHMS()
        algorithm
          part.contents := convertAlgorithmItems(part.contents, localRules, rules);
        then
          ();

      case Absyn.ClassPart.EXTERNAL()
        algorithm
          part.externalDecl := convertExternalDecl(part.externalDecl, localRules, rules, info);
        then
          ();

      else ();
    end match;
  end convertClassPart;

  function convertElementArgs
    "Converts a list of Absyn.ElementArgs."
    input output list<Absyn.ElementArg> args;
    input RuleTable localRules;
    input ConversionRules rules;
  algorithm
    args := list(convertElementArg(a, localRules, rules) for a in args);
  end convertElementArgs;

  function convertElementArg
    "Converts an Absyn.ElementArg."
    input output Absyn.ElementArg arg;
    input RuleTable localRules;
    input ConversionRules rules;
  algorithm
    () := match arg
      local
        list<ConversionRule> mod_rules;

      case Absyn.ElementArg.MODIFICATION()
        algorithm
          mod_rules := UnorderedMap.getOrDefault(AbsynUtil.pathString(arg.path), localRules, {});

          for rule in mod_rules loop
            () := match rule
              case ConversionRule.ELEMENT()
                algorithm
                  arg.path := Absyn.IDENT(rule.newName);
                then
                  ();

              else ();
            end match;
          end for;

          arg.modification := convertModificationExps(arg.modification, localRules, rules, arg.info);
        then
          ();

      case Absyn.ElementArg.REDECLARATION()
        algorithm
          arg.elementSpec := convertElementSpec(arg.elementSpec, rules, {}, arg.info);
          arg.constrainClass := convertOption(arg.constrainClass, convertConstrainClass, rules, arg.info);
        then
          ();

    end match;
  end convertElementArg;

  function convertModificationExps
    "Converts the expressions in an Absyn.Modification (but not the modifier
     names, which is handled by convertModification)."
    input output Option<Absyn.Modification> mod;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    mod := convertOption(mod, function convertModificationExps2(localRules = localRules), rules, info);
  end convertModificationExps;

  function convertModificationExps2
    input output Absyn.Modification mod;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    mod.elementArgLst := convertElementArgs(mod.elementArgLst, localRules, rules);
    mod.eqMod := convertEqMod(mod.eqMod, localRules, rules);
  end convertModificationExps2;

  function convertEqMod
    "Converts the expressions in an Absyn.EqMod."
    input output Absyn.EqMod mod;
    input RuleTable localRules;
    input ConversionRules rules;
  algorithm
    () := match mod
      case Absyn.EqMod.EQMOD()
        algorithm
          mod.exp := convertExp(mod.exp, localRules, rules, mod.info);
        then
          ();

      else ();
    end match;
  end convertEqMod;

  function convertModification
    "Converts an Absyn.Modification using convertModifiers rules."
    input output Option<Absyn.Modification> mod;
    input list<ConversionRule> modifierRules;
  protected
    list<Absyn.ElementArg> elem_args;
    Absyn.EqMod eq_mod;
  algorithm
    if isSome(mod) then
      SOME(Absyn.Modification.CLASSMOD(elem_args, eq_mod)) := mod;
    else
      elem_args := {};
      eq_mod := Absyn.EqMod.NOMOD();
    end if;

    elem_args := convertModification2(modifierRules, elem_args);

    mod := match (elem_args, eq_mod)
      case ({}, Absyn.EqMod.NOMOD()) then NONE();
      else SOME(Absyn.Modification.CLASSMOD(elem_args, eq_mod));
    end match;
  end convertModification;

  function convertModification2
    input list<ConversionRule> modifierRules;
    input output list<Absyn.ElementArg> elemArgs;
  algorithm
    for rule in modifierRules loop
      elemArgs := convertModifier(rule, elemArgs);
    end for;
  end convertModification2;

  function convertModifier
    "Applies a single convertModifiers rule to a list of Absyn.ElementArgs."
    input ConversionRule rule;
    input output list<Absyn.ElementArg> elemArgs;
  protected
    list<Absyn.ElementArg> old_mods, new_mods, matching_mods, rest_mods;
    UnorderedMap<String, Option<Absyn.Exp>> placeholders;
    SourceInfo info;
  algorithm
    ConversionRule.MODIFIERS(oldMods = old_mods, newMods = new_mods, info = info) := rule;

    if listEmpty(old_mods) then
      // If the list of old modifiers is empty, just add the new modifiers.
      elemArgs := mergeModifiers(elemArgs, new_mods);
    else
      // Otherwise, filter out the referenced old modifiers from the list of
      // modifiers on the element.
      (matching_mods, rest_mods) :=
        List.splitOnTrue(elemArgs, function isModifierInList(mods = old_mods));

      if not listEmpty(matching_mods) then
        // If any old modifiers matched, replace them with the new modifiers.
        placeholders := makePlaceholderTable(listAppend(old_mods, matching_mods));
        new_mods := list(replacePlaceholders(m, placeholders, info) for m in new_mods);
        elemArgs := mergeModifiers(rest_mods, new_mods);
      end if;
    end if;
  end convertModifier;

  function isModifierInList
    "Returns whether a modifier with the same name exists in the given list."
    input Absyn.ElementArg mod;
    input list<Absyn.ElementArg> mods;
    output Boolean res = List.exist(mods, function isEqualNameMod(mod2 = mod));
  end isModifierInList;

  function isEqualNameMod
    "Returns whether the two modifiers have the same name or not."
    input Absyn.ElementArg mod1;
    input Absyn.ElementArg mod2;
    output Boolean res;
  algorithm
    res := match (mod1, mod2)
      case (Absyn.ElementArg.MODIFICATION(), Absyn.ElementArg.MODIFICATION())
        then AbsynUtil.pathEqual(mod1.path, mod2.path);

      else false;
    end match;
  end isEqualNameMod;

  function makePlaceholderTable
    "Creates a table with placeholders and the values they should be replaced with."
    input list<Absyn.ElementArg> args;
    output UnorderedMap<String, Option<Absyn.Exp>> placeholders;
  protected
    type OptExp = Option<Absyn.Exp>;
  algorithm
    placeholders := UnorderedMap.new<OptExp>(System.stringHashDjb2Mod, stringEq);

    for arg in args loop
      UnorderedMap.add(AbsynUtil.pathString(AbsynUtil.elementArgName(arg)),
        getElementArgBinding(arg), placeholders);
    end for;
  end makePlaceholderTable;

  function getElementArgBinding
    "Returns the binding of a modifier, or NONE() if the modifier has not binding."
    input Absyn.ElementArg arg;
    output Option<Absyn.Exp> exp;
  protected
    Absyn.Exp e;
  algorithm
    exp := match arg
      case Absyn.ElementArg.MODIFICATION(modification =
          SOME(Absyn.Modification.CLASSMOD(eqMod = Absyn.EqMod.EQMOD(exp = e))))
        then SOME(e);

      else NONE();
    end match;
  end getElementArgBinding;

  function replacePlaceholders
    "Replaces placeholders with their respective values in a modifier."
    input output Absyn.ElementArg arg;
    input UnorderedMap<String, Option<Absyn.Exp>> placeholders;
    input SourceInfo info;
  protected
    Absyn.Modification mod;
    list<Absyn.ElementArg> args;
    Absyn.EqMod eq_mod;
  algorithm
    () := match arg
      case Absyn.ElementArg.MODIFICATION(modification = SOME(mod))
        algorithm
          Absyn.Modification.CLASSMOD(args, eq_mod) := mod;
          args := list(replacePlaceholders(a, placeholders, info) for a in args);
          eq_mod := replacePlaceholdersEqMod(eq_mod, placeholders, {arg.info, info});
          arg.modification := SOME(Absyn.Modification.CLASSMOD(args, eq_mod));
        then
          ();

      else ();
    end match;
  end replacePlaceholders;

  function replacePlaceholdersEqMod
    "Replaces placeholders with their respective values in an Absyn.EqMod."
    input output Absyn.EqMod eqMod;
    input UnorderedMap<String, Option<Absyn.Exp>> placeholders;
    input list<SourceInfo> info;
  algorithm
    () := match eqMod
      case Absyn.EqMod.EQMOD()
        algorithm
          eqMod.exp := AbsynUtil.traverseExp(eqMod.exp,
            function replacePlaceholdersExp(info = info), placeholders);
        then
          ();

      else ();
    end match;
  end replacePlaceholdersEqMod;

  function replacePlaceholdersExp
    "Replaces placeholders with their respective values in an Absyn.Exp."
    input Absyn.Exp exp;
    input UnorderedMap<String, Option<Absyn.Exp>> placeholders;
    input list<SourceInfo> info;
    output Absyn.Exp outExp;
    output UnorderedMap<String, Option<Absyn.Exp>> outPlaceholders = placeholders;
  protected
    String name;
    Integer len;
    Option<Absyn.Exp> new_exp;
  algorithm
    outExp := match exp
      case Absyn.Exp.CREF(componentRef =
          Absyn.ComponentRef.CREF_IDENT(name = name, subscripts = {}))
        algorithm
          len := stringLength(name);

          // Placeholders have the form '%name%'
          if len > 4 and stringGet(name, 1) == 39 and stringGet(name, 2) == 37 and
                         stringGet(name, len - 1) == 37 and stringGet(name, len) == 39 then
            name := substring(name, 3, len - 2);
            new_exp := UnorderedMap.getOrDefault(name, placeholders, NONE());

            if isNone(new_exp) then
              Error.addMultiSourceMessage(Error.CONVERSION_MISSING_PLACEHOLDER_VALUE,
                {"%" + name + "%"}, info);
            end if;

            SOME(outExp) := new_exp;
          else
            outExp := exp;
          end if;
        then
          outExp;

      else exp;
    end match;
  end replacePlaceholdersExp;

  function mergeModifiers
    "Merges two lists of modifiers, with the outer modifiers having precedence."
    input list<Absyn.ElementArg> outerMods;
    input list<Absyn.ElementArg> innerMods;
    output list<Absyn.ElementArg> mods = outerMods;
  algorithm
    for m in listReverse(innerMods) loop
      if not isModifierInList(m, outerMods) then
        mods := m :: mods;
      end if;
    end for;
  end mergeModifiers;

  function convertTypeSpec
    "Converts an Absyn.TypeSpec."
    input output Absyn.TypeSpec ty;
    input Option<ConversionRule> typeRule;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    () := match ty
      case Absyn.TypeSpec.TPATH()
        algorithm
          if isSome(typeRule) then
            ty.path := convertTypePath(ty.path, Util.getOption(typeRule), info);
          end if;

          ty.arrayDim := convertOption(ty.arrayDim,
            function convertSubscripts(localRules = localRules), rules, info);
        then
          ();

      case Absyn.TypeSpec.TCOMPLEX()
        algorithm
          if isSome(typeRule) then
            ty.path := convertTypePath(ty.path, Util.getOption(typeRule), info);
          end if;

          ty.typeSpecs := list(convertTypeSpec(t, NONE(), localRules, rules, info) for t in ty.typeSpecs);
          ty.arrayDim := convertOption(ty.arrayDim,
            function convertSubscripts(localRules = localRules), rules, info);
        then
          ();

      else ();
    end match;
  end convertTypeSpec;

  function convertTypePath
    "Converts an Absyn.Path representing a type."
    input output Absyn.Path path;
    input ConversionRule rule;
    input SourceInfo info;
  algorithm
    () := match rule
      case ConversionRule.CLASS()
        algorithm
          if AbsynUtil.pathPartCount(path) == arrayLength(rule.oldPath) then
            path := rule.newPath;
          else
            path := Util.foldcallN(arrayLength(rule.oldPath), AbsynUtil.pathRest, path);
            path := AbsynUtil.joinPaths(rule.newPath, path);
          end if;
        then
          ();

      case ConversionRule.MESSAGE()
        algorithm
          Error.addSourceMessage(Error.CONVERSION_MESSAGE,
            {rule.message}, info);
        then
          ();

      else ();
    end match;
  end convertTypePath;

  function convertElementItems
    "Converts a list of Absyn.ElementItems."
    input output list<Absyn.ElementItem> elements;
    input ConversionRules rules;
    input list<ConversionRules> extendsRules;
  algorithm
    elements := list(convertElementItem(e, rules, extendsRules) for e in elements);
  end convertElementItems;

  function convertElementItem
    "Converts an Absyn.ElementItem."
    input output Absyn.ElementItem element;
    input ConversionRules rules;
    input list<ConversionRules> extendsRules;
  algorithm
    () := match element
      case Absyn.ElementItem.ELEMENTITEM()
        algorithm
          element.element := convertElement(element.element, rules, extendsRules);
        then
          ();

      else ();
    end match;
  end convertElementItem;

  function convertElement
    "Converts an Absyn.Element."
    input output Absyn.Element element;
    input ConversionRules rules;
    input list<ConversionRules> extendsRules;
  algorithm
    () := match element
      local
        RuleTable local_rules;

      case Absyn.Element.ELEMENT()
        algorithm
          element.specification := convertElementSpec(element.specification,
            rules, extendsRules, element.info);
          element.constrainClass := convertOption(element.constrainClass,
            convertConstrainClass, rules, element.info);
        then
          ();

      case Absyn.Element.DEFINEUNIT()
        algorithm
          local_rules := newRuleTable();
          element.args := list(convertNamedArg(a, local_rules, rules, element.info) for a in element.args);
        then
          ();

      else ();
    end match;
  end convertElement;

  function convertConstrainClass
    "Converts an Absyn.ConstrainClass."
    input output Absyn.ConstrainClass cc;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    cc.elementSpec := convertElementSpec(cc.elementSpec, rules, {}, info);
  end convertConstrainClass;

  function convertElementSpec
    "Converts an Absyn.ElementSpec."
    input output Absyn.ElementSpec spec;
    input ConversionRules rules;
    input list<ConversionRules> extendsRules;
    input SourceInfo info;
  algorithm
    () := match spec
      local
        Option<ConversionRule> ty_rule;
        RuleTable local_rules;
        list<ConversionRule> mod_rules;

      case Absyn.ElementSpec.CLASSDEF()
        algorithm
          spec.class_ := convertClass(spec.class_, rules, extendsRules);
        then
          ();

      case Absyn.ElementSpec.EXTENDS()
        algorithm
          (ty_rule, local_rules, mod_rules) := lookupTypeRules(spec.path, rules);
          spec.path := convertPath(spec.path, rules, info);
          spec.elementArg := convertModification2(mod_rules, spec.elementArg);
          spec.elementArg := convertElementArgs(spec.elementArg, local_rules, rules);
        then
          ();

      case Absyn.ElementSpec.IMPORT()
        algorithm
          spec.import_ := convertImport(spec.import_, rules, info);
        then
          ();

      case Absyn.ElementSpec.COMPONENTS()
        algorithm
          (ty_rule, local_rules, mod_rules) := lookupTypeRules(AbsynUtil.typeSpecPath(spec.typeSpec), rules);
          spec.typeSpec := convertTypeSpec(spec.typeSpec, ty_rule, local_rules, rules, info);
          spec.components := list(convertComponentItem(c, local_rules, mod_rules, rules, info) for c in spec.components);
        then
          ();

      else ();
    end match;
  end convertElementSpec;

  function convertImport
    "Converts an Absyn.Import."
    input output Absyn.Import imp;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    () := match imp
      case Absyn.Import.NAMED_IMPORT()
        algorithm
          imp.path := convertPath(imp.path, rules, info);
        then
          ();

      case Absyn.Import.QUAL_IMPORT()
        algorithm
          imp.path := convertPath(imp.path, rules, info);
        then
          ();

      case Absyn.Import.UNQUAL_IMPORT()
        algorithm
          imp.path := convertPath(imp.path, rules, info);
        then
          ();

      case Absyn.Import.GROUP_IMPORT()
        algorithm
          imp.prefix := convertPath(imp.prefix, rules, info);
        then
          ();

      else ();
    end match;
  end convertImport;

  function convertComponentItem
    "Converts an Absyn.ComponentItem."
    input output Absyn.ComponentItem comp;
    input RuleTable localRules;
    input list<ConversionRule> modifierRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    comp.component := convertComponent(comp.component, localRules, modifierRules, rules, info);
    comp.condition := convertOptExp(comp.condition, localRules, rules, info);
  end convertComponentItem;

  function convertComponent
    "Converts an Absyn.Component."
    input output Absyn.Component comp;
    input RuleTable localRules;
    input list<ConversionRule> modifierRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    comp.arrayDim := convertSubscripts(comp.arrayDim, localRules, rules, info);

    if not listEmpty(modifierRules) then
      comp.modification := convertModification(comp.modification, modifierRules);
    end if;

    comp.modification := convertModificationExps(comp.modification, localRules, rules, info);
  end convertComponent;

  function convertEquationItems
    "Converts a list of Absyn.EquationItems."
    input output list<Absyn.EquationItem> eqs;
    input RuleTable localRules;
    input ConversionRules rules;
  algorithm
    eqs := list(convertEquationItem(eq, localRules, rules) for eq in eqs);
  end convertEquationItems;

  function convertEquationItem
    "Converts an Absyn.EquationItem."
    input output Absyn.EquationItem eq;
    input RuleTable localRules;
    input ConversionRules rules;
  algorithm
    () := match eq
      case Absyn.EquationItem.EQUATIONITEM()
        algorithm
          eq.equation_ := convertEquation(eq.equation_, localRules, rules, eq.info);
        then
          ();

      else ();
    end match;
  end convertEquationItem;

  function convertEquation
    "Converts an Absyn.Equation."
    input output Absyn.Equation eq;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    () := match eq
      case Absyn.Equation.EQ_IF()
        algorithm
          eq.ifExp := convertExp(eq.ifExp, localRules, rules, info);
          eq.equationTrueItems := convertEquationItems(eq.equationTrueItems, localRules, rules);
          eq.elseIfBranches := convertBranches(eq.elseIfBranches,
            function convertExp(info = info), convertEquationItems, localRules, rules);
          eq.equationElseItems := convertEquationItems(eq.equationElseItems, localRules, rules);
        then
          ();

      case Absyn.Equation.EQ_EQUALS()
        algorithm
          eq.leftSide := convertExp(eq.leftSide, localRules, rules, info);
          eq.rightSide := convertExp(eq.rightSide, localRules, rules, info);
        then
          ();

      case Absyn.Equation.EQ_PDE()
        algorithm
          eq.leftSide := convertExp(eq.leftSide, localRules, rules, info);
          eq.rightSide := convertExp(eq.rightSide, localRules, rules, info);
        then
          ();

      case Absyn.Equation.EQ_CONNECT()
        algorithm
          eq.connector1 := convertCref(eq.connector1, localRules, rules, info);
          eq.connector2 := convertCref(eq.connector2, localRules, rules, info);
        then
          ();

      case Absyn.Equation.EQ_FOR()
        algorithm
          eq.iterators := convertForIterators(eq.iterators, localRules, rules, info);
          eq.forEquations := convertEquationItems(eq.forEquations, localRules, rules);
        then
          ();

      case Absyn.Equation.EQ_WHEN_E()
        algorithm
          eq.whenExp := convertExp(eq.whenExp, localRules, rules, info);
          eq.whenEquations := convertEquationItems(eq.whenEquations, localRules, rules);
          eq.elseWhenEquations := convertBranches(eq.elseWhenEquations,
            function convertExp(info = info), convertEquationItems, localRules, rules);
        then
          ();

      case Absyn.Equation.EQ_NORETCALL()
        algorithm
          eq.functionName := convertCref(eq.functionName, localRules, rules, info);
          eq.functionArgs := convertFunctionArgs(eq.functionArgs, localRules, rules, info);
        then
          ();

      case Absyn.Equation.EQ_FAILURE()
        algorithm
          eq.equ := convertEquationItem(eq.equ, localRules, rules);
        then
          ();

      else ();
    end match;
  end convertEquation;

  function convertAlgorithmItems
    "Converts a list of Absyn.AlgorithmItems."
    input output list<Absyn.AlgorithmItem> algs;
    input RuleTable localRules;
    input ConversionRules rules;
  algorithm
    algs := list(convertAlgorithmItem(alg, localRules, rules) for alg in algs);
  end convertAlgorithmItems;

  function convertAlgorithmItem
    "Converts an Absyn.AlgorithmItem."
    input output Absyn.AlgorithmItem alg;
    input RuleTable localRules;
    input ConversionRules rules;
  algorithm
    () := match alg
      case Absyn.AlgorithmItem.ALGORITHMITEM()
        algorithm
          alg.algorithm_ := convertAlgorithm(alg.algorithm_, localRules, rules, alg.info);
        then
          ();

      else ();
    end match;
  end convertAlgorithmItem;

  function convertAlgorithm
    "Converts an Absyn.Algorithm."
    input output Absyn.Algorithm alg;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    () := match alg
      case Absyn.Algorithm.ALG_ASSIGN()
        algorithm
          alg.assignComponent := convertExp(alg.assignComponent, localRules, rules, info);
          alg.value := convertExp(alg.value, localRules, rules, info);
        then
          ();

      case Absyn.Algorithm.ALG_IF()
        algorithm
          alg.ifExp := convertExp(alg.ifExp, localRules, rules, info);
          alg.trueBranch := convertAlgorithmItems(alg.trueBranch, localRules, rules);
          alg.elseIfAlgorithmBranch := convertBranches(alg.elseIfAlgorithmBranch,
            function convertExp(info = info), convertAlgorithmItems, localRules, rules);
          alg.elseBranch := convertAlgorithmItems(alg.elseBranch, localRules, rules);
        then
          ();

      case Absyn.Algorithm.ALG_FOR()
        algorithm
          alg.iterators := convertForIterators(alg.iterators, localRules, rules, info);
          alg.forBody := convertAlgorithmItems(alg.forBody, localRules, rules);
        then
          ();

      case Absyn.Algorithm.ALG_PARFOR()
        algorithm
          alg.iterators := convertForIterators(alg.iterators, localRules, rules, info);
          alg.parforBody := convertAlgorithmItems(alg.parforBody, localRules, rules);
        then
          ();

      case Absyn.Algorithm.ALG_WHILE()
        algorithm
          alg.boolExpr := convertExp(alg.boolExpr, localRules, rules, info);
          alg.whileBody := convertAlgorithmItems(alg.whileBody, localRules, rules);
        then
          ();

      case Absyn.Algorithm.ALG_WHEN_A()
        algorithm
          alg.boolExpr := convertExp(alg.boolExpr, localRules, rules, info);
          alg.whenBody := convertAlgorithmItems(alg.whenBody, localRules, rules);
          alg.elseWhenAlgorithmBranch := convertBranches(alg.elseWhenAlgorithmBranch,
            function convertExp(info = info), convertAlgorithmItems, localRules, rules);
        then
          ();

      case Absyn.Algorithm.ALG_NORETCALL()
        algorithm
          alg.functionCall := convertCref(alg.functionCall, localRules, rules, info);
          alg.functionArgs := convertFunctionArgs(alg.functionArgs, localRules, rules, info);
        then
          ();

      case Absyn.Algorithm.ALG_FAILURE()
        algorithm
          alg.equ := convertAlgorithmItems(alg.equ, localRules, rules);
        then
          ();

      case Absyn.Algorithm.ALG_TRY()
        algorithm
          alg.body := convertAlgorithmItems(alg.body, localRules, rules);
          alg.elseBody := convertAlgorithmItems(alg.elseBody, localRules, rules);
        then
          ();

      else ();
    end match;
  end convertAlgorithm;

  function convertBranches<CondT, BodyT>
    "Generic function for converting if/when branches."
    input output list<tuple<CondT, BodyT>> branches;
    input CondFunc condFunc;
    input BodyFunc bodyFunc;
    input RuleTable localRules;
    input ConversionRules rules;

    partial function CondFunc
      input output CondT cond;
      input RuleTable localRules;
      input ConversionRules rules;
    end CondFunc;

    partial function BodyFunc
      input output BodyT body;
      input RuleTable localRules;
      input ConversionRules rules;
    end BodyFunc;
  algorithm
    branches := list(
      (condFunc(Util.tuple21(b), localRules, rules),
       bodyFunc(Util.tuple22(b), localRules, rules))
      for b in branches
    );
  end convertBranches;

  function convertForIterators
    "Converts an Absyn.ForIterators."
    input output Absyn.ForIterators iters;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    iters := list(convertForIterator(i, localRules, rules, info) for i in iters);
  end convertForIterators;

  function convertForIterator
    "Converts an Absyn.ForIterator."
    input output Absyn.ForIterator iter;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    iter.guardExp := convertOptExp(iter.guardExp, localRules, rules, info);
    iter.range := convertOptExp(iter.range, localRules, rules, info);
  end convertForIterator;

  function convertExternalDecl
    "Converts an Absyn.ExternalDecl."
    input output Absyn.ExternalDecl extDecl;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    extDecl.args := convertExps(extDecl.args, localRules, rules, info);
  end convertExternalDecl;

  function convertExps
    "Converts a list of Absyn.Exps."
    input output list<Absyn.Exp> exps;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    exps := list(convertExp(e, localRules, rules, info) for e in exps);
  end convertExps;

  function convertOptExp
    "Converts an optional Absyn.Exp."
    input output Option<Absyn.Exp> exp;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    exp := match exp
      local
        Absyn.Exp e;

      case SOME(e) then SOME(convertExp(e, localRules, rules, info));
      else NONE();
    end match;
  end convertOptExp;

  function convertExp
    "Converts an Absyn.Exp."
    input output Absyn.Exp exp;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    () := match exp
      case Absyn.Exp.CREF()
        algorithm
          exp.componentRef := convertCref(exp.componentRef, localRules, rules, info);
        then
          ();

      case Absyn.Exp.BINARY()
        algorithm
          exp.exp1 := convertExp(exp.exp1, localRules, rules, info);
          exp.exp2 := convertExp(exp.exp2, localRules, rules, info);
        then
          ();

      case Absyn.Exp.UNARY()
        algorithm
          exp.exp := convertExp(exp.exp, localRules, rules, info);
        then
          ();

      case Absyn.Exp.LBINARY()
        algorithm
          exp.exp1 := convertExp(exp.exp1, localRules, rules, info);
          exp.exp2 := convertExp(exp.exp2, localRules, rules, info);
        then
          ();

      case Absyn.Exp.LUNARY()
        algorithm
          exp.exp := convertExp(exp.exp, localRules, rules, info);
        then
          ();

      case Absyn.Exp.RELATION()
        algorithm
          exp.exp1 := convertExp(exp.exp1, localRules, rules, info);
          exp.exp2 := convertExp(exp.exp2, localRules, rules, info);
        then
          ();

      case Absyn.Exp.IFEXP()
        algorithm
          exp.ifExp := convertExp(exp.ifExp, localRules, rules, info);
          exp.trueBranch := convertExp(exp.trueBranch, localRules, rules, info);
          exp.elseBranch := convertExp(exp.elseBranch, localRules, rules, info);
          exp.elseIfBranch := convertBranches(exp.elseIfBranch,
            function convertExp(info = info), function convertExp(info = info), localRules, rules);
        then
          ();

      case Absyn.Exp.CALL()
        algorithm
          exp.function_ := convertCref(exp.function_, localRules, rules, info);
          exp.functionArgs := convertFunctionArgs(exp.functionArgs, localRules, rules, info);
        then
          ();

      case Absyn.Exp.PARTEVALFUNCTION()
        algorithm
          exp.function_ := convertCref(exp.function_, localRules, rules, info);
          exp.functionArgs := convertFunctionArgs(exp.functionArgs, localRules, rules, info);
        then
          ();

      case Absyn.Exp.ARRAY()
        algorithm
          exp.arrayExp := convertExps(exp.arrayExp, localRules, rules, info);
        then
          ();

      case Absyn.Exp.MATRIX()
        algorithm
          exp.matrix := list(convertExps(e, localRules, rules, info) for e in exp.matrix);
        then
          ();

      case Absyn.Exp.RANGE()
        algorithm
          exp.start := convertExp(exp.start, localRules, rules, info);
          exp.step := convertOptExp(exp.step, localRules, rules, info);
          exp.stop := convertExp(exp.stop, localRules, rules, info);
        then
          ();

      case Absyn.Exp.TUPLE()
        algorithm
          exp.expressions := convertExps(exp.expressions, localRules, rules, info);
        then
          ();

      else ();
    end match;
  end convertExp;

  function convertCref
    "Converts an Absyn.ComponentRef."
    input output Absyn.ComponentRef cref;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  protected
    Absyn.Path path;
    list<ConversionRule> cref_rules;
    ConversionRule rule;
  algorithm
    if AbsynUtil.crefIsWild(cref) then
      return;
    end if;

    if AbsynUtil.crefHasSubscripts(cref) then
      cref := convertCrefSubscripts(cref, localRules, rules, info);
    else
      cref_rules := UnorderedMap.getOrDefault(AbsynUtil.crefFirstIdent(cref), localRules, {});

      if listEmpty(cref_rules) then
        path := AbsynUtil.crefToPath(cref);
        path := convertPath(path, rules, info);
        cref := AbsynUtil.pathToCref(path);
      else
        rule := listHead(cref_rules);

        cref := match rule
          case ConversionRule.ELEMENT()
            then AbsynUtil.crefSetFirstIdent(cref, rule.newName);

          else cref;
        end match;
      end if;
    end if;
  end convertCref;

  function convertCrefSubscripts
    "Converts an Absyn.ComponentRef."
    input output Absyn.ComponentRef cref;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    () := match cref
      case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
        algorithm
          cref.componentRef := convertCrefSubscripts(cref.componentRef, localRules, rules, info);
        then
          ();

      case Absyn.ComponentRef.CREF_QUAL()
        algorithm
          cref.subscripts := convertSubscripts(cref.subscripts, localRules, rules, info);
          cref.componentRef := convertCrefSubscripts(cref.componentRef, localRules, rules, info);
        then
          ();

      case Absyn.ComponentRef.CREF_IDENT()
        algorithm
          cref.subscripts := convertSubscripts(cref.subscripts, localRules, rules, info);
        then
          ();

      else ();
    end match;
  end convertCrefSubscripts;

  function convertSubscripts
    "Converts a list of Absyn.Subscripts."
    input output list<Absyn.Subscript> subs;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    subs := list(convertSubscript(s, localRules, rules, info) for s in subs);
  end convertSubscripts;

  function convertSubscript
    "Converts an Absyn.Subscript."
    input output Absyn.Subscript sub;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    () := match sub
      case Absyn.Subscript.SUBSCRIPT()
        algorithm
          sub.subscript := convertExp(sub.subscript, localRules, rules, info);
        then
          ();

      else ();
    end match;
  end convertSubscript;

  function convertPath
    "Converts an Absyn.Path."
    input output Absyn.Path path;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    path := applyRulesPath(path, lookupRules(path, rules), info);
  end convertPath;

  function applyRulesPath
    input output Absyn.Path path;
    input list<list<ConversionRule>> rules;
    input SourceInfo info;
  protected
    Integer path_len = AbsynUtil.pathPartCount(path);
    Boolean found;
  algorithm
    for rl in rules loop
      for rule in rl loop
        found := match rule
          case ConversionRule.CLASS()
            algorithm
              if path_len == arrayLength(rule.oldPath) then
                // convertClass(A.B.C, X.Y.Z) on A.B.C => X.Y.Z
                path := rule.newPath;
              else
                // convertClass(A.B.C, X.Y.Z) on A.B.C.D... => X.Y.Z.D...
                path := Util.foldcallN(arrayLength(rule.oldPath), AbsynUtil.pathRest, path);
                path := AbsynUtil.joinPaths(rule.newPath, path);
              end if;
            then
              true;

          case ConversionRule.ELEMENT()
            guard path_len > arrayLength(rule.oldPath) and
                  AbsynUtil.pathNthIdent(path, arrayLength(rule.oldPath) + 1) == rule.oldName
            algorithm
              if path_len == arrayLength(rule.oldPath) - 1 then
                // convertElement(A.B.C, X, Y) on A.B.C.X => A.B.C.Y
                path := AbsynUtil.pathSetLastIdent(path, rule.newName);
              else
                // convertElement(A.B.C, X, Y) on A.B.C.X.E... => A.B.C.Y.E...
                path := AbsynUtil.pathSetNthIdent(path, rule.newName,
                  arrayLength(rule.oldPath) + 1);
              end if;
            then
              true;

          case ConversionRule.MESSAGE()
            algorithm
              Error.addSourceMessage(Error.CONVERSION_MESSAGE, {rule.message}, info);
            then
              true;

          else false;
        end match;

        if found then
          return;
        end if;
      end for;
    end for;
  end applyRulesPath;

  function convertFunctionArgs
    "Converts an Absyn.FunctionArgs."
    input output Absyn.FunctionArgs args;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    () := match args
      case Absyn.FunctionArgs.FUNCTIONARGS()
        algorithm
          args.args := convertExps(args.args, localRules, rules, info);
          args.argNames := list(convertNamedArg(a, localRules, rules, info) for a in args.argNames);
        then
          ();

      case Absyn.FunctionArgs.FOR_ITER_FARG()
        algorithm
          args.exp := convertExp(args.exp, localRules, rules, info);
          args.iterators := convertForIterators(args.iterators, localRules, rules, info);
        then
          ();

    end match;
  end convertFunctionArgs;

  function convertNamedArg
    "Converts an Absyn.NamedArg."
    input output Absyn.NamedArg arg;
    input RuleTable localRules;
    input ConversionRules rules;
    input SourceInfo info;
  algorithm
    arg.argValue := convertExp(arg.argValue, localRules, rules, info);
  end convertNamedArg;

  function convertOption<T>
    "Converts an optional value using the given conversion function."
    input output Option<T> opt;
    input OptFunc optFunc;
    input ConversionRules rules;
    input SourceInfo info;

    partial function OptFunc
      input output T e;
      input ConversionRules rules;
      input SourceInfo info;
    end OptFunc;
  protected
    T e;
  algorithm
    opt := match opt
      case SOME(e) then SOME(optFunc(e, rules, info));
      else opt;
    end match;
  end convertOption;

  function getExtendsRules
    "Returns the rules for any extends clauses in the given list of class parts."
    input list<Absyn.ClassPart> parts;
    input ConversionRules rules;
    output list<ConversionRules> extendsRules = {};
  protected
    Option<ConversionRules> onode;
  algorithm
    for ext in getExtendsPathsInParts(parts) loop
      onode := lookupRuleNode(ext, rules);

      if isSome(onode) then
        extendsRules := Util.getOption(onode) :: extendsRules;
      end if;
    end for;
  end getExtendsRules;

  function getExtendsPathsInParts
    "Returns a list of extends clauses in the given list of class parts."
    input list<Absyn.ClassPart> parts;
    output list<Absyn.Path> extendsPaths = {};
  algorithm
    for part in parts loop
      () := match part
        case Absyn.ClassPart.PUBLIC()
          algorithm
            for e in part.contents loop
              extendsPaths := getExtendsPathsInElementItem(e, extendsPaths);
            end for;
          then
            ();

        case Absyn.ClassPart.PROTECTED()
          algorithm
            for e in part.contents loop
              extendsPaths := getExtendsPathsInElementItem(e, extendsPaths);
            end for;
          then
            ();

        else ();
      end match;
    end for;
  end getExtendsPathsInParts;

  function getExtendsPathsInElementItem
    "Appends the path of the element to the given list if the element is an extends clause."
    input Absyn.ElementItem element;
    input output list<Absyn.Path> extendsPaths;
  algorithm
    () := match element
      local
        Absyn.Path ext_path;

      case Absyn.ElementItem.ELEMENTITEM(element =
          Absyn.Element.ELEMENT(specification = Absyn.ElementSpec.EXTENDS(path = ext_path)))
        algorithm
          extendsPaths := ext_path :: extendsPaths;
        then
          ();

      else ();
    end match;
  end getExtendsPathsInElementItem;

  annotation(__OpenModelica_Interface="backend");
end Conversion;

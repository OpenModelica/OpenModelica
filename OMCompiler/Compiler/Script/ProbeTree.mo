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

encapsulated package ProbeTree
  "The probe tree of a file and the properties of its nodes, for property
   probing tools like CodeProber, see getProbeTree and evaluateProbe.

   The tree is built from the abstract syntax of the file: the classes, the
   elements and the equations and statements, nested like in the source, with
   the names found by NFDefUseChains as leaves (Ident), each in the smallest
   node it's in. A node is identified by the path of child indices from the
   root, e.g. 0.1.3, which stays the same as long as the file doesn't change.
   The properties are evaluated on the loaded classes, so the file has to be
   loaded too. The results of translateModel are kept in a directory named by
   the hash of the name and contents of the file in the temporary directory, so
   the simulation equations of a model are only generated once for each version
   of the file."

  import Absyn;
  import JSON;

protected
  import AbsynUtil;
  import CevalScriptBackend;
  import Dump;
  import Error;
  import ErrorExt;
  import ErrorTypes;
  import FCore;
  import FGraph;
  import Flags;
  import FlagsUtil;
  import List;
  import NFDefUseChains;
  import NFDefUseChains.Position;
  import NFUsedElements;
  import NFUsedElements.Definition;
  import NFUsedElements.Use;
  import Parser;
  import Settings;
  import StringUtil;
  import SymbolTable;
  import Testsuite;
  import System;
  import UnorderedMap;
  import Util;
  import Values;
  import Vector;

  uniontype NodeData
    record FILE_DATA
    end FILE_DATA;

    record CLASS_DATA
      Absyn.Path path;
      Absyn.Class cls;
    end CLASS_DATA;

    record COMPONENT_DATA
      String name "The full name, e.g. P.R.r.";
      Absyn.Path classPath;
    end COMPONENT_DATA;

    record CLAUSE_DATA
      "A component clause with several components, an extends or an import."
    end CLAUSE_DATA;

    record EQUATION_DATA
      Absyn.Equation eq;
    end EQUATION_DATA;

    record STATEMENT_DATA
      Absyn.Algorithm alg;
    end STATEMENT_DATA;

    record NAME_DATA
      list<Use> uses "What the name refers to, the first that isn't a candidate first.";
      Option<Definition> declares "The definition this name is the declared name of.";
    end NAME_DATA;
  end NodeData;

  uniontype ProbeNode
    record NODE
      String id;
      String kind;
      String label;
      SourceInfo info;
      NodeData data;
      list<ProbeNode> children;
    end NODE;
  end ProbeNode;

  uniontype Tree
    record TREE
      String fileName "The file name as in the source info of the classes.";
      String path "The file as given.";
      array<String> lines;
      ProbeNode root;
      UnorderedMap<String, Definition> definitions "By key.";
      UnorderedMap<String, Definition> declared "By full name.";
      UnorderedMap<String, String> declaringNode "The id of the node declaring a definition, by key.";
      UnorderedMap<String, String> nameNode "The id of the Ident node, by position line:column.";
      list<tuple<Use, Position>> uses;
      list<tuple<Use, Position>> unresolved;
    end TREE;
  end Tree;

  uniontype Message
    record MESSAGE
      String severity "error, warning or info.";
      String text;
      SourceInfo info;
    end MESSAGE;
  end Message;

  uniontype Translation
    record TRANSLATION
      Boolean ok;
      String modelName;
      String directory;
      JSON info "The _info.json, NULL if the translation failed.";
      list<Message> messages;
    end TRANSLATION;
  end Translation;

  type NodeList = list<ProbeNode>;
  type StringList = list<String>;
  type Items = list<JSON>;
  type DefOption = Option<Definition>;

  constant String ARROW_COLOR = "#27ef";
  // The moduli of the hashes that name the translation directories, like the
  // ones of NFDefUseChains, small enough for 32-bit targets.
  constant Integer HASH_MOD1 = 4082651;
  constant Integer HASH_MOD2 = 4082629;

public
  function probeTreeJSON
    "Returns the probe tree of a file as JSON, or the syntax errors if it can't
     be parsed."
    input String fileName;
    input Boolean prettyPrint;
    output String json;
  protected
    Option<Tree> otree;
    list<Message> errors;
    Tree tree;
    JSON obj = JSON.emptyListObject();
  algorithm
    (otree, errors) := buildTree(fileName);
    obj := JSON.addPair("file", JSON.makeString(fileName), obj);
    obj := JSON.addPair("root", match otree
      case SOME(tree) then nodeJSON(tree.root);
      else JSON.makeNull();
    end match, obj);
    obj := JSON.addPair("errors", JSON.makeArray(list(messageItem(m) for m in errors)), obj);
    json := JSON.toString(obj, prettyPrint);
  end probeTreeJSON;

  function evaluateProbeJSON
    "Evaluates a property of a node of the probe tree of a file and returns
     the result as JSON."
    input String fileName;
    input String nodeId;
    input String property;
    input String contextModel "The model translated for the simulation properties, the enclosing one if empty.";
    input Boolean prettyPrint;
    output String json;
  protected
    Option<Tree> otree;
    list<Message> errors;
    Tree tree;
    list<ProbeNode> path;
    Items result;
    JSON obj = JSON.emptyListObject();
  algorithm
    (otree, errors) := buildTree(fileName);

    result := match otree
      case SOME(tree)
        algorithm
          path := findNode(tree.root, nodeId);
        then
          if listEmpty(path) then {textItem("no node " + nodeId)}
          elseif not listMember(property, properties(listHead(path))) then
            {textItem("no property " + property + " on " + nodeKind(listHead(path)))}
          else evaluate(property, path, tree, contextModel);

      // The file doesn't parse, only its errors can be probed.
      else if property == "errors" then list(messageItem(m) for m in errors)
           else {textItem("the file has syntax errors")};
    end match;

    obj := JSON.addPair("node", JSON.makeString(nodeId), obj);
    obj := JSON.addPair("property", JSON.makeString(property), obj);
    obj := JSON.addPair("result", JSON.makeArray(result), obj);
    json := JSON.toString(obj, prettyPrint);
  end evaluateProbeJSON;

protected
  // ---- building the tree ---------------------------------------------------

  function buildTree
    input String fileName;
    output Option<Tree> tree = NONE();
    output list<Message> errors = {};
  protected
    Absyn.Program program;
    list<Absyn.Path> paths = {};
    Absyn.Path prefix;
    Boolean prefixed;
    list<Definition> defs;
    list<Use> uses, unresolved;
    list<tuple<Definition, Position>> declared;
    list<tuple<Use, Position>> placed, placed_unresolved;
    UnorderedMap<String, Definition> def_map, declared_map;
    UnorderedMap<String, Position> names;
    String file;
    array<String> lines;
    ProbeNode root;
    Tree t;
    Definition d;
    Position pos;
  algorithm
    ErrorExt.setCheckpoint(getInstanceName());
    try
      program := Parser.parse(fileName, "UTF-8");
    else
      errors := list(toMessage(m) for m in ErrorExt.getCheckpointMessages());
      ErrorExt.delCheckpoint(getInstanceName());
      return;
    end try;
    ErrorExt.rollBack(getInstanceName());

    if listEmpty(program.classes) then
      errors := {MESSAGE("info", "the file has no classes", Absyn.dummyInfo)};
      return;
    end if;

    file := AbsynUtil.classFilename(listHead(program.classes));
    (prefixed, prefix) := match program.within_
      case Absyn.WITHIN(path = prefix) then (true, prefix);
      else (false, Absyn.IDENT(""));
    end match;

    for c in program.classes loop
      paths := classPaths(c, if prefixed then AbsynUtil.suffixPath(prefix, c.name) else Absyn.IDENT(c.name), paths);
    end for;

    (defs, uses, unresolved) := CevalScriptBackend.collectDefUse(paths, SymbolTable.getSCode());
    (declared, placed, placed_unresolved) := NFDefUseChains.placeNames(file, defs, uses, unresolved);

    def_map := UnorderedMap.new<Definition>(stringHashDjb2, stringEq);
    for d in defs loop
      UnorderedMap.add(d.key, d, def_map);
    end for;

    declared_map := UnorderedMap.new<Definition>(stringHashDjb2, stringEq);
    names := UnorderedMap.new<Position>(stringHashDjb2, stringEq);
    for dp in declared loop
      (d, pos) := dp;
      UnorderedMap.add(d.name, d, declared_map);
      UnorderedMap.add(d.name, pos, names);
    end for;

    lines := readLines(fileName);
    root := NODE("", "StoredDefinition", fileBaseName(fileName),
      SOURCEINFO(file, true, 1, 1, arrayLength(lines), max(1, stringLength(arrayGet(lines, arrayLength(lines)))), 0.0),
      FILE_DATA(),
      list(classNode(c, if prefixed then AbsynUtil.suffixPath(prefix, c.name) else Absyn.IDENT(c.name), names, lines)
        for c in program.classes));

    root := addNames(root, declared, placed, lines);
    root := assignIds(root, "0");

    t := TREE(file, fileName, lines, root, def_map, declared_map,
      UnorderedMap.new<String>(stringHashDjb2, stringEq),
      UnorderedMap.new<String>(stringHashDjb2, stringEq), placed, placed_unresolved);
    indexNodes(root, t);
    tree := SOME(t);
  end buildTree;

  function classPaths
    "Returns the paths of a class and of the classes declared in it, in reverse order."
    input Absyn.Class cls;
    input Absyn.Path path;
    input output list<Absyn.Path> paths;
  algorithm
    paths := path :: paths;
    for e in classElements(cls) loop
      paths := match e
        local
          Absyn.Class c;
        case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = c)))
          then classPaths(c, AbsynUtil.suffixPath(path, c.name), paths);
        else paths;
      end match;
    end for;
  end classPaths;

  function classParts
    input Absyn.Class cls;
    output list<Absyn.ClassPart> parts;
  algorithm
    parts := match cls.body
      case Absyn.PARTS(classParts = parts) then parts;
      case Absyn.CLASS_EXTENDS(parts = parts) then parts;
      else {};
    end match;
  end classParts;

  function classElements
    input Absyn.Class cls;
    output list<Absyn.ElementItem> elements = {};
  algorithm
    for p in classParts(cls) loop
      elements := match p
        case Absyn.PUBLIC() then listAppend(elements, p.contents);
        case Absyn.PROTECTED() then listAppend(elements, p.contents);
        else elements;
      end match;
    end for;
  end classElements;

  function classNode
    input Absyn.Class cls;
    input Absyn.Path path;
    input UnorderedMap<String, Position> names;
    input array<String> lines;
    output ProbeNode node;
  protected
    list<ProbeNode> children = {};
  algorithm
    for p in classParts(cls) loop
      children := match p
        case Absyn.PUBLIC() then listAppend(children, List.flatten(list(elementNodes(e, path, names, lines) for e in p.contents)));
        case Absyn.PROTECTED() then listAppend(children, List.flatten(list(elementNodes(e, path, names, lines) for e in p.contents)));
        case Absyn.EQUATIONS() then listAppend(children, List.flatten(list(equationNodes(e) for e in p.contents)));
        case Absyn.INITIALEQUATIONS() then listAppend(children, List.flatten(list(equationNodes(e) for e in p.contents)));
        case Absyn.ALGORITHMS() then listAppend(children, List.flatten(list(statementNodes(e) for e in p.contents)));
        case Absyn.INITIALALGORITHMS() then listAppend(children, List.flatten(list(statementNodes(e) for e in p.contents)));
        else children;
      end match;
    end for;

    node := NODE("", "ClassDefinition", cls.name, cls.info, CLASS_DATA(path, cls), children);
  end classNode;

  function elementNodes
    input Absyn.ElementItem item;
    input Absyn.Path classPath;
    input UnorderedMap<String, Position> names;
    input array<String> lines;
    output list<ProbeNode> nodes;
  algorithm
    nodes := match item
      local
        Absyn.Class c;
        Absyn.ElementSpec spec;
        SourceInfo info;
        list<Absyn.ComponentItem> comps;
        String name;

      case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = c)))
        then {classNode(c, AbsynUtil.suffixPath(classPath, c.name), names, lines)};

      case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = spec as Absyn.EXTENDS(), info = info))
        then {NODE("", "ExtendsClause", AbsynUtil.pathString(spec.path), info, CLAUSE_DATA(), {})};

      case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.IMPORT(), info = info))
        then {NODE("", "ImportClause", "", info, CLAUSE_DATA(), {})};

      case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = {Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name))}), info = info))
        then {NODE("", "ComponentDeclaration", name, info,
          COMPONENT_DATA(AbsynUtil.pathString(classPath) + "." + name, classPath), {})};

      // Several components in one clause, each declaration spans from its name to the next one.
      case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = comps), info = info))
        then {NODE("", "ComponentClause", "", info, CLAUSE_DATA(),
          componentNodes(list(c.component.name for c in comps), classPath, info, names, lines))};

      else {};
    end match;
  end elementNodes;

  function componentNodes
    input list<String> compNames;
    input Absyn.Path classPath;
    input SourceInfo clauseInfo;
    input UnorderedMap<String, Position> names;
    input array<String> lines;
    output list<ProbeNode> nodes = {};
  protected
    list<tuple<String, Option<Position>>> found;
    String name, full;
    Option<Position> opos, onext;
    Position pos, next;
    SourceInfo info;
  algorithm
    found := list((n, UnorderedMap.get(AbsynUtil.pathString(classPath) + "." + n, names)) for n in compNames);

    while not listEmpty(found) loop
      (name, opos) :: found := found;
      full := AbsynUtil.pathString(classPath) + "." + name;
      info := clauseInfo;

      if isSome(opos) then
        SOME(pos) := opos;
        if pos.exact then
          info.lineNumberStart := pos.lineStart;
          info.columnNumberStart := pos.columnStart;

          onext := if listEmpty(found) then NONE() else Util.tuple22(listHead(found));
          if isSome(onext) then
            SOME(next) := onext;
            if next.exact and next.columnStart > 1 then
              info.lineNumberEnd := next.lineStart;
              info.columnNumberEnd := next.columnStart - 1;
            elseif next.exact then
              info.lineNumberEnd := next.lineStart - 1;
              info.columnNumberEnd := max(1, stringLength(arrayGet(lines, next.lineStart - 1)));
            end if;
          end if;
        end if;
      end if;

      nodes := NODE("", "ComponentDeclaration", name, info, COMPONENT_DATA(full, classPath), {}) :: nodes;
    end while;

    nodes := listReverse(nodes);
  end componentNodes;

  function equationNodes
    input Absyn.EquationItem item;
    output list<ProbeNode> nodes;
  algorithm
    nodes := match item
      local
        Absyn.Equation eq;
      case Absyn.EQUATIONITEM(equation_ = eq)
        then {NODE("", "Equation", equationLabel(eq), item.info, EQUATION_DATA(eq), nestedEquations(eq))};
      else {};
    end match;
  end equationNodes;

  function nestedEquations
    input Absyn.Equation eq;
    output list<ProbeNode> nodes;
  protected
    list<Absyn.EquationItem> items;
  algorithm
    items := match eq
      case Absyn.EQ_IF() then listAppend(eq.equationTrueItems, listAppend(
        List.flatten(list(Util.tuple22(b) for b in eq.elseIfBranches)), eq.equationElseItems));
      case Absyn.EQ_FOR() then eq.forEquations;
      case Absyn.EQ_WHEN_E() then listAppend(eq.whenEquations,
        List.flatten(list(Util.tuple22(b) for b in eq.elseWhenEquations)));
      else {};
    end match;
    nodes := List.flatten(list(equationNodes(i) for i in items));
  end nestedEquations;

  function equationLabel
    input Absyn.Equation eq;
    output String label;
  algorithm
    label := match eq
      case Absyn.EQ_CONNECT() then "connect";
      case Absyn.EQ_EQUALS() then "=";
      case Absyn.EQ_IF() then "if";
      case Absyn.EQ_FOR() then "for";
      case Absyn.EQ_WHEN_E() then "when";
      case Absyn.EQ_NORETCALL() then AbsynUtil.crefString(eq.functionName);
      else "";
    end match;
  end equationLabel;

  function statementNodes
    input Absyn.AlgorithmItem item;
    output list<ProbeNode> nodes;
  algorithm
    nodes := match item
      local
        Absyn.Algorithm alg;
      case Absyn.ALGORITHMITEM(algorithm_ = alg)
        then {NODE("", "Statement", statementLabel(alg), item.info, STATEMENT_DATA(alg), nestedStatements(alg))};
      else {};
    end match;
  end statementNodes;

  function nestedStatements
    input Absyn.Algorithm alg;
    output list<ProbeNode> nodes;
  protected
    list<Absyn.AlgorithmItem> items;
  algorithm
    items := match alg
      case Absyn.ALG_IF() then listAppend(alg.trueBranch, listAppend(
        List.flatten(list(Util.tuple22(b) for b in alg.elseIfAlgorithmBranch)), alg.elseBranch));
      case Absyn.ALG_FOR() then alg.forBody;
      case Absyn.ALG_PARFOR() then alg.parforBody;
      case Absyn.ALG_WHILE() then alg.whileBody;
      case Absyn.ALG_WHEN_A() then listAppend(alg.whenBody,
        List.flatten(list(Util.tuple22(b) for b in alg.elseWhenAlgorithmBranch)));
      else {};
    end match;
    nodes := List.flatten(list(statementNodes(i) for i in items));
  end nestedStatements;

  function statementLabel
    input Absyn.Algorithm alg;
    output String label;
  algorithm
    label := match alg
      case Absyn.ALG_ASSIGN() then ":=";
      case Absyn.ALG_IF() then "if";
      case Absyn.ALG_FOR() then "for";
      case Absyn.ALG_PARFOR() then "parfor";
      case Absyn.ALG_WHILE() then "while";
      case Absyn.ALG_WHEN_A() then "when";
      case Absyn.ALG_NORETCALL() then AbsynUtil.crefString(alg.functionCall);
      case Absyn.ALG_RETURN() then "return";
      case Absyn.ALG_BREAK() then "break";
      else "";
    end match;
  end statementLabel;

  function addNames
    "Adds an Ident node for each name with a position, in the smallest node it's in."
    input output ProbeNode root;
    input list<tuple<Definition, Position>> declared;
    input list<tuple<Use, Position>> uses;
    input array<String> lines;
  protected
    UnorderedMap<String, ProbeNode> idents = UnorderedMap.new<ProbeNode>(stringHashDjb2, stringEq);
    String key;
    Position pos;
    Definition d;
    Use u;
    ProbeNode n;
    NodeData data;
  algorithm
    for dp in declared loop
      (d, pos) := dp;
      if pos.exact then
        UnorderedMap.add(positionKey(pos.lineStart, pos.columnStart),
          NODE("", "Ident", AbsynUtil.pathLastIdent(AbsynUtil.stringPath(d.name)), positionInfo(pos),
            NAME_DATA({}, SOME(d)), {}), idents);
      end if;
    end for;

    for up in uses loop
      (u, pos) := up;
      if pos.exact then
        key := positionKey(pos.lineStart, pos.columnStart);
        n := match UnorderedMap.get(key, idents)
          case SOME(n as NODE(data = data as NAME_DATA()))
            algorithm
              // The use that isn't a candidate comes first.
              data.uses := if u.candidate then listAppend(data.uses, {u}) else u :: data.uses;
              n.data := data;
            then
              n;
          else NODE("", "Ident", stringDelimitList(sourceLinesOf(lines, positionInfo(pos)), " "), positionInfo(pos),
            NAME_DATA({u}, NONE()), {});
        end match;
        UnorderedMap.add(key, n, idents);
      end if;
    end for;

    for i in List.sort(UnorderedMap.valueList(idents), nodeAfter) loop
      root := insertNode(root, i);
    end for;
  end addNames;

  function insertNode
    "Inserts a node into the smallest node containing it, keeping the children in source order."
    input output ProbeNode node;
    input ProbeNode leaf;
  protected
    list<ProbeNode> before = {}, rest;
    ProbeNode c;
    Boolean inserted = false;
  algorithm
    rest := node.children;
    while not listEmpty(rest) loop
      c :: rest := rest;
      if not inserted and contains(c.info, leaf.info) then
        before := insertNode(c, leaf) :: before;
        inserted := true;
      elseif not inserted and startsAfter(c.info, leaf.info) then
        before := c :: leaf :: before;
        inserted := true;
      else
        before := c :: before;
      end if;
    end while;

    if not inserted then
      before := leaf :: before;
    end if;

    node.children := listReverse(before);
  end insertNode;

  function assignIds
    input output ProbeNode node;
    input String id;
  protected
    Integer i = 0;
    list<ProbeNode> children = {};
  algorithm
    node.id := id;
    for c in node.children loop
      children := assignIds(c, id + "." + intString(i)) :: children;
      i := i + 1;
    end for;
    node.children := listReverse(children);
  end assignIds;

  function indexNodes
    input ProbeNode node;
    input Tree tree;
  algorithm
    () := match node.data
      local
        Definition d;
        Option<Definition> od;
      case NAME_DATA(declares = od)
        algorithm
          UnorderedMap.add(positionKey(node.info.lineNumberStart, node.info.columnNumberStart), node.id, tree.nameNode);
          if isSome(od) then
            SOME(d) := od;
            UnorderedMap.add(d.key, node.id, tree.declaringNode);
          end if;
        then ();
      else ();
    end match;

    for c in node.children loop
      indexNodes(c, tree);
    end for;
  end indexNodes;

  function findNode
    "Returns the node with the id and the nodes it's in, innermost first, or an empty list."
    input ProbeNode root;
    input String id;
    output list<ProbeNode> path = {};
  protected
    list<String> parts = Util.stringSplitAtChar(id, ".");
    ProbeNode n = root;
    Integer i;
  algorithm
    if listEmpty(parts) or listHead(parts) <> "0" then
      return;
    end if;

    path := {root};
    for p in listRest(parts) loop
      i := stringInt(p);
      if i < 0 or i >= listLength(n.children) then
        path := {};
        return;
      end if;
      n := listGet(n.children, i + 1);
      path := n :: path;
    end for;
  end findNode;

  function nodeJSON
    input ProbeNode node;
    output JSON obj = JSON.emptyListObject();
  algorithm
    obj := JSON.addPair("id", JSON.makeString(node.id), obj);
    obj := JSON.addPair("kind", JSON.makeString(node.kind), obj);
    obj := JSON.addPair("label", JSON.makeString(node.label), obj);
    obj := addSpan(node.info, obj);
    obj := JSON.addPair("properties", JSON.makeArray(list(JSON.makeString(p) for p in properties(node))), obj);
    obj := JSON.addPair("children", JSON.makeArray(list(nodeJSON(c) for c in node.children)), obj);
  end nodeJSON;

  // ---- the properties ------------------------------------------------------

  function properties
    input ProbeNode node;
    output list<String> props;
  protected
    list<String> specific;
  algorithm
    specific := match node.data
      case FILE_DATA() then {"errors", "topClasses", "contextModel", "omcVersion"};
      case CLASS_DATA() then {"definition", "uses", "dependsOn", "checkModel", "flatModelica",
        "simVariables", "simEquations", "translationMessages"};
      case COMPONENT_DATA() then {"definition", "uses", "useArrows", "simVariables", "flatDeclarations"};
      case EQUATION_DATA(eq = Absyn.EQ_CONNECT()) then {"simEquations", "jacobianEquations", "cCode", "connectionEquations"};
      case EQUATION_DATA() then {"simEquations", "jacobianEquations", "cCode"};
      case STATEMENT_DATA() then {"simEquations", "jacobianEquations", "cCode"};
      case NAME_DATA(declares = SOME(_)) then {"definition", "role", "uses", "useArrows"};
      case NAME_DATA() then {"definition", "role"};
      else {};
    end match;
    props := listAppend(specific, {"text", "hover"});
  end properties;

  function evaluate
    input String property;
    input list<ProbeNode> path "The node and the nodes it's in.";
    input Tree tree;
    input String contextModel;
    output Items items;
  protected
    ProbeNode node = listHead(path);
  algorithm
    items := match property
      case "text" then list(textItem(l) for l in sourceLines(tree, node.info));
      case "hover" then hover(path, tree, contextModel);
      case "errors" then fileErrors(tree);
      case "topClasses" then list(nodeItem(c.id) for c guard c.kind == "ClassDefinition" in node.children);
      case "contextModel" then {textItem(if stringEmpty(contextModel) then
        "the model each node is in" else contextModel)};
      case "omcVersion" then {textItem(Settings.getVersionNr())};
      case "definition" then definition(node, tree);
      case "uses" then uses(node, tree);
      case "useArrows" then useArrows(node, tree);
      case "role" then role(node);
      case "dependsOn" then dependsOn(node, tree);
      case "checkModel" then checkModel(node, tree);
      case "flatModelica" then flatModelica(node, tree);
      case "simVariables" then simVariables(path, tree, contextModel);
      case "simEquations" then simEquations(path, tree, contextModel, false);
      case "jacobianEquations" then simEquations(path, tree, contextModel, true);
      case "translationMessages" then translationMessages(path, tree, contextModel);
      case "flatDeclarations" then flatDeclarations(path, tree, contextModel);
      case "cCode" then cCode(path, tree, contextModel);
      case "connectionEquations" then connectionEquations(path, tree, contextModel);
      else {textItem("unknown property " + property)};
    end match;
  end evaluate;

  // ---- names ---------------------------------------------------------------

  function declaredDefinition
    "The definition a class, component declaration or declared name declares."
    input ProbeNode node;
    input Tree tree;
    output Option<Definition> def;
  algorithm
    def := match node.data
      local
        Absyn.Path path;
        String name;
      case CLASS_DATA(path = path) then UnorderedMap.get(AbsynUtil.pathString(path), tree.declared);
      case COMPONENT_DATA(name = name) then UnorderedMap.get(name, tree.declared);
      case NAME_DATA(declares = def) then def;
      else NONE();
    end match;
  end declaredDefinition;

  function describe
    input Definition d;
    input Tree tree;
    output String str;
  algorithm
    str := d.kind + " " + d.name;
    if not stringEmpty(d.detail) then
      str := str + (if d.kind == "class" then " (" + d.detail + ")" else " : " + d.detail);
    end if;
    if d.info.lineNumberStart > 0 then
      str := str + ", declared " + (if isFile(d.info.fileName, tree) then "" else "in " +
        fileBaseName(d.info.fileName) + " ") + "at line " + intString(d.info.lineNumberStart);
    end if;
  end describe;

  function definition
    input ProbeNode node;
    input Tree tree;
    output Items items = {};
  protected
    Definition d;
    Boolean first = true;
  algorithm
    if isSome(declaredDefinition(node, tree)) then
      SOME(d) := declaredDefinition(node, tree);
      items := {textItem(describe(d, tree))};
      return;
    end if;

    for u in nameUses(node) loop
      d := UnorderedMap.getOrFail(u.key, tree.definitions);
      if first and not u.candidate then
        items := textItem(describe(d, tree)) :: items;
        items := List.consOption(Util.applyOption(UnorderedMap.get(d.key, tree.declaringNode),
          function declarationItem(tree = tree)), items);
      else
        items := textItem("candidate: " + describe(d, tree)) :: items;
      end if;
      first := false;
    end for;

    items := if listEmpty(items) then {textItem("not looked up by omc")} else listReverse(items);
  end definition;

  function nameUses
    "What the name of an Ident node refers to."
    input ProbeNode node;
    output list<Use> uses;
  algorithm
    uses := match node.data
      case NAME_DATA(uses = uses) then uses;
      else {};
    end match;
  end nameUses;

  function nodeKind
    input ProbeNode node;
    output String kind = node.kind;
  end nodeKind;

  function nodeInfo
    "The span of the node with the given id."
    input Tree tree;
    input String id;
    output SourceInfo info;
  protected
    ProbeNode n;
  algorithm
    n := listHead(findNode(tree.root, id));
    info := n.info;
  end nodeInfo;

  function classPathOf
    input ProbeNode node;
    output Absyn.Path path;
  algorithm
    CLASS_DATA(path = path) := node.data;
  end classPathOf;

  function translated
    input Option<Translation> ot;
    output Boolean ok;
  algorithm
    ok := match ot
      local
        Translation t;
      case SOME(t) then t.ok;
      else false;
    end match;
  end translated;

  function declarationItem
    "A link to the class definition or component declaration a declared name is in."
    input String nameId;
    input Tree tree;
    output JSON item;
  protected
    list<ProbeNode> path = findNode(tree.root, nameId);
    ProbeNode decl;
  algorithm
    // The Ident node is in its declaration.
    if listLength(path) > 1 then
      decl := listGet(path, 2);
      item := nodeItem(decl.id);
    else
      item := nodeItem(nameId);
    end if;
  end declarationItem;

  function role
    input ProbeNode node;
    output Items items;
  protected
    Use u;
  algorithm
    items := match node.data
      case NAME_DATA(declares = SOME(_)) then {textItem("declaration")};
      case NAME_DATA(uses = u :: _) then {textItem(u.site.role)};
      else {textItem("not looked up by omc")};
    end match;
  end role;

  function usesOf
    "The uses in the file of the definition a node declares, in source order."
    input ProbeNode node;
    input Tree tree;
    output list<tuple<Use, Position>> placed = {};
  protected
    Definition d;
  algorithm
    () := match declaredDefinition(node, tree)
      case SOME(d)
        algorithm
          placed := list(p for p guard isPlacedUseOf(p, d.key) in tree.uses);
          placed := List.sort(placed, placedAfter);
        then ();
      else ();
    end match;
  end usesOf;

  function isPlacedUseOf
    input tuple<Use, Position> placed;
    input String key;
    output Boolean res;
  protected
    Use u;
    Position pos;
  algorithm
    (u, pos) := placed;
    res := u.key == key and pos.exact;
  end isPlacedUseOf;

  function uses
    input ProbeNode node;
    input Tree tree;
    output Items items;
  protected
    Use u;
    Position pos;
  algorithm
    if isNone(declaredDefinition(node, tree)) then
      items := {textItem("not a declaration")};
      return;
    end if;

    items := {};
    for p in usesOf(node, tree) loop
      (u, pos) := p;
      items := (match UnorderedMap.get(positionKey(pos.lineStart, pos.columnStart), tree.nameNode)
        local
          String id;
        case SOME(id) then nodeItem(id);
        else textItem("line " + intString(pos.lineStart) + " " + NFDefUseChains.useText(u) + " (" + u.site.role + ")");
      end match) :: items;
    end for;

    items := if listEmpty(items) then {textItem("no uses in " + fileBaseName(tree.fileName))} else listReverse(items);
  end uses;

  function useArrows
    input ProbeNode node;
    input Tree tree;
    output Items items = {};
  protected
    SourceInfo from;
    Use u;
    Position pos;
  algorithm
    from := match node.data
      local
        String id;
        Definition d;
      case NAME_DATA() then node.info;
      else
        algorithm
          SOME(d) := declaredDefinition(node, tree);
          SOME(id) := UnorderedMap.get(d.key, tree.declaringNode);
        then
          nodeInfo(tree, id);
    end match;

    for p in usesOf(node, tree) loop
      (u, pos) := p;
      items := arrowItem(from, positionInfo(pos), ARROW_COLOR, "line " + intString(pos.lineStart) + ": " +
        NFDefUseChains.useText(u) + " (" + u.site.role + ")") :: items;
    end for;
    items := listReverse(items);
  end useArrows;

  function dependsOn
    "The classes a class uses, like in getDependencyGraph."
    input ProbeNode node;
    input Tree tree;
    output Items items = {};
  protected
    String name, to;
    Definition d;
    Use u;
    list<String> names = {};
  algorithm
    name := AbsynUtil.pathString(classPathOf(node));

    for p in tree.uses loop
      (u, _) := p;
      d := UnorderedMap.getOrFail(u.key, tree.definitions);
      if u.site.scope <> name or d.kind == "iterator" or d.info.fileName == "<builtin>" or
         (d.kind == "class" and u.index < listLength(AbsynUtil.pathToStringList(
           AbsynUtil.makeNotFullyQualified(u.written)))) then
        continue;
      end if;

      to := if d.kind == "class" then d.name else ownerName(d.name);
      if not stringEmpty(to) and to <> name and not listMember(to, names) then
        names := to :: names;
      end if;
    end for;

    for n in List.sort(names, Util.strcmpBool) loop
      items := (match UnorderedMap.get(n, tree.declared)
        case SOME(d) guard UnorderedMap.contains(d.key, tree.declaringNode)
          then declarationItem(UnorderedMap.getOrFail(d.key, tree.declaringNode), tree);
        else textItem(n);
      end match) :: items;
    end for;

    items := listReverse(items);
    if listEmpty(items) then
      items := {textItem("uses no other classes")};
    end if;
  end dependsOn;

  function ownerName
    input String name;
    output String owner;
  protected
    list<String> parts = Util.stringSplitAtChar(name, ".");
  algorithm
    owner := if listLength(parts) > 1 then stringDelimitList(List.stripLast(parts), ".") else "";
  end ownerName;

  // ---- hover ---------------------------------------------------------------

  function hover
    input list<ProbeNode> path;
    input Tree tree;
    input String contextModel;
    output Items items = {};
  protected
    ProbeNode node = listHead(path);
    Definition d;
    Boolean first = true;
  algorithm
    items := match node.data
      case NAME_DATA(declares = SOME(d)) then {textItem("declares " + describe(d, tree))};

      case NAME_DATA()
        algorithm
          for u in nameUses(node) loop
            d := UnorderedMap.getOrFail(u.key, tree.definitions);
            items := textItem(if first and not u.candidate then
              NFDefUseChains.useText(u) + " -> " + describe(d, tree) + " [" + u.site.role + "]"
              else "candidate: " + describe(d, tree)) :: items;
            first := false;
          end for;
        then
          listReverse(items);

      case EQUATION_DATA(eq = Absyn.EQ_CONNECT())
        then textItem("connection equations" + contextNote(path, tree, contextModel, "") + ":") ::
          list(indent(i) for i in connectionEquations(path, tree, contextModel));

      case EQUATION_DATA() then simEquations(path, tree, contextModel, false, withOperations = false);
      case STATEMENT_DATA() then simEquations(path, tree, contextModel, false, withOperations = false);
      else {};
    end match;
  end hover;

  function indent
    input output JSON item;
  algorithm
    item := match item
      case JSON.LIST_OBJECT(values = {("text", JSON.STRING())})
        then textItem("  " + JSON.getString(JSON.get(item, "text")));
      else item;
    end match;
  end indent;

  // ---- errors and frontend results -----------------------------------------

  function isSimulationModel
    input ProbeNode node;
    output Boolean res;
  algorithm
    res := match node.data
      case CLASS_DATA(cls = Absyn.CLASS(partialPrefix = false, restriction = Absyn.R_MODEL())) then true;
      case CLASS_DATA(cls = Absyn.CLASS(partialPrefix = false, restriction = Absyn.R_BLOCK())) then true;
      case CLASS_DATA(cls = Absyn.CLASS(partialPrefix = false, restriction = Absyn.R_CLASS())) then true;
      else false;
    end match;
  end isSimulationModel;

  function classNodes
    "All class definitions in a node, outermost first."
    input ProbeNode node;
    input output list<ProbeNode> classes = {};
  algorithm
    for c in node.children loop
      if c.kind == "ClassDefinition" then
        classes := classNodes(c, c :: classes);
      end if;
    end for;
  end classNodes;

  function fileErrors
    "The names that couldn't be looked up and the messages of checkModel of the
     models in the file."
    input Tree tree;
    output Items items = {};
  protected
    Use u;
    Position pos;
    list<String> seen = {};
    String sig;
  algorithm
    for p in tree.unresolved loop
      (u, pos) := p;
      items := diagnosticItem("warning", positionInfo(pos), "unresolved name " + NFDefUseChains.useText(u)) :: items;
    end for;

    for c in listReverse(classNodes(tree.root)) loop
      if isSimulationModel(c) then
        for m in Util.tuple22(runCheckModel(c)) loop
          sig := m.severity + m.text + Error.infoStr(m.info);
          if not listMember(sig, seen) then
            seen := sig :: seen;
            items := messageItemAt(m, tree, nameInfo(c, tree)) :: items;
          end if;
        end for;
      end if;
    end for;

    items := if listEmpty(items) then {textItem("no errors")} else listReverse(items);
  end fileErrors;

  function nameInfo
    "The span of the declared name of a class or component, or of the node."
    input ProbeNode node;
    input Tree tree;
    output SourceInfo info = node.info;
  protected
    Definition d;
    String id;
  algorithm
    if isSome(declaredDefinition(node, tree)) then
      SOME(d) := declaredDefinition(node, tree);
      if UnorderedMap.contains(d.key, tree.declaringNode) then
        SOME(id) := UnorderedMap.get(d.key, tree.declaringNode);
        info := nodeInfo(tree, id);
      end if;
    end if;
  end nameInfo;

  function runCheckModel
    input ProbeNode node;
    output tuple<String, list<Message>> result;
  protected
    Absyn.Path path;
    String str = "";
    Values.Value v;
    list<Message> messages;
  algorithm
    CLASS_DATA(path = path) := node.data;
    ErrorExt.setCheckpoint(getInstanceName());
    FlagsUtil.setConfigBool(Flags.CHECK_MODEL, true);
    try
      (_, v) := CevalScriptBackend.checkModel(FCore.emptyCache(), FGraph.empty(), path, Absyn.NO_MSG());
      str := match v
        case Values.STRING() then v.string;
        else "";
      end match;
    else
    end try;
    FlagsUtil.setConfigBool(Flags.CHECK_MODEL, false);
    messages := list(toMessage(m) for m in ErrorExt.getCheckpointMessages());
    ErrorExt.delCheckpoint(getInstanceName());
    result := (str, messages);
  end runCheckModel;

  function checkModel
    input ProbeNode node;
    input Tree tree;
    output Items items;
  protected
    String str;
    list<Message> messages;
  algorithm
    if not isSimulationModel(node) then
      items := {textItem("not a model")};
      return;
    end if;

    (str, messages) := runCheckModel(node);
    items := listAppend(list(textItem(l) for l in splitLines(str)),
      list(messageItemAt(m, tree, nameInfo(node, tree)) for m in messages));
  end checkModel;

  function flatModel
    "The flat model as Base Modelica and the messages of instantiateModel."
    input Absyn.Path path;
    output tuple<String, list<Message>> result;
  protected
    String str = "";
    Values.Value v;
    Boolean base;
    list<Message> messages;
  algorithm
    ErrorExt.setCheckpoint(getInstanceName());
    base := Flags.getConfigBool(Flags.BASE_MODELICA);
    FlagsUtil.setConfigBool(Flags.BASE_MODELICA, true);
    try
      (_, v) := CevalScriptBackend.instantiateModel(FCore.emptyCache(), FGraph.empty(), path);
      str := match v
        case Values.STRING() then v.string;
        else "";
      end match;
    else
    end try;
    FlagsUtil.setConfigBool(Flags.BASE_MODELICA, base);
    messages := list(toMessage(m) for m in ErrorExt.getCheckpointMessages());
    ErrorExt.delCheckpoint(getInstanceName());
    result := (str, messages);
  end flatModel;

  function flatModelica
    input ProbeNode node;
    input Tree tree;
    output Items items;
  protected
    String str;
    list<Message> messages;
  algorithm
    if not isSimulationModel(node) then
      items := {textItem("not a model")};
      return;
    end if;

    (str, messages) := flatModel(classPathOf(node));
    items := listAppend(list(textItem(l) for l in splitLines(str)),
      list(messageItemAt(m, tree, nameInfo(node, tree)) for m in messages));
  end flatModelica;

  // ---- the context model and its translation -------------------------------

  function contextModelName
    "The model translated for a node: the given one, else the model the node is in."
    input list<ProbeNode> path;
    input String contextModel;
    output String name = contextModel;
  algorithm
    if stringEmpty(name) then
      for n in path loop
        if isSimulationModel(n) then
          name := AbsynUtil.pathString(classPathOf(n));
          return;
        end if;
      end for;
    end if;
  end contextModelName;

  function contextNote
    input list<ProbeNode> path;
    input Tree tree;
    input String contextModel;
    input String text;
    output String note;
  protected
    String m = contextModelName(path, contextModel);
  algorithm
    note := text + (if stringEmpty(m) then " (no model to translate, give a contextModel)" else " in " + m);
  end contextNote;

  function translation
    "Translates the context model of a node, or reads the translation of this
     version of the file."
    input list<ProbeNode> path;
    input Tree tree;
    input String contextModel;
    output Option<Translation> result = NONE();
  protected
    String modelName, contents, dir, stamp, cwd;
    Boolean ok = false, ops;
    list<Message> messages;
    JSON info = JSON.makeNull(), obj;
  algorithm
    modelName := contextModelName(path, contextModel);
    if stringEmpty(modelName) then
      return;
    end if;

    // The translation refers to the file by its name, so the name is part of the key.
    contents := tree.fileName + "\n" + System.readFile(tree.path);
    dir := Settings.getTempDirectoryPath() + "/omc-probe";
    _ := System.createDirectory(dir);
    dir := dir + "/" + intString(stringHashDjb2Mod(contents, HASH_MOD1)) + "-" +
      intString(stringHashDjb2Mod(contents, HASH_MOD2)) + "-" + intString(stringLength(contents));
    _ := System.createDirectory(dir);
    stamp := dir + "/" + modelName + "_probe.json";

    if System.regularFileExists(stamp) then
      obj := JSON.parseFile(stamp);
      ok := JSON.getBoolean(JSON.get(obj, "ok"));
      messages := list(messageFromJSON(m) for m in jsonList(JSON.get(obj, "messages")));
    else
      cwd := System.pwd();
      _ := System.cd(dir);
      ops := Flags.isSet(Flags.INFO_XML_OPERATIONS);
      FlagsUtil.set(Flags.INFO_XML_OPERATIONS, true);
      ErrorExt.setCheckpoint(getInstanceName());
      try
        (ok, _) := CevalScriptBackend.translateModel(FCore.emptyCache(), FGraph.empty(),
          AbsynUtil.stringPath(modelName), modelName, true, true, NONE());
      else
        ok := false;
      end try;
      messages := list(toMessage(m) for m in ErrorExt.getCheckpointMessages());
      ErrorExt.delCheckpoint(getInstanceName());
      FlagsUtil.set(Flags.INFO_XML_OPERATIONS, ops);
      _ := System.cd(cwd);

      obj := JSON.emptyListObject();
      obj := JSON.addPair("ok", JSON.makeBoolean(ok), obj);
      obj := JSON.addPair("messages", JSON.makeArray(list(messageToJSON(m) for m in messages)), obj);
      System.writeFile(stamp, JSON.toString(obj));
    end if;

    if ok and System.regularFileExists(dir + "/" + modelName + "_info.json") then
      info := JSON.parseFile(dir + "/" + modelName + "_info.json");
    else
      ok := false;
    end if;

    result := SOME(TRANSLATION(ok, modelName, dir, info, messages));
  end translation;

  function translationMessages
    input list<ProbeNode> path;
    input Tree tree;
    input String contextModel;
    output Items items;
  protected
    Translation t;
  algorithm
    items := match translation(path, tree, contextModel)
      case SOME(t) then if listEmpty(t.messages) then {textItem((if t.ok then "translated " else "could not translate ") + t.modelName)}
        else list(messageItemAt(m, tree, nameInfo(listHead(path), tree)) for m in t.messages);
      else {textItem(contextNote(path, tree, contextModel, "not translated"))};
    end match;
  end translationMessages;

  function failedTranslation
    "What a simulation property shows when there's no translation."
    input Option<Translation> t;
    input list<ProbeNode> path;
    input Tree tree;
    input String contextModel;
    output Items items;
  algorithm
    items := if isSome(t) then translationMessages(path, tree, contextModel)
      else {textItem(contextNote(path, tree, contextModel, "not translated"))};
  end failedTranslation;

  // ---- simulation variables ------------------------------------------------

  function segments
    "The parts of a variable name, without subscripts."
    input String name;
    output list<String> parts = {};
  protected
    Integer depth = 0;
    list<String> chars = {};
    String c;
  algorithm
    for i in 1:stringLength(name) loop
      c := stringGetStringChar(name, i);
      if c == "[" then
        depth := depth + 1;
      elseif c == "]" then
        depth := depth - 1;
      elseif c == "." and depth == 0 then
        parts := stringAppendList(listReverse(chars)) :: parts;
        chars := {};
      elseif depth == 0 then
        chars := c :: chars;
      end if;
    end for;
    parts := listReverse(stringAppendList(listReverse(chars)) :: parts);
  end segments;

  function instantiates
    "Whether a simulation variable is an instance of a component declaration."
    input String varName;
    input JSON var;
    input ProbeNode node;
    input Tree tree;
    output Boolean res = false;
  protected
    String cls, comp, full;
    Absyn.Path cls_path;
    list<String> seg, types;
    JSON source, info;
  algorithm
    COMPONENT_DATA(name = full, classPath = cls_path) := node.data;
    cls := AbsynUtil.pathString(cls_path);
    comp := AbsynUtil.pathLastIdent(AbsynUtil.stringPath(full));
    source := jget(var, "source");
    types := list(jstring(t) for t in jsonList(jget(source, "typeLst")));
    seg := segments(varName);

    while not listEmpty(seg) and not listEmpty(types) loop
      if listHead(seg) == comp and listHead(types) == cls then
        res := true;
        return;
      end if;
      seg := listRest(seg);
      types := listRest(types);
    end while;

    info := jget(source, "info");
    res := isFile(jstring(jget(info, "file")), tree) and
      containsPosition(node.info, jint(jget(info, "lineStart")), jint(jget(info, "colStart")));
  end instantiates;

  function simVariables
    input list<ProbeNode> path;
    input Tree tree;
    input String contextModel;
    output Items items = {};
  protected
    Option<Translation> ot = translation(path, tree, contextModel);
    Translation t;
    JSON vars, v;
    ProbeNode node = listHead(path);
  algorithm
    if not isSome(ot) or not translated(ot) then
      items := failedTranslation(ot, path, tree, contextModel);
      return;
    end if;

    SOME(t) := ot;
    vars := jget(t.info, "variables");
    for name in jkeys(vars) loop
      v := jget(vars, name);
      if node.kind == "ClassDefinition" or instantiates(name, v, node, tree) then
        items := textItem(name + " : " + jstring(jget(v, "kind")) + " " + jstring(jget(v, "type"))) :: items;
        items := listAppend(listReverse(operations(jget(v, "source"))), items);
      end if;
    end for;

    items := if listEmpty(items) then {textItem(contextNote(path, tree, contextModel, "no simulation variables"))}
             else listReverse(items);
  end simVariables;

  function operations
    "The symbolic operations of an equation or variable, without repeated ones."
    input JSON source;
    output Items items = {};
  protected
    list<String> seen = {};
    String s;
  algorithm
    for op in jsonList(jget(source, "operations")) loop
      s := "    " + jstring(jget(op, "display")) + ": " +
        stringDelimitList(list(jstring(d) for d in jsonList(jget(op, "data"))), "  =>  ");
      if not listMember(s, seen) then
        seen := s :: seen;
        items := textItem(s) :: items;
      end if;
    end for;
    items := listReverse(items);
  end operations;

  function flatDeclarations
    "The declarations in the flat model of the instances of a component."
    input list<ProbeNode> path;
    input Tree tree;
    input String contextModel;
    output Items items = {};
  protected
    String modelName = contextModelName(path, contextModel), l;
    Option<Translation> ot;
    Translation t;
    list<String> names = {};
    JSON vars;
  algorithm
    if stringEmpty(modelName) then
      items := {textItem(contextNote(path, tree, contextModel, ""))};
      return;
    end if;

    ot := translation(path, tree, contextModel);
    if isSome(ot) then
      SOME(t) := ot;
      if t.ok then
        vars := jget(t.info, "variables");
        names := list(n for n guard instantiates(n, jget(vars, n), listHead(path), tree) in jkeys(vars));
      end if;
    end if;

    for line in splitLines(Util.tuple21(flatModel(AbsynUtil.stringPath(modelName)))) loop
      l := System.trimWhitespace(line);
      if (StringUtil.startsWith(l, "parameter") or not stringContains(l, " = ")) and
         List.any(quotedNames(l), function listMemberString(lst = names)) then
        items := textItem(l) :: items;
      end if;
    end for;

    items := if listEmpty(items) then {textItem(contextNote(path, tree, contextModel, "no flat declarations"))}
             else listReverse(items);
  end flatDeclarations;

  function listMemberString
    input String s;
    input list<String> lst;
    output Boolean res = listMember(s, lst);
  end listMemberString;

  function stringContains
    input String str;
    input String sub;
    output Boolean res = System.stringFind(str, sub) >= 0;
  end stringContains;

  function quotedNames
    "The 'quoted' names in a line of Base Modelica."
    input String line;
    output list<String> names = {};
  protected
    Boolean inside = false;
    list<String> chars = {};
    String c;
  algorithm
    for i in 1:stringLength(line) loop
      c := stringGetStringChar(line, i);
      if c == "'" then
        if inside then
          names := stringAppendList(listReverse(chars)) :: names;
          chars := {};
        end if;
        inside := not inside;
      elseif inside then
        chars := c :: chars;
      end if;
    end for;
    names := listReverse(names);
  end quotedNames;

  // ---- simulation equations ------------------------------------------------

  function nestedSpans
    "The spans of the equations and statements nested in a node."
    input ProbeNode node;
    output list<SourceInfo> spans = {};
  algorithm
    for c in node.children loop
      if c.kind == "Equation" or c.kind == "Statement" then
        spans := c.info :: spans;
      end if;
    end for;
  end nestedSpans;

  function matchingEquations
    "The equations of the translation that come from a node, but not from an
     equation nested in it. All of them for a class."
    input ProbeNode node;
    input Tree tree;
    input Translation t;
    input Boolean jacobian;
    output list<JSON> equations = {};
  protected
    list<SourceInfo> nested = nestedSpans(node);
    JSON info;
    Integer line, col;
    Boolean all = node.kind == "ClassDefinition";
  algorithm
    for eq in jsonList(jget(t.info, "equations")) loop
      info := jget(jget(eq, "source"), "info");
      if not JSON.isNull(info) and isFile(jstring(jget(info, "file")), tree) then
        line := jint(jget(info, "lineStart"));
        col := jint(jget(info, "colStart"));
        if (all or (containsPosition(node.info, line, col) and
            not List.any(nested, function containsPosition(line = line, column = col)))) and
           jacobian == (jstring(jget(eq, "tag")) == "jacobian") then
          equations := eq :: equations;
        end if;
      end if;
    end for;
    equations := listReverse(equations);
  end matchingEquations;

  function equationLine
    input JSON eq;
    output String str;
  protected
    list<String> defines;
  algorithm
    defines := list(jstring(d) for d in jsonList(jget(eq, "defines")));
    str := "eq " + intString(jint(jget(eq, "eqIndex"))) + " [" + jstring(jget(eq, "section")) + ", " +
      jstring(jget(eq, "tag")) + "] " + (if listEmpty(defines) then "" else stringDelimitList(defines, ", ") + " := ") +
      stringDelimitList(list(jstring(e) for e in jsonList(jget(eq, "equation"))), "; ");
  end equationLine;

  function simEquations
    input list<ProbeNode> path;
    input Tree tree;
    input String contextModel;
    input Boolean jacobian;
    input Boolean withOperations = true;
    output Items items = {};
  protected
    Option<Translation> ot = translation(path, tree, contextModel);
    Translation t;
  algorithm
    if not isSome(ot) or not translated(ot) then
      items := failedTranslation(ot, path, tree, contextModel);
      return;
    end if;

    SOME(t) := ot;
    for eq in matchingEquations(listHead(path), tree, t, jacobian) loop
      items := textItem(equationLine(eq)) :: items;
      if withOperations then
        items := listAppend(listReverse(operations(jget(eq, "source"))), items);
      end if;
    end for;

    items := if listEmpty(items) then {textItem(contextNote(path, tree, contextModel,
      "no simulation equations from this " + (if nodeKind(listHead(path)) == "ClassDefinition" then "class" else "equation")))}
      else listReverse(items);
  end simEquations;

  function cCode
    "The generated C functions of the simulation equations of a node."
    input list<ProbeNode> path;
    input Tree tree;
    input String contextModel;
    output Items items = {};
  protected
    Option<Translation> ot = translation(path, tree, contextModel);
    Translation t;
    UnorderedMap<Integer, list<String>> functions;
  algorithm
    if not isSome(ot) or not translated(ot) then
      items := failedTranslation(ot, path, tree, contextModel);
      return;
    end if;

    SOME(t) := ot;
    functions := equationFunctions(t);
    for eq in matchingEquations(listHead(path), tree, t, false) loop
      () := match UnorderedMap.get(jint(jget(eq, "eqIndex")), functions)
        local
          list<String> lines;
        case SOME(lines)
          algorithm
            items := textItem("") :: listAppend(listReverse(list(textItem(l) for l in lines)), items);
          then ();
        else ();
      end match;
    end for;

    items := if listEmpty(items) then {textItem(contextNote(path, tree, contextModel, "no generated C equation function"))}
             else listReverse(items);
  end cCode;

  function equationFunctions
    "The C functions of the equations, with the comment before them, by equation
     index, from the C files listed in the generated makefile."
    input Translation t;
    output UnorderedMap<Integer, list<String>> functions = UnorderedMap.new<StringList>(Util.id, intEq);
  protected
    list<String> files = {}, lines, comment, body;
    String l, fn, idx;
    Integer i, n;
  algorithm
    try
      for line in splitLines(System.readFile(t.directory + "/" + t.modelName + ".makefile")) loop
        if StringUtil.startsWith(line, "MAINFILE=") or StringUtil.startsWith(line, "CFILES=") or
           (not listEmpty(files) and StringUtil.startsWith(line, t.modelName)) then
          l := Util.stringReplaceChar(Util.stringReplaceChar(Util.stringReplaceChar(line, "\\", " "), "=", " "), "\t", " ");
          files := listAppend(list(f for f guard StringUtil.endsWith(f, ".c") in Util.stringSplitAtChar(l, " ")), files);
        end if;
      end for;
    else
    end try;

    for file in files loop
      lines := {};
      try
        lines := splitLines(System.readFile(t.directory + "/" + file));
      else
      end try;

      comment := {};
      body := {};
      fn := "";
      while not listEmpty(lines) loop
        l :: lines := lines;

        if not stringEmpty(fn) then
          body := l :: body;
          if l == "}" then
            UnorderedMap.add(stringInt(fn), ("// " + file) :: listReverse(body), functions);
            fn := "";
            body := {};
          end if;
        elseif StringUtil.startsWith(l, "void ") and stringContains(l, "_eqFunction_") then
          // void <prefix>_eqFunction_<n>(DATA *data, ...
          i := System.stringFind(l, "_eqFunction_") + 13;
          n := System.stringFind(l, "(");
          idx := if n >= i then substring(l, i, n) else "";
          if not stringEmpty(idx) and Util.isIntegerString(idx) then
            fn := idx;
            body := l :: comment;
          end if;
          comment := {};
        elseif l == "/*" then
          comment := {l};
        elseif not listEmpty(comment) then
          comment := l :: comment;
        end if;
      end while;
    end for;
  end equationFunctions;

  // ---- connections ---------------------------------------------------------

  function instancePrefixes
    "The prefixes of the instances of a class in the context model, empty for the model itself."
    input String cls;
    input String modelName;
    input Option<Translation> ot;
    output list<String> prefixes = {};
  protected
    Translation t;
    list<String> seg, types;
    JSON vars;
    String p;
  algorithm
    if cls == modelName then
      prefixes := {""};
    end if;

    if isSome(ot) and translated(ot) then
      SOME(t) := ot;
      vars := jget(t.info, "variables");
      for name in jkeys(vars) loop
        types := list(jstring(ty) for ty in jsonList(jget(jget(jget(vars, name), "source"), "typeLst")));
        seg := segments(name);
        for i in 2:min(listLength(types), listLength(seg)) loop
          if listGet(types, i) == cls then
            p := stringDelimitList(List.firstN(seg, i - 1), ".") + ".";
            if not listMember(p, prefixes) then
              prefixes := p :: prefixes;
            end if;
          end if;
        end for;
      end for;
    end if;
  end instancePrefixes;

  function mentions
    input list<String> names;
    input String connectorName;
    output Boolean res = List.any(names, function isConnectorName(connectorName = connectorName));
  end mentions;

  function isConnectorName
    input String name;
    input String connectorName;
    output Boolean res = name == connectorName or StringUtil.startsWith(name, connectorName + ".");
  end isConnectorName;

  function connectionEquations
    "The equations of the flat model that relate the two connectors of a connect:
     the equalities and flow sums of their connection sets."
    input list<ProbeNode> path;
    input Tree tree;
    input String contextModel;
    output Items items = {};
  protected
    ProbeNode node = listHead(path);
    Absyn.ComponentRef c1, c2;
    String modelName = contextModelName(path, contextModel), side1, side2, cls = "", l;
    list<String> prefixes, names;
    Boolean in_equations = false;
  algorithm
    EQUATION_DATA(eq = Absyn.EQ_CONNECT(connector1 = c1, connector2 = c2)) := node.data;
    for n in path loop
      if n.kind == "ClassDefinition" then
        cls := AbsynUtil.pathString(classPathOf(n));
        break;
      end if;
    end for;

    if stringEmpty(modelName) or stringEmpty(cls) then
      items := {textItem(contextNote(path, tree, contextModel, ""))};
      return;
    end if;

    side1 := Util.stringReplaceChar(Dump.printComponentRefStr(c1), " ", "");
    side2 := Util.stringReplaceChar(Dump.printComponentRefStr(c2), " ", "");
    prefixes := instancePrefixes(cls, modelName, translation(path, tree, contextModel));

    for line in splitLines(Util.tuple21(flatModel(AbsynUtil.stringPath(modelName)))) loop
      l := System.trimWhitespace(line);
      if l == "equation" then
        in_equations := true;
      elseif in_equations and not StringUtil.startsWith(l, "end ") then
        names := quotedNames(l);
        for p in prefixes loop
          if mentions(names, p + side1) and mentions(names, p + side2) then
            items := textItem(l) :: items;
            break;
          end if;
        end for;
      end if;
    end for;

    items := if listEmpty(items) then {textItem(contextNote(path, tree, contextModel, "no connection equations found"))}
             else listReverse(items);
  end connectionEquations;

  // ---- items ---------------------------------------------------------------

  function textItem
    input String text;
    output JSON item = JSON.addPair("text", JSON.makeString(text), JSON.emptyListObject());
  end textItem;

  function nodeItem
    input String id;
    output JSON item = JSON.addPair("node", JSON.makeString(id), JSON.emptyListObject());
  end nodeItem;

  function diagnosticItem
    input String severity;
    input SourceInfo info;
    input String message;
    output JSON item = JSON.emptyListObject();
  algorithm
    item := JSON.addPair("severity", JSON.makeString(severity), item);
    item := addSpan(info, item);
    item := JSON.addPair("message", JSON.makeString(message), item);
  end diagnosticItem;

  function arrowItem
    input SourceInfo from;
    input SourceInfo to;
    input String color;
    input String message;
    output JSON item = JSON.emptyListObject();
  algorithm
    item := JSON.addPair("arrow", JSON.makeString(color), item);
    item := addSpan(from, item);
    item := JSON.addPair("to", addSpan(to, JSON.emptyListObject()), item);
    item := JSON.addPair("message", JSON.makeString(message), item);
  end arrowItem;

  function messageItem
    "A message as a diagnostic, or as text if it has no position."
    input Message m;
    output JSON item;
  algorithm
    item := if m.info.lineNumberStart > 0 then diagnosticItem(m.severity, m.info, m.text)
            else textItem(m.severity + ": " + m.text);
  end messageItem;

  function messageItemAt
    "A message as a diagnostic, at the given span if it isn't in the file."
    input Message m;
    input Tree tree;
    input SourceInfo fallback;
    output JSON item;
  algorithm
    item := if isFile(m.info.fileName, tree) and m.info.lineNumberStart > 0 then
      diagnosticItem(m.severity, m.info, m.text)
      else diagnosticItem(m.severity, fallback, (if m.info.lineNumberStart > 0 then
        "[" + fileBaseName(m.info.fileName) + ":" + intString(m.info.lineNumberStart) + "] " else "") + m.text);
  end messageItemAt;

  function toMessage
    input ErrorTypes.TotalMessage m;
    output Message msg;
  algorithm
    msg := MESSAGE(match m.msg.severity
      case ErrorTypes.WARNING() then "warning";
      case ErrorTypes.NOTIFICATION() then "info";
      else "error";
    end match, m.msg.message, m.info);
  end toMessage;

  function messageToJSON
    input Message m;
    output JSON obj = JSON.emptyListObject();
  algorithm
    obj := JSON.addPair("severity", JSON.makeString(m.severity), obj);
    obj := JSON.addPair("message", JSON.makeString(m.text), obj);
    obj := JSON.addPair("file", JSON.makeString(m.info.fileName), obj);
    obj := addSpan(m.info, obj);
  end messageToJSON;

  function messageFromJSON
    input JSON obj;
    output Message m;
  algorithm
    m := MESSAGE(jstring(jget(obj, "severity")), jstring(jget(obj, "message")),
      SOURCEINFO(jstring(jget(obj, "file")), false, jint(jget(obj, "lineStart")), jint(jget(obj, "columnStart")),
        jint(jget(obj, "lineEnd")), jint(jget(obj, "columnEnd")), 0.0));
  end messageFromJSON;

  // ---- utilities -----------------------------------------------------------

  function addSpan
    input SourceInfo info;
    input output JSON obj;
  algorithm
    obj := JSON.addPair("lineStart", JSON.makeInteger(info.lineNumberStart), obj);
    obj := JSON.addPair("columnStart", JSON.makeInteger(info.columnNumberStart), obj);
    obj := JSON.addPair("lineEnd", JSON.makeInteger(info.lineNumberEnd), obj);
    obj := JSON.addPair("columnEnd", JSON.makeInteger(info.columnNumberEnd), obj);
  end addSpan;

  function jget
    "A member of an object, NULL if it isn't one or has no such member."
    input JSON obj;
    input String key;
    output JSON value = JSON.getOrDefault(obj, key, JSON.makeNull());
  end jget;

  function jsonList
    input JSON arr;
    output list<JSON> values;
  algorithm
    values := match arr
      case JSON.ARRAY() then Vector.toList(arr.values);
      case JSON.LIST() then arr.values;
      else {};
    end match;
  end jsonList;

  function jkeys
    input JSON obj;
    output list<String> keys;
  algorithm
    keys := match obj
      case JSON.OBJECT() then JSON.getKeys(obj);
      case JSON.LIST_OBJECT() then JSON.getKeys(obj);
      else {};
    end match;
  end jkeys;

  function jstring
    input JSON value;
    output String str;
  algorithm
    str := match value
      case JSON.STRING() then value.str;
      case JSON.INTEGER() then intString(value.i);
      case JSON.NUMBER() then realString(value.r);
      case JSON.TRUE() then "true";
      case JSON.FALSE() then "false";
      else "";
    end match;
  end jstring;

  function jint
    input JSON value;
    output Integer i;
  algorithm
    i := match value
      case JSON.INTEGER() then value.i;
      else 0;
    end match;
  end jint;

  function positionKey
    input Integer line;
    input Integer column;
    output String key = intString(line) + ":" + intString(column);
  end positionKey;

  function positionInfo
    input Position pos;
    output SourceInfo info = SOURCEINFO(pos.fileName, false, pos.lineStart, pos.columnStart,
      pos.lineEnd, pos.columnEnd, 0.0);
  end positionInfo;

  function containsPosition
    input SourceInfo info;
    input Integer line;
    input Integer column;
    output Boolean res = (line > info.lineNumberStart or (line == info.lineNumberStart and column >= info.columnNumberStart)) and
                         (line < info.lineNumberEnd or (line == info.lineNumberEnd and column <= info.columnNumberEnd));
  end containsPosition;

  function contains
    "Whether a span contains another one."
    input SourceInfo span;
    input SourceInfo part;
    output Boolean res = containsPosition(span, part.lineNumberStart, part.columnNumberStart) and
                         containsPosition(span, part.lineNumberEnd, part.columnNumberEnd);
  end contains;

  function startsAfter
    "Whether a span starts after another one."
    input SourceInfo a;
    input SourceInfo b;
    output Boolean res = a.lineNumberStart > b.lineNumberStart or
      (a.lineNumberStart == b.lineNumberStart and a.columnNumberStart > b.columnNumberStart);
  end startsAfter;

  function nodeAfter
    input ProbeNode a;
    input ProbeNode b;
    output Boolean res = startsAfter(a.info, b.info);
  end nodeAfter;

  function placedAfter
    input tuple<Use, Position> a;
    input tuple<Use, Position> b;
    output Boolean res = startsAfter(positionInfo(Util.tuple22(a)), positionInfo(Util.tuple22(b)));
  end placedAfter;

  function readLines
    input String fileName;
    output array<String> lines;
  protected
    list<String> l = {};
  algorithm
    try
      l := splitLines(System.readFile(fileName));
    else
    end try;
    lines := listArray(if listEmpty(l) then {""} else l);
  end readLines;

  function splitLines
    input String str;
    output list<String> lines;
  algorithm
    lines := list(if StringUtil.endsWith(l, "\r") then (if stringLength(l) > 1 then substring(l, 1, stringLength(l) - 1) else "") else l
      for l in Util.stringSplitAtChar(str, "\n"));
    // A trailing newline doesn't start another line.
    if not listEmpty(lines) and stringEmpty(List.last(lines)) then
      lines := List.stripLast(lines);
    end if;
  end splitLines;

  function sourceLines
    "The text of a span of the file."
    input Tree tree;
    input SourceInfo info;
    output list<String> lines = sourceLinesOf(tree.lines, info);
  end sourceLines;

  function sourceLinesOf
    input array<String> fileLines;
    input SourceInfo info;
    output list<String> lines = {};
  protected
    String l;
    Integer n = arrayLength(fileLines), first, last;
  algorithm
    for i in max(1, info.lineNumberStart):min(n, info.lineNumberEnd) loop
      l := arrayGet(fileLines, i);
      first := if i == info.lineNumberStart then info.columnNumberStart else 1;
      last := if i == info.lineNumberEnd then min(stringLength(l), info.columnNumberEnd) else stringLength(l);
      lines := (if first <= last then substring(l, first, last) else "") :: lines;
    end for;
    lines := listReverse(lines);
  end sourceLinesOf;

  function isFile
    "Whether a file name is the file of the tree. The names in messages and in
     the translation aren't always written like the ones of the classes, e.g.
     in the testsuite."
    input String fileName;
    input Tree tree;
    output Boolean res = fileName == tree.fileName or
      Testsuite.friendly(fileName) == Testsuite.friendly(tree.fileName);
  end isFile;

  function fileBaseName
    input String fileName;
    output String name = List.last(Util.stringSplitAtChar(Util.stringReplaceChar(fileName, "\\", "/"), "/"));
  end fileBaseName;

  annotation(__OpenModelica_Interface="backend_main");
end ProbeTree;

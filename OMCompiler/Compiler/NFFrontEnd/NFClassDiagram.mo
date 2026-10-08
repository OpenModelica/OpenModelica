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

encapsulated package NFClassDiagram
  "UML class diagrams of Modelica classes as PlantUML, Mermaid or draw.io text, used by
   getClassDiagram.

   The diagram has the class, the classes it extends and the classes they are
   redeclared from (class extends), and the classes it uses, up to a number of
   levels: the types of its components and the classes that replaceable classes
   default to, are constrained by or are redeclared as. The names are looked up
   with the walker of NFUsedElements, which follows imports, base classes and
   redeclares without instantiating anything; the declarations, prefixes and
   modifiers are taken from the SCode."

  import Absyn;
  import SCode;

  constant Integer GENERALIZATION = 1;
  constant Integer COMPOSITION = 2;
  constant Integer DEPENDENCY = 3;
  constant Integer NESTING = 4;
  constant Integer ASSOCIATION = 5;

  uniontype Member
    "A line in a box, with the link it goes to, or an empty one."
    record MEMBER
      String text;
      String link;
    end MEMBER;
  end Member;

  uniontype Box
    "A box of the diagram, as the generators draw it: a class or an instance."
    record BOX
      String id "The name of the box in the diagram text.";
      String title;
      String stereotype;
      Boolean isAbstract "Drawn in italics.";
      String link;
      list<Member> members;
    end BOX;
  end Box;

  uniontype Edge
    record EDGE
      Integer kind;
      String source "The id of the box it's from.";
      String target "The id of the box it points to.";
      String label;
      String multiplicity;
    end EDGE;
  end Edge;

protected
  import AbsynUtil;
  import Dump;
  import NFUsedElements;
  import NFUsedElements.Definition;
  import NFUsedElements.Use;
  import Pointer;
  import SCodeDump;
  import SCodeUtil;
  import System;
  import UnorderedMap;
  import UnorderedSet;

  constant Integer INHERITED = 0 "A base class or a nested class, same level.";
  constant Integer USED = 1 "A used class, one level more.";
  constant Integer DRAWN = -1 "Only drawn if the class is in the diagram anyway.";

  uniontype Node
    record NODE
      String name "The full name of the class.";
      String id "The name of the class in the diagram text.";
      SCode.Element element;
      Integer level "Levels of uses from the class the diagram is of.";
    end NODE;
  end Node;

  uniontype Relation
    record RELATION
      Integer kind;
      String target "The full name of the class it points to.";
      String label;
      String multiplicity;
      Integer step "INHERITED, USED or DRAWN.";
      String declaredBy "The short class definition it's declared by, if any.";
    end RELATION;
  end Relation;

  uniontype Diagram
    record DIAGRAM
      UnorderedMap<String, Node> nodes "By full name.";
      Pointer<list<String>> order "The full names of the nodes, in reverse order.";
      UnorderedSet<String> ids;
      UnorderedMap<String, String> resolved "The full name a name refers to, by scope and name.";
      SCode.Program program;
      Integer depth;
      list<String> exclude;
      Boolean showModifiers;
    end DIAGRAM;
  end Diagram;

public
  function generate
    "Returns the diagram of a class, or an empty string if the class isn't found."
    input Absyn.Path className;
    input SCode.Program program "Including the builtin classes.";
    input SCode.Program annotationProgram;
    input String format "plantuml, mermaid or drawio.";
    input Integer depth "Levels of used classes.";
    input list<String> exclude "Classes and packages to leave out.";
    input Boolean showModifiers;
    output String diagram = "";
  protected
    Diagram d;
    list<String> pending, batch;
    list<Absyn.Path> paths;
    list<Definition> defs;
    list<Use> uses;
    String name;
  algorithm
    d := DIAGRAM(UnorderedMap.new<Node>(stringHashDjb2, stringEq), Pointer.create({}),
                 UnorderedSet.new<String>(stringHashDjb2, stringEq),
                 UnorderedMap.new<String>(stringHashDjb2, stringEq),
                 program, depth, exclude, showModifiers);
    name := AbsynUtil.pathString(AbsynUtil.makeNotFullyQualified(className));
    pending := addNode(name, 0, true, d, {});

    if listEmpty(pending) then
      return;
    end if;

    // The classes are walked a level at a time, since the classes a class uses
    // are only known once its names are looked up.
    while not listEmpty(pending) loop
      batch := listReverse(pending);
      pending := {};
      paths := {};

      for n in batch loop
        paths := walkedPaths(UnorderedMap.getOrFail(n, d.nodes), paths);
      end for;

      (defs, uses, _) := NFUsedElements.collectUses(listReverse(paths), program, annotationProgram);
      addResolved(defs, uses, d.resolved);

      for n in batch loop
        pending := expand(UnorderedMap.getOrFail(n, d.nodes), d, pending);
      end for;
    end while;

    diagram := render(format, name, classBoxes(d), classEdges(d));
  end generate;

protected
  function addNode
    "Adds a class to the diagram, and to the classes to walk if it's new or
     found on a lower level."
    input String name;
    input Integer level;
    input Boolean isRoot;
    input Diagram d;
    input output list<String> pending;
  protected
    SCode.Element cls;
    Node node;
  algorithm
    if not isRoot and (level > d.depth or isExcluded(name, d.exclude)) then
      return;
    end if;

    () := match UnorderedMap.get(name, d.nodes)
      case SOME(node)
        algorithm
          if level < node.level then
            node.level := level;
            UnorderedMap.add(name, node, d.nodes);

            if not listMember(name, pending) then
              pending := name :: pending;
            end if;
          end if;
        then
          ();

      else
        algorithm
          () := match findClass(name, d.program)
            case SOME(cls) guard isRoot or isDiagramClass(cls)
              algorithm
                UnorderedMap.add(name, NODE(name, newId(name, d.ids), cls, level), d.nodes);
                Pointer.update(d.order, name :: Pointer.access(d.order));
                pending := name :: pending;
              then
                ();

            else ();
          end match;
        then
          ();
    end match;
  end addNode;

  function isExcluded
    input String name;
    input list<String> exclude;
    output Boolean res = false;
  algorithm
    for e in exclude loop
      if name == e or (stringLength(name) > stringLength(e) and
         substring(name, 1, stringLength(e) + 1) == e + ".") then
        res := true;
        return;
      end if;
    end for;
  end isExcluded;

  function isDiagramClass
    "Types and enumerations are only shown as the types of components."
    input SCode.Element cls;
    output Boolean res;
  algorithm
    res := match cls
      case SCode.CLASS(classDef = SCode.ENUMERATION()) then false;
      case SCode.CLASS(restriction = SCode.R_TYPE()) then false;
      case SCode.CLASS(restriction = SCode.R_ENUMERATION()) then false;
      case SCode.CLASS(restriction = SCode.R_PREDEFINED_INTEGER()) then false;
      case SCode.CLASS(restriction = SCode.R_PREDEFINED_REAL()) then false;
      case SCode.CLASS(restriction = SCode.R_PREDEFINED_STRING()) then false;
      case SCode.CLASS(restriction = SCode.R_PREDEFINED_BOOLEAN()) then false;
      case SCode.CLASS(restriction = SCode.R_PREDEFINED_CLOCK()) then false;
      case SCode.CLASS(restriction = SCode.R_PREDEFINED_ENUMERATION()) then false;
      case SCode.CLASS() then true;
      else false;
    end match;
  end isDiagramClass;

  function newId
    "Returns a unique name for a class in the diagram text, its full name with
     the characters that aren't letters, digits or underscores replaced."
    input String name;
    input UnorderedSet<String> ids;
    output String id;
  protected
    String base;
    Integer i = 1;
  algorithm
    base := stringAppendList(list(if isIdChar(c) then c else "_" for c in stringListStringChar(name)));
    id := base;

    while UnorderedSet.contains(id, ids) loop
      i := i + 1;
      id := base + "_" + intString(i);
    end while;

    UnorderedSet.add(id, ids);
  end newId;

  function isIdChar
    input String c;
    output Boolean res;
  protected
    Integer i = stringCharInt(c);
  algorithm
    res := (i >= 48 and i <= 57) or (i >= 65 and i <= 90) or (i >= 97 and i <= 122) or i == 95;
  end isIdChar;

  function findClass
    "Returns the class declared with the given full name."
    input String name;
    input SCode.Program program;
    output Option<SCode.Element> cls = NONE();
  protected
    list<SCode.Element> elements = program;
    Absyn.Path path;
    String id;
    Boolean found;
  algorithm
    path := AbsynUtil.stringPath(name);

    while true loop
      id := AbsynUtil.pathFirstIdent(path);
      found := false;

      for e in elements loop
        if SCodeUtil.elementIsClass(e) and SCodeUtil.elementName(e) == id then
          cls := SOME(e);
          elements := SCodeUtil.getClassElements(e);
          found := true;
          break;
        end if;
      end for;

      if not found then
        cls := NONE();
        return;
      elseif not AbsynUtil.pathIsQual(path) then
        return;
      end if;

      path := AbsynUtil.pathRest(path);
    end while;
  end findClass;

  function walkedPaths
    "Adds the paths to walk to find the names a node uses: the class itself and
     the short class definitions in it, which are their own scopes."
    input Node node;
    input output list<Absyn.Path> paths;
  protected
    Absyn.Path path = AbsynUtil.stringPath(node.name);
  algorithm
    paths := path :: paths;

    for e in SCodeUtil.getClassElements(node.element) loop
      if SCodeUtil.elementIsClass(e) and SCodeUtil.isDerivedClass(e) then
        paths := AbsynUtil.suffixPath(path, SCodeUtil.elementName(e)) :: paths;
      end if;
    end for;
  end walkedPaths;

  function addResolved
    "Records the full name each name used in the walked classes refers to, by
     the class it's used in and the name as written."
    input list<Definition> defs;
    input list<Use> uses;
    input UnorderedMap<String, String> resolved;
  protected
    UnorderedMap<String, String> names = UnorderedMap.new<String>(stringHashDjb2, stringEq);
    String role;
  algorithm
    for d in defs loop
      UnorderedMap.add(d.key, d.name, names);
    end for;

    for u in uses loop
      role := u.site.role;

      // Modifier names are looked up in the class of what's modified, and the
      // name after end is the class itself. Only the whole name is kept.
      if not u.candidate and role <> "modifier" and role <> "end" and
         u.index == pathLength(u.written) then
        UnorderedMap.add(resolvedKey(u.site.scope, AbsynUtil.pathString(
          AbsynUtil.makeNotFullyQualified(u.written)), role == "classExtends" or role == "redeclare"),
          UnorderedMap.getOrFail(u.key, names), resolved);
      end if;
    end for;
  end addResolved;

  function pathLength
    input Absyn.Path path;
    output Integer len;
  algorithm
    len := match path
      case Absyn.Path.QUALIFIED() then 1 + pathLength(path.path);
      case Absyn.Path.FULLYQUALIFIED() then pathLength(path.path);
      else 1;
    end match;
  end pathLength;

  function resolvedKey
    input String scope;
    input String name;
    input Boolean classExtends "The name of a class extends or redeclared class, the class it replaces.";
    output String key = stringAppendList({scope, if classExtends then " extends " else " ", name});
  end resolvedKey;

  function resolve
    "Returns the full name a name used in a class refers to, or an empty string."
    input String scope;
    input Absyn.Path name;
    input Diagram d;
    input Boolean classExtends = false;
    output String fullName;
  algorithm
    fullName := UnorderedMap.getOrDefault(resolvedKey(scope,
      AbsynUtil.pathString(AbsynUtil.makeNotFullyQualified(name)), classExtends), d.resolved, "");
  end resolve;

  function expand
    "Adds the classes a node points to."
    input Node node;
    input Diagram d;
    input output list<String> pending;
  algorithm
    for r in relations(node, d) loop
      if r.step <> DRAWN and not stringEmpty(r.target) then
        pending := addNode(r.target, node.level + r.step, false, d, pending);
      end if;
    end for;
  end expand;

  function relations
    "Returns what a class points to, in the order it's declared."
    input Node node;
    input Diagram d;
    output list<Relation> rels = {};
  protected
    String scope = node.name, target, name;
    SCode.Element cls = node.element;
    Absyn.TypeSpec ts;
    SCode.Mod mod;
  algorithm
    rels := match cls
      case SCode.CLASS(classDef = SCode.DERIVED(typeSpec = ts, modifications = mod))
        algorithm
          target := resolve(scope, AbsynUtil.typeSpecPath(ts), d);
          rels := RELATION(GENERALIZATION, target, modString(mod, d), "", INHERITED, "") :: rels;
        then
          redeclares(mod, "", scope, d, rels);

      case SCode.CLASS(name = name, classDef = SCode.CLASS_EXTENDS(modifications = mod))
        algorithm
          target := resolve(scope, Absyn.IDENT(name), d, classExtends = true);
          rels := RELATION(GENERALIZATION, target, modString(mod, d), "", INHERITED, "") :: rels;
        then
          redeclares(mod, "", scope, d, rels);

      else rels;
    end match;

    // A redeclared class that doesn't extend the class it replaces.
    if SCodeUtil.isElementRedeclare(cls) and not SCodeUtil.isClassExtends(cls) then
      target := resolve(scope, Absyn.IDENT(SCodeUtil.elementName(cls)), d, classExtends = true);
      rels := RELATION(DEPENDENCY, target, "redeclares", "", INHERITED, "") :: rels;
    end if;

    for e in SCodeUtil.getClassElements(cls) loop
      rels := elementRelations(e, scope, d, rels);
    end for;

    rels := listReverse(rels);
  end relations;

  function elementRelations
    input SCode.Element element;
    input String scope;
    input Diagram d;
    input output list<Relation> rels;
  protected
    String target, name, full_name;
    Absyn.Path path;
    Absyn.TypeSpec ts;
    Absyn.ArrayDim dims;
    SCode.Mod mod;
    SCode.Prefixes prefixes;
  algorithm
    () := match element
      case SCode.EXTENDS(baseClassPath = path, modifications = mod)
        algorithm
          target := resolve(scope, path, d);
          rels := RELATION(GENERALIZATION, target, modString(mod, d), "", INHERITED, "") :: rels;
          rels := redeclares(mod, "extends " + AbsynUtil.pathString(path), scope, d, rels);
        then
          ();

      case SCode.COMPONENT(name = name, prefixes = prefixes, typeSpec = ts, modifications = mod,
                           attributes = SCode.ATTR(arrayDims = dims))
        algorithm
          target := resolve(scope, AbsynUtil.typeSpecPath(ts), d);
          rels := RELATION(COMPOSITION, target, name, Dump.printArraydimStr(dims), USED, "") :: rels;
          rels := constrainedBy(prefixes, name, {scope}, d, rels);
          rels := redeclares(mod, name, scope, d, rels);
        then
          ();

      case SCode.CLASS(name = name, prefixes = prefixes,
                       classDef = SCode.DERIVED(typeSpec = ts, modifications = mod))
        algorithm
          full_name := scope + "." + name;
          path := AbsynUtil.typeSpecPath(ts);
          target := resolve(full_name, path, d);

          if stringEmpty(target) then
            target := resolve(scope, path, d);
          end if;

          rels := RELATION(NESTING, full_name, "", "", DRAWN, "") :: rels;
          rels := RELATION(DEPENDENCY, target, stereotype(element) + " " + name, "", USED, full_name) :: rels;
          rels := constrainedBy(prefixes, name, {full_name, scope}, d, rels);
          rels := redeclares(mod, name, full_name, d, rels);
        then
          ();

      // Class extends and redeclared classes are part of the class, other
      // classes declared in it are only drawn if they're in the diagram anyway.
      case SCode.CLASS(name = name)
        algorithm
          rels := RELATION(NESTING, scope + "." + name, "", "",
            if SCodeUtil.isClassExtends(element) or SCodeUtil.isElementRedeclare(element)
            then INHERITED else DRAWN, "") :: rels;
        then
          ();

      else ();
    end match;
  end elementRelations;

  function constrainedBy
    input SCode.Prefixes prefixes;
    input String name;
    input list<String> scopes "The classes to look the name up in, in order.";
    input Diagram d;
    input output list<Relation> rels;
  protected
    String target = "";
    Absyn.Path path;
  algorithm
    () := match prefixes
      case SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(cc = SOME(SCode.CONSTRAINCLASS(constrainingClass = path))))
        algorithm
          for s in scopes loop
            target := resolve(s, path, d);

            if not stringEmpty(target) then
              break;
            end if;
          end for;

          rels := RELATION(DEPENDENCY, target, name + " constrainedby", "", USED, "") :: rels;
        then
          ();

      else ();
    end match;
  end constrainedBy;

  function redeclares
    "Adds the classes redeclared in a modifier, as dependencies of the class the
     modifier is in."
    input SCode.Mod mod;
    input String owner "What the modifier modifies, e.g. the component name.";
    input String scope;
    input Diagram d;
    input output list<Relation> rels;
  protected
    String target, label;
    list<SCode.SubMod> submods;
    SCode.Element e;
    Absyn.TypeSpec ts;
  algorithm
    () := match mod
      case SCode.MOD(subModLst = submods)
        algorithm
          for sm in submods loop
            rels := redeclares(sm.mod, owner, scope, d, rels);
          end for;
        then
          ();

      case SCode.REDECL(element = e)
        algorithm
          target := match e
            case SCode.CLASS(classDef = SCode.DERIVED(typeSpec = ts)) then resolve(scope, AbsynUtil.typeSpecPath(ts), d);
            case SCode.COMPONENT(typeSpec = ts) then resolve(scope, AbsynUtil.typeSpecPath(ts), d);
            else "";
          end match;

          label := elementString(e, d);
          label := if stringEmpty(owner) then label else owner + "(" + label + ")";
          rels := RELATION(DEPENDENCY, target, label, "", USED, "") :: rels;
        then
          ();

      else ();
    end match;
  end redeclares;

  function modString
    input SCode.Mod mod;
    input Diagram d;
    output String str;
  algorithm
    str := if d.showModifiers then oneLine(SCodeDump.printModStr(mod, SCodeDump.generateOptions(stripStringComments = true))) else "";
  end modString;

  function elementString
    "Returns an element as it would be declared, without comments, annotations
     and, if the modifiers aren't shown, modifiers."
    input SCode.Element element;
    input Diagram d;
    output String str;
  protected
    SCode.Element e = element;
    Absyn.TypeSpec ts;
    SCode.Attributes attr;
  algorithm
    () := match e
      case SCode.COMPONENT()
        algorithm
          e.comment := SCode.noComment;

          if not d.showModifiers then
            e.modifications := SCode.NOMOD();
          end if;
        then
          ();

      case SCode.CLASS(classDef = SCode.DERIVED(typeSpec = ts, attributes = attr))
        algorithm
          e.cmt := SCode.noComment;

          if not d.showModifiers then
            e.classDef := SCode.DERIVED(ts, SCode.NOMOD(), attr);
          end if;
        then
          ();

      else ();
    end match;

    str := oneLine(SCodeDump.unparseElementStr(e, SCodeDump.generateOptions(stripStringComments = true)));

    if stringLength(str) > 0 and substring(str, stringLength(str), stringLength(str)) == ";" then
      str := substring(str, 1, stringLength(str) - 1);
    end if;
  end elementString;

  function oneLine
    input String str;
    output String res;
  algorithm
    res := System.trim(System.stringReplace(System.stringReplace(str, "\r", ""), "\n", " "));

    while System.stringFind(res, "  ") >= 0 loop
      res := System.stringReplace(res, "  ", " ");
    end while;
  end oneLine;

  function stereotype
    "Returns how a class is declared, e.g. replaceable function or redeclare
     model extends."
    input SCode.Element cls;
    output String str;
  protected
    list<String> strl = {};
    SCode.Restriction restriction;
  algorithm
    if SCodeUtil.isElementRedeclare(cls) then
      strl := "redeclare" :: strl;
    end if;

    if SCodeUtil.isElementReplaceable(cls) then
      strl := "replaceable" :: strl;
    end if;

    () := match cls
      case SCode.CLASS(restriction = restriction)
        algorithm
          strl := SCodeDump.restrString(restriction) :: strl;

          if SCodeUtil.isClassExtends(cls) then
            strl := "extends" :: strl;
          end if;
        then
          ();

      else ();
    end match;

    str := stringDelimitList(listReverse(strl), " ");
  end stereotype;

  function members
    "Returns the lines shown in the box of a class: its components, short class
     definitions and the replaceable classes that aren't in the diagram, and the
     elements they show."
    input Node node;
    input Diagram d;
    output list<String> lines = {};
    output list<SCode.Element> elements = {};
  protected
    String vis, name;
  algorithm
    for e in SCodeUtil.getClassElements(node.element) loop
      vis := if SCodeUtil.isElementProtected(e) then "- " else "+ ";

      () := match e
        case SCode.COMPONENT()
          algorithm
            lines := (vis + elementString(e, d)) :: lines;
            elements := e :: elements;
          then
            ();

        case SCode.CLASS(classDef = SCode.DERIVED())
          algorithm
            lines := (vis + elementString(e, d)) :: lines;
            elements := e :: elements;
          then
            ();

        case SCode.CLASS(name = name)
          guard SCodeUtil.isElementReplaceable(e) and
                not UnorderedMap.contains(node.name + "." + name, d.nodes)
          algorithm
            lines := (vis + stereotype(e) + " " + name) :: lines;
            elements := e :: elements;
          then
            ();

        else ();
      end match;
    end for;

    lines := listReverse(lines);
    elements := listReverse(elements);
  end members;

  function nodes
    input Diagram d;
    output list<Node> res;
  algorithm
    res := list(UnorderedMap.getOrFail(n, d.nodes) for n in listReverse(Pointer.access(d.order)));
  end nodes;

  function edges
    "Returns the relations between the nodes, as source, target and relation."
    input Diagram d;
    output list<tuple<Node, Node, Relation>> res = {};
  protected
    UnorderedSet<String> seen = UnorderedSet.new<String>(stringHashDjb2, stringEq);
    String key;
    Node target;
  algorithm
    for n in nodes(d) loop
      for r in relations(n, d) loop
        // A short class definition in the diagram shows what it's defined as itself.
        if not stringEmpty(r.declaredBy) and UnorderedMap.contains(r.declaredBy, d.nodes) then
          continue;
        end if;

        () := match UnorderedMap.get(r.target, d.nodes)
          case SOME(target)
            algorithm
              key := stringDelimitList({intString(r.kind), n.id, target.id, r.label}, " ");

              if not UnorderedSet.contains(key, seen) then
                UnorderedSet.add(key, seen);
                res := (n, target, r) :: res;
              end if;
            then
              ();

          else ();
        end match;
      end for;
    end for;

    res := listReverse(res);
  end edges;

  function classBoxes
    "The boxes of the classes in the diagram."
    input Diagram d;
    output list<Box> boxes = {};
  protected
    list<String> lines;
    list<SCode.Element> elements;
  algorithm
    for n in nodes(d) loop
      (lines, elements) := members(n, d);
      boxes := BOX(n.id, n.name, stereotype(n.element), SCodeUtil.isPartial(n.element), classLink(n.name),
        list(MEMBER(l, memberLink(n, e)) threaded for l in lines, e in elements)) :: boxes;
    end for;

    boxes := listReverse(boxes);
  end classBoxes;

  function classEdges
    "The relations between the classes in the diagram."
    input Diagram d;
    output list<Edge> res = {};
  protected
    Node source, target;
    Relation r;
  algorithm
    for e in edges(d) loop
      (source, target, r) := e;
      res := EDGE(r.kind, source.id, target.id, r.label, r.multiplicity) :: res;
    end for;

    res := listReverse(res);
  end classEdges;

  function memberLink
    "Returns the link of a line in the box of a class: the line in the file the
     element it shows is declared on, if it's known, and for a component also
     its name, so that a viewer can select it in a graphical view instead."
    input Node node;
    input SCode.Element element;
    output String link = "";
  protected
    SourceInfo info = SCodeUtil.elementInfo(element);
  algorithm
    if info.lineNumberStart > 0 then
      link := elementLink(node.name, info.lineNumberStart,
        if SCodeUtil.isComponent(element) then SCodeUtil.elementName(element) else "");
    end if;
  end memberLink;

public
  function render
    "Returns the boxes and edges as a PlantUML, Mermaid or draw.io diagram."
    input String format "plantuml, mermaid or drawio.";
    input String name "The name of the diagram, for draw.io.";
    input list<Box> boxes;
    input list<Edge> edges;
    output String str;
  algorithm
    str := if format == "drawio" then drawio(name, boxes, edges)
           elseif format == "mermaid" then mermaid(boxes, edges) else plantuml(boxes, edges);
  end render;

  function classLink
    "modelica://<class>, the link Modelica documentation uses for a class."
    input String name;
    output String link = "modelica://" + urlEscape(name);
  end classLink;

  function elementLink
    "modelica://<class>?lineNumber=<line in the file>, with &element=<name> if
     the element is a component."
    input String className;
    input Integer lineNumber;
    input String elementName = "";
    output String link;
  algorithm
    link := classLink(className) + "?lineNumber=" + intString(lineNumber);

    if not stringEmpty(elementName) then
      link := link + "&element=" + urlEscape(elementName);
    end if;
  end elementLink;

protected
  function plantuml
    input list<Box> boxes;
    input list<Edge> edges;
    output String str;
  protected
    list<String> strl = {"hide empty members", "skinparam classAttributeIconSize 0", "@startuml"};
  algorithm
    for b in boxes loop
      strl := stringAppendList({if b.isAbstract then "abstract class \"" else "class \"",
        b.title, "\" as ", b.id, " <<", b.stereotype, ">>", if listEmpty(b.members) then "" else " {"}) :: strl;

      if not listEmpty(b.members) then
        for m in b.members loop
          strl := ("  {field} " + m.text) :: strl;
        end for;

        strl := "}" :: strl;
      end if;
    end for;

    for e in edges loop
      strl := (stringAppendList(
        if e.kind == GENERALIZATION then {e.target, " <|-- ", e.source}
        elseif e.kind == COMPOSITION then {e.source, " *-- ",
          if stringEmpty(e.multiplicity) then "" else "\"" + e.multiplicity + "\" ", e.target}
        elseif e.kind == DEPENDENCY then {e.source, " ..> ", e.target}
        elseif e.kind == ASSOCIATION then {e.source, " -- ", e.target}
        else {e.source, " +-- ", e.target}) + (if stringEmpty(e.label) then "" else " : " + e.label)) :: strl;
    end for;

    strl := "@enduml\n" :: strl;
    str := stringDelimitList(listReverse(strl), "\n");
  end plantuml;

  function mermaid
    "Returns the diagram as a Mermaid class diagram. Mermaid has no nested
     classes, so a nested class is linked to the class it's declared in."
    input list<Box> boxes;
    input list<Edge> edges;
    output String str;
  protected
    list<String> strl = {"classDiagram"};
    String label;
  algorithm
    for b in boxes loop
      strl := stringAppendList({"  class ", b.id, "[\"", b.title, "\"] {"}) :: strl;
      strl := stringAppendList({"    <<", if b.isAbstract then "partial " else "", b.stereotype, ">>"}) :: strl;

      for m in b.members loop
        strl := ("    " + mermaidEscape(m.text)) :: strl;
      end for;

      strl := "  }" :: strl;
    end for;

    for e in edges loop
      label := if e.kind == NESTING and stringEmpty(e.label) then "nested" else e.label;

      strl := (stringAppendList(
        if e.kind == GENERALIZATION then {"  ", e.target, " <|-- ", e.source}
        elseif e.kind == COMPOSITION then {"  ", e.source, " *-- ",
          if stringEmpty(e.multiplicity) then "" else "\"" + mermaidEscape(e.multiplicity) + "\" ", e.target}
        elseif e.kind == DEPENDENCY then {"  ", e.source, " ..> ", e.target}
        else {"  ", e.source, " -- ", e.target}) + (if stringEmpty(label) then "" else " : " + mermaidEscape(label))) :: strl;
    end for;

    str := stringDelimitList(listReverse("" :: strl), "\n");
  end mermaid;

  function mermaidEscape
    "Escapes what Mermaid would read as syntax: a member ending with ) would be a
     method, ~ a generic type, braces end the class and : starts a label."
    input String str;
    output String res;
  algorithm
    res := System.stringReplace(str, "#", "#35;");
    res := System.stringReplace(res, "(", "#40;");
    res := System.stringReplace(res, ")", "#41;");
    res := System.stringReplace(res, "{", "#123;");
    res := System.stringReplace(res, "}", "#125;");
    res := System.stringReplace(res, "<", "#60;");
    res := System.stringReplace(res, ">", "#62;");
    res := System.stringReplace(res, "~", "#126;");
    res := System.stringReplace(res, ":", "#58;");
  end mermaidEscape;

  function drawio
    "Returns the diagram as a draw.io (diagrams.net) file. The boxes are laid
     out in rows, base classes above the classes that extend them; draw.io can
     arrange them in other ways (Arrange > Layout). Every box links to its link,
     e.g. modelica://<class>, and every line in it to its own, e.g. the line of
     the element it shows, modelica://<class>?lineNumber=<line in the file>,
     with &element=<name> for a component."
    input String name;
    input list<Box> boxes;
    input list<Edge> edges;
    output String str;
  protected
    UnorderedMap<String, Integer> ranks = UnorderedMap.new<Integer>(stringHashDjb2, stringEq);
    Integer rank, max_rank = 0, x, y = 20, w, h, row_h, i = 0;
    list<String> strl, lines, links;
    String label;
    Boolean changed = true;
  algorithm
    // The rank of a box is one more than the rank of its lowest base class.
    for b in boxes loop
      UnorderedMap.add(b.id, 0, ranks);
    end for;

    while changed and i < listLength(boxes) loop
      changed := false;
      i := i + 1;

      for e in edges loop
        if e.kind == GENERALIZATION then
          rank := UnorderedMap.getOrFail(e.target, ranks) + 1;

          if rank > UnorderedMap.getOrFail(e.source, ranks) then
            UnorderedMap.add(e.source, rank, ranks);
            max_rank := max(max_rank, rank);
            changed := true;
          end if;
        end if;
      end for;
    end while;

    strl := {"      <mxCell id=\"1\" parent=\"0\"/>", "      <mxCell id=\"0\"/>",
             "    <root>", "   <mxGraphModel>",
             "  <diagram id=\"" + xmlEscape(name) + "\" name=\"" + xmlEscape(name) + "\">",
             "<mxfile host=\"OpenModelica\">"};

    for rk in 0:max_rank loop
      x := 20;
      row_h := 0;

      for b in boxes loop
        if UnorderedMap.getOrFail(b.id, ranks) == rk then
          lines := list(m.text for m in b.members);
          w := 20 + 7 * max(stringLength(l) for l in b.stereotype :: b.title :: lines);
          h := 44 + (if listEmpty(lines) then 0 else 8 + 16 * listLength(lines));
          label := "<p style=\"margin:4px;text-align:center\"><i>&#171;" + htmlEscape(b.stereotype) +
            "&#187;</i><br/>" + (if b.isAbstract then "<b><i>" + htmlEscape(b.title) + "</i></b>"
            else "<b>" + htmlEscape(b.title) + "</b>") + "</p>";

          if not listEmpty(lines) then
            links := list(memberHtml(m) for m in b.members);
            label := label + "<hr size=\"1\"/><p style=\"margin:0 4px\">" +
              stringDelimitList(links, "<br/>") + "</p>";
          end if;

          strl := stringAppendList({"      <UserObject id=\"", b.id, "\" label=\"", xmlEscape(label),
            "\" link=\"", xmlEscape(b.link), "\">",
            "<mxCell style=\"verticalAlign=top;align=left;overflow=fill;html=1;whiteSpace=nowrap;\" vertex=\"1\" parent=\"1\">",
            "<mxGeometry x=\"", intString(x), "\" y=\"", intString(y), "\" width=\"", intString(w),
            "\" height=\"", intString(h), "\" as=\"geometry\"/></mxCell></UserObject>"}) :: strl;
          x := x + w + 40;
          row_h := max(row_h, h);
        end if;
      end for;

      y := y + row_h + 80;
    end for;

    i := 0;
    for e in edges loop
      i := i + 1;
      label := if stringEmpty(e.multiplicity) then e.label else e.label + " " + e.multiplicity;

      strl := stringAppendList({"      <mxCell id=\"e", intString(i), "\" value=\"", xmlEscape(htmlEscape(label)),
        "\" style=\"", edgeStyle(e.kind), "html=1;\" edge=\"1\" parent=\"1\" source=\"", e.source,
        "\" target=\"", e.target, "\"><mxGeometry relative=\"1\" as=\"geometry\"/></mxCell>"}) :: strl;
    end for;

    strl := "</mxfile>\n" :: "  </diagram>" :: "   </mxGraphModel>" :: "    </root>" :: strl;
    str := stringDelimitList(listReverse(strl), "\n");
  end drawio;

  function memberHtml
    "Returns a line in a box as HTML, a link if it has one."
    input Member member;
    output String html = htmlEscape(member.text);
  algorithm
    if not stringEmpty(member.link) then
      html := "<a href=\"" + htmlEscape(member.link) + "\" style=\"color:inherit;text-decoration:none\">" + html + "</a>";
    end if;
  end memberHtml;

  function urlEscape
    "Escapes what can't be in a URL path; only quoted names have these."
    input String str;
    output String res;
  algorithm
    res := System.stringReplace(str, "%", "%25");
    res := System.stringReplace(res, " ", "%20");
    res := System.stringReplace(res, "\"", "%22");
    res := System.stringReplace(res, "#", "%23");
    res := System.stringReplace(res, "'", "%27");
    res := System.stringReplace(res, "<", "%3C");
    res := System.stringReplace(res, ">", "%3E");
    res := System.stringReplace(res, "?", "%3F");
  end urlEscape;

  function edgeStyle
    input Integer kind;
    output String style;
  algorithm
    style := if kind == GENERALIZATION then "endArrow=block;endFill=0;endSize=12;"
      elseif kind == COMPOSITION then "startArrow=diamondThin;startFill=1;startSize=14;endArrow=none;"
      elseif kind == DEPENDENCY then "dashed=1;endArrow=open;endSize=12;"
      elseif kind == ASSOCIATION then "endArrow=none;"
      else "startArrow=circlePlus;startFill=0;endArrow=none;";
  end edgeStyle;

  function htmlEscape
    input String str;
    output String res;
  algorithm
    res := System.stringReplace(str, "&", "&amp;");
    res := System.stringReplace(res, "<", "&lt;");
    res := System.stringReplace(res, ">", "&gt;");
  end htmlEscape;

  function xmlEscape
    input String str;
    output String res;
  algorithm
    res := htmlEscape(str);
    res := System.stringReplace(res, "\"", "&quot;");
  end xmlEscape;

  annotation(__OpenModelica_Interface="nf_frontend");
end NFClassDiagram;

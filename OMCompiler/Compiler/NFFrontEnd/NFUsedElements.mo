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

encapsulated package NFUsedElements
  "Finds the classes and package constants a class uses by looking up the
   names in it in the new frontend's scopes, without instantiating anything.
   Used by saveTotalModel.

   Every class found is walked in turn: the types, base classes, modifiers,
   bindings, dimensions, equations, algorithms and derivative/inverse
   annotations of its own elements, and the functions used without being
   named (operators, equalityConstraint, external object constructors).
   Classes are only expanded, and an expanded class can only look up its
   local classes and imports, so inherited elements and components are found
   by searching the definitions of the class and its base classes.

   Without instantiation a name like Medium.f only finds the default of a
   replaceable package, so the replaceable, redeclared and class extends
   elements of every walked class that have a name looked up somewhere are
   walked too. That finds what a redeclare puts in place of it and what it
   replaces, and keeps more than is used rather than less.

   collectUses walks the same way with a recorder, which records for every
   name where it's used and the definition it's found to be, the def-use chains
   used by getDefUseChains. Everything in the given classes is walked, and the
   classes found are only looked into to find the names, not walked."

  import Absyn;
  import SCode;
  import NFInstNode.InstNode;
  import UnorderedSet;

protected
  import AbsynUtil;
  import Class = NFClass;
  import NFClassTree.ClassTree;
  import Inst = NFInst;
  import InstContext = NFInstContext;
  import List;
  import Lookup = NFLookup;
  import Pointer;
  import SCodeUtil;
  import Type = NFType;
  import ComplexType = NFComplexType;
  import Dump;
  import SCodeDump;
  import UnorderedMap;
  import StringUtil;
  import Util;

  constant InstContext.Type CONTEXT =
    intBitOr(NFInstContext.RELAXED, NFInstContext.FAST_LOOKUP);

  type PathList = list<Absyn.Path>;
  type NodeList = list<InstNode>;
  type PendingList = list<Pending>;

  uniontype Walk
    record WALK
      UnorderedSet<String> used "Keys of the used elements, see elementKey.";
      UnorderedSet<String> walked "Keys of the walked classes and constants.";
      UnorderedSet<String> names "Names that were looked up.";
      Pointer<list<InstNode>> queue "Classes found but not walked yet.";
      Pointer<list<InstNode>> classes "The walked classes.";
      UnorderedMap<String, list<Absyn.Path>> rests
        "The rest of the names looked up through a replaceable class, by its key.";
      UnorderedMap<String, list<InstNode>> replacements
        "The classes a replaceable class is redeclared as, by its key.";
      Option<Recorder> recorder "Records the uses of the names, see collectUses.";
    end WALK;
  end Walk;

  uniontype Found
    "The last element found by findElement or lookupFirstIdent."
    record NOT_FOUND end NOT_FOUND;

    record FOUND_NODE
      InstNode node;
    end FOUND_NODE;

    record FOUND_ELEMENT
      SCode.Element element;
      InstNode scope "The class the element is declared in.";
    end FOUND_ELEMENT;
  end Found;

  uniontype Pending
    "A name looked up through a replaceable class, to look up the rest of it in
     the classes the replaceable class is redeclared as."
    record PENDING
      Absyn.Path rest;
      Absyn.Path written;
      Integer index "The part of the written name the rest begins with.";
      Site site;
    end PENDING;
  end Pending;

  uniontype Recorder
    record RECORDER
      UnorderedMap<String, Definition> definitions "By key.";
      Pointer<list<Use>> uses "In reverse order.";
      Pointer<list<Use>> unresolved "Names that weren't found, in reverse order.";
      Pointer<Option<Site>> site "Where the names looked up are used, none while not recording.";
      Pointer<String> scope "The name of the class being walked.";
      Pointer<Boolean> candidate "Looking up the rest of a name in a redeclared class.";
      Pointer<Found> found;
      Pointer<list<tuple<String, String>>> iterators "The names and keys of the iterators in scope.";
      UnorderedMap<String, list<Pending>> pending "By the key of the replaceable class.";
      UnorderedSet<String> pendingKeys;
    end RECORDER;
  end Recorder;

public
  function collect
    "Returns the keys (see elementKey) of the elements the given classes use,
     including the classes themselves and everything declared in them."
    input list<Absyn.Path> classPaths "A class and the classes declared in it.";
    input SCode.Program program;
    input SCode.Program annotationProgram;
    output UnorderedSet<String> used;
  protected
    InstNode top, cls;
    Walk walk;
    Integer names_count;
  algorithm
    Inst.resetGlobalFlags();
    top := Inst.makeTopNode(program, annotationProgram);
    walk := WALK(UnorderedSet.new<String>(stringHashDjb2, stringEq),
                 UnorderedSet.new<String>(stringHashDjb2, stringEq),
                 UnorderedSet.new<String>(stringHashDjb2, stringEq),
                 Pointer.create({}), Pointer.create({}),
                 UnorderedMap.new<PathList>(stringHashDjb2, stringEq),
                 UnorderedMap.new<NodeList>(stringHashDjb2, stringEq), NONE());

    // The saved classes are kept whole, so also their package constants are walked.
    for path in classPaths loop
      try
        cls := walkPath(AbsynUtil.makeFullyQualified(path), top, walk);

        if InstNode.isClass(cls) then
          walkClass(cls, walk, allConstants = true);
        end if;
      else
      end try;
    end for;

    while true loop
      walkQueue(walk);
      names_count := UnorderedSet.size(walk.names);

      for c in Pointer.access(walk.classes) loop
        try
          walkNamedElements(c, walk);
        else
        end try;
      end for;

      if listEmpty(Pointer.access(walk.queue)) and UnorderedSet.size(walk.names) == names_count then
        break;
      end if;
    end while;

    used := walk.used;
    Inst.clearCaches();
  end collect;

  uniontype Site
    "Where a name is used."
    record SITE
      SourceInfo info "Of the element, equation, statement or class it's used in.";
      String role "What it's used as, e.g. type, extends, modifier, equation.";
      String scope "The class it's used in.";
    end SITE;
  end Site;

  uniontype Definition
    record DEFINITION
      String key "See elementKey.";
      String name "The full name, e.g. P.Base.x.";
      String kind "class, component or iterator.";
      String detail "The restriction of a class, the type of a component.";
      SourceInfo info;
      Boolean declared "Declared in one of the walked classes.";
    end DEFINITION;
  end Definition;

  uniontype Use
    record USE
      String key "The key of the definition, empty if the name wasn't found.";
      Absyn.Path written "The name as written, without subscripts.";
      Integer index "The part of the written name that refers to the definition.";
      Site site;
      Boolean candidate "Found in a class a replaceable class is redeclared as.";
    end USE;
  end Use;

  function collectUses
    "Walks every element, equation and algorithm of the given classes and records
     for each name in them the definition it refers to. Returns the definitions,
     both the ones used and the ones declared in the classes, and the uses and the
     names that weren't found, in the order they were found."
    input list<Absyn.Path> classPaths "The classes to walk.";
    input SCode.Program program;
    input SCode.Program annotationProgram;
    output list<Definition> definitions;
    output list<Use> uses;
    output list<Use> unresolved;
  protected
    InstNode top, cls;
    Walk walk;
    Recorder rec;
  algorithm
    Inst.resetGlobalFlags();
    top := Inst.makeTopNode(program, annotationProgram);
    rec := RECORDER(UnorderedMap.new<Definition>(stringHashDjb2, stringEq),
                    Pointer.create({}), Pointer.create({}), Pointer.create(NONE()),
                    Pointer.create(""), Pointer.create(false), Pointer.create(NOT_FOUND()),
                    Pointer.create({}),
                    UnorderedMap.new<PendingList>(stringHashDjb2, stringEq),
                    UnorderedSet.new<String>(stringHashDjb2, stringEq));
    walk := WALK(UnorderedSet.new<String>(stringHashDjb2, stringEq),
                 UnorderedSet.new<String>(stringHashDjb2, stringEq),
                 UnorderedSet.new<String>(stringHashDjb2, stringEq),
                 Pointer.create({}), Pointer.create({}),
                 UnorderedMap.new<PathList>(stringHashDjb2, stringEq),
                 UnorderedMap.new<NodeList>(stringHashDjb2, stringEq), SOME(rec));

    for path in classPaths loop
      try
        cls := declaredClass(path, top, walk);

        if InstNode.isClass(cls) then
          Pointer.update(rec.scope, AbsynUtil.pathString(path));
          walkClass(cls, walk, allConstants = true);
        end if;
      else
      end try;

      Pointer.update(rec.site, NONE());
      Pointer.update(rec.iterators, {});
    end for;

    definitions := UnorderedMap.valueList(rec.definitions);
    uses := listReverse(Pointer.access(rec.uses));
    unresolved := listReverse(Pointer.access(rec.unresolved));
    Inst.clearCaches();
  end collectUses;

  function elementKey
    "Identifies an element definition by its name and source position. Nodes are
     copied when inherited, so the definition is what the copies share."
    input SCode.Element definition;
    output String key;
  protected
    SourceInfo info = SCodeUtil.elementInfo(definition);
  algorithm
    key := stringAppendList({SCodeUtil.elementName(definition), "@", info.fileName,
      ":", intString(info.lineNumberStart), ":", intString(info.columnNumberStart),
      "-", intString(info.lineNumberEnd), ":", intString(info.columnNumberEnd)});
  end elementKey;

protected
  function declaredClass
    "Returns the class declared with the given name. A lookup of the name finds
     the class it replaces for a class extends or a redeclared class."
    input Absyn.Path path;
    input InstNode top;
    input Walk walk;
    output InstNode cls;
  protected
    InstNode parent, n;
    String name;
  algorithm
    cls := walkPath(AbsynUtil.makeFullyQualified(path), top, walk);

    if not AbsynUtil.pathIsQual(path) then
      return;
    end if;

    parent := walkPath(AbsynUtil.makeFullyQualified(AbsynUtil.stripLast(path)), top, walk);

    if not InstNode.isClass(parent) then
      return;
    end if;

    name := AbsynUtil.pathLastIdent(path);

    // A class extends or redeclared class, or a class the lookup doesn't find,
    // e.g. the constructor of an external object.
    for e in SCodeUtil.getClassElements(InstNode.definition(parent)) loop
      if SCodeUtil.elementIsClass(e) and SCodeUtil.elementName(e) == name and
         (isReplacingClass(e) or not InstNode.isClass(cls)) then
        if not (InstNode.isClass(cls) and elementKey(InstNode.definition(cls)) == elementKey(e)) then
          parent := expandNode(parent);
          n := localClass(e, parent);
          cls := if InstNode.isClass(n) then n else InstNode.newClass(e, parent);
        end if;

        break;
      end if;
    end for;
  end declaredClass;

  function isRecording
    input Walk walk;
    output Boolean res = isSome(walk.recorder);
  end isRecording;

  function setFound
    input Found found;
    input Walk walk;
  algorithm
    () := match walk.recorder
      local
        Recorder rec;
      case SOME(rec) algorithm Pointer.update(rec.found, found); then ();
      else ();
    end match;
  end setFound;

  function takeFound
    "Returns the last element found and forgets it."
    input Walk walk;
    output Found found = NOT_FOUND();
  algorithm
    () := match walk.recorder
      local
        Recorder rec;
      case SOME(rec)
        algorithm
          found := Pointer.access(rec.found);
          Pointer.update(rec.found, NOT_FOUND());
        then
          ();
      else ();
    end match;
  end takeFound;

  function enterSite
    "Sets where the names looked up next are used, returns the previous site."
    input SourceInfo info;
    input String role;
    input Walk walk;
    output Option<Site> old = NONE();
  algorithm
    () := match walk.recorder
      local
        Recorder rec;
      case SOME(rec)
        algorithm
          old := Pointer.access(rec.site);
          Pointer.update(rec.site, SOME(SITE(info, role, Pointer.access(rec.scope))));
        then
          ();
      else ();
    end match;
  end enterSite;

  function setRole
    "Changes what the names looked up next are used as, returns the previous site."
    input String role;
    input Walk walk;
    output Option<Site> old = NONE();
  algorithm
    () := match walk.recorder
      local
        Recorder rec;
        Site site;
      case SOME(rec)
        algorithm
          old := Pointer.access(rec.site);

          if isSome(old) then
            SOME(site) := old;
            site.role := role;
            Pointer.update(rec.site, SOME(site));
          end if;
        then
          ();
      else ();
    end match;
  end setRole;

  function leaveSite
    input Option<Site> old;
    input Walk walk;
  algorithm
    () := match walk.recorder
      local
        Recorder rec;
      case SOME(rec) algorithm Pointer.update(rec.site, old); then ();
      else ();
    end match;
  end leaveSite;

  function suspendRecording
    "Stops recording for lookups of names that aren't written at the current site."
    input Walk walk;
    output Option<Site> old = leaveSiteNone(walk);
  end suspendRecording;

  function leaveSiteNone
    input Walk walk;
    output Option<Site> old = NONE();
  algorithm
    () := match walk.recorder
      local
        Recorder rec;
      case SOME(rec)
        algorithm
          old := Pointer.access(rec.site);
          Pointer.update(rec.site, NONE());
        then
          ();
      else ();
    end match;
  end leaveSiteNone;

  function makeDefinition
    input SCode.Element element;
    input String name;
    input Boolean declared;
    output Definition def;
  protected
    String kind, detail;
  algorithm
    (kind, detail) := match element
      case SCode.CLASS() then ("class", SCodeDump.restrString(element.restriction));
      case SCode.COMPONENT() then ("component", Dump.unparseTypeSpec(element.typeSpec));
      else ("element", "");
    end match;

    def := DEFINITION(elementKey(element), name, kind, detail,
      SCodeUtil.elementInfo(element), declared);
  end makeDefinition;

  function addDefinition
    "Adds a definition, a declared one replaces one added when it was used."
    input Definition def;
    input Recorder rec;
  protected
    Option<Definition> odef;
    Definition old;
  algorithm
    odef := UnorderedMap.get(def.key, rec.definitions);

    if isSome(odef) then
      SOME(old) := odef;

      if old.declared or not def.declared then
        return;
      end if;
    end if;

    UnorderedMap.add(def.key, def, rec.definitions);
  end addDefinition;

  function declare
    "Adds a definition declared in one of the walked classes."
    input SCode.Element element;
    input String name;
    input Walk walk;
  algorithm
    () := match walk.recorder
      local
        Recorder rec;
      case SOME(rec)
        algorithm
          try
            addDefinition(makeDefinition(element, name, true), rec);
          else
          end try;
        then
          ();
      else ();
    end match;
  end declare;

  function foundDefinition
    input Found found;
    output Option<Definition> def = NONE();
  protected
    InstNode n;
    SCode.Element e;
    String name;
  algorithm
    try
      () := match found
        // An enumeration literal has no definition of its own, it's declared by its type.
        case FOUND_NODE(node = n as InstNode.COMPONENT_NODE(definition = NONE()))
          guard not InstNode.isBuiltin(InstNode.parent(n))
          algorithm
            e := InstNode.definition(InstNode.parent(n));
            name := AbsynUtil.pathString(InstNode.scopePath(n, ignoreBaseClass = true));
            def := SOME(DEFINITION(InstNode.name(n) + "@" + elementKey(e), name,
              "enumerationLiteral", "", SCodeUtil.elementInfo(e), false));
          then
            ();

        case FOUND_NODE(node = n)
          guard (InstNode.isClass(n) or InstNode.isComponent(n)) and not InstNode.isBuiltin(n)
          algorithm
            e := InstNode.definition(n);
            name := AbsynUtil.pathString(InstNode.scopePath(n, ignoreBaseClass = true));
            def := SOME(makeDefinition(e, name, false));
          then
            ();

        case FOUND_ELEMENT(element = e, scope = n)
          algorithm
            name := AbsynUtil.pathString(InstNode.scopePath(n, ignoreBaseClass = true)) +
              "." + SCodeUtil.elementName(e);
            def := SOME(makeDefinition(e, name, false));
          then
            ();

        else ();
      end match;
    else
      def := NONE();
    end try;

    // The builtin classes and functions of the compiler, e.g. Connections.branch.
    () := match def
      local
        Definition d;
      case SOME(d) guard StringUtil.endsWith(d.info.fileName, "ModelicaBuiltin.mo")
        algorithm
          def := NONE();
        then
          ();
      else ();
    end match;
  end foundDefinition;

  function recordFound
    "Records that the given part of a name used at the current site refers to
     what was found."
    input Found found;
    input Absyn.Path written;
    input Integer index;
    input Walk walk;
  algorithm
    () := match walk.recorder
      local
        Recorder rec;
        Site site;
        Definition def;
      case SOME(rec)
        guard isSome(Pointer.access(rec.site))
        algorithm
          SOME(site) := Pointer.access(rec.site);

          () := match foundDefinition(found)
            case SOME(def)
              algorithm
                addDefinition(def, rec);
                Pointer.update(rec.uses, USE(def.key, written, index, site,
                  Pointer.access(rec.candidate)) :: Pointer.access(rec.uses));
              then
                ();

            // A builtin, or not found.
            else
              algorithm
                if isNotFound(found) and not Pointer.access(rec.candidate) then
                  Pointer.update(rec.unresolved, USE("", written, index, site, false) ::
                    Pointer.access(rec.unresolved));
                end if;
              then
                ();
          end match;
        then
          ();

      else ();
    end match;
  end recordFound;

  function recordIterator
    "Records the use of an iterator in scope, returns false if there's none with
     that name."
    input String name;
    input Absyn.Path written;
    input Walk walk;
    output Boolean isIterator = false;
  algorithm
    () := match walk.recorder
      local
        Recorder rec;
        Site site;
      case SOME(rec)
        guard isSome(Pointer.access(rec.site))
        algorithm
          SOME(site) := Pointer.access(rec.site);

          for it in Pointer.access(rec.iterators) loop
            if Util.tuple21(it) == name then
              Pointer.update(rec.uses, USE(Util.tuple22(it), written, 1, site,
                Pointer.access(rec.candidate)) :: Pointer.access(rec.uses));
              isIterator := true;
              return;
            end if;
          end for;
        then
          ();
      else ();
    end match;
  end recordIterator;

  function pushIterator
    "Declares an iterator at the current site."
    input String name;
    input Walk walk;
  algorithm
    () := match walk.recorder
      local
        Recorder rec;
        Site site;
        String key;
      case SOME(rec)
        guard isSome(Pointer.access(rec.site))
        algorithm
          SOME(site) := Pointer.access(rec.site);
          key := stringAppendList({name, "@", site.info.fileName, ":",
            intString(site.info.lineNumberStart), ":", intString(site.info.columnNumberStart),
            "-", intString(site.info.lineNumberEnd), ":", intString(site.info.columnNumberEnd)});
          addDefinition(DEFINITION(key, site.scope + "." + name, "iterator", "", site.info, true), rec);
          Pointer.update(rec.iterators, (name, key) :: Pointer.access(rec.iterators));
        then
          ();
      else ();
    end match;
  end pushIterator;

  function popIterator
    input Walk walk;
  algorithm
    () := match walk.recorder
      local
        Recorder rec;
      case SOME(rec)
        algorithm
          if not listEmpty(Pointer.access(rec.iterators)) then
            Pointer.update(rec.iterators, listRest(Pointer.access(rec.iterators)));
          end if;
        then
          ();
      else ();
    end match;
  end popIterator;

  function isNotFound
    input Found found;
    output Boolean res;
  algorithm
    res := match found
      case NOT_FOUND() then true;
      else false;
    end match;
  end isNotFound;

  function foundLocalName
    "Looks up a name among the elements of a class, also inherited ones, and
     records it. Returns the class found, or with needType the class of the
     component found, otherwise an empty node."
    input String name;
    input InstNode cls;
    input Walk walk;
    input Boolean needType = false;
    output InstNode node;
  algorithm
    (node, _) := findElement(name, cls, walk, needType);
  end foundLocalName;

  function findElement
    "Finds an element declared in a class or in one of its base classes and
     records it. Returns the class found, or with needType the class of the
     component found, otherwise an empty node."
    input String name;
    input InstNode cls;
    input Walk walk;
    input Boolean needType = false;
    output InstNode node = InstNode.EMPTY_NODE();
    output Boolean found = false;
  algorithm
    if InstNode.isClass(cls) then
      try
        (node, found) := findElement2(name, cls, walk, needType);
      else
        node := InstNode.EMPTY_NODE();
        found := false;
      end try;
    end if;
  end findElement;

  function findElement2
    input String name;
    input InstNode cls;
    input Walk walk;
    input Boolean needType;
    output InstNode node = InstNode.EMPTY_NODE();
    output Boolean found = false;
  protected
    InstNode c = expandNode(cls), n = InstNode.EMPTY_NODE();
    SCode.Element def = InstNode.definition(c);
  algorithm
    // The local classes and imports can be looked up in an expanded class, the
    // inherited elements and the components only once it's instantiated.
    try
      n := Lookup.lookupLocalSimpleName(name, c);
      found := true;
    else
    end try;

    // The name refers to a class extends, not to the class it replaces that
    // the lookup finds.
    if isRecording(walk) then
      node := redeclaredClass(name, c);

      if InstNode.isClass(node) then
        n := node;
        found := true;
      end if;

      node := InstNode.EMPTY_NODE();
    end if;

    if found then
      UnorderedSet.add(name, walk.names);
      foundNode(n, walk);
      setFound(FOUND_NODE(n), walk);

      if InstNode.isClass(n) then
        node := n;
      end if;

      return;
    end if;

    for e in SCodeUtil.getClassElements(def) loop
      if SCodeUtil.isComponent(e) and SCodeUtil.elementName(e) == name then
        foundComponent(e, c, walk);

        // Continue in the class of the component, e.g. for world.gravityAcceleration.
        if needType then
          node := componentClass(e, c, walk);
        end if;

        setFound(FOUND_ELEMENT(e, c), walk);

        found := true;
        return;
      end if;
    end for;

    for b in baseClasses(c) loop
      (node, found) := findElement2(name, b, walk, needType);

      if found then
        return;
      end if;
    end for;
  end findElement2;

  function foundComponent
    "Records a component declared in the given class, and walks it if it's
     declared in a package."
    input SCode.Element component;
    input InstNode cls;
    input Walk walk;
  protected
    String key = elementKey(component);
  algorithm
    foundNode(cls, walk);
    UnorderedSet.add(SCodeUtil.elementName(component), walk.names);
    UnorderedSet.add(key, walk.used);

    if not isRecording(walk) and SCodeUtil.isPackage(InstNode.definition(cls)) and
       not UnorderedSet.contains(key, walk.walked) then
      UnorderedSet.add(key, walk.walked);
      walkElement(component, cls, walk);
    end if;
  end foundComponent;

  function localClass
    "Returns the node of a class declared in the given class."
    input SCode.Element element;
    input InstNode cls;
    output InstNode node = InstNode.EMPTY_NODE();
  protected
    String key = elementKey(element);
    array<InstNode> classes;
    NFInstNode.ScopeRef structor_ref;
  algorithm
    try
      classes := ClassTree.getClasses(Class.classTree(InstNode.getClass(cls)));
    else
      // An instantiated class, where any element can be looked up.
      try
        node := Lookup.lookupLocalSimpleName(SCodeUtil.elementName(element), cls);
      else
      end try;

      classes := listArray({});
    end try;

    for n in classes loop
      if InstNode.isClass(n) and elementKey(InstNode.definition(n)) == key then
        node := n;
        break;
      end if;
    end for;

    // The constructor and destructor of an external object are only kept in its type.
    if InstNode.isEmpty(node) then
      try
        Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT(constructor = structor_ref)) := InstNode.getType(cls);

        if SCodeUtil.elementName(element) == "destructor" then
          Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT(destructor = structor_ref)) := InstNode.getType(cls);
        end if;

        node := InstNode.borrow(structor_ref);
      else
      end try;
    end if;
  end localClass;

  function componentClass
    "Returns the class of a component declared in the given class."
    input SCode.Element component;
    input InstNode scope;
    input Walk walk;
    output InstNode node = InstNode.EMPTY_NODE();
  protected
    Absyn.Path path;
    Option<Site> site;
  algorithm
    () := match component
      case SCode.COMPONENT(typeSpec = Absyn.TypeSpec.TPATH(path = path))
        algorithm
          // The type isn't written where the component is used.
          site := suspendRecording(walk);
          node := walkPath(path, scope, walk);
          leaveSite(site, walk);
        then
          ();

      else ();
    end match;
  end componentClass;

  function baseClasses
    "Returns the base classes of an expanded class."
    input InstNode cls;
    output list<InstNode> bases = {};
  protected
    Absyn.Path path;
  algorithm
    () := match InstNode.getClass(cls)
      local
        InstNode base;

      case Class.EXPANDED_DERIVED(baseClass = base)
        algorithm
          bases := {base};
        then
          ();

      else
        algorithm
          // The base class of a class extends is only known once the redeclare
          // is applied, it's the class with the same name that the enclosing
          // class inherits.
          if SCodeUtil.isClassExtends(InstNode.definition(cls)) then
            bases := listReverse(inheritedClasses(InstNode.name(cls), InstNode.parent(cls)));
          end if;

          // A class that couldn't be expanded may have no class tree.
          try
            for ext in ClassTree.getExtends(Class.classTree(InstNode.getClass(cls))) loop
              // The base class of an extends that couldn't be expanded, e.g. a class extends
              // that is only applied when the class it's in is instantiated, is looked up here.
              () := match InstNode.definition(ext)
                case SCode.EXTENDS(baseClassPath = path)
                  algorithm
                    ext := findClassPath(path, InstNode.parent(cls));
                  then
                    ();
                else ();
              end match;

              if InstNode.isClass(ext) then
                bases := ext :: bases;
              end if;
            end for;
          else
          end try;

          bases := listReverse(bases);
        then
          ();
    end match;
  end baseClasses;

  function inheritedClasses
    "Returns the classes with the given name that a class inherits."
    input String name;
    input InstNode cls;
    output list<InstNode> classes = {};
  protected
    InstNode n;
  algorithm
    if not InstNode.isClass(cls) then
      return;
    end if;

    for b in baseClasses(expandNode(cls)) loop
      n := findClass(name, b);

      if not InstNode.isEmpty(n) then
        classes := n :: classes;
      end if;
    end for;
  end inheritedClasses;

  function redeclaredClass
    "Returns the class extends or redeclared class with the given name declared
     in a class, or an empty node. The lookup finds the class it replaces."
    input String name;
    input InstNode cls "An expanded class.";
    output InstNode node = InstNode.EMPTY_NODE();
  algorithm
    for e in SCodeUtil.getClassElements(InstNode.definition(cls)) loop
      if SCodeUtil.elementIsClass(e) and isReplacingClass(e) and
         SCodeUtil.elementName(e) == name then
        node := localClass(e, cls);

        if not (InstNode.isClass(node) and elementKey(InstNode.definition(node)) == elementKey(e)) then
          node := InstNode.newClass(e, cls);
        end if;

        return;
      end if;
    end for;
  end redeclaredClass;

  function replacedClasses
    "Returns the classes a class extends or redeclared class replaces, and the
     classes those replace."
    input InstNode cls;
    output list<InstNode> classes = {};
  algorithm
    if isReplacingClass(InstNode.definition(cls)) then
      for r in inheritedClasses(InstNode.name(cls), InstNode.parent(cls)) loop
        classes := listAppend(r :: replacedClasses(r), classes);
      end for;
    end if;
  end replacedClasses;

  function isReplacingClass
    input SCode.Element element;
    output Boolean res = SCodeUtil.isClassExtends(element) or SCodeUtil.isElementRedeclare(element);
  end isReplacingClass;

  function findClass
    "Finds a class declared in a class or in one of its base classes, without
     recording anything. A class extends is found instead of the class it
     replaces."
    input String name;
    input InstNode cls;
    output InstNode node = InstNode.EMPTY_NODE();
  protected
    InstNode c = expandNode(cls);
  algorithm
    node := redeclaredClass(name, c);

    if InstNode.isClass(node) then
      return;
    end if;

    try
      node := Lookup.lookupLocalSimpleName(name, c);
    else
    end try;

    if not InstNode.isClass(node) then
      node := InstNode.EMPTY_NODE();

      for b in baseClasses(c) loop
        node := findClass(name, b);

        if not InstNode.isEmpty(node) then
          return;
        end if;
      end for;
    end if;
  end findClass;

  function findClassPath
    "Looks up the name of a class like lookupFirstIdent and walkRest do, without
     recording anything."
    input Absyn.Path path;
    input InstNode scope;
    output InstNode node = InstNode.EMPTY_NODE();
  protected
    InstNode cur = scope;
    String first = AbsynUtil.pathFirstIdent(path);
  algorithm
    if AbsynUtil.pathIsFullyQualified(path) then
      cur := InstNode.topScope(scope);
    else
      while InstNode.isClass(cur) and not InstNode.isTopScope(cur) loop
        node := findClass(first, cur);

        if InstNode.isClass(node) then
          break;
        elseif first == InstNode.name(cur) then
          node := cur;
          break;
        elseif InstNode.isEncapsulated(cur) then
          break;
        end if;

        cur := InstNode.parentScope(cur);
      end while;
    end if;

    if not InstNode.isClass(node) then
      try
        node := Lookup.lookupSimpleName(first, InstNode.topScope(scope), CONTEXT);
      else
        node := InstNode.EMPTY_NODE();
        return;
      end try;
    end if;

    for id in listRest(AbsynUtil.pathToStringList(AbsynUtil.makeNotFullyQualified(path))) loop
      node := findClass(id, node);

      if not InstNode.isClass(node) then
        return;
      end if;
    end for;
  end findClassPath;

  function lookupFirstIdent
    "Looks up the first part of a name in a scope and the scopes it's in. Returns
     the class found, or an empty node if the name is a component or isn't found."
    input String name;
    input InstNode scope;
    input Walk walk;
    input Boolean needType = false;
    output InstNode node = InstNode.EMPTY_NODE();
  protected
    InstNode cur = scope;
    Boolean found;
  algorithm
    while InstNode.isClass(cur) and not InstNode.isTopScope(cur) loop
      (node, found) := findElement(name, cur, walk, needType);

      if found then
        return;
      end if;

      // A class can refer to itself by its name.
      if name == InstNode.name(cur) then
        node := cur;
        setFound(FOUND_NODE(cur), walk);
        return;
      end if;

      if InstNode.isEncapsulated(cur) then
        break;
      end if;

      cur := InstNode.parentScope(cur);
    end while;

    // Top level classes, builtin classes and libraries that aren't loaded yet.
    try
      node := Lookup.lookupSimpleName(name, InstNode.topScope(scope), CONTEXT);
      setFound(FOUND_NODE(node), walk);
    else
    end try;
  end lookupFirstIdent;

  function isBuiltinName
    input String name;
    output Boolean builtin;
  algorithm
    try
      Lookup.lookupSimpleBuiltinName(name);
      builtin := true;
    else
      builtin := false;
    end try;
  end isBuiltinName;

  function expandNode
    input output InstNode node;
  protected
    list<InstNode> scopes = {};
    InstNode n;
  algorithm
    // Instantiate the classes the class is in before expanding it, like the
    // instantiation does when it looks the class up. A lookup through them,
    // e.g. of P.A in extends P.A of a class in P, copies their classes. A class
    // expanded first would be copied while it's being expanded, and the copy
    // would then be an extends loop for every class that extends it.
    () := match InstNode.getClass(node)
      case Class.NOT_INSTANTIATED()
        algorithm
          n := InstNode.parent(node);
          while InstNode.isClass(n) and not InstNode.isTopScope(n) loop
            scopes := n :: scopes;
            n := InstNode.parent(n);
          end while;

          for s in scopes loop
            try
              Inst.instPackage(s, CONTEXT);
            else
            end try;
          end for;
        then
          ();

      else ();
    end match;

    try
      node := Inst.expand(node, CONTEXT);
    else
    end try;
  end expandNode;

  function expandScopes
    "Expands a class and the classes it's declared in."
    input InstNode node;
  protected
    InstNode n = node;
  algorithm
    while InstNode.isClass(n) and not InstNode.isTopScope(n) loop
      expandNode(n);
      n := InstNode.parent(n);
    end while;
  end expandScopes;

  function walkQueue
    input Walk walk;
  protected
    list<InstNode> queue;
  algorithm
    while not listEmpty(Pointer.access(walk.queue)) loop
      queue := Pointer.access(walk.queue);
      Pointer.update(walk.queue, {});

      for c in queue loop
        try
          walkClass(c, walk);
        else
        end try;
      end for;
    end while;
  end walkQueue;

  function foundNode
    "Records a class or constant found by a lookup, and the classes it's in."
    input InstNode node;
    input Walk walk;
  protected
    InstNode n = node;
    String key;
  algorithm
    while InstNode.isClass(n) or InstNode.isComponent(n) loop
      if InstNode.isTopScope(n) or InstNode.isBuiltin(n) then
        break;
      end if;

      try
        key := elementKey(InstNode.definition(n));
      else
        key := "";
      end try;

      if stringEmpty(key) then
        break;
      end if;

      if UnorderedSet.contains(key, walk.used) or isRecording(walk) then
        break;
      end if;

      UnorderedSet.add(key, walk.used);

      if InstNode.isClass(n) then
        Pointer.update(walk.queue, n :: Pointer.access(walk.queue));
      else
        walkPackageConstant(n, walk);
      end if;

      n := InstNode.parent(n);
    end while;
  end foundNode;

  function walkPackageConstant
    "Walks a component found by a lookup, if it's declared in a package."
    input InstNode node;
    input Walk walk;
  protected
    InstNode scope = InstNode.parent(node);
    SCode.Element def = InstNode.definition(node);
  algorithm
    if InstNode.isClass(scope) and SCodeUtil.isPackage(InstNode.definition(scope)) and
       not UnorderedSet.contains(elementKey(def), walk.walked) then
      UnorderedSet.add(elementKey(def), walk.walked);
      walkElement(def, scope, walk);
    end if;
  end walkPackageConstant;

  function walkClass
    input InstNode node;
    input Walk walk;
    input Boolean allConstants = false;
  protected
    InstNode cls = node, scope, op, replacement;
    SCode.Element def = InstNode.definition(node);
    Boolean is_operator;
    String key = elementKey(def);
    Boolean is_package;
    Option<Site> site = NONE();
  algorithm
    if UnorderedSet.contains(key, walk.walked) then
      return;
    end if;

    UnorderedSet.add(key, walk.walked);
    Pointer.update(walk.classes, node :: Pointer.access(walk.classes));

    // Lookups in the class also search the classes it's declared in.
    expandScopes(InstNode.parent(node));
    cls := expandNode(node);
    scope := InstNode.parent(cls);

    if isRecording(walk) then
      declareClass(def, walk);
      site := enterSite(SCodeUtil.elementInfo(def), "annotation", walk);
    end if;

    walkAnnotation(def, cls, walk);

    // A class extends replaces the inherited class with its name.
    if SCodeUtil.isClassExtends(def) then
      UnorderedSet.add(InstNode.name(node), walk.names);
      setRole("classExtends", walk);

      for r in inheritedClasses(InstNode.name(node), InstNode.parent(node)) loop
        recordFound(FOUND_NODE(r), Absyn.IDENT(InstNode.name(node)), 1, walk);
      end for;
    end if;

    // A redeclare element replaces the inherited class with its name.
    if SCodeUtil.elementIsClass(def) and SCodeUtil.isElementRedeclare(def) then
      replacement := match InstNode.getClass(cls)
        case Class.EXPANDED_DERIVED(baseClass = replacement) then replacement;
        else cls;
      end match;

      setRole("redeclare", walk);

      for r in inheritedClasses(InstNode.name(node), InstNode.parent(node)) loop
        // Already recorded as the class it extends.
        if not SCodeUtil.isClassExtends(def) then
          recordFound(FOUND_NODE(r), Absyn.IDENT(InstNode.name(node)), 1, walk);
        end if;

        // It also replaces what the replaced class replaces, e.g. a class extends
        // of a class extends of a replaceable class.
        for rr in r :: replacedClasses(r) loop
          redeclared(rr, replacement, walk);
        end for;
      end for;
    end if;

    // Some functions are used without being named: the operators of an
    // operator record (any function of an operator can be the one used), the
    // equalityConstraint of an overdetermined type and the constructor and
    // destructor of an external object.
    is_operator := SCodeUtil.isOperatorRecord(def) or SCodeUtil.isOperator(def);

    for e in SCodeUtil.getClassElements(def) loop
      if SCodeUtil.elementIsClass(e) and
         (is_operator and (SCodeUtil.isOperator(e) or SCodeUtil.isFunction(e)) or
          listMember(SCodeUtil.elementName(e), {"equalityConstraint", "constructor", "destructor"})) then
        op := localClass(e, cls);

        if InstNode.isClass(op) then
          foundNode(op, walk);
        end if;
      end if;
    end for;

    setRole("extends", walk);

    () := match def
      case SCode.CLASS()
        algorithm
          is_package := SCodeUtil.isPackage(def) and not allConstants;
          walkClassDef(def.classDef, cls, scope, is_package, walk);
        then
          ();

      else ();
    end match;

    leaveSite(site, walk);
  end walkClass;

  function declareClass
    "Adds a walked class and the components declared in it to the definitions."
    input SCode.Element def;
    input Walk walk;
  protected
    String name;
  algorithm
    () := match walk.recorder
      local
        Recorder rec;
      case SOME(rec)
        algorithm
          name := Pointer.access(rec.scope);
          declare(def, name, walk);

          for e in SCodeUtil.getClassElements(def) loop
            if SCodeUtil.isComponent(e) then
              declare(e, name + "." + SCodeUtil.elementName(e), walk);
            end if;
          end for;
        then
          ();
      else ();
    end match;
  end declareClass;

  function walkClassDef
    input SCode.ClassDef classDef;
    input InstNode cls "The scope inside the class.";
    input InstNode scope "The scope the class is declared in.";
    input Boolean isPackage "Constants of packages are only walked when used.";
    input Walk walk;
  protected
    list<SCode.Statement> stmts;
    list<Absyn.Exp> exps;
    Absyn.ArrayDim dims;
    InstNode target;
    Option<Absyn.ComponentRef> ext_output;
  algorithm
    () := match classDef
      case SCode.PARTS()
        algorithm
          for e in classDef.elementLst loop
            if not (isPackage and SCodeUtil.isComponent(e)) then
              try
                walkElement(e, cls, walk);
              else
              end try;
            end if;
          end for;

          for eq in listAppend(classDef.normalEquationLst, classDef.initialEquationLst) loop
            walkEquation(eq, cls, walk);
          end for;

          for alg in listAppend(classDef.normalAlgorithmLst, classDef.initialAlgorithmLst) loop
            SCode.ALGORITHM(statements = stmts) := alg;

            for stmt in stmts loop
              if isRecording(walk) then
                walkStatement(stmt, cls, walk);
              else
                SCodeUtil.foldStatementsExps(stmt, function walkExp(scope = cls), walk);
              end if;
            end for;
          end for;

          setRole("external", walk);

          for c in classDef.constraintLst loop
            SCode.CONSTRAINTS(constraints = exps) := c;
            List.fold(exps, function walkExp(scope = cls), walk);
          end for;

          () := match classDef.externalDecl
            case SOME(SCode.EXTERNALDECL(args = exps, output_ = ext_output))
              algorithm
                if isSome(ext_output) then
                  walkCref(Util.getOption(ext_output), cls, walk);
                end if;

                List.fold(exps, function walkExp(scope = cls), walk);
              then
                ();
            else ();
          end match;
        then
          ();

      case SCode.CLASS_EXTENDS()
        algorithm
          walkMod(classDef.modifications, cls, walk);
          walkClassDef(classDef.composition, cls, scope, isPackage, walk);
        then
          ();

      // The base class of a short class definition and its modifiers are
      // looked up where the class is declared.
      case SCode.DERIVED()
        algorithm
          target := walkTypeSpec(classDef.typeSpec, scope, walk);
          walkMod(classDef.modifications, scope, walk, target);
          SCode.ATTR(arrayDims = dims) := classDef.attributes;
          walkDims(dims, scope, walk);
        then
          ();

      case SCode.OVERLOAD()
        algorithm
          for p in classDef.pathLst loop
            walkPath(p, scope, walk);
          end for;
        then
          ();

      case SCode.PDER()
        algorithm
          walkPath(classDef.functionPath, scope, walk);
        then
          ();

      else ();
    end match;
  end walkClassDef;

  function walkElement
    "Walks an element of a class. Classes declared in it are walked when they
     are found by a lookup."
    input SCode.Element element;
    input InstNode scope;
    input Walk walk;
    input Boolean inModifier = false "The name of a redeclare in a modifier is recorded by the modifier.";
  protected
    Found inherited = NOT_FOUND();
    Absyn.ArrayDim dims;
    Absyn.Path path;
    InstNode target;
    Option<Site> site;
    list<Absyn.GroupImport> groups;
  algorithm
    site := enterSite(SCodeUtil.elementInfo(element), "type", walk);

    () := match element
      case SCode.COMPONENT()
        algorithm
          // A redeclared component replaces the inherited one with its name.
          if isRecording(walk) and SCodeUtil.isElementRedeclare(element) and not inModifier then
            inherited := recordInherited(SCodeUtil.elementName(element), scope, walk);
            setRole("type", walk);
          end if;

          // In the order they're written, the uses are placed in that order.
          target := walkTypeSpec(element.typeSpec, scope, walk);

          if not stringEmpty(replaceableComponentKey(inherited)) then
            redeclaredKey(replaceableComponentKey(inherited), target, walk);
          end if;
          setRole("dimension", walk);
          SCode.ATTR(arrayDims = dims) := element.attributes;
          walkDims(dims, scope, walk);
          setRole("type", walk);
          walkMod(element.modifications, scope, walk, target);

          if isSome(element.condition) then
            setRole("condition", walk);
            walkExp(Util.getOption(element.condition), scope, walk);
          end if;

          setRole("constrainedby", walk);
          walkConstrainingClass(element.prefixes, scope, walk);
        then
          ();

      case SCode.EXTENDS()
        algorithm
          setRole("extends", walk);
          target := walkPath(element.baseClassPath, scope, walk);
          walkMod(element.modifications, scope, walk, target);
        then
          ();

      // An unqualified import is kept, so what it imports is needed.
      case SCode.IMPORT(imp = Absyn.Import.UNQUAL_IMPORT(path = path))
        algorithm
          setRole("import", walk);
          walkPath(Absyn.Path.FULLYQUALIFIED(path), scope, walk, path);
        then
          ();

      // The other imports are only walked for their uses.
      case SCode.IMPORT()
        guard isRecording(walk)
        algorithm
          setRole("import", walk);

          () := match element.imp
            case Absyn.Import.QUAL_IMPORT(path = path)
              algorithm
                walkPath(Absyn.Path.FULLYQUALIFIED(path), scope, walk, path);
              then
                ();

            case Absyn.Import.NAMED_IMPORT(path = path)
              algorithm
                walkPath(Absyn.Path.FULLYQUALIFIED(path), scope, walk, path);
              then
                ();

            // import P.{a, b = c}: the names are looked up in P.
            case Absyn.Import.GROUP_IMPORT(prefix = path, groups = groups)
              algorithm
                target := walkPath(Absyn.Path.FULLYQUALIFIED(path), scope, walk, path);

                if InstNode.isClass(target) then
                  for g in groups loop
                    () := match g
                      case Absyn.GroupImport.GROUP_IMPORT_NAME()
                        algorithm
                          walkRest(Absyn.IDENT(g.name), target, walk);
                        then
                          ();
                      case Absyn.GroupImport.GROUP_IMPORT_RENAME()
                        algorithm
                          walkRest(Absyn.IDENT(g.name), target, walk);
                        then
                          ();
                      else ();
                    end match;
                  end for;
                end if;
              then
                ();

            else ();
          end match;
        then
          ();

      else ();
    end match;

    leaveSite(site, walk);
  end walkElement;

  function recordInherited
    "Records a use of the element with the given name that a class inherits,
     returns what was found."
    input String name;
    input InstNode cls;
    input Walk walk;
    output Found found = NOT_FOUND();
  protected
    Boolean is_found;
  algorithm
    for b in baseClasses(expandNode(cls)) loop
      takeFound(walk);
      (_, is_found) := findElement(name, b, walk);

      if is_found then
        found := takeFound(walk);
        recordFound(found, Absyn.IDENT(name), 1, walk);
        return;
      end if;
    end for;
  end recordInherited;

  function walkNamedElements
    "Walks the replaceable, redeclared and class extends elements of a class
     that have the name of something found elsewhere, since they might replace
     it or be replaced by it."
    input InstNode cls;
    input Walk walk;
  protected
    SCode.Element def = InstNode.definition(cls);
    InstNode c = expandNode(cls), node;
  algorithm
    for e in SCodeUtil.getClassElements(def) loop
      if (SCodeUtil.elementIsClass(e) or SCodeUtil.isComponent(e)) and
         (SCodeUtil.isElementReplaceable(e) or SCodeUtil.isElementRedeclare(e) or
          SCodeUtil.isClassExtends(e)) and
         UnorderedSet.contains(SCodeUtil.elementName(e), walk.names) and
         not UnorderedSet.contains(elementKey(e), walk.used) then
        if SCodeUtil.isComponent(e) then
          foundComponent(e, c, walk);
        elseif SCodeUtil.elementIsClass(e) then
          node := localClass(e, c);

          if InstNode.isClass(node) then
            foundNode(node, walk);
          end if;
        end if;
      end if;
    end for;
  end walkNamedElements;

  function walkConstrainingClass
    input SCode.Prefixes prefixes;
    input InstNode scope;
    input Walk walk;
  algorithm
    () := match prefixes
      local
        SCode.ConstrainClass cc;

      case SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(cc = SOME(cc as SCode.CONSTRAINCLASS())))
        algorithm
          walkMod(cc.modifier, scope, walk, walkPath(cc.constrainingClass, scope, walk));
        then
          ();

      else ();
    end match;
  end walkConstrainingClass;

  function walkAnnotation
    "Walks the derivative and inverse annotations of a function, which refer to
     other functions."
    input SCode.Element element;
    input InstNode scope;
    input Walk walk;
  algorithm
    () := match element
      local
        SCode.Mod mod;

      case SCode.CLASS(cmt = SCode.COMMENT(annotation_ = SOME(SCode.ANNOTATION(modification = mod as SCode.MOD()))))
        algorithm
          for sm in mod.subModLst loop
            if sm.ident == "derivative" or sm.ident == "inverse" then
              walkMod(sm.mod, scope, walk);
            end if;
          end for;
        then
          ();

      else ();
    end match;
  end walkAnnotation;

  function walkMod
    "Walks the expressions in a modifier, which are looked up where the modifier
     is written, and looks up the modified elements in the modified class."
    input SCode.Mod mod;
    input InstNode scope;
    input Walk walk;
    input InstNode target = InstNode.EMPTY_NODE() "The modified class, if known.";
  protected
    SCode.ClassDef cdef;
    InstNode node;
    Option<Site> site;
    Absyn.ArrayDim dims;
    Found found;
    SCode.Element elem;
  algorithm
    () := match mod
      case SCode.MOD()
        algorithm
          for sm in mod.subModLst loop
            takeFound(walk);
            node := foundLocalName(sm.ident, target, walk, needType = hasSubMods(sm.mod));
            found := takeFound(walk);

            if InstNode.isClass(target) then
              site := setRole("modifier", walk);
              lookedUpThrough(target, Absyn.IDENT(sm.ident), walk);
              recordFound(found, Absyn.IDENT(sm.ident), 1, walk);
              leaveSite(site, walk);
            end if;

            // A redeclared component gives the replaceable one a new type.
            () := match sm.mod
              case SCode.REDECL(element = elem as SCode.COMPONENT())
                guard isRecording(walk) and not stringEmpty(replaceableComponentKey(found))
                algorithm
                  redeclaredKey(replaceableComponentKey(found), componentClass(elem, scope, walk), walk);
                then
                  ();
              else ();
            end match;

            walkMod(sm.mod, scope, walk, if InstNode.isClass(node) then node else InstNode.EMPTY_NODE());
          end for;

          if isSome(mod.binding) then
            site := setRole("binding", walk);
            walkExp(Util.getOption(mod.binding), scope, walk);
            leaveSite(site, walk);
          end if;
        then
          ();

      // The element of a redeclare is looked up where the modifier is written.
      // The target is what it replaces, found by the enclosing modifier.
      case SCode.REDECL()
        algorithm
          site := setRole("type", walk);

          () := match mod.element
            case SCode.CLASS(classDef = cdef as SCode.DERIVED())
              algorithm
                node := walkTypeSpec(cdef.typeSpec, scope, walk);
                redeclared(target, node, walk);
                walkMod(cdef.modifications, scope, walk, node);
                SCode.ATTR(arrayDims = dims) := cdef.attributes;
                walkDims(dims, scope, walk);
              then
                ();

            case SCode.CLASS(classDef = cdef)
              algorithm
                walkClassDef(cdef, scope, scope, false, walk);
              then
                ();

            else
              algorithm
                walkElement(mod.element, scope, walk, inModifier = true);
              then
                ();
          end match;

          leaveSite(site, walk);
        then
          ();

      else ();
    end match;
  end walkMod;

  function hasSubMods
    input SCode.Mod mod;
    output Boolean res;
  algorithm
    res := match mod
      case SCode.MOD(subModLst = _ :: _) then true;
      else false;
    end match;
  end hasSubMods;

  function walkEquation
    input SCode.Equation eq;
    input InstNode scope;
    input Walk walk;
  protected
    Option<Site> site;
  algorithm
    if not isRecording(walk) then
      SCodeUtil.foldEquationsExps(eq, function walkExp(scope = scope), walk);
      return;
    end if;

    // Each equation is its own site, and a for equation declares its iterator.
    site := enterSite(SCodeUtil.getEquationInfo(eq), "equation", walk);

    () := match eq
      case SCode.EQ_CONNECT()
        algorithm
          walkCref(eq.crefLeft, scope, walk);
          walkCref(eq.crefRight, scope, walk);
        then
          ();

      else
        algorithm
          SCodeUtil.mapEquationExps(eq, function walkExpMap(scope = scope, walk = walk));
        then
          ();
    end match;

    () := match eq
      case SCode.EQ_IF()
        algorithm
          for branch in eq.thenBranch loop
            for e in branch loop
              walkEquation(e, scope, walk);
            end for;
          end for;

          for e in eq.elseBranch loop
            walkEquation(e, scope, walk);
          end for;
        then
          ();

      case SCode.EQ_FOR()
        algorithm
          pushIterator(eq.index, walk);

          for e in eq.eEquationLst loop
            walkEquation(e, scope, walk);
          end for;

          popIterator(walk);
        then
          ();

      case SCode.EQ_WHEN()
        algorithm
          for e in eq.eEquationLst loop
            walkEquation(e, scope, walk);
          end for;

          for b in eq.elseBranches loop
            for e in Util.tuple22(b) loop
              walkEquation(e, scope, walk);
            end for;
          end for;
        then
          ();

      else ();
    end match;

    leaveSite(site, walk);
  end walkEquation;

  function walkStatement
    "Walks a statement while recording, each statement is its own site."
    input SCode.Statement stmt;
    input InstNode scope;
    input Walk walk;
  protected
    Option<Site> site;
  algorithm
    site := enterSite(SCodeUtil.getStatementInfo(stmt), "algorithm", walk);
    SCodeUtil.mapStatementExps(stmt, function walkExpMap(scope = scope, walk = walk));

    () := match stmt
      case SCode.ALG_IF()
        algorithm
          walkStatements(stmt.trueBranch, scope, walk);

          for b in stmt.elseIfBranch loop
            walkStatements(Util.tuple22(b), scope, walk);
          end for;

          walkStatements(stmt.elseBranch, scope, walk);
        then
          ();

      case SCode.ALG_FOR()
        algorithm
          pushIterator(stmt.index, walk);
          walkStatements(stmt.forBody, scope, walk);
          popIterator(walk);
        then
          ();

      case SCode.ALG_PARFOR()
        algorithm
          pushIterator(stmt.index, walk);
          walkStatements(stmt.parforBody, scope, walk);
          popIterator(walk);
        then
          ();

      case SCode.ALG_WHILE()
        algorithm
          walkStatements(stmt.whileBody, scope, walk);
        then
          ();

      case SCode.ALG_WHEN_A()
        algorithm
          for b in stmt.branches loop
            walkStatements(Util.tuple22(b), scope, walk);
          end for;
        then
          ();

      case SCode.ALG_FAILURE()
        algorithm
          walkStatements(stmt.stmts, scope, walk);
        then
          ();

      case SCode.ALG_TRY()
        algorithm
          walkStatements(stmt.body, scope, walk);
          walkStatements(stmt.elseBody, scope, walk);
        then
          ();

      else ();
    end match;

    leaveSite(site, walk);
  end walkStatement;

  function walkStatements
    input list<SCode.Statement> stmts;
    input InstNode scope;
    input Walk walk;
  algorithm
    for s in stmts loop
      walkStatement(s, scope, walk);
    end for;
  end walkStatements;

  function walkDims
    input Absyn.ArrayDim dims;
    input InstNode scope;
    input Walk walk;
  algorithm
    for d in dims loop
      () := match d
        case Absyn.Subscript.SUBSCRIPT()
          algorithm
            walkExp(d.subscript, scope, walk);
          then
            ();
        else ();
      end match;
    end for;
  end walkDims;

  function walkTypeSpec
    input Absyn.TypeSpec ty;
    input InstNode scope;
    input Walk walk;
    output InstNode node = InstNode.EMPTY_NODE() "The class, if found.";
  algorithm
    () := match ty
      case Absyn.TypeSpec.TPATH()
        algorithm
          node := walkPath(ty.path, scope, walk);

          if isSome(ty.arrayDim) then
            walkDims(Util.getOption(ty.arrayDim), scope, walk);
          end if;
        then
          ();

      else ();
    end match;
  end walkTypeSpec;

  function walkExp
    input Absyn.Exp exp;
    input InstNode scope;
    input output Walk walk;
  algorithm
    if isRecording(walk) then
      AbsynUtil.traverseExpBidir(exp, function recordExpEnter(scope = scope),
        recordExpExit, walk);
    else
      AbsynUtil.traverseExp(exp, function walkExpNode(scope = scope), walk);
    end if;
  end walkExp;

  function walkExpMap
    input output Absyn.Exp exp;
    input InstNode scope;
    input Walk walk;
  algorithm
    walkExp(exp, scope, walk);
  end walkExpMap;

  function recordExpEnter
    "Looks up the names in an expression while recording. The iterators of a
     reduction are declared for its expression, and the named arguments of a
     call are looked up in the function."
    input output Absyn.Exp exp;
    input InstNode scope;
    input output Walk walk;
  protected
    InstNode fn;
    list<Absyn.NamedArg> args;
    Absyn.ForIterators iters;
  algorithm
    () := match exp
      // The level AbsynToSCode adds to an assert without one isn't written.
      case Absyn.Exp.CREF(componentRef = Absyn.ComponentRef.CREF_FULLYQUALIFIED(
          componentRef = Absyn.ComponentRef.CREF_QUAL(name = "AssertionLevel")))
        then ();

      // The subscripts are traversed as subexpressions.
      case Absyn.Exp.CREF()
        algorithm
          walkCref(exp.componentRef, scope, walk, walkSubscripts = false);
        then
          ();

      case Absyn.Exp.CALL()
        algorithm
          fn := walkCref(exp.function_, scope, walk);

          () := match exp.functionArgs
            case Absyn.FunctionArgs.FUNCTIONARGS(argNames = args)
              algorithm
                recordNamedArgs(args, fn, walk);
              then
                ();

            case Absyn.FunctionArgs.FOR_ITER_FARG(iterators = iters)
              algorithm
                for it in iters loop
                  pushIterator(it.name, walk);
                end for;
              then
                ();

            else ();
          end match;
        then
          ();

      case Absyn.Exp.PARTEVALFUNCTION()
        algorithm
          fn := walkCref(exp.function_, scope, walk);

          () := match exp.functionArgs
            case Absyn.FunctionArgs.FUNCTIONARGS(argNames = args)
              algorithm
                recordNamedArgs(args, fn, walk);
              then
                ();
            else ();
          end match;
        then
          ();

      else ();
    end match;
  end recordExpEnter;

  function recordExpExit
    input output Absyn.Exp exp;
    input output Walk walk;
  protected
    Absyn.ForIterators iters;
  algorithm
    () := match exp
      case Absyn.Exp.CALL(functionArgs = Absyn.FunctionArgs.FOR_ITER_FARG(iterators = iters))
        algorithm
          for it in iters loop
            popIterator(walk);
          end for;
        then
          ();
      else ();
    end match;
  end recordExpExit;

  function recordNamedArgs
    "Records the named arguments of a call as uses of the inputs of the function."
    input list<Absyn.NamedArg> args;
    input InstNode fn;
    input Walk walk;
  protected
    Option<Site> site;
    InstNode f = fn, constructor;
  algorithm
    if listEmpty(args) or not InstNode.isClass(fn) or InstNode.isBuiltin(fn) then
      return;
    end if;

    // An external object is called as its constructor.
    for e in SCodeUtil.getClassElements(InstNode.definition(fn)) loop
      if SCodeUtil.elementIsClass(e) and SCodeUtil.elementName(e) == "constructor" then
        constructor := localClass(e, expandNode(fn));

        if InstNode.isClass(constructor) then
          f := constructor;
        end if;

        break;
      end if;
    end for;

    site := setRole("argument", walk);

    for a in args loop
      lookedUpThrough(f, Absyn.IDENT(a.argName), walk);
      takeFound(walk);
      foundLocalName(a.argName, f, walk);
      recordFound(takeFound(walk), Absyn.IDENT(a.argName), 1, walk);
    end for;

    leaveSite(site, walk);
  end recordNamedArgs;

  function walkExpNode
    input output Absyn.Exp exp;
    input InstNode scope;
    input output Walk walk;
  algorithm
    () := match exp
      case Absyn.Exp.CREF()
        algorithm
          walkCref(exp.componentRef, scope, walk);
        then
          ();

      case Absyn.Exp.CALL()
        algorithm
          walkCref(exp.function_, scope, walk);
        then
          ();

      case Absyn.Exp.PARTEVALFUNCTION()
        algorithm
          walkCref(exp.function_, scope, walk);
        then
          ();

      else ();
    end match;
  end walkExpNode;

  function walkCref
    "Looks up the name a component reference begins with, as far as it goes
     through classes, and walks its subscripts."
    input Absyn.ComponentRef cref;
    input InstNode scope;
    input Walk walk;
    input Boolean walkSubscripts = true;
    output InstNode node = InstNode.EMPTY_NODE() "What the whole name refers to, if found.";
  algorithm
    try
      node := walkPath(AbsynUtil.crefToPathIgnoreSubs(cref), scope, walk);
    else
    end try;

    if not walkSubscripts then
      return;
    end if;

    for s in AbsynUtil.getSubsFromCref(cref, true, true) loop
      () := match s
        case Absyn.Subscript.SUBSCRIPT()
          algorithm
            walkExp(s.subscript, scope, walk);
          then
            ();
        else ();
      end match;
    end for;
  end walkCref;

  function walkPath
    "Looks up a name as far as it goes through classes, recording what it
     finds. Classes are only expanded, not instantiated, to look inside them."
    input Absyn.Path path;
    input InstNode scope;
    input Walk walk;
    input Absyn.Path written = path "The name as written where it's used.";
    input Integer index = 1 "The part of the written name the path begins with.";
    output InstNode node = InstNode.EMPTY_NODE() "What the whole name refers to, if found.";
  protected
    InstNode n;
    Found found;
    String comp_key;
  algorithm
    () := match path
      case Absyn.Path.FULLYQUALIFIED()
        algorithm
          node := walkPath(path.path, InstNode.topScope(scope), walk, written, index);
        then
          ();

      else
        algorithm
          if isRecording(walk) and not AbsynUtil.pathIsFullyQualified(written) and
             recordIterator(AbsynUtil.pathFirstIdent(path), written, walk) then
            return;
          end if;

          if isBuiltinName(AbsynUtil.pathFirstIdent(path)) or AbsynUtil.pathFirstIdent(path) == "time" or
             stringGet(AbsynUtil.pathFirstIdent(path), 1) == 36 /* $, e.g. $array */ then
            return;
          end if;

          // Something that isn't found, e.g. Medium.f where only the redeclared
          // Medium has f, may be found by its name in another class.
          for id in AbsynUtil.pathToStringList(path) loop
            UnorderedSet.add(id, walk.names);
          end for;

          takeFound(walk);
          n := lookupFirstIdent(AbsynUtil.pathFirstIdent(path), scope, walk,
            needType = AbsynUtil.pathIsQual(path));
          found := takeFound(walk);
          recordFound(found, written, index, walk);

          // The rest of the name is also looked up in the types a replaceable component is redeclared with.
          comp_key := replaceableComponentKey(found);
          if isRecording(walk) and AbsynUtil.pathIsQual(path) and not stringEmpty(comp_key) then
            lookedUpThroughRecording(comp_key, AbsynUtil.pathRest(path), written, index + 1, walk);
          end if;

          if InstNode.isEmpty(n) then
            return;
          end if;

          foundNode(n, walk);

          if AbsynUtil.pathIsQual(path) then
            node := walkRest(AbsynUtil.pathRest(path), n, walk, written, index + 1);
          else
            node := n;
          end if;
        then
          ();
    end match;
  end walkPath;

  function walkRest
    "Looks up the rest of a name in the class the first part was found in."
    input Absyn.Path path;
    input InstNode cls;
    input Walk walk;
    input Absyn.Path written = path "The name as written where it's used.";
    input Integer index = 1 "The part of the written name the path begins with.";
    output InstNode node = cls;
  protected
    Absyn.Path rest = path;
    Integer i = index;
    Boolean searched;
    Found found;
    String comp_key;
  algorithm
    while true loop
      lookedUpThrough(node, rest, walk, written, i);
      searched := InstNode.isClass(node);
      takeFound(walk);
      node := foundLocalName(AbsynUtil.pathFirstIdent(rest), node, walk,
        needType = AbsynUtil.pathIsQual(rest));
      found := takeFound(walk);

      if searched then
        recordFound(found, written, i, walk);
      end if;

      comp_key := replaceableComponentKey(found);
      if isRecording(walk) and AbsynUtil.pathIsQual(rest) and not stringEmpty(comp_key) then
        lookedUpThroughRecording(comp_key, AbsynUtil.pathRest(rest), written, i + 1, walk);
      end if;

      if InstNode.isEmpty(node) or not AbsynUtil.pathIsQual(rest) then
        break;
      end if;

      rest := AbsynUtil.pathRest(rest);
      i := i + 1;
    end while;
  end walkRest;

  function lookedUpThrough
    "Remembers the rest of a name looked up through a replaceable class, and
     looks it up in the classes it's redeclared as. Those may not extend the
     replaceable class and only have the same contents, e.g. Medium.f with
     redeclare package Medium = A where A only declares its own f."
    input InstNode cls;
    input Absyn.Path rest;
    input Walk walk;
    input Absyn.Path written = rest;
    input Integer index = 1;
  protected
    String key;
    list<Absyn.Path> rests;
    list<InstNode> replacements;
  algorithm
    if not (InstNode.isClass(cls) and SCodeUtil.isElementReplaceable(InstNode.definition(cls))) then
      return;
    end if;

    key := elementKey(InstNode.definition(cls));

    if isRecording(walk) then
      lookedUpThroughRecording(key, rest, written, index, walk);
      return;
    end if;

    rests := UnorderedMap.getOrDefault(key, walk.rests, {});

    if not List.isMemberOnTrue(rest, rests, AbsynUtil.pathEqual) then
      UnorderedMap.add(key, rest :: rests, walk.rests);
      replacements := UnorderedMap.getOrDefault(key, walk.replacements, {});

      for r in replacements loop
        walkRest(rest, r, walk);
      end for;
    end if;
  end lookedUpThrough;

  function redeclared
    "Remembers that a replaceable class is redeclared as another class, and
     looks up in it what was looked up through the replaceable class."
    input InstNode replaced;
    input InstNode replacement;
    input Walk walk;
  algorithm
    if InstNode.isClass(replaced) and InstNode.isClass(replacement) then
      redeclaredKey(elementKey(InstNode.definition(replaced)), replacement, walk);
    end if;
  end redeclared;

  function redeclaredKey
    "Remembers that the replaceable class or component with the given key is
     redeclared as, or with the type of, another class."
    input String key;
    input InstNode replacement;
    input Walk walk;
  protected
    list<InstNode> replacements;
    list<Absyn.Path> rests;
    list<Pending> pending;
  algorithm
    if not InstNode.isClass(replacement) then
      return;
    end if;

    replacements := UnorderedMap.getOrDefault(key, walk.replacements, {});

    if not List.isMemberOnTrue(replacement, replacements, InstNode.refEqual) then
      UnorderedMap.add(key, replacement :: replacements, walk.replacements);

      () := match walk.recorder
        local
          Recorder rec;

        case SOME(rec)
          algorithm
            pending := UnorderedMap.getOrDefault(key, rec.pending, {});

            for p in pending loop
              walkPending(p, replacement, walk);
            end for;
          then
            ();

        else
          algorithm
            rests := UnorderedMap.getOrDefault(key, walk.rests, {});

            for rest in rests loop
              walkRest(rest, replacement, walk);
            end for;
          then
            ();
      end match;
    end if;
  end redeclaredKey;

  function replaceableComponentKey
    "Returns the key of a replaceable component that was found, or an empty string."
    input Found found;
    output String key = "";
  protected
    SCode.Element e;
  algorithm
    try
      e := match found
        case FOUND_ELEMENT(element = e) then e;
        case FOUND_NODE() guard InstNode.isComponent(found.node) then InstNode.definition(found.node);
      end match;

      if SCodeUtil.isComponent(e) and SCodeUtil.isElementReplaceable(e) then
        key := elementKey(e);
      end if;
    else
    end try;
  end replaceableComponentKey;

  function lookedUpThroughRecording
    "Remembers where the rest of a name was looked up through a replaceable
     class, and records what it refers to in the classes it's redeclared as."
    input String key;
    input Absyn.Path rest;
    input Absyn.Path written;
    input Integer index;
    input Walk walk;
  protected
    Site site;
    Pending p;
    String pkey;
    list<InstNode> replacements;
  algorithm
    () := match walk.recorder
      local
        Recorder rec;

      case SOME(rec)
        guard isSome(Pointer.access(rec.site))
        algorithm
          SOME(site) := Pointer.access(rec.site);
          pkey := stringAppendList({key, "|", AbsynUtil.pathString(written), "|",
            intString(index), "|", site.info.fileName, ":", intString(site.info.lineNumberStart),
            ":", intString(site.info.columnNumberStart)});

          if not UnorderedSet.contains(pkey, rec.pendingKeys) then
            UnorderedSet.add(pkey, rec.pendingKeys);
            p := PENDING(rest, written, index, site);
            UnorderedMap.add(key, p :: UnorderedMap.getOrDefault(key, rec.pending, {}), rec.pending);

            replacements := UnorderedMap.getOrDefault(key, walk.replacements, {});

            for r in replacements loop
              walkPending(p, r, walk);
            end for;
          end if;
        then
          ();

      else ();
    end match;
  end lookedUpThroughRecording;

  function walkPending
    "Looks up the rest of a name used through a replaceable class in a class it's
     redeclared as, recording the uses at the site of the name."
    input Pending pending;
    input InstNode replacement;
    input Walk walk;
  protected
    Option<Site> site;
    Boolean candidate;
  algorithm
    () := match walk.recorder
      local
        Recorder rec;

      case SOME(rec)
        algorithm
          site := Pointer.access(rec.site);
          candidate := Pointer.access(rec.candidate);
          Pointer.update(rec.site, SOME(pending.site));
          Pointer.update(rec.candidate, true);
          walkRest(pending.rest, replacement, walk, pending.written, pending.index);
          Pointer.update(rec.site, site);
          Pointer.update(rec.candidate, candidate);
        then
          ();

      else ();
    end match;
  end walkPending;

annotation(__OpenModelica_Interface="nf_frontend");
end NFUsedElements;

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
   replaces, and keeps more than is used rather than less."

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
  import UnorderedMap;
  import Util;

  constant InstContext.Type CONTEXT =
    intBitOr(NFInstContext.RELAXED, NFInstContext.FAST_LOOKUP);

  type PathList = list<Absyn.Path>;
  type NodeList = list<InstNode>;

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
    end WALK;
  end Walk;

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
                 UnorderedMap.new<NodeList>(stringHashDjb2, stringEq));

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

    if found then
      UnorderedSet.add(name, walk.names);
      foundNode(n, walk);

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

    if SCodeUtil.isPackage(InstNode.definition(cls)) and not UnorderedSet.contains(key, walk.walked) then
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
  algorithm
    () := match component
      case SCode.COMPONENT(typeSpec = Absyn.TypeSpec.TPATH(path = path))
        algorithm
          node := walkPath(path, scope, walk);
        then
          ();

      else ();
    end match;
  end componentClass;

  function baseClasses
    "Returns the base classes of an expanded class."
    input InstNode cls;
    output list<InstNode> bases = {};
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

          for ext in ClassTree.getExtends(Class.classTree(InstNode.getClass(cls))) loop
            if InstNode.isClass(ext) then
              bases := ext :: bases;
            end if;
          end for;

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

  function findClass
    "Finds a class declared in a class or in one of its base classes, without
     recording anything."
    input String name;
    input InstNode cls;
    output InstNode node = InstNode.EMPTY_NODE();
  protected
    InstNode c = expandNode(cls);
  algorithm
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
  algorithm
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

      if UnorderedSet.contains(key, walk.used) then
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
    walkAnnotation(def, cls, walk);

    // A class extends replaces the inherited class with its name.
    if SCodeUtil.isClassExtends(def) then
      UnorderedSet.add(InstNode.name(node), walk.names);
    end if;

    // A redeclare element replaces the inherited class with its name.
    if SCodeUtil.elementIsClass(def) and SCodeUtil.isElementRedeclare(def) then
      replacement := match InstNode.getClass(cls)
        case Class.EXPANDED_DERIVED(baseClass = replacement) then replacement;
        else cls;
      end match;

      for r in inheritedClasses(InstNode.name(node), InstNode.parent(node)) loop
        redeclared(r, replacement, walk);
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

    () := match def
      case SCode.CLASS()
        algorithm
          is_package := SCodeUtil.isPackage(def) and not allConstants;
          walkClassDef(def.classDef, cls, scope, is_package, walk);
        then
          ();

      else ();
    end match;
  end walkClass;

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
              SCodeUtil.foldStatementsExps(stmt, function walkExp(scope = cls), walk);
            end for;
          end for;

          for c in classDef.constraintLst loop
            SCode.CONSTRAINTS(constraints = exps) := c;
            List.fold(exps, function walkExp(scope = cls), walk);
          end for;

          () := match classDef.externalDecl
            case SOME(SCode.EXTERNALDECL(args = exps))
              algorithm
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
  protected
    Absyn.ArrayDim dims;
    Absyn.Path path;
    InstNode target;
  algorithm
    () := match element
      case SCode.COMPONENT()
        algorithm
          target := walkTypeSpec(element.typeSpec, scope, walk);
          walkMod(element.modifications, scope, walk, target);
          SCode.ATTR(arrayDims = dims) := element.attributes;
          walkDims(dims, scope, walk);
          walkConstrainingClass(element.prefixes, scope, walk);

          if isSome(element.condition) then
            walkExp(Util.getOption(element.condition), scope, walk);
          end if;
        then
          ();

      case SCode.EXTENDS()
        algorithm
          target := walkPath(element.baseClassPath, scope, walk);
          walkMod(element.modifications, scope, walk, target);
        then
          ();

      // An unqualified import is kept, so what it imports is needed.
      case SCode.IMPORT(imp = Absyn.Import.UNQUAL_IMPORT(path = path))
        algorithm
          walkPath(Absyn.Path.FULLYQUALIFIED(path), scope, walk);
        then
          ();

      else ();
    end match;
  end walkElement;

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
  algorithm
    () := match mod
      case SCode.MOD()
        algorithm
          for sm in mod.subModLst loop
            node := foundLocalName(sm.ident, target, walk, needType = hasSubMods(sm.mod));
            walkMod(sm.mod, scope, walk, if InstNode.isClass(node) then node else InstNode.EMPTY_NODE());
          end for;

          if isSome(mod.binding) then
            walkExp(Util.getOption(mod.binding), scope, walk);
          end if;
        then
          ();

      // The element of a redeclare is looked up where the modifier is written.
      // The target is what it replaces, found by the enclosing modifier.
      case SCode.REDECL()
        algorithm
          () := match mod.element
            case SCode.CLASS(classDef = cdef as SCode.DERIVED())
              algorithm
                redeclared(target, walkTypeSpec(cdef.typeSpec, scope, walk), walk);
                walkClassDef(cdef, scope, scope, false, walk);
              then
                ();

            case SCode.CLASS(classDef = cdef)
              algorithm
                walkClassDef(cdef, scope, scope, false, walk);
              then
                ();

            else
              algorithm
                walkElement(mod.element, scope, walk);
              then
                ();
          end match;
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
  algorithm
    SCodeUtil.foldEquationsExps(eq, function walkExp(scope = scope), walk);
  end walkEquation;

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
    AbsynUtil.traverseExp(exp, function walkExpNode(scope = scope), walk);
  end walkExp;

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
  algorithm
    try
      walkPath(AbsynUtil.crefToPathIgnoreSubs(cref), scope, walk);
    else
    end try;

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
    output InstNode node = InstNode.EMPTY_NODE() "What the whole name refers to, if found.";
  protected
    InstNode n;
  algorithm
    () := match path
      case Absyn.Path.FULLYQUALIFIED()
        algorithm
          node := walkPath(path.path, InstNode.topScope(scope), walk);
        then
          ();

      else
        algorithm
          if isBuiltinName(AbsynUtil.pathFirstIdent(path)) then
            return;
          end if;

          // Something that isn't found, e.g. Medium.f where only the redeclared
          // Medium has f, may be found by its name in another class.
          for id in AbsynUtil.pathToStringList(path) loop
            UnorderedSet.add(id, walk.names);
          end for;

          n := lookupFirstIdent(AbsynUtil.pathFirstIdent(path), scope, walk,
            needType = AbsynUtil.pathIsQual(path));

          if InstNode.isEmpty(n) then
            return;
          end if;

          foundNode(n, walk);

          if AbsynUtil.pathIsQual(path) then
            node := walkRest(AbsynUtil.pathRest(path), n, walk);
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
    output InstNode node = cls;
  protected
    Absyn.Path rest = path;
  algorithm
    while true loop
      lookedUpThrough(node, rest, walk);
      node := foundLocalName(AbsynUtil.pathFirstIdent(rest), node, walk,
        needType = AbsynUtil.pathIsQual(rest));

      if InstNode.isEmpty(node) or not AbsynUtil.pathIsQual(rest) then
        break;
      end if;

      rest := AbsynUtil.pathRest(rest);
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
  protected
    String key;
    list<Absyn.Path> rests;
    list<InstNode> replacements;
  algorithm
    if not (InstNode.isClass(cls) and SCodeUtil.isElementReplaceable(InstNode.definition(cls))) then
      return;
    end if;

    key := elementKey(InstNode.definition(cls));
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
  protected
    String key;
    list<InstNode> replacements;
    list<Absyn.Path> rests;
  algorithm
    if not (InstNode.isClass(replaced) and InstNode.isClass(replacement)) then
      return;
    end if;

    key := elementKey(InstNode.definition(replaced));
    replacements := UnorderedMap.getOrDefault(key, walk.replacements, {});

    if not List.isMemberOnTrue(replacement, replacements, InstNode.refEqual) then
      UnorderedMap.add(key, replacement :: replacements, walk.replacements);
      rests := UnorderedMap.getOrDefault(key, walk.rests, {});

      for rest in rests loop
        walkRest(rest, replacement, walk);
      end for;
    end if;
  end redeclared;

annotation(__OpenModelica_Interface="nf_frontend");
end NFUsedElements;

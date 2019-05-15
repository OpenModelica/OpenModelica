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

encapsulated package NFClassTree
  import NFInstNode.InstNode;
  import SCode;
  import NFType.Type;
  import Mutable;
  import NFModifier.Modifier;
  import Import = NFImport;
  import NFBuiltin;

protected
  import Array;
  import Error;
  import MetaModelica.Dangerous.*;
  import NFClass.Class;
  import NFComponent.Component;
  import Inst = NFInst;
  import List;
  import Lookup = NFLookup;
  import SCodeDump;
  import NFInstNode.InstNodeType;

public
  encapsulated package LookupTree
    uniontype Entry
      record CLASS
        Integer index;
      end CLASS;

      record COMPONENT
        Integer index;
      end COMPONENT;

      record IMPORT
        Integer index;
      end IMPORT;

      function index
        input Entry entry;
        output Integer index;
      algorithm
        index := match entry
          case CLASS() then entry.index;
          case COMPONENT() then entry.index;
          case IMPORT() then entry.index;
        end match;
      end index;

      function isEqual
        input Entry entry1;
        input Entry entry2;
        output Boolean isEqual = index(entry1) == index(entry2);
      end isEqual;

      function isImport
        input Entry entry;
        output Boolean isImport;
      algorithm
        isImport := match entry
          case IMPORT() then true;
          else false;
        end match;
      end isImport;
    end Entry;

    import BaseAvlTree;

    extends BaseAvlTree(redeclare type Key = String,
                        redeclare type Value = Entry);

    redeclare function extends keyStr
    algorithm
      outString := inKey;
    end keyStr;

    redeclare function extends valueStr
    algorithm
      outString := match inValue
        case Entry.CLASS() then "class " + String(inValue.index);
        case Entry.COMPONENT() then "comp " + String(inValue.index);
      end match;
    end valueStr;

    redeclare function extends keyCompare
    algorithm
      outResult := stringCompare(inKey1, inKey2);
    end keyCompare;

    annotation(__OpenModelica_Interface="util");
  end LookupTree;

  encapsulated package DuplicateTree
    import NFClassTree.LookupTree;
    import NFInstNode.InstNode;

    type EntryType = enumeration(DUPLICATE, REDECLARE, ENTRY);

    uniontype Entry
      record ENTRY
        LookupTree.Entry entry;
        Option<InstNode> node;
        list<Entry> children;
        EntryType ty;
      end ENTRY;
    end Entry;

    extends BaseAvlTree(redeclare type Key = String,
                        redeclare type Value = Entry);

    redeclare function extends keyStr
    algorithm
      outString := inKey;
    end keyStr;

    redeclare function extends valueStr
    algorithm
      outString := "";
    end valueStr;

    redeclare function extends keyCompare
    algorithm
      outResult := stringCompare(inKey1, inKey2);
    end keyCompare;

    function newRedeclare
      input LookupTree.Entry entry;
      output Entry redecl = ENTRY(entry, NONE(), {}, EntryType.REDECLARE);
    end newRedeclare;

    function newDuplicate
      input LookupTree.Entry kept;
      input LookupTree.Entry duplicate;
      output Entry entry = ENTRY(kept, NONE(), {newEntry(duplicate)}, EntryType.DUPLICATE);
    end newDuplicate;

    function newEntry
      input LookupTree.Entry lentry;
      output Entry entry = ENTRY(lentry, NONE(), {}, EntryType.ENTRY);
    end newEntry;

    function idExistsInEntry
      input LookupTree.Entry id;
      input Entry entry;
      output Boolean exists;
    algorithm
      exists := LookupTree.Entry.isEqual(id, entry.entry) or
                List.exist(entry.children, function idExistsInEntry(id = id));
    end idExistsInEntry;

    annotation(__OpenModelica_Interface="util");
  end DuplicateTree;

  constant ClassTree EMPTY = ClassTree.PARTIAL_TREE(LookupTree.EMPTY(),
      listArray({}), listArray({}), listArray({}), listArray({}), DuplicateTree.EMPTY());
  constant ClassTree EMPTY_FLAT = ClassTree.FLAT_TREE(LookupTree.EMPTY(),
      listArray({}), listArray({}), listArray({}), DuplicateTree.EMPTY());

  uniontype ClassTree
    record PARTIAL_TREE
      "A partial tree allows lookup of local classes and imported elements."
      LookupTree.Tree tree;
      array<InstNode> classes;
      array<InstNode> components;
      array<InstNode> exts;
      array<Import> imports;
      DuplicateTree.Tree duplicates;
    end PARTIAL_TREE;

    record EXPANDED_TREE
      "Like partial tree, but the lookup tree is populated with all named
       elements. The elements have not yet been added to the arrays though, so
       lookup is still restricted to local classes and imported elements."
      LookupTree.Tree tree;
      array<InstNode> classes;
      array<InstNode> components;
      array<InstNode> exts;
      array<Import> imports;
      DuplicateTree.Tree duplicates;
    end EXPANDED_TREE;

    record INSTANTIATED_TREE
      "Allows lookup of both local and inherited elements."
      LookupTree.Tree tree;
      array<Mutable<InstNode>> classes;
      array<Mutable<InstNode>> components;
      list<Integer> localComponents;
      array<InstNode> exts;
      array<Import> imports;
      DuplicateTree.Tree duplicates;
    end INSTANTIATED_TREE;

    record FLAT_TREE
      "A flattened version of an instantiated tree."
      LookupTree.Tree tree;
      array<InstNode> classes;
      array<InstNode> components;
      array<Import> imports;
      DuplicateTree.Tree duplicates;
    end FLAT_TREE;

    record EMPTY_TREE
    end EMPTY_TREE;

    function fromSCode
      "Creates a new class tree from a list of SCode elements."
      input list<SCode.Element> elements;
      input Boolean isClassExtends;
      input InstNode parent;
      output ClassTree tree;
    protected
      LookupTree.Tree ltree;
      LookupTree.Entry lentry;
      Integer clsc, compc, extc, i;
      array<InstNode> clss, comps, exts;
      Integer cls_idx = 0, ext_idx = 0, comp_idx = 0;
      DuplicateTree.Tree dups;
      list<Import> imps = {};
      array<Import> imps_arr;
      SourceInfo info;
    algorithm
      ltree := LookupTree.new();

      // Count the different types of elements.
      (clsc, compc, extc) := countElements(elements);

      // If the class is a class extends, reserve space for the extends.
      if isClassExtends then
        extc := extc + 1;
      end if;

      // Preallocate arrays for the elements. We can't do this for imports
      // though, since an import clause might import multiple elements.
      clss := arrayCreateNoInit(clsc, InstNode.EMPTY_NODE());
      comps := arrayCreateNoInit(compc + extc, InstNode.EMPTY_NODE());
      exts := arrayCreateNoInit(extc, InstNode.EMPTY_NODE());
      dups := DuplicateTree.new();
      // Make a temporary class tree so we can do lookup for error reporting.
      tree := PARTIAL_TREE(ltree, clss, comps, exts, listArray({}), dups);

      // If the class is a class extends, fill in the first extends with an
      // empty node so we don't have unassigned memory after this step.
      if isClassExtends then
        exts[1] := InstNode.EMPTY_NODE();
        comps[1] := InstNode.REF_NODE(1);
        ext_idx := ext_idx + 1;
        comp_idx := comp_idx + 1;
      end if;

      for e in elements loop
        () := match e
          // A class, add it to the class array and add an entry in the lookup tree.
          case SCode.CLASS()
            algorithm
              cls_idx := cls_idx + 1;
              arrayUpdateNoBoundsChecking(clss, cls_idx, InstNode.newClass(e, parent));
              lentry := LookupTree.Entry.CLASS(cls_idx);
              ltree := addLocalElement(e.name, lentry, tree, ltree);

              // If the class is an element redeclare, add an entry in the duplicate
              // tree so we can check later that it actually redeclares something.
              if SCode.isElementRedeclare(e) or SCode.isClassExtends(e) then
                dups := DuplicateTree.add(dups, e.name, DuplicateTree.newRedeclare(lentry));
              end if;
            then
              ();

          // A component, add it to the component array but don't add an entry
          // in the lookup tree. We need to preserve the components' order, but
          // won't know their actual indices until we've expanded the extends.
          // We don't really need to be able to look up components until after
          // that happens, so we add them to the lookup tree later instead.
          case SCode.COMPONENT()
            algorithm
              comp_idx := comp_idx + 1;
              arrayUpdateNoBoundsChecking(comps, comp_idx, InstNode.newComponent(e));
            then
              ();

          // An extends clause, add it to the list of extends, and also add a
          // reference in the component array so we can preserve the order of
          // components.
          case SCode.EXTENDS()
            algorithm
              ext_idx := ext_idx + 1;
              arrayUpdateNoBoundsChecking(exts, ext_idx, InstNode.newExtends(e, parent));
              comp_idx := comp_idx + 1;
              arrayUpdateNoBoundsChecking(comps, comp_idx, InstNode.REF_NODE(ext_idx));
            then
              ();

          // An unqualified import clause. We need to know which names are
          // imported by the clause, so it needs to be instantiated.
          case SCode.IMPORT(imp = Absyn.Import.UNQUAL_IMPORT(), info = info)
            algorithm
              imps := Import.instUnqualified(e.imp, parent, info, imps);
            then
              ();

          // A qualified import clause. Since the import itself gives the name
          // of the imported element we can delay resolving the path until we
          // need it (i.e. when the name is used). Doing so avoids some
          // dependency issues, like when a package is imported into one of it's
          // enclosing scopes.
          case SCode.IMPORT()
            algorithm
              imps := Import.UNRESOLVED_IMPORT(e.imp, parent, e.info) :: imps;
            then
              ();

          //else
          //  algorithm
          //    print(getInstanceName() + " skipping:\n" +
          //      SCodeDump.unparseElementStr(e) + "\n");
          //  then
          //    ();
        end match;
      end for;


      // Add all the imported names to the lookup tree.
      imps_arr := listArray(imps);
      i := 1;
      for e in imps loop
        ltree := addImport(e, i, ltree, imps_arr);
        i := i + 1;
      end for;

      tree := PARTIAL_TREE(ltree, clss, comps, exts, imps_arr, dups);
    end fromSCode;

    function fromEnumeration
      "Creates a class tree for an enumeration type."
      input list<SCode.Enum> literals "The SCode literals";
      input Type enumType "The type of the enumeration";
      input InstNode enumClass "The InstNode of the enumeration type";
      output ClassTree tree;
    protected
      array<InstNode> comps;
      Integer attr_count = 5;
      Integer i = 0;
      InstNode comp;
      LookupTree.Tree ltree;
      String name;
    algorithm
      comps := arrayCreateNoInit(listLength(literals) + attr_count, InstNode.EMPTY_NODE());
      ltree := NFBuiltin.ENUM_LOOKUP_TREE;

      arrayUpdateNoBoundsChecking(comps, 1, InstNode.fromComponent("quantity",
        Component.TYPE_ATTRIBUTE(Type.STRING(), Modifier.NOMOD()), enumClass));
      arrayUpdateNoBoundsChecking(comps, 2, InstNode.fromComponent("min",
        Component.TYPE_ATTRIBUTE(enumType, Modifier.NOMOD()), enumClass));
      arrayUpdateNoBoundsChecking(comps, 3, InstNode.fromComponent("max",
        Component.TYPE_ATTRIBUTE(enumType, Modifier.NOMOD()), enumClass));
      arrayUpdateNoBoundsChecking(comps, 4, InstNode.fromComponent("start",
        Component.TYPE_ATTRIBUTE(enumType, Modifier.NOMOD()), enumClass));
      arrayUpdateNoBoundsChecking(comps, 5, InstNode.fromComponent("fixed",
        Component.TYPE_ATTRIBUTE(Type.BOOLEAN(), Modifier.NOMOD()), enumClass));

      for l in literals loop
        // Make a new component node for the literal and add it to the lookup tree.
        name := l.literal;
        i := i + 1;
        comp := InstNode.fromComponent(name, Component.newEnum(enumType, name, i), enumClass);
        arrayUpdateNoBoundsChecking(comps, i + attr_count, comp);
        ltree := LookupTree.add(ltree, name, LookupTree.Entry.COMPONENT(i + attr_count),
          function addEnumConflict(literal = comp));
      end for;

      // Enumerations can't contain extends, so we can go directly to a flat tree here.
      tree := FLAT_TREE(ltree, listArray({}), comps, listArray({}), DuplicateTree.EMPTY());
    end fromEnumeration;

    function addElementsToFlatTree
      "Adds a list of class and/or component nodes as elements to a flat class
       tree, in the same order as they are listed. Name conflicts will result in
       an duplicate element error, and trying to add nodes that are not pure
       class or component nodes will result in undefined behaviour."
      input list<InstNode> elements;
      input output ClassTree tree;
    protected
      LookupTree.Tree ltree;
      array<InstNode> cls_arr, comp_arr;
      list<InstNode> cls_lst = {}, comp_lst = {};
      array<Import> imports;
      DuplicateTree.Tree duplicates;
      Integer cls_idx, comp_idx;
      LookupTree.Entry lentry;
    algorithm
      FLAT_TREE(ltree, cls_arr, comp_arr, imports, duplicates) := tree;
      cls_idx := arrayLength(cls_arr);
      comp_idx := arrayLength(comp_arr);

      for e in elements loop
        if InstNode.isComponent(e) then
          comp_idx := comp_idx + 1;
          lentry := LookupTree.Entry.COMPONENT(comp_idx);
          comp_lst := e :: comp_lst;
        else
          cls_idx := cls_idx + 1;
          lentry := LookupTree.Entry.CLASS(cls_idx);
          cls_lst := e :: cls_lst;
        end if;

        ltree := addLocalElement(InstNode.name(e), lentry, tree, ltree);
      end for;

      cls_arr := Array.appendList(cls_arr, listReverseInPlace(cls_lst));
      comp_arr := Array.appendList(comp_arr, listReverseInPlace(comp_lst));
      tree := FLAT_TREE(ltree, cls_arr, comp_arr, imports, duplicates);
    end addElementsToFlatTree;

    function expand
      "This function adds all local and inherited class and component names to
       the lookup tree. Note that only their names are added, the elements
       themselves are added to their respective arrays by the instantiation
       function below."
      input output ClassTree tree;
    protected
      LookupTree.Tree ltree;
      LookupTree.Entry lentry;
      array<InstNode> exts, clss, comps;
      array<Import> imps;
      list<tuple<Integer, Integer>> ext_idxs = {};
      Integer ccount, cls_idx, comp_idx = 1;
      DuplicateTree.Tree dups;
      Mutable<DuplicateTree.Tree> dups_ptr;
    algorithm
      PARTIAL_TREE(ltree, clss, comps, exts, imps, dups) := tree;
      cls_idx := arrayLength(clss) + 1;

      // Since we now know the names of both local and inherited components we
      // can add them to the lookup tree. First we add the local components'
      // names, to be able to catch duplicate local elements easier.
      for c in comps loop
        () := match c
          // A component. Add its name to the lookup tree.
          case InstNode.COMPONENT_NODE()
            algorithm
              lentry := LookupTree.Entry.COMPONENT(comp_idx);
              ltree := addLocalElement(InstNode.name(c), lentry, tree, ltree);

              // If the component is an element redeclare, add an entry in the duplicate
              // tree so we can check later that it actually redeclares something.
              if InstNode.isRedeclare(c) then
                dups := DuplicateTree.add(dups, c.name, DuplicateTree.newRedeclare(lentry));
              end if;

              comp_idx := comp_idx + 1;
            then
              ();

          // An extends node. Save the index so we know where to start adding
          // components later, and increment the index with the number of
          // components it contains.
          case InstNode.REF_NODE()
            algorithm
              ext_idxs := (cls_idx - 1, comp_idx - 1) :: ext_idxs;
              (cls_idx, comp_idx) := countInheritedElements(exts[c.index], cls_idx, comp_idx);
            then
              ();

          else
            algorithm
              Error.assertion(false, getInstanceName() + " got invalid component", sourceInfo());
            then
              fail();
        end match;
      end for;

      // Checking whether inherited duplicate elements are identical is hard to
      // do correctly at this point. So we just detect them and store their
      // indices in the class tree for now, and check them for identicalness
      // later on instead.
      dups_ptr := Mutable.create(dups);

      // Add the names of inherited components and classes to the lookup tree.
      if not listEmpty(ext_idxs) then
        // Use the component indices we saved earlier to add the required
        // elements from the extends nodes to the lookup tree.
        ext_idxs := listReverseInPlace(ext_idxs);

        for ext in exts loop
          (cls_idx, comp_idx) :: ext_idxs := ext_idxs;
          ltree := expandExtends(ext, ltree, cls_idx, comp_idx, dups_ptr);
        end for;
      end if;

      tree := EXPANDED_TREE(ltree, clss, comps, exts, imps, Mutable.access(dups_ptr));
    end expand;

    function instantiate
      "This function instantiates an expanded tree. clsNode is the class to
       be instantiated, while instance is the instance the clsNode belongs to.
       instance is usually the component which has the class as its type. In
       some cases the class itself is the instance, like for the top-level
       model that's being instantiated or packages used for lookup. Because the
       actual instance of clsNode will then be the cloned clsNode created by
       this function it's not possible to send in the correct instance in that
       case, so setting the instance to an empty node is interpreted by this
       function to mean that the instance should be set to the cloned clsNode."
      input output InstNode clsNode;
      input output InstNode instance = InstNode.EMPTY_NODE();
      input InstNode scope = InstNode.EMPTY_NODE();
            output Integer classCount = 0;
            output Integer compCount = 0;
    protected
      Class cls;
      ClassTree tree, ext_tree;
      LookupTree.Tree ltree;
      array<InstNode> exts, old_clss, old_comps;
      array<Import> imps;
      array<Mutable<InstNode>> clss, comps, ext_clss;
      list<Integer> local_comps = {};
      Integer cls_idx = 1, comp_idx = 1, cls_count, comp_count;
      InstNode node, parent_scope, inner_node, inst_scope;
      DuplicateTree.Tree dups;
      Component comp;
      SCode.Element ext_def;
    algorithm
      // TODO: If we don't have any extends we could probably generate a flat
      // tree directly and skip a lot of this.

      // Clone the class node by replacing the class in the node with itself.
      cls := InstNode.getClass(clsNode);
      clsNode := InstNode.replaceClass(cls, clsNode);

      () := match cls
        case Class.EXPANDED_CLASS(elements = INSTANTIATED_TREE())
          then ();

        case Class.EXPANDED_CLASS()
          algorithm
            // If the instance is an empty node, use the cloned clsNode as the instance.
            if InstNode.isEmpty(instance) then
              instance := clsNode;
              parent_scope := InstNode.parent(clsNode);
            else
              parent_scope := instance;
              inst_scope := scope;
            end if;

            inst_scope := if InstNode.isEmpty(scope) then instance else scope;

            // Fetch the elements from the class tree.
            EXPANDED_TREE(ltree, old_clss, old_comps, exts, imps, dups) := cls.elements;

            // Count the number of local classes and components we have.
            classCount := arrayLength(old_clss);
            // The component array contains placeholders for extends, so the length of the
            // extends array needs to be subtracted here to get the number of components.
            compCount := arrayLength(old_comps) - arrayLength(exts);

            // Make a new extends array, and recursively instantiate the extends nodes.
            exts := arrayCopy(exts);
            for i in 1:arrayLength(exts) loop
              // Update the parent of the extends to be the new instance.
              node := exts[i];
              InstNodeType.BASE_CLASS(definition = ext_def) := InstNode.nodeType(node);
              node := InstNode.setNodeType(InstNodeType.BASE_CLASS(instance, ext_def), node);
              // Instantiate the class tree of the extends.
              (node, _, cls_count, comp_count) := instantiate(node, InstNode.EMPTY_NODE(), inst_scope);
              exts[i] := node;

              // Add the inherited elements to the class/component counts.
              classCount := cls_count + classCount;
              compCount := comp_count + compCount;
            end for;

            // Create new arrays that can hold both local and inherited elements.
            comps := arrayCreateNoInit(compCount, /*dummy*/Mutable.create(InstNode.EMPTY_NODE()));
            clss := arrayCreateNoInit(classCount, /*dummy*/Mutable.create(InstNode.EMPTY_NODE()));

            // Copy the local classes into the new class array, and set the
            // class we're instantiating to be their parent.
            for c in old_clss loop
              if not InstNode.isOperator(c) then
                c := InstNode.clone(c);
              end if;

              c := InstNode.setParent(clsNode, c);

              // If the class is outer, check that it's valid and link it with
              // the corresponding inner class.
              if InstNode.isOuter(c) then
                checkOuterClass(c);
                c := linkInnerOuter(c, parent_scope);
              end if;

              arrayUpdateNoBoundsChecking(clss, cls_idx, Mutable.create(c));
              cls_idx := cls_idx + 1;
            end for;

            // Copy inherited classes into the new class array. Note that inherited
            // classes are just inserted after the local ones, and not where the
            // extends say they should go. The order shouldn't matter for classes,
            // and otherwise we wouldn't be able to reuse the lookup tree.
            for ext in exts loop
              () := match Class.classTree(InstNode.getClass(ext))
                case INSTANTIATED_TREE(classes = ext_clss)
                  algorithm
                    cls_count := arrayLength(ext_clss);

                    if cls_count > 0 then
                      Array.copyRange(ext_clss, clss, 1, cls_count, cls_idx);
                      cls_idx := cls_idx + cls_count;
                    end if;
                  then
                    ();

                else ();
              end match;
            end for;

            // Copy both local and inherited components into the new array.
            for c in old_comps loop
              () := match c
                case InstNode.COMPONENT_NODE()
                  algorithm
                    // Set the component's parent and create a unique instance for it.
                    node := InstNode.setParent(instance, c);
                    comp := InstNode.component(node);
                    node := InstNode.replaceComponent(comp, node);

                    // If the component is outer, link it with the corresponding
                    // inner component.
                    if Component.isOuter(comp) then
                      node := linkInnerOuter(node, inst_scope);
                    end if;

                    // Add the node to the component array.
                    arrayUpdateNoBoundsChecking(comps, comp_idx, Mutable.create(node));
                    local_comps := comp_idx :: local_comps;
                    comp_idx := comp_idx + 1;
                  then
                    ();

                case InstNode.REF_NODE()
                  algorithm
                    comp_idx := instExtendsComps(exts[c.index], comps, comp_idx);
                  then
                    ();
              end match;
            end for;

            // Sanity check.
            if comp_idx <> compCount + 1 then
              Error.assertion(false, getInstanceName() + " miscounted components in " +
                InstNode.name(clsNode), sourceInfo());
            end if;

            if cls_idx <> classCount + 1 then
              Error.assertion(false, getInstanceName() + " miscounted classes in " +
                InstNode.name(clsNode), sourceInfo());
            end if;

            // Create a new class tree and update the class in the node.
            cls.elements := INSTANTIATED_TREE(ltree, clss, comps, local_comps, exts, imps, dups);
          then
            ();

        case Class.EXPANDED_DERIVED(baseClass = node)
          algorithm
            node := InstNode.setNodeType(
              InstNodeType.BASE_CLASS(clsNode, InstNode.definition(node)), node);
            (node, instance, classCount, compCount) := instantiate(node, instance, scope);
            cls.baseClass := node;
          then
            ();

        case Class.PARTIAL_BUILTIN(elements = tree as FLAT_TREE(components = old_comps))
          algorithm
            instance := if InstNode.isEmpty(instance) then clsNode else instance;
            old_comps := arrayCopy(old_comps);

            for i in 1:arrayLength(old_comps) loop
              node := old_comps[i];
              node := InstNode.setParent(instance, node);
              old_comps[i] := InstNode.replaceComponent(InstNode.component(node), node);
            end for;

            tree.components := old_comps;
            cls.elements := tree;
            compCount := arrayLength(old_comps);
          then
            ();

        case Class.PARTIAL_BUILTIN() then ();

        else
          algorithm
            Error.assertion(false, getInstanceName() + " got invalid class", sourceInfo());
          then
            fail();

      end match;

      InstNode.updateClass(cls, clsNode);
    end instantiate;

    function fromRecordConstructor
      input list<InstNode> inputs;
      input list<InstNode> locals;
      input InstNode out;
      output ClassTree tree = EMPTY;
    protected
      LookupTree.Tree ltree = LookupTree.new();
      Integer i = 1;
      array<InstNode> comps;
    algorithm
      comps := arrayCreateNoInit(listLength(inputs) + listLength(locals) + 1, InstNode.EMPTY_NODE());

      for ci in inputs loop
        comps[i] := ci;
        ltree := addLocalElement(InstNode.name(ci), LookupTree.Entry.COMPONENT(i), tree, ltree);
        i := i + 1;
      end for;

      for cl in locals loop
        comps[i] := cl;
        ltree := addLocalElement(InstNode.name(cl), LookupTree.Entry.COMPONENT(i), tree, ltree);
        i := i + 1;
      end for;

      comps[i] := out;
      ltree := addLocalElement(InstNode.name(out), LookupTree.Entry.COMPONENT(i), tree, ltree);

      tree := FLAT_TREE(ltree, listArray({}), comps, listArray({}), DuplicateTree.new());
    end fromRecordConstructor;

    function clone
      input ClassTree tree;
      output ClassTree outTree;
    algorithm
      outTree := match tree
        local
          array<InstNode> clss;

        case EXPANDED_TREE()
          algorithm
            clss := arrayCopy(tree.classes);
            clss := Array.mapNoCopy(clss, InstNode.clone);
          then
            EXPANDED_TREE(tree.tree, clss, tree.components, tree.exts, tree.imports, tree.duplicates);

        else tree;
      end match;
    end clone;

    function mapRedeclareChains
      input ClassTree tree;
      input FuncT func;

      partial function FuncT
        input list<Mutable<InstNode>> chain;
      end FuncT;
    algorithm
      () := match tree
        case INSTANTIATED_TREE() guard not DuplicateTree.isEmpty(tree.duplicates)
          algorithm
            DuplicateTree.map(tree.duplicates,
              function mapRedeclareChain(func = func, tree = tree));
          then
            ();

        else ();
      end match;
    end mapRedeclareChains;

    function replaceDuplicates
      "This function replaces all duplicate elements with the element that is
       kept, such that lookup in the extends nodes will find the correct node."
      input output ClassTree tree;
    algorithm
      () := match tree
        case INSTANTIATED_TREE() guard not DuplicateTree.isEmpty(tree.duplicates)
          algorithm
            tree.duplicates := DuplicateTree.map(tree.duplicates,
              function replaceDuplicates2(tree = tree));
          then
            ();

        else ();
      end match;
    end replaceDuplicates;

    function appendComponentsToInstTree
      "Appens a list of local components to an instantiated class tree."
      input list<Mutable<InstNode>> components;
      input output ClassTree tree;
    algorithm
      if listEmpty(components) then
        return;
      else
        () := match tree
          local
            Integer comp_idx;
            list<Integer> local_comps;

          case INSTANTIATED_TREE()
            algorithm
              comp_idx := arrayLength(tree.components);
              tree.components := Array.appendList(tree.components, components);
              local_comps := tree.localComponents;

              for i in comp_idx+1:comp_idx+listLength(components) loop
                local_comps := i :: local_comps;
              end for;

              tree.localComponents := local_comps;
            then
              ();
        end match;
      end if;
    end appendComponentsToInstTree;

    function flatten
      input output ClassTree tree;
    algorithm
      tree := match tree
        local
          array<InstNode> clss, comps;
          Integer clsc, compc;
          list<Integer> dup_cls, dup_comp;

        case INSTANTIATED_TREE()
          algorithm
            (dup_cls, dup_comp) := enumerateDuplicates(tree.duplicates);

            clsc := arrayLength(tree.classes);
            compc := arrayLength(tree.components);
            clss := arrayCreateNoInit(clsc, InstNode.EMPTY_NODE());
            comps := arrayCreateNoInit(compc, InstNode.EMPTY_NODE());

            flatten2(tree.classes, clss, dup_cls);
            flatten2(tree.components, comps, dup_comp);
          then
            FLAT_TREE(tree.tree, clss, comps, tree.imports, tree.duplicates);

        else tree;
      end match;
    end flatten;

    function flatten2
      input array<Mutable<InstNode>> elements;
      input array<InstNode> flatElements;
      input list<Integer> duplicates;
    algorithm
      for i in 1:arrayLength(elements) loop
        arrayUpdateNoBoundsChecking(flatElements, i,
          Mutable.access(arrayGetNoBoundsChecking(elements, i)));
      end for;

      for i in duplicates loop
        arrayUpdateNoBoundsChecking(flatElements, i, InstNode.EMPTY_NODE());
      end for;
    end flatten2;

    function lookupElement
      "Returns the class or component with the given name in the class tree."
      input String name;
      input ClassTree tree;
      output InstNode element;
      output Boolean isImport;
    protected
      LookupTree.Entry entry;
    algorithm
      entry := LookupTree.get(lookupTree(tree), name);
      (element, isImport) := resolveEntry(entry, tree);
    end lookupElement;

    function lookupElementPtr
      input String name;
      input ClassTree tree;
      output Mutable<InstNode> element;
    protected
      LookupTree.Entry entry;
    algorithm
      entry := LookupTree.get(lookupTree(tree), name);
      element := resolveEntryPtr(entry, tree);
    end lookupElementPtr;

    function lookupElementsPtr
      input String name;
      input ClassTree tree;
      output list<Mutable<InstNode>> elements;
    protected
      DuplicateTree.Entry dup_entry;
    algorithm
      try
        dup_entry := DuplicateTree.get(getDuplicates(tree), name);
        elements := resolveDuplicateEntriesPtr(dup_entry, tree);
      else
        elements := {lookupElementPtr(name, tree)};
      end try;
    end lookupElementsPtr;

    function lookupComponentIndex
      input String name;
      input ClassTree tree;
      output Integer index;
    algorithm
      LookupTree.Entry.COMPONENT(index = index) :=
        LookupTree.get(lookupTree(tree), name);
    end lookupComponentIndex;

    function nthComponent
      input Integer index;
      input ClassTree tree;
      output InstNode component;
    algorithm
      component := match tree
        case PARTIAL_TREE() then arrayGet(tree.components, index);
        case EXPANDED_TREE() then arrayGet(tree.components, index);
        case INSTANTIATED_TREE() then Mutable.access(arrayGet(tree.components, index));
        case FLAT_TREE() then arrayGet(tree.components, index);
      end match;
    end nthComponent;

    function mapClasses
      input ClassTree tree;
      input FuncT func;

      partial function FuncT
        input output InstNode extendsNode;
      end FuncT;
    protected
      array<InstNode> clss = getClasses(tree);
    algorithm
      for i in 1:arrayLength(clss) loop
        arrayUpdateNoBoundsChecking(clss, i,
          func(arrayGetNoBoundsChecking(clss, i)));
      end for;
    end mapClasses;

    function foldClasses<ArgT>
      input ClassTree tree;
      input FuncT func;
      input output ArgT arg;

      partial function FuncT
        input InstNode clsNode;
        input output ArgT arg;
      end FuncT;
    protected
      array<InstNode> clss = getClasses(tree);
    algorithm
      for cls in clss loop
        arg := func(cls, arg);
      end for;
    end foldClasses;

    function applyExtends
      input ClassTree tree;
      input FuncT func;
      partial function FuncT
        input InstNode extendsNode;
      end FuncT;
    protected
      array<InstNode> exts = getExtends(tree);
    algorithm
      for ext in exts loop
        func(ext);
      end for;
    end applyExtends;

    function mapExtends
      "Applies a function to each extends node in the class tree, and updates
       the extends array with the returned nodes."
      input ClassTree tree;
      input FuncT func;

      partial function FuncT
        input output InstNode extendsNode;
      end FuncT;
    protected
      array<InstNode> exts = getExtends(tree);
    algorithm
      for i in 1:arrayLength(exts) loop
        arrayUpdateNoBoundsChecking(exts, i,
          func(arrayGetNoBoundsChecking(exts, i)));
      end for;
    end mapExtends;

    function foldExtends<ArgT>
      input ClassTree tree;
      input FuncT func;
      input output ArgT arg;

      partial function FuncT
        input InstNode extendsNode;
        input output ArgT arg;
      end FuncT;
    protected
      array<InstNode> exts = getExtends(tree);
    algorithm
      for ext in exts loop
        arg := func(ext, arg);
      end for;
    end foldExtends;

    function mapFoldExtends<ArgT>
      "Applies a mutating function to each extends node in the class tree.
       A given argument is also folded and returned."
      input ClassTree tree;
      input FuncT func;
      input output ArgT arg;

      partial function FuncT
        input output InstNode ext;
        input output ArgT arg;
      end FuncT;
    protected
      array<InstNode> exts = getExtends(tree);
      InstNode ext;
    algorithm
      for i in 1:arrayLength(exts) loop
        (ext, arg) := func(arrayGetNoBoundsChecking(exts, i), arg);
        arrayUpdateNoBoundsChecking(exts, i, ext);
      end for;
    end mapFoldExtends;

    function applyLocalComponents
      input ClassTree tree;
      input FuncT func;

      partial function FuncT
        input InstNode component;
      end FuncT;
    algorithm
      () := match tree
        case INSTANTIATED_TREE()
          algorithm
            for i in tree.localComponents loop
              func(Mutable.access(arrayGetNoBoundsChecking(tree.components, i)));
            end for;
          then
            ();

        case PARTIAL_TREE()
          algorithm
            for c in tree.components loop
              func(c);
            end for;
          then
            ();

        case EXPANDED_TREE()
          algorithm
            for c in tree.components loop
              func(c);
            end for;
          then
            ();
      end match;
    end applyLocalComponents;

    function applyComponents
      input ClassTree tree;
      input FuncT func;

      partial function FuncT
        input InstNode component;
      end FuncT;
    algorithm
      () := match tree
        case PARTIAL_TREE()
          algorithm
            for c in tree.components loop
              func(c);
            end for;
          then
            ();

        case EXPANDED_TREE()
          algorithm
            for c in tree.components loop
              func(c);
            end for;
          then
            ();

        case INSTANTIATED_TREE()
          algorithm
            for c in tree.components loop
              func(Mutable.access(c));
            end for;
          then
            ();

        case FLAT_TREE()
          algorithm
            for c in tree.components loop
              func(c);
            end for;
          then
            ();

        else ();
      end match;
    end applyComponents;

    function classCount
      input ClassTree tree;
      output Integer count;
    algorithm
      count := match tree
        case PARTIAL_TREE() then arrayLength(tree.classes);
        case EXPANDED_TREE() then arrayLength(tree.classes);
        case INSTANTIATED_TREE() then arrayLength(tree.classes);
        case FLAT_TREE() then arrayLength(tree.classes);
      end match;
    end classCount;

    function componentCount
      input ClassTree tree;
      output Integer count;
    algorithm
      count := match tree
        case PARTIAL_TREE() then arrayLength(tree.components) - arrayLength(tree.exts);
        case EXPANDED_TREE() then arrayLength(tree.components) - arrayLength(tree.exts);
        case INSTANTIATED_TREE() then arrayLength(tree.components);
        case FLAT_TREE() then arrayLength(tree.components);
      end match;
    end componentCount;

    function extendsCount
      input ClassTree tree;
      output Integer count = arrayLength(getExtends(tree));
    end extendsCount;

    function checkDuplicates
      input ClassTree tree;
    algorithm
      () := match tree
        case INSTANTIATED_TREE() guard not DuplicateTree.isEmpty(tree.duplicates)
          algorithm
            DuplicateTree.fold(tree.duplicates, checkDuplicates2, tree);
          then
            ();

        else ();
      end match;
    end checkDuplicates;

    function checkDuplicates2
      input String name;
      input DuplicateTree.Entry entry;
      input output ClassTree tree;
    protected
      InstNode kept, dup;
    algorithm
      SOME(kept) := entry.node;

      () := match entry.ty
        case DuplicateTree.EntryType.REDECLARE
          algorithm

          then
            ();

        else
          algorithm
            for c in entry.children loop
              SOME(dup) := c.node;
              InstNode.checkIdentical(kept, dup);
            end for;
          then
            ();
      end match;
    end checkDuplicates2;

    function isIdentical
      input ClassTree tree1;
      input ClassTree tree2;
      output Boolean identical;
    algorithm
      identical := true;
    end isIdentical;

    function getRedeclaredNode
      input String name;
      input ClassTree tree;
      output InstNode node;
    protected
      DuplicateTree.Entry entry;
    algorithm
      try
        entry := DuplicateTree.get(getDuplicates(tree), name);
        entry := listHead(entry.children);

        if isSome(entry.node) then
          SOME(node) := entry.node;
        else
          node := resolveEntry(entry.entry, tree);
        end if;
      else
        Error.assertion(false, getInstanceName() + " failed on " + name, sourceInfo());
      end try;
    end getRedeclaredNode;

    function setClassExtends
      input InstNode extNode;
      input output ClassTree tree;
    algorithm
      arrayUpdate(getExtends(tree), 1, extNode);
    end setClassExtends;

    function enumerateComponents
      input ClassTree tree;
      output list<InstNode> components;
    protected
      LookupTree.Tree ltree;
      array<InstNode> comps;
    algorithm
      FLAT_TREE(tree = ltree, components = comps) := tree;
      components := LookupTree.fold(ltree, function enumerateComponents2(comps = comps), {});
    end enumerateComponents;

    function enumerateComponents2
      input String name;
      input LookupTree.Entry entry;
      input array<InstNode> comps;
      input output list<InstNode> components;
    algorithm
      () := match entry
        case LookupTree.Entry.COMPONENT()
          algorithm
            components := comps[entry.index] :: components;
          then
            ();

        else ();
      end match;
    end enumerateComponents2;

    function getClasses
      input ClassTree tree;
      output array<InstNode> clss;
    algorithm
      clss := match tree
        case PARTIAL_TREE() then tree.classes;
        case EXPANDED_TREE() then tree.classes;
        case FLAT_TREE() then tree.classes;
      end match;
    end getClasses;

    function getExtends
      input ClassTree tree;
      output array<InstNode> exts;
    algorithm
      exts := match tree
        case PARTIAL_TREE() then tree.exts;
        case EXPANDED_TREE() then tree.exts;
        case INSTANTIATED_TREE() then tree.exts;
      end match;
    end getExtends;

    function getComponents
      input ClassTree tree;
      output array<InstNode> comps;
    algorithm
      comps := match tree
        case PARTIAL_TREE() then tree.components;
        case EXPANDED_TREE() then tree.components;
        case FLAT_TREE() then tree.components;
      end match;
    end getComponents;

    function isEmptyTree
      input ClassTree tree;
      output Boolean isEmpty;
    algorithm
      isEmpty := match tree
        case EMPTY_TREE() then true;
        else false;
      end match;
    end isEmptyTree;

  protected

    function instExtendsComps
      input InstNode extNode;
      input array<Mutable<InstNode>> comps;
      input output Integer index "The first free index in comps";
    protected
      array<Mutable<InstNode>> ext_comps_ptrs;
      array<InstNode> ext_comps;
      Integer comp_count;
      InstNode ext_comp;
    algorithm
      () := match Class.classTree(InstNode.getClass(extNode))
        case INSTANTIATED_TREE(components = ext_comps_ptrs)
          algorithm
            comp_count := arrayLength(ext_comps_ptrs);

            if comp_count > 0 then
              Array.copyRange(ext_comps_ptrs, comps, 1, comp_count, index);
              index := index + comp_count;
            end if;
          then
            ();

        case FLAT_TREE(components = ext_comps)
          algorithm
            comp_count := arrayLength(ext_comps);

            if comp_count > 0 then
              for i in index:index+comp_count-1 loop
                arrayUpdate(comps, i, Mutable.create(ext_comps[i]));
              end for;

              index := index + comp_count;
            end if;
          then
            ();

        else ();
      end match;
    end instExtendsComps;

    function getDuplicates
      input ClassTree tree;
      output DuplicateTree.Tree duplicates;
    algorithm
      duplicates := match tree
        case PARTIAL_TREE() then tree.duplicates;
        case EXPANDED_TREE() then tree.duplicates;
        case INSTANTIATED_TREE() then tree.duplicates;
        case FLAT_TREE() then tree.duplicates;
      end match;
    end getDuplicates;

    function lookupTree
      input ClassTree ctree;
      output LookupTree.Tree ltree;
    algorithm
      ltree := match ctree
        case PARTIAL_TREE() then ctree.tree;
        case EXPANDED_TREE() then ctree.tree;
        case INSTANTIATED_TREE() then ctree.tree;
        case FLAT_TREE() then ctree.tree;
      end match;
    end lookupTree;

    function addLocalElement
      input String name;
      input LookupTree.Entry entry;
      input ClassTree classTree;
      input output LookupTree.Tree tree;
    algorithm
      tree := LookupTree.add(tree, name, entry,
        function addLocalElementConflict(classTree = classTree));
    end addLocalElement;

    function addLocalElementConflict
      input LookupTree.Entry newEntry;
      input LookupTree.Entry oldEntry;
      input String name;
      input ClassTree classTree;
      output LookupTree.Entry entry;
    protected
      InstNode n1, n2;
    algorithm
      entry := match (newEntry, oldEntry)
        // Local elements overwrite imported elements with same name.
        case (_, LookupTree.Entry.IMPORT()) then newEntry;
        // Otherwise we have two local elements with the same name, which is an error.
        else
          algorithm
            n1 := findLocalConflictElement(newEntry, classTree);
            n2 := findLocalConflictElement(oldEntry, classTree);

            Error.addMultiSourceMessage(Error.DOUBLE_DECLARATION_OF_ELEMENTS,
              {name}, {InstNode.info(n2), InstNode.info(n1)});
          then
            fail();
      end match;
    end addLocalElementConflict;

    function findLocalConflictElement
      "Helper function to addLocalElementConflict. Looks up an entry in a
       partial class tree."
      input LookupTree.Entry entry;
      input ClassTree classTree;
      output InstNode node;
    algorithm
      node := match entry
        local
          array<InstNode> comps, exts;
          Integer i;

        // For classes we can just use the normal resolveClass function.
        case LookupTree.Entry.CLASS() then resolveClass(entry.index, classTree);

        // Components are more complicated, since they are given indices based
        // on where they will end up once inherited elements have been inserted
        // into the component array. We therefore just count components until we
        // get to the given index. Not very efficient, but it doesn't really
        // matter at this point since we're just going to show an error and fail.
        case LookupTree.Entry.COMPONENT()
          algorithm
            i := 0;
            PARTIAL_TREE(components = comps, exts = exts) := classTree;

            for c in comps loop
              i := match c
                case InstNode.COMPONENT_NODE() then i + 1;
                case InstNode.REF_NODE()
                  algorithm
                    (_, i) := countInheritedElements(exts[c.index], 0, i);
                  then
                    i;
              end match;

              if i == entry.index then
                node := c;
                break;
              end if;
            end for;

            // Make extra sure that we actually found the component.
            Error.assertion(i == entry.index, getInstanceName() + " got invalid entry index", sourceInfo());
          then
            node;

        else
          algorithm
            Error.assertion(false, getInstanceName() + " got invalid entry", sourceInfo());
          then
            fail();

      end match;
    end findLocalConflictElement;

    function addEnumConflict
      "Conflict handler for fromEnumeration."
      input LookupTree.Entry newEntry;
      input LookupTree.Entry oldEntry;
      input String name;
      input InstNode literal;
      output LookupTree.Entry entry;
    algorithm
      Error.addSourceMessage(Error.DOUBLE_DECLARATION_OF_ELEMENTS,
        {InstNode.name(literal)}, InstNode.info(literal));
      fail();
    end addEnumConflict;

    function addImport
      input Import imp;
      input Integer index;
      input output LookupTree.Tree tree;
      input array<Import> imports;
    algorithm
      tree := LookupTree.add(tree, Import.name(imp), LookupTree.Entry.IMPORT(index),
        function addImportConflict(imports = imports));
    end addImport;

    function addImportConflict
      input LookupTree.Entry newEntry;
      input LookupTree.Entry oldEntry;
      input String name;
      input array<Import> imports;
      output LookupTree.Entry entry;
    algorithm
      entry := match (newEntry, oldEntry)
        local
          Import imp1, imp2;

        case (LookupTree.Entry.IMPORT(), LookupTree.Entry.IMPORT())
          algorithm
            imp1 := imports[newEntry.index];
            imp2 := imports[oldEntry.index];

            // Check what kind of imports we have. In case of an error we replace the import
            // with the error information, and only print the error if the name is looked up.
            entry := match (imp1, imp2)
              // Two qualified imports of the same name gives an error.
              case (Import.UNRESOLVED_IMPORT(), Import.UNRESOLVED_IMPORT())
                algorithm
                  arrayUpdate(imports, oldEntry.index, Import.CONFLICTING_IMPORT(imp1, imp2));
                then
                  oldEntry;

              // A name imported from several unqualified imports gives an error.
              case (Import.RESOLVED_IMPORT(), Import.RESOLVED_IMPORT())
                algorithm
                  arrayUpdate(imports, oldEntry.index, Import.CONFLICTING_IMPORT(imp1, imp2));
                then
                  oldEntry;

              // Qualified import overwrites an unqualified.
              case (Import.UNRESOLVED_IMPORT(), _) then newEntry;
              // oldEntry is either qualified or a delayed error, keep it.
              else oldEntry;
            end match;
          then
            entry;

        // Other elements overwrite an imported name.
        else oldEntry;
      end match;
    end addImportConflict;

    function addDuplicate
      "Adds an entry to the duplicates tree."
      input String name;
      input LookupTree.Entry duplicateEntry;
      input LookupTree.Entry keptEntry;
      input output Mutable<DuplicateTree.Tree> duplicates;
    algorithm
      Mutable.update(duplicates,
        DuplicateTree.add(Mutable.access(duplicates), name,
          DuplicateTree.newDuplicate(keptEntry, duplicateEntry), addDuplicateConflict));
    end addDuplicate;

    function addDuplicateConflict
      input DuplicateTree.Entry newEntry;
      input DuplicateTree.Entry oldEntry;
      input String name;
      output DuplicateTree.Entry entry;
    algorithm
      // The previously kept entry should be either kept or dup, since it's the
      // one found during lookup. So we can ignore it here.
      entry := DuplicateTree.ENTRY(newEntry.entry, NONE(),
        listHead(newEntry.children) :: oldEntry.children, DuplicateTree.EntryType.DUPLICATE);
    end addDuplicateConflict;

    function resolveEntry
      "Resolves a lookup tree entry to an inst node."
      input LookupTree.Entry entry;
      input ClassTree tree;
      output InstNode element;
      output Boolean isImport;
    algorithm
      (element, isImport) := match entry
        case LookupTree.Entry.CLASS() then (resolveClass(entry.index, tree), false);
        case LookupTree.Entry.COMPONENT() then (resolveComponent(entry.index, tree), false);
        case LookupTree.Entry.IMPORT() then (resolveImport(entry.index, tree), true);
      end match;
    end resolveEntry;

    function resolveEntryPtr
      input LookupTree.Entry entry;
      input ClassTree tree;
      output Mutable<InstNode> element;
    protected
      array<Mutable<InstNode>> elems;
    algorithm
      element := match entry
        case LookupTree.Entry.CLASS()
          algorithm
            INSTANTIATED_TREE(classes = elems) := tree;
          then
            arrayGet(elems, entry.index);

        case LookupTree.Entry.COMPONENT()
          algorithm
            INSTANTIATED_TREE(components = elems) := tree;
          then
            arrayGet(elems, entry.index);
      end match;
    end resolveEntryPtr;

    function resolveDuplicateEntriesPtr
      input DuplicateTree.Entry entry;
      input ClassTree tree;
      input output list<Mutable<InstNode>> elements = {};
    protected
      Mutable<InstNode> node_ptr;
    algorithm
      node_ptr := resolveEntryPtr(entry.entry, tree);
      elements := node_ptr :: elements;

      for child in entry.children loop
        elements := resolveDuplicateEntriesPtr(child, tree, elements);
      end for;
    end resolveDuplicateEntriesPtr;

    function resolveClass
      input Integer index;
      input ClassTree tree;
      output InstNode element;
    algorithm
      element := match tree
        case PARTIAL_TREE() then arrayGet(tree.classes, index);
        case EXPANDED_TREE() then arrayGet(tree.classes, index);
        case INSTANTIATED_TREE() then Mutable.access(arrayGet(tree.classes, index));
        case FLAT_TREE() then arrayGet(tree.classes, index);
      end match;
    end resolveClass;

    function resolveComponent
      input Integer index;
      input ClassTree tree;
      output InstNode element;
    algorithm
      element := match tree
        case INSTANTIATED_TREE() then Mutable.access(arrayGet(tree.components, index));
        case FLAT_TREE() then arrayGet(tree.components, index);
      end match;
    end resolveComponent;

    function resolveImport
      input Integer index;
      input ClassTree tree;
      output InstNode element;
    protected
      array<Import> imports;
      Import imp;
      Boolean changed;
    algorithm
      imports := match tree
        case PARTIAL_TREE() then tree.imports;
        case EXPANDED_TREE() then tree.imports;
        case INSTANTIATED_TREE() then tree.imports;
        case FLAT_TREE() then tree.imports;
      end match;

      // Imports are resolved on demand, i.e. here.
      (element, changed, imp) := Import.resolve(imports[index]);

      // Save the import if it wasn't already resolved.
      if changed then
        arrayUpdate(imports, index, imp);
      end if;
    end resolveImport;

    function countElements
      "Counts the number of classes, components and extends clauses in a list of
       SCode elements."
      input list<SCode.Element> elements;
      output Integer classCount = 0;
      output Integer compCount = 0;
      output Integer extCount = 0;
    algorithm
      for e in elements loop
        () := match e
          case SCode.CLASS()
            algorithm
              classCount := classCount + 1;
            then
              ();

          case SCode.COMPONENT()
            algorithm
              compCount := compCount + 1;
            then
              ();

          case SCode.EXTENDS()
            algorithm
              extCount := extCount + 1;
            then
              ();

          else ();
        end match;
      end for;
    end countElements;

    function countInheritedElements
      input InstNode extendsNode;
      input output Integer classCount = 0;
      input output Integer componentCount = 0;
    protected
      array<InstNode> clss, comps, exts;
    algorithm
      () := match Class.classTree(InstNode.getClass(extendsNode))
        case EXPANDED_TREE(classes = clss, components = comps, exts = exts)
          algorithm
            // The component array contains placeholders for extends, which need to be
            // subtracted to get the proper component count.
            componentCount := componentCount + arrayLength(comps) - arrayLength(exts);
            classCount := classCount + arrayLength(clss);

            for ext in exts loop
              (classCount, componentCount) := countInheritedElements(ext, classCount, componentCount);
            end for;
          then
            ();

        case FLAT_TREE(classes = clss, components = comps)
          algorithm
            componentCount := componentCount + arrayLength(comps);
            classCount := classCount + arrayLength(clss);
          then
            ();

        else ();
      end match;
    end countInheritedElements;

    function expandExtends
      input InstNode extendsNode "The extends node";
      input output LookupTree.Tree tree "The lookup tree to add names to";
      input Integer classOffset "The index of the first class";
      input Integer componentOffset "The index of the first component";
      input Mutable<DuplicateTree.Tree> duplicates "Duplicate elements info.";
    protected
      ClassTree cls_tree;
      LookupTree.Tree ext_tree;
      DuplicateTree.Tree ext_dups, dups;
      LookupTree.ConflictFunc conf_func;
    algorithm
      // The extends node's lookup tree should at this point contain all the
      // entries we need, so we don't need to recursively traverse its
      // elements. Instead we can just take each entry in the extends node's
      // lookup tree, add the class or component index as an offset, and then
      // add the entry to the given lookup tree.
      cls_tree := Class.classTree(InstNode.getClass(extendsNode));

      (ext_tree, ext_dups) := match cls_tree
        case EXPANDED_TREE() then (cls_tree.tree, cls_tree.duplicates);
        case FLAT_TREE() then (cls_tree.tree, cls_tree.duplicates);
        else algorithm return; then (tree, DuplicateTree.new());
      end match;

      // Copy entries from the extends node's duplicate tree if there are any.
      if not DuplicateTree.isEmpty(ext_dups) then
        // Offset the entries so they're correct for the inheriting class tree.
        dups := DuplicateTree.map(ext_dups,
          function offsetDuplicates(classOffset = classOffset, componentOffset = componentOffset));
        // Join the two duplicate trees together.
        dups := DuplicateTree.join(Mutable.access(duplicates), dups, joinDuplicates);
        Mutable.update(duplicates, dups);
      end if;

      conf_func := function addInheritedElementConflict(
        duplicates = duplicates,
        extDuplicates = ext_dups);

      // Copy entries from the extends node's lookup tree.
      tree := LookupTree.fold(ext_tree,
        function addInheritedElement(
          classOffset = classOffset,
          componentOffset = componentOffset,
          conflictFunc = conf_func),
        tree);
    end expandExtends;

    function addInheritedElement
      input String name;
      input LookupTree.Entry entry;
      input Integer classOffset;
      input Integer componentOffset;
      input LookupTree.ConflictFunc conflictFunc;
      input output LookupTree.Tree tree;
    algorithm
      () := match entry
        case LookupTree.Entry.CLASS()
          algorithm
            entry.index := entry.index + classOffset;
            tree := LookupTree.add(tree, name, entry, conflictFunc);
          then
            ();

        case LookupTree.Entry.COMPONENT()
          algorithm
            entry.index := entry.index + componentOffset;
            tree := LookupTree.add(tree, name, entry, conflictFunc);
          then
            ();

        // Ignore IMPORT, since imports aren't inherited.
        else ();
      end match;
    end addInheritedElement;

    function addInheritedElementConflict
      "Conflict handler for addInheritedComponent."
      input LookupTree.Entry newEntry;
      input LookupTree.Entry oldEntry;
      input String name;
      input Mutable<DuplicateTree.Tree> duplicates;
      input DuplicateTree.Tree extDuplicates;
      output LookupTree.Entry entry;
    protected
      DuplicateTree.Tree dups;
      Option<DuplicateTree.Entry> opt_dup_entry;
      DuplicateTree.Entry dup_entry;
      Integer new_id = LookupTree.Entry.index(newEntry);
      Integer old_id = LookupTree.Entry.index(oldEntry);
      DuplicateTree.EntryType ty;
    algorithm
      // Overwrite the existing entry if it's an import. This happens when a
      // class both imports and inherits the same name.
      if LookupTree.Entry.isImport(oldEntry) then
        entry := newEntry;
        return;
      end if;

      dups := Mutable.access(duplicates);
      opt_dup_entry := DuplicateTree.getOpt(dups, name);

      if isNone(opt_dup_entry) then
        // If no duplicate entry yet exists, add a new one.
        if new_id < old_id then
          entry := newEntry;
          dup_entry := DuplicateTree.newDuplicate(newEntry, oldEntry);
        else
          entry := oldEntry;
          dup_entry := DuplicateTree.newDuplicate(oldEntry, newEntry);
        end if;

        dups := DuplicateTree.add(dups, name, dup_entry);
        Mutable.update(duplicates, dups);
      else
        SOME(dup_entry) := opt_dup_entry;
        ty := dup_entry.ty;

        // Here it's possible for either the new or the old entry to not exist in the duplicate entry.
        // The new might not exist simply because it hasn't been added yet, while the old might not
        // exist because it wasn't a duplicate in its own scope. At least one of them must exist though,
        // since duplicate entries are added for any name occurring more than once.
        if not DuplicateTree.idExistsInEntry(newEntry, dup_entry) then
          if ty == DuplicateTree.EntryType.REDECLARE then
            // If the existing entry is for a redeclare, then the position of the element
            // doesn't matter and the new entry should be added as a child to the redeclare.
            entry := newEntry;
            dup_entry.children := DuplicateTree.newEntry(newEntry) :: dup_entry.children;
          else
            // Otherwise we need to keep the 'first' element as the parent.
            // Note that this only actually works for components, since we don't
            // preserve the order for classes. But which class we choose shouldn't
            // matter since they should be identical. We might also compare e.g. a
            // component to a class here, but that will be caught in checkDuplicates.
            if new_id < old_id then
              entry := newEntry;
              dup_entry := DuplicateTree.Entry.ENTRY(newEntry, NONE(),
                DuplicateTree.newEntry(oldEntry) :: dup_entry.children, dup_entry.ty);
            else
              entry := oldEntry;
              dup_entry.children := DuplicateTree.newEntry(newEntry) :: dup_entry.children;
            end if;
          end if;

          dups := DuplicateTree.update(dups, name, dup_entry);
          Mutable.update(duplicates, dups);
        elseif not DuplicateTree.idExistsInEntry(oldEntry, dup_entry) then
          // Same as above but we add the old entry instead.
          if ty == DuplicateTree.EntryType.REDECLARE or new_id < old_id then
            entry := newEntry;
            dup_entry.children := DuplicateTree.newEntry(oldEntry) :: dup_entry.children;
          else
            entry := newEntry;
            dup_entry := DuplicateTree.Entry.ENTRY(newEntry, NONE(),
              DuplicateTree.newEntry(oldEntry) :: dup_entry.children, dup_entry.ty);
          end if;

          dups := DuplicateTree.update(dups, name, dup_entry);
          Mutable.update(duplicates, dups);
        else
          // If both the old and the new entry already exists, which can happen if the
          // new entry was added by expandExtents, then we don't need to add anything.
          entry := if new_id < old_id then newEntry else oldEntry;
        end if;
      end if;
    end addInheritedElementConflict;

    function offsetDuplicates
      "Offsets all values in the given entry so that they become valid for the
       inheriting class."
      input String name;
      input DuplicateTree.Entry entry;
      input Integer classOffset;
      input Integer componentOffset;
      output DuplicateTree.Entry offsetEntry;
    protected
      LookupTree.Entry parent;
      list<DuplicateTree.Entry> children;
    algorithm
      parent := offsetDuplicate(entry.entry, classOffset, componentOffset);
      children := list(offsetDuplicates(name, c, classOffset, componentOffset) for c in entry.children);
      offsetEntry := DuplicateTree.ENTRY(parent, NONE(), children, entry.ty);
    end offsetDuplicates;

    function offsetDuplicate
      input LookupTree.Entry entry;
      input Integer classOffset;
      input Integer componentOffset;
      output LookupTree.Entry offsetEntry;
    algorithm
      offsetEntry := match entry
        case LookupTree.Entry.CLASS()
          then LookupTree.Entry.CLASS(entry.index + classOffset);
        case LookupTree.Entry.COMPONENT()
          then LookupTree.Entry.COMPONENT(entry.index + componentOffset);
      end match;
    end offsetDuplicate;

    function joinDuplicates
      "Joins two duplicate tree entries together."
      input DuplicateTree.Entry newEntry;
      input DuplicateTree.Entry oldEntry;
      input String name;
      output DuplicateTree.Entry entry = oldEntry;
    algorithm
      // Add the new entry as a child of the old entry.
      entry.children := newEntry :: entry.children;
    end joinDuplicates;

    function enumerateDuplicates
      "Returns the indices of the duplicate classes and components,
       not including the ones that should be kept."
      input DuplicateTree.Tree duplicates;
      output list<Integer> classes;
      output list<Integer> components;
    algorithm
      if DuplicateTree.isEmpty(duplicates) then
        classes := {};
        components := {};
      else
        (classes, components) := DuplicateTree.fold_2(duplicates, enumerateDuplicates2, {}, {});
      end if;
    end enumerateDuplicates;

    function enumerateDuplicates2
      input String name;
      input DuplicateTree.Entry entry;
      input output list<Integer> classes;
      input output list<Integer> components;
    algorithm
      for c in entry.children loop
        (classes, components) := enumerateDuplicates3(c, classes, components);
      end for;
    end enumerateDuplicates2;

    function enumerateDuplicates3
      input DuplicateTree.Entry entry;
      input output list<Integer> classes;
      input output list<Integer> components;
    algorithm
      (classes, components) := enumerateDuplicates4(entry.entry, classes, components);

      for c in entry.children loop
        (classes, components) := enumerateDuplicates3(c, classes, components);
      end for;
    end enumerateDuplicates3;

    function enumerateDuplicates4
      input LookupTree.Entry entry;
      input output list<Integer> classes;
      input output list<Integer> components;
    algorithm
      () := match entry
        case LookupTree.Entry.CLASS()
          algorithm
            //classes := entry.index :: classes;
          then
            ();

        case LookupTree.Entry.COMPONENT()
          algorithm
            components := entry.index :: components;
          then
            ();
      end match;
    end enumerateDuplicates4;

    function mapRedeclareChain
      input String name;
      input output DuplicateTree.Entry entry;
      input FuncT func;
      input ClassTree tree;

      partial function FuncT
        input list<Mutable<InstNode>> chain;
      end FuncT;
    protected
      list<Mutable<InstNode>> chain;
    algorithm
      chain := getRedeclareChain(entry, tree);

      if not listEmpty(chain) then
        func(chain);
      end if;
    end mapRedeclareChain;

    function getRedeclareChain
      input DuplicateTree.Entry entry;
      input ClassTree tree;
      input output list<Mutable<InstNode>> chain = {};
    algorithm
      chain := match entry.ty
        local
          Mutable<InstNode> node_ptr;
          InstNode node;

        case DuplicateTree.EntryType.REDECLARE
          algorithm
            node_ptr := resolveEntryPtr(entry.entry, tree);

            if listEmpty(entry.children) then
              node := Mutable.access(node_ptr);

              if SCode.isClassExtends(InstNode.definition(node)) then
                Error.addSourceMessage(Error.CLASS_EXTENDS_TARGET_NOT_FOUND,
                  {InstNode.name(node)}, InstNode.info(node));
              else
                Error.addSourceMessage(Error.REDECLARE_NONEXISTING_ELEMENT,
                  {InstNode.name(node)}, InstNode.info(node));
              end if;

              fail();
            end if;
          then
            getRedeclareChain(listHead(entry.children), tree, node_ptr :: chain);

        case DuplicateTree.EntryType.ENTRY
          algorithm
            node_ptr := resolveEntryPtr(entry.entry, tree);
          then
            node_ptr :: chain;

        else chain;
      end match;
    end getRedeclareChain;

    function replaceDuplicates2
      input String name;
      input output DuplicateTree.Entry entry;
      input ClassTree tree;
    protected
      InstNode kept;
      Mutable<InstNode> node_ptr;
      list<DuplicateTree.Entry> children;
      DuplicateTree.Entry kept_entry;
    algorithm
      node_ptr := resolveEntryPtr(entry.entry, tree);

      () := match entry.ty
        case DuplicateTree.EntryType.REDECLARE
          algorithm
            kept := Mutable.access(resolveEntryPtr(entry.entry, tree));
            entry := replaceDuplicates4(entry, kept);
          then
            ();

        case DuplicateTree.EntryType.DUPLICATE
          algorithm
            kept := Mutable.access(node_ptr);
            entry.node := SOME(kept);
            entry.children := list(replaceDuplicates3(c, kept, tree) for c in entry.children);
          then
            ();

        else ();
      end match;
    end replaceDuplicates2;

    function replaceDuplicates3
      input output DuplicateTree.Entry entry;
      input InstNode kept;
      input ClassTree tree;
    protected
      Mutable<InstNode> node_ptr;
      InstNode node;
    algorithm
      node_ptr := resolveEntryPtr(entry.entry, tree);
      node := Mutable.access(node_ptr);
      entry.node := SOME(node);
      Mutable.update(node_ptr, kept);
      entry.children := list(replaceDuplicates3(c, kept, tree) for c in entry.children);
    end replaceDuplicates3;

    function replaceDuplicates4
      input output DuplicateTree.Entry entry;
      input InstNode node;
    algorithm
      entry.node := SOME(node);
      entry.children := list(replaceDuplicates4(c, node) for c in entry.children);
    end replaceDuplicates4;

    function linkInnerOuter
      "Looks up the corresponding inner node for the given outer node,
       and returns an INNER_OUTER_NODE containing them both."
      input InstNode outerNode;
      input InstNode scope;
      output InstNode innerOuterNode;
    protected
      InstNode inner_node;
    algorithm
      inner_node := Lookup.lookupInner(outerNode, scope);

      // Make sure we found a node of the same kind.
      if valueConstructor(outerNode) <> valueConstructor(inner_node) then
        Error.addMultiSourceMessage(Error.FOUND_WRONG_INNER_ELEMENT,
          {InstNode.typeName(inner_node), InstNode.name(outerNode), InstNode.typeName(outerNode)},
          {InstNode.info(outerNode), InstNode.info(inner_node)});
        fail();
      end if;

      innerOuterNode := InstNode.INNER_OUTER_NODE(inner_node, outerNode);
    end linkInnerOuter;

    function checkOuterClass
      "Checks that a class used as outer is valid, i.e. is a short class
       definition with no modifier."
      input InstNode outerCls;
    protected
      SCode.ClassDef def;
    algorithm
      if InstNode.isOnlyOuter(outerCls) then
        def := SCode.getClassDef(InstNode.definition(outerCls));

        () := match def
          // Outer short class definition without mod is ok.
          case SCode.ClassDef.DERIVED(modifications = SCode.Mod.NOMOD()) then ();

          // Outer short class definition with mod is an error.
          case SCode.ClassDef.DERIVED()
            algorithm
              Error.addSourceMessage(Error.OUTER_ELEMENT_MOD,
                {SCodeDump.printModStr(def.modifications), InstNode.name(outerCls)},
                InstNode.info(outerCls));
            then
              fail();

          // Outer long class definition is an error.
          else
            algorithm
              Error.addSourceMessage(Error.OUTER_LONG_CLASS,
                {InstNode.name(outerCls)}, InstNode.info(outerCls));
            then
              fail();

        end match;
      end if;
    end checkOuterClass;
  end ClassTree;

annotation(__OpenModelica_Interface="frontend");
end NFClassTree;

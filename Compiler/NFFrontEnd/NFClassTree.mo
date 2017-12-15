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
      array<InstNode> imports;
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
      array<InstNode> imports;
      DuplicateTree.Tree duplicates;
    end EXPANDED_TREE;

    record INSTANTIATED_TREE
      "Allows lookup of both local and inherited elements."
      LookupTree.Tree tree;
      array<Mutable<InstNode>> classes;
      array<Mutable<InstNode>> components;
      list<Integer> localComponents;
      array<InstNode> exts;
      array<InstNode> imports;
      DuplicateTree.Tree duplicates;
    end INSTANTIATED_TREE;

    record FLAT_TREE
      "A flattened version of an instantiated tree."
      LookupTree.Tree tree;
      array<InstNode> classes;
      array<InstNode> components;
      array<InstNode> imports;
      DuplicateTree.Tree duplicates;
    end FLAT_TREE;

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
      array<InstNode> clss, comps, exts, imps;
      Integer cls_idx = 0, ext_idx = 0, comp_idx = 0;
      list<InstNode> imported_elems = {};
      DuplicateTree.Tree dups;
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

          // An import clause. Instantiate it to get the elements it points to
          // (might be multiple elements if it's unqualified) and store them in
          // the list for later.
          case SCode.IMPORT()
            algorithm
              imported_elems := Inst.instImport(e.imp, parent, e.info, imported_elems);
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

      // Add all the imports to the tree.
      i := 1;
      for e in imported_elems loop
        ltree := addImport(e, i, ltree);
        i := i + 1;
      end for;

      tree := PARTIAL_TREE(ltree, clss, comps, exts, listArray(imported_elems), dups);
    end fromSCode;

    function fromEnumeration
      "Creates a class tree for an enumeration type."
      input list<SCode.Enum> literals "The SCode literals";
      input Type enumType "The type of the enumeration";
      input InstNode enumClass "The InstNode of the enumeration type";
      output ClassTree tree;
    protected
      array<InstNode> comps;
      Integer i = 0;
      InstNode comp;
      LookupTree.Tree ltree;
      String name;
    algorithm
      comps := arrayCreateNoInit(listLength(literals), InstNode.EMPTY_NODE());
      ltree := LookupTree.new();

      for l in literals loop
        name := l.literal;

        // Check that the literal is not one of the reserved attribute names.
        if listMember(name, {"quantity", "min", "max", "start", "fixed"}) then
          Error.addSourceMessage(Error.INVALID_ENUM_LITERAL, {name}, InstNode.info(enumClass));
          fail();
        end if;

        // Make a new component node for the literal and add it to the lookup tree.
        i := i + 1;
        comp := InstNode.fromComponent(name, Component.newEnum(enumType, name, i), enumClass);
        arrayUpdateNoBoundsChecking(comps, i, comp);
        ltree := LookupTree.add(ltree, name, LookupTree.Entry.COMPONENT(i),
          function addEnumConflict(literal = comp));
      end for;

      // Enumerations can't contain extends, so we can go directly to a flat tree here.
      tree := FLAT_TREE(ltree, listArray({}), comps, listArray({}), DuplicateTree.EMPTY());
    end fromEnumeration;

    function expand
      "This function adds all local and inherited class and component names to
       the lookup tree. Note that only their names are added, the elements
       themselves are added to their respective arrays by the instantiation
       function below."
      input output ClassTree tree;
    protected
      LookupTree.Tree ltree;
      LookupTree.Entry lentry;
      array<InstNode> exts, clss, comps, imps;
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
      output Integer classCount = 0;
      output Integer compCount = 0;
    protected
      Class cls;
      ClassTree tree, ext_tree;
      LookupTree.Tree ltree;
      array<InstNode> exts, old_clss, old_comps, imps;
      array<Mutable<InstNode>> clss, comps, ext_clss;
      list<Integer> local_comps = {};
      Integer cls_idx = 1, comp_idx = 1, cls_count, comp_count;
      InstNode node, parent_scope, inner_node;
      DuplicateTree.Tree dups;
      Component comp;
    algorithm
      // TODO: If we don't have any extends we could probably generate a flat
      // tree directly and skip a lot of this.

      // Clone the class node by replacing the class in the node with itself.
      cls := InstNode.getClass(clsNode);
      clsNode := InstNode.replaceClass(cls, clsNode);

      () := match cls
        case Class.EXPANDED_CLASS()
          algorithm
            // If the instance is an empty node, use the cloned clsNode as the instance.
            if InstNode.isEmpty(instance) then
              instance := clsNode;
              parent_scope := InstNode.parent(clsNode);
            else
              parent_scope := instance;
            end if;

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
              (node, _, cls_count, comp_count) := instantiate(exts[i], instance);
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
              INSTANTIATED_TREE(classes = ext_clss) := Class.classTree(InstNode.getClass(ext));
              cls_count := arrayLength(ext_clss);

              if cls_count > 0 then
                Array.copyRange(ext_clss, clss, 1, cls_count, cls_idx);
                cls_idx := cls_idx + cls_count;
              end if;
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
                      node := linkInnerOuter(node, instance);
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
            Error.assertion(comp_idx == compCount + 1, getInstanceName() + " miscounted components in " + InstNode.name(clsNode), sourceInfo());
            Error.assertion(cls_idx == classCount + 1, getInstanceName() + " miscounted classes in " + InstNode.name(clsNode), sourceInfo());

            // Create a new class tree and update the class in the node.
            cls.elements := INSTANTIATED_TREE(ltree, clss, comps, local_comps, exts, imps, dups);
          then
            ();

        case Class.DERIVED_CLASS()
          algorithm
            (node, _, classCount, compCount) := instantiate(cls.baseClass);
            cls.baseClass := node;
          then
            ();

        else
          algorithm
            Error.assertion(false, getInstanceName() + " got invalid class", sourceInfo());
          then
            fail();

      end match;

      InstNode.updateClass(cls, clsNode);
    end instantiate;

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
    protected
      LookupTree.Entry entry;
    algorithm
      entry := LookupTree.get(lookupTree(tree), name);
      element := resolveEntry(entry, tree);
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

    function copyModifiersToDups
      input ClassTree tree;
    algorithm
      () := match tree
        case INSTANTIATED_TREE() guard not DuplicateTree.isEmpty(tree.duplicates)
          algorithm
            DuplicateTree.fold(tree.duplicates, copyModifiersToDup, tree);
          then
            ();

        else ();
      end match;
    end copyModifiersToDups;

    function copyModifiersToDup
      input String name;
      input DuplicateTree.Entry entry;
      input output ClassTree tree;
    algorithm
    end copyModifiersToDup;

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
        // A redeclare element without an element to replace.
        case DuplicateTree.EntryType.REDECLARE guard listEmpty(entry.children)
          algorithm
            if SCode.isClassExtends(InstNode.definition(kept)) then
              Error.addSourceMessage(Error.CLASS_EXTENDS_TARGET_NOT_FOUND,
                {name}, InstNode.info(kept));
            else
              Error.addSourceMessage(Error.REDECLARE_NONEXISTING_ELEMENT,
                {name}, InstNode.info(kept));
            end if;
          then
            fail();

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

  protected

    function instExtendsComps
      input InstNode extNode;
      input array<Mutable<InstNode>> comps;
      input output Integer index "The first free index in comps";
    protected
      array<Mutable<InstNode>> ext_comps;
      Integer comp_count;
    algorithm
      INSTANTIATED_TREE(components = ext_comps) := Class.classTree(InstNode.getClass(extNode));
      comp_count := arrayLength(ext_comps);

      if comp_count > 0 then
        Array.copyRange(ext_comps, comps, 1, comp_count, index);
        index := index + comp_count;
      end if;
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
      input InstNode node;
      input Integer index;
      input output LookupTree.Tree tree;
    algorithm
      tree := LookupTree.add(tree, InstNode.name(node),
        LookupTree.Entry.IMPORT(index), addImportConflict);
    end addImport;

    function addImportConflict
      input LookupTree.Entry newEntry;
      input LookupTree.Entry oldEntry;
      input String name;
      output LookupTree.Entry entry;
    algorithm
      entry := oldEntry;
      // TODO: We should probably give an error message here in some cases:
      // * Named/qualified import conflicting with normal element: warning
      // * Unqualified import conflicting with normal element: ignore import
      // * Import conflicting with import: Error, but only if used
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
    algorithm
      element := match entry
        case LookupTree.Entry.CLASS() then resolveClass(entry.index, tree);
        case LookupTree.Entry.COMPONENT() then resolveComponent(entry.index, tree);
        case LookupTree.Entry.IMPORT() then resolveImport(entry.index, tree);
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
      array<InstNode> imports;
    algorithm
      imports := match tree
        case PARTIAL_TREE() then tree.imports;
        case EXPANDED_TREE() then tree.imports;
        case INSTANTIATED_TREE() then tree.imports;
        case FLAT_TREE() then tree.imports;
      end match;

      element := imports[index];
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
      LookupTree.Tree ltree;
      array<InstNode> clss, comps, exts;
    algorithm
      EXPANDED_TREE(tree = ltree, classes = clss, components = comps, exts = exts) :=
        Class.classTree(InstNode.getClass(extendsNode));

      // The component array contains placeholders for extends, which need to be
      // subtracted to get the proper component count.
      componentCount := componentCount + arrayLength(comps) - arrayLength(exts);
      classCount := classCount + arrayLength(clss);

      for ext in exts loop
        (classCount, componentCount) := countInheritedElements(ext, classCount, componentCount);
      end for;
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
      DuplicateTree.Tree dups;
      LookupTree.ConflictFunc conf_func;
    algorithm
      // The extends node's lookup tree should at this point contain all the
      // entries we need, so we don't need to recursively traverse its
      // elements. Instead we can just take each entry in the extends node's
      // lookup tree, add the class or component index as an offset, and then
      // add the entry to the given lookup tree.
      cls_tree := Class.classTree(InstNode.getClass(extendsNode));
      EXPANDED_TREE(tree = ext_tree, duplicates = dups) := cls_tree;

      // Copy entries from the extends node's duplicate tree if there are any.
      if not DuplicateTree.isEmpty(dups) then
        // Offset the entries so they're correct for the inheriting class tree.
        dups := DuplicateTree.map(dups,
          function offsetDuplicates(classOffset = classOffset, componentOffset = componentOffset));
        // Join the two duplicate trees together.
        dups := DuplicateTree.join(Mutable.access(duplicates), dups, joinDuplicates);
        Mutable.update(duplicates, dups);
      end if;

      conf_func := function addInheritedElementConflict(
        duplicates = duplicates,
        extDuplicates = dups);

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
    algorithm
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
      elseif isNone(DuplicateTree.getOpt(extDuplicates, name)) then
        // If a duplicate entry does exist, but not in the extends node's duplicate
        // tree, then we need to add the inherited element to the existing entry.
        // This happens when the element is not a duplicate in its own scope.
        SOME(dup_entry) := opt_dup_entry;

        // TODO: Change this to an if-statement when compiler bug #4502 is fixed.
        () := match dup_entry.ty
          case DuplicateTree.EntryType.REDECLARE
            algorithm
              // If the existing entry is for a redeclare, then the position of
              // the element doesn't matter and the new entry should be added as
              // a child to the redeclare.
              entry := oldEntry;
              dup_entry.children := DuplicateTree.newEntry(newEntry) :: dup_entry.children;
            then
              ();
          else
            algorithm
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
            then
              ();
        end match;

        dups := DuplicateTree.update(dups, name, dup_entry);
        Mutable.update(duplicates, dups);
      else
        // If an entry does exist in both duplicate tree, then it's already been
        // added by expandExtends and nothing more needs to be done here.
        entry := if new_id < old_id then newEntry else oldEntry;
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
      output DuplicateTree.Entry entry;
    algorithm
      // The kept entry from the extends node is ignored, since it's already
      // added when copying entries from the extends node's lookup tree.
      entry := DuplicateTree.ENTRY(oldEntry.entry, NONE(),
        listAppend(newEntry.children, oldEntry.children), oldEntry.ty);
    end joinDuplicates;

    function enumerateDuplicates
      "Returns two sorted lists with the indices of the duplicate classes and
       components."
      input DuplicateTree.Tree duplicates;
      output list<Integer> classes;
      output list<Integer> components;
    algorithm
      if DuplicateTree.isEmpty(duplicates) then
        classes := {};
        components := {};
      else
        (classes, components) := DuplicateTree.fold_2(duplicates, enumerateDuplicates2, {}, {});
        //classes := List.sort(classes, intGt);
        //components := List.sort(components, intGt);
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
            classes := entry.index :: classes;
          then
            ();

        case LookupTree.Entry.COMPONENT()
          algorithm
            components := entry.index :: components;
          then
            ();
      end match;
    end enumerateDuplicates4;

    function replaceDuplicates2
      input String name;
      input output DuplicateTree.Entry entry;
      input ClassTree tree;
    protected
      InstNode parent;
    algorithm
      parent := Mutable.access(resolveEntryPtr(entry.entry, tree));
      entry.node := SOME(parent);
      entry.children := list(replaceDuplicates3(c, parent, tree) for c in entry.children);
    end replaceDuplicates2;

    function replaceDuplicates3
      input output DuplicateTree.Entry entry;
      input InstNode parent;
      input ClassTree tree;
    protected
      Mutable<InstNode> node_ptr, child_ptr;
      InstNode node, child;
    algorithm
      node_ptr := resolveEntryPtr(entry.entry, tree);
      node := Mutable.access(node_ptr);
      entry.node := SOME(node);
      Mutable.update(node_ptr, parent);
      entry.children := list(replaceDuplicates3(c, parent, tree) for c in entry.children);
    end replaceDuplicates3;

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

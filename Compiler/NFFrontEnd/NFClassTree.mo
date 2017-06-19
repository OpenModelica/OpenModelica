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
  import DoubleEndedList;
  import MetaModelica.Dangerous.*;
  import NFClass.Class;
  import NFComponent.Component;
  import Inst = NFInst;

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

  constant ClassTree EMPTY = ClassTree.PARTIAL_TREE(LookupTree.EMPTY(),
      listArray({}), listArray({}), listArray({}), listArray({}));

  uniontype ClassTree
    record PARTIAL_TREE
      "A partial tree allows lookup of local classes and imported elements."
      LookupTree.Tree tree;
      array<InstNode> classes;
      array<InstNode> components;
      array<InstNode> exts;
      array<InstNode> imports;
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
      list<LookupTree.Entry> duplicates;
    end EXPANDED_TREE;

    record INSTANTIATED_TREE
      "Allows lookup of both local and inherited elements."
      LookupTree.Tree tree;
      array<Mutable<InstNode>> classes;
      array<Mutable<InstNode>> components;
      list<Integer> localComponents;
      array<InstNode> exts;
      array<InstNode> imports;
    end INSTANTIATED_TREE;

    record FLAT_TREE
      "A flattened version of an instantiated tree."
      LookupTree.Tree tree;
      array<InstNode> classes;
      array<InstNode> components;
      array<InstNode> imports;
    end FLAT_TREE;

    function fromSCode
      "Creates a new class tree from a list of SCode elements."
      input list<SCode.Element> elements;
      input InstNode parent;
      output ClassTree tree;
    protected
      LookupTree.Tree ltree;
      Integer clsc, compc, extc, i;
      array<InstNode> clss, comps, exts, imps;
      Integer cls_idx = 0, ext_idx = 0, comp_idx = 0;
      list<InstNode> imported_elems = {};
    algorithm
      ltree := LookupTree.new();

      // Count the elements and create arrays for them.
      (clsc, compc, extc) := countElements(elements);
      clss := arrayCreateNoInit(clsc, InstNode.EMPTY_NODE());
      comps := arrayCreateNoInit(compc + extc, InstNode.EMPTY_NODE());
      exts := arrayCreateNoInit(extc, InstNode.EMPTY_NODE());

      for e in elements loop
        () := match e
          // A class, add it to the class array and add an entry in the lookup tree.
          case SCode.CLASS()
            algorithm
              cls_idx := cls_idx + 1;
              arrayUpdate(clss, cls_idx, InstNode.newClass(e, parent));
              ltree := addLocalClass(e.name, cls_idx, clss, ltree);
            then
              ();

          // A component, add it to the component array but don't add an entry
          // in the lookup tree. We need to preserve the components' order, but
          // wont know their actual indices until we've expanded the extends.
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

      tree := PARTIAL_TREE(ltree, clss, comps, exts, listArray(imported_elems));
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
      tree := FLAT_TREE(ltree, listArray({}), comps, listArray({}));
    end fromEnumeration;

    function expand
      "This function adds all local and inherited class and component names to
       the lookup tree. Note that only their names are added, the elements
       themselves are added to their respective arrays by the instantiation
       function below."
      input output ClassTree tree;
    protected
      LookupTree.Tree ltree;
      array<InstNode> exts, clss, comps, imps;
      list<tuple<Integer, Integer>> ext_idxs = {};
      Integer ccount, cls_idx, comp_idx = 1;
      DoubleEndedList<LookupTree.Entry> duplicates;
    algorithm
      PARTIAL_TREE(ltree, clss, comps, exts, imps) := tree;
      cls_idx := arrayLength(clss) + 1;

      // Since we now know the names of both local and inherited components we
      // can add them to the lookup tree. First we add the local components'
      // names, to be able to catch duplicate local elements easier.
      for c in comps loop
        () := match c
          // A component. Add its name to the lookup tree.
          case InstNode.COMPONENT_NODE()
            algorithm
              ltree := addLocalComponent(c, comp_idx, tree, ltree);
              comp_idx := comp_idx + 1;
            then
              ();

          // An extends node. Save the index so we know where to start adding
          // components later, and increment the index with the number of
          // components it contains.
          case InstNode.REF_NODE()
            algorithm
              ext_idxs := (cls_idx, comp_idx) :: ext_idxs;
              (cls_idx, comp_idx) := countInheritedElements(exts[c.index], cls_idx, comp_idx);
            then
              ();

          else
            algorithm
              assert(false, getInstanceName() + " got invalid component");
            then
              fail();
        end match;
      end for;

      // Checking whether inherited duplicate elements are identical is hard to
      // do correctly at this point. So we just detect them and store their
      // indices in the class tree for now, and check them for identicalness
      // later on instead.
      duplicates := DoubleEndedList.empty(/*dummy*/LookupTree.Entry.COMPONENT(0));

      // Add the names of inherited components and classes to the lookup tree.
      if not listEmpty(ext_idxs) then
        // Use the component indices we saved earlier to add the required
        // elements from the extends nodes to the lookup tree.
        ext_idxs := listReverseInPlace(ext_idxs);

        for ext in exts loop
          (cls_idx, comp_idx) :: ext_idxs := ext_idxs;
          ltree := expandExtends(ext, ltree, cls_idx, comp_idx, duplicates);
        end for;
      end if;

      tree := EXPANDED_TREE(ltree, clss, comps, exts, imps,
        DoubleEndedList.toListAndClear(duplicates));
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
      InstNode node;
    algorithm
      // TODO: If we don't have any extends we could probably generate a flat
      // tree directly and skip a lot of this.

      // Clone the class node by replacing the class in the node with itself.
      cls := InstNode.getClass(clsNode);
      clsNode := InstNode.replaceClass(cls, clsNode);

      // If the instance is an empty node, use the cloned clsNode as the instance.
      if InstNode.isEmpty(instance) then
        instance := clsNode;
      end if;

      // Fetch the elements from the class tree.
      EXPANDED_TREE(ltree, old_clss, old_comps, exts, imps, _) := Class.classTree(cls);

      // Count the number of local classes and components we have.
      classCount := arrayLength(old_clss);
      // The component array contains placeholders for extends, so the length of
      // the extends array is subtracted here to get only the number of components.
      compCount := arrayLength(old_comps) - arrayLength(exts);

      // Make a new extends array, and recursively instantiate the extends nodes.
      exts := arrayCopy(exts);
      for i in 1:arrayLength(exts) loop
        (node, _, cls_count, comp_count) := instantiate(exts[i]);
        exts[i] := node;
        // Add the inherited elements to the class/component counts.
        classCount := cls_count + classCount;
        compCount := comp_count + compCount;
      end for;

      // Create new arrays that can hold both local and inherited elements.
      comps := arrayCreateNoInit(compCount, /*dummy*/Mutable.create(InstNode.EMPTY_NODE()));
      clss := arrayCreateNoInit(classCount, /*dummy*/Mutable.create(InstNode.EMPTY_NODE()));

      // Copy the local classes into the new class array, and set their parent
      // to be the class we're instantiating.
      for c in old_clss loop
        c := InstNode.setParent(clsNode, c);
        arrayUpdateNoBoundsChecking(clss, cls_idx, Mutable.create(c));
        cls_idx := cls_idx + 1;
      end for;

      // Copy inherited classes into the new class array. Note that inherited
      // classes are just inserted after the local ones, and not where the
      // extends say they should go. Otherwise we wouldn't be able to reuse the
      // lookup tree, and the order of classes shouldn't really matter.
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
              // Set the components parent and create a unique instance for it.
              node := InstNode.setParent(instance, c);
              node := InstNode.replaceComponent(InstNode.component(node), node);
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
      assert(comp_idx == compCount + 1, getInstanceName() + " miscounted components in " + InstNode.name(clsNode));
      assert(cls_idx == classCount + 1, getInstanceName() + " miscounted classes in " + InstNode.name(clsNode));

      // Create a new class tree and update the class in the node.
      tree := INSTANTIATED_TREE(ltree, clss, comps, local_comps, exts, imps);
      cls := Class.setClassTree(tree, cls);
      InstNode.updateClass(cls, clsNode);
    end instantiate;

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

    function flatten
      input output ClassTree tree;
    algorithm
      tree := match tree
        local
          array<InstNode> clss, comps;
          Integer clsc, compc;

        case INSTANTIATED_TREE()
          algorithm
            clsc := arrayLength(tree.classes);
            compc := arrayLength(tree.components);
            clss := arrayCreateNoInit(clsc, InstNode.EMPTY_NODE());
            comps := arrayCreateNoInit(compc, InstNode.EMPTY_NODE());

            for i in 1:clsc loop
              arrayUpdateNoBoundsChecking(clss, i,
                Mutable.access(arrayGetNoBoundsChecking(tree.classes, i)));
            end for;

            for i in 1:compc loop
              arrayUpdateNoBoundsChecking(comps, i,
                Mutable.access(arrayGetNoBoundsChecking(tree.components, i)));
            end for;
          then
            FLAT_TREE(tree.tree, clss, comps, tree.imports);

        else tree;
      end match;
    end flatten;

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

    function componentCount
      input ClassTree tree;
      output Integer count;
    algorithm
      count := match tree
        case PARTIAL_TREE() then arrayLength(tree.components) - arrayLength(tree.exts);
        case EXPANDED_TREE() then arrayLength(tree.components) - arrayLength(tree.exts);
        case INSTANTIATED_TREE() then arrayLength(tree.components) - arrayLength(tree.exts);
        case FLAT_TREE() then arrayLength(tree.components);
      end match;
    end componentCount;

    function extendsCount
      input ClassTree tree;
      output Integer count = arrayLength(getExtends(tree));
    end extendsCount;

  protected

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

    function addLocalClass
      "Adds a local class name to the lookup tree."
      input String name;
      input Integer index;
      input array<InstNode> classes;
      input output LookupTree.Tree tree;
    algorithm
      tree := LookupTree.add(tree, name, LookupTree.Entry.CLASS(index),
        function addLocalClassConflict(classes = classes));
    end addLocalClass;

    function addLocalClassConflict
      "Conflict handler for addLocalClass."
      input LookupTree.Entry newEntry;
      input LookupTree.Entry oldEntry;
      input array<InstNode> classes;
      output LookupTree.Entry entry;
    protected
      Integer i1, i2;
      InstNode node1, node2;
    algorithm
      // Local elements with the same name are never allowed.
      LookupTree.Entry.CLASS(index = i1) := newEntry;
      LookupTree.Entry.CLASS(index = i2) := oldEntry;

      Error.addMultiSourceMessage(Error.DOUBLE_DECLARATION_OF_ELEMENTS,
        {InstNode.name(classes[i1])}, {InstNode.info(classes[i2]), InstNode.info(classes[i1])});
      fail();
    end addLocalClassConflict;

    function addInheritedClass
      "Adds an inherited class name to the lookup tree."
      input String name;
      input Integer index;
      input output LookupTree.Tree tree;
      input DoubleEndedList<LookupTree.Entry> duplicates;
    algorithm
      if index <= 0 then
        assert(false, "Got invalid class index");
      end if;
      tree := LookupTree.add(tree, name, LookupTree.Entry.CLASS(index),
        function addInheritedClassConflict(duplicates = duplicates));
    end addInheritedClass;

    function addInheritedClassConflict
      "Conflict handler for addInheritedClass."
      input LookupTree.Entry newEntry;
      input LookupTree.Entry oldEntry;
      input DoubleEndedList<LookupTree.Entry> duplicates;
      output LookupTree.Entry entry;
    algorithm
      // Keep the old entry in the tree and save the new as a duplicate. This
      // works correctly if both classes are inherited, but might keep the wrong
      // class if the old class is a local class defined above the extends since
      // we don't preserve the order of classes. But the order of classes
      // shouldn't matter, and this would only cause issues with already very
      // dubious models. Note that none of the entries can be a component, since
      // classes are added first.
      DoubleEndedList.push_back(duplicates, newEntry);
      entry := oldEntry;
    end addInheritedClassConflict;

    function addLocalComponent
      "Adds a local component name to the lookup tree."
      input InstNode component;
      input Integer index;
      input ClassTree classTree;
      input output LookupTree.Tree tree;
    algorithm
      tree := LookupTree.add(tree, InstNode.name(component),
        LookupTree.Entry.COMPONENT(index),
        function addLocalComponentConflict(classTree = classTree));
    end addLocalComponent;

    function addLocalComponentConflict
      "Conflict handler for addLocalComponent."
      input LookupTree.Entry newEntry;
      input LookupTree.Entry oldEntry;
      input ClassTree classTree;
      output LookupTree.Entry entry;
    protected
      InstNode n1, n2;
    algorithm
      // Local elements with the same name are never allowed.
      n1 := resolveEntry(newEntry, classTree);
      n2 := resolveEntry(oldEntry, classTree);
      Error.addMultiSourceMessage(Error.DOUBLE_DECLARATION_OF_ELEMENTS,
        {InstNode.name(n1)}, {InstNode.info(n2), InstNode.info(n1)});
      fail();
    end addLocalComponentConflict;

    function addInheritedComponent
      "Adds an inherited component to the lookup tree."
      //input InstNode component;
      input String name;
      input Integer index;
      input output LookupTree.Tree tree;
      input DoubleEndedList<LookupTree.Entry> duplicates;
    algorithm
      tree := LookupTree.add(tree, name, LookupTree.Entry.COMPONENT(index),
        function addInheritedComponentConflict(duplicates = duplicates));
    end addInheritedComponent;

    function addInheritedComponentConflict
      "Conflict handler for addInheritedComponent."
      input LookupTree.Entry newEntry;
      input LookupTree.Entry oldEntry;
      input DoubleEndedList<LookupTree.Entry> duplicates;
      output LookupTree.Entry entry;
    algorithm
      entry := match (newEntry, oldEntry)
        // Both are components.
        case (LookupTree.COMPONENT(), LookupTree.COMPONENT())
          algorithm
            // Keep the component with the lowest index in the tree, and save
            // the other's index as a duplicate.
            if newEntry.index < oldEntry.index then
              entry := newEntry;
              DoubleEndedList.push_back(duplicates, oldEntry);
            else
              entry := oldEntry;
              DoubleEndedList.push_back(duplicates, newEntry);
            end if;
          then
            entry;

        // Otherwise the old entry must be a class, in which case we could
        // report an error immediately. But to keep things simple we handle it
        // like a normal duplicate element.
        else
          algorithm
            DoubleEndedList.push_back(duplicates, newEntry);
          then
            oldEntry;

      end match;
    end addInheritedComponentConflict;

    function addEnumConflict
      "Conflict handler for fromEnumeration."
      input LookupTree.Entry newEntry;
      input LookupTree.Entry oldEntry;
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
      output LookupTree.Entry entry;
    algorithm
      entry := oldEntry;
      // TODO: We should probably give an error message here in some cases:
      // * Named/qualified import conflicting with normal element: warning
      // * Unqualified import conflicting with normal element: ignore import
      // * Import conflicting with import: Error, but only if used
    end addImportConflict;

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
      input Integer classIndex "The index of the first class";
      input Integer componentIndex "The index of the first component";
      input DoubleEndedList<LookupTree.Entry> duplicates "Mutable list of duplicate elements";
    protected
      LookupTree.Tree ext_tree;
    algorithm
      // The extends node's lookup tree should at this point contain all the
      // entries we need, so we don't need to recursively traverse its
      // elements. Instead we can just take each entry in the extends node's
      // lookup tree, add the class or component index as an offset, and then
      // add the entry to the given lookup tree.
      ext_tree := lookupTree(Class.classTree(InstNode.getClass(extendsNode)));
      tree := LookupTree.fold(ext_tree,
        function expandExtends2(
          classIndex = classIndex - 1,
          componentIndex = componentIndex - 1,
          duplicates = duplicates),
        tree);
    end expandExtends;

    function expandExtends2
      input String name;
      input LookupTree.Entry entry;
      input Integer classIndex;
      input Integer componentIndex;
      input DoubleEndedList<LookupTree.Entry> duplicates;
      input output LookupTree.Tree tree;
    algorithm
      () := match entry
        case LookupTree.Entry.CLASS()
          algorithm
            tree := addInheritedClass(name, classIndex + entry.index, tree, duplicates);
          then
            ();

        case LookupTree.Entry.COMPONENT()
          algorithm
            tree := addInheritedComponent(name, componentIndex + entry.index, tree, duplicates);
          then
            ();

        else ();
      end match;
    end expandExtends2;
  end ClassTree;

annotation(__OpenModelica_Interface="frontend");
end NFClassTree;

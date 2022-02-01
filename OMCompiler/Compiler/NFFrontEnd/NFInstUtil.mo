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

encapsulated package NFInstUtil
  import ComponentRef = NFComponentRef;
  import Call = NFCall;
  import Expression = NFExpression;
  import FlatModel = NFFlatModel;
  import NFInstNode.InstNode;
  import NFFlatten.FunctionTree;
  import NFFunction.Function;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;
  import Algorithm = NFAlgorithm;
  import Statement = NFStatement;
  import Equation = NFEquation;
  import SCode;
  import Absyn;

protected
  import AbsynUtil;
  import SCodeUtil;
  import Dump;
  import Flags;
  import UnorderedMap;
  import MetaModelica.Dangerous.listReverseInPlace;
  import SCodeDump;
  import ExecStat.execStat;

public
  function dumpFlatModelDebug
    input String stage;
    input FlatModel flatModel;
    input FunctionTree functions = FunctionTree.new();
  protected
    FlatModel flat_model = flatModel;
  algorithm
    // --dumpFlatModel=stage dumps specific stages, --dumpFlatModel dumps all stages.
    if Flags.isConfigFlagSet(Flags.DUMP_FLAT_MODEL, stage) or
       listEmpty(Flags.getConfigStringList(Flags.DUMP_FLAT_MODEL)) then
      flat_model := combineSubscripts(flatModel);

      print("########################################\n");
      print(stage);
      print("\n########################################\n\n");

      if Flags.getConfigBool(Flags.FLAT_MODELICA) then
        FlatModel.printFlatString(flat_model, FunctionTree.listValues(functions));
      else
        FlatModel.printString(flat_model);
      end if;

      print("\n");
    end if;
  end dumpFlatModelDebug;

  function combineSubscripts
    input output FlatModel flatModel;
  algorithm
    if Flags.isSet(Flags.COMBINE_SUBSCRIPTS) then
      flatModel := FlatModel.mapExp(flatModel, combineSubscriptsExp);
    end if;
  end combineSubscripts;

  function combineSubscriptsExp
    input output Expression exp;
  protected
    function traverser
      input output Expression exp;
    algorithm
      () := match exp
        case Expression.CREF()
          algorithm
            exp.cref := ComponentRef.combineSubscripts(exp.cref);
          then
            ();

        else ();
      end match;
    end traverser;
  algorithm
    exp := Expression.map(exp, traverser);
  end combineSubscriptsExp;

  function printStructuralParameters
    input FlatModel flatModel;
  protected
    list<Variable> params;
    list<String> names;
  algorithm
    if Flags.isSet(Flags.PRINT_STRUCTURAL) then
      params := list(v for v guard Variable.isStructural(v) in flatModel.variables);

      if not listEmpty(params) then
        names := list(ComponentRef.toString(v.name) for v in params);
        Error.addMessage(Error.NOTIFY_FRONTEND_STRUCTURAL_PARAMETERS,
          {stringDelimitList(names, ", ")});
      end if;
    end if;
  end printStructuralParameters;

  function dumpFlatModel
    input FlatModel flatModel;
    input FunctionTree functions;
    output String str;
  protected
    FlatModel flat_model;
  algorithm
    flat_model := combineSubscripts(flatModel);
    str := FlatModel.toFlatString(flat_model, FunctionTree.listValues(functions));
  end dumpFlatModel;

  function replaceEmptyArrays
    input output FlatModel flatModel;
  algorithm
    flatModel := FlatModel.mapExp(flatModel, replaceEmptyArraysExp);
  end replaceEmptyArrays;

  function replaceEmptyArraysExp
    "Variables with 0-dimensions are not present in the flat model, so replace
     any cref that refers to such a variable with an empty array expression."
    input output Expression exp;
  protected
    function traverser
      input Expression exp;
      output Expression outExp;
    protected
      ComponentRef cref;
      list<Subscript> subs;
      Type ty;
    algorithm
      outExp := match exp
        case Expression.CREF(cref = cref)
          guard ComponentRef.isEmptyArray(cref)
          algorithm
            if ComponentRef.hasSubscripts(cref) then
              cref := ComponentRef.fillSubscripts(cref);
              cref := ComponentRef.replaceWholeSubscripts(cref);
              subs := ComponentRef.subscriptsAllFlat(cref);
              cref := ComponentRef.stripSubscriptsAll(cref);
              ty := ComponentRef.getSubscriptedType(cref);
            else
              subs := {};
              ty := exp.ty;
            end if;

            outExp := Expression.makeDefaultValue(ty);

            if not listEmpty(subs) then
              outExp := Expression.SUBSCRIPTED_EXP(outExp, subs, exp.ty, false);
            end if;
          then
            outExp;

        else exp;
      end match;
    end traverser;
  algorithm
    exp := Expression.map(exp, traverser);
  end replaceEmptyArraysExp;

  function expandSlicedCrefs
    input output FlatModel flatModel;
    input output FunctionTree functions;
  algorithm
    if Flags.isSet(Flags.COMBINE_SUBSCRIPTS) or not Flags.isSet(Flags.NF_SCALARIZE) then
      return;
    end if;

    flatModel.variables := list(Variable.mapExp(v, expandSlicedCrefsExp) for v in flatModel.variables);
    flatModel := FlatModel.mapEquations(flatModel, expandSlicedCrefsEq);
    flatModel := FlatModel.mapAlgorithms(flatModel, expandSlicedCrefsAlg);
    functions := FunctionTree.map(functions, expandSlicedCrefsFunction);
  end expandSlicedCrefs;

  function expandSlicedCrefsExp
    input output Expression exp;
  algorithm
    exp := match exp
      case Expression.CREF()
        guard ComponentRef.isSliced(exp.cref)
        then expandSlicedCrefsExp2(exp.cref, exp.ty);

      else exp;
    end match;
  end expandSlicedCrefsExp;

  function expandSlicedCrefsExp2
    input ComponentRef cref;
    input Type ty;
    output Expression outExp;
  protected
    ComponentRef cr;
    list<tuple<InstNode, Expression>> iterators;
  algorithm
    (cr, iterators) := ComponentRef.iterate(cref);
    outExp := Expression.CALL(
      Call.TYPED_ARRAY_CONSTRUCTOR(
        ty,
        ComponentRef.variability(cref),
        ComponentRef.purity(cref),
        Expression.fromCref(cr),
        iterators
      )
    );
  end expandSlicedCrefsExp2;

  function expandSlicedCrefsEq
    input output Equation eq;
  protected
    Expression e1, e2;
  algorithm
    eq := match eq
      case Equation.EQUALITY(rhs = e1)
        algorithm
          e2 := Expression.map(e1, expandSlicedCrefsExp);

          if not referenceEq(e1, e2) then
            eq.rhs := e2;
          end if;
        then
          eq;

      case Equation.ARRAY_EQUALITY(rhs = e1)
        algorithm
          e2 := Expression.map(e1, expandSlicedCrefsExp);

          if not referenceEq(e1, e2) then
            eq.rhs := e2;
          end if;
        then
          eq;

      else Equation.mapExpShallow(eq, function Expression.map(func = expandSlicedCrefsExp));
    end match;
  end expandSlicedCrefsEq;

  function expandSlicedCrefsAlg
    input output Algorithm alg;
  algorithm
    alg.statements := list(Statement.map(s, expandSlicedCrefsStmt) for s in alg.statements);
  end expandSlicedCrefsAlg;

  function expandSlicedCrefsStmt
    input output Statement stmt;
  protected
    Expression e1, e2;
  algorithm
    stmt := match stmt
      case Statement.ASSIGNMENT(rhs = e1)
        algorithm
          e2 := Expression.map(e1, expandSlicedCrefsExp);

          if not referenceEq(e1, e2) then
            stmt.rhs := e2;
          end if;
        then
          stmt;

      else Statement.mapExpShallow(stmt, function Expression.map(func = expandSlicedCrefsExp));
    end match;
  end expandSlicedCrefsStmt;

  function expandSlicedCrefsFunction
    input Absyn.Path fnPath;
    input output Function fn;
  algorithm
    fn := Function.mapExp(fn,
      function Expression.map(func = expandSlicedCrefsExp), mapBody = false);
    fn := Function.mapBody(fn, expandSlicedCrefsAlg);
  end expandSlicedCrefsFunction;

  function mergeScalars
    "Tries to merge components inside the given class into arrays. Components
     can be merged if they have e.g. the same type, same prefixes, same
     modifiers, etc."
    input output InstNode node;
  protected
    SCode.Element elem;
  algorithm
    if not Flags.isSet(Flags.MERGE_COMPONENTS) then
      return;
    end if;

    elem := InstNode.definition(node);
    elem := mergeScalars2(elem);
    node := InstNode.setDefinition(elem, node);
    execStat(getInstanceName());
  end mergeScalars;

  function mergeScalars2
    "Helper function to mergeScalars, does the actual merging."
    input output SCode.Element cls;
  protected
    SCode.ClassDef cdef;
    list<SCode.Element> elems;
    UnorderedMap<String, Absyn.ComponentRef> name_map;
  algorithm
    () := match cls
      case SCode.Element.CLASS(classDef = cdef as SCode.ClassDef.PARTS())
        algorithm
          // Merge components.
          (elems, name_map) := mergeScalars3(cdef.elementLst);
          cdef.elementLst := elems;
          // Replace references to merged components with their new names.
          cdef.normalEquationLst := mergeScalarsEql(cdef.normalEquationLst, name_map);
          cdef.initialEquationLst := mergeScalarsEql(cdef.initialEquationLst, name_map);
          cdef.normalAlgorithmLst := mergeScalarsAlgs(cdef.normalAlgorithmLst, name_map);
          cdef.initialAlgorithmLst := mergeScalarsAlgs(cdef.initialAlgorithmLst, name_map);
          cls.classDef := cdef;
        then
          ();

      else ();
    end match;
  end mergeScalars2;

  function mergeScalars3
    "Helper function to mergeScalars2. Takes a list of elements and returns a
     new list with components merged, as well as a map of the merged components'
     old names to their new names."
    input list<SCode.Element> elements;
    output list<SCode.Element> outElements;
    output UnorderedMap<String, Absyn.ComponentRef> outNameMap;
  protected
    list<list<SCode.Element>> mergeable;
    SCode.Element merged_e;
    Integer i = 1;
    Absyn.TypeSpec ty;
    String prefix;
  algorithm
    // Find the groups of mergeable component.
    (mergeable, outElements) := makeMergeMap(elements);
    outNameMap := UnorderedMap.new<Absyn.ComponentRef>(stringHashDjb2Mod, stringEq);

    // Merge each group of mergeable components.
    for el in mergeable loop
      // The name of the merged component will be $LastIdentInTypeOfComponent +
      // an index to ensure the name is unique.
      ty := SCodeUtil.getComponentTypeSpec(listHead(el));
      prefix := "$" + AbsynUtil.pathLastIdent(AbsynUtil.typeSpecPath(ty));
      merged_e := mergeComponents(el, prefix + String(i), outNameMap);
      i := i + 1;
      outElements := merged_e :: outElements;
    end for;

    outElements := listReverseInPlace(outElements);
  end mergeScalars3;

  function makeMergeMap
    "Takes a list of elements and returns a list of mergeable component groups
     and a list of all other unmergeable elements."
    input list<SCode.Element> elements;
    output list<list<SCode.Element>> mergeable = {};
    output list<SCode.Element> unmergeable = {};
  protected
    type ElementList = list<SCode.Element>;
    UnorderedMap<String, ElementList> merge_map;
    list<list<SCode.Element>> grouped_elems;

    function append_merge
      input Option<list<SCode.Element>> oldValue;
      input SCode.Element elem;
      output list<SCode.Element> newValue;
    algorithm
      if isSome(oldValue) then
        SOME(newValue) := oldValue;
      else
        newValue := {};
      end if;

      newValue := elem :: newValue;
    end append_merge;
  algorithm
    merge_map := UnorderedMap.new<ElementList>(stringHashDjb2Mod, stringEq);

    // Group the components by their signature if they fulfill the requirements
    // for being considered mergeable.
    for e in elements loop
      () := match e
        case SCode.Element.COMPONENT()
          guard isMergeableComponent(e)
          algorithm
            UnorderedMap.addUpdate(getComponentSignature(e),
              function append_merge(elem = e), merge_map);
          then
            ();

        else
          algorithm
            unmergeable := e :: unmergeable;
          then
            ();
      end match;
    end for;

    grouped_elems := UnorderedMap.valueList(merge_map);

    // Move single mergeable components to the list of unmergeables.
    for el in grouped_elems loop
      if listLength(el) == 1 then
        unmergeable := listHead(el) :: unmergeable;
      else
        mergeable := listReverseInPlace(el) :: mergeable;
      end if;
    end for;
  end makeMergeMap;

  function isMergeableComponent
    "Returns true if an element is a component that is considered to be
     mergeable, otherwise false. A component is considered to be not mergeable
     if it is e.g. a redeclare or inner/outer."
    input SCode.Element element;
    output Boolean isMergeable;
  algorithm
    isMergeable := match element
      case SCode.Element.COMPONENT(attributes = SCode.Attributes.ATTR(arrayDims = {}),
                                   prefixes = SCode.Prefixes.PREFIXES(
                                     redeclarePrefix = SCode.Redeclare.NOT_REDECLARE(),
                                     innerOuter = Absyn.InnerOuter.NOT_INNER_OUTER(),
                                     replaceablePrefix = SCode.Replaceable.NOT_REPLACEABLE()),
                                   condition = NONE())
        then isMergeableType(element.typeSpec) and isMergeableMod(element.modifications);

      else false;
    end match;
  end isMergeableComponent;

  function isMergeableMod
    input SCode.Mod mod;
    output Boolean mergeable;
  algorithm
    mergeable := match mod
      case SCode.MOD(eachPrefix = SCode.Each.NOT_EACH())
        algorithm
          for m in mod.subModLst loop
            if not isMergeableMod(m.mod) then
              mergeable := false;
              return;
            end if;
          end for;
        then
          true;

      case SCode.NOMOD() then true;
      else false;
    end match;
  end isMergeableMod;

  function isMergeableType
    input Absyn.TypeSpec ty;
    output Boolean mergeable;
  algorithm
    mergeable := match ty
      case Absyn.TPATH(arrayDim = NONE()) then true;
      else false;
    end match;
  end isMergeableType;

  function getComponentSignature
    "Creates a signature string for a component which consists of the components
     attributes, type, and modifiers, that can be used to group similar
     components together."
    input SCode.Element element;
    output String signature;
  protected
    SCode.Prefixes prefs;
    SCode.Attributes attrs;
    Absyn.TypeSpec ty;
    SCode.Mod mod;
  algorithm
    SCode.Element.COMPONENT(prefixes = prefs, attributes = attrs, typeSpec = ty,
      modifications = mod) := element;

    signature := stringAppendList({
      SCodeDump.visibilityStr(prefs.visibility),
      SCodeDump.finalStr(prefs.finalPrefix),
      SCodeDump.connectorTypeStr(attrs.connectorType),
      SCodeDump.variabilityString(attrs.variability),
      Dump.unparseDirectionSymbolStr(attrs.direction),
      Dump.unparseTypeSpec(ty),
      getModSignature(mod)
    });
  end getComponentSignature;

  function getModSignature
    "Creates a signature string for a modifier that can be hashed in order to
     group similar modifiers. The signature is similar to the string
     representation of the modifier with the binding expressions removed, e.g.:

       (x=3, y(start=1)=4, m(a=1)) => '(m(a=,),x=,y(start=,)=,)'

     Submodifiers are also sorted by their names, so (x=3, y=4) and (y=4, x=3)
     both have the signature '(x=,y=,)'."
    input SCode.Mod mod;
    input String name = "";
    output String signature;
  protected
    function sub_mod_lt
      input SCode.SubMod m1;
      input SCode.SubMod m2;
      output Boolean res = m1.ident < m2.ident;
    end sub_mod_lt;

    list<String> strl = {};
    Boolean has_binding, has_submods;
  algorithm
    signature := match mod
      case SCode.Mod.MOD()
        algorithm
          has_binding := isSome(mod.binding);
          has_submods := not listEmpty(mod.subModLst);

          if has_binding then
            strl := "=" :: strl;
          end if;

          if has_submods then
            strl := ")" :: strl;

            for m in List.sort(mod.subModLst, sub_mod_lt) loop
              strl := "," :: strl;
              strl := getModSignature(m.mod, m.ident) :: strl;
            end for;

            strl := "(" :: strl;
          end if;

          if has_binding or has_submods then
            strl := name :: strl;
          end if;

          if SCodeUtil.finalBool(mod.finalPrefix) then
            strl := "final " :: strl;
          end if;

          if SCodeUtil.eachBool(mod.eachPrefix) then
            strl := "each " :: strl;
          end if;
        then
          stringAppendList(strl);

      else "";
    end match;
  end getModSignature;

  function mergeComponents
    "Merges a list of components into a single component."
    input list<SCode.Element> components;
    input String prefix;
    input UnorderedMap<String, Absyn.ComponentRef> nameMap;
    output SCode.Element mergedComponent;
  protected
    Absyn.TypeSpec ty;
    SCode.Prefixes prefs;
    SCode.Attributes attrs;
    SCode.Mod mod;
    Integer i = 1;
    String name;
    Absyn.ComponentRef cref;
    list<SCode.Mod> mods;
  algorithm
    // All components should have the same type and attributes, so take them
    // from the first component in the list.
    SCode.Element.COMPONENT(typeSpec = ty,
                            prefixes = prefs,
                            attributes = attrs) := listHead(components);

    // Add a dimension equal to the number of components.
    attrs.arrayDims := {AbsynUtil.makeIntegerSubscript(listLength(components))};

    // Merge the modifiers into a single modifier.
    mods := list(SCodeUtil.componentMod(c) for c in components);
    mod := mergeMods(mods);

    mergedComponent := SCode.Element.COMPONENT(
      prefix,
      prefs,
      attrs,
      ty,
      mod,
      SCode.noComment,
      NONE(),
      AbsynUtil.dummyInfo
    );

    // Add a mapping from old name to new name for each of the merged components.
    for c in components loop
      SCode.Element.COMPONENT(name = name) := c;
      cref := Absyn.ComponentRef.CREF_IDENT(prefix, {AbsynUtil.makeIntegerSubscript(i)});
      i := i + 1;
      UnorderedMap.addUnique(name, cref, nameMap);
    end for;
  end mergeComponents;

  function mergeMods
    "Merges a list of modifiers into one modifier. All modifiers are assumed to
     be equal with exception for binding expressions."
    input list<SCode.Mod> mods;
    output SCode.Mod mod;
  protected
    list<Absyn.Path> names;
    list<list<Absyn.Exp>> bindings;
    UnorderedMap<Absyn.Path, Absyn.Exp> binding_map;
  algorithm
    if listEmpty(mods) then
      mod := SCode.Mod.NOMOD();
      return;
    end if;

    // Get the paths of all the modified elements.
    mod := listHead(mods);
    names := getModNames(mod);
    bindings := List.fill({}, listLength(names));

    // Collect the bindings from all modifiers.
    for m in listReverse(mods) loop
      bindings := getModBindings(m, names, bindings);
    end for;

    // Make a name => binding map.
    binding_map := UnorderedMap.fromLists<Absyn.Exp>(names,
      listReverse(Absyn.Exp.ARRAY(b) for b in bindings),
      AbsynUtil.pathHashMod, AbsynUtil.pathEqual);

    // Use one the modifiers as a template and replace the bindings in it with
    // the merged bindings, in order to preserve 'each' and 'final'.
    mod := mergeMods2(mod, binding_map);
  end mergeMods;

  function getModNames
    "Returns a list of the modified names in a modifier, e.g.:
       (x = 4, y(start = 1) = 3, m(a = 2)) => {x, y, y.start, m.a}"
    input SCode.Mod mod;
    input list<String> name = {};
    input output list<Absyn.Path> names = {};
  algorithm
    names := match mod
      case SCode.Mod.MOD()
        algorithm
          if isSome(mod.binding) then
            names := AbsynUtil.stringListPathReversed(name) :: names;
          end if;

          for m in mod.subModLst loop
            names := getModNames(m.mod, m.ident :: name, names);
          end for;
        then
          names;

      else names;
    end match;
  end getModNames;

  function mergeMods2
    "Helper function to mergeMods, replaces bindings in the given modifier with
     the merged bindings."
    input output SCode.Mod mod;
    input UnorderedMap<Absyn.Path, Absyn.Exp> bindingMap;
    input list<String> name = {};
  protected
    Absyn.Exp new_binding;
    list<SCode.SubMod> submods = {};
  algorithm
    () := match mod
      case SCode.Mod.MOD()
        algorithm
          // If the modifier has a binding expression, look up the new binding
          // in the map and replace it.
          if isSome(mod.binding) then
            new_binding := UnorderedMap.getOrFail(AbsynUtil.stringListPathReversed(name), bindingMap);
            mod.binding := SOME(new_binding);
          end if;

          // Recursively do the same to the submodifiers.
          if not listEmpty(mod.subModLst) then
            for m in mod.subModLst loop
              m.mod := mergeMods2(m.mod, bindingMap, m.ident :: name);
              submods := m :: submods;
            end for;

            mod.subModLst := listReverseInPlace(submods);
          end if;
        then
          ();

      else ();
    end match;
  end mergeMods2;

  function getModBindings
    "Looks up the named bindings in a modifier and appends them to the binding
     expression lists."
    input SCode.Mod mod;
    input list<Absyn.Path> names;
    input output list<list<Absyn.Exp>> bindings;
  protected
    list<Absyn.Exp> mod_bindings = {};
  algorithm
    for name in names loop
      mod_bindings := lookupModBinding(name, mod) :: mod_bindings;
    end for;

    bindings := List.threadMap(mod_bindings, bindings, cons);
  end getModBindings;

  function lookupModBinding
    "Looks up the binding expression for the modifier given by the path."
    input Absyn.Path name;
    input SCode.Mod mod;
    output Absyn.Exp binding;
  protected
    SCode.Mod m;
  algorithm
    SCode.Mod.MOD(binding = SOME(binding)) := lookupMod(name, mod);
  end lookupModBinding;

  function lookupMod
    "Looks up the modifier given by the path."
    input Absyn.Path name;
    input SCode.Mod mod;
    output SCode.Mod outMod;
  algorithm
    outMod := match name
      case Absyn.Path.IDENT()
        then SCodeUtil.lookupModInMod(name.name, mod);

      case Absyn.Path.QUALIFIED()
        algorithm
          outMod := SCodeUtil.lookupModInMod(name.name, mod);
        then
          lookupMod(name.path, outMod);
    end match;
  end lookupMod;

  function mergeScalarsEql
    "Updates the names of merged components in a list of equations."
    input output list<SCode.Equation> eql;
    input UnorderedMap<String, Absyn.ComponentRef> nameMap;
  algorithm
    eql := SCodeUtil.mapEquationsList(eql, function mergeScalarsEq(nameMap = nameMap));
  end mergeScalarsEql;

  function mergeScalarsEq
    "Updates the names of merged components in an equation."
    input output SCode.EEquation eq;
    input UnorderedMap<String, Absyn.ComponentRef> nameMap;
  algorithm
    eq := SCodeUtil.mapEEquationExps(eq, function mergeScalarsExps(nameMap = nameMap));

    () := match eq
      case SCode.EEquation.EQ_CONNECT()
        algorithm
          eq.crefLeft := mergeScalarsCref(eq.crefLeft, nameMap);
          eq.crefRight := mergeScalarsCref(eq.crefRight, nameMap);
        then
          ();

      else ();
    end match;
  end mergeScalarsEq;

  function mergeScalarsExps
    "Updates the names of merged components in an expression."
    input output Absyn.Exp exp;
    input UnorderedMap<String, Absyn.ComponentRef> nameMap;
  algorithm
    exp := AbsynUtil.traverseExp(exp, mergeScalarsExp, nameMap);
  end mergeScalarsExps;

  function mergeScalarsExp
    input output Absyn.Exp exp;
    input output UnorderedMap<String, Absyn.ComponentRef> nameMap;
  algorithm
    () := match exp
      case Absyn.Exp.CREF()
        guard not AbsynUtil.crefIsWild(exp.componentRef)
        algorithm
          exp.componentRef := mergeScalarsCref(exp.componentRef, nameMap);
        then
          ();

      else ();
    end match;
  end mergeScalarsExp;

  function mergeScalarsCref
    "Updates the names of a component reference if it refers to a merged component."
    input output Absyn.ComponentRef cref;
    input UnorderedMap<String, Absyn.ComponentRef> nameMap;
  protected
    Option<Absyn.ComponentRef> repl_ocr;
    Absyn.ComponentRef repl_cr;
    list<Absyn.Subscript> subs;
  algorithm
    // Look up the first part of the cref in the name map.
    repl_ocr := UnorderedMap.get(AbsynUtil.crefFirstIdent(cref), nameMap);

    // If a replacement was found...
    if isSome(repl_ocr) then
      SOME(repl_cr) := repl_ocr;
      // The new name has a subscript that needs to be merged with any existing subscripts.
      subs := AbsynUtil.crefFirstSubs(cref);

      if not listEmpty(subs) then
        subs := listAppend(AbsynUtil.crefFirstSubs(repl_cr), subs);
        repl_cr := AbsynUtil.crefSetLastSubs(repl_cr, subs);
      end if;

      // Replace the first part of the cref with the new part.
      cref := AbsynUtil.crefReplaceFirst(cref, repl_cr);
    end if;
  end mergeScalarsCref;

  function mergeScalarsAlgs
    "Updates the names of merged components in a list of algorithm sections."
    input output list<SCode.AlgorithmSection> algs;
    input UnorderedMap<String, Absyn.ComponentRef> nameMap;
  algorithm
    algs := list(SCodeUtil.mapAlgorithmStatements(a,
      function mergeScalarsStmt(nameMap = nameMap)) for a in algs);
  end mergeScalarsAlgs;

  function mergeScalarsStmt
    "Updates the names of merged components in a statement."
    input output SCode.Statement stmt;
    input UnorderedMap<String, Absyn.ComponentRef> nameMap;
  algorithm
    stmt := SCodeUtil.mapStatementExps(stmt, function mergeScalarsExps(nameMap = nameMap));
  end mergeScalarsStmt;

annotation(__OpenModelica_Interface="frontend");
end NFInstUtil;

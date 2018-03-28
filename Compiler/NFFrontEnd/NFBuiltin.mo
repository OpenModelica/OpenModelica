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


encapsulated package NFBuiltin
" file:        NFBuiltin.mo
  package:     NFBuiltin
  description: Builtin definitions.


  Definitions for various builtin Modelica types and variables that can't be
  defined by ModelicaBuiltin.mo.
  "

public
import Absyn;
import SCode;
import Binding = NFBinding;
import BindingOrigin = NFBindingOrigin;
import NFClass.Class;
import NFClassTree.ClassTree;
import NFComponent.Component;
import Expression = NFExpression;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import NFModifier.Modifier;
import Type = NFType;
import BuiltinFuncs = NFBuiltinFuncs;
import Pointer;
import NFPrefixes.Variability;
import NFPrefixes.Visibility;
import ComponentRef = NFComponentRef;
import NFComponentRef.Origin;
import Restriction = NFRestriction;

protected
import MetaModelica.Dangerous.*;

public
encapsulated package Elements
  import SCode;
  import Absyn;

  // Default parts of the declarations for builtin elements and types:
  public constant Absyn.TypeSpec ENUMTYPE_SPEC =
    Absyn.TPATH(Absyn.IDENT("$EnumType"), NONE());

  // StateSelect-specific elements:
  constant SCode.Element REAL = SCode.CLASS("Real",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, Absyn.dummyInfo);

  constant SCode.Element INTEGER = SCode.CLASS("Integer",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, Absyn.dummyInfo);

  constant SCode.Element BOOLEAN = SCode.CLASS("Boolean",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, Absyn.dummyInfo);

  constant SCode.Element STRING = SCode.CLASS("String",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, Absyn.dummyInfo);

  constant SCode.Element ENUMERATION = SCode.CLASS("enumeration",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, Absyn.dummyInfo);

  constant SCode.Element ANY = SCode.CLASS("polymorphic",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, Absyn.dummyInfo);

end Elements;

// An empty InstNode cache for the builtin types. This should really be an empty
// array to make sure all attempts at using the cache fails, since trying to
// update the cache of a constant literal would cause a segfault. Creating a
// completely empty array here doesn't work due to compiler bugs though
// (generates invalid C code), but this is probably close enough.
constant array<NFInstNode.CachedData> EMPTY_NODE_CACHE = listArrayLiteral({
  NFInstNode.CachedData.FUNCTION({}, true, true)
});

// InstNodes for the builtin types. These have empty class trees to prevent
// access to the attributes via dot notation (which is not needed for
// modifiers and illegal in other cases).
constant InstNode POLYMORPHIC_NODE = InstNode.CLASS_NODE("polymorphic",
  Elements.ANY, Visibility.PUBLIC,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.POLYMORPHIC(""), ClassTree.EMPTY_TREE(),
    Modifier.NOMOD(), Restriction.TYPE())),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant InstNode REAL_NODE = InstNode.CLASS_NODE("Real",
  Elements.REAL, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.REAL(), ClassTree.EMPTY_TREE(), Modifier.NOMOD(), Restriction.TYPE())),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant InstNode INTEGER_NODE = InstNode.CLASS_NODE("Integer",
  Elements.INTEGER, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.INTEGER(), ClassTree.EMPTY_TREE(), Modifier.NOMOD(), Restriction.TYPE())),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant InstNode BOOLEAN_NODE = InstNode.CLASS_NODE("Boolean",
  Elements.BOOLEAN, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.BOOLEAN(), ClassTree.EMPTY_TREE(), Modifier.NOMOD(), Restriction.TYPE())),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant ComponentRef BOOLEAN_CREF =
  ComponentRef.CREF(BOOLEAN_NODE, {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

constant InstNode STRING_NODE = InstNode.CLASS_NODE("String",
  Elements.STRING, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.STRING(), ClassTree.EMPTY_TREE(), Modifier.NOMOD(), Restriction.TYPE())),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant InstNode ENUM_NODE = InstNode.CLASS_NODE("enumeration",
  Elements.ENUMERATION, Visibility.PUBLIC,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.ENUMERATION_ANY(), ClassTree.EMPTY_TREE(),
    Modifier.NOMOD(), Restriction.ENUMERATION())),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant Type STATESELECT_TYPE = Type.ENUMERATION(
  Absyn.IDENT("StateSelect"), {"never", "avoid", "default", "prefer", "always"});

constant Type ASSERTIONLEVEL_TYPE = Type.ENUMERATION(
  Absyn.IDENT("AssertionLevel"), {"error", "warning"});

constant Expression ASSERTIONLEVEL_ERROR = Expression.ENUM_LITERAL(
  ASSERTIONLEVEL_TYPE, "error", 1);

constant Expression ASSERTIONLEVEL_WARNING = Expression.ENUM_LITERAL(
  ASSERTIONLEVEL_TYPE, "error", 2);

constant InstNode TIME =
  InstNode.COMPONENT_NODE("time",
    Visibility.PUBLIC,
    Pointer.createImmutable(Component.TYPED_COMPONENT(
      REAL_NODE,
      Type.REAL(),
      Binding.UNBOUND(),
      Binding.UNBOUND(),
      NFComponent.INPUT_ATTR,
      NONE(),
      Absyn.dummyInfo)),
    0,
    InstNode.EMPTY_NODE());

constant ComponentRef TIME_CREF = ComponentRef.CREF(TIME, {}, Type.REAL(), Origin.CREF, ComponentRef.EMPTY());

annotation(__OpenModelica_Interface="frontend");
end NFBuiltin;

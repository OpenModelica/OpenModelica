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

// Rust-only declarations for NFBuiltinFuncs; see mmtorust/src/overrides.rs.
//
// As NFBuiltin.rust.mo: a constant spells out every field, so the crefs and
// the builtin nodes are written out with the Rust port's representation.
encapsulated package NFBuiltinFuncs
  constant ComponentRef INTEGER_CREF =
    ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(INTEGER_NODE), {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

  constant ComponentRef STRING_CREF =
    ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(STRING_NODE), {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

  constant ComponentRef CLOCK_CREF =
    ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(CLOCK_NODE), {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

constant InstNode INT_PARAM = InstNode.COMPONENT_NODE("i",
  NONE(), Visibility.PUBLIC,
  Pointer.createImmutable(INT_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE,
  InstNodeType.NORMAL_COMP());

constant InstNode REAL_PARAM = InstNode.COMPONENT_NODE("r",
  NONE(), Visibility.PUBLIC,
  Pointer.createImmutable(REAL_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE,
  InstNodeType.NORMAL_COMP());

constant InstNode BOOL_PARAM = InstNode.COMPONENT_NODE("b",
  NONE(), Visibility.PUBLIC,
  Pointer.createImmutable(BOOL_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE,
  InstNodeType.NORMAL_COMP());

constant InstNode STRING_PARAM = InstNode.COMPONENT_NODE("s",
  NONE(), Visibility.PUBLIC,
  Pointer.createImmutable(STRING_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE,
  InstNodeType.NORMAL_COMP());

constant InstNode ENUM_PARAM = InstNode.COMPONENT_NODE("e",
  NONE(), Visibility.PUBLIC,
  Pointer.createImmutable(ENUM_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE,
  InstNodeType.NORMAL_COMP());

constant InstNode INTEGER_DUMMY_NODE = NFInstNode.CLASS_NODE("Integer",
  DUMMY_ELEMENT, Visibility.PUBLIC, Pointer.createImmutable(Class.NOT_INSTANTIATED()),
  EMPTY_NODE_CACHE,
  NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_CLASS());

constant InstNode INTEGER_NODE = InstNode.CLASS_NODE("IntegerFunc",
  DUMMY_ELEMENT, Visibility.PUBLIC,
  Pointer.createImmutable(Class.INSTANCED_CLASS(Type.UNKNOWN(), ClassTree.EMPTY_TREE(),
    Sections.EMPTY(), NFClass.DEFAULT_PREFIXES, Restriction.FUNCTION())),
  listArrayLiteral({NFInstNode.CachedData.FUNCTION({INTEGER_FUNCTION}, true, false),
                    NFInstNode.CachedData.NO_CACHE(),
                    NFInstNode.CachedData.NO_CACHE()}),
  NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.BUILTIN_CLASS());

constant InstNode STRING_DUMMY_NODE = NFInstNode.CLASS_NODE("String",
  DUMMY_ELEMENT, Visibility.PUBLIC, Pointer.createImmutable(Class.NOT_INSTANTIATED()),
  EMPTY_NODE_CACHE, NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_CLASS());

constant InstNode R_PARAM = InstNode.COMPONENT_NODE("r", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(REAL_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode I_PARAM = InstNode.COMPONENT_NODE("i", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(INT_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode B_PARAM = InstNode.COMPONENT_NODE("b", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(BOOL_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode E_PARAM = InstNode.COMPONENT_NODE("e", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(ENUM_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode SIGNIFICANT_DIGITS_PARAM = InstNode.COMPONENT_NODE("significantDigits", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(INT_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode MINIMUM_LENGTH_PARAM = InstNode.COMPONENT_NODE("minimumLength", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(INT_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode LEFT_JUSTIFIED_PARAM = InstNode.COMPONENT_NODE("leftJustified", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(BOOL_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode FORMAT_PARAM = InstNode.COMPONENT_NODE("format", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(STRING_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode STRING_NODE = InstNode.CLASS_NODE("String",
  DUMMY_ELEMENT, Visibility.PUBLIC,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.STRING(), ClassTree.EMPTY_TREE(),
    Modifier.NOMOD(), NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  listArrayLiteral({
    NFInstNode.CachedData.FUNCTION({
        STRING_ENUM,
        STRING_INT,
        STRING_BOOL,
        STRING_REAL,
        STRING_REAL_FORMAT},
      true, true),
    NFInstNode.CachedData.NO_CACHE(),
    NFInstNode.CachedData.NO_CACHE()}
  ),
  NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.BUILTIN_CLASS());

constant InstNode CLOCK_PARAM = InstNode.COMPONENT_NODE("s",
  NONE(), Visibility.PUBLIC,
  Pointer.createImmutable(CLOCK_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE,
  InstNodeType.NORMAL_COMP());

constant InstNode CLOCK_DUMMY_NODE = NFInstNode.CLASS_NODE("Clock",
  DUMMY_ELEMENT, Visibility.PUBLIC, Pointer.createImmutable(Class.NOT_INSTANTIATED()),
  EMPTY_NODE_CACHE, NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_CLASS());

constant InstNode INTERVAL_COUNTER_PARAM = InstNode.COMPONENT_NODE("intervalCounter", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(INT_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode RESOLUTION_PARAM = InstNode.COMPONENT_NODE("resolution", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(INT_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode INTERVAL_PARAM = InstNode.COMPONENT_NODE("interval", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(REAL_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode CONDITION_PARAM = InstNode.COMPONENT_NODE("condition", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(BOOL_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode START_INTERVAL_PARAM = InstNode.COMPONENT_NODE("startInterval", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(REAL_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode C_PARAM = InstNode.COMPONENT_NODE("c", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(CLOCK_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode SOLVER_METHOD_PARAM = InstNode.COMPONENT_NODE("solverMethod", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(STRING_COMPONENT), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP());

constant InstNode CLOCK_NODE = InstNode.CLASS_NODE("Clock",
  DUMMY_ELEMENT, Visibility.PUBLIC,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.CLOCK(), ClassTree.EMPTY_TREE(),
    Modifier.NOMOD(), NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  listArrayLiteral({
    NFInstNode.CachedData.FUNCTION({
        CLOCK_INFERRED,
        CLOCK_INT,
        CLOCK_REAL,
        CLOCK_BOOL,
        CLOCK_SOLVER
        },
      true, true),
    NFInstNode.CachedData.NO_CACHE(),
    NFInstNode.CachedData.NO_CACHE()}
  ),
  NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.BUILTIN_CLASS());

end NFBuiltinFuncs;

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

encapsulated package Error
"
  file:        Error.mo
  package:     Error
  description: Error handling


  This file contains the Error handling for the Compiler. The following steps
  are used to add a new error message:

    1) Add a new ErrorID constant below with an unique id.

    2) Add a new entry in the errorTable. Each entry is a tuple consisting of
       the ErrorID, a MessageType, a Severity and a message string. See the
       MessageType and Severity uniontypes below for more information about
       them.

      The message string is the error message that should be displayed, which
      may contain directives to insert tokens given when the message is used.
      These directives are:

        %s: Inserts the next token in the list.
        %n: Inserts token number n in the list, where n is a number from 1 to 9.

      Note that these two directives do not affect each other. I.e. %s will move
      to the next token in the list regardless of any positional directives, and
      %1 will always point to the first token regardless of any %s before it.
      An example:

        Message: '%2: This is a %s of %2 %s and %1'
        Tokens: {'test', 'error', 'directives', 'messages'}
        Result: 'error: This is a test of error messages and directives'

    3) Use the new error message by calling addSourceMessage or addMessage with
       it's ErrorID.
"

public import ErrorTypes;
public import Gettext;

protected

import ErrorExt;
import Flags;
import Global;
import System;
import Testsuite;
import Util;

public constant ErrorTypes.Message LOOKUP_ERROR = ErrorTypes.MESSAGE(3, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Class %s not found in scope %s."));
public constant ErrorTypes.Message LOOKUP_ERROR_COMPNAME = ErrorTypes.MESSAGE(4, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Class %s not found in scope %s while instantiating %s."));
public constant ErrorTypes.Message LOOKUP_VARIABLE_ERROR = ErrorTypes.MESSAGE(5, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Variable %s not found in scope %s."));
public constant ErrorTypes.Message ASSIGN_CONSTANT_ERROR = ErrorTypes.MESSAGE(6, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Trying to assign to constant component in %s := %s"));
public constant ErrorTypes.Message ASSIGN_PARAM_ERROR = ErrorTypes.MESSAGE(7, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Trying to assign to parameter component in %s := %s"));
public constant ErrorTypes.Message ASSIGN_READONLY_ERROR = ErrorTypes.MESSAGE(8, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Trying to assign to %s component %s."));
public constant ErrorTypes.Message ASSIGN_TYPE_MISMATCH_ERROR = ErrorTypes.MESSAGE(9, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch in assignment in %s := %s of %s := %s"));
public constant ErrorTypes.Message IF_CONDITION_TYPE_ERROR = ErrorTypes.MESSAGE(10, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type error in conditional '%s'. Expected Boolean, got %s."));
public constant ErrorTypes.Message FOR_EXPRESSION_TYPE_ERROR = ErrorTypes.MESSAGE(11, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type error in iteration range '%s'. Expected array got %s."));
public constant ErrorTypes.Message WHEN_CONDITION_TYPE_ERROR = ErrorTypes.MESSAGE(12, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type error in when conditional '%s'. Expected Boolean scalar or vector, got %s."));
public constant ErrorTypes.Message WHILE_CONDITION_TYPE_ERROR = ErrorTypes.MESSAGE(13, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type error in while conditional '%s'. Expected Boolean got %s."));
public constant ErrorTypes.Message END_ILLEGAL_USE_ERROR = ErrorTypes.MESSAGE(14, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("'end' can not be used outside array subscripts."));
public constant ErrorTypes.Message DIVISION_BY_ZERO = ErrorTypes.MESSAGE(15, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Division by zero in %s / %s"));
public constant ErrorTypes.Message MODULO_BY_ZERO = ErrorTypes.MESSAGE(16, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Modulo by zero in mod(%s,%s)."));
public constant ErrorTypes.Message REM_ARG_ZERO = ErrorTypes.MESSAGE(17, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Second argument in rem is zero in rem(%s,%s)."));
public constant ErrorTypes.Message SCRIPT_READ_SIM_RES_ERROR = ErrorTypes.MESSAGE(18, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Error reading simulation result."));
public constant ErrorTypes.Message EXTENDS_LOOP = ErrorTypes.MESSAGE(19, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("extends %s causes an instantiation loop."));
public constant ErrorTypes.Message LOAD_MODEL_ERROR = ErrorTypes.MESSAGE(20, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Class %s not found."));
public constant ErrorTypes.Message WRITING_FILE_ERROR = ErrorTypes.MESSAGE(21, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Error writing to file %s."));
public constant ErrorTypes.Message SIMULATOR_BUILD_ERROR = ErrorTypes.MESSAGE(22, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Error building simulator. Build log: %s"));
public constant ErrorTypes.Message DIMENSION_NOT_KNOWN = ErrorTypes.MESSAGE(23, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Dimensions must be parameter or constant expression (in %s)."));
public constant ErrorTypes.Message UNBOUND_VALUE = ErrorTypes.MESSAGE(24, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Variable %s has no value."));
public constant ErrorTypes.Message NEGATIVE_SQRT = ErrorTypes.MESSAGE(25, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Negative value as argument to sqrt."));
public constant ErrorTypes.Message NO_CONSTANT_BINDING = ErrorTypes.MESSAGE(26, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("No constant value for variable %s in scope %s."));
public constant ErrorTypes.Message TYPE_NOT_FROM_PREDEFINED = ErrorTypes.MESSAGE(27, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("In class %s, class specialization 'type' can only be derived from predefined types."));
public constant ErrorTypes.Message INCOMPATIBLE_CONNECTOR_VARIABILITY = ErrorTypes.MESSAGE(28, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Cannot connect %s %s to non-constant/parameter %s."));
public constant ErrorTypes.Message INVALID_CONNECTOR_PREFIXES = ErrorTypes.MESSAGE(29, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Connector element %s may not be both %s and %s."));
public constant ErrorTypes.Message INVALID_COMPLEX_CONNECTOR_VARIABILITY = ErrorTypes.MESSAGE(30, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s is a composite connector element, and may not be declared as %s."));
public constant ErrorTypes.Message DIFFERENT_NO_EQUATION_IF_BRANCHES = ErrorTypes.MESSAGE(31, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Different number of equations in the branches of the if equation: %s"));
public constant ErrorTypes.Message UNDERDET_EQN_SYSTEM = ErrorTypes.MESSAGE(32, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("Too few equations, under-determined system. The model has %s equation(s) and %s variable(s)."));
public constant ErrorTypes.Message OVERDET_EQN_SYSTEM = ErrorTypes.MESSAGE(33, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("Too many equations, over-determined system. The model has %s equation(s) and %s variable(s)."));
public constant ErrorTypes.Message STRUCT_SINGULAR_SYSTEM = ErrorTypes.MESSAGE(34, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("Model is structurally singular, error found sorting equations\n%s\nfor variables\n%s"));
public constant ErrorTypes.Message UNSUPPORTED_LANGUAGE_FEATURE = ErrorTypes.MESSAGE(35, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The language feature %s is not supported. Suggested workaround: %s"));
public constant ErrorTypes.Message NON_EXISTING_DERIVATIVE = ErrorTypes.MESSAGE(36, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("Derivative of expression \"%s\" w.r.t. \"%s\" is non-existent."));
public constant ErrorTypes.Message NO_CLASSES_LOADED = ErrorTypes.MESSAGE(37, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("No classes are loaded."));
public constant ErrorTypes.Message INST_PARTIAL_CLASS = ErrorTypes.MESSAGE(38, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Illegal to instantiate partial class %s."));
public constant ErrorTypes.Message LOOKUP_BASECLASS_ERROR = ErrorTypes.MESSAGE(39, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Base class %s not found in scope %s."));
public constant ErrorTypes.Message INVALID_REDECLARE_AS = ErrorTypes.MESSAGE(40, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid redeclaration of %s %s as %s."));
public constant ErrorTypes.Message REDECLARE_NON_REPLACEABLE = ErrorTypes.MESSAGE(41, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Trying to redeclare %1 %2 but %1 not declared as replaceable."));
public constant ErrorTypes.Message COMPONENT_INPUT_OUTPUT_MISMATCH = ErrorTypes.MESSAGE(42, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Component declared as %s when having the variable %s declared as %s."));
public constant ErrorTypes.Message ARRAY_DIMENSION_MISMATCH = ErrorTypes.MESSAGE(43, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Array dimension mismatch, expression %s has type %s, expected array dimensions [%s]."));
public constant ErrorTypes.Message ARRAY_DIMENSION_INTEGER = ErrorTypes.MESSAGE(44, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Array dimension must be integer expression in %s which has type %s."));
public constant ErrorTypes.Message EQUATION_TYPE_MISMATCH_ERROR = ErrorTypes.MESSAGE(45, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch in equation %s of type %s."));
public constant ErrorTypes.Message INST_ARRAY_EQ_UNKNOWN_SIZE = ErrorTypes.MESSAGE(46, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Array equation has unknown size in %s."));
public constant ErrorTypes.Message TUPLE_ASSIGN_FUNCALL_ONLY = ErrorTypes.MESSAGE(47, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Tuple assignment only allowed when rhs is function call (in %s)."));
public constant ErrorTypes.Message INVALID_CONNECTOR_TYPE = ErrorTypes.MESSAGE(48, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s is not a valid connector."));
public constant ErrorTypes.Message EXPANDABLE_NON_EXPANDABLE_CONNECTION = ErrorTypes.MESSAGE(49, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Cannot connect expandable connector %s with non-expandable connector %s."));
public constant ErrorTypes.Message UNDECLARED_CONNECTION = ErrorTypes.MESSAGE(50, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Cannot connect undeclared connectors %s with %s. At least one of them must be declared."));
public constant ErrorTypes.Message CONNECT_PREFIX_MISMATCH = ErrorTypes.MESSAGE(51, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Cannot connect %1 component %2 to non-%1 component %3."));
public constant ErrorTypes.Message INVALID_CONNECTOR_VARIABLE = ErrorTypes.MESSAGE(52, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The type of variables %s and %s\nare inconsistent in connect equations."));
public constant ErrorTypes.Message TYPE_ERROR = ErrorTypes.MESSAGE(53, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Wrong type on %s, expected %s."));
public constant ErrorTypes.Message MODIFY_PROTECTED = ErrorTypes.MESSAGE(54, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Modification or redeclaration of protected elements is not allowed.\n\tElement: %s, modification: %s."));
public constant ErrorTypes.Message INVALID_TUPLE_CONTENT = ErrorTypes.MESSAGE(55, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Tuple %s must contain component references only."));
public constant ErrorTypes.Message MISSING_REDECLARE_IN_CLASS_MOD = ErrorTypes.MESSAGE(56, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Missing redeclare keyword on attempted redeclaration of class %s."));
public constant ErrorTypes.Message IMPORT_SEVERAL_NAMES = ErrorTypes.MESSAGE(57, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s found in several unqualified import statements."));
public constant ErrorTypes.Message LOOKUP_TYPE_FOUND_COMP = ErrorTypes.MESSAGE(58, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Found a component with same name when looking for type %s."));
public constant ErrorTypes.Message INHERITED_EXTENDS = ErrorTypes.MESSAGE(59, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The base class name %s was found in one or more base classes:"));
public constant ErrorTypes.Message EXTEND_THROUGH_COMPONENT = ErrorTypes.MESSAGE(60, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Part %s of base class name %s is not a class."));
public constant ErrorTypes.Message PROTECTED_ACCESS = ErrorTypes.MESSAGE(61, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Illegal access of protected element %s."));
public constant ErrorTypes.Message ILLEGAL_MODIFICATION = ErrorTypes.MESSAGE(62, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Illegal modification %s (of %s)."));
public constant ErrorTypes.Message INTERNAL_ERROR = ErrorTypes.MESSAGE(63, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Internal error %s"));
public constant ErrorTypes.Message TYPE_MISMATCH_ARRAY_EXP = ErrorTypes.MESSAGE(64, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch in array expression in component %s. %s is of type %s while the elements %s are of type %s."));
public constant ErrorTypes.Message TYPE_MISMATCH_MATRIX_EXP = ErrorTypes.MESSAGE(65, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch in matrix rows in component %s. %s is a row of %s, the rest of the matrix is of type %s."));
public constant ErrorTypes.Message MATRIX_EXP_ROW_SIZE = ErrorTypes.MESSAGE(66, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Incompatible row length in matrix expression in component %s. %s is a row of size %s, the rest of the matrix rows are of size %s."));
public constant ErrorTypes.Message OPERAND_BUILTIN_TYPE = ErrorTypes.MESSAGE(67, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Operand of %s in component %s must be builtin-type in %s."));
public constant ErrorTypes.Message WRONG_TYPE_OR_NO_OF_ARGS = ErrorTypes.MESSAGE(68, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Wrong type or wrong number of arguments to %s (in component %s)."));
public constant ErrorTypes.Message DIFFERENT_DIM_SIZE_IN_ARGUMENTS = ErrorTypes.MESSAGE(69, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Different dimension sizes in arguments to %s in component %s."));
public constant ErrorTypes.Message LOOKUP_IMPORT_ERROR = ErrorTypes.MESSAGE(70, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Import %s not found in scope %s."));
public constant ErrorTypes.Message LOOKUP_SHADOWING = ErrorTypes.MESSAGE(71, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Import %s is shadowed by a local element."));
public constant ErrorTypes.Message ARGUMENT_MUST_BE_INTEGER = ErrorTypes.MESSAGE(72, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s argument to %s in component %s must be Integer expression."));
public constant ErrorTypes.Message ARGUMENT_MUST_BE_DISCRETE_VAR = ErrorTypes.MESSAGE(73, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s argument to %s in component %s must be discrete variable."));
public constant ErrorTypes.Message TYPE_MUST_BE_SIMPLE = ErrorTypes.MESSAGE(74, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type in %s must be simple type in component %s."));
public constant ErrorTypes.Message ARGUMENT_MUST_BE_VARIABLE = ErrorTypes.MESSAGE(75, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s argument to %s in component %s must be a variable."));
public constant ErrorTypes.Message NO_MATCHING_FUNCTION_FOUND = ErrorTypes.MESSAGE(76, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("No matching function found for %s in component %s\ncandidates are %s"));
public constant ErrorTypes.Message NO_MATCHING_FUNCTION_FOUND_NO_CANDIDATE = ErrorTypes.MESSAGE(77, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("No matching function found for %s."));
public constant ErrorTypes.Message FUNCTION_COMPS_MUST_HAVE_DIRECTION = ErrorTypes.MESSAGE(78, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Component %s in function is neither input nor output."));
public constant ErrorTypes.Message FUNCTION_SLOT_ALREADY_FILLED = ErrorTypes.MESSAGE(79, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Slot %s already filled in a function call in component %s."));
public constant ErrorTypes.Message NO_SUCH_PARAMETER = ErrorTypes.MESSAGE(80, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Function %s has no parameter named %s."));
public constant ErrorTypes.Message CONSTANT_OR_PARAM_WITH_NONCONST_BINDING = ErrorTypes.MESSAGE(81, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s is a constant or parameter with a non-constant initializer %s."));
public constant ErrorTypes.Message WRONG_DIMENSION_TYPE = ErrorTypes.MESSAGE(82, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Subscript %s of type %s is not a subtype of Integer, Boolean or enumeration."));
public constant ErrorTypes.Message TYPE_MISMATCH_IF_EXP = ErrorTypes.MESSAGE(83, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch in if-expression in component %s. True branch: %s has type %s, false branch: %s has type %s."));
public constant ErrorTypes.Message UNRESOLVABLE_TYPE = ErrorTypes.MESSAGE(84, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Cannot resolve type of expression %s. The operands have types %s in component %s."));
public constant ErrorTypes.Message INCOMPATIBLE_TYPES = ErrorTypes.MESSAGE(85, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Incompatible argument types to operation %s in component %s, left type: %s, right type: %s"));
public constant ErrorTypes.Message NON_ENCAPSULATED_CLASS_ACCESS = ErrorTypes.MESSAGE(86, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Class %s does not satisfy the requirements for a package. Lookup is therefore restricted to encapsulated elements, but %s is not encapsulated."));
public constant ErrorTypes.Message INHERIT_BASIC_WITH_COMPS = ErrorTypes.MESSAGE(87, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Class %s inherits builtin type but has components."));
public constant ErrorTypes.Message MODIFIER_TYPE_MISMATCH_ERROR = ErrorTypes.MESSAGE(88, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch in modifier of component %s, expected type %s, got modifier %s of type %s."));
public constant ErrorTypes.Message ERROR_FLATTENING = ErrorTypes.MESSAGE(89, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Error occurred while flattening model %s"));
public constant ErrorTypes.Message DUPLICATE_ELEMENTS_NOT_IDENTICAL = ErrorTypes.MESSAGE(90, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Duplicate elements (due to inherited elements) not identical:\n  first element is:  %s\n  second element is: %s"));
public constant ErrorTypes.Message PACKAGE_VARIABLE_NOT_CONSTANT = ErrorTypes.MESSAGE(91, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Variable %s in package %s is not constant."));
public constant ErrorTypes.Message RECURSIVE_DEFINITION = ErrorTypes.MESSAGE(92, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Declaration of element %s causes recursive definition of class %s."));
public constant ErrorTypes.Message NOT_ARRAY_TYPE_IN_FOR_STATEMENT = ErrorTypes.MESSAGE(93, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Expression %s in for-statement must be an array type."));
public constant ErrorTypes.Message NON_CLASS_IN_COMP_FUNC_NAME = ErrorTypes.MESSAGE(94, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Found non-class %s while looking for function via component. The only valid form is c1..cN.C1..CN.f where c1..cN are scalar components and C1..CN are classes."));
public constant ErrorTypes.Message DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN = ErrorTypes.MESSAGE(95, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("The same variables must be solved in elsewhen clause as in the when clause."));
public constant ErrorTypes.Message CLASS_IN_COMPOSITE_COMP_NAME = ErrorTypes.MESSAGE(96, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Found class %s during lookup of composite component name '%s', expected component."));
public constant ErrorTypes.Message MODIFIER_DECLARATION_TYPE_MISMATCH_ERROR = ErrorTypes.MESSAGE(97, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch in modifier of component %s, declared type %s, got modifier %s of type %s."));
public constant ErrorTypes.Message ASSERT_CONSTANT_FALSE_ERROR = ErrorTypes.MESSAGE(98, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("Assertion triggered during translation: %s."));
public constant ErrorTypes.Message ARRAY_INDEX_OUT_OF_BOUNDS = ErrorTypes.MESSAGE(99, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Subscript '%s' for dimension %s (size = %s) of %s is out of bounds."));
public constant ErrorTypes.Message COMPONENT_CONDITION_VARIABILITY = ErrorTypes.MESSAGE(100, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Component condition must be parameter or constant expression (in %s)."));
public constant ErrorTypes.Message FOUND_CLASS_NAME_VIA_COMPONENT = ErrorTypes.MESSAGE(101, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Class name '%s' was found via a component (only component and function call names may be accessed in this way)."));
public constant ErrorTypes.Message FOUND_FUNC_NAME_VIA_COMP_NONCALL = ErrorTypes.MESSAGE(102, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Found function %s by name lookup via component, but this is only valid when the name is used as a function call."));
public constant ErrorTypes.Message DUPLICATE_MODIFICATIONS = ErrorTypes.MESSAGE(103, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Duplicate modification of element %s on %s."));
public constant ErrorTypes.Message ILLEGAL_SUBSCRIPT = ErrorTypes.MESSAGE(104, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Illegal subscript %s for dimensions %s in component %s."));
public constant ErrorTypes.Message ILLEGAL_EQUATION_TYPE = ErrorTypes.MESSAGE(105, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Illegal type in equation %s, only builtin types (Real, String, Integer, Boolean or enumeration) or record type allowed in equation."));
public constant ErrorTypes.Message EVAL_LOOP_LIMIT_REACHED = ErrorTypes.MESSAGE(106, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The loop iteration limit (--evalLoopLimit=%s) was exceeded during evaluation."));
public constant ErrorTypes.Message LOOKUP_IN_PARTIAL_CLASS = ErrorTypes.MESSAGE(107, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s is partial, name lookup is not allowed in partial classes."));
public constant ErrorTypes.Message MISSING_INNER_PREFIX = ErrorTypes.MESSAGE(108, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("No corresponding 'inner' declaration found for component %s declared as '%s'.\n  The existing 'inner' components are:\n    %s\n  Check if you have not misspelled the 'outer' component name.\n  Please declare an 'inner' component with the same name in the top scope.\n  Continuing flattening by only considering the 'outer' component declaration."));
public constant ErrorTypes.Message NON_PARAMETER_ITERATOR_RANGE = ErrorTypes.MESSAGE(109, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The iteration range %s is not a constant or parameter expression."));
public constant ErrorTypes.Message IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY = ErrorTypes.MESSAGE(110, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Identifier %s of implicit for iterator must be present as array subscript in the loop body."));
public constant ErrorTypes.Message CONNECTOR_NON_PARAMETER_SUBSCRIPT = ErrorTypes.MESSAGE(111, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Connector ‘%s‘ has non-parameter subscript ‘%s‘."));
public constant ErrorTypes.Message LOOKUP_CLASS_VIA_COMP_COMP = ErrorTypes.MESSAGE(112, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Illegal access of class '%s' via a component when looking for '%s'."));
public constant ErrorTypes.Message SUBSCRIPTED_FUNCTION_CALL = ErrorTypes.MESSAGE(113, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Function call %s contains subscripts."));
public constant ErrorTypes.Message IF_EQUATION_UNBALANCED = ErrorTypes.MESSAGE(114, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("In equation %s. If-equation with conditions that are not parameter expressions must have the same number of equations in each branch, equation count is %s for each respective branch."));
public constant ErrorTypes.Message IF_EQUATION_MISSING_ELSE = ErrorTypes.MESSAGE(115, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Missing else-clause in if-equation with non-parameter conditions."));
public constant ErrorTypes.Message CONNECT_IN_IF = ErrorTypes.MESSAGE(116, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("connect may not be used inside if-equations with non-parametric conditions (found connect(%s, %s))."));
public constant ErrorTypes.Message CONNECT_IN_WHEN = ErrorTypes.MESSAGE(117, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("connect may not be used inside when-equations (found connect(%s, %s))."));
public constant ErrorTypes.Message CONNECT_INCOMPATIBLE_TYPES = ErrorTypes.MESSAGE(118, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Incompatible components in connect statement: connect(%s, %s)\n- %s has components %s\n- %s has components %s"));
public constant ErrorTypes.Message CONNECT_OUTER_OUTER = ErrorTypes.MESSAGE(119, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Illegal connecting two outer connectors in statement connect(%s, %s)."));
public constant ErrorTypes.Message CONNECTOR_ARRAY_NONCONSTANT = ErrorTypes.MESSAGE(120, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("in statement %s, subscript %s is not a parameter or constant."));
public constant ErrorTypes.Message CONNECTOR_ARRAY_DIFFERENT = ErrorTypes.MESSAGE(121, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Unmatched dimension in equation connect(%s, %s), %s != %s."));
public constant ErrorTypes.Message MODIFIER_NON_ARRAY_TYPE_WARNING = ErrorTypes.MESSAGE(122, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Non-array modification '%s' for array component, possibly due to missing 'each'."));
public constant ErrorTypes.Message BUILTIN_VECTOR_INVALID_DIMENSIONS = ErrorTypes.MESSAGE(123, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("In scope %s, in component %s: Invalid dimensions %s in %s, no more than one dimension may have size > 1."));
public constant ErrorTypes.Message UNROLL_LOOP_CONTAINING_WHEN = ErrorTypes.MESSAGE(124, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Unable to unroll for loop containing when statements or equations: %s."));
public constant ErrorTypes.Message CIRCULAR_PARAM = ErrorTypes.MESSAGE(125, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Variable '%s' has a cyclic dependency and has variability %s."));
public constant ErrorTypes.Message NESTED_WHEN = ErrorTypes.MESSAGE(126, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Nested when statements are not allowed."));
public constant ErrorTypes.Message INVALID_ENUM_LITERAL = ErrorTypes.MESSAGE(127, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid use of reserved attribute name %s as enumeration literal."));
public constant ErrorTypes.Message UNEXPECTED_FUNCTION_INPUTS_WARNING = ErrorTypes.MESSAGE(128, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Function %s has not the expected inputs. Expected inputs are %s."));
public constant ErrorTypes.Message DUPLICATE_CLASSES_NOT_EQUIVALENT = ErrorTypes.MESSAGE(129, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Duplicate class definitions (due to inheritance) not equivalent, first definition is: %s, second definition is: %s."));
public constant ErrorTypes.Message HIGHER_VARIABILITY_BINDING = ErrorTypes.MESSAGE(130, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Component %s of variability %s has binding %s of higher variability %s."));
public constant ErrorTypes.Message IF_EQUATION_WARNING = ErrorTypes.MESSAGE(131, ErrorTypes.SYMBOLIC(), ErrorTypes.WARNING(),
  Gettext.gettext("If-equations are only partially supported. Ignoring %s."));
public constant ErrorTypes.Message IF_EQUATION_UNBALANCED_2 = ErrorTypes.MESSAGE(132, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("If-equation with conditions that are not parameter expressions must have the same number of equations in each branch, equation count is %s for each respective branch:\n%s"));
public constant ErrorTypes.Message EQUATION_GENERIC_FAILURE = ErrorTypes.MESSAGE(133, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to instantiate equation %s."));
public constant ErrorTypes.Message INST_PARTIAL_CLASS_CHECK_MODEL_WARNING = ErrorTypes.MESSAGE(134, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Forcing full instantiation of partial class %s during checkModel."));
public constant ErrorTypes.Message VARIABLE_BINDING_TYPE_MISMATCH = ErrorTypes.MESSAGE(135, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch in binding %s = %s, expected subtype of %s, got type %s."));
public constant ErrorTypes.Message COMPONENT_NAME_SAME_AS_TYPE_NAME = ErrorTypes.MESSAGE(136, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Component %s has the same name as its type %s.\n\tThis is forbidden by Modelica specification and may lead to lookup errors."));
public constant ErrorTypes.Message CONDITIONAL_EXP_WITHOUT_VALUE = ErrorTypes.MESSAGE(137, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The conditional expression %s could not be evaluated."));
public constant ErrorTypes.Message INCOMPATIBLE_IMPLICIT_RANGES = ErrorTypes.MESSAGE(138, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Dimension %s of %s and %s of %s differs when trying to deduce implicit iteration range."));
public constant ErrorTypes.Message INITIAL_WHEN = ErrorTypes.MESSAGE(139, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("when-clause is not allowed in initial section."));
public constant ErrorTypes.Message MODIFICATION_INDEX_NOT_FOUND = ErrorTypes.MESSAGE(140, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Instantiation of array component: %s failed because index modification: %s is invalid.\n\tArray component: %s has more dimensions than binding %s."));
public constant ErrorTypes.Message DUPLICATE_MODIFICATIONS_WARNING = ErrorTypes.MESSAGE(141, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Duplicate modifications for attribute: %s in modifier: %s.\n\tConsidering only the first modification: %s and ignoring the rest %s."));
public constant ErrorTypes.Message GENERATECODE_INVARS_HAS_FUNCTION_PTR = ErrorTypes.MESSAGE(142, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("%s has a function pointer as input. OpenModelica does not support this feature in the interactive environment. Suggested workaround: Call this function with the arguments you want from another function (that does not have function pointer input). Then call that function from the interactive environment instead."));
public constant ErrorTypes.Message LOOKUP_FOUND_WRONG_TYPE = ErrorTypes.MESSAGE(143, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Expected %s to be a %s, but found %s instead."));
public constant ErrorTypes.Message DUPLICATE_ELEMENTS_NOT_SYNTACTICALLY_IDENTICAL = ErrorTypes.MESSAGE(144, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Duplicate elements (due to inherited elements) not syntactically identical but semantically identical:\n\tfirst element is:  %s\tsecond element is: %s\tModelica specification requires that elements are exactly identical."));
public constant ErrorTypes.Message GENERIC_INST_FUNCTION = ErrorTypes.MESSAGE(145, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to instantiate function %s in scope %s."));
public constant ErrorTypes.Message WRONG_NO_OF_ARGS = ErrorTypes.MESSAGE(146, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Wrong number of arguments to %s."));
public constant ErrorTypes.Message TUPLE_ASSIGN_CREFS_ONLY = ErrorTypes.MESSAGE(147, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Tuple assignment only allowed for tuple of component references in lhs (in %s)."));
public constant ErrorTypes.Message LOOKUP_FUNCTION_GOT_CLASS = ErrorTypes.MESSAGE(148, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Looking for a function %s but found a %s."));
public constant ErrorTypes.Message NON_STREAM_OPERAND_IN_STREAM_OPERATOR = ErrorTypes.MESSAGE(149, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Operand ‘%s‘ to operator ‘%s‘ is not a stream variable."));
public constant ErrorTypes.Message UNBALANCED_CONNECTOR = ErrorTypes.MESSAGE(150, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Connector %s is not balanced: %s"));
public constant ErrorTypes.Message RESTRICTION_VIOLATION = ErrorTypes.MESSAGE(151, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Class specialization violation: %s is a %s, not a %s."));
public constant ErrorTypes.Message ZERO_STEP_IN_ARRAY_CONSTRUCTOR = ErrorTypes.MESSAGE(152, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Step equals 0 in array constructor %s."));
public constant ErrorTypes.Message RECURSIVE_SHORT_CLASS_DEFINITION = ErrorTypes.MESSAGE(153, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Recursive short class definition of %s in terms of %s."));
public constant ErrorTypes.Message WRONG_NUMBER_OF_SUBSCRIPTS = ErrorTypes.MESSAGE(154, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Wrong number of subscripts in %s (%s subscripts for %s dimensions)."));
public constant ErrorTypes.Message FUNCTION_ELEMENT_WRONG_KIND = ErrorTypes.MESSAGE(155, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Element is not allowed in function context: %s"));
public constant ErrorTypes.Message MISSING_BINDING_PROTECTED_RECORD_VAR = ErrorTypes.MESSAGE(156, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Protected record member %s has no binding and is not modifiable by a record constructor."));
public constant ErrorTypes.Message DUPLICATE_CLASSES_TOP_LEVEL = ErrorTypes.MESSAGE(157, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Duplicate classes on top level is not allowed (got %s)."));
public constant ErrorTypes.Message WHEN_EQ_LHS = ErrorTypes.MESSAGE(158, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid left-hand side of when-equation: %s."));
public constant ErrorTypes.Message GENERIC_ELAB_EXPRESSION = ErrorTypes.MESSAGE(159, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to elaborate expression: %s."));
public constant ErrorTypes.Message EXTENDS_EXTERNAL = ErrorTypes.MESSAGE(160, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Ignoring external declaration of the extended class: %s."));
public constant ErrorTypes.Message DOUBLE_DECLARATION_OF_ELEMENTS = ErrorTypes.MESSAGE(161, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("An element with name %s is already declared in this scope."));
public constant ErrorTypes.Message INVALID_REDECLARATION_OF_CLASS = ErrorTypes.MESSAGE(162, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid redeclaration of class %s, class extends only allowed on inherited classes."));
public constant ErrorTypes.Message MULTIPLE_QUALIFIED_IMPORTS_WITH_SAME_NAME = ErrorTypes.MESSAGE(163, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Qualified import name %s already exists in this scope."));
public constant ErrorTypes.Message EXTENDS_INHERITED_FROM_LOCAL_EXTENDS = ErrorTypes.MESSAGE(164, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s was found in base class %s."));
public constant ErrorTypes.Message LOOKUP_FUNCTION_ERROR = ErrorTypes.MESSAGE(165, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Function %s not found in scope %s."));
public constant ErrorTypes.Message ELAB_CODE_EXP_FAILED = ErrorTypes.MESSAGE(166, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to elaborate %s as a code expression of type %s."));
public constant ErrorTypes.Message EQUATION_TRANSITION_FAILURE = ErrorTypes.MESSAGE(167, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Equations are not allowed in %s."));
public constant ErrorTypes.Message METARECORD_CONTAINS_METARECORD_MEMBER = ErrorTypes.MESSAGE(168, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The called uniontype record (%s) contains a member (%s) that has a uniontype record as its type instead of a uniontype."));
public constant ErrorTypes.Message INVALID_EXTERNAL_OBJECT = ErrorTypes.MESSAGE(169, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid external object %s, %s."));
public constant ErrorTypes.Message CIRCULAR_COMPONENTS = ErrorTypes.MESSAGE(170, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Cyclically dependent constants or parameters found in scope %s: %s (ignore with -d=ignoreCycles)."));
public constant ErrorTypes.Message FAILURE_TO_DEDUCE_DIMS_FROM_MOD = ErrorTypes.MESSAGE(171, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Failed to deduce dimensions of %s due to unknown dimensions of modifier %s."));
public constant ErrorTypes.Message REPLACEABLE_BASE_CLASS = ErrorTypes.MESSAGE(172, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Class '%s' in 'extends %s' is replaceable, the base class name must be transitively non-replaceable."));
public constant ErrorTypes.Message NON_REPLACEABLE_CLASS_EXTENDS = ErrorTypes.MESSAGE(173, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Non-replaceable base class %s in class extends."));
public constant ErrorTypes.Message ERROR_FROM_HERE = ErrorTypes.MESSAGE(174, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("From here:"));
public constant ErrorTypes.Message EXTERNAL_FUNCTION_RESULT_NOT_CREF = ErrorTypes.MESSAGE(175, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The lhs (result) of the external function declaration is not a component reference: %s."));
public constant ErrorTypes.Message EXTERNAL_FUNCTION_RESULT_NOT_VAR = ErrorTypes.MESSAGE(176, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The lhs (result) of the external function declaration is not a variable."));
public constant ErrorTypes.Message EXTERNAL_FUNCTION_RESULT_ARRAY_TYPE = ErrorTypes.MESSAGE(177, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The lhs (result) of the external function declaration has array type (%s), but this is not allowed in the specification. You need to pass it as an input to the function (preferably also with a size()-expression to avoid out-of-bounds errors in the external call)."));
public constant ErrorTypes.Message INVALID_REDECLARE = ErrorTypes.MESSAGE(178, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Redeclaration of %s %s %s is not allowed."));
public constant ErrorTypes.Message INVALID_TYPE_PREFIX = ErrorTypes.MESSAGE(179, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid type prefix '%s' on %s %s, due to existing type prefix '%s'."));
public constant ErrorTypes.Message LINEAR_SYSTEM_INVALID = ErrorTypes.MESSAGE(180, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("Linear solver (%s) returned invalid input for linear system %s."));
public constant ErrorTypes.Message LINEAR_SYSTEM_SINGULAR = ErrorTypes.MESSAGE(181, ErrorTypes.SYMBOLIC(), ErrorTypes.WARNING(),
  Gettext.gettext("The linear system: %1\n might be structurally or numerically singular for variable %3 since U(%2,%2) = 0.0. It might be hard to solve. Compilation continues anyway."));
public constant ErrorTypes.Message EMPTY_ARRAY = ErrorTypes.MESSAGE(182, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Array constructor may not be empty."));
public constant ErrorTypes.Message LOAD_MODEL_DIFFERENT_VERSIONS = ErrorTypes.MESSAGE(183, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("Requested package %s of version %s, but this package was already loaded with version %s. OpenModelica cannot reason about compatibility between the two packages since they are not semantic versions."));
public constant ErrorTypes.Message LOAD_MODEL = ErrorTypes.MESSAGE(184, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to load package %s (%s) using MODELICAPATH %s."));
public constant ErrorTypes.Message REPLACEABLE_BASE_CLASS_SIMPLE = ErrorTypes.MESSAGE(185, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Base class %s is replaceable."));
public constant ErrorTypes.Message INVALID_SIZE_INDEX = ErrorTypes.MESSAGE(186, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid index %s in call to size of %s, valid index interval is [1,%s]."));
public constant ErrorTypes.Message ALGORITHM_TRANSITION_FAILURE = ErrorTypes.MESSAGE(187, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Algorithm section is not allowed in %s."));
public constant ErrorTypes.Message FAILURE_TO_DEDUCE_DIMS_NO_MOD = ErrorTypes.MESSAGE(188, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to deduce dimension %s of %s due to missing binding equation."));
public constant ErrorTypes.Message FUNCTION_MULTIPLE_ALGORITHM = ErrorTypes.MESSAGE(189, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("The behavior of multiple algorithm sections in function %s is not standard Modelica. OpenModelica will execute the sections in the order in which they were declared or inherited (same ordering as inherited input/output arguments, which also are not standardized)."));
public constant ErrorTypes.Message STATEMENT_GENERIC_FAILURE = ErrorTypes.MESSAGE(190, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to instantiate statement:\n%s"));
public constant ErrorTypes.Message EXTERNAL_NOT_SINGLE_RESULT = ErrorTypes.MESSAGE(191, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s is an unbound output in external function %s. Either add it to the external declaration or add a default binding."));
public constant ErrorTypes.Message FUNCTION_UNUSED_INPUT = ErrorTypes.MESSAGE(192, ErrorTypes.SYMBOLIC(), ErrorTypes.WARNING(),
  Gettext.gettext("Unused input variable %s in function %s."));
public constant ErrorTypes.Message ARRAY_TYPE_MISMATCH = ErrorTypes.MESSAGE(193, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Array types mismatch: %s and %s."));
public constant ErrorTypes.Message VECTORIZE_TWO_UNKNOWN = ErrorTypes.MESSAGE(194, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Could not vectorize call with unknown dimensions due to finding two for-iterators: %s and %s."));
public constant ErrorTypes.Message FUNCTION_SLOT_VARIABILITY = ErrorTypes.MESSAGE(195, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Function argument %s=%s in call to %s has variability %s which is not a %s expression."));
public constant ErrorTypes.Message INVALID_ARRAY_DIM_IN_CONVERSION_OP = ErrorTypes.MESSAGE(196, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid dimension %s of argument to %s, expected dimension size %s but got %s."));
public constant ErrorTypes.Message DUPLICATE_REDECLARATION = ErrorTypes.MESSAGE(197, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s is already redeclared in this scope."));
public constant ErrorTypes.Message INVALID_FUNCTION_VAR_TYPE = ErrorTypes.MESSAGE(198, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid type %s for function component %s."));
public constant ErrorTypes.Message IMBALANCED_EQUATIONS = ErrorTypes.MESSAGE(199, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("An independent subset of the model has imbalanced number of equations (%s) and variables (%s).\nvariables:\n%s\nequations:\n%s"));
public constant ErrorTypes.Message EQUATIONS_VAR_NOT_DEFINED = ErrorTypes.MESSAGE(200, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("Variable %s is not referenced in any equation (possibly after symbolic manipulations)."));
public constant ErrorTypes.Message NON_FORMAL_PUBLIC_FUNCTION_VAR = ErrorTypes.MESSAGE(201, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Invalid public variable %s, function variables that are not input/output must be protected."));
public constant ErrorTypes.Message PROTECTED_FORMAL_FUNCTION_VAR = ErrorTypes.MESSAGE(202, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid protected variable %s, function variables that are input/output must be public."));
public constant ErrorTypes.Message UNFILLED_SLOT = ErrorTypes.MESSAGE(203, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Function parameter %s was not given by the function call, and does not have a default value."));
public constant ErrorTypes.Message SAME_CONNECT_INSTANCE = ErrorTypes.MESSAGE(204, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("connect(%s, %s) connects the same connector instance! The connect equation will be ignored."));
public constant ErrorTypes.Message STACK_OVERFLOW = ErrorTypes.MESSAGE(205, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Stack overflow occurred while evaluating %s."));
public constant ErrorTypes.Message UNKNOWN_DEBUG_FLAG = ErrorTypes.MESSAGE(206, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Unknown debug flag %s."));
public constant ErrorTypes.Message INVALID_FLAG_TYPE = ErrorTypes.MESSAGE(207, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid type of flag %s, expected %s but got %s."));
public constant ErrorTypes.Message CHANGED_STD_VERSION = ErrorTypes.MESSAGE(208, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Modelica language version set to %s due to loading of MSL %s."));
public constant ErrorTypes.Message SIMPLIFY_FIXPOINT_MAXIMUM = ErrorTypes.MESSAGE(209, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Expression simplification iterated to the fix-point maximum, which may be a performance bottleneck. The last two iterations were: %s, and %s."));
public constant ErrorTypes.Message UNKNOWN_OPTION = ErrorTypes.MESSAGE(210, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Unknown option %s."));
public constant ErrorTypes.Message SUBSCRIPTED_MODIFIER = ErrorTypes.MESSAGE(211, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Subscripted modifier is illegal."));
public constant ErrorTypes.Message TRANS_VIOLATION = ErrorTypes.MESSAGE(212, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Class specialization violation: %s is a %s, which may not contain an %s."));
public constant ErrorTypes.Message INSERT_CLASS = ErrorTypes.MESSAGE(213, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to insert class %s %s the available classes were:%s"));
public constant ErrorTypes.Message MISSING_MODIFIED_ELEMENT = ErrorTypes.MESSAGE(214, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Modified element %s not found in class %s."));
public constant ErrorTypes.Message INVALID_REDECLARE_IN_BASIC_TYPE = ErrorTypes.MESSAGE(215, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid redeclaration of %s, attributes of basic types may not be redeclared."));
public constant ErrorTypes.Message INVALID_STREAM_CONNECTOR = ErrorTypes.MESSAGE(216, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid stream connector %s: %s"));
public constant ErrorTypes.Message CONDITION_TYPE_ERROR = ErrorTypes.MESSAGE(217, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch in condition '%s' of component %s. Expected a Boolean expression, but got an expression of type %s."));
public constant ErrorTypes.Message SIMPLIFY_CONSTANT_ERROR = ErrorTypes.MESSAGE(218, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("The compiler failed to perform constant folding on expression %s. Please report this bug to the developers and we will fix it as soon as possible (using the +t compiler option if possible)."));
public constant ErrorTypes.Message SUM_EXPECTED_ARRAY = ErrorTypes.MESSAGE(219, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("In sum(%s), the expression is of type %s, but is required to be of builtin array type (of any number of dimensions)."));
public constant ErrorTypes.Message INVALID_CLASS_RESTRICTION = ErrorTypes.MESSAGE(220, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid specialized class type '%s' for component %s."));
public constant ErrorTypes.Message CONNECT_IN_INITIAL_EQUATION = ErrorTypes.MESSAGE(221, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Connect equations are not allowed in initial equation sections."));
public constant ErrorTypes.Message FINAL_COMPONENT_OVERRIDE = ErrorTypes.MESSAGE(222, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Trying to override final element %s with modifier '%s'."));
public constant ErrorTypes.Message NOTIFY_NOT_LOADED = ErrorTypes.MESSAGE(223, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Automatically loaded package %s %s due to uses annotation."));
public constant ErrorTypes.Message REINIT_MUST_BE_REAL = ErrorTypes.MESSAGE(224, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The first argument to reinit must be a subtype of Real, but %s has type %s."));
public constant ErrorTypes.Message REINIT_MUST_BE_VAR = ErrorTypes.MESSAGE(225, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The first argument to reinit must be a continuous time variable, but %s is %s."));
public constant ErrorTypes.Message CONNECT_TWO_SOURCES = ErrorTypes.MESSAGE(226, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Connecting two signal sources while connecting %s to %s."));
public constant ErrorTypes.Message INNER_OUTER_FORMAL_PARAMETER = ErrorTypes.MESSAGE(227, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid prefix %s on formal parameter %s."));
public constant ErrorTypes.Message REDECLARE_NONEXISTING_ELEMENT = ErrorTypes.MESSAGE(228, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Illegal redeclare of element %s, no inherited element with that name exists."));
public constant ErrorTypes.Message INVALID_ARGUMENT_TYPE_FIRST_ARRAY = ErrorTypes.MESSAGE(229, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The first argument of %s must be an array expression."));
public constant ErrorTypes.Message INVALID_ARGUMENT_TYPE_BRANCH_FIRST = ErrorTypes.MESSAGE(230, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The first argument '%s' of %s must have the form A.R, where A is a connector and R an over-determined type/record."));
public constant ErrorTypes.Message INVALID_ARGUMENT_TYPE_BRANCH_SECOND = ErrorTypes.MESSAGE(231, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The second argument '%s' of %s must have the form A.R, where A is a connector and R an over-determined type/record."));
public constant ErrorTypes.Message INVALID_ARGUMENT_TYPE_OVERDET_FIRST = ErrorTypes.MESSAGE(232, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The first argument of %s must be an over-determined type or record."));
public constant ErrorTypes.Message INVALID_ARGUMENT_TYPE_OVERDET_SECOND = ErrorTypes.MESSAGE(233, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The second argument of %s must be an over-determined type or record."));
public constant ErrorTypes.Message LIBRARY_ONE_PACKAGE_PER_FILE = ErrorTypes.MESSAGE(234, ErrorTypes.GRAMMAR(), ErrorTypes.ERROR(),
  Gettext.gettext("Modelica library files should contain exactly one package, but found the following classes: %s."));
public constant ErrorTypes.Message LIBRARY_UNEXPECTED_WITHIN = ErrorTypes.MESSAGE(235, ErrorTypes.GRAMMAR(), ErrorTypes.ERROR(),
  Gettext.gettext("Expected the package to have %s but got %s."));
public constant ErrorTypes.Message LIBRARY_UNEXPECTED_NAME = ErrorTypes.MESSAGE(236, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Expected the package to have name %s, but got %s."));
public constant ErrorTypes.Message PACKAGE_MO_NOT_IN_ORDER = ErrorTypes.MESSAGE(237, ErrorTypes.GRAMMAR(), ErrorTypes.WARNING(),
  Gettext.gettext("Elements in the package.mo-file need to be in the same relative order as the package.order file. Got element named %s but it was already added because it was not the next element in the list at that time."));
public constant ErrorTypes.Message LIBRARY_EXPECTED_PARTS = ErrorTypes.MESSAGE(238, ErrorTypes.GRAMMAR(), ErrorTypes.ERROR(),
  Gettext.gettext("%s is a package.mo-file and needs to be based on class parts (i.e. not class extends, derived class, or enumeration)."));
public constant ErrorTypes.Message PACKAGE_ORDER_FILE_NOT_FOUND = ErrorTypes.MESSAGE(239, ErrorTypes.GRAMMAR(), ErrorTypes.WARNING(),
  Gettext.gettext("%1 was referenced in the package.order file, but was not found in package.mo, %1/package.mo or %1.mo."));
public constant ErrorTypes.Message FOUND_ELEMENT_NOT_IN_ORDER_FILE = ErrorTypes.MESSAGE(240, ErrorTypes.GRAMMAR(), ErrorTypes.WARNING(),
  Gettext.gettext("Got element %1 that was not referenced in the package.order file."));
public constant ErrorTypes.Message ORDER_FILE_COMPONENTS = ErrorTypes.MESSAGE(241, ErrorTypes.GRAMMAR(), ErrorTypes.WARNING(),
  Gettext.gettext("Components referenced in the package.order file must be moved in full chunks. Either split the constants to different lines or make them subsequent in the package.order file."));
public constant ErrorTypes.Message GUARD_EXPRESSION_TYPE_MISMATCH = ErrorTypes.MESSAGE(242, ErrorTypes.GRAMMAR(), ErrorTypes.ERROR(),
  Gettext.gettext("Guard expressions need to be Boolean, got expression of type %s."));
public constant ErrorTypes.Message FUNCTION_RETURNS_META_ARRAY = ErrorTypes.MESSAGE(243, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("User-defined function calls that return Array<...> are not supported: %s."));
public constant ErrorTypes.Message ASSIGN_UNKNOWN_ERROR = ErrorTypes.MESSAGE(244, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed elaborate assignment for some unknown reason: %1 := %2. File a bug report and we will make sure this error gets a better message in the future."));
public constant ErrorTypes.Message WARNING_DEF_USE = ErrorTypes.MESSAGE(245, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("%s was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed."));
public constant ErrorTypes.Message EXP_TYPE_MISMATCH = ErrorTypes.MESSAGE(246, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Expression '%1' has type %3, expected type %2."));
public constant ErrorTypes.Message PACKAGE_ORDER_DUPLICATES = ErrorTypes.MESSAGE(247, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Found duplicate names in package.order file: %s."));
public constant ErrorTypes.Message ERRONEOUS_TYPE_ERROR = ErrorTypes.MESSAGE(248, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Got type mismatch error, but matching types %s.\nThis is a ***COMPILER BUG***, please report it to https://trac.openmodelica.org/OpenModelica."));
public constant ErrorTypes.Message REINIT_MUST_BE_VAR_OR_ARRAY = ErrorTypes.MESSAGE(249, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The first argument to reinit must be a variable of type Real or an array of such variables."));
public constant ErrorTypes.Message SLICE_ASSIGN_NON_ARRAY = ErrorTypes.MESSAGE(250, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Cannot assign slice to non-initialized array %s."));
public constant ErrorTypes.Message EXTERNAL_ARG_WRONG_EXP = ErrorTypes.MESSAGE(251, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Expression %s cannot be an external argument. Only identifiers, scalar constants, and size-expressions are allowed."));
public constant ErrorTypes.Message OPERATOR_FUNCTION_NOT_EXPECTED = ErrorTypes.MESSAGE(252, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Only classes of type 'operator record' may contain elements of type 'operator function'; %s was found in a class that has restriction '%s'."));
public constant ErrorTypes.Message OPERATOR_FUNCTION_EXPECTED = ErrorTypes.MESSAGE(253, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("'operator record' classes may only contain elements of type 'operator function'; %s has restriction '%s'."));
public constant ErrorTypes.Message STRUCTURAL_SINGULAR_INITIAL_SYSTEM = ErrorTypes.MESSAGE(254, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("Initialization problem is structurally singular, error found sorting equations \n %s for variables \n %s"));
public constant ErrorTypes.Message UNFIXED_PARAMETER_WITH_BINDING = ErrorTypes.MESSAGE(255, ErrorTypes.SYMBOLIC(), ErrorTypes.WARNING(),
  Gettext.gettext("The parameter %s has fixed = false and a binding equation %s = %s, which is probably redundant.\nSetting fixed = false usually means there is an additional initial equation to determine the parameter value. The binding was ignored by old Modelica tools, but this is not according to the Modelica specification. Please remove the parameter binding, or bind the parameter to another parameter with fixed = false and no binding."));
public constant ErrorTypes.Message UNFIXED_PARAMETER_WITH_BINDING_31 = ErrorTypes.MESSAGE(256, ErrorTypes.SYMBOLIC(), ErrorTypes.WARNING(),
  Gettext.gettext("The parameter %s has fixed = false and a binding equation %s = %s, which is probably redundant. The binding equation will be ignored, as it is expected for Modelica 3.1."));
public constant ErrorTypes.Message UNFIXED_PARAMETER_WITH_BINDING_AND_START_VALUE_31 = ErrorTypes.MESSAGE(257, ErrorTypes.SYMBOLIC(), ErrorTypes.WARNING(),
  Gettext.gettext("The parameter %s has fixed = false, a start value, start = %s and a binding equation %s = %s, which is probably redundant. The binding equation will be ignored, as it is expected for Modelica 3.1."));
public constant ErrorTypes.Message BACKENDDAEINFO_LOWER = ErrorTypes.MESSAGE(258, ErrorTypes.SYMBOLIC(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Model statistics after passing the front-end and creating the data structures used by the back-end:\n * Number of equations: %s\n * Number of variables: %s"));
public constant ErrorTypes.Message BACKENDDAEINFO_STATISTICS = ErrorTypes.MESSAGE(259, ErrorTypes.SYMBOLIC(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Model statistics after passing the back-end for %s:\n * Number of independent subsystems: %s\n * Number of states: %s\n * Number of discrete variables: %s\n * Number of discrete states: %s\n * Number of clocked states: %s\n * Top-level inputs: %s"));
public constant ErrorTypes.Message BACKENDDAEINFO_MIXED = ErrorTypes.MESSAGE(260, ErrorTypes.SYMBOLIC(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Mixed equation statistics:\n * Mixed systems with single equation: %s\n * Mixed systems with array equation: %s\n * Mixed systems with algorithm: %s\n * Mixed systems with complex equation: %s\n * Mixed systems with constant Jacobian: %s\n * Mixed systems with linear Jacobian: %s\n * Mixed systems with non-linear Jacobian: %s\n * Mixed systems with analytic Jacobian: %s\n * Mixed systems with linear tearing system: %s\n * Mixed systems with nonlinear tearing system: %s"));
public constant ErrorTypes.Message BACKENDDAEINFO_STRONGCOMPONENT_STATISTICS = ErrorTypes.MESSAGE(261, ErrorTypes.SYMBOLIC(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Strong component statistics for %s (%s):\n * Single equations (assignments): %s\n * Array equations: %s\n * Algorithm blocks: %s\n * Record equations: %s\n * When equations: %s\n * If-equations: %s\n * Equation systems (not torn): %s\n * Torn equation systems: %s\n * Mixed (continuous/discrete) equation systems: %s"));
public constant ErrorTypes.Message BACKENDDAEINFO_SYSTEMS = ErrorTypes.MESSAGE(262, ErrorTypes.SYMBOLIC(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Equation system details (not torn):\n * Constant Jacobian (size): %s\n * Linear Jacobian (size,density): %s\n * Non-linear Jacobian (size): %s\n * Without analytic Jacobian (size): %s"));
public constant ErrorTypes.Message BACKENDDAEINFO_TORN = ErrorTypes.MESSAGE(263, ErrorTypes.SYMBOLIC(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Torn system details for %s tearing set:\n * Linear torn systems (#iteration vars, #inner vars, density): %s\n * Non-linear torn systems (#iteration vars, #inner vars): %s"));
public constant ErrorTypes.Message BACKEND_DAE_TO_MODELICA = ErrorTypes.MESSAGE(264, ErrorTypes.SYMBOLIC(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("The following Modelica-like model represents the back-end DAE for the '%s' stage:\n%s"));
public constant ErrorTypes.Message NEGATIVE_DIMENSION_INDEX = ErrorTypes.MESSAGE(265, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Negative dimension index (%s) for component %s."));
public constant ErrorTypes.Message GENERATE_SEPARATE_CODE_DEPENDENCIES_FAILED = ErrorTypes.MESSAGE(266, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to get dependencies for package %s. Perhaps there is an import to a non-existing package."));
public constant ErrorTypes.Message CYCLIC_DEFAULT_VALUE = ErrorTypes.MESSAGE(267, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("The default value of %s causes a cyclic dependency."));
public constant ErrorTypes.Message NAMED_ARG_TYPE_MISMATCH = ErrorTypes.MESSAGE(268, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch for named argument in %s(%s=%s). The argument has type:\n  %s\nexpected type:\n  %s"));
public constant ErrorTypes.Message ARG_TYPE_MISMATCH = ErrorTypes.MESSAGE(269, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch for positional argument %s in %s(%s=%s). The argument has type:\n  %s\nexpected type:\n  %s"));
public constant ErrorTypes.Message OP_OVERLOAD_MULTIPLE_VALID = ErrorTypes.MESSAGE(270, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Operator overloading requires exactly one matching expression, but found %s expressions: %s"));
public constant ErrorTypes.Message OP_OVERLOAD_OPERATOR_NOT_INPUT = ErrorTypes.MESSAGE(271, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Operator %s is not an input to the overloaded function: %s"));
public constant ErrorTypes.Message NOTIFY_FRONTEND_STRUCTURAL_PARAMETERS = ErrorTypes.MESSAGE(272, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("The following structural parameters were evaluated in the front-end: %s\nStructural parameters are parameters used to calculate array dimensions or branch selection in certain if-equations or if-expressions among other things."));
public constant ErrorTypes.Message SIMPLIFICATION_TYPE = ErrorTypes.MESSAGE(273, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Expression simplification '%s' → '%s' changed the type from %s to %s."));
public constant ErrorTypes.Message VECTORIZE_CALL_DIM_MISMATCH = ErrorTypes.MESSAGE(274, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to vectorize function call because arguments %s=%s and %s=%s have mismatched dimensions %s and %s."));
public constant ErrorTypes.Message TCOMPLEX_MULTIPLE_NAMES = ErrorTypes.MESSAGE(275, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Non-tuple complex type specifiers need to have exactly one type name: %s."));
public constant ErrorTypes.Message TCOMPLEX_TUPLE_ONE_NAME = ErrorTypes.MESSAGE(276, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Tuple complex type specifiers need to have more than one type name: %s."));
public constant ErrorTypes.Message ENUM_DUPLICATES = ErrorTypes.MESSAGE(277, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Enumeration has duplicate names: %s in list of names %s."));
public constant ErrorTypes.Message RESERVED_IDENTIFIER = ErrorTypes.MESSAGE(278, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Identifier %s is reserved for the built-in element with the same name."));
public constant ErrorTypes.Message NOTIFY_PKG_FOUND = ErrorTypes.MESSAGE(279, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("You can install the requested package using one of the commands:\n%s."));
public constant ErrorTypes.Message DERIVATIVE_FUNCTION_CONTEXT = ErrorTypes.MESSAGE(280, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("The der() operator is not allowed in function context (possible solutions: pass the derivative as an explicit input; use a block instead of function)."));
public constant ErrorTypes.Message RETURN_OUTSIDE_FUNCTION = ErrorTypes.MESSAGE(281, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("'return' may not be used outside function."));
public constant ErrorTypes.Message EXT_LIBRARY_NOT_FOUND = ErrorTypes.MESSAGE(282, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Could not find library %s in either of:%s"));
public constant ErrorTypes.Message EXT_LIBRARY_NOT_FOUND_DESPITE_COMPILATION_SUCCESS = ErrorTypes.MESSAGE(283, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Could not find library %s despite compilation command %s in directory %s returning success."));
public constant ErrorTypes.Message GENERATE_SEPARATE_CODE_DEPENDENCIES_FAILED_UNKNOWN_PACKAGE = ErrorTypes.MESSAGE(284, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to get dependencies for package %s. %s contains an import to non-existing package %s."));
public constant ErrorTypes.Message USE_OF_PARTIAL_CLASS = ErrorTypes.MESSAGE(285, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("component %s contains the definition of a partial class %s.\nPlease redeclare it to any package compatible with %s."));
public constant ErrorTypes.Message SCANNER_ERROR = ErrorTypes.MESSAGE(286, ErrorTypes.SYNTAX(), ErrorTypes.ERROR(),
  Gettext.gettext("Syntax error, unrecognized input: %s."));
public constant ErrorTypes.Message SCANNER_ERROR_LIMIT = ErrorTypes.MESSAGE(287, ErrorTypes.SYNTAX(), ErrorTypes.ERROR(),
  Gettext.gettext("Additional syntax errors were suppressed."));
public constant ErrorTypes.Message INVALID_TIME_SCOPE = ErrorTypes.MESSAGE(288, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Built-in variable 'time' may only be used in a model or block."));
public constant ErrorTypes.Message NO_JACONIAN_TORNLINEAR_SYSTEM = ErrorTypes.MESSAGE(289, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("A torn linear system has no symbolic jacobian and currently there are no means to solve that numerically. Please compile with the module \"calculateStrongComponentJacobians\" to provide symbolic jacobians for torn linear systems."));
public constant ErrorTypes.Message EXT_FN_SINGLE_RETURN_ARRAY = ErrorTypes.MESSAGE(290, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("An external declaration with a single output without explicit mapping is defined as having the output as the lhs, but language %s does not support this for array variables. OpenModelica will put the output as an input (as is done when there is more than 1 output), but this is not according to the Modelica Specification. Use an explicit mapping instead of the implicit one to suppress this warning."));
public constant ErrorTypes.Message RHS_TUPLE_EXPRESSION = ErrorTypes.MESSAGE(291, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Tuple expressions may only occur on the left side of an assignment or equation with a single function call on the right side. Got the following expression: %s."));
public constant ErrorTypes.Message EACH_ON_NON_ARRAY = ErrorTypes.MESSAGE(292, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("'each' used when modifying non-array element %s."));
public constant ErrorTypes.Message BUILTIN_EXTENDS_INVALID_ELEMENTS = ErrorTypes.MESSAGE(293, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("A class extending from builtin type %s may not have other elements."));
public constant ErrorTypes.Message INITIAL_CALL_WARNING = ErrorTypes.MESSAGE(294, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("initial() may only be used as a when condition (when initial() or when {..., initial(), ...}), but got condition ‘%s‘."));
public constant ErrorTypes.Message RANGE_TYPE_MISMATCH = ErrorTypes.MESSAGE(295, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch in range: '%s' of type\n  %s\nis not type compatible with '%s' of type\n  %s"));
public constant ErrorTypes.Message RANGE_TOO_SMALL_STEP = ErrorTypes.MESSAGE(296, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Step size %s in range is too small."));
public constant ErrorTypes.Message RANGE_INVALID_STEP = ErrorTypes.MESSAGE(297, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Range of type %s may not specify a step size."));
public constant ErrorTypes.Message RANGE_INVALID_TYPE = ErrorTypes.MESSAGE(298, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Range has invalid type %s."));
public constant ErrorTypes.Message CLASS_EXTENDS_MISSING_REDECLARE = ErrorTypes.MESSAGE(299, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Missing redeclare prefix on class extends %s, treating like redeclare anyway."));
public constant ErrorTypes.Message CYCLIC_DIMENSIONS = ErrorTypes.MESSAGE(300, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Dimension %s of %s, '%s', could not be evaluated due to a cyclic dependency."));
public constant ErrorTypes.Message INVALID_DIMENSION_TYPE = ErrorTypes.MESSAGE(301, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Dimension '%s' of type %s is not an integer expression or an enumeration or Boolean type name."));
public constant ErrorTypes.Message NON_PARAMETER_EXPRESSION_DIMENSION = ErrorTypes.MESSAGE(302, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Expression ‘%s‘ that determines the size of dimension ‘%s‘ of ‘%s‘ is not an evaluable parameter expression."));
public constant ErrorTypes.Message INVALID_TYPENAME_USE = ErrorTypes.MESSAGE(303, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type name '%s' is not allowed in this context."));
public constant ErrorTypes.Message FOUND_WRONG_INNER_ELEMENT = ErrorTypes.MESSAGE(305, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Found inner %s %s instead of expected %s."));
public constant ErrorTypes.Message FOUND_OTHER_BASECLASS = ErrorTypes.MESSAGE(306, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Found other base class for extends %s after instantiating extends."));
public constant ErrorTypes.Message OUTER_ELEMENT_MOD = ErrorTypes.MESSAGE(307, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Modifier '%s' found on outer element %s."));
public constant ErrorTypes.Message OUTER_LONG_CLASS = ErrorTypes.MESSAGE(308, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Illegal outer class %s, outer classes may only be declared using short-class definitions."));
public constant ErrorTypes.Message MISSING_INNER_ADDED = ErrorTypes.MESSAGE(309, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("An inner declaration for outer %s %s could not be found and was automatically generated."));
public constant ErrorTypes.Message MISSING_INNER_MESSAGE = ErrorTypes.MESSAGE(310, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("The diagnostics message for the missing inner is: %s"));
public constant ErrorTypes.Message INVALID_CONNECTOR_FORM = ErrorTypes.MESSAGE(311, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s is not a valid form for a connector, connectors must be either c1.c2...cn or m.c (where c is a connector and m is a non-connector)."));
public constant ErrorTypes.Message CONNECTOR_PREFIX_OUTSIDE_CONNECTOR = ErrorTypes.MESSAGE(312, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Prefix '%s' used outside connector declaration."));
public constant ErrorTypes.Message EXTERNAL_OBJECT_INVALID_ELEMENT = ErrorTypes.MESSAGE(313, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("External object %s contains invalid element '%s'."));
public constant ErrorTypes.Message EXTERNAL_OBJECT_MISSING_STRUCTOR = ErrorTypes.MESSAGE(314, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("External object %s is missing a %s."));
public constant ErrorTypes.Message MULTIPLE_SECTIONS_IN_FUNCTION = ErrorTypes.MESSAGE(315, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Function %s has more than one algorithm section or external declaration."));
public constant ErrorTypes.Message INVALID_EXTERNAL_LANGUAGE = ErrorTypes.MESSAGE(316, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("'%s' is not a valid language for an external function."));
public constant ErrorTypes.Message SUBSCRIPT_TYPE_MISMATCH = ErrorTypes.MESSAGE(317, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Subscript '%s' has type %s, expected type %s."));
public constant ErrorTypes.Message EXP_INVALID_IN_FUNCTION = ErrorTypes.MESSAGE(318, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s is not allowed in a function."));
public constant ErrorTypes.Message NO_MATCHING_FUNCTION_FOUND_NFINST = ErrorTypes.MESSAGE(319, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("No matching function found for %s.\nCandidates are:\n  %s"));
public constant ErrorTypes.Message ARGUMENT_OUT_OF_RANGE = ErrorTypes.MESSAGE(320, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Argument %s of %s is out of range (%s)"));
public constant ErrorTypes.Message UNBOUND_CONSTANT = ErrorTypes.MESSAGE(321, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Constant %s is used without having been given a value."));
public constant ErrorTypes.Message INVALID_ARGUMENT_VARIABILITY = ErrorTypes.MESSAGE(322, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Argument %s of %s must be a %s expression, but %s is %s."));
public constant ErrorTypes.Message AMBIGUOUS_MATCHING_FUNCTIONS_NFINST = ErrorTypes.MESSAGE(323, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Ambiguous matching functions found for %s.\nCandidates are:\n  %s"));
public constant ErrorTypes.Message AMBIGUOUS_MATCHING_OPERATOR_FUNCTIONS_NFINST = ErrorTypes.MESSAGE(324, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Ambiguous matching overloaded operator functions found for %s.\nCandidates are:\n  %s"));
public constant ErrorTypes.Message REDECLARE_CONDITION = ErrorTypes.MESSAGE(325, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid redeclaration of %s, a redeclare may not have a condition attribute."));
public constant ErrorTypes.Message REDECLARE_OF_CONSTANT = ErrorTypes.MESSAGE(326, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s is constant and may not be redeclared."));
public constant ErrorTypes.Message REDECLARE_MISMATCHED_PREFIX = ErrorTypes.MESSAGE(327, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid redeclaration '%s %s', original element is declared '%s'."));
public constant ErrorTypes.Message EXTERNAL_ARG_NONCONSTANT_SIZE_INDEX = ErrorTypes.MESSAGE(328, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid external argument '%s', the dimension index must be a constant expression."));
public constant ErrorTypes.Message FAILURE_TO_DEDUCE_DIMS_EACH = ErrorTypes.MESSAGE(329, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to deduce dimension %s of ‘%s‘ due to ‘each‘ prefix on binding equation."));
public constant ErrorTypes.Message MISSING_TYPE_BASETYPE = ErrorTypes.MESSAGE(330, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type ‘%s‘ does not extend a basic type."));
public constant ErrorTypes.Message ASSERT_TRIGGERED_WARNING = ErrorTypes.MESSAGE(331, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("assert triggered: %s"));
public constant ErrorTypes.Message ASSERT_TRIGGERED_ERROR = ErrorTypes.MESSAGE(332, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("assert triggered: %s"));
public constant ErrorTypes.Message TERMINATE_TRIGGERED = ErrorTypes.MESSAGE(333, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("terminate triggered: %s"));
public constant ErrorTypes.Message EVAL_RECURSION_LIMIT_REACHED = ErrorTypes.MESSAGE(334, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The recursion limit (--evalRecursionLimit=%s) was exceeded during evaluation of %s."));
public constant ErrorTypes.Message UNASSIGNED_FUNCTION_OUTPUT = ErrorTypes.MESSAGE(335, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Output parameter %s was not assigned a value"));
public constant ErrorTypes.Message INVALID_WHEN_STATEMENT_CONTEXT = ErrorTypes.MESSAGE(336, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("A when-statement may not be used inside a function or a while, if, or for-clause."));
public constant ErrorTypes.Message MISSING_FUNCTION_DERIVATIVE_NAME = ErrorTypes.MESSAGE(337, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Derivative annotation for function ‘%s‘ does not specify a derivative function."));
public constant ErrorTypes.Message INVALID_FUNCTION_ANNOTATION_ATTR = ErrorTypes.MESSAGE(338, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("‘%s‘ is not a valid function %s attribute."));
public constant ErrorTypes.Message INVALID_FUNCTION_ANNOTATION_INPUT = ErrorTypes.MESSAGE(339, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("‘%s‘ is not an input of function ‘%s‘."));
public constant ErrorTypes.Message OPERATOR_OVERLOADING_ONE_OUTPUT_ERROR = ErrorTypes.MESSAGE(340, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Operator %s must have exactly one output."));
public constant ErrorTypes.Message OPERATOR_OVERLOADING_INVALID_OUTPUT_TYPE = ErrorTypes.MESSAGE(341, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Output ‘%s‘ in operator %s must be of type %s, got type %s."));
public constant ErrorTypes.Message OPERATOR_NOT_ENCAPSULATED = ErrorTypes.MESSAGE(342, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Operator %s is not encapsulated."));
public constant ErrorTypes.Message NO_SUCH_INPUT_PARAMETER = ErrorTypes.MESSAGE(343, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Function %s has no input parameter named %s."));
public constant ErrorTypes.Message INVALID_REDUCTION_TYPE = ErrorTypes.MESSAGE(344, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid expression ‘%s‘ of type %s in %s reduction, expected %s."));
public constant ErrorTypes.Message INVALID_COMPONENT_PREFIX = ErrorTypes.MESSAGE(345, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Prefix ‘%s‘ on component ‘%s‘ not allowed in class specialization ‘%s‘."));
public constant ErrorTypes.Message INVALID_CARDINALITY_CONTEXT = ErrorTypes.MESSAGE(346, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("cardinality may only be used in the condition of an if-statement/equation or an assert."));
public constant ErrorTypes.Message VARIABLE_BINDING_DIMS_MISMATCH = ErrorTypes.MESSAGE(347, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch in binding ‘%s = %s‘, expected array dimensions %s, got %s."));
public constant ErrorTypes.Message MODIFIER_NON_ARRAY_TYPE_ERROR = ErrorTypes.MESSAGE(348, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Non-array modification ‘%s‘ for array component ‘%s‘, possibly due to missing ‘each‘."));
public constant ErrorTypes.Message INST_RECURSION_LIMIT_REACHED = ErrorTypes.MESSAGE(349, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Recursion limit reached while instantiating ‘%s‘."));
public constant ErrorTypes.Message WHEN_IF_VARIABLE_MISMATCH = ErrorTypes.MESSAGE(350, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The branches of an if-equation inside a when-equation must have the same set of component references on the left-hand side."));
public constant ErrorTypes.Message DIMENSION_DEDUCTION_FROM_BINDING_FAILURE = ErrorTypes.MESSAGE(351, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Dimension %s of ‘%s‘ could not be deduced from the component's binding equation ‘%s‘."));
public constant ErrorTypes.Message NON_REAL_FLOW_OR_STREAM = ErrorTypes.MESSAGE(352, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid prefix ‘%s‘ on non-Real component ‘%s‘."));
public constant ErrorTypes.Message LIBRARY_UNEXPECTED_NAME_CASE_SENSITIVE = ErrorTypes.MESSAGE(353, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("Expected the package to have name %s, but got %s. Proceeding since only the case of the names are different."));
public constant ErrorTypes.Message PACKAGE_ORDER_CASE_SENSITIVE = ErrorTypes.MESSAGE(354, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("The package.order file contains a class %s, which is expected to be stored in file %s, but seems to be named %s. Proceeding since only the case of the names are different."));
public constant ErrorTypes.Message REDECLARE_CLASS_NON_SUBTYPE = ErrorTypes.MESSAGE(355, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Redeclaration of %s ‘%s‘ is not a subtype of the redeclared element."));
public constant ErrorTypes.Message REDECLARE_ENUM_NON_SUBTYPE = ErrorTypes.MESSAGE(356, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Redeclaration of enumeration ‘%s‘ is not a subtype of the redeclared element (use enumeration(:) for a generic replaceable enumeration)."));
public constant ErrorTypes.Message CONDITIONAL_COMPONENT_INVALID_CONTEXT = ErrorTypes.MESSAGE(357, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Conditional component ‘%s‘ is used in a non-connect context."));
public constant ErrorTypes.Message OPERATOR_RECORD_MISSING_OPERATOR = ErrorTypes.MESSAGE(358, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type ‘%s‘ of expression ‘%s‘ in ‘%s‘ does not implement the required operator ‘%s‘"));
public constant ErrorTypes.Message IMPORT_IN_COMPOSITE_NAME = ErrorTypes.MESSAGE(359, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Found imported name ‘%s‘ while looking up composite name ‘%s‘."));
public constant ErrorTypes.Message SHADOWED_ITERATOR = ErrorTypes.MESSAGE(360, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("An iterator named ‘%s‘ is already declared in this scope."));
public constant ErrorTypes.Message W_INVALID_ARGUMENT_TYPE_BRANCH_FIRST = ErrorTypes.MESSAGE(361, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("The first argument '%s' of %s must have the form A.R, where A is a connector and R an over-determined type/record."));
public constant ErrorTypes.Message W_INVALID_ARGUMENT_TYPE_BRANCH_SECOND = ErrorTypes.MESSAGE(362, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("The second argument '%s' of %s must have the form A.R, where A is a connector and R an over-determined type/record."));
public constant ErrorTypes.Message LIBRARY_WITHIN_WRONG_CASE = ErrorTypes.MESSAGE(363, ErrorTypes.GRAMMAR(), ErrorTypes.WARNING(),
  Gettext.gettext("Expected the package to have %s but got %s (ignoring the potential error; the class might have been inserted at an unexpected location)."));
public constant ErrorTypes.Message INVALID_FLAG_CONDITION = ErrorTypes.MESSAGE(364, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("Flag %s ignored: %s."));
public constant ErrorTypes.Message EXPERIMENTAL_REQUIRED = ErrorTypes.MESSAGE(365, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s is an experimental feature and requires the --std=experimental flag."));
public constant ErrorTypes.Message INVALID_NUMBER_OF_DIMENSIONS_FOR_PROMOTE = ErrorTypes.MESSAGE(366, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The second argument ‘%s‘ of promote may not be smaller than the number of dimensions (%s) of the first argument."));
public constant ErrorTypes.Message PURE_FUNCTION_WITH_IMPURE_CALLS = ErrorTypes.MESSAGE(367, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Pure function ‘%s‘ contains a call to impure function ‘%s‘."));
public constant ErrorTypes.Message DISCRETE_REAL_UNDEFINED = ErrorTypes.MESSAGE(368, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Following variable is discrete, but does not appear on the LHS of a when-statement: ‘%s‘."));
public constant ErrorTypes.Message DER_OF_NONDIFFERENTIABLE_EXP = ErrorTypes.MESSAGE(369, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Argument ‘%s‘ of der is not differentiable."));
public constant ErrorTypes.Message LOAD_MODEL_DIFFERENT_VERSIONS_WITHOUT_CONVERSION = ErrorTypes.MESSAGE(370, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("%1 requested package %2 of version %3. %2 %4 is used instead which states that it is fully compatible without conversion script needed."));
public constant ErrorTypes.Message LOAD_MODEL_DIFFERENT_VERSIONS_WITH_CONVERSION = ErrorTypes.MESSAGE(371, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("%1 requested package %2 of version %3. %2 %4 is used instead which states that it is only compatible with a conversion script. OpenModelica currently does not support conversion scripts and will proceed with potential issues as a result."));
public constant ErrorTypes.Message LOAD_MODEL_DIFFERENT_VERSIONS_OLDER = ErrorTypes.MESSAGE(372, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("Requested package %1 of version %2, but this package was already loaded with version %3. There are no conversion annotations and %2 is older than %3, so the libraries are probably incompatible."));
public constant ErrorTypes.Message LOAD_MODEL_DIFFERENT_VERSIONS_NEWER = ErrorTypes.MESSAGE(373, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("Requested package %1 of version %2, but this package was already loaded with version %3. There are no conversion annotations for this version but %2 is newer than %3. There is a possibility that %3 remains backwards compatible, but it is not loaded so OpenModelica cannot verify this."));
public constant ErrorTypes.Message EQUATION_NOT_SOLVABLE_DIFFERENT_COUNT = ErrorTypes.MESSAGE(374, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("%s has size %s but %s variables (%s)"));
public constant ErrorTypes.Message PARTIAL_COMPONENT_TYPE = ErrorTypes.MESSAGE(375, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Component ‘%s‘ has partial type ‘%s‘."));
public constant ErrorTypes.Message PARTIAL_FUNCTION_CALL = ErrorTypes.MESSAGE(376, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Called function ‘%s‘ is partial."));
public constant ErrorTypes.Message TOO_MANY_TYPE_VARS_IN_CALL = ErrorTypes.MESSAGE(377, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Too many type variables given in call to ‘%s‘."));
public constant ErrorTypes.Message BREAK_OUTSIDE_LOOP = ErrorTypes.MESSAGE(378, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("‘break' may only be used in a while- or for-loop."));
public constant ErrorTypes.Message TOP_LEVEL_OUTER = ErrorTypes.MESSAGE(379, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("The model can't be instantiated due to top-level outer element ‘%s‘, it may only be used as part of a simulation model."));
public constant ErrorTypes.Message MISSING_INNER_NAME_CONFLICT = ErrorTypes.MESSAGE(380, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("An inner declaration for outer element ‘%s‘ could not be found, and could not be automatically generated due to an existing declaration of that name."));
public constant ErrorTypes.Message TOP_LEVEL_INPUT_WITH_BINDING = ErrorTypes.MESSAGE(381, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Top-level input ‘%s‘ has a binding equation and will not be accessible as an input of the model."));
public constant ErrorTypes.Message NON_DISCRETE_WHEN_CONDITION = ErrorTypes.MESSAGE(382, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("When-condition ‘%s‘ is not a discrete-time expression."));
public constant ErrorTypes.Message CYCLIC_FUNCTION_COMPONENTS = ErrorTypes.MESSAGE(383, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Cyclically dependent function components found: %s"));
public constant ErrorTypes.Message EXTERNAL_FUNCTION_NOT_FOUND = ErrorTypes.MESSAGE(384, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("External function ‘%s‘ could not be found in any of the given shared libraries:\n%s"));
public constant ErrorTypes.Message INVALID_CONVERSION_RULE = ErrorTypes.MESSAGE(385, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid conversion rule ‘%s‘."));
public constant ErrorTypes.Message CONVERSION_MESSAGE = ErrorTypes.MESSAGE(386, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("%s"));
public constant ErrorTypes.Message CONVERSION_MISMATCHED_PLACEHOLDER = ErrorTypes.MESSAGE(387, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("Mismatched % in conversion modifier ‘%s‘."));
public constant ErrorTypes.Message CONVERSION_MISSING_PLACEHOLDER_VALUE = ErrorTypes.MESSAGE(388, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("No replacement value for placeholder ‘%s‘ could be found."));
public constant ErrorTypes.Message UNSUPPORTED_RECORD_REORDERING = ErrorTypes.MESSAGE(389, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The record constructor for ‘%s‘ requires reordering of local fields to initialize them in the correct order, which is not yet supported."));
public constant ErrorTypes.Message FUNCTION_INVALID_OUTPUTS_FOR_INVERSE = ErrorTypes.MESSAGE(390, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid inverse annotation for ‘%s‘, only functions with exactly one output may have an inverse."));
public constant ErrorTypes.Message NOTIFY_IMPLICIT_LOAD = ErrorTypes.MESSAGE(391, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Automatically loaded package %s %s due to usage."));
public constant ErrorTypes.Message CONVERSION_MISSING_USES = ErrorTypes.MESSAGE(392, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Cannot convert ‘%s‘ since it has no uses-annotation for ‘%s‘."));
public constant ErrorTypes.Message CONVERSION_NO_COMPATIBLE_SCRIPT_FOUND = ErrorTypes.MESSAGE(393, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("No compatible conversion script for converting from %s %s to %s could be found."));

public constant Gettext.TranslatableContent FUNCTION_CALL_EXPRESSION = Gettext.gettext("a function call expression");
public constant ErrorTypes.Message FUNCTION_ARGUMENT_MUST_BE = ErrorTypes.MESSAGE(394, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("The argument to ‘%s‘ must be %s."));
public constant ErrorTypes.Message UNEXPECTED_COMPONENT_IN_COMPOSITE_NAME = ErrorTypes.MESSAGE(395, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Found component ‘%s‘ in composite name ‘%s‘, expected class."));

public constant ErrorTypes.Message INITIALIZATION_NOT_FULLY_SPECIFIED = ErrorTypes.MESSAGE(496, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("The initial conditions are not fully specified. %s."));
public constant ErrorTypes.Message INITIALIZATION_OVER_SPECIFIED = ErrorTypes.MESSAGE(497, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("The initial conditions are over specified. %s."));
public constant ErrorTypes.Message INITIALIZATION_ITERATION_VARIABLES = ErrorTypes.MESSAGE(498, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("There are nonlinear iteration variables with default zero start attribute found in %s. %s."));
public constant ErrorTypes.Message UNBOUND_PARAMETER_WITH_START_VALUE_WARNING = ErrorTypes.MESSAGE(499, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Parameter %s has no value, and is fixed during initialization (fixed=true), using available start value (start=%s) as default value."));
public constant ErrorTypes.Message UNBOUND_PARAMETER_WARNING = ErrorTypes.MESSAGE(500, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Parameter %s has neither value nor start value, and is fixed during initialization (fixed=true)."));
public constant ErrorTypes.Message BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER = ErrorTypes.MESSAGE(502, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Function \"product\" has scalar as argument in %s in component %s."));
public constant ErrorTypes.Message SETTING_FIXED_ATTRIBUTE = ErrorTypes.MESSAGE(503, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Using over-determined solver for initialization. Setting fixed=false to the following variables: %s."));
public constant ErrorTypes.Message FAILED_TO_EVALUATE_FUNCTION = ErrorTypes.MESSAGE(506, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to evaluate function: %s."));
public constant ErrorTypes.Message WARNING_RELATION_ON_REAL = ErrorTypes.MESSAGE(509, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("In relation %s, %s on Real numbers is only allowed inside functions."));
public constant ErrorTypes.Message OUTER_MODIFICATION = ErrorTypes.MESSAGE(512, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Ignoring the modification on outer element: %s."));
public constant ErrorTypes.Message DERIVATIVE_NON_REAL = ErrorTypes.MESSAGE(514, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Argument '%s' to der has illegal type %s, must be a subtype of Real."));
public constant ErrorTypes.Message UNUSED_MODIFIER = ErrorTypes.MESSAGE(515, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("In modifier %s."));
public constant ErrorTypes.Message MULTIPLE_MODIFIER = ErrorTypes.MESSAGE(516, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Multiple modifiers in same scope for element %s."));
public constant ErrorTypes.Message INCONSISTENT_UNITS = ErrorTypes.MESSAGE(517, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("The system of units is inconsistent in term %s with the units %s and %s respectively."));
public constant ErrorTypes.Message CONSISTENT_UNITS = ErrorTypes.MESSAGE(518, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("The system of units is consistent."));
public constant ErrorTypes.Message INCOMPLETE_UNITS = ErrorTypes.MESSAGE(519, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("The system of units is incomplete. Please provide unit information to the model by e.g. using types from the SIunits package."));
public constant ErrorTypes.Message ASSIGN_RHS_ELABORATION = ErrorTypes.MESSAGE(521, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to elaborate rhs of %s."));
public constant ErrorTypes.Message FAILED_TO_EVALUATE_EXPRESSION = ErrorTypes.MESSAGE(522, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Could not evaluate expression: %s"));
public constant ErrorTypes.Message WARNING_JACOBIAN_EQUATION_SOLVE = ErrorTypes.MESSAGE(523, ErrorTypes.SYMBOLIC(), ErrorTypes.WARNING(),
  Gettext.gettext("Jacobian equation %s could not solve proper for %s. Assume %s=0."));
public constant ErrorTypes.Message SIMPLIFICATION_COMPLEXITY = ErrorTypes.MESSAGE(523, ErrorTypes.SYMBOLIC(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Simplification produced a higher complexity (%s) than the original (%s). The simplification was: %s => %s."));
public constant ErrorTypes.Message ITERATOR_NON_ARRAY = ErrorTypes.MESSAGE(524, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Iterator %s, has type %s, but expected a 1D array expression."));
public constant ErrorTypes.Message INST_INVALID_RESTRICTION = ErrorTypes.MESSAGE(525, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Cannot instantiate %s due to class specialization %s."));
public constant ErrorTypes.Message INST_NON_LOADED = ErrorTypes.MESSAGE(526, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Library %s was not loaded but is marked as used by model %s."));
public constant ErrorTypes.Message RECURSION_DEPTH_REACHED = ErrorTypes.MESSAGE(527, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The maximum recursion depth of %s was reached, probably due to mutual recursion. The current scope: %s."));
public constant ErrorTypes.Message DERIVATIVE_INPUT = ErrorTypes.MESSAGE(528, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The model requires derivatives of some inputs as listed below:\n%s"));
public constant ErrorTypes.Message UTF8_COMMAND_LINE_ARGS = ErrorTypes.MESSAGE(529, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The compiler was sent command-line arguments that were not UTF-8 encoded and will abort the current execution."));
public constant ErrorTypes.Message PACKAGE_ORDER_FILE_NOT_COMPLETE = ErrorTypes.MESSAGE(530, ErrorTypes.GRAMMAR(), ErrorTypes.WARNING(),
  Gettext.gettext("The package.order file does not list all .mo files and directories (containing package.mo) present in its directory.\nMissing names are:\n\t%s"));
public constant ErrorTypes.Message REINIT_IN_WHEN_INITIAL = ErrorTypes.MESSAGE(531, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Using reinit in when with condition initial() is not allowed. Use assignment or equality equation instead."));
public constant ErrorTypes.Message MISSING_INNER_CLASS = ErrorTypes.MESSAGE(532, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("No corresponding 'inner' declaration found for class %s declared as '%s'.\n Continuing flattening by only considering the 'outer' class declaration."));
public constant ErrorTypes.Message RECURSION_DEPTH_WARNING = ErrorTypes.MESSAGE(533, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The maximum recursion depth of %s was reached when evaluating expression %s in scope %s. Translation may still succeed but you are recommended to fix the problem."));
public constant ErrorTypes.Message RECURSION_DEPTH_DERIVED = ErrorTypes.MESSAGE(534, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The maximum recursion depth of was reached when instantiating a derived class. Current class %s in scope %s."));
public constant ErrorTypes.Message EVAL_EXTERNAL_OBJECT_CONSTRUCTOR = ErrorTypes.MESSAGE(535, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("OpenModelica requires that all external objects input arguments are possible to evaluate before initialization in order to avoid odd run-time failures, but %s is a variable."));
public constant ErrorTypes.Message CLASS_ANNOTATION_DOES_NOT_EXIST = ErrorTypes.MESSAGE(536, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Could not find class annotation %s in class %s."));
public constant ErrorTypes.Message SEPARATE_COMPILATION_PACKAGE_FAILED = ErrorTypes.MESSAGE(537, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to compile all functions in package %s."));
public constant ErrorTypes.Message INVALID_ARRAY_DIM_IN_SCALAR_OP = ErrorTypes.MESSAGE(538, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The operator scalar requires all dimension size to be 1, but the input has type %s."));
public constant ErrorTypes.Message NON_STANDARD_OPERATOR_CLASS_DIRECTORY = ErrorTypes.MESSAGE(539, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("classDirectory() is a non-standard operator that was replaced by Modelica.Utilities.Files.loadResource(uri) before it was added to the language specification."));
public constant ErrorTypes.Message PACKAGE_DUPLICATE_CHILDREN = ErrorTypes.MESSAGE(540, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The same class is defined in multiple files: %s."));
public constant ErrorTypes.Message INTEGER_ENUMERATION_CONVERSION_WARNING = ErrorTypes.MESSAGE(541, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Integer (%s) to enumeration (%s) conversion is not valid Modelica, please use enumeration constant (%s) instead."));
public constant ErrorTypes.Message INTEGER_ENUMERATION_OUT_OF_RANGE = ErrorTypes.MESSAGE(542, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The Integer to %s conversion failed, as the Integer %s is outside the range (1, ..., %s) of values corresponding to enumeration constants."));
public constant ErrorTypes.Message INTEGER_TO_UNKNOWN_ENUMERATION = ErrorTypes.MESSAGE(543, ErrorTypes.TRANSLATION(), ErrorTypes.INTERNAL(),
  Gettext.gettext("The Integer (%s) to enumeration conversion failed because information about the the enumeration type is missing."));
public constant ErrorTypes.Message NORETCALL_INVALID_EXP = ErrorTypes.MESSAGE(544, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Expression %s is not a valid statement - only function calls are allowed."));
public constant ErrorTypes.Message INVALID_FLAG_TYPE_STRINGS = ErrorTypes.MESSAGE(545, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid type of flag %s, expected one of %s but got %s."));
public constant ErrorTypes.Message FUNCTION_RETURN_EXT_OBJ = ErrorTypes.MESSAGE(546, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Function %s returns an external object, but the only function allowed to return this object is %s."));
public constant ErrorTypes.Message NON_STANDARD_OPERATOR = ErrorTypes.MESSAGE(547, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Usage of non-standard operator (not specified in the Modelica specification): %s. Functionality might be partially supported but is not guaranteed."));
public constant ErrorTypes.Message CONNECT_ARRAY_SIZE_ZERO = ErrorTypes.MESSAGE(548, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Ignoring connection of array components having size zero: %s and %s."));
public constant ErrorTypes.Message ILLEGAL_RECORD_COMPONENT = ErrorTypes.MESSAGE(549, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Ignoring record component:\n%swhen building the record constructor. Records are allowed to contain only components of basic types, arrays of basic types or other records."));
public constant ErrorTypes.Message EQ_WITHOUT_TIME_DEP_VARS = ErrorTypes.MESSAGE(550, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("Found equation without time-dependent variables: %s = %s"));
public constant ErrorTypes.Message OVERCONSTRAINED_OPERATOR_SIZE_ZERO = ErrorTypes.MESSAGE(551, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Ignoring overconstrained operator applied to array components having size zero: %s."));
public constant ErrorTypes.Message OVERCONSTRAINED_OPERATOR_SIZE_ZERO_RETURN_FALSE = ErrorTypes.MESSAGE(552, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Returning false from overconstrained operator applied to array components having size zero: %s."));
public constant ErrorTypes.Message MISMATCHING_INTERFACE_TYPE = ErrorTypes.MESSAGE(553, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("__OpenModelica_Interface types are incompatible. Got interface type '%s', expected something compatible with '%s'."));
public constant ErrorTypes.Message MISSING_INTERFACE_TYPE = ErrorTypes.MESSAGE(554, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Annotation __OpenModelica_Interface is missing or the string is not in the input list."));
public constant ErrorTypes.Message CLASS_NOT_FOUND = ErrorTypes.MESSAGE(555, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("Class %s not found inside class %s."));
public constant ErrorTypes.Message NOTIFY_LOAD_MODEL_FAILED = ErrorTypes.MESSAGE(556, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Skipped loading package %s (%s) using MODELICAPATH %s (uses-annotation may be wrong)."));
public constant ErrorTypes.Message ROOT_USER_INTERACTIVE = ErrorTypes.MESSAGE(557, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("You are trying to run OpenModelica as a server using the root user.\nThis is a very bad idea:\n* The socket interface does not authenticate the user.\n* OpenModelica allows execution of arbitrary commands."));
public constant ErrorTypes.Message USES_MISSING_VERSION = ErrorTypes.MESSAGE(558, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("Uses-annotation is missing version for library %s. Assuming the tool-specific version=\"default\"."));
public constant ErrorTypes.Message CLOCK_PREFIX_ERROR = ErrorTypes.MESSAGE(559, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Clock variable can not be declared with prefixes flow, stream, discrete, parameter, or constant."));
public constant ErrorTypes.Message DEFAULT_CLOCK_USED = ErrorTypes.MESSAGE(560, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Default inferred clock is used."));
public constant ErrorTypes.Message CONT_CLOCKED_PARTITION_CONFLICT_VAR = ErrorTypes.MESSAGE(561, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Variable %s belongs to clocked and continuous partitions."));
public constant ErrorTypes.Message ELSE_WHEN_CLOCK = ErrorTypes.MESSAGE(562, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Clocked when equation can not contain elsewhen part."));
public constant ErrorTypes.Message REINIT_NOT_IN_WHEN = ErrorTypes.MESSAGE(563, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Operator reinit may only be used in the body of a when equation."));
public constant ErrorTypes.Message NESTED_CLOCKED_WHEN = ErrorTypes.MESSAGE(564, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Nested clocked when statements are not allowed."));
public constant ErrorTypes.Message CLOCKED_WHEN_BRANCH = ErrorTypes.MESSAGE(565, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Clocked when branch in when equation."));
public constant ErrorTypes.Message CLOCKED_WHEN_IN_WHEN_EQ = ErrorTypes.MESSAGE(566, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Clocked when equation inside the body of when equation."));
public constant ErrorTypes.Message CONT_CLOCKED_PARTITION_CONFLICT_EQ = ErrorTypes.MESSAGE(567, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Equation belongs to clocked and continuous partitions."));
public constant ErrorTypes.Message CLOCK_SOLVERMETHOD = ErrorTypes.MESSAGE(568, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Applying clock solverMethod %s instead of specified %s. Supported are: ImplicitEuler, SemiImplicitEuler, ExplicitEuler and ImplicitTrapezoid."));
public constant ErrorTypes.Message INVALID_CLOCK_EQUATION = ErrorTypes.MESSAGE(569, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid form of clock equation"));
public constant ErrorTypes.Message SUBCLOCK_CONFLICT = ErrorTypes.MESSAGE(570, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Partition has different sub-clock %ss (%s) and (%s)."));
public constant ErrorTypes.Message CLOCK_CONFLICT = ErrorTypes.MESSAGE(571, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Partitions have different base clocks."));
public constant ErrorTypes.Message EXEC_STAT = ErrorTypes.MESSAGE(572, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Performance of %s: time %s/%s, allocations: %s / %s, free: %s / %s"));
public constant ErrorTypes.Message EXEC_STAT_GC = ErrorTypes.MESSAGE(573, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Performance of %s: time %s/%s, GC stats:%s"));
public constant ErrorTypes.Message MAX_TEARING_SIZE = ErrorTypes.MESSAGE(574, ErrorTypes.SYMBOLIC(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Tearing is skipped for strong component %s because system size of %s exceeds maximum system size for tearing of %s systems (%s).\nTo adjust the maximum system size for tearing use --%s=<size>.\n"));
public constant ErrorTypes.Message NO_TEARING_FOR_COMPONENT = ErrorTypes.MESSAGE(575, ErrorTypes.SYMBOLIC(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Tearing is skipped for strong component %s because of activated compiler flag 'noTearingForComponent=%1'.\n"));
public constant ErrorTypes.Message WRONG_VALUE_OF_ARG = ErrorTypes.MESSAGE(576, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Wrong value of argument to %s: %s = %s %s."));
public constant ErrorTypes.Message USER_DEFINED_TEARING_ERROR = ErrorTypes.MESSAGE(577, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("Wrong usage of user defined tearing: %s Make sure you use user defined tearing as stated in the flag description."));
public constant ErrorTypes.Message USER_TEARING_VARS = ErrorTypes.MESSAGE(578, ErrorTypes.SYMBOLIC(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Following iteration variables are selected by the user for strong component %s (DAE kind: %s):\n%s"));
public constant ErrorTypes.Message CLASS_EXTENDS_TARGET_NOT_FOUND = ErrorTypes.MESSAGE(579, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Base class targeted by class extends %s not found in the inherited classes."));
public constant ErrorTypes.Message ASSIGN_PARAM_FIXED_ERROR = ErrorTypes.MESSAGE(580, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Trying to assign to parameter component %s(fixed=true) in %s := %s"));
public constant ErrorTypes.Message EQN_NO_SPACE_TO_SOLVE = ErrorTypes.MESSAGE(581, ErrorTypes.SYMBOLIC(), ErrorTypes.WARNING(),
  Gettext.gettext("Equation %s (size: %s) %s is not big enough to solve for enough variables.\n  Remaining unsolved variables are: %s\n  Already solved: %s\n  Equations used to solve those variables:%s"));
public constant ErrorTypes.Message VAR_NO_REMAINING_EQN = ErrorTypes.MESSAGE(582, ErrorTypes.SYMBOLIC(), ErrorTypes.WARNING(),
  Gettext.gettext("Variable %s does not have any remaining equation to be solved in.\n  The original equations were:%s"));
public constant ErrorTypes.Message MOVING_PARAMETER_BINDING_TO_INITIAL_EQ_SECTION = ErrorTypes.MESSAGE(583, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Moving binding to initial equation section and setting fixed attribute of %s to false."));
public constant ErrorTypes.Message MIXED_DETERMINED = ErrorTypes.MESSAGE(584, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("The initialization problem of given system is mixed-determined. It is under- as well as overdetermined and the mixed-determination-index is too high. [index > %s]\nPlease checkout the option \"--maxMixedDeterminedIndex\" to simulate with a higher threshold or consider changing some initial equations, fixed variables and start values. Use -d=initialization for more information."));
public constant ErrorTypes.Message STACK_OVERFLOW_DETAILED = ErrorTypes.MESSAGE(585, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Stack overflow occurred while evaluating %s:\n%s"));
public constant ErrorTypes.Message NF_VECTOR_INVALID_DIMENSIONS = ErrorTypes.MESSAGE(586, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid dimensions %s in %s, no more than one dimension may have size > 1."));
public constant ErrorTypes.Message NF_ARRAY_TYPE_MISMATCH = ErrorTypes.MESSAGE(587, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Array types mismatch. Argument %s (%s) has type %s whereas previous arguments have type %s."));
public constant ErrorTypes.Message NF_DIFFERENT_NUM_DIM_IN_ARGUMENTS = ErrorTypes.MESSAGE(588, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Different number of dimensions (%s) in arguments to %s."));
public constant ErrorTypes.Message NF_CAT_WRONG_DIMENSION = ErrorTypes.MESSAGE(589, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The first argument of cat characterizes an existing dimension in the other arguments (1..%s), but got dimension %s."));
public constant ErrorTypes.Message NF_CAT_FIRST_ARG_EVAL = ErrorTypes.MESSAGE(590, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The first argument of cat must be possible to evaluate during compile-time. Expression %s has variability %s."));
public constant ErrorTypes.Message COMMA_OPERATOR_DIFFERENT_SIZES = ErrorTypes.MESSAGE(591, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Arguments of concatenation comma operator have different sizes for the first dimension: %s has dimension %s and %s has dimension %s."));
public constant ErrorTypes.Message NON_STATE_STATESELECT_ALWAYS = ErrorTypes.MESSAGE(592, ErrorTypes.SYMBOLIC(), ErrorTypes.WARNING(),
  Gettext.gettext("Variable %s has attribute stateSelect=StateSelect.always, but can't be selected as a state."));
public constant ErrorTypes.Message STATE_STATESELECT_NEVER = ErrorTypes.MESSAGE(593, ErrorTypes.SYMBOLIC(), ErrorTypes.WARNING(),
  Gettext.gettext("Variable %s has attribute stateSelect=StateSelect.never, but was selected as a state"));
public constant ErrorTypes.Message FUNCTION_HIGHER_VARIABILITY_BINDING = ErrorTypes.MESSAGE(594, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Component ‘%s’ of variability %s has binding %s of higher variability %s."));
public constant ErrorTypes.Message OCG_MISSING_BRANCH = ErrorTypes.MESSAGE(595, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Connections.rooted(%s) needs exactly one statement Connections.branch(%s, B.R) involving %s but we found none in the graph. Run with -d=cgraphGraphVizFile to debug"));
public constant ErrorTypes.Message UNBOUND_PARAMETER_EVALUATE_TRUE = ErrorTypes.MESSAGE(596, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Parameter %s has annotation(Evaluate=true) and no binding."));
public constant ErrorTypes.Message FMI_URI_RESOLVE = ErrorTypes.MESSAGE(597, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Could not resolve URI (%s) at compile-time; copying all loaded packages into the FMU"));
public constant ErrorTypes.Message PATTERN_MIXED_POS_NAMED = ErrorTypes.MESSAGE(598, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Call to %s contains mixed positional and named arguments."));
public constant ErrorTypes.Message STATE_STATESELECT_NEVER_FORCED = ErrorTypes.MESSAGE(599, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Following variables have attribute stateSelect=StateSelect.never, but cant be statically chosen. %s"));
public constant ErrorTypes.Message STATE_STATESELECT_PREFER_REVERT = ErrorTypes.MESSAGE(600, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("Some equations could not be differentiated for following variables having attribute stateSelect=StateSelect.prefer. %s"));
public constant ErrorTypes.Message ERROR_PKG_NOT_IDENT = ErrorTypes.MESSAGE(601, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("The package manager only accepts simple identifiers (%s has a dot in it)."));
public constant ErrorTypes.Message ERROR_PKG_NOT_FOUND_VERSION = ErrorTypes.MESSAGE(602, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("The package index did not contain an entry for package %s that provides version %s. The following versions are available:\n%s"));
public constant ErrorTypes.Message ERROR_PKG_NOT_EXACT_MATCH = ErrorTypes.MESSAGE(603, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("The package index did not contain an entry for package %s of version %s. There are other versions that claim to be compatible: %s."));
public constant ErrorTypes.Message ERROR_PKG_INDEX_NOT_ON_PATH = ErrorTypes.MESSAGE(604, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("The MODELICAPATH (%s) does not contain %s, so the package index cannot be used."));
public constant ErrorTypes.Message ERROR_PKG_INDEX_NOT_FOUND = ErrorTypes.MESSAGE(605, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("The package index does not exist: %s."));
public constant ErrorTypes.Message ERROR_PKG_INDEX_NOT_PARSED = ErrorTypes.MESSAGE(606, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("The package index %s could not be parsed."));
public constant ErrorTypes.Message ERROR_PKG_INDEX_FAILED_DOWNLOAD = ErrorTypes.MESSAGE(607, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to download package index %s to file %s."));
public constant ErrorTypes.Message NOTIFY_PKG_INDEX_DOWNLOAD = ErrorTypes.MESSAGE(608, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Downloaded package index from URL %s."));
public constant ErrorTypes.Message NOTIFY_PKG_INSTALL_DONE = ErrorTypes.MESSAGE(609, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Package installed successfully (SHA %s)."));
public constant ErrorTypes.Message NOTIFY_PKG_UPGRADE_DONE = ErrorTypes.MESSAGE(609, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Package upgraded successfully (SHA %s from %s)."));
public constant ErrorTypes.Message ERROR_PKG_INSTALL_NO_PACKAGE_MO = ErrorTypes.MESSAGE(611, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("After extracting %s, %s does not exist. Removing the failed installation."));
public constant ErrorTypes.Message WARNING_PKG_CONFLICTING_VERSIONS = ErrorTypes.MESSAGE(612, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("Conflicting versions for loading package %s: %s is to be installed, but another package requires version %s which is not provided by this version."));
public constant ErrorTypes.Message NOTIFY_PKG_NO_INSTALL = ErrorTypes.MESSAGE(613, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("%s %s will not be installed since version %s is installed."));
public constant ErrorTypes.Message DEPRECATED_FLAG = ErrorTypes.MESSAGE(614, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("The flag '%s' is deprecated. Please use '%s' instead."));
public constant ErrorTypes.Message UNKNOWN_ERROR_INST_FUNCTION = ErrorTypes.MESSAGE(615, ErrorTypes.TRANSLATION(), ErrorTypes.INTERNAL(),
  Gettext.gettext("Unknown error trying to instantiate function: %s."));

public constant ErrorTypes.Message MATCH_SHADOWING = ErrorTypes.MESSAGE(5001, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Local variable '%s' shadows another variable."));
public constant ErrorTypes.Message META_POLYMORPHIC = ErrorTypes.MESSAGE(5002, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s uses invalid subtypeof syntax. Only subtypeof Any is supported."));
public constant ErrorTypes.Message META_FUNCTION_TYPE_NO_PARTIAL_PREFIX = ErrorTypes.MESSAGE(5003, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("%s is used as a function reference, but doesn't specify the partial prefix."));
public constant ErrorTypes.Message META_MATCH_EQUATION_FORBIDDEN = ErrorTypes.MESSAGE(5004, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Match expression equation sections forbid the use of %s-equations."));
public constant ErrorTypes.Message META_UNIONTYPE_ALIAS_MODS = ErrorTypes.MESSAGE(5005, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Uniontype %s was not generated correctly. One possible cause is modifications, which are not allowed."));
public constant ErrorTypes.Message META_COMPLEX_TYPE_MOD = ErrorTypes.MESSAGE(5006, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("MetaModelica complex types may not have modifiers."));
public constant ErrorTypes.Message META_CEVAL_FUNCTION_REFERENCE = ErrorTypes.MESSAGE(5008, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Cannot evaluate function pointers (got %s)."));
public constant ErrorTypes.Message NON_INSTANTIATED_FUNCTION = ErrorTypes.MESSAGE(5009, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Tried to use function %s, but it was not instantiated."));
public constant ErrorTypes.Message META_UNSOLVED_POLYMORPHIC_BINDINGS = ErrorTypes.MESSAGE(5010, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Could not solve the polymorphism in the function call to %s\n  Input bindings:\n%s\n  Solved bindings:\n%s\n  Unsolved bindings:\n%s"));
public constant ErrorTypes.Message META_RECORD_FOUND_FAILURE = ErrorTypes.MESSAGE(5011, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("In record constructor %s: %s"));
public constant ErrorTypes.Message META_INVALID_PATTERN = ErrorTypes.MESSAGE(5012, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid pattern: %s"));
public constant ErrorTypes.Message META_MATCH_GENERAL_FAILURE = ErrorTypes.MESSAGE(5014, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to elaborate match expression %s"));
public constant ErrorTypes.Message META_CONS_TYPE_MATCH = ErrorTypes.MESSAGE(5015, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Failed to match types of cons expression %s. The head has type %s and the tail %s."));
public constant ErrorTypes.Message META_NONE_CREF = ErrorTypes.MESSAGE(5017, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("NONE is not acceptable syntax. Use NONE() instead."));
public constant ErrorTypes.Message META_INVALID_PATTERN_NAMED_FIELD = ErrorTypes.MESSAGE(5018, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid named fields: %s. Valid field names: %s."));
public constant ErrorTypes.Message META_INVALID_LOCAL_ELEMENT = ErrorTypes.MESSAGE(5019, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Only components without direction are allowed in local declarations, got: %s"));
public constant ErrorTypes.Message META_INVALID_COMPLEX_TYPE = ErrorTypes.MESSAGE(5020, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Invalid complex type name: %s"));
public constant ErrorTypes.Message META_CONSTRUCTOR_NOT_PART_OF_UNIONTYPE = ErrorTypes.MESSAGE(5021, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("In pattern %s: %s is not part of uniontype %s"));
public constant ErrorTypes.Message META_TYPE_MISMATCH_PATTERN = ErrorTypes.MESSAGE(5022, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Type mismatch in pattern %s\nexpression type:\n  %s\npattern type:\n  %s"));
public constant ErrorTypes.Message META_CONSTRUCTOR_NOT_RECORD = ErrorTypes.MESSAGE(5023, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Call pattern is not a record constructor %s"));
public constant ErrorTypes.Message META_MATCHEXP_RESULT_TYPES = ErrorTypes.MESSAGE(5024, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Match expression has mismatched result types:%s"));
public constant ErrorTypes.Message MATCHCONTINUE_TO_MATCH_OPTIMIZATION = ErrorTypes.MESSAGE(5025, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("This matchcontinue expression has no overlapping patterns and should be using match instead of matchcontinue."));
public constant ErrorTypes.Message META_DEAD_CODE = ErrorTypes.MESSAGE(5026, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Dead code elimination: %s."));
public constant ErrorTypes.Message META_UNUSED_DECL = ErrorTypes.MESSAGE(5027, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Unused local variable: %s."));
public constant ErrorTypes.Message META_UNUSED_AS_BINDING = ErrorTypes.MESSAGE(5028, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Removing unused as-binding: %s."));
public constant ErrorTypes.Message MATCH_TO_SWITCH_OPTIMIZATION = ErrorTypes.MESSAGE(5029, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Converted match expression to switch of type %s."));
public constant ErrorTypes.Message REDUCTION_TYPE_ERROR = ErrorTypes.MESSAGE(5030, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Reductions require the types of the %s and %s to be %s, but got: %s and %s."));
public constant ErrorTypes.Message UNSUPPORTED_REDUCTION_TYPE = ErrorTypes.MESSAGE(5031, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Expected a reduction function with type signature ('A,'B) => 'B, but got %s."));
public constant ErrorTypes.Message FOUND_NON_NUMERIC_TYPES = ErrorTypes.MESSAGE(5032, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Operator %s expects numeric types as operands, but got '%s and %s'."));
public constant ErrorTypes.Message STRUCTURAL_PARAMETER_OR_CONSTANT_WITH_NO_BINDING = ErrorTypes.MESSAGE(5033, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Could not evaluate structural parameter (or constant): %s which gives dimensions of array: %s. Array dimensions must be known at compile time."));
public constant ErrorTypes.Message META_UNUSED_ASSIGNMENT = ErrorTypes.MESSAGE(5034, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Removing unused assignment to: %s."));
public constant ErrorTypes.Message META_EMPTY_CALL_PATTERN = ErrorTypes.MESSAGE(5035, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Removing empty call named pattern argument: %s."));
public constant ErrorTypes.Message META_ALL_EMPTY = ErrorTypes.MESSAGE(5036, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("All patterns in call were empty: %s."));
public constant ErrorTypes.Message DUPLICATE_DEFINITION = ErrorTypes.MESSAGE(5037, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("The same variable is being defined twice: %s."));
public constant ErrorTypes.Message PATTERN_VAR_NOT_VARIABLE = ErrorTypes.MESSAGE(5038, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Identifiers need to point to local or output variables. Variable %s is %s."));
public constant ErrorTypes.Message LIST_REVERSE_WRONG_ORDER = ErrorTypes.MESSAGE(5039, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.gettext("%1:=listAppend(%1, _) has the first argument in the \"wrong\" order.\n  It is very slow to keep appending a linked list (scales like O(N²)).\n  Consider building the list in the reverse order in order to improve performance (scales like O(N) even if you need to reverse a lot of lists). Use annotation __OpenModelica_DisableListAppendWarning=true to disable this message for a certain assignment."));
public constant ErrorTypes.Message IS_PRESENT_WRONG_SCOPE = ErrorTypes.MESSAGE(5040, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("isPresent needs to be called from a function scope, got %s."));
public constant ErrorTypes.Message IS_PRESENT_WRONG_DIRECTION = ErrorTypes.MESSAGE(5041, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("isPresent needs to be called on an input or output formal parameter."));
public constant ErrorTypes.Message IS_PRESENT_INVALID_EXP = ErrorTypes.MESSAGE(5042, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("isPresent needs to be called on an input or output formal parameter, but got a non-identifier expression: %s."));
public constant ErrorTypes.Message METARECORD_WITH_TYPEVARS = ErrorTypes.MESSAGE(5043, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Records inside uniontypes must not contain type variables (got: %s). Put them on the uniontype instead."));
public constant ErrorTypes.Message UNIONTYPE_MISSING_TYPEVARS = ErrorTypes.MESSAGE(5044, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Uniontype %s has type variables, but they were not given in the declaration."));
public constant ErrorTypes.Message UNIONTYPE_WRONG_NUM_TYPEVARS = ErrorTypes.MESSAGE(5045, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Uniontype %s has %s type variables, but got %s."));
public constant ErrorTypes.Message SERIALIZED_SIZE = ErrorTypes.MESSAGE(5046, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("%s uses %s of memory (%s without GC overhead; %s is consumed by not performing String sharing)."));
public constant ErrorTypes.Message META_MATCH_CONSTANT = ErrorTypes.MESSAGE(5047, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Match input %s is a constant value."));
public constant ErrorTypes.Message CONVERSION_MISSING_FROM_VERSION = ErrorTypes.MESSAGE(5048, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("Conversion-annotation is missing version for from-conversion: %s."));
public constant ErrorTypes.Message CONVERSION_UNKNOWN_ANNOTATION = ErrorTypes.MESSAGE(5049, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("Conversion-annotation contains unknown element: %s."));


public constant ErrorTypes.Message COMPILER_ERROR = ErrorTypes.MESSAGE(5999, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.notrans("%s"));
public constant ErrorTypes.Message COMPILER_WARNING = ErrorTypes.MESSAGE(6000, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.notrans("%s"));
public constant ErrorTypes.Message COMPILER_NOTIFICATION = ErrorTypes.MESSAGE(6001, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.notrans("%s"));
public constant ErrorTypes.Message COMPILER_NOTIFICATION_SCRIPTING = ErrorTypes.MESSAGE(6002, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.notrans("%s"));
public constant ErrorTypes.Message SUSAN_ERROR = ErrorTypes.MESSAGE(7000, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.notrans("%s"));
public constant ErrorTypes.Message TEMPLATE_ERROR = ErrorTypes.MESSAGE(7001, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Template error: %s."));
public constant ErrorTypes.Message PARMODELICA_WARNING = ErrorTypes.MESSAGE(7004, ErrorTypes.TRANSLATION(), ErrorTypes.WARNING(),
  Gettext.notrans("ParModelica: %s."));
public constant ErrorTypes.Message PARMODELICA_ERROR = ErrorTypes.MESSAGE(7005, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.notrans("ParModelica: %s."));
public constant ErrorTypes.Message OPTIMICA_ERROR = ErrorTypes.MESSAGE(7006, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.notrans("Optimica: %s."));
public constant ErrorTypes.Message FILE_NOT_FOUND_ERROR = ErrorTypes.MESSAGE(7007, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("File not Found: %s."));
public constant ErrorTypes.Message UNKNOWN_FMU_VERSION = ErrorTypes.MESSAGE(7008, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Unknown FMU version %s. Only version 1.0 & 2.0 are supported."));
public constant ErrorTypes.Message UNKNOWN_FMU_TYPE = ErrorTypes.MESSAGE(7009, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Unknown FMU type %s. Supported types are me (model exchange), cs (co-simulation) & me_cs (model exchange & co-simulation)."));
public constant ErrorTypes.Message FMU_EXPORT_NOT_SUPPORTED = ErrorTypes.MESSAGE(7010, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Export of FMU type %s for version %s is not supported. Supported combinations are me (model exchange) for versions 1.0 & 2.0, cs (co-simulation) & me_cs (model exchange & co-simulation) for version 2.0."));
// FIGARO_ERROR added by Alexander Carlqvist
public constant ErrorTypes.Message FIGARO_ERROR = ErrorTypes.MESSAGE(7011, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.notrans("Figaro: %s."));
public constant ErrorTypes.Message SUSAN_NOTIFY = ErrorTypes.MESSAGE(7012, ErrorTypes.TRANSLATION(), ErrorTypes.NOTIFICATION(),
  Gettext.notrans("%s"));
public constant ErrorTypes.Message PDEModelica_ERROR = ErrorTypes.MESSAGE(7013, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("PDEModelica: %s"));
public constant ErrorTypes.Message TEMPLATE_ERROR_FUNC = ErrorTypes.MESSAGE(7014, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Template error: A template call failed (%s). One possible reason could be that a template imported function call failed (which should not happen for functions called from within template code; templates assert pure 'match'/non-failing semantics)."));
public constant ErrorTypes.Message FMU_EXPORT_NOT_SUPPORTED_CPP = ErrorTypes.MESSAGE(7015, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("Export of FMU type %s is not supported with Cpp target. FMU will be for Model Exchange (me)."));
public constant ErrorTypes.Message DEPRECATED_API_CALL = ErrorTypes.MESSAGE(7016, ErrorTypes.SCRIPTING(), ErrorTypes.WARNING(),
  Gettext.gettext("'%1' is deprecated. It is recommended to use '%2' instead."));
public constant ErrorTypes.Message REDUNDANT_ALIAS_SET = ErrorTypes.MESSAGE(7017, ErrorTypes.SYMBOLIC(), ErrorTypes.WARNING(),
  Gettext.gettext("The model contains alias variables with redundant start and/or conflicting nominal values. It is recommended to resolve the conflicts, because otherwise the system could be hard to solve. To print the conflicting alias sets and the chosen candidates please use -d=aliasConflicts."));
public constant ErrorTypes.Message CONFLICTING_ALIAS_SET = ErrorTypes.MESSAGE(7018, ErrorTypes.SYMBOLIC(), ErrorTypes.ERROR(),
  Gettext.gettext("The model contains alias variables with conflicting fixed start values. It is necessary to resolve the conflicts, because otherwise the initial system is impossible to solve. To print the conflicting alias sets and the chosen candidates please use -d=aliasConflicts."));
public constant ErrorTypes.Message PACKAGE_FILE_NOT_FOUND_ERROR = ErrorTypes.MESSAGE(7019, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Unable to find the package definition file. Looked for \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\" and \"%s\"."));
public constant ErrorTypes.Message UNABLE_TO_UNZIP_FILE = ErrorTypes.MESSAGE(7020, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Unable to unzip the file: %s."));
public constant ErrorTypes.Message EXPECTED_ENCRYPTED_PACKAGE = ErrorTypes.MESSAGE(7021, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Expected encrypted package with .mol extension got: %s."));
public constant ErrorTypes.Message SAVE_ENCRYPTED_CLASS_ERROR = ErrorTypes.MESSAGE(7022, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("Cannot save the encrypted class. Encrypted classes are read-only."));
public constant ErrorTypes.Message ACCESS_ENCRYPTED_PROTECTED_CONTENTS = ErrorTypes.MESSAGE(7023, ErrorTypes.SCRIPTING(), ErrorTypes.NOTIFICATION(),
  Gettext.gettext("Cannot access encrypted and protected class contents."));
public constant ErrorTypes.Message INVALID_NONLINEAR_JACOBIAN_COMPONENT = ErrorTypes.MESSAGE(7024, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Jacobian %s contains non-linear components. This indicates a singular system or internal generation errors."));
public constant ErrorTypes.Message DUPLICATE_VARIABLE_ERROR = ErrorTypes.MESSAGE(7025, ErrorTypes.TRANSLATION(), ErrorTypes.ERROR(),
  Gettext.gettext("Duplicate elements:\n %s."));
public constant ErrorTypes.Message ENCRYPTION_NOT_SUPPORTED = ErrorTypes.MESSAGE(7026, ErrorTypes.SCRIPTING(), ErrorTypes.ERROR(),
  Gettext.gettext("File not Found: %s. Compile OpenModelica with Encryption support."));

constant SourceInfo dummyInfo = SOURCEINFO("",false,0,0,0,0,0.0);

public function clearCurrentComponent
protected function dummy
  input output String str;
  input Integer i;
end dummy;
algorithm
  updateCurrentComponent(0, "", dummyInfo, dummy);
end clearCurrentComponent;

public function updateCurrentComponent<T> "Function: updateCurrentComponent
This function takes a String and set the global var to
which the current variable the compiler is working with."
  input T cpre; // Should be DAE.ComponentPrefix
  input String component;
  input SourceInfo info;
  input prefixToStr func;
  partial function prefixToStr<T>
    input String str;
    input T t;
    output String ostr;
  end prefixToStr;
protected
  Option<tuple<array<T>, array<String>, array<SourceInfo>, array<prefixToStr>>> tpl;
  array<T> apre;
  array<String> astr;
  array<SourceInfo> ainfo;
  array<prefixToStr> afunc;
algorithm
  tpl := getGlobalRoot(Global.currentInstVar);
  _ := match tpl
    case NONE() algorithm setGlobalRoot(Global.currentInstVar, SOME((arrayCreate(1,cpre),arrayCreate(1,component),arrayCreate(1,info),arrayCreate(1,func)))); then ();
    case SOME((apre,astr,ainfo,afunc))
      algorithm
        arrayUpdate(apre, 1, cpre);
        arrayUpdate(astr, 1, component);
        arrayUpdate(ainfo, 1, info);
        arrayUpdate(afunc, 1, func);
      then ();
  end match;
end updateCurrentComponent;

public function getCurrentComponent<T> "Gets the current component as a string."
  output String str;
  output Integer sline=0, scol=0, eline=0, ecol=0;
  output Boolean read_only=false;
  output String filename="";
protected
  Option<tuple<array<T>, array<String>, array<SourceInfo>, array<prefixToStr>>> tpl;
  array<T> apre;
  array<String> astr;
  array<SourceInfo> ainfo;
  array<prefixToStr> afunc;
  SourceInfo info;
  prefixToStr func;
  partial function prefixToStr<T>
    input String str;
    input T t;
    output String ostr;
  end prefixToStr;
algorithm
  tpl := getGlobalRoot(Global.currentInstVar);
  str := match tpl
    case NONE() then "";
    case SOME((apre,astr,ainfo,afunc))
      algorithm
        str := arrayGet(astr, 1);
        if str <> "" then
          func := arrayGet(afunc, 1);
          str := "Variable " + func(str,arrayGet(apre,1)) + ": ";
          info := arrayGet(ainfo, 1);
          sline := info.lineNumberStart;
          scol := info.columnNumberStart;
          eline := info.lineNumberEnd;
          ecol := info.columnNumberEnd;
          read_only := info.isReadOnly;
          filename := info.fileName;
        end if;
      then str;
  end match;
end getCurrentComponent;

public function addMessage "Implementation of Relations
  function: addMessage
  Adds a message given ID and tokens. The rest of the info
  is looked up in the message table."
  input ErrorTypes.Message inErrorMsg;
  input ErrorTypes.MessageTokens inMessageTokens;
protected
  ErrorTypes.MessageType msg_type;
  ErrorTypes.Severity severity;
  String str, msg_str, file;
  ErrorTypes.ErrorID error_id,sline,scol,eline,ecol;
  Boolean isReadOnly;
  Gettext.TranslatableContent msg;
algorithm
  if not Flags.getConfigBool(Flags.DEMO_MODE) then
    (str,sline,scol,eline,ecol,isReadOnly,file) := getCurrentComponent();
    //print(" adding message: " + intString(error_id) + "\n");
    ErrorTypes.MESSAGE(error_id, msg_type, severity, msg) := inErrorMsg;
    msg_str := Gettext.translateContent(msg);
    ErrorExt.addSourceMessage(error_id, msg_type, severity, sline, scol, eline, ecol, isReadOnly, Testsuite.friendly(file), str+msg_str, inMessageTokens);
    //print(" succ add " + msg_type_str + " " + severity_string + ",  " + msg + "\n");
  end if;
end addMessage;

public function addSourceMessage "
  Adds a message given ID, tokens and source file info.
  The rest of the info is looked up in the message table."
  input ErrorTypes.Message inErrorMsg;
  input ErrorTypes.MessageTokens inMessageTokens;
  input SourceInfo inInfo;
algorithm
  _ := match (inErrorMsg,inMessageTokens,inInfo)
    local
      ErrorTypes.MessageType msg_type;
      ErrorTypes.Severity severity;
      String msg_str,file;
      ErrorTypes.ErrorID error_id,sline,scol,eline,ecol;
      ErrorTypes.MessageTokens tokens;
      Boolean isReadOnly;
      Gettext.TranslatableContent msg;
    case (ErrorTypes.MESSAGE(error_id, msg_type, severity, msg), tokens,
        SOURCEINFO(fileName = file,isReadOnly = isReadOnly,
          lineNumberStart = sline, columnNumberStart = scol,
          lineNumberEnd = eline,columnNumberEnd = ecol))
      equation
        msg_str = Gettext.translateContent(msg);
        ErrorExt.addSourceMessage(error_id, msg_type, severity, sline, scol,
          eline, ecol, isReadOnly, Testsuite.friendly(file), msg_str, tokens);
      then ();
  end match;
end addSourceMessage;

function addSourceMessageAsError
  input ErrorTypes.Message msg;
  input ErrorTypes.MessageTokens tokens;
  input SourceInfo info;
protected
  ErrorTypes.Message m = msg;
algorithm
  m.severity := ErrorTypes.ERROR();
  addSourceMessage(m, tokens, info);
end addSourceMessageAsError;

function addStrictMessage
  input ErrorTypes.Message errorMsg;
  input ErrorTypes.MessageTokens tokens;
  input SourceInfo info;
protected
  ErrorTypes.Message msg = errorMsg;
algorithm
  if Flags.getConfigBool(Flags.STRICT) then
    msg.severity := ErrorTypes.ERROR();
    addSourceMessageAndFail(msg, tokens, info);
  else
    addSourceMessage(msg, tokens, info);
  end if;
end addStrictMessage;

public function addSourceMessageAndFail
  "Same as addSourceMessage, but fails after adding the error."
  input ErrorTypes.Message inErrorMsg;
  input ErrorTypes.MessageTokens inMessageTokens;
  input SourceInfo inInfo;
algorithm
  addSourceMessage(inErrorMsg, inMessageTokens, inInfo);
  fail();
end addSourceMessageAndFail;

public function addMultiSourceMessage
  "Adds an error message given the message, token and a list of file info. The
   the last file info in the list is used for the message itself, the rest of the
   file infos are used to print a trace of where the error came from."
  input ErrorTypes.Message inErrorMsg;
  input ErrorTypes.MessageTokens inMessageTokens;
  input list<SourceInfo> inInfo;
algorithm
  _ := match(inErrorMsg, inMessageTokens, inInfo)
    local
      SourceInfo info;
      list<SourceInfo> rest_info;

    // Only one info left, print out the message.
    case (_, _, {info})
      equation
        addSourceMessage(inErrorMsg, inMessageTokens, info);
      then
        ();

    // Multiple infos left, print a trace with the first info.
    case (_, _, info :: rest_info)
      equation
        if not listMember(info, rest_info) then
          addSourceMessage(ERROR_FROM_HERE, {}, info);
        end if;
        addMultiSourceMessage(inErrorMsg, inMessageTokens, rest_info);
      then
        ();

    // No infos given, print a sourceless error.
    case (_, _, {})
      equation
        addMessage(inErrorMsg, inMessageTokens);
      then
        ();

  end match;
end addMultiSourceMessage;

public function addMessageOrSourceMessage
"@author:adrpo
  Adds a message or a source message depending on the OPTIONAL source file info.
  If the source file info is not present a normal message is added.
  If the source file info is present a source message is added"
  input ErrorTypes.Message inErrorMsg;
  input ErrorTypes.MessageTokens inMessageTokens;
  input Option<SourceInfo> inInfoOpt;
algorithm
  _ := match (inErrorMsg, inMessageTokens, inInfoOpt)
    local
      SourceInfo info;

    // we DON'T have an info, add message
    case (_, _, NONE())
      equation
        addMessage(inErrorMsg, inMessageTokens);
      then ();

    // we have an info, add source message
    case (_, _, SOME(info))
      equation
        addSourceMessage(inErrorMsg, inMessageTokens, info);
      then ();
  end match;
end addMessageOrSourceMessage;

function addTotalMessage
  input ErrorTypes.TotalMessage message;
protected
  ErrorTypes.Message msg;
  SourceInfo info;
algorithm
  ErrorTypes.TOTALMESSAGE(msg = msg, info = info) := message;
  addSourceMessage(msg, {}, info);
end addTotalMessage;

function addTotalMessages
  input list<ErrorTypes.TotalMessage> messages;
algorithm
  for msg in messages loop
    addTotalMessage(msg);
  end for;
end addTotalMessages;

public function printMessagesStr "Relations for pretty printing.
  function: printMessagesStr
  Prints messages to a string."
  input Boolean warningsAsErrors = false;
  output String res;
algorithm
  res := ErrorExt.printMessagesStr(warningsAsErrors);
end printMessagesStr;

public function printErrorsNoWarning "
  Prints errors only to a string.
"
  output String res;
algorithm
  res := ErrorExt.printErrorsNoWarning();
end printErrorsNoWarning;

public function printMessagesStrLst "Returns all messages as a list of strings, one for each message."
  output list<String> outStringLst;
algorithm
  outStringLst := match ()
    case () then {"Not impl. yet"};
  end match;
end printMessagesStrLst;

public function printMessagesStrLstType " Returns all messages as a list of strings, one for each message.
   Filters out messages of certain type."
  input ErrorTypes.MessageType inMessageType;
  output list<String> outStringLst;
algorithm
  outStringLst := match (inMessageType)
    case (_) then {"Not impl. yet"};
  end match;
end printMessagesStrLstType;

public function printMessagesStrLstSeverity "Returns all messages as a list of strings, one for each message.
  Filters out messages of certain severity"
  input ErrorTypes.Severity inSeverity;
  output list<String> outStringLst;
algorithm
  outStringLst := match (inSeverity)
    case (_) then {"Not impl. yet"};
  end match;
end printMessagesStrLstSeverity;

public function clearMessages "clears the message buffer"
algorithm
  ErrorExt.clearMessages();
end clearMessages;

public function getNumMessages "Returns the number of messages in the message queue"
  output Integer num;
algorithm
  num := ErrorExt.getNumMessages();
end getNumMessages;

public function getNumErrorMessages "Returns the number of messages with severity 'Error' in the message queue "
  output Integer num;
algorithm
  num := ErrorExt.getNumErrorMessages();
end getNumErrorMessages;

public function getMessages "
  Relations for interactive comm. These returns the messages as an array
  of strings, suitable for sending to clients like model editor, MDT, etc.

  Return all messages in a matrix format, vector of strings for each
  message, written out as a string."
  output list<ErrorTypes.TotalMessage> res;
algorithm
  res := ErrorExt.getMessages();
end getMessages;

public function getMessagesStrType "
  Return all messages in a matrix format, vector of strings for each
  message, written out as a string.
  Filtered by a specific MessageType."
  input ErrorTypes.MessageType inMessageType;
  output String outString;
algorithm
  outString := "not impl yet.";
end getMessagesStrType;

public function getMessagesStrSeverity "
  Return all messages in a matrix format, vector of strings for each
  message, written out as a string.
  Filtered by a specific MessageType."
  input ErrorTypes.Severity inSeverity;
  output String outString;
algorithm
  outString := "not impl yet.";
end getMessagesStrSeverity;

public function messageTypeStr "
  Converts a MessageType to a string."
  input ErrorTypes.MessageType inMessageType;
  output String outString;
algorithm
  outString := match(inMessageType)
    case (ErrorTypes.SYNTAX()) then "SYNTAX";
    case (ErrorTypes.GRAMMAR()) then "GRAMMAR";
    case (ErrorTypes.TRANSLATION()) then "TRANSLATION";
    case (ErrorTypes.SYMBOLIC()) then "SYMBOLIC";
    case (ErrorTypes.SIMULATION()) then "SIMULATION";
    case (ErrorTypes.SCRIPTING()) then "SCRIPTING";
  end match;
end messageTypeStr;

public function severityStr "
  Converts a Severity to a string."
  input ErrorTypes.Severity inSeverity;
  output String outString;
algorithm
  outString := match(inSeverity)
    case (ErrorTypes.INTERNAL()) then "Internal error";
    case (ErrorTypes.ERROR()) then "Error";
    case (ErrorTypes.WARNING()) then "Warning";
    case (ErrorTypes.NOTIFICATION()) then "Notification";
  end match;
end severityStr;

public function infoStr "
  Converts an SourceInfo into a string ready to be used in error messages.
  Format is [filename:line start:column start-line end:column end]"
  input SourceInfo info;
  output String str;
algorithm
  str := match(info)
    local
      String filename, info_str;
      Integer line_start, line_end, col_start, col_end;
    case (SOURCEINFO(fileName = filename, lineNumberStart = line_start,
        columnNumberStart = col_start, lineNumberEnd = line_end, columnNumberEnd = col_end))
        equation
          info_str = "[" + Testsuite.friendly(filename) + ":" +
                     intString(line_start) + ":" + intString(col_start) + "-" +
                     intString(line_end) + ":" + intString(col_end) + "]";
      then info_str;
  end match;
end infoStr;

public function assertion "
  Used to make compiler-internal assertions. These messages are not meant
  to be shown to a user, but rather to show internal error messages."
  input Boolean b;
  input String message;
  input SourceInfo info;
algorithm
  _ := match (b,message,info)
    case (true, _, _) then ();
    else equation
      addSourceMessage(INTERNAL_ERROR, {message}, info);
    then fail();
  end match;
end assertion;

public function assertionOrAddSourceMessage "
  Used to make assertions. These messages are meant to be shown to a user when
  the condition is true. If the Error-level of the message is Error, this function
  fails."
  input Boolean inCond;
  input ErrorTypes.Message inErrorMsg;
  input ErrorTypes.MessageTokens inMessageTokens;
  input SourceInfo inInfo;
algorithm
  _ := match (inCond, inErrorMsg, inMessageTokens, inInfo)
    case (true, _, _, _) then ();
    else equation
      addSourceMessage(inErrorMsg, inMessageTokens, inInfo);
      failOnErrorMsg(inErrorMsg);
    then ();
  end match;
end assertionOrAddSourceMessage;

protected function failOnErrorMsg
  input ErrorTypes.Message inMessage;
algorithm
  _ := match(inMessage)
    case ErrorTypes.MESSAGE(severity=ErrorTypes.ERROR()) then fail();
    else ();
  end match;
end failOnErrorMsg;

public function addCompilerError "
  Used to make a compiler warning"
  input String message;
algorithm
  addMessage(COMPILER_ERROR, {message});
end addCompilerError;

public function addCompilerWarning "
  Used to make a compiler warning"
  input String message;
algorithm
  addMessage(COMPILER_WARNING, {message});
end addCompilerWarning;

public function addCompilerNotification "
  Used to make a compiler notification"
  input String message;
algorithm
  addMessage(COMPILER_NOTIFICATION, {message});
end addCompilerNotification;

public function addInternalError "
  Used to make an internal error"
  input String message;
  input SourceInfo info;
protected
  String filename;
algorithm
  if Testsuite.isRunning() then
    SOURCEINFO(fileName=filename):=info;
    addSourceMessage(INTERNAL_ERROR, {message}, SOURCEINFO(filename,false,0,0,0,0,0));
  else
    addSourceMessage(INTERNAL_ERROR, {message}, info);
  end if;
end addInternalError;

public function terminateError
  "Prints out a message and terminates the execution."
  input String message;
  input SourceInfo info;
algorithm
  ErrorExt.addSourceMessage(0, ErrorTypes.TRANSLATION(), ErrorTypes.INTERNAL(),
    info.lineNumberStart, info.columnNumberStart,
    info.lineNumberEnd, info.columnNumberEnd, info.isReadOnly,
    info.fileName, "%s", {message});
  print(ErrorExt.printMessagesStr());
  System.exit(-1);
end terminateError;

annotation(__OpenModelica_Interface="util");
end Error;

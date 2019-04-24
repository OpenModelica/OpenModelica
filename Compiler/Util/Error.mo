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

public import Util;
public import Flags;

protected

import Config;
import Global;

public
uniontype Severity "severity of message"
  record INTERNAL "Error because of a failure in the tool" end INTERNAL;

  record ERROR "Error when tool can not succeed in translation because of a user error" end ERROR;

  record WARNING "Warning when tool succeeds but with warning" end WARNING;

  record NOTIFICATION "Additional information to user, e.g. what
             actions tool has taken to succeed in translation" end NOTIFICATION;
end Severity;

public
uniontype MessageType "runtime scripting /interpretation error"
  record SYNTAX "syntax errors" end SYNTAX;

  record GRAMMAR "grammar errors" end GRAMMAR;

  record TRANSLATION "instantiation errors: up to
           flat modelica" end TRANSLATION;

  record SYMBOLIC "Symbolic manipulation error,
           simcodegen, up to .exe file" end SYMBOLIC;

  record SIMULATION "Runtime simulation error" end SIMULATION;

  record SCRIPTING "runtime scripting /interpretation error" end SCRIPTING;

end MessageType;

public
type ErrorID = Integer "Unique error id. Used to
        look up message string and type and severity";

public
uniontype Message
  record MESSAGE
    ErrorID id;
    MessageType ty;
    Severity severity;
    Util.TranslatableContent message;
  end MESSAGE;
end Message;

public
uniontype TotalMessage
  record TOTALMESSAGE
    Message msg;
    SourceInfo info;
  end TOTALMESSAGE;
end TotalMessage;

public
type MessageTokens = list<String>   "\"Tokens\" to insert into message at
            positions identified by
            - %s for string
            - %n for string number n" ;

public constant Message LOOKUP_ERROR = MESSAGE(3, TRANSLATION(), ERROR(),
  Util.gettext("Class %s not found in scope %s."));
public constant Message LOOKUP_ERROR_COMPNAME = MESSAGE(4, TRANSLATION(), ERROR(),
  Util.gettext("Class %s not found in scope %s while instantiating %s."));
public constant Message LOOKUP_VARIABLE_ERROR = MESSAGE(5, TRANSLATION(), ERROR(),
  Util.gettext("Variable %s not found in scope %s."));
public constant Message ASSIGN_CONSTANT_ERROR = MESSAGE(6, TRANSLATION(), ERROR(),
  Util.gettext("Trying to assign to constant component in %s := %s"));
public constant Message ASSIGN_PARAM_ERROR = MESSAGE(7, TRANSLATION(), ERROR(),
  Util.gettext("Trying to assign to parameter component in %s := %s"));
public constant Message ASSIGN_READONLY_ERROR = MESSAGE(8, TRANSLATION(), ERROR(),
  Util.gettext("Trying to assign to %s component %s."));
public constant Message ASSIGN_TYPE_MISMATCH_ERROR = MESSAGE(9, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch in assignment in %s := %s of %s := %s"));
public constant Message IF_CONDITION_TYPE_ERROR = MESSAGE(10, TRANSLATION(), ERROR(),
  Util.gettext("Type error in conditional '%s'. Expected Boolean, got %s."));
public constant Message FOR_EXPRESSION_TYPE_ERROR = MESSAGE(11, TRANSLATION(), ERROR(),
  Util.gettext("Type error in iteration range '%s'. Expected array got %s."));
public constant Message WHEN_CONDITION_TYPE_ERROR = MESSAGE(12, TRANSLATION(), ERROR(),
  Util.gettext("Type error in when conditional '%s'. Expected Boolean scalar or vector, got %s."));
public constant Message WHILE_CONDITION_TYPE_ERROR = MESSAGE(13, TRANSLATION(), ERROR(),
  Util.gettext("Type error in while conditional '%s'. Expected Boolean got %s."));
public constant Message END_ILLEGAL_USE_ERROR = MESSAGE(14, TRANSLATION(), ERROR(),
  Util.gettext("'end' can not be used outside array subscripts."));
public constant Message DIVISION_BY_ZERO = MESSAGE(15, TRANSLATION(), ERROR(),
  Util.gettext("Division by zero in %s / %s"));
public constant Message MODULO_BY_ZERO = MESSAGE(16, TRANSLATION(), ERROR(),
  Util.gettext("Modulo by zero in mod(%s,%s)."));
public constant Message REM_ARG_ZERO = MESSAGE(17, TRANSLATION(), ERROR(),
  Util.gettext("Second argument in rem is zero in rem(%s,%s)."));
public constant Message SCRIPT_READ_SIM_RES_ERROR = MESSAGE(18, SCRIPTING(), ERROR(),
  Util.gettext("Error reading simulation result."));
public constant Message EXTENDS_LOOP = MESSAGE(19, TRANSLATION(), ERROR(),
  Util.gettext("extends %s causes an instantiation loop."));
public constant Message LOAD_MODEL_ERROR = MESSAGE(20, TRANSLATION(), ERROR(),
  Util.gettext("Class %s not found."));
public constant Message WRITING_FILE_ERROR = MESSAGE(21, SCRIPTING(), ERROR(),
  Util.gettext("Error writing to file %s."));
public constant Message SIMULATOR_BUILD_ERROR = MESSAGE(22, TRANSLATION(), ERROR(),
  Util.gettext("Error building simulator. Build log: %s"));
public constant Message DIMENSION_NOT_KNOWN = MESSAGE(23, TRANSLATION(), ERROR(),
  Util.gettext("Dimensions must be parameter or constant expression (in %s)."));
public constant Message UNBOUND_VALUE = MESSAGE(24, TRANSLATION(), ERROR(),
  Util.gettext("Variable %s has no value."));
public constant Message NEGATIVE_SQRT = MESSAGE(25, TRANSLATION(), ERROR(),
  Util.gettext("Negative value as argument to sqrt."));
public constant Message NO_CONSTANT_BINDING = MESSAGE(26, TRANSLATION(), ERROR(),
  Util.gettext("No constant value for variable %s in scope %s."));
public constant Message TYPE_NOT_FROM_PREDEFINED = MESSAGE(27, TRANSLATION(), ERROR(),
  Util.gettext("In class %s, class specialization 'type' can only be derived from predefined types."));
public constant Message INCOMPATIBLE_CONNECTOR_VARIABILITY = MESSAGE(28, TRANSLATION(), ERROR(),
  Util.gettext("Cannot connect %s %s to non-constant/parameter %s."));
public constant Message INVALID_CONNECTOR_PREFIXES = MESSAGE(29, TRANSLATION(), ERROR(),
  Util.gettext("Connector element %s may not be both %s and %s."));
public constant Message INVALID_COMPLEX_CONNECTOR_VARIABILITY = MESSAGE(30, TRANSLATION(), ERROR(),
  Util.gettext("%s is a composite connector element, and may not be declared as %s."));
public constant Message DIFFERENT_NO_EQUATION_IF_BRANCHES = MESSAGE(31, TRANSLATION(), ERROR(),
  Util.gettext("Different number of equations in the branches of the if equation: %s"));
public constant Message UNDERDET_EQN_SYSTEM = MESSAGE(32, SYMBOLIC(), ERROR(),
  Util.gettext("Too few equations, under-determined system. The model has %s equation(s) and %s variable(s)."));
public constant Message OVERDET_EQN_SYSTEM = MESSAGE(33, SYMBOLIC(), ERROR(),
  Util.gettext("Too many equations, over-determined system. The model has %s equation(s) and %s variable(s)."));
public constant Message STRUCT_SINGULAR_SYSTEM = MESSAGE(34, SYMBOLIC(), ERROR(),
  Util.gettext("Model is structurally singular, error found sorting equations \n %s for variables \n %s"));
public constant Message UNSUPPORTED_LANGUAGE_FEATURE = MESSAGE(35, TRANSLATION(), ERROR(),
  Util.gettext("The language feature %s is not supported. Suggested workaround: %s"));
public constant Message NON_EXISTING_DERIVATIVE = MESSAGE(36, SYMBOLIC(), ERROR(),
  Util.gettext("Derivative of expression \"%s\" w.r.t. \"%s\" is non-existent."));
public constant Message NO_CLASSES_LOADED = MESSAGE(37, TRANSLATION(), ERROR(),
  Util.gettext("No classes are loaded."));
public constant Message INST_PARTIAL_CLASS = MESSAGE(38, TRANSLATION(), ERROR(),
  Util.gettext("Illegal to instantiate partial class %s."));
public constant Message LOOKUP_BASECLASS_ERROR = MESSAGE(39, TRANSLATION(), ERROR(),
  Util.gettext("Base class %s not found in scope %s."));
public constant Message INVALID_REDECLARE_AS = MESSAGE(40, TRANSLATION(), ERROR(),
  Util.gettext("Invalid redeclaration of %s %s as %s."));
public constant Message REDECLARE_NON_REPLACEABLE = MESSAGE(41, TRANSLATION(), ERROR(),
  Util.gettext("Trying to redeclare %1 %2 but %1 not declared as replaceable."));
public constant Message COMPONENT_INPUT_OUTPUT_MISMATCH = MESSAGE(42, TRANSLATION(), ERROR(),
  Util.gettext("Component declared as %s when having the variable %s declared as %s."));
public constant Message ARRAY_DIMENSION_MISMATCH = MESSAGE(43, TRANSLATION(), ERROR(),
  Util.gettext("Array dimension mismatch, expression %s has type %s, expected array dimensions [%s]."));
public constant Message ARRAY_DIMENSION_INTEGER = MESSAGE(44, TRANSLATION(), ERROR(),
  Util.gettext("Array dimension must be integer expression in %s which has type %s."));
public constant Message EQUATION_TYPE_MISMATCH_ERROR = MESSAGE(45, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch in equation %s of type %s."));
public constant Message INST_ARRAY_EQ_UNKNOWN_SIZE = MESSAGE(46, TRANSLATION(), ERROR(),
  Util.gettext("Array equation has unknown size in %s."));
public constant Message TUPLE_ASSIGN_FUNCALL_ONLY = MESSAGE(47, TRANSLATION(), ERROR(),
  Util.gettext("Tuple assignment only allowed when rhs is function call (in %s)."));
public constant Message INVALID_CONNECTOR_TYPE = MESSAGE(48, TRANSLATION(), ERROR(),
  Util.gettext("%s is not a valid connector."));
public constant Message EXPANDABLE_NON_EXPANDABLE_CONNECTION = MESSAGE(49, TRANSLATION(), ERROR(),
  Util.gettext("Cannot connect expandable connector %s with non-expandable connector %s."));
public constant Message UNDECLARED_CONNECTION = MESSAGE(50, TRANSLATION(), ERROR(),
  Util.gettext("Cannot connect undeclared connectors %s with %s. At least one of them must be declared."));
public constant Message CONNECT_PREFIX_MISMATCH = MESSAGE(51, TRANSLATION(), ERROR(),
  Util.gettext("Cannot connect %1 component %2 to non-%1 component %3."));
public constant Message INVALID_CONNECTOR_VARIABLE = MESSAGE(52, TRANSLATION(), ERROR(),
  Util.gettext("The type of variables %s and %s\nare inconsistent in connect equations."));
public constant Message TYPE_ERROR = MESSAGE(53, TRANSLATION(), ERROR(),
  Util.gettext("Wrong type on %s, expected %s."));
public constant Message MODIFY_PROTECTED = MESSAGE(54, TRANSLATION(), WARNING(),
  Util.gettext("Modification or redeclaration of protected elements is not allowed.\n\tElement: %s, modification: %s."));
public constant Message INVALID_TUPLE_CONTENT = MESSAGE(55, TRANSLATION(), ERROR(),
  Util.gettext("Tuple %s must contain component references only."));
public constant Message MISSING_REDECLARE_IN_CLASS_MOD = MESSAGE(56, TRANSLATION(), ERROR(),
  Util.gettext("Missing redeclare keyword on attempted redeclaration of class %s."));
public constant Message IMPORT_SEVERAL_NAMES = MESSAGE(57, TRANSLATION(), ERROR(),
  Util.gettext("%s found in several unqualified import statements."));
public constant Message LOOKUP_TYPE_FOUND_COMP = MESSAGE(58, TRANSLATION(), ERROR(),
  Util.gettext("Found a component with same name when looking for type %s."));
public constant Message INHERITED_EXTENDS = MESSAGE(59, TRANSLATION(), ERROR(),
  Util.gettext("The base class name %s was found in one or more base classes:"));
public constant Message EXTEND_THROUGH_COMPONENT = MESSAGE(60, TRANSLATION(), ERROR(),
  Util.gettext("Part %s of base class name %s is not a class."));
public constant Message PROTECTED_ACCESS = MESSAGE(61, TRANSLATION(), ERROR(),
  Util.gettext("Illegal access of protected element %s."));
public constant Message ILLEGAL_MODIFICATION = MESSAGE(62, TRANSLATION(), ERROR(),
  Util.gettext("Illegal modification %s (of %s)."));
public constant Message INTERNAL_ERROR = MESSAGE(63, TRANSLATION(), ERROR(),
  Util.gettext("Internal error %s"));
public constant Message TYPE_MISMATCH_ARRAY_EXP = MESSAGE(64, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch in array expression in component %s. %s is of type %s while the elements %s are of type %s."));
public constant Message TYPE_MISMATCH_MATRIX_EXP = MESSAGE(65, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch in matrix rows in component %s. %s is a row of %s, the rest of the matrix is of type %s."));
public constant Message MATRIX_EXP_ROW_SIZE = MESSAGE(66, TRANSLATION(), ERROR(),
  Util.gettext("Incompatible row length in matrix expression in component %s. %s is a row of size %s, the rest of the matrix rows are of size %s."));
public constant Message OPERAND_BUILTIN_TYPE = MESSAGE(67, TRANSLATION(), ERROR(),
  Util.gettext("Operand of %s in component %s must be builtin-type in %s."));
public constant Message WRONG_TYPE_OR_NO_OF_ARGS = MESSAGE(68, TRANSLATION(), ERROR(),
  Util.gettext("Wrong type or wrong number of arguments to %s (in component %s)."));
public constant Message DIFFERENT_DIM_SIZE_IN_ARGUMENTS = MESSAGE(69, TRANSLATION(), ERROR(),
  Util.gettext("Different dimension sizes in arguments to %s in component %s."));
public constant Message LOOKUP_IMPORT_ERROR = MESSAGE(70, TRANSLATION(), ERROR(),
  Util.gettext("Import %s not found in scope %s."));
public constant Message LOOKUP_SHADOWING = MESSAGE(71, TRANSLATION(), WARNING(),
  Util.gettext("Import %s is shadowed by a local element."));
public constant Message ARGUMENT_MUST_BE_INTEGER = MESSAGE(72, TRANSLATION(), ERROR(),
  Util.gettext("%s argument to %s in component %s must be Integer expression."));
public constant Message ARGUMENT_MUST_BE_DISCRETE_VAR = MESSAGE(73, TRANSLATION(), ERROR(),
  Util.gettext("%s argument to %s in component %s must be discrete variable."));
public constant Message TYPE_MUST_BE_SIMPLE = MESSAGE(74, TRANSLATION(), ERROR(),
  Util.gettext("Type in %s must be simple type in component %s."));
public constant Message ARGUMENT_MUST_BE_VARIABLE = MESSAGE(75, TRANSLATION(), ERROR(),
  Util.gettext("%s argument to %s in component %s must be a variable."));
public constant Message NO_MATCHING_FUNCTION_FOUND = MESSAGE(76, TRANSLATION(), ERROR(),
  Util.gettext("No matching function found for %s in component %s\ncandidates are %s"));
public constant Message NO_MATCHING_FUNCTION_FOUND_NO_CANDIDATE = MESSAGE(77, TRANSLATION(), ERROR(),
  Util.gettext("No matching function found for %s."));
public constant Message FUNCTION_COMPS_MUST_HAVE_DIRECTION = MESSAGE(78, TRANSLATION(), ERROR(),
  Util.gettext("Component %s in function is neither input nor output."));
public constant Message FUNCTION_SLOT_ALREADY_FILLED = MESSAGE(79, TRANSLATION(), ERROR(),
  Util.gettext("Slot %s already filled in a function call in component %s."));
public constant Message NO_SUCH_PARAMETER = MESSAGE(80, TRANSLATION(), ERROR(),
  Util.gettext("Function %s has no parameter named %s."));
public constant Message CONSTANT_OR_PARAM_WITH_NONCONST_BINDING = MESSAGE(81, TRANSLATION(), ERROR(),
  Util.gettext("%s is a constant or parameter with a non-constant initializer %s."));
public constant Message WRONG_DIMENSION_TYPE = MESSAGE(82, TRANSLATION(), ERROR(),
  Util.gettext("Subscript %s of type %s is not a subtype of Integer, Boolean or enumeration."));
public constant Message TYPE_MISMATCH_IF_EXP = MESSAGE(83, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch in if-expression in component %s. True branch: %s has type %s, false branch: %s has type %s."));
public constant Message UNRESOLVABLE_TYPE = MESSAGE(84, TRANSLATION(), ERROR(),
  Util.gettext("Cannot resolve type of expression %s. The operands have types %s in component %s."));
public constant Message INCOMPATIBLE_TYPES = MESSAGE(85, TRANSLATION(), ERROR(),
  Util.gettext("Incompatible argument types to operation %s in component %s, left type: %s, right type: %s"));
public constant Message NON_ENCAPSULATED_CLASS_ACCESS = MESSAGE(86, TRANSLATION(), ERROR(),
  Util.gettext("Class %s does not satisfy the requirements for a package. Lookup is therefore restricted to encapsulated elements, but %s is not encapsulated."));
public constant Message INHERIT_BASIC_WITH_COMPS = MESSAGE(87, TRANSLATION(), ERROR(),
  Util.gettext("Class %s inherits builtin type but has components."));
public constant Message MODIFIER_TYPE_MISMATCH_ERROR = MESSAGE(88, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch in modifier of component %s, expected type %s, got modifier %s of type %s."));
public constant Message ERROR_FLATTENING = MESSAGE(89, TRANSLATION(), ERROR(),
  Util.gettext("Error occurred while flattening model %s"));
public constant Message DUPLICATE_ELEMENTS_NOT_IDENTICAL = MESSAGE(90, TRANSLATION(), ERROR(),
  Util.gettext("Duplicate elements (due to inherited elements) not identical:\n  first element is:  %s\n  second element is: %s"));
public constant Message PACKAGE_VARIABLE_NOT_CONSTANT = MESSAGE(91, TRANSLATION(), ERROR(),
  Util.gettext("Variable %s in package %s is not constant."));
public constant Message RECURSIVE_DEFINITION = MESSAGE(92, TRANSLATION(), ERROR(),
  Util.gettext("Declaration of element %s causes recursive definition of class %s."));
public constant Message NOT_ARRAY_TYPE_IN_FOR_STATEMENT = MESSAGE(93, TRANSLATION(), ERROR(),
  Util.gettext("Expression %s in for-statement must be an array type."));
public constant Message NON_CLASS_IN_COMP_FUNC_NAME = MESSAGE(94, TRANSLATION(), ERROR(),
  Util.gettext("Found non-class %s while looking for function via component. The only valid form is c.C1..CN.f where c is a scalar component and C1..CN are classes."));
public constant Message DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN = MESSAGE(95, SYMBOLIC(), ERROR(),
  Util.gettext("The same variables must be solved in elsewhen clause as in the when clause."));
public constant Message CLASS_IN_COMPOSITE_COMP_NAME = MESSAGE(96, TRANSLATION(), ERROR(),
  Util.gettext("Found class %s during lookup of composite component name '%s', expected component."));
public constant Message MODIFIER_DECLARATION_TYPE_MISMATCH_ERROR = MESSAGE(97, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch in modifier of component %s, declared type %s, got modifier %s of type %s."));
public constant Message ASSERT_CONSTANT_FALSE_ERROR = MESSAGE(98, SYMBOLIC(), ERROR(),
  Util.gettext("Assertion triggered during translation: %s."));
public constant Message ARRAY_INDEX_OUT_OF_BOUNDS = MESSAGE(99, TRANSLATION(), ERROR(),
  Util.gettext("Subscript '%s' for dimension %s (size = %s) of %s is out of bounds."));
public constant Message COMPONENT_CONDITION_VARIABILITY = MESSAGE(100, TRANSLATION(), ERROR(),
  Util.gettext("Component condition must be parameter or constant expression (in %s)."));
public constant Message FOUND_CLASS_NAME_VIA_COMPONENT = MESSAGE(101, TRANSLATION(), ERROR(),
  Util.gettext("Class name '%s' was found via a component (only component and function call names may be accessed in this way)."));
public constant Message FOUND_FUNC_NAME_VIA_COMP_NONCALL = MESSAGE(102, TRANSLATION(), ERROR(),
  Util.gettext("Found function %s by name lookup via component, but this is only valid when the name is used as a function call."));
public constant Message DUPLICATE_MODIFICATIONS = MESSAGE(103, TRANSLATION(), ERROR(),
  Util.gettext("Duplicate modification of element %s on %s."));
public constant Message ILLEGAL_SUBSCRIPT = MESSAGE(104, TRANSLATION(), ERROR(),
  Util.gettext("Illegal subscript %s for dimensions %s in component %s."));
public constant Message ILLEGAL_EQUATION_TYPE = MESSAGE(105, TRANSLATION(), ERROR(),
  Util.gettext("Illegal type in equation %s, only builtin types (Real, String, Integer, Boolean or enumeration) or record type allowed in equation."));
public constant Message EVAL_LOOP_LIMIT_REACHED = MESSAGE(106, TRANSLATION(), ERROR(),
  Util.gettext("The loop iteration limit (--evalLoopLimit=%s) was exceeded during evaluation."));
public constant Message LOOKUP_IN_PARTIAL_CLASS = MESSAGE(107, TRANSLATION(), ERROR(),
  Util.gettext("%s is partial, name lookup is not allowed in partial classes."));
public constant Message MISSING_INNER_PREFIX = MESSAGE(108, TRANSLATION(), WARNING(),
  Util.gettext("No corresponding 'inner' declaration found for component %s declared as '%s'.\n  The existing 'inner' components are:\n    %s\n  Check if you have not misspelled the 'outer' component name.\n  Please declare an 'inner' component with the same name in the top scope.\n  Continuing flattening by only considering the 'outer' component declaration."));
public constant Message NON_PARAMETER_ITERATOR_RANGE = MESSAGE(109, TRANSLATION(), ERROR(),
  Util.gettext("The iteration range %s is not a constant or parameter expression."));
public constant Message IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY = MESSAGE(110, TRANSLATION(), ERROR(),
  Util.gettext("Identifier %s of implicit for iterator must be present as array subscript in the loop body."));
public constant Message CONNECTOR_NON_PARAMETER_SUBSCRIPT = MESSAGE(111, TRANSLATION(), ERROR(),
  Util.gettext("Connector ‘%s‘ has non-parameter subscript ‘%s‘."));
public constant Message LOOKUP_CLASS_VIA_COMP_COMP = MESSAGE(112, TRANSLATION(), ERROR(),
  Util.gettext("Illegal access of class '%s' via a component when looking for '%s'."));
public constant Message SUBSCRIPTED_FUNCTION_CALL = MESSAGE(113, TRANSLATION(), ERROR(),
  Util.gettext("Function call %s contains subscripts."));
public constant Message IF_EQUATION_UNBALANCED = MESSAGE(114, TRANSLATION(), ERROR(),
  Util.gettext("In equation %s. If-equation with conditions that are not parameter expressions must have the same number of equations in each branch, equation count is %s for each respective branch."));
public constant Message IF_EQUATION_MISSING_ELSE = MESSAGE(115, TRANSLATION(), ERROR(),
  Util.gettext("Missing else-clause in if-equation with non-parameter conditions."));
public constant Message CONNECT_IN_IF = MESSAGE(116, TRANSLATION(), ERROR(),
  Util.gettext("connect may not be used inside if-equations with non-parametric conditions (found connect(%s, %s))."));
public constant Message CONNECT_IN_WHEN = MESSAGE(117, TRANSLATION(), ERROR(),
  Util.gettext("connect may not be used inside when-equations (found connect(%s, %s))."));
public constant Message CONNECT_INCOMPATIBLE_TYPES = MESSAGE(118, TRANSLATION(), ERROR(),
  Util.gettext("Incompatible components in connect statement: connect(%s, %s)\n- %s has components %s\n- %s has components %s"));
public constant Message CONNECT_OUTER_OUTER = MESSAGE(119, TRANSLATION(), ERROR(),
  Util.gettext("Illegal connecting two outer connectors in statement connect(%s, %s)."));
public constant Message CONNECTOR_ARRAY_NONCONSTANT = MESSAGE(120, TRANSLATION(), ERROR(),
  Util.gettext("in statement %s, subscript %s is not a parameter or constant."));
public constant Message CONNECTOR_ARRAY_DIFFERENT = MESSAGE(121, TRANSLATION(), ERROR(),
  Util.gettext("Unmatched dimension in equation connect(%s, %s), %s != %s."));
public constant Message MODIFIER_NON_ARRAY_TYPE_WARNING = MESSAGE(122, TRANSLATION(), WARNING(),
  Util.gettext("Non-array modification '%s' for array component, possibly due to missing 'each'."));
public constant Message BUILTIN_VECTOR_INVALID_DIMENSIONS = MESSAGE(123, TRANSLATION(), ERROR(),
  Util.gettext("In scope %s, in component %s: Invalid dimensions %s in %s, no more than one dimension may have size > 1."));
public constant Message UNROLL_LOOP_CONTAINING_WHEN = MESSAGE(124, TRANSLATION(), ERROR(),
  Util.gettext("Unable to unroll for loop containing when statements or equations: %s."));
public constant Message CIRCULAR_PARAM = MESSAGE(125, TRANSLATION(), ERROR(),
  Util.gettext("Variable '%s' has a cyclic dependency and has variability %s."));
public constant Message NESTED_WHEN = MESSAGE(126, TRANSLATION(), ERROR(),
  Util.gettext("Nested when statements are not allowed."));
public constant Message INVALID_ENUM_LITERAL = MESSAGE(127, TRANSLATION(), ERROR(),
  Util.gettext("Invalid use of reserved attribute name %s as enumeration literal."));
public constant Message UNEXPECTED_FUNCTION_INPUTS_WARNING = MESSAGE(128, TRANSLATION(), WARNING(),
  Util.gettext("Function %s has not the expected inputs. Expected inputs are %s."));
public constant Message DUPLICATE_CLASSES_NOT_EQUIVALENT = MESSAGE(129, TRANSLATION(), ERROR(),
  Util.gettext("Duplicate class definitions (due to inheritance) not equivalent, first definition is: %s, second definition is: %s."));
public constant Message HIGHER_VARIABILITY_BINDING = MESSAGE(130, TRANSLATION(), ERROR(),
  Util.gettext("Component %s of variability %s has binding %s of higher variability %s."));
public constant Message IF_EQUATION_WARNING = MESSAGE(131, SYMBOLIC(), WARNING(),
  Util.gettext("If-equations are only partially supported. Ignoring %s."));
public constant Message IF_EQUATION_UNBALANCED_2 = MESSAGE(132, SYMBOLIC(), ERROR(),
  Util.gettext("If-equation with conditions that are not parameter expressions must have the same number of equations in each branch, equation count is %s for each respective branch:\n%s"));
public constant Message EQUATION_GENERIC_FAILURE = MESSAGE(133, TRANSLATION(), ERROR(),
  Util.gettext("Failed to instantiate equation %s."));
public constant Message INST_PARTIAL_CLASS_CHECK_MODEL_WARNING = MESSAGE(134, TRANSLATION(), WARNING(),
  Util.gettext("Forcing full instantiation of partial class %s during checkModel."));
public constant Message VARIABLE_BINDING_TYPE_MISMATCH = MESSAGE(135, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch in binding %s = %s, expected subtype of %s, got type %s."));
public constant Message COMPONENT_NAME_SAME_AS_TYPE_NAME = MESSAGE(136, TRANSLATION(), WARNING(),
  Util.gettext("Component %s has the same name as its type %s.\n\tThis is forbidden by Modelica specification and may lead to lookup errors."));
public constant Message CONDITIONAL_EXP_WITHOUT_VALUE = MESSAGE(137, TRANSLATION(), ERROR(),
  Util.gettext("The conditional expression %s could not be evaluated."));
public constant Message INCOMPATIBLE_IMPLICIT_RANGES = MESSAGE(138, TRANSLATION(), ERROR(),
  Util.gettext("Dimension %s of %s and %s of %s differs when trying to deduce implicit iteration range."));
public constant Message INITIAL_WHEN = MESSAGE(139, TRANSLATION(), ERROR(),
  Util.gettext("when-clause is not allowed in initial section."));
public constant Message MODIFICATION_INDEX_NOT_FOUND = MESSAGE(140, TRANSLATION(), ERROR(),
  Util.gettext("Instantiation of array component: %s failed because index modification: %s is invalid.\n\tArray component: %s has more dimensions than binding %s."));
public constant Message DUPLICATE_MODIFICATIONS_WARNING = MESSAGE(141, TRANSLATION(), WARNING(),
  Util.gettext("Duplicate modifications for attribute: %s in modifier: %s.\n\tConsidering only the first modification: %s and ignoring the rest %s."));
public constant Message GENERATECODE_INVARS_HAS_FUNCTION_PTR = MESSAGE(142, SYMBOLIC(), ERROR(),
  Util.gettext("%s has a function pointer as input. OpenModelica does not support this feature in the interactive environment. Suggested workaround: Call this function with the arguments you want from another function (that does not have function pointer input). Then call that function from the interactive environment instead."));
public constant Message LOOKUP_FOUND_WRONG_TYPE = MESSAGE(143, TRANSLATION(), ERROR(),
  Util.gettext("Expected %s to be a %s, but found %s instead."));
public constant Message DUPLICATE_ELEMENTS_NOT_SYNTACTICALLY_IDENTICAL = MESSAGE(144, TRANSLATION(), WARNING(),
  Util.gettext("Duplicate elements (due to inherited elements) not syntactically identical but semantically identical:\n\tfirst element is:  %s\tsecond element is: %s\tModelica specification requires that elements are exactly identical."));
public constant Message GENERIC_INST_FUNCTION = MESSAGE(145, TRANSLATION(), ERROR(),
  Util.gettext("Failed to instantiate function %s in scope %s."));
public constant Message WRONG_NO_OF_ARGS = MESSAGE(146, TRANSLATION(), ERROR(),
  Util.gettext("Wrong number of arguments to %s."));
public constant Message TUPLE_ASSIGN_CREFS_ONLY = MESSAGE(147, TRANSLATION(), ERROR(),
  Util.gettext("Tuple assignment only allowed for tuple of component references in lhs (in %s)."));
public constant Message LOOKUP_FUNCTION_GOT_CLASS = MESSAGE(148, TRANSLATION(), ERROR(),
  Util.gettext("Looking for a function %s but found a %s."));
public constant Message NON_STREAM_OPERAND_IN_STREAM_OPERATOR = MESSAGE(149, TRANSLATION(), ERROR(),
  Util.gettext("Operand ‘%s‘ to operator ‘%s‘ is not a stream variable."));
public constant Message UNBALANCED_CONNECTOR = MESSAGE(150, TRANSLATION(), WARNING(),
  Util.gettext("Connector %s is not balanced: %s"));
public constant Message RESTRICTION_VIOLATION = MESSAGE(151, TRANSLATION(), ERROR(),
  Util.gettext("Class specialization violation: %s is a %s, not a %s."));
public constant Message ZERO_STEP_IN_ARRAY_CONSTRUCTOR = MESSAGE(152, TRANSLATION(), ERROR(),
  Util.gettext("Step equals 0 in array constructor %s."));
public constant Message RECURSIVE_SHORT_CLASS_DEFINITION = MESSAGE(153, TRANSLATION(), ERROR(),
  Util.gettext("Recursive short class definition of %s in terms of %s."));
public constant Message WRONG_NUMBER_OF_SUBSCRIPTS = MESSAGE(154, TRANSLATION(), ERROR(),
  Util.gettext("Wrong number of subscripts in %s (%s subscripts for %s dimensions)."));
public constant Message FUNCTION_ELEMENT_WRONG_KIND = MESSAGE(155, TRANSLATION(), ERROR(),
  Util.gettext("Element is not allowed in function context: %s"));
public constant Message MISSING_DEFAULT_ARG = MESSAGE(156, TRANSLATION(), WARNING(),
  Util.gettext("Missing default argument on function parameter %s."));
public constant Message DUPLICATE_CLASSES_TOP_LEVEL = MESSAGE(157, TRANSLATION(), ERROR(),
  Util.gettext("Duplicate classes on top level is not allowed (got %s)."));
public constant Message WHEN_EQ_LHS = MESSAGE(158, TRANSLATION(), ERROR(),
  Util.gettext("Invalid left-hand side of when-equation: %s."));
public constant Message GENERIC_ELAB_EXPRESSION = MESSAGE(159, TRANSLATION(), ERROR(),
  Util.gettext("Failed to elaborate expression: %s."));
public constant Message EXTENDS_EXTERNAL = MESSAGE(160, TRANSLATION(), WARNING(),
  Util.gettext("Ignoring external declaration of the extended class: %s."));
public constant Message DOUBLE_DECLARATION_OF_ELEMENTS = MESSAGE(161, TRANSLATION(), ERROR(),
  Util.gettext("An element with name %s is already declared in this scope."));
public constant Message INVALID_REDECLARATION_OF_CLASS = MESSAGE(162, TRANSLATION(), ERROR(),
  Util.gettext("Invalid redeclaration of class %s, class extends only allowed on inherited classes."));
public constant Message MULTIPLE_QUALIFIED_IMPORTS_WITH_SAME_NAME = MESSAGE(163, TRANSLATION(), ERROR(),
  Util.gettext("Qualified import name %s already exists in this scope."));
public constant Message EXTENDS_INHERITED_FROM_LOCAL_EXTENDS = MESSAGE(164, TRANSLATION(), ERROR(),
  Util.gettext("%s was found in base class %s."));
public constant Message LOOKUP_FUNCTION_ERROR = MESSAGE(165, TRANSLATION(), ERROR(),
  Util.gettext("Function %s not found in scope %s."));
public constant Message ELAB_CODE_EXP_FAILED = MESSAGE(166, TRANSLATION(), ERROR(),
  Util.gettext("Failed to elaborate %s as a code expression of type %s."));
public constant Message EQUATION_TRANSITION_FAILURE = MESSAGE(167, TRANSLATION(), ERROR(),
  Util.gettext("Equations are not allowed in %s."));
public constant Message METARECORD_CONTAINS_METARECORD_MEMBER = MESSAGE(168, TRANSLATION(), ERROR(),
  Util.gettext("The called uniontype record (%s) contains a member (%s) that has a uniontype record as its type instead of a uniontype."));
public constant Message INVALID_EXTERNAL_OBJECT = MESSAGE(169, TRANSLATION(), ERROR(),
  Util.gettext("Invalid external object %s, %s."));
public constant Message CIRCULAR_COMPONENTS = MESSAGE(170, TRANSLATION(), ERROR(),
  Util.gettext("Cyclically dependent constants or parameters found in scope %s: %s (ignore with -d=ignoreCycles)."));
public constant Message FAILURE_TO_DEDUCE_DIMS_FROM_MOD = MESSAGE(171, TRANSLATION(), WARNING(),
  Util.gettext("Failed to deduce dimensions of %s due to unknown dimensions of modifier %s."));
public constant Message REPLACEABLE_BASE_CLASS = MESSAGE(172, TRANSLATION(), ERROR(),
  Util.gettext("Class '%s' in 'extends %s' is replaceable, the base class name must be transitively non-replaceable."));
public constant Message NON_REPLACEABLE_CLASS_EXTENDS = MESSAGE(173, TRANSLATION(), ERROR(),
  Util.gettext("Non-replaceable base class %s in class extends."));
public constant Message ERROR_FROM_HERE = MESSAGE(174, TRANSLATION(), NOTIFICATION(),
  Util.gettext("From here:"));
public constant Message EXTERNAL_FUNCTION_RESULT_NOT_CREF = MESSAGE(175, TRANSLATION(), ERROR(),
  Util.gettext("The lhs (result) of the external function declaration is not a component reference: %s."));
public constant Message EXTERNAL_FUNCTION_RESULT_NOT_VAR = MESSAGE(176, TRANSLATION(), ERROR(),
  Util.gettext("The lhs (result) of the external function declaration is not a variable."));
public constant Message EXTERNAL_FUNCTION_RESULT_ARRAY_TYPE = MESSAGE(177, TRANSLATION(), ERROR(),
  Util.gettext("The lhs (result) of the external function declaration has array type (%s), but this is not allowed in the specification. You need to pass it as an input to the function (preferably also with a size()-expression to avoid out-of-bounds errors in the external call)."));
public constant Message INVALID_REDECLARE = MESSAGE(178, TRANSLATION(), ERROR(),
  Util.gettext("Redeclaration of %s %s %s is not allowed."));
public constant Message INVALID_TYPE_PREFIX = MESSAGE(179, TRANSLATION(), ERROR(),
  Util.gettext("Invalid type prefix '%s' on %s %s, due to existing type prefix '%s'."));
public constant Message LINEAR_SYSTEM_INVALID = MESSAGE(180, SYMBOLIC(), ERROR(),
  Util.gettext("Linear solver (%s) returned invalid input for linear system %s."));
public constant Message LINEAR_SYSTEM_SINGULAR = MESSAGE(181, SYMBOLIC(), WARNING(),
  Util.gettext("The linear system: %1\n might be structurally or numerically singular for variable %3 since U(%2,%2) = 0.0. It might be hard to solve. Compilation continues anyway."));
public constant Message EMPTY_ARRAY = MESSAGE(182, TRANSLATION(), ERROR(),
  Util.gettext("Array constructor may not be empty."));
public constant Message LOAD_MODEL_DIFFERENT_VERSIONS = MESSAGE(183, SCRIPTING(), WARNING(),
  Util.gettext("Requested package %s of version %s, but this package was already loaded with version %s. You might experience problems if these versions are incompatible."));
public constant Message LOAD_MODEL = MESSAGE(184, SCRIPTING(), ERROR(),
  Util.gettext("Failed to load package %s (%s) using MODELICAPATH %s."));
public constant Message REPLACEABLE_BASE_CLASS_SIMPLE = MESSAGE(185, TRANSLATION(), ERROR(),
  Util.gettext("Base class %s is replaceable."));
public constant Message INVALID_SIZE_INDEX = MESSAGE(186, TRANSLATION(), ERROR(),
  Util.gettext("Invalid index %s in call to size of %s, valid index interval is [1,%s]."));
public constant Message ALGORITHM_TRANSITION_FAILURE = MESSAGE(187, TRANSLATION(), ERROR(),
  Util.gettext("Algorithm section is not allowed in %s."));
public constant Message FAILURE_TO_DEDUCE_DIMS_NO_MOD = MESSAGE(188, TRANSLATION(), ERROR(),
  Util.gettext("Failed to deduce dimension %s of %s due to missing binding equation."));
public constant Message FUNCTION_MULTIPLE_ALGORITHM = MESSAGE(189, TRANSLATION(), WARNING(),
  Util.gettext("The behavior of multiple algorithm sections in function %s is not standard Modelica. OpenModelica will execute the sections in the order in which they were declared or inherited (same ordering as inherited input/output arguments, which also are not standardized)."));
public constant Message STATEMENT_GENERIC_FAILURE = MESSAGE(190, TRANSLATION(), ERROR(),
  Util.gettext("Failed to instantiate statement:\n%s"));
public constant Message EXTERNAL_NOT_SINGLE_RESULT = MESSAGE(191, TRANSLATION(), ERROR(),
  Util.gettext("%s is an unbound output in external function %s. Either add it to the external declaration or add a default binding."));
public constant Message FUNCTION_UNUSED_INPUT = MESSAGE(192, SYMBOLIC(), WARNING(),
  Util.gettext("Unused input variable %s in function %s."));
public constant Message ARRAY_TYPE_MISMATCH = MESSAGE(193, TRANSLATION(), ERROR(),
  Util.gettext("Array types mismatch: %s and %s."));
public constant Message VECTORIZE_TWO_UNKNOWN = MESSAGE(194, TRANSLATION(), ERROR(),
  Util.gettext("Could not vectorize call with unknown dimensions due to finding two for-iterators: %s and %s."));
public constant Message FUNCTION_SLOT_VARIABILITY = MESSAGE(195, TRANSLATION(), ERROR(),
  Util.gettext("Function argument %s=%s in call to %s has variability %s which is not a %s expression."));
public constant Message INVALID_ARRAY_DIM_IN_CONVERSION_OP = MESSAGE(196, TRANSLATION(), ERROR(),
  Util.gettext("Invalid dimension %s of argument to %s, expected dimension size %s but got %s."));
public constant Message DUPLICATE_REDECLARATION = MESSAGE(197, TRANSLATION(), ERROR(),
  Util.gettext("%s is already redeclared in this scope."));
public constant Message INVALID_FUNCTION_VAR_TYPE = MESSAGE(198, TRANSLATION(), ERROR(),
  Util.gettext("Invalid type %s for function component %s."));
public constant Message IMBALANCED_EQUATIONS = MESSAGE(199, SYMBOLIC(), ERROR(),
  Util.gettext("An independent subset of the model has imbalanced number of equations (%s) and variables (%s).\nvariables:\n%s\nequations:\n%s"));
public constant Message EQUATIONS_VAR_NOT_DEFINED = MESSAGE(200, SYMBOLIC(), ERROR(),
  Util.gettext("Variable %s is not referenced in any equation (possibly after symbolic manipulations)."));
public constant Message NON_FORMAL_PUBLIC_FUNCTION_VAR = MESSAGE(201, TRANSLATION(), WARNING(),
  Util.gettext("Invalid public variable %s, function variables that are not input/output must be protected."));
public constant Message PROTECTED_FORMAL_FUNCTION_VAR = MESSAGE(202, TRANSLATION(), ERROR(),
  Util.gettext("Invalid protected variable %s, function variables that are input/output must be public."));
public constant Message UNFILLED_SLOT = MESSAGE(203, TRANSLATION(), ERROR(),
  Util.gettext("Function parameter %s was not given by the function call, and does not have a default value."));
public constant Message SAME_CONNECT_INSTANCE = MESSAGE(204, TRANSLATION(), WARNING(),
  Util.gettext("connect(%s, %s) connects the same connector instance! The connect equation will be ignored."));
public constant Message STACK_OVERFLOW = MESSAGE(205, SCRIPTING(), ERROR(),
  Util.gettext("Stack overflow occurred while evaluating %s."));
public constant Message UNKNOWN_DEBUG_FLAG = MESSAGE(206, SCRIPTING(), ERROR(),
  Util.gettext("Unknown debug flag %s."));
public constant Message INVALID_FLAG_TYPE = MESSAGE(207, SCRIPTING(), ERROR(),
  Util.gettext("Invalid type of flag %s, expected %s but got %s."));
public constant Message CHANGED_STD_VERSION = MESSAGE(208, SCRIPTING(), NOTIFICATION(),
  Util.gettext("Modelica language version set to %s due to loading of MSL %s."));
public constant Message SIMPLIFY_FIXPOINT_MAXIMUM = MESSAGE(209, TRANSLATION(), WARNING(),
  Util.gettext("Expression simplification iterated to the fix-point maximum, which may be a performance bottleneck. The last two iterations were: %s, and %s."));
public constant Message UNKNOWN_OPTION = MESSAGE(210, SCRIPTING(), ERROR(),
  Util.gettext("Unknown option %s."));
public constant Message SUBSCRIPTED_MODIFIER = MESSAGE(211, TRANSLATION(), ERROR(),
  Util.gettext("Subscripted modifier is illegal."));
public constant Message TRANS_VIOLATION = MESSAGE(212, TRANSLATION(), ERROR(),
  Util.gettext("Class specialization violation: %s is a %s, which may not contain an %s."));
public constant Message INSERT_CLASS = MESSAGE(213, SCRIPTING(), ERROR(),
  Util.gettext("Failed to insert class %s %s the available classes were:%s"));
public constant Message MISSING_MODIFIED_ELEMENT = MESSAGE(214, TRANSLATION(), ERROR(),
  Util.gettext("Modified element %s not found in class %s."));
public constant Message INVALID_REDECLARE_IN_BASIC_TYPE = MESSAGE(215, TRANSLATION(), ERROR(),
  Util.gettext("Invalid redeclaration of %s, attributes of basic types may not be redeclared."));
public constant Message INVALID_STREAM_CONNECTOR = MESSAGE(216, TRANSLATION(), ERROR(),
  Util.gettext("Invalid stream connector %s: %s"));
public constant Message CONDITION_TYPE_ERROR = MESSAGE(217, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch in condition '%s' of component %s. Expected a Boolean expression, but got an expression of type %s."));
public constant Message SIMPLIFY_CONSTANT_ERROR = MESSAGE(218, TRANSLATION(), NOTIFICATION(),
  Util.gettext("The compiler failed to perform constant folding on expression %s. Please report this bug to the developers and we will fix it as soon as possible (using the +t compiler option if possible)."));
public constant Message SUM_EXPECTED_ARRAY = MESSAGE(219, TRANSLATION(), ERROR(),
  Util.gettext("In sum(%s), the expression is of type %s, but is required to be of builtin array type (of any number of dimensions)."));
public constant Message INVALID_CLASS_RESTRICTION = MESSAGE(220, TRANSLATION(), ERROR(),
  Util.gettext("Invalid specialized class type '%s' for component %s."));
public constant Message CONNECT_IN_INITIAL_EQUATION = MESSAGE(221, TRANSLATION(), ERROR(),
  Util.gettext("Connect equations are not allowed in initial equation sections."));
public constant Message FINAL_COMPONENT_OVERRIDE = MESSAGE(222, TRANSLATION(), ERROR(),
  Util.gettext("Trying to override final element %s with modifier '%s'."));
public constant Message NOTIFY_NOT_LOADED = MESSAGE(223, SCRIPTING(), NOTIFICATION(),
  Util.gettext("Automatically loaded package %s %s due to uses annotation."));
public constant Message REINIT_MUST_BE_REAL = MESSAGE(224, TRANSLATION(), ERROR(),
  Util.gettext("The first argument to reinit must be a subtype of Real, but %s has type %s."));
public constant Message REINIT_MUST_BE_VAR = MESSAGE(225, TRANSLATION(), ERROR(),
  Util.gettext("The first argument to reinit must be a continuous time variable, but %s is %s."));
public constant Message CONNECT_TWO_SOURCES = MESSAGE(226, TRANSLATION(), WARNING(),
  Util.gettext("Connecting two signal sources while connecting %s to %s."));
public constant Message INNER_OUTER_FORMAL_PARAMETER = MESSAGE(227, TRANSLATION(), ERROR(),
  Util.gettext("Invalid prefix %s on formal parameter %s."));
public constant Message REDECLARE_NONEXISTING_ELEMENT = MESSAGE(228, TRANSLATION(), ERROR(),
  Util.gettext("Illegal redeclare of element %s, no inherited element with that name exists."));
public constant Message INVALID_ARGUMENT_TYPE_FIRST_ARRAY = MESSAGE(229, TRANSLATION(), ERROR(),
  Util.gettext("The first argument of %s must be an array expression."));
public constant Message INVALID_ARGUMENT_TYPE_BRANCH_FIRST = MESSAGE(230, TRANSLATION(), ERROR(),
  Util.gettext("The first argument of %s must be on the form A.R, where A is a connector and R an over-determined type/record."));
public constant Message INVALID_ARGUMENT_TYPE_BRANCH_SECOND = MESSAGE(231, TRANSLATION(), ERROR(),
  Util.gettext("The second argument of %s must be on the form A.R, where A is a connector and R an over-determined type/record."));
public constant Message INVALID_ARGUMENT_TYPE_OVERDET_FIRST = MESSAGE(232, TRANSLATION(), ERROR(),
  Util.gettext("The first argument of %s must be an over-determined type or record."));
public constant Message INVALID_ARGUMENT_TYPE_OVERDET_SECOND = MESSAGE(233, TRANSLATION(), ERROR(),
  Util.gettext("The second argument of %s must be an over-determined type or record."));
public constant Message LIBRARY_ONE_PACKAGE_PER_FILE = MESSAGE(234, GRAMMAR(), ERROR(),
  Util.gettext("Modelica library files should contain exactly one package, but found the following classes: %s."));
public constant Message LIBRARY_UNEXPECTED_WITHIN = MESSAGE(235, GRAMMAR(), ERROR(),
  Util.gettext("Expected the package to have %s but got %s."));
public constant Message LIBRARY_UNEXPECTED_NAME = MESSAGE(236, SCRIPTING(), ERROR(),
  Util.gettext("Expected the package to have name %s, but got %s."));
public constant Message PACKAGE_MO_NOT_IN_ORDER = MESSAGE(237, GRAMMAR(), ERROR(),
  Util.gettext("Elements in the package.mo-file need to be in the same relative order as the package.order file. Got element named %s but it was already added because it was not the next element in the list at that time."));
public constant Message LIBRARY_EXPECTED_PARTS = MESSAGE(238, GRAMMAR(), ERROR(),
  Util.gettext("%s is a package.mo-file and needs to be based on class parts (i.e. not class extends, derived class, or enumeration)."));
public constant Message PACKAGE_ORDER_FILE_NOT_FOUND = MESSAGE(239, GRAMMAR(), ERROR(),
  Util.gettext("%1 was referenced in the package.order file, but was not found in package.mo, %1/package.mo or %1.mo."));
public constant Message FOUND_ELEMENT_NOT_IN_ORDER_FILE = MESSAGE(240, GRAMMAR(), ERROR(),
  Util.gettext("Got element %1 that was not referenced in the package.order file."));
public constant Message ORDER_FILE_COMPONENTS = MESSAGE(241, GRAMMAR(), ERROR(),
  Util.gettext("Components referenced in the package.order file must be moved in full chunks. Either split the constants to different lines or make them subsequent in the package.order file."));
public constant Message GUARD_EXPRESSION_TYPE_MISMATCH = MESSAGE(242, GRAMMAR(), ERROR(),
  Util.gettext("Guard expressions need to be Boolean, got expression of type %s."));
public constant Message FUNCTION_RETURNS_META_ARRAY = MESSAGE(243, TRANSLATION(), ERROR(),
  Util.gettext("User-defined function calls that return Array<...> are not supported: %s."));
public constant Message ASSIGN_UNKNOWN_ERROR = MESSAGE(244, TRANSLATION(), ERROR(),
  Util.gettext("Failed elaborate assignment for some unknown reason: %1 := %2. File a bug report and we will make sure this error gets a better message in the future."));
public constant Message WARNING_DEF_USE = MESSAGE(245, TRANSLATION(), WARNING(),
  Util.gettext("%s was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed."));
public constant Message EXP_TYPE_MISMATCH = MESSAGE(246, TRANSLATION(), ERROR(),
  Util.gettext("Expression '%1' has type %3, expected type %2."));
public constant Message PACKAGE_ORDER_DUPLICATES = MESSAGE(247, TRANSLATION(), ERROR(),
  Util.gettext("Found duplicate names in package.order file: %s."));
public constant Message ERRONEOUS_TYPE_ERROR = MESSAGE(248, TRANSLATION(), ERROR(),
  Util.gettext("Got type mismatch error, but matching types %s.\nThis is a ***COMPILER BUG***, please report it to https://trac.openmodelica.org/OpenModelica."));
public constant Message REINIT_MUST_BE_VAR_OR_ARRAY = MESSAGE(249, TRANSLATION(), ERROR(),
  Util.gettext("The first argument to reinit must be a variable of type Real or an array of such variables."));
public constant Message SLICE_ASSIGN_NON_ARRAY = MESSAGE(250, SCRIPTING(), ERROR(),
  Util.gettext("Cannot assign slice to non-initialized array %s."));
public constant Message EXTERNAL_ARG_WRONG_EXP = MESSAGE(251, TRANSLATION(), ERROR(),
  Util.gettext("Expression %s cannot be an external argument. Only identifiers, scalar constants, and size-expressions are allowed."));
public constant Message OPERATOR_FUNCTION_NOT_EXPECTED = MESSAGE(252, TRANSLATION(), ERROR(),
  Util.gettext("Only classes of type 'operator record' may contain elements of type 'operator function'; %s was found in a class that has restriction '%s'."));
public constant Message OPERATOR_FUNCTION_EXPECTED = MESSAGE(253, TRANSLATION(), ERROR(),
  Util.gettext("'operator record' classes may only contain elements of type 'operator function'; %s has restriction '%s'."));
public constant Message STRUCTURAL_SINGULAR_INITIAL_SYSTEM = MESSAGE(254, SYMBOLIC(), ERROR(),
  Util.gettext("Initialization problem is structurally singular, error found sorting equations \n %s for variables \n %s"));
public constant Message UNFIXED_PARAMETER_WITH_BINDING = MESSAGE(255, SYMBOLIC(), WARNING(),
  Util.gettext("The parameter %s has fixed = false and a binding equation %s = %s, which is probably redundant.\nSetting fixed = false usually means there is an additional initial equation to determine the parameter value. The binding was ignored by old Modelica tools, but this is not according to the Modelica specification. Please remove the parameter binding, or bind the parameter to another parameter with fixed = false and no binding."));
public constant Message UNFIXED_PARAMETER_WITH_BINDING_31 = MESSAGE(256, SYMBOLIC(), WARNING(),
  Util.gettext("The parameter %s has fixed = false and a binding equation %s = %s, which is probably redundant. The binding equation will be ignored, as it is expected for Modelica 3.1."));
public constant Message UNFIXED_PARAMETER_WITH_BINDING_AND_START_VALUE_31 = MESSAGE(257, SYMBOLIC(), WARNING(),
  Util.gettext("The parameter %s has fixed = false, a start value, start = %s and a binding equation %s = %s, which is probably redundant. The binding equation will be ignored, as it is expected for Modelica 3.1."));
public constant Message BACKENDDAEINFO_LOWER = MESSAGE(258, SYMBOLIC(), NOTIFICATION(),
  Util.gettext("Model statistics after passing the front-end and creating the data structures used by the back-end:\n * Number of equations: %s\n * Number of variables: %s"));
public constant Message BACKENDDAEINFO_STATISTICS = MESSAGE(259, SYMBOLIC(), NOTIFICATION(),
  Util.gettext("Model statistics after passing the back-end for %s:\n * Number of independent subsystems: %s\n * Number of states: %s\n * Number of discrete variables: %s\n * Number of discrete states: %s\n * Top-level inputs: %s"));
public constant Message BACKENDDAEINFO_MIXED = MESSAGE(260, SYMBOLIC(), NOTIFICATION(),
  Util.gettext("Mixed equation statistics:\n * Mixed systems with single equation: %s\n * Mixed systems with array equation: %s\n * Mixed systems with algorithm: %s\n * Mixed systems with complex equation: %s\n * Mixed systems with constant Jacobian: %s\n * Mixed systems with linear Jacobian: %s\n * Mixed systems with non-linear Jacobian: %s\n * Mixed systems with analytic Jacobian: %s\n * Mixed systems with linear tearing system: %s\n * Mixed systems with nonlinear tearing system: %s"));
public constant Message BACKENDDAEINFO_STRONGCOMPONENT_STATISTICS = MESSAGE(261, SYMBOLIC(), NOTIFICATION(),
  Util.gettext("Strong component statistics for %s (%s):\n * Single equations (assignments): %s\n * Array equations: %s\n * Algorithm blocks: %s\n * Record equations: %s\n * When equations: %s\n * If-equations: %s\n * Equation systems (linear and non-linear blocks): %s\n * Torn equation systems: %s\n * Mixed (continuous/discrete) equation systems: %s"));
public constant Message BACKENDDAEINFO_SYSTEMS = MESSAGE(262, SYMBOLIC(), NOTIFICATION(),
  Util.gettext("Equation system details:\n * Constant Jacobian: %s\n * Linear Jacobian (size,density): %s\n * Non-linear Jacobian: %s\n * Without analytic Jacobian: %s"));
public constant Message BACKENDDAEINFO_TORN = MESSAGE(263, SYMBOLIC(), NOTIFICATION(),
  Util.gettext("Torn system details for %s tearing set:\n * Linear torn systems: %s\n * Non-linear torn systems: %s"));
public constant Message BACKEND_DAE_TO_MODELICA = MESSAGE(264, SYMBOLIC(), NOTIFICATION(),
  Util.gettext("The following Modelica-like model represents the back-end DAE for the '%s' stage:\n%s"));
public constant Message NEGATIVE_DIMENSION_INDEX = MESSAGE(265, TRANSLATION(), ERROR(),
  Util.gettext("Negative dimension index (%s) for component %s."));
public constant Message GENERATE_SEPARATE_CODE_DEPENDENCIES_FAILED = MESSAGE(266, SCRIPTING(), ERROR(),
  Util.gettext("Failed to get dependencies for package %s. Perhaps there is an import to a non-existing package."));
public constant Message CYCLIC_DEFAULT_VALUE = MESSAGE(267, SCRIPTING(), ERROR(),
  Util.gettext("The default value of %s causes a cyclic dependency."));
public constant Message NAMED_ARG_TYPE_MISMATCH = MESSAGE(268, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch for named argument in %s(%s=%s). The argument has type:\n  %s\nexpected type:\n  %s"));
public constant Message ARG_TYPE_MISMATCH = MESSAGE(269, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch for positional argument %s in %s(%s=%s). The argument has type:\n  %s\nexpected type:\n  %s"));
public constant Message OP_OVERLOAD_MULTIPLE_VALID = MESSAGE(270, TRANSLATION(), ERROR(),
  Util.gettext("Operator overloading requires exactly one matching expression, but found %s expressions: %s"));
public constant Message OP_OVERLOAD_OPERATOR_NOT_INPUT = MESSAGE(271, TRANSLATION(), ERROR(),
  Util.gettext("Operator %s is not an input to the overloaded function: %s"));
public constant Message NOTIFY_FRONTEND_STRUCTURAL_PARAMETERS = MESSAGE(272, TRANSLATION(), NOTIFICATION(),
  Util.gettext("The following structural parameters were evaluated in the front-end: %s\nStructural parameters are parameters used to calculate array dimensions or branch selection in certain if-equations or if-expressions among other things."));
public constant Message SIMPLIFICATION_TYPE = MESSAGE(273, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Expression simplification '%s' → '%s' changed the type from %s to %s."));
public constant Message VECTORIZE_CALL_DIM_MISMATCH = MESSAGE(274, TRANSLATION(), ERROR(),
  Util.gettext("Failed to vectorize function call because arguments %s=%s and %s=%s have mismatched dimensions %s and %s."));
public constant Message TCOMPLEX_MULTIPLE_NAMES = MESSAGE(275, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Non-tuple complex type specifiers need to have exactly one type name: %s."));
public constant Message TCOMPLEX_TUPLE_ONE_NAME = MESSAGE(276, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Tuple complex type specifiers need to have more than one type name: %s."));
public constant Message ENUM_DUPLICATES = MESSAGE(277, TRANSLATION(), ERROR(),
  Util.gettext("Enumeration has duplicate names: %s in list of names %s."));
public constant Message RESERVED_IDENTIFIER = MESSAGE(278, TRANSLATION(), ERROR(),
  Util.gettext("Identifier %s is reserved for the built-in element with the same name."));
public constant Message NOTIFY_IMPACT_FOUND = MESSAGE(279, SCRIPTING(), NOTIFICATION(),
  Util.gettext("The impact package manager downloaded package %s%s to directory %s."));
public constant Message DERIVATIVE_FUNCTION_CONTEXT = MESSAGE(280, SCRIPTING(), ERROR(),
  Util.gettext("The der() operator is not allowed in function context (possible solutions: pass the derivative as an explicit input; use a block instead of function)."));
public constant Message RETURN_OUTSIDE_FUNCTION = MESSAGE(281, TRANSLATION(), ERROR(),
  Util.gettext("'return' may not be used outside function."));
public constant Message EXT_LIBRARY_NOT_FOUND = MESSAGE(282, TRANSLATION(), WARNING(),
  Util.gettext("Could not find library %s in either of:%s"));
public constant Message EXT_LIBRARY_NOT_FOUND_DESPITE_COMPILATION_SUCCESS = MESSAGE(283, TRANSLATION(), WARNING(),
  Util.gettext("Could not find library %s despite compilation command %s in directory %s returning success."));
public constant Message GENERATE_SEPARATE_CODE_DEPENDENCIES_FAILED_UNKNOWN_PACKAGE = MESSAGE(284, SCRIPTING(), ERROR(),
  Util.gettext("Failed to get dependencies for package %s. %s contains an import to non-existing package %s."));
public constant Message USE_OF_PARTIAL_CLASS = MESSAGE(285, TRANSLATION(), ERROR(),
  Util.gettext("component %s contains the definition of a partial class %s.\nPlease redeclare it to any package compatible with %s."));
public constant Message SCANNER_ERROR = MESSAGE(286, SYNTAX(), ERROR(),
  Util.gettext("Syntax error, unrecognized input: %s."));
public constant Message SCANNER_ERROR_LIMIT = MESSAGE(287, SYNTAX(), ERROR(),
  Util.gettext("Additional syntax errors were suppressed."));
public constant Message INVALID_TIME_SCOPE = MESSAGE(288, TRANSLATION(), ERROR(),
  Util.gettext("Built-in variable 'time' may only be used in a model or block."));
public constant Message NO_JACONIAN_TORNLINEAR_SYSTEM = MESSAGE(289, SYMBOLIC(), ERROR(),
  Util.gettext("A torn linear system has no symbolic jacobian and currently there are no means to solve that numerically. Please compile with the module \"calculateStrongComponentJacobians\" to provide symbolic jacobians for torn linear systems."));
public constant Message EXT_FN_SINGLE_RETURN_ARRAY = MESSAGE(290, TRANSLATION(), WARNING(),
  Util.gettext("An external declaration with a single output without explicit mapping is defined as having the output as the lhs, but language %s does not support this for array variables. OpenModelica will put the output as an input (as is done when there is more than 1 output), but this is not according to the Modelica Specification. Use an explicit mapping instead of the implicit one to suppress this warning."));
public constant Message RHS_TUPLE_EXPRESSION = MESSAGE(291, TRANSLATION(), ERROR(),
  Util.gettext("Tuple expressions may only occur on the left side of an assignment or equation with a single function call on the right side. Got the following expression: %s."));
public constant Message EACH_ON_NON_ARRAY = MESSAGE(292, TRANSLATION(), WARNING(),
  Util.gettext("'each' used when modifying non-array element %s."));
public constant Message BUILTIN_EXTENDS_INVALID_ELEMENTS = MESSAGE(293, TRANSLATION(), ERROR(),
  Util.gettext("A class extending from builtin type %s may not have other elements."));
public constant Message INITIAL_CALL_WARNING = MESSAGE(294, TRANSLATION(), WARNING(),
  Util.gettext("The standard says that initial() may only be used as a when condition (when initial() or when {..., initial(), ...}), but got condition %s."));
public constant Message RANGE_TYPE_MISMATCH = MESSAGE(295, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch in range: '%s' of type\n  %s\nis not type compatible with '%s' of type\n  %s"));
public constant Message RANGE_TOO_SMALL_STEP = MESSAGE(296, TRANSLATION(), ERROR(),
  Util.gettext("Step size %s in range is too small."));
public constant Message RANGE_INVALID_STEP = MESSAGE(297, TRANSLATION(),
ERROR(),
  Util.gettext("Range of type %s may not specify a step size."));
public constant Message RANGE_INVALID_TYPE = MESSAGE(298, TRANSLATION(), ERROR(),
  Util.gettext("Range has invalid type %s."));
public constant Message CLASS_EXTENDS_MISSING_REDECLARE = MESSAGE(299, TRANSLATION(), WARNING(),
  Util.gettext("Missing redeclare prefix on class extends %s, treating like redeclare anyway."));
public constant Message CYCLIC_DIMENSIONS = MESSAGE(300, TRANSLATION(), ERROR(),
  Util.gettext("Dimension %s of %s, '%s', could not be evaluated due to a cyclic dependency."));
public constant Message INVALID_DIMENSION_TYPE = MESSAGE(301, TRANSLATION(), ERROR(),
  Util.gettext("Dimension '%s' of type %s is not an integer expression or an enumeration or Boolean type name."));
public constant Message RAGGED_DIMENSION = MESSAGE(302, TRANSLATION(), ERROR(),
  Util.gettext("Ragged dimensions are not yet supported (from dimension '%s')"));
public constant Message INVALID_TYPENAME_USE = MESSAGE(303, TRANSLATION(), ERROR(),
  Util.gettext("Type name '%s' is not allowed in this context."));
public constant Message FOUND_WRONG_INNER_ELEMENT = MESSAGE(305, TRANSLATION(), ERROR(),
  Util.gettext("Found inner %s %s instead of expected %s."));
public constant Message FOUND_OTHER_BASECLASS = MESSAGE(306, TRANSLATION(), ERROR(),
  Util.gettext("Found other base class for extends %s after instantiating extends."));
public constant Message OUTER_ELEMENT_MOD = MESSAGE(307, TRANSLATION(), ERROR(),
  Util.gettext("Modifier '%s' found on outer element %s."));
public constant Message OUTER_LONG_CLASS = MESSAGE(308, TRANSLATION(), ERROR(),
  Util.gettext("Illegal outer class %s, outer classes may only be declared using short-class definitions."));
public constant Message MISSING_INNER_ADDED = MESSAGE(309, TRANSLATION(), WARNING(),
  Util.gettext("An inner declaration for outer %s %s could not be found and was automatically generated."));
public constant Message MISSING_INNER_MESSAGE = MESSAGE(310, TRANSLATION(), NOTIFICATION(),
  Util.gettext("The diagnostics message for the missing inner is: %s"));
public constant Message INVALID_CONNECTOR_FORM = MESSAGE(311, TRANSLATION(), ERROR(),
  Util.gettext("%s is not a valid form for a connector, connectors must be either c1.c2...cn or m.c (where c is a connector and m is a non-connector)."));
public constant Message CONNECTOR_PREFIX_OUTSIDE_CONNECTOR = MESSAGE(312, TRANSLATION(), WARNING(),
  Util.gettext("Prefix '%s' used outside connector declaration."));
public constant Message EXTERNAL_OBJECT_INVALID_ELEMENT = MESSAGE(313, TRANSLATION(), ERROR(),
  Util.gettext("External object %s contains invalid element '%s'."));
public constant Message EXTERNAL_OBJECT_MISSING_STRUCTOR = MESSAGE(314, TRANSLATION(), ERROR(),
  Util.gettext("External object %s is missing a %s."));
public constant Message MULTIPLE_SECTIONS_IN_FUNCTION = MESSAGE(315, TRANSLATION(), ERROR(),
  Util.gettext("Function %s has more than one algorithm section or external declaration."));
public constant Message INVALID_EXTERNAL_LANGUAGE = MESSAGE(316, TRANSLATION(), ERROR(),
  Util.gettext("'%s' is not a valid language for an external function."));
public constant Message SUBSCRIPT_TYPE_MISMATCH = MESSAGE(317, TRANSLATION(), ERROR(),
  Util.gettext("Subscript '%s' has type %s, expected type %s."));
public constant Message EXP_INVALID_IN_FUNCTION = MESSAGE(318, TRANSLATION(), ERROR(),
  Util.gettext("%s is not allowed in a function."));
public constant Message NO_MATCHING_FUNCTION_FOUND_NFINST = MESSAGE(319, TRANSLATION(), ERROR(),
  Util.gettext("No matching function found for %s.\nCandidates are:\n  %s"));
public constant Message ARGUMENT_OUT_OF_RANGE = MESSAGE(320, TRANSLATION(), ERROR(),
  Util.gettext("Argument %s of %s is out of range (%s)"));
public constant Message UNBOUND_CONSTANT = MESSAGE(321, TRANSLATION(), ERROR(),
  Util.gettext("Constant %s is used without having been given a value."));
public constant Message INVALID_ARGUMENT_VARIABILITY = MESSAGE(322, TRANSLATION(), ERROR(),
  Util.gettext("Argument %s of %s must be a %s expression, but %s is %s."));
public constant Message AMBIGUOUS_MATCHING_FUNCTIONS_NFINST = MESSAGE(323, TRANSLATION(), ERROR(),
  Util.gettext("Ambiguous matching functions found for %s.\nCandidates are:\n  %s"));
public constant Message AMBIGUOUS_MATCHING_OPERATOR_FUNCTIONS_NFINST = MESSAGE(324, TRANSLATION(), ERROR(),
  Util.gettext("Ambiguous matching overloaded operator functions found for %s.\nCandidates are:\n  %s"));
public constant Message REDECLARE_CONDITION = MESSAGE(325, TRANSLATION(), ERROR(),
  Util.gettext("Invalid redeclaration of %s, a redeclare may not have a condition attribute."));
public constant Message REDECLARE_OF_CONSTANT = MESSAGE(326, TRANSLATION(), ERROR(),
  Util.gettext("%s is constant and may not be redeclared."));
public constant Message REDECLARE_MISMATCHED_PREFIX = MESSAGE(327, TRANSLATION(), ERROR(),
  Util.gettext("Invalid redeclaration '%s %s', original element is declared '%s'."));
public constant Message EXTERNAL_ARG_NONCONSTANT_SIZE_INDEX = MESSAGE(328, TRANSLATION(), ERROR(),
  Util.gettext("Invalid external argument '%s', the dimension index must be a constant expression."));
public constant Message FAILURE_TO_DEDUCE_DIMS_EACH = MESSAGE(329, TRANSLATION(), ERROR(),
  Util.gettext("Failed to deduce dimension %s of ‘%s‘ due to ‘each‘ prefix on binding equation."));
public constant Message MISSING_TYPE_BASETYPE = MESSAGE(330, TRANSLATION(), ERROR(),
  Util.gettext("Type ‘%s‘ does not extend a basic type."));
public constant Message ASSERT_TRIGGERED_WARNING = MESSAGE(331, TRANSLATION(), WARNING(),
  Util.gettext("assert triggered: %s"));
public constant Message ASSERT_TRIGGERED_ERROR = MESSAGE(332, TRANSLATION(), ERROR(),
  Util.gettext("assert triggered: %s"));
public constant Message TERMINATE_TRIGGERED = MESSAGE(333, TRANSLATION(), ERROR(),
  Util.gettext("terminate triggered: %s"));
public constant Message EVAL_RECURSION_LIMIT_REACHED = MESSAGE(334, TRANSLATION(), ERROR(),
  Util.gettext("The recursion limit (--evalRecursionLimit=%s) was exceeded during evaluation of %s."));
public constant Message UNASSIGNED_FUNCTION_OUTPUT = MESSAGE(335, TRANSLATION(), ERROR(),
  Util.gettext("Output parameter %s was not assigned a value"));
public constant Message INVALID_WHEN_STATEMENT_CONTEXT = MESSAGE(336, TRANSLATION(), ERROR(),
  Util.gettext("A when-statement may not be used inside a function or a while, if, or for-clause."));
public constant Message MISSING_FUNCTION_DERIVATIVE_NAME = MESSAGE(337, TRANSLATION(), WARNING(),
  Util.gettext("Derivative annotation for function ‘%s‘ does not specify a derivative function."));
public constant Message INVALID_FUNCTION_DERIVATIVE_ATTR = MESSAGE(338, TRANSLATION(), WARNING(),
  Util.gettext("‘%s‘ is not a valid function derivative attribute."));
public constant Message INVALID_FUNCTION_DERIVATIVE_INPUT = MESSAGE(339, TRANSLATION(), ERROR(),
  Util.gettext("‘%s‘ is not an input of function ‘%s‘."));
public constant Message OPERATOR_OVERLOADING_ONE_OUTPUT_ERROR = MESSAGE(340, TRANSLATION(), ERROR(),
  Util.gettext("Operator %s must have exactly one output."));
public constant Message OPERATOR_OVERLOADING_INVALID_OUTPUT_TYPE = MESSAGE(341, TRANSLATION(), ERROR(),
  Util.gettext("Output ‘%s‘ in operator %s must be of type %s, got type %s."));
public constant Message OPERATOR_NOT_ENCAPSULATED = MESSAGE(342, TRANSLATION(), ERROR(),
  Util.gettext("Operator %s is not encapsulated."));
public constant Message NO_SUCH_INPUT_PARAMETER = MESSAGE(343, TRANSLATION(), ERROR(),
  Util.gettext("Function %s has no input parameter named %s."));
public constant Message INVALID_REDUCTION_TYPE = MESSAGE(344, TRANSLATION(), ERROR(),
  Util.gettext("Invalid expression ‘%s‘ of type %s in %s reduction, expected %s."));
public constant Message INVALID_COMPONENT_PREFIX = MESSAGE(345, TRANSLATION(), ERROR(),
  Util.gettext("Prefix ‘%s‘ on component ‘%s‘ not allowed in class specialization ‘%s‘."));
public constant Message INVALID_CARDINALITY_CONTEXT = MESSAGE(346, TRANSLATION(), ERROR(),
  Util.gettext("cardinality may only be used in the condition of an if-statement/equation or an assert."));
public constant Message VARIABLE_BINDING_DIMS_MISMATCH = MESSAGE(347, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch in binding ‘%s = %s‘, expected array dimensions %s, got %s."));
public constant Message MODIFIER_NON_ARRAY_TYPE_ERROR = MESSAGE(348, TRANSLATION(), ERROR(),
  Util.gettext("Non-array modification ‘%s‘ for array component ‘%s‘, possibly due to missing ‘each‘."));
public constant Message INST_RECURSION_LIMIT_REACHED = MESSAGE(349, TRANSLATION(), ERROR(),
  Util.gettext("Recursion limit reached while instantiating ‘%s‘."));
public constant Message WHEN_IF_VARIABLE_MISMATCH = MESSAGE(350, TRANSLATION(), ERROR(),
  Util.gettext("The branches of an if-equation inside a when-equation must have the same set of component references on the left-hand side."));
public constant Message DIMENSION_DEDUCTION_FROM_BINDING_FAILURE = MESSAGE(351, TRANSLATION(), ERROR(),
  Util.gettext("Dimension %s of ‘%s‘ could not be deduced from the component's binding equation ‘%s‘."));
public constant Message NON_REAL_FLOW_OR_STREAM = MESSAGE(352, TRANSLATION(), ERROR(),
  Util.gettext("Invalid prefix ‘%s‘ on non-Real component ‘%s‘."));
public constant Message LIBRARY_UNEXPECTED_NAME_CASE_SENSITIVE = MESSAGE(353, SCRIPTING(), WARNING(),
  Util.gettext("Expected the package to have name %s, but got %s. Proceeding since only the case of the names are different."));
public constant Message PACKAGE_ORDER_CASE_SENSITIVE = MESSAGE(354, SCRIPTING(), WARNING(),
  Util.gettext("The package.order file contains a class %s, which is expected to be stored in file %s, but seems to be named %s. Proceeding since only the case of the names are different."));
public constant Message INITIALIZATION_NOT_FULLY_SPECIFIED = MESSAGE(496, TRANSLATION(), WARNING(),
  Util.gettext("The initial conditions are not fully specified. %s."));
public constant Message INITIALIZATION_OVER_SPECIFIED = MESSAGE(497, TRANSLATION(), WARNING(),
  Util.gettext("The initial conditions are over specified. %s."));
public constant Message INITIALIZATION_ITERATION_VARIABLES = MESSAGE(498, TRANSLATION(), WARNING(),
  Util.gettext("There are iteration variables with default zero start attribute. %s."));
public constant Message UNBOUND_PARAMETER_WITH_START_VALUE_WARNING = MESSAGE(499, TRANSLATION(), WARNING(),
  Util.gettext("Parameter %s has no value, and is fixed during initialization (fixed=true), using available start value (start=%s) as default value."));
public constant Message UNBOUND_PARAMETER_WARNING = MESSAGE(500, TRANSLATION(), WARNING(),
  Util.gettext("Parameter %s has neither value nor start value, and is fixed during initialization (fixed=true)."));
public constant Message BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER = MESSAGE(502, TRANSLATION(), WARNING(),
  Util.gettext("Function \"product\" has scalar as argument in %s in component %s."));
public constant Message SETTING_FIXED_ATTRIBUTE = MESSAGE(503, TRANSLATION(), WARNING(),
  Util.gettext("Using over-determined solver for initialization. Setting fixed=false to the following variables: %s."));
public constant Message FAILED_TO_EVALUATE_FUNCTION = MESSAGE(506, TRANSLATION(), ERROR(),
  Util.gettext("Failed to evaluate function: %s."));
public constant Message WARNING_RELATION_ON_REAL = MESSAGE(509, TRANSLATION(), WARNING(),
  Util.gettext("In relation %s, %s on Real numbers is only allowed inside functions."));
public constant Message OUTER_MODIFICATION = MESSAGE(512, TRANSLATION(), WARNING(),
  Util.gettext("Ignoring the modification on outer element: %s."));
public constant Message DERIVATIVE_NON_REAL = MESSAGE(514, TRANSLATION(), ERROR(),
  Util.gettext("Argument '%s' to der has illegal type %s, must be a subtype of Real."));
public constant Message UNUSED_MODIFIER = MESSAGE(515, TRANSLATION(), ERROR(),
  Util.gettext("In modifier %s."));
public constant Message MULTIPLE_MODIFIER = MESSAGE(516, TRANSLATION(), ERROR(),
  Util.gettext("Multiple modifiers in same scope for element %s."));
public constant Message INCONSISTENT_UNITS = MESSAGE(517, TRANSLATION(), WARNING(),
  Util.gettext("The system of units is inconsistent in term %s with the units %s and %s respectively."));
public constant Message CONSISTENT_UNITS = MESSAGE(518, TRANSLATION(), NOTIFICATION(),
  Util.gettext("The system of units is consistent."));
public constant Message INCOMPLETE_UNITS = MESSAGE(519, TRANSLATION(), NOTIFICATION(),
  Util.gettext("The system of units is incomplete. Please provide unit information to the model by e.g. using types from the SIunits package."));
public constant Message ASSIGN_RHS_ELABORATION = MESSAGE(521, TRANSLATION(), ERROR(),
  Util.gettext("Failed to elaborate rhs of %s."));
public constant Message FAILED_TO_EVALUATE_EXPRESSION = MESSAGE(522, TRANSLATION(), ERROR(),
  Util.gettext("Could not evaluate expression: %s"));
public constant Message WARNING_JACOBIAN_EQUATION_SOLVE = MESSAGE(523, SYMBOLIC(), WARNING(),
  Util.gettext("Jacobian equation %s could not solve proper for %s. Assume %s=0."));
public constant Message SIMPLIFICATION_COMPLEXITY = MESSAGE(523, SYMBOLIC(), NOTIFICATION(),
  Util.gettext("Simplification produced a higher complexity (%s) than the original (%s). The simplification was: %s => %s."));
public constant Message ITERATOR_NON_ARRAY = MESSAGE(524, TRANSLATION(), ERROR(),
  Util.gettext("Iterator %s, has type %s, but expected a 1D array expression."));
public constant Message INST_INVALID_RESTRICTION = MESSAGE(525, TRANSLATION(), ERROR(),
  Util.gettext("Cannot instantiate %s due to class specialization %s."));
public constant Message INST_NON_LOADED = MESSAGE(526, TRANSLATION(), WARNING(),
  Util.gettext("Library %s was not loaded but is marked as used by model %s."));
public constant Message RECURSION_DEPTH_REACHED = MESSAGE(527, TRANSLATION(), ERROR(),
  Util.gettext("The maximum recursion depth of %s was reached, probably due to mutual recursion. The current scope: %s."));
public constant Message DERIVATIVE_INPUT = MESSAGE(528, TRANSLATION(), ERROR(),
  Util.gettext("The model requires derivatives of some inputs as listed below:\n%s"));
public constant Message UTF8_COMMAND_LINE_ARGS = MESSAGE(529, TRANSLATION(), ERROR(),
  Util.gettext("The compiler was sent command-line arguments that were not UTF-8 encoded and will abort the current execution."));
public constant Message PACKAGE_ORDER_FILE_NOT_COMPLETE = MESSAGE(530, GRAMMAR(), WARNING(),
  Util.gettext("The package.order file does not list all .mo files and directories (containing package.mo) present in its directory.\nMissing names are:\n\t%s"));
public constant Message REINIT_IN_WHEN_INITIAL = MESSAGE(531, TRANSLATION(), ERROR(),
  Util.gettext("Using reinit in when with condition initial() is not allowed. Use assignment or equality equation instead."));
public constant Message MISSING_INNER_CLASS = MESSAGE(532, TRANSLATION(), WARNING(),
  Util.gettext("No corresponding 'inner' declaration found for class %s declared as '%s'.\n Continuing flattening by only considering the 'outer' class declaration."));
public constant Message RECURSION_DEPTH_WARNING = MESSAGE(533, TRANSLATION(), ERROR(),
  Util.gettext("The maximum recursion depth of %s was reached when evaluating expression %s in scope %s. Translation may still succeed but you are recommended to fix the problem."));
public constant Message RECURSION_DEPTH_DERIVED = MESSAGE(534, TRANSLATION(), ERROR(),
  Util.gettext("The maximum recursion depth of was reached when instantiating a derived class. Current class %s in scope %s."));
public constant Message EVAL_EXTERNAL_OBJECT_CONSTRUCTOR = MESSAGE(535, TRANSLATION(), WARNING(),
  Util.gettext("OpenModelica requires that all external objects input arguments are possible to evaluate before initialization in order to avoid odd run-time failures, but %s is a variable."));
public constant Message CLASS_ANNOTATION_DOES_NOT_EXIST = MESSAGE(536, SCRIPTING(), ERROR(),
  Util.gettext("Could not find class annotation %s in class %s."));
public constant Message SEPARATE_COMPILATION_PACKAGE_FAILED = MESSAGE(537, SCRIPTING(), ERROR(),
  Util.gettext("Failed to compile all functions in package %s."));
public constant Message INVALID_ARRAY_DIM_IN_SCALAR_OP = MESSAGE(538, TRANSLATION(), ERROR(),
  Util.gettext("The operator scalar requires all dimension size to be 1, but the input has type %s."));
public constant Message NON_STANDARD_OPERATOR_CLASS_DIRECTORY = MESSAGE(539, TRANSLATION(), WARNING(),
  Util.gettext("classDirectory() is a non-standard operator that was replaced by Modelica.Utilities.Files.loadResource(uri) before it was added to the language specification."));
public constant Message PACKAGE_DUPLICATE_CHILDREN = MESSAGE(540, TRANSLATION(), ERROR(),
  Util.gettext("The same class is defined in multiple files: %s."));
public constant Message INTEGER_ENUMERATION_CONVERSION_WARNING = MESSAGE(541, TRANSLATION(), WARNING(),
  Util.gettext("Integer (%s) to enumeration (%s) conversion is not valid Modelica, please use enumeration constant (%s) instead."));
public constant Message INTEGER_ENUMERATION_OUT_OF_RANGE = MESSAGE(542, TRANSLATION(), ERROR(),
  Util.gettext("The Integer to %s conversion failed, as the Integer %s is outside the range (1, ..., %s) of values corresponding to enumeration constants."));
public constant Message INTEGER_TO_UNKNOWN_ENUMERATION = MESSAGE(543, TRANSLATION(), INTERNAL(),
  Util.gettext("The Integer (%s) to enumeration conversion failed because information about the the enumeration type is missing."));
public constant Message NORETCALL_INVALID_EXP = MESSAGE(544, TRANSLATION(), ERROR(),
  Util.gettext("Expression %s is not a valid statement - only function calls are allowed."));
public constant Message INVALID_FLAG_TYPE_STRINGS = MESSAGE(545, SCRIPTING(), ERROR(),
  Util.gettext("Invalid type of flag %s, expected one of %s but got %s."));
public constant Message FUNCTION_RETURN_EXT_OBJ = MESSAGE(546, TRANSLATION(), ERROR(),
  Util.gettext("Function %s returns an external object, but the only function allowed to return this object is %s."));
public constant Message NON_STANDARD_OPERATOR = MESSAGE(547, TRANSLATION(), WARNING(),
  Util.gettext("Usage of non-standard operator (not specified in the Modelica specification): %s. Functionality might be partially supported but is not guaranteed."));
public constant Message CONNECT_ARRAY_SIZE_ZERO = MESSAGE(548, TRANSLATION(), WARNING(),
  Util.gettext("Ignoring connection of array components having size zero: %s and %s."));
public constant Message ILLEGAL_RECORD_COMPONENT = MESSAGE(549, TRANSLATION(), ERROR(),
  Util.gettext("Ignoring record component:\n%swhen building the record constructor. Records are allowed to contain only components of basic types, arrays of basic types or other records."));
public constant Message EQ_WITHOUT_TIME_DEP_VARS = MESSAGE(550, SYMBOLIC(), ERROR(),
  Util.gettext("Found equation without time-dependent variables: %s = %s"));
public constant Message OVERCONSTRAINED_OPERATOR_SIZE_ZERO = MESSAGE(551, TRANSLATION(), WARNING(),
  Util.gettext("Ignoring overconstrained operator applied to array components having size zero: %s."));
public constant Message OVERCONSTRAINED_OPERATOR_SIZE_ZERO_RETURN_FALSE = MESSAGE(552, TRANSLATION(), WARNING(),
  Util.gettext("Returning false from overconstrained operator applied to array components having size zero: %s."));
public constant Message MISMATCHING_INTERFACE_TYPE = MESSAGE(553, SCRIPTING(), ERROR(),
  Util.gettext("__OpenModelica_Interface types are incompatible. Got interface type '%s', expected something compatible with '%s'."));
public constant Message MISSING_INTERFACE_TYPE = MESSAGE(554, SCRIPTING(), ERROR(),
  Util.gettext("Annotation __OpenModelica_Interface is missing or the string is not in the input list."));
public constant Message CLASS_NOT_FOUND = MESSAGE(555, SCRIPTING(), WARNING(),
  Util.gettext("Class %s not found inside class %s."));
public constant Message NOTIFY_LOAD_MODEL_FAILED = MESSAGE(556, SCRIPTING(), NOTIFICATION(),
  Util.gettext("Skipped loading package %s (%s) using MODELICAPATH %s (uses-annotation may be wrong)."));
public constant Message ROOT_USER_INTERACTIVE = MESSAGE(557, SCRIPTING(), ERROR(),
  Util.gettext("You are trying to run OpenModelica as a server using the root user.\nThis is a very bad idea:\n* The socket interface does not authenticate the user.\n* OpenModelica allows execution of arbitrary commands."));
public constant Message USES_MISSING_VERSION = MESSAGE(558, SCRIPTING(), WARNING(),
  Util.gettext("Uses-annotation is missing version for library %s. Assuming the tool-specific version=\"default\"."));
public constant Message CLOCK_PREFIX_ERROR = MESSAGE(559, TRANSLATION(), ERROR(),
  Util.gettext("Clock variable can not be declared with prefixes flow, stream, discrete, parameter, or constant."));
public constant Message DEFAULT_CLOCK_USED = MESSAGE(560, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Default inferred clock is used."));
public constant Message CONT_CLOCKED_PARTITION_CONFLICT_VAR = MESSAGE(561, TRANSLATION(), ERROR(),
  Util.gettext("Variable %s belongs to clocked and continuous partitions."));
public constant Message ELSE_WHEN_CLOCK = MESSAGE(562, TRANSLATION(), ERROR(),
  Util.gettext("Clocked when equation can not contain elsewhen part."));
public constant Message REINIT_NOT_IN_WHEN = MESSAGE(563, TRANSLATION(), ERROR(),
  Util.gettext("Operator reinit may only be used in the body of a when equation."));
public constant Message NESTED_CLOCKED_WHEN = MESSAGE(564, TRANSLATION(), ERROR(),
  Util.gettext("Nested clocked when statements are not allowed."));
public constant Message CLOCKED_WHEN_BRANCH = MESSAGE(565, TRANSLATION(), ERROR(),
  Util.gettext("Clocked when branch in when equation."));
public constant Message CLOCKED_WHEN_IN_WHEN_EQ = MESSAGE(566, TRANSLATION(), ERROR(),
  Util.gettext("Clocked when equation inside the body of when equation."));
public constant Message CONT_CLOCKED_PARTITION_CONFLICT_EQ = MESSAGE(567, TRANSLATION(), ERROR(),
  Util.gettext("Equation belongs to clocked and continuous partitions."));
public constant Message CLOCK_SOLVERMETHOD = MESSAGE(568, TRANSLATION(), WARNING(),
  Util.gettext("Applying clock solverMethod %s instead of specified %s. Supported are: ImplicitEuler, SemiImplicitEuler, ExplicitEuler and ImplicitTrapezoid."));
public constant Message INVALID_CLOCK_EQUATION = MESSAGE(569, TRANSLATION(), ERROR(),
  Util.gettext("Invalid form of clock equation"));
public constant Message SUBCLOCK_CONFLICT = MESSAGE(570, TRANSLATION(), ERROR(),
  Util.gettext("Partition has different sub-clock %ss (%s) and (%s)."));
public constant Message CLOCK_CONFLICT = MESSAGE(571, TRANSLATION(), ERROR(),
  Util.gettext("Partitions have different base clocks."));
public constant Message EXEC_STAT = MESSAGE(572, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Performance of %s: time %s/%s, allocations: %s / %s, free: %s / %s"));
public constant Message EXEC_STAT_GC = MESSAGE(573, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Performance of %s: time %s/%s, GC stats:%s"));
public constant Message MAX_TEARING_SIZE = MESSAGE(574, SYMBOLIC(), NOTIFICATION(),
  Util.gettext("Tearing is skipped for strong component %s because system size of %s exceeds maximum system size for tearing of %s systems (%s).\nTo adjust the maximum system size for tearing use --maxSizeLinearTearing=<size> and --maxSizeNonlinearTearing=<size>.\n"));
public constant Message NO_TEARING_FOR_COMPONENT = MESSAGE(575, SYMBOLIC(), NOTIFICATION(),
  Util.gettext("Tearing is skipped for strong component %s because of activated compiler flag 'noTearingForComponent=%1'.\n"));
public constant Message WRONG_VALUE_OF_ARG = MESSAGE(576, TRANSLATION(), ERROR(),
  Util.gettext("Wrong value of argument to %s: %s = %s %s."));
public constant Message USER_DEFINED_TEARING_ERROR = MESSAGE(577, SYMBOLIC(), ERROR(),
  Util.gettext("Wrong usage of user defined tearing: %s Make sure you use user defined tearing as stated in the flag description."));
public constant Message USER_TEARING_VARS = MESSAGE(578, SYMBOLIC(), NOTIFICATION(),
  Util.gettext("Following iteration variables are selected by the user for strong component %s (DAE kind: %s):\n%s"));
public constant Message CLASS_EXTENDS_TARGET_NOT_FOUND = MESSAGE(579, TRANSLATION(), ERROR(),
  Util.gettext("Base class targeted by class extends %s not found in the inherited classes."));
public constant Message ASSIGN_PARAM_FIXED_ERROR = MESSAGE(580, TRANSLATION(), ERROR(),
  Util.gettext("Trying to assign to parameter component %s(fixed=true) in %s := %s"));
public constant Message EQN_NO_SPACE_TO_SOLVE = MESSAGE(581, SYMBOLIC(), WARNING(),
  Util.gettext("Equation %s (size: %s) %s is not big enough to solve for enough variables.\n  Remaining unsolved variables are: %s\n  Already solved: %s\n  Equations used to solve those variables:%s"));
public constant Message VAR_NO_REMAINING_EQN = MESSAGE(582, SYMBOLIC(), WARNING(),
  Util.gettext("Variable %s does not have any remaining equation to be solved in.\n  The original equations were:%s"));
public constant Message MOVING_PARAMETER_BINDING_TO_INITIAL_EQ_SECTION = MESSAGE(583, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Moving binding to initial equation section and setting fixed attribute of %s to false."));
public constant Message MIXED_DETERMINED = MESSAGE(584, SYMBOLIC(), ERROR(),
  Util.gettext("The initialization problem of given system is mixed-determined. It is under- as well as overdetermined and the mixed-determination-index is too high. [index > %s]\nPlease checkout the option \"--maxMixedDeterminedIndex\" to simulate with a higher threshold or consider changing some initial equations, fixed variables and start values."));
public constant Message STACK_OVERFLOW_DETAILED = MESSAGE(584, SCRIPTING(), ERROR(),
  Util.gettext("Stack overflow occurred while evaluating %s:\n%s"));
public constant Message NF_VECTOR_INVALID_DIMENSIONS = MESSAGE(585, TRANSLATION(), ERROR(),
  Util.gettext("Invalid dimensions %s in %s, no more than one dimension may have size > 1."));
public constant Message NF_ARRAY_TYPE_MISMATCH = MESSAGE(586, TRANSLATION(), ERROR(),
  Util.gettext("Array types mismatch. Argument %s (%s) has type %s whereas previous arguments have type %s."));
public constant Message NF_DIFFERENT_NUM_DIM_IN_ARGUMENTS = MESSAGE(587, TRANSLATION(), ERROR(),
  Util.gettext("Different number of dimensions (%s) in arguments to %s."));
public constant Message NF_CAT_WRONG_DIMENSION = MESSAGE(588, TRANSLATION(), ERROR(),
  Util.gettext("The first argument of cat characterizes an existing dimension in the other arguments (1..%s), but got dimension %s."));
public constant Message NF_CAT_FIRST_ARG_EVAL = MESSAGE(589, TRANSLATION(), ERROR(),
  Util.gettext("The first argument of cat must be possible to evaluate during compile-time. Expression %s has variability %s."));
public constant Message COMMA_OPERATOR_DIFFERENT_SIZES = MESSAGE(590, TRANSLATION(), ERROR(),
  Util.gettext("Arguments of concatenation comma operator have different sizes for the first dimension: %s has dimension %s and %s has dimension %s."));
public constant Message NON_STATE_STATESELECT_ALWAYS = MESSAGE(591, SYMBOLIC(), WARNING(),
  Util.gettext("Variable %s has attribute stateSelect=StateSelect.always, but was selected as a continuous variable."));
public constant Message STATE_STATESELECT_NEVER = MESSAGE(592, SYMBOLIC(), WARNING(),
  Util.gettext("Variable %s has attribute stateSelect=StateSelect.never, but was selected as a state"));
public constant Message FUNCTION_HIGHER_VARIABILITY_BINDING = MESSAGE(593, TRANSLATION(), WARNING(),
  Util.gettext("Component ‘%s’ of variability %s has binding %s of higher variability %s."));
public constant Message OCG_MISSING_BRANCH = MESSAGE(594, TRANSLATION(), WARNING(),
  Util.gettext("Connections.rooted(%s) needs exactly one statement Connections.branch(%s, B.R) involving %s but we found none in the graph. Run with -d=cgraphGraphVizFile to debug"));
public constant Message UNBOUND_PARAMETER_EVALUATE_TRUE = MESSAGE(594, TRANSLATION(), WARNING(),
  Util.gettext("Parameter %s has annotation(Evaluate=true) and no binding."));
public constant Message FMI_URI_RESOLVE = MESSAGE(595, TRANSLATION(), WARNING(),
  Util.gettext("Could not resolve URI (%s) at compile-time; copying all loaded packages into the FMU"));

public constant Message MATCH_SHADOWING = MESSAGE(5001, TRANSLATION(), ERROR(),
  Util.gettext("Local variable '%s' shadows another variable."));
public constant Message META_POLYMORPHIC = MESSAGE(5002, TRANSLATION(), ERROR(),
  Util.gettext("%s uses invalid subtypeof syntax. Only subtypeof Any is supported."));
public constant Message META_FUNCTION_TYPE_NO_PARTIAL_PREFIX = MESSAGE(5003, TRANSLATION(), ERROR(),
  Util.gettext("%s is used as a function reference, but doesn't specify the partial prefix."));
public constant Message META_MATCH_EQUATION_FORBIDDEN = MESSAGE(5004, TRANSLATION(), ERROR(),
  Util.gettext("Match expression equation sections forbid the use of %s-equations."));
public constant Message META_UNIONTYPE_ALIAS_MODS = MESSAGE(5005, TRANSLATION(), ERROR(),
  Util.gettext("Uniontype %s was not generated correctly. One possible cause is modifications, which are not allowed."));
public constant Message META_COMPLEX_TYPE_MOD = MESSAGE(5006, TRANSLATION(), ERROR(),
  Util.gettext("MetaModelica complex types may not have modifiers."));
public constant Message META_CEVAL_FUNCTION_REFERENCE = MESSAGE(5008, TRANSLATION(), ERROR(),
  Util.gettext("Cannot evaluate function pointers (got %s)."));
public constant Message NON_INSTANTIATED_FUNCTION = MESSAGE(5009, TRANSLATION(), ERROR(),
  Util.gettext("Tried to use function %s, but it was not instantiated."));
public constant Message META_UNSOLVED_POLYMORPHIC_BINDINGS = MESSAGE(5010, TRANSLATION(), ERROR(),
  Util.gettext("Could not solve the polymorphism in the function call to %s\n  Input bindings:\n%s\n  Solved bindings:\n%s\n  Unsolved bindings:\n%s"));
public constant Message META_RECORD_FOUND_FAILURE = MESSAGE(5011, TRANSLATION(), ERROR(),
  Util.gettext("In record constructor %s: %s"));
public constant Message META_INVALID_PATTERN = MESSAGE(5012, TRANSLATION(), ERROR(),
  Util.gettext("Invalid pattern: %s"));
public constant Message META_MATCH_GENERAL_FAILURE = MESSAGE(5014, TRANSLATION(), ERROR(),
  Util.gettext("Failed to elaborate match expression %s"));
public constant Message META_CONS_TYPE_MATCH = MESSAGE(5015, TRANSLATION(), ERROR(),
  Util.gettext("Failed to match types of cons expression %s. The head has type %s and the tail %s."));
public constant Message META_NONE_CREF = MESSAGE(5017, TRANSLATION(), ERROR(),
  Util.gettext("NONE is not acceptable syntax. Use NONE() instead."));
public constant Message META_INVALID_PATTERN_NAMED_FIELD = MESSAGE(5018, TRANSLATION(), ERROR(),
  Util.gettext("Invalid named fields: %s. Valid field names: %s."));
public constant Message META_INVALID_LOCAL_ELEMENT = MESSAGE(5019, TRANSLATION(), ERROR(),
  Util.gettext("Only components without direction are allowed in local declarations, got: %s"));
public constant Message META_INVALID_COMPLEX_TYPE = MESSAGE(5020, TRANSLATION(), ERROR(),
  Util.gettext("Invalid complex type name: %s"));
public constant Message META_CONSTRUCTOR_NOT_PART_OF_UNIONTYPE = MESSAGE(5021, TRANSLATION(), ERROR(),
  Util.gettext("In pattern %s: %s is not part of uniontype %s"));
public constant Message META_TYPE_MISMATCH_PATTERN = MESSAGE(5022, TRANSLATION(), ERROR(),
  Util.gettext("Type mismatch in pattern %s\nexpression type:\n  %s\npattern type:\n  %s"));
public constant Message META_CONSTRUCTOR_NOT_RECORD = MESSAGE(5023, TRANSLATION(), ERROR(),
  Util.gettext("Call pattern is not a record constructor %s"));
public constant Message META_MATCHEXP_RESULT_TYPES = MESSAGE(5024, TRANSLATION(), ERROR(),
  Util.gettext("Match expression has mismatched result types:%s"));
public constant Message MATCHCONTINUE_TO_MATCH_OPTIMIZATION = MESSAGE(5025, TRANSLATION(), NOTIFICATION(),
  Util.gettext("This matchcontinue expression has no overlapping patterns and should be using match instead of matchcontinue."));
public constant Message META_DEAD_CODE = MESSAGE(5026, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Dead code elimination: %s."));
public constant Message META_UNUSED_DECL = MESSAGE(5027, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Unused local variable: %s."));
public constant Message META_UNUSED_AS_BINDING = MESSAGE(5028, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Removing unused as-binding: %s."));
public constant Message MATCH_TO_SWITCH_OPTIMIZATION = MESSAGE(5029, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Converted match expression to switch of type %s."));
public constant Message REDUCTION_TYPE_ERROR = MESSAGE(5030, TRANSLATION(), ERROR(),
  Util.gettext("Reductions require the types of the %s and %s to be %s, but got: %s and %s."));
public constant Message UNSUPPORTED_REDUCTION_TYPE = MESSAGE(5031, TRANSLATION(), ERROR(),
  Util.gettext("Expected a reduction function with type signature ('A,'B) => 'B, but got %s."));
public constant Message FOUND_NON_NUMERIC_TYPES = MESSAGE(5032, TRANSLATION(), ERROR(),
  Util.gettext("Operator %s expects numeric types as operands, but got '%s and %s'."));
public constant Message STRUCTURAL_PARAMETER_OR_CONSTANT_WITH_NO_BINDING = MESSAGE(5033, TRANSLATION(), ERROR(),
  Util.gettext("Could not evaluate structural parameter (or constant): %s which gives dimensions of array: %s. Array dimensions must be known at compile time."));
public constant Message META_UNUSED_ASSIGNMENT = MESSAGE(5034, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Removing unused assignment to: %s."));
public constant Message META_EMPTY_CALL_PATTERN = MESSAGE(5035, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Removing empty call named pattern argument: %s."));
public constant Message META_ALL_EMPTY = MESSAGE(5036, TRANSLATION(), NOTIFICATION(),
  Util.gettext("All patterns in call were empty: %s."));
public constant Message DUPLICATE_DEFINITION = MESSAGE(5037, TRANSLATION(), ERROR(),
  Util.gettext("The same variable is being defined twice: %s."));
public constant Message PATTERN_VAR_NOT_VARIABLE = MESSAGE(5038, TRANSLATION(), ERROR(),
  Util.gettext("Identifiers need to point to local or output variables. Variable %s is %s."));
public constant Message LIST_REVERSE_WRONG_ORDER = MESSAGE(5039, TRANSLATION(), NOTIFICATION(),
  Util.gettext("%1:=listAppend(%1, _) has the first argument in the \"wrong\" order.\n  It is very slow to keep appending a linked list (scales like O(N²)).\n  Consider building the list in the reverse order in order to improve performance (scales like O(N) even if you need to reverse a lot of lists). Use annotation __OpenModelica_DisableListAppendWarning=true to disable this message for a certain assignment."));
public constant Message IS_PRESENT_WRONG_SCOPE = MESSAGE(5040, TRANSLATION(), ERROR(),
  Util.gettext("isPresent needs to be called from a function scope, got %s."));
public constant Message IS_PRESENT_WRONG_DIRECTION = MESSAGE(5041, TRANSLATION(), ERROR(),
  Util.gettext("isPresent needs to be called on an input or output formal parameter."));
public constant Message IS_PRESENT_INVALID_EXP = MESSAGE(5042, TRANSLATION(), ERROR(),
  Util.gettext("isPresent needs to be called on an input or output formal parameter, but got a non-identifier expression: %s."));
public constant Message METARECORD_WITH_TYPEVARS = MESSAGE(5043, TRANSLATION(), ERROR(),
  Util.gettext("Records inside uniontypes must not contain type variables (got: %s). Put them on the uniontype instead."));
public constant Message UNIONTYPE_MISSING_TYPEVARS = MESSAGE(5044, TRANSLATION(), ERROR(),
  Util.gettext("Uniontype %s has type variables, but they were not given in the declaration."));
public constant Message UNIONTYPE_WRONG_NUM_TYPEVARS = MESSAGE(5045, TRANSLATION(), ERROR(),
  Util.gettext("Uniontype %s has %s type variables, but got %s."));
public constant Message SERIALIZED_SIZE = MESSAGE(5046, TRANSLATION(), NOTIFICATION(),
  Util.gettext("%s uses %s of memory (%s without GC overhead; %s is consumed by not performing String sharing)."));
public constant Message META_MATCH_CONSTANT = MESSAGE(5047, TRANSLATION(), NOTIFICATION(),
  Util.gettext("Match input %s is a constant value."));


public constant Message COMPILER_ERROR = MESSAGE(5999, TRANSLATION(), ERROR(),
  Util.notrans("%s"));
public constant Message COMPILER_WARNING = MESSAGE(6000, TRANSLATION(), WARNING(),
  Util.notrans("%s"));
public constant Message COMPILER_NOTIFICATION = MESSAGE(6001, TRANSLATION(), NOTIFICATION(),
  Util.notrans("%s"));
public constant Message COMPILER_NOTIFICATION_SCRIPTING = MESSAGE(6002, SCRIPTING(), NOTIFICATION(),
  Util.notrans("%s"));
public constant Message SUSAN_ERROR = MESSAGE(7000, TRANSLATION(), ERROR(),
  Util.notrans("%s"));
public constant Message TEMPLATE_ERROR = MESSAGE(7001, TRANSLATION(), ERROR(),
  Util.gettext("Template error: %s."));
public constant Message PARMODELICA_WARNING = MESSAGE(7004, TRANSLATION(), WARNING(),
  Util.notrans("ParModelica: %s."));
public constant Message PARMODELICA_ERROR = MESSAGE(7005, TRANSLATION(), ERROR(),
  Util.notrans("ParModelica: %s."));
public constant Message OPTIMICA_ERROR = MESSAGE(7006, TRANSLATION(), ERROR(),
  Util.notrans("Optimica: %s."));
public constant Message FILE_NOT_FOUND_ERROR = MESSAGE(7007, SCRIPTING(), ERROR(),
  Util.gettext("File not Found: %s."));
public constant Message UNKNOWN_FMU_VERSION = MESSAGE(7008, SCRIPTING(), ERROR(),
  Util.gettext("Unknown FMU version %s. Only version 1.0 & 2.0 are supported."));
public constant Message UNKNOWN_FMU_TYPE = MESSAGE(7009, SCRIPTING(), ERROR(),
  Util.gettext("Unknown FMU type %s. Supported types are me (model exchange), cs (co-simulation) & me_cs (model exchange & co-simulation)."));
public constant Message FMU_EXPORT_NOT_SUPPORTED = MESSAGE(7010, SCRIPTING(), ERROR(),
  Util.gettext("Export of FMU type %s for version %s is not supported. Supported combinations are me (model exchange) for versions 1.0 & 2.0, cs (co-simulation) & me_cs (model exchange & co-simulation) for version 2.0."));
// FIGARO_ERROR added by Alexander Carlqvist
public constant Message FIGARO_ERROR = MESSAGE(7011, SCRIPTING(), ERROR(),
  Util.notrans("Figaro: %s."));
public constant Message SUSAN_NOTIFY = MESSAGE(7012, TRANSLATION(), NOTIFICATION(),
  Util.notrans("%s"));
public constant Message PDEModelica_ERROR = MESSAGE(7013, TRANSLATION(), ERROR(),
  Util.gettext("PDEModelica: %s"));
public constant Message TEMPLATE_ERROR_FUNC = MESSAGE(7014, TRANSLATION(), ERROR(),
  Util.gettext("Template error: A template call failed (%s). One possible reason could be that a template imported function call failed (which should not happen for functions called from within template code; templates assert pure 'match'/non-failing semantics)."));
public constant Message FMU_EXPORT_NOT_SUPPORTED_CPP = MESSAGE(7015, SCRIPTING(), WARNING(),
  Util.gettext("Export of FMU type %s is not supported with Cpp target. FMU will be for Model Exchange (me)."));
public constant Message DEPRECATED_API_CALL = MESSAGE(7016, SCRIPTING(), WARNING(),
  Util.gettext("'%1' is deprecated. It is recommended to use '%2' instead."));
public constant Message CONFLICTING_ALIAS_SET = MESSAGE(7017, SYMBOLIC(), WARNING(),
  Util.gettext("The model contains alias variables with conflicting start and/or nominal values. It is recommended to resolve the conflicts, because otherwise the system could be hard to solve. To print the conflicting alias sets and the chosen candidates please use -d=aliasConflicts."));
public constant Message ENCRYPTION_NOT_SUPPORTED = MESSAGE(7018, SCRIPTING(), ERROR(),
  Util.gettext("File not Found: %s. Compile OpenModelica with Encryption support."));
public constant Message ENCRYPTED_FILE_NOT_FOUND_ERROR = MESSAGE(7019, SCRIPTING(), ERROR(),
  Util.gettext("No encrypted files found. Looked for %s and %s."));
public constant Message UNABLE_TO_UNZIP_FILE = MESSAGE(7020, SCRIPTING(), ERROR(),
  Util.gettext("Unable to unzip the file: %s."));
public constant Message EXPECTED_ENCRYPTED_PACKAGE = MESSAGE(7021, SCRIPTING(), ERROR(),
  Util.gettext("Expected encrypted package with .mol extension got: %s."));
public constant Message SAVE_ENCRYPTED_CLASS_ERROR = MESSAGE(7022, SCRIPTING(), ERROR(),
  Util.gettext("Cannot save the encrypted class. Encrypted classes are read-only."));
public constant Message ACCESS_ENCRYPTED_PROTECTED_CONTENTS = MESSAGE(7023, SCRIPTING(), ERROR(),
  Util.gettext("Cannot access encrypted and protected class contents."));
public constant Message INVALID_NONLINEAR_JACOBIAN_COMPONENT = MESSAGE(7024, TRANSLATION(), ERROR(),
  Util.gettext("Jacobian %s contains non-linear components. This indicates a singular system or internal generation errors."));


protected

import ErrorExt;
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
  input T cpre; // Should be Prefix.ComponentPrefix
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
  input Message inErrorMsg;
  input MessageTokens inMessageTokens;
protected
  MessageType msg_type;
  Severity severity;
  String str, msg_str, file;
  ErrorID error_id,sline,scol,eline,ecol;
  Boolean isReadOnly;
  Util.TranslatableContent msg;
algorithm
  if not Flags.getConfigBool(Flags.DEMO_MODE) then
    (str,sline,scol,eline,ecol,isReadOnly,file) := getCurrentComponent();
    //print(" adding message: " + intString(error_id) + "\n");
    MESSAGE(error_id, msg_type, severity, msg) := inErrorMsg;
    msg_str := Util.translateContent(msg);
    ErrorExt.addSourceMessage(error_id, msg_type, severity, sline, scol, eline, ecol, isReadOnly, Util.testsuiteFriendly(file), str+msg_str, inMessageTokens);
    //print(" succ add " + msg_type_str + " " + severity_string + ",  " + msg + "\n");
  end if;
end addMessage;

public function addSourceMessage "
  Adds a message given ID, tokens and source file info.
  The rest of the info is looked up in the message table."
  input Message inErrorMsg;
  input MessageTokens inMessageTokens;
  input SourceInfo inInfo;
algorithm
  _ := match (inErrorMsg,inMessageTokens,inInfo)
    local
      MessageType msg_type;
      Severity severity;
      String msg_str,file;
      ErrorID error_id,sline,scol,eline,ecol;
      MessageTokens tokens;
      Boolean isReadOnly;
      Util.TranslatableContent msg;
    case (MESSAGE(error_id, msg_type, severity, msg), tokens,
        SOURCEINFO(fileName = file,isReadOnly = isReadOnly,
          lineNumberStart = sline, columnNumberStart = scol,
          lineNumberEnd = eline,columnNumberEnd = ecol))
      equation
        msg_str = Util.translateContent(msg);
        ErrorExt.addSourceMessage(error_id, msg_type, severity, sline, scol,
          eline, ecol, isReadOnly, Util.testsuiteFriendly(file), msg_str, tokens);
      then ();
  end match;
end addSourceMessage;

public function addSourceMessageAndFail
  "Same as addSourceMessage, but fails after adding the error."
  input Message inErrorMsg;
  input MessageTokens inMessageTokens;
  input SourceInfo inInfo;
algorithm
  addSourceMessage(inErrorMsg, inMessageTokens, inInfo);
  fail();
end addSourceMessageAndFail;

public function addMultiSourceMessage
  "Adds an error message given the message, token and a list of file info. The
   the last file info in the list is used for the message itself, the rest of the
   file infos are used to print a trace of where the error came from."
  input Message inErrorMsg;
  input MessageTokens inMessageTokens;
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
  input Message inErrorMsg;
  input MessageTokens inMessageTokens;
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
  input TotalMessage message;
protected
  Message msg;
  SourceInfo info;
algorithm
  TOTALMESSAGE(msg = msg, info = info) := message;
  addSourceMessage(msg, {}, info);
end addTotalMessage;

function addTotalMessages
  input list<TotalMessage> messages;
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
  input MessageType inMessageType;
  output list<String> outStringLst;
algorithm
  outStringLst := match (inMessageType)
    case (_) then {"Not impl. yet"};
  end match;
end printMessagesStrLstType;

public function printMessagesStrLstSeverity "Returns all messages as a list of strings, one for each message.
  Filters out messages of certain severity"
  input Severity inSeverity;
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
  output list<TotalMessage> res;
algorithm
  res := ErrorExt.getMessages();
end getMessages;

public function getMessagesStrType "
  Return all messages in a matrix format, vector of strings for each
  message, written out as a string.
  Filtered by a specific MessageType."
  input MessageType inMessageType;
  output String outString;
algorithm
  outString := "not impl yet.";
end getMessagesStrType;

public function getMessagesStrSeverity "
  Return all messages in a matrix format, vector of strings for each
  message, written out as a string.
  Filtered by a specific MessageType."
  input Severity inSeverity;
  output String outString;
algorithm
  outString := "not impl yet.";
end getMessagesStrSeverity;

public function messageTypeStr "
  Converts a MessageType to a string."
  input MessageType inMessageType;
  output String outString;
algorithm
  outString := match(inMessageType)
    case (SYNTAX()) then "SYNTAX";
    case (GRAMMAR()) then "GRAMMAR";
    case (TRANSLATION()) then "TRANSLATION";
    case (SYMBOLIC()) then "SYMBOLIC";
    case (SIMULATION()) then "SIMULATION";
    case (SCRIPTING()) then "SCRIPTING";
  end match;
end messageTypeStr;

public function severityStr "
  Converts a Severity to a string."
  input Severity inSeverity;
  output String outString;
algorithm
  outString := match(inSeverity)
    case (INTERNAL()) then "Internal error";
    case (ERROR()) then "Error";
    case (WARNING()) then "Warning";
    case (NOTIFICATION()) then "Notification";
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
          info_str = "[" + Util.testsuiteFriendly(filename) + ":" +
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
  input Message inErrorMsg;
  input MessageTokens inMessageTokens;
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
  input Message inMessage;
algorithm
  _ := match(inMessage)
    case MESSAGE(severity=ERROR()) then fail();
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
  if Config.getRunningTestsuite() then
    SOURCEINFO(fileName=filename):=info;
    addSourceMessage(INTERNAL_ERROR, {message}, SOURCEINFO(filename,false,0,0,0,0,0));
  else
    addSourceMessage(INTERNAL_ERROR, {message}, info);
  end if;
end addInternalError;

annotation(__OpenModelica_Interface="util");
end Error;

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

encapsulated package Error
"
  file:        Error.mo
  package:     Error
  description: Error handling

  RCS: $Id$

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


public
uniontype Severity "severity of message"
  record ERROR "Error when tool can not succed in translation" end ERROR;

  record WARNING "Warning when tool succeds but with warning" end WARNING;

  record NOTIFICATION "Additional information to user, e.g. what
             actions tool has taken to succed in translation" end NOTIFICATION;
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
    String message;
  end MESSAGE;
end Message;

public
uniontype TotalMessage
  record TOTALMESSAGE
    Message msg;
    Absyn.Info info;
  end TOTALMESSAGE;
end TotalMessage;

public
type MessageTokens = list<String>   "\"Tokens\" to insert into message at
            positions identified by
            - %s for string
            - %n for string number n" ;

public import Absyn;

public constant Message SYNTAX_ERROR = MESSAGE(1, SYNTAX(), ERROR(),
  "Syntax error near: %s");
public constant Message GRAMMATIC_ERROR = MESSAGE(2, GRAMMAR(), ERROR(),
  "%s");
public constant Message LOOKUP_ERROR = MESSAGE(3, TRANSLATION(), ERROR(),
  "Class %s not found in scope %s.");
public constant Message LOOKUP_ERROR_COMPNAME = MESSAGE(4, TRANSLATION(), ERROR(),
  "Class %s not found in scope %s while instantiating %s.");
public constant Message LOOKUP_VARIABLE_ERROR = MESSAGE(5, TRANSLATION(), ERROR(),
  "Variable %s not found in scope %s");
public constant Message ASSIGN_CONSTANT_ERROR = MESSAGE(6, TRANSLATION(), ERROR(),
  "Trying to assign to constant component in %s := %s");
public constant Message ASSIGN_PARAM_ERROR = MESSAGE(7, TRANSLATION(), ERROR(),
  "Trying to assign to parameter component in %s := %s");
public constant Message ASSIGN_READONLY_ERROR = MESSAGE(8, TRANSLATION(), ERROR(),
  "Trying to assign to %s component %s");
public constant Message ASSIGN_TYPE_MISMATCH_ERROR = MESSAGE(9, TRANSLATION(), ERROR(),
  "Type mismatch in assignment in %s := %s of %s := %s");
public constant Message IF_CONDITION_TYPE_ERROR = MESSAGE(10, TRANSLATION(), ERROR(),
  "Type error in conditional ( %s). Expected Boolean, got %s.");
public constant Message FOR_EXPRESSION_TYPE_ERROR = MESSAGE(11, TRANSLATION(), ERROR(),
  "Type error in for expression (%s). Expected array got %s.");
public constant Message WHEN_CONDITION_TYPE_ERROR = MESSAGE(12, TRANSLATION(), ERROR(),
  "Type error in when conditional (%s). Expected Boolean scalar or vector, got %s.");
public constant Message WHILE_CONDITION_TYPE_ERROR = MESSAGE(13, TRANSLATION(), ERROR(),
  "Type error in while conditional (%s). Expected Boolean got %s.");
public constant Message END_ILLEGAL_USE_ERROR = MESSAGE(14, TRANSLATION(), ERROR(),
  "'end' can not be used outside array subscripts.");
public constant Message DIVISION_BY_ZERO = MESSAGE(15, TRANSLATION(), ERROR(),
  "Division by zero in %s / %s");
public constant Message MODULO_BY_ZERO = MESSAGE(16, TRANSLATION(), ERROR(),
  "Modulo by zero in mod(%s,%s)");
public constant Message REM_ARG_ZERO = MESSAGE(17, TRANSLATION(), ERROR(),
  "Second argument in rem is zero in rem(%s,%s)");
public constant Message SCRIPT_READ_SIM_RES_ERROR = MESSAGE(18, SCRIPTING(), ERROR(),
  "Error reading simulation result.");
public constant Message SCRIPT_READ_SIM_RES_SIZE_ERROR = MESSAGE(19, SCRIPTING(), ERROR(),
  "Error reading simulation result size");
public constant Message LOAD_MODEL_ERROR = MESSAGE(20, TRANSLATION(), ERROR(),
  "Class %s not found");
public constant Message WRITING_FILE_ERROR = MESSAGE(21, SCRIPTING(), ERROR(),
  "Error writing to file %s.");
public constant Message SIMULATOR_BUILD_ERROR = MESSAGE(22, TRANSLATION(), ERROR(),
  "Error building simulator. Buildlog: %s");
public constant Message DIMENSION_NOT_KNOWN = MESSAGE(23, TRANSLATION(), ERROR(),
  "Dimensions must be parameter or constant expression (in %s).");
public constant Message UNBOUND_VALUE = MESSAGE(24, TRANSLATION(), ERROR(),
  "Variable %s has no value.");
public constant Message NEGATIVE_SQRT = MESSAGE(25, TRANSLATION(), ERROR(),
  "Negative value as argument to sqrt.");
public constant Message NO_CONSTANT_BINDING = MESSAGE(26, TRANSLATION(), ERROR(),
  "No constant value for variable %s in scope %s.");
public constant Message TYPE_NOT_FROM_PREDEFINED = MESSAGE(27, TRANSLATION(), ERROR(),
  "In class %s, class restriction 'type' can only be derived from predefined types.");
public constant Message UNKNOWN_EXTERNAL_LANGUAGE = MESSAGE(30, TRANSLATION(), ERROR(),
  "Unknown external language %s in external function declaration");
public constant Message DIFFERENT_NO_EQUATION_IF_BRANCHES = MESSAGE(31, TRANSLATION(), ERROR(),
  "Different number of equations in the branches of the if equation: %s");
public constant Message UNDERDET_EQN_SYSTEM = MESSAGE(32, SYMBOLIC(), ERROR(),
  "Too few equations, underdetermined system. The model has %s equation(s) and %s variable(s)");
public constant Message OVERDET_EQN_SYSTEM = MESSAGE(33, SYMBOLIC(), ERROR(),
  "Too many equations, overdetermined system. The model has %s equation(s) and %s variable(s)");
public constant Message STRUCT_SINGULAR_SYSTEM = MESSAGE(34, SYMBOLIC(), ERROR(),
  "Model is structurally singular, error found sorting equations %s for variables %s");
public constant Message UNSUPPORTED_LANGUAGE_FEATURE = MESSAGE(35, TRANSLATION(), ERROR(),
  "The language feature %s is not supported. Suggested workaround: %s");
public constant Message NON_EXISTING_DERIVATIVE = MESSAGE(36, SYMBOLIC(), ERROR(),
  "Derivative of expression %s is non-existent");
public constant Message NO_CLASSES_LOADED = MESSAGE(37, TRANSLATION(), ERROR(),
  "No classes are loaded.");
public constant Message INST_PARTIAL_CLASS = MESSAGE(38, TRANSLATION(), ERROR(),
  "Illegal to instantiate partial class %s");
public constant Message LOOKUP_BASECLASS_ERROR = MESSAGE(39, TRANSLATION(), ERROR(),
  "Base class %s not found in scope %s");
public constant Message REDECLARE_CLASS_AS_VAR = MESSAGE(40, TRANSLATION(), ERROR(),
  "Trying to redeclare the class %s as a variable");
public constant Message REDECLARE_NON_REPLACEABLE = MESSAGE(41, TRANSLATION(), ERROR(),
  "Trying to redeclare %1 %2 but %1 not declared as replaceable");
public constant Message COMPONENT_INPUT_OUTPUT_MISMATCH = MESSAGE(42, TRANSLATION(), ERROR(),
  "Component declared as %s when having the variable %s declared as %s");
public constant Message ARRAY_DIMENSION_MISMATCH = MESSAGE(43, TRANSLATION(), ERROR(),
  "Array dimension mismatch, expression %s has type %s, expected array dimensions [%s]");
public constant Message ARRAY_DIMENSION_INTEGER = MESSAGE(44, TRANSLATION(), ERROR(),
  "Array dimension must be integer expression in %s which has type %s");
public constant Message EQUATION_TYPE_MISMATCH_ERROR = MESSAGE(45, TRANSLATION(), ERROR(),
  "Type mismatch in equation %s of type %s");
public constant Message INST_ARRAY_EQ_UNKNOWN_SIZE = MESSAGE(46, TRANSLATION(), ERROR(),
  "Array equation has unknown size in %s");
public constant Message TUPLE_ASSIGN_FUNCALL_ONLY = MESSAGE(47, TRANSLATION(), ERROR(),
  "Tuple assignment only allowed when rhs is function call (in %s)");
public constant Message INVALID_CONNECTOR_TYPE = MESSAGE(48, TRANSLATION(), ERROR(),
  "Cannot connect objects of type %s, not a connector.");
public constant Message CONNECT_TWO_INPUTS = MESSAGE(49, TRANSLATION(), ERROR(),
  "Cannot connect two input variables while connecting %s to %s unless one of them is inside and the other outside connector.");
public constant Message CONNECT_TWO_OUTPUTS = MESSAGE(50, TRANSLATION(), ERROR(),
  "Cannot connect two output variables while connecting %s to %s unless one of them is inside and the other outside connector.");
public constant Message CONNECT_FLOW_TO_NONFLOW = MESSAGE(51, TRANSLATION(), ERROR(),
  "Cannot connect flow component %s to non-flow component %s");
public constant Message INVALID_CONNECTOR_VARIABLE = MESSAGE(52, TRANSLATION(), ERROR(),
  "The type of variables %s (%s) are inconsistent in connect equations");
public constant Message TYPE_ERROR = MESSAGE(53, TRANSLATION(), ERROR(),
  "Wrong type on %s, expected %s");
public constant Message MODIFY_PROTECTED = MESSAGE(54, TRANSLATION(), ERROR(),
  "Attempt to modify protected element %s");
public constant Message INVALID_TUPLE_CONTENT = MESSAGE(55, TRANSLATION(), ERROR(),
  "Tuple %s  must contain component references only");
public constant Message IMPORT_PACKAGES_ONLY = MESSAGE(56, TRANSLATION(), ERROR(),
  "%s is not a package, imports is only allowed for packages.");
public constant Message IMPORT_SEVERAL_NAMES = MESSAGE(57, TRANSLATION(), ERROR(),
  "%s found in several unqualified import statements.");
public constant Message LOOKUP_TYPE_FOUND_COMP = MESSAGE(58, TRANSLATION(), ERROR(),
  "Found a component with same name when looking for type %s");
public constant Message LOOKUP_ENCAPSULATED_RESTRICTION_VIOLATION = MESSAGE(59, TRANSLATION(), ERROR(),
  "Lookup is restricted to encapsulated elements only, violated in %s");
public constant Message REFERENCE_PROTECTED = MESSAGE(60, TRANSLATION(), ERROR(),
  "Attempt to reference protected element %s");
public constant Message ILLEGAL_SLICE_MOD = MESSAGE(61, TRANSLATION(), ERROR(),
  "Illegal slice modification %s");
public constant Message ILLEGAL_MODIFICATION = MESSAGE(62, TRANSLATION(), ERROR(),
  "Illegal modification %s (of %s)");
public constant Message INTERNAL_ERROR = MESSAGE(63, TRANSLATION(), ERROR(),
  "Internal error %s");
public constant Message TYPE_MISMATCH_ARRAY_EXP = MESSAGE(64, TRANSLATION(), ERROR(),
  "Type mismatch in array expression in component %s. %s is of type %s while the elements %s are of type %s");
public constant Message TYPE_MISMATCH_MATRIX_EXP = MESSAGE(65, TRANSLATION(), ERROR(),
  "Type mismatch in matrix rows in component %s. %s is a row of %s, the rest of the matrix is of type %s");
public constant Message MATRIX_EXP_ROW_SIZE = MESSAGE(66, TRANSLATION(), ERROR(),
  "Incompatible row length in matrix expression in component %s. %s is a row of size %s, the rest of the matrix rows are of size %s");
public constant Message OPERAND_BUILTIN_TYPE = MESSAGE(67, TRANSLATION(), ERROR(),
  "Operand of %s in component %s must be builtin-type in %s");
public constant Message WRONG_TYPE_OR_NO_OF_ARGS = MESSAGE(68, TRANSLATION(), ERROR(),
  "Wrong type or wrong number of arguments to %s (in component %s)");
public constant Message DIFFERENT_DIM_SIZE_IN_ARGUMENTS = MESSAGE(69, TRANSLATION(), ERROR(),
  "Different dimension sizes in arguments to %s in component %s");
public constant Message DER_APPLIED_TO_CONST = MESSAGE(70, TRANSLATION(), ERROR(),
  "der operator applied to constant expression der(%s)");
public constant Message ARGUMENT_MUST_BE_INTEGER_OR_REAL = MESSAGE(71, TRANSLATION(), ERROR(),
  "%s argument to %s in component %s must be Integer or Real expression");
public constant Message ARGUMENT_MUST_BE_INTEGER = MESSAGE(72, TRANSLATION(), ERROR(),
  "%s argument to %s in component %s must be Integer expression");
public constant Message ARGUMENT_MUST_BE_DISCRETE_VAR = MESSAGE(73, TRANSLATION(), ERROR(),
  "%s argument to %s in component %s must be discrete variable");
public constant Message TYPE_MUST_BE_SIMPLE = MESSAGE(74, TRANSLATION(), ERROR(),
  "Type in %s must be simple type in component %s");
public constant Message ARGUMENT_MUST_BE_VARIABLE = MESSAGE(75, TRANSLATION(), ERROR(),
  "%s argument to %s in component %s must be a variable");
public constant Message NO_MATCHING_FUNCTION_FOUND = MESSAGE(76, TRANSLATION(), ERROR(),
  "No matching function found for %s in component %s
candidates are %s");
public constant Message NO_MATCHING_FUNCTION_FOUND_NO_CANDIDATE = MESSAGE(77, TRANSLATION(), ERROR(),
  "No matching function found for %s");
public constant Message FUNCTION_COMPS_MUST_HAVE_DIRECTION = MESSAGE(78, TRANSLATION(), ERROR(),
  "Component %s in function is neither input nor output");
public constant Message FUNCTION_SLOT_ALLREADY_FILLED = MESSAGE(79, TRANSLATION(), ERROR(),
  "Slot %s already filled in a function call in component %s");
public constant Message NO_SUCH_ARGUMENT = MESSAGE(80, TRANSLATION(), ERROR(),
  "No such argument %s in component %s");
public constant Message CONSTANT_OR_PARAM_WITH_NONCONST_BINDING = MESSAGE(81, TRANSLATION(), ERROR(),
  "%s is a constant or parameter with a non-constant initializer %s");
public constant Message SUBSCRIPT_NOT_INT_OR_INT_ARRAY = MESSAGE(82, TRANSLATION(), ERROR(),
  "Subscript is not an integer or integer array in %s which is of type %s, in component: %s");
public constant Message TYPE_MISMATCH_IF_EXP = MESSAGE(83, TRANSLATION(), ERROR(),
  "Type mismatch in if-expression in component %s. True branch: %s has type %s,  false branch: %s has type %s");
public constant Message UNRESOLVABLE_TYPE = MESSAGE(84, TRANSLATION(), ERROR(),
  "Cannot resolve type of expression %s in component %s");
public constant Message INCOMPATIBLE_TYPES = MESSAGE(85, TRANSLATION(), ERROR(),
  "Incompatible argument types to operation %s in component %s, left type: %s, right type: %s");
public constant Message ERROR_OPENING_FILE = MESSAGE(86, TRANSLATION(), ERROR(),
  "Error opening file %s");
public constant Message INHERIT_BASIC_WITH_COMPS = MESSAGE(87, TRANSLATION(), ERROR(),
  "Class %s inherits primary type but has components");
public constant Message MODIFIER_TYPE_MISMATCH_ERROR = MESSAGE(88, TRANSLATION(), ERROR(),
  "Type mismatch in modifier of component %s, expected type %s, got modifier %s of type %s");
public constant Message ERROR_FLATTENING = MESSAGE(89, TRANSLATION(), ERROR(),
  "Error occured while flattening model %s");
public constant Message DUPLICATE_ELEMENTS_NOT_IDENTICAL = MESSAGE(90, TRANSLATION(), ERROR(),
  "Duplicate elements (due to inherited elements) not identical:
	first element is:  %s
	second element is: %s");
public constant Message PACKAGE_VARIABLE_NOT_CONSTANT = MESSAGE(91, TRANSLATION(), ERROR(),
  "Variable %s in package %s is not constant");
public constant Message RECURSIVE_DEFINITION = MESSAGE(92, TRANSLATION(), ERROR(),
  "Declaration of element %s causes recursive definition of class %s.");
public constant Message NOT_ARRAY_TYPE_IN_FOR_STATEMENT = MESSAGE(93, TRANSLATION(), ERROR(),
  "Expression %s in for-statement must be an array type");
public constant Message BREAK_OUT_OF_LOOP = MESSAGE(94, GRAMMAR(), WARNING(),
  "Break statement found inside a loop");
public constant Message DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN = MESSAGE(95, SYMBOLIC(), ERROR(),
  "The same variables must me solved in elsewhen clause as in the when clause");
public constant Message GENERIC_TRANSLATION_ERROR = MESSAGE(96, TRANSLATION(), ERROR(),
  "Error, %s");
public constant Message MODIFIER_DECLARATION_TYPE_MISMATCH_ERROR = MESSAGE(97, TRANSLATION(), ERROR(),
  "Type mismatch in modifier of component %s, declared type %s, got modifier %s of type %s");
public constant Message ASSERT_CONSTANT_FALSE_ERROR = MESSAGE(98, SYMBOLIC(), ERROR(),
  "Assertion triggered during translation: %s");
public constant Message ARRAY_INDEX_OUT_OF_BOUNDS = MESSAGE(99, TRANSLATION(), ERROR(),
  "Index out of bounds. Adressing position: %s, while array length is: %s");
public constant Message COMPONENT_CONDITION_VARIABILITY = MESSAGE(100, TRANSLATION(), ERROR(),
  "Component condition must be parameter or constant expression (in %s).");
public constant Message SELF_REFERENCE_EQUATION = MESSAGE(101, TRANSLATION(), WARNING(),
  "Circular reference with variable \"%s\"");
public constant Message DUPLICATE_MODIFICATIONS = MESSAGE(103, TRANSLATION(), ERROR(),
  "Duplicate modifications in %s");
public constant Message ILLEGAL_SUBSCRIPT = MESSAGE(104, TRANSLATION(), ERROR(),
  "Illegal subscript %s for dimensions %s in component %s");
public constant Message ILLEGAL_EQUATION_TYPE = MESSAGE(105, TRANSLATION(), ERROR(),
  "Illegal type in equation %s, only builtin types (Real, String, Integer, Boolean or enumeration) or record type allowed in equation.");
public constant Message ASSERT_FAILED = MESSAGE(106, TRANSLATION(), ERROR(),
  "Assertion failed in function, message: %s ");
public constant Message WARNING_IMPORT_PACKAGES_ONLY = MESSAGE(107, TRANSLATION(), WARNING(),
  "%s is not a package, imports is only allowed for packages.");
public constant Message MISSING_INNER_PREFIX = MESSAGE(108, TRANSLATION(), WARNING(),
  "No corresponding 'inner' declaration found for component %s declared as '%s'.
  The existing 'inner' components are: 
    %s
  Check if you have not misspelled the 'outer' component name.
  Please declare an 'inner' component with the same name in the top scope.
  Continuing flattening by only considering the 'outer' component declaration.");
public constant Message CONNECT_STREAM_TO_NONSTREAM = MESSAGE(109, TRANSLATION(), ERROR(),
  "Cannot connect stream component %s to non-stream component %s");
public constant Message IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY = MESSAGE(110, TRANSLATION(), ERROR(),
  "Identificator %s of implicit for iterator must be present as array subscript in the loop body.");
public constant Message STRUCT_SINGULAR_SYSTEM_INITIALIZATION = MESSAGE(111, TRANSLATION(), ERROR(),
  "The initialization problem of model is structurally singular, error found sorting equations %s for variables %s");
public constant Message CIRCULAR_EQUATION = MESSAGE(112, TRANSLATION(), ERROR(),
  " Equation : '%s'  has circular references for variable %s.");
public constant Message IF_EQUATION_NO_ELSE = MESSAGE(113, TRANSLATION(), ERROR(),
  "In equation %s. If-equation with conditions that are not parameter expressions must have an else branch, in equation.");
public constant Message IF_EQUATION_UNBALANCED = MESSAGE(114, TRANSLATION(), ERROR(),
  "In equation %s. If-equation with conditions that are not parameter expressions must have the same number of equations in each branch, equation count is %s for each respective branch.");
public constant Message LINSPACE_ILLEGAL_SIZE_ARG = MESSAGE(115, TRANSLATION(), ERROR(),
  "In expression %s, third argument to linspace must be >= 2");
public constant Message STRUCT_SINGULAR_SYSTEM_CONNECTORS = MESSAGE(116, SYMBOLIC(), WARNING(),
  "Model is structurally singular, the following connectors are not connected from the outside: %s");
public constant Message CONNECT_INCOMPATIBLE_TYPES = MESSAGE(117, TRANSLATION(), ERROR(),
  "Incompatible components in connect statement: connect(%s, %s)
- %s has components %s
- %s has components %s");
public constant Message CONNECT_OUTER_OUTER = MESSAGE(118, TRANSLATION(), ERROR(),
  "Illegal connecting two outer connectors in statement connect(%s, %s)");
public constant Message CONNECTOR_ARRAY_NONCONSTANT = MESSAGE(119, TRANSLATION(), ERROR(),
  "in statement %s, subscript %s is not a parameter or constant");
public constant Message CONNECTOR_ARRAY_DIFFERENT = MESSAGE(120, TRANSLATION(), ERROR(),
  "Unmatched dimension in equation connect(%s, %s)");
public constant Message MODIFIER_NON_ARRAY_TYPE_WARNING = MESSAGE(121, TRANSLATION(), WARNING(),
  "Non-array modification '%s' for array component, possibly due to missing 'each'.
");
public constant Message BUILTIN_VECTOR_INVALID_DIMENSIONS = MESSAGE(122, TRANSLATION(), ERROR(),
  "In scope %s, in component %s: Invalid dimensions %s in %s, no more than one dimension may have size > 1.");
public constant Message UNROLL_LOOP_CONTAINING_WHEN = MESSAGE(123, TRANSLATION(), ERROR(),
  "Unable to unroll for loop containing when statements or equations: %s
");
public constant Message CIRCULAR_PARAM = MESSAGE(124, TRANSLATION(), ERROR(),
  " Variable '%s' has a cyclic dependency and has variability %s.");
public constant Message NESTED_WHEN = MESSAGE(125, TRANSLATION(), ERROR(),
  "Nested when statements are not allowed.");
public constant Message INVALID_ENUM_LITERAL = MESSAGE(126, TRANSLATION(), ERROR(),
  "Invalid use of reserved attribute name %s as enumeration literal.");
public constant Message UNEXCPECTED_FUNCTION_INPUTS_WARNING = MESSAGE(127, TRANSLATION(), WARNING(),
  "Function %s has not the expected inputs. Expected inputs are %s.");
public constant Message DUPLICATE_CLASSES_NOT_EQUIVALENT = MESSAGE(128, TRANSLATION(), ERROR(),
  "Duplicate class definitions (due to inheritance) not equivalent, first definiton is: %s, second definition is: %s");
public constant Message HIGHER_VARIABILITY_BINDING = MESSAGE(129, TRANSLATION(), ERROR(),
  "Component %s of variability %s has binding %s of higher variability %s.");
public constant Message STRUCT_SINGULAR_EQUATION = MESSAGE(130, SYMBOLIC(), ERROR(),
  "Model is structurally singular in equation %s.");
public constant Message IF_EQUATION_WARNING = MESSAGE(131, SYMBOLIC(), WARNING(),
  "If-equations are only partially supported. Ignoring %s");
public constant Message IF_EQUATION_UNBALANCED_2 = MESSAGE(132, SYMBOLIC(), ERROR(),
  "If-equation with conditions that are not parameter expressions must have the same number of equations in each branch, equation count is %s for each respective branch.");
public constant Message EQUATION_GENERIC_FAILURE = MESSAGE(133, TRANSLATION(), ERROR(),
  "Failed to instantiate equation %s");
public constant Message INST_PARTIAL_CLASS_CHECK_MODEL_WARNING = MESSAGE(134, TRANSLATION(), WARNING(),
  "Forcing full instantiation of partial class %s during checkModel.");
public constant Message VARIABLE_BINDING_TYPE_MISMATCH = MESSAGE(135, TRANSLATION(), ERROR(),
  "Type mismatch in binding %s = %s, expected subtype of %s, got type %s.");
public constant Message COMPONENT_NAME_SAME_AS_TYPE_NAME = MESSAGE(136, GRAMMAR(), WARNING(),
  "Component %s has the same name as its type %s.
	This is forbidden by Modelica specification and may lead to lookup errors.");
public constant Message MODIFICATION_INDEX_OVERLAP = MESSAGE(137, TRANSLATION(), WARNING(),
  "Index modifications: %s for array component: %s are overlapping. 
	The final bindings will be set by the last modifications given for the same index.");
public constant Message MODIFICATION_AND_MODIFICATION_INDEX_OVERLAP = MESSAGE(138, TRANSLATION(), WARNING(),
  "Index modifications: %s are overlapping with array binding modification %s for array component: %s. 
	The final bindings will be set by the last index modification given for the same index.");
public constant Message MODIFICATION_OVERLAP = MESSAGE(139, TRANSLATION(), WARNING(),
  "Modifications: %s for component: %s are overlapping. 
	The final bindings will be set by the first modification.");
public constant Message MODIFICATION_INDEX_NOT_FOUND = MESSAGE(140, TRANSLATION(), ERROR(),
  "Instantiation of array component: %s failed because index modification: %s is invalid. 
	Array component: %s has more dimensions than binding %s.");
public constant Message DUPLICATE_MODIFICATIONS_WARNING = MESSAGE(141, TRANSLATION(), WARNING(),
  "Duplicate modifications for attribute: %s in modifier: %s. 
	Considering only the first modification: %s and ignoring the rest %s.");
public constant Message GENERATECODE_INVARS_HAS_FUNCTION_PTR = MESSAGE(142, SYMBOLIC(), ERROR(),
  "%s has a function pointer as input. OpenModelica does not support this feature in the interactive environment. Suggested workaround: Call this function with the arguments you want from another function (that does not have function pointer input). Then call that function from the interactive environment instead.");
public constant Message LOOKUP_COMP_FOUND_TYPE = MESSAGE(143, TRANSLATION(), WARNING(),
  "Found a type with same name when looking for component %s");
public constant Message DUPLICATE_ELEMENTS_NOT_SYNTACTICALLY_IDENTICAL = MESSAGE(144, TRANSLATION(), WARNING(),
  "Duplicate elements (due to inherited elements) not syntactically identical but semantically identical:
	first element is:  %s	second element is: %s	Modelica specification requires that elements are exactly identical.");
public constant Message GENERIC_INST_FUNCTION = MESSAGE(145, TRANSLATION(), ERROR(),
  "Failed to instantiate function %s in scope %s");
public constant Message WRONG_NO_OF_ARGS = MESSAGE(146, TRANSLATION(), ERROR(),
  "Wrong number of arguments to %s");
public constant Message TUPLE_ASSIGN_CREFS_ONLY = MESSAGE(147, TRANSLATION(), ERROR(),
  "Tuple assignment only allowed for tuple of component references in lhs (in %s)");
public constant Message LOOKUP_FUNCTION_GOT_CLASS = MESSAGE(148, TRANSLATION(), ERROR(),
  "Looking for a function %s but found a %s.");
public constant Message NON_STREAM_OPERAND_IN_STREAM_OPERATOR = MESSAGE(149, TRANSLATION(), ERROR(),
  "Operand %s to operator %s is not a stream variable.");
public constant Message UNBALANCED_CONNECTOR = MESSAGE(150, TRANSLATION(), WARNING(),
  "Connector %s is not balanced: %s");
public constant Message RESTRICTION_VIOLATION = MESSAGE(151, TRANSLATION(), ERROR(),
  "Restriction violation: %s is a %s, not a %s");
public constant Message ZERO_STEP_IN_ARRAY_CONSTRUCTOR = MESSAGE(152, TRANSLATION(), ERROR(),
  "Step equals 0 in array constructor %s.");
public constant Message RECURSIVE_SHORT_CLASS_DEFINITION = MESSAGE(153, TRANSLATION(), ERROR(),
  "Recursive short class definition of %s in terms of %s");
public constant Message FUNCTION_ELEMENT_WRONG_KIND = MESSAGE(155, TRANSLATION(), ERROR(),
  "Element is not allowed in function context: %s");
public constant Message WITHOUT_SENDDATA = MESSAGE(156, SCRIPTING(), ERROR(),
  "%s failed because OpenModelica was configured without sendData support.");
public constant Message DUPLICATE_CLASSES_TOP_LEVEL = MESSAGE(157, TRANSLATION(), ERROR(),
  "Duplicate classes on top level is not allowed (got %s).");
public constant Message WHEN_EQ_LHS = MESSAGE(158, TRANSLATION(), ERROR(),
  "Invalid left-hand side of when-equation: %s.");
public constant Message GENERIC_ELAB_EXPRESSION = MESSAGE(159, TRANSLATION(), ERROR(),
  "Failed to elaborate expression: %s");
public constant Message EXTENDS_EXTERNAL = MESSAGE(160, TRANSLATION(), WARNING(),
  "Ignoring external declaration of the extended class: %s.");
public constant Message DOUBLE_DECLARATION_OF_ELEMENTS = MESSAGE(161, TRANSLATION(), ERROR(),
  "An element with name %s is already declared in this scope.");
public constant Message INVALID_REDECLARATION_OF_CLASS = MESSAGE(162, TRANSLATION(), ERROR(),
  "Invalid redeclaration of class %s, class extends only allowed on inherited classes.");
public constant Message MULTIPLE_QUALIFIED_IMPORTS_WITH_SAME_NAME = MESSAGE(163, TRANSLATION(), ERROR(),
  "Qualified import name %s already exists in this scope.");
public constant Message EXTENDS_INHERITED_FROM_LOCAL_EXTENDS = MESSAGE(164, TRANSLATION(), ERROR(),
  "Extends %s depends on inherited element %s.");
public constant Message LOOKUP_FUNCTION_ERROR = MESSAGE(165, TRANSLATION(), ERROR(),
  "Function %s not found in scope %s.");
public constant Message ELAB_CODE_EXP_FAILED = MESSAGE(166, TRANSLATION(), ERROR(),
  "Failed to elaborate %s as a code expression of type %s.");
public constant Message EQUATION_TRANSITION_FAILURE = MESSAGE(167, TRANSLATION(), ERROR(),
  "Equations are not allowed in %s.");
public constant Message METARECORD_CONTAINS_METARECORD_MEMBER = MESSAGE(168, TRANSLATION(), ERROR(),
  "The called uniontype record (%s) contains a member (%s) that has a uniontype record as its type instead of a uniontype.");
public constant Message INVALID_EXTERNAL_OBJECT = MESSAGE(169, TRANSLATION(), ERROR(),
  "Invalid external object %s, %s.");
public constant Message CIRCULAR_COMPONENTS = MESSAGE(170, TRANSLATION(), ERROR(),
  "Cyclically dependent constants or parameters found in scope %s: %s");
public constant Message FAILURE_TO_DEDUCE_DIMS_FROM_MOD = MESSAGE(171, TRANSLATION(), WARNING(),
  "Failed to deduce dimensions of %s due to unknown dimensions of modifier %s.");
public constant Message REPLACEABLE_BASE_CLASS = MESSAGE(172, TRANSLATION(), ERROR(),
  "Base class %s is replaceable.");
public constant Message NON_REPLACEABLE_CLASS_EXTENDS = MESSAGE(173, TRANSLATION(), ERROR(),
  "Non-replaceable base class %s in class extends.");
public constant Message ERROR_FROM_HERE = MESSAGE(174, TRANSLATION(), NOTIFICATION(),
  "From here:");
public constant Message EXTERNAL_FUNCTION_RESULT_NOT_CREF = MESSAGE(175, TRANSLATION(), ERROR(),
  "The lhs (result) of the external function declaration is not a component reference: %s");
public constant Message EXTERNAL_FUNCTION_RESULT_NOT_VAR = MESSAGE(176, TRANSLATION(), ERROR(),
  "The lhs (result) of the external function declaration is not a variable");
public constant Message EXTERNAL_FUNCTION_RESULT_ARRAY_TYPE = MESSAGE(177, TRANSLATION(), ERROR(),
  "The lhs (result) of the external function declaration has array type (%s), but this is not allowed in the specification. You need to pass it as an input to the function (preferably also with a size()-expression to avoid out-of-bounds errors in the external call).");
public constant Message INVALID_REDECLARE = MESSAGE(178, TRANSLATION(), ERROR(),
  "Redeclaration of %s is not allowed.");
public constant Message INVALID_TYPE_PREFIX = MESSAGE(179, TRANSLATION(), ERROR(),
  "Invalid type prefix '%s' on variable %s, due to existing type prefix '%s'.");
public constant Message LINEAR_SYSTEM_INVALID = MESSAGE(180, SYMBOLIC(), ERROR(),
  "Linear solver (%s) returned invalid input for linear system %s.");
public constant Message LINEAR_SYSTEM_SINGULAR = MESSAGE(181, SYMBOLIC(), ERROR(),
  "When solving linear system %1
  U(%2,%2) = 0.0, which means system is singular for variable %3.");
public constant Message EMPTY_ARRAY = MESSAGE(182, TRANSLATION(), ERROR(),
  "Array constructor may not be empty.");
public constant Message LOAD_MODEL_DIFFERENT_VERSIONS = MESSAGE(183, SCRIPTING(), WARNING(),
  "Requested package %s of version %s, but this package was already loaded with version %s. You might experience problems if these versions are incompatible.");
public constant Message LOAD_MODEL = MESSAGE(184, SCRIPTING(), ERROR(),
  "Failed to load package %s (%s) using MODELICAPATH %s.");
public constant Message INVALID_ARGUMENT_TYPE = MESSAGE(185, TRANSLATION(), ERROR(),
  "Argument %s of %s must be %s");
public constant Message INVALID_SIZE_INDEX = MESSAGE(186, TRANSLATION(), ERROR(),
  "Invalid index %s in call to size of %s, valid index interval is [1,%s].");
public constant Message ALGORITHM_TRANSITION_FAILURE = MESSAGE(187, TRANSLATION(), ERROR(),
  "Algorithm section is not allowed in %s.");
public constant Message FAILURE_TO_DEDUCE_DIMS_NO_MOD = MESSAGE(188, TRANSLATION(), ERROR(),
  "Failed to deduce dimensions of %s due to missing binding equation.");
public constant Message FUNCTION_MULTIPLE_ALGORITHM = MESSAGE(189, TRANSLATION(), WARNING(),
  "The behaviour of multiple algorithm sections in function %s is not standard Modelica. OpenModelica will execute the sections in the order in which they were declared or inherited (same ordering as inherited input/output arguments, which also are not standardized).");
public constant Message STATEMENT_GENERIC_FAILURE = MESSAGE(190, TRANSLATION(), ERROR(),
  "Failed to instantiate statement:
%s");
public constant Message EXTERNAL_NOT_SINGLE_RESULT = MESSAGE(191, TRANSLATION(), ERROR(),
  "%s is an unbound output in external function %s. Either add it to the external declaration or add a default binding.");
public constant Message FUNCTION_UNUSED_INPUT = MESSAGE(192, SYMBOLIC(), WARNING(),
  "Unused input variable %s in function %s.");
public constant Message ARRAY_TYPE_MISMATCH = MESSAGE(193, TRANSLATION(), ERROR(),
  "Array types mismatch: %s and %s.");
public constant Message VECTORIZE_TWO_UNKNOWN = MESSAGE(194, TRANSLATION(), ERROR(),
  "Could not vectorize call with unknown dimensions due to finding two foreach arguments: %s and %s.");
public constant Message FUNCTION_SLOT_VARIABILITY = MESSAGE(195, TRANSLATION(), ERROR(),
  "Function argument %s=%s is not a %sexpression");
public constant Message INVALID_ARRAY_DIM_IN_CONVERSION_OP = MESSAGE(196, TRANSLATION(), ERROR(),
  "Invalid dimension %s of argument to %s, expected dimension size %s but got %s.");
public constant Message DUPLICATE_REDECLARATION = MESSAGE(197, TRANSLATION(), ERROR(),
  "%s is already redeclared in this scope.");
public constant Message INVALID_FUNCTION_VAR_TYPE = MESSAGE(198, TRANSLATION(), ERROR(),
  "Invalid type %s for function component %s.");
public constant Message IMBALANCED_EQUATIONS = MESSAGE(199, SYMBOLIC(), ERROR(),
  "An independent subset of the model has imbalanced number of equations (%s) and variables (%s).
variables:
%s
equations:
%s");
public constant Message EQUATIONS_VAR_NOT_DEFINED = MESSAGE(200, SYMBOLIC(), ERROR(),
  "Variable %s is not referenced in any equation (possibly after symbolic manipulations).");
public constant Message NON_FORMAL_PUBLIC_FUNCTION_VAR = MESSAGE(201, TRANSLATION(), WARNING(),
  "Invalid public variable %s, function variables that are not input/output must be protected.");
public constant Message PROTECTED_FORMAL_FUNCTION_VAR = MESSAGE(202, TRANSLATION(), ERROR(),
  "Invalid protected formal parameter %s, formal arguments must be public.");
public constant Message UNFILLED_SLOT = MESSAGE(203, TRANSLATION(), ERROR(),
  "Function argument %s was not given by the function call, and does not have a default value.");
public constant Message UNBOUND_PARAMETER_WITH_START_VALUE_WARNING = MESSAGE(499, TRANSLATION(), WARNING(),
  "Parameter %s has no value, and is fixed during initialization (fixed=true), using available start value (start=%s) as default value");
public constant Message UNBOUND_PARAMETER_WARNING = MESSAGE(500, TRANSLATION(), WARNING(),
  "Parameter %s has neither value nor start value, and is fixed during initialization (fixed=true)");
public constant Message BUILTIN_FUNCTION_SUM_HAS_SCALAR_PARAMETER = MESSAGE(501, TRANSLATION(), WARNING(),
  "Function \"sum\" has scalar as argument in %s in component %s");
public constant Message BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER = MESSAGE(502, TRANSLATION(), WARNING(),
  "Function \"product\" has scalar as argument in %s in component %s");
public constant Message SETTING_FIXED_ATTRIBUTE = MESSAGE(503, TRANSLATION(), WARNING(),
  "Using overdeterimed solver for initialization. Setting fixed=false to the following variables: %s");
public constant Message PROPAGATE_START_VALUE = MESSAGE(504, TRANSLATION(), WARNING(),
  "Failed to propagate the start value from variable dummy state %s to state %s. Provide a start value for the selected state instead");
public constant Message SEMI_SUPPORTED_FUNCTION = MESSAGE(505, TRANSLATION(), WARNING(),
  "Using non-standardized function %s. For full conformance with language specification please use the appropriate function %s or the Modelica.Math library");
public constant Message FAILED_TO_EVALUATE_FUNCTION = MESSAGE(506, TRANSLATION(), ERROR(),
  "Failed to evaluate function: %s");
public constant Message OVERDET_INITIAL_EQN_SYSTEM = MESSAGE(507, SYMBOLIC(), WARNING(),
  "Overdetermined initial equation system, using solver for overdetermined systems.");
public constant Message FINAL_OVERRIDE = MESSAGE(508, TRANSLATION(), ERROR(),
  "trying to override final variable in class: %s");
public constant Message WARNING_RELATION_ON_REAL = MESSAGE(509, TRANSLATION(), WARNING(),
  "In component %s, in relation %s, %s on Reals is only allowed inside functions.");
public constant Message WARNING_BUILTIN_DELAY = MESSAGE(510, TRANSLATION(), WARNING(),
  "Improper use of builtin function delay(expr,delayTime,delayMax*) in component %s: %s");
public constant Message When_With_IF = MESSAGE(511, TRANSLATION(), ERROR(),
  "When equations using if-statements on form 'if a then b=c else b=d' not implemented yet, use 'b=if a then c else d' as workaround
%s");
public constant Message OUTER_MODIFICATION = MESSAGE(512, TRANSLATION(), WARNING(),
  "Ignoring the modification on outer element: %s");
public constant Message REDUNDANT_GUESS = MESSAGE(513, TRANSLATION(), WARNING(),
  "Start value is assigned for variable: %s, but not used since %s");
public constant Message DERIVATIVE_NON_REAL = MESSAGE(514, TRANSLATION(), ERROR(),
  "Illegal derivative. der(%s) in component %s is of type %s, which is not a subtype of Real");
public constant Message UNUSED_MODIFIER = MESSAGE(515, TRANSLATION(), ERROR(),
  "In modifier %s");
public constant Message SELECTED_STATES = MESSAGE(515, TRANSLATION(), ERROR(),
  "In modifier %s");
public constant Message MULTIPLE_MODIFIER = MESSAGE(516, TRANSLATION(), ERROR(),
  "Multiple modifiers in same scope for element %s, %s");
public constant Message INCONSISTENT_UNITS = MESSAGE(517, TRANSLATION(), WARNING(),
  "The system of units is inconsistent in term %s with the units %s and %s respectively.");
public constant Message CONSISTENT_UNITS = MESSAGE(518, TRANSLATION(), NOTIFICATION(),
  "The system of units is consistent.");
public constant Message INCOMPLETE_UNITS = MESSAGE(519, TRANSLATION(), NOTIFICATION(),
  "The system of units is incomplete. Please provide unit information to the model by e.g. using types from the SIunits package.");
public constant Message INCOMPATIBLE_TYPES_FUNC = MESSAGE(520, SYMBOLIC(), ERROR(),
  "While deriving %s to %s, types of inputs: %s and type of %s: %s did not match");
public constant Message ASSIGN_RHS_ELABORATION = MESSAGE(521, TRANSLATION(), ERROR(),
  "Failed to elaborate rhs of %s");
public constant Message FAILED_TO_EVALUATE_EXPRESSION = MESSAGE(522, TRANSLATION(), ERROR(),
  "Could not evaluate expression: %s");
public constant Message WARNING_JACOBIAN_EQUATION_SOLVE = MESSAGE(523, SYMBOLIC(), WARNING(),
  "jacobian equation %s could not solve proper for %s. Assume %s=0.");
public constant Message INDEX_REDUCTION_NOTIFICATION = MESSAGE(1000, SYMBOLIC(), NOTIFICATION(),
  "Differentiated equation %s to %s for index reduction");
public constant Message SELECTED_STATE_DUE_TO_START_NOTIFICATION = MESSAGE(1001, SYMBOLIC(), NOTIFICATION(),
  "Selecting %s as state since it has a start value and a potential state variable (appearing inside der()) was found in the same scope without start value.");
public constant Message INTERACTIVE_ASSIGN = MESSAGE(5000, SCRIPTING(), ERROR(),
  "Interactive assignment of %s failed for expression %s.");
public constant Message MATCH_SHADOWING = MESSAGE(5001, TRANSLATION(), ERROR(),
  " Local variable '%s' shadows input or result variables in a {match,matchcontinue} expression.");
public constant Message META_POLYMORPHIC = MESSAGE(5002, TRANSLATION(), ERROR(),
  " %s uses invalid subtypeof syntax. Only subtypeof Any is supported.");
public constant Message META_FUNCTION_TYPE_NO_PARTIAL_PREFIX = MESSAGE(5003, TRANSLATION(), ERROR(),
  "%s is used as a function reference, but doesn't specify the partial prefix.");
public constant Message META_MATCH_EQUATION_FORBIDDEN = MESSAGE(5004, TRANSLATION(), ERROR(),
  "Match expression equation sections forbid the use of %s-equations.");
public constant Message META_UNIONTYPE_ALIAS_MODS = MESSAGE(5005, TRANSLATION(), ERROR(),
  "Uniontype was not generated correctly. One possible cause is modifications, which are not allowed.");
public constant Message META_COMPLEX_TYPE_MOD = MESSAGE(5006, TRANSLATION(), ERROR(),
  "MetaModelica complex types may not have modifiers.");
public constant Message META_MATCHEXP_RESULT_NUM_ARGS = MESSAGE(5007, TRANSLATION(), ERROR(),
  "Match expression has mismatched number of expected (%s) and actual (%s) outputs. The expressions were %s and %s.");
public constant Message META_CEVAL_FUNCTION_REFERENCE = MESSAGE(5008, TRANSLATION(), ERROR(),
  "Cannot evaluate function pointers (got %s).");
public constant Message NON_INSTANTIATED_FUNCTION = MESSAGE(5009, SYMBOLIC(), ERROR(),
  "Tried to use function %s, but it was not instantiated.");
public constant Message META_UNSOLVED_POLYMORPHIC_BINDINGS = MESSAGE(5010, TRANSLATION(), ERROR(),
  "Could not solve the polymorphism in the function call to %s
  Input bindings:
%s
  Solved bindings:
%s
  Unsolved bindings:
%s");
public constant Message META_RECORD_FOUND_FAILURE = MESSAGE(5011, TRANSLATION(), ERROR(),
  "In metarecord call %s: %s");
public constant Message META_INVALID_PATTERN = MESSAGE(5012, TRANSLATION(), ERROR(),
  "Invalid pattern: %s");
public constant Message META_MATCH_INPUT_OUTPUT_NON_CREF = MESSAGE(5013, TRANSLATION(), ERROR(),
  "Only component references are valid as %s of a match expression. Got %s.");
public constant Message META_MATCH_GENERAL_FAILURE = MESSAGE(5014, TRANSLATION(), ERROR(),
  "Failed to elaborate match expression %s");
public constant Message META_CONS_TYPE_MATCH = MESSAGE(5015, TRANSLATION(), ERROR(),
  "Failed to match types of cons expression %s. The head has type %s and the tail %s.");
public constant Message META_STRICT_RML_MATCH_IN_OUT = MESSAGE(5016, TRANSLATION(), ERROR(),
  "%s. Strict RML enforces match expression input and output to be the same as the function's.");
public constant Message META_NONE_CREF = MESSAGE(5017, TRANSLATION(), ERROR(),
  "NONE is not acceptable syntax. Use NONE() instead.");
public constant Message META_INVALID_PATTERN_NAMED_FIELD = MESSAGE(5018, TRANSLATION(), ERROR(),
  "Invalid named fields: %s");
public constant Message META_INVALID_LOCAL_ELEMENT = MESSAGE(5019, TRANSLATION(), ERROR(),
  "Only components without direction are allowed in local declarations, got: %s");
public constant Message META_INVALID_COMPLEX_TYPE = MESSAGE(5020, TRANSLATION(), ERROR(),
  "Invalid complex type name: %s");
public constant Message META_DECONSTRUCTOR_NOT_PART_OF_UNIONTYPE = MESSAGE(5021, TRANSLATION(), ERROR(),
  "In pattern %s: %s is not part of uniontype %s");
public constant Message META_TYPE_MISMATCH_PATTERN = MESSAGE(5022, TRANSLATION(), ERROR(),
  "Type mismatch in pattern %s
actual type:
  %s
expected type:
  %s");
public constant Message META_DECONSTRUCTOR_NOT_RECORD = MESSAGE(5023, TRANSLATION(), ERROR(),
  "Call pattern is not a record deconstructor %s");
public constant Message META_MATCHEXP_RESULT_TYPES = MESSAGE(5024, TRANSLATION(), ERROR(),
  "Match expression has mismatched result types:%s");
public constant Message MATCHCONTINUE_TO_MATCH_OPTIMIZATION = MESSAGE(5025, TRANSLATION(), NOTIFICATION(),
  "This matchcontinue expression has no overlapping patterns and should be using match instead of matchcontinue.");
public constant Message META_DEAD_CODE = MESSAGE(5026, TRANSLATION(), NOTIFICATION(),
  "Dead code elimination: %s.");
public constant Message META_UNUSED_DECL = MESSAGE(5027, TRANSLATION(), NOTIFICATION(),
  "Unused local variable: %s.");
public constant Message META_UNUSED_AS_BINDING = MESSAGE(5028, TRANSLATION(), NOTIFICATION(),
  "Removing unused as-binding: %s.");
public constant Message MATCH_TO_SWITCH_OPTIMIZATION = MESSAGE(5029, TRANSLATION(), NOTIFICATION(),
  "Converted match expression to switch of type %s.");
public constant Message REDUCTION_TYPE_ERROR = MESSAGE(5030, TRANSLATION(), ERROR(),
  "Reductions require the types of the %s and %s to be %s, but got: %s and %s.");
public constant Message UNSUPPORTED_REDUCTION_TYPE = MESSAGE(5031, TRANSLATION(), ERROR(),
  "Expected a reduction function with type signature ('A,'B) => 'B, but got %s.");
public constant Message MATCH_SHADOWING_OPTIMIZER = MESSAGE(5032, TRANSLATION(), WARNING(),
  "Cannot optimize function due to a local variable having the same name as an input variable: %s.");
public constant Message COMPILER_ERROR = MESSAGE(5999, TRANSLATION(), ERROR(),
  "%s");
public constant Message COMPILER_WARNING = MESSAGE(6000, TRANSLATION(), WARNING(),
  "%s");
public constant Message COMPILER_NOTIFICATION = MESSAGE(6001, TRANSLATION(), NOTIFICATION(),
  "%s");
public constant Message SUSAN_ERROR = MESSAGE(7000, TRANSLATION(), ERROR(),
  "%s");
public constant Message TEMPLATE_ERROR = MESSAGE(7001, TRANSLATION(), ERROR(),
  "Template error: %s");

protected import ErrorExt;
protected import Print;
protected import RTOpts;
protected import System;

public function updateCurrentComponent "Function: updateCurrentComponent
This function takes a String and set the global var to 
which the current variable the compiler is working with."
  input String component;
  input Absyn.Info info;
protected
  String filename;
  Integer ls, le, cs, ce;
  Boolean ro;
algorithm
  Absyn.INFO(filename, ro, ls, cs, le, ce, _) := info;
  ErrorExt.updateCurrentComponent(component, ro, filename, ls, le, cs, ce);
end updateCurrentComponent;

public function addMessage "Implementation of Relations
  function: addMessage
  Adds a message given ID and tokens. The rest of the info
  is looked up in the message table."
  input Message inErrorMsg;
  input MessageTokens inMessageTokens;
algorithm
  _ := match (inErrorMsg,inMessageTokens)
    local
      MessageType msg_type;
      Severity severity;
      String msg,msg_type_str,severity_string,id_str;
      ErrorID error_id;
      MessageTokens tokens;
    case (MESSAGE(error_id, msg_type, severity, msg), tokens)
      equation
        //print(" adding message: " +& intString(error_id) +& "\n");
        ErrorExt.addMessage(error_id, msg_type, severity, msg, tokens);
        //print(" succ add " +& msg_type_str +& " " +& severity_string +& ",  " +& msg +& "\n");
      then
        ();
  end match;
end addMessage;

public function addSourceMessage "
  Adds a message given ID, tokens and source file info.
  The rest of the info is looked up in the message table."
  input Message inErrorMsg;
  input MessageTokens inMessageTokens;
  input Absyn.Info inInfo;
algorithm
  _ := match (inErrorMsg,inMessageTokens,inInfo)
    local
      MessageType msg_type;
      Severity severity;
      String msg,msg_type_str,severity_string,file,id_str;
      ErrorID error_id,sline,scol,eline,ecol;
      MessageTokens tokens;
      Boolean isReadOnly;
    case (MESSAGE(error_id, msg_type, severity, msg), tokens, 
        Absyn.INFO(fileName = file,isReadOnly = isReadOnly, 
          lineNumberStart = sline, columnNumberStart = scol,
          lineNumberEnd = eline,columnNumberEnd = ecol))
      equation
        ErrorExt.addSourceMessage(error_id, msg_type, severity, sline, scol,
          eline, ecol, isReadOnly, file, msg, tokens);
      then ();
  end match;
end addSourceMessage;


public function addMessageOrSourceMessage
"@author:adrpo
  Adds a message or a source message depending on the OPTIONAL source file info.
  If the source file info is not present a normal message is added.
  If the source file info is present a source message is added"
  input Message inErrorMsg;
  input MessageTokens inMessageTokens;
  input Option<Absyn.Info> inInfoOpt;
algorithm
  _ := match (inErrorMsg, inMessageTokens, inInfoOpt)
    local
      Absyn.Info info;
    
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

public function printMessagesStr "Relations for pretty printing.
  function: printMessagesStr
  Prints messages to a string."
  output String res;
algorithm
  res := ErrorExt.printMessagesStr();
end printMessagesStr;

public function printErrorsNoWarning "
  Prints errors only to a string.
"
  output String res;
algorithm
  res := ErrorExt.printErrorsNoWarning();
end printErrorsNoWarning;

public function printMessagesStrLst "function: printMessagesStr
  Returns all messages as a list of strings, one for each message."
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue ()
    case () then {"Not impl. yet"};
  end matchcontinue;
end printMessagesStrLst;

public function printMessagesStrLstType "function: printMessagesStrLstType
   Returns all messages as a list of strings, one for each message.
   Filters out messages of certain type."
  input MessageType inMessageType;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inMessageType)
    case (_) then {"Not impl. yet"};
  end matchcontinue;
end printMessagesStrLstType;

public function printMessagesStrLstSeverity "function: printMessagesStrLstSeverity
  Returns all messages as a list of strings, one for each message.
  Filters out messages of certain severity"
  input Severity inSeverity;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inSeverity)
    case (_) then {"Not impl. yet"};
  end matchcontinue;
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

public function getMessages "Relations for interactive comm. These returns the messages as an array
  of strings, suitable for sending to clients like model editor, MDT, etc.

  function getMessagesStr

  Return all messages in a matrix format, vector of strings for each
  message, written out as a string.
"
  output list<TotalMessage> res;
algorithm
  res := ErrorExt.getMessages();
end getMessages;

public function getMessagesStrType "function getMessagesStrType

  Return all messages in a matrix format, vector of strings for each
  message, written out as a string.
  Filtered by a specific MessageType.
"
  input MessageType inMessageType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inMessageType)
    case (_) then "not impl yet.";
  end matchcontinue;
end getMessagesStrType;

public function getMessagesStrSeverity "function getMessagesStrSeverity

  Return all messages in a matrix format, vector of strings for each
  message, written out as a string.
  Filtered by a specific MessageType.
"
  input Severity inSeverity;
  output String outString;
algorithm
  outString:=
  matchcontinue (inSeverity)
    case (_) then "not impl yet.";
  end matchcontinue;
end getMessagesStrSeverity;

protected function messageTypeStr "function: messageTypeStr

  Converts a MessageType to a string.
"
  input MessageType inMessageType;
  output String outString;
algorithm
  outString:=
  match (inMessageType)
    case (SYNTAX()) then "SYNTAX";
    case (GRAMMAR()) then "GRAMMAR";
    case (TRANSLATION()) then "TRANSLATION";
    case (SYMBOLIC()) then "SYMBOLIC";
    case (SIMULATION()) then "SIMULATION";
    case (SCRIPTING()) then "SCRIPTING";
  end match;
end messageTypeStr;

protected function severityStr "function: severityStr

  Converts a Severity to a string.
"
  input Severity inSeverity;
  output String outString;
algorithm
  outString:=
  match (inSeverity)
    case (ERROR()) then "Error";
    case (WARNING()) then "Warning";
    case (NOTIFICATION()) then "Notification";
  end match;
end severityStr;

protected function selectString "function selectString
  author: adrpo, 2006-02-05
  selects first string is bool is true otherwise the second string
"
  input Boolean inBoolean1;
  input String inString2;
  input String inString3;
  output String outString;
algorithm
  outString:=
  matchcontinue (inBoolean1,inString2,inString3)
    local String s1,s2;
    case (true,s1,_) then s1;
    case (false,_,s2) then s2;
  end matchcontinue;
end selectString;

public function infoStr
  "Converts an Absyn.Info into a string ready to be used in error messages.
  Format is [filename:line start:column start-line end:column end]"
  input Absyn.Info info;
  output String str;
algorithm
  str := match(info)
    local 
      String filename, info_str;
      Integer line_start, line_end, col_start, col_end;
    case (Absyn.INFO(fileName = filename, lineNumberStart = line_start, 
        columnNumberStart = col_start, lineNumberEnd = line_end, columnNumberEnd = col_end))
        equation
          info_str = "[" +& filename +& ":" +& 
                     intString(line_start) +& ":" +& intString(col_start) +& "-" +& 
                     intString(line_end) +& ":" +& intString(col_end) +& "]";
      then info_str;
  end match;
end infoStr;

public function assertion
"Used to make compiler-internal assertions. These messages are not meant
to be shown to a user, but rather to show internal error messages."
  input Boolean b;
  input String message;
  input Absyn.Info info;
algorithm
  _ := match (b,message,info)
    case (true,_,_) then ();
    else
      equation
        addSourceMessage(INTERNAL_ERROR, {message}, info);
      then fail();
  end match;
end assertion;

public function assertionOrAddSourceMessage
"Used to make assertions. These messages are meant to be shown to a user when
the condition is true. If the Error-level of the message is Error, this function
fails."
  input Boolean inCond;
  input Message inErrorMsg;
  input MessageTokens inMessageTokens;
  input Absyn.Info inInfo;
algorithm
  _ := match (inCond, inErrorMsg, inMessageTokens, inInfo)
    case (true,_,_,_) then ();
    else
      equation
        addSourceMessage(inErrorMsg, inMessageTokens, inInfo);
        failOnErrorMsg(inErrorMsg);
      then ();
  end match;
end assertionOrAddSourceMessage;

protected function failOnErrorMsg
  input Message inMessage;
algorithm
  _ := match(inMessage)
    case MESSAGE(severity = ERROR()) then fail();
    else ();
  end match;
end failOnErrorMsg;

public function addCompilerWarning
"Used to make a compiler warning "
  input String message;
algorithm
  _ := match (message)
    case (message)
      equation
        addMessage(COMPILER_WARNING, {message});
      then 
        ();
  end match;
end addCompilerWarning;

end Error;

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package DAE
" file:	 DAE.mo
  package:     DAE
  description: DAE management and output
 
  RCS: $Id$
  
  This module defines data structures for DAE equations and declarations of
  variables and functions. The DAE data structure is the result of flattening,
  containing only flat modelica, i.e. equations, algorithms, variables and
  functions. 
"

public import Absyn;
public import ClassInf;
public import Exp;
public import SCode;
public import Values;

public type Ident = String;

public type InstDims = list<Exp.Subscript>;

public type StartValue = Option<Exp.Exp>;
  
public constant String UNIQUEIO = "$unique$outer$";
  

public uniontype VarKind
  record VARIABLE end VARIABLE;

  record DISCRETE end DISCRETE;

  record PARAM end PARAM;

  record CONST end CONST;

end VarKind;

public uniontype Flow "The Flow of a variable indicates if it is a Flow variable or not, or if
   it is not a connector variable at all."
  record FLOW end FLOW;
 
  record NON_FLOW end NON_FLOW;

  record NON_CONNECTOR end NON_CONNECTOR;

end Flow;

public uniontype Stream "The Stream of a variable indicates if it is a Stream variable or not, or if
   it is not a connector variable at all."
  record STREAM end STREAM;

  record NON_STREAM end NON_STREAM;

  record NON_STREAM_CONNECTOR end NON_STREAM_CONNECTOR;
    
end Stream;


public uniontype VarDirection
  record INPUT end INPUT;

  record OUTPUT end OUTPUT;

  record BIDIR end BIDIR;

end VarDirection;

public uniontype VarProtection
  record PUBLIC "public variables" end PUBLIC; 
  record PROTECTED "protected variables" end PROTECTED;
end VarProtection;

public uniontype Element
  record VAR 
    Exp.ComponentRef componentRef " The variable name";
    VarKind kind "varible kind: variable, constant, parameter, discrete etc." ;
    VarDirection direction "input, output or bidir" ;
    VarProtection protection "if protected or public";
    Type ty "Full type information required";
    Option<Exp.Exp> binding "Binding expression e.g. for parameters ; value of start attribute" ; 
    InstDims  dims "dimensions";
    Flow flowPrefix "Flow of connector variable. Needed for unconnected flow variables" ;
    Stream streamPrefix "Stream variables in connectors" ;
    list<Absyn.Path> pathLst " " ;
    Option<VariableAttributes> variableAttributesOption;
    Option<SCode.Comment> absynCommentOption;
    Absyn.InnerOuter innerOuter "inner/outer required to 'change' outer references";
  end VAR;

  record DEFINE "A solved equation"
    Exp.ComponentRef componentRef;
    Exp.Exp exp;
  end DEFINE;

  record INITIALDEFINE " A solved initial equation"
    Exp.ComponentRef componentRef;
    Exp.Exp exp;
  end INITIALDEFINE;
  
  record EQUATION "Scalar equation"
    Exp.Exp exp;
    Exp.Exp scalar ;
  end EQUATION;

  record EQUEQUATION "effort variable equality"
    Exp.ComponentRef cr1;
    Exp.ComponentRef cr2;
  end EQUEQUATION;

  record ARRAY_EQUATION " an array equation"
    list<Integer> dimension "dimension sizes" ;
    Exp.Exp exp;
    Exp.Exp array  ;
  end ARRAY_EQUATION;

  record COMPLEX_EQUATION "an equation of complex type, e.g. record = func(..)"
    Exp.Exp lhs;
    Exp.Exp rhs;
  end COMPLEX_EQUATION;
  
  record INITIAL_COMPLEX_EQUATION "an initial equation of complex type, e.g. record = func(..)"
    Exp.Exp lhs;
    Exp.Exp rhs;
  end INITIAL_COMPLEX_EQUATION;
  
  
  record WHEN_EQUATION " a when equation"
    Exp.Exp condition "Condition" ;
    list<Element> equations "Equations" ;
    Option<Element> elsewhen_ "Elsewhen should be of type WHEN_EQUATION" ;
  end WHEN_EQUATION;

  record IF_EQUATION " an if-equation"
    list<Exp.Exp> condition1 "Condition" ;
    list<list<Element>> equations2 "Equations of true branch" ;
    list<Element> equations3 "Equations of false branch" ;
  end IF_EQUATION;

  record INITIAL_IF_EQUATION "An initial if-equation"
    list<Exp.Exp> condition1 "Condition" ;
    list<list<Element>> equations2 "Equations of true branch" ;
    list<Element> equations3 "Equations of false branch" ;
  end INITIAL_IF_EQUATION;

  record INITIALEQUATION " An initial equaton"
    Exp.Exp exp1;
    Exp.Exp exp2;
  end INITIALEQUATION;

  record ALGORITHM " An algorithm section"
    Algorithm algorithm_;
  end ALGORITHM;

  record INITIALALGORITHM " An initial algorithm section"
    Algorithm algorithm_;
  end INITIALALGORITHM;

  record COMP
    Ident ident;
    DAElist dAElist "a component with 
						    subelements, normally 
						    only used at top level." ;
  end COMP;

  record FUNCTION " A Modelica function"
    Absyn.Path path;
    DAElist dAElist;
    Type type_;
    Boolean partialPrefix "MetaModelica extension";
  end FUNCTION;

  record EXTFUNCTION "An external function"
    Absyn.Path path;
    DAElist dAElist;
    Type type_;
    ExternalDecl externalDecl;
  end EXTFUNCTION;
  
  record RECORD_CONSTRUCTOR "A Modelica record constructor. The function can be generated from the Path and Type alone."
    Absyn.Path path;
    Type type_;
  end RECORD_CONSTRUCTOR;

  record EXTOBJECTCLASS "The 'class' of an external object"
    Absyn.Path path "className of external object";
    Element constructor "constructor is an EXTFUNCTION";
    Element destructor "destructor is an EXTFUNCTION";
  end EXTOBJECTCLASS;
  
  record ASSERT " The Modelica builtin assert"
    Exp.Exp condition;
    Exp.Exp message;
  end ASSERT;

  record TERMINATE " The Modelica builtin terminate(msg)"
    Exp.Exp message;
  end TERMINATE;

  record REINIT " reinit operator for reinitialization of states"
    Exp.ComponentRef componentRef;
    Exp.Exp exp;
  end REINIT;

   record NORETCALL "call with no return value, i.e. no equation. 
	   Typically sideeffect call of external function."  
     Absyn.Path functionName;
     list<Exp.Exp> functionArgs;
   end NORETCALL;
end Element;

public 
uniontype VariableAttributes
  record VAR_ATTR_REAL
    Option<Exp.Exp> quantity "quantity" ;
    Option<Exp.Exp> unit "unit" ;
    Option<Exp.Exp> displayUnit "displayUnit" ;
    tuple<Option<Exp.Exp>, Option<Exp.Exp>> min "min , max" ;
    Option<Exp.Exp> initial_ "Initial value" ;
    Option<Exp.Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables" ;
    Option<Exp.Exp> nominal "nominal" ;
    Option<StateSelect> stateSelectOption;
    Option<Exp.Exp> equationBound;
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
  end VAR_ATTR_REAL;

  record VAR_ATTR_INT
    Option<Exp.Exp> quantity "quantity" ;
    tuple<Option<Exp.Exp>, Option<Exp.Exp>> min "min , max" ;
    Option<Exp.Exp> initial_ "Initial value" ;
    Option<Exp.Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables" ;
    Option<Exp.Exp> equationBound;
    Option<Boolean> isProtected; // ,eb,ip
    Option<Boolean> finalPrefix;
  end VAR_ATTR_INT;

  record VAR_ATTR_BOOL
    Option<Exp.Exp> quantity "quantity" ;
    Option<Exp.Exp> initial_ "Initial value" ;
    Option<Exp.Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables" ;
    Option<Exp.Exp> equationBound;
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
  end VAR_ATTR_BOOL;

  record VAR_ATTR_STRING
    Option<Exp.Exp> quantity "quantity" ;
    Option<Exp.Exp> initial_ "Initial value" ;
    Option<Exp.Exp> equationBound;
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
  end VAR_ATTR_STRING;

  record VAR_ATTR_ENUMERATION
    Option<Exp.Exp> quantity "quantity" ;
    tuple<Option<Exp.Exp>, Option<Exp.Exp>> min "min , max" ;
    Option<Exp.Exp> start "start" ;
    Option<Exp.Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables" ;
    Option<Exp.Exp> equationBound;
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
  end VAR_ATTR_ENUMERATION;

end VariableAttributes;

public uniontype StateSelect
  record NEVER end NEVER;

  record AVOID end AVOID;

  record DEFAULT end DEFAULT;

  record PREFER end PREFER;

  record ALWAYS end ALWAYS;
end StateSelect;

public uniontype ExtArg
  record EXTARG
    Exp.ComponentRef componentRef;
    Attributes attributes;
    Type type_;
  end EXTARG;

  record EXTARGEXP
    Exp.Exp exp;
    Type type_;
  end EXTARGEXP;

  record EXTARGSIZE
    Exp.ComponentRef componentRef;
    Attributes attributes;
    Type type_;
    Exp.Exp exp;
  end EXTARGSIZE;

  record NOEXTARG end NOEXTARG;
end ExtArg;

public uniontype ExternalDecl
  record EXTERNALDECL
    Ident ident;
    list<ExtArg> external_ "external function name" ;
    ExtArg parameters "parameters" ;
    String returnType "return type" ;
    Option<Absyn.Annotation> language "language e.g. Library" ;
  end EXTERNALDECL;
end ExternalDecl;

public uniontype DAElist "A DAElist is a list of Elements. Variables, equations, functions, 
  algorithms, etc. are all found in this list.
"
  record DAE
    list<Element> elementLst;
  end DAE;
end DAElist;

/* -- Algorithm.mo -- */
public 
uniontype Algorithm "The `Algorithm\' type corresponds to a whole algorithm section.
  It is simple a list of algorithm statements."
  record ALGORITHM_STMTS
    list<Statement> statementLst;
  end ALGORITHM_STMTS;

end Algorithm;

public 
uniontype Statement "There are four kinds of statements.  Assignments (`a := b;\'),
    if statements (`if A then B; elseif C; else D;\'), for loops
    (`for i in 1:10 loop ...; end for;\') and when statements
    (`when E do S; end when;\')."
  record STMT_ASSIGN
    Exp.Type type_;
    Exp.Exp exp1;
    Exp.Exp exp;
  end STMT_ASSIGN;

  record STMT_TUPLE_ASSIGN
    Exp.Type type_;
    list<Exp.Exp> expExpLst;
    Exp.Exp exp;
  end STMT_TUPLE_ASSIGN;

  record STMT_ASSIGN_ARR
    Exp.Type type_;
    Exp.ComponentRef componentRef;
    Exp.Exp exp;
  end STMT_ASSIGN_ARR;

  record STMT_IF
    Exp.Exp exp;
    list<Statement> statementLst;
    Else else_;
  end STMT_IF;

  record STMT_FOR
    Exp.Type type_;
    Boolean boolean;
    Ident ident;
    Exp.Exp exp;
    list<Statement> statementLst;
  end STMT_FOR;

  record STMT_WHILE
    Exp.Exp exp;
    list<Statement> statementLst;
  end STMT_WHILE;

  record STMT_WHEN
    Exp.Exp exp;
    list<Statement> statementLst;
    Option<Statement> elseWhen;
    list<Integer> helpVarIndices;
  end STMT_WHEN;

  record STMT_ASSERT "assert(cond,msg)"
    Exp.Exp cond;
    Exp.Exp msg;
  end STMT_ASSERT;
  
  record STMT_TERMINATE "terminate(msg)"
    Exp.Exp msg;
  end STMT_TERMINATE;

  record STMT_REINIT 
    Exp.Exp var "Variable"; 
    Exp.Exp value "Value "; 
  end STMT_REINIT;
  
  record STMT_NORETCALL "call with no return value, i.e. no equation. 
		   Typically sideeffect call of external function."  
    Exp.Exp exp;
  end STMT_NORETCALL;    
  
  record STMT_RETURN
  end STMT_RETURN;
  
  record STMT_BREAK
  end STMT_BREAK;

  // MetaModelica extension. KS
  record STMT_TRY
    list<Statement> tryBody;
  end STMT_TRY;

  record STMT_CATCH
    list<Statement> catchBody;
  end STMT_CATCH;

  record STMT_THROW
  end STMT_THROW;

  record STMT_GOTO
    String labelName;
  end STMT_GOTO;

  record STMT_LABEL
    String labelName;
  end STMT_LABEL;
  
  record STMT_MATCHCASES "matchcontinue helper"
    list<Exp.Exp> caseStmt;
  end STMT_MATCHCASES;
  
  //-----

end Statement;

public 
uniontype Else "An if statements can one or more `elseif\' branches and an
    optional `else\' branch."
  record NOELSE end NOELSE;

  record ELSEIF
    Exp.Exp exp;
    list<Statement> statementLst;
    Else else_;
  end ELSEIF;

  record ELSE
    list<Statement> statementLst;
  end ELSE;

end Else;
/* -- End Algorithm.mo -- */

/* -- Start Types.mo -- */
public 
uniontype Var "- Variables"
  record TYPES_VAR
    Ident name "name" ;
    Attributes attributes "attributes" ;
    Boolean protected_ "protected" ;
    Type type_ "type" ;
    Binding binding "binding ; equation modification" ;
  end TYPES_VAR;

end Var;

public 
uniontype Attributes "- Attributes"
  record ATTR
    Boolean flowPrefix "flow" ;
    Boolean streamPrefix "stream" ;
    SCode.Accessibility accessibility "accessibility" ;
    SCode.Variability parameter_ "parameter" ;
    Absyn.Direction direction "direction" ;
    Absyn.InnerOuter innerOuter "inner, outer,  inner outer or unspecified";
  end ATTR;

end Attributes;

public 
uniontype Binding "- Binding"
  record UNBOUND end UNBOUND;

  record EQBOUND
    Exp.Exp exp "exp" ;
    Option<Values.Value> evaluatedExp "evaluatedExp; evaluated exp" ;
    Const constant_ "constant" ;
  end EQBOUND;

  record VALBOUND
    Values.Value valBound "valBound" ;
  end VALBOUND;

end Binding;

public type Type = tuple<TType, Option<Absyn.Path>> "
     A Type is a tuple of a TType (containing the actual type) and a optional classname
     for the class where the type originates from.

- Type";

public
type EqualityConstraint = Option<tuple<Absyn.Path, Integer>>;
 
public 
uniontype TType "-TType contains the actual type"
  record T_INTEGER
    list<Var> varLstInt "varLstInt" ;
  end T_INTEGER;

  record T_REAL
    list<Var> varLstReal "varLstReal" ;
  end T_REAL;

  record T_STRING
    list<Var> varLstString "varLstString" ;
  end T_STRING;

  record T_BOOL
    list<Var> varLstBool "varLstBool" ;
  end T_BOOL;

//  record T_ENUM end T_ENUM;

  record T_ENUMERATION
    Option<Integer> index "the enumeration value index, SOME for element, NONE for type" ;
    Absyn.Path path "enumeration path" ;
    list<String> names "names" ;
    list<Var> varLst "varLst, empty for elements" ;
  end T_ENUMERATION;

  record T_ARRAY
    ArrayDim arrayDim "arrayDim" ;
    Type arrayType "arrayType" ;
  end T_ARRAY;

  record T_NORETCALL "For functions not returning any values." end T_NORETCALL;

  record T_NOTYPE "Used when type is not yet determined" end T_NOTYPE;

  record T_ANYTYPE
    Option<ClassInf.State> anyClassType "anyClassType - used for generic types. When class state present the type is assumed to be a complex type which has that restriction." ;
  end T_ANYTYPE;
  
  // MetaModelica extensions
  record T_LIST "MetaModelica list type"
    Type listType "listType";
  end T_LIST;

  record T_METATUPLE "MetaModelica tuple type"
    list<Type> types;
  end T_METATUPLE;

  record T_METAOPTION "MetaModelica option type"
    Type optionType;
  end T_METAOPTION;

  record T_UNIONTYPE "MetaModelica Uniontype, added by simbj"
    list <Absyn.Path> records;
  end T_UNIONTYPE;
  
  record T_METARECORD "MetaModelica Record, used by Uniontypes. added by simbj"
    Integer index; //The index in the uniontype
    list<Var> fields;
  end T_METARECORD;
  
  record T_COMPLEX
    ClassInf.State complexClassType "complexClassType ; The type of. a class" ;
    list<Var> complexVarLst "complexVarLst ; The variables of a complex type" ;
    Option<Type> complexTypeOption "complexTypeOption ; A complex type can be a subtype of another (primitive) type (through extends). In that case the varlist is empty" ;
    EqualityConstraint equalityConstraint;
  end T_COMPLEX;

  record T_FUNCTION
    list<FuncArg> funcArg "funcArg" ;
    Type funcResultType "funcResultType ; Only single-result" ;
  end T_FUNCTION;

  record T_TUPLE
    list<Type> tupleType "tupleType ; For functions returning multiple values."  ;
  end T_TUPLE;

  record T_BOXED "Used for MetaModelica generic types"
    Type ty;
  end T_BOXED;
  
  record T_POLYMORPHIC
    String name;
  end T_POLYMORPHIC;
  
end TType;

public 
uniontype ArrayDim "- Array Dimensions"
  record DIM
    Option<Integer> integerOption;
  end DIM;

end ArrayDim;

public 
type FuncArg = tuple<Ident, Type> "- Function Argument" ;

public 
uniontype Const "The degree of constantness of an expression is determined by the Const 
    datatype. Variables declared as \'constant\' will get C_CONST constantness.
    Variables declared as \'parameter\' will get C_PARAM constantness and
    all other variables are not constant and will get C_VAR constantness.

  - Variable properties"
  record C_CONST end C_CONST;

  record C_PARAM "\'constant\'s, should always be evaluated" end C_PARAM;

  record C_VAR "\'parameter\'s, evaluated if structural not constants, never evaluated" end C_VAR;

end Const;

public 
uniontype TupleConst "A tuple is added to the Types. This is used by functions whom returns multiple arguments.
  Used by split_props
  - Tuple constants"
  record SINGLE_CONST
    Const const;
  end SINGLE_CONST;

  record TUPLE_CONST
    list<TupleConst> tupleConstLst "tupleConstLst" ;
  end TUPLE_CONST;

end TupleConst;

public 
uniontype Properties "P.R 1.1 for multiple return arguments from functions, 
    one constant flag for each return argument. 

  The datatype `Properties\' contain information about an
    expression.  The properties are created by analyzing the
    expressions.
  - Expression properties"
  record PROP 
    Type type_ "type" ;
    Const constFlag "constFlag; if the type is a tuple, each element 
				          have a const flag." ;
  end PROP;

  record PROP_TUPLE
    Type type_;
    TupleConst tupleConst "tupleConst; The elements might be 
							    tuple themselfs." ;
  end PROP_TUPLE;

end Properties;

public 
uniontype EqMod "To generate the correct set of equations, the translator has to
  differentiate between the primitive types `Real\', `Integer\',
  `String\', `Boolean\' and types directly derived from then from
  other, complex types.  For arrays and matrices the type
  `T_ARRAY\' is used, with the first argument being the number of
  dimensions, and the second being the type of the objects in the
  array.  The `Type\' type is used to store
  information about whether a class is derived from a primitive
  type, and whether a variable is of one of these types.
  - Modification datatype, was originally in Mod"
  record TYPED
    Exp.Exp modifierAsExp "modifierAsExp ; modifier as expression" ;
    Option<Values.Value> modifierAsValue "modifierAsValue ; modifier as Value option" ;
    Properties properties "properties" ;
  end TYPED;

  record UNTYPED
    Absyn.Exp exp;
  end UNTYPED;

end EqMod;

public 
uniontype SubMod "-Sub Modification"
  record NAMEMOD
    Ident ident;
    Mod mod;
  end NAMEMOD;

  record IDXMOD
    list<Integer> integerLst;
    Mod mod;
  end IDXMOD;

end SubMod;

public 
uniontype Mod "Modification"
  record MOD
    Boolean finalPrefix "final" ;
    Absyn.Each each_;
    list<SubMod> subModLst;
    Option<EqMod> eqModOption;
  end MOD;

  record REDECL
    Boolean finalPrefix "final" ;
    list<tuple<SCode.Element, Mod>> tplSCodeElementModLst;
  end REDECL;

  record NOMOD end NOMOD;

end Mod;

/* -- End Types.mo -- */

end DAE;


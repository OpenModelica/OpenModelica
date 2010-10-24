//interface package SimCodeTV 

package builtin
  
  function listLength "Return the length of the list"
    replaceable type TypeVar subtypeof Any;    
    input list<TypeVar> lst;
    output Integer result;
  end listLength;
  
  function intAdd
    input Integer a;
    input Integer b;
    output Integer c;
  end intAdd;
  
  function stringEqual
    input String a;
    input String b;
    output Boolean res;
  end stringEqual;
  
end builtin;


package SimCode

  type ExtConstructor = tuple<DAE.ComponentRef, String, list<DAE.Exp>>;
  type ExtDestructor = tuple<String, DAE.ComponentRef>;
  type ExtAlias = tuple<DAE.ComponentRef, DAE.ComponentRef>;
  type HelpVarInfo = tuple<Integer, DAE.Exp, Integer>;
  type JacobianMatrix = tuple<list<SimEqSystem>, list<SimVar>, String>;
  
  uniontype SimCode
    record SIMCODE
      ModelInfo modelInfo;
      list<Function> functions;
      list<String> externalFunctionIncludes;
      list<SimEqSystem> allEquations;
      list<SimEqSystem> allEquationsPlusWhen;
      list<SimEqSystem> stateContEquations;
      list<SimEqSystem> nonStateContEquations;
      list<SimEqSystem> nonStateDiscEquations;
      list<SimEqSystem> residualEquations;
      list<SimEqSystem> initialEquations;
      list<SimEqSystem> parameterEquations;
      list<SimEqSystem> removedEquations;
      list<DAE.Statement> algorithmAndEquationAsserts;
      list<BackendDAE.ZeroCrossing> zeroCrossings;
      list<list<SimVar>> zeroCrossingsNeedSave;
      list<HelpVarInfo> helpVarInfo;
      list<SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      ExtObjInfo extObjInfo;
      MakefileParams makefileParams;
      DelayedExpression delayedExps;
      list<JacobianMatrix> JacobianMatrixes;  
      Option<SimulationSettings> simulationSettingsOpt;
      String fileNamePrefix;
    end SIMCODE;
  end SimCode;

  uniontype DelayedExpression
    record DELAYED_EXPRESSIONS
      list<tuple<Integer, DAE.Exp>> delayedExps;
      Integer maxDelayedIndex;
    end DELAYED_EXPRESSIONS;
  end DelayedExpression;

  uniontype FunctionCode
    record FUNCTIONCODE
      String name;
      Function mainFunction;
      list<Function> functions;
      list<String> externalFunctionIncludes;
      MakefileParams makefileParams;
      list<RecordDeclaration> extraRecordDecls;
    end FUNCTIONCODE;
  end FunctionCode;

  uniontype MakefileParams
    record MAKEFILE_PARAMS
      String ccompiler;
      String cxxcompiler;
      String linker;
      String exeext;
      String dllext;
      String omhome;
      String cflags;
      String ldflags;
      String senddatalibs;
      list<String> libs;
    end MAKEFILE_PARAMS;
  end MakefileParams;
  
  uniontype SimulationSettings
    record SIMULATION_SETTINGS
      Real startTime;
      Real stopTime;
      Integer numberOfIntervals;
      Real stepSize;
      Real tolerance;
      String method;
      String options;
      String outputFormat;      
    end SIMULATION_SETTINGS;
  end SimulationSettings;
  
  uniontype Context
    record SIMULATION
      Boolean genDiscrete;
    end SIMULATION;
    record FUNCTION_CONTEXT
    end FUNCTION_CONTEXT;
    record OTHER
    end OTHER;
    record INLINE_CONTEXT
    end INLINE_CONTEXT;
  end Context;
  
  uniontype Variable
    record VARIABLE
      DAE.ComponentRef name;
      DAE.ExpType ty;
      Option<DAE.Exp> value;
      list<DAE.Exp> instDims;
    end VARIABLE;  

    record FUNCTION_PTR
      String name;
      DAE.ExpType ty;
      list<Variable> args;
    end FUNCTION_PTR;
  end Variable;
  
  uniontype Statement
    record ALGORITHM
       list<DAE.Statement> statementLst;
    end ALGORITHM;
  end Statement;

  uniontype ExtObjInfo
    record EXTOBJINFO
      list<String> includes;
      list<ExtConstructor> constructors;
      list<ExtDestructor> destructors;
      list<ExtAlias> aliases;
    end EXTOBJINFO;
  end ExtObjInfo;
  
  uniontype SimEqSystem
    record SES_RESIDUAL
      DAE.Exp exp;
    end SES_RESIDUAL;
    record SES_SIMPLE_ASSIGN
      DAE.ComponentRef cref;
      DAE.Exp exp;
    end SES_SIMPLE_ASSIGN;
    record SES_ARRAY_CALL_ASSIGN
      DAE.ComponentRef componentRef;
      DAE.Exp exp;
    end SES_ARRAY_CALL_ASSIGN;
    record SES_ALGORITHM
      list<DAE.Statement> statements;
    end SES_ALGORITHM;
    record SES_LINEAR
      Boolean partOfMixed;
      list<SimVar> vars;
      list<DAE.Exp> beqs;
      list<tuple<Integer, Integer, SimEqSystem>> simJac;
    end SES_LINEAR;
    record SES_NONLINEAR
      Integer index;
      list<SimEqSystem> eqs;
      list<DAE.ComponentRef> crefs;
    end SES_NONLINEAR;
    record SES_MIXED
      SimEqSystem cont;
      list<SimVar> discVars;
      list<SimEqSystem> discEqs;
      list<String> values;
      list<Integer> value_dims;
    end SES_MIXED;
    record SES_WHEN
      DAE.ComponentRef left;
      DAE.Exp right;
      list<tuple<DAE.Exp, Integer>> conditions;
    end SES_WHEN;
  end SimEqSystem;

  uniontype SimWhenClause
    record SIM_WHEN_CLAUSE
      list<DAE.ComponentRef> conditionVars;
      list<BackendDAE.ReinitStatement> reinits;
      Option<BackendDAE.WhenEquation> whenEq;
      list<tuple<DAE.Exp, Integer>> conditions;
    end SIM_WHEN_CLAUSE;
  end SimWhenClause;

  uniontype ModelInfo
    record MODELINFO
      Absyn.Path name;
      String directory;
      VarInfo varInfo;
      SimVars vars;
    end MODELINFO;
  end ModelInfo;
  
  uniontype VarInfo
	  record VARINFO
	    Integer numHelpVars;
	    Integer numZeroCrossings;
	    Integer numTimeEvents;
	    Integer numStateVars;
	    Integer numAlgVars;
	    Integer numIntAlgVars;
	    Integer numBoolAlgVars;
	    Integer numParams;
	    Integer numIntParams;
	    Integer numBoolParams;
	    Integer numOutVars;
	    Integer numInVars;
	    Integer numResiduals;
	    Integer numExternalObjects;
	    Integer numStringAlgVars;
	    Integer numStringParamVars;
	  end VARINFO;
	end VarInfo;
	
	uniontype SimVars
	  record SIMVARS
	    list<SimVar> stateVars;
	    list<SimVar> derivativeVars;
	    list<SimVar> algVars;
	    list<SimVar> intAlgVars;
	    list<SimVar> boolAlgVars;
	    list<SimVar> inputVars;
	    list<SimVar> outputVars;
	    list<SimVar> paramVars;
	    list<SimVar> intParamVars;
	    list<SimVar> boolParamVars;
	    list<SimVar> stringAlgVars;
	    list<SimVar> stringParamVars;
	    list<SimVar> extObjVars;
	  end SIMVARS;
	end SimVars;
  
  uniontype SimVar
    record SIMVAR
      DAE.ComponentRef name;
      BackendDAE.VarKind varKind;
      String comment;
      String unit;
      String displayUnit;
      Integer index;
      Option<DAE.Exp> initialValue;
      Boolean isFixed;
      DAE.ExpType type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
    end SIMVAR;
  end SimVar;
  
  uniontype Function
    record FUNCTION    
      Absyn.Path name;
      list<Variable> inVars;
      list<Variable> outVars;
      list<RecordDeclaration> recordDecls; 
      list<Variable> functionArguments;
      list<Variable> variableDeclarations;
      list<Statement> body;
    end FUNCTION;
    record EXTERNAL_FUNCTION
      Absyn.Path name;
      String extName;
      list<Variable> funArgs;
      list<SimExtArg> extArgs;
      SimExtArg extReturn;
      list<Variable> inVars;
      list<Variable> outVars;
      list<Variable> biVars;
      Libs libs;
      String language;
      list<RecordDeclaration> recordDecls;
    end EXTERNAL_FUNCTION;
    record RECORD_CONSTRUCTOR
      Absyn.Path name;
      list<Variable> funArgs;
      list<RecordDeclaration> recordDecls;
    end RECORD_CONSTRUCTOR;
  end Function;
  
  uniontype RecordDeclaration
    record RECORD_DECL_FULL
      String name;
      Absyn.Path defPath;
      list<Variable> variables;
    end RECORD_DECL_FULL;
    record RECORD_DECL_DEF
      Absyn.Path path;
      list<String> fieldNames;
    end RECORD_DECL_DEF;
  end RecordDeclaration;

  uniontype SimExtArg
    record SIMEXTARG
      DAE.ComponentRef cref;
      Boolean isInput;
      Integer outputIndex;
      Boolean isArray;
      DAE.ExpType type_;
    end SIMEXTARG;
    record SIMEXTARGEXP
      DAE.Exp exp;
      DAE.ExpType type_;
    end SIMEXTARGEXP;
    record SIMEXTARGSIZE
      DAE.ComponentRef cref;
      Boolean isInput;
      Integer outputIndex;
      DAE.ExpType type_;
      DAE.Exp exp;
    end SIMEXTARGSIZE;
    record SIMNOEXTARG end SIMNOEXTARG;
  end SimExtArg;
  
  constant Context contextSimulationNonDiscrete;
  constant Context contextSimulationDiscrete;
  constant Context contextInlineSolver;
  constant Context contextFunction;
  constant Context contextOther;  

  function valueblockVars
    input DAE.Exp valueblock;
    output list<Variable> vars;
  end valueblockVars;
  
  function crefSubIsScalar
    input DAE.ComponentRef cref;
    output Boolean isScalar;
  end crefSubIsScalar;
	
  function crefNoSub
    input DAE.ComponentRef cref;
    output Boolean noSub;
  end crefNoSub;

  function crefIsScalar
    input DAE.ComponentRef cref;
		input Context context;
    output Boolean isScalar;
  end crefIsScalar;

  function crefSubs
    input DAE.ComponentRef cref;
    output list<DAE.Subscript> subs;
  end crefSubs;
  
  function buildCrefExpFromAsub
    input DAE.Exp cref;
    input list<DAE.Exp> subs;
    output DAE.Exp cRefOut;
  end buildCrefExpFromAsub;

  function incrementInt
    input Integer inInt;
    input Integer increment;
    output Integer outInt;
  end incrementInt;
 
  function decrementInt
    input Integer inInt;
    input Integer decrement;
    output Integer outInt;
  end decrementInt;

  function makeCrefRecordExp
    input DAE.ComponentRef inCRefRecord;
    input DAE.ExpVar inVar;
    output DAE.Exp outExp;
  end makeCrefRecordExp;
  
  
  function cref2simvar
    input DAE.ComponentRef cref;
    input SimCode simCode;
    output SimVar outSimVar;
  end cref2simvar;
  
  function derComponentRef
    input DAE.ComponentRef inCref;
    output DAE.ComponentRef derCref;
  end derComponentRef;

end SimCode;


package BackendDAE

  uniontype VarKind "- Variable kind"
    record VARIABLE end VARIABLE;
    record STATE end STATE;
    record STATE_DER end STATE_DER;
    record DUMMY_DER end DUMMY_DER;
    record DUMMY_STATE end DUMMY_STATE;
    record DISCRETE end DISCRETE;
    record PARAM end PARAM;
    record CONST end CONST;
    record EXTOBJ Absyn.Path fullClassName; end EXTOBJ;
  end VarKind;

  uniontype ZeroCrossing
    record ZERO_CROSSING
      DAE.Exp relation_;
    end ZERO_CROSSING;
  end ZeroCrossing;

  uniontype ReinitStatement
    record REINIT
      DAE.ComponentRef stateVar;
      DAE.Exp value;

    end REINIT;
    record EMPTY_REINIT end EMPTY_REINIT;
  end ReinitStatement;

  uniontype WhenEquation
    record WHEN_EQ
      Integer index;
      DAE.ComponentRef left;
      DAE.Exp right;
      Option<WhenEquation> elsewhenPart;
    end WHEN_EQ;
  end WhenEquation;
  
end BackendDAE;

package System

  function stringReplace
    input String str;
    input String source;
    input String target;
    output String res;
  end stringReplace;
  
  function tmpTick
    output Integer tickNo;
  end tmpTick;
  
  function tmpTickReset
    input Integer start;
  end tmpTickReset;

  function getCurrentTimeStr
    output String timeStr;
  end getCurrentTimeStr;

  function getUUIDStr 
    output String uuidStr;
  end getUUIDStr;

end System;


package Tpl
  function textFile
    input Text inText;
    input String inFileName;
  end textFile;
end Tpl;


package Absyn

  type Ident = String;
  
  uniontype Path
    record QUALIFIED
      Ident name;
      Path path;
    end QUALIFIED;
    record IDENT
      Ident name;
    end IDENT;
    record FULLYQUALIFIED
      Path path;
    end FULLYQUALIFIED;
  end Path;
  
  uniontype MatchType
    record MATCH end MATCH;
    record MATCHCONTINUE end MATCHCONTINUE;
  end MatchType;

end Absyn;


package DAE

  type Type = tuple<TType, Option<Absyn.Path>>;
  type Ident = String;

  uniontype ExpType
    record ET_INT end ET_INT;
    record ET_REAL end ET_REAL;
    record ET_BOOL end ET_BOOL;
    record ET_STRING end ET_STRING;
    record ET_ENUMERATION
      Absyn.Path path;
      list<String> names;
      list<ExpVar> varLst;
    end ET_ENUMERATION;
    record ET_COMPLEX
      Absyn.Path name;
      list<ExpVar> varLst; 
      ClassInf.State complexClassType;
    end ET_COMPLEX;
    record ET_OTHER end ET_OTHER;
    record ET_ARRAY
      ExpType ty;
      list<DAE.Dimension> arrayDimensions;
    end ET_ARRAY;
    record ET_LIST
      ExpType ty;
    end ET_LIST;
    record ET_METATUPLE
      list<ExpType> ty;
    end ET_METATUPLE;
    record ET_METAOPTION
      ExpType ty;
    end ET_METAOPTION;
    record ET_FUNCTION_REFERENCE_VAR end ET_FUNCTION_REFERENCE_VAR;
    record ET_FUNCTION_REFERENCE_FUNC
      Boolean builtin;
    end ET_FUNCTION_REFERENCE_FUNC;
    record ET_UNIONTYPE end ET_UNIONTYPE;
    record ET_BOXED
      ExpType ty;
    end ET_BOXED;
    record ET_POLYMORPHIC end ET_POLYMORPHIC;
    record ET_META_ARRAY
      ExpType ty;
    end ET_META_ARRAY;
    record ET_NORETCALL end ET_NORETCALL;
  end ExpType;

  uniontype ExpVar
    record COMPLEX_VAR
      String name;
      ExpType tp;
    end COMPLEX_VAR;
  end ExpVar;

  uniontype Exp
    record ICONST
      Integer integer;
    end ICONST;
    record RCONST
      Real real;
    end RCONST;
    record SCONST
      String string;
    end SCONST;
    record BCONST
      Boolean bool;
    end BCONST;
    record ENUM_LITERAL
      Absyn.Path name;
      Integer index;
    end ENUM_LITERAL;
    record CREF
      ComponentRef componentRef;
      ExpType ty;
    end CREF;
    record BINARY
      Exp exp1;
      Operator operator;
      Exp exp2; 
    end BINARY;
    record UNARY
      Operator operator;
      Exp exp; 
    end UNARY;
    record LBINARY
      Exp exp1;
      Operator operator;
      Exp exp2; 
    end LBINARY;
    record LUNARY
      Operator operator;
      Exp exp; 
    end LUNARY;
    record RELATION
      Exp exp1;
      Operator operator;
      Exp exp2; 
    end RELATION;
    record IFEXP
      Exp expCond;
      Exp expThen;
      Exp expElse;
    end IFEXP;
    record CALL
      Absyn.Path path;
      list<Exp> expLst;
      Boolean tuple_;
      Boolean builtin;
      ExpType ty;
    end CALL;
    record ARRAY
      ExpType ty;
      Boolean scalar;
      list<Exp> array;
    end ARRAY;
    record MATRIX
      ExpType ty;
      Integer integer;
      list<list<tuple<Exp, Boolean>>> scalar;
    end MATRIX;
    record RANGE
      ExpType ty;
      Exp exp;
      Option<Exp> expOption;
      Exp range;
    end RANGE;
    record TUPLE
      list<Exp> PR;
    end TUPLE;
    record CAST
      ExpType ty;
      Exp exp;
    end CAST;
    record ASUB
      Exp exp;
      list<Exp> sub;
    end ASUB;
    record SIZE
      Exp exp;
      Option<Exp> sz;
    end SIZE;
    record CODE
      Absyn.CodeNode code;
      ExpType ty;
    end CODE;
    record REDUCTION
      Absyn.Path path;
      Exp expr;
      Ident ident;
      Exp range;
    end REDUCTION;
    record END end END;
    record VALUEBLOCK
      ExpType ty;
      list<Element> localDecls;
      list<Statement> body;
      Exp result;	
    end VALUEBLOCK;  
    record LIST
      ExpType ty;
      list<Exp> valList;
    end LIST;
    record CONS
      ExpType ty;
      Exp car;
      Exp cdr;
    end CONS;
    record META_TUPLE
      list<Exp> listExp;
    end META_TUPLE;
    record META_OPTION
      Option<Exp> exp;
    end META_OPTION;
    record METARECORDCALL
      Absyn.Path path;
      list<Exp> args;
      list<String> fieldNames;
      Integer index;
    end METARECORDCALL;
  end Exp;
  
  uniontype ComponentRef
    record CREF_QUAL
      Ident ident;
      ExpType identType;
      list<Subscript> subscriptLst;
      ComponentRef componentRef;
    end CREF_QUAL;
    record CREF_IDENT
      Ident ident;
      ExpType identType;
      list<Subscript> subscriptLst;
    end CREF_IDENT;
    record WILD end WILD;
  end ComponentRef;

  uniontype Operator
    record ADD
      ExpType ty;
    end ADD;
    record SUB
      ExpType ty;
    end SUB;
    record MUL
      ExpType ty;
    end MUL;
    record DIV
      ExpType ty;
    end DIV;
    record POW
      ExpType ty;
    end POW;
    record UMINUS
      ExpType ty;
    end UMINUS;
    record UPLUS
      ExpType ty;
    end UPLUS;
    record UMINUS_ARR
      ExpType ty;
    end UMINUS_ARR;
    record UPLUS_ARR
      ExpType ty;
    end UPLUS_ARR;
    record ADD_ARR
      ExpType ty;
    end ADD_ARR;
    record SUB_ARR
      ExpType ty;
    end SUB_ARR;
    record MUL_ARR
      ExpType ty;
    end MUL_ARR;
    record DIV_ARR
      ExpType ty;
    end DIV_ARR;
    record MUL_SCALAR_ARRAY
      ExpType ty;
    end MUL_SCALAR_ARRAY;
    record MUL_ARRAY_SCALAR
      ExpType ty;
    end MUL_ARRAY_SCALAR;
    record ADD_SCALAR_ARRAY
      ExpType ty;
    end ADD_SCALAR_ARRAY;
    record ADD_ARRAY_SCALAR
      ExpType ty;
    end ADD_ARRAY_SCALAR;
    record SUB_SCALAR_ARRAY
      ExpType ty;
    end SUB_SCALAR_ARRAY;
    record SUB_ARRAY_SCALAR
      ExpType ty;
    end SUB_ARRAY_SCALAR;
    record MUL_SCALAR_PRODUCT
      ExpType ty;
    end MUL_SCALAR_PRODUCT;
    record MUL_MATRIX_PRODUCT
      ExpType ty;
    end MUL_MATRIX_PRODUCT;
    record DIV_ARRAY_SCALAR
      ExpType ty;
    end DIV_ARRAY_SCALAR;
    record DIV_SCALAR_ARRAY
      ExpType ty;
    end DIV_SCALAR_ARRAY;
    record POW_ARRAY_SCALAR
      ExpType ty;
    end POW_ARRAY_SCALAR;
    record POW_SCALAR_ARRAY
      ExpType ty;
    end POW_SCALAR_ARRAY;
    record POW_ARR
      ExpType ty;
    end POW_ARR;
    record POW_ARR2
      ExpType ty;
    end POW_ARR2;
    record AND end AND;
    record OR end OR;
    record NOT end NOT;
    record LESS
      ExpType ty;
    end LESS;
    record LESSEQ
      ExpType ty;
    end LESSEQ;
    record GREATER
      ExpType ty;
    end GREATER;
    record GREATEREQ
      ExpType ty;
    end GREATEREQ;
    record EQUAL
      ExpType ty;
    end EQUAL;
    record NEQUAL
      ExpType ty;
    end NEQUAL;
    record USERDEFINED
      Absyn.Path fqName;
    end USERDEFINED;
  end Operator;
  
  uniontype Statement
    record STMT_ASSIGN
      ExpType type_;
      Exp exp1;
      Exp exp;
      ElementSource source;
    end STMT_ASSIGN;
    record STMT_ASSIGN_ARR
      ExpType type_;
      ComponentRef componentRef;
      Exp exp;
      ElementSource source;
    end STMT_ASSIGN_ARR;
    record STMT_TUPLE_ASSIGN
      ExpType type_;
      list<Exp> expExpLst;
      Exp exp;
      ElementSource source;
    end STMT_TUPLE_ASSIGN;
    record STMT_IF
      Exp exp;
      list<Statement> statementLst;
      Else else_;
      ElementSource source;
    end STMT_IF;
    record STMT_FOR
      ExpType type_;
      Boolean iterIsArray;
      Ident ident;
      Exp exp;
      list<Statement> statementLst;
      ElementSource source;
    end STMT_FOR;
    record STMT_WHILE
      Exp exp;
      list<Statement> statementLst;
      ElementSource source;
    end STMT_WHILE;
    record STMT_WHEN
      Exp exp;
      list<Statement> statementLst;
      Option<Statement> elseWhen;
      list<Integer> helpVarIndices;
      ElementSource source;
    end STMT_WHEN;
    record STMT_ASSERT
      Exp cond;
      Exp msg;
      ElementSource source;
    end STMT_ASSERT;
    record STMT_RETURN
      ElementSource source;
    end STMT_RETURN;
    record STMT_MATCHCASES
      Absyn.MatchType matchType;
      list<Exp> inputExps;
      list<Exp> caseStmt;
      ElementSource source;
    end STMT_MATCHCASES;
    record STMT_BREAK
      ElementSource source;
    end STMT_BREAK;
    record STMT_FAILURE
      list<Statement> body;
      ElementSource source;
    end STMT_FAILURE;
    record STMT_TRY
      list<Statement> tryBody;
      ElementSource source;
    end STMT_TRY;
    record STMT_CATCH
      list<Statement> catchBody;
      ElementSource source;
    end STMT_CATCH;
    record STMT_THROW
      ElementSource source;
    end STMT_THROW;
    record STMT_NORETCALL
      Exp exp;
      ElementSource source;
    end STMT_NORETCALL;
  end Statement;

  uniontype Else
    record NOELSE end NOELSE;
    record ELSEIF
      Exp exp;
      list<Statement> statementLst;
      Else else_;
    end ELSEIF;
    record ELSE
      list<Statement> statementLst;
    end ELSE;
  end Else;

  uniontype Var
    record TYPES_VAR
      Ident name;
      Attributes attributes;
      Boolean protected_;
      Type type_;
      Binding binding;
    end TYPES_VAR;
  end Var;

  uniontype TType
    record T_INTEGER
      list<Var> varLstInt;
    end T_INTEGER;
    record T_REAL
      list<Var> varLstReal;
    end T_REAL;
    record T_STRING
      list<Var> varLstString;
    end T_STRING;
    record T_BOOL
      list<Var> varLstBool;
    end T_BOOL;
    record T_ARRAY
      Dimension arrayDim;
      Type arrayType;
    end T_ARRAY;
    record T_NORETCALL end T_NORETCALL;
    record T_NOTYPE end T_NOTYPE;
    record T_ANYTYPE
      Option<ClassInf.State> anyClassType;
    end T_ANYTYPE;
    record T_COMPLEX
      ClassInf.State complexClassType;
      list<Var> complexVarLst;
      Option<Type> complexTypeOption;
      EqualityConstraint equalityConstraint;
    end T_COMPLEX;
  end TType;

  uniontype Dimension
    record DIM_INTEGER
      Integer integer;
    end DIM_INTEGER;

    record DIM_ENUM
      Absyn.Path enumTypeName;
      list<String> literals;
      Integer size;
    end DIM_ENUM;

    record DIM_UNKNOWN
    end DIM_UNKNOWN;
  end Dimension;

  uniontype Subscript
    record WHOLEDIM end WHOLEDIM;
    record SLICE
      Exp exp;
    end SLICE;
    record INDEX
      Exp exp;
    end INDEX;
  end Subscript;

end DAE;


package ClassInf

  uniontype State
    record UNKNOWN
      String string;
    end UNKNOWN;
    record MODEL
      String string;
    end MODEL;
    record RECORD
        Absyn.Path path;
    end RECORD;
    record BLOCK
      String string;
    end BLOCK;
    record CONNECTOR
      String string;
      Boolean isExpandable;
    end CONNECTOR;
    record TYPE
      String string;
    end TYPE;
    record PACKAGE
      String string;
    end PACKAGE;
    record FUNCTION
      String string;
    end FUNCTION;
    record ENUMERATION
      String string;
    end ENUMERATION;
    record HAS_EQUATIONS
      String string;
    end HAS_EQUATIONS;
    record IS_NEW
      String string;
    end IS_NEW;
    record TYPE_INTEGER
      String string;
    end TYPE_INTEGER;
    record TYPE_REAL
      String string;
    end TYPE_REAL;
    record TYPE_STRING
      String string;
    end TYPE_STRING;
    record TYPE_BOOL
      String string;
    end TYPE_BOOL;
    record TYPE_ENUM
      String string;
    end TYPE_ENUM;
    record EXTERNAL_OBJ
      Absyn.Path path;
    end EXTERNAL_OBJ;
  end State;

end ClassInf;


package Util
  
	uniontype DateTime
	  record DATETIME
	    Integer sec;
	    Integer min;
	    Integer hour;
	    Integer mday;
	    Integer mon;
	    Integer year;
	  end DATETIME;
	end DateTime;  
  
  function escapeModelicaStringToCString
    input String modelicaString;
    output String cString;
  end escapeModelicaStringToCString;

	function getCurrentDateTime
	  output DateTime dt;
	end getCurrentDateTime;

end Util;


package Exp

	function crefHasScalarSubscripts
		input DAE.ComponentRef cr;
		output Boolean hasScalarSubs;
	end crefHasScalarSubscripts;

	function crefStripLastSubs
		input DAE.ComponentRef inComponentRef;
		output DAE.ComponentRef outComponentRef;
	end crefStripLastSubs;

  function getEnumIndexfromCref
    input DAE.ComponentRef inComponentRef;
    output Integer outEnumIndex;
  end getEnumIndexfromCref;

  function typeof
    input DAE.Exp inExp;
    output DAE.ExpType outType;
  end typeof;

end Exp;

package RTOpts
  function acceptMetaModelicaGrammar
    output Boolean outBoolean;
  end acceptMetaModelicaGrammar;
end RTOpts;

package Settings
  function getVersionNr
    output String outString;
  end getVersionNr;
end Settings;

//end SimCodeTV;

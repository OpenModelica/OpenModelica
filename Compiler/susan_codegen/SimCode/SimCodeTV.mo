interface package SimCodeTV 

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
      list<RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes;
      list<SimEqSystem> allEquations;
      list<SimEqSystem> allEquationsPlusWhen;
      list<SimEqSystem> odeEquations;
      list<SimEqSystem> algebraicEquations;
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
      list<DAE.ComponentRef> discreteModelVars2;
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
      list<DAE.ExpType> tys;
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
      list<Integer> values;
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
      list<BackendDAE.WhenOperator> reinits;
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
      AliasVariable aliasvar; 
    end SIMVAR;
  end SimVar;
  
  uniontype AliasVariable
    record NOALIAS end NOALIAS;
    record ALIAS 
      DAE.ComponentRef varName;
    end ALIAS;
    record NEGATEDALIAS 
      DAE.ComponentRef varName;
    end NEGATEDALIAS;
  end AliasVariable;
  
  uniontype Function
    record FUNCTION    
      Absyn.Path name;
      list<Variable> inVars;
      list<Variable> outVars;
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
    end EXTERNAL_FUNCTION;
    record RECORD_CONSTRUCTOR
      Absyn.Path name;
      list<Variable> funArgs;
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

  function elementVars
    input list<DAE.Element> ld;
    output list<Variable> vars;
  end elementVars;
  
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
  
  function hackArrayReverseToCref
    input DAE.Exp inExp;
    input Context context; 
    output DAE.Exp outExp;
  end hackArrayReverseToCref;

  function hackMatrixReverseToCref
    input DAE.Exp inExp;
    input Context context; 
    output DAE.Exp outExp;
  end hackMatrixReverseToCref;

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
  
  uniontype WhenOperator "- Reinit Statement"
    record REINIT
      DAE.ComponentRef stateVar "State variable to reinit" ;
      DAE.Exp value             "Value after reinit" ;
      DAE.ElementSource source "origin of equation";
    end REINIT;

    record ASSERT
      DAE.Exp condition;
      DAE.Exp message;
      DAE.ElementSource source "the origin of the component/equation/algorithm";
    end ASSERT;  
  
    record TERMINATE " The Modelica builtin terminate(msg)"
      DAE.Exp message;
      DAE.ElementSource source "the origin of the component/equation/algorithm";
    end TERMINATE; 
  end WhenOperator;

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
    record ET_METATYPE end ET_METATYPE;
    record ET_BOXED ExpType ty; end ET_BOXED;
    record ET_FUNCTION_REFERENCE_VAR end ET_FUNCTION_REFERENCE_VAR;
    record ET_FUNCTION_REFERENCE_FUNC
      Boolean builtin;
    end ET_FUNCTION_REFERENCE_FUNC;
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
    record MATCHEXPRESSION
      Absyn.MatchType matchType;
      list<Exp> inputs;
      list<Element> localDecls;
      list<MatchCase> cases;
      ExpType et;
    end MATCHEXPRESSION;
    record BOX
      Exp exp;
    end BOX;
    record UNBOX
      Exp exp;
      ExpType ty;
    end UNBOX;
  end Exp;
  
  uniontype MatchCase
    record CASE
      list<Pattern> patterns "ELSE is handled by not doing pattern-matching";
      list<Element> localDecls;
      list<Statement> body;
      Option<Exp> result;
    end CASE;
  end MatchCase;

  uniontype Pattern "Patterns deconstruct expressions"
    record PAT_WILD "_"
    end PAT_WILD;
    record PAT_CONSTANT "compare to this constant value using equality"
      Option<ExpType> ty "so we can unbox if needed";
      Exp exp;
    end PAT_CONSTANT;
    record PAT_AS "id as pat"
      String id;
      Option<ExpType> ty;
      Pattern pat;
    end PAT_AS;
    record PAT_AS_FUNC_PTR "id as pat"
      String id;
      Pattern pat;
    end PAT_AS_FUNC_PTR;
    record PAT_META_TUPLE "(pat1,...,patn)"
      list<Pattern> patterns;
    end PAT_META_TUPLE;
    record PAT_CALL_TUPLE "(pat1,...,patn)"
      list<Pattern> patterns;
    end PAT_CALL_TUPLE;
    record PAT_CONS "head::tail"
      Pattern head;
      Pattern tail;
    end PAT_CONS;
    record PAT_CALL "RECORD(pat1,...,patn); all patterns are positional"
      Absyn.Path name;
      Integer index;
      list<Pattern> patterns;
    end PAT_CALL;
    record PAT_CALL_NAMED "RECORD(pat1,...,patn); all patterns are named"
      Absyn.Path name;
      list<tuple<Pattern,String,ExpType>> patterns;
    end PAT_CALL_NAMED;
    record PAT_SOME "SOME(pat)"
      Pattern pat;
    end PAT_SOME;
  end Pattern;

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
    record STMT_ASSIGN_PATTERN "(x,1,ROOT(a as _,false,_)) := rhs; MetaModelica extension"
      Pattern lhs;
      Exp rhs;
      ElementSource source "the origin of the component/equation/algorithm";
    end STMT_ASSIGN_PATTERN;
    record STMT_IF
      Exp exp;
      list<Statement> statementLst;
      Else else_;
      ElementSource source;
    end STMT_IF;
    record STMT_FOR
      ExpType type_;
      Boolean iterIsArray;
      Ident iter;
      Exp range;
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
    record STMT_TERMINATE
      Exp msg;
      ElementSource source;
    end STMT_TERMINATE;  
    record STMT_ASSERT
      Exp cond;
      Exp msg;
      ElementSource source;
    end STMT_ASSERT;
    record STMT_REINIT
      Exp var;
      Exp value;
      ElementSource source;
    end STMT_REINIT;  
    record STMT_RETURN
      ElementSource source;
    end STMT_RETURN;
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

package SCode

type Ident = Absyn.Ident "Some definitions are borrowed from `Absyn\'";

type Path = Absyn.Path;

type Subscript = Absyn.Subscript;

uniontype Restriction
  record R_CLASS end R_CLASS;
  record R_OPTIMIZATION end R_OPTIMIZATION;
  record R_MODEL end R_MODEL;
  record R_RECORD end R_RECORD;
  record R_BLOCK end R_BLOCK;
  record R_CONNECTOR "a connector"
    Boolean isExpandable "is expandable?";
  end R_CONNECTOR;
  record R_OPERATOR "an operator definition"
    Boolean isFunction "is this operator a function?";
  end R_OPERATOR;
  record R_TYPE end R_TYPE;
  record R_PACKAGE end R_PACKAGE;
  record R_FUNCTION end R_FUNCTION;
  record R_EXT_FUNCTION "Added c.t. Absyn" end R_EXT_FUNCTION;
  record R_ENUMERATION end R_ENUMERATION;

  // predefined internal types
  record R_PREDEFINED_INTEGER     "predefined IntegerType" end R_PREDEFINED_INTEGER;
  record R_PREDEFINED_REAL        "predefined RealType"    end R_PREDEFINED_REAL;
  record R_PREDEFINED_STRING      "predefined StringType"  end R_PREDEFINED_STRING;
  record R_PREDEFINED_BOOLEAN     "predefined BooleanType" end R_PREDEFINED_BOOLEAN;
  record R_PREDEFINED_ENUMERATION "predefined EnumType"    end R_PREDEFINED_ENUMERATION;

  // MetaModelica extensions
  record R_METARECORD "Metamodelica extension"
    Absyn.Path name; //Name of the uniontype
    Integer index; //Index in the uniontype
  end R_METARECORD; /* added by x07simbj */

  record R_UNIONTYPE "Metamodelica extension"
  end R_UNIONTYPE; /* added by simbj */
end Restriction;

uniontype Mod "- Modifications"

  record MOD
    Boolean finalPrefix "final" ;
    Absyn.Each eachPrefix;
    list<SubMod> subModLst;
    Option<tuple<Absyn.Exp,Boolean>> absynExpOption "The binding expression of a modification
    has an expression and a Boolean delayElaboration which is true if elaboration(type checking)
    should be delayed. This can for instance be used when having A a(x = a.y) where a.y can not be
    type checked -before- a is instantiated, which is the current design in instantiation process.";
  end MOD;

  record REDECL
    Boolean finalPrefix       "final" ;
    list<Element> elementLst  "elements" ;
  end REDECL;

  record NOMOD end NOMOD;

end Mod;

uniontype SubMod "Modifications are represented in an more structured way than in
    the `Absyn\' module.  Modifications using qualified names
    (such as in `x.y =  z\') are normalized (to `x(y = z)\').  And a
    special case when arrays are subscripted in a modification.
"
  record NAMEMOD
    Ident ident;
    Mod A "A named component" ;
  end NAMEMOD;

  record IDXMOD
    list<Subscript> subscriptLst;
    Mod an "An array element" ;
  end IDXMOD;

end SubMod;

type Program = list<Class>;

uniontype Class "- Classes"
  record CLASS "the simplified SCode class"
    Ident name "the name of the class" ;
    Boolean partialPrefix "the partial prefix" ;
    Boolean encapsulatedPrefix "the encapsulated prefix" ;
    Restriction restriction "the restriction of the class" ;
    ClassDef classDef "the class specification" ;
    Absyn.Info info "the class information";
  end CLASS;
end Class;

uniontype Enum "Enum, which is a name in an enumeration and an optional Comment."
  record ENUM
    Ident           literal;
    Option<Comment> comment;
  end ENUM;
end Enum;

uniontype ClassDef
"The major difference between these types and their Absyn
 counterparts is that the PARTS constructor contains separate
 lists for elements, equations and algorithms.

 SCode.PARTS contains elements of a class definition. For instance,
    model A
      extends B;
      C c;
    end A;
 Here PARTS contains two elements ('extends B' and 'C c')
 SCode.DERIVED is used for short class definitions, i.e:
  class A = B(modifiers);
 SCode.CLASS_EXTENDS is used for extended class definition, i.e:
  class extends A (modifier)
    new elements;
  end A;"
  record PARTS "a class made of parts"
    list<Element>              elementLst          "the list of elements";
    list<Equation>             normalEquationLst   "the list of equations";
    list<Equation>             initialEquationLst  "the list of initial equations";
    list<AlgorithmSection>     normalAlgorithmLst  "the list of algorithms";
    list<AlgorithmSection>     initialAlgorithmLst "the list of initial algorithms";
    Option<Absyn.ExternalDecl> externalDecl        "used by external functions" ;
    list<Annotation>           annotationLst       "the list of annotations found in between class elements, equations and algorithms";
    Option<Comment>            comment             "the class comment";
  end PARTS;

  record CLASS_EXTENDS "an extended class definition plus the additional parts"
    Ident            baseClassName       "the name of the base class we have to extend";
    Mod              modifications       "the modifications that need to be applied to the base class";
    list<Element>    elementLst          "the list of elements";
    list<Equation>   normalEquationLst   "the list of equations";
    list<Equation>   initialEquationLst  "the list of initial equations";
    list<AlgorithmSection>  normalAlgorithmLst  "the list of algorithms";
    list<AlgorithmSection>  initialAlgorithmLst "the list of initial algorithms";
    list<Annotation> annotationLst       "the list of annotations found in between class elements, equations and algorithms";
    Option<Comment>  comment             "the class comment";
  end CLASS_EXTENDS;

  record DERIVED "a derived class"
    Absyn.TypeSpec typeSpec "typeSpec: type specification" ;
    Mod modifications;
    Absyn.ElementAttributes attributes;
    Option<Comment> comment "the translated comment from the Absyn";
  end DERIVED;

  record ENUMERATION "an enumeration"
    list<Enum> enumLst "if the list is empty it means :, the supertype of all enumerations";
    Option<Comment> comment "the translated comment from the Absyn";
  end ENUMERATION;

  record OVERLOAD "an overloaded function"
    list<Absyn.Path> pathLst;
    Option<Comment> comment "the translated comment from the Absyn";
  end OVERLOAD;

  record PDER "the partial derivative"
    Absyn.Path  functionPath "function name" ;
    list<Ident> derivedVariables "derived variables" ;
    Option<Comment> comment "the Absyn comment";
  end PDER;

end ClassDef;

uniontype Comment

  record COMMENT
    Option<Annotation> annotation_;
    Option<String> comment;
  end COMMENT;

  record CLASS_COMMENT
    list<Annotation> annotations;
    Option<Comment> comment;
  end CLASS_COMMENT;
end Comment;

uniontype Annotation

  record ANNOTATION
    Mod modification;
  end ANNOTATION;

end Annotation;

uniontype Equation "- Equations"
  record EQUATION "an equation"
    EEquation eEquation "an equation";
  end EQUATION;

end Equation;

uniontype EEquation
"These represent equations and are almost identical to their Absyn versions.
 In EQ_IF the elseif branches are represented as normal else branches with
 a single if statement in them."
  record EQ_IF
    list<Absyn.Exp> condition "conditional" ;
    list<list<EEquation>> thenBranch "the true (then) branch" ;
    list<EEquation>       elseBranch "the false (else) branch" ;
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_IF;

  record EQ_EQUALS "the equality equation"
    Absyn.Exp expLeft  "the expression on the left side of the operator";
    Absyn.Exp expRight "the expression on the right side of the operator";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_EQUALS;

  record EQ_CONNECT "the connect equation"
    Absyn.ComponentRef crefLeft  "the connector/component reference on the left side";
    Absyn.ComponentRef crefRight "the connector/component reference on the right side";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_CONNECT;

  record EQ_FOR "the for equation"
    Ident           index        "the index name";
    Absyn.Exp       range        "the range of the index";
    list<EEquation> eEquationLst "the equation list";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_FOR;

  record EQ_WHEN "the when equation"
    Absyn.Exp        condition "the when condition";
    list<EEquation>  eEquationLst "the equation list";
    list<tuple<Absyn.Exp, list<EEquation>>> tplAbsynExpEEquationLstLst "the elsewhen expression and equation list";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_WHEN;

  record EQ_ASSERT "the assert equation"
    Absyn.Exp condition "the assert condition";
    Absyn.Exp message   "the assert message";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_ASSERT;

  record EQ_TERMINATE "the terminate equation"
    Absyn.Exp message "the terminate message";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_TERMINATE;

  record EQ_REINIT "a reinit equation"
    Absyn.ComponentRef cref      "the variable to initialize";
    Absyn.Exp          expReinit "the new value" ;
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_REINIT;

  record EQ_NORETCALL "function calls without return value"
    Absyn.ComponentRef functionName "the function nanme";
    Absyn.FunctionArgs functionArgs "the function arguments";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_NORETCALL;

end EEquation;

uniontype AlgorithmSection "- Algorithms
  The Absyn module uses the terminology from the
  grammar, where algorithm means an algorithmic
  statement. But here, an Algorithm means a whole
  algorithm section."
  record ALGORITHM "the algorithm section"
    list<Statement> statements "the algorithm statements" ;
  end ALGORITHM;

end AlgorithmSection;

uniontype Statement "The Statement type describes one algorithm statement in an algorithm section."
  record ALG_ASSIGN
    Absyn.Exp assignComponent "assignComponent" ;
    Absyn.Exp value "value" ;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_ASSIGN;

  record ALG_IF
    Absyn.Exp boolExpr;
    list<Statement> trueBranch;
    list<tuple<Absyn.Exp, list<Statement>>> elseIfBranch;
    list<Statement> elseBranch;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_IF;

  record ALG_FOR
    Absyn.ForIterators iterators;
    list<Statement> forBody "forBody" ;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_FOR;

  record ALG_WHILE
    Absyn.Exp boolExpr "boolExpr" ;
    list<Statement> whileBody "whileBody" ;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_WHILE;

  record ALG_WHEN_A
    list<tuple<Absyn.Exp, list<Statement>>> branches;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_WHEN_A;

  record ALG_NORETCALL
    Absyn.ComponentRef functionCall "functionCall" ;
    Absyn.FunctionArgs functionArgs "functionArgs; general fcalls without return value" ;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_NORETCALL;

  record ALG_RETURN
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_RETURN;

  record ALG_BREAK
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_BREAK;

  // Part of MetaModelica extension. KS
  record ALG_TRY
    list<Statement> tryBody;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_TRY;

  record ALG_CATCH
    list<Statement> catchBody;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_CATCH;

  record ALG_THROW
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_THROW;

  record ALG_MATCHCASES
    Absyn.MatchType matchType;
    list<Absyn.Exp> inputExps;
    list<Absyn.Exp> switchCases;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_MATCHCASES;

  record ALG_GOTO
    String labelName;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_GOTO;

  record ALG_LABEL
    String labelName;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_LABEL;

  record ALG_FAILURE
    list<Statement> stmts;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_FAILURE;
  //-------------------------------

end Statement;

uniontype Element "- Elements
  There are four types of elements in a declaration, represented by the constructors:
  EXTENDS   (for extends clauses),
  CLASSDEF  (for local class definitions)
  COMPONENT (for local variables). and
  IMPORT    (for import clauses)
  The baseclass name is initially NONE() in the translation,
  and if an element is inherited from a base class it is
  filled in during the instantiation process."
  record EXTENDS "the extends element"
    Path baseClassPath "the extends path";
    Mod modifications  "the modifications applied to the base class";
    Option<Annotation> annotation_;
  end EXTENDS;

  record CLASSDEF "a local class definition"
    Ident   name               "the name of the local class" ;
    Boolean finalPrefix        "final prefix" ;
    Boolean replaceablePrefix  "replaceable prefix" ;
    Class   classDef           "the class definition" ;
    Option<Absyn.ConstrainClass> cc;
  end CLASSDEF;

  record IMPORT "an import element"
    Absyn.Import imp "the import definition";
  end IMPORT;

  record COMPONENT "a component"
    Ident component               "the component name" ;
    Absyn.InnerOuter innerOuter   "the inner/outer/innerouter prefix";
    Boolean finalPrefix           "the final prefix" ;
    Boolean replaceablePrefix     "the replaceable prefix" ;
    Boolean protectedPrefix       "the protected prefix" ;
    Attributes attributes         "the component attributes";
    Absyn.TypeSpec typeSpec       "the type specification" ;
    Mod modifications             "the modifications to be applied to the component";
    Option<Comment> comment       "this if for extraction of comments and annotations from Absyn";
    Option<Absyn.Exp> condition   "the conditional declaration of a component";
    Option<Absyn.Info> info       "this is for line and column numbers, also file name.";
    Option<Absyn.ConstrainClass> cc "The constraining class for the component";
  end COMPONENT;

  record DEFINEUNIT "a unit defintion has a name and the two optional parameters exp, and weight"
    Ident name;
    Option<String> exp;
    Option<Real> weight;
  end DEFINEUNIT;
end Element;

uniontype Attributes "- Attributes"
  record ATTR "the attributes of the component"
    Absyn.ArrayDim arrayDims "the array dimensions of the component";
    Boolean flowPrefix "the flow prefix" ;
    Boolean streamPrefix "the stream prefix" ;
    Accessibility accesibility "the accesibility of the component: RW (read/write), RO (read only), WO (write only)" ;
    Variability variability " the variability: parameter, discrete, variable, constant" ;
    Absyn.Direction direction "the direction: input, output or bidirectional" ;
  end ATTR;
end Attributes;

uniontype Variability "the variability of a component"
  record VAR      "a variable"          end VAR;
  record DISCRETE "a discrete variable" end DISCRETE;
  record PARAM    "a parameter"         end PARAM;
  record CONST    "a constant"          end CONST;
end Variability;

uniontype Accessibility "These are attributes that apply to a declared component."
  record RW "read/write" end RW;
  record RO "read-only" end RO;
  record WO "write-only (not used)" end WO;
end Accessibility;

uniontype Initial "the initial attribute of an algorithm or equation
 Intial is used as argument to instantiation-function for
 specifying if equations or algorithms are initial or not."
  record INITIAL "an initial equation or algorithm" end INITIAL;
  record NON_INITIAL "a normal equation or algorithm" end NON_INITIAL;
end Initial;

end SCode;

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


package ComponentReference

	function crefStripLastSubs
		input DAE.ComponentRef inComponentRef;
		output DAE.ComponentRef outComponentRef;
	end crefStripLastSubs;

  function crefSubs
    input DAE.ComponentRef cref;
    output list<DAE.Subscript> subs;
  end crefSubs;

end ComponentReference;

package Expression

	function crefHasScalarSubscripts
		input DAE.ComponentRef cr;
		output Boolean hasScalarSubs;
	end crefHasScalarSubscripts;

  function typeof
    input DAE.Exp inExp;
    output DAE.ExpType outType;
  end typeof;

end Expression;

package ExpressionDump
  function printExpStr
    input DAE.Exp e;
    output String s;
  end printExpStr;
end ExpressionDump;

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

end SimCodeTV;

package SimCode

  function listLengthStr
    input list<String> lst;
    output Integer len;
  end listLengthStr;
  
  function listLengthSimVar
    input list<SimVar> lst;
    output Integer len;
  end listLengthSimVar;
  
  type Path = Absyn.Path;
  type Ident = String;
  type Type = DAE.ExpType;
  type HelpVarInfo = tuple<Integer, DAE.Exp, Integer>;
  
  type Variables = list<Variable>;
  type Statements = list<Statement>;
  type FunctionArguments = Variables;
  type FunctionBody = list<Statement>;
  type VariableDeclarations = Variables;
  
  uniontype Variable
    record VARIABLE
      String name;
      Type ty;
      Option<DAE.Exp> value;
    end VARIABLE;  
  end Variable;
  
  uniontype Statement
    record ALGORITHM
       list<DAE.Statement> statementLst;
    end ALGORITHM;
    record BLOCK
      VariableDeclarations variableDeclarations;
      FunctionBody body;
    end BLOCK;
  end Statement;
  
  uniontype SimCode
    record SIMCODE
      ModelInfo modelInfo;
      list<Function> functions;
      list<SimEqSystem> stateEquations;
      list<SimEqSystem> nonStateContEquations;
      list<SimEqSystem> nonStateDiscEquations;
      list<SimEqSystem> residualEquations;
      list<SimEqSystem> initialEquations;
      list<SimEqSystem> parameterEquations;
      list<SimEqSystem> removedEquations;
      list<DAELow.ZeroCrossing> zeroCrossings;
      list<list<DAE.ComponentRef>> zeroCrossingsNeedSave;
      list<HelpVarInfo> helpVarInfo;
      list<SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
    end SIMCODE;
  end SimCode;
  
  uniontype SimEqSystem
    record SES_RESIDUAL
      DAE.Exp exp;
    end SES_RESIDUAL;
    record SES_SIMPLE_ASSIGN
      DAE.ComponentRef componentRef;
      DAE.Exp exp;
    end SES_SIMPLE_ASSIGN;
  end SimEqSystem;

  uniontype SimWhenClause
    record SIM_WHEN_CLAUSE
      list<DAE.ComponentRef> conditionVars;
      list<DAELow.ReinitStatement> reinits;
      Option<DAELow.WhenEquation> whenEq;
    end SIM_WHEN_CLAUSE;
  end SimWhenClause;

  uniontype ModelInfo
    record MODELINFO
      String name;
      String directory;
      VarInfo varInfo;
      SimVars vars;
    end MODELINFO;
  end ModelInfo;
  
  uniontype VarInfo
    record VARINFO
      Integer numHelpVars;
      Integer numZeroCrossings;
      Integer numStateVars;
      Integer numAlgVars;
      Integer numParams;
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
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> paramVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> extObjVars;
    end SIMVARS;
  end SimVars;
  
  uniontype SimVar
    record SIMVAR
      DAE.ComponentRef name;
      DAE.ComponentRef origName;
      String comment;
      Integer index;
      Boolean isFixed;
      DAE.ExpType type_;
      Boolean isDiscrete;
    end SIMVAR;
  end SimVar;
  
  uniontype TargetSettings
    record TS_C
      String CCompiler;
      String CXXCompiler;
      String linker;
    end TS_C;
  end TargetSettings;
  
  uniontype Function
    record FUNCTION    
      Path name;
      Variables inVars;
      Variables outVars;
      list<RecordDeclaration> recordDecls; 
      FunctionArguments functionArguments;
      VariableDeclarations variableDeclarations;
      FunctionBody body;
    end FUNCTION;
    record EXTERNAL_FUNCTION
      FunctionName functionName;
      FunctionArguments functionArguments;
      VariableDeclarations variableDeclarations;
      Includes includes;
      Libs libs;
      String language;
    end EXTERNAL_FUNCTION;
  end Function;
  
  uniontype RecordDeclaration
    record RECORD_DECL_FULL
      Ident name;
      Path defPath;
      Variables variables;
    end RECORD_DECL_FULL;
    record RECORD_DECL_DEF
      Path path;
      list<Ident> fieldNames;
    end RECORD_DECL_DEF;
  end RecordDeclaration;

end SimCode;


package DAELow

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

end DAELow;

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
      Option<Integer> index;
      Absyn.Path path;
      list<String> names;
      list<ExpVar> varLst;
    end ET_ENUMERATION;
    record ET_COMPLEX
      String name;
      list<ExpVar> varLst; 
      ClassInf.State complexClassType;
    end ET_COMPLEX;
    record ET_OTHER end ET_OTHER;
    record ET_ARRAY
      ExpType ty;
      list<Option<Integer>> arrayDimensions;
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
    record ET_FUNCTION_REFERENCE_FUNC end ET_FUNCTION_REFERENCE_FUNC;
    record ET_UNIONTYPE end ET_UNIONTYPE;
    record ET_BOXED
      ExpType ty;
    end ET_BOXED;
    record ET_POLYMORPHIC end ET_POLYMORPHIC;
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
      Element body;
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
    end STMT_ASSIGN;
    record STMT_IF
      Exp exp;
      list<Statement> statementLst;
      Else else_;
    end STMT_IF;
    record STMT_FOR
      ExpType type_;
      Boolean boolean;
      Ident ident;
      Exp exp;
      list<Statement> statementLst;
    end STMT_FOR;
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
      ArrayDim arrayDim;
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

  uniontype ArrayDim
    record DIM
      Option<Integer> integerOption;
    end DIM;
  end ArrayDim;

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
      String string;
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
      Absyn.Path fullClassName;
    end EXTERNAL_OBJ;
  end State;

end ClassInf;


package Util
  
  function escapeModelicaStringToCString
    input String modelicaString;
    output String cString;
  end escapeModelicaStringToCString;

end Util;

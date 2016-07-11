interface package GraphvizDumpTV

  package builtin
    function intGt
      input Integer a;
      input Integer b;
      output Boolean c;
    end intGt;

    function arrayList
      replaceable type TypeVar subtypeof Any;
      input array<TypeVar> arr;
      output list<TypeVar> lst;
    end arrayList;

    function arrayGet "Extract (indexed access) an array element from the array"
      input array<Type_a> inVec;
      output Type_a outElement;
      replaceable type Type_a subtypeof Any;
    end arrayGet;

    function listGet "
      Return the element of the list at the given index.
      The index starts from 1."
      replaceable type TypeVar subtypeof Any;
      input list<TypeVar> lst;
      input Integer index;
      output TypeVar result;
    end listGet;

    function intEq "Integer equality comparison"
      input Integer i1;
      input Integer i2;
      output Boolean result;
    end intEq;

    function intString "Integer to String conversion"
      input Integer i;
      output String result;
    end intString;
  end builtin;

  package ExpressionDump
    function printExpStr
      input DAE.Exp e;
      output String s;
    end printExpStr;
    function printCrefsFromExpStr
      input DAE.Exp e;
      output String s;
    end printCrefsFromExpStr;
  end ExpressionDump;

  package BackendDAE
    uniontype BackendDAE
      record DAE
        EqSystems eqs;
        Shared shared;
      end DAE;
    end BackendDAE;

    type EqSystems = list<EqSystem>;

    uniontype EqSystem
      record EQSYSTEM
        Variables orderedVars;
        EquationArray orderedEqs;
        Option<IncidenceMatrix> m;
        Option<IncidenceMatrixT> mT;
        Matching matching;
        StateSets stateSets;
      end EQSYSTEM;
    end EqSystem;

    uniontype Matching
      record NO_MATCHING
      end NO_MATCHING;

      record MATCHING
        array<Integer> ass1 "ass[varindx]=eqnindx";
        array<Integer> ass2 "ass[eqnindx]=varindx";
        StrongComponents comps;
      end MATCHING;
    end Matching;

    type StrongComponents = list<StrongComponent> "Order of the equations the have to be solved" ;

    uniontype StrongComponent
      record SINGLEEQUATION
        Integer eqn;
        Integer var;
      end SINGLEEQUATION;

      record EQUATIONSYSTEM
        list<Integer> eqns;
        list<Integer> vars "be careful with states, this are solved for der(x)";
        Jacobian jac;
        JacobianType jacType;
        Boolean mixedSystem "true for system that discrete dependencies to the iteration variables";
      end EQUATIONSYSTEM;

      record SINGLEARRAY
        Integer eqn;
        list<Integer> vars "be careful with states, this are solved for der(x)";
      end SINGLEARRAY;

      record SINGLEALGORITHM
        Integer eqn;
        list<Integer> vars "be careful with states, this are solved for der(x)";
      end SINGLEALGORITHM;

      record SINGLECOMPLEXEQUATION
        Integer eqn;
        list<Integer> vars "be careful with states, this are solved for der(x)";
      end SINGLECOMPLEXEQUATION;

      record SINGLEWHENEQUATION
        Integer eqn;
        list<Integer> vars "be careful with states, this are solved for der(x)";
      end SINGLEWHENEQUATION;

      record SINGLEIFEQUATION
        Integer eqn;
        list<Integer> vars "be careful with states, this are solved for der(x)";
      end SINGLEIFEQUATION;

      record TORNSYSTEM
        TearingSet strictTearingSet;
        Option<TearingSet> casualTearingSet;
        Boolean linear;
        Boolean mixedSystem "true for system that discrete dependencies to the iteration variables";
      end TORNSYSTEM;
    end StrongComponent;

    uniontype Jacobian
      record FULL_JACOBIAN
        FullJacobian jacobian;
      end FULL_JACOBIAN;

      record GENERIC_JACOBIAN
        SymbolicJacobian jacobian;
        SparsePattern sparsePattern;
        SparseColoring coloring;
      end GENERIC_JACOBIAN;

      record EMPTY_JACOBIAN end EMPTY_JACOBIAN;
    end Jacobian;

    type SymbolicJacobians = list<tuple<Option<SymbolicJacobian>, SparsePattern, SparseColoring>>;
    type FullJacobian = Option<list<tuple<Integer, Integer, Equation>>>;
    type SymbolicJacobian = tuple<BackendDAE,               // symbolic equation system
                                  String,                   // Matrix name
                                  list<Var>,                // diff vars
                                  list<Var>,                // result diffed equation
                                  list<Var>                 // all diffed equation
                                  >;
    type SparsePattern = tuple<list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>>,   // column-wise sparse pattern
                               list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>>,   // row-wise sparse pattern
                               tuple<list<DAE.ComponentRef>,                            // diff vars
                                     list<DAE.ComponentRef>>>;                          // diffed vars
    type SparseColoring = list<list<DAE.ComponentRef>>;

    type IncidenceMatrixElementEntry = Integer;
    type IncidenceMatrixElement = list<IncidenceMatrixElementEntry>;
    type IncidenceMatrix = array<IncidenceMatrixElement>;
    type IncidenceMatrixT = IncidenceMatrix;

    uniontype Shared
      record SHARED
        Variables knownVars                  "Known variables, i.e. constants and parameters" ;
        Variables externalObjects            "External object variables";
        Variables aliasVars                  "Data originating from removed simple equations needed to build
                                              variables' lookup table (in C output).

                                              In that way, double buffering of variables in pre()-buffer, extrapolation
                                              buffer and results caching, etc., is avoided, but in C-code output all the
                                              data about variables' names, comments, units, etc. is preserved as well as
                                              pinter to their values (trajectories).";
        EquationArray initialEqs             "Initial equations" ;
        EquationArray removedEqs             "these are equations that cannot solve for a variable. for example assertions, external function calls, algorithm sections without effect" ;
        list<DAE.Constraint> constraints     "constraints (Optimica extension)";
        list<DAE.ClassAttributes> classAttrs "class attributes (Optimica extension)";
        FCore.Cache cache;
        FCore.Graph env;
        DAE.FunctionTree functionTree        "functions for Backend";
        EventInfo eventInfo                  "eventInfo" ;
        ExternalObjectClasses extObjClasses  "classes of external objects, contains constructor & destructor";
        BackendDAEType backendDAEType        "indicate for what the BackendDAE is used";
        SymbolicJacobians symjacs            "Symbolic Jacobians";
        ExtraInfo info                       "contains extra info that we send around like the model name";
      end SHARED;
    end Shared;

    uniontype ExtraInfo "extra information that we should send arround with the DAE"
      record EXTRA_INFO
        String fileNamePrefix "the model name to be used in the dumps";
      end EXTRA_INFO;
    end ExtraInfo;

    uniontype Variables
      record VARIABLES
        array<list<CrefIndex>> crefIdxLstArr "HashTB, cref->indx";
        VariableArray varArr "Array of variables";
        Integer bucketSize "bucket size";
        Integer numberOfVars "no. of vars";
      end VARIABLES;
    end Variables;

    uniontype Var "variables"
      record VAR
        DAE.ComponentRef varName "variable name" ;
        VarKind varKind "Kind of variable" ;
        DAE.VarDirection varDirection "input, output or bidirectional" ;
        DAE.VarParallelism varParallelism "parallelism of the variable. parglobal, parlocal or non-parallel";
        DAE.Type varType "builtin type or enumeration" ;
        Option<DAE.Exp> bindExp "Binding expression e.g. for parameters" ;
        Option<Values.Value> bindValue "binding value for parameters" ;
        DAE.InstDims arryDim "array dimensions on nonexpanded var" ;
        DAE.ElementSource source "origin of variable" ;
        Option<DAE.VariableAttributes> values "values on builtin attributes" ;
        Option<SCode.Comment> comment "this contains the comment and annotation from Absyn" ;
        DAE.ConnectorType connectorType "flow, stream, unspecified or not connector.";
      end VAR;
    end Var;

    uniontype VarKind "- Variabile kind"
      record VARIABLE end VARIABLE;
      record STATE
        Integer index;
        Option<DAE.ComponentRef> derName;
      end STATE;
      record STATE_DER end STATE_DER;
      record DUMMY_DER end DUMMY_DER;
      record DUMMY_STATE end DUMMY_STATE;
      record DISCRETE end DISCRETE;
      record PARAM end PARAM;
      record CONST end CONST;
      record EXTOBJ Absyn.Path fullClassName; end EXTOBJ;
      record JAC_VAR end JAC_VAR;
      record JAC_DIFF_VAR end JAC_DIFF_VAR;
    end VarKind;

    uniontype ZeroCrossing
      record ZERO_CROSSING
        DAE.Exp relation_;
        list<Integer> occurEquLst;
        list<Integer> occurWhenLst;
      end ZERO_CROSSING;
    end ZeroCrossing;

    uniontype SampleLookup
      record SAMPLE_LOOKUP
        Integer nSamples                              "total number of different sample calls" ;
        list<tuple<Integer, DAE.Exp, DAE.Exp>> lookup "sample arguments (index, start, interval)" ;
      end SAMPLE_LOOKUP;
    end SampleLookup;

    uniontype WhenOperator "- Reinit Statement"
      record REINIT
        DAE.ComponentRef stateVar "State variable to reinit" ;
        DAE.Exp value             "Value after reinit" ;
        DAE.ElementSource source "origin of equation";
      end REINIT;

      record ASSERT
        DAE.Exp condition;
        DAE.Exp message;
        DAE.Exp level;
        DAE.ElementSource source "the origin of the component/equation/algorithm";
      end ASSERT;

      record TERMINATE " The Modelica builtin terminate(msg)"
        DAE.Exp message;
        DAE.ElementSource source "the origin of the component/equation/algorithm";
      end TERMINATE;

      record NORETCALL "call with no return value, i.e. no equation.
        Typically sideeffect call of external function but also
        Connections.* i.e. Connections.root(...) functions."
        Absyn.Path functionName;
        list<DAE.Exp> functionArgs;
        DAE.ElementSource source "the origin of the component/equation/algorithm";
      end NORETCALL;
    end WhenOperator;

    uniontype WhenEquation
      record WHEN_EQ
        Integer index;
        DAE.ComponentRef left;
        DAE.Exp right;
        Option<WhenEquation> elsewhenPart;
      end WHEN_EQ;
    end WhenEquation;

    uniontype EquationArray
      record EQUATION_ARRAY
        Integer size "size of the Equations in scalar form";
        Integer numberOfElement "no. elements" ;
        array<Option<Equation>> equOptArr;
      end EQUATION_ARRAY;
    end EquationArray;

    uniontype Equation
      record EQUATION
        DAE.Exp exp;
        DAE.Exp scalar;
        DAE.ElementSource source "origin of equation";
        Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
      end EQUATION;

      record ARRAY_EQUATION
        list<Integer> dimSize "dimension sizes" ;
        DAE.Exp left "lhs" ;
        DAE.Exp right "rhs" ;
        DAE.ElementSource source "the element source";
        Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
      end ARRAY_EQUATION;

      record SOLVED_EQUATION
        DAE.ComponentRef componentRef;
        DAE.Exp exp;
        DAE.ElementSource source "origin of equation";
        Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
      end SOLVED_EQUATION;

      record RESIDUAL_EQUATION
        DAE.Exp exp "not present from FrontEnd" ;
        DAE.ElementSource source "origin of equation";
         Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
      end RESIDUAL_EQUATION;

      record ALGORITHM
        Integer size "size of equation" ;
        DAE.Algorithm alg;
        DAE.ElementSource source "origin of algorithm";
        DAE.Expand expand "this algorithm was translated from an equation. we should not expand array crefs!";
      end ALGORITHM;

      record WHEN_EQUATION
        Integer size "size of equation";
        WhenEquation whenEquation;
        DAE.ElementSource source "origin of equation";
      end WHEN_EQUATION;

      record COMPLEX_EQUATION "complex equations: recordX = function call(x, y, ..);"
         Integer size "size of equation" ;
        DAE.Exp left "lhs" ;
        DAE.Exp right "rhs" ;
        DAE.ElementSource source "the element source";
         Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
      end COMPLEX_EQUATION;

      record IF_EQUATION "an if-equation"
        list< DAE.Exp> conditions "Condition";
        list<list<Equation>> eqnstrue "Equations of true branch";
        list<Equation> eqnsfalse "Equations of false branch";
        DAE.ElementSource source "origin of equation";
      end IF_EQUATION;
    end Equation;
  end BackendDAE;

  package BackendVariable
    function isStateVar
      input BackendDAE.Var inVar;
      output Boolean outBoolean;
    end isStateVar;

    function varList
      input BackendDAE.Variables inVariables;
      output list<BackendDAE.Var> outVarLst;
    end varList;
  end BackendVariable;

  package BackendEquation
    function equationList
      input BackendDAE.EquationArray inEquationArray;
      output list<BackendDAE.Equation> outEquationLst;
    end equationList;
  end BackendEquation;

  package BackendDump
    function equationString "Helper function to e.g. dump."
      input BackendDAE.Equation inEquation;
      output String outString;
    end equationString;
  end BackendDump;

  package DAE
    uniontype ComponentRef
      record CREF_QUAL
        Ident ident;
        Type identType;
        list<Subscript> subscriptLst;
        ComponentRef componentRef;
      end CREF_QUAL;
      record CREF_IDENT
        Ident ident;
        Type identType;
        list<Subscript> subscriptLst;
      end CREF_IDENT;
      record OPTIMICA_ATTR_INST_CREF
        ComponentRef componentRef;
        String instant;
      end OPTIMICA_ATTR_INST_CREF;
      record WILD end WILD;
    end ComponentRef;

    uniontype Type "models the different front-end and back-end types"
      record T_INTEGER
        list<Var> varLst;
        TypeSource source;
      end T_INTEGER;

      record T_REAL
        list<Var> varLst;
        TypeSource source;
      end T_REAL;

      record T_STRING
        list<Var> varLst;
        TypeSource source;
      end T_STRING;

      record T_BOOL
        list<Var> varLst;
        TypeSource source;
      end T_BOOL;

      record T_ENUMERATION "If the list of names is empty, this is the super-enumeration that is the super-class of all enumerations"
        Option<Integer> index "the enumeration value index, SOME for element, NONE() for type" ;
        Absyn.Path path "enumeration path" ;
        list<String> names "names" ;
        list<Var> literalVarLst;
        list<Var> attributeLst;
        TypeSource source;
      end T_ENUMERATION;

      record T_ARRAY
        "an array can be represented in two equivalent ways:
           1. T_ARRAY(non_array_type, {dim1, dim2, dim3}) =
           2. T_ARRAY(T_ARRAY(T_ARRAY(non_array_type, {dim1}), {dim2}), {dim3})
           In general Inst generates 1 and all the others generates 2"
        Type ty "Type";
        Dimensions dims "dims";
        TypeSource source;
      end T_ARRAY;

      record T_NORETCALL "For functions not returning any values."
        TypeSource source;
      end T_NORETCALL;

      record T_UNKNOWN "Used when type is not yet determined"
        TypeSource source;
      end T_UNKNOWN;

      record T_COMPLEX
        ClassInf.State complexClassType "The type of a class" ;
        list<Var> varLst "The variables of a complex type" ;
        EqualityConstraint equalityConstraint;
        TypeSource source;
      end T_COMPLEX;

      record T_SUBTYPE_BASIC
        ClassInf.State complexClassType "The type of a class" ;
        list<Var> varLst "complexVarLst; The variables of a complex type! Should be empty, kept here to verify!";
        Type complexType "complexType; A complex type can be a subtype of another (primitive) type (through extends)";
        EqualityConstraint equalityConstraint;
        TypeSource source;
      end T_SUBTYPE_BASIC;

      record T_FUNCTION
        list<FuncArg> funcArg "funcArg" ;
        Type funcResultType "Only single-result" ;
        FunctionAttributes functionAttributes;
        TypeSource source;
      end T_FUNCTION;

      record T_FUNCTION_REFERENCE_VAR "MetaModelica Function Reference that is a variable"
        Type functionType "the type of the function";
        TypeSource source;
      end T_FUNCTION_REFERENCE_VAR;

      record T_FUNCTION_REFERENCE_FUNC "MetaModelica Function Reference that is a direct reference to a function"
        Boolean builtin;
        Type functionType "type of the non-boxptr function";
        TypeSource source;
      end T_FUNCTION_REFERENCE_FUNC;

      record T_TUPLE
        list<Type> tupleType "For functions returning multiple values.";
        TypeSource source;
      end T_TUPLE;

      record T_CODE
        CodeType ty;
        TypeSource source;
      end T_CODE;

      record T_ANYTYPE
        Option<ClassInf.State> anyClassType "anyClassType - used for generic types. When class state present the type is assumed to be a complex type which has that restriction.";
        TypeSource source;
      end T_ANYTYPE;

      // MetaModelica extensions
      record T_METALIST "MetaModelica list type"
        Type listType "listType";
        TypeSource source;
      end T_METALIST;

      record T_METATUPLE "MetaModelica tuple type"
        list<Type> types;
        TypeSource source;
      end T_METATUPLE;

      record T_METAOPTION "MetaModelica option type"
        Type optionType;
        TypeSource source;
      end T_METAOPTION;

      record T_METAUNIONTYPE "MetaModelica Uniontype, added by simbj"
        list<Absyn.Path> paths;
        Boolean knownSingleton "The runtime system (dynload), does not know if the value is a singleton. But optimizations are safe if this is true.";
        TypeSource source;
      end T_METAUNIONTYPE;

      record T_METARECORD "MetaModelica Record, used by Uniontypes. added by simbj"
        Absyn.Path utPath "the path to its uniontype; this is what we match the type against";
        // If the metarecord constructor was added to the FunctionTree, this would
        // not be needed. They are used to create the datatype in the runtime...
        Integer index; //The index in the uniontype
        list<Var> fields;
        Boolean knownSingleton "The runtime system (dynload), does not know if the value is a singleton. But optimizations are safe if this is true.";
        TypeSource source;
      end T_METARECORD;

      record T_METAARRAY
        Type ty;
        TypeSource source;
      end T_METAARRAY;

      record T_METABOXED "Used for MetaModelica generic types"
        Type ty;
        TypeSource source;
      end T_METABOXED;

      record T_METAPOLYMORPHIC
        String name;
        TypeSource source;
      end T_METAPOLYMORPHIC;

      record T_METATYPE "this type contains all the meta types"
        Type ty;
        TypeSource source;
      end T_METATYPE;
    end Type;

    uniontype VariableAttributes
      record VAR_ATTR_REAL
        Option<Exp> quantity "quantity";
        Option<Exp> unit "unit";
        Option<Exp> displayUnit "displayUnit";
        Option<Exp> min;
        Option<Exp> max;
        Option<Exp> start "start value";
        Option<Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables";
        Option<Exp> nominal "nominal";
        Option<StateSelect> stateSelectOption;
        Option<Uncertainty> uncertainOption;
        Option<Distribution> distributionOption;
        Option<Exp> equationBound;
        Option<Boolean> isProtected;
        Option<Boolean> finalPrefix;
        Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
      end VAR_ATTR_REAL;

      record VAR_ATTR_INT
        Option<Exp> quantity "quantity";
        Option<Exp> min;
        Option<Exp> max;
        Option<Exp> start "start value";
        Option<Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables";
        Option<Uncertainty> uncertainOption;
        Option<Distribution> distributionOption;
        Option<Exp> equationBound;
        Option<Boolean> isProtected; // ,eb,ip
        Option<Boolean> finalPrefix;
        Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
      end VAR_ATTR_INT;

      record VAR_ATTR_BOOL
        Option<Exp> quantity "quantity";
        Option<Exp> start "start value";
        Option<Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables";
        Option<Exp> equationBound;
        Option<Boolean> isProtected;
        Option<Boolean> finalPrefix;
        Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
      end VAR_ATTR_BOOL;

      record VAR_ATTR_STRING
        Option<Exp> quantity "quantity";
        Option<Exp> start "start value";
        Option<Exp> equationBound;
        Option<Boolean> isProtected;
        Option<Boolean> finalPrefix;
        Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
      end VAR_ATTR_STRING;

      record VAR_ATTR_ENUMERATION
        Option<Exp> quantity "quantity";
        Option<Exp> min;
        Option<Exp> max;
        Option<Exp> start "start";
        Option<Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables";
        Option<Exp> equationBound;
        Option<Boolean> isProtected;
        Option<Boolean> finalPrefix;
        Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
      end VAR_ATTR_ENUMERATION;
    end VariableAttributes;
  end DAE;

  package Tpl
    function textFile
      input Text inText;
      input String inFileName;
    end textFile;

    function textFileConvertLines
      input Text inText;
      input String inFileName;
    end textFileConvertLines;

    //we do not import Error.addSourceMessage() directly
    //because of list creation in Susan is not possible (yet by design)
    function addSourceTemplateError
      "Wraps call to Error.addSourceMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken."
      input String inErrMsg;
      input SourceInfo inInfo;
    end addSourceTemplateError;

    //for completeness; although the addSourceTemplateError() above is preferable
    function addTemplateError
      "Wraps call to Error.addMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken."
      input String inErrMsg;
    end addTemplateError;
  end Tpl;
end GraphvizDumpTV;

interface package GraphvizDumpTV 

  package builtin
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
        list<Integer> vars "be carefule with states, this are solved for der(x)";
        Option<list<tuple<Integer, Integer, Equation>>> jac;
        JacobianType jacType;
      end EQUATIONSYSTEM;

      record MIXEDEQUATIONSYSTEM
        StrongComponent condSystem;
        list<Integer> disc_eqns;
        list<Integer> disc_vars;
      end MIXEDEQUATIONSYSTEM;

      record SINGLEARRAY
        Integer eqn;
        list<Integer> vars "be carefule with states, this are solved for der(x)";
      end SINGLEARRAY;

      record SINGLEALGORITHM
        Integer eqn;
        list<Integer> vars "be carefule with states, this are solved for der(x)";
      end SINGLEALGORITHM;

      record SINGLECOMPLEXEQUATION
        Integer eqn;
        list<Integer> vars "be carefule with states, this are solved for der(x)";
      end SINGLECOMPLEXEQUATION;

      record SINGLEWHENEQUATION
        Integer eqn;
        list<Integer> vars "be carefule with states, this are solved for der(x)";
      end SINGLEWHENEQUATION;

      record SINGLEIFEQUATION
        Integer eqn;
        list<Integer> vars "be carefule with states, this are solved for der(x)";
      end SINGLEIFEQUATION;

      record TORNSYSTEM
        list<Integer> tearingvars;
        list<Integer> residualequations;
        list<tuple<Integer,list<Integer>>> otherEqnVarTpl "list of tuples of indexes for Equation and Variable solved in the equation, in the order they have to be solved";
        Boolean linear;
      end TORNSYSTEM;
    end StrongComponent;
    
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
        Env.Cache cache;
        Env.Env env;
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
        Type varType "builtin type or enumeration" ;
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
        Integer arrSize "array size" ;
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
      input Absyn.Info inInfo;
    end addSourceTemplateError;
    
    //for completeness; although the addSourceTemplateError() above is preferable
    function addTemplateError
      "Wraps call to Error.addMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken."
      input String inErrMsg;  
    end addTemplateError;
  end Tpl;
end GraphvizDumpTV;

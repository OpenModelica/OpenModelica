interface package UnparsingTV

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
  
package Absyn

type Ident = String;
type ForIterator = tuple<Ident, Option<Exp>>;
type ForIterators = list<ForIterator>;

uniontype Program
  record PROGRAM  "PROGRAM, the top level construct"
    list<Class>  classes "List of classes" ;
    Within       within_ "Within clause" ;
    TimeStamp    globalBuildTimes "";
  end PROGRAM;
end Program;

uniontype Within "Within Clauses"
  record WITHIN "the within clause"
    Path path "the path for within";
  end WITHIN;

  record TOP end TOP;
end Within;

uniontype Info
  record INFO
    String fileName "fileName where the class is defined in" ;
    Boolean isReadOnly "isReadOnly : (true|false). Should be true for libraries" ;
    Integer lineNumberStart "lineNumberStart" ;
    Integer columnNumberStart "columnNumberStart" ;
    Integer lineNumberEnd "lineNumberEnd" ;
    Integer columnNumberEnd "columnNumberEnd" ;
    TimeStamp buildTimes "Build and edit times";
  end INFO;
end Info;

uniontype TimeStamp
 record TIMESTAMP
   Real lastBuildTime "Last Build Time";
   Real lastEditTime "Last Edit Time";
  end TIMESTAMP;
end TimeStamp;

uniontype Class
 record CLASS
    Ident name;
    Boolean     partialPrefix   "true if partial" ;
    Boolean     finalPrefix     "true if final" ;
    Boolean     encapsulatedPrefix "true if encapsulated" ;
    Restriction restriction  "Restriction" ;
    ClassDef    body;
    Info       info    "Information: FileName is the class is defined in +
               isReadOnly bool + start line no + start column no +
               end line no + end column no";
  end CLASS;
end Class;

uniontype ClassDef
  record PARTS
    list<ClassPart> classParts;
    Option<String>  comment;
  end PARTS;

  record DERIVED
    TypeSpec          typeSpec "typeSpec specification includes array dimensions" ;
    ElementAttributes attributes;
    list<ElementArg>  arguments;
    Option<Comment>   comment;
  end DERIVED;

  record ENUMERATION
    EnumDef         enumLiterals;
    Option<Comment> comment;
  end ENUMERATION;

  record OVERLOAD
    list<Path>      functionNames;
    Option<Comment> comment;
  end OVERLOAD;

  record CLASS_EXTENDS
    Ident            baseClassName  "name of class to extend" ;
    list<ElementArg> modifications  "modifications to be applied to the base class";
    Option<String>   comment        "comment";
    list<ClassPart>  parts          "class parts";
  end CLASS_EXTENDS;

  record PDER
    Path         functionName;
    list<Ident>  vars "derived variables" ;
    Option<Comment> comment "comment";
  end PDER;
end ClassDef;

uniontype TypeSpec "ModExtension: new MetaModelica type specification!"
  record TPATH
    Path path;
    Option<ArrayDim> arrayDim;
  end TPATH;

  record TCOMPLEX
    Path             path;
    list<TypeSpec>   typeSpecs;
    Option<ArrayDim> arrayDim;
  end TCOMPLEX;
end TypeSpec;

uniontype EnumDef
  "The definition of an enumeration is either a list of literals
     or a colon, \':\', which defines a supertype of all enumerations"
  record ENUMLITERALS
    list<EnumLiteral> enumLiterals;
  end ENUMLITERALS;

  record ENUM_COLON end ENUM_COLON;
end EnumDef;

uniontype EnumLiteral "EnumLiteral, which is a name in an enumeration and an optional
   Comment."
  record ENUMLITERAL
    Ident           literal;
    Option<Comment> comment;
  end ENUMLITERAL;
end EnumLiteral;

uniontype ClassPart "A class definition contains several parts.  There are public and
  protected component declarations, type definitions and `extends\'
  clauses, collectively called elements.  There are also equation
  sections and algorithm sections. The EXTERNAL part is used only by functions
  which can be declared as external C or FORTRAN functions."
  record PUBLIC
    list<ElementItem> contents ;
  end PUBLIC;

  record PROTECTED
    list<ElementItem> contents;
  end PROTECTED;

  record CONSTRAINTS
    list<EquationItem> contents;
  end CONSTRAINTS;

  record EQUATIONS
    list<EquationItem> contents;
  end EQUATIONS;

  record INITIALEQUATIONS
    list<EquationItem> contents;
  end INITIALEQUATIONS;

  record ALGORITHMS
    list<AlgorithmItem> contents;
  end ALGORITHMS;

  record INITIALALGORITHMS
    list<AlgorithmItem> contents;
  end INITIALALGORITHMS;

  record EXTERNAL
    ExternalDecl externalDecl "externalDecl" ;
    Option<Annotation> annotation_ "annotation" ;
  end EXTERNAL;
end ClassPart;

uniontype ElementItem "An element item is either an element or an annotation"
  record ELEMENTITEM
    Element  element;
  end ELEMENTITEM;

  record ANNOTATIONITEM
    Annotation  annotation_ ;
  end ANNOTATIONITEM;
end ElementItem;

uniontype Element
  record ELEMENT
    Boolean                   finalPrefix;
    Option<RedeclareKeywords> redeclareKeywords "replaceable, redeclare" ;
    InnerOuter                innerOuter "inner/outer" ;
    Ident                     name;
    ElementSpec               specification "Actual element specification" ;
    Info                      info  "File name the class is defined in + line no + column no" ;
    Option<ConstrainClass> constrainClass "constrainClass ; only valid for classdef and component" ;
  end ELEMENT;

  record DEFINEUNIT
    Ident name;
    list<NamedArg> args;
  end DEFINEUNIT;

  record TEXT
    Option<Ident> optName "optName : optional name of text, e.g. model with syntax error.
                                       We need the name to be able to browse it..." ;
    String string;
    Info info;
  end TEXT;
end Element;

uniontype ConstrainClass "Constraining type, must be extends"
  record CONSTRAINCLASS
    ElementSpec elementSpec "elementSpec ; must be extends" ;
    Option<Comment> comment "comment" ;
  end CONSTRAINCLASS;
end ConstrainClass;

uniontype ElementSpec
  record CLASSDEF
    Boolean replaceable_ "replaceable" ;
    Class class_ "class" ;
  end CLASSDEF;

  record EXTENDS
    Path path "path" ;
    list<ElementArg> elementArg "elementArg" ;
    Option<Annotation> annotationOpt "optional annotation";
  end EXTENDS;

  record IMPORT
    Import import_ "import" ;
    Option<Comment> comment "comment" ;
  end IMPORT;

  record COMPONENTS
    ElementAttributes attributes "attributes" ;
    TypeSpec typeSpec "typeSpec" ;
    list<ComponentItem> components "components" ;
  end COMPONENTS;
end ElementSpec;

uniontype InnerOuter
  record INNER "an inner component"                    end INNER;
  record OUTER "an outer component"                    end OUTER;
  record INNEROUTER "an inner/outer component"         end INNEROUTER;
  record UNSPECIFIED "a component without inner/outer" end UNSPECIFIED;
end InnerOuter;

uniontype Import
  record NAMED_IMPORT
    Ident name "name" ;
    Path path "path" ;
  end NAMED_IMPORT;

  record QUAL_IMPORT
    Path path "path" ;
  end QUAL_IMPORT;

  record UNQUAL_IMPORT
    Path path "path" ;
  end UNQUAL_IMPORT;
end Import;

uniontype ComponentItem
  record COMPONENTITEM
    Component component "component" ;
    Option<ComponentCondition> condition "condition" ;
    Option<Comment> comment "comment" ;
  end COMPONENTITEM;
end ComponentItem;

type ComponentCondition = Exp;

uniontype Component
  record COMPONENT
    Ident name "name" ;
    ArrayDim arrayDim "arrayDim ; Array dimensions, if any" ;
    Option<Modification> modification "modification ; Optional modification" ;
  end COMPONENT;
end Component;

uniontype EquationItem
  record EQUATIONITEM
    Equation equation_ "equation" ;
    Option<Comment> comment "comment" ;
    Info info "line number" ;
  end EQUATIONITEM;

  record EQUATIONITEMANN
    Annotation annotation_ "annotation" ;
  end EQUATIONITEMANN;
end EquationItem;

uniontype AlgorithmItem
  record ALGORITHMITEM
    Algorithm algorithm_ "algorithm" ;
    Option<Comment> comment "comment" ;
    Info info "line number" ;
  end ALGORITHMITEM;

  record ALGORITHMITEMANN
    Annotation annotation_ "annotation" ;
  end ALGORITHMITEMANN;
end AlgorithmItem;

uniontype Equation
  record EQ_IF
    Exp ifExp "ifExp ; Conditional expression" ;
    list<EquationItem> equationTrueItems "equationTrueItems ; true branch" ;
    list<tuple<Exp, list<EquationItem>>> elseIfBranches "elseIfBranches" ;
    list<EquationItem> equationElseItems "equationElseItems Standard 2-side eqn" ;
  end EQ_IF;

  record EQ_EQUALS
    Exp leftSide "leftSide" ;
    Exp rightSide "rightSide Connect stmt" ;
  end EQ_EQUALS;

  record EQ_CONNECT
    ComponentRef connector1 "connector1" ;
    ComponentRef connector2 "connector2" ;
  end EQ_CONNECT;

  record EQ_FOR
    ForIterators iterators;
    list<EquationItem> forEquations "forEquations" ;
  end EQ_FOR;

  record EQ_WHEN_E
    Exp whenExp "whenExp" ;
    list<EquationItem> whenEquations "whenEquations" ;
    list<tuple<Exp, list<EquationItem>>> elseWhenEquations "elseWhenEquations" ;
  end EQ_WHEN_E;

  record EQ_NORETCALL
    ComponentRef functionName "functionName" ;
    FunctionArgs functionArgs "functionArgs; fcalls without return value" ;
  end EQ_NORETCALL;

  record EQ_FAILURE
    EquationItem equ;
  end EQ_FAILURE;
end Equation;

uniontype Algorithm
  record ALG_ASSIGN
    Exp assignComponent "assignComponent" ;
    Exp value "value" ;
  end ALG_ASSIGN;

  record ALG_IF
    Exp ifExp "ifExp" ;
    list<AlgorithmItem> trueBranch "trueBranch" ;
    list<tuple<Exp, list<AlgorithmItem>>> elseIfAlgorithmBranch "elseIfAlgorithmBranch" ;
    list<AlgorithmItem> elseBranch "elseBranch" ;
  end ALG_IF;

  record ALG_FOR
    ForIterators iterators;
    list<AlgorithmItem> forBody "forBody" ;
  end ALG_FOR;

  record ALG_WHILE
    Exp boolExpr "boolExpr" ;
    list<AlgorithmItem> whileBody "whileBody" ;
  end ALG_WHILE;

  record ALG_WHEN_A
    Exp boolExpr "boolExpr" ;
    list<AlgorithmItem> whenBody "whenBody" ;
    list<tuple<Exp, list<AlgorithmItem>>> elseWhenAlgorithmBranch "elseWhenAlgorithmBranch" ;
  end ALG_WHEN_A;

  record ALG_NORETCALL
    ComponentRef functionCall "functionCall" ;
    FunctionArgs functionArgs "functionArgs; general fcalls without return value" ;
  end ALG_NORETCALL;

  record ALG_RETURN
  end ALG_RETURN;

  record ALG_BREAK
  end ALG_BREAK;

  // Part of MetaModelica extension. KS
  record ALG_TRY
    list<AlgorithmItem> tryBody;
  end ALG_TRY;

  record ALG_CATCH
    list<AlgorithmItem> catchBody;
  end ALG_CATCH;

  record ALG_THROW
  end ALG_THROW;

  record ALG_MATCHCASES
    MatchType matchType;
    list<Exp> inputExps;
    list<Exp> switchCases;
  end ALG_MATCHCASES;

  record ALG_GOTO
    String labelName;
  end ALG_GOTO;

  record ALG_LABEL
    String labelName;
  end ALG_LABEL;

  record ALG_FAILURE
    list<AlgorithmItem> equ;
  end ALG_FAILURE;
end Algorithm;

uniontype Modification
  record CLASSMOD
    list<ElementArg> elementArgLst;
    Option<Exp> expOption;
  end CLASSMOD;
end Modification;

uniontype ElementArg
  record MODIFICATION
    Boolean finalItem "finalItem" ;
    Each each_ "each" ;
    ComponentRef componentRef "componentRef" ;
    Option<Modification> modification "modification" ;
    Option<String> comment "comment" ;
  end MODIFICATION;

  record REDECLARATION
    Boolean finalItem "finalItem" ;
    RedeclareKeywords redeclareKeywords "redeclare  or replaceable " ;
    Each each_ "each" ;
    ElementSpec elementSpec "elementSpec" ;
    Option<ConstrainClass> constrainClass "class definition or declaration" ;
  end REDECLARATION;
end ElementArg;

uniontype RedeclareKeywords
  record REDECLARE end REDECLARE;

  record REPLACEABLE end REPLACEABLE;

  record REDECLARE_REPLACEABLE end REDECLARE_REPLACEABLE;
end RedeclareKeywords;

uniontype Each
  record EACH end EACH;

  record NON_EACH end NON_EACH;
end Each;

uniontype ElementAttributes
  record ATTR
    Boolean flowPrefix "flow" ;
    Boolean streamPrefix "stream" ;
    Variability variability "variability ; parameter, constant etc." ;
    Direction direction "direction" ;
    ArrayDim arrayDim "arrayDim" ;
  end ATTR;
end ElementAttributes;

uniontype Variability
  record VAR end VAR;
  record DISCRETE end DISCRETE;
  record PARAM end PARAM;
  record CONST end CONST;
end Variability;

uniontype Direction
  record INPUT  "direction is input"                                   end INPUT;
  record OUTPUT "direction is output"                                  end OUTPUT;
  record BIDIR  "direction is not specified, neither input nor output" end BIDIR;
end Direction;

type ArrayDim = list<Subscript>;

uniontype Exp
  record INTEGER
    Integer value;
  end INTEGER;

  record REAL
    Real value;
  end REAL;

  record CREF
    ComponentRef componentRef;
  end CREF;

  record STRING
    String value;
  end STRING;

  record BOOL
    Boolean value;
  end BOOL;

  record BINARY   "Binary operations, e.g. a*b"
    Exp exp1;
    Operator op;
    Exp exp2;
  end BINARY;

  record UNARY  "Unary operations, e.g. -(x)"
    Operator op "op" ;
    Exp exp "exp Logical binary operations: and, or" ;
  end UNARY;

  record LBINARY
    Exp exp1 "exp1" ;
    Operator op "op" ;
    Exp exp2 ;
  end LBINARY;

  record LUNARY  "Logical unary operations: not"
    Operator op "op" ;
    Exp exp "exp Relations, e.g. a >= 0" ;
  end LUNARY;

  record RELATION
    Exp exp1 "exp1" ;
    Operator op "op" ;
    Exp exp2  ;
  end RELATION;

  record IFEXP  "If expressions"
    Exp ifExp "ifExp" ;
    Exp trueBranch "trueBranch" ;
    Exp elseBranch "elseBranch" ;
    list<tuple<Exp, Exp>> elseIfBranch "elseIfBranch Function calls" ;
  end IFEXP;

  record CALL
    ComponentRef function_ "function" ;
    FunctionArgs functionArgs ;
  end CALL;

  // stefan
  record PARTEVALFUNCTION "Partially evaluated function"
    ComponentRef function_ "function" ;
    FunctionArgs functionArgs ;
  end PARTEVALFUNCTION;

  record ARRAY   "Array construction using {, }, or array"
    list<Exp> arrayExp ;
  end ARRAY;

  record MATRIX  "Matrix construction using {, } "
    list<list<Exp>> matrix ;
  end MATRIX;

  record RANGE  "Range expressions, e.g. 1:10 or 1:0.5:10"
    Exp start "start" ;
    Option<Exp> step "step" ;
    Exp stop "stop";
  end RANGE;

  record TUPLE " Tuples used in function calls returning several values"
    list<Exp> expressions "comma-separated expressions" ;
  end TUPLE;

  record END "array access operator for last element, e.g. a{end}:=1;"
  end END;


  record CODE  "Modelica AST Code constructors - MetaModelica extension"
    CodeNode code;
  end CODE;

  // MetaModelica expressions follow below!

  record AS  "as operator"
    Ident id " only an id " ;
    Exp exp  " expression to bind to the id ";
  end AS;

  record CONS  "list cons or :: operator"
    Exp head " head of the list ";
    Exp rest " rest of the list ";
  end CONS;

  record MATCHEXP "matchcontinue expression"
    MatchType matchTy            " match or matchcontinue      ";
    Exp inputExp                 " match expression of         ";
    list<ElementItem> localDecls " local declarations          ";
    list<Case> cases             " case list + else in the end ";
    Option<String> comment       " match expr comment_optional ";
  end MATCHEXP;

    // The following two are only used internaly in the compiler
  record LIST "Part of MetaModelica extension"
    list<Exp> exps;
  end LIST;
end Exp;

uniontype Case "case in match or matchcontinue"
  record CASE
    Exp pattern " patterns to be matched ";
    Info patternInfo "file information of the pattern";
    list<ElementItem> localDecls " local decls ";
    list<EquationItem>  equations " equations [] for no equations ";
    Exp result " result ";
    Option<String> comment " comment after case like: case pattern string_comment ";
  end CASE;

  record ELSE "else in match or matchcontinue"
    list<ElementItem> localDecls " local decls ";
    list<EquationItem>  equations " equations [] for no equations ";
    Exp result " result ";
    Option<String> comment " comment after case like: case pattern string_comment ";
  end ELSE;
end Case;

uniontype MatchType
  record MATCH end MATCH;
  record MATCHCONTINUE end MATCHCONTINUE;
end MatchType;

uniontype CodeNode
  record C_TYPENAME "Cannot be parsed; used by Static for API calls"
    Path path;
  end C_TYPENAME;

  record C_VARIABLENAME "Cannot be parsed; used by Static for API calls"
    ComponentRef componentRef;
  end C_VARIABLENAME;

  record C_CONSTRAINTSECTION
    Boolean boolean;
    list<EquationItem> equationItemLst;
  end C_CONSTRAINTSECTION;

  record C_EQUATIONSECTION
    Boolean boolean;
    list<EquationItem> equationItemLst;
  end C_EQUATIONSECTION;

  record C_ALGORITHMSECTION
    Boolean boolean;
    list<AlgorithmItem> algorithmItemLst;
  end C_ALGORITHMSECTION;

  record C_ELEMENT
    Element element;
  end C_ELEMENT;

  record C_EXPRESSION
    Exp exp;
  end C_EXPRESSION;

  record C_MODIFICATION
    Modification modification;
  end C_MODIFICATION;
end CodeNode;

uniontype FunctionArgs
  record FUNCTIONARGS
    list<Exp> args "args" ;
    list<NamedArg> argNames "argNames" ;
  end FUNCTIONARGS;

  record FOR_ITER_FARG
     Exp  exp "iterator expression";
     ForIterators iterators;
  end FOR_ITER_FARG;
end FunctionArgs;


uniontype NamedArg
  record NAMEDARG
    Ident argName "argName" ;
    Exp argValue "argValue" ;
  end NAMEDARG;
end NamedArg;


uniontype Operator "Expression operators"
  /* arithmetic operators */
  record ADD       "addition"                    end ADD;
  record SUB       "subtraction"                 end SUB;
  record MUL       "multiplication"              end MUL;
  record DIV       "division"                    end DIV;
  record POW       "power"                       end POW;
  record UPLUS     "unary plus"                  end UPLUS;
  record UMINUS    "unary minus"                 end UMINUS;
  /* element-wise arithmetic operators */
  record ADD_EW    "element-wise addition"       end ADD_EW;
  record SUB_EW    "element-wise subtraction"    end SUB_EW;
  record MUL_EW    "element-wise multiplication" end MUL_EW;
  record DIV_EW    "element-wise division"       end DIV_EW;
  record POW_EW    "element-wise power"          end POW_EW;
  record UPLUS_EW  "element-wise unary minus"    end UPLUS_EW;
  record UMINUS_EW "element-wise unary plus"     end UMINUS_EW;
  /* logical operators */
  record AND       "logical and"                 end AND;
  record OR        "logical or"                  end OR;
  record NOT       "logical not"                 end NOT;
  /* relational operators */
  record LESS      "less than"                   end LESS;
  record LESSEQ    "less than or equal"          end LESSEQ;
  record GREATER   "greater than"                end GREATER;
  record GREATEREQ "greater than or equal"       end GREATEREQ;
  record EQUAL     "relational equal"            end EQUAL;
  record NEQUAL    "relational not equal"        end NEQUAL;
end Operator;

uniontype Subscript
  record NOSUB end NOSUB;

  record SUBSCRIPT
    Exp subScript "subScript" ;
  end SUBSCRIPT;
end Subscript;


uniontype ComponentRef
  record CREF_FULLYQUALIFIED
    ComponentRef componentRef;
  end CREF_FULLYQUALIFIED;
  record CREF_QUAL
    Ident name "name" ;
    list<Subscript> subScripts "subScripts" ;
    ComponentRef componentRef "componentRef" ;
  end CREF_QUAL;
  record CREF_IDENT
    Ident name "name" ;
    list<Subscript> subscripts "subscripts" ;
  end CREF_IDENT;
  record WILD end WILD;
end ComponentRef;

uniontype Path
  record QUALIFIED
    Ident name "name" ;
    Path path "path" ;
  end QUALIFIED;
  record IDENT
    Ident name "name" ;
  end IDENT;
  record FULLYQUALIFIED "Used during instantiation for names that are fully qualified,
    i.e. the names are looked up from top scope directly like for instance Modelica.SIunits.Voltage
    Note: Not created during parsing, only during instantation to speedup/simplify lookup.
  "
    Path path;
  end FULLYQUALIFIED;
end Path;


uniontype Restriction
  record R_CLASS end R_CLASS;
  record R_OPTIMIZATION end R_OPTIMIZATION;
  record R_MODEL end R_MODEL;
  record R_RECORD end R_RECORD;
  record R_BLOCK end R_BLOCK;
  record R_CONNECTOR "connector class" end R_CONNECTOR;
  record R_EXP_CONNECTOR "expandable connector class" end R_EXP_CONNECTOR;
  record R_TYPE end R_TYPE;
  record R_PACKAGE end R_PACKAGE;
  record R_FUNCTION end R_FUNCTION;
  record R_OPERATOR "an operator" end R_OPERATOR;
  record R_OPERATOR_FUNCTION "an operator function" end R_OPERATOR_FUNCTION;
  record R_OPERATOR_RECORD   "an operator record"   end R_OPERATOR_RECORD;
  record R_ENUMERATION end R_ENUMERATION;
  record R_PREDEFINED_INTEGER end R_PREDEFINED_INTEGER;
  record R_PREDEFINED_REAL end R_PREDEFINED_REAL;
  record R_PREDEFINED_STRING end R_PREDEFINED_STRING;
  record R_PREDEFINED_BOOLEAN end R_PREDEFINED_BOOLEAN;
  record R_PREDEFINED_ENUMERATION end R_PREDEFINED_ENUMERATION;

  // MetaModelica
  record R_UNIONTYPE "MetaModelica uniontype" end R_UNIONTYPE;
  record R_METARECORD "Metamodelica record"  //MetaModelica extension, added by simbj
    Path name; //Name of the uniontype
    Integer index; //Index in the uniontype
  end R_METARECORD;
  record R_UNKNOWN "Helper restriction" end R_UNKNOWN; /* added by simbj */
end Restriction;

uniontype Annotation
  record ANNOTATION
    list<ElementArg> elementArgs "elementArgs" ;
  end ANNOTATION;
end Annotation;

uniontype Comment
  record COMMENT
    Option<Annotation> annotation_ "annotation" ;
    Option<String> comment "comment" ;
  end COMMENT;
end Comment;

uniontype ExternalDecl
  record EXTERNALDECL
    Option<Ident>        funcName "The name of the external function" ;
    Option<String>       lang     "Language of the external function" ;
    Option<ComponentRef> output_  "output parameter as return value" ;
    list<Exp>            args     "only positional arguments, i.e. expression list" ;
    Option<Annotation>   annotation_ ;
  end EXTERNALDECL;
end ExternalDecl;

function pathString
  input Path p;
  output String s;
end pathString;

function stripLast
  input Path inPath;
  output Path outPath;
end stripLast;

end Absyn;

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

end UnparsingTV;

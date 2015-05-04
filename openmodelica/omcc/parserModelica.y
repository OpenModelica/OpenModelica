%{
import Absyn;
import OMCCTypes;
import System;

constant list<String> lstSemValue3 = {};
constant list<String> lstSemValue = {
   "error", "$undefined", "ALGORITHM", "AND", "ANNOTATION",
  "BLOCK", "CLASS", "CONNECT", "CONNECTOR", "CONSTANT", "DISCRETE", "DER",
  "DEFINEUNIT", "EACH", "ELSE", "ELSEIF", "ELSEWHEN", "END",
  "ENUMERATION", "EQUATION", "ENCAPSULATED", "EXPANDABLE", "EXTENDS",
  "CONSTRAINEDBY", "EXTERNAL", "FALSE", "FINAL", "FLOW", "FOR",
  "FUNCTION", "IF", "IMPORT", "IN","INITIALEQUATION","INITIALALGORITHM","T_INITIAL", "INNER", "INPUT",
  "LOOP", "MODEL", "NOT", "OUTER", "OPERATOR", "OVERLOAD", "OR",
  "OUTPUT", "PACKAGE", "PARAMETER", "PARTIAL", "PROTECTED", "PUBLIC",
  "RECORD", "REDECLARE", "REPLACEABLE", "RESULTS", "THEN", "TRUE",
  "TYPE", "REAL", "WHEN", "WHILE", "WITHIN", "RETURN", "BREAK",
  ".", "(", ")", "[", "]", "{", "}", "=",
  "ASSIGN", "COMMA", "COLON", "SEMICOLON", "CODE", "CODE_NAME", "CODE_EXP",
  "CODE_VAR", "PURE", "IMPURE", "Identity", "DIGIT", "INTEGER",
  "*", "-", "+", "<=", "<>", "<", ">",
  ">=", "==", "^", "SLASH","OPTIMIZATION","PARFOR","ENDPARFOR","PARLOCAL","PARGLOBAL",
  "PARALLEL","KERNEL","STRING", ".+", ".-",
  ".*", "./", ".*", "STREAM", "AS", "CASE", "EQUALITY",
  "FAILURE", "GUARD", "LOCAL", "MATCH", "MATCHCONTINUE", "UNIONTYPE",
  "ALLWILD", "WILD", "SUBTYPEOF", "COLONCOLON", "MOD", "ENDIF", "ENDFOR",
  "ENDWHILE", "ENDWHEN", "ENDCLASS", "ENDMATCHCONTINUE", "ENDMATCH",
   "$accept",
  "program", "within", "classes_list", "class", "classprefix",
  "encapsulated", "partial", "restriction","classdef2","classdef",
  "classdefenumeration", "classdefderived", "enumeration", "enumlist",
  "enumliteral", "classparts", "classpart", "restClass",
  "algorithmsection", "algorithmitem", "algorithm", "if_algorithm",
  "algelseifs", "algelseif", "when_algorithm", "algelsewhens",
  "algelsewhen", "equationsection", "equationitem", "equation",
  "when_equation", "elsewhens", "elsewhen", "foriterators", "foriterator",
  "if_equation", "elseifs", "elseif", "elementItems", "elementItem",
  "element", "componentclause", "componentitems", "componentitem",
  "component", "modification", "redeclarekeywords", "innerouter",
  "importelementspec", "classelementspec", "import", "elementspec",
  "elementAttr","parallelism", "variability", "direction", "typespec", "arrayComplex",
  "typespecs", "arraySubscripts", "arrayDim", "functioncall",
  "functionargs", "namedargs", "namedarg", "exp", "matchcont", "if_exp",
  "expelseifs", "expelseif", "matchlocal", "cases", "case", "casearg",
  "simpleExp", "headtail", "rangeExp", "logicexp", "logicterm",
  "logfactor", "relterm", "addterm", "term", "factor", "expElement",
  "tuple", "explist", "explist2", "cref", "woperator", "soperator",
  "power", "relOperator", "path", "ident", "string", "comment"};

uniontype AstItem
  record TOKEN
    OMCCTypes.Token tok;
  end TOKEN;
  record BOOLEAN
    Boolean bool;
  end BOOLEAN;
  record PROGRAM
    Absyn.Program program;
  end PROGRAM;
  record WITHIN
    Absyn.Within _within;
  end WITHIN;
  record CLASSES
    list<Absyn.Class> classes;
  end CLASSES;
  record CLASS
    Absyn.Class _class;
  end CLASS;
  record STRING
    String string;
  end STRING;
  record PATH
    Absyn.Path path;
  end PATH;
  record CLASSDEF
    Absyn.ClassDef classdef;
  end CLASSDEF;
  record CLASSPART
    Absyn.ClassPart part;
  end CLASSPART;
  record CLASSPARTS
    list<Absyn.ClassPart> parts;
  end CLASSPARTS;
  record IMPORT
    Absyn.Import _import;
  end IMPORT;
  record ELEMENTITEM
    Absyn.ElementItem item;
  end ELEMENTITEM;
  record ELEMENTITEMS
    list<Absyn.ElementItem> items;
  end ELEMENTITEMS;
  record ELEMENT
    Absyn.Element element;
  end ELEMENT;
  record ELEMENTSPEC
    Absyn.ElementSpec spec;
  end ELEMENTSPEC;
  record ELEMENTATTRIBUTES
    Absyn.ElementAttributes attrs;
  end ELEMENTATTRIBUTES;
  record COMMENT
    Absyn.Comment comment;
  end COMMENT;
  record DIRECTION
    Absyn.Direction direction;
  end DIRECTION;
  record EXP
    Absyn.Exp exp;
  end EXP;
  record EXPS
    list<Absyn.Exp> exps;
  end EXPS;
  record MATRIX
    list<list<Absyn.Exp>> matrix;
  end MATRIX;
  record SUBSCRIPT
    Absyn.Subscript subscript;
  end SUBSCRIPT;
  record ARRAYDIM
    list<Absyn.Subscript> dim;
  end ARRAYDIM;
  record OPERATOR
    Absyn.Operator op;
  end OPERATOR;
  record CASE
    Absyn.Case _case;
  end CASE;
  record CASES
    list<Absyn.Case> cases;
  end CASES;
  record MATCHTYPE
    Absyn.MatchType matchType;
  end MATCHTYPE;
  record RESTRICTION
    Absyn.Restriction restriction;
  end RESTRICTION;
  record INNEROUTER
    Absyn.InnerOuter innerOuter;
  end INNEROUTER;
  record CREF
    Absyn.ComponentRef cref;
  end CREF;
  record PARALLELISM
    Absyn.Parallelism parallelism;
  end PARALLELISM;
  record VARIABILITY
    Absyn.Variability variability;
  end VARIABILITY;
  record REDECLAREKEYWORDS
    Absyn.RedeclareKeywords redeclareKeywords;
  end REDECLAREKEYWORDS;
  record NAMEDARG
    Absyn.NamedArg arg;
  end NAMEDARG;
  record TYPESPEC
    Absyn.TypeSpec spec;
  end TYPESPEC;
  record TYPESPECS
    list<Absyn.TypeSpec> specs;
  end TYPESPECS;
  record COMPONENTITEM
    Absyn.ComponentItem item;
  end COMPONENTITEM;
  record COMPONENTITEMS
    list<Absyn.ComponentItem> items;
  end COMPONENTITEMS;
  record COMPONENT
    Absyn.Component component;
  end COMPONENT;
  record EQUATIONITEM
    Absyn.EquationItem item;
  end EQUATIONITEM;
  record EQUATIONITEMS
    list<Absyn.EquationItem> items;
  end EQUATIONITEMS;
  record EQUATION
    Absyn.Equation eq;
  end EQUATION;
  record ELSEIF
    tuple<Absyn.Exp, list<Absyn.EquationItem>> elseIf;
  end ELSEIF;
  record ELSEIFS
    list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> elseIfs;
  end ELSEIFS;
  record FORITERATOR
    Absyn.ForIterator iterator;
  end FORITERATOR;
  record FORITERATORS
    list<Absyn.ForIterator> iterators;
  end FORITERATORS;
  record ELSEWHEN
    tuple<Absyn.Exp, list<Absyn.EquationItem>> elseWhen;
  end ELSEWHEN;
  record ELSEWHENS
    list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> elseWhens;
  end ELSEWHENS;
  record FUNCTIONARGS
    Absyn.FunctionArgs args;
  end FUNCTIONARGS;
  record NAMEDARGS
    list<Absyn.NamedArg> arg;
  end NAMEDARGS;
  record ALGORITHMITEM
    Absyn.AlgorithmItem item;
  end ALGORITHMITEM;
  record ALGORITHMITEMS
    list<Absyn.AlgorithmItem> items;
  end ALGORITHMITEMS;
  record ALGORITHM
    Absyn.Algorithm alg;
  end ALGORITHM;
  record ALGELSEIF
    tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> elseIf;
  end ALGELSEIF;
  record ALGELSEIFS
    list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> elseIfs;
  end ALGELSEIFS;
  record ALGELSEWHEN
    tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> elseWhen;
  end ALGELSEWHEN;
  record ALGELSEWHENS
    list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> elseWhens;
  end ALGELSEWHENS;
  record EXPELSEIF
    tuple<Absyn.Exp, Absyn.Exp> elseIf;
  end EXPELSEIF;
  record EXPELSEIFS
    list<tuple<Absyn.Exp, Absyn.Exp>> elseIfs;
  end EXPELSEIFS;
  record ENUMDEF
    Absyn.EnumDef def;
  end ENUMDEF;
  record ENUMLITERAL
    Absyn.EnumLiteral literal;
  end ENUMLITERAL;
  record ENUMLITERALS
    list<Absyn.EnumLiteral> literals;
  end ENUMLITERALS;
  record MODIFICATION
    Absyn.Modification mod;
  end MODIFICATION;
  record CLASSPREFIX
    Boolean encap,part;
  end CLASSPREFIX;
  record ELEMENTARG
     Absyn.ElementArg arg;
  end ELEMENTARG;
  record ELEMENTARGS
     list<Absyn.ElementArg> args;
  end ELEMENTARGS;
  record EACH
     Absyn.Each _each;
  end EACH;
  record EQMOD
     Absyn.EqMod mod;
  end EQMOD;
  record EXTERNALDECL
     Absyn.ExternalDecl decl;
  end EXTERNALDECL;
  record ANNOTATION
    Absyn.Annotation ann;
  end ANNOTATION;
  record CONSTRAINCLASS
    Absyn.ConstrainClass cc;
  end CONSTRAINCLASS;
end AstItem;

%}

%token T_ALGORITHM
%token T_AND
%token T_ANNOTATION
%token BLOCK
%token CLASS
%token CONNECT
%token CONNECTOR
%token CONSTANT
%token DISCRETE
%token DER
%token DEFINEUNIT
%token EACH
%token ELSE
%token ELSEIF
%token ELSEWHEN
%token T_END
%token ENUMERATION
%token EQUATION
%token ENCAPSULATED
%token EXPANDABLE
%token EXTENDS
%token CONSTRAINEDBY
%token EXTERNAL
%token T_FALSE
%token FINAL
%token FLOW
%token FOR
%token FUNCTION
%token IF
%token IMPORT
%token T_IN
%token INITIALEQUATION
%token INITIALALGORITHM
%token T_INITIAL
%token INNER
%token T_INPUT
%token LOOP
%token MODEL
%token T_NOT
%token T_OUTER
%token OPERATOR
%token OVERLOAD
%token T_OR
%token T_OUTPUT
%token T_PACKAGE
%token PARAMETER
%token PARTIAL
%token PROTECTED
%token PUBLIC
%token RECORD
%token REDECLARE
%token REPLACEABLE
%token RESULTS
%token THEN
%token T_TRUE
%token TYPE
%token UNSIGNED_REAL
%token WHEN
%token WHILE
%token WITHIN
%token RETURN
%token BREAK
%token DOT
%token LPAR
%token RPAR
%token LBRACK
%token RBRACK
%token LBRACE
%token RBRACE
%token EQUALS
%token ASSIGN
%token COMMA
%token COLON
%token SEMICOLON
%token CODE
%token CODE_NAME
%token CODE_EXP
%token CODE_VAR
%token PURE
%token IMPURE
%token IDENT
%token DIGIT
%token UNSIGNED_INTEGER

%token  STAR
%token  MINUS
%token  PLUS
%token  LESSEQ
%token  LESSGT
%token  LESS
%token  GREATER
%token  GREATEREQ
%token  EQEQ
%token  POWER
%token SLASH
%token T_OPTIMIZATION
%token PARFOR
%token ENDPARFOR
%token T_PARLOCAL
%token T_PARGLOBAL
%token T_PARALLEL
%token T_KERNEL
%token STRING

%token PLUS_EW
%token MINUS_EW
%token STAR_EW
%token SLASH_EW
%token POWER_EW

%token STREAM

%token AS
%token CASE
%token EQUALITY
%token FAILURE
%token GUARD
%token LOCAL
%token MATCH
%token MATCHCONTINUE
%token UNIONTYPE
%token ALLWILD
%token WILD
%token SUBTYPEOF
%token COLONCOLON
%token MOD
%token ENDIF
%token ENDFOR
%token ENDWHILE
%token ENDWHEN
%token ENDCLASS
%token ENDMATCHCONTINUE
%token ENDMATCH
//%expect 42



%%

/* Yacc BNF grammar of the Modelica+MetaModelica language */

program             :  classes_list
                                { $$ = PROGRAM(Absyn.PROGRAM(getClasses($1),Absyn.TOP(),Absyn.TIMESTAMP(0.0,1.0))); }
                       | within classes_list
                                { $$ = PROGRAM(Absyn.PROGRAM(getClasses($2),getWithin($1),Absyn.TIMESTAMP(0.0,1.0))); }


within              :  WITHIN path SEMICOLON { $$ = WITHIN(Absyn.WITHIN(getPath($2))); }



classes_list            : class2 SEMICOLON { $$ = CLASSES(getClass($1)::{}); }
                        | class2 SEMICOLON classes_list { $$ = CLASSES(getClass($1)::getClasses($3)); }
                          /* restriction IDENT classdef T_END IDENT SEMICOLON
                                { if (not stringEqual($2,$5) ) then print(Types.printInfoError(info) + " Error: The identifier at start and end are different '" + $2 + "'");
                                   true = ($2 == $5);
                                  end if; $$[Class] = Absyn.CLASS($2,false,false,false,$1[Restriction],$3[ClassDef],yyinfo); }
                          */

class2               : FINAL classprefix restriction IDENT classdef { $$ = CLASS(Absyn.CLASS(getString($4),getClassPrefixPartial($1),true,getClassPrefixEncapsulated($1),getRestriction($3),getClassDef($5),yyinfo)); }
                     | FINAL restriction IDENT classdef
                         {  $$ = CLASS(Absyn.CLASS(getString($3),false,true,false,getRestriction($2),getClassDef($4),yyinfo)); }
                     | class { $$ = $1; }

class                  : restriction IDENT classdef
                                { $$ = CLASS(Absyn.CLASS(getString($2),false,false,false,getRestriction($1),getClassDef($3),yyinfo)); }
                       | restriction EXTENDS IDENT elementargs classparts ENDCLASS 
                                { $$ = CLASS(Absyn.CLASS(getString($3),false,false,false,getRestriction($1),Absyn.CLASS_EXTENDS(getString($3),getElementArgs($4),NONE(),getClassParts($5),{}),yyinfo)); } 
                       | restriction EXTENDS IDENT elementargs string classparts ENDCLASS 
                                { $$ = CLASS(Absyn.CLASS(getString($3),false,false,false,getRestriction($1),Absyn.CLASS_EXTENDS(getString($3),getElementArgs($4),SOME(getString($5)),getClassParts($6),{}),yyinfo)); }                   
                       | classprefix restriction IDENT classdef
                                { $$ = CLASS(Absyn.CLASS(getString($3),getClassPrefixPartial($1),false,getClassPrefixEncapsulated($1),getRestriction($2),getClassDef($4),yyinfo)); }
                       | classprefix restriction EXTENDS IDENT elementargs classparts ENDCLASS 
                                { $$ = CLASS(Absyn.CLASS(getString($4),getClassPrefixPartial($1),false,getClassPrefixEncapsulated($1),getRestriction($2),Absyn.CLASS_EXTENDS(getString($4),getElementArgs($5),NONE(),getClassParts($6),{}),yyinfo)); }                       
                       | classprefix restriction EXTENDS IDENT elementargs string classparts ENDCLASS 
                                { $$ = CLASS(Absyn.CLASS(getString($4),getClassPrefixPartial($1),false,getClassPrefixEncapsulated($1),getRestriction($2),Absyn.CLASS_EXTENDS(getString($4),getElementArgs($5),SOME(getString($6)),getClassParts($7),{}),yyinfo)); }

classdef             : string ENDCLASS
                          { $$ = CLASSDEF(Absyn.PARTS({},{},{},{},SOME(getString($1)))); }
                      |ENDCLASS
                          { $$ = CLASSDEF(Absyn.PARTS({},{},{},{},NONE())); }
                      
                      |classparts ENDCLASS
                          { $$ = CLASSDEF(Absyn.PARTS({},{},getClassParts($1),{},NONE())); } 
                     
                     |classparts annotation SEMICOLON ENDCLASS
                          { $$ = CLASSDEF(Absyn.PARTS({},{},getClassParts($1),{getAnnotation($2)},NONE())); }                                           
                     
                     |LPAR namedargs RPAR classparts ENDCLASS
                          { $$ = CLASSDEF(Absyn.PARTS({},getNamedArgs($2),getClassParts($4),{},NONE())); } 
                          
                     | string classparts ENDCLASS
                          { $$ = CLASSDEF(Absyn.PARTS({},{},getClassParts($2),{},SOME(getString($1)))); }
                     
                     | string classparts annotation SEMICOLON ENDCLASS
                          { $$ = CLASSDEF(Absyn.PARTS({},{},getClassParts($2),{getAnnotation($3)},SOME(getString($1)))); }
                     
                     | classdefenumeration
                          { $$ = $1; };
                     | classdefderived
                          { $$ = $1; };

classprefix            : ENCAPSULATED partial
                         { $$ = CLASSPREFIX(true,getBoolean($2)); }
                        | PARTIAL
                         { $$ = CLASSPREFIX(false,true); }


// encapsulated           : ENCAPSULATED { $$[Boolean] = true; }
//                        | /* empty */ { $$[Boolean] = false; }

partial                : PARTIAL { $$ = BOOLEAN(true); }
                        | /* empty */ { $$ = BOOLEAN(false); }

final                   : FINAL { $$ = BOOLEAN(true); }
                        | /* empty */ { $$ = BOOLEAN(false); }

restriction             : CLASS { $$ = RESTRICTION(Absyn.R_CLASS()); }
						| MODEL { $$ = RESTRICTION(Absyn.R_MODEL()); }
						| RECORD { $$ = RESTRICTION(Absyn.R_RECORD()); }
						| T_PACKAGE { $$ = RESTRICTION(Absyn.R_PACKAGE()); }
						| TYPE { $$ = RESTRICTION(Absyn.R_TYPE()); }
						| T_OPTIMIZATION { $$ = RESTRICTION(Absyn.R_OPTIMIZATION()); }
						
						| FUNCTION { $$ = RESTRICTION(Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.PURE()))); }
						 /* PARMODELICA EXTENSIONS */
						| T_PARALLEL FUNCTION { $$ = RESTRICTION(Absyn.R_FUNCTION(Absyn.FR_PARALLEL_FUNCTION())); }
						| T_KERNEL FUNCTION { $$ = RESTRICTION(Absyn.R_FUNCTION(Absyn.FR_KERNEL_FUNCTION())); }
						| UNIONTYPE { $$ = RESTRICTION(Absyn.R_UNIONTYPE()); }
						| BLOCK { $$ = RESTRICTION(Absyn.R_BLOCK()); }
						| CONNECTOR { $$ = RESTRICTION(Absyn.R_CONNECTOR()); }
						| EXPANDABLE CONNECTOR { $$ = RESTRICTION(Absyn.R_EXP_CONNECTOR()); }
						| ENUMERATION { $$ = RESTRICTION(Absyn.R_ENUMERATION()); }
                        | OPERATOR FUNCTION { $$ = RESTRICTION(Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION())); }	
						| OPERATOR RECORD { $$ = RESTRICTION(Absyn.R_OPERATOR_RECORD()); }
	                    | OPERATOR { $$ = RESTRICTION(Absyn.R_OPERATOR()); }
						


classdefenumeration  :  EQUALS ENUMERATION LPAR enumeration RPAR comment
                          { $$ = CLASSDEF(Absyn.ENUMERATION(getEnumDef($4),SOME(getComment($6)))); }

classdefderived     : EQUALS typespec elementargs2 comment
                        { $$ = CLASSDEF(Absyn.DERIVED(getTypeSpec($2),Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(), Absyn.BIDIR(),{}),getElementArgs($3),SOME(getComment($4)))); }
                    | EQUALS elementAttr typespec elementargs2 comment
                        { $$ = CLASSDEF(Absyn.DERIVED(getTypeSpec($3),getElementAttributes($2),getElementArgs($4),SOME(getComment($5)))); }
                    				
				
enumeration         : enumlist { $$ = ENUMDEF(Absyn.ENUMLITERALS(getEnumLiterals($1))); }
                     | COLON { $$ = ENUMDEF(Absyn.ENUM_COLON()); }

enumlist          :  enumliteral { $$ = ENUMLITERALS(getEnumLiteral($1)::{}); }
                   | enumliteral COMMA enumlist { $$ = ENUMLITERALS(getEnumLiteral($1)::getEnumLiterals($3)); }

enumliteral          : ident comment { $$ = ENUMLITERAL(Absyn.ENUMLITERAL(getString($1),SOME(getComment($2)))); }

classparts           : classpart { $$ = CLASSPARTS(getClassPart($1)::{}); }
                      | classpart classparts { $$ = CLASSPARTS(getClassPart($1)::getClassParts($2)); }
                      |/*EMPTY*/ { $$ = CLASSPARTS({}); }
                       
classpart           : elementItems { $$ = CLASSPART(Absyn.PUBLIC(getElementItems($1))); }
                     | restClass { $$ = $1; }

restClass              : PUBLIC optelement { $$ = CLASSPART(Absyn.PUBLIC(getElementItems($2))); }
                        | PROTECTED optelement { $$ = CLASSPART(Absyn.PROTECTED(getElementItems($2))); }
                        | EQUATION optequationsection { $$ = CLASSPART(Absyn.EQUATIONS(getEquationItems($2))); }
                        | T_ALGORITHM optalgorithmsection { $$ = CLASSPART(Absyn.ALGORITHMS(getAlgorithmItems($2))); }
						| INITIALEQUATION equationsection { $$ = CLASSPART(Absyn.INITIALEQUATIONS(getEquationItems($2))); }
                        | INITIALALGORITHM algorithmsection { $$ = CLASSPART(Absyn.INITIALALGORITHMS(getAlgorithmItems($2))); }
                        | external { $$ = $1; }


optelement             : elementItems { $$ = $1; }
                       | /* empty */ { $$ = ELEMENTITEMS({}); }

optequationsection     : equationsection { $$ = $1; }
                       | /* empty */ { $$ = EQUATIONITEMS({}); }

optalgorithmsection    : algorithmsection { $$ = $1; }
                       | /* empty */ { $$ = ALGORITHMITEMS({}); }

external               : EXTERNAL SEMICOLON  { $$ = CLASSPART(Absyn.EXTERNAL(Absyn.EXTERNALDECL(NONE(),NONE(),NONE(),{},NONE()),NONE())); }
                        | EXTERNAL externalDecl SEMICOLON  { $$ = CLASSPART(Absyn.EXTERNAL(getExternalDecl($2),NONE())); }
                        | EXTERNAL externalDecl SEMICOLON annotation SEMICOLON { $$ = CLASSPART(Absyn.EXTERNAL(getExternalDecl($2),SOME(getAnnotation($3)))); }


externalDecl           : string { $$ = EXTERNALDECL(Absyn.EXTERNALDECL(NONE(),SOME(getString($1)),NONE(),{},NONE())); }
                       | string annotation { $$ = EXTERNALDECL(Absyn.EXTERNALDECL(NONE(),SOME(getString($1)),NONE(),{},SOME(getAnnotation($2)))); }
                       | string cref EQUALS ident LPAR explist2 RPAR  { $$ = EXTERNALDECL(Absyn.EXTERNALDECL(SOME(getString($4)),SOME(getString($1)),SOME(getCref($2)),getExps($6),NONE())); }
                       | string cref EQUALS ident LPAR explist2 RPAR annotation { $$ = EXTERNALDECL(Absyn.EXTERNALDECL(SOME(getString($4)),SOME(getString($1)),SOME(getCref($2)),getExps($6),SOME(getAnnotation($8)))); }
                       | string ident LPAR explist2 RPAR annotation { $$ = EXTERNALDECL(Absyn.EXTERNALDECL(SOME(getString($2)),SOME(getString($1)),NONE(),getExps($4),SOME(getAnnotation($6)))); }
                       | string ident LPAR explist2 RPAR { $$ = EXTERNALDECL(Absyn.EXTERNALDECL(SOME(getString($2)),SOME(getString($1)),NONE(),getExps($4),NONE())); }
                       | cref EQUALS ident LPAR explist2 RPAR  { $$ = EXTERNALDECL(Absyn.EXTERNALDECL(SOME(getString($3)),NONE(),SOME(getCref($1)),getExps($5),NONE())); }
                       | cref EQUALS ident LPAR explist2 RPAR annotation { $$ = EXTERNALDECL(Absyn.EXTERNALDECL(SOME(getString($3)),NONE(),SOME(getCref($1)),getExps($5),SOME(getAnnotation($7)))); }
                       | ident LPAR explist2 RPAR annotation { $$ = EXTERNALDECL(Absyn.EXTERNALDECL(SOME(getString($1)),NONE(),NONE(),getExps($3),SOME(getAnnotation($5)))); }
                       | ident LPAR explist2 RPAR { $$ = EXTERNALDECL(Absyn.EXTERNALDECL(SOME(getString($1)),NONE(),NONE(),getExps($3),NONE())); }


/* ALGORITHMS */

algorithmsection        :  algorithmitem SEMICOLON { $$ = ALGORITHMITEMS(getAlgorithmItem($1)::{}); }
                        | algorithmitem SEMICOLON algorithmsection { $$ = ALGORITHMITEMS(getAlgorithmItem($1)::getAlgorithmItems($3)); }
                        | /*empty*/ { $$ = ALGORITHMITEMS({}); }
						
algorithmitem           : algorithm comment
                          { $$ = ALGORITHMITEM(Absyn.ALGORITHMITEM(getAlgorithm($1),SOME(getComment($2)),yyinfo)); }

algorithm              :  simpleExp ASSIGN exp
                            { $$ = ALGORITHM(Absyn.ALG_ASSIGN(getExp($1),getExp($3))); }
                        | cref functioncall
                            { $$ = ALGORITHM(Absyn.ALG_NORETCALL(getCref($1),getFunctionArgs($2))); }
                        | RETURN
                            { $$ = ALGORITHM(Absyn.ALG_RETURN()); }
                        | BREAK
                             { $$ = ALGORITHM(Absyn.ALG_BREAK()); }
                        | if_algorithm
                             { $$ = $1; }
                        | when_algorithm
                             { $$ = $1; }
                        | FOR foriterators LOOP algorithmsection ENDFOR
                             { $$ = ALGORITHM(Absyn.ALG_FOR(getForIterators($2),getAlgorithmItems($4))); }
                         /*PARMODELICA EXTENSIONS*/
                        | PARFOR foriterators LOOP algorithmsection ENDPARFOR
                            { $$ = ALGORITHM(Absyn.ALG_PARFOR(getForIterators($2),getAlgorithmItems($4))); }

                        | WHILE exp LOOP  algorithmsection ENDWHILE
                            { $$ = ALGORITHM(Absyn.ALG_WHILE(getExp($2),getAlgorithmItems($4))); }

if_algorithm           : IF exp THEN ENDIF { $$ = ALGORITHM(Absyn.ALG_IF(getExp($2),{},{},{})); } // warning empty if
                       | IF exp THEN algorithmsection ENDIF { $$ = ALGORITHM(Absyn.ALG_IF(getExp($2),getAlgorithmItems($4),{},{})); }
                       | IF exp THEN algorithmsection ELSE algorithmsection ENDIF { $$ = ALGORITHM(Absyn.ALG_IF(getExp($2),getAlgorithmItems($4),{},getAlgorithmItems($6))); }
                       | IF exp THEN algorithmsection ELSE ENDIF { $$ = ALGORITHM(Absyn.ALG_IF(getExp($2),getAlgorithmItems($4),{},{})); }
                       | IF exp THEN algorithmsection algelseifs ENDIF { $$ = ALGORITHM(Absyn.ALG_IF(getExp($2),getAlgorithmItems($4),getAlgElseIfs($5),{})); }
                       | IF exp THEN algorithmsection algelseifs ELSE algorithmsection ENDIF { $$ = ALGORITHM(Absyn.ALG_IF(getExp($2),getAlgorithmItems($4),getAlgElseIfs($5),getAlgorithmItems($7))); }
                       | IF exp THEN algorithmsection algelseifs ELSE ENDIF { $$ = ALGORITHM(Absyn.ALG_IF(getExp($2),getAlgorithmItems($4),getAlgElseIfs($5),{})); }

algelseifs              :  algelseif { $$ = ALGELSEIFS(getAlgElseIf($1)::{}); }
                        | algelseif algelseifs { $$ = ALGELSEIFS(getAlgElseIf($1)::getAlgElseIfs($2)); }
                        | /*empty*/ { $$ = ALGELSEIFS({}); }
						
algelseif               : ELSEIF exp THEN algorithmsection  { $$ = ALGELSEIF((getExp($2),getAlgorithmItems($4))); }

when_algorithm        :  WHEN exp THEN algorithmsection ENDWHEN
                           { $$ = ALGORITHM(Absyn.ALG_WHEN_A(getExp($2),getAlgorithmItems($4),{})); }
                     | WHEN exp THEN algorithmsection algelsewhens ENDWHEN
                           { $$ = ALGORITHM(Absyn.ALG_WHEN_A(getExp($2),getAlgorithmItems($4),getAlgElseWhens($5))); }

algelsewhens               :  algelsewhen { $$ = ALGELSEWHENS(getAlgElseWhen($1)::{}); }
                        | algelsewhen algelsewhens { $$ = ALGELSEWHENS(getAlgElseWhen($1)::getAlgElseWhens($2)); }

algelsewhen               : ELSEWHEN exp THEN algorithmsection  { $$ = ALGELSEWHEN((getExp($2),getAlgorithmItems($4))); }


/* EQUATIONS */
equationsection        :  equationitem SEMICOLON { $$ = EQUATIONITEMS(getEquationItem($1)::{}); }
                        | equationitem SEMICOLON equationsection { $$ = EQUATIONITEMS(getEquationItem($1)::getEquationItems($3)); }
                        | /*empty */ { $$ = EQUATIONITEMS({}); }

equationitem           :  equation comment
                          { $$ = EQUATIONITEM(Absyn.EQUATIONITEM(getEquation($1),SOME(getComment($2)),yyinfo)); }

equation               : exp EQUALS exp
                             { $$ = EQUATION(Absyn.EQ_EQUALS(getExp($1),getExp($3))); }
                        | if_equation
                             { $$ = $1; }
                        | when_equation
                             { $$ = $1; }
                        | CONNECT LPAR cref COMMA cref RPAR
                             { $$ = EQUATION(Absyn.EQ_CONNECT(getCref($3),getCref($5))); }
                        | FOR foriterators LOOP equationsection ENDFOR
                             { $$ = EQUATION(Absyn.EQ_FOR(getForIterators($2),getEquationItems($4))); }
                        | cref functioncall { $$ = EQUATION(Absyn.EQ_NORETCALL(getCref($1),getFunctionArgs($2))); }

when_equation        :  WHEN exp THEN equationsection ENDWHEN
                           { $$ = EQUATION(Absyn.EQ_WHEN_E(getExp($2),getEquationItems($4),{})); }
                     | WHEN exp THEN equationsection elsewhens ENDWHEN
                           { $$ = EQUATION(Absyn.EQ_WHEN_E(getExp($2),getEquationItems($4),getElseWhens($5))); }

elsewhens               :  elsewhen { $$ = ELSEWHENS(getElseWhen($1)::{}); }
                        | elsewhen elsewhens { $$ = ELSEWHENS(getElseWhen($1)::getElseWhens($2)); }

elsewhen               : ELSEWHEN exp THEN equationsection  { $$ = ELSEWHEN((getExp($2),getEquationItems($4))); }

foriterators          : foriterator { $$ = FORITERATORS(getForIterator($1)::{}); }
                      | foriterator COMMA foriterators { $$ = FORITERATORS(getForIterator($1)::getForIterators($2)); }

foriterator           : IDENT { $$ = FORITERATOR(Absyn.ITERATOR(getString($1),NONE(),NONE())); }
                      | IDENT T_IN exp { $$ = FORITERATOR(Absyn.ITERATOR(getString($1),NONE(),SOME(getExp($3)))); }

if_equation           : IF exp THEN equationsection ENDIF
                           { $$ = EQUATION(Absyn.EQ_IF(getExp($2),getEquationItems($4),{},{})); }
                      | IF exp THEN equationsection ELSE equationsection ENDIF
                           { $$ = EQUATION(Absyn.EQ_IF(getExp($2),getEquationItems($4),{},getEquationItems($6))); }
                      | IF exp THEN equationsection ELSE ENDIF
                           { $$ = EQUATION(Absyn.EQ_IF(getExp($2),getEquationItems($4),{},{})); }
                      | IF exp THEN equationsection elseifs ENDIF
                           { $$ = EQUATION(Absyn.EQ_IF(getExp($2),getEquationItems($4),getElseIfs($5),{})); }
                      | IF exp THEN equationsection elseifs ELSE equationsection ENDIF
                           { $$ = EQUATION(Absyn.EQ_IF(getExp($2),getEquationItems($4),getElseIfs($5),getEquationItems($7))); }
                      | IF exp THEN equationsection elseifs ELSE ENDIF
                           { $$ = EQUATION(Absyn.EQ_IF(getExp($2),getEquationItems($4),getElseIfs($5),{})); }

elseifs               :  elseif { $$ = ELSEIFS(getElseIf($1)::{}); }
                        | elseif elseifs { $$ = ELSEIFS(getElseIf($1)::getElseIfs($2)); }
                        |/*empty */ { $$ = ELSEIFS({}); }

elseif               : ELSEIF exp THEN equationsection  { $$ = ELSEIF((getExp($2),getEquationItems($4))); }

/* Expressions and Elements */

elementItems         : elementItem { $$ = ELEMENTITEMS(getElementItemAllowAnnotation($1)::{}); }
                      | elementItem elementItems { $$ = ELEMENTITEMS(getElementItem($1)::getElementItems($2)); }
                      

elementItem         : element SEMICOLON { $$ = ELEMENTITEM(Absyn.ELEMENTITEM(getElement($1))); }
                    /*  | annotation SEMICOLON { $$ = ELEMENTITEM(Absyn.ANNOTATIONITEM(getAnnotation($1))); } */
                      
element             : componentclause
                        { $$ = $1; }
                    | classElement2
                        { $$ = $1; }
                    | importelementspec
                        { $$ = ELEMENT(Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),getElementSpec($1),yyinfo,NONE())); }
                    | extends
                       { $$ = ELEMENT(Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),getElementSpec($1),yyinfo,NONE())); }
                    | unitclause
                        { $$ = $1; }

unitclause         : DEFINEUNIT ident { $$ = ELEMENT(Absyn.DEFINEUNIT(getString($2),{})); }
                   | DEFINEUNIT ident LPAR namedargs RPAR { $$ = ELEMENT(Absyn.DEFINEUNIT(getString($2),getNamedArgs($4))); }


classElement2      : classelementspec
                        { $$ = ELEMENT(Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),getElementSpec($1),yyinfo,NONE())); }
                   
                   |classelementspec constraining_clause 
                        { $$ = ELEMENT(Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),getElementSpec($1),yyinfo,SOME(getConstrainClass($2)))); }
                       
                   | REDECLARE classelementspec
                        { $$ = ELEMENT(Absyn.ELEMENT(false,SOME(Absyn.REDECLARE()),Absyn.NOT_INNER_OUTER(),getElementSpec($2),yyinfo,NONE())); }




componentclause      :  elementspec
                        { $$ = ELEMENT(Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),getElementSpec($1),yyinfo,NONE())); }
	                  | innerouter elementspec
	                        { $$ = ELEMENT(Absyn.ELEMENT(false,NONE(),getInnerOuter($1),getElementSpec($2),yyinfo,NONE())); }
	                  | redeclarekeywords final innerouter elementspec
	                        { $$ = ELEMENT(Absyn.ELEMENT(getBoolean($2),SOME(getRedeclareKeywords($1)),getInnerOuter($3),getElementSpec($4),yyinfo,NONE())); }
	                  | redeclarekeywords final elementspec
	                       { $$ = ELEMENT(Absyn.ELEMENT(getBoolean($2),SOME(getRedeclareKeywords($1)),Absyn.NOT_INNER_OUTER(),getElementSpec($3),yyinfo,NONE())); }
                       | redeclarekeywords final elementspec constraining_clause
	                       { $$ = ELEMENT(Absyn.ELEMENT(getBoolean($2),SOME(getRedeclareKeywords($1)),Absyn.NOT_INNER_OUTER(),getElementSpec($3),yyinfo,SOME(getConstrainClass($4)))); }
                      | FINAL elementspec
                        { $$ = ELEMENT(Absyn.ELEMENT(true,NONE(),Absyn.NOT_INNER_OUTER(),getElementSpec($2),yyinfo,NONE())); }
                      | FINAL innerouter elementspec
                        { $$ = ELEMENT(Absyn.ELEMENT(true,NONE(),getInnerOuter($2),getElementSpec($3),yyinfo,NONE())); }
	
componentitems      : componentitem { $$ = COMPONENTITEMS(getComponentItem($1)::{}); }
                    | componentitem COMMA componentitems { $$ = COMPONENTITEMS(getComponentItem($1)::getComponentItems($3)); }

componentitem       : component comment { $$ = COMPONENTITEM(Absyn.COMPONENTITEM(getComponent($1),NONE(),SOME(getComment($2)))); }
                    | component componentcondition comment { $$ = COMPONENTITEM(Absyn.COMPONENTITEM(getComponent($1),SOME(getExp($2)),SOME(getComment($3)))); }

componentcondition : IF exp { $$ = $2; }

component           : ident arraySubscripts modification { $$ = COMPONENT(Absyn.COMPONENT(getString($1),getArrayDim($2),SOME(getModification($3)))); }
                    | ident arraySubscripts { $$ = COMPONENT(Absyn.COMPONENT(getString($1),getArrayDim($2),NONE())); }

modification        : EQUALS exp { $$ = MODIFICATION(Absyn.CLASSMOD({},Absyn.EQMOD(getExp($2),yyinfo))); }
                    | ASSIGN exp { $$ = MODIFICATION(Absyn.CLASSMOD({},Absyn.EQMOD(getExp($2),yyinfo))); }
                    | class_modification { $$ = $1; }

class_modification : elementargs
                      { $$ = MODIFICATION(Absyn.CLASSMOD(getElementArgs($1),Absyn.NOMOD())); }
                    | elementargs EQUALS exp
                      { $$ = MODIFICATION(Absyn.CLASSMOD(getElementArgs($1),Absyn.EQMOD(getExp($3),yyinfo))); }

annotation         : T_ANNOTATION elementargs { $$ = ANNOTATION(Absyn.ANNOTATION(getElementArgs($2))); }

elementargs         : LPAR argumentlist RPAR { $$ = $2; }

elementargs2         : LPAR argumentlist RPAR { $$ = $2; }
                     | /* empty */ { $$ = ELEMENTARGS({}); }

argumentlist        : elementarg { $$ = ELEMENTARGS({getElementArg($1)}); }
                    | elementarg COMMA argumentlist { $$ = ELEMENTARGS(getElementArg($1)::getElementArgs($3)); }

elementarg         : element_mod_rep { $$ = $1; }
                   | element_redec { $$ = $1; }

element_mod_rep   : element_mod { $$ = $1; }
                  | element_rep { $$ = $1; }

element_mod        : eachprefix final path
                      { $$ = ELEMENTARG(Absyn.MODIFICATION(getBoolean($2),getEach($1),getPath($3),NONE(),NONE(),yyinfo)); }
                   | eachprefix final path modification
                      { $$ = ELEMENTARG(Absyn.MODIFICATION(getBoolean($2),getEach($1),getPath($3),SOME(getModification($4)),NONE(),yyinfo)); }
                   | eachprefix final path string
                      { $$ = ELEMENTARG(Absyn.MODIFICATION(getBoolean($2),getEach($1),getPath($3),NONE(),SOME(getString($4)),yyinfo)); }
                   | eachprefix final path modification string
                      { $$ = ELEMENTARG(Absyn.MODIFICATION(getBoolean($2),getEach($1),getPath($3),SOME(getModification($4)),SOME(getString($5)),yyinfo)); }


element_rep       :  REPLACEABLE eachprefix final classelementspec
                   { $$ = ELEMENTARG(Absyn.REDECLARATION(getBoolean($3),Absyn.REPLACEABLE(),getEach($2),getElementSpec($4),NONE(),yyinfo)); }
                   | REPLACEABLE eachprefix final elementspec2
                   { $$ = ELEMENTARG(Absyn.REDECLARATION(getBoolean($3),Absyn.REPLACEABLE(),getEach($2),getElementSpec($4),NONE(),yyinfo)); }
                   | REPLACEABLE eachprefix final classelementspec constraining_clause
                     { $$ = ELEMENTARG(Absyn.REDECLARATION(getBoolean($3),Absyn.REDECLARE(),getEach($2),getElementSpec($4),SOME(getConstrainClass($5)),yyinfo)); }                 
                   | REDECLARE REPLACEABLE eachprefix final classelementspec constraining_clause
                     { $$ = ELEMENTARG(Absyn.REDECLARATION(getBoolean($4),Absyn.REDECLARE_REPLACEABLE(),getEach($3),getElementSpec($5),SOME(getConstrainClass($6)),yyinfo)); }
                   | REDECLARE REPLACEABLE eachprefix final classelementspec
                     { $$ = ELEMENTARG(Absyn.REDECLARATION(getBoolean($4),Absyn.REDECLARE_REPLACEABLE(),getEach($3),getElementSpec($5),NONE(),yyinfo)); }
                   | REPLACEABLE eachprefix final elementspec2 constraining_clause
                     { $$ = ELEMENTARG(Absyn.REDECLARATION(getBoolean($3),Absyn.REDECLARE(),getEach($2),getElementSpec($4),SOME(getConstrainClass($5)),yyinfo)); }


element_redec     : REDECLARE eachprefix final classelementspec
                     { $$ = ELEMENTARG(Absyn.REDECLARATION(getBoolean($3),Absyn.REDECLARE(),getEach($2),getElementSpec($4),NONE(),yyinfo)); }
                   | REDECLARE eachprefix final elementspec2
                     { $$ = ELEMENTARG(Absyn.REDECLARATION(getBoolean($3),Absyn.REDECLARE(),getEach($2),getElementSpec($4),NONE(),yyinfo)); }


elementspec2          :  elementAttr typespec  componentitems2 // arraydim from typespec should be in elementAttr arraydim
                        { $$ = fixArray($1,$2,$3); }
                      |  typespec  componentitems2 // arraydim from typespec should be in elementAttr arraydim
                        { $$ = fixArray(ELEMENTATTRIBUTES(Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(), Absyn.BIDIR(),{})),$1,$2); }

componentitems2	 : component comment   { $$ = COMPONENTITEMS({Absyn.COMPONENTITEM(getComponent($1),NONE(),SOME(getComment($2)))}); }

eachprefix         : EACH { $$ = EACH(Absyn.EACH()); }
                   | /* empty */ { $$ = EACH(Absyn.NON_EACH()); }

redeclarekeywords   : REDECLARE { $$ = REDECLAREKEYWORDS(Absyn.REDECLARE()); }
                    | REPLACEABLE { $$ = REDECLAREKEYWORDS(Absyn.REPLACEABLE()); }
                    | REDECLARE REPLACEABLE { $$ = REDECLAREKEYWORDS(Absyn.REDECLARE_REPLACEABLE()); }

innerouter		    : INNER { $$ = INNEROUTER(Absyn.INNER()); }
                     | T_OUTER { $$ = INNEROUTER(Absyn.OUTER()); }
                     | INNER T_OUTER { $$ = INNEROUTER(Absyn.INNER_OUTER()); }
                    //| /* empty */ { $$[InnerOuter] = Absyn.NOT_INNER_OUTER(); }


importelementspec    :  import comment { $$ = ELEMENTSPEC(Absyn.IMPORT(getImport($1),SOME(getComment($2)),yyinfo)); }

classelementspec    : class { $$ = ELEMENTSPEC(Absyn.CLASSDEF(false,getClass($1))); }
                    | REPLACEABLE class { $$ = ELEMENTSPEC(Absyn.CLASSDEF(true,getClass($2))); }

import              : IMPORT path  { $$ = IMPORT(Absyn.QUAL_IMPORT(getPath($2))); }
                     | IMPORT path STAR_EW { $$ = IMPORT(Absyn.UNQUAL_IMPORT(getPath($2))); }
                     | IMPORT ident EQUALS path { $$ = IMPORT(Absyn.NAMED_IMPORT(getString($2),getPath($4))); }

extends              : EXTENDS path elementargs2
                       { $$ = ELEMENTSPEC(Absyn.EXTENDS(getPath($2),getElementArgs($3),NONE())); }
                     | EXTENDS path elementargs2 annotation
                       { $$ = ELEMENTSPEC(Absyn.EXTENDS(getPath($2),getElementArgs($3),SOME(getAnnotation($4)))); }

constraining_clause : extends { $$ = CONSTRAINCLASS(Absyn.CONSTRAINCLASS(getElementSpec($1),NONE())); }
                    | CONSTRAINEDBY path elementargs2 { $$ = CONSTRAINCLASS(Absyn.CONSTRAINCLASS(Absyn.EXTENDS(getPath($2),getElementArgs($3),NONE()),NONE())); }
                    | CONSTRAINEDBY path elementargs2 comment
                        { $$ = CONSTRAINCLASS(Absyn.CONSTRAINCLASS(Absyn.EXTENDS(getPath($2),getElementArgs($3),NONE()),SOME(getComment($4)))); }

elementspec          :  elementAttr typespec  componentitems // arraydim from typespec should be in elementAttr arraydim
                        { $$ = fixArray($1,$2,$3); }
                      |  typespec  componentitems // arraydim from typespec should be in elementAttr arraydim
                        { $$ = fixArray(ELEMENTATTRIBUTES(Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(), Absyn.BIDIR(),{})),$1,$2); }

elementAttr          : parallelism direction
                         { $$ = ELEMENTATTRIBUTES(Absyn.ATTR(false,false,getParallelism($1),Absyn.VAR(),getDirection($2),{})); }

                      |parallelism
                         { $$ = ELEMENTATTRIBUTES(Absyn.ATTR(false,false,getParallelism($1),Absyn.VAR(),Absyn.BIDIR(),{})); }

                      |direction
                         { $$ = ELEMENTATTRIBUTES(Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(), getDirection($1),{})); }
                      |variability
                         { $$ = ELEMENTATTRIBUTES(Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),getVariability($1), Absyn.BIDIR(),{})); }

                      | variability direction
                         { $$ = ELEMENTATTRIBUTES(Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),getVariability($1), getDirection($2),{})); }

                      | STREAM variability direction
                         { $$ = ELEMENTATTRIBUTES(Absyn.ATTR(false,true,Absyn.NON_PARALLEL(),getVariability($2), getDirection($3),{})); }
                      | FLOW variability direction
                         { $$ = ELEMENTATTRIBUTES(Absyn.ATTR(true,false,Absyn.NON_PARALLEL(),getVariability($2), getDirection($3),{})); }
                      | FLOW direction
                         { $$ = ELEMENTATTRIBUTES(Absyn.ATTR(true,false,Absyn.NON_PARALLEL(),Absyn.VAR(), getDirection($2),{})); }
                      | FLOW
                         { $$ = ELEMENTATTRIBUTES(Absyn.ATTR(true,false,Absyn.NON_PARALLEL(),Absyn.VAR(),Absyn.BIDIR(),{})); }
                      | STREAM
                         { $$ = ELEMENTATTRIBUTES(Absyn.ATTR(false,true,Absyn.NON_PARALLEL(),Absyn.VAR(),Absyn.BIDIR(),{})); }
                      
parallelism          : T_PARGLOBAL { $$ = PARALLELISM(Absyn.PARGLOBAL()); }
                      |T_PARLOCAL { $$ = PARALLELISM(Absyn.PARLOCAL()); }
                     // | /* empty */ { $$[Parallelism] = Absyn.NON_PARALLEL(); }


variability          : PARAMETER { $$ = VARIABILITY(Absyn.PARAM()); }
                      | CONSTANT { $$ = VARIABILITY(Absyn.CONST()); }
                      | DISCRETE { $$ = VARIABILITY(Absyn.DISCRETE()); }
                     // | /* empty */ { $$[Variability] = Absyn.VAR(); }

direction           : T_INPUT { $$ = DIRECTION(Absyn.INPUT()); }
                     | T_OUTPUT { $$ = DIRECTION(Absyn.OUTPUT()); }
                    // | /* empty */ { $$[Direction] = Absyn.BIDIR(); }


/* Type specification */

typespec             : path arraySubscripts { $$ = TYPESPEC(Absyn.TPATH(getPath($1),SOME(getArrayDim($2)))); }
                     | path arrayComplex { $$ = TYPESPEC(Absyn.TCOMPLEX(getPath($1),getTypeSpecs($2),NONE())); }

arrayComplex        : LESS typespecs GREATER { $$ = $1; }

typespecs           : typespec { $$ = TYPESPECS({getTypeSpec($1)}); }
                     | typespec COMMA typespecs { $$ = TYPESPECS(getTypeSpec($1)::getTypeSpecs($2)); }

arraySubscripts     : LBRACK arrayDim RBRACK { $$ = $2; }
                    | /* empty */ { $$ = ARRAYDIM({}); }

arrayDim			: subscript { $$ = ARRAYDIM({getSubscript($1)}); }
              | subscript COMMA arrayDim { $$ = ARRAYDIM(getSubscript($1)::getArrayDim($3)); }

subscript           : exp { $$ = SUBSCRIPT(Absyn.SUBSCRIPT(getExp($1))); }
                    | COLON { $$ = SUBSCRIPT(Absyn.NOSUB()); }

/* function calls */

functioncall        : LPAR functionargs RPAR { $$ = $2; }

functionargs        : namedargs
                       { $$ = FUNCTIONARGS(Absyn.FUNCTIONARGS({},getNamedArgs($1))); }
                    | functionargs2 { $$ = $1; }
                    | functionargs3 { $$ = $1; }



functionargs2       : explist2
                       { $$ = FUNCTIONARGS(Absyn.FUNCTIONARGS(getExps($1),{})); }
                    | explist2 COMMA namedargs
                       { $$ = FUNCTIONARGS(Absyn.FUNCTIONARGS(getExps($1),getNamedArgs($3))); }



functionargs3       :  exp FOR foriterators
                       { $$ = FUNCTIONARGS(Absyn.FOR_ITER_FARG(getExp($1),getForIterators($3))); }


namedargs           : namedarg { $$ = NAMEDARGS({getNamedArg($1)}); }
                     | namedarg COMMA namedargs { $$ = NAMEDARGS(getNamedArg($1)::getNamedArgs($3)); }


namedarg            : ident EQUALS exp { $$ = NAMEDARG(Absyn.NAMEDARG(getString($1),getExp($3))); }

/* expressions */

exp	: simpleExp { $$ = $1; }
    | if_exp { $$ = $1; }
    | matchcont { $$ = $1; }
    
matchcont        : MATCH exp cases ENDMATCH { $$ = EXP(Absyn.MATCHEXP(Absyn.MATCH(),getExp($2),{},getCases($3),NONE())); }
                 | MATCH exp matchlocal cases ENDMATCH { $$ = EXP(Absyn.MATCHEXP(Absyn.MATCH(),getExp($2),getElementItems($3),getCases($4),NONE())); }
                 | MATCHCONTINUE exp cases ENDMATCHCONTINUE { $$ = EXP(Absyn.MATCHEXP(Absyn.MATCHCONTINUE(),getExp($2),{},getCases($3),NONE())); }
                 | MATCHCONTINUE exp matchlocal cases ENDMATCHCONTINUE { $$ = EXP(Absyn.MATCHEXP(Absyn.MATCHCONTINUE(),getExp($2),getElementItems($3),getCases($4),NONE())); }


if_exp           : IF exp THEN exp ELSE exp { $$ = EXP(Absyn.IFEXP(getExp($2),getExp($4),getExp($6),{})); }
                 | IF exp THEN exp expelseifs ELSE exp  { $$ = EXP(Absyn.IFEXP(getExp($2),getExp($4),getExp($7),getExpElseIfs($5))); }

expelseifs        :  expelseif { $$ = EXPELSEIFS({getExpElseIf($1)}); }
                  | expelseif expelseifs { $$ = EXPELSEIFS(getExpElseIf($1)::getExpElseIfs($2)); }

expelseif       : ELSEIF exp THEN exp  { $$ = EXPELSEIF((getExp($2),getExp($4))); }


matchlocal        : LOCAL elementItems { $$ = $2; }

cases             : case { $$ = CASES({getCase($1)}); }
                  | case cases { $$ = CASES(getCase($1)::getCases($2)); }

case              : CASE casearg THEN exp SEMICOLON
                       { $$ = CASE(Absyn.CASE(getExp($2),NONE(),yyinfo,{},{},getExp($4),yyinfo,NONE(),yyinfo)); }
                  | CASE casearg EQUATION THEN exp SEMICOLON
                       { $$ = CASE(Absyn.CASE(getExp($2),NONE(),yyinfo,{},{},getExp($4),yyinfo,NONE(),yyinfo)); }
                  | CASE casearg EQUATION equationsection THEN exp SEMICOLON
                       { $$ = CASE(Absyn.CASE(getExp($2),NONE(),yyinfo,{},getEquationItems($4),getExp($6),yyinfo,NONE(),yyinfo)); }
                  | ELSE THEN exp SEMICOLON
                       { $$ = CASE(Absyn.ELSE({},{},getExp($3),yyinfo,NONE(),yyinfo)); }
                  | ELSE EQUATION equationsection THEN exp SEMICOLON
                       { $$ = CASE(Absyn.ELSE({},getEquationItems($3),getExp($5),yyinfo,NONE(),yyinfo)); }

casearg          : exp { $$ = $1; }


simpleExp        : logicexp { $$ = $1; }
                  | rangeExp { $$ = $1; }
                  | headtail { $$ = $1; }
                  | ident AS simpleExp { $$ = EXP(Absyn.AS(getString($1),getExp($3))); }

headtail        : logicexp COLONCOLON logicexp { $$ = EXP(Absyn.CONS(getExp($1),getExp($3))); }
                 | logicexp COLONCOLON headtail { $$ = EXP(Absyn.CONS(getExp($1),getExp($3))); }

rangeExp          : logicexp COLON logicexp { $$ = EXP(Absyn.RANGE(getExp($1),NONE(),getExp($3))); }
                  | logicexp COLON logicexp COLON logicexp { $$ = EXP(Absyn.RANGE(getExp($1),SOME(getExp($3)),getExp($5))); }
				
logicexp          : logicterm { $$ = $1; }
                   | logicexp T_OR logicterm  { $$ = EXP(Absyn.LBINARY(getExp($1),Absyn.OR(),getExp($3))); }

logicterm          : logfactor { $$ = $1; }
                   | logicterm T_AND logfactor  { $$ = EXP(Absyn.LBINARY(getExp($1),Absyn.AND(),getExp($3))); }

logfactor         : relterm  { $$ = $1; }
                   | T_NOT relterm { $$ = EXP(Absyn.LUNARY(Absyn.NOT(),getExp($2))); }

relterm            : addterm { $$ = $1; }
                   | addterm relOperator addterm { $$ = EXP(Absyn.RELATION(getExp($1),getOperator($2),getExp($3))); }

addterm             : term { $$ = $1; }
                    | unoperator  term  { $$ = EXP(Absyn.UNARY(getOperator($1),getExp($2))); }
                    | addterm woperator term  { $$ = EXP(Absyn.BINARY(getExp($1),getOperator($2),getExp($3))); }

term               : factor { $$ = EXP(getExp($1)); }
					| term soperator factor  { $$ = EXP(Absyn.BINARY(getExp($1),getOperator($2),getExp($3))); }

factor              : expElement { $$ = EXP(getExp($1)); }
					| expElement power factor  { $$ = EXP(Absyn.BINARY(getExp($1),getOperator($2),getExp($3))); }
					
expElement          : number { $$ = $1; }
                     | cref { $$ = EXP(Absyn.CREF(getCref($1))); }
                     | T_FALSE { $$ = EXP(Absyn.BOOL(false)); }
                     | T_TRUE { $$ = EXP(Absyn.BOOL(true)); }
                     | string { $$ = EXP(Absyn.STRING(getString($1))); }
                     | tuple  { $$ = $1; }
                     | LBRACE explist2 RBRACE { $$ = EXP(Absyn.ARRAY(getExps($2))); }
                     | LBRACE functionargs RBRACE { $$ = EXP(Absyn.CALL(Absyn.CREF_IDENT("array",{}),getFunctionArgs($2))); }
                     | LBRACK matrix RBRACK { $$ = EXP(Absyn.MATRIX(getMatrix($2))); }
                     | cref functioncall { $$ = EXP(Absyn.CALL(getCref($1),getFunctionArgs($2))); }
                     | FUNCTION cref functioncall { $$ = EXP(Absyn.PARTEVALFUNCTION(getCref($2),getFunctionArgs($3))); }                   
                     | DER functioncall { $$ = EXP(Absyn.CALL(Absyn.CREF_IDENT("der",{}),getFunctionArgs($2))); }
                     | T_INITIAL functioncall { $$ = EXP(Absyn.CALL(Absyn.CREF_IDENT("initial",{}),getFunctionArgs($2))); }
                     | LPAR exp RPAR { $$ = $2; }
                     | T_END { $$ = EXP(Absyn.END()); }

number             : UNSIGNED_INTEGER { $$ = EXP(Absyn.INTEGER(stringInt(getString($1)))); }
                    | UNSIGNED_REAL { $$ = EXP(Absyn.REAL(getString($1))); }

matrix             : explist2  { $$ = MATRIX({getExps($1)}); }
                    | explist2 SEMICOLON matrix  { $$ = MATRIX(getExps($1)::getMatrix($3)); }

tuple               : LPAR explist RPAR { $$ = EXP(Absyn.TUPLE(getExps($2))); }

explist             : exp COMMA exp { $$ = EXPS({getExp($1),getExp($3)}); }
                    | exp COMMA explist { $$ = EXPS(getExp($1)::getExps($3)); }
                    | /* empty */ { $$ = EXPS({}); }

explist2            : exp  { $$ = EXPS({getExp($1)}); }
                    | explist2 COMMA exp { $$ = EXPS(listReverse(getExp($3)::listReverse(getExps($1)))); }
                    | /* empty */ { $$ = EXPS({}); }

cref                :  ident arraySubscripts { $$ = CREF(Absyn.CREF_IDENT(getString($1),getArrayDim($2))); }
                     | ident arraySubscripts DOT cref  { $$ = CREF(Absyn.CREF_QUAL(getString($1),getArrayDim($2),getCref($4))); }
                     | DOT cref  { $$ = CREF(Absyn.CREF_FULLYQUALIFIED(getCref($2))); }
                     | WILD { $$ = CREF(Absyn.WILD()); }
                     | ALLWILD { $$ = CREF(Absyn.ALLWILD()); }

unoperator          : PLUS { $$ = OPERATOR(Absyn.UPLUS()); }
                     | MINUS { $$ = OPERATOR(Absyn.UMINUS()); }
                     |  PLUS_EW { $$ = OPERATOR(Absyn.UPLUS_EW()); }
                     | MINUS_EW { $$ = OPERATOR(Absyn.UMINUS_EW()); }


woperator			: PLUS { $$ = OPERATOR(Absyn.ADD()); }
                     | MINUS { $$ = OPERATOR(Absyn.SUB()); }
                     |  PLUS_EW { $$ = OPERATOR(Absyn.ADD_EW()); }
                     | MINUS_EW { $$ = OPERATOR(Absyn.SUB_EW()); }


soperator			: STAR { $$ = OPERATOR(Absyn.MUL()); }
                     | SLASH { $$ = OPERATOR(Absyn.DIV()); }
                     | STAR_EW { $$ = OPERATOR(Absyn.MUL_EW()); }
                     | SLASH_EW { $$ = OPERATOR(Absyn.DIV_EW()); }

power              : POWER  { $$ = OPERATOR(Absyn.POW()); }
                     | POWER_EW { $$ = OPERATOR(Absyn.POW_EW()); }

relOperator			: LESS { $$ = OPERATOR(Absyn.LESS()); }
                     | LESSEQ { $$ = OPERATOR(Absyn.LESSEQ()); }
                     | GREATER { $$ = OPERATOR(Absyn.GREATER()); }
                     | GREATEREQ { $$ = OPERATOR(Absyn.GREATEREQ()); }
                     | EQEQ { $$ = OPERATOR(Absyn.EQUAL()); }
                     | LESSGT { $$ = OPERATOR(Absyn.NEQUAL()); }

path                 : ident { $$ = PATH(Absyn.IDENT(getString($1))); }
                      | ident DOT path { $$ = PATH(Absyn.QUALIFIED(getString($1),getPath($3))); }
                      | DOT path { $$ = PATH(Absyn.FULLYQUALIFIED(getPath($2))); }

ident                :  IDENT { $$ = $1; }

string               : STRING { $$ = STRING(trimquotes(getString($1))); } // trim the quote of the string

comment              : string { $$ = COMMENT(Absyn.COMMENT(NONE(),SOME(getString($1)))); }
                     | string annotation { $$ = COMMENT(Absyn.COMMENT(SOME(getAnnotation($2)),SOME(getString($1)))); }
                     | annotation { $$ = COMMENT(Absyn.COMMENT(SOME(getAnnotation($1)),NONE())); }
                     | /* empty */ { $$ = COMMENT(Absyn.COMMENT(NONE(),NONE())); }


%%

public function trimquotes
"removes chars in charsToRemove from inString"
  input String inString;
  output String outString;
 algorithm
  if (stringLength(inString)>2) then
    outString := System.substring(inString,2,stringLength(inString)-1);
  else
    outString := "";
  end if;
end trimquotes;

/* A little more special access functions */

function fixArray
  input AstItem elementAttributes;
  input AstItem typeSpec;
  input AstItem items;
  output AstItem spec;
protected
  Absyn.ElementAttributes v1ElementAttributes2;
  Absyn.TypeSpec v2TypeSpec2;
  Boolean flowPrefix,b1,b2 "flow" ;
  Boolean streamPrefix "stream" ;
  Absyn.Variability variability,v1 "variability ; parameter, constant etc." ;
  Absyn.Direction direction,d1 "direction" ;
  Absyn.Parallelism parallelism, prl;
  Absyn.ArrayDim arrayDim,a1 "arrayDim" ;
  Absyn.Path path,p1;
  Option<Absyn.ArrayDim> oa1;
algorithm
  ELEMENTATTRIBUTES(Absyn.ATTR(flowPrefix=b1,streamPrefix=b2,parallelism=prl,variability=v1,direction=d1,arrayDim=a1)) := elementAttributes;
  TYPESPEC(Absyn.TPATH(path=p1,arrayDim=oa1)) :=typeSpec;
  a1 := match oa1
    local Absyn.ArrayDim l1;
     case SOME(l1) then (l1);
     case NONE() then ({});
  end match;

  v1ElementAttributes2 := Absyn.ATTR(b1,b2,prl,v1,d1,a1);
  v2TypeSpec2 := Absyn.TPATH(p1,NONE());
  spec := ELEMENTSPEC(Absyn.COMPONENTS(v1ElementAttributes2,v2TypeSpec2,getComponentItems(items)));
end fixArray;

function getString
  input AstItem item;
  output String out;
algorithm
  out := match item
    local
      OMCCTypes.Token tok;
    case STRING(string=out) then out;
    case TOKEN(tok=tok) then OMCCTypes.getStringValue(tok);
    else equation print("getString() failed\n"); then fail();
  end match;
end getString;

function getClassPrefixPartial
  input AstItem item;
  output Boolean out;
algorithm
  CLASSPREFIX(part=out) := item;
end getClassPrefixPartial;

function getClassPrefixEncapsulated
  input AstItem item;
  output Boolean out;
algorithm
  CLASSPREFIX(encap=out) := item;
end getClassPrefixEncapsulated;

/* Type Declarations */
function getProgram
  input AstItem item;
  output Absyn.Program out;
algorithm
  PROGRAM(program=out) := item;
end getProgram;

function getToken
  input AstItem item;
  output OMCCTypes.Token out;
algorithm
  OMCCTypes.TOKEN(tok=out) := item;
end getToken;

function getWithin
  input AstItem item;
  output Absyn.Within out;
algorithm
  WITHIN(_within=out) := item;
end getWithin;

function getClasses
  input AstItem item;
  output list<Absyn.Class> out;
algorithm
  CLASSES(classes=out) := item;
end getClasses;

function getClass
  input AstItem item;
  output Absyn.Class out;
algorithm
  CLASS(_class=out) := item;
end getClass;

function getPath
  input AstItem item;
  output Absyn.Path out;
algorithm
  PATH(path=out) := item;
end getPath;

function getClassDef
  input AstItem item;
  output Absyn.ClassDef out;
algorithm
  CLASSDEF(classdef=out) := item;
end getClassDef;

function getClassPart
  input AstItem item;
  output Absyn.ClassPart out;
algorithm
  CLASSPART(part=out) := item;
end getClassPart;

function getClassParts
  input AstItem item;
  output list<Absyn.ClassPart> out;
algorithm
  CLASSPARTS(parts=out) := item;
end getClassParts;

function getImport
  input AstItem item;
  output Absyn.Import out;
algorithm
  IMPORT(_import=out) := item;
end getImport;

function getElementItem
  input AstItem item;
  output Absyn.ElementItem out;
algorithm
  ELEMENTITEM(item=out) := item;
 /* _ := match out
    case (_) equation print("Error: AnnotationItem only allowed at the end of the class\n"); then fail();
    else ();
  end match; */
end getElementItem;

function getElementItemAllowAnnotation
  input AstItem item;
  output Absyn.ElementItem out;
algorithm
  ELEMENTITEM(item=out) := item;
end getElementItemAllowAnnotation;

function getElementItems
  input AstItem item;
  output list<Absyn.ElementItem> out;
algorithm
  ELEMENTITEMS(items=out) := item;
end getElementItems;

function getElementArg
  input AstItem item;
  output Absyn.ElementArg out;
algorithm
  ELEMENTARG(arg=out) := item;
end getElementArg;

function getElementArgs
  input AstItem item;
  output list<Absyn.ElementArg> out;
algorithm
  ELEMENTARGS(args=out) := item;
end getElementArgs;

function getElementAttributes
  input AstItem item;
  output Absyn.ElementAttributes out;
algorithm
  ELEMENTATTRIBUTES(attrs=out) := item;
end getElementAttributes;

function getElement
  input AstItem item;
  output Absyn.Element out;
algorithm
  ELEMENT(element=out) := item;
end getElement;

function getElementSpec
  input AstItem item;
  output Absyn.ElementSpec out;
algorithm
  ELEMENTSPEC(spec=out) := item;
end getElementSpec;

function getRestriction
  input AstItem item;
  output Absyn.Restriction out;
algorithm
  RESTRICTION(restriction=out) := item;
end getRestriction;

function getFunctionArgs
  input AstItem item;
  output Absyn.FunctionArgs out;
algorithm
  FUNCTIONARGS(args=out) := item;
end getFunctionArgs;

function getNamedArg
  input AstItem item;
  output Absyn.NamedArg out;
algorithm
  NAMEDARG(arg=out) := item;
end getNamedArg;

function getNamedArgs
  input AstItem item;
  output list<Absyn.NamedArg> out;
algorithm
  NAMEDARGS(arg=out) := item;
end getNamedArgs;

function getBoolean
  input AstItem item;
  output Boolean out;
algorithm
  BOOLEAN(bool=out) := item;
end getBoolean;

function getEnumDef
  input AstItem item;
  output Absyn.EnumDef out;
algorithm
  ENUMDEF(def=out) := item;
end getEnumDef;

function getEnumLiteral
  input AstItem item;
  output Absyn.EnumLiteral out;
algorithm
  ENUMLITERAL(literal=out) := item;
end getEnumLiteral;

function getEnumLiterals
  input AstItem item;
  output list<Absyn.EnumLiteral> out;
algorithm
  ENUMLITERALS(literals=out) := item;
end getEnumLiterals;

function getComment
  input AstItem item;
  output Absyn.Comment out;
algorithm
  COMMENT(comment=out) := item;
end getComment;

function getEquation
  input AstItem item;
  output Absyn.Equation out;
algorithm
  EQUATION(eq=out) := item;
end getEquation;

function getEquationItem
  input AstItem item;
  output Absyn.EquationItem out;
algorithm
  EQUATIONITEM(item=out) := item;
end getEquationItem;

function getEquationItems
  input AstItem item;
  output list<Absyn.EquationItem> out;
algorithm
  EQUATIONITEMS(items=out) := item;
end getEquationItems;

function getAlgorithm
  input AstItem item;
  output Absyn.Algorithm out;
algorithm
  ALGORITHM(alg=out) := item;
end getAlgorithm;

function getAlgorithmItem
  input AstItem item;
  output Absyn.AlgorithmItem out;
algorithm
  ALGORITHMITEM(item=out) := item;
end getAlgorithmItem;

function getAlgorithmItems
  input AstItem item;
  output list<Absyn.AlgorithmItem> out;
algorithm
  ALGORITHMITEMS(items=out) := item;
end getAlgorithmItems;

function getExternalDecl
  input AstItem item;
  output Absyn.ExternalDecl out;
algorithm
  EXTERNALDECL(decl=out) := item;
end getExternalDecl;

function getAnnotation
  input AstItem item;
  output Absyn.Annotation out;
algorithm
  ANNOTATION(ann=out) := item;
end getAnnotation;

function getCref
  input AstItem item;
  output Absyn.ComponentRef out;
algorithm
  CREF(cref=out) := item;
end getCref;

function getExp
  input AstItem item;
  output Absyn.Exp out;
algorithm
  EXP(exp=out) := item;
end getExp;

function getExps
  input AstItem item;
  output list<Absyn.Exp> out;
algorithm
  EXPS(exps=out) := item;
end getExps;

function getForIterator
  input AstItem item;
  output Absyn.ForIterator out;
algorithm
  FORITERATOR(iterator=out) := item;
end getForIterator;

function getForIterators
  input AstItem item;
  output list<Absyn.ForIterator> out;
algorithm
  FORITERATORS(iterators=out) := item;
end getForIterators;

function getAlgElseIf
  input AstItem item;
  output tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> out;
algorithm
  ALGELSEIF(elseIf=out) := item;
end getAlgElseIf;

function getAlgElseIfs
  input AstItem item;
  output list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> out;
algorithm
  ALGELSEIFS(elseIfs=out) := item;
end getAlgElseIfs;

function getAlgElseWhen
  input AstItem item;
  output tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> out;
algorithm
  ALGELSEWHEN(elseWhen=out) := item;
end getAlgElseWhen;

function getAlgElseWhens
  input AstItem item;
  output list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> out;
algorithm
  ALGELSEWHENS(elseWhens=out) := item;
end getAlgElseWhens;

function getElseWhen
  input AstItem item;
  output tuple<Absyn.Exp, list<Absyn.EquationItem>> out;
algorithm
  ELSEWHEN(elseWhen=out) := item;
end getElseWhen;

function getElseWhens
  input AstItem item;
  output list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> out;
algorithm
  ELSEWHENS(elseWhens=out) := item;
end getElseWhens;

function getElseIf
  input AstItem item;
  output tuple<Absyn.Exp, list<Absyn.EquationItem>> out;
algorithm
  ELSEIF(elseIf=out) := item;
end getElseIf;

function getElseIfs
  input AstItem item;
  output list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> out;
algorithm
  ELSEIFS(elseIfs=out) := item;
end getElseIfs;

function getInnerOuter
  input AstItem item;
  output Absyn.InnerOuter out;
algorithm
  INNEROUTER(innerOuter=out) := item;
end getInnerOuter;

function getRedeclareKeywords
  input AstItem item;
  output Absyn.RedeclareKeywords out;
algorithm
  REDECLAREKEYWORDS(redeclareKeywords=out) := item;
end getRedeclareKeywords;

function getConstrainClass
  input AstItem item;
  output Absyn.ConstrainClass out;
algorithm
  CONSTRAINCLASS(cc=out) := item;
end getConstrainClass;

function getComponent
  input AstItem item;
  output Absyn.Component out;
algorithm
  COMPONENT(component=out) := item;
end getComponent;

function getComponentItem
  input AstItem item;
  output Absyn.ComponentItem out;
algorithm
  COMPONENTITEM(item=out) := item;
end getComponentItem;

function getComponentItems
  input AstItem item;
  output list<Absyn.ComponentItem> out;
algorithm
  COMPONENTITEMS(items=out) := item;
end getComponentItems;

function getArrayDim
  input AstItem item;
  output Absyn.ArrayDim out;
algorithm
  ARRAYDIM(dim=out) := item;
end getArrayDim;

function getModification
  input AstItem item;
  output Absyn.Modification out;
algorithm
  MODIFICATION(mod=out) := item;
end getModification;

function getEach
  input AstItem item;
  output Absyn.Each out;
algorithm
  EACH(_each=out) := item;
end getEach;

function getParallelism
  input AstItem item;
  output Absyn.Parallelism out;
algorithm
  PARALLELISM(parallelism=out) := item;
end getParallelism;

function getDirection
  input AstItem item;
  output Absyn.Direction out;
algorithm
  DIRECTION(direction=out) := item;
end getDirection;

function getVariability
  input AstItem item;
  output Absyn.Variability out;
algorithm
  VARIABILITY(variability=out) := item;
end getVariability;

function getTypeSpec
  input AstItem item;
  output Absyn.TypeSpec out;
algorithm
  TYPESPEC(spec=out) := item;
end getTypeSpec;

function getTypeSpecs
  input AstItem item;
  output list<Absyn.TypeSpec> out;
algorithm
  TYPESPECS(specs=out) := item;
end getTypeSpecs;

function getSubscript
  input AstItem item;
  output Absyn.Subscript out;
algorithm
  SUBSCRIPT(subscript=out) := item;
end getSubscript;

function getCase
  input AstItem item;
  output Absyn.Case out;
algorithm
  CASE(_case=out) := item;
end getCase;

function getCases
  input AstItem item;
  output list<Absyn.Case> out;
algorithm
  CASES(cases=out) := item;
end getCases;

function getExpElseIf
  input AstItem item;
  output tuple<Absyn.Exp, Absyn.Exp> out;
algorithm
  EXPELSEIF(elseIf=out) := item;
end getExpElseIf;

function getExpElseIfs
  input AstItem item;
  output list<tuple<Absyn.Exp, Absyn.Exp>> out;
algorithm
  EXPELSEIFS(elseIfs=out) := item;
end getExpElseIfs;

function getOperator
  input AstItem item;
  output Absyn.Operator out;
algorithm
  OPERATOR(op=out) := item;
end getOperator;

function getMatrix
  input AstItem item;
  output list<list<Absyn.Exp>> out;
algorithm
  MATRIX(matrix=out) := item;
end getMatrix;

function itemStr
  input AstItem item;
  output String str;
algorithm
  str := match item
    local
      OMCCTypes.Token tok;
    case TOKEN(tok=tok) then OMCCTypes.printToken(tok);
    else anyString(item);
  end match;
end itemStr;

  module Absyn


    using MetaModelica
    #= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
    using ExportAll
    #= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#

    @UniontypeDecl ForIterator
    @UniontypeDecl Program
    @UniontypeDecl Within
    @UniontypeDecl Class
    @UniontypeDecl ClassDef
    @UniontypeDecl TypeSpec
    @UniontypeDecl EnumDef
    @UniontypeDecl EnumLiteral
    @UniontypeDecl ClassPart
    @UniontypeDecl ElementItem
    @UniontypeDecl Element
    @UniontypeDecl ConstrainClass
    @UniontypeDecl ElementSpec
    @UniontypeDecl InnerOuter
    @UniontypeDecl Import
    @UniontypeDecl GroupImport
    @UniontypeDecl ComponentItem
    @UniontypeDecl Component
    @UniontypeDecl EquationItem
    @UniontypeDecl AlgorithmItem
    @UniontypeDecl Equation
    @UniontypeDecl Algorithm
    @UniontypeDecl Modification
    @UniontypeDecl EqMod
    @UniontypeDecl ElementArg
    @UniontypeDecl RedeclareKeywords
    @UniontypeDecl Each
    @UniontypeDecl ElementAttributes
    @UniontypeDecl IsField
    @UniontypeDecl Parallelism
    @UniontypeDecl FlowStream
    @UniontypeDecl Variability
    @UniontypeDecl Direction
    @UniontypeDecl Exp
    @UniontypeDecl Case
    @UniontypeDecl MatchType
    @UniontypeDecl CodeNode
    @UniontypeDecl FunctionArgs
    @UniontypeDecl ReductionIterType
    @UniontypeDecl NamedArg
    @UniontypeDecl Operator
    @UniontypeDecl Subscript
    @UniontypeDecl ComponentRef
    @UniontypeDecl Path
    @UniontypeDecl Restriction
    @UniontypeDecl FunctionPurity
    @UniontypeDecl FunctionRestriction
    @UniontypeDecl Annotation
    @UniontypeDecl Comment
    @UniontypeDecl ExternalDecl
    @UniontypeDecl Ref
    @UniontypeDecl Msg

         #= /*
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
         * from the URLs: http:www.ida.liu.se/projects/OpenModelica or
         * http:www.openmodelica.org, and in the OpenModelica distribution.
         * GNU version 3 is obtained from: http:www.gnu.org/copyleft/gpl.html.
         *
         * This program is distributed WITHOUT ANY WARRANTY; without
         * even the implied warranty of  MERCHANTABILITY or FITNESS
         * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
         * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
         *
         * See the full OSMC Public License conditions for more details.
         *
         */ =#

        Ident = String  #= An identifier, for example a variable name =#

          #= For Iterator - these are used in:
            * for loops where the expression part can be NONE() and then the range
              is taken from an array variable that the iterator is used to index,
              see 3.3.3.2 Several Iterators from Modelica Specification.
            * in array iterators where the expression should always be SOME(Exp),
              see 3.4.4.2 Array constructor with iterators from Specification
            * the guard is a MetaModelica extension; it's a Boolean expression that
              filters out items in the range. =#
         @Uniontype ForIterator begin
              @Record ITERATOR begin

                       name::String
                       guardExp::Option
                       range::Option
              end
         end

        ForIterators = IList  #= For Iterators -
           these are used in:
           * for loops where the expression part can be NONE() and then the range
             is taken from an array variable that the iterator is used to index,
             see 3.3.3.2 Several Iterators from Modelica Specification.
           * in array iterators where the expression should always be SOME(Exp),
             see 3.4.4.2 Array constructor with iterators from Specification =#

          #= - Programs, the top level construct
            A program is simply a list of class definitions declared at top
            level in the source file, combined with a within statement that
            indicates the hieractical position of the program. =#
         @Uniontype Program begin
              @Record PROGRAM begin

                       classes #= List of classes =#::IList
                       within_ #= Within clause =#::Within
              end
         end

          #= Within Clauses =#
         @Uniontype Within begin
              @Record WITHIN begin

                       path #= the path for within =#::Path
              end

              @Record TOP begin

              end
         end

        Info = SourceInfo

          #= A class definition consists of a name, a flag to indicate
           if this class is declared as partial, the declared class restriction,
           and the body of the declaration. =#
         @Uniontype Class begin
              @Record CLASS begin

                       name::Ident
                       partialPrefix #= true if partial =#::Bool
                       finalPrefix #= true if final =#::Bool
                       encapsulatedPrefix #= true if encapsulated =#::Bool
                       restriction #= Restriction =#::Restriction
                       body::ClassDef
                       info #= Information: FileName is the class is defined in +
                                      isReadOnly bool + start line no + start column no +
                                      end line no + end column no =#::Info
              end
         end

          #= The ClassDef type contains thClasse definition part of a class declaration.
          The definition is either explicit, with a list of parts
          (public, protected, equation, and algorithm), or it is a definition
          derived from another class or an enumeration type.
          For a derived type, the  type contains the name of the derived class
          and an optional array dimension and a list of modifications.
           =#
         @Uniontype ClassDef begin
              @Record PARTS begin

                       typeVars #= class A<B,C> ... has type variables B,C =#::IList
                       classAttrs #= optimization Op (objective=...) end Op. A list arguments attributing a
                           class declaration. Currently used only for Optimica extensions =#::IList
                       classParts::IList
                       ann #= Modelica2 allowed multiple class-annotations =#::IList
                       comment::Option
              end

              @Record DERIVED begin

                       typeSpec #= typeSpec specification includes array dimensions =#::TypeSpec
                       attributes::ElementAttributes
                       arguments::IList
                       comment::Option
              end

              @Record ENUMERATION begin

                       enumLiterals::EnumDef
                       comment::Option
              end

              @Record OVERLOAD begin

                       functionNames::IList
                       comment::Option
              end

              @Record CLASS_EXTENDS begin

                       baseClassName #= name of class to extend =#::Ident
                       modifications #= modifications to be applied to the base class =#::IList
                       comment #= comment =#::Option
                       parts #= class parts =#::IList
                       ann::IList
              end

              @Record PDER begin

                       functionName::Path
                       vars #= derived variables =#::IList
                       comment #= comment =#::Option
              end
         end

        ArrayDim = IList  #= Component attributes are
          properties of components which are applied by type prefixes.
          As an example, declaring a component as `input Real x;\\' will
          give the attributes `ATTR({},false,VAR,INPUT)\\'.
          Components in Modelica can be scalar or arrays with one or more
          dimensions. This type is used to indicate the dimensionality
          of a component or a type definition.
        - Array dimensions =#

          #= ModExtension: new MetaModelica type specification! =#
         @Uniontype TypeSpec begin
              @Record TPATH begin

                       path::Path
                       arrayDim::Option
              end

              @Record TCOMPLEX begin

                       path::Path
                       typeSpecs::IList
                       arrayDim::Option
              end
         end

          #= The definition of an enumeration is either a list of literals
              or a colon, \\':\\', which defines a supertype of all enumerations =#
         @Uniontype EnumDef begin
              @Record ENUMLITERALS begin

                       enumLiterals::IList
              end

              @Record ENUM_COLON begin

              end
         end

          #= EnumLiteral, which is a name in an enumeration and an optional
            Comment. =#
         @Uniontype EnumLiteral begin
              @Record ENUMLITERAL begin

                       literal::Ident
                       comment::Option
              end
         end

          #= A class definition contains several parts.  There are public and
           protected component declarations, type definitions and `extends\\'
           clauses, collectively called elements.  There are also equation
           sections and algorithm sections. The EXTERNAL part is used only by functions
           which can be declared as external C or FORTRAN functions. =#
         @Uniontype ClassPart begin
              @Record PUBLIC begin

                       contents::IList
              end

              @Record PROTECTED begin

                       contents::IList
              end

              @Record CONSTRAINTS begin

                       contents::IList
              end

              @Record EQUATIONS begin

                       contents::IList
              end

              @Record INITIALEQUATIONS begin

                       contents::IList
              end

              @Record ALGORITHMS begin

                       contents::IList
              end

              @Record INITIALALGORITHMS begin

                       contents::IList
              end

              @Record EXTERNAL begin

                       externalDecl #= externalDecl =#::ExternalDecl
                       annotation_ #= annotation =#::Option
              end
         end

          #= An element item is either an element or an annotation =#
         @Uniontype ElementItem begin
              @Record ELEMENTITEM begin

                       element::Element
              end

              @Record LEXER_COMMENT begin

                       comment::String
              end
         end

          #= Elements
           The basic element type in Modelica =#
         @Uniontype Element begin
              @Record ELEMENT begin

                       finalPrefix::Bool
                       redeclareKeywords #= replaceable, redeclare =#::Option
                       innerOuter #= inner/outer =#::InnerOuter
                       specification #= Actual element specification =#::ElementSpec
                       info #= File name the class is defined in + line no + column no =#::Info
                       constrainClass #= only valid for classdef and component =#::Option
              end

              @Record DEFINEUNIT begin

                       name::Ident
                       args::IList
              end

              @Record TEXT begin

                       optName #= optName : optional name of text, e.g. model with syntax error.
                                                              We need the name to be able to browse it... =#::Option
                       string::String
                       info::Info
              end
         end

          #= Constraining type, must be extends =#
         @Uniontype ConstrainClass begin
              @Record CONSTRAINCLASS begin

                       elementSpec #= must be extends =#::ElementSpec
                       comment #= comment =#::Option
              end
         end

          #= An element is something that occurs in a public or protected
             section in a class definition.  There is one constructor in the
             `ElementSpec\\' type for each possible element type.  There are
             class definitions (`CLASSDEF\\'), `extends\\' clauses (`EXTENDS\\')
             and component declarations (`COMPONENTS\\').

             As an example, if the element `extends TwoPin;\\' appears
             in the source, it is represented in the AST as
             `EXTENDS(IDENT(\\\"TwoPin\\\"),{})\\'.
          =#
         @Uniontype ElementSpec begin
              @Record CLASSDEF begin

                       replaceable_ #= replaceable =#::Bool
                       class_ #= class =#::Class
              end

              @Record EXTENDS begin

                       path #= path =#::Path
                       elementArg #= elementArg =#::IList
                       annotationOpt #= optional annotation =#::Option
              end

              @Record IMPORT begin

                       import_ #= import =#::Import
                       comment #= comment =#::Option
                       info::Info
              end

              @Record COMPONENTS begin

                       attributes #= attributes =#::ElementAttributes
                       typeSpec #= typeSpec =#::TypeSpec
                       components #= components =#::IList
              end
         end

          #= One of the keyword inner and outer CAN be given to reference an
            inner or outer element. Thus there are three disjoint possibilities. =#
         @Uniontype InnerOuter begin
              @Record INNER begin

              end

              @Record OUTER begin

              end

              @Record INNER_OUTER begin

              end

              @Record NOT_INNER_OUTER begin

              end
         end

          #= Import statements, different kinds =#
         @Uniontype Import begin
               #=  A named import is a import statement to a variable ex;
               =#
               #=  NAMED_IMPORT(\"SI\",QUALIFIED(\"Modelica\",IDENT(\"SIunits\")));
               =#

              @Record NAMED_IMPORT begin

                       name #= name =#::Ident
                       path #= path =#::Path
              end

              @Record QUAL_IMPORT begin

                       path #= path =#::Path
              end

              @Record UNQUAL_IMPORT begin

                       path #= path =#::Path
              end

              @Record GROUP_IMPORT begin

                       prefix::Path
                       groups::IList
              end
         end

         @Uniontype GroupImport begin
              @Record GROUP_IMPORT_NAME begin

                       name::String
              end

              @Record GROUP_IMPORT_RENAME begin

                       rename::String
                       name::String
              end
         end

        ComponentCondition = Exp  #= A componentItem can have a condition that must be fulfilled if
          the component should be instantiated.
         =#

          #= Collection of component and an optional comment =#
         @Uniontype ComponentItem begin
              @Record COMPONENTITEM begin

                       component #= component =#::Component
                       condition #= condition =#::Option
                       comment #= comment =#::Option
              end
         end

          #= Some kind of Modelica entity (object or variable) =#
         @Uniontype Component begin
              @Record COMPONENT begin

                       name #= name =#::Ident
                       arrayDim #= Array dimensions, if any =#::ArrayDim
                       modification #= Optional modification =#::Option
              end
         end

          #= Several component declarations can be grouped together in one
           `ElementSpec\\' by writing them on the same line in the source.
           This type contains the information specific to one component. =#
         @Uniontype EquationItem begin
              @Record EQUATIONITEM begin

                       equation_ #= equation =#::Equation
                       comment #= comment =#::Option
                       info #= line number =#::Info
              end

              @Record EQUATIONITEMCOMMENT begin

                       comment::String
              end
         end

          #= Info specific for an algorithm item. =#
         @Uniontype AlgorithmItem begin
              @Record ALGORITHMITEM begin

                       algorithm_ #= algorithm =#::Algorithm
                       comment #= comment =#::Option
                       info #= line number =#::Info
              end

              @Record ALGORITHMITEMCOMMENT begin

                       comment::String
              end
         end

          #= Information on one (kind) of equation, different constructors for different
              kinds of equations =#
         @Uniontype Equation begin
              @Record EQ_IF begin

                       ifExp #= Conditional expression =#::Exp
                       equationTrueItems #= true branch =#::IList
                       elseIfBranches #= elseIfBranches =#::IList
                       equationElseItems #= equationElseItems Standard 2-side eqn =#::IList
              end

              @Record EQ_EQUALS begin

                       leftSide #= leftSide =#::Exp
                       rightSide #= rightSide Connect stmt =#::Exp
              end

              @Record EQ_PDE begin

                       leftSide #= leftSide =#::Exp
                       rightSide #= rightSide Connect stmt =#::Exp
                       domain #= domain for PDEs =#::ComponentRef
              end

              @Record EQ_CONNECT begin

                       connector1 #= connector1 =#::ComponentRef
                       connector2 #= connector2 =#::ComponentRef
              end

              @Record EQ_FOR begin

                       iterators::ForIterators
                       forEquations #= forEquations =#::IList
              end

              @Record EQ_WHEN_E begin

                       whenExp #= whenExp =#::Exp
                       whenEquations #= whenEquations =#::IList
                       elseWhenEquations #= elseWhenEquations =#::IList
              end

              @Record EQ_NORETCALL begin

                       functionName #= functionName =#::ComponentRef
                       functionArgs #= functionArgs; fcalls without return value =#::FunctionArgs
              end

              @Record EQ_FAILURE begin

                       equ::EquationItem
              end
         end

          #= The Algorithm type describes one algorithm statement in an
           algorithm section.  It does not describe a whole algorithm.  The
           reason this type is named like this is that the name of the
           grammar rule for algorithm statements is `algorithm\\'. =#
         @Uniontype Algorithm begin
              @Record ALG_ASSIGN begin

                       assignComponent #= assignComponent =#::Exp
                       value #= value =#::Exp
              end

              @Record ALG_IF begin

                       ifExp #= ifExp =#::Exp
                       trueBranch #= trueBranch =#::IList
                       elseIfAlgorithmBranch #= elseIfAlgorithmBranch =#::IList
                       elseBranch #= elseBranch =#::IList
              end

              @Record ALG_FOR begin

                       iterators::ForIterators
                       forBody #= forBody =#::IList
              end

              @Record ALG_PARFOR begin

                       iterators::ForIterators
                       parforBody #= parallel for loop Body =#::IList
              end

              @Record ALG_WHILE begin

                       boolExpr #= boolExpr =#::Exp
                       whileBody #= whileBody =#::IList
              end

              @Record ALG_WHEN_A begin

                       boolExpr #= boolExpr =#::Exp
                       whenBody #= whenBody =#::IList
                       elseWhenAlgorithmBranch #= elseWhenAlgorithmBranch =#::IList
              end

              @Record ALG_NORETCALL begin

                       functionCall #= functionCall =#::ComponentRef
                       functionArgs #= functionArgs; general fcalls without return value =#::FunctionArgs
              end

              @Record ALG_RETURN begin

              end

              @Record ALG_BREAK begin

              end

               #=  MetaModelica extensions
               =#

              @Record ALG_FAILURE begin

                       equ::IList
              end

              @Record ALG_TRY begin

                       body::IList
                       elseBody::IList
              end

              @Record ALG_CONTINUE begin

              end
         end

          #= Modifications are described by the `Modification\\' type.  There
           are two forms of modifications: redeclarations and component
           modifications.
           - Modifications =#
         @Uniontype Modification begin
              @Record CLASSMOD begin

                       elementArgLst::IList
                       eqMod::EqMod
              end
         end

         @Uniontype EqMod begin
              @Record NOMOD begin

              end

              @Record EQMOD begin

                       exp::Exp
                       info::Info
              end
         end

          #= Wrapper for things that modify elements, modifications and redeclarations =#
         @Uniontype ElementArg begin
              @Record MODIFICATION begin

                       finalPrefix #= final prefix =#::Bool
                       eachPrefix #= each =#::Each
                       path::Path
                       modification #= modification =#::Option
                       comment #= comment =#::Option
                       info::Info
              end

              @Record REDECLARATION begin

                       finalPrefix #= final prefix =#::Bool
                       redeclareKeywords #= redeclare  or replaceable  =#::RedeclareKeywords
                       eachPrefix #= each prefix =#::Each
                       elementSpec #= elementSpec =#::ElementSpec
                       constrainClass #= class definition or declaration =#::Option
                       info #= needed because ElementSpec does not contain this info; Element does =#::Info
              end
         end

          #= The keywords redeclare and replacable can be given in three different kombinations, each one by themself or the both combined. =#
         @Uniontype RedeclareKeywords begin
              @Record REDECLARE begin

              end

              @Record REPLACEABLE begin

              end

              @Record REDECLARE_REPLACEABLE begin

              end
         end

          #= The each keyword can be present in both MODIFICATION\\'s and REDECLARATION\\'s.
           - Each attribute =#
         @Uniontype Each begin
              @Record EACH begin

              end

              @Record NON_EACH begin

              end
         end

          #= Element attributes =#
         @Uniontype ElementAttributes begin
              @Record ATTR begin

                       flowPrefix #= flow =#::Bool
                       streamPrefix #= stream =#::Bool
                       parallelism #= for OpenCL/CUDA parglobal, parlocal ... =#::Parallelism
                       variability #= parameter, constant etc. =#::Variability
                       direction #= input/output =#::Direction
                       isField #= non-field / field =#::IsField
                       arrayDim #= array dimensions =#::ArrayDim
              end
         end

          #= Is field =#
         @Uniontype IsField begin
              @Record NONFIELD begin

              end

              @Record FIELD begin

              end
         end

          #= Parallelism =#
         @Uniontype Parallelism begin
              @Record PARGLOBAL begin

              end

              @Record PARLOCAL begin

              end

              @Record NON_PARALLEL begin

              end
         end

         @Uniontype FlowStream begin
              @Record FLOW begin

              end

              @Record STREAM begin

              end

              @Record NOT_FLOW_STREAM begin

              end
         end

          #= Variability =#
         @Uniontype Variability begin
              @Record VAR begin

              end

              @Record DISCRETE begin

              end

              @Record PARAM begin

              end

              @Record CONST begin

              end
         end

          #= Direction =#
         @Uniontype Direction begin
              @Record INPUT begin

              end

              @Record OUTPUT begin

              end

              @Record BIDIR begin

              end

              @Record INPUT_OUTPUT begin

              end
         end

          #= The Exp uniontype is the container of a Modelica expression.
           - Expressions =#
         @Uniontype Exp begin
              @Record INTEGER begin

                       value::ModelicaInteger
              end

              @Record REAL begin

                       value #= String representation of a Real, in order to unparse without changing the user's display preference =#::String
              end

              @Record CREF begin

                       componentRef::ComponentRef
              end

              @Record STRING begin

                       value::String
              end

              @Record BOOL begin

                       value::Bool
              end

              @Record BINARY begin

                       exp1::Exp
                       op::Operator
                       exp2::Exp
              end

              @Record UNARY begin

                       op #= op =#::Operator
                       exp #= exp - any arithmetic expression =#::Exp
              end

              @Record LBINARY begin

                       exp1 #= exp1 =#::Exp
                       op #= op =#::Operator
                       exp2::Exp
              end

              @Record LUNARY begin

                       op #= op =#::Operator
                       exp #= exp - any logical or relation expression =#::Exp
              end

              @Record RELATION begin

                       exp1 #= exp1 =#::Exp
                       op #= op =#::Operator
                       exp2::Exp
              end

              @Record IFEXP begin

                       ifExp #= ifExp =#::Exp
                       trueBranch #= trueBranch =#::Exp
                       elseBranch #= elseBranch =#::Exp
                       elseIfBranch #= elseIfBranch Function calls =#::IList
              end

              @Record CALL begin

                       function_ #= function =#::ComponentRef
                       functionArgs::FunctionArgs
              end

               #=  stefan
               =#

              @Record PARTEVALFUNCTION begin

                       function_ #= function =#::ComponentRef
                       functionArgs::FunctionArgs
              end

              @Record ARRAY begin

                       arrayExp::IList
              end

              @Record MATRIX begin

                       matrix::IList
              end

              @Record RANGE begin

                       start #= start =#::Exp
                       step #= step =#::Option
                       stop #= stop =#::Exp
              end

              @Record TUPLE begin

                       expressions #= comma-separated expressions =#::IList
              end

              @Record END begin

              end

              @Record CODE begin

                       code::CodeNode
              end

               #=  MetaModelica expressions follow below!
               =#

              @Record AS begin

                       id #=  only an id  =#::Ident
                       exp #=  expression to bind to the id  =#::Exp
              end

              @Record CONS begin

                       head #=  head of the list  =#::Exp
                       rest #=  rest of the list  =#::Exp
              end

              @Record MATCHEXP begin

                       matchTy #=  match or matchcontinue       =#::MatchType
                       inputExp #=  match expression of          =#::Exp
                       localDecls #=  local declarations           =#::IList
                       cases #=  case list + else in the end  =#::IList
                       comment #=  match expr comment_optional  =#::Option
              end

               #=  The following are only used internally in the compiler
               =#

              @Record LIST begin

                       exps::IList
              end

              @Record DOT begin

                       exp::Exp
                       index::Exp
              end
         end

          #= case in match or matchcontinue =#
         @Uniontype Case begin
              @Record CASE begin

                       pattern #=  patterns to be matched  =#::Exp
                       patternGuard::Option
                       patternInfo #= file information of the pattern =#::Info
                       localDecls #=  local decls  =#::IList
                       classPart #=  equation or algorithm section  =#::ClassPart
                       result #=  result  =#::Exp
                       resultInfo #= file information of the result-exp =#::Info
                       comment #=  comment after case like: case pattern string_comment  =#::Option
                       info #= file information of the whole case =#::Info
              end

              @Record ELSE begin

                       localDecls #=  local decls  =#::IList
                       classPart #=  equation or algorithm section  =#::ClassPart
                       result #=  result  =#::Exp
                       resultInfo #= file information of the result-exp =#::Info
                       comment #=  comment after case like: case pattern string_comment  =#::Option
                       info #= file information of the whole case =#::Info
              end
         end

         @Uniontype MatchType begin
              @Record MATCH begin

              end

              @Record MATCHCONTINUE begin

              end
         end

          #= The Code uniontype is used for Meta-programming. It originates from the Code quoting mechanism. See paper in Modelica2003 conference =#
         @Uniontype CodeNode begin
              @Record C_TYPENAME begin

                       path::Path
              end

              @Record C_VARIABLENAME begin

                       componentRef::ComponentRef
              end

              @Record C_CONSTRAINTSECTION begin

                       boolean::Bool
                       equationItemLst::IList
              end

              @Record C_EQUATIONSECTION begin

                       boolean::Bool
                       equationItemLst::IList
              end

              @Record C_ALGORITHMSECTION begin

                       boolean::Bool
                       algorithmItemLst::IList
              end

              @Record C_ELEMENT begin

                       element::Element
              end

              @Record C_EXPRESSION begin

                       exp::Exp
              end

              @Record C_MODIFICATION begin

                       modification::Modification
              end
         end

          #= The FunctionArgs uniontype consists of a list of positional arguments
           followed by a list of named arguments (Modelica v2.0) =#
         @Uniontype FunctionArgs begin
              @Record FUNCTIONARGS begin

                       args #= args =#::IList
                       argNames #= argNames =#::IList
              end

              @Record FOR_ITER_FARG begin

                       exp #= iterator expression =#::Exp
                       iterType::ReductionIterType
                       iterators::ForIterators
              end
         end

         emptyFunctionArgs = FUNCTIONARGS(list(), list())::FunctionArgs

         @Uniontype ReductionIterType begin
              @Record COMBINE begin

              end

              @Record THREAD begin

              end
         end

          #= The NamedArg uniontype consist of an Identifier for the argument and an expression
           giving the value of the argument =#
         @Uniontype NamedArg begin
              @Record NAMEDARG begin

                       argName #= argName =#::Ident
                       argValue #= argValue =#::Exp
              end
         end

          #= Expression operators =#
         @Uniontype Operator begin
               #= /* arithmetic operators */ =#

              @Record ADD begin

              end

              @Record SUB begin

              end

              @Record MUL begin

              end

              @Record DIV begin

              end

              @Record POW begin

              end

              @Record UPLUS begin

              end

              @Record UMINUS begin

              end

               #= /* element-wise arithmetic operators */ =#

              @Record ADD_EW begin

              end

              @Record SUB_EW begin

              end

              @Record MUL_EW begin

              end

              @Record DIV_EW begin

              end

              @Record POW_EW begin

              end

              @Record UPLUS_EW begin

              end

              @Record UMINUS_EW begin

              end

               #= /* logical operators */ =#

              @Record AND begin

              end

              @Record OR begin

              end

              @Record NOT begin

              end

               #= /* relational operators */ =#

              @Record LESS begin

              end

              @Record LESSEQ begin

              end

              @Record GREATER begin

              end

              @Record GREATEREQ begin

              end

              @Record EQUAL begin

              end

              @Record NEQUAL begin

              end
         end

          #= The Subscript uniontype is used both in array declarations and
           component references.  This might seem strange, but it is
           inherited from the grammar.  The NOSUB constructor means that
           the dimension size is undefined when used in a declaration, and
           when it is used in a component reference it means a slice of the
           whole dimension.
           - Subscripts =#
         @Uniontype Subscript begin
              @Record NOSUB begin

              end

              @Record SUBSCRIPT begin

                       subscript #= subscript =#::Exp
              end
         end

          #= A component reference is the fully or partially qualified name of
           a component.  It is represented as a list of
           identifier--subscript pairs.
           - Component references and paths =#
         @Uniontype ComponentRef begin
              @Record CREF_FULLYQUALIFIED begin

                       componentRef::ComponentRef
              end

              @Record CREF_QUAL begin

                       name #= name =#::Ident
                       subscripts #= subscripts =#::IList
                       componentRef #= componentRef =#::ComponentRef
              end

              @Record CREF_IDENT begin

                       name #= name =#::Ident
                       subscripts #= subscripts =#::IList
              end

              @Record WILD begin

              end

              @Record ALLWILD begin

              end
         end

          #= The type `Path\\', on the other hand,
           is used to store references to class names, or names inside
           class definitions. =#
         @Uniontype Path begin
              @Record QUALIFIED begin

                       name #= name =#::Ident
                       path #= path =#::Path
              end

              @Record IDENT begin

                       name #= name =#::Ident
              end

              @Record FULLYQUALIFIED begin

                       path::Path
              end
         end

          #= These constructors each correspond to a different kind of class
           declaration in Modelica, except the last four, which are used
           for the predefined types.  The parser assigns each class
           declaration one of the restrictions, and the actual class
           definition is checked for conformance during translation.  The
           predefined types are created in the Builtin module and are
           assigned special restrictions.
           =#
         @Uniontype Restriction begin
              @Record R_CLASS begin

              end

              @Record R_OPTIMIZATION begin

              end

              @Record R_MODEL begin

              end

              @Record R_RECORD begin

              end

              @Record R_BLOCK begin

              end

              @Record R_CONNECTOR begin

              end

              @Record R_EXP_CONNECTOR begin

              end

              @Record R_TYPE begin

              end

              @Record R_PACKAGE begin

              end

              @Record R_FUNCTION begin

                       functionRestriction::FunctionRestriction
              end

              @Record R_OPERATOR begin

              end

              @Record R_OPERATOR_RECORD begin

              end

              @Record R_ENUMERATION begin

              end

              @Record R_PREDEFINED_INTEGER begin

              end

              @Record R_PREDEFINED_REAL begin

              end

              @Record R_PREDEFINED_STRING begin

              end

              @Record R_PREDEFINED_BOOLEAN begin

              end

              @Record R_PREDEFINED_ENUMERATION begin

              end

               #=  BTH
               =#

              @Record R_PREDEFINED_CLOCK begin

              end

               #=  MetaModelica
               =#

              @Record R_UNIONTYPE begin

              end

              @Record R_METARECORD begin

                       #= MetaModelica extension, added by simbj
                       =#
                       name::Path
                       #= Name of the uniontype
                       =#
                       index::ModelicaInteger
                       #= Index in the uniontype
                       =#
                       singleton::Bool
                       moved::Bool
                       #=  true if moved outside uniontype, otherwise false.
                       =#
                       typeVars::IList
              end

              @Record R_UNKNOWN begin

              end

               #= /* added by simbj */ =#
         end

          #= function purity =#
         @Uniontype FunctionPurity begin
              @Record PURE begin

              end

              @Record IMPURE begin

              end

              @Record NO_PURITY begin

              end
         end

         @Uniontype FunctionRestriction begin
              @Record FR_NORMAL_FUNCTION begin

                       purity #= function purity =#::FunctionPurity
              end

              @Record FR_OPERATOR_FUNCTION begin

              end

              @Record FR_PARALLEL_FUNCTION begin

              end

              @Record FR_KERNEL_FUNCTION begin

              end
         end

          #= An Annotation is a class_modification.
           - Annotation =#
         @Uniontype Annotation begin
              @Record ANNOTATION begin

                       elementArgs #= elementArgs =#::IList
              end
         end

          #= Comment =#
         @Uniontype Comment begin
              @Record COMMENT begin

                       annotation_ #= annotation =#::Option
                       comment #= comment =#::Option
              end
         end

          #= Declaration of an external function call - ExternalDecl =#
         @Uniontype ExternalDecl begin
              @Record EXTERNALDECL begin

                       funcName #= The name of the external function =#::Option
                       lang #= Language of the external function =#::Option
                       output_ #= output parameter as return value =#::Option
                       args #= only positional arguments, i.e. expression list =#::IList
                       annotation_::Option
              end
         end

         @Uniontype Ref begin
              @Record RCR begin

                       cr::ComponentRef
              end

              @Record RTS begin

                       ts::TypeSpec
              end

              @Record RIM begin

                       im::Import
              end
         end

          #= Controls output of error-messages =#
         @Uniontype Msg begin
              @Record MSG begin

                       info::Info
              end

              @Record NO_MSG begin

              end
         end

    #= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
    @exportAll()
  end
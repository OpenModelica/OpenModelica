  module SCode


    using MetaModelica
    #= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
    using ExportAll
    #= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#

    @UniontypeDecl Restriction
    @UniontypeDecl FunctionRestriction
    @UniontypeDecl Mod
    @UniontypeDecl SubMod
    @UniontypeDecl Enum
    @UniontypeDecl ClassDef
    @UniontypeDecl Comment
    @UniontypeDecl Annotation
    @UniontypeDecl ExternalDecl
    @UniontypeDecl Equation
    @UniontypeDecl EEquation
    @UniontypeDecl AlgorithmSection
    @UniontypeDecl ConstraintSection
    @UniontypeDecl Statement
    @UniontypeDecl Visibility
    @UniontypeDecl Redeclare
    @UniontypeDecl ConstrainClass
    @UniontypeDecl Replaceable
    @UniontypeDecl Final
    @UniontypeDecl Each
    @UniontypeDecl Encapsulated
    @UniontypeDecl Partial
    @UniontypeDecl ConnectorType
    @UniontypeDecl Prefixes
    @UniontypeDecl Element
    @UniontypeDecl Attributes
    @UniontypeDecl Parallelism
    @UniontypeDecl Variability
    @UniontypeDecl Initial

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

        import Absyn

        import AbsynUtil
         #=  Some definitions are aliased from Absyn
         =#

        Ident = Absyn.Ident

        Path = Absyn.Path

        Subscript = Absyn.Subscript

         @Uniontype Restriction begin
              @Record R_CLASS begin

              end

              @Record R_OPTIMIZATION begin

              end

              @Record R_MODEL begin

              end

              @Record R_RECORD begin

                       isOperator::Bool
              end

              @Record R_BLOCK begin

              end

              @Record R_CONNECTOR begin

                       isExpandable #= is expandable? =#::Bool
              end

              @Record R_OPERATOR begin

              end

              @Record R_TYPE begin

              end

              @Record R_PACKAGE begin

              end

              @Record R_FUNCTION begin

                       functionRestriction::FunctionRestriction
              end

              @Record R_ENUMERATION begin

              end

               #=  predefined internal types
               =#

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

               #=  MetaModelica extensions
               =#

              @Record R_METARECORD begin

                       name::Absyn.Path
                       #= Name of the uniontype
                       =#
                       index::ModelicaInteger
                       #= Index in the uniontype
                       =#
                       singleton::Bool
                       moved::Bool
                       #=  true if moved outside uniontype, otherwise false.
                       =#
                       typeVars::List{String}
              end

               #= /* added by x07simbj */ =#

              @Record R_UNIONTYPE begin

                       typeVars::List{String}
              end

               #= /* added by simbj */ =#
         end

         #=  Same as Absyn.FunctionRestriction except this contains
         =#
         #=  FR_EXTERNAL_FUNCTION and FR_RECORD_CONSTRUCTOR.
         =#

         @Uniontype FunctionRestriction begin
              @Record FR_NORMAL_FUNCTION begin

                       isImpure #= true for impure functions, false otherwise =#::Bool
              end

              @Record FR_EXTERNAL_FUNCTION begin

                       isImpure #= true for impure functions, false otherwise =#::Bool
              end

              @Record FR_OPERATOR_FUNCTION begin

              end

              @Record FR_RECORD_CONSTRUCTOR begin

              end

              @Record FR_PARALLEL_FUNCTION begin

              end

              @Record FR_KERNEL_FUNCTION begin

              end
         end

          #= - Modifications =#
         @Uniontype Mod begin
              @Record MOD begin

                       finalPrefix #= final prefix =#::Final
                       eachPrefix #= each prefix =#::Each
                       subModLst::List{SubMod}
                       binding::Option{Absyn.Exp}
                       info::SourceInfo
              end

              @Record REDECL begin

                       finalPrefix #= final prefix =#::Final
                       eachPrefix #= each prefix =#::Each
                       element #= The new element declaration. =#::Element
              end

              @Record NOMOD begin

              end
         end

          #= Modifications are represented in an more structured way than in
             the `Absyn\\' module.  Modifications using qualified names
             (such as in `x.y =  z\\') are normalized (to `x(y = z)\\'). =#
         @Uniontype SubMod begin
              @Record NAMEMOD begin

                       ident::Ident
                       mod #= A named component =#::Mod
              end
         end

        Program = List{Element}  #= - Programs
        As in the AST, a program is simply a list of class definitions. =#

          #= Enum, which is a name in an enumeration and an optional Comment. =#
         @Uniontype Enum begin
              @Record ENUM begin

                       literal::Ident
                       comment::Comment
              end
         end

          #= The major difference between these types and their Absyn
          counterparts is that the PARTS constructor contains separate
          lists for elements, equations and algorithms.

          SCode.PARTS contains elements of a class definition. For instance,
             model A
               extends B;
               C c;
             end A;
          Here PARTS contains two elements ('extends B' and 'C c')
          SCode.DERIVED is used for short class definitions, i.e:
           class A = B[ArrayDims](modifiers);
          SCode.CLASS_EXTENDS is used for extended class definition, i.e:
           class extends A (modifier)
             new elements;
           end A; =#
         @Uniontype ClassDef begin
              @Record PARTS begin

                       elementLst #= the list of elements =#::List{Element}
                       normalEquationLst #= the list of equations =#::List{Equation}
                       initialEquationLst #= the list of initial equations =#::List{Equation}
                       normalAlgorithmLst #= the list of algorithms =#::List{AlgorithmSection}
                       initialAlgorithmLst #= the list of initial algorithms =#::List{AlgorithmSection}
                       constraintLst #= the list of constraints =#::List{ConstraintSection}
                       clsattrs #= the list of class attributes. Currently for Optimica extensions =#::List{Absyn.NamedArg}
                       externalDecl #= used by external functions =#::Option{ExternalDecl}
              end

              @Record CLASS_EXTENDS begin

                       modifications #= the modifications that need to be applied to the base class =#::Mod
                       composition #= the new composition =#::ClassDef
              end

              @Record DERIVED begin

                       typeSpec #= typeSpec: type specification =#::Absyn.TypeSpec
                       modifications #= the modifications =#::Mod
                       attributes #= the element attributes =#::Attributes
              end

              @Record ENUMERATION begin

                       enumLst #= if the list is empty it means :, the supertype of all enumerations =#::List{Enum}
              end

              @Record OVERLOAD begin

                       pathLst #= the path lists =#::List{Absyn.Path}
              end

              @Record PDER begin

                       functionPath #= function name =#::Absyn.Path
                       derivedVariables #= derived variables =#::List{Ident}
              end
         end

         @Uniontype Comment begin
              @Record COMMENT begin

                       annotation_::Option{Annotation}
                       comment::Option{String}
              end
         end

         noComment = COMMENT(NONE(), NONE())::Comment
         #=  stefan
         =#

         @Uniontype Annotation begin
              @Record ANNOTATION begin

                       modification::Mod
              end
         end

          #= Declaration of an external function call - ExternalDecl =#
         @Uniontype ExternalDecl begin
              @Record EXTERNALDECL begin

                       funcName #= The name of the external function =#::Option{Ident}
                       lang #= Language of the external function =#::Option{String}
                       output_ #= output parameter as return value =#::Option{Absyn.ComponentRef}
                       args #= only positional arguments, i.e. expression list =#::List{Absyn.Exp}
                       annotation_::Option{Annotation}
              end
         end

          #= - Equations =#
         @Uniontype Equation begin
              @Record EQUATION begin

                       eEquation #= an equation =#::EEquation
              end
         end

          #= These represent equations and are almost identical to their Absyn versions.
          In EQ_IF the elseif branches are represented as normal else branches with
          a single if statement in them. =#
         @Uniontype EEquation begin
              @Record EQ_IF begin

                       condition #= conditional =#::List{Absyn.Exp}
                       thenBranch #= the true (then) branch =#::List{List{EEquation}}
                       elseBranch #= the false (else) branch =#::List{EEquation}
                       comment::Comment
                       info::SourceInfo
              end

              @Record EQ_EQUALS begin

                       expLeft #= the expression on the left side of the operator =#::Absyn.Exp
                       expRight #= the expression on the right side of the operator =#::Absyn.Exp
                       comment::Comment
                       info::SourceInfo
              end

              @Record EQ_PDE begin

                       expLeft #= the expression on the left side of the operator =#::Absyn.Exp
                       expRight #= the expression on the right side of the operator =#::Absyn.Exp
                       domain #= domain for PDEs =#::Absyn.ComponentRef
                       comment::Comment
                       info::SourceInfo
              end

              @Record EQ_CONNECT begin

                       crefLeft #= the connector/component reference on the left side =#::Absyn.ComponentRef
                       crefRight #= the connector/component reference on the right side =#::Absyn.ComponentRef
                       comment::Comment
                       info::SourceInfo
              end

              @Record EQ_FOR begin

                       index #= the index name =#::Ident
                       range #= the range of the index =#::Option{Absyn.Exp}
                       eEquationLst #= the equation list =#::List{EEquation}
                       comment::Comment
                       info::SourceInfo
              end

              @Record EQ_WHEN begin

                       condition #= the when condition =#::Absyn.Exp
                       eEquationLst #= the equation list =#::List{EEquation}
                       elseBranches #= the elsewhen expression and equation list =#::List{Tuple{Absyn.Exp, List{EEquation}}}
                       comment::Comment
                       info::SourceInfo
              end

              @Record EQ_ASSERT begin

                       condition #= the assert condition =#::Absyn.Exp
                       message #= the assert message =#::Absyn.Exp
                       level::Absyn.Exp
                       comment::Comment
                       info::SourceInfo
              end

              @Record EQ_TERMINATE begin

                       message #= the terminate message =#::Absyn.Exp
                       comment::Comment
                       info::SourceInfo
              end

              @Record EQ_REINIT begin

                       cref #= the variable to initialize =#::Absyn.Exp
                       expReinit #= the new value =#::Absyn.Exp
                       comment::Comment
                       info::SourceInfo
              end

              @Record EQ_NORETCALL begin

                       exp::Absyn.Exp
                       comment::Comment
                       info::SourceInfo
              end
         end

          #= - Algorithms
           The Absyn module uses the terminology from the
           grammar, where algorithm means an algorithmic
           statement. But here, an Algorithm means a whole
           algorithm section. =#
         @Uniontype AlgorithmSection begin
              @Record ALGORITHM begin

                       statements #= the algorithm statements =#::List{Statement}
              end
         end

         @Uniontype ConstraintSection begin
              @Record CONSTRAINTS begin

                       constraints::List{Absyn.Exp}
              end
         end

          #= The Statement type describes one algorithm statement in an algorithm section. =#
         @Uniontype Statement begin
              @Record ALG_ASSIGN begin

                       assignComponent #= assignComponent =#::Absyn.Exp
                       value #= value =#::Absyn.Exp
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_IF begin

                       boolExpr::Absyn.Exp
                       trueBranch::List{Statement}
                       elseIfBranch::List{Tuple{Absyn.Exp, List{Statement}}}
                       elseBranch::List{Statement}
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_FOR begin

                       index #= the index name =#::Ident
                       range #= the range of the index =#::Option{Absyn.Exp}
                       forBody #= forBody =#::List{Statement}
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_PARFOR begin

                       index #= the index name =#::Ident
                       range #= the range of the index =#::Option{Absyn.Exp}
                       parforBody #= parallel for loop body =#::List{Statement}
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_WHILE begin

                       boolExpr #= boolExpr =#::Absyn.Exp
                       whileBody #= whileBody =#::List{Statement}
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_WHEN_A begin

                       branches::List{Tuple{Absyn.Exp, List{Statement}}}
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_ASSERT begin

                       condition::Absyn.Exp
                       message::Absyn.Exp
                       level::Absyn.Exp
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_TERMINATE begin

                       message::Absyn.Exp
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_REINIT begin

                       cref::Absyn.Exp
                       newValue::Absyn.Exp
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_NORETCALL begin

                       exp::Absyn.Exp
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_RETURN begin

                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_BREAK begin

                       comment::Comment
                       info::SourceInfo
              end

               #=  MetaModelica extensions
               =#

              @Record ALG_FAILURE begin

                       stmts::List{Statement}
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_TRY begin

                       body::List{Statement}
                       elseBody::List{Statement}
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_CONTINUE begin

                       comment::Comment
                       info::SourceInfo
              end
         end

         #=  common prefixes to elements
         =#

          #= the visibility prefix =#
         @Uniontype Visibility begin
              @Record PUBLIC begin

              end

              @Record PROTECTED begin

              end
         end

          #= the redeclare prefix =#
         @Uniontype Redeclare begin
              @Record REDECLARE begin

              end

              @Record NOT_REDECLARE begin

              end
         end

         @Uniontype ConstrainClass begin
              @Record CONSTRAINCLASS begin

                       constrainingClass::Absyn.Path
                       modifier::Mod
                       comment::Comment
              end
         end

          #= the replaceable prefix =#
         @Uniontype Replaceable begin
              @Record REPLACEABLE begin

                       cc #= the constraint class =#::Option{ConstrainClass}
              end

              @Record NOT_REPLACEABLE begin

              end
         end

          #= the final prefix =#
         @Uniontype Final begin
              @Record FINAL begin

              end

              @Record NOT_FINAL begin

              end
         end

          #= the each prefix =#
         @Uniontype Each begin
              @Record EACH begin

              end

              @Record NOT_EACH begin

              end
         end

          #= the encapsulated prefix =#
         @Uniontype Encapsulated begin
              @Record ENCAPSULATED begin

              end

              @Record NOT_ENCAPSULATED begin

              end
         end

          #= the partial prefix =#
         @Uniontype Partial begin
              @Record PARTIAL begin

              end

              @Record NOT_PARTIAL begin

              end
         end

         @Uniontype ConnectorType begin
              @Record POTENTIAL begin

              end

              @Record FLOW begin

              end

              @Record STREAM begin

              end
         end

          #= the common class or component prefixes =#
         @Uniontype Prefixes begin
              @Record PREFIXES begin

                       visibility #= the protected/public prefix =#::Visibility
                       redeclarePrefix #= redeclare prefix =#::Redeclare
                       finalPrefix #= final prefix, be it at the element or top level =#::Final
                       innerOuter #= the inner/outer/innerouter prefix =#::Absyn.InnerOuter
                       replaceablePrefix #= replaceable prefix =#::Replaceable
              end
         end

          #= - Elements
           There are four types of elements in a declaration, represented by the constructors:
           IMPORT     (for import clauses)
           EXTENDS    (for extends clauses),
           CLASS      (for top/local class definitions)
           COMPONENT  (for local variables)
           DEFINEUNIT (for units) =#
         @Uniontype Element begin
              @Record IMPORT begin

                       imp #= the import definition =#::Absyn.Import
                       visibility #= the protected/public prefix =#::Visibility
                       info #= the import information =#::SourceInfo
              end

              @Record EXTENDS begin

                       baseClassPath #= the extends path =#::Path
                       visibility #= the protected/public prefix =#::Visibility
                       modifications #= the modifications applied to the base class =#::Mod
                       ann #= the extends annotation =#::Option{Annotation}
                       info #= the extends info =#::SourceInfo
              end

              @Record CLASS begin

                       name #= the name of the class =#::Ident
                       prefixes #= the common class or component prefixes =#::Prefixes
                       encapsulatedPrefix #= the encapsulated prefix =#::Encapsulated
                       partialPrefix #= the partial prefix =#::Partial
                       restriction #= the restriction of the class =#::Restriction
                       classDef #= the class specification =#::ClassDef
                       cmt #= the class annotation and string-comment =#::Comment
                       info #= the class information =#::SourceInfo
              end

              @Record COMPONENT begin

                       name #= the component name =#::Ident
                       prefixes #= the common class or component prefixes =#::Prefixes
                       attributes #= the component attributes =#::Attributes
                       typeSpec #= the type specification =#::Absyn.TypeSpec
                       modifications #= the modifications to be applied to the component =#::Mod
                       comment #= this if for extraction of comments and annotations from Absyn =#::Comment
                       condition #= the conditional declaration of a component =#::Option{Absyn.Exp}
                       info #= this is for line and column numbers, also file name. =#::SourceInfo
              end

              @Record DEFINEUNIT begin

                       name::Ident
                       visibility #= the protected/public prefix =#::Visibility
                       exp #= the unit expression =#::Option{String}
                       weight #= the weight =#::Option{ModelicaReal}
              end
         end

          #= - Attributes =#
         @Uniontype Attributes begin
              @Record ATTR begin

                       arrayDims #= the array dimensions of the component =#::Absyn.ArrayDim
                       connectorType #= The connector type: flow, stream or nothing. =#::ConnectorType
                       parallelism #= parallelism prefix: parglobal, parlocal, parprivate =#::Parallelism
                       variability #=  the variability: parameter, discrete, variable, constant =#::Variability
                       direction #= the direction: input, output or bidirectional =#::Absyn.Direction
                       isField #= non-fiel / field =#::Absyn.IsField
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

          #= the variability of a component =#
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

         #= /* adrpo: previously present in Inst.mo */ =#

          #= the initial attribute of an algorithm or equation
          Intial is used as argument to instantiation-function for
          specifying if equations or algorithms are initial or not. =#
         @Uniontype Initial begin
              @Record INITIAL begin

              end

              @Record NON_INITIAL begin

              end
         end

         defaultPrefixes = PREFIXES(PUBLIC(), NOT_REDECLARE(), NOT_FINAL(), Absyn.NOT_INNER_OUTER(), NOT_REPLACEABLE())::Prefixes

         defaultVarAttr = ATTR(list(), POTENTIAL(), NON_PARALLEL(), VAR(), Absyn.BIDIR(), Absyn.NONFIELD())::Attributes

         defaultParamAttr = ATTR(list(), POTENTIAL(), NON_PARALLEL(), PARAM(), Absyn.BIDIR(), Absyn.NONFIELD())::Attributes

         defaultConstAttr = ATTR(list(), POTENTIAL(), NON_PARALLEL(), CONST(), Absyn.BIDIR(), Absyn.NONFIELD())::Attributes

    #= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
    @exportAll()
  end
#= Partly automatically generated =#
module SCode

    using MetaModelica
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

    FilterFunc = Function

    FoldFunc = Function

    FoldFunc = Function

    FoldFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

    TraverseFunc = Function

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

import Util

import List

Lst = MetaModelica.List

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
                       typeVars::Lst
              end

               #= /* added by x07simbj */ =#

              @Record R_UNIONTYPE begin

                       typeVars::Lst
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
                       subModLst::Lst
                       binding::Option
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

        Program = List  #= - Programs
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

                       elementLst #= the list of elements =#::Lst
                       normalEquationLst #= the list of equations =#::Lst
                       initialEquationLst #= the list of initial equations =#::Lst
                       normalAlgorithmLst #= the list of algorithms =#::Lst
                       initialAlgorithmLst #= the list of initial algorithms =#::Lst
                       constraintLst #= the list of constraints =#::Lst
                       clsattrs #= the list of class attributes. Currently for Optimica extensions =#::Lst
                       externalDecl #= used by external functions =#::Option
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

                       enumLst #= if the list is empty it means :, the supertype of all enumerations =#::Lst
              end

              @Record OVERLOAD begin

                       pathLst #= the path lists =#::Lst
              end

              @Record PDER begin

                       functionPath #= function name =#::Absyn.Path
                       derivedVariables #= derived variables =#::Lst
              end
         end


         @Uniontype Comment begin
              @Record COMMENT begin

                       annotation_::Option
                       comment::Option
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

                       funcName #= The name of the external function =#::Option
                       lang #= Language of the external function =#::Option
                       output_ #= output parameter as return value =#::Option
                       args #= only positional arguments, i.e. expression list =#::Lst
                       annotation_::Option
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

                       condition #= conditional =#::Lst
                       thenBranch #= the true (then) branch =#::Lst
                       elseBranch #= the false (else) branch =#::Lst
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
                       range #= the range of the index =#::Option
                       eEquationLst #= the equation list =#::Lst
                       comment::Comment
                       info::SourceInfo
              end

              @Record EQ_WHEN begin

                       condition #= the when condition =#::Absyn.Exp
                       eEquationLst #= the equation list =#::Lst
                       elseBranches #= the elsewhen expression and equation list =#::Lst
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

                       statements #= the algorithm statements =#::Lst
              end
         end

         @Uniontype ConstraintSection begin
              @Record CONSTRAINTS begin

                       constraints::Lst
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
                       trueBranch::Lst
                       elseIfBranch::Lst
                       elseBranch::Lst
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_FOR begin

                       index #= the index name =#::Ident
                       range #= the range of the index =#::Option
                       forBody #= forBody =#::Lst
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_PARFOR begin

                       index #= the index name =#::Ident
                       range #= the range of the index =#::Option
                       parforBody #= parallel for loop body =#::Lst
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_WHILE begin

                       boolExpr #= boolExpr =#::Absyn.Exp
                       whileBody #= whileBody =#::Lst
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_WHEN_A begin

                       branches::Lst
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

                       stmts::Lst
                       comment::Comment
                       info::SourceInfo
              end

              @Record ALG_TRY begin

                       body::Lst
                       elseBody::Lst
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

                       cc #= the constraint class =#::Option
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
                       ann #= the extends annotation =#::Option
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
                       condition #= the conditional declaration of a component =#::Option
                       info #= this is for line and column numbers, also file name. =#::SourceInfo
              end

              @Record DEFINEUNIT begin

                       name::Ident
                       visibility #= the protected/public prefix =#::Visibility
                       exp #= the unit expression =#::Option
                       weight #= the weight =#::Option
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
         #= Removes all submodifiers from the Mod. =#
        function stripSubmod(inMod::Mod)::Mod
              local outMod::Mod

              outMod = begin
                  local fp::Final
                  local ep::Each
                  local binding::Option
                  local info::SourceInfo
                @match inMod begin
                  MOD(fp, ep, _, binding, info)  => begin
                    MOD(fp, ep, list(), binding, info)
                  end
                  
                  _  => begin
                      inMod
                  end
                end
              end
          outMod
        end

         #= Removes submods from a modifier based on a filter function. =#
        function filterSubMods(mod::Mod, filter::FilterFunc)::Mod


              mod = begin
                @match mod begin
                  MOD()  => begin
                      mod.subModLst = list(m for m in mod.subModLst if filter(m))
                    begin
                      @match mod begin
                        MOD(subModLst =  nil(), binding = NONE())  => begin
                          NOMOD()
                        end
                        
                        _  => begin
                            mod
                        end
                      end
                    end
                  end
                  
                  _  => begin
                      mod
                  end
                end
              end
          mod
        end

         #= Return the Element with the name given as first argument from the Class. =#
        function getElementNamed(inIdent::Ident, inClass::Element)::Element
              local outElement::Element

              outElement = begin
                  local elt::Element
                  local id::String
                  local elts::Lst
                @match (inIdent, inClass) begin
                  (id, CLASS(classDef = PARTS(elementLst = elts)))  => begin
                      elt = getElementNamedFromElts(id, elts)
                    elt
                  end
                  
                  (id, CLASS(classDef = CLASS_EXTENDS(composition = PARTS(elementLst = elts))))  => begin
                      elt = getElementNamedFromElts(id, elts)
                    elt
                  end
                end
              end
               #= /* adrpo: handle also the case model extends X then X; */ =#
          outElement
        end

         #= Helper function to getElementNamed. =#
        function getElementNamedFromElts(inIdent::Ident, inElementLst::Lst)::Element
              local outElement::Element

              outElement = begin
                  local elt::Element
                  local comp::Element
                  local cdef::Element
                  local id2::String
                  local id1::String
                  local xs::Lst
                @matchcontinue (inIdent, inElementLst) begin
                  (id2, COMPONENT(name = id1) <| _)  => begin
                    comp,
                      @assert true == (stringEq(id1, id2))
                    comp
                  end
                  
                  (id2, COMPONENT(name = id1) <| xs)  => begin
                      @assert false == (stringEq(id1, id2))
                      elt = getElementNamedFromElts(id2, xs)
                    elt
                  end
                  
                  (id2, CLASS(name = id1) <| xs)  => begin
                      @assert false == (stringEq(id1, id2))
                      elt = getElementNamedFromElts(id2, xs)
                    elt
                  end
                  
                  (id2, EXTENDS() <| xs)  => begin
                      elt = getElementNamedFromElts(id2, xs)
                    elt
                  end
                  
                  (id2, CLASS(name = id1) <| _)  => begin
                    cdef,
                      @assert true == (stringEq(id1, id2))
                    cdef
                  end
                  
                  (id2, _ <| xs)  => begin
                      elt = getElementNamedFromElts(id2, xs)
                    elt
                  end
                end
              end
               #=  Try next.
               =#
          outElement
        end

         #= 
        Author BZ, 2009-01
        check if an element is of type EXTENDS or not. =#
        function isElementExtends(ele::Element)::Bool
              local isExtend::Bool

              isExtend = begin
                @match ele begin
                  EXTENDS()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isExtend
        end

         #= Check if an element extends another class. =#
        function isElementExtendsOrClassExtends(ele::Element)::Bool
              local isExtend::Bool

              isExtend = begin
                @match ele begin
                  EXTENDS()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isExtend
        end

         #= 
        check if an element is not of type CLASS_EXTENDS. =#
        function isNotElementClassExtends(ele::Element)::Bool
              local isExtend::Bool

              isExtend = begin
                @match ele begin
                  CLASS(classDef = CLASS_EXTENDS())  => begin
                    false
                  end
                  
                  _  => begin
                      true
                  end
                end
              end
          isExtend
        end

         #= Returns true if Variability indicates a parameter or constant. =#
        function isParameterOrConst(inVariability::Variability)::Bool
              local outBoolean::Bool

              outBoolean = begin
                @match inVariability begin
                  PARAM()  => begin
                    true
                  end
                  
                  CONST()  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          outBoolean
        end

         #= Returns true if Variability is constant, otherwise false =#
        function isConstant(inVariability::Variability)::Bool
              local outBoolean::Bool

              outBoolean = begin
                @match inVariability begin
                  CONST()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outBoolean
        end

         #= Counts the number of ClassParts of a Class. =#
        function countParts(inClass::Element)::ModelicaInteger
              local outInteger::ModelicaInteger

              outInteger = begin
                  local res::ModelicaInteger
                  local elts::Lst
                @matchcontinue inClass begin
                  CLASS(classDef = PARTS(elementLst = elts))  => begin
                      res = listLength(elts)
                    res
                  end
                  
                  CLASS(classDef = CLASS_EXTENDS(composition = PARTS(elementLst = elts)))  => begin
                      res = listLength(elts)
                    res
                  end
                  
                  _  => begin
                      0
                  end
                end
              end
               #= /* adrpo: handle also model extends X ... parts ... end X; */ =#
          outInteger
        end

         #= Return a string list of all component names of a class. =#
        function componentNames(inClass::Element)::Lst
              local outStringLst::Lst

              outStringLst = begin
                  local res::Lst
                  local elts::Lst
                @match inClass begin
                  CLASS(classDef = PARTS(elementLst = elts))  => begin
                      res = componentNamesFromElts(elts)
                    res
                  end
                  
                  CLASS(classDef = CLASS_EXTENDS(composition = PARTS(elementLst = elts)))  => begin
                      res = componentNamesFromElts(elts)
                    res
                  end
                  
                  _  => begin
                      list()
                  end
                end
              end
               #= /* adrpo: handle also the case model extends X end X;*/ =#
          outStringLst
        end

         #= Helper function to componentNames. =#
        function componentNamesFromElts(inElements::Lst)::Lst
              local outComponentNames::Lst

              outComponentNames = List.filterMap(inElements, componentName)
          outComponentNames
        end

        function componentName(inComponent::Element)::String
              local outName::String

              COMPONENT(name = outName) = inComponent
          outName
        end

         #= retrieves the element info =#
        function elementInfo(e::Element)::SourceInfo
              local info::SourceInfo

              info = begin
                  local i::SourceInfo
                @match e begin
                  COMPONENT(info = i)  => begin
                    i
                  end
                  
                  CLASS(info = i)  => begin
                    i
                  end

                  EXTENDS(info = i)  => begin
                    i
                  end

                  IMPORT(info = i)  => begin
                    i
                  end

                  _  => begin
                      AbsynUtil.dummyInfo
                  end
                end
              end
          info
        end

         #=  =#
        function elementName(e::Element)::String
              local s::String

              s = begin
                @match e begin
                  COMPONENT(name = s)  => begin
                    s
                  end
                  
                  CLASS(name = s)  => begin
                    s
                  end
                end
              end
          s
        end

        function elementNameInfo(inElement::Element)::Tuple{SourceInfo, String}
              local outInfo::SourceInfo
              local outName::String

              (outName, outInfo) = begin
                  local name::String
                  local info::SourceInfo
                @match inElement begin
                  COMPONENT(name = name, info = info)  => begin
                    (name, info)
                  end
                  
                  CLASS(name = name, info = info)  => begin
                    (name, info)
                  end
                end
              end
          (outInfo, outName)
        end

         #= Gets all elements that have an element name from the list =#
        function elementNames(elts::Lst)::Lst
              local names::Lst

              names = List.fold(elts, elementNamesWork, list())
          names
        end

         #= Gets all elements that have an element name from the list =#
        function elementNamesWork(e::Element, acc::Lst)::Lst
              local out::Lst

              out = begin
                  local s::String
                @match (e, acc) begin
                  (COMPONENT(name = s), _)  => begin
                    s <| acc
                  end
                  
                  (CLASS(name = s), _)  => begin
                    s <| acc
                  end

                  _  => begin
                      acc
                  end
                end
              end
          out
        end

        function renameElement(inElement::Element, inName::String)::Element
              local outElement::Element

              outElement = begin
                  local pf::Prefixes
                  local ep::Encapsulated
                  local pp::Partial
                  local res::Restriction
                  local cdef::ClassDef
                  local i::SourceInfo
                  local attr::Attributes
                  local ty::Absyn.TypeSpec
                  local mod::Mod
                  local cmt::Comment
                  local cond::Option
                @match (inElement, inName) begin
                  (CLASS(_, pf, ep, pp, res, cdef, cmt, i), _)  => begin
                    CLASS(inName, pf, ep, pp, res, cdef, cmt, i)
                  end
                  
                  (COMPONENT(_, pf, attr, ty, mod, cmt, cond, i), _)  => begin
                    COMPONENT(inName, pf, attr, ty, mod, cmt, cond, i)
                  end
                end
              end
          outElement
        end

        function elementNameEqual(inElement1::Element, inElement2::Element)::Bool
              local outEqual::Bool

              outEqual = begin
                @match (inElement1, inElement2) begin
                  (CLASS(), CLASS())  => begin
                    inElement1.name == inElement2.name
                  end
                  
                  (COMPONENT(), COMPONENT())  => begin
                    inElement1.name == inElement2.name
                  end

                  (DEFINEUNIT(), DEFINEUNIT())  => begin
                    inElement1.name == inElement2.name
                  end

                  (EXTENDS(), EXTENDS())  => begin
                    AbsynUtil.pathEqual(inElement1.baseClassPath, inElement2.baseClassPath)
                  end

                  (IMPORT(), IMPORT())  => begin
                    AbsynUtil.importEqual(inElement1.imp, inElement2.imp)
                  end

                  _  => begin
                      false
                  end
                end
              end
          outEqual
        end

         #=  =#
        function enumName(e::Enum)::String
              local s::String

              s = begin
                @match e begin
                  ENUM(literal = s)  => begin
                    s
                  end
                end
              end
          s
        end

         #= Return true if Class is a record. =#
        function isRecord(inClass::Element)::Bool
              local outBoolean::Bool

              outBoolean = begin
                @match inClass begin
                  CLASS(restriction = R_RECORD())  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outBoolean
        end

         #= Return true if Class is a operator record. =#
        function isOperatorRecord(inClass::Element)::Bool
              local outBoolean::Bool

              outBoolean = begin
                @match inClass begin
                  CLASS(restriction = R_RECORD(true))  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outBoolean
        end

         #= Return true if Class is a function. =#
        function isFunction(inClass::Element)::Bool
              local outBoolean::Bool

              outBoolean = begin
                @match inClass begin
                  CLASS(restriction = R_FUNCTION())  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outBoolean
        end

         #= Return true if restriction is a function. =#
        function isFunctionRestriction(inRestriction::Restriction)::Bool
              local outBoolean::Bool

              outBoolean = begin
                @match inRestriction begin
                  R_FUNCTION()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outBoolean
        end

         #= restriction is function or external function.
          Otherwise false is returned. =#
        function isFunctionOrExtFunctionRestriction(r::Restriction)::Bool
              local res::Bool

              res = begin
                @match r begin
                  R_FUNCTION(FR_NORMAL_FUNCTION())  => begin
                    true
                  end
                  
                  R_FUNCTION(FR_EXTERNAL_FUNCTION())  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          res
        end

         #= restriction is operator or operator function.
          Otherwise false is returned. =#
        function isOperator(el::Element)::Bool
              local res::Bool

              res = begin
                @match el begin
                  CLASS(restriction = R_OPERATOR())  => begin
                    true
                  end
                  
                  CLASS(restriction = R_FUNCTION(FR_OPERATOR_FUNCTION()))  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          res
        end

         #= Returns the class name of a Class. =#
        function className(inClass::Element)::String
              local outName::String

              CLASS(name = outName) = inClass
          outName
        end

         #= author: PA
          Sets the partial attribute of a Class =#
        function classSetPartial(inClass::Element, inPartial::Partial)::Element
              local outClass::Element

              outClass = begin
                  local id::String
                  local enc::Encapsulated
                  local partialPrefix::Partial
                  local restr::Restriction
                  local def::ClassDef
                  local info::SourceInfo
                  local prefixes::Prefixes
                  local cmt::Comment
                @match (inClass, inPartial) begin
                  (CLASS(name = id, prefixes = prefixes, encapsulatedPrefix = enc, restriction = restr, classDef = def, cmt = cmt, info = info), partialPrefix)  => begin
                    CLASS(id, prefixes, enc, partialPrefix, restr, def, cmt, info)
                  end
                end
              end
          outClass
        end

         #= returns true if two elements are equal,
          i.e. for a component have the same type,
          name, and attributes, etc. =#
        function elementEqual(element1::Element, element2::Element)::Bool
              local equal::Bool

              equal = begin
                  local name1::Ident
                  local name2::Ident
                  local prefixes1::Prefixes
                  local prefixes2::Prefixes
                  local en1::Encapsulated
                  local en2::Encapsulated
                  local p1::Partial
                  local p2::Partial
                  local restr1::Restriction
                  local restr2::Restriction
                  local attr1::Attributes
                  local attr2::Attributes
                  local mod1::Mod
                  local mod2::Mod
                  local tp1::Absyn.TypeSpec
                  local tp2::Absyn.TypeSpec
                  local im1::Absyn.Import
                  local im2::Absyn.Import
                  local path1::Absyn.Path
                  local path2::Absyn.Path
                  local os1::Option
                  local os2::Option
                  local or1::Option
                  local or2::Option
                  local cond1::Option
                  local cond2::Option
                  local cd1::ClassDef
                  local cd2::ClassDef
                @matchcontinue (element1, element2) begin
                  (CLASS(name1, prefixes1, en1, p1, restr1, cd1, _, _), CLASS(name2, prefixes2, en2, p2, restr2, cd2, _, _))  => begin
                      @assert true == (stringEq(name1, name2))
                      @assert true == (prefixesEqual(prefixes1, prefixes2))
                      @assert true == (valueEq(en1, en2))
                      @assert true == (valueEq(p1, p2))
                      @assert true == (restrictionEqual(restr1, restr2))
                      @assert true == (classDefEqual(cd1, cd2))
                    true
                  end
                  
                  (COMPONENT(name1, prefixes1, attr1, tp1, mod1, _, cond1, _), COMPONENT(name2, prefixes2, attr2, tp2, mod2, _, cond2, _))  => begin
                      equality(cond1, cond2)
                      @assert true == (stringEq(name1, name2))
                      @assert true == (prefixesEqual(prefixes1, prefixes2))
                      @assert true == (attributesEqual(attr1, attr2))
                      @assert true == (modEqual(mod1, mod2))
                      @assert true == (AbsynUtil.typeSpecEqual(tp1, tp2))
                    true
                  end
                  
                  (EXTENDS(path1, _, mod1, _, _), EXTENDS(path2, _, mod2, _, _))  => begin
                      @assert true == (AbsynUtil.pathEqual(path1, path2))
                      @assert true == (modEqual(mod1, mod2))
                    true
                  end
                  
                  (IMPORT(imp = im1), IMPORT(imp = im2))  => begin
                      @assert true == (AbsynUtil.importEqual(im1, im2))
                    true
                  end
                  
                  (DEFINEUNIT(name1, _, os1, or1), DEFINEUNIT(name2, _, os2, or2))  => begin
                      @assert true == (stringEq(name1, name2))
                      equality(os1, os2)
                      equality(or1, or2)
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
               #=  otherwise false
               =#
          equal
        end

         #=  stefan
         =#

         #= returns true if 2 annotations are equal =#
        function annotationEqual(annotation1::Annotation, annotation2::Annotation)::Bool
              local equal::Bool

              local mod1::Mod
              local mod2::Mod

              ANNOTATION(modification = mod1) = annotation1
              ANNOTATION(modification = mod2) = annotation2
              equal = modEqual(mod1, mod2)
          equal
        end

         #= Returns true if two Restriction's are equal. =#
        function restrictionEqual(restr1::Restriction, restr2::Restriction)::Bool
              local equal::Bool

              equal = begin
                  local funcRest1::FunctionRestriction
                  local funcRest2::FunctionRestriction
                @match (restr1, restr2) begin
                  (R_CLASS(), R_CLASS())  => begin
                    true
                  end
                  
                  (R_OPTIMIZATION(), R_OPTIMIZATION())  => begin
                    true
                  end

                  (R_MODEL(), R_MODEL())  => begin
                    true
                  end

                  (R_RECORD(true), R_RECORD(true))  => begin
                    true
                  end

                  (R_RECORD(false), R_RECORD(false))  => begin
                    true
                  end

                  (R_BLOCK(), R_BLOCK())  => begin
                    true
                  end

                  (R_CONNECTOR(true), R_CONNECTOR(true))  => begin
                    true
                  end

                  (R_CONNECTOR(false), R_CONNECTOR(false))  => begin
                    true
                  end

                  (R_OPERATOR(), R_OPERATOR())  => begin
                    true
                  end

                  (R_TYPE(), R_TYPE())  => begin
                    true
                  end

                  (R_PACKAGE(), R_PACKAGE())  => begin
                    true
                  end

                  (R_FUNCTION(funcRest1), R_FUNCTION(funcRest2))  => begin
                    funcRestrictionEqual(funcRest1, funcRest2)
                  end

                  (R_ENUMERATION(), R_ENUMERATION())  => begin
                    true
                  end

                  (R_PREDEFINED_INTEGER(), R_PREDEFINED_INTEGER())  => begin
                    true
                  end

                  (R_PREDEFINED_REAL(), R_PREDEFINED_REAL())  => begin
                    true
                  end

                  (R_PREDEFINED_STRING(), R_PREDEFINED_STRING())  => begin
                    true
                  end

                  (R_PREDEFINED_BOOLEAN(), R_PREDEFINED_BOOLEAN())  => begin
                    true
                  end

                  (R_PREDEFINED_CLOCK(), R_PREDEFINED_CLOCK())  => begin
                    true
                  end

                  (R_PREDEFINED_ENUMERATION(), R_PREDEFINED_ENUMERATION())  => begin
                    true
                  end

                  (R_UNIONTYPE(), R_UNIONTYPE())  => begin
                    min(@do_threaded_for t1 == t2 (t1, t2) (restr1.typeVars, restr2.typeVars))
                  end

                  _  => begin
                      false
                  end
                end
              end
               #=  operator record
               =#
               #=  expandable connectors
               =#
               #=  non expandable connectors
               =#
               #=  operator
               =#
               #=  BTH
               =#
          equal
        end

        function funcRestrictionEqual(funcRestr1::FunctionRestriction, funcRestr2::FunctionRestriction)::Bool
              local equal::Bool

              equal = begin
                  local b1::Bool
                  local b2::Bool
                @match (funcRestr1, funcRestr2) begin
                  (FR_NORMAL_FUNCTION(b1), FR_NORMAL_FUNCTION(b2))  => begin
                    boolEq(b1, b2)
                  end
                  
                  (FR_EXTERNAL_FUNCTION(b1), FR_EXTERNAL_FUNCTION(b2))  => begin
                    boolEq(b1, b2)
                  end

                  (FR_OPERATOR_FUNCTION(), FR_OPERATOR_FUNCTION())  => begin
                    true
                  end

                  (FR_RECORD_CONSTRUCTOR(), FR_RECORD_CONSTRUCTOR())  => begin
                    true
                  end

                  (FR_PARALLEL_FUNCTION(), FR_PARALLEL_FUNCTION())  => begin
                    true
                  end

                  (FR_KERNEL_FUNCTION(), FR_KERNEL_FUNCTION())  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          equal
        end

        function enumEqual(e1::Enum, e2::Enum)::Bool
              local isEqual::Bool

              isEqual = begin
                  local s1::String
                  local s2::String
                  local b1::Bool
                @match (e1, e2) begin
                  (ENUM(s1, _), ENUM(s2, _))  => begin
                      b1 = stringEq(s1, s2)
                    b1
                  end
                end
              end
               #=  ignore comments here.
               =#
          isEqual
        end

         #= Returns true if Two ClassDef's are equal =#
        function classDefEqual(cdef1::ClassDef, cdef2::ClassDef)::Bool
              local equal::Bool

              equal = begin
                  local elts1::Lst
                  local elts2::Lst
                  local eqns1::Lst
                  local eqns2::Lst
                  local ieqns1::Lst
                  local ieqns2::Lst
                  local algs1::Lst
                  local algs2::Lst
                  local ialgs1::Lst
                  local ialgs2::Lst
                  local cons1::Lst
                  local cons2::Lst
                  local attr1::Attributes
                  local attr2::Attributes
                  local tySpec1::Absyn.TypeSpec
                  local tySpec2::Absyn.TypeSpec
                  local p1::Absyn.Path
                  local p2::Absyn.Path
                  local mod1::Mod
                  local mod2::Mod
                  local elst1::Lst
                  local elst2::Lst
                  local ilst1::Lst
                  local ilst2::Lst
                  local clsttrs1::Lst
                  local clsttrs2::Lst
                @match (cdef1, cdef2) begin
                  (PARTS(elts1, eqns1, ieqns1, algs1, ialgs1, _, _, _), PARTS(elts2, eqns2, ieqns2, algs2, ialgs2, _, _, _))  => begin
                      List.threadMapAllValue(elts1, elts2, elementEqual, true)
                      List.threadMapAllValue(eqns1, eqns2, equationEqual, true)
                      List.threadMapAllValue(ieqns1, ieqns2, equationEqual, true)
                      List.threadMapAllValue(algs1, algs2, algorithmEqual, true)
                      List.threadMapAllValue(ialgs1, ialgs2, algorithmEqual, true)
                    true
                  end
                  
                  (DERIVED(tySpec1, mod1, attr1), DERIVED(tySpec2, mod2, attr2))  => begin
                      @assert true == (AbsynUtil.typeSpecEqual(tySpec1, tySpec2))
                      @assert true == (modEqual(mod1, mod2))
                      @assert true == (attributesEqual(attr1, attr2))
                    true
                  end
                  
                  (ENUMERATION(elst1), ENUMERATION(elst2))  => begin
                      List.threadMapAllValue(elst1, elst2, enumEqual, true)
                    true
                  end
                  
                  (CLASS_EXTENDS(mod1, PARTS(elts1, eqns1, ieqns1, algs1, ialgs1, _, _, _)), CLASS_EXTENDS(mod2, PARTS(elts2, eqns2, ieqns2, algs2, ialgs2, _, _, _)))  => begin
                      List.threadMapAllValue(elts1, elts2, elementEqual, true)
                      List.threadMapAllValue(eqns1, eqns2, equationEqual, true)
                      List.threadMapAllValue(ieqns1, ieqns2, equationEqual, true)
                      List.threadMapAllValue(algs1, algs2, algorithmEqual, true)
                      List.threadMapAllValue(ialgs1, ialgs2, algorithmEqual, true)
                      @assert true == (modEqual(mod1, mod2))
                    true
                  end
                  
                  (PDER(_, ilst1), PDER(_, ilst2))  => begin
                      List.threadMapAllValue(ilst1, ilst2, stringEq, true)
                    true
                  end
                  
                  _  => begin
                      fail()
                  end
                end
              end
               #= /* adrpo: TODO! FIXME! are these below really needed??!!
                   as far as I can tell we handle all the cases.
                  case(cdef1, cdef2)
                    equation
                      equality(cdef1=cdef2);
                    then true;

                  case(cdef1, cdef2)
                    equation
                      failure(equality(cdef1=cdef2));
                    then false;*/ =#
          equal
        end

         #= Returns true if two Option<ArrayDim> are equal =#
        function arraydimOptEqual(adopt1::Option, adopt2::Option)::Bool
              local equal::Bool

              equal = begin
                  local lst1::Lst
                  local lst2::Lst
                  local blst::Lst
                @matchcontinue (adopt1, adopt2) begin
                  (NONE(), NONE())  => begin
                    true
                  end
                  
                  (SOME(lst1), SOME(lst2))  => begin
                      List.threadMapAllValue(lst1, lst2, subscriptEqual, true)
                    true
                  end
                  
                  (SOME(_), SOME(_))  => begin
                    false
                  end
                end
              end
               #=  oth. false
               =#
          equal
        end

         #= Returns true if two Absyn.Subscript are equal =#
        function subscriptEqual(sub1::Absyn.Subscript, sub2::Absyn.Subscript)::Bool
              local equal::Bool

              equal = begin
                  local e1::Absyn.Exp
                  local e2::Absyn.Exp
                @match (sub1, sub2) begin
                  (Absyn.NOSUB(), Absyn.NOSUB())  => begin
                    true
                  end
                  
                  (Absyn.SUBSCRIPT(e1), Absyn.SUBSCRIPT(e2))  => begin
                    AbsynUtil.expEqual(e1, e2)
                  end
                end
              end
          equal
        end

         #= Returns true if two Algorithm's are equal. =#
        function algorithmEqual(alg1::AlgorithmSection, alg2::AlgorithmSection)::Bool
              local equal::Bool

              equal = begin
                  local a1::Lst
                  local a2::Lst
                @matchcontinue (alg1, alg2) begin
                  (ALGORITHM(a1), ALGORITHM(a2))  => begin
                      List.threadMapAllValue(a1, a2, algorithmEqual2, true)
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
               #=  false otherwise!
               =#
          equal
        end

         #= Returns true if two Absyn.Algorithm are equal. =#
        function algorithmEqual2(ai1::Statement, ai2::Statement)::Bool
              local equal::Bool

              equal = begin
                  local alg1::Absyn.Algorithm
                  local alg2::Absyn.Algorithm
                  local a1::Statement
                  local a2::Statement
                  local cr1::Absyn.ComponentRef
                  local cr2::Absyn.ComponentRef
                  local e1::Absyn.Exp
                  local e2::Absyn.Exp
                  local e11::Absyn.Exp
                  local e12::Absyn.Exp
                  local e21::Absyn.Exp
                  local e22::Absyn.Exp
                  local b1::Bool
                  local b2::Bool
                @matchcontinue (ai1, ai2) begin
                  (ALG_ASSIGN(assignComponent = Absyn.CREF(cr1), value = e1), ALG_ASSIGN(assignComponent = Absyn.CREF(cr2), value = e2))  => begin
                      b1 = AbsynUtil.crefEqual(cr1, cr2)
                      b2 = AbsynUtil.expEqual(e1, e2)
                      equal = boolAnd(b1, b2)
                    equal
                  end
                  
                  (ALG_ASSIGN(assignComponent = e11 = Absyn.TUPLE(_), value = e12), ALG_ASSIGN(assignComponent = e21 = Absyn.TUPLE(_), value = e22))  => begin
                      b1 = AbsynUtil.expEqual(e11, e21)
                      b2 = AbsynUtil.expEqual(e12, e22)
                      equal = boolAnd(b1, b2)
                    equal
                  end
                  
                  (a1, a2)  => begin
                      Absyn.ALGORITHMITEM(algorithm_ = alg1) = statementToAlgorithmItem(a1)
                      Absyn.ALGORITHMITEM(algorithm_ = alg2) = statementToAlgorithmItem(a2)
                      equality(alg1, alg2)
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
               #=  base it on equality for now as the ones below are not implemented!
               =#
               #=  Don't compare comments and line numbers
               =#
               #=  maybe replace failure/equality with these:
               =#
               #= case(Absyn.ALG_IF(_,_,_,_),Absyn.ALG_IF(_,_,_,_)) then false;  TODO: ALG_IF
               =#
               #= case (Absyn.ALG_FOR(_,_),Absyn.ALG_FOR(_,_)) then false;  TODO: ALG_FOR
               =#
               #= case (Absyn.ALG_WHILE(_,_),Absyn.ALG_WHILE(_,_)) then false;  TODO: ALG_WHILE
               =#
               #= case(Absyn.ALG_WHEN_A(_,_,_),Absyn.ALG_WHEN_A(_,_,_)) then false; TODO: ALG_WHILE
               =#
               #= case (Absyn.ALG_NORETCALL(_,_),Absyn.ALG_NORETCALL(_,_)) then false; TODO: ALG_NORETCALL
               =#
          equal
        end

         #= Returns true if two equations are equal. =#
        function equationEqual(eqn1::Equation, eqn2::Equation)::Bool
              local equal::Bool

              local eq1::EEquation
              local eq2::EEquation

              EQUATION(eEquation = eq1) = eqn1
              EQUATION(eEquation = eq2) = eqn2
              equal = equationEqual2(eq1, eq2)
          equal
        end

         #= Helper function to equationEqual =#
        function equationEqual2(eq1::EEquation, eq2::EEquation)::Bool
              local equal::Bool

              equal = begin
                  local tb1::Lst
                  local tb2::Lst
                  local cond1::Absyn.Exp
                  local cond2::Absyn.Exp
                  local ifcond1::Lst
                  local ifcond2::Lst
                  local e11::Absyn.Exp
                  local e12::Absyn.Exp
                  local e21::Absyn.Exp
                  local e22::Absyn.Exp
                  local exp1::Absyn.Exp
                  local exp2::Absyn.Exp
                  local c1::Absyn.Exp
                  local c2::Absyn.Exp
                  local m1::Absyn.Exp
                  local m2::Absyn.Exp
                  local e1::Absyn.Exp
                  local e2::Absyn.Exp
                  local cr11::Absyn.ComponentRef
                  local cr12::Absyn.ComponentRef
                  local cr21::Absyn.ComponentRef
                  local cr22::Absyn.ComponentRef
                  local cr1::Absyn.ComponentRef
                  local cr2::Absyn.ComponentRef
                  local id1::Absyn.Ident
                  local id2::Absyn.Ident
                  local fb1::Lst
                  local fb2::Lst
                  local eql1::Lst
                  local eql2::Lst
                  local elst1::Lst
                  local elst2::Lst
                @matchcontinue (eq1, eq2) begin
                  (EQ_IF(condition = ifcond1, thenBranch = tb1, elseBranch = fb1), EQ_IF(condition = ifcond2, thenBranch = tb2, elseBranch = fb2))  => begin
                      @assert true == (equationEqual22(tb1, tb2))
                      List.threadMapAllValue(fb1, fb2, equationEqual2, true)
                      List.threadMapAllValue(ifcond1, ifcond2, AbsynUtil.expEqual, true)
                    true
                  end
                  
                  (EQ_EQUALS(expLeft = e11, expRight = e12), EQ_EQUALS(expLeft = e21, expRight = e22))  => begin
                      @assert true == (AbsynUtil.expEqual(e11, e21))
                      @assert true == (AbsynUtil.expEqual(e12, e22))
                    true
                  end
                  
                  (EQ_PDE(expLeft = e11, expRight = e12, domain = cr1), EQ_PDE(expLeft = e21, expRight = e22, domain = cr2))  => begin
                      @assert true == (AbsynUtil.expEqual(e11, e21))
                      @assert true == (AbsynUtil.expEqual(e12, e22))
                      @assert true == (AbsynUtil.crefEqual(cr1, cr2))
                    true
                  end
                  
                  (EQ_CONNECT(crefLeft = cr11, crefRight = cr12), EQ_CONNECT(crefLeft = cr21, crefRight = cr22))  => begin
                      @assert true == (AbsynUtil.crefEqual(cr11, cr21))
                      @assert true == (AbsynUtil.crefEqual(cr12, cr22))
                    true
                  end
                  
                  (EQ_FOR(index = id1, range = SOME(exp1), eEquationLst = eql1), EQ_FOR(index = id2, range = SOME(exp2), eEquationLst = eql2))  => begin
                      List.threadMapAllValue(eql1, eql2, equationEqual2, true)
                      @assert true == (AbsynUtil.expEqual(exp1, exp2))
                      @assert true == (stringEq(id1, id2))
                    true
                  end
                  
                  (EQ_FOR(index = id1, range = NONE(), eEquationLst = eql1), EQ_FOR(index = id2, range = NONE(), eEquationLst = eql2))  => begin
                      List.threadMapAllValue(eql1, eql2, equationEqual2, true)
                      @assert true == (stringEq(id1, id2))
                    true
                  end
                  
                  (EQ_WHEN(condition = cond1, eEquationLst = elst1), EQ_WHEN(condition = cond2, eEquationLst = elst2))  => begin
                      List.threadMapAllValue(elst1, elst2, equationEqual2, true)
                      @assert true == (AbsynUtil.expEqual(cond1, cond2))
                    true
                  end
                  
                  (EQ_ASSERT(condition = c1, message = m1), EQ_ASSERT(condition = c2, message = m2))  => begin
                      @assert true == (AbsynUtil.expEqual(c1, c2))
                      @assert true == (AbsynUtil.expEqual(m1, m2))
                    true
                  end
                  
                  (EQ_REINIT(), EQ_REINIT())  => begin
                      @assert true == (AbsynUtil.expEqual(eq1.cref, eq2.cref))
                      @assert true == (AbsynUtil.expEqual(eq1.expReinit, eq2.expReinit))
                    true
                  end
                  
                  (EQ_NORETCALL(exp = e1), EQ_NORETCALL(exp = e2))  => begin
                      @assert true == (AbsynUtil.expEqual(e1, e2))
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
               #=  TODO: elsewhen not checked yet.
               =#
               #=  otherwise false
               =#
          equal
        end

         #= Author BZ
         Helper function for equationEqual2, does compare list<list<equation>> (else ifs in ifequations.) =#
        function equationEqual22(inTb1::Lst, inTb2::Lst)::Bool
              local bOut::Bool

              bOut = begin
                  local tb_1::Lst
                  local tb_2::Lst
                  local tb1::Lst
                  local tb2::Lst
                @matchcontinue (inTb1, inTb2) begin
                  ( nil(),  nil())  => begin
                    true
                  end
                  
                  (_,  nil())  => begin
                    false
                  end

                  ( nil(), _)  => begin
                    false
                  end

                  (tb_1 <| tb1, tb_2 <| tb2)  => begin
                      List.threadMapAllValue(tb_1, tb_2, equationEqual2, true)
                      @assert true == (equationEqual22(tb1, tb2))
                    true
                  end
                  
                  (_ <| _, _ <| _)  => begin
                    false
                  end
                end
              end
          bOut
        end

         #= Return true if two Mod:s are equal =#
        function modEqual(mod1::Mod, mod2::Mod)::Bool
              local equal::Bool

              equal = begin
                  local f1::Final
                  local f2::Final
                  local each1::Each
                  local each2::Each
                  local submodlst1::Lst
                  local submodlst2::Lst
                  local e1::Absyn.Exp
                  local e2::Absyn.Exp
                  local elt1::Element
                  local elt2::Element
                @matchcontinue (mod1, mod2) begin
                  (MOD(f1, each1, submodlst1, SOME(e1), _), MOD(f2, each2, submodlst2, SOME(e2), _))  => begin
                      @assert true == (valueEq(f1, f2))
                      @assert true == (eachEqual(each1, each2))
                      @assert true == (subModsEqual(submodlst1, submodlst2))
                      @assert true == (AbsynUtil.expEqual(e1, e2))
                    true
                  end
                  
                  (MOD(f1, each1, submodlst1, NONE(), _), MOD(f2, each2, submodlst2, NONE(), _))  => begin
                      @assert true == (valueEq(f1, f2))
                      @assert true == (eachEqual(each1, each2))
                      @assert true == (subModsEqual(submodlst1, submodlst2))
                    true
                  end
                  
                  (NOMOD(), NOMOD())  => begin
                    true
                  end

                  (REDECL(f1, each1, elt1), REDECL(f2, each2, elt2))  => begin
                      @assert true == (valueEq(f1, f2))
                      @assert true == (eachEqual(each1, each2))
                      @assert true == (elementEqual(elt1, elt2))
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          equal
        end

         #= Return true if two subModifier lists are equal =#
        function subModsEqual(inSubModLst1::Lst, inSubModLst2::Lst)::Bool
              local equal::Bool

              equal = begin
                  local id1::Ident
                  local id2::Ident
                  local mod1::Mod
                  local mod2::Mod
                  local ss1::Lst
                  local ss2::Lst
                  local subModLst1::Lst
                  local subModLst2::Lst
                @matchcontinue (inSubModLst1, inSubModLst2) begin
                  ( nil(),  nil())  => begin
                    true
                  end
                  
                  (NAMEMOD(id1, mod1) <| subModLst1, NAMEMOD(id2, mod2) <| subModLst2)  => begin
                      @assert true == (stringEq(id1, id2))
                      @assert true == (modEqual(mod1, mod2))
                      @assert true == (subModsEqual(subModLst1, subModLst2))
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          equal
        end

         #= Returns true if two subscript lists are equal =#
        function subscriptsEqual(inSs1::Lst, inSs2::Lst)::Bool
              local equal::Bool

              equal = begin
                  local e1::Absyn.Exp
                  local e2::Absyn.Exp
                  local ss1::Lst
                  local ss2::Lst
                @matchcontinue (inSs1, inSs2) begin
                  ( nil(),  nil())  => begin
                    true
                  end
                  
                  (Absyn.NOSUB() <| ss1, Absyn.NOSUB() <| ss2)  => begin
                    subscriptsEqual(ss1, ss2)
                  end

                  (Absyn.SUBSCRIPT(e1) <| ss1, Absyn.SUBSCRIPT(e2) <| ss2)  => begin
                      @assert true == (AbsynUtil.expEqual(e1, e2))
                      @assert true == (subscriptsEqual(ss1, ss2))
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          equal
        end

         #= Returns true if two Atributes are equal =#
        function attributesEqual(attr1::Attributes, attr2::Attributes)::Bool
              local equal::Bool

              equal = begin
                  local prl1::Parallelism
                  local prl2::Parallelism
                  local var1::Variability
                  local var2::Variability
                  local ct1::ConnectorType
                  local ct2::ConnectorType
                  local ad1::Absyn.ArrayDim
                  local ad2::Absyn.ArrayDim
                  local dir1::Absyn.Direction
                  local dir2::Absyn.Direction
                  local if1::Absyn.IsField
                  local if2::Absyn.IsField
                @matchcontinue (attr1, attr2) begin
                  (ATTR(ad1, ct1, prl1, var1, dir1, if1), ATTR(ad2, ct2, prl2, var2, dir2, if2))  => begin
                      @assert true == (arrayDimEqual(ad1, ad2))
                      @assert true == (valueEq(ct1, ct2))
                      @assert true == (parallelismEqual(prl1, prl2))
                      @assert true == (variabilityEqual(var1, var2))
                      @assert true == (AbsynUtil.directionEqual(dir1, dir2))
                      @assert true == (AbsynUtil.isFieldEqual(if1, if2))
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          equal
        end

         #= Returns true if two Parallelism prefixes are equal =#
        function parallelismEqual(prl1::Parallelism, prl2::Parallelism)::Bool
              local equal::Bool

              equal = begin
                @match (prl1, prl2) begin
                  (PARGLOBAL(), PARGLOBAL())  => begin
                    true
                  end
                  
                  (PARLOCAL(), PARLOCAL())  => begin
                    true
                  end

                  (NON_PARALLEL(), NON_PARALLEL())  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          equal
        end

         #= Returns true if two Variablity prefixes are equal =#
        function variabilityEqual(var1::Variability, var2::Variability)::Bool
              local equal::Bool

              equal = begin
                @match (var1, var2) begin
                  (VAR(), VAR())  => begin
                    true
                  end
                  
                  (DISCRETE(), DISCRETE())  => begin
                    true
                  end

                  (PARAM(), PARAM())  => begin
                    true
                  end

                  (CONST(), CONST())  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          equal
        end

         #= Return true if two arraydims are equal =#
        function arrayDimEqual(iad1::Absyn.ArrayDim, iad2::Absyn.ArrayDim)::Bool
              local equal::Bool

              equal = begin
                  local e1::Absyn.Exp
                  local e2::Absyn.Exp
                  local ad1::Absyn.ArrayDim
                  local ad2::Absyn.ArrayDim
                @matchcontinue (iad1, iad2) begin
                  ( nil(),  nil())  => begin
                    true
                  end
                  
                  (Absyn.NOSUB() <| ad1, Absyn.NOSUB() <| ad2)  => begin
                      @assert true == (arrayDimEqual(ad1, ad2))
                    true
                  end
                  
                  (Absyn.SUBSCRIPT(e1) <| ad1, Absyn.SUBSCRIPT(e2) <| ad2)  => begin
                      @assert true == (AbsynUtil.expEqual(e1, e2))
                      @assert true == (arrayDimEqual(ad1, ad2))
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          equal
        end

         #= Sets the restriction of a SCode Class =#
        function setClassRestriction(r::Restriction, cl::Element)::Element
              local outCl::Element

              outCl = begin
                  local parts::ClassDef
                  local p::Partial
                  local e::Encapsulated
                  local id::Ident
                  local info::SourceInfo
                  local prefixes::Prefixes
                  local oldR::Restriction
                  local cmt::Comment
                   #=  check if restrictions are equal, so you can return the same thing!
                   =#
                @matchcontinue (r, cl) begin
                  (_, CLASS(restriction = oldR))  => begin
                      @assert true == (restrictionEqual(r, oldR))
                    cl
                  end
                  
                  (_, CLASS(id, prefixes, e, p, _, parts, cmt, info))  => begin
                    CLASS(id, prefixes, e, p, r, parts, cmt, info)
                  end
                end
              end
               #=  not equal, change
               =#
          outCl
        end

         #= Sets the name of a SCode Class =#
        function setClassName(name::Ident, cl::Element)::Element
              local outCl::Element

              outCl = begin
                  local parts::ClassDef
                  local p::Partial
                  local e::Encapsulated
                  local info::SourceInfo
                  local prefixes::Prefixes
                  local r::Restriction
                  local id::Ident
                  local cmt::Comment
                   #=  check if restrictions are equal, so you can return the same thing!
                   =#
                @matchcontinue (name, cl) begin
                  (_, CLASS(name = id))  => begin
                      @assert true == (stringEqual(name, id))
                    cl
                  end
                  
                  (_, CLASS(_, prefixes, e, p, r, parts, cmt, info))  => begin
                    CLASS(name, prefixes, e, p, r, parts, cmt, info)
                  end
                end
              end
               #=  not equal, change
               =#
          outCl
        end

        function makeClassPartial(inClass::Element)::Element
              local outClass::Element = inClass

              outClass = begin
                @match outClass begin
                  CLASS(partialPrefix = NOT_PARTIAL())  => begin
                      outClass.partialPrefix = PARTIAL()
                    outClass
                  end
                  
                  _  => begin
                      outClass
                  end
                end
              end
          outClass
        end

         #= Sets the partial prefix of a SCode Class =#
        function setClassPartialPrefix(partialPrefix::Partial, cl::Element)::Element
              local outCl::Element

              outCl = begin
                  local parts::ClassDef
                  local e::Encapsulated
                  local id::Ident
                  local info::SourceInfo
                  local restriction::Restriction
                  local prefixes::Prefixes
                  local oldPartialPrefix::Partial
                  local cmt::Comment
                   #=  check if partial prefix are equal, so you can return the same thing!
                   =#
                @matchcontinue (partialPrefix, cl) begin
                  (_, CLASS(partialPrefix = oldPartialPrefix))  => begin
                      @assert true == (valueEq(partialPrefix, oldPartialPrefix))
                    cl
                  end
                  
                  (_, CLASS(id, prefixes, e, _, restriction, parts, cmt, info))  => begin
                    CLASS(id, prefixes, e, partialPrefix, restriction, parts, cmt, info)
                  end
                end
              end
               #=  not the same, change
               =#
          outCl
        end

        function findIteratorIndexedCrefsInEEquations(inEqs::Lst, inIterator::String, inCrefs::Lst = list())::Lst
              local outCrefs::Lst

              outCrefs = List.fold1(inEqs, findIteratorIndexedCrefsInEEquation, inIterator, inCrefs)
          outCrefs
        end

        function findIteratorIndexedCrefsInEEquation(inEq::EEquation, inIterator::String, inCrefs::Lst = list())::Lst
              local outCrefs::Lst

              outCrefs = SCode.foldEEquationsExps(inEq, @ExtendedAnonFunction AbsynUtil.findIteratorIndexedCrefs(inIterator = inIterator), inCrefs)
          outCrefs
        end

        function findIteratorIndexedCrefsInStatements(inStatements::Lst, inIterator::String, inCrefs::Lst = list())::Lst
              local outCrefs::Lst

              outCrefs = List.fold1(inStatements, findIteratorIndexedCrefsInStatement, inIterator, inCrefs)
          outCrefs
        end

        function findIteratorIndexedCrefsInStatement(inStatement::Statement, inIterator::String, inCrefs::Lst = list())::Lst
              local outCrefs::Lst

              outCrefs = SCode.foldStatementsExps(inStatement, @ExtendedAnonFunction AbsynUtil.findIteratorIndexedCrefs(inIterator = inIterator), inCrefs)
          outCrefs
        end

         #= Filters out the components from the given list of elements, as well as their names. =#
        function filterComponents(inElements::Lst)::Tuple{List, List}
              local outComponentNames::Lst
              local outComponents::Lst

              (outComponents, outComponentNames) = List.map_2(inElements, filterComponents2)
          (outComponentNames, outComponents)
        end

        function filterComponents2(inElement::Element)::Tuple{String, Element}
              local outName::String
              local outComponent::Element

              COMPONENT(name = outName) = inElement
              outComponent = inElement
          (outName, outComponent)
        end

         #= This function returns the components from a class =#
        function getClassComponents(cl::Element)::Tuple{List, List}
              local compNames::Lst
              local compElts::Lst

              (compElts, compNames) = begin
                  local elts::Lst
                  local comps::Lst
                  local names::Lst
                @match cl begin
                  CLASS(classDef = PARTS(elementLst = elts))  => begin
                      (comps, names) = filterComponents(elts)
                    (comps, names)
                  end
                  
                  CLASS(classDef = CLASS_EXTENDS(composition = PARTS(elementLst = elts)))  => begin
                      (comps, names) = filterComponents(elts)
                    (comps, names)
                  end
                end
              end
          (compNames, compElts)
        end

         #= This function returns the components from a class =#
        function getClassElements(cl::Element)::Lst
              local elts::Lst

              elts = begin
                @match cl begin
                  CLASS(classDef = PARTS(elementLst = elts))  => begin
                    elts
                  end
                  
                  CLASS(classDef = CLASS_EXTENDS(composition = PARTS(elementLst = elts)))  => begin
                    elts
                  end

                  _  => begin
                      list()
                  end
                end
              end
          elts
        end

         #= Creates an EnumType element from an enumeration literal and an optional
          comment. =#
        function makeEnumType(inEnum::Enum, inInfo::SourceInfo)::Element
              local outEnumType::Element

              local literal::String
              local comment::Comment

              ENUM(literal = literal, comment = comment) = inEnum
              #NFSCodeCheck.checkValidEnumLiteral(literal, inInfo)
              outEnumType = COMPONENT(literal, defaultPrefixes, defaultConstAttr, Absyn.TPATH(Absyn.IDENT("EnumType"), NONE()), NOMOD(), comment, NONE(), inInfo)
          outEnumType
        end

         #= Returns the more constant of two Variabilities
           (considers VAR() < DISCRETE() < PARAM() < CONST()),
           similarly to Types.constOr. =#
        function variabilityOr(inConst1::Variability, inConst2::Variability)::Variability
              local outConst::Variability

              outConst = begin
                @match (inConst1, inConst2) begin
                  (CONST(), _)  => begin
                    CONST()
                  end
                  
                  (_, CONST())  => begin
                    CONST()
                  end

                  (PARAM(), _)  => begin
                    PARAM()
                  end

                  (_, PARAM())  => begin
                    PARAM()
                  end

                  (DISCRETE(), _)  => begin
                    DISCRETE()
                  end

                  (_, DISCRETE())  => begin
                    DISCRETE()
                  end

                  _  => begin
                      VAR()
                  end
                end
              end
          outConst
        end

         #= Transforms SCode.Statement back to Absyn.AlgorithmItem. Discards the comment.
        Only to be used to unparse statements again. =#
        function statementToAlgorithmItem(stmt::Statement)::Absyn.AlgorithmItem
              local algi::Absyn.AlgorithmItem

              algi = begin
                  local functionCall::Absyn.ComponentRef
                  local assignComponent::Absyn.Exp
                  local boolExpr::Absyn.Exp
                  local value::Absyn.Exp
                  local iterator::String
                  local range::Option
                  local functionArgs::Absyn.FunctionArgs
                  local info::SourceInfo
                  local conditions::Lst
                  local stmtsList::Lst
                  local body::Lst
                  local trueBranch::Lst
                  local elseBranch::Lst
                  local branches::Lst
                  local comment::Option
                  local algs1::Lst
                  local algs2::Lst
                  local algsLst::Lst
                  local abranches::Lst
                @match stmt begin
                  ALG_ASSIGN(assignComponent, value, _, info)  => begin
                    Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(assignComponent, value), NONE(), info)
                  end
                  
                  ALG_IF(boolExpr, trueBranch, branches, elseBranch, _, info)  => begin
                      algs1 = List.map(trueBranch, statementToAlgorithmItem)
                      conditions = List.map(branches, Util.tuple21)
                      stmtsList = List.map(branches, Util.tuple22)
                      algsLst = List.mapList(stmtsList, statementToAlgorithmItem)
                      abranches = List.threadTuple(conditions, algsLst)
                      algs2 = List.map(elseBranch, statementToAlgorithmItem)
                    Absyn.ALGORITHMITEM(Absyn.ALG_IF(boolExpr, algs1, abranches, algs2), NONE(), info)
                  end
                  
                  ALG_FOR(iterator, range, body, _, info)  => begin
                      algs1 = List.map(body, statementToAlgorithmItem)
                    Absyn.ALGORITHMITEM(Absyn.ALG_FOR(list(Absyn.ITERATOR(iterator, NONE(), range)), algs1), NONE(), info)
                  end
                  
                  ALG_PARFOR(iterator, range, body, _, info)  => begin
                      algs1 = List.map(body, statementToAlgorithmItem)
                    Absyn.ALGORITHMITEM(Absyn.ALG_PARFOR(list(Absyn.ITERATOR(iterator, NONE(), range)), algs1), NONE(), info)
                  end
                  
                  ALG_WHILE(boolExpr, body, _, info)  => begin
                      algs1 = List.map(body, statementToAlgorithmItem)
                    Absyn.ALGORITHMITEM(Absyn.ALG_WHILE(boolExpr, algs1), NONE(), info)
                  end
                  
                  ALG_WHEN_A(branches, _, info)  => begin
                      boolExpr, conditions = listHead(List.map(branches, Util.tuple21)), listRest(List.map(branches, Util.tuple21))
                      stmtsList = List.map(branches, Util.tuple22)
                      algs1, algsLst = listHead(List.mapList(stmtsList, statementToAlgorithmItem)), listRest(List.mapList(stmtsList, statementToAlgorithmItem))
                      abranches = List.threadTuple(conditions, algsLst)
                    Absyn.ALGORITHMITEM(Absyn.ALG_WHEN_A(boolExpr, algs1, abranches), NONE(), info)
                  end
                  
                  ALG_ASSERT()  => begin
                    Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("assert", list()), Absyn.FUNCTIONARGS(list(stmt.condition, stmt.message, stmt.level), list())), NONE(), stmt.info)
                  end

                  ALG_TERMINATE()  => begin
                    Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("terminate", list()), Absyn.FUNCTIONARGS(list(stmt.message), list())), NONE(), stmt.info)
                  end

                  ALG_REINIT()  => begin
                    Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("reinit", list()), Absyn.FUNCTIONARGS(list(stmt.cref, stmt.newValue), list())), NONE(), stmt.info)
                  end

                  ALG_NORETCALL(Absyn.CALL(function_ = functionCall, functionArgs = functionArgs), _, info)  => begin
                    Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(functionCall, functionArgs), NONE(), info)
                  end

                  ALG_RETURN(_, info)  => begin
                    Absyn.ALGORITHMITEM(Absyn.ALG_RETURN(), NONE(), info)
                  end

                  ALG_BREAK(_, info)  => begin
                    Absyn.ALGORITHMITEM(Absyn.ALG_BREAK(), NONE(), info)
                  end

                  ALG_CONTINUE(_, info)  => begin
                    Absyn.ALGORITHMITEM(Absyn.ALG_CONTINUE(), NONE(), info)
                  end

                  ALG_FAILURE(body, _, info)  => begin
                      algs1 = List.map(body, statementToAlgorithmItem)
                    Absyn.ALGORITHMITEM(Absyn.ALG_FAILURE(algs1), NONE(), info)
                  end
                end
              end
          algi
        end

        function equationFileInfo(eq::EEquation)::SourceInfo
              local info::SourceInfo

              info = begin
                @match eq begin
                  EQ_IF(info = info)  => begin
                    info
                  end
                  
                  EQ_EQUALS(info = info)  => begin
                    info
                  end

                  EQ_PDE(info = info)  => begin
                    info
                  end

                  EQ_CONNECT(info = info)  => begin
                    info
                  end

                  EQ_FOR(info = info)  => begin
                    info
                  end

                  EQ_WHEN(info = info)  => begin
                    info
                  end

                  EQ_ASSERT(info = info)  => begin
                    info
                  end

                  EQ_TERMINATE(info = info)  => begin
                    info
                  end

                  EQ_REINIT(info = info)  => begin
                    info
                  end

                  EQ_NORETCALL(info = info)  => begin
                    info
                  end
                end
              end
          info
        end

         #= Checks if a Mod is empty (or only an equality binding is present) =#
        function emptyModOrEquality(mod::Mod)::Bool
              local b::Bool

              b = begin
                @match mod begin
                  NOMOD()  => begin
                    true
                  end
                  
                  MOD(subModLst =  nil())  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          b
        end

        function isComponentWithDirection(elt::Element, dir1::Absyn.Direction)::Bool
              local b::Bool

              b = begin
                  local dir2::Absyn.Direction
                @match (elt, dir1) begin
                  (COMPONENT(attributes = ATTR(direction = dir2)), _)  => begin
                    AbsynUtil.directionEqual(dir1, dir2)
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          b
        end

        function isComponent(elt::Element)::Bool
              local b::Bool

              b = begin
                @match elt begin
                  COMPONENT()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          b
        end

        function isNotComponent(elt::Element)::Bool
              local b::Bool

              b = begin
                @match elt begin
                  COMPONENT()  => begin
                    false
                  end
                  
                  _  => begin
                      true
                  end
                end
              end
          b
        end

        function isClassOrComponent(inElement::Element)::Bool
              local outIsClassOrComponent::Bool

              outIsClassOrComponent = begin
                @match inElement begin
                  CLASS()  => begin
                    true
                  end
                  
                  COMPONENT()  => begin
                    true
                  end
                end
              end
          outIsClassOrComponent
        end

        function isClass(inElement::Element)::Bool
              local outIsClass::Bool

              outIsClass = begin
                @match inElement begin
                  CLASS()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outIsClass
        end

        function isFunctionOutput(inElement::Element)::Bool
              local isOutput::Bool

              isOutput = begin
                @match inElement begin
                  COMPONENT(attributes = ATTR(direction = Absyn.OUTPUT(__)))  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isOutput
        end

        function getOutputElements(inElements::Lst)::Lst
              local outElements::Lst

              outElements = List.filterOnTrue(inElements, isFunctionOutput)
          outElements
        end

         #= Calls the given function on the equation and all its subequations, and
           updates the argument for each call. =#
        ArgT = Any 
        function foldEEquations(inEquation::EEquation, inFunc::FoldFunc, inArg::ArgT)::ArgT
              local outArg::ArgT

              outArg = inFunc(inEquation, inArg)
              outArg = begin
                  local eql::Lst
                @match inEquation begin
                  EQ_IF()  => begin
                      outArg = List.foldList1(inEquation.thenBranch, foldEEquations, inFunc, outArg)
                    List.fold1(inEquation.elseBranch, foldEEquations, inFunc, outArg)
                  end
                  
                  EQ_FOR()  => begin
                    List.fold1(inEquation.eEquationLst, foldEEquations, inFunc, outArg)
                  end

                  EQ_WHEN()  => begin
                      outArg = List.fold1(inEquation.eEquationLst, foldEEquations, inFunc, outArg)
                      for branch in inEquation.elseBranches
                        (_, eql) = branch
                        outArg = List.fold1(eql, foldEEquations, inFunc, outArg)
                      end
                    outArg
                  end
                end
              end
          outArg
        end

         #= Calls the given function on all expressions inside the equation, and updates
           the argument for each call. =#
        ArgT = Any 
        function foldEEquationsExps(inEquation::EEquation, inFunc::FoldFunc, inArg::ArgT)::ArgT
              local outArg::ArgT = inArg

              outArg = begin
                  local exp::Absyn.Exp
                  local eql::Lst
                @match inEquation begin
                  EQ_IF()  => begin
                      outArg = List.fold(inEquation.condition, inFunc, outArg)
                      outArg = List.foldList1(inEquation.thenBranch, foldEEquationsExps, inFunc, outArg)
                    List.fold1(inEquation.elseBranch, foldEEquationsExps, inFunc, outArg)
                  end
                  
                  EQ_EQUALS()  => begin
                      outArg = inFunc(inEquation.expLeft, outArg)
                      outArg = inFunc(inEquation.expRight, outArg)
                    outArg
                  end
                  
                  EQ_PDE()  => begin
                      outArg = inFunc(inEquation.expLeft, outArg)
                      outArg = inFunc(inEquation.expRight, outArg)
                    outArg
                  end
                  
                  EQ_CONNECT()  => begin
                      outArg = inFunc(Absyn.CREF(inEquation.crefLeft), outArg)
                      outArg = inFunc(Absyn.CREF(inEquation.crefRight), outArg)
                    outArg
                  end
                  
                  EQ_FOR()  => begin
                      if isSome(inEquation.range)
                        SOME(exp) = inEquation.range
                        outArg = inFunc(exp, outArg)
                      end
                    List.fold1(inEquation.eEquationLst, foldEEquationsExps, inFunc, outArg)
                  end
                  
                  EQ_WHEN()  => begin
                      outArg = List.fold1(inEquation.eEquationLst, foldEEquationsExps, inFunc, outArg)
                      for branch in inEquation.elseBranches
                        (exp, eql) = branch
                        outArg = inFunc(exp, outArg)
                        outArg = List.fold1(eql, foldEEquationsExps, inFunc, outArg)
                      end
                    outArg
                  end
                  
                  EQ_ASSERT()  => begin
                      outArg = inFunc(inEquation.condition, outArg)
                      outArg = inFunc(inEquation.message, outArg)
                      outArg = inFunc(inEquation.level, outArg)
                    outArg
                  end
                  
                  EQ_TERMINATE()  => begin
                    inFunc(inEquation.message, outArg)
                  end

                  EQ_REINIT()  => begin
                      outArg = inFunc(inEquation.cref, outArg)
                      outArg = inFunc(inEquation.expReinit, outArg)
                    outArg
                  end
                  
                  EQ_NORETCALL()  => begin
                    inFunc(inEquation.exp, outArg)
                  end
                end
              end
          outArg
        end

         #= Calls the given function on all expressions inside the statement, and updates
           the argument for each call. =#
        ArgT = Any 
        function foldStatementsExps(inStatement::Statement, inFunc::FoldFunc, inArg::ArgT)::ArgT
              local outArg::ArgT = inArg

              outArg = begin
                  local exp::Absyn.Exp
                  local stmts::Lst
                @match inStatement begin
                  ALG_ASSIGN()  => begin
                      outArg = inFunc(inStatement.assignComponent, outArg)
                      outArg = inFunc(inStatement.value, outArg)
                    outArg
                  end
                  
                  ALG_IF()  => begin
                      outArg = inFunc(inStatement.boolExpr, outArg)
                      outArg = List.fold1(inStatement.trueBranch, foldStatementsExps, inFunc, outArg)
                      for branch in inStatement.elseIfBranch
                        (exp, stmts) = branch
                        outArg = inFunc(exp, outArg)
                        outArg = List.fold1(stmts, foldStatementsExps, inFunc, outArg)
                      end
                    outArg
                  end
                  
                  ALG_FOR()  => begin
                      if isSome(inStatement.range)
                        SOME(exp) = inStatement.range
                        outArg = inFunc(exp, outArg)
                      end
                    List.fold1(inStatement.forBody, foldStatementsExps, inFunc, outArg)
                  end
                  
                  ALG_PARFOR()  => begin
                      if isSome(inStatement.range)
                        SOME(exp) = inStatement.range
                        outArg = inFunc(exp, outArg)
                      end
                    List.fold1(inStatement.parforBody, foldStatementsExps, inFunc, outArg)
                  end
                  
                  ALG_WHILE()  => begin
                      outArg = inFunc(inStatement.boolExpr, outArg)
                    List.fold1(inStatement.whileBody, foldStatementsExps, inFunc, outArg)
                  end
                  
                  ALG_WHEN_A()  => begin
                      for branch in inStatement.branches
                        (exp, stmts) = branch
                        outArg = inFunc(exp, outArg)
                        outArg = List.fold1(stmts, foldStatementsExps, inFunc, outArg)
                      end
                    outArg
                  end
                  
                  ALG_ASSERT()  => begin
                      outArg = inFunc(inStatement.condition, outArg)
                      outArg = inFunc(inStatement.message, outArg)
                      outArg = inFunc(inStatement.level, outArg)
                    outArg
                  end
                  
                  ALG_TERMINATE()  => begin
                    inFunc(inStatement.message, outArg)
                  end

                  ALG_REINIT()  => begin
                      outArg = inFunc(inStatement.cref, outArg)
                    inFunc(inStatement.newValue, outArg)
                  end
                  
                  ALG_NORETCALL()  => begin
                    inFunc(inStatement.exp, outArg)
                  end

                  ALG_FAILURE()  => begin
                    List.fold1(inStatement.stmts, foldStatementsExps, inFunc, outArg)
                  end

                  ALG_TRY()  => begin
                      outArg = List.fold1(inStatement.body, foldStatementsExps, inFunc, outArg)
                    List.fold1(inStatement.elseBody, foldStatementsExps, inFunc, outArg)
                  end
                  
                  ALG_RETURN()  => begin
                    outArg
                  end

                  ALG_BREAK()  => begin
                    outArg
                  end

                  ALG_CONTINUE()  => begin
                    outArg
                  end
                end
              end
               #=  No else case, to make this function break if a new statement is added to SCode.
               =#
          outArg
        end

         #= Traverses a list of EEquations, calling traverseEEquations on each EEquation
          in the list. =#
        function traverseEEquationsList(inEEquations::Lst, inTuple::Tuple)::Tuple{Tuple, List}
              local outTuple::Tuple
              local outEEquations::Lst

              (outEEquations, outTuple) = List.mapFold(inEEquations, traverseEEquations, inTuple)
          (outTuple, outEEquations)
        end

         #= Traverses an EEquation. For each EEquation it finds it calls the given
          function with the EEquation and an extra argument which is passed along. =#
        function traverseEEquations(inEEquation::EEquation, inTuple::Tuple)::Tuple{Tuple, EEquation}
              local outTuple::Tuple
              local outEEquation::EEquation

              local traverser::TraverseFunc
              local arg::Argument
              local eq::EEquation

              (traverser, arg) = inTuple
              (eq, arg) = traverser((inEEquation, arg))
              (outEEquation, outTuple) = traverseEEquations2(eq, (traverser, arg))
          (outTuple, outEEquation)
        end

         #= Helper function to traverseEEquations, does the actual traversing. =#
        function traverseEEquations2(inEEquation::EEquation, inTuple::Tuple)::Tuple{Tuple, EEquation}
              local outTuple::Tuple
              local outEEquation::EEquation

              (outEEquation, outTuple) = begin
                  local tup::Tuple
                  local e1::Absyn.Exp
                  local oe1::Option
                  local expl1::Lst
                  local then_branch::Lst
                  local else_branch::Lst
                  local eql::Lst
                  local else_when::Lst
                  local comment::Comment
                  local info::SourceInfo
                  local index::Ident
                @match (inEEquation, inTuple) begin
                  (EQ_IF(expl1, then_branch, else_branch, comment, info), tup)  => begin
                      (then_branch, tup) = List.mapFold(then_branch, traverseEEquationsList, tup)
                      (else_branch, tup) = traverseEEquationsList(else_branch, tup)
                    (EQ_IF(expl1, then_branch, else_branch, comment, info), tup)
                  end
                  
                  (EQ_FOR(index, oe1, eql, comment, info), tup)  => begin
                      (eql, tup) = traverseEEquationsList(eql, tup)
                    (EQ_FOR(index, oe1, eql, comment, info), tup)
                  end
                  
                  (EQ_WHEN(e1, eql, else_when, comment, info), tup)  => begin
                      (eql, tup) = traverseEEquationsList(eql, tup)
                      (else_when, tup) = List.mapFold(else_when, traverseElseWhenEEquations, tup)
                    (EQ_WHEN(e1, eql, else_when, comment, info), tup)
                  end
                  
                  _  => begin
                      (inEEquation, inTuple)
                  end
                end
              end
          (outTuple, outEEquation)
        end

         #= Traverses all EEquations in an else when branch, calling the given function
          on each EEquation. =#
        function traverseElseWhenEEquations(inElseWhen::Tuple, inTuple::Tuple)::Tuple{Tuple, Tuple}
              local outTuple::Tuple
              local outElseWhen::Tuple

              local exp::Absyn.Exp
              local eql::Lst

              (exp, eql) = inElseWhen
              (eql, outTuple) = traverseEEquationsList(eql, inTuple)
              outElseWhen = (exp, eql)
          (outTuple, outElseWhen)
        end

         #= Traverses a list of EEquations, calling the given function on each Absyn.Exp
          it encounters. =#
        function traverseEEquationListExps(inEEquations::Lst, traverser::TraverseFunc, inArg::Argument)::Tuple{Argument, List}
              local outArg::Argument
              local outEEquations::Lst

              (outEEquations, outArg) = List.map1Fold(inEEquations, traverseEEquationExps, traverser, inArg)
          (outArg, outEEquations)
        end

         #= Traverses an EEquation, calling the given function on each Absyn.Exp it
          encounters. This funcion is intended to be used together with
          traverseEEquations, and does NOT descend into sub-EEquations. =#
        function traverseEEquationExps(inEEquation::EEquation, inFunc::TraverseFunc, inArg::Argument)::Tuple{Argument, EEquation}
              local outArg::Argument
              local outEEquation::EEquation

              (outEEquation, outArg) = begin
                  local traverser::TraverseFunc
                  local arg::Argument
                  local tup::Tuple
                  local e1::Absyn.Exp
                  local e2::Absyn.Exp
                  local e3::Absyn.Exp
                  local expl1::Lst
                  local then_branch::Lst
                  local else_branch::Lst
                  local eql::Lst
                  local else_when::Lst
                  local comment::Comment
                  local info::SourceInfo
                  local cr1::Absyn.ComponentRef
                  local cr2::Absyn.ComponentRef
                  local domain::Absyn.ComponentRef
                  local index::Ident
                @match (inEEquation, inFunc, inArg) begin
                  (EQ_IF(expl1, then_branch, else_branch, comment, info), traverser, arg)  => begin
                      (expl1, arg) = AbsynUtil.traverseExpList(expl1, traverser, arg)
                    (EQ_IF(expl1, then_branch, else_branch, comment, info), arg)
                  end
                  
                  (EQ_EQUALS(e1, e2, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                      (e2, arg) = traverser(e2, arg)
                    (EQ_EQUALS(e1, e2, comment, info), arg)
                  end
                  
                  (EQ_PDE(e1, e2, domain, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                      (e2, arg) = traverser(e2, arg)
                    (EQ_PDE(e1, e2, domain, comment, info), arg)
                  end
                  
                  (EQ_CONNECT(cr1, cr2, comment, info), _, _)  => begin
                      (cr1, arg) = traverseComponentRefExps(cr1, inFunc, inArg)
                      (cr2, arg) = traverseComponentRefExps(cr2, inFunc, arg)
                    (EQ_CONNECT(cr1, cr2, comment, info), arg)
                  end
                  
                  (EQ_FOR(index, SOME(e1), eql, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                    (EQ_FOR(index, SOME(e1), eql, comment, info), arg)
                  end
                  
                  (EQ_WHEN(e1, eql, else_when, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                      (else_when, arg) = List.map1Fold(else_when, traverseElseWhenExps, traverser, arg)
                    (EQ_WHEN(e1, eql, else_when, comment, info), arg)
                  end
                  
                  (EQ_ASSERT(e1, e2, e3, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                      (e2, arg) = traverser(e2, arg)
                      (e3, arg) = traverser(e3, arg)
                    (EQ_ASSERT(e1, e2, e3, comment, info), arg)
                  end
                  
                  (EQ_TERMINATE(e1, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                    (EQ_TERMINATE(e1, comment, info), arg)
                  end
                  
                  (EQ_REINIT(e1, e2, comment, info), traverser, _)  => begin
                      (e1, arg) = traverser(e1, inArg)
                      (e2, arg) = traverser(e2, arg)
                    (EQ_REINIT(e1, e2, comment, info), arg)
                  end
                  
                  (EQ_NORETCALL(e1, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                    (EQ_NORETCALL(e1, comment, info), arg)
                  end
                  
                  _  => begin
                      (inEEquation, inArg)
                  end
                end
              end
          (outArg, outEEquation)
        end

         #= Traverses the subscripts of a component reference and calls the given
          function on the subscript expressions. =#
        function traverseComponentRefExps(inCref::Absyn.ComponentRef, inFunc::TraverseFunc, inArg::Argument)::Tuple{Argument, Absyn.ComponentRef}
              local outArg::Argument
              local outCref::Absyn.ComponentRef

              (outCref, outArg) = begin
                  local name::Absyn.Ident
                  local subs::Lst
                  local cr::Absyn.ComponentRef
                  local arg::Argument
                @match (inCref, inFunc, inArg) begin
                  (Absyn.CREF_FULLYQUALIFIED(componentRef = cr), _, _)  => begin
                      (cr, arg) = traverseComponentRefExps(cr, inFunc, inArg)
                    (AbsynUtil.crefMakeFullyQualified(cr), arg)
                  end
                  
                  (Absyn.CREF_QUAL(name = name, subscripts = subs, componentRef = cr), _, _)  => begin
                      (cr, arg) = traverseComponentRefExps(cr, inFunc, inArg)
                      (subs, arg) = List.map1Fold(subs, traverseSubscriptExps, inFunc, arg)
                    (Absyn.CREF_QUAL(name, subs, cr), arg)
                  end
                  
                  (Absyn.CREF_IDENT(name = name, subscripts = subs), _, _)  => begin
                      (subs, arg) = List.map1Fold(subs, traverseSubscriptExps, inFunc, inArg)
                    (Absyn.CREF_IDENT(name, subs), arg)
                  end
                  
                  (Absyn.WILD(), _, _)  => begin
                    (inCref, inArg)
                  end
                end
              end
          (outArg, outCref)
        end

         #= Calls the given function on the subscript expression. =#
        function traverseSubscriptExps(inSubscript::Absyn.Subscript, inFunc::TraverseFunc, inArg::Argument)::Tuple{Argument, Absyn.Subscript}
              local outArg::Argument
              local outSubscript::Absyn.Subscript

              (outSubscript, outArg) = begin
                  local sub_exp::Absyn.Exp
                  local traverser::TraverseFunc
                  local arg::Argument
                @match (inSubscript, inFunc, inArg) begin
                  (Absyn.SUBSCRIPT(subscript = sub_exp), traverser, arg)  => begin
                      (sub_exp, arg) = traverser(sub_exp, arg)
                    (Absyn.SUBSCRIPT(sub_exp), arg)
                  end
                  
                  (Absyn.NOSUB(), _, _)  => begin
                    (inSubscript, inArg)
                  end
                end
              end
          (outArg, outSubscript)
        end

         #= Traverses the expressions in an else when branch, and calls the given
          function on the expressions. =#
        function traverseElseWhenExps(inElseWhen::Tuple, traverser::TraverseFunc, inArg::Argument)::Tuple{Argument, Tuple}
              local outArg::Argument
              local outElseWhen::Tuple

              local exp::Absyn.Exp
              local eql::Lst

              (exp, eql) = inElseWhen
              (exp, outArg) = traverser(exp, inArg)
              outElseWhen = (exp, eql)
          (outArg, outElseWhen)
        end

         #= Calls the given function on the value expression associated with a named
          function argument. =#
        function traverseNamedArgExps(inArg::Absyn.NamedArg, inTuple::Tuple)::Tuple{Tuple, Absyn.NamedArg}
              local outTuple::Tuple
              local outArg::Absyn.NamedArg

              local traverser::TraverseFunc
              local arg::Argument
              local name::Absyn.Ident
              local value::Absyn.Exp

              (traverser, arg) = inTuple
              Absyn.NAMEDARG(argName = name, argValue = value) = inArg
              (value, arg) = traverser(value, arg)
              outArg = Absyn.NAMEDARG(name, value)
              outTuple = (traverser, arg)
          (outTuple, outArg)
        end

         #= Calls the given function on the expression associated with a for iterator. =#
        function traverseForIteratorExps(inIterator::Absyn.ForIterator, inFunc::TraverseFunc, inArg::Argument)::Tuple{Argument, Absyn.ForIterator}
              local outArg::Argument
              local outIterator::Absyn.ForIterator

              (outIterator, outArg) = begin
                  local traverser::TraverseFunc
                  local arg::Argument
                  local ident::Absyn.Ident
                  local guardExp::Absyn.Exp
                  local range::Absyn.Exp
                @match (inIterator, inFunc, inArg) begin
                  (Absyn.ITERATOR(ident, NONE(), NONE()), _, arg)  => begin
                    (Absyn.ITERATOR(ident, NONE(), NONE()), arg)
                  end
                  
                  (Absyn.ITERATOR(ident, NONE(), SOME(range)), traverser, arg)  => begin
                      (range, arg) = traverser(range, arg)
                    (Absyn.ITERATOR(ident, NONE(), SOME(range)), arg)
                  end
                  
                  (Absyn.ITERATOR(ident, SOME(guardExp), SOME(range)), traverser, arg)  => begin
                      (guardExp, arg) = traverser(guardExp, arg)
                      (range, arg) = traverser(range, arg)
                    (Absyn.ITERATOR(ident, SOME(guardExp), SOME(range)), arg)
                  end
                  
                  (Absyn.ITERATOR(ident, SOME(guardExp), NONE()), traverser, arg)  => begin
                      (guardExp, arg) = traverser(guardExp, arg)
                    (Absyn.ITERATOR(ident, SOME(guardExp), NONE()), arg)
                  end
                end
              end
          (outArg, outIterator)
        end

         #= Calls traverseStatement on each statement in the given list. =#
        function traverseStatementsList(inStatements::Lst, inTuple::Tuple)::Tuple{Tuple, List}
              local outTuple::Tuple
              local outStatements::Lst

              (outStatements, outTuple) = List.mapFold(inStatements, traverseStatements, inTuple)
          (outTuple, outStatements)
        end

         #= Traverses all statements in the given statement in a top-down approach where
          the given function is applied to each statement found, beginning with the given
          statement. =#
        function traverseStatements(inStatement::Statement, inTuple::Tuple)::Tuple{Tuple, Statement}
              local outTuple::Tuple
              local outStatement::Statement

              local traverser::TraverseFunc
              local arg::Argument
              local stmt::Statement

              (traverser, arg) = inTuple
              (stmt, arg) = traverser((inStatement, arg))
              (outStatement, outTuple) = traverseStatements2(stmt, (traverser, arg))
          (outTuple, outStatement)
        end

         #= Helper function to traverseStatements. Goes through each statement contained
          in the given statement and calls traverseStatements on them. =#
        function traverseStatements2(inStatement::Statement, inTuple::Tuple)::Tuple{Tuple, Statement}
              local outTuple::Tuple
              local outStatement::Statement

              (outStatement, outTuple) = begin
                  local traverser::TraverseFunc
                  local arg::Argument
                  local tup::Tuple
                  local e::Absyn.Exp
                  local stmts1::Lst
                  local stmts2::Lst
                  local branches::Lst
                  local comment::Comment
                  local info::SourceInfo
                  local iter::String
                  local range::Option
                @match (inStatement, inTuple) begin
                  (ALG_IF(e, stmts1, branches, stmts2, comment, info), tup)  => begin
                      (stmts1, tup) = traverseStatementsList(stmts1, tup)
                      (branches, tup) = List.mapFold(branches, traverseBranchStatements, tup)
                      (stmts2, tup) = traverseStatementsList(stmts2, tup)
                    (ALG_IF(e, stmts1, branches, stmts2, comment, info), tup)
                  end
                  
                  (ALG_FOR(iter, range, stmts1, comment, info), tup)  => begin
                      (stmts1, tup) = traverseStatementsList(stmts1, tup)
                    (ALG_FOR(iter, range, stmts1, comment, info), tup)
                  end
                  
                  (ALG_PARFOR(iter, range, stmts1, comment, info), tup)  => begin
                      (stmts1, tup) = traverseStatementsList(stmts1, tup)
                    (ALG_PARFOR(iter, range, stmts1, comment, info), tup)
                  end
                  
                  (ALG_WHILE(e, stmts1, comment, info), tup)  => begin
                      (stmts1, tup) = traverseStatementsList(stmts1, tup)
                    (ALG_WHILE(e, stmts1, comment, info), tup)
                  end
                  
                  (ALG_WHEN_A(branches, comment, info), tup)  => begin
                      (branches, tup) = List.mapFold(branches, traverseBranchStatements, tup)
                    (ALG_WHEN_A(branches, comment, info), tup)
                  end
                  
                  (ALG_FAILURE(stmts1, comment, info), tup)  => begin
                      (stmts1, tup) = traverseStatementsList(stmts1, tup)
                    (ALG_FAILURE(stmts1, comment, info), tup)
                  end
                  
                  _  => begin
                      (inStatement, inTuple)
                  end
                end
              end
          (outTuple, outStatement)
        end

         #= Helper function to traverseStatements2. Calls traverseStatement each
          statement in a given branch. =#
        function traverseBranchStatements(inBranch::Tuple, inTuple::Tuple)::Tuple{Tuple, Tuple}
              local outTuple::Tuple
              local outBranch::Tuple

              local exp::Absyn.Exp
              local stmts::Lst

              (exp, stmts) = inBranch
              (stmts, outTuple) = traverseStatementsList(stmts, inTuple)
              outBranch = (exp, stmts)
          (outTuple, outBranch)
        end

         #= Traverses a list of statements and calls the given function on each
          expression found. =#
        function traverseStatementListExps(inStatements::Lst, inFunc::TraverseFunc, inArg::Argument)::Tuple{Argument, List}
              local outArg::Argument
              local outStatements::Lst

              (outStatements, outArg) = List.map1Fold(inStatements, traverseStatementExps, inFunc, inArg)
          (outArg, outStatements)
        end

         #= Applies the given function to each expression in the given statement. This
          function is intended to be used together with traverseStatements, and does NOT
          descend into sub-statements. =#
        function traverseStatementExps(inStatement::Statement, inFunc::TraverseFunc, inArg::Argument)::Tuple{Argument, Statement}
              local outArg::Argument
              local outStatement::Statement

              (outStatement, outArg) = begin
                  local traverser::TraverseFunc
                  local arg::Argument
                  local tup::Tuple
                  local iterator::String
                  local e1::Absyn.Exp
                  local e2::Absyn.Exp
                  local e3::Absyn.Exp
                  local stmts1::Lst
                  local stmts2::Lst
                  local branches::Lst
                  local comment::Comment
                  local info::SourceInfo
                  local cref::Absyn.ComponentRef
                @match (inStatement, inFunc, inArg) begin
                  (ALG_ASSIGN(e1, e2, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                      (e2, arg) = traverser(e2, arg)
                    (ALG_ASSIGN(e1, e2, comment, info), arg)
                  end
                  
                  (ALG_IF(e1, stmts1, branches, stmts2, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                      (branches, arg) = List.map1Fold(branches, traverseBranchExps, traverser, arg)
                    (ALG_IF(e1, stmts1, branches, stmts2, comment, info), arg)
                  end
                  
                  (ALG_FOR(iterator, SOME(e1), stmts1, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                    (ALG_FOR(iterator, SOME(e1), stmts1, comment, info), arg)
                  end
                  
                  (ALG_PARFOR(iterator, SOME(e1), stmts1, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                    (ALG_PARFOR(iterator, SOME(e1), stmts1, comment, info), arg)
                  end
                  
                  (ALG_WHILE(e1, stmts1, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                    (ALG_WHILE(e1, stmts1, comment, info), arg)
                  end
                  
                  (ALG_WHEN_A(branches, comment, info), traverser, arg)  => begin
                      (branches, arg) = List.map1Fold(branches, traverseBranchExps, traverser, arg)
                    (ALG_WHEN_A(branches, comment, info), arg)
                  end
                  
                  (ALG_ASSERT(), traverser, arg)  => begin
                      (e1, arg) = traverser(inStatement.condition, arg)
                      (e2, arg) = traverser(inStatement.message, arg)
                      (e3, arg) = traverser(inStatement.level, arg)
                    (ALG_ASSERT(e1, e2, e3, inStatement.comment, inStatement.info), arg)
                  end
                  
                  (ALG_TERMINATE(), traverser, arg)  => begin
                      (e1, arg) = traverser(inStatement.message, arg)
                    (ALG_TERMINATE(e1, inStatement.comment, inStatement.info), arg)
                  end
                  
                  (ALG_REINIT(), traverser, arg)  => begin
                      (e1, arg) = traverser(inStatement.cref, arg)
                      (e2, arg) = traverser(inStatement.newValue, arg)
                    (ALG_REINIT(e1, e2, inStatement.comment, inStatement.info), arg)
                  end
                  
                  (ALG_NORETCALL(e1, comment, info), traverser, arg)  => begin
                      (e1, arg) = traverser(e1, arg)
                    (ALG_NORETCALL(e1, comment, info), arg)
                  end
                  
                  _  => begin
                      (inStatement, inArg)
                  end
                end
              end
          (outArg, outStatement)
        end

         #= Calls the given function on each expression found in an if or when branch. =#
        function traverseBranchExps(inBranch::Tuple, traverser::TraverseFunc, inArg::Argument)::Tuple{Argument, Tuple}
              local outArg::Argument
              local outBranch::Tuple

              local arg::Argument
              local exp::Absyn.Exp
              local stmts::Lst

              (exp, stmts) = inBranch
              (exp, outArg) = traverser(exp, inArg)
              outBranch = (exp, stmts)
          (outArg, outBranch)
        end

        function elementIsClass(el::Element)::Bool
              local b::Bool

              b = begin
                @match el begin
                  CLASS()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          b
        end

        function elementIsImport(inElement::Element)::Bool
              local outIsImport::Bool

              outIsImport = begin
                @match inElement begin
                  IMPORT()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outIsImport
        end

        function elementIsPublicImport(el::Element)::Bool
              local b::Bool

              b = begin
                @match el begin
                  IMPORT(visibility = PUBLIC())  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          b
        end

        function elementIsProtectedImport(el::Element)::Bool
              local b::Bool

              b = begin
                @match el begin
                  IMPORT(visibility = PROTECTED())  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          b
        end

        function getElementClass(el::Element)::Element
              local cl::Element

              cl = begin
                @match el begin
                  CLASS()  => begin
                    el
                  end
                  
                  _  => begin
                      fail()
                  end
                end
              end
          cl
        end

         knownExternalCFunctions = list("sin", "cos", "tan", "asin", "acos", "atan", "atan2", "sinh", "cosh", "tanh", "exp", "log", "log10", "sqrt")::Lst

        function isBuiltinFunction(cl::Element, inVars::Lst, outVars::Lst)::String
              local name::String

              name = begin
                  local outVar1::String
                  local outVar2::String
                  local argsStr::Lst
                  local args::Lst
                @match (cl, inVars, outVars) begin
                  (CLASS(name = name, restriction = R_FUNCTION(FR_EXTERNAL_FUNCTION()), classDef = PARTS(externalDecl = SOME(EXTERNALDECL(funcName = NONE(), lang = SOME("builtin"))))), _, _)  => begin
                    name
                  end
                  
                  (CLASS(restriction = R_FUNCTION(FR_EXTERNAL_FUNCTION()), classDef = PARTS(externalDecl = SOME(EXTERNALDECL(funcName = SOME(name), lang = SOME("builtin"))))), _, _)  => begin
                    name
                  end

                  (CLASS(name = name, restriction = R_FUNCTION(FR_PARALLEL_FUNCTION()), classDef = PARTS(externalDecl = SOME(EXTERNALDECL(funcName = NONE(), lang = SOME("builtin"))))), _, _)  => begin
                    name
                  end

                  (CLASS(restriction = R_FUNCTION(FR_PARALLEL_FUNCTION()), classDef = PARTS(externalDecl = SOME(EXTERNALDECL(funcName = SOME(name), lang = SOME("builtin"))))), _, _)  => begin
                    name
                  end

                  (CLASS(restriction = R_FUNCTION(FR_EXTERNAL_FUNCTION()), classDef = PARTS(externalDecl = SOME(EXTERNALDECL(funcName = SOME(name), lang = SOME("C"), output_ = SOME(Absyn.CREF_IDENT(outVar2,  nil())), args = args)))), _, outVar1 <|  nil())  => begin
                      @assert true == (listMember(name, knownExternalCFunctions))
                      @assert true == (outVar2 == outVar1)
                      argsStr = List.mapMap(args, AbsynUtil.expCref, AbsynUtil.crefIdent)
                      equality(argsStr, inVars)
                    name
                  end
                  
                  (CLASS(name = name, restriction = R_FUNCTION(FR_EXTERNAL_FUNCTION()), classDef = PARTS(externalDecl = SOME(EXTERNALDECL(funcName = NONE(), lang = SOME("C"))))), _, _)  => begin
                      @assert true == (listMember(name, knownExternalCFunctions))
                    name
                  end
                end
              end
          name
        end

         #= Extracts the SourceInfo from an EEquation. =#
        function getEEquationInfo(inEEquation::EEquation)::SourceInfo
              local outInfo::SourceInfo

              outInfo = begin
                  local info::SourceInfo
                @match inEEquation begin
                  EQ_IF(info = info)  => begin
                    info
                  end
                  
                  EQ_EQUALS(info = info)  => begin
                    info
                  end

                  EQ_PDE(info = info)  => begin
                    info
                  end

                  EQ_CONNECT(info = info)  => begin
                    info
                  end

                  EQ_FOR(info = info)  => begin
                    info
                  end

                  EQ_WHEN(info = info)  => begin
                    info
                  end

                  EQ_ASSERT(info = info)  => begin
                    info
                  end

                  EQ_TERMINATE(info = info)  => begin
                    info
                  end

                  EQ_REINIT(info = info)  => begin
                    info
                  end

                  EQ_NORETCALL(info = info)  => begin
                    info
                  end
                end
              end
          outInfo
        end

         #= Extracts the SourceInfo from a Statement. =#
        function getStatementInfo(inStatement::Statement)::SourceInfo
              local outInfo::SourceInfo

              outInfo = begin
                @match inStatement begin
                  ALG_ASSIGN()  => begin
                    inStatement.info
                  end
                  
                  ALG_IF()  => begin
                    inStatement.info
                  end

                  ALG_FOR()  => begin
                    inStatement.info
                  end

                  ALG_PARFOR()  => begin
                    inStatement.info
                  end

                  ALG_WHILE()  => begin
                    inStatement.info
                  end

                  ALG_WHEN_A()  => begin
                    inStatement.info
                  end

                  ALG_ASSERT()  => begin
                    inStatement.info
                  end

                  ALG_TERMINATE()  => begin
                    inStatement.info
                  end

                  ALG_REINIT()  => begin
                    inStatement.info
                  end

                  ALG_NORETCALL()  => begin
                    inStatement.info
                  end

                  ALG_RETURN()  => begin
                    inStatement.info
                  end

                  ALG_BREAK()  => begin
                    inStatement.info
                  end

                  ALG_FAILURE()  => begin
                    inStatement.info
                  end

                  ALG_TRY()  => begin
                    inStatement.info
                  end

                  ALG_CONTINUE()  => begin
                    inStatement.info
                  end

                  _  => begin
                    println("Error error..")
                      AbsynUtil.dummyInfo
                  end
                end
              end
          outInfo
        end

         #= Adds a given element to a class definition. Only implemented for PARTS. =#
        function addElementToClass(inElement::Element, inClassDef::Element)::Element
              local outClassDef::Element

              local cdef::ClassDef

              CLASS(classDef = cdef) = inClassDef
              cdef = addElementToCompositeClassDef(inElement, cdef)
              outClassDef = setElementClassDefinition(cdef, inClassDef)
          outClassDef
        end

         #= Adds a given element to a PARTS class definition. =#
        function addElementToCompositeClassDef(inElement::Element, inClassDef::ClassDef)::ClassDef
              local outClassDef::ClassDef

              local el::Lst
              local nel::Lst
              local iel::Lst
              local nal::Lst
              local ial::Lst
              local nco::Lst
              local ed::Option
              local clsattrs::Lst

              PARTS(el, nel, iel, nal, ial, nco, clsattrs, ed) = inClassDef
              outClassDef = PARTS(inElement <| el, nel, iel, nal, ial, nco, clsattrs, ed)
          outClassDef
        end

        function setElementClassDefinition(inClassDef::ClassDef, inElement::Element)::Element
              local outElement::Element

              local n::Ident
              local pf::Prefixes
              local pp::Partial
              local ep::Encapsulated
              local r::Restriction
              local i::SourceInfo
              local cmt::Comment

              CLASS(n, pf, ep, pp, r, _, cmt, i) = inElement
              outElement = CLASS(n, pf, ep, pp, r, inClassDef, cmt, i)
          outElement
        end

         #= returns true for PUBLIC and false for PROTECTED =#
        function visibilityBool(inVisibility::Visibility)::Bool
              local bVisibility::Bool

              bVisibility = begin
                @match inVisibility begin
                  PUBLIC()  => begin
                    true
                  end
                  
                  PROTECTED()  => begin
                    false
                  end
                end
              end
          bVisibility
        end

         #= returns for PUBLIC true and for PROTECTED false =#
        function boolVisibility(inBoolVisibility::Bool)::Visibility
              local outVisibility::Visibility

              outVisibility = begin
                @match inBoolVisibility begin
                  true  => begin
                    PUBLIC()
                  end
                  
                  false  => begin
                    PROTECTED()
                  end
                end
              end
          outVisibility
        end

        function visibilityEqual(inVisibility1::Visibility, inVisibility2::Visibility)::Bool
              local outEqual::Bool

              outEqual = begin
                @match (inVisibility1, inVisibility2) begin
                  (PUBLIC(), PUBLIC())  => begin
                    true
                  end
                  
                  (PROTECTED(), PROTECTED())  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          outEqual
        end

        function eachBool(inEach::Each)::Bool
              local bEach::Bool

              bEach = begin
                @match inEach begin
                  EACH()  => begin
                    true
                  end
                  
                  NOT_EACH()  => begin
                    false
                  end
                end
              end
          bEach
        end

        function boolEach(inBoolEach::Bool)::Each
              local outEach::Each

              outEach = begin
                @match inBoolEach begin
                  true  => begin
                    EACH()
                  end
                  
                  false  => begin
                    NOT_EACH()
                  end
                end
              end
          outEach
        end

        function prefixesRedeclare(inPrefixes::Prefixes)::Redeclare
              local outRedeclare::Redeclare

              PREFIXES(redeclarePrefix = outRedeclare) = inPrefixes
          outRedeclare
        end

        function prefixesSetRedeclare(inPrefixes::Prefixes, inRedeclare::Redeclare)::Prefixes
              local outPrefixes::Prefixes

              local v::Visibility
              local f::Final
              local io::Absyn.InnerOuter
              local rp::Replaceable

              PREFIXES(v, _, f, io, rp) = inPrefixes
              outPrefixes = PREFIXES(v, inRedeclare, f, io, rp)
          outPrefixes
        end

        function prefixesSetReplaceable(inPrefixes::Prefixes, inReplaceable::Replaceable)::Prefixes
              local outPrefixes::Prefixes

              local v::Visibility
              local f::Final
              local io::Absyn.InnerOuter
              local rd::Redeclare

              PREFIXES(v, rd, f, io, _) = inPrefixes
              outPrefixes = PREFIXES(v, rd, f, io, inReplaceable)
          outPrefixes
        end

        function redeclareBool(inRedeclare::Redeclare)::Bool
              local bRedeclare::Bool

              bRedeclare = begin
                @match inRedeclare begin
                  REDECLARE()  => begin
                    true
                  end
                  
                  NOT_REDECLARE()  => begin
                    false
                  end
                end
              end
          bRedeclare
        end

        function boolRedeclare(inBoolRedeclare::Bool)::Redeclare
              local outRedeclare::Redeclare

              outRedeclare = begin
                @match inBoolRedeclare begin
                  true  => begin
                    REDECLARE()
                  end
                  
                  false  => begin
                    NOT_REDECLARE()
                  end
                end
              end
          outRedeclare
        end

        function replaceableBool(inReplaceable::Replaceable)::Bool
              local bReplaceable::Bool

              bReplaceable = begin
                @match inReplaceable begin
                  REPLACEABLE()  => begin
                    true
                  end
                  
                  NOT_REPLACEABLE()  => begin
                    false
                  end
                end
              end
          bReplaceable
        end

        function replaceableOptConstraint(inReplaceable::Replaceable)::Option
              local outOptConstrainClass::Option

              outOptConstrainClass = begin
                  local cc::Option
                @match inReplaceable begin
                  REPLACEABLE(cc)  => begin
                    cc
                  end
                  
                  NOT_REPLACEABLE()  => begin
                    NONE()
                  end
                end
              end
          outOptConstrainClass
        end

        function boolReplaceable(inBoolReplaceable::Bool, inOptConstrainClass::Option)::Replaceable
              local outReplaceable::Replaceable

              outReplaceable = begin
                @match (inBoolReplaceable, inOptConstrainClass) begin
                  (true, _)  => begin
                    REPLACEABLE(inOptConstrainClass)
                  end
                  
                  (false, SOME(_))  => begin
                      print("Ignoring constraint class because replaceable prefix is not present!\n")
                    NOT_REPLACEABLE()
                  end
                  
                  (false, _)  => begin
                    NOT_REPLACEABLE()
                  end
                end
              end
          outReplaceable
        end

        function encapsulatedBool(inEncapsulated::Encapsulated)::Bool
              local bEncapsulated::Bool

              bEncapsulated = begin
                @match inEncapsulated begin
                  ENCAPSULATED()  => begin
                    true
                  end
                  
                  NOT_ENCAPSULATED()  => begin
                    false
                  end
                end
              end
          bEncapsulated
        end

        function boolEncapsulated(inBoolEncapsulated::Bool)::Encapsulated
              local outEncapsulated::Encapsulated

              outEncapsulated = begin
                @match inBoolEncapsulated begin
                  true  => begin
                    ENCAPSULATED()
                  end
                  
                  false  => begin
                    NOT_ENCAPSULATED()
                  end
                end
              end
          outEncapsulated
        end

        function partialBool(inPartial::Partial)::Bool
              local bPartial::Bool

              bPartial = begin
                @match inPartial begin
                  PARTIAL()  => begin
                    true
                  end
                  
                  NOT_PARTIAL()  => begin
                    false
                  end
                end
              end
          bPartial
        end

        function boolPartial(inBoolPartial::Bool)::Partial
              local outPartial::Partial

              outPartial = begin
                @match inBoolPartial begin
                  true  => begin
                    PARTIAL()
                  end
                  
                  false  => begin
                    NOT_PARTIAL()
                  end
                end
              end
          outPartial
        end

        function prefixesFinal(inPrefixes::Prefixes)::Final
              local outFinal::Final

              PREFIXES(finalPrefix = outFinal) = inPrefixes
          outFinal
        end

        function finalBool(inFinal::Final)::Bool
              local bFinal::Bool

              bFinal = begin
                @match inFinal begin
                  FINAL()  => begin
                    true
                  end
                  
                  NOT_FINAL()  => begin
                    false
                  end
                end
              end
          bFinal
        end

        function finalEqual(inFinal1::Final, inFinal2::Final)::Bool
              local bFinal::Bool

              bFinal = begin
                @match (inFinal1, inFinal2) begin
                  (FINAL(), FINAL())  => begin
                    true
                  end
                  
                  (NOT_FINAL(), NOT_FINAL())  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          bFinal
        end

        function boolFinal(inBoolFinal::Bool)::Final
              local outFinal::Final

              outFinal = begin
                @match inBoolFinal begin
                  true  => begin
                    FINAL()
                  end
                  
                  false  => begin
                    NOT_FINAL()
                  end
                end
              end
          outFinal
        end

        function connectorTypeEqual(inConnectorType1::ConnectorType, inConnectorType2::ConnectorType)::Bool
              local outEqual::Bool

              outEqual = begin
                @match (inConnectorType1, inConnectorType2) begin
                  (POTENTIAL(), POTENTIAL())  => begin
                    true
                  end
                  
                  (FLOW(), FLOW())  => begin
                    true
                  end

                  (STREAM(), STREAM())  => begin
                    true
                  end
                end
              end
          outEqual
        end

        function potentialBool(inConnectorType::ConnectorType)::Bool
              local outPotential::Bool

              outPotential = begin
                @match inConnectorType begin
                  POTENTIAL()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outPotential
        end

        function flowBool(inConnectorType::ConnectorType)::Bool
              local outFlow::Bool

              outFlow = begin
                @match inConnectorType begin
                  FLOW()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outFlow
        end

        function boolFlow(inBoolFlow::Bool)::ConnectorType
              local outFlow::ConnectorType

              outFlow = begin
                @match inBoolFlow begin
                  true  => begin
                    FLOW()
                  end
                  
                  _  => begin
                      POTENTIAL()
                  end
                end
              end
          outFlow
        end

        function streamBool(inStream::ConnectorType)::Bool
              local bStream::Bool

              bStream = begin
                @match inStream begin
                  STREAM()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          bStream
        end

        function boolStream(inBoolStream::Bool)::ConnectorType
              local outStream::ConnectorType

              outStream = begin
                @match inBoolStream begin
                  true  => begin
                    STREAM()
                  end
                  
                  _  => begin
                      POTENTIAL()
                  end
                end
              end
          outStream
        end

        function mergeAttributesFromClass(inAttributes::Attributes, inClass::Element)::Attributes
              local outAttributes::Attributes

              outAttributes = begin
                  local cls_attr::Attributes
                  local attr::Attributes
                @match (inAttributes, inClass) begin
                  (_, CLASS(classDef = DERIVED(attributes = cls_attr)))  => begin
                      SOME(attr) = mergeAttributes(inAttributes, SOME(cls_attr))
                    attr
                  end
                  
                  _  => begin
                      inAttributes
                  end
                end
              end
          outAttributes
        end

         #= @author: adrpo
         Function that is used with Derived classes,
         merge the derived Attributes with the optional Attributes returned from ~instClass~. =#
        function mergeAttributes(ele::Attributes, oEle::Option)::Option
              local outoEle::Option

              outoEle = begin
                  local p1::Parallelism
                  local p2::Parallelism
                  local p::Parallelism
                  local v1::Variability
                  local v2::Variability
                  local v::Variability
                  local d1::Absyn.Direction
                  local d2::Absyn.Direction
                  local d::Absyn.Direction
                  local isf1::Absyn.IsField
                  local isf2::Absyn.IsField
                  local isf::Absyn.IsField
                  local ad1::Absyn.ArrayDim
                  local ad2::Absyn.ArrayDim
                  local ad::Absyn.ArrayDim
                  local ct1::ConnectorType
                  local ct2::ConnectorType
                  local ct::ConnectorType
                @match (ele, oEle) begin
                  (_, NONE())  => begin
                    SOME(ele)
                  end
                  
                  (ATTR(ad1, ct1, p1, v1, d1, isf1), SOME(ATTR(_, ct2, p2, v2, d2, isf2)))  => begin
                      ct = propagateConnectorType(ct1, ct2)
                      p = propagateParallelism(p1, p2)
                      v = propagateVariability(v1, v2)
                      d = propagateDirection(d1, d2)
                      isf = propagateIsField(isf1, isf2)
                      ad = ad1
                    SOME(ATTR(ad, ct, p, v, d, isf))
                  end
                end
              end
               #=  TODO! CHECK if ad1 == ad2!
               =#
          outoEle
        end

        function prefixesVisibility(inPrefixes::Prefixes)::Visibility
              local outVisibility::Visibility

              PREFIXES(visibility = outVisibility) = inPrefixes
          outVisibility
        end

        function prefixesSetVisibility(inPrefixes::Prefixes, inVisibility::Visibility)::Prefixes
              local outPrefixes::Prefixes

              local rd::Redeclare
              local f::Final
              local io::Absyn.InnerOuter
              local rp::Replaceable

              PREFIXES(_, rd, f, io, rp) = inPrefixes
              outPrefixes = PREFIXES(inVisibility, rd, f, io, rp)
          outPrefixes
        end

         #= Returns true if two each attributes are equal =#
        function eachEqual(each1::Each, each2::Each)::Bool
              local equal::Bool

              equal = begin
                @match (each1, each2) begin
                  (NOT_EACH(), NOT_EACH())  => begin
                    true
                  end
                  
                  (EACH(), EACH())  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          equal
        end

         #= Returns true if two replaceable attributes are equal =#
        function replaceableEqual(r1::Replaceable, r2::Replaceable)::Bool
              local equal::Bool

              equal = begin
                  local p1::Absyn.Path
                  local p2::Absyn.Path
                  local m1::Mod
                  local m2::Mod
                @matchcontinue (r1, r2) begin
                  (NOT_REPLACEABLE(), NOT_REPLACEABLE())  => begin
                    true
                  end
                  
                  (REPLACEABLE(SOME(CONSTRAINCLASS(constrainingClass = p1, modifier = m1))), REPLACEABLE(SOME(CONSTRAINCLASS(constrainingClass = p2, modifier = m2))))  => begin
                      @assert true == (AbsynUtil.pathEqual(p1, p2))
                      @assert true == (modEqual(m1, m2))
                    true
                  end
                  
                  (REPLACEABLE(NONE()), REPLACEABLE(NONE()))  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          equal
        end

         #= Returns true if two prefixes are equal =#
        function prefixesEqual(prefixes1::Prefixes, prefixes2::Prefixes)::Bool
              local equal::Bool

              equal = begin
                  local v1::Visibility
                  local v2::Visibility
                  local rd1::Redeclare
                  local rd2::Redeclare
                  local f1::Final
                  local f2::Final
                  local io1::Absyn.InnerOuter
                  local io2::Absyn.InnerOuter
                  local rpl1::Replaceable
                  local rpl2::Replaceable
                @matchcontinue (prefixes1, prefixes2) begin
                  (PREFIXES(v1, rd1, f1, io1, rpl1), PREFIXES(v2, rd2, f2, io2, rpl2))  => begin
                      @assert true == (valueEq(v1, v2))
                      @assert true == (valueEq(rd1, rd2))
                      @assert true == (valueEq(f1, f2))
                      @assert true == (AbsynUtil.innerOuterEqual(io1, io2))
                      @assert true == (replaceableEqual(rpl1, rpl2))
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          equal
        end

         #= Returns the replaceable part =#
        function prefixesReplaceable(prefixes::Prefixes)::Replaceable
              local repl::Replaceable

              PREFIXES(replaceablePrefix = repl) = prefixes
          repl
        end

        function elementPrefixes(inElement::Element)::Prefixes
              local outPrefixes::Prefixes

              outPrefixes = begin
                  local pf::Prefixes
                @match inElement begin
                  CLASS(prefixes = pf)  => begin
                    pf
                  end
                  
                  COMPONENT(prefixes = pf)  => begin
                    pf
                  end
                end
              end
          outPrefixes
        end

        function isElementReplaceable(inElement::Element)::Bool
              local isReplaceable::Bool

              local pf::Prefixes

              pf = elementPrefixes(inElement)
              isReplaceable = replaceableBool(prefixesReplaceable(pf))
          isReplaceable
        end

        function isElementRedeclare(inElement::Element)::Bool
              local isRedeclare::Bool

              local pf::Prefixes

              pf = elementPrefixes(inElement)
              isRedeclare = redeclareBool(prefixesRedeclare(pf))
          isRedeclare
        end

        function prefixesInnerOuter(inPrefixes::Prefixes)::Absyn.InnerOuter
              local outInnerOuter::Absyn.InnerOuter

              PREFIXES(innerOuter = outInnerOuter) = inPrefixes
          outInnerOuter
        end

        function prefixesSetInnerOuter(prefixes::Prefixes, innerOuter::Absyn.InnerOuter)::Prefixes


              prefixes.innerOuter = innerOuter
          prefixes
        end

        function removeAttributeDimensions(inAttributes::Attributes)::Attributes
              local outAttributes::Attributes

              local ct::ConnectorType
              local v::Variability
              local p::Parallelism
              local d::Absyn.Direction
              local isf::Absyn.IsField

              ATTR(_, ct, p, v, d, isf) = inAttributes
              outAttributes = ATTR(list(), ct, p, v, d, isf)
          outAttributes
        end

        function setAttributesDirection(attributes::Attributes, direction::Absyn.Direction)::Attributes


              attributes.direction = direction
          attributes
        end

         #= Return the variability attribute from Attributes =#
        function attrVariability(attr::Attributes)::Variability
              local var::Variability

              var = begin
                  local v::Variability
                @match attr begin
                  ATTR(variability = v)  => begin
                    v
                  end
                end
              end
          var
        end

        function setAttributesVariability(attributes::Attributes, variability::Variability)::Attributes


              attributes.variability = variability
          attributes
        end

        function isDerivedClassDef(inClassDef::ClassDef)::Bool
              local isDerived::Bool

              isDerived = begin
                @match inClassDef begin
                  DERIVED()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isDerived
        end

        function isConnector(inRestriction::Restriction)::Bool
              local isConnector::Bool

              isConnector = begin
                @match inRestriction begin
                  R_CONNECTOR()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isConnector
        end

        function removeBuiltinsFromTopScope(inProgram::Program)::Program
              local outProgram::Program

              outProgram = List.filterOnTrue(inProgram, isNotBuiltinClass)
          outProgram
        end

        function isNotBuiltinClass(inClass::Element)::Bool
              local b::Bool

              b = begin
                @match inClass begin
                  CLASS(classDef = PARTS(externalDecl = SOME(EXTERNALDECL(lang = SOME("builtin")))))  => begin
                    false
                  end
                  
                  _  => begin
                      true
                  end
                end
              end
          b
        end

         #= Returns the annotation with the given name in the element, or fails if no
           such annotation could be found. =#
        function getElementNamedAnnotation(element::Element, name::String)::Absyn.Exp
              local exp::Absyn.Exp

              local ann::Annotation

              ann = begin
                @match element begin
                  EXTENDS(ann = SOME(ann))  => begin
                    ann
                  end
                  
                  CLASS(cmt = COMMENT(annotation_ = SOME(ann)))  => begin
                    ann
                  end

                  COMPONENT(comment = COMMENT(annotation_ = SOME(ann)))  => begin
                    ann
                  end
                end
              end
              exp = getNamedAnnotation(ann, name)
          exp
        end

         #= Checks if the given annotation contains an entry with the given name with the
           value true. =#
        function getNamedAnnotation(inAnnotation::Annotation, inName::String)::Tuple{SourceInfo, Absyn.Exp}
              local info::SourceInfo
              local exp::Absyn.Exp

              local submods::Lst

              ANNOTATION(modification = MOD(subModLst = submods)) = inAnnotation
              NAMEMOD(mod = MOD(info = info, binding = SOME(exp))) = List.find1(submods, hasNamedAnnotation, inName)
          (info, exp)
        end

         #= Checks if a submod has the same name as the given name, and if its binding
           in that case is true. =#
        function hasNamedAnnotation(inSubMod::SubMod, inName::String)::Bool
              local outIsMatch::Bool

              outIsMatch = begin
                  local id::String
                @match (inSubMod, inName) begin
                  (NAMEMOD(ident = id, mod = MOD(binding = SOME(_))), _)  => begin
                    stringEq(id, inName)
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outIsMatch
        end

         #= Returns the modifier with the given name if it can be found in the
           annotation, otherwise an empty modifier. =#
        function lookupNamedAnnotation(ann::Annotation, name::String)::Mod
              local mod::Mod

              local submods::Lst
              local id::String

              mod = begin
                @match ann begin
                  Annotation.ANNOTATION(modification = Mod.MOD(subModLst = submods))  => begin
                      for sm in submods
                        SubMod.NAMEMOD(id, mod) = sm
                        if id == name
                          return 
                        end
                      end
                    Mod.NOMOD()
                  end
                  
                  _  => begin
                      Mod.NOMOD()
                  end
                end
              end
          mod
        end

         #= Returns a list of modifiers with the given name found in the annotation. =#
        function lookupNamedAnnotations(ann::Annotation, name::String)::Lst
              local mods::Lst = list()

              local submods::Lst
              local id::String
              local mod::Mod

              mods = begin
                @match ann begin
                  Annotation.ANNOTATION(modification = Mod.MOD(subModLst = submods))  => begin
                      for sm in submods
                        SubMod.NAMEMOD(id, mod) = sm
                        if id == name
                          mods = mod <| mods
                        end
                      end
                    mods
                  end
                  
                  _  => begin
                      list()
                  end
                end
              end
          mods
        end

        function hasBooleanNamedAnnotationInClass(inClass::Element, namedAnnotation::String)::Bool
              local hasAnn::Bool

              hasAnn = begin
                  local ann::Annotation
                @match (inClass, namedAnnotation) begin
                  (CLASS(cmt = COMMENT(annotation_ = SOME(ann))), _)  => begin
                    hasBooleanNamedAnnotation(ann, namedAnnotation)
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          hasAnn
        end

        function hasBooleanNamedAnnotationInComponent(inComponent::Element, namedAnnotation::String)::Bool
              local hasAnn::Bool

              hasAnn = begin
                  local ann::Annotation
                @match (inComponent, namedAnnotation) begin
                  (COMPONENT(comment = COMMENT(annotation_ = SOME(ann))), _)  => begin
                    hasBooleanNamedAnnotation(ann, namedAnnotation)
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          hasAnn
        end

         #= check if the named annotation is present and has value true =#
        function optCommentHasBooleanNamedAnnotation(comm::Option, annotationName::String)::Bool
              local outB::Bool

              outB = begin
                  local ann::Annotation
                @match (comm, annotationName) begin
                  (SOME(COMMENT(annotation_ = SOME(ann))), _)  => begin
                    hasBooleanNamedAnnotation(ann, annotationName)
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outB
        end

         #= check if the named annotation is present and has value true =#
        function commentHasBooleanNamedAnnotation(comm::Comment, annotationName::String)::Bool
              local outB::Bool

              outB = begin
                  local ann::Annotation
                @match (comm, annotationName) begin
                  (COMMENT(annotation_ = SOME(ann)), _)  => begin
                    hasBooleanNamedAnnotation(ann, annotationName)
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outB
        end

         #= Checks if the given annotation contains an entry with the given name with the
           value true. =#
        function hasBooleanNamedAnnotation(inAnnotation::Annotation, inName::String)::Bool
              local outHasEntry::Bool

              local submods::Lst

              ANNOTATION(modification = MOD(subModLst = submods)) = inAnnotation
              outHasEntry = List.exist1(submods, hasBooleanNamedAnnotation2, inName)
          outHasEntry
        end

         #= Checks if a submod has the same name as the given name, and if its binding
           in that case is true. =#
        function hasBooleanNamedAnnotation2(inSubMod::SubMod, inName::String)::Bool
              local outIsMatch::Bool

              outIsMatch = begin
                  local id::String
                @match inSubMod begin
                  NAMEMOD(ident = id, mod = MOD(binding = SOME(Absyn.BOOL(value = true))))  => begin
                    stringEq(id, inName)
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outIsMatch
        end

         #= @author: adrpo
         returns true if annotation(Evaluate = true) is present,
         otherwise false =#
        function getEvaluateAnnotation(inCommentOpt::Option)::Bool
              local evalIsTrue::Bool

              evalIsTrue = begin
                  local ann::Annotation
                @match inCommentOpt begin
                  SOME(COMMENT(annotation_ = SOME(ann)))  => begin
                    hasBooleanNamedAnnotation(ann, "Evaluate")
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          evalIsTrue
        end

        function getInlineTypeAnnotationFromCmt(inComment::Comment)::Option
              local outAnnotation::Option

              outAnnotation = begin
                  local ann::Annotation
                @match inComment begin
                  COMMENT(annotation_ = SOME(ann))  => begin
                    getInlineTypeAnnotation(ann)
                  end
                  
                  _  => begin
                      NONE()
                  end
                end
              end
          outAnnotation
        end

        function getInlineTypeAnnotation(inAnnotation::Annotation)::Option
              local outAnnotation::Option

              outAnnotation = begin
                  local submods::Lst
                  local inline_mod::SubMod
                  local fp::Final
                  local ep::Each
                  local info::SourceInfo
                @matchcontinue inAnnotation begin
                  ANNOTATION(MOD(fp, ep, submods, _, info))  => begin
                      inline_mod = List.find(submods, isInlineTypeSubMod)
                    SOME(ANNOTATION(MOD(fp, ep, list(inline_mod), NONE(), info)))
                  end
                  
                  _  => begin
                      NONE()
                  end
                end
              end
          outAnnotation
        end

        function isInlineTypeSubMod(inSubMod::SubMod)::Bool
              local outIsInlineType::Bool

              outIsInlineType = begin
                @match inSubMod begin
                  NAMEMOD(ident = "Inline")  => begin
                    true
                  end
                  
                  NAMEMOD(ident = "LateInline")  => begin
                    true
                  end

                  NAMEMOD(ident = "InlineAfterIndexReduction")  => begin
                    true
                  end
                end
              end
          outIsInlineType
        end

        function appendAnnotationToComment(inAnnotation::Annotation, inComment::Comment)::Comment
              local outComment::Comment

              outComment = begin
                  local cmt::Option
                  local fp::Final
                  local ep::Each
                  local mods1::Lst
                  local mods2::Lst
                  local b::Option
                  local info::SourceInfo
                @match (inAnnotation, inComment) begin
                  (_, COMMENT(NONE(), cmt))  => begin
                    COMMENT(SOME(inAnnotation), cmt)
                  end
                  
                  (ANNOTATION(modification = MOD(subModLst = mods1)), COMMENT(SOME(ANNOTATION(MOD(fp, ep, mods2, b, info))), cmt))  => begin
                      mods2 = listAppend(mods1, mods2)
                    COMMENT(SOME(ANNOTATION(MOD(fp, ep, mods2, b, info))), cmt)
                  end
                end
              end
          outComment
        end

        function getModifierInfo(inMod::Mod)::SourceInfo
              local outInfo::SourceInfo

              outInfo = begin
                  local info::SourceInfo
                  local el::Element
                @match inMod begin
                  MOD(info = info)  => begin
                    info
                  end
                  
                  REDECL(element = el)  => begin
                    elementInfo(el)
                  end

                  _  => begin
                      AbsynUtil.dummyInfo
                  end
                end
              end
          outInfo
        end

        function getModifierBinding(inMod::Mod)::Option
              local outBinding::Option

              outBinding = begin
                  local binding::Absyn.Exp
                @match inMod begin
                  MOD(binding = SOME(binding))  => begin
                    SOME(binding)
                  end
                  
                  _  => begin
                      NONE()
                  end
                end
              end
          outBinding
        end

        function getComponentCondition(element::Element)::Option
              local condition::Option

              condition = begin
                @match element begin
                  COMPONENT()  => begin
                    element.condition
                  end
                  
                  _  => begin
                      NONE()
                  end
                end
              end
          condition
        end

        function removeComponentCondition(inElement::Element)::Element
              local outElement::Element

              local name::Ident
              local pf::Prefixes
              local attr::Attributes
              local ty::Absyn.TypeSpec
              local mod::Mod
              local cmt::Comment
              local info::SourceInfo

              COMPONENT(name, pf, attr, ty, mod, cmt, _, info) = inElement
              outElement = COMPONENT(name, pf, attr, ty, mod, cmt, NONE(), info)
          outElement
        end

         #= Returns true if the given element is an element with the inner prefix,
           otherwise false. =#
        function isInnerComponent(inElement::Element)::Bool
              local outIsInner::Bool

              outIsInner = begin
                  local io::Absyn.InnerOuter
                @match inElement begin
                  COMPONENT(prefixes = PREFIXES(innerOuter = io))  => begin
                    AbsynUtil.isInner(io)
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outIsInner
        end

        function makeElementProtected(inElement::Element)::Element
              local outElement::Element

              outElement = begin
                  local name::Ident
                  local attr::Attributes
                  local ty::Absyn.TypeSpec
                  local mod::Mod
                  local cmt::Comment
                  local cnd::Option
                  local info::SourceInfo
                  local rdp::Redeclare
                  local fp::Final
                  local io::Absyn.InnerOuter
                  local rpp::Replaceable
                  local bc::Path
                  local ann::Option
                @match inElement begin
                  COMPONENT(prefixes = PREFIXES(visibility = PROTECTED()))  => begin
                    inElement
                  end
                  
                  COMPONENT(name, PREFIXES(_, rdp, fp, io, rpp), attr, ty, mod, cmt, cnd, info)  => begin
                    COMPONENT(name, PREFIXES(PROTECTED(), rdp, fp, io, rpp), attr, ty, mod, cmt, cnd, info)
                  end

                  EXTENDS(visibility = PROTECTED())  => begin
                    inElement
                  end

                  EXTENDS(bc, _, mod, ann, info)  => begin
                    EXTENDS(bc, PROTECTED(), mod, ann, info)
                  end

                  _  => begin
                      inElement
                  end
                end
              end
          outElement
        end

        function isElementPublic(inElement::Element)::Bool
              local outIsPublic::Bool

              outIsPublic = visibilityBool(prefixesVisibility(elementPrefixes(inElement)))
          outIsPublic
        end

        function isElementProtected(inElement::Element)::Bool
              local outIsProtected::Bool

              outIsProtected = ! visibilityBool(prefixesVisibility(elementPrefixes(inElement)))
          outIsProtected
        end

        function isElementEncapsulated(inElement::Element)::Bool
              local outIsEncapsulated::Bool

              outIsEncapsulated = begin
                @match inElement begin
                  CLASS(encapsulatedPrefix = ENCAPSULATED())  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outIsEncapsulated
        end

         #= replace the element in program at the specified path (includes the element name).
         if the element does not exist at that location then it fails.
         this function will fail if any of the path prefixes
         to the element are not found in the given program =#
        function replaceOrAddElementInProgram(inProgram::Program, inElement::Element, inClassPath::Absyn.Path)::Program
              local outProgram::Program

              outProgram = begin
                  local sp::Program
                  local c::Element
                  local e::Element
                  local p::Absyn.Path
                  local i::Absyn.Ident
                @match (inProgram, inElement, inClassPath) begin
                  (_, _, Absyn.QUALIFIED(i, p))  => begin
                      e = getElementWithId(inProgram, i)
                      sp = getElementsFromElement(inProgram, e)
                      sp = replaceOrAddElementInProgram(sp, inElement, p)
                      e = replaceElementsInElement(inProgram, e, sp)
                      sp = replaceOrAddElementWithId(inProgram, e, i)
                    sp
                  end
                  
                  (_, _, Absyn.IDENT(i))  => begin
                      sp = replaceOrAddElementWithId(inProgram, inElement, i)
                    sp
                  end
                  
                  (_, _, Absyn.FULLYQUALIFIED(p))  => begin
                      sp = replaceOrAddElementInProgram(inProgram, inElement, p)
                    sp
                  end
                end
              end
          outProgram
        end

         #= replace the class in program at the specified id.
         if the class does not exist at that location then is is added =#
        function replaceOrAddElementWithId(inProgram::Program, inElement::Element, inId::Ident)::Program
              local outProgram::Program

              outProgram = begin
                  local sp::Program
                  local rest::Program
                  local c::Element
                  local e::Element
                  local p::Absyn.Path
                  local i::Absyn.Ident
                  local n::Absyn.Ident
                @matchcontinue (inProgram, inElement, inId) begin
                  (CLASS(name = n) <| rest, _, i)  => begin
                      @assert true == (stringEq(n, i))
                    inElement <| rest
                  end
                  
                  (COMPONENT(name = n) <| rest, _, i)  => begin
                      @assert true == (stringEq(n, i))
                    inElement <| rest
                  end
                  
                  (EXTENDS(baseClassPath = p) <| rest, _, i)  => begin
                      @assert true == (stringEq(AbsynUtil.pathString(p), i))
                    inElement <| rest
                  end
                  
                  (e <| rest, _, i)  => begin
                      sp = replaceOrAddElementWithId(rest, inElement, i)
                    e <| sp
                  end
                  
                  ( nil(), _, _)  => begin
                      sp = list(inElement)
                    sp
                  end
                end
              end
               #=  not found, add it
               =#
          outProgram
        end

        function getElementsFromElement(inProgram::Program, inElement::Element)::Program
              local outProgram::Program

              outProgram = begin
                  local els::Program
                  local e::Element
                  local p::Absyn.Path
                  local i::Absyn.Ident
                   #=  a class with parts
                   =#
                @match (inProgram, inElement) begin
                  (_, CLASS(classDef = PARTS(elementLst = els)))  => begin
                    els
                  end
                  
                  (_, CLASS(classDef = CLASS_EXTENDS(composition = PARTS(elementLst = els))))  => begin
                    els
                  end

                  (_, CLASS(classDef = DERIVED(typeSpec = Absyn.TPATH(path = p))))  => begin
                      e = getElementWithPath(inProgram, p)
                      els = getElementsFromElement(inProgram, e)
                    els
                  end
                end
              end
               #=  a class extends
               =#
               #=  a derived class
               =#
          outProgram
        end

         #= replaces elements in element, it will search for elements pointed by derived =#
        function replaceElementsInElement(inProgram::Program, inElement::Element, inElements::Program)::Element
              local outElement::Element

              outElement = begin
                  local els::Program
                  local e::Element
                  local p::Absyn.Path
                  local i::Absyn.Ident
                  local name::Ident #= the name of the class =#
                  local prefixes::Prefixes #= the common class or component prefixes =#
                  local encapsulatedPrefix::Encapsulated #= the encapsulated prefix =#
                  local partialPrefix::Partial #= the partial prefix =#
                  local restriction::Restriction #= the restriction of the class =#
                  local classDef::ClassDef #= the class specification =#
                  local info::SourceInfo #= the class information =#
                  local cmt::Comment
                   #=  a class with parts, non derived
                   =#
                @matchcontinue (inProgram, inElement, inElements) begin
                  (_, CLASS(name, prefixes, encapsulatedPrefix, partialPrefix, restriction, classDef, cmt, info), _)  => begin
                      (classDef, NONE()) = replaceElementsInClassDef(inProgram, classDef, inElements)
                    CLASS(name, prefixes, encapsulatedPrefix, partialPrefix, restriction, classDef, cmt, info)
                  end
                  
                  (_, CLASS(classDef = classDef), _)  => begin
                      (classDef, SOME(e)) = replaceElementsInClassDef(inProgram, classDef, inElements)
                    e
                  end
                end
              end
               #=  a class derived
               =#
          outElement
        end

         #= replaces the elements in class definition.
         if derived a SOME(element) is returned,
         otherwise the modified class def and NONE() =#
        function replaceElementsInClassDef(inProgram::Program, classDef::ClassDef, inElements::Program)::Tuple{Option, ClassDef}
              local outElementOpt::Option


              outElementOpt = begin
                  local e::Element
                  local p::Absyn.Path
                  local composition::ClassDef
                   #=  a derived class
                   =#
                @match classDef begin
                  DERIVED(typeSpec = Absyn.TPATH(path = p))  => begin
                      e = getElementWithPath(inProgram, p)
                      e = replaceElementsInElement(inProgram, e, inElements)
                    SOME(e)
                  end
                  
                  PARTS()  => begin
                       #=  a parts
                       =#
                      classDef.elementLst = inElements
                    NONE()
                  end
                  
                  CLASS_EXTENDS(composition = composition)  => begin
                       #=  a class extends
                       =#
                      (composition, outElementOpt) = replaceElementsInClassDef(inProgram, composition, inElements)
                      if isNone(outElementOpt)
                        classDef.composition = composition
                      end
                    outElementOpt
                  end
                end
              end
          (outElementOpt, classDef)
        end

         #= returns the element from the program having the name as the id.
         if the element does not exist it fails =#
        function getElementWithId(inProgram::Program, inId::String)::Element
              local outElement::Element

              outElement = begin
                  local sp::Program
                  local rest::Program
                  local c::Element
                  local e::Element
                  local p::Absyn.Path
                  local i::Absyn.Ident
                  local n::Absyn.Ident
                @match (inProgram, inId) begin
                  (CLASS(name = n) <| _, i) where (stringEq(n, i))  => begin
                    e,
                    e
                  end
                  
                  (COMPONENT(name = n) <| _, i) where (stringEq(n, i))  => begin
                    e,
                    e
                  end
                  
                  (EXTENDS(baseClassPath = p) <| _, i) where (stringEq(AbsynUtil.pathString(p), i))  => begin
                    e,
                    e
                  end
                  
                  (_ <| rest, i)  => begin
                    getElementWithId(rest, i)
                  end
                end
              end
          outElement
        end

         #= returns the element from the program having the name as the id.
         if the element does not exist it fails =#
        function getElementWithPath(inProgram::Program, inPath::Absyn.Path)::Element
              local outElement::Element

              outElement = begin
                  local sp::Program
                  local rest::Program
                  local c::Element
                  local e::Element
                  local p::Absyn.Path
                  local i::Absyn.Ident
                  local n::Absyn.Ident
                @match (inProgram, inPath) begin
                  (_, Absyn.FULLYQUALIFIED(p))  => begin
                    getElementWithPath(inProgram, p)
                  end
                  
                  (_, Absyn.IDENT(i))  => begin
                      e = getElementWithId(inProgram, i)
                    e
                  end
                  
                  (_, Absyn.QUALIFIED(i, p))  => begin
                      e = getElementWithId(inProgram, i)
                      sp = getElementsFromElement(inProgram, e)
                      e = getElementWithPath(sp, p)
                    e
                  end
                end
              end
          outElement
        end

         #=  =#
        function getElementName(e::Element)::String
              local s::String

              s = begin
                  local p::Absyn.Path
                @match e begin
                  COMPONENT(name = s)  => begin
                    s
                  end
                  
                  CLASS(name = s)  => begin
                    s
                  end

                  EXTENDS(baseClassPath = p)  => begin
                    AbsynUtil.pathString(p)
                  end
                end
              end
          s
        end

         #= @auhtor: adrpo
         set the base class path in extends =#
        function setBaseClassPath(inE::Element, inBcPath::Absyn.Path)::Element
              local outE::Element

              local bc::Path
              local v::Visibility
              local m::Mod
              local a::Option
              local i::SourceInfo

              EXTENDS(bc, v, m, a, i) = inE
              outE = EXTENDS(inBcPath, v, m, a, i)
          outE
        end

         #= @auhtor: adrpo
         return the base class path in extends =#
        function getBaseClassPath(inE::Element)::Absyn.Path
              local outBcPath::Absyn.Path

              local bc::Path
              local v::Visibility
              local m::Mod
              local a::Option
              local i::SourceInfo

              EXTENDS(baseClassPath = outBcPath) = inE
          outBcPath
        end

         #= @auhtor: adrpo
         set the typespec path in component =#
        function setComponentTypeSpec(inE::Element, inTypeSpec::Absyn.TypeSpec)::Element
              local outE::Element

              local n::Ident
              local pr::Prefixes
              local atr::Attributes
              local ts::Absyn.TypeSpec
              local cmt::Comment
              local cnd::Option
              local bc::Path
              local v::Visibility
              local m::Mod
              local a::Option
              local i::SourceInfo

              COMPONENT(n, pr, atr, ts, m, cmt, cnd, i) = inE
              outE = COMPONENT(n, pr, atr, inTypeSpec, m, cmt, cnd, i)
          outE
        end

         #= @auhtor: adrpo
         get the typespec path in component =#
        function getComponentTypeSpec(inE::Element)::Absyn.TypeSpec
              local outTypeSpec::Absyn.TypeSpec

              COMPONENT(typeSpec = outTypeSpec) = inE
          outTypeSpec
        end

         #= @auhtor: adrpo
         set the modification in component =#
        function setComponentMod(inE::Element, inMod::Mod)::Element
              local outE::Element

              local n::Ident
              local pr::Prefixes
              local atr::Attributes
              local ts::Absyn.TypeSpec
              local cmt::Comment
              local cnd::Option
              local bc::Path
              local v::Visibility
              local m::Mod
              local a::Option
              local i::SourceInfo

              COMPONENT(n, pr, atr, ts, m, cmt, cnd, i) = inE
              outE = COMPONENT(n, pr, atr, ts, inMod, cmt, cnd, i)
          outE
        end

         #= @auhtor: adrpo
         get the modification in component =#
        function getComponentMod(inE::Element)::Mod
              local outMod::Mod

              COMPONENT(modifications = outMod) = inE
          outMod
        end

        function isDerivedClass(inClass::Element)::Bool
              local isDerived::Bool

              isDerived = begin
                @match inClass begin
                  CLASS(classDef = DERIVED())  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isDerived
        end

        function isClassExtends(cls::Element)::Bool
              local isCE::Bool

              isCE = begin
                @match cls begin
                  CLASS(classDef = CLASS_EXTENDS())  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isCE
        end

         #= @auhtor: adrpo
         set the base class path in extends =#
        function setDerivedTypeSpec(inE::Element, inTypeSpec::Absyn.TypeSpec)::Element
              local outE::Element

              local n::Ident
              local pr::Prefixes
              local atr::Attributes
              local ep::Encapsulated
              local pp::Partial
              local res::Restriction
              local cd::ClassDef
              local i::SourceInfo
              local ts::Absyn.TypeSpec
              local ann::Option
              local cmt::Comment
              local m::Mod

              CLASS(n, pr, ep, pp, res, cd, cmt, i) = inE
              DERIVED(ts, m, atr) = cd
              cd = DERIVED(inTypeSpec, m, atr)
              outE = CLASS(n, pr, ep, pp, res, cd, cmt, i)
          outE
        end

         #= @auhtor: adrpo
         set the base class path in extends =#
        function getDerivedTypeSpec(inE::Element)::Absyn.TypeSpec
              local outTypeSpec::Absyn.TypeSpec

              CLASS(classDef = DERIVED(typeSpec = outTypeSpec)) = inE
          outTypeSpec
        end

         #= @auhtor: adrpo
         set the base class path in extends =#
        function getDerivedMod(inE::Element)::Mod
              local outMod::Mod

              CLASS(classDef = DERIVED(modifications = outMod)) = inE
          outMod
        end

        function setClassPrefixes(inPrefixes::Prefixes, cl::Element)::Element
              local outCl::Element

              outCl = begin
                  local parts::ClassDef
                  local e::Encapsulated
                  local id::Ident
                  local info::SourceInfo
                  local restriction::Restriction
                  local prefixes::Prefixes
                  local pp::Partial
                  local cmt::Comment
                   #=  not the same, change
                   =#
                @match (inPrefixes, cl) begin
                  (_, CLASS(id, _, e, pp, restriction, parts, cmt, info))  => begin
                    CLASS(id, inPrefixes, e, pp, restriction, parts, cmt, info)
                  end
                end
              end
          outCl
        end

        function makeEquation(inEEq::EEquation)::Equation
              local outEq::Equation

              outEq = EQUATION(inEEq)
          outEq
        end

        function getClassDef(inClass::Element)::ClassDef
              local outCdef::ClassDef

              outCdef = begin
                @match inClass begin
                  CLASS(classDef = outCdef)  => begin
                    outCdef
                  end
                end
              end
          outCdef
        end

         #= @author:
         returns true if equations contains reinit =#
        function equationsContainReinit(inEqs::Lst)::Bool
              local hasReinit::Bool

              hasReinit = begin
                  local b::Bool
                @match inEqs begin
                  _  => begin
                      b = List.applyAndFold(inEqs, boolOr, equationContainReinit, false)
                    b
                  end
                end
              end
          hasReinit
        end

         #= @author:
         returns true if equation contains reinit =#
        function equationContainReinit(inEq::EEquation)::Bool
              local hasReinit::Bool

              hasReinit = begin
                  local b::Bool
                  local eqs::Lst
                  local eqs_lst::Lst
                  local tpl_el::Lst
                @match inEq begin
                  EQ_REINIT()  => begin
                    true
                  end
                  
                  EQ_WHEN(eEquationLst = eqs, elseBranches = tpl_el)  => begin
                      b = equationsContainReinit(eqs)
                      eqs_lst = List.map(tpl_el, Util.tuple22)
                      b = List.applyAndFold(eqs_lst, boolOr, equationsContainReinit, b)
                    b
                  end
                  
                  EQ_IF(thenBranch = eqs_lst, elseBranch = eqs)  => begin
                      b = equationsContainReinit(eqs)
                      b = List.applyAndFold(eqs_lst, boolOr, equationsContainReinit, b)
                    b
                  end
                  
                  EQ_FOR(eEquationLst = eqs)  => begin
                      b = equationsContainReinit(eqs)
                    b
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          hasReinit
        end

         #= @author:
         returns true if statements contains reinit =#
        function algorithmsContainReinit(inAlgs::Lst)::Bool
              local hasReinit::Bool

              hasReinit = begin
                  local b::Bool
                @match inAlgs begin
                  _  => begin
                      b = List.applyAndFold(inAlgs, boolOr, algorithmContainReinit, false)
                    b
                  end
                end
              end
          hasReinit
        end
#= For testing =#
        function getConstrainedByModifiers(inPrefixes::SCode.Prefixes)::SCode.Mod
              local outMod::SCode.Mod

              outMod = begin
                  local m::SCode.Mod
                @match inPrefixes begin
                  SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(SOME(SCode.CONSTRAINCLASS(modifier = m))))  => begin
                    m
                  end
                  
                  _  => begin
                      SCode.NOMOD()
                  end
                end
              end
          outMod
        end

         #= @author:
         returns true if statement contains reinit =#
        function algorithmContainReinit(inAlg::Statement)::Bool
              local hasReinit::Bool

              hasReinit = begin
                  local b::Bool
                  local b1::Bool
                  local b2::Bool
                  local b3::Bool
                  local algs::Lst
                  local algs1::Lst
                  local algs2::Lst
                  local algs_lst::Lst
                  local tpl_alg::Lst
                @match inAlg begin
                  ALG_REINIT()  => begin
                    true
                  end
                  
                  ALG_WHEN_A(branches = tpl_alg)  => begin
                      algs_lst = List.map(tpl_alg, Util.tuple22)
                      b = List.applyAndFold(algs_lst, boolOr, algorithmsContainReinit, false)
                    b
                  end

                  ALG_IF(trueBranch = algs1, elseIfBranch = tpl_alg, elseBranch = algs2)  => begin
                      b1 = algorithmsContainReinit(algs1)
                      algs_lst = List.map(tpl_alg, Util.tuple22)
                      b2 = List.applyAndFold(algs_lst, boolOr, algorithmsContainReinit, b1)
                      b3 = algorithmsContainReinit(algs2)
                      b = boolOr(b1, boolOr(b2, b3))
                    b
                  end
                  
                  ALG_FOR(forBody = algs)  => begin
                      b = algorithmsContainReinit(algs)
                    b
                  end
                  
                  ALG_WHILE(whileBody = algs)  => begin
                      b = algorithmsContainReinit(algs)
                    b
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          hasReinit
        end

        function getClassPartialPrefix(inElement::Element)::Partial
              local outPartial::Partial

              CLASS(partialPrefix = outPartial) = inElement
          outPartial
        end

        function getClassRestriction(inElement::Element)::Restriction
              local outRestriction::Restriction

              CLASS(restriction = outRestriction) = inElement
          outRestriction
        end

        function isRedeclareSubMod(inSubMod::SubMod)::Bool
              local outIsRedeclare::Bool

              outIsRedeclare = begin
                @match inSubMod begin
                  NAMEMOD(mod = REDECL())  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outIsRedeclare
        end

        function componentMod(inElement::Element)::Mod
              local outMod::Mod

              outMod = begin
                  local mod::Mod
                @match inElement begin
                  COMPONENT(modifications = mod)  => begin
                    mod
                  end
                  
                  _  => begin
                      NOMOD()
                  end
                end
              end
          outMod
        end

        function elementMod(inElement::Element)::Mod
              local outMod::Mod

              outMod = begin
                  local mod::Mod
                @match inElement begin
                  COMPONENT(modifications = mod)  => begin
                    mod
                  end
                  
                  CLASS(classDef = DERIVED(modifications = mod))  => begin
                    mod
                  end
                  
                  CLASS(classDef = CLASS_EXTENDS(modifications = mod))  => begin
                    mod
                  end
                  
                  EXTENDS(modifications = mod)  => begin
                    mod
                  end
                end
              end
          outMod
        end

         #= Sets the modifier of an element, or fails if the element is not capable of
           having a modifier. =#
        function setElementMod(inElement::Element, inMod::Mod)::Element
              local outElement::Element

              outElement = begin
                  local n::Ident
                  local pf::Prefixes
                  local attr::Attributes
                  local ty::Absyn.TypeSpec
                  local cmt::Comment
                  local cnd::Option
                  local i::SourceInfo
                  local ep::Encapsulated
                  local pp::Partial
                  local res::Restriction
                  local cdef::ClassDef
                  local bc::Absyn.Path
                  local vis::Visibility
                  local ann::Option
                @match (inElement, inMod) begin
                  (COMPONENT(n, pf, attr, ty, _, cmt, cnd, i), _)  => begin
                    COMPONENT(n, pf, attr, ty, inMod, cmt, cnd, i)
                  end
                  
                  (CLASS(n, pf, ep, pp, res, cdef, cmt, i), _)  => begin
                      cdef = setClassDefMod(cdef, inMod)
                    CLASS(n, pf, ep, pp, res, cdef, cmt, i)
                  end
                  
                  (EXTENDS(bc, vis, _, ann, i), _)  => begin
                    EXTENDS(bc, vis, inMod, ann, i)
                  end
                end
              end
          outElement
        end

        function setClassDefMod(inClassDef::ClassDef, inMod::Mod)::ClassDef
              local outClassDef::ClassDef

              outClassDef = begin
                  local bc::Ident
                  local cdef::ClassDef
                  local ty::Absyn.TypeSpec
                  local attr::Attributes
                @match (inClassDef, inMod) begin
                  (DERIVED(ty, _, attr), _)  => begin
                    DERIVED(ty, inMod, attr)
                  end
                  
                  (CLASS_EXTENDS(_, cdef), _)  => begin
                    CLASS_EXTENDS(inMod, cdef)
                  end
                end
              end
          outClassDef
        end

        function isBuiltinElement(inElement::Element)::Bool
              local outIsBuiltin::Bool

              outIsBuiltin = begin
                  local ann::Annotation
                @match inElement begin
                  CLASS(classDef = PARTS(externalDecl = SOME(EXTERNALDECL(lang = SOME("builtin")))))  => begin
                    true
                  end
                  
                  CLASS(cmt = COMMENT(annotation_ = SOME(ann)))  => begin
                    hasBooleanNamedAnnotation(ann, "__OpenModelica_builtin")
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outIsBuiltin
        end

        function partitionElements(inElements::Lst)::Tuple{List, List, List, List, List}
              local outDefineUnits::Lst
              local outImports::Lst
              local outExtends::Lst
              local outClasses::Lst
              local outComponents::Lst

              (outComponents, outClasses, outExtends, outImports, outDefineUnits) = partitionElements2(inElements, list(), list(), list(), list(), list())
          (outDefineUnits, outImports, outExtends, outClasses, outComponents)
        end

        function partitionElements2(inElements::Lst, inComponents::Lst, inClasses::Lst, inExtends::Lst, inImports::Lst, inDefineUnits::Lst)::Tuple{List, List, List, List, List}
              local outDefineUnits::Lst
              local outImports::Lst
              local outExtends::Lst
              local outClasses::Lst
              local outComponents::Lst

              (outComponents, outClasses, outExtends, outImports, outDefineUnits) = begin
                  local el::Element
                  local rest_el::Lst
                  local comp::Lst
                  local cls::Lst
                  local ext::Lst
                  local imp::Lst
                  local def::Lst
                @match (inElements, inComponents, inClasses, inExtends, inImports, inDefineUnits) begin
                  (COMPONENT() <| rest_el, comp, cls, ext, imp, def)  => begin
                    el,
                      (comp, cls, ext, imp, def) = partitionElements2(rest_el, el <| comp, cls, ext, imp, def)
                    (comp, cls, ext, imp, def)
                  end
                  
                  (CLASS() <| rest_el, comp, cls, ext, imp, def)  => begin
                    el,
                      (comp, cls, ext, imp, def) = partitionElements2(rest_el, comp, el <| cls, ext, imp, def)
                    (comp, cls, ext, imp, def)
                  end
                  
                  (EXTENDS() <| rest_el, comp, cls, ext, imp, def)  => begin
                    el,
                      (comp, cls, ext, imp, def) = partitionElements2(rest_el, comp, cls, el <| ext, imp, def)
                    (comp, cls, ext, imp, def)
                  end
                  
                  (IMPORT() <| rest_el, comp, cls, ext, imp, def)  => begin
                    el,
                      (comp, cls, ext, imp, def) = partitionElements2(rest_el, comp, cls, ext, el <| imp, def)
                    (comp, cls, ext, imp, def)
                  end
                  
                  (DEFINEUNIT() <| rest_el, comp, cls, ext, imp, def)  => begin
                    el,
                      (comp, cls, ext, imp, def) = partitionElements2(rest_el, comp, cls, ext, imp, el <| def)
                    (comp, cls, ext, imp, def)
                  end
                  
                  ( nil(), comp, cls, ext, imp, def)  => begin
                    (listReverse(comp), listReverse(cls), listReverse(ext), listReverse(imp), listReverse(def))
                  end
                end
              end
          (outDefineUnits, outImports, outExtends, outClasses, outComponents)
        end

        function isExternalFunctionRestriction(inRestr::FunctionRestriction)::Bool
              local isExternal::Bool

              isExternal = begin
                @match inRestr begin
                  FR_EXTERNAL_FUNCTION()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isExternal
        end

        function isImpureFunctionRestriction(inRestr::FunctionRestriction)::Bool
              local isExternal::Bool

              isExternal = begin
                @match inRestr begin
                  FR_EXTERNAL_FUNCTION(true)  => begin
                    true
                  end
                  
                  FR_NORMAL_FUNCTION(true)  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isExternal
        end

        function isRestrictionImpure(inRestr::Restriction, hasZeroOutputPreMSL3_2::Bool)::Bool
              local isExternal::Bool

              isExternal = begin
                @match (inRestr, hasZeroOutputPreMSL3_2) begin
                  (R_FUNCTION(FR_EXTERNAL_FUNCTION(true)), _)  => begin
                    true
                  end
                  
                  (R_FUNCTION(FR_NORMAL_FUNCTION(true)), _)  => begin
                    true
                  end
                  
                  (R_FUNCTION(FR_EXTERNAL_FUNCTION(false)), false)  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isExternal
        end

        function setElementVisibility(inElement::Element, inVisibility::Visibility)::Element
              local outElement::Element

              outElement = begin
                  local name::Ident
                  local prefs::Prefixes
                  local attr::Attributes
                  local ty::Absyn.TypeSpec
                  local mod::Mod
                  local cmt::Comment
                  local cond::Option
                  local info::SourceInfo
                  local ep::Encapsulated
                  local pp::Partial
                  local res::Restriction
                  local cdef::ClassDef
                  local bc::Absyn.Path
                  local ann::Option
                  local imp::Absyn.Import
                  local unit::Option
                  local weight::Option
                @match (inElement, inVisibility) begin
                  (COMPONENT(name, prefs, attr, ty, mod, cmt, cond, info), _)  => begin
                      prefs = prefixesSetVisibility(prefs, inVisibility)
                    COMPONENT(name, prefs, attr, ty, mod, cmt, cond, info)
                  end
                  
                  (CLASS(name, prefs, ep, pp, res, cdef, cmt, info), _)  => begin
                      prefs = prefixesSetVisibility(prefs, inVisibility)
                    CLASS(name, prefs, ep, pp, res, cdef, cmt, info)
                  end
                  
                  (EXTENDS(bc, _, mod, ann, info), _)  => begin
                    EXTENDS(bc, inVisibility, mod, ann, info)
                  end
                  
                  (IMPORT(imp, _, info), _)  => begin
                    IMPORT(imp, inVisibility, info)
                  end
                  
                  (DEFINEUNIT(name, _, unit, weight), _)  => begin
                    DEFINEUNIT(name, inVisibility, unit, weight)
                  end
                end
              end
          outElement
        end

         #= Returns true if the given element is a class with the given name, otherwise false. =#
        function isClassNamed(inName::Ident, inClass::Element)::Bool
              local outIsNamed::Bool

              outIsNamed = begin
                  local name::Ident
                @match (inName, inClass) begin
                  (_, CLASS(name = name))  => begin
                    stringEq(inName, name)
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outIsNamed
        end

         #= Returns the comment of an element. =#
        function getElementComment(inElement::Element)::Option
              local outComment::Option

              outComment = begin
                  local cmt::Comment
                  local cdef::ClassDef
                @match inElement begin
                  COMPONENT(comment = cmt)  => begin
                    SOME(cmt)
                  end
                  
                  CLASS(cmt = cmt)  => begin
                    SOME(cmt)
                  end
                  
                  _  => begin
                      NONE()
                  end
                end
              end
          outComment
        end

         #= Removes the annotation from a comment. =#
        function stripAnnotationFromComment(inComment::Option)::Option
              local outComment::Option

              outComment = begin
                  local str::Option
                  local cmt::Option
                @match inComment begin
                  SOME(COMMENT(_, str))  => begin
                    SOME(COMMENT(NONE(), str))
                  end
                  
                  _  => begin
                      NONE()
                  end
                end
              end
          outComment
        end

        function isOverloadedFunction(inElement::Element)::Bool
              local isOverloaded::Bool

              isOverloaded = begin
                @match inElement begin
                  CLASS(classDef = OVERLOAD())  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isOverloaded
        end

         #= @author: adrpo
         this function merges the original declaration with the redeclared declaration, see 7.3.2 in Spec.
         - modifiers from the constraining class on derived classes are merged into the new declaration
         - modifiers from the original derived classes are merged into the new declaration
         - if the original declaration has no constraining type the derived declaration is used
         - prefixes and attributes are merged
         same with components
         TODO! how about non-short class definitions with constrained by with modifications? =#
        function mergeWithOriginal(inNew::Element, inOld::Element)::Element
              local outNew::Element

              outNew = begin
                  local n::Element
                  local o::Element
                  local name1::Ident
                  local name2::Ident
                  local prefixes1::Prefixes
                  local prefixes2::Prefixes
                  local en1::Encapsulated
                  local en2::Encapsulated
                  local p1::Partial
                  local p2::Partial
                  local restr1::Restriction
                  local restr2::Restriction
                  local attr1::Attributes
                  local attr2::Attributes
                  local mod1::Mod
                  local mod2::Mod
                  local tp1::Absyn.TypeSpec
                  local tp2::Absyn.TypeSpec
                  local im1::Absyn.Import
                  local im2::Absyn.Import
                  local path1::Absyn.Path
                  local path2::Absyn.Path
                  local os1::Option
                  local os2::Option
                  local or1::Option
                  local or2::Option
                  local cond1::Option
                  local cond2::Option
                  local cd1::ClassDef
                  local cd2::ClassDef
                  local cm::Comment
                  local i::SourceInfo
                  local mCCNew::Mod
                  local mCCOld::Mod
                   #=  for functions return the new one!
                   =#
                @matchcontinue (inNew, inOld) begin
                  (_, _)  => begin
                      @assert true == (isFunction(inNew))
                    inNew
                  end
                  
                  (CLASS(name1, prefixes1, en1, p1, restr1, cd1, cm, i), CLASS(_, prefixes2, _, _, _, cd2, _, _))  => begin
                      mCCNew = getConstrainedByModifiers(prefixes1)
                      mCCOld = getConstrainedByModifiers(prefixes2)
                      cd1 = mergeClassDef(cd1, cd2, mCCNew, mCCOld)
                      prefixes1 = propagatePrefixes(prefixes2, prefixes1)
                      n = CLASS(name1, prefixes1, en1, p1, restr1, cd1, cm, i)
                    n
                  end
                  
                  _  => begin
                      inNew
                  end
                end
              end
          outNew
        end

         #= @author: adrpo
         see mergeWithOriginal =#
        function mergeClassDef(inNew::ClassDef, inOld::ClassDef, inCCModNew::Mod, inCCModOld::Mod)::ClassDef
              local outNew::ClassDef

              outNew = begin
                  local n::ClassDef
                  local o::ClassDef
                  local ts1::Absyn.TypeSpec
                  local ts2::Absyn.TypeSpec
                  local m1::Mod
                  local m2::Mod
                  local a1::Attributes
                  local a2::Attributes
                @match (inNew, inOld, inCCModNew, inCCModOld) begin
                  (DERIVED(ts1, m1, a1), DERIVED(_, m2, a2), _, _)  => begin
                      m2 = mergeModifiers(m2, inCCModOld)
                      m1 = mergeModifiers(m1, inCCModNew)
                      m2 = mergeModifiers(m1, m2)
                      a2 = propagateAttributes(a2, a1)
                      n = DERIVED(ts1, m2, a2)
                    n
                  end
                end
              end
          outNew
        end

        function mergeModifiers(inNewMod::Mod, inOldMod::Mod)::Mod
              local outMod::Mod

              outMod = begin
                  local f1::Final
                  local f2::Final
                  local e1::Each
                  local e2::Each
                  local sl1::Lst
                  local sl2::Lst
                  local sl::Lst
                  local b1::Option
                  local b2::Option
                  local b::Option
                  local i1::SourceInfo
                  local i2::SourceInfo
                  local m::Mod
                @matchcontinue (inNewMod, inOldMod) begin
                  (_, NOMOD())  => begin
                    inNewMod
                  end
                  
                  (NOMOD(), _)  => begin
                    inOldMod
                  end
                  
                  (REDECL(), _)  => begin
                    inNewMod
                  end
                  
                  (MOD(f1, e1, sl1, b1, i1), MOD(f2, e2, sl2, b2, _))  => begin
                      b = mergeBindings(b1, b2)
                      sl = mergeSubMods(sl1, sl2)
                      if referenceEq(b, b1) && referenceEq(sl, sl1)
                        m = inNewMod
                      elseif referenceEq(b, b2) && referenceEq(sl, sl2) && valueEq(f1, f2) && valueEq(e1, e2)
                        m = inOldMod
                      else
                        m = MOD(f1, e1, sl, b, i1)
                      end
                    m
                  end
                  
                  _  => begin
                      inNewMod
                  end
                end
              end
          outMod
        end

        function mergeBindings(inNew::Option, inOld::Option)::Option
              local outBnd::Option

              outBnd = begin
                @match (inNew, inOld) begin
                  (SOME(_), _)  => begin
                    inNew
                  end
                  
                  (NONE(), _)  => begin
                    inOld
                  end
                end
              end
          outBnd
        end

        function mergeSubMods(inNew::Lst, inOld::Lst)::Lst
              local outSubs::Lst

              outSubs = begin
                  local sl::Lst
                  local rest::Lst
                  local old::Lst
                  local s::SubMod
                @matchcontinue (inNew, inOld) begin
                  ( nil(), _)  => begin
                    inOld
                  end
                  
                  (s <| rest, _)  => begin
                      old = removeSub(s, inOld)
                      sl = mergeSubMods(rest, old)
                    s <| sl
                  end
                  
                  _  => begin
                      inNew
                  end
                end
              end
          outSubs
        end

        function removeSub(inSub::SubMod, inOld::Lst)::Lst
              local outSubs::Lst

              outSubs = begin
                  local rest::Lst
                  local id1::Ident
                  local id2::Ident
                  local idxs1::Lst
                  local idxs2::Lst
                  local s::SubMod
                @matchcontinue (inSub, inOld) begin
                  (_,  nil())  => begin
                    inOld
                  end
                  
                  (NAMEMOD(ident = id1), NAMEMOD(ident = id2) <| rest)  => begin
                      @assert true == (stringEqual(id1, id2))
                    rest
                  end
                  
                  (_, s <| rest)  => begin
                      rest = removeSub(inSub, rest)
                    s <| rest
                  end
                end
              end
          outSubs
        end

        function mergeComponentModifiers(inNewComp::Element, inOldComp::Element)::Element
              local outComp::Element

              outComp = begin
                  local n1::Ident
                  local n2::Ident
                  local p1::Prefixes
                  local p2::Prefixes
                  local a1::Attributes
                  local a2::Attributes
                  local t1::Absyn.TypeSpec
                  local t2::Absyn.TypeSpec
                  local m1::Mod
                  local m2::Mod
                  local m::Mod
                  local c1::Comment
                  local c2::Comment
                  local cnd1::Option
                  local cnd2::Option
                  local i1::SourceInfo
                  local i2::SourceInfo
                  local c::Element
                @match (inNewComp, inOldComp) begin
                  (COMPONENT(n1, p1, a1, t1, m1, c1, cnd1, i1), COMPONENT(_, _, _, _, m2, _, _, _))  => begin
                      m = mergeModifiers(m1, m2)
                      c = COMPONENT(n1, p1, a1, t1, m, c1, cnd1, i1)
                    c
                  end
                end
              end
          outComp
        end

        function propagateAttributes(inOriginalAttributes::Attributes, inNewAttributes::Attributes, inNewTypeIsArray::Bool = false)::Attributes
              local outNewAttributes::Attributes

              local dims1::Absyn.ArrayDim
              local dims2::Absyn.ArrayDim
              local ct1::ConnectorType
              local ct2::ConnectorType
              local prl1::Parallelism
              local prl2::Parallelism
              local var1::Variability
              local var2::Variability
              local dir1::Absyn.Direction
              local dir2::Absyn.Direction
              local if1::Absyn.IsField
              local if2::Absyn.IsField

              ATTR(dims1, ct1, prl1, var1, dir1, if1) = inOriginalAttributes
              ATTR(dims2, ct2, prl2, var2, dir2, if2) = inNewAttributes
               #=  If the new component has an array type, don't propagate the old dimensions.
               =#
               #=  E.g. type Real3 = Real[3];
               =#
               #=       replaceable Real x[:];
               =#
               #=       comp(redeclare Real3 x) => Real[3] x
               =#
              if ! inNewTypeIsArray
                dims2 = propagateArrayDimensions(dims1, dims2)
              end
              ct2 = propagateConnectorType(ct1, ct2)
              prl2 = propagateParallelism(prl1, prl2)
              var2 = propagateVariability(var1, var2)
              dir2 = propagateDirection(dir1, dir2)
              if2 = propagateIsField(if1, if2)
              outNewAttributes = ATTR(dims2, ct2, prl2, var2, dir2, if2)
          outNewAttributes
        end

        function propagateArrayDimensions(inOriginalDims::Absyn.ArrayDim, inNewDims::Absyn.ArrayDim)::Absyn.ArrayDim
              local outNewDims::Absyn.ArrayDim

              outNewDims = begin
                @match (inOriginalDims, inNewDims) begin
                  (_,  nil())  => begin
                    inOriginalDims
                  end
                  
                  _  => begin
                      inNewDims
                  end
                end
              end
          outNewDims
        end

        function propagateConnectorType(inOriginalConnectorType::ConnectorType, inNewConnectorType::ConnectorType)::ConnectorType
              local outNewConnectorType::ConnectorType

              outNewConnectorType = begin
                @match (inOriginalConnectorType, inNewConnectorType) begin
                  (_, POTENTIAL())  => begin
                    inOriginalConnectorType
                  end
                  
                  _  => begin
                      inNewConnectorType
                  end
                end
              end
          outNewConnectorType
        end

        function propagateParallelism(inOriginalParallelism::Parallelism, inNewParallelism::Parallelism)::Parallelism
              local outNewParallelism::Parallelism

              outNewParallelism = begin
                @match (inOriginalParallelism, inNewParallelism) begin
                  (_, NON_PARALLEL())  => begin
                    inOriginalParallelism
                  end
                  
                  _  => begin
                      inNewParallelism
                  end
                end
              end
          outNewParallelism
        end

        function propagateVariability(inOriginalVariability::Variability, inNewVariability::Variability)::Variability
              local outNewVariability::Variability

              outNewVariability = begin
                @match (inOriginalVariability, inNewVariability) begin
                  (_, VAR())  => begin
                    inOriginalVariability
                  end
                  
                  _  => begin
                      inNewVariability
                  end
                end
              end
          outNewVariability
        end

        function propagateDirection(inOriginalDirection::Absyn.Direction, inNewDirection::Absyn.Direction)::Absyn.Direction
              local outNewDirection::Absyn.Direction

              outNewDirection = begin
                @match (inOriginalDirection, inNewDirection) begin
                  (_, Absyn.BIDIR())  => begin
                    inOriginalDirection
                  end
                  
                  _  => begin
                      inNewDirection
                  end
                end
              end
          outNewDirection
        end

        function propagateIsField(inOriginalIsField::Absyn.IsField, inNewIsField::Absyn.IsField)::Absyn.IsField
              local outNewIsField::Absyn.IsField

              outNewIsField = begin
                @matchcontinue (inOriginalIsField, inNewIsField) begin
                  (_, Absyn.NONFIELD())  => begin
                    inOriginalIsField
                  end
                  
                  _  => begin
                      inNewIsField
                  end
                end
              end
          outNewIsField
        end

        function propagateAttributesVar(inOriginalVar::Element, inNewVar::Element, inNewTypeIsArray::Bool)::Element
              local outNewVar::Element

              local name::Ident
              local pref1::Prefixes
              local pref2::Prefixes
              local attr1::Attributes
              local attr2::Attributes
              local ty::Absyn.TypeSpec
              local mod::Mod
              local cmt::Comment
              local cond::Option
              local info::SourceInfo

              COMPONENT(prefixes = pref1, attributes = attr1) = inOriginalVar
              COMPONENT(name, pref2, attr2, ty, mod, cmt, cond, info) = inNewVar
              pref2 = propagatePrefixes(pref1, pref2)
              attr2 = propagateAttributes(attr1, attr2, inNewTypeIsArray)
              outNewVar = COMPONENT(name, pref2, attr2, ty, mod, cmt, cond, info)
          outNewVar
        end

        function propagateAttributesClass(inOriginalClass::Element, inNewClass::Element)::Element
              local outNewClass::Element

              local name::Ident
              local pref1::Prefixes
              local pref2::Prefixes
              local ep::Encapsulated
              local pp::Partial
              local res::Restriction
              local cdef::ClassDef
              local cmt::Comment
              local info::SourceInfo

              CLASS(prefixes = pref1) = inOriginalClass
              CLASS(name, pref2, ep, pp, res, cdef, cmt, info) = inNewClass
              pref2 = propagatePrefixes(pref1, pref2)
              outNewClass = CLASS(name, pref2, ep, pp, res, cdef, cmt, info)
          outNewClass
        end

        function propagatePrefixes(inOriginalPrefixes::Prefixes, inNewPrefixes::Prefixes)::Prefixes
              local outNewPrefixes::Prefixes

              local vis1::Visibility
              local vis2::Visibility
              local io1::Absyn.InnerOuter
              local io2::Absyn.InnerOuter
              local rdp::Redeclare
              local fp::Final
              local rpp::Replaceable

              PREFIXES(visibility = vis1, innerOuter = io1) = inOriginalPrefixes
              PREFIXES(vis2, rdp, fp, io2, rpp) = inNewPrefixes
              io2 = propagatePrefixInnerOuter(io1, io2)
              outNewPrefixes = PREFIXES(vis2, rdp, fp, io2, rpp)
          outNewPrefixes
        end

        function propagatePrefixInnerOuter(inOriginalIO::Absyn.InnerOuter, inIO::Absyn.InnerOuter)::Absyn.InnerOuter
              local outIO::Absyn.InnerOuter

              outIO = begin
                @match (inOriginalIO, inIO) begin
                  (_, Absyn.NOT_INNER_OUTER())  => begin
                    inOriginalIO
                  end
                  
                  _  => begin
                      inIO
                  end
                end
              end
          outIO
        end

         #= Return true if Class is a partial. =#
        function isPackage(inClass::Element)::Bool
              local outBoolean::Bool

              outBoolean = begin
                @match inClass begin
                  CLASS(restriction = R_PACKAGE())  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outBoolean
        end

         #= Return true if Class is a partial. =#
        function isPartial(inClass::Element)::Bool
              local outBoolean::Bool

              outBoolean = begin
                @match inClass begin
                  CLASS(partialPrefix = PARTIAL())  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outBoolean
        end

         #= Return true if the given element is allowed in a package, i.e. if it's a
           constant or non-component element. Otherwise returns false. =#
        function isValidPackageElement(inElement::Element)::Bool
              local outIsValid::Bool

              outIsValid = begin
                @match inElement begin
                  COMPONENT(attributes = ATTR(variability = CONST()))  => begin
                    true
                  end
                  
                  COMPONENT()  => begin
                    false
                  end
                  
                  _  => begin
                      true
                  end
                end
              end
          outIsValid
        end

         #= returns true if a Class fulfills the requirements of an external object =#
        function classIsExternalObject(cl::Element)::Bool
              local res::Bool

              res = begin
                  local els::Lst
                @match cl begin
                  CLASS(classDef = PARTS(elementLst = els))  => begin
                    isExternalObject(els)
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          res
        end

         #= Returns true if the element list fulfills the condition of an External Object.
        An external object extends the builtinClass ExternalObject, and has two local
        functions, destructor and constructor.  =#
        function isExternalObject(els::Lst)::Bool
              local res::Bool

              res = begin
                @matchcontinue els begin
                  _  => begin
                      @assert 3 == (listLength(els))
                      @assert true == (hasExtendsOfExternalObject(els))
                      @assert true == (hasExternalObjectDestructor(els))
                      @assert true == (hasExternalObjectConstructor(els))
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          res
        end

         #= returns true if element list contains 'extends ExternalObject;' =#
        function hasExtendsOfExternalObject(inEls::Lst)::Bool
              local res::Bool

              res = begin
                  local els::Lst
                  local path::Absyn.Path
                @match inEls begin
                   nil()  => begin
                    false
                  end
                  
                  EXTENDS(baseClassPath = path) <| _ where (AbsynUtil.pathEqual(path, Absyn.IDENT("ExternalObject")))  => begin
                    true
                  end
                  
                  _ <| els  => begin
                    hasExtendsOfExternalObject(els)
                  end
                end
              end
          res
        end

         #= returns true if element list contains 'function destructor .. end destructor' =#
        function hasExternalObjectDestructor(inEls::Lst)::Bool
              local res::Bool

              res = begin
                  local els::Lst
                @match inEls begin
                  CLASS(name = "destructor") <| _  => begin
                    true
                  end
                  
                  _ <| els  => begin
                    hasExternalObjectDestructor(els)
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          res
        end

         #= returns true if element list contains 'function constructor ... end constructor' =#
        function hasExternalObjectConstructor(inEls::Lst)::Bool
              local res::Bool

              res = begin
                  local els::Lst
                @match inEls begin
                  CLASS(name = "constructor") <| _  => begin
                    true
                  end
                  
                  _ <| els  => begin
                    hasExternalObjectConstructor(els)
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          res
        end

         #= returns the class 'function destructor .. end destructor' from element list =#
        function getExternalObjectDestructor(inEls::Lst)::Element
              local cl::Element

              cl = begin
                  local els::Lst
                @match inEls begin
                  CLASS(name = "destructor") <| _  => begin
                    cl,
                    cl
                  end
                  
                  _ <| els  => begin
                    getExternalObjectDestructor(els)
                  end
                end
              end
          cl
        end

         #= returns the class 'function constructor ... end constructor' from element list =#
        function getExternalObjectConstructor(inEls::Lst)::Element
              local cl::Element

              cl = begin
                  local els::Lst
                @match inEls begin
                  CLASS(name = "constructor") <| _  => begin
                    cl,
                    cl
                  end
                  
                  _ <| els  => begin
                    getExternalObjectConstructor(els)
                  end
                end
              end
          cl
        end

        function isInstantiableClassRestriction(inRestriction::Restriction)::Bool
              local outIsInstantiable::Bool

              outIsInstantiable = begin
                @match inRestriction begin
                  R_CLASS()  => begin
                    true
                  end
                  
                  R_MODEL()  => begin
                    true
                  end
                  
                  R_RECORD()  => begin
                    true
                  end
                  
                  R_BLOCK()  => begin
                    true
                  end
                  
                  R_CONNECTOR()  => begin
                    true
                  end
                  
                  R_TYPE()  => begin
                    true
                  end
                  
                  R_ENUMERATION()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outIsInstantiable
        end

        function isInitial(inInitial::Initial)::Bool
              local isIn::Bool

              isIn = begin
                @match inInitial begin
                  INITIAL()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isIn
        end

         #= check if the restrictions are the same for redeclared classes =#
        function checkSameRestriction(inResNew::Restriction, inResOrig::Restriction, inInfoNew::SourceInfo, inInfoOrig::SourceInfo)::Tuple{SourceInfo, Restriction}
              local outInfo::SourceInfo
              local outRes::Restriction

              (outRes, outInfo) = begin
                @match (inResNew, inResOrig, inInfoNew, inInfoOrig) begin
                  (_, _, _, _)  => begin
                    (inResNew, inInfoNew)
                  end
                end
              end
               #=  todo: check if the restrictions are the same for redeclared classes
               =#
          (outInfo, outRes)
        end

         #= @auhtor: adrpo
         set the name of the component =#
        function setComponentName(inE::Element, inName::Ident)::Element
              local outE::Element

              local n::Ident
              local pr::Prefixes
              local atr::Attributes
              local ts::Absyn.TypeSpec
              local cmt::Comment
              local cnd::Option
              local bc::Path
              local v::Visibility
              local m::Mod
              local a::Option
              local i::SourceInfo

              COMPONENT(n, pr, atr, ts, m, cmt, cnd, i) = inE
              outE = COMPONENT(inName, pr, atr, ts, m, cmt, cnd, i)
          outE
        end

        function isArrayComponent(inElement::Element)::Bool
              local outIsArray::Bool

              outIsArray = begin
                @match inElement begin
                  COMPONENT(attributes = ATTR(arrayDims = _ <| _))  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          outIsArray
        end

        function isEmptyMod(mod::Mod)::Bool
              local isEmpty::Bool

              isEmpty = begin
                @match mod begin
                  Mod.NOMOD()  => begin
                    true
                  end
                  
                  _  => begin
                      false
                  end
                end
              end
          isEmpty
        end

        function getConstrainingMod(element::SCode.Element)::SCode.Mod
              local mod::SCode.Mod

              mod = begin
                @match element begin
                  Element.CLASS(prefixes = Prefixes.PREFIXES(replaceablePrefix = Replaceable.REPLACEABLE(cc = SOME(ConstrainClass.CONSTRAINCLASS(modifier = mod)))))  => begin
                    mod
                  end
                  
                  Element.CLASS(classDef = ClassDef.DERIVED(modifications = mod))  => begin
                    mod
                  end
                  
                  Element.COMPONENT(prefixes = Prefixes.PREFIXES(replaceablePrefix = Replaceable.REPLACEABLE(cc = SOME(ConstrainClass.CONSTRAINCLASS(modifier = mod)))))  => begin
                    mod
                  end
                  
                  Element.COMPONENT(modifications = mod)  => begin
                    mod
                  end
                  
                  _  => begin
                      Mod.NOMOD()
                  end
                end
              end
          mod
        end

        function isEmptyClassDef(cdef::SCode.ClassDef)::Bool
              local isEmpty::Bool

              isEmpty = begin
                @match cdef begin
                  PARTS()  => begin
                    listEmpty(cdef.elementLst) && listEmpty(cdef.normalEquationLst) && listEmpty(cdef.initialEquationLst) && listEmpty(cdef.normalAlgorithmLst) && listEmpty(cdef.initialAlgorithmLst) && isNone(cdef.externalDecl)
                  end
                  
                  CLASS_EXTENDS()  => begin
                    isEmptyClassDef(cdef.composition)
                  end
                  
                  ENUMERATION()  => begin
                    listEmpty(cdef.enumLst)
                  end
                  
                  _  => begin
                      true
                  end
                end
              end
          isEmpty
        end

         #= Strips all annotations and/or comments from a program. =#
        function stripCommentsFromProgram(program::Program, stripAnnotations::Bool, stripComments::Bool)::Program


              program = list(stripCommentsFromElement(e, stripAnnotations, stripComments) for e in program)
          program
        end

        function stripCommentsFromElement(element::Element, stripAnn::Bool, stripCmt::Bool)::Element


              () = begin
                @match element begin
                  Element.EXTENDS()  => begin
                      if stripAnn
                        element.ann = NONE()
                      end
                      element.modifications = stripCommentsFromMod(element.modifications, stripAnn, stripCmt)
                    ()
                  end
                  
                  Element.CLASS()  => begin
                      element.classDef = stripCommentsFromClassDef(element.classDef, stripAnn, stripCmt)
                      element.cmt = stripCommentsFromComment(element.cmt, stripAnn, stripCmt)
                    ()
                  end
                  
                  Element.COMPONENT()  => begin
                      element.modifications = stripCommentsFromMod(element.modifications, stripAnn, stripCmt)
                      element.comment = stripCommentsFromComment(element.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  _  => begin
                      ()
                  end
                end
              end
          element
        end

        function stripCommentsFromMod(mod::Mod, stripAnn::Bool, stripCmt::Bool)::Mod


              () = begin
                @match mod begin
                  Mod.MOD()  => begin
                      mod.subModLst = list(stripCommentsFromSubMod(m, stripAnn, stripCmt) for m in mod.subModLst)
                    ()
                  end
                  
                  Mod.REDECL()  => begin
                      mod.element = stripCommentsFromElement(mod.element, stripAnn, stripCmt)
                    ()
                  end
                  
                  _  => begin
                      ()
                  end
                end
              end
          mod
        end

        function stripCommentsFromSubMod(submod::SubMod, stripAnn::Bool, stripCmt::Bool)::SubMod


              submod.mod = stripCommentsFromMod(submod.mod, stripAnn, stripCmt)
          submod
        end

        function stripCommentsFromClassDef(cdef::ClassDef, stripAnn::Bool, stripCmt::Bool)::ClassDef


              cdef = begin
                  local el::Lst
                  local eql::Lst
                  local ieql::Lst
                  local alg::Lst
                  local ialg::Lst
                  local ext::Option
                @match cdef begin
                  ClassDef.PARTS()  => begin
                      el = list(stripCommentsFromElement(e, stripAnn, stripCmt) for e in cdef.elementLst)
                      eql = list(stripCommentsFromEquation(eq, stripAnn, stripCmt) for eq in cdef.normalEquationLst)
                      ieql = list(stripCommentsFromEquation(ieq, stripAnn, stripCmt) for ieq in cdef.initialEquationLst)
                      alg = list(stripCommentsFromAlgorithm(a, stripAnn, stripCmt) for a in cdef.normalAlgorithmLst)
                      ialg = list(stripCommentsFromAlgorithm(ia, stripAnn, stripCmt) for ia in cdef.initialAlgorithmLst)
                      ext = stripCommentsFromExternalDecl(cdef.externalDecl, stripAnn, stripCmt)
                    ClassDef.PARTS(el, eql, ieql, alg, ialg, cdef.constraintLst, cdef.clsattrs, ext)
                  end
                  
                  ClassDef.CLASS_EXTENDS()  => begin
                      cdef.modifications = stripCommentsFromMod(cdef.modifications, stripAnn, stripCmt)
                      cdef.composition = stripCommentsFromClassDef(cdef.composition, stripAnn, stripCmt)
                    cdef
                  end
                  
                  ClassDef.DERIVED()  => begin
                      cdef.modifications = stripCommentsFromMod(cdef.modifications, stripAnn, stripCmt)
                    cdef
                  end
                  
                  ClassDef.ENUMERATION()  => begin
                      cdef.enumLst = list(stripCommentsFromEnum(e, stripAnn, stripCmt) for e in cdef.enumLst)
                    cdef
                  end
                  
                  _  => begin
                      cdef
                  end
                end
              end
          cdef
        end

        function stripCommentsFromEnum(enum::Enum, stripAnn::Bool, stripCmt::Bool)::Enum


              enum.comment = stripCommentsFromComment(enum.comment, stripAnn, stripCmt)
          enum
        end

        function stripCommentsFromComment(cmt::Comment, stripAnn::Bool, stripCmt::Bool)::Comment


              if stripAnn
                cmt.annotation_ = NONE()
              end
              if stripCmt
                cmt.comment = NONE()
              end
          cmt
        end

        function stripCommentsFromExternalDecl(extDecl::Option, stripAnn::Bool, stripCmt::Bool)::Option


              local ext_decl::ExternalDecl

              if isSome(extDecl) && stripAnn
                SOME(ext_decl) = extDecl
                ext_decl.annotation_ = NONE()
                extDecl = SOME(ext_decl)
              end
          extDecl
        end

        function stripCommentsFromEquation(eq::Equation, stripAnn::Bool, stripCmt::Bool)::Equation


              eq.eEquation = stripCommentsFromEEquation(eq.eEquation, stripAnn, stripCmt)
          eq
        end

        function stripCommentsFromEEquation(eq::EEquation, stripAnn::Bool, stripCmt::Bool)::EEquation


              () = begin
                @match eq begin
                  EEquation.EQ_IF()  => begin
                      eq.thenBranch = list(list(stripCommentsFromEEquation(e, stripAnn, stripCmt) for e in branch) for branch in eq.thenBranch)
                      eq.elseBranch = list(stripCommentsFromEEquation(e, stripAnn, stripCmt) for e in eq.elseBranch)
                      eq.comment = stripCommentsFromComment(eq.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  EEquation.EQ_EQUALS()  => begin
                      eq.comment = stripCommentsFromComment(eq.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  EEquation.EQ_PDE()  => begin
                      eq.comment = stripCommentsFromComment(eq.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  EEquation.EQ_CONNECT()  => begin
                      eq.comment = stripCommentsFromComment(eq.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  EEquation.EQ_FOR()  => begin
                      eq.eEquationLst = list(stripCommentsFromEEquation(e, stripAnn, stripCmt) for e in eq.eEquationLst)
                      eq.comment = stripCommentsFromComment(eq.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  EEquation.EQ_WHEN()  => begin
                      eq.eEquationLst = list(stripCommentsFromEEquation(e, stripAnn, stripCmt) for e in eq.eEquationLst)
                      eq.elseBranches = list(stripCommentsFromWhenEqBranch(b, stripAnn, stripCmt) for b in eq.elseBranches)
                      eq.comment = stripCommentsFromComment(eq.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  EEquation.EQ_ASSERT()  => begin
                      eq.comment = stripCommentsFromComment(eq.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  EEquation.EQ_TERMINATE()  => begin
                      eq.comment = stripCommentsFromComment(eq.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  EEquation.EQ_REINIT()  => begin
                      eq.comment = stripCommentsFromComment(eq.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  EEquation.EQ_NORETCALL()  => begin
                      eq.comment = stripCommentsFromComment(eq.comment, stripAnn, stripCmt)
                    ()
                  end
                end
              end
          eq
        end

        function stripCommentsFromWhenEqBranch(branch::Tuple, stripAnn::Bool, stripCmt::Bool)::Tuple


              local cond::Absyn.Exp
              local body::Lst

              (cond, body) = branch
              body = list(stripCommentsFromEEquation(e, stripAnn, stripCmt) for e in body)
              branch = (cond, body)
          branch
        end

        function stripCommentsFromAlgorithm(alg::AlgorithmSection, stripAnn::Bool, stripCmt::Bool)::AlgorithmSection


              alg.statements = list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in alg.statements)
          alg
        end

        function stripCommentsFromStatement(stmt::Statement, stripAnn::Bool, stripCmt::Bool)::Statement


              () = begin
                @match stmt begin
                  Statement.ALG_ASSIGN()  => begin
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end

                  Statement.ALG_IF()  => begin
                      stmt.trueBranch = list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.trueBranch)
                      stmt.elseIfBranch = list(stripCommentsFromStatementBranch(b, stripAnn, stripCmt) for b in stmt.elseIfBranch)
                      stmt.elseBranch = list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.elseBranch)
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_FOR()  => begin
                      stmt.forBody = list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.forBody)
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_PARFOR()  => begin
                      stmt.parforBody = list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.parforBody)
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_WHILE()  => begin
                      stmt.whileBody = list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.whileBody)
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_WHEN_A()  => begin
                      stmt.branches = list(stripCommentsFromStatementBranch(b, stripAnn, stripCmt) for b in stmt.branches)
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_ASSERT()  => begin
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_TERMINATE()  => begin
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_REINIT()  => begin
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_NORETCALL()  => begin
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_RETURN()  => begin
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_BREAK()  => begin
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_FAILURE()  => begin
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_TRY()  => begin
                      stmt.body = list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.body)
                      stmt.elseBody = list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in stmt.elseBody)
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                  
                  Statement.ALG_CONTINUE()  => begin
                      stmt.comment = stripCommentsFromComment(stmt.comment, stripAnn, stripCmt)
                    ()
                  end
                end
              end
          stmt
        end

        function stripCommentsFromStatementBranch(branch::Tuple, stripAnn::Bool, stripCmt::Bool)::Tuple


              local cond::Absyn.Exp
              local body::Lst

              (cond, body) = branch
              body = list(stripCommentsFromStatement(s, stripAnn, stripCmt) for s in body)
              branch = (cond, body)
          branch
        end

  end

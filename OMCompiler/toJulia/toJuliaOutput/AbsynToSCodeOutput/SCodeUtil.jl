module SCodeUtil


using MetaModelica

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
import SCode
import Flags
import List
import MetaUtil
import System
import Util
import MetaModelica.Dangerous
#=  Constant expression for AssertionLevel.error.
=#
Lst = MetaModelica.List

ASSERTION_LEVEL_ERROR = Absyn.CREF(Absyn.CREF_FULLYQUALIFIED(Absyn.CREF_QUAL("AssertionLevel", list(), Absyn.CREF_IDENT("error", list()))))::Absyn.Exp

#= This function takes an Absyn.Program
and constructs a SCode.Program from it.
This particular version of translate tries to fix any uniontypes
in the inProgram before translating further. This should probably
be moved into Parser.parse since you have to modify the tree every
single time you translate... =#
function translateAbsyn2SCode(inProgram::Absyn.Program)::SCode.Program
  local outProgram::SCode.Program

  outProgram = begin
    local spInitial::SCode.Program
    local sp::SCode.Program
    local inClasses::Lst
    local initialClasses::Lst
    @match inProgram begin
      _  => begin
        @match Absyn.PROGRAM(inClasses) = MetaUtil.createMetaClassesInProgram(inProgram)
      sp = list(translateClass(c) for c in inClasses)
      sp
      end
    end
  end
  #=  adrpo: TODO! FIXME! disable function caching for now as some tests fail.
  =#
  #=  setGlobalRoot(Ceval.cevalHashIndex, Ceval.emptyCevalHashTable());
  =#
  #=  set the external flag that signals the presence of inner/outer components in the model
  =#
  #=  set the external flag that signals the presence of expandable connectors in the model
  =#
  #=  set the external flag that signals the presence of overconstrained connectors in the model
  =#
  #=  set the external flag that signals the presence of expandable connectors in the model
  =#
  #=  translate given absyn to scode.
  =#
  #=  adrpo: note that WE DO NOT NEED to add initial functions to the program
  =#
  #=         as they are already part of the initialEnv done by Builtin.initialGraph
  =#
  outProgram
end

function translateClass(inClass::Absyn.Class)::SCode.Element
  local outClass::SCode.Element

  outClass = translateClass2(inClass, 0)
  outClass
end

#= This functions converts an Absyn.Class to a SCode.Class. =#
function translateClass2(inClass::Absyn.Class, inNumMessages::ModelicaInteger)::SCode.Element
  local outClass::SCode.Element

  outClass = begin
    local d_1::SCode.ClassDef
    local r_1::SCode.Restriction
    local c::Absyn.Class
    local n::String
    local p::Bool
    local f::Bool
    local e::Bool
    local r::Absyn.Restriction
    local d::Absyn.ClassDef
    local file_info::SourceInfo
    local scodeClass::SCode.Element
    local sFin::SCode.Final
    local sEnc::SCode.Encapsulated
    local sPar::SCode.Partial
    local cmt::SCode.Comment
    @matchcontinue (inClass, inNumMessages) begin
      (Absyn.CLASS(name = n, partialPrefix = p, finalPrefix = f, encapsulatedPrefix = e, restriction = r, body = d, info = file_info), _)  => begin
        c,
        r_1 = translateRestriction(c, r)
        (d_1, cmt) = translateClassdef(d, file_info, r_1)
        sFin = SCode.boolFinal(f)
        sEnc = SCode.boolEncapsulated(e)
        sPar = SCode.boolPartial(p)
        scodeClass = SCode.CLASS(n, SCode.PREFIXES(SCode.PUBLIC(), SCode.NOT_REDECLARE(), sFin, Absyn.NOT_INNER_OUTER(), SCode.NOT_REPLACEABLE()), sEnc, sPar, r_1, d_1, cmt, file_info)
        scodeClass
      end

      (Absyn.CLASS(name = n, info = file_info), _)  => begin
        @assert true == (intEq(0, inNumMessages))
        n = "SCodeUtil.translateClass2 failed: " + n
        fail()
      end
    end
  end
  #=  fprint(Flags.TRANSLATE, \"Translating class:\" + n + \"\\n\");
  =#
  #=  uniontype will not get translated!
  =#
  #=  here we set only final as is a top level class!
  =#
  #=  Print out an internal error msg only if no other errors have already
  =#
  #=  been printed.
  =#
  outClass
end

#= mahge: FIX HERE. Check for proper input and output
=#
#= declarations in operators according to the specifications.
=#

function translateOperatorDef(inClassDef::Absyn.ClassDef, operatorName::Absyn.Ident, info::SourceInfo)::Tuple{SCode.Comment, SCode.ClassDef}
  local cmt::SCode.Comment
  local outOperDef::SCode.ClassDef

  (outOperDef, cmt) = begin
    local cmtString::Option
    local els::Lst
    local anns::Lst
    local parts::Lst
    local scodeCmt::Option
    local opName::SCode.Ident
    local aann::Lst
    local ann::Option
    @match (inClassDef, operatorName, info) begin
      (Absyn.PARTS(parts, aann, cmtString), _, _)  => begin
        els = translateClassdefElements(parts)
        cmt = translateCommentList(aann, cmtString)
        (SCode.PARTS(els, list(), list(), list(), list(), list(), list(), NONE()), cmt)
      end

      _  => begin
        println("Error")
        fail()
      end
    end
  end
  (cmt, outOperDef)
end

function getOperatorGivenName(inOperatorFunction::SCode.Element)::Absyn.Path
  local outName::Absyn.Path

  outName = begin
    local name::SCode.Ident
    @match inOperatorFunction begin
      SCode.CLASS(name, _, _, _, SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()), _, _, _)  => begin
        Absyn.IDENT(name)
      end
    end
  end
  outName
end

function getOperatorQualName(inOperatorFunction::SCode.Element, operName::SCode.Ident)::SCode.Path
  local outName::SCode.Path

  outName = begin
    local name::SCode.Ident
    local opname::SCode.Ident
    @match (inOperatorFunction, operName) begin
      (SCode.CLASS(name, _, _, _, SCode.R_FUNCTION(_), _, _, _), opname)  => begin
        AbsynUtil.joinPaths(Absyn.IDENT(opname), Absyn.IDENT(name))
      end
    end
  end
  outName
end

function getListofQualOperatorFuncsfromOperator(inOperator::SCode.Element)::Lst
  local outNames::Lst

  outNames = begin
    local els::Lst
    local opername::SCode.Ident
    local names::Lst
    #= If operator get the list of functions in it.
    =#
    @match inOperator begin
      SCode.CLASS(opername, _, _, _, SCode.R_OPERATOR(), SCode.PARTS(elementLst = els), _, _)  => begin
        names = List.map1(els, getOperatorQualName, opername)
        names
      end

      SCode.CLASS(opername, _, _, _, SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()), _, _, _)  => begin
        names = list(Absyn.IDENT(opername))
        names
      end
    end
  end
  #= If operator function return its name
  =#
  outNames
end

function translatePurity(inPurity::Absyn.FunctionPurity)::Bool
  local outPurity::Bool
  outPurity = begin
    @match inPurity begin
      Absyn.IMPURE()  => begin
        true
      end
      _  => begin
        false
      end
    end
  end
  outPurity
end

#=  Changed to public! krsta
=#

#= Convert a class restriction. =#
function translateRestriction(inClass::Absyn.Class, inRestriction::Absyn.Restriction)::SCode.Restriction
  local outRestriction::SCode.Restriction

  outRestriction = begin
    local d::Absyn.Class
    local name::Absyn.Path
    local index::ModelicaInteger
    local singleton::Bool
    local isImpure::Bool
    local moved::Bool
    local purity::Absyn.FunctionPurity
    local typeVars::Lst
    #=  ?? Only normal functions can have 'external'
    =#
    @match (inClass, inRestriction) begin
      (d, Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(purity)))  => begin
        isImpure = translatePurity(purity)
        if containsExternalFuncDecl(d)
          SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(isImpure))
        else
          SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(isImpure))
        end
      end

      (_, Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION()))  => begin
        SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION())
      end

      (_, Absyn.R_FUNCTION(Absyn.FR_PARALLEL_FUNCTION()))  => begin
        SCode.R_FUNCTION(SCode.FR_PARALLEL_FUNCTION())
      end

      (_, Absyn.R_FUNCTION(Absyn.FR_KERNEL_FUNCTION()))  => begin
        SCode.R_FUNCTION(SCode.FR_KERNEL_FUNCTION())
      end

      (_, Absyn.R_CLASS())  => begin
        SCode.R_CLASS()
      end

      (_, Absyn.R_OPTIMIZATION())  => begin
        SCode.R_OPTIMIZATION()
      end

      (_, Absyn.R_MODEL())  => begin
        SCode.R_MODEL()
      end

      (_, Absyn.R_RECORD())  => begin
        SCode.R_RECORD(false)
      end

      (_, Absyn.R_OPERATOR_RECORD())  => begin
        SCode.R_RECORD(true)
      end

      (_, Absyn.R_BLOCK())  => begin
        SCode.R_BLOCK()
      end

      (_, Absyn.R_CONNECTOR())  => begin
        SCode.R_CONNECTOR(false)
      end

      (_, Absyn.R_EXP_CONNECTOR())  => begin
        System.setHasExpandableConnectors(true)
        SCode.R_CONNECTOR(true)
      end

      (_, Absyn.R_OPERATOR())  => begin
        SCode.R_OPERATOR()
      end

      (_, Absyn.R_TYPE())  => begin
        SCode.R_TYPE()
      end

      (_, Absyn.R_PACKAGE())  => begin
        SCode.R_PACKAGE()
      end

      (_, Absyn.R_ENUMERATION())  => begin
        SCode.R_ENUMERATION()
      end

      (_, Absyn.R_PREDEFINED_INTEGER())  => begin
        SCode.R_PREDEFINED_INTEGER()
      end

      (_, Absyn.R_PREDEFINED_REAL())  => begin
        SCode.R_PREDEFINED_REAL()
      end

      (_, Absyn.R_PREDEFINED_STRING())  => begin
        SCode.R_PREDEFINED_STRING()
      end

      (_, Absyn.R_PREDEFINED_BOOLEAN())  => begin
        SCode.R_PREDEFINED_BOOLEAN()
      end

      (_, Absyn.R_PREDEFINED_CLOCK())  => begin
        SCode.R_PREDEFINED_CLOCK()
      end

      (_, Absyn.R_PREDEFINED_ENUMERATION())  => begin
        SCode.R_PREDEFINED_ENUMERATION()
      end

      (_, Absyn.R_METARECORD(name, index, singleton, moved, typeVars))  => begin
        SCode.R_METARECORD(name, index, singleton, moved, typeVars)
      end

      (Absyn.CLASS(Absyn.PARTS(typeVars)), Absyn.R_UNIONTYPE())  => begin
        SCode.R_UNIONTYPE(typeVars)
      end

      (_, Absyn.R_UNIONTYPE())  => begin
        SCode.R_UNIONTYPE(list())
      end
    end
  end
  #=  BTH
  =#
  #= MetaModelica extension, added by x07simbj
  =#
  #= /*MetaModelica extension added by x07simbj */ =#
  #= /*MetaModelica extension added by x07simbj */ =#
  outRestriction
end

#= Returns true if the Absyn.Class contains an external function declaration. =#
function containsExternalFuncDecl(inClass::Absyn.Class)::Bool
  local outBoolean::Bool

  outBoolean = begin
    local res::Bool
    local b::Bool
    local c::Bool
    local d::Bool
    local a::String
    local e::Absyn.Restriction
    local rest::Lst
    local cmt::Option
    local file_info::SourceInfo
    local ann::Lst
    @match inClass begin
      Absyn.CLASS(Absyn.PARTS(classParts = Absyn.EXTERNAL() <| _))  => begin
        true
      end

      Absyn.CLASS(a, b, c, d, e, Absyn.PARTS(_ <| rest, cmt, ann), file_info)  => begin
        containsExternalFuncDecl(Absyn.CLASS(a, b, c, d, e, Absyn.PARTS(list(), list(), rest, ann, cmt), file_info))
      end

      Absyn.CLASS(Absyn.CLASS_EXTENDS(parts = Absyn.EXTERNAL() <| _))  => begin
        true
      end

      Absyn.CLASS(a, b, c, d, e, Absyn.CLASS_EXTENDS(_ <| rest, cmt, ann), file_info)  => begin
        containsExternalFuncDecl(Absyn.CLASS(a, b, c, d, e, Absyn.PARTS(list(), list(), rest, ann, cmt), file_info))
      end

      _  => begin
        false
      end
    end
  end
  #= /* adrpo: handling also the case model extends X external ... end X; */ =#
  #= /* adrpo: handling also the case model extends X external ... end X; */ =#
  outBoolean
end

#= @author: adrpo
translates from Absyn.ElementAttributes to SCode.Attributes =#
function translateAttributes(inEA::Absyn.ElementAttributes, extraArrayDim::Absyn.ArrayDim)::SCode.Attributes
  local outA::SCode.Attributes

  outA = begin
    local f::Bool
    local s::Bool
    local v::Absyn.Variability
    local p::Absyn.Parallelism
    local adim::Absyn.ArrayDim
    local extraADim::Absyn.ArrayDim
    local dir::Absyn.Direction
    local fi::Absyn.IsField
    local ct::SCode.ConnectorType
    local sp::SCode.Parallelism
    local sv::SCode.Variability
    @match (inEA, extraArrayDim) begin
      (Absyn.ATTR(f, s, p, v, dir, fi, adim), extraADim)  => begin
        ct = translateConnectorType(f, s)
        sv = translateVariability(v)
        sp = translateParallelism(p)
        adim = listAppend(extraADim, adim)
        SCode.ATTR(adim, ct, sp, sv, dir, fi)
      end
    end
  end
  outA
end

function translateConnectorType(inFlow::Bool, inStream::Bool)::SCode.ConnectorType
  local outType::SCode.ConnectorType

  outType = begin
    @match (inFlow, inStream) begin
      (false, false)  => begin
        SCode.POTENTIAL()
      end

      (true, false)  => begin
        SCode.FLOW()
      end

      (false, true)  => begin
        SCode.STREAM()
      end

      (true, true)  => begin
        fail()
      end
    end
  end
  #=  Both flow and stream is not allowed by the grammar, so this shouldn't be
  =#
  #=  possible.
  =#
  outType
end

#= This function converts an Absyn.ClassDef to a SCode.ClassDef.
For the DERIVED case, the conversion is fairly trivial, but for
the PARTS case more work is needed.
The result contains separate lists for:
elements, equations and algorithms, which are mixed in the input.
LS: Divided the translateClassdef into separate functions for collecting the different parts =#
function translateClassdef(inClassDef::Absyn.ClassDef, info::SourceInfo, re::SCode.Restriction)::Tuple{SCode.Comment, SCode.ClassDef}
  local outComment::SCode.Comment
  local outClassDef::SCode.ClassDef

  (outClassDef, outComment) = begin
    local mod::SCode.Mod
    local t::Absyn.TypeSpec
    local attr::Absyn.ElementAttributes
    local a::Lst
    local cmod::Lst
    local cmt::Option
    local cmtString::Option
    local els::Lst
    local tvels::Lst
    local anns::Lst
    local eqs::Lst
    local initeqs::Lst
    local als::Lst
    local initals::Lst
    local cos::Lst
    local decl::Option
    local parts::Lst
    local vars::Lst
    local lst_1::Lst
    local lst::Lst
    local scodeCmt::SCode.Comment
    local path::Absyn.Path
    local pathLst::Lst
    local typeVars::Lst
    local scodeAttr::SCode.Attributes
    local classAttrs::Lst
    local ann::Lst
    @match (inClassDef, info) begin
      (Absyn.DERIVED(t, attr, a, cmt), _)  => begin
        checkTypeSpec(t, info)
        mod = translateMod(SOME(Absyn.CLASSMOD(a, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info) #= TODO: attributes of derived classes =#
        scodeAttr = translateAttributes(attr, list())
        scodeCmt = translateComment(cmt)
        (SCode.DERIVED(t, mod, scodeAttr), scodeCmt)
      end

      (Absyn.PARTS(typeVars, classAttrs, parts, ann, cmtString), _)  => begin
        typeVars = begin
          @match re begin
            SCode.R_METARECORD()  => begin
              List.union(typeVars, re.typeVars)
            end

            SCode.R_UNIONTYPE()  => begin
              List.union(typeVars, re.typeVars)
            end

            _  => begin
              typeVars
            end
          end
        end
        tvels = List.map1(typeVars, makeTypeVarElement, info)
        els = translateClassdefElements(parts)
        els = listAppend(tvels, els)
        eqs = translateClassdefEquations(parts)
        initeqs = translateClassdefInitialequations(parts)
        als = translateClassdefAlgorithms(parts)
        initals = translateClassdefInitialalgorithms(parts)
        cos = translateClassdefConstraints(parts)
        scodeCmt = translateCommentList(ann, cmtString)
        decl = translateClassdefExternaldecls(parts)
        decl = translateAlternativeExternalAnnotation(decl, scodeCmt)
        (SCode.PARTS(els, eqs, initeqs, als, initals, cos, classAttrs, decl), scodeCmt)
      end

      (Absyn.ENUMERATION(Absyn.ENUMLITERALS(lst), cmt), _)  => begin
        lst_1 = translateEnumlist(lst)
        scodeCmt = translateComment(cmt)
        (SCode.ENUMERATION(lst_1), scodeCmt)
      end

      (Absyn.ENUMERATION(Absyn.ENUM_COLON(), cmt), _)  => begin
        scodeCmt = translateComment(cmt)
        (SCode.ENUMERATION(list()), scodeCmt)
      end

      (Absyn.OVERLOAD(pathLst, cmt), _)  => begin
        scodeCmt = translateComment(cmt)
        (SCode.OVERLOAD(pathLst), scodeCmt)
      end

      (Absyn.CLASS_EXTENDS(cmod, ann, cmtString, parts), _)  => begin
        els = translateClassdefElements(parts)
        eqs = translateClassdefEquations(parts)
        initeqs = translateClassdefInitialequations(parts)
        als = translateClassdefAlgorithms(parts)
        initals = translateClassdefInitialalgorithms(parts)
        cos = translateClassdefConstraints(parts)
        mod = translateMod(SOME(Absyn.CLASSMOD(cmod, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), AbsynUtil.dummyInfo)
        scodeCmt = translateCommentList(ann, cmtString)
        decl = translateClassdefExternaldecls(parts)
        decl = translateAlternativeExternalAnnotation(decl, scodeCmt)
        (SCode.CLASS_EXTENDS(mod, SCode.PARTS(els, eqs, initeqs, als, initals, cos, list(), decl)), scodeCmt)
      end

      (Absyn.PDER(path, vars, cmt), _)  => begin
        scodeCmt = translateComment(cmt)
        (SCode.PDER(path, vars), scodeCmt)
      end

      _  => begin
        println("Error")
        fail()
      end
    end
  end
  #=  fprintln(Flags.TRANSLATE, \"translating derived class: \" + Dump.unparseTypeSpec(t));
  =#
  #=  fprintln(Flags.TRANSLATE, \"translating class parts\");
  =#
  #=  fprintln(Flags.TRANSLATE, \"translating enumerations\");
  =#
  #=  fprintln(Flags.TRANSLATE, \"translating enumeration of ':'\");
  =#
  #=  fprintln(Flags.TRANSLATE, \"translating overloaded\");
  =#
  #=  fprintln(Flags.TRANSLATE \"translating model extends \" + name + \" ... end \" + name + \";\");
  =#
  #=  fprintln(Flags.TRANSLATE, \"translating pder( \" + AbsynUtil.pathString(path) + \", vars)\");
  =#
  (outComment, outClassDef)
end

#= first class annotation instead, since it is very common that an element
annotation is used for this purpose.
For instance, instead of external \\\"C\\\" annotation(Library=\\\"foo.lib\\\";
it says external \\\"C\\\" ; annotation(Library=\\\"foo.lib\\\"; =#
function translateAlternativeExternalAnnotation(decl::Option, comment::SCode.Comment)::Option
  local outDecl::Option

  outDecl = begin
    local name::Option
    local l::Option
    local out::Option
    local a::Lst
    local ann1::Option
    local ann2::Option
    local ann::Option
    #=  none
    =#
    @match (decl, comment) begin
      (NONE(), _)  => begin
        NONE()
      end

      (SOME(SCode.EXTERNALDECL(name, l, out, a, ann1)), SCode.COMMENT(annotation_ = ann2))  => begin
        ann = mergeSCodeOptAnn(ann1, ann2)
        SOME(SCode.EXTERNALDECL(name, l, out, a, ann))
      end
    end
  end
  #=  Else, merge
  =#
  outDecl
end

function mergeSCodeAnnotationsFromParts(part::Absyn.ClassPart, inMod::Option)::Option
  local outMod::Option

  outMod = begin
    local aann::Absyn.Annotation
    local ann::Option
    local rest::Lst
    @match (part, inMod) begin
      (Absyn.EXTERNAL(_, SOME(aann)), _)  => begin
        ann = translateAnnotation(aann)
        ann = mergeSCodeOptAnn(ann, inMod)
        ann
      end

      (Absyn.PUBLIC(_ <| rest), _)  => begin
        mergeSCodeAnnotationsFromParts(Absyn.PUBLIC(rest), inMod)
      end

      (Absyn.PROTECTED(_ <| rest), _)  => begin
        mergeSCodeAnnotationsFromParts(Absyn.PROTECTED(rest), inMod)
      end

      _  => begin
        inMod
      end
    end
  end
  outMod
end

#= Convert an EnumLiteral list to an Ident list.
Comments are lost. =#
function translateEnumlist(inAbsynEnumLiteralLst::Lst)::Lst
  local outEnumLst::Lst

  outEnumLst = begin
    local res::Lst
    local id::String
    local cmtOpt::Option
    local cmt::SCode.Comment
    local rest::Lst
    @match inAbsynEnumLiteralLst begin
      nil()  => begin
        list()
      end

      Absyn.ENUMLITERAL(id, cmtOpt) <| rest  => begin
        cmt = translateComment(cmtOpt)
        res = translateEnumlist(rest)
        SCode.ENUM(id, cmt) <| res
      end
    end
  end
  outEnumLst
end

#= Convert an Absyn.ClassPart list to an Element list. =#
function translateClassdefElements(inAbsynClassPartLst::Lst)::Lst
  local outElementLst::Lst

  outElementLst = begin
    local els::Lst
    local es_1::Lst
    local els_1::Lst
    local es::Lst
    local rest::Lst
    @match inAbsynClassPartLst begin
      nil()  => begin
        list()
      end

      Absyn.PUBLIC(contents = es) <| rest  => begin
        es_1 = translateEitemlist(es, SCode.PUBLIC())
        els = translateClassdefElements(rest)
        els = listAppend(es_1, els)
        els
      end

      Absyn.PROTECTED(contents = es) <| rest  => begin
        es_1 = translateEitemlist(es, SCode.PROTECTED())
        els = translateClassdefElements(rest)
        els = listAppend(es_1, els)
        els
      end

      _ <| rest  => begin
        translateClassdefElements(rest)
      end
    end
  end
  #= /* ignore all other than PUBLIC and PROTECTED, i.e. elements */ =#
  outElementLst
end

#= Convert an Absyn.ClassPart list to an Equation list. =#
function translateClassdefEquations(inAbsynClassPartLst::Lst)::Lst
  local outEquationLst::Lst

  outEquationLst = begin
    local eqs::Lst
    local eql_1::Lst
    local eqs_1::Lst
    local eql::Lst
    local rest::Lst
    @match inAbsynClassPartLst begin
      nil()  => begin
        list()
      end

      Absyn.EQUATIONS(eql) <| rest  => begin
        eql_1 = translateEquations(eql, false)
        eqs = translateClassdefEquations(rest)
        eqs_1 = listAppend(eqs, eql_1)
        eqs_1
      end

      _ <| rest  => begin
        eqs = translateClassdefEquations(rest)
        eqs
      end
    end
  end
  #= /* ignore everthing other than equations */ =#
  outEquationLst
end

#= Convert an Absyn.ClassPart list to an initial Equation list. =#
function translateClassdefInitialequations(inAbsynClassPartLst::Lst)::Lst
  local outEquationLst::Lst

  outEquationLst = begin
    local eqs::Lst
    local eql_1::Lst
    local eqs_1::Lst
    local eql::Lst
    local rest::Lst
    @match inAbsynClassPartLst begin
      nil()  => begin
        list()
      end

      Absyn.INITIALEQUATIONS(eql) <| rest  => begin
        eql_1 = translateEquations(eql, true)
        eqs = translateClassdefInitialequations(rest)
        eqs_1 = listAppend(eqs, eql_1)
        eqs_1
      end

      _ <| rest  => begin
        eqs = translateClassdefInitialequations(rest)
        eqs
      end
    end
  end
  #= /* ignore everthing other than equations */ =#
  outEquationLst
end

#= Convert an Absyn.ClassPart list to an Algorithm list. =#
function translateClassdefAlgorithms(inAbsynClassPartLst::Lst)::Lst
  local outAlgorithmLst::Lst

  outAlgorithmLst = begin
    local als::Lst
    local als_1::Lst
    local al_1::Lst
    local al::Lst
    local rest::Lst
    local cp::Absyn.ClassPart
    @match inAbsynClassPartLst begin
      nil()  => begin
        list()
      end

      Absyn.ALGORITHMS(al) <| rest  => begin
        al_1 = translateClassdefAlgorithmitems(al)
        als = translateClassdefAlgorithms(rest)
        als_1 = SCode.ALGORITHM(al_1) <| als
        als_1
      end

      cp <| rest  => begin
        throw("Absyn.ALGORITHMS() = cp")
        als = translateClassdefAlgorithms(rest)
        als
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        println("- SCodeUtil.translateClassdefAlgorithms failed\n")
        fail()
      end
    end
  end
  #= /* ignore everthing other than algorithms */ =#
  outAlgorithmLst
end

#= Convert an Absyn.ClassPart list to an Constraint list. =#
function translateClassdefConstraints(inAbsynClassPartLst::Lst)::Lst
  local outConstraintLst::Lst

  outConstraintLst = begin
    local cos::Lst
    local cos_1::Lst
    local consts::Lst
    local rest::Lst
    local cp::Absyn.ClassPart
    @match inAbsynClassPartLst begin
      nil()  => begin
        list()
      end

      Absyn.CONSTRAINTS(consts) <| rest  => begin
        cos = translateClassdefConstraints(rest)
        cos_1 = SCode.CONSTRAINTS(consts) <| cos
        cos_1
      end

      cp <| rest  => begin
        throw("Absyn.CONSTRAINTS() = cp")
        cos = translateClassdefConstraints(rest)
        cos
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        println("- SCodeUtil.translateClassdefConstraints failed\n")
        fail()
      end
    end
  end
  #= /* ignore everthing other than Constraints */ =#
  outConstraintLst
end

#= Convert an Absyn.ClassPart list to an initial Algorithm list. =#
function translateClassdefInitialalgorithms(inAbsynClassPartLst::Lst)::Lst
  local outAlgorithmLst::Lst

  outAlgorithmLst = begin
    local als::Lst
    local als_1::Lst
    local stmts::Lst
    local al::Lst
    local rest::Lst
    @match inAbsynClassPartLst begin
      nil()  => begin
        list()
      end

      Absyn.INITIALALGORITHMS(al) <| rest  => begin
        stmts = translateClassdefAlgorithmitems(al)
        als = translateClassdefInitialalgorithms(rest)
        als_1 = SCode.ALGORITHM(stmts) <| als
        als_1
      end

      _ <| rest  => begin
        als = translateClassdefInitialalgorithms(rest)
        als
      end
    end
  end
  #= /* ignore everthing other than algorithms */ =#
  outAlgorithmLst
end

function translateClassdefAlgorithmitems(inStatements::Lst)::Lst
  local outStatements::Lst

  outStatements = list(translateClassdefAlgorithmItem(stmt) for stmt in inStatements if AbsynUtil.isAlgorithmItem(stmt))
  outStatements
end

#= Translates an Absyn algorithm (statement) into SCode statement. =#
function translateClassdefAlgorithmItem(inAlgorithm::Absyn.AlgorithmItem)::SCode.Statement
  local outStatement::SCode.Statement

  local absynComment::Option
  local comment::SCode.Comment
  local info::SourceInfo
  local alg::Absyn.Algorithm

  @match Absyn.ALGORITHMITEM(alg, absynComment, info) = inAlgorithm
  (comment, info) = translateCommentWithLineInfoChanges(absynComment, info)
  outStatement = begin
    local body::Lst
    local else_body::Lst
    local branches::Lst
    local iter_name::String
    local iter_range::Option
    local stmt::SCode.Statement
    local e1::Absyn.Exp
    local e2::Absyn.Exp
    local e3::Absyn.Exp
    local cr::Absyn.ComponentRef
    @match alg begin
      Absyn.ALG_ASSIGN()  => begin
        SCode.ALG_ASSIGN(alg.assignComponent, alg.value, comment, info)
      end

      Absyn.ALG_IF()  => begin
        body = translateClassdefAlgorithmitems(alg.trueBranch)
        else_body = translateClassdefAlgorithmitems(alg.elseBranch)
        branches = translateAlgBranches(alg.elseIfAlgorithmBranch)
        SCode.ALG_IF(alg.ifExp, body, branches, else_body, comment, info)
      end

      Absyn.ALG_FOR()  => begin
        body = translateClassdefAlgorithmitems(alg.forBody)
        #=  Convert for-loops with multiple iterators into nested for-loops.
        =#
        for i in listReverse(alg.iterators)
          (iter_name, iter_range) = translateIterator(i, info)
          body = list(SCode.ALG_FOR(iter_name, iter_range, body, comment, info))
        end
        listHead(body)
      end

      Absyn.ALG_PARFOR()  => begin
        body = translateClassdefAlgorithmitems(alg.parforBody)
        #=  Convert for-loops with multiple iterators into nested for-loops.
        =#
        for i in listReverse(alg.iterators)
          (iter_name, iter_range) = translateIterator(i, info)
          body = list(SCode.ALG_PARFOR(iter_name, iter_range, body, comment, info))
        end
        listHead(body)
      end

      Absyn.ALG_WHILE()  => begin
        body = translateClassdefAlgorithmitems(alg.whileBody)
        SCode.ALG_WHILE(alg.boolExpr, body, comment, info)
      end

      Absyn.ALG_WHEN_A()  => begin
        branches = translateAlgBranches((alg.boolExpr, alg.whenBody) <| alg.elseWhenAlgorithmBranch)
        SCode.ALG_WHEN_A(branches, comment, info)
      end

      Absyn.ALG_NORETCALL(Absyn.CREF_IDENT(name = "assert"), Absyn.FUNCTIONARGS((e1 <| e2 <| nil()), nil()))  => begin
        SCode.ALG_ASSERT(e1, e2, ASSERTION_LEVEL_ERROR, comment, info)
      end

      Absyn.ALG_NORETCALL(Absyn.CREF_IDENT(name = "assert"), Absyn.FUNCTIONARGS((e1 <| e2 <| e3 <| nil()), nil()))  => begin
        SCode.ALG_ASSERT(e1, e2, e3, comment, info)
      end

      Absyn.ALG_NORETCALL(Absyn.CREF_IDENT(name = "assert"), Absyn.FUNCTIONARGS((e1 <| e2 <| nil()), Absyn.NAMEDARG("level", e3) <|  nil()))  => begin
        SCode.ALG_ASSERT(e1, e2, e3, comment, info)
      end

      Absyn.ALG_NORETCALL(Absyn.CREF_IDENT(name = "terminate"), Absyn.FUNCTIONARGS((e1 <| nil()), nil()))  => begin
        SCode.ALG_TERMINATE(e1, comment, info)
      end

      Absyn.ALG_NORETCALL(Absyn.CREF_IDENT(name = "reinit"), Absyn.FUNCTIONARGS((e1 <| e2 <| nil()), nil()))  => begin
        SCode.ALG_REINIT(e1, e2, comment, info)
      end

      Absyn.ALG_NORETCALL()  => begin
        #=  assert(condition, message)
        =#
        #=  assert(condition, message, level)
        =#
        #=  assert(condition, message, level = arg)
        =#
        e1 = Absyn.CALL(alg.functionCall, alg.functionArgs)
        SCode.ALG_NORETCALL(e1, comment, info)
      end

      Absyn.ALG_FAILURE()  => begin
        body = translateClassdefAlgorithmitems(alg.equ)
        SCode.ALG_FAILURE(body, comment, info)
      end

      Absyn.ALG_TRY()  => begin
        body = translateClassdefAlgorithmitems(alg.body)
        else_body = translateClassdefAlgorithmitems(alg.elseBody)
        SCode.ALG_TRY(body, else_body, comment, info)
      end

      Absyn.ALG_RETURN()  => begin
        SCode.ALG_RETURN(comment, info)
      end

      Absyn.ALG_BREAK()  => begin
        SCode.ALG_BREAK(comment, info)
      end

      Absyn.ALG_CONTINUE()  => begin
        SCode.ALG_CONTINUE(comment, info)
      end

      _  => begin
        println("Error")
        fail()
      end
    end
  end
  outStatement
end

#= Translates the elseif or elsewhen branches from Absyn to SCode form. =#
function translateAlgBranches(inBranches::Lst)::Lst
  local outBranches::Lst

  local condition::Absyn.Exp
  local body::Lst

  outBranches = list(begin
                     @match branch begin
                     (condition, body)  => begin
                     (condition, translateClassdefAlgorithmitems(body))
                     end
                     end
                     end for branch in inBranches)
  outBranches
end

#= Converts an Absyn.ClassPart list to an SCode.ExternalDecl option.
The list should only contain one external declaration, so pick the first one. =#
function translateClassdefExternaldecls(inAbsynClassPartLst::Lst)::Option
  local outAbsynExternalDeclOption::Option

  outAbsynExternalDeclOption = begin
    local res::Option
    local rest::Lst
    local fn_name::Option
    local lang::Option
    local output_::Option
    local args::Lst
    local aann::Option
    local sann::Option
    @match inAbsynClassPartLst begin
      Absyn.EXTERNAL(externalDecl = Absyn.EXTERNALDECL(fn_name, lang, output_, args, aann)) <| _  => begin
        sann = translateAnnotationOpt(aann)
        SOME(SCode.EXTERNALDECL(fn_name, lang, output_, args, sann))
      end

      _ <| rest  => begin
        res = translateClassdefExternaldecls(rest)
        res
      end

      nil()  => begin
        NONE()
      end
    end
  end
  outAbsynExternalDeclOption
end

#= This function converts a list of Absyn.ElementItem to a list of SCode.Element.
The boolean argument flags whether the elements are protected.
Annotations are not translated, i.e. they are removed when converting to SCode. =#
function translateEitemlist(inAbsynElementItemLst::Lst, inVisibility::SCode.Visibility = SCode.PUBLIC())::Lst
  local outElementLst::Lst

  local l::Lst = list()
  local es::Lst = inAbsynElementItemLst
  local ei::Absyn.ElementItem
  local vis::SCode.Visibility
  local e::Absyn.Element

  for ei in es
    _ = begin
      local e_1::Lst
      @match ei begin
        Absyn.ELEMENTITEM(e)  => begin
          e_1 = translateElement(e, inVisibility)
          l = List.append_reverse(e_1, l)
          ()
        end
        _  => begin
          ()
        end
      end
    end
  end
  #=  fprintln(Flags.TRANSLATE, \"translating element: \" + Dump.unparseElementStr(1, e));
  =#
  outElementLst = Dangerous.listReverseInPlace(l)
  outElementLst
end

#=  stefan
=#

#= translates an Absyn.Annotation into an SCode.Annotation =#
function translateAnnotation(inAnnotation::Absyn.Annotation)::Option
  local outAnnotation::Option

  outAnnotation = begin
    local args::Lst
    local m::SCode.Mod
    @match inAnnotation begin
      Absyn.ANNOTATION(nil())  => begin
        NONE()
      end

      Absyn.ANNOTATION(args)  => begin
        m = translateMod(SOME(Absyn.CLASSMOD(args, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), AbsynUtil.dummyInfo)
        if SCode.isEmptyMod(m)
          NONE()
        else
          SOME(SCode.ANNOTATION(m))
        end
      end
    end
  end
  outAnnotation
end

function translateAnnotationOpt(absynAnnotation::Option)::Option
  local scodeAnnotation::Option

  scodeAnnotation = begin
    local ann::Absyn.Annotation
    @match absynAnnotation begin
      SOME(ann)  => begin
        translateAnnotation(ann)
      end
      _  => begin
        NONE()
      end
    end
  end
  scodeAnnotation
end

#= This function converts an Absyn.Element to a list of SCode.Element.
The original element may declare several components at once, and
those are separated to several declarations in the result. =#
function translateElement(inElement::Absyn.Element, inVisibility::SCode.Visibility)::Lst
  local outElementLst::Lst
  outElementLst = begin
    local es::Lst
    local f::Bool
    local repl::Option
    local s::Absyn.ElementSpec
    local io::Absyn.InnerOuter
    local info::SourceInfo
    local cc::Option
    local expOpt::Option
    local weightOpt::Option
    local args::Lst
    local name::String
    local vis::SCode.Visibility
    @match (inElement, inVisibility) begin
      (Absyn.ELEMENT(cc, f, io, repl, s, info), vis)  => begin
        es = translateElementspec(cc, f, io, repl, vis, s, info)
        es
      end
      (Absyn.DEFINEUNIT(name, args), vis)  => begin
        expOpt = translateDefineunitParam(args, "exp")
        weightOpt = translateDefineunitParam2(args, "weight")
        list(SCode.DEFINEUNIT(name, vis, expOpt, weightOpt))
      end
    end
  end
  outElementLst
end

#=  help function to translateElement =#
function translateDefineunitParam(inArgs::Lst, inArg::String)::Option
  local expOpt::Option

  expOpt = begin
    local str::String
    local name::String
    local arg::String
    local args::Lst
    @matchcontinue (inArgs, inArg) begin
      (Absyn.NAMEDARG(name, Absyn.STRING(str)) <| _, arg)  => begin
        @assert true == (name == arg)
        SOME(str)
      end

      ( nil(), _)  => begin
        NONE()
      end

      (_ <| args, arg)  => begin
        translateDefineunitParam(args, arg)
      end
    end
  end
  expOpt
end

#=  help function to translateElement =#
function translateDefineunitParam2(inArgs::Lst, inArg::String)::Option
  local weightOpt::Option

  weightOpt = begin
    local name::String
    local arg::String
    local s::String
    local r::ModelicaReal
    local args::Lst
    @matchcontinue (inArgs, inArg) begin
      (Absyn.NAMEDARG(name, Absyn.REAL(s)) <| _, arg)  => begin
        @assert true == (name == arg)
        r = System.stringReal(s)
        SOME(r)
      end

      ( nil(), _)  => begin
        NONE()
      end

      (_ <| args, arg)  => begin
        translateDefineunitParam2(args, arg)
      end
    end
  end
  weightOpt
end

#= This function turns an Absyn.ElementSpec to a list of SCode.Element.
The boolean arguments say if the element is final and protected, respectively. =#
function translateElementspec(cc::Option, finalPrefix::Bool, io::Absyn.InnerOuter, inRedeclareKeywords::Option, inVisibility::SCode.Visibility, inElementSpec4::Absyn.ElementSpec, inInfo::SourceInfo)::Lst
  local outElementLst::Lst

  outElementLst = begin
    local de_1::SCode.ClassDef
    local re_1::SCode.Restriction
    local rp::Bool
    local pa::Bool
    local fi::Bool
    local e::Bool
    local repl_1::Bool
    local fl::Bool
    local st::Bool
    local redecl::Bool
    local repl::Option
    local cl::Absyn.Class
    local n::String
    local re::Absyn.Restriction
    local de::Absyn.ClassDef
    local mod::SCode.Mod
    local args::Lst
    local xs_1::Lst
    local prl1::SCode.Parallelism
    local var1::SCode.Variability
    local tot_dim::Lst
    local ad::Lst
    local d::Lst
    local attr::Absyn.ElementAttributes
    local di::Absyn.Direction
    local isf::Absyn.IsField
    local t::Absyn.TypeSpec
    local m::Option
    local comment::Option
    local cmt::SCode.Comment
    local xs::Lst
    local imp::Absyn.Import
  local cond::Option
    local path::Absyn.Path
    local absann::Absyn.Annotation
    local ann::Option
    local variability::Absyn.Variability
    local parallelism::Absyn.Parallelism
    local i::SourceInfo
    local info::SourceInfo
    local cls::SCode.Element
    local sRed::SCode.Redeclare
    local sFin::SCode.Final
    local sRep::SCode.Replaceable
    local sEnc::SCode.Encapsulated
    local sPar::SCode.Partial
    local vis::SCode.Visibility
    local ct::SCode.ConnectorType
    local prefixes::SCode.Prefixes
    local scc::Option
    @match (cc, finalPrefix, io, inRedeclareKeywords, inVisibility, inElementSpec4, inInfo) begin
      (_, _, _, repl, vis, Absyn.CLASSDEF(rp, Absyn.CLASS(n, pa, e, Absyn.R_OPERATOR(), de, i)), _)  => begin
        (de_1, cmt) = translateOperatorDef(de, n, i)
        (_, redecl) = translateRedeclarekeywords(repl)
        sRed = SCode.boolRedeclare(redecl)
        sFin = SCode.boolFinal(finalPrefix)
        scc = translateConstrainClass(cc)
        sRep = if rp
          SCode.REPLACEABLE(scc)
        else
          SCode.NOT_REPLACEABLE()
        end
        sEnc = SCode.boolEncapsulated(e)
        sPar = SCode.boolPartial(pa)
        cls = SCode.CLASS(n, SCode.PREFIXES(vis, sRed, sFin, io, sRep), sEnc, sPar, SCode.R_OPERATOR(), de_1, cmt, i)
        list(cls)
      end

      (_, _, _, repl, vis, Absyn.CLASSDEF(rp, Absyn.CLASS(n, pa, e, re, de, i)), _)  => begin
        cl = Absyn.CLASS(n, pa, e, re, de, i)
        re_1 = translateRestriction(cl, re)
        (de_1, cmt) = translateClassdef(de, i, re_1)
        (_, redecl) = translateRedeclarekeywords(repl)
        sRed = SCode.boolRedeclare(redecl)
        sFin = SCode.boolFinal(finalPrefix)
        scc = translateConstrainClass(cc)
        sRep = if rp
          SCode.REPLACEABLE(scc)
        else
          SCode.NOT_REPLACEABLE()
        end
        sEnc = SCode.boolEncapsulated(e)
        sPar = SCode.boolPartial(pa)
        cls = SCode.CLASS(n, SCode.PREFIXES(vis, sRed, sFin, io, sRep), sEnc, sPar, re_1, de_1, cmt, i)
        list(cls)
      end

      (_, _, _, _, vis, Absyn.EXTENDS(path, args, NONE()), info)  => begin
        mod = translateMod(SOME(Absyn.CLASSMOD(args, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), AbsynUtil.dummyInfo)
        list(SCode.EXTENDS(path, vis, mod, NONE(), info))
      end

      (_, _, _, _, vis, Absyn.EXTENDS(path, args, SOME(absann)), info)  => begin
        mod = translateMod(SOME(Absyn.CLASSMOD(args, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), AbsynUtil.dummyInfo)
        ann = translateAnnotation(absann)
        list(SCode.EXTENDS(path, vis, mod, ann, info))
      end

      (_, _, _, _, _, Absyn.COMPONENTS(components =  nil()), _)  => begin
        list()
      end

      (_, _, _, repl, vis, Absyn.COMPONENTS(Absyn.ATTR(fl, st, parallelism, variability, di, isf, ad), t), info)  => begin
        attributes = Absyn.ATTR(fl, st, parallelism, variability, di, isf, ad)
        #=  fprintln(Flags.TRANSLATE, \"translating local class: \" + n);
        =#
        #=  uniontype will not get translated!
        =#
        #=  fprintln(Flags.TRANSLATE, \"translating extends: \" + AbsynUtil.pathString(n));
        =#
        #=  fprintln(Flags.TRANSLATE, \"translating extends: \" + AbsynUtil.pathString(n));
        =#
        xs_1 = list()
        for comp in inElementSpec4.components
          @match Absyn.COMPONENTITEM(Absyn.COMPONENT(n, d, m), comment, cond) = comp
          checkTypeSpec(t, info)
          setHasInnerOuterDefinitionsHandler(io)
          setHasStreamConnectorsHandler(st)
          mod = translateMod(m, SCode.NOT_FINAL(), SCode.NOT_EACH(), info)
          prl1 = translateParallelism(parallelism)
          var1 = translateVariability(variability)
          tot_dim = listAppend(d, ad)
          (repl_1, redecl) = translateRedeclarekeywords(repl)
          (cmt, info) = translateCommentWithLineInfoChanges(comment, info)
          sFin = SCode.boolFinal(finalPrefix)
          sRed = SCode.boolRedeclare(redecl)
          scc = translateConstrainClass(cc)
          sRep = if repl_1
            SCode.REPLACEABLE(scc)
          else
            SCode.NOT_REPLACEABLE()
          end
          ct = translateConnectorType(fl, st)
          prefixes = SCode.PREFIXES(vis, sRed, sFin, io, sRep)
          xs_1 = begin
            #=  TODO: Improve performance by iterating over all elements at once instead of creating a new Absyn.COMPONENTS in each step...
            =#
            #=  fprintln(Flags.TRANSLATE, \"translating component: \" + n + \" final: \" + SCode.finalStr(SCode.boolFinal(finalPrefix)));
            =#
            #=  signal the external flag that we have inner/outer definitions
            =#
            #=  signal the external flag that we have stream connectors
            =#
            #=  PR. This adds the arraydimension that may be specified together with the type of the component.
            =#
            local attr1::SCode.Attributes
            local attr2::SCode.Attributes
            local mod2::SCode.Mod
            local inName::String
            @match di begin
              Absyn.INPUT_OUTPUT() where (! Flags.isSet(Flags.SKIP_INPUT_OUTPUT_SYNTACTIC_SUGAR))  => begin
                inName = "in_" + n
                attr1 = SCode.ATTR(tot_dim, ct, prl1, var1, Absyn.INPUT(), isf)
                attr2 = SCode.ATTR(tot_dim, ct, prl1, var1, Absyn.OUTPUT(), isf)
                mod2 = SCode.MOD(SCode.FINAL(), SCode.NOT_EACH(), list(), SOME(Absyn.CREF(Absyn.CREF_IDENT(inName, list()))), info)
                SCode.COMPONENT(n, prefixes, attr2, t, mod2, cmt, cond, info) <| SCode.COMPONENT(inName, prefixes, attr1, t, mod, cmt, cond, info) <| xs_1
              end

              _  => begin
                SCode.COMPONENT(n, prefixes, SCode.ATTR(tot_dim, ct, prl1, var1, di, isf), t, mod, cmt, cond, info) <| xs_1
              end
            end
          end
        end
        xs_1 = Dangerous.listReverseInPlace(xs_1)
        xs_1
      end

(_, _, _, _, vis, Absyn.IMPORT(imp, info), _)  => begin
  xs_1 = translateImports(imp, vis, info)
  xs_1
end

_  => begin
  println("Error")
  fail()
end
end
end
#=  fprintln(Flags.TRANSLATE, \"translating import: \" + Dump.unparseImportStr(imp));
=#
outElementLst
end

#= Used to handle group imports, i.e. A.B.C.{x=a,b} =#
function translateImports(imp::Absyn.Import, visibility::SCode.Visibility, info::SourceInfo)::Lst
  local elts::Lst

  elts = begin
    local name::String
    local p::Absyn.Path
    local groups::Lst
    #= /* Maybe these should give warnings? I don't know. See https:trac.modelica.org/Modelica/ticket/955 */ =#
    @match (imp, visibility, info) begin
      (Absyn.NAMED_IMPORT(name, Absyn.FULLYQUALIFIED(p)), _, _)  => begin
        translateImports(Absyn.NAMED_IMPORT(name, p), visibility, info)
      end

      (Absyn.QUAL_IMPORT(Absyn.FULLYQUALIFIED(p)), _, _)  => begin
        translateImports(Absyn.QUAL_IMPORT(p), visibility, info)
      end

      (Absyn.UNQUAL_IMPORT(Absyn.FULLYQUALIFIED(p)), _, _)  => begin
        translateImports(Absyn.UNQUAL_IMPORT(p), visibility, info)
      end

      (Absyn.GROUP_IMPORT(p, groups), _, _)  => begin
        List.map3(groups, translateGroupImport, p, visibility, info)
      end

      _  => begin
        list(SCode.IMPORT(imp, visibility, info))
      end
    end
  end
  elts
end

#= Used to handle group imports, i.e. A.B.C.{x=a,b} =#
function translateGroupImport(gimp::Absyn.GroupImport, prefix::Absyn.Path, visibility::SCode.Visibility, info::SourceInfo)::SCode.Element
  local elt::SCode.Element

  elt = begin
    local name::String
    local rename::String
    local path::Absyn.Path
    local vis::SCode.Visibility
    @match (gimp, prefix, visibility, info) begin
      (Absyn.GROUP_IMPORT_NAME(name), _, vis, _)  => begin
        path = AbsynUtil.joinPaths(prefix, Absyn.IDENT(name))
        SCode.IMPORT(Absyn.QUAL_IMPORT(path), vis, info)
      end

      (Absyn.GROUP_IMPORT_RENAME(rename, name), _, vis, _)  => begin
        path = AbsynUtil.joinPaths(prefix, Absyn.IDENT(name))
        SCode.IMPORT(Absyn.NAMED_IMPORT(rename, path), vis, info)
      end
    end
  end
  elt
end

#= @author: adrpo
This function will set the external flag that signals
that a model has inner/outer component definitions =#
function setHasInnerOuterDefinitionsHandler(io::Absyn.InnerOuter)
  _ = begin
    @match io begin
      Absyn.NOT_INNER_OUTER()  => begin
        ()
      end

      _  => begin
        System.setHasInnerOuterDefinitions(true)
        ()
      end
    end
  end
  #=  no inner outer!
  =#
  #=  has inner, outer or innerouter components
  =#
end

#= @author: adrpo
This function will set the external flag that signals
that a model has stream connectors =#
function setHasStreamConnectorsHandler(streamPrefix::Bool)
  _ = begin
    @match streamPrefix begin
      false  => begin
        ()
      end

      true  => begin
        System.setHasStreamConnectors(true)
        ()
      end
    end
  end
  #=  no stream prefix
  =#
  #=  has stream prefix
  =#
end

#= author: PA
For now, translate to bool, replaceable. =#
function translateRedeclarekeywords(inRedeclKeywords::Option)::Tuple{Bool, Bool}
  local outIsRedeclared::Bool
  local outIsReplaceable::Bool

  (outIsReplaceable, outIsRedeclared) = begin
    @match inRedeclKeywords begin
      SOME(Absyn.REDECLARE())  => begin
        (false, true)
      end

      SOME(Absyn.REPLACEABLE())  => begin
        (true, false)
      end

      SOME(Absyn.REDECLARE_REPLACEABLE())  => begin
        (true, true)
      end

      _  => begin
        (false, false)
      end
    end
  end
  (outIsRedeclared, outIsReplaceable)
end

function translateConstrainClass(inConstrainClass::Option)::Option
  local outConstrainClass::Option

  outConstrainClass = begin
    local cc_path::Absyn.Path
    local eltargs::Lst
    local cmt::Option
    local cc_cmt::SCode.Comment
    local mod::Absyn.Modification
    local cc_mod::SCode.Mod
    @match inConstrainClass begin
      SOME(Absyn.CONSTRAINCLASS(Absyn.EXTENDS(cc_path, eltargs), cmt))  => begin
        mod = Absyn.CLASSMOD(eltargs, Absyn.NOMOD())
        cc_mod = translateMod(SOME(mod), SCode.NOT_FINAL(), SCode.NOT_EACH(), AbsynUtil.dummyInfo)
        cc_cmt = translateComment(cmt)
        SOME(SCode.CONSTRAINCLASS(cc_path, cc_mod, cc_cmt))
      end

      _  => begin
        NONE()
      end
    end
  end
  outConstrainClass
end

#= Converts an Absyn.Parallelism to SCode.Parallelism. =#
function translateParallelism(inParallelism::Absyn.Parallelism)::SCode.Parallelism
  local outParallelism::SCode.Parallelism

  outParallelism = begin
    @match inParallelism begin
      Absyn.PARGLOBAL()  => begin
        SCode.PARGLOBAL()
      end

      Absyn.PARLOCAL()  => begin
        SCode.PARLOCAL()
      end

      Absyn.NON_PARALLEL()  => begin
        SCode.NON_PARALLEL()
      end
    end
  end
  outParallelism
end

#= Converts an Absyn.Variability to SCode.Variability. =#
function translateVariability(inVariability::Absyn.Variability)::SCode.Variability
  local outVariability::SCode.Variability

  outVariability = begin
    @match inVariability begin
      Absyn.VAR()  => begin
        SCode.VAR()
      end

      Absyn.DISCRETE()  => begin
        SCode.DISCRETE()
      end

      Absyn.PARAM()  => begin
        SCode.PARAM()
      end

      Absyn.CONST()  => begin
        SCode.CONST()
      end
    end
  end
  outVariability
end

#= This function transforms a list of Absyn.Equation to a list of
SCode.Equation, by applying the translateEquation function to each
equation. =#
function translateEquations(inAbsynEquationItemLst::Lst, inIsInitial::Bool)::Lst
  local outEquationLst::Lst

  outEquationLst = list(begin
                        local com::SCode.Comment
                        local info::SourceInfo
                        @match eq begin
                        Absyn.EQUATIONITEM()  => begin
                        (com, info) = translateCommentWithLineInfoChanges(eq.comment, eq.info)
                        SCode.EQUATION(translateEquation(eq.equation_, com, info, inIsInitial))
                        end
                        end
                        end for eq in inAbsynEquationItemLst if begin
                        @match eq begin
                        Absyn.EQUATIONITEM()  => begin
                        true
                        end

                        _  => begin
                        false
                        end
                        end
                        end)
  outEquationLst
end

#= Helper function to translateEquations =#
function translateEEquations(inAbsynEquationItemLst::Lst, inIsInitial::Bool)::Lst
  local outEEquationLst::Lst

  outEEquationLst = begin
    local e_1::SCode.EEquation
    local es_1::Lst
    local e::Absyn.Equation
    local es::Lst
    local acom::Option
    local com::SCode.Comment
    local info::SourceInfo
    @match (inAbsynEquationItemLst, inIsInitial) begin
      ( nil(), _)  => begin
        list()
      end

      (Absyn.EQUATIONITEM(e, acom, info) <| es, _)  => begin
        (com, info) = translateCommentWithLineInfoChanges(acom, info)
        e_1 = translateEquation(e, com, info, inIsInitial)
        es_1 = translateEEquations(es, inIsInitial)
        e_1 <| es_1
      end

      (Absyn.EQUATIONITEMCOMMENT() <| es, _)  => begin
        translateEEquations(es, inIsInitial)
      end
    end
  end
  #=  fprintln(Flags.TRANSLATE, \"translating equation: \" + Dump.unparseEquationStr(0, e));
  =#
  outEEquationLst
end

#= turns an Absyn.Comment into an SCode.Comment =#
function translateCommentWithLineInfoChanges(inComment::Option, inInfo::SourceInfo)::Tuple{SourceInfo, SCode.Comment}
  local outInfo::SourceInfo
  local outComment::SCode.Comment

  outComment = translateComment(inComment)
  outInfo = getInfoAnnotationOrDefault(outComment, inInfo)
  (outInfo, outComment)
end

#= Replaces the file info if there is an annotation __OpenModelica_FileInfo=(\\\"fileName\\\",line). Should be improved. =#
function getInfoAnnotationOrDefault(comment::SCode.Comment, default::SourceInfo)::SourceInfo
  local info::SourceInfo

  info = begin
    local lst::Lst
    @match (comment, default) begin
      (SCode.COMMENT(SOME(SCode.ANNOTATION(SCode.MOD(lst)))), _)  => begin
        getInfoAnnotationOrDefault2(lst, default)
      end

      _  => begin
        default
      end
    end
  end
  info
end

function getInfoAnnotationOrDefault2(lst::Lst, default::SourceInfo)::SourceInfo
  local info::SourceInfo

  info = begin
    local rest::Lst
    local fileName::String
    local line::ModelicaInteger
    @match (lst, default) begin
      ( nil(), _)  => begin
        default
      end

      (SCode.NAMEMOD(ident = "__OpenModelica_FileInfo", mod = SCode.MOD(binding = SOME(Absyn.TUPLE(Absyn.STRING(fileName) <| Absyn.INTEGER(line) <|  nil())))) <| _, _)  => begin
        SOURCEINFO(fileName, false, line, 0, line, 0, 0.0)
      end

      (_ <| rest, _)  => begin
        getInfoAnnotationOrDefault2(rest, default)
      end
    end
  end
  info
end

#= turns an Absyn.Comment into an SCode.Comment =#
function translateComment(inComment::Option)::SCode.Comment
  local outComment::SCode.Comment

  outComment = begin
    local absann::Option
    local ann::Option
    local ostr::Option
    @match inComment begin
      NONE()  => begin
        SCode.noComment
      end

      SOME(Absyn.COMMENT(absann, ostr))  => begin
        ann = translateAnnotationOpt(absann)
        ostr = Util.applyOption(ostr, System.unescapedString)
        SCode.COMMENT(ann, ostr)
      end
    end
  end
  outComment
end

#= turns an Absyn.Comment into an SCode.Comment =#
function translateCommentList(inAnns::Lst, inString::Option)::SCode.Comment
  local outComment::SCode.Comment

  outComment = begin
    local absann::Absyn.Annotation
    local anns::Lst
    local ann::Option
    local ostr::Option
    @match (inAnns, inString) begin
      ( nil(), _)  => begin
        SCode.COMMENT(NONE(), inString)
      end

      (absann <|  nil(), _)  => begin
        ann = translateAnnotation(absann)
        ostr = Util.applyOption(inString, "Unscaped string")
        SCode.COMMENT(ann, ostr)
      end

      (absann <| anns, _)  => begin
        absann = List.fold(anns, AbsynUtil.mergeAnnotations, absann)
        ann = translateAnnotation(absann)
        ostr = Util.applyOption(inString, "Unescaped string")
        SCode.COMMENT(ann, ostr)
      end
    end
  end
  outComment
end

#= turns an Absyn.Comment into an SCode.Annotation + string =#
function translateCommentSeparate(inComment::Option)::Tuple{Option, Option}
  local outStr::Option
  local outAnn::Option

  (outAnn, outStr) = begin
    local absann::Absyn.Annotation
    local ann::Option
    local str::String
    @match inComment begin
      NONE()  => begin
        (NONE(), NONE())
      end

      SOME(Absyn.COMMENT(NONE(), NONE()))  => begin
        (NONE(), NONE())
      end

      SOME(Absyn.COMMENT(NONE(), SOME(str)))  => begin
        (NONE(), SOME(str))
      end

      SOME(Absyn.COMMENT(SOME(absann), NONE()))  => begin
        ann = translateAnnotation(absann)
        (ann, NONE())
      end

      SOME(Absyn.COMMENT(SOME(absann), SOME(str)))  => begin
        ann = translateAnnotation(absann)
        (ann, SOME(str))
      end
    end
  end
  (outStr, outAnn)
end

function translateEquation(inEquation::Absyn.Equation, inComment::SCode.Comment, inInfo::SourceInfo, inIsInitial::Bool)::SCode.EEquation
  local outEEquation::SCode.EEquation

  outEEquation = begin
    local exp::Absyn.Exp
    local e1::Absyn.Exp
    local e2::Absyn.Exp
    local e3::Absyn.Exp
    local abody::Lst
    local else_branch::Lst
    local body::Lst
    local branches::Lst
    local iter_name::String
    local iter_range::Option
    local eq::SCode.EEquation
    local conditions::Lst
    local bodies::Lst
    local cr::Absyn.ComponentRef
    @match inEquation begin
      Absyn.EQ_IF()  => begin
        body = translateEEquations(inEquation.equationTrueItems, inIsInitial)
        (conditions, bodies) = List.map1_2(inEquation.elseIfBranches, translateEqBranch, inIsInitial)
        conditions = inEquation.ifExp <| conditions
        else_branch = translateEEquations(inEquation.equationElseItems, inIsInitial)
        SCode.EQ_IF(conditions, body <| bodies, else_branch, inComment, inInfo)
      end

      Absyn.EQ_WHEN_E()  => begin
        body = translateEEquations(inEquation.whenEquations, inIsInitial)
        (conditions, bodies) = List.map1_2(inEquation.elseWhenEquations, translateEqBranch, inIsInitial)
        branches = list(@do_threaded_for (c, b) (c, b) (conditions, bodies))
        SCode.EQ_WHEN(inEquation.whenExp, body, branches, inComment, inInfo)
      end

      Absyn.EQ_EQUALS()  => begin
        SCode.EQ_EQUALS(inEquation.leftSide, inEquation.rightSide, inComment, inInfo)
      end

      Absyn.EQ_PDE()  => begin
        SCode.EQ_PDE(inEquation.leftSide, inEquation.rightSide, inEquation.domain, inComment, inInfo)
      end

      Absyn.EQ_CONNECT()  => begin
        if inIsInitial
          println("Error")
        end
        SCode.EQ_CONNECT(inEquation.connector1, inEquation.connector2, inComment, inInfo)
      end

      Absyn.EQ_FOR()  => begin
        body = translateEEquations(inEquation.forEquations, inIsInitial)
        #=  Convert for-loops with multiple iterators into nested for-loops.
        =#
        for i in listReverse(inEquation.iterators)
          (iter_name, iter_range) = translateIterator(i, inInfo)
          body = list(SCode.EQ_FOR(iter_name, iter_range, body, inComment, inInfo))
        end
        listHead(body)
      end

      Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT(name = "assert"), functionArgs = Absyn.FUNCTIONARGS(args = e1 <| e2 <|  nil(), argNames =  nil()))  => begin
        SCode.EQ_ASSERT(e1, e2, ASSERTION_LEVEL_ERROR, inComment, inInfo)
      end

      Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT(name = "assert"), functionArgs = Absyn.FUNCTIONARGS(args = e1 <| e2 <| e3 <|  nil(), argNames =  nil()))  => begin
        SCode.EQ_ASSERT(e1, e2, e3, inComment, inInfo)
      end

      Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT(name = "assert"), functionArgs = Absyn.FUNCTIONARGS(args = e1 <| e2 <|  nil(), argNames = Absyn.NAMEDARG("level", e3) <|  nil()))  => begin
        SCode.EQ_ASSERT(e1, e2, e3, inComment, inInfo)
      end

      Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT(name = "terminate"), functionArgs = Absyn.FUNCTIONARGS(args = e1 <|  nil(), argNames =  nil()))  => begin
        SCode.EQ_TERMINATE(e1, inComment, inInfo)
      end

      Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT(name = "reinit"), functionArgs = Absyn.FUNCTIONARGS(args = e1 <| e2 <|  nil(), argNames =  nil()))  => begin
        SCode.EQ_REINIT(e1, e2, inComment, inInfo)
      end

      Absyn.EQ_NORETCALL()  => begin
        SCode.EQ_NORETCALL(Absyn.CALL(inEquation.functionName, inEquation.functionArgs), inComment, inInfo)
      end

      _  => begin
        #=  assert(condition, message)
        =#
        #=  assert(condition, message, level)
        =#
        #=  assert(condition, message, level = arg)
        =#
        #=  terminate(message)
        =#
        #=  reinit(cref, exp)
        =#
        #=  Other nonreturning calls. assert, terminate and reinit with the wrong
        =#
        #=  number of arguments is also turned into a noretcall, since it's
        =#
        #=  preferable to handle the error during instantation instead of here.
        =#
        println("Error")
        fail()
      end
    end
  end
  outEEquation
end

function translateEqBranch(inBranch::Tuple, inIsInitial::Bool)::Tuple{List, Absyn.Exp}
  local outBody::Lst
  local outCondition::Absyn.Exp

  local body::Lst

  (outCondition, body) = inBranch
  outBody = translateEEquations(body, inIsInitial)
  (outBody, outCondition)
end

function translateIterator(inIterator::Absyn.ForIterator, inInfo::SourceInfo)::Tuple{Option, String}
  local outRange::Option
  local outName::String

  local guard_exp::Option

  @match Absyn.ITERATOR(outName, guard_exp, outRange) = inIterator
  if isSome(guard_exp)
    println("Error")
  end
  (outRange, outName)
end

#= function: translateElementAddinfo =#
function translateElementAddinfo(elem::SCode.Element, nfo::SourceInfo)::SCode.Element
  local oelem::SCode.Element

  oelem = begin
    local a1::SCode.Ident
    local a2::Absyn.InnerOuter
    local a3::Bool
    local a4::Bool
    local a5::Bool
    local rd::Bool
    local a6::SCode.Attributes
    local a7::Absyn.TypeSpec
    local a8::SCode.Mod
    local a10::SCode.Comment
    local a11::Option
    local a13::Option
    local p::SCode.Prefixes
    @matchcontinue (elem, nfo) begin
      (SCode.COMPONENT(a1, p, a6, a7, a8, a10, a11, _), _)  => begin
        SCode.COMPONENT(a1, p, a6, a7, a8, a10, a11, nfo)
      end

      _  => begin
        elem
      end
    end
  end
  oelem
end

#= /* Modification management */ =#

#= Builds an SCode.Mod from an Absyn.Modification. =#
function translateMod(inMod::Option, finalPrefix::SCode.Final, eachPrefix::SCode.Each, info::SourceInfo)::SCode.Mod
  local outMod::SCode.Mod

  local args::Lst
  local eqmod::Absyn.EqMod
  local subs::Lst
  local binding::Option

  (args, eqmod) = begin
    @match inMod begin
      SOME(Absyn.CLASSMOD(args, eqmod))  => begin
        (args, eqmod)
      end

      _  => begin
        (list(), Absyn.NOMOD())
      end
    end
  end
  subs = if listEmpty(args)
    list()
  else
    translateArgs(args)
  end
  binding = begin
    @match eqmod begin
      Absyn.EQMOD()  => begin
        SOME(eqmod.exp)
      end

      _  => begin
        NONE()
      end
    end
  end
  outMod = begin
    @match (subs, binding, finalPrefix, eachPrefix) begin
      ( nil(), NONE(), SCode.NOT_FINAL(), SCode.NOT_EACH())  => begin
        SCode.NOMOD()
      end

      _  => begin
        SCode.MOD(finalPrefix, eachPrefix, subs, binding, info)
      end
    end
  end
  outMod
end

function translateArgs(args::Lst)::Lst
  local subMods::Lst = list()

  local smod::SCode.Mod
  local elem::SCode.Element
  local sub::SCode.SubMod

  for arg in args
    subMods = begin
      @match arg begin
        Absyn.MODIFICATION()  => begin
          smod = translateMod(arg.modification, SCode.boolFinal(arg.finalPrefix), translateEach(arg.eachPrefix), arg.info)
          if ! SCode.isEmptyMod(smod)
            sub = translateSub(arg.path, smod, arg.info)
            subMods = sub <| subMods
          end
          subMods
        end

        Absyn.REDECLARATION()  => begin
          @assert list(elem) == (translateElementspec(arg.constrainClass, arg.finalPrefix, Absyn.NOT_INNER_OUTER(), SOME(arg.redeclareKeywords), SCode.PUBLIC(), arg.elementSpec, arg.info))
          sub = SCode.NAMEMOD(AbsynUtil.elementSpecName(arg.elementSpec), SCode.REDECL(SCode.boolFinal(arg.finalPrefix), translateEach(arg.eachPrefix), elem))
          sub <| subMods
        end
      end
    end
  end
  subMods = listReverse(subMods)
  subMods
end

#= This function converts a Absyn.ComponentRef plus a list
of modifications into a number of nested SCode.SUBMOD. =#
function translateSub(inPath::Absyn.Path, inMod::SCode.Mod, info::SourceInfo)::SCode.SubMod
  local outSubMod::SCode.SubMod

  outSubMod = begin
    local i::String
    local path::Absyn.Path
    local mod::SCode.Mod
    local sub::SCode.SubMod
    #=  Then the normal rules
    =#
    @match (inPath, inMod, info) begin
      (Absyn.IDENT(i), mod, _)  => begin
        SCode.NAMEMOD(i, mod)
      end

      (Absyn.QUALIFIED(i, path), mod, _)  => begin
        sub = translateSub(path, mod, info)
        mod = SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), list(sub), NONE(), info)
        SCode.NAMEMOD(i, mod)
      end
    end
  end
  outSubMod
end

#= @author: adrpo
this function translates a SCode.Mod into Absyn.NamedArg
and prefixes all *LOCAL* expressions with the given prefix.
Example:
Input:
prefix       : world
modifications: (gravityType  = gravityType, g  = g * Modelica.Math.Vectors.normalize(n), mue  = mue)
Gives:
namedArgs:     (gravityType  = world.gravityType, g  = world.g * Modelica.Math.Vectors.normalize(world.n), mue  = world.mue) =#
function translateSCodeModToNArgs(prefix::String #= given prefix, example: world =#, mod::SCode.Mod #= given modifications =#)::Lst
  local namedArgs::Lst #= the resulting named arguments =#

  namedArgs = begin
    local nArgs::Lst
    local subModLst::Lst
    @match (prefix, mod) begin
      (_, SCode.MOD(subModLst))  => begin
        nArgs = translateSubModToNArgs(prefix, subModLst)
        nArgs
      end
    end
  end
  namedArgs #= the resulting named arguments =#
end

#= @author: adrpo
this function translates a SCode.SubMod into Absyn.NamedArg
and prefixes all *LOCAL* expressions with the given prefix. =#
function translateSubModToNArgs(prefix::String #= given prefix, example: world =#, subMods::Lst #= given sub modifications =#)::Lst
  local namedArgs::Lst #= the resulting named arguments =#

  namedArgs = begin
    local nArgs::Lst
    local subModLst::Lst
    local exp::Absyn.Exp
    local ident::SCode.Ident
    #=  deal with the empty list
    =#
    @match (prefix, subMods) begin
      (_,  nil())  => begin
        list()
      end

      (_, SCode.NAMEMOD(ident, SCode.MOD(binding = SOME(exp))) <| subModLst)  => begin
        nArgs = translateSubModToNArgs(prefix, subModLst)
        exp = prefixUnqualifiedCrefsFromExp(exp, prefix)
        Absyn.NAMEDARG(ident, exp) <| nArgs
      end
    end
  end
  #=  deal with named modifiers
  =#
  namedArgs #= the resulting named arguments =#
end

function prefixTuple(expTuple::Tuple, prefix::String)::Tuple
  local prefixedExpTuple::Tuple

  prefixedExpTuple = begin
    local e1::Absyn.Exp
    local e2::Absyn.Exp
    @match (expTuple, prefix) begin
      ((e1, e2), _)  => begin
        e1 = prefixUnqualifiedCrefsFromExp(e1, prefix)
        e2 = prefixUnqualifiedCrefsFromExp(e2, prefix)
        (e1, e2)
      end
    end
  end
  prefixedExpTuple
end

function prefixUnqualifiedCrefsFromExpOpt(inExpOpt::Option, prefix::String)::Option
  local outExpOpt::Option

  outExpOpt = begin
    local exp::Absyn.Exp
    @match (inExpOpt, prefix) begin
      (NONE(), _)  => begin
        NONE()
      end

      (SOME(exp), _)  => begin
        exp = prefixUnqualifiedCrefsFromExp(exp, prefix)
        SOME(exp)
      end
    end
  end
  outExpOpt
end

function prefixUnqualifiedCrefsFromExpLst(inExpLst::Lst, prefix::String)::Lst
  local outExpLst::Lst

  outExpLst = begin
    local exp::Absyn.Exp
    local rest::Lst
    @match (inExpLst, prefix) begin
      ( nil(), _)  => begin
        list()
      end

      (exp <| rest, _)  => begin
        exp = prefixUnqualifiedCrefsFromExp(exp, prefix)
        rest = prefixUnqualifiedCrefsFromExpLst(rest, prefix)
        exp <| rest
      end
    end
  end
  outExpLst
end

function prefixFunctionArgs(inFunctionArgs::Absyn.FunctionArgs, prefix::String)::Absyn.FunctionArgs
  local outFunctionArgs::Absyn.FunctionArgs

  outFunctionArgs = begin
    local args::Lst #= args =#
    local argNames::Lst #= argNames =#
    @match (inFunctionArgs, prefix) begin
      (Absyn.FUNCTIONARGS(args, argNames), _)  => begin
        args = prefixUnqualifiedCrefsFromExpLst(args, prefix)
        Absyn.FUNCTIONARGS(args, argNames)
      end
    end
  end
  outFunctionArgs
end

function prefixUnqualifiedCrefsFromExp(exp::Absyn.Exp, prefix::String)::Absyn.Exp
  local prefixedExp::Absyn.Exp

  prefixedExp = begin
    local s::SCode.Ident
    local c::Absyn.ComponentRef
    local fcn::Absyn.ComponentRef
    local e1::Absyn.Exp
    local e2::Absyn.Exp
    local e1a::Absyn.Exp
    local e2a::Absyn.Exp
    local e::Absyn.Exp
    local t::Absyn.Exp
    local f::Absyn.Exp
    local start::Absyn.Exp
    local stop::Absyn.Exp
    local cond::Absyn.Exp
    local op::Absyn.Operator
    local lst::Lst
    local args::Absyn.FunctionArgs
    local es::Lst
    local matchType::Absyn.MatchType
    local head::Absyn.Exp
    local rest::Absyn.Exp
    local inputExp::Absyn.Exp
    local localDecls::Lst
    local cases::Lst
    local comment::Option
    local esLstLst::Lst
    local expOpt::Option
    #=  deal with basic types
    =#
    @matchcontinue (exp, prefix) begin
      (Absyn.INTEGER(_), _)  => begin
        exp
      end

      (Absyn.REAL(_), _)  => begin
        exp
      end

      (Absyn.STRING(_), _)  => begin
        exp
      end

      (Absyn.BOOL(_), _)  => begin
        exp
      end

      (Absyn.CREF(Absyn.CREF_QUAL()), _)  => begin
        exp
      end

      (Absyn.CREF(Absyn.CREF_IDENT()), _)  => begin
        c = Absyn.CREF_IDENT()
        e = AbsynUtil.crefExp(Absyn.CREF_QUAL(prefix, list(), c))
      end

      (Absyn.BINARY(e1, op, e2), _)  => begin
        e1a = prefixUnqualifiedCrefsFromExp(e1, prefix)
        e2a = prefixUnqualifiedCrefsFromExp(e2, prefix)
        Absyn.BINARY(e1a, op, e2a)
      end

      (Absyn.UNARY(op = op, exp = e), _)  => begin
        e = prefixUnqualifiedCrefsFromExp(e, prefix)
        Absyn.UNARY(op, e)
      end

      (Absyn.LBINARY(exp1 = e1, op = op, exp2 = e2), _)  => begin
        e1a = prefixUnqualifiedCrefsFromExp(e1, prefix)
        e2a = prefixUnqualifiedCrefsFromExp(e2, prefix)
        Absyn.LBINARY(e1a, op, e2a)
      end

      (Absyn.LUNARY(op = op, exp = e), _)  => begin
        e = prefixUnqualifiedCrefsFromExp(e, prefix)
        Absyn.LUNARY(op, e)
      end

      (Absyn.RELATION(exp1 = e1, op = op, exp2 = e2), _)  => begin
        e1a = prefixUnqualifiedCrefsFromExp(e1, prefix)
        e2a = prefixUnqualifiedCrefsFromExp(e2, prefix)
        Absyn.RELATION(e1a, op, e2a)
      end

      (Absyn.IFEXP(ifExp = cond, trueBranch = t, elseBranch = f, elseIfBranch = lst), _)  => begin
        cond = prefixUnqualifiedCrefsFromExp(cond, prefix)
        t = prefixUnqualifiedCrefsFromExp(t, prefix)
        f = prefixUnqualifiedCrefsFromExp(f, prefix)
        lst = List.map1(lst, prefixTuple, prefix)
        Absyn.IFEXP(cond, t, f, lst)
      end

      (Absyn.CALL(function_ = fcn, functionArgs = args), _)  => begin
        args = prefixFunctionArgs(args, prefix)
        Absyn.CALL(fcn, args)
      end

      (Absyn.PARTEVALFUNCTION(function_ = fcn, functionArgs = args), _)  => begin
        args = prefixFunctionArgs(args, prefix)
        Absyn.PARTEVALFUNCTION(fcn, args)
      end

      (Absyn.ARRAY(arrayExp = es), _)  => begin
        es = List.map1(es, prefixUnqualifiedCrefsFromExp, prefix)
        Absyn.ARRAY(es)
      end

      (Absyn.TUPLE(expressions = es), _)  => begin
        es = List.map1(es, prefixUnqualifiedCrefsFromExp, prefix)
        Absyn.TUPLE(es)
      end

      (Absyn.MATRIX(matrix = esLstLst), _)  => begin
        esLstLst = List.map1(esLstLst, prefixUnqualifiedCrefsFromExpLst, prefix)
        Absyn.MATRIX(esLstLst)
      end

      (Absyn.RANGE(start = start, step = expOpt, stop = stop), _)  => begin
        start = prefixUnqualifiedCrefsFromExp(start, prefix)
        expOpt = prefixUnqualifiedCrefsFromExpOpt(expOpt, prefix)
        stop = prefixUnqualifiedCrefsFromExp(stop, prefix)
        Absyn.RANGE(start, expOpt, stop)
      end

      (Absyn.END(), _)  => begin
        exp
      end

      (Absyn.LIST(es), _)  => begin
        es = List.map1(es, prefixUnqualifiedCrefsFromExp, prefix)
        Absyn.LIST(es)
      end

      (Absyn.CONS(head, rest), _)  => begin
        head = prefixUnqualifiedCrefsFromExp(head, prefix)
        rest = prefixUnqualifiedCrefsFromExp(rest, prefix)
        Absyn.CONS(head, rest)
      end

      (Absyn.AS(s, rest), _)  => begin
        rest = prefixUnqualifiedCrefsFromExp(rest, prefix)
        Absyn.AS(s, rest)
      end

      (Absyn.MATCHEXP(matchType, inputExp, localDecls, cases, comment), _)  => begin
        Absyn.MATCHEXP(matchType, inputExp, localDecls, cases, comment)
      end

      _  => begin
        exp
      end
    end
  end
  #=  do NOT prefix if you have qualified component references
  =#
  #=  do prefix if you have simple component references
  =#
  #=  binary
  =#
  #=  unary
  =#
  #=  binary logical
  =#
  #=  unary logical
  =#
  #=  relations
  =#
  #=  if expressions
  =#
  #=  TODO! fixme, prefix these also.
  =#
  #=  calls
  =#
  #=  partial evaluated functions
  =#
  #=  arrays
  =#
  #=  tuples
  =#
  #=  matrix
  =#
#=  range
  =#
#=  end
=#
#=  MetaModelica expressions!
=#
#=  cons
=#
#=  as
=#
#=  matchexp
=#
#=  something else, just return the expression
=#
prefixedExp
end

#= Gets the Absyn.Import from an SCode.Element (fails if the element is not SCode.IMPORT) =#
function getImportFromElement(elt::SCode.Element)::Absyn.Import
  local imp::Absyn.Import
  @match elt = SCode.IMPORT(imp)
  imp
end

function makeTypeVarElement(str::String, info::SourceInfo)::SCode.Element
  local elt::SCode.Element

  local cd::SCode.ClassDef
  local ts::Absyn.TypeSpec

  ts = Absyn.TCOMPLEX(Absyn.IDENT("polymorphic"), list(Absyn.TPATH(Absyn.IDENT("Any"), NONE())), NONE())
  cd = SCode.DERIVED(ts, SCode.NOMOD(), SCode.ATTR(list(), SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR(), Absyn.NONFIELD()))
  elt = SCode.CLASS(str, SCode.PREFIXES(SCode.PUBLIC(), SCode.NOT_REDECLARE(), SCode.FINAL(), Absyn.NOT_INNER_OUTER(), SCode.NOT_REPLACEABLE()), SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(), cd, SCode.noComment, info)
  elt
end

function translateEach(inAEach::Absyn.Each)::SCode.Each
  local outSEach::SCode.Each

  outSEach = begin
    @match inAEach begin
      Absyn.EACH()  => begin
        SCode.EACH()
      end

      Absyn.NON_EACH()  => begin
        SCode.NOT_EACH()
      end
    end
  end
  outSEach
end

#= get the redeclare-as-element elements =#
function isRedeclareElement(element::SCode.Element)::Bool
  local isElement::Bool

  isElement = begin
    @match element begin
      SCode.COMPONENT(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE()))  => begin
        true
      end

      SCode.CLASS(classDef = SCode.CLASS_EXTENDS())  => begin
        false
      end

      SCode.CLASS(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE()))  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  #=  redeclare-as-element component
  =#
  #=  not redeclare class extends
  =#
  #=  redeclare-as-element class!, not class extends
  =#
  isElement
end

#= add the redeclare-as-element elements to extends =#
function addRedeclareAsElementsToExtends(inElements::Lst, redeclareElements::Lst)::Lst
  local outExtendsElements::Lst

  outExtendsElements = begin
    local el::SCode.Element
    local redecls::Lst
    local rest::Lst
    local out::Lst
    local baseClassPath::Absyn.Path
    local visibility::SCode.Visibility
    local mod::SCode.Mod
    local ann::Option #= the extends annotation =#
    local info::SourceInfo
    local redeclareMod::SCode.Mod
    local submods::Lst
    #=  empty, return the same
    =#
    @matchcontinue (inElements, redeclareElements) begin
      (_,  nil())  => begin
        inElements
      end

      ( nil(), _)  => begin
        list()
      end

      (SCode.EXTENDS(baseClassPath, visibility, mod, ann, info) <| rest, redecls)  => begin
        submods = makeElementsIntoSubMods(SCode.NOT_FINAL(), SCode.NOT_EACH(), redecls)
        redeclareMod = SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), submods, NONE(), info)
        mod = mergeSCodeMods(redeclareMod, mod)
        out = addRedeclareAsElementsToExtends(rest, redecls)
        SCode.EXTENDS(baseClassPath, visibility, mod, ann, info) <| out
      end

      (SCode.EXTENDS() <| _, redecls)  => begin
        el,
        print("- SCodeUtil.addRedeclareAsElementsToExtends failed on:\next\n")
        fail()
      end

      (el <| rest, redecls)  => begin
        out = addRedeclareAsElementsToExtends(rest, redecls)
        el <| out
      end
    end
  end
  #=  empty elements
  =#
  #=  we got some
  =#
  #=  failure
  =#
  #=  ignore non-extends
  =#
  outExtendsElements
end

function mergeSCodeMods(inModOuter::SCode.Mod, inModInner::SCode.Mod)::SCode.Mod
  local outMod::SCode.Mod

  outMod = begin
    local f1::SCode.Final
    local f2::SCode.Final
    local e1::SCode.Each
    local e2::SCode.Each
    local subMods1::Lst
    local subMods2::Lst
    local b1::Option
    local b2::Option
    local info::SourceInfo
    #=  inner is NOMOD
    =#
    @matchcontinue (inModOuter, inModInner) begin
      (_, SCode.NOMOD())  => begin
        inModOuter
      end

      (SCode.MOD(f1, e1, subMods1, b1, info), SCode.MOD(_, _, subMods2, b2, _))  => begin
        subMods2 = listAppend(subMods1, subMods2)
        b1 = if isSome(b1)
          b1
        else
          b2
        end
        SCode.MOD(f1, e1, subMods2, b1, info)
      end

      _  => begin
        print("SCodeUtil.mergeSCodeMods failed on:\nouterMod: ")
        fail()
      end
    end
  end
  #=  both are redeclarations
  =#
  #= case (SCode.REDECL(f1, e1, redecls), SCode.REDECL(f2, e2, els))
  =#
  #=   equation
  =#
  #=     els = listAppend(redecls, els);
  =#
  #=   then
  =#
  #=     SCode.REDECL(f2, e2, els);
  =#
  #=  inner is mod
  =#
  #= case (SCode.REDECL(f1, e1, redecls), SCode.MOD(f2, e2, subMods, b, info))
  =#
  #=   equation
  =#
  #=      we need to make each redcls element into a submod!
  =#
  #=     newSubMods = makeElementsIntoSubMods(f1, e1, redecls);
  =#
  #=     newSubMods = listAppend(newSubMods, subMods);
  =#
  #=   then
  =#
  #=     SCode.MOD(f2, e2, newSubMods, b, info);
  =#
  #=  failure
  =#
  outMod
end

function mergeSCodeOptAnn(inModOuter::Option, inModInner::Option)::Option
  local outMod::Option

  outMod = begin
    local mod1::SCode.Mod
    local mod2::SCode.Mod
    local mod::SCode.Mod
    @match (inModOuter, inModInner) begin
      (NONE(), _)  => begin
        inModInner
      end

      (_, NONE())  => begin
        inModOuter
      end

      (SOME(SCode.ANNOTATION(mod1)), SOME(SCode.ANNOTATION(mod2)))  => begin
        mod = mergeSCodeMods(mod1, mod2)
        SOME(SCode.ANNOTATION(mod))
      end
    end
  end
  outMod
end

#= transform elements into submods with named mods =#
function makeElementsIntoSubMods(inFinal::SCode.Final, inEach::SCode.Each, inElements::Lst)::Lst
  local outSubMods::Lst

  outSubMods = begin
    local el::SCode.Element
    local rest::Lst
    local f::SCode.Final
    local e::SCode.Each
    local n::SCode.Ident
    local newSubMods::Lst
    #=  empty
    =#
    @matchcontinue (inFinal, inEach, inElements) begin
      (_, _,  nil())  => begin
        list()
      end

      (f, e, SCode.CLASS(classDef = SCode.CLASS_EXTENDS()) <| rest)  => begin
        el,
        print("- SCodeUtil.makeElementsIntoSubMods ignoring class-extends redeclare-as-element: \n")
        newSubMods = makeElementsIntoSubMods(f, e, rest)
        newSubMods
      end

      (f, e, SCode.COMPONENT(name = n) <| rest)  => begin
        el,
        newSubMods = makeElementsIntoSubMods(f, e, rest)
        SCode.NAMEMOD(n, SCode.REDECL(f, e, el)) <| newSubMods
      end

      (f, e, SCode.CLASS(name = n) <| rest)  => begin
        el,
        newSubMods = makeElementsIntoSubMods(f, e, rest)
        SCode.NAMEMOD(n, SCode.REDECL(f, e, el)) <| newSubMods
      end

      (f, e, el <| rest)  => begin
        print("- SCodeUtil.makeElementsIntoSubMods ignoring redeclare-as-element redeclaration: \n")
        newSubMods = makeElementsIntoSubMods(f, e, rest)
        newSubMods
      end
    end
  end
  #=  class extends, error!
  =#
  #=  print an error here
  =#
  #=  recurse
  =#
  #=  component
  =#
  #=  recurse
  =#
  #=  class
  =#
  #=  recurse
  =#
  #=  rest
  =#
  #=  print an error here
  =#
  #=  recurse
  =#
  outSubMods
end

#= @author: adrpo
keeps the constant binding and if not returns none =#
function constantBindingOrNone(inBinding::Option)::Option
  local outBinding::Option

  outBinding = begin
    local e::Absyn.Exp
    #=  keep it
    =#
    @matchcontinue inBinding begin
      SOME(e)  => begin
        @assert list() == (AbsynUtil.getCrefFromExp(e, true, true))
        inBinding
      end

      _  => begin
        NONE()
      end
    end
  end
  #=  else
  =#
  outBinding
end

#= @author: adrpo
keeps the redeclares and removes all non-constant bindings!
if onlyRedeclare is true then bindings are removed completely! =#
function removeNonConstantBindingsKeepRedeclares(inMod::SCode.Mod, onlyRedeclares::Bool)::SCode.Mod
  local outMod::SCode.Mod

  outMod = begin
    local sl::Lst
    local fp::SCode.Final
    local ep::SCode.Each
    local i::SourceInfo
    local binding::Option
    @matchcontinue (inMod, onlyRedeclares) begin
      (SCode.MOD(fp, ep, sl, binding, i), _)  => begin
        binding = if onlyRedeclares
          NONE()
        else
          constantBindingOrNone(binding)
        end
        sl = removeNonConstantBindingsKeepRedeclaresFromSubMod(sl, onlyRedeclares)
        SCode.MOD(fp, ep, sl, binding, i)
      end

      (SCode.REDECL(), _)  => begin
        inMod
      end

      _  => begin
        inMod
      end
    end
  end
  outMod
end

#= @author: adrpo
removes the non-constant bindings in submods and keeps the redeclares =#
function removeNonConstantBindingsKeepRedeclaresFromSubMod(inSl::Lst, onlyRedeclares::Bool)::Lst
  local outSl::Lst

  outSl = begin
    local n::String
    local sl::Lst
    local rest::Lst
    local m::SCode.Mod
    local ssl::Lst
    @match (inSl, onlyRedeclares) begin
      ( nil(), _)  => begin
        list()
      end

      (SCode.NAMEMOD(n, m) <| rest, _)  => begin
        m = removeNonConstantBindingsKeepRedeclares(m, onlyRedeclares)
        sl = removeNonConstantBindingsKeepRedeclaresFromSubMod(rest, onlyRedeclares)
        SCode.NAMEMOD(n, m) <| sl
      end
    end
  end
  outSl
end

#= @author: adrpo
remove the binding that contains a cref =#
function removeReferenceInBinding(inBinding::Option, inCref::Absyn.ComponentRef)::Option
  local outBinding::Option

  outBinding = begin
    local e::Absyn.Exp
    local crlst1::Lst
    local crlst2::Lst
    #=  if cref is not present keep the binding!
    =#
    @matchcontinue inBinding begin
      SOME(e)  => begin
        crlst1 = AbsynUtil.getCrefFromExp(e, true, true)
        crlst2 = AbsynUtil.removeCrefFromCrefs(crlst1, inCref)
        @assert true == (intEq(listLength(crlst1), listLength(crlst2)))
        inBinding
      end

      _  => begin
        NONE()
      end
    end
  end
  #=  else
  =#
  outBinding
end

#= @author: adrpo
remove the self reference from mod! =#
function removeSelfReferenceFromMod(inMod::SCode.Mod, inCref::Absyn.ComponentRef)::SCode.Mod
  local outMod::SCode.Mod

  outMod = begin
    local sl::Lst
    local fp::SCode.Final
    local ep::SCode.Each
    local i::SourceInfo
    local binding::Option
    @matchcontinue (inMod, inCref) begin
      (SCode.MOD(fp, ep, sl, binding, i), _)  => begin
        binding = removeReferenceInBinding(binding, inCref)
        sl = removeSelfReferenceFromSubMod(sl, inCref)
        SCode.MOD(fp, ep, sl, binding, i)
      end

      (SCode.REDECL(), _)  => begin
        inMod
      end

      _  => begin
        inMod
      end
    end
  end
  outMod
end

#= @author: adrpo
removes the self references from a submod =#
function removeSelfReferenceFromSubMod(inSl::Lst, inCref::Absyn.ComponentRef)::Lst
  local outSl::Lst

  outSl = begin
    local n::String
    local sl::Lst
    local rest::Lst
    local m::SCode.Mod
    local ssl::Lst
    @match (inSl, inCref) begin
      ( nil(), _)  => begin
        list()
      end

      (SCode.NAMEMOD(n, m) <| rest, _)  => begin
        m = removeSelfReferenceFromMod(m, inCref)
        sl = removeSelfReferenceFromSubMod(rest, inCref)
        SCode.NAMEMOD(n, m) <| sl
      end
    end
  end
  outSl
end

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

function expandEnumerationSubMod(inSubMod::SCode.SubMod, inChanged::Bool)::Tuple{Bool, SCode.SubMod}
  local outChanged::Bool
  local outSubMod::SCode.SubMod

  (outSubMod, outChanged) = begin
    local mod::SCode.Mod
    local mod1::SCode.Mod
    local ident::SCode.Ident
    @match inSubMod begin
      SCode.NAMEMOD(ident = ident, mod = mod)  => begin
        mod1 = expandEnumerationMod(mod)
        if referenceEq(mod, mod1)
          (inSubMod, inChanged)
        else
          (SCode.NAMEMOD(ident, mod1), true)
        end
      end

      _  => begin
        (inSubMod, inChanged)
      end
    end
  end
  (outChanged, outSubMod)
end

function expandEnumerationMod(inMod::SCode.Mod)::SCode.Mod
  local outMod::SCode.Mod

  local f::SCode.Final
  local e::SCode.Each
  local el::SCode.Element
  local el1::SCode.Element
  local submod::Lst
  local binding::Option
  local info::SourceInfo
  local changed::Bool

  outMod = begin
    @match inMod begin
      SCode.REDECL(f, e, el)  => begin
        el1 = expandEnumerationClass(el)
        if referenceEq(el, el1)
          inMod
        else
          SCode.REDECL(f, e, el1)
        end
      end

      SCode.MOD(f, e, submod, binding, info)  => begin
        (submod, changed) = List.mapFold(submod, expandEnumerationSubMod, false)
        if changed
          SCode.MOD(f, e, submod, binding, info)
        else
          inMod
        end
      end

      _  => begin
        inMod
      end
    end
  end
  outMod
end

#= @author: PA, adrpo
this function expands the enumeration from a list into a class with components
if the class is not an enumeration is kept as it is =#
function expandEnumerationClass(inElement::SCode.Element)::SCode.Element
  local outElement::SCode.Element

  outElement = begin
    local n::SCode.Ident
    local l::Lst
    local cmt::SCode.Comment
    local info::SourceInfo
    local c::SCode.Element
    local prefixes::SCode.Prefixes
    local m::SCode.Mod
    local m1::SCode.Mod
    local p::Absyn.Path
    local v::SCode.Visibility
    local ann::Option
    @match inElement begin
      SCode.CLASS(name = n, restriction = SCode.R_TYPE(), prefixes = prefixes, classDef = SCode.ENUMERATION(enumLst = l), cmt = cmt, info = info)  => begin
        c = expandEnumeration(n, l, prefixes, cmt, info)
        c
      end

      SCode.EXTENDS(baseClassPath = p, visibility = v, modifications = m, ann = ann, info = info)  => begin
        m1 = expandEnumerationMod(m)
        if referenceEq(m, m1)
          inElement
        else
          SCode.EXTENDS(p, v, m1, ann, info)
        end
      end

      _  => begin
        inElement
      end
    end
  end
  outElement
end

#= author: PA
This function takes an Ident and list of strings, and returns an enumeration class. =#
function expandEnumeration(n::SCode.Ident, l::Lst, prefixes::SCode.Prefixes, cmt::SCode.Comment, info::SourceInfo)::SCode.Element
  local outClass::SCode.Element

  outClass = SCode.CLASS(n, prefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_ENUMERATION(), makeEnumParts(l, info), cmt, info)
  outClass
end

function makeEnumParts(inEnumLst::Lst, info::SourceInfo)::SCode.ClassDef
  local classDef::SCode.ClassDef

  classDef = SCode.PARTS(makeEnumComponents(inEnumLst, info), list(), list(), list(), list(), list(), list(), NONE())
  classDef
end

#= Translates a list of Enums to a list of elements of type EnumType. =#
function makeEnumComponents(inEnumLst::Lst, info::SourceInfo)::Lst
  local outSCodeElementLst::Lst

  outSCodeElementLst = List.map1(inEnumLst, SCode.makeEnumType, info)
  outSCodeElementLst
end

function checkTypeSpec(ts::Absyn.TypeSpec, info::SourceInfo)
  _ = begin
    local tss::Lst
    local ts2::Absyn.TypeSpec
    local str::String
    @match (ts, info) begin
      (Absyn.TPATH(), _)  => begin
        ()
      end

      (Absyn.TCOMPLEX(Absyn.IDENT("tuple"), ts2 <|  nil()), _)  => begin
        str = AbsynUtil.typeSpecString(ts)
        println("Error")
        checkTypeSpec(ts2, info)
        ()
      end

      (Absyn.TCOMPLEX(Absyn.IDENT("tuple"), tss), _)  => begin
        @assert listLength(tss) >= 2
        List.map1_0(tss, checkTypeSpec, info)
        ()
      end

      (Absyn.TCOMPLEX(ts2 <|  nil()), _)  => begin
        checkTypeSpec(ts2, info)
        ()
      end

      (Absyn.TCOMPLEX(tss), _)  => begin
        if listMember(ts.path, list(Absyn.IDENT("list"), Absyn.IDENT("List"), Absyn.IDENT("array"), Absyn.IDENT("Array"), Absyn.IDENT("polymorphic"), Absyn.IDENT("Option")))
          str = AbsynUtil.typeSpecString(ts)
          println("Error")
          List.map1_0(tss, checkTypeSpec, info)
        end
        ()
      end
    end
  end
end

#= @author: adrpo
redeclare T x where the original type has array dimensions
but the redeclare doesn't. Keep the original array dimensions then =#
function mergeDimensions(fromRedeclare::SCode.Attributes, fromOriginal::SCode.Attributes)::SCode.Attributes
  local result::SCode.Attributes

  result = begin
    local ad1::Absyn.ArrayDim
    local ad2::Absyn.ArrayDim
    local ct1::SCode.ConnectorType
    local ct2::SCode.ConnectorType
    local p1::SCode.Parallelism
    local p2::SCode.Parallelism
    local v1::SCode.Variability
    local v2::SCode.Variability
    local d1::Absyn.Direction
    local d2::Absyn.Direction
    local if1::Absyn.IsField
    @matchcontinue (fromRedeclare, fromOriginal) begin
      (SCode.ATTR( nil(), ct1, p1, v1, d1, if1), SCode.ATTR(ad2, _, _, _, _, _))  => begin
        SCode.ATTR(ad2, ct1, p1, v1, d1, if1)
      end
      _  => begin
        fromRedeclare
      end
    end
  end
  result
end

end

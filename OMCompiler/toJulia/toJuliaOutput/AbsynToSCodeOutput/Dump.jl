#= Partly automatically generated =#
module Dump


using MetaModelica
#= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#

Lst = MetaModelica.List

@UniontypeDecl DumpOptions

FuncTypeType_aToString = Function

FuncTypeType_aTo = Function

FuncTypeType_aTo = Function

FuncTypeType_aTo = Function

FuncTypeType_aToString = Function

FuncTypeType_aToString = Function

FuncTypeType_aToString = Function

FuncTypeType_aToString = Function

FuncTypeType_aTo = Function

FuncTypeType_a = Function
FuncTypeType_b = Function

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
#=  public imports
=#
import Absyn
import File
import File.Escape
#=  protected imports
=#

import AbsynDumpTpl
import Config
import List #Lugnt
import Print #Lugnt
import Tpl
import Util #Lugnt



@Uniontype DumpOptions begin
  @Record DUMPOPTIONS begin

    fileName::String
  end
end

defaultDumpOptions = DUMPOPTIONS("")::DumpOptions

#= Returns true if the filename in the SOURCEINFO should be unparsed =#
function boolUnparseFileFromInfo(info::SourceInfo, options::DumpOptions)::Bool
  local b::Bool

  b = begin
    @match options, info begin
      (DUMPOPTIONS(fileName = ""), _)  => begin
        true
      end

      (DUMPOPTIONS(), SOURCEINFO())  => begin
        options.fileName == info.fileName
      end
    end
  end
  #=  The default is to not filter
  =#
  b
end

function dumpExpStr(exp::Absyn.Exp)::String
  local str::String

  Print.clearBuf()
  printExp(exp)
  str = Print.getString()
  str
end

function dumpExp(exp::Absyn.Exp)
  local str::String

  Print.clearBuf()
  printExp(exp)
  str = Print.getString()
  print(str)
  print("--------------------\n")
end

#= Prints a program, i.e. the whole AST, to the Print buffer. =#
function dump(inProgram::Absyn.Program)
  _ = begin
    local cs::Lst
    local w::Absyn.Within
    @match inProgram begin
      Absyn.PROGRAM(classes = cs, within_ = w)  => begin
        Print.printBuf("Absyn.PROGRAM([\n")
        printList(cs, printClass, ", ")
        Print.printBuf("],")
        dumpWithin(w)
        Print.printBuf(")\n")
        ()
      end
    end
  end
end

#= Prettyprints the Program, i.e. the whole AST, to a string. =#
function unparseStr(inProgram::Absyn.Program, markup #=
                    Used by MathCore, and dependencies to other modules requires this to also be in OpenModelica.
                    Contact peter.aronsson@mathcore.com for an explanation.

                    Note: This will be used for a different purpose in OpenModelica once we redesign Dump to use templates
                    ... by sending in DumpOptions (for example to add markup, etc)
                    =#::Bool, options::DumpOptions)::String
  local outString::String

  outString = Tpl.tplString2(AbsynDumpTpl.dump, inProgram, options)
  outString
end

#= Prettyprints a list of classes =#
function unparseClassList(inClasses::Lst)::String
  local outString::String

  outString = Tpl.tplString2(AbsynDumpTpl.dump, Absyn.PROGRAM(inClasses, Absyn.TOP()), defaultDumpOptions)
  outString
end

#= Prettyprints a Class. =#
function unparseClassStr(inClass::Absyn.Class)::String
  local outString::String

  outString = Tpl.tplString2(AbsynDumpTpl.dumpClass, inClass, defaultDumpOptions)
  outString
end

#= Prettyprints a within statement. =#
function unparseWithin(inWithin::Absyn.Within)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpWithin, inWithin)
  outString
end

#= Dumps within to the Print buffer. =#
function dumpWithin(inWithin::Absyn.Within)
  _ = begin
    local p::Absyn.Path
    @match inWithin begin
      Absyn.TOP()  => begin
        Print.printBuf("Absyn.TOP")
        ()
      end

      Absyn.WITHIN(path = p)  => begin
        Print.printBuf("Absyn.WITHIN(")
        dumpPath(p)
        Print.printBuf("\n")
        ()
      end
    end
  end
end

#= Prettyprints Class attributes. =#
function unparseClassAttributesStr(inClass::Absyn.Class)::String
  local outString::String

  outString = begin
    local s1::String
    local s2::String
    local s2_1::String
    local s3::String
    local str::String
    local n::String
    local p::Bool
    local f::Bool
    local e::Bool
    local r::Absyn.Restriction
    @match inClass begin
      Absyn.CLASS(partialPrefix = p, finalPrefix = f, encapsulatedPrefix = e, restriction = r)  => begin
        s1 = selectString(p, "partial ", "")
        s2 = selectString(f, "final ", "")
        s2_1 = selectString(e, "encapsulated ", "")
        s3 = unparseRestrictionStr(r)
        str = stringAppendList(list(s2_1, s1, s2, s3))
        str
      end
    end
  end
  outString
end

#= Prettyprints a Comment. =#
function unparseCommentOption(inComment::Option)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpCommentOpt, inComment)
  outString
end

#= Prints a Comment to the Print buffer. =#
function dumpCommentOption(inAbsynCommentOption::Option)
  _ = begin
    local str::String
    local cmt::String
    local annopt::Option
    @match inAbsynCommentOption begin
      NONE()  => begin
        Print.printBuf("NONE()")
        ()
      end

      SOME(Absyn.COMMENT(annopt, SOME(cmt)))  => begin
        Print.printBuf("SOME(Absyn.COMMENT(")
        dumpAnnotationOption(annopt)
        str = stringAppendList(list("SOME(\"", cmt, "\")))"))
        Print.printBuf(str)
        ()
      end

      SOME(Absyn.COMMENT(annopt, NONE()))  => begin
        Print.printBuf("SOME(Absyn.COMMENT(")
        dumpAnnotationOption(annopt)
        Print.printBuf(",NONE()))")
        ()
      end
    end
  end
end

#= Dumps an annotation option to the Print buffer. =#
function dumpAnnotationOption(inAbsynAnnotationOption::Option)
  _ = begin
    local mod::Lst
    @match inAbsynAnnotationOption begin
      NONE()  => begin
        Print.printBuf("NONE()")
        ()
      end

      SOME(Absyn.ANNOTATION(mod))  => begin
        Print.printBuf("SOME(Absyn.ANNOTATION(")
        printMod1(mod)
        Print.printBuf("))")
        ()
      end
    end
  end
end

#= Prints enumeration literals, each consisting of an
identifier and an optional comment to the Print buffer. =#
function printEnumliterals(lst::Lst)
  Print.printBuf("[")
  printEnumliterals2(lst)
  Print.printBuf("]")
end

#= Helper function to printEnumliterals =#
function printEnumliterals2(inAbsynEnumLiteralLst::Lst)
  _ = begin
    local str::String
    local str2::String
    local optcmt::Option
    local optcmt2::Option
    local a::Absyn.EnumLiteral
    local b::Lst
    @matchcontinue inAbsynEnumLiteralLst begin
      nil()  => begin
        ()
      end

      Absyn.ENUMLITERAL(literal = str, comment = optcmt) <| a <| b  => begin
        Print.printBuf("Absyn.ENUMLITERAL(\"")
        Print.printBuf(str)
        Print.printBuf("\",")
        dumpCommentOption(optcmt)
        Print.printBuf("), ")
        printEnumliterals2(a <| b)
        ()
      end

      Absyn.ENUMLITERAL(literal = str, comment = optcmt) <| Absyn.ENUMLITERAL(literal = str2, comment = optcmt2) <|  nil()  => begin
        Print.printBuf("Absyn.ENUMLITERAL(\"")
        Print.printBuf(str)
        Print.printBuf("\",")
        dumpCommentOption(optcmt)
        Print.printBuf("), Absyn.ENUMLITERAL(\"")
        Print.printBuf(str2)
        Print.printBuf("\",")
        dumpCommentOption(optcmt2)
        Print.printBuf(")")
        ()
      end
    end
  end
end

#= Prettyprints the class restriction. =#
function unparseRestrictionStr(inRestriction::Absyn.Restriction)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpRestriction, inRestriction)
  outString
end

#= author: adrpo, 2006-02-05
Dumps an Info to the Print buffer. =#
function printInfo(inInfo::SourceInfo)
  _ = begin
    local s1::String
    local s2::String
    local s3::String
    local s4::String
    local filename::String
    local isReadOnly::Bool
    local sline::ModelicaInteger
    local scol::ModelicaInteger
    local eline::ModelicaInteger
    local ecol::ModelicaInteger
    @match inInfo begin
      SOURCEINFO(fileName = filename, isReadOnly = isReadOnly, lineNumberStart = sline, columnNumberStart = scol, lineNumberEnd = eline, columnNumberEnd = ecol)  => begin
        Print.printBuf("SOURCEINFO(\"")
        Print.printBuf(filename)
        Print.printBuf("\", ")
        printBool(isReadOnly)
        Print.printBuf(", ")
        s1 = intString(sline)
        Print.printBuf(s1)
        Print.printBuf(", ")
        s2 = intString(scol)
        Print.printBuf(s2)
        Print.printBuf(", ")
        s3 = intString(eline)
        Print.printBuf(s3)
        Print.printBuf(", ")
        s4 = intString(ecol)
        Print.printBuf(s4)
        Print.printBuf(")")
        ()
      end
    end
  end
end

#= author: adrpo, 2006-02-05
Translates Info to a string representation =#
function unparseInfoStr(inInfo::SourceInfo)::String
  local outString::String

  outString = begin
    local s1::String
    local s2::String
    local s3::String
    local s4::String
    local s5::String
    local str::String
    local filename::String
    local isReadOnly::Bool
    local sline::ModelicaInteger
    local scol::ModelicaInteger
    local eline::ModelicaInteger
    local ecol::ModelicaInteger
    @match inInfo begin
      SOURCEINFO(fileName = filename, isReadOnly = isReadOnly, lineNumberStart = sline, columnNumberStart = scol, lineNumberEnd = eline, columnNumberEnd = ecol)  => begin
        s1 = selectString(isReadOnly, "readonly", "writable")
        s2 = intString(sline)
        s3 = intString(scol)
        s4 = intString(eline)
        s5 = intString(ecol)
        str = stringAppendList(list("SOURCEINFO(\"", filename, "\", ", s1, ", ", s2, ", ", s3, ", ", s4, ", ", s5, ")\n"))
        str
      end
    end
  end
  outString
end

#= Dumps a Class to the Print buffer.
changed by adrpo, 2006-02-05 to use printInfo. =#
function printClass(inClass::Absyn.Class)
  _ = begin
    local n::String
    local p::Bool
    local f::Bool
    local e::Bool
    local r::Absyn.Restriction
    local cdef::Absyn.ClassDef
    local info::SourceInfo
    @match inClass begin
      Absyn.CLASS(name = n, partialPrefix = p, finalPrefix = f, encapsulatedPrefix = e, restriction = r, body = cdef, info = info)  => begin
        Print.printBuf("Absyn.CLASS(\"")
        Print.printBuf(n)
        Print.printBuf("\", ")
        printBool(p)
        Print.printBuf(", ")
        printBool(f)
        Print.printBuf(", ")
        printBool(e)
        Print.printBuf(", ")
        printClassRestriction(r)
        Print.printBuf(", ")
        printClassdef(cdef)
        Print.printBuf(", ")
        printInfo(info)
        Print.printBuf(")\n")
        ()
      end
    end
  end
end

#= Prints a ClassDef to the Print buffer. =#
function printClassdef(inClassDef::Absyn.ClassDef)
  _ = begin
    local parts::Lst
    local commentStr::Option
    local comment::Option
    local s::String
    local baseClassName::String
    local tspec::Absyn.TypeSpec
    local attr::Absyn.ElementAttributes
    local earg::Lst
    local modifications::Lst
    local enumlst::Lst
    @match inClassDef begin
      Absyn.PARTS(classParts = parts, comment = commentStr)  => begin
        Print.printBuf("Absyn.PARTS([")
        printListDebug("print_classdef", parts, printClassPart, ", ")
        Print.printBuf("], ")
        printStringCommentOption(commentStr)
        Print.printBuf(")")
        ()
      end

      Absyn.CLASS_EXTENDS(baseClassName = baseClassName, modifications = modifications, parts = parts, comment = commentStr)  => begin
        Print.printBuf("Absyn.CLASS_EXTENDS([")
        Print.printBuf(baseClassName)
        Print.printBuf(",[")
        printList(modifications, printElementArg, ",")
        Print.printBuf("], ")
        printStringCommentOption(commentStr)
        Print.printBuf(", ")
        Print.printBuf("Absyn.PARTS([")
        printListDebug("print_classdef", parts, printClassPart, ", ")
        Print.printBuf("]))")
        ()
      end

      Absyn.DERIVED(typeSpec = tspec, attributes = attr, arguments = earg, comment = comment)  => begin
        Print.printBuf("Absyn.DERIVED(")
        s = unparseTypeSpec(tspec)
        Print.printBuf(s)
        Print.printBuf(", ")
        printElementattr(attr)
        Print.printBuf(",[")
        printList(earg, printElementArg, ",")
        Print.printBuf("], ")
        s = unparseCommentOption(comment)
        Print.printBuf(s)
        Print.printBuf(")")
        ()
      end

      Absyn.ENUMERATION(enumLiterals = Absyn.ENUMLITERALS(enumLiterals = enumlst), comment = comment)  => begin
        Print.printBuf("Absyn.ENUMERATION(")
        printEnumliterals(enumlst)
        Print.printBuf(", ")
        dumpCommentOption(comment)
        Print.printBuf(")")
        ()
      end

      Absyn.ENUMERATION(enumLiterals = Absyn.ENUM_COLON(), comment = comment)  => begin
        Print.printBuf("Absyn.ENUMERATION( :, ")
        dumpCommentOption(comment)
        Print.printBuf(")")
        ()
      end

      Absyn.OVERLOAD()  => begin
        Print.printBuf("Absyn.OVERLOAD( fill in )")
        ()
      end
    end
  end
end

#= Prints the class restriction to the Print buffer. =#
function printClassRestriction(inRestriction::Absyn.Restriction)
  _ = begin
    @matchcontinue inRestriction begin
      Absyn.R_CLASS()  => begin
        Print.printBuf("Absyn.R_CLASS")
        ()
      end

      Absyn.R_OPTIMIZATION()  => begin
        Print.printBuf("Absyn.R_OPTIMIZATION")
        ()
      end

      Absyn.R_MODEL()  => begin
        Print.printBuf("Absyn.R_MODEL")
        ()
      end

      Absyn.R_RECORD()  => begin
        Print.printBuf("Absyn.R_RECORD")
        ()
      end

      Absyn.R_BLOCK()  => begin
        Print.printBuf("Absyn.R_BLOCK")
        ()
      end

      Absyn.R_CONNECTOR()  => begin
        Print.printBuf("Absyn.R_CONNECTOR")
        ()
      end

      Absyn.R_EXP_CONNECTOR()  => begin
        Print.printBuf("Absyn.R_EXP_CONNECTOR")
        ()
      end

      Absyn.R_TYPE()  => begin
        Print.printBuf("Absyn.R_TYPE")
        ()
      end

      Absyn.R_PACKAGE()  => begin
        Print.printBuf("Absyn.R_PACKAGE")
        ()
      end

      Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.IMPURE()))  => begin
        Print.printBuf("Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.IMPURE))")
        ()
      end

      Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.PURE()))  => begin
        Print.printBuf("Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.PURE))")
        ()
      end

      Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.NO_PURITY()))  => begin
        Print.printBuf("Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.NO_PURITY))")
        ()
      end

      Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION())  => begin
        Print.printBuf("Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION)")
        ()
      end

      Absyn.R_FUNCTION(Absyn.FR_PARALLEL_FUNCTION())  => begin
        Print.printBuf("Absyn.R_FUNCTION(Absyn.FR_PARALLEL_FUNCTION)")
        ()
      end

      Absyn.R_FUNCTION(Absyn.FR_KERNEL_FUNCTION())  => begin
        Print.printBuf("Absyn.R_FUNCTION(Absyn.FR_KERNEL_FUNCTION)")
        ()
      end

      Absyn.R_OPERATOR()  => begin
        Print.printBuf("Absyn.R_OPERATOR")
        ()
      end

      Absyn.R_OPERATOR_RECORD()  => begin
        Print.printBuf("Absyn.R_OPERATOR_RECORD")
        ()
      end

      Absyn.R_ENUMERATION()  => begin
        Print.printBuf("Absyn.R_ENUMERATION")
        ()
      end

      Absyn.R_PREDEFINED_INTEGER()  => begin
        Print.printBuf("Absyn.R_PREDEFINED_INTEGER")
        ()
      end

      Absyn.R_PREDEFINED_REAL()  => begin
        Print.printBuf("Absyn.R_PREDEFINED_REAL")
        ()
      end

      Absyn.R_PREDEFINED_STRING()  => begin
        Print.printBuf("Absyn.R_PREDEFINED_STRING")
        ()
      end

      Absyn.R_PREDEFINED_BOOLEAN()  => begin
        Print.printBuf("Absyn.R_PREDEFINED_BOOLEAN")
        ()
      end

      Absyn.R_PREDEFINED_CLOCK()  => begin
        Print.printBuf("Absyn.R_PREDEFINED_CLOCK")
        ()
      end

      Absyn.R_PREDEFINED_ENUMERATION()  => begin
        Print.printBuf("Absyn.R_PREDEFINED_ENUMERATION")
        ()
      end

      Absyn.R_UNIONTYPE()  => begin
        Print.printBuf("Absyn.R_UNIONTYPE")
        ()
      end

      _  => begin
        Print.printBuf("/* UNKNOWN RESTRICTION! FIXME! */")
        ()
      end
    end
  end
  #=  BTH
  =#
end

#= Prints a class modification to a print buffer. =#
function printClassModification(inAbsynElementArgLst::Lst)
  _ = begin
    local l::Lst
    @matchcontinue inAbsynElementArgLst begin
      nil()  => begin
        ()
      end

      l  => begin
        Print.printBuf("(")
        printListDebug("print_class_modification", l, printElementArg, ",")
        Print.printBuf(")")
        ()
      end
    end
  end
end

#= Prints an ElementArg to the Print buffer. =#
function printElementArg(inElementArg::Absyn.ElementArg)
  _ = begin
    local f::Bool
    local each_::Absyn.Each
    local optm::Option
    local optcmt::Option
    local keywords::Absyn.RedeclareKeywords
    local spec::Absyn.ElementSpec
    local p::Absyn.Path
    @match inElementArg begin
      Absyn.MODIFICATION(finalPrefix = f, eachPrefix = each_, path = p, modification = optm, comment = optcmt)  => begin
        Print.printBuf("Absyn.MODIFICATION(")
        printBool(f)
        Print.printBuf(", ")
        dumpEach(each_)
        Print.printBuf(", ")
        printPath(p)
        Print.printBuf(", ")
        printOptModification(optm)
        Print.printBuf(", ")
        printStringCommentOption(optcmt)
        Print.printBuf(")")
        ()
      end

      Absyn.REDECLARATION(finalPrefix = f, elementSpec = spec)  => begin
        Print.printBuf("Absyn.REDECLARATION(")
        printBool(f)
        printElementspec(spec)
        Print.printBuf(",_)")
        ()
      end
    end
  end
end

#= Prettyprints the each keyword. =#
function unparseEachStr(inEach::Absyn.Each)::String
  local outString::String

  outString = begin
    @match inEach begin
      Absyn.EACH()  => begin
        "each "
      end

      Absyn.NON_EACH()  => begin
        ""
      end
    end
  end
  outString
end

#= Print the each keyword to the Print buffer =#
function dumpEach(inEach::Absyn.Each)
  _ = begin
    @match inEach begin
      Absyn.EACH()  => begin
        Print.printBuf("Absyn.EACH")
        ()
      end

      Absyn.NON_EACH()  => begin
        Print.printBuf("Absyn.NON_EACH")
        ()
      end
    end
  end
end

#= Prints the ClassPart to the Print buffer. =#
function printClassPart(inClassPart::Absyn.ClassPart)
  _ = begin
    local el::Lst
    local eqs::Lst
    #=  list<Absyn.ConstraintItem> constr;
    =#
    local algs::Lst
    local exps::Lst
    local edecl::Absyn.ExternalDecl
    @match inClassPart begin
      Absyn.PUBLIC(contents = el)  => begin
        Print.printBuf("Absyn.PUBLIC(")
        printElementitems(el)
        Print.printBuf(")")
        ()
      end

      Absyn.PROTECTED(contents = el)  => begin
        Print.printBuf("Absyn.PROTECTED(")
        printElementitems(el)
        Print.printBuf(")")
        ()
      end

      Absyn.EQUATIONS(contents = eqs)  => begin
        Print.printBuf("Absyn.EQUATIONS([")
        printList(eqs, printEquationitem, ", ")
        Print.printBuf("])")
        ()
      end

      Absyn.CONSTRAINTS(contents = exps)  => begin
        Print.printBuf("Absyn.CONSTRAINTS([")
        printList(exps, printExp, "; ")
        Print.printBuf("])")
        ()
      end

      Absyn.INITIALEQUATIONS(contents = eqs)  => begin
        Print.printBuf("Absyn.INITIALEQUATIONS([")
        printList(eqs, printEquationitem, ", ")
        Print.printBuf("])")
        ()
      end

      Absyn.ALGORITHMS(contents = algs)  => begin
        Print.printBuf("Absyn.ALGORITHMS(")
        printList(algs, printAlgorithmitem, ", ")
        Print.printBuf(")")
        ()
      end

      Absyn.INITIALALGORITHMS(contents = algs)  => begin
        Print.printBuf("Absyn.INITIALALGORITHMS([")
        printList(algs, printAlgorithmitem, ", ")
        Print.printBuf("])")
        ()
      end

      Absyn.EXTERNAL(externalDecl = edecl)  => begin
        Print.printBuf("Absyn.EXTERNAL(")
        printExternalDecl(edecl)
        Print.printBuf(")")
        ()
      end
    end
  end
end

#= Prints an external declaration to the Print buffer. =#
function printExternalDecl(inExternalDecl::Absyn.ExternalDecl)
  _ = begin
    local idstr::String
    local crefstr::String
    local expstr::String
    local str::String
    local lang::String
    local id::Option
    local cref::Option
    local exps::Lst
    @match inExternalDecl begin
      Absyn.EXTERNALDECL(funcName = id, lang = NONE(), output_ = cref, args = exps)  => begin
        idstr = Util.getOptionOrDefault(id, "")
        crefstr = getOptionStr(cref, printComponentRefStr)
        expstr = printListStr(exps, printExpStr, ",")
        str = stringAppendList(list(idstr, ", ", crefstr, ", (", expstr, ")"))
        Print.printBuf(str)
        ()
      end

      Absyn.EXTERNALDECL(funcName = id, lang = SOME(lang), output_ = cref, args = exps)  => begin
        idstr = Util.getOptionOrDefault(id, "")
        crefstr = getOptionStr(cref, printComponentRefStr)
        expstr = printListStr(exps, printExpStr, ",")
        str = stringAppendList(list(idstr, ", \"", lang, "\", ", crefstr, ", (", expstr, ")"))
        Print.printBuf(str)
        ()
      end
    end
  end
end

#= Print a list of ElementItems to the Print buffer. =#
function printElementitems(elts::Lst)
  Print.printBuf("[")
  printElementitems2(elts)
  Print.printBuf("]")
end

#= Helper function to printElementitems =#
function printElementitems2(inAbsynElementItemLst::Lst)
  _ = begin
    local e::Absyn.Element
    local a::Absyn.Annotation
    local els::Lst
    @matchcontinue inAbsynElementItemLst begin
      nil()  => begin
        ()
      end

      Absyn.ELEMENTITEM(element = e) <|  nil()  => begin
        Print.printBuf("Absyn.ELEMENTITEM(")
        printElement(e)
        Print.printBuf(")")
        ()
      end

      Absyn.ELEMENTITEM(element = e) <| els  => begin
        Print.printBuf("Absyn.ELEMENTITEM(")
        printElement(e)
        Print.printBuf("), ")
        printElementitems2(els)
        ()
      end

      _  => begin
        Print.printBuf("Error Dump.printElementitems2\n")
        ()
      end
    end
  end
end

#= Prints an annotation to the Print buffer. =#
function printAnnotation(inAnnotation::Absyn.Annotation)
  _ = begin
    local mod::Lst
    @match inAnnotation begin
      Absyn.ANNOTATION(elementArgs = mod)  => begin
        Print.printBuf("ANNOTATION(")
        printModification(Absyn.CLASSMOD(mod, Absyn.NOMOD()))
        Print.printBuf(")")
        ()
      end
    end
  end
end

#= Prettyprints an Absyn.ElementArg =#
function unparseElementArgStr(inElementArg::Absyn.ElementArg)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpElementArg, inElementArg)
  outString
end

#= Prettyprints and ElementItem. =#
function unparseElementItemStr(inElementItem::Absyn.ElementItem)::String
  local outString::String

  outString = Tpl.tplString2(AbsynDumpTpl.dumpElementItem, inElementItem, defaultDumpOptions)
  outString
end

#= Prettyprint an annotation. =#
function unparseAnnotation(inAnnotation::Absyn.Annotation)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpAnnotation, inAnnotation)
  outString
end

#= Prettyprint an annotation. =#
function unparseAnnotationOption(inAbsynAnnotation::Option)::String
  local outString::String

  outString = begin
    local ann::Absyn.Annotation
    @match inAbsynAnnotation begin
      SOME(ann)  => begin
        unparseAnnotation(ann)
      end

      _  => begin
        ""
      end
    end
  end
  outString
end

#=
Prints an Element to the Print buffer.
changed by adrpo, 2006-02-06 to use print_info and dump Absyn.TEXT also
=#
function printElement(inElement::Absyn.Element)
  _ = begin
    local finalPrefix::Bool
    local repl::Option
    local inout::Absyn.InnerOuter
    local name::String
    local text::String
    local spec::Absyn.ElementSpec
    local info::SourceInfo
    @match inElement begin
      Absyn.ELEMENT(finalPrefix = finalPrefix, innerOuter = inout, specification = spec, info = info, constrainClass = NONE())  => begin
        Print.printBuf("Absyn.ELEMENT(")
        printBool(finalPrefix)
        Print.printBuf(", _")
        Print.printBuf(", ")
        printInnerouter(inout)
        Print.printBuf(", ")
        printElementspec(spec)
        Print.printBuf(", ")
        printInfo(info)
        Print.printBuf("),NONE())")
        ()
      end

      Absyn.ELEMENT(finalPrefix = finalPrefix, innerOuter = inout, specification = spec, info = info, constrainClass = SOME(_))  => begin
        Print.printBuf("Absyn.ELEMENT(")
        printBool(finalPrefix)
        Print.printBuf(", _")
        Print.printBuf(", ")
        printInnerouter(inout)
        Print.printBuf(",")
        printElementspec(spec)
        Print.printBuf(", ")
        printInfo(info)
        Print.printBuf(", SOME(...))")
        ()
      end

      Absyn.TEXT(optName = SOME(name), string = text, info = info)  => begin
        Print.printBuf("Absyn.TEXT(")
        Print.printBuf("SOME(\"")
        Print.printBuf(name)
        Print.printBuf("\"), \"")
        Print.printBuf(text)
        Print.printBuf("\", ")
        printInfo(info)
        Print.printBuf(")")
        ()
      end

      Absyn.TEXT(optName = NONE(), string = text, info = info)  => begin
        Print.printBuf("Absyn.TEXT(")
        Print.printBuf("NONE, \"")
        Print.printBuf(text)
        Print.printBuf("\", ")
        printInfo(info)
        Print.printBuf(")")
        ()
      end
    end
  end
end

#= Prints the inner or outer keyword to the Print buffer. =#
function printInnerouter(inInnerOuter::Absyn.InnerOuter)
  _ = begin
    @match inInnerOuter begin
      Absyn.INNER()  => begin
        Print.printBuf("Absyn.INNER")
        ()
      end

      Absyn.OUTER()  => begin
        Print.printBuf("Absyn.OUTER")
        ()
      end

      Absyn.INNER_OUTER()  => begin
        Print.printBuf("Absyn.INNER_OUTER ")
        ()
      end

      Absyn.NOT_INNER_OUTER()  => begin
        Print.printBuf("Absyn.NOT_INNER_OUTER ")
        ()
      end
    end
  end
end

#=
Prettyprints the inner or outer keyword to a string.
=#
function unparseInnerouterStr(inInnerOuter::Absyn.InnerOuter)::String
  local outString::String

  outString = begin
    @match inInnerOuter begin
      Absyn.INNER()  => begin
        "inner "
      end

      Absyn.OUTER()  => begin
        "outer "
      end

      Absyn.INNER_OUTER()  => begin
        "inner outer "
      end

      Absyn.NOT_INNER_OUTER()  => begin
        ""
      end
    end
  end
  outString
end

#= Prints the ElementSpec to the Print buffer. =#
function printElementspec(inElementSpec::Absyn.ElementSpec)
  _ = begin
    local repl::Bool
    local cl::Absyn.Class
    local p::Absyn.Path
    local l::Lst
    local s::String
    local attr::Absyn.ElementAttributes
    local t::Absyn.TypeSpec
    local cs::Lst
    local i::Absyn.Import
  local ann::Absyn.Annotation
    @matchcontinue inElementSpec begin
      Absyn.CLASSDEF(replaceable_ = repl, class_ = cl)  => begin
        Print.printBuf("Absyn.CLASSDEF(")
        printBool(repl)
        Print.printBuf(", ")
        printClass(cl)
        Print.printBuf(")")
        ()
      end

      Absyn.EXTENDS(path = p, elementArg = l, annotationOpt = SOME(ann))  => begin
        Print.printBuf("Absyn.EXTENDS(")
        dumpPath(p)
        Print.printBuf(", [")
        printListDebug("print_elementspec", l, printElementArg, ",")
        printAnnotation(ann)
        Print.printBuf("])")
        ()
      end

      Absyn.EXTENDS(path = p, elementArg = l, annotationOpt = NONE())  => begin
        Print.printBuf("Absyn.EXTENDS(")
        dumpPath(p)
        Print.printBuf(", [")
        printListDebug("print_elementspec", l, printElementArg, ",")
        Print.printBuf("])")
        ()
      end

      Absyn.COMPONENTS(attributes = attr, typeSpec = t, components = cs)  => begin
        Print.printBuf("Absyn.COMPONENTS(")
        printElementattr(attr)
        Print.printBuf(",")
        s = unparseTypeSpec(t)
        Print.printBuf(s)
        Print.printBuf(",[")
        printListDebug("print_elementspec", cs, printComponentitem, ",")
        Print.printBuf("])")
        ()
      end

      Absyn.IMPORT(import_ = i)  => begin
        Print.printBuf("Absyn.IMPORT(")
        printImport(i)
        Print.printBuf(")")
        ()
      end

      _  => begin
        Print.printBuf(" ##ERROR## ")
        ()
      end
    end
  end
end

#= Prints an Import to the Print buffer. =#
function printImport(inImport::Absyn.Import)
  _ = begin
    local i::String
    local p::Absyn.Path
    local groups::Lst
    @match inImport begin
      Absyn.NAMED_IMPORT(name = i, path = p)  => begin
        Print.printBuf(i)
        Print.printBuf(" = ")
        printPath(p)
        ()
      end

      Absyn.QUAL_IMPORT(path = p)  => begin
        printPath(p)
        ()
      end

      Absyn.UNQUAL_IMPORT(path = p)  => begin
        printPath(p)
        Print.printBuf(".*")
        ()
      end

      Absyn.GROUP_IMPORT(prefix = p, groups = groups)  => begin
        printPath(p)
        Print.printBuf(".{")
        Print.printBuf(stringDelimitList(List.map(groups, unparseGroupImport), ","))
        Print.printBuf("}")
        ()
      end

      _  => begin
        Print.printBuf("/* Unknown import */")
        ()
      end
    end
  end
end

function unparseGroupImport(gimp::Absyn.GroupImport)::String
  local str::String

  str = begin
    local name::String
    local rename::String
    @match gimp begin
      Absyn.GROUP_IMPORT_NAME(name = name)  => begin
        name
      end

      Absyn.GROUP_IMPORT_RENAME(rename = rename, name = name)  => begin
        rename + " = " + name
      end
    end
  end
  str
end

#= Prettyprints an Import to a string. =#
function unparseImportStr(inImport::Absyn.Import)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpImport, inImport)
  outString
end

#= Prints ElementAttributes to the Print buffer. =#
function printElementattr(inElementAttributes::Absyn.ElementAttributes)
  _ = begin
    local vs::String
    local ds::String
    local ps::String
    local fl::Bool
    local st::Bool
    local par::Absyn.Parallelism
    local var::Absyn.Variability
    local dir::Absyn.Direction
    local adim::Lst
    @matchcontinue inElementAttributes begin
      Absyn.ATTR(flowPrefix = fl, streamPrefix = st, parallelism = par, variability = var, direction = dir, arrayDim = adim)  => begin
        Print.printBuf("Absyn.ATTR(")
        printBool(fl)
        Print.printBuf(", ")
        printBool(st)
        Print.printBuf(", ")
        ps = parallelSymbol(par)
        Print.printBuf(ps)
        Print.printBuf(", ")
        vs = variabilitySymbol(var)
        Print.printBuf(vs)
        Print.printBuf(", ")
        ds = directionSymbol(dir)
        Print.printBuf(ds)
        Print.printBuf(", ")
        printArraydim(adim)
        Print.printBuf(")")
        ()
      end

      _  => begin
        Print.printBuf(" ##ERROR## print_elementattr")
        ()
      end
    end
  end
end

#=
Returns a string for the Variability.
=#
function parallelSymbol(inparallel::Absyn.Parallelism)::String
  local outString::String

  outString = begin
    @match inparallel begin
      Absyn.NON_PARALLEL()  => begin
        "Absyn.NON_PARALLEL"
      end

      Absyn.PARGLOBAL()  => begin
        "Absyn.PARGLOBAL"
      end

      Absyn.PARLOCAL()  => begin
        "Absyn.PARLOCAL"
      end
    end
  end
  outString
end

#=
Returns a string for the Variability.
=#
function variabilitySymbol(inVariability::Absyn.Variability)::String
  local outString::String

  outString = begin
    @match inVariability begin
      Absyn.VAR()  => begin
        "Absyn.VAR"
      end

      Absyn.DISCRETE()  => begin
        "Absyn.DISCRETE"
      end

      Absyn.PARAM()  => begin
        "Absyn.PARAM"
      end

      Absyn.CONST()  => begin
        "Absyn.CONST"
      end
    end
  end
  outString
end

#=
Returns a string for the direction.
=#
function directionSymbol(inDirection::Absyn.Direction)::String
  local outString::String

  outString = begin
    @match inDirection begin
      Absyn.BIDIR()  => begin
        "Absyn.BIDIR"
      end

      Absyn.INPUT()  => begin
        "Absyn.INPUT"
      end

      Absyn.OUTPUT()  => begin
        "Absyn.OUTPUT"
      end
    end
  end
  outString
end

#=
Returns a prettyprinted string of variability.
=#
function unparseVariabilitySymbolStr(inVariability::Absyn.Variability)::String
  local outString::String

  outString = begin
    @match inVariability begin
      Absyn.VAR()  => begin
        ""
      end

      Absyn.DISCRETE()  => begin
        "discrete "
      end

      Absyn.PARAM()  => begin
        "parameter "
      end

      Absyn.CONST()  => begin
        "constant "
      end
    end
  end
  outString
end

#= Returns a prettyprinted string of direction. =#
function unparseDirectionSymbolStr(inDirection::Absyn.Direction)::String
  local outString::String

  outString = begin
    @match inDirection begin
      Absyn.BIDIR()  => begin
        ""
      end

      Absyn.INPUT()  => begin
        "input "
      end

      Absyn.OUTPUT()  => begin
        "output "
      end
    end
  end
  outString
end

function unparseParallelismSymbolStr(inParallelism::Absyn.Parallelism)::String
  local outString::String

  outString = begin
    @match inParallelism begin
      Absyn.NON_PARALLEL()  => begin
        ""
      end

      Absyn.PARGLOBAL()  => begin
        "parglobal "
      end

      Absyn.PARLOCAL()  => begin
        "parlocal "
      end
    end
  end
  outString
end

#= Prints a Component to the Print buffer. =#
function printComponent(inComponent::Absyn.Component)
  _ = begin
    local n::String
    local a::Lst
    local m::Option
    @match inComponent begin
      Absyn.COMPONENT(name = n, arrayDim = a, modification = m)  => begin
        Print.printBuf("Absyn.COMPONENT(\"")
        Print.printBuf(n)
        Print.printBuf("\",")
        printArraydim(a)
        Print.printBuf(", ")
        printOption(m, printModification)
        Print.printBuf(")")
        ()
      end
    end
  end
end

#= Prints a ComponentItem to the Print buffer. =#
function printComponentitem(inComponentItem::Absyn.ComponentItem)
  _ = begin
    local c::Absyn.Component
    local optcond::Option
    local optcmt::Option
    @match inComponentItem begin
      Absyn.COMPONENTITEM(component = c, comment = optcmt)  => begin
        Print.printBuf("Absyn.COMPONENTITEM(")
        printComponent(c)
        Print.printBuf(", ")
        dumpCommentOption(optcmt)
        Print.printBuf(")")
        ()
      end
    end
  end
end

#= Prints a ComponentCondition option to a string. =#
function unparseComponentCondition(inComponentCondition::Option)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpComponentCondition, inComponentCondition)
  outString
end

#=
Prints an ArrayDim option to the Print buffer.
=#
function printArraydimOpt(inAbsynArrayDimOption::Option)
  _ = begin
    local s::Lst
    @match inAbsynArrayDimOption begin
      NONE()  => begin
        Print.printBuf("NONE()")
        ()
      end

      SOME(s)  => begin
        Print.printBuf("SOME(")
        printSubscripts(s)
        Print.printBuf(")")
        ()
      end
    end
  end
end

#=
Prints an ArrayDim to the Print buffer.
=#
function printArraydim(s::Absyn.ArrayDim)
  printSubscripts(s)
end

#=
Prettyprints an ArrayDim to a string.
=#
function printArraydimStr(s::Absyn.ArrayDim)::String
  local str::String

  str = printSubscriptsStr(s)
  str
end

#=
Prints an Subscript to the Print buffer.
=#
function printSubscript(inSubscript::Absyn.Subscript)
  _ = begin
    local e1::Absyn.Exp
    @match inSubscript begin
      Absyn.NOSUB()  => begin
        Print.printBuf("Absyn.NOSUB")
        ()
      end

      Absyn.SUBSCRIPT(subscript = e1)  => begin
        Print.printBuf("Absyn.SUBSCRIPT(")
        printExp(e1)
        Print.printBuf(")")
        ()
      end
    end
  end
end

#=
Prettyprints an Subscript to a string.
=#
function printSubscriptStr(inSubscript::Absyn.Subscript)::String
  local outString::String

  outString = begin
    local s::String
    local e1::Absyn.Exp
    @match inSubscript begin
      Absyn.NOSUB()  => begin
        ":"
      end

      Absyn.SUBSCRIPT(subscript = e1)  => begin
        s = printExpStr(e1)
        s
      end
    end
  end
  outString
end

#=
Prints a Modification option to the Print buffer.
=#
function printOptModification(inAbsynModificationOption::Option)
  _ = begin
    local m::Absyn.Modification
    @match inAbsynModificationOption begin
      SOME(m)  => begin
        Print.printBuf("SOME(")
        printModification(m)
        Print.printBuf(")")
        ()
      end

      NONE()  => begin
        ()
      end
    end
  end
end

#=
Prints a Modification to the Print buffer.
=#
function printModification(inModification::Absyn.Modification)
  _ = begin
    local l::Lst
    local e::Absyn.EqMod
    @matchcontinue inModification begin
      Absyn.CLASSMOD(elementArgLst = l, eqMod = e)  => begin
        Print.printBuf("Absyn.CLASSMOD([")
        printMod1(l)
        Print.printBuf("], ")
        printMod2(e)
        Print.printBuf(")")
        ()
      end

      _  => begin
        Print.printBuf("( ** MODIFICATION ** )")
        ()
      end
    end
  end
end

#=
Helper relaton to print_modification.
=#
function printMod1(inAbsynElementArgLst::Lst)
  _ = begin
    local l::Lst
    @matchcontinue inAbsynElementArgLst begin
      nil()  => begin
        ()
      end

      l  => begin
        Print.printBuf("(")
        printListDebug("print_mod1", l, printElementArg, ",")
        Print.printBuf(")")
        ()
      end
    end
  end
end

#=
Helper relaton to print_mod1
=#
function printMod2(inAbsynExpOption::Absyn.EqMod)
  _ = begin
    local e::Absyn.Exp
    @match inAbsynExpOption begin
      Absyn.NOMOD()  => begin
        Print.printBuf("Absyn.NOMOD()")
        ()
      end

      Absyn.EQMOD(exp = e)  => begin
        Print.printBuf("Absyn.EQMOD([")
        printExp(e)
        Print.printBuf("])")
        ()
      end
    end
  end
end

#= Prettyprints a Modification to a string. =#
function unparseModificationStr(inModification::Absyn.Modification)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpModification, inModification)
  outString
end

function equationName(eq::Absyn.Equation)::String
  local name::String

  name = begin
    @match eq begin
      Absyn.EQ_IF()  => begin
        "if"
      end

      Absyn.EQ_EQUALS()  => begin
        "equals"
      end

      Absyn.EQ_PDE()  => begin
        "pde"
      end

      Absyn.EQ_CONNECT()  => begin
        "connect"
      end

      Absyn.EQ_WHEN_E()  => begin
        "when"
      end

      Absyn.EQ_NORETCALL()  => begin
        "function call"
      end

      Absyn.EQ_FAILURE()  => begin
        "failure"
      end
    end
  end
  name
end

#= Equations
function: printEquation
Prints an Equation to the Print buffer. =#
function printEquation(inEquation::Absyn.Equation)
  _ = begin
    local e::Absyn.Exp
    local e1::Absyn.Exp
    local e2::Absyn.Exp
    local tb::Lst
    local fb::Lst
    local el::Lst
    local eb::Lst
    local iterators::Absyn.ForIterators
    local equItem::Absyn.EquationItem
    local cr::Absyn.ComponentRef
    local fargs::Absyn.FunctionArgs
    local cr1::Absyn.ComponentRef
    local cr2::Absyn.ComponentRef
    @matchcontinue inEquation begin
      Absyn.EQ_IF(ifExp = e, equationTrueItems = tb, elseIfBranches = eb, equationElseItems = fb)  => begin
        Print.printBuf("IF (")
        printExp(e)
        Print.printBuf(") THEN ")
        printListDebug("print_equation", tb, printEquationitem, ";")
        printListDebug("print_equation", eb, printEqElseif, " ")
        Print.printBuf(" ELSE ")
        printListDebug("print_equation", fb, printEquationitem, ";")
        ()
      end

      Absyn.EQ_EQUALS(leftSide = e1, rightSide = e2)  => begin
        Print.printBuf("EQ_EQUALS(")
        printExp(e1)
        Print.printBuf(",")
        printExp(e2)
        Print.printBuf(")")
        ()
      end

      Absyn.EQ_PDE(leftSide = e1, rightSide = e2, domain = cr)  => begin
        Print.printBuf("EQ_PDE(")
        printExp(e1)
        Print.printBuf(",")
        printExp(e2)
        Print.printBuf(") indomain ")
        printComponentRef(cr)
        ()
      end

      Absyn.EQ_NORETCALL(functionName = cr, functionArgs = fargs)  => begin
        Print.printBuf("EQ_NORETCALL(")
        Print.printBuf(printComponentRefStr(cr) + "(")
        Print.printBuf(printFunctionArgsStr(fargs))
        Print.printBuf(")")
        ()
      end

      Absyn.EQ_CONNECT(connector1 = cr1, connector2 = cr2)  => begin
        Print.printBuf("EQ_CONNECT(")
        printComponentRef(cr1)
        Print.printBuf(",")
        printComponentRef(cr2)
        Print.printBuf(")")
        ()
      end

      Absyn.EQ_FOR(iterators = iterators, forEquations = el)  => begin
        Print.printBuf("FOR ")
        printListDebug("print_iterators", iterators, printIterator, ", ")
        Print.printBuf(" {")
        printListDebug("print_equation", el, printEquationitem, ";")
        Print.printBuf("}")
        ()
      end

      Absyn.EQ_FAILURE(equItem)  => begin
        Print.printBuf("FAILURE(")
        printEquationitem(equItem)
        Print.printBuf(")")
        ()
      end

      _  => begin
        Print.printBuf(" ** UNKNOWN EQUATION ** ")
        ()
      end
    end
  end
  #= /* EQ_NORETCALL */ =#
end

#= Prints and EquationItem to the Print buffer. =#
function printEquationitem(inEquationItem::Absyn.EquationItem)
  _ = begin
    local eq::Absyn.Equation
    @match inEquationItem begin
      Absyn.EQUATIONITEM(equation_ = eq)  => begin
        Print.printBuf("EQUATIONITEM(")
        printEquation(eq)
        Print.printBuf(", <comment>)\n")
        ()
      end
    end
  end
end

#= Prettyprints an Equation to a string. =#
function unparseClassPart(classPart::Absyn.ClassPart)::String
  local outString::String

  outString = Tpl.tplString3(AbsynDumpTpl.dumpClassPart, classPart, 0, defaultDumpOptions)
  outString
end

#= Prettyprints an Equation to a string. =#
function unparseEquationStr(inEquation::Absyn.Equation)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpEquation, inEquation)
  outString
end

#= Prettyprints an EquationItem to a string. =#
function unparseEquationItemStr(inEquation::Absyn.EquationItem)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpEquationItem, inEquation)
  outString
end

#= Prettyprints and EquationItem list to a string. =#
function unparseEquationItemStrLst(inEquationItems::Lst, inSeparator::String)::String
  local outString::String

  outString = stringDelimitList(List.map(inEquationItems, unparseEquationItemStr), inSeparator)
  outString
end

#= Prints an Elseif branch to the Print buffer. =#
function printEqElseif(inElseIfBranch::Tuple)
  local e::Absyn.Exp
  local el::Lst

  e, el = inElseIfBranch
  Print.printBuf(" ELSEIF ")
  printExp(e)
  Print.printBuf(" THEN ")
  printListDebug("print_eq_elseif", el, printEquationitem, ";")
end

#= Algorithm clauses
function: printAlgorithmitem
Prints an AlgorithmItem to the Print buffer. =#
function printAlgorithmitem(inAlgorithmItem::Absyn.AlgorithmItem)
  _ = begin
    local alg::Absyn.Algorithm
    local ann::Absyn.Annotation
    @match inAlgorithmItem begin
      Absyn.ALGORITHMITEM(algorithm_ = alg)  => begin
        Print.printBuf("ALGORITHMITEM(")
        printAlgorithm(alg)
        Print.printBuf(")\n")
        ()
      end
    end
  end
end

#= Prints an Algorithm to the Print buffer. =#
function printAlgorithm(inAlgorithm::Absyn.Algorithm)
  _ = begin
    local cr::Absyn.ComponentRef
    local exp::Absyn.Exp
    local e::Absyn.Exp
    local assignComp::Absyn.Exp
    local tb::Lst
    local fb::Lst
    local el::Lst
    local al::Lst
    local eb::Lst
    local iterators::Absyn.ForIterators
    local algItem::Absyn.AlgorithmItem
    local fargs::Absyn.FunctionArgs
    @matchcontinue inAlgorithm begin
      Absyn.ALG_ASSIGN(assignComponent = assignComp, value = exp)  => begin
        Print.printBuf("ALG_ASSIGN(")
        printExp(assignComp)
        Print.printBuf(" := ")
        printExp(exp)
        Print.printBuf(")")
        ()
      end

      Absyn.ALG_NORETCALL(functionCall = cr, functionArgs = fargs)  => begin
        Print.printBuf("ALG_NORETCALL(")
        Print.printBuf(printComponentRefStr(cr) + "(")
        Print.printBuf(printFunctionArgsStr(fargs))
        Print.printBuf(")")
        ()
      end

      Absyn.ALG_IF(ifExp = e, trueBranch = tb, elseIfAlgorithmBranch = eb, elseBranch = fb)  => begin
        Print.printBuf("IF (")
        printExp(e)
        Print.printBuf(") THEN ")
        printListDebug("print_algorithm", tb, printAlgorithmitem, ";")
        printListDebug("print_algorithm", eb, printAlgElseif, " ")
        Print.printBuf(" ELSE ")
        printListDebug("print_algorithm", fb, printAlgorithmitem, ";")
        ()
      end

      Absyn.ALG_FOR(iterators = iterators, forBody = el)  => begin
        Print.printBuf("FOR ")
        printListDebug("print_iterators", iterators, printIterator, ", ")
        Print.printBuf(" {")
        printListDebug("print_algorithm", el, printAlgorithmitem, ";")
        Print.printBuf("}")
        ()
      end

      Absyn.ALG_PARFOR(iterators = iterators, parforBody = el)  => begin
        Print.printBuf("PARFOR ")
        printListDebug("print_iterators", iterators, printIterator, ", ")
        Print.printBuf(" {")
        printListDebug("print_algorithm", el, printAlgorithmitem, ";")
        Print.printBuf("}")
        ()
      end

      Absyn.ALG_WHILE(boolExpr = e, whileBody = al)  => begin
        Print.printBuf("WHILE ")
        printExp(e)
        Print.printBuf(" {")
        printListDebug("print_algorithm", al, printAlgorithmitem, ";")
        Print.printBuf("}")
        ()
      end

      Absyn.ALG_WHEN_A(boolExpr = e, whenBody = al)  => begin
        Print.printBuf("WHEN_A ")
        printExp(e)
        Print.printBuf(" {")
        printListDebug("print_algorithm", al, printAlgorithmitem, ";")
        Print.printBuf("}")
        ()
      end

      Absyn.ALG_RETURN()  => begin
        Print.printBuf("RETURN()")
        ()
      end

      Absyn.ALG_BREAK()  => begin
        Print.printBuf("BREAK()")
        ()
      end

      Absyn.ALG_FAILURE(algItem <|  nil())  => begin
        Print.printBuf("FAILURE(")
        printAlgorithmitem(algItem)
        Print.printBuf(")")
        ()
      end

      Absyn.ALG_FAILURE(_)  => begin
        Print.printBuf("FAILURE(...)")
        ()
      end

      _  => begin
        Print.printBuf(" ** UNKNOWN ALGORITHM CLAUSE ** ")
        ()
      end
    end
  end
  #= /* ALG_NORETCALL */ =#
  #= /* rule  Print.print_buf \\\"WHEN_E \\\" & print_exp(e) &
  Print.print_buf \\\" {\\\" & print_list_debug(\\\"print_algorithm\\\",al, print_algorithmitem, \\\";\\\") & Print.print_buf \\\"}\\\"
  ----------------------------------------------------------
  print_algorithm Absyn.ALG_WHEN_E(e,al)
  */ =#
end

#= Prettyprints an AlgorithmItem list to a string. =#
function unparseAlgorithmStrLst(inAlgorithmItems::Lst, inSeparator::String)::String
  local outString::String

  outString = stringDelimitList(List.map(inAlgorithmItems, unparseAlgorithmStr), inSeparator)
  outString
end

#= Helper function to unparseAlgorithmStr =#
function unparseAlgorithmStr(inAlgorithmItem::Absyn.AlgorithmItem)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpAlgorithmItem, inAlgorithmItem)
  outString
end

#= Prints an algorithm elseif branch to the Print buffer. =#
function printAlgElseif(inElseIfBranch::Tuple)
  local e::Absyn.Exp
  local el::Lst

  e, el = inElseIfBranch
  Print.printBuf(" ELSEIF ")
  printExp(e)
  Print.printBuf(" THEN ")
  printListDebug("print_alg_elseif", el, printAlgorithmitem, ";")
end

#= Component references and paths
function: printComponentRef
Print a ComponentRef to the Print buffer. =#
function printComponentRef(inComponentRef::Absyn.ComponentRef)
  _ = begin
    local s::String
    local subs::Lst
    local cr::Absyn.ComponentRef
    @match inComponentRef begin
      Absyn.CREF_IDENT(name = s, subscripts = subs)  => begin
        Print.printBuf("Absyn.CREF_IDENT(\"")
        Print.printBuf(s)
        Print.printBuf("\", ")
        printSubscripts(subs)
        Print.printBuf(")")
        ()
      end

      Absyn.CREF_QUAL(name = s, subscripts = subs, componentRef = cr)  => begin
        Print.printBuf("Absyn.CREF_QUAL(\"")
        Print.printBuf(s)
        Print.printBuf("\", ")
        printSubscripts(subs)
        Print.printBuf(",")
        printComponentRef(cr)
        Print.printBuf(")")
        ()
      end

      Absyn.WILD()  => begin
        Print.printBuf("Absyn.WILD")
        ()
      end

      Absyn.ALLWILD()  => begin
        Print.printBuf("Absyn.ALLWILD")
        ()
      end
    end
  end
  #=  MetaModelica wildcard
  =#
end

#= Prints a Subscript to the Print buffer. =#
function printSubscripts(inAbsynSubscriptLst::Lst)
  _ = begin
    local l::Lst
    @matchcontinue inAbsynSubscriptLst begin
      nil()  => begin
        Print.printBuf("[]")
        ()
      end

      l  => begin
        Print.printBuf("[")
        printListDebug("print_subscripts", l, printSubscript, ",")
        Print.printBuf("]")
        ()
      end
    end
  end
end

#= Print a ComponentRef and return as a string. =#
function printComponentRefStr(inComponentRef::Absyn.ComponentRef)::String
  local outString::String

  outString = begin
    local subsstr::String
    local s_1::String
    local s::String
    local crs::String
    local s_2::String
    local s_3::String
    local subs::Lst
    local cr::Absyn.ComponentRef
    @match inComponentRef begin
      Absyn.CREF_IDENT(name = s, subscripts = subs)  => begin
        subsstr = printSubscriptsStr(subs)
        s_1 = stringAppend(s, subsstr)
        s_1
      end

      Absyn.CREF_QUAL(name = s, subscripts = subs, componentRef = cr)  => begin
        crs = printComponentRefStr(cr)
        subsstr = printSubscriptsStr(subs)
        s_1 = stringAppend(s, subsstr)
        s_2 = stringAppend(s_1, ".")
        s_3 = stringAppend(s_2, crs)
        s_3
      end

      Absyn.CREF_FULLYQUALIFIED(componentRef = cr)  => begin
        crs = printComponentRefStr(cr)
        s_3 = stringAppend(".", crs)
        s_3
      end

      Absyn.ALLWILD()  => begin
        "__"
      end

      Absyn.WILD()  => begin
        if Config.acceptMetaModelicaGrammar() "_"
        else
          ""
        end
      end
    end
  end
  outString
end

#= Prettyprint a Subscript list to a string. =#
function printSubscriptsStr(inAbsynSubscriptLst::Lst)::String
  local outString::String

  outString = begin
    local s::String
    local s_1::String
    local s_2::String
    local l::Lst
    @matchcontinue inAbsynSubscriptLst begin
      nil()  => begin
        ""
      end

      l  => begin
        s = printListStr(l, printSubscriptStr, ",")
        s_1 = stringAppend("[", s)
        s_2 = stringAppend(s_1, "]")
        s_2
      end
    end
  end
  outString
end

#= Print a Path. =#
function printPath(p::Absyn.Path)
  "I am a path hurrdurr"
end

#= Dumps path to the Print buffer =#
function dumpPath(inPath::Absyn.Path)
  _ = begin
    local str::String
    local path::Absyn.Path
    @match inPath begin
      Absyn.IDENT(name = str)  => begin
        Print.printBuf("Absyn.IDENT(\"")
        Print.printBuf(str)
        Print.printBuf("\")")
        ()
      end

      Absyn.QUALIFIED(name = str, path = path)  => begin
        Print.printBuf("Absyn.QUALIFIED(\"")
        Print.printBuf(str)
        Print.printBuf("\",")
        dumpPath(path)
        Print.printBuf(")")
        ()
      end
    end
  end
end

#= This function prints a complete expression to the Print buffer. =#
function printExp(inExp::Absyn.Exp)
  _ = begin
    local s::String
    local sym::String
    local i::ModelicaInteger
    local r::ModelicaReal
    local c::Absyn.ComponentRef
    local fcn::Absyn.ComponentRef
    local e1::Absyn.Exp
    local e2::Absyn.Exp
    local e::Absyn.Exp
    local t::Absyn.Exp
    local f::Absyn.Exp
    local start::Absyn.Exp
    local stop::Absyn.Exp
    local step::Absyn.Exp
    local op::Absyn.Operator
    local lst::Lst
    local args::Absyn.FunctionArgs
    local es::Lst
    local matchType::Absyn.MatchType
    local head::Absyn.Exp
    local rest::Absyn.Exp
    local inputExp::Absyn.Exp
    local cond::Absyn.Exp
    local localDecls::Lst
    local cases::Lst
    local comment::Option
    local esLst::Lst
    @matchcontinue inExp begin
      Absyn.INTEGER(value = i)  => begin
        s = intString(i)
        Print.printBuf("Absyn.INTEGER(")
        Print.printBuf(s)
        Print.printBuf(")")
        ()
      end

      Absyn.REAL(value = s)  => begin
        Print.printBuf("Absyn.REAL(")
        Print.printBuf(s)
        Print.printBuf(")")
        ()
      end

      Absyn.CREF(componentRef = c)  => begin
        Print.printBuf("Absyn.CREF(")
        printComponentRef(c)
        Print.printBuf(")")
        ()
      end

      Absyn.STRING(value = s)  => begin
        Print.printBuf("Absyn.STRING(\"")
        Print.printBuf(s)
        Print.printBuf("\")")
        ()
      end

      Absyn.BOOL(value = false)  => begin
        Print.printBuf("Absyn.BOOL(false)")
        ()
      end

      Absyn.BOOL(value = true)  => begin
        Print.printBuf("Absyn.BOOL(true)")
        ()
      end

      Absyn.BINARY(exp1 = e1, op = op, exp2 = e2)  => begin
        sym = dumpOpSymbol(op)
        Print.printBuf("Absyn.BINARY(")
        printExp(e1)
        Print.printBuf(",")
        Print.printBuf(sym)
        Print.printBuf(",")
        printExp(e2)
        Print.printBuf(")")
        ()
      end

      Absyn.UNARY(op = op, exp = e)  => begin
        sym = dumpOpSymbol(op)
        Print.printBuf("Absyn.UNARY(")
        Print.printBuf(sym)
        Print.printBuf(", ")
        printExp(e)
        Print.printBuf(")")
        ()
      end

      Absyn.LBINARY(exp1 = e1, op = op, exp2 = e2)  => begin
        sym = dumpOpSymbol(op)
        Print.printBuf("Absyn.LBINARY(")
        printExp(e1)
        Print.printBuf(",")
        Print.printBuf(sym)
        Print.printBuf(",")
        printExp(e2)
        Print.printBuf(")")
        ()
      end

      Absyn.LUNARY(op = op, exp = e)  => begin
        sym = dumpOpSymbol(op)
        Print.printBuf("Absyn.UNARY(")
        Print.printBuf(sym)
        Print.printBuf(", ")
        printExp(e)
        Print.printBuf(")")
        ()
      end

      Absyn.RELATION(exp1 = e1, op = op, exp2 = e2)  => begin
        sym = dumpOpSymbol(op)
        Print.printBuf("Absyn.RELATION(")
        printExp(e1)
        Print.printBuf(",")
        Print.printBuf(sym)
        Print.printBuf(",")
        printExp(e2)
        Print.printBuf(")")
        ()
      end

      Absyn.IFEXP(ifExp = cond, trueBranch = t, elseBranch = f)  => begin
        Print.printBuf("Absyn.IFEXP(")
        printExp(cond)
        Print.printBuf(", ")
        printExp(t)
        Print.printBuf(", ")
        printExp(f)
        Print.printBuf(")")
        ()
      end

      Absyn.CALL(function_ = fcn, functionArgs = args)  => begin
        Print.printBuf("Absyn.CALL(")
        printComponentRef(fcn)
        Print.printBuf(", ")
        printFunctionArgs(args)
        Print.printBuf(")")
        ()
      end

      Absyn.PARTEVALFUNCTION(function_ = fcn, functionArgs = args)  => begin
        Print.printBuf("Absyn.PARTEVALFUNCTION(")
        printComponentRef(fcn)
        Print.printBuf(", ")
        printFunctionArgs(args)
        Print.printBuf(")")
        ()
      end

      Absyn.ARRAY(arrayExp = es)  => begin
        Print.printBuf("Absyn.ARRAY([")
        printListDebug("print_exp", es, printExp, ",")
        Print.printBuf("])")
        ()
      end

      Absyn.TUPLE(expressions = es)  => begin
        Print.printBuf("Absyn.TUPLE([")
        Print.printBuf("(")
        printListDebug("print_exp", es, printExp, ",")
        Print.printBuf("])")
        ()
      end

      Absyn.MATRIX(matrix = esLst)  => begin
        Print.printBuf("Absyn.MATRIX([")
        printListDebug("print_exp", esLst, printRow, ";")
        Print.printBuf("])")
        ()
      end

      Absyn.RANGE(start = start, step = NONE(), stop = stop)  => begin
        Print.printBuf("Absyn.RANGE(")
        printExp(start)
        Print.printBuf(",NONE(),")
        printExp(stop)
        Print.printBuf(")")
        ()
      end

      Absyn.RANGE(start = start, step = SOME(step), stop = stop)  => begin
        Print.printBuf("Absyn.RANGE(")
        printExp(start)
        Print.printBuf(",SOME(")
        printExp(step)
        Print.printBuf("),")
        printExp(stop)
        Print.printBuf(")")
        ()
      end

      Absyn.END()  => begin
        Print.printBuf("Absyn.END")
        ()
      end

      Absyn.LIST(es)  => begin
        Print.printBuf("Absyn.LIST([")
        printListDebug("print_exp", es, printExp, ",")
        Print.printBuf("])")
        ()
      end

      Absyn.CONS(head, rest)  => begin
        Print.printBuf("Absyn.CONS(")
        printExp(head)
        Print.printBuf(", ")
        printExp(rest)
        Print.printBuf(")")
        ()
      end

      Absyn.AS(s, rest)  => begin
        Print.printBuf("Absyn.AS(")
        Print.printBuf(s)
        Print.printBuf(", ")
        printExp(rest)
        Print.printBuf(")")
        ()
      end

_  => begin
  Print.printBuf("#UNKNOWN EXPRESSION#")
  ()
end
end
end
#= /* PR. */ =#
#=  MetaModelica expressions!
=#
end

#=
MetaModelica construct printing
@author Adrian Pop  =#
function printMatchType(matchType::Absyn.MatchType)::String
  local out::String

  out = begin
    @match matchType begin
      Absyn.MATCH()  => begin
        "match"
      end

      Absyn.MATCHCONTINUE()  => begin
        "matchcontinue"
      end
    end
  end
  out
end

#=
Prints FunctionArgs to Print buffer.
=#
function printFunctionArgs(inFunctionArgs::Absyn.FunctionArgs)
  _ = begin
    local expargs::Lst
    local nargs::Lst
    local exp::Absyn.Exp
    local iterators::Absyn.ForIterators
    @match inFunctionArgs begin
      Absyn.FUNCTIONARGS(args = expargs, argNames = nargs)  => begin
        Print.printBuf("FUNCTIONARGS(")
        printListDebug("print_exp", expargs, printExp, ", ")
        Print.printBuf(", ")
        printListDebug("print_namedarg", nargs, printNamedArg, ", ")
        Print.printBuf(")")
        ()
      end

      Absyn.FOR_ITER_FARG(exp = exp, iterators = iterators)  => begin
        Print.printBuf("FOR_ITER_FARG(")
        printExp(exp)
        Print.printBuf(", ")
        printListDebug("print_iterators", iterators, printIterator, ", ")
        Print.printBuf(")")
        ()
      end
    end
  end
end

#=  @author adrpo
prints iterator: (i,exp1) =#
function printIterator(iterator::Absyn.ForIterator)
  _ = begin
    local exp::Absyn.Exp
    local id::Absyn.Ident
    @match iterator begin
      Absyn.ITERATOR(id, NONE(), SOME(exp))  => begin
        Print.printBuf("(")
        Print.printBuf(id)
        Print.printBuf(", ")
        printExp(exp)
        Print.printBuf(")")
        ()
      end

      Absyn.ITERATOR(id, NONE(), NONE())  => begin
        Print.printBuf("(")
        Print.printBuf(id)
        Print.printBuf(")")
        ()
      end
    end
  end
end

#=
Prettyprint FunctionArgs to a string.
=#
function printFunctionArgsStr(inFunctionArgs::Absyn.FunctionArgs)::String
  local outString::String

  outString = begin
    local s1::String
    local s2::String
    local s3::String
    local str::String
    local estr::String
    local istr::String
    local expargs::Lst
    local nargs::Lst
    local exp::Absyn.Exp
    local iterators::Absyn.ForIterators
    @matchcontinue inFunctionArgs begin
      Absyn.FUNCTIONARGS(args = expargs = _ <| _, argNames = nargs = _ <| _)  => begin
        s1 = printListStr(expargs, printExpStr, ", ") #= Both positional and named arguments =#
        s2 = stringAppend(s1, ", ")
        s3 = printListStr(nargs, printNamedArgStr, ", ")
        str = stringAppend(s2, s3)
        str
      end

      Absyn.FUNCTIONARGS(args =  nil(), argNames = nargs)  => begin
        str = printListStr(nargs, printNamedArgStr, ", ") #= Only named arguments =#
        str
      end

      Absyn.FUNCTIONARGS(args = expargs, argNames =  nil())  => begin
        str = printListStr(expargs, printExpStr, ", ") #= Only positional arguments =#
        str
      end

      Absyn.FOR_ITER_FARG(exp = exp, iterators = iterators)  => begin
        estr = printExpStr(exp)
        istr = printIteratorsStr(iterators)
        str = stringAppendList(list(estr, " for ", istr))
        str
      end
    end
  end
  outString
end

#=  @author adrpo
prints iterators: i in exp1, j in exp2, k in exp3 =#
function printIteratorsStr(iterators::Absyn.ForIterators)::String
  local iteratorsStr::String

  iteratorsStr = begin
    local s::String
    local s1::String
    local s2::String
    local guardExp::Absyn.Exp
    local exp::Absyn.Exp
    local id::Absyn.Ident
    local rest::Absyn.ForIterators
    local x::Absyn.ForIterator
    @matchcontinue iterators begin
      nil()  => begin
        ""
      end

      Absyn.ITERATOR(id, SOME(guardExp), SOME(exp)) <|  nil()  => begin
        s1 = printExpStr(exp)
        s2 = printExpStr(guardExp)
        s = stringAppendList(list(id, " guard ", s2, " in ", s1))
        s
      end

      Absyn.ITERATOR(id, NONE(), SOME(exp)) <|  nil()  => begin
        s1 = printExpStr(exp)
        s = stringAppendList(list(id, " in ", s1))
        s
      end

      Absyn.ITERATOR(id, NONE(), NONE()) <|  nil()  => begin
        id
      end

      x <| rest  => begin
        s1 = printIteratorsStr(list(x))
        s2 = printIteratorsStr(rest)
        s = stringAppendList(list(s1, ", ", s2))
        s
      end
    end
  end
  iteratorsStr
end

#= Print NamedArg to the Print buffer. =#
function printNamedArg(inNamedArg::Absyn.NamedArg)
  _ = begin
    local ident::String
    local e::Absyn.Exp
    @match inNamedArg begin
      Absyn.NAMEDARG(argName = ident, argValue = e)  => begin
        Print.printBuf(ident)
        Print.printBuf(" = ")
        printExp(e)
        ()
      end
    end
  end
end

#= Prettyprint NamedArg to a string. =#
function printNamedArgStr(inNamedArg::Absyn.NamedArg)::String
  local outString::String

  outString = begin
    local s1::String
    local s2::String
    local str::String
    local ident::String
    local e::Absyn.Exp
    @match inNamedArg begin
      Absyn.NAMEDARG(argName = ident, argValue = e)  => begin
        s1 = stringAppend(ident, " = ")
        s2 = printExpStr(e)
        str = stringAppend(s1, s2)
        str
      end
    end
  end
  outString
end

#= Prettyprint NamedArg value to a string. =#
function printNamedArgValueStr(inNamedArg::Absyn.NamedArg)::String
  local outString::String

  outString = begin
    local str::String
    local e::Absyn.Exp
    @match inNamedArg begin
      Absyn.NAMEDARG(argValue = e)  => begin
        str = printExpStr(e)
        str
      end
    end
  end
  outString
end

#=
Print an Expression list to the Print buffer.
=#
function printRow(es::Lst)
  printListDebug("print_row", es, printExp, ",")
end

#= Determines whether an operand in an expression needs parentheses around it. =#
function shouldParenthesize(inOperand::Absyn.Exp, inOperator::Absyn.Exp, inLhs::Bool)::Bool
  local outShouldParenthesize::Bool

  outShouldParenthesize = begin
    local diff::ModelicaInteger
    @match inOperand, inOperator, inLhs begin
      (Absyn.UNARY(), _, _)  => begin
        true
      end

      _  => begin
        diff = Util.intCompare(expPriority(inOperand, inLhs), expPriority(inOperator, inLhs))
        shouldParenthesize2(diff, inOperand, inLhs)
      end
    end
  end
  outShouldParenthesize
end

function shouldParenthesize2(inPrioDiff::ModelicaInteger, inOperand::Absyn.Exp, inLhs::Bool)::Bool
  local outShouldParenthesize::Bool

  outShouldParenthesize = begin
    @match inPrioDiff, inOperand, inLhs begin
      (1, _, _)  => begin
        true
      end

      (0, _, false)  => begin
        ! isAssociativeExp(inOperand)
      end

      _  => begin
        false
      end
    end
  end
  outShouldParenthesize
end

#= Determines whether the given expression represents an associative operation or not. =#
function isAssociativeExp(inExp::Absyn.Exp)::Bool
  local outIsAssociative::Bool

  outIsAssociative = begin
    local op::Absyn.Operator
    @match inExp begin
      Absyn.BINARY(op = op)  => begin
        isAssociativeOp(op)
      end

      Absyn.LBINARY()  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  outIsAssociative
end

#= Determines whether the given operator is associative or not. =#
function isAssociativeOp(inOperator::Absyn.Operator)::Bool
  local outIsAssociative::Bool

  outIsAssociative = begin
    @match inOperator begin
      Absyn.ADD()  => begin
        true
      end

      Absyn.ADD_EW()  => begin
        true
      end

      Absyn.MUL_EW()  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  outIsAssociative
end

#= Returns an integer priority given an expression, which is used by
printOperatorStr to add parentheses around operands when dumping expressions.
The inLhs argument should be true if the expression occurs on the left side
of a binary operation, otherwise false. This is because we don't need to add
parentheses to expressions such as x * y / z, but x / (y * z) needs them, so
the priorities of some binary operations differ depending on which side they
are. =#
function expPriority(inExp::Absyn.Exp, inLhs::Bool)::ModelicaInteger
  local outPriority::ModelicaInteger

  outPriority = begin
    local op::Absyn.Operator
    @match inExp, inLhs begin
      (Absyn.BINARY(op = op), false)  => begin
        priorityBinopRhs(op)
      end

      (Absyn.BINARY(op = op), true)  => begin
        priorityBinopLhs(op)
      end

      (Absyn.UNARY(), _)  => begin
        4
      end

      (Absyn.LBINARY(op = op), _)  => begin
        priorityLBinop(op)
      end

      (Absyn.LUNARY(), _)  => begin
        7
      end

      (Absyn.RELATION(), _)  => begin
        6
      end

      (Absyn.RANGE(), _)  => begin
        10
      end

      (Absyn.IFEXP(), _)  => begin
        11
      end

      _  => begin
        0
      end
    end
  end
  outPriority
end

#= Returns the priority for a binary operation on the left hand side. Add and
sub has the same priority, and mul and div too, in contrast with
priorityBinopRhs. =#
function priorityBinopLhs(inOp::Absyn.Operator)::ModelicaInteger
  local outPriority::ModelicaInteger

  outPriority = begin
    @match inOp begin
      Absyn.ADD()  => begin
        5
      end

      Absyn.SUB()  => begin
        5
      end

      Absyn.MUL()  => begin
        2
      end

      Absyn.DIV()  => begin
        2
      end

      Absyn.POW()  => begin
        1
      end

      Absyn.ADD_EW()  => begin
        5
      end

      Absyn.SUB_EW()  => begin
        5
      end

      Absyn.MUL_EW()  => begin
        2
      end

      Absyn.DIV_EW()  => begin
        2
      end

      Absyn.POW_EW()  => begin
        1
      end
    end
  end
  outPriority
end

#= Returns the priority for a binary operation on the right hand side. Add and
sub has different priorities, and mul and div too, in contrast with
priorityBinopLhs. =#
function priorityBinopRhs(inOp::Absyn.Operator)::ModelicaInteger
  local outPriority::ModelicaInteger

  outPriority = begin
    @match inOp begin
      Absyn.ADD()  => begin
        6
      end

      Absyn.SUB()  => begin
        5
      end

      Absyn.MUL()  => begin
        2
      end

      Absyn.DIV()  => begin
        2
      end

      Absyn.POW()  => begin
        1
      end

      Absyn.ADD_EW()  => begin
        6
      end

      Absyn.SUB_EW()  => begin
        5
      end

      Absyn.MUL_EW()  => begin
        3
      end

      Absyn.DIV_EW()  => begin
        2
      end

      Absyn.POW_EW()  => begin
        1
      end
    end
  end
  outPriority
end

function priorityLBinop(inOp::Absyn.Operator)::ModelicaInteger
  local outPriority::ModelicaInteger

  outPriority = begin
    @match inOp begin
      Absyn.AND()  => begin
        8
      end

      Absyn.OR()  => begin
        9
      end
    end
  end
  outPriority
end

#= Prints an operand to a string. =#
function printOperandStr(inOperand #= The operand expression. =#::Absyn.Exp, inOperation #= The unary/binary operation which the operand belongs to. =#::Absyn.Exp, inLhs #= True if the operand is the left hand operand, otherwise false. =#::Bool)::String
  local outString::String

  outString = begin
    local op_str::String
    #=  Print parentheses around an operand if the priority of the operation is
    =#
    #=  less than the priority of the operand.
    =#
    @matchcontinue inOperand, inOperation, inLhs begin
      (_, _, _)  => begin
        @assert true == (shouldParenthesize(inOperand, inOperation, inLhs))
        op_str = printExpStr(inOperand)
        op_str = stringAppendList(list("(", op_str, ")"))
        op_str
      end

      _  => begin
        printExpStr(inOperand)
      end
    end
  end
  outString
end

#= exp

Prints a list of expressions to a string
=#
function printExpLstStr(expl::Lst)::String
  local outString::String

  outString = stringDelimitList(List.map(expl, printExpStr), ", ")
  outString
end

#=
This function prints a complete expression.
=#
function printExpStr(inExp::Absyn.Exp)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpExp, inExp)
  outString
end

#= Prettyprint Code to a string. =#
function printCodeStr(inCode::Absyn.CodeNode)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpCodeNode, inCode)
  outString
end

#= Same as printList, except it returns a string instead of printing =#
function printListStr(inTypeALst::Lst, inFuncTypeTypeAToString::FuncTypeType_aToString, inString::String)::String
  local outString::String

  outString = begin
    local s::String
    local srest::String
    local s_1::String
    local s_2::String
    local sep::String
    local h::Type_a
    local r::FuncTypeType_aToString
    local t::Lst
    @matchcontinue inTypeALst, inFuncTypeTypeAToString, inString begin
      ( nil(), _, _)  => begin
        ""
      end

      (h <|  nil(), r, _)  => begin
        s = r(h)
        s
      end

      (h <| t, r, sep)  => begin
        s = r(h)
        srest = printListStr(t, r, sep)
        s_1 = stringAppend(s, sep)
        s_2 = stringAppend(s_1, srest)
        s_2
      end
    end
  end
  outString
end

#= Make a string describing different operators. =#
function opSymbol(inOperator::Absyn.Operator)::String
  local outString::String

  outString = begin
    @match inOperator begin
      Absyn.ADD()  => begin
        " + "
      end

      Absyn.SUB()  => begin
        " - "
      end

      Absyn.MUL()  => begin
        " * "
      end

      Absyn.DIV()  => begin
        " / "
      end

      Absyn.POW()  => begin
        " ^ "
      end

      Absyn.UMINUS()  => begin
        "-"
      end

      Absyn.UPLUS()  => begin
        "+"
      end

      Absyn.ADD_EW()  => begin
        " .+ "
      end

      Absyn.SUB_EW()  => begin
        " .- "
      end

      Absyn.MUL_EW()  => begin
        " .* "
      end

      Absyn.DIV_EW()  => begin
        " ./ "
      end

      Absyn.POW_EW()  => begin
        " .^ "
      end

      Absyn.UMINUS_EW()  => begin
        " .-"
      end

      Absyn.UPLUS_EW()  => begin
        " .+"
      end

      Absyn.AND()  => begin
        " and "
      end

      Absyn.OR()  => begin
        " or "
      end

      Absyn.NOT()  => begin
        "not "
      end

      Absyn.LESS()  => begin
        " < "
      end

      Absyn.LESSEQ()  => begin
        " <= "
      end

      Absyn.GREATER()  => begin
        " > "
      end

      Absyn.GREATEREQ()  => begin
        " >= "
      end

      Absyn.EQUAL()  => begin
        " == "
      end

      Absyn.NEQUAL()  => begin
        " <> "
      end
    end
  end
  #= /* arithmetic operators */ =#
  #= /* element-wise arithmetic operators */ =#
  #= /* logical operators */ =#
  #= /* relational operators */ =#
  outString
end

#= same as opSymbol but without spaces included
used for operator overload resolving.
Some of them are not supported ?? but have them
anyway =#
function opSymbolCompact(inOperator::Absyn.Operator)::String
  local outString::String

  outString = begin
    @match inOperator begin
      Absyn.ADD()  => begin
        "+"
      end

      Absyn.SUB()  => begin
        "-"
      end

      Absyn.MUL()  => begin
        "*"
      end

      Absyn.DIV()  => begin
        "/"
      end

      Absyn.POW()  => begin
        "^"
      end

      Absyn.UMINUS()  => begin
        "-"
      end

      Absyn.UPLUS()  => begin
        "+"
      end

      Absyn.ADD_EW()  => begin
        "+"
      end

      Absyn.SUB_EW()  => begin
        "-"
      end

      Absyn.MUL_EW()  => begin
        "*"
      end

      Absyn.DIV_EW()  => begin
        "/"
      end

      Absyn.POW_EW()  => begin
        "^"
      end

      Absyn.UMINUS_EW()  => begin
        "-"
      end

      Absyn.AND()  => begin
        "and"
      end

      Absyn.OR()  => begin
        "or"
      end

      Absyn.NOT()  => begin
        "not"
      end

      Absyn.LESS()  => begin
        "<"
      end

      Absyn.LESSEQ()  => begin
        "<="
      end

      Absyn.GREATER()  => begin
        ">"
      end

      Absyn.GREATEREQ()  => begin
        ">="
      end

      Absyn.EQUAL()  => begin
        "=="
      end

      Absyn.NEQUAL()  => begin
        "<>"
      end

      _  => begin
        fail()
      end
    end
  end
  #= /* arithmetic operators */ =#
  #= /* element-wise arithmetic operators */ =#
  #=  case (Absyn.UPLUS_EW()) then \"+\";
  =#
  #= /* logical operators */ =#
  #= /* relational operators */ =#
  outString
end

#= Make a string describing different operators. =#
function dumpOpSymbol(inOperator::Absyn.Operator)::String
  local outString::String

  outString = begin
    @match inOperator begin
      Absyn.ADD()  => begin
        "Absyn.ADD"
      end

      Absyn.SUB()  => begin
        "Absyn.SUB"
      end

      Absyn.MUL()  => begin
        "Absyn.MUL"
      end

      Absyn.DIV()  => begin
        "Absyn.DIV"
      end

      Absyn.POW()  => begin
        "Absyn.POW"
      end

      Absyn.UMINUS()  => begin
        "Absyn.UMINUS"
      end

      Absyn.UPLUS()  => begin
        "Absyn.UPLUS"
      end

      Absyn.ADD_EW()  => begin
        "Absyn.ADD_EW"
      end

      Absyn.SUB_EW()  => begin
        "Absyn.SUB_EW"
      end

      Absyn.MUL_EW()  => begin
        "Absyn.MUL_EW"
      end

      Absyn.DIV_EW()  => begin
        "Absyn.DIV_EW"
      end

      Absyn.POW_EW()  => begin
        "Absyn.POW_EW"
      end

      Absyn.UMINUS_EW()  => begin
        "Absyn.UMINUS_EW"
      end

      Absyn.UPLUS_EW()  => begin
        "Absyn.UPLUS_EW"
      end

      Absyn.AND()  => begin
        "Absyn.AND"
      end

      Absyn.OR()  => begin
        "Absyn.OR"
      end

      Absyn.NOT()  => begin
        "Absyn.NOT"
      end

      Absyn.LESS()  => begin
        "Absyn.LESS"
      end

      Absyn.LESSEQ()  => begin
        "Absyn.LESSEQ"
      end

      Absyn.GREATER()  => begin
        "Absyn.GREATER"
      end

      Absyn.GREATEREQ()  => begin
        "Absyn.GREATEREQ"
      end

      Absyn.EQUAL()  => begin
        "Absyn.EQUAL"
      end

      Absyn.NEQUAL()  => begin
        "Absyn.NEQUAL"
      end
    end
  end
  #= /* arithmetic operators */ =#
  #= /* element-wise arithmetic operators */ =#
  #= /* logical operators */ =#
  #= /* relational operators */ =#
  outString
end

#= /*
*
* Utility functions
* These are utility functions used in some of the other functions.
*
*/ =#

#= Select one of the two strings depending on boolean value. =#
function selectString(inBoolean1::Bool, inString2::String, inString3::String)::String
  local outString::String

  outString = begin
    local a::String
    local b::String
    @match inBoolean1, inString2, inString3 begin
      (true, a, _)  => begin
        a
      end

      (false, _, b)  => begin
        b
      end
    end
  end
  outString
end

#=
Select one of the two string depending on boolean value
and print it on the Print buffer.
=#
function printSelect(f::Bool, yes::String, no::String)
  local res::String

  res = selectString(f, yes, no)
  Print.printBuf(res)
end

#=
Prints an option value given a print function.
=#
function printOption(inTypeAOption::Option, inFuncTypeTypeATo::FuncTypeType_aTo)
  _ = begin
    local x::Type_a
    local r::FuncTypeType_aTo
    @match inTypeAOption, inFuncTypeTypeATo begin
      (NONE(), _)  => begin
        Print.printBuf("NONE()")
        ()
      end

      (SOME(x), r)  => begin
        Print.printBuf("SOME(")
        r(x)
        Print.printBuf(")")
        ()
      end
    end
  end
end

#=
Prints a list of values given a print function and a caller string.
=#
function printListDebug(inString1::String, inTypeALst2::Lst, inFuncTypeTypeATo3::FuncTypeType_aTo, inString4::String)
  _ = begin
    local caller::String
    local s1::String
    local sep::String
    local h::Type_a
    local r::FuncTypeType_aTo
    local rest::Lst
    @match inString1, inTypeALst2, inFuncTypeTypeATo3, inString4 begin
      (_,  nil(), _, _)  => begin
        ()
      end

      (_, h <|  nil(), r, _)  => begin
        r(h)
        ()
      end

      (caller, h <| rest, r, sep)  => begin
        s1 = stringAppend("print_list_debug-3 from ", caller)
        r(h)
        Print.printBuf(sep)
        printListDebug(s1, rest, r, sep)
        ()
      end
    end
  end
end

#=
Prints a list of values given a print function.
=#
function printList(inTypeALst::Lst, inFuncTypeTypeATo::FuncTypeType_aTo, inString::String)
  _ = begin
    local h::Type_a
    local r::FuncTypeType_aTo
    local t::Lst
    local sep::String
    @matchcontinue inTypeALst, inFuncTypeTypeATo, inString begin
      ( nil(), _, _)  => begin
        ()
      end

      (h <|  nil(), r, _)  => begin
        r(h)
        ()
      end

      (h <| t, r, sep)  => begin
        r(h)
        Print.printBuf(sep)
        printList(t, r, sep)
        ()
      end
    end
  end
end

#= a value to a string.
=#
function getStringList(inTypeALst::Lst, inFuncTypeTypeAToString::FuncTypeType_aToString, inString::String)::String
  local outString::String

  outString = begin
    local s::String
    local s_1::String
    local srest::String
    local s_2::String
    local sep::String
    local h::Type_a
    local r::FuncTypeType_aToString
    local t::Lst
    @matchcontinue inTypeALst, inFuncTypeTypeAToString, inString begin
      ( nil(), _, _)  => begin
        ""
      end

      (h <|  nil(), r, _)  => begin
        s = r(h)
        s
      end

      (h <| t, r, sep)  => begin
        s = r(h)
        s_1 = stringAppend(s, sep)
        srest = getStringList(t, r, sep)
        s_2 = stringAppend(s_1, srest)
        s_2
      end
    end
  end
  outString
end

#=
Print a bool value to the Print buffer
=#
function printBool(b::Bool)
  printSelect(b, "true", "false")
end

#= Retrieve the string from a string option.
If NONE() return empty string.
=#
function getOptionStr(inTypeAOption::Option, inFuncTypeTypeAToString::FuncTypeType_aToString)::String
  local outString::String

  outString = begin
    local str::String
    local a::Type_a
    local r::FuncTypeType_aToString
    @match inTypeAOption, inFuncTypeTypeAToString begin
      (SOME(a), r)  => begin
        str = r(a)
        str
      end

      (NONE(), _)  => begin
        ""
      end
    end
  end
  outString
end

#= Retrieve the string from a string option.
If NONE() return default string.
=#
function getOptionStrDefault(inTypeAOption::Option, inFuncTypeTypeAToString::FuncTypeType_aToString, inString::String)::String
  local outString::String

  outString = begin
    local str::String
    local def::String
    local a::Type_a
    local r::FuncTypeType_aToString
    @match inTypeAOption, inFuncTypeTypeAToString, inString begin
      (SOME(a), r, _)  => begin
        str = r(a)
        str
      end

      (NONE(), _, def)  => begin
        def
      end
    end
  end
  outString
end

#=
Get option string value using a function translating the value to a string
and concatenate with an additional suffix string.
=#
function getOptionWithConcatStr(inTypeAOption::Option, inFuncTypeTypeAToString::FuncTypeType_aToString, inString::String)::String
  local outString::String

  outString = begin
    local str::String
    local str_1::String
    local default_str::String
    local a::Type_a
    local r::FuncTypeType_aToString
    @match inTypeAOption, inFuncTypeTypeAToString, inString begin
      (SOME(a), r, default_str)  => begin
        str = r(a)
        str_1 = stringAppend(default_str, str)
        str_1
      end

      (NONE(), _, _)  => begin
        ""
      end
    end
  end
  #= /* suffix */ =#
  outString
end

#=
Print a string comment option on the Print buffer
=#
function printStringCommentOption(inStringOption::Option)
  _ = begin
    local str::String
    local s::String
    @match inStringOption begin
      NONE()  => begin
        Print.printBuf("NONE()")
        ()
      end

      SOME(s)  => begin
        str = stringAppendList(list("SOME(\"", s, "\")"))
        Print.printBuf(str)
        ()
      end
    end
  end
end

#=
Prints a bool to a string.
=#
function printBoolStr(b::Bool)::String
  local s::String

  s = selectString(b, "true", "false")
  s
end

#=
Creates an indentation string, i.e. whitespaces, given and indentation
level.
=#
function indentStr(inInteger::ModelicaInteger)::String
  local outString::String

  outString = begin
    local i_1::ModelicaInteger
    local i::ModelicaInteger
    local s1::String
    local res::String
    @matchcontinue inInteger begin
      0  => begin
        ""
      end

      i  => begin
        @assert true == (i > 0)
        i_1 = i - 1
        s1 = indentStr(i_1)
        res = stringAppend(s1, "  ") #= Indent using two whitespaces =#
        res
      end

      _  => begin
        ""
      end
    end
  end
  outString
end

function unparseTypeSpec(inTypeSpec::Absyn.TypeSpec)::String
  local outString::String

  outString = Tpl.tplString(AbsynDumpTpl.dumpTypeSpec, inTypeSpec)
  outString
end

function printTypeSpec(typeSpec::Absyn.TypeSpec)
  local str::String

  str = unparseTypeSpec(typeSpec)
  print(str)
end

#=
Prints the text sent to the print buffer (Print.mo) to stdout (i.e.
using MetaModelica Compiler (MMC) standard print). After printing, the print buffer is cleared.
=#
function stdout()
  local str::String

  str = Print.getString()
  print(str)
  Print.clearBuf()
end

function getAstAsCorbaString(program::Absyn.Program)
  _ = begin
    local classes::Lst
    local within_::Absyn.Within
    @match program begin
      Absyn.PROGRAM(classes = classes, within_ = within_)  => begin
        Print.printBuf("record Absyn.PROGRAM\nclasses = ")
        printListAsCorbaString(classes, printClassAsCorbaString, ",\n")
        Print.printBuf(",\nwithin_ = ")
        printWithinAsCorbaString(within_)
        Print.printBuf("\nend Absyn.PROGRAM;")
        ()
      end
    end
  end
end

function printPathAsCorbaString(inPath::Absyn.Path)
  _ = begin
    local s::String
    local p::Absyn.Path
    @match inPath begin
      Absyn.QUALIFIED(name = s, path = p)  => begin
        Print.printBuf("record Absyn.QUALIFIED name = \"")
        Print.printBuf(s)
        Print.printBuf("\", path = ")
        printPathAsCorbaString(p)
        Print.printBuf(" end Absyn.QUALIFIED;")
        ()
      end

      Absyn.IDENT(name = s)  => begin
        Print.printBuf("record Absyn.IDENT name = \"")
        Print.printBuf(s)
        Print.printBuf("\" end Absyn.IDENT;")
        ()
      end

      Absyn.FULLYQUALIFIED(path = p)  => begin
        Print.printBuf("record Absyn.FULLYQUALIFIED path = \"")
        printPathAsCorbaString(p)
        Print.printBuf("\" end Absyn.FULLYQUALIFIED;")
        ()
      end
    end
  end
end

function printComponentRefAsCorbaString(cref::Absyn.ComponentRef)
  _ = begin
    local s::String
    local p::Absyn.ComponentRef
    local subscripts::Lst
    @match cref begin
      Absyn.CREF_QUAL(name = s, subscripts = subscripts, componentRef = p)  => begin
        Print.printBuf("record Absyn.CREF_QUAL name = \"")
        Print.printBuf(s)
        Print.printBuf("\", subscripts = ")
        printListAsCorbaString(subscripts, printSubscriptAsCorbaString, ",")
        Print.printBuf(", componentRef = ")
        printComponentRefAsCorbaString(p)
        Print.printBuf(" end Absyn.CREF_QUAL;")
        ()
      end

      Absyn.CREF_IDENT(name = s, subscripts = subscripts)  => begin
        Print.printBuf("record Absyn.CREF_IDENT name = \"")
        Print.printBuf(s)
        Print.printBuf("\", subscripts = ")
        printListAsCorbaString(subscripts, printSubscriptAsCorbaString, ",")
        Print.printBuf(" end Absyn.CREF_IDENT;")
        ()
      end

      Absyn.ALLWILD()  => begin
        Print.printBuf("record Absyn.ALLWILD end Absyn.ALLWILD;")
        ()
      end

      Absyn.WILD()  => begin
        Print.printBuf("record Absyn.WILD end Absyn.WILD;")
        ()
      end
    end
  end
end

function printWithinAsCorbaString(within_::Absyn.Within)
  _ = begin
    local path::Absyn.Path
    @match within_ begin
      Absyn.WITHIN(path = path)  => begin
        Print.printBuf("record Absyn.WITHIN path = ")
        printPathAsCorbaString(path)
        Print.printBuf(" end Absyn.WITHIN;")
        ()
      end

      Absyn.TOP()  => begin
        Print.printBuf("record Absyn.TOP end Absyn.TOP;")
        ()
      end
    end
  end
end

function printClassAsCorbaString(cl::Absyn.Class)
  _ = begin
    local name::String
    local partialPrefix::Bool
    local finalPrefix::Bool
    local encapsulatedPrefix::Bool
    local restriction::Absyn.Restriction
    local body::Absyn.ClassDef
    local info::SourceInfo
    @match cl begin
      Absyn.CLASS(name, partialPrefix, finalPrefix, encapsulatedPrefix, restriction, body, info)  => begin
        Print.printBuf("record Absyn.CLASS name = \"")
        Print.printBuf(name)
        Print.printBuf("\", partialPrefix = ")
        Print.printBuf(boolString(partialPrefix))
        Print.printBuf(", finalPrefix = ")
        Print.printBuf(boolString(finalPrefix))
        Print.printBuf(", encapsulatedPrefix = ")
        Print.printBuf(boolString(encapsulatedPrefix))
        Print.printBuf(", restriction = ")
        printRestrictionAsCorbaString(restriction)
        Print.printBuf(", body = ")
        printClassDefAsCorbaString(body)
        Print.printBuf(", info = ")
        printInfoAsCorbaString(info)
        Print.printBuf(" end Absyn.CLASS;")
        ()
      end

      _  => begin
        Error.addMessage(Error.INTERNAL_ERROR, list("printClassAsCorbaString failed"))
        fail()
      end
    end
  end
end

function printInfoAsCorbaString(info::SourceInfo)
  _ = begin
    local fileName::String
    local isReadOnly::Bool
    local lineNumberStart::ModelicaInteger
    local columnNumberStart::ModelicaInteger
    local lineNumberEnd::ModelicaInteger
    local columnNumberEnd::ModelicaInteger
    local lastModified::ModelicaReal
    @match info begin
      SOURCEINFO(fileName, isReadOnly, lineNumberStart, columnNumberStart, lineNumberEnd, columnNumberEnd, lastModified)  => begin
        Print.printBuf("record SOURCEINFO fileName = \"")
        Print.printBuf(fileName)
        Print.printBuf("\", isReadOnly = ")
        Print.printBuf(boolString(isReadOnly))
        Print.printBuf(", lineNumberStart = ")
        Print.printBuf(intString(lineNumberStart))
        Print.printBuf(", columnNumberStart = ")
        Print.printBuf(intString(columnNumberStart))
        Print.printBuf(", lineNumberEnd = ")
        Print.printBuf(intString(lineNumberEnd))
        Print.printBuf(", columnNumberEnd = ")
        Print.printBuf(intString(columnNumberEnd))
        Print.printBuf(", lastModified = ")
        Print.printBuf(realString(lastModified))
        Print.printBuf(" end SOURCEINFO;")
        ()
      end

      _  => begin
        Error.addMessage(Error.INTERNAL_ERROR, list("printInfoAsCorbaString failed"))
        fail()
      end
    end
  end
end

function printClassDefAsCorbaString(classDef::Absyn.ClassDef)
  _ = begin
    local classParts::Lst
    local optString::Option
    local typeSpec::Absyn.TypeSpec
    local attributes::Absyn.ElementAttributes
    local arguments::Lst
    local modifications::Lst
    local comment::Option
    local enumLiterals::Absyn.EnumDef
    local functionNames::Lst
    local baseClassName::String
    local functionName::Absyn.Path
    local typeVars::Lst
    local vars::Lst
    local classAttrs::Lst
    local ann::Lst
    @match classDef begin
      Absyn.PARTS(typeVars, _, classParts, ann, optString)  => begin
        Print.printBuf("record Absyn.PARTS typeVars = {")
        Print.printBuf(stringDelimitList(typeVars, ","))
        Print.printBuf("}, classParts = ")
        printListAsCorbaString(classParts, printClassPartAsCorbaString, ",")
        Print.printBuf(", ann = ")
        printListAsCorbaString(ann, printAnnotationAsCorbaString, ",")
        Print.printBuf(", comment = ")
        printStringCommentOption(optString)
        Print.printBuf(" end Absyn.PARTS;")
        ()
      end

      Absyn.DERIVED(typeSpec, attributes, arguments, comment)  => begin
        Print.printBuf("record Absyn.DERIVED typeSpec = ")
        printTypeSpecAsCorbaString(typeSpec)
        Print.printBuf(", attributes = ")
        printElementAttributesAsCorbaString(attributes)
        Print.printBuf(", arguments = ")
        printListAsCorbaString(arguments, printElementArgAsCorbaString, ",")
        Print.printBuf(", comment = ")
        printOption(comment, printCommentAsCorbaString)
        Print.printBuf("end Absyn.DERIVED;")
        ()
      end

      Absyn.ENUMERATION(enumLiterals, comment)  => begin
        Print.printBuf("record Absyn.ENUMERATION enumLiterals = ")
        printEnumDefAsCorbaString(enumLiterals)
        Print.printBuf(", comment = ")
        printOption(comment, printCommentAsCorbaString)
        Print.printBuf("end Absyn.ENUMERATION;")
        ()
      end

      Absyn.OVERLOAD(functionNames, comment)  => begin
        Print.printBuf("record Absyn.OVERLOAD functionNames = ")
        printListAsCorbaString(functionNames, printPathAsCorbaString, ",")
        Print.printBuf(", comment = ")
        printOption(comment, printCommentAsCorbaString)
        Print.printBuf("end Absyn.OVERLOAD;")
        ()
      end

      Absyn.CLASS_EXTENDS(baseClassName, modifications, optString, classParts, ann)  => begin
        Print.printBuf("record Absyn.CLASS_EXTENDS baseClassName = \"")
        Print.printBuf(baseClassName)
        Print.printBuf("\", modifications = ")
        printListAsCorbaString(modifications, printElementArgAsCorbaString, ",")
        Print.printBuf(", comment = ")
        printStringCommentOption(optString)
        Print.printBuf(", parts = ")
        printListAsCorbaString(classParts, printClassPartAsCorbaString, ",")
        Print.printBuf(", ann = ")
        printListAsCorbaString(ann, printAnnotationAsCorbaString, ",")
        Print.printBuf("end Absyn.CLASS_EXTENDS;")
        ()
      end

      Absyn.PDER(functionName, vars, comment)  => begin
        Print.printBuf("record Absyn.PDER functionName = ")
        printPathAsCorbaString(functionName)
        Print.printBuf(", vars = ")
        printListAsCorbaString(vars, printStringAsCorbaString, ",")
        Print.printBuf(", comment = ")
        printOption(comment, printCommentAsCorbaString)
        Print.printBuf("end Absyn.PDER;")
        ()
      end

      _  => begin
        Error.addMessage(Error.INTERNAL_ERROR, list("printClassDefAsCorbaString failed"))
        fail()
      end
    end
  end
end

function printEnumDefAsCorbaString(enumDef::Absyn.EnumDef)
  _ = begin
    local enumLiterals::Lst
    @match enumDef begin
      Absyn.ENUMLITERALS(enumLiterals)  => begin
        Print.printBuf("record Absyn.ENUMLITERALS enumLiterals = ")
        printListAsCorbaString(enumLiterals, printEnumLiteralAsCorbaString, ",")
        Print.printBuf("end Absyn.ENUMLITERALS;")
        ()
      end

      Absyn.ENUM_COLON()  => begin
        Print.printBuf("record Absyn.ENUM_COLON end Absyn.ENUM_COLON;")
        ()
      end

      _  => begin
        Error.addMessage(Error.INTERNAL_ERROR, list("printEnumDefAsCorbaString failed"))
        fail()
      end
    end
  end
end

function printEnumLiteralAsCorbaString(enumLit::Absyn.EnumLiteral)
  _ = begin
    local literal::String
    local comment::Option
    @match enumLit begin
      Absyn.ENUMLITERAL(literal, comment)  => begin
        Print.printBuf("record Absyn.ENUMLITERAL literal = \"")
        Print.printBuf(literal)
        Print.printBuf("\", comment = ")
        printOption(comment, printCommentAsCorbaString)
        Print.printBuf("end Absyn.ENUMLITERAL;")
        ()
      end

      _  => begin
        Error.addMessage(Error.INTERNAL_ERROR, list("printEnumLiteralAsCorbaString failed"))
        fail()
      end
    end
  end
end

function printRestrictionAsCorbaString(r::Absyn.Restriction)
  _ = begin
    local path::Absyn.Path
    local i::ModelicaInteger
    local functionRestriction::Absyn.FunctionRestriction
    @match r begin
      Absyn.R_CLASS()  => begin
        Print.printBuf("record Absyn.R_CLASS end Absyn.R_CLASS;")
        ()
      end

      Absyn.R_OPTIMIZATION()  => begin
        Print.printBuf("record Absyn.R_OPTIMIZATION end Absyn.R_OPTIMIZATION;")
        ()
      end

      Absyn.R_MODEL()  => begin
        Print.printBuf("record Absyn.R_MODEL end Absyn.R_MODEL;")
        ()
      end

      Absyn.R_RECORD()  => begin
        Print.printBuf("record Absyn.R_RECORD end Absyn.R_RECORD;")
        ()
      end

      Absyn.R_BLOCK()  => begin
        Print.printBuf("record Absyn.R_BLOCK end Absyn.R_BLOCK;")
        ()
      end

      Absyn.R_CONNECTOR()  => begin
        Print.printBuf("record Absyn.R_CONNECTOR end Absyn.R_CONNECTOR;")
        ()
      end

      Absyn.R_EXP_CONNECTOR()  => begin
        Print.printBuf("record Absyn.R_EXP_CONNECTOR end Absyn.R_EXP_CONNECTOR;")
        ()
      end

      Absyn.R_TYPE()  => begin
        Print.printBuf("record Absyn.R_TYPE end Absyn.R_TYPE;")
        ()
      end

      Absyn.R_PACKAGE()  => begin
        Print.printBuf("record Absyn.R_PACKAGE end Absyn.R_PACKAGE;")
        ()
      end

      Absyn.R_FUNCTION(functionRestriction = functionRestriction)  => begin
        Print.printBuf("record Absyn.R_FUNCTION functionRestriction = ")
        printFunctionRestrictionAsCorbaString(functionRestriction)
        Print.printBuf("end Absyn.R_FUNCTION;")
        ()
      end

      Absyn.R_OPERATOR()  => begin
        Print.printBuf("record Absyn.R_OPERATOR end Absyn.R_OPERATOR;")
        ()
      end

      Absyn.R_ENUMERATION()  => begin
        Print.printBuf("record Absyn.R_ENUMERATION end Absyn.R_ENUMERATION;")
        ()
      end

      Absyn.R_PREDEFINED_INTEGER()  => begin
        Print.printBuf("record Absyn.R_PREDEFINED_INTEGER end Absyn.R_PREDEFINED_INTEGER;")
        ()
      end

      Absyn.R_PREDEFINED_REAL()  => begin
        Print.printBuf("record Absyn.R_PREDEFINED_REAL end Absyn.R_PREDEFINED_REAL;")
        ()
      end

      Absyn.R_PREDEFINED_STRING()  => begin
        Print.printBuf("record Absyn.R_PREDEFINED_STRING end Absyn.R_PREDEFINED_STRING;")
        ()
      end

      Absyn.R_PREDEFINED_BOOLEAN()  => begin
        Print.printBuf("record Absyn.R_PREDEFINED_BOOLEAN end Absyn.R_PREDEFINED_BOOLEAN;")
        ()
      end

      Absyn.R_PREDEFINED_CLOCK()  => begin
        Print.printBuf("record Absyn.R_PREDEFINED_CLOCK end Absyn.R_PREDEFINED_CLOCK;")
        ()
      end

      Absyn.R_PREDEFINED_ENUMERATION()  => begin
        Print.printBuf("record Absyn.R_PREDEFINED_ENUMERATION end Absyn.R_PREDEFINED_ENUMERATION;")
        ()
      end

      Absyn.R_UNIONTYPE()  => begin
        Print.printBuf("record Absyn.R_UNIONTYPE end Absyn.R_UNIONTYPE;")
        ()
      end

      Absyn.R_METARECORD(name = path, index = i)  => begin
        Print.printBuf("record Absyn.R_METARECORD name = ")
        printPathAsCorbaString(path)
        Print.printBuf(", index = ")
        Print.printBuf(intString(i))
        Print.printBuf(" end Absyn.R_METARECORD;")
        ()
      end

      Absyn.R_UNKNOWN()  => begin
        Print.printBuf("record Absyn.R_UNKNOWN end Absyn.R_UNKNOWN;")
        ()
      end

      _  => begin
        Error.addMessage(Error.INTERNAL_ERROR, list("printRestrictionAsCorbaString failed"))
        fail()
      end
    end
  end
  #=  BTH
  =#
end

function printFunctionRestrictionAsCorbaString(functionRestriction::Absyn.FunctionRestriction)
  _ = begin
    local purity::Absyn.FunctionPurity
    @match functionRestriction begin
      Absyn.FR_NORMAL_FUNCTION(purity)  => begin
        Print.printBuf("record Absyn.FR_NORMAL_FUNCTION purity = ")
        printFunctionPurityAsCorbaString(purity)
        Print.printBuf(" end Absyn.FR_NORMAL_FUNCTION;")
        ()
      end

      Absyn.FR_OPERATOR_FUNCTION()  => begin
        Print.printBuf("record Absyn.FR_OPERATOR_FUNCTION end Absyn.FR_OPERATOR_FUNCTION;")
        ()
      end

      Absyn.FR_PARALLEL_FUNCTION()  => begin
        Print.printBuf("record Absyn.FR_PARALLEL_FUNCTION end Absyn.FR_PARALLEL_FUNCTION;")
        ()
      end

      Absyn.FR_KERNEL_FUNCTION()  => begin
        Print.printBuf("record Absyn.FR_KERNEL_FUNCTION end Absyn.FR_KERNEL_FUNCTION;")
        ()
      end
    end
  end
end

function printFunctionPurityAsCorbaString(functionPurity::Absyn.FunctionPurity)
  _ = begin
    @match functionPurity begin
      Absyn.PURE()  => begin
        Print.printBuf("record Absyn.PURE end Absyn.PURE;")
        ()
      end

      Absyn.IMPURE()  => begin
        Print.printBuf("record Absyn.IMPURE end Absyn.IMPURE;")
        ()
      end

      Absyn.NO_PURITY()  => begin
        Print.printBuf("record Absyn.NO_PURITY end Absyn.NO_PURITY;")
        ()
      end
    end
  end
end

function printClassPartAsCorbaString(classPart::Absyn.ClassPart)
  _ = begin
    local contents::Lst
    local eqContents::Lst
    local algContents::Lst
    local externalDecl::Absyn.ExternalDecl
    local annotation_::Option
    @match classPart begin
      Absyn.PUBLIC(contents)  => begin
        Print.printBuf("\nrecord Absyn.PUBLIC contents = ")
        printListAsCorbaString(contents, printElementItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.PUBLIC;")
        ()
      end

      Absyn.PROTECTED(contents)  => begin
        Print.printBuf("\nrecord Absyn.PROTECTED contents = ")
        printListAsCorbaString(contents, printElementItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.PROTECTED;")
        ()
      end

      Absyn.EQUATIONS(eqContents)  => begin
        Print.printBuf("\nrecord Absyn.EQUATIONS contents = ")
        printListAsCorbaString(eqContents, printEquationItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.EQUATIONS;")
        ()
      end

      Absyn.INITIALEQUATIONS(eqContents)  => begin
        Print.printBuf("\nrecord Absyn.INITIALEQUATIONS contents = ")
        printListAsCorbaString(eqContents, printEquationItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.INITIALEQUATIONS;")
        ()
      end

      Absyn.ALGORITHMS(algContents)  => begin
        Print.printBuf("\nrecord Absyn.ALGORITHMS contents = ")
        printListAsCorbaString(algContents, printAlgorithmItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.ALGORITHMS;")
        ()
      end

      Absyn.INITIALALGORITHMS(algContents)  => begin
        Print.printBuf("\nrecord Absyn.INITIALALGORITHMS contents = ")
        printListAsCorbaString(algContents, printAlgorithmItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.INITIALALGORITHMS;")
        ()
      end

      Absyn.EXTERNAL(externalDecl, annotation_)  => begin
        Print.printBuf("\nrecord Absyn.EXTERNAL externalDecl = ")
        printExternalDeclAsCorbaString(externalDecl)
        Print.printBuf(", annotation_ = ")
        printOption(annotation_, printAnnotationAsCorbaString)
        Print.printBuf(" end Absyn.EXTERNAL;")
        ()
      end

      _  => begin
        Error.addMessage(Error.INTERNAL_ERROR, list("printClassPartAsCorbaString failed"))
        fail()
      end
    end
  end
end

function printExternalDeclAsCorbaString(decl::Absyn.ExternalDecl)
  _ = begin
    local funcName::Option
    local lang::Option
    local output_::Option
    local args::Lst
    local annotation_::Option
    @match decl begin
      Absyn.EXTERNALDECL(funcName, lang, output_, args, annotation_)  => begin
        Print.printBuf("record Absyn.EXTERNALDECL funcName = ")
        printStringCommentOption(funcName)
        Print.printBuf(", lang = ")
        printStringCommentOption(lang)
        Print.printBuf(", output_ = ")
        printOption(output_, printComponentRefAsCorbaString)
        Print.printBuf(", args = ")
        printListAsCorbaString(args, printExpAsCorbaString, ",")
        Print.printBuf(", annotation_ = ")
        printOption(annotation_, printAnnotationAsCorbaString)
        Print.printBuf(" end Absyn.EXTERNALDECL;")
        ()
      end

      _  => begin
        Error.addMessage(Error.INTERNAL_ERROR, list("printExternalDeclAsCorbaString failed"))
        fail()
      end
    end
  end
end

function printElementItemAsCorbaString(el::Absyn.ElementItem)
  _ = begin
    local element::Absyn.Element
    local annotation_::Absyn.Annotation
    local cmt::String
    @match el begin
      Absyn.ELEMENTITEM(element)  => begin
        Print.printBuf("record Absyn.ELEMENTITEM element = ")
        printElementAsCorbaString(element)
        Print.printBuf(" end Absyn.ELEMENTITEM;")
        ()
      end

      Absyn.LEXER_COMMENT(cmt)  => begin
        Print.printBuf("record Absyn.ELEMENTITEM element = \"")
        Print.printBuf(cmt)
        Print.printBuf("\" end Absyn.ELEMENTITEM;")
        ()
      end

      _  => begin
        Error.addMessage(Error.INTERNAL_ERROR, list("printElementItemAsCorbaString failed"))
        fail()
      end
    end
  end
end

function printElementAsCorbaString(el::Absyn.Element)
  _ = begin
    local finalPrefix::Bool
    local redeclareKeywords::Option
    local innerOuter::Absyn.InnerOuter
    local name::String
    local string::String
    local specification::Absyn.ElementSpec
    local info::SourceInfo
    local constrainClass::Option
    local args::Lst
    local optName::Option
    @match el begin
      Absyn.ELEMENT(finalPrefix, redeclareKeywords, innerOuter, specification, info, constrainClass)  => begin
        Print.printBuf("\nrecord Absyn.ELEMENT finalPrefix = ")
        Print.printBuf(boolString(finalPrefix))
        Print.printBuf(",redeclareKeywords = ")
        printOption(redeclareKeywords, printRedeclareKeywordsAsCorbaString)
        Print.printBuf(",innerOuter = ")
        printInnerOuterAsCorbaString(innerOuter)
        Print.printBuf(",specification = ")
        printElementSpecAsCorbaString(specification)
        Print.printBuf(",info = ")
        printInfoAsCorbaString(info)
        Print.printBuf(",constrainClass = ")
        printOption(constrainClass, printConstrainClassAsCorbaString)
        Print.printBuf(" end Absyn.ELEMENT;")
        ()
      end

      Absyn.DEFINEUNIT(name, args)  => begin
        Print.printBuf("\nrecord Absyn.DEFINEUNIT name = \"")
        Print.printBuf(name)
        Print.printBuf("\", args = ")
        printListAsCorbaString(args, printNamedArg, ",")
        Print.printBuf(" end Absyn.DEFINEUNIT;")
        ()
      end

      Absyn.TEXT(optName, string, info)  => begin
        Print.printBuf("\nrecord Absyn.TEXT optName = ")
        printStringCommentOption(optName)
        Print.printBuf(", string = \"")
        Print.printBuf(string)
        Print.printBuf("\", info = ")
        printInfoAsCorbaString(info)
        Print.printBuf(" end Absyn.TEXT;")
        ()
      end

      _  => begin
        Error.addMessage(Error.INTERNAL_ERROR, list("printElementAsCorbaString failed"))
        fail()
      end
    end
  end
end

function printInnerOuterAsCorbaString(innerOuter::Absyn.InnerOuter)
  _ = begin
    @match innerOuter begin
      Absyn.INNER()  => begin
        Print.printBuf("record Absyn.INNER end Absyn.INNER;")
        ()
      end

      Absyn.OUTER()  => begin
        Print.printBuf("record Absyn.OUTER end Absyn.OUTER;")
        ()
      end

      Absyn.INNER_OUTER()  => begin
        Print.printBuf("record Absyn.INNER_OUTER end Absyn.INNER_OUTER;")
        ()
      end

      Absyn.NOT_INNER_OUTER()  => begin
        Print.printBuf("record Absyn.NOT_INNER_OUTER end Absyn.NOT_INNER_OUTER;")
        ()
      end
    end
  end
end

function printRedeclareKeywordsAsCorbaString(redeclareKeywords::Absyn.RedeclareKeywords)
  _ = begin
    @match redeclareKeywords begin
      Absyn.REDECLARE()  => begin
        Print.printBuf("record Absyn.REDECLARE end Absyn.REDECLARE;")
        ()
      end

      Absyn.REPLACEABLE()  => begin
        Print.printBuf("record Absyn.REPLACEABLE end Absyn.REPLACEABLE;")
        ()
      end

      Absyn.REDECLARE_REPLACEABLE()  => begin
        Print.printBuf("record Absyn.REDECLARE_REPLACEABLE end Absyn.REDECLARE_REPLACEABLE;")
        ()
      end
    end
  end
end

function printConstrainClassAsCorbaString(constrainClass::Absyn.ConstrainClass)
  _ = begin
    local elementSpec::Absyn.ElementSpec
    local comment::Option
    @match constrainClass begin
      Absyn.CONSTRAINCLASS(elementSpec, comment)  => begin
        Print.printBuf("record Absyn.CONSTRAINCLASS elementSpec = ")
        printElementSpecAsCorbaString(elementSpec)
        Print.printBuf(", comment = ")
        printOption(comment, printCommentAsCorbaString)
        Print.printBuf(" end Absyn.CONSTRAINCLASS;")
        ()
      end
    end
  end
end

function printElementSpecAsCorbaString(spec::Absyn.ElementSpec)
  _ = begin
    local replaceable_::Bool
    local class_::Absyn.Class
    local import_::Absyn.Import
  local comment::Option
    local attributes::Absyn.ElementAttributes
    local typeSpec::Absyn.TypeSpec
    local components::Lst
    local annotationOpt::Option
    local elementArg::Lst
    local path::Absyn.Path
    local info::SourceInfo
    @match spec begin
      Absyn.CLASSDEF(replaceable_, class_)  => begin
        Print.printBuf("record Absyn.CLASSDEF replaceable_ = ")
        Print.printBuf(boolString(replaceable_))
        Print.printBuf(", class_ = ")
        printClassAsCorbaString(class_)
        Print.printBuf(" end Absyn.CLASSDEF;")
        ()
      end

      Absyn.EXTENDS(path, elementArg, annotationOpt)  => begin
        Print.printBuf("record Absyn.EXTENDS path = ")
        printPathAsCorbaString(path)
        Print.printBuf(", elementArg = ")
        printListAsCorbaString(elementArg, printElementArgAsCorbaString, ",")
        Print.printBuf(", annotationOpt = ")
        printOption(annotationOpt, printAnnotationAsCorbaString)
        Print.printBuf(" end Absyn.EXTENDS;")
        ()
      end

      Absyn.IMPORT(import_, comment, info)  => begin
        Print.printBuf("record Absyn.IMPORT import_ = ")
        printImportAsCorbaString(import_)
        Print.printBuf(", comment = ")
        printOption(comment, printCommentAsCorbaString)
        Print.printBuf(", info = ")
        printInfoAsCorbaString(info)
        Print.printBuf(" end Absyn.IMPORT;")
        ()
      end

      Absyn.COMPONENTS(attributes, typeSpec, components)  => begin
        Print.printBuf("record Absyn.COMPONENTS attributes = ")
        printElementAttributesAsCorbaString(attributes)
        Print.printBuf(", typeSpec = ")
        printTypeSpecAsCorbaString(typeSpec)
        Print.printBuf(", components = ")
        printListAsCorbaString(components, printComponentItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.COMPONENTS;")
        ()
      end
    end
  end
end

function printComponentItemAsCorbaString(componentItem::Absyn.ComponentItem)
  _ = begin
    local component::Absyn.Component
    local condition::Option
    local comment::Option
    @match componentItem begin
      Absyn.COMPONENTITEM(component, condition, comment)  => begin
        Print.printBuf("record Absyn.COMPONENTITEM component = ")
        printComponentAsCorbaString(component)
        Print.printBuf(", condition = ")
        printOption(condition, printExpAsCorbaString)
        Print.printBuf(", comment = ")
        printOption(comment, printCommentAsCorbaString)
        Print.printBuf(" end Absyn.COMPONENTITEM;")
        ()
      end
    end
  end
end

function printComponentAsCorbaString(component::Absyn.Component)
  _ = begin
    local name::String
    local arrayDim::Absyn.ArrayDim
    local modification::Option
    @match component begin
      Absyn.COMPONENT(name, arrayDim, modification)  => begin
        Print.printBuf("record Absyn.COMPONENT name = \"")
        Print.printBuf(name)
        Print.printBuf("\", arrayDim = ")
        printArrayDimAsCorbaString(arrayDim)
        Print.printBuf(", modification = ")
        printOption(modification, printModificationAsCorbaString)
        Print.printBuf(" end Absyn.COMPONENT;")
        ()
      end
    end
  end
end

function printModificationAsCorbaString(mod::Absyn.Modification)
  _ = begin
    local elementArgLst::Lst
    local eqMod::Absyn.EqMod
    @match mod begin
      Absyn.CLASSMOD(elementArgLst, eqMod)  => begin
        Print.printBuf("record Absyn.CLASSMOD elementArgLst = ")
        printListAsCorbaString(elementArgLst, printElementArgAsCorbaString, ",")
        Print.printBuf(", eqMod = ")
        printEqModAsCorbaString(eqMod)
        Print.printBuf(" end Absyn.CLASSMOD;")
        ()
      end
    end
  end
end

function printEqModAsCorbaString(eqMod::Absyn.EqMod)
  _ = begin
    local exp::Absyn.Exp
    local info::SourceInfo
    @match eqMod begin
      Absyn.NOMOD()  => begin
        Print.printBuf("record Absyn.NOMOD end Absyn.NOMOD;")
        ()
      end

      Absyn.EQMOD(exp, info)  => begin
        Print.printBuf("record Absyn.EQMOD exp = ")
        printExpAsCorbaString(exp)
        Print.printBuf(", info = ")
        printInfoAsCorbaString(info)
        Print.printBuf(" end Absyn.EQMOD;")
        ()
      end
    end
  end
end

function printEquationItemAsCorbaString(el::Absyn.EquationItem)
  _ = begin
    local equation_::Absyn.Equation
    local comment::Option
    local annotation_::Absyn.Annotation
    local info::SourceInfo
    @match el begin
      Absyn.EQUATIONITEM(equation_, comment, info)  => begin
        Print.printBuf("\nrecord Absyn.EQUATIONITEM equation_ = ")
        printEquationAsCorbaString(equation_)
        Print.printBuf(", comment = ")
        printOption(comment, printCommentAsCorbaString)
        Print.printBuf(", info = ")
        printInfoAsCorbaString(info)
        Print.printBuf(" end Absyn.EQUATIONITEM;")
        ()
      end
    end
  end
end

function printEquationAsCorbaString(eq::Absyn.Equation)
  _ = begin
    local ifExp::Absyn.Exp
    local leftSide::Absyn.Exp
    local rightSide::Absyn.Exp
    local whenExp::Absyn.Exp
    local elseIfBranches::Lst
    local elseWhenEquations::Lst
    local connector1::Absyn.ComponentRef
    local connector2::Absyn.ComponentRef
    local functionName::Absyn.ComponentRef
    local cr::Absyn.ComponentRef
    local iterators::Absyn.ForIterators
    local equationTrueItems::Lst
    local equationElseItems::Lst
    local forEquations::Lst
    local whenEquations::Lst
    local functionArgs::Absyn.FunctionArgs
    local equ::Absyn.EquationItem
    @match eq begin
      Absyn.EQ_IF(ifExp, equationTrueItems, elseIfBranches, equationElseItems)  => begin
        Print.printBuf("record Absyn.EQ_IF ifExp = ")
        printExpAsCorbaString(ifExp)
        Print.printBuf(", equationTrueItems = ")
        printListAsCorbaString(equationTrueItems, printEquationItemAsCorbaString, ",")
        Print.printBuf(", elseIfBranches = ")
        printListAsCorbaString(elseIfBranches, printEquationBranchAsCorbaString, ",")
        Print.printBuf(", equationElseItems = ")
        printListAsCorbaString(equationElseItems, printEquationItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.EQ_IF;")
        ()
      end

      Absyn.EQ_EQUALS(leftSide, rightSide)  => begin
        Print.printBuf("record Absyn.EQ_EQUALS leftSide = ")
        printExpAsCorbaString(leftSide)
        Print.printBuf(", rightSide = ")
        printExpAsCorbaString(rightSide)
        Print.printBuf(" end Absyn.EQ_EQUALS;")
        ()
      end

      Absyn.EQ_PDE(leftSide, rightSide, cr)  => begin
        Print.printBuf("record Absyn.EQ_PDE leftSide = ")
        printExpAsCorbaString(leftSide)
        Print.printBuf(", rightSide = ")
        printExpAsCorbaString(rightSide)
        Print.printBuf(", domain = ")
        printComponentRefAsCorbaString(cr)
        Print.printBuf(" end Absyn.EQ_PDE;")
        ()
      end

      Absyn.EQ_CONNECT(connector1, connector2)  => begin
        Print.printBuf("record Absyn.EQ_CONNECT connector1 = ")
        printComponentRefAsCorbaString(connector1)
        Print.printBuf(", connector2 = ")
        printComponentRefAsCorbaString(connector2)
        Print.printBuf(" end Absyn.EQ_CONNECT;")
        ()
      end

      Absyn.EQ_FOR(iterators, forEquations)  => begin
        Print.printBuf("record Absyn.EQ_FOR iterators = ")
        printListAsCorbaString(iterators, printForIteratorAsCorbaString, ",")
        Print.printBuf(", forEquations = ")
        printListAsCorbaString(forEquations, printEquationItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.EQ_FOR;")
        ()
      end

      Absyn.EQ_WHEN_E(whenExp, whenEquations, elseWhenEquations)  => begin
        Print.printBuf("record Absyn.EQ_WHEN_E whenExp = ")
        printExpAsCorbaString(whenExp)
        Print.printBuf(", whenEquations = ")
        printListAsCorbaString(whenEquations, printEquationItemAsCorbaString, ",")
        Print.printBuf(", elseWhenEquations = ")
        printListAsCorbaString(elseWhenEquations, printEquationBranchAsCorbaString, ",")
        Print.printBuf(" end Absyn.EQ_WHEN_E;")
        ()
      end

      Absyn.EQ_NORETCALL(functionName, functionArgs)  => begin
        Print.printBuf("record Absyn.EQ_NORETCALL functionName = ")
        printComponentRefAsCorbaString(functionName)
        Print.printBuf(", functionArgs = ")
        printFunctionArgsAsCorbaString(functionArgs)
        Print.printBuf(" end Absyn.EQ_NORETCALL;")
        ()
      end

      Absyn.EQ_FAILURE(equ)  => begin
        Print.printBuf("record Absyn.EQ_FAILURE equ = ")
        printEquationItemAsCorbaString(equ)
        Print.printBuf(" end Absyn.EQ_FAILURE;")
        ()
      end
    end
  end
end

function printAlgorithmItemAsCorbaString(el::Absyn.AlgorithmItem)
  _ = begin
    local algorithm_::Absyn.Algorithm
    local comment::Option
    local annotation_::Absyn.Annotation
    local info::SourceInfo
    @match el begin
      Absyn.ALGORITHMITEM(algorithm_, comment, info)  => begin
        Print.printBuf("\nrecord Absyn.ALGORITHMITEM algorithm_ = ")
        printAlgorithmAsCorbaString(algorithm_)
        Print.printBuf(", comment = ")
        printOption(comment, printCommentAsCorbaString)
        Print.printBuf(", info = ")
        printInfo(info)
        Print.printBuf(" end Absyn.ALGORITHMITEM;")
        ()
      end
    end
  end
end

function printAlgorithmAsCorbaString(alg::Absyn.Algorithm)
  _ = begin
    local assignComponent::Absyn.Exp
    local value::Absyn.Exp
    local ifExp::Absyn.Exp
    local boolExpr::Absyn.Exp
    local elseIfAlgorithmBranch::Lst
    local elseWhenAlgorithmBranch::Lst
    local trueBranch::Lst
    local elseBranch::Lst
    local forBody::Lst
    local whileBody::Lst
    local whenBody::Lst
    local tryBody::Lst
    local catchBody::Lst
    local body::Lst
    local iterators::Absyn.ForIterators
    local functionCall::Absyn.ComponentRef
    local functionArgs::Absyn.FunctionArgs
    @match alg begin
      Absyn.ALG_ASSIGN(assignComponent, value)  => begin
        Print.printBuf("record Absyn.ALG_ASSIGN assignComponent = ")
        printExpAsCorbaString(assignComponent)
        Print.printBuf(", value = ")
        printExpAsCorbaString(value)
        Print.printBuf(" end Absyn.ALG_ASSIGN;")
        ()
      end

      Absyn.ALG_IF(ifExp, trueBranch, elseIfAlgorithmBranch, elseBranch)  => begin
        Print.printBuf("record Absyn.ALG_IF ifExp = ")
        printExpAsCorbaString(ifExp)
        Print.printBuf(", trueBranch = ")
        printListAsCorbaString(trueBranch, printAlgorithmItemAsCorbaString, ",")
        Print.printBuf(", elseIfAlgorithmBranch = ")
        printListAsCorbaString(elseIfAlgorithmBranch, printAlgorithmBranchAsCorbaString, ",")
        Print.printBuf(", elseBranch = ")
        printListAsCorbaString(elseBranch, printAlgorithmItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.ALG_IF;")
        ()
      end

      Absyn.ALG_FOR(iterators, forBody)  => begin
        Print.printBuf("record Absyn.ALG_FOR iterators = ")
        printListAsCorbaString(iterators, printForIteratorAsCorbaString, ",")
        Print.printBuf(", forBody = ")
        printListAsCorbaString(forBody, printAlgorithmItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.ALG_FOR;")
        ()
      end

      Absyn.ALG_PARFOR(iterators, forBody)  => begin
        Print.printBuf("record Absyn.ALG_PARFOR iterators = ")
        printListAsCorbaString(iterators, printForIteratorAsCorbaString, ",")
        Print.printBuf(", parforBody = ")
        printListAsCorbaString(forBody, printAlgorithmItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.ALG_PARFOR;")
        ()
      end

      Absyn.ALG_WHILE(boolExpr, whileBody)  => begin
        Print.printBuf("record Absyn.ALG_WHILE boolExpr = ")
        printExpAsCorbaString(boolExpr)
        Print.printBuf(", whileBody = ")
        printListAsCorbaString(whileBody, printAlgorithmItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.ALG_WHILE;")
        ()
      end

      Absyn.ALG_WHEN_A(boolExpr, whenBody, elseWhenAlgorithmBranch)  => begin
        Print.printBuf("record Absyn.ALG_WHEN_A boolExpr = ")
        printExpAsCorbaString(boolExpr)
        Print.printBuf(", whenBody = ")
        printListAsCorbaString(whenBody, printAlgorithmItemAsCorbaString, ",")
        Print.printBuf(", elseWhenAlgorithmBranch = ")
        printListAsCorbaString(elseWhenAlgorithmBranch, printAlgorithmBranchAsCorbaString, ",")
        Print.printBuf(" end Absyn.ALG_WHEN_A;")
        ()
      end

      Absyn.ALG_NORETCALL(functionCall, functionArgs)  => begin
        Print.printBuf("record Absyn.ALG_NORETCALL functionCall = ")
        printComponentRefAsCorbaString(functionCall)
        Print.printBuf(", functionArgs = ")
        printFunctionArgsAsCorbaString(functionArgs)
        Print.printBuf(" end Absyn.ALG_NORETCALL;")
        ()
      end

      Absyn.ALG_RETURN()  => begin
        Print.printBuf("record Absyn.ALG_RETURN end Absyn.ALG_RETURN;")
        ()
      end

      Absyn.ALG_BREAK()  => begin
        Print.printBuf("record Absyn.ALG_BREAK end Absyn.ALG_BREAK;")
        ()
      end

      Absyn.ALG_FAILURE(body)  => begin
        Print.printBuf("record Absyn.ALG_FAILURE body = ")
        printListAsCorbaString(body, printAlgorithmItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.ALG_FAILURE;")
        ()
      end
    end
  end
end

function printAlgorithmBranchAsCorbaString(inBranch::Tuple)
  printTupleAsCorbaString(inBranch, printExpAsCorbaString, printAlgorithmItemListAsCorbaString)
end

function printAlgorithmItemListAsCorbaString(inLst::Lst)
  printListAsCorbaString(inLst, printAlgorithmItemAsCorbaString, ",")
end

function printEquationBranchAsCorbaString(inBranch::Tuple)
  printTupleAsCorbaString(inBranch, printExpAsCorbaString, printEquationItemListAsCorbaString)
end

function printEquationItemListAsCorbaString(inLst::Lst)
  printListAsCorbaString(inLst, printEquationItemAsCorbaString, ",")
end

function printAnnotationAsCorbaString(annotation_::Absyn.Annotation)
  _ = begin
    local elementArgs::Lst
    @match annotation_ begin
      Absyn.ANNOTATION(elementArgs)  => begin
        Print.printBuf("record Absyn.ANNOTATION elementArgs = ")
        printListAsCorbaString(elementArgs, printElementArgAsCorbaString, ",")
        Print.printBuf(" end Absyn.ANNOTATION;")
        ()
      end
    end
  end
end

function printCommentAsCorbaString(inComment::Absyn.Comment)
  _ = begin
    local annotation_::Option
    local comment::Option
    @match inComment begin
      Absyn.COMMENT(annotation_, comment)  => begin
        Print.printBuf("record Absyn.COMMENT annotation_ = ")
        printOption(annotation_, printAnnotationAsCorbaString)
        Print.printBuf(", comment = ")
        printStringCommentOption(comment)
        Print.printBuf(" end Absyn.COMMENT;")
        ()
      end
    end
  end
end

function printTypeSpecAsCorbaString(typeSpec::Absyn.TypeSpec)
  _ = begin
    local path::Absyn.Path
    local arrayDim::Option
    local typeSpecs::Lst
    @match typeSpec begin
      Absyn.TPATH(path, arrayDim)  => begin
        Print.printBuf("record Absyn.TPATH path = ")
        printPathAsCorbaString(path)
        Print.printBuf(", arrayDim = ")
        printOption(arrayDim, printArrayDimAsCorbaString)
        Print.printBuf(" end Absyn.TPATH;")
        ()
      end

      Absyn.TCOMPLEX(path, typeSpecs, arrayDim)  => begin
        Print.printBuf("record Absyn.TPATH path = ")
        printPathAsCorbaString(path)
        Print.printBuf(", typeSpecs = ")
        printListAsCorbaString(typeSpecs, printTypeSpecAsCorbaString, ",")
        Print.printBuf(", arrayDim = ")
        printOption(arrayDim, printArrayDimAsCorbaString)
        Print.printBuf(" end Absyn.TPATH;")
        ()
      end
    end
  end
end

function printArrayDimAsCorbaString(arrayDim::Absyn.ArrayDim)
  printListAsCorbaString(arrayDim, printSubscriptAsCorbaString, ",")
end

function printSubscriptAsCorbaString(subscript::Absyn.Subscript)
  _ = begin
    local sub::Absyn.Exp
    @match subscript begin
      Absyn.NOSUB()  => begin
        Print.printBuf("record Absyn.NOSUB end Absyn.NOSUB;")
        ()
      end

      Absyn.SUBSCRIPT(sub)  => begin
        Print.printBuf("record Absyn.SUBSCRIPT subscript = ")
        printExpAsCorbaString(sub)
        Print.printBuf(" end Absyn.SUBSCRIPT;")
        ()
      end
    end
  end
end

function printImportAsCorbaString(import_::Absyn.Import)
  _ = begin
    local name::String
    local path::Absyn.Path
    @match import_ begin
      Absyn.NAMED_IMPORT(name, path)  => begin
        Print.printBuf("record Absyn.NAMED_IMPORT name = \"")
        Print.printBuf(name)
        Print.printBuf("\", path = ")
        printPathAsCorbaString(path)
        Print.printBuf(" end Absyn.NAMED_IMPORT;")
        ()
      end

      Absyn.QUAL_IMPORT(path)  => begin
        Print.printBuf("record Absyn.QUAL_IMPORT path = ")
        printPathAsCorbaString(path)
        Print.printBuf(" end Absyn.QUAL_IMPORT;")
        ()
      end

      Absyn.UNQUAL_IMPORT(path)  => begin
        Print.printBuf("record Absyn.UNQUAL_IMPORT path = ")
        printPathAsCorbaString(path)
        Print.printBuf(" end Absyn.UNQUAL_IMPORT;")
        ()
      end
    end
  end
end

function printElementAttributesAsCorbaString(attr::Absyn.ElementAttributes)
  _ = begin
    local flowPrefix::Bool
    local streamPrefix::Bool
    local parallelism::Absyn.Parallelism
    local variability::Absyn.Variability
    local direction::Absyn.Direction
    local arrayDim::Absyn.ArrayDim
    local isField::Absyn.IsField
    @match attr begin
      Absyn.ATTR(flowPrefix, streamPrefix, parallelism, variability, direction, isField, arrayDim)  => begin
        Print.printBuf("record Absyn.ATTR flowPrefix = ")
        Print.printBuf(boolString(flowPrefix))
        Print.printBuf(", streamPrefix = ")
        Print.printBuf(boolString(streamPrefix))
        Print.printBuf(", parallelism = ")
        printParallelismAsCorbaString(parallelism)
        Print.printBuf(", variability = ")
        printVariabilityAsCorbaString(variability)
        Print.printBuf(", direction = ")
        printDirectionAsCorbaString(direction)
        if intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PDEMODELICA)
          Print.printBuf(", isField = ")
          printIsFieldAsCorbaString(isField)
        end
        Print.printBuf(", arrayDim = ")
        printArrayDimAsCorbaString(arrayDim)
        Print.printBuf(" end Absyn.ATTR;")
        ()
      end
    end
  end
end

function printParallelismAsCorbaString(parallelism::Absyn.Parallelism)
  _ = begin
    @match parallelism begin
      Absyn.PARGLOBAL()  => begin
        Print.printBuf("record Absyn.PARGLOBAL end Absyn.PARGLOBAL;")
        ()
      end

      Absyn.PARLOCAL()  => begin
        Print.printBuf("record Absyn.PARLOCAL end Absyn.PARLOCAL;")
        ()
      end

      Absyn.NON_PARALLEL()  => begin
        Print.printBuf("record Absyn.NON_PARALLEL end Absyn.NON_PARALLEL;")
        ()
      end
    end
  end
end

function printVariabilityAsCorbaString(var::Absyn.Variability)
  _ = begin
    @match var begin
      Absyn.VAR()  => begin
        Print.printBuf("record Absyn.VAR end Absyn.VAR;")
        ()
      end

      Absyn.DISCRETE()  => begin
        Print.printBuf("record Absyn.DISCRETE end Absyn.DISCRETE;")
        ()
      end

      Absyn.PARAM()  => begin
        Print.printBuf("record Absyn.PARAM end Absyn.PARAM;")
        ()
      end

      Absyn.CONST()  => begin
        Print.printBuf("record Absyn.CONST end Absyn.CONST;")
        ()
      end
    end
  end
end

function printDirectionAsCorbaString(dir::Absyn.Direction)
  _ = begin
    @match dir begin
      Absyn.INPUT()  => begin
        Print.printBuf("record Absyn.INPUT end Absyn.INPUT;")
        ()
      end

      Absyn.OUTPUT()  => begin
        Print.printBuf("record Absyn.OUTPUT end Absyn.OUTPUT;")
        ()
      end

      Absyn.BIDIR()  => begin
        Print.printBuf("record Absyn.BIDIR end Absyn.BIDIR;")
        ()
      end
    end
  end
end

function printIsFieldAsCorbaString(isf::Absyn.IsField)
  _ = begin
    @match isf begin
      Absyn.NONFIELD()  => begin
        Print.printBuf("record Absyn.NONFIELD end Absyn.NONFIELD;")
        ()
      end

      Absyn.FIELD()  => begin
        Print.printBuf("record Absyn.FIELD end Absyn.FIELD;")
        ()
      end
    end
  end
end

function printElementArgAsCorbaString(arg::Absyn.ElementArg)
  _ = begin
    local finalPrefix::Bool
    local eachPrefix::Absyn.Each
    local modification::Option
    local comment::Option
    local redeclareKeywords::Absyn.RedeclareKeywords
    local elementSpec::Absyn.ElementSpec
    local constrainClass::Option
    local info::SourceInfo
    local p::Absyn.Path
    @match arg begin
      Absyn.MODIFICATION(finalPrefix, eachPrefix, p, modification, comment, info)  => begin
        Print.printBuf("record Absyn.MODIFICATION finalPrefix = ")
        Print.printBuf(boolString(finalPrefix))
        Print.printBuf(", eachPrefix = ")
        printEachAsCorbaString(eachPrefix)
        Print.printBuf(", path = ")
        printPathAsCorbaString(p)
        Print.printBuf(", modification = ")
        printOption(modification, printModificationAsCorbaString)
        Print.printBuf(", comment = ")
        printStringCommentOption(comment)
        Print.printBuf(", info = ")
        printInfoAsCorbaString(info)
        Print.printBuf(" end Absyn.MODIFICATION;")
        ()
      end

      Absyn.REDECLARATION(finalPrefix, redeclareKeywords, eachPrefix, elementSpec, constrainClass, info)  => begin
        Print.printBuf("record Absyn.REDECLARATION finalPrefix = ")
        Print.printBuf(boolString(finalPrefix))
        Print.printBuf(", redeclareKeywords = ")
        printRedeclareKeywordsAsCorbaString(redeclareKeywords)
        Print.printBuf(", eachPrefix = ")
        printEachAsCorbaString(eachPrefix)
        Print.printBuf(", elementSpec = ")
        printElementSpecAsCorbaString(elementSpec)
        Print.printBuf(", constrainClass = ")
        printOption(constrainClass, printConstrainClassAsCorbaString)
        Print.printBuf(", info = ")
        printInfoAsCorbaString(info)
        Print.printBuf(" end Absyn.REDECLARATION;")
        ()
      end
    end
  end
end

function printFunctionArgsAsCorbaString(fargs::Absyn.FunctionArgs)
  _ = begin
    local args::Lst
    local argNames::Lst
    local exp::Absyn.Exp
    local iterators::Absyn.ForIterators
    @match fargs begin
      Absyn.FUNCTIONARGS(args, argNames)  => begin
        Print.printBuf("record Absyn.FUNCTIONARGS args = ")
        printListAsCorbaString(args, printExpAsCorbaString, ",")
        Print.printBuf(", argNames = ")
        printListAsCorbaString(argNames, printNamedArgAsCorbaString, ",")
        Print.printBuf(" end Absyn.FUNCTIONARGS;")
        ()
      end

      Absyn.FOR_ITER_FARG(exp, _, iterators)  => begin
        Print.printBuf("record Absyn.FOR_ITER_FARG exp = ")
        printExpAsCorbaString(exp)
        Print.printBuf(", iterators = ")
        printListAsCorbaString(iterators, printForIteratorAsCorbaString, ",")
        Print.printBuf(" end Absyn.FOR_ITER_FARG;")
        ()
      end
    end
  end
end

function printForIteratorAsCorbaString(iter::Absyn.ForIterator)
  _ = begin
    local id::String
    local guardExp::Option
    local range::Option
    @match iter begin
      Absyn.ITERATOR(id, guardExp, range)  => begin
        Print.printBuf("record Absyn.ITERATOR name = \"")
        Print.printBuf(id)
        Print.printBuf("\", guardExp = ")
        printOption(guardExp, printExpAsCorbaString)
        Print.printBuf(", range = ")
        printOption(range, printExpAsCorbaString)
        Print.printBuf("end Absyn.ITERATOR;")
        ()
      end
    end
  end
end

function printNamedArgAsCorbaString(arg::Absyn.NamedArg)
  _ = begin
    local argName::String
    local argValue::Absyn.Exp
    @match arg begin
      Absyn.NAMEDARG(argName, argValue)  => begin
        Print.printBuf("record Absyn.NAMEDARG argName = \"")
        Print.printBuf(argName)
        Print.printBuf("\", argValue = ")
        printExpAsCorbaString(argValue)
        Print.printBuf(" end Absyn.NAMEDARG;")
        ()
      end
    end
  end
end

function printExpAsCorbaString(inExp::Absyn.Exp)
  _ = begin
    local i::ModelicaInteger
    local r::ModelicaReal
    local s::String
    local id::String
    local b::Bool
    local componentRef::Absyn.ComponentRef
    local function_::Absyn.ComponentRef
    local functionArgs::Absyn.FunctionArgs
    local exp::Absyn.Exp
    local exp1::Absyn.Exp
    local exp2::Absyn.Exp
    local ifExp::Absyn.Exp
    local trueBranch::Absyn.Exp
    local elseBranch::Absyn.Exp
    local start::Absyn.Exp
    local stop::Absyn.Exp
    local head::Absyn.Exp
    local rest::Absyn.Exp
    local inputExp::Absyn.Exp
    local step::Option
    local op::Absyn.Operator
    local arrayExp::Lst
    local expressions::Lst
    local matrix::Lst
    local elseIfBranch::Lst
    local code::Absyn.CodeNode
    local matchTy::Absyn.MatchType
    local localDecls::Lst
    local cases::Lst
    local comment::Option
    @match inExp begin
      Absyn.INTEGER(value = i)  => begin
        Print.printBuf("record Absyn.INTEGER value = ")
        Print.printBuf(intString(i))
        Print.printBuf(" end Absyn.INTEGER;")
        ()
      end

      Absyn.REAL(value = s)  => begin
        Print.printBuf("record Absyn.REAL value = ")
        Print.printBuf(s)
        Print.printBuf(" end Absyn.REAL;")
        ()
      end

      Absyn.CREF(componentRef)  => begin
        Print.printBuf("record Absyn.CREF componentRef = ")
        printComponentRefAsCorbaString(componentRef)
        Print.printBuf(" end Absyn.CREF;")
        ()
      end

      Absyn.STRING(value = s)  => begin
        Print.printBuf("record Absyn.STRING value = \"")
        Print.printBuf(s)
        Print.printBuf("\" end Absyn.STRING;")
        ()
      end

      Absyn.BOOL(value = b)  => begin
        Print.printBuf("record Absyn.BOOL value = ")
        Print.printBuf(boolString(b))
        Print.printBuf(" end Absyn.BOOL;")
        ()
      end

      Absyn.BINARY(exp1, op, exp2)  => begin
        Print.printBuf("record Absyn.BINARY exp1 = ")
        printExpAsCorbaString(exp1)
        Print.printBuf(", op = ")
        printOperatorAsCorbaString(op)
        Print.printBuf(", exp2 = ")
        printExpAsCorbaString(exp2)
        Print.printBuf(" end Absyn.BINARY;")
        ()
      end

      Absyn.UNARY(op, exp)  => begin
        Print.printBuf("record Absyn.UNARY op = ")
        printOperatorAsCorbaString(op)
        Print.printBuf(", exp = ")
        printExpAsCorbaString(exp)
        Print.printBuf(" end Absyn.UNARY;")
        ()
      end

      Absyn.LBINARY(exp1, op, exp2)  => begin
        Print.printBuf("record Absyn.LBINARY exp1 = ")
        printExpAsCorbaString(exp1)
        Print.printBuf(", op = ")
        printOperatorAsCorbaString(op)
        Print.printBuf(", exp2 = ")
        printExpAsCorbaString(exp2)
        Print.printBuf(" end Absyn.LBINARY;")
        ()
      end

      Absyn.LUNARY(op, exp)  => begin
        Print.printBuf("record Absyn.LUNARY op = ")
        printOperatorAsCorbaString(op)
        Print.printBuf(", exp = ")
        printExpAsCorbaString(exp)
        Print.printBuf(" end Absyn.LUNARY;")
        ()
      end

      Absyn.RELATION(exp1, op, exp2)  => begin
        Print.printBuf("record Absyn.RELATION exp1 = ")
        printExpAsCorbaString(exp1)
        Print.printBuf(", op = ")
        printOperatorAsCorbaString(op)
        Print.printBuf(", exp2 = ")
        printExpAsCorbaString(exp2)
        Print.printBuf(" end Absyn.RELATION;")
        ()
      end

      Absyn.IFEXP(ifExp, trueBranch, elseBranch, elseIfBranch)  => begin
        Print.printBuf("record Absyn.IFEXP ifExp = ")
        printExpAsCorbaString(ifExp)
        Print.printBuf(", trueBranch = ")
        printExpAsCorbaString(trueBranch)
        Print.printBuf(", elseBranch = ")
        printExpAsCorbaString(elseBranch)
        Print.printBuf(", elseIfBranch = ")
        printListAsCorbaString(elseIfBranch, printTupleExpExpAsCorbaString, ",")
        Print.printBuf(" end Absyn.IFEXP;")
        ()
      end

      Absyn.CALL(function_, functionArgs)  => begin
        Print.printBuf("record Absyn.CALL function_ = ")
        printComponentRefAsCorbaString(function_)
        Print.printBuf(", functionArgs = ")
        printFunctionArgsAsCorbaString(functionArgs)
        Print.printBuf(" end Absyn.CALL;")
        ()
      end

      Absyn.PARTEVALFUNCTION(function_, functionArgs)  => begin
        Print.printBuf("record Absyn.PARTEVALFUNCTION function_ = ")
        printComponentRefAsCorbaString(function_)
        Print.printBuf(", functionArgs = ")
        printFunctionArgsAsCorbaString(functionArgs)
        Print.printBuf(" end Absyn.PARTEVALFUNCTION;")
        ()
      end

      Absyn.ARRAY(arrayExp)  => begin
        Print.printBuf("record Absyn.ARRAY arrayExp = ")
        printListAsCorbaString(arrayExp, printExpAsCorbaString, ",")
        Print.printBuf(" end Absyn.ARRAY;")
        ()
      end

      Absyn.MATRIX(matrix)  => begin
        Print.printBuf("record Absyn.MATRIX matrix = ")
        printListAsCorbaString(matrix, printListExpAsCorbaString, ",")
        Print.printBuf(" end Absyn.MATRIX;")
        ()
      end

      Absyn.RANGE(start, step, stop)  => begin
        Print.printBuf("record Absyn.RANGE start = ")
        printExpAsCorbaString(start)
        Print.printBuf(", step = ")
        printOption(step, printExpAsCorbaString)
        Print.printBuf(", stop = ")
        printExpAsCorbaString(stop)
        Print.printBuf(" end Absyn.RANGE;")
        ()
      end

      Absyn.TUPLE(expressions)  => begin
        Print.printBuf("record Absyn.TUPLE expressions = ")
        printListAsCorbaString(expressions, printExpAsCorbaString, ",")
        Print.printBuf(" end Absyn.TUPLE;")
        ()
      end

      Absyn.END()  => begin
        Print.printBuf("record Absyn.END end Absyn.END;")
        ()
      end

Absyn.CODE(code)  => begin
  Print.printBuf("record Absyn.CODE code = ")
  printCodeAsCorbaString(code)
  Print.printBuf(" end Absyn.CODE;")
  ()
end

Absyn.AS(id, exp)  => begin
  Print.printBuf("record Absyn.AS id = \"")
  Print.printBuf(id)
  Print.printBuf("\", exp = ")
  printExpAsCorbaString(exp)
  Print.printBuf(" end Absyn.AS;")
  ()
end

Absyn.CONS(head, rest)  => begin
  Print.printBuf("record Absyn.CONS head = ")
  printExpAsCorbaString(head)
  Print.printBuf(", rest = ")
  printExpAsCorbaString(rest)
  Print.printBuf(" end Absyn.CONS;")
  ()
end

Absyn.MATCHEXP(matchTy, inputExp, localDecls, cases, comment)  => begin
  Print.printBuf("record Absyn.MATCHEXP matchTy = ")
  printMatchTypeAsCorbaString(matchTy)
  Print.printBuf(", inputExp = ")
  printExpAsCorbaString(inputExp)
  Print.printBuf(", localDecls = ")
  printListAsCorbaString(localDecls, printElementItemAsCorbaString, ",\n")
  Print.printBuf(", cases = ")
  printListAsCorbaString(cases, printCaseAsCorbaString, ",\n")
  Print.printBuf(", comment = ")
  printStringCommentOption(comment)
  Print.printBuf(" end Absyn.MATCHEXP;")
  ()
end
end
end
#= /* Absyn.LIST and Absyn.VALUEBLOCK are only used internally, not by the parser. */ =#
end

function printMatchTypeAsCorbaString(matchTy::Absyn.MatchType)
  _ = begin
    @match matchTy begin
      Absyn.MATCH()  => begin
        Print.printBuf("record Absyn.MATCH end Absyn.MATCH;")
        ()
      end

      Absyn.MATCHCONTINUE()  => begin
        Print.printBuf("record Absyn.MATCHCONTINUE end Absyn.MATCHCONTINUE;")
        ()
      end
    end
  end
end

function printCaseAsCorbaString(case_::Absyn.Case)
  _ = begin
    local pattern::Absyn.Exp
    local patternGuard::Option
    local patternInfo::SourceInfo
    local info::SourceInfo
    local resultInfo::SourceInfo
    local localDecls::Lst
    local classPart::Absyn.ClassPart
    local result::Absyn.Exp
    local comment::Option
    @match case_ begin
      Absyn.CASE(pattern, patternGuard, patternInfo, localDecls, classPart, result, resultInfo, comment, info)  => begin
        Print.printBuf("record Absyn.CASE pattern = ")
        printExpAsCorbaString(pattern)
        Print.printBuf(", patternGuard = ")
        printOption(patternGuard, printExpAsCorbaString)
        Print.printBuf(", patternInfo = ")
        printInfoAsCorbaString(patternInfo)
        Print.printBuf(", localDecls = ")
        printListAsCorbaString(localDecls, printElementItemAsCorbaString, ",")
        Print.printBuf(", classPart = ")
        printClassPartAsCorbaString(classPart)
        Print.printBuf(", result = ")
        printExpAsCorbaString(result)
        Print.printBuf(", resultInfo = ")
        printInfoAsCorbaString(resultInfo)
        Print.printBuf(", comment = ")
        printStringCommentOption(comment)
        Print.printBuf(", info = ")
        printInfoAsCorbaString(info)
        Print.printBuf(" end Absyn.CASE;")
        ()
      end

      Absyn.ELSE(localDecls, classPart, result, resultInfo, comment, info)  => begin
        Print.printBuf("record Absyn.ELSE localDecls = ")
        printListAsCorbaString(localDecls, printElementItemAsCorbaString, ",")
        Print.printBuf(", classPart = ")
        printClassPartAsCorbaString(classPart)
        Print.printBuf(", result = ")
        printExpAsCorbaString(result)
        Print.printBuf(", resultInfo = ")
        printInfoAsCorbaString(resultInfo)
        Print.printBuf(", comment = ")
        printStringCommentOption(comment)
        Print.printBuf(", info = ")
        printInfoAsCorbaString(info)
        Print.printBuf(" end Absyn.ELSE;")
        ()
      end
    end
  end
end

function printCodeAsCorbaString(code::Absyn.CodeNode)
  _ = begin
    local path::Absyn.Path
    local componentRef::Absyn.ComponentRef
    local boolean::Bool
    local equationItemLst::Lst
    local algorithmItemLst::Lst
    local element::Absyn.Element
    local exp::Absyn.Exp
    local modification::Absyn.Modification
    @match code begin
      Absyn.C_TYPENAME(path)  => begin
        Print.printBuf("record Absyn.C_TYPENAME path = ")
        printPathAsCorbaString(path)
        Print.printBuf(" end Absyn.C_TYPENAME;")
        ()
      end

      Absyn.C_VARIABLENAME(componentRef)  => begin
        Print.printBuf("record Absyn.C_VARIABLENAME componentRef = ")
        printComponentRefAsCorbaString(componentRef)
        Print.printBuf(" end Absyn.C_VARIABLENAME;")
        ()
      end

      Absyn.C_EQUATIONSECTION(boolean, equationItemLst)  => begin
        Print.printBuf("record Absyn.C_EQUATIONSECTION boolean = ")
        Print.printBuf(boolString(boolean))
        Print.printBuf(", equationItemLst = ")
        printListAsCorbaString(equationItemLst, printEquationItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.C_EQUATIONSECTION;")
        ()
      end

      Absyn.C_ALGORITHMSECTION(boolean, algorithmItemLst)  => begin
        Print.printBuf("record Absyn.C_ALGORITHMSECTION boolean = ")
        Print.printBuf(boolString(boolean))
        Print.printBuf(", algorithmItemLst = ")
        printListAsCorbaString(algorithmItemLst, printAlgorithmItemAsCorbaString, ",")
        Print.printBuf(" end Absyn.C_ALGORITHMSECTION;")
        ()
      end

      Absyn.C_ELEMENT(element)  => begin
        Print.printBuf("record Absyn.C_ELEMENT element = ")
        printElementAsCorbaString(element)
        Print.printBuf(" end Absyn.C_ELEMENT;")
        ()
      end

      Absyn.C_EXPRESSION(exp)  => begin
        Print.printBuf("record Absyn.C_EXPRESSION exp = ")
        printExpAsCorbaString(exp)
        Print.printBuf(" end Absyn.C_EXPRESSION;")
        ()
      end

      Absyn.C_MODIFICATION(modification)  => begin
        Print.printBuf("record Absyn.C_MODIFICATION modification = ")
        printModificationAsCorbaString(modification)
        Print.printBuf(" end Absyn.C_MODIFICATION;")
        ()
      end
    end
  end
end

function printListExpAsCorbaString(inLst::Lst)
  printListAsCorbaString(inLst, printExpAsCorbaString, ",")
end

function printListAsCorbaString(inTypeALst::Lst, inFuncTypeTypeATo::FuncTypeType_aTo, inString::String)
  Print.printBuf("{")
  printList(inTypeALst, inFuncTypeTypeATo, inString)
  Print.printBuf("}")
end

function printTupleAsCorbaString(inTpl::Tuple, fnA::FuncTypeType_a, fnB::FuncTypeType_b)
  _ = begin
    local a::Type_a
    local b::Type_b
    @match inTpl, fnA, fnB begin
      ((a, b), _, _)  => begin
        Print.printBuf("(")
        fnA(a)
        Print.printBuf(",")
        fnB(b)
        Print.printBuf(")")
        ()
      end
    end
  end
end

function printOperatorAsCorbaString(op::Absyn.Operator)
  _ = begin
    @match op begin
      Absyn.ADD()  => begin
        Print.printBuf("record Absyn.ADD end Absyn.ADD;")
        ()
      end

      Absyn.SUB()  => begin
        Print.printBuf("record Absyn.SUB end Absyn.SUB;")
        ()
      end

      Absyn.MUL()  => begin
        Print.printBuf("record Absyn.MUL end Absyn.MUL;")
        ()
      end

      Absyn.DIV()  => begin
        Print.printBuf("record Absyn.DIV end Absyn.DIV;")
        ()
      end

      Absyn.POW()  => begin
        Print.printBuf("record Absyn.POW end Absyn.POW;")
        ()
      end

      Absyn.UPLUS()  => begin
        Print.printBuf("record Absyn.UPLUS end Absyn.UPLUS;")
        ()
      end

      Absyn.UMINUS()  => begin
        Print.printBuf("record Absyn.UMINUS end Absyn.UMINUS;")
        ()
      end

      Absyn.ADD_EW()  => begin
        Print.printBuf("record Absyn.ADD_EW end Absyn.ADD_EW;")
        ()
      end

      Absyn.SUB_EW()  => begin
        Print.printBuf("record Absyn.SUB_EW end Absyn.SUB_EW;")
        ()
      end

      Absyn.MUL_EW()  => begin
        Print.printBuf("record Absyn.MUL_EW end Absyn.MUL_EW;")
        ()
      end

      Absyn.DIV_EW()  => begin
        Print.printBuf("record Absyn.DIV_EW end Absyn.DIV_EW;")
        ()
      end

      Absyn.UPLUS_EW()  => begin
        Print.printBuf("record Absyn.UPLUS_EW end Absyn.UPLUS_EW;")
        ()
      end

      Absyn.UMINUS_EW()  => begin
        Print.printBuf("record Absyn.UMINUS_EW end Absyn.UMINUS_EW;")
        ()
      end

      Absyn.AND()  => begin
        Print.printBuf("record Absyn.AND end Absyn.AND;")
        ()
      end

      Absyn.OR()  => begin
        Print.printBuf("record Absyn.OR end Absyn.OR;")
        ()
      end

      Absyn.NOT()  => begin
        Print.printBuf("record Absyn.NOT end Absyn.NOT;")
        ()
      end

      Absyn.LESS()  => begin
        Print.printBuf("record Absyn.LESS end Absyn.LESS;")
        ()
      end

      Absyn.LESSEQ()  => begin
        Print.printBuf("record Absyn.LESSEQ end Absyn.LESSEQ;")
        ()
      end

      Absyn.GREATER()  => begin
        Print.printBuf("record Absyn.GREATER end Absyn.GREATER;")
        ()
      end

      Absyn.GREATEREQ()  => begin
        Print.printBuf("record Absyn.GREATEREQ end Absyn.GREATEREQ;")
        ()
      end

      Absyn.EQUAL()  => begin
        Print.printBuf("record Absyn.EQUAL end Absyn.EQUAL;")
        ()
      end

      Absyn.NEQUAL()  => begin
        Print.printBuf("record Absyn.NEQUAL end Absyn.NEQUAL;")
        ()
      end
    end
  end
end

function printEachAsCorbaString(each_::Absyn.Each)
  _ = begin
    @match each_ begin
      Absyn.EACH()  => begin
        Print.printBuf("record Absyn.EACH end Absyn.EACH;")
        ()
      end

      Absyn.NON_EACH()  => begin
        Print.printBuf("record Absyn.NON_EACH end Absyn.NON_EACH;")
        ()
      end
    end
  end
end

function printTupleExpExpAsCorbaString(tpl::Tuple)
  printTupleAsCorbaString(tpl, printExpAsCorbaString, printExpAsCorbaString)
end

function printStringAsCorbaString(s::String)
  Print.printBuf("\"")
  Print.printBuf(s)
  Print.printBuf("\"")
end

function writePath(file::File.File, path::Absyn.Path, escape::Escape, delimiter::String, initialDot::Bool)
  local p::Absyn.Path = path

  while true
    p = begin
      @match p begin
        Absyn.IDENT()  => begin
          File.writeEscape(file, p.name, escape)
          return
          fail()
        end

        Absyn.QUALIFIED()  => begin
          File.writeEscape(file, p.name, escape)
          File.writeEscape(file, delimiter, escape)
          p.path
        end

        Absyn.FULLYQUALIFIED()  => begin
          if initialDot
            File.writeEscape(file, delimiter, escape)
          end
          p.path
        end
      end
    end
  end
end

end

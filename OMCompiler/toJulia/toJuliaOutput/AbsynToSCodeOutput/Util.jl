  module Util


    using MetaModelica
    #= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
    using ExportAll
    #= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#

    @UniontypeDecl ReplacePattern
    @UniontypeDecl Status
    @UniontypeDecl DateTime

    FuncType = Function

    FuncType = Function

    FuncType = Function

    FuncType = Function

    FuncType = Function

    FuncType = Function

    CompareFunc = Function

    FuncType = Function
    @UniontypeDecl TranslatableContent

    FuncT = Function

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

         @Uniontype ReplacePattern begin
              @Record REPLACEPATTERN begin

                       from #= from string (ie \\\".\\\" =#::String
                       to #= to string (ie \\\"$p\\\") )) =#::String
              end
         end

          #= Used to signal success or failure of a function call =#
         @Uniontype Status begin
              @Record SUCCESS begin

              end

              @Record FAILURE begin

              end
         end

         @Uniontype DateTime begin
              @Record DATETIME begin

                       sec::ModelicaInteger
                       min::ModelicaInteger
                       hour::ModelicaInteger
                       mday::ModelicaInteger
                       mon::ModelicaInteger
                       year::ModelicaInteger
              end
         end

        import Autoconf
        import ClockIndexes
        import Config
        import Flags
        import Global
        import MetaModelica.ListUtil
        import Print
        import System

         const dummyInfo = SOURCEINFO("", false, 0, 0, 0, 0, 0.0)::SourceInfo

         const derivativeNamePrefix = "DER"::String

         const pointStr = "P"::String

         const leftBraketStr = "lB"::String

         const rightBraketStr = "rB"::String

         const leftParStr = "lP"::String

         const rightParStr = "rP"::String

         const commaStr = "c"::String

         const appostrophStr = "a"::String

         const replaceStringPatterns = list(REPLACEPATTERN(".", pointStr), REPLACEPATTERN("[", leftBraketStr), REPLACEPATTERN("]", rightBraketStr), REPLACEPATTERN("(", leftParStr), REPLACEPATTERN(")", rightParStr), REPLACEPATTERN(",", commaStr), REPLACEPATTERN("'", appostrophStr))::List

         #= Author: BZ =#
        function isIntGreater(lhs::ModelicaInteger, rhs::ModelicaInteger) ::Bool
              local b::Bool = lhs > rhs
          b
        end

         #= Author: BZ =#
        function isRealGreater(lhs::ModelicaReal, rhs::ModelicaReal) ::Bool
              local b::Bool = lhs > rhs
          b
        end

         #= If operating system is Linux/Unix, return a './', otherwise return empty string =#
        function linuxDotSlash() ::String
              local str::String

              str = Autoconf.os
              str = if str == "linux" || str == "OSX"
                    "./"
                  else
                    ""
                  end
          str
        end

         #= author: x02lucpo
          Extracts the flagvalue from an argument list:
          flagValue('-s',{'-d','hej','-s','file'}) => 'file' =#
        function flagValue(flag::String, arguments::List{<:String}) ::String
              local flagVal::String

              local arg::String
              local rest::List{String} = arguments

              while ! listEmpty(rest)
                @match arg <| rest = rest
                if arg == flag
                  break
                end
              end
              flagVal = if listEmpty(rest)
                    ""
                  else
                    listHead(rest)
                  end
          flagVal
        end

         #= Selects the first non-empty string from a list of strings.
           Returns an empty string if no such string exists. =#
        function selectFirstNonEmptyString(inStrings::List{<:String}) ::String
              local outResult::String

              for e in inStrings
                if e != ""
                  outResult = e
                  return outResult
                end
              end
              outResult = ""
          outResult
        end

         #=   Function could used with List.sort to sort a
          List as list< tuple<Integer, Type_a> > by first argument.
           =#
        function compareTupleIntGt(inTplA::Tuple{ModelicaInteger, T}, inTplB::Tuple{ModelicaInteger, T})  where {T}
              local res::Bool

              local a::ModelicaInteger
              local b::ModelicaInteger

              (a, _) = inTplA
              (b, _) = inTplB
              res = intGt(a, b)
          res
        end

         #=   Function could used with List.sort to sort a
          List as list< tuple<Integer, Type_a> > by first argument.
           =#
        function compareTupleIntLt(inTplA::Tuple{ModelicaInteger, T}, inTplB::Tuple{ModelicaInteger, T})  where {T}
              local res::Bool

              local a::ModelicaInteger
              local b::ModelicaInteger

              (a, _) = inTplA
              (b, _) = inTplB
              res = intLt(a, b)
          res
        end

         #=   Function could used with List.sort to sort a
          List as list< tuple<Type_a,Integer> > by second argument.
           =#
        function compareTuple2IntGt(inTplA::Tuple{T, ModelicaInteger}, inTplB::Tuple{T, ModelicaInteger})  where {T}
              local res::Bool

              local a::ModelicaInteger
              local b::ModelicaInteger

              (_, a) = inTplA
              (_, b) = inTplB
              res = intGt(a, b)
          res
        end

         #=   Function could used with List.sort to sort a
          List as list< tuple<Type_a,Integer> > by second argument.
           =#
        function compareTuple2IntLt(inTplA::Tuple{T, ModelicaInteger}, inTplB::Tuple{T, ModelicaInteger})  where {T}
              local res::Bool

              local a::ModelicaInteger
              local b::ModelicaInteger

              (_, a) = inTplA
              (_, b) = inTplB
              res = intLt(a, b)
          res
        end

         #= Takes a tuple of two values and returns the first value.
           Example: tuple21(('a', 1)) => 'a' =#
        function tuple21(inTuple::Tuple{T1, T2})  where {T1, T2}
              local outValue::T1

              (outValue, _) = inTuple
          outValue
        end

         #= Takes a tuple of two values and returns the second value.
           Example: tuple22(('a',1)) => 1 =#
        function tuple22(inTuple::Tuple{T1, T2})  where {T1, T2}
              local outValue::T2

              (_, outValue) = inTuple
          outValue
        end

         #= Takes an option tuple of two values and returns the second value.
           Example: optTuple22(SOME('a',1)) => 1 =#
        function optTuple22(inTuple::Option{Tuple{T1, T2}})  where {T1, T2}
              local outValue::T2

              @match SOME((_, outValue)) = inTuple
          outValue
        end

         #= Takes a tuple of three values and returns the tuple of the two first values.
           Example: tuple312(('a',1,2)) => ('a',1) =#
        function tuple312(inTuple::Tuple{T1, T2, T3})  where {T1, T2, T3}
              local outTuple::Tuple{T1, T2}

              local e1::T1
              local e2::T2

              (e1, e2, _) = inTuple
              outTuple = (e1, e2)
          outTuple
        end

         #= Takes a tuple of three values and returns the first value.
           Example: tuple31(('a',1,2)) => 'a' =#
        function tuple31(inValue::Tuple{T1, T2, T3})  where {T1, T2, T3}
              local outValue::T1

              (outValue, _, _) = inValue
          outValue
        end

         #= Takes a tuple of three values and returns the second value.
           Example: tuple32(('a',1,2)) => 1 =#
        function tuple32(inValue::Tuple{T1, T2, T3})  where {T1, T2, T3}
              local outValue::T2

              (_, outValue, _) = inValue
          outValue
        end

         #= Takes a tuple of three values and returns the first value.
           Example: tuple33(('a',1,2)) => 2 =#
        function tuple33(inValue::Tuple{T1, T2, T3})  where {T1, T2, T3}
              local outValue::T3

              (_, _, outValue) = inValue
          outValue
        end

        function tuple41(inTuple::Tuple{T1, T2, T3, T4})  where {T1, T2, T3, T4}
              local outValue::T1

              (outValue, _, _, _) = inTuple
          outValue
        end

        function tuple42(inTuple::Tuple{T1, T2, T3, T4})  where {T1, T2, T3, T4}
              local outValue::T2

              (_, outValue, _, _) = inTuple
          outValue
        end

        function tuple43(inTuple::Tuple{T1, T2, T3, T4})  where {T1, T2, T3, T4}
              local outValue::T3

              (_, _, outValue, _) = inTuple
          outValue
        end

        function tuple44(inTuple::Tuple{T1, T2, T3, T4})  where {T1, T2, T3, T4}
              local outValue::T4

              (_, _, _, outValue) = inTuple
          outValue
        end

        function tuple51(inTuple::Tuple{T1, T2, T3, T4, T5})  where {T1, T2, T3, T4, T5}
              local outValue::T1

              (outValue, _, _, _, _) = inTuple
          outValue
        end

        function tuple52(inTuple::Tuple{T1, T2, T3, T4, T5})  where {T1, T2, T3, T4, T5}
              local outValue::T2

              (_, outValue, _, _, _) = inTuple
          outValue
        end

        function tuple53(inTuple::Tuple{T1, T2, T3, T4, T5})  where {T1, T2, T3, T4, T5}
              local outValue::T3

              (_, _, outValue, _, _) = inTuple
          outValue
        end

        function tuple54(inTuple::Tuple{T1, T2, T3, T4, T5})  where {T1, T2, T3, T4, T5}
              local outValue::T4

              (_, _, _, outValue, _) = inTuple
          outValue
        end

        function tuple55(inTuple::Tuple{T1, T2, T3, T4, T5})  where {T1, T2, T3, T4, T5}
              local outValue::T5

              (_, _, _, _, outValue) = inTuple
          outValue
        end

        function tuple61(inTuple::Tuple{T1, T2, T3, T4, T5, T6})  where {T1, T2, T3, T4, T5, T6}
              local outValue::T1

              (outValue, _, _, _, _, _) = inTuple
          outValue
        end

        function tuple62(inTuple::Tuple{T1, T2, T3, T4, T5, T6})  where {T1, T2, T3, T4, T5, T6}
              local outValue::T2

              (_, outValue, _, _, _, _) = inTuple
          outValue
        end

         #= Returns true if a string contains a specified character =#
        function stringContainsChar(str::String, char::String) ::Bool
              local res::Bool

              res = begin
                @matchcontinue () begin
                  ()  => begin
                      @match _ <| _ <| _ = stringSplitAtChar(str, char)
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          res
        end

         #=
        Author: BZ, 2009-11
        Same functionality as stringDelimitListPrint, but writes to print buffer instead of string variable.
        Usefull for heavy string operations(causes malloc error on some models when generating init file).
         =#
        function stringDelimitListPrintBuf(inStringLst::List{<:String}, inDelimiter::String)
              _ = begin
                  local f::String
                  local delim::String
                  local str1::String
                  local str2::String
                  local str::String
                  local r::List{String}
                @matchcontinue inStringLst begin
                   nil()  => begin
                    ()
                  end

                  f <|  nil()  => begin
                      Print.printBuf(f)
                    ()
                  end

                  f <| r  => begin
                      stringDelimitListPrintBuf(r, inDelimiter)
                      Print.printBuf(f)
                      Print.printBuf(inDelimiter)
                    ()
                  end
                end
              end
        end

         #= author: PA
          This function is similar to stringDelimitList, i.e it inserts string delimiters between
          consecutive strings in a list. But it also count the lists and inserts a second string delimiter
          when the counter is reached. This can be used when for instance outputting large lists of values
          and a newline is needed after ten or so items. =#
        function stringDelimitListAndSeparate(str::List{<:String}, sep1::String, sep2::String, n::ModelicaInteger) ::String
              local res::String

              local handle::ModelicaInteger

              handle = Print.saveAndClearBuf()
              stringDelimitListAndSeparate2(str, sep1, sep2, n, 0)
              res = Print.getString()
              Print.restoreBuf(handle)
          res
        end

         #= author: PA
          Helper function to stringDelimitListAndSeparate =#
        function stringDelimitListAndSeparate2(inStringLst1::List{<:String}, inString2::String, inString3::String, inInteger4::ModelicaInteger, inInteger5::ModelicaInteger)
              _ = begin
                  local s::String
                  local str1::String
                  local str::String
                  local f::String
                  local sep1::String
                  local sep2::String
                  local r::List{String}
                  local n::ModelicaInteger
                  local iter_1::ModelicaInteger
                  local iter::ModelicaInteger
                @matchcontinue (inStringLst1, inString2, inString3, inInteger4, inInteger5) begin
                  ( nil(), _, _, _, _)  => begin
                    ()
                  end

                  (s <|  nil(), _, _, _, _)  => begin
                      Print.printBuf(s)
                    ()
                  end

                  (f <| r, sep1, sep2, n, 0)  => begin
                      Print.printBuf(f)
                      Print.printBuf(sep1)
                      stringDelimitListAndSeparate2(r, sep1, sep2, n, 1) #= special case for first element =#
                    ()
                  end

                  (f <| r, sep1, sep2, n, iter)  => begin
                      @match 0 = intMod(iter, n) #= insert second delimiter =#
                      iter_1 = iter + 1
                      Print.printBuf(f)
                      Print.printBuf(sep1)
                      Print.printBuf(sep2)
                      stringDelimitListAndSeparate2(r, sep1, sep2, n, iter_1)
                    ()
                  end

                  (f <| r, sep1, sep2, n, iter)  => begin
                      iter_1 = iter + 1 #= not inserting second delimiter =#
                      Print.printBuf(f)
                      Print.printBuf(sep1)
                      stringDelimitListAndSeparate2(r, sep1, sep2, n, iter_1)
                    ()
                  end

                  _  => begin
                        print("- stringDelimitListAndSeparate2 failed\\n")
                      fail()
                  end
                end
              end
               #= /* iterator */ =#
        end

         #= the string delimiter inserted between those elements that are not empty.
          Example: stringDelimitListNonEmptyElts({\\\"x\\\",\\\"\\\",\\\"z\\\"}, \\\", \\\") => \\\"x, z\\\" =#
        function stringDelimitListNonEmptyElts(lst::List{<:String}, delim::String) ::String
              local str::String

              local lst1::List{String}

              lst1 = ListUtil.select(lst, isNotEmptyString)
              str = stringDelimitList(lst1, delim)
          str
        end

         #=  splits the input string at the delimiter string in list of strings and converts to integer list which is then summarized
           =#
        function mulStringDelimit2Int(inString::String, delim::String) ::ModelicaInteger
              local i::ModelicaInteger

              local lst::List{String}
              local lst2::List{ModelicaInteger}

              lst = stringSplitAtChar(inString, delim)
              lst2 = ListUtil.map(lst, stringInt)
              if ! listEmpty(lst2)
                i = ListUtil.fold(lst2, intMul, 1)
              else
                i = 0
              end
          i
        end

         #= Takes a string and two chars and replaces the first char with the second char:
          Example: string_replace_char(\\\"hej.b.c\\\",\\\".\\\",\\\"_\\\") => \\\"hej_b_c\\\"
          2007-11-26 BZ: Now it is possible to replace chars with emptychar, and
                         replace a char with a string
          Example: string_replace_char(\\\"hej.b.c\\\",\\\".\\\",\\\"_dot_\\\") => \\\"hej_dot_b_dot_c\\\"
           =#
        function stringReplaceChar(inString1::String, inString2::String, inString3::String) ::String
              local outString::String

              outString = System.stringReplace(inString1, inString2, inString3)
          outString
        end

         #= Takes a string and a char and split the string at the char returning the list of components.
          Example: stringSplitAtChar(\\\"hej.b.c\\\",\\\".\\\") => {\\\"hej,\\\"b\\\",\\\"c\\\"} =#
        function stringSplitAtChar(string::String, token::String) ::List{String}
              local strings::List{String} = nil

              local ch::ModelicaInteger = stringCharInt(token)
              local cur::List{String} = nil

              for c in stringListStringChar(string)
                if stringCharInt(c) == ch
                  strings = stringAppendList(listReverse(cur)) <| strings
                  cur = nil
                else
                  cur = c <| cur
                end
              end
              if ! listEmpty(cur)
                strings = stringAppendList(listReverse(cur)) <| strings
              end
              strings = listReverse(strings)
          strings
        end

         #=  this replaces symbols that are illegal in C to legal symbols
         see replaceStringPatterns to see the format. (example: \\\".\\\" becomes \\\"$P\\\")
          author: x02lucpo

          NOTE: This function should not be used in OMC, since the OMC backend no longer
            uses stringified components. It is still used by MathCore though. =#
        function modelicaStringToCStr(str::String, changeDerCall::Bool #= if true, first change 'DER(v)' to $derivativev =#) ::String
              local res_str::String

              res_str = begin
                  local s::String
                @matchcontinue (str, changeDerCall) begin
                  (s, false)  => begin
                      @match false = Flags.getConfigBool(Flags.TRANSLATE_DAE_STRING)
                    s
                  end

                  (_, false)  => begin
                      res_str = "" + modelicaStringToCStr1(str, replaceStringPatterns)
                    res_str
                  end

                  (s, true)  => begin
                      s = modelicaStringToCStr2(s)
                    s
                  end
                end
              end
               #=  BoschRexroth specifics
               =#
               #=  debug_print(\"prefix$\", res_str);
               =#
          res_str
        end

         #= help function to modelicaStringToCStr,
        first  changes name 'der(v)' to $derivativev and 'pre(v)' to 'pre(v)' with applied rules for v =#
        function modelicaStringToCStr2(inDerName::String) ::String
              local outDerName::String

              outDerName = begin
                  local name::String
                  local derName::String
                  local names::List{String}
                @matchcontinue inDerName begin
                  derName  => begin
                      @match 0 = System.strncmp(derName, "der(", 4)
                      @match _ <| names = System.strtok(derName, "()")
                      names = ListUtil.map1(names, modelicaStringToCStr, false)
                      name = derivativeNamePrefix + stringAppendList(names)
                    name
                  end

                  derName  => begin
                      @match 0 = System.strncmp(derName, "pre(", 4)
                      @match _ <| name <| _ = System.strtok(derName, "()")
                      name = "pre(" + modelicaStringToCStr(name, false) + ")"
                    name
                  end

                  derName  => begin
                    modelicaStringToCStr(derName, false)
                  end
                end
              end
               #=  adrpo: 2009-09-08
               =#
               #=  the commented text: _::name::_ = listLast(System.strtok(derName,\"()\"));
               =#
               #=  is wrong as der(der(x)) ends up beeing translated to $der$der instead
               =#
               #=  of $der$der$x. Changed to the following 2 lines below!
               =#
          outDerName
        end

         #=  =#
        function modelicaStringToCStr1(inString::String, inReplacePatternLst::List{<:ReplacePattern}) ::String
              local outString::String

              outString = begin
                  local str::String
                  local str_1::String
                  local res_str::String
                  local from::String
                  local to::String
                  local res::List{ReplacePattern}
                @matchcontinue (inString, inReplacePatternLst) begin
                  (str,  nil())  => begin
                    str
                  end

                  (str, REPLACEPATTERN(from = from, to = to) <| res)  => begin
                      str_1 = modelicaStringToCStr1(str, res)
                      res_str = System.stringReplace(str_1, from, to)
                    res_str
                  end

                  _  => begin
                        print("- Util.modelicaStringToCStr1 failed for str:" + inString + "\\n")
                      fail()
                  end
                end
              end
          outString
        end

         #=  this replaces symbols that have been replace to correct value for modelica string
         see replaceStringPatterns to see the format. (example: \\\"$p\\\" becomes \\\".\\\")
          author: x02lucpo

          NOTE: This function should not be used in OMC, since the OMC backend no longer
            uses stringified components. It is still used by MathCore though. =#
        function cStrToModelicaString(str::String) ::String
              local res_str::String

              res_str = cStrToModelicaString1(str, replaceStringPatterns)
          res_str
        end

        function cStrToModelicaString1(inString::String, inReplacePatternLst::List{<:ReplacePattern}) ::String
              local outString::String

              outString = begin
                  local str::String
                  local str_1::String
                  local res_str::String
                  local from::String
                  local to::String
                  local res::List{ReplacePattern}
                @match (inString, inReplacePatternLst) begin
                  (str,  nil())  => begin
                    str
                  end

                  (str, REPLACEPATTERN(from = from, to = to) <| res)  => begin
                      str_1 = cStrToModelicaString1(str, res)
                      res_str = System.stringReplace(str_1, to, from)
                    res_str
                  end
                end
              end
          outString
        end

         #= Example:
            boolOrList({true,false,false})  => true
            boolOrList({false,false,false}) => false =#
        function boolOrList(inBooleanLst::List{<:Bool}) ::Bool
              local outBoolean::Bool = false

              for b in inBooleanLst
                if b
                  outBoolean = true
                  return outBoolean
                end
              end
          outBoolean
        end

         #= Takes a list of boolean values and applies the boolean AND operator on the elements
          Example:
          boolAndList({}) => true
          boolAndList({true, true}) => true
          boolAndList({false,false,true}) => false =#
        function boolAndList(inBooleanLst::List{<:Bool}) ::Bool
              local outBoolean::Bool = true

              for b in inBooleanLst
                if ! b
                  outBoolean = false
                  return outBoolean
                end
              end
          outBoolean
        end

         #= Takes an option value and a function over the value. It returns in another
           option value, resulting from the application of the function on the value.

           Example:
             applyOption(SOME(1), intString) => SOME(\\\"1\\\")
             applyOption(NONE(),  intString) => NONE()
           =#
        function applyOption(inOption::Option{TI}, inFunc::FuncType)  where {TI}
              local outOption::Option
              outOption = begin
                  local ival::TI
                  local oval
                @match inOption begin
                  SOME(ival)  => begin
                    SOME(inFunc(ival))
                  end
                  _  => begin
                      NONE()
                  end
                end
              end
          outOption
        end

         #= Like applyOption but takes an additional argument =#
        function applyOption1(inOption::Option{TI}, inFunc::FuncType, inArg::ArgT)  where {TI, ArgT}
              local outOption::Option
              outOption = begin
                  local ival::TI
                  local oval
                @match inOption begin
                  SOME(ival)  => begin
                    SOME(inFunc(ival, inArg))
                  end

                  _  => begin
                      NONE()
                  end
                end
              end
          outOption
        end

         #= Takes an optional value, a function and an extra value. If the optional value
           is SOME, applies the function on that value and returns the result.
           Otherwise returns the extra value. =#
        function applyOptionOrDefault(inValue::Option{TI}, inFunc::FuncType, inDefaultValue)  where {TI, TO}
              local outValue
              outValue = begin
                  local value::TI
                  local res
                @match inValue begin
                  SOME(value)  => begin
                    inFunc(value)
                  end
                  _  => begin
                      inDefaultValue
                  end
                end
              end
          outValue
        end

         #= Takes an optional value, a function, an extra argument and an extra value.
           If the optional value is SOME, applies the function on that value and the
           extra argument and returns the result. Otherwise returns the extra value. =#
        function applyOptionOrDefault1(inValue::Option{TI}, inFunc::FuncType, inArg::ArgT, inDefaultValue::TO)  where {TI, ArgT, TO}
              local outValue::TO
              outValue = begin
                  local value::TI
                  local res
                @match inValue begin
                  SOME(value)  => begin
                    inFunc(value, inArg)
                  end

                  _  => begin
                      inDefaultValue
                  end
                end
              end
          outValue
        end

         #= Takes an optional value, a function, two extra arguments and an extra value.
           If the optional value is SOME, applies the function on that value and the
           extra argument and returns the result. Otherwise returns the extra value. =#
        function applyOptionOrDefault2(inValue::Option{TI}, inFunc::FuncType, inArg1::ArgT1, inArg2::ArgT2, inDefaultValue::TO)  where {TI, TO, ArgT1, ArgT2}
              local outValue
              outValue = begin
                  local value::TI
                  local res::TO
                @match inValue begin
                  SOME(value)  => begin
                    inFunc(value, inArg1, inArg2)
                  end
                  _  => begin
                      inDefaultValue
                  end
                end
              end
          outValue
        end

        function applyOption_2(inValue1::Option{T}, inValue2::Option{T}, inFunc::FuncType)  where {T}
              local outValue::Option{T}

              outValue = begin
                @match (inValue1, inValue2) begin
                  (NONE(), _)  => begin
                    inValue2
                  end

                  (_, NONE())  => begin
                    inValue1
                  end

                  _  => begin
                      SOME(inFunc(getOption(inValue1), getOption(inValue2)))
                  end
                end
              end
          outValue
        end

         #= Makes a value into value option, using SOME(value) =#
        function makeOption(inValue::T)  where {T}
              local outOption::Option{T} = SOME(inValue)
          outOption
        end

        function makeOptionOnTrue(inCondition::Bool, inValue::T)  where {T}
              local outOption::Option{T} = if inCondition
                    SOME(inValue)
                  else
                    NONE()
                  end
          outOption
        end

         #= author: PA
          Returns string value or empty string from string option. =#
        function stringOption(inStringOption::Option{<:String}) ::String
              local outString::String

              outString = begin
                  local s::String
                @match inStringOption begin
                  SOME(s)  => begin
                    s
                  end

                  _  => begin
                      ""
                  end
                end
              end
          outString
        end

         #= Returns an option value if SOME, otherwise fails =#
        function getOption(inOption::Option{T})  where {T}
              local outValue::T

              @match SOME(outValue) = inOption
          outValue
        end

         #= Returns an option value if SOME, otherwise the default =#
        function getOptionOrDefault(inOption::Option{T}, inDefault::T)  where {T}
              local outValue::T

              outValue = begin
                  local value::T
                @match inOption begin
                  SOME(value)  => begin
                    value
                  end

                  _  => begin
                      inDefault
                  end
                end
              end
          outValue
        end

         #= Returns true if integer value is greater zero (> 0) =#
        function intGreaterZero(v::ModelicaInteger) ::Bool
              local res::Bool = v > 0
          res
        end

         #= Returns true if integer value is positive (>= 0) =#
        function intPositive(v::ModelicaInteger) ::Bool
              local res::Bool = v >= 0
          res
        end

         #= Returns true if integer value is negative (< 0) =#
        function intNegative(v::ModelicaInteger) ::Bool
              local res::Bool = v < 0
          res
        end

        function intSign(i::ModelicaInteger) ::ModelicaInteger
              local o::ModelicaInteger = if i == 0
                    0
                  elseif (i > 0)
                        1
                  else
                    -1
                  end
          o
        end

         #= Compares two integers and return -1 if the first is smallest, 1 if the second
           is smallest, or 0 if they are equal. =#
        function intCompare(inN::ModelicaInteger, inM::ModelicaInteger) ::ModelicaInteger
              local outResult::ModelicaInteger = if inN == inM
                    0
                  elseif (inN > inM)
                        1
                  else
                    -1
                  end
          outResult
        end

         #= Performs integer exponentiation. =#
        function intPow(base::ModelicaInteger, exponent::ModelicaInteger) ::ModelicaInteger
              local result::ModelicaInteger = 1

              if exponent >= 0
                for i in 1:exponent
                  result = result * base
                end
              else
                fail()
              end
          result
        end

         #= Compares two reals and return -1 if the first is smallest, 1 if the second
           is smallest, or 0 if they are equal. =#
        function realCompare(inN::ModelicaReal, inM::ModelicaReal) ::ModelicaInteger
              local outResult::ModelicaInteger = if inN == inM
                    0
                  elseif (inN > inM)
                        1
                  else
                    -1
                  end
          outResult
        end

         #= Compares two booleans and return -1 if the first is smallest, 1 if the second
           is smallest, or 0 if they are equal. =#
        function boolCompare(inN::Bool, inM::Bool) ::ModelicaInteger
              local outResult::ModelicaInteger = if inN == inM
                    0
                  elseif (inN > inM)
                        1
                  else
                    -1
                  end
          outResult
        end

         #= Returns true if string is not the empty string. =#
        function isNotEmptyString(inString::String) ::Bool
              local outIsNotEmpty::Bool = stringLength(inString) > 0
          outIsNotEmpty
        end

         #= This function tries to write to a file and if it fails then it
          outputs \\\"# Cannot write to file: <filename>.\\\" to errorBuf =#
        function writeFileOrErrorMsg(inFilename::String, inString::String)
              try
                System.writeFile(inFilename, inString)
              catch
                Print.printErrorBuf("# Cannot write to file: " + inFilename + ".")
              end
        end

        function stringStartsWith(inString1::String, inString2::String) ::Bool
              local outEqual::Bool

              outEqual = 0 == System.strncmp(inString1, inString2, stringLength(inString1))
          outEqual
        end

         #= Compare two strings up to the nth character
          Returns true if they are equal. =#
        function strncmp(inString1::String, inString2::String, inLength::ModelicaInteger) ::Bool
              local outEqual::Bool

              outEqual = 0 == System.strncmp(inString1, inString2, inLength)
          outEqual
        end

         #= Compares two strings up to the nth character. Returns true if they are not
          equal. =#
        function notStrncmp(inString1::String, inString2::String, inLength::ModelicaInteger) ::Bool
              local outEqual::Bool

              outEqual = 0 != System.strncmp(inString1, inString2, inLength)
          outEqual
        end

         #= author: PA
          Returns tick as a string, i.e. an unique number. =#
        function tickStr() ::String
              local s::String = intString(tick())
          s
        end

         #= @author: adrpo
         replace \\\\ with path delimiter only in Windows! =#
        function replaceWindowsBackSlashWithPathDelimiter(inPath::String) ::String
              local outPath::String

              if Autoconf.os == "Windows_NT"
                outPath = System.stringReplace(inPath, "\\\\", Autoconf.pathDelimiter)
              else
                outPath = inPath
              end
          outPath
        end

         #= author: x02lucpo
          splits the filepath in directory and filename
          (\\\"c:\\\\programs\\\\file.mo\\\") => (\\\"c:\\\\programs\\\",\\\"file.mo\\\")
          (\\\"..\\\\work\\\\file.mo\\\") => (\\\"c:\\\\openmodelica123\\\\work\\\", \\\"file.mo\\\") =#
        function getAbsoluteDirectoryAndFile(filename::String) ::Tuple{String, String}
              local basename::String
              local dirname::String

              local realpath::String

              realpath = System.realpath(filename)
              dirname = System.dirname(realpath)
              basename = System.basename(realpath)
              dirname = replaceWindowsBackSlashWithPathDelimiter(dirname)
          (dirname, basename)
        end

         #= author: x02lucpo
          replace the double-backslash with backslash =#
        function rawStringToInputString(inString::String) ::String
              local outString::String

              outString = System.stringReplace(inString, "\\\\\\", "\\") #= change backslash-double-quote to double-quote  =#
              outString = System.stringReplace(outString, "\\\\\\\\", "\\\\") #= double-backslash with backslash  =#
          outString
        end

        function escapeModelicaStringToCString(modelicaString::String) ::String
              local cString::String

               #=  C cannot handle newline in string constants
               =#
              cString = System.escapedString(modelicaString, true)
          cString
        end

        function escapeModelicaStringToJLString(modelicaString::String) ::String
              local cString::String

               #= TODO. Do this the proper way. We just remove all the dollars for now
               =#
              cString = System.stringReplace(modelicaString, "", "")
              cString = System.stringReplace(cString, "\\", "")
              cString = System.stringReplace(cString, "\\", "")
              cString = System.stringReplace(cString, "\\\\", "")
              cString = System.escapedString(cString, true)
          cString
        end

        function escapeModelicaStringToXmlString(modelicaString::String) ::String
              local xmlString::String

               #=  C cannot handle newline in string constants
               =#
              xmlString = System.stringReplace(modelicaString, "&", "&amp;")
              xmlString = System.stringReplace(xmlString, "\\", "&quot;")
              xmlString = System.stringReplace(xmlString, "<", "&lt;")
              xmlString = System.stringReplace(xmlString, ">", "&gt;")
               #=  TODO! FIXME!, we have issues with accented chars in comments
               =#
               #=  that end up in the Model_init.xml file and makes it not well
               =#
               #=  formed but the line below does not work if the xmlString is
               =#
               #=  already UTF-8. We should somehow detect the encoding.
               =#
               #=  xmlString := System.iconv(xmlString, \"\", \"UTF-8\");
               =#
          xmlString
        end

        function makeTuple(inValue1::T1, inValue2::T2)  where {T1, T2}
              local outTuple::Tuple{T1, T2} = (inValue1, inValue2)
          outTuple
        end

        function makeTupleR(inValue1::T1, inValue2::T2)  where {T1, T2}
              local outTuple::Tuple{T2, T1} = (inValue2, inValue1)
          outTuple
        end

        function make3Tuple(inValue1::T1, inValue2::T2, inValue3::T3)  where {T1, T2, T3}
              local outTuple::Tuple{T1, T2, T3} = (inValue1, inValue2, inValue3)
          outTuple
        end

        function mulListIntegerOpt(inList::List{<:Option{<:ModelicaInteger}}, inAccum::ModelicaInteger = 1) ::ModelicaInteger
              local outResult::ModelicaInteger

              outResult = begin
                  local i::ModelicaInteger
                  local rest::List{Option{ModelicaInteger}}
                @match inList begin
                   nil()  => begin
                    inAccum
                  end

                  SOME(i) <| rest  => begin
                    mulListIntegerOpt(rest, i * inAccum)
                  end

                  NONE() <| rest  => begin
                    mulListIntegerOpt(rest, inAccum)
                  end
                end
              end
          outResult
        end

        StatefulBoolean = Array  #= A single boolean value that can be updated (a destructive operation). NOTE: Use Mutable<Boolean> instead. This implementation is kept since Susan cannot use that type. =#

         #= Create a boolean with state (that is, it is mutable) =#
        function makeStatefulBoolean(b::Bool) ::StatefulBoolean
              local sb::StatefulBoolean = arrayCreate(1, b)
          sb
        end

         #= Create a boolean with state (that is, it is mutable) =#
        function getStatefulBoolean(sb::StatefulBoolean) ::Bool
              local b::Bool = sb[1]
          b
        end

         #= Update the state of a mutable boolean =#
        function setStatefulBoolean(sb::StatefulBoolean, b::Bool)
              arrayUpdate(sb, 1, b)
        end

         #= Takes two options and a function to compare the type. =#
        function optionEqual(inOption1::Option{T1}, inOption2::Option{T2}, inFunc::CompareFunc)  where {T1, T2}
              local outEqual::Bool

              outEqual = begin
                  local val1::T1
                  local val2::T2
                @match (inOption1, inOption2) begin
                  (SOME(val1), SOME(val2))  => begin
                    inFunc(val1, val2)
                  end

                  (NONE(), NONE())  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          outEqual
        end

         #= Returns the value if the function call succeeds, otherwise the default =#
        function makeValueOrDefault(inFunc::FuncType, inArg::TI, inDefaultValue::TO)  where {TI, TO}
              local outValue::TO

              try
                outValue = inFunc(inArg)
              catch
                outValue = inDefaultValue
              end
          outValue
        end

         #= Escapes a String so that it can be used in xml =#
        function xmlEscape(s1::String) ::String
              local s2::String

              s2 = stringReplaceChar(s1, "&", "&amp;")
              s2 = stringReplaceChar(s2, "<", "&lt;")
              s2 = stringReplaceChar(s2, ">", "&gt;")
              s2 = stringReplaceChar(s2, "\\", "&quot;")
          s2
        end

         #= As strcmp, but has Boolean output as is expected by the sort function =#
        function strcmpBool(s1::String, s2::String) ::Bool
              local b::Bool = stringCompare(s1, s2) > 0
          b
        end

         #= @author: adrpo
          This function will append the first string to the second string =#
        function stringAppendReverse(str1::String, str2::String) ::String
              local str::String = stringAppend(str2, str1)
          str
        end

        function stringAppendNonEmpty(inString1::String, inString2::String) ::String
              local outString::String

              outString = begin
                @match inString2 begin
                  ""  => begin
                    inString2
                  end

                  _  => begin
                      stringAppend(inString1, inString2)
                  end
                end
              end
          outString
        end

        function getCurrentDateTime() ::DateTime
              local dt::DateTime

              local sec::ModelicaInteger
              local min::ModelicaInteger
              local hour::ModelicaInteger
              local mday::ModelicaInteger
              local mon::ModelicaInteger
              local year::ModelicaInteger

              (sec, min, hour, mday, mon, year) = System.getCurrentDateTime()
              dt = DATETIME(sec, min, hour, mday, mon, year)
          dt
        end

        function isSuccess(status::Status) ::Bool
              local bool::Bool

              bool = begin
                @match status begin
                  SUCCESS(__)  => begin
                    true
                  end

                  FAILURE(__)  => begin
                    false
                  end
                end
              end
          bool
        end

        function id(inValue::T)  where {T}
              local outValue::T = inValue
          outValue
        end

         #= Takes two lists of the same type and builds a string like x = val1, y = val2, ....
          Example: listThread({1,2,3},{4,5,6},'=',',') => 1=4, 2=5, 3=6 =#
        function buildMapStr(inLst1::List{<:String}, inLst2::List{<:String}, inMiddleDelimiter::String, inEndDelimiter::String) ::String
              local outStr::String

              outStr = begin
                  local ra::List{String}
                  local rb::List{String}
                  local fa::String
                  local fb::String
                  local md::String
                  local ed::String
                  local str::String
                @match (inLst1, inLst2, inMiddleDelimiter, inEndDelimiter) begin
                  ( nil(),  nil(), _, _)  => begin
                    ""
                  end

                  (fa <|  nil(), fb <|  nil(), md, _)  => begin
                      str = stringAppendList(list(fa, md, fb))
                    str
                  end

                  (fa <| ra, fb <| rb, md, ed)  => begin
                      str = buildMapStr(ra, rb, md, ed)
                      str = stringAppendList(list(fa, md, fb, ed, str))
                    str
                  end
                end
              end
          outStr
        end

         #= assoc(key,lst) => value, where lst is a tuple of (key,value) pairs.
          Does linear search using equality(). This means it is slow for large
          inputs (many elements or large elements); if you have large inputs, you
          should use a hash-table instead. =#
        function assoc(inKey::Key, inList::List{Tuple{Key, Val}})  where {Key, Val}
              local outValue::Val

              local k::Key
              local v::Val

              (k, v) = listHead(inList)
              outValue = if valueEq(inKey, k)
                    v
                  else
                    assoc(inKey, listRest(inList))
                  end
          outValue
        end

         #= {{1,2,3},{4,5},{6}} => {{1,4,6},{1,5,6},{2,4,6},...}.
          The output is a 2-dim list with lengths (len1*len2*...*lenN)) and N.

          This function screams WARNING I USE COMBINATORIAL EXPLOSION.
          So there are flags that limit the size of the set it works on. =#
        function allCombinations(lst::List{List{T}}, maxTotalSize::Option{ModelicaInteger}, info::SourceInfo)  where {T}
              local out::List{List{T}}

              out = begin
                  local sz::ModelicaInteger
                  local maxSz::ModelicaInteger
                @matchcontinue (lst, maxTotalSize, info) begin
                  (_, SOME(maxSz), _)  => begin
                      sz = intMul(listLength(lst), ListUtil.applyAndFold(lst, intMul, listLength, 1))
                      @match true = sz <= maxSz
                    allCombinations2(lst)
                  end

                  (_, NONE(), _)  => begin
                    allCombinations2(lst)
                  end

                  (_, SOME(_), _)  => begin
                    fail()
                  end
                end
              end
          out
        end

         #= {{1,2,3},{4,5},{6}} => {{1,4,6},{1,5,6},{2,4,6},...}.
          The output is a 2-dim list with lengths (len1*len2*...*lenN)) and N.

          This function screams WARNING I USE COMBINATORIAL EXPLOSION. =#
        function allCombinations2(ilst::List{List{T}})  where {T}
              local out::List{List{T}}

              out = begin
                  local x::List{T}
                  local lst::List{List{T}}
                @match ilst begin
                   nil()  => begin
                    nil
                  end

                  x <| lst  => begin
                      lst = allCombinations2(lst)
                      lst = allCombinations3(x, lst, nil)
                    lst
                  end
                end
              end
          out
        end

        function allCombinations3(ilst1::List{T}, ilst2::List{List{T}}, iacc::List{List{T}})  where {T}
              local out::List{List{T}}

              out = begin
                  local x::T
                  local lst1::List{T}
                  local lst2::List{List{T}}
                  local acc::List{List{T}}
                @match (ilst1, ilst2, iacc) begin
                  ( nil(), _, acc)  => begin
                    listReverse(acc)
                  end

                  (x <| lst1, lst2, acc)  => begin
                      acc = allCombinations4(x, lst2, acc)
                      acc = allCombinations3(lst1, lst2, acc)
                    acc
                  end
                end
              end
          out
        end

        function allCombinations4(x::T, ilst::List{List{T}}, iacc::List{List{T}})  where {T}
              local out::List{List{T}}

              out = begin
                  local l::List{T}
                  local lst::List{List{T}}
                  local acc::List{List{T}}
                @match (x, ilst, iacc) begin
                  (_,  nil(), acc)  => begin
                    list(x) <| acc
                  end

                  (_, l <|  nil(), acc)  => begin
                    x <| l <| acc
                  end

                  (_, l <| lst, acc)  => begin
                      acc = allCombinations4(x, lst, x <| l <| acc)
                    acc
                  end
                end
              end
          out
        end

         #= Returns 1 if the given boolean is true, otherwise 0. =#
        function boolInt(inBoolean::Bool) ::ModelicaInteger
              local outInteger::ModelicaInteger = if inBoolean
                    1
                  else
                    0
                  end
          outInteger
        end

         #= Returns true if the given integer is larger than 0, otherwise false. =#
        function intBool(inInteger::ModelicaInteger) ::Bool
              local outBoolean::Bool = inInteger > 0
          outBoolean
        end

         #= Converts a string to a boolean value. true and yes is converted to true,
          false and no is converted to false. The function is case-insensitive. =#
        function stringBool(inString::String) ::Bool
              local outBoolean::Bool

              outBoolean = stringBool2(System.tolower(inString))
          outBoolean
        end

         #= Helper function to stringBool. =#
        function stringBool2(inString::String) ::Bool
              local outBoolean::Bool

              outBoolean = begin
                @match inString begin
                  "true"  => begin
                    true
                  end

                  "false"  => begin
                    false
                  end

                  "yes"  => begin
                    true
                  end

                  "no"  => begin
                    false
                  end
                end
              end
          outBoolean
        end

        function stringEqCaseInsensitive(str1::String, str2::String) ::Bool
              local eq::Bool

              eq = stringEq(System.tolower(str1), System.tolower(str2))
          eq
        end

         #= SOME(a) => {a}
           NONE()  => {} =#
        function optionList(inOption::Option{T})  where {T}
              local outList::List{T}

              outList = begin
                  local value::T
                @match inOption begin
                  SOME(value)  => begin
                    list(value)
                  end

                  _  => begin
                      nil
                  end
                end
              end
          outList
        end

         #= Pads a string with the given padding so that the resulting string is as long
           as the given width. If the string is already longer nothing is done to it.
           Note that the length of the padding is assumed to be one, i.e. a single char. =#
        function stringPadRight(inString::String, inPadWidth::ModelicaInteger, inPadString::String) ::String
              local outString::String

              local pad_length::ModelicaInteger
              local pad_str::String

              pad_length = inPadWidth - stringLength(inString)
              if pad_length > 0
                pad_str = stringAppendList(list(inPadString for i in 1:pad_length))
                outString = inString + pad_str
              else
                outString = inString
              end
          outString
        end

         #= Pads a string with the given padding so that the resulting string is as long
           as the given width. If the string is already longer nothing is done to it.
           Note that the length of the padding is assumed to be one, i.e. a single char. =#
        function stringPadLeft(inString::String, inPadWidth::ModelicaInteger, inPadString::String) ::String
              local outString::String

              local pad_length::ModelicaInteger
              local pad_str::String

              pad_length = inPadWidth - stringLength(inString)
              if pad_length > 0
                pad_str = stringAppendList(list(inPadString for i in 1:pad_length))
                outString = pad_str + inString
              else
                outString = inString
              end
          outString
        end

         #= Returns all but the first character of a string. =#
        function stringRest(inString::String) ::String
              local outRest::String

              local len::ModelicaInteger

              len = stringLength(inString)
              outRest = substring(inString, 2, len)
          outRest
        end

        function intProduct(lst::List{<:ModelicaInteger}) ::ModelicaInteger
              local i::ModelicaInteger = ListUtil.fold(lst, intMul, 1)
          i
        end

         #= Given a positive integer, returns the closest prime number that is equal or
           larger. This algorithm checks every odd number larger than the given number
           until it finds a prime, but since the distance between primes is relatively
           small (the largest gap between primes up to 32 bit is only around 300) it's
           still reasonably fast. It's useful for e.g. determining a good size for a
           hash table with a known number of elements. =#
        function nextPrime(inN::ModelicaInteger) ::ModelicaInteger
              local outNextPrime::ModelicaInteger

              outNextPrime = if inN <= 2
                    2
                  else
                    nextPrime2(inN + intMod(inN + 1, 2))
                  end
          outNextPrime
        end

         #= Helper function to nextPrime2, does the actual work of finding the next
           prime. =#
        function nextPrime2(inN::ModelicaInteger) ::ModelicaInteger
              local outNextPrime::ModelicaInteger

              outNextPrime = if nextPrime_isPrime(inN)
                    inN
                  else
                    nextPrime2(inN + 2)
                  end
          outNextPrime
        end

         #= Helper function to nextPrime2, checks if a given number is a prime or not.
           Note that this function is not a general prime checker, it only works for
           positive odd numbers. =#
        function nextPrime_isPrime(inN::ModelicaInteger) ::Bool
              local outIsPrime::Bool

              local i::ModelicaInteger = 3
              local q::ModelicaInteger = intDiv(inN, 3)

               #=  Check all factors up to sqrt(inN)
               =#
              while q >= i
                if inN == q * i
                  outIsPrime = false
                  return outIsPrime
                end
                i = i + 2
                q = intDiv(inN, i)
              end
               #=  The number is divisible by a factor => not a prime.
               =#
               #=  All factors have been checked, inN is a prime.
               =#
              outIsPrime = true
          outIsPrime
        end

         #= Useful if you do not want to write an unparser =#
        function anyToEmptyString(a::T)  where {T}
              local empty::String = ""
          empty
        end

         @Uniontype TranslatableContent begin
              @Record gettext begin

                       msgid::String
              end

              @Record notrans begin

                       str::String
              end
         end

         #= Translate content to a string =#
        function translateContent(msg::TranslatableContent) ::String
              local str::String

              str = begin
                @match msg begin
                  gettext(str)  => begin
                      str = System.gettext(str)
                    str
                  end

                  notrans(str)  => begin
                    str
                  end
                end
              end
          str
        end

        function removeLast3Char(str::String) ::String
              local outStr::String

              outStr = substring(str, 1, stringLength(str) - 3)
          outStr
        end

        function removeLast4Char(str::String) ::String
              local outStr::String

              outStr = substring(str, 1, stringLength(str) - 4)
          outStr
        end

        function removeLastNChar(str::String, n::ModelicaInteger) ::String
              local outStr::String

              outStr = substring(str, 1, stringLength(str) - n)
          outStr
        end

        function stringNotEqual(str1::String, str2::String) ::Bool
              local b::Bool = ! stringEq(str1, str2)
          b
        end

        function swap(cond::Bool, in1::T, in2::T)  where {T}
              local out2::T
              local out1::T

              (out1, out2) = begin
                @match cond begin
                  true  => begin
                    (in2, in1)
                  end

                  _  => begin
                      (in1, in2)
                  end
                end
              end
          (out1, out2)
        end

        function replace(replaced::T, arg::T)  where {T}
              local outArg::T = arg
          outArg
        end

         #= Calculates the size of a Real range given the start, step and stop values. =#
        function realRangeSize(inStart::ModelicaReal, inStep::ModelicaReal, inStop::ModelicaReal) ::ModelicaInteger
              local outSize::ModelicaInteger

              outSize = integer(floor((inStop - inStart) / inStep + 5e-15)) + 1
              outSize = max(outSize, 0)
          outSize
        end

         #= Testsuite friendly name (start after testsuite/ or build/) =#
        function testsuiteFriendly(name::String) ::String
              local friendly::String

              friendly = testsuiteFriendly2(Config.getRunningTestsuite(), Config.getRunningWSMTestsuite(), name)
          friendly
        end

         #= Testsuite friendly name (start after testsuite/ or build/) =#
        function testsuiteFriendly2(cond::Bool, wsmTestsuite::Bool, name::String) ::String
              local friendly::String

              friendly = begin
                  local i::ModelicaInteger
                  local strs::List{String}
                  local newName::String
                @match (cond, wsmTestsuite) begin
                  (_, true)  => begin
                    System.basename(name)
                  end

                  (true, _)  => begin
                      newName = if Autoconf.os == "Windows_NT"
                            System.stringReplace(name, "\\\\", "/")
                          else
                            name
                          end
                      (i, strs) = System.regex(newName, "^(.*/Compiler/)?(.*/testsuite/)?(.*/lib/omlibrary/)?(.*/build/)?(.*)", 6, true, false)
                      friendly = listGet(strs, i)
                    friendly
                  end

                  _  => begin
                      name
                  end
                end
              end
          friendly
        end

         #= Adds ../ in front of a relative file path if we're running
           the testsuite, to compensate for tests being sandboxed.
           adrpo: only when running with partest the tests are sandboxed! =#
        function testsuiteFriendlyPath(inPath::String) ::String
              local outPath::String

              outPath = begin
                  local path::String
                @matchcontinue () begin
                  ()  => begin
                      @match true = Config.getRunningTestsuite()
                      @match false = System.directoryExists(inPath)
                      @match false = System.regularFileExists(inPath)
                      path = "../" + inPath
                      @match true = System.directoryExists(path) || System.regularFileExists(path)
                    path
                  end

                  _  => begin
                      inPath
                  end
                end
              end
               #=  we're running the testsuite
               =#
               #=  directory or file does not exist in this directory
               =#
               #=  prefix the path
               =#
          outPath
        end

        function createDirectoryTreeH(inString::String, parentDir::String, parentDirExists::Bool) ::Bool
              local outBool::Bool

              outBool = begin
                  local b::Bool
                @matchcontinue parentDirExists begin
                  _  => begin
                      @match true = stringEqual(parentDir, System.dirname(parentDir))
                      b = System.createDirectory(inString)
                    b
                  end

                  true  => begin
                      b = System.createDirectory(inString)
                    b
                  end

                  false  => begin
                      @match true = createDirectoryTree(parentDir)
                      b = System.createDirectory(inString)
                    b
                  end

                  _  => begin
                      false
                  end
                end
              end
          outBool
        end

        function createDirectoryTree(inString::String) ::Bool
              local outBool::Bool

              local parentDir::String
              local parentDirExists::Bool

              parentDir = System.dirname(inString)
              parentDirExists = System.directoryExists(parentDir)
              outBool = createDirectoryTreeH(inString, parentDir, parentDirExists)
          outBool
        end

         #= Rounds up to the nearest power of 2 =#
        function nextPowerOf2(i::ModelicaInteger) ::ModelicaInteger
              local v::ModelicaInteger

              v = i - 1
              v = intBitOr(v, intBitLShift(v, 1))
              v = intBitOr(v, intBitLShift(v, 2))
              v = intBitOr(v, intBitLShift(v, 4))
              v = intBitOr(v, intBitLShift(v, 8))
              v = intBitOr(v, intBitLShift(v, 16))
              v = v + 1
          v
        end

        function endsWith(inString::String, inSuffix::String) ::Bool
              local outEndsWith::Bool

              local start::ModelicaInteger
              local stop::ModelicaInteger
              local str_len::ModelicaInteger
              local suf_len::ModelicaInteger

              if inString == ""
                outEndsWith = false
              else
                str_len = stringLength(inString)
                suf_len = stringLength(inSuffix)
                start = if str_len > suf_len
                      str_len - suf_len + 1
                    else
                      1
                    end
                outEndsWith = inSuffix == substring(inString, start, str_len)
              end
          outEndsWith
        end

        function isCIdentifier(str::String) ::Bool
              local b::Bool

              local i::ModelicaInteger

              (i, _) = System.regex(str, "^[_A-Za-z][_A-Za-z0-9]*", 0, true, false)
              b = i == 1
          b
        end

         #= @author:adrpo
         if the string is bigger than len keep only until len
         if not, return the same string =#
        function stringTrunc(str::String, len::ModelicaInteger) ::String
              local truncatedStr::String

              truncatedStr = if stringLength(str) <= len
                    str
                  else
                    substring(str, 0, len)
                  end
          truncatedStr
        end

         #= Create an iterator or the like with a unique name =#
        function getTempVariableIndex() ::String
              local name::String

              name = stringAppend("tmpVar", intString(System.tmpTickIndex(Global.tmpVariableIndex)))
          name
        end

        function anyReturnTrue(a::T)  where {T}
              local b::Bool = true
          b
        end

         #= @author: adrpo
         returns the given path if it exists if not it considers it relative and returns that =#
        function absoluteOrRelative(inFileName::String) ::String
              local outFileName::String

              local pwd::String
              local pd::String

              pwd = System.pwd()
              pd = Autoconf.pathDelimiter
              outFileName = if System.regularFileExists(inFileName)
                    inFileName
                  else
                    stringAppendList(list(pwd, pd, inFileName))
                  end
          outFileName
        end

        function intLstString(lst::List{<:ModelicaInteger}) ::String
              local s::String

              s = stringDelimitList(ListUtil.map(lst, intString), ", ")
          s
        end

         #= Returns whether the given SourceInfo is empty or not. =#
        function sourceInfoIsEmpty(inInfo::SourceInfo) ::Bool
              local outIsEmpty::Bool

              outIsEmpty = begin
                @match inInfo begin
                  SOURCEINFO(fileName = "")  => begin
                    true
                  end

                  _  => begin
                      false
                  end
                end
              end
          outIsEmpty
        end

         #= Returns whether two SourceInfo are equal or not. =#
        function sourceInfoIsEqual(inInfo1::SourceInfo, inInfo2::SourceInfo) ::Bool
              local outIsEqual::Bool

              outIsEqual = begin
                @match (inInfo1, inInfo2) begin
                  (SOURCEINFO(__), SOURCEINFO(__))  => begin
                    inInfo1.fileName == inInfo2.fileName && inInfo1.isReadOnly == inInfo2.isReadOnly && inInfo1.lineNumberStart == inInfo2.lineNumberStart && inInfo1.columnNumberStart == inInfo2.columnNumberStart && inInfo1.lineNumberEnd == inInfo2.lineNumberEnd && inInfo1.columnNumberEnd == inInfo2.columnNumberEnd
                  end

                  _  => begin
                      false
                  end
                end
              end
          outIsEqual
        end

         #= /*************************************************
         * profiler stuff
         ************************************************/ =#

        function profilerinit()
              setGlobalRoot(Global.profilerTime1Index, 0.0)
              setGlobalRoot(Global.profilerTime2Index, 0.0)
              System.realtimeTick(ClockIndexes.RT_PROFILER0)
        end

        function profilerresults()
              local tg::ModelicaReal
              local t1::ModelicaReal
              local t2::ModelicaReal

              tg = System.realtimeTock(ClockIndexes.RT_PROFILER0)
              t1 = profilertime1()
              t2 = profilertime2()
              print("Time all: ")
              print(realString(tg))
              print("\\n")
              print("Time t1: ")
              print(realString(t1))
              print("\\n")
              print("Time t2: ")
              print(realString(t2))
              print("\\n")
              print("Time all-t1-t2: ")
              print(realString(realSub(realSub(tg, t1), t2)))
              print("\\n")
        end

        function profilertime1() ::ModelicaReal
              local t1::ModelicaReal

              t1 = getGlobalRoot(Global.profilerTime1Index)
          t1
        end

        function profilertime2() ::ModelicaReal
              local t2::ModelicaReal

              t2 = getGlobalRoot(Global.profilerTime2Index)
          t2
        end

        function profilerstart1()
              System.realtimeTick(ClockIndexes.RT_PROFILER1)
        end

        function profilerstart2()
              System.realtimeTick(ClockIndexes.RT_PROFILER2)
        end

        function profilerstop1()
              local t::ModelicaReal

              t = System.realtimeTock(ClockIndexes.RT_PROFILER1)
              setGlobalRoot(Global.profilerTime1Index, realAdd(getGlobalRoot(Global.profilerTime1Index), t))
        end

        function profilerstop2()
              local t::ModelicaReal

              t = System.realtimeTock(ClockIndexes.RT_PROFILER2)
              setGlobalRoot(Global.profilerTime2Index, realAdd(getGlobalRoot(Global.profilerTime2Index), t))
        end

        function profilerreset1()
              setGlobalRoot(Global.profilerTime1Index, 0.0)
        end

        function profilerreset2()
              setGlobalRoot(Global.profilerTime2Index, 0.0)
        end

        function profilertock1() ::ModelicaReal
              local t::ModelicaReal

              t = System.realtimeTock(ClockIndexes.RT_PROFILER1)
          t
        end

        function profilertock2() ::ModelicaReal
              local t::ModelicaReal

              t = System.realtimeTock(ClockIndexes.RT_PROFILER2)
          t
        end

        function applyTuple31(inTuple::Tuple{T1, T2, T3}, func::FuncT)  where {T1, T2, T3}
              local outTuple::Tuple{T1, T2, T3}

              local t1::T1
              local t1_new::T1
              local t2::T2
              local t3::T3

              (t1, t2, t3) = inTuple
              t1_new = func(t1)
              outTuple = if referenceEq(t1, t1_new)
                    inTuple
                  else
                    (t1_new, t2, t3)
                  end
          outTuple
        end

    #= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
    @exportAll()
  end

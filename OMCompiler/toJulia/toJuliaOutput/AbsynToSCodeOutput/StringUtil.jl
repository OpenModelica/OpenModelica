  module StringUtil


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

  import System

  import MetaModelica.Dangerous
  using MetaModelica.Dangerous

         NO_POS = 0::ModelicaInteger
         CHAR_NEWLINE = 10::ModelicaInteger
         CHAR_SPACE = 32::ModelicaInteger
         CHAR_DASH = 45::ModelicaInteger
         CHAR_DOT = 46::ModelicaInteger

         #= Searches for a given character in the given string, returning the index of
           the character if found. If not found returns NO_POS. The start and end
           position determines the section of the string to search in, and if not
           specified they are set to the start and end of the string. =#
        function findChar(inString::String, inChar::ModelicaInteger, inStartPos::ModelicaInteger, inEndPos::ModelicaInteger)::ModelicaInteger
              local outIndex::ModelicaInteger = NO_POS

              local len::ModelicaInteger = stringLength(inString)
              local start_pos::ModelicaInteger
              local end_pos::ModelicaInteger

              start_pos = max(inStartPos, 1)
              end_pos = if inEndPos > 0 min(inEndPos, len)
                  else
                  len
                  end
              for i in start_pos:end_pos
                if stringGetNoBoundsChecking(inString, i) == inChar
                  outIndex = i
                  break
                end
              end
          outIndex
        end

         #= Searches backwards for a given character in the given string, returning the
           index of the character if found. If not found returns NO_POS. The start and
           end position determines the section of the string to search in, and if not
           specified they are set to the start and end of the string. =#
        function rfindChar(inString::String, inChar::ModelicaInteger, inStartPos::ModelicaInteger, inEndPos::ModelicaInteger)::ModelicaInteger
              local outIndex::ModelicaInteger = NO_POS

              local len::ModelicaInteger = stringLength(inString)
              local start_pos::ModelicaInteger
              local end_pos::ModelicaInteger

              start_pos = if inStartPos > 0 min(inStartPos, len)
                  else
                  len
                  end
              end_pos = max(inEndPos, 1)
              for i in start_pos:(-1):end_pos
                if stringGetNoBoundsChecking(inString, i) == inChar
                  outIndex = i
                  break
                end
              end
          outIndex
        end

         #= Searches for a character not matching the given character in the given
           string, returning the index of the character if found. If not found returns
           NO_POS. The start and end position determines the section of the string to
           search in, and if not specified they are set to the start and end of the
           string. =#
        function findCharNot(inString::String, inChar::ModelicaInteger, inStartPos::ModelicaInteger, inEndPos::ModelicaInteger)::ModelicaInteger
              local outIndex::ModelicaInteger = NO_POS

              local len::ModelicaInteger = stringLength(inString)
              local start_pos::ModelicaInteger
              local end_pos::ModelicaInteger

              start_pos = max(inStartPos, 1)
              end_pos = if inEndPos > 0 min(inEndPos, len)
                  else
                  len
                  end
              for i in start_pos:end_pos
                if stringGetNoBoundsChecking(inString, i) != inChar
                  outIndex = i
                  break
                end
              end
          outIndex
        end

         #= Searches backwards for a character not matching the given character in the
           given string, returning the index of the character if found. If not found
           returns NO_POS. The start and end position determines the section of the
           string to search in, and if not specified they are set to the start and end
           of the string. =#
        function rfindCharNot(inString::String, inChar::ModelicaInteger, inStartPos::ModelicaInteger, inEndPos::ModelicaInteger)::ModelicaInteger
              local outIndex::ModelicaInteger = NO_POS

              local len::ModelicaInteger = stringLength(inString)
              local start_pos::ModelicaInteger
              local end_pos::ModelicaInteger

              start_pos = if inStartPos > 0 min(inStartPos, len)
                  else
                  len
                  end
              end_pos = max(inEndPos, 1)
              for i in start_pos:(-1):end_pos
                if stringGetNoBoundsChecking(inString, i) != inChar
                  outIndex = i
                  break
                end
              end
          outIndex
        end

         #= Returns true if the given character represented by it's ASCII decimal number
           is an alphabetic character. =#
        function isAlpha(inChar::ModelicaInteger)::Bool
              local outIsAlpha::Bool = inChar >= 65 && inChar <= 90 || inChar >= 97 && inChar <= 122
          outIsAlpha
        end

         #= Breaks the given string into lines which are no longer than the given wrap
           length. The function tries to break lines at word boundaries, i.e. at spaces,
           so that words are not split. It also wraps the string at any newline
           characters it finds. The function also takes two optional parameters to set
           the delimiter and raggedness.

           inDelimiter sets the delimiter which is prefixed to all lines except for the
           first one. The length of this delimiter is taken into account when wrapping
           the string, so it must be shorter than the wrap length. Otherwise the string
           will be returned unwrapped. The default is an empty string.

           inRaggedness determines the allowed raggedness of the lines, given as a ratio
           between 0 and 1. A raggedness of e.g. 0.2 means that each segment may be at
           most 20% smaller than the max line length. If a line would be shorter than
           this, due to a long word, then the function instead hyphenates the last word.
           This is not done according to any grammatical rules, the words are just
           broken so that the line is as long as allowed. The default is 0.3.

           This function operates on ASCII strings, and does not handle UTF-8 strings
           correctly. =#
        function wordWrap(inString::String, inWrapLength::ModelicaInteger, inDelimiter::String, inRaggedness::ModelicaReal)::List
              local outStrings::List = list()

              local start_pos::ModelicaInteger = 1
              local end_pos::ModelicaInteger = inWrapLength
              local line_len::ModelicaInteger
              local pos::ModelicaInteger
              local next_char::ModelicaInteger
              local char::ModelicaInteger
              local gap_size::ModelicaInteger
              local next_gap_size::ModelicaInteger
              local str::String
              local delim::String = ""
              local lines::List

               #=  Check that the wrap length is larger than the delimiter, otherwise just
               =#
               #=  return the string as it is.
               =#
              if stringLength(inDelimiter) >= inWrapLength - 1
                outStrings = list(inString)
                return outStrings
              end
               #=  Split the string at newlines.
               =#
              lines = System.strtok(inString, "\n")
               #=  Calculate the length of each line, excluding the delimiter.
               =#
              line_len = inWrapLength - stringLength(inDelimiter) - 1
               #=  The gap size is how many characters a line may be shorter than the sought
               =#
               #=  after line length.
               =#
              gap_size = max(realInt(realMul(line_len, inRaggedness)), 0)
               #=  Wrap each line separately.
               =#
              for line in lines
                while end_pos < stringLength(line)
                  next_char = stringGetNoBoundsChecking(line, end_pos + 1)
                  if next_char != CHAR_SPACE && next_char != CHAR_DASH
                    pos = rfindChar(line, CHAR_SPACE, end_pos, end_pos - gap_size)
                    if pos != NO_POS
                      str = substring(line, start_pos, pos - 1)
                      start_pos = pos + 1
                    else
                      pos = rfindChar(line, CHAR_DASH, end_pos, start_pos + gap_size)
                      if pos > 1
                        char = stringGetNoBoundsChecking(line, pos - 1)
                        pos = if isAlpha(char) && isAlpha(next_char) pos
                            else
                            NO_POS
                            end
                      end
                      if pos != NO_POS
                        str = substring(line, start_pos, pos)
                        start_pos = pos + 1
                      else
                        str = substring(line, start_pos, end_pos - 1) + "-"
                        start_pos = end_pos
                      end
                    end
                  else
                    str = substring(line, start_pos, end_pos)
                    start_pos = end_pos + (if next_char == CHAR_SPACE 2
                        else
                        1
                        end)
                  end
                  outStrings = delim + str <| outStrings
                  end_pos = start_pos + line_len
                  delim = inDelimiter
                end
                if start_pos < stringLength(line)
                  str = delim + substring(line, start_pos, stringLength(line))
                  outStrings = str <| outStrings
                end
                start_pos = 1
                end_pos = line_len
                delim = inDelimiter
              end
               #=  If the next character isn't a space or dash, search backwards for a space.
               =#
               #=  A space was found, break the string here.
               =#
               #=  No space was found, search for a dash instead.
               =#
               #=  A dash was found, check that the previous character is alphabetic.
               =#
               #=  A dash was found, break the string here.
               =#
               #=  No dash was found, break the word and hyphenate it.
               =#
               #=  The next character is a space or dash, split the string here.
               =#
               #=  Skip the space.
               =#
               #=  Add the string to the list and continue with the rest of the line.
               =#
               #=  Add any remainder of the line to the list.
               =#
               #=  Continue with the next line.
               =#
              outStrings = listReverseInPlace(outStrings)
          outStrings
        end

         #= Repeat str n times =#
        function repeat(str::String, n::ModelicaInteger)::String
              local res::String = ""

              local len::ModelicaInteger = stringLength(str)
              local ext::System.StringAllocator = System.StringAllocator(len * n)

              for i in 0:n - 1
                System.stringAllocatorStringCopy(ext, str, len * i)
              end
              res = System.stringAllocatorResult(ext, res)
          res
        end

         #= Adds quotation marks to the beginning and end of a string. =#
        function quoteBanan(inString::String)::String
              local outString::String = stringAppendList(list("\"", inString, "\""))
          outString
        end

        function equalIgnoreSpace(s1::String, s2::String)::Bool
              local b::Bool

              local j::ModelicaInteger = 1

              b = true
              for i in 1:stringLength(s1)
                if MetaModelica.Dangerous.stringGetNoBoundsChecking(s1, i) != stringCharInt(" ")
                  b = false
                  for j2 in j:stringLength(s2)
                    if MetaModelica.Dangerous.stringGetNoBoundsChecking(s2, j2) != stringCharInt(" ")
                      j = j2 + 1
                      b = true
                      break
                    end
                  end
                  if ! b
                    return b
                  end
                end
              end
              for j2 in j:stringLength(s2)
                if MetaModelica.Dangerous.stringGetNoBoundsChecking(s2, j2) != stringCharInt(" ")
                  b = false
                  return b
                end
              end
          b
        end

        function bytesToReadableUnit(bytes::ModelicaReal, significantDigits::ModelicaInteger, maxSizeInUnit #= If it is 1000, we print up to 1000GB before changing to X TB =#::ModelicaReal)::String
              local str::String

              local TB::ModelicaReal = 1024 ^ 4
              local GB::ModelicaReal = 1024 ^ 3
              local MB::ModelicaReal = 1024 ^ 2
              local kB::ModelicaReal = 1024

              if bytes > maxSizeInUnit * GB
                str = String(bytes / TB, significantDigits = significantDigits) + " TB"
              elseif bytes > maxSizeInUnit * MB
                str = String(bytes / GB, significantDigits = significantDigits) + " GB"
              elseif bytes > maxSizeInUnit * kB
                str = String(bytes / MB, significantDigits = significantDigits) + " MB"
              elseif bytes > maxSizeInUnit
                str = String(bytes / kB, significantDigits = significantDigits) + " kB"
              else
                str = String(integer(bytes))
              end
          str
        end

        function stringHashDjb2Work(str::String, hash::ModelicaInteger)::ModelicaInteger
              local ohash::ModelicaInteger = hash

              for i in 1:stringLength(str)
                ohash = ohash * 31 + MetaModelica.Dangerous.stringGetNoBoundsChecking(str, i)
              end
          ohash
        end

        function stringAppend9(str1, str2, str3, str4, str5, str6, str7, str8, str9::String)::String
              local str::String

              local sb::System.StringAllocator = System.StringAllocator(stringLength(str1) + stringLength(str2) + stringLength(str3) + stringLength(str4) + stringLength(str5) + stringLength(str6) + stringLength(str7) + stringLength(str8) + stringLength(str9))
              local c::ModelicaInteger = 0

              System.stringAllocatorStringCopy(sb, str1, c)
              c = c + stringLength(str1)
              System.stringAllocatorStringCopy(sb, str2, c)
              c = c + stringLength(str2)
              System.stringAllocatorStringCopy(sb, str3, c)
              c = c + stringLength(str3)
              System.stringAllocatorStringCopy(sb, str4, c)
              c = c + stringLength(str4)
              System.stringAllocatorStringCopy(sb, str5, c)
              c = c + stringLength(str5)
              System.stringAllocatorStringCopy(sb, str6, c)
              c = c + stringLength(str6)
              System.stringAllocatorStringCopy(sb, str7, c)
              c = c + stringLength(str7)
              System.stringAllocatorStringCopy(sb, str8, c)
              c = c + stringLength(str8)
              System.stringAllocatorStringCopy(sb, str9, c)
              c = c + stringLength(str9)
              str = System.stringAllocatorResult(sb, str1)
          str
        end

        function endsWithNewline(str::String)::Bool
              local b::Bool

              b = CHAR_NEWLINE == MetaModelica.Dangerous.stringGetNoBoundsChecking(str, stringLength(str))
          b
        end

  end

/*
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
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package StringUtil
" file:        StringUtil.mo
  package:     StringUtil
  description: String utility functions.


  This package contains various utility functions for handling the builtin
  MetaModelica String type."

protected import System;

protected import MetaModelica.Dangerous.{listReverseInPlace, stringGetNoBoundsChecking};

public
constant Integer NO_POS = 0;
constant Integer CHAR_NEWLINE = 10;
constant Integer CHAR_SPACE = 32;
constant Integer CHAR_DASH = 45;
constant Integer CHAR_DOT = 46;

constant String HEADLINE_1 = "################################################################################";
constant String HEADLINE_2 = "========================================";
constant String HEADLINE_3 = "----------------------------------------";
constant String HEADLINE_4 = "****************************************";

public function headline_1
  input String title;
  output String header;
algorithm
  header := HEADLINE_1 + "\n\n\t" + title + "\n\n" + HEADLINE_1 + "\n";
end headline_1;

public function headline_2
  input String title;
  output String header;
algorithm
  header := HEADLINE_2 + "\n" + title + "\n" + HEADLINE_2 + "\n";
end headline_2;

public function headline_3
  input String title;
  output String header;
algorithm
  header := title + "\n" + HEADLINE_3 + "\n";
end headline_3;

public function headline_4
  input String title;
  output String header;
algorithm
  header := title + "\n" + HEADLINE_4 + "\n";
end headline_4;

public function findChar
  "Searches for a given character in the given string, returning the index of
   the character if found. If not found returns NO_POS. The start and end
   position determines the section of the string to search in, and if not
   specified they are set to the start and end of the string."
  input String inString;
  input Integer inChar;
  input Integer inStartPos = 1;
  input Integer inEndPos = 0;
  output Integer outIndex = NO_POS;
protected
  constant Integer len = stringLength(inString);
  Integer start_pos, end_pos;
algorithm
  start_pos := max(inStartPos, 1);
  end_pos := if inEndPos > 0 then min(inEndPos, len) else len;

  for i in start_pos:end_pos loop
    if stringGetNoBoundsChecking(inString, i) == inChar then
      outIndex := i;
      break;
    end if;
  end for;
end findChar;

public function rfindChar
  "Searches backwards for a given character in the given string, returning the
   index of the character if found. If not found returns NO_POS. The start and
   end position determines the section of the string to search in, and if not
   specified they are set to the start and end of the string."
  input String inString;
  input Integer inChar;
  input Integer inStartPos = 0;
  input Integer inEndPos = 1;
  output Integer outIndex = NO_POS;
protected
  constant Integer len = stringLength(inString);
  Integer start_pos, end_pos;
algorithm
  start_pos := if inStartPos > 0 then min(inStartPos, len) else len;
  end_pos := max(inEndPos, 1);

  for i in start_pos:-1:end_pos loop
    if stringGetNoBoundsChecking(inString, i) == inChar then
      outIndex := i;
      break;
    end if;
  end for;
end rfindChar;

public function findCharNot
  "Searches for a character not matching the given character in the given
   string, returning the index of the character if found. If not found returns
   NO_POS. The start and end position determines the section of the string to
   search in, and if not specified they are set to the start and end of the
   string."
  input String inString;
  input Integer inChar;
  input Integer inStartPos = 1;
  input Integer inEndPos = 0;
  output Integer outIndex = NO_POS;
protected
  constant Integer len = stringLength(inString);
  Integer start_pos, end_pos;
algorithm
  start_pos := max(inStartPos, 1);
  end_pos := if inEndPos > 0 then min(inEndPos, len) else len;

  for i in start_pos:end_pos loop
    if stringGetNoBoundsChecking(inString, i) <> inChar then
      outIndex := i;
      break;
    end if;
  end for;
end findCharNot;

public function rfindCharNot
  "Searches backwards for a character not matching the given character in the
   given string, returning the index of the character if found. If not found
   returns NO_POS. The start and end position determines the section of the
   string to search in, and if not specified they are set to the start and end
   of the string."
  input String inString;
  input Integer inChar;
  input Integer inStartPos = 0;
  input Integer inEndPos = 1;
  output Integer outIndex = NO_POS;
protected
  constant Integer len = stringLength(inString);
  Integer start_pos, end_pos;
algorithm
  start_pos := if inStartPos > 0 then min(inStartPos, len) else len;
  end_pos := max(inEndPos, 1);

  for i in start_pos:-1:end_pos loop
    if stringGetNoBoundsChecking(inString, i) <> inChar then
      outIndex := i;
      break;
    end if;
  end for;
end rfindCharNot;

public function isAlpha
  "Returns true if the given character represented by it's ASCII decimal number
   is an alphabetic character."
  input Integer inChar;
  output Boolean outIsAlpha = (inChar >= 65 and inChar <= 90) or
                               (inChar >= 97 and inChar <= 122);
end isAlpha;

public function wordWrap
  "Breaks the given string into lines which are no longer than the given wrap
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
   correctly."
  input String inString;
  input Integer inWrapLength;
  input String inDelimiter = "";
  input Real inRaggedness = 0.3;
  output list<String> outStrings = {};
protected
  Integer start_pos = 1, end_pos = inWrapLength;
  Integer line_len, pos, next_char, char, gap_size, next_gap_size;
  String str, delim = "";
  list<String> lines;
algorithm
  // Check that the wrap length is larger than the delimiter, otherwise just
  // return the string as it is.
  if stringLength(inDelimiter) >= inWrapLength - 1 then
    outStrings := {inString};
    return;
  end if;

  // Split the string at newlines.
  lines := System.strtok(inString, "\n");
  // Calculate the length of each line, excluding the delimiter.
  line_len := inWrapLength - stringLength(inDelimiter) - 1;
  // The gap size is how many characters a line may be shorter than the sought
  // after line length.
  gap_size := max(realInt(realMul(line_len, inRaggedness)), 0);

  // Wrap each line separately.
  for line in lines loop
    while end_pos < stringLength(line) loop
      next_char := stringGetNoBoundsChecking(line, end_pos + 1);

      if next_char <> CHAR_SPACE and next_char <> CHAR_DASH then
        // If the next character isn't a space or dash, search backwards for a space.
        pos := rfindChar(line, CHAR_SPACE, end_pos, end_pos - gap_size);

        if pos <> NO_POS then
          // A space was found, break the string here.
          str := substring(line, start_pos, pos - 1);
          start_pos := pos + 1;
        else
          // No space was found, search for a dash instead.
          pos := rfindChar(line, CHAR_DASH, end_pos, start_pos + gap_size);

          if pos > 1 then
            // A dash was found, check that the previous character is alphabetic.
            char := stringGetNoBoundsChecking(line, pos - 1);
            pos := if isAlpha(char) and isAlpha(next_char) then pos else NO_POS;
          end if;

          if pos <> NO_POS then
            // A dash was found, break the string here.
            str := substring(line, start_pos, pos);
            start_pos := pos + 1;
          else
            // No dash was found, break the word and hyphenate it.
            str := substring(line, start_pos, end_pos - 1) + "-";
            start_pos := end_pos;
          end if;
        end if;
      else
        // The next character is a space or dash, split the string here.
        str := substring(line, start_pos, end_pos);
        // Skip the space.
        start_pos := end_pos + (if next_char == CHAR_SPACE then 2 else 1);
      end if;

      // Add the string to the list and continue with the rest of the line.
      outStrings := (delim + str) :: outStrings;
      end_pos := start_pos + line_len;
      delim := inDelimiter;
    end while;

    // Add any remainder of the line to the list.
    if start_pos < stringLength(line) then
      str := delim + substring(line, start_pos, stringLength(line));
      outStrings := str :: outStrings;
    end if;

    // Continue with the next line.
    start_pos := 1;
    end_pos := line_len;
    delim := inDelimiter;
  end for;

  outStrings := listReverseInPlace(outStrings);
end wordWrap;

function repeat
  "Repeat str n times"
  input String str;
  input Integer n;
  output String res="";
protected
  Integer len = stringLength(str);
  System.StringAllocator ext = System.StringAllocator(len*n);
algorithm
  for i in 0:n-1 loop
    System.stringAllocatorStringCopy(ext, str, len*i);
  end for;
  res := System.stringAllocatorResult(ext, res);
end repeat;

function quote
  "Adds quotation marks to the beginning and end of a string."
  input String inString;
  output String outString = stringAppendList({"\"", inString, "\""});
  annotation(__OpenModelica_EarlyInline = true);
end quote;

function equalIgnoreSpace
  input String s1;
  input String s2;
  output Boolean b;
protected
  Integer j=1;
algorithm
  b := true;
  for i in 1:stringLength(s1) loop
    if MetaModelica.Dangerous.stringGetNoBoundsChecking(s1, i) <> stringCharInt(" ") then
      b := false;
      for j2 in j:stringLength(s2) loop
        if MetaModelica.Dangerous.stringGetNoBoundsChecking(s2, j2) <> stringCharInt(" ") then
          j := j2+1;
          b := true;
          break;
        end if;
      end for;
      if not b then
        return;
      end if;
    end if;
  end for;
  for j2 in j:stringLength(s2) loop
    if MetaModelica.Dangerous.stringGetNoBoundsChecking(s2, j2) <> stringCharInt(" ") then
      b := false;
      return;
    end if;
  end for;
end equalIgnoreSpace;

function bytesToReadableUnit
  input Real bytes;
  input Integer significantDigits=4;
  input Real maxSizeInUnit=500 "If it is 1000, we print up to 1000GB before changing to X TB";
  output String str;
protected
  constant Real TB = 1024^4, GB=1024^3, MB=1024^2, kB=1024;
algorithm
  if bytes > maxSizeInUnit*GB then
    str := String(bytes/TB, significantDigits=significantDigits)+" TB";
  elseif bytes > maxSizeInUnit*MB then
    str := String(bytes/GB, significantDigits=significantDigits)+" GB";
  elseif bytes > maxSizeInUnit*kB then
    str := String(bytes/MB, significantDigits=significantDigits)+" MB";
  elseif bytes > maxSizeInUnit then
    str := String(bytes/kB, significantDigits=significantDigits)+" kB";
  else
    str := String(integer(bytes));
  end if;
end bytesToReadableUnit;

function stringHashDjb2Work
  input String str;
  input Integer hash=5381;
  output Integer ohash=hash;
algorithm
  for i in 1:stringLength(str) loop
    ohash := ohash*31 + MetaModelica.Dangerous.stringGetNoBoundsChecking(str, i);
  end for;
end stringHashDjb2Work;

function stringAppend9
  input String str1,str2,str3,str4="",str5="",str6="",str7="",str8="",str9="";
  output String str;
protected
  System.StringAllocator sb=System.StringAllocator(stringLength(str1)+stringLength(str2)+stringLength(str3)+stringLength(str4)+stringLength(str5)+stringLength(str6)+stringLength(str7)+stringLength(str8)+stringLength(str9));
  Integer c=0;
algorithm
  System.stringAllocatorStringCopy(sb, str1, c);
  c := c + stringLength(str1);
  System.stringAllocatorStringCopy(sb, str2, c);
  c := c + stringLength(str2);
  System.stringAllocatorStringCopy(sb, str3, c);
  c := c + stringLength(str3);
  System.stringAllocatorStringCopy(sb, str4, c);
  c := c + stringLength(str4);
  System.stringAllocatorStringCopy(sb, str5, c);
  c := c + stringLength(str5);
  System.stringAllocatorStringCopy(sb, str6, c);
  c := c + stringLength(str6);
  System.stringAllocatorStringCopy(sb, str7, c);
  c := c + stringLength(str7);
  System.stringAllocatorStringCopy(sb, str8, c);
  c := c + stringLength(str8);
  System.stringAllocatorStringCopy(sb, str9, c);
  c := c + stringLength(str9);
  str := System.stringAllocatorResult(sb,str1);
end stringAppend9;

function endsWithNewline
  input String str;
  output Boolean b;
algorithm
  b := CHAR_NEWLINE == MetaModelica.Dangerous.stringGetNoBoundsChecking(str, stringLength(str));
end endsWithNewline;

annotation(__OpenModelica_Interface="util");
end StringUtil;

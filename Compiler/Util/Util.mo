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

encapsulated package Util
" file:        Util.mo
  package:     Util
  description: Miscellanous MetaModelica Compiler (MMC) utilities


  This package contains various MetaModelica Compiler (MMC) utilities sigh, mostly
  related to lists.
  It is used pretty much everywhere. The difference between this
  module and the ModUtil module is that ModUtil contains modelica
  related utilities. The Util module only contains *low-level*
  MetaModelica Compiler (MMC) utilities, for example finding elements in lists.

  This modules contains many functions that use *type variables* in MetaModelica Compiler (MMC).
  A type variable is exactly what it sounds like, a type bound to a variable.
  It is used for higher order functions, i.e. in MetaModelica Compiler (MMC) the possibility to pass a
  \"pointer\" to a function into another function. But it can also be used for
  generic data types, like in  C++ templates.

  A type variable in MetaModelica Compiler (MMC) is written as:
  replaceable type TyVar subtypeof Any;
  For instance,
  function listFill
    replaceable type TyVar subtypeof Any;
    input TyVar in;
    input Integer i;
    output list<TyVar>
  ...
  end listFill;
  the type variable TyVar is here used as a generic type for the function listFill,
  which returns a list of n elements of a certain type."

public uniontype ReplacePattern
  record REPLACEPATTERN
    String from "from string (ie \".\"" ;
    String to "to string (ie \"$p\") ))" ;
  end REPLACEPATTERN;
end ReplacePattern;

public uniontype Status "Used to signal success or failure of a function call"
  record SUCCESS end SUCCESS;
  record FAILURE end FAILURE;
end Status;

public uniontype DateTime
  record DATETIME
    Integer sec;
    Integer min;
    Integer hour;
    Integer mday;
    Integer mon;
    Integer year;
  end DATETIME;
end DateTime;

protected
import Autoconf;
import ClockIndexes;
import Config;
import Error;
import Flags;
import Global;
import List;
import Print;
import System;

public constant SourceInfo dummyInfo = SOURCEINFO("",false,0,0,0,0,0.0);
public constant String derivativeNamePrefix="$DER";
public constant String pointStr = "$P";
public constant String leftBraketStr = "$lB";
public constant String rightBraketStr = "$rB";
public constant String leftParStr = "$lP";
public constant String rightParStr = "$rP";
public constant String commaStr = "$c";
public constant String appostrophStr = "$a";

protected constant list<ReplacePattern> replaceStringPatterns=
         {REPLACEPATTERN(".",pointStr),
          REPLACEPATTERN("[",leftBraketStr),REPLACEPATTERN("]",rightBraketStr),
          REPLACEPATTERN("(",leftParStr),REPLACEPATTERN(")",rightParStr),
          REPLACEPATTERN(",",commaStr),
          REPLACEPATTERN("'",appostrophStr)};

public function isIntGreater "Author: BZ"
  input Integer lhs;
  input Integer rhs;
  output Boolean b = lhs > rhs;
end isIntGreater;

public function isRealGreater "Author: BZ"
  input Real lhs;
  input Real rhs;
  output Boolean b = lhs > rhs;
end isRealGreater;

public function linuxDotSlash "If operating system is Linux/Unix, return a './', otherwise return empty string"
  output String str;
algorithm
  str := Autoconf.os;
  str := if str == "linux" or str == "OSX" then "./" else "";
end linuxDotSlash;

public function flagValue "author: x02lucpo
  Extracts the flagvalue from an argument list:
  flagValue('-s',{'-d','hej','-s','file'}) => 'file'"
  input String flag;
  input list<String> arguments;
  output String flagVal;
protected
  String arg;
  list<String> rest = arguments;
algorithm
  while not listEmpty(rest) loop
    arg :: rest := rest;

    if arg == flag then
      break;
    end if;
  end while;

  flagVal := if listEmpty(rest) then "" else listHead(rest);
end flagValue;

public function selectFirstNonEmptyString
  "Selects the first non-empty string from a list of strings.
   Returns an empty string if no such string exists."
  input list<String> inStrings;
  output String outResult;
algorithm
  for e in inStrings loop
    if e <> "" then
      outResult := e;
      return;
    end if;
  end for;
  outResult := "";
end selectFirstNonEmptyString;

public function compareTupleIntGt<T>
"  Function could used with List.sort to sort a
  List as list< tuple<Integer, Type_a> > by first argument.
  "
  input tuple<Integer, T> inTplA;
  input tuple<Integer, T> inTplB;
  output Boolean res;
protected
  Integer a,b;
algorithm
  (a, _) := inTplA;
  (b, _) := inTplB;
  res := intGt(a,b);
end compareTupleIntGt;

public function compareTupleIntLt<T>
"  Function could used with List.sort to sort a
  List as list< tuple<Integer, Type_a> > by first argument.
  "
  input tuple<Integer, T> inTplA;
  input tuple<Integer, T> inTplB;
  output Boolean res;
protected
  Integer a,b;
algorithm
  (a, _) := inTplA;
  (b, _) := inTplB;
  res := intLt(a,b);
end compareTupleIntLt;

public function compareTuple2IntGt<T>
"  Function could used with List.sort to sort a
  List as list< tuple<Type_a,Integer> > by second argument.
  "
  input tuple<T, Integer> inTplA;
  input tuple<T, Integer> inTplB;
  output Boolean res;
protected
  Integer a,b;
algorithm
  (_, a) := inTplA;
  (_, b) := inTplB;
  res := intGt(a,b);
end compareTuple2IntGt;

public function compareTuple2IntLt<T>
"  Function could used with List.sort to sort a
  List as list< tuple<Type_a,Integer> > by second argument.
  "
  input tuple<T, Integer> inTplA;
  input tuple<T, Integer> inTplB;
  output Boolean res;
protected
  Integer a,b;
algorithm
  (_, a) := inTplA;
  (_, b) := inTplB;
  res := intLt(a,b);
end compareTuple2IntLt;

public function tuple21<T1, T2>
  "Takes a tuple of two values and returns the first value.
   Example: tuple21(('a', 1)) => 'a'"
  input tuple<T1, T2> inTuple;
  output T1 outValue;
algorithm
  (outValue, _) := inTuple;
end tuple21;

public function tuple22<T1, T2>
  "Takes a tuple of two values and returns the second value.
   Example: tuple22(('a',1)) => 1"
  input tuple<T1, T2> inTuple;
  output T2 outValue;
algorithm
  (_, outValue) := inTuple;
end tuple22;

public function optTuple22<T1, T2>
  "Takes an option tuple of two values and returns the second value.
   Example: optTuple22(SOME('a',1)) => 1"
  input Option<tuple<T1, T2>> inTuple;
  output T2 outValue;
algorithm
  SOME((_, outValue)) := inTuple;
end optTuple22;

public function tuple312<T1, T2, T3>
  "Takes a tuple of three values and returns the tuple of the two first values.
   Example: tuple312(('a',1,2)) => ('a',1)"
  input tuple<T1, T2, T3> inTuple;
  output tuple<T1, T2> outTuple;
protected
  T1 e1;
  T2 e2;
algorithm
  (e1, e2, _) := inTuple;
  outTuple := (e1, e2);
end tuple312;

public function tuple31<T1, T2, T3>
  "Takes a tuple of three values and returns the first value.
   Example: tuple31(('a',1,2)) => 'a'"
  input tuple<T1, T2, T3> inValue;
  output T1 outValue;
algorithm
  (outValue, _, _) := inValue;
end tuple31;

public function tuple32<T1, T2, T3>
  "Takes a tuple of three values and returns the second value.
   Example: tuple32(('a',1,2)) => 1"
  input tuple<T1, T2, T3> inValue;
  output T2 outValue;
algorithm
  (_, outValue, _) := inValue;
end tuple32;

public function tuple33<T1, T2, T3>
  "Takes a tuple of three values and returns the first value.
   Example: tuple33(('a',1,2)) => 2"
  input tuple<T1, T2, T3> inValue;
  output T3 outValue;
algorithm
  (_, _, outValue) := inValue;
end tuple33;

public function tuple41<T1, T2, T3, T4>
  input tuple<T1, T2, T3, T4> inTuple;
  output T1 outValue;
algorithm
  (outValue, _, _, _) := inTuple;
end tuple41;

public function tuple42<T1, T2, T3, T4>
  input tuple<T1, T2, T3, T4> inTuple;
  output T2 outValue;
algorithm
  (_, outValue, _, _) := inTuple;
end tuple42;

public function tuple43<T1, T2, T3, T4>
  input tuple<T1, T2, T3, T4> inTuple;
  output T3 outValue;
algorithm
  (_, _, outValue, _) := inTuple;
end tuple43;

public function tuple44<T1, T2, T3, T4>
  input tuple<T1, T2, T3, T4> inTuple;
  output T4 outValue;
algorithm
  (_, _, _, outValue) := inTuple;
end tuple44;

public function tuple51<T1, T2, T3, T4, T5>
  input tuple<T1, T2, T3, T4, T5> inTuple;
  output T1 outValue;
algorithm
  (outValue, _, _, _, _) := inTuple;
end tuple51;

public function tuple52<T1, T2, T3, T4, T5>
  input tuple<T1, T2, T3, T4, T5> inTuple;
  output T2 outValue;
algorithm
  (_, outValue, _, _, _) := inTuple;
end tuple52;

public function tuple53<T1, T2, T3, T4, T5>
  input tuple<T1, T2, T3, T4, T5> inTuple;
  output T3 outValue;
algorithm
  (_, _, outValue, _, _) := inTuple;
end tuple53;

public function tuple54<T1, T2, T3, T4, T5>
  input tuple<T1, T2, T3, T4, T5> inTuple;
  output T4 outValue;
algorithm
  (_, _, _, outValue, _) := inTuple;
end tuple54;

public function tuple55<T1, T2, T3, T4, T5>
  input tuple<T1, T2, T3, T4, T5> inTuple;
  output T5 outValue;
algorithm
  (_, _, _, _, outValue) := inTuple;
end tuple55;

public function tuple61<T1, T2, T3, T4, T5, T6>
  input tuple<T1, T2, T3, T4, T5, T6> inTuple;
  output T1 outValue;
algorithm
  (outValue, _, _ ,_ ,_ ,_ ) := inTuple;
end tuple61;

public function tuple62<T1, T2, T3, T4, T5, T6>
  input tuple<T1, T2, T3, T4, T5, T6> inTuple;
  output T2 outValue;
algorithm
  (_, outValue, _ ,_ ,_ ,_ ) := inTuple;
end tuple62;

public function stringContainsChar "Returns true if a string contains a specified character"
  input String str;
  input String char;
  output Boolean res;
algorithm
  res := matchcontinue()
    case ()
      equation
        _::_::_ = stringSplitAtChar(str,char);
      then true;
    else false;
  end matchcontinue;
end stringContainsChar;

public function stringDelimitListPrintBuf "
Author: BZ, 2009-11
Same functionality as stringDelimitListPrint, but writes to print buffer instead of string variable.
Usefull for heavy string operations(causes malloc error on some models when generating init file).
"
  input list<String> inStringLst;
  input String inDelimiter;
algorithm
  _:=
  matchcontinue (inStringLst)
    local
      String f,delim,str1,str2,str;
      list<String> r;
    case {} then ();
    case {f} equation Print.printBuf(f); then ();
    case f :: r
      equation
        stringDelimitListPrintBuf(r, inDelimiter);
        Print.printBuf(f);
        Print.printBuf(inDelimiter);
      then
        ();
  end matchcontinue;
end stringDelimitListPrintBuf;

public function stringDelimitListAndSeparate "author: PA
  This function is similar to stringDelimitList, i.e it inserts string delimiters between
  consecutive strings in a list. But it also count the lists and inserts a second string delimiter
  when the counter is reached. This can be used when for instance outputting large lists of values
  and a newline is needed after ten or so items."
  input list<String> str;
  input String sep1;
  input String sep2;
  input Integer n;
  output String res;
protected
  Integer handle;
algorithm
  handle := Print.saveAndClearBuf();
  stringDelimitListAndSeparate2(str, sep1, sep2, n, 0);
  res := Print.getString();
  Print.restoreBuf(handle);
end stringDelimitListAndSeparate;

protected function stringDelimitListAndSeparate2 "author: PA
  Helper function to stringDelimitListAndSeparate"
  input list<String> inStringLst1;
  input String inString2;
  input String inString3;
  input Integer inInteger4;
  input Integer inInteger5;
algorithm
  _ := matchcontinue (inStringLst1,inString2,inString3,inInteger4,inInteger5)
    local
      String s,str1,str,f,sep1,sep2;
      list<String> r;
      Integer n,iter_1,iter;
    case ({},_,_,_,_) then ();  /* iterator */
    case ({s},_,_,_,_) equation
      Print.printBuf(s);
    then ();
    case ((f :: r),sep1,sep2,n,0)
      equation
        Print.printBuf(f);Print.printBuf(sep1);
        stringDelimitListAndSeparate2(r, sep1, sep2, n, 1) "special case for first element" ;
      then
        ();
    case ((f :: r),sep1,sep2,n,iter)
      equation
        0 = intMod(iter, n) "insert second delimiter" ;
        iter_1 = iter + 1;
        Print.printBuf(f);Print.printBuf(sep1);Print.printBuf(sep2);
        stringDelimitListAndSeparate2(r, sep1, sep2, n, iter_1);
      then
        ();
    case ((f :: r),sep1,sep2,n,iter)
      equation
        iter_1 = iter + 1 "not inserting second delimiter" ;
        Print.printBuf(f);Print.printBuf(sep1);
        stringDelimitListAndSeparate2(r, sep1, sep2, n, iter_1);
      then
        ();
    else
      equation
        print("- stringDelimitListAndSeparate2 failed\n");
      then
        fail();
  end matchcontinue;
end stringDelimitListAndSeparate2;

public function stringDelimitListNonEmptyElts "the string delimiter inserted between those elements that are not empty.
  Example: stringDelimitListNonEmptyElts({\"x\",\"\",\"z\"}, \", \") => \"x, z\""
  input list<String> lst;
  input String delim;
  output String str;
protected
  list<String> lst1;
algorithm
  lst1 := List.select(lst, isNotEmptyString);
  str := stringDelimitList(lst1, delim);
end stringDelimitListNonEmptyElts;

public  function mulStringDelimit2Int
" splits the input string at the delimiter string in list of strings and converts to integer list which is then summarized
  "
    input String inString;
    input String delim;
    output Integer i;
protected
  list<String> lst;
 list<Integer> lst2;
   algorithm
       lst:=stringSplitAtChar(inString,delim);
       lst2:=List.map(lst, stringInt);
       if not listEmpty(lst2) then
         i := List.fold(lst2,intMul,1);
       else
         i := 0;
       end if;
end mulStringDelimit2Int;

public function stringReplaceChar "Takes a string and two chars and replaces the first char with the second char:
  Example: string_replace_char(\"hej.b.c\",\".\",\"_\") => \"hej_b_c\"
  2007-11-26 BZ: Now it is possible to replace chars with emptychar, and
                 replace a char with a string
  Example: string_replace_char(\"hej.b.c\",\".\",\"_dot_\") => \"hej_dot_b_dot_c\"
  "
  input String inString1;
  input String inString2;
  input String inString3;
  output String outString;
algorithm
  outString := System.stringReplace(inString1, inString2, inString3);
end stringReplaceChar;

public function stringSplitAtChar "Takes a string and a char and split the string at the char returning the list of components.
  Example: stringSplitAtChar(\"hej.b.c\",\".\") => {\"hej,\"b\",\"c\"}"
  input String string;
  input String token;
  output list<String> strings = {};
protected
  Integer ch = stringCharInt(token);
  list<String> cur = {};
algorithm
  for c in stringListStringChar(string) loop
    if stringCharInt(c) == ch then
      strings := stringAppendList(listReverse(cur)) :: strings;
      cur := {};
    else
      cur := c :: cur;
    end if;
  end for;
  if not listEmpty(cur) then
    strings := stringAppendList(listReverse(cur)) :: strings;
  end if;
  strings := listReverse(strings);
end stringSplitAtChar;

public function modelicaStringToCStr " this replaces symbols that are illegal in C to legal symbols
 see replaceStringPatterns to see the format. (example: \".\" becomes \"$P\")
  author: x02lucpo

  NOTE: This function should not be used in OMC, since the OMC backend no longer
    uses stringified components. It is still used by MathCore though."
  input String str;
  input Boolean changeDerCall "if true, first change 'DER(v)' to $derivativev";
  output String res_str;
algorithm
  res_str := matchcontinue(str,changeDerCall)
    local String s;
    case(s,false) // BoschRexroth specifics
      equation
        false = Flags.getConfigBool(Flags.TRANSLATE_DAE_STRING);
        then
          s;
    case(_,false)
      equation
        res_str = "$"+ modelicaStringToCStr1(str, replaceStringPatterns);
        // debug_print("prefix$", res_str);
      then res_str;
    case(s,true) equation
      s = modelicaStringToCStr2(s);
    then s;
  end matchcontinue;
end modelicaStringToCStr;

protected function modelicaStringToCStr2 "help function to modelicaStringToCStr,
first  changes name 'der(v)' to $derivativev and 'pre(v)' to 'pre(v)' with applied rules for v"
  input String inDerName;
  output String outDerName;
algorithm
  outDerName := matchcontinue(inDerName)
    local
      String name, derName;
      list<String> names;

    case(derName) equation
      0 = System.strncmp(derName,"der(",4);
      // adrpo: 2009-09-08
      // the commented text: _::name::_ = listLast(System.strtok(derName,"()"));
      // is wrong as der(der(x)) ends up beeing translated to $der$der instead
      // of $der$der$x. Changed to the following 2 lines below!
      _::names = (System.strtok(derName,"()"));
      names = List.map1(names, modelicaStringToCStr, false);
      name = derivativeNamePrefix + stringAppendList(names);
    then name;
    case(derName) equation
      0 = System.strncmp(derName,"pre(",4);
      _::name::_= System.strtok(derName,"()");
      name = "pre(" + modelicaStringToCStr(name,false) + ")";
    then name;
    case(derName) then modelicaStringToCStr(derName,false);
  end matchcontinue;
end modelicaStringToCStr2;

protected function modelicaStringToCStr1 ""
  input String inString;
  input list<ReplacePattern> inReplacePatternLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString,inReplacePatternLst)
    local
      String str,str_1,res_str,from,to;
      list<ReplacePattern> res;
    case (str,{}) then str;
    case (str,(REPLACEPATTERN(from = from,to = to) :: res))
      equation
        str_1 = modelicaStringToCStr1(str, res);
        res_str = System.stringReplace(str_1, from, to);
      then
        res_str;
    else
      equation
        print("- Util.modelicaStringToCStr1 failed for str:"+inString+"\n");
      then
        fail();
  end matchcontinue;
end modelicaStringToCStr1;

public function cStrToModelicaString " this replaces symbols that have been replace to correct value for modelica string
 see replaceStringPatterns to see the format. (example: \"$p\" becomes \".\")
  author: x02lucpo

  NOTE: This function should not be used in OMC, since the OMC backend no longer
    uses stringified components. It is still used by MathCore though."
  input String str;
  output String res_str;
algorithm
  res_str := cStrToModelicaString1(str, replaceStringPatterns);
end cStrToModelicaString;

protected function cStrToModelicaString1
  input String inString;
  input list<ReplacePattern> inReplacePatternLst;
  output String outString;
algorithm
  outString := match (inString,inReplacePatternLst)
    local
      String str,str_1,res_str,from,to;
      list<ReplacePattern> res;
    case (str,{}) then str;
    case (str,(REPLACEPATTERN(from = from,to = to) :: res))
      equation
        str_1 = cStrToModelicaString1(str, res);
        res_str = System.stringReplace(str_1, to, from);
      then
        res_str;
  end match;
end cStrToModelicaString1;

public function boolOrList "Example:
    boolOrList({true,false,false})  => true
    boolOrList({false,false,false}) => false"
  input list<Boolean> inBooleanLst;
  output Boolean outBoolean = false;
algorithm
  for b in inBooleanLst loop
    if b then
      outBoolean := true;
      return;
    end if;
  end for;
end boolOrList;

public function boolAndList "Takes a list of boolean values and applies the boolean AND operator on the elements
  Example:
  boolAndList({}) => true
  boolAndList({true, true}) => true
  boolAndList({false,false,true}) => false"
  input list<Boolean> inBooleanLst;
  output Boolean outBoolean = true;
algorithm
  for b in inBooleanLst loop
    if not b then
      outBoolean := false;
      return;
    end if;
  end for;
end boolAndList;

public function applyOption<TI, TO>
  "Takes an option value and a function over the value. It returns in another
   option value, resulting from the application of the function on the value.

   Example:
     applyOption(SOME(1), intString) => SOME(\"1\")
     applyOption(NONE(),  intString) => NONE()
  "
  input Option<TI> inOption;
  input FuncType inFunc;
  output Option<TO> outOption;

  partial function FuncType
    input TI inValue;
    output TO outValue;
  end FuncType;
algorithm
  outOption := match(inOption)
    local
      TI ival;
      TO oval;

    case SOME(ival) then SOME(inFunc(ival));
    else NONE();
  end match;
end applyOption;

public function applyOption1<TI, TO, ArgT>
  "Like applyOption but takes an additional argument"
  input Option<TI> inOption;
  input FuncType inFunc;
  input ArgT inArg;
  output Option<TO> outOption;

  partial function FuncType
    input TI inValue;
    input ArgT inArg;
    output TO outValue;
  end FuncType;
algorithm
  outOption := match(inOption)
    local
      TI ival;
      TO oval;

    case SOME(ival) then SOME(inFunc(ival, inArg));
    else NONE();
  end match;
end applyOption1;

public function applyOptionOrDefault<TI, TO>
  "Takes an optional value, a function and an extra value. If the optional value
   is SOME, applies the function on that value and returns the result.
   Otherwise returns the extra value."
  input Option<TI> inValue;
  input FuncType inFunc;
  input TO inDefaultValue;
  output TO outValue;

  partial function FuncType
    input TI inValue;
    output TO outValue;
  end FuncType;
algorithm
  outValue := match(inValue)
    local
      TI value;
      TO res;

    case SOME(value) then inFunc(value);
    else inDefaultValue;
  end match;
end applyOptionOrDefault;

public function applyOptionOrDefault1<TI, TO, ArgT>
  "Takes an optional value, a function, an extra argument and an extra value.
   If the optional value is SOME, applies the function on that value and the
   extra argument and returns the result. Otherwise returns the extra value."
  input Option<TI> inValue;
  input FuncType inFunc;
  input ArgT inArg;
  input TO inDefaultValue;
  output TO outValue;

  partial function FuncType
    input TI inValue;
    input ArgT inArg;
    output TO outValue;
  end FuncType;
algorithm
  outValue := match(inValue)
    local
      TI value;
      TO res;

    case SOME(value) then inFunc(value, inArg);
    else inDefaultValue;
  end match;
end applyOptionOrDefault1;

public function applyOptionOrDefault2<TI, TO, ArgT1, ArgT2>
  "Takes an optional value, a function, two extra arguments and an extra value.
   If the optional value is SOME, applies the function on that value and the
   extra argument and returns the result. Otherwise returns the extra value."
  input Option<TI> inValue;
  input FuncType inFunc;
  input ArgT1 inArg1;
  input ArgT2 inArg2;
  input TO inDefaultValue;
  output TO outValue;

  partial function FuncType
    input TI inValue;
    input ArgT1 inArg1;
    input ArgT2 inArg2;
    output TO outValue;
  end FuncType;
algorithm
  outValue := match(inValue)
    local
      TI value;
      TO res;

    case SOME(value) then inFunc(value, inArg1, inArg2);
    else inDefaultValue;
  end match;
end applyOptionOrDefault2;

public function applyOption_2<T>
  input Option<T> inValue1;
  input Option<T> inValue2;
  input FuncType inFunc;
  output Option<T> outValue;

  partial function FuncType
    input T inValue1;
    input T inValue2;
    output T outValue;
  end FuncType;
algorithm
  outValue := match (inValue1, inValue2)
    case (NONE(), _) then inValue2;
    case (_, NONE()) then inValue1;
    else SOME(inFunc(getOption(inValue1), getOption(inValue2)));
  end match;
end applyOption_2;

public function makeOption<T>
  "Makes a value into value option, using SOME(value)"
  input T inValue;
  output Option<T> outOption = SOME(inValue);
  annotation(__OpenModelica_EarlyInline = true);
end makeOption;

public function makeOptionOnTrue<T>
  input Boolean inCondition;
  input T inValue;
  output Option<T> outOption = if inCondition then SOME(inValue) else NONE();
  annotation(__OpenModelica_EarlyInline = true);
end makeOptionOnTrue;

public function stringOption "author: PA
  Returns string value or empty string from string option."
  input Option<String> inStringOption;
  output String outString;
algorithm
  outString:= match(inStringOption)
    local
      String s;

    case SOME(s) then s;
    else "";
  end match;
end stringOption;

public function getOption<T>
  "Returns an option value if SOME, otherwise fails"
  input Option<T> inOption;
  output T outValue;
algorithm
  SOME(outValue) := inOption;
end getOption;

public function getOptionOrDefault<T>
  "Returns an option value if SOME, otherwise the default"
  input Option<T> inOption;
  input T inDefault;
  output T outValue;
algorithm
  outValue := match(inOption)
    local
      T value;

    case SOME(value) then value;
    else inDefault;
  end match;
end getOptionOrDefault;

public function intGreaterZero
  "Returns true if integer value is greater zero (> 0)"
  input Integer v;
  output Boolean res = v > 0;
end intGreaterZero;

public function intPositive
  "Returns true if integer value is positive (>= 0)"
  input Integer v;
  output Boolean res = v >= 0;
end intPositive;

public function intNegative
  "Returns true if integer value is negative (< 0)"
  input Integer v;
  output Boolean res = v < 0;
end intNegative;

public function intSign
  input Integer i;
  output Integer o = if i == 0 then 0 elseif i > 0 then 1 else -1;
end intSign;

public function intCompare
  "Compares two integers and return -1 if the first is smallest, 1 if the second
   is smallest, or 0 if they are equal."
  input Integer inN;
  input Integer inM;
  output Integer outResult = if inN == inM then 0 elseif inN > inM then 1 else -1;
end intCompare;

public function intPow
  "Performs integer exponentiation."
  input Integer base;
  input Integer exponent;
  output Integer result = 1;
algorithm
  if exponent >= 0 then
    for i in 1:exponent loop
      result := result * base;
    end for;
  else
    fail();
  end if;
end intPow;

public function realCompare
  "Compares two reals and return -1 if the first is smallest, 1 if the second
   is smallest, or 0 if they are equal."
  input Real inN;
  input Real inM;
  output Integer outResult = if inN == inM then 0 elseif inN > inM then 1 else -1;
end realCompare;

public function boolCompare
  "Compares two booleans and return -1 if the first is smallest, 1 if the second
   is smallest, or 0 if they are equal."
  input Boolean inN;
  input Boolean inM;
  output Integer outResult = if inN == inM then 0 elseif inN > inM then 1 else -1;
end boolCompare;

public function isNotEmptyString "Returns true if string is not the empty string."
  input String inString;
  output Boolean outIsNotEmpty = stringLength(inString) > 0;
end isNotEmptyString;

public function writeFileOrErrorMsg "This function tries to write to a file and if it fails then it
  outputs \"# Cannot write to file: <filename>.\" to errorBuf"
  input String inFilename;
  input String inString;
algorithm
  try
    System.writeFile(inFilename, inString);
  else
    Print.printErrorBuf("# Cannot write to file: " + inFilename + ".");
  end try;
end writeFileOrErrorMsg;

public function stringStartsWith
  input String inString1;
  input String inString2;
  output Boolean outEqual;
algorithm
  outEqual := (0 == System.strncmp(inString1, inString2, stringLength(inString1)));
end stringStartsWith;

public function strncmp "Compare two strings up to the nth character
  Returns true if they are equal."
  input String inString1;
  input String inString2;
  input Integer inLength;
  output Boolean outEqual;
algorithm
  outEqual := (0 == System.strncmp(inString1, inString2, inLength));
end strncmp;

public function notStrncmp
  "Compares two strings up to the nth character. Returns true if they are not
  equal."
  input String inString1;
  input String inString2;
  input Integer inLength;
  output Boolean outEqual;
algorithm
  outEqual := (0 <> System.strncmp(inString1, inString2, inLength));
end notStrncmp;

public function tickStr "author: PA
  Returns tick as a string, i.e. an unique number."
  output String s = intString(tick());
end tickStr;

public function replaceWindowsBackSlashWithPathDelimiter
"@author: adrpo
 replace \\ with path delimiter only in Windows!"
  input String inPath;
  output String outPath;
algorithm
  if Autoconf.os == "Windows_NT" then
    outPath := System.stringReplace(inPath, "\\", Autoconf.pathDelimiter);
  else
    outPath := inPath;
  end if;
end replaceWindowsBackSlashWithPathDelimiter;

public function getAbsoluteDirectoryAndFile "author: x02lucpo
  splits the filepath in directory and filename
  (\"c:\\programs\\file.mo\") => (\"c:\\programs\",\"file.mo\")
  (\"..\\work\\file.mo\") => (\"c:\\openmodelica123\\work\", \"file.mo\")"
  input String filename;
  output String dirname;
  output String basename;
protected
  String realpath;
algorithm
  realpath := System.realpath(filename);
  dirname := System.dirname(realpath);
  basename := System.basename(realpath);
  dirname := replaceWindowsBackSlashWithPathDelimiter(dirname);
end getAbsoluteDirectoryAndFile;

public function rawStringToInputString "author: x02lucpo
  replace the double-backslash with backslash"
  input String inString;
  output String outString;
algorithm
  outString := System.stringReplace(inString, "\\\"", "\"") "change backslash-double-quote to double-quote ";
  outString := System.stringReplace(outString, "\\\\", "\\") "double-backslash with backslash ";
end rawStringToInputString;

public function escapeModelicaStringToCString
  input String modelicaString;
  output String cString;
algorithm
  // C cannot handle newline in string constants
  cString := System.escapedString(modelicaString,true);
end escapeModelicaStringToCString;

public function escapeModelicaStringToXmlString
  input String modelicaString;
  output String xmlString;
algorithm
  // C cannot handle newline in string constants
  xmlString := System.stringReplace(modelicaString, "&", "&amp;");
  xmlString := System.stringReplace(xmlString, "\"", "&quot;");
  xmlString := System.stringReplace(xmlString, "<", "&lt;");
  xmlString := System.stringReplace(xmlString, ">", "&gt;");
  // TODO! FIXME!, we have issues with accented chars in comments
  // that end up in the Model_init.xml file and makes it not well
  // formed but the line below does not work if the xmlString is
  // already UTF-8. We should somehow detect the encoding.
  // xmlString := System.iconv(xmlString, "", "UTF-8");
end escapeModelicaStringToXmlString;

public function makeTuple<T1, T2>
  input T1 inValue1;
  input T2 inValue2;
  output tuple<T1, T2> outTuple = (inValue1, inValue2);
  annotation(__OpenModelica_EarlyInline = true);
end makeTuple;

public function makeTupleR<T1, T2>
  input T1 inValue1;
  input T2 inValue2;
  output tuple<T2, T1> outTuple = (inValue2, inValue1);
  annotation(__OpenModelica_EarlyInline = true);
end makeTupleR;

public function make3Tuple<T1, T2, T3>
  input T1 inValue1;
  input T2 inValue2;
  input T3 inValue3;
  output tuple<T1, T2, T3> outTuple = (inValue1, inValue2, inValue3);
  annotation(__OpenModelica_EarlyInline = true);
end make3Tuple;

public function mulListIntegerOpt
  input list<Option<Integer>> inList;
  input Integer inAccum = 1;
  output Integer outResult;
algorithm
  outResult := match(inList)
    local
      Integer i;
      list<Option<Integer>> rest;

    case {} then inAccum;
    case SOME(i) :: rest then mulListIntegerOpt(rest, i * inAccum);
    case NONE() :: rest then mulListIntegerOpt(rest, inAccum);
  end match;
end mulListIntegerOpt;

public type StatefulBoolean = array<Boolean> "A single boolean value that can be updated (a destructive operation). NOTE: Use Mutable<Boolean> instead. This implementation is kept since Susan cannot use that type.";

public function makeStatefulBoolean
"Create a boolean with state (that is, it is mutable)"
  input Boolean b;
  output StatefulBoolean sb = arrayCreate(1, b);
end makeStatefulBoolean;

public function getStatefulBoolean
"Create a boolean with state (that is, it is mutable)"
  input StatefulBoolean sb;
  output Boolean b = sb[1];
end getStatefulBoolean;

public function setStatefulBoolean
"Update the state of a mutable boolean"
  input StatefulBoolean sb;
  input Boolean b;
algorithm
  arrayUpdate(sb,1,b);
end setStatefulBoolean;

public function optionEqual<T1, T2>
  "Takes two options and a function to compare the type."
  input Option<T1> inOption1;
  input Option<T2> inOption2;
  input CompareFunc inFunc;
  output Boolean outEqual;

  partial function CompareFunc
    input T1 inValue1;
    input T2 inValue2;
    output Boolean outEqual;
  end CompareFunc;
algorithm
  outEqual := match(inOption1, inOption2)
    local
      T1 val1;
      T2 val2;

    case (SOME(val1), SOME(val2)) then inFunc(val1, val2);
    case (NONE(), NONE()) then true;
    else false;
  end match;
end optionEqual;

public function makeValueOrDefault<TI, TO>
  "Returns the value if the function call succeeds, otherwise the default"
  input FuncType inFunc;
  input TI inArg;
  input TO inDefaultValue;
  output TO outValue;

  partial function FuncType
    input TI inValue;
    output TO outValue;
  end FuncType;
algorithm
  try
    outValue := inFunc(inArg);
  else
    outValue := inDefaultValue;
  end try;
end makeValueOrDefault;

public function xmlEscape "Escapes a String so that it can be used in xml"
  input String s1;
  output String s2;
algorithm
  s2 := stringReplaceChar(s1,"&","&amp;");
  s2 := stringReplaceChar(s2,"<","&lt;");
  s2 := stringReplaceChar(s2,">","&gt;");
  s2 := stringReplaceChar(s2,"\"","&quot;");
end xmlEscape;

public function strcmpBool
  "As strcmp, but has Boolean output as is expected by the sort function"
  input String s1;
  input String s2;
  output Boolean b = stringCompare(s1, s2) > 0;
end strcmpBool;

public function stringAppendReverse
  "@author: adrpo
  This function will append the first string to the second string"
  input String str1;
  input String str2;
  output String str = stringAppend(str2, str1);
end stringAppendReverse;

public function stringAppendNonEmpty
  input String inString1;
  input String inString2;
  output String outString;
algorithm
  outString := match(inString2)
    case "" then inString2;
    else stringAppend(inString1, inString2);
  end match;
end stringAppendNonEmpty;

public function getCurrentDateTime
  output DateTime dt;
protected
  Integer sec;
  Integer min;
  Integer hour;
  Integer mday;
  Integer mon;
  Integer year;
algorithm
  (sec,min,hour,mday,mon,year) := System.getCurrentDateTime();
  dt := DATETIME(sec,min,hour,mday,mon,year);
end getCurrentDateTime;

public function isSuccess
  input Status status;
  output Boolean bool;
algorithm
  bool := match status
    case SUCCESS() then true;
    case FAILURE() then false;
  end match;
end isSuccess;

public function id<T>
  input T inValue;
  output T outValue = inValue;
end id;

public function buildMapStr "Takes two lists of the same type and builds a string like x = val1, y = val2, ....
  Example: listThread({1,2,3},{4,5,6},'=',',') => 1=4, 2=5, 3=6"
  input list<String> inLst1;
  input list<String> inLst2;
  input String inMiddleDelimiter;
  input String inEndDelimiter;
  output String outStr;
algorithm
  outStr := match (inLst1, inLst2, inMiddleDelimiter, inEndDelimiter)
    local
      list<String> ra,rb;
      String fa,fb, md, ed, str;

    case ({}, {}, _, _) then "";

    case ({fa}, {fb}, md, _)
      equation
        str = stringAppendList({fa, md, fb});
      then
        str;

    case (fa :: ra, fb :: rb, md, ed)
      equation
        str = buildMapStr(ra, rb, md, ed);
        str = stringAppendList({fa, md, fb, ed, str});
      then
        str;

  end match;
end buildMapStr;

public function assoc<Key, Val>
  "assoc(key,lst) => value, where lst is a tuple of (key,value) pairs.
  Does linear search using equality(). This means it is slow for large
  inputs (many elements or large elements); if you have large inputs, you
  should use a hash-table instead."
  input Key inKey;
  input list<tuple<Key,Val>> inList;
  output Val outValue;
protected
  Key k;
  Val v;
algorithm
  (k, v) := listHead(inList);
  outValue := if valueEq(inKey, k) then v else assoc(inKey, listRest(inList));
end assoc;

public function allCombinations<T>
  "{{1,2,3},{4,5},{6}} => {{1,4,6},{1,5,6},{2,4,6},...}.
  The output is a 2-dim list with lengths (len1*len2*...*lenN)) and N.

  This function screams WARNING I USE COMBINATORIAL EXPLOSION.
  So there are flags that limit the size of the set it works on."
  input list<list<T>> lst;
  input Option<Integer> maxTotalSize;
  input SourceInfo info;
  output list<list<T>> out;
algorithm
  out := matchcontinue (lst,maxTotalSize,info)
    local
      Integer sz,maxSz;
    case (_,SOME(maxSz),_)
      equation
        sz = intMul(listLength(lst),List.applyAndFold(lst,intMul,listLength,1));
        true = (sz <= maxSz);
      then allCombinations2(lst);

    case (_,NONE(),_) then allCombinations2(lst);

    case (_,SOME(_),_)
      equation
        Error.addSourceMessage(Error.COMPILER_NOTIFICATION, {"Util.allCombinations failed because the input was too large"}, info);
      then fail();
  end matchcontinue;
end allCombinations;

protected function allCombinations2<T>
  "{{1,2,3},{4,5},{6}} => {{1,4,6},{1,5,6},{2,4,6},...}.
  The output is a 2-dim list with lengths (len1*len2*...*lenN)) and N.

  This function screams WARNING I USE COMBINATORIAL EXPLOSION."
  input list<list<T>> ilst;
  output list<list<T>> out;
algorithm
  out := match (ilst)
    local
      list<T> x;
      list<list<T>> lst;

    case {} then {};
    case (x::lst)
      equation
        lst = allCombinations2(lst);
        lst = allCombinations3(x, lst, {});
      then lst;
  end match;
end allCombinations2;

protected function allCombinations3<T>
  input list<T> ilst1;
  input list<list<T>> ilst2;
  input list<list<T>> iacc;
  output list<list<T>> out;
algorithm
  out := match (ilst1,ilst2,iacc)
    local
      T x;
      list<T> lst1;
      list<list<T>> lst2;
      list<list<T>> acc;


    case ({},_,acc) then listReverse(acc);
    case (x::lst1,lst2,acc)
      equation
        acc = allCombinations4(x, lst2, acc);
        acc = allCombinations3(lst1, lst2, acc);
      then acc;
  end match;
end allCombinations3;

protected function allCombinations4<T>
  input T x;
  input list<list<T>> ilst;
  input list<list<T>> iacc;
  output list<list<T>> out;
algorithm
  out := match (x,ilst,iacc)
    local
      list<T> l;
      list<list<T>> lst;
      list<list<T>> acc;

    case (_,{},acc) then {x}::acc;
    case (_,{l},acc) then (x::l)::acc;
    case (_,l::lst,acc)
      equation
        acc = allCombinations4(x, lst, (x::l)::acc);
      then acc;
  end match;
end allCombinations4;

public function boolInt
  "Returns 1 if the given boolean is true, otherwise 0."
  input Boolean inBoolean;
  output Integer outInteger = if inBoolean then 1 else 0;
end boolInt;

public function intBool
  "Returns true if the given integer is larger than 0, otherwise false."
  input Integer inInteger;
  output Boolean outBoolean = inInteger > 0;
end intBool;

public function stringBool
  "Converts a string to a boolean value. true and yes is converted to true,
  false and no is converted to false. The function is case-insensitive."
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := stringBool2(System.tolower(inString));
end stringBool;

protected function stringBool2
  "Helper function to stringBool."
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inString)
    case "true" then true;
    case "false" then false;
    case "yes" then true;
    case "no" then false;
  end match;
end stringBool2;

public function stringEqCaseInsensitive
  input String str1, str2;
  output Boolean eq;
algorithm
  eq := stringEq(System.tolower(str1), System.tolower(str2));
end stringEqCaseInsensitive;

public function optionList<T>
  "SOME(a) => {a}
   NONE()  => {}"
  input Option<T> inOption;
  output list<T> outList;
algorithm
  outList := match(inOption)
    local
      T value;

    case SOME(value) then {value};
    else {};
  end match;
end optionList;

public function stringPadRight
  "Pads a string with the given padding so that the resulting string is as long
   as the given width. If the string is already longer nothing is done to it.
   Note that the length of the padding is assumed to be one, i.e. a single char."
  input String inString;
  input Integer inPadWidth;
  input String inPadString;
  output String outString;
protected
  Integer pad_length;
  String pad_str;
algorithm
  pad_length := inPadWidth - stringLength(inString);

  if pad_length > 0 then
    pad_str := stringAppendList(list(inPadString for i in 1:pad_length));
    outString := inString + pad_str;
  else
    outString := inString;
  end if;
end stringPadRight;

public function stringPadLeft
  "Pads a string with the given padding so that the resulting string is as long
   as the given width. If the string is already longer nothing is done to it.
   Note that the length of the padding is assumed to be one, i.e. a single char."
  input String inString;
  input Integer inPadWidth;
  input String inPadString;
  output String outString;
protected
  Integer pad_length;
  String pad_str;
algorithm
  pad_length := inPadWidth - stringLength(inString);

  if pad_length > 0 then
    pad_str := stringAppendList(list(inPadString for i in 1:pad_length));
    outString := pad_str + inString;
  else
    outString := inString;
  end if;
end stringPadLeft;

public function stringRest
  "Returns all but the first character of a string."
  input String inString;
  output String outRest;
protected
  Integer len;
algorithm
  len := stringLength(inString);
  outRest := substring(inString, 2, len);
end stringRest;

public function intProduct
  input list<Integer> lst;
  output Integer i = List.fold(lst, intMul, 1);
end intProduct;

public function nextPrime
  "Given a positive integer, returns the closest prime number that is equal or
   larger. This algorithm checks every odd number larger than the given number
   until it finds a prime, but since the distance between primes is relatively
   small (the largest gap between primes up to 32 bit is only around 300) it's
   still reasonably fast. It's useful for e.g. determining a good size for a
   hash table with a known number of elements."
  input Integer inN;
  output Integer outNextPrime;
algorithm
  outNextPrime := if inN <= 2 then 2 else nextPrime2(inN + intMod(inN + 1, 2));
end nextPrime;

protected function nextPrime2
  "Helper function to nextPrime2, does the actual work of finding the next
   prime."
  input Integer inN;
  output Integer outNextPrime;
algorithm
  outNextPrime := if nextPrime_isPrime(inN) then inN else nextPrime2(inN + 2);
end nextPrime2;

protected function nextPrime_isPrime
  "Helper function to nextPrime2, checks if a given number is a prime or not.
   Note that this function is not a general prime checker, it only works for
   positive odd numbers."
  input Integer inN;
  output Boolean outIsPrime;
protected
  Integer i = 3, q = intDiv(inN, 3);
algorithm
  // Check all factors up to sqrt(inN)
  while q >= i loop
    // The number is divisible by a factor => not a prime.
    if inN == q * i then
      outIsPrime := false;
      return;
    end if;

    i := i + 2;
    q := intDiv(inN, i);
  end while;

  // All factors have been checked, inN is a prime.
  outIsPrime := true;
end nextPrime_isPrime;

public function anyToEmptyString<T> "Useful if you do not want to write an unparser"
  input T a;
  output String empty = "";
end anyToEmptyString;

public uniontype TranslatableContent
  record gettext "Used to mark messages as targets for translation"
    String msgid;
  end gettext;
  record notrans "String cannot be translated; used for too generic messages"
    String str;
  end notrans;
end TranslatableContent;

public function translateContent "Translate content to a string"
  input TranslatableContent msg;
  output String str;
algorithm
  str := match msg
    case gettext(str)
      equation
        str = System.gettext(str);
      then str;
    case notrans(str) then str;
  end match;
end translateContent;

public function removeLast3Char
  input String str;
  output String outStr;
algorithm
  outStr := substring(str,1,stringLength(str)-3);
end removeLast3Char;

public function removeLast4Char
  input String str;
  output String outStr;
algorithm
  outStr := substring(str,1,stringLength(str)-4);
end removeLast4Char;

public function removeLastNChar
  input String str;
  input Integer n;
  output String outStr;
algorithm
  outStr := substring(str,1,stringLength(str)-n);
end removeLastNChar;

public function stringNotEqual
  input String str1;
  input String str2;
  output Boolean b = not stringEq(str1,str2);
end stringNotEqual;

public function swap<T>
  input Boolean cond;
  input T in1;
  input T in2;
  output T out1;
  output T out2;
algorithm
  (out1,out2) := match (cond)
    case true then (in2, in1);
    else (in1, in2);
  end match;
end swap;

public function realRangeSize
  "Calculates the size of a Real range given the start, step and stop values."
  input Real inStart;
  input Real inStep;
  input Real inStop;
  output Integer outSize;
algorithm
  outSize := integer(floor(((inStop - inStart) / inStep) + 5e-15)) + 1;
  outSize := max(outSize, 0);
end realRangeSize;

public function testsuiteFriendly "Testsuite friendly name (start after testsuite/ or build/)"
  input String name;
  output String friendly;
algorithm
  friendly := testsuiteFriendly2(Config.getRunningTestsuite(),Config.getRunningWSMTestsuite(),name);
end testsuiteFriendly;

protected function testsuiteFriendly2
  "Testsuite friendly name (start after testsuite/ or build/)"
  input Boolean cond;
  input Boolean wsmTestsuite;
  input String name;
  output String friendly;
algorithm
  friendly := match (cond,wsmTestsuite)
    local
      Integer i;
      list<String> strs;
      String newName;

    case (_,true) then System.basename(name);

    case (true,_)
      algorithm
        newName := if Autoconf.os == "Windows_NT" then System.stringReplace(name, "\\", "/") else name;
        (i,strs) := System.regex(newName, "^(.*/Compiler/)?(.*/testsuite/)?(.*/lib/omlibrary/)?(.*/build/)?(.*)$", 6, true, false);
        friendly := listGet(strs,i);
      then
        friendly;

    else name;
  end match;
end testsuiteFriendly2;

public function testsuiteFriendlyPath
  "Adds ../ in front of a relative file path if we're running
   the testsuite, to compensate for tests being sandboxed.
   adrpo: only when running with partest the tests are sandboxed!"
  input String inPath;
  output String outPath;
algorithm
  outPath := matchcontinue()
    local
      String path;

    case ()
      equation
        // we're running the testsuite
        true = Config.getRunningTestsuite();
        // directory or file does not exist in this directory
        false = System.directoryExists(inPath);
        false = System.regularFileExists(inPath);
        // prefix the path
        path = "../" + inPath;
        true = System.directoryExists(path) or System.regularFileExists(path);
      then
        path;

    else inPath;
  end matchcontinue;
end testsuiteFriendlyPath;

protected function createDirectoryTreeH
  input String inString;
  input String parentDir;
  input Boolean parentDirExists;
  output Boolean outBool;
algorithm
  outBool := matchcontinue(parentDirExists)
    local
      Boolean b;

    case _
      equation
        true = stringEqual(parentDir, System.dirname(parentDir));
        b = System.createDirectory(inString);
      then b;

    case true
      equation
        b = System.createDirectory(inString);
    then b;

    case false
      equation
        true = createDirectoryTree(parentDir);
        b = System.createDirectory(inString);
      then b;

    else false;
  end matchcontinue;
end createDirectoryTreeH;

public function createDirectoryTree
  input String inString;
  output Boolean outBool;
protected
  String parentDir;
  Boolean parentDirExists;
algorithm
  parentDir := System.dirname(inString);
  parentDirExists := System.directoryExists(parentDir);
  outBool := createDirectoryTreeH(inString,parentDir,parentDirExists);
end createDirectoryTree;

public function nextPowerOf2
  "Rounds up to the nearest power of 2"
  input Integer i;
  output Integer v;
algorithm
  v := i - 1;
  v := intBitOr(v, intBitLShift(v, 1));
  v := intBitOr(v, intBitLShift(v, 2));
  v := intBitOr(v, intBitLShift(v, 4));
  v := intBitOr(v, intBitLShift(v, 8));
  v := intBitOr(v, intBitLShift(v, 16));
  v := v + 1;
end nextPowerOf2;

public function endsWith
  input String inString;
  input String inSuffix;
  output Boolean outEndsWith;
protected
  Integer start, stop, str_len, suf_len;
algorithm
  if inString == "" then
    outEndsWith := false;
  else
    str_len := stringLength(inString);
    suf_len := stringLength(inSuffix);
    start := if str_len > suf_len then str_len - suf_len + 1 else 1;
    outEndsWith := inSuffix == substring(inString, start, str_len);
  end if;
end endsWith;

public function isCIdentifier
  input String str;
  output Boolean b;
protected
  Integer i;
algorithm
  (i,_) := System.regex(str, "^[_A-Za-z][_A-Za-z0-9]*$", 0, true, false);
  b := i == 1;
end isCIdentifier;

public function stringTrunc
"@author:adrpo
 if the string is bigger than len keep only until len
 if not, return the same string"
  input String str;
  input Integer len;
  output String truncatedStr;
algorithm
  truncatedStr := if stringLength(str) <= len then str else substring(str, 0, len);
end stringTrunc;

public function getTempVariableIndex "Create an iterator or the like with a unique name"
  output String name;
algorithm
  name := stringAppend("$tmpVar",intString(System.tmpTickIndex(Global.tmpVariableIndex)));
end getTempVariableIndex;

public function anyReturnTrue<T>
  input T a;
  output Boolean b = true;
end anyReturnTrue;

public function absoluteOrRelative
"@author: adrpo
 returns the given path if it exists if not it considers it relative and returns that"
 input String inFileName;
 output String outFileName;
protected
 String pwd, pd;
algorithm
 pwd := System.pwd();
 pd := Autoconf.pathDelimiter;
 outFileName := if System.regularFileExists(inFileName)
                then inFileName
                else stringAppendList({pwd,pd,inFileName});
end absoluteOrRelative;

public function intLstString
  input list<Integer> lst;
  output String s;
algorithm
  s := stringDelimitList(List.map(lst,intString),", ");
end intLstString;

public function sourceInfoIsEmpty
  "Returns whether the given SourceInfo is empty or not."
  input SourceInfo inInfo;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match inInfo
    case SOURCEINFO(fileName = "") then true;
    else false;
  end match;
end sourceInfoIsEmpty;

public function sourceInfoIsEqual
  "Returns whether two SourceInfo are equal or not."
  input SourceInfo inInfo1;
  input SourceInfo inInfo2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match (inInfo1, inInfo2)
    case (SOURCEINFO(), SOURCEINFO())
      then inInfo1.fileName == inInfo2.fileName and
           inInfo1.isReadOnly == inInfo2.isReadOnly and
           inInfo1.lineNumberStart == inInfo2.lineNumberStart and
           inInfo1.columnNumberStart == inInfo2.columnNumberStart and
           inInfo1.lineNumberEnd == inInfo2.lineNumberEnd and
           inInfo1.columnNumberEnd == inInfo2.columnNumberEnd;

    else false;
  end match;
end sourceInfoIsEqual;

/*************************************************
 * profiler stuff
 ************************************************/
public

function profilerinit
algorithm
  setGlobalRoot(Global.profilerTime1Index, 0.0);
  setGlobalRoot(Global.profilerTime2Index, 0.0);
  System.realtimeTick(ClockIndexes.RT_PROFILER0);
end profilerinit;

function profilerresults
protected
   Real tg,t1,t2;
algorithm
  tg := System.realtimeTock(ClockIndexes.RT_PROFILER0);
  t1 := profilertime1();
  t2 := profilertime2();
  print("Time all: "); print(realString(tg)); print("\n");
  print("Time t1: "); print(realString(t1)); print("\n");
  print("Time t2: "); print(realString(t2)); print("\n");
  print("Time all-t1-t2: "); print(realString(realSub(realSub(tg,t1),t2))); print("\n");
end profilerresults;

function profilertime1
  output Real t1;
algorithm
  t1 := getGlobalRoot(Global.profilerTime1Index);
end profilertime1;

function profilertime2
  output Real t2;
algorithm
  t2 := getGlobalRoot(Global.profilerTime2Index);
end profilertime2;

function profilerstart1
algorithm
   System.realtimeTick(ClockIndexes.RT_PROFILER1);
end profilerstart1;

function profilerstart2
algorithm
   System.realtimeTick(ClockIndexes.RT_PROFILER2);
end profilerstart2;

function profilerstop1
protected
   Real t;
algorithm
   t := System.realtimeTock(ClockIndexes.RT_PROFILER1);
   setGlobalRoot(Global.profilerTime1Index,
     realAdd(getGlobalRoot(Global.profilerTime1Index),t));
end profilerstop1;

function profilerstop2
protected
   Real t;
algorithm
   t := System.realtimeTock(ClockIndexes.RT_PROFILER2);
   setGlobalRoot(Global.profilerTime2Index,
     realAdd(getGlobalRoot(Global.profilerTime2Index),t));
end profilerstop2;

function profilerreset1
algorithm
  setGlobalRoot(Global.profilerTime1Index, 0.0);
end profilerreset1;

function profilerreset2
algorithm
  setGlobalRoot(Global.profilerTime2Index, 0.0);
end profilerreset2;

function profilertock1
  output Real t;
algorithm
   t := System.realtimeTock(ClockIndexes.RT_PROFILER1);
end profilertock1;

function profilertock2
  output Real t;
algorithm
   t := System.realtimeTock(ClockIndexes.RT_PROFILER2);
end profilertock2;

annotation(__OpenModelica_Interface="util");
end Util;

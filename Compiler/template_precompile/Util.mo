/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�pings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package Util
" file:	       Util.mo
  package:     Util
  description: Part of Util.mo, to get rid off System for TemplCG...

  RCS: $Id: Util.mo 3875 2009-02-17 07:57:42Z adrpo $
"

public function stringReplaceChar "function stringReplaceChar
  Takes a string and two chars and replaces the first char with the second char:
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
  outString:=
  matchcontinue (inString1,inString2,inString3)
    local
      list<String> strList,resList;
      String res,str;
      String fromChar,toChar;
    case (str,fromChar,toChar)
      equation 
        strList = string_list_string_char(str);
        resList = stringReplaceChar2(strList, fromChar, toChar);
        res = string_char_list_string(resList);
      then
        res;
    case (strList,_,_)
      local String strList;
      equation 
        print("- Util.stringReplaceChar failed\n");
      then
        strList;
  end matchcontinue;
end stringReplaceChar;

protected function stringReplaceChar2
  input list<String> inStringLst1;
  input String inString2;
  input String inString3;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inStringLst1,inString2,inString3)
    local
      list<String> res,rest,strList, charList2;
      String firstChar,fromChar,toChar;
    case ({},_,_) then {}; 
    case ((firstChar :: rest),fromChar,"") // added special case for removal of char.
      equation 
        equality(firstChar = fromChar);
        res = stringReplaceChar2(rest, fromChar, "");
      then
        (res);
    case ((firstChar :: rest),fromChar,toChar)
      equation 
        equality(firstChar = fromChar);
        res = stringReplaceChar2(rest, fromChar, toChar);
        charList2 = string_list_string_char(toChar);
        res = listAppend(charList2,res);
      then
        res;
        
    case ((firstChar :: rest),fromChar,toChar)
      equation 
        failure(equality(firstChar = fromChar));
        res = stringReplaceChar2(rest, fromChar, toChar);
      then
        (firstChar :: res);
    case (strList,_,_)
      equation 
        print("- Util.stringReplaceChar2 failed\n");
      then
        strList;
  end matchcontinue;
end stringReplaceChar2;

public function stringSplitAtChar "function stringSplitAtChar
  Takes a string and a char and split the string at the char returning the list of components.
  Example: stringSplitAtChar(\"hej.b.c\",\".\") => {\"hej,\"b\",\"c\"}"
  input String inString1;
  input String inString2;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inString1,inString2)
    local
      list<String> chrList;
      list<String> stringList;
      String str,strList;
      String chr;
    case (str,chr)
      equation 
        chrList = string_list_string_char(str);
        stringList = stringSplitAtChar2(chrList, chr, {}) "listString(resList) => res" ;
      then
        stringList;
    case (strList,_) then {strList}; 
  end matchcontinue;
end stringSplitAtChar;

protected function stringSplitAtChar2
  input list<String> inStringLst1;
  input String inString2;
  input list<String> inStringLst3;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inStringLst1,inString2,inStringLst3)
    local
      list<String> chr_rest_1,chr_rest,chrList,rest,strList;
      String res;
      list<String> res_str;
      String firstChar,chr;
    case ({},_,chr_rest)
      equation 
        chr_rest_1 = listReverse(chr_rest);
        res = string_char_list_string(chr_rest_1);
      then
        {res};
    case ((firstChar :: rest),chr,chr_rest)
      equation 
        equality(firstChar = chr);
        chrList = listReverse(chr_rest) "this is needed because it returns the reversed list" ;
        res = string_char_list_string(chrList);
        res_str = stringSplitAtChar2(rest, chr, {});
      then
        (res :: res_str);
    case ((firstChar :: rest),chr,chr_rest)
      local list<String> res;
      equation 
        failure(equality(firstChar = chr));
        res = stringSplitAtChar2(rest, chr, (firstChar :: chr_rest));
      then
        res;
    case (strList,_,_)
      equation 
        print("- Util.stringSplitAtChar2 failed\n");
      then
        fail();
  end matchcontinue;
end stringSplitAtChar2;

public function listFirst "function: listFirst 
  Returns the first element of a list
  Example: listFirst({3,5,7,11,13}) => 3"
  input list<Type_a> inTypeALst;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeA:= listNth(inTypeALst, 0);
end listFirst;

public function listMap "function: listMap
  Takes a list and a function over the elements of the lists, which is applied
  for each element, producing a new list.
  Example: listMap({1,2,3}, intString) => { \"1\", \"2\", \"3\"}"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  output list<Type_b> outTypeBLst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
algorithm 
  /* Fastest impl. on large lists, 10M elts takes about 3 seconds */
  outTypeBLst := listMap_impl_2(inTypeALst,{},inFuncTypeTypeAToTypeB);  
end listMap;

function listMap_impl_2 
"@author adrpo
 this will work in O(2n) due to listReverse"
  replaceable type TypeA subtypeof Any;
  replaceable type TypeB subtypeof Any;
  input  list<TypeA> inLst;
  input  list<TypeB> accumulator;
  input  FuncTypeTypeVarToTypeVar fn;  
  output list<TypeB> outLst;
  partial function FuncTypeTypeVarToTypeVar
    input TypeA inTypeA;
    output TypeB outTypeB;
    replaceable type TypeA subtypeof Any;
    replaceable type TypeB subtypeof Any;
  end FuncTypeTypeVarToTypeVar;
algorithm
  outLst := matchcontinue(inLst, accumulator, fn)
    local
      TypeA hd;
      TypeB hdChanged;
      list<TypeA> rest;
      list<TypeB> l, result;
    case ({}, l, _) then listReverse(l);
    case (hd::rest, l, fn)
      equation
        hdChanged = fn(hd);
        l = hdChanged::l;
        result = listMap_impl_2(rest, l, fn);
    then 
        result;
  end matchcontinue;
end listMap_impl_2;

public function if_ "function: if_
  Takes a boolean and two values.
  Returns the first value (second argument) if the boolean value is 
  true, otherwise the second value (third argument) is returned.
  Example: if_(true,\"a\",\"b\") => \"a\"
"
  input Boolean inBoolean1;
  input Type_a inTypeA2;
  input Type_a inTypeA3;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeA:=
  matchcontinue (inBoolean1,inTypeA2,inTypeA3)
    local Type_a r;
    case (true,r,_) then r; 
    case (false,_,r) then r; 
  end matchcontinue;
end if_;

end Util;


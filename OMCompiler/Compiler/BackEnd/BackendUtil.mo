/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2019, Open Source Modelica Consortium (OSMC),
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

encapsulated package BackendUtil
" file:        BackendUtil.mo
  package:     BackendUtil
  description: Miscellanous MetaModelica Compiler (MMC) utilities used by the backend."

protected

import List;
import System;
import DAE;

uniontype ReplacePattern
  record REPLACEPATTERN
    String from "from string (ie \".\"" ;
    String to "to string (ie \"$p\") ))" ;
  end REPLACEPATTERN;
end ReplacePattern;

constant list<ReplacePattern> replaceStringPatterns =
         {REPLACEPATTERN(".",pointStr),
          REPLACEPATTERN("[",leftBraketStr),REPLACEPATTERN("]",rightBraketStr),
          REPLACEPATTERN("(",leftParStr),REPLACEPATTERN(")",rightParStr),
          REPLACEPATTERN(",",commaStr),
          REPLACEPATTERN("'",appostrophStr)};

constant String pointStr = "$P";
constant String leftBraketStr = "$lB";
constant String rightBraketStr = "$rB";
constant String leftParStr = "$lP";
constant String rightParStr = "$rP";
constant String commaStr = "$c";
constant String appostrophStr = "$a";

public

function modelicaStringToCStr " this replaces symbols that are illegal in C to legal symbols
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

protected

function modelicaStringToCStr1 ""
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
        print(getInstanceName() + " failed for str:"+inString+"\n");
      then
        fail();
  end matchcontinue;
end modelicaStringToCStr1;

function modelicaStringToCStr2 "help function to modelicaStringToCStr,
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
      name = DAE.derivativeNamePrefix + stringAppendList(names);
    then name;
    case(derName) equation
      0 = System.strncmp(derName,"pre(",4);
      _::name::_= System.strtok(derName,"()");
      name = "pre(" + modelicaStringToCStr(name,false) + ")";
    then name;
    case(derName) then modelicaStringToCStr(derName,false);
  end matchcontinue;
end modelicaStringToCStr2;


annotation(__OpenModelica_Interface="backend");
end BackendUtil;

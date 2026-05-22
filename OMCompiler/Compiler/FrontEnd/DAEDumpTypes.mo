/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package DAEDumpTypes
" file:        DAEDumpTypes.mo
  package:     DAEDumpTypes
  description: DAEDumpTypes output


  This module implements functions to print the DAE AST."

import DAE;
import SCode;

protected
import SCodeDump;
import SCodeUtil;

public uniontype splitElements
  record SPLIT_ELEMENTS
    list<DAE.Element> v;
    list<DAE.Element> ie;
    list<DAE.Element> ia;
    list<DAE.Element> e;
    list<DAE.Element> a;
    list<DAE.Element> co;
    list<DAE.Element> o;
    list<DAE.Element> ca;
    list<compWithSplitElements> sm;
  end SPLIT_ELEMENTS;
end splitElements;

public uniontype compWithSplitElements
  record COMP_WITH_SPLIT
    String name;
    splitElements spltElems;
    Option<SCode.Comment> comment;
  end COMP_WITH_SPLIT;
end compWithSplitElements;

public uniontype functionList
  record FUNCTION_LIST
    list<DAE.Function> funcs;
  end FUNCTION_LIST;
end functionList;

protected
import Config;
import System;

public

function dumpCommentStr
  "Dumps a comment to a string."
  input Option<SCode.Comment> inComment;
  output String outString;
algorithm
  outString := match(inComment)
    local
      String cmt;

    case SOME(SCode.COMMENT(comment = SOME(cmt)))
      algorithm
        cmt := System.escapedString(cmt,false);
      then stringAppendList({" \"", cmt, "\""});

    else "";

  end match;
end dumpCommentStr;

function dumpClassAnnotationStr
  input Option<SCode.Comment> inComment;
  output String outString;
algorithm
  outString := dumpAnnotationStr(inComment, "  ", ";\n");
end dumpClassAnnotationStr;

function dumpCommentAnnotationStr
  input Option<SCode.Comment> inComment;
  output String outString;
algorithm
  outString := match(inComment)
    case NONE() then "";
    else dumpCommentStr(inComment) + dumpCompAnnotationStr(inComment);
  end match;
end dumpCommentAnnotationStr;

function dumpCompAnnotationStr
  input Option<SCode.Comment> inComment;
  output String outString;
algorithm
  outString := dumpAnnotationStr(inComment, " ", "");
end dumpCompAnnotationStr;

protected function dumpAnnotationStr
  input Option<SCode.Comment> inComment;
  input String inPrefix;
  input String inSuffix;
  output String outString;
algorithm
  outString := matchcontinue(inComment, inPrefix, inSuffix)
    local
      String ann;
      SCode.Mod ann_mod;

    case (SOME(SCode.COMMENT(annotation_ = SOME(SCode.ANNOTATION(ann_mod)))), _, _)
      algorithm
        if Config.showAnnotations() then
          ann := inPrefix + "annotation" + SCodeDump.printModStr(ann_mod, SCodeDump.defaultOptions) + inSuffix;
        elseif Config.showStructuralAnnotations() then
          ann_mod := filterStructuralMods(ann_mod);

          if not SCodeUtil.isEmptyMod(ann_mod) then
            ann := inPrefix + "annotation" + SCodeDump.printModStr(ann_mod, SCodeDump.defaultOptions) + inSuffix;
          else
            ann := "";
          end if;
        else
          ann := "";
        end if;
      then
        ann;

    else "";

  end matchcontinue;
end dumpAnnotationStr;

public function filterStructuralMods
  input output SCode.Mod mod;
algorithm
  mod := SCodeUtil.filterSubMods(mod, filterStructuralMod);
end filterStructuralMods;

protected function filterStructuralMod
  input SCode.SubMod mod;
  output Boolean keep;
algorithm
  keep := match mod.ident
    case "Evaluate" then true;
    case "Inline" then true;
    case "LateInline" then true;
    case "derivative" then true;
    case "inverse" then true;
    case "smoothOrder" then true;
    case "InlineAfterIndexReduction" then true;
    case "GenerateEvents" then true;
    else false;
  end match;
end filterStructuralMod;

annotation(__OpenModelica_Interface="frontend_dump");
end DAEDumpTypes;

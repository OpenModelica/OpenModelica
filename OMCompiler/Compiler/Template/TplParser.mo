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
encapsulated package TplParser
"
  file:        TplParser.mo
  package:     TplParser
  description: Susan Parser

  $Id$
"

import Tpl;
import TplAbsyn;

protected
import BaseAvlTree;
import Debug;
import Flags;
import List;
import System;
//protected import Print;


protected constant Integer TabSpaces = 4;

package CacheTree "AvlTree for String to Integer. New implementation only used by the backend (until we get a new bootstrapping tarball)"
  extends BaseAvlTree;
  redeclare type Key = String;
  redeclare type Value = list<TplAbsyn.ASTDef>;
  redeclare function extends keyStr
  algorithm
    outString := inKey;
  end keyStr;
  redeclare function extends valueStr
  algorithm
    outString := "#OPAQUE#";
  end valueStr;
  redeclare function extends keyCompare
  algorithm
    outResult := stringCompare(inKey1, inKey2);
  end keyCompare;
annotation(__OpenModelica_Interface="util");
end CacheTree;

public
uniontype ParseInfo
  record PARSE_INFO
    String fileName;
    list<String> errors;
    Boolean wasFatalError;
  end PARSE_INFO;
end ParseInfo;

public
uniontype LineInfo
  record LINE_INFO
    ParseInfo parseInfo;
    Integer lineNumber;
    Integer lineLength;
    list<String> startOfLineChars;
  end LINE_INFO;
end LineInfo;


public function getPosition
  input list<String> inChars;
  input LineInfo inLineInfo;

  output Integer outLineNumber;
  output Integer outColumnNumber;
algorithm
  (outLineNumber,outColumnNumber)  :=
  match (inChars, inLineInfo)
    local
      list<String> chars;
      Integer lnum, llen, tillEnd;

    case (chars, LINE_INFO(lineNumber = lnum, lineLength = llen))
      equation
        tillEnd = charsTillEndOfLine(chars, 0);
      then (lnum, llen - tillEnd);
  end match;
end getPosition;


type LineColumnNumber = tuple<Integer,Integer>;
constant SourceInfo dummySourceInfo = TplAbsyn.dummySourceInfo;

public function captureStartPosition
  input list<String> inChars;
  input LineInfo inLineInfo;
  input Integer inColumnOffset;

  output LineColumnNumber outLineColumnNumber;
protected
  Integer line, col;
algorithm
  (line, col) := getPosition(inChars, inLineInfo);
  col := col - inColumnOffset;
  outLineColumnNumber  := (line, col);
end captureStartPosition;


//TODO: add correct TIME_STAMP
public function tplSourceInfo
  input LineColumnNumber inStartLineColumnNumber;
  input list<String>     inEndChars;
  input LineInfo         inEndLineInfo;

  output SourceInfo outSourceInfo;
algorithm
  outSourceInfo  :=
  match (inStartLineColumnNumber, inEndChars, inEndLineInfo)
    local
      Integer startL, startC, endL, endC;
      LineInfo endlinfo;
      String  fileName;

    case ( (startL, startC), _, endlinfo as LINE_INFO(parseInfo = PARSE_INFO(fileName = fileName)) )
      equation
        (endL, endC) = getPosition(inEndChars, endlinfo);
        outSourceInfo = SOURCEINFO(fileName, false, startL, startC, endL, endC, 0.0);
      then outSourceInfo;
  end match;
end tplSourceInfo;


public function startPositionFromExp
  input TplAbsyn.Expression inExpression;
  output LineColumnNumber outLineColumnNumber;
protected
  Integer line, col;
algorithm
  outLineColumnNumber :=  match inExpression
    local
      Integer startL, startC;
   case ((_, SOURCEINFO(lineNumberStart = startL, columnNumberStart = startC)))
     then ((startL, startC));
  end match;
end startPositionFromExp;


public function charsTillEndOfLine
  input list<String> inChars;
  input output Integer outCharsTillEnd;
protected
  Integer i;
algorithm
  for c in inChars loop
    i := stringCharInt(c);
    if (i == 10) or (i == 13) then return; end if;
    outCharsTillEnd := outCharsTillEnd + (if i == 9 then TabSpaces else 1); // \t counts as 4 spaces
  end for;
end charsTillEndOfLine;


public function makeStartLineInfo
  input list<String> inChars;
  input String inFileName;
  output LineInfo outLineInfo;
protected
  Integer llen;
algorithm
  llen := charsTillEndOfLine(inChars, 1);
  outLineInfo := LINE_INFO(PARSE_INFO(inFileName,{}, false), 1, llen, inChars);
end makeStartLineInfo;

public function printAndFailIfError
  input  LineInfo inLineInfo;
algorithm
  _ := match (inLineInfo)
    local
      list<String> errLst;

    case (LINE_INFO(parseInfo = PARSE_INFO(errors = {})))
        equation
          print("\nSusan parsing successful.\n");
        then ();

    case (LINE_INFO(parseInfo = PARSE_INFO(errors = errLst as (_::_))))
        equation
          print("\nSusan parse error(s):\n");
          print(stringDelimitList(listReverse(errLst), "\n"));
          print("\n");
        then fail();

  end match;
end printAndFailIfError;

public function parseError
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inErrMessage;
  input Boolean isFatal;

  output LineInfo outLineInfo;
algorithm
  outLineInfo := matchcontinue (inChars, inLineInfo, inErrMessage, isFatal)
    local
      list<String> chars, solchars, errLst;
      LineInfo linfo;
      String fname, errMsg, locStr;
      Integer lnum, llen, colnum;
      Boolean isfatal;

    case (chars, linfo as LINE_INFO( parseInfo = PARSE_INFO(fileName = fname, errors = errLst, wasFatalError = false),
                                     lineNumber = lnum, lineLength = llen, startOfLineChars = solchars
                           ), errMsg, isfatal)
      equation
        (_, colnum) = getPosition(chars, linfo);
        locStr = intString(lnum) + "." + intString(colnum);
        errMsg = fname + ":" + locStr + "-" + locStr + " Error:(parser)" + errMsg + "(col "+intString(colnum)+ ")";     //TplParser.mo:126.38-126.55 Error:
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.traceln("TplParser.parseError msg: " + errMsg);
        end if;
      then (LINE_INFO(PARSE_INFO(fname, errMsg :: errLst, isfatal), lnum,llen, solchars));

    case (_, linfo as LINE_INFO( parseInfo = PARSE_INFO(wasFatalError = true)), _, _)
       then (linfo);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- !!! TplParser.parseError failed.\n");
      then fail();

  end matchcontinue;
end parseError;


public function parseErrorPrevPosition
  input list<String> inCharsPrevPos;
  input LineInfo inLineInfoPrevPos;
  input LineInfo inLineInfo;
  input String inErrMessage;
  input Boolean isFatal;

  output LineInfo outLineInfo;
algorithm
  (outLineInfo) := matchcontinue (inCharsPrevPos, inLineInfoPrevPos, inLineInfo, inErrMessage, isFatal)
    local
      list<String> charspp, solchars, solcharspp;
      LineInfo  linfopp;
      String  errMsg;
      Integer lnum, llen, lnumpp, llenpp;
      Boolean isfatal;
      ParseInfo pinfo;

    case (charspp,
          LINE_INFO( lineNumber = lnumpp,
                     lineLength = llenpp,
                     startOfLineChars = solcharspp
                   ),
          LINE_INFO( parseInfo = pinfo,
                     lineNumber = lnum,
                     lineLength = llen,
                     startOfLineChars = solchars
                   ),
          errMsg, isfatal)
      equation
        linfopp = LINE_INFO(pinfo, lnumpp, llenpp, solcharspp);
        LINE_INFO(parseInfo = pinfo) = parseError(charspp, linfopp, errMsg, isfatal);
      then LINE_INFO(pinfo, lnum, llen,solchars);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- !!! TplParser.parseErrorPrevPosition failed.\n");
      then fail();

  end matchcontinue;
end parseErrorPrevPosition;

public function wasFatalError
  input LineInfo inLineInfo;
  output Boolean outWasError;
algorithm
  (outWasError) := match (inLineInfo)
    case (LINE_INFO( parseInfo = PARSE_INFO(wasFatalError = true)) )
      then true;

    else false;
  end match;
end wasFatalError;

public function mergeErrors
  input LineInfo inLineInfo;
  input LineInfo inLineInfoToAddErrorsFrom;
  output LineInfo outLineInfo;
algorithm
  (outLineInfo) := matchcontinue (inLineInfo, inLineInfoToAddErrorsFrom)
    local
      list<String>  solchars, errLst, errLstToAdd;
      String fname;
      Integer lnum, llen;
      Boolean wasFatalError, wasFatalErrorToAdd;

    case (LINE_INFO( parseInfo = PARSE_INFO(fileName = fname, errors = errLst, wasFatalError = wasFatalError),
                                     lineNumber = lnum, lineLength = llen, startOfLineChars = solchars
                           ),
          LINE_INFO(parseInfo = PARSE_INFO(errors = errLstToAdd ) ))
      equation
        errLst = listAppend(errLstToAdd, errLst); //error lists are in reversed order
        //let the fatal error state from the first, leading file, only add errors from the other file
        //wasFatalError = wasFatalError or wasFatalErrorToAdd;
      then (LINE_INFO(PARSE_INFO(fname, errLst, wasFatalError), lnum, llen, solchars));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- !!! TplParser.mergeErrors failed.\n");
      then fail();

  end matchcontinue;
end mergeErrors;


public function parseErrorPrevPositionOpt
  input list<String> inCharsPrevPos;
  input LineInfo inLineInfoPrevPos;
  input LineInfo inLineInfo;
  input Option<String> inErrMessage;
  input Boolean isFatal;

  output LineInfo outLineInfo;
algorithm
  (outLineInfo) := matchcontinue (inCharsPrevPos, inLineInfoPrevPos, inLineInfo, inErrMessage, isFatal)
    local
      list<String> charspp;
      LineInfo linfo, linfopp;
      String  errMsg;
      Boolean isfatal;


    case (_, _, linfo,NONE(), _)
      then (linfo);

    case (charspp, linfopp, linfo, SOME(errMsg), isfatal)
      equation
        (linfo) = parseErrorPrevPosition(charspp, linfopp, linfo, errMsg, isfatal);
      then (linfo);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- !!! TplParser.parseErrorPrevPositionOpt failed.\n");
      then fail();

  end matchcontinue;
end parseErrorPrevPositionOpt;

public function parseErrorPrevPositionOptInfoChars
  input LineInfo inLineInfoPrevPos;
  input LineInfo inLineInfo;
  input Option<String> inErrMessage;
  input Boolean isFatal;
  output LineInfo outLineInfo;
protected
  list<String> sol_chars;
algorithm
  LINE_INFO(startOfLineChars = sol_chars) := inLineInfoPrevPos;
  outLineInfo := parseErrorPrevPositionOpt(sol_chars, inLineInfoPrevPos,
    inLineInfo, inErrMessage, isFatal);
end parseErrorPrevPositionOptInfoChars;

public function expectChar
  input output list<String> chars;
  input output LineInfo lineInfo;
  input String inExpectedChar;
algorithm
  chars := match (chars)
    local
      list<String> rest;
      LineInfo linfo;
      String c;

    case (c :: rest)
      guard stringEq(c, inExpectedChar)
      then rest;

    case (_)
      equation
        // false = stringEq(c, ec));
        // or chars = {}
        (lineInfo) = parseError(chars, lineInfo, "Expected character '" + inExpectedChar + "' at the position.", false);
        //fprint(Flags.FAILTRACE, "???Expected character '" + ec + "'\n");
      then chars;
  end match;
end expectChar;

//intended to say error before the last interleave, but need
//TODO: remember the last position before interleave in the LINE_INFO
public function interleaveExpectChar
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inExpectedChar;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo, inExpectedChar)
    local
      list<String> chars;
      LineInfo linfo;
      String ec, c;

    case (chars, linfo, ec)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (c :: chars) = chars;
        true = stringEq(c, ec);
      then (chars, linfo);

    case (chars, linfo, ec)
      equation
        // false = stringEq( c, ec );
        // or chars = {}
        (linfo) = parseError(chars, linfo, "Expected character '" + ec + "' after the position.",false);
      then (chars, linfo);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("- !!! TplParser.interleaveExpectChar failed.\n");
      then fail();

  end matchcontinue;
end interleaveExpectChar;


public function takeKeywordChars
  input list<String> inChars;
  input list<String> inKeywordChars;

  output list<String> outChars;
algorithm
  (outChars) := match (inChars, inKeywordChars)
    local
      list<String> chars, kwchars;
      String c, kwc;

    case (c :: chars, kwc :: kwchars)
      equation
        true = stringEq(c, kwc);
      then takeKeywordChars(chars, kwchars);

    case (chars, {})
      then (chars);

  end match;
end takeKeywordChars;

public function isKeyword
  input list<String> inChars;
  input list<String> inKeywordChars;

  output list<String> outChars;
  output Boolean isKeyword;
algorithm
  (outChars, isKeyword) := matchcontinue (inChars, inKeywordChars)
    local
      list<String> chars, kwchars;

    case (chars, kwchars)
      equation
        chars = takeKeywordChars(chars, kwchars);
        afterKeyword(chars);
      then (chars, true);

    else (inChars, false);

  end matchcontinue;
end isKeyword;


public function interleaveExpectKeyWord
  input list<String> inChars;
  input LineInfo inLineInfo;
  input list<String> inKeywordChars;
  input Boolean isFatal;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo, inKeywordChars, isFatal)
    local
      list<String> chars, kwchars;
      LineInfo linfo;
      String kw;
      Boolean isfatal;

    case (chars, linfo, kwchars, _)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, true) = isKeyword(chars, kwchars);
      then (chars, linfo);

    case (chars, linfo, kwchars, isfatal)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (_, false) = isKeyword(chars, kwchars);
        kw = stringCharListString(kwchars);
        (linfo) = parseError(chars, linfo, "Expected keyword '" + kw + "' at the position.", isfatal);
      then (chars, linfo);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("- !!! TplParser.interleaveExpectKeyWord failed.\n");
      then fail();

  end matchcontinue;
end interleaveExpectKeyWord;

public function interleaveExpectEndOfFile
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;

    case (chars, linfo)
      equation
        ({}, linfo) = interleave(chars, linfo);
      then ({}, linfo);

    case (chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (linfo) = parseError(chars, linfo, "Expected end of file at the position.", false);
      then (chars, linfo);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("- !!! TplParser.interleaveExpectEndOfFile failed.\n");
      then fail();

  end matchcontinue;
end interleaveExpectEndOfFile;


public function openFile
  input  String inFile;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output Option<String> outErrorOpt;
algorithm
  (outChars, outLineInfo, outErrorOpt) := matchcontinue (inFile)
    local
      String file, src, errStr;
      list<String> chars;
      LineInfo linfo;

    case (file)
      equation
        true = System.regularFileExists(file);
        src = System.readFile(file);
        chars = stringListStringChar( src );
        linfo = makeStartLineInfo(chars, file);
      then (chars, linfo,NONE());

    case (file)
      equation
        false = System.regularFileExists(file);
        chars = {};
        linfo = makeStartLineInfo(chars, file);
        errStr = "No such file '" + file + "'.";
      then (chars, linfo, SOME(errStr));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse error - TplParser.openFile failed for file '" + inFile + "'.\n");
      then fail();

  end matchcontinue;
end openFile;


public function templPackageFromFile
  input String inFile;
  output TplAbsyn.TemplPackage outTemplPackage;
algorithm
  (outTemplPackage) := matchcontinue (inFile)
    local
      String  file;
      Option<String> errOpt;
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.TemplPackage tplPackage;
    case (file)
        equation
          (chars, linfo, errOpt) = openFile(file);
          linfo = parseErrorPrevPositionOpt(chars, linfo, linfo, errOpt, true);
          (chars, linfo, tplPackage) = templPackage(chars, linfo, CacheTree.Tree.EMPTY());
          (_, linfo) = interleaveExpectEndOfFile(chars, linfo);
          printAndFailIfError(linfo);
        then tplPackage;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse error - TplParser.templPackageFromFile failed for file '" + inFile + "'.\n");
      then fail();

  end matchcontinue;
end templPackageFromFile;


protected function typeviewDefsFromInterfaceFile
  input TplAbsyn.PathIdent interfaceName;
  input output list<TplAbsyn.ASTDef> astDefs;
  output LineInfo linfo;
  output Option<String> errOpt;
  input output CacheTree.Tree cachedDefs;
protected
  String file;
  list<String> chars;
  list<TplAbsyn.ASTDef> newAstDefs;
algorithm
  file := TplAbsyn.pathIdentString(interfaceName) + ".mo";
  try
    if CacheTree.hasKey(cachedDefs, file) then
      // Return cached result, because it's very slow if we don't...
      astDefs := listAppend(CacheTree.get(cachedDefs, file), astDefs);
      linfo := LINE_INFO(PARSE_INFO("cachedResult",{},false),0,0,{});
      errOpt := NONE();
      return;
    end if;
    (chars, linfo, errOpt) := openFile(file);
    (chars, linfo) := interleave(chars, linfo);
    (chars, linfo,_, newAstDefs) := interfacePackage(chars, linfo, {});
    (_, linfo) := interleaveExpectEndOfFile(chars, linfo);
    if Flags.isSet(Flags.FAILTRACE) then
      Debug.trace("Loaded interface file: "+file+"\n");
    end if;
    cachedDefs := CacheTree.add(cachedDefs, file, newAstDefs);
    astDefs := listAppend(newAstDefs, astDefs);
  else
    if Flags.isSet(Flags.FAILTRACE) then
      Debug.trace("Parse error - TplParser.typeviewDefsFromInterfaceFile "+file+" failed.\n");
    end if;
    fail();
  end try;
end typeviewDefsFromInterfaceFile;


protected function typeviewDefsFromTemplateFile
  input TplAbsyn.PathIdent packageName;
  input Boolean isUnqualifiedImport;
  input output list<TplAbsyn.ASTDef> astDefs;
  output LineInfo linfo;
  output Option<String> errOpt;
  input output CacheTree.Tree cachedDefs;
protected
  String file;
  list<String> chars;
  TplAbsyn.ASTDef newAstDef;
  TplAbsyn.TemplPackage tplPackage;
  list<tuple<TplAbsyn.Ident,TplAbsyn.TemplateDef>> templateDefs;
  list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> astTypes;
algorithm
  file := TplAbsyn.pathIdentString(packageName) + ".tpl";
  try
    if CacheTree.hasKey(cachedDefs, file) then
      // We cache everything. But we need to pass isUnqualifiedImport=true|false...
      {TplAbsyn.AST_DEF(_, _, astTypes)} := CacheTree.get(cachedDefs, file);
      astDefs := TplAbsyn.AST_DEF(packageName, isUnqualifiedImport, astTypes)::astDefs;
      linfo := LINE_INFO(PARSE_INFO("cachedResult",{},false),0,0,{});
      errOpt := NONE();
      return;
    end if;
    (chars, linfo, errOpt) := openFile(file);
    (chars, linfo, tplPackage, cachedDefs) := templPackage(chars, linfo, cachedDefs);
    (_, linfo) := interleaveExpectEndOfFile(chars, linfo);
    TplAbsyn.TEMPL_PACKAGE(templateDefs = templateDefs)
      := TplAbsyn.fullyQualifyTemplatePackage(tplPackage);
    astTypes := List.map(templateDefs, templateDefToAstDefType);
    newAstDef := TplAbsyn.AST_DEF(packageName, isUnqualifiedImport, astTypes);
    cachedDefs := CacheTree.add(cachedDefs, file, newAstDef::{});
    astDefs :=  newAstDef :: astDefs;
    if Flags.isSet(Flags.FAILTRACE) then
      Debug.trace("Loaded typeview from template file: "+file+"\n");
    end if;
  else
    if Flags.isSet(Flags.FAILTRACE) then
      Debug.trace("Parse error - TplParser.typeviewDefsFromInterfaceFile "+file+" failed.\n");
    end if;
    fail();
  end try;
end typeviewDefsFromTemplateFile;


public function templateDefToAstDefType
  input tuple<TplAbsyn.Ident,TplAbsyn.TemplateDef> inTemplateDef;
  output tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> outType;
algorithm
  (outType) := matchcontinue (inTemplateDef)
    local
      TplAbsyn.Ident id;
      TplAbsyn.TypeSignature litType;
      TplAbsyn.TypedIdents iargs, oargs;
    case ( (id, TplAbsyn.STR_TOKEN_DEF()) )
      then ( (id, TplAbsyn.TI_CONST_TYPE(TplAbsyn.STRING_TOKEN_TYPE())) );

    case ( (id, TplAbsyn.LITERAL_DEF(litType = litType)) )
      then ( (id, TplAbsyn.TI_CONST_TYPE(litType)) );

    case ( (id, TplAbsyn.TEMPLATE_DEF(args = iargs)) )
      equation
        iargs =  TplAbsyn.imlicitTxtArg :: iargs;
        oargs = List.filterOnTrue(iargs, TplAbsyn.isText);
      then ( (id, TplAbsyn.TI_FUN_TYPE(iargs,oargs,{})) );

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse error - TplParser.templateDefToAstDefType failed.\n");
      then fail();

  end matchcontinue;
end templateDefToAstDefType;

/*
newLine:
  \r \n  //CR + LF ... Windows
  |
  \n     //CR only ... Linux
  |
  \r     //LF only ... Mac OS up to 9
*/
public function newLine
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := match(inChars, inLineInfo)
    local
      list<String> chars;
      ParseInfo pinfo;
      String c;
      Integer lnum, llen, i;

    // CR + LF .. Windows
    // LF only ... Linux
    // or CR only - Mac OS up to 9
    case (c :: chars, LINE_INFO(parseInfo = pinfo, lineNumber = lnum))
      equation
        i = stringCharInt(c);
        if i == 13
        then
          chars = match(chars)
            case ("\n" :: chars) then chars; // \n
            else chars;
          end match;
        end if;
        true = (i == 10) or (i == 13); // \n or \r
        llen = charsTillEndOfLine(chars, 1); // 1 is colum number of the first character, so count it
        lnum = lnum + 1;
      then (chars, LINE_INFO(pinfo, lnum, llen, chars));

  end match;
end newLine;

/*
// interleave will be applied before every token
interleave:  //i.e. space / comment
  [' '\n\r\t] interleave
  |
  '//' toEndOfLine  interleave
  |
  '/''*' comment  interleave
  |
  _ //just nothing
*/
public function interleave
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, charsRest;
      LineInfo linfo;
    case (" "  :: chars, linfo)
      equation
        (chars, linfo) =  interleave(chars, linfo);
      then (chars, linfo);
    case ("\t" :: chars, linfo)
      equation
        (chars, linfo) =  interleave(chars, linfo);
      then (chars, linfo);
    case ("/" :: "/" :: chars, linfo)
      equation
        (chars, linfo) = toEndOfLine(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
      then (chars, linfo);
    case ("/" :: "*" :: chars, linfo)
      equation
        (chars, linfo) = comment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
      then (chars, linfo);

    case (chars as ("/" :: "*" :: charsRest), linfo)
      equation
        failure((_,_) = comment(charsRest, linfo));
        (linfo) = parseError(chars, linfo, "Unmatched /* */ comment - reached end of file.", true);
      then ({}, linfo);


    case (chars, linfo)
      equation
        (chars, linfo) = newLine(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
      then (chars, linfo);

    else (inChars, inLineInfo);

  end matchcontinue;
end interleave;



/*
toEndOfLine:
    \n
    |
    eof  //end of stream ~ {}
    |
    any  toEndOfLine //any is any character
*/
public function toEndOfLine
  input list<String> inChars;
  input LineInfo inLineInfo;
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue(inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
    case (chars, linfo)
      equation
        (chars, linfo) = newLine(chars, linfo);
      then (chars, linfo);
    case (_ :: chars, linfo)
      equation
        (chars, linfo) = toEndOfLine(chars, linfo);
      then (chars, linfo);
    case ({}, linfo) then ({},linfo);
  end matchcontinue;
end toEndOfLine;


//comment:
//  '*''/'
//  |
//  '/''*' comment comment  //nesting is possible
//  |
//  any  comment

public function comment
  input list<String> inChars;
  input LineInfo inLineInfo;
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, charsRest;
      LineInfo linfo;
    case ("*" :: "/" :: chars, linfo) then (chars, linfo);
    case ("/" :: "*" :: chars, linfo)
      equation
        (chars, linfo) = comment(chars,linfo);
        (chars, linfo) = comment(chars,linfo);
      then (chars, linfo);
    case (chars, linfo)
      equation
        (chars, linfo) = newLine(chars, linfo);
        (chars, linfo) = comment(chars,linfo);
      then (chars, linfo);
    case (chars as (_ :: charsRest), linfo)
      equation
        failure((_,_) = newLine(chars, linfo));
        (chars, linfo) = comment(charsRest,linfo);
      then (chars, linfo);

    //case ({}, linfo)
    //  equation
    //    true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!Parse error - TplParser.comment - unmatched /* */ comment - reached end of file.\n");
    //  then fail(); //({}, linfo);
  end matchcontinue;
end comment;

/*
//afterKeyword must not fail after every keyword to be considered as keyword
afterKeyword:
    [_0-9A-Za-z]  =>  fail  // if it can be an identifier/other keyword
    |
    _  => ()
*/

public function afterKeyword
  input list<String> inChars;
algorithm
  _ := match inChars
    local
      String c;
      Integer i;

    case (c :: _)
      equation
        i = stringCharInt(c);
        //[_0-9A-Za-z]
        false = (i == 95/*_*/)
            or ( 48/*0*/ <= i and i <= 57/*9*/)
            or ( 65/*A*/ <= i and i <= 90/*Z*/)
            or ( 97/*a*/ <= i and i <= 122/*z*/);
      then ();

    case ({}) then ();

  end match;
end afterKeyword;


/*
identifier:
  [_A-Za-z]:c  identifier_rest:rest     =>  stringCharListString(c::rest)
*/

protected constant list<String> keywords =
 { "end","if","then","else","match","case","equation","equality","failure","algorithm","input","output","matchcontinue","local","constant","extends","external","for","function","import","package","partial","protected","public","record","as","uniontype","subtypeof"};

public function identifier
  input list<String> inChars;

  output list<String> outChars;
  output TplAbsyn.Ident outIdent;
algorithm
  (outChars, outIdent) := match inChars
    local
      list<String> chars, restIdChars;
      String c, ident;
      Integer i;

    case (c :: chars)
      equation
        i = stringCharInt(c);
        //[_A-Za-z]
        true = (i == 95/*_*/)
            or ( 65/*A*/ <= i and i <= 90/*Z*/)
            or ( 97/*a*/ <= i and i <= 122/*z*/);
        (chars, restIdChars) = identifier_rest(chars);
        ident = stringCharListString(c :: restIdChars);
        //false = listMember(ident, keywords);
      then (chars, ident);

  end match;
end identifier;

/*
identifier_rest:
    [_0-9A-Za-z]:c  identifier_rest:rest  =>  c::rest
    |
  _  =>  {}
*/
public function identifier_rest
  input list<String> inChars;

  output list<String> outChars;
  output list<String> outRestIdentChars;
algorithm
  (outChars, outRestIdentChars) := match inChars
    local
      list<String> chars, restIdChars;
      String c;
      Integer i;

    case (c :: chars)
      equation
        i = stringCharInt(c);
        //[_0-9A-Za-z]
        if (i == 95/*_*/)
            or ( 48/*0*/ <= i and i <= 57/*9*/)
            or ( 65/*A*/ <= i and i <= 90/*Z*/)
            or ( 97/*a*/ <= i and i <= 122/*z*/)
        then
          (chars, restIdChars) = identifier_rest(chars);
          restIdChars = c :: restIdChars;
        else
          chars = inChars;
          restIdChars = {};
        end if;
      then (chars, restIdChars);

  end match;
end identifier_rest;

/*
pathIdent:
  identifier:head  pathIdentPath(head):pid => pid
*/
public function pathIdent
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.PathIdent outPathIdent;
algorithm
  (outChars, outLineInfo, outPathIdent) := match (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      String head;
      TplAbsyn.PathIdent pid;

    case (chars, linfo)
      equation
        (chars, head) = identifier(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, pid) = pathIdentPath(chars, linfo, head);
      then (chars, linfo, pid);

  end match;
end pathIdent;


/*
pathIdentPath(head):
  '.' pathIdent:path  =>  PATH_IDENT(head, path)
  |
  '.' error "expecting identifier after dot."
    => PATH_IDENT(head, TplAbsyn.IDENT("#error#"))
  |
  _ =>  IDENT(head)
*/
public function pathIdentPath
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.Ident inHeadIdent;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.PathIdent outPathIdent;
algorithm
  (outChars, outLineInfo, outPathIdent) := matchcontinue (inChars, inLineInfo,inHeadIdent)
    local
      list<String> chars;
      LineInfo linfo;
      String head;
      TplAbsyn.PathIdent pid;

    case ("." :: chars, linfo, head)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, pid) = pathIdent(chars, linfo);
      then (chars, linfo, TplAbsyn.PATH_IDENT(head, pid));

    // can be followed by .*,  for example
    //case ("." :: chars, linfo, head)
    //  equation
    //    (chars, linfo) = interleave(chars, linfo);
    //    failure( (_, _, _) = pathIdent(chars, linfo));
    //    (linfo) = parseError(chars, linfo, "Expected an identifier after '.' at the position.", true);
    //  then (chars, linfo, TplAbsyn.PATH_IDENT(head, TplAbsyn.IDENT("#error#")));


    else (inChars, inLineInfo, TplAbsyn.IDENT(inHeadIdent));

  end matchcontinue;
end pathIdentPath;


public function identifierNoOpt
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Ident outIdent;
algorithm
  (outChars, outLineInfo, outIdent) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      String  ident;
      LineInfo linfo;

    case (chars, linfo)
      equation
        (chars, ident) = identifier(chars);
      then (chars, linfo, ident);

    case (chars, linfo)
      equation
        failure((_, _) = identifier(chars));
        (linfo) = parseError(chars, linfo, "Expected an identifier at the position.", true);
      then (chars, linfo, "#error#");

  end matchcontinue;
end identifierNoOpt;


public function pathIdentNoOpt
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.PathIdent outPathIdent;
algorithm
  (outChars, outLineInfo, outPathIdent) := match (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      String head;
      TplAbsyn.PathIdent pid;

    case (chars, linfo)
      equation
        (chars, linfo, head) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, pid) = pathIdentPath(chars, linfo, head);
      then (chars, linfo, pid);

  end match;
end pathIdentNoOpt;

/*
templPackage:
  'package'  pathIdent:pid  stringComment
    definitions(pid,{},{}):(astDefs,templDefs)
  endDefPathIdent(pid)
  =>   TEMPL_PACKAGE(pid, astDefs,templDefs)
*/
public function templPackage
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TemplPackage outTemplPackage;
  input output CacheTree.Tree cachedDefs;
algorithm
  (outChars, outLineInfo, outTemplPackage) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.PathIdent pid;
      list<TplAbsyn.ASTDef> astDefs;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TemplateDef>> templDefs;
      String annotationFooter;

    case (chars, linfo)
      equation
        (chars, linfo) = interleaveExpectKeyWord(chars, linfo, {"p","a","c","k","a","g","e"}, true);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, pid) = pathIdentNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, astDefs,templDefs,cachedDefs) = definitions(chars, linfo,{},{},cachedDefs);
        astDefs = listReverse(astDefs);
        templDefs = listReverse(templDefs);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, annotationFooter) = annotationFooter(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = endDefPathIdent(chars, linfo,pid);
      then (chars, linfo, TplAbsyn.TEMPL_PACKAGE(pid, astDefs, templDefs, annotationFooter));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!!Parse error - TplParser.templPackage failed.\n");
      then fail();

  end matchcontinue;
end templPackage;

/*
definitions(astDefs,templDefs):
  'import' 'interface' pathIdent:pid stringComment ';'
    { ads = typeviewDefsFromInterfaceFile(packageNameToFileName(pid,".mo"), astDefs) }
    definitions(ads, templDefs):(ads,tds)
    => (ads,tds)
  |
  'import' pathIdent:pid unqualImportPostfix:unq stringComment ';'
    { ads = typeviewDefsFromTemplateFile(pid, unq, astDefs) }
    definitions(ads, templDefs):(ads,tds)
    => (ads,tds)
//  |
//  absynDef:ad  definitions(ad::astDefs,templDefs):(ads,tds) => (ads,tds)
  |
  templDef:(name, td)  definitions(astDefs,(name,td)::templDefs):(ads,tds) => (ads,tds)
//  |
//  error "Expecting 'end' | ['public' | 'protected' ] 'package' definition | template definition starting with an identifier."
*/
public function definitions
  input list<String> inChars;
  input LineInfo inLineInfo;
  input list<TplAbsyn.ASTDef> inAccASTDefs;
  input list<tuple<TplAbsyn.Ident, TplAbsyn.TemplateDef>> inAccTemplDefs;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.ASTDef> outASTDefs;
  output list<tuple<TplAbsyn.Ident, TplAbsyn.TemplateDef>> outTemplDefs;
  input output CacheTree.Tree cachedDefs;
algorithm
  (outChars, outLineInfo, outASTDefs, outTemplDefs) := matchcontinue (inChars, inLineInfo, inAccASTDefs, inAccTemplDefs)
    local
      list<String> chars, startChars;
      Option<String> errOptTV;
      LineInfo linfo, startLinfo, linfoTV;
      Boolean  isUnqual;
      TplAbsyn.Ident  name;
      TplAbsyn.PathIdent pid;
      TplAbsyn.TemplateDef td;
      list<TplAbsyn.ASTDef> astDefs;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TemplateDef>> templDefs;

    //stop at 'end' ... a little workaround to have the code "nice"
    case (startChars as ("e"::"n"::"d":: chars), linfo, astDefs, templDefs)
      equation
        afterKeyword(chars);
      then (startChars, linfo, astDefs, templDefs);

    case ("i"::"m"::"p"::"o"::"r"::"t":: chars, linfo, astDefs, templDefs)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        ("i"::"n"::"t"::"e"::"r"::"f"::"a"::"c"::"e" :: chars) = chars;
        afterKeyword(chars);
        //remember position for a file error
        (startChars, startLinfo) = interleave(chars, linfo);
        (chars, linfo, pid) = pathIdentNoOpt(startChars, startLinfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);

        (astDefs, linfoTV, errOptTV, cachedDefs) = typeviewDefsFromInterfaceFile(pid, astDefs, cachedDefs);
        linfo = parseErrorPrevPositionOpt(startChars, startLinfo, linfo, errOptTV, false);
        linfo = mergeErrors(linfo, linfoTV);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, astDefs, templDefs, cachedDefs) = definitions(chars, linfo, astDefs, templDefs, cachedDefs);
      then (chars, linfo, astDefs, templDefs);

    case ("i"::"m"::"p"::"o"::"r"::"t":: chars, linfo, astDefs, templDefs)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        //remember position for a file error
        (startChars, startLinfo) = interleave(chars, linfo);
        (chars, linfo, pid) = pathIdentNoOpt(startChars, startLinfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, isUnqual) = unqualImportPostfix(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);

        (astDefs, linfoTV, errOptTV, cachedDefs) = typeviewDefsFromTemplateFile(pid, isUnqual, astDefs, cachedDefs);
        linfo = parseErrorPrevPositionOpt(startChars, startLinfo, linfo, errOptTV, false);
        linfo = mergeErrors(linfo, linfoTV);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, astDefs, templDefs, cachedDefs) = definitions(chars, linfo, astDefs, templDefs, cachedDefs);
      then (chars, linfo, astDefs, templDefs);

    case (chars, linfo, astDefs,templDefs)
      equation
        (chars, linfo, name, td) = templDef(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, astDefs, templDefs, cachedDefs) = definitions(chars, linfo, astDefs, (name,td)::templDefs, cachedDefs);
      then (chars, linfo, astDefs, templDefs);

    else (inChars, inLineInfo, inAccASTDefs, inAccTemplDefs);

  end matchcontinue;
end definitions;

/*
unqualImportPostfix:
  '.' '*' => true
  |
  _ => false
*/
public function unqualImportPostfix
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output Boolean outIsUnqual;
algorithm
  (outChars, outLineInfo, outIsUnqual) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;

    case ("." :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        ("*" :: chars) = chars;
      then (chars, linfo, true);
    else (inChars, inLineInfo, false);
  end matchcontinue;
end unqualImportPostfix;

//optional, may fail
public function typeSig
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypeSignature outTypeSignature;
algorithm
  (outChars, outLineInfo, outTypeSignature) := match (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.TypeSignature ts;

    case (chars, linfo)
      equation
        (chars, linfo, ts) = typeSig_base(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
      then (chars, linfo, ts);

  end match;
end typeSig;

//must not fail
public function typeSigNoOpt
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypeSignature outTypeSignature;
algorithm
  (outChars, outLineInfo, outTypeSignature) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.TypeSignature  ts;

    case (chars, linfo)
      equation
        (chars, linfo, ts) = typeSig(chars, linfo);
      then (chars, linfo, ts);

    case (chars, linfo)
      equation
        linfo = parseError(chars, linfo, "Expected a type signature at the position.", true);
      then (chars, linfo,  TplAbsyn.UNRESOLVED_TYPE("#parse error#"));

  end matchcontinue;
end typeSigNoOpt;

/*
typeSig_base:
  'list' '<' typeSig:tof '>'  =>  LIST_TYPE(tof)
  |
  'Option' '<' typeSig '>'   =>  OPTION_TYPE(tof)
  |
  'tuple' '<' typeSig:ts  typeSig_restList:restLst  '>'  => TUPLE_TYPE(ts::restLst)
  |
  'array' '<' typeSig:tof '>'  =>  ARRAY_TYPE(tof)
  |
  pathIdent:pid  =>  NAMED_TYPE(pid)  // +specializations for String, Integer, .... => STRING_TYPE(), ...
*/
public function typeSig_base
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypeSignature outTypeSignature;
algorithm
  (outChars, outLineInfo, outTypeSignature) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.TypeSignature ts, tof;
      list<TplAbsyn.TypeSignature> restLst;
      TplAbsyn.PathIdent pid;

    case ("l"::"i"::"s"::"t" :: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleaveExpectChar(chars, linfo, "<");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, tof) = typeSigNoOpt(chars, linfo);
        (chars, linfo) = interleaveExpectChar(chars, linfo, ">");
      then (chars, linfo, TplAbsyn.LIST_TYPE(tof));

    case ("O"::"p"::"t"::"i"::"o"::"n" :: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleaveExpectChar(chars, linfo, "<");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, tof) = typeSigNoOpt(chars, linfo);
        (chars, linfo) = interleaveExpectChar(chars, linfo, ">");
      then (chars, linfo, TplAbsyn.OPTION_TYPE(tof));

    case ("t"::"u"::"p"::"l"::"e" :: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleaveExpectChar(chars, linfo, "<");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, tof) = typeSigNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, restLst) = typeSig_restList(chars, linfo);
        (chars, linfo) = interleaveExpectChar(chars, linfo, ">");
      then (chars, linfo, TplAbsyn.TUPLE_TYPE(tof::restLst));

    case ("a"::"r"::"r"::"a"::"y" :: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleaveExpectChar(chars, linfo, "<");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, tof) = typeSigNoOpt(chars, linfo);
        (chars, linfo) = interleaveExpectChar(chars, linfo, ">");
      then (chars, linfo, TplAbsyn.ARRAY_TYPE(tof));

    case (chars, linfo)
      equation
        (chars, linfo, pid) = pathIdent(chars, linfo);
        ts = typeSigFromPathIdent(pid);
      then (chars, linfo, ts);

  end matchcontinue;
end typeSig_base;

/*
typeSig_restList:
    ',' typeSig:ts  typeSig_restList:restLst  =>  ts::restLst
    |
    _  => {}
*/
public function typeSig_restList
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.TypeSignature> outTypeSignatureList;
algorithm
  (outChars, outLineInfo, outTypeSignatureList) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.TypeSignature ts;
      list<TplAbsyn.TypeSignature> tsLst;

    case ("," :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSigNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, tsLst) = typeSig_restList(chars, linfo);
      then (chars, linfo, ts::tsLst);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end typeSig_restList;


public function typeSigFromPathIdent
  input TplAbsyn.PathIdent inPathIdent;
  output TplAbsyn.TypeSignature outTypeSignature;
algorithm
  (outTypeSignature) := match (inPathIdent)
    case (TplAbsyn.IDENT("String") )  then TplAbsyn.STRING_TYPE();
    case (TplAbsyn.IDENT("Integer") ) then TplAbsyn.INTEGER_TYPE();
    case (TplAbsyn.IDENT("Real") )    then TplAbsyn.REAL_TYPE();
    case (TplAbsyn.IDENT("Boolean") ) then TplAbsyn.BOOLEAN_TYPE();

    else TplAbsyn.NAMED_TYPE(inPathIdent);

  end match;
end typeSigFromPathIdent;

/*
publicProtected:
  'public' => true
  |
  'protected' => false
  |
  _ => true
*/
public function publicProtected
  input list<String> inChars;

  output list<String> outChars;
  output Boolean outIsDefault;
algorithm
  (outChars, outIsDefault) := matchcontinue (inChars)
    local
      list<String> chars;

    case ("p"::"u"::"b"::"l"::"i"::"c" :: chars)
      equation
        afterKeyword(chars);
      then (chars, true);

    case ("p"::"r"::"o"::"t"::"e"::"c"::"t"::"e"::"d" :: chars)
      equation
        afterKeyword(chars);
      then (chars, false);

    else (inChars, true);

  end matchcontinue;
end publicProtected;

/*
stringComment:
  '"' stringCommentRest
  |
  _
*/
public function stringComment
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, startChars;
      LineInfo linfo, startLinfo;
      Option<String> optErr;

    case (startChars as ("\"" :: chars), startLinfo)
      equation
        (chars, linfo, optErr) = stringCommentRest(chars, startLinfo);
        linfo = parseErrorPrevPositionOpt(startChars, startLinfo, linfo, optErr, true);
      then (chars, linfo);

    else (inChars, inLineInfo);

  end matchcontinue;
end stringComment;
/*
stringCommentRest:
  '\\"' stringCommentRest
  |
  '\\' stringCommentRest
  |
  ~'"' stringCommentRest
  |
  '"'
*/
public function stringCommentRest
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output Option<String> outError;
algorithm
  (outChars, outLineInfo, outError) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, startChars;
      LineInfo linfo;
      Option<String> optErr;
      String strErr;

    case ("\"" :: chars, linfo)
      then (chars, linfo,NONE());

    case ("\\"::"\"" :: chars, linfo)
      equation
        (chars, linfo, optErr) = stringCommentRest(chars, linfo);
      then (chars, linfo, optErr);

    case ("\\"::"\\" :: chars, linfo)
      equation
        (chars, linfo, optErr) = stringCommentRest(chars, linfo);
      then (chars, linfo, optErr);

    case (chars, linfo)
      equation
        (chars, linfo) = newLine(chars, linfo);
        (chars, linfo, optErr) = stringCommentRest(chars, linfo);
      then (chars, linfo, optErr);

    case (startChars as (_ :: chars), linfo)
      equation
        failure((_, _) = newLine(startChars, linfo));
        (chars, linfo, optErr) = stringCommentRest(chars, linfo);
      then (chars, linfo, optErr);

    case ( {}, linfo )
      equation
        strErr = "Unmatched \" \" comment - reached end of file.";
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("Parse error - TplParser.stringCommentRest - " + strErr + "\n");
        end if;
      then ( {}, linfo, SOME(strErr) );

  end matchcontinue;
end stringCommentRest;


public function semicolon
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;

   case (";":: chars, linfo)
     then (chars, linfo);

   //error expect ; ... only report it if it is the first error
   case (chars, linfo)
      equation
        linfo = parseError(chars, linfo, "Expected semicolon ';' at the position.", false );
      then (chars, linfo);

   else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!! TplParser.semicolon failed.\n");
      then fail();

  end matchcontinue;
end semicolon;


/*
interfacePackage(astDefs):
  'interface' 'package'  pathIdent:pid  stringComment
    typeviewDefs(astDefs):ads
  endDefPathIdent(pid)
  =>   (pid, ads)
*/
public function interfacePackage
  input list<String> inChars;
  input LineInfo inLineInfo;
  input list<TplAbsyn.ASTDef> inAccASTDefs;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.PathIdent outPid;
  output list<TplAbsyn.ASTDef> outAccASTDefs;
algorithm
  (outChars, outLineInfo, outPid, outAccASTDefs)
  := matchcontinue (inChars, inLineInfo, inAccASTDefs)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.PathIdent pid;
      list<TplAbsyn.ASTDef> astDefs;

    case (chars, linfo, _)
      equation
        (chars, linfo) = interleaveExpectKeyWord(chars, linfo, {"i","n","t","e","r","f","a","c","e"}, true);
        (chars, linfo) = interleaveExpectKeyWord(chars, linfo, {"p","a","c","k","a","g","e"}, true);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, pid) = pathIdentNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, astDefs) = typeviewDefs(chars, linfo, inAccASTDefs);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = endDefPathIdent(chars, linfo,pid);
      then (chars, linfo, pid, astDefs);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!!Parse error - TplParser.interfacePackage failed.\n");
      then fail();

  end matchcontinue;
end interfacePackage;

/*
typeviewDefs(astDefs):
  absynDef:ad  typeviewDefs(ad::astDefs):ads => ads
  |
  _ => astDefs
*/
public function typeviewDefs
  input list<String> inChars;
  input LineInfo inLineInfo;
  input list<TplAbsyn.ASTDef> inAccASTDefs;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.ASTDef> outASTDefs;
algorithm
  (outChars, outLineInfo, outASTDefs) := matchcontinue (inChars, inLineInfo, inAccASTDefs)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.ASTDef ad;
      list<TplAbsyn.ASTDef> astDefs;

    case (chars, linfo, astDefs)
      equation
        (chars, linfo, ad) = absynDef(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, astDefs) = typeviewDefs(chars, linfo, ad::astDefs);
      then (chars, linfo, astDefs);

    else (inChars, inLineInfo, inAccASTDefs);

  end matchcontinue;
end typeviewDefs;


/*
absynDef:
  publicProtected:isD  'package' pathIdent:pid  stringComment
    absynTypes:types
  endDefPathIdent(pid)
  =>  AST_DEF(pid, isD, types)
*/
public function absynDef
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.ASTDef outASTDef;
algorithm
  (outChars, outLineInfo, outASTDef) := match (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;

    case (chars, linfo)
      equation
        (chars, isD) = publicProtected(chars);
        (chars, linfo) = interleave(chars, linfo);
        ("p"::"a"::"c"::"k"::"a"::"g"::"e" :: chars) = chars;
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);

        (chars, linfo,pid) = pathIdentNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, types) = absynTypes(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = endDefPathIdent(chars, linfo,pid);
      then (chars, linfo, TplAbsyn.AST_DEF(pid,isD,types));

  end match;
end absynDef;

/*
//not optional, must not fail
endDefPathIdent(pid):
  'end' pathIdent:pidEnd ';' // pid == pidEnd | warning
*/
public function endDefPathIdent
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.PathIdent inPathIdentToMatch;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo, inPathIdentToMatch)
    local
      list<String> chars, startChars;
      LineInfo linfo, startLinfo;
      TplAbsyn.PathIdent pid, pidToMatch;

    case ("e"::"n"::"d" :: chars, linfo, pidToMatch)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo,pid) = pathIdentNoOpt(chars, linfo);
        equality(pid = pidToMatch);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
      then (chars, linfo);

   //error unmatched "end"
   case ("e"::"n"::"d" :: chars, linfo, pidToMatch)
      equation
        afterKeyword(chars);
        (startChars, startLinfo) = interleave(chars, linfo);
        (chars, linfo,pid) = pathIdentNoOpt(startChars, startLinfo);
        failure(equality(pid = pidToMatch));
        linfo = parseErrorPrevPosition(startChars, startLinfo, linfo,
                   "Unmatched ident for 'end'. Expected '" + TplAbsyn.pathIdentString(pidToMatch) + "', but '" + TplAbsyn.pathIdentString(pid) + "' found instead.",
                   false);
        //true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse warning - TplParser.endDefPathIdent - unmatched ident for 'end' of the definition of '" + TplAbsyn.pathIdentString(pidToMatch) + "' ... 'end " + TplAbsyn.pathIdentString(pid) + "' found instead.\n");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
      then (chars, linfo);

   //error "end" expected
   case (chars, linfo, _)
      equation
        (_, false) = isKeyword(chars, "e"::"n"::"d"::{});
        (linfo) = parseError(chars, linfo, "Expected 'end' keyword at the position.", true);
      then (chars, linfo);

   case (chars, linfo, _)
     equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("!!!Parse error - TplParser.endDefPathIdent failed.\n");
        end if;
     then (chars, linfo);

  end matchcontinue;
end endDefPathIdent;

/*
//not optional ... must not fail
endDefIdent(id):
  'end' identifier:idEnd ';' // id == idEnd | warning
*/
public function endDefIdent
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.Ident inIdentToMatch;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo, inIdentToMatch)
    local
      list<String> chars, startChars;
      LineInfo linfo, startLinfo;
      TplAbsyn.Ident id, idToMatch;

    case ("e"::"n"::"d" :: chars, linfo, idToMatch)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars,linfo,id) = identifierNoOpt(chars,linfo);
        equality(id = idToMatch);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
      then (chars, linfo);

    //error unmatched ids
    case ("e"::"n"::"d" :: chars, linfo, idToMatch)
      equation
        afterKeyword(chars);
        (startChars, startLinfo) = interleave(chars, linfo);
        (chars,linfo,id) = identifierNoOpt(startChars,startLinfo);
        failure(equality(id = idToMatch));
        linfo = parseErrorPrevPosition(startChars, startLinfo, linfo,
                   "Unmatched ident for 'end'. Expected '" + idToMatch + "', but '" + id + "' found instead.",
                   false);
        //true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse warning - TplParser.endDefIdent - unmatched ident for 'end' of the definition of " + idToMatch + " ... end " + id + " found instead.\n");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
      then (chars, linfo);

    //error "end" expected
    case (chars, linfo, _)
      equation
        (_, false) = isKeyword(chars, "e"::"n"::"d"::{});
        (linfo) = parseError(chars, linfo, "Expected 'end' keyword at the position.", true);
      then (chars, linfo);

    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("!!!Parse error - TplParser.endDefIdent failed.\n");
        end if;
      then (inChars, inLineInfo);

  end matchcontinue;
end endDefIdent;


/*
absynTypes:
  absynType:(id,ti)  absynTypes:types  => (id,ti) :: types
  |
  _ => {}
*/
public function absynTypes
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> outTypes;
algorithm
  (outChars, outLineInfo, outTypes) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;

    case (chars, linfo)
      equation
        (chars, linfo, idti) = absynType(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, types) = absynTypes(chars, linfo);
      then (chars, linfo, idti :: types);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end absynTypes;
/*
absynType:
  'uniontype' identifier:id  stringComment
      recordTags(id):rtags
  => (id, TI_UNION_TYPE(rtags))
  |
  recordType:(id,fields)
  => (id, TI_RECORD_TYPE(fields))
  |
  'function' identifier:id  stringComment
    inputFunArgs:inArgs
    outputFunArgs:outArgs
  endDefIdent(id)
  => (id, TI_FUN_TYPE(inArgs,outArgs))
  |
  'constant'  typeSig:ts  identifier:id  stringComment  ';'
  => (id, TI_CONST_TYPE(ts))
  |
  'type' identifier:id '=' typeSig:ts stringComment  ';'
  => (id, TI_ALIAS_TYPE(ts))
*/
public function absynType
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> outType;
algorithm
  (outChars, outLineInfo, outType) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
      list<TplAbsyn.Ident> tyvars;

    case ("u"::"n"::"i"::"o"::"n"::"t"::"y"::"p"::"e" :: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, id) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, rtags) = recordTags(chars, linfo, id);
      then (chars, linfo, (id, TplAbsyn.TI_UNION_TYPE(rtags)));

   case (chars, linfo)
      equation
        (chars, linfo, (id,fields)) = recordType(chars, linfo);
      then (chars, linfo, (id, TplAbsyn.TI_RECORD_TYPE(fields)));

   case ("f"::"u"::"n"::"c"::"t"::"i"::"o"::"n":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, id) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, tyvars) = typeVars(chars, linfo, {});
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, inargs) = inputFunArgs(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, outargs) = outputFunArgs(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, tyvars) = typeVars(chars, linfo, tyvars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = endDefIdent(chars, linfo,id);
      then (chars, linfo, (id, TplAbsyn.TI_FUN_TYPE(inargs,outargs,tyvars)));

   case ("c"::"o"::"n"::"s"::"t"::"a"::"n"::"t":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSigNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, id) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
      then (chars, linfo, (id, TplAbsyn.TI_CONST_TYPE(ts)));

   case ("t"::"y"::"p"::"e":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, id) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleaveExpectChar(chars, linfo, "=");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSigNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
      then (chars, linfo, (id, TplAbsyn.TI_ALIAS_TYPE(ts)));

  end matchcontinue;
end absynType;

/*
recordType:
  'record' identifier:id  stringComment
      typeDecls:tids
  'end' identifier:idEnd ';' // id == idEnd
  => (id,tids)
*/
public function recordType
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> outRecordType;
algorithm
  (outChars, outLineInfo, outRecordType) := match (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields;

    case ("r"::"e"::"c"::"o"::"r"::"d":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, id) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, fields) = typeDecls(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = endDefIdent(chars, linfo,id);
      then (chars, linfo, (id, fields));

  end match;
end recordType;
/*
typeDecls:
  typeSig:ts  identifier:id  stringComment ';'
  typeDecls:tids
  => (id,ts) :: tids
  |
  _ => {}
*/
public function typeDecls
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypedIdents outTypeDecls;
algorithm
  (outChars, outLineInfo, outTypeDecls) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, startChars;
      LineInfo linfo;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields;
      TplAbsyn.TypeSignature ts;

    //stop at 'end' ... a little workaround to have the code "nice"
    case (startChars as ("e"::"n"::"d":: chars), linfo)
      equation
        afterKeyword(chars);
      then (startChars, linfo, {} );

    case (chars, linfo)
      equation
        (chars, linfo, ts) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, id) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, fields) = typeDecls(chars, linfo);
      then (chars, linfo, (id,ts)::fields );

    else (inChars, inLineInfo, {});

  end matchcontinue;
end typeDecls;
/*
recordTags:
  recordType:(id,tids)  recordTags:rtags  => (id,tids) :: rtags
  |
  _ => {}
*/
public function recordTags
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String id;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> outRecordTags;
algorithm
  (outChars, outLineInfo, outRecordTags) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> rtag;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;

    case (chars, linfo)
      equation
        (chars, linfo, rtag) = recordType(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, rtags) = recordTags(chars, linfo, id);
      then (chars, linfo, rtag :: rtags);

    case (chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = endDefIdent(chars, linfo, id);
      then (chars, linfo, {});

    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("!!!Parse error - TplParser.recordTags failed at " + inLineInfo.parseInfo.fileName + ": " + String(inLineInfo.lineNumber) + ".\n");
        end if;
      then (inChars, inLineInfo, {});

  end matchcontinue;
end recordTags;
/*
inputFunArgs:
  'input' typeSig:ts  identifier:id  stringComment
  inputFunArgs:iargs
  => (id,ts) :: iargs
  |
  _ => {}
*/
public function inputFunArgs
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypedIdents outTypedIdents;
algorithm
  (outChars, outLineInfo, outTypedIdents) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents inargs;
      TplAbsyn.TypeSignature ts;

    case ("i"::"n"::"p"::"u"::"t":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSigNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, id) = identifierNoOpt(chars,linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, inargs) = inputFunArgs(chars, linfo);
      then (chars, linfo, (id,ts) :: inargs);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end inputFunArgs;
/*
outputFunArgs:
  'output' typeSig:ts  identifier:id  stringComment ';'
  outputFunArgs:oargs
  => (id,ts) :: oargs
  |
  _ => {}
*/
public function outputFunArgs
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypedIdents outTypedIdents;
algorithm
  (outChars, outLineInfo, outTypedIdents) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents outargs;
      TplAbsyn.TypeSignature ts;

    case ("o"::"u"::"t"::"p"::"u"::"t":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSigNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, id) = identifierNoOpt(chars,linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, outargs) = outputFunArgs(chars, linfo);
      then (chars, linfo, (id,ts) :: outargs);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end outputFunArgs;

/*
typeVars(tyvars):
  'replaceable' 'type'  identifier:id  'subtypeof' 'Any' ';'
  typeVars(id :: tyvars):tyvars
  => tyvars
  |
  _ => tyvars
*/
public function typeVars
  input list<String> inChars;
  input LineInfo inLineInfo;
  input list<TplAbsyn.Ident> inTyVars;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.Ident> outTyVars;
algorithm
  (outChars, outLineInfo, outTyVars) := matchcontinue (inChars, inLineInfo, inTyVars)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.Ident id;
      list<TplAbsyn.Ident> tyvars;

    case ("r"::"e"::"p"::"l"::"a"::"c"::"e"::"a"::"b"::"l"::"e":: chars, linfo, tyvars)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleaveExpectKeyWord(chars, linfo, {"t","y","p","e"}, true);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, id) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleaveExpectKeyWord(chars, linfo, {"s","u","b","t","y","p","e","o","f"}, true);
        (chars, linfo) = interleaveExpectKeyWord(chars, linfo, {"A","n","y"}, true);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars,linfo);
        (chars, linfo, tyvars) = typeVars(chars, linfo, id::tyvars);
      then (chars, linfo, tyvars);

    else (inChars, inLineInfo, inTyVars);

  end matchcontinue;
end typeVars;

/*
templDef:
    'template' identifier:name
      '(' templArgs:args ')' stringComment
      templDef_Templ:(exp,lesc,resc)
    endDefIdent(name)
      =>  (name, TEMPLATE_DEF(args,lesc,resc,exp))
    |
    'constant' constantType:ctype  identifier:name templDef_Const:td //check ctype
      stringComment ';'
      => (name, td)
*/
public function templDef
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Ident outTemplName;
  output TplAbsyn.TemplateDef outTemplDef;
algorithm
  (outChars, outLineInfo, outTemplName, outTemplDef) := match (inChars, inLineInfo)
    local
      String lesc, resc;
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.Ident name;
      TplAbsyn.TemplateDef td;
      TplAbsyn.TypeSignature ctype, ctypeLit;
      TplAbsyn.TypedIdents args;
      TplAbsyn.Expression exp;

    case ("t"::"e"::"m"::"p"::"l"::"a"::"t"::"e":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, name) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleaveExpectChar(chars, linfo, "(");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, args) = templArgs(chars, linfo);
        (chars, linfo) = interleaveExpectChar(chars, linfo, ")");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp, lesc, resc) = templDef_Templ(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = endDefIdent(chars, linfo, name);
      then (chars, linfo, name, TplAbsyn.TEMPLATE_DEF(args,lesc,resc,exp));

    case ("c"::"o"::"n"::"s"::"t"::"a"::"n"::"t" :: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ctype) = constantType(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, name) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, td, ctypeLit) = templDef_Const(chars, linfo);
        (chars, linfo) = checkConstantType(chars, linfo, ctype, ctypeLit);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars,linfo) = interleave(chars, linfo);
        (chars,linfo) = semicolon(chars, linfo);
      then (chars, linfo, name, td);
  end match;
end templDef;

/*
templDef_Const:
  '=' stringConstant:strRevList
    =>  STR_TOKEN_DEF(makeStrTokFromRevStrList(strRevList))
  |
  '=' literalConstant:(str,litType)
    =>  LITERAL_DEF(str, litType)
*/
public function templDef_Const
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TemplateDef outTemplDef;
  output TplAbsyn.TypeSignature outConstType;
algorithm
  (outChars, outLineInfo, outTemplDef, outConstType) := matchcontinue (inChars, inLineInfo)
    local
      String   str;
      list<String> chars, strRevList;
      LineInfo linfo;
      Tpl.StringToken st;
      TplAbsyn.TypeSignature litType;

    case ("=" :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, strRevList) = stringConstant(chars, linfo);
        st = makeStrTokFromRevStrList(strRevList);
      then (chars, linfo, TplAbsyn.STR_TOKEN_DEF(st), TplAbsyn.STRING_TYPE());

    case ("=" :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, str, litType) = literalConstant(chars, linfo);
      then (chars, linfo, TplAbsyn.LITERAL_DEF(str, litType), litType);

   //error after = expect constant
   case ("=" :: chars, linfo)
      equation
        linfo = parseError(chars, linfo, "Expected a constant definition after the '='.", true);
        litType = TplAbsyn.UNRESOLVED_TYPE("#Error#");
      then (chars, linfo, TplAbsyn.LITERAL_DEF("#error#", litType),litType);

   //error, cannot follow on
   case (chars, linfo)
      equation
        linfo = parseError(chars, linfo, "Expected a constant definition after the position.", true);
        litType = TplAbsyn.UNRESOLVED_TYPE("#Error#");
      then (chars, linfo, TplAbsyn.TEMPLATE_DEF({},"","",(TplAbsyn.ERROR_EXP(),dummySourceInfo)), litType);


  end matchcontinue;
end templDef_Const;

/*
constantType:
  'String'  => STRING_TYPE()
  'Integer' => INTEGER_TYPE()
  'Real'    => REAL_TYPE()
  'Boolean' => BOOLEAN_TYPE()
*/
public function constantType
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypeSignature outConstType;
algorithm
  (outChars, outLineInfo, outConstType) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;

    case ("S"::"t"::"r"::"i"::"n"::"g" :: chars, linfo)
      equation
        afterKeyword(chars);
      then (chars, linfo, TplAbsyn.STRING_TYPE());

    case ("I"::"n"::"t"::"e"::"g"::"e"::"r" :: chars, linfo)
      equation
        afterKeyword(chars);
      then (chars, linfo, TplAbsyn.INTEGER_TYPE());

    case ("R"::"e"::"a"::"l":: chars, linfo)
      equation
        afterKeyword(chars);
      then (chars, linfo, TplAbsyn.REAL_TYPE());

    case ("B"::"o"::"o"::"l"::"e"::"a"::"n" :: chars, linfo)
      equation
        afterKeyword(chars);
      then (chars, linfo, TplAbsyn.BOOLEAN_TYPE());

   //error, no expected type, cannot follow on
   case (chars, linfo)
      equation
        linfo = parseError(chars, linfo, "Expected 'String', 'Integer', 'Real' or 'Boolean' type specification for the constant definition after the position.", false);
      then (chars, linfo, TplAbsyn.UNRESOLVED_TYPE("#Error#"));


  end matchcontinue;
end constantType;


public function checkConstantType
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.TypeSignature inConstType;
  input TplAbsyn.TypeSignature inConstTypeLiteral;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo, inConstType, inConstTypeLiteral)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.TypeSignature ctype, litType;


    //types resolved, but not equal
    case (chars, linfo, ctype, litType)
      equation
        failure(TplAbsyn.UNRESOLVED_TYPE(_) = ctype);
        failure(TplAbsyn.UNRESOLVED_TYPE(_) = litType);
        failure(equality(ctype = litType));
        linfo = parseError(chars, linfo, "Declared constant type and the type of the constant's definition literal are different.", false);
      then (chars, linfo);

    //otherwise, error is already reported
    else (inChars, inLineInfo);

  end matchcontinue;
end checkConstantType;



/*
templDef_Templ:
  '::='  expression(LEsc = '<',REsc = '>'):exp   => (exp,'<','>')
  ///|
  //'$$='  expression(LEsc = '$',REsc = '$'):exp   => (exp,'$','$')
*/
public function templDef_Templ
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
  output String outLeftEsc;
  output String outRightEsc;
algorithm
  (outChars, outLineInfo, outExpression, outLeftEsc, outRightEsc) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.Expression exp;

    case (":"::":"::"=" :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, "<", ">", false);
      then (chars, linfo, exp, "<", ">");

    //case ("$"::"$"::"=" :: chars, linfo)
    //  equation
    //    (chars, linfo) = interleave(chars, linfo);
    //    (chars, linfo, exp) = expression(chars, linfo, "$", "$", false);
    //  then (chars, linfo, exp, "$", "$");

   //error expect ::= or $$=, try ::=
   case (chars, linfo)
      equation
        failure(":"::":"::"=" :: _ = chars);
        //failure("$"::"$"::"=" :: _ = chars);
        linfo = parseError(chars, linfo, "Expected '::=' symbol before a template definition body at the position.", false);
        //try the ::= path
        (chars, linfo, exp) = expression(chars, linfo, "<", ">", false);
      then (chars, linfo, exp, "<", ">");

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!!Parse error - TplParser.templDef_Templ failed.\n");
      then fail();

  end matchcontinue;
end templDef_Templ;
/*
templArgs:
    //TODO: to be TEXT_REF ... for now only syntax
    'Text' '&' identifier:name  templArgs_rest:args  =>  (name,TEXT_TYPE())::args
    |
    typeSig:ts  identifier:name  templArgs_rest:args  =>  (name,ts)::args
    |
    _  => {}
*/
public function templArgs
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypedIdents outArgs;
algorithm
  (outChars, outLineInfo, outArgs) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.Ident name;
      TplAbsyn.TypedIdents args;
      TplAbsyn.TypeSignature ts;

    //TODO: a HACK!!  ... just for now
    case ("T"::"e"::"x"::"t":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        ("&":: chars) = chars;
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, name) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, args) = templArgs_rest(chars, linfo);
      then (chars, linfo, (name,TplAbsyn.TEXT_TYPE())::args);

    case (chars, linfo)
      equation
        (chars, linfo, ts) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, name) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, args) = templArgs_rest(chars, linfo);
      then (chars, linfo, (name,ts)::args);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end templArgs;
/*
templArg0:
    typeSig:ts  implicitArgName:name  =>  (name,ts)

*/
/*
public function templArg0
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output tuple<TplAbsyn.Ident, TplAbsyn.TypeSignature> outArg;
algorithm
  (outChars, outLineInfo, outArg) := matchcontinue (inChars, inLineInfo)
    local
      String lesc, resc;
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      TplAbsyn.Ident name;
      TplAbsyn.TemplateDef td;
      TplAbsyn.TypedIdents args;
      TplAbsyn.Expression exp;
      TplAbsyn.TypeSignature ts;

    case (chars, linfo)
      equation
        (chars, linfo, ts) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, name) = implicitArgName(chars);
      then (chars, linfo, (name,ts));

  end matchcontinue;
end templArg0;
*/
/*
implicitArgName:
      IDENT:id  => id  //maybe 'it' explicitly
      |
      _  => 'it'


public function implicitArgName
  input list<String> inChars;

  output list<String> outChars;
  output TplAbsyn.Ident outArgName;
algorithm
  (outChars, outArgName) := matchcontinue (inChars)
    local
      String lesc, resc;
      list<String> chars;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      TplAbsyn.Ident name;
      TplAbsyn.TemplateDef td;
      TplAbsyn.TypedIdents args;
      TplAbsyn.Expression exp;
      TplAbsyn.TypeSignature ts;

    case (chars)
      equation
        (chars, name) = identifier(chars);
      then (chars, name);

    else (inChars, "it");

  end matchcontinue;
end implicitArgName;
*/


/*
templArgs_rest
  ',' typeSig:ts  argName_nonIt:name  templArgs_rest:rest  =>  (name,ts)::rest
  |
  _  => {}
*/
public function templArgs_rest
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypedIdents outArgs;
algorithm
  (outChars, outLineInfo, outArgs) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.Ident name;
      TplAbsyn.TypedIdents args;
      TplAbsyn.TypeSignature ts;
      TplAbsyn.TypedIdents rest;

    //TODO: a HACK!! ... just for now
    case ("," :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        ("T"::"e"::"x"::"t":: chars) = chars;
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        ("&":: chars) = chars;
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, name) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, args) = templArgs_rest(chars, linfo);
      then (chars, linfo, (name,TplAbsyn.TEXT_TYPE())::args);

    case ("," :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSigNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, name) = identifierNoOpt(chars, linfo);
        //(chars, linfo, name) = argName_nonIt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, rest) = templArgs_rest(chars, linfo);
      then (chars, linfo, (name,ts) :: rest);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end templArgs_rest;

/*
argName_nonIt:
      'it'  =>  Error("Implicit argument 'it' appeared at non-fist position in the template argument list. 'it' can be explicitly only as the first argument.")
      |
      IDENT:id  => id
*/
/*
public function argName_nonIt
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Ident outArgName;
algorithm
  (outChars, outLineInfo, outArgName) := matchcontinue (inChars, inLineInfo)
    local
      String lesc, resc;
      list<String> chars, startChars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      TplAbsyn.Ident name;
      TplAbsyn.TemplateDef td;
      TplAbsyn.TypedIdents args;
      TplAbsyn.Expression exp;
      TplAbsyn.TypeSignature ts;
      TplAbsyn.TypedIdents rest;

    case (startChars as ("i"::"t":: chars), linfo)
      equation
        afterKeyword(chars);
        (linfo) = parseError(startChars, linfo, "Implicit argument 'it' appeared at non-first position in the template argument list. 'it' can be explicitly only as the first argument.",
        false);
        //true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse error - implicit argument 'it' appeared at non-first position in the template argument list. 'it' can be explicitly only as the first argument.\n");
      then (chars, linfo, "#Error-displaced it#");

    case (chars, linfo)
      equation
        (chars, linfo, name) = identifierNoOpt(chars, linfo);
      then (chars, linfo, name);

  end matchcontinue;
end argName_nonIt;
*/

/*
expression(lesc,resc):
  expressionNoOptions(lesc,resc):exp  escapedOptions:opts
    => makeEscapedExp(exp, opts)
*/
public function expression
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  input Boolean isOptional;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc, isOptional)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression exp;
      list<TplAbsyn.EscOption> opts, indexOffsetOption;
      //LineColumnNumber startLCN;

    case (chars, linfo, lesc, resc, _)
      equation
        //startLCN = captureStartPosition(chars, linfo, 0);
        (chars, linfo, exp, indexOffsetOption) = expressionNoOptions(chars, linfo, lesc, resc);
        (chars, linfo, opts) = escapedOptions(chars, linfo, lesc, resc);
        opts = listAppend(indexOffsetOption, opts);
        //exp = makeEscapedExp(exp, listAppend(sopt,opts));
        exp = makeEscapedExp(chars, linfo, exp, opts);
      then (chars, linfo, exp);

    case (chars, linfo, _, _, false)
      equation
        (linfo) = parseError(chars, linfo, "Expecting an expression - not able to parse from this point.", true);
      then (chars, linfo, (TplAbsyn.ERROR_EXP(), dummySourceInfo));

  end matchcontinue;
end expression;


public function makeEscapedExp
  input list<String> inEndChars;
  input LineInfo inEndLineInfo;
  input TplAbsyn.Expression inExpression;
  input list<TplAbsyn.EscOption> inOptions;
  output TplAbsyn.Expression outExpression;
algorithm
  (outExpression) := match (inEndChars, inEndLineInfo, inExpression, inOptions)
    local
      TplAbsyn.Expression exp;
      list<TplAbsyn.EscOption> opts;
      SourceInfo sinfo;
   case (_, _, exp, {})  then exp;
   case (_, _, exp, opts as (_::_))
     equation
       sinfo = tplSourceInfo(startPositionFromExp(exp), inEndChars, inEndLineInfo);
     then ((TplAbsyn.ESCAPED(exp, opts), sinfo));
  end match;
end makeEscapedExp;

/*
escapedOptions(lesc,resc):
  ';' identifier:id  escOptionExp(lesc,resc):expOpt  escapedOptions(lesc,resc):opts
  => (id, expOpt) :: opts
  |
  _ => {}

*/
public function escapedOptions
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.EscOption> outOptions;
algorithm
  (outChars, outLineInfo, outOptions) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Ident id;
      Option<TplAbsyn.Expression> expOpt;
      list<TplAbsyn.EscOption> opts;

   case (";" :: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, id) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expOpt) = escOptionExp(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, opts) = escapedOptions(chars, linfo, lesc, resc);
      then (chars, linfo, (id, expOpt) :: opts);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end escapedOptions;

/*
escOptionExp(lesc,resc):
  '=' expressionLet(lesc,resc):exp
    => SOME(exp)
  |
  _ => NONE
*/
public function escOptionExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output Option<TplAbsyn.Expression> outExpOption;
algorithm
  (outChars, outLineInfo, outExpOption) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression exp;

    case ("=" :: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expressionLet(chars, linfo, lesc, resc);
      then (chars, linfo, SOME(exp));

    else (inChars, inLineInfo, NONE());

  end matchcontinue;
end escOptionExp;


/* not optional
expressionNoOptions(lesc,resc):
  expressionLet(lesc,resc):expLet  mapTailOpt(lesc,resc,expLet):exp
    => exp
*/
public function expressionNoOptions
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
  output list<TplAbsyn.EscOption> outIndexOffsetOption;
algorithm
  (outChars, outLineInfo, outExpression, outIndexOffsetOption)
   := match (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression exp;


   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = expressionLet(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp, outIndexOffsetOption)
         = mapTailOpt(chars, linfo, exp, lesc, resc);
      then (chars, linfo, exp, outIndexOffsetOption);

  end match;
end expressionNoOptions;

/*
mapTailOpt(headExp,lesc,resc):
  '|>' matchBinding:mexp
  indexedByOpt:idxNmOpt
  '=>' expressionLet(lesc,resc):exp  =>  MAP(headExp,mexp,exp)
  |
  _ => headExp
*/
public function mapTailOpt
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.Expression inHeadExpression;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
  output list<TplAbsyn.EscOption> outIndexOffsetOption;
algorithm
  (outChars, outLineInfo, outExpression, outIndexOffsetOption) := matchcontinue (inChars, inLineInfo, inHeadExpression, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      Option<TplAbsyn.Ident> idxNmOpt;
      TplAbsyn.Expression exp, headExp;
      TplAbsyn.MatchingExp mexp;
      SourceInfo sinfo;

    case ("|"::">":: chars, linfo, headExp, lesc, resc)
      equation
        //afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, idxNmOpt, outIndexOffsetOption) = indexedByOpt(chars, linfo, lesc, resc);
        (chars, linfo) = interleaveExpectChar(chars, linfo, "=");
        (chars, linfo) = expectChar(chars, linfo, ">");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expressionLet(chars, linfo, lesc, resc);
        sinfo = tplSourceInfo(startPositionFromExp(headExp), chars, linfo);
      then (chars, linfo, (TplAbsyn.MAP(headExp, mexp, exp, idxNmOpt), sinfo), outIndexOffsetOption);

    else (inChars, inLineInfo, inHeadExpression, {});

  end matchcontinue;
end mapTailOpt;

/*
indexedByOpt:
  'hasindex' identifier:id
    => SOME(id)
  |
  _ => NONE
*/
public function indexedByOpt
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output Option<TplAbsyn.Ident> outIndexNameOpt;
  output list<TplAbsyn.EscOption> outIndexOffsetOption;
algorithm
  (outChars, outLineInfo, outIndexNameOpt, outIndexOffsetOption)
   := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Ident id;

    case ("h"::"a"::"s"::"i"::"n"::"d"::"e"::"x":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars,linfo,id) = identifierNoOpt(chars,linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, outIndexOffsetOption) = fromOpt(chars, linfo, lesc, resc);
      then (chars, linfo, SOME(id), outIndexOffsetOption);

    else (inChars, inLineInfo, NONE(), {});

  end matchcontinue;
end indexedByOpt;

/*
fromOpt:
  'fromindex' expression_base:expFrom
    => { ("$indexOffset", SOME(expFrom)) }
  |
  _ => {}
*/
public function fromOpt
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.EscOption> outIndexOffsetOption;
algorithm
  (outChars, outLineInfo, outIndexOffsetOption)
   := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression exp;

    case ("f"::"r"::"o"::"m"::"i"::"n"::"d"::"e"::"x":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression_base(chars, linfo, lesc, resc);
      then (chars, linfo, {(TplAbsyn.indexOffsetOptionId, SOME(exp))});

    //deprecated keyword, this check will be removed after some time (if needed)
    case ("f"::"r"::"o"::"m":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        linfo = parseError(chars, linfo, "Keyword 'from' was changed to 'fromindex', please update your source code here.", false);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression_base(chars, linfo, lesc, resc);
      then (chars, linfo, {(TplAbsyn.indexOffsetOptionId, SOME(exp))});

    else (inChars, inLineInfo, {});

  end matchcontinue;
end fromOpt;


/*
expressionLet(lesc,resc):
  'let' letExp(lesc,resc):lexp  concatLetExp_rest(lesc,resc):expLst
     => TEMPLATE(lexp::expLst}, "let", ""); //TODO: should be a LET_EXPRESSION()
  |
  expressionMatch(lesc,resc):exp
*/
public function expressionLet
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars, startChars;
      LineInfo linfo, startLInfo;
      String  lesc, resc;
      TplAbsyn.Expression exp,  lexp;
      SourceInfo sinfo;

    case ("l"::"e"::"t" :: startChars, startLInfo, lesc, resc)
      equation
        afterKeyword(startChars);
        (chars, linfo) = interleave(startChars, startLInfo);
        (chars, linfo, lexp) = letExp(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expressionLet(chars, linfo, lesc, resc);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 3), chars, linfo);
        //(chars, linfo, expLst) = concatLetExp_rest(chars, linfo, lesc, resc);
      then (chars, linfo, (TplAbsyn.LET(lexp, exp), sinfo));

    case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = expressionMatch(chars, linfo, lesc, resc);
      then (chars, linfo, exp);

  end matchcontinue;
end expressionLet;

/*
concatLetExp_rest(lesc,resc):
  'let' letExp(lesc,resc):lexp  concatLetExp_rest(lesc,resc):expLst
    =>  lexp::expLst
  |
  expression(lesc,resc):exp
    => {exp}
*/
/*
public function concatLetExp_rest
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.Expression> outExpressionList;
algorithm
  (outChars, outLineInfo, outExpressionList) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, lexp;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.MatchingExp mexp;

    case ("l"::"e"::"t":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, lexp) = letExp(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = concatLetExp_rest(chars, linfo, lesc, resc);
      then (chars, linfo, lexp::expLst);

    case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = expressionMatch(chars, linfo, lesc, resc);
      then (chars, linfo, {exp});

  end matchcontinue;
end concatLetExp_rest;
*/

/*
must not fail - not optional, at least one must match
letExp(lesc,resc):
  '&' identifier:id '=' 'buffer' expression(lesc,resc):exp
       => TEXT_CREATE(id,exp)
  |
  '&' identifier:id '+=' expression(lesc,resc):exp
       => TEXT_ADD(id,exp)
  |
  '()' '=' pathIdent:name  funCall(name,lesc,resc):exp
       =>  exp //TODO: noRetCall expression should be here
  |
  identifier:id '=' expression(lesc,resc):exp
    => TEXT_CREATE(id,exp) //TODO: !! a HACK for now

  //TODO:
  |
  letBinding:bd '=' expression(lesc,resc):exp
    =>  LET_BINDING(bd, exp)
*/
public function letExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars, startChars;
      LineInfo linfo, startLInfo;
      String lesc, resc;
      TplAbsyn.PathIdent name;
      TplAbsyn.Expression exp;
      list<TplAbsyn.Expression> args;
      TplAbsyn.Ident id;
      //LineColumnNumber startLCN;
      SourceInfo sinfo;

  case ("&":: startChars, startLInfo, lesc, resc)
      equation
        (chars, linfo) = interleave(startChars, startLInfo);
        (chars, id) = identifier(chars);
        //capture only ident span for the letExp, the exp will have its own span
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 1), chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        ("=":: chars) = chars;
        (chars, linfo) = interleaveExpectKeyWord(chars, linfo, {"b","u","f","f","e","r"}, false);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc, false);
      then (chars, linfo, (TplAbsyn.TEXT_CREATE(id, exp), sinfo));

  case ("&":: startChars, startLInfo, lesc, resc)
      equation
        (chars, linfo) = interleave(startChars, startLInfo);
        (chars, id) = identifier(chars);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 1), chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        ("+"::"=":: chars) = chars;
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc, false);
      then (chars, linfo, (TplAbsyn.TEXT_ADD(id, exp), sinfo));

  case ("&":: startChars, startLInfo, _, _)
      equation
        (chars, linfo) = interleave(startChars, startLInfo);
        (chars, linfo,_) = identifierNoOpt(chars, linfo);
        linfo = parseError(chars, linfo, "Expecting a '=' or '+=' text variable creation/addition (&var = exp or &var += exp) at the position.", true);
      then (chars, linfo, (TplAbsyn.ERROR_EXP(), dummySourceInfo));


  case ("("::")":: startChars, startLInfo, lesc, resc)
      equation
        (chars, linfo) = interleaveExpectChar(startChars, startLInfo, "=");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, name) = pathIdentNoOpt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, TplAbsyn.FUN_CALL(name, args)) = funCall(chars, linfo, name, lesc, resc);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 2), chars, linfo);
      then (chars, linfo, (TplAbsyn.NORET_CALL(name, args), sinfo));

  case ("("::")":: startChars, startLInfo, _, _)
      equation
        (chars, linfo) = interleaveExpectChar(startChars, startLInfo, "=");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo,_) = pathIdentNoOpt(chars, linfo);
        //(chars, linfo) = interleaveExpectChar(chars, linfo, "(");
        linfo = parseError(chars, linfo, "Expecting a non-return function call( let () = [package.]funName(args,...) ) at the position.", true);
      then (chars, linfo, (TplAbsyn.ERROR_EXP(), dummySourceInfo));

  //TODO: to be  letBinding:bd '=' expression(lesc,resc):exp    =>  LET_BINDING(bd, exp)
  case (startChars, startLInfo, lesc, resc)
      equation
        (chars, linfo, id) = identifierNoOpt(startChars, startLInfo);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 0), chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = interleaveExpectChar(chars, linfo, "=");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc, false);
      then (chars, linfo, (TplAbsyn.TEXT_CREATE(id, exp), sinfo));

  //case (chars, linfo, lesc, resc)
  //    equation
  //      linfo = parseError(chars, linfo, "Expecting a let-expression: no-return function call ( ()=funName(...) ) or text variable binding/creation/addition (var = exp, &var = exp or &var += exp) at the position.", true);
  //    then (chars, linfo, TplAbsyn.ERROR_EXP());


   else
     equation
       if Flags.isSet(Flags.FAILTRACE) then
         Debug.trace("!!!Parse error - TplParser.letExp failed.\n");
       end if;
     then fail();
  end matchcontinue;
end letExp;


/*
expressionMatch(lesc,resc):
  matchExp(lesc,resc):exp
    => exp
  |
  expressionIf(lesc,resc):exp
    => exp
*/
public function expressionMatch
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression exp;

   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = matchExp(chars, linfo, lesc, resc);
      then (chars, linfo, exp);

   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = expressionIf(chars, linfo, lesc, resc);
      then (chars, linfo, exp);

  end matchcontinue;
end expressionMatch;

/*
expressionIf(lesc,resc):
  conditionExp(lesc,resc):exp
    => exp
  |
  expressionPlus(lesc,resc):exp
    => exp
*/
public function expressionIf
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression exp;

   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = conditionExp(chars, linfo, lesc, resc);
      then (chars, linfo, exp);

   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = expressionPlus(chars, linfo, lesc, resc);
      then (chars, linfo, exp);

  end matchcontinue;
end expressionIf;


/*
expressionPlus(lesc,resc):
  expression_base(lesc,resc):bexp  plusTailOpt(lesc,resc,bexp):exp
    => exp
*/
public function expressionPlus
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := match (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression exp;

   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = expression_base(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = plusTailOpt(chars, linfo, exp, lesc, resc);
      then (chars, linfo, exp);

  end match;
end expressionPlus;

/*
plusTailOpt(lesc,resc,bexp):
  '+' expression_base(lesc,resc):exp  concatExp_rest(lesc,resc):expLst   //  concatenation same as "<expression><expression>"
    => TEMPLATE(bexp::exp::expLst, "+", "");
  |
  _ => bexp
*/
public function plusTailOpt
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.Expression inBaseExpression;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inBaseExpression, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression exp, bexp;
      list<TplAbsyn.Expression> expLst;
      SourceInfo sinfo;

    case ("+" :: chars, linfo, bexp, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression_base(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = concatExp_rest(chars, linfo, lesc, resc);
        sinfo = tplSourceInfo(startPositionFromExp(bexp), chars, linfo);
      then (chars, linfo, (TplAbsyn.TEMPLATE(bexp::exp::expLst, "+", ""), sinfo));

    else (inChars, inLineInfo, inBaseExpression);

  end matchcontinue;
end plusTailOpt;


/*
concatExp_rest(lesc,resc):
  '+' expression_base(lesc,resc):exp  concatExp_rest(lesc,resc):expLst  =>  exp::expLst
  |
  _ => {}
*/
public function concatExp_rest
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.Expression> outExpressionList;
algorithm
  (outChars, outLineInfo, outExpressionList) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression exp;
      list<TplAbsyn.Expression> expLst;

    case ("+":: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression_base(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = concatExp_rest(chars, linfo, lesc, resc);
      then (chars, linfo, exp::expLst);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end concatExp_rest;


/*
expression_base(lesc,resc):
  stringConstant:strRevList
    => STR_TOKEN(makeStrTokFromRevStrList(strRevList))
  |
  literalConstant:(str,litType)
    => LITERAL(str,litType)
  |
  templateExp(lesc,resc)
  |
  '{' '}'  => MAP_ARG_LIST({})
  |
  '{' expressionPlus(lesc,resc):exp  expressionList_rest(lesc,resc):expLst '}'   //  list construction with possible mixed scalars and lists
                                                             // useful in map/concatenation context
     => MAP_ARG_LIST(exp::expLst)
  |
  '(' expression(lesc,resc):exp ')'
     => exp
  |
  '&' identifier:id
    => BOUND_VALUE(IDENT(name))  //TODO: ref Text buffer
  |// TODO: create an optional/error reporting variant of pathIdent
  pathIdent:name  boundValueOrFunCall(name,lesc,resc):exp  =>  exp
*/
public function expression_base
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars, startChars, strRevList;
      LineInfo linfo, startLInfo;
      String  lesc, resc, str;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp;
      TplAbsyn.ExpressionBase expB;
      list<TplAbsyn.Expression> expLst;
      //LineColumnNumber startLCN;
      SourceInfo sinfo;

    case (startChars, startLInfo, _, _)
      equation
        //startLCN = captureStartPosition(chars, linfo, 0);
        (chars, linfo, strRevList) = stringConstant(startChars, startLInfo);
        st = makeStrTokFromRevStrList(strRevList);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 0), chars, linfo);
      then (chars, linfo, (TplAbsyn.STR_TOKEN(st), sinfo));

    case (startChars, startLInfo, _, _)
      equation
        (chars, linfo, str, ts) = literalConstant(startChars, startLInfo);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 0), chars, linfo);
      then (chars, linfo, (TplAbsyn.LITERAL(str, ts), sinfo));

   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = templateExp(chars, linfo, lesc, resc);
      then (chars, linfo, exp);

   case ("{" :: startChars, startLInfo, _, _)
      equation
        (chars, linfo) = interleave(startChars, startLInfo);
        ("}" :: chars) = chars;
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 1), chars, linfo);
      then (chars, linfo, (TplAbsyn.MAP_ARG_LIST({}), sinfo));

   case ("{" :: startChars, startLInfo, lesc, resc)
      equation
        (chars, linfo) = interleave(startChars, startLInfo);
        (chars, linfo, exp) = expressionPlus(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = expressionList_rest(chars, linfo, lesc, resc);
        (chars, linfo) = interleaveExpectChar(chars, linfo, "}");
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 1), chars, linfo);
      then (chars, linfo, (TplAbsyn.MAP_ARG_LIST(exp::expLst), sinfo));

   case ("(" :: startChars, startLInfo, lesc, resc)
      equation
        (chars, linfo) = interleave(startChars, startLInfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc, false);
        (chars, linfo) = interleaveExpectChar(chars, linfo, ")");
      then (chars, linfo, exp);

   //TODO: be a ref Text buffer
   case ("&" :: startChars, startLInfo, _, _)
      equation
        (chars, linfo) = interleave(startChars, startLInfo);
        (chars, linfo, id) = identifierNoOpt(chars, linfo);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 1), chars, linfo);
      then (chars, linfo, (TplAbsyn.BOUND_VALUE(TplAbsyn.IDENT(id)), sinfo));

   case (startChars, startLInfo, lesc, resc)
      equation
        (chars, linfo, name) = pathIdent(startChars, startLInfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expB) = boundValueOrFunCall(chars, linfo, name, lesc, resc);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 0), chars, linfo);
      then (chars, linfo, (expB, sinfo));

  end matchcontinue;
end expression_base;


/*
boundValueOrFunCall(name,lesc,resc):
  funCall(name,lesc,resc):exp  => exp
  |
  _ => BOUND_VALUE(name)
*/
public function boundValueOrFunCall
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.PathIdent inName;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.ExpressionBase outExpressionBase;
algorithm
  (outChars, outLineInfo, outExpressionBase) :=
  matchcontinue (inChars, inLineInfo, inName, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String lesc, resc;
      TplAbsyn.PathIdent name;
      TplAbsyn.ExpressionBase expB;

    case (chars, linfo, name, lesc, resc)
      equation
        (chars, linfo, expB) = funCall(chars, linfo, name, lesc, resc);
      then (chars, linfo, expB);

    else (inChars, inLineInfo, TplAbsyn.BOUND_VALUE(inName));

  end matchcontinue;
end boundValueOrFunCall;

/*
//may fail
funCall(name,lesc,resc):
  '(' ')' => FUN_CALL(name,{})
  |
  '(' expression(lesc,resc):exp  expressionList_rest(lesc,resc):expLst ')'  //template  or  intrinsic function
    => FUN_CALL(name,exp::expLst)
*/
public function funCall
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.PathIdent inName;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.ExpressionBase outExpressionBase;
algorithm
  (outChars, outLineInfo, outExpressionBase) := matchcontinue (inChars, inLineInfo, inName, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String lesc, resc;
      TplAbsyn.PathIdent name;
      TplAbsyn.Expression exp;
      list<TplAbsyn.Expression> expLst;

    case ("(":: chars, linfo, name, _, _)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (")" :: chars) = chars;
      then (chars, linfo, TplAbsyn.FUN_CALL(name,{}));

    case ("(":: chars, linfo, name, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expressionPlus(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = expressionList_rest(chars, linfo, lesc, resc);
        (chars, linfo) = interleaveExpectChar(chars, linfo, ")");
      then (chars, linfo, TplAbsyn.FUN_CALL(name, exp::expLst));

  end matchcontinue;
end funCall;

/*
expressionList_rest(lesc,resc):
  ',' expressionPlus(lesc,resc):exp  expressionList_rest(lesc,resc):expLst => exp::expLst
  |
  _ => {}
*/
public function expressionList_rest
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.Expression> outExpressionList;
algorithm
  (outChars, outLineInfo, outExpressionList) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression exp;
      list<TplAbsyn.Expression> expLst;

    case (",":: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expressionPlus(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = expressionList_rest(chars, linfo, lesc, resc);
      then (chars, linfo, exp::expLst);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end expressionList_rest;


/*
stringConstant:
  '"' doubleQuoteConst({},{}):stRevLst
    => stRevLst
  |
  //'%'(lquot) stripFirstNewLine verbatimConst(Rquote(lquot),{},{}):stRevLst
  //  => stRevLst
  //|
  '\\n' escUnquotedChars({}, {"\n"}):stRevLst
    => stRevLst
  |
  '\\' escChar:c  escUnquotedChars({c}, {}):stRevLst
    => stRevLst
*/
public function stringConstant
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<String> outStrRevList;
algorithm
  (outChars, outLineInfo, outStrRevList) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, startChars,  stRevLst;
      LineInfo linfo, startLinfo;
      String    c;
      Option<String> optError;

    case (startChars as ("\"" :: chars), startLinfo)
      equation
        (chars, linfo, stRevLst, optError) = doubleQuoteConst(chars, startLinfo,{},{});
        linfo = parseErrorPrevPositionOpt(startChars, startLinfo, linfo, optError, true);
      then (chars, linfo, stRevLst);

    /*
    case (startChars as ("%"::lquot:: chars), startLinfo)
      equation
        (chars, linfo) = stripFirstNewLine(chars, startLinfo);
        rquot = rightVerbatimConstQuote(lquot);
        (chars, linfo, stRevLst, optError) = verbatimConst(chars, linfo, rquot,{},{});
        linfo = parseErrorPrevPositionOpt(startChars, startLinfo, linfo, optError, true);
      then (chars, linfo, stRevLst);
    */

    case ("\\"::"n":: chars, linfo)
      equation
        (chars, linfo, stRevLst) = escUnquotedChars(chars, linfo, {},{"\n"});
      then (chars, linfo, stRevLst);

    case ("\\":: c :: chars, linfo)
      equation
        c = escChar(c);
        (chars, linfo,stRevLst) = escUnquotedChars(chars, linfo, {c},{});
      then (chars, linfo, stRevLst);

  end matchcontinue;
end stringConstant;

/*
//not optional, must not fail
literalConstant:
  //(+|-)?d*(.d+)?(('e'|'E')(+|-)?d+)?
  plusMinus:pm digits:ds dotNumber:(dn,ts) exponent(ts):(ex,ts)
  => (pm+ stringCharListString(ds)+dn+ex, ts)  //validate the number - must have integer part or dotpart
  |
  'true' => ("true", BOOLEAN_TYPE())
  |
  'false' => ("false", BOOLEAN_TYPE())
*/
public function literalConstant
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output String outConstantValue;
  output TplAbsyn.TypeSignature outConstantType;
algorithm
  (outChars, outLineInfo, outConstantValue, outConstantType) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, ds;
      LineInfo linfo;
      String pm, dn,ex, num;
      TplAbsyn.TypeSignature ts;

     case (chars, linfo)
      equation
        (chars, pm) = plusMinus(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, ds) = digits(chars);
        (chars, dn, ts) = dotNumber(chars);
        //validate the number - must have integer part or dotpart
        num = stringCharListString(ds)+dn;
        true = stringLength(num) > 0;
        (chars, ex, ts) = exponent(chars,ts);
        num = pm + num + ex;
      then (chars, linfo, num, ts);

    case ("t"::"r"::"u"::"e" :: chars, linfo)
      equation
        afterKeyword(chars);
      then (chars, linfo, "true",TplAbsyn.BOOLEAN_TYPE());

    case ("f"::"a"::"l"::"s"::"e" :: chars, linfo)
      equation
        afterKeyword(chars);
      then (chars, linfo, "false",TplAbsyn.BOOLEAN_TYPE());

  end matchcontinue;
end literalConstant;


public function stripFirstNewLine
  input list<String> inChars;
  input LineInfo inLineInfo;
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
    case (chars, linfo)
      equation
        (chars, linfo) = newLine(chars, linfo);
      then (chars, linfo);
    else (inChars, inLineInfo);
  end matchcontinue;
end stripFirstNewLine;

public function rightVerbatimConstQuote
  input  String inLeftQuote;
  output String outRightQuote;
algorithm
  (outRightQuote) := match (inLeftQuote)
    case ("(" ) then ")";
    case ("{" ) then "}";
    case ("<" ) then ">";
    case ("[" ) then "]";
    else inLeftQuote;
  end match;
end rightVerbatimConstQuote;

/*
doubleQuoteConst(accChars,accStrList):
  '"' => stringCharListString(listReverse(accChars)) :: accStrList
  |
  newLine doubleQuoteConst({}, stringCharListString(listReverse('\n'::accChars))::accStrList):stRevLst
  => stRevLst
  |
  '\\n' doubleQuoteConst({}, stringCharListString(listReverse('\n'::accChars))::accStrList):stRevLst
  => stRevLst
  |
  '\\'escChar:c doubleQuoteConst(c::accChars,accStrList):stRevLst
  => stRevLst
  |
  c doubleQuoteConst(c::accChars,accStrList):stRevLst
  => stRevLst
  |
  Error end of file
*/
public function doubleQuoteConst
  input list<String> inChars;
  input LineInfo inLineInfo;
  input list<String> inAccChars;
  input list<String> inAccStrList;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<String> outStrRevList;
  output Option<String> outError;
algorithm
  (outChars, outLineInfo, outStrRevList, outError) := matchcontinue (inChars, inLineInfo, inAccChars, inAccStrList)
    local
      list<String> chars, restChars, accChars, accStrList, stRevLst;
      LineInfo linfo;
      String c, str, errStr;
      Option<String> optError;

    case ("\"" :: chars, linfo, accChars, accStrList)
      equation
        str = stringCharListString(listReverse(accChars));
      then (chars, linfo, str :: accStrList,NONE());

    //escaped new line
    case ("\\"::"n" :: chars, linfo, accChars, accStrList)
      equation
        str = stringCharListString(listReverse("\n"::accChars));
        (chars, linfo,stRevLst, optError) = doubleQuoteConst(chars, linfo,{},str :: accStrList);
      then (chars, linfo, stRevLst, optError);

    case ("\\":: c :: chars, linfo, accChars, accStrList)
      equation
        c = escChar(c);
        (chars, linfo,stRevLst,optError) = doubleQuoteConst(chars, linfo, c::accChars, accStrList);
      then (chars, linfo, stRevLst,optError);

    //inline new line
    case (chars, linfo, accChars, accStrList)
      equation
        (chars, linfo) = newLine(chars, linfo);
        str = stringCharListString(listReverse("\n"::accChars));
        (chars, linfo,stRevLst,optError) = doubleQuoteConst(chars, linfo,{},str :: accStrList);
      then (chars, linfo, stRevLst, optError);

    case (chars as (c :: restChars), linfo, accChars, accStrList)
      equation
        failure((_, _) = newLine(chars, linfo));
        (chars, linfo,stRevLst,optError) = doubleQuoteConst(restChars, linfo, c::accChars, accStrList);
      then (chars, linfo, stRevLst,optError);

    case ( {}, linfo, accChars, accStrList)
      equation
        str = stringCharListString(listReverse(accChars));
        errStr = "Unmatched \" \" quotes for a string constant - reached end of file.";
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("Parse error - TplParser.doubleQuoteConst - " + errStr + "\n");
        end if;
      then ({}, linfo, str :: accStrList, SOME(errStr));

  end matchcontinue;
end doubleQuoteConst;

/*
escChar:
  ( '\'' | '"' | '?' |  '\\' | 'a' | 'b' | 'f' | 'n' | 'r' | 't' | 'v' | ' ' )
  => the escaped char

*/
public function escChar
  input  String inEscChar;
  output String outTheChar;
algorithm
  (outTheChar) := match (inEscChar)
    case ("'" ) then "'";
    case ("\"" ) then "\"";
    case ("?" ) then "?";
    case ("\\" ) then "\\";
    /*
    //TODO: Error in the .srz or .c compilation(\r)
    case ("a" ) then "\a";
    case ("b" ) then "\b";
    case ("f" ) then "\f";
    case ("r" ) then "\r";
    case ("v" ) then "\v";
    */
    case ("n" ) then "\n";
    case ("t" ) then "\t";
    case (" " ) then " ";
  end match;
end escChar;

/*
verbatimConst(rquot, accChars, accStrList):
  //strip a last inline new line
  newLine (rquot)'%' =>  stringCharListString(listReverse(accChars)) :: accStrList
  |
  (rquot)'%' =>  stringCharListString(listReverse(accChars)) :: accStrList
  |
  newLine verbatimConst(rquot, {}, stringCharListString(listReverse('\n'::accChars))::accStrList):stRevLst
    => stRevLst
  |
  c  verbatimConst(rquot, c::accChars,accStrList):stRevLst
    => stRevLst
  |
  Error end of file
*/
public function verbatimConst
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inRightQuote;
  input list<String> inAccChars;
  input list<String> inAccStrList;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<String> outStrRevList;
  output Option<String> outError;
algorithm
  (outChars, outLineInfo, outStrRevList, outError) := matchcontinue (inChars, inLineInfo, inRightQuote, inAccChars, inAccStrList)
    local
      list<String> chars, restChars, accChars, accStrList, stRevLst;
      LineInfo linfo;
      String lquot,rquot,c,str, errStr;
      Option<String> optError;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> rtag;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;

    //strip a last inline new line
    case (chars, linfo, rquot, accChars, accStrList)
      equation
        (chars, linfo) = newLine(chars, linfo);
        (c :: "%" :: chars) = chars;
        true = stringEq(c, rquot);
        str = stringCharListString(listReverse(accChars));
      then (chars, linfo, str :: accStrList,NONE());

    case (c :: "%" :: chars, linfo, rquot, accChars, accStrList)
      equation
        true = stringEq(c, rquot);
        str = stringCharListString(listReverse(accChars));
      then (chars, linfo, str :: accStrList,NONE());

    case (chars, linfo, rquot, accChars, accStrList)
      equation
        (chars, linfo) = newLine(chars, linfo);
        str = stringCharListString(listReverse("\n"::accChars));
        (chars, linfo, stRevLst, optError) = verbatimConst(chars, linfo,rquot,{}, str :: accStrList);
      then (chars, linfo, stRevLst, optError);

    case (chars as (c :: restChars), linfo, rquot, accChars, accStrList)
      equation
        failure((_, _) = newLine(chars, linfo));
        (chars, linfo, stRevLst, optError) = verbatimConst(restChars, linfo, rquot, c::accChars, accStrList);
      then (chars, linfo, stRevLst, optError);

    case ( {}, linfo, rquot, accChars, accStrList)
      equation
        str = stringCharListString(listReverse(accChars));
        errStr = "Unmatched %"+rquot+" "+rquot+"% quotes for a verbatim string constant - reached end of file.";
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse error - TplParser.verbatimConst - " + errStr + "\n");
      then ({}, linfo, str :: accStrList, SOME(errStr));

  end matchcontinue;
end verbatimConst;

/*
escUnquotedChars(accChars,accStrList):
  '\\n' escUnquotedChars({}, stringCharListString(listReverse('\n'::accChars)) :: accStrList):stRevLst
  => stRevLst
  |
  '\\' escChar:c  escUnquotedChars(c::accChars, accStrList):stRevLst
  => stRevLst
  |
  _ => stringCharListString(listReverse(accChars)) :: accStrList

*/
public function escUnquotedChars
  input list<String> inChars;
  input LineInfo inLineInfo;
  input list<String> inAccChars;
  input list<String> inAccStrList;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<String> outStrRevList;
algorithm
  (outChars, outLineInfo, outStrRevList) := matchcontinue (inChars, inLineInfo, inAccChars, inAccStrList)
    local
      list<String> chars, accChars, accStrList, stRevLst;
      LineInfo linfo;
      String c, str;

    case ("\\":: "n" :: chars, linfo, accChars, accStrList)
      equation
       str = stringCharListString(listReverse("\n"::accChars));
       (chars, linfo,stRevLst) = escUnquotedChars(chars, linfo,{},str :: accStrList);
      then (chars, linfo, stRevLst);

    case ("\\":: c :: chars, linfo, accChars, accStrList)
      equation
        c = escChar(c);
        (chars, linfo,stRevLst) = escUnquotedChars(chars, linfo, c::accChars, accStrList);
      then (chars, linfo, stRevLst);

    case (chars, linfo, accChars, accStrList)
      equation
        str = stringCharListString(listReverse(accChars));
      then (chars, linfo, str :: accStrList);

  end matchcontinue;
end escUnquotedChars;


public function makeStrTokFromRevStrList
  input list<String> inRevStrList;
  output Tpl.StringToken outStringToken;
algorithm
  (outStringToken) := matchcontinue (inRevStrList)
    local
      list<String> strList;
      String str;

    case ( { str } )
      then Tpl.ST_STRING(str);

    case ( { "", "\n" } )
      then Tpl.ST_NEW_LINE();

    case ( { "" , str} )
      then Tpl.ST_LINE(str);

    case ( "" :: strList )
      equation
        strList = listReverse(strList);
      then Tpl.ST_STRING_LIST(strList, true);

    case ( strList as (_ :: _))
      equation
        strList = listReverse(strList);
      then Tpl.ST_STRING_LIST(strList, false);

    // should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("Parse invalid operation error - TplParser.makeStrTokFromRevStrList failed (an empty string list passed?) .\n");
      then fail();

  end matchcontinue;
end makeStrTokFromRevStrList;

/*
plusMinus:
  '+' => "+"
  |
  '-' => "-"
  |
  _ => ""
*/
public function plusMinus
  input list<String> inChars;

  output list<String> outChars;
  output String outSign;
algorithm
  (outChars, outSign) := match (inChars)
    local
      list<String> chars;
      String char;

    case (char :: chars) guard char=="+" or char=="-"
      then (chars, char);

    else
      then (inChars, "");

  end match;
end plusMinus;
/*
digits:
  [0-9]:d  digits:ds => d::ds
  |
  _ => {}
*/
public function digits
  input list<String> inChars;

  output list<String> outChars;
  output list<String> outDigits;
algorithm
  (outChars, outDigits) := matchcontinue (inChars)
    local
      String d;
      list<String> chars, ds;
      Integer i;

    case (d :: chars)
      equation
        i = stringCharInt(d);
        //[0-9]
        true = ( 48/*0*/ <= i and i <= 57/*9*/);
        (chars,ds) = digits(chars);
      then (chars, d::ds);

    case (chars)
      then (chars, {});

  end matchcontinue;
end digits;
/*
dotNumber:
  '.' digits:ds  =>  (stringCharListString(ds), REAL_TYPE())
  |
  _ => INTEGER_TYPE()
*/
public function dotNumber
  input list<String> inChars;

  output list<String> outChars;
  output String outDotNumber;
  output TplAbsyn.TypeSignature outLitType;
algorithm
  (outChars, outDotNumber, outLitType) := matchcontinue (inChars)
    local
      String dn;
      list<String> chars, ds;

    case ("." :: chars)
      equation
        (chars,ds) = digits(chars);
        (_::_) = ds; //some digits must be there
        dn = "." + stringCharListString(ds);
      then (chars, dn, TplAbsyn.REAL_TYPE());

    else (inChars, "", TplAbsyn.INTEGER_TYPE());

  end matchcontinue;
end dotNumber;

/*
exponent(typ):
  'e' plusMinus:pm  digits:ds => ("e"+pm+stringCharListString(ds), REAL_TYPE())
  |
  'E' plusMinus:pm  digits:ds => ("E"+pm+stringCharListString(ds), REAL_TYPE())
  |
  => ("",typ)
*/
public function exponent
  input list<String> inChars;
  input TplAbsyn.TypeSignature inLitType;

  output list<String> outChars;
  output String outExponent;
  output TplAbsyn.TypeSignature outLitType;
algorithm
  (outChars,outExponent,outLitType) := matchcontinue (inChars,inLitType)
    local
      String ex,pm;
      list<String> chars, ds;
      TplAbsyn.TypeSignature litType;

    case ("e" :: chars, _)
      equation
        (chars,pm) = plusMinus(chars);
        (chars,ds) = digits(chars);
        (_::_) = ds; //some digits must be there
        ex = "e" + pm + stringCharListString(ds);
      then (chars, ex, TplAbsyn.REAL_TYPE());

    case ("E" :: chars, _)
      equation
        (chars,pm) = plusMinus(chars);
        (chars,ds) = digits(chars);
        (_::_) = ds; //some digits must be there
        ex = "E" + pm + stringCharListString(ds);
      then (chars, ex, TplAbsyn.REAL_TYPE());

    else (inChars, "", inLitType);

  end matchcontinue;
end exponent;

/*
templateExp(lesc, resc):
  "'" stripFirstNewLine  templateBody(lesc, resc, isSingleQuote = true, {},{},0)
  |
  '<<' stripFirstNewLine templateBody(lesc, resc, isSingleQuote = false,{},{},0 )
*/
public function templateExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars, startChars, solChars;
      LineInfo linfo, startLInfo;
      String  lesc, resc;
      TplAbsyn.ExpressionBase expB;
      Integer baseInd, lineInd;
      SourceInfo sinfo;

   case ("'" :: startChars, startLInfo, lesc, resc)
      equation
        //single quotes has no special treatment of indent and new lines
        //i.e., it takes O as the base indent, and it counts every new line
        (chars, linfo, expB) = templateBody(startChars, startLInfo, lesc, resc, true, {},{},0);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 1), chars, linfo);
      then (chars, linfo, (expB, sinfo));

   case ("<"::"<":: startChars, startLInfo as LINE_INFO(startOfLineChars = solChars), lesc, resc)
      equation
        //the base indent is the indent of the line where the << appears
        (_, baseInd) = lineIndent(solChars,0);
        //the case when nothing visible is after <<
        (chars, linfo) = takeSpaceAndNewLine(startChars, startLInfo);
        //(chars, linfo) = templStripFirstNewLine(chars, linfo);
        (chars, linfo, expB) = templateBody(chars, linfo, lesc, resc, false, {}, {}, baseInd);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 2), chars, linfo);
      then (chars, linfo, (expB, sinfo));

   //special treatment when some non-space is right after <<
   case ("<"::"<":: startChars, startLInfo as LINE_INFO(startOfLineChars = solChars), lesc, resc)
      equation
        //the base indent is the indent of the line where the << appears
        (_, baseInd) = lineIndent(solChars,0);
        //some non-space char(s) is after <<
        failure( (_,_) = takeSpaceAndNewLine(startChars, startLInfo) );
        (chars, lineInd) = lineIndent(startChars,0);
        //correct the indent of the line right after << to baseInd
        lineInd = lineInd + baseInd;
        (chars, linfo, expB) = restOfTemplLine(chars, startLInfo, lesc, resc, false, {}, {}, baseInd, lineInd);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 2), chars, linfo);
      then (chars, linfo, (expB, sinfo));
  end matchcontinue;
end templateExp;



/*
//optional, may fail
takeSpaceAndNewLine:
  newLine
  |
  ' ' takeSpaceAndNewLine
  |
  '\t' takeSpaceAndNewLine
*/
public function takeSpaceAndNewLine
  input list<String> inChars;
  input LineInfo inLineInfo;
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      String char;

   case (chars, linfo)
     equation
       (chars, linfo) = newLine(chars, linfo);
     then (chars, linfo);

   case (char :: chars, linfo) guard char==" " or char =="\t"
      equation
       (chars, linfo) = takeSpaceAndNewLine(chars, linfo);
      then (chars, linfo);
  end matchcontinue;
end takeSpaceAndNewLine;

/*
templateBody(lesc, resc, isSingleQuote, expList, indStack, actInd):
  lineIndent(0):lineInd
    restOfTemplLine(lesc, resc, isSingleQuote, expList, indStack, actInd, lineInd, {}):exp
  => exp
*/
public function templateBody
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  input Boolean inIsSingleQuote;
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.ExpressionBase outExpressionBase;
protected
  Integer lindent;
algorithm
  (outChars, lindent) := lineIndent(inChars, 0);
  (outChars, outLineInfo, outExpressionBase) := restOfTemplLine(outChars,
    inLineInfo, inLeftEsc, inRightEsc, inIsSingleQuote, inExpressionList,
    inIndentStack, inActualIndent, lindent);
end templateBody;

/*
lineIndent(ind):
  ' ' lineIndent(ind+1):n  =>  n
  |
  '\t' lineIndent(ind+4):n  =>  n
  |
  _  =>  ind

*/
public function lineIndent
  input list<String> inChars;
  input Integer inLineIndent;

  output list<String> outChars;
  output Integer outLineIndent;
algorithm
  (outChars, outLineIndent) := match inChars
    case " "  :: outChars then lineIndent(outChars, inLineIndent + 1);
    case "\t" :: outChars then lineIndent(outChars, inLineIndent + TabSpaces);
    else (inChars, inLineIndent);
  end match;
end lineIndent;
/*
// & ... no interleave
restOfTemplLine(lesc, resc, isSingleQuote, expList, indStack, actInd, lineInd, accStrChars):
  //(lesc)'#' nonTemplateExprWithOpts(lesc,resc):eexp  '#'(resc)
  //   { (expList, indStack, actInd) = onEscapedExp(eexp, expList, indStack, actInd, lineInd, accStrChars) }
  //   & restOfTemplLine(lesc,resc,isSingleQuote, expList, indStack, actInd, actInd, {}):exp
  //   => exp
  //
  //|
  (lesc)  (resc)  // a comment | empty expression ... ignore completely
     & restOfTemplLineAfterEmptyExp(lesc,resc,isSingleQuote, expList, indStack, actInd, lineInd, accStrChars):exp
     => exp
  |
  (lesc) '%' expression(lesc,resc):eexp (resc)
     { (expList, indStack, actInd) = onEscapedExp(eexp, expList, indStack, actInd, lineInd, accStrChars) }
     & restOfTemplLine(lesc,resc,isSingleQuote, expList, indStack, actInd, actInd, {}):exp
     => exp

  | // on \n
  newLine
   { (expList, indStack, actInd) = onNewLine(expList, indStack, actInd, lineInd, accStrChars) }
   & templateBody(lesc, resc, isSingleQuote, expList, indStack, actInd):exp
  => exp

  | //end
  (isSingleQuote = true) "'"
   =>
    onTemplEnd(expList, indStack, actInd, lineInd, accStrChars)

  | //end
  (isSingleQuote = false) '>>'
   =>
   onTemplEnd(expList, indStack, actInd, lineInd, accStrChars)

  |
  '\' & ( '\' | "'" | (lesc) | (resc) ):c
   & restOfTemplLine(lesc, resc, isSingleQuote, expList, indStack, actInd, lineInd, c :: accStrChars) : exp
    => exp
  |
  any:c
    & restOfTemplLine(lesc, resc, isSingleQuote, expList, indStack, actInd, lineInd, c :: accStrChars) : exp
    => exp
*/
public function restOfTemplLine
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  input Boolean inIsSingleQuote;
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;
  input Integer inLineIndent;

  output list<String> outChars = inChars;
  output LineInfo outLineInfo = inLineInfo;
  output TplAbsyn.ExpressionBase outExpressionBase;
protected
  list<TplAbsyn.Expression> expl = inExpressionList;
  Integer lindent = inLineIndent;
  Integer aindent = inActualIndent;
  list<tuple<Integer, list<TplAbsyn.Expression>>> ind_stack = inIndentStack;

  String char, next_char;
  Boolean remaining_chars = true;
  TplAbsyn.Expression exp;
  list<String> chars, sol_chars, acc_chars = {};
  Option<String> err_opt;
  LineInfo linfo;
algorithm
  try
    while true loop
      char :: outChars := outChars;

      // isSingleQuote = true
      if inIsSingleQuote and char == "'" then
        expl := onTemplEnd(false, expl, ind_stack, aindent, lindent, acc_chars);
        outExpressionBase := makeTemplateFromExpList(expl, "'", "'");
        return;
      end if;

      // Peek at the next character.
      next_char :: chars := outChars;

      // isSingleQuote = false =>  << >>
      if not inIsSingleQuote and char == ">" and next_char == ">" then
        expl := onTemplEnd(true, expl, ind_stack, aindent, lindent, acc_chars);
        outExpressionBase := makeTemplateFromExpList(expl, "<<", ">>");
        outChars := chars;
        return;
      // New line.
      elseif char == "\r" or char == "\n" then
        (outChars, linfo) := newLine(char :: outChars, outLineInfo);
        (expl, ind_stack, aindent, err_opt) := onNewLine(expl, ind_stack, aindent, lindent, acc_chars);
        outLineInfo := parseErrorPrevPositionOptInfoChars(outLineInfo, linfo, err_opt, false);
        (outChars, lindent) := lineIndent(outChars, 0);
        acc_chars := {};
      // <% something %>
      elseif char == inLeftEsc and next_char == "%" then
        (outChars, linfo) := interleave(chars, outLineInfo);
        char :: next_char :: chars := outChars;

        // <% %>  empty expression ... i.e. comment or a break in line that is not parsed.
        if char == "%" and next_char == inRightEsc then
          (outChars, outLineInfo, lindent) :=
            dropNewLineAfterEmptyExp(chars, linfo, lindent, acc_chars);
        else // <% expression %>
          (outChars, linfo, exp) := expression(outChars, linfo, inLeftEsc, inRightEsc, false);
          (outChars, linfo) := interleaveExpectChar(outChars, linfo, "%");
          (outChars, linfo) := expectChar(outChars, linfo, inRightEsc);
          (expl, ind_stack, aindent, err_opt) :=
            onEscapedExp(exp, expl, ind_stack, aindent, lindent, acc_chars);
          outLineInfo := parseErrorPrevPositionOptInfoChars(outLineInfo, linfo, err_opt, false);
          acc_chars := {};
        end if;
      // Anything else.
      else
        acc_chars := char :: acc_chars;
      end if;
    end while;
  else
    outChars := {};
    outLineInfo := parseError({}, inLineInfo, "Not able to parse the text template expression from the point.", true);
    outExpressionBase := TplAbsyn.ERROR_EXP();
  end try;

//   //<# #> or $# #$
//   /*
//   case (startChars as (c :: "#" :: chars), startLinfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, accChars)
//      equation
//        equality( c  = lesc );
//        (chars, linfo) = interleave(chars, startLinfo);
//        (chars, linfo, eexp) = nonTemplateExprWithOpts(chars, linfo, lesc, resc);
//        (chars, linfo) = interleaveExpectChar(chars, linfo, "#");
//        (chars, linfo) = expectChar(chars, linfo, resc);
//        //("#" :: c :: chars) = chars;
//        //equality( c  = resc );
//        (chars, linfo, lineInd) = dropNewLineAfterEmptyExp(chars, linfo, lineInd, accChars);
//        (expLst, indStack, actInd, errOpt) = onEscapedExp(eexp, expLst, indStack, actInd, lineInd, accChars);
//        LINE_INFO(startOfLineChars = solChars) = startLinfo;
//        linfo = parseErrorPrevPositionOpt(solChars, startLinfo, linfo, errOpt, false);
//        (chars, linfo, exp) = restOfTemplLine(chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, actInd, {});
//      then (chars, linfo, exp);
//   */
//
//   //??? should we allow escaping at all ??
//   /* experimentally we will disallow it ... use "" constants in like 'hey son<%"'"%>s brother'
//   // \ will be taken literally,  '\\' and <<\\>> are both double-backslash !
//   case ("\\":: c :: chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, accChars)
//      equation
//        true = (c == "\\" or c == "'" or c == lesc or c == resc);
//        (chars, linfo, exp) = restOfTemplLine(chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, c :: accChars);
//      then (chars, linfo, exp);
//   */
end restOfTemplLine;

public function dropNewLineAfterEmptyExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input Integer inLineIndent;
  input list<String> inAccStringChars;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output Integer outLineIndent;
algorithm
  (outChars, outLineInfo, outLineIndent)
  := matchcontinue (inChars, inLineInfo, inLineIndent, inAccStringChars)
    local
      list<String> chars;
      LineInfo linfo;
      Integer lineInd;

    //ignore a pure-empty-exp line
    //accChars = {} nothing before the empty exp
    //and [space] and newLine() after it
    case (chars, linfo, _, {})
      equation
        (chars, linfo) = takeSpaceAndNewLine(chars, linfo);
        (chars,lineInd) = lineIndent(chars, 0);
      then (chars, linfo, lineInd);

    //do nothing otherwise ... i.e. continue parsing after the empty exp
    else (inChars, inLineInfo, inLineIndent);

  end matchcontinue;
end dropNewLineAfterEmptyExp;


public function makeTemplateFromExpList
  input list<TplAbsyn.Expression> inExpressionList;
  input String inLeftQuote;
  input String inRightQuote;

  output TplAbsyn.ExpressionBase outExpressionBase;
algorithm
  (outExpressionBase)
  := matchcontinue (inExpressionList, inLeftQuote,inRightQuote)
    local
      String lquote, rquote;
      TplAbsyn.ExpressionBase expB;
      list<TplAbsyn.Expression> expLst;

   case ( { } , _ , _)
      then TplAbsyn.STR_TOKEN(Tpl.ST_STRING(""));

   //the outer boundings will be used for the SourceInfo
   case ( { (expB,_) } , _ , _)
      then expB;

   case (expLst, lquote, rquote)
     equation
       expLst = listReverse(expLst);
     then TplAbsyn.TEMPLATE(expLst, lquote, rquote);

  end matchcontinue;
end makeTemplateFromExpList;


public function onEscapedExp
  input TplAbsyn.Expression inExpression;
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;
  input Integer inLineIndent;
  input list<String> inAccStringChars;

  output list<TplAbsyn.Expression> outExpressionList;
  output list<tuple<Integer,list<TplAbsyn.Expression>>> outIndentStack;
  output Integer outActualIndent;
  output Option<String> outError;
algorithm
  (outExpressionList, outIndentStack, outActualIndent, outError)
  := matchcontinue (inExpression, inExpressionList, inIndentStack,
                    inActualIndent, inLineIndent, inAccStringChars)
    local
      list<String>  accChars;
      String    errStr;
      Option<String> errOpt;
      Integer actInd, lineInd, baseInd;
      TplAbsyn.Expression exp;
      list<TplAbsyn.Expression> expLst;
      list<tuple<Integer,list<TplAbsyn.Expression>>> indStack;


   //TODO: optimization for <\n>
   //we need a flag for having something non-space on the line
   //case (TplAbsyn.STR_TOKEN(value = Tpl.ST_NEW_LINE()), expLst, indStack, actInd, lineInd, accChars)
   //   equation
   //     // true = intEq( lineInd, actInd);
   //     expLst = addAccStringChars(expLst, "\n" :: accChars);
   //   then (expLst, indStack,  actInd);

   //the same indent level
   case (exp, expLst, indStack, actInd, lineInd, accChars)
      equation
        true = intEq( lineInd, actInd );
        expLst = addAccStringChars(expLst, accChars);
        expLst = finalizeLastStringToken(expLst);
        expLst = exp :: expLst;
      then (expLst, indStack,  actInd,NONE());

   //push new indent level
   case (exp, expLst, indStack, actInd, lineInd, accChars)
      equation
        true = ( lineInd > actInd );
        expLst = finalizeLastStringToken(expLst);
        indStack = (actInd, expLst) :: indStack;
        expLst = addAccStringChars({}, accChars);
        expLst = finalizeLastStringToken(expLst);
        expLst = exp :: expLst;
      then (expLst, indStack,  lineInd,NONE());

   //if the indent is under the base indent level, warn and make it 0 level
   case (exp, expLst, {}, baseInd, lineInd, accChars)
      equation
        true = ( lineInd < baseInd );
        errStr = "Indent level is under the level of the '<<' determined level (by "+ intString(baseInd - lineInd)+ " chars).";
        errOpt = SOME(errStr);
        //true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse warning onEscapedExp() - indent level is under the level of the '<<' determined level.\n");
        //call again as  lineInd = baseInd
        (expLst, indStack,  actInd, _) = onEscapedExp(exp, expLst, {}, baseInd, baseInd, accChars);
      then (expLst, indStack,  actInd, errOpt);

   //pop indent level and try again (indStack must have at least one pushed indent level)
   case (exp, expLst, indStack as (_::_), actInd, lineInd, accChars)
      equation
        true = ( lineInd < actInd );
        expLst = finalizeLastStringToken(expLst);
        (expLst, indStack, actInd) = popIndentStack(expLst, indStack, actInd, lineInd);
        (expLst, indStack,  actInd, errOpt) = onEscapedExp(exp, expLst, indStack, actInd, lineInd, accChars);
      then (expLst, indStack,  lineInd, errOpt);

   //should not happen
   else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse unexpected error - TplParser.onEscapedExp failed .\n");
      then fail();

  end matchcontinue;
end onEscapedExp;


public function onNewLine
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;
  input Integer inLineIndent;
  input list<String> inAccStringChars;

  output list<TplAbsyn.Expression> outExpressionList;
  output list<tuple<Integer,list<TplAbsyn.Expression>>> outIndentStack;
  output Integer outActualIndent;
  output Option<String> outError;
algorithm
  (outExpressionList, outIndentStack, outActualIndent, outError)
  := matchcontinue (inExpressionList, inIndentStack, inActualIndent, inLineIndent, inAccStringChars)
    local
      list<String>  accChars, strLst;
      String c,   errStr;
      Option<String> errOpt;
      Integer actInd, lineInd, baseInd;
      list<TplAbsyn.Expression> expLst;
      list<tuple<Integer,list<TplAbsyn.Expression>>> indStack;

   //drop invisible space before new line
   case (expLst, indStack, actInd, lineInd, c :: accChars)
      equation
        true = (c == " " or c == "\t");
        (expLst, indStack,  actInd, errOpt)
         = onNewLine(expLst, indStack, actInd, lineInd, accChars);
      then (expLst, indStack, actInd, errOpt);

   //AccStringChars = {}
   // expLst = {} -> the 1. and the only \n in the template (special case) - make permanent
   // ignore lineInd - actInd and lineInd should be 0, anyway
   case ( {}, indStack, actInd, _, {})
      equation
        expLst = addAccStringChars({}, {"\n"} );
      then (expLst, indStack,  actInd,NONE());

   //AccStringChars = {}
   // expLst = ST opened :: _ -> a standalone \n on the line - make permanent
   // ignore lineInd
   case (expLst as ( (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = (""::_))),_) :: _),
       indStack, actInd, _, {})
      equation
        expLst = addAccStringChars(expLst, {"\n"} );
      then (expLst, indStack,  actInd,NONE());

   //TODO: this does not work, because the <\n> finalizes the previous ST to be closed
   //AccStringChars = {}
   // expLst = <\n> :: _ -> a forced new line - make permanent - replace with \n
   // ignore lineInd - must be lineInd = actInd  (because the <\n> exp made it so)
   case ( (TplAbsyn.STR_TOKEN(value = Tpl.ST_NEW_LINE()),_) :: expLst,
       indStack, actInd, _, {})
      equation
        expLst = addAccStringChars(expLst, {"\n"} );
      then (expLst, indStack,  actInd,NONE());

   //AccStringChars = {}
   // expLst = SNL :: _ -> a standalone \n on the line - make permanent
   // ignore lineInd
   case (expLst as ( (TplAbsyn.SOFT_NEW_LINE(),_) :: _) , indStack, actInd, _, {})
      equation
        expLst = addAccStringChars(expLst, {"\n"} );
      then (expLst, indStack,  actInd,NONE());

   //AccStringChars = {}
   // expLst = some expression :: _ -> an exp must be last --> Soft new line
   // ignore lineInd - must be lineInd = actInd  (because the exp made it so)
   case (expLst as (_ :: _) , indStack, actInd, _, {})
      equation
        expLst = (TplAbsyn.SOFT_NEW_LINE(), dummySourceInfo) :: expLst;
      then (expLst, indStack,  actInd,NONE());

   //AccStringChars = (_::_)
   // lineInd >= actInd
   // align the string with prefixed space
   // put a disposable new line - may be disposed by onTemplEnd() or hardened by addAccStringChars() or finalizeLastStringToken()
   case (expLst, indStack, actInd, lineInd, accChars as (_::_) )
      equation
        true = ( lineInd >= actInd );
        accChars = listAppend(accChars, List.fill(" ",lineInd - actInd)) annotation(__OpenModelica_DisableListAppendWarning=true);
        ( (TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST(strLst, false)),_) :: expLst)
         = addAccStringChars(expLst, accChars); //must create the ST becase of accChars as (_::_)
        //make the opened last ST be disposable new line
        expLst = (TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST(strLst, true)), dummySourceInfo) :: expLst;
      then (expLst, indStack,  actInd,NONE());

   //if the indent is under base indent level, warn and make it 0 level
   //AccStringChars = (_::_)
   // lineInd < actInd
   //pop indent level and try again
   case (expLst, {}, baseInd, lineInd, accChars as (_ :: _))
      equation
        true = ( lineInd < baseInd );
        errStr = "Indent level is under the level of the '<<' determined level (by "+ intString(baseInd - lineInd)+ " chars).";
        errOpt = SOME(errStr);
        //true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse warning onNewLine() - indent level is under the level of the '<<' determined level.\n");
        //call again as  lineInd = baseInd
        (expLst, indStack,  actInd, _) = onNewLine(expLst, {}, baseInd, baseInd, accChars);
      then (expLst, indStack,  actInd, errOpt);

   //AccStringChars = (_::_)
   // lineInd < actInd
   //pop indent level and try again
   //(indStack must have at least one pushed indent level)
   case (expLst, indStack as (_::_), actInd, lineInd, accChars as (_ :: _))
      equation
        true = ( lineInd < actInd );
        expLst = finalizeLastStringToken(expLst);
        (expLst, indStack, actInd) = popIndentStack(expLst, indStack, actInd, lineInd);
        (expLst, indStack,  actInd, errOpt) = onNewLine(expLst, indStack, actInd, lineInd, accChars);
      then (expLst, indStack,  actInd, errOpt);

   //should not happen
   else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse unexpected error - TplParser.onNewLine failed .\n");
      then fail();

  end matchcontinue;
end onNewLine;


public function onTemplEnd
  input Boolean inDropLastNewLine;
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;
  input Integer inLineIndent;
  input list<String> inAccStringChars;

  output list<TplAbsyn.Expression> outExpressionList;
algorithm
  (outExpressionList)
  := matchcontinue (inDropLastNewLine, inExpressionList, inIndentStack, inActualIndent,
                    inLineIndent, inAccStringChars)
    local
      list<String>  accChars, strLst;
      Boolean dropLastNL;
      Integer actInd, lineInd, baseInd;
      list<TplAbsyn.Expression> expLst;
      list<tuple<Integer,list<TplAbsyn.Expression>>> indStack;

   //AccStringChars = {}
   // expLst = {} - special case, only space in the template
   // make the space and take it
   case (_, {}, {}, baseInd, lineInd, {})
      equation
        true = (lineInd >= baseInd);
        expLst = addAccStringChars({}, List.fill(" ",lineInd-baseInd));
        expLst = finalizeLastStringToken(expLst);
      then expLst;

   //if drop-the-last-new-line is set
   //AccStringChars = {}
   // expLst = SNL :: _ -> dispose the SNL
   // ignore lineInd
   // pop all indent
   case (true, (TplAbsyn.SOFT_NEW_LINE(),_) :: expLst, indStack, actInd, _, {})
      equation
        (expLst, {}, _) = popIndentStack(expLst, indStack, actInd, 0);
      then expLst;

   //if drop-the-last-new-line is set
   //AccStringChars = {}
   // expLst = ST opened with disposable new line :: _ -> dispose the \n on the line
   // ignore lineInd
   // pop all indent
   case (true, (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = strLst as (""::_), lastHasNewLine = true)),_) :: expLst,
       indStack, actInd, _, {})
      equation
        expLst = finalizeLastStringToken( (TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST(strLst, false)), dummySourceInfo) :: expLst);
        (expLst, {},_) = popIndentStack(expLst, indStack, actInd, 0);
        //TODO: warn when >> is under << determined indent
      then expLst;

   //if drop-the-last-new-line is set
   //AccStringChars = {}
   // expLst = nothing to be stripped
   // ignore lineInd - it should be the same as actInd
   // pop all indent
   case (true, expLst, indStack, actInd, _, {})
      equation
        expLst = finalizeLastStringToken(expLst);
        (expLst, {}, _) = popIndentStack(expLst, indStack, actInd, 0);
      then expLst;

   //AccStringChars = (_::_)  or  drop-the-last-new-line is set
   // lineInd >= actInd
   // align the string with prefixed space
   // pop all indent
   case (_, expLst, indStack, actInd, lineInd, accChars)
      equation
        true = ( lineInd >= actInd );
        accChars = listAppend(accChars, List.fill(" ",lineInd - actInd)) annotation(__OpenModelica_DisableListAppendWarning=true);
        expLst = addAccStringChars(expLst, accChars);
        expLst = finalizeLastStringToken(expLst);
        (expLst, {}, _) = popIndentStack(expLst, indStack, actInd, 0);
      then expLst;

   // lineInd < baseInd
   // the indent is under the base indent level,
   // warn and make it 0 level
   //pop indent level and try again (only the previous case will be the end of the recursion)
   case (dropLastNL, expLst, {}, baseInd, lineInd, accChars)
      equation
        true = ( lineInd < baseInd );
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse warning onTemplEnd() - indent level is under the level of the '<<' determined level.\n");
        expLst = onTemplEnd(dropLastNL, expLst, {}, baseInd, baseInd, accChars);
      then expLst;

   // lineInd < actInd
   //pop indent level and try again (only the previous case will be the end of the recursion)
   case (dropLastNL, expLst, indStack as (_::_), actInd, lineInd, accChars)
      equation
        true = ( lineInd < actInd );
        expLst = finalizeLastStringToken(expLst);
        (expLst, indStack, actInd) = popIndentStack(expLst, indStack, actInd, lineInd);
        expLst = onTemplEnd(dropLastNL, expLst, indStack, actInd, lineInd, accChars);
      then expLst;

   //should not happen
   else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!!Parse error - TplParser.onTemplEnd failed .\n");
      then fail();

  end matchcontinue;
end onTemplEnd;


public function popIndentStack
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;
  input Integer inLineIndent;

  output list<TplAbsyn.Expression> outExpressionList;
  output list<tuple<Integer,list<TplAbsyn.Expression>>> outIndentStack;
  output Integer outActualIndent;
algorithm
  (outExpressionList, outIndentStack, outActualIndent)
  := matchcontinue (inExpressionList, inIndentStack, inActualIndent, inLineIndent)
    local
      Integer actInd, lineInd, baseInd, d, prevInd;
      list<TplAbsyn.Expression> expLst, prevExpLst;
      list<tuple<Integer,list<TplAbsyn.Expression>>> indStack;


   case (expLst, (prevInd, prevExpLst) :: indStack, actInd, lineInd)
      equation
        true = (lineInd < actInd); //when actInd > 0 --> something has to be on the stack
        d = actInd - prevInd; //must be positive
        expLst = listReverse(expLst);
        expLst = (TplAbsyn.INDENTATION(d, expLst), dummySourceInfo) :: prevExpLst;
        (expLst, indStack,  actInd) = popIndentStack(expLst, indStack, prevInd, lineInd);
      then (expLst, indStack,  actInd);

   case (expLst, indStack, actInd, lineInd)
      equation
        true = (lineInd >= actInd);
      then (expLst, indStack,  actInd);

   //base indent
   case (expLst, {}, baseInd, _)
      then (expLst, {},  baseInd);


   //should not happen
   else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!!Parse error - TplParser.popIndentStack failed .\n");
      then fail();

  end matchcontinue;
end popIndentStack;


public function addAccStringChars
  input list<TplAbsyn.Expression> inExpressionList;
  input list<String> inAccStringChars;

  output list<TplAbsyn.Expression> outExpressionList;
algorithm
  (outExpressionList)
  := matchcontinue (inExpressionList, inAccStringChars)
    local
      list<String> accChars, strLst;
      String str, strNonNl;
      list<TplAbsyn.Expression> expLst;

   //AccStringChars = {}
   // nothing
   case ( expLst, {})
      then expLst;


   // add a string
   // expLst = ST opened with new line :: _
   // merge the pushed new line with previous string without new line
   case ( (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = ("" :: strNonNl :: strLst), lastHasNewLine = true)),_) :: expLst,
       accChars as (_::_))
      equation
        failure("\n" = stringGetStringChar(strNonNl, stringLength(strNonNl)));
        // push the disposable new line
        strNonNl = strNonNl + "\n";
        str = stringCharListString(listReverse(accChars));
        expLst = (TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST("" :: str :: strNonNl :: strLst, false)), dummySourceInfo) :: expLst;
      then expLst;

   // add a string
   // expLst = ST opened with new line :: _
   // push the disposable new line - previous string has new line
   case ( (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = ("" :: strLst), lastHasNewLine = true)),_) :: expLst,
       accChars as (_::_))
      equation
        //"\n" = stringGetStringChar(strNonNl, stringLength(strNonNl));
        str = stringCharListString(listReverse(accChars));
        expLst = (TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST("" :: str :: "\n" :: strLst, false)), dummySourceInfo) :: expLst;
      then expLst;


   // add a string
   // expLst = ST opened without new line :: _
   case ( (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = ("" :: strLst), lastHasNewLine = false)),_) :: expLst,
       accChars as (_::_))
      equation
        str = stringCharListString(listReverse(accChars));
        expLst = (TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST("" :: str :: strLst, false)), dummySourceInfo) :: expLst;
      then expLst;


   // add a string
   // expLst = no opened ST  :: _
   case ( expLst, accChars as (_::_))
      equation
        str = stringCharListString(listReverse(accChars));
        expLst = (TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST({"", str}, false)), dummySourceInfo) :: expLst;
      then expLst;


   //should not happen
   else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!!Parse error - TplParser.addAccStringChars failed .\n");
      then fail();

  end matchcontinue;
end addAccStringChars;


public function finalizeLastStringToken
  input list<TplAbsyn.Expression> inExpressionList;

  output list<TplAbsyn.Expression> outExpressionList;
algorithm
  (outExpressionList)
  := matchcontinue (inExpressionList)
    local
      list<String>  strLst;
      String str, strNonNl;
      list<TplAbsyn.Expression> expLst;
      Boolean hasNL;


   // expLst = ST opened with new line :: _
   // merge the pushed new line with previous string without new line
   case ( (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = ("" :: strNonNl :: strLst), lastHasNewLine = true)),_) :: expLst )
      equation
        failure("\n" = stringGetStringChar(strNonNl, stringLength(strNonNl)));
        // push the disposable new line
        str = strNonNl + "\n";
        expLst = finalizeLastStringToken( (TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST( ""::str::strLst, false)), dummySourceInfo) :: expLst);
      then expLst;

   // expLst = ST opened with new line :: _
   // the last string has new line (or empty - should not happen)
   case ( (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = ("" :: strLst), lastHasNewLine = true)),_) :: expLst)
      equation
        //"\n" = stringGetStringChar(str, stringLength(str));
        expLst = finalizeLastStringToken( (TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST( ""::"\n"::strLst, false)), dummySourceInfo) :: expLst);
      then expLst;


   // expLst = ST opened with new line :: _
   // empty ST - for sure - should not happen
   case ( (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = { "" }, lastHasNewLine = false)),_) :: expLst )
      then expLst;


   // expLst = ST opened with new line :: _
   // the last and only string has new line
   case ( (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = { "" , "\n" }, lastHasNewLine = false)),_) :: expLst )
      equation
        expLst = (TplAbsyn.STR_TOKEN(Tpl.ST_NEW_LINE()), dummySourceInfo) :: expLst;
      then expLst;


   // expLst = ST opened with new line :: _
   // the last and only string has new line => ST_LINE
   case ( (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = { "" , str }, lastHasNewLine = false)),_) :: expLst )
      equation
        "\n" = stringGetStringChar(str, stringLength(str));
        expLst = (TplAbsyn.STR_TOKEN(Tpl.ST_LINE(str)), dummySourceInfo) :: expLst;
      then expLst;

   // expLst = ST opened with new line :: _
   // the last and only string has NOT a new line  => ST_STRING
   case ( (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = { "" , str }, lastHasNewLine = false)),_) :: expLst )
      equation
        failure("\n" = stringGetStringChar(str, stringLength(str)));
        expLst = (TplAbsyn.STR_TOKEN(Tpl.ST_STRING(str)), dummySourceInfo) :: expLst;
      then expLst;


   // expLst = ST is string list :: _
   // make it a ST_STRING_LIST with properly set lastHasNewLine
   case ( (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST( strList = ("" :: (strLst as (str :: _))), lastHasNewLine = false)),_) :: expLst )
      equation
        hasNL = ("\n" == stringGetStringChar(str, stringLength(str)));
        strLst = listReverse(strLst);
        expLst = (TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST( strLst, hasNL)), dummySourceInfo) :: expLst;
      then expLst;

   //nothing to be finalized
   else inExpressionList;

  end matchcontinue;
end finalizeLastStringToken;


/*
conditionExp(lesc,resc):
  'if' condArgExp(lesc,resc):(isNot, lhsExp, rhsMExpOpt)
  'then' expressionLet(lesc,resc):trueBr
  elseBranch(lesc,resc):elseBrOpt
   => CONDITION(isNot, lhsExp, rhsMExpOpt, trueBr, elseBrOpt)
*/
public function conditionExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := match (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars, startChars;
      LineInfo linfo, startLInfo;
      String  lesc, resc;
      Boolean  isNot;
      TplAbsyn.Expression   lhsExp, trueBr;
      Option<TplAbsyn.MatchingExp> rhsMExpOpt;
      Option<TplAbsyn.Expression> elseBrOpt;
      SourceInfo sinfo;

   case ("i"::"f":: startChars, startLInfo, lesc, resc)
      equation
        afterKeyword(startChars);
        (chars, linfo) = interleave(startChars, startLInfo);
        (chars, linfo, isNot, lhsExp, rhsMExpOpt) = condArgExp(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, trueBr) = thenBranch(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, elseBrOpt) = elseBranch(chars, linfo, lesc, resc);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 2), chars, linfo);
      then (chars, linfo, (TplAbsyn.CONDITION(isNot, lhsExp, rhsMExpOpt, trueBr, elseBrOpt), sinfo));

  end match;
end conditionExp;


public function thenBranch
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outTrueBranch;
algorithm
  (outChars, outLineInfo, outTrueBranch) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression exp;

   case ("t"::"h"::"e"::"n":: chars, linfo, lesc, resc)
     equation
       afterKeyword(chars);
       (chars, linfo) = interleave(chars, linfo);
       (chars, linfo, exp) = expressionLet(chars, linfo, lesc, resc);
     then (chars, linfo, exp);

   //error not a keyword
   //try move on ?
   case (chars, linfo, lesc, resc)
     equation
       (_, false) = isKeyword(chars, "t"::"h"::"e"::"n"::{});
       (linfo) = parseError(chars, linfo, "Expected 'then' keyword at the position.", false);
       (chars, linfo, exp) = expressionLet(chars, linfo, lesc, resc);
     then (chars, linfo, exp);

   else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("- !!! TplParser.thenBranch failed.\n");
      then fail();

  end matchcontinue;
end thenBranch;


/*
elseBranch(lesc,resc):
  'else' expressionLet(lesc,resc):elseBr
    => SOME(elseBr)
  |
  _ => NONE

*/
public function elseBranch
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output Option<TplAbsyn.Expression> outElseBranchOpt;
algorithm
  (outChars, outLineInfo, outElseBranchOpt) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression    elseBr;

    case ("e"::"l"::"s"::"e":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, elseBr) = expressionLet(chars, linfo, lesc, resc);
      then (chars, linfo, SOME(elseBr));

    else (inChars, inLineInfo, NONE());

  end matchcontinue;
end elseBranch;
/*
must not fail
condArgExp:
  'not' expressionPlus(lesc,resc):lhsExp
    => (true, lhsExp,NONE())
  |
  expressionPlus(lesc,resc):lhsExp
  //  condArgRHS:(isNot, rshMExpOpt)
  { isNot = false }
   => (isNot,lhsExp, rhsMExpOpt)
*/
public function condArgExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output Boolean outIsNot;
  output TplAbsyn.Expression outLHSExpression;
  output Option<TplAbsyn.MatchingExp> outRHSMExpOpt;
algorithm
  (outChars, outLineInfo, outIsNot, outLHSExpression, outRHSMExpOpt) :=
  matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression   lhsExp;

   //TODO: perhaps, we should record the start of the expression from the 'not'
   //but for now, we don't have other operators, so it is non an issue here
   case ("n"::"o"::"t":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, lhsExp) = expressionPlus(chars, linfo, lesc, resc);
      then (chars, linfo, true, lhsExp,NONE());

   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, lhsExp) = expressionPlus(chars, linfo, lesc, resc);
        //(chars, linfo) = interleave(chars, linfo);
        //(chars, linfo, isNot, rhsMExpOpt) = condArgRHS(chars, linfo);
        //isNot = false;
      then (chars, linfo, false, lhsExp,NONE());

  end matchcontinue;
end condArgExp;
/*
condArgRHS:
  'is' 'not' matchBinding:rhsMExp  =>  (true, SOME(rhsMexp))
  |
  'is' matchBinding:rhsMExp  =>  (false, SOME(rhsMexp))
  |
  _ => (false,NONE())
*/
/*
public function condArgRHS
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output Boolean outIsNot;
  output Option<TplAbsyn.MatchingExp> outRHSMExpOpt;
algorithm
  (outChars, outLineInfo, outIsNot, outRHSMExpOpt) :=
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp, lhsExp, elseBr;
      TplAbsyn.MatchingExp rhsMExp;
      Option<TplAbsyn.MatchingExp> rhsMExpOpt;
      Option<TplAbsyn.Expression> elseBrOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;

    case ("i"::"s":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        ("n"::"o"::"t":: chars) = chars;
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, rhsMExp) = matchBinding(chars, linfo);
      then (chars, linfo, true, SOME(rhsMExp));

    case ("i"::"s":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, rhsMExp) = matchBinding(chars, linfo);
      then (chars, linfo, false, SOME(rhsMExp));


    else (inChars, inLineInfo, false, NONE());

  end matchcontinue;
end condArgRHS;
*/


/*
optional, can fail
matchExp(lesc,resc):
  'match' expressionIf:exp
    matchCaseList(lesc,resc):mcaseLst  { (_::_) = mcaseLst }//not optional
    matchElseCase(lesc,resc):elseLst
    matchEndMatch
   => MATCH(exp, listAppend(mcaseLst, elseLst))
  //|
  //matchCaseList(lesc,resc):mcaseLst { (_::_) = mcaseLst }
  //=> MATCH(BOUND_VALUE(IDENT("it")), mcaseLst)
*/
public function matchExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := match (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars, startChars;
      LineInfo linfo, startLInfo;
      String  lesc, resc;
      TplAbsyn.Expression exp;
      list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> mcaseLst, elseLst;
      SourceInfo sinfo;

   case ("m"::"a"::"t"::"c"::"h":: startChars, startLInfo, lesc, resc)
      equation
        afterKeyword(startChars);
        (chars, linfo) = interleave(startChars, startLInfo);
        (chars, linfo, exp) = expressionIf(chars, linfo, lesc, resc);
        (chars, linfo, mcaseLst) = matchCaseListNoOpt(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, elseLst) = matchElseCase(chars, linfo, lesc, resc);
        mcaseLst = listAppend(mcaseLst, elseLst) annotation(__OpenModelica_DisableListAppendWarning=true);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = matchEndMatch(chars, linfo);
        sinfo = tplSourceInfo(captureStartPosition(startChars, startLInfo, 5), chars, linfo);
      then (chars, linfo, (TplAbsyn.MATCH(exp, mcaseLst), sinfo));

   //implicit without 'match' keyword -> match it
   //case (chars, linfo, lesc, resc)
   //   equation
   //     (chars, linfo, mcaseLst) = matchCaseList(chars, linfo, lesc, resc);
   //     (_::_) = mcaseLst;
   //   then (chars, linfo, TplAbsyn.MATCH(TplAbsyn.BOUND_VALUE(TplAbsyn.IDENT("it")), mcaseLst));

  end match;
end matchExp;


/*
matchCase(lesc,resc):
  'case'  matchBinding:mexp  matchCaseHeads(): mexpHeadLst
  'then'  expression:exp
     => makeMatchCaseLst(mexp::mexpHeadLst,exp)
*/
public function matchCase
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> outMatchCaseLst;
algorithm
  (outChars, outLineInfo, outMatchCaseLst) :=
  match (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      TplAbsyn.Expression exp;
      TplAbsyn.MatchingExp mexp;
      list<TplAbsyn.MatchingExp> mexpHeadList;
      list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> matchCaseLst;

   case ("c"::"a"::"s"::"e":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexpHeadList) = matchCaseHeads(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = thenBranch(chars, linfo, lesc, resc);
        matchCaseLst = makeMatchCaseLst(mexp::mexpHeadList,exp);
      then (chars, linfo, matchCaseLst);

  end match;
end matchCase;

/*
matchElseCase(lesc,resc):
  'else' expression:exp
    => {(REST_MATCH(), exp)}
  |
  _ => {}
*/
public function matchElseCase
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> outMatchCaseLst;
algorithm
  (outChars, outLineInfo, outMatchCaseLst) :=
  matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String lesc, resc;
      TplAbsyn.Expression exp;

    case ("e"::"l"::"s"::"e":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars,linfo,exp) = expressionLet(chars, linfo, lesc, resc);
      then (chars, linfo, { (TplAbsyn.REST_MATCH(), exp) } );

    else (inChars, inLineInfo, {});

  end matchcontinue;
end matchElseCase;

/*
matchEndMatch:
  'end' 'match'
  |
  _
*/
public function matchEndMatch
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) :=
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;

    case ("e"::"n"::"d":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        //both keywords are optional ... the match cannot be "expected" as there can be 'end' indentifier ';'
        ("m"::"a"::"t"::"c"::"h" :: chars) = chars; // interleaveExpectKeyWord(chars, linfo, {"m","a","t","c","h"}, false);
        afterKeyword(chars);
      then (chars, linfo);

    else (inChars, inLineInfo);

  end matchcontinue;
end matchEndMatch;

/*
matchCaseHeads(lesc,resc):
  'case'  matchBinding:mexp  matchCaseHeads(): mexpHeadLst
     => mexp :: mexpHeadLst
  |
  _ => {}
*/
public function matchCaseHeads
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.MatchingExp> outMExpHeadLst;
algorithm
  (outChars, outLineInfo, outMExpHeadLst) :=
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.MatchingExp mexp;
      list<TplAbsyn.MatchingExp> mexpHeadList;

    case ("c"::"a"::"s"::"e":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexpHeadList) = matchCaseHeads(chars, linfo);
      then (chars, linfo, mexp :: mexpHeadList);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end matchCaseHeads;


public function makeMatchCaseLst
  input list<TplAbsyn.MatchingExp> inMExpHeadLst;
  input TplAbsyn.Expression inExpression;

  output list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> outMatchCaseLst;
algorithm
  (outMatchCaseLst) :=
  match (inMExpHeadLst, inExpression)
    local
      TplAbsyn.Expression exp;
      TplAbsyn.MatchingExp mexp;
      list<TplAbsyn.MatchingExp> mexpHeadList;
      list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> matchCaseLst;

   case ({}, _)  then {};

   case (mexp :: mexpHeadList, exp)
      equation
        matchCaseLst = makeMatchCaseLst(mexpHeadList,exp);
      then ((mexp, exp) :: matchCaseLst);

  end match;
end makeMatchCaseLst;

/*
matchCaseList(lesc,resc):
  matchCase(lesc,resc):mcaseLst  matchCaseList(lesc,resc):mcrest
    => listAppend(mcaseLst, mcrest)
  |
  _ => {}
*/
public function matchCaseList
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> outMatchCases;
algorithm
  (outChars, outLineInfo, outMatchCases) :=
  matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> mcaseLst, mcrest;

    case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, mcaseLst) = matchCase(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mcrest) = matchCaseList(chars, linfo, lesc, resc);
        mcaseLst = listAppend(mcaseLst, mcrest) annotation(__OpenModelica_DisableListAppendWarning=true);
      then (chars, linfo, mcaseLst);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end matchCaseList;


public function matchCaseListNoOpt
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> outMatchCases;
algorithm
  (outChars, outLineInfo, outMatchCases) :=
  matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String  lesc, resc;
      list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> mcaseLst;

   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, mcaseLst) = matchCaseList(chars, linfo, lesc, resc);
        (_::_) = mcaseLst;
      then (chars, linfo, mcaseLst);

   case (chars, linfo, _, _)
      equation
        (_, false) = isKeyword(chars, "c"::"a"::"s"::"e"::{});
        (linfo) = parseError(chars, linfo, "Expected keyword 'case' at the position.", true);
      then (chars, linfo, {});

   else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!! TplParser.matchCaseListNoOpt failed.\n");
      then fail();

  end matchcontinue;
end matchCaseListNoOpt;

/*
matchBinding:
  matchBinding_base:headMExp  matchBinding_tail(headMExp):mexp
    => mexp

*/
public function matchBinding
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.MatchingExp outMatchingExp;
algorithm
  (outChars, outLineInfo, outMatchingExp) :=
  match (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.MatchingExp headMExp, mexp;

   case (chars, linfo)
      equation
        (chars, linfo, headMExp) = matchBinding_base(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding_tail(chars, linfo, headMExp);
      then (chars, linfo, mexp);

  end match;
end matchBinding;
/*
matchBinding_tail(headMExp):
  '::' matchBinding:restMExp
    => LIST_CONS_MATCH(headMExp, restMExp)
  |
  _ => headMExp
*/
public function matchBinding_tail
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.MatchingExp inHeadMatchingExp;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.MatchingExp outMatchingExp;
algorithm
  (outChars, outLineInfo, outMatchingExp) :=
  matchcontinue (inChars, inLineInfo, inHeadMatchingExp)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.MatchingExp headMExp,  restMExp;

    case (":"::":":: chars, linfo, headMExp)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, restMExp) = matchBinding(chars, linfo);
      then (chars, linfo, TplAbsyn.LIST_CONS_MATCH(headMExp, restMExp));

    else (inChars, inLineInfo, inHeadMatchingExp);

  end matchcontinue;
end matchBinding_tail;
/*
matchBinding_base:
  'SOME' someBinding_rest:mexp
    => SOME_MATCH(mexp)
  |
  'NONE' takeEmptyBraces
    => NONE_MATCH()
  |
  '(' matchBinding:headMExp  tupleOrSingleMatch(headMExp):mexp ')'
    => mexp
  |
  '{' '}'
    => LIST_MATCH({})
  |
  '{' matchBinding:headMExp  listMatch_rest:mrest '}
    => LIST_MATCH(headMExp :: mrest)
  |
  stringConstant:strRevList
    => STRING_MATCH(stringAppendList(listReverse(strRevList))
  |
  literalConstant:(str,litType)
    => LITERAL_MATCH(str,litType)
  |
  '_'
    => REST_MATCH()
  |
  pathIdent:pid  afterIdentBinding(pid):mexp
    => mexp
*/
public function matchBinding_base
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.MatchingExp outMatchingExp;
algorithm
  (outChars, outLineInfo, outMatchingExp) :=
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, strRevList;
      LineInfo linfo;
      String str;
      TplAbsyn.PathIdent  pid;
      TplAbsyn.MatchingExp headMExp, mexp;
      list<TplAbsyn.MatchingExp> mrest;
      TplAbsyn.TypeSignature ts;

   case ("S"::"O"::"M"::"E":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = someBinding_rest(chars, linfo);
      then (chars, linfo, TplAbsyn.SOME_MATCH(mexp));

   case ("N"::"O"::"N"::"E":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = takeEmptyBraces(chars, linfo);
      then (chars, linfo, TplAbsyn.NONE_MATCH());

   case ("(":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, headMExp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = tupleOrSingleMatch(chars, linfo, headMExp);
        (chars, linfo) = interleaveExpectChar(chars, linfo, ")");
      then (chars, linfo, mexp);

   case ("{":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        ("}"::chars) = chars;
      then (chars, linfo, TplAbsyn.LIST_MATCH({}));

   case ("{":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, headMExp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mrest) = listMatch_rest(chars, linfo);
        (chars, linfo) = interleaveExpectChar(chars, linfo, "}");
      then (chars, linfo, TplAbsyn.LIST_MATCH(headMExp :: mrest));

   case ("_":: chars, linfo)
      then (chars, linfo, TplAbsyn.REST_MATCH());

   case (chars, linfo)
      equation
        (chars, linfo, strRevList) = stringConstant(chars, linfo);
        str = stringAppendList(listReverse(strRevList));
      then (chars, linfo, TplAbsyn.STRING_MATCH(str));

   case (chars, linfo)
      equation
        (chars, linfo, str, ts) = literalConstant(chars, linfo);
      then (chars, linfo, TplAbsyn.LITERAL_MATCH(str,ts));

   case (chars, linfo)
      equation
        (chars, linfo, pid) = pathIdent(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = afterIdentBinding(chars, linfo, pid);
      then (chars, linfo, mexp);

   case (chars, linfo)
      equation
        (linfo) = parseError(chars, linfo, "Expected a valid match binding expression at the position.", true);
        //true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Parse error - TplParser.matchBinding_base failed .\n");
      then (chars, linfo, TplAbsyn.LITERAL_MATCH("#Error#", TplAbsyn.UNRESOLVED_TYPE("#Error#")));

  end matchcontinue;
end matchBinding_base;
/*
someBinding_rest:
  '(' '__' ')'
    => SOME_MATCH(REST_MATCH())
  |
  '(' matchBinding:mexp ')'
    => SOME_MATCH(mexp)
  |
  _ => SOME_MATCH(REST_MATCH())
*/
public function someBinding_rest
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.MatchingExp outMatchingExp;
algorithm
  (outChars, outLineInfo, outMatchingExp) :=
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.MatchingExp  mexp;

    case ("(":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        ("_"::"_":: chars) = chars;
        (chars, linfo) = interleaveExpectChar(chars, linfo, ")");
      then (chars, linfo, TplAbsyn.REST_MATCH());

    case ("(":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
        (chars, linfo) = interleaveExpectChar(chars, linfo, ")");
      then (chars, linfo, mexp);

    else (inChars, inLineInfo, TplAbsyn.REST_MATCH());

  end matchcontinue;
end someBinding_rest;
/*
takeEmptyBraces:
  '(' ')'
  |
  _
*/
public function takeEmptyBraces
  input list<String> inChars;
  input LineInfo inLineInfo;
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) :=
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;

    case ("(":: chars, linfo)
      equation
        (chars, linfo) = interleaveExpectChar(chars, linfo, ")");
      then (chars, linfo);

    else (inChars, inLineInfo);

  end matchcontinue;
end takeEmptyBraces;
/*
tupleOrSingleMatch(headMExp):
  ',' matchBinding:secMExp  listMatch_rest:mrest
    => TUPLE_MATCH(headMExp :: secMExp :: mrest)
  |
  _ => headMExp

*/
public function tupleOrSingleMatch
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.MatchingExp inHeadMatchingExp;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.MatchingExp outMatchingExp;
algorithm
  (outChars, outLineInfo, outMatchingExp) :=
  matchcontinue (inChars, inLineInfo, inHeadMatchingExp)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.MatchingExp headMExp,   secMExp;
      list<TplAbsyn.MatchingExp> mrest;

    case (",":: chars, linfo, headMExp)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, secMExp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mrest) = listMatch_rest(chars, linfo);
      then (chars, linfo, TplAbsyn.TUPLE_MATCH(headMExp :: secMExp :: mrest));

    else (inChars, inLineInfo, inHeadMatchingExp);

  end matchcontinue;
end tupleOrSingleMatch;
/*
listMatch_rest:
  ',' matchBinding:mexp  listMatch_rest:mrest
    => mexp :: mrest
  |
  _ => {}

*/
public function listMatch_rest
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.MatchingExp> outMatchingExpListRest;
algorithm
  (outChars, outLineInfo, outMatchingExpListRest) :=
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.MatchingExp  mexp;
      list<TplAbsyn.MatchingExp> mrest;

    case (",":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mrest) = listMatch_rest(chars, linfo);
      then (chars, linfo, mexp :: mrest);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end listMatch_rest;
/*
afterIdentBinding(pid):
  '(' ')'
    => RECORD_MATCH(pid, {})
  |
  '(' '__' ')'
    => RECORD_MATCH(pid, {}) //TODO: to be RECORD_TYPE_MATCH(pid)
  |
  '(' fieldBinding:fb  fieldBinding_rest:fbs ')'
    => RECORD_MATCH(pid, fb::fbs)
  |
  {pid is PATH_IDENT}
  => error "Expected '(' after the dot path."
  //RECORD_MATCH(pid, {})
  |
  {pid is IDENT(id)}
  'as' matchBinding:mexp
    => BIND_AS_MATCH(id, mexp)
  |
  {pid is IDENT(id)}
  _ => BIND_MATCH(id)
*/
public function afterIdentBinding
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.PathIdent inPathIdent;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.MatchingExp outMatchingExp;
algorithm
  (outChars, outLineInfo, outMatchingExp) :=
  matchcontinue (inChars, inLineInfo, inPathIdent)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent pid;
      TplAbsyn.MatchingExp  mexp;
      tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp> fb;
      list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> fbs;

    case ("(":: chars, linfo, pid)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (")":: chars) = chars;
      then (chars, linfo, TplAbsyn.RECORD_MATCH(pid, {}));

    case ("(":: chars, linfo, pid)
      equation
        (chars, linfo) = interleave(chars, linfo);
        ("_"::"_":: chars) = chars;
        (chars, linfo) = interleaveExpectChar(chars, linfo, ")");
      then (chars, linfo, TplAbsyn.RECORD_MATCH(pid, {}));

    case ("(":: chars, linfo, pid)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, fb) = fieldBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, fbs) = fieldBinding_rest(chars, linfo);
        (chars, linfo) = interleaveExpectChar(chars, linfo, ")");
      then (chars, linfo, TplAbsyn.RECORD_MATCH(pid, fb::fbs));

    case (chars, linfo, pid as TplAbsyn.PATH_IDENT(_,_))
      equation
         (linfo) = parseError(chars, linfo, "Expected '(' after the dot path.", false);
      then (chars, linfo, TplAbsyn.RECORD_MATCH(pid, {}));

    case ("a"::"s":: chars, linfo, TplAbsyn.IDENT(id))
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
      then (chars, linfo, TplAbsyn.BIND_AS_MATCH(id, mexp));

    case (chars, linfo, TplAbsyn.IDENT(id))
      then (chars, linfo, TplAbsyn.BIND_MATCH(id));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!! TplParser.afterIdentBinding failed.\n");
      then fail();

  end matchcontinue;
end afterIdentBinding;



/*
must not fail
fieldBinding:
  identifier:fldId '=' matchBinding:mexp
    => (fldId, mexp)
*/
public function fieldBinding
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp> outFieldBinding;
algorithm
  (outChars, outLineInfo, outFieldBinding) :=
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.Ident id;
      TplAbsyn.MatchingExp  mexp;

   case (chars, linfo)
      equation
        (chars, linfo, id) = identifierNoOpt(chars, linfo);
        (chars, linfo) = interleaveExpectChar(chars, linfo, "=");
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
      then (chars, linfo, (id, mexp));

   else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("- !!! TplParser.fieldBinding failed.\n");
      then fail();

  end matchcontinue;
end fieldBinding;
/*
fieldBinding_rest:
  ',' fieldBinding:fb  fieldBinding_rest:fbs
    => fb :: fbs
  |
  _ => {}

*/
public function fieldBinding_rest
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> outFieldBindingsRest;
algorithm
  (outChars, outLineInfo, outFieldBindingsRest) :=
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp> fb;
      list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> fbs;

    case (",":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, fb) = fieldBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, fbs) = fieldBinding_rest(chars, linfo);
      then (chars, linfo, fb :: fbs);

    else (inChars, inLineInfo, {});

  end matchcontinue;
end fieldBinding_rest;

/*
annotationFooter:
  'annotation(...)' => str
  |
  _ => ""

*/
protected function annotationFooter
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> chars;
  output LineInfo linfo;
  output String footer;
algorithm
  (chars,linfo,footer) := match (inChars,inLineInfo)
    local
      list<String> footerChars;
    case ("a"::"n"::"n"::"o"::"t"::"a"::"t"::"i"::"o"::"n"::chars, linfo)
      equation
        (footerChars,chars) = List.split(inChars,List.position(";", inChars)+1);
        footer = stringAppendList(footerChars);
      then (chars,linfo,footer);
    else (inChars,inLineInfo,"annotation(__OpenModelica_generator=\"Susan\");"); // No annotation; put default footer
  end match;
end annotationFooter;

annotation(__OpenModelica_Interface="susan");
end TplParser;

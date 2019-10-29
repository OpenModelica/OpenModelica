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

encapsulated package Parser
" file:        Parser.mo
  package:     Parser
  description: Interface to external code for parsing

  $Id$

  The parser module is used for both parsing of files and statements in
  interactive mode."

import Absyn;
import GlobalScript;
import HashTableStringToProgram;

protected
import Config;
import ErrorExt;
import Flags;
import ParserExt;
import AbsynToSCode;
import System;
import Util;

public

function parse "Parse a mo-file"
  input String filename;
  input String encoding;
  input String libraryPath = "";
  input Option<Integer> lveInstance = NONE();
  output Absyn.Program outProgram;
algorithm
  outProgram := parsebuiltin(filename,encoding,libraryPath,lveInstance);
  /* Check that the program is not totally off the charts */
  _ := AbsynToSCode.translateAbsyn2SCode(outProgram);
end parse;

function parseexp "Parse a mos-file"
  input String filename;
  output GlobalScript.Statements outStatements;
algorithm
  outStatements := ParserExt.parseexp(System.realpath(filename), Util.testsuiteFriendly(System.realpath(filename)), Config.acceptedGrammar(), Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), Config.getRunningTestsuite());
end parseexp;

function parsestring "Parse a string as if it were a stored definition"
  input String str;
  input String infoFilename = "<interactive>";
  output Absyn.Program outProgram;
algorithm
  outProgram := ParserExt.parsestring(str, infoFilename, Config.acceptedGrammar(), Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), Config.getRunningTestsuite());
  /* Check that the program is not totally off the charts */
  _ := AbsynToSCode.translateAbsyn2SCode(outProgram);
end parsestring;

function parsebuiltin "Like parse, but skips the SCode check to avoid infinite loops for ModelicaBuiltin.mo."
  input String filename;
  input String encoding;
  input String libraryPath = "";
  input Option<Integer> lveInstance = NONE();
  input Integer acceptedGram=Config.acceptedGrammar();
  input Integer languageStandardInt=Flags.getConfigEnum(Flags.LANGUAGE_STANDARD);
  output Absyn.Program outProgram;
  annotation(__OpenModelica_EarlyInline = true);
protected
  String realpath;
algorithm
  realpath := Util.replaceWindowsBackSlashWithPathDelimiter(System.realpath(filename));
  outProgram := ParserExt.parse(realpath, Util.testsuiteFriendly(realpath), acceptedGram, encoding, languageStandardInt, Config.getRunningTestsuite(), libraryPath, lveInstance);
end parsebuiltin;

function parsestringexp "Parse a string as if it was a sequence of statements"
  input String str;
  input String infoFilename = "<interactive>";
  output GlobalScript.Statements outStatements;
algorithm
  outStatements := ParserExt.parsestringexp(str,infoFilename,
    Config.acceptedGrammar(), Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), Config.getRunningTestsuite());
end parsestringexp;

function stringPath
  input String str;
  output Absyn.Path path;
algorithm
  path := ParserExt.stringPath(str, "<internal>", Config.acceptedGrammar(), Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), Config.getRunningTestsuite());
end stringPath;

function stringCref
  input String str;
  output Absyn.ComponentRef cref;
algorithm
  cref := ParserExt.stringCref(str, "<internal>", Config.acceptedGrammar(), Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), Config.getRunningTestsuite());
end stringCref;

function parallelParseFiles
  input list<String> filenames;
  input String encoding;
  input Integer numThreads = Config.noProc();
  input String libraryPath = "";
  input Option<Integer> lveInstance = NONE();
  output HashTableStringToProgram.HashTable ht;
protected
  list<ParserResult> partialResults;
algorithm
  partialResults := parallelParseFilesWork(filenames, encoding, numThreads, libraryPath, lveInstance);
  ht := HashTableStringToProgram.emptyHashTableSized(Util.nextPrime(listLength(partialResults)));
  for res in partialResults loop
    ht := match res
      local
        Absyn.Program p;
      case PARSERRESULT(program=SOME(p))
        then BaseHashTable.add((res.filename,p), ht);
    end match;
  end for;
end parallelParseFiles;

function parallelParseFilesToProgramList
  input list<String> filenames;
  input String encoding;
  input Integer numThreads = Config.noProc();
  output list<Absyn.Program> result = {};
algorithm
  for r in parallelParseFilesWork(filenames, encoding, numThreads) loop
    result := (match r
      local
        Absyn.Program p;
      case PARSERRESULT(program=SOME(p)) then p;
    end match) :: result;
  end for;
  result := MetaModelica.Dangerous.listReverseInPlace(result);
end parallelParseFilesToProgramList;

function startLibraryVendorExecutable
  input String lvePath;
  output Boolean success;
  output Option<Integer> lveInstance "Stores a pointer. If it is declared as Integer, it is truncated to 32-bit.";
algorithm
  (success, lveInstance) := ParserExt.startLibraryVendorExecutable(lvePath);
end startLibraryVendorExecutable;

function checkLVEToolLicense
  input Option<Integer> lveInstance;
  input String packageName;
  output Boolean status;
algorithm
  status := ParserExt.checkLVEToolLicense(lveInstance, packageName);
end checkLVEToolLicense;

function checkLVEToolFeature
  input Option<Integer> lveInstance;
  input String feature;
algorithm
  ParserExt.checkLVEToolFeature(lveInstance, feature);
end checkLVEToolFeature;

function stopLibraryVendorExecutable
  input Option<Integer> lveInstance "Stores a pointer. If it is declared as Integer, it is truncated to 32-bit.";
algorithm
  ParserExt.stopLibraryVendorExecutable(lveInstance);
end stopLibraryVendorExecutable;

protected

uniontype ParserResult
  record PARSERRESULT
    String filename;
    Option<Absyn.Program> program;
  end PARSERRESULT;
end ParserResult;

function parallelParseFilesWork
  input list<String> filenames;
  input String encoding;
  input Integer numThreads;
  input String libraryPath = "";
  input Option<Integer> lveInstance = NONE();
  output list<ParserResult> partialResults;
protected
  list<tuple<String,String,String,Option<Integer>>> workList = list((file,encoding,libraryPath,lveInstance) for file in filenames);
algorithm
  if Config.getRunningTestsuite() or Config.noProc()==1 or numThreads == 1 or listLength(filenames)<2 or not(libraryPath == "") then
    partialResults := list(loadFileThread(t) for t in workList);
  else
    // GC.disable(); // Seems to sometimes break building nightly omc
    partialResults := System.launchParallelTasks(min(8, numThreads) /* Boehm GC does not scale to infinity */, workList, loadFileThread);
    // GC.enable();
  end if;
end parallelParseFilesWork;

function loadFileThread
  input tuple<String,String,String,Option<Integer>> inFileEncoding;
  output ParserResult result;
algorithm
  result := matchcontinue inFileEncoding
    local
      String filename,encoding,libraryPath;
      Option<Integer> lveInstance;
    case (filename,encoding,libraryPath,lveInstance) then PARSERRESULT(filename,SOME(Parser.parse(filename, encoding, libraryPath, lveInstance)));
    case (filename,_,_,_) then PARSERRESULT(filename,NONE());
  end matchcontinue;
  if ErrorExt.getNumMessages() > 0 then
    ErrorExt.moveMessagesToParentThread();
  end if;
end loadFileThread;

annotation(__OpenModelica_Interface="frontend");
end Parser;

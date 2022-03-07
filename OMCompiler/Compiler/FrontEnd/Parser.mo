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
import Testsuite;
import Util;
import List;

public

function parse "Parse a mo-file"
  input String filename;
  input String encoding;
  input String libraryPath = "";
  input Option<Integer> lveInstance = NONE();
  output Absyn.Program outProgram;
protected
  list<Absyn.Class> classes, classes1;
  Absyn.Within w;
  Absyn.Class cs;
algorithm
  outProgram := parsebuiltin(filename,encoding,libraryPath,lveInstance);
  /* Check that the program is not totally off the charts */
  _ := AbsynToSCode.translateAbsyn2SCode(outProgram);
  // Check license features
  if (isSome(lveInstance)) then
    Absyn.PROGRAM(classes, w) := outProgram;
    classes1 := {};
    for cs in classes loop
      if checkLicenseAndFeatures(cs, lveInstance) then
        classes1 := cs :: classes1;
      end if;
    end for;
    outProgram := Absyn.PROGRAM(classes1, w);
  end if;
end parse;

function parseexp "Parse a mos-file"
  input String filename;
  output GlobalScript.Statements outStatements;
algorithm
  outStatements := ParserExt.parseexp(System.realpath(filename), Testsuite.friendly(System.realpath(filename)), Config.acceptedGrammar(), Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), Testsuite.isRunning());
end parseexp;

function parsestring "Parse a string as if it were a stored definition"
  input String str;
  input String infoFilename = "<interactive>";
  input Integer grammar = Config.acceptedGrammar();
  input Integer languageStd = Flags.getConfigEnum(Flags.LANGUAGE_STANDARD);
  output Absyn.Program outProgram;
algorithm
  outProgram := ParserExt.parsestring(str, infoFilename, grammar, languageStd, Testsuite.isRunning());
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
  outProgram := ParserExt.parse(realpath, Testsuite.friendly(realpath), acceptedGram, encoding, languageStandardInt, Testsuite.isRunning(), libraryPath, lveInstance);
end parsebuiltin;

function parsestringexp "Parse a string as if it was a sequence of statements"
  input String str;
  input String infoFilename = "<interactive>";
  output GlobalScript.Statements outStatements;
algorithm
  outStatements := ParserExt.parsestringexp(str,infoFilename,
    Config.acceptedGrammar(), Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), Testsuite.isRunning());
end parsestringexp;

function stringPath
  input String str;
  output Absyn.Path path;
algorithm
  path := ParserExt.stringPath(str, "<internal>", Config.acceptedGrammar(), Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), Testsuite.isRunning());
end stringPath;

function stringCref
  input String str;
  output Absyn.ComponentRef cref;
algorithm
  cref := ParserExt.stringCref(str, "<internal>", Config.acceptedGrammar(), Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), Testsuite.isRunning());
end stringCref;

function stringMod
  input String str;
  input String filename = "<internal>";
  output Absyn.ElementArg mod;
algorithm
  mod := ParserExt.stringMod(str, filename, Config.acceptedGrammar(), Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), Testsuite.isRunning());
end stringMod;

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
  output Boolean status;
algorithm
  status := ParserExt.checkLVEToolFeature(lveInstance, feature);
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
  if Testsuite.isRunning() or Config.noProc()==1 or numThreads == 1 or listLength(filenames)<2 or isSome(lveInstance) then
    partialResults := list(loadFileThread(t) for t in workList);
  else
    // GCExt.disable(); // Seems to sometimes break building nightly omc
    partialResults := System.launchParallelTasks(min(8, numThreads) /* Boehm GC does not scale to infinity */, workList, loadFileThread);
    // GCExt.enable();
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

public function checkLicenseAndFeatures
  input Absyn.Class c1;
  input Option<Integer> lveInstance = NONE();
  output Boolean result;
protected
  list<String> orFeatures;
  list<String> andFeatures;
algorithm
  // check license
  //print("Parser.checkLVEToolLicense returned = " + boolString(Parser.checkLVEToolLicense(lveInstance, AbsynUtil.getClassName(c1))) + "\n");
  //(libraryKey, licenseFile) := getLicenseAnnotation(c1);
  //print("Library Key is : " + libraryKey + "\n");
  //print("License File is : " + licenseFile + "\n");

  // annotation(Protection(features={"LicenseOption1 LicenseOption2", "LicenseOption3"}));
  // For above annotation. Requires license features ("LicenseOption1" and "LicenseOption2") or "LicenseOption3"
  result := true;
  orFeatures := getFeaturesAnnotation(c1);
  for orFeature in orFeatures loop
    andFeatures := Util.stringSplitAtChar(orFeature, " ");
    result := true;
    for andFeature in andFeatures loop
      if not checkLVEToolFeature(lveInstance, andFeature) then
        result := false;
        break;
      end if;
    end for;
    // If we one of the feature is there then do not look for other features.
    // If the features vector has more than one element, then at least a license feature according to one of the elements must be present
    if result then
      break;
    end if;
  end for;
end checkLicenseAndFeatures;

protected function getLicenseAnnotation
  "Returns the Protection(License=) annotation of a class.
  This is annotated with the annotation:
  annotation(Protection(License(libraryKey=\"15783-A39323-498222-444ckk4ll\", licenseFile=\"MyLibraryAuthorization_Tool.mo_lic\"))); in the class definition"
  input Absyn.Class className;
  output tuple<String, String> license;
protected
  Option<tuple<String, String>> opt_license;
algorithm
  opt_license := AbsynUtil.getNamedAnnotationInClass(className, Absyn.IDENT("Protection"), getLicenseAnnotationWork1);
  license := Util.getOptionOrDefault(opt_license, ("", ""));
end getLicenseAnnotation;

protected function getLicenseAnnotationWork1
  "Extractor function for getLicenseAnnotation"
  input Option<Absyn.Modification> mod;
  output tuple<String, String> license;
algorithm
  license := match (mod)
    local
      list<Absyn.ElementArg> arglst;
      String libraryKey, licenseFile;

    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      equation
        (libraryKey, licenseFile) = getLicenseAnnotationWork2(arglst);
      then (libraryKey, licenseFile);
  end match;
end getLicenseAnnotationWork1;

protected function getLicenseAnnotationWork2
  "Extractor function for getLicenseAnnotation"
  input list<Absyn.ElementArg> eltArgs;
  output tuple<String, String> license;
algorithm
  license := match eltArgs
    local
      Option<Absyn.Modification> mod;
      list<Absyn.ElementArg> xs;
      String libraryKey, licenseFile;

    case ({}) then ("", "");

    case (Absyn.MODIFICATION(path = Absyn.IDENT(name="License"), modification = mod)::_)
      equation
        (libraryKey, licenseFile) = getLicenseAnnotationTuple(mod);
      then (libraryKey, licenseFile);

    case (_::xs)
      equation
        (libraryKey, licenseFile) = getLicenseAnnotationWork2(xs);
      then (libraryKey, licenseFile);

  end match;
end getLicenseAnnotationWork2;

protected function getLicenseAnnotationTuple
  "Extractor function for getLicenseAnnotation"
  input Option<Absyn.Modification> mod;
  output tuple<String, String> license;
algorithm
  license := match (mod)
    local
      list<Absyn.ElementArg> arglst;
      String libraryKey, licenseFile;

    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      equation
        libraryKey = getLicenseAnnotationLibraryKey(arglst);
        licenseFile = getLicenseAnnotationLicenseFile(arglst);
      then (libraryKey, licenseFile);
  end match;
end getLicenseAnnotationTuple;

protected function getLicenseAnnotationLibraryKey
  "Extractor function for getLicenseAnnotation"
  input list<Absyn.ElementArg> eltArgs;
  output String libraryKey;
algorithm
  libraryKey := match eltArgs
    local
      list<Absyn.ElementArg> xs;
      String s;

    case ({}) then "";

    case (Absyn.MODIFICATION(path = Absyn.IDENT(name="libraryKey"), modification = SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=Absyn.STRING(s)))))::_)
      then s;

    case (_::xs)
      equation
        s = getLicenseAnnotationLibraryKey(xs);
      then s;

    end match;
end getLicenseAnnotationLibraryKey;

protected function getLicenseAnnotationLicenseFile
  "Extractor function for getLicenseAnnotation"
  input list<Absyn.ElementArg> eltArgs;
  output String licenseFile;
algorithm
  licenseFile := match eltArgs
    local
      list<Absyn.ElementArg> xs;
      String s;

    case ({}) then "";

    case (Absyn.MODIFICATION(path = Absyn.IDENT(name="licenseFile"), modification = SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=Absyn.STRING(s)))))::_)
      then s;

    case (_::xs)
      equation
        s = getLicenseAnnotationLicenseFile(xs);
      then s;

    end match;
end getLicenseAnnotationLicenseFile;

protected function getFeaturesAnnotation
  "Returns the Protection(features=) annotation of a class.
  This is annotated with the annotation:
  annotation(Protection(features={\"LicenseOption1 LicenseOption2\", \"LicenseOption3\"})); in the class definition"
  input Absyn.Class className;
  output list<String> features;
protected
  Option<list<String>> opt_featuresList;
algorithm
  opt_featuresList := AbsynUtil.getNamedAnnotationInClass(className, Absyn.IDENT("Protection"), getFeaturesAnnotationList);
  features := Util.getOptionOrDefault(opt_featuresList, {});
end getFeaturesAnnotation;

protected function getFeaturesAnnotationList
  "Extractor function for getFeaturesAnnotation"
  input Option<Absyn.Modification> mod;
  output list<String> features;
algorithm
  features := match (mod)
    local
      list<Absyn.ElementArg> arglst;

    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      then getFeaturesAnnotationList2(arglst);

  end match;
end getFeaturesAnnotationList;

protected function getFeaturesAnnotationList2
  "Extractor function for getFeaturesAnnotation"
  input list<Absyn.ElementArg> eltArgs;
  output list<String> features;
algorithm
  features := match eltArgs
    local
      list<Absyn.Exp> expList;
      list<Absyn.ElementArg> xs;
      list<String> featuresList;

    case ({}) then {};

    case (Absyn.MODIFICATION(path = Absyn.IDENT(name="features"), modification = SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=Absyn.ARRAY(expList)))))::_)
      equation
        featuresList = List.map(expList, expToString);
      then featuresList;

    case (_::xs)
      equation
        featuresList = getFeaturesAnnotationList2(xs);
      then featuresList;

    end match;
end getFeaturesAnnotationList2;

protected function expToString
  input Absyn.Exp inExp;
  output String outExp;
algorithm
  outExp := match (inExp)
    local
      String str;
    case (Absyn.STRING(str)) then str;
    case (_) then "";
  end match;
end expToString;

annotation(__OpenModelica_Interface="frontend");
end Parser;

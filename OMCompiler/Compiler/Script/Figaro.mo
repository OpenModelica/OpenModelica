encapsulated package Figaro "Figaro support."

// Imports
import Absyn;
import Error;
import SCode;
import SCodeUtil;
protected

import Autoconf;
import System;

// Aliases
public type Ident = Absyn.Ident;
public type Path = Absyn.Path;
public type TypeSpec = Absyn.TypeSpec;

public function run "The main function to be called from CevalScript. This one is very imperative
because of all the side-effects. However, all of them are captured here."
  input SCode.Program inProgram;
  input Path inPath;
  input String workingDir "working directory";
  input String inDatabaseFile "Figaro database file";
  input String inMode "Figaro processor mode";
  input String inOptions "Figaro fault tree generation options";
  input String inFigaroProcessorFile "Figaro processor to call";
protected
  String bdfFile = workingDir + "/FigaroObjects.fi" "Figaro code to the Figaro processor";
  String figaroFile = workingDir + "/Figaro0.fi" "Figaro code from the Figaro processor";
  String argumentFile = workingDir + "/figp_commands.xml" "instructions to the Figaro processor";
  String resultFile = System.pwd() + "/result.xml" "status from the Figaro processor"; // File name cannot be changed.
  SCode.Element program;
  String figaro, database, xml, xml2;
  list<String> sl;
algorithm

  program := SCodeUtil.getElementWithPathCheckBuiltin(inProgram, inPath);

  // Code for the Figaro objects.
  figaro := makeFigaro(inProgram, program, inProgram);

  if figaro == ""
    then fail();
  end if;
  System.writeFile(bdfFile, figaro);

  // Get XML defining the database.
  //database := System.readFile(inDatabaseFile);
  database := inDatabaseFile;
  //database := System.trimWhitespace(database);

  // Instructions for the Figaro processor.
  xml := makeXml(workingDir, database, bdfFile, inMode, inOptions, figaroFile);
  System.writeFile(argumentFile, xml);

  callFigaroProcessor(inFigaroProcessorFile, argumentFile);

  // Temporary (or maybe permanent) fix because the Figaro processor works in an asynchronous way.

 if Autoconf.os == "Windows_NT" then
     System.systemCall("timeout 5");
 else
  System.systemCall("sleep 5");
  end if;

  // Result from the Figaro processor.
  xml2 := System.readFile(resultFile);
  sl := interpret(xml2);
  if reportErrors(sl)
    then
   /* Error.addMessage(Error.FIGARO_ERROR, {"For more information see" + System.pwd() + "/result.xml"}); */
    fail();
  end if;
end run;

protected uniontype FigaroClass "A class that has a corresponding class in Figaro."
  record FIGAROCLASS
    Ident className;
    String typeName "Figaro type name";
  end FIGAROCLASS;
end FigaroClass;

protected uniontype FigaroObject "A component that will be an object in Figaro."
  record FIGAROOBJECT
    String objectName;
    String typeName "Figaro type name";
    String figaroCode "a piece of Figaro code that belongs to the object";
  end FIGAROOBJECT;
end FigaroObject;

public function makeFigaro "Translates a program to Figaro. First finds all relevant classes. Then
finds all instances of those classes."
  input list<SCode.Element> inProgram;
  input SCode.Element inModel;
  input list<SCode.Element>  env;
  output String outCode;
protected
  list<FigaroClass> fcl;
  list<FigaroObject> fol;
algorithm
  fcl := listAppend(
    fcElementList("Figaro_Object", "", inModel, NONE(), inProgram, env),
    fcElementList("Figaro_Object_connector", "", inModel, NONE(), inProgram, env)
  );

  // Debug.
  printFigaroClassList(fcl);
  print("\n\n");

  fol := foElement(fcl, inModel);

  // Debug.
  printFigaroObjectList(fol);

  outCode := figaroObjectListToString(fol);
end makeFigaro;

/* Finds all classes derived from the specified base class and also
carries along the Figaro type name in order to assign the correct Figaro type to a class if it
does not have an explicit fullClassName modifier. */

protected function fcElement
  input Ident inFigaroBase;
  input String inFigaroType;
  input SCode.Element inProgram;

  input Option<Ident> inClassName;

  input SCode.Element inElement;
  input list<SCode.Element>  env;
  output list<FigaroClass> outFigaroClassList;
algorithm
  outFigaroClassList := matchcontinue (inFigaroBase, inFigaroType, inProgram, inClassName, inElement, env)
    local
      Ident fb;
      String ft;
      SCode.Element program, cdef;
      list<SCode.Element> e;
      Ident cn;
      Path bcp;
      SCode.Mod m;
      String tn;
      Ident n;
      SCode.ClassDef cd;
      Path p;
    // Element is an extends clause.
    case (fb, ft, program, SOME(cn), SCode.EXTENDS(baseClassPath = bcp, modifications = m), e)
      equation

        true = fb == getLastIdent(bcp);
        tn = fcMod1(m);
      then fcAddFigaroClass(ft, program, cn, tn, e);
    case (fb, ft, program, SOME(cn), SCode.EXTENDS(baseClassPath = bcp, modifications = m), e)
      equation
        cdef = SCodeUtil.getElementWithPathCheckBuiltin(e, bcp);
        true = fcExtends(fb, ft, program, SOME(cn), cdef, e);
        tn = fcMod1(m);
      then fcAddFigaroClass(ft, program, cn, tn, e);
    // Nested class of some sort.
    case (fb, ft, program, _, SCode.CLASS(name = n, classDef = cd), e)
      then fcClassDef(fb, ft, program, n, cd, e);
  end matchcontinue;
end fcElement;

protected function fcExtends
  input Ident inFigaroBase;
  input String inFigaroType;
  input SCode.Element inProgram;
  input Option<Ident> inClassName;

  input SCode.Element inElement;
  input list<SCode.Element>  env;
  output Boolean doExtend;
algorithm
  doExtend := matchcontinue (inFigaroBase, inFigaroType, inProgram, inClassName, inElement, env)
    local
      Ident fb;
      String ft;
      SCode.Element program, cdef;
      list<SCode.Element> e, el;
      Ident cn;
      Path bcp;
      SCode.Mod m;
      String tn;
      Ident n;
      SCode.ClassDef cd;
      Path p;
    // Element is an extends clause.
    case (fb, ft, program, _, SCode.CLASS(name = n, classDef = SCode.PARTS(elementLst = el)), e)
      equation
      then fcElementListExt(fb, ft, program, SOME(n), el, e);
    case (fb, _, _, SOME(_), SCode.EXTENDS(baseClassPath = bcp), _)
      equation
        true = fb == getLastIdent(bcp);
      then true;
    case (fb, ft, program, SOME(cn), SCode.EXTENDS(baseClassPath = bcp), e)
      equation
        cdef = SCodeUtil.getElementWithPathCheckBuiltin(e, bcp);
      then fcExtends(fb, ft, program, SOME(cn), cdef, e);
    // Nested class of some sort.
    case (_, _, _, _, _, _)
      then false;
  end matchcontinue;
end fcExtends;

protected function fcElementListExt
  input Ident inFigaroBase;
  input String inFigaroType;
  input SCode.Element inProgram;
  input Option<Ident> inClassName;
  input list<SCode.Element> inElementList;
  input list<SCode.Element> env;
  output Boolean res;
algorithm
  res := matchcontinue (inFigaroBase, inFigaroType, inProgram, inClassName, inElementList, env)
    local
      Ident fb;
      String ft;
      SCode.Element program;
      Option<Ident> cn;
      list<SCode.Element> e;
      SCode.Element first;
      list<SCode.Element> rest;
      list<FigaroClass> rf, rr;
    case (_, _, _, _, {}, _)
      then false;
    case (fb, ft, program, cn, first :: _, e)
      equation
        true = fcExtends(fb, ft, program, cn, first, e);
      then true;
    case (fb, ft, program, cn, _ :: rest, e)
      then fcElementListExt(fb, ft, program, cn, rest, e);
  end matchcontinue;
end fcElementListExt;

protected function fcAddFigaroClass "Adds Figaro class. Finds classes inherited from that class."
  input String inFigaroType;
  input SCode.Element inProgram;
  input Ident inClassName;

  input String inTypeName;
   input list<SCode.Element>  env;
  output list<FigaroClass> outFigaroClassList;
protected
  String tn;
  FigaroClass fc;
algorithm
  tn := if inTypeName == "" then inFigaroType else inTypeName;
  fc := FIGAROCLASS(inClassName, tn);
  outFigaroClassList := fc :: fcElement(inClassName, tn, inProgram, NONE(), inProgram, env);
end fcAddFigaroClass;

protected function fcClassDef
  input Ident inFigaroBase;
  input String inFigaroType;
  input SCode.Element inProgram;

  input Ident inClassName;
  input SCode.ClassDef inClassDef;
  input list<SCode.Element>  env;
  output list<FigaroClass> outFigaroClassList;
algorithm
  outFigaroClassList := match (inFigaroBase, inFigaroType, inProgram, inClassName, inClassDef, env)
    local
      Ident fb;
      String ft;
      SCode.Element program;
      Ident cn;
      list<SCode.Element> e;
      list<SCode.Element> el;
      TypeSpec ts;
      SCode.Mod m;
      Path p;
      String tn;
    case (fb, ft, program, cn, SCode.PARTS(elementLst = el), e)
      then fcElementList(fb, ft, program, SOME(cn), el, e);
    // Short class definitions.
    case (fb, ft, program, cn, SCode.DERIVED(typeSpec = ts, modifications = m), e)
      equation
        p = Absyn.typeSpecPath(ts);
        true = fb == getLastIdent(p);
        tn = fcMod1(m);
      then fcAddFigaroClass(ft, program, cn, tn, e);
  end match;
end fcClassDef;

protected function fcElementList
  input Ident inFigaroBase;
  input String inFigaroType;
  input SCode.Element inProgram;
  input Option<Ident> inClassName;
  input list<SCode.Element> inElementList;
  input list<SCode.Element> env;
  output list<FigaroClass> outFigaroClassList;
algorithm
  outFigaroClassList := matchcontinue (inFigaroBase, inFigaroType, inProgram, inClassName, inElementList, env)
    local
      Ident fb;
      String ft;
      SCode.Element program;
      Option<Ident> cn;
      list<SCode.Element> e;
      SCode.Element first;
      list<SCode.Element> rest;
      list<FigaroClass> rf, rr;
    case (_, _, _, _, {}, _)
      then {};
    case (fb, ft, program, cn, first :: rest, e)
      equation
        rf = fcElement(fb, ft, program, cn, first, e);
        rr = fcElementList(fb, ft, program, cn, rest, e);
      then listAppend(rf, rr);
    case (fb, ft, program, cn, _ :: rest, e)
      then fcElementList(fb, ft, program, cn, rest, e);
  end matchcontinue;
end fcElementList;

protected function fcMod1
  input SCode.Mod inMod;
  output String outTypeName;
algorithm
  outTypeName := match inMod
    local
      list<SCode.SubMod> sml;
    case SCode.MOD(subModLst = sml)
      then fcSubModList(sml);
    case SCode.NOMOD()
      then "";
  end match;
end fcMod1;

protected function fcSubModList
  input list<SCode.SubMod> inSubModList;
  output String outTypeName;
algorithm
  outTypeName := matchcontinue inSubModList
    local
      SCode.SubMod first;
      list<SCode.SubMod> rest;
    case {}
      then "";
    case first :: _
      then fcSubMod(first);
    case _ :: rest
      then fcSubModList(rest);
  end matchcontinue;
end fcSubModList;

protected function fcSubMod
  input SCode.SubMod inSubMod;
  output String outTypeName;
algorithm
  outTypeName := match inSubMod
    local
      Ident n;
      SCode.Mod m;
    case SCode.NAMEMOD(ident = n, mod = m)
      equation
        true = n == "fullClassName";
      then fcMod2(m);
  end match;
end fcSubMod;

protected function fcMod2
  input SCode.Mod inMod;
  output String outTypeName;
algorithm
  outTypeName := match inMod
    local
      Absyn.Exp e;
    case SCode.MOD(binding = NONE())
      then "";
    case SCode.MOD(binding = SOME(e))
      then fcExp(e);
  end match;
end fcMod2;

protected function fcExp "returns the actual Figaro type name"
  input Absyn.Exp inExp;
  output String outTypeName;
algorithm
  outTypeName := match inExp
    local
      String tn;
    case Absyn.STRING(value = tn)
      then tn;
  end match;
end fcExp;

/* Finds declarations and checks whether the type matches any of the Figaro classes.
If that is the case, then those objects are collected. */

protected function foElement
  input list<FigaroClass> inFigaroClassList;

  input SCode.Element inElement;
  output list<FigaroObject> outFigaroObjectList;
algorithm
  outFigaroObjectList := match (inFigaroClassList, inElement)
    local
      list<FigaroClass> fcl;

      Ident n;
      SCode.ClassDef cd;
      Path p;
      TypeSpec ts;
      SCode.Mod m;
      String tn;
      String c, tmp;
      FigaroObject fo;
    case (fcl, SCode.CLASS(classDef = cd))
      then foClassDef(fcl, cd);
    case (fcl, SCode.COMPONENT(name = n, typeSpec = ts, modifications = m))
      equation
        p = Absyn.typeSpecPath(ts);
        //tn = findFigaroTypeName(p, fcl);
        tmp = foMod1(m, "fullClassName");
        tn = if tmp == "" then findFigaroTypeName(p, fcl) else tmp;
        c = foMod1(m, "codeInstanceFigaro");
        fo = FIGAROOBJECT(n, tn, c);
      then {fo};
  end match;
end foElement;

protected function foClassDef
  input list<FigaroClass> inFigaroClassList;

  input SCode.ClassDef inClassDef;
  output list<FigaroObject> outFigaroObjectList;
algorithm
  outFigaroObjectList := match (inFigaroClassList, inClassDef)
    local
      list<FigaroClass> fcl;
      list<SCode.Element> el;
    case (fcl, SCode.PARTS(elementLst = el))
      then foElementList(fcl, el);
  end match;
end foClassDef;

protected function foElementList
  input list<FigaroClass> inFigaroClassList;

  input list<SCode.Element> inElementList;
  output list<FigaroObject> outFigaroObjectList;
algorithm
  outFigaroObjectList := matchcontinue (inFigaroClassList, inElementList)
    local
      list<FigaroClass> fcl;
      SCode.Element first;
      list<SCode.Element> rest;
      list<FigaroObject> rf, rr;
    case (_, {})
      then {};
    case (fcl, first :: rest)
      equation
        rf = foElement(fcl, first);
        rr = foElementList(fcl, rest);
      then listAppend(rf, rr);
    case (fcl, _ :: rest)
      then foElementList(fcl, rest);
  end matchcontinue;
end foElementList;

protected function findFigaroTypeName
  input Path inClassPath;
  input list<FigaroClass> inFigaroClassList;
  output String outTypeName;
algorithm
  outTypeName := matchcontinue (inClassPath, inFigaroClassList)
    local
      Path p;
      FigaroClass first;
      list<FigaroClass> rest;
      String tn;
    case (_, {})
      then fail();
    case (p, first :: _)
      equation
        tn = getFigaroTypeName(p, first);
      then tn;
    case (p, _ :: rest)
      equation
        tn = findFigaroTypeName(p, rest);
      then tn;
  end matchcontinue;
end findFigaroTypeName;

protected function getFigaroTypeName
  input Path inClassPath;
  input FigaroClass inFigaroClass;
  output String outTypeName;
algorithm
  outTypeName := match (inClassPath, inFigaroClass)
    local
      Path p;
      Ident cn;
      String tn;
    case (p, FIGAROCLASS(className = cn, typeName = tn))
      equation
        true = getLastIdent(p) == cn;
      then tn;
  end match;
end getFigaroTypeName;

protected function foMod1
  input SCode.Mod inMod;
  input String name;
  output String outCode;
algorithm
  outCode := match inMod
    local
      list<SCode.SubMod> sml;
    case SCode.MOD(subModLst = sml)
      then foSubModList(sml, name);
    case SCode.NOMOD()
      then "";
  end match;
end foMod1;

protected function foSubModList
  input list<SCode.SubMod> inSubModList;
  input String name;
  output String outCode;
algorithm
  outCode := matchcontinue inSubModList
    local
      SCode.SubMod first;
      list<SCode.SubMod> rest;
    case {}
      then "";
    case first :: _
      then foSubMod(first, name);
    case _ :: rest
      then foSubModList(rest, name);
  end matchcontinue;
end foSubModList;

protected function foSubMod
  input SCode.SubMod inSubMod;
  input String name;
  output String outCode;
algorithm
  outCode := match inSubMod
    local
      Ident n;
      SCode.Mod m;
    case SCode.NAMEMOD(ident = n, mod = m)
      equation
        true = n == name;
      then foMod2(m);
  end match;
end foSubMod;

protected function foMod2
  input SCode.Mod inMod;
  output String outCode;
algorithm
  outCode := match inMod
    local
      Absyn.Exp e;
    case SCode.MOD(binding = NONE())
      then "";
    case SCode.MOD(binding = SOME(e))
      then foExp(e);
  end match;
end foMod2;

protected function foExp "returns the actual Figaro code"
  input Absyn.Exp inExp;
  output String outCode;
algorithm
  outCode := match inExp
    local
      String c;
    case Absyn.STRING(value = c)
      then c;
  end match;
end foExp;

protected function getLastIdent "Retrieves the last identifier in a path."
  input Path inPath;
  output Ident outIdent;
algorithm
  outIdent := match inPath
    local
      Path p;
      Ident n;
    case Absyn.QUALIFIED(path = p)
      then getLastIdent(p);
    case Absyn.IDENT(name = n)
      then n;
    case Absyn.FULLYQUALIFIED(path = p)
      then getLastIdent(p);
  end match;
end getLastIdent;

protected function figaroObjectListToString "Makes Figaro code from a list of Figaro objects."
  input list<FigaroObject> inFigaroObjectList;
  output String outString;
algorithm
  outString := match inFigaroObjectList
    local
      FigaroObject first;
      list<FigaroObject> rest;
      String rf, rr;
    case {}
      then "";
    case first :: rest
      equation
        rf = figaroObjectToString(first);
        rr = figaroObjectListToString(rest);
      then rf + rr;
  end match;
end figaroObjectListToString;

protected function figaroObjectToString "Makes Figaro code from a Figaro object."
  input FigaroObject inFigaroObject;
  output String outString;
algorithm
  outString := match inFigaroObject
    local
      String on;
      String tn;
      String fc;
      String middle;
    case FIGAROOBJECT(objectName = on, typeName = tn, figaroCode = fc)
      equation
        middle = if fc == "" then "" else "\n" + fc;
      then "OBJECT " + on + " IS_A " + tn + ";" + middle + "\n\n";
  end match;
end figaroObjectToString;

protected function makeXml "Makes instructions for the Figaro processor."
  input String workingDir;
  input String inDatabase "database the Figaro processor will use";
  input String inBdfFile "Figaro code to the Figaro processor";
  input String inMode "Figaro processor mode";
  input String inOptions "Figaro fault tree generation options";
  input String inFigaroFile "Figaro code from the Figaro processor";
  output String outXml;
protected
  String xml, newName;
  list<String> sl;
algorithm
  xml := "<REQUESTS>\n  ";
  xml := xml + "\n\n<LOAD_BDC_FI>\n    <FILE_FI>";
  xml := xml + inDatabase + "</FILE_FI>\n";

  // In case a dbc file exists
  sl := stringListStringChar(inDatabase);
  newName := truncateExtension(sl);
  if System.regularFileExists(newName + ".bdc") then
  xml := xml + "<FILE> " + newName + ".bdc</FILE>\n";
  end if;
  xml := xml + "</LOAD_BDC_FI>\n";
  xml := xml + "\n\n<LOAD_BDF_FI>\n    <FILE>";
  xml := xml + inBdfFile;
  xml := xml + "</FILE>\n</LOAD_BDF_FI>\n";
  xml := xml + "<RUN_TREATMENT>\n";


  // In case the fault tree will be needed.
  if inMode == "figaro0" then
    xml := xml + "    <TREATMENT>GENERATE_FIG0</TREATMENT>\n    <FILE>";
    xml := xml + inFigaroFile;
    xml := xml + "</FILE>";
  elseif inMode == "fault-tree" then
    xml := xml + "    <TREATMENT>GENERATE_TREE</TREATMENT>\n    <FILE>";
    xml := xml + workingDir + "/FaultTree.xml";
    xml := xml + "</FILE>\n";
    xml := xml + "    <FILE_MACRO>fiab_ADD.h</FILE_MACRO>";
    xml := xml + "\n    <FILE_TREE_OPTIONS>" + inOptions + "</FILE_TREE_OPTIONS>";
  end if;

  xml := xml + "\n    <RESOLVE_CONST>VRAI</RESOLVE_CONST>\n    <RESOLVE_ATTR>FAUX</RESOLVE_ATTR>\n    <INST_RULE>VRAI</INST_RULE>\n";
  xml := xml + "</RUN_TREATMENT>\n</REQUESTS>";
  outXml := xml;
end makeXml;

protected function truncateExtension
   input List<String> name;

   output String newName;
  algorithm
     newName := match name
      local String c;
        List<String> rest;
     case "."::_
        then "";
     case c::rest
      then stringAppend (c, truncateExtension(rest));
  end match;
end truncateExtension;

protected function callFigaroProcessor "Calls the Figaro processor."
  input String inFigaroProcessorFile "Figaro processor to call";
  input String inArgumentFile "argument to the Figaro processor";
protected
  String command;
algorithm
  command := "start " + inFigaroProcessorFile + " -testxml " + inArgumentFile;
  System.systemCall(command);
end callFigaroProcessor;

protected uniontype Token "An XML token."
  record OPENTAG
    String tagName;
  end OPENTAG;
  record CLOSETAG
    String tagName;
  end CLOSETAG;
  record TEXT
    String text;
  end TEXT;
end Token;

protected function interpret "Interprets XML from the Figaro processor."
  input String inString "XML to interpret";
  output list<String> outStringList "errors found";
algorithm
  outStringList := match inString
    local
      String s;
      list<String> sl, sl2;
      list<Token> tl, tl2, tl3;
    case s
      equation
        sl = stringListStringChar(s);
        tl = scan(sl);
        tl2 = removeFirstIfText(tl);
        tl3 = removeTokens(tl2);
        sl2 = parse(tl3);
      then sl2;
    case _
      equation
        // Report unknown error. Bad XML.
      then fail();
  end match;
end interpret;

protected function scan "Lexer main function."
  input list<String> inStringList "character sequence to scan";
  output list<Token> outTokenList "token sequence";
algorithm
  outTokenList := matchcontinue inStringList
    local
      String first;
      list<String> rest, r;
      Token t;
      String s;
    case {}
      then {};
    // XML declaration.
    case "<" :: "?" :: rest
      equation
        r = scanDeclaration(rest);
      then scan(r);
    // Closing tag.
    case "<" :: "/" :: rest
      equation
        (r, s) = scanTagName(rest);
        t = CLOSETAG(s);
      then t :: scan(r);
    // Opening tag.
    case "<" :: rest
      equation
        (r, s) = scanTagName(rest);
        t = OPENTAG(s);
      then t :: scan(r);
    // Some text.
    case rest
      equation
        (r, s) = scanText(rest);
        t = TEXT(s);
      then t :: scan(r);
  end matchcontinue;
end scan;

protected function scanDeclaration "Scans a declaration."
  input list<String> inStringList "string sequence to scan";
  output list<String> outStringList "string sequence to continue scanning";
algorithm
  outStringList := matchcontinue inStringList
    local
      list<String> rest;
    case "?" :: ">" :: rest
      then rest;
    case _ :: rest
      then scanDeclaration(rest);
  end matchcontinue;
end scanDeclaration;

protected function scanTagName "Scans a tag name."
  input list<String> inStringList "string sequence to scan";
  input String inTagName = "" "accumulated tag name";
  output list<String> outStringList "string sequence to continue scanning";
  output String outTagName;
algorithm
  (outStringList, outTagName) := matchcontinue inStringList
    local
      String first;
      list<String> rest;
    case ">" :: rest
      then (rest, inTagName);
    case first :: rest
      then scanTagName(rest, inTagName + first);
  end matchcontinue;
end scanTagName;

protected function scanText "Greedy. Scans text until some kind of tag begins."
  input list<String> inStringList "string sequence to scan";
  input String inText = "" "accumulated text";
  output list<String> outStringList "string sequence to continue scanning";
  output String outText;
algorithm
  (outStringList, outText) := matchcontinue inStringList
    local
      String first;
      list<String> rest;
    case {}
      then ({}, "");
    case "<" :: _
      then (inStringList, inText);
    case first :: rest
      then scanText(rest, inText + first);
  end matchcontinue;
end scanText;

/* These functions walk over the token sequence from the lexer and throw away tokens that will not
be usable. E. g., if a tag is not known, the tokens associated with it will be thrown away.
The purpose of this step is to return a very simple sequence for the parser to work on. */

protected function removeTokens
  input list<Token> inTokenList;
  output list<Token> outTokenList;
algorithm
  outTokenList := matchcontinue inTokenList
    local
      Token first;
      list<Token> rest, r;
      String tn;
    case {}
      then {};
    case OPENTAG(tagName = tn) :: rest
      equation
        true = isKnownTag(tn);
        false = isInfoTag(tn);
        r = removeFirstIfText(rest);
      then OPENTAG(tn) :: removeTokens(r);
    case OPENTAG(tagName = tn) :: rest
      equation
        false = isKnownTag(tn);
        r = removeUnknown(rest, tn);
      then removeTokens(r);
    case CLOSETAG(tagName = tn) :: rest
      equation
        r = removeFirstIfText(rest);
      then CLOSETAG(tn) :: removeTokens(r);
    case first :: rest
      then first :: removeTokens(rest);
  end matchcontinue;
end removeTokens;

protected function removeFirstIfText
  input list<Token> inTokenList;
  output list<Token> outTokenList;
algorithm
  outTokenList := match inTokenList
    local
      list<Token> rest;
    case TEXT() :: rest
      then rest;
    else
      inTokenList;
  end match;
end removeFirstIfText;

protected function removeUnknown "Removes tokens until the closing tag is found."
  input list<Token> inTokenList;
  input String inTagName;
  output list<Token> outTokenList;
algorithm
  outTokenList := matchcontinue inTokenList
    local
      String tn;
      list<Token> rest;
    case {}
      then {};
    case CLOSETAG(tagName = tn) :: rest
      equation
        true = tn == inTagName;
      then removeFirstIfText(rest);
    case _ :: rest
      then removeUnknown(rest, inTagName);
  end matchcontinue;
end removeUnknown;

protected function isKnownTag "Answers whether the tag contributes to the tree structure we want to
parse for fault analysis."
  input String inTagName;
  output Boolean outBoolean;
protected
  list<String> ktl = {"ANSWERS", "ANSWER", "ERROR", "LABEL", "CRITICITY"} "list of tags defining
  the important structure";
algorithm
  outBoolean := listMember(inTagName, ktl);
end isKnownTag;

protected function isInfoTag "Answers whether a tag gives us any concrete information about an error."
  input String inTagName;
  output Boolean outBoolean;
protected
  list<String> itl = {"LABEL", "CRITICITY"} "list of tags containing information about an error";
algorithm
  outBoolean := listMember(inTagName, itl);
end isInfoTag;

protected function parse "Parser main function."
  input list<Token> inTokenList "token sequence to parse";
  output list<String> outStringList "list of error messages";
algorithm
  outStringList := match inTokenList
    local
      String tn;
      list<Token> rest;
    case {}
      then {};
    case OPENTAG(tagName = tn) :: rest
      equation
        true = tn == "ANSWERS";
      then parseAnswers(rest);
  end match;
end parse;

protected function parseAnswers
  input list<Token> inTokenList;
  output list<String> outStringList "list of error messages";
protected
  list<String> sl;
algorithm
  (sl, _) := parseAnswerList(inTokenList);
  outStringList := sl;
end parseAnswers;

protected function parseAnswerList
  input list<Token> inTokenList;
  output list<String> outStringList "list of error messages";
  output list<Token> outTokenList;
algorithm
  (outStringList, outTokenList) := match inTokenList
    local
      String tn;
      list<String> sl, sl2;
      list<Token> rest, tl, tl2;
    case OPENTAG(tagName = tn) :: rest
      equation
        true = tn == "ANSWER";
        (sl, tl) = parseAnswer(rest);
        (sl2, tl2) = parseAnswerList(tl);
      then (listAppend(sl, sl2), tl2);
    case CLOSETAG(tagName = tn) :: rest
      equation
        true = tn == "ANSWERS";
      then ({}, rest);
  end match;
end parseAnswerList;

protected function parseAnswer
  input list<Token> inTokenList;
  output list<String> outStringList "list of error messages";
  output list<Token> outTokenList;
algorithm
  (outStringList, outTokenList) := parseErrorList(inTokenList);
end parseAnswer;

protected function parseErrorList
  input list<Token> inTokenList;
  output list<String> outStringList "list of error messages";
  output list<Token> outTokenList;
algorithm
  (outStringList, outTokenList) := match inTokenList
    local
      String tn;
      list<String> sl, sl2;
      list<Token> rest, tl, tl2;
    case OPENTAG(tagName = tn) :: rest
      equation
        true = tn == "ERROR";
        (sl, tl) = parseError(rest);
        (sl2, tl2) = parseErrorList(tl);
      then (listAppend(sl, sl2), tl2);
    case CLOSETAG(tagName = tn) :: rest
      equation
        true = tn == "ANSWER";
      then ({}, rest);
  end match;
end parseErrorList;

protected function parseError
  input list<Token> inTokenList;
  output list<String> outStringList "list of error messages";
  output list<Token> outTokenList;
protected
  list<tuple<String, String>> stl;
  list<Token> tl;
  list<String> sl;
algorithm
  (stl, tl) := parseInfoList(inTokenList);
  sl := if isToBeReported(stl) then {getMessage(stl)} else {};
  (outStringList, outTokenList) := (sl, tl);
end parseError;

protected function parseInfoList
  input list<Token> inTokenList;
  output list<tuple<String, String>> outStringTupleList;
  output list<Token> outTokenList;
algorithm
  (outStringTupleList, outTokenList) := match inTokenList
    local
      String tn, s;
      list<tuple<String, String>> stl;
      list<Token> rest, tl, tl2;
    case OPENTAG(tagName = tn) :: rest
      equation
        (s, tl) = parseInfo(rest);
        (stl, tl2) = parseInfoList(tl);
      then ((tn, s) :: stl, tl2);
    case CLOSETAG(tagName = tn) :: rest
      equation
        true = tn == "ERROR";
      then ({}, rest);
  end match;
end parseInfoList;

protected function parseInfo
  input list<Token> inTokenList;
  output String outString;
  output list<Token> outTokenList;
algorithm
  (outString, outTokenList) := match inTokenList
    local
      String s;
      list<Token> rest;
    case TEXT(s) :: _ :: rest
      then (s, rest);
  end match;
end parseInfo;

protected function isToBeReported "Answers whether an error should be reported."
  input list<tuple<String, String>> inStringTupleList;
  output Boolean outBoolean;
protected
  list<String> errorsToReport = {"FATAL" /*, "MAJOR" */} "list of errors we are interested in";
algorithm
  outBoolean := matchcontinue inStringTupleList
    local
      String k, v;
      list<tuple<String, String>> rest;
    case {}
      then false;
    case (k, v) :: _
      equation
        true = k == "CRITICITY";
      then listMember(v, errorsToReport);
    case _ :: rest
      then isToBeReported(rest);
  end matchcontinue;
end isToBeReported;

protected function getMessage "Retrieves the error message."
  input list<tuple<String, String>> inStringTupleList;
  output String outString;
algorithm
  outString := matchcontinue inStringTupleList
    local
      String k, v;
      list<tuple<String, String>> rest;
    case (k, v) :: _
      equation
        true = k == "LABEL";
      then v;
    case _ :: rest
      then getMessage(rest);
  end matchcontinue;
end getMessage;

protected function reportErrors "Reports Figaro errors one by one."
  input list<String> inStringList "list of error messages";
  output Boolean outBoolean "true if any error was reported";
algorithm
  outBoolean := match inStringList
    local
      String first;
      list<String> rest;
    case {}
      then false;
    case first :: rest
      equation
        // It has its own kind of error, because it is not a Modelica error.
        Error.addMessage(Error.FIGARO_ERROR, {first});
        reportErrors(rest);
      then true;
  end match;
end reportErrors;


/* Debug */

protected function printFigaroClassList
  input list<FigaroClass> inFigaroClassList;
algorithm
  _ := matchcontinue (inFigaroClassList)
    local
      FigaroClass first;
      list<FigaroClass> rest;
    case {}
      then ();
    case first :: rest
      equation
        printFigaroClass(first);
        printFigaroClassList(rest);
      then ();
    case _ :: rest
      equation
        printFigaroClassList(rest);
      then ();
  end matchcontinue;
end printFigaroClassList;

protected function printFigaroClass
  input FigaroClass inFigaroClass;
algorithm
  _ := match inFigaroClass
    local
      Ident cn;
      String tn;
    case FIGAROCLASS(className = cn, typeName = tn)
      equation
        print(cn + " = " + tn + "\n");
      then ();
  end match;
end printFigaroClass;

protected function printFigaroObjectList
  input list<FigaroObject> inFigaroObjectList;
algorithm
  _ := matchcontinue (inFigaroObjectList)
    local
      FigaroObject first;
      list<FigaroObject> rest;
    case {}
      then ();
    case first :: rest
      equation
        print(figaroObjectToString(first));
        printFigaroObjectList(rest);
      then ();
    case _ :: rest
      equation
        printFigaroObjectList(rest);
      then ();
  end matchcontinue;
end printFigaroObjectList;

protected function printTokenList
  input list<Token> inTokenList;
algorithm
  _ := matchcontinue inTokenList
    local
      Token first;
      list<Token> rest;
    case {}
      then ();
    case first :: rest
      equation
        printToken(first);
        print("\n");
        printTokenList(rest);
      then ();
    case _ :: rest
      equation
        printTokenList(rest);
      then ();
  end matchcontinue;
end printTokenList;

protected function printToken
  input Token inToken;
algorithm
  _ := match inToken
    local
      String s;
    case OPENTAG(tagName = s)
      equation
        print("OPEN: " + s);
      then ();
    case CLOSETAG(tagName = s)
      equation
        print("CLOSE: " + s);
      then ();
    case TEXT(text = s)
      equation
        print("\"" + s + "\"");
      then ();
  end match;
end printToken;

annotation(__OpenModelica_Interface="frontend");
end Figaro;

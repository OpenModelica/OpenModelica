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

encapsulated package ClassLoader
" file:        ClassLoader.mo
  package:     ClassLoader
  description: Loading of classes from $OPENMODELICALIBRARY.


  This module loads classes from $OPENMODELICALIBRARY. It exports several functions:
  loadClass function
  loadModel function
  loadFile function"

import Absyn;

protected
import Autoconf;
import BaseHashTable;
import Config;
import Debug;
import Error;
import Flags;
import HashTableStringToProgram;
import List;
import Parser;
import Settings;
import System;
import Util;

type HashTable = HashTableStringToProgram.HashTable;

protected

uniontype PackageOrder
  record CLASSPART
    Absyn.ClassPart cp;
  end CLASSPART;
  record ELEMENT
    Absyn.ElementItem element;
    Boolean pub "public";
  end ELEMENT;
  record CLASSLOAD
    String cl;
  end CLASSLOAD;
end PackageOrder;

uniontype LoadFileStrategy
  record STRATEGY_HASHTABLE
    HashTable ht;
  end STRATEGY_HASHTABLE;
  record STRATEGY_ON_DEMAND
    String encoding;
  end STRATEGY_ON_DEMAND;
end LoadFileStrategy;

public function loadClass
"This function takes a \'Path\' and the $OPENMODELICALIBRARY as a string
  and tries to load the class from the path.
  If the classname is qualified, the complete package is loaded.
  E.g. load_class(Modelica.SIunits.Voltage) -> whole Modelica package loaded."
  input Absyn.Path inPath;
  input list<String> priorityList;
  input String modelicaPath;
  input Option<String> encoding;
  input Boolean requireExactVersion = false;
  input Boolean encrypted = false;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inPath,priorityList,modelicaPath,encoding)
    local
      String gd,classname,mp,pack;
      list<String> mps;
      Absyn.Program p;
      Absyn.Path rest;
    /* Simple names: Just load the file if it can be found in $OPENMODELICALIBRARY */
    case (Absyn.IDENT(name = classname),_,mp,_)
      equation
        gd = Autoconf.groupDelimiter;
        mps = System.strtok(mp, gd);
        p = loadClassFromMps(classname, priorityList, mps, encoding, requireExactVersion, encrypted);
        checkOnLoadMessage(p);
      then
        p;
    /* Qualified names: First check if it is defined in a file pack.mo */
    case (Absyn.QUALIFIED(name = pack),_,mp,_)
      equation
        gd = Autoconf.groupDelimiter;
        mps = System.strtok(mp, gd);
        p = loadClassFromMps(pack, priorityList, mps, encoding, requireExactVersion, encrypted);
        checkOnLoadMessage(p);
      then
        p;
    /* failure */
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("ClassLoader.loadClass failed\n");
      then
        fail();
  end matchcontinue;
end loadClass;

protected function loadClassFromMps
"Loads a class or classes from a set of paths in OPENMODELICALIBRARY"
  input String id;
  input list<String> prios;
  input list<String> mps;
  input Option<String> encoding;
  input Boolean requireExactVersion = false;
  input Boolean encrypted = false;
  output Absyn.Program outProgram;
protected
  String mp, name, pwd, cmd, version, userLibraries;
  Boolean isDir, impactOK;
  Absyn.Class cl;
algorithm
  try
    (mp,name,isDir) := System.getLoadModelPath(id,prios,mps,requireExactVersion);
  else
    pwd := System.pwd();
    userLibraries := Settings.getHomeDir(Config.getRunningTestsuite()) + "/.openmodelica/libraries/";
    true := System.directoryExists(userLibraries);
    true := listMember(userLibraries, mps);
    System.cd(userLibraries);
    version := match prios
      case version::_ guard version <> "default" then version;
      else "";
    end match;
    cmd := "impact install \"" + id + (if version<>"" then "#" + version else "") + "\"";
    impactOK := 0==System.systemCall(cmd, "/dev/null");
    System.cd(pwd);
    if impactOK then
      Error.addMessage(Error.NOTIFY_IMPACT_FOUND, {id, (if version <> "" then (" "+version) else ""), userLibraries});
      (mp,name,isDir) := System.getLoadModelPath(id,prios,mps,true);
    else
      fail();
    end if;
  end try;
  // print("System.getLoadModelPath: " + id + " {" + stringDelimitList(prios,",") + "} " + stringDelimitList(mps,",") + " => " + mp + " " + name + " " + boolString(isDir));
  Config.setLanguageStandardFromMSL(name);
  cl := loadClassFromMp(id, mp, name, isDir, encoding, encrypted);
  outProgram := Absyn.PROGRAM({cl},Absyn.TOP());
end loadClassFromMps;

protected function loadClassFromMp
  input String id "the actual class name";
  input String path;
  input String name;
  input Boolean isDir;
  input Option<String> optEncoding;
  input Boolean encrypted = false;
  output Absyn.Class outClass;
algorithm
  outClass := match (id,path,name,isDir,optEncoding)
    local
      String pd,encoding,encodingfile;
      Absyn.Class cl;
      list<String> filenames;
      LoadFileStrategy strategy;
      Boolean lveStarted;
      Option<Integer> lveInstance;

    case (_,_,_,false,_)
      equation
        pd = Autoconf.pathDelimiter;
        /* Check for path/package.encoding; OpenModelica extension */
        encodingfile = stringAppendList({path,pd,"package.encoding"});
        encoding = System.trimChar(System.trimChar(if System.regularFileExists(encodingfile) then System.readFile(encodingfile) else Util.getOptionOrDefault(optEncoding,"UTF-8"),"\n")," ");
        strategy = STRATEGY_ON_DEMAND(encoding);
        cl = parsePackageFile(path + pd + name, strategy, false, Absyn.TOP(), id);
      then
        cl;

    case (_,_,_,true,_)
      equation
        /* Check for path/package.encoding; OpenModelica extension */
        pd = Autoconf.pathDelimiter;
        encodingfile = stringAppendList({path,pd,name,pd,"package.encoding"});
        encoding = System.trimChar(System.trimChar(if System.regularFileExists(encodingfile) then System.readFile(encodingfile) else Util.getOptionOrDefault(optEncoding,"UTF-8"),"\n")," ");

        if encrypted then
          (lveStarted, lveInstance) = Parser.startLibraryVendorExecutable(path + pd + name);
          if not lveStarted then
            fail();
          end if;
        end if;

        if (Config.getRunningTestsuite() or Config.noProc()==1) and not encrypted then
          strategy = STRATEGY_ON_DEMAND(encoding);
        else
          filenames = getAllFilesFromDirectory(path + pd + name, encrypted);
      // print("Files load in parallel:\n" + stringDelimitList(filenames, "\n") + "\n");
          strategy = STRATEGY_HASHTABLE(Parser.parallelParseFiles(filenames, encoding, Config.noProc(), path + pd + name, lveInstance));
        end if;
        cl = loadCompletePackageFromMp(id, name, path, strategy, Absyn.TOP(), Error.getNumErrorMessages(), encrypted);
        if (encrypted and lveStarted) then
          Parser.stopLibraryVendorExecutable(lveInstance);
        end if;
      then
        cl;
  end match;
end loadClassFromMp;

protected function getAllFilesFromDirectory
  input String dir;
  input Boolean encrypted;
  input list<String> acc = {};
  output list<String> files;
protected
  list<String> subdirs;
  String pd = Autoconf.pathDelimiter;
algorithm
  if encrypted then
    files := (dir + pd + "package.moc") :: listAppend(list(dir + pd + f for f in System.mocFiles(dir)), acc);
  else
    files := (dir + pd + "package.mo") :: listAppend(list(dir + pd + f for f in System.moFiles(dir)), acc);
  end if;
  subdirs := list(dir + pd + d for d in List.filter2OnTrue(System.subDirectories(dir), existPackage, dir, encrypted));
  files := List.fold1(subdirs, getAllFilesFromDirectory, encrypted, files);
end getAllFilesFromDirectory;

protected function loadCompletePackageFromMp
"Loads a whole package from the ModelicaPaths defined in OPENMODELICALIBRARY"
  input String id "actual class identifier";
  input Absyn.Ident inIdent;
  input String inString;
  input LoadFileStrategy strategy;
  input Absyn.Within inWithin;
  input Integer numError;
  input Boolean encrypted = false;
  output Absyn.Class cl;
algorithm
  cl := matchcontinue (id,inIdent,inString,inWithin)
    local
      String pd,mp_1,packagefile,orderfile,pack,mp,name,str;
      Absyn.Within within_;
      list<String> tv;
      Boolean pp,fp,ep;
      Absyn.Restriction r;
      list<Absyn.NamedArg> ca;
      list<Absyn.ClassPart> cp;
      Option<String> cmt;
      SourceInfo info;
      Absyn.Path path;
      Absyn.Within w2;
      list<PackageOrder> reverseOrder;
      list<Absyn.Annotation> ann;
    case (_,pack,mp,within_)
      equation
        pd = Autoconf.pathDelimiter;
        mp_1 = stringAppendList({mp,pd,pack});
        packagefile = stringAppendList({mp_1,pd,if encrypted then "package.moc" else "package.mo"});
        orderfile = stringAppendList({mp_1,pd,"package.order"});
        if not System.regularFileExists(packagefile) then
          Error.addInternalError("Expected file " + packagefile + " to exist", sourceInfo());
          fail();
        end if;
        // print("Look for " + packagefile + "\n");
        (cl as Absyn.CLASS(name,pp,fp,ep,r,Absyn.PARTS(tv,ca,cp,ann,cmt),info)) = parsePackageFile(packagefile, strategy, true, within_, id);
        // print("Got " + packagefile + "\n");
        reverseOrder = getPackageContentNames(cl, orderfile, mp_1, Error.getNumErrorMessages(), encrypted);
        path = Absyn.joinWithinPath(within_,Absyn.IDENT(id));
        w2 = Absyn.WITHIN(path);
        cp = List.fold4(reverseOrder, loadCompletePackageFromMp2, mp_1, strategy, w2, encrypted, {});
      then Absyn.CLASS(name,pp,fp,ep,r,Absyn.PARTS(tv,ca,cp,ann,cmt),info);
    case (_,pack,mp,_)
      equation
        true = numError == Error.getNumErrorMessages();
        Error.addInternalError("loadCompletePackageFromMp failed for unknown reason: mp=" + mp + " pack=" + pack, sourceInfo());
      then fail();
  end matchcontinue;
end loadCompletePackageFromMp;

protected function mergeBefore
  input Absyn.ClassPart cp;
  input list<Absyn.ClassPart> cps;
  output list<Absyn.ClassPart> ocp;
algorithm
  ocp := match (cp,cps)
    local
      list<Absyn.ElementItem> ei1,ei2,ei;
      list<Absyn.ClassPart> rest;
    case (Absyn.PUBLIC(ei1),Absyn.PUBLIC(ei2)::rest)
      equation
        ei = listAppend(ei1,ei2);
      then Absyn.PUBLIC(ei)::rest;
    case (Absyn.PROTECTED(ei1),Absyn.PROTECTED(ei2)::rest)
      equation
        ei = listAppend(ei1,ei2);
      then Absyn.PROTECTED(ei)::rest;
    else cp::cps;
  end match;
end mergeBefore;

protected function loadCompletePackageFromMp2
"Loads a whole package from the ModelicaPaths defined in OPENMODELICALIBRARY"
  input PackageOrder po "mo-file or directory";
  input String mp;
  input LoadFileStrategy strategy;
  input Absyn.Within w1 "With the parent added";
  input Boolean encrypted = false;
  input list<Absyn.ClassPart> acc;
  output list<Absyn.ClassPart> cps;
algorithm
  cps := match po
    local
      Absyn.ElementItem ei;
      String pd,file,id;
      Absyn.ClassPart cp;
      Absyn.Class cl;
      Boolean bDirectoryAndFileExists;

    case CLASSPART(cp)
      equation
        cps = mergeBefore(cp,acc);
      then cps;

    case ELEMENT(ei,true)
      equation
        cps = mergeBefore(Absyn.PUBLIC({ei}),acc);
      then cps;

    case ELEMENT(ei,false)
      equation
        cps = mergeBefore(Absyn.PROTECTED({ei}),acc);
      then cps;

    case CLASSLOAD(id)
      equation
        pd = Autoconf.pathDelimiter;
        file = mp + pd + id + (if encrypted then "/package.moc" else "/package.mo");
        bDirectoryAndFileExists = System.directoryExists(mp + pd + id) and System.regularFileExists(file);
        if bDirectoryAndFileExists then
          cl = loadCompletePackageFromMp(id,id,mp,strategy,w1,Error.getNumErrorMessages(),encrypted);
          ei = Absyn.makeClassElement(cl);
          cps = mergeBefore(Absyn.PUBLIC({ei}),acc);
        else
          file = mp + pd + id + (if encrypted then ".moc" else ".mo");
          if not System.regularFileExists(file) then
            Error.addInternalError("Expected file " + file + " to exist", sourceInfo());
            fail();
          end if;
          cl = parsePackageFile(file, strategy, false, w1, id);
          ei = Absyn.makeClassElement(cl);
          cps = mergeBefore(Absyn.PUBLIC({ei}),acc);
        end if;
      then cps;

  end match;
end loadCompletePackageFromMp2;

public function parsePackageFile
  "Parses a file containing a single class that matches the within"
  input String name;
  input LoadFileStrategy strategy;
  input Boolean expectPackage;
  input Absyn.Within w1 "Expected within of the package";
  input String pack "Expected name of the package";
  output Absyn.Class cl;
protected
  list<Absyn.Class> cs;
  Absyn.Within w2;
  list<String> classNames;
  SourceInfo info;
  String str,s1,s2,cname;
  Absyn.ClassDef body;
algorithm
  Absyn.PROGRAM(cs,w2) := getProgramFromStrategy(name, strategy);
  classNames := List.map(cs, Absyn.getClassName);
  str := stringDelimitList(classNames,", ");
  if not listLength(cs)==1 then
    Error.addSourceMessage(Error.LIBRARY_ONE_PACKAGE_PER_FILE, {str}, SOURCEINFO(name,true,0,0,0,0,0.0));
    fail();
  end if;
  (cl as Absyn.CLASS(name=cname,body=body,info=info))::{} := cs;
  if not stringEqual(cname,pack) then
    if stringEqual(System.tolower(cname), System.tolower(pack)) then
      Error.addSourceMessage(Error.LIBRARY_UNEXPECTED_NAME_CASE_SENSITIVE, {pack,cname}, info);
    else
      Error.addSourceMessage(Error.LIBRARY_UNEXPECTED_NAME, {pack,cname}, info);
      fail();
    end if;
  end if;
  s1 := Absyn.withinString(w1);
  s2 := Absyn.withinString(w2);
  if not (Absyn.withinEqual(w1,w2) or Config.languageStandardAtMost(Config.LanguageStandard.'2.x')) then
    Error.addSourceMessage(Error.LIBRARY_UNEXPECTED_WITHIN, {s1,s2}, info);
    fail();
  elseif expectPackage and not Absyn.isParts(body) then
    Error.addSourceMessage(Error.LIBRARY_EXPECTED_PARTS, {pack}, info);
    fail();
  end if;
end parsePackageFile;

protected function getBothPackageAndFilename
  input String str;
  input String mp;
  output String out;
algorithm
  out := Util.testsuiteFriendly(System.realpath(mp + "/" + str + ".mo")) + ", " + Util.testsuiteFriendly(System.realpath(mp + "/" + str + "/package.mo"));
end getBothPackageAndFilename;

protected function getPackageContentNames
  "Gets the names of packages to load before the package.mo, and the ones to load after"
  input Absyn.Class cl;
  input String filename;
  input String mp;
  input Integer numError;
  input Boolean encrypted = false;
  output list<PackageOrder> po "reverse";
algorithm
  (po) := matchcontinue (cl,filename,mp,numError)
    local
      String contents, duplicatesStr, differencesStr, classFilename;
      list<String> duplicates, namesToFind, mofiles, subdirs, differences, intersection, caseInsensitiveFiles;
      list<Absyn.ClassPart> cp;
      SourceInfo info;
      list<PackageOrder> po1, po2;

    case (Absyn.CLASS(body=Absyn.PARTS(classParts=cp),info=info),_,_,_)
      equation
        if (System.regularFileExists(filename)) then
          contents = System.readFile(filename);
          namesToFind = System.strtok(contents, "\n");
          namesToFind = List.removeOnTrue("",stringEqual,List.map(namesToFind,System.trimWhitespace));
          duplicates = List.sortedDuplicates(List.sort(namesToFind,Util.strcmpBool),stringEq);
          duplicatesStr = stringDelimitList(duplicates, ", ");
          Error.assertionOrAddSourceMessage(listEmpty(duplicates),Error.PACKAGE_ORDER_DUPLICATES,{duplicatesStr},SOURCEINFO(filename,true,0,0,0,0,0.0));

          if encrypted then
            // get all the .moc files in the directory!
            mofiles = List.map(System.mocFiles(mp), Util.removeLast4Char);
          else
            // get all the .mo files in the directory!
            mofiles = List.map(System.moFiles(mp), Util.removeLast3Char);
          end if;
          // get all the subdirs
          subdirs = System.subDirectories(mp);
          subdirs = List.filter2OnTrue(subdirs, existPackage, mp, encrypted);
          // build a list
          intersection = List.intersectionOnTrue(subdirs,mofiles,stringEq);
          differencesStr = stringDelimitList(List.map1(intersection, getBothPackageAndFilename, mp), ", ");
          Error.assertionOrAddSourceMessage(listEmpty(intersection),Error.PACKAGE_DUPLICATE_CHILDREN,{differencesStr},SOURCEINFO(filename,true,0,0,0,0,0.0));
          mofiles = listAppend(subdirs,mofiles);
          // check if all are present in the package.order
          differences = List.setDifference(mofiles, namesToFind);
          (po1) = getPackageContentNamesinParts(namesToFind,cp,{});
          (po1,differences) = List.map3Fold(po1,checkPackageOrderFilesExist,mp,info,encrypted,differences);

          // issue a warning if not all are present
          differencesStr = stringDelimitList(differences, "\n\t");
          Error.assertionOrAddSourceMessage(listEmpty(differences),Error.PACKAGE_ORDER_FILE_NOT_COMPLETE,{differencesStr},SOURCEINFO(filename,true,0,0,0,0,0.0));

          po2 = List.map(differences, makeClassLoad);

          po = listAppend(po2, po1);
        else // file not found
          mofiles = List.map(System.moFiles(mp), Util.removeLast3Char) "Here .mo files in same directory as package.mo should be loaded as sub-packages";
          subdirs = System.subDirectories(mp);
          subdirs = List.filter2OnTrue(subdirs, existPackage, mp, encrypted);
          mofiles = List.sort(listAppend(subdirs,mofiles), Util.strcmpBool);
          // Look for duplicates
          intersection = List.sortedDuplicates(mofiles,stringEq);
          differencesStr = stringDelimitList(List.map1(intersection, getBothPackageAndFilename, mp), ", ");
          Error.assertionOrAddSourceMessage(listEmpty(intersection),Error.PACKAGE_DUPLICATE_CHILDREN,{differencesStr},info);

          po = listAppend(List.map(cp, makeClassPart),List.map(mofiles, makeClassLoad));
        end if;
      then
        po;

    case (Absyn.CLASS(info=info),_,_,_)
      equation
        true = numError == Error.getNumErrorMessages();
        Error.addSourceMessage(Error.INTERNAL_ERROR,{"getPackageContentNames failed for unknown reason"},info);
      then fail();

  end matchcontinue;
end getPackageContentNames;

protected function makeClassPart
  input Absyn.ClassPart part;
  output PackageOrder po;
algorithm
  po := CLASSPART(part);
end makeClassPart;

protected function makeElement
  input Absyn.ElementItem el;
  input Boolean pub;
  output PackageOrder po;
algorithm
  po := ELEMENT(el,pub);
end makeElement;

protected function makeClassLoad
  input String str;
  output PackageOrder po;
algorithm
  po := CLASSLOAD(str);
end makeClassLoad;

protected function checkPackageOrderFilesExist
  input output PackageOrder po;
  input String mp;
  input SourceInfo info;
  input Boolean encrypted = false;
  input output list<String> differences;
algorithm
  _ := match (po,mp,info)
    local
      String pd,str,str2,str3,str4;
      list<String> strs;
    case (CLASSLOAD(str),_,_)
      algorithm
        pd := Autoconf.pathDelimiter;
        str2 := str + (if encrypted then ".moc" else ".mo");
        if not (System.directoryExists(mp + pd + str) or System.regularFileExists(mp + pd + str2)) then
          try
            str3 := List.find(System.moFiles(mp), function Util.stringEqCaseInsensitive(str2=System.tolower(str2)));
          else
            Error.addSourceMessage(Error.PACKAGE_ORDER_FILE_NOT_FOUND,{str},info);
            fail();
          end try;
          Error.addSourceMessage(Error.PACKAGE_ORDER_CASE_SENSITIVE, {str, str2, str3}, info);
          str4 := Util.removeLastNChar(str3,if encrypted then 4 else 3);
          differences := List.removeOnTrue(str4, stringEq, differences);
          po := CLASSLOAD(str4);
        end if;
      then ();
    else ();
  end match;
end checkPackageOrderFilesExist;

protected function existPackage
  input String name;
  input String mp;
  input Boolean encrypted = false;
  output Boolean b;
protected
  String pd;
algorithm
  pd := Autoconf.pathDelimiter;
  b := System.regularFileExists(mp + pd + name + pd + (if encrypted then "package.moc" else "package.mo"));
end existPackage;

protected function getPackageContentNamesinParts
  input list<String> inNamesToSort;
  input list<Absyn.ClassPart> cps;
  input list<PackageOrder> acc;
  output list<PackageOrder> outOrder "reverse";
algorithm
  outOrder := match (inNamesToSort,cps,acc)
    local
      list<Absyn.ClassPart> rcp;
      list<Absyn.ElementItem> elts;
      list<String> namesToSort;
      Absyn.ClassPart cp;
    case (namesToSort,{},_)
      equation
        outOrder = listAppend(List.mapReverse(namesToSort,makeClassLoad),acc);
      then outOrder;
    case (namesToSort,Absyn.PUBLIC(elts)::rcp,_)
      equation
        (outOrder,namesToSort) = getPackageContentNamesinElts(namesToSort,elts,acc,true);
        (outOrder) = getPackageContentNamesinParts(namesToSort,rcp,outOrder);
      then outOrder;
    case (namesToSort,Absyn.PROTECTED(elts)::rcp,_)
      equation
        (outOrder,namesToSort) = getPackageContentNamesinElts(namesToSort,elts,acc,false);
        (outOrder) = getPackageContentNamesinParts(namesToSort,rcp,outOrder);
      then outOrder;
    case (namesToSort,cp::rcp,_)
      equation
        (outOrder) = getPackageContentNamesinParts(namesToSort,rcp,CLASSPART(cp)::acc);
      then outOrder;
  end match;
end getPackageContentNamesinParts;

protected function getPackageContentNamesinElts
  input list<String> inNamesToSort;
  input list<Absyn.ElementItem> inElts;
  input list<PackageOrder> po;
  input Boolean pub;
  output list<PackageOrder> outOrder;
  output list<String> outNames;
algorithm
  (outOrder,outNames) := match (inNamesToSort,inElts,po,pub)
    local
      String name1,name2;
      list<String> namesToSort,names,compNames;
      list<Absyn.ElementItem> elts;
      Boolean b;
      SourceInfo info;
      list<Absyn.ComponentItem> comps;
      Absyn.ElementItem ei;
      PackageOrder orderElt,load;
    case (namesToSort,{},_,_) then (po,namesToSort);

    case (name1::_,(ei as Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.COMPONENTS(components=comps),info=info)))::elts,_,_)
      equation
        compNames = List.map(comps,Absyn.componentName);
        (names,b) = matchCompNames(inNamesToSort,compNames,info);
        orderElt = if b then makeElement(ei,pub) else makeClassLoad(name1);
        (outOrder,names) = getPackageContentNamesinElts(names,if b then elts else inElts,orderElt :: po,pub);
      then (outOrder,names);

    case (name1::namesToSort,(ei as Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF(class_=Absyn.CLASS(name=name2,info=info)))))::elts,_,_)
      equation
        load = makeClassLoad(name1);
        b = name1 == name2;
        Error.assertionOrAddSourceMessage(if b then not listMember(load,po) else true, Error.PACKAGE_MO_NOT_IN_ORDER, {name2}, info);
        orderElt = if b then makeElement(ei,pub) else load;
        (outOrder,names) = getPackageContentNamesinElts(namesToSort,if b then elts else inElts,orderElt :: po, pub);
      then (outOrder,names);

    case ({},(Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF(class_=Absyn.CLASS(name=name2,info=info)))))::_,_,_)
      equation
        load = makeClassLoad(name2);
        Error.assertionOrAddSourceMessage(not listMember(load,po), Error.PACKAGE_MO_NOT_IN_ORDER, {name2}, info);
        Error.addSourceMessage(Error.FOUND_ELEMENT_NOT_IN_ORDER_FILE, {name2}, info);
      then fail();

    case ({},Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.COMPONENTS(components=Absyn.COMPONENTITEM(component=Absyn.COMPONENT(name=name2))::_),info=info))::_,_,_)
      equation
        load = makeClassLoad(name2);
        Error.assertionOrAddSourceMessage(not listMember(load,po), Error.PACKAGE_MO_NOT_IN_ORDER, {name2}, info);
        Error.addSourceMessage(Error.FOUND_ELEMENT_NOT_IN_ORDER_FILE, {name2}, info);
      then fail();

    case (namesToSort,ei::elts,_,_)
      equation
        (outOrder,names) = getPackageContentNamesinElts(namesToSort,elts,ELEMENT(ei,pub) :: po, pub);
      then (outOrder,names);
  end match;
end getPackageContentNamesinElts;

protected function matchCompNames
  input list<String> names;
  input list<String> comps;
  input SourceInfo info;
  output list<String> outNames;
  output Boolean matchedNames;
algorithm
  (outNames,matchedNames) := match (names,comps,info)
    local
      Boolean b, b1;
      String n1,n2;
      list<String> rest1,rest2;

    case (_,{},_) then (names,true);

    case (n1::rest1,n2::rest2,_)
      equation
        if (n1 == n2)
        then
          (rest1,b) = matchCompNames(rest1,rest2,info);
          Error.assertionOrAddSourceMessage(b, Error.ORDER_FILE_COMPONENTS, {}, info);
          b1 = true;
        else
          b1 = false;
        end if;
      then (rest1,b1);

  end match;
end matchCompNames;

protected function packageOrderName
  input PackageOrder ord;
  output String name;
algorithm
  name := match ord
    case CLASSLOAD(name) then name;
    else "#";
  end match;
end packageOrderName;

public function checkOnLoadMessage
  "Checks annotation __OpenModelica_messageOnLoad for a message to display"
  input Absyn.Program p1;
protected
  list<Absyn.Class> classes;
algorithm
  Absyn.PROGRAM(classes=classes) := p1;
  _ := List.map2(classes,Absyn.getNamedAnnotationInClass,Absyn.IDENT("__OpenModelica_messageOnLoad"),checkOnLoadMessageWork);
end checkOnLoadMessage;

protected function checkOnLoadMessageWork
  "Checks annotation __OpenModelica_messageOnLoad for a message to display"
  input Option<Absyn.Modification> mod;
  output Integer dummy;
algorithm
  dummy := match mod
    local
      String str;
      SourceInfo info;
    case SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(info=info,exp=Absyn.STRING(str))))
      equation
        Error.addSourceMessage(Error.COMPILER_NOTIFICATION_SCRIPTING,{str},info);
      then 1;
  end match;
end checkOnLoadMessageWork;

function getProgramFromStrategy
  input String filename;
  input LoadFileStrategy strategy;
  output Absyn.Program program;
algorithm
  program := match strategy
    case STRATEGY_HASHTABLE()
      equation
        /* if not BaseHashTable.hasKey(filename, strategy.ht) then
          Error.addInternalError("HashTable missing file " + filename + " - all entries include:\n" + stringDelimitList(BaseHashTable.hashTableKeyList(ht), "\n"), sourceInfo());
          fail();
        end if; */
      then BaseHashTable.get(filename, strategy.ht);
    case STRATEGY_ON_DEMAND() then Parser.parse(filename, strategy.encoding);
  end match;
end getProgramFromStrategy;

annotation(__OpenModelica_Interface="frontend");
end ClassLoader;

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package ClassLoader
" file:        ClassLoader.mo
  package:     ClassLoader
  description: Loading of classes from $OPENMODELICALIBRARY.

  RCS: $Id$

  This module loads classes from $OPENMODELICALIBRARY. It exports several functions:
  loadClass function
  loadModel function
  loadFile function"

public import Absyn;
public import Interactive;

protected import Config;
protected import Debug;
protected import Error;
protected import Flags;
protected import List;
protected import Parser;
protected import Print;
protected import System;
protected import Util;

public function loadClass
"function: loadClass
  This function takes a \'Path\' and the $OPENMODELICALIBRARY as a string
  and tries to load the class from the path.
  If the classname is qualified, the complete package is loaded.
  E.g. load_class(Modelica.SIunits.Voltage) -> whole Modelica package loaded."
  input Absyn.Path inPath;
  input list<String> priorityList;
  input String modelicaPath;
  input Option<String> encoding;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inPath,priorityList,modelicaPath,encoding)
    local
      String gd,classname,mp,pack;
      list<String> mps;
      Absyn.Program p;
      Absyn.Path rest,path;
      Absyn.TimeStamp ts;
    /* Simple names: Just load the file if it can be found in $OPENMODELICALIBRARY */
    case (Absyn.IDENT(name = classname),priorityList,mp,encoding)
      equation
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        p = loadClassFromMps(classname, priorityList, mps, encoding);
      then
        p;
    /* Qualified names: First check if it is defined in a file pack.mo */
    case (Absyn.QUALIFIED(name = pack,path = rest),priorityList,mp,encoding)
      equation
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        p = loadClassFromMps(pack, priorityList, mps, encoding);
      then
        p;
    /* failure */
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "ClassLoader.loadClass failed\n");
      then
        fail();
  end matchcontinue;
end loadClass;

protected function existRegularFile
"function: existRegularFile
  Checks if a file exists"
  input String filename;
algorithm
  true := System.regularFileExists(filename);
end existRegularFile;

public function existDirectoryFile
"function: existDirectoryFile
  Checks if a directory exist"
  input String filename;
algorithm
  true := System.directoryExists(filename);
end existDirectoryFile;

protected function loadClassFromMps
"Loads a class or classes from a set of paths in OPENMODELICALIBRARY"
  input String id;
  input list<String> prios;
  input list<String> mps;
  input Option<String> encoding;
  output Absyn.Program outProgram;
protected
  String mp,name;
  Boolean isDir;
  Absyn.Class cl;
  Absyn.TimeStamp ts;
algorithm
  (mp,name,isDir) := System.getLoadModelPath(id,prios,mps);
  // print("System.getLoadModelPath: " +& id +& " {" +& stringDelimitList(prios,",") +& "} " +& stringDelimitList(mps,",") +& " => " +& mp +& " " +& name +& " " +& boolString(isDir));
  Config.setLanguageStandardFromMSL(name);
  cl := loadClassFromMp(id, mp, name, isDir, encoding);
  ts := Absyn.getNewTimeStamp();
  outProgram := Absyn.PROGRAM({cl},Absyn.TOP(),ts);
end loadClassFromMps;

protected function loadClassFromMp
  input String id "the actual class name";
  input String path;
  input String name;
  input Boolean isDir;
  input Option<String> optEncoding;
  output Absyn.Class outClass;
algorithm
  outClass := match (id,path,name,isDir,optEncoding)
    local
      String mp,pd,classfile,classfile_1,class_,mp_1,dirfile,packfile,encoding,encodingfile;
      Absyn.Program p;
      Absyn.TimeStamp ts;
      Absyn.Class cl;

    case (id,path,name,false,optEncoding)
      equation
        pd = System.pathDelimiter();
        /* Check for path/package.encoding; OpenModelica extension */
        encodingfile = stringAppendList({path,pd,"package.encoding"});
        encoding = System.trimChar(System.trimChar(Debug.bcallret1(System.regularFileExists(encodingfile),System.readFile,encodingfile,Util.getOptionOrDefault(optEncoding,"UTF-8")),"\n")," ");
        cl = parsePackageFile(path +& pd +& name,encoding,false,Absyn.TOP(),id);
      then
        cl;

    case (id,path,name,true,optEncoding)
      equation
        /* Check for path/package.encoding; OpenModelica extension */
        pd = System.pathDelimiter();
        encodingfile = stringAppendList({path,pd,name,pd,"package.encoding"});
        encoding = System.trimChar(System.trimChar(Debug.bcallret1(System.regularFileExists(encodingfile),System.readFile,encodingfile,Util.getOptionOrDefault(optEncoding,"UTF-8")),"\n")," ");
        cl = loadCompletePackageFromMp(id, name, path, encoding, Absyn.TOP(), Error.getNumErrorMessages());
      then
        cl;
  end match;
end loadClassFromMp;

protected function loadCompletePackageFromMp
"function: loadCompletePackageFromMp
  Loads a whole package from the ModelicaPaths defined in OPENMODELICALIBRARY"
  input String id "actual class identifier";
  input Absyn.Ident inIdent;
  input String inString;
  input String encoding;
  input Absyn.Within inWithin;
  input Integer numError;
  output Absyn.Class cl;
algorithm
  cl := matchcontinue (id,inIdent,inString,encoding,inWithin,numError)
    local
      String pd,mp_1,packagefile,orderfile,subdirstr,pack,mp,name,str;
      Absyn.Class cl;
      list<Absyn.ElementItem> cbefore,cafter;
      Absyn.Within w1,within_;
      Absyn.Program p1_1,p2,p;
      list<String> subdirs,tv,before,after;
      Absyn.Path wpath_1,wpath;
      Absyn.TimeStamp ts;
      Boolean pp,fp,ep;
      Absyn.Restriction r;
      list<Absyn.NamedArg> ca;
      list<Absyn.ClassPart> cp;
      Option<String> cmt;
      Absyn.Info info;
      Absyn.Path path;
      Absyn.Within w2;
    case (id,pack,mp,encoding,within_,numError)
      equation
        pd = System.pathDelimiter();
        mp_1 = stringAppendList({mp,pd,pack});
        packagefile = stringAppendList({mp_1,pd,"package.mo"});
        orderfile = stringAppendList({mp_1,pd,"package.order"});
        existRegularFile(packagefile);
        (cl as Absyn.CLASS(name,pp,fp,ep,r,Absyn.PARTS(tv,ca,cp,cmt),info)) = parsePackageFile(packagefile,encoding,true,within_,id);
        (before,after) = getPackageContentNames(cl, orderfile, mp_1);
        path = Absyn.joinWithinPath(within_,Absyn.IDENT(id));
        w2 = Absyn.WITHIN(path);
        cbefore = List.map(List.map3(before,loadCompletePackageFromMp2,mp_1,encoding,w2),Absyn.makeClassElement);
        cafter = List.map(List.map3(after,loadCompletePackageFromMp2,mp_1,encoding,w2),Absyn.makeClassElement);
        cp = mergeBefore(cbefore,cp);
        cp = mergeAfter(cafter,cp);
      then Absyn.CLASS(name,pp,fp,ep,r,Absyn.PARTS(tv,ca,cp,cmt),info);
    case (id,pack,mp,encoding,within_,numError)
      equation
        true = numError == Error.getNumErrorMessages();
        str = "loadCompletePackageFromMp failed for unknown reason: mp=" +& mp +& " pack=" +& pack;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end loadCompletePackageFromMp;

protected function mergeBefore
  input list<Absyn.ElementItem> cs;
  input list<Absyn.ClassPart> cp;
  output list<Absyn.ClassPart> ocp;
algorithm
  ocp := match (cs,cp)
    local
      list<Absyn.ElementItem> ei;
      list<Absyn.ClassPart> rest;
    case (cs,Absyn.PUBLIC(ei)::rest)
      equation
        ei = listAppend(cs,ei);
      then Absyn.PUBLIC(ei)::rest;
    case (cs,cp) then Absyn.PUBLIC(cs)::cp;
  end match;
end mergeBefore;

protected function mergeAfter
  input list<Absyn.ElementItem> cs;
  input list<Absyn.ClassPart> cp;
  output list<Absyn.ClassPart> ocp;
algorithm
  ocp := listReverse(mergeAfter2(cs,listReverse(cp)));
end mergeAfter;

protected function mergeAfter2
  input list<Absyn.ElementItem> cs;
  input list<Absyn.ClassPart> cp;
  output list<Absyn.ClassPart> ocp;
algorithm
  ocp := match (cs,cp)
    local
      list<Absyn.ElementItem> ei;
      list<Absyn.ClassPart> rest;
    case (cs,Absyn.PUBLIC(ei)::rest)
      equation
        ei = listAppend(cs,ei);
      then Absyn.PUBLIC(ei)::rest;
    case (cs,cp) then Absyn.PUBLIC(cs)::cp;
  end match;
end mergeAfter2;

protected function loadCompletePackageFromMp2
"function: loadCompletePackageFromMp
  Loads a whole package from the ModelicaPaths defined in OPENMODELICALIBRARY"
  input String id "mo-file or directory";
  input String mp;
  input String encoding;
  input Absyn.Within w1 "With the parent added";
  output Absyn.Class cl;
algorithm
  cl := matchcontinue (id,mp,encoding,w1)
    local
      String pd,file;
      Absyn.Path path;
    case (id,mp,encoding,w1)
      equation
        pd = System.pathDelimiter();
        true = System.directoryExists(mp +& pd +& id);
        cl = loadCompletePackageFromMp(id,id,mp,encoding,w1,Error.getNumErrorMessages());
      then cl;

    case (id,mp,encoding,w1)
      equation
        pd = System.pathDelimiter();
        false = System.directoryExists(mp +& pd +& id);
        file = mp +& pd +& id +& ".mo";
        true = System.regularFileExists(file);
        cl = parsePackageFile(file,encoding,false,w1,id);
      then cl;
    
  end matchcontinue;
end loadCompletePackageFromMp2;

public function loadFile
"function loadFile
  author: x02lucpo
  load the file or the directory structure if the file is named package.mo"
  input String name;
  input String encoding;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (name,encoding)
    local
      String dir,pd,dir_1,name,filename,cname,prio,mp;
      Absyn.Program p1_1,p1;
      list<String> rest;

    case (name,encoding)
      equation
        true = System.regularFileExists(name);
        (dir,"package.mo") = Util.getAbsoluteDirectoryAndFile(name);
        cname::rest = System.strtok(List.last(System.strtok(dir,"/"))," ");
        prio = stringDelimitList(rest, " ");
        prio = Util.if_(stringEq(prio,""), "default", prio);
        mp = dir +& "/../";
        p1 = loadClass(Absyn.IDENT(cname),{prio},mp,SOME(encoding));
      then p1;

    case (name,encoding)
      equation
        true = System.regularFileExists(name);
        (dir,filename) = Util.getAbsoluteDirectoryAndFile(name);
        false = stringEq(filename,"package.mo");
        p1 = Parser.parse(name,encoding);
      then p1;

    // faliling
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "ClassLoader.loadFile failed: "+&name+&"\n");
      then
        fail();
  end matchcontinue;
end loadFile;

public function parsePackageFile
  "Parses a file containing a single class that matches the within"
  input String name;
  input String encoding;
  input Boolean expectPackage;
  input Absyn.Within w1 "Expected within of the package";
  input String pack "Expected name of the package";
  output Absyn.Class outClass;
algorithm
  outClass := matchcontinue (name,encoding,expectPackage,w1,pack)
    local
      Absyn.Program p;
      Absyn.Class cl;
      list<Absyn.Class> cs;
      Absyn.Within w2;
      Absyn.TimeStamp ts;
      Boolean b;
      list<String> classNames;
      Absyn.Info info;
      String str,s1,s2,cname;
      Absyn.ClassDef body;

    case (name,encoding,expectPackage,w1,pack)
      equation
        true = System.regularFileExists(name);
        Absyn.PROGRAM(cs,w2,ts) = Parser.parse(name,encoding);
        classNames = List.map(cs, Absyn.getClassName);
        str = stringDelimitList(classNames,", ");
        Error.assertionOrAddSourceMessage(listLength(cs)==1, Error.LIBRARY_ONE_PACKAGE_PER_FILE, {str}, Absyn.INFO(name,true,0,0,0,0,ts));
        cl::{} = cs;
        Absyn.CLASS(name=cname,body=body,info=info) = cl;
        Error.assertionOrAddSourceMessage(stringEqual(cname,pack), Error.LIBRARY_UNEXPECTED_NAME, {pack,cname}, info);
        s1 = Absyn.withinString(w1);
        s2 = Absyn.withinString(w2);
        Error.assertionOrAddSourceMessage(Absyn.withinEqual(w1,w2) or Config.languageStandardAtMost(Config.MODELICA_1_X()), Error.LIBRARY_UNEXPECTED_WITHIN, {s1,s2}, info);
        Error.assertionOrAddSourceMessage((not expectPackage) or Absyn.isParts(body), Error.LIBRARY_EXPECTED_PARTS, {pack}, info);
      then cl;

    // faliling
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "ClassLoader.parsePackageFile failed: "+&name+&"\n");
      then
        fail();
  end matchcontinue;
end parsePackageFile;

protected function getPackageContentNames
  "Gets the names of packages to load before the package.mo, and the ones to load after"
  input Absyn.Class cl;
  input String filename;
  input String mp;
  output list<String> namesBefore;
  output list<String> namesAfter;
protected
  String contents;
  String namesToSort;
algorithm
  (namesBefore,namesAfter) := matchcontinue (cl,filename,mp)
    local
      String contents,name;
      list<String> namesToFind, tv, before, after, mofiles, subdirs;
      Boolean pp,fp,ep;
      list<Absyn.NamedArg> ca;
      list<Absyn.ClassPart> cp;
      Option<String> cmt;
      Absyn.Info info;
      list<tuple<Boolean,Absyn.Element>> elts;
      Boolean b;
    case (Absyn.CLASS(restriction=Absyn.R_PACKAGE(),body=Absyn.PARTS(tv,ca,cp,cmt),info=info),filename,mp)
      equation
        true = System.regularFileExists(filename);
        contents = System.readFile(filename);
        namesToFind = System.strtok(contents, "\n");
        namesToFind = List.removeOnTrue("",stringEqual,List.map(namesToFind,System.trimWhitespace));
        (before,after) = getPackageContentNamesinParts(namesToFind,cp,{},false);
        List.map2_0(before,checkPackageOrderFilesExist,mp,info);
        List.map2_0(after,checkPackageOrderFilesExist,mp,info);
      then (before,after);

    case (cl,filename,mp)
      equation
        false = System.regularFileExists(filename);
        mofiles = List.map(System.moFiles(mp), Util.removeLast3Char) "Here .mo files in same directory as package.mo should be loaded as sub-packages";
        subdirs = System.subDirectories(mp);
        subdirs = List.filter1OnTrue(subdirs, existPackage, mp);
        mofiles = List.sort(listAppend(subdirs,mofiles), Util.strcmpBool);
      then ({},mofiles);
  end matchcontinue;
end getPackageContentNames;

protected function checkPackageOrderFilesExist
  input String str;
  input String mp;
  input Absyn.Info info;
protected
  String pd;
algorithm
  pd := System.pathDelimiter();
  Error.assertionOrAddSourceMessage(System.directoryExists(mp +& pd +& str) or System.regularFileExists(mp +& pd +& str +& ".mo"),Error.PACKAGE_ORDER_FILE_NOT_FOUND,{str},info);  
end checkPackageOrderFilesExist;

protected function existPackage
  input String name;
  input String mp;
  output Boolean b;
protected
  String pd;
algorithm
  pd := System.pathDelimiter();
  b := System.regularFileExists(mp +& pd +& name +& pd +& "package.mo"); 
end existPackage;

protected function getPackageContentNamesinParts
  input list<String> inNamesToSort;
  input list<Absyn.ClassPart> cp;
  input list<String> inBefore;
  input Boolean inFoundFirst;
  output list<String> outBefore;
  output list<String> outAfter;
algorithm
  (outBefore,outAfter) := match (inNamesToSort,cp,inBefore,inFoundFirst)
    local
      list<Absyn.ClassPart> rcp;
      list<Absyn.ElementItem> elts;
      list<String> namesToSort, before, after;
      String str;
      Boolean foundFirst;
    case (namesToSort,{},before,_) then (listReverse(before),namesToSort);
    case (namesToSort,Absyn.PUBLIC(elts)::rcp,before,foundFirst)
      equation
        (before,foundFirst,namesToSort) = getPackageContentNamesinElts(namesToSort,elts,before,foundFirst);
        (before,after) = getPackageContentNamesinParts(namesToSort,rcp,before,foundFirst);
      then (before,after);
    case (namesToSort,Absyn.PROTECTED(elts)::rcp,before,foundFirst)
      equation
        (before,foundFirst,namesToSort) = getPackageContentNamesinElts(namesToSort,elts,before,foundFirst);
        (before,after) = getPackageContentNamesinParts(namesToSort,rcp,before,foundFirst);
      then (before,after);
    case (namesToSort,_::rcp,before,foundFirst)
      equation
        (before,after) = getPackageContentNamesinParts(namesToSort,rcp,before,foundFirst);
      then (before,after);
  end match;
end getPackageContentNamesinParts;

protected function getPackageContentNamesinElts
  input list<String> inNamesToSort;
  input list<Absyn.ElementItem> inElts;
  input list<String> inBefore;
  input Boolean inFoundFirst;
  output list<String> outBefore;
  output Boolean outFoundFirst;
  output list<String> outNames;
algorithm
  (outBefore,outFoundFirst,outNames) := match (inNamesToSort,inElts,inBefore,inFoundFirst)
    local
      String name1,name2,str;
      list<String> namesToSort,before,names;
      list<Absyn.ElementItem> elts;
      Boolean foundFirst,b;
      Absyn.Info info;
      list<Absyn.ComponentItem> comps;
    case (namesToSort,{},before,foundFirst) then (before,foundFirst,namesToSort);

    case (namesToSort,Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.COMPONENTS(components=comps),info=info))::elts,before,foundFirst)
      equation
        (before,foundFirst,names) = getPackageContentNamesinComps(namesToSort,comps,before,foundFirst,info);
        (before,foundFirst,names) = getPackageContentNamesinElts(names,elts,before,foundFirst);
      then (before,foundFirst,names);

    case (name1::namesToSort,Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF(class_=Absyn.CLASS(name=name2,info=info))))::elts,before,false)
      equation
        b = name1 ==& name2;
        (before,foundFirst,names) = getPackageContentNamesinElts(namesToSort,Util.if_(b,elts,inElts),List.consOnTrue(not b,name1,before),b);
      then (before,foundFirst,names);
    case (name1::namesToSort,Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF(class_=Absyn.CLASS(name=name2,info=info))))::elts,before,true)
      equation
        b = name1 ==& name2;
        str = Debug.bcallret2(not b, stringDelimitList, inNamesToSort, ", ", "");
        Error.assertionOrAddSourceMessage(name1 ==& name2, Error.PACKAGE_MO_NOT_IN_ORDER, {name2, str}, info);
        (before,foundFirst,names) = getPackageContentNamesinElts(namesToSort,elts,before,true);
      then (before,foundFirst,names);
    case ({},Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF(class_=Absyn.CLASS(name=name2,info=info))))::elts,before,true)
      equation
        Error.addSourceMessage(Error.FOUND_ELEMENT_NOT_IN_ORDER_FILE, {name2}, info);
      then fail();
    case (namesToSort,_::elts,before,foundFirst)
      equation
        (before,foundFirst,names) = getPackageContentNamesinElts(namesToSort,elts,before,foundFirst);
      then (before,foundFirst,names);
  end match;
end getPackageContentNamesinElts;

protected function getPackageContentNamesinComps
  input list<String> inNamesToSort;
  input list<Absyn.ComponentItem> inComps;
  input list<String> inBefore;
  input Boolean inFoundFirst;
  input Absyn.Info info;
  output list<String> outBefore;
  output Boolean outFoundFirst;
  output list<String> outNames;
algorithm
  (outBefore,outFoundFirst,outNames) := match (inNamesToSort,inComps,inBefore,inFoundFirst,info)
    local
      String name1,name2,str;
      list<String> namesToSort,before,names;
      list<Absyn.ComponentItem> comps;
      Boolean foundFirst,b;
    case (namesToSort,{},before,foundFirst,info) then (before,foundFirst,namesToSort);
    case (name1::namesToSort,Absyn.COMPONENTITEM(component=Absyn.COMPONENT(name=name2))::comps,before,false,info)
      equation
        b = name1 ==& name2;
        (before,foundFirst,names) = getPackageContentNamesinComps(namesToSort,comps,List.consOnTrue(not b,name1,before),b,info);
      then (before,foundFirst,names);
    case (name1::namesToSort,Absyn.COMPONENTITEM(component=Absyn.COMPONENT(name=name2))::comps,before,true,info)
      equation
        b = name1 ==& name2;
        str = Debug.bcallret2(not b, stringDelimitList, inNamesToSort, ", ", "");
        Error.assertionOrAddSourceMessage(name1 ==& name2, Error.PACKAGE_MO_NOT_IN_ORDER, {name2, str}, info);
        (before,foundFirst,names) = getPackageContentNamesinComps(namesToSort,Util.if_(b,comps,inComps),before,true,info);
      then (before,foundFirst,names);
    case ({},Absyn.COMPONENTITEM(component=Absyn.COMPONENT(name=name2))::comps,before,true,info)
      equation
        Error.addSourceMessage(Error.FOUND_ELEMENT_NOT_IN_ORDER_FILE, {name2}, info);
      then fail();
    case (namesToSort,_::comps,before,foundFirst,info)
      equation
        (before,foundFirst,names) = getPackageContentNamesinComps(namesToSort,comps,before,foundFirst,info);
      then (before,foundFirst,names);
  end match;
end getPackageContentNamesinComps;

end ClassLoader;


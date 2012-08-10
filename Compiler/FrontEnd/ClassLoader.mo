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
algorithm
  (mp,name,isDir) := System.getLoadModelPath(id,prios,mps);
  // print("System.getLoadModelPath: " +& id +& " {" +& stringDelimitList(prios,",") +& "} " +& stringDelimitList(mps,",") +& " => " +& mp +& " " +& name +& " " +& boolString(isDir));
  Config.setLanguageStandardFromMSL(name);
  outProgram := loadClassFromMp(id, mp, name, isDir, encoding);
end loadClassFromMps;

protected function loadClassFromMp
  input String id "the actual class name";
  input String path;
  input String name;
  input Boolean isDir;
  input Option<String> optEncoding;
  output Absyn.Program outProgram;
algorithm
  outProgram := match (id,path,name,isDir,optEncoding)
    local
      String mp,pd,classfile,classfile_1,class_,mp_1,dirfile,packfile,encoding,encodingfile;
      Absyn.Program p;
      Absyn.TimeStamp ts;

    case (_,path,name,false,optEncoding)
      equation
        pd = System.pathDelimiter();
        encodingfile = stringAppendList({path,pd,"package.encoding"});
        encoding = System.trimChar(System.trimChar(Debug.bcallret1(System.regularFileExists(encodingfile),System.readFile,encodingfile,Util.getOptionOrDefault(optEncoding,"UTF-8")),"\n")," ");
        p = Parser.parse(path +& pd +& name,encoding);
      then
        p;

    case (id,path,name,true,optEncoding)
      equation
        ts = Absyn.getNewTimeStamp();
        /* Check for path/package.encoding; OpenModelica extension */
        pd = System.pathDelimiter();
        encodingfile = stringAppendList({path,pd,name,pd,"package.encoding"});
        encoding = System.trimChar(System.trimChar(Debug.bcallret1(System.regularFileExists(encodingfile),System.readFile,encodingfile,Util.getOptionOrDefault(optEncoding,"UTF-8")),"\n")," ");
        p = loadCompletePackageFromMp(id, name, path, encoding, Absyn.TOP(), Absyn.PROGRAM({},Absyn.TOP(), ts));
      then
        p;
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
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (id,inIdent,inString,encoding,inWithin,inProgram)
    local
      String pd,mp_1,packagefile,orderfile,subdirstr,pack,mp;
      list<Absyn.Class> p1,oldc;
      Absyn.Within w1,within_;
      Absyn.Program p1_1,p2,p;
      list<String> subdirs;
      Absyn.Path wpath_1,wpath;
      Absyn.TimeStamp ts;
    case (id,pack,mp,encoding,within_,Absyn.PROGRAM(classes = oldc))
      equation
        pd = System.pathDelimiter();
        mp_1 = stringAppendList({mp,pd,pack});
        packagefile = stringAppendList({mp_1,pd,"package.mo"});
        orderfile = stringAppendList({mp_1,pd,"package.order"});
        existRegularFile(packagefile);
        Absyn.PROGRAM(p1,w1,ts) = parsePackageFile(packagefile,encoding,within_,id);
        Print.printBuf("loading ");
        Print.printBuf(packagefile);
        Print.printBuf("\n");
        p1_1 = Interactive.updateProgram(Absyn.PROGRAM(p1,w1,ts), Absyn.PROGRAM(oldc,Absyn.TOP(),ts));
        subdirs = System.subDirectories(mp_1);
        subdirs = List.sort(subdirs, Util.strcmpBool);
        subdirstr = stringDelimitList(subdirs, ", ");
        p2 = loadCompleteSubdirs(subdirs, id, mp_1, encoding, within_, p1_1);
        p = loadCompleteSubfiles(id, mp_1, encoding, within_, p2);
      then
        p;

    case (id,pack,mp,encoding,within_,p) // No package.mo file is different from a parse error
      equation
        pd = System.pathDelimiter();
        mp_1 = stringAppendList({mp,pd,pack});
        packagefile = stringAppendList({mp_1,pd,"package.mo"});
        failure(existRegularFile(packagefile));
      then p;

  end matchcontinue;
end loadCompletePackageFromMp;

protected function loadCompleteSubdirs
"function: loadCompleteSubdirs
  Loads all classes present in a subdirectory"
  input list<String> inStringLst;
  input Absyn.Ident inIdent;
  input String inString;
  input String encoding;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inStringLst,inIdent,inString,encoding,inWithin,inProgram)
    local
      Absyn.Within w,w2,within_;
      list<Absyn.Class> oldcls;
      Absyn.Path pack_1,pack2;
      Absyn.Program p,p_1,oldp;
      String pack,pack1,mp;
      list<String> packs;
      Absyn.TimeStamp ts;

    case ({},_,_,encoding,w,Absyn.PROGRAM(classes = oldcls,within_ = w2, globalBuildTimes=ts))
      then (Absyn.PROGRAM(oldcls,w2,ts));
    case ((pack :: packs),pack1,mp,encoding,(within_ as Absyn.WITHIN(path = pack2)),oldp)
      equation
        pack_1 = Absyn.joinPaths(pack2, Absyn.IDENT(pack1));
        p = loadCompletePackageFromMp(pack, pack, mp, encoding, Absyn.WITHIN(pack_1), oldp);
        p_1 = loadCompleteSubdirs(packs, pack1, mp, encoding, within_, p);
      then
        p_1;

    case ((pack :: packs),pack1,mp,encoding,(within_ as Absyn.TOP()),oldp)
      equation
        pack_1 = Absyn.joinPaths(Absyn.IDENT(pack1), Absyn.IDENT(pack));
        p = loadCompletePackageFromMp(pack, pack, mp, encoding, Absyn.WITHIN(Absyn.IDENT(pack1)), oldp);
        p_1 = loadCompleteSubdirs(packs, pack1, mp, encoding, within_, p);
      then
        p_1;

    /* Do not silently accept broken libraries...
    case ((pack :: packs),pack1,mp,within_,p)
      equation
        p_1 = loadCompleteSubdirs(packs, pack1, mp, within_, p);
      then
        p_1;
    */

    case (pack::_,_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"ClassLoader.loadCompleteSubdirs failed: " +& pack);
      then
        fail();
  end matchcontinue;
end loadCompleteSubdirs;

protected function loadCompleteSubfiles
"function: loadCompleteSubfiles
  This function loads all modelicafiles (.mo) from a subdir package."
  input Absyn.Ident inIdent;
  input String inString;
  input String encoding;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inIdent,inString,encoding,inWithin,inProgram)
    local
      list<String> mofiles;
      Absyn.Path within_1,within_;
      Absyn.Program p,oldp;
      String pack,mp;

    case (pack,mp,encoding,Absyn.WITHIN(path = within_),oldp)
      equation
        mofiles = System.moFiles(mp) "Here .mo files in same directory as package.mo should be loaded as sub-packages" ;
        mofiles = List.sort(mofiles, Util.strcmpBool);
        within_1 = Absyn.joinPaths(within_, Absyn.IDENT(pack));
        p = loadSubpackageFiles(mofiles, mp, encoding, Absyn.WITHIN(within_1), oldp);
      then
        p;

    case (pack,mp,encoding,Absyn.TOP(),oldp)
      equation
        mofiles = System.moFiles(mp) "Here .mo files in same directory as package.mo should be loaded as sub-packages" ;
        mofiles = List.sort(mofiles, Util.strcmpBool);
        p = loadSubpackageFiles(mofiles, mp, encoding, Absyn.WITHIN(Absyn.IDENT(pack)), oldp);
      then
        p;

    else
      equation
        Debug.fprintln(Flags.FAILTRACE,"ClassLoader.loadCompleteSubfiles failed");
      then
        fail();
  end matchcontinue;
end loadCompleteSubfiles;

protected function loadSubpackageFiles
"function: loadSubpackageFiles
  Loads all classes from a subpackage"
  input list<String> inStringLst;
  input String inString;
  input String encoding;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inStringLst,inString,encoding,inWithin,inProgram)
    local
      String mp,pd,f_1,f,id;
      Absyn.Within within_,w;
      list<Absyn.Class> cls,oldc;
      Absyn.Program p_1,p_2;
      list<String> fs;
      Absyn.TimeStamp ts;

    case ({},mp,encoding,within_,Absyn.PROGRAM(classes = cls,within_ = w, globalBuildTimes=ts))
      then Absyn.PROGRAM(cls,w,ts);

    case ((f :: fs),mp,encoding,within_,Absyn.PROGRAM(classes = oldc,globalBuildTimes = ts))
      equation
        pd = System.pathDelimiter();
        f_1 = stringAppendList({mp,pd,f});
        id = System.substring(f,1,stringLength(f)-3 /* .mo */);
        Absyn.PROGRAM(classes=cls) = parsePackageFile(f_1,encoding,within_,id);
        p_1 = Interactive.updateProgram(Absyn.PROGRAM(cls,within_,ts), Absyn.PROGRAM(oldc,Absyn.TOP(),ts));
        p_2 = loadSubpackageFiles(fs, mp, encoding, within_, p_1);
      then
        p_2;

    else
      equation
        Debug.fprintln(Flags.FAILTRACE,"ClassLoader.loadSubpackageFiles failed");
      then fail();
  end matchcontinue;
end loadSubpackageFiles;

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
      String dir,pd,dir_1,name,filename;
      Absyn.Program p1_1,p1;

    case (name,encoding)
      equation
        true = System.regularFileExists(name);
        (dir,"package.mo") = Util.getAbsoluteDirectoryAndFile(name);
        p1_1 = Parser.parse(name,encoding);
        pd = System.pathDelimiter();
        dir_1 = stringAppendList({dir,pd,".."});
        p1 = loadModelFromEachClass(p1_1, dir_1, SOME(encoding));
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
  input Absyn.Within w1 "Expected within of the package";
  input String pack "Expected name of the package";
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (name,encoding,w1,pack)
    local
      Absyn.Program p;
      list<Absyn.Class> cs;
      Absyn.Within w2;
      Absyn.TimeStamp ts;
      Boolean b;
      list<String> classNames;
      Absyn.Info info;
      String str,s1,s2,cname;

    case (name,encoding,w1,pack)
      equation
        true = System.regularFileExists(name);
        Absyn.PROGRAM(cs,w2,ts) = Parser.parse(name,encoding);
        classNames = List.map(cs, Absyn.getClassName);
        str = stringDelimitList(classNames,", ");
        Error.assertionOrAddSourceMessage(listLength(cs)==1, Error.LIBRARY_ONE_PACKAGE_PER_FILE, {str}, Absyn.INFO(name,true,0,0,0,0,ts));
        Absyn.CLASS(name=cname,info=info)::{} = cs;
        Error.assertionOrAddSourceMessage(stringEqual(cname,pack), Error.LIBRARY_UNEXPECTED_NAME, {pack,cname}, info);
        s1 = Absyn.withinString(w1);
        s2 = Absyn.withinString(w2);
        Error.assertionOrAddSourceMessage(Absyn.withinEqual(w1,w2) or Config.languageStandardAtMost(Config.MODELICA_1_X), Error.LIBRARY_UNEXPECTED_WITHIN, {s1,s2}, info);
      then Absyn.PROGRAM(cs,w1 /* Modelica 1.x did not keep within */,ts);

    // faliling
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "ClassLoader.parsePackageFile failed: "+&name+&"\n");
      then
        fail();
  end matchcontinue;
end parsePackageFile;

protected function loadModelFromEachClass
"function loadModelFromEachClass
  author: x02lucpo
  helper function to loadFile"
  input Absyn.Program inProgram;
  input String inString;
  input Option<String> optEncoding;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inProgram,inString,optEncoding)
    local
      Absyn.Within a;
      Absyn.Path path;
      Absyn.Program pnew,p_res,p_1;
      String id,dir;
      list<Absyn.Class> res;
      Absyn.TimeStamp ts;

    case (Absyn.PROGRAM(classes = {},within_ = a,globalBuildTimes=ts),_,_)
      then (Absyn.PROGRAM({},a,ts));

    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id) :: res),within_ = a,globalBuildTimes=ts),dir,optEncoding)
      equation
        path = Absyn.IDENT(id);
        pnew = loadClass(path, {"default"}, dir, optEncoding);
        p_res = loadModelFromEachClass(Absyn.PROGRAM(res,a,ts), dir, optEncoding);
        p_1 = Interactive.updateProgram(pnew, p_res);
      then
        p_1;

    else
      equation
        Debug.fprint(Flags.FAILTRACE, "ClassLoader.loadModelFromEachClass failed\n");
      then
        fail();
  end matchcontinue;
end loadModelFromEachClass;

protected function sortPackageOrder
  "Sort the classes based on the package.order file"
  input Absyn.Program p;
  input Absyn.Path path "Path where the classes to sort reside";
  input String filename;
  output Absyn.Program op;
protected
  String contents;
  String namesToSort;
algorithm
  op := matchcontinue (p,path,filename)
    local
      String contents,name;
      list<String> namesToSort, tv;
      Boolean pp,fp,ep;
      list<Absyn.NamedArg> ca;
      list<Absyn.ClassPart> cp;
      Option<String> cmt;
      Absyn.Info info;
      list<tuple<Boolean,Absyn.Element>> elts;
      Boolean b;
      
    case (p,path,filename)
      equation
        /*
        contents = System.readFile(filename);
        namesToSort = List.removeOnTrue("",stringEqual,List.map(System.strtok(contents, "\n"),System.trimWhitespace));
        Absyn.CLASS(name,pp,fp,ep,Absyn.R_PACKAGE(),Absyn.PARTS(tv,ca,cp,cmt),info) = Interactive.getPathedClassInProgram(path,p);
        b = sortPackageAlreadyInOrder(namesToSort,cp);
        print("sortPackageOrder: already in order " +& Absyn.pathString(path) +& "? " +& boolString(b) +& "\n");
        */
        /* ((cp,el)) = List.fold(namesToSort,sortPackageOrder3,(cp,{}));
        print("number of classparts " +& intString(listLength(cp)) +& "\n"); */
      then p;
  end matchcontinue;
end sortPackageOrder;

protected function sortPackageAlreadyInOrder
  input list<String> inNamesToSort;
  input list<Absyn.ClassPart> cp;
  output Boolean b;
algorithm
  b := matchcontinue (inNamesToSort,cp)
    local
      list<Absyn.ClassPart> rcp;
      list<Absyn.ElementItem> elts;
      list<String> namesToSort;
    case (_,_) then sortPackageAlreadyInOrder2(inNamesToSort,cp);
    else false;
  end matchcontinue;
end sortPackageAlreadyInOrder;

protected function sortPackageAlreadyInOrder2
  input list<String> inNamesToSort;
  input list<Absyn.ClassPart> cp;
  output Boolean b;
algorithm
  b := match (inNamesToSort,cp)
    local
      list<Absyn.ClassPart> rcp;
      list<Absyn.ElementItem> elts;
      list<String> namesToSort;
      String str;
    case ({},{}) then true;
    case (namesToSort,Absyn.PUBLIC(elts)::rcp)
      equation
        namesToSort = sortPackageAlreadyInOrderElts(namesToSort,elts);
      then sortPackageAlreadyInOrder2(namesToSort,rcp);
    case (namesToSort,Absyn.PROTECTED(elts)::rcp)
      equation
        namesToSort = sortPackageAlreadyInOrderElts(namesToSort,elts);
      then sortPackageAlreadyInOrder2(namesToSort,rcp);
    case (namesToSort,_::rcp)
      then sortPackageAlreadyInOrder2(namesToSort,rcp);
    else
      equation
        str = stringDelimitList(inNamesToSort, ", ");
        print("sortPackageAlreadyInOrder2 failed: " +& str +& "\n");
      then false;
  end match;
end sortPackageAlreadyInOrder2;

protected function sortPackageAlreadyInOrderElts
  input list<String> inNamesToSort;
  input list<Absyn.ElementItem> inElts;
  output list<String> outNamesToSort;
algorithm
  outNamesToSort := match (inNamesToSort,inElts)
    local
      String name1,name2;
      list<String> namesToSort;
      list<Absyn.ElementItem> elts;
    case (name1::namesToSort,Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF(class_=Absyn.CLASS(name=name2))))::elts)
      equation
        print(Util.if_(boolNot(name1 ==& name2), "sortPackageAlreadyInOrderElts failed: " +& name1 +& " == " +& name2 +& "\n", ""));
        true = name1 ==& name2;
      then sortPackageAlreadyInOrderElts(namesToSort,elts);
    case (namesToSort,_::elts)
      then sortPackageAlreadyInOrderElts(namesToSort,elts);
    else inNamesToSort;
  end match;
end sortPackageAlreadyInOrderElts;

end ClassLoader;


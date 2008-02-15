/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science, 
 * SE-58183 Linköping, Sweden. 
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
 * from Linköpings University, either from the above address, 
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
 
package ClassLoader 
" file:	 ClassLoader.mo
  package:      ClassLoader
  description: Loading of classes from $OPENMODELICALIBRARY.
 
  RCS: $Id$
 
  This module loads classes from $OPENMODELICALIBRARY. It exports two
  functions: 
  load_class function 
  load_file function
  
"

public import Absyn;
public import Interactive;

protected import System;
protected import Util;
protected import Parser;
protected import Print;
protected import Debug;

public function loadClass "function: loadClass
  This function takes a \'Path\' and the $OPENMODELICALIBRARY as a string
  and tries to load the class from the path.
  If the classname is qualified, the complete package is loaded. 
  E.g. load_class(Modelica.SIunits.Voltage) -> whole Modelica package loaded.
"
  input Absyn.Path inPath;
  input String inString;
  input list<Interactive.CompiledCFunction> inCompiledFunctions;
  output Absyn.Program outProgram;
  output list<Interactive.CompiledCFunction> outCompiledFunctions;
algorithm 
  (outProgram,outCompiledFunctions):=
  matchcontinue (inPath,inString,inCompiledFunctions)
    local
      String gd,classname,mp,pack;
      list<String> mps;
      Absyn.Program p;
      Absyn.Path rest,path;
      list<Interactive.CompiledCFunction> cf, newCF;
    case (Absyn.IDENT(name = classname),mp,cf) /* Simple names: Just load the file if it can be found in $OPENMODELICALIBRARY */ 
      equation 
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        (p, newCF) = loadClassFromMps(classname, mps, cf);
      then
        (p, newCF);
    case (Absyn.QUALIFIED(name = pack,path = rest),mp, cf) /* Qualified names: First check if it is defined in a file pack.mo */ 
      equation 
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        (p, newCF) = loadClassFromMps(pack, mps, cf);
      then
        (p, newCF);
    case ((path as Absyn.QUALIFIED(name = pack,path = rest)),mp,cf) /* Qualified names: Else, load the complete package and then check that the package contains the file */ 
      equation 
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        (p, newCF) = loadCompletePackageFromMps(pack, mps, Absyn.TOP(), Absyn.PROGRAM({},Absyn.TOP()), cf);
        _ = Interactive.getPathedClassInProgram(path, p);
      then
        (p, newCF);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "load_class failed\n");
      then
        fail();
  end matchcontinue;
end loadClass;

protected function existRegularFile "function: existRegularFile
 
  Checks if a file exists
"
  input String filename;
algorithm 
  0 := System.regularFileExists(filename);
end existRegularFile;

protected function existDirectoryFile "function: existDirectoryFile
 
  Checks if a directory exist
"
  input String filename;
algorithm 
  0 := System.directoryExists(filename);
end existDirectoryFile;

protected function loadClassFromMps "function: loadClassFromMps
 
  Loads a class or classes from a set of paths in OPENMODELICALIBRARY
"
  input Absyn.Ident inIdent;
  input list<String> inStringLst;
  input list<Interactive.CompiledCFunction> inCompiledFunctions;
  output Absyn.Program outProgram;
  output list<Interactive.CompiledCFunction> outCompiledFunctions;
algorithm 
  (outProgram,outCompiledFunctions):=
  matchcontinue (inIdent,inStringLst,inCompiledFunctions)
    local
      Absyn.Program p;
      String class_,mp;
      list<String> mps;
      list<Interactive.CompiledCFunction> cf, newCF;
    case (class_,(mp :: mps),cf)
      equation 
        (p, newCF) = loadClassFromMp(class_, mp, cf);
      then
        (p, newCF);
    case (class_,(_ :: mps),cf)
      equation 
        (p, newCF) = loadClassFromMps(class_, mps, cf);
      then
        (p, newCF);
  end matchcontinue;
end loadClassFromMps;

protected function loadClassFromMp "function: loadClassFromMp
  
  This function loads a modelica class \"className\" from the file path 
  \"<mp>/className.mo\" or it loads complete package from 
  \"<mp>/className/package.mo\"
"
  input Absyn.Ident inIdent;
  input String inString;
  input list<Interactive.CompiledCFunction> inCompiledFunctions;
  output Absyn.Program outProgram;
  output list<Interactive.CompiledCFunction> outCompiledFunctions;
algorithm 
  (outProgram,outCompiledFunctions):=
  matchcontinue (inIdent,inString,inCompiledFunctions)
    local
      String mp,pd,classfile,classfile_1,class_,mp_1,dirfile,packfile;
      Absyn.Program p;
      list<Interactive.CompiledCFunction> cf, newCF;
    case (class_,mp_1,cf)
      equation 
        mp = System.trim(mp_1, " \"\t");
        pd = System.pathDelimiter();
        classfile = stringAppend(class_, ".mo");
        classfile_1 = Util.stringAppendList({mp,pd,classfile});
        existRegularFile(classfile_1);
        print("parsing ");
        print(classfile_1);
        print("\n");
        p = Parser.parse(classfile_1);
      then
        (p,cf);
    case (class_,mp_1,cf)
      equation 
        mp = System.trim(mp_1, " \"\t");
        pd = System.pathDelimiter();
        dirfile = Util.stringAppendList({mp,pd,class_});
        packfile = Util.stringAppendList({dirfile,pd,"package.mo"});
        existDirectoryFile(dirfile);
        existRegularFile(packfile);
        Print.printBuf(
          "Class is package stored in a directory, loading whole package(incl. subdir)\n");
        (p, newCF) = loadCompletePackageFromMp(class_, mp, Absyn.TOP(), Absyn.PROGRAM({},Absyn.TOP()), cf);
      then
        (p, newCF);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "load_class_from_mp failed\n");
      then
        fail();
  end matchcontinue;
end loadClassFromMp;

protected function loadCompletePackageFromMps "function: loadCompletePackageFromMps
 
  Loads a whole package from the ModelicaPaths defined in OPENMODELICALIBRARY
"
  input Absyn.Ident inIdent;
  input list<String> inStringLst;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  input list<Interactive.CompiledCFunction> inCompiledFunctions;
  output Absyn.Program outProgram;
  output list<Interactive.CompiledCFunction> outCompiledFunctions;
algorithm 
  (outProgram,outCompiledFunctions):=
  matchcontinue (inIdent,inStringLst,inWithin,inProgram,inCompiledFunctions)
    local
      Absyn.Program p,oldp;
      String pack,mp;
      Absyn.Within within_;
      list<String> mps;
      list<Interactive.CompiledCFunction> cf, newCF;
    case (pack,(mp :: _),within_,oldp,cf)
      equation 
        (p, newCF) = loadCompletePackageFromMp(pack, mp, within_, oldp, cf);
      then
        (p, newCF);
    case (pack,(_ :: mps),within_,oldp,cf)
      equation 
        (p, newCF) = loadCompletePackageFromMps(pack, mps, within_, oldp, cf);
      then
        (p, newCF);
  end matchcontinue;
end loadCompletePackageFromMps;

protected function loadCompletePackageFromMp "function: loadCompletePackageFromMp
  
  Loads a whole package from the ModelicaPaths defined in OPENMODELICALIBRARY
"
  input Absyn.Ident inIdent;
  input String inString;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  input list<Interactive.CompiledCFunction> inCompiledFunctions;
  output Absyn.Program outProgram;
  output list<Interactive.CompiledCFunction> outCompiledFunctions;
algorithm 
  (outProgram,outCompiledFunctions):=
  matchcontinue (inIdent,inString,inWithin,inProgram,inCompiledFunctions)
    local
      String pd,mp_1,packagefile,subdirstr,pack,mp;
      list<Absyn.Class> p1,oldc;
      Absyn.Within w1,within_;
      Absyn.Program p1_1,p2,p;
      list<String> subdirs;
      Absyn.Path wpath_1,wpath;
      list<Interactive.CompiledCFunction> cf, newCF, newCF_1, newCF_2;
    case (pack,mp,(within_ as Absyn.TOP()),Absyn.PROGRAM(classes = oldc),cf)
      equation 
        pd = System.pathDelimiter();
        mp_1 = Util.stringAppendList({mp,pd,pack});
        packagefile = Util.stringAppendList({mp_1,pd,"package.mo"});
        existRegularFile(packagefile);
        print("parsing ");
        print(packagefile);
        print("\n");
        Absyn.PROGRAM(p1,w1) = Parser.parse(packagefile);
        Print.printBuf("loading ");
        Print.printBuf(packagefile);
        Print.printBuf("\n");
        (p1_1, newCF) = Interactive.updateProgram(Absyn.PROGRAM(p1,w1), Absyn.PROGRAM(oldc,Absyn.TOP()), cf);
        subdirs = System.subDirectories(mp_1);
        subdirstr = Util.stringDelimitList(subdirs, ", ");
        print("subdirs =");
        print(subdirstr);
        print("\n");
        (p2, newCF_1) = loadCompleteSubdirs(subdirs, pack, mp_1, within_, p1_1, newCF);
        (p, newCF_2) = loadCompleteSubfiles(pack, mp_1, within_, p2, newCF_1);
      then
        (p, newCF_2);
    case (pack,mp,(within_ as Absyn.WITHIN(path = wpath)),Absyn.PROGRAM(classes = oldc),cf)
      equation 
        pd = System.pathDelimiter();
        mp_1 = Util.stringAppendList({mp,pd,pack});
        packagefile = Util.stringAppendList({mp_1,pd,"package.mo"});
        existRegularFile(packagefile);
        print("parsing ");
        print(packagefile);
        print("\n");
        Absyn.PROGRAM(p1,w1) = Parser.parse(packagefile);
        Print.printBuf("loading ");
        Print.printBuf(packagefile);
        Print.printBuf("\n");
        (p1_1,newCF) = Interactive.updateProgram(Absyn.PROGRAM(p1,Absyn.WITHIN(wpath)), 
          Absyn.PROGRAM(oldc,Absyn.TOP()),cf);
        subdirs = System.subDirectories(mp_1);
        subdirstr = Util.stringDelimitList(subdirs, ", ");
        print("subdirs =");
        print(subdirstr);
        print("\n");
        (p2,newCF_1) = loadCompleteSubdirs(subdirs, pack, mp_1, within_, p1_1, newCF);
        wpath_1 = Absyn.joinPaths(wpath, Absyn.IDENT(pack));
        (p, newCF_2) = loadCompleteSubfiles(pack, mp_1, within_, p2, newCF_1);
      then
        (p, newCF_2);
    case (_,_,_,_,_) then fail(); 
  end matchcontinue;
end loadCompletePackageFromMp;

protected function loadCompleteSubdirs "function: loadCompleteSubdirs
  
  Loads all classes present in a subdirectory
"
  input list<String> inStringLst;
  input Absyn.Ident inIdent;
  input String inString;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  input list<Interactive.CompiledCFunction> inCompiledFunctions;
  output Absyn.Program outProgram;
  output list<Interactive.CompiledCFunction> outCompiledFunctions;
algorithm 
  (outProgram,outCompiledFunctions):=
  matchcontinue (inStringLst,inIdent,inString,inWithin,inProgram,inCompiledFunctions)
    local
      Absyn.Within w,w2,within_;
      list<Absyn.Class> oldcls;
      Absyn.Path pack_1,pack2;
      Absyn.Program p,p_1,oldp;
      String pack,pack1,mp;
      list<String> packs;
      list<Interactive.CompiledCFunction> cf, newCF, newCF_1;
    case ({},_,_,w,Absyn.PROGRAM(classes = oldcls,within_ = w2),cf) then (Absyn.PROGRAM(oldcls,w2),cf); 
    case ((pack :: packs),pack1,mp,(within_ as Absyn.WITHIN(path = pack2)),oldp,cf)
      equation 
        pack_1 = Absyn.joinPaths(pack2, Absyn.IDENT(pack1));
        (p, newCF) = loadCompletePackageFromMp(pack, mp, Absyn.WITHIN(pack_1), oldp, cf);
        (p_1, newCF_1) = loadCompleteSubdirs(packs, pack1, mp, within_, p, newCF);
      then
        (p_1, newCF_1);
    case ((pack :: packs),pack1,mp,(within_ as Absyn.TOP()),oldp,cf)
      equation 
        pack_1 = Absyn.joinPaths(Absyn.IDENT(pack1), Absyn.IDENT(pack));
        (p, newCF) = loadCompletePackageFromMp(pack, mp, Absyn.WITHIN(Absyn.IDENT(pack1)), oldp, cf);
        (p_1, newCF_1) = loadCompleteSubdirs(packs, pack1, mp, within_, p, newCF);
      then
        (p_1, newCF_1);
    case ((pack :: packs),pack1,mp,within_,p,cf)
      equation 
        (p_1, newCF) = loadCompleteSubdirs(packs, pack1, mp, within_, p, cf);
      then
        (p_1, newCF);
    case (_,_,_,_,_,_)
      equation 
        print("load_complete_subdirs failed\n");
      then
        fail();
  end matchcontinue;
end loadCompleteSubdirs;

protected function loadCompleteSubfiles "function: loadCompleteSubfiles
  
  This function loads all modelicafiles (.mo) from a subdir package.
"
  input Absyn.Ident inIdent;
  input String inString;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  input list<Interactive.CompiledCFunction> inCompiledFunctions;
  output Absyn.Program outProgram;
  output list<Interactive.CompiledCFunction> outCompiledFunctions;
algorithm 
  (outProgram,outCompiledFunctions):=
  matchcontinue (inIdent,inString,inWithin,inProgram,inCompiledFunctions)
    local
      list<String> mofiles;
      Absyn.Path within_1,within_;
      Absyn.Program p,oldp;
      String pack,mp;
      list<Interactive.CompiledCFunction> cf, newCF;
    case (pack,mp,Absyn.WITHIN(path = within_),oldp,cf)
      equation 
        mofiles = System.moFiles(mp) "Here .mo files in same directory as package.mo should be loaded as sub-packages" ;
        within_1 = Absyn.joinPaths(within_, Absyn.IDENT(pack));
        (p, newCF) = loadSubpackageFiles(mofiles, mp, Absyn.WITHIN(within_1), oldp, cf);
      then
        (p, newCF);
    case (pack,mp,Absyn.TOP(),oldp,cf)
      equation 
        mofiles = System.moFiles(mp) "Here .mo files in same directory as package.mo should be loaded as sub-packages" ;
        (p, newCF) = loadSubpackageFiles(mofiles, mp, Absyn.WITHIN(Absyn.IDENT(pack)), oldp, cf);
      then
        (p, newCF);
    case (_,_,_,_,_)
      equation 
        print("load_complete_subfiles failed\n");
      then
        fail();
  end matchcontinue;
end loadCompleteSubfiles;

protected function loadSubpackageFiles "function: loadSubpackageFiles
 
  Loads all classes from a subpackage
"
  input list<String> inStringLst;
  input String inString;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  input list<Interactive.CompiledCFunction> inCompiledFunction;
  output Absyn.Program outProgram;
  output list<Interactive.CompiledCFunction> outCompiledFunction;
algorithm 
  (outProgram,outCompiledFunction):=
  matchcontinue (inStringLst,inString,inWithin,inProgram,inCompiledFunction)
    local
      String mp,pd,f_1,f;
      Absyn.Within within_,w;
      list<Absyn.Class> cls,oldc;
      Absyn.Program p_1,p_2;
      list<String> fs;
      list<Interactive.CompiledCFunction> cf, newCF, newCF_1;
    case ({},mp,within_,Absyn.PROGRAM(classes = cls,within_ = w),cf) then (Absyn.PROGRAM(cls,w),cf); 
    case ((f :: fs),mp,within_,Absyn.PROGRAM(classes = oldc),cf)
      equation 
        pd = System.pathDelimiter();
        f_1 = Util.stringAppendList({mp,pd,f});
        print("parsing ");
        print(f_1);
        print("\n");
        Absyn.PROGRAM(cls,_) = Parser.parse(f_1);
        Print.printBuf("loading ");
        Print.printBuf(f_1);
        Print.printBuf("\n");
        (p_1,newCF) = Interactive.updateProgram(Absyn.PROGRAM(cls,within_), Absyn.PROGRAM(oldc,Absyn.TOP()), cf);
        (p_2,newCF_1) = loadSubpackageFiles(fs, mp, within_, p_1, newCF);
      then
        (p_2,newCF_1);
    case (_,_,_,_,_)
      equation 
        print("load_subpackage_files failed\n");
      then
        fail();
  end matchcontinue;
end loadSubpackageFiles;

public function loadFile "function loadFile
  author: x02lucpo
  load the file or the directory structure if the file is a
  package.mo
"
  input String inString;
  input list<Interactive.CompiledCFunction> inCompiledFunctions;
  output Absyn.Program outProgram;
  output list<Interactive.CompiledCFunction> outCompiledFunctions;
algorithm 
  (outProgram, outCompiledFunctions):=
  matchcontinue (inString,inCompiledFunctions)
    local
      String dir,pd,dir_1,name,filename;
      Absyn.Program p1_1,p1;
      list<Interactive.CompiledCFunction> cf, newCF;
    case (name,cf)
      equation 
        0 = System.regularFileExists(name);
        (dir,"package.mo") = Util.getAbsoluteDirectoryAndFile(name);
        p1_1 = Parser.parse(name);
        pd = System.pathDelimiter();
        dir_1 = Util.stringAppendList({dir,pd,".."});
        (p1, newCF) = loadModelFromEachClass(p1_1, cf, dir_1);
      then
        (p1, newCF);
    case (name,cf)
      equation 
        0 = System.regularFileExists(name);
        (dir,filename) = Util.getAbsoluteDirectoryAndFile(name);
        p1 = Parser.parse(name);
      then
        (p1,cf);
    case (_,_)
      equation 
        Debug.fprint("failtrace", "load_file failed\n");
      then
        fail();
  end matchcontinue;
end loadFile;

protected function loadModelFromEachClass "function loadModelFromEachClass
  author: x02lucpo
 
  helper function to load_file
"
  input Absyn.Program inProgram;
  input list<Interactive.CompiledCFunction> inCompiledFunctions;
  input String inString;
  output Absyn.Program outProgram;
  output list<Interactive.CompiledCFunction> outCompiledFunctions;
algorithm 
  (outProgram,outCompiledFunctions):=
  matchcontinue (inProgram,inCompiledFunctions,inString)
    local
      Absyn.Within a;
      Absyn.Path path;
      Absyn.Program pnew,p_res,p_1;
      String id,dir;
      list<Absyn.Class> res;
      list<Interactive.CompiledCFunction> cf, newCF, newCF_1, newCF_2;
    case (Absyn.PROGRAM(classes = {},within_ = a),cf,_) then (Absyn.PROGRAM({},a),cf); 
    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id) :: res),within_ = a),cf,dir)
      equation
        path = Absyn.IDENT(id);
        (pnew, newCF) = loadClass(path, dir, cf);
        (p_res, newCF_1) = loadModelFromEachClass(Absyn.PROGRAM(res,a), newCF, dir);
        (p_1, newCF_2) = Interactive.updateProgram(pnew, p_res, newCF_1);
      then
        (p_1, newCF_2);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "-load_model_from_each_class failed\n");
      then
        fail();
  end matchcontinue;
end loadModelFromEachClass;
end ClassLoader;


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
 
  This module loads classes from $OPENMODELICALIBRARY. It exports several functions: 
  loadClass function
  loadModel function 
  loadFile function"

public import Absyn;
public import Interactive;

protected import System;
protected import Util;
protected import Parser;
protected import Print;
protected import Debug;

public function loadClass 
"function: loadClass
  This function takes a \'Path\' and the $OPENMODELICALIBRARY as a string
  and tries to load the class from the path.
  If the classname is qualified, the complete package is loaded. 
  E.g. load_class(Modelica.SIunits.Voltage) -> whole Modelica package loaded."
  input Absyn.Path inPath;
  input String inString;
  output Absyn.Program outProgram;
algorithm 
  outProgram := matchcontinue (inPath,inString)
    local
      String gd,classname,mp,pack;
      list<String> mps;
      Absyn.Program p;
      Absyn.Path rest,path;
      Absyn.TimeStamp ts;
    /* Simple names: Just load the file if it can be found in $OPENMODELICALIBRARY */
    case (Absyn.IDENT(name = classname),mp) 
      equation 
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        p = loadClassFromMps(classname, mps);
      then
        p;
    /* Qualified names: First check if it is defined in a file pack.mo */
    case (Absyn.QUALIFIED(name = pack,path = rest),mp) 
      equation 
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        p = loadClassFromMps(pack, mps);
      then
        p;
    /* Qualified names: Else, load the complete package and then check that the package contains the file */
    case ((path as Absyn.QUALIFIED(name = pack,path = rest)),mp)
      equation 
        ts = Absyn.getNewTimeStamp();
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        p = loadCompletePackageFromMps(pack, mps, Absyn.TOP(), Absyn.PROGRAM({},Absyn.TOP(),ts));
        // _ = Interactive.getPathedClassInProgram(path, p);
      then
        p;
    /* failure */
    case (_,_)
      equation 
        Debug.fprint("failtrace", "ClassLoader.loadClass failed\n");
      then
        fail();
  end matchcontinue;
end loadClass;

protected function existRegularFile 
"function: existRegularFile 
  Checks if a file exists"
  input String filename;
algorithm 
  0 := System.regularFileExists(filename);
end existRegularFile;

protected function existDirectoryFile 
"function: existDirectoryFile 
  Checks if a directory exist"
  input String filename;
algorithm 
  0 := System.directoryExists(filename);
end existDirectoryFile;

protected function loadClassFromMps 
"function: loadClassFromMps 
  Loads a class or classes from a set of paths in OPENMODELICALIBRARY"
  input Absyn.Ident inIdent;
  input list<String> inStringLst;
  output Absyn.Program outProgram;
algorithm 
  outProgram := matchcontinue (inIdent,inStringLst)
    local
      Absyn.Program p;
      String class_,mp;
      list<String> mps;
    case (class_,(mp :: mps))
      equation 
        p = loadClassFromMp(class_, mp);
      then
        p;
    case (class_,(_ :: mps))
      equation 
        p = loadClassFromMps(class_, mps);
      then
        p;
  end matchcontinue;
end loadClassFromMps;

protected function loadClassFromMp 
"function: loadClassFromMp  
  This function loads a modelica class \"className\" from the file path 
  \"<mp>/className.mo\" or it loads complete package from 
  \"<mp>/className/package.mo\""
  input Absyn.Ident inIdent;
  input String inString;
  output Absyn.Program outProgram;
algorithm 
  outProgram := matchcontinue (inIdent,inString)
    local
      String mp,pd,classfile,classfile_1,class_,mp_1,dirfile,packfile;
      Absyn.Program p;
      Absyn.TimeStamp ts;
      
    case (class_,mp_1)
      local Real t1, t2; String s;
      equation
        mp = System.trim(mp_1, " \"\t");
        pd = System.pathDelimiter();
        classfile = stringAppend(class_, ".mo");
        classfile_1 = Util.stringAppendList({mp,pd,classfile});
        existRegularFile(classfile_1);
        print("parsing ");
        print(classfile_1);
        t1 = clock();
        p = Parser.parse(classfile_1);
        t2 = clock();
        s = realString(t2 -. t1);        
        print(" [" +& s +& "s]\n");
      then
        p;
        
    case (class_,mp_1)
      equation 
        ts = Absyn.getNewTimeStamp();
        mp = System.trim(mp_1, " \"\t");
        pd = System.pathDelimiter();
        dirfile = Util.stringAppendList({mp,pd,class_});
        packfile = Util.stringAppendList({dirfile,pd,"package.mo"});
        existDirectoryFile(dirfile);
        existRegularFile(packfile);
        Print.printBuf("Class is package stored in a directory, loading whole package(incl. subdir)\n");
        p = loadCompletePackageFromMp(class_, mp, Absyn.TOP(), Absyn.PROGRAM({},Absyn.TOP(), ts));
      then
        p;
    case (_,_)
      equation 
        Debug.fprint("failtrace", "ClassLoader.loadClassFromMp failed\n");
      then
        fail();
  end matchcontinue;
end loadClassFromMp;

protected function loadCompletePackageFromMps 
"function: loadCompletePackageFromMps 
  Loads a whole package from the ModelicaPaths defined in OPENMODELICALIBRARY"
  input Absyn.Ident inIdent;
  input list<String> inStringLst;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm 
  outProgram := matchcontinue (inIdent,inStringLst,inWithin,inProgram)
    local
      Absyn.Program p,oldp;
      String pack,mp;
      Absyn.Within within_;
      list<String> mps;
    case (pack,(mp :: _),within_,oldp)
      equation 
        p = loadCompletePackageFromMp(pack, mp, within_, oldp);
      then
        p;
    case (pack,(_ :: mps),within_,oldp)
      equation 
        p = loadCompletePackageFromMps(pack, mps, within_, oldp);
      then
        p;
  end matchcontinue;
end loadCompletePackageFromMps;

protected function loadCompletePackageFromMp 
"function: loadCompletePackageFromMp  
  Loads a whole package from the ModelicaPaths defined in OPENMODELICALIBRARY"
  input Absyn.Ident inIdent;
  input String inString;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm 
  outProgram := matchcontinue (inIdent,inString,inWithin,inProgram)
    local
      String pd,mp_1,packagefile,subdirstr,pack,mp;
      list<Absyn.Class> p1,oldc;
      Absyn.Within w1,within_;
      Absyn.Program p1_1,p2,p;
      list<String> subdirs;
      Absyn.Path wpath_1,wpath;
      Real t1, t2; String s;
      Absyn.TimeStamp ts;
    case (pack,mp,(within_ as Absyn.TOP()),Absyn.PROGRAM(classes = oldc)) 
      equation
        pd = System.pathDelimiter();
        mp_1 = Util.stringAppendList({mp,pd,pack});
        packagefile = Util.stringAppendList({mp_1,pd,"package.mo"});
        existRegularFile(packagefile);
        print("parsing ");
        print(packagefile);
        t1 = clock();
        Absyn.PROGRAM(p1,w1,ts) = Parser.parse(packagefile);
        t2 = clock();
        s = realString(t2 -. t1);        
        print(" [" +& s +& "s]\n");
        Print.printBuf("loading ");
        Print.printBuf(packagefile);
        Print.printBuf("\n");
        p1_1 = Interactive.updateProgram(Absyn.PROGRAM(p1,w1,ts), Absyn.PROGRAM(oldc,Absyn.TOP(),ts));
        subdirs = System.subDirectories(mp_1);
        subdirstr = Util.stringDelimitList(subdirs, ", ");
        print("subdirs =");
        print(subdirstr);
        print("\n");
        p2 = loadCompleteSubdirs(subdirs, pack, mp_1, within_, p1_1);
        p = loadCompleteSubfiles(pack, mp_1, within_, p2);
      then
        p;
        
    case (pack,mp,(within_ as Absyn.WITHIN(path = wpath)),Absyn.PROGRAM(classes = oldc))
      equation 
        pd = System.pathDelimiter();
        mp_1 = Util.stringAppendList({mp,pd,pack});
        packagefile = Util.stringAppendList({mp_1,pd,"package.mo"});
        existRegularFile(packagefile);
        print("parsing ");
        print(packagefile);
        t1 = clock();        
        Absyn.PROGRAM(p1,w1,ts) = Parser.parse(packagefile);
        t2 = clock();
        s  = realString(t2 -. t1);        
        print(" [" +& s +& "s]\n");
        Print.printBuf("loading ");
        Print.printBuf(packagefile);
        Print.printBuf("\n");
        p1_1 = Interactive.updateProgram(Absyn.PROGRAM(p1,Absyn.WITHIN(wpath),ts),Absyn.PROGRAM(oldc,Absyn.TOP(),ts));
        subdirs = System.subDirectories(mp_1);
        subdirstr = Util.stringDelimitList(subdirs, ", ");
        print("subdirs =");
        print(subdirstr);
        print("\n");
        p2 = loadCompleteSubdirs(subdirs, pack, mp_1, within_, p1_1);
        wpath_1 = Absyn.joinPaths(wpath, Absyn.IDENT(pack));
        p = loadCompleteSubfiles(pack, mp_1, within_, p2);
      then
        p;
        
    case (_,_,_,_)
      equation 
        // adrpo: not needed as it might fail due to no package file!
        // print("ClassLoader.loadCompletePackageFromMp failed\n");
      then fail();
      
  end matchcontinue;
end loadCompletePackageFromMp;

protected function loadCompleteSubdirs 
"function: loadCompleteSubdirs  
  Loads all classes present in a subdirectory"
  input list<String> inStringLst;
  input Absyn.Ident inIdent;
  input String inString;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm 
  outProgram := matchcontinue (inStringLst,inIdent,inString,inWithin,inProgram)
    local
      Absyn.Within w,w2,within_;
      list<Absyn.Class> oldcls;
      Absyn.Path pack_1,pack2;
      Absyn.Program p,p_1,oldp;
      String pack,pack1,mp;
      list<String> packs;
      Absyn.TimeStamp ts;
      
    case ({},_,_,w,Absyn.PROGRAM(classes = oldcls,within_ = w2, globalBuildTimes=ts)) 
      then (Absyn.PROGRAM(oldcls,w2,ts));
    case ((pack :: packs),pack1,mp,(within_ as Absyn.WITHIN(path = pack2)),oldp) 
      equation 
        pack_1 = Absyn.joinPaths(pack2, Absyn.IDENT(pack1));
        p = loadCompletePackageFromMp(pack, mp, Absyn.WITHIN(pack_1), oldp);
        p_1 = loadCompleteSubdirs(packs, pack1, mp, within_, p);
      then
        p_1;
        
    case ((pack :: packs),pack1,mp,(within_ as Absyn.TOP()),oldp)
      equation 
        pack_1 = Absyn.joinPaths(Absyn.IDENT(pack1), Absyn.IDENT(pack));
        p = loadCompletePackageFromMp(pack, mp, Absyn.WITHIN(Absyn.IDENT(pack1)), oldp);        
        p_1 = loadCompleteSubdirs(packs, pack1, mp, within_, p);
      then
        p_1;
        
    case ((pack :: packs),pack1,mp,within_,p)
      equation 
        p_1 = loadCompleteSubdirs(packs, pack1, mp, within_, p);
      then
        p_1;
        
    case (_,_,_,_,_)
      equation 
        print("ClassLoader.loadCompleteSubdirs failed\n");
      then
        fail();
  end matchcontinue;
end loadCompleteSubdirs;

protected function loadCompleteSubfiles 
"function: loadCompleteSubfiles  
  This function loads all modelicafiles (.mo) from a subdir package."
  input Absyn.Ident inIdent;
  input String inString;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm 
  outProgram := matchcontinue (inIdent,inString,inWithin,inProgram)
    local
      list<String> mofiles;
      Absyn.Path within_1,within_;
      Absyn.Program p,oldp;
      String pack,mp;
      
    case (pack,mp,Absyn.WITHIN(path = within_),oldp)
      equation 
        mofiles = System.moFiles(mp) "Here .mo files in same directory as package.mo should be loaded as sub-packages" ;
        within_1 = Absyn.joinPaths(within_, Absyn.IDENT(pack));
        p = loadSubpackageFiles(mofiles, mp, Absyn.WITHIN(within_1), oldp);
      then
        p;

    case (pack,mp,Absyn.TOP(),oldp)
      equation 
        mofiles = System.moFiles(mp) "Here .mo files in same directory as package.mo should be loaded as sub-packages" ;
        p = loadSubpackageFiles(mofiles, mp, Absyn.WITHIN(Absyn.IDENT(pack)), oldp);
      then
        p;

    case (_,_,_,_)
      equation 
        print("ClassLoader.loadCompleteSubfiles failed\n");
      then
        fail();
  end matchcontinue;
end loadCompleteSubfiles;

protected function loadSubpackageFiles 
"function: loadSubpackageFiles 
  Loads all classes from a subpackage"
  input list<String> inStringLst;
  input String inString;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm 
  outProgram := matchcontinue (inStringLst,inString,inWithin,inProgram)
    local
      String mp,pd,f_1,f;
      Absyn.Within within_,w;
      list<Absyn.Class> cls,oldc;
      Absyn.Program p_1,p_2;
      list<String> fs;
      Real t1, t2; String s;
      Absyn.TimeStamp ts;
      
    case ({},mp,within_,Absyn.PROGRAM(classes = cls,within_ = w, globalBuildTimes=ts)) 
      then Absyn.PROGRAM(cls,w,ts);
              
    case ((f :: fs),mp,within_,Absyn.PROGRAM(classes = oldc,globalBuildTimes = ts)) 
      equation 
        pd = System.pathDelimiter();
        f_1 = Util.stringAppendList({mp,pd,f});
        print("parsing ");
        print(f_1);
        t1 = clock();        
        Absyn.PROGRAM(cls,_,_) = Parser.parse(f_1);
        t2 = clock();
        s  = realString(t2 -. t1);        
        print(" [" +& s +& "s]\n");        
        Print.printBuf("loading ");
        Print.printBuf(f_1);
        Print.printBuf("\n");
        p_1 = Interactive.updateProgram(Absyn.PROGRAM(cls,within_,ts), Absyn.PROGRAM(oldc,Absyn.TOP(),ts));        
        p_2 = loadSubpackageFiles(fs, mp, within_, p_1);
      then
        p_2;
        
    case (_,_,_,_)
      equation 
        print("ClassLoader.loadSubpackageFiles failed\n");
      then
        fail();
  end matchcontinue;
end loadSubpackageFiles;

public function loadFile 
"function loadFile
  author: x02lucpo
  load the file or the directory structure if the file is named package.mo"
  input String inString;
  output Absyn.Program outProgram;
algorithm 
  outProgram := matchcontinue inString
    local
      String dir,pd,dir_1,name,filename;
      Absyn.Program p1_1,p1;
      
    case name
      equation 
        0 = System.regularFileExists(name);
        (dir,"package.mo") = Util.getAbsoluteDirectoryAndFile(name);
        p1_1 = Parser.parse(name);
        pd = System.pathDelimiter();
        dir_1 = Util.stringAppendList({dir,pd,".."});
        p1 = loadModelFromEachClass(p1_1, dir_1);
      then
        p1;
        
    case name
      equation 
        0 = System.regularFileExists(name);
        (dir,filename) = Util.getAbsoluteDirectoryAndFile(name);
        p1 = Parser.parse(name);
      then
        p1;
        
    // faliling
    case _
      equation 
        Debug.fprint("failtrace", "ClassLoader.loadFile failed\n");
      then
        fail();
  end matchcontinue;
end loadFile;

protected function loadModelFromEachClass 
"function loadModelFromEachClass
  author: x02lucpo 
  helper function to loadFile"
  input Absyn.Program inProgram;
  input String inString;
  output Absyn.Program outProgram;
algorithm 
  outProgram := matchcontinue (inProgram,inString)
    local
      Absyn.Within a;
      Absyn.Path path;
      Absyn.Program pnew,p_res,p_1;
      String id,dir;
      list<Absyn.Class> res;
      Absyn.TimeStamp ts;
      
    case (Absyn.PROGRAM(classes = {},within_ = a,globalBuildTimes=ts),_) 
      then (Absyn.PROGRAM({},a,ts));
              
    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id) :: res),within_ = a,globalBuildTimes=ts),dir) 
      equation 
        path = Absyn.IDENT(id);
        pnew = loadClass(path, dir);
        p_res = loadModelFromEachClass(Absyn.PROGRAM(res,a,ts), dir);        
        p_1 = Interactive.updateProgram(pnew, p_res);
      then
        p_1;
        
    case (_,_)
      equation 
        Debug.fprint("failtrace", "ClassLoader.loadModelFromEachClass failed\n");
      then
        fail();
  end matchcontinue;
end loadModelFromEachClass;

end ClassLoader;


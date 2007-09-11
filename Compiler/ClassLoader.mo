/* This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2007, Linköpings universitet, Department of
 * Computer and Information Science, PELAB
 * 
 * All rights reserved.
 * 
 * (The new BSD license, see also
 * http://www.opensource.org/licenses/bsd-license.php)
 * 
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *  Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * 
 *  Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in
 *   the documentation and/or other materials provided with the
 *   distribution.
 * 
 *  Neither the name of Linköpings universitet nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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

protected import System;
protected import Interactive;
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
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inPath,inString)
    local
      String gd,classname,mp,pack;
      list<String> mps;
      Absyn.Program p;
      Absyn.Path rest,path;
    case (Absyn.IDENT(name = classname),mp) /* Simple names: Just load the file if it can be found in $OPENMODELICALIBRARY */ 
      equation 
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        p = loadClassFromMps(classname, mps);
      then
        p;
    case (Absyn.QUALIFIED(name = pack,path = rest),mp) /* Qualified names: First check if it is defined in a file pack.mo */ 
      equation 
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        p = loadClassFromMps(pack, mps);
      then
        p;
    case ((path as Absyn.QUALIFIED(name = pack,path = rest)),mp) /* Qualified names: Else, load the complete package and then check that the package contains the file */ 
      equation 
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        p = loadCompletePackageFromMps(pack, mps, Absyn.TOP(), Absyn.PROGRAM({},Absyn.TOP()));
        _ = Interactive.getPathedClassInProgram(path, p);
      then
        p;
    case (_,_)
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
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inIdent,inStringLst)
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

protected function loadClassFromMp "function: loadClassFromMp
  
  This function loads a modelica class \"className\" from the file path 
  \"<mp>/className.mo\" or it loads complete package from 
  \"<mp>/className/package.mo\"
"
  input Absyn.Ident inIdent;
  input String inString;
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inIdent,inString)
    local
      String mp,pd,classfile,classfile_1,class_,mp_1,dirfile,packfile;
      Absyn.Program p;
    case (class_,mp_1)
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
        p;
    case (class_,mp_1)
      equation 
        mp = System.trim(mp_1, " \"\t");
        pd = System.pathDelimiter();
        dirfile = Util.stringAppendList({mp,pd,class_});
        packfile = Util.stringAppendList({dirfile,pd,"package.mo"});
        existDirectoryFile(dirfile);
        existRegularFile(packfile);
        Print.printBuf(
          "Class is package stored in a directory, loading whole package(incl. subdir)\n");
        p = loadCompletePackageFromMp(class_, mp, Absyn.TOP(), Absyn.PROGRAM({},Absyn.TOP()));
      then
        p;
    case (_,_)
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
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inIdent,inStringLst,inWithin,inProgram)
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

protected function loadCompletePackageFromMp "function: loadCompletePackageFromMp
  
  Loads a whole package from the ModelicaPaths defined in OPENMODELICALIBRARY
"
  input Absyn.Ident inIdent;
  input String inString;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inIdent,inString,inWithin,inProgram)
    local
      String pd,mp_1,packagefile,subdirstr,pack,mp;
      list<Absyn.Class> p1,oldc;
      Absyn.Within w1,within_;
      Absyn.Program p1_1,p2,p;
      list<String> subdirs;
      Absyn.Path wpath_1,wpath;
    case (pack,mp,(within_ as Absyn.TOP()),Absyn.PROGRAM(classes = oldc))
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
        p1_1 = Interactive.updateProgram(Absyn.PROGRAM(p1,w1), Absyn.PROGRAM(oldc,Absyn.TOP()));
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
        print("\n");
        Absyn.PROGRAM(p1,w1) = Parser.parse(packagefile);
        Print.printBuf("loading ");
        Print.printBuf(packagefile);
        Print.printBuf("\n");
        p1_1 = Interactive.updateProgram(Absyn.PROGRAM(p1,Absyn.WITHIN(wpath)), 
          Absyn.PROGRAM(oldc,Absyn.TOP()));
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
    case (_,_,_,_) then fail(); 
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
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inStringLst,inIdent,inString,inWithin,inProgram)
    local
      Absyn.Within w,w2,within_;
      list<Absyn.Class> oldcls;
      Absyn.Path pack_1,pack2;
      Absyn.Program p,p_1,oldp;
      String pack,pack1,mp;
      list<String> packs;
    case ({},_,_,w,Absyn.PROGRAM(classes = oldcls,within_ = w2)) then Absyn.PROGRAM(oldcls,w2); 
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
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inIdent,inString,inWithin,inProgram)
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
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inStringLst,inString,inWithin,inProgram)
    local
      String mp,pd,f_1,f;
      Absyn.Within within_,w;
      list<Absyn.Class> cls,oldc;
      Absyn.Program p_1,p_2;
      list<String> fs;
    case ({},mp,within_,Absyn.PROGRAM(classes = cls,within_ = w)) then Absyn.PROGRAM(cls,w); 
    case ((f :: fs),mp,within_,Absyn.PROGRAM(classes = oldc))
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
        p_1 = Interactive.updateProgram(Absyn.PROGRAM(cls,within_), Absyn.PROGRAM(oldc,Absyn.TOP()));
        p_2 = loadSubpackageFiles(fs, mp, within_, p_1);
      then
        p_2;
    case (_,_,_,_)
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
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inString)
    local
      String dir,pd,dir_1,name,filename;
      Absyn.Program p1_1,p1;
    case (name)
      equation 
        0 = System.regularFileExists(name);
        (dir,"package.mo") = Util.getAbsoluteDirectoryAndFile(name);
        p1_1 = Parser.parse(name);
        pd = System.pathDelimiter();
        dir_1 = Util.stringAppendList({dir,pd,".."});
        p1 = loadModelFromEachClass(p1_1, dir_1);
      then
        p1;
    case (name)
      equation 
        0 = System.regularFileExists(name);
        (dir,filename) = Util.getAbsoluteDirectoryAndFile(name);
        p1 = Parser.parse(name);
      then
        p1;
    case (_)
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
  input String inString;
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inProgram,inString)
    local
      Absyn.Within a;
      Absyn.Path path;
      Absyn.Program pnew,p_res,p_1;
      String id,dir;
      list<Absyn.Class> res;
    case (Absyn.PROGRAM(classes = {},within_ = a),_) then Absyn.PROGRAM({},a); 
    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id) :: res),within_ = a),dir)
      equation 
        path = Absyn.IDENT(id);
        pnew = loadClass(path, dir);
        p_res = loadModelFromEachClass(Absyn.PROGRAM(res,a), dir);
        p_1 = Interactive.updateProgram(pnew, p_res);
      then
        p_1;
    case (_,_)
      equation 
        Debug.fprint("failtrace", "-load_model_from_each_class failed\n");
      then
        fail();
  end matchcontinue;
end loadModelFromEachClass;
end ClassLoader;


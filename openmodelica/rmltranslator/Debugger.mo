encapsulated package Debugger

import LexerModelica;
import ParserModelica;
import ParseCodeModelica;
import Translate;
import Absyn;
import Absynrml;
import Util;
import System;
import Types;
import OMCCTypes;
import Flags;
import Error;
import Dump;
import Print;
import ErrorExt;
import Debug;

public function debug
"function: main
  This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
  start the translation."
  input String filename;
  protected
  String fileextension;
  list<OMCCTypes.Token> tokens;
  Absynrml.Program rmlast;
  Absyn.Program modast;
  Boolean result;
algorithm
  tokens := LexerModelica.scan(filename);
  (result,ParseCodeModelica.PROGRAM(rmlast)) := ParserModelica.parse(tokens,filename);
  modast:=Translate.transform(rmlast,filename);
  fileextension :=System.stringReplace(filename,".rml",".mo");
  System.writeFile(fileextension,Dump.unparseStr(modast,true));
end debug;
end Debugger;



encapsulated package Main

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

public function main
"function: main
  This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
  start the translation."
  input list<String> inStringLst;
  protected
  list<OMCCTypes.Token> tokens;
  Absynrml.Program rmlast;
  Absyn.Program modast;
  type Mcode_MCodeLst = list<Mcode.MCode>;
algorithm
  _ := matchcontinue (inStringLst)
    local
      String ver_str,errstr,filename,grammar,ast,unparsed,fileextension;
      list<String> args_1,args,chars;
      String s,str;
      Boolean runparser,result;
      Real tp,tl,tt;
    case args as _::_
      equation
        {filename,grammar} = Flags.new(args);
        runparser = match grammar
          case "Modelica" then true;
          case "ModelicaLexer" then false;
        else equation print("Unknown grammar:" + grammar + "\n"); then fail();
        end match;
        false=(0==stringLength(filename));
        print("Parsing Modelica with file " + filename + "\n");
        System.realtimeTick(1);
        // call the lexer
        print("starting lexer\n");
        tokens = LexerModelica.scan(filename);
        //print(OMCCTypes.printTokens(tokens,""));
        print("Tokens processed:" + intString(listLength(tokens)) + ", time: " + realString(System.realtimeTock(1)*1000) + "ms\n");
        System.realtimeTick(1);
        // call the parser
        if runparser then
          print("starting parser\n");
          (result,ParseCodeModelica.PROGRAM(rmlast)) = ParserModelica.parse(tokens,filename);
          print("Parser done in time: " + realString(System.realtimeTock(1)*1000) + "ms\n");
          else
            result = true;
        end if;
          // call the translator
          modast=Translate.transform(rmlast,filename);

          // unparse the AST to ".mo" file
          fileextension =System.stringReplace(filename,".rml",".mo");
          System.writeFile(fileextension,Dump.unparseStr(modast,true));

          if (result) then
            print("SUCCEED\n");
            else
              fail();
          end if;
          then ();

          case {}
            equation
              print("no args");
              printUsage();
            then ();

          case _
            equation
              print("\n**********Error*************");
              print("\n" +Error.printMessagesStr());
              printUsage();
            then fail();
  end matchcontinue;
end main;


public function printUsage
  protected
  Integer n;
  List<String> strs;
algorithm
  print("\nOMCCp (OpenModelica compiler-compiler Parser generator) Lexer and Parser Generator-2014\n\n");
end printUsage;

end Main;

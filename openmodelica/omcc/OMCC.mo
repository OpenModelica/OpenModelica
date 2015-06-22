class OMCC

import Util;
import RTOpts;
import System;
import Absyn;
import LexerGenerator;
import ParserGenerator;
constant String copyright = "OMCCp v0.10.0 OpenModelica lexer and parser generator (2014)";

public function main
"function: main
This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
start the translation."
  input list<String> inStringLst;
algorithm

  _ := matchcontinue (inStringLst)
    local
      String ver_str,errstr,filename,parser,ast;
      list<String> args_1,args,chars;
      String s,str,omhome,oldpath,newpath;
      Boolean result;
    case  "--lexer-only" :: args
      equation
        {parser} = Flags.new(args);
        print("Generating FLEX grammar file lexer" + parser +".c ...\n");
        0 = System.systemCall("flex -t -l lexer" + parser +".l > lexer" + parser +".c");
        str = LexerGenerator.genLexer("lexer"+ parser +".c", "lexer"+ parser +".l", parser);
        print("Result:" + str + "\n");
        print("\nGenerated files:\n" + sum("  " + s + "Modelica.mo\n" for s in {"LexerCode","Lexer","LexTable"}));
      then ();
    case args as _::_
      equation
        {parser} = Flags.new(args);
        print("Generating FLEX grammar file lexer" + parser +".c ...\n");
        0 = System.systemCall("flex -t -l lexer" + parser +".l > lexer" + parser +".c");
        print("Generating BISON grammar file parser" + parser +".c ...\n");
        0 = System.systemCall("bison parser" + parser +".y --output=parser" + parser +".c");
        str = LexerGenerator.genLexer("lexer"+ parser +".c", "lexer"+ parser +".l", parser);
        print("Result:" + str + "\n");
        str = ParserGenerator.genParser("parser"+ parser +".c","parser"+ parser +".y",parser);
        print("Result:" + str + "\n");

        print("\n 9 Files Generated for the language grammar:" + parser);
      then ();
    case _
      equation
        print("\n**********Error*************");
        printUsage();
      then fail();
  end matchcontinue;
end main;

public function printUsage
algorithm
  print("\n" + copyright + "\n");
end printUsage;

end OMCC;

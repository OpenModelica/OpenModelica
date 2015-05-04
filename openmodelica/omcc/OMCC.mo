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
          printUsage();
        then ();
      case _
        equation
          print("\n**********Error*************");
          printUsage();
        then fail();
    end matchcontinue;
  end main;

  public function printUsage
    protected
    Integer n;
    List<String> strs;
    Absyn.Program prog;
    Absyn.Class mClass;
    Absyn.ClassDef mCDef;
  algorithm
    /* mCDef := Absyn.OVERLOAD({Absyn.IDENT("fname")},NONE());
     mClass := Absyn.CLASS("ctest",false,false,false,Absyn.R_CLASS(),mCDef);
     prog := Absyn.PROGRAM({mClass},Absyn.WITHIN(Absyn.IDENT("test")),Absyn.TIMESTAMP(System.getCurrentTime(),System.getCurrentTime()));
     printAny(prog); */
    print("\n" + copyright +& "\n");
  end printUsage;

  protected function readSettings
"function: readSettings
 author: x02lucpo
 Checks if 'settings.mos' exist and uses handleCommand with runScript(...) to execute it.
 Checks if '-s <file>.mos' has been
 returns Interactive.InteractiveSymbolTable which is used in the rest of the loop"
    input list<String> inStringLst;
    output String str;
  algorithm
    str:=
    matchcontinue (inStringLst)
      local
        list<String> args;
      case (args)
        equation
          outSymbolTable = Interactive.emptySymboltable;
          "" = Util.flagValue("-s",args);
          //         this is out-commented because automatically reading settings.mos
          //         can make a system bad
          //         outSymbolTable = readSettingsFile("settings.mos", Interactive.emptySymboltable);
        then
          outSymbolTable;
      case (args)
        equation
          str = Util.flagValue("-s",args);
          str = System.trim(str," \"");
          outSymbolTable = readSettingsFile(str, Interactive.emptySymboltable);
        then
          outSymbolTable;
    end matchcontinue;
  end readSettings;



end OMCC;

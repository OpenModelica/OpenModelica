encapsulated package LexerTest

import LexerModelica;
import ParserModelica;
import ParseCodeModelica;

import Absyn;
import Util;
import RTOpts;
import System;
import Types;
import OMCCTypes;
import Flags;
import Error;

public function main
"function: main
  This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
  start the translation."
  input list<String> inStringLst;
protected
  list<OMCCTypes.Token> tokens;
  type Mcode_MCodeLst = list<Mcode.MCode>;
algorithm
   _ := matchcontinue (inStringLst)
  local
      String ver_str,errstr,filename,grammar,ast,unparsed;
      list<String> args_1,args,chars;
      String s,str;
      Boolean runparser,result;
      Real tp,tl,tt;
     case args as _::_
      equation
        {filename} = Flags.new(args);
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
        result = true;
        // printing  the AST

        if (result) then
          print("SUCCEED\n");
        else
          fail();
        end if;
      then ();

    case {}
      equation
        print("no args");
     then ();

    case _
      equation
        print("\n**********Error*************");
        print("\n" +Error.printMessagesStr());
     then fail();
   end matchcontinue;
end main;

end LexerTest;

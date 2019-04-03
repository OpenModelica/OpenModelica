encapsulated package Main

import LexerModelica;
import ParserModelica;
import ParseCodeModelica;
import Translate;
import Absyn;
import AbsynMat;
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
  output Boolean outresult;
  protected
  list<OMCCTypes.Token> tokens;
  AbsynMat.AstStart matstart;
  Absyn.Program modast;
  Absyn.Program modast1;
  type Mcode_MCodeLst = list<Mcode.MCode>;
algorithm
  outresult:= matchcontinue (inStringLst)
    local
      String ver_str,errstr,filename,grammar,ast,unparsed,fileextension;
      list<String> args_1,args,chars;
      String s,str;
      Boolean runparser,result,c;
      Real tp,tl,tt,r1;
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
          (result,ParseCodeModelica.ASTSTART(matstart)) = ParserModelica.parse(tokens,filename);
          print("Parser done in time: " + realString(System.realtimeTock(1)*1000) + "ms\n");
        end if;
        
          // call the translator
        if result then         
          modast=Translate.transform(matstart);         
          //print("\n ********* Final Abstract Syntax tree ************ \n");
          //print(anyString(modast));  
                 
          unparsed=Dump.unparseStr(modast,false);
          
          print("\n Translated Modelica Code \n"); 
          print("\n");
          print(unparsed);
          print("\n");
          result=true;
        else
          print ("\n Failed");
          result=false;
        end if;
      
        then 
          result;
              
         /* if (result) then
            print("SUCCEED\n");
            else
              fail();
          end if;
          then (); */

    case {}
      equation
        print("no args");
        printUsage();
        result=false;
      then 
        result;

    case _
      equation
         print("\n**********Error*************");
         print("\n" +Error.printMessagesStr());
         printUsage();
         result=false;
      then 
        result; 
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

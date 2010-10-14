package TplMain "
This is the main module of Susan language.
It only calls the other parts of the compiler
and contains some tests for basic parts of Susan. 
"

protected import Debug;
protected import Util;
protected import Print;
protected import System;

public import Tpl;
public import TplParser;
public import TplAbsyn;
public import TplCodegen;

protected
constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {}); 

public function main
  input String inFile;

algorithm  
  _ := matchcontinue inFile
    local
      String file, strErrBuf;
      
    case ( "SusanTest.tpl" )
      equation
        tplMainTest("a");
      then ();
    
    case ( file )
      equation
        failure("SusanTest.tpl" = file);
        translateFile(file);
        strErrBuf = Print.getErrorString();
        strErrBuf = Util.if_(strErrBuf ==& "","",
          "### Error Buffer ###\n"+&strErrBuf+&"\n### End of Error Buffer ###\n");
        print(strErrBuf);         
      then ();
   
  end matchcontinue; 
end main;


public function translateFile
  input String inFile;

algorithm  
  _ := matchcontinue inFile
    local
      String file, destFile, src, res;
      list<String> chars, lst;
      Tpl.Text txt;
      TplAbsyn.TemplPackage tplPackage;
      TplAbsyn.MMPackage mmPckg;
    
    case ( file )
      equation
        print("\nProcessing file '" +& file +& "'\n");
        
        destFile = System.stringReplace(file +& "*", ".tpl*", ".mo");
        false = stringEqual(file, destFile);
        
        //print(destFile);
        
        tplPackage = TplParser.templPackageFromFile(file);
        
        mmPckg = TplAbsyn.transformAST(tplPackage);
        txt = emptyTxt;
        txt = TplCodegen.mmPackage(txt, mmPckg);
        //res = "/* generated on " +& System.getCurrentTimeStr() +& "*/\n" +& Tpl.textString(txt);
        res = Tpl.textString(txt);
        print("\nWriting result to file '" +& destFile +& "'\n");
        
        System.writeFile(destFile, res);
        //print("\nReamining characters:\n" +& stringCharListString(chars) +& "\n<<"); 
      then ();
   
    case (file)
      equation
        print("\n### translation of file '"+& file +& "' failed!  ###\n" );
        print("### Error Buffer ###\n");
        print(Print.getErrorString());
        print("\n### End of Error Buffer ###\n");
        Print.clearErrorBuf();
      then fail();
                   
  end matchcontinue; 
end translateFile;


// ********** Tests **************** 



public function testStringEquality
  input String inStringReturned;
  input String inStringShouldBe;
  input Boolean inPrintResult;
  input Boolean inPrintErrorBuffer;
  input String inTestLabel;
  input Integer inNotPassedCnt;
  
  output Integer outNotPassedCnt;
algorithm
  outPassed := matchcontinue (inStringReturned, inStringShouldBe, inPrintResult, inPrintErrorBuffer, inTestLabel, inNotPassedCnt)
    local
      // Tpl.Tokens toks, txttoks;
      String strRet, strShouldBe, strLabel, strRes, strErrBuf;
      Boolean printResult, printErrBuf;
      Integer notPassedCnt;
      Tpl.Text txt;
    
    case ( strRet, strShouldBe, printResult, printErrBuf, strLabel, notPassedCnt)
      equation
        true = stringEqual(strRet, strShouldBe);
        print("\n**************************************************\n" +& strLabel);
        
        strRes = Util.if_(printResult, "  returned <<\n" +& strRet +& ">>\n", "\n result not shown \n");
        print(strRes);
        
        strErrBuf = Print.getErrorString();
        strErrBuf = Util.if_(strErrBuf ==& "","",
          Util.if_(printErrBuf, "### Error Buffer ###\n"+&strErrBuf+&"\n### End of Error Buffer ###\n", 
                                "### Error Buffer is NOT empty - not shown ###\n"));
        print(strErrBuf);
        print("*** OK ***\n");
        Print.clearErrorBuf();
      then 
        notPassedCnt;
    
    case ( strRet, strShouldBe, printResult,printErrBuf, strLabel, notPassedCnt)
      equation
        false = stringEqual(strRet, strShouldBe);
        print("\n##################################################\n" 
                +& strLabel );
                
        strRes = Util.if_(printResult,
           "  returned <<\n" +& strRet +& ">>\nshould be <<\n" +& strShouldBe +& ">>\n"
          ,"\n result not shown \n");        
        print(strRes); 
        
        strErrBuf = Print.getErrorString();
        strErrBuf = Util.if_(strErrBuf ==& "","",
          Util.if_(printErrBuf, "### Error Buffer ###\n"+&strErrBuf+&"\n### End of Error Buffer ###\n", 
                                "### Error Buffer is NOT empty - not shown ###\n"));
        print(strErrBuf);
        
        print("### NOT Passed ###\n");
        Print.clearErrorBuf();
      then 
        (notPassedCnt + 1);
        
    //should not ever happen 
    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.tplMainTest failed.\n");
      then 
        fail();
  end matchcontinue;
end testStringEquality;


public function testTranslateTplFile
  input String inFile;
  input Boolean inPrintResult;
  input Boolean inPrintErrorBuffer;
  input Integer inNotPassedCnt;
  
  output Integer outNotPassedCnt;  
algorithm  
  outNotPassedCnt := matchcontinue (inFile, inPrintResult, inPrintErrorBuffer, inNotPassedCnt)
    local
      String file, res, resToBe;
      Boolean printRes, printErrBuf;
      Integer notPassedCnt;
    
    case ( file, printRes, printErrBuf, notPassedCnt)
      equation
        System.writeFile(file +& ".mo", "Test failed.");
        translateFile(file +& ".tpl");
        res = System.stringReplace(System.readFile(file +& ".mo"), intStringChar(13), "");
        resToBe = System.stringReplace(System.readFile(file +& "__testShouldBe.mo"), intStringChar(13), "");
        notPassedCnt = testStringEquality(res,resToBe, printRes, printErrBuf,
                       "translateFile "+& file +& ".tpl", notPassedCnt);
      then notPassedCnt;
    
    //failed
    case ( file, printRes, printErrBuf, notPassedCnt)
      equation
        System.writeFile(file +& ".mo", "Test failed.");
        //failure( translateFile(file +& ".tpl") );
        res = System.stringReplace(System.readFile(file +& ".mo"), intStringChar(13), "");
        resToBe = System.stringReplace(System.readFile(file +& "__testShouldBe.mo"), intStringChar(13), "");
        notPassedCnt = testStringEquality(res,resToBe, printRes, printErrBuf,
                       "translateFile "+& file +& ".tpl", notPassedCnt);
      then notPassedCnt;
                   
  end matchcontinue; 
end testTranslateTplFile;



public function tplMainTest
  input String inFile;
algorithm
  
  _ := matchcontinue inFile
    local
      //Tpl.Tokens toks, txttoks;
      String file, str, strOut, ident, cval;
      list<String> chars; 
      Tpl.Text txt;
      Boolean tequal;
      TplAbsyn.TemplPackage tplPackage;
      TplAbsyn.MMPackage mmPckg;
      TplAbsyn.PathIdent pid;
      TplAbsyn.TypeSignature ts;
      list<TplAbsyn.ASTDef> astDefs;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      TplAbsyn.Expression exp;
      Tpl.StringToken tok;
      Real tstart,t1,t2;
      Integer lnum,colnum, llen, notPassedCnt;
    case ( "a" )
      equation
        notPassedCnt = 0;
        Print.clearErrorBuf();
        print("\n A Test:\n" );
        tstart = clock();
        
        //*************
        txt = Tpl.writeStr(emptyTxt, "Ahoj Susan");
        //txt = newLine(txt);
        txt = Tpl.pushBlock(txt,Tpl.BT_ANCHOR(0));
        txt = Tpl.writeStr(txt, "Ahoj Susan");
        txt = Tpl.newLine(txt);
        txt = Tpl.writeStr(txt, "Ahoj Susan");
        txt = Tpl.popBlock(txt);
        str = Tpl.textString(txt);
        notPassedCnt = testStringEquality(str, 
"Ahoj SusanAhoj Susan
          Ahoj Susan", true, true, "Anchor", notPassedCnt);
        
        //*************
        txt = emptyTxt;
        txt = TplCodegen.pathIdent(txt, TplAbsyn.IDENT("Susan"));
        str = Tpl.textString(txt);
        notPassedCnt = testStringEquality(str,  
"Susan", true, true, "PathIdent IDENT", notPassedCnt);
        
        //*************
        txt = emptyTxt;
        txt = TplCodegen.pathIdent(txt, TplAbsyn.PATH_IDENT("Hej", TplAbsyn.IDENT("Susan")));
        str = Tpl.textString(txt);
        notPassedCnt = testStringEquality(str,  
"Hej.Susan", true, true, "PathIdent PATH_IDENT", notPassedCnt);

        //*************
        txt = emptyTxt;
        txt = TplCodegen.typedIdents(txt, { 
                ("Hej", TplAbsyn.TEXT_TYPE()), 
                ("Susan", TplAbsyn.LIST_TYPE(TplAbsyn.NAMED_TYPE(TplAbsyn.PATH_IDENT("Pa",TplAbsyn.IDENT("Li")))))} );
        str = Tpl.textString(txt);
        notPassedCnt = testStringEquality(str,  
"Tpl.Text Hej;
list<Pa.Li> Susan;", true, true, "typedIdents", notPassedCnt);

        //*************
        txt = emptyTxt;
        txt = TplCodegen.typedIdentsEx(txt, { 
                ("Hej", TplAbsyn.TEXT_TYPE()), 
                ("Susan", TplAbsyn.NAMED_TYPE(TplAbsyn.PATH_IDENT("Pa",TplAbsyn.IDENT("Li"))))},
                "input","in" );
        str = Tpl.textString(txt);
        notPassedCnt = testStringEquality(str,  
"input Tpl.Text inHej;
input Pa.Li inSusan;", true, true, "typedIdentsEx", notPassedCnt);

        //*************
        txt = emptyTxt;
        txt = TplCodegen.mmPackage(txt, 
          TplAbsyn.MM_PACKAGE(
            TplAbsyn.IDENT("Susan"),
            {
              TplAbsyn.MM_IMPORT(true, TplAbsyn.PATH_IDENT("Pa",TplAbsyn.PATH_IDENT("Li",TplAbsyn.IDENT("Ko"))))
              ,TplAbsyn.MM_STR_TOKEN_DECL(true, "strTokConst", Tpl.ST_STRING_LIST({"Susan","is","beautiful\n"},true))
              ,TplAbsyn.MM_LITERAL_DECL(false, "c_literalValueConst", "123", TplAbsyn.INTEGER_TYPE())
              ,TplAbsyn.MM_FUN(true,"MuchFun",
                { ("txt",TplAbsyn.TEXT_TYPE()), ("laughLevel",TplAbsyn.INTEGER_TYPE()), ("jokes",TplAbsyn.LIST_TYPE(TplAbsyn.STRING_TYPE()))  },
                { ("txt",TplAbsyn.TEXT_TYPE()) },
                { ("txt",TplAbsyn.TEXT_TYPE()), ("laughLevel",TplAbsyn.INTEGER_TYPE()), ("jokes",TplAbsyn.LIST_TYPE(TplAbsyn.STRING_TYPE()))  },
                {
                  TplAbsyn.MM_ASSIGN({"out_txt"}, 
                     TplAbsyn.MM_FN_CALL(TplAbsyn.PATH_IDENT("Tpl", TplAbsyn.IDENT("writeStr")), 
                                 { TplAbsyn.MM_IDENT(TplAbsyn.IDENT("txt")),
                                  TplAbsyn.MM_STRING("Susan")
                                 } )),
                  TplAbsyn.MM_ASSIGN({"out_txt"}, 
                     TplAbsyn.MM_FN_CALL(TplAbsyn.PATH_IDENT("Tpl", TplAbsyn.IDENT("writeTok")), 
                                 { TplAbsyn.MM_IDENT(TplAbsyn.IDENT("out_txt")),
                                   TplAbsyn.MM_STR_TOKEN(Tpl.ST_LINE("Susan is cosmic!\n"))
                                 } ))               
                },
                NONE
                 
               )
              ,TplAbsyn.MM_FUN(true,"MoreFun",
                { ("txt",TplAbsyn.TEXT_TYPE()), 
                  ("v_laughLevel",TplAbsyn.OPTION_TYPE(TplAbsyn.STRING_TYPE())), 
                  ("v_jokes",TplAbsyn.LIST_TYPE(TplAbsyn.STRING_TYPE()))  },
                { ("txt",TplAbsyn.TEXT_TYPE()) },
                { ("txt",TplAbsyn.TEXT_TYPE()) },
                {
                  TplAbsyn.MM_MATCH({
                   ({ TplAbsyn.BIND_MATCH("txt"),
                      TplAbsyn.SOME_MATCH(TplAbsyn.BIND_AS_MATCH("v_hej",TplAbsyn.STRING_MATCH("Hej"))),
                      TplAbsyn.BIND_MATCH("v_jokes")
                    },
                    { ("v_hej",TplAbsyn.STRING_TYPE()),
                      ("v_jokes",TplAbsyn.LIST_TYPE(TplAbsyn.STRING_TYPE()))
                    },
                    { 
                     TplAbsyn.MM_ASSIGN({"txt"}, 
                       TplAbsyn.MM_FN_CALL(TplAbsyn.PATH_IDENT("Tpl", TplAbsyn.IDENT("writeStr")), 
                                 { TplAbsyn.MM_IDENT(TplAbsyn.IDENT("txt")),
                                   TplAbsyn.MM_IDENT(TplAbsyn.IDENT("v_hej"))
                                 } ))                                  
                    }),
                    ({ TplAbsyn.BIND_MATCH("txt"),
                      TplAbsyn.SOME_MATCH(TplAbsyn.BIND_MATCH("v_hej")),
                      TplAbsyn.REST_MATCH()
                    },
                    { ("v_hej",TplAbsyn.STRING_TYPE())
                    },
                    { 
                     TplAbsyn.MM_ASSIGN({"txt"}, 
                       TplAbsyn.MM_FN_CALL(TplAbsyn.PATH_IDENT("Tpl", TplAbsyn.IDENT("writeStr")), 
                                 { TplAbsyn.MM_IDENT(TplAbsyn.IDENT("txt")),
                                   TplAbsyn.MM_STRING("Not hej:")
                                 } )),
                     TplAbsyn.MM_ASSIGN({"txt"},
                       TplAbsyn.MM_FN_CALL(TplAbsyn.PATH_IDENT("Tpl", TplAbsyn.IDENT("writeStr")), 
                                 { TplAbsyn.MM_IDENT(TplAbsyn.IDENT("txt")),
                                   TplAbsyn.MM_IDENT(TplAbsyn.IDENT("v_hej"))
                                 } ))                                  
                    }),
                    ({ TplAbsyn.BIND_MATCH("txt"),
                      TplAbsyn.NONE_MATCH(),
                      TplAbsyn.REST_MATCH()
                    },
                    { },
                    { 
                     TplAbsyn.MM_ASSIGN({"txt"}, 
                       TplAbsyn.MM_FN_CALL(TplAbsyn.PATH_IDENT("Tpl", TplAbsyn.IDENT("writeStr")), 
                                 { TplAbsyn.MM_IDENT(TplAbsyn.IDENT("txt")),
                                   TplAbsyn.MM_STRING("NONE at all")
                                 } ))                                  
                    })
                  })
                },
                NONE
               )
            }
          
          ) 
        );
        str = Tpl.textString(txt);
        notPassedCnt = testStringEquality(str,  
"package Susan

protected constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {});

public import Tpl;

public import Pa.Li.Ko;

public constant Tpl.StringToken strTokConst = Tpl.ST_STRING_LIST({
                                                  \"Susan\",
                                                  \"is\",
                                                  \"beautiful\\n\"
                                              }, true);

protected constant Integer c_literalValueConst = 123;

public function MuchFun
  input Tpl.Text txt;
  input Integer laughLevel;
  input list<String> jokes;

  output Tpl.Text out_txt;
protected
  Tpl.Text txt;
  Integer laughLevel;
  list<String> jokes;
algorithm
  out_txt := Tpl.writeStr(txt, \"Susan\");
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(\"Susan is cosmic!\\n\"));
end MuchFun;

public function MoreFun
  input Tpl.Text in_txt;
  input Option<String> in_v_laughLevel;
  input list<String> in_v_jokes;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_v_laughLevel, in_v_jokes)
    local
      Tpl.Text txt;

    case ( txt,
           SOME((v_hej as \"Hej\")),
           v_jokes )
      local
        String v_hej;
        list<String> v_jokes;
      equation
        txt = Tpl.writeStr(txt, v_hej);
      then txt;

    case ( txt,
           SOME(v_hej),
           _ )
      local
        String v_hej;
      equation
        txt = Tpl.writeStr(txt, \"Not hej:\");
        txt = Tpl.writeStr(txt, v_hej);
      then txt;

    case ( txt,
           NONE,
           _ )
      equation
        txt = Tpl.writeStr(txt, \"NONE at all\");
      then txt;
  end matchcontinue;
end MoreFun;

end Susan;", false, false, "mmPackage", notPassedCnt);
        
        
       
        //*************
  /*
  type Ident = String;
	type TypedIdents = list<tuple<Ident, PathIdent>>;
	
	uniontype PathIdent
	  record IDENT
	    Ident ident;    
	  end IDENT;
	  
	  record PATH_IDENT
	    Ident ident;
	    PathIdent path;
	  end PATH_IDENT;
	end PathIdent;

pathIdent(PathIdent) <>= 
  case IDENT      then ident
  case PATH_IDENT then ident &'.'& pathIdent(path) //"<ident>.<pathIdent(path)>"
	
typedIdents(TypedIdents decls) <>= 
<decls of (id,pid) : 
   "<pathIdent(pid)> <id>;" 
   \n
>
	
	*/
        tplPackage = TplAbsyn.TEMPL_PACKAGE(
           TplAbsyn.IDENT("Susan"), 
           { TplAbsyn.AST_DEF(TplAbsyn.IDENT("TplAbsyn"), true, 
             { ("Ident", TplAbsyn.TI_ALIAS_TYPE(TplAbsyn.STRING_TYPE())),
               ("TypedIdents", TplAbsyn.TI_ALIAS_TYPE(TplAbsyn.LIST_TYPE(TplAbsyn.TUPLE_TYPE({TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("Ident")), TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("PathIdent"))})))),
               ("PathIdent", TplAbsyn.TI_UNION_TYPE({
                               ("IDENT",{("ident", TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("Ident")))}),
                               ("PATH_IDENT",{ ("ident", TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("Ident"))),
                                               ("path", TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("PathIdent")))  })
                             }) )
             } )
           },
           { ("pathIdent", TplAbsyn.TEMPLATE_DEF({("it",TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("PathIdent")))}, "", "",
                             TplAbsyn.MATCH(TplAbsyn.BOUND_VALUE(TplAbsyn.IDENT("it")),
                               { (TplAbsyn.RECORD_MATCH(TplAbsyn.IDENT("IDENT"),{}), TplAbsyn.BOUND_VALUE(TplAbsyn.IDENT("ident"))),
                                 (TplAbsyn.RECORD_MATCH(TplAbsyn.IDENT("PATH_IDENT"),{}), 
                                  TplAbsyn.TEMPLATE({ 
                                    TplAbsyn.BOUND_VALUE(TplAbsyn.IDENT("ident")),
                                    TplAbsyn.STR_TOKEN(Tpl.ST_STRING(".")),
                                    TplAbsyn.FUN_CALL(TplAbsyn.IDENT("pathIdent"), {TplAbsyn.BOUND_VALUE(TplAbsyn.IDENT("path"))})
                                   },"\"","\"") )
                               }
                             ) 
                           )
             ),
             ("typedIdents", TplAbsyn.TEMPLATE_DEF({("decls",TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("TypedIdents")))}, "", "",
                             TplAbsyn.ESCAPED(
                               TplAbsyn.MAP(
                                 TplAbsyn.BOUND_VALUE(TplAbsyn.IDENT("decls")),
                                 TplAbsyn.TUPLE_MATCH({TplAbsyn.BIND_MATCH("id"), TplAbsyn.BIND_MATCH("pid")}),
                                 TplAbsyn.TEMPLATE({ 
                                    TplAbsyn.FUN_CALL(TplAbsyn.IDENT("pathIdent"), {TplAbsyn.BOUND_VALUE(TplAbsyn.IDENT("pid"))}),
                                    TplAbsyn.STR_TOKEN(Tpl.ST_STRING(" ")),
                                    TplAbsyn.BOUND_VALUE(TplAbsyn.IDENT("id")),
                                    TplAbsyn.STR_TOKEN(Tpl.ST_STRING(";"))                                    
                                   },"\"","\""
                                 )
                               ),
                               { ("separator", SOME(TplAbsyn.STR_TOKEN(Tpl.ST_NEW_LINE())))
                               }
                             ) 
                           )
             )
             
           }
           );
        mmPckg = TplAbsyn.transformAST(tplPackage);
        txt = emptyTxt;
        txt = TplCodegen.mmPackage(txt, mmPckg);
        str = Tpl.textString(txt);
        notPassedCnt = testStringEquality(str,  
"package Susan

protected constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {});

public import Tpl;

public import TplAbsyn;

public function pathIdent
  input Tpl.Text in_txt;
  input TplAbsyn.PathIdent in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           TplAbsyn.IDENT(ident = i_ident) )
      local
        TplAbsyn.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           TplAbsyn.PATH_IDENT(ident = i_ident, path = i_path) )
      local
        TplAbsyn.PathIdent i_path;
        TplAbsyn.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(\".\"));
        txt = pathIdent(txt, i_path);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end pathIdent;

protected function lm_2
  input Tpl.Text in_txt;
  input TplAbsyn.TypedIdents in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_id, i_pid) :: rest )
      local
        TplAbsyn.TypedIdents rest;
        TplAbsyn.PathIdent i_pid;
        TplAbsyn.Ident i_id;
      equation
        txt = pathIdent(txt, i_pid);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(\" \"));
        txt = Tpl.writeStr(txt, i_id);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(\";\"));
        txt = Tpl.nextIter(txt);
        txt = lm_2(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        TplAbsyn.TypedIdents rest;
      equation
        txt = lm_2(txt, rest);
      then txt;
  end matchcontinue;
end lm_2;

public function typedIdents
  input Tpl.Text txt;
  input TplAbsyn.TypedIdents i_decls;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_2(out_txt, i_decls);
  out_txt := Tpl.popIter(out_txt);
end typedIdents;

end Susan;", false, false, "transformAST - pathIdent() + typedIdents()", notPassedCnt);

        //*************
        str = "// Hej Susan
/*this is another dance with Susan */  
/* event I will /*nest*/ into */ //and still comment
			Susan lives!";
        chars = stringListStringChar( str );
        
        (chars, _) = TplParser.interleave(chars, TplParser.makeStartLineInfo(chars, "in memory test"));
        strOut = stringCharListString(chars);        
        notPassedCnt = testStringEquality(strOut,  
           "Susan lives!", true, true, "TplParser.interleave \n\""+& str +&"\"\n", notPassedCnt);

        //*************
        str = "(Susan)";
        chars = stringListStringChar( str );
        
        TplParser.afterKeyword(chars); //not fail
        strOut = stringCharListString(chars);        
        notPassedCnt = testStringEquality(strOut,  
           "(Susan)", true, true, "TplParser.afterKeyword \n\""+& str +&"\"\n", notPassedCnt);
        
        //*************
        str = "Susan2:)";
        chars = stringListStringChar( str );
        
        (chars, ident) = TplParser.identifier(chars);
        strOut = "*" +& ident +& "*" +& stringCharListString(chars);        
        notPassedCnt = testStringEquality(strOut,  
           "*Susan2*:)", true, true, "TplParser.identifier \n\""+& str +&"\"\n", notPassedCnt);
        
        //*************
        str = "Susan:)";
        chars = stringListStringChar( str );
        
        (chars,_, pid) = TplParser.pathIdent(chars, TplParser.makeStartLineInfo(chars, "in memory test"));
        txt = emptyTxt;
        txt = TplCodegen.pathIdent(txt, pid);
        ident = Tpl.textString(txt);
        strOut = "*" +& ident +& "*" +& stringCharListString(chars);        
        notPassedCnt = testStringEquality(strOut,  
           "*Susan*:)", true, true, "TplParser.pathIdent \n\""+& str +&"\"\n", notPassedCnt);
        
        //*************
        str = "Susan./*comment*/ Susan2 . tpl3_h4:)";
        chars = stringListStringChar( str );
        
        (chars,_, pid) = TplParser.pathIdent(chars, TplParser.makeStartLineInfo(chars, "in memory test"));
        txt = emptyTxt;
        txt = TplCodegen.pathIdent(txt, pid);
        ident = Tpl.textString(txt);
        strOut = "*" +& ident +& "*" +& stringCharListString(chars);        
        notPassedCnt = testStringEquality(strOut,  
           "*Susan.Susan2.tpl3_h4*:)", true, true, "TplParser.pathIdent \n\""+& str +&"\"\n", notPassedCnt);
        
        //*************
        str = "Tpl.Susan:)";
        chars = stringListStringChar( str );
        
        (chars,_, ts) = TplParser.typeSig(chars, TplParser.makeStartLineInfo(chars, "in memory test"));
        tequal = Util.equal(ts, TplAbsyn.NAMED_TYPE(TplAbsyn.PATH_IDENT("Tpl", TplAbsyn.IDENT("Susan"))));
        txt = emptyTxt;
        txt = TplCodegen.typeSig(txt, ts);
        ident = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +& "*" +& ident +& "*" +& stringCharListString(chars);        
        notPassedCnt = testStringEquality(strOut,  
           "true*Tpl.Susan*:)", true, true, "TplParser.typeSig \n\""+& str +&"\"\n", notPassedCnt);
        
        //*************
        str = "list< tuple<Hej.Susan,list <String>,Option< /*uáá*/Integer>> >:)";
        chars = stringListStringChar( str );
        
        (chars,_, ts) = TplParser.typeSig(chars, TplParser.makeStartLineInfo(chars, "in memory test"));
        tequal = Util.equal(ts, TplAbsyn.LIST_TYPE(TplAbsyn.TUPLE_TYPE({ 
                    TplAbsyn.NAMED_TYPE(TplAbsyn.PATH_IDENT("Hej", TplAbsyn.IDENT("Susan"))),
                    TplAbsyn.LIST_TYPE(TplAbsyn.STRING_TYPE()),
                    TplAbsyn.OPTION_TYPE(TplAbsyn.INTEGER_TYPE())})));
        txt = emptyTxt;
        txt = TplCodegen.typeSig(txt, ts);
        ident = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +&"*" +& ident +& "*" +& stringCharListString(chars);        
        notPassedCnt = testStringEquality(strOut,  
           "true*list<tuple<Hej.Susan, list<String>, Option<Integer>>>*:)", true, true, "TplParser.typeSig \n\""+& str +&"\"\n", notPassedCnt);
        
        //*************
        str = "
spackage Susan
	package TplAbsyn
		type Ident = String;
		type TypedIdents = list<tuple<Ident, PathIdent>>;
		
		uniontype PathIdent
			record IDENT
			  Ident ident;    
			end IDENT;
			
			record PATH_IDENT
			  Ident ident;
			  PathIdent path;
			end PATH_IDENT;
		end PathIdent;
	end TplAbsyn;
end Susan;:)";
        chars = stringListStringChar( str );
        
        (chars,_, TplAbsyn.TEMPL_PACKAGE(pid, astDefs, {})) = TplParser.templPackage(chars, TplParser.makeStartLineInfo(chars, "in memory test"));
        /*{ TplAbsyn.AST_DEF(TplAbsyn.IDENT("TplAbsyn"), true, types) } = astDefs;
        (("Ident", TplAbsyn.TI_ALIAS_TYPE(TplAbsyn.STRING_TYPE())) 
          :: ("TypedIdents", TplAbsyn.TI_ALIAS_TYPE(TplAbsyn.LIST_TYPE(TplAbsyn.TUPLE_TYPE({TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("Ident")), TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("PathIdent"))}))))
          :: ("PathIdent", TplAbsyn.TI_UNION_TYPE({
                               ("IDENT",{("ident", TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("Ident")))}),
                               ("PATH_IDENT",{ ("ident", TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("Ident"))),
                                               ("path", TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("PathIdent")))  })
                             }) )
          ::_) = types;*/
        
        tequal = Util.equal(astDefs, 
           { TplAbsyn.AST_DEF(TplAbsyn.IDENT("TplAbsyn"), true, 
             { ("Ident", TplAbsyn.TI_ALIAS_TYPE(TplAbsyn.STRING_TYPE())),
               ("TypedIdents", TplAbsyn.TI_ALIAS_TYPE(TplAbsyn.LIST_TYPE(TplAbsyn.TUPLE_TYPE({TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("Ident")), TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("PathIdent"))})))),
               ("PathIdent", TplAbsyn.TI_UNION_TYPE({
                               ("IDENT",{("ident", TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("Ident")))}),
                               ("PATH_IDENT",{ ("ident", TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("Ident"))),
                                               ("path", TplAbsyn.NAMED_TYPE(TplAbsyn.IDENT("PathIdent")))  })
                             }) )
             } )
           });
        
        txt = emptyTxt;
        txt = TplCodegen.pathIdent(txt, pid);
        ident = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +&"*" +& ident +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*Susan*:)", true, true, "TplParser.templPackage - absyn - type Ident, TypedIdents, PathIdent \n", notPassedCnt);   
        
        
        //*************
        str = "
spackage Susan
package builtin
	function stringListStringChar
	  input String inString;
	  output list<String> outStringList;
	end stringListStringChar;
end builtin;
end Susan;:)";
        chars = stringListStringChar( str );
        
        (chars,_, tplPackage) = TplParser.templPackage(chars, TplParser.makeStartLineInfo(chars, "in memory test"));
        
        tequal = Util.equal(tplPackage,
          TplAbsyn.TEMPL_PACKAGE(
            TplAbsyn.IDENT("Susan"), 
            { TplAbsyn.AST_DEF(TplAbsyn.IDENT("builtin"), true, 
             { ("stringListStringChar", 
                  TplAbsyn.TI_FUN_TYPE(
                     { ("inString", TplAbsyn.STRING_TYPE()) },
                     { ("outStringList", TplAbsyn.LIST_TYPE(TplAbsyn.STRING_TYPE())) },
                     {} )
               )
             } )
           }, 
           {}));
        
        txt = emptyTxt;
        txt = TplCodegen.pathIdent(txt, pid);
        ident = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +&"*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*:)", true, true, "TplParser.templPackage - function stringListStringChar\n", notPassedCnt);   
        
        
        //*************
        str = "
spackage Susan
package builtin
	function stringListStringChar
	  input String inString;
	  output list<String> outStringList;
	end stringListStringChar;
end builtin;


protected package Tpl
	uniontype StringToken
	  record ST_NEW_LINE \"Always outputs the new-line char.\"  end ST_NEW_LINE;

	  record ST_STRING \"A string without new-lines in it.\"
	    String value;
	  end ST_STRING;

	  record ST_LINE \"A (non-empty) string with new-line at the end.\"
	    String line;
	  end ST_LINE;
  
	  record ST_STRING_LIST \"Every string in the list can have a new-line at its end (but does not have to).\"
	    list<String> strList;
	    Boolean lastHasNewLine \"True when the last string in the list has new-line at the end.\"; 
	  end ST_STRING_LIST;
	end StringToken;
end Tpl;


package TplAbsyn
	type Ident = String;
	type TypedIdents = list<tuple<Ident, TypeSignature>>;
	type StringToken = Tpl.StringToken;
	
	uniontype PathIdent
	  record IDENT
	    Ident ident;    
	  end IDENT;
	  
	  record PATH_IDENT
	    Ident ident;
	    PathIdent path;
	  end PATH_IDENT;
	end PathIdent;
	
	uniontype TypeSignature
	  record LIST_TYPE
	    TypeSignature ofType;
	  end LIST_TYPE;
	  
	  record ARRAY_TYPE  // one-dimensional arrays --> with only (safe) list behaviour
	    TypeSignature ofType;
	  end ARRAY_TYPE;
	  
	  record OPTION_TYPE
	    TypeSignature ofType;
	  end OPTION_TYPE;
	  
	  record TUPLE_TYPE
	    list<TypeSignature> ofTypes;
	  end TUPLE_TYPE;
	  
	  record NAMED_TYPE \"key/path to a TypeInfo list from an AST definition\"
	    PathIdent name;
	  end NAMED_TYPE;
	  
	  record STRING_TYPE  end STRING_TYPE;
	  record TEXT_TYPE    end TEXT_TYPE;
	  record STRING_TOKEN_TYPE \"Used only for internal string constants.\" end STRING_TOKEN_TYPE;
  
	  record INTEGER_TYPE end INTEGER_TYPE;
	  record REAL_TYPE    end REAL_TYPE;
	  record BOOLEAN_TYPE end BOOLEAN_TYPE;
	
	  record UNRESOLVED_TYPE \"Errorneous resolving type. Only used during elaboration phase.\"
	    String reason; 
	  end UNRESOLVED_TYPE;
	end TypeSignature;
		   

	uniontype MatchingExp
	  record BIND_AS_MATCH
	    Ident bindIdent;
	    MatchingExp matchingExp;
	  end BIND_AS_MATCH;
	  
	  record BIND_MATCH 
	    Ident bindIdent;
	  end BIND_MATCH;
	  
	  record RECORD_MATCH
	    PathIdent tagName;
	    list<tuple<Ident, MatchingExp>> fieldMatchings;
	  end RECORD_MATCH;
	  
	  record SOME_MATCH
	    MatchingExp value;
	  end SOME_MATCH;
	  
	  record NONE_MATCH end NONE_MATCH;
	  
	  record TUPLE_MATCH
	    list<MatchingExp> tupleArgs;
	  end TUPLE_MATCH;
	
	  record LIST_MATCH //non-empty list
	    list<MatchingExp> listElts; 
	  end LIST_MATCH;
	  
	  record LIST_CONS_MATCH
	    MatchingExp head;
	    MatchingExp rest;
	  end LIST_CONS_MATCH;
	  
	  record STRING_MATCH
	    String value;
	  end STRING_MATCH;

	  record LITERAL_MATCH
	    String value;
	    TypeSignature litType; // only INTEGER_TYPE, REAL_TYPE or BOOLEAN_TYPE 
	  end LITERAL_MATCH;
	
	  record REST_MATCH end REST_MATCH;
	end MatchingExp;
	
	
	// **** the (core) output AST
	
	uniontype MMPackage
	  record MM_PACKAGE
	    PathIdent name;
	    list<MMDeclaration> mmDeclarations;      
	  end MM_PACKAGE;
	end MMPackage;
	
	type MMMatchCase = tuple<list<MatchingExp>, TypedIdents, list<MMExp>>;
	  
	uniontype MMDeclaration
	  record MM_IMPORT
	    Boolean isPublic;
	    PathIdent packageName;
	  end MM_IMPORT;
	  
	  record MM_STR_TOKEN_DECL
	    Boolean isPublic;
	    Ident name;
	    StringToken value;
	  end MM_STR_TOKEN_DECL;
	  
	  record MM_LITERAL_DECL
	    Boolean isPublic;
	    Ident name;
	    String value;
	    TypeSignature litType;
	  end MM_LITERAL_DECL;
  
	  
	  record MM_FUN
	    Boolean isPublic;
	    Ident name;
	    TypedIdents inArgs; //inTxt inclusive
	    TypedIdents outArgs; // outTxt + extra Texts
	    TypedIdents locals;
	    list<MMExp> statements;    
	  end MM_FUN;      
	end MMDeclaration;
	
	uniontype MMExp
	  record MM_ASSIGN
	    list<Ident> lhsArgs;
	    MMExp rhs;
	  end MM_ASSIGN;
	  
	  record MM_FN_CALL
	    PathIdent fnName;
	    list<MMExp> args;
	  end MM_FN_CALL;
	  
	  record MM_IDENT
	    PathIdent ident;
	  end MM_IDENT;
	  
	  record MM_STR_TOKEN \"constructor of type StringToken\"
	    StringToken value;
	  end MM_STR_TOKEN;
	  
	  record MM_STRING \"to pass a string constant as parameter of type String\" 
	    String value;
	  end MM_STRING;
	  
	  record MM_LITERAL \"to pass a literal constant as parameter of type Integer, Real or Boolean\" 
	    String value;    
	  end MM_LITERAL;
	  
	  record MM_MATCH
	    list<MMMatchCase> matchCases;
	  end MM_MATCH;
	end MMExp;
end TplAbsyn;
end Susan;:)";
        chars = stringListStringChar( str );
        
        (chars,_, tplPackage) = TplParser.templPackage(chars, TplParser.makeStartLineInfo(chars, "in memory test"));
        
        txt = emptyTxt;
        txt = TplCodegen.pathIdent(txt, pid);
        ident = Tpl.textString(txt);
        strOut = "parsed*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "parsed*:)", true, true, "TplParser.templPackage - all types for Susan's backend\n", notPassedCnt);  
        
        //*************
        str = "\"Susan\"~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.STR_TOKEN(Tpl.ST_STRING("Susan")) 
        );
        
        TplAbsyn.STR_TOKEN(tok) = exp;
        txt = emptyTxt;
        txt = Tpl.writeTok(txt, tok);
        strOut = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +& "*" +& strOut +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*Susan*~:)", true, true, "TplParser.expression \n>"+& str +&"<\n", notPassedCnt);   
        
        //*************
        str = "\"\\n\"~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.STR_TOKEN(Tpl.ST_NEW_LINE()) 
        );
        
        TplAbsyn.STR_TOKEN(tok) = exp;
        //Tpl.ST_STRING_LIST({"\n",""},false) = tok;
        txt = emptyTxt;
        txt = Tpl.writeTok(txt, tok);
        strOut = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +& "*" +& strOut +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*\n*~:)", true, true, "TplParser.expression \n>"+& str +&"<\n", notPassedCnt);
 
        //*************
        str = "\",\\n\"~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.STR_TOKEN(Tpl.ST_LINE(",\n")) 
        );
        
        TplAbsyn.STR_TOKEN(tok) = exp;
        //Tpl.ST_STRING_LIST({"\n",""},false) = tok;
        txt = emptyTxt;
        txt = Tpl.writeTok(txt, tok);
        strOut = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +& "*" +& strOut +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*,\n*~:)", true, true, "TplParser.expression \n>"+& str +&"<\n", notPassedCnt);
           
        //*************
        str = "\"Susan
is\\nfantastic!\"~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST({"Susan\n", "is\n", "fantastic!"}, false)) 
        );
        
        TplAbsyn.STR_TOKEN(tok) = exp;
        txt = emptyTxt;
        txt = Tpl.writeTok(txt, tok);
        strOut = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +& "*" +& strOut +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*Susan\nis\nfantastic!*~:)", true, true, "TplParser.expression \n>"+& str +&"<\n", notPassedCnt);   
       
        //*************
        str = "\"
Susan
is\\n new lined!
\"~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST({"\n","Susan\n", "is\n", " new lined!\n"}, true)) 
        );
        
        TplAbsyn.STR_TOKEN(tok) = exp;
        txt = emptyTxt;
        txt = Tpl.writeTok(txt, tok);
        strOut = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +& "*" +& strOut +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*\nSusan\nis\n new lined!\n*~:)", true, true, "TplParser.expression \n>"+& str +&"<\n", notPassedCnt);   
                  
        //*************
        /*
        str = "%(Susan)%~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.STR_TOKEN(Tpl.ST_STRING("Susan")) 
        );
        
        TplAbsyn.STR_TOKEN(tok) = exp;
        txt = emptyTxt;
        txt = Tpl.writeTok(txt, tok);
        strOut = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +& "*" +& strOut +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*Susan*~:)", true, true, "TplParser.expression \n\""+& str +&"\"\n", notPassedCnt);   
        */
        //*************
        /*
        str = "%/
Susan
is\\n verbatim!
/%~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST({"Susan\n", "is\\n verbatim!"}, false)) 
        );
        
        TplAbsyn.STR_TOKEN(tok) = exp;
        txt = emptyTxt;
        txt = Tpl.writeTok(txt, tok);
        strOut = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +& "*" +& strOut +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*Susan\nis\\n verbatim!*~:)", true, true, "TplParser.expression \n\""+& str +&"\"\n", notPassedCnt);   
				*/
        //*************
        str = "1234567~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.LITERAL("1234567", TplAbsyn.INTEGER_TYPE()) 
        );
        
        TplAbsyn.LITERAL(cval,_) = exp;
        strOut = Tpl.booleanString(tequal) +& "*" +& cval +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*1234567*~:)", true, true, "TplParser.expression \n\""+& str +&"\"\n", notPassedCnt);   

        //*************
        str = "- 1234567~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.LITERAL("-1234567", TplAbsyn.INTEGER_TYPE()) 
        );
        
        TplAbsyn.LITERAL(cval,_) = exp;
        strOut = Tpl.booleanString(tequal) +& "*" +& cval +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*-1234567*~:)", true, true, "TplParser.expression \n\""+& str +&"\"\n", notPassedCnt);   
        
        //*************
        str = "- 1234567.0123e-12~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.LITERAL("-1234567.0123e-12", TplAbsyn.REAL_TYPE()) 
        );
        
        TplAbsyn.LITERAL(cval,_) = exp;
        strOut = Tpl.booleanString(tequal) +& "*" +& cval +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*-1234567.0123e-12*~:)", true, true, "TplParser.expression \n\""+& str +&"\"\n", notPassedCnt);   
        
        //*************
        str = ".0123E12~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.LITERAL(".0123E12", TplAbsyn.REAL_TYPE()) 
        );
        
        TplAbsyn.LITERAL(cval,_) = exp;
        strOut = Tpl.booleanString(tequal) +& "*" +& cval +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*.0123E12*~:)", true, true, "TplParser.expression \n\""+& str +&"\"\n", notPassedCnt);   
 
        //*************
        str = "true~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.LITERAL("true", TplAbsyn.BOOLEAN_TYPE()) 
        );
        
        TplAbsyn.LITERAL(cval,_) = exp;
        strOut = Tpl.booleanString(tequal) +& "*" +& cval +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*true*~:)", true, true, "TplParser.expression \n\""+& str +&"\"\n", notPassedCnt);   

        //*************
        str = "false~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.LITERAL("false", TplAbsyn.BOOLEAN_TYPE()) 
        );
        
        TplAbsyn.LITERAL(cval,_) = exp;
        strOut = Tpl.booleanString(tequal) +& "*" +& cval +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*false*~:)", true, true, "TplParser.expression \n\""+& str +&"\"\n", notPassedCnt);   

        //*************
        str = "\\n~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.STR_TOKEN(Tpl.ST_NEW_LINE()) 
        );
        
        TplAbsyn.STR_TOKEN(tok) = exp;
        //Tpl.ST_STRING_LIST({"\n",""},false) = tok;
        txt = emptyTxt;
        txt = Tpl.writeTok(txt, tok);
        strOut = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +& "*" +& strOut +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*\n*~:)", true, true, "TplParser.expression \n\""+& str +&"\"\n", notPassedCnt);

        //*************
        str = "\\\"\\n\\n\\ ~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST({"\"\n", "\n"," "}, false)) 
        );
        
        TplAbsyn.STR_TOKEN(tok) = exp;
        txt = emptyTxt;
        txt = Tpl.writeTok(txt, tok);
        strOut = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +& "*" +& strOut +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*\"\n\n *~:)", true, true, "TplParser.expression \n\""+& str +&"\"\n", notPassedCnt);   
    
        //*************
        str = "'Susan'~:)";
        chars = stringListStringChar( str );
        
        (chars,_, exp) = TplParser.expression(chars, TplParser.makeStartLineInfo(chars, "in memory test"),"<",">", false);
        
        tequal = Util.equal(
          exp,
          TplAbsyn.STR_TOKEN(Tpl.ST_STRING("Susan")) 
        );
        
        TplAbsyn.STR_TOKEN(tok) = exp; //dangerous, can fail fatally here
        txt = emptyTxt;
        txt = Tpl.writeTok(txt, tok);
        strOut = Tpl.textString(txt);
        strOut = Tpl.booleanString(tequal) +& "*" +& strOut +& "*" +& stringCharListString(chars);       
        notPassedCnt = testStringEquality(strOut,  
           "true*Susan*~:)", true, true, "TplParser.expression \n\""+& str +&"\"\n", notPassedCnt);   

        
        //*************
        str = "Susan:)";
        chars = stringListStringChar( str );
        llen = TplParser.charsTillEndOfLine(chars, 1);
        (_ :: _ :: chars) = chars;
        (lnum,colnum) = TplParser.getPosition(chars, TplParser.LINE_INFO(TplParser.PARSE_INFO("test - no file",{},false), 11, llen, chars));
        notPassedCnt = testStringEquality(intString(lnum) +& "," +& intString(colnum) +& " of " +& intString(llen),  
           "11,3 of 8", true, true, "TplParser.charsTillEndOfLine and getPosition \n", notPassedCnt);
       
        
        
        //*************
        txt = emptyTxt;
        txt = statement(txt, 
               WHILE( BINARY( VARIABLE("x"), LESS(), ICONST(20) ),
                 {ASSIGN( 
                    VARIABLE("x"), 
                    BINARY( VARIABLE("x"), PLUS(), 
                            BINARY( VARIABLE("y"), TIMES(), ICONST(2) ) 
                    ) 
                 )}
               )  
                 
               );
        str = Tpl.textString(txt);
        notPassedCnt = testStringEquality(str,  
"while((x < 20)) {
  x = (x + (y * 2));
}", true, true, "Paper Example statement()", notPassedCnt);
        
        //*************
        txt = emptyTxt;
        txt = intMatrix(txt,
          {   { 1, 2, 3, 4, 5 },  
              { 6, 7, 8, 9, 10 },
              { 11, 12, 13, 14, 15 }
          }  
        );
        str = Tpl.textString(txt);
        notPassedCnt = testStringEquality(str,  
"[ 1, 2, 3, 4, 5;
  6, 7, 8, 9, 10;
  11, 12, 13, 14, 15 ]", true, true, "intMatrix() from test.tpl", notPassedCnt);
        
        //*************
        notPassedCnt = testTranslateTplFile("TplCodegen", false, false, notPassedCnt);
        
        //*************
        notPassedCnt = testTranslateTplFile("paper", false, false, notPassedCnt);
        
        //*************
        notPassedCnt = testTranslateTplFile("test", false, true, notPassedCnt);
        
        //*************
        //notPassedCnt = testTranslateTplFile("SimCodeC", false, true, notPassedCnt);
        
        
        print("All tests took " +& realString(clock() -. tstart) +& " seconds.\n");        
        str = Util.if_(notPassedCnt == 0, 
          "\n ***** All a) tests OK *****\n\n", 
          "\n #### " +& intString(notPassedCnt) +& " test" +& Util.if_(notPassedCnt > 1,"s","") +& " DID NOT passed ####\n\n");
        print(str);
        //print("TplCodegen.tpl:258.1-259.1 Error: Toto je uff!\n");
        //print("TplCodegen.tpl:263.1-263.3 Error: Toto je algor uff!\n");
        //print("Hej!\n"); 
      then 
        ();
      
        
    //should not ever happen -  a badly designed test ? 
    case (str)
      equation
        print("\n######## tplMainTest '"+& str +& "' (fatally) failed!  ########\n" );
        print("### Error Buffer ###\n");
        print(Print.getErrorString());
        print("\n### End of Error Buffer ###\n");
        Print.clearErrorBuf();
      then 
        ();
        
  end matchcontinue;
end tplMainTest;


/* the paper example */

uniontype Statement  "Algorithmic stmts"
	  record ASSIGN  "An assignment stmt"
	    Exp lhs; Exp rhs;
	  end ASSIGN;
	
	  record WHILE  "A while statement"
	    Exp condition;
	    list<Statement> statements;
	  end WHILE;
	end Statement;
	
	uniontype Exp  "Expression nodes"
	  record ICONST  "Integer constant value"
	    Integer value;
	  end ICONST;
	
	  record VARIABLE "Variable reference"
	    String name;
	  end VARIABLE;
	
	  record BINARY  "Binary ops"
	    Exp lhs; 
	    Operator op;  
	    Exp rhs;
	  end BINARY;
	end Exp;
	
	uniontype Operator
	  record PLUS end PLUS;
	  record TIMES end TIMES;
	  record LESS end LESS;
	end Operator; 



protected function lm_1
  input Tpl.Text in_txt;
  input list<Statement> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<Statement> rest;
        Statement i_it;
      equation
        txt = statement(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_1(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Statement> rest;
      equation
        txt = lm_1(txt, rest);
      then txt;
  end matchcontinue;
end lm_1;

public function statement
  input Tpl.Text in_txt;
  input Statement in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           ASSIGN(lhs = i_lhs, rhs = i_rhs) )
      local
        Exp i_rhs;
        Exp i_lhs;
      equation
        txt = exp(txt, i_lhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = exp(txt, i_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;

    case ( txt,
           WHILE(condition = i_condition, statements = i_statements) )
      local
        list<Statement> i_statements;
        Exp i_condition;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("while("));
        txt = exp(txt, i_condition);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_1(txt, i_statements);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end statement;

public function exp
  input Tpl.Text in_txt;
  input Exp in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           ICONST(value = i_value) )
      local
        Integer i_value;
      equation
        txt = Tpl.writeStr(txt, intString(i_value));
      then txt;

    case ( txt,
           VARIABLE(name = i_name) )
      local
        String i_name;
      equation
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           BINARY(lhs = i_lhs, op = i_op, rhs = i_rhs) )
      local
        Exp i_rhs;
        Operator i_op;
        Exp i_lhs;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = exp(txt, i_lhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = oper(txt, i_op);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = exp(txt, i_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end exp;

public function oper
  input Tpl.Text in_txt;
  input Operator in_i_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_it)
    local
      Tpl.Text txt;

    case ( txt,
           PLUS() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
      then txt;

    case ( txt,
           TIMES() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("*"));
      then txt;

    case ( txt,
           LESS() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("<"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end oper;

/***************************/
/* intMatrix from test.tpl */
/***************************/

protected function lm_54
  input Tpl.Text in_txt;
  input list<Integer> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      local
        list<Integer> rest;
        Integer i_it;
      equation
        txt = Tpl.writeStr(txt, intString(i_it));
        txt = Tpl.nextIter(txt);
        txt = lm_54(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_54(txt, rest);
      then txt;
  end matchcontinue;
end lm_54;

protected function lm_55
  input Tpl.Text in_txt;
  input list<list<Integer>> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_intLst :: rest )
      local
        list<list<Integer>> rest;
        list<Integer> i_intLst;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_54(txt, i_intLst);
        txt = Tpl.popIter(txt);
        txt = Tpl.nextIter(txt);
        txt = lm_55(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<list<Integer>> rest;
      equation
        txt = lm_55(txt, rest);
      then txt;
  end matchcontinue;
end lm_55;

public function intMatrix
  input Tpl.Text txt;
  input list<list<Integer>> i_lstOfLst;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("[ "));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_ANCHOR(0));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(";\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_55(out_txt, i_lstOfLst);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" ]"));
end intMatrix;
/***************************/
/* end of intMatrix from test.tpl */
/***************************/



//!!! weird type behavior of MM
public
function MuchFun2
  input Tpl.Text txt;
  input Integer inlaughLevel;
  input list<String> injokes;

  output Integer txt;

  Tpl.Text txt1;
  Integer laughLevel;
  list<String> jokes;
algorithm
(txt) := Tpl.writeStr(txt, "Susan");
txt := 1;
//(txt1) := Tpl.writeStr(txt, "Susan");

//(txt) := Tpl.writeTok(txt, Tpl.ST_LINE("Susan is cosmic!\n"));
end MuchFun2;


end TplMain;

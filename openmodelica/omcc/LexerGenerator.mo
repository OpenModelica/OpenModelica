package LexerGenerator
  import System;
  constant Boolean debug = true;

  import OMCC.copyright;

function genLexer
  input String flexFile;
  input String grammarFile;
  input String outFileName;
  output String result;
protected
  String flexCode,re,ar1,rest;
  Boolean res1,res2,res3,res4;
  list<String> resultRegex,resTable,chars;
algorithm
  //open flex file and validate

  if (outFileName<>"" and stringLength(outFileName)<15) then
    if (debug==true) then
      print("Generating Lexer from " + flexFile + "\n");
    end if;

    flexCode := System.readFile(flexFile);

    print("Read FLEX grammar file " + flexFile + "\n");

    res1 := buildLexTable(flexCode,"LexTable" + outFileName);

    if (debug==true) then
      print("Build Lex Table ...\n");
    end if;

    res2 := buildLexerCode(flexCode,grammarFile,outFileName);

    if (debug==true) then
     print("Build LexerCode ...\n");
    end if;
    res3  := buildLexer(outFileName);

    if (debug==true) then
     print("Build lexermodelica ...\n");
    end if;

    result := "Lexer Built";

    if (res1==false) then
     result := result + "LexerTable"+ outFileName +".mo could not be generated.\n";
    end if;
    if (res2==false) then
     result := result + "LexerCode"+ outFileName +".mo could not be generated.\n";
    end if;
    if (res3==false) then
      result := result + "Lexer"+ outFileName +".mo could not be generated.\n";
    end if;
  else
    result := "Invalid language grammar name";
  end if;
end genLexer;

 function readPrologEpilog
   input String lexerCode;
   input String grammarFileName;
   output String lexerCodeIncluded;
   protected
   String grammarFile,epilog,prolog,re,ar1,astRootType;
   Integer numMatches,pos1,pos2;
   list<String> resultRegex;
  algorithm
    if (debug==true) then
      print("\nRead epilogue and prologue");
    end if;
     grammarFile := System.readFile(grammarFileName);

    //find prologue

    pos1 := System.stringFind(grammarFile,"%{");
    pos2 := System.stringFind(grammarFile,"%}");

    ar1 := System.substring(grammarFile,pos1+3,pos2-1);
    lexerCodeIncluded := System.stringReplace(lexerCode,"%prologue%",ar1);

    //
  /*  ar1 := System.stringFindString(grammarFile,"AstTree");
    pos1 := System.stringFind(ar1,"=");
    pos2 := System.stringFind(ar1,";");
    astRootType := System.substring(ar1,pos1+2,pos2);
    astRootType := System.trim(astRootType," ");
    parserCodeIncluded := System.stringReplace(parserCodeIncluded,"%astTree%",astRootType); */

    //find epilogue
    re := "%%";
    ar1 := System.stringFindString(grammarFile,re);
    ar1 := System.substring(ar1,3,stringLength(ar1));
    ar1 := System.stringFindString(ar1,re);
    ar1 := System.substring(ar1,3,stringLength(ar1));
    lexerCodeIncluded := System.stringReplace(lexerCodeIncluded,"%epilogue%",ar1);


 end readPrologEpilog;

function buildLexerCode
  input String flexCode;
  input String grammarFile;
  input String outFileName;
  output Boolean buildResult;
protected
  list<String> resTable;
  String lexCode,result,rest,stTime,cp,caseAction,re,tokenName;
  Integer i,numMatches,numRules,pos,pos2,posBegin,posReturn,posKeepBuffer,posBreak,valBegin;
algorithm
  lexCode := System.readFile("LexerCode.tmo");
  stTime := copyright;
  result := System.stringReplace(lexCode,"%LexerCode%","LexerCode" + outFileName);
  result := System.stringReplace(result,"%time%",stTime);
  result := System.stringReplace(result,"%Token%","Token" + outFileName);
  result := System.stringReplace(result,"%Lexer%","Lexer" + outFileName);
  result := System.stringReplace(result,"%ParseTable%","ParseTable" + outFileName);
  result := System.stringReplace(result,"%nameSpan%","255");

  result := readPrologEpilog(result,grammarFile);
  caseAction := "";
  resTable := {};
  numRules := findValue(flexCode,"YY_NUM_RULES");
   //  print("\n new area");
  re := "/* beginning of action switch */";
  rest := System.stringFindString(flexCode,re);

  if (debug==true) then
    print("beginning of action switch\n");
  end if;
  for i in 1:numRules loop
    cp := "       case (";
    resTable := cp::resTable;
    cp := intString(i);
    resTable := cp::resTable;
    cp := ") // ";
    resTable := cp::resTable;

    re := "case " + intString(i) + ":";
    (numMatches,_::rest::_) := System.regex(flexCode,"case " + intString(i) + ":[^#]*(#[^#]*)YY_BREAK[^#]*",2,extended=true);
    if (numMatches < 2) then
      print("Failed to find lexer case " + intString(i) + "\n");
      fail();
    end if;
    (numMatches,_::tokenName::_) := System.regex(rest,"return *([^;]*);",2,extended=true);
print(intString(i) + " is token " + tokenName + "\n");
    re := "#line";
    pos := System.stringFind(rest,re);
    pos2 := System.stringFind(rest,".l");
    cp := substring2(rest,pos+1,pos2+3);
    resTable := cp::resTable;
    //posReturn,posKeepBuffer,posBreak
    posReturn := System.stringFind(rest,"Return ");
    posBegin := System.stringFind(rest,"BEGIN");
    posKeepBuffer := System.stringFind(rest,"keepBuffer");
    //print("\n pos:" + intString(pos) + ":" + "pos2:" + intString(pos2) + ":" + "posB:" + intString(posBegin) );
    resTable := "\n         equation" :: resTable;
    if (posBegin>=0) then // starts BEGIN switch start state
        // find token
        pos := System.stringFind(rest,"(");
        pos2 := System.stringFind(rest,")");
        cp := substring2(rest,pos+2,pos2);

        valBegin := findValue(flexCode,cp);
        valBegin := 1+2*valBegin;
        if (debug==true) then
           print("\n BEGIN at" + intString(valBegin));
        end if;
        cp := "           mm_startSt = " + intString(valBegin) +";";
        resTable := cp::resTable;
    end if;

    if (posKeepBuffer>=0) then // starts keepbuffer switch start state
        // print keep buffer
        if (debug==true) then
           print("\n keepbuffer");
        end if;
        cp := "\n           bufferRet = buffer;";
        resTable := cp::resTable;
    end if;

   if tokenName <> "" then
     cp := "\n           act2 = Token";
     resTable := cp::resTable;
     resTable := outFileName::resTable;
     cp := ".";
     resTable := cp::resTable;

     resTable := tokenName::resTable;
     cp := ";\n           tok = OMCCTypes.TOKEN(\""+tokenName+"\",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);\n         then tok;\n ";
     resTable := cp::resTable;
   else
     //print("NONE");
     cp := "\n         then OMCCTypes.noToken;\n";
     resTable := cp::resTable;
   end if;

  end for;

  resTable := listReverse(resTable);
  caseAction := stringCharListString(resTable);

  result := System.stringReplace(result,"%caseAction%",caseAction);
  System.writeFile("LexerCode" + outFileName + ".mo",result);
  buildResult := true;
end buildLexerCode;

  function findValue
    input String flexCode;
    input String variable;
    output Integer value;

    protected
    Integer pos;
    String rest,val,re;
   algorithm
    (_,_::val::{}) := System.regex(flexCode,"define " + variable + " ([0-9]*)",2,true,false);
    print("\n val is:" +val);
    value := stringInt(val);

    print("\n value found");
  end findValue;

  function buildLexer
    input String outFileName;
    output Boolean buildResult;
    protected
    String lexCode,result,stTime,cp;
  algorithm
    lexCode := System.readFile("Lexer.mo");
    stTime := copyright;
    result := System.stringReplace(lexCode,"LexTable","LexTable" + outFileName);
    result := System.stringReplace(result,"LexerCode","LexerCode" + outFileName);
    cp := "package Lexer" + outFileName + " // " + stTime;
    result := System.stringReplace(result,"package Lexer",cp );
    result := System.stringReplace(result,"end Lexer;","end Lexer" + outFileName + ";");
    System.writeFile("Lexer" + outFileName + ".mo",result);
    buildResult := true;
  end buildLexer;

  function buildLexTable
    input String flexCode;
    input String outFileName;
    output Boolean buildResult;
    protected
    String cp,re,re1,ar1,rest,result,stTime;
    Integer numMatches,pos1,pos2,len;
    list<String> resultRegex,resTable,chars;

  algorithm

    stTime := copyright;

    cp := "encapsulated package " + outFileName +" // " + stTime + " \n\nconstant Integer yy_limit = ";

    resTable := cp::{};

    // Insert yy_limit
    re := "if ( yy_current_state >= ";
    re1 := "if ( yy_current_state >=[^)]*)";
    (numMatches,resultRegex) := System.regex(flexCode,re1,1,false,false);

    ar1::_ := resultRegex;
    if (debug==true) then
       print("\nFound regex:" + ar1);
    end if;
    numMatches:=0;
    (numMatches,resultRegex) := System.regex("if ( yy_current_state >= 65 )","[0-9]*",2,false,false);
    if (debug==true) then
       print("\nNumMatches:" + intString(numMatches));
    end if;
    cp::_ := resultRegex;
    if (debug==true) then
       print("\nFound regex2:" + cp);
    end if;

    rest := System.stringFindString(flexCode,re);

    pos2 := System.stringFind(rest,")");
    ar1 := substring2(rest,stringLength(re)+1,pos2-1);
    resTable := ar1::resTable;

    cp := ";\n\nconstant Integer yy_finish = ";
    resTable := cp::resTable;
    re := "while ( yy_base[yy_current_state] != ";
    rest := System.stringFindString(flexCode,re);
    pos2 := System.stringFind(rest,")");
    ar1 := substring2(rest,stringLength(re)+1,pos2-1);
    resTable := ar1::resTable;

    cp := ";\n\nconstant list<Integer> yy_acclist = {";
    resTable := cp::resTable;

    // match acclist
    re := "yy_acclist\\[[0-9]*\\] =[^}]*}";
    (numMatches,resultRegex) := System.regex(flexCode,re,1,false,false);
    ar1::_ := resultRegex;
    if (numMatches > 0) then
      pos1 := System.stringFind(ar1,",");
      pos2 := System.stringFind(ar1,"}");
      ar1 := substring2(ar1,pos1+2,pos2-1);
    else
      ar1 := "";
    end if;
    resTable := ar1::resTable;


    cp := "};\n\nconstant list<Integer> yy_accept = {";
    resTable := cp::resTable;
    re := "yy_accept\\[[0-9]*\\] =[^}]*}";
    (numMatches,resultRegex) := System.regex(flexCode,re,1,false,false);
    rest::_ := resultRegex;
    if (numMatches > 0) then
      //rest := System.stringFindString(flexCode,re);
      pos1 := System.stringFind(rest,",");
      pos2 := System.stringFind(rest,"}");
      ar1 := substring2(rest,pos1+2,pos2-1);
      resTable := ar1::resTable;
    end if;
    cp := "};\n\nconstant list<Integer> yy_ec = {";
    resTable := cp::resTable;
    //re := "static yyconst int yy_ec";
    re := "yy_ec\\[[0-9]*\\] =[^}]*}";
    (numMatches,resultRegex) := System.regex(flexCode,re,1,false,false);
    rest::_ := resultRegex;
    if (numMatches > 0) then
      //rest := System.stringFindString(flexCode,re);
      pos1 := System.stringFind(rest,",");
      pos2 := System.stringFind(rest,"}");
      ar1 := substring2(rest,pos1+2,pos2-1);
      resTable := ar1::resTable;
    end if;
    cp := "};\n\nconstant list<Integer> yy_meta = {";
    resTable := cp::resTable;
    //re := "static yyconst int yy_meta";
    re := "yy_meta\\[[0-9]*\\] =[^}]*}";
    (numMatches,resultRegex) := System.regex(flexCode,re,1,false,false);
    rest::_ := resultRegex;
    if (numMatches > 0) then
      //rest := System.stringFindString(flexCode,re);
      pos1 := System.stringFind(rest,",");
      pos2 := System.stringFind(rest,"}");
      ar1 := substring2(rest,pos1+2,pos2-1);
      resTable := ar1::resTable;
    end if;

    cp := "};\n\nconstant list<Integer> yy_base = {";
    resTable := cp::resTable;

    //re := "static yyconst short int yy_base";
    re := "yy_base\\[[0-9]*\\] =[^}]*}";
    (numMatches,resultRegex) := System.regex(flexCode,re,1,false,false);
    rest::_ := resultRegex;
    if (numMatches > 0) then
      //rest := System.stringFindString(flexCode,re);
      pos1 := System.stringFind(rest,",");
      pos2 := System.stringFind(rest,"}");
      ar1 := substring2(rest,pos1+2,pos2-1);
      resTable := ar1::resTable;
    end if;

    cp := "};\n\nconstant list<Integer> yy_def = {";
    resTable := cp::resTable;
    //re := "static yyconst short int yy_def";
    re := "yy_def\\[[0-9]*\\] =[^}]*}";
    (numMatches,resultRegex) := System.regex(flexCode,re,1,false,false);
    rest::_ := resultRegex;
    if (numMatches > 0) then
      //rest := System.stringFindString(flexCode,re);
      pos1 := System.stringFind(rest,",");
      pos2 := System.stringFind(rest,"}");
      ar1 := substring2(rest,pos1+2,pos2-1);
      resTable := ar1::resTable;
    end if;

    cp := "};\n\nconstant list<Integer> yy_nxt = {";
    resTable := cp::resTable;
    //re := "static yyconst short int yy_nxt";
    re := "yy_nxt\\[[0-9]*\\] =[^}]*}";
    (numMatches,resultRegex) := System.regex(flexCode,re,1,false,false);
    rest::_ := resultRegex;
    if (debug==true) then
       print("\nREST next" + rest);
    end if;
    if (numMatches > 0) then
      //rest := System.stringFindString(flexCode,re);
      pos1 := System.stringFind(rest,",");
      pos2 := System.stringFind(rest,"}");
      ar1 := substring2(rest,pos1+2,pos2-1);
      resTable := ar1::resTable;
    end if;

    cp := "};\n\nconstant list<Integer> yy_chk = {";
    resTable := cp::resTable;
    re := "static yyconst short int yy_chk";
    re := "yy_chk\\[[0-9]*\\] =[^}]*}";
    (numMatches,resultRegex) := System.regex(flexCode,re,1,false,false);
    rest::_ := resultRegex;
    if (numMatches > 0) then
      //rest := System.stringFindString(flexCode,re);
      pos1 := System.stringFind(rest,",");
      pos2 := System.stringFind(rest,"}");
      ar1 := substring2(rest,pos1+2,pos2-1);
      resTable := ar1::resTable;
    end if;


    cp := "};\n\nend " + outFileName + ";";
    resTable := cp::resTable;

    resTable := listReverse(resTable);
    result := stringCharListString(resTable);
    System.writeFile(outFileName + ".mo",result);
    buildResult := true;
  end buildLexTable;

public function getCurrentTimeStr "
returns current time in format Www Mmm dd hh:mm:ss yyyy
using the asctime() function in time.h (libc)
"
  output String timeStr;
  protected
  Integer sec, min, hour, mday, mon, year;
 algorithm
   timeStr := System.getCurrentTimeStr();
   /*(sec, min, hour, mday, mon, year) := System.getCurrentDateTime();
    timeStr := intString(year) + "/" + intString(mon)+ "/" + intString(mday)+
           " " + intString(hour)+ ":" + intString(min) + ":" + intString(sec); */
end getCurrentTimeStr;

public function substring2
  input String inString;
  input Integer start;
  input Integer stop;
  output String outString;
protected
  list<String> chars, result;
  String c;
  Integer i;
algorithm
  outString := System.substring(inString,start,stop);
  /* result :={};
   chars := stringListStringChar(inString);
   for i in 1:stop loop
      c::chars := chars;
      if (i>=start) then
         result := c::result;
      end if;
   end for;
   result := listReverse(result);
   outString := stringCharListString(result);  */
end substring2;

function buildTokens
  input String outFileName;
  input String flexFile;
  output Boolean buildResult;
protected
  String cp,re,flexCode,s;
  Integer numMatches=0;
  list<String> resTable,tokens,tokens2,tmp;
algorithm
  cp := "encapsulated package " + outFileName +" // " + copyright;
  resTable := cp::{};
  tokens := {};

  flexCode := System.readFile(flexFile);
  for str in System.strtok(flexCode, "return ") loop
    tmp := System.strtok(str,";");
    s := if listEmpty(tmp) then "" else System.trim(listGet(tmp,1));
    if 1==System.regex(s, "^[A-Z_]{2,}$",0,extended=true) then
      tokens := s :: tokens;
    end if;
  end for;
  tokens2 := List.sortedUnique(List.sort(tokens, Util.strcmpBool), stringEqual);
  numMatches := listLength(tokens2);
  tokens := {};
  for str in tokens2 loop
    tokens := ("\n  constant Integer " + str + "=" + String(numMatches) + ";") :: tokens;
    numMatches := numMatches - 1;
  end for;
  cp := stringAppendList(listReverse(tokens));
  resTable := cp::resTable;
  cp := "\nend " + outFileName + ";";
  resTable := cp::resTable;

  resTable := listReverse(resTable);
  System.writeFile(outFileName + ".mo", stringAppendList(resTable));
  buildResult := true;
end buildTokens;

end LexerGenerator;

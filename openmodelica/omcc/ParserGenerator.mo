package ParserGenerator
import System;
import Util;
import OMCC.copyright;
/*

*/
constant Boolean debug = false;

function genParser
  input String bisonFile;
  input String grammarFile;
  input String outFileName;
  output String result;
protected
  String bisonCode,re,ar1,rest;
  Boolean res1,res2,res3,res4;
  list<String> resultRegex,resTable,chars;
  array<Integer> yyr2;
algorithm
  //open bison file
  if (outFileName<>"" and stringLength(outFileName)<15) then
    if (debug==true) then
       print("\nGenerating Parser from " + bisonFile);
    end if;
    bisonCode := System.readFile(bisonFile);
    print("Reading BISON grammar file " + bisonFile + "\n");

    (res1,yyr2) := buildParseTable(bisonCode,"ParseTable" + outFileName);
     if (debug==true) then
       print("\nbuild Parse table");
    end if;

    res2 := buildTokens(bisonCode,"Token" + outFileName);
    if (debug==true) then
       print("Generating Token from " + bisonFile + "\n");
    end if;

    res3 := buildParserCode(bisonCode,grammarFile,outFileName,yyr2);
    if (debug==true) then
      print("Generating ParserCode from " + bisonFile + "\n");
    end if;
    /*
    if (debug==true) then
       print("Build Parser ..." + "\n");
    end if;
    res4 := buildParser(outFileName);
    */
    res4 := buildParser(outFileName);
      if (debug==true) then
       print("\nBuild Parser ...");
    end if;
    result := "Parser Built";
    if (res1==false) then
       result := result + "\nParseTable"+ outFileName +".mo could not be generated.";
    end if;
    if (res2==false) then
       result := result + "\nToken"+ outFileName +".mo could not be generated.";
    end if;
    if (res3==false) then
       result := result + "\nParseCode"+ outFileName +".mo could not be generated.";
    end if;
    if (res4==false) then
       result := result + "\nParser"+ outFileName +".mo could not be generated.";
    end if;
  else
    result := "Parser can not be generated. Invalid name";
  end if;
end genParser;

function buildParser
  input String outFileName;
  output Boolean buildResult;
  protected
  String parser,result,stTime,cp;
algorithm
  parser := System.readFile("Parser.mo");
  result := System.stringReplace(parser,"ParseTable","ParseTable" + outFileName);
  result := System.stringReplace(result,"Lexer.","Lexer" + outFileName + ".");
  result := System.stringReplace(result,"ParseCode","ParseCode" + outFileName);
  cp := "package Parser" + outFileName + " \" " + copyright + "\"";
  result := System.stringReplace(result,"package Parser",cp );
  result := System.stringReplace(result,"end Parser;","end Parser" + outFileName + ";");
  System.writeFile("Parser" + outFileName + ".mo",result);
  buildResult := true;
end buildParser;


function readPrologEpilog
 input String parserCode;
 input String grammarFileName;
 output String parserCodeIncluded;
 protected
 String grammarFile,epilog,prolog,re,ar1,astRootType;
 Integer numMatches,pos1,pos2;
 list<String> resultRegex;
algorithm
   grammarFile := System.readFile(grammarFileName);

  //find prologue

  pos1 := System.stringFind(grammarFile,"%{");
  pos2 := System.stringFind(grammarFile,"%}");

  ar1 := substring(grammarFile,pos1+3,pos2-1);
  parserCodeIncluded := System.stringReplace(parserCode,"%prologue%",ar1);

  //
/*  ar1 := System.stringFindString(grammarFile,"AstTree");
  pos1 := System.stringFind(ar1,"=");
  pos2 := System.stringFind(ar1,";");
  astRootType := substring(ar1,pos1+2,pos2);
  astRootType := System.trim(astRootType," ");
  parserCodeIncluded := System.stringReplace(parserCodeIncluded,"%astTree%",astRootType); */

  //find epilogue
  re := "%%";
  ar1 := System.stringFindString(grammarFile,re);
  ar1 := substring(ar1,3,stringLength(ar1));
  ar1 := System.stringFindString(ar1,re);
  ar1 := substring(ar1,3,stringLength(ar1));
  parserCodeIncluded := System.stringReplace(parserCodeIncluded,"%epilogue%",ar1);


end readPrologEpilog;


function buildParserCode
  input String bisonCode;
  input String grammarFile;
  input String outFileName;
  input array<Integer> yyr2;
  output Boolean buildResult;
protected
  list<String> resTable;
  String parseCode,result,rest,stTime,cp,caseAction,re,typeTok,astValType,astRootType,resultRegex,regexError,lineStr,origFile,fileInfoAnnotation;
  Integer i,numRules,pos,pos2,posBegin,valBegin;
  list<String> types;
  Integer ix,maxReduce,numReduce,numMatches;
algorithm
  types := {"String","Integer"};
  maxReduce := 0;
  parseCode := System.readFile("ParseCode.tmo");
  stTime := copyright;
  result := System.stringReplace(parseCode,"%ParseCode%","ParseCode" + outFileName);
  result := System.stringReplace(result,"%time%",stTime);
  result := readPrologEpilog(result,grammarFile);


  caseAction := "";
  resTable := {};
  if (debug==true) then
     print("\nFind value ynrules...");
  end if;
  numRules := findValue(bisonCode,"YYNRULES");
  re := "switch (yyn)";
  rest := System.stringFindString(bisonCode,re);

  for i in 2:numRules loop
    cp := "\n       case ";
    resTable := cp::resTable;
    cp := intString(i);
    resTable := cp::resTable;

    re := "case " + intString(i) + ":";
    if (debug==true) then
       print("\n" + re);
       printAny("\n" + re);
    end if;
    pos := System.stringFind(bisonCode,re);
    if (pos<0) then
        print("\nError in rule " + intString(i) + ". Case not found.");
    end if;
    rest := System.stringFindString(bisonCode,re);

    re := "#line";
    (3,_::lineStr::origFile::_) := System.regex(rest,"#line *([0-9]*) *(\"[A-Za-z0-9.]*\")",3,extended=true);
    fileInfoAnnotation := " annotation(__OpenModelica_FileInfo=("+origFile+","+lineStr+"));\n";

    pos2 := System.stringFind(rest,"break;");
    rest := substring(rest,1,pos2-1);
    //re := "{[^}]*;}";
    re := "[{] *(.*;) *[}]";
    (numMatches,regexError::resultRegex::_) := System.regex(rest,re,2,extended=true);
    if numMatches == 2 then
        cp := "\n         equation\n";
        resTable := cp::resTable;
        if (debug==true) then
           print("Rule " + intString(i) + ":" + resultRegex + "\n");
        end if;
        print("Rule " + intString(i) + ":" + resultRegex + "\n");
        ix := arrayGet(yyr2,i);
        (cp,types) := processRule(resultRegex,types,ix);
        maxReduce := max(maxReduce, ix);
        cp := cp + "\n           stack = yyval::stack;\n";
        cp := System.stringReplace(cp,";\n",fileInfoAnnotation);
        resTable := cp::resTable;
        cp := "         then ();\n";
        resTable := cp::resTable;
    else
      print("Rule "+intString(i)+" not found: \n");
      print(regexError);
      print(rest);
      fail();
    end if;
  end for;

  resTable := listReverse(resTable);
  caseAction := stringCharListString(resTable);


  // generate variables and typesStack
  astValType := "";
  types := "Token"::types; //stack to push tokens

  astValType := "        AstItem " + stringDelimitList(list("yysp_" + intString(i) for i in 1:maxReduce), ",") + ";\n";

  caseAction := astValType + caseAction;

  astRootType := "AstItem"; // substring(rest,stringLength(re)+1,pos2);

  result := System.stringReplace(result,"%astTree%",astRootType);

  result := System.stringReplace(result,"%caseAction%",caseAction);

  System.writeFile("ParseCode" + outFileName + ".mo",result);
  buildResult := true;
end buildParserCode;

function processRule
  input String inRule;
  input list<String> types;
  input Integer numTokensInRule;
  output String processedRules;
  output list<String> types2;
protected
  Integer pos1,pos2,i;
  list<String> resTable;
  String cp,tokRes,re,typeTok,rule,var;
 algorithm
   rule := inRule;
   resTable := {};
   types2 := types;
   if numTokensInRule >=2 then
     cp := "           stackToken = mergeStackTokens(stackToken,"+intString(numTokensInRule)+");\n";
     resTable := cp::resTable;
   elseif numTokensInRule == 0 then
     // We need to add something to the stack...
     cp := "           stackToken = OMCCTypes.noToken::stackToken;\n";
     resTable := cp::resTable;
   end if;

   for i in numTokensInRule:-1:1 loop
     var := "yysp_"+intString(i);
     re := "(yyvsp[("+intString(i)+") - ("+intString(numTokensInRule)+")])";
     cp := "           "+var+"::stack = stack;\n";
     rule := System.stringReplace(rule,re,var);
     resTable := cp::resTable;
   end for;

   resTable := ("           "+rule)::resTable;
   processedRules := stringAppendList(listReverse(resTable));
   processedRules := System.stringReplace(processedRules, "yyinfo", "OMCCTypes.makeInfo(listGet(stackToken,1),fileName)");
end processRule;

function replaceTokenVal
  input String rule;
  input Integer tok;
  output String result;
  protected
   Integer pos,pos2,numTok;
   String re,rest,typeTok,cp;
 algorithm
  numTok := numTokens(rule);
  typeTok := findTypeToken(rule,tok);
  re := "(yyvsp[(" + intString(tok) + ") - (" + intString(numTok) + ")])[" + typeTok + "]";
  pos := System.stringFind(rule, re);
  if (pos<0) then
     re := "(yyvsp[(" + intString(tok) + ") - (" + intString(numTok) + ")])";
  end if;
  cp := "(v" + intString(tok) + typeTok + ")";
  if (findTypeResult(rule)=="Integer" and typeTok=="String") then
     cp := "(stringInt(v" + intString(tok) + typeTok + "))";
  end if;
  //print(re);
  result := System.stringReplace(rule,re,cp);
  //print(result);
end replaceTokenVal;

function reduceToken
  input String rule;
  input Integer tok;
  output String reduce;
  protected
   Integer pos,pos2;
   String re,rest,typeTok;
 algorithm
  typeTok := findTypeToken(rule,tok);
  reduce := "           v" + intString(tok) + typeTok  +"::sk" + typeTok + " = sk" + typeTok + ";\n";
  //print(reduce);
end reduceToken;

function findTypeResult
  input String rule;
  output String typeTok;
  protected
   Integer pos,pos2,posAST;
   String re,rest;
 algorithm
  //print("\n Rule-" + rule + "-");
  re := "(absyntree)[";
  posAST := System.stringFind(rule,re);
  re := "(yyval)";
  pos2 := System.stringFind(rule,re);
  re := "(yyval)[";
  pos := System.stringFind(rule,re);
  if (pos>=0) then
    rest := System.stringFindString(rule,re);
    pos2 := System.stringFind(rest,"]");
    typeTok := substring(rest,stringLength(re)+1,pos2);
  elseif (posAST>=0) then
    re := "(absyntree)[";
    rest := System.stringFindString(rule,re);
    pos2 := System.stringFind(rest,"]");
    typeTok := substring(rest,stringLength(re)+1,pos2);
  else
    if (pos2>=0) then
       typeTok := "String";
    end if;
  end if;
  if (debug==true) then
     print("\n TypeTok-" + typeTok + "-");
  end if;
end findTypeResult;

function findTypeToken
  input String rule;
  input Integer tok;
  output String typeTok;
  protected
   Integer pos,pos2,numTok;
   String re,rest;
 algorithm
  numTok := numTokens(rule);
  re := "(yyvsp[(" + intString(tok) + ") - (" + intString(numTok) + ")])[";

  pos := System.stringFind(rule,re);

  if (pos<0) then
     typeTok := "String";
  else
     rest := substring(rule,pos+stringLength(re)+1,stringLength(rule)-1);
     pos2 := System.stringFind(rest,"]");
     typeTok := substring(rest,1,pos2);
     if (debug==true) then
        print("\nTypeToken[" + typeTok + "]");
     end if;
  end if;

end findTypeToken;

function numTokens
  input String rule;
  output Integer num;
  protected
   Integer pos,pos2;
   String re,rest,val;
 algorithm
  re :=  ") - (";
  pos := System.stringFind(rule,re);

  if (pos<0) then
     num := 0;
  else
    rest := System.stringFindString(rule,re);
    pos2 := System.stringFind(rest,")]");

    val := substring(rest,stringLength(re)+1,pos2);
    if (debug==true) then
       print("\n found numTokens:" + val);
    end if;
    num := stringInt(val);
  end if;
end numTokens;

function findValue
  input String bisonCode;
  input String variable;
  output Integer value;
  protected
  Integer pos;
  String rest,val,re;
 algorithm
  re := "define " + variable;
  rest := System.stringFindString(bisonCode,re);
  pos := System.stringFind(rest,"\n");
  val := substring(rest,stringLength(re)+1,pos);
  if (debug==true) then
     print("\n found value:" + val);
  end if;
  value := stringInt(val);
end findValue;

function buildTokens
  input String bisonCode;
  input String outFileName;
  output Boolean buildResult;
  protected
  String cp,re,ar1,rest,result,stTime,rest2;
  Integer pos1,pos2,len,numMatches;
  list<String> resultRegex,resTable,chars,tokens;
algorithm
  stTime := copyright;
  cp := "encapsulated package " + outFileName +" // " + copyright + stTime;
  resTable := cp::{};

  //re := "enum yytokentype {";
  re := "enum yytokentype[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,"{");
    pos2 := System.stringFind(rest,"}");
  end if;
  rest := substring(rest,pos1+2,pos2-4);
  tokens := System.strtok(rest,",");
  while (listEmpty(tokens)==false) loop
     cp := "\n constant Integer ";
     resTable := cp::resTable;
     cp::tokens := tokens;
     cp := System.trim(cp,"\n");
     resTable := cp::resTable;
     cp := ";";
     resTable := cp::resTable;
  end while;

  cp := "\nend " + outFileName + ";";
  resTable := cp::resTable;

  resTable := listReverse(resTable);
  result := stringCharListString(resTable);
  System.writeFile(outFileName + ".mo",result);
  buildResult := true;
end buildTokens;

function buildParseTable
  input String bisonCode;
  input String outFileName;
  output Boolean buildResult;
  output array<Integer> yyr2;
protected
  String cp,re,ar1,rest,result,stTime;
  Integer pos1,pos2,len,numMatches;
  list<String> resultRegex,resTable,chars;
algorithm

  stTime := copyright;
  cp := "encapsulated package " + outFileName +" // " + stTime + " \n\nconstant Integer YYFINAL = ";
  resTable := cp::{};

  // Insert YYFINAL
  re := "define YYFINAL";
  rest := System.stringFindString(bisonCode,re);
  pos2 := System.stringFind(rest,"\n");
  ar1 := substring(rest,stringLength(re)+1,pos2);
  resTable := ar1::resTable;

  cp := ";\n\nconstant Integer YYLAST = ";
  resTable := cp::resTable;
  re := "#define YYLAST";
  rest := System.stringFindString(bisonCode,re);
  pos2 := System.stringFind(rest,"\n");
  ar1 := substring(rest,stringLength(re)+1,pos2);
  resTable := ar1::resTable;

  cp := ";\n\nconstant Integer YYNTOKENS =";
  resTable := cp::resTable;
  re := "define YYNTOKENS";
  rest := System.stringFindString(bisonCode,re);
  pos2 := System.stringFind(rest,"\n");
  ar1 := substring(rest,stringLength(re)+1,pos2);
  resTable := ar1::resTable;

  cp := ";\n\nconstant Integer YYNNTS = ";
  resTable := cp::resTable;
  re := "define YYNNTS";
  rest := System.stringFindString(bisonCode,re);
  pos2 := System.stringFind(rest,"\n");
  ar1 := substring(rest,stringLength(re)+1,pos2);
  resTable := ar1::resTable;

  cp := ";\n\nconstant Integer YYNRULES = ";
  resTable := cp::resTable;
  re := "define YYNRULES";
  rest := System.stringFindString(bisonCode,re);
  pos2 := System.stringFind(rest,"\n");
  ar1 := substring(rest,stringLength(re)+1,pos2);
  resTable := ar1::resTable;

   cp := ";\n\nconstant Integer YYNSTATES = ";
  resTable := cp::resTable;
  re := "define YYNSTATES";
  rest := System.stringFindString(bisonCode,re);
  pos2 := System.stringFind(rest,"\n");
  ar1 := substring(rest,stringLength(re)+1,pos2);
  resTable := ar1::resTable;

   cp := ";\n\nconstant Integer YYUNDEFTOK = ";
  resTable := cp::resTable;
  re := "define YYUNDEFTOK";
  rest := System.stringFindString(bisonCode,re);
  pos2 := System.stringFind(rest,"\n");
  ar1 := substring(rest,stringLength(re)+1,pos2);
  resTable := ar1::resTable;

  cp := ";\n\nconstant Integer YYMAXUTOK = ";
  resTable := cp::resTable;
  re := "define YYMAXUTOK";
  rest := System.stringFindString(bisonCode,re);
  pos2 := System.stringFind(rest,"\n");
  ar1 := substring(rest,stringLength(re)+1,pos2);
  resTable := ar1::resTable;

  cp := ";\n\nconstant Integer YYPACT_NINF = ";
  resTable := cp::resTable;
  re := "define YYPACT_NINF";
  rest := System.stringFindString(bisonCode,re);
  pos2 := System.stringFind(rest,"\n");
  ar1 := substring(rest,stringLength(re)+1,pos2);
  resTable := ar1::resTable;

  cp := ";\n\nconstant Integer YYTABLE_NINF = ";
  resTable := cp::resTable;
  re := "define YYTABLE_NINF";
  rest := System.stringFindString(bisonCode,re);
  pos2 := System.stringFind(rest,"\n");
  ar1 := substring(rest,stringLength(re)+1,pos2);
  resTable := ar1::resTable;

 cp := ";\n\nconstant list<Integer> yytranslate = {\n";
  resTable := cp::resTable;
  //re := "static const yytype_uint8 yytranslate";
  re := "yytranslate\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,",");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+2,pos2-1);
    resTable := ar1::resTable;
  end if;

  cp := "};\n\nconstant list<Integer> yyprhs = {\n";
  resTable := cp::resTable;
  //re := "static const yytype_uint8 yyprhs";
  re := "yyprhs\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,",");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+2,pos2-1);
    resTable := ar1::resTable;
  end if;

  cp := "};\n\nconstant list<Integer> yyrhs = ";
  resTable := cp::resTable;
  //re := "static const yytype_int8 yyrhs";
  re := "yyrhs\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,"{");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+1,pos2+1);
    resTable := ar1::resTable;
  end if;

  cp := ";\n\nconstant list<Integer> yyrline :=  {\n";
  resTable := cp::resTable;
  re := "static const yytype_uint8 yyrline";
  re := "yyrline\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,",");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+2,pos2-1);
    resTable := ar1::resTable;
  end if;

  cp := "};\n\nconstant list<String> yytname = {\n";
  resTable := cp::resTable;
  //re := "static const char *const yytname";
  re := "yytname[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);

  rest::_ := resultRegex;

  //print("\nNumMatches:" + intString(numMatches) + "\n" + rest);
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    (2,_::ar1::_) := System.regex(rest,",([^#]*),.*(0|YY_NULL)",2,true,false);
    resTable := ar1::resTable;
  end if;

  cp := "};\n\nconstant list<Integer> yytoknum = {\n";
  resTable := cp::resTable;
  //re := "static const yytype_uint16 yytoknum";
  re := "yytoknum\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,",");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+2,pos2-1);
    resTable := ar1::resTable;
  end if;

  cp := "};\n\nconstant list<Integer> yyr1 = {\n";
  resTable := cp::resTable;
  //re := "static const yytype_uint8 yyr1";
  re := "yyr1\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,",");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+2,pos2-1);
    resTable := ar1::resTable;
  end if;

  cp := "};\n\nconstant list<Integer> yyr2 = {";
  resTable := cp::resTable;
  re := "yyr2\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,",");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+2,pos2-1);
    resTable := ar1::resTable;
    yyr2 := listArray(List.map(System.strtok(ar1,","), stringInt));
  else
    print("Failed to find yyr2\n");
    fail();
  end if;

  cp := "};\n\nconstant list<Integer> yydefact = ";
  resTable := cp::resTable;
  //re := "static const yytype_uint8 yydefact";
  re := "yydefact\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,"{");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+1,pos2+1);
    resTable := ar1::resTable;
  end if;

  cp := ";\n\nconstant list<Integer> yydefgoto = ";
  resTable := cp::resTable;
  //re := "static const yytype_int8 yydefgoto";
  re := "yydefgoto\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,"{");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+1,pos2+1);
    resTable := ar1::resTable;
  end if;

  cp := ";\n\nconstant list<Integer> yypact = ";
  resTable := cp::resTable;
  //re := "static const yytype_int8 yypact";
  re := "yypact\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,"{");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+1,pos2+1);
    resTable := ar1::resTable;
  end if;

  cp := ";\n\nconstant list<Integer> yypgoto = ";
  resTable := cp::resTable;
  //re := "static const yytype_int8 yypgoto";
  re := "yypgoto\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,"{");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+1,pos2+1);
    resTable := ar1::resTable;
  end if;

  cp := ";\n\nconstant list<Integer> yytable = ";
  resTable := cp::resTable;
  //re := "static const yytype_uint8 yytable";
  re := "yytable\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,"{");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+1,pos2+1);
    resTable := ar1::resTable;
  end if;

  cp := ";\n\nconstant list<Integer> yycheck =";
  resTable := cp::resTable;
  //re := "static const yytype_int8 yycheck";
  re := "yycheck\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,"{");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+1,pos2+1);
    resTable := ar1::resTable;
  end if;

  cp := ";\n\nconstant list<Integer> yystos = ";
  resTable := cp::resTable;
  //re := "static const yytype_uint8 yystos";
  re := "yystos\\[[0-9]*\\] =[^}]*}";
  (numMatches,resultRegex) := System.regex(bisonCode,re,1,false,false);
  rest::_ := resultRegex;
  if (numMatches > 0) then
    //rest := System.stringFindString(bisonCode,re);
    pos1 := System.stringFind(rest,"{");
    pos2 := System.stringFind(rest,"}");
    ar1 := substring(rest,pos1+1,pos2+1);
    resTable := ar1::resTable;
  end if;

  cp := ";\n\nend " + outFileName + ";";
  resTable := cp::resTable;

  resTable := listReverse(resTable);
  result := stringCharListString(resTable);
  System.writeFile(outFileName + ".mo",result);
  buildResult := true;
end buildParseTable;

public function getCurrentTimeStr "
returns current time in format Www Mmm dd hh:mm:ss yyyy
using the asctime() function in time.h (libc)
"
output String timeStr;
protected
Integer sec, min, hour, mday, mon, year;
algorithm
 timeStr := System.getCurrentTimeStr();
 /* (sec, min, hour, mday, mon, year) := System.getCurrentDateTime();
  timeStr := intString(year) + "/" + intString(mon)+ "/" + intString(mday)+
         " " + intString(hour)+ ":" + intString(min) + ":" + intString(sec);*/
end getCurrentTimeStr;


public function substring3
input String inString;
input Integer start;
input Integer stop;
output String outString;
protected
list<String> chars, result;
String c;
Integer i;
algorithm

   result :={};
   chars := stringListStringChar(inString);
   for i in 1:stop loop
      c::chars := chars;
      if (i>=start) then
         result := c::result;
      end if;
   end for;
   result := listReverse(result);
   outString := stringCharListString(result);
end substring3;

end ParserGenerator;

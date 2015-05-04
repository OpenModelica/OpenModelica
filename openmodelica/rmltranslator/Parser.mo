encapsulated package Parser
import Types;
import Absyn;
import Error;
import OMCCTypes;
import List;
import LexerModelica;
import ParseCode;
import ParseTable;
import System;

import arrayGet = MetaModelica.Dangerous.arrayGetNoBoundsChecking;

constant Boolean debug = false;

uniontype Env
  record ENV
    OMCCTypes.Token crTk,lookAhTk;
    list<Integer> state;
    list<String> errMessages;
    Integer errStatus,sState,cState;
    list<OMCCTypes.Token> program,progBk;
    list<Integer> stateBackup;
    ParseCode.AstStack astStackBackup;
  end ENV;
end Env;

uniontype ParseData
  record PARSE_TABLE
    array<Integer> translate;
    array<Integer> prhs;
    array<Integer> rhs;
    array<Integer> rline;
    array<String> tname;
    array<Integer> toknum;
    array<Integer> r1;
    array<Integer> r2;
    array<Integer> defact;
    array<Integer> defgoto;
    array<Integer> pact;
    array<Integer> pgoto;
    array<Integer> table;
    array<Integer> check;
    array<Integer> stos; // to be replaced
    String fileName;
  end PARSE_TABLE;
end ParseData;

 /* when the error is positive the parser runs in recovery mode,
    if the error is negative, the parser runs in testing candidate mode
    if the error is cero, then no error is present or has been recovered
    The error value decreases with each shifted token */
constant Integer maxErrShiftToken = 3;
constant Integer maxCandidateTokens = 4;
constant Integer maxErrRecShift = -5;

constant Integer ERR_TYPE_DELETE = 1;
constant Integer ERR_TYPE_INSERT = 2;
constant Integer ERR_TYPE_REPLACE = 3;
constant Integer ERR_TYPE_INSEND = 4;
constant Integer ERR_TYPE_MERGE = 5;

type AstTree = ParseCode.AstTree;

function parse "realize the syntax analysis over the list of tokens and generates the AST tree"
  input list<OMCCTypes.Token> tokens "list of tokens from the lexer";
  input String fileName "file name of the source code";
  output Boolean result "result of the parsing";
  output ParseCode.AstItem ast "AST tree that is returned when the result output is true";
protected
  list<OMCCTypes.Token> tokens1:=tokens;
  array<String> mm_tname;
  array<Integer> mm_translate, mm_prhs, mm_rhs, mm_rline, mm_toknum, mm_r1, mm_r2, mm_defact, mm_defgoto,
                 mm_pact, mm_pgoto, mm_table, mm_check, mm_stos;
  ParseData pt;
  Env env;
  OMCCTypes.Token emptyTok;
  OMCCTypes.Token emptyTok1:=emptyTok;
  ParseCode.AstStack astStk;

  list<OMCCTypes.Token> rToks;
  list<Integer> stateStk;
  list<String> errStk;
  //Boolean result;
algorithm

   if (debug) then
      print("\nParsing tokens ParseCode ..." + fileName + "\n");
   end if;
   mm_translate := listArray(ParseTable.yytranslate);
   mm_prhs := listArray(ParseTable.yyprhs);
   mm_rhs := listArray(ParseTable.yyrhs);
   mm_rline := listArray(ParseTable.yyrline);
   mm_tname := listArray(ParseTable.yytname);
   mm_toknum := listArray(ParseTable.yytoknum);
   mm_r1 := listArray(ParseTable.yyr1);
   mm_r2 := listArray(ParseTable.yyr2);
   mm_defact := listArray(ParseTable.yydefact);
   mm_defgoto := listArray(ParseTable.yydefgoto);
   mm_pact := listArray(ParseTable.yypact);
   mm_pgoto := listArray(ParseTable.yypgoto);
   mm_table := listArray(ParseTable.yytable);
   mm_check := listArray(ParseTable.yycheck);
   mm_stos := listArray(ParseTable.yystos);

   pt := PARSE_TABLE(mm_translate,mm_prhs,mm_rhs,mm_rline,mm_tname,mm_toknum,mm_r1,mm_r2
       ,mm_defact,mm_defgoto,mm_pact,mm_pgoto,mm_table,mm_check,mm_stos,fileName);
   stateStk := {0};
   errStk := {};
   astStk := ParseCode.initAstStack();
   env := ENV(emptyTok1,emptyTok1,stateStk,errStk,0,0,0,tokens,{},stateStk,astStk);


   while (List.isEmpty(tokens1)==false) loop
     if (debug) then
       print("\nTokens remaining:");
       print(intString(listLength(tokens1)));
     end if;
    // printAny("\nTokens remaining:");
    // printAny(intString(listLength(tokens)));
     (tokens1,env,astStk,result) := processToken(tokens1,env,astStk,pt);
     if (result==false) then
       break;
     end if;
   end while;

   ParseCode.ASTSTACK(stack={ast}) := astStk;

    if (debug) then
       printAny(ast);
    end if;

    /*if (result==true) then
       print("\n SUCCEED - (AST)");
    else
       print("\n FAILED PARSING");
    end if;*/
end parse;

function addSourceMessage
  input list<String> errStk;
  input OMCCTypes.Info info;
algorithm
    Error.addSourceMessage(Error.COMPILER_ERROR,errStk,info);
    //print(printSemStack(listReverse(errStk),""));
end addSourceMessage;

function printErrorMessages
  input list<String> errStk;
algorithm
   // print("\n ***ERROR(S) FOUND*** ");
   // print(printSemStack(listReverse(errStk),""));
end printErrorMessages;

function processToken
  input list<OMCCTypes.Token> tokens;
  input Env env;
  input ParseCode.AstStack inAstStk;
  input ParseData pt;
  output list<OMCCTypes.Token> rTokens;
  output Env env2;
  output ParseCode.AstStack astStk := inAstStk;
  output Boolean result;
protected
  list<OMCCTypes.Token> tokens1:=tokens;
  list<OMCCTypes.Token> tempTokens;
  // parse tables
  array<String> mm_tname;
  array<Integer> mm_translate, mm_prhs, mm_rhs, mm_rline, mm_toknum, mm_r1, mm_r2, mm_defact, mm_defgoto,
                 mm_pact, mm_pgoto, mm_table, mm_check, mm_stos;
  // env variables
  OMCCTypes.Token cTok,nTk;
  ParseCode.AstStack astSkBk;
  list<Integer> stateStk,stateSkBk;
  list<String> errStk;
  String astTmp;
  Integer sSt,cSt,lSt,errSt,cFinal,cPactNinf,cTableNinf;
  list<OMCCTypes.Token> prog,prgBk;
algorithm
  PARSE_TABLE(translate=mm_translate,prhs=mm_prhs,rhs=mm_rhs,rline=mm_rline,tname=mm_tname,toknum=mm_toknum,r1=mm_r1,r2=mm_r2
       ,defact=mm_defact,defgoto=mm_defgoto,pact=mm_pact,pgoto=mm_pgoto,table=mm_table,check=mm_check,stos=mm_stos) := pt;

  ENV(crTk=cTok,lookAhTk=nTk,state=stateStk,errMessages=errStk,errStatus=errSt,
     sState=sSt,cState=cSt,program=prog,progBk=prgBk,stateBackup=stateSkBk,astStackBackup=astSkBk):= env;
  if (debug) then
    print("\n[State:" + intString(cSt) +"]{" + printStack(stateStk,"") + "}\n");
  end if;

  // Start the LALR(1) Parsing
  cFinal := ParseTable.YYFINAL;
  cPactNinf := ParseTable.YYPACT_NINF;
  cTableNinf := ParseTable.YYTABLE_NINF;
  prog := tokens1;
  // cFinal==cSt is a final state? then ACCEPT
  // mm_pact[cSt]==cPactNinf if this REDUCE or ERROR
  result := true;
  env2 := env;
  (rTokens,result) := match (tokens,pt,cFinal==cSt,arrayGet(mm_pact,cSt+1)==cPactNinf)
     local
       list<OMCCTypes.Token> rest;
       list<Integer> vl;
       OMCCTypes.Token c =cTok;
       OMCCTypes.Token nt =nTk;
       Integer n,len,val,tok,tmTok,chkVal;
       String nm,semVal;
       Absyn.Ident idVal;
    case ({},_,false,false)
       equation
         c =cTok;
         nt =nTk;
         if (debug) then
           print("\nNow at end of input:\n");
         end if;
         n = arrayGet(mm_pact,cSt+1);
         rest = {};
         if (debug) then
           print("[n:" + intString(n) + "]");
         end if;
         if (n < 0 or ParseTable.YYLAST < n or arrayGet(mm_check,n+1) <> 0) then
           //goto yydefault;
           n = arrayGet(mm_defact,cSt+1);
           if (n==0) then
             // Error Handler
             if (debug) then
                print("\n Syntax Error found yyerrlab5:" + intString(errSt));
                //printAny("\n Syntax Error found yyerrlab5:" + intString(errSt));
             end if;
             if (errSt>=0) then
               (env2,semVal,result) = errorHandler(cTok,env,pt);
               ENV(crTk=cTok, lookAhTk=nTk, state=stateStk, errMessages=errStk, errStatus=errSt, sState=sSt, cState=cSt, program=prog, progBk=prgBk, stateBackup=stateSkBk, astStackBackup=astSkBk)= env2;
             else
                result=false;
             end if;
           end if;
             if (debug) then
               print(" REDUCE4");
             end if;
             (env2,astStk)=reduce(n,env,astStk,pt);
             ENV(crTk=cTok,lookAhTk=nTk,state=stateStk,errMessages=errStk,errStatus=errSt,sState=sSt,cState=cSt,
               program=prog,progBk=prgBk,stateBackup=stateSkBk,astStackBackup=astSkBk)= env2;

         else
           n = arrayGet(mm_table,n+1);
           if (n<=0) then
             if (n==0 or n==cTableNinf) then
               // Error Handler
               if (debug) then
                  print("\n Syntax Error found yyerrlab4:" + intString(n));
               end if;
               if (errSt>=0) then
                  (env2,semVal,result) = errorHandler(cTok,env,pt);
               else
                  result = false;
               end if;
               ENV(crTk=cTok, lookAhTk=nTk, state=stateStk, errMessages=errStk, errStatus=errSt, sState=sSt, cState=cSt, program=prog, progBk=prgBk, stateBackup=stateSkBk, astStackBackup=astSkBk)= env2;
             end if;
               n = -n;
               if (debug) then
                 print(" REDUCE5");
               end if;
               (env2,astStk)=reduce(n,env,astStk,pt);
               ENV(crTk=cTok, lookAhTk=nTk, state=stateStk, errMessages=errStk, errStatus=errSt, sState=sSt, cState=cSt, program=prog, progBk=prgBk, stateBackup=stateSkBk, astStackBackup=astSkBk)= env2;

           else
             if (debug) then
               print(" SHIFT");
             end if;
             if (errSt<0) then // reduce the shift error lookup
               if (debug) then
                 print("\n***-RECOVERY TOKEN INSERTED IS SHIFTED-***");
               end if;
                errSt = maxErrRecShift;
             end if;
             cSt = n;
             stateStk = cSt::stateStk;
             env2 = ENV(c,nt,stateStk,errStk,errSt,sSt,cSt,rest,rest,stateSkBk,astSkBk);

           end if;
         end if;
         if (result==true and errSt>maxErrRecShift) then //stops when it finds and error
            if (debug) then
              print("\nReprocesing at the END");
            end if;
            (rest,env2,astStk,result) = processToken(rest,env2,astStk,pt);
         end if;

        then ({},result);
     case (_,_,true,_)
       equation
         if (debug) then
            print("\n\n***************-ACCEPTED-***************\n");
         end if;
         result = true;
         if (List.isEmpty(errStk)==false) then
           printErrorMessages(errStk);
           result = false;
         end if;
       then ({},result);
     case (_,_,false,true)
       equation
          n = arrayGet(mm_defact,cSt+1);
          if (n == 0) then
            // Error Handler
             if (debug) then
                print("\n Syntax Error found yyerrlab3:" + intString(n));
             end if;
             if (errSt>=0) then
                  (env2,semVal,result) = errorHandler(cTok,env,pt);
                  ENV(crTk=cTok,lookAhTk=nTk,state=stateStk,errMessages=errStk,errStatus=errSt,sState=sSt,cState=cSt, program=prog,progBk=prgBk,stateBackup=stateSkBk,astStackBackup=astSkBk)= env2;
               else
                  result = false;
               end if;
          end if;
           // reduce;
           if (debug) then
              print("REDUCE3");
           end if;

           (env2,astStk)=reduce(n,env,astStk,pt);

           if (result==true) then //stops when it finds and error
              (rest,env2,astStk,result) = processToken(tokens,env2,astStk,pt);
           end if;

      then (rest,result);
     case (_,_,false,false)
       equation
          /* Do appropriate processing given the current state.  Read a
            lookahead token if we need one and don't already have one.  */
          c::rest = tokens1;
          cTok = c;
          OMCCTypes.TOKEN(id=tmTok,name=nm) = c;
          tok = translate(tmTok,pt);

          /* First try to decide what to do without reference to lookahead token.  */

          n = arrayGet(mm_pact,cSt+1);
          if (debug) then
             print("[n:" + intString(n) + "-");
          end if;

          n = n + tok;
          if (debug) then
             print("NT:" + intString(n) + "]");
          end if;
          chkVal = n+1;
          if (chkVal<=0) then
             chkVal = 1;
          end if;
         if (n < 0 or ParseTable.YYLAST < n or arrayGet(mm_check,chkVal) <> tok) then
           //goto yydefault;
           n = arrayGet(mm_defact,cSt+1);
           if (n==0) then
               // Error Handler
               if (debug) then
                  print("\n Syntax Error found yyerrlab2:" + intString(n));
               end if;
               if (errSt>=0) then
                  (env2,semVal,result) = errorHandler(cTok,env,pt);
                  ENV(crTk=cTok,lookAhTk=nTk,state=stateStk,errMessages=errStk,errStatus=errSt,sState=sSt,cState=cSt,program=prog,progBk=prgBk,stateBackup=stateSkBk,astStackBackup=astSkBk)= env2;
               else
                  errSt = maxErrRecShift;
                  result = false;
               end if;
           else
               if (debug) then
                  print(" REDUCE2");
               end if;
               (env2,astStk)=reduce(n,env,astStk,pt);
               ENV(crTk=cTok,lookAhTk=nTk,state=stateStk,errMessages=errStk,errStatus=errSt,sState=sSt,cState=cSt,program=prog,progBk=prgBk,stateBackup=stateSkBk,astStackBackup=astSkBk)= env2;
               rest = tokens1;
           end if;
         else
           // try to get the value for the action in the table array
           n = arrayGet(mm_table,n+1);
           if (n<=0) then
             //
             if (n==0 or n==cTableNinf) then
               // Error Handler
               if (debug) then
                 print("\n Syntax Error found yyerrlab:" + intString(n));
               end if;
               if (errSt>=0) then
                  (env2,semVal,result) = errorHandler(cTok,env,pt);
                  ENV(crTk=cTok,lookAhTk=nTk,state=stateStk,errMessages=errStk,errStatus=errSt,sState=sSt,cState=cSt,program=prog,progBk=prgBk,stateBackup=stateSkBk,astStackBackup=astSkBk)= env2;
               else
                  result = false;
                  errSt = maxErrRecShift;
               end if;
             else
               n = -n;
               if (debug) then
                   print(" REDUCE");
               end if;
               (env2,astStk)=reduce(n,env,astStk,pt);
               ENV(crTk=cTok,lookAhTk=nTk,state=stateStk,errMessages=errStk,errStatus=errSt,sState=sSt,cState=cSt,program=prog,progBk=prgBk,stateBackup=stateSkBk,astStackBackup=astSkBk)= env2;
               rest = tokens1;
             end if;
           else
             if (debug) then
                print(" SHIFT1");
             end if;
             cSt = n;
             stateStk = cSt::stateStk;
             astStk = ParseCode.push(astStk,cTok);
             astSkBk = astStk;
             stateSkBk = stateStk;
             if (errSt<>0) then // reduce the shift error lookup
                errSt = errSt - 1;
             end if;
             env2 = ENV(c,nt,stateStk,errStk,errSt,sSt,cSt,rest,rest,stateSkBk,astSkBk);
           end if;
         end if;


         if (errSt<>0 or List.isEmpty(rest)) then
           if ((result==true) and (errSt>maxErrRecShift)) then //stops when it finds and error
             (rest,env2,astStk,result) = processToken(rest,env2,astStk,pt);
           end if;
         end if;
     then (rest,result);
    end match;
   // return the AST

end processToken;

function errorHandler
  input OMCCTypes.Token currTok;
  input Env env;
  input ParseData pt;
  output Env env2;
  output String errorMsg;
  output Boolean result;
  // env variables
protected
  OMCCTypes.Token cTok,nTk;
  ParseCode.AstStack astSkBk;
  Integer sSt,cSt,errSt;
  list<OMCCTypes.Token> prog,prgBk;
  list<Integer> stateStk,stateSkBk;
  list<String> errStk;
   // parse tables
  array<String> mm_tname;
  array<Integer> mm_translate, mm_prhs, mm_rhs, mm_rline, mm_toknum, mm_r1, mm_r2, mm_defact, mm_defgoto,
                 mm_pact, mm_pgoto, mm_table, mm_check, mm_stos;

  list<String> redStk;
  Integer numTokens;
  String msg,semVal,fileName;

algorithm
   PARSE_TABLE(fileName=fileName,translate=mm_translate,prhs=mm_prhs,rhs=mm_rhs,rline=mm_rline,tname=mm_tname,toknum=mm_toknum,r1=mm_r1,r2=mm_r2
       ,defact=mm_defact,defgoto=mm_defgoto,pact=mm_pact,pgoto=mm_pgoto,table=mm_table,check=mm_check,stos=mm_stos) := pt;

  ENV(crTk=cTok,lookAhTk=nTk,state=stateStk,sState=sSt,errMessages=errStk,errStatus=errSt,cState=cSt,
        program=prog,progBk=prgBk,stateBackup=stateSkBk,astStackBackup=astSkBk):= env;

  if (debug) then
     print("\nERROR RECOVERY INITIATED:");
     print("\n[State:" + intString(cSt) +"]{" + printStack(stateStk,"") + "}\n");
     print("\n[StateStack Backup:{" + printStack(stateSkBk,"") + "}\n");
  end if;
  semVal := OMCCTypes.printToken(currTok);
  (errorMsg,result) := matchcontinue(errSt==0,prog)
    local
       String erMsg,name;
       list<String> candidates;
       list<OMCCTypes.Token> rest;
       Integer i,idTok;
       OMCCTypes.Info info;
    case (true,{}) //start error catching
      equation
         erMsg = OMCCTypes.printErrorToken(currTok);
         // insert token
         if (debug) then
            print("\n Checking INSERT at the END token:");
            //printAny("\n Checking INSERT at the END token:");
         end if;
         candidates = {};
         candidates = checkCandidates(candidates,env,pt,3);
         if (List.isEmpty(candidates)==false) then
             erMsg = erMsg + ", INSERT at the End token " + printCandidateTokens(candidates,"") ;
         end if;
         errStk = erMsg::errStk;

         info = OMCCTypes.makeInfo(currTok,fileName);
         addSourceMessage(errStk,info);

         printErrorMessages(errStk);
         errSt = maxErrShiftToken;
      then (erMsg,false); //end error catching
    case (true,_) //start error catching
      equation

         //OMCCTypes.TOKEN(id=idTok) = currTok;
         //erMsg = OMCCTypes.printErrorToken(currTok);
         erMsg = OMCCTypes.printErrorLine(currTok);

        if (debug) then
            print("\n Check MERGE token until next token");
         end if;
         nTk::_ = prog;
         OMCCTypes.TOKEN(id=idTok) = nTk;
         if (checkToken(idTok,env,pt,5)==true) then
            _::nTk::_ = prog;
            erMsg = erMsg + ", MERGE tokens " + OMCCTypes.printShortToken(currTok)
              + " and " +  OMCCTypes.printShortToken(nTk);
         end if;

         // insert token
         if (debug) then
            print("\n Checking INSERT token:");
         end if;
         candidates = {};
         candidates = checkCandidates(candidates,env,pt,2);
         if (List.isEmpty(candidates)==false) then
             erMsg = OMCCTypes.printErrorLine2(currTok);
             erMsg = erMsg + ", INSERT token " + printCandidateTokens(candidates,"");
             //errStk = erMsg::errStk;
         end if;

         errSt = maxErrShiftToken;

        // replace token
        // erMsg = "Syntax Error near " + semVal;
         if (debug) then
            print("\n Checking REPLACE token:");
         end if;
         candidates = {};
         candidates = checkCandidates(candidates,env,pt,3);
         if (List.isEmpty(candidates)==false) then
           erMsg = erMsg + ", REPLACE token with " + printCandidateTokens(candidates,"");
           //errStk = erMsg::errStk;
         end if;

         errSt = maxErrShiftToken;

          // try to supress the token
         // erMsg = "Syntax Error near " + semVal;
         if (debug) then
            print("\n Check ERASE token until next token");
         end if;
         nTk::_ = prog;
         OMCCTypes.TOKEN(id=idTok) = nTk;
         if (checkToken(idTok,env,pt,1)==true) then
            erMsg = erMsg + ", ERASE token" + " " + OMCCTypes.printShortToken(currTok);
            //errStk = erMsg::errStk;
         end if;
         //printAny(errStk);
         if (List.isEmpty(errStk)==true) then
            errStk = erMsg::{};
         else
             errStk = erMsg::errStk;
         end if;
         info = OMCCTypes.makeInfo(currTok,fileName);
         addSourceMessage(errStk,info);
         errSt = maxErrShiftToken;
      then (erMsg,true); //end error catching
    case (false,_) // add one more error
      equation
         printErrorMessages(errStk);
         erMsg = OMCCTypes.printErrorToken(currTok);
      then (erMsg,false);
  end matchcontinue;
  if (debug==true) then
     print("\nERROR NUM:" + intString(errSt) +" DETECTED:\n" + errorMsg);
  end if;
  env2 := ENV(cTok,nTk,stateStk,errStk,errSt,sSt,cSt,prog,prgBk,stateSkBk,astSkBk);
  //env2 := env;
end errorHandler;

function checkCandidates
  input list<String> candidates;
  input Env env;
  input ParseData pt;
  input Integer action;
  output list<String> resCandidates;
  protected
  list<String> candidates1:=candidates;
  Integer n;
   // env variables
  OMCCTypes.Token cTok,nTk;
  ParseCode.AstStack astSkBk;
  Boolean debug;
  Integer sSt,cSt,errSt;
  list<OMCCTypes.Token> prog,prgBk;
  list<Integer> stateStk,stateSkBk;
  list<String> errStk;
   // parse tables
  array<String> mm_tname;
  array<Integer> mm_translate, mm_prhs, mm_rhs, mm_rline, mm_toknum, mm_r1, mm_r2, mm_defact, mm_defgoto,
                 mm_pact, mm_pgoto, mm_table, mm_check, mm_stos;

  Integer numTokens,i,j=1;
  String name,tokVal;
 algorithm
    PARSE_TABLE(tname=mm_tname) := pt;

    resCandidates := candidates1;
    numTokens := 255 + ParseTable.YYNTOKENS - 1;
    // exhaustive search over the tokens
    for i in 258:numTokens loop
      if (checkToken(i,env,pt,action)==true) then
         //name := mm_tname[i-255];
         if (j<=maxCandidateTokens) then
           tokVal := getTokenSemValue(i-255,pt);
           resCandidates := tokVal::resCandidates;
           j := j+1;
         else
           i := numTokens+1;
         end if;
      end if;
    end for;
end checkCandidates;

function checkToken
  input Integer chkTok;
  input Env env;
  input ParseData pt;
  input Integer action; // 1 delete 2 insert 3 replace
  output Boolean result;
protected
  Integer n;
   // env variables
  OMCCTypes.Token cTok,nTk;
  ParseCode.AstStack astSkBk;
  Integer sSt,cSt,errSt;
  list<OMCCTypes.Token> prog,prgBk;
  list<Integer> stateStk,stateSkBk;
  list<String> errStk;
   // parse tables
  array<String> mm_tname;
  array<Integer> mm_translate, mm_prhs, mm_rhs, mm_rline, mm_toknum, mm_r1, mm_r2, mm_defact, mm_defgoto,
                 mm_pact, mm_pgoto, mm_table, mm_check, mm_stos;
  Integer chk2;
  Env env2;
  OMCCTypes.Info info;
  OMCCTypes.Token candTok;
 algorithm
    PARSE_TABLE(translate=mm_translate,prhs=mm_prhs,rhs=mm_rhs,rline=mm_rline,tname=mm_tname,toknum=mm_toknum,r1=mm_r1,r2=mm_r2
       ,defact=mm_defact,defgoto=mm_defgoto,pact=mm_pact,pgoto=mm_pgoto,table=mm_table,check=mm_check,stos=mm_stos) := pt;

   ENV(crTk=cTok,lookAhTk=nTk,state=stateStk,sState=sSt,errMessages=errStk,errStatus=errSt,cState=cSt,program=prog,
         progBk=prgBk,stateBackup=stateSkBk,astStackBackup=astSkBk):= env;

   if (debug) then
      print("\n **** Checking TOKEN: " + intString(chkTok) + " action:" + intString(action));
      //printAny("\n **** Checking TOKEN: " + intString(chkTok) + " action:" + intString(action));
   end if;
  // restore back up configuration and run the machine again to check candidate
   if (List.isEmpty(prog)==false) then
     cTok::prog := prog;
     if (debug) then
        print("\n **** Last token: " + OMCCTypes.printToken(cTok));
     end if;
     candTok := OMCCTypes.TOKEN(arrayGet(mm_tname,chkTok-255),chkTok,"",1,0,0,0,0,0);
   else
     if (debug) then
        print("\n Creating Fake Token position");
     end if;
     candTok := OMCCTypes.TOKEN(arrayGet(mm_tname,chkTok-255),chkTok,"",1,0,0,0,0,0);
   end if;

   if (debug) then
      print("\n **** Process candidate token: " + OMCCTypes.printToken(candTok) + " action: " + intString(action));
   end if;

   (prog) := matchcontinue(action)
     local
        String value;
        list<OMCCTypes.Token> lstTokens;
     case (5) // Merge
       equation
          if (List.isEmpty(prog)==false) then
             candTok::prog = prog;
             value = OMCCTypes.getMergeTokenValue(cTok,candTok);
             lstTokens = Lexer.lex("fileName",value);
             candTok::_ = lstTokens;
             prog = candTok::prog;
          end if;
       then (prog);
     case (2) // Insert
       equation
           prog = candTok::cTok::prog;
       then (prog);
     case (3) // replace
       equation
           prog = candTok::prog;
       then (prog);
   else then (prog);
   end matchcontinue;

   cSt::_ := stateSkBk;
   errStk := {}; //reset errors
   errSt := -1; // no errors reset
   // backup the env variables to the last shifted token
   env2 := ENV(cTok,nTk,stateSkBk,errStk,errSt,sSt,cSt,prog,prgBk,stateSkBk,astSkBk);
   //printAny(env2);

   result := false;
   if (debug) then
      //print("\n\n*****ProcessTOKENS:" + OMCCTypes.printTokens(prog,"") + " check" + intString(chkTok));
   end if;
   //print("\n[State="+ intString(cSt) + " Stack Backup:{" + printStack(stateSkBk,"") + "}]\n");
   //print("\n[StateStack Backup:{" + printStack(stateSkBk,"") + "}\n");

   (_,_,_,result) := processToken(prog,env2,astSkBk,pt);

   if (result and debug) then
      print("\n **** Candidate TOKEN ADDED: " + intString(chkTok));
   end if;
end checkToken;

function reduce
  input Integer rule;
  input Env env;
  input ParseCode.AstStack inAstStk;
  input ParseData pt;
  output Env env2;
  output ParseCode.AstStack astStk := inAstStk;
protected
  // parse tables
  array<String> mm_tname;
  array<Integer> mm_translate, mm_prhs, mm_rhs, mm_rline, mm_toknum, mm_r1, mm_r2, mm_defact, mm_defgoto,
                 mm_pact, mm_pgoto, mm_table, mm_check, mm_stos;
  // env variables
  OMCCTypes.Token cTok,nTk;
  ParseCode.AstStack astSkBk;
  Boolean error;
  list<Integer> stateStk,stateSkBk;
  list<String> errStk,redStk;
  String astTmp,semVal,errMsg,fileName;
  Integer errSt,sSt,cSt;
  list<OMCCTypes.Token> prog,prgBk;
  Integer i,len,val,n, nSt,chkVal;
algorithm
  PARSE_TABLE(translate=mm_translate,prhs=mm_prhs,rhs=mm_rhs,rline=mm_rline,tname=mm_tname,toknum=mm_toknum,r1=mm_r1,r2=mm_r2
       ,defact=mm_defact,defgoto=mm_defgoto,pact=mm_pact,pgoto=mm_pgoto,table=mm_table,check=mm_check,stos=mm_stos,fileName=fileName) := pt;

  ENV(crTk=cTok,lookAhTk=nTk,state=stateStk /* changes */,sState=sSt,errMessages=errStk /* changes */,
      errStatus=errSt /* changes */,cState=cSt /* changes */,program=prog,progBk=prgBk,
      stateBackup=stateSkBk,astStackBackup=astSkBk):= env;
  if rule > 0 then
    len := arrayGet(mm_r2,rule);
    if (debug) then
      print("[Reducing(l:" + intString(len) + ",r:" + intString(rule) +")]");
    end if;
    redStk := {};
    for i in 1:len loop
      val::stateStk := stateStk;
    end for;
    if (errSt>=0) then
    (astStk,error,errMsg) := ParseCode.actionRed(rule,astStk,fileName);
    end if;
    if (error) then
      errStk := errMsg::errStk;
      errSt := maxErrShiftToken;
    end if;

    cSt::_ := stateStk;

    n := arrayGet(mm_r1,rule);

    nSt := mm_pgoto[n - ParseTable.YYNTOKENS + 1];
    nSt := nSt + cSt;
    chkVal := nSt +1;
    if (chkVal<=0) then
      chkVal := 1;
    end if;
    if ( (nSt >=0) and (nSt <= ParseTable.YYLAST) and (arrayGet(mm_check,chkVal) == cSt) ) then
      cSt := arrayGet(mm_table,nSt+1);
    else
      cSt := arrayGet(mm_defgoto,n - ParseTable.YYNTOKENS+1);
    end if;
    if (debug) then
     print("[nState:" + intString(cSt) + "]");
    end if;
    stateStk := cSt::stateStk;
  end if;
  env2 := ENV(cTok,nTk,stateStk,errStk,errSt,sSt,cSt,prog,prgBk,stateSkBk,astSkBk);
end reduce;

function translate
  input Integer tok1;
  input ParseData pt;
  output Integer tok2;
  protected
  ParseData pt1:=pt;
  array<Integer> mm_translate;
  Integer maxT,uTok;
  algorithm
    PARSE_TABLE(translate=mm_translate) := pt1;
    maxT := ParseTable.YYMAXUTOK;
    uTok := ParseTable.YYUNDEFTOK;
    (tok2) := matchcontinue(tok1<=maxT)
       local
         Integer res;
      case (true)
        equation

          res = arrayGet(mm_translate,tok1);
          //print("\nTRANSLATE TO:" + intString(res));
        then (res);
      case (false)
        then (uTok);
    end matchcontinue;
end translate;

function getTokenSemValue "retrieves semantic value from token id"
  input Integer tokenId;
  input ParseData pt;
  output String tokenSemValue "returns semantic value of the token";
  protected
  array<String> values;
  algorithm

    if (List.isEmpty(ParseCode.lstSemValue)==true) then
       PARSE_TABLE(tname=values) := pt;
    else
       values := listArray(ParseCode.lstSemValue);
    end if;
    tokenSemValue := "'" + arrayGet(values,tokenId) + "'";
end getTokenSemValue;

function printBuffer
  input list<Integer> inList;
  output String outList;
  protected
  list<Integer> inList1:=inList;
  Integer c:=0;
algorithm
  outList := stringAppendList(list(intStringChar(c) for c in inList1));
end printBuffer;

  function printSemStack
    input list<String> inList;
    input String cBuff;
    output String outList;
    protected
    list<String> inList1:=inList;
   algorithm
    (outList) := matchcontinue(inList,cBuff)
      local
        String c;
        String new,tout;
        list<String> rest;
      case ({},_)
        then (cBuff);
      else
        equation
           c::rest = inList1;
           new = cBuff + "\n" + c;
           (tout) = printSemStack(rest,new);
        then (tout);
     end matchcontinue;
  end printSemStack;

    function printCandidateTokens
    input list<String> inList;
    input String cBuff;
    output String outList;
    protected
    list<String> inList1:=inList;
    String cBuff1:=cBuff;
   algorithm
    (outList) := matchcontinue(inList,cBuff)
      local
        String c;
        String new,tout;
        list<String> rest;
      case ({},_)
        equation
           cBuff1 = System.substring(cBuff1,1,stringLength(cBuff1)-4);
        then (cBuff1);
      else
        equation
           c::rest = inList1;
           new = cBuff1 + c + " or ";
           (tout) = printCandidateTokens(rest,new);
        then (tout);
     end matchcontinue;
  end printCandidateTokens;

  function printStack
    input list<Integer> inList;
    input String cBuff;
    output String outList;
    protected
    list<Integer> inList1:=inList;
   algorithm
    (outList) := matchcontinue(inList,cBuff)
      local
        Integer c;
        String new,tout;
        list<Integer> rest;
      case ({},_)
        then (cBuff);
      else
        equation
           c::rest = inList1;
           new = cBuff + "|" + intString(c);
           (tout) = printStack(rest,new);
        then (tout);
     end matchcontinue;
  end printStack;
end Parser;

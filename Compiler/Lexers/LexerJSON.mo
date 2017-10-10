encapsulated package LexerJSON "Automatically generated lexer based on flex, generated OMCCp v0.11.0 OpenModelica lexer and parser generator (2015)"
  /*
   Template for Lexer Code
   replace keywords:
   %LexerCode
   %time
   %Token
   %Lexer
   %LexTable
   %constant
   %nameSpan
   %functions
   %caseAction
  */

import System;

constant Boolean debug = false;

replaceable package LexTable
  constant Integer yy_limit;
  constant Integer yy_finish;
  constant Integer yy_acclist[:];
  constant Integer yy_accept[:];
  constant Integer yy_ec[:];
  constant Integer yy_meta[:];
  constant Integer yy_base[:];
  constant Integer yy_def[:];
  constant Integer yy_nxt[:];
  constant Integer yy_chk[:];
end LexTable;

function scan "Scan starts the lexical analysis, load the tables and consume the program to output the tokens"
  input String fileName "input source code file";
  output list<Token> tokens "return list of tokens";
  output list<Token> errorTokens;
protected
  String contents;
algorithm
  contents := System.readFile(fileName);
  (tokens, errorTokens) := lex(fileName,contents);
end scan;

function scanString "Scan starts the lexical analysis, load the tables and consume the program to output the tokens"
  input String fileSource "input source code file";
  input String fileName = "<StringSource>";
  output list<Token> tokens "return list of tokens";
  output list<Token> errorTokens;
algorithm
  (tokens, errorTokens) := lex(fileName,fileSource);
end scanString;


/* grammar according to json.org */
protected
import Error;
import StringUtil;
public
function action
  input Integer act;
  input Integer startSt;
  input Integer mm_currSt,mm_pos,mm_sPos,mm_ePos,mm_linenr,lineNrStart;
  input Integer buffer;
  input Boolean debug;
  input String fileNm;
  input String fileContents;
  input list<Token> inErrorTokens;
  output Token token;
  output Integer mm_startSt;
  output Integer bufferRet;
  output list<Token> errorTokens=inErrorTokens;
protected
  SourceInfo info;
  String sToken;
algorithm
  mm_startSt := startSt;
  // nameSpan := 255;
  bufferRet := 0;
  (token) := match (act)
    local
      Token tok;
    case (1) // #line 25 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.STRING,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (2) // #line 26 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.STRING,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (3) // #line 27 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.NUMBER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (4) // #line 28 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.NUMBER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (5) // #line 29 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.INTEGER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (6) // #line 30 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.TRUE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (7) // #line 31 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.FALSE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (8) // #line 32 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.NULL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (9) // #line 33 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.OBJECTBEGIN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (10) // #line 34 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.OBJECTEND,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (11) // #line 36 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.ARRAYBEGIN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (12) // #line 38 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.ARRAYEND,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (13) // #line 40 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.COMMA,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (14) // #line 41 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.COLON,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (15) // #line 43 "lexerJSON.l"
      algorithm
      then noToken;
    case (16) // #line 45 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId._NO_TOKEN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
        errorTokens := tok :: errorTokens;
      then noToken;

    else
      algorithm
        print("\nLexer unknown rule, action="+String(act)+"\n");
        tok := TOKEN(fileNm,TokenId._NO_TOKEN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
        print(printToken(tok));
      then fail();
  end match;
end action;

type TokenId = enumeration(
  _NO_TOKEN,
  ARRAYBEGIN,
  ARRAYEND,
  COLON,
  COMMA,
  FALSE,
  INTEGER,
  NULL,
  NUMBER,
  OBJECTBEGIN,
  OBJECTEND,
  STRING,
  TRUE
);

uniontype Token
  record TOKEN
    String fileName;
    TokenId id;
    String fileContents;
    Integer byteOffset,length;
    Integer lineNumberStart;
    Integer columnNumberStart;
    Integer lineNumberEnd;
    Integer columnNumberEnd;
  end TOKEN;
end Token;

constant Token noToken = TOKEN("<NoFile>",TokenId._NO_TOKEN,"",0,0,0,0,0,0);

function printToken
  input Token token;
  output String strTk;
protected
  TokenId id;
  String contents;
  Integer byteOffset,length;
algorithm
  TOKEN(id=id, fileContents=contents, byteOffset=byteOffset, length=length) := token;
  contents := if length>0 then substring(contents,byteOffset,byteOffset+length-1) else "";
  strTk := "[TOKEN:" + String(id) + " '" +  contents +"' (" + intString(token.lineNumberStart) + ":" + intString(token.columnNumberStart) + "-"+ intString(token.lineNumberEnd) + ":" + intString(token.columnNumberEnd) +")]";
end printToken;

function tokenContent
  input Token token;
  output String contents;
protected
  Integer byteOffset,length;
algorithm
  TOKEN(fileContents=contents,byteOffset=byteOffset,length=length) := token;
  contents := if length>0 then substring(contents,byteOffset,byteOffset+length-1) else "";
end tokenContent;

function tokenContentEq
  input Token token1, token2;
  output Boolean b;
protected
  String contents1,contents2;
  Integer offset1,length1,offset2,length2;
algorithm
  TOKEN(fileContents=contents1,byteOffset=offset1,length=length1) := token1;
  TOKEN(fileContents=contents2,byteOffset=offset2,length=length2) := token2;
  // We do not need to know in which order to sort. If lengths differ, the tokens differ
  b := if length1 <> length2 then false else (0 == System.strcmp_offset(contents1, offset1, length1, contents2, offset2, length2));
end tokenContentEq;

function tokenSourceInfo
  input Token token;
  output SourceInfo info;
algorithm
  info := match t as token
    case TOKEN() then SOURCEINFO(t.fileName, false, t.lineNumberStart, t.columnNumberStart, t.lineNumberEnd, t.columnNumberEnd, 0.0);
  end match;
end tokenSourceInfo;

protected

function lex "Scan starts the lexical analysis, load the tables and consume the program to output the tokens"
  input String fileName "input source code file";
  input String contents;
  output list<Token> tokens "return list of tokens";
  output list<Token> errorTokens={};
protected
  Integer startSt,numStates,i,r,cTok,cTok2,currSt,pos,sPos,ePos,linenr,contentLen,numBacktrack,buffer,lineNrStart;
  list<Integer> cProg,cProg2;
  list<String> chars;
  array<Integer> states;
  String s1,s2;
  import MetaModelica.Dangerous.listReverseInPlace;
  import stringGet = MetaModelica.Dangerous.stringGetNoBoundsChecking;
algorithm
  // load arrays

  // Initialize the Env Variables
  startSt := 1;
  currSt := 1;
  pos := 1;
  sPos := 0;
  ePos := 0;
  linenr := 1;
  lineNrStart := 1;
  buffer := 0;

  states := arrayCreate(128,1);
  numStates := 1;

  if (debug==true) then
     print("\nLexer analyzer LexerCode..." + fileName + "\n");
     //printAny("\nLexer analyzer LexerCode..." + fileName + "\n");
  end if;

  tokens := {};
  if (debug) then
    print("\n TOTAL Chars:");
    print(intString(stringLength(contents)));
  end if;
  contentLen := stringLength(contents);
  i := 1;
  while i <= contentLen loop
     cTok := stringGet(contents,i);
     (tokens,numBacktrack,startSt,currSt,pos,sPos,ePos,linenr,lineNrStart,buffer,states,numStates,errorTokens) := consume(cTok,tokens,contents,startSt,currSt,pos,sPos,ePos,linenr,lineNrStart,buffer,states,numStates,fileName,errorTokens);
     i := i - numBacktrack + 1;
  end while;
  tokens := listReverseInPlace(tokens);
  errorTokens := listReverseInPlace(errorTokens);
end lex;

function consume
  input Integer cp;
  input list<Token> tokens;
  input String fileContents;
  input Integer startSt;
  input Integer currSt,pos,sPos,ePos,linenr,inLineNrStart;
  input Integer inBuffer;
  input array<Integer> inStates;
  input Integer inNumStates;
  input String fileName;
  input list<Token> inErrorTokens;
  output list<Token> resToken;
  output Integer bkBuffer = 0;
  output Integer mm_startSt;
  output Integer mm_currSt,mm_pos,mm_sPos,mm_ePos,mm_linenr,lineNrStart;
  output Integer buffer;
  output array<Integer> states;
  output Integer numStates;
  output list<Token> errorTokens=inErrorTokens;
protected
  Token tok;
  Integer act,buffer2;
  Integer c,baseCond;
algorithm
  mm_startSt := startSt;
  mm_currSt := currSt;
  mm_pos := pos;
  mm_sPos := sPos;
  mm_ePos := ePos;
  mm_linenr := linenr;
  lineNrStart := inLineNrStart;
  buffer := inBuffer;
  states := inStates;
  numStates := inNumStates;

  baseCond := LexTable.yy_base[mm_currSt];
  if (debug==true) then
    print("\nPROGRAM:{" + intString(cp) + "} ");
    print("\nBUFFER:{" + intString(buffer) + "} ");
    print("base:" + intString(baseCond) + " st:" + intString(mm_currSt)+" ");
  end if;

  buffer := buffer+1;
  mm_pos := mm_pos+1;

  if (cp==10) then
    mm_linenr := mm_linenr+1;
    mm_sPos := 0;
  else
    mm_sPos := mm_sPos+1;
  end if;
  if (debug==true) then
    print("\n[Reading:'"  + intStringChar(cp) +"' at p:" + intString(mm_pos-1) + " line:"+ intString(mm_linenr) + " rPos:" + intString(mm_sPos) +"]");
  end if;
  c := LexTable.yy_ec[cp];

  if (debug==true) then
    print(" evalState Before[c" + intString(c) + ",s"+ intString(mm_currSt)+"]");
  end if;
  (mm_currSt,c) := evalState(mm_currSt,c);
  if (debug==true) then
    print(" After[c" + intString(c) + ",s"+ intString(mm_currSt)+"]");
  end if;
  if (mm_currSt>0) then
    mm_currSt := LexTable.yy_base[mm_currSt];
    // print("BASE:"+ intString(mm_currSt)+"]");
    mm_currSt := LexTable.yy_nxt[mm_currSt + c];
    // print("NEXT:"+ intString(mm_currSt)+"]");
  else
    mm_currSt := LexTable.yy_nxt[c];
  end if;
  numStates := numStates+1; // TODO: BAD BAD BAD. At least arrayUpdate should be a safe operation... We need to grow the number of states on demand though.
  arrayUpdate(states,numStates,mm_currSt);

  baseCond := LexTable.yy_base[mm_currSt];
  if (baseCond==LexTable.yy_finish) then
    if (debug==true) then
      print("\n[RESTORE=" + intString(LexTable.yy_accept[mm_currSt]) + "]");
    end if;

    (act, mm_currSt, mm_pos, mm_sPos, mm_linenr, buffer, bkBuffer, states, numStates) := findRule(fileContents, mm_currSt, mm_pos, mm_sPos, mm_ePos, mm_linenr, buffer, bkBuffer, states, numStates);

    if (debug==true) then
      print("\nFound rule: " + String(act));
    end if;

    (tok,mm_startSt,buffer2,errorTokens) := action(act,mm_startSt,mm_currSt,mm_pos,mm_sPos,mm_ePos,mm_linenr,lineNrStart,buffer,debug,fileName,fileContents,errorTokens);

    if (debug==true) then
      print("\nDid action");
    end if;

    mm_currSt := mm_startSt;
    arrayUpdate(states,1,mm_startSt);
    numStates := 1;

    /* Either a token was output (get new positions for next token). Or a whitespace was emitted. */
    if buffer <> buffer2 then
      mm_ePos := mm_sPos;
      lineNrStart := linenr;
    end if;
    buffer := buffer2;

    resToken := match tok
      case TOKEN(id=TokenId._NO_TOKEN) then tokens;
      else tok::tokens;
    end match;
    if(debug) then
      print("\n CountTokens:" + intString(listLength(resToken)));
    end if;
  else
     bkBuffer := 0; // consume the character
     resToken := tokens;
  end if;

end consume;


function findRule
  input String fileContents;
  input Integer currSt;
  input Integer pos;
  input Integer sPos;
  input Integer mm_ePos;
  input Integer linenr;
  input Integer inBuffer;
  input Integer inBkBuffer;
  input array<Integer> inStates;
  input Integer inNumStates;
  output Integer action;
  output Integer mm_currSt;
  output Integer mm_pos;
  output Integer mm_sPos;
  output Integer mm_linenr;
  output Integer buffer;
  output Integer bkBuffer;
  output array<Integer> states;
  output Integer numStates;
protected
  array<Integer> mm_accept,mm_ec,mm_meta,mm_base,mm_def,mm_nxt,mm_chk,mm_acclist;
  Integer lp,lp1,stCmp;
  Boolean st;
  import arrayGet = MetaModelica.Dangerous.arrayGetNoBoundsChecking; // Bounds checked with debug=true
  import stringGet = MetaModelica.Dangerous.stringGetNoBoundsChecking;
algorithm
  mm_currSt := currSt;
  mm_pos := pos;
  mm_sPos := sPos;
  mm_linenr := linenr;
  buffer := inBuffer;
  bkBuffer := inBkBuffer;
  states := inStates;
  numStates := inNumStates;

  stCmp := arrayGet(states,numStates);
  lp := LexTable.yy_accept[stCmp];
  lp1 := LexTable.yy_accept[stCmp+1];

  st := intGt(lp,0) and intLt(lp,lp1);
  (action, mm_currSt, mm_pos, mm_sPos, mm_linenr, buffer, bkBuffer, states, numStates) := match(numStates,st)
    local
      Integer act,cp;
      list<Integer> restBuff;
    case (_,true)
      algorithm
        if debug then
          checkArrayModelica(LexTable.yy_accept,stCmp,sourceInfo());
          checkArrayModelica(LexTable.yy_acclist,lp,sourceInfo());
        end if;
        lp := LexTable.yy_accept[stCmp];
        act := LexTable.yy_acclist[lp];
      then (act, mm_currSt, mm_pos, mm_sPos, mm_linenr, buffer, bkBuffer, states, numStates);
    case (_,false)
      algorithm
        cp := stringGet(fileContents,mm_pos-1);
        buffer := buffer-1;
        bkBuffer := bkBuffer+1;
        mm_pos := mm_pos - 1;
        mm_sPos := mm_sPos -1;
        if (cp==10) then
          mm_sPos := mm_ePos;
          mm_linenr := mm_linenr-1;
        end if;
        if debug then
          checkArray(states,numStates,sourceInfo());
        end if;
        mm_currSt := arrayGet(states,numStates);
        numStates := numStates - 1;
        (act, mm_currSt, mm_pos, mm_sPos, mm_linenr, buffer, bkBuffer, states, numStates) := findRule(fileContents, mm_currSt, mm_pos, mm_sPos, mm_ePos, mm_linenr, buffer, bkBuffer, states, numStates);
      then (act, mm_currSt, mm_pos, mm_sPos, mm_linenr, buffer, bkBuffer, states, numStates);

  end match;
end findRule;

function evalState
  input Integer cState;
  input Integer c;
  output Integer new_state;
  output Integer new_c;
protected
  Integer cState1=cState;
  Integer c1=c;
  Integer val,val2,chk;
algorithm
  chk := LexTable.yy_base[cState1];
  chk := chk + c1;
  val := LexTable.yy_chk[chk];
  val2 := LexTable.yy_base[cState1] + c1;
  if cState1<>val then
    cState1 := LexTable.yy_def[cState1];
    if cState1 >= LexTable.yy_limit then
      c1 := LexTable.yy_meta[c1];
    end if;
    if (cState1>0) then
      (cState1,c1) := evalState(cState1,c1);
    end if;
  end if;
  new_state := cState1;
  new_c := c1;
end evalState;

function checkArray<T>
  input array<T> arr;
  input Integer index;
  input SourceInfo info;
protected
  String filename;
  Integer lineStart;
algorithm
  if index<1 or index>arrayLength(arr) then
    SOURCEINFO(fileName=filename, lineNumberStart=lineStart) := info;
    print("\n[" + filename + ":" + String(lineStart) + "]: checkArray failed: arrayLength="+String(arrayLength(arr))+" index=" + String(index) + "\n");
    fail();
  end if;
end checkArray;

function checkArrayModelica
  input Integer arr[:];
  input Integer index;
  input SourceInfo info;
protected
  String filename;
  Integer lineStart;
algorithm
  if index<1 or index>size(arr,1) then
    SOURCEINFO(fileName=filename, lineNumberStart=lineStart) := info;
    print("\n[" + filename + ":" + String(lineStart) + "]: checkArray failed: arrayLength="+String(size(arr,1))+" index=" + String(index) + "\n");
    fail();
  end if;
end checkArrayModelica;

package LexTable
  constant Integer yy_limit = 46;
  constant Integer yy_finish = 82;
  constant Integer yy_acclist[:] = array(
       17,   16,   15,   16,   16,   13,   16,    5,   16,   14,
       16,   11,   16,   12,   16,   16,   16,   16,    9,   16,
       10,   16,   15,    1,    5,    2,    3,    4,    8,    6,
        3,    7
   );
  constant Integer yy_accept[:] = array(
        1,    1,    1,    2,    3,    5,    6,    8,   10,   12,
       14,   16,   17,   18,   19,   21,   23,   24,   24,   25,
       25,   25,   26,   26,   26,   26,   26,   27,   27,   28,
       28,   29,   29,   29,   29,   29,   29,   29,   30,   31,
       31,   31,   32,   33,   33,   33
   );
  constant Integer yy_ec[:] = array(
        1,    1,    1,    1,    1,    1,    1,    1,    2,    2,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    2,    1,    3,    1,    1,    1,    1,    1,    1,
        1,    1,    4,    5,    6,    7,    8,    9,    9,    9,
        9,    9,    9,    9,    9,    9,    9,   10,    1,    1,
        1,    1,    1,    1,   11,   11,   11,   11,   12,   11,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
       13,   14,   15,    1,    1,    1,   16,   17,   11,   11,

       18,   19,    1,    1,    1,    1,    1,   20,    1,   21,
        1,    1,    1,   22,   23,   24,   25,    1,    1,    1,
        1,    1,   26,    1,   27,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,

        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1
   );
  constant Integer yy_meta[:] = array(
        1,    1,    2,    1,    1,    1,    1,    2,    3,    1,
        3,    3,    1,    2,    1,    3,    4,    3,    4,    1,
        2,    2,    1,    2,    2,    1,    1
   );
  constant Integer yy_base[:] = array(
        0,    0,   81,   82,   78,   25,   82,   22,   82,   82,
       82,   63,   53,   55,   82,   82,   74,   27,   82,   50,
       65,   26,   39,   53,   52,   37,   82,    0,   37,   45,
       43,   27,   27,   24,    0,   47,   19,   82,   82,    0,
       27,   23,   82,    0,   82,   56,   59,   61,   63,   65,
       67
   );
  constant Integer yy_def[:] = array(
       45,    1,   45,   45,   45,   46,   45,   45,   45,   45,
       45,   45,   45,   45,   45,   45,   45,   46,   45,   47,
       45,   45,   45,   45,   45,   45,   45,   48,   45,   45,
       45,   45,   45,   45,   49,   45,   45,   45,   45,   50,
       45,   45,   45,   51,    0,   45,   45,   45,   45,   45,
       45
   );
  constant Integer yy_nxt[:] = array(
        4,    5,    6,    4,    7,    4,    4,    4,    8,    9,
        4,    4,   10,    4,   11,    4,    4,    4,   12,    4,
       13,    4,    4,   14,    4,   15,   16,   19,   21,   27,
       22,   42,   21,   23,   22,   42,   43,   23,   20,   23,
       20,   39,   30,   23,   30,   29,   38,   31,   36,   37,
       41,   31,   41,   31,   36,   42,   18,   18,   18,   18,
       18,   34,   18,   35,   35,   40,   40,   44,   44,   18,
       18,   33,   32,   29,   28,   17,   26,   25,   24,   17,
       45,    3,   45,   45,   45,   45,   45,   45,   45,   45,
       45,   45,   45,   45,   45,   45,   45,   45,   45,   45,

       45,   45,   45,   45,   45,   45,   45,   45,   45
   );
  constant Integer yy_chk[:] = array(
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    6,    8,   18,
        8,   42,   22,    8,   22,   41,   37,   22,    6,    8,
       18,   34,   23,   22,   23,   29,   33,   23,   29,   32,
       36,   31,   36,   30,   29,   36,   46,   46,   46,   46,
       47,   26,   47,   48,   48,   49,   49,   50,   50,   51,
       51,   25,   24,   21,   20,   17,   14,   13,   12,    5,
        3,   45,   45,   45,   45,   45,   45,   45,   45,   45,
       45,   45,   45,   45,   45,   45,   45,   45,   45,   45,

       45,   45,   45,   45,   45,   45,   45,   45,   45
   );

end LexTable;



annotation(__OpenModelica_Interface="util");


end LexerJSON;

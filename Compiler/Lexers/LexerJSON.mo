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
  output list<Token> tokens "return list of tokens";
  output list<Token> errorTokens;
algorithm
  (tokens, errorTokens) := lex("<StringSource>",fileSource);
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
    case (1) // #line 26 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.STRING,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (2) // #line 27 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.STRING,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (3) // #line 28 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.NUMBER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (4) // #line 29 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.TRUE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (5) // #line 30 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.FALSE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (6) // #line 31 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.NULL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (7) // #line 32 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.OBJECTBEGIN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (8) // #line 33 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.OBJECTEND,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (9) // #line 35 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.ARRAYBEGIN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (10) // #line 37 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.ARRAYEND,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (11) // #line 39 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.COMMA,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (12) // #line 40 "lexerJSON.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.COLON,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (13) // #line 42 "lexerJSON.l"
      algorithm
      then noToken;
    case (14) // #line 44 "lexerJSON.l"
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
  constant Integer yy_limit = 51;
  constant Integer yy_finish = 99;
  constant Integer yy_acclist[:] = array(
       15,   14,   13,   14,   14,   11,   14,   14,    3,   14,
        3,   14,   12,   14,    9,   14,   14,   10,   14,   14,
       14,   14,    7,   14,    8,   14,   13,    2,    1,    3,
        3,    3,    3,    6,    4,    3,    3,    5,    3
   );
  constant Integer yy_accept[:] = array(
        1,    1,    1,    2,    3,    5,    6,    8,    9,   11,
       13,   15,   17,   18,   20,   21,   22,   23,   25,   27,
       28,   29,   30,   31,   32,   33,   33,   33,   33,   33,
       34,   34,   34,   34,   34,   34,   34,   34,   34,   35,
       36,   37,   37,   38,   38,   39,   39,   39,   39,   40,
       40
   );
  constant Integer yy_ec[:] = array(
        1,    1,    1,    1,    1,    1,    1,    1,    2,    2,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    3,    4,    5,    4,    4,    4,    4,    4,    4,
        4,    4,    6,    7,    8,    9,   10,   11,   12,   12,
       12,   12,   12,   12,   12,   12,   12,   13,    4,    4,
        4,    4,    4,    4,   14,   14,   14,   14,   15,   14,
        4,    4,    4,    4,    4,    4,    4,    4,    4,    4,
        4,    4,    4,    4,    4,    4,    4,    4,    4,    4,
       16,   17,   18,    4,    4,    4,   19,   20,   14,   14,

       21,   22,    4,    4,    4,    4,    4,   23,    4,   24,
        4,    4,    4,   25,   26,   27,   28,    4,    4,    4,
        4,    4,   29,    4,   30,    4,    1,    1,    1,    1,
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
        1,    1,    2,    2,    3,    2,    2,    2,    2,    3,
        4,    4,    2,    4,    4,    2,    5,    2,    4,    6,
        4,    6,    2,    3,    3,    2,    3,    3,    2,    2
   );
  constant Integer yy_base[:] = array(
        0,    0,   98,   99,   29,   92,   99,   22,   99,   24,
       99,   99,   67,   99,   73,   61,   61,   99,   99,   35,
       99,   99,   99,   28,   30,    0,   59,   56,   41,   34,
        0,   40,   31,   31,   36,   45,    0,   29,   99,   99,
       47,   49,   52,    0,   99,   59,   39,   61,   63,   99,
       74,   78,   81,   84,   87,   90
   );
  constant Integer yy_def[:] = array(
       50,    1,   50,   50,   50,   51,   50,   50,   50,   50,
       50,   50,   52,   50,   50,   50,   50,   50,   50,   50,
       50,   50,   50,   50,   50,   53,   50,   50,   50,   50,
       54,   50,   50,   50,   50,   50,   55,   50,   50,   50,
       50,   50,   50,   56,   50,   50,   56,   50,   50,    0,
       50,   50,   50,   50,   50,   50
   );
  constant Integer yy_nxt[:] = array(
        4,    5,    5,    4,    6,    4,    7,    8,    4,    4,
        9,   10,   11,    4,    4,   12,   13,   14,    4,    4,
        4,   15,    4,   16,    4,    4,   17,    4,   18,   19,
       20,   20,   23,   24,   25,   25,   20,   20,   30,   30,
       25,   25,   35,   21,   30,   30,   41,   41,   36,   45,
       42,   40,   42,   39,   36,   43,   43,   41,   41,   43,
       43,   46,   43,   43,   48,   38,   48,   46,   34,   49,
       49,   49,   49,   49,   49,   21,   21,   21,   33,   21,
       21,   32,   21,   21,   31,   29,   31,   37,   28,   37,
       44,   27,   44,   47,   26,   47,   22,   50,    3,   50,

       50,   50,   50,   50,   50,   50,   50,   50,   50,   50,
       50,   50,   50,   50,   50,   50,   50,   50,   50,   50,
       50,   50,   50,   50,   50,   50,   50,   50,   50
   );
  constant Integer yy_chk[:] = array(
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        5,    5,    8,    8,   10,   10,   20,   20,   24,   24,
       25,   25,   30,   47,   30,   30,   35,   35,   30,   38,
       36,   34,   36,   33,   30,   36,   36,   41,   41,   42,
       42,   41,   43,   43,   46,   32,   46,   41,   29,   46,
       46,   48,   48,   49,   49,   51,   51,   51,   28,   51,
       52,   27,   52,   52,   53,   17,   53,   54,   16,   54,
       55,   15,   55,   56,   13,   56,    6,    3,   50,   50,

       50,   50,   50,   50,   50,   50,   50,   50,   50,   50,
       50,   50,   50,   50,   50,   50,   50,   50,   50,   50,
       50,   50,   50,   50,   50,   50,   50,   50,   50
   );

end LexTable;



annotation(__OpenModelica_Interface="util");


end LexerJSON;

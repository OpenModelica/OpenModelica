encapsulated package LexerModelicaDiff "Automatically generated lexer based on flex, generated OMCCp v0.11.0 OpenModelica lexer and parser generator (2015)"
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


import DiffAlgorithm;
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
    case (1) // #line 36 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.WHITESPACE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (2) // #line 37 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.NEWLINE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (3) // #line 38 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.UNSIGNED_REAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (4) // #line 39 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.UNSIGNED_REAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (5) // #line 40 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.UNSIGNED_REAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (6) // #line 41 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.ALGORITHM,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (7) // #line 42 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.AND,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (8) // #line 43 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.ANNOTATION,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (9) // #line 44 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.BLOCK,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (10) // #line 45 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.CLASS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (11) // #line 46 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.CONNECT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (12) // #line 47 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.CONNECTOR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (13) // #line 48 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.CONSTANT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (14) // #line 49 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.DISCRETE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (15) // #line 50 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.DER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (16) // #line 51 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.DEFINEUNIT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (17) // #line 52 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.EACH,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (18) // #line 53 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.ELSE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (19) // #line 54 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.ELSEIF,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (20) // #line 55 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.ELSEWHEN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (21) // #line 56 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.END,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (22) // #line 57 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.ENUMERATION,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (23) // #line 58 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.EQUATION,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (24) // #line 59 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.ENCAPSULATED,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (25) // #line 60 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.EXPANDABLE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (26) // #line 61 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.EXTENDS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (27) // #line 62 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.CONSTRAINEDBY,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (28) // #line 63 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.EXTERNAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (29) // #line 64 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.FALSE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (30) // #line 65 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.FINAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (31) // #line 66 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.FLOW,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (32) // #line 67 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.FOR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (33) // #line 68 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.FUNCTION,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (34) // #line 69 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.IF,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (35) // #line 70 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.IMPORT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (36) // #line 71 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.IN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (37) // #line 72 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.INITIAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (38) // #line 73 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.INNER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (39) // #line 74 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.INPUT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (40) // #line 75 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.LOOP,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (41) // #line 76 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.MODEL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (42) // #line 77 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.NOT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (43) // #line 78 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.OUTER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (44) // #line 79 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.OPERATOR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (45) // #line 80 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.OVERLOAD,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (46) // #line 81 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.OR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (47) // #line 82 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.OUTPUT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (48) // #line 83 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.PACKAGE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (49) // #line 84 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.PARAMETER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (50) // #line 85 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.PARTIAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (51) // #line 86 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.PROTECTED,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (52) // #line 87 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.PUBLIC,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (53) // #line 88 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.RECORD,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (54) // #line 89 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.REDECLARE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (55) // #line 90 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.REPLACEABLE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (56) // #line 91 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.THEN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (57) // #line 92 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.TRUE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (58) // #line 93 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.TYPE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (59) // #line 94 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.WHEN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (60) // #line 95 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.WHILE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (61) // #line 96 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.WITHIN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (62) // #line 97 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.RETURN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (63) // #line 98 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.BREAK,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (64) // #line 100 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.LPAR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (65) // #line 101 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.RPAR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (66) // #line 102 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.LBRACK,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (67) // #line 103 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.RBRACK,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (68) // #line 104 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.LBRACE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (69) // #line 105 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.RBRACE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (70) // #line 106 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.EQEQ,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (71) // #line 107 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.EQUALS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (72) // #line 108 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.COMMA,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (73) // #line 109 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.ASSIGN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (74) // #line 110 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.COLONCOLON,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (75) // #line 111 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.COLON,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (76) // #line 112 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.SEMICOLON,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (77) // #line 114 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.PURE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (78) // #line 115 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.IMPURE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (79) // #line 116 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.OPTIMIZATION,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (80) // #line 118 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.PLUS_EW,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (81) // #line 119 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.MINUS_EW,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (82) // #line 120 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.STAR_EW,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (83) // #line 121 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.SLASH_EW,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (84) // #line 122 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.POWER_EW,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (85) // #line 124 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.STAR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (86) // #line 125 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.MINUS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (87) // #line 126 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.PLUS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (88) // #line 127 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.LESSEQ,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (89) // #line 128 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.LESSGT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (90) // #line 129 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.LESS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (91) // #line 130 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.GREATER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (92) // #line 131 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.GREATEREQ,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (93) // #line 133 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.POWER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (94) // #line 134 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.SLASH,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (95) // #line 136 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.SUBTYPEOF,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (96) // #line 138 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.STREAM,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (97) // #line 140 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.DOT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (98) // #line 142 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.IDENT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (99) // #line 144 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.IDENT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (100) // #line 146 "lexerModelicaDiff.l"
      algorithm
        tok := TOKEN(fileNm,TokenId.UNSIGNED_INTEGER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (101) // #line 148 "lexerModelicaDiff.l"
      algorithm
        mm_startSt := 7;
        bufferRet := buffer;
      then noToken;
    case (102) // #line 153 "lexerModelicaDiff.l"
      algorithm
        bufferRet := buffer;
      then noToken;
    case (103) // #line 154 "lexerModelicaDiff.l"
      algorithm
        bufferRet := buffer;
      then noToken;
    case (104) // #line 155 "lexerModelicaDiff.l"
      algorithm
        mm_startSt := 1;
        tok := TOKEN(fileNm,TokenId.STRING,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (105) // #line 156 "lexerModelicaDiff.l"
      algorithm
        bufferRet := buffer;
      then noToken;
    case (106) // #line 157 "lexerModelicaDiff.l"
      algorithm
        bufferRet := buffer;
      then noToken;
    case (107) // #line 160 "lexerModelicaDiff.l"
      algorithm
        mm_startSt := 3;
        bufferRet := buffer;
      then noToken;
    case (108) // #line 165 "lexerModelicaDiff.l"
      algorithm
        mm_startSt := 1;
        tok := TOKEN(fileNm,TokenId.BLOCK_COMMENT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (109) // #line 166 "lexerModelicaDiff.l"
      algorithm
        bufferRet := buffer;
      then noToken;
    case (110) // #line 167 "lexerModelicaDiff.l"
      algorithm
        bufferRet := buffer;
      then noToken;
    case (111) // #line 174 "lexerModelicaDiff.l"
      algorithm
        mm_startSt := 5;
        bufferRet := buffer;
      then noToken;
    case (112) // #line 180 "lexerModelicaDiff.l"
      algorithm
        mm_startSt := 1;
        tok := TOKEN(fileNm,TokenId.LINE_COMMENT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (113) // #line 181 "lexerModelicaDiff.l"
      algorithm
        bufferRet := buffer;
      then noToken;
    case (114) // #line 184 "lexerModelicaDiff.l"
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
  ALGORITHM,
  AND,
  ANNOTATION,
  ASSIGN,
  BLOCK,
  BLOCK_COMMENT,
  BREAK,
  CLASS,
  COLON,
  COLONCOLON,
  COMMA,
  CONNECT,
  CONNECTOR,
  CONSTANT,
  CONSTRAINEDBY,
  DEFINEUNIT,
  DER,
  DISCRETE,
  DOT,
  EACH,
  ELSE,
  ELSEIF,
  ELSEWHEN,
  ENCAPSULATED,
  END,
  ENUMERATION,
  EQEQ,
  EQUALS,
  EQUATION,
  EXPANDABLE,
  EXTENDS,
  EXTERNAL,
  FALSE,
  FINAL,
  FLOW,
  FOR,
  FUNCTION,
  GREATER,
  GREATEREQ,
  IDENT,
  IF,
  IMPORT,
  IMPURE,
  IN,
  INITIAL,
  INNER,
  INPUT,
  LBRACE,
  LBRACK,
  LESS,
  LESSEQ,
  LESSGT,
  LINE_COMMENT,
  LOOP,
  LPAR,
  MINUS,
  MINUS_EW,
  MODEL,
  MODELICA,
  NEWLINE,
  NOT,
  OPERATOR,
  OPTIMIZATION,
  OR,
  OUTER,
  OUTPUT,
  OVERLOAD,
  PACKAGE,
  PARAMETER,
  PARTIAL,
  PLUS,
  PLUS_EW,
  POWER,
  POWER_EW,
  PROTECTED,
  PUBLIC,
  PURE,
  RBRACE,
  RBRACK,
  RECORD,
  REDECLARE,
  REPLACEABLE,
  RETURN,
  RPAR,
  SEMICOLON,
  SLASH,
  SLASH_EW,
  STAR,
  STAR_EW,
  STREAM,
  STRING,
  SUBTYPEOF,
  THEN,
  TRUE,
  TYPE,
  UNSIGNED_INTEGER,
  UNSIGNED_REAL,
  WHEN,
  WHILE,
  WHITESPACE,
  WITHIN
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
  Integer startSt,i,r,cTok,cTok2,currSt,pos,sPos,ePos,linenr,contentLen,numBacktrack,buffer,lineNrStart;
  list<Integer> cProg,cProg2;
  list<String> chars;
  list<Integer> states;
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

  states := {};

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
     (tokens,numBacktrack,startSt,currSt,pos,sPos,ePos,linenr,lineNrStart,buffer,states,errorTokens) := consume(cTok,tokens,contents,startSt,currSt,pos,sPos,ePos,linenr,lineNrStart,buffer,states,fileName,errorTokens);
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
  input list<Integer> inStates;
  input String fileName;
  input list<Token> inErrorTokens;
  output list<Token> resToken;
  output Integer bkBuffer = 0;
  output Integer mm_startSt;
  output Integer mm_currSt,mm_pos,mm_sPos,mm_ePos,mm_linenr,lineNrStart;
  output Integer buffer;
  output list<Integer> states;
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
  states := mm_currSt::states;

  baseCond := LexTable.yy_base[mm_currSt];
  if (baseCond==LexTable.yy_finish) then
    if (debug==true) then
      print("\n[RESTORE=" + intString(LexTable.yy_accept[mm_currSt]) + "]");
    end if;

    (act, mm_currSt, mm_pos, mm_sPos, mm_linenr, buffer, bkBuffer, states) := findRule(fileContents, mm_currSt, mm_pos, mm_sPos, mm_ePos, mm_linenr, buffer, bkBuffer, states);

    if (debug==true) then
      print("\nFound rule: " + String(act));
    end if;

    (tok,mm_startSt,buffer2,errorTokens) := action(act,mm_startSt,mm_currSt,mm_pos,mm_sPos,mm_ePos,mm_linenr,lineNrStart,buffer,debug,fileName,fileContents,errorTokens);

    if (debug==true) then
      print("\nDid action");
    end if;

    mm_currSt := mm_startSt;
    states := {};

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
  input list<Integer> inStates;
  output Integer action;
  output Integer mm_currSt;
  output Integer mm_pos;
  output Integer mm_sPos;
  output Integer mm_linenr;
  output Integer buffer;
  output Integer bkBuffer;
  output list<Integer> states;
protected
  array<Integer> mm_accept,mm_ec,mm_meta,mm_base,mm_def,mm_nxt,mm_chk,mm_acclist;
  Integer lp,lp1,stCmp,cp;
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

  stCmp := listGet(states, 1);
  lp := LexTable.yy_accept[stCmp];
  lp1 := LexTable.yy_accept[stCmp+1];

  st := intGt(lp,0) and intLt(lp,lp1);
  if st then
    if debug then
      checkArrayModelica(LexTable.yy_accept,stCmp,sourceInfo());
      checkArrayModelica(LexTable.yy_acclist,lp,sourceInfo());
    end if;
    lp := LexTable.yy_accept[stCmp];
    action := LexTable.yy_acclist[lp];
  else
    cp := stringGet(fileContents,mm_pos-1);
    buffer := buffer-1;
    bkBuffer := bkBuffer+1;
    mm_pos := mm_pos - 1;
    mm_sPos := mm_sPos -1;
    if (cp==10) then
      mm_sPos := mm_ePos;
      mm_linenr := mm_linenr-1;
    end if;
    mm_currSt::states := states;
    (action, mm_currSt, mm_pos, mm_sPos, mm_linenr, buffer, bkBuffer, states) := findRule(fileContents, mm_currSt, mm_pos, mm_sPos, mm_ePos, mm_linenr, buffer, bkBuffer, states);
  end if;
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
  constant Integer yy_limit = 395;
  constant Integer yy_finish = 453;
  constant Integer yy_acclist[:] = array(
      115,  114,    1,  114,    2,  114,  114,  101,  114,  114,
       64,  114,   65,  114,   85,  114,   87,  114,   72,  114,
       86,  114,   97,  114,   94,  114,  100,  114,   75,  114,
       76,  114,   90,  114,   71,  114,   91,  114,   98,  114,
       66,  114,   67,  114,   93,  114,   98,  114,   98,  114,
       98,  114,   98,  114,   98,  114,   98,  114,   98,  114,
       98,  114,   98,  114,   98,  114,   98,  114,   98,  114,
       98,  114,   98,  114,   98,  114,   98,  114,   68,  114,
       69,  114,  109,  114,  110,  114,  109,  114,  113,  114,
      112,  114,  105,  114,  106,  114,  104,  105,  114,  105,

      114,    1,    2,   82,   80,   81,   83,    5,   84,  107,
      111,    3,  100,   74,   73,   88,   89,   70,   92,   98,
       98,   98,   98,   98,   98,   98,   98,   98,   98,   98,
       98,   98,   98,   98,   98,   98,   98,   98,   34,   98,
       98,   36,   98,   98,   98,   98,   98,   46,   98,   98,
       98,   98,   98,   98,   98,   98,   98,   98,   98,   98,
       98,   98,  108,  102,  103,   99,    3,    4,   98,    7,
       98,   98,   98,   98,   98,   98,   98,   15,   98,   98,
       98,   98,   98,   21,   98,   98,   98,   98,   98,   98,
       98,   98,   32,   98,   98,   98,   98,   98,   98,   98,

       98,   42,   98,   98,   98,   98,   98,   98,   98,   98,
       98,   98,   98,   98,   98,   98,   98,   98,   98,   98,
       98,   98,   98,   98,    5,    3,   98,   98,   98,   98,
       98,   98,   98,   98,   98,   17,   98,   18,   98,   98,
       98,   98,   98,   98,   98,   98,   31,   98,   98,   98,
       98,   98,   98,   98,   40,   98,   98,   98,   98,   98,
       98,   98,   98,   98,   98,   98,   98,   77,   98,   98,
       98,   98,   98,   98,   98,   56,   98,   57,   98,   58,
       98,   59,   98,   98,   98,   98,   98,    9,   98,   63,
       98,   10,   98,   98,   98,   98,   98,   98,   98,   98,

       98,   98,   98,   98,   98,   29,   98,   30,   98,   98,
       98,   98,   98,   38,   98,   39,   98,   41,   98,   98,
       98,   43,   98,   98,   98,   98,   98,   98,   98,   98,
       98,   98,   98,   98,   98,   98,   60,   98,   98,   98,
       98,   98,   98,   98,   98,   98,   19,   98,   98,   98,
       98,   98,   98,   98,   98,   98,   35,   98,   78,   98,
       98,   98,   98,   47,   98,   98,   98,   98,   98,   98,
       52,   98,   53,   98,   98,   98,   62,   98,   96,   98,
       98,   61,   98,   98,   98,   11,   98,   98,   98,   98,
       98,   98,   98,   98,   98,   98,   26,   98,   98,   98,

       37,   98,   98,   98,   98,   48,   98,   98,   50,   98,
       98,   98,   98,   98,   98,   98,   98,   13,   98,   98,
       98,   14,   98,   20,   98,   98,   98,   23,   98,   98,
       28,   98,   33,   98,   44,   98,   98,   45,   98,   98,
       98,   98,   98,   98,    6,   98,   98,   12,   98,   98,
       98,   98,   98,   98,   98,   49,   98,   51,   98,   54,
       98,   98,   95,   98,    8,   98,   98,   16,   98,   98,
       98,   25,   98,   98,   98,   98,   98,   22,   98,   98,
       55,   98,   98,   24,   98,   79,   98,   27,   98
   );
  constant Integer yy_accept[:] = array(
        1,    1,    1,    1,    1,    1,    1,    1,    1,    2,
        3,    5,    7,    8,   10,   11,   13,   15,   17,   19,
       21,   23,   25,   27,   29,   31,   33,   35,   37,   39,
       41,   43,   45,   47,   49,   51,   53,   55,   57,   59,
       61,   63,   65,   67,   69,   71,   73,   75,   77,   79,
       81,   83,   85,   87,   89,   91,   93,   95,   97,  100,
      102,  103,  104,  104,  104,  105,  106,  107,  108,  109,
      110,  111,  112,  113,  114,  114,  115,  116,  117,  118,
      119,  120,  121,  122,  123,  124,  125,  126,  127,  128,
      129,  130,  131,  132,  133,  134,  135,  136,  137,  138,

      139,  141,  142,  144,  145,  146,  147,  148,  150,  151,
      152,  153,  154,  155,  156,  157,  158,  159,  160,  161,
      162,  163,  164,  165,  166,  167,  167,  168,  168,  168,
      169,  170,  172,  173,  174,  175,  176,  177,  178,  180,
      181,  182,  183,  184,  186,  187,  188,  189,  190,  191,
      192,  193,  195,  196,  197,  198,  199,  200,  201,  202,
      204,  205,  206,  207,  208,  209,  210,  211,  212,  213,
      214,  215,  216,  217,  218,  219,  220,  221,  222,  223,
      224,  225,  225,  226,  226,  227,  228,  229,  230,  231,
      232,  233,  234,  235,  236,  238,  240,  241,  242,  243,

      244,  245,  246,  247,  249,  250,  251,  252,  253,  254,
      255,  257,  258,  259,  260,  261,  262,  263,  264,  265,
      266,  267,  268,  270,  271,  272,  273,  274,  275,  276,
      278,  280,  282,  284,  285,  286,  287,  288,  290,  292,
      294,  295,  296,  297,  298,  299,  300,  301,  302,  303,
      304,  305,  306,  308,  310,  311,  312,  313,  314,  316,
      318,  320,  321,  322,  324,  325,  326,  327,  328,  329,
      330,  331,  332,  333,  334,  335,  336,  337,  339,  340,
      341,  342,  343,  344,  345,  346,  347,  349,  350,  351,
      352,  353,  354,  355,  356,  357,  359,  361,  362,  363,

      364,  366,  367,  368,  369,  370,  371,  373,  375,  376,
      377,  379,  381,  382,  384,  385,  386,  388,  389,  390,
      391,  392,  393,  394,  395,  396,  397,  399,  400,  401,
      403,  404,  405,  406,  408,  409,  411,  412,  413,  414,
      415,  416,  417,  418,  420,  421,  422,  424,  426,  427,
      428,  430,  431,  433,  435,  437,  438,  440,  441,  442,
      443,  444,  445,  447,  448,  450,  451,  452,  453,  454,
      455,  456,  458,  460,  462,  463,  465,  467,  468,  470,
      471,  472,  474,  475,  476,  477,  478,  480,  481,  483,
      484,  486,  488,  490,  490

   );
  constant Integer yy_ec[:] = array(
        1,    1,    1,    1,    1,    1,    1,    1,    2,    3,
        1,    1,    4,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    5,    6,    7,    6,    6,    6,    6,    8,    9,
       10,   11,   12,   13,   14,   15,   16,   17,   17,   17,
       17,   17,   17,   17,   17,   17,   17,   18,   19,   20,
       21,   22,    6,    6,   23,   23,   23,   23,   24,   23,
       23,   23,   23,   23,   23,   23,   23,   23,   23,   23,
       23,   23,   23,   23,   23,   23,   23,   23,   23,   23,
       25,   26,   27,   28,   23,    1,   29,   30,   31,   32,

       33,   34,   35,   36,   37,   23,   38,   39,   40,   41,
       42,   43,   44,   45,   46,   47,   48,   49,   50,   51,
       52,   53,   54,    6,   55,    1,    1,    1,    1,    1,
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
        1,    1,    1,    1,    2,    2,    3,    3,    2,    2,
        2,    2,    2,    2,    2,    2,    4,    2,    2,    2,
        5,    2,    4,    4,    2,    5,    2,    2,    6,    6,
        4,    4,    4,    6,    4,    4,    4,    4,    4,    4,
        6,    4,    4,    4,    6,    4,    4,    4,    6,    4,
        4,    6,    4,    2,    2
   );
  constant Integer yy_base[:] = array(
        0,    0,   53,   54,  449,  448,   55,   56,  450,  453,
       64,  453,  446,  453,  422,  453,  453,  453,  453,  453,
      453,   56,   60,   62,   57,  453,   39,  426,  425,    0,
      453,  453,  453,   44,   35,   48,   55,   60,   68,   62,
      403,  402,  401,   69,   77,  409,   46,   79,   72,  453,
      453,  453,  453,  425,  453,  453,  453,  453,  453,   93,
      118,  453,  113,    0,  453,  453,  453,  453,  109,  453,
      453,  453,  110,  113,  124,  453,  453,  453,  453,  453,
      453,    0,  405,  103,  397,  405,  408,  395,   95,  389,
      403,  387,  116,  384,  102,  392,  389,  387,  383,  386,

        0,  383,  113,  383,  392,  376,  118,    0,  375,  388,
      121,  378,   68,  126,  374,  388,  384,  368,  372,  122,
      367,  453,  453,  146,  453,  162,  144,  166,  396,  395,
      369,    0,  368,  378,  379,  361,  121,  369,    0,  374,
      368,  370,  373,    0,  361,  371,  370,  365,  351,  367,
      345,    0,  363,  133,  346,  359,  343,  347,  356,    0,
      343,  350,  127,  341,  347,  142,  337,  344,  349,  339,
      347,  340,  330,  344,  329,  334,  341,  340,  331,  332,
      334,  352,  351,  350,  349,  320,  317,  325,  324,  315,
      327,  312,  317,  312,    0,  145,  313,  322,  307,  312,

      143,  319,  312,    0,  303,  304,  303,  310,  301,  298,
        0,  305,  314,  302,  296,  292,  300,  309,  297,  299,
      302,  297,    0,  288,  301,  302,  285,  300,  276,    0,
        0,    0,    0,  294,  289,  288,  295,    0,    0,    0,
      292,  156,  289,  288,  286,  283,  272,  272,  279,  283,
      282,  272,    0,    0,  275,  264,  277,  280,    0,    0,
        0,  261,  270,    0,  259,  263,  269,  270,  273,  270,
      269,  267,  259,  266,  255,  255,  251,    0,  252,  245,
      244,  243,  248,  259,  239,  239,    0,  252,  236,  254,
      240,  252,  234,  250,  236,    0,    0,  238,  234,  222,

        0,  245,  240,  225,  232,  223,    0,    0,  240,  235,
        0,    0,  234,    0,  230,  228,  222,  216,  225,  220,
      227,  218,  219,  210,  215,  225,    0,  215,  212,    0,
      207,  222,  218,    0,  216,    0,  215,  202,  217,  203,
      204,  201,  197,    0,  200,  203,    0,    0,  210,  201,
        0,  198,    0,    0,    0,  189,    0,  190,  202,  200,
      202,  195,    0,  185,    0,  188,  153,  152,  156,  164,
      159,    0,    0,    0,  155,    0,    0,  161,    0,  159,
      150,    0,  148,  154,  156,  131,    0,   91,    0,   39,
        0,    0,    0,  453,  201,  207,  213,  218,  221,  225

   );
  constant Integer yy_def[:] = array(
      394,    1,  395,  395,  396,  396,  397,  397,  394,  394,
      394,  394,  394,  394,  398,  394,  394,  394,  394,  394,
      394,  394,  394,  394,  394,  394,  394,  394,  394,  399,
      394,  394,  394,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  394,
      394,  394,  394,  394,  394,  394,  394,  394,  394,  394,
      394,  394,  398,  400,  394,  394,  394,  394,  394,  394,
      394,  394,  394,  394,  394,  394,  394,  394,  394,  394,
      394,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,

      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  394,  394,  394,  394,  394,  394,  394,  394,  394,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  394,  394,  394,  394,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,

      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,

      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,  399,  399,  399,  399,  399,  399,  399,
      399,  399,  399,    0,  394,  394,  394,  394,  394,  394

   );
  constant Integer yy_nxt[:] = array(
       10,   11,   12,   13,   11,   10,   14,   15,   16,   17,
       18,   19,   20,   21,   22,   23,   24,   25,   26,   27,
       28,   29,   30,   30,   31,   10,   32,   33,   34,   35,
       36,   37,   38,   39,   30,   30,   40,   30,   41,   42,
       43,   44,   45,   30,   46,   47,   48,   30,   30,   49,
       30,   30,   30,   50,   51,   53,   53,   58,   58,   78,
       79,   59,   59,   54,   54,   61,   65,   66,   61,   67,
       71,   68,   69,   85,   76,   72,   73,   77,   74,   86,
       60,   60,   83,   70,   84,   75,   87,   89,   91,   88,
      393,   90,  115,  116,   75,  101,   96,  168,   92,  123,

       93,  102,  103,   94,   97,  111,   98,  120,  121,   99,
       95,  107,  169,  108,  117,  100,  109,  110,  124,   61,
      125,  112,   61,  118,  113,   69,  127,   73,  138,   74,
      119,  392,  126,  128,  132,  129,   75,  129,   64,  139,
      130,  126,  128,  133,  147,   75,  143,  144,  148,  155,
      161,  165,  123,  156,  179,  157,  170,  171,  180,  215,
      127,  191,  391,  145,  162,  166,  192,  128,  172,  216,
      219,  124,  173,  182,  206,  182,  128,  184,  183,  184,
      207,  245,  185,  251,  283,  390,  389,  252,  220,  388,
      387,  386,  385,  384,  246,  383,  382,  381,  380,  379,

      284,   52,   52,   52,   52,   52,   52,   55,   55,   55,
       55,   55,   55,   57,   57,   57,   57,   57,   57,   63,
      378,   63,   63,   63,   82,  377,   82,   63,  376,   63,
       63,  375,  374,  373,  372,  371,  370,  369,  368,  367,
      366,  365,  364,  363,  362,  361,  360,  359,  358,  357,
      356,  355,  354,  353,  352,  351,  350,  349,  348,  347,
      346,  345,  344,  343,  342,  341,  340,  339,  338,  337,
      336,  335,  334,  333,  332,  331,  330,  329,  328,  327,
      326,  325,  324,  323,  322,  321,  320,  319,  318,  317,
      316,  315,  314,  313,  312,  311,  310,  309,  308,  307,

      306,  305,  304,  303,  302,  301,  300,  299,  298,  297,
      296,  295,  294,  293,  292,  291,  290,  289,  288,  287,
      286,  285,  282,  281,  280,  279,  278,  277,  276,  275,
      274,  273,  272,  271,  270,  269,  268,  267,  266,  265,
      264,  263,  262,  261,  260,  259,  258,  257,  256,  255,
      254,  253,  250,  249,  248,  247,  244,  243,  242,  241,
      240,  239,  238,  237,  236,  185,  185,  183,  183,  235,
      234,  233,  232,  231,  230,  229,  228,  227,  226,  225,
      224,  223,  222,  221,  218,  217,  214,  213,  212,  211,
      210,  209,  208,  205,  204,  203,  202,  201,  200,  199,

      198,  197,  196,  195,  194,  193,  190,  189,  188,  187,
      186,  130,  130,  181,  178,  177,  176,  175,  174,  167,
      164,  163,  160,  159,  158,  154,  153,  152,  151,  150,
      149,  146,  142,  141,  140,  137,  136,  135,  134,  131,
      122,  114,  106,  105,  104,   81,   80,   64,   62,  394,
       56,   56,    9,  394,  394,  394,  394,  394,  394,  394,
      394,  394,  394,  394,  394,  394,  394,  394,  394,  394,
      394,  394,  394,  394,  394,  394,  394,  394,  394,  394,
      394,  394,  394,  394,  394,  394,  394,  394,  394,  394,
      394,  394,  394,  394,  394,  394,  394,  394,  394,  394,

      394,  394,  394,  394,  394,  394,  394,  394
   );
  constant Integer yy_chk[:] = array(
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    3,    4,    7,    8,   27,
       27,    7,    8,    3,    4,   11,   22,   22,   11,   22,
       23,   22,   22,   35,   25,   23,   24,   25,   24,   35,
        7,    8,   34,   22,   34,   24,   36,   37,   38,   36,
      390,   37,   47,   47,   24,   40,   39,  113,   38,   60,

       38,   40,   40,   38,   39,   45,   39,   49,   49,   39,
       38,   44,  113,   44,   48,   39,   44,   44,   60,   61,
       63,   45,   61,   48,   45,   69,   73,   74,   89,   74,
       48,  388,   69,   73,   84,   75,   74,   75,   63,   89,
       75,   69,   73,   84,   95,   74,   93,   93,   95,  103,
      107,  111,  124,  103,  120,  103,  114,  114,  120,  163,
      127,  137,  386,   93,  107,  111,  137,  127,  114,  163,
      166,  124,  114,  126,  154,  126,  127,  128,  126,  128,
      154,  196,  128,  201,  242,  385,  384,  201,  166,  383,
      381,  380,  378,  375,  196,  371,  370,  369,  368,  367,

      242,  395,  395,  395,  395,  395,  395,  396,  396,  396,
      396,  396,  396,  397,  397,  397,  397,  397,  397,  398,
      366,  398,  398,  398,  399,  364,  399,  400,  362,  400,
      400,  361,  360,  359,  358,  356,  352,  350,  349,  346,
      345,  343,  342,  341,  340,  339,  338,  337,  335,  333,
      332,  331,  329,  328,  326,  325,  324,  323,  322,  321,
      320,  319,  318,  317,  316,  315,  313,  310,  309,  306,
      305,  304,  303,  302,  300,  299,  298,  295,  294,  293,
      292,  291,  290,  289,  288,  286,  285,  284,  283,  282,
      281,  280,  279,  277,  276,  275,  274,  273,  272,  271,

      270,  269,  268,  267,  266,  265,  263,  262,  258,  257,
      256,  255,  252,  251,  250,  249,  248,  247,  246,  245,
      244,  243,  241,  237,  236,  235,  234,  229,  228,  227,
      226,  225,  224,  222,  221,  220,  219,  218,  217,  216,
      215,  214,  213,  212,  210,  209,  208,  207,  206,  205,
      203,  202,  200,  199,  198,  197,  194,  193,  192,  191,
      190,  189,  188,  187,  186,  185,  184,  183,  182,  181,
      180,  179,  178,  177,  176,  175,  174,  173,  172,  171,
      170,  169,  168,  167,  165,  164,  162,  161,  159,  158,
      157,  156,  155,  153,  151,  150,  149,  148,  147,  146,

      145,  143,  142,  141,  140,  138,  136,  135,  134,  133,
      131,  130,  129,  121,  119,  118,  117,  116,  115,  112,
      110,  109,  106,  105,  104,  102,  100,   99,   98,   97,
       96,   94,   92,   91,   90,   88,   87,   86,   85,   83,
       54,   46,   43,   42,   41,   29,   28,   15,   13,    9,
        6,    5,  394,  394,  394,  394,  394,  394,  394,  394,
      394,  394,  394,  394,  394,  394,  394,  394,  394,  394,
      394,  394,  394,  394,  394,  394,  394,  394,  394,  394,
      394,  394,  394,  394,  394,  394,  394,  394,  394,  394,
      394,  394,  394,  394,  394,  394,  394,  394,  394,  394,

      394,  394,  394,  394,  394,  394,  394,  394
   );

end LexTable;


public

function modelicaDiffTokenEq
  import LexerModelicaDiff.{Token,TokenId,tokenContent};
  input Token ta,tb;
  output Boolean b;
protected
  LexerModelicaDiff.TokenId ida,idb;
algorithm
  LexerModelicaDiff.TOKEN(id=ida) := ta;
  LexerModelicaDiff.TOKEN(id=idb) := tb;
  if ida <> idb then
    b := false;
    return;
  end if;
  b := match ida
    case TokenId.IDENT then tokenContentEq(ta,tb);
    case TokenId.UNSIGNED_INTEGER then tokenContentEq(ta,tb);
    case TokenId.UNSIGNED_REAL
      then stringReal(tokenContent(ta))==stringReal(tokenContent(tb));
    case TokenId.BLOCK_COMMENT
      then valueEq(blockCommentCanonical(ta),blockCommentCanonical(tb));
    case TokenId.LINE_COMMENT then tokenContentEq(ta,tb);
    case TokenId.STRING
      algorithm
        b := tokenContentEq(ta,tb);
        if not b then
          b := if 0<>StringUtil.findChar(tokenContent(ta), stringCharInt("\n")) then valueEq(blockCommentCanonical(ta),blockCommentCanonical(tb)) else false;
        end if;
      then b;
    case TokenId.WHITESPACE then true; // tokenContent(ta)==tokenContent(tb);
    else true;
  end match;
end modelicaDiffTokenEq;

function modelicaDiffTokenWhitespace
  import LexerModelicaDiff.{Token,TokenId};
  input Token t;
  output Boolean b;
protected
  LexerModelicaDiff.TokenId id;
algorithm
  LexerModelicaDiff.TOKEN(id=id) := t;
  b := id==TokenId.BLOCK_COMMENT or id==TokenId.LINE_COMMENT or id==TokenId.WHITESPACE or id==TokenId.NEWLINE;
end modelicaDiffTokenWhitespace;

function filterModelicaDiff
  import LexerModelicaDiff.{Token,TokenId,tokenContent,TOKEN};
  import DiffAlgorithm.Diff;
  input list<tuple<Diff, list<Token>>> diffs;
  input Boolean removeWhitespace=true;
  output list<tuple<Diff, list<Token>>> odiffs;
protected
  list<String> addedLineComments, removedLineComments;
  list<list<String>> addedBlockComments, removedBlockComments;
  list<tuple<Diff, Token>> simpleDiff, tmp, rest;
  Boolean lastIsNewline;
  Integer depth;
algorithm
  // No changes are easy
  _ := match diffs
    case {(Diff.Equal,_)}
      algorithm
        odiffs := diffs;
        return;
      then ();
    else ();
  end match;

  odiffs := listReverse(match e
    local
      list<Token> ts;
    case (Diff.Delete,ts as {TOKEN(id=TokenId.WHITESPACE)}) then (Diff.Equal,ts);
    case (Diff.Delete,ts as {TOKEN(id=TokenId.NEWLINE)}) then (Diff.Equal,ts);
    else e;
    end match

    for e guard(
    match e
      // Single addition of whitespace, not followed by another addition
      // is suspected garbage added by OMC.
      case (Diff.Add,{TOKEN(id=TokenId.WHITESPACE)}) then not removeWhitespace;
      case (Diff.Add,{TOKEN(id=TokenId.NEWLINE)}) then not removeWhitespace;
      case (_,{}) then false;
      else true;
    end match
  ) in diffs);

  // Convert from multiple additions per item to one per item
  // Costs more memory, but is easier to transform
  simpleDiff := listAppend(
    match e
      local
        list<Token> ts;
      case (Diff.Add,ts) then list((Diff.Add,t) for t in ts);
      case (Diff.Equal,ts) then list((Diff.Equal,t) for t in ts);
      case (Diff.Delete,ts) then list((Diff.Delete,t) for t in ts);
    end match
  for e in odiffs);

  tmp := {};
  lastIsNewline := false;
  depth := 2;
  while not listEmpty(simpleDiff) loop
    (lastIsNewline,simpleDiff,tmp) := match simpleDiff
      local
        tuple<Diff, Token> e,e1,e2;
        Token t,t1,t2,tk3,tk4,tk5;
        TokenId t3,t4,t5;
        Diff d1,d2,d3,d4,d5;
      // Do not delete whitespace in-between two tokens
      case (e1 as (Diff.Equal,_))::(Diff.Delete,t1 as TOKEN(id=TokenId.NEWLINE))::(Diff.Delete,t2 as TOKEN(id=TokenId.WHITESPACE))::(e2 as (Diff.Equal,_))::rest then (false,e1::(Diff.Equal,t1)::(Diff.Equal,t2)::e2::rest,tmp);
      case (e1 as (Diff.Equal,_))::(Diff.Delete,t as TOKEN(id=TokenId.WHITESPACE))::(e2 as (Diff.Equal,_))::rest then (false,e1::(Diff.Equal,t)::e2::rest,tmp);
      case (e1 as (Diff.Equal,TOKEN(id=t3)))::rest
        guard t3<>TokenId.WHITESPACE and t3<>TokenId.NEWLINE and deleteWhitespaceFollowedByEqualNonWhitespace(rest)
        algorithm
          (_,rest) := deleteWhitespaceFollowedByEqualNonWhitespace(rest);
        then (false,e1::rest,tmp);

      // Do not delete+add the same token just because there is whitespace added
      case (d1,t1)::(Diff.Add,TOKEN(id=t3))::(Diff.Add,TOKEN(id=t4))::(Diff.Add,TOKEN(id=t5))::(d2,t2)::rest
        guard ((d1==Diff.Add and d2==Diff.Delete) or (d2==Diff.Add and d1==Diff.Delete)) and modelicaDiffTokenEq(t1,t2)
               and (t3==TokenId.NEWLINE or t3 == TokenId.WHITESPACE) and (t4==TokenId.NEWLINE or t4 == TokenId.WHITESPACE) and (t5==TokenId.NEWLINE or t5 == TokenId.WHITESPACE)
        then (false,(Diff.Equal,t1)::rest,tmp);
      case (d1,t1)::(Diff.Add,TOKEN(id=t3))::(Diff.Add,TOKEN(id=t4))::(d2,t2)::rest
        guard ((d1==Diff.Add and d2==Diff.Delete) or (d2==Diff.Add and d1==Diff.Delete)) and modelicaDiffTokenEq(t1,t2)
               and (t3==TokenId.NEWLINE or t3 == TokenId.WHITESPACE) and (t4==TokenId.NEWLINE or t4 == TokenId.WHITESPACE)
        then (false,(Diff.Equal,t1)::rest,tmp);
      case (d1,t1)::(Diff.Add,TOKEN(id=t3))::(d2,t2)::rest
        guard ((d1==Diff.Add and d2==Diff.Delete) or (d2==Diff.Add and d1==Diff.Delete)) and modelicaDiffTokenEq(t1,t2)
               and (t3==TokenId.NEWLINE or t3 == TokenId.WHITESPACE)
        then (false,(Diff.Equal,t1)::rest,tmp);

      // Odd case of Delete token + equals whitespace + Add token again... Do Equal token + equal whitespace
      case (d1,t1)::(d3,tk3 as TOKEN(id=t3))::(d4,tk4 as TOKEN(id=t4))::(d5,tk5 as TOKEN(id=t5))::(d2,t2)::rest
        guard ((d1==Diff.Add and d2==Diff.Delete) or (d2==Diff.Add and d1==Diff.Delete)) and modelicaDiffTokenEq(t1,t2)
               and (d3==Diff.Equal or d3==Diff.Delete) and (d4==Diff.Equal or d4==Diff.Delete) and (d5==Diff.Equal or d5==Diff.Delete)
               and (t3==TokenId.NEWLINE or t3 == TokenId.WHITESPACE) and (t4==TokenId.NEWLINE or t4 == TokenId.WHITESPACE) and (t5==TokenId.NEWLINE or t5 == TokenId.WHITESPACE)
        then (false,(Diff.Equal,t1)::(Diff.Equal,tk3)::(Diff.Equal,tk4)::(Diff.Equal,tk5)::rest,tmp);
      case (d1,t1)::(d3,tk3 as TOKEN(id=t3))::(d4,tk4 as TOKEN(id=t4))::(d2,t2)::rest
        guard ((d1==Diff.Add and d2==Diff.Delete) or (d2==Diff.Add and d1==Diff.Delete)) and modelicaDiffTokenEq(t1,t2)
               and (d3==Diff.Equal or d3==Diff.Delete) and (d4==Diff.Equal or d4==Diff.Delete)
               and (t3==TokenId.NEWLINE or t3 == TokenId.WHITESPACE) and (t4==TokenId.NEWLINE or t4 == TokenId.WHITESPACE)
        then (false,(Diff.Equal,t1)::(Diff.Equal,tk3)::(Diff.Equal,tk4)::rest,tmp);
      case (d1,t1)::(d3,tk3 as TOKEN(id=t3))::(d2,t2)::rest
        guard ((d1==Diff.Add and d2==Diff.Delete) or (d2==Diff.Add and d1==Diff.Delete)) and modelicaDiffTokenEq(t1,t2)
               and (d3==Diff.Equal or d3==Diff.Delete)
               and (t3==TokenId.NEWLINE or t3 == TokenId.WHITESPACE)
        then (false,(Diff.Equal,t1)::(Diff.Equal,tk3)::rest,tmp);

      case (Diff.Add,TOKEN(id=TokenId.NEWLINE))::(Diff.Add,TOKEN(id=TokenId.WHITESPACE))::(rest as (_,TOKEN(id=TokenId.NEWLINE))::_)
        then (false,rest,tmp);
      case (Diff.Add,TOKEN(id=TokenId.NEWLINE))::(rest as (_,TOKEN(id=TokenId.NEWLINE))::_)
        then (false,rest,tmp);
      case (e as (_,TOKEN(id=TokenId.NEWLINE)))::(Diff.Add,TOKEN(id=TokenId.NEWLINE))::rest
        then (false,e::rest,tmp);
      case (e as (_,TOKEN(id=TokenId.NEWLINE)))::rest then (true,rest,e::tmp);
      case (Diff.Add,TOKEN(id=TokenId.WHITESPACE))::(e as (Diff.Add,_))::rest guard lastIsNewline
        then (false,rest,e::
          (Diff.Add,TOKEN("WHITESPACE",TokenId.WHITESPACE,sum(" " for i in 1:depth),1,depth,0,0,0,0))
          ::tmp);
      case (Diff.Add,TOKEN(id=TokenId.WHITESPACE))::(rest as (_,TOKEN(id=TokenId.NEWLINE))::_) guard lastIsNewline
        then (true,rest,tmp);
      case (e as (_,t as TOKEN(id=TokenId.WHITESPACE)))::rest guard lastIsNewline
        algorithm
          TOKEN(length=depth) := t;
        then (false,rest,e::tmp);
      case e::rest then (false,rest,e::tmp);
    end match;
  end while;
  simpleDiff := listReverse(tmp);

  addedLineComments := list(tokenContent(tuple22(e)) for e guard Diff.Add==tuple21(e) and isLineComment(tuple22(e)) in simpleDiff);
  removedLineComments := list(tokenContent(tuple22(e)) for e guard Diff.Delete==tuple21(e) and isLineComment(tuple22(e)) in simpleDiff);

  addedBlockComments := list(blockCommentCanonical(tuple22(e)) for e guard Diff.Add==tuple21(e) and isBlockComment(tuple22(e)) in simpleDiff);
  removedBlockComments := list(blockCommentCanonical(tuple22(e)) for e guard Diff.Delete==tuple21(e) and isBlockComment(tuple22(e)) in simpleDiff);

  simpleDiff := list(
    match e
      local
        Token t;
      case (Diff.Delete,t as TOKEN(id=TokenId.LINE_COMMENT)) then (if listMember(tokenContent(t), addedLineComments) then (Diff.Equal,t) else e);
      case (Diff.Delete,t as TOKEN(id=TokenId.BLOCK_COMMENT)) then (if listMember(blockCommentCanonical(t), addedBlockComments) then (Diff.Equal,t) else e);
      else e;
    end match
    for e guard(
    match e
      local
        Token t;
      case (Diff.Add,t as TOKEN(id=TokenId.LINE_COMMENT)) then not listMember(tokenContent(t), removedLineComments);
      case (Diff.Add,t as TOKEN(id=TokenId.BLOCK_COMMENT)) then not listMember(blockCommentCanonical(t), removedBlockComments);
      else true;
    end match
  ) in simpleDiff);

  odiffs := list(
    match e
      local
        Diff d;
        Token t;
      case (d,t) then (d,{t});
    end match
    for e in simpleDiff);
end filterModelicaDiff;

function isBlockComment
  import LexerModelicaDiff.{Token,TokenId,TOKEN};
  input Token t;
  output Boolean b;
algorithm
  b := match t case TOKEN(id=TokenId.BLOCK_COMMENT) then true; else false; end match;
end isBlockComment;

function isLineComment
  import LexerModelicaDiff.{Token,TokenId,TOKEN};
  input Token t;
  output Boolean b;
algorithm
  b := match t case TOKEN(id=TokenId.LINE_COMMENT) then true; else false; end match;
end isLineComment;

function tuple21<A,B>
  input tuple<A,B> t;
  output A a;
algorithm
  (a,_) := t;
end tuple21;

function tuple22<A,B>
  input tuple<A,B> t;
  output B b;
algorithm
  (_,b) := t;
end tuple22;

function blockCommentCanonical
  import LexerModelicaDiff.{Token,tokenContent};
  input Token t;
  output list<String> lines;
algorithm
  // Canonical representation trims whitespace from each line
  lines := list(System.trim(s) for s in System.strtok(tokenContent(t),"\n"));
end blockCommentCanonical;

function deleteWhitespaceFollowedByEqualNonWhitespace
  import LexerModelicaDiff.{Token,TokenId,TOKEN};
  import DiffAlgorithm.Diff;
  input list<tuple<Diff, Token>> inRest;
  output Boolean b;
  output list<tuple<Diff, Token>> result;
protected
  tuple<Diff, Token> head;
  Diff diff;
  Token t;
  TokenId id;
  list<tuple<Diff, Token>> rest;
  Boolean foundWS=false, foundNL=false;
algorithm
  rest := inRest;
  result := {};
  while not listEmpty(rest) loop
    (head as (diff,t as TOKEN(id=id))) := listHead(rest);
    if diff <> Diff.Delete then
      break;
    end if;
    rest := listRest(rest);
    if id==TokenId.WHITESPACE and not foundWS then
      foundWS := true;
      result := (Diff.Equal,t)::result;
    elseif id==TokenId.NEWLINE then
      foundNL := true;
      break;
    else
      result := head :: result;
    end if;
  end while;
  if (not foundWS) or foundNL then
    // If we find a newline, we probably went too far.
    b := false;
    result := {};
    return;
  end if;
  _ := match rest
    case (Diff.Equal,t)::_ then ();
    else
      algorithm
        b := false;
        result := {};
        return;
      then fail();
  end match;
  b := true;
  for i in result loop
    rest := i::rest;
  end for;
  result := rest;
end deleteWhitespaceFollowedByEqualNonWhitespace;

function reportErrors
  import LexerModelicaDiff.{Token,TokenId,tokenContent,tokenSourceInfo};
  input list<Token> tokens;
protected
  Integer i=0;
  String content;
algorithm
  for t in tokens loop
    i := i+1;
    if i>10 then
      Error.addMessage(Error.SCANNER_ERROR_LIMIT, {});
    end if;
    content := tokenContent(t);
    Error.addSourceMessage(Error.SCANNER_ERROR, {StringUtil.convertCharNonAsciiToHex(content)}, tokenSourceInfo(t));
  end for;
  if not listEmpty(tokens) then
    fail();
  end if;
end reportErrors;

annotation(__OpenModelica_Interface="backend");


end LexerModelicaDiff;

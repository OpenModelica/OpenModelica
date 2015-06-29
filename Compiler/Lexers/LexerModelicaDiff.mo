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

import arrayGet = MetaModelica.Dangerous.arrayGetNoBoundsChecking; // Bounds checked with debug=true
import stringGet = MetaModelica.Dangerous.stringGetNoBoundsChecking;
import MetaModelica.Dangerous.listReverseInPlace;

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
protected
  String contents;
algorithm
  contents := System.readFile(fileName);
  tokens := lex(fileName,contents);
end scan;

function scanString "Scan starts the lexical analysis, load the tables and consume the program to output the tokens"
  input String fileSource "input source code file";
  output list<Token> tokens "return list of tokens";
algorithm
  tokens := lex("<StringSource>",fileSource);
end scanString;



function action
  input Integer act;
  input Integer startSt;
  input Integer mm_currSt,mm_pos,mm_sPos,mm_ePos,mm_linenr,lineNrStart;
  input Integer buffer;
  input Boolean debug;
  input String fileNm;
  input String fileContents;
  output Token token;
  output Integer mm_startSt;
  output Integer bufferRet;
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
    case (1) // #line 29 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("WHITESPACE",TokenId.WHITESPACE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (2) // #line 30 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("WHITESPACE",TokenId.WHITESPACE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (3) // #line 31 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("UNSIGNED_REAL",TokenId.UNSIGNED_REAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (4) // #line 32 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("UNSIGNED_REAL",TokenId.UNSIGNED_REAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (5) // #line 33 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("UNSIGNED_REAL",TokenId.UNSIGNED_REAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (6) // #line 34 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_ALGORITHM",TokenId.T_ALGORITHM,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (7) // #line 35 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_AND",TokenId.T_AND,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (8) // #line 36 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_ANNOTATION",TokenId.T_ANNOTATION,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (9) // #line 37 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("BLOCK",TokenId.BLOCK,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (10) // #line 38 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("CLASS",TokenId.CLASS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (11) // #line 39 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("CONNECT",TokenId.CONNECT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (12) // #line 40 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("CONNECTOR",TokenId.CONNECTOR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (13) // #line 41 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("CONSTANT",TokenId.CONSTANT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (14) // #line 42 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("DISCRETE",TokenId.DISCRETE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (15) // #line 43 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("DER",TokenId.DER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (16) // #line 44 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("DEFINEUNIT",TokenId.DEFINEUNIT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (17) // #line 45 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("EACH",TokenId.EACH,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (18) // #line 46 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("ELSE",TokenId.ELSE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (19) // #line 47 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("ELSEIF",TokenId.ELSEIF,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (20) // #line 48 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("ELSEWHEN",TokenId.ELSEWHEN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (21) // #line 49 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_END",TokenId.T_END,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (22) // #line 50 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("ENUMERATION",TokenId.ENUMERATION,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (23) // #line 51 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("EQUATION",TokenId.EQUATION,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (24) // #line 52 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("ENCAPSULATED",TokenId.ENCAPSULATED,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (25) // #line 53 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("EXPANDABLE",TokenId.EXPANDABLE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (26) // #line 54 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("EXTENDS",TokenId.EXTENDS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (27) // #line 55 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("CONSTRAINEDBY",TokenId.CONSTRAINEDBY,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (28) // #line 56 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("EXTERNAL",TokenId.EXTERNAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (29) // #line 57 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_FALSE",TokenId.T_FALSE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (30) // #line 58 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("FINAL",TokenId.FINAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (31) // #line 59 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("FLOW",TokenId.FLOW,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (32) // #line 60 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("FOR",TokenId.FOR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (33) // #line 61 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("FUNCTION",TokenId.FUNCTION,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (34) // #line 62 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("IF",TokenId.IF,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (35) // #line 63 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("IMPORT",TokenId.IMPORT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (36) // #line 64 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_IN",TokenId.T_IN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (37) // #line 65 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_INITIAL",TokenId.T_INITIAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (38) // #line 66 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("INNER",TokenId.INNER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (39) // #line 67 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_INPUT",TokenId.T_INPUT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (40) // #line 68 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("LOOP",TokenId.LOOP,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (41) // #line 69 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("MODEL",TokenId.MODEL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (42) // #line 70 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_NOT",TokenId.T_NOT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (43) // #line 71 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_OUTER",TokenId.T_OUTER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (44) // #line 72 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("OPERATOR",TokenId.OPERATOR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (45) // #line 73 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("OVERLOAD",TokenId.OVERLOAD,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (46) // #line 74 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_OR",TokenId.T_OR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (47) // #line 75 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_OUTPUT",TokenId.T_OUTPUT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (48) // #line 76 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_PACKAGE",TokenId.T_PACKAGE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (49) // #line 77 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("PARAMETER",TokenId.PARAMETER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (50) // #line 78 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("PARTIAL",TokenId.PARTIAL,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (51) // #line 79 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("PROTECTED",TokenId.PROTECTED,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (52) // #line 80 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("PUBLIC",TokenId.PUBLIC,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (53) // #line 81 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("RECORD",TokenId.RECORD,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (54) // #line 82 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("REDECLARE",TokenId.REDECLARE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (55) // #line 83 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("REPLACEABLE",TokenId.REPLACEABLE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (56) // #line 84 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("RESULTS",TokenId.RESULTS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (57) // #line 85 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("THEN",TokenId.THEN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (58) // #line 86 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_TRUE",TokenId.T_TRUE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (59) // #line 87 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("TYPE",TokenId.TYPE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (60) // #line 88 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("WHEN",TokenId.WHEN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (61) // #line 89 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("WHILE",TokenId.WHILE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (62) // #line 90 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("WITHIN",TokenId.WITHIN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (63) // #line 91 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("RETURN",TokenId.RETURN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (64) // #line 92 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("BREAK",TokenId.BREAK,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (65) // #line 94 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("LPAR",TokenId.LPAR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (66) // #line 95 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("RPAR",TokenId.RPAR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (67) // #line 96 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("LBRACK",TokenId.LBRACK,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (68) // #line 97 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("RBRACK",TokenId.RBRACK,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (69) // #line 98 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("LBRACE",TokenId.LBRACE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (70) // #line 99 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("RBRACE",TokenId.RBRACE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (71) // #line 100 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("EQEQ",TokenId.EQEQ,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (72) // #line 101 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("EQUALS",TokenId.EQUALS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (73) // #line 102 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("COMMA",TokenId.COMMA,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (74) // #line 103 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("ASSIGN",TokenId.ASSIGN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (75) // #line 104 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("COLONCOLON",TokenId.COLONCOLON,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (76) // #line 105 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("COLON",TokenId.COLON,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (77) // #line 106 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("SEMICOLON",TokenId.SEMICOLON,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (78) // #line 108 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("PURE",TokenId.PURE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (79) // #line 109 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("IMPURE",TokenId.IMPURE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (80) // #line 110 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("T_OPTIMIZATION",TokenId.T_OPTIMIZATION,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (81) // #line 112 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("PLUS_EW",TokenId.PLUS_EW,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (82) // #line 113 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("MINUS_EW",TokenId.MINUS_EW,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (83) // #line 114 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("STAR_EW",TokenId.STAR_EW,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (84) // #line 115 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("SLASH_EW",TokenId.SLASH_EW,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (85) // #line 116 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("POWER_EW",TokenId.POWER_EW,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (86) // #line 118 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("STAR",TokenId.STAR,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (87) // #line 119 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("MINUS",TokenId.MINUS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (88) // #line 120 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("PLUS",TokenId.PLUS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (89) // #line 121 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("LESSEQ",TokenId.LESSEQ,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (90) // #line 122 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("LESSGT",TokenId.LESSGT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (91) // #line 123 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("LESS",TokenId.LESS,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (92) // #line 124 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("GREATER",TokenId.GREATER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (93) // #line 125 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("GREATEREQ",TokenId.GREATEREQ,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (94) // #line 127 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("POWER",TokenId.POWER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (95) // #line 128 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("SLASH",TokenId.SLASH,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (96) // #line 130 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("SUBTYPEOF",TokenId.SUBTYPEOF,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (97) // #line 132 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("STREAM",TokenId.STREAM,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (98) // #line 134 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("DOT",TokenId.DOT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (99) // #line 136 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("IDENT",TokenId.IDENT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (100) // #line 137 "lexerModelicaDiff.l"
      equation
        tok = TOKEN("UNSIGNED_INTEGER",TokenId.UNSIGNED_INTEGER,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (101) // #line 139 "lexerModelicaDiff.l"
      equation
        mm_startSt = 7;
        bufferRet = buffer;
      then noToken;
    case (102) // #line 144 "lexerModelicaDiff.l"
      equation
        bufferRet = buffer;
      then noToken;
    case (103) // #line 145 "lexerModelicaDiff.l"
      equation
        bufferRet = buffer;
      then noToken;
    case (104) // #line 146 "lexerModelicaDiff.l"
      equation
        mm_startSt = 1;
        tok = TOKEN("STRING",TokenId.STRING,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (105) // #line 147 "lexerModelicaDiff.l"
      equation
        bufferRet = buffer;
      then noToken;
    case (106) // #line 148 "lexerModelicaDiff.l"
      equation
        bufferRet = buffer;
      then noToken;
    case (107) // #line 151 "lexerModelicaDiff.l"
      equation
        mm_startSt = 3;
        bufferRet = buffer;
      then noToken;
    case (108) // #line 156 "lexerModelicaDiff.l"
      equation
        mm_startSt = 1;
        tok = TOKEN("BLOCK_COMMENT",TokenId.BLOCK_COMMENT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (109) // #line 157 "lexerModelicaDiff.l"
      equation
        bufferRet = buffer;
      then noToken;
    case (110) // #line 158 "lexerModelicaDiff.l"
      equation
        bufferRet = buffer;
      then noToken;
    case (111) // #line 165 "lexerModelicaDiff.l"
      equation
        mm_startSt = 5;
        bufferRet = buffer;
      then noToken;
    case (112) // #line 171 "lexerModelicaDiff.l"
      equation
        mm_startSt = 1;
        tok = TOKEN("LINE_COMMENT",TokenId.LINE_COMMENT,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
      then tok;
    case (113) // #line 172 "lexerModelicaDiff.l"
      equation
        bufferRet = buffer;
      then noToken;
    case (114) // #line 175 "lexerModelicaDiff.l"
      equation
      then noToken;

    else
      equation
        print("\nLexer unknown rule, action="+String(act)+"\n");
        tok = TOKEN("",TokenId._NO_TOKEN,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
        print(printToken(tok));
      then fail();
  end match;
end action;

type TokenId = enumeration(
  _NO_TOKEN,
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
  ENUMERATION,
  EQEQ,
  EQUALS,
  EQUATION,
  EXPANDABLE,
  EXTENDS,
  EXTERNAL,
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
  INNER,
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
  OPERATOR,
  OVERLOAD,
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
  RESULTS,
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
  TYPE,
  T_ALGORITHM,
  T_AND,
  T_ANNOTATION,
  T_END,
  T_FALSE,
  T_IN,
  T_INITIAL,
  T_INPUT,
  T_NOT,
  T_OPTIMIZATION,
  T_OR,
  T_OUTER,
  T_OUTPUT,
  T_PACKAGE,
  T_TRUE,
  UNSIGNED_INTEGER,
  UNSIGNED_REAL,
  WHEN,
  WHILE,
  WHITESPACE,
  WITHIN
);

uniontype Token
  record TOKEN
    String name;
    TokenId id;
    String fileContents;
    Integer byteOffset,length;
    Integer lineNumberStart;
    Integer columnNumberStart;
    Integer lineNumberEnd;
    Integer columnNumberEnd;
  end TOKEN;
end Token;

constant Token noToken = TOKEN("",TokenId._NO_TOKEN,"",0,0,0,0,0,0);

function printToken
  input Token token;
  output String strTk;
protected
  String tokName,contents;
  Integer lns,cns,lne,cne,byteOffset,length;
algorithm
  TOKEN(name=tokName,lineNumberStart=lns,columnNumberStart=cns,lineNumberEnd=lne,columnNumberEnd=cne,fileContents=contents,byteOffset=byteOffset,length=length) := token;
  contents := if length>0 then substring(contents,byteOffset,byteOffset+length-1) else "";
  strTk := "[TOKEN:" + tokName + " '" +  contents + "' (" + intString(lns) + ":" + intString(cns) + "-"+ intString(lne) + ":" + intString(cne) +")]";
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

protected

function lex "Scan starts the lexical analysis, load the tables and consume the program to output the tokens"
  input String fileName "input source code file";
  input String contents;
  output list<Token> tokens "return list of tokens";
protected
  Integer startSt,numStates,i,r,cTok,cTok2,currSt,pos,sPos,ePos,linenr,contentLen,numBacktrack,buffer,lineNrStart;
  list<Integer> cProg,cProg2;
  list<String> chars;
  array<Integer> states;
  String s1,s2;
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
     (tokens,numBacktrack,startSt,currSt,pos,sPos,ePos,linenr,lineNrStart,buffer,states,numStates) := consume(cTok,tokens,contents,startSt,currSt,pos,sPos,ePos,linenr,lineNrStart,buffer,states,numStates,fileName);
     i := i - numBacktrack + 1;
  end while;
  tokens := listReverseInPlace(tokens);
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
  output list<Token> resToken;
  output Integer bkBuffer = 0;
  output Integer mm_startSt;
  output Integer mm_currSt,mm_pos,mm_sPos,mm_ePos,mm_linenr,lineNrStart;
  output Integer buffer;
  output array<Integer> states;
  output Integer numStates;
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

    (tok,mm_startSt,buffer2) := action(act,mm_startSt,mm_currSt,mm_pos,mm_sPos,mm_ePos,mm_linenr,lineNrStart,buffer,debug,fileName,fileContents);

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
  constant Integer yy_limit = 398;
  constant Integer yy_finish = 443;
  constant Integer yy_acclist[:] = array(
      115,  114,    1,  114,    2,  114,  101,  114,  114,   65,
      114,   66,  114,   86,  114,   88,  114,   73,  114,   87,
      114,   98,  114,   95,  114,  100,  114,   76,  114,   77,
      114,   91,  114,   72,  114,   92,  114,   99,  114,   67,
      114,   68,  114,   94,  114,   99,  114,   99,  114,   99,
      114,   99,  114,   99,  114,   99,  114,   99,  114,   99,
      114,   99,  114,   99,  114,   99,  114,   99,  114,   99,
      114,   99,  114,   99,  114,   99,  114,   69,  114,   70,
      114,  109,  114,  110,  114,  109,  114,  113,  114,  112,
      114,  105,  114,  106,  114,  104,  105,  114,  105,  114,

        1,    2,   99,   83,   81,   82,   84,    5,   85,  107,
      111,    3,  100,   75,   74,   89,   90,   71,   93,   99,
       99,   99,   99,   99,   99,   99,   99,   99,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   99,   34,   99,
       99,   36,   99,   99,   99,   99,   99,   46,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   99,   99,   99,
       99,   99,  108,  102,  103,    3,    4,   99,    7,   99,
       99,   99,   99,   99,   99,   99,   15,   99,   99,   99,
       99,   99,   21,   99,   99,   99,   99,   99,   99,   99,
       99,   32,   99,   99,   99,   99,   99,   99,   99,   99,

       42,   99,   99,   99,   99,   99,   99,   99,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   99,   99,   99,
       99,   99,   99,   99,    5,    3,   99,   99,   99,   99,
       99,   99,   99,   99,   99,   17,   99,   18,   99,   99,
       99,   99,   99,   99,   99,   99,   31,   99,   99,   99,
       99,   99,   99,   99,   40,   99,   99,   99,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   78,   99,   99,
       99,   99,   99,   99,   99,   99,   57,   99,   58,   99,
       59,   99,   60,   99,   99,   99,   99,   99,    9,   99,
       64,   99,   10,   99,   99,   99,   99,   99,   99,   99,

       99,   99,   99,   99,   99,   99,   29,   99,   30,   99,
       99,   99,   99,   99,   38,   99,   39,   99,   41,   99,
       99,   99,   43,   99,   99,   99,   99,   99,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   99,   61,   99,
       99,   99,   99,   99,   99,   99,   99,   99,   19,   99,
       99,   99,   99,   99,   99,   99,   99,   99,   35,   99,
       79,   99,   99,   99,   99,   47,   99,   99,   99,   99,
       99,   99,   52,   99,   53,   99,   99,   99,   99,   63,
       99,   97,   99,   99,   62,   99,   99,   99,   11,   99,
       99,   99,   99,   99,   99,   99,   99,   99,   99,   26,

       99,   99,   99,   37,   99,   99,   99,   99,   48,   99,
       99,   50,   99,   99,   99,   99,   56,   99,   99,   99,
       99,   99,   13,   99,   99,   99,   14,   99,   20,   99,
       99,   99,   23,   99,   99,   28,   99,   33,   99,   44,
       99,   99,   45,   99,   99,   99,   99,   99,   99,    6,
       99,   99,   12,   99,   99,   99,   99,   99,   99,   99,
       49,   99,   51,   99,   54,   99,   99,   96,   99,    8,
       99,   99,   16,   99,   99,   99,   25,   99,   99,   99,
       99,   99,   22,   99,   99,   55,   99,   99,   24,   99,
       80,   99,   27,   99

   );
  constant Integer yy_accept[:] = array(
        1,    1,    1,    1,    1,    1,    1,    1,    1,    2,
        3,    5,    7,    9,   10,   12,   14,   16,   18,   20,
       22,   24,   26,   28,   30,   32,   34,   36,   38,   40,
       42,   44,   46,   48,   50,   52,   54,   56,   58,   60,
       62,   64,   66,   68,   70,   72,   74,   76,   78,   80,
       82,   84,   86,   88,   90,   92,   94,   96,   99,  101,
      102,  103,  104,  104,  105,  106,  107,  108,  109,  110,
      111,  112,  113,  114,  114,  115,  116,  117,  118,  119,
      120,  121,  122,  123,  124,  125,  126,  127,  128,  129,
      130,  131,  132,  133,  134,  135,  136,  137,  138,  139,

      141,  142,  144,  145,  146,  147,  148,  150,  151,  152,
      153,  154,  155,  156,  157,  158,  159,  160,  161,  162,
      163,  164,  165,  166,  166,  167,  167,  167,  168,  169,
      171,  172,  173,  174,  175,  176,  177,  179,  180,  181,
      182,  183,  185,  186,  187,  188,  189,  190,  191,  192,
      194,  195,  196,  197,  198,  199,  200,  201,  203,  204,
      205,  206,  207,  208,  209,  210,  211,  212,  213,  214,
      215,  216,  217,  218,  219,  220,  221,  222,  223,  224,
      225,  225,  226,  226,  227,  228,  229,  230,  231,  232,
      233,  234,  235,  236,  238,  240,  241,  242,  243,  244,

      245,  246,  247,  249,  250,  251,  252,  253,  254,  255,
      257,  258,  259,  260,  261,  262,  263,  264,  265,  266,
      267,  268,  270,  271,  272,  273,  274,  275,  276,  277,
      279,  281,  283,  285,  286,  287,  288,  289,  291,  293,
      295,  296,  297,  298,  299,  300,  301,  302,  303,  304,
      305,  306,  307,  309,  311,  312,  313,  314,  315,  317,
      319,  321,  322,  323,  325,  326,  327,  328,  329,  330,
      331,  332,  333,  334,  335,  336,  337,  338,  339,  341,
      342,  343,  344,  345,  346,  347,  348,  349,  351,  352,
      353,  354,  355,  356,  357,  358,  359,  361,  363,  364,

      365,  366,  368,  369,  370,  371,  372,  373,  375,  377,
      378,  379,  380,  382,  384,  385,  387,  388,  389,  391,
      392,  393,  394,  395,  396,  397,  398,  399,  400,  402,
      403,  404,  406,  407,  408,  409,  411,  412,  414,  415,
      416,  417,  419,  420,  421,  422,  423,  425,  426,  427,
      429,  431,  432,  433,  435,  436,  438,  440,  442,  443,
      445,  446,  447,  448,  449,  450,  452,  453,  455,  456,
      457,  458,  459,  460,  461,  463,  465,  467,  468,  470,
      472,  473,  475,  476,  477,  479,  480,  481,  482,  483,
      485,  486,  488,  489,  491,  493,  495,  495

   );
  constant Integer yy_ec[:] = array(
        1,    1,    1,    1,    1,    1,    1,    1,    2,    3,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    2,    1,    4,    1,    1,    1,    1,    5,    6,
        7,    8,    9,   10,   11,   12,   13,   14,   14,   14,
       14,   14,   14,   14,   14,   14,   14,   15,   16,   17,
       18,   19,    1,    1,   20,   20,   20,   20,   21,   20,
       20,   20,   20,   20,   20,   20,   20,   20,   20,   20,
       20,   20,   20,   20,   20,   20,   20,   20,   20,   20,
       22,   23,   24,   25,   26,    1,   27,   28,   29,   30,

       31,   32,   33,   34,   35,   20,   36,   37,   38,   39,
       40,   41,   42,   43,   44,   45,   46,   47,   48,   49,
       50,   51,   52,    1,   53,    1,    1,    1,    1,    1,
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
        1,    1,    1,    1,    2,    1,    1,    2,    2,    1,
        2,    1,    2,    3,    1,    1,    1,    2,    1,    3,
        3,    1,    1,    1,    2,    4,    3,    3,    3,    3,
        3,    3,    3,    3,    3,    3,    3,    3,    3,    3,
        3,    3,    3,    3,    3,    3,    3,    3,    3,    3,
        3,    1,    1
   );
  constant Integer yy_base[:] = array(
        0,    0,   51,   52,  439,  438,   53,   58,  440,  443,
       61,  443,  443,  434,  443,  443,  443,  443,  443,  443,
       57,   59,   63,   65,  443,   55,  420,  419,    0,  443,
      443,  443,   48,   49,   51,   58,   63,   69,   69,  396,
      395,  394,   70,   52,  402,   73,   80,   86,  443,  443,
      443,  443,  419,  443,  443,  443,  443,  443,   74,  122,
      443,    0,  426,  443,  443,  443,  443,  108,  443,  443,
      443,  112,  120,  126,  443,  443,  443,  443,  443,  443,
        0,  397,   97,  389,  397,  400,  387,   26,  381,  395,
      379,  115,  376,   58,  384,  381,  379,  375,  378,    0,

      375,  107,  375,  384,  368,  107,    0,  367,  380,  120,
      370,  119,  124,  366,  380,  376,  360,  364,  124,  359,
      443,  443,  127,  161,  143,  162,  389,  388,  361,    0,
      360,  370,  371,  353,  138,  361,    0,  366,  360,  362,
      365,    0,  353,  363,  362,  357,  343,  359,  337,    0,
      355,  120,  338,  351,  335,  339,  348,    0,  335,  342,
      147,  333,  339,   83,  329,  336,  341,  331,  339,  332,
      322,  321,  335,  320,  325,  332,  331,  322,  323,  325,
      344,  343,  342,  341,  311,  308,  316,  315,  306,  318,
      303,  308,  303,    0,  132,  304,  313,  298,  303,  140,

      310,  303,    0,  294,  295,  294,  301,  292,  289,    0,
      296,  305,  293,  287,  283,  291,  300,  288,  290,  293,
      288,    0,  279,  292,  293,  282,  275,  290,  266,    0,
        0,    0,    0,  284,  279,  278,  285,    0,    0,    0,
      282,  154,  279,  278,  276,  273,  262,  262,  269,  273,
      272,  262,    0,    0,  265,  254,  267,  270,    0,    0,
        0,  251,  260,    0,  249,  253,  259,  260,  263,  260,
      259,  257,  249,  256,  239,  244,  244,  240,    0,  241,
      234,  233,  232,  237,  248,  228,  228,    0,  241,  225,
      243,  229,  241,  223,  239,  225,    0,    0,  227,  223,

      211,    0,  234,  229,  214,  221,  212,    0,    0,  229,
      224,  210,    0,    0,  222,    0,  218,  216,  210,  204,
      213,  208,  215,  206,  207,  198,  203,  213,    0,  203,
      200,    0,  195,  210,  206,    0,  204,    0,  203,  190,
      205,    0,  191,  192,  189,  185,    0,  188,  191,    0,
        0,  198,  189,    0,  186,    0,    0,    0,  177,    0,
      178,  190,  188,  190,  185,    0,  177,    0,  184,  169,
      151,  155,  163,  158,    0,    0,    0,  155,    0,    0,
      161,    0,  159,  150,    0,  147,  155,  157,  154,    0,
      119,    0,  106,    0,    0,    0,  443,  197,  201,  205,

      208,  209
   );
  constant Integer yy_def[:] = array(
      397,    1,  398,  398,  399,  399,  400,  400,  397,  397,
      397,  397,  397,  401,  397,  397,  397,  397,  397,  397,
      397,  397,  397,  397,  397,  397,  397,  397,  402,  397,
      397,  397,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  397,  397,
      397,  397,  397,  397,  397,  397,  397,  397,  397,  397,
      397,  402,  401,  397,  397,  397,  397,  397,  397,  397,
      397,  397,  397,  397,  397,  397,  397,  397,  397,  397,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,

      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      397,  397,  397,  397,  397,  397,  397,  397,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      397,  397,  397,  397,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,

      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,

      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,  402,  402,  402,  402,
      402,  402,  402,  402,  402,  402,    0,  397,  397,  397,

      397,  397
   );
  constant Integer yy_nxt[:] = array(
       10,   11,   12,   13,   14,   15,   16,   17,   18,   19,
       20,   21,   22,   23,   24,   25,   26,   27,   28,   29,
       29,   30,   10,   31,   32,   29,   33,   34,   35,   36,
       37,   38,   29,   29,   39,   29,   40,   41,   42,   43,
       44,   29,   45,   46,   47,   29,   29,   48,   29,   29,
       29,   49,   50,   52,   52,   57,   58,  136,   53,   53,
       57,   58,   60,   61,   64,   65,   70,   66,  137,   67,
       68,   71,   77,   78,   72,   59,   73,  122,  110,   75,
       59,   69,   76,   74,   82,   84,   83,   86,   88,   90,
       87,   85,   89,   74,  111,   95,  123,  112,  145,   91,

      100,   92,  146,   96,   93,   97,  101,  102,   98,  218,
      106,   94,  107,  116,   99,  108,  109,  114,  115,  119,
      120,   68,  117,   60,   61,  125,  130,  219,  124,  118,
      122,   72,  126,   73,  127,  131,  127,  159,  124,  128,
       74,  153,  126,  141,  142,  154,  166,  155,  163,  123,
       74,  160,  168,  169,  178,  396,  125,  395,  179,  205,
      143,  167,  164,  126,  170,  206,  245,  171,  172,  181,
      183,  181,  183,  126,  182,  184,  190,  214,  251,  246,
      284,  191,  252,  394,  393,  392,  391,  215,  390,  389,
      388,  387,  386,  385,  384,  383,  285,   51,   51,   51,

       51,   54,   54,   54,   54,   56,   56,   56,   56,   63,
       63,   81,   81,  382,  381,  380,  379,  378,  377,  376,
      375,  374,  373,  372,  371,  370,  369,  368,  367,  366,
      365,  364,  363,  362,  361,  360,  359,  358,  357,  356,
      355,  354,  353,  352,  351,  350,  349,  348,  347,  346,
      345,  344,  343,  342,  341,  340,  339,  338,  337,  336,
      335,  334,  333,  332,  331,  330,  329,  328,  327,  326,
      325,  324,  323,  322,  321,  320,  319,  318,  317,  316,
      315,  314,  313,  312,  311,  310,  309,  308,  307,  306,
      305,  304,  303,  302,  301,  300,  299,  298,  297,  296,

      295,  294,  293,  292,  291,  290,  289,  288,  287,  286,
      283,  282,  281,  280,  279,  278,  277,  276,  275,  274,
      273,  272,  271,  270,  269,  268,  267,  266,  265,  264,
      263,  262,  261,  260,  259,  258,  257,  256,  255,  254,
      253,  250,  249,  248,  247,  244,  243,  242,  241,  240,
      239,  238,  237,  236,  184,  184,  182,  182,  235,  234,
      233,  232,  231,  230,  229,  228,  227,  226,  225,  224,
      223,  222,  221,  220,  217,  216,  213,  212,  211,  210,
      209,  208,  207,  204,  203,  202,  201,  200,  199,  198,
      197,  196,  195,  194,  193,  192,  189,  188,  187,  186,

      185,  128,  128,  180,  177,  176,  175,  174,  173,  165,
      162,  161,  158,  157,  156,  152,  151,  150,  149,  148,
      147,  144,  140,  139,  138,  135,  134,  133,  132,  129,
       62,  121,  113,  105,  104,  103,   80,   79,   62,  397,
       55,   55,    9,  397,  397,  397,  397,  397,  397,  397,
      397,  397,  397,  397,  397,  397,  397,  397,  397,  397,
      397,  397,  397,  397,  397,  397,  397,  397,  397,  397,
      397,  397,  397,  397,  397,  397,  397,  397,  397,  397,
      397,  397,  397,  397,  397,  397,  397,  397,  397,  397,
      397,  397,  397,  397,  397,  397

   );
  constant Integer yy_chk[:] = array(
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    3,    4,    7,    7,   88,    3,    4,
        8,    8,   11,   11,   21,   21,   22,   21,   88,   21,
       21,   22,   26,   26,   23,    7,   23,   59,   44,   24,
        8,   21,   24,   23,   33,   34,   33,   35,   36,   37,
       35,   34,   36,   23,   44,   38,   59,   44,   94,   37,

       39,   37,   94,   38,   37,   38,   39,   39,   38,  164,
       43,   37,   43,   47,   38,   43,   43,   46,   46,   48,
       48,   68,   47,   60,   60,   72,   83,  164,   68,   47,
      123,   73,   72,   73,   74,   83,   74,  106,   68,   74,
       73,  102,   72,   92,   92,  102,  112,  102,  110,  123,
       73,  106,  113,  113,  119,  393,  125,  391,  119,  152,
       92,  112,  110,  125,  113,  152,  195,  113,  113,  124,
      126,  124,  126,  125,  124,  126,  135,  161,  200,  195,
      242,  135,  200,  389,  388,  387,  386,  161,  384,  383,
      381,  378,  374,  373,  372,  371,  242,  398,  398,  398,

      398,  399,  399,  399,  399,  400,  400,  400,  400,  401,
      401,  402,  402,  370,  369,  367,  365,  364,  363,  362,
      361,  359,  355,  353,  352,  349,  348,  346,  345,  344,
      343,  341,  340,  339,  337,  335,  334,  333,  331,  330,
      328,  327,  326,  325,  324,  323,  322,  321,  320,  319,
      318,  317,  315,  312,  311,  310,  307,  306,  305,  304,
      303,  301,  300,  299,  296,  295,  294,  293,  292,  291,
      290,  289,  287,  286,  285,  284,  283,  282,  281,  280,
      278,  277,  276,  275,  274,  273,  272,  271,  270,  269,
      268,  267,  266,  265,  263,  262,  258,  257,  256,  255,

      252,  251,  250,  249,  248,  247,  246,  245,  244,  243,
      241,  237,  236,  235,  234,  229,  228,  227,  226,  225,
      224,  223,  221,  220,  219,  218,  217,  216,  215,  214,
      213,  212,  211,  209,  208,  207,  206,  205,  204,  202,
      201,  199,  198,  197,  196,  193,  192,  191,  190,  189,
      188,  187,  186,  185,  184,  183,  182,  181,  180,  179,
      178,  177,  176,  175,  174,  173,  172,  171,  170,  169,
      168,  167,  166,  165,  163,  162,  160,  159,  157,  156,
      155,  154,  153,  151,  149,  148,  147,  146,  145,  144,
      143,  141,  140,  139,  138,  136,  134,  133,  132,  131,

      129,  128,  127,  120,  118,  117,  116,  115,  114,  111,
      109,  108,  105,  104,  103,  101,   99,   98,   97,   96,
       95,   93,   91,   90,   89,   87,   86,   85,   84,   82,
       63,   53,   45,   42,   41,   40,   28,   27,   14,    9,
        6,    5,  397,  397,  397,  397,  397,  397,  397,  397,
      397,  397,  397,  397,  397,  397,  397,  397,  397,  397,
      397,  397,  397,  397,  397,  397,  397,  397,  397,  397,
      397,  397,  397,  397,  397,  397,  397,  397,  397,  397,
      397,  397,  397,  397,  397,  397,  397,  397,  397,  397,
      397,  397,  397,  397,  397,  397

   );

end LexTable;




end LexerModelicaDiff;

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


import DiffAlgorithm;
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
        tok = TOKEN("NEWLINE",TokenId.NEWLINE,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
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
  NEWLINE,
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
  constant Integer yy_limit = 397;
  constant Integer yy_finish = 441;
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

        1,   99,   83,   81,   82,   84,    5,   85,  107,  111,
        3,  100,   75,   74,   89,   90,   71,   93,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   99,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   34,   99,   99,
       36,   99,   99,   99,   99,   99,   46,   99,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   99,   99,   99,
       99,  108,  102,  103,    3,    4,   99,    7,   99,   99,
       99,   99,   99,   99,   99,   15,   99,   99,   99,   99,
       99,   21,   99,   99,   99,   99,   99,   99,   99,   99,
       32,   99,   99,   99,   99,   99,   99,   99,   99,   42,

       99,   99,   99,   99,   99,   99,   99,   99,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   99,   99,   99,
       99,   99,   99,    5,    3,   99,   99,   99,   99,   99,
       99,   99,   99,   99,   17,   99,   18,   99,   99,   99,
       99,   99,   99,   99,   99,   31,   99,   99,   99,   99,
       99,   99,   99,   40,   99,   99,   99,   99,   99,   99,
       99,   99,   99,   99,   99,   99,   78,   99,   99,   99,
       99,   99,   99,   99,   99,   57,   99,   58,   99,   59,
       99,   60,   99,   99,   99,   99,   99,    9,   99,   64,
       99,   10,   99,   99,   99,   99,   99,   99,   99,   99,

       99,   99,   99,   99,   99,   29,   99,   30,   99,   99,
       99,   99,   99,   38,   99,   39,   99,   41,   99,   99,
       99,   43,   99,   99,   99,   99,   99,   99,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   61,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   19,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   35,   99,   79,
       99,   99,   99,   99,   47,   99,   99,   99,   99,   99,
       99,   52,   99,   53,   99,   99,   99,   99,   63,   99,
       97,   99,   99,   62,   99,   99,   99,   11,   99,   99,
       99,   99,   99,   99,   99,   99,   99,   99,   26,   99,

       99,   99,   37,   99,   99,   99,   99,   48,   99,   99,
       50,   99,   99,   99,   99,   56,   99,   99,   99,   99,
       99,   13,   99,   99,   99,   14,   99,   20,   99,   99,
       99,   23,   99,   99,   28,   99,   33,   99,   44,   99,
       99,   45,   99,   99,   99,   99,   99,   99,    6,   99,
       99,   12,   99,   99,   99,   99,   99,   99,   99,   49,
       99,   51,   99,   54,   99,   99,   96,   99,    8,   99,
       99,   16,   99,   99,   99,   25,   99,   99,   99,   99,
       99,   22,   99,   99,   55,   99,   99,   24,   99,   80,
       99,   27,   99

   );
  constant Integer yy_accept[:] = array(
        1,    1,    1,    1,    1,    1,    1,    1,    1,    2,
        3,    5,    7,    9,   10,   12,   14,   16,   18,   20,
       22,   24,   26,   28,   30,   32,   34,   36,   38,   40,
       42,   44,   46,   48,   50,   52,   54,   56,   58,   60,
       62,   64,   66,   68,   70,   72,   74,   76,   78,   80,
       82,   84,   86,   88,   90,   92,   94,   96,   99,  101,
      102,  103,  103,  104,  105,  106,  107,  108,  109,  110,
      111,  112,  113,  113,  114,  115,  116,  117,  118,  119,
      120,  121,  122,  123,  124,  125,  126,  127,  128,  129,
      130,  131,  132,  133,  134,  135,  136,  137,  138,  140,

      141,  143,  144,  145,  146,  147,  149,  150,  151,  152,
      153,  154,  155,  156,  157,  158,  159,  160,  161,  162,
      163,  164,  165,  165,  166,  166,  166,  167,  168,  170,
      171,  172,  173,  174,  175,  176,  178,  179,  180,  181,
      182,  184,  185,  186,  187,  188,  189,  190,  191,  193,
      194,  195,  196,  197,  198,  199,  200,  202,  203,  204,
      205,  206,  207,  208,  209,  210,  211,  212,  213,  214,
      215,  216,  217,  218,  219,  220,  221,  222,  223,  224,
      224,  225,  225,  226,  227,  228,  229,  230,  231,  232,
      233,  234,  235,  237,  239,  240,  241,  242,  243,  244,

      245,  246,  248,  249,  250,  251,  252,  253,  254,  256,
      257,  258,  259,  260,  261,  262,  263,  264,  265,  266,
      267,  269,  270,  271,  272,  273,  274,  275,  276,  278,
      280,  282,  284,  285,  286,  287,  288,  290,  292,  294,
      295,  296,  297,  298,  299,  300,  301,  302,  303,  304,
      305,  306,  308,  310,  311,  312,  313,  314,  316,  318,
      320,  321,  322,  324,  325,  326,  327,  328,  329,  330,
      331,  332,  333,  334,  335,  336,  337,  338,  340,  341,
      342,  343,  344,  345,  346,  347,  348,  350,  351,  352,
      353,  354,  355,  356,  357,  358,  360,  362,  363,  364,

      365,  367,  368,  369,  370,  371,  372,  374,  376,  377,
      378,  379,  381,  383,  384,  386,  387,  388,  390,  391,
      392,  393,  394,  395,  396,  397,  398,  399,  401,  402,
      403,  405,  406,  407,  408,  410,  411,  413,  414,  415,
      416,  418,  419,  420,  421,  422,  424,  425,  426,  428,
      430,  431,  432,  434,  435,  437,  439,  441,  442,  444,
      445,  446,  447,  448,  449,  451,  452,  454,  455,  456,
      457,  458,  459,  460,  462,  464,  466,  467,  469,  471,
      472,  474,  475,  476,  478,  479,  480,  481,  482,  484,
      485,  487,  488,  490,  492,  494,  494

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
        0,    0,   51,   52,  437,  436,   53,   58,  438,  441,
      435,  441,  441,  431,  441,  441,  441,  441,  441,  441,
       55,   57,   61,   56,  441,   59,  417,  416,    0,  441,
      441,  441,   46,   47,   49,   56,   61,   67,   67,  393,
      392,  391,   68,   74,  399,   50,   78,   84,  441,  441,
      441,  441,  416,  441,  441,  441,  441,  441,   93,  426,
        0,  422,  441,  441,  441,  441,  108,  441,  441,  441,
      109,  112,  123,  441,  441,  441,  441,  441,  441,    0,
      393,   28,  385,  393,  396,  383,   93,  377,  391,  375,
      112,  372,   86,  380,  377,  375,  371,  374,    0,  371,

      109,  371,  380,  364,   48,    0,  363,  376,  106,  366,
      110,  116,  362,  376,  372,  356,  360,  116,  355,  441,
      441,  148,  145,  141,  154,  385,  384,  357,    0,  356,
      366,  367,  349,  125,  357,    0,  362,  356,  358,  361,
        0,  349,  359,  358,  353,  339,  355,  333,    0,  351,
      127,  334,  347,  331,  335,  344,    0,  331,  338,  135,
      329,  335,  143,  325,  332,  337,  327,  335,  328,  318,
      317,  331,  316,  321,  328,  327,  318,  319,  321,  340,
      339,  338,  337,  307,  304,  312,  311,  302,  314,  299,
      304,  299,    0,  139,  300,  309,  294,  299,  136,  306,

      299,    0,  290,  291,  290,  297,  288,  285,    0,  292,
      301,  289,  283,  279,  287,  296,  284,  286,  289,  284,
        0,  275,  288,  289,  278,  271,  286,  262,    0,    0,
        0,    0,  280,  275,  274,  281,    0,    0,    0,  278,
      150,  275,  274,  272,  269,  258,  258,  265,  269,  268,
      258,    0,    0,  261,  250,  263,  266,    0,    0,    0,
      247,  256,    0,  245,  249,  255,  256,  259,  256,  255,
      253,  245,  252,  235,  240,  240,  236,    0,  237,  230,
      229,  228,  233,  244,  224,  224,    0,  237,  221,  239,
      225,  237,  219,  235,  221,    0,    0,  223,  219,  207,

        0,  230,  225,  210,  217,  208,    0,    0,  225,  220,
      206,    0,    0,  218,    0,  214,  212,  206,  200,  209,
      204,  211,  202,  203,  194,  199,  209,    0,  199,  196,
        0,  191,  206,  202,    0,  200,    0,  199,  186,  201,
        0,  187,  188,  185,  181,    0,  184,  187,    0,    0,
      194,  185,    0,  182,    0,    0,    0,  173,    0,  174,
      186,  184,  186,  181,    0,  173,    0,  180,  165,  147,
      151,  159,  154,    0,    0,    0,  149,    0,    0,  155,
        0,  153,  144,    0,  142,  150,  152,  148,    0,   69,
        0,   22,    0,    0,    0,  441,  193,  197,  201,  204,

      205
   );
  constant Integer yy_def[:] = array(
      396,    1,  397,  397,  398,  398,  399,  399,  396,  396,
      396,  396,  396,  400,  396,  396,  396,  396,  396,  396,
      396,  396,  396,  396,  396,  396,  396,  396,  401,  396,
      396,  396,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  396,  396,
      396,  396,  396,  396,  396,  396,  396,  396,  396,  396,
      401,  400,  396,  396,  396,  396,  396,  396,  396,  396,
      396,  396,  396,  396,  396,  396,  396,  396,  396,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,

      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  396,
      396,  396,  396,  396,  396,  396,  396,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  396,
      396,  396,  396,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,

      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,

      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,  401,  401,  401,  401,  401,
      401,  401,  401,  401,  401,    0,  396,  396,  396,  396,

      396
   );
  constant Integer yy_nxt[:] = array(
       10,   11,   12,   13,   14,   15,   16,   17,   18,   19,
       20,   21,   22,   23,   24,   25,   26,   27,   28,   29,
       29,   30,   10,   31,   32,   29,   33,   34,   35,   36,
       37,   38,   29,   29,   39,   29,   40,   41,   42,   43,
       44,   29,   45,   46,   47,   29,   29,   48,   29,   29,
       29,   49,   50,   52,   52,   57,   58,  129,   53,   53,
       57,   58,   63,   64,   69,   65,  130,   66,   67,   70,
       74,  395,   71,   75,   72,   59,   76,   77,  158,   68,
       59,   73,   81,   83,   82,   85,   87,   89,   86,   84,
       88,   73,  159,   94,  113,  114,  121,   90,   99,   91,

      109,   95,   92,   96,  100,  101,   97,  394,  105,   93,
      106,  115,   98,  107,  108,  122,  110,  118,  119,  111,
      116,   67,  124,   71,  135,   72,  144,  117,  123,  125,
      145,  126,   73,  126,  162,  136,  127,  165,  123,  125,
      140,  141,   73,  152,  167,  168,  177,  153,  163,  154,
      178,  121,  166,  180,  124,  180,  169,  142,  181,  170,
      171,  125,  182,  189,  182,  213,  204,  183,  190,  217,
      122,  125,  205,  244,  250,  214,  283,  393,  251,  392,
      391,  390,  389,  388,  387,  386,  245,  218,  385,  384,
      383,  382,  284,   51,   51,   51,   51,   54,   54,   54,

       54,   56,   56,   56,   56,   62,   62,   80,   80,  381,
      380,  379,  378,  377,  376,  375,  374,  373,  372,  371,
      370,  369,  368,  367,  366,  365,  364,  363,  362,  361,
      360,  359,  358,  357,  356,  355,  354,  353,  352,  351,
      350,  349,  348,  347,  346,  345,  344,  343,  342,  341,
      340,  339,  338,  337,  336,  335,  334,  333,  332,  331,
      330,  329,  328,  327,  326,  325,  324,  323,  322,  321,
      320,  319,  318,  317,  316,  315,  314,  313,  312,  311,
      310,  309,  308,  307,  306,  305,  304,  303,  302,  301,
      300,  299,  298,  297,  296,  295,  294,  293,  292,  291,

      290,  289,  288,  287,  286,  285,  282,  281,  280,  279,
      278,  277,  276,  275,  274,  273,  272,  271,  270,  269,
      268,  267,  266,  265,  264,  263,  262,  261,  260,  259,
      258,  257,  256,  255,  254,  253,  252,  249,  248,  247,
      246,  243,  242,  241,  240,  239,  238,  237,  236,  235,
      183,  183,  181,  181,  234,  233,  232,  231,  230,  229,
      228,  227,  226,  225,  224,  223,  222,  221,  220,  219,
      216,  215,  212,  211,  210,  209,  208,  207,  206,  203,
      202,  201,  200,  199,  198,  197,  196,  195,  194,  193,
      192,  191,  188,  187,  186,  185,  184,  127,  127,  179,

      176,  175,  174,  173,  172,  164,  161,  160,  157,  156,
      155,  151,  150,  149,  148,  147,  146,  143,  139,  138,
      137,  134,  133,  132,  131,  128,   61,   60,  120,  112,
      104,  103,  102,   79,   78,   61,   60,  396,   55,   55,
        9,  396,  396,  396,  396,  396,  396,  396,  396,  396,
      396,  396,  396,  396,  396,  396,  396,  396,  396,  396,
      396,  396,  396,  396,  396,  396,  396,  396,  396,  396,
      396,  396,  396,  396,  396,  396,  396,  396,  396,  396,
      396,  396,  396,  396,  396,  396,  396,  396,  396,  396,
      396,  396,  396,  396

   );
  constant Integer yy_chk[:] = array(
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    3,    4,    7,    7,   82,    3,    4,
        8,    8,   21,   21,   22,   21,   82,   21,   21,   22,
       24,  392,   23,   24,   23,    7,   26,   26,  105,   21,
        8,   23,   33,   34,   33,   35,   36,   37,   35,   34,
       36,   23,  105,   38,   46,   46,   59,   37,   39,   37,

       44,   38,   37,   38,   39,   39,   38,  390,   43,   37,
       43,   47,   38,   43,   43,   59,   44,   48,   48,   44,
       47,   67,   71,   72,   87,   72,   93,   47,   67,   71,
       93,   73,   72,   73,  109,   87,   73,  111,   67,   71,
       91,   91,   72,  101,  112,  112,  118,  101,  109,  101,
      118,  122,  111,  123,  124,  123,  112,   91,  123,  112,
      112,  124,  125,  134,  125,  160,  151,  125,  134,  163,
      122,  124,  151,  194,  199,  160,  241,  388,  199,  387,
      386,  385,  383,  382,  380,  377,  194,  163,  373,  372,
      371,  370,  241,  397,  397,  397,  397,  398,  398,  398,

      398,  399,  399,  399,  399,  400,  400,  401,  401,  369,
      368,  366,  364,  363,  362,  361,  360,  358,  354,  352,
      351,  348,  347,  345,  344,  343,  342,  340,  339,  338,
      336,  334,  333,  332,  330,  329,  327,  326,  325,  324,
      323,  322,  321,  320,  319,  318,  317,  316,  314,  311,
      310,  309,  306,  305,  304,  303,  302,  300,  299,  298,
      295,  294,  293,  292,  291,  290,  289,  288,  286,  285,
      284,  283,  282,  281,  280,  279,  277,  276,  275,  274,
      273,  272,  271,  270,  269,  268,  267,  266,  265,  264,
      262,  261,  257,  256,  255,  254,  251,  250,  249,  248,

      247,  246,  245,  244,  243,  242,  240,  236,  235,  234,
      233,  228,  227,  226,  225,  224,  223,  222,  220,  219,
      218,  217,  216,  215,  214,  213,  212,  211,  210,  208,
      207,  206,  205,  204,  203,  201,  200,  198,  197,  196,
      195,  192,  191,  190,  189,  188,  187,  186,  185,  184,
      183,  182,  181,  180,  179,  178,  177,  176,  175,  174,
      173,  172,  171,  170,  169,  168,  167,  166,  165,  164,
      162,  161,  159,  158,  156,  155,  154,  153,  152,  150,
      148,  147,  146,  145,  144,  143,  142,  140,  139,  138,
      137,  135,  133,  132,  131,  130,  128,  127,  126,  119,

      117,  116,  115,  114,  113,  110,  108,  107,  104,  103,
      102,  100,   98,   97,   96,   95,   94,   92,   90,   89,
       88,   86,   85,   84,   83,   81,   62,   60,   53,   45,
       42,   41,   40,   28,   27,   14,   11,    9,    6,    5,
      396,  396,  396,  396,  396,  396,  396,  396,  396,  396,
      396,  396,  396,  396,  396,  396,  396,  396,  396,  396,
      396,  396,  396,  396,  396,  396,  396,  396,  396,  396,
      396,  396,  396,  396,  396,  396,  396,  396,  396,  396,
      396,  396,  396,  396,  396,  396,  396,  396,  396,  396,
      396,  396,  396,  396

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
    case TokenId.IDENT then tokenContent(ta)==tokenContent(tb);
    case TokenId.UNSIGNED_INTEGER then tokenContent(ta)==tokenContent(tb);
    case TokenId.UNSIGNED_REAL
      then stringReal(tokenContent(ta))==stringReal(tokenContent(tb));
    case TokenId.BLOCK_COMMENT
      then valueEq(blockCommentCanonical(ta),blockCommentCanonical(tb));
    case TokenId.LINE_COMMENT then tokenContent(ta)==tokenContent(tb);
    case TokenId.STRING then tokenContent(ta)==tokenContent(tb);
    case TokenId.WHITESPACE then true; // tokenContent(ta)==tokenContent(tb);
    else true;
  end match;
end modelicaDiffTokenEq;

function modelicaDiffTokenWhitespace
  import LexerModelicaDiff.{Token,TokenId,tokenContent};
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
      case (Diff.Add,TOKEN(id=TokenId.WHITESPACE))::(e as (Diff.Add,t))::rest guard lastIsNewline
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

annotation(__OpenModelica_Interface="backend");


end LexerModelicaDiff;

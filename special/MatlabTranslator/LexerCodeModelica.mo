encapsulated package LexerCodeModelica // Generated OMCCp v0.10.0 OpenModelica lexer and parser generator (2014)
  /* 
   Template for Lexer Code
   replace keywords:
   %LexerCode
   %time
   %Token
   %Lexer
   %ParseTable
   %constant
   %nameSpan
   %functions
   %caseAction
  */
import Types;
import TokenModelica;
import LexerModelica;
import ParseTableModelica;
import OMCCTypes;
import Error;



function action
  input Integer act;
  input Integer startSt;
  input Integer mm_currSt,mm_pos,mm_sPos,mm_ePos,mm_linenr,lineNrStart;
  input Integer buffer;
  input Boolean debug;
  input String fileNm;
  input String fileContents;
  output OMCCTypes.Token token;
  output Integer mm_startSt;
  output Integer bufferRet;
protected
  OMCCTypes.Info info;
  String sToken;
  Integer nameSpan,act2;
algorithm
  mm_startSt := startSt;
  nameSpan := 255;
  act2 := act;
  bufferRet := 0;
  (token) := match (act)
    local 
      OMCCTypes.Token tok;
       case (1) // #line 27 "lexerModelica.l"
         equation
           act2 = TokenModelica.FUNCTION;
           tok = OMCCTypes.TOKEN("FUNCTION",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (2) // #line 28 "lexerModelica.l"
         equation
           act2 = TokenModelica.END;
           tok = OMCCTypes.TOKEN("END",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (3) // #line 29 "lexerModelica.l"
         equation
           act2 = TokenModelica.IF;
           tok = OMCCTypes.TOKEN("IF",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (4) // #line 30 "lexerModelica.l"
         equation
           act2 = TokenModelica.ELSEIF;
           tok = OMCCTypes.TOKEN("ELSEIF",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (5) // #line 31 "lexerModelica.l"
         equation
           act2 = TokenModelica.ELSE;
           tok = OMCCTypes.TOKEN("ELSE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (6) // #line 32 "lexerModelica.l"
         equation
           act2 = TokenModelica.WHILE;
           tok = OMCCTypes.TOKEN("WHILE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (7) // #line 33 "lexerModelica.l"
         equation
           act2 = TokenModelica.FOR;
           tok = OMCCTypes.TOKEN("FOR",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (8) // #line 34 "lexerModelica.l"
         equation
           act2 = TokenModelica.SWITCH;
           tok = OMCCTypes.TOKEN("SWITCH",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (9) // #line 35 "lexerModelica.l"
         equation
           act2 = TokenModelica.CASE;
           tok = OMCCTypes.TOKEN("CASE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (10) // #line 36 "lexerModelica.l"
         equation
           act2 = TokenModelica.OTHERWISE;
           tok = OMCCTypes.TOKEN("OTHERWISE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (11) // #line 37 "lexerModelica.l"
         equation
           act2 = TokenModelica.GLOBAL;
           tok = OMCCTypes.TOKEN("GLOBAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (12) // #line 38 "lexerModelica.l"
         equation
           act2 = TokenModelica.BREAK;
           tok = OMCCTypes.TOKEN("BREAK",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (13) // #line 39 "lexerModelica.l"
         equation
           act2 = TokenModelica.CONTINUE;
           tok = OMCCTypes.TOKEN("CONTINUE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (14) // #line 40 "lexerModelica.l"
         equation
           act2 = TokenModelica.RETURN;
           tok = OMCCTypes.TOKEN("RETURN",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (15) // #line 42 "lexerModelica.l"
         equation
           act2 = TokenModelica.CLASSDEF;
           tok = OMCCTypes.TOKEN("CLASSDEF",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (16) // #line 43 "lexerModelica.l"
         equation
           act2 = TokenModelica.PROPERTIES;
           tok = OMCCTypes.TOKEN("PROPERTIES",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (17) // #line 44 "lexerModelica.l"
         equation
           act2 = TokenModelica.METHODS;
           tok = OMCCTypes.TOKEN("METHODS",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (18) // #line 45 "lexerModelica.l"
         equation
           act2 = TokenModelica.EVENTS;
           tok = OMCCTypes.TOKEN("EVENTS",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (19) // #line 46 "lexerModelica.l"
         equation
           act2 = TokenModelica.GET;
           tok = OMCCTypes.TOKEN("GET",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (20) // #line 47 "lexerModelica.l"
         equation
           act2 = TokenModelica.SET;
           tok = OMCCTypes.TOKEN("SET",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (21) // #line 48 "lexerModelica.l"
         equation
           act2 = TokenModelica.TRY;
           tok = OMCCTypes.TOKEN("TRY",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (22) // #line 49 "lexerModelica.l"
         equation
           act2 = TokenModelica.CATCH;
           tok = OMCCTypes.TOKEN("CATCH",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (23) // #line 52 "lexerModelica.l"
         equation
           act2 = TokenModelica.INTEGER;
           tok = OMCCTypes.TOKEN("INTEGER",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (24) // #line 53 "lexerModelica.l"
         equation
           act2 = TokenModelica.NUMBER;
           tok = OMCCTypes.TOKEN("NUMBER",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (25) // #line 54 "lexerModelica.l"
         equation
           act2 = TokenModelica.IMAG_NUM;
           tok = OMCCTypes.TOKEN("IMAG_NUM",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (26) // #line 55 "lexerModelica.l"
         equation
           act2 = TokenModelica.IDENT;
           tok = OMCCTypes.TOKEN("IDENT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (27) // #line 56 "lexerModelica.l"
         equation
         then OMCCTypes.noToken;
       case (28) // #line 57 "lexerModelica.l"
         equation
         then OMCCTypes.noToken;
       case (29) // #line 58 "lexerModelica.l"
         equation
           act2 = TokenModelica.NEWLINES;
           tok = OMCCTypes.TOKEN("NEWLINES",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (30) // #line 60 "lexerModelica.l"
         equation
         then OMCCTypes.noToken;
       case (31) // #line 63 "lexerModelica.l"
         equation
           act2 = TokenModelica.STRING;
           tok = OMCCTypes.TOKEN("STRING",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (32) // #line 65 "lexerModelica.l"
         equation
           act2 = TokenModelica.ADD;
           tok = OMCCTypes.TOKEN("ADD",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (33) // #line 66 "lexerModelica.l"
         equation
           act2 = TokenModelica.SUB;
           tok = OMCCTypes.TOKEN("SUB",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (34) // #line 67 "lexerModelica.l"
         equation
           act2 = TokenModelica.MUL;
           tok = OMCCTypes.TOKEN("MUL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (35) // #line 68 "lexerModelica.l"
         equation
           act2 = TokenModelica.DIV;
           tok = OMCCTypes.TOKEN("DIV",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (36) // #line 69 "lexerModelica.l"
         equation
           act2 = TokenModelica.POW;
           tok = OMCCTypes.TOKEN("POW",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (37) // #line 71 "lexerModelica.l"
         equation
           act2 = TokenModelica.EMUL;
           tok = OMCCTypes.TOKEN("EMUL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (38) // #line 72 "lexerModelica.l"
         equation
           act2 = TokenModelica.EDIV;
           tok = OMCCTypes.TOKEN("EDIV",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (39) // #line 73 "lexerModelica.l"
         equation
           act2 = TokenModelica.ELEFTDIV;
           tok = OMCCTypes.TOKEN("ELEFTDIV",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (40) // #line 74 "lexerModelica.l"
         equation
           act2 = TokenModelica.EPOW;
           tok = OMCCTypes.TOKEN("EPOW",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (41) // #line 76 "lexerModelica.l"
         equation
           act2 = TokenModelica.EXPR_LT;
           tok = OMCCTypes.TOKEN("EXPR_LT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (42) // #line 77 "lexerModelica.l"
         equation
           act2 = TokenModelica.EXPR_GT;
           tok = OMCCTypes.TOKEN("EXPR_GT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (43) // #line 78 "lexerModelica.l"
         equation
           act2 = TokenModelica.EXPR_LE;
           tok = OMCCTypes.TOKEN("EXPR_LE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (44) // #line 79 "lexerModelica.l"
         equation
           act2 = TokenModelica.EXPR_GE;
           tok = OMCCTypes.TOKEN("EXPR_GE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (45) // #line 80 "lexerModelica.l"
         equation
           act2 = TokenModelica.EXPR_EQ;
           tok = OMCCTypes.TOKEN("EXPR_EQ",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (46) // #line 81 "lexerModelica.l"
         equation
           act2 = TokenModelica.EXPR_NE;
           tok = OMCCTypes.TOKEN("EXPR_NE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (47) // #line 83 "lexerModelica.l"
         equation
           act2 = TokenModelica.EXPR_AND;
           tok = OMCCTypes.TOKEN("EXPR_AND",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (48) // #line 84 "lexerModelica.l"
         equation
           act2 = TokenModelica.EXPR_OR;
           tok = OMCCTypes.TOKEN("EXPR_OR",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (49) // #line 85 "lexerModelica.l"
         equation
           act2 = TokenModelica.LEFTDIV;
           tok = OMCCTypes.TOKEN("LEFTDIV",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (50) // #line 86 "lexerModelica.l"
         equation
           act2 = TokenModelica.EXPR_AND_AND;
           tok = OMCCTypes.TOKEN("EXPR_AND_AND",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (51) // #line 87 "lexerModelica.l"
         equation
           act2 = TokenModelica.EXPR_OR_OR;
           tok = OMCCTypes.TOKEN("EXPR_OR_OR",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (52) // #line 88 "lexerModelica.l"
         equation
           act2 = TokenModelica.EXPR_NOT;
           tok = OMCCTypes.TOKEN("EXPR_NOT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (53) // #line 90 "lexerModelica.l"
         equation
           act2 = TokenModelica.COMMA;
           tok = OMCCTypes.TOKEN("COMMA",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (54) // #line 91 "lexerModelica.l"
         equation
           act2 = TokenModelica.EQ;
           tok = OMCCTypes.TOKEN("EQ",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (55) // #line 92 "lexerModelica.l"
         equation
           act2 = TokenModelica.COLON;
           tok = OMCCTypes.TOKEN("COLON",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (56) // #line 93 "lexerModelica.l"
         equation
           act2 = TokenModelica.SEMI_COLON;
           tok = OMCCTypes.TOKEN("SEMI_COLON",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (57) // #line 95 "lexerModelica.l"
         equation
           act2 = TokenModelica.RBRACK;
           tok = OMCCTypes.TOKEN("RBRACK",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (58) // #line 96 "lexerModelica.l"
         equation
           act2 = TokenModelica.LBRACK;
           tok = OMCCTypes.TOKEN("LBRACK",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (59) // #line 97 "lexerModelica.l"
         equation
           act2 = TokenModelica.LPAR;
           tok = OMCCTypes.TOKEN("LPAR",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (60) // #line 98 "lexerModelica.l"
         equation
           act2 = TokenModelica.RPAR;
           tok = OMCCTypes.TOKEN("RPAR",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (61) // #line 99 "lexerModelica.l"
         equation
           act2 = TokenModelica.RBRACE;
           tok = OMCCTypes.TOKEN("RBRACE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (62) // #line 100 "lexerModelica.l"
         equation
           act2 = TokenModelica.LBRACE;
           tok = OMCCTypes.TOKEN("LBRACE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (63) // #line 102 "lexerModelica.l"
         equation
           act2 = TokenModelica.DOT;
           tok = OMCCTypes.TOKEN("DOT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (64) // #line 103 "lexerModelica.l"
         equation
           act2 = TokenModelica.AT;
           tok = OMCCTypes.TOKEN("AT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (65) // #line 105 "lexerModelica.l"
         equation
           act2 = TokenModelica.SUPERCLASSREF;
           tok = OMCCTypes.TOKEN("SUPERCLASSREF",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (66) // #line 106 "lexerModelica.l"
         equation
           act2 = TokenModelica.SUPERCLASSREF;
           tok = OMCCTypes.TOKEN("SUPERCLASSREF",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (67) // #line 107 "lexerModelica.l"
         equation
           act2 = TokenModelica.METAQUERY;
           tok = OMCCTypes.TOKEN("METAQUERY",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (68) // #line 108 "lexerModelica.l"
         equation
           act2 = TokenModelica.METAQUERY;
           tok = OMCCTypes.TOKEN("METAQUERY",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (69) // #line 110 "lexerModelica.l"
         equation           mm_startSt = 5;
         then OMCCTypes.noToken;
       case (70) // #line 115 "lexerModelica.l"
         equation           mm_startSt = 1;
         then OMCCTypes.noToken;
       case (71) // #line 120 "lexerModelica.l"
         equation           mm_startSt = 7;
         then OMCCTypes.noToken;
       case (72) // #line 125 "lexerModelica.l"
         equation           mm_startSt = 1;
         then OMCCTypes.noToken;
       case (73) // #line 129 "lexerModelica.l"
         equation           mm_startSt = 3;
           act2 = TokenModelica.TRANSPOSE;
           tok = OMCCTypes.TOKEN("TRANSPOSE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (74) // #line 133 "lexerModelica.l"
         equation
           act2 = TokenModelica.CTRANSPOSE;
           tok = OMCCTypes.TOKEN("CTRANSPOSE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (75) // #line 137 "lexerModelica.l"
         equation
         then OMCCTypes.noToken;
       case (76) // #line 141 "lexerModelica.l"
         equation
         then OMCCTypes.noToken;

    else
      equation
        tok = OMCCTypes.TOKEN("",act,fileContents,mm_pos,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
        print(OMCCTypes.printToken(tok));
      then (OMCCTypes.noToken);
  end match;
end action;  
   



end LexerCodeModelica;

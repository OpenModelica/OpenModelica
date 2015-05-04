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
       case (1) // #line 30 "lexerModelica.l"
         equation
         then OMCCTypes.noToken;
       case (2) // #line 31 "lexerModelica.l"
         equation
           act2 = TokenModelica.ICON;
           tok = OMCCTypes.TOKEN("ICON",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (3) // #line 32 "lexerModelica.l"
         equation
           act2 = TokenModelica.RCON;
           tok = OMCCTypes.TOKEN("RCON",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (4) // #line 33 "lexerModelica.l"
         equation
           act2 = TokenModelica.RCON;
           tok = OMCCTypes.TOKEN("RCON",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (5) // #line 34 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_AND;
           tok = OMCCTypes.TOKEN("KW_AND",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (6) // #line 35 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_AS;
           tok = OMCCTypes.TOKEN("KW_AS",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (7) // #line 36 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_AXIOM;
           tok = OMCCTypes.TOKEN("KW_AXIOM",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (8) // #line 37 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_DATATYPE;
           tok = OMCCTypes.TOKEN("KW_DATATYPE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (9) // #line 38 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_DEFAULT ;
           tok = OMCCTypes.TOKEN("KW_DEFAULT ",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (10) // #line 39 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_END;
           tok = OMCCTypes.TOKEN("KW_END",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (11) // #line 40 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_EQTYPE;
           tok = OMCCTypes.TOKEN("KW_EQTYPE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (12) // #line 41 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_FAIL;
           tok = OMCCTypes.TOKEN("KW_FAIL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (13) // #line 42 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_LET;
           tok = OMCCTypes.TOKEN("KW_LET",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (14) // #line 43 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_MODULE;
           tok = OMCCTypes.TOKEN("KW_MODULE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (15) // #line 44 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_NOT ;
           tok = OMCCTypes.TOKEN("KW_NOT ",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (16) // #line 45 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_OF;
           tok = OMCCTypes.TOKEN("KW_OF",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (17) // #line 46 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_RELATION;
           tok = OMCCTypes.TOKEN("KW_RELATION",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (18) // #line 47 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_RULE;
           tok = OMCCTypes.TOKEN("KW_RULE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (19) // #line 48 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_TYPE;
           tok = OMCCTypes.TOKEN("KW_TYPE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (20) // #line 49 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_VAL;
           tok = OMCCTypes.TOKEN("KW_VAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (21) // #line 50 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_WITH;
           tok = OMCCTypes.TOKEN("KW_WITH",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (22) // #line 51 "lexerModelica.l"
         equation
           act2 = TokenModelica.KW_WITHTYPE;
           tok = OMCCTypes.TOKEN("KW_WITHTYPE",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (23) // #line 54 "lexerModelica.l"
         equation
           act2 = TokenModelica.AMPERSAND;
           tok = OMCCTypes.TOKEN("AMPERSAND",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (24) // #line 55 "lexerModelica.l"
         equation
           act2 = TokenModelica.LPAR;
           tok = OMCCTypes.TOKEN("LPAR",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (25) // #line 56 "lexerModelica.l"
         equation
           act2 = TokenModelica.RPAR;
           tok = OMCCTypes.TOKEN("RPAR",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (26) // #line 57 "lexerModelica.l"
         equation
           act2 = TokenModelica.STAR;
           tok = OMCCTypes.TOKEN("STAR",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (27) // #line 58 "lexerModelica.l"
         equation
           act2 = TokenModelica.COMMA;
           tok = OMCCTypes.TOKEN("COMMA",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (28) // #line 59 "lexerModelica.l"
         equation
           act2 = TokenModelica.DASHES;
           tok = OMCCTypes.TOKEN("DASHES",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (29) // #line 60 "lexerModelica.l"
         equation
           act2 = TokenModelica.DOT;
           tok = OMCCTypes.TOKEN("DOT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (30) // #line 61 "lexerModelica.l"
         equation
           act2 = TokenModelica.COLONCOLON;
           tok = OMCCTypes.TOKEN("COLONCOLON",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (31) // #line 62 "lexerModelica.l"
         equation
           act2 = TokenModelica.COLON;
           tok = OMCCTypes.TOKEN("COLON",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (32) // #line 63 "lexerModelica.l"
         equation
           act2 = TokenModelica.EQ;
           tok = OMCCTypes.TOKEN("EQ",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (33) // #line 64 "lexerModelica.l"
         equation
           act2 = TokenModelica.FATARROW;
           tok = OMCCTypes.TOKEN("FATARROW",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (34) // #line 65 "lexerModelica.l"
         equation
           act2 = TokenModelica.LBRACK;
           tok = OMCCTypes.TOKEN("LBRACK",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (35) // #line 66 "lexerModelica.l"
         equation
           act2 = TokenModelica.RBRACK;
           tok = OMCCTypes.TOKEN("RBRACK",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (36) // #line 67 "lexerModelica.l"
         equation
           act2 = TokenModelica.WILD;
           tok = OMCCTypes.TOKEN("WILD",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (37) // #line 68 "lexerModelica.l"
         equation
           act2 = TokenModelica.BAR;
           tok = OMCCTypes.TOKEN("BAR",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (38) // #line 72 "lexerModelica.l"
         equation
           act2 = TokenModelica.ADD_INT;
           tok = OMCCTypes.TOKEN("ADD_INT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (39) // #line 73 "lexerModelica.l"
         equation
           act2 = TokenModelica.SUB_INT;
           tok = OMCCTypes.TOKEN("SUB_INT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (40) // #line 74 "lexerModelica.l"
         equation
           act2 = TokenModelica.NEG_INT;
           tok = OMCCTypes.TOKEN("NEG_INT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (41) // #line 75 "lexerModelica.l"
         equation
           act2 = TokenModelica.DIV_INT;
           tok = OMCCTypes.TOKEN("DIV_INT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (42) // #line 76 "lexerModelica.l"
         equation
           act2 = TokenModelica.MOD_INT;
           tok = OMCCTypes.TOKEN("MOD_INT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (43) // #line 77 "lexerModelica.l"
         equation
           act2 = TokenModelica.EQEQ_INT;
           tok = OMCCTypes.TOKEN("EQEQ_INT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (44) // #line 78 "lexerModelica.l"
         equation
           act2 = TokenModelica.GE_INT;
           tok = OMCCTypes.TOKEN("GE_INT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (45) // #line 79 "lexerModelica.l"
         equation
           act2 = TokenModelica.GT_INT;
           tok = OMCCTypes.TOKEN("GT_INT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (46) // #line 80 "lexerModelica.l"
         equation
           act2 = TokenModelica.LE_INT;
           tok = OMCCTypes.TOKEN("LE_INT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (47) // #line 81 "lexerModelica.l"
         equation
           act2 = TokenModelica.LT_INT;
           tok = OMCCTypes.TOKEN("LT_INT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (48) // #line 82 "lexerModelica.l"
         equation
           act2 = TokenModelica.NOTEQ_INT;
           tok = OMCCTypes.TOKEN("NOTEQ_INT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (49) // #line 83 "lexerModelica.l"
         equation
           act2 = TokenModelica.NOTEQ_INT;
           tok = OMCCTypes.TOKEN("NOTEQ_INT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (50) // #line 85 "lexerModelica.l"
         equation
           act2 = TokenModelica.ADD_REAL;
           tok = OMCCTypes.TOKEN("ADD_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (51) // #line 86 "lexerModelica.l"
         equation
           act2 = TokenModelica.SUB_REAL;
           tok = OMCCTypes.TOKEN("SUB_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (52) // #line 87 "lexerModelica.l"
         equation
           act2 = TokenModelica.NEG_REAL;
           tok = OMCCTypes.TOKEN("NEG_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (53) // #line 88 "lexerModelica.l"
         equation
           act2 = TokenModelica.MUL_REAL;
           tok = OMCCTypes.TOKEN("MUL_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (54) // #line 89 "lexerModelica.l"
         equation
           act2 = TokenModelica.DIV_REAL;
           tok = OMCCTypes.TOKEN("DIV_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (55) // #line 90 "lexerModelica.l"
         equation
           act2 = TokenModelica.MOD_REAL;
           tok = OMCCTypes.TOKEN("MOD_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (56) // #line 91 "lexerModelica.l"
         equation
           act2 = TokenModelica.POWER_REAL;
           tok = OMCCTypes.TOKEN("POWER_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (57) // #line 92 "lexerModelica.l"
         equation
           act2 = TokenModelica.EQEQ_REAL;
           tok = OMCCTypes.TOKEN("EQEQ_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (58) // #line 93 "lexerModelica.l"
         equation
           act2 = TokenModelica.GE_REAL;
           tok = OMCCTypes.TOKEN("GE_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (59) // #line 94 "lexerModelica.l"
         equation
           act2 = TokenModelica.GT_REAL;
           tok = OMCCTypes.TOKEN("GT_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (60) // #line 95 "lexerModelica.l"
         equation
           act2 = TokenModelica.LE_REAL;
           tok = OMCCTypes.TOKEN("LE_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (61) // #line 96 "lexerModelica.l"
         equation
           act2 = TokenModelica.LT_REAL;
           tok = OMCCTypes.TOKEN("LT_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (62) // #line 97 "lexerModelica.l"
         equation
           act2 = TokenModelica.NOTEQ_REAL;
           tok = OMCCTypes.TOKEN("NOTEQ_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (63) // #line 98 "lexerModelica.l"
         equation
           act2 = TokenModelica.NOTEQ_REAL;
           tok = OMCCTypes.TOKEN("NOTEQ_REAL",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (64) // #line 101 "lexerModelica.l"
         equation
           act2 = TokenModelica.SCON;
           tok = OMCCTypes.TOKEN("SCON",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (65) // #line 103 "lexerModelica.l"
         equation
           act2 = TokenModelica.IDENT;
           tok = OMCCTypes.TOKEN("IDENT",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (66) // #line 104 "lexerModelica.l"
         equation
           act2 = TokenModelica.TYVAR ;
           tok = OMCCTypes.TOKEN("TYVAR ",act2,fileContents,mm_pos-buffer,buffer,lineNrStart,mm_ePos+1,mm_linenr,mm_sPos+1);
         then tok;
        case (67) // #line 107 "lexerModelica.l"
         equation           mm_startSt = 3;
         then OMCCTypes.noToken;
       case (68) // #line 112 "lexerModelica.l"
         equation           mm_startSt = 1;
         then OMCCTypes.noToken;
       case (69) // #line 114 "lexerModelica.l"
         equation
         then OMCCTypes.noToken;
       case (70) // #line 115 "lexerModelica.l"
         equation
         then OMCCTypes.noToken;
       case (71) // #line 121 "lexerModelica.l"
         equation           mm_startSt = 5;
         then OMCCTypes.noToken;
       case (72) // #line 126 "lexerModelica.l"
         equation           mm_startSt = 1;
         then OMCCTypes.noToken;
       case (73) // #line 127 "lexerModelica.l"
         equation
         then OMCCTypes.noToken;
       case (74) // #line 128 "lexerModelica.l"
         equation
         then OMCCTypes.noToken;
       case (75) // #line 134 "lexerModelica.l"
         equation           mm_startSt = 7;
         then OMCCTypes.noToken;
       case (76) // #line 140 "lexerModelica.l"
         equation           mm_startSt = 1;
         then OMCCTypes.noToken;
       case (77) // #line 143 "lexerModelica.l"
         equation
         then OMCCTypes.noToken;
       case (78) // #line 149 "lexerModelica.l"
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

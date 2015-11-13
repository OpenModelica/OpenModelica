encapsulated package ParseCodeModelica // OMCCp v0.10.0 OpenModelica lexer and parser generator (2014)
import Types;

constant Boolean debug = false;
// Note: AstItem must be defined, and TOKEN(someToken) must return a valid AstItem (usually a record in the uniontype)


import AbsynMat;
import Absyn;
import OMCCTypes;
import System;

constant list<String> lstSemValue3 = {};

constant list<String> lstSemValue = {
   "error", "$undefined", "FUNCTION", "END", "IF", "ELSEIF", "ELSE", "WHILE", "FOR", 
   "SWITCH", "CASE", "OTHERWISE", "GLOBAL", "BREAK", "CONTINUE", "RETURN", "CLASSDEF", "PROPERTIES",
   "METHODS", "EVENTS", "GET", "SET", "TRY", "CATCH", "INTEGER" ,"NUMBER", "IMAG_NUM", 
   "IDENT", "NEWLINES", "STRING", "+", "-", "*", "/", "^", ".*", "./", "ELEFTDIV", ".^",
   "<", ">", "<=", ">=", "==", "~=",  "&", "|",  "LEFTDIV", "&&", "||", "~", "UNARY", "CTRANSPOSE", "TRANSPOSE", ",", "=", ":", ";",  
   "]", "[", "(", ")", "}", "{", ".", "AT", "SUPERCLASSREF", "METAQUERY", "$accept", "stash_comment", "function_beg", "classdef_beg", 
   "properties_beg", "methods_beg", "events_beg", "sep_no_nl", "opt_sep_no_nl", "sep", "opt_sep", 
   "input", "string", "constant", "magic_colon", "anon_fcn_handle", "fcn_handle", "cell_rows", "cell_rows1",
   "matrix_rows", "matrix_rows1", "matrix", "cell", "primary_expr", "postfix_expr", 
   "prefix_expr", "binary_expr", "simple_expr", "colon_expr", "assign_expr", "expression", "identifier", 
   "fcn_name", "magic_tilde", "superclass_identifier", "meta_identifier", "function1", "function2", 
   "classdef1", "word_list_cmd", "colon_expr1", "arg_list", "word_list", "assign_lhs", "cell_or_matrix_row",
   "param_list", "param_list1", "param_list2", "return_list", "return_list1", "superclasses", "opt_superclasses",
   "command", "select_command", "loop_command", "jump_command", "except_command", "function",
   "script_file", "classdef", "function_file", "function_list", "if_command", "elseif_clauses", "elseif_clause", "switch_command", 
   "switch_case", "default_case", "case_list1", "case_list", "decl2", "decl1", "declaration", "statement", "function_end", "classdef_end", "simple_list", "simple_list1",
   "list", "list1", "opt_list", "input1"};

/* Type Declarations */

uniontype AstItem
  record TOKEN
    OMCCTypes.Token tok;
  end TOKEN;
  
  record ASTSTART
  	AbsynMat.AstStart aststart;
  end ASTSTART;
 
  record START
   	AbsynMat.Start start;
  end START; 
  
  record STRING
  	String string;
  end STRING;

   record IDENT
    AbsynMat.Ident ident;
  end IDENT; 
  
  record EXPRESSION
    AbsynMat.Expression exp;
  end EXPRESSION; 
  
  record LEXPRESSION
   list<AbsynMat.Expression> lexp;
  end LEXPRESSION;

  record ARGUMENT  
    AbsynMat.Argument arg;
  end ARGUMENT;

  record LARGUMENT  
    list<AbsynMat.Argument> larg;
  end LARGUMENT;
    
  record COMMAND  
    AbsynMat.Command cmd;
  end COMMAND;
  
  record LRETURN  
    list<AbsynMat.Return> lret;
  end LRETURN;    
  
  record RETURN
    AbsynMat.Return ret;
  end RETURN;
  
  record PARAMETER 
    AbsynMat.Parameter par;
  end PARAMETER;
  
  record LPARAMETER
    list<AbsynMat.Parameter> lpar;
  end LPARAMETER;
  
  record DECL
    AbsynMat.Decl_Elt decl;
  end DECL;
  
  record LDECL
    list<AbsynMat.Decl_Elt> ldecl;
  end LDECL;
      
  record COMMENT    
    AbsynMat.Mat_Comment cmt;
  end COMMENT;
  
  record LCOMMENT
    list<AbsynMat.Mat_Comment> lcmt;
  end LCOMMENT;
 
  record SWITCH
    AbsynMat.Switch_Case swt;
  end SWITCH;
  
  record LSWITCH
    list<AbsynMat.Switch_Case> lswt;
  end LSWITCH;
  
  record SWTCASES
    tuple<list<AbsynMat.Switch_Case>, Option<AbsynMat.Switch_Case>> swtcases;
  end SWTCASES;

  record STATEMENT
    AbsynMat.Statement stmt;
  end STATEMENT;
      
  record LSTATEMENT    
    list<AbsynMat.Statement> lstmt;
  end LSTATEMENT;

  record LSTART  
    list<AbsynMat.Start> start;
  end LSTART;
  
  record UFUNCTION
    AbsynMat.User_Function ufnc;
  end UFUNCTION;
  
  record LFUNCTION    
    list<AbsynMat.User_Function> lfnc;
  end LFUNCTION;
  
  record OPERATOR
    AbsynMat.Operator oper;
  end OPERATOR;
  
  record SEPARATOR    
    AbsynMat.Separator sep;
  end SEPARATOR;
  
  record LSEPARATOR
    list<AbsynMat.Separator> lsep;
  end LSEPARATOR;
 
  record ELSEIF
    AbsynMat.Elseif elsif;
  end ELSEIF;

  record LELSEIF
    list<AbsynMat.Elseif> lelsif;
  end LELSEIF;

  record CLASS
    AbsynMat.Class cls;
  end CLASS;
  
  record LCLASS
    list<AbsynMat.Class> lcls;
  end LCLASS;
  
  record CELL
    AbsynMat.Cell cell;
  end CELL;
  
  record LCELL
    list<AbsynMat.Cell> lcell;
  end LCELL;
  
  record MATRIX
    AbsynMat.Matrix mtx;
  end MATRIX;
  
  record LMATRIX
    list<AbsynMat.Matrix> lmtx;
  end LMATRIX;    
  
  record CLNEXP
    AbsynMat.Colon_Exp cexp;
  end CLNEXP;
  
  record LEXP
    list<AbsynMat.Colon_Exp> lexp;
  end LEXP;

end AstItem;


uniontype AstStack
  record ASTSTACK
    list<OMCCTypes.Token> stackToken;
    list<AstItem> stack;
  end ASTSTACK;
end AstStack;

function initAstStack
  output AstStack astStack;
 algorithm 
   astStack := ASTSTACK({},{});
end initAstStack;

function actionRed
  input Integer act;
  input AstStack astStack;
  input String fileName;
  output AstStack outStack;
  output Boolean error=false;
  output String errorMsg="";
protected
  list<OMCCTypes.Token> stackToken;
  list<AstItem> stack;
  AstItem yyval;
algorithm
  ASTSTACK(stackToken=stackToken,stack=stack) := astStack;
  if debug then
    print("reduce: " + intString(act) + ", " + intString(listLength(stack)) + " on stack with top token ctor " + intString(valueConstructor(listGet(stackToken,1))) + "\n");
  end if;
  _ := match act
    local
      //local variables
        AstItem yysp_1,yysp_2,yysp_3,yysp_4,yysp_5,yysp_6,yysp_7,yysp_8,yysp_9,yysp_10,yysp_11;

       case 2
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",273));
           (yyval) = SEPARATOR(getSEPARATOR(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",273));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",273));
         then ();

       case 3
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",274));
           (yyval) = ASTSTART(AbsynMat.ASTSTART(getSTART(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",274));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",274));
         then ();

       case 4
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",276));
           (yyval) = SEPARATOR(AbsynMat.NEWLINES()) annotation(__OpenModelica_FileInfo=("parserModelica.y",276));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",276));
         then ();

       case 5
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",279));
           (yyval) = LSTATEMENT({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",279));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",279));
         then ();

       case 6
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",281));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",281));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",281));
           (yyval) = LSTATEMENT(getSTATEMENT(yysp_1)::getLSTATEMENT(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",281));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",281));
         then ();

       case 7
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",283));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",283));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",283));
           (yyval) = STATEMENT(AbsynMat.STATEMENT_APPEND(getSTATEMENT(yysp_1),getSEPARATOR(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",283));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",283));
         then ();

       case 8
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",285));
           (yyval) = STATEMENT(AbsynMat.STATEMENT(NONE(), SOME(getEXPRESSION(yysp_1)), NONE(), NONE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",285));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",285));
         then ();

       case 9
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",286));
           (yyval) = STATEMENT(AbsynMat.STATEMENT(SOME(getCOMMAND(yysp_1)), NONE(), NONE(), NONE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",286));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",286));
         then ();

       case 10
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
           (yyval) = STATEMENT(AbsynMat.STATEMENT(NONE(), NONE(), SOME(getSTART(yysp_1)), NONE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",287));
         then ();

       case 11
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",291));
           (yyval) = STRING(getString(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",291));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",291));
         then ();

       case 12
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",293));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",293));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",293));
         then ();

       case 13
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",295));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",295));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",295));
         then ();

       case 14
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",297));
           (yyval) = EXPRESSION(AbsynMat.INT(stringInt(getString(yysp_1)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",297));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",297));
         then ();

       case 15
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",298));
           (yyval) = EXPRESSION(AbsynMat.NUM(stringReal(getString(yysp_1)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",298));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",298));
         then ();

       case 16
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",299));
           (yyval) = EXPRESSION(AbsynMat.INUM(stringReal(getString(yysp_1)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",299));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",299));
         then ();

       case 17
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",300));
           (yyval) = EXPRESSION(AbsynMat.STR(getString(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",300));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",300));
         then ();

       case 18
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",302));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",302));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",302));
           (yyval) = EXPRESSION(AbsynMat.FINISH_CELL({})) annotation(__OpenModelica_FileInfo=("parserModelica.y",302));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",302));
         then ();

       case 19
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",303));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",303));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",303));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",303));
           (yyval) = EXPRESSION(AbsynMat.FINISH_CELL({})) annotation(__OpenModelica_FileInfo=("parserModelica.y",303));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",303));
         then ();

       case 20
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",304));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",304));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",304));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",304));
           (yyval) = EXPRESSION(AbsynMat.FINISH_CELL(getLCELL(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",304));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",304));
         then ();

       case 21
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",306));
           (yyval) = LCELL(getLCELL(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",306));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",306));
         then ();

       case 22
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",307));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",307));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",307));
           (yyval) = LCELL(getLCELL(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",307));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",307));
         then ();

       case 23
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",309));
           (yyval) = LCELL(getCELL(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",309));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",309));
         then ();

       case 24
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",310));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",310));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",310));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",310));
           (yyval) = LCELL(getCELL(yysp_1)::getLCELL(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",310));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",310));
         then ();

       case 25
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",312));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",312));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",312));
           (yyval) = EXPRESSION(AbsynMat.FINISH_MATRIX({})) annotation(__OpenModelica_FileInfo=("parserModelica.y",312));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",312));
         then ();

       case 26
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",313));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",313));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",313));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",313));
           (yyval) = EXPRESSION(AbsynMat.FINISH_MATRIX({})) annotation(__OpenModelica_FileInfo=("parserModelica.y",313));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",313));
         then ();

       case 27
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
           (yyval) = EXPRESSION(AbsynMat.FINISH_MATRIX({})) annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",314));
         then ();

       case 28
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",315));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",315));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",315));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",315));
           (yyval) = EXPRESSION(AbsynMat.FINISH_MATRIX(getLMATRIX(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",315));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",315));
         then ();

       case 29
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",317));
           (yyval) = LMATRIX(getLMATRIX(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",317));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",317));
         then ();

       case 30
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",318));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",318));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",318));
           (yyval) = LMATRIX(getLMATRIX(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",318));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",318));
         then ();

       case 31
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",320));
           (yyval) = LMATRIX(getMATRIX(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",320));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",320));
         then ();

       case 32
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",321));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",321));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",321));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",321));
           (yyval) = LMATRIX(getMATRIX(yysp_1)::getLMATRIX(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",321));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",321));
         then ();

       case 33
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",323));
           (yyval) = CELL(AbsynMat.CELL(getLARGUMENT(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",323));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",323));
         then ();

       case 34
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",324));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",324));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",324));
           (yyval) = CELL(AbsynMat.CELL(getLARGUMENT(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",324));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",324));
         then ();

       case 35
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",326));
           (yyval) = MATRIX(AbsynMat.MATRIX(getLARGUMENT(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",326));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",326));
         then ();

       case 36
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",327));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",327));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",327));
           (yyval) = MATRIX(AbsynMat.MATRIX(getLARGUMENT(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",327));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",327));
         then ();

       case 37
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",329));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",329));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",329));
           (yyval) = EXPRESSION(AbsynMat.FCN_HANDLE(getIDENT(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",329));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",329));
         then ();

       case 38
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",331));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",331));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",331));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",331));
           (yyval) = EXPRESSION(AbsynMat.ANON_FCN_HANDLE(getLPARAMETER(yysp_2),getSTATEMENT(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",331));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",331));
         then ();

       case 39
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",333));
           (yyval) = EXPRESSION(AbsynMat.IDENTIFIER(getString(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",333));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",333));
         then ();

       case 40
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",334));
           (yyval) = EXPRESSION(getEXPRESSION(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",334));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",334));
         then ();

       case 41
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",335));
           (yyval) = EXPRESSION(getEXPRESSION(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",335));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",335));
         then ();

       case 42
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",336));
           (yyval) = EXPRESSION(getEXPRESSION(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",336));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",336));
         then ();

       case 43
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",337));
           (yyval) = EXPRESSION(getEXPRESSION(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",337));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",337));
         then ();

       case 44
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",338));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",338));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",338));
         then ();

       case 45
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",339));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",339));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",339));
         then ();

       case 46
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",340));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",340));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",340));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",340));
           (yyval) = EXPRESSION(getEXPRESSION(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",340));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",340));
         then ();

       case 47
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",342));
           (yyval) = EXPRESSION(AbsynMat.CONSTANT()) annotation(__OpenModelica_FileInfo=("parserModelica.y",342));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",342));
         then ();

       case 48
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",344));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",344));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",344));
         then ();

       case 49
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",346));
           (yyval) = ARGUMENT(AbsynMat.ARGUMENT(getEXPRESSION(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",346));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",346));
         then ();

       case 50
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",348));
           (yyval) = ARGUMENT(AbsynMat.ARGUMENT(getEXPRESSION(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",348));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",348));
         then ();

       case 51
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",350));
           (yyval) = ARGUMENT(AbsynMat.ARGUMENT(getEXPRESSION(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",350));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",350));
         then ();

       case 52
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",352));
           (yyval) = LARGUMENT(getARGUMENT(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",352));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",352));
         then ();

       case 53
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",353));
           (yyval) = LARGUMENT(getARGUMENT(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",353));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",353));
         then ();

       case 54
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",354));
           (yyval) = LARGUMENT(getARGUMENT(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",354));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",354));
         then ();

       case 55
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",355));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",355));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",355));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",355));
           (yyval) = LARGUMENT(getARGUMENT(yysp_1)::getLARGUMENT(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",355));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",355));
         then ();

       case 56
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",356));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",356));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",356));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",356));
           (yyval) = LARGUMENT(getARGUMENT(yysp_1)::getLARGUMENT(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",356));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",356));
         then ();

       case 57
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
           (yyval) = LARGUMENT(getARGUMENT(yysp_1)::getLARGUMENT(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",357));
         then ();

       case 58
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",359));
           (yyval) = EXPRESSION(getEXPRESSION(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",359));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",359));
         then ();

       case 59
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
           (yyval) = EXPRESSION(AbsynMat.INDEX_EXPRESSION (getEXPRESSION(yysp_1), {})) annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",360));
         then ();

       case 60
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",361));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",361));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",361));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",361));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",361));
           (yyval) = EXPRESSION(AbsynMat.INDEX_EXPRESSION (getEXPRESSION(yysp_1), getLARGUMENT(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",361));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",361));
         then ();

       case 61
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",362));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",362));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",362));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",362));
           (yyval) = EXPRESSION(AbsynMat.INDEX_EXPRESSION (getEXPRESSION(yysp_1), {})) annotation(__OpenModelica_FileInfo=("parserModelica.y",362));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",362));
         then ();

       case 62
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
           (yyval) = EXPRESSION(AbsynMat.INDEX_EXPRESSION (getEXPRESSION(yysp_1), getLARGUMENT(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",363));
         then ();

       case 63
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",364));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",364));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",364));
           (yyval) = EXPRESSION(AbsynMat.POSTFIX_EXPRESSION (getEXPRESSION(yysp_1), AbsynMat.OP_HERMITIAN())) annotation(__OpenModelica_FileInfo=("parserModelica.y",364));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",364));
         then ();

       case 64
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",365));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",365));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",365));
           (yyval) = EXPRESSION(AbsynMat.POSTFIX_EXPRESSION (getEXPRESSION(yysp_1), AbsynMat.OP_TRANSPOSE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",365));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",365));
         then ();

       case 65
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",367));
           (yyval) = EXPRESSION(getEXPRESSION(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",367));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",367));
         then ();

       case 66
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",368));
           (yyval) = EXPRESSION(getEXPRESSION(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",368));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",368));
         then ();

       case 67
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",369));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",369));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",369));
           (yyval) = EXPRESSION(AbsynMat.PREFIX_EXPRESSION(getEXPRESSION(yysp_2),  AbsynMat.EXPR_NOT())) annotation(__OpenModelica_FileInfo=("parserModelica.y",369));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",369));
         then ();

       case 68
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",370));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",370));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",370));
           (yyval) = EXPRESSION(AbsynMat.PREFIX_EXPRESSION(getEXPRESSION(yysp_2), AbsynMat.UPLUS())) annotation(__OpenModelica_FileInfo=("parserModelica.y",370));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",370));
         then ();

       case 69
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",371));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",371));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",371));
           (yyval) = EXPRESSION(AbsynMat.PREFIX_EXPRESSION(getEXPRESSION(yysp_2), AbsynMat.UMINUS())) annotation(__OpenModelica_FileInfo=("parserModelica.y",371));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",371));
         then ();

       case 70
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",373));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",373));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",373));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",373));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.ADD())) annotation(__OpenModelica_FileInfo=("parserModelica.y",373));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",373));
         then ();

       case 71
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",374));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",374));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",374));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",374));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.SUB())) annotation(__OpenModelica_FileInfo=("parserModelica.y",374));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",374));
         then ();

       case 72
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.MUL())) annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",375));
         then ();

       case 73
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",376));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",376));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",376));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",376));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.DIV())) annotation(__OpenModelica_FileInfo=("parserModelica.y",376));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",376));
         then ();

       case 74
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",377));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",377));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",377));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",377));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.POW())) annotation(__OpenModelica_FileInfo=("parserModelica.y",377));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",377));
         then ();

       case 75
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EPOW())) annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",378));
         then ();

       case 76
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",379));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",379));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",379));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",379));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EMUL())) annotation(__OpenModelica_FileInfo=("parserModelica.y",379));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",379));
         then ();

       case 77
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",380));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",380));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",380));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",380));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EDIV())) annotation(__OpenModelica_FileInfo=("parserModelica.y",380));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",380));
         then ();

       case 78
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.LDIV())) annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",381));
         then ();

       case 79
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",382));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",382));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",382));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",382));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.ELEFTDIV())) annotation(__OpenModelica_FileInfo=("parserModelica.y",382));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",382));
         then ();

       case 80
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",384));
           (yyval) = LEXPRESSION(getEXPRESSION(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",384));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",384));
         then ();

       case 81
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",385));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",385));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",385));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",385));
           (yyval) = LEXPRESSION(getEXPRESSION(yysp_1)::getLEXPRESSION(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",385));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",385));
         then ();

       case 82
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",389));
           (yyval) = EXPRESSION(AbsynMat.FINISH_COLON_EXP(getLEXPRESSION(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",389));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",389));
         then ();

       case 83
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",390));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",390));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",390));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",390));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EXPR_LT())) annotation(__OpenModelica_FileInfo=("parserModelica.y",390));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",390));
         then ();

       case 84
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",391));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",391));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",391));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",391));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EXPR_LE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",391));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",391));
         then ();

       case 85
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",392));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",392));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",392));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",392));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EXPR_EQ())) annotation(__OpenModelica_FileInfo=("parserModelica.y",392));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",392));
         then ();

       case 86
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",393));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",393));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",393));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",393));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EXPR_GE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",393));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",393));
         then ();

       case 87
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",394));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",394));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",394));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",394));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EXPR_GT())) annotation(__OpenModelica_FileInfo=("parserModelica.y",394));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",394));
         then ();

       case 88
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",395));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",395));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",395));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",395));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EXPR_NE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",395));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",395));
         then ();

       case 89
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",396));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",396));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",396));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",396));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EXPR_AND())) annotation(__OpenModelica_FileInfo=("parserModelica.y",396));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",396));
         then ();

       case 90
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",397));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",397));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",397));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",397));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EXPR_OR())) annotation(__OpenModelica_FileInfo=("parserModelica.y",397));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",397));
         then ();

       case 91
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",398));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",398));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",398));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",398));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EXPR_AND_AND())) annotation(__OpenModelica_FileInfo=("parserModelica.y",398));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",398));
         then ();

       case 92
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",399));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",399));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",399));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",399));
           (yyval) = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION(yysp_1), getEXPRESSION(yysp_3), AbsynMat.EXPR_OR_OR())) annotation(__OpenModelica_FileInfo=("parserModelica.y",399));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",399));
         then ();

       case 93
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",404));
           (yyval) = ARGUMENT(AbsynMat.ARGUMENT(getEXPRESSION(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",404));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",404));
         then ();

       case 94
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",406));
           (yyval) = LARGUMENT(getARGUMENT(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",406));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",406));
         then ();

       case 95
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",409));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",409));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",409));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",409));
           (yyval) = EXPRESSION(AbsynMat.ASSIGN_OP (getLARGUMENT(yysp_1), AbsynMat.EQ(), getEXPRESSION(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",409));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",409));
         then ();

       case 96
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",411));
           (yyval) = EXPRESSION(getEXPRESSION(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",411));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",411));
         then ();

       case 97
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",412));
           (yyval) = EXPRESSION(getEXPRESSION(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",412));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",412));
         then ();

       case 98
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",413));
           (yyval) = EXPRESSION(getEXPRESSION(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",413));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",413));
         then ();

       case 99
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",417));
           (yyval) = COMMAND(getCOMMAND(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",417));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",417));
         then ();

       case 100
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",418));
           (yyval) = COMMAND(getCOMMAND(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",418));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",418));
         then ();

       case 101
         equation
           stackToken = mergeStackTokens(stackToken,6) annotation(__OpenModelica_FileInfo=("parserModelica.y",423));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",423));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",423));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",423));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",423));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",423));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",423));
           (yyval) = COMMAND(AbsynMat.IF_COMMAND (getEXPRESSION(yysp_3), getSEPARATOR(yysp_4), getLSTATEMENT(yysp_5), {}, NONE(), {}, SOME(getCOMMENT(yysp_2)), NONE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",423));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",423));
         then ();

       case 102
         equation
           stackToken = mergeStackTokens(stackToken,10) annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
           yysp_10::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
           yysp_9::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
           yysp_8::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
           yysp_7::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
           (yyval) = COMMAND(AbsynMat.IF_COMMAND (getEXPRESSION(yysp_3), getSEPARATOR(yysp_4), getLSTATEMENT(yysp_5), {}, SOME(getSEPARATOR(yysp_8)), getLSTATEMENT(yysp_9), SOME(getCOMMENT(yysp_2)), SOME(getCOMMENT(yysp_7)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",425));
         then ();

       case 103
         equation
           stackToken = mergeStackTokens(stackToken,11) annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           yysp_11::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           yysp_10::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           yysp_9::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           yysp_8::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           yysp_7::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           (yyval) = COMMAND(AbsynMat.IF_COMMAND (getEXPRESSION(yysp_3), getSEPARATOR(yysp_4), getLSTATEMENT(yysp_5), getLELSEIF(yysp_6), SOME(getSEPARATOR(yysp_9)), getLSTATEMENT(yysp_10), SOME(getCOMMENT(yysp_2)), SOME(getCOMMENT(yysp_7)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",427));
         then ();

       case 104
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",429));
           (yyval) = LELSEIF(getELSEIF(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",429));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",429));
         then ();

       case 105
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",430));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",430));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",430));
           (yyval) = LELSEIF(getELSEIF(yysp_1)::getLELSEIF(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",430));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",430));
         then ();

       case 106
         equation
           stackToken = mergeStackTokens(stackToken,6) annotation(__OpenModelica_FileInfo=("parserModelica.y",433));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",433));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",433));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",433));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",433));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",433));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",433));
           (yyval) = ELSEIF(AbsynMat.ELSEIF_CLAUSE (getSEPARATOR(yysp_3), getEXPRESSION(yysp_4), getSEPARATOR(yysp_5), getLSTATEMENT(yysp_6), SOME(getCOMMENT(yysp_2)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",433));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",433));
         then ();

       case 107
         equation
           stackToken = mergeStackTokens(stackToken,6) annotation(__OpenModelica_FileInfo=("parserModelica.y",438));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",438));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",438));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",438));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",438));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",438));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",438));
           (yyval) = COMMAND(AbsynMat.SWITCH_COMMAND (getEXPRESSION(yysp_3), getSEPARATOR(yysp_4), getSWTCASES(yysp_5), SOME(getCOMMENT(yysp_2)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",438));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",438));
         then ();

       case 108
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",440));
           (yyval) = SWTCASES(({}, NONE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",440));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",440));
         then ();

       case 109
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",441));
           (yyval) = SWTCASES(({}, SOME(getSWITCH(yysp_1)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",441));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",441));
         then ();

       case 110
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",442));
           (yyval) = SWTCASES((getLSWITCH(yysp_1), NONE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",442));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",442));
         then ();

       case 111
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",443));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",443));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",443));
           (yyval) = SWTCASES((getLSWITCH(yysp_1), SOME(getSWITCH(yysp_2)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",443));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",443));
         then ();

       case 112
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",445));
           (yyval) = LSWITCH(getSWITCH(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",445));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",445));
         then ();

       case 113
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",446));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",446));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",446));
           (yyval) = LSWITCH(getSWITCH(yysp_1)::getLSWITCH(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",446));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",446));
         then ();

       case 114
         equation
           stackToken = mergeStackTokens(stackToken,6) annotation(__OpenModelica_FileInfo=("parserModelica.y",449));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",449));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",449));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",449));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",449));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",449));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",449));
           (yyval) = SWITCH(AbsynMat.SWITCH_CASE (getSEPARATOR(yysp_3),getEXPRESSION(yysp_4), getSEPARATOR(yysp_5), getLSTATEMENT(yysp_6), SOME(getCOMMENT(yysp_2)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",449));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",449));
         then ();

       case 115
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",452));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",452));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",452));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",452));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",452));
           (yyval) = SWITCH(AbsynMat.DEFAULT_CASE(getSEPARATOR(yysp_3), getLSTATEMENT(yysp_4), SOME(getCOMMENT(yysp_2)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",452));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",452));
         then ();

       case 116
         equation
           stackToken = mergeStackTokens(stackToken,6) annotation(__OpenModelica_FileInfo=("parserModelica.y",457));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",457));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",457));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",457));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",457));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",457));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",457));
           (yyval) = COMMAND(AbsynMat.WHILE_COMMAND (getEXPRESSION(yysp_3), SOME(getSEPARATOR(yysp_4)), getLSTATEMENT(yysp_5), SOME(getCOMMENT(yysp_2)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",457));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",457));
         then ();

       case 117
         equation
           stackToken = mergeStackTokens(stackToken,8) annotation(__OpenModelica_FileInfo=("parserModelica.y",459));
           yysp_8::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",459));
           yysp_7::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",459));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",459));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",459));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",459));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",459));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",459));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",459));
           (yyval) = COMMAND(AbsynMat.FOR_COMMAND (getLARGUMENT(yysp_3), getEXPRESSION(yysp_5), SOME(getSEPARATOR(yysp_6)), getLSTATEMENT(yysp_7), SOME(getCOMMENT(yysp_2)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",459));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",459));
         then ();

       case 118
         equation
           stackToken = mergeStackTokens(stackToken,10) annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           yysp_10::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           yysp_9::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           yysp_8::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           yysp_7::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           (yyval) = COMMAND(AbsynMat.FOR_COMMAND (getLARGUMENT(yysp_4), getEXPRESSION(yysp_6), SOME(getSEPARATOR(yysp_8)), getLSTATEMENT(yysp_9), SOME(getCOMMENT(yysp_2)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",461));
         then ();

       case 119
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",465));
           (yyval) = COMMAND(AbsynMat.BREAK_COMMAND ()) annotation(__OpenModelica_FileInfo=("parserModelica.y",465));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",465));
         then ();

       case 120
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",466));
           (yyval) = COMMAND(AbsynMat.CONTINUE_COMMAND ()) annotation(__OpenModelica_FileInfo=("parserModelica.y",466));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",466));
         then ();

       case 121
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",467));
           (yyval) = COMMAND(AbsynMat.RETURN_COMMAND ()) annotation(__OpenModelica_FileInfo=("parserModelica.y",467));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",467));
         then ();

       case 122
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",472));
           (yyval) = COMMAND(getCOMMAND(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",472));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",472));
         then ();

       case 123
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",473));
           (yyval) = COMMAND(getCOMMAND(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",473));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",473));
         then ();

       case 124
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",474));
           (yyval) = COMMAND(getCOMMAND(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",474));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",474));
         then ();

       case 125
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",475));
           (yyval) = COMMAND(getCOMMAND(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",475));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",475));
         then ();

       case 126
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",476));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",476));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",476));
         then ();

       case 127
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",477));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",477));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",477));
         then ();

       case 128
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",485));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",485));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",485));
           (yyval) = COMMAND(AbsynMat.MAKE_DECL_COMMAND(getLDECL(yysp_2))) annotation(__OpenModelica_FileInfo=("parserModelica.y",485));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",485));
         then ();

       case 129
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",487));
           (yyval) = LDECL(getDECL(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",487));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",487));
         then ();

       case 130
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",488));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",488));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",488));
           (yyval) = LDECL(getDECL(yysp_1)::getLDECL(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",488));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",488));
         then ();

       case 131
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",490));
           (yyval) = LDECL({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",490));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",490));
         then ();

       case 132
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",492));
           (yyval) = DECL(AbsynMat.DECL(getString(yysp_1),NONE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",492));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",492));
         then ();

       case 133
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",494));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",494));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",494));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",494));
           (yyval) = DECL(AbsynMat.DECL(getString(yysp_1),SOME(getEXPRESSION(yysp_3)))) annotation(__OpenModelica_FileInfo=("parserModelica.y",494));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",494));
         then ();

       case 134
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",495));
           (yyval) = DECL(AbsynMat.DECL(getIDENT(yysp_1),NONE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",495));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",495));
         then ();

       case 135
         equation
           stackToken = mergeStackTokens(stackToken,9) annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           yysp_9::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           yysp_8::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           yysp_7::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           (yyval) = COMMAND(AbsynMat.TRY_CATCH_COMMAND(getSEPARATOR(yysp_3),getLSTATEMENT(yysp_4),getLSTATEMENT(yysp_8),getLCOMMENT(yysp_2),getLCOMMENT(yysp_6))) annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",500));
         then ();

       case 136
         equation
           stackToken = mergeStackTokens(stackToken,5) annotation(__OpenModelica_FileInfo=("parserModelica.y",502));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",502));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",502));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",502));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",502));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",502));
           (yyval) = COMMAND(AbsynMat.TRY_CATCH_COMMAND(getSEPARATOR(yysp_3),getLSTATEMENT(yysp_4),{},getLCOMMENT(yysp_2),{})) annotation(__OpenModelica_FileInfo=("parserModelica.y",502));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",502));
         then ();

       case 137
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",519));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",519));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",519));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",519));
           (yyval) = LPARAMETER(getPARAMETER(yysp_2)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",519));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",519));
         then ();

       case 138
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",521));
           (yyval) = LPARAMETER({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",521));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",521));
         then ();

       case 139
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",522));
           (yyval) = PARAMETER(AbsynMat.PARM(getLDECL(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",522));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",522));
         then ();

       case 140
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",524));
           (yyval) = LDECL(getDECL(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",524));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",524));
         then ();

       case 141
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",525));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",525));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",525));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",525));
           (yyval) = LDECL(getDECL(yysp_1)::getLDECL(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",525));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",525));
         then ();

       case 142
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",529));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",529));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",529));
           (yyval) = LDECL({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",529));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",529));
         then ();

       case 143
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",530));
           (yyval) = LDECL(getLDECL(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",530));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",530));
         then ();

       case 144
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",531));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",531));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",531));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",531));
           (yyval) = LDECL(getLDECL(yysp_2)) annotation(__OpenModelica_FileInfo=("parserModelica.y",531));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",531));
         then ();

       case 145
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",533));
           (yyval) = LDECL(getDECL(yysp_1)::{}) annotation(__OpenModelica_FileInfo=("parserModelica.y",533));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",533));
         then ();

       case 146
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",534));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",534));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",534));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",534));
           (yyval) = LDECL(getDECL(yysp_1)::getLDECL(yysp_3)) annotation(__OpenModelica_FileInfo=("parserModelica.y",534));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",534));
         then ();

       case 147
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",536));
           (yyval) = DECL(AbsynMat.DECL(getString(yysp_1),NONE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",536));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",536));
         then ();

       case 148
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",541));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",541));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",541));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",541));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",541));
           (yyval) = START(AbsynMat.START(getUFUNCTION(yysp_2), getSEPARATOR(yysp_3), getLSTATEMENT(yysp_4))) annotation(__OpenModelica_FileInfo=("parserModelica.y",541));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",541));
         then ();

       case 149
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",548));
           (yyval) = UFUNCTION(AbsynMat.FINISH_FUNCTION ({},getUFUNCTION(yysp_1))) annotation(__OpenModelica_FileInfo=("parserModelica.y",548));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",548));
         then ();

       case 150
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",549));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",549));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",549));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",549));
           (yyval) = UFUNCTION(AbsynMat.FINISH_FUNCTION (getLDECL(yysp_1),getUFUNCTION(yysp_3))) annotation(__OpenModelica_FileInfo=("parserModelica.y",549));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",549));
         then ();

       case 151
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",551));
           (yyval) = IDENT(getString(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",551));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",551));
         then ();

       case 152
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",552));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",552));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",552));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",552));
           (yyval) = yysp_3 annotation(__OpenModelica_FileInfo=("parserModelica.y",552));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",552));
         then ();

       case 153
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",553));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",553));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",553));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",553));
           (yyval) = yysp_3 annotation(__OpenModelica_FileInfo=("parserModelica.y",553));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",553));
         then ();

       case 154
         equation
           stackToken = mergeStackTokens(stackToken,5) annotation(__OpenModelica_FileInfo=("parserModelica.y",558));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",558));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",558));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",558));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",558));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",558));
           (yyval) = UFUNCTION(AbsynMat.START_FUNCTION (getIDENT(yysp_1),getLPARAMETER(yysp_2), SOME(getSEPARATOR(yysp_3)), getLSTATEMENT(yysp_4), getSTATEMENT(yysp_5))) annotation(__OpenModelica_FileInfo=("parserModelica.y",558));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",558));
         then ();

       case 155
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",559));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",559));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",559));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",559));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",559));
           (yyval) = UFUNCTION(AbsynMat.START_FUNCTION (getIDENT(yysp_1),{}, SOME(getSEPARATOR(yysp_2)), getLSTATEMENT(yysp_3), getSTATEMENT(yysp_4))) annotation(__OpenModelica_FileInfo=("parserModelica.y",559));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",559));
         then ();

       case 156
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",561));
           (yyval) = STATEMENT(AbsynMat.WITHOUT_END()) annotation(__OpenModelica_FileInfo=("parserModelica.y",561));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",561));
         then ();

       case 157
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",562));
           (yyval) = STATEMENT(AbsynMat.MAKE_END ()) annotation(__OpenModelica_FileInfo=("parserModelica.y",562));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",562));
         then ();

       case 158
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",563));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",563));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",563));
           (yyval) = STATEMENT(getSTATEMENT(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",563));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",563));
         then ();

       case 159
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",567));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",567));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",567));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",567));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",567));
         then ();

       case 160
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",569));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",569));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",569));
         then ();

       case 161
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",571));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",571));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",571));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",571));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",571));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",571));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",571));
         then ();

       case 162
         equation
           stackToken = mergeStackTokens(stackToken,6) annotation(__OpenModelica_FileInfo=("parserModelica.y",573));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",573));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",573));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",573));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",573));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",573));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",573));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",573));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",573));
         then ();

       case 163
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",575));
           (yyval) = LCLASS({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",575));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",575));
         then ();

       case 164
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",576));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",576));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",576));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",576));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",576));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",576));
         then ();

       case 165
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",578));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",578));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",578));
         then ();

       case 166
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",579));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",579));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",579));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",579));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",579));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",579));
         then ();

       case 167
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",581));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",581));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",581));
         then ();

       case 168
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",582));
         then ();

       case 169
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",583));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",583));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",583));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",583));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",583));
         then ();

       case 170
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",585));
           (yyval) = LCLASS({}) annotation(__OpenModelica_FileInfo=("parserModelica.y",585));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",585));
         then ();

       case 171
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",586));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",586));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",586));
         then ();

       case 172
         equation
           stackToken = mergeStackTokens(stackToken,4) annotation(__OpenModelica_FileInfo=("parserModelica.y",588));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",588));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",588));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",588));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",588));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",588));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",588));
         then ();

       case 173
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",589));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",589));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",589));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",589));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",589));
         then ();

       case 174
         equation
           stackToken = mergeStackTokens(stackToken,5) annotation(__OpenModelica_FileInfo=("parserModelica.y",590));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",590));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",590));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",590));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",590));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",590));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",590));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",590));
         then ();

       case 175
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",591));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",591));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",591));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",591));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",591));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",591));
         then ();

       case 176
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",593));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",593));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",593));
         then ();

       case 177
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",594));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",594));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",594));
         then ();

       case 178
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",595));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",595));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",595));
         then ();

       case 179
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",596));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",596));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",596));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",596));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",596));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",596));
         then ();

       case 180
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",597));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",597));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",597));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",597));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",597));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",597));
         then ();

       case 181
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",598));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",598));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",598));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",598));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",598));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",598));
         then ();

       case 182
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",600));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",600));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",600));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",600));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",600));
         then ();

       case 183
         equation
           stackToken = mergeStackTokens(stackToken,6) annotation(__OpenModelica_FileInfo=("parserModelica.y",602));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",602));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",602));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",602));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",602));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",602));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",602));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",602));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",602));
         then ();

       case 184
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",604));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",604));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",604));
         then ();

       case 185
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",605));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",605));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",605));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",605));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",605));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",605));
         then ();

       case 186
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",607));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",607));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",607));
         then ();

       case 187
         equation
           stackToken = mergeStackTokens(stackToken,5) annotation(__OpenModelica_FileInfo=("parserModelica.y",608));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",608));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",608));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",608));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",608));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",608));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",608));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",608));
         then ();

       case 188
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",610));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",610));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",610));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",610));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",610));
         then ();

       case 189
         equation
           stackToken = mergeStackTokens(stackToken,6) annotation(__OpenModelica_FileInfo=("parserModelica.y",612));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",612));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",612));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",612));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",612));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",612));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",612));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",612));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",612));
         then ();

       case 190
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",614));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",614));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",614));
         then ();

       case 191
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",615));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",615));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",615));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",615));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",615));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",615));
         then ();

       case 192
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",617));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",617));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",617));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",617));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",617));
         then ();

       case 193
         equation
           stackToken = mergeStackTokens(stackToken,6) annotation(__OpenModelica_FileInfo=("parserModelica.y",619));
           yysp_6::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",619));
           yysp_5::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",619));
           yysp_4::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",619));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",619));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",619));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",619));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",619));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",619));
         then ();

       case 194
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",621));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",621));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",621));
         then ();

       case 195
         equation
           stackToken = mergeStackTokens(stackToken,3) annotation(__OpenModelica_FileInfo=("parserModelica.y",622));
           yysp_3::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",622));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",622));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",622));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",622));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",622));
         then ();

       case 196
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",624));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",624));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",624));
         then ();

       case 197
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",628));
           (yyval) = COMMENT(AbsynMat.COMMENT(NONE())) annotation(__OpenModelica_FileInfo=("parserModelica.y",628));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",628));
         then ();

       case 198
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",630));
           (yyval) = SEPARATOR(AbsynMat.COMMA()) annotation(__OpenModelica_FileInfo=("parserModelica.y",630));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",630));
         then ();

       case 199
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",631));
           (yyval) = SEPARATOR(AbsynMat.SEMI_COLON()) annotation(__OpenModelica_FileInfo=("parserModelica.y",631));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",631));
         then ();

       case 200
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",632));
           (yyval) = SEPARATOR(AbsynMat.NEWLINES()) annotation(__OpenModelica_FileInfo=("parserModelica.y",632));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",632));
         then ();

       case 201
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",633));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",633));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",633));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",633));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",633));
         then ();

       case 202
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",634));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",634));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",634));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",634));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",634));
         then ();

       case 203
         equation
           stackToken = mergeStackTokens(stackToken,2) annotation(__OpenModelica_FileInfo=("parserModelica.y",635));
           yysp_2::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",635));
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",635));
           (yyval) = yysp_1 annotation(__OpenModelica_FileInfo=("parserModelica.y",635));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",635));
         then ();

       case 204
         equation
           stackToken = OMCCTypes.noToken::stackToken annotation(__OpenModelica_FileInfo=("parserModelica.y",637));
           (yyval) = SEPARATOR(AbsynMat.EMPTY()) annotation(__OpenModelica_FileInfo=("parserModelica.y",637));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",637));
         then ();

       case 205
         equation
           yysp_1::stack = stack annotation(__OpenModelica_FileInfo=("parserModelica.y",638));
           (yyval) = SEPARATOR(getSEPARATOR(yysp_1)) annotation(__OpenModelica_FileInfo=("parserModelica.y",638));
           stack = yyval::stack annotation(__OpenModelica_FileInfo=("parserModelica.y",638));
         then ();
    
     else
       equation
          error = true;
       then ();
  end match;
  if debug then
    print("reduce: " + intString(act) + " to " + intString(listLength(stack)) + " on stack\n");
  end if;
  outStack := ASTSTACK(stackToken=stackToken,stack=stack);
end actionRed;  

function mergeStackTokens
  input list<OMCCTypes.Token> skToken;
  input Integer nTokens(min=2);
  output list<OMCCTypes.Token> skTokenRes;
protected
  list<OMCCTypes.Token> skToken1= skToken;
  OMCCTypes.Token token;
  OMCCTypes.Info tmpInfo;
  Integer lns,cns,lne,cne,i;
  String fn;
algorithm
  for i in 1:nTokens loop
     token::skToken1 := skToken1;
     if (i==nTokens) then
        OMCCTypes.TOKEN(lineNumberStart=lns,columnNumberStart=cns) := token;
     end if;
     if (i==1) then
        OMCCTypes.TOKEN(lineNumberEnd=lne,columnNumberEnd=cne) := token;
     end if;
  end for;
  // TODO: merge the contents also?
  token := OMCCTypes.TOKEN("grouped token",0,"",0,0,lns,cns,lne,cne);
  skTokenRes := token::skToken1; 
end mergeStackTokens;

function push
  input AstStack astStk;
  input OMCCTypes.Token token;
  output AstStack astStk2;
protected
  list<OMCCTypes.Token> stackToken;
  list<AstItem> stack;
algorithm
  ASTSTACK(stackToken=stackToken,stack=stack) := astStk;
  stackToken := token::stackToken;
  stack := TOKEN(token)::stack;
  astStk2 := ASTSTACK(stackToken=stackToken,stack=stack);
end push;


public function trimquotes
"removes chars in charsToRemove from inString"
  input String inString;
  output String outString;
 algorithm
  if (stringLength(inString)>2) then
    outString := System.substring(inString,2,stringLength(inString)-1);
  else
    outString := "";
  end if;
end trimquotes;
/*
function getString
  input AstItem item;
  output String out;
algorithm
  out := match item
    local
      OMCCTypes.Token tok;
    case STRING(string=out) then out;
    case TOKEN(tok=tok) then OMCCTypes.getStringValue(tok);
    else equation print("getString() failed\n"); then fail();
  end match;
end getString;
*/

function getString
  input AstItem item;
  output String out;
algorithm
  out := match item
    local
      OMCCTypes.Token tok;
    case STRING(string=out) then out;
    case TOKEN(tok=tok) then OMCCTypes.getStringValue(tok);
    else equation print("getString() failed\n"); then fail();
  end match;
end getString;

function getTOKEN
 input AstItem item;
 output OMCCTypes.Token out;
 algorithm
  TOKEN(tok=out) := item;
end getTOKEN;

function getASTSTART
  input AstItem item;
  output AbsynMat.AstStart out;
algorithm
  ASTSTART(aststart=out) := item;
end getASTSTART; 

function getSTART
 input AstItem item;
 output AbsynMat.Start out;
 algorithm
  START(start=out) := item;
end getSTART;

function getLSTART
 input AstItem item;
 output list<AbsynMat.Start> out;
 algorithm
  LSTART(start=out) := item;
end getLSTART; 

function getIDENT
 input AstItem item;
 output AbsynMat.Ident out;
 algorithm
  IDENT(ident=out) := item;
end getIDENT;

function getEXPRESSION
 input AstItem item;
  output AbsynMat.Expression out;
algorithm
  		EXPRESSION(exp=out) := item;
end getEXPRESSION;
  
function getLEXPRESSION
 input AstItem item;
 output list<AbsynMat.Expression> out;
 algorithm
  LEXPRESSION(lexp=out) := item;
end getLEXPRESSION;

function getARGUMENT
 input AstItem item;
 output AbsynMat.Argument out;
algorithm
  ARGUMENT(arg=out) := item;
end getARGUMENT;

function getLARGUMENT
 input AstItem item;
 output list<AbsynMat.Argument> out;
algorithm
  LARGUMENT(larg=out) := item;
end getLARGUMENT;
  
function getCOMMAND
 input AstItem item;
 output AbsynMat.Command out;
 algorithm
  COMMAND(cmd=out) := item;
end getCOMMAND;
  
function getLRETURN
 input AstItem item;
 output list<AbsynMat.Return> out;
 algorithm
  LRETURN(lret=out) := item;
end getLRETURN;

function getRETURN
 input AstItem item;
 output AbsynMat.Return out;
 algorithm
  RETURN(ret=out) := item;
end getRETURN;

function getPARAMETER
 input AstItem item;
 output AbsynMat.Parameter out;
algorithm
  PARAMETER(par=out) := item;
end getPARAMETER;

  
function getLPARAMETER
 input AstItem item;
 output list<AbsynMat.Parameter> out;
algorithm
  LPARAMETER(lpar=out) := item;
end getLPARAMETER; 
 
function getDECL
 input AstItem item;
 output AbsynMat.Decl_Elt out;
 algorithm
  DECL(decl=out) := item;
end getDECL;
  
function getLDECL
 input AstItem item;
 output list<AbsynMat.Decl_Elt> out;
 algorithm
  LDECL(ldecl=out) := item;
end getLDECL;
  
function getCOMMENT
 input AstItem item;
 output AbsynMat.Mat_Comment out;
algorithm
  COMMENT(cmt=out) := item;
end getCOMMENT;
  
function getLCOMMENT
 input AstItem item;
 output list<AbsynMat.Mat_Comment> out;
 algorithm
  LCOMMENT(lcmt=out) := item;
end getLCOMMENT;

function getSWITCH
 input AstItem item;
 output AbsynMat.Switch_Case out;
algorithm
  SWITCH(swt=out) := item;
end getSWITCH;
  
function getLSWITCH
 input AstItem item;
 output list<AbsynMat.Switch_Case> out;
 algorithm
  LSWITCH(lswt=out) := item;
end getLSWITCH;
  
function getSWTCASES
 input AstItem item;
 output tuple<list<AbsynMat.Switch_Case>, Option<AbsynMat.Switch_Case>> out;
algorithm
  SWTCASES(swtcases=out) := item;
end getSWTCASES;
        
function getSTATEMENT
 input AstItem item;
 output AbsynMat.Statement out;
algorithm
  STATEMENT(stmt=out) := item;
end getSTATEMENT;
      
function getLSTATEMENT
 input AstItem item;
 output list<AbsynMat.Statement> out;
algorithm
  LSTATEMENT(lstmt=out) := item;
end getLSTATEMENT;

function getUFUNCTION
 input AstItem item;
 output AbsynMat.User_Function out;
algorithm
  UFUNCTION(ufnc=out) := item;
end getUFUNCTION;

function getLFUNCTION
 input AstItem item;
 output list<AbsynMat.User_Function> out;
algorithm
  LFUNCTION(lfnc=out) := item;
end getLFUNCTION;

function getOPERATOR
 input AstItem item;
 output AbsynMat.Operator out;
algorithm
  OPERATOR(oper=out) := item;
end getOPERATOR;

function getSEPARATOR
 input AstItem item;
 output AbsynMat.Separator out;
algorithm
  SEPARATOR(sep=out) := item;
end getSEPARATOR;

function getLSEPARATOR
 input AstItem item;
 output list<AbsynMat.Separator> out;
 algorithm
  LSEPARATOR(lsep=out) := item;
end getLSEPARATOR;

function getELSEIF
 input AstItem item;
 output AbsynMat.Elseif out;
 algorithm
  ELSEIF(elsif=out) := item;
end getELSEIF;

function getLELSEIF
 input AstItem item;
 output list<AbsynMat.Elseif> out;
 algorithm
  LELSEIF(lelsif=out) := item;
end getLELSEIF;

function getCLASS
 input AstItem item;
 output AbsynMat.Class out;
algorithm
  CLASS(cls=out) := item;
end getCLASS;

function getLCLASS
 input AstItem item;
 output list<AbsynMat.Class> out;
algorithm
  LCLASS(lcls=out) := item;
end getLCLASS;

function getCELL
 input AstItem item;
 output AbsynMat.Cell out;
algorithm
  CELL(cell=out) := item;
end getCELL;

function getLCELL
 input AstItem item;
 output list<AbsynMat.Cell> out;
algorithm
  LCELL(lcell=out) := item;
end getLCELL;
  
function getMATRIX
 input AstItem item;
 output AbsynMat.Matrix out;
algorithm
  MATRIX(mtx=out) := item;
end getMATRIX;

function getLMATRIX
 input AstItem item;
 output list<AbsynMat.Matrix> out;
 algorithm
  LMATRIX(lmtx=out) := item;
end getLMATRIX;
  
function getCLNEXP
 input AstItem item;
 output AbsynMat.Colon_Exp out;
 algorithm
  CLNEXP(cexp=out) := item;
end getCLNEXP;
  
function getLEXP
 input AstItem item;
 output list<AbsynMat.Colon_Exp> out;
 algorithm
  LEXP(lexp=out) := item;
end getLEXP;



  


end ParseCodeModelica;

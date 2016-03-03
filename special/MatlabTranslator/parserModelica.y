%{
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

%}

   %token FUNCTION
   %token END
   %token IF		
   %token ELSEIF		
   %token ELSE
   %token WHILE 
   %token FOR
   %token SWITCH 
   %token CASE
   %token OTHERWISE   
   %token GLOBAL
   %token BREAK
   %token CONTINUE
   %token RETURN
   
   %token CLASSDEF;
   %token PROPERTIES;
   %token METHODS;
   %token EVENTS;
   %token GET;
   %token SET;
   %token TRY;
   %token CATCH;
   
   %token INTEGER;
   %token NUMBER 
   %token IMAG_NUM
   %token IDENT	
   %token NEWLINES
   %token STRING			 
     
   %left ADD
   %left SUB 
   %left MUL 
   %left DIV 
   %token POW 

   %token EMUL
   %token EDIV
   %token ELEFTDIV
   %token EPOW 

   %token EXPR_LT
   %token EXPR_GT
   %token EXPR_LE
   %token EXPR_GE
   %token EXPR_EQ
   %token EXPR_NE

   %token EXPR_AND
   %token EXPR_OR
   %token LEFTDIV
   %token EXPR_AND_AND
   %token EXPR_OR_OR
   %token EXPR_NOT 
   %left UNARY
   
   %token CTRANSPOSE
   %token TRANSPOSE
   
   %token COMMA 
   %right EQ 
   %token COLON
   %token SEMI_COLON
    
   %token RBRACK
   %token LBRACK
   %token LPAR
   %token RPAR
   %token RBRACE
   %token LBRACE

   %token DOT 
   %token AT;
   %token SUPERCLASSREF;  
   %token METAQUERY;   
   %token FCN_HANDLE;
   
%%

/* Statements and statement lists */
   
input		: input1 { $$ = SEPARATOR(getSEPARATOR($1)); }   
			| function_file { $$ = ASTSTART(AbsynMat.ASTSTART(getSTART($1))); } 
				
input1 	: NEWLINES { $$ = SEPARATOR(AbsynMat.NEWLINES()); } 

opt_list    : // empty
              { $$ = LSTATEMENT({}); }
              | list opt_list
              { $$ = LSTATEMENT(getSTATEMENT($1)::getLSTATEMENT($2)); }                    

list        : statement opt_sep  { $$ = STATEMENT(AbsynMat.STATEMENT_APPEND(getSTATEMENT($1),getSEPARATOR($2))); }

statement 	:			expression		{ $$ = STATEMENT(AbsynMat.STATEMENT(NONE(), SOME(getEXPRESSION($1)), NONE(), NONE())); }
			| 			command		 { $$ = STATEMENT(AbsynMat.STATEMENT(SOME(getCOMMAND($1)), NONE(), NONE(), NONE())); }
			| 			function_file {  $$ = STATEMENT(AbsynMat.STATEMENT(NONE(), NONE(), SOME(getSTART($1)), NONE())); }

  /* Expressions */
  
identifier	: IDENT	{ $$ = STRING(getString($1)); }

superclass_identifier : SUPERCLASSREF  { $$ = $1; }

meta_identifier : METAQUERY { $$ = $1;}

constant	: INTEGER { $$ = EXPRESSION(AbsynMat.INT(stringInt(getString($1)))); }
			| NUMBER { $$ = EXPRESSION(AbsynMat.NUM(stringReal(getString($1)))); }
			| IMAG_NUM { $$ = EXPRESSION(AbsynMat.INUM(stringReal(getString($1)))); } 
			| STRING { $$ = EXPRESSION(AbsynMat.STR(getString($1))); }

cell		: LBRACE RBRACE { $$ = EXPRESSION(AbsynMat.FINISH_CELL({})); }
     		| LBRACE SEMI_COLON RBRACE { $$ = EXPRESSION(AbsynMat.FINISH_CELL({})); }
			| LBRACE cell_rows RBRACE { $$ = EXPRESSION(AbsynMat.FINISH_CELL(getLCELL($2))); }			

cell_rows 	: cell_rows1 { $$ = LCELL(getLCELL($1)); }
			| cell_rows1 SEMI_COLON	/* Ignore trailing semicolon */ { $$ = LCELL(getLCELL($1)); }

cell_rows1	: cell_or_matrix_row { $$ = LCELL(getCELL($1)::{}); } 
			| cell_or_matrix_row SEMI_COLON cell_rows1 { $$ = LCELL(getCELL($1)::getLCELL($3)); }  
              
matrix 		: LBRACK RBRACK { $$ = EXPRESSION(AbsynMat.FINISH_MATRIX({})); }
			| LBRACK SEMI_COLON RBRACK { $$ = EXPRESSION(AbsynMat.FINISH_MATRIX({})); }
			| LBRACK COMMA	RBRACK { $$ = EXPRESSION(AbsynMat.FINISH_MATRIX({})); }			 
			| LBRACK matrix_rows RBRACK { $$ = EXPRESSION(AbsynMat.FINISH_MATRIX(getLMATRIX($2))); }  

matrix_rows:  matrix_rows1 { $$ = LMATRIX(getLMATRIX($1)); }  
			| matrix_rows1 SEMI_COLON /* Ignore trailing semicolon */ { $$ = LMATRIX(getLMATRIX($1)); }
 						
matrix_rows1: cell_or_matrix_row1 { $$ = LMATRIX(getMATRIX($1)::{}); }  
 			| cell_or_matrix_row1 SEMI_COLON matrix_rows1 { $$ = LMATRIX(getMATRIX($1)::getLMATRIX($3)); }

cell_or_matrix_row : arg_list { $$ = CELL(AbsynMat.CELL(getLARGUMENT($1))); }  // $$[Argument] = AbsynMat.VALIDATE_MATRIX_ROW ($1[Argument]); 
			| arg_list 	COMMA /* Ignore trailing comma */ { $$ = CELL(AbsynMat.CELL(getLARGUMENT($1))); } // $$[Argument] = AbsynMat.VALIDATE_MATRIX_ROW ($1[Argument]); 

cell_or_matrix_row1 : arg_list { $$ = MATRIX(AbsynMat.MATRIX(getLARGUMENT($1))); }  
			| arg_list 	COMMA /* Ignore trailing comma */ { $$ = MATRIX(AbsynMat.MATRIX(getLARGUMENT($1))); } 

fcn_handle : AT identifier { $$ = EXPRESSION(AbsynMat.FCN_HANDLE(getIDENT($2)));  }

anon_fcn_handle : AT param_list statement { $$ = EXPRESSION(AbsynMat.ANON_FCN_HANDLE(getLPARAMETER($2),getSTATEMENT($3))); }
  
primary_expr: identifier { $$ = EXPRESSION(AbsynMat.IDENTIFIER(getString($1))); }
			| constant { $$ = EXPRESSION(getEXPRESSION($1)); }
			| matrix { $$ = EXPRESSION(getEXPRESSION($1)); }
		 	| cell { $$ = EXPRESSION(getEXPRESSION($1)); } 
		 	| fcn_handle { $$ = EXPRESSION(getEXPRESSION($1)); }
			| superclass_identifier { $$ = $1; }
			| meta_identifier { $$ = $1; }
			| LPAR expression RPAR { $$ = EXPRESSION(getEXPRESSION($2)); }  

magic_colon	: COLON { $$ = EXPRESSION(AbsynMat.CONSTANT()); }

magic_tilde	: EXPR_NOT { $$ = $1; }   

expression1 : expression { $$ = ARGUMENT(AbsynMat.ARGUMENT(getEXPRESSION($1))); }

magic_colon1 : magic_colon { $$ = ARGUMENT(AbsynMat.ARGUMENT(getEXPRESSION($1))); }

magic_tilde1 : magic_tilde { $$ = ARGUMENT(AbsynMat.ARGUMENT(getEXPRESSION($1))); }

arg_list	: expression1 { $$ = LARGUMENT(getARGUMENT($1)::{}); }
			| magic_colon1 { $$ = LARGUMENT(getARGUMENT($1)::{}); }
			| magic_tilde1 { $$ = LARGUMENT(getARGUMENT($1)::{}); }
			| magic_colon1 COMMA arg_list  { $$ = LARGUMENT(getARGUMENT($1)::getLARGUMENT($3)); }
			| magic_tilde1 COMMA arg_list  { $$ = LARGUMENT(getARGUMENT($1)::getLARGUMENT($3)); }
			| expression1 COMMA arg_list  { $$ = LARGUMENT(getARGUMENT($1)::getLARGUMENT($3)); }

postfix_expr: primary_expr { $$ = EXPRESSION(getEXPRESSION($1)); }
			| postfix_expr LPAR RPAR { $$ = EXPRESSION(AbsynMat.INDEX_EXPRESSION (getEXPRESSION($1), {})); }
			| postfix_expr LPAR arg_list RPAR { $$ = EXPRESSION(AbsynMat.INDEX_EXPRESSION (getEXPRESSION($1), getLARGUMENT($3))); }
			| postfix_expr LBRACE RBRACE { $$ = EXPRESSION(AbsynMat.INDEX_EXPRESSION (getEXPRESSION($1), {})); }
			| postfix_expr LBRACE arg_list RBRACE { $$ = EXPRESSION(AbsynMat.INDEX_EXPRESSION (getEXPRESSION($1), getLARGUMENT($3))); }
			| postfix_expr CTRANSPOSE { $$ = EXPRESSION(AbsynMat.POSTFIX_EXPRESSION (getEXPRESSION($1), AbsynMat.OP_HERMITIAN())); }
            | postfix_expr TRANSPOSE { $$ = EXPRESSION(AbsynMat.POSTFIX_EXPRESSION (getEXPRESSION($1), AbsynMat.OP_TRANSPOSE())); }
 
prefix_expr	: postfix_expr { $$ = EXPRESSION(getEXPRESSION($1)); }
			| binary_expr { $$ = EXPRESSION(getEXPRESSION($1)); }
			| EXPR_NOT prefix_expr %prec UNARY { $$ = EXPRESSION(AbsynMat.PREFIX_EXPRESSION(getEXPRESSION($2),  AbsynMat.EXPR_NOT())); }  
			| ADD prefix_expr %prec UNARY { $$ = EXPRESSION(AbsynMat.PREFIX_EXPRESSION(getEXPRESSION($2), AbsynMat.UPLUS()));  } 
			| SUB prefix_expr %prec	UNARY { $$ = EXPRESSION(AbsynMat.PREFIX_EXPRESSION(getEXPRESSION($2), AbsynMat.UMINUS()));  } 

binary_expr : prefix_expr ADD prefix_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.ADD())); }
			| prefix_expr SUB prefix_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.SUB())); }
			| prefix_expr MUL prefix_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.MUL())); }
			| prefix_expr DIV prefix_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.DIV())); }
			| prefix_expr POW prefix_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.POW())); }
			| prefix_expr EPOW prefix_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EPOW())); }
			| prefix_expr EMUL prefix_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EMUL())); }
			| prefix_expr EDIV prefix_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EDIV())); }
			| prefix_expr LEFTDIV prefix_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.LDIV())); }
			| prefix_expr ELEFTDIV prefix_expr{ $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.ELEFTDIV())); }
             
colon_expr	: prefix_expr { $$ = LEXPRESSION(getEXPRESSION($1)::{}); } // $$[Colon_Exp] = AbsynMat.COLON_EXP ($1[Expression]);
			| prefix_expr COLON colon_expr { $$ = LEXPRESSION(getEXPRESSION($1)::getLEXPRESSION($3)); } // $$[Colon_Exps] = $1[Colon_Exp]::$3[Colon_Exps];  
             
// colon_expr	: colon_expr1 { $$[Expression] = AbsynMat.FINISH_COLON_EXP($1[Colon_Exp]); } 
            
simple_expr	: colon_expr { $$ = EXPRESSION(AbsynMat.FINISH_COLON_EXP(getLEXPRESSION($1))); }  
			| simple_expr EXPR_LT simple_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EXPR_LT())); }
			| simple_expr EXPR_LE simple_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EXPR_LE())); }
			| simple_expr EXPR_EQ simple_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EXPR_EQ())); }
			| simple_expr EXPR_GE simple_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EXPR_GE())); }
			| simple_expr EXPR_GT simple_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EXPR_GT())); }
			| simple_expr EXPR_NE simple_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EXPR_NE())); }
			| simple_expr EXPR_AND simple_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EXPR_AND())); }
			| simple_expr EXPR_OR simple_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EXPR_OR())); }
			| simple_expr EXPR_AND_AND simple_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EXPR_AND_AND())); }
			| simple_expr EXPR_OR_OR simple_expr { $$ = EXPRESSION(AbsynMat.BINARY_EXPRESSION (getEXPRESSION($1), getEXPRESSION($3), AbsynMat.EXPR_OR_OR())); }
            
/* Arrange for the lexer to return CLOSE_BRACE for `]' by looking ahead */
/* one token for an assignment op */
            
simple_expr2	: simple_expr { $$ = ARGUMENT(AbsynMat.ARGUMENT(getEXPRESSION($1))); }  
 
assign_lhs	: simple_expr2 { $$ = LARGUMENT(getARGUMENT($1)::{}); } 
		//	| LBRACK arg_list RBRACK { $$[Arguments] = $2[Arguments]; }  
 
assign_expr	: assign_lhs EQ	expression { $$ = EXPRESSION(AbsynMat.ASSIGN_OP (getLARGUMENT($1), AbsynMat.EQ(), getEXPRESSION($3))); } 
 
expression	: simple_expr { $$ = EXPRESSION(getEXPRESSION($1)); }
			| assign_expr { $$ = EXPRESSION(getEXPRESSION($1)); }
			| anon_fcn_handle { $$ = EXPRESSION(getEXPRESSION($1)); }

 /* Selection statements */
 
select_command: if_command { $$ = COMMAND(getCOMMAND($1)); }
			| switch_command  { $$ = COMMAND(getCOMMAND($1));  }

 /* If statement */
 		   
if_command    : IF stash_comment expression opt_sep opt_list END  
				{ $$ = COMMAND(AbsynMat.IF_COMMAND (getEXPRESSION($3), getSEPARATOR($4), getLSTATEMENT($5), {}, NONE(), {}, SOME(getCOMMENT($2)), NONE())); } 
              | IF stash_comment expression opt_sep opt_list ELSE stash_comment opt_sep opt_list END
                { $$ = COMMAND(AbsynMat.IF_COMMAND (getEXPRESSION($3), getSEPARATOR($4), getLSTATEMENT($5), {}, SOME(getSEPARATOR($8)), getLSTATEMENT($9), SOME(getCOMMENT($2)), SOME(getCOMMENT($7)))); } 
              | IF stash_comment expression opt_sep opt_list elseif_clauses ELSE stash_comment opt_sep opt_list END
				{ $$ = COMMAND(AbsynMat.IF_COMMAND (getEXPRESSION($3), getSEPARATOR($4), getLSTATEMENT($5), getLELSEIF($6), SOME(getSEPARATOR($9)), getLSTATEMENT($10), SOME(getCOMMENT($2)), SOME(getCOMMENT($7)))); } 

elseif_clauses : elseif_clause { $$ = LELSEIF(getELSEIF($1)::{}); }
              | elseif_clause elseif_clauses { $$ = LELSEIF(getELSEIF($1)::getLELSEIF($2)); }
               
elseif_clause :  ELSEIF stash_comment opt_sep expression opt_sep opt_list
				{ $$ = ELSEIF(AbsynMat.ELSEIF_CLAUSE (getSEPARATOR($3), getEXPRESSION($4), getSEPARATOR($5), getLSTATEMENT($6), SOME(getCOMMENT($2)))); } 
 
 /* Switch statement */
  
switch_command: SWITCH stash_comment expression opt_sep case_list END
			   { $$ = COMMAND(AbsynMat.SWITCH_COMMAND (getEXPRESSION($3), getSEPARATOR($4), getSWTCASES($5), SOME(getCOMMENT($2)))); }
			   
case_list 	: /* empty */ { $$ = SWTCASES(({}, NONE())); } 
			| default_case { $$ = SWTCASES(({}, SOME(getSWITCH($1)))); }
			| case_list1 { $$ = SWTCASES((getLSWITCH($1), NONE())); }   
			| case_list1 default_case { $$ = SWTCASES((getLSWITCH($1), SOME(getSWITCH($2)))); }
 
case_list1	: switch_case { $$ = LSWITCH(getSWITCH($1)::{}); }
			| switch_case case_list1 { $$ = LSWITCH(getSWITCH($1)::getLSWITCH($2)); }

switch_case	: CASE stash_comment opt_sep expression opt_sep opt_list
			{ $$ = SWITCH(AbsynMat.SWITCH_CASE (getSEPARATOR($3),getEXPRESSION($4), getSEPARATOR($5), getLSTATEMENT($6), SOME(getCOMMENT($2)))); }

default_case: OTHERWISE stash_comment opt_sep opt_list 
			{ $$ = SWITCH(AbsynMat.DEFAULT_CASE(getSEPARATOR($3), getLSTATEMENT($4), SOME(getCOMMENT($2)))); }
 
 /* Looping */
 
loop_command: WHILE stash_comment expression opt_sep opt_list END
		    { $$ = COMMAND(AbsynMat.WHILE_COMMAND (getEXPRESSION($3), SOME(getSEPARATOR($4)), getLSTATEMENT($5), SOME(getCOMMENT($2))));   }
			| FOR stash_comment assign_lhs EQ expression opt_sep opt_list END
			{ $$ = COMMAND(AbsynMat.FOR_COMMAND (getLARGUMENT($3), getEXPRESSION($5), SOME(getSEPARATOR($6)), getLSTATEMENT($7), SOME(getCOMMENT($2)))); }
			| FOR stash_comment	LPAR assign_lhs EQ	expression	RPAR opt_sep opt_list END
			{ $$ = COMMAND(AbsynMat.FOR_COMMAND (getLARGUMENT($4), getEXPRESSION($6), SOME(getSEPARATOR($8)), getLSTATEMENT($9), SOME(getCOMMENT($2)))); }
 
 /* Jumping */
  
jump_command: BREAK { $$ = COMMAND(AbsynMat.BREAK_COMMAND ()); }
			| CONTINUE { $$ = COMMAND(AbsynMat.CONTINUE_COMMAND ()); }
			| RETURN { $$ = COMMAND(AbsynMat.RETURN_COMMAND ()); }

 /* Commands, declarations, and function definitions */
 
 
command		: declaration { $$ = COMMAND(getCOMMAND($1)); } // $$[Decl_Command] = $1[Decl_Command];
			| select_command  { $$ = COMMAND(getCOMMAND($1)); }
            | loop_command { $$ = COMMAND(getCOMMAND($1)); }
			| jump_command { $$ = COMMAND(getCOMMAND($1)); }
 			| except_command { $$ = $1; }
 			| classdef { $$ = $1; }
 			  			
  
 /* Declaration statemnts */
 
//parsing_decl_list : /* empty */ { $$[Decl_Elts] = {}; }  //??
 
// declaration	: GLOBAL parsing_decl_list decl1 { $$[Command] = AbsynMat.MAKE_DECL_COMMAND($3[Decl_Elts]); } // $$[Decl_Command] = AbsynMat.MAKE_DECL_COMMAND($3[Decl_Elts]);
declaration	: GLOBAL decl1 { $$ = COMMAND(AbsynMat.MAKE_DECL_COMMAND(getLDECL($2))); }

decl1		: decl2 { $$ = LDECL(getDECL($1)::{}); }
			| decl2 decl1 { $$ = LDECL(getDECL($1)::getLDECL($2)); }
 
decl_param_init : /* empty */ { $$ = LDECL({}); }

decl2		: identifier { $$ = DECL(AbsynMat.DECL(getString($1),NONE())); }
		//	| identifier EQ decl_param_init expression { $$ = DECL(AbsynMat.DECL(getIDENT($1),SOME(getEXPRESSION($4)))); }
			| identifier EQ expression { $$ = DECL(AbsynMat.DECL(getString($1),SOME(getEXPRESSION($3)))); }
			| magic_tilde { $$ = DECL(AbsynMat.DECL(getIDENT($1),NONE())); }
  
 /* Exceptions */
  
except_command  : TRY stash_comment opt_sep opt_list CATCH stash_comment opt_sep opt_list END
                     { $$ = COMMAND(AbsynMat.TRY_CATCH_COMMAND(getSEPARATOR($3),getLSTATEMENT($4),getLSTATEMENT($8),getLCOMMENT($2),getLCOMMENT($6))); }
                | TRY stash_comment opt_sep opt_list END
                     { $$ = COMMAND(AbsynMat.TRY_CATCH_COMMAND(getSEPARATOR($3),getLSTATEMENT($4),{},getLCOMMENT($2),{})); } 
 
 /* Some `subroutines' for function definitions */
 
 /* push_fcn_symtab : */ /* empty */
 /* { printf("\n push_fcn_symtab : empty"); } */
 
 
 /* List of function parameters */
 
//param_list_beg: LPAR { $$ = $1; }

//param_list_end: RPAR { $$ = $1; }

//param_list	: param_list_beg param_list1 param_list_end { $$[Parameters] = $2[Parameters]; }
//			| param_list_beg error { $$ = $1; }

param_list	: LPAR param_list1 RPAR { $$ = LPARAMETER(getPARAMETER($2)::{}); }

param_list1	: /* empty */ { $$ = LPARAMETER({}); }
			| param_list2 { $$ = PARAMETER(AbsynMat.PARM(getLDECL($1))); }

param_list2	: decl3 { $$ = LDECL(getDECL($1)::{}); }
			| decl3 COMMA param_list2 { $$ = LDECL(getDECL($1)::getLDECL($3)); }

 /* List of function return value names */
 
return_list	: LBRACK RBRACK { $$ = LDECL({}); }
			| return_list1 { $$ = LDECL(getLDECL($1)); }
			| LBRACK return_list1 RBRACK { $$ = LDECL(getLDECL($2)); }
 
return_list1: decl3 { $$ = LDECL(getDECL($1)::{}); }
			| decl3 COMMA return_list1 { $$ = LDECL(getDECL($1)::getLDECL($3)); }
 
 decl3		: identifier { $$ = DECL(AbsynMat.DECL(getString($1),NONE())); }
 
 /* Function file */
  
function_file: FUNCTION function_list opt_sep opt_list  
{ $$ = START(AbsynMat.START(getUFUNCTION($2), getSEPARATOR($3), getLSTATEMENT($4))); } 

 /* Function definition */
 
//function_list: function { $$[User_Functions] = $1[User_Function]::{}; }
//            | function sep function_list { $$[User_Functions] = $1[User_Function]::$3[User_Functions]; }
   
function_list: function1 { $$ = UFUNCTION(AbsynMat.FINISH_FUNCTION ({},getUFUNCTION($1))); }
 			| return_list EQ function1 { $$ = UFUNCTION(AbsynMat.FINISH_FUNCTION (getLDECL($1),getUFUNCTION($3))); }
 			
fcn_name	: identifier { $$ = IDENT(getString($1)); }
            | GET DOT identifier { $$ = $3; }
            | SET DOT identifier { $$ = $3; }
            
//function1 	: fcn_name function2 { $$[User_Function] = AbsynMat.FROB_FUNCTION ($1[Ident], $2[User_Function]); }  //faced problem for fetching fname in translation phase
 
function1 	: fcn_name param_list opt_sep opt_list function_end 
			  { $$ = UFUNCTION(AbsynMat.START_FUNCTION (getIDENT($1),getLPARAMETER($2), SOME(getSEPARATOR($3)), getLSTATEMENT($4), getSTATEMENT($5))); }
			| fcn_name opt_sep opt_list function_end { $$ = UFUNCTION(AbsynMat.START_FUNCTION (getIDENT($1),{}, SOME(getSEPARATOR($2)), getLSTATEMENT($3), getSTATEMENT($4))); }

function_end: /* empty */ { $$ = STATEMENT(AbsynMat.WITHOUT_END()); }
			| END { $$ = STATEMENT(AbsynMat.MAKE_END ()); }
			| function_end END { $$ = STATEMENT(getSTATEMENT($1)); }
 
 /* Classdef */
   
  classdef_beg    : CLASSDEF stash_comment { $$ = $1; }
 
  classdef_end   : END { $$ = $1; } 
  
  classdef1       : classdef_beg opt_attr_list identifier opt_superclasses { $$ = $1; }
  
  classdef        : classdef1 '\n' class_body '\n' stash_comment classdef_end { $$ = $1; }
  
  opt_attr_list   : /* empty */  { $$ = LCLASS({}); }
                  | LPAR attr_list RPAR { $$ = $1; }
   
  attr_list       : attr { $$ = $1; }
                  | attr_list COMMA attr { $$ = $1; } 
  
  attr            : identifier { $$ = $1; }
                  | identifier EQ decl_param_init expression { $$ = $1; }
                  | EXPR_NOT identifier { $$ = $1; }

  opt_superclasses : /* empty */ { $$ = LCLASS({}); } 
                    | superclasses { $$ = $1; }
  
  superclasses    : EXPR_LT identifier DOT identifier { $$ = $1; }
                  | EXPR_LT identifier { $$ = $1; }
                  | superclasses EXPR_AND identifier DOT identifier { $$ = $1; }
                  | superclasses EXPR_AND identifier { $$ = $1; }
                    
  class_body      : properties_block { $$ = $1; }
                  | methods_block { $$ = $1; }
                  | events_block { $$ = $1; }
                  | class_body '\n' properties_block { $$ = $1; }
                  | class_body '\n' methods_block { $$ = $1; }
                  | class_body '\n' events_block { $$ = $1; }               
  
  properties_beg  : PROPERTIES stash_comment { $$ = $1; } 
  
  properties_block : properties_beg opt_attr_list '\n' properties_list '\n' END { $$ = $1; }
                    
  properties_list : class_property { $$ = $1; }
                  | properties_list '\n' class_property { $$ = $1; }              
  
  class_property  : identifier { $$ = $1; }
                  | identifier '=' decl_param_init expression ';' { $$ = $1; }
   
  methods_beg     : METHODS stash_comment { $$ = $1; }                  
  
  methods_block   : methods_beg opt_attr_list '\n' methods_list '\n' END { $$ = $1; }  
  
  methods_list    : function_file { $$ = $1; }
                  | methods_list '\n' function_file { $$ = $1; }
                    
  events_beg      : EVENTS stash_comment { $$ = $1; }
                    
  events_block    : events_beg opt_attr_list '\n' events_list '\n' END { $$ = $1; }                
  
  events_list     : class_event { $$ = $1; }
                  | events_list '\n' class_event { $$ = $1; }
                    
  class_event     : identifier { $$ = $1; }
  
/* Miscellaneous */
 
stash_comment: /* empty */ { $$ = COMMENT(AbsynMat.COMMENT(NONE())); }  
                   
sep			: COMMA { $$ = SEPARATOR(AbsynMat.COMMA()); } 
			| SEMI_COLON { $$ = SEPARATOR(AbsynMat.SEMI_COLON()); }
			| NEWLINES { $$ = SEPARATOR(AbsynMat.NEWLINES()); }
			| sep COMMA  { $$ = $1; }//$$[Separators] = $1[Separator]::$2[Separators]; 
			| sep SEMI_COLON { $$ = $1; }//$$[Separators] = $1[Separator]::$2[Separators]; 
			| sep NEWLINES { $$ = $1; }//$$[Separators] = $1[Separator]::$2[Separators]; 

opt_sep		: /* empty */ { $$ = SEPARATOR(AbsynMat.EMPTY()); }
			| sep { $$ = SEPARATOR(getSEPARATOR($1)); }
			//| function_file { $$[Separator] = AbsynMat.START_FUN($1[Start]); }

%%
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



  

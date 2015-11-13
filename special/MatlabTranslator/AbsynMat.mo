encapsulated package AbsynMat

public type Ident = String;

uniontype AstStart

record ASTSTART
  Start aststart;
end ASTSTART; 

end AstStart;


uniontype Start
  
  record START
    User_Function usr_fun;
    Separator sep;    
    list<Statement> stmt_lst;
  end START;
  
end Start;

uniontype User_Function 

// Begin defining a function.
  record START_FUNCTION 
    Ident fname;
    list<Parameter> prm; 
    Option<Separator> sep;             
    list<Statement> stmt_lst;       
    Statement stmt_2nd; 
  end START_FUNCTION;
    
// Do most of the work for defining a function.
/*  record FROB_FUNCTION 
    Function_Name fname;
    User_Function usr;
  end FROB_FUNCTION;
*/
// Finish defining a function.
  record FINISH_FUNCTION 
    list<Decl_Elt> ret;   
    User_Function usr;                
  end FINISH_FUNCTION;

end User_Function;

uniontype Argument
    
  record ARGUMENT
    Expression exp;
  end ARGUMENT;
  
  record VALIDATE_MATRIX_ROW
    Argument arg_lst; 
  end VALIDATE_MATRIX_ROW;
  
end Argument;           

uniontype Command
  
  record NO_OP_COMMAND 
    //string    
  end NO_OP_COMMAND;
  
  record TRY_CATCH_COMMAND 
    Separator sep;
    list<Statement> stmt_lst1;
    list<Statement> stmt_lst2;
    list<Mat_Comment> m_cmd_lst;
    list<Mat_Comment> m_cmd_lst2;
  end TRY_CATCH_COMMAND;
  
  record UNWIND_PROTECCOMMAND 
    list<Statement> stmt_lst1; 
    list<Statement> stmt_lst2;
    list<Mat_Comment> m_cmd_lst;
  end UNWIND_PROTECCOMMAND;
  
  record DECL_COMMAND
    Ident identifer;
    list<Decl_Elt> decl_elt;
  end DECL_COMMAND;
  
  record BREAK_COMMAND
  end BREAK_COMMAND;
  
  record CONTINUE_COMMAND 
  end CONTINUE_COMMAND; 
  
  record RETURN_COMMAND 
  end RETURN_COMMAND; 
  
  record SWITCH_COMMAND
    Expression exp; 
    Separator sep;
    tuple<list<Switch_Case>, Option<Switch_Case>> swcse_lst; 
    Option<Mat_Comment> m_cmd_lst;
  end SWITCH_COMMAND;       
  
  record WHILE_COMMAND
    Expression exp;
    Option<Separator> sep;
    list<Statement>  stmt_lst;
    Option<Mat_Comment> m_cmd_lst;
  end WHILE_COMMAND;
  
  record FOR_COMMAND 
    list<Argument> arg;
    Expression exp1;
    Option<Separator> sep;
    list<Statement> stmt_lst;
    Option<Mat_Comment> m_cmd_lst;
  end FOR_COMMAND;
  
  record IF_COMMAND
    Expression exp;
    Separator sep;
    list<Statement> stmts;
    list<Elseif> elifs;
    Option<Separator> sep2;
    list<Statement> stmts2;
    Option<Mat_Comment> cmts; 
    Option<Mat_Comment> cmts2;
  end IF_COMMAND;  

// Make a declaration command.
  record MAKE_DECL_COMMAND 
    list<Decl_Elt> decl_elts;
  end MAKE_DECL_COMMAND;
  
 
end Command;      

uniontype Elseif
  
  record ELSEIF_CLAUSE
    Separator sep;
    Expression exp;
    Separator sep2;
    list<Statement> stmt_lst;
    Option<Mat_Comment> m_cmd_lst;
  end ELSEIF_CLAUSE;

end Elseif; 

uniontype Class

  record CLASS
  end CLASS; 

end Class;     

uniontype Parameter 

  record PARM
  list<Decl_Elt> dec_elt; 
  end PARM;

end Parameter;

uniontype Decl_Elt 
  
  record DECL
    Ident identifier;
    Option<Expression> exp;
  end DECL;
  
end Decl_Elt;


uniontype Switch_Case 
  
  record SWITCH_CASE
    Separator sep;
    Expression exp;
    Separator sep2;
    list<Statement> stmt;
    Option<Mat_Comment> m_cmt;
  end SWITCH_CASE; 
  
  record DEFAULT_CASE
    Separator sep;
    list<Statement> stmt;
    Option<Mat_Comment> m_cmt;
  end DEFAULT_CASE;
end Switch_Case;

uniontype Statement 
  
  record STATEMENT
    Option<Command> cmd;
    Option<Expression> exp;
    Option<Start> usr_fun;
    Option<Mat_Comment> m_cmt;
  end STATEMENT; 

  record SET_STMT_PRINT_FLAG
    Statement stmt_apd; 
    Option<Separator> set_sep;
  end SET_STMT_PRINT_FLAG; 

  record STATEMENT_APPEND  
    Statement stmt_apd; 
    Separator sep;
   // list<Statement> stmt_lst;    
  end STATEMENT_APPEND;      

  record MAKE_END       
  end MAKE_END;
  
  record WITHOUT_END
  end WITHOUT_END;
  
end Statement;

uniontype Separator
  
  record COMMA    
  end COMMA;
  record SEMI_COLON
  end SEMI_COLON;
  record NEWLINES
  end NEWLINES;
  record EMPTY
  end EMPTY;
   
end Separator;

uniontype Expression
  
  record INT
  Integer int;
  end INT;
  
  record NUM
   Real number;
  end NUM;
  
  record INUM
    Real real;
  end INUM;
  
  record STR
    String str;
  end STR;
  
  record CONSTANT    
  end CONSTANT;
  
  record IDENTIFIER 
    Ident identifier;    
   // TypeCheck.ComType ty;
  end IDENTIFIER;
  
  record SIMPLE_ASSIGNMENT 
    Expression exp1;  
    Expression exp2;
    Operator a_op;            
  end SIMPLE_ASSIGNMENT; 
  
  record MULTI_ASSIGNMENT 
    list<Argument> arg_lst;  
    Expression exp; 
  end MULTI_ASSIGNMENT;
  
  record UNARY_EXPRESSION 
    Option<Expression> exp;
    Operator u_op;
  end UNARY_EXPRESSION;
  
  record BINARY_EXPRESSION 
    Expression exp1;
    Expression exp2; 
    Operator b_op;             
  end BINARY_EXPRESSION;
  
  record BOOLEAN_EXPRESSION 
    Expression exp1; 
    Expression exp2;
  end BOOLEAN_EXPRESSION;
  
  record PREFIX_EXPRESSION 
    Expression exp;
    Operator u_op;
  end PREFIX_EXPRESSION;  
  
  record POSTFIX_EXPRESSION 
    Expression exp; 
    Operator u_op;    
  end POSTFIX_EXPRESSION;
/*  
  record COMPOUND_BINARY_EXPRESSION 
    Expression exp1;
    Expression exp2; 
    Operator b_op; 
    Expression exp3; 
    Expression exp4;
    Com_Binary_Op c_b_op;   
  end COMPOUND_BINARY_EXPRESSION;
*/
/*  record COLON_EXPRESSION 
    Expression exp1;
    Expression exp2;
    Expression exp3;
  end COLON_EXPRESSION;
*/
  record FINISH_COLON_EXP
    list<Expression> exp;
    //Colon_Exp cln_exp;
  end FINISH_COLON_EXP;
    
  record FCN_HANDLE 
    Ident identifier;
  end FCN_HANDLE;
  
  record ANON_FCN_HANDLE 
    list<Parameter> par_lst2;
    Statement stmt_lst;
  end ANON_FCN_HANDLE;
  
  // Finish building a matrix list.
  record FINISH_MATRIX
   list<Matrix> arg_lst;   
  end FINISH_MATRIX;
  
  // Finish building a cell list.
	record FINISH_CELL
    list<Cell> cel;  
  end FINISH_CELL;

  // Build an assignment to a variable.
  record ASSIGN_OP 
    list<Argument> arg_lst;
    Operator op1;
    Expression exp;
  end ASSIGN_OP;

  record INDEX_EXPRESSION 
    Expression exp1; 
    list<Argument> arg_lst; 
  end INDEX_EXPRESSION; 
  
end Expression;                             

uniontype Colon_Exp

  record COLON_EXP
    Expression exp;
  end COLON_EXP;

end Colon_Exp;

uniontype Cell
  
  record CELL 
    list<Argument> arg_lst;
  end CELL;
  
end Cell;

uniontype Matrix
  
  record MATRIX 
    list<Argument> arg_lst;
  end MATRIX;
  
end Matrix;

uniontype Return
  
  record RET    
  end RET;
  
end Return;

uniontype Mat_Comment
  
  record COMMENT
    Option<String> comment;
  end COMMENT;
  
end Mat_Comment;

uniontype Operator
  
  record UPLUS // Unary Plus
  end UPLUS;
  record UMINUS // Unary Minus
  end UMINUS;
  record ADD   // PLUS
  end ADD;
  record SUB   // MINUS
  end SUB;
  record MUL   // MTIMES
  end MUL;
  record DIV   // MRDIVIDE
  end DIV;
  record POW   // MPOWER
  end POW;
  record LDIV  //MLDIVIDE
  end LDIV;
  record EXPR_LT     //LT
  end EXPR_LT;
  record EXPR_LE     //LE
  end EXPR_LE;     
  record EXPR_EQ     //EQ 
  end EXPR_EQ;
  record EXPR_GE     //GE
  end EXPR_GE;
  record EXPR_GT     //GT   
  end EXPR_GT;     
  record EXPR_NE     //NE  
  end EXPR_NE;     
  record EMUL //TIMES
  end  EMUL;    
  record EDIV //RDIVIDE
  end  EDIV;    
  record EPOW //POWER
  end  EPOW;    
  record ELEFTDIV //LDIVIDE 
  end ELEFTDIV;     
  record EXPR_AND  //AND
  end EXPR_AND;
  record EXPR_OR   //OR
  end EXPR_OR;
  record EXPR_AND_AND  //AND AND
  end EXPR_AND_AND; 
  record EXPR_OR_OR   //OR OR
  end EXPR_OR_OR;
  record EXPR_NOT //NOT
  end EXPR_NOT;            
  record OP_TRANSPOSE //TRANSPOSE
  end OP_TRANSPOSE; 
  record OP_HERMITIAN //CTRANSPOSE
  end OP_HERMITIAN;
  record EQ // =
  end EQ;
  
        
end Operator;
         
/*         
uniontype Compound_Binary_Op
  // ** compound operations **
  record OP_TRANS_MUL
  end OP_TRANS_MUL;
  record OP_MUL_TRANS 
  end OP_MUL_TRANS;
  record OP_HERM_MUL
  end OP_HERM_MUL;
  record OP_MUL_HERM
	end OP_MUL_HERM;
  record OP_TRANS_LDIV
  end OP_TRANS_LDIV;
  record OP_HERM_LDIV 
  end OP_HERM_LDIV;
  record OP_EL_NOAND
  end OP_EL_NOAND;
  record OP_EL_NOOR
  end OP_EL_NOOR;
  record OP_EL_AND_NOT
  end OP_EL_AND_NOT;
  record OP_EL_OR_NOT
  end OP_EL_OR_NOT;        
end Compound_Binary_Op;
*/

end AbsynMat;
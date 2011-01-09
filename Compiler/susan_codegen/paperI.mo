interface package paperI
  
package Example
	uniontype Statement  "Algorithmic stmts"
	  record ASSIGN  "An assignment stmt"
	    Exp lhs; Exp rhs;
	  end ASSIGN;
	
	  record WHILE  "A while statement"
	    Exp condition;
	    list<Statement> statements;
	  end WHILE;
	end Statement;
	
	uniontype Exp  "Expression nodes"
	  record ICONST  "Integer constant value"
	    Integer value;
	  end ICONST;
	
	  record VARIABLE "Variable reference"
	    String name;
	  end VARIABLE;
	
	  record BINARY  "Binary ops"
	    Exp lhs; 
	    Operator op;  
	    Exp rhs;
	  end BINARY;
	end Exp;
	
	uniontype Operator
	  record PLUS end PLUS;
	  record TIMES end TIMES;
	  record LESS end LESS;
	end Operator; 

end Example;

end paperI;
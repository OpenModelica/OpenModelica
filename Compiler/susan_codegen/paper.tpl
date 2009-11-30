spackage paper
  
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

statement(Statement) ::=
  case ASSIGN then <<
  <exp(lhs)> = <exp(rhs)>;
  >>	
  case WHILE  then <<
  while(<exp(condition)>) {
    <statements : statement() \n>
  }
  >>

exp(Exp) ::=
 case ICONST   then value
 case VARIABLE then name
 case BINARY   then
  '(<exp(lhs)> <oper(op)> <exp(rhs)>)'

oper(Operator) ::=
  case PLUS then "+"
  case TIMES then "*"
  case LESS then "<"

//********
opt(Option<Option<Integer>> ho) ::= ho

pok(list<String> names, Integer i0) ::= '<i0> <names : '<it> <i0>' ", ">'

pok2(list<String> names, String sep) ::= (names of "a" : i0 'o<sep>')	 

pok3(list<Exp> exps) ::= (exps of ICONST : value ", ")	 

pok4(String s) ::= it

pok5(String a, Integer it) ::= it //error ... displaced it

pok6(tuple<Integer,String> tup) ::= tup of (i,s) : i + s

pok7(list<tuple<String,Integer>> tuples) ::= (tuples of (s,i) : 'o<it of (s,_):s>')	 

pok8() ::= <<
   blabla<\n>hej you!<\n>
     juchi
>>
//********/

end paper;
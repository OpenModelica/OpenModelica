// (?<!(>|-|(list|Option|tuple)<\w{1,40}))>(?!>)
// (?<!(<|list|Option|tuple))<(?!<)
// (?s)(?<!template )(\w+)(.*?)(?:\n*template) -> \1\2\nend \1;
// (?<=template )(\w+)(?s:.*?)(?=\R*template)
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

template statement(Statement it) ::=
  match it
  case ASSIGN(__) then <<
  <%exp(lhs)%> = <%exp(rhs)%>;
  >>	
  case WHILE(__)  then <<
  while(<%exp(condition)%>) {
    <%statements |> it => statement(it) ;separator="\n"%>
  }
  >>
end statement;

template exp(Exp it) ::=
 match it
 case ICONST(__)   then value
 case VARIABLE(__) then name
 case BINARY(__)   then
  '(<%exp(lhs)%> <%oper(op)%> <%exp(rhs)%>)'
end exp;

template oper(Operator it) ::=
  match it
  case PLUS(__) then "+"
  case TIMES(__) then "*"
  case LESS(__) then "<"
end oper;

//********
template opt(Option<Option<Integer>> ho) ::= ho
end opt;

template pok(list<String> names, Integer i0) ::= '<%i0%> <%names |> it => '<%it%> <%i0%>' ;separator=", "%>'
end pok;

template pok2(list<String> names, String sep) ::= (names |> "a" => i0 ;separator='o<%sep%>')	 
end pok2;

template pok3(list<Exp> exps) ::= (exps |> ICONST(__) => value ;separator=", ")	 
end pok3;

template pok4(String s) ::= it
end pok4;

template pok5(String a, Integer /*it*/itt) ::= it //error ... displaced it
end pok5;

template pok6(tuple<Integer,String> tup) ::= tup |> (i,s) => i + s
end pok6;

template pok7(list<tuple<String,Integer>> tuples) ::= (tuples |> (s,i) => 'o<%it |> (s,_)=>s%>')	 
end pok7;

template pok8() ::= <<
   blabla<%\n%>hej you!<%\n%>
     juchi
>>
end pok8;

//********/

end paper;
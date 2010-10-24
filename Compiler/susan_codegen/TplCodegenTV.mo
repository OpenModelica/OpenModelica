interface package TplCodegenTV

package builtin
	function stringListStringChar
	  input String inString;
	  output list<String> outStringList;
	end stringListStringChar;
end builtin;

package Tpl
	uniontype StringToken
	  record ST_NEW_LINE "Always outputs the new-line char."  end ST_NEW_LINE;

	  record ST_STRING "A string without new-lines in it."
	    String value;
	  end ST_STRING;

	  record ST_LINE "A (non-empty) string with new-line at the end."
	    String line;
	  end ST_LINE;
  
	  record ST_STRING_LIST "Every string in the list can have a new-line at its end (but does not have to)."
	    list<String> strList;
	    Boolean lastHasNewLine "True when the last string in the list has new-line at the end."; 
	  end ST_STRING_LIST;
	end StringToken;
end Tpl;

package TplAbsyn	
	// **** shared types for the input and the output AST
	
	type Ident = String;
	type TypedIdents = list<tuple<Ident, TypeSignature>>;
	type StringToken = Tpl.StringToken;
	
	uniontype PathIdent
	  record IDENT
	    Ident ident;    
	  end IDENT;
	  
	  record PATH_IDENT
	    Ident ident;
	    PathIdent path;
	  end PATH_IDENT;
	end PathIdent;
	
	uniontype TypeSignature
	  record LIST_TYPE
	    TypeSignature ofType;
	  end LIST_TYPE;
	  
	  record ARRAY_TYPE  // one-dimensional arrays --> with only (safe) list behaviour
	    TypeSignature ofType;
	  end ARRAY_TYPE;
	  
	  record OPTION_TYPE
	    TypeSignature ofType;
	  end OPTION_TYPE;
	  
	  record TUPLE_TYPE
	    list<TypeSignature> ofTypes;
	  end TUPLE_TYPE;
	  
	  record NAMED_TYPE "key/path to a TypeInfo list from an AST definition"
	    PathIdent name;
	  end NAMED_TYPE;
	  
	  record STRING_TYPE  end STRING_TYPE;
	  record TEXT_TYPE    end TEXT_TYPE;
	  record STRING_TOKEN_TYPE "Used only for internal string constants." end STRING_TOKEN_TYPE;
  
	  record INTEGER_TYPE end INTEGER_TYPE;
	  record REAL_TYPE    end REAL_TYPE;
	  record BOOLEAN_TYPE end BOOLEAN_TYPE;
	
	  record UNRESOLVED_TYPE "Errorneous resolving type. Only used during elaboration phase."
	    String reason; 
	  end UNRESOLVED_TYPE;
	end TypeSignature;
		   

	uniontype MatchingExp
	  record BIND_AS_MATCH
	    Ident bindIdent;
	    MatchingExp matchingExp;
	  end BIND_AS_MATCH;
	  
	  record BIND_MATCH 
	    Ident bindIdent;
	  end BIND_MATCH;
	  
	  record RECORD_MATCH
	    PathIdent tagName;
	    list<tuple<Ident, MatchingExp>> fieldMatchings;
	  end RECORD_MATCH;
	  
	  record SOME_MATCH
	    MatchingExp value;
	  end SOME_MATCH;
	  
	  record NONE_MATCH end NONE_MATCH;
	  
	  record TUPLE_MATCH
	    list<MatchingExp> tupleArgs;
	  end TUPLE_MATCH;
	
	  record LIST_MATCH //non-empty list
	    list<MatchingExp> listElts; 
	  end LIST_MATCH;
	  
	  record LIST_CONS_MATCH
	    MatchingExp head;
	    MatchingExp rest;
	  end LIST_CONS_MATCH;
	  
	  record STRING_MATCH
	    String value;
	  end STRING_MATCH;

	  record LITERAL_MATCH
	    String value;
	    TypeSignature litType; // only INTEGER_TYPE, REAL_TYPE or BOOLEAN_TYPE 
	  end LITERAL_MATCH;
	
	  record REST_MATCH end REST_MATCH;
	end MatchingExp;
	
	
	// **** the (core) output AST
	
	uniontype MMPackage
	  record MM_PACKAGE
	    PathIdent name;
	    list<MMDeclaration> mmDeclarations;      
	  end MM_PACKAGE;
	end MMPackage;
	
	type MMMatchCase = tuple<list<MatchingExp>, TypedIdents, list<MMExp>>;
	  
	uniontype MMDeclaration
	  record MM_IMPORT
	    Boolean isPublic;
	    PathIdent packageName;
	  end MM_IMPORT;
	  
	  record MM_STR_TOKEN_DECL
	    Boolean isPublic;
	    Ident name;
	    StringToken value;
	  end MM_STR_TOKEN_DECL;
	  
	  record MM_LITERAL_DECL
	    Boolean isPublic;
	    Ident name;
	    String value;
	    TypeSignature litType;
	  end MM_LITERAL_DECL;
  
	  
	  record MM_FUN
	    Boolean isPublic;
	    Ident name;
	    TypedIdents inArgs; //inTxt inclusive
	    TypedIdents outArgs; // outTxt + extra Texts
	    TypedIdents locals;
	    list<MMExp> statements;    
	  end MM_FUN;      
	end MMDeclaration;
	
	uniontype MMExp
	  record MM_ASSIGN
	    list<Ident> lhsArgs;
	    MMExp rhs;
	  end MM_ASSIGN;
	  
	  record MM_FN_CALL
	    PathIdent fnName;
	    list<MMExp> args;
	  end MM_FN_CALL;
	  
	  record MM_IDENT
	    PathIdent ident;
	  end MM_IDENT;
	  
	  record MM_STR_TOKEN "constructor of type StringToken"
	    StringToken value;
	  end MM_STR_TOKEN;
	  
	  record MM_STRING "to pass a string constant as parameter of type String" 
	    String value;
	  end MM_STRING;
	  
	  record MM_LITERAL "to pass a literal constant as parameter of type Integer, Real or Boolean" 
	    String value;    
	  end MM_LITERAL;
	  
	  record MM_MATCH
	    list<MMMatchCase> matchCases;
	  end MM_MATCH;
	end MMExp;
	
	// **** types for dumping purposes ... i.e. Susan input AST
	
	function canBeEscapedUnquoted
	  input list<String> inStringList;
	  output Boolean outCanBeUnquoted;
	end canBeEscapedUnquoted;
	
	function canBeOnOneLine
	  input list<String> inStringList;
	  output Boolean outCanBeOnOneLine;
	end canBeOnOneLine;
	
	uniontype Expression
	  record TEMPLATE
	    list<Expression> items;
	    String lquote; // just preserved for effective quoted dump
	    String rquote;
	  end TEMPLATE;
	  
	  record STR_TOKEN
	    StringToken value; //only one of ST_STRING, ST_NEW_LINE or ST_STRING_LIST
	  end STR_TOKEN;
	  
	  record LITERAL
	    String value;
	    TypeSignature litType; // only INTEGER_TYPE, REAL_TYPE or BOOLEAN_TYPE 
	  end LITERAL;
	  
	  record SOFT_NEW_LINE end SOFT_NEW_LINE; //appears only in a TEMPLATE
	    
	  record BOUND_VALUE
	    PathIdent boundPath;
	  end BOUND_VALUE;
	
	  record FUN_CALL
	    PathIdent name;
	    list<Expression> args;
	  end FUN_CALL;
	  
	  record CONDITION
	    Boolean isNot "Is not or inequal";
	    Expression lhsExp;
	    Option<MatchingExp> rhsValue;
	    Expression trueBranch;
	    Option<Expression> elseBranch;
	  end CONDITION;
	
	  record MATCH
	    Expression matchExp;
	    list<tuple<MatchingExp,Expression>> cases;
	  end MATCH;
	  
	  record MAP
	    //list<tuple<Expression, MatchingExp>> bindings; // default/empty MatchingExp is "it"
	    //only 1 argument allowed in the first impl
	    Expression argExp;
	    MatchingExp ofBinding; // default/empty MatchingExp is "it"
	    Expression mapExp;
	  end MAP;
	
	  record MAP_ARG_LIST
	    list<Expression> parts; // a part is a scalar or a list
	  end MAP_ARG_LIST;
	  
	  record STREAM_CREATE
	    Ident name;
	    Expression exp;
	  end STREAM_CREATE;
	
	  record STREAM_ADD
	    Ident name;
	    Expression exp;
	  end STREAM_ADD;
	  
	  record ESCAPED
	    Expression exp;
	    //Option<Expression> separator;
	    list<EscOption> options;
	  end ESCAPED;
	  
	  record INDENTATION "Indented block."
	    Integer width;
	    list<Expression> items;
	  end INDENTATION;
	end Expression;

	uniontype TypeInfo
	  record TI_UNION_TYPE
	    list<tuple<Ident, TypedIdents>> recTags;
	  end TI_UNION_TYPE;
	  
	  record TI_RECORD_TYPE
	    TypedIdents fields;
	  end TI_RECORD_TYPE;
	  
	  record TI_ALIAS_TYPE
	    TypeSignature aliasType;
	  end TI_ALIAS_TYPE;
	  
	  record TI_FUN_TYPE "Imported AST/builtin functions."
	    TypedIdents inArgs;
	    TypedIdents outArgs;
	    //Ident callName; ... can be made as direct/wrapper calls
	  end TI_FUN_TYPE;
	  
	  record TI_CONST_TYPE "Imported AST constants."
	    TypeSignature constType;
	  end TI_CONST_TYPE;  
	end TypeInfo;
	
	uniontype ASTDef
	  record AST_DEF
	    PathIdent importPackage;
	    Boolean isDefault;
	    list<tuple<Ident, TypeInfo>> types;
	  end AST_DEF;
	end ASTDef;    
	
	uniontype TemplPackage
	  record TEMPL_PACKAGE
	    PathIdent name;
	    //list<PathIdent> extendsList;
	    list<ASTDef> astDefs;
	    list<tuple<Ident,TemplateDef>> templateDefs;     
	  end TEMPL_PACKAGE;
	end TemplPackage;
	
	uniontype TemplateDef
	  record STR_TOKEN_DEF
	    StringToken value; //only one of ST_STRING, ST_NEW_LINE or  ST_STRING_LIST
	  end STR_TOKEN_DEF;
	  
	  record LITERAL_DEF
	    String value;
	    TypeSignature litType; // only INTEGER_TYPE, REAL_TYPE or BOOLEAN_TYPE 
	  end LITERAL_DEF;
	  
	  record TEMPLATE_DEF
	    TypedIdents args;
	    String lesc; // just preserved for original-like quoted dump
	    String resc;
	    Expression exp;
	  end TEMPLATE_DEF;
	end TemplateDef;
	
end TplAbsyn;

end TplCodegenTV;
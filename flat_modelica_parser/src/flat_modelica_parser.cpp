/* $ANTLR 2.7.1: "flat_modelica_parser.g" -> "flat_modelica_parser.cpp"$ */
#include "flat_modelica_parser.hpp"
#include "antlr/NoViableAltException.hpp"
#include "antlr/SemanticException.hpp"
#line 1 "flat_modelica_parser.g"

#line 8 "flat_modelica_parser.cpp"
flat_modelica_parser::flat_modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenBuffer& tokenBuf, int k)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(tokenBuf,k)
{
	setTokenNames(_tokenNames);
}

flat_modelica_parser::flat_modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenBuffer& tokenBuf)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(tokenBuf,2)
{
	setTokenNames(_tokenNames);
}

flat_modelica_parser::flat_modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenStream& lexer, int k)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(lexer,k)
{
	setTokenNames(_tokenNames);
}

flat_modelica_parser::flat_modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenStream& lexer)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(lexer,2)
{
	setTokenNames(_tokenNames);
}

flat_modelica_parser::flat_modelica_parser(const ANTLR_USE_NAMESPACE(antlr)ParserSharedInputState& state)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(state,2)
{
	setTokenNames(_tokenNames);
}

void flat_modelica_parser::stored_definition() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST stored_definition_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefToken  f = ANTLR_USE_NAMESPACE(antlr)nullToken;
	ANTLR_USE_NAMESPACE(antlr)RefAST f_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case WITHIN:
	{
		within_clause();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp1_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp1_AST = astFactory.create(LT(1));
		match(SEMICOLON);
		break;
	}
	case ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE:
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case ENCAPSULATED:
	case FINAL:
	case FUNCTION:
	case MODEL:
	case PACKAGE:
	case PARTIAL:
	case RECORD:
	case TYPE:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	{
	for (;;) {
		if ((_tokenSet_0.member(LA(1)))) {
			{
			switch ( LA(1)) {
			case FINAL:
			{
				f = LT(1);
				if (inputState->guessing==0) {
					f_AST = astFactory.create(f);
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
				}
				match(FINAL);
				break;
			}
			case BLOCK:
			case CLASS:
			case CONNECTOR:
			case ENCAPSULATED:
			case FUNCTION:
			case MODEL:
			case PACKAGE:
			case PARTIAL:
			case RECORD:
			case TYPE:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}
			}
			}
			class_definition();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp2_AST = astFactory.create(LT(1));
			match(SEMICOLON);
		}
		else {
			goto _loop5;
		}
		
	}
	_loop5:;
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp3_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp3_AST = astFactory.create(LT(1));
	match(ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE);
	if ( inputState->guessing==0 ) {
		stored_definition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 64 "flat_modelica_parser.g"
		
						stored_definition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(STORED_DEFINITION,"STORED_DEFINITION"))->add(stored_definition_AST)));
					
#line 138 "flat_modelica_parser.cpp"
		currentAST.root = stored_definition_AST;
		if ( stored_definition_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			stored_definition_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = stored_definition_AST->getFirstChild();
		else
			currentAST.child = stored_definition_AST;
		currentAST.advanceChildToEnd();
	}
	stored_definition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = stored_definition_AST;
}

void flat_modelica_parser::within_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST within_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp4_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp4_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp4_AST));
	}
	match(WITHIN);
	{
	switch ( LA(1)) {
	case IDENT:
	{
		name_path();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case SEMICOLON:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	within_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = within_clause_AST;
}

void flat_modelica_parser::class_definition() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_definition_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case ENCAPSULATED:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp5_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp5_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp5_AST));
		}
		match(ENCAPSULATED);
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case FUNCTION:
	case MODEL:
	case PACKAGE:
	case PARTIAL:
	case RECORD:
	case TYPE:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	{
	switch ( LA(1)) {
	case PARTIAL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp6_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp6_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp6_AST));
		}
		match(PARTIAL);
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case FUNCTION:
	case MODEL:
	case PACKAGE:
	case RECORD:
	case TYPE:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	class_type();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp7_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp7_AST = astFactory.create(LT(1));
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp7_AST));
	}
	match(IDENT);
	class_specifier();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		class_definition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 84 "flat_modelica_parser.g"
		
					class_definition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(CLASS_DEFINITION,"CLASS_DEFINITION"))->add(class_definition_AST))); 
				
#line 270 "flat_modelica_parser.cpp"
		currentAST.root = class_definition_AST;
		if ( class_definition_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			class_definition_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = class_definition_AST->getFirstChild();
		else
			currentAST.child = class_definition_AST;
		currentAST.advanceChildToEnd();
	}
	class_definition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = class_definition_AST;
}

void flat_modelica_parser::name_path() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST name_path_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (((LA(1)==IDENT) && (_tokenSet_1.member(LA(2))))&&( LA(2)!=DOT )) {
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp8_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp8_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp8_AST));
		}
		match(IDENT);
		name_path_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else if ((LA(1)==IDENT) && (LA(2)==DOT)) {
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp9_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp9_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp9_AST));
		}
		match(IDENT);
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp10_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp10_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp10_AST));
		}
		match(DOT);
		name_path();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		name_path_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = name_path_AST;
}

void flat_modelica_parser::class_type() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_type_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case CLASS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp11_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp11_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp11_AST));
		}
		match(CLASS);
		break;
	}
	case MODEL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp12_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp12_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp12_AST));
		}
		match(MODEL);
		break;
	}
	case RECORD:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp13_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp13_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp13_AST));
		}
		match(RECORD);
		break;
	}
	case BLOCK:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp14_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp14_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp14_AST));
		}
		match(BLOCK);
		break;
	}
	case CONNECTOR:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp15_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp15_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp15_AST));
		}
		match(CONNECTOR);
		break;
	}
	case TYPE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp16_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp16_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp16_AST));
		}
		match(TYPE);
		break;
	}
	case PACKAGE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp17_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp17_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp17_AST));
		}
		match(PACKAGE);
		break;
	}
	case FUNCTION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp18_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp18_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp18_AST));
		}
		match(FUNCTION);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	class_type_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = class_type_AST;
}

void flat_modelica_parser::class_specifier() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_specifier_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if ((_tokenSet_2.member(LA(1)))) {
		string_comment();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		composition();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp19_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp19_AST = astFactory.create(LT(1));
		match(END);
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp20_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp20_AST = astFactory.create(LT(1));
		match(IDENT);
	}
	else if ((LA(1)==EQUALS) && (_tokenSet_3.member(LA(2)))) {
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp21_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp21_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp21_AST));
		}
		match(EQUALS);
		base_prefix();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		name_path();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		switch ( LA(1)) {
		case LBRACK:
		{
			array_subscripts();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case ANNOTATION:
		case EXTENDS:
		case LPAR:
		case RPAR:
		case COMMA:
		case SEMICOLON:
		case STRING:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		{
		switch ( LA(1)) {
		case LPAR:
		{
			class_modification();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case ANNOTATION:
		case EXTENDS:
		case RPAR:
		case COMMA:
		case SEMICOLON:
		case STRING:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		comment();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1)==EQUALS) && (LA(2)==ENUMERATION)) {
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp22_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp22_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp22_AST));
		}
		match(EQUALS);
		enumeration();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	class_specifier_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = class_specifier_AST;
}

void flat_modelica_parser::string_comment() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST string_comment_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case STRING:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp23_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp23_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp23_AST));
		}
		match(STRING);
		{
		for (;;) {
			if ((LA(1)==PLUS)) {
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp24_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				if (inputState->guessing==0) {
					tmp24_AST = astFactory.create(LT(1));
					astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp24_AST));
				}
				match(PLUS);
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp25_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				if (inputState->guessing==0) {
					tmp25_AST = astFactory.create(LT(1));
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp25_AST));
				}
				match(STRING);
			}
			else {
				goto _loop226;
			}
			
		}
		_loop226:;
		}
		break;
	}
	case ALGORITHM:
	case ANNOTATION:
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case CONSTANT:
	case DISCRETE:
	case END:
	case EQUATION:
	case ENCAPSULATED:
	case EXTENDS:
	case EXTERNAL:
	case FINAL:
	case FLOW:
	case FUNCTION:
	case IMPORT:
	case INITIAL:
	case INNER:
	case INPUT:
	case MODEL:
	case OUTER:
	case OUTPUT:
	case PACKAGE:
	case PARAMETER:
	case PARTIAL:
	case PROTECTED:
	case PUBLIC:
	case RECORD:
	case REPLACEABLE:
	case TYPE:
	case RPAR:
	case COMMA:
	case SEMICOLON:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	if ( inputState->guessing==0 ) {
		string_comment_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 729 "flat_modelica_parser.g"
		
		if (string_comment_AST)
		{
		string_comment_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(STRING_COMMENT,"STRING_COMMENT"))->add(string_comment_AST)));
		}
				
#line 626 "flat_modelica_parser.cpp"
		currentAST.root = string_comment_AST;
		if ( string_comment_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			string_comment_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = string_comment_AST->getFirstChild();
		else
			currentAST.child = string_comment_AST;
		currentAST.advanceChildToEnd();
	}
	string_comment_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = string_comment_AST;
}

void flat_modelica_parser::composition() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST composition_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	element_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		switch ( LA(1)) {
		case PUBLIC:
		{
			public_element_list();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case PROTECTED:
		{
			protected_element_list();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case EQUATION:
		{
			equation_clause();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case ALGORITHM:
		{
			algorithm_clause();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		default:
			if ((LA(1)==INITIAL) && (LA(2)==EQUATION)) {
				initial_equation_clause();
				if (inputState->guessing==0) {
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
			else if ((LA(1)==INITIAL) && (LA(2)==ALGORITHM)) {
				initial_algorithm_clause();
				if (inputState->guessing==0) {
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
		else {
			goto _loop25;
		}
		}
	}
	_loop25:;
	}
	{
	switch ( LA(1)) {
	case EXTERNAL:
	{
		external_clause();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case END:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	composition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = composition_AST;
}

void flat_modelica_parser::base_prefix() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST base_prefix_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	type_prefix();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	base_prefix_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = base_prefix_AST;
}

void flat_modelica_parser::array_subscripts() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST array_subscripts_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp26_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp26_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp26_AST));
	}
	match(LBRACK);
	subscript();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==COMMA)) {
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp27_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp27_AST = astFactory.create(LT(1));
			match(COMMA);
			subscript();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop216;
		}
		
	}
	_loop216:;
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp28_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp28_AST = astFactory.create(LT(1));
	match(RBRACK);
	array_subscripts_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = array_subscripts_AST;
}

void flat_modelica_parser::class_modification() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_modification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp29_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp29_AST = astFactory.create(LT(1));
	match(LPAR);
	{
	switch ( LA(1)) {
	case EACH:
	case FINAL:
	case REDECLARE:
	case IDENT:
	{
		argument_list();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case RPAR:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp30_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp30_AST = astFactory.create(LT(1));
	match(RPAR);
	if ( inputState->guessing==0 ) {
		class_modification_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 283 "flat_modelica_parser.g"
		
					class_modification_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(CLASS_MODIFICATION,"CLASS_MODIFICATION"))->add(class_modification_AST)));
				
#line 820 "flat_modelica_parser.cpp"
		currentAST.root = class_modification_AST;
		if ( class_modification_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			class_modification_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = class_modification_AST->getFirstChild();
		else
			currentAST.child = class_modification_AST;
		currentAST.advanceChildToEnd();
	}
	class_modification_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = class_modification_AST;
}

void flat_modelica_parser::comment() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST comment_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	string_comment();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	switch ( LA(1)) {
	case ANNOTATION:
	{
		annotation();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case EXTENDS:
	case RPAR:
	case COMMA:
	case SEMICOLON:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	}
	if ( inputState->guessing==0 ) {
		comment_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 722 "flat_modelica_parser.g"
		
					comment_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(COMMENT,"COMMENT"))->add(comment_AST)));
				
#line 873 "flat_modelica_parser.cpp"
		currentAST.root = comment_AST;
		if ( comment_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			comment_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = comment_AST->getFirstChild();
		else
			currentAST.child = comment_AST;
		currentAST.advanceChildToEnd();
	}
	comment_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = comment_AST;
}

void flat_modelica_parser::enumeration() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST enumeration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp31_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp31_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp31_AST));
	}
	match(ENUMERATION);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp32_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp32_AST = astFactory.create(LT(1));
	match(LPAR);
	enum_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp33_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp33_AST = astFactory.create(LT(1));
	match(RPAR);
	comment();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	enumeration_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = enumeration_AST;
}

void flat_modelica_parser::type_prefix() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST type_prefix_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case FLOW:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp34_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp34_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp34_AST));
		}
		match(FLOW);
		break;
	}
	case CONSTANT:
	case DISCRETE:
	case INPUT:
	case OUTPUT:
	case PARAMETER:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	{
	switch ( LA(1)) {
	case DISCRETE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp35_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp35_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp35_AST));
		}
		match(DISCRETE);
		break;
	}
	case PARAMETER:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp36_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp36_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp36_AST));
		}
		match(PARAMETER);
		break;
	}
	case CONSTANT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp37_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp37_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp37_AST));
		}
		match(CONSTANT);
		break;
	}
	case INPUT:
	case OUTPUT:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	{
	switch ( LA(1)) {
	case INPUT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp38_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp38_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp38_AST));
		}
		match(INPUT);
		break;
	}
	case OUTPUT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp39_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp39_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp39_AST));
		}
		match(OUTPUT);
		break;
	}
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	type_prefix_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = type_prefix_AST;
}

void flat_modelica_parser::enum_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST enum_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	enumeration_literal();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==COMMA)) {
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp40_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp40_AST = astFactory.create(LT(1));
			match(COMMA);
			enumeration_literal();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop21;
		}
		
	}
	_loop21:;
	}
	enum_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = enum_list_AST;
}

void flat_modelica_parser::enumeration_literal() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST enumeration_literal_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp41_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp41_AST = astFactory.create(LT(1));
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp41_AST));
	}
	match(IDENT);
	comment();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		enumeration_literal_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 115 "flat_modelica_parser.g"
		
					enumeration_literal_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(ENUMERATION_LITERAL,"ENUMERATION_LITERAL"))->add(enumeration_literal_AST)));
				
#line 1079 "flat_modelica_parser.cpp"
		currentAST.root = enumeration_literal_AST;
		if ( enumeration_literal_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			enumeration_literal_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = enumeration_literal_AST->getFirstChild();
		else
			currentAST.child = enumeration_literal_AST;
		currentAST.advanceChildToEnd();
	}
	enumeration_literal_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = enumeration_literal_AST;
}

void flat_modelica_parser::element_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	for (;;) {
		if ((_tokenSet_4.member(LA(1)))) {
			{
			switch ( LA(1)) {
			case BLOCK:
			case CLASS:
			case CONNECTOR:
			case CONSTANT:
			case DISCRETE:
			case ENCAPSULATED:
			case EXTENDS:
			case FINAL:
			case FLOW:
			case FUNCTION:
			case IMPORT:
			case INNER:
			case INPUT:
			case MODEL:
			case OUTER:
			case OUTPUT:
			case PACKAGE:
			case PARAMETER:
			case PARTIAL:
			case RECORD:
			case REPLACEABLE:
			case TYPE:
			case IDENT:
			{
				element();
				if (inputState->guessing==0) {
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				break;
			}
			case ANNOTATION:
			{
				annotation();
				if (inputState->guessing==0) {
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}
			}
			}
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp42_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp42_AST = astFactory.create(LT(1));
			match(SEMICOLON);
		}
		else {
			goto _loop41;
		}
		
	}
	_loop41:;
	}
	element_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = element_list_AST;
}

void flat_modelica_parser::public_element_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST public_element_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp43_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp43_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp43_AST));
	}
	match(PUBLIC);
	element_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	public_element_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = public_element_list_AST;
}

void flat_modelica_parser::protected_element_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST protected_element_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp44_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp44_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp44_AST));
	}
	match(PROTECTED);
	element_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	protected_element_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = protected_element_list_AST;
}

void flat_modelica_parser::initial_equation_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST initial_equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ec_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (!( LA(2)==EQUATION))
		throw ANTLR_USE_NAMESPACE(antlr)SemanticException(" LA(2)==EQUATION");
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp45_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp45_AST = astFactory.create(LT(1));
	match(INITIAL);
	equation_clause();
	if (inputState->guessing==0) {
		ec_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		initial_equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 333 "flat_modelica_parser.g"
		
		initial_equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(INITIAL_EQUATION,"INTIAL_EQUATION"))->add(ec_AST)));
		
#line 1221 "flat_modelica_parser.cpp"
		currentAST.root = initial_equation_clause_AST;
		if ( initial_equation_clause_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			initial_equation_clause_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = initial_equation_clause_AST->getFirstChild();
		else
			currentAST.child = initial_equation_clause_AST;
		currentAST.advanceChildToEnd();
	}
	initial_equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = initial_equation_clause_AST;
}

void flat_modelica_parser::initial_algorithm_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST initial_algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (!( LA(2)==ALGORITHM))
		throw ANTLR_USE_NAMESPACE(antlr)SemanticException(" LA(2)==ALGORITHM");
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp46_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp46_AST = astFactory.create(LT(1));
	match(INITIAL);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp47_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp47_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp47_AST));
	}
	match(ALGORITHM);
	{
	for (;;) {
		switch ( LA(1)) {
		case FOR:
		case IF:
		case WHEN:
		case WHILE:
		case LPAR:
		case IDENT:
		{
			algorithm();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp48_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp48_AST = astFactory.create(LT(1));
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp49_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp49_AST = astFactory.create(LT(1));
			match(SEMICOLON);
			break;
		}
		default:
		{
			goto _loop100;
		}
		}
	}
	_loop100:;
	}
	if ( inputState->guessing==0 ) {
		initial_algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 362 "flat_modelica_parser.g"
		
			            initial_algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(INITIAL_ALGORITHM,"INTIAL_ALGORITHM"))->add(initial_algorithm_clause_AST)));
				
#line 1294 "flat_modelica_parser.cpp"
		currentAST.root = initial_algorithm_clause_AST;
		if ( initial_algorithm_clause_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			initial_algorithm_clause_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = initial_algorithm_clause_AST->getFirstChild();
		else
			currentAST.child = initial_algorithm_clause_AST;
		currentAST.advanceChildToEnd();
	}
	initial_algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = initial_algorithm_clause_AST;
}

void flat_modelica_parser::equation_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp50_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp50_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp50_AST));
	}
	match(EQUATION);
	equation_annotation_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = equation_clause_AST;
}

void flat_modelica_parser::algorithm_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp51_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp51_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp51_AST));
	}
	match(ALGORITHM);
	{
	for (;;) {
		switch ( LA(1)) {
		case FOR:
		case IF:
		case WHEN:
		case WHILE:
		case LPAR:
		case IDENT:
		{
			algorithm();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp52_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp52_AST = astFactory.create(LT(1));
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp53_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp53_AST = astFactory.create(LT(1));
			match(SEMICOLON);
			break;
		}
		default:
		{
			goto _loop97;
		}
		}
	}
	_loop97:;
	}
	algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = algorithm_clause_AST;
}

void flat_modelica_parser::external_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST external_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp54_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp54_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp54_AST));
	}
	match(EXTERNAL);
	{
	switch ( LA(1)) {
	case STRING:
	{
		language_specification();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case ANNOTATION:
	case END:
	case SEMICOLON:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	{
	switch ( LA(1)) {
	case IDENT:
	{
		external_function_call();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case ANNOTATION:
	case END:
	case SEMICOLON:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	{
	switch ( LA(1)) {
	case SEMICOLON:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp55_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp55_AST = astFactory.create(LT(1));
		match(SEMICOLON);
		break;
	}
	case ANNOTATION:
	case END:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	{
	switch ( LA(1)) {
	case ANNOTATION:
	{
		annotation();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp56_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp56_AST = astFactory.create(LT(1));
		match(SEMICOLON);
		break;
	}
	case END:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	external_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = external_clause_AST;
}

void flat_modelica_parser::language_specification() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST language_specification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp57_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp57_AST = astFactory.create(LT(1));
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp57_AST));
	}
	match(STRING);
	language_specification_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = language_specification_AST;
}

void flat_modelica_parser::external_function_call() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST external_function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if ((LA(1)==IDENT) && (LA(2)==LBRACK||LA(2)==EQUALS||LA(2)==DOT)) {
		component_reference();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp58_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp58_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp58_AST));
		}
		match(EQUALS);
	}
	else if ((LA(1)==IDENT) && (LA(2)==LPAR)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp59_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp59_AST = astFactory.create(LT(1));
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp59_AST));
	}
	match(IDENT);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp60_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp60_AST = astFactory.create(LT(1));
	match(LPAR);
	{
	switch ( LA(1)) {
	case END:
	case FALSE:
	case IF:
	case INITIAL:
	case NOT:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	{
		expression_list();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case RPAR:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp61_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp61_AST = astFactory.create(LT(1));
	match(RPAR);
	if ( inputState->guessing==0 ) {
		external_function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 157 "flat_modelica_parser.g"
		
					external_function_call_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(EXTERNAL_FUNCTION_CALL,"EXTERNAL_FUNCTION_CALL"))->add(external_function_call_AST)));
				
#line 1574 "flat_modelica_parser.cpp"
		currentAST.root = external_function_call_AST;
		if ( external_function_call_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			external_function_call_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = external_function_call_AST->getFirstChild();
		else
			currentAST.child = external_function_call_AST;
		currentAST.advanceChildToEnd();
	}
	external_function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = external_function_call_AST;
}

void flat_modelica_parser::annotation() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST annotation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp62_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp62_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp62_AST));
	}
	match(ANNOTATION);
	class_modification();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	annotation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = annotation_AST;
}

void flat_modelica_parser::component_reference() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_reference_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp63_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp63_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp63_AST));
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case AND:
	case ANNOTATION:
	case ELSE:
	case ELSEIF:
	case EXTENDS:
	case FOR:
	case LOOP:
	case OR:
	case THEN:
	case LPAR:
	case RPAR:
	case RBRACK:
	case RBRACE:
	case EQUALS:
	case ASSIGN:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case COMMA:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case COLON:
	case SEMICOLON:
	case POWER:
	case IDENT:
	case STRING:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	{
	switch ( LA(1)) {
	case DOT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp64_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp64_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp64_AST));
		}
		match(DOT);
		component_reference();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case AND:
	case ANNOTATION:
	case ELSE:
	case ELSEIF:
	case EXTENDS:
	case FOR:
	case LOOP:
	case OR:
	case THEN:
	case LPAR:
	case RPAR:
	case RBRACK:
	case RBRACE:
	case EQUALS:
	case ASSIGN:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case COMMA:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case COLON:
	case SEMICOLON:
	case POWER:
	case IDENT:
	case STRING:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	component_reference_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = component_reference_AST;
}

void flat_modelica_parser::expression_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	expression_list2();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		expression_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 701 "flat_modelica_parser.g"
		
					expression_list_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(EXPRESSION_LIST,"EXPRESSION_LIST"))->add(expression_list_AST)));
				
#line 1743 "flat_modelica_parser.cpp"
		currentAST.root = expression_list_AST;
		if ( expression_list_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			expression_list_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = expression_list_AST->getFirstChild();
		else
			currentAST.child = expression_list_AST;
		currentAST.advanceChildToEnd();
	}
	expression_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = expression_list_AST;
}

void flat_modelica_parser::element() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ic_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ec_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST cc_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST cc2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	switch ( LA(1)) {
	case IMPORT:
	{
		import_clause();
		if (inputState->guessing==0) {
			ic_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		element_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	case EXTENDS:
	{
		extends_clause();
		if (inputState->guessing==0) {
			ec_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		element_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case CONSTANT:
	case DISCRETE:
	case ENCAPSULATED:
	case FINAL:
	case FLOW:
	case FUNCTION:
	case INNER:
	case INPUT:
	case MODEL:
	case OUTER:
	case OUTPUT:
	case PACKAGE:
	case PARAMETER:
	case PARTIAL:
	case RECORD:
	case REPLACEABLE:
	case TYPE:
	case IDENT:
	{
		{
		switch ( LA(1)) {
		case FINAL:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp65_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp65_AST = astFactory.create(LT(1));
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp65_AST));
			}
			match(FINAL);
			break;
		}
		case BLOCK:
		case CLASS:
		case CONNECTOR:
		case CONSTANT:
		case DISCRETE:
		case ENCAPSULATED:
		case FLOW:
		case FUNCTION:
		case INNER:
		case INPUT:
		case MODEL:
		case OUTER:
		case OUTPUT:
		case PACKAGE:
		case PARAMETER:
		case PARTIAL:
		case RECORD:
		case REPLACEABLE:
		case TYPE:
		case IDENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		{
		switch ( LA(1)) {
		case INNER:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp66_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp66_AST = astFactory.create(LT(1));
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp66_AST));
			}
			match(INNER);
			break;
		}
		case OUTER:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp67_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp67_AST = astFactory.create(LT(1));
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp67_AST));
			}
			match(OUTER);
			break;
		}
		case BLOCK:
		case CLASS:
		case CONNECTOR:
		case CONSTANT:
		case DISCRETE:
		case ENCAPSULATED:
		case FLOW:
		case FUNCTION:
		case INPUT:
		case MODEL:
		case OUTPUT:
		case PACKAGE:
		case PARAMETER:
		case PARTIAL:
		case RECORD:
		case REPLACEABLE:
		case TYPE:
		case IDENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		{
		switch ( LA(1)) {
		case BLOCK:
		case CLASS:
		case CONNECTOR:
		case CONSTANT:
		case DISCRETE:
		case ENCAPSULATED:
		case FLOW:
		case FUNCTION:
		case INPUT:
		case MODEL:
		case OUTPUT:
		case PACKAGE:
		case PARAMETER:
		case PARTIAL:
		case RECORD:
		case TYPE:
		case IDENT:
		{
			{
			switch ( LA(1)) {
			case BLOCK:
			case CLASS:
			case CONNECTOR:
			case ENCAPSULATED:
			case FUNCTION:
			case MODEL:
			case PACKAGE:
			case PARTIAL:
			case RECORD:
			case TYPE:
			{
				class_definition();
				if (inputState->guessing==0) {
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				break;
			}
			case CONSTANT:
			case DISCRETE:
			case FLOW:
			case INPUT:
			case OUTPUT:
			case PARAMETER:
			case IDENT:
			{
				component_clause();
				if (inputState->guessing==0) {
					cc_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}
			}
			}
			break;
		}
		case REPLACEABLE:
		{
			{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp68_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp68_AST = astFactory.create(LT(1));
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp68_AST));
			}
			match(REPLACEABLE);
			{
			switch ( LA(1)) {
			case BLOCK:
			case CLASS:
			case CONNECTOR:
			case ENCAPSULATED:
			case FUNCTION:
			case MODEL:
			case PACKAGE:
			case PARTIAL:
			case RECORD:
			case TYPE:
			{
				class_definition();
				if (inputState->guessing==0) {
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				break;
			}
			case CONSTANT:
			case DISCRETE:
			case FLOW:
			case INPUT:
			case OUTPUT:
			case PARAMETER:
			case IDENT:
			{
				component_clause();
				if (inputState->guessing==0) {
					cc2_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}
			}
			}
			{
			switch ( LA(1)) {
			case EXTENDS:
			{
				constraining_clause();
				if (inputState->guessing==0) {
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				comment();
				if (inputState->guessing==0) {
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				break;
			}
			case SEMICOLON:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}
			}
			}
			}
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		if ( inputState->guessing==0 ) {
			element_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 177 "flat_modelica_parser.g"
			
						if(cc_AST != null || cc2_AST != null) 
						{ 
							element_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(DECLARATION,"DECLARATION"))->add(element_AST))); 
						}
						else	
						{ 
							element_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(DEFINITION,"DEFINITION"))->add(element_AST))); 
						}
					
#line 2055 "flat_modelica_parser.cpp"
			currentAST.root = element_AST;
			if ( element_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
				element_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
				  currentAST.child = element_AST->getFirstChild();
			else
				currentAST.child = element_AST;
			currentAST.advanceChildToEnd();
		}
		element_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	returnAST = element_AST;
}

void flat_modelica_parser::import_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST import_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp69_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp69_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp69_AST));
	}
	match(IMPORT);
	{
	if ((LA(1)==IDENT) && (LA(2)==EQUALS)) {
		explicit_import_name();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1)==STAR||LA(1)==IDENT) && (_tokenSet_5.member(LA(2)))) {
		implicit_import_name();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	comment();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	import_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = import_clause_AST;
}

void flat_modelica_parser::extends_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST extends_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp70_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp70_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp70_AST));
	}
	match(EXTENDS);
	name_path();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	switch ( LA(1)) {
	case LPAR:
	{
		class_modification();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case ANNOTATION:
	case RPAR:
	case COMMA:
	case SEMICOLON:
	case STRING:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	extends_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = extends_clause_AST;
}

void flat_modelica_parser::component_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	type_prefix();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	type_specifier();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	component_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	component_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = component_clause_AST;
}

void flat_modelica_parser::constraining_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST constraining_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	extends_clause();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	constraining_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = constraining_clause_AST;
}

void flat_modelica_parser::explicit_import_name() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST explicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp71_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp71_AST = astFactory.create(LT(1));
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp71_AST));
	}
	match(IDENT);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp72_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp72_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp72_AST));
	}
	match(EQUALS);
	name_path();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	explicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = explicit_import_name_AST;
}

void flat_modelica_parser::implicit_import_name() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST implicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST np_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 197 "flat_modelica_parser.g"
	
				bool has_star = false;
			
#line 2243 "flat_modelica_parser.cpp"
	
	has_star=name_path_star();
	if (inputState->guessing==0) {
		np_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
	}
	if ( inputState->guessing==0 ) {
		implicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 203 "flat_modelica_parser.g"
		
					if (has_star)
					{
						implicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(UNQUALIFIED,"UNQUALIFIED"))->add(np_AST)));
					}
					else
					{
						implicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(QUALIFIED,"QUALIFIED"))->add(np_AST)));
					}
				
#line 2262 "flat_modelica_parser.cpp"
		currentAST.root = implicit_import_name_AST;
		if ( implicit_import_name_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			implicit_import_name_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = implicit_import_name_AST->getFirstChild();
		else
			currentAST.child = implicit_import_name_AST;
		currentAST.advanceChildToEnd();
	}
	returnAST = implicit_import_name_AST;
}

bool  flat_modelica_parser::name_path_star() {
#line 631 "flat_modelica_parser.g"
	bool val;
#line 2277 "flat_modelica_parser.cpp"
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST name_path_star_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefToken  i = ANTLR_USE_NAMESPACE(antlr)nullToken;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST np_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (((LA(1)==IDENT) && (LA(2)==ANNOTATION||LA(2)==SEMICOLON||LA(2)==STRING))&&( LA(2)!=DOT )) {
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp73_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp73_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp73_AST));
		}
		match(IDENT);
		if ( inputState->guessing==0 ) {
#line 633 "flat_modelica_parser.g"
			val=false;
#line 2295 "flat_modelica_parser.cpp"
		}
		name_path_star_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else if (((LA(1)==STAR))&&( LA(2)!=DOT )) {
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp74_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp74_AST = astFactory.create(LT(1));
		match(STAR);
		if ( inputState->guessing==0 ) {
#line 634 "flat_modelica_parser.g"
			val=true;
#line 2306 "flat_modelica_parser.cpp"
		}
		name_path_star_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else if ((LA(1)==IDENT) && (LA(2)==DOT)) {
		i = LT(1);
		if (inputState->guessing==0) {
			i_AST = astFactory.create(i);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		}
		match(IDENT);
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp75_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp75_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp75_AST));
		}
		match(DOT);
		val=name_path_star();
		if (inputState->guessing==0) {
			np_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		if ( inputState->guessing==0 ) {
			name_path_star_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 636 "flat_modelica_parser.g"
			
						if(!(np_AST))
						{
							name_path_star_AST = i_AST;
						}
					
#line 2337 "flat_modelica_parser.cpp"
			currentAST.root = name_path_star_AST;
			if ( name_path_star_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
				name_path_star_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
				  currentAST.child = name_path_star_AST->getFirstChild();
			else
				currentAST.child = name_path_star_AST;
			currentAST.advanceChildToEnd();
		}
		name_path_star_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = name_path_star_AST;
	return val;
}

void flat_modelica_parser::type_specifier() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST type_specifier_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	name_path();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	type_specifier_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = type_specifier_AST;
}

void flat_modelica_parser::component_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	component_declaration();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==COMMA)) {
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp76_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp76_AST = astFactory.create(LT(1));
			match(COMMA);
			component_declaration();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop66;
		}
		
	}
	_loop66:;
	}
	component_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = component_list_AST;
}

void flat_modelica_parser::component_declaration() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_declaration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	declaration();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	comment();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	component_declaration_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = component_declaration_AST;
}

void flat_modelica_parser::declaration() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST declaration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	component_reference();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	declaration_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = declaration_AST;
}

void flat_modelica_parser::modification() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST modification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case LPAR:
	{
		class_modification();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		switch ( LA(1)) {
		case EQUALS:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp77_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp77_AST = astFactory.create(LT(1));
			match(EQUALS);
			expression();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case RPAR:
		case COMMA:
		case STRING:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		break;
	}
	case EQUALS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp78_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp78_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp78_AST));
		}
		match(EQUALS);
		expression();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case ASSIGN:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp79_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp79_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp79_AST));
		}
		match(ASSIGN);
		expression();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	modification_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = modification_AST;
}

void flat_modelica_parser::expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case IF:
	{
		if_expression();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case END:
	case FALSE:
	case INITIAL:
	case NOT:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	{
		simple_expression();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = expression_AST;
}

void flat_modelica_parser::argument_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST argument_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	argument();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==COMMA)) {
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp80_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp80_AST = astFactory.create(LT(1));
			match(COMMA);
			argument();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop76;
		}
		
	}
	_loop76:;
	}
	if ( inputState->guessing==0 ) {
		argument_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 291 "flat_modelica_parser.g"
		
					argument_list_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(ARGUMENT_LIST,"ARGUMENT_LIST"))->add(argument_list_AST)));
				
#line 2587 "flat_modelica_parser.cpp"
		currentAST.root = argument_list_AST;
		if ( argument_list_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			argument_list_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = argument_list_AST->getFirstChild();
		else
			currentAST.child = argument_list_AST;
		currentAST.advanceChildToEnd();
	}
	argument_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = argument_list_AST;
}

void flat_modelica_parser::argument() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST argument_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST em_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST er_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case EACH:
	case FINAL:
	case IDENT:
	{
		element_modification();
		if (inputState->guessing==0) {
			em_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
		}
		if ( inputState->guessing==0 ) {
			argument_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 298 "flat_modelica_parser.g"
			
						argument_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(ELEMENT_MODIFICATION,"ELEMENT_MODIFICATION"))->add(em_AST))); 
					
#line 2623 "flat_modelica_parser.cpp"
			currentAST.root = argument_AST;
			if ( argument_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
				argument_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
				  currentAST.child = argument_AST->getFirstChild();
			else
				currentAST.child = argument_AST;
			currentAST.advanceChildToEnd();
		}
		break;
	}
	case REDECLARE:
	{
		element_redeclaration();
		if (inputState->guessing==0) {
			er_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
		}
		if ( inputState->guessing==0 ) {
			argument_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 302 "flat_modelica_parser.g"
			
						argument_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(ELEMENT_REDECLARATION,"ELEMENT_REDECLARATION"))->add(er_AST))); 		
#line 2645 "flat_modelica_parser.cpp"
			currentAST.root = argument_AST;
			if ( argument_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
				argument_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
				  currentAST.child = argument_AST->getFirstChild();
			else
				currentAST.child = argument_AST;
			currentAST.advanceChildToEnd();
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	returnAST = argument_AST;
}

void flat_modelica_parser::element_modification() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_modification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case EACH:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp81_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp81_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp81_AST));
		}
		match(EACH);
		break;
	}
	case FINAL:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	{
	switch ( LA(1)) {
	case FINAL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp82_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp82_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp82_AST));
		}
		match(FINAL);
		break;
	}
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	component_reference();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	modification();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	string_comment();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	element_modification_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = element_modification_AST;
}

void flat_modelica_parser::element_redeclaration() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_redeclaration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp83_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp83_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp83_AST));
	}
	match(REDECLARE);
	{
	switch ( LA(1)) {
	case EACH:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp84_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp84_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp84_AST));
		}
		match(EACH);
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case CONSTANT:
	case DISCRETE:
	case ENCAPSULATED:
	case FINAL:
	case FLOW:
	case FUNCTION:
	case INPUT:
	case MODEL:
	case OUTPUT:
	case PACKAGE:
	case PARAMETER:
	case PARTIAL:
	case RECORD:
	case REPLACEABLE:
	case TYPE:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	{
	switch ( LA(1)) {
	case FINAL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp85_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp85_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp85_AST));
		}
		match(FINAL);
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case CONSTANT:
	case DISCRETE:
	case ENCAPSULATED:
	case FLOW:
	case FUNCTION:
	case INPUT:
	case MODEL:
	case OUTPUT:
	case PACKAGE:
	case PARAMETER:
	case PARTIAL:
	case RECORD:
	case REPLACEABLE:
	case TYPE:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	{
	switch ( LA(1)) {
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case CONSTANT:
	case DISCRETE:
	case ENCAPSULATED:
	case FLOW:
	case FUNCTION:
	case INPUT:
	case MODEL:
	case OUTPUT:
	case PACKAGE:
	case PARAMETER:
	case PARTIAL:
	case RECORD:
	case TYPE:
	case IDENT:
	{
		{
		switch ( LA(1)) {
		case BLOCK:
		case CLASS:
		case CONNECTOR:
		case ENCAPSULATED:
		case FUNCTION:
		case MODEL:
		case PACKAGE:
		case PARTIAL:
		case RECORD:
		case TYPE:
		{
			class_definition();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case IDENT:
		{
			component_clause1();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		break;
	}
	case REPLACEABLE:
	{
		{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp86_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp86_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp86_AST));
		}
		match(REPLACEABLE);
		{
		switch ( LA(1)) {
		case BLOCK:
		case CLASS:
		case CONNECTOR:
		case ENCAPSULATED:
		case FUNCTION:
		case MODEL:
		case PACKAGE:
		case PARTIAL:
		case RECORD:
		case TYPE:
		{
			class_definition();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case IDENT:
		{
			component_clause1();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		{
		switch ( LA(1)) {
		case EXTENDS:
		{
			constraining_clause();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case RPAR:
		case COMMA:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	element_redeclaration_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = element_redeclaration_AST;
}

void flat_modelica_parser::component_clause1() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_clause1_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	type_prefix();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	type_specifier();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	component_declaration();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	component_clause1_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = component_clause1_AST;
}

void flat_modelica_parser::equation_annotation_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_annotation_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (((_tokenSet_6.member(LA(1))) && (_tokenSet_7.member(LA(2))))&&( LA(1) == END || LA(1) == EQUATION || LA(1) == ALGORITHM || LA(1)==INITIAL)) {
		equation_annotation_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else if ((_tokenSet_8.member(LA(1))) && (_tokenSet_9.member(LA(2)))) {
		{
		switch ( LA(1)) {
		case CONNECT:
		case END:
		case FALSE:
		case FOR:
		case IF:
		case INITIAL:
		case NOT:
		case TRUE:
		case UNSIGNED_REAL:
		case WHEN:
		case LPAR:
		case LBRACK:
		case LBRACE:
		case PLUS:
		case MINUS:
		case IDENT:
		case UNSIGNED_INTEGER:
		case STRING:
		{
			equation();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp87_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp87_AST = astFactory.create(LT(1));
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp88_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp88_AST = astFactory.create(LT(1));
			match(SEMICOLON);
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		equation_annotation_list();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		equation_annotation_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = equation_annotation_list_AST;
}

void flat_modelica_parser::equation() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case IF:
	{
		conditional_equation_e();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case FOR:
	{
		for_clause_e();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case CONNECT:
	{
		connect_clause();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case WHEN:
	{
		when_clause_e();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	default:
		bool synPredMatched104 = false;
		if (((_tokenSet_10.member(LA(1))) && (_tokenSet_9.member(LA(2))))) {
			int _m104 = mark();
			synPredMatched104 = true;
			inputState->guessing++;
			try {
				{
				simple_expression();
				match(EQUALS);
				}
			}
			catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
				synPredMatched104 = false;
			}
			rewind(_m104);
			inputState->guessing--;
		}
		if ( synPredMatched104 ) {
			equality_equation();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else if ((LA(1)==IDENT) && (LA(2)==LPAR)) {
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp89_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp89_AST = astFactory.create(LT(1));
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp89_AST));
			}
			match(IDENT);
			function_call();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	if ( inputState->guessing==0 ) {
		equation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 375 "flat_modelica_parser.g"
		
		equation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(EQUATION_STATEMENT,"EQUATION_STATEMENT"))->add(equation_AST)));
		
#line 3140 "flat_modelica_parser.cpp"
		currentAST.root = equation_AST;
		if ( equation_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			equation_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = equation_AST->getFirstChild();
		else
			currentAST.child = equation_AST;
		currentAST.advanceChildToEnd();
	}
	comment();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	equation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = equation_AST;
}

void flat_modelica_parser::algorithm() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case IDENT:
	{
		assign_clause_a();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case LPAR:
	{
		multi_assign_clause_a();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case IF:
	{
		conditional_equation_a();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case FOR:
	{
		for_clause_a();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case WHILE:
	{
		while_clause();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case WHEN:
	{
		when_clause_a();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	comment();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		algorithm_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 390 "flat_modelica_parser.g"
		
		algorithm_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(ALGORITHM_STATEMENT,"ALGORITHM_STATEMENT"))->add(algorithm_AST)));
		
#line 3228 "flat_modelica_parser.cpp"
		currentAST.root = algorithm_AST;
		if ( algorithm_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			algorithm_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = algorithm_AST->getFirstChild();
		else
			currentAST.child = algorithm_AST;
		currentAST.advanceChildToEnd();
	}
	algorithm_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = algorithm_AST;
}

void flat_modelica_parser::simple_expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST simple_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST l1_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST l2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST l3_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	logical_expression();
	if (inputState->guessing==0) {
		l1_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
	}
	{
	switch ( LA(1)) {
	case COLON:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp90_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp90_AST = astFactory.create(LT(1));
		}
		match(COLON);
		logical_expression();
		if (inputState->guessing==0) {
			l2_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
		}
		{
		switch ( LA(1)) {
		case COLON:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp91_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp91_AST = astFactory.create(LT(1));
			}
			match(COLON);
			logical_expression();
			if (inputState->guessing==0) {
				l3_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
			}
			break;
		}
		case ANNOTATION:
		case ELSE:
		case ELSEIF:
		case FOR:
		case LOOP:
		case THEN:
		case RPAR:
		case RBRACK:
		case RBRACE:
		case EQUALS:
		case COMMA:
		case SEMICOLON:
		case IDENT:
		case STRING:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		break;
	}
	case ANNOTATION:
	case ELSE:
	case ELSEIF:
	case FOR:
	case LOOP:
	case THEN:
	case RPAR:
	case RBRACK:
	case RBRACE:
	case EQUALS:
	case COMMA:
	case SEMICOLON:
	case IDENT:
	case STRING:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	if ( inputState->guessing==0 ) {
		simple_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 530 "flat_modelica_parser.g"
		
					if (l3_AST != null) 
					{ 
						simple_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(4))->add(astFactory.create(RANGE3,"RANGE3"))->add(l1_AST)->add(l2_AST)->add(l3_AST))); 
					}
					else if (l2_AST != null) 
					{ 
						simple_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(3))->add(astFactory.create(RANGE2,"RANGE2"))->add(l1_AST)->add(l2_AST))); 
					}
					else 
					{ 
						simple_expression_AST = l1_AST; 
					}
				
#line 3346 "flat_modelica_parser.cpp"
		currentAST.root = simple_expression_AST;
		if ( simple_expression_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			simple_expression_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = simple_expression_AST->getFirstChild();
		else
			currentAST.child = simple_expression_AST;
		currentAST.advanceChildToEnd();
	}
	returnAST = simple_expression_AST;
}

void flat_modelica_parser::equality_equation() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equality_equation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	simple_expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp92_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp92_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp92_AST));
	}
	match(EQUALS);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	equality_equation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = equality_equation_AST;
}

void flat_modelica_parser::conditional_equation_e() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST conditional_equation_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp93_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp93_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp93_AST));
	}
	match(IF);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp94_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp94_AST = astFactory.create(LT(1));
	match(THEN);
	equation_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==ELSEIF)) {
			equation_elseif();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop113;
		}
		
	}
	_loop113:;
	}
	{
	switch ( LA(1)) {
	case ELSE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp95_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp95_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp95_AST));
		}
		match(ELSE);
		equation_list();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case END:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp96_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp96_AST = astFactory.create(LT(1));
	match(END);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp97_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp97_AST = astFactory.create(LT(1));
	match(IF);
	conditional_equation_e_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = conditional_equation_e_AST;
}

void flat_modelica_parser::for_clause_e() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_clause_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp98_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp98_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp98_AST));
	}
	match(FOR);
	for_indices();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp99_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp99_AST = astFactory.create(LT(1));
	match(LOOP);
	equation_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp100_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp100_AST = astFactory.create(LT(1));
	match(END);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp101_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp101_AST = astFactory.create(LT(1));
	match(FOR);
	for_clause_e_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = for_clause_e_AST;
}

void flat_modelica_parser::connect_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST connect_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp102_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp102_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp102_AST));
	}
	match(CONNECT);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp103_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp103_AST = astFactory.create(LT(1));
	match(LPAR);
	connector_ref();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp104_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp104_AST = astFactory.create(LT(1));
	match(COMMA);
	connector_ref();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp105_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp105_AST = astFactory.create(LT(1));
	match(RPAR);
	connect_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = connect_clause_AST;
}

void flat_modelica_parser::when_clause_e() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST when_clause_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp106_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp106_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp106_AST));
	}
	match(WHEN);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp107_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp107_AST = astFactory.create(LT(1));
	match(THEN);
	equation_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==ELSEWHEN)) {
			else_when_e();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop124;
		}
		
	}
	_loop124:;
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp108_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp108_AST = astFactory.create(LT(1));
	match(END);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp109_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp109_AST = astFactory.create(LT(1));
	match(WHEN);
	when_clause_e_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = when_clause_e_AST;
}

void flat_modelica_parser::function_call() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp110_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp110_AST = astFactory.create(LT(1));
	match(LPAR);
	{
	function_arguments();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp111_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp111_AST = astFactory.create(LT(1));
	match(RPAR);
	if ( inputState->guessing==0 ) {
		function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 650 "flat_modelica_parser.g"
		
					function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(FUNCTION_ARGUMENTS,"FUNCTION_ARGUMENTS"))->add(function_call_AST)));
				
#line 3588 "flat_modelica_parser.cpp"
		currentAST.root = function_call_AST;
		if ( function_call_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			function_call_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = function_call_AST->getFirstChild();
		else
			currentAST.child = function_call_AST;
		currentAST.advanceChildToEnd();
	}
	function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = function_call_AST;
}

void flat_modelica_parser::assign_clause_a() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST assign_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	component_reference();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	switch ( LA(1)) {
	case ASSIGN:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp112_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp112_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp112_AST));
		}
		match(ASSIGN);
		expression();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case LPAR:
	{
		function_call();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	assign_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = assign_clause_a_AST;
}

void flat_modelica_parser::multi_assign_clause_a() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST multi_assign_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp113_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp113_AST = astFactory.create(LT(1));
	match(LPAR);
	expression_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp114_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp114_AST = astFactory.create(LT(1));
	match(RPAR);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp115_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp115_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp115_AST));
	}
	match(ASSIGN);
	component_reference();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	function_call();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	multi_assign_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = multi_assign_clause_a_AST;
}

void flat_modelica_parser::conditional_equation_a() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST conditional_equation_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp116_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp116_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp116_AST));
	}
	match(IF);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp117_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp117_AST = astFactory.create(LT(1));
	match(THEN);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==ELSEIF)) {
			algorithm_elseif();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop117;
		}
		
	}
	_loop117:;
	}
	{
	switch ( LA(1)) {
	case ELSE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp118_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp118_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp118_AST));
		}
		match(ELSE);
		algorithm_list();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case END:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp119_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp119_AST = astFactory.create(LT(1));
	match(END);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp120_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp120_AST = astFactory.create(LT(1));
	match(IF);
	conditional_equation_a_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = conditional_equation_a_AST;
}

void flat_modelica_parser::for_clause_a() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp121_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp121_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp121_AST));
	}
	match(FOR);
	for_indices();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp122_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp122_AST = astFactory.create(LT(1));
	match(LOOP);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp123_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp123_AST = astFactory.create(LT(1));
	match(END);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp124_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp124_AST = astFactory.create(LT(1));
	match(FOR);
	for_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = for_clause_a_AST;
}

void flat_modelica_parser::while_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST while_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp125_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp125_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp125_AST));
	}
	match(WHILE);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp126_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp126_AST = astFactory.create(LT(1));
	match(LOOP);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp127_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp127_AST = astFactory.create(LT(1));
	match(END);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp128_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp128_AST = astFactory.create(LT(1));
	match(WHILE);
	while_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = while_clause_AST;
}

void flat_modelica_parser::when_clause_a() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST when_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp129_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp129_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp129_AST));
	}
	match(WHEN);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp130_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp130_AST = astFactory.create(LT(1));
	match(THEN);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==ELSEWHEN)) {
			else_when_a();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop128;
		}
		
	}
	_loop128:;
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp131_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp131_AST = astFactory.create(LT(1));
	match(END);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp132_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp132_AST = astFactory.create(LT(1));
	match(WHEN);
	when_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = when_clause_a_AST;
}

void flat_modelica_parser::equation_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if ((((LA(1) >= ELSE && LA(1) <= END)) && (_tokenSet_11.member(LA(2))))&&(LA(1) != END || (LA(1) == END && LA(2) != IDENT))) {
		equation_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else if ((_tokenSet_11.member(LA(1))) && (_tokenSet_9.member(LA(2)))) {
		{
		equation();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp133_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp133_AST = astFactory.create(LT(1));
		match(SEMICOLON);
		equation_list();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		}
		equation_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = equation_list_AST;
}

void flat_modelica_parser::equation_elseif() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_elseif_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp134_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp134_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp134_AST));
	}
	match(ELSEIF);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp135_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp135_AST = astFactory.create(LT(1));
	match(THEN);
	equation_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	equation_elseif_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = equation_elseif_AST;
}

void flat_modelica_parser::algorithm_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	for (;;) {
		if ((_tokenSet_12.member(LA(1)))) {
			algorithm();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp136_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp136_AST = astFactory.create(LT(1));
			match(SEMICOLON);
		}
		else {
			goto _loop136;
		}
		
	}
	_loop136:;
	}
	algorithm_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = algorithm_list_AST;
}

void flat_modelica_parser::algorithm_elseif() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_elseif_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp137_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp137_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp137_AST));
	}
	match(ELSEIF);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp138_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp138_AST = astFactory.create(LT(1));
	match(THEN);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	algorithm_elseif_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = algorithm_elseif_AST;
}

void flat_modelica_parser::for_indices() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_indices_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	for_index();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	for_indices2();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	for_indices_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = for_indices_AST;
}

void flat_modelica_parser::else_when_e() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST else_when_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp139_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp139_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp139_AST));
	}
	match(ELSEWHEN);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp140_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp140_AST = astFactory.create(LT(1));
	match(THEN);
	equation_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	else_when_e_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = else_when_e_AST;
}

void flat_modelica_parser::else_when_a() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST else_when_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp141_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp141_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp141_AST));
	}
	match(ELSEWHEN);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp142_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp142_AST = astFactory.create(LT(1));
	match(THEN);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	else_when_a_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = else_when_a_AST;
}

void flat_modelica_parser::connector_ref() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST connector_ref_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp143_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp143_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp143_AST));
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case RPAR:
	case DOT:
	case COMMA:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	{
	switch ( LA(1)) {
	case DOT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp144_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp144_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp144_AST));
		}
		match(DOT);
		connector_ref_2();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case RPAR:
	case COMMA:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	connector_ref_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = connector_ref_AST;
}

void flat_modelica_parser::connector_ref_2() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST connector_ref_2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp145_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp145_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp145_AST));
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case RPAR:
	case COMMA:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	connector_ref_2_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = connector_ref_2_AST;
}

void flat_modelica_parser::if_expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST if_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp146_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp146_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp146_AST));
	}
	match(IF);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp147_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp147_AST = astFactory.create(LT(1));
	match(THEN);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==ELSEIF)) {
			elseif_expression();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop147;
		}
		
	}
	_loop147:;
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp148_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp148_AST = astFactory.create(LT(1));
	match(ELSE);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = if_expression_AST;
}

void flat_modelica_parser::elseif_expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST elseif_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp149_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp149_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp149_AST));
	}
	match(ELSEIF);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp150_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp150_AST = astFactory.create(LT(1));
	match(THEN);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	elseif_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = elseif_expression_AST;
}

void flat_modelica_parser::for_index() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_index_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp151_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp151_AST = astFactory.create(LT(1));
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp151_AST));
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case IN:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp152_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp152_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp152_AST));
		}
		match(IN);
		expression();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case LOOP:
	case RPAR:
	case COMMA:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	}
	for_index_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = for_index_AST;
}

void flat_modelica_parser::for_indices2() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_indices2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (((LA(1)==LOOP||LA(1)==RPAR||LA(1)==IDENT))&&(LA(2) != IN)) {
		for_indices2_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else if ((LA(1)==COMMA)) {
		{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp153_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp153_AST = astFactory.create(LT(1));
		match(COMMA);
		for_index();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		}
		for_indices2();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		for_indices2_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = for_indices2_AST;
}

void flat_modelica_parser::logical_expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	logical_term();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==OR)) {
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp154_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp154_AST = astFactory.create(LT(1));
				astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp154_AST));
			}
			match(OR);
			logical_term();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop160;
		}
		
	}
	_loop160:;
	}
	logical_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = logical_expression_AST;
}

void flat_modelica_parser::logical_term() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_term_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	logical_factor();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==AND)) {
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp155_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp155_AST = astFactory.create(LT(1));
				astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp155_AST));
			}
			match(AND);
			logical_factor();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop163;
		}
		
	}
	_loop163:;
	}
	logical_term_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = logical_term_AST;
}

void flat_modelica_parser::logical_factor() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_factor_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case NOT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp156_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp156_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp156_AST));
		}
		match(NOT);
		break;
	}
	case END:
	case FALSE:
	case INITIAL:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	relation();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	logical_factor_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = logical_factor_AST;
}

void flat_modelica_parser::relation() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST relation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	arithmetic_expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	switch ( LA(1)) {
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	{
		{
		switch ( LA(1)) {
		case LESS:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp157_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp157_AST = astFactory.create(LT(1));
				astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp157_AST));
			}
			match(LESS);
			break;
		}
		case LESSEQ:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp158_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp158_AST = astFactory.create(LT(1));
				astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp158_AST));
			}
			match(LESSEQ);
			break;
		}
		case GREATER:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp159_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp159_AST = astFactory.create(LT(1));
				astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp159_AST));
			}
			match(GREATER);
			break;
		}
		case GREATEREQ:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp160_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp160_AST = astFactory.create(LT(1));
				astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp160_AST));
			}
			match(GREATEREQ);
			break;
		}
		case EQEQ:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp161_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp161_AST = astFactory.create(LT(1));
				astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp161_AST));
			}
			match(EQEQ);
			break;
		}
		case LESSGT:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp162_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp162_AST = astFactory.create(LT(1));
				astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp162_AST));
			}
			match(LESSGT);
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		arithmetic_expression();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case AND:
	case ANNOTATION:
	case ELSE:
	case ELSEIF:
	case FOR:
	case LOOP:
	case OR:
	case THEN:
	case RPAR:
	case RBRACK:
	case RBRACE:
	case EQUALS:
	case COMMA:
	case COLON:
	case SEMICOLON:
	case IDENT:
	case STRING:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	relation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = relation_AST;
}

void flat_modelica_parser::arithmetic_expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	unary_arithmetic_expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==PLUS||LA(1)==MINUS)) {
			{
			switch ( LA(1)) {
			case PLUS:
			{
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp163_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				if (inputState->guessing==0) {
					tmp163_AST = astFactory.create(LT(1));
					astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp163_AST));
				}
				match(PLUS);
				break;
			}
			case MINUS:
			{
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp164_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				if (inputState->guessing==0) {
					tmp164_AST = astFactory.create(LT(1));
					astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp164_AST));
				}
				match(MINUS);
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}
			}
			}
			term();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop174;
		}
		
	}
	_loop174:;
	}
	arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = arithmetic_expression_AST;
}

void flat_modelica_parser::rel_op() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST rel_op_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case LESS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp165_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp165_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp165_AST));
		}
		match(LESS);
		break;
	}
	case LESSEQ:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp166_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp166_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp166_AST));
		}
		match(LESSEQ);
		break;
	}
	case GREATER:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp167_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp167_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp167_AST));
		}
		match(GREATER);
		break;
	}
	case GREATEREQ:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp168_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp168_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp168_AST));
		}
		match(GREATEREQ);
		break;
	}
	case EQEQ:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp169_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp169_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp169_AST));
		}
		match(EQEQ);
		break;
	}
	case LESSGT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp170_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp170_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp170_AST));
		}
		match(LESSGT);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	rel_op_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = rel_op_AST;
}

void flat_modelica_parser::unary_arithmetic_expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST t1_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST t2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST t3_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case PLUS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp171_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp171_AST = astFactory.create(LT(1));
		}
		match(PLUS);
		term();
		if (inputState->guessing==0) {
			t1_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 573 "flat_modelica_parser.g"
			
						unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(UNARY_PLUS,"PLUS"))->add(t1_AST))); 
					
#line 4688 "flat_modelica_parser.cpp"
			currentAST.root = unary_arithmetic_expression_AST;
			if ( unary_arithmetic_expression_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
				unary_arithmetic_expression_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
				  currentAST.child = unary_arithmetic_expression_AST->getFirstChild();
			else
				currentAST.child = unary_arithmetic_expression_AST;
			currentAST.advanceChildToEnd();
		}
		break;
	}
	case MINUS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp172_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp172_AST = astFactory.create(LT(1));
		}
		match(MINUS);
		term();
		if (inputState->guessing==0) {
			t2_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 577 "flat_modelica_parser.g"
			
						unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(UNARY_MINUS,"MINUS"))->add(t2_AST))); 
					
#line 4716 "flat_modelica_parser.cpp"
			currentAST.root = unary_arithmetic_expression_AST;
			if ( unary_arithmetic_expression_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
				unary_arithmetic_expression_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
				  currentAST.child = unary_arithmetic_expression_AST->getFirstChild();
			else
				currentAST.child = unary_arithmetic_expression_AST;
			currentAST.advanceChildToEnd();
		}
		break;
	}
	case END:
	case FALSE:
	case INITIAL:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	{
		term();
		if (inputState->guessing==0) {
			t3_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 581 "flat_modelica_parser.g"
			
						unary_arithmetic_expression_AST = t3_AST; 
					
#line 4749 "flat_modelica_parser.cpp"
			currentAST.root = unary_arithmetic_expression_AST;
			if ( unary_arithmetic_expression_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
				unary_arithmetic_expression_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
				  currentAST.child = unary_arithmetic_expression_AST->getFirstChild();
			else
				currentAST.child = unary_arithmetic_expression_AST;
			currentAST.advanceChildToEnd();
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	returnAST = unary_arithmetic_expression_AST;
}

void flat_modelica_parser::term() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST term_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	factor();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	for (;;) {
		if ((LA(1)==STAR||LA(1)==SLASH)) {
			{
			switch ( LA(1)) {
			case STAR:
			{
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp173_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				if (inputState->guessing==0) {
					tmp173_AST = astFactory.create(LT(1));
					astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp173_AST));
				}
				match(STAR);
				break;
			}
			case SLASH:
			{
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp174_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				if (inputState->guessing==0) {
					tmp174_AST = astFactory.create(LT(1));
					astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp174_AST));
				}
				match(SLASH);
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}
			}
			}
			factor();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop180;
		}
		
	}
	_loop180:;
	}
	term_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = term_AST;
}

void flat_modelica_parser::factor() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST factor_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	primary();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	switch ( LA(1)) {
	case POWER:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp175_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp175_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp175_AST));
		}
		match(POWER);
		primary();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case AND:
	case ANNOTATION:
	case ELSE:
	case ELSEIF:
	case FOR:
	case LOOP:
	case OR:
	case THEN:
	case RPAR:
	case RBRACK:
	case RBRACE:
	case EQUALS:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case COMMA:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case COLON:
	case SEMICOLON:
	case IDENT:
	case STRING:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	factor_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = factor_AST;
}

void flat_modelica_parser::primary() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST primary_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case UNSIGNED_INTEGER:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp176_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp176_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp176_AST));
		}
		match(UNSIGNED_INTEGER);
		break;
	}
	case UNSIGNED_REAL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp177_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp177_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp177_AST));
		}
		match(UNSIGNED_REAL);
		break;
	}
	case STRING:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp178_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp178_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp178_AST));
		}
		match(STRING);
		break;
	}
	case FALSE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp179_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp179_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp179_AST));
		}
		match(FALSE);
		break;
	}
	case TRUE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp180_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp180_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp180_AST));
		}
		match(TRUE);
		break;
	}
	case INITIAL:
	case IDENT:
	{
		component_reference__function_call();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case LPAR:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp181_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp181_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp181_AST));
		}
		match(LPAR);
		expression_list();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp182_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp182_AST = astFactory.create(LT(1));
		match(RPAR);
		break;
	}
	case LBRACK:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp183_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp183_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp183_AST));
		}
		match(LBRACK);
		expression_list();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		for (;;) {
			if ((LA(1)==SEMICOLON)) {
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp184_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				tmp184_AST = astFactory.create(LT(1));
				match(SEMICOLON);
				expression_list();
				if (inputState->guessing==0) {
					astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
			else {
				goto _loop186;
			}
			
		}
		_loop186:;
		}
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp185_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp185_AST = astFactory.create(LT(1));
		match(RBRACK);
		break;
	}
	case LBRACE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp186_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp186_AST = astFactory.create(LT(1));
			astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp186_AST));
		}
		match(LBRACE);
		expression_list();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp187_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp187_AST = astFactory.create(LT(1));
		match(RBRACE);
		break;
	}
	case END:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp188_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp188_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp188_AST));
		}
		match(END);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	primary_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = primary_AST;
}

void flat_modelica_parser::component_reference__function_call() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_reference__function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST cr_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST fc_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefToken  i = ANTLR_USE_NAMESPACE(antlr)nullToken;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	switch ( LA(1)) {
	case IDENT:
	{
		component_reference();
		if (inputState->guessing==0) {
			cr_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
		}
		{
		switch ( LA(1)) {
		case LPAR:
		{
			function_call();
			if (inputState->guessing==0) {
				fc_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
			}
			break;
		}
		case AND:
		case ANNOTATION:
		case ELSE:
		case ELSEIF:
		case FOR:
		case LOOP:
		case OR:
		case THEN:
		case RPAR:
		case RBRACK:
		case RBRACE:
		case EQUALS:
		case PLUS:
		case MINUS:
		case STAR:
		case SLASH:
		case COMMA:
		case LESS:
		case LESSEQ:
		case GREATER:
		case GREATEREQ:
		case EQEQ:
		case LESSGT:
		case COLON:
		case SEMICOLON:
		case POWER:
		case IDENT:
		case STRING:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		if ( inputState->guessing==0 ) {
			component_reference__function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 611 "flat_modelica_parser.g"
			
						if (fc_AST != null) 
						{ 
							component_reference__function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(3))->add(astFactory.create(FUNCTION_CALL,"FUNCTION_CALL"))->add(cr_AST)->add(fc_AST)));
						} 
						else 
						{ 
							component_reference__function_call_AST = cr_AST;
						} 
					
#line 5121 "flat_modelica_parser.cpp"
			currentAST.root = component_reference__function_call_AST;
			if ( component_reference__function_call_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
				component_reference__function_call_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
				  currentAST.child = component_reference__function_call_AST->getFirstChild();
			else
				currentAST.child = component_reference__function_call_AST;
			currentAST.advanceChildToEnd();
		}
		break;
	}
	case INITIAL:
	{
		i = LT(1);
		if (inputState->guessing==0) {
			i_AST = astFactory.create(i);
		}
		match(INITIAL);
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp189_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp189_AST = astFactory.create(LT(1));
		match(LPAR);
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp190_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp190_AST = astFactory.create(LT(1));
		match(RPAR);
		if ( inputState->guessing==0 ) {
			component_reference__function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 621 "flat_modelica_parser.g"
			
						component_reference__function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(INITIAL_FUNCTION_CALL,"INITIAL_FUNCTION_CALL"))->add(i_AST)));
					
#line 5151 "flat_modelica_parser.cpp"
			currentAST.root = component_reference__function_call_AST;
			if ( component_reference__function_call_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
				component_reference__function_call_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
				  currentAST.child = component_reference__function_call_AST->getFirstChild();
			else
				currentAST.child = component_reference__function_call_AST;
			currentAST.advanceChildToEnd();
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	returnAST = component_reference__function_call_AST;
}

void flat_modelica_parser::function_arguments() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST function_arguments_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	for_or_expression_list();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	}
	{
	switch ( LA(1)) {
	case IDENT:
	{
		named_arguments();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case RPAR:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	function_arguments_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = function_arguments_AST;
}

void flat_modelica_parser::for_or_expression_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_or_expression_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if (((LA(1)==RPAR||LA(1)==IDENT) && (_tokenSet_13.member(LA(2))))&&(LA(1)==IDENT && LA(2) == EQUALS|| LA(1) == RPAR)) {
	}
	else if ((_tokenSet_14.member(LA(1))) && (_tokenSet_15.member(LA(2)))) {
		{
		expression();
		if (inputState->guessing==0) {
			e_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		switch ( LA(1)) {
		case COMMA:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp191_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp191_AST = astFactory.create(LT(1));
			match(COMMA);
			for_or_expression_list2();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case FOR:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp192_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if (inputState->guessing==0) {
				tmp192_AST = astFactory.create(LT(1));
				astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp192_AST));
			}
			match(FOR);
			for_indices();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case RPAR:
		case IDENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		}
		if ( inputState->guessing==0 ) {
			for_or_expression_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 671 "flat_modelica_parser.g"
			
							for_or_expression_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(EXPRESSION_LIST,"EXPRESSION_LIST"))->add(for_or_expression_list_AST)));
						
#line 5266 "flat_modelica_parser.cpp"
			currentAST.root = for_or_expression_list_AST;
			if ( for_or_expression_list_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
				for_or_expression_list_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
				  currentAST.child = for_or_expression_list_AST->getFirstChild();
			else
				currentAST.child = for_or_expression_list_AST;
			currentAST.advanceChildToEnd();
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	for_or_expression_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = for_or_expression_list_AST;
}

void flat_modelica_parser::named_arguments() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST named_arguments_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	named_arguments2();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		named_arguments_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 686 "flat_modelica_parser.g"
		
					named_arguments_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory.make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory.create(NAMED_ARGUMENTS,"NAMED_ARGUMENTS"))->add(named_arguments_AST)));
				
#line 5300 "flat_modelica_parser.cpp"
		currentAST.root = named_arguments_AST;
		if ( named_arguments_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			named_arguments_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = named_arguments_AST->getFirstChild();
		else
			currentAST.child = named_arguments_AST;
		currentAST.advanceChildToEnd();
	}
	named_arguments_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = named_arguments_AST;
}

void flat_modelica_parser::for_or_expression_list2() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_or_expression_list2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (((LA(1)==RPAR||LA(1)==IDENT) && (_tokenSet_13.member(LA(2))))&&(LA(2) == EQUALS)) {
		for_or_expression_list2_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else if ((_tokenSet_14.member(LA(1))) && (_tokenSet_16.member(LA(2)))) {
		expression();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		switch ( LA(1)) {
		case COMMA:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp193_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp193_AST = astFactory.create(LT(1));
			match(COMMA);
			for_or_expression_list2();
			if (inputState->guessing==0) {
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case RPAR:
		case IDENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		for_or_expression_list2_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = for_or_expression_list2_AST;
}

void flat_modelica_parser::named_arguments2() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST named_arguments2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	named_argument();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	switch ( LA(1)) {
	case COMMA:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp194_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp194_AST = astFactory.create(LT(1));
		match(COMMA);
		named_arguments2();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case RPAR:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	named_arguments2_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = named_arguments2_AST;
}

void flat_modelica_parser::named_argument() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST named_argument_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp195_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp195_AST = astFactory.create(LT(1));
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp195_AST));
	}
	match(IDENT);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp196_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if (inputState->guessing==0) {
		tmp196_AST = astFactory.create(LT(1));
		astFactory.makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp196_AST));
	}
	match(EQUALS);
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	named_argument_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = named_argument_AST;
}

void flat_modelica_parser::expression_list2() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_list2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	expression();
	if (inputState->guessing==0) {
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	switch ( LA(1)) {
	case COMMA:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp197_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp197_AST = astFactory.create(LT(1));
		match(COMMA);
		expression_list2();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case RPAR:
	case RBRACK:
	case RBRACE:
	case SEMICOLON:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	expression_list2_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = expression_list2_AST;
}

void flat_modelica_parser::subscript() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST subscript_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	switch ( LA(1)) {
	case END:
	case FALSE:
	case IF:
	case INITIAL:
	case NOT:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	{
		expression();
		if (inputState->guessing==0) {
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		subscript_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	case COLON:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp198_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if (inputState->guessing==0) {
			tmp198_AST = astFactory.create(LT(1));
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp198_AST));
		}
		match(COLON);
		subscript_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	returnAST = subscript_AST;
}

const char* flat_modelica_parser::_tokenNames[] = {
	"<0>",
	"EOF",
	"<2>",
	"NULL_TREE_LOOKAHEAD",
	"\"algorithm\"",
	"\"and\"",
	"\"annotation\"",
	"\"block\"",
	"\"boundary\"",
	"\"class\"",
	"\"connect\"",
	"\"connector\"",
	"\"constant\"",
	"\"discrete\"",
	"\"each\"",
	"\"else\"",
	"\"elseif\"",
	"\"elsewhen\"",
	"\"end\"",
	"\"enumeration\"",
	"\"equation\"",
	"\"encapsulated\"",
	"\"extends\"",
	"\"external\"",
	"\"false\"",
	"\"final\"",
	"\"flow\"",
	"\"for\"",
	"\"function\"",
	"\"if\"",
	"\"import\"",
	"\"in\"",
	"\"initial\"",
	"\"inner\"",
	"\"input\"",
	"\"loop\"",
	"\"model\"",
	"\"not\"",
	"\"outer\"",
	"\"or\"",
	"\"output\"",
	"\"package\"",
	"\"parameter\"",
	"\"partial\"",
	"\"protected\"",
	"\"public\"",
	"\"record\"",
	"\"redeclare\"",
	"\"replaceable\"",
	"\"results\"",
	"\"then\"",
	"\"true\"",
	"\"type\"",
	"\"unsigned_real\"",
	"\"when\"",
	"\"while\"",
	"\"within\"",
	"LPAR",
	"RPAR",
	"LBRACK",
	"RBRACK",
	"LBRACE",
	"RBRACE",
	"EQUALS",
	"ASSIGN",
	"PLUS",
	"MINUS",
	"STAR",
	"SLASH",
	"DOT",
	"COMMA",
	"LESS",
	"LESSEQ",
	"GREATER",
	"GREATEREQ",
	"EQEQ",
	"LESSGT",
	"COLON",
	"SEMICOLON",
	"POWER",
	"WS",
	"ML_COMMENT",
	"ML_COMMENT_CHAR",
	"SL_COMMENT",
	"IDENT",
	"NONDIGIT",
	"DIGIT",
	"EXPONENT",
	"UNSIGNED_INTEGER",
	"STRING",
	"SCHAR",
	"SESCAPE",
	"ESC",
	"ALGORITHM_STATEMENT",
	"ARGUMENT_LIST",
	"CLASS_DEFINITION",
	"CLASS_MODIFICATION",
	"COMMENT",
	"DECLARATION",
	"DEFINITION",
	"ENUMERATION_LITERAL",
	"ELEMENT",
	"ELEMENT_MODIFICATION",
	"ELEMENT_REDECLARATION",
	"EQUATION_STATEMENT",
	"INITIAL_EQUATION",
	"INITIAL_ALGORITHM",
	"EXPRESSION_LIST",
	"EXTERNAL_FUNCTION_CALL",
	"FOR_INDICES",
	"FUNCTION_CALL",
	"INITIAL_FUNCTION_CALL",
	"FUNCTION_ARGUMENTS",
	"NAMED_ARGUMENTS",
	"QUALIFIED",
	"RANGE2",
	"RANGE3",
	"STORED_DEFINITION",
	"STRING_COMMENT",
	"UNARY_MINUS",
	"UNARY_PLUS",
	"UNQUALIFIED",
	0
};

const unsigned long flat_modelica_parser::_tokenSet_0_data_[] = { 304089728UL, 1067536UL, 0UL, 0UL };
// "block" "class" "connector" "encapsulated" "final" "function" "model" 
// "package" "partial" "record" "type" 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_0(_tokenSet_0_data_,4);
const unsigned long flat_modelica_parser::_tokenSet_1_data_[] = { 4194368UL, 234881024UL, 34619456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "extends" LPAR RPAR LBRACK COMMA SEMICOLON IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_1(_tokenSet_1_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_2_data_[] = { 1458846416UL, 1146711UL, 34603008UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "annotation" "block" "class" "connector" "constant" "discrete" 
// "end" "equation" "encapsulated" "extends" "external" "final" "flow" 
// "function" "import" "initial" "inner" "input" "model" "outer" "output" 
// "package" "parameter" "partial" "protected" "public" "record" "replaceable" 
// "type" IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_2(_tokenSet_2_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_3_data_[] = { 67121152UL, 1284UL, 1048576UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "constant" "discrete" "flow" "input" "output" "parameter" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_3(_tokenSet_3_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_4_data_[] = { 1449147072UL, 1134422UL, 1048576UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "block" "class" "connector" "constant" "discrete" "encapsulated" 
// "extends" "final" "flow" "function" "import" "inner" "input" "model" 
// "outer" "output" "package" "parameter" "partial" "record" "replaceable" 
// "type" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_4(_tokenSet_4_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_5_data_[] = { 64UL, 0UL, 33570848UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" DOT SEMICOLON STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_5(_tokenSet_5_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_6_data_[] = { 9699344UL, 12289UL, 0UL, 0UL };
// "algorithm" "end" "equation" "external" "initial" "protected" "public" 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_6(_tokenSet_6_data_,4);
const unsigned long flat_modelica_parser::_tokenSet_7_data_[] = { 2146713296UL, 720994167UL, 51396614UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "annotation" "block" "class" "connect" "connector" "constant" 
// "discrete" "end" "equation" "encapsulated" "extends" "external" "false" 
// "final" "flow" "for" "function" "if" "import" "initial" "inner" "input" 
// "model" "not" "outer" "output" "package" "parameter" "partial" "protected" 
// "public" "record" "replaceable" "true" "type" "unsigned_real" "when" 
// "while" LPAR LBRACK LBRACE PLUS MINUS SEMICOLON IDENT UNSIGNED_INTEGER 
// STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_7(_tokenSet_7_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_8_data_[] = { 688129088UL, 711458849UL, 51380230UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "connect" "end" "false" "for" "if" "initial" "not" "true" 
// "unsigned_real" "when" LPAR LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER 
// STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_8(_tokenSet_8_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_9_data_[] = { 553910304UL, 2854748321UL, 51429310UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real" 
// LPAR LBRACK LBRACE EQUALS PLUS MINUS STAR SLASH DOT LESS LESSEQ GREATER 
// GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_9(_tokenSet_9_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_10_data_[] = { 17039360UL, 707264545UL, 51380230UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "end" "false" "initial" "not" "true" "unsigned_real" LPAR LBRACK LBRACE 
// PLUS MINUS IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_10(_tokenSet_10_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_11_data_[] = { 688129024UL, 711458849UL, 51380230UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "connect" "end" "false" "for" "if" "initial" "not" "true" "unsigned_real" 
// "when" LPAR LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_11(_tokenSet_11_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_12_data_[] = { 671088640UL, 46137344UL, 1048576UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "for" "if" "when" "while" LPAR IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_12(_tokenSet_12_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_13_data_[] = { 134316128UL, 3557032072UL, 34668510UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "annotation" "else" "elseif" "for" "loop" "or" "then" RPAR RBRACK 
// RBRACE EQUALS PLUS MINUS STAR SLASH COMMA LESS LESSEQ GREATER GREATEREQ 
// EQEQ LESSGT COLON SEMICOLON POWER IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_13(_tokenSet_13_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_14_data_[] = { 553910272UL, 707264545UL, 51380230UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "end" "false" "if" "initial" "not" "true" "unsigned_real" LPAR LBRACK 
// LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_14(_tokenSet_14_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_15_data_[] = { 688128032UL, 774373537UL, 51429374UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "end" "false" "for" "if" "initial" "not" "or" "true" "unsigned_real" 
// LPAR RPAR LBRACK LBRACE PLUS MINUS STAR SLASH DOT COMMA LESS LESSEQ 
// GREATER GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_15(_tokenSet_15_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_16_data_[] = { 553910304UL, 774373537UL, 51429374UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real" 
// LPAR RPAR LBRACK LBRACE PLUS MINUS STAR SLASH DOT COMMA LESS LESSEQ 
// GREATER GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_16(_tokenSet_16_data_,8);



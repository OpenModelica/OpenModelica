/* $ANTLR 2.7.2: "modelica_parser.g" -> "modelica_parser.cpp"$ */
#include "modelica_parser.hpp"
#include <antlr/NoViableAltException.hpp>
#include <antlr/SemanticException.hpp>
#include <antlr/ASTFactory.hpp>
#line 1 "modelica_parser.g"
#line 8 "modelica_parser.cpp"
modelica_parser::modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenBuffer& tokenBuf, int k)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(tokenBuf,k)
{
}

modelica_parser::modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenBuffer& tokenBuf)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(tokenBuf,2)
{
}

modelica_parser::modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenStream& lexer, int k)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(lexer,k)
{
}

modelica_parser::modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenStream& lexer)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(lexer,2)
{
}

modelica_parser::modelica_parser(const ANTLR_USE_NAMESPACE(antlr)ParserSharedInputState& state)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(state,2)
{
}

void modelica_parser::stored_definition() {
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
			astFactory->addASTChild( currentAST, returnAST );
		}
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
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_0.member(LA(1)))) {
			{
			switch ( LA(1)) {
			case FINAL:
			{
				f = LT(1);
				if ( inputState->guessing == 0 ) {
					f_AST = astFactory->create(f);
					astFactory->addASTChild(currentAST, f_AST);
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
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
		}
		else {
			goto _loop5;
		}
		
	}
	_loop5:;
	} // ( ... )*
	match(ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE);
	if ( inputState->guessing==0 ) {
		stored_definition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 71 "modelica_parser.g"
		
						stored_definition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(STORED_DEFINITION,"STORED_DEFINITION"))->add(stored_definition_AST)));
					
#line 127 "modelica_parser.cpp"
		currentAST.root = stored_definition_AST;
		if ( stored_definition_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			stored_definition_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = stored_definition_AST->getFirstChild();
		else
			currentAST.child = stored_definition_AST;
		currentAST.advanceChildToEnd();
	}
	stored_definition_AST = currentAST.root;
	returnAST = stored_definition_AST;
}

void modelica_parser::within_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST within_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp4_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp4_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp4_AST);
	}
	match(WITHIN);
	{
	switch ( LA(1)) {
	case IDENT:
	{
		name_path();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	within_clause_AST = currentAST.root;
	returnAST = within_clause_AST;
}

void modelica_parser::class_definition() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_definition_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case ENCAPSULATED:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp5_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp5_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp5_AST);
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
		if ( inputState->guessing == 0 ) {
			tmp6_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp6_AST);
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
		astFactory->addASTChild( currentAST, returnAST );
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp7_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp7_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, tmp7_AST);
	}
	match(IDENT);
	class_specifier();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	if ( inputState->guessing==0 ) {
		class_definition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 91 "modelica_parser.g"
		
					class_definition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(CLASS_DEFINITION,"CLASS_DEFINITION"))->add(class_definition_AST))); 
				
#line 259 "modelica_parser.cpp"
		currentAST.root = class_definition_AST;
		if ( class_definition_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			class_definition_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = class_definition_AST->getFirstChild();
		else
			currentAST.child = class_definition_AST;
		currentAST.advanceChildToEnd();
	}
	class_definition_AST = currentAST.root;
	returnAST = class_definition_AST;
}

void modelica_parser::name_path() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST name_path_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (((LA(1) == IDENT) && (_tokenSet_1.member(LA(2))))&&( LA(2)!=DOT )) {
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp8_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp8_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp8_AST);
		}
		match(IDENT);
		name_path_AST = currentAST.root;
	}
	else if ((LA(1) == IDENT) && (LA(2) == DOT)) {
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp9_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp9_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp9_AST);
		}
		match(IDENT);
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp10_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp10_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp10_AST);
		}
		match(DOT);
		name_path();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		name_path_AST = currentAST.root;
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = name_path_AST;
}

void modelica_parser::class_type() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_type_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case CLASS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp11_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp11_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp11_AST);
		}
		match(CLASS);
		break;
	}
	case MODEL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp12_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp12_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp12_AST);
		}
		match(MODEL);
		break;
	}
	case RECORD:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp13_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp13_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp13_AST);
		}
		match(RECORD);
		break;
	}
	case BLOCK:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp14_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp14_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp14_AST);
		}
		match(BLOCK);
		break;
	}
	case CONNECTOR:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp15_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp15_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp15_AST);
		}
		match(CONNECTOR);
		break;
	}
	case TYPE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp16_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp16_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp16_AST);
		}
		match(TYPE);
		break;
	}
	case PACKAGE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp17_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp17_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp17_AST);
		}
		match(PACKAGE);
		break;
	}
	case FUNCTION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp18_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp18_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp18_AST);
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
	class_type_AST = currentAST.root;
	returnAST = class_type_AST;
}

void modelica_parser::class_specifier() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_specifier_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if ((_tokenSet_2.member(LA(1)))) {
		string_comment();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		composition();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		match(END);
		match(IDENT);
	}
	else if ((LA(1) == EQUALS) && (_tokenSet_3.member(LA(2)))) {
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp21_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp21_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp21_AST);
		}
		match(EQUALS);
		base_prefix();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		name_path();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		{
		switch ( LA(1)) {
		case LBRACK:
		{
			array_subscripts();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
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
				astFactory->addASTChild( currentAST, returnAST );
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
			astFactory->addASTChild( currentAST, returnAST );
		}
	}
	else if ((LA(1) == EQUALS) && (LA(2) == OVERLOAD)) {
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp22_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp22_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp22_AST);
		}
		match(EQUALS);
		overloading();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
	}
	else if ((LA(1) == EQUALS) && (LA(2) == ENUMERATION)) {
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp23_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp23_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp23_AST);
		}
		match(EQUALS);
		enumeration();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	class_specifier_AST = currentAST.root;
	returnAST = class_specifier_AST;
}

void modelica_parser::string_comment() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST string_comment_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case STRING:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp24_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp24_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp24_AST);
		}
		match(STRING);
		{ // ( ... )*
		for (;;) {
			if ((LA(1) == PLUS)) {
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp25_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				if ( inputState->guessing == 0 ) {
					tmp25_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, tmp25_AST);
				}
				match(PLUS);
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp26_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				if ( inputState->guessing == 0 ) {
					tmp26_AST = astFactory->create(LT(1));
					astFactory->addASTChild(currentAST, tmp26_AST);
				}
				match(STRING);
			}
			else {
				goto _loop248;
			}
			
		}
		_loop248:;
		} // ( ... )*
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
#line 791 "modelica_parser.g"
		
		if (string_comment_AST)
		{
		string_comment_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(STRING_COMMENT,"STRING_COMMENT"))->add(string_comment_AST)));
		}
				
#line 623 "modelica_parser.cpp"
		currentAST.root = string_comment_AST;
		if ( string_comment_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			string_comment_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = string_comment_AST->getFirstChild();
		else
			currentAST.child = string_comment_AST;
		currentAST.advanceChildToEnd();
	}
	string_comment_AST = currentAST.root;
	returnAST = string_comment_AST;
}

void modelica_parser::composition() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST composition_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	element_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		switch ( LA(1)) {
		case PUBLIC:
		{
			public_element_list();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
			break;
		}
		case PROTECTED:
		{
			protected_element_list();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
			break;
		}
		case EQUATION:
		{
			equation_clause();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
			break;
		}
		case ALGORITHM:
		{
			algorithm_clause();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
			break;
		}
		default:
			if ((LA(1) == INITIAL) && (LA(2) == EQUATION)) {
				initial_equation_clause();
				if (inputState->guessing==0) {
					astFactory->addASTChild( currentAST, returnAST );
				}
			}
			else if ((LA(1) == INITIAL) && (LA(2) == ALGORITHM)) {
				initial_algorithm_clause();
				if (inputState->guessing==0) {
					astFactory->addASTChild( currentAST, returnAST );
				}
			}
		else {
			goto _loop29;
		}
		}
	}
	_loop29:;
	} // ( ... )*
	{
	switch ( LA(1)) {
	case EXTERNAL:
	{
		external_clause();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	composition_AST = currentAST.root;
	returnAST = composition_AST;
}

void modelica_parser::base_prefix() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST base_prefix_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	type_prefix();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	base_prefix_AST = currentAST.root;
	returnAST = base_prefix_AST;
}

void modelica_parser::array_subscripts() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST array_subscripts_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp27_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp27_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp27_AST);
	}
	match(LBRACK);
	subscript();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == COMMA)) {
			match(COMMA);
			subscript();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop238;
		}
		
	}
	_loop238:;
	} // ( ... )*
	match(RBRACK);
	array_subscripts_AST = currentAST.root;
	returnAST = array_subscripts_AST;
}

void modelica_parser::class_modification() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_modification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
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
			astFactory->addASTChild( currentAST, returnAST );
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
	match(RPAR);
	if ( inputState->guessing==0 ) {
		class_modification_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 291 "modelica_parser.g"
		
					class_modification_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(CLASS_MODIFICATION,"CLASS_MODIFICATION"))->add(class_modification_AST)));
				
#line 809 "modelica_parser.cpp"
		currentAST.root = class_modification_AST;
		if ( class_modification_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			class_modification_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = class_modification_AST->getFirstChild();
		else
			currentAST.child = class_modification_AST;
		currentAST.advanceChildToEnd();
	}
	class_modification_AST = currentAST.root;
	returnAST = class_modification_AST;
}

void modelica_parser::comment() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST comment_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	string_comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{
	switch ( LA(1)) {
	case ANNOTATION:
	{
		annotation();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
#line 784 "modelica_parser.g"
		
					comment_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(COMMENT,"COMMENT"))->add(comment_AST)));
				
#line 862 "modelica_parser.cpp"
		currentAST.root = comment_AST;
		if ( comment_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			comment_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = comment_AST->getFirstChild();
		else
			currentAST.child = comment_AST;
		currentAST.advanceChildToEnd();
	}
	comment_AST = currentAST.root;
	returnAST = comment_AST;
}

void modelica_parser::overloading() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST overloading_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp32_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp32_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp32_AST);
	}
	match(OVERLOAD);
	match(LPAR);
	name_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(RPAR);
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	overloading_AST = currentAST.root;
	returnAST = overloading_AST;
}

void modelica_parser::enumeration() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST enumeration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp35_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp35_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp35_AST);
	}
	match(ENUMERATION);
	match(LPAR);
	enum_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(RPAR);
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	enumeration_AST = currentAST.root;
	returnAST = enumeration_AST;
}

void modelica_parser::type_prefix() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST type_prefix_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case FLOW:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp38_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp38_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp38_AST);
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
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp39_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp39_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp39_AST);
		}
		match(DISCRETE);
		break;
	}
	case PARAMETER:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp40_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp40_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp40_AST);
		}
		match(PARAMETER);
		break;
	}
	case CONSTANT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp41_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp41_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp41_AST);
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
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp42_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp42_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp42_AST);
		}
		match(INPUT);
		break;
	}
	case OUTPUT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp43_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp43_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp43_AST);
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
	type_prefix_AST = currentAST.root;
	returnAST = type_prefix_AST;
}

void modelica_parser::name_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST name_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	name_path();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == COMMA)) {
			match(COMMA);
			name_path();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop21;
		}
		
	}
	_loop21:;
	} // ( ... )*
	name_list_AST = currentAST.root;
	returnAST = name_list_AST;
}

void modelica_parser::enum_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST enum_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	enumeration_literal();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == COMMA)) {
			match(COMMA);
			enumeration_literal();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop25;
		}
		
	}
	_loop25:;
	} // ( ... )*
	enum_list_AST = currentAST.root;
	returnAST = enum_list_AST;
}

void modelica_parser::enumeration_literal() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST enumeration_literal_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp46_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp46_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, tmp46_AST);
	}
	match(IDENT);
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	if ( inputState->guessing==0 ) {
		enumeration_literal_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 131 "modelica_parser.g"
		
					enumeration_literal_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(ENUMERATION_LITERAL,"ENUMERATION_LITERAL"))->add(enumeration_literal_AST)));
				
#line 1116 "modelica_parser.cpp"
		currentAST.root = enumeration_literal_AST;
		if ( enumeration_literal_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			enumeration_literal_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = enumeration_literal_AST->getFirstChild();
		else
			currentAST.child = enumeration_literal_AST;
		currentAST.advanceChildToEnd();
	}
	enumeration_literal_AST = currentAST.root;
	returnAST = enumeration_literal_AST;
}

void modelica_parser::element_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{ // ( ... )*
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
					astFactory->addASTChild( currentAST, returnAST );
				}
				break;
			}
			case ANNOTATION:
			{
				annotation();
				if (inputState->guessing==0) {
					astFactory->addASTChild( currentAST, returnAST );
				}
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}
			}
			}
			match(SEMICOLON);
		}
		else {
			goto _loop45;
		}
		
	}
	_loop45:;
	} // ( ... )*
	element_list_AST = currentAST.root;
	returnAST = element_list_AST;
}

void modelica_parser::public_element_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST public_element_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp48_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp48_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp48_AST);
	}
	match(PUBLIC);
	element_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	public_element_list_AST = currentAST.root;
	returnAST = public_element_list_AST;
}

void modelica_parser::protected_element_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST protected_element_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp49_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp49_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp49_AST);
	}
	match(PROTECTED);
	element_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	protected_element_list_AST = currentAST.root;
	returnAST = protected_element_list_AST;
}

void modelica_parser::initial_equation_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST initial_equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ec_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (!( LA(2)==EQUATION))
		throw ANTLR_USE_NAMESPACE(antlr)SemanticException(" LA(2)==EQUATION");
	match(INITIAL);
	equation_clause();
	if (inputState->guessing==0) {
		ec_AST = returnAST;
		astFactory->addASTChild( currentAST, returnAST );
	}
	if ( inputState->guessing==0 ) {
		initial_equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 341 "modelica_parser.g"
		
		initial_equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(INITIAL_EQUATION,"INTIAL_EQUATION"))->add(ec_AST)));
		
#line 1254 "modelica_parser.cpp"
		currentAST.root = initial_equation_clause_AST;
		if ( initial_equation_clause_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			initial_equation_clause_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = initial_equation_clause_AST->getFirstChild();
		else
			currentAST.child = initial_equation_clause_AST;
		currentAST.advanceChildToEnd();
	}
	initial_equation_clause_AST = currentAST.root;
	returnAST = initial_equation_clause_AST;
}

void modelica_parser::initial_algorithm_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST initial_algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (!( LA(2)==ALGORITHM))
		throw ANTLR_USE_NAMESPACE(antlr)SemanticException(" LA(2)==ALGORITHM");
	match(INITIAL);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp52_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp52_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp52_AST);
	}
	match(ALGORITHM);
	{ // ( ... )*
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
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
			break;
		}
		default:
		{
			goto _loop107;
		}
		}
	}
	_loop107:;
	} // ( ... )*
	if ( inputState->guessing==0 ) {
		initial_algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 371 "modelica_parser.g"
		
			            initial_algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(INITIAL_ALGORITHM,"INTIAL_ALGORITHM"))->add(initial_algorithm_clause_AST)));
				
#line 1321 "modelica_parser.cpp"
		currentAST.root = initial_algorithm_clause_AST;
		if ( initial_algorithm_clause_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			initial_algorithm_clause_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = initial_algorithm_clause_AST->getFirstChild();
		else
			currentAST.child = initial_algorithm_clause_AST;
		currentAST.advanceChildToEnd();
	}
	initial_algorithm_clause_AST = currentAST.root;
	returnAST = initial_algorithm_clause_AST;
}

void modelica_parser::equation_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp55_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp55_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp55_AST);
	}
	match(EQUATION);
	equation_annotation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	equation_clause_AST = currentAST.root;
	returnAST = equation_clause_AST;
}

void modelica_parser::algorithm_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp56_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp56_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp56_AST);
	}
	match(ALGORITHM);
	{ // ( ... )*
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
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
			break;
		}
		default:
		{
			goto _loop104;
		}
		}
	}
	_loop104:;
	} // ( ... )*
	algorithm_clause_AST = currentAST.root;
	returnAST = algorithm_clause_AST;
}

void modelica_parser::external_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST external_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp59_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp59_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp59_AST);
	}
	match(EXTERNAL);
	{
	switch ( LA(1)) {
	case STRING:
	{
		language_specification();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
			astFactory->addASTChild( currentAST, returnAST );
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
			astFactory->addASTChild( currentAST, returnAST );
		}
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
	external_clause_AST = currentAST.root;
	returnAST = external_clause_AST;
}

void modelica_parser::language_specification() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST language_specification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp62_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp62_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, tmp62_AST);
	}
	match(STRING);
	language_specification_AST = currentAST.root;
	returnAST = language_specification_AST;
}

void modelica_parser::external_function_call() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST external_function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if ((LA(1) == IDENT) && (LA(2) == LBRACK || LA(2) == EQUALS || LA(2) == DOT)) {
		component_reference();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp63_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp63_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp63_AST);
		}
		match(EQUALS);
	}
	else if ((LA(1) == IDENT) && (LA(2) == LPAR)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp64_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp64_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, tmp64_AST);
	}
	match(IDENT);
	match(LPAR);
	{
	switch ( LA(1)) {
	case CODE:
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
			astFactory->addASTChild( currentAST, returnAST );
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
	match(RPAR);
	if ( inputState->guessing==0 ) {
		external_function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 173 "modelica_parser.g"
		
					external_function_call_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(EXTERNAL_FUNCTION_CALL,"EXTERNAL_FUNCTION_CALL"))->add(external_function_call_AST)));
				
#line 1590 "modelica_parser.cpp"
		currentAST.root = external_function_call_AST;
		if ( external_function_call_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			external_function_call_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = external_function_call_AST->getFirstChild();
		else
			currentAST.child = external_function_call_AST;
		currentAST.advanceChildToEnd();
	}
	external_function_call_AST = currentAST.root;
	returnAST = external_function_call_AST;
}

void modelica_parser::annotation() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST annotation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp67_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp67_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp67_AST);
	}
	match(ANNOTATION);
	class_modification();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	annotation_AST = currentAST.root;
	returnAST = annotation_AST;
}

void modelica_parser::component_reference() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_reference_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp68_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp68_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp68_AST);
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp69_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp69_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp69_AST);
		}
		match(DOT);
		component_reference();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	component_reference_AST = currentAST.root;
	returnAST = component_reference_AST;
}

void modelica_parser::expression_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	expression_list2();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	if ( inputState->guessing==0 ) {
		expression_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 763 "modelica_parser.g"
		
					expression_list_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(EXPRESSION_LIST,"EXPRESSION_LIST"))->add(expression_list_AST)));
				
#line 1759 "modelica_parser.cpp"
		currentAST.root = expression_list_AST;
		if ( expression_list_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			expression_list_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = expression_list_AST->getFirstChild();
		else
			currentAST.child = expression_list_AST;
		currentAST.advanceChildToEnd();
	}
	expression_list_AST = currentAST.root;
	returnAST = expression_list_AST;
}

void modelica_parser::element() {
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
			ic_AST = returnAST;
			astFactory->addASTChild( currentAST, returnAST );
		}
		element_AST = currentAST.root;
		break;
	}
	case EXTENDS:
	{
		extends_clause();
		if (inputState->guessing==0) {
			ec_AST = returnAST;
			astFactory->addASTChild( currentAST, returnAST );
		}
		element_AST = currentAST.root;
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
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp70_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp70_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, tmp70_AST);
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
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp71_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp71_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, tmp71_AST);
			}
			match(INNER);
			break;
		}
		case OUTER:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp72_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp72_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, tmp72_AST);
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
					astFactory->addASTChild( currentAST, returnAST );
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
					cc_AST = returnAST;
					astFactory->addASTChild( currentAST, returnAST );
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
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp73_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp73_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, tmp73_AST);
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
					astFactory->addASTChild( currentAST, returnAST );
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
					cc2_AST = returnAST;
					astFactory->addASTChild( currentAST, returnAST );
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
					astFactory->addASTChild( currentAST, returnAST );
				}
				comment();
				if (inputState->guessing==0) {
					astFactory->addASTChild( currentAST, returnAST );
				}
				break;
			}
			case RPAR:
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
#line 193 "modelica_parser.g"
			
						if(cc_AST != null || cc2_AST != null) 
						{ 
							element_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(DECLARATION,"DECLARATION"))->add(element_AST))); 
						}
						else	
						{ 
							element_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(DEFINITION,"DEFINITION"))->add(element_AST))); 
						}
					
#line 2072 "modelica_parser.cpp"
			currentAST.root = element_AST;
			if ( element_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
				element_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
				  currentAST.child = element_AST->getFirstChild();
			else
				currentAST.child = element_AST;
			currentAST.advanceChildToEnd();
		}
		element_AST = currentAST.root;
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	returnAST = element_AST;
}

void modelica_parser::import_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST import_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp74_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp74_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp74_AST);
	}
	match(IMPORT);
	{
	if ((LA(1) == IDENT) && (LA(2) == EQUALS)) {
		explicit_import_name();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
	}
	else if ((LA(1) == STAR || LA(1) == IDENT) && (_tokenSet_5.member(LA(2)))) {
		implicit_import_name();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	import_clause_AST = currentAST.root;
	returnAST = import_clause_AST;
}

void modelica_parser::extends_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST extends_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp75_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp75_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp75_AST);
	}
	match(EXTENDS);
	name_path();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{
	switch ( LA(1)) {
	case LPAR:
	{
		class_modification();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	extends_clause_AST = currentAST.root;
	returnAST = extends_clause_AST;
}

void modelica_parser::component_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	type_prefix();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	type_specifier();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
		astFactory->addASTChild( currentAST, returnAST );
	}
	component_clause_AST = currentAST.root;
	returnAST = component_clause_AST;
}

void modelica_parser::constraining_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST constraining_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	extends_clause();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	constraining_clause_AST = currentAST.root;
	returnAST = constraining_clause_AST;
}

void modelica_parser::explicit_import_name() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST explicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp76_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp76_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, tmp76_AST);
	}
	match(IDENT);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp77_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp77_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp77_AST);
	}
	match(EQUALS);
	name_path();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	explicit_import_name_AST = currentAST.root;
	returnAST = explicit_import_name_AST;
}

void modelica_parser::implicit_import_name() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST implicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST np_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 213 "modelica_parser.g"
	
				bool has_star = false;
			
#line 2260 "modelica_parser.cpp"
	
	has_star=name_path_star();
	if (inputState->guessing==0) {
		np_AST = returnAST;
	}
	if ( inputState->guessing==0 ) {
		implicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 219 "modelica_parser.g"
		
					if (has_star)
					{
						implicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(UNQUALIFIED,"UNQUALIFIED"))->add(np_AST)));
					}
					else
					{
						implicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(QUALIFIED,"QUALIFIED"))->add(np_AST)));
					}
				
#line 2279 "modelica_parser.cpp"
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

bool  modelica_parser::name_path_star() {
#line 693 "modelica_parser.g"
	bool val;
#line 2294 "modelica_parser.cpp"
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST name_path_star_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefToken  i = ANTLR_USE_NAMESPACE(antlr)nullToken;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST np_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (((LA(1) == IDENT) && (_tokenSet_6.member(LA(2))))&&( LA(2)!=DOT )) {
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp78_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp78_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp78_AST);
		}
		match(IDENT);
		if ( inputState->guessing==0 ) {
#line 695 "modelica_parser.g"
			val=false;
#line 2312 "modelica_parser.cpp"
		}
		name_path_star_AST = currentAST.root;
	}
	else if (((LA(1) == STAR))&&( LA(2)!=DOT )) {
		match(STAR);
		if ( inputState->guessing==0 ) {
#line 696 "modelica_parser.g"
			val=true;
#line 2321 "modelica_parser.cpp"
		}
		name_path_star_AST = currentAST.root;
	}
	else if ((LA(1) == IDENT) && (LA(2) == DOT)) {
		i = LT(1);
		if ( inputState->guessing == 0 ) {
			i_AST = astFactory->create(i);
			astFactory->addASTChild(currentAST, i_AST);
		}
		match(IDENT);
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp80_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp80_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp80_AST);
		}
		match(DOT);
		val=name_path_star();
		if (inputState->guessing==0) {
			np_AST = returnAST;
			astFactory->addASTChild( currentAST, returnAST );
		}
		if ( inputState->guessing==0 ) {
			name_path_star_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 698 "modelica_parser.g"
			
						if(!(np_AST))
						{
							name_path_star_AST = i_AST;
						}
					
#line 2352 "modelica_parser.cpp"
			currentAST.root = name_path_star_AST;
			if ( name_path_star_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
				name_path_star_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
				  currentAST.child = name_path_star_AST->getFirstChild();
			else
				currentAST.child = name_path_star_AST;
			currentAST.advanceChildToEnd();
		}
		name_path_star_AST = currentAST.root;
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = name_path_star_AST;
	return val;
}

void modelica_parser::type_specifier() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST type_specifier_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	name_path();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	type_specifier_AST = currentAST.root;
	returnAST = type_specifier_AST;
}

void modelica_parser::component_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	component_declaration();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == COMMA)) {
			match(COMMA);
			component_declaration();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop70;
		}
		
	}
	_loop70:;
	} // ( ... )*
	component_list_AST = currentAST.root;
	returnAST = component_list_AST;
}

void modelica_parser::component_declaration() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_declaration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	declaration();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	component_declaration_AST = currentAST.root;
	returnAST = component_declaration_AST;
}

void modelica_parser::declaration() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST declaration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp82_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp82_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp82_AST);
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case ANNOTATION:
	case EXTENDS:
	case LPAR:
	case RPAR:
	case EQUALS:
	case ASSIGN:
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
	case EQUALS:
	case ASSIGN:
	{
		modification();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	declaration_AST = currentAST.root;
	returnAST = declaration_AST;
}

void modelica_parser::modification() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST modification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case LPAR:
	{
		class_modification();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		{
		switch ( LA(1)) {
		case EQUALS:
		{
			match(EQUALS);
			expression();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
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
		break;
	}
	case EQUALS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp84_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp84_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp84_AST);
		}
		match(EQUALS);
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case ASSIGN:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp85_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp85_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp85_AST);
		}
		match(ASSIGN);
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	modification_AST = currentAST.root;
	returnAST = modification_AST;
}

void modelica_parser::expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case IF:
	{
		if_expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case CODE:
	{
		code_expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	expression_AST = currentAST.root;
	returnAST = expression_AST;
}

void modelica_parser::argument_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST argument_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	argument();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == COMMA)) {
			match(COMMA);
			argument();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop82;
		}
		
	}
	_loop82:;
	} // ( ... )*
	if ( inputState->guessing==0 ) {
		argument_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 299 "modelica_parser.g"
		
					argument_list_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(ARGUMENT_LIST,"ARGUMENT_LIST"))->add(argument_list_AST)));
				
#line 2664 "modelica_parser.cpp"
		currentAST.root = argument_list_AST;
		if ( argument_list_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			argument_list_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = argument_list_AST->getFirstChild();
		else
			currentAST.child = argument_list_AST;
		currentAST.advanceChildToEnd();
	}
	argument_list_AST = currentAST.root;
	returnAST = argument_list_AST;
}

void modelica_parser::argument() {
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
			em_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			argument_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 306 "modelica_parser.g"
			
						argument_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(ELEMENT_MODIFICATION,"ELEMENT_MODIFICATION"))->add(em_AST))); 
					
#line 2700 "modelica_parser.cpp"
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
			er_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			argument_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 310 "modelica_parser.g"
			
						argument_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(ELEMENT_REDECLARATION,"ELEMENT_REDECLARATION"))->add(er_AST))); 		
#line 2722 "modelica_parser.cpp"
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

void modelica_parser::element_modification() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_modification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case EACH:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp87_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp87_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp87_AST);
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
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp88_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp88_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp88_AST);
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
		astFactory->addASTChild( currentAST, returnAST );
	}
	{
	switch ( LA(1)) {
	case LPAR:
	case EQUALS:
	case ASSIGN:
	{
		modification();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	string_comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	element_modification_AST = currentAST.root;
	returnAST = element_modification_AST;
}

void modelica_parser::element_redeclaration() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_redeclaration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp89_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp89_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp89_AST);
	}
	match(REDECLARE);
	{
	switch ( LA(1)) {
	case EACH:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp90_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp90_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp90_AST);
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
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp91_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp91_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp91_AST);
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
				astFactory->addASTChild( currentAST, returnAST );
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
				astFactory->addASTChild( currentAST, returnAST );
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
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp92_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp92_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp92_AST);
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
				astFactory->addASTChild( currentAST, returnAST );
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
				astFactory->addASTChild( currentAST, returnAST );
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
				astFactory->addASTChild( currentAST, returnAST );
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
	element_redeclaration_AST = currentAST.root;
	returnAST = element_redeclaration_AST;
}

void modelica_parser::component_clause1() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_clause1_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	type_prefix();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	type_specifier();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	component_declaration();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	component_clause1_AST = currentAST.root;
	returnAST = component_clause1_AST;
}

void modelica_parser::equation_annotation_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_annotation_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (((_tokenSet_7.member(LA(1))) && (_tokenSet_8.member(LA(2))))&&( LA(1) == END || LA(1) == EQUATION || LA(1) == ALGORITHM || LA(1)==INITIAL 
		 || LA(1) == PROTECTED || LA(1) == PUBLIC )) {
		equation_annotation_list_AST = currentAST.root;
	}
	else if ((_tokenSet_9.member(LA(1))) && (_tokenSet_10.member(LA(2)))) {
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
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
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
			astFactory->addASTChild( currentAST, returnAST );
		}
		equation_annotation_list_AST = currentAST.root;
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = equation_annotation_list_AST;
}

void modelica_parser::equation() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case IF:
	{
		conditional_equation_e();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case FOR:
	{
		for_clause_e();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case CONNECT:
	{
		connect_clause();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case WHEN:
	{
		when_clause_e();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	default:
		bool synPredMatched111 = false;
		if (((_tokenSet_11.member(LA(1))) && (_tokenSet_10.member(LA(2))))) {
			int _m111 = mark();
			synPredMatched111 = true;
			inputState->guessing++;
			try {
				{
				simple_expression();
				match(EQUALS);
				}
			}
			catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
				synPredMatched111 = false;
			}
			rewind(_m111);
			inputState->guessing--;
		}
		if ( synPredMatched111 ) {
			equality_equation();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else if ((LA(1) == IDENT) && (LA(2) == LPAR)) {
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp95_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp95_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, tmp95_AST);
			}
			match(IDENT);
			function_call();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	if ( inputState->guessing==0 ) {
		equation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 384 "modelica_parser.g"
		
		equation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(EQUATION_STATEMENT,"EQUATION_STATEMENT"))->add(equation_AST)));
		
#line 3234 "modelica_parser.cpp"
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
		astFactory->addASTChild( currentAST, returnAST );
	}
	equation_AST = currentAST.root;
	returnAST = equation_AST;
}

void modelica_parser::algorithm() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case IDENT:
	{
		assign_clause_a();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case LPAR:
	{
		multi_assign_clause_a();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case IF:
	{
		conditional_equation_a();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case FOR:
	{
		for_clause_a();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case WHILE:
	{
		while_clause();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case WHEN:
	{
		when_clause_a();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
		astFactory->addASTChild( currentAST, returnAST );
	}
	if ( inputState->guessing==0 ) {
		algorithm_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 399 "modelica_parser.g"
		
		algorithm_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(ALGORITHM_STATEMENT,"ALGORITHM_STATEMENT"))->add(algorithm_AST)));
		
#line 3322 "modelica_parser.cpp"
		currentAST.root = algorithm_AST;
		if ( algorithm_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			algorithm_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = algorithm_AST->getFirstChild();
		else
			currentAST.child = algorithm_AST;
		currentAST.advanceChildToEnd();
	}
	algorithm_AST = currentAST.root;
	returnAST = algorithm_AST;
}

void modelica_parser::simple_expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST simple_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST l1_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST l2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST l3_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	logical_expression();
	if (inputState->guessing==0) {
		l1_AST = returnAST;
	}
	{
	switch ( LA(1)) {
	case COLON:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp96_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp96_AST = astFactory->create(LT(1));
		}
		match(COLON);
		logical_expression();
		if (inputState->guessing==0) {
			l2_AST = returnAST;
		}
		{
		switch ( LA(1)) {
		case COLON:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp97_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp97_AST = astFactory->create(LT(1));
			}
			match(COLON);
			logical_expression();
			if (inputState->guessing==0) {
				l3_AST = returnAST;
			}
			break;
		}
		case ANNOTATION:
		case ELSE:
		case ELSEIF:
		case EXTENDS:
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
	case EXTENDS:
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
#line 540 "modelica_parser.g"
		
					if (l3_AST != null) 
					{ 
						simple_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(4))->add(astFactory->create(RANGE3,"RANGE3"))->add(l1_AST)->add(l2_AST)->add(l3_AST))); 
					}
					else if (l2_AST != null) 
					{ 
						simple_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(3))->add(astFactory->create(RANGE2,"RANGE2"))->add(l1_AST)->add(l2_AST))); 
					}
					else 
					{ 
						simple_expression_AST = l1_AST; 
					}
				
#line 3442 "modelica_parser.cpp"
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

void modelica_parser::equality_equation() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equality_equation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	simple_expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp98_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp98_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp98_AST);
	}
	match(EQUALS);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	equality_equation_AST = currentAST.root;
	returnAST = equality_equation_AST;
}

void modelica_parser::conditional_equation_e() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST conditional_equation_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp99_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp99_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp99_AST);
	}
	match(IF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(THEN);
	equation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == ELSEIF)) {
			equation_elseif();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop120;
		}
		
	}
	_loop120:;
	} // ( ... )*
	{
	switch ( LA(1)) {
	case ELSE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp101_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp101_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp101_AST);
		}
		match(ELSE);
		equation_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	match(END);
	match(IF);
	conditional_equation_e_AST = currentAST.root;
	returnAST = conditional_equation_e_AST;
}

void modelica_parser::for_clause_e() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_clause_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp104_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp104_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp104_AST);
	}
	match(FOR);
	for_indices();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(LOOP);
	equation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(END);
	match(FOR);
	for_clause_e_AST = currentAST.root;
	returnAST = for_clause_e_AST;
}

void modelica_parser::connect_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST connect_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp108_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp108_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp108_AST);
	}
	match(CONNECT);
	match(LPAR);
	connector_ref();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(COMMA);
	connector_ref();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(RPAR);
	connect_clause_AST = currentAST.root;
	returnAST = connect_clause_AST;
}

void modelica_parser::when_clause_e() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST when_clause_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp112_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp112_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp112_AST);
	}
	match(WHEN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(THEN);
	equation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == ELSEWHEN)) {
			else_when_e();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop131;
		}
		
	}
	_loop131:;
	} // ( ... )*
	match(END);
	match(WHEN);
	when_clause_e_AST = currentAST.root;
	returnAST = when_clause_e_AST;
}

void modelica_parser::function_call() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	match(LPAR);
	{
	function_arguments();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	}
	match(RPAR);
	if ( inputState->guessing==0 ) {
		function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 712 "modelica_parser.g"
		
					function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(FUNCTION_ARGUMENTS,"FUNCTION_ARGUMENTS"))->add(function_call_AST)));
				
#line 3656 "modelica_parser.cpp"
		currentAST.root = function_call_AST;
		if ( function_call_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			function_call_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = function_call_AST->getFirstChild();
		else
			currentAST.child = function_call_AST;
		currentAST.advanceChildToEnd();
	}
	function_call_AST = currentAST.root;
	returnAST = function_call_AST;
}

void modelica_parser::assign_clause_a() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST assign_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	component_reference();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{
	switch ( LA(1)) {
	case ASSIGN:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp118_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp118_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp118_AST);
		}
		match(ASSIGN);
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case LPAR:
	{
		function_call();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	assign_clause_a_AST = currentAST.root;
	returnAST = assign_clause_a_AST;
}

void modelica_parser::multi_assign_clause_a() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST multi_assign_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	match(LPAR);
	expression_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(RPAR);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp121_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp121_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp121_AST);
	}
	match(ASSIGN);
	component_reference();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	function_call();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	multi_assign_clause_a_AST = currentAST.root;
	returnAST = multi_assign_clause_a_AST;
}

void modelica_parser::conditional_equation_a() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST conditional_equation_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp122_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp122_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp122_AST);
	}
	match(IF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(THEN);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == ELSEIF)) {
			algorithm_elseif();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop124;
		}
		
	}
	_loop124:;
	} // ( ... )*
	{
	switch ( LA(1)) {
	case ELSE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp124_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp124_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp124_AST);
		}
		match(ELSE);
		algorithm_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	match(END);
	match(IF);
	conditional_equation_a_AST = currentAST.root;
	returnAST = conditional_equation_a_AST;
}

void modelica_parser::for_clause_a() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp127_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp127_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp127_AST);
	}
	match(FOR);
	for_indices();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(LOOP);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(END);
	match(FOR);
	for_clause_a_AST = currentAST.root;
	returnAST = for_clause_a_AST;
}

void modelica_parser::while_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST while_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp131_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp131_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp131_AST);
	}
	match(WHILE);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(LOOP);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(END);
	match(WHILE);
	while_clause_AST = currentAST.root;
	returnAST = while_clause_AST;
}

void modelica_parser::when_clause_a() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST when_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp135_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp135_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp135_AST);
	}
	match(WHEN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(THEN);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == ELSEWHEN)) {
			else_when_a();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop135;
		}
		
	}
	_loop135:;
	} // ( ... )*
	match(END);
	match(WHEN);
	when_clause_a_AST = currentAST.root;
	returnAST = when_clause_a_AST;
}

void modelica_parser::equation_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if ((((LA(1) >= ELSE && LA(1) <= END)) && (_tokenSet_12.member(LA(2))))&&(LA(1) != END || (LA(1) == END && LA(2) != IDENT))) {
		equation_list_AST = currentAST.root;
	}
	else if ((_tokenSet_13.member(LA(1))) && (_tokenSet_10.member(LA(2)))) {
		{
		equation();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		match(SEMICOLON);
		equation_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		}
		equation_list_AST = currentAST.root;
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = equation_list_AST;
}

void modelica_parser::equation_elseif() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_elseif_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp140_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp140_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp140_AST);
	}
	match(ELSEIF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(THEN);
	equation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	equation_elseif_AST = currentAST.root;
	returnAST = equation_elseif_AST;
}

void modelica_parser::algorithm_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_14.member(LA(1)))) {
			algorithm();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
		}
		else {
			goto _loop143;
		}
		
	}
	_loop143:;
	} // ( ... )*
	algorithm_list_AST = currentAST.root;
	returnAST = algorithm_list_AST;
}

void modelica_parser::algorithm_elseif() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_elseif_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp143_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp143_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp143_AST);
	}
	match(ELSEIF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(THEN);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	algorithm_elseif_AST = currentAST.root;
	returnAST = algorithm_elseif_AST;
}

void modelica_parser::for_indices() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_indices_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	for_index();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	for_indices2();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	for_indices_AST = currentAST.root;
	returnAST = for_indices_AST;
}

void modelica_parser::else_when_e() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST else_when_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp145_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp145_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp145_AST);
	}
	match(ELSEWHEN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(THEN);
	equation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	else_when_e_AST = currentAST.root;
	returnAST = else_when_e_AST;
}

void modelica_parser::else_when_a() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST else_when_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp147_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp147_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp147_AST);
	}
	match(ELSEWHEN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(THEN);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	else_when_a_AST = currentAST.root;
	returnAST = else_when_a_AST;
}

void modelica_parser::connector_ref() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST connector_ref_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp149_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp149_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp149_AST);
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp150_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp150_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp150_AST);
		}
		match(DOT);
		connector_ref_2();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	connector_ref_AST = currentAST.root;
	returnAST = connector_ref_AST;
}

void modelica_parser::connector_ref_2() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST connector_ref_2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp151_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp151_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp151_AST);
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	connector_ref_2_AST = currentAST.root;
	returnAST = connector_ref_2_AST;
}

void modelica_parser::if_expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST if_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp152_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp152_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp152_AST);
	}
	match(IF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(THEN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == ELSEIF)) {
			elseif_expression();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop154;
		}
		
	}
	_loop154:;
	} // ( ... )*
	match(ELSE);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	if_expression_AST = currentAST.root;
	returnAST = if_expression_AST;
}

void modelica_parser::code_expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST code_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST m_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST el_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST eq_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ieq_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST alg_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ialg_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp155_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp155_AST = astFactory->create(LT(1));
	}
	match(CODE);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp156_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp156_AST = astFactory->create(LT(1));
	}
	match(LPAR);
	{
	switch ( LA(1)) {
	case EQUATION:
	{
		code_equation_clause();
		if (inputState->guessing==0) {
			eq_AST = returnAST;
		}
		break;
	}
	case ALGORITHM:
	{
		code_algorithm_clause();
		if (inputState->guessing==0) {
			alg_AST = returnAST;
		}
		break;
	}
	default:
		bool synPredMatched168 = false;
		if (((_tokenSet_15.member(LA(1))) && (_tokenSet_16.member(LA(2))))) {
			int _m168 = mark();
			synPredMatched168 = true;
			inputState->guessing++;
			try {
				{
				expression();
				match(RPAR);
				}
			}
			catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
				synPredMatched168 = false;
			}
			rewind(_m168);
			inputState->guessing--;
		}
		if ( synPredMatched168 ) {
			expression();
			if (inputState->guessing==0) {
				e_AST = returnAST;
			}
		}
		else if ((LA(1) == LPAR || LA(1) == EQUALS || LA(1) == ASSIGN) && (_tokenSet_17.member(LA(2)))) {
			modification();
			if (inputState->guessing==0) {
				m_AST = returnAST;
			}
		}
		else if ((_tokenSet_18.member(LA(1))) && (_tokenSet_19.member(LA(2)))) {
			element();
			if (inputState->guessing==0) {
				el_AST = returnAST;
			}
		}
		else if ((LA(1) == INITIAL) && (LA(2) == EQUATION)) {
			code_initial_equation_clause();
			if (inputState->guessing==0) {
				ieq_AST = returnAST;
			}
		}
		else if ((LA(1) == INITIAL) && (LA(2) == ALGORITHM)) {
			code_initial_algorithm_clause();
			if (inputState->guessing==0) {
				ialg_AST = returnAST;
			}
		}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp157_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp157_AST = astFactory->create(LT(1));
	}
	match(RPAR);
	if ( inputState->guessing==0 ) {
		code_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 561 "modelica_parser.g"
		
					if (e_AST) {
						code_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(CODE_EXPRESSION,"CODE_EXPRESSION"))->add(e_AST)));
					} else if (m_AST) {
						code_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(CODE_MODIFICATION,"CODE_MODIFICATION"))->add(m_AST)));
					} else if (el_AST) {
						code_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(CODE_ELEMENT,"CODE_ELEMENT"))->add(el_AST)));
					} else if (eq_AST) {
						code_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(CODE_EQUATION,"CODE_EQUATION"))->add(eq_AST)));
					} else if (ieq_AST) {				
						code_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(CODE_INITIALEQUATION,"CODE_EQUATION"))->add(ieq_AST)));
					} else if (alg_AST) {
						code_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(CODE_ALGORITHM,"CODE_ALGORITHM"))->add(alg_AST)));
					} else if (ialg_AST) {				
						code_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(CODE_INITIALALGORITHM,"CODE_ALGORITHM"))->add(ialg_AST)));
					}
				
#line 4330 "modelica_parser.cpp"
		currentAST.root = code_expression_AST;
		if ( code_expression_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			code_expression_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = code_expression_AST->getFirstChild();
		else
			currentAST.child = code_expression_AST;
		currentAST.advanceChildToEnd();
	}
	returnAST = code_expression_AST;
}

void modelica_parser::elseif_expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST elseif_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp158_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp158_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp158_AST);
	}
	match(ELSEIF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	match(THEN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	elseif_expression_AST = currentAST.root;
	returnAST = elseif_expression_AST;
}

void modelica_parser::for_index() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_index_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp160_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp160_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, tmp160_AST);
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case IN:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp161_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp161_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp161_AST);
		}
		match(IN);
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	for_index_AST = currentAST.root;
	returnAST = for_index_AST;
}

void modelica_parser::for_indices2() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_indices2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (((LA(1) == LOOP || LA(1) == RPAR || LA(1) == IDENT))&&(LA(2) != IN)) {
		for_indices2_AST = currentAST.root;
	}
	else if ((LA(1) == COMMA)) {
		{
		match(COMMA);
		for_index();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		}
		for_indices2();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		for_indices2_AST = currentAST.root;
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = for_indices2_AST;
}

void modelica_parser::logical_expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	logical_term();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == OR)) {
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp163_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp163_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, tmp163_AST);
			}
			match(OR);
			logical_term();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop182;
		}
		
	}
	_loop182:;
	} // ( ... )*
	logical_expression_AST = currentAST.root;
	returnAST = logical_expression_AST;
}

void modelica_parser::code_equation_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST code_equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp164_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp164_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp164_AST);
	}
	match(EQUATION);
	{ // ( ... )*
	for (;;) {
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
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
			break;
		}
		default:
		{
			goto _loop172;
		}
		}
	}
	_loop172:;
	} // ( ... )*
	}
	code_equation_clause_AST = currentAST.root;
	returnAST = code_equation_clause_AST;
}

void modelica_parser::code_initial_equation_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST code_initial_equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ec_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (!( LA(2)==EQUATION))
		throw ANTLR_USE_NAMESPACE(antlr)SemanticException(" LA(2)==EQUATION");
	match(INITIAL);
	code_equation_clause();
	if (inputState->guessing==0) {
		ec_AST = returnAST;
		astFactory->addASTChild( currentAST, returnAST );
	}
	if ( inputState->guessing==0 ) {
		code_initial_equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 587 "modelica_parser.g"
		
		code_initial_equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(INITIAL_EQUATION,"INTIAL_EQUATION"))->add(ec_AST)));
		
#line 4558 "modelica_parser.cpp"
		currentAST.root = code_initial_equation_clause_AST;
		if ( code_initial_equation_clause_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			code_initial_equation_clause_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = code_initial_equation_clause_AST->getFirstChild();
		else
			currentAST.child = code_initial_equation_clause_AST;
		currentAST.advanceChildToEnd();
	}
	code_initial_equation_clause_AST = currentAST.root;
	returnAST = code_initial_equation_clause_AST;
}

void modelica_parser::code_algorithm_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST code_algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp168_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp168_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp168_AST);
	}
	match(ALGORITHM);
	{ // ( ... )*
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
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
			break;
		}
		default:
		{
			goto _loop176;
		}
		}
	}
	_loop176:;
	} // ( ... )*
	code_algorithm_clause_AST = currentAST.root;
	returnAST = code_algorithm_clause_AST;
}

void modelica_parser::code_initial_algorithm_clause() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST code_initial_algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (!( LA(2) == ALGORITHM ))
		throw ANTLR_USE_NAMESPACE(antlr)SemanticException(" LA(2) == ALGORITHM ");
	match(INITIAL);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp172_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp172_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp172_AST);
	}
	match(ALGORITHM);
	{ // ( ... )*
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
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
			match(SEMICOLON);
			break;
		}
		default:
		{
			goto _loop179;
		}
		}
	}
	_loop179:;
	} // ( ... )*
	if ( inputState->guessing==0 ) {
		code_initial_algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 601 "modelica_parser.g"
		
					code_initial_algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(INITIAL_ALGORITHM,"INTIAL_ALGORITHM"))->add(code_initial_algorithm_clause_AST)));
				
#line 4674 "modelica_parser.cpp"
		currentAST.root = code_initial_algorithm_clause_AST;
		if ( code_initial_algorithm_clause_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			code_initial_algorithm_clause_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = code_initial_algorithm_clause_AST->getFirstChild();
		else
			currentAST.child = code_initial_algorithm_clause_AST;
		currentAST.advanceChildToEnd();
	}
	code_initial_algorithm_clause_AST = currentAST.root;
	returnAST = code_initial_algorithm_clause_AST;
}

void modelica_parser::logical_term() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_term_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	logical_factor();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == AND)) {
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp175_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp175_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, tmp175_AST);
			}
			match(AND);
			logical_factor();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop185;
		}
		
	}
	_loop185:;
	} // ( ... )*
	logical_term_AST = currentAST.root;
	returnAST = logical_term_AST;
}

void modelica_parser::logical_factor() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_factor_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case NOT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp176_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp176_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp176_AST);
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
		astFactory->addASTChild( currentAST, returnAST );
	}
	logical_factor_AST = currentAST.root;
	returnAST = logical_factor_AST;
}

void modelica_parser::relation() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST relation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	arithmetic_expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
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
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp177_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp177_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, tmp177_AST);
			}
			match(LESS);
			break;
		}
		case LESSEQ:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp178_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp178_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, tmp178_AST);
			}
			match(LESSEQ);
			break;
		}
		case GREATER:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp179_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp179_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, tmp179_AST);
			}
			match(GREATER);
			break;
		}
		case GREATEREQ:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp180_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp180_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, tmp180_AST);
			}
			match(GREATEREQ);
			break;
		}
		case EQEQ:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp181_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp181_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, tmp181_AST);
			}
			match(EQEQ);
			break;
		}
		case LESSGT:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp182_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp182_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, tmp182_AST);
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
			astFactory->addASTChild( currentAST, returnAST );
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
	relation_AST = currentAST.root;
	returnAST = relation_AST;
}

void modelica_parser::arithmetic_expression() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	unary_arithmetic_expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == PLUS || LA(1) == MINUS)) {
			{
			switch ( LA(1)) {
			case PLUS:
			{
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp183_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				if ( inputState->guessing == 0 ) {
					tmp183_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, tmp183_AST);
				}
				match(PLUS);
				break;
			}
			case MINUS:
			{
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp184_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				if ( inputState->guessing == 0 ) {
					tmp184_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, tmp184_AST);
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
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop196;
		}
		
	}
	_loop196:;
	} // ( ... )*
	arithmetic_expression_AST = currentAST.root;
	returnAST = arithmetic_expression_AST;
}

void modelica_parser::rel_op() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST rel_op_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case LESS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp185_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp185_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp185_AST);
		}
		match(LESS);
		break;
	}
	case LESSEQ:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp186_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp186_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp186_AST);
		}
		match(LESSEQ);
		break;
	}
	case GREATER:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp187_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp187_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp187_AST);
		}
		match(GREATER);
		break;
	}
	case GREATEREQ:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp188_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp188_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp188_AST);
		}
		match(GREATEREQ);
		break;
	}
	case EQEQ:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp189_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp189_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp189_AST);
		}
		match(EQEQ);
		break;
	}
	case LESSGT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp190_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp190_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp190_AST);
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
	rel_op_AST = currentAST.root;
	returnAST = rel_op_AST;
}

void modelica_parser::unary_arithmetic_expression() {
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
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp191_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp191_AST = astFactory->create(LT(1));
		}
		match(PLUS);
		term();
		if (inputState->guessing==0) {
			t1_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 635 "modelica_parser.g"
			
						unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(UNARY_PLUS,"PLUS"))->add(t1_AST))); 
					
#line 5051 "modelica_parser.cpp"
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
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp192_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp192_AST = astFactory->create(LT(1));
		}
		match(MINUS);
		term();
		if (inputState->guessing==0) {
			t2_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 639 "modelica_parser.g"
			
						unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(UNARY_MINUS,"MINUS"))->add(t2_AST))); 
					
#line 5079 "modelica_parser.cpp"
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
			t3_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 643 "modelica_parser.g"
			
						unary_arithmetic_expression_AST = t3_AST; 
					
#line 5112 "modelica_parser.cpp"
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

void modelica_parser::term() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST term_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	factor();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == STAR || LA(1) == SLASH)) {
			{
			switch ( LA(1)) {
			case STAR:
			{
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp193_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				if ( inputState->guessing == 0 ) {
					tmp193_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, tmp193_AST);
				}
				match(STAR);
				break;
			}
			case SLASH:
			{
				ANTLR_USE_NAMESPACE(antlr)RefAST tmp194_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
				if ( inputState->guessing == 0 ) {
					tmp194_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, tmp194_AST);
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
				astFactory->addASTChild( currentAST, returnAST );
			}
		}
		else {
			goto _loop202;
		}
		
	}
	_loop202:;
	} // ( ... )*
	term_AST = currentAST.root;
	returnAST = term_AST;
}

void modelica_parser::factor() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST factor_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	primary();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{
	switch ( LA(1)) {
	case POWER:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp195_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp195_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp195_AST);
		}
		match(POWER);
		primary();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	factor_AST = currentAST.root;
	returnAST = factor_AST;
}

void modelica_parser::primary() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST primary_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	switch ( LA(1)) {
	case UNSIGNED_INTEGER:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp196_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp196_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp196_AST);
		}
		match(UNSIGNED_INTEGER);
		break;
	}
	case UNSIGNED_REAL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp197_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp197_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp197_AST);
		}
		match(UNSIGNED_REAL);
		break;
	}
	case STRING:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp198_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp198_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp198_AST);
		}
		match(STRING);
		break;
	}
	case FALSE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp199_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp199_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp199_AST);
		}
		match(FALSE);
		break;
	}
	case TRUE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp200_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp200_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp200_AST);
		}
		match(TRUE);
		break;
	}
	case INITIAL:
	case IDENT:
	{
		component_reference__function_call();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		break;
	}
	case LPAR:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp201_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp201_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp201_AST);
		}
		match(LPAR);
		expression_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		match(RPAR);
		break;
	}
	case LBRACK:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp203_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp203_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp203_AST);
		}
		match(LBRACK);
		expression_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		{ // ( ... )*
		for (;;) {
			if ((LA(1) == SEMICOLON)) {
				match(SEMICOLON);
				expression_list();
				if (inputState->guessing==0) {
					astFactory->addASTChild( currentAST, returnAST );
				}
			}
			else {
				goto _loop208;
			}
			
		}
		_loop208:;
		} // ( ... )*
		match(RBRACK);
		break;
	}
	case LBRACE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp206_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp206_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, tmp206_AST);
		}
		match(LBRACE);
		expression_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		match(RBRACE);
		break;
	}
	case END:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp208_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp208_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp208_AST);
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
	primary_AST = currentAST.root;
	returnAST = primary_AST;
}

void modelica_parser::component_reference__function_call() {
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
			cr_AST = returnAST;
		}
		{
		switch ( LA(1)) {
		case LPAR:
		{
			function_call();
			if (inputState->guessing==0) {
				fc_AST = returnAST;
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
#line 673 "modelica_parser.g"
			
						if (fc_AST != null) 
						{ 
							component_reference__function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(3))->add(astFactory->create(FUNCTION_CALL,"FUNCTION_CALL"))->add(cr_AST)->add(fc_AST)));
						} 
						else 
						{ 
							component_reference__function_call_AST = cr_AST;
						} 
					
#line 5478 "modelica_parser.cpp"
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
		if ( inputState->guessing == 0 ) {
			i_AST = astFactory->create(i);
		}
		match(INITIAL);
		match(LPAR);
		match(RPAR);
		if ( inputState->guessing==0 ) {
			component_reference__function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 683 "modelica_parser.g"
			
						component_reference__function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(INITIAL_FUNCTION_CALL,"INITIAL_FUNCTION_CALL"))->add(i_AST)));
					
#line 5504 "modelica_parser.cpp"
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

void modelica_parser::function_arguments() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST function_arguments_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	for_or_expression_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	}
	{
	switch ( LA(1)) {
	case IDENT:
	{
		named_arguments();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	function_arguments_AST = currentAST.root;
	returnAST = function_arguments_AST;
}

void modelica_parser::for_or_expression_list() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_or_expression_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if (((LA(1) == RPAR || LA(1) == IDENT) && (_tokenSet_20.member(LA(2))))&&(LA(1)==IDENT && LA(2) == EQUALS|| LA(1) == RPAR)) {
	}
	else if ((_tokenSet_15.member(LA(1))) && (_tokenSet_21.member(LA(2)))) {
		{
		expression();
		if (inputState->guessing==0) {
			e_AST = returnAST;
			astFactory->addASTChild( currentAST, returnAST );
		}
		{
		switch ( LA(1)) {
		case COMMA:
		{
			match(COMMA);
			for_or_expression_list2();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
			}
			break;
		}
		case FOR:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp212_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			if ( inputState->guessing == 0 ) {
				tmp212_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, tmp212_AST);
			}
			match(FOR);
			for_indices();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
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
#line 733 "modelica_parser.g"
			
							for_or_expression_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(EXPRESSION_LIST,"EXPRESSION_LIST"))->add(for_or_expression_list_AST)));
						
#line 5617 "modelica_parser.cpp"
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
	for_or_expression_list_AST = currentAST.root;
	returnAST = for_or_expression_list_AST;
}

void modelica_parser::named_arguments() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST named_arguments_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	named_arguments2();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	if ( inputState->guessing==0 ) {
		named_arguments_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
#line 748 "modelica_parser.g"
		
					named_arguments_AST=ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(astFactory->create(NAMED_ARGUMENTS,"NAMED_ARGUMENTS"))->add(named_arguments_AST)));
				
#line 5651 "modelica_parser.cpp"
		currentAST.root = named_arguments_AST;
		if ( named_arguments_AST!=ANTLR_USE_NAMESPACE(antlr)nullAST &&
			named_arguments_AST->getFirstChild() != ANTLR_USE_NAMESPACE(antlr)nullAST )
			  currentAST.child = named_arguments_AST->getFirstChild();
		else
			currentAST.child = named_arguments_AST;
		currentAST.advanceChildToEnd();
	}
	named_arguments_AST = currentAST.root;
	returnAST = named_arguments_AST;
}

void modelica_parser::for_or_expression_list2() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_or_expression_list2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (((LA(1) == RPAR || LA(1) == IDENT) && (_tokenSet_20.member(LA(2))))&&(LA(2) == EQUALS)) {
		for_or_expression_list2_AST = currentAST.root;
	}
	else if ((_tokenSet_15.member(LA(1))) && (_tokenSet_22.member(LA(2)))) {
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
		}
		{
		switch ( LA(1)) {
		case COMMA:
		{
			match(COMMA);
			for_or_expression_list2();
			if (inputState->guessing==0) {
				astFactory->addASTChild( currentAST, returnAST );
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
		for_or_expression_list2_AST = currentAST.root;
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = for_or_expression_list2_AST;
}

void modelica_parser::named_arguments2() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST named_arguments2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	named_argument();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{
	switch ( LA(1)) {
	case COMMA:
	{
		match(COMMA);
		named_arguments2();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	named_arguments2_AST = currentAST.root;
	returnAST = named_arguments2_AST;
}

void modelica_parser::named_argument() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST named_argument_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp215_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp215_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, tmp215_AST);
	}
	match(IDENT);
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp216_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	if ( inputState->guessing == 0 ) {
		tmp216_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, tmp216_AST);
	}
	match(EQUALS);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	named_argument_AST = currentAST.root;
	returnAST = named_argument_AST;
}

void modelica_parser::expression_list2() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_list2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild( currentAST, returnAST );
	}
	{
	switch ( LA(1)) {
	case COMMA:
	{
		match(COMMA);
		expression_list2();
		if (inputState->guessing==0) {
			astFactory->addASTChild( currentAST, returnAST );
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
	expression_list2_AST = currentAST.root;
	returnAST = expression_list2_AST;
}

void modelica_parser::subscript() {
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST subscript_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	switch ( LA(1)) {
	case CODE:
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
			astFactory->addASTChild( currentAST, returnAST );
		}
		subscript_AST = currentAST.root;
		break;
	}
	case COLON:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp218_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		if ( inputState->guessing == 0 ) {
			tmp218_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, tmp218_AST);
		}
		match(COLON);
		subscript_AST = currentAST.root;
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	returnAST = subscript_AST;
}

void modelica_parser::initializeASTFactory( ANTLR_USE_NAMESPACE(antlr)ASTFactory& factory )
{
	factory.setMaxNodeType(130);
}
const char* modelica_parser::tokenNames[] = {
	"<0>",
	"EOF",
	"<2>",
	"NULL_TREE_LOOKAHEAD",
	"\"algorithm\"",
	"\"and\"",
	"\"annotation\"",
	"\"block\"",
	"\"boundary\"",
	"\"Code\"",
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
	"\"overload\"",
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
	"CODE_EXPRESSION",
	"CODE_MODIFICATION",
	"CODE_ELEMENT",
	"CODE_EQUATION",
	"CODE_INITIALEQUATION",
	"CODE_ALGORITHM",
	"CODE_INITIALALGORITHM",
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

const unsigned long modelica_parser::_tokenSet_0_data_[] = { 608179328UL, 4270112UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "encapsulated" "final" "function" "model" 
// "package" "partial" "record" "type" 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_0(_tokenSet_0_data_,6);
const unsigned long modelica_parser::_tokenSet_1_data_[] = { 8388672UL, 939524096UL, 138477824UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "extends" LPAR RPAR LBRACK COMMA SEMICOLON IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_1(_tokenSet_1_data_,8);
const unsigned long modelica_parser::_tokenSet_2_data_[] = { 2917692624UL, 4586798UL, 138412032UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "annotation" "block" "class" "connector" "constant" "discrete" 
// "end" "equation" "encapsulated" "extends" "external" "final" "flow" 
// "function" "import" "initial" "inner" "input" "model" "outer" "output" 
// "package" "parameter" "partial" "protected" "public" "record" "replaceable" 
// "type" IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_2(_tokenSet_2_data_,8);
const unsigned long modelica_parser::_tokenSet_3_data_[] = { 134242304UL, 5128UL, 4194304UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "constant" "discrete" "flow" "input" "output" "parameter" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_3(_tokenSet_3_data_,8);
const unsigned long modelica_parser::_tokenSet_4_data_[] = { 2898293952UL, 4537644UL, 4194304UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "block" "class" "connector" "constant" "discrete" "encapsulated" 
// "extends" "final" "flow" "function" "import" "inner" "input" "model" 
// "outer" "output" "package" "parameter" "partial" "record" "replaceable" 
// "type" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_4(_tokenSet_4_data_,8);
const unsigned long modelica_parser::_tokenSet_5_data_[] = { 64UL, 268435456UL, 134283392UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" RPAR DOT SEMICOLON STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_5(_tokenSet_5_data_,8);
const unsigned long modelica_parser::_tokenSet_6_data_[] = { 64UL, 268435456UL, 134283264UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" RPAR SEMICOLON STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_6(_tokenSet_6_data_,8);
const unsigned long modelica_parser::_tokenSet_7_data_[] = { 19398672UL, 49154UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "end" "equation" "external" "initial" "protected" "public" 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_7(_tokenSet_7_data_,6);
const unsigned long modelica_parser::_tokenSet_8_data_[] = { 4293426384UL, 2883976558UL, 205586456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "annotation" "block" "class" "connect" "connector" "constant" 
// "discrete" "end" "equation" "encapsulated" "extends" "external" "false" 
// "final" "flow" "for" "function" "if" "import" "initial" "inner" "input" 
// "model" "not" "outer" "output" "package" "parameter" "partial" "protected" 
// "public" "record" "replaceable" "true" "type" "unsigned_real" "when" 
// "while" LPAR LBRACK LBRACE PLUS MINUS SEMICOLON IDENT UNSIGNED_INTEGER 
// STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_8(_tokenSet_8_data_,8);
const unsigned long modelica_parser::_tokenSet_9_data_[] = { 1376258112UL, 2845835330UL, 205520920UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "connect" "end" "false" "for" "if" "initial" "not" "true" 
// "unsigned_real" "when" LPAR LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER 
// STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_9(_tokenSet_9_data_,8);
const unsigned long modelica_parser::_tokenSet_10_data_[] = { 1107821088UL, 2829058626UL, 205717242UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real" 
// LPAR LBRACK LBRACE EQUALS PLUS MINUS STAR SLASH DOT LESS LESSEQ GREATER 
// GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_10(_tokenSet_10_data_,8);
const unsigned long modelica_parser::_tokenSet_11_data_[] = { 34078720UL, 2829058114UL, 205520920UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "end" "false" "initial" "not" "true" "unsigned_real" LPAR LBRACK LBRACE 
// PLUS MINUS IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_11(_tokenSet_11_data_,8);
const unsigned long modelica_parser::_tokenSet_12_data_[] = { 1376258560UL, 2845835330UL, 205520920UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "Code" "connect" "end" "false" "for" "if" "initial" "not" "true" "unsigned_real" 
// "when" LPAR LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_12(_tokenSet_12_data_,8);
const unsigned long modelica_parser::_tokenSet_13_data_[] = { 1376258048UL, 2845835330UL, 205520920UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "connect" "end" "false" "for" "if" "initial" "not" "true" "unsigned_real" 
// "when" LPAR LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_13(_tokenSet_13_data_,8);
const unsigned long modelica_parser::_tokenSet_14_data_[] = { 1342177280UL, 184549376UL, 4194304UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "for" "if" "when" "while" LPAR IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_14(_tokenSet_14_data_,8);
const unsigned long modelica_parser::_tokenSet_15_data_[] = { 1107821056UL, 2829058114UL, 205520920UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "Code" "end" "false" "if" "initial" "not" "true" "unsigned_real" LPAR 
// LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_15(_tokenSet_15_data_,8);
const unsigned long modelica_parser::_tokenSet_16_data_[] = { 1107821088UL, 3097494082UL, 205717240UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real" 
// LPAR RPAR LBRACK LBRACE PLUS MINUS STAR SLASH DOT LESS LESSEQ GREATER 
// GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_16(_tokenSet_16_data_,8);
const unsigned long modelica_parser::_tokenSet_17_data_[] = { 1174962688UL, 3097624642UL, 205520920UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "Code" "each" "end" "false" "final" "if" "initial" "not" "redeclare" 
// "true" "unsigned_real" LPAR RPAR LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER 
// STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_17(_tokenSet_17_data_,8);
const unsigned long modelica_parser::_tokenSet_18_data_[] = { 2898293888UL, 4537644UL, 4194304UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "constant" "discrete" "encapsulated" "extends" 
// "final" "flow" "function" "import" "inner" "input" "model" "outer" "output" 
// "package" "parameter" "partial" "record" "replaceable" "type" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_18(_tokenSet_18_data_,8);
const unsigned long modelica_parser::_tokenSet_19_data_[] = { 675312768UL, 541408556UL, 4194464UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "constant" "discrete" "encapsulated" "flow" 
// "function" "inner" "input" "model" "outer" "output" "package" "parameter" 
// "partial" "record" "replaceable" "type" LBRACK STAR DOT IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_19(_tokenSet_19_data_,8);
const unsigned long modelica_parser::_tokenSet_20_data_[] = { 277020768UL, 1343226384UL, 138674043UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "annotation" "else" "elseif" "extends" "for" "loop" "or" "then" 
// RPAR RBRACK RBRACE EQUALS PLUS MINUS STAR SLASH COMMA LESS LESSEQ GREATER 
// GREATEREQ EQEQ LESSGT COLON SEMICOLON POWER IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_20(_tokenSet_20_data_,8);
const unsigned long modelica_parser::_tokenSet_21_data_[] = { 1376256544UL, 3097494082UL, 205717496UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "end" "false" "for" "if" "initial" "not" "or" "true" "unsigned_real" 
// LPAR RPAR LBRACK LBRACE PLUS MINUS STAR SLASH DOT COMMA LESS LESSEQ 
// GREATER GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_21(_tokenSet_21_data_,8);
const unsigned long modelica_parser::_tokenSet_22_data_[] = { 1107821088UL, 3097494082UL, 205717496UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real" 
// LPAR RPAR LBRACK LBRACE PLUS MINUS STAR SLASH DOT COMMA LESS LESSEQ 
// GREATER GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_22(_tokenSet_22_data_,8);



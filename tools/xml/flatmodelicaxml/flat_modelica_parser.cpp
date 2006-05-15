/* $ANTLR 2.7.5rc2 (20050108): "flat_modelica_parser.g" -> "flat_modelica_parser.cpp"$ */
#include "flat_modelica_parser.hpp"
#include <antlr/NoViableAltException.hpp>
#include <antlr/SemanticException.hpp>
#include <antlr/ASTFactory.hpp>
#line 1 "flat_modelica_parser.g"
#line 8 "flat_modelica_parser.cpp"
flat_modelica_parser::flat_modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenBuffer& tokenBuf, int k)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(tokenBuf,k)
{
}

flat_modelica_parser::flat_modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenBuffer& tokenBuf)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(tokenBuf,2)
{
}

flat_modelica_parser::flat_modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenStream& lexer, int k)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(lexer,k)
{
}

flat_modelica_parser::flat_modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenStream& lexer)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(lexer,2)
{
}

flat_modelica_parser::flat_modelica_parser(const ANTLR_USE_NAMESPACE(antlr)ParserSharedInputState& state)
: ANTLR_USE_NAMESPACE(antlr)LLkParser(state,2)
{
}

void flat_modelica_parser::stored_definition() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST stored_definition_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	class_definition();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		stored_definition_AST = RefMyAST(currentAST.root);
#line 79 "flat_modelica_parser.g"
		
		stored_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(STORED_DEFINITION,"STORED_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(stored_definition_AST))));
		
#line 49 "flat_modelica_parser.cpp"
		currentAST.root = stored_definition_AST;
		if ( stored_definition_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			stored_definition_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = stored_definition_AST->getFirstChild();
		else
			currentAST.child = stored_definition_AST;
		currentAST.advanceChildToEnd();
	}
	stored_definition_AST = RefMyAST(currentAST.root);
	returnAST = stored_definition_AST;
}

void flat_modelica_parser::class_definition() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_definition_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	class_type();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	RefMyAST tmp1_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp1_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp1_AST));
	}
	match(IDENT);
	class_specifier();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		class_definition_AST = RefMyAST(currentAST.root);
#line 94 "flat_modelica_parser.g"
		
					class_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CLASS_DEFINITION,"CLASS_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(class_definition_AST)))); 
				
#line 87 "flat_modelica_parser.cpp"
		currentAST.root = class_definition_AST;
		if ( class_definition_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			class_definition_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = class_definition_AST->getFirstChild();
		else
			currentAST.child = class_definition_AST;
		currentAST.advanceChildToEnd();
	}
	class_definition_AST = RefMyAST(currentAST.root);
	returnAST = class_definition_AST;
}

void flat_modelica_parser::class_type() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_type_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp2_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp2_AST));
	}
	match(MODEL);
	class_type_AST = RefMyAST(currentAST.root);
	returnAST = class_type_AST;
}

void flat_modelica_parser::class_specifier() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_specifier_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if ((_tokenSet_0.member(LA(1)))) {
		string_comment();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		composition();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		match(END);
		name_path();
		match(SEMICOLON);
		{ // ( ... )*
		for (;;) {
			if (((LA(1) >= ALGORITHM && LA(1) <= UNQUALIFIED))) {
				matchNot(ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE);
			}
			else {
				goto _loop7;
			}
			
		}
		_loop7:;
		} // ( ... )*
		match(ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE);
	}
	else if ((LA(1) == EQUALS) && (_tokenSet_1.member(LA(2)))) {
		RefMyAST tmp7_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp7_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp7_AST));
		}
		match(EQUALS);
		base_prefix();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		name_path();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		if ((LA(1) == LBRACK)) {
			array_subscripts();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else if ((_tokenSet_2.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		
		}
		{
		if ((LA(1) == LPAR)) {
			class_modification();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else if ((_tokenSet_3.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		
		}
		comment();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == EQUALS) && (LA(2) == ENUMERATION)) {
		RefMyAST tmp8_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp8_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp8_AST));
		}
		match(EQUALS);
		enumeration();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	class_specifier_AST = RefMyAST(currentAST.root);
	returnAST = class_specifier_AST;
}

void flat_modelica_parser::string_comment() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST string_comment_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if ((LA(1) == STRING)) {
		RefMyAST tmp9_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp9_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp9_AST));
		}
		match(STRING);
		{
		bool synPredMatched197 = false;
		if (((LA(1) == PLUS))) {
			int _m197 = mark();
			synPredMatched197 = true;
			inputState->guessing++;
			try {
				{
				match(PLUS);
				match(STRING);
				}
			}
			catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
				synPredMatched197 = false;
			}
			rewind(_m197);
			inputState->guessing--;
		}
		if ( synPredMatched197 ) {
			{ // ( ... )+
			int _cnt199=0;
			for (;;) {
				if ((LA(1) == PLUS)) {
					RefMyAST tmp10_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
					if ( inputState->guessing == 0 ) {
						tmp10_AST = astFactory->create(LT(1));
						astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp10_AST));
					}
					match(PLUS);
					RefMyAST tmp11_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
					if ( inputState->guessing == 0 ) {
						tmp11_AST = astFactory->create(LT(1));
						astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp11_AST));
					}
					match(STRING);
				}
				else {
					if ( _cnt199>=1 ) { goto _loop199; } else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());}
				}
				
				_cnt199++;
			}
			_loop199:;
			}  // ( ... )+
		}
		else if ((_tokenSet_4.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		
		}
	}
	else if ((_tokenSet_4.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	if ( inputState->guessing==0 ) {
		string_comment_AST = RefMyAST(currentAST.root);
#line 673 "flat_modelica_parser.g"
		
		if (string_comment_AST)
		{
		string_comment_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(STRING_COMMENT,"STRING_COMMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(string_comment_AST))));
		}
				
#line 298 "flat_modelica_parser.cpp"
		currentAST.root = string_comment_AST;
		if ( string_comment_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			string_comment_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = string_comment_AST->getFirstChild();
		else
			currentAST.child = string_comment_AST;
		currentAST.advanceChildToEnd();
	}
	string_comment_AST = RefMyAST(currentAST.root);
	returnAST = string_comment_AST;
}

void flat_modelica_parser::composition() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST composition_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	element_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		switch ( LA(1)) {
		case PUBLIC:
		{
			public_element_list();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case PROTECTED:
		{
			protected_element_list();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case EQUATION:
		{
			equation_clause();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case ALGORITHM:
		{
			algorithm_clause();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		default:
			if ((LA(1) == INITIAL) && (LA(2) == EQUATION)) {
				initial_equation_clause();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
			else if ((LA(1) == INITIAL) && (LA(2) == ALGORITHM)) {
				initial_algorithm_clause();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
		else {
			goto _loop21;
		}
		}
	}
	_loop21:;
	} // ( ... )*
	{
	if ((LA(1) == EXTERNAL)) {
		external_clause();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == END)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	composition_AST = RefMyAST(currentAST.root);
	returnAST = composition_AST;
}

void flat_modelica_parser::name_path() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST name_path_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (((LA(1) == IDENT) && (_tokenSet_5.member(LA(2))))&&( LA(2)!=DOT )) {
		RefMyAST tmp12_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp12_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp12_AST));
		}
		match(IDENT);
		name_path_AST = RefMyAST(currentAST.root);
	}
	else if ((LA(1) == IDENT) && (LA(2) == DOT)) {
		RefMyAST tmp13_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp13_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp13_AST));
		}
		match(IDENT);
		RefMyAST tmp14_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp14_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp14_AST));
		}
		match(DOT);
		name_path();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		name_path_AST = RefMyAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = name_path_AST;
}

void flat_modelica_parser::base_prefix() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST base_prefix_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	type_prefix();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	base_prefix_AST = RefMyAST(currentAST.root);
	returnAST = base_prefix_AST;
}

void flat_modelica_parser::array_subscripts() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST array_subscripts_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp15_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp15_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp15_AST));
	}
	match(LBRACK);
	subscript();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == COMMA)) {
			match(COMMA);
			subscript();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop188;
		}
		
	}
	_loop188:;
	} // ( ... )*
	match(RBRACK);
	array_subscripts_AST = RefMyAST(currentAST.root);
	returnAST = array_subscripts_AST;
}

void flat_modelica_parser::class_modification() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_modification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	match(LPAR);
	{
	if ((LA(1) == EACH || LA(1) == IDENT)) {
		argument_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == RPAR)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	match(RPAR);
	if ( inputState->guessing==0 ) {
		class_modification_AST = RefMyAST(currentAST.root);
#line 244 "flat_modelica_parser.g"
		
					class_modification_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CLASS_MODIFICATION,"CLASS_MODIFICATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(class_modification_AST))));
				
#line 509 "flat_modelica_parser.cpp"
		currentAST.root = class_modification_AST;
		if ( class_modification_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			class_modification_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = class_modification_AST->getFirstChild();
		else
			currentAST.child = class_modification_AST;
		currentAST.advanceChildToEnd();
	}
	class_modification_AST = RefMyAST(currentAST.root);
	returnAST = class_modification_AST;
}

void flat_modelica_parser::comment() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST comment_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	string_comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if ((LA(1) == ANNOTATION)) {
		annotation();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_6.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	}
	if ( inputState->guessing==0 ) {
		comment_AST = RefMyAST(currentAST.root);
#line 666 "flat_modelica_parser.g"
		
					comment_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(COMMENT,"COMMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(comment_AST))));
				
#line 553 "flat_modelica_parser.cpp"
		currentAST.root = comment_AST;
		if ( comment_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			comment_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = comment_AST->getFirstChild();
		else
			currentAST.child = comment_AST;
		currentAST.advanceChildToEnd();
	}
	comment_AST = RefMyAST(currentAST.root);
	returnAST = comment_AST;
}

void flat_modelica_parser::enumeration() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST enumeration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp20_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp20_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp20_AST));
	}
	match(ENUMERATION);
	match(LPAR);
	enum_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(RPAR);
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	enumeration_AST = RefMyAST(currentAST.root);
	returnAST = enumeration_AST;
}

void flat_modelica_parser::type_prefix() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST type_prefix_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if ((LA(1) == FLOW)) {
		RefMyAST tmp23_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp23_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp23_AST));
		}
		match(FLOW);
	}
	else if ((_tokenSet_7.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	{
	switch ( LA(1)) {
	case DISCRETE:
	{
		RefMyAST tmp24_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp24_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp24_AST));
		}
		match(DISCRETE);
		break;
	}
	case PARAMETER:
	{
		RefMyAST tmp25_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp25_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp25_AST));
		}
		match(PARAMETER);
		break;
	}
	case CONSTANT:
	{
		RefMyAST tmp26_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp26_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp26_AST));
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
		RefMyAST tmp27_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp27_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp27_AST));
		}
		match(INPUT);
		break;
	}
	case OUTPUT:
	{
		RefMyAST tmp28_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp28_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp28_AST));
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
	type_prefix_AST = RefMyAST(currentAST.root);
	returnAST = type_prefix_AST;
}

void flat_modelica_parser::name_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST name_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	name_path();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == COMMA)) {
			match(COMMA);
			name_path();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop13;
		}
		
	}
	_loop13:;
	} // ( ... )*
	name_list_AST = RefMyAST(currentAST.root);
	returnAST = name_list_AST;
}

void flat_modelica_parser::enum_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST enum_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	enumeration_literal();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == COMMA)) {
			match(COMMA);
			enumeration_literal();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop17;
		}
		
	}
	_loop17:;
	} // ( ... )*
	enum_list_AST = RefMyAST(currentAST.root);
	returnAST = enum_list_AST;
}

void flat_modelica_parser::enumeration_literal() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST enumeration_literal_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp31_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp31_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp31_AST));
	}
	match(IDENT);
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		enumeration_literal_AST = RefMyAST(currentAST.root);
#line 128 "flat_modelica_parser.g"
		
					enumeration_literal_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ENUMERATION_LITERAL,"ENUMERATION_LITERAL")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(enumeration_literal_AST))));
				
#line 771 "flat_modelica_parser.cpp"
		currentAST.root = enumeration_literal_AST;
		if ( enumeration_literal_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			enumeration_literal_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = enumeration_literal_AST->getFirstChild();
		else
			currentAST.child = enumeration_literal_AST;
		currentAST.advanceChildToEnd();
	}
	enumeration_literal_AST = RefMyAST(currentAST.root);
	returnAST = enumeration_literal_AST;
}

void flat_modelica_parser::element_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_8.member(LA(1)))) {
			{
			if ((_tokenSet_9.member(LA(1)))) {
				element();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
			else if ((LA(1) == ANNOTATION)) {
				annotation();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
			else {
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}
			
			}
			match(SEMICOLON);
		}
		else {
			goto _loop37;
		}
		
	}
	_loop37:;
	} // ( ... )*
	element_list_AST = RefMyAST(currentAST.root);
	returnAST = element_list_AST;
}

void flat_modelica_parser::public_element_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST public_element_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp33_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp33_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp33_AST));
	}
	match(PUBLIC);
	element_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	public_element_list_AST = RefMyAST(currentAST.root);
	returnAST = public_element_list_AST;
}

void flat_modelica_parser::protected_element_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST protected_element_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp34_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp34_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp34_AST));
	}
	match(PROTECTED);
	element_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	protected_element_list_AST = RefMyAST(currentAST.root);
	returnAST = protected_element_list_AST;
}

void flat_modelica_parser::initial_equation_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST initial_equation_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ec_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (!( LA(2)==EQUATION))
		throw ANTLR_USE_NAMESPACE(antlr)SemanticException(" LA(2)==EQUATION");
	match(INITIAL);
	equation_clause();
	if (inputState->guessing==0) {
		ec_AST = returnAST;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		initial_equation_clause_AST = RefMyAST(currentAST.root);
#line 281 "flat_modelica_parser.g"
		
		initial_equation_clause_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_EQUATION,"INTIAL_EQUATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(ec_AST))));
		
#line 881 "flat_modelica_parser.cpp"
		currentAST.root = initial_equation_clause_AST;
		if ( initial_equation_clause_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			initial_equation_clause_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = initial_equation_clause_AST->getFirstChild();
		else
			currentAST.child = initial_equation_clause_AST;
		currentAST.advanceChildToEnd();
	}
	initial_equation_clause_AST = RefMyAST(currentAST.root);
	returnAST = initial_equation_clause_AST;
}

void flat_modelica_parser::initial_algorithm_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST initial_algorithm_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (!( LA(2)==ALGORITHM))
		throw ANTLR_USE_NAMESPACE(antlr)SemanticException(" LA(2)==ALGORITHM");
	match(INITIAL);
	RefMyAST tmp37_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp37_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp37_AST));
	}
	match(ALGORITHM);
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_10.member(LA(1)))) {
			algorithm();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
		}
		else if ((LA(1) == ANNOTATION)) {
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
		}
		else {
			goto _loop78;
		}
		
	}
	_loop78:;
	} // ( ... )*
	if ( inputState->guessing==0 ) {
		initial_algorithm_clause_AST = RefMyAST(currentAST.root);
#line 311 "flat_modelica_parser.g"
		
			            initial_algorithm_clause_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_ALGORITHM,"INTIAL_ALGORITHM")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(initial_algorithm_clause_AST))));
				
#line 937 "flat_modelica_parser.cpp"
		currentAST.root = initial_algorithm_clause_AST;
		if ( initial_algorithm_clause_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			initial_algorithm_clause_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = initial_algorithm_clause_AST->getFirstChild();
		else
			currentAST.child = initial_algorithm_clause_AST;
		currentAST.advanceChildToEnd();
	}
	initial_algorithm_clause_AST = RefMyAST(currentAST.root);
	returnAST = initial_algorithm_clause_AST;
}

void flat_modelica_parser::equation_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp40_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp40_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp40_AST));
	}
	match(EQUATION);
	equation_annotation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	equation_clause_AST = RefMyAST(currentAST.root);
	returnAST = equation_clause_AST;
}

void flat_modelica_parser::algorithm_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp41_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp41_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp41_AST));
	}
	match(ALGORITHM);
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_10.member(LA(1)))) {
			algorithm();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
		}
		else if ((LA(1) == ANNOTATION)) {
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
		}
		else {
			goto _loop75;
		}
		
	}
	_loop75:;
	} // ( ... )*
	algorithm_clause_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_clause_AST;
}

void flat_modelica_parser::external_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST external_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp44_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp44_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp44_AST));
	}
	match(EXTERNAL);
	{
	if ((LA(1) == STRING)) {
		language_specification();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_11.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	{
	if ((LA(1) == IDENT)) {
		external_function_call();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == ANNOTATION || LA(1) == END || LA(1) == SEMICOLON)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	{
	if ((LA(1) == SEMICOLON)) {
		match(SEMICOLON);
	}
	else if ((LA(1) == ANNOTATION || LA(1) == END)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	{
	if ((LA(1) == ANNOTATION)) {
		annotation();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		match(SEMICOLON);
	}
	else if ((LA(1) == END)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	external_clause_AST = RefMyAST(currentAST.root);
	returnAST = external_clause_AST;
}

void flat_modelica_parser::language_specification() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST language_specification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp47_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp47_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp47_AST));
	}
	match(STRING);
	language_specification_AST = RefMyAST(currentAST.root);
	returnAST = language_specification_AST;
}

void flat_modelica_parser::external_function_call() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST external_function_call_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if ((LA(1) == IDENT) && (LA(2) == LBRACK || LA(2) == EQUALS || LA(2) == DOT)) {
		component_reference();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		RefMyAST tmp48_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp48_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp48_AST));
		}
		match(EQUALS);
	}
	else if ((LA(1) == IDENT) && (LA(2) == LPAR)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	RefMyAST tmp49_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp49_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp49_AST));
	}
	match(IDENT);
	match(LPAR);
	{
	if ((_tokenSet_12.member(LA(1)))) {
		expression_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == RPAR)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	match(RPAR);
	if ( inputState->guessing==0 ) {
		external_function_call_AST = RefMyAST(currentAST.root);
#line 170 "flat_modelica_parser.g"
		
					external_function_call_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EXTERNAL_FUNCTION_CALL,"EXTERNAL_FUNCTION_CALL")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(external_function_call_AST))));
				
#line 1144 "flat_modelica_parser.cpp"
		currentAST.root = external_function_call_AST;
		if ( external_function_call_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			external_function_call_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = external_function_call_AST->getFirstChild();
		else
			currentAST.child = external_function_call_AST;
		currentAST.advanceChildToEnd();
	}
	external_function_call_AST = RefMyAST(currentAST.root);
	returnAST = external_function_call_AST;
}

void flat_modelica_parser::annotation() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST annotation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp52_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp52_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp52_AST));
	}
	match(ANNOTATION);
	class_modification();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	annotation_AST = RefMyAST(currentAST.root);
	returnAST = annotation_AST;
}

void flat_modelica_parser::component_reference() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_reference_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp53_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp53_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp53_AST));
	}
	match(IDENT);
	{
	if ((LA(1) == LBRACK)) {
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_13.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	{
	if ((LA(1) == DOT)) {
		RefMyAST tmp54_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp54_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp54_AST));
		}
		match(DOT);
		component_reference();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_14.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	component_reference_AST = RefMyAST(currentAST.root);
	returnAST = component_reference_AST;
}

void flat_modelica_parser::expression_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST expression_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	expression_list2();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		expression_list_AST = RefMyAST(currentAST.root);
#line 645 "flat_modelica_parser.g"
		
					expression_list_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EXPRESSION_LIST,"EXPRESSION_LIST")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(expression_list_AST))));
				
#line 1240 "flat_modelica_parser.cpp"
		currentAST.root = expression_list_AST;
		if ( expression_list_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			expression_list_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = expression_list_AST->getFirstChild();
		else
			currentAST.child = expression_list_AST;
		currentAST.advanceChildToEnd();
	}
	expression_list_AST = RefMyAST(currentAST.root);
	returnAST = expression_list_AST;
}

void flat_modelica_parser::element() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST cc_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if ((LA(1) == FINAL)) {
		RefMyAST tmp55_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp55_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp55_AST));
		}
		match(FINAL);
	}
	else if ((_tokenSet_15.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	{
	switch ( LA(1)) {
	case INNER:
	{
		RefMyAST tmp56_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp56_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp56_AST));
		}
		match(INNER);
		break;
	}
	case OUTER:
	{
		RefMyAST tmp57_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp57_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp57_AST));
		}
		match(OUTER);
		break;
	}
	case CONSTANT:
	case DISCRETE:
	case FLOW:
	case INPUT:
	case MODEL:
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
	if ((LA(1) == MODEL)) {
		class_definition();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_1.member(LA(1)))) {
		component_clause();
		if (inputState->guessing==0) {
			cc_AST = returnAST;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	if ( inputState->guessing==0 ) {
		element_AST = RefMyAST(currentAST.root);
#line 184 "flat_modelica_parser.g"
		
					if(cc_AST != null ) 
					{ 
						element_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(DECLARATION,"DECLARATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(element_AST)))); 
					}
					else	
					{ 
						element_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(DEFINITION,"DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(element_AST)))); 
					}
				
#line 1346 "flat_modelica_parser.cpp"
		currentAST.root = element_AST;
		if ( element_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			element_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = element_AST->getFirstChild();
		else
			currentAST.child = element_AST;
		currentAST.advanceChildToEnd();
	}
	element_AST = RefMyAST(currentAST.root);
	returnAST = element_AST;
}

void flat_modelica_parser::component_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	type_prefix();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	type_specifier();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if ((LA(1) == LBRACK)) {
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == IDENT)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	component_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	component_clause_AST = RefMyAST(currentAST.root);
	returnAST = component_clause_AST;
}

void flat_modelica_parser::type_specifier() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST type_specifier_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	name_path();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	type_specifier_AST = RefMyAST(currentAST.root);
	returnAST = type_specifier_AST;
}

void flat_modelica_parser::component_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	component_declaration();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == COMMA)) {
			match(COMMA);
			component_declaration();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop51;
		}
		
	}
	_loop51:;
	} // ( ... )*
	component_list_AST = RefMyAST(currentAST.root);
	returnAST = component_list_AST;
}

void flat_modelica_parser::component_declaration() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_declaration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	declaration();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	component_declaration_AST = RefMyAST(currentAST.root);
	returnAST = component_declaration_AST;
}

void flat_modelica_parser::declaration() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST declaration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp59_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp59_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp59_AST));
	}
	match(IDENT);
	{
	if ((LA(1) == LBRACK)) {
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_16.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	{
	if ((LA(1) == LPAR || LA(1) == EQUALS || LA(1) == ASSIGN)) {
		modification();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_17.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	declaration_AST = RefMyAST(currentAST.root);
	returnAST = declaration_AST;
}

void flat_modelica_parser::modification() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST modification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	switch ( LA(1)) {
	case LPAR:
	{
		class_modification();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		if ((LA(1) == EQUALS)) {
			match(EQUALS);
			expression();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else if ((_tokenSet_18.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		
		}
		break;
	}
	case EQUALS:
	{
		RefMyAST tmp61_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp61_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp61_AST));
		}
		match(EQUALS);
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case ASSIGN:
	{
		RefMyAST tmp62_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp62_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp62_AST));
		}
		match(ASSIGN);
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	modification_AST = RefMyAST(currentAST.root);
	returnAST = modification_AST;
}

void flat_modelica_parser::expression() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if ((LA(1) == IF)) {
		if_expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_19.member(LA(1)))) {
		simple_expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	expression_AST = RefMyAST(currentAST.root);
	returnAST = expression_AST;
}

void flat_modelica_parser::argument_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST argument_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	argument();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == COMMA)) {
			match(COMMA);
			argument();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop63;
		}
		
	}
	_loop63:;
	} // ( ... )*
	if ( inputState->guessing==0 ) {
		argument_list_AST = RefMyAST(currentAST.root);
#line 252 "flat_modelica_parser.g"
		
					argument_list_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ARGUMENT_LIST,"ARGUMENT_LIST")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(argument_list_AST))));
				
#line 1622 "flat_modelica_parser.cpp"
		currentAST.root = argument_list_AST;
		if ( argument_list_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			argument_list_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = argument_list_AST->getFirstChild();
		else
			currentAST.child = argument_list_AST;
		currentAST.advanceChildToEnd();
	}
	argument_list_AST = RefMyAST(currentAST.root);
	returnAST = argument_list_AST;
}

void flat_modelica_parser::argument() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST argument_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST em_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	element_modification();
	if (inputState->guessing==0) {
		em_AST = returnAST;
	}
	if ( inputState->guessing==0 ) {
		argument_AST = RefMyAST(currentAST.root);
#line 259 "flat_modelica_parser.g"
		
					argument_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ELEMENT_MODIFICATION,"ELEMENT_MODIFICATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(em_AST)))); 
				
#line 1651 "flat_modelica_parser.cpp"
		currentAST.root = argument_AST;
		if ( argument_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			argument_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = argument_AST->getFirstChild();
		else
			currentAST.child = argument_AST;
		currentAST.advanceChildToEnd();
	}
	returnAST = argument_AST;
}

void flat_modelica_parser::element_modification() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_modification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if ((LA(1) == EACH)) {
		RefMyAST tmp64_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp64_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp64_AST));
		}
		match(EACH);
	}
	else if ((LA(1) == IDENT)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	component_reference();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if ((LA(1) == LPAR || LA(1) == EQUALS || LA(1) == ASSIGN)) {
		modification();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == RPAR || LA(1) == COMMA || LA(1) == STRING)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	string_comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	element_modification_AST = RefMyAST(currentAST.root);
	returnAST = element_modification_AST;
}

void flat_modelica_parser::component_clause1() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_clause1_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	type_prefix();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	type_specifier();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	component_declaration();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	component_clause1_AST = RefMyAST(currentAST.root);
	returnAST = component_clause1_AST;
}

void flat_modelica_parser::equation_annotation_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_annotation_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (((_tokenSet_20.member(LA(1))) && (_tokenSet_21.member(LA(2))))&&( LA(1) == END || LA(1) == EQUATION || LA(1) == ALGORITHM || LA(1)==INITIAL 
		 || LA(1) == PROTECTED || LA(1) == PUBLIC )) {
		equation_annotation_list_AST = RefMyAST(currentAST.root);
	}
	else if ((_tokenSet_22.member(LA(1))) && (_tokenSet_23.member(LA(2)))) {
		{
		if ((_tokenSet_24.member(LA(1)))) {
			equation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
		}
		else if ((LA(1) == ANNOTATION)) {
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		
		}
		equation_annotation_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		equation_annotation_list_AST = RefMyAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = equation_annotation_list_AST;
}

void flat_modelica_parser::equation() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	switch ( LA(1)) {
	case IF:
	{
		conditional_equation_e();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case FOR:
	{
		for_clause_e();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case WHEN:
	{
		when_clause_e();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	default:
		bool synPredMatched82 = false;
		if (((_tokenSet_19.member(LA(1))) && (_tokenSet_23.member(LA(2))))) {
			int _m82 = mark();
			synPredMatched82 = true;
			inputState->guessing++;
			try {
				{
				simple_expression();
				match(EQUALS);
				}
			}
			catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
				synPredMatched82 = false;
			}
			rewind(_m82);
			inputState->guessing--;
		}
		if ( synPredMatched82 ) {
			equality_equation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else if ((LA(1) == IDENT) && (LA(2) == LPAR)) {
			RefMyAST tmp67_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp67_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp67_AST));
			}
			match(IDENT);
			function_call();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	}
	if ( inputState->guessing==0 ) {
		equation_AST = RefMyAST(currentAST.root);
#line 323 "flat_modelica_parser.g"
		
		equation_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EQUATION_STATEMENT,"EQUATION_STATEMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(equation_AST))));
		
#line 1852 "flat_modelica_parser.cpp"
		currentAST.root = equation_AST;
		if ( equation_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			equation_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = equation_AST->getFirstChild();
		else
			currentAST.child = equation_AST;
		currentAST.advanceChildToEnd();
	}
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	equation_AST = RefMyAST(currentAST.root);
	returnAST = equation_AST;
}

void flat_modelica_parser::algorithm() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	switch ( LA(1)) {
	case IDENT:
	{
		assign_clause_a();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case LPAR:
	{
		multi_assign_clause_a();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case IF:
	{
		conditional_equation_a();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case FOR:
	{
		for_clause_a();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case WHILE:
	{
		while_clause();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case WHEN:
	{
		when_clause_a();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		algorithm_AST = RefMyAST(currentAST.root);
#line 338 "flat_modelica_parser.g"
		
		algorithm_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ALGORITHM_STATEMENT,"ALGORITHM_STATEMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(algorithm_AST))));
		
#line 1940 "flat_modelica_parser.cpp"
		currentAST.root = algorithm_AST;
		if ( algorithm_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			algorithm_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = algorithm_AST->getFirstChild();
		else
			currentAST.child = algorithm_AST;
		currentAST.advanceChildToEnd();
	}
	algorithm_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_AST;
}

void flat_modelica_parser::simple_expression() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST simple_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST l1_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST l2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST l3_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	logical_expression();
	if (inputState->guessing==0) {
		l1_AST = returnAST;
	}
	{
	if ((LA(1) == COLON)) {
		RefMyAST tmp68_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp68_AST = astFactory->create(LT(1));
		}
		match(COLON);
		logical_expression();
		if (inputState->guessing==0) {
			l2_AST = returnAST;
		}
		{
		if ((LA(1) == COLON)) {
			RefMyAST tmp69_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp69_AST = astFactory->create(LT(1));
			}
			match(COLON);
			logical_expression();
			if (inputState->guessing==0) {
				l3_AST = returnAST;
			}
		}
		else if ((_tokenSet_25.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		
		}
	}
	else if ((_tokenSet_25.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	if ( inputState->guessing==0 ) {
		simple_expression_AST = RefMyAST(currentAST.root);
#line 467 "flat_modelica_parser.g"
		
					if (l3_AST != null) 
					{ 
						simple_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(4))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(RANGE3,"RANGE3")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(l1_AST))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(l2_AST))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(l3_AST)))); 
					}
					else if (l2_AST != null) 
					{ 
						simple_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(3))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(RANGE2,"RANGE2")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(l1_AST))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(l2_AST)))); 
					}
					else 
					{ 
						simple_expression_AST = l1_AST; 
					}
				
#line 2020 "flat_modelica_parser.cpp"
		currentAST.root = simple_expression_AST;
		if ( simple_expression_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			simple_expression_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = simple_expression_AST->getFirstChild();
		else
			currentAST.child = simple_expression_AST;
		currentAST.advanceChildToEnd();
	}
	returnAST = simple_expression_AST;
}

void flat_modelica_parser::equality_equation() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equality_equation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	simple_expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	RefMyAST tmp70_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp70_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp70_AST));
	}
	match(EQUALS);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	equality_equation_AST = RefMyAST(currentAST.root);
	returnAST = equality_equation_AST;
}

void flat_modelica_parser::conditional_equation_e() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST conditional_equation_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp71_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp71_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp71_AST));
	}
	match(IF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(THEN);
	equation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == ELSEIF)) {
			equation_elseif();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop91;
		}
		
	}
	_loop91:;
	} // ( ... )*
	{
	if ((LA(1) == ELSE)) {
		RefMyAST tmp73_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp73_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp73_AST));
		}
		match(ELSE);
		equation_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == END)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	match(END);
	match(IF);
	conditional_equation_e_AST = RefMyAST(currentAST.root);
	returnAST = conditional_equation_e_AST;
}

void flat_modelica_parser::for_clause_e() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_clause_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp76_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp76_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp76_AST));
	}
	match(FOR);
	for_indices();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(LOOP);
	equation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(END);
	match(FOR);
	for_clause_e_AST = RefMyAST(currentAST.root);
	returnAST = for_clause_e_AST;
}

void flat_modelica_parser::when_clause_e() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST when_clause_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp80_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp80_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp80_AST));
	}
	match(WHEN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(THEN);
	equation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == ELSEWHEN)) {
			else_when_e();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop102;
		}
		
	}
	_loop102:;
	} // ( ... )*
	match(END);
	match(WHEN);
	when_clause_e_AST = RefMyAST(currentAST.root);
	returnAST = when_clause_e_AST;
}

void flat_modelica_parser::function_call() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST function_call_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	match(LPAR);
	{
	function_arguments();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	}
	match(RPAR);
	if ( inputState->guessing==0 ) {
		function_call_AST = RefMyAST(currentAST.root);
#line 588 "flat_modelica_parser.g"
		
					function_call_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(FUNCTION_ARGUMENTS,"FUNCTION_ARGUMENTS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(function_call_AST))));
				
#line 2202 "flat_modelica_parser.cpp"
		currentAST.root = function_call_AST;
		if ( function_call_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			function_call_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = function_call_AST->getFirstChild();
		else
			currentAST.child = function_call_AST;
		currentAST.advanceChildToEnd();
	}
	function_call_AST = RefMyAST(currentAST.root);
	returnAST = function_call_AST;
}

void flat_modelica_parser::assign_clause_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST assign_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	component_reference();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if ((LA(1) == ASSIGN)) {
		RefMyAST tmp86_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp86_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp86_AST));
		}
		match(ASSIGN);
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == LPAR)) {
		function_call();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	assign_clause_a_AST = RefMyAST(currentAST.root);
	returnAST = assign_clause_a_AST;
}

void flat_modelica_parser::multi_assign_clause_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST multi_assign_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	match(LPAR);
	expression_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(RPAR);
	RefMyAST tmp89_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp89_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp89_AST));
	}
	match(ASSIGN);
	component_reference();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	function_call();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	multi_assign_clause_a_AST = RefMyAST(currentAST.root);
	returnAST = multi_assign_clause_a_AST;
}

void flat_modelica_parser::conditional_equation_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST conditional_equation_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp90_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp90_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp90_AST));
	}
	match(IF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(THEN);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == ELSEIF)) {
			algorithm_elseif();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop95;
		}
		
	}
	_loop95:;
	} // ( ... )*
	{
	if ((LA(1) == ELSE)) {
		RefMyAST tmp92_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp92_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp92_AST));
		}
		match(ELSE);
		algorithm_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == END)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	match(END);
	match(IF);
	conditional_equation_a_AST = RefMyAST(currentAST.root);
	returnAST = conditional_equation_a_AST;
}

void flat_modelica_parser::for_clause_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp95_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp95_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp95_AST));
	}
	match(FOR);
	for_indices();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(LOOP);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(END);
	match(FOR);
	for_clause_a_AST = RefMyAST(currentAST.root);
	returnAST = for_clause_a_AST;
}

void flat_modelica_parser::while_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST while_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp99_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp99_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp99_AST));
	}
	match(WHILE);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(LOOP);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(END);
	match(WHILE);
	while_clause_AST = RefMyAST(currentAST.root);
	returnAST = while_clause_AST;
}

void flat_modelica_parser::when_clause_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST when_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp103_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp103_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp103_AST));
	}
	match(WHEN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(THEN);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == ELSEWHEN)) {
			else_when_a();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop106;
		}
		
	}
	_loop106:;
	} // ( ... )*
	match(END);
	match(WHEN);
	when_clause_a_AST = RefMyAST(currentAST.root);
	returnAST = when_clause_a_AST;
}

void flat_modelica_parser::equation_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if ((((LA(1) >= ELSE && LA(1) <= END)) && (_tokenSet_24.member(LA(2))))&&(LA(1) != END || (LA(1) == END && LA(2) != IDENT))) {
		equation_list_AST = RefMyAST(currentAST.root);
	}
	else if ((_tokenSet_24.member(LA(1))) && (_tokenSet_23.member(LA(2)))) {
		{
		equation();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		match(SEMICOLON);
		equation_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		}
		equation_list_AST = RefMyAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = equation_list_AST;
}

void flat_modelica_parser::equation_elseif() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_elseif_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp108_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp108_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp108_AST));
	}
	match(ELSEIF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(THEN);
	equation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	equation_elseif_AST = RefMyAST(currentAST.root);
	returnAST = equation_elseif_AST;
}

void flat_modelica_parser::algorithm_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_10.member(LA(1)))) {
			algorithm();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
		}
		else {
			goto _loop114;
		}
		
	}
	_loop114:;
	} // ( ... )*
	algorithm_list_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_list_AST;
}

void flat_modelica_parser::algorithm_elseif() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_elseif_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp111_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp111_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp111_AST));
	}
	match(ELSEIF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(THEN);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	algorithm_elseif_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_elseif_AST;
}

void flat_modelica_parser::for_indices() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_indices_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	for_index();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	for_indices2();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	for_indices_AST = RefMyAST(currentAST.root);
	returnAST = for_indices_AST;
}

void flat_modelica_parser::else_when_e() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST else_when_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp113_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp113_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp113_AST));
	}
	match(ELSEWHEN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(THEN);
	equation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	else_when_e_AST = RefMyAST(currentAST.root);
	returnAST = else_when_e_AST;
}

void flat_modelica_parser::else_when_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST else_when_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp115_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp115_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp115_AST));
	}
	match(ELSEWHEN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(THEN);
	algorithm_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	else_when_a_AST = RefMyAST(currentAST.root);
	returnAST = else_when_a_AST;
}

void flat_modelica_parser::if_expression() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST if_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp117_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp117_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp117_AST));
	}
	match(IF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(THEN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == ELSEIF)) {
			elseif_expression();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop119;
		}
		
	}
	_loop119:;
	} // ( ... )*
	match(ELSE);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if_expression_AST = RefMyAST(currentAST.root);
	returnAST = if_expression_AST;
}

void flat_modelica_parser::elseif_expression() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST elseif_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp120_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp120_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp120_AST));
	}
	match(ELSEIF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(THEN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	elseif_expression_AST = RefMyAST(currentAST.root);
	returnAST = elseif_expression_AST;
}

void flat_modelica_parser::for_index() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_index_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	RefMyAST tmp122_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp122_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp122_AST));
	}
	match(IDENT);
	{
	if ((LA(1) == IN)) {
		RefMyAST tmp123_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp123_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp123_AST));
		}
		match(IN);
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_26.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	}
	for_index_AST = RefMyAST(currentAST.root);
	returnAST = for_index_AST;
}

void flat_modelica_parser::for_indices2() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_indices2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (((_tokenSet_27.member(LA(1))))&&(LA(2) != IN)) {
		for_indices2_AST = RefMyAST(currentAST.root);
	}
	else if ((LA(1) == COMMA)) {
		{
		match(COMMA);
		for_index();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		}
		for_indices2();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		for_indices2_AST = RefMyAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = for_indices2_AST;
}

void flat_modelica_parser::logical_expression() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST logical_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	logical_term();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == OR)) {
			RefMyAST tmp125_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp125_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp125_AST));
			}
			match(OR);
			logical_term();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop132;
		}
		
	}
	_loop132:;
	} // ( ... )*
	logical_expression_AST = RefMyAST(currentAST.root);
	returnAST = logical_expression_AST;
}

void flat_modelica_parser::logical_term() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST logical_term_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	logical_factor();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == AND)) {
			RefMyAST tmp126_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp126_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp126_AST));
			}
			match(AND);
			logical_factor();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop135;
		}
		
	}
	_loop135:;
	} // ( ... )*
	logical_term_AST = RefMyAST(currentAST.root);
	returnAST = logical_term_AST;
}

void flat_modelica_parser::logical_factor() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST logical_factor_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if ((LA(1) == NOT)) {
		RefMyAST tmp127_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp127_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp127_AST));
		}
		match(NOT);
	}
	else if ((_tokenSet_28.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	relation();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	logical_factor_AST = RefMyAST(currentAST.root);
	returnAST = logical_factor_AST;
}

void flat_modelica_parser::relation() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST relation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	arithmetic_expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if (((LA(1) >= LESS && LA(1) <= LESSGT))) {
		{
		switch ( LA(1)) {
		case LESS:
		{
			RefMyAST tmp128_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp128_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp128_AST));
			}
			match(LESS);
			break;
		}
		case LESSEQ:
		{
			RefMyAST tmp129_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp129_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp129_AST));
			}
			match(LESSEQ);
			break;
		}
		case GREATER:
		{
			RefMyAST tmp130_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp130_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp130_AST));
			}
			match(GREATER);
			break;
		}
		case GREATEREQ:
		{
			RefMyAST tmp131_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp131_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp131_AST));
			}
			match(GREATEREQ);
			break;
		}
		case EQEQ:
		{
			RefMyAST tmp132_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp132_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp132_AST));
			}
			match(EQEQ);
			break;
		}
		case LESSGT:
		{
			RefMyAST tmp133_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp133_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp133_AST));
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
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_29.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	relation_AST = RefMyAST(currentAST.root);
	returnAST = relation_AST;
}

void flat_modelica_parser::arithmetic_expression() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST arithmetic_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	unary_arithmetic_expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == PLUS || LA(1) == MINUS)) {
			{
			if ((LA(1) == PLUS)) {
				RefMyAST tmp134_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp134_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp134_AST));
				}
				match(PLUS);
			}
			else if ((LA(1) == MINUS)) {
				RefMyAST tmp135_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp135_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp135_AST));
				}
				match(MINUS);
			}
			else {
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}
			
			}
			term();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop146;
		}
		
	}
	_loop146:;
	} // ( ... )*
	arithmetic_expression_AST = RefMyAST(currentAST.root);
	returnAST = arithmetic_expression_AST;
}

void flat_modelica_parser::rel_op() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST rel_op_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	switch ( LA(1)) {
	case LESS:
	{
		RefMyAST tmp136_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp136_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp136_AST));
		}
		match(LESS);
		break;
	}
	case LESSEQ:
	{
		RefMyAST tmp137_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp137_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp137_AST));
		}
		match(LESSEQ);
		break;
	}
	case GREATER:
	{
		RefMyAST tmp138_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp138_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp138_AST));
		}
		match(GREATER);
		break;
	}
	case GREATEREQ:
	{
		RefMyAST tmp139_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp139_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp139_AST));
		}
		match(GREATEREQ);
		break;
	}
	case EQEQ:
	{
		RefMyAST tmp140_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp140_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp140_AST));
		}
		match(EQEQ);
		break;
	}
	case LESSGT:
	{
		RefMyAST tmp141_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp141_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp141_AST));
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
	rel_op_AST = RefMyAST(currentAST.root);
	returnAST = rel_op_AST;
}

void flat_modelica_parser::unary_arithmetic_expression() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST unary_arithmetic_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST t1_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST t2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST t3_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	switch ( LA(1)) {
	case PLUS:
	{
		RefMyAST tmp142_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp142_AST = astFactory->create(LT(1));
		}
		match(PLUS);
		term();
		if (inputState->guessing==0) {
			t1_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = RefMyAST(currentAST.root);
#line 511 "flat_modelica_parser.g"
			
						unary_arithmetic_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(UNARY_PLUS,"PLUS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(t1_AST)))); 
					
#line 3082 "flat_modelica_parser.cpp"
			currentAST.root = unary_arithmetic_expression_AST;
			if ( unary_arithmetic_expression_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				unary_arithmetic_expression_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = unary_arithmetic_expression_AST->getFirstChild();
			else
				currentAST.child = unary_arithmetic_expression_AST;
			currentAST.advanceChildToEnd();
		}
		break;
	}
	case MINUS:
	{
		RefMyAST tmp143_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp143_AST = astFactory->create(LT(1));
		}
		match(MINUS);
		term();
		if (inputState->guessing==0) {
			t2_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = RefMyAST(currentAST.root);
#line 515 "flat_modelica_parser.g"
			
						unary_arithmetic_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(UNARY_MINUS,"MINUS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(t2_AST)))); 
					
#line 3110 "flat_modelica_parser.cpp"
			currentAST.root = unary_arithmetic_expression_AST;
			if ( unary_arithmetic_expression_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				unary_arithmetic_expression_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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
			unary_arithmetic_expression_AST = RefMyAST(currentAST.root);
#line 519 "flat_modelica_parser.g"
			
						unary_arithmetic_expression_AST = t3_AST; 
					
#line 3143 "flat_modelica_parser.cpp"
			currentAST.root = unary_arithmetic_expression_AST;
			if ( unary_arithmetic_expression_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				unary_arithmetic_expression_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST term_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	factor();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{ // ( ... )*
	for (;;) {
		if ((LA(1) == STAR || LA(1) == SLASH)) {
			{
			if ((LA(1) == STAR)) {
				RefMyAST tmp144_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp144_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp144_AST));
				}
				match(STAR);
			}
			else if ((LA(1) == SLASH)) {
				RefMyAST tmp145_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp145_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp145_AST));
				}
				match(SLASH);
			}
			else {
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}
			
			}
			factor();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop152;
		}
		
	}
	_loop152:;
	} // ( ... )*
	term_AST = RefMyAST(currentAST.root);
	returnAST = term_AST;
}

void flat_modelica_parser::factor() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST factor_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	primary();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if ((LA(1) == POWER)) {
		RefMyAST tmp146_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp146_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp146_AST));
		}
		match(POWER);
		primary();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_30.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	factor_AST = RefMyAST(currentAST.root);
	returnAST = factor_AST;
}

void flat_modelica_parser::primary() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST primary_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	switch ( LA(1)) {
	case UNSIGNED_INTEGER:
	{
		RefMyAST tmp147_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp147_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp147_AST));
		}
		match(UNSIGNED_INTEGER);
		break;
	}
	case UNSIGNED_REAL:
	{
		RefMyAST tmp148_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp148_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp148_AST));
		}
		match(UNSIGNED_REAL);
		break;
	}
	case STRING:
	{
		RefMyAST tmp149_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp149_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp149_AST));
		}
		match(STRING);
		break;
	}
	case FALSE:
	{
		RefMyAST tmp150_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp150_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp150_AST));
		}
		match(FALSE);
		break;
	}
	case TRUE:
	{
		RefMyAST tmp151_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp151_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp151_AST));
		}
		match(TRUE);
		break;
	}
	case INITIAL:
	case IDENT:
	{
		component_reference__function_call();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case LPAR:
	{
		RefMyAST tmp152_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp152_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp152_AST));
		}
		match(LPAR);
		expression_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		match(RPAR);
		break;
	}
	case LBRACK:
	{
		RefMyAST tmp154_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp154_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp154_AST));
		}
		match(LBRACK);
		expression_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{ // ( ... )*
		for (;;) {
			if ((LA(1) == SEMICOLON)) {
				match(SEMICOLON);
				expression_list();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
			else {
				goto _loop158;
			}
			
		}
		_loop158:;
		} // ( ... )*
		match(RBRACK);
		break;
	}
	case LBRACE:
	{
		RefMyAST tmp157_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp157_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp157_AST));
		}
		match(LBRACE);
		for_or_expression_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		match(RBRACE);
		break;
	}
	case END:
	{
		RefMyAST tmp159_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp159_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp159_AST));
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
	primary_AST = RefMyAST(currentAST.root);
	returnAST = primary_AST;
}

void flat_modelica_parser::component_reference__function_call() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_reference__function_call_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST cr_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST fc_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)RefToken  i = ANTLR_USE_NAMESPACE(antlr)nullToken;
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if ((LA(1) == IDENT)) {
		component_reference();
		if (inputState->guessing==0) {
			cr_AST = returnAST;
		}
		{
		if ((LA(1) == LPAR)) {
			function_call();
			if (inputState->guessing==0) {
				fc_AST = returnAST;
			}
		}
		else if ((_tokenSet_31.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		
		}
		if ( inputState->guessing==0 ) {
			component_reference__function_call_AST = RefMyAST(currentAST.root);
#line 549 "flat_modelica_parser.g"
			
						if (fc_AST != null) 
						{ 
							component_reference__function_call_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(3))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(FUNCTION_CALL,"FUNCTION_CALL")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(cr_AST))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(fc_AST))));
						} 
						else 
						{ 
							component_reference__function_call_AST = cr_AST;
						} 
					
#line 3434 "flat_modelica_parser.cpp"
			currentAST.root = component_reference__function_call_AST;
			if ( component_reference__function_call_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				component_reference__function_call_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = component_reference__function_call_AST->getFirstChild();
			else
				currentAST.child = component_reference__function_call_AST;
			currentAST.advanceChildToEnd();
		}
	}
	else if ((LA(1) == INITIAL)) {
		i = LT(1);
		if ( inputState->guessing == 0 ) {
			i_AST = astFactory->create(i);
		}
		match(INITIAL);
		match(LPAR);
		match(RPAR);
		if ( inputState->guessing==0 ) {
			component_reference__function_call_AST = RefMyAST(currentAST.root);
#line 559 "flat_modelica_parser.g"
			
						component_reference__function_call_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_FUNCTION_CALL,"INITIAL_FUNCTION_CALL")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST))));
					
#line 3458 "flat_modelica_parser.cpp"
			currentAST.root = component_reference__function_call_AST;
			if ( component_reference__function_call_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				component_reference__function_call_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = component_reference__function_call_AST->getFirstChild();
			else
				currentAST.child = component_reference__function_call_AST;
			currentAST.advanceChildToEnd();
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = component_reference__function_call_AST;
}

void flat_modelica_parser::for_or_expression_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_or_expression_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST explist_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST forind_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if (((LA(1) == RPAR || LA(1) == RBRACE || LA(1) == IDENT) && (_tokenSet_31.member(LA(2))))&&(LA(1)==IDENT && LA(2) == EQUALS|| LA(1) == RPAR)) {
	}
	else if ((_tokenSet_12.member(LA(1))) && (_tokenSet_32.member(LA(2)))) {
		{
		expression();
		if (inputState->guessing==0) {
			e_AST = returnAST;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		switch ( LA(1)) {
		case COMMA:
		{
			match(COMMA);
			for_or_expression_list2();
			if (inputState->guessing==0) {
				explist_AST = returnAST;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case FOR:
		{
			RefMyAST tmp163_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp163_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp163_AST));
			}
			match(FOR);
			for_indices();
			if (inputState->guessing==0) {
				forind_AST = returnAST;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case RPAR:
		case RBRACE:
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
			for_or_expression_list_AST = RefMyAST(currentAST.root);
#line 609 "flat_modelica_parser.g"
			
			if (forind_AST != null) {
			for_or_expression_list_AST = 
			RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(FOR_ITERATOR,"FOR_ITERATOR")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(for_or_expression_list_AST))));
			}
			else {
			for_or_expression_list_AST = 
			RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EXPRESSION_LIST,"EXPRESSION_LIST")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(for_or_expression_list_AST))));
			}
			
#line 3546 "flat_modelica_parser.cpp"
			currentAST.root = for_or_expression_list_AST;
			if ( for_or_expression_list_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				for_or_expression_list_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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
	for_or_expression_list_AST = RefMyAST(currentAST.root);
	returnAST = for_or_expression_list_AST;
}

bool  flat_modelica_parser::name_path_star() {
#line 569 "flat_modelica_parser.g"
	bool val;
#line 3568 "flat_modelica_parser.cpp"
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST name_path_star_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)RefToken  i = ANTLR_USE_NAMESPACE(antlr)nullToken;
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST np_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (((LA(1) == IDENT) && (LA(2) == ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE))&&( LA(2)!=DOT )) {
		RefMyAST tmp164_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp164_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp164_AST));
		}
		match(IDENT);
		if ( inputState->guessing==0 ) {
#line 571 "flat_modelica_parser.g"
			val=false;
#line 3586 "flat_modelica_parser.cpp"
		}
		name_path_star_AST = RefMyAST(currentAST.root);
	}
	else if (((LA(1) == STAR))&&( LA(2)!=DOT )) {
		match(STAR);
		if ( inputState->guessing==0 ) {
#line 572 "flat_modelica_parser.g"
			val=true;
#line 3595 "flat_modelica_parser.cpp"
		}
		name_path_star_AST = RefMyAST(currentAST.root);
	}
	else if ((LA(1) == IDENT) && (LA(2) == DOT)) {
		i = LT(1);
		if ( inputState->guessing == 0 ) {
			i_AST = astFactory->create(i);
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		}
		match(IDENT);
		RefMyAST tmp166_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp166_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp166_AST));
		}
		match(DOT);
		val=name_path_star();
		if (inputState->guessing==0) {
			np_AST = returnAST;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		if ( inputState->guessing==0 ) {
			name_path_star_AST = RefMyAST(currentAST.root);
#line 574 "flat_modelica_parser.g"
			
						if(!(np_AST))
						{
							name_path_star_AST = i_AST;
						}
					
#line 3626 "flat_modelica_parser.cpp"
			currentAST.root = name_path_star_AST;
			if ( name_path_star_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				name_path_star_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = name_path_star_AST->getFirstChild();
			else
				currentAST.child = name_path_star_AST;
			currentAST.advanceChildToEnd();
		}
		name_path_star_AST = RefMyAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = name_path_star_AST;
	return val;
}

void flat_modelica_parser::function_arguments() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST function_arguments_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	for_or_expression_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	}
	{
	if ((LA(1) == IDENT)) {
		named_arguments();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == RPAR)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	function_arguments_AST = RefMyAST(currentAST.root);
	returnAST = function_arguments_AST;
}

void flat_modelica_parser::named_arguments() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST named_arguments_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	named_arguments2();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		named_arguments_AST = RefMyAST(currentAST.root);
#line 630 "flat_modelica_parser.g"
		
					named_arguments_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(NAMED_ARGUMENTS,"NAMED_ARGUMENTS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(named_arguments_AST))));
				
#line 3689 "flat_modelica_parser.cpp"
		currentAST.root = named_arguments_AST;
		if ( named_arguments_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			named_arguments_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = named_arguments_AST->getFirstChild();
		else
			currentAST.child = named_arguments_AST;
		currentAST.advanceChildToEnd();
	}
	named_arguments_AST = RefMyAST(currentAST.root);
	returnAST = named_arguments_AST;
}

void flat_modelica_parser::for_or_expression_list2() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_or_expression_list2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (((LA(1) == RPAR || LA(1) == RBRACE || LA(1) == IDENT) && (_tokenSet_31.member(LA(2))))&&(LA(2) == EQUALS)) {
		for_or_expression_list2_AST = RefMyAST(currentAST.root);
	}
	else if ((_tokenSet_12.member(LA(1))) && (_tokenSet_33.member(LA(2)))) {
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		if ((LA(1) == COMMA)) {
			match(COMMA);
			for_or_expression_list2();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else if ((LA(1) == RPAR || LA(1) == RBRACE || LA(1) == IDENT)) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		
		}
		for_or_expression_list2_AST = RefMyAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = for_or_expression_list2_AST;
}

void flat_modelica_parser::named_arguments2() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST named_arguments2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	named_argument();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	bool synPredMatched181 = false;
	if (((LA(1) == COMMA))) {
		int _m181 = mark();
		synPredMatched181 = true;
		inputState->guessing++;
		try {
			{
			match(COMMA);
			match(IDENT);
			match(EQUALS);
			}
		}
		catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
			synPredMatched181 = false;
		}
		rewind(_m181);
		inputState->guessing--;
	}
	if ( synPredMatched181 ) {
		match(COMMA);
		named_arguments2();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == RPAR)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	named_arguments2_AST = RefMyAST(currentAST.root);
	returnAST = named_arguments2_AST;
}

void flat_modelica_parser::named_argument() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST named_argument_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp169_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp169_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp169_AST));
	}
	match(IDENT);
	RefMyAST tmp170_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp170_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp170_AST));
	}
	match(EQUALS);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	named_argument_AST = RefMyAST(currentAST.root);
	returnAST = named_argument_AST;
}

void flat_modelica_parser::expression_list2() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST expression_list2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if ((LA(1) == COMMA)) {
		match(COMMA);
		expression_list2();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == RPAR || LA(1) == RBRACK || LA(1) == SEMICOLON)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	expression_list2_AST = RefMyAST(currentAST.root);
	returnAST = expression_list2_AST;
}

void flat_modelica_parser::subscript() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST subscript_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if ((_tokenSet_12.member(LA(1)))) {
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		subscript_AST = RefMyAST(currentAST.root);
	}
	else if ((LA(1) == COLON)) {
		RefMyAST tmp172_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp172_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp172_AST));
		}
		match(COLON);
		subscript_AST = RefMyAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = subscript_AST;
}

void flat_modelica_parser::initializeASTFactory( ANTLR_USE_NAMESPACE(antlr)ASTFactory& factory )
{
	factory.setMaxNodeType(155);
}
const char* flat_modelica_parser::tokenNames[] = {
	"<0>",
	"EOF",
	"<2>",
	"NULL_TREE_LOOKAHEAD",
	"\"algorithm\"",
	"\"and\"",
	"\"annotation\"",
	"\"block\"",
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
	"\"outer\"",
	"\"overload\"",
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
	"\"abstype\"",
	"\"as\"",
	"\"axiom\"",
	"\"datatype\"",
	"\"fail\"",
	"\"let\"",
	"\"interface\"",
	"\"module\"",
	"\"of\"",
	"\"relation\"",
	"\"rule\"",
	"\"val\"",
	"\"_\"",
	"\"with\"",
	"\"withtype\"",
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
	"YIELDS",
	"AMPERSAND",
	"PIPEBAR",
	"COLONCOLON",
	"DASHES",
	"WS",
	"ML_COMMENT",
	"ML_COMMENT_CHAR",
	"SL_COMMENT",
	"an identifier",
	"a type identifier",
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
	"BEGIN_DEFINITION",
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
	"COMPONENT_DEFINITION",
	"DECLARATION",
	"DEFINITION",
	"END_DEFINITION",
	"ENUMERATION_LITERAL",
	"ELEMENT",
	"ELEMENT_MODIFICATION",
	"ELEMENT_REDECLARATION",
	"EQUATION_STATEMENT",
	"INITIAL_EQUATION",
	"INITIAL_ALGORITHM",
	"IMPORT_DEFINITION",
	"EXPRESSION_LIST",
	"EXTERNAL_FUNCTION_CALL",
	"FOR_INDICES",
	"FOR_ITERATOR",
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

const unsigned long flat_modelica_parser::_tokenSet_0_data_[] = { 110374992UL, 27223UL, 0UL, 33280UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "annotation" "constant" "discrete" "end" "equation" "external" 
// "final" "flow" "initial" "inner" "input" "model" "outer" "output" "parameter" 
// "protected" "public" IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_0(_tokenSet_0_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_1_data_[] = { 67121152UL, 2564UL, 0UL, 512UL, 0UL, 0UL, 0UL, 0UL };
// "constant" "discrete" "flow" "input" "output" "parameter" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_1(_tokenSet_1_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_2_data_[] = { 66UL, 0UL, 1073742336UL, 32768UL, 0UL, 0UL, 0UL, 0UL };
// EOF "annotation" LPAR SEMICOLON STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_2(_tokenSet_2_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_3_data_[] = { 66UL, 0UL, 1073741824UL, 32768UL, 0UL, 0UL, 0UL, 0UL };
// EOF "annotation" SEMICOLON STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_3(_tokenSet_3_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_4_data_[] = { 110374994UL, 27223UL, 1077937152UL, 512UL, 0UL, 0UL, 0UL, 0UL };
// EOF "algorithm" "annotation" "constant" "discrete" "end" "equation" 
// "external" "final" "flow" "initial" "inner" "input" "model" "outer" 
// "output" "parameter" "protected" "public" RPAR COMMA SEMICOLON IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_4(_tokenSet_4_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_5_data_[] = { 66UL, 0UL, 1077938688UL, 33280UL, 0UL, 0UL, 0UL, 0UL };
// EOF "annotation" LPAR LBRACK COMMA SEMICOLON IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_5(_tokenSet_5_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_6_data_[] = { 2UL, 0UL, 1077937152UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// EOF RPAR COMMA SEMICOLON 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_6(_tokenSet_6_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_7_data_[] = { 12288UL, 2564UL, 0UL, 512UL, 0UL, 0UL, 0UL, 0UL };
// "constant" "discrete" "input" "output" "parameter" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_7(_tokenSet_7_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_8_data_[] = { 100675648UL, 2646UL, 0UL, 512UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "constant" "discrete" "final" "flow" "inner" "input" "model" 
// "outer" "output" "parameter" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_8(_tokenSet_8_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_9_data_[] = { 100675584UL, 2646UL, 0UL, 512UL, 0UL, 0UL, 0UL, 0UL };
// "constant" "discrete" "final" "flow" "inner" "input" "model" "outer" 
// "output" "parameter" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_9(_tokenSet_9_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_10_data_[] = { 671088640UL, 25165824UL, 512UL, 512UL, 0UL, 0UL, 0UL, 0UL };
// "for" "if" "when" "while" LPAR IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_10(_tokenSet_10_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_11_data_[] = { 262208UL, 0UL, 1073741824UL, 512UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "end" SEMICOLON IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_11(_tokenSet_11_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_12_data_[] = { 553910272UL, 5242913UL, 403968UL, 49664UL, 0UL, 0UL, 0UL, 0UL };
// "end" "false" "if" "initial" "not" "true" "unsigned_real" LPAR LBRACK 
// LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_12(_tokenSet_12_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_13_data_[] = { 134316130UL, 524552UL, 4294956544UL, 33280UL, 0UL, 0UL, 0UL, 0UL };
// EOF "and" "annotation" "else" "elseif" "for" "loop" "or" "then" LPAR 
// RPAR RBRACK RBRACE EQUALS ASSIGN PLUS MINUS STAR SLASH DOT COMMA LESS 
// LESSEQ GREATER GREATEREQ EQEQ LESSGT COLON SEMICOLON POWER IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_13(_tokenSet_13_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_14_data_[] = { 134316130UL, 524552UL, 4292859392UL, 33280UL, 0UL, 0UL, 0UL, 0UL };
// EOF "and" "annotation" "else" "elseif" "for" "loop" "or" "then" LPAR 
// RPAR RBRACK RBRACE EQUALS ASSIGN PLUS MINUS STAR SLASH COMMA LESS LESSEQ 
// GREATER GREATEREQ EQEQ LESSGT COLON SEMICOLON POWER IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_14(_tokenSet_14_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_15_data_[] = { 67121152UL, 2646UL, 0UL, 512UL, 0UL, 0UL, 0UL, 0UL };
// "constant" "discrete" "flow" "inner" "input" "model" "outer" "output" 
// "parameter" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_15(_tokenSet_15_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_16_data_[] = { 66UL, 0UL, 1078034944UL, 32768UL, 0UL, 0UL, 0UL, 0UL };
// EOF "annotation" LPAR EQUALS ASSIGN COMMA SEMICOLON STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_16(_tokenSet_16_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_17_data_[] = { 66UL, 0UL, 1077936128UL, 32768UL, 0UL, 0UL, 0UL, 0UL };
// EOF "annotation" COMMA SEMICOLON STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_17(_tokenSet_17_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_18_data_[] = { 66UL, 0UL, 1077937152UL, 32768UL, 0UL, 0UL, 0UL, 0UL };
// EOF "annotation" RPAR COMMA SEMICOLON STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_18(_tokenSet_18_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_19_data_[] = { 17039360UL, 5242913UL, 403968UL, 49664UL, 0UL, 0UL, 0UL, 0UL };
// "end" "false" "initial" "not" "true" "unsigned_real" LPAR LBRACK LBRACE 
// PLUS MINUS IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_19(_tokenSet_19_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_20_data_[] = { 9699344UL, 24577UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "end" "equation" "external" "initial" "protected" "public" 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_20(_tokenSet_20_data_,6);
const unsigned long flat_modelica_parser::_tokenSet_21_data_[] = { 798240848UL, 30435959UL, 1074145792UL, 49664UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "annotation" "constant" "discrete" "end" "equation" "external" 
// "false" "final" "flow" "for" "if" "initial" "inner" "input" "model" 
// "not" "outer" "output" "parameter" "protected" "public" "true" "unsigned_real" 
// "when" "while" LPAR LBRACK LBRACE PLUS MINUS SEMICOLON IDENT UNSIGNED_INTEGER 
// STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_21(_tokenSet_21_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_22_data_[] = { 688128064UL, 13631521UL, 403968UL, 49664UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "end" "false" "for" "if" "initial" "not" "true" "unsigned_real" 
// "when" LPAR LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_22(_tokenSet_22_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_23_data_[] = { 553910304UL, 5243169UL, 3216960000UL, 49664UL, 0UL, 0UL, 0UL, 0UL };
// "and" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real" 
// LPAR LBRACK LBRACE RBRACE EQUALS PLUS MINUS STAR SLASH DOT LESS LESSEQ 
// GREATER GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_23(_tokenSet_23_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_24_data_[] = { 688128000UL, 13631521UL, 403968UL, 49664UL, 0UL, 0UL, 0UL, 0UL };
// "end" "false" "for" "if" "initial" "not" "true" "unsigned_real" "when" 
// LPAR LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_24(_tokenSet_24_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_25_data_[] = { 134316098UL, 524296UL, 1077990400UL, 33280UL, 0UL, 0UL, 0UL, 0UL };
// EOF "annotation" "else" "elseif" "for" "loop" "then" RPAR RBRACK RBRACE 
// EQUALS COMMA SEMICOLON IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_25(_tokenSet_25_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_26_data_[] = { 0UL, 8UL, 4211712UL, 512UL, 0UL, 0UL, 0UL, 0UL };
// "loop" RPAR RBRACE COMMA IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_26(_tokenSet_26_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_27_data_[] = { 0UL, 8UL, 17408UL, 512UL, 0UL, 0UL, 0UL, 0UL };
// "loop" RPAR RBRACE IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_27(_tokenSet_27_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_28_data_[] = { 17039360UL, 5242881UL, 403968UL, 49664UL, 0UL, 0UL, 0UL, 0UL };
// "end" "false" "initial" "true" "unsigned_real" LPAR LBRACK LBRACE PLUS 
// MINUS IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_28(_tokenSet_28_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_29_data_[] = { 134316130UL, 524552UL, 1614861312UL, 33280UL, 0UL, 0UL, 0UL, 0UL };
// EOF "and" "annotation" "else" "elseif" "for" "loop" "or" "then" RPAR 
// RBRACK RBRACE EQUALS COMMA COLON SEMICOLON IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_29(_tokenSet_29_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_30_data_[] = { 134316130UL, 524552UL, 2145309696UL, 33280UL, 0UL, 0UL, 0UL, 0UL };
// EOF "and" "annotation" "else" "elseif" "for" "loop" "or" "then" RPAR 
// RBRACK RBRACE EQUALS PLUS MINUS STAR SLASH COMMA LESS LESSEQ GREATER 
// GREATEREQ EQEQ LESSGT COLON SEMICOLON IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_30(_tokenSet_30_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_31_data_[] = { 134316130UL, 524552UL, 4292793344UL, 33280UL, 0UL, 0UL, 0UL, 0UL };
// EOF "and" "annotation" "else" "elseif" "for" "loop" "or" "then" RPAR 
// RBRACK RBRACE EQUALS PLUS MINUS STAR SLASH COMMA LESS LESSEQ GREATER 
// GREATEREQ EQEQ LESSGT COLON SEMICOLON POWER IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_31(_tokenSet_31_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_32_data_[] = { 688128032UL, 5243169UL, 3221122560UL, 49664UL, 0UL, 0UL, 0UL, 0UL };
// "and" "end" "false" "for" "if" "initial" "not" "or" "true" "unsigned_real" 
// LPAR RPAR LBRACK LBRACE RBRACE PLUS MINUS STAR SLASH DOT COMMA LESS 
// LESSEQ GREATER GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER 
// STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_32(_tokenSet_32_data_,8);
const unsigned long flat_modelica_parser::_tokenSet_33_data_[] = { 553910304UL, 5243169UL, 3221122560UL, 49664UL, 0UL, 0UL, 0UL, 0UL };
// "and" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real" 
// LPAR RPAR LBRACK LBRACE RBRACE PLUS MINUS STAR SLASH DOT COMMA LESS 
// LESSEQ GREATER GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER 
// STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_parser::_tokenSet_33(_tokenSet_33_data_,8);



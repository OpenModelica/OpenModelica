/* $ANTLR 2.7.5rc2 (20050108): "modelica_parser.g" -> "modelica_parser.cpp"$ */
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
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST stored_definition_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST cd_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)RefToken  s = ANTLR_USE_NAMESPACE(antlr)nullToken;
	RefMyAST s_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	switch ( LA(1)) {
	case END:
	{
		match(END);
		RefMyAST tmp2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp2_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp2_AST));
		}
		match(IDENT);
		match(SEMICOLON);
		match(ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE);
		if ( inputState->guessing==0 ) {
			stored_definition_AST = RefMyAST(currentAST.root);
#line 96 "modelica_parser.g"

			stored_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(END_DEFINITION,"END_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(stored_definition_AST))));

#line 60 "modelica_parser.cpp"
			currentAST.root = stored_definition_AST;
			if ( stored_definition_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				stored_definition_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = stored_definition_AST->getFirstChild();
			else
				currentAST.child = stored_definition_AST;
			currentAST.advanceChildToEnd();
		}
		stored_definition_AST = RefMyAST(currentAST.root);
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
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		match(SEMICOLON);
		match(ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE);
		if ( inputState->guessing==0 ) {
			stored_definition_AST = RefMyAST(currentAST.root);
#line 102 "modelica_parser.g"

			stored_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(COMPONENT_DEFINITION,"COMPONENT_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(stored_definition_AST))));

#line 92 "modelica_parser.cpp"
			currentAST.root = stored_definition_AST;
			if ( stored_definition_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				stored_definition_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = stored_definition_AST->getFirstChild();
			else
				currentAST.child = stored_definition_AST;
			currentAST.advanceChildToEnd();
		}
		stored_definition_AST = RefMyAST(currentAST.root);
		break;
	}
	case IMPORT:
	{
		import_clause();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		match(SEMICOLON);
		match(ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE);
		if ( inputState->guessing==0 ) {
			stored_definition_AST = RefMyAST(currentAST.root);
#line 108 "modelica_parser.g"

			stored_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(IMPORT_DEFINITION,"IMPORT_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(stored_definition_AST))));

#line 118 "modelica_parser.cpp"
			currentAST.root = stored_definition_AST;
			if ( stored_definition_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				stored_definition_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = stored_definition_AST->getFirstChild();
			else
				currentAST.child = stored_definition_AST;
			currentAST.advanceChildToEnd();
		}
		stored_definition_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
		bool synPredMatched5 = false;
		if (((_tokenSet_0.member(LA(1))) && (_tokenSet_1.member(LA(2))))) {
			int _m5 = mark();
			synPredMatched5 = true;
			inputState->guessing++;
			try {
				{
				{
				if ((LA(1) == ENCAPSULATED)) {
					match(ENCAPSULATED);
				}
				else if ((_tokenSet_2.member(LA(1)))) {
				}
				else {
					throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
				}

				}
				{
				if ((LA(1) == PARTIAL)) {
					match(PARTIAL);
				}
				else if ((_tokenSet_3.member(LA(1)))) {
				}
				else {
					throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
				}

				}
				class_type();
				match(IDENT);
				match(ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE);
				}
			}
			catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
				synPredMatched5 = false;
			}
			rewind(_m5);
			inputState->guessing--;
		}
		if ( synPredMatched5 ) {
			{
			{
			if ((LA(1) == ENCAPSULATED)) {
				RefMyAST tmp9_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp9_AST = astFactory->create(LT(1));
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp9_AST));
				}
				match(ENCAPSULATED);
			}
			else if ((_tokenSet_2.member(LA(1)))) {
			}
			else {
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}

			}
			{
			if ((LA(1) == PARTIAL)) {
				RefMyAST tmp10_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp10_AST = astFactory->create(LT(1));
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp10_AST));
				}
				match(PARTIAL);
			}
			else if ((_tokenSet_3.member(LA(1)))) {
			}
			else {
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}

			}
			class_type();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			RefMyAST tmp11_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp11_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp11_AST));
			}
			match(IDENT);
			match(ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE);
			}
			if ( inputState->guessing==0 ) {
				stored_definition_AST = RefMyAST(currentAST.root);
#line 91 "modelica_parser.g"

				stored_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(BEGIN_DEFINITION,"BEGIN_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(stored_definition_AST))));

#line 223 "modelica_parser.cpp"
				currentAST.root = stored_definition_AST;
				if ( stored_definition_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
					stored_definition_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
					  currentAST.child = stored_definition_AST->getFirstChild();
				else
					currentAST.child = stored_definition_AST;
				currentAST.advanceChildToEnd();
			}
			stored_definition_AST = RefMyAST(currentAST.root);
		}
		else if ((_tokenSet_4.member(LA(1))) && (_tokenSet_5.member(LA(2)))) {
			{
			if ((LA(1) == WITHIN)) {
				within_clause();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				match(SEMICOLON);
			}
			else if ((_tokenSet_6.member(LA(1)))) {
			}
			else {
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}

			}
			{ // ( ... )*
			for (;;) {
				if ((_tokenSet_7.member(LA(1)))) {
					{
					if ((LA(1) == FINAL)) {
						RefMyAST tmp14_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
						if ( inputState->guessing == 0 ) {
							tmp14_AST = astFactory->create(LT(1));
							astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp14_AST));
						}
						match(FINAL);
					}
					else if ((_tokenSet_0.member(LA(1)))) {
					}
					else {
						throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
					}

					}
					class_definition();
					if (inputState->guessing==0) {
						cd_AST = returnAST;
						astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
					}
					s = LT(1);
					if ( inputState->guessing == 0 ) {
						s_AST = astFactory->create(s);
					}
					match(SEMICOLON);
					if ( inputState->guessing==0 ) {
#line 116 "modelica_parser.g"

									  /* adrpo, fix the end of this AST node */
									  if(cd_AST != NULL)
									  {
								  	/*
								  	std::cout << (#cd)->toString() << std::endl;
								  	std::cout << s->getLine() << ":" << s->getColumn() << std::endl;
								  	*/
										RefMyAST(cd_AST)->setEndLine(s->getLine());
										RefMyAST(cd_AST)->setEndColumn(s->getColumn());
									   }

#line 293 "modelica_parser.cpp"
					}
				}
				else {
					goto _loop14;
				}

			}
			_loop14:;
			} // ( ... )*
			match(ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE);
			if ( inputState->guessing==0 ) {
				stored_definition_AST = RefMyAST(currentAST.root);
#line 130 "modelica_parser.g"

								stored_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(STORED_DEFINITION,"STORED_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(stored_definition_AST))));

#line 310 "modelica_parser.cpp"
				currentAST.root = stored_definition_AST;
				if ( stored_definition_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
					stored_definition_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
					  currentAST.child = stored_definition_AST->getFirstChild();
				else
					currentAST.child = stored_definition_AST;
				currentAST.advanceChildToEnd();
			}
			stored_definition_AST = RefMyAST(currentAST.root);
		}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	returnAST = stored_definition_AST;
}

void modelica_parser::class_type() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_type_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	switch ( LA(1)) {
	case CLASS:
	{
		RefMyAST tmp16_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp16_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp16_AST));
		}
		match(CLASS);
		break;
	}
	case MODEL:
	{
		RefMyAST tmp17_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp17_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp17_AST));
		}
		match(MODEL);
		break;
	}
	case RECORD:
	{
		RefMyAST tmp18_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp18_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp18_AST));
		}
		match(RECORD);
		break;
	}
	case BLOCK:
	{
		RefMyAST tmp19_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp19_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp19_AST));
		}
		match(BLOCK);
		break;
	}
	case CONNECTOR:
	case EXPANDABLE:
	{
		{
		if ((LA(1) == EXPANDABLE)) {
			RefMyAST tmp20_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp20_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp20_AST));
			}
			match(EXPANDABLE);
		}
		else if ((LA(1) == CONNECTOR)) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
		RefMyAST tmp21_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp21_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp21_AST));
		}
		match(CONNECTOR);
		break;
	}
	case TYPE:
	{
		RefMyAST tmp22_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp22_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp22_AST));
		}
		match(TYPE);
		break;
	}
	case PACKAGE:
	{
		RefMyAST tmp23_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp23_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp23_AST));
		}
		match(PACKAGE);
		break;
	}
	case FUNCTION:
	{
		RefMyAST tmp24_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp24_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp24_AST));
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
	class_type_AST = RefMyAST(currentAST.root);
	returnAST = class_type_AST;
}

void modelica_parser::component_clause() {
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

void modelica_parser::import_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST import_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp25_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp25_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp25_AST));
	}
	match(IMPORT);
	{
	if ((LA(1) == IDENT) && (LA(2) == EQUALS)) {
		explicit_import_name();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == STAR || LA(1) == IDENT) && (_tokenSet_8.member(LA(2)))) {
		implicit_import_name();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	import_clause_AST = RefMyAST(currentAST.root);
	returnAST = import_clause_AST;
}

void modelica_parser::within_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST within_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp26_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp26_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp26_AST));
	}
	match(WITHIN);
	{
	if ((LA(1) == IDENT)) {
		name_path();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == SEMICOLON)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	within_clause_AST = RefMyAST(currentAST.root);
	returnAST = within_clause_AST;
}

void modelica_parser::class_definition() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_definition_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	if ((LA(1) == ENCAPSULATED)) {
		RefMyAST tmp27_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp27_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp27_AST));
		}
		match(ENCAPSULATED);
	}
	else if ((_tokenSet_2.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	{
	if ((LA(1) == PARTIAL)) {
		RefMyAST tmp28_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp28_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp28_AST));
		}
		match(PARTIAL);
	}
	else if ((_tokenSet_3.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	class_type();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	class_specifier();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		class_definition_AST = RefMyAST(currentAST.root);
#line 150 "modelica_parser.g"

					class_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CLASS_DEFINITION,"CLASS_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(class_definition_AST))));

#line 594 "modelica_parser.cpp"
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

void modelica_parser::name_path() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST name_path_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	if (((LA(1) == IDENT) && (_tokenSet_9.member(LA(2))))&&( LA(2)!=DOT )) {
		RefMyAST tmp29_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp29_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp29_AST));
		}
		match(IDENT);
		name_path_AST = RefMyAST(currentAST.root);
	}
	else if ((LA(1) == IDENT) && (LA(2) == DOT)) {
		RefMyAST tmp30_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp30_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp30_AST));
		}
		match(IDENT);
		RefMyAST tmp31_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp31_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp31_AST));
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

void modelica_parser::class_specifier() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_specifier_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	if ((LA(1) == IDENT)) {
		RefMyAST tmp32_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp32_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp32_AST));
		}
		match(IDENT);
		class_specifier2();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		class_specifier_AST = RefMyAST(currentAST.root);
	}
	else if ((LA(1) == EXTENDS)) {
		match(EXTENDS);
		RefMyAST tmp34_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp34_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp34_AST));
		}
		match(IDENT);
		{
		if ((LA(1) == LPAR)) {
			class_modification();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else if ((_tokenSet_10.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
		string_comment();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		composition();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		match(END);
		match(IDENT);
		if ( inputState->guessing==0 ) {
			class_specifier_AST = RefMyAST(currentAST.root);
#line 166 "modelica_parser.g"

			class_specifier_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CLASS_EXTENDS,"CLASS_EXTENDS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(class_specifier_AST))));

#line 703 "modelica_parser.cpp"
			currentAST.root = class_specifier_AST;
			if ( class_specifier_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				class_specifier_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = class_specifier_AST->getFirstChild();
			else
				currentAST.child = class_specifier_AST;
			currentAST.advanceChildToEnd();
		}
		class_specifier_AST = RefMyAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	returnAST = class_specifier_AST;
}

void modelica_parser::class_specifier2() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_specifier2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	if ((_tokenSet_10.member(LA(1)))) {
		string_comment();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		composition();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		match(END);
		match(IDENT);
	}
	else if ((LA(1) == EQUALS) && (_tokenSet_11.member(LA(2)))) {
		RefMyAST tmp39_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp39_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp39_AST));
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
		else if ((_tokenSet_12.member(LA(1)))) {
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
		else if ((_tokenSet_13.member(LA(1)))) {
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
		RefMyAST tmp40_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp40_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp40_AST));
		}
		match(EQUALS);
		enumeration();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == EQUALS) && (LA(2) == DER)) {
		RefMyAST tmp41_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp41_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp41_AST));
		}
		match(EQUALS);
		pder();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == EQUALS) && (LA(2) == OVERLOAD)) {
		RefMyAST tmp42_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp42_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp42_AST));
		}
		match(EQUALS);
		overloading();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	class_specifier2_AST = RefMyAST(currentAST.root);
	returnAST = class_specifier2_AST;
}

void modelica_parser::class_modification() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_modification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	match(LPAR);
	{
	if ((_tokenSet_14.member(LA(1)))) {
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
#line 446 "modelica_parser.g"

					class_modification_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CLASS_MODIFICATION,"CLASS_MODIFICATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(class_modification_AST))));

#line 859 "modelica_parser.cpp"
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

void modelica_parser::string_comment() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST string_comment_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	if ((LA(1) == STRING)) {
		RefMyAST tmp45_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp45_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp45_AST));
		}
		match(STRING);
		{
		bool synPredMatched271 = false;
		if (((LA(1) == PLUS))) {
			int _m271 = mark();
			synPredMatched271 = true;
			inputState->guessing++;
			try {
				{
				match(PLUS);
				match(STRING);
				}
			}
			catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
				synPredMatched271 = false;
			}
			rewind(_m271);
			inputState->guessing--;
		}
		if ( synPredMatched271 ) {
			{ // ( ... )+
			int _cnt273=0;
			for (;;) {
				if ((LA(1) == PLUS)) {
					RefMyAST tmp46_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
					if ( inputState->guessing == 0 ) {
						tmp46_AST = astFactory->create(LT(1));
						astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp46_AST));
					}
					match(PLUS);
					RefMyAST tmp47_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
					if ( inputState->guessing == 0 ) {
						tmp47_AST = astFactory->create(LT(1));
						astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp47_AST));
					}
					match(STRING);
				}
				else {
					if ( _cnt273>=1 ) { goto _loop273; } else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());}
				}

				_cnt273++;
			}
			_loop273:;
			}  // ( ... )+
		}
		else if ((_tokenSet_15.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
	}
	else if ((_tokenSet_15.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	if ( inputState->guessing==0 ) {
		string_comment_AST = RefMyAST(currentAST.root);
#line 1059 "modelica_parser.g"

		if (string_comment_AST)
		{
		string_comment_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(STRING_COMMENT,"STRING_COMMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(string_comment_AST))));
		}

#line 954 "modelica_parser.cpp"
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

void modelica_parser::composition() {
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
			goto _loop44;
		}
		}
	}
	_loop44:;
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

void modelica_parser::base_prefix() {
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

void modelica_parser::array_subscripts() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST array_subscripts_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp48_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp48_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp48_AST));
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
			goto _loop262;
		}

	}
	_loop262:;
	} // ( ... )*
	match(RBRACK);
	array_subscripts_AST = RefMyAST(currentAST.root);
	returnAST = array_subscripts_AST;
}

void modelica_parser::comment() {
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
	else if ((_tokenSet_16.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	}
	if ( inputState->guessing==0 ) {
		comment_AST = RefMyAST(currentAST.root);
#line 1052 "modelica_parser.g"

					comment_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(COMMENT,"COMMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(comment_AST))));

#line 1129 "modelica_parser.cpp"
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

void modelica_parser::enumeration() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST enumeration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp51_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp51_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp51_AST));
	}
	match(ENUMERATION);
	match(LPAR);
	{
	if ((LA(1) == IDENT)) {
		enum_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == COLON)) {
		RefMyAST tmp53_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp53_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp53_AST));
		}
		match(COLON);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	match(RPAR);
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	enumeration_AST = RefMyAST(currentAST.root);
	returnAST = enumeration_AST;
}

void modelica_parser::pder() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST pder_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp55_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp55_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp55_AST));
	}
	match(DER);
	match(LPAR);
	name_path();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(COMMA);
	ident_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(RPAR);
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	pder_AST = RefMyAST(currentAST.root);
	returnAST = pder_AST;
}

void modelica_parser::overloading() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST overloading_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp59_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp59_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp59_AST));
	}
	match(OVERLOAD);
	match(LPAR);
	name_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(RPAR);
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	overloading_AST = RefMyAST(currentAST.root);
	returnAST = overloading_AST;
}

void modelica_parser::ident_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST ident_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	if ((LA(1) == IDENT) && (LA(2) == RPAR)) {
		RefMyAST tmp62_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp62_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp62_AST));
		}
		match(IDENT);
		ident_list_AST = RefMyAST(currentAST.root);
	}
	else if ((LA(1) == IDENT) && (LA(2) == COMMA)) {
		RefMyAST tmp63_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp63_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp63_AST));
		}
		match(IDENT);
		match(COMMA);
		ident_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		if ( inputState->guessing==0 ) {
			ident_list_AST = RefMyAST(currentAST.root);
#line 185 "modelica_parser.g"

			ident_list_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(IDENT_LIST,"IDENT_LIST")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(ident_list_AST))));

#line 1270 "modelica_parser.cpp"
			currentAST.root = ident_list_AST;
			if ( ident_list_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				ident_list_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = ident_list_AST->getFirstChild();
			else
				currentAST.child = ident_list_AST;
			currentAST.advanceChildToEnd();
		}
		ident_list_AST = RefMyAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	returnAST = ident_list_AST;
}

void modelica_parser::name_list() {
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
			goto _loop35;
		}

	}
	_loop35:;
	} // ( ... )*
	name_list_AST = RefMyAST(currentAST.root);
	returnAST = name_list_AST;
}

void modelica_parser::type_prefix() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST type_prefix_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	if ((LA(1) == FLOW)) {
		RefMyAST tmp66_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp66_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp66_AST));
		}
		match(FLOW);
	}
	else if ((_tokenSet_17.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	{
	switch ( LA(1)) {
	case DISCRETE:
	{
		RefMyAST tmp67_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp67_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp67_AST));
		}
		match(DISCRETE);
		break;
	}
	case PARAMETER:
	{
		RefMyAST tmp68_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp68_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp68_AST));
		}
		match(PARAMETER);
		break;
	}
	case CONSTANT:
	{
		RefMyAST tmp69_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp69_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp69_AST));
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
		RefMyAST tmp70_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp70_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp70_AST));
		}
		match(INPUT);
		break;
	}
	case OUTPUT:
	{
		RefMyAST tmp71_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp71_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp71_AST));
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

void modelica_parser::enum_list() {
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
			goto _loop40;
		}

	}
	_loop40:;
	} // ( ... )*
	enum_list_AST = RefMyAST(currentAST.root);
	returnAST = enum_list_AST;
}

void modelica_parser::enumeration_literal() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST enumeration_literal_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp73_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp73_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp73_AST));
	}
	match(IDENT);
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		enumeration_literal_AST = RefMyAST(currentAST.root);
#line 212 "modelica_parser.g"

					enumeration_literal_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ENUMERATION_LITERAL,"ENUMERATION_LITERAL")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(enumeration_literal_AST))));

#line 1468 "modelica_parser.cpp"
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

void modelica_parser::element_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)RefToken  s = ANTLR_USE_NAMESPACE(antlr)nullToken;
	RefMyAST s_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_18.member(LA(1)))) {
			{
			if ((_tokenSet_19.member(LA(1)))) {
				element();
				if (inputState->guessing==0) {
					e_AST = returnAST;
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
			else if ((LA(1) == ANNOTATION)) {
				annotation();
				if (inputState->guessing==0) {
					a_AST = returnAST;
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
			else {
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}

			}
			s = LT(1);
			if ( inputState->guessing == 0 ) {
				s_AST = astFactory->create(s);
			}
			match(SEMICOLON);
			if ( inputState->guessing==0 ) {
#line 269 "modelica_parser.g"

						   /* adrpo, fix the end of this AST node */
						   if (e_AST)
						   {
						  	/*
						  	std::cout << (#e)->toString() << std::endl;
						  	std::cout << s->getLine() << ":" << s->getColumn() << std::endl;
						  	*/
							RefMyAST(e_AST)->setEndLine(s->getLine());
							RefMyAST(e_AST)->setEndColumn(s->getColumn());
						   	if (e_AST->getFirstChild())
						   	{
						   	   /*
						  	   std::cout << (#e->getFirstChild())->toString() << std::endl;
						  	   std::cout << s->getLine() << ":" << s->getColumn() << std::endl;
						  	   */
							   RefMyAST(e_AST->getFirstChild())->setEndLine(s->getLine());
							   RefMyAST(e_AST->getFirstChild())->setEndColumn(s->getColumn());
						        }
						   }


#line 1542 "modelica_parser.cpp"
			}
		}
		else {
			goto _loop61;
		}

	}
	_loop61:;
	} // ( ... )*
	element_list_AST = RefMyAST(currentAST.root);
	returnAST = element_list_AST;
}

void modelica_parser::public_element_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST public_element_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp74_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp74_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp74_AST));
	}
	match(PUBLIC);
	element_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	public_element_list_AST = RefMyAST(currentAST.root);
	returnAST = public_element_list_AST;
}

void modelica_parser::protected_element_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST protected_element_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp75_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp75_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp75_AST));
	}
	match(PROTECTED);
	element_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	protected_element_list_AST = RefMyAST(currentAST.root);
	returnAST = protected_element_list_AST;
}

void modelica_parser::initial_equation_clause() {
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
#line 503 "modelica_parser.g"

		initial_equation_clause_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_EQUATION,"INTIAL_EQUATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(ec_AST))));

#line 1614 "modelica_parser.cpp"
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

void modelica_parser::initial_algorithm_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST initial_algorithm_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	if (!( LA(2)==ALGORITHM))
		throw ANTLR_USE_NAMESPACE(antlr)SemanticException(" LA(2)==ALGORITHM");
	match(INITIAL);
	RefMyAST tmp78_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp78_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp78_AST));
	}
	match(ALGORITHM);
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_20.member(LA(1)))) {
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
			goto _loop130;
		}

	}
	_loop130:;
	} // ( ... )*
	if ( inputState->guessing==0 ) {
		initial_algorithm_clause_AST = RefMyAST(currentAST.root);
#line 574 "modelica_parser.g"

			            initial_algorithm_clause_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_ALGORITHM,"INTIAL_ALGORITHM")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(initial_algorithm_clause_AST))));

#line 1670 "modelica_parser.cpp"
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

void modelica_parser::equation_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp81_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp81_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp81_AST));
	}
	match(EQUATION);
	equation_annotation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	equation_clause_AST = RefMyAST(currentAST.root);
	returnAST = equation_clause_AST;
}

void modelica_parser::algorithm_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp82_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp82_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp82_AST));
	}
	match(ALGORITHM);
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_20.member(LA(1)))) {
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
			goto _loop127;
		}

	}
	_loop127:;
	} // ( ... )*
	algorithm_clause_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_clause_AST;
}

void modelica_parser::external_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST external_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp85_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp85_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp85_AST));
	}
	match(EXTERNAL);
	{
	if ((LA(1) == STRING)) {
		language_specification();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == ANNOTATION || LA(1) == SEMICOLON || LA(1) == IDENT)) {
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
	else if ((LA(1) == ANNOTATION || LA(1) == SEMICOLON)) {
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
	}
	else if ((LA(1) == SEMICOLON)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	match(SEMICOLON);
	{
	if ((LA(1) == ANNOTATION)) {
		external_annotation();
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
	external_clause_AST = RefMyAST(currentAST.root);
	returnAST = external_clause_AST;
}

void modelica_parser::language_specification() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST language_specification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp87_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp87_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp87_AST));
	}
	match(STRING);
	language_specification_AST = RefMyAST(currentAST.root);
	returnAST = language_specification_AST;
}

void modelica_parser::external_function_call() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST external_function_call_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	if ((LA(1) == IDENT) && (LA(2) == DOT || LA(2) == LBRACK || LA(2) == EQUALS)) {
		component_reference();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		RefMyAST tmp88_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp88_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp88_AST));
		}
		match(EQUALS);
	}
	else if ((LA(1) == IDENT) && (LA(2) == LPAR)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	RefMyAST tmp89_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp89_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp89_AST));
	}
	match(IDENT);
	match(LPAR);
	{
	if ((_tokenSet_21.member(LA(1)))) {
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
#line 261 "modelica_parser.g"

					external_function_call_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EXTERNAL_FUNCTION_CALL,"EXTERNAL_FUNCTION_CALL")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(external_function_call_AST))));

#line 1880 "modelica_parser.cpp"
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

void modelica_parser::annotation() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST annotation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp92_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp92_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp92_AST));
	}
	match(ANNOTATION);
	class_modification();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	annotation_AST = RefMyAST(currentAST.root);
	returnAST = annotation_AST;
}

void modelica_parser::external_annotation() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST external_annotation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	annotation();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(SEMICOLON);
	if ( inputState->guessing==0 ) {
		external_annotation_AST = RefMyAST(currentAST.root);
#line 240 "modelica_parser.g"

		external_annotation_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EXTERNAL_ANNOTATION,"EXTERNAL_ANNOTATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(external_annotation_AST))));

#line 1928 "modelica_parser.cpp"
		currentAST.root = external_annotation_AST;
		if ( external_annotation_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			external_annotation_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = external_annotation_AST->getFirstChild();
		else
			currentAST.child = external_annotation_AST;
		currentAST.advanceChildToEnd();
	}
	external_annotation_AST = RefMyAST(currentAST.root);
	returnAST = external_annotation_AST;
}

void modelica_parser::component_reference() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_reference_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp94_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp94_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp94_AST));
	}
	match(IDENT);
	{
	if ((LA(1) == LBRACK)) {
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_22.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	{
	if ((LA(1) == DOT)) {
		RefMyAST tmp95_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp95_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp95_AST));
		}
		match(DOT);
		component_reference();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_23.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	component_reference_AST = RefMyAST(currentAST.root);
	returnAST = component_reference_AST;
}

void modelica_parser::expression_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST expression_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	expression_list2();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		expression_list_AST = RefMyAST(currentAST.root);
#line 1031 "modelica_parser.g"

					expression_list_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EXPRESSION_LIST,"EXPRESSION_LIST")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(expression_list_AST))));

#line 2005 "modelica_parser.cpp"
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

void modelica_parser::element() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ic_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ec_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST cc_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST cc2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	switch ( LA(1)) {
	case IMPORT:
	{
		import_clause();
		if (inputState->guessing==0) {
			ic_AST = returnAST;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		element_AST = RefMyAST(currentAST.root);
		break;
	}
	case EXTENDS:
	{
		extends_clause();
		if (inputState->guessing==0) {
			ec_AST = returnAST;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		element_AST = RefMyAST(currentAST.root);
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case CONSTANT:
	case DISCRETE:
	case ENCAPSULATED:
	case EXPANDABLE:
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
	case REDECLARE:
	case REPLACEABLE:
	case TYPE:
	case IDENT:
	{
		{
		if ((LA(1) == REDECLARE)) {
			RefMyAST tmp96_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp96_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp96_AST));
			}
			match(REDECLARE);
		}
		else if ((_tokenSet_24.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
		{
		if ((LA(1) == FINAL)) {
			RefMyAST tmp97_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp97_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp97_AST));
			}
			match(FINAL);
		}
		else if ((_tokenSet_25.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
		{
		if ((LA(1) == INNER)) {
			RefMyAST tmp98_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp98_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp98_AST));
			}
			match(INNER);
		}
		else if ((_tokenSet_26.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
		{
		if ((LA(1) == OUTER)) {
			RefMyAST tmp99_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp99_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp99_AST));
			}
			match(OUTER);
		}
		else if ((_tokenSet_27.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
		{
		if ((_tokenSet_28.member(LA(1)))) {
			{
			if ((_tokenSet_0.member(LA(1)))) {
				class_definition();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
			else if ((_tokenSet_11.member(LA(1)))) {
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
		}
		else if ((LA(1) == REPLACEABLE)) {
			{
			RefMyAST tmp100_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp100_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp100_AST));
			}
			match(REPLACEABLE);
			{
			if ((_tokenSet_0.member(LA(1)))) {
				class_definition();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
			else if ((_tokenSet_11.member(LA(1)))) {
				component_clause();
				if (inputState->guessing==0) {
					cc2_AST = returnAST;
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
			else {
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}

			}
			{
			if ((LA(1) == EXTENDS)) {
				constraining_clause();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				comment();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
			}
			else if ((LA(1) == RPAR || LA(1) == SEMICOLON)) {
			}
			else {
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
			}

			}
			}
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
		if ( inputState->guessing==0 ) {
			element_AST = RefMyAST(currentAST.root);
#line 325 "modelica_parser.g"

						if(cc_AST != null || cc2_AST != null)
						{
							element_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(DECLARATION,"DECLARATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(element_AST))));
						}
						else
						{
							element_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(DEFINITION,"DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(element_AST))));
						}

#line 2223 "modelica_parser.cpp"
			currentAST.root = element_AST;
			if ( element_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				element_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = element_AST->getFirstChild();
			else
				currentAST.child = element_AST;
			currentAST.advanceChildToEnd();
		}
		element_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	returnAST = element_AST;
}

void modelica_parser::extends_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST extends_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp101_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp101_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp101_AST));
	}
	match(EXTENDS);
	name_path();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if ((LA(1) == LPAR)) {
		class_modification();
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
	extends_clause_AST = RefMyAST(currentAST.root);
	returnAST = extends_clause_AST;
}

void modelica_parser::constraining_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST constraining_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	extends_clause();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	constraining_clause_AST = RefMyAST(currentAST.root);
	returnAST = constraining_clause_AST;
}

void modelica_parser::explicit_import_name() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST explicit_import_name_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp102_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp102_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp102_AST));
	}
	match(IDENT);
	RefMyAST tmp103_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp103_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp103_AST));
	}
	match(EQUALS);
	name_path();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	explicit_import_name_AST = RefMyAST(currentAST.root);
	returnAST = explicit_import_name_AST;
}

void modelica_parser::implicit_import_name() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST implicit_import_name_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST np_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 364 "modelica_parser.g"

				bool has_star = false;

#line 2323 "modelica_parser.cpp"

	has_star=name_path_star();
	if (inputState->guessing==0) {
		np_AST = returnAST;
	}
	if ( inputState->guessing==0 ) {
		implicit_import_name_AST = RefMyAST(currentAST.root);
#line 370 "modelica_parser.g"

					if (has_star)
					{
						implicit_import_name_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(UNQUALIFIED,"UNQUALIFIED")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(np_AST))));
					}
					else
					{
						implicit_import_name_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(QUALIFIED,"QUALIFIED")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(np_AST))));
					}

#line 2342 "modelica_parser.cpp"
		currentAST.root = implicit_import_name_AST;
		if ( implicit_import_name_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			implicit_import_name_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = implicit_import_name_AST->getFirstChild();
		else
			currentAST.child = implicit_import_name_AST;
		currentAST.advanceChildToEnd();
	}
	returnAST = implicit_import_name_AST;
}

bool  modelica_parser::name_path_star() {
#line 955 "modelica_parser.g"
	bool val=false;
#line 2357 "modelica_parser.cpp"
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST name_path_star_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)RefToken  i = ANTLR_USE_NAMESPACE(antlr)nullToken;
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST np_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	if (((LA(1) == IDENT) && (_tokenSet_30.member(LA(2))))&&( LA(2)!=DOT )) {
		RefMyAST tmp104_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp104_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp104_AST));
		}
		match(IDENT);
		if ( inputState->guessing==0 ) {
#line 957 "modelica_parser.g"
			val=false;
#line 2375 "modelica_parser.cpp"
		}
		name_path_star_AST = RefMyAST(currentAST.root);
	}
	else if (((LA(1) == STAR))&&( LA(2)!=DOT )) {
		match(STAR);
		if ( inputState->guessing==0 ) {
#line 958 "modelica_parser.g"
			val=true;
#line 2384 "modelica_parser.cpp"
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
		RefMyAST tmp106_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp106_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp106_AST));
		}
		match(DOT);
		val=name_path_star();
		if (inputState->guessing==0) {
			np_AST = returnAST;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		if ( inputState->guessing==0 ) {
			name_path_star_AST = RefMyAST(currentAST.root);
#line 960 "modelica_parser.g"

						if(!(np_AST))
						{
							name_path_star_AST = i_AST;
						}

#line 2415 "modelica_parser.cpp"
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

void modelica_parser::type_specifier() {
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

void modelica_parser::component_list() {
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
			goto _loop88;
		}

	}
	_loop88:;
	} // ( ... )*
	component_list_AST = RefMyAST(currentAST.root);
	returnAST = component_list_AST;
}

void modelica_parser::component_declaration() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_declaration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	declaration();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if ((LA(1) == IF)) {
		conditional_attribute();
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
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	component_declaration_AST = RefMyAST(currentAST.root);
	returnAST = component_declaration_AST;
}

void modelica_parser::declaration() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST declaration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp108_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp108_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp108_AST));
	}
	match(IDENT);
	{
	if ((LA(1) == LBRACK)) {
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_31.member(LA(1)))) {
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
	else if ((_tokenSet_32.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	declaration_AST = RefMyAST(currentAST.root);
	returnAST = declaration_AST;
}

void modelica_parser::conditional_attribute() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST conditional_attribute_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp109_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp109_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp109_AST));
	}
	match(IF);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	conditional_attribute_AST = RefMyAST(currentAST.root);
	returnAST = conditional_attribute_AST;
}

void modelica_parser::expression() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	switch ( LA(1)) {
	case IF:
	{
		if_expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case DER:
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
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case CODE:
	{
		code_expression();
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
	expression_AST = RefMyAST(currentAST.root);
	returnAST = expression_AST;
}

void modelica_parser::modification() {
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
		else if ((_tokenSet_32.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
		break;
	}
	case EQUALS:
	{
		RefMyAST tmp111_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp111_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp111_AST));
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
		RefMyAST tmp112_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp112_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp112_AST));
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

void modelica_parser::argument_list() {
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
			goto _loop102;
		}

	}
	_loop102:;
	} // ( ... )*
	if ( inputState->guessing==0 ) {
		argument_list_AST = RefMyAST(currentAST.root);
#line 454 "modelica_parser.g"

					argument_list_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ARGUMENT_LIST,"ARGUMENT_LIST")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(argument_list_AST))));

#line 2723 "modelica_parser.cpp"
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

void modelica_parser::argument() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST argument_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST em_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST er_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	if ((_tokenSet_33.member(LA(1)))) {
		element_modification_or_replaceable();
		if (inputState->guessing==0) {
			em_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			argument_AST = RefMyAST(currentAST.root);
#line 461 "modelica_parser.g"

						argument_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ELEMENT_MODIFICATION,"ELEMENT_MODIFICATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(em_AST))));

#line 2755 "modelica_parser.cpp"
			currentAST.root = argument_AST;
			if ( argument_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				argument_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = argument_AST->getFirstChild();
			else
				currentAST.child = argument_AST;
			currentAST.advanceChildToEnd();
		}
	}
	else if ((LA(1) == REDECLARE)) {
		element_redeclaration();
		if (inputState->guessing==0) {
			er_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			argument_AST = RefMyAST(currentAST.root);
#line 465 "modelica_parser.g"

						argument_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ELEMENT_REDECLARATION,"ELEMENT_REDECLARATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(er_AST))));
#line 2775 "modelica_parser.cpp"
			currentAST.root = argument_AST;
			if ( argument_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				argument_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = argument_AST->getFirstChild();
			else
				currentAST.child = argument_AST;
			currentAST.advanceChildToEnd();
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	returnAST = argument_AST;
}

void modelica_parser::element_modification_or_replaceable() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_modification_or_replaceable_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	if ((LA(1) == EACH)) {
		RefMyAST tmp114_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp114_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp114_AST));
		}
		match(EACH);
	}
	else if ((LA(1) == FINAL || LA(1) == REPLACEABLE || LA(1) == IDENT)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	{
	if ((LA(1) == FINAL)) {
		RefMyAST tmp115_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp115_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp115_AST));
		}
		match(FINAL);
	}
	else if ((LA(1) == REPLACEABLE || LA(1) == IDENT)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	{
	if ((LA(1) == IDENT)) {
		element_modification();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == REPLACEABLE)) {
		element_replaceable();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	element_modification_or_replaceable_AST = RefMyAST(currentAST.root);
	returnAST = element_modification_or_replaceable_AST;
}

void modelica_parser::element_redeclaration() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_redeclaration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp116_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp116_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp116_AST));
	}
	match(REDECLARE);
	{
	if ((LA(1) == EACH)) {
		RefMyAST tmp117_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp117_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp117_AST));
		}
		match(EACH);
	}
	else if ((_tokenSet_34.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	{
	if ((LA(1) == FINAL)) {
		RefMyAST tmp118_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp118_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp118_AST));
		}
		match(FINAL);
	}
	else if ((_tokenSet_27.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	{
	if ((_tokenSet_28.member(LA(1)))) {
		{
		if ((_tokenSet_0.member(LA(1)))) {
			class_definition();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else if ((_tokenSet_11.member(LA(1)))) {
			component_clause1();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
	}
	else if ((LA(1) == REPLACEABLE)) {
		element_replaceable();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	element_redeclaration_AST = RefMyAST(currentAST.root);
	returnAST = element_redeclaration_AST;
}

void modelica_parser::element_modification() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_modification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

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

void modelica_parser::element_replaceable() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_replaceable_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp119_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp119_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp119_AST));
	}
	match(REPLACEABLE);
	{
	if ((_tokenSet_0.member(LA(1)))) {
		class_definition();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_11.member(LA(1)))) {
		component_clause1();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	{
	if ((LA(1) == EXTENDS)) {
		constraining_clause();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		comment();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == RPAR || LA(1) == COMMA)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	element_replaceable_AST = RefMyAST(currentAST.root);
	returnAST = element_replaceable_AST;
}

void modelica_parser::component_clause1() {
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
	component_declaration1();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	component_clause1_AST = RefMyAST(currentAST.root);
	returnAST = component_clause1_AST;
}

void modelica_parser::component_declaration1() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_declaration1_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	declaration();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	component_declaration1_AST = RefMyAST(currentAST.root);
	returnAST = component_declaration1_AST;
}

void modelica_parser::equation_annotation_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_annotation_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	if (((_tokenSet_35.member(LA(1))) && (_tokenSet_36.member(LA(2))))&&( LA(1) == END || LA(1) == EQUATION || LA(1) == ALGORITHM || LA(1)==INITIAL
		 || LA(1) == PROTECTED || LA(1) == PUBLIC )) {
		equation_annotation_list_AST = RefMyAST(currentAST.root);
	}
	else if ((_tokenSet_37.member(LA(1))) && (_tokenSet_38.member(LA(2)))) {
		{
		if ((_tokenSet_39.member(LA(1)))) {
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

void modelica_parser::equation() {
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
	case CONNECT:
	{
		connect_clause();
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
		bool synPredMatched134 = false;
		if (((_tokenSet_40.member(LA(1))) && (_tokenSet_38.member(LA(2))))) {
			int _m134 = mark();
			synPredMatched134 = true;
			inputState->guessing++;
			try {
				{
				simple_expression();
				match(EQUALS);
				}
			}
			catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
				synPredMatched134 = false;
			}
			rewind(_m134);
			inputState->guessing--;
		}
		if ( synPredMatched134 ) {
			equality_equation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else if ((LA(1) == IDENT) && (LA(2) == LPAR)) {
			RefMyAST tmp122_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp122_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp122_AST));
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
#line 607 "modelica_parser.g"

		equation_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EQUATION_STATEMENT,"EQUATION_STATEMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(equation_AST))));

#line 3180 "modelica_parser.cpp"
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

void modelica_parser::algorithm() {
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
#line 641 "modelica_parser.g"

		algorithm_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ALGORITHM_STATEMENT,"ALGORITHM_STATEMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(algorithm_AST))));

#line 3268 "modelica_parser.cpp"
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

void modelica_parser::simple_expression() {
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
		RefMyAST tmp123_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp123_AST = astFactory->create(LT(1));
		}
		match(COLON);
		logical_expression();
		if (inputState->guessing==0) {
			l2_AST = returnAST;
		}
		{
		if ((LA(1) == COLON)) {
			RefMyAST tmp124_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp124_AST = astFactory->create(LT(1));
			}
			match(COLON);
			logical_expression();
			if (inputState->guessing==0) {
				l3_AST = returnAST;
			}
		}
		else if ((_tokenSet_41.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
	}
	else if ((_tokenSet_41.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	if ( inputState->guessing==0 ) {
		simple_expression_AST = RefMyAST(currentAST.root);
#line 801 "modelica_parser.g"

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

#line 3348 "modelica_parser.cpp"
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

void modelica_parser::equality_equation() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equality_equation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	simple_expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	RefMyAST tmp125_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp125_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp125_AST));
	}
	match(EQUALS);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	equality_equation_AST = RefMyAST(currentAST.root);
	returnAST = equality_equation_AST;
}

void modelica_parser::conditional_equation_e() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST conditional_equation_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp126_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp126_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp126_AST));
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
			goto _loop143;
		}

	}
	_loop143:;
	} // ( ... )*
	{
	if ((LA(1) == ELSE)) {
		RefMyAST tmp128_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp128_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp128_AST));
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

void modelica_parser::for_clause_e() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_clause_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp131_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp131_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp131_AST));
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

void modelica_parser::connect_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST connect_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp135_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp135_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp135_AST));
	}
	match(CONNECT);
	match(LPAR);
	connector_ref();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(COMMA);
	connector_ref();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(RPAR);
	connect_clause_AST = RefMyAST(currentAST.root);
	returnAST = connect_clause_AST;
}

void modelica_parser::when_clause_e() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST when_clause_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp139_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp139_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp139_AST));
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
			goto _loop154;
		}

	}
	_loop154:;
	} // ( ... )*
	match(END);
	match(WHEN);
	when_clause_e_AST = RefMyAST(currentAST.root);
	returnAST = when_clause_e_AST;
}

void modelica_parser::function_call() {
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
#line 974 "modelica_parser.g"

					function_call_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(FUNCTION_ARGUMENTS,"FUNCTION_ARGUMENTS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(function_call_AST))));

#line 3556 "modelica_parser.cpp"
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

void modelica_parser::assign_clause_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST assign_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	component_reference();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if ((LA(1) == ASSIGN)) {
		RefMyAST tmp145_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp145_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp145_AST));
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

void modelica_parser::multi_assign_clause_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST multi_assign_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	match(LPAR);
	expression_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	match(RPAR);
	RefMyAST tmp148_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp148_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp148_AST));
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

void modelica_parser::conditional_equation_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST conditional_equation_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp149_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp149_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp149_AST));
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
			goto _loop147;
		}

	}
	_loop147:;
	} // ( ... )*
	{
	if ((LA(1) == ELSE)) {
		RefMyAST tmp151_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp151_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp151_AST));
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

void modelica_parser::for_clause_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp154_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp154_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp154_AST));
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

void modelica_parser::while_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST while_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp158_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp158_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp158_AST));
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

void modelica_parser::when_clause_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST when_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp162_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp162_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp162_AST));
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
			goto _loop158;
		}

	}
	_loop158:;
	} // ( ... )*
	match(END);
	match(WHEN);
	when_clause_a_AST = RefMyAST(currentAST.root);
	returnAST = when_clause_a_AST;
}

void modelica_parser::equation_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	if ((((LA(1) >= ELSE && LA(1) <= END)) && (_tokenSet_42.member(LA(2))))&&(LA(1) != END || (LA(1) == END && LA(2) != IDENT))) {
		equation_list_AST = RefMyAST(currentAST.root);
	}
	else if ((_tokenSet_39.member(LA(1))) && (_tokenSet_38.member(LA(2)))) {
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

void modelica_parser::equation_elseif() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_elseif_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp167_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp167_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp167_AST));
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

void modelica_parser::algorithm_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_20.member(LA(1)))) {
			algorithm();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
		}
		else {
			goto _loop166;
		}

	}
	_loop166:;
	} // ( ... )*
	algorithm_list_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_list_AST;
}

void modelica_parser::algorithm_elseif() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_elseif_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp170_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp170_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp170_AST));
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

void modelica_parser::for_indices() {
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

void modelica_parser::else_when_e() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST else_when_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp172_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp172_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp172_AST));
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

void modelica_parser::else_when_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST else_when_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp174_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp174_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp174_AST));
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

void modelica_parser::connector_ref() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST connector_ref_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp176_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp176_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp176_AST));
	}
	match(IDENT);
	{
	if ((LA(1) == LBRACK)) {
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == DOT || LA(1) == RPAR || LA(1) == COMMA)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	{
	if ((LA(1) == DOT)) {
		RefMyAST tmp177_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp177_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp177_AST));
		}
		match(DOT);
		connector_ref_2();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == RPAR || LA(1) == COMMA)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	connector_ref_AST = RefMyAST(currentAST.root);
	returnAST = connector_ref_AST;
}

void modelica_parser::connector_ref_2() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST connector_ref_2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp178_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp178_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp178_AST));
	}
	match(IDENT);
	{
	if ((LA(1) == LBRACK)) {
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((LA(1) == RPAR || LA(1) == COMMA)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	connector_ref_2_AST = RefMyAST(currentAST.root);
	returnAST = connector_ref_2_AST;
}

void modelica_parser::if_expression() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST if_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp179_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp179_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp179_AST));
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
			goto _loop177;
		}

	}
	_loop177:;
	} // ( ... )*
	match(ELSE);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if_expression_AST = RefMyAST(currentAST.root);
	returnAST = if_expression_AST;
}

void modelica_parser::code_expression() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST code_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST m_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ieq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST alg_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ialg_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp182_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp182_AST = astFactory->create(LT(1));
	}
	match(CODE);
	RefMyAST tmp183_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp183_AST = astFactory->create(LT(1));
	}
	match(LPAR);
	{
	bool synPredMatched191 = false;
	if (((_tokenSet_21.member(LA(1))) && (_tokenSet_43.member(LA(2))))) {
		int _m191 = mark();
		synPredMatched191 = true;
		inputState->guessing++;
		try {
			{
			expression();
			match(RPAR);
			}
		}
		catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
			synPredMatched191 = false;
		}
		rewind(_m191);
		inputState->guessing--;
	}
	if ( synPredMatched191 ) {
		expression();
		if (inputState->guessing==0) {
			e_AST = returnAST;
		}
	}
	else if ((LA(1) == LPAR || LA(1) == EQUALS || LA(1) == ASSIGN) && (_tokenSet_44.member(LA(2)))) {
		modification();
		if (inputState->guessing==0) {
			m_AST = returnAST;
		}
	}
	else if ((_tokenSet_19.member(LA(1))) && (_tokenSet_45.member(LA(2)))) {
		element();
		if (inputState->guessing==0) {
			el_AST = returnAST;
		}
		{
		if ((LA(1) == SEMICOLON)) {
			match(SEMICOLON);
		}
		else if ((LA(1) == RPAR)) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
	}
	else if ((LA(1) == EQUATION)) {
		code_equation_clause();
		if (inputState->guessing==0) {
			eq_AST = returnAST;
		}
	}
	else if ((LA(1) == INITIAL) && (LA(2) == EQUATION)) {
		code_initial_equation_clause();
		if (inputState->guessing==0) {
			ieq_AST = returnAST;
		}
	}
	else if ((LA(1) == ALGORITHM)) {
		code_algorithm_clause();
		if (inputState->guessing==0) {
			alg_AST = returnAST;
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
	RefMyAST tmp185_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp185_AST = astFactory->create(LT(1));
	}
	match(RPAR);
	if ( inputState->guessing==0 ) {
		code_expression_AST = RefMyAST(currentAST.root);
#line 822 "modelica_parser.g"

					if (e_AST) {
						code_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CODE_EXPRESSION,"CODE_EXPRESSION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST))));
					} else if (m_AST) {
						code_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CODE_MODIFICATION,"CODE_MODIFICATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(m_AST))));
					} else if (el_AST) {
						code_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CODE_ELEMENT,"CODE_ELEMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(el_AST))));
					} else if (eq_AST) {
						code_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CODE_EQUATION,"CODE_EQUATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(eq_AST))));
					} else if (ieq_AST) {
						code_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CODE_INITIALEQUATION,"CODE_EQUATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(ieq_AST))));
					} else if (alg_AST) {
						code_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CODE_ALGORITHM,"CODE_ALGORITHM")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(alg_AST))));
					} else if (ialg_AST) {
						code_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CODE_INITIALALGORITHM,"CODE_ALGORITHM")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(ialg_AST))));
					}

#line 4201 "modelica_parser.cpp"
		currentAST.root = code_expression_AST;
		if ( code_expression_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			code_expression_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = code_expression_AST->getFirstChild();
		else
			currentAST.child = code_expression_AST;
		currentAST.advanceChildToEnd();
	}
	returnAST = code_expression_AST;
}

void modelica_parser::elseif_expression() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST elseif_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp186_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp186_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp186_AST));
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

void modelica_parser::for_index() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_index_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	RefMyAST tmp188_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp188_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp188_AST));
	}
	match(IDENT);
	{
	if ((LA(1) == IN)) {
		RefMyAST tmp189_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp189_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp189_AST));
		}
		match(IN);
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_46.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	}
	for_index_AST = RefMyAST(currentAST.root);
	returnAST = for_index_AST;
}

void modelica_parser::for_indices2() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_indices2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	if (((_tokenSet_47.member(LA(1))))&&(LA(2) != IN)) {
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

void modelica_parser::logical_expression() {
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
			RefMyAST tmp191_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp191_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp191_AST));
			}
			match(OR);
			logical_term();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop206;
		}

	}
	_loop206:;
	} // ( ... )*
	logical_expression_AST = RefMyAST(currentAST.root);
	returnAST = logical_expression_AST;
}

void modelica_parser::code_equation_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST code_equation_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	RefMyAST tmp192_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp192_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp192_AST));
	}
	match(EQUATION);
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_39.member(LA(1)))) {
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
			goto _loop196;
		}

	}
	_loop196:;
	} // ( ... )*
	}
	code_equation_clause_AST = RefMyAST(currentAST.root);
	returnAST = code_equation_clause_AST;
}

void modelica_parser::code_initial_equation_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST code_initial_equation_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ec_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	if (!( LA(2)==EQUATION))
		throw ANTLR_USE_NAMESPACE(antlr)SemanticException(" LA(2)==EQUATION");
	match(INITIAL);
	code_equation_clause();
	if (inputState->guessing==0) {
		ec_AST = returnAST;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		code_initial_equation_clause_AST = RefMyAST(currentAST.root);
#line 848 "modelica_parser.g"

		code_initial_equation_clause_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_EQUATION,"INTIAL_EQUATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(ec_AST))));

#line 4397 "modelica_parser.cpp"
		currentAST.root = code_initial_equation_clause_AST;
		if ( code_initial_equation_clause_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			code_initial_equation_clause_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = code_initial_equation_clause_AST->getFirstChild();
		else
			currentAST.child = code_initial_equation_clause_AST;
		currentAST.advanceChildToEnd();
	}
	code_initial_equation_clause_AST = RefMyAST(currentAST.root);
	returnAST = code_initial_equation_clause_AST;
}

void modelica_parser::code_algorithm_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST code_algorithm_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp196_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp196_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp196_AST));
	}
	match(ALGORITHM);
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_20.member(LA(1)))) {
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
			goto _loop200;
		}

	}
	_loop200:;
	} // ( ... )*
	code_algorithm_clause_AST = RefMyAST(currentAST.root);
	returnAST = code_algorithm_clause_AST;
}

void modelica_parser::code_initial_algorithm_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST code_initial_algorithm_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	if (!( LA(2) == ALGORITHM ))
		throw ANTLR_USE_NAMESPACE(antlr)SemanticException(" LA(2) == ALGORITHM ");
	match(INITIAL);
	RefMyAST tmp200_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp200_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp200_AST));
	}
	match(ALGORITHM);
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_20.member(LA(1)))) {
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
			goto _loop203;
		}

	}
	_loop203:;
	} // ( ... )*
	if ( inputState->guessing==0 ) {
		code_initial_algorithm_clause_AST = RefMyAST(currentAST.root);
#line 862 "modelica_parser.g"

					code_initial_algorithm_clause_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_ALGORITHM,"INTIAL_ALGORITHM")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(code_initial_algorithm_clause_AST))));

#line 4491 "modelica_parser.cpp"
		currentAST.root = code_initial_algorithm_clause_AST;
		if ( code_initial_algorithm_clause_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
			code_initial_algorithm_clause_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			  currentAST.child = code_initial_algorithm_clause_AST->getFirstChild();
		else
			currentAST.child = code_initial_algorithm_clause_AST;
		currentAST.advanceChildToEnd();
	}
	code_initial_algorithm_clause_AST = RefMyAST(currentAST.root);
	returnAST = code_initial_algorithm_clause_AST;
}

void modelica_parser::logical_term() {
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
			RefMyAST tmp203_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp203_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp203_AST));
			}
			match(AND);
			logical_factor();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop209;
		}

	}
	_loop209:;
	} // ( ... )*
	logical_term_AST = RefMyAST(currentAST.root);
	returnAST = logical_term_AST;
}

void modelica_parser::logical_factor() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST logical_factor_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	if ((LA(1) == NOT)) {
		RefMyAST tmp204_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp204_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp204_AST));
		}
		match(NOT);
	}
	else if ((_tokenSet_48.member(LA(1)))) {
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

void modelica_parser::relation() {
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
			RefMyAST tmp205_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp205_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp205_AST));
			}
			match(LESS);
			break;
		}
		case LESSEQ:
		{
			RefMyAST tmp206_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp206_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp206_AST));
			}
			match(LESSEQ);
			break;
		}
		case GREATER:
		{
			RefMyAST tmp207_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp207_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp207_AST));
			}
			match(GREATER);
			break;
		}
		case GREATEREQ:
		{
			RefMyAST tmp208_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp208_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp208_AST));
			}
			match(GREATEREQ);
			break;
		}
		case EQEQ:
		{
			RefMyAST tmp209_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp209_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp209_AST));
			}
			match(EQEQ);
			break;
		}
		case LESSGT:
		{
			RefMyAST tmp210_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp210_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp210_AST));
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
	else if ((_tokenSet_49.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	relation_AST = RefMyAST(currentAST.root);
	returnAST = relation_AST;
}

void modelica_parser::arithmetic_expression() {
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
				RefMyAST tmp211_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp211_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp211_AST));
				}
				match(PLUS);
			}
			else if ((LA(1) == MINUS)) {
				RefMyAST tmp212_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp212_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp212_AST));
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
			goto _loop220;
		}

	}
	_loop220:;
	} // ( ... )*
	arithmetic_expression_AST = RefMyAST(currentAST.root);
	returnAST = arithmetic_expression_AST;
}

void modelica_parser::rel_op() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST rel_op_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	switch ( LA(1)) {
	case LESS:
	{
		RefMyAST tmp213_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp213_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp213_AST));
		}
		match(LESS);
		break;
	}
	case LESSEQ:
	{
		RefMyAST tmp214_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp214_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp214_AST));
		}
		match(LESSEQ);
		break;
	}
	case GREATER:
	{
		RefMyAST tmp215_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp215_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp215_AST));
		}
		match(GREATER);
		break;
	}
	case GREATEREQ:
	{
		RefMyAST tmp216_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp216_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp216_AST));
		}
		match(GREATEREQ);
		break;
	}
	case EQEQ:
	{
		RefMyAST tmp217_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp217_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp217_AST));
		}
		match(EQEQ);
		break;
	}
	case LESSGT:
	{
		RefMyAST tmp218_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp218_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp218_AST));
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

void modelica_parser::unary_arithmetic_expression() {
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
		RefMyAST tmp219_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp219_AST = astFactory->create(LT(1));
		}
		match(PLUS);
		term();
		if (inputState->guessing==0) {
			t1_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = RefMyAST(currentAST.root);
#line 896 "modelica_parser.g"

						unary_arithmetic_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(UNARY_PLUS,"PLUS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(t1_AST))));

#line 4816 "modelica_parser.cpp"
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
		RefMyAST tmp220_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp220_AST = astFactory->create(LT(1));
		}
		match(MINUS);
		term();
		if (inputState->guessing==0) {
			t2_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = RefMyAST(currentAST.root);
#line 900 "modelica_parser.g"

						unary_arithmetic_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(UNARY_MINUS,"MINUS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(t2_AST))));

#line 4844 "modelica_parser.cpp"
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
	case DER:
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
#line 904 "modelica_parser.g"

						unary_arithmetic_expression_AST = t3_AST;

#line 4878 "modelica_parser.cpp"
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

void modelica_parser::term() {
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
				RefMyAST tmp221_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp221_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp221_AST));
				}
				match(STAR);
			}
			else if ((LA(1) == SLASH)) {
				RefMyAST tmp222_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp222_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp222_AST));
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
			goto _loop226;
		}

	}
	_loop226:;
	} // ( ... )*
	term_AST = RefMyAST(currentAST.root);
	returnAST = term_AST;
}

void modelica_parser::factor() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST factor_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	primary();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if ((LA(1) == POWER)) {
		RefMyAST tmp223_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp223_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp223_AST));
		}
		match(POWER);
		primary();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
	}
	else if ((_tokenSet_50.member(LA(1)))) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	}
	factor_AST = RefMyAST(currentAST.root);
	returnAST = factor_AST;
}

void modelica_parser::primary() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST primary_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	switch ( LA(1)) {
	case UNSIGNED_INTEGER:
	{
		RefMyAST tmp224_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp224_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp224_AST));
		}
		match(UNSIGNED_INTEGER);
		break;
	}
	case UNSIGNED_REAL:
	{
		RefMyAST tmp225_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp225_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp225_AST));
		}
		match(UNSIGNED_REAL);
		break;
	}
	case STRING:
	{
		RefMyAST tmp226_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp226_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp226_AST));
		}
		match(STRING);
		break;
	}
	case FALSE:
	{
		RefMyAST tmp227_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp227_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp227_AST));
		}
		match(FALSE);
		break;
	}
	case TRUE:
	{
		RefMyAST tmp228_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp228_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp228_AST));
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
	case DER:
	{
		RefMyAST tmp229_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp229_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp229_AST));
		}
		match(DER);
		function_call();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case LPAR:
	{
		RefMyAST tmp230_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp230_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp230_AST));
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
		RefMyAST tmp232_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp232_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp232_AST));
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
				goto _loop232;
			}

		}
		_loop232:;
		} // ( ... )*
		match(RBRACK);
		break;
	}
	case LBRACE:
	{
		RefMyAST tmp235_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp235_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp235_AST));
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
		RefMyAST tmp237_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp237_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp237_AST));
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

void modelica_parser::component_reference__function_call() {
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
		else if ((_tokenSet_51.member(LA(1)))) {
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}

		}
		if ( inputState->guessing==0 ) {
			component_reference__function_call_AST = RefMyAST(currentAST.root);
#line 935 "modelica_parser.g"

						if (fc_AST != null)
						{
							component_reference__function_call_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(3))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(FUNCTION_CALL,"FUNCTION_CALL")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(cr_AST))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(fc_AST))));
						}
						else
						{
							component_reference__function_call_AST = cr_AST;
						}

#line 5183 "modelica_parser.cpp"
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
#line 945 "modelica_parser.g"

						component_reference__function_call_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_FUNCTION_CALL,"INITIAL_FUNCTION_CALL")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST))));

#line 5207 "modelica_parser.cpp"
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

void modelica_parser::for_or_expression_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_or_expression_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST explist_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST forind_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	{
	if (((LA(1) == RPAR || LA(1) == RBRACE || LA(1) == IDENT) && (_tokenSet_51.member(LA(2))))&&(LA(1)==IDENT && LA(2) == EQUALS|| LA(1) == RPAR)) {
	}
	else if ((_tokenSet_21.member(LA(1))) && (_tokenSet_52.member(LA(2)))) {
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
			RefMyAST tmp241_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp241_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp241_AST));
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
#line 995 "modelica_parser.g"

			if (forind_AST != null) {
			for_or_expression_list_AST =
			RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(FOR_ITERATOR,"FOR_ITERATOR")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(for_or_expression_list_AST))));
			}
			else {
			for_or_expression_list_AST =
			RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EXPRESSION_LIST,"EXPRESSION_LIST")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(for_or_expression_list_AST))));
			}

#line 5295 "modelica_parser.cpp"
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

void modelica_parser::function_arguments() {
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

void modelica_parser::named_arguments() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST named_arguments_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	named_arguments2();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		named_arguments_AST = RefMyAST(currentAST.root);
#line 1016 "modelica_parser.g"

					named_arguments_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(NAMED_ARGUMENTS,"NAMED_ARGUMENTS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(named_arguments_AST))));

#line 5358 "modelica_parser.cpp"
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

void modelica_parser::for_or_expression_list2() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_or_expression_list2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	if (((LA(1) == RPAR || LA(1) == RBRACE || LA(1) == IDENT) && (_tokenSet_51.member(LA(2))))&&(LA(2) == EQUALS)) {
		for_or_expression_list2_AST = RefMyAST(currentAST.root);
	}
	else if ((_tokenSet_21.member(LA(1))) && (_tokenSet_53.member(LA(2)))) {
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

void modelica_parser::named_arguments2() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST named_arguments2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	named_argument();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	bool synPredMatched255 = false;
	if (((LA(1) == COMMA))) {
		int _m255 = mark();
		synPredMatched255 = true;
		inputState->guessing++;
		try {
			{
			match(COMMA);
			match(IDENT);
			match(EQUALS);
			}
		}
		catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
			synPredMatched255 = false;
		}
		rewind(_m255);
		inputState->guessing--;
	}
	if ( synPredMatched255 ) {
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

void modelica_parser::named_argument() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST named_argument_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	RefMyAST tmp244_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp244_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp244_AST));
	}
	match(IDENT);
	RefMyAST tmp245_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp245_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp245_AST));
	}
	match(EQUALS);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	named_argument_AST = RefMyAST(currentAST.root);
	returnAST = named_argument_AST;
}

void modelica_parser::expression_list2() {
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

void modelica_parser::subscript() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST subscript_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);

	if ((_tokenSet_21.member(LA(1)))) {
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		subscript_AST = RefMyAST(currentAST.root);
	}
	else if ((LA(1) == COLON)) {
		RefMyAST tmp247_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp247_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp247_AST));
		}
		match(COLON);
		subscript_AST = RefMyAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}

	returnAST = subscript_AST;
}

void modelica_parser::initializeASTFactory( ANTLR_USE_NAMESPACE(antlr)ASTFactory& factory )
{
	factory.setMaxNodeType(146);
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
	"\"Code\"",
	"\"class\"",
	"\"connect\"",
	"\"connector\"",
	"\"constant\"",
	"\"discrete\"",
	"\"der\"",
	"\"each\"",
	"\"else\"",
	"\"elseif\"",
	"\"elsewhen\"",
	"\"end\"",
	"\"enumeration\"",
	"\"equation\"",
	"\"encapsulated\"",
	"\"expandable\"",
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
	"\".\"",
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
	"an identifier",
	"NONDIGIT",
	"DIGIT",
	"EXPONENT",
	"UNSIGNED_INTEGER",
	"STRING",
	"SCHAR",
	"QCHAR",
	"SESCAPE",
	"ESC",
	"ALGORITHM_STATEMENT",
	"ARGUMENT_LIST",
	"BEGIN_DEFINITION",
	"CLASS_DEFINITION",
	"CLASS_EXTENDS",
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
	"EXTERNAL_ANNOTATION",
	"INITIAL_EQUATION",
	"INITIAL_ALGORITHM",
	"IMPORT_DEFINITION",
	"IDENT_LIST",
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

const unsigned long modelica_parser::_tokenSet_0_data_[] = { 1086327424UL, 8540224UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "encapsulated" "expandable" "function" "model"
// "package" "partial" "record" "type"
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_0(_tokenSet_0_data_,6);
const unsigned long modelica_parser::_tokenSet_1_data_[] = { 1082133120UL, 8540224UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "expandable" "function" "model" "package"
// "partial" "record" "type" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_1(_tokenSet_1_data_,8);
const unsigned long modelica_parser::_tokenSet_2_data_[] = { 1082133120UL, 8540224UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "expandable" "function" "model" "package"
// "partial" "record" "type"
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_2(_tokenSet_2_data_,6);
const unsigned long modelica_parser::_tokenSet_3_data_[] = { 1082133120UL, 8523840UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "expandable" "function" "model" "package"
// "record" "type"
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_3(_tokenSet_3_data_,6);
const unsigned long modelica_parser::_tokenSet_4_data_[] = { 1220545154UL, 276975680UL, 0UL, 0UL, 0UL, 0UL };
// EOF "block" "class" "connector" "encapsulated" "expandable" "final"
// "function" "model" "package" "partial" "record" "type" "within"
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_4(_tokenSet_4_data_,6);
const unsigned long modelica_parser::_tokenSet_5_data_[] = { 1103104642UL, 8540224UL, 268566528UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// EOF "block" "class" "connector" "encapsulated" "expandable" "extends"
// "function" "model" "package" "partial" "record" "type" SEMICOLON IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_5(_tokenSet_5_data_,8);
const unsigned long modelica_parser::_tokenSet_6_data_[] = { 1220545154UL, 8540224UL, 0UL, 0UL, 0UL, 0UL };
// EOF "block" "class" "connector" "encapsulated" "expandable" "final"
// "function" "model" "package" "partial" "record" "type"
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_6(_tokenSet_6_data_,6);
const unsigned long modelica_parser::_tokenSet_7_data_[] = { 1220545152UL, 8540224UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "encapsulated" "expandable" "final" "function"
// "model" "package" "partial" "record" "type"
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_7(_tokenSet_7_data_,6);
const unsigned long modelica_parser::_tokenSet_8_data_[] = { 64UL, 1107296256UL, 131072UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "." RPAR SEMICOLON STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_8(_tokenSet_8_data_,8);
const unsigned long modelica_parser::_tokenSet_9_data_[] = { 16777280UL, 3758096384UL, 268567040UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "extends" LPAR RPAR LBRACK COMMA SEMICOLON IDENT STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_9(_tokenSet_9_data_,8);
const unsigned long modelica_parser::_tokenSet_10_data_[] = { 1541946064UL, 9435485UL, 268435456UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "annotation" "block" "class" "connector" "constant" "discrete"
// "end" "equation" "encapsulated" "expandable" "extends" "external" "final"
// "flow" "function" "import" "initial" "inner" "input" "model" "outer"
// "output" "package" "parameter" "partial" "protected" "public" "record"
// "redeclare" "replaceable" "type" IDENT STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_10(_tokenSet_10_data_,8);
const unsigned long modelica_parser::_tokenSet_11_data_[] = { 268447744UL, 10256UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "constant" "discrete" "flow" "input" "output" "parameter" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_11(_tokenSet_11_data_,8);
const unsigned long modelica_parser::_tokenSet_12_data_[] = { 16777280UL, 1610612736UL, 131584UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "extends" LPAR RPAR COMMA SEMICOLON STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_12(_tokenSet_12_data_,8);
const unsigned long modelica_parser::_tokenSet_13_data_[] = { 16777280UL, 1073741824UL, 131584UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "extends" RPAR COMMA SEMICOLON STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_13(_tokenSet_13_data_,8);
const unsigned long modelica_parser::_tokenSet_14_data_[] = { 134250496UL, 786432UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "each" "final" "redeclare" "replaceable" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_14(_tokenSet_14_data_,8);
const unsigned long modelica_parser::_tokenSet_15_data_[] = { 1541946064UL, 1083177309UL, 268567040UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "annotation" "block" "class" "connector" "constant" "discrete"
// "end" "equation" "encapsulated" "expandable" "extends" "external" "final"
// "flow" "function" "import" "initial" "inner" "input" "model" "outer"
// "output" "package" "parameter" "partial" "protected" "public" "record"
// "redeclare" "replaceable" "type" RPAR COMMA SEMICOLON IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_15(_tokenSet_15_data_,8);
const unsigned long modelica_parser::_tokenSet_16_data_[] = { 16777216UL, 1073741824UL, 131584UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "extends" RPAR COMMA SEMICOLON
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_16(_tokenSet_16_data_,8);
const unsigned long modelica_parser::_tokenSet_17_data_[] = { 12288UL, 10256UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "constant" "discrete" "input" "output" "parameter" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_17(_tokenSet_17_data_,8);
const unsigned long modelica_parser::_tokenSet_18_data_[] = { 1505770176UL, 9337177UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "block" "class" "connector" "constant" "discrete" "encapsulated"
// "expandable" "extends" "final" "flow" "function" "import" "inner" "input"
// "model" "outer" "output" "package" "parameter" "partial" "record" "redeclare"
// "replaceable" "type" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_18(_tokenSet_18_data_,8);
const unsigned long modelica_parser::_tokenSet_19_data_[] = { 1505770112UL, 9337177UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "constant" "discrete" "encapsulated" "expandable"
// "extends" "final" "flow" "function" "import" "inner" "input" "model"
// "outer" "output" "package" "parameter" "partial" "record" "redeclare"
// "replaceable" "type" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_19(_tokenSet_19_data_,8);
const unsigned long modelica_parser::_tokenSet_20_data_[] = { 2684354560UL, 738197504UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "for" "if" "when" "while" LPAR IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_20(_tokenSet_20_data_,8);
const unsigned long modelica_parser::_tokenSet_21_data_[] = { 2215133440UL, 2705326212UL, 268435554UL, 6UL, 0UL, 0UL, 0UL, 0UL };
// "Code" "der" "end" "false" "if" "initial" "not" "true" "unsigned_real"
// LPAR LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_21(_tokenSet_21_data_,8);
const unsigned long modelica_parser::_tokenSet_22_data_[] = { 2701328480UL, 1646265376UL, 268959741UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "and" "annotation" "else" "elseif" "extends" "for" "if" "loop" "or"
// "then" "." LPAR RPAR RBRACK RBRACE EQUALS ASSIGN PLUS MINUS STAR SLASH
// COMMA LESS LESSEQ GREATER GREATEREQ EQEQ LESSGT COLON SEMICOLON POWER
// IDENT STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_22(_tokenSet_22_data_,8);
const unsigned long modelica_parser::_tokenSet_23_data_[] = { 2701328480UL, 1612710944UL, 268959741UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "and" "annotation" "else" "elseif" "extends" "for" "if" "loop" "or"
// "then" LPAR RPAR RBRACK RBRACE EQUALS ASSIGN PLUS MINUS STAR SLASH COMMA
// LESS LESSEQ GREATER GREATEREQ EQEQ LESSGT COLON SEMICOLON POWER IDENT
// STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_23(_tokenSet_23_data_,8);
const unsigned long modelica_parser::_tokenSet_24_data_[] = { 1488992896UL, 9075032UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "constant" "discrete" "encapsulated" "expandable"
// "final" "flow" "function" "inner" "input" "model" "outer" "output" "package"
// "parameter" "partial" "record" "replaceable" "type" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_24(_tokenSet_24_data_,8);
const unsigned long modelica_parser::_tokenSet_25_data_[] = { 1354775168UL, 9075032UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "constant" "discrete" "encapsulated" "expandable"
// "flow" "function" "inner" "input" "model" "outer" "output" "package"
// "parameter" "partial" "record" "replaceable" "type" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_25(_tokenSet_25_data_,8);
const unsigned long modelica_parser::_tokenSet_26_data_[] = { 1354775168UL, 9075024UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "constant" "discrete" "encapsulated" "expandable"
// "flow" "function" "input" "model" "outer" "output" "package" "parameter"
// "partial" "record" "replaceable" "type" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_26(_tokenSet_26_data_,8);
const unsigned long modelica_parser::_tokenSet_27_data_[] = { 1354775168UL, 9074768UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "constant" "discrete" "encapsulated" "expandable"
// "flow" "function" "input" "model" "output" "package" "parameter" "partial"
// "record" "replaceable" "type" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_27(_tokenSet_27_data_,8);
const unsigned long modelica_parser::_tokenSet_28_data_[] = { 1354775168UL, 8550480UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "constant" "discrete" "encapsulated" "expandable"
// "flow" "function" "input" "model" "output" "package" "parameter" "partial"
// "record" "type" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_28(_tokenSet_28_data_,8);
const unsigned long modelica_parser::_tokenSet_29_data_[] = { 64UL, 1073741824UL, 131584UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" RPAR COMMA SEMICOLON STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_29(_tokenSet_29_data_,8);
const unsigned long modelica_parser::_tokenSet_30_data_[] = { 64UL, 1073741824UL, 131072UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" RPAR SEMICOLON STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_30(_tokenSet_30_data_,8);
const unsigned long modelica_parser::_tokenSet_31_data_[] = { 2164260928UL, 1610612736UL, 131608UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "extends" "if" LPAR RPAR EQUALS ASSIGN COMMA SEMICOLON
// STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_31(_tokenSet_31_data_,8);
const unsigned long modelica_parser::_tokenSet_32_data_[] = { 2164260928UL, 1073741824UL, 131584UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "extends" "if" RPAR COMMA SEMICOLON STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_32(_tokenSet_32_data_,8);
const unsigned long modelica_parser::_tokenSet_33_data_[] = { 134250496UL, 524288UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "each" "final" "replaceable" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_33(_tokenSet_33_data_,8);
const unsigned long modelica_parser::_tokenSet_34_data_[] = { 1488992896UL, 9074768UL, 268435456UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "constant" "discrete" "encapsulated" "expandable"
// "final" "flow" "function" "input" "model" "output" "package" "parameter"
// "partial" "record" "replaceable" "type" IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_34(_tokenSet_34_data_,8);
const unsigned long modelica_parser::_tokenSet_35_data_[] = { 36175888UL, 98308UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "end" "equation" "external" "initial" "protected" "public"
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_35(_tokenSet_35_data_,6);
const unsigned long modelica_parser::_tokenSet_36_data_[] = { 4293426896UL, 2916088285UL, 268566626UL, 6UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "annotation" "block" "class" "connect" "connector" "constant"
// "discrete" "der" "end" "equation" "encapsulated" "expandable" "extends"
// "external" "false" "final" "flow" "for" "function" "if" "import" "initial"
// "inner" "input" "model" "not" "outer" "output" "package" "parameter"
// "partial" "protected" "public" "record" "redeclare" "replaceable" "true"
// "type" "unsigned_real" "when" "while" LPAR LBRACK LBRACE PLUS MINUS
// SEMICOLON IDENT UNSIGNED_INTEGER STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_36(_tokenSet_36_data_,8);
const unsigned long modelica_parser::_tokenSet_37_data_[] = { 2752005184UL, 2772435076UL, 268435554UL, 6UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "connect" "der" "end" "false" "for" "if" "initial" "not"
// "true" "unsigned_real" "when" LPAR LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER
// STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_37(_tokenSet_37_data_,8);
const unsigned long modelica_parser::_tokenSet_38_data_[] = { 2215133472UL, 2738881668UL, 268828142UL, 6UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "der" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real"
// "." LPAR LBRACK LBRACE RBRACE EQUALS PLUS MINUS STAR SLASH LESS LESSEQ
// GREATER GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_38(_tokenSet_38_data_,8);
const unsigned long modelica_parser::_tokenSet_39_data_[] = { 2752005120UL, 2772435076UL, 268435554UL, 6UL, 0UL, 0UL, 0UL, 0UL };
// "connect" "der" "end" "false" "for" "if" "initial" "not" "true" "unsigned_real"
// "when" LPAR LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_39(_tokenSet_39_data_,8);
const unsigned long modelica_parser::_tokenSet_40_data_[] = { 67649536UL, 2705326212UL, 268435554UL, 6UL, 0UL, 0UL, 0UL, 0UL };
// "der" "end" "false" "initial" "not" "true" "unsigned_real" LPAR LBRACK
// LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_40(_tokenSet_40_data_,8);
const unsigned long modelica_parser::_tokenSet_41_data_[] = { 2701328448UL, 1075839008UL, 268567053UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "else" "elseif" "extends" "for" "if" "loop" "then" RPAR
// RBRACK RBRACE EQUALS COMMA SEMICOLON IDENT STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_41(_tokenSet_41_data_,8);
const unsigned long modelica_parser::_tokenSet_42_data_[] = { 2752005376UL, 2772435076UL, 268435554UL, 6UL, 0UL, 0UL, 0UL, 0UL };
// "Code" "connect" "der" "end" "false" "for" "if" "initial" "not" "true"
// "unsigned_real" "when" LPAR LBRACK LBRACE PLUS MINUS IDENT UNSIGNED_INTEGER
// STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_42(_tokenSet_42_data_,8);
const unsigned long modelica_parser::_tokenSet_43_data_[] = { 2215133472UL, 3812623492UL, 268828134UL, 6UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "der" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real"
// "." LPAR RPAR LBRACK LBRACE RBRACE PLUS MINUS STAR SLASH LESS LESSEQ
// GREATER GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_43(_tokenSet_43_data_,8);
const unsigned long modelica_parser::_tokenSet_44_data_[] = { 2349383936UL, 3779854468UL, 268435554UL, 6UL, 0UL, 0UL, 0UL, 0UL };
// "Code" "der" "each" "end" "false" "final" "if" "initial" "not" "redeclare"
// "replaceable" "true" "unsigned_real" LPAR RPAR LBRACK LBRACE PLUS MINUS
// IDENT UNSIGNED_INTEGER STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_44(_tokenSet_44_data_,8);
const unsigned long modelica_parser::_tokenSet_45_data_[] = { 1505770112UL, 2190113112UL, 268435584UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "constant" "discrete" "encapsulated" "expandable"
// "extends" "final" "flow" "function" "inner" "input" "model" "outer"
// "output" "package" "parameter" "partial" "record" "replaceable" "type"
// "." LBRACK STAR IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_45(_tokenSet_45_data_,8);
const unsigned long modelica_parser::_tokenSet_46_data_[] = { 0UL, 1073741856UL, 268435972UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "loop" RPAR RBRACE COMMA IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_46(_tokenSet_46_data_,8);
const unsigned long modelica_parser::_tokenSet_47_data_[] = { 0UL, 1073741856UL, 268435460UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "loop" RPAR RBRACE IDENT
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_47(_tokenSet_47_data_,8);
const unsigned long modelica_parser::_tokenSet_48_data_[] = { 67649536UL, 2705326084UL, 268435554UL, 6UL, 0UL, 0UL, 0UL, 0UL };
// "der" "end" "false" "initial" "true" "unsigned_real" LPAR LBRACK LBRACE
// PLUS MINUS IDENT UNSIGNED_INTEGER STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_48(_tokenSet_48_data_,8);
const unsigned long modelica_parser::_tokenSet_49_data_[] = { 2701328480UL, 1075840032UL, 268632589UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "and" "annotation" "else" "elseif" "extends" "for" "if" "loop" "or"
// "then" RPAR RBRACK RBRACE EQUALS COMMA COLON SEMICOLON IDENT STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_49(_tokenSet_49_data_,8);
const unsigned long modelica_parser::_tokenSet_50_data_[] = { 2701328480UL, 1075840032UL, 268697581UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "and" "annotation" "else" "elseif" "extends" "for" "if" "loop" "or"
// "then" RPAR RBRACK RBRACE EQUALS PLUS MINUS STAR SLASH COMMA LESS LESSEQ
// GREATER GREATEREQ EQEQ LESSGT COLON SEMICOLON IDENT STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_50(_tokenSet_50_data_,8);
const unsigned long modelica_parser::_tokenSet_51_data_[] = { 2701328480UL, 1075840032UL, 268959725UL, 4UL, 0UL, 0UL, 0UL, 0UL };
// "and" "annotation" "else" "elseif" "extends" "for" "if" "loop" "or"
// "then" RPAR RBRACK RBRACE EQUALS PLUS MINUS STAR SLASH COMMA LESS LESSEQ
// GREATER GREATEREQ EQEQ LESSGT COLON SEMICOLON POWER IDENT STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_51(_tokenSet_51_data_,8);
const unsigned long modelica_parser::_tokenSet_52_data_[] = { 2752004384UL, 3812623492UL, 268828646UL, 6UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "der" "end" "false" "for" "if" "initial" "not" "or" "true"
// "unsigned_real" "." LPAR RPAR LBRACK LBRACE RBRACE PLUS MINUS STAR SLASH
// COMMA LESS LESSEQ GREATER GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER
// STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_52(_tokenSet_52_data_,8);
const unsigned long modelica_parser::_tokenSet_53_data_[] = { 2215133472UL, 3812623492UL, 268828646UL, 6UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "der" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real"
// "." LPAR RPAR LBRACK LBRACE RBRACE PLUS MINUS STAR SLASH COMMA LESS
// LESSEQ GREATER GREATEREQ EQEQ LESSGT COLON POWER IDENT UNSIGNED_INTEGER
// STRING
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_53(_tokenSet_53_data_,8);



/* $ANTLR 2.7.7 (2006-11-01): "modelica_parser.g" -> "modelica_parser.cpp"$ */
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
#line 97 "modelica_parser.g"
			
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
	case STREAM:
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
#line 103 "modelica_parser.g"
			
			stored_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(COMPONENT_DEFINITION,"COMPONENT_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(stored_definition_AST))));
			
#line 93 "modelica_parser.cpp"
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
#line 109 "modelica_parser.g"
			
			stored_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(IMPORT_DEFINITION,"IMPORT_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(stored_definition_AST))));
			
#line 119 "modelica_parser.cpp"
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
				switch ( LA(1)) {
				case ENCAPSULATED:
				{
					match(ENCAPSULATED);
					break;
				}
				case BLOCK:
				case CLASS:
				case CONNECTOR:
				case EXPANDABLE:
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
					match(PARTIAL);
					break;
				}
				case BLOCK:
				case CLASS:
				case CONNECTOR:
				case EXPANDABLE:
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
			switch ( LA(1)) {
			case ENCAPSULATED:
			{
				RefMyAST tmp9_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp9_AST = astFactory->create(LT(1));
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp9_AST));
				}
				match(ENCAPSULATED);
				break;
			}
			case BLOCK:
			case CLASS:
			case CONNECTOR:
			case EXPANDABLE:
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
				RefMyAST tmp10_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp10_AST = astFactory->create(LT(1));
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp10_AST));
				}
				match(PARTIAL);
				break;
			}
			case BLOCK:
			case CLASS:
			case CONNECTOR:
			case EXPANDABLE:
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
#line 92 "modelica_parser.g"
				
				stored_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(BEGIN_DEFINITION,"BEGIN_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(stored_definition_AST))));
				
#line 282 "modelica_parser.cpp"
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
		else if ((_tokenSet_2.member(LA(1))) && (_tokenSet_3.member(LA(2)))) {
			{
			switch ( LA(1)) {
			case WITHIN:
			{
				within_clause();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				match(SEMICOLON);
				break;
			}
			case ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE:
			case BLOCK:
			case CLASS:
			case CONNECTOR:
			case ENCAPSULATED:
			case EXPANDABLE:
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
				if ((_tokenSet_4.member(LA(1)))) {
					{
					switch ( LA(1)) {
					case FINAL:
					{
						RefMyAST tmp14_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
						if ( inputState->guessing == 0 ) {
							tmp14_AST = astFactory->create(LT(1));
							astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp14_AST));
						}
						match(FINAL);
						break;
					}
					case BLOCK:
					case CLASS:
					case CONNECTOR:
					case ENCAPSULATED:
					case EXPANDABLE:
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
						cd_AST = returnAST;
						astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
					}
					s = LT(1);
					if ( inputState->guessing == 0 ) {
						s_AST = astFactory->create(s);
					}
					match(SEMICOLON);
					if ( inputState->guessing==0 ) {
#line 117 "modelica_parser.g"
						
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
									
#line 386 "modelica_parser.cpp"
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
#line 131 "modelica_parser.g"
				
								stored_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(STORED_DEFINITION,"STORED_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(stored_definition_AST))));
							
#line 403 "modelica_parser.cpp"
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
		switch ( LA(1)) {
		case EXPANDABLE:
		{
			RefMyAST tmp20_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp20_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp20_AST));
			}
			match(EXPANDABLE);
			break;
		}
		case CONNECTOR:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
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
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
	else if ((LA(1) == IDENT) && (_tokenSet_5.member(LA(2)))) {
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
	switch ( LA(1)) {
	case IDENT:
	{
		name_path();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
	within_clause_AST = RefMyAST(currentAST.root);
	returnAST = within_clause_AST;
}

void modelica_parser::class_definition() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_definition_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	switch ( LA(1)) {
	case ENCAPSULATED:
	{
		RefMyAST tmp27_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp27_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp27_AST));
		}
		match(ENCAPSULATED);
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case EXPANDABLE:
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
		RefMyAST tmp28_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp28_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp28_AST));
		}
		match(PARTIAL);
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case EXPANDABLE:
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
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	class_specifier();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		class_definition_AST = RefMyAST(currentAST.root);
#line 151 "modelica_parser.g"
		
					class_definition_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CLASS_DEFINITION,"CLASS_DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(class_definition_AST))));
				
#line 734 "modelica_parser.cpp"
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
	
	if (((LA(1) == IDENT) && (_tokenSet_6.member(LA(2))))&&( LA(2)!=DOT )) {
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
	
	switch ( LA(1)) {
	case IDENT:
	{
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
		break;
	}
	case EXTENDS:
	{
		match(EXTENDS);
		RefMyAST tmp34_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp34_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp34_AST));
		}
		match(IDENT);
		{
		switch ( LA(1)) {
		case LPAR:
		{
			class_modification();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
		case EXPANDABLE:
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
		case REDECLARE:
		case REPLACEABLE:
		case TYPE:
		case STREAM:
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
#line 163 "modelica_parser.g"
			
			class_specifier_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CLASS_EXTENDS,"CLASS_EXTENDS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(class_specifier_AST))));
			
#line 887 "modelica_parser.cpp"
			currentAST.root = class_specifier_AST;
			if ( class_specifier_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				class_specifier_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				  currentAST.child = class_specifier_AST->getFirstChild();
			else
				currentAST.child = class_specifier_AST;
			currentAST.advanceChildToEnd();
		}
		class_specifier_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	returnAST = class_specifier_AST;
}

void modelica_parser::class_specifier2() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_specifier2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if ((_tokenSet_7.member(LA(1)))) {
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
	else if ((LA(1) == EQUALS) && (_tokenSet_8.member(LA(2)))) {
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
		switch ( LA(1)) {
		case LBRACK:
		{
			array_subscripts();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case ANNOTATION:
		case EXTENDS:
		case CONSTRAINEDBY:
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
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case ANNOTATION:
		case EXTENDS:
		case CONSTRAINEDBY:
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
	switch ( LA(1)) {
	case EACH:
	case FINAL:
	case REDECLARE:
	case REPLACEABLE:
	case IDENT:
	{
		argument_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
		class_modification_AST = RefMyAST(currentAST.root);
#line 424 "modelica_parser.g"
		
					class_modification_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(CLASS_MODIFICATION,"CLASS_MODIFICATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(class_modification_AST))));
				
#line 1080 "modelica_parser.cpp"
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
	switch ( LA(1)) {
	case STRING:
	{
		RefMyAST tmp45_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp45_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp45_AST));
		}
		match(STRING);
		{
		switch ( LA(1)) {
		case PLUS:
		{
			{ // ( ... )+
			int _cnt274=0;
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
					if ( _cnt274>=1 ) { goto _loop274; } else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());}
				}
				
				_cnt274++;
			}
			_loop274:;
			}  // ( ... )+
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
		case EXPANDABLE:
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
		case REDECLARE:
		case REPLACEABLE:
		case TYPE:
		case CONSTRAINEDBY:
		case STREAM:
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
	case EXPANDABLE:
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
	case REDECLARE:
	case REPLACEABLE:
	case TYPE:
	case CONSTRAINEDBY:
	case STREAM:
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
		string_comment_AST = RefMyAST(currentAST.root);
#line 969 "modelica_parser.g"
		
		if (string_comment_AST)
		{
		string_comment_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(STRING_COMMENT,"STRING_COMMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(string_comment_AST))));
		}
				
#line 1244 "modelica_parser.cpp"
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
	switch ( LA(1)) {
	case EXTERNAL:
	{
		external_clause();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
			goto _loop263;
		}
		
	}
	_loop263:;
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
	switch ( LA(1)) {
	case ANNOTATION:
	{
		annotation();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case EXTENDS:
	case CONSTRAINEDBY:
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
		comment_AST = RefMyAST(currentAST.root);
#line 962 "modelica_parser.g"
		
					comment_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(COMMENT,"COMMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(comment_AST))));
				
#line 1435 "modelica_parser.cpp"
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
	switch ( LA(1)) {
	case IDENT:
	{
		enum_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case COLON:
	{
		RefMyAST tmp53_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp53_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp53_AST));
		}
		match(COLON);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
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
#line 182 "modelica_parser.g"
			
			ident_list_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(IDENT_LIST,"IDENT_LIST")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(ident_list_AST))));
			
#line 1582 "modelica_parser.cpp"
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
	switch ( LA(1)) {
	case FLOW:
	{
		RefMyAST tmp66_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp66_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp66_AST));
		}
		match(FLOW);
		break;
	}
	case STREAM:
	{
		RefMyAST tmp67_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp67_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp67_AST));
		}
		match(STREAM);
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
		RefMyAST tmp68_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp68_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp68_AST));
		}
		match(DISCRETE);
		break;
	}
	case PARAMETER:
	{
		RefMyAST tmp69_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp69_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp69_AST));
		}
		match(PARAMETER);
		break;
	}
	case CONSTANT:
	{
		RefMyAST tmp70_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp70_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp70_AST));
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
		RefMyAST tmp71_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp71_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp71_AST));
		}
		match(INPUT);
		break;
	}
	case OUTPUT:
	{
		RefMyAST tmp72_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp72_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp72_AST));
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
	
	RefMyAST tmp74_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp74_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp74_AST));
	}
	match(IDENT);
	comment();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		enumeration_literal_AST = RefMyAST(currentAST.root);
#line 209 "modelica_parser.g"
		
					enumeration_literal_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ENUMERATION_LITERAL,"ENUMERATION_LITERAL")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(enumeration_literal_AST))));
				
#line 1801 "modelica_parser.cpp"
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
		if ((_tokenSet_9.member(LA(1)))) {
			{
			switch ( LA(1)) {
			case BLOCK:
			case CLASS:
			case CONNECTOR:
			case CONSTANT:
			case DISCRETE:
			case ENCAPSULATED:
			case EXPANDABLE:
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
			case REDECLARE:
			case REPLACEABLE:
			case TYPE:
			case STREAM:
			case IDENT:
			{
				element();
				if (inputState->guessing==0) {
					e_AST = returnAST;
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				break;
			}
			case ANNOTATION:
			{
				annotation();
				if (inputState->guessing==0) {
					a_AST = returnAST;
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
			s = LT(1);
			if ( inputState->guessing == 0 ) {
				s_AST = astFactory->create(s);
			}
			match(SEMICOLON);
			if ( inputState->guessing==0 ) {
#line 266 "modelica_parser.g"
				
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
				
						
#line 1906 "modelica_parser.cpp"
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
	
	RefMyAST tmp75_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp75_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp75_AST));
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
	
	RefMyAST tmp76_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp76_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp76_AST));
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
#line 481 "modelica_parser.g"
		
		initial_equation_clause_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_EQUATION,"INTIAL_EQUATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(ec_AST))));
		
#line 1978 "modelica_parser.cpp"
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
	RefMyAST ac_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (!( LA(2)==ALGORITHM ))
		throw ANTLR_USE_NAMESPACE(antlr)SemanticException(" LA(2)==ALGORITHM ");
	match(INITIAL);
	algorithm_clause();
	if (inputState->guessing==0) {
		ac_AST = returnAST;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	if ( inputState->guessing==0 ) {
		initial_algorithm_clause_AST = RefMyAST(currentAST.root);
#line 527 "modelica_parser.g"
		
		initial_algorithm_clause_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_ALGORITHM,"INTIAL_ALGORITHM")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(ac_AST))));
		
#line 2011 "modelica_parser.cpp"
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
	
	RefMyAST tmp79_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp79_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp79_AST));
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
	
	RefMyAST tmp80_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp80_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp80_AST));
	}
	match(ALGORITHM);
	algorithm_annotation_list();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	algorithm_clause_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_clause_AST;
}

void modelica_parser::external_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST external_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp81_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp81_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp81_AST));
	}
	match(EXTERNAL);
	{
	switch ( LA(1)) {
	case STRING:
	{
		language_specification();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case ANNOTATION:
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
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case ANNOTATION:
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
	case ANNOTATION:
	{
		annotation();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
	match(SEMICOLON);
	{
	switch ( LA(1)) {
	case ANNOTATION:
	{
		external_annotation();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
	external_clause_AST = RefMyAST(currentAST.root);
	returnAST = external_clause_AST;
}

void modelica_parser::language_specification() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST language_specification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp83_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp83_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp83_AST));
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
	if ((LA(1) == IDENT) && (_tokenSet_10.member(LA(2)))) {
		component_reference();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		RefMyAST tmp84_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp84_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp84_AST));
		}
		match(EQUALS);
	}
	else if ((LA(1) == IDENT) && (LA(2) == LPAR)) {
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	}
	RefMyAST tmp85_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp85_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp85_AST));
	}
	match(IDENT);
	match(LPAR);
	{
	switch ( LA(1)) {
	case CODE:
	case DER:
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
	case PLUS_EW:
	case MINUS_EW:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	{
		expression_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
		external_function_call_AST = RefMyAST(currentAST.root);
#line 258 "modelica_parser.g"
		
					external_function_call_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EXTERNAL_FUNCTION_CALL,"EXTERNAL_FUNCTION_CALL")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(external_function_call_AST))));
				
#line 2253 "modelica_parser.cpp"
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
	
	RefMyAST tmp88_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp88_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp88_AST));
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
#line 237 "modelica_parser.g"
		
		external_annotation_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EXTERNAL_ANNOTATION,"EXTERNAL_ANNOTATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(external_annotation_AST))));
		
#line 2301 "modelica_parser.cpp"
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
	
	RefMyAST tmp90_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp90_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp90_AST));
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case AND:
	case ANNOTATION:
	case ELSE:
	case ELSEIF:
	case EXTENDS:
	case FOR:
	case IF:
	case LOOP:
	case OR:
	case THEN:
	case DOT:
	case CONSTRAINEDBY:
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
	case POWER:
	case PLUS_EW:
	case MINUS_EW:
	case STAR_EW:
	case SLASH_EW:
	case POWER_EW:
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
	{
	switch ( LA(1)) {
	case DOT:
	{
		RefMyAST tmp91_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp91_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp91_AST));
		}
		match(DOT);
		component_reference();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case AND:
	case ANNOTATION:
	case ELSE:
	case ELSEIF:
	case EXTENDS:
	case FOR:
	case IF:
	case LOOP:
	case OR:
	case THEN:
	case CONSTRAINEDBY:
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
	case POWER:
	case PLUS_EW:
	case MINUS_EW:
	case STAR_EW:
	case SLASH_EW:
	case POWER_EW:
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
#line 941 "modelica_parser.g"
		
					expression_list_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EXPRESSION_LIST,"EXPRESSION_LIST")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(expression_list_AST))));
				
#line 2465 "modelica_parser.cpp"
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
	case STREAM:
	case IDENT:
	{
		{
		switch ( LA(1)) {
		case REDECLARE:
		{
			RefMyAST tmp92_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp92_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp92_AST));
			}
			match(REDECLARE);
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
		case REPLACEABLE:
		case TYPE:
		case STREAM:
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
			RefMyAST tmp93_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp93_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp93_AST));
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
		case EXPANDABLE:
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
		case STREAM:
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
			RefMyAST tmp94_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp94_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp94_AST));
			}
			match(INNER);
			break;
		}
		case BLOCK:
		case CLASS:
		case CONNECTOR:
		case CONSTANT:
		case DISCRETE:
		case ENCAPSULATED:
		case EXPANDABLE:
		case FLOW:
		case FUNCTION:
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
		case STREAM:
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
		case OUTER:
		{
			RefMyAST tmp95_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp95_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp95_AST));
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
		case EXPANDABLE:
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
		case STREAM:
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
		case EXPANDABLE:
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
		case STREAM:
		case IDENT:
		{
			{
			switch ( LA(1)) {
			case BLOCK:
			case CLASS:
			case CONNECTOR:
			case ENCAPSULATED:
			case EXPANDABLE:
			case FUNCTION:
			case MODEL:
			case PACKAGE:
			case PARTIAL:
			case RECORD:
			case TYPE:
			{
				class_definition();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				break;
			}
			case CONSTANT:
			case DISCRETE:
			case FLOW:
			case INPUT:
			case OUTPUT:
			case PARAMETER:
			case STREAM:
			case IDENT:
			{
				component_clause();
				if (inputState->guessing==0) {
					cc_AST = returnAST;
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
			break;
		}
		case REPLACEABLE:
		{
			{
			RefMyAST tmp96_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp96_AST = astFactory->create(LT(1));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp96_AST));
			}
			match(REPLACEABLE);
			{
			switch ( LA(1)) {
			case BLOCK:
			case CLASS:
			case CONNECTOR:
			case ENCAPSULATED:
			case EXPANDABLE:
			case FUNCTION:
			case MODEL:
			case PACKAGE:
			case PARTIAL:
			case RECORD:
			case TYPE:
			{
				class_definition();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				break;
			}
			case CONSTANT:
			case DISCRETE:
			case FLOW:
			case INPUT:
			case OUTPUT:
			case PARAMETER:
			case STREAM:
			case IDENT:
			{
				component_clause();
				if (inputState->guessing==0) {
					cc2_AST = returnAST;
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
			{
			switch ( LA(1)) {
			case EXTENDS:
			case CONSTRAINEDBY:
			{
				constraining_clause();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				}
				comment();
				if (inputState->guessing==0) {
					astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
			element_AST = RefMyAST(currentAST.root);
#line 322 "modelica_parser.g"
			
						if(cc_AST != null || cc2_AST != null)
						{
							element_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(DECLARATION,"DECLARATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(element_AST))));
						}
						else
						{
							element_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(DEFINITION,"DEFINITION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(element_AST))));
						}
					
#line 2868 "modelica_parser.cpp"
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
	
	RefMyAST tmp97_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp97_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp97_AST));
	}
	match(EXTENDS);
	name_path();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	switch ( LA(1)) {
	case LPAR:
	{
		class_modification();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
	extends_clause_AST = RefMyAST(currentAST.root);
	returnAST = extends_clause_AST;
}

void modelica_parser::constraining_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST constraining_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	switch ( LA(1)) {
	case EXTENDS:
	{
		extends_clause();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		constraining_clause_AST = RefMyAST(currentAST.root);
		break;
	}
	case CONSTRAINEDBY:
	{
		RefMyAST tmp98_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp98_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp98_AST));
		}
		match(CONSTRAINEDBY);
		name_path();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		switch ( LA(1)) {
		case LPAR:
		{
			class_modification();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
		constraining_clause_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	}
	returnAST = constraining_clause_AST;
}

void modelica_parser::explicit_import_name() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST explicit_import_name_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp99_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp99_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp99_AST));
	}
	match(IDENT);
	RefMyAST tmp100_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp100_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp100_AST));
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
#line 342 "modelica_parser.g"
	
				bool has_star = false;
			
#line 3027 "modelica_parser.cpp"
	
	has_star=name_path_star();
	if (inputState->guessing==0) {
		np_AST = returnAST;
	}
	if ( inputState->guessing==0 ) {
		implicit_import_name_AST = RefMyAST(currentAST.root);
#line 348 "modelica_parser.g"
		
					if (has_star)
					{
						implicit_import_name_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(UNQUALIFIED,"UNQUALIFIED")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(np_AST))));
					}
					else
					{
						implicit_import_name_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(QUALIFIED,"QUALIFIED")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(np_AST))));
					}
				
#line 3046 "modelica_parser.cpp"
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
#line 873 "modelica_parser.g"
	bool val=false;
#line 3061 "modelica_parser.cpp"
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST name_path_star_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)RefToken  i = ANTLR_USE_NAMESPACE(antlr)nullToken;
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST np_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (((LA(1) == IDENT) && (_tokenSet_11.member(LA(2))))&&( LA(2) != DOT )) {
		RefMyAST tmp101_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp101_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp101_AST));
		}
		match(IDENT);
		if ( inputState->guessing==0 ) {
#line 875 "modelica_parser.g"
			val=false;
#line 3079 "modelica_parser.cpp"
		}
		{
		switch ( LA(1)) {
		case STAR_EW:
		{
			match(STAR_EW);
			if ( inputState->guessing==0 ) {
#line 875 "modelica_parser.g"
				val=true;
#line 3089 "modelica_parser.cpp"
			}
			break;
		}
		case ANNOTATION:
		case RPAR:
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
		name_path_star_AST = RefMyAST(currentAST.root);
	}
	else if ((LA(1) == IDENT) && (LA(2) == DOT)) {
		i = LT(1);
		if ( inputState->guessing == 0 ) {
			i_AST = astFactory->create(i);
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		}
		match(IDENT);
		RefMyAST tmp103_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp103_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp103_AST));
		}
		match(DOT);
		val=name_path_star();
		if (inputState->guessing==0) {
			np_AST = returnAST;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		if ( inputState->guessing==0 ) {
			name_path_star_AST = RefMyAST(currentAST.root);
#line 876 "modelica_parser.g"
			if(!(np_AST))	{ name_path_star_AST = i_AST;	}
#line 3130 "modelica_parser.cpp"
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
			goto _loop89;
		}
		
	}
	_loop89:;
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
	switch ( LA(1)) {
	case IF:
	{
		conditional_attribute();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case ANNOTATION:
	case EXTENDS:
	case CONSTRAINEDBY:
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
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	component_declaration_AST = RefMyAST(currentAST.root);
	returnAST = component_declaration_AST;
}

void modelica_parser::declaration() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST declaration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp105_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp105_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp105_AST));
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case ANNOTATION:
	case EXTENDS:
	case IF:
	case CONSTRAINEDBY:
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
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case ANNOTATION:
	case EXTENDS:
	case IF:
	case CONSTRAINEDBY:
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
	declaration_AST = RefMyAST(currentAST.root);
	returnAST = declaration_AST;
}

void modelica_parser::conditional_attribute() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST conditional_attribute_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp106_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp106_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp106_AST));
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
	case PLUS_EW:
	case MINUS_EW:
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
		switch ( LA(1)) {
		case EQUALS:
		{
			match(EQUALS);
			expression();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case ANNOTATION:
		case EXTENDS:
		case IF:
		case CONSTRAINEDBY:
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
		RefMyAST tmp108_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp108_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp108_AST));
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
		RefMyAST tmp109_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp109_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp109_AST));
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
			goto _loop103;
		}
		
	}
	_loop103:;
	} // ( ... )*
	if ( inputState->guessing==0 ) {
		argument_list_AST = RefMyAST(currentAST.root);
#line 432 "modelica_parser.g"
		
					argument_list_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ARGUMENT_LIST,"ARGUMENT_LIST")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(argument_list_AST))));
				
#line 3496 "modelica_parser.cpp"
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
	switch ( LA(1)) {
	case EACH:
	case FINAL:
	case REPLACEABLE:
	case IDENT:
	{
		element_modification_or_replaceable();
		if (inputState->guessing==0) {
			em_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			argument_AST = RefMyAST(currentAST.root);
#line 439 "modelica_parser.g"
			
						argument_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ELEMENT_MODIFICATION,"ELEMENT_MODIFICATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(em_AST))));
					
#line 3533 "modelica_parser.cpp"
			currentAST.root = argument_AST;
			if ( argument_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				argument_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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
			argument_AST = RefMyAST(currentAST.root);
#line 443 "modelica_parser.g"
			
						argument_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ELEMENT_REDECLARATION,"ELEMENT_REDECLARATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(er_AST)))); 		
#line 3555 "modelica_parser.cpp"
			currentAST.root = argument_AST;
			if ( argument_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				argument_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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

void modelica_parser::element_modification_or_replaceable() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_modification_or_replaceable_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	switch ( LA(1)) {
	case EACH:
	{
		RefMyAST tmp111_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp111_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp111_AST));
		}
		match(EACH);
		break;
	}
	case FINAL:
	case REPLACEABLE:
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
		RefMyAST tmp112_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp112_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp112_AST));
		}
		match(FINAL);
		break;
	}
	case REPLACEABLE:
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
		element_modification();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case REPLACEABLE:
	{
		element_replaceable();
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
	element_modification_or_replaceable_AST = RefMyAST(currentAST.root);
	returnAST = element_modification_or_replaceable_AST;
}

void modelica_parser::element_redeclaration() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_redeclaration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp113_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp113_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp113_AST));
	}
	match(REDECLARE);
	{
	switch ( LA(1)) {
	case EACH:
	{
		RefMyAST tmp114_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp114_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp114_AST));
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
	case EXPANDABLE:
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
	case STREAM:
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
		RefMyAST tmp115_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp115_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp115_AST));
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
	case EXPANDABLE:
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
	case STREAM:
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
	case EXPANDABLE:
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
	case STREAM:
	case IDENT:
	{
		{
		switch ( LA(1)) {
		case BLOCK:
		case CLASS:
		case CONNECTOR:
		case ENCAPSULATED:
		case EXPANDABLE:
		case FUNCTION:
		case MODEL:
		case PACKAGE:
		case PARTIAL:
		case RECORD:
		case TYPE:
		{
			class_definition();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case STREAM:
		case IDENT:
		{
			component_clause1();
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
		break;
	}
	case REPLACEABLE:
	{
		element_replaceable();
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
	switch ( LA(1)) {
	case LPAR:
	case EQUALS:
	case ASSIGN:
	{
		modification();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	element_modification_AST = RefMyAST(currentAST.root);
	returnAST = element_modification_AST;
}

void modelica_parser::element_replaceable() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_replaceable_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp116_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp116_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp116_AST));
	}
	match(REPLACEABLE);
	{
	switch ( LA(1)) {
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case ENCAPSULATED:
	case EXPANDABLE:
	case FUNCTION:
	case MODEL:
	case PACKAGE:
	case PARTIAL:
	case RECORD:
	case TYPE:
	{
		class_definition();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case CONSTANT:
	case DISCRETE:
	case FLOW:
	case INPUT:
	case OUTPUT:
	case PARAMETER:
	case STREAM:
	case IDENT:
	{
		component_clause1();
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
	{
	switch ( LA(1)) {
	case EXTENDS:
	case CONSTRAINEDBY:
	{
		constraining_clause();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		comment();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
	
	if (((_tokenSet_12.member(LA(1))) && (_tokenSet_13.member(LA(2))))&&( LA(1) == END || LA(1) == EQUATION || LA(1) == ALGORITHM || LA(1)==INITIAL
		 || LA(1) == PROTECTED || LA(1) == PUBLIC )) {
		equation_annotation_list_AST = RefMyAST(currentAST.root);
	}
	else if ((_tokenSet_14.member(LA(1))) && (_tokenSet_15.member(LA(2)))) {
		{
		switch ( LA(1)) {
		case CONNECT:
		case DER:
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
		case PLUS_EW:
		case MINUS_EW:
		case IDENT:
		case UNSIGNED_INTEGER:
		case STRING:
		{
			equation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
		bool synPredMatched131 = false;
		if (((_tokenSet_16.member(LA(1))) && (_tokenSet_15.member(LA(2))))) {
			int _m131 = mark();
			synPredMatched131 = true;
			inputState->guessing++;
			try {
				{
				simple_expression();
				match(EQUALS);
				}
			}
			catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
				synPredMatched131 = false;
			}
			rewind(_m131);
			inputState->guessing--;
		}
		if ( synPredMatched131 ) {
			equality_equation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else if ((LA(1) == IDENT) && (_tokenSet_17.member(LA(2)))) {
			component_reference();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
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
#line 540 "modelica_parser.g"
		
		equation_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EQUATION_STATEMENT,"EQUATION_STATEMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(equation_AST))));
		
#line 4146 "modelica_parser.cpp"
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

void modelica_parser::algorithm_annotation_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_annotation_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (((_tokenSet_12.member(LA(1))) && (_tokenSet_13.member(LA(2))))&&( LA(1) == END || LA(1) == EQUATION || LA(1) == ALGORITHM || LA(1)==INITIAL
		 || LA(1) == PROTECTED || LA(1) == PUBLIC )) {
		algorithm_annotation_list_AST = RefMyAST(currentAST.root);
	}
	else if ((_tokenSet_18.member(LA(1))) && (_tokenSet_19.member(LA(2)))) {
		{
		switch ( LA(1)) {
		case DER:
		case END:
		case FALSE:
		case FOR:
		case IF:
		case INITIAL:
		case NOT:
		case TRUE:
		case UNSIGNED_REAL:
		case WHEN:
		case WHILE:
		case LPAR:
		case LBRACK:
		case LBRACE:
		case PLUS:
		case MINUS:
		case PLUS_EW:
		case MINUS_EW:
		case IDENT:
		case UNSIGNED_INTEGER:
		case STRING:
		{
			algorithm();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
		algorithm_annotation_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		algorithm_annotation_list_AST = RefMyAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = algorithm_annotation_list_AST;
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
	switch ( LA(1)) {
	case COLON:
	{
		RefMyAST tmp121_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp121_AST = astFactory->create(LT(1));
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
			RefMyAST tmp122_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp122_AST = astFactory->create(LT(1));
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
		case IF:
		case LOOP:
		case THEN:
		case CONSTRAINEDBY:
		case RPAR:
		case RBRACK:
		case RBRACE:
		case EQUALS:
		case ASSIGN:
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
	case IF:
	case LOOP:
	case THEN:
	case CONSTRAINEDBY:
	case RPAR:
	case RBRACK:
	case RBRACE:
	case EQUALS:
	case ASSIGN:
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
		simple_expression_AST = RefMyAST(currentAST.root);
#line 727 "modelica_parser.g"
		
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
				
#line 4345 "modelica_parser.cpp"
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
	RefMyAST tmp123_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp123_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp123_AST));
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
	
	RefMyAST tmp124_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp124_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp124_AST));
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
	switch ( LA(1)) {
	case ELSE:
	{
		RefMyAST tmp126_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp126_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp126_AST));
		}
		match(ELSE);
		equation_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
	conditional_equation_e_AST = RefMyAST(currentAST.root);
	returnAST = conditional_equation_e_AST;
}

void modelica_parser::for_clause_e() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_clause_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp129_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp129_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp129_AST));
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
	
	RefMyAST tmp133_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp133_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp133_AST));
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
	
	RefMyAST tmp137_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp137_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp137_AST));
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
#line 884 "modelica_parser.g"
		
					function_call_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(FUNCTION_ARGUMENTS,"FUNCTION_ARGUMENTS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(function_call_AST))));
				
#line 4559 "modelica_parser.cpp"
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

void modelica_parser::algorithm() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	switch ( LA(1)) {
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
		bool synPredMatched137 = false;
		if (((_tokenSet_16.member(LA(1))) && (_tokenSet_19.member(LA(2))))) {
			int _m137 = mark();
			synPredMatched137 = true;
			inputState->guessing++;
			try {
				{
				simple_expression();
				match(ASSIGN);
				}
			}
			catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
				synPredMatched137 = false;
			}
			rewind(_m137);
			inputState->guessing--;
		}
		if ( synPredMatched137 ) {
			assign_clause_a();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else if ((LA(1) == IDENT) && (_tokenSet_17.member(LA(2)))) {
			component_reference();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			function_call();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else if ((LA(1) == LPAR) && (_tokenSet_20.member(LA(2)))) {
			multi_assign_clause_a();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
	else {
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
#line 563 "modelica_parser.g"
		
		algorithm_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(ALGORITHM_STATEMENT,"ALGORITHM_STATEMENT")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(algorithm_AST))));
		
#line 4666 "modelica_parser.cpp"
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

void modelica_parser::assign_clause_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST assign_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	simple_expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	RefMyAST tmp143_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp143_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp143_AST));
	}
	match(ASSIGN);
	expression();
	if (inputState->guessing==0) {
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
	RefMyAST tmp146_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp146_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp146_AST));
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
	
	RefMyAST tmp147_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp147_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp147_AST));
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
	switch ( LA(1)) {
	case ELSE:
	{
		RefMyAST tmp149_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp149_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp149_AST));
		}
		match(ELSE);
		algorithm_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
	conditional_equation_a_AST = RefMyAST(currentAST.root);
	returnAST = conditional_equation_a_AST;
}

void modelica_parser::for_clause_a() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp152_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp152_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp152_AST));
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
	
	RefMyAST tmp156_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp156_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp156_AST));
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
	
	RefMyAST tmp160_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp160_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp160_AST));
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
	
	if ((((LA(1) >= ELSE && LA(1) <= END)) && (_tokenSet_21.member(LA(2))))&&(LA(1) != END || (LA(1) == END && LA(2) != IDENT))) {
		equation_list_AST = RefMyAST(currentAST.root);
	}
	else if ((_tokenSet_22.member(LA(1))) && (_tokenSet_15.member(LA(2)))) {
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
	
	RefMyAST tmp165_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp165_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp165_AST));
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
	
	if ((((LA(1) >= ELSE && LA(1) <= END)) && (_tokenSet_23.member(LA(2))))&&(LA(1) != END || (LA(1) == END && LA(2) != IDENT))) {
		algorithm_list_AST = RefMyAST(currentAST.root);
	}
	else if ((_tokenSet_24.member(LA(1))) && (_tokenSet_19.member(LA(2)))) {
		{
		algorithm();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		match(SEMICOLON);
		algorithm_list();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		}
		algorithm_list_AST = RefMyAST(currentAST.root);
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
	}
	
	returnAST = algorithm_list_AST;
}

void modelica_parser::algorithm_elseif() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_elseif_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp168_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp168_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp168_AST));
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
	
	RefMyAST tmp170_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp170_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp170_AST));
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
	
	RefMyAST tmp174_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp174_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp174_AST));
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case DOT:
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
	{
	switch ( LA(1)) {
	case DOT:
	{
		RefMyAST tmp175_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp175_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp175_AST));
		}
		match(DOT);
		connector_ref_2();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
	connector_ref_AST = RefMyAST(currentAST.root);
	returnAST = connector_ref_AST;
}

void modelica_parser::connector_ref_2() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST connector_ref_2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp176_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp176_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp176_AST));
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case LBRACK:
	{
		array_subscripts();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
	connector_ref_2_AST = RefMyAST(currentAST.root);
	returnAST = connector_ref_2_AST;
}

void modelica_parser::if_expression() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST if_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp177_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp177_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp177_AST));
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
			goto _loop176;
		}
		
	}
	_loop176:;
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
	
	RefMyAST tmp180_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp180_AST = astFactory->create(LT(1));
	}
	match(CODE);
	RefMyAST tmp181_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp181_AST = astFactory->create(LT(1));
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
		bool synPredMatched190 = false;
		if (((_tokenSet_20.member(LA(1))) && (_tokenSet_25.member(LA(2))))) {
			int _m190 = mark();
			synPredMatched190 = true;
			inputState->guessing++;
			try {
				{
				expression();
				match(RPAR);
				}
			}
			catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
				synPredMatched190 = false;
			}
			rewind(_m190);
			inputState->guessing--;
		}
		if ( synPredMatched190 ) {
			expression();
			if (inputState->guessing==0) {
				e_AST = returnAST;
			}
		}
		else if ((_tokenSet_26.member(LA(1))) && (_tokenSet_27.member(LA(2)))) {
			modification();
			if (inputState->guessing==0) {
				m_AST = returnAST;
			}
		}
		else if ((_tokenSet_28.member(LA(1))) && (_tokenSet_29.member(LA(2)))) {
			element();
			if (inputState->guessing==0) {
				el_AST = returnAST;
			}
			{
			switch ( LA(1)) {
			case SEMICOLON:
			{
				match(SEMICOLON);
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
	RefMyAST tmp183_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp183_AST = astFactory->create(LT(1));
	}
	match(RPAR);
	if ( inputState->guessing==0 ) {
		code_expression_AST = RefMyAST(currentAST.root);
#line 748 "modelica_parser.g"
		
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
				
#line 5341 "modelica_parser.cpp"
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
	
	RefMyAST tmp184_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp184_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp184_AST));
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
	RefMyAST tmp186_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp186_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp186_AST));
	}
	match(IDENT);
	{
	switch ( LA(1)) {
	case IN:
	{
		RefMyAST tmp187_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp187_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp187_AST));
		}
		match(IN);
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case LOOP:
	case RPAR:
	case RBRACE:
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
	for_index_AST = RefMyAST(currentAST.root);
	returnAST = for_index_AST;
}

void modelica_parser::for_indices2() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_indices2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (((_tokenSet_30.member(LA(1))))&&(LA(2) != IN)) {
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
			RefMyAST tmp189_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp189_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp189_AST));
			}
			match(OR);
			logical_term();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop205;
		}
		
	}
	_loop205:;
	} // ( ... )*
	logical_expression_AST = RefMyAST(currentAST.root);
	returnAST = logical_expression_AST;
}

void modelica_parser::code_equation_clause() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST code_equation_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	RefMyAST tmp190_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp190_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp190_AST));
	}
	match(EQUATION);
	{ // ( ... )*
	for (;;) {
		switch ( LA(1)) {
		case CONNECT:
		case DER:
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
		case PLUS_EW:
		case MINUS_EW:
		case IDENT:
		case UNSIGNED_INTEGER:
		case STRING:
		{
			equation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
			break;
		}
		default:
		{
			goto _loop195;
		}
		}
	}
	_loop195:;
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
#line 774 "modelica_parser.g"
		
		code_initial_equation_clause_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_EQUATION,"INTIAL_EQUATION")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(ec_AST))));
		
#line 5573 "modelica_parser.cpp"
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
	
	RefMyAST tmp194_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp194_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp194_AST));
	}
	match(ALGORITHM);
	{ // ( ... )*
	for (;;) {
		switch ( LA(1)) {
		case DER:
		case END:
		case FALSE:
		case FOR:
		case IF:
		case INITIAL:
		case NOT:
		case TRUE:
		case UNSIGNED_REAL:
		case WHEN:
		case WHILE:
		case LPAR:
		case LBRACK:
		case LBRACE:
		case PLUS:
		case MINUS:
		case PLUS_EW:
		case MINUS_EW:
		case IDENT:
		case UNSIGNED_INTEGER:
		case STRING:
		{
			algorithm();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
			break;
		}
		default:
		{
			goto _loop199;
		}
		}
	}
	_loop199:;
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
	RefMyAST tmp198_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp198_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp198_AST));
	}
	match(ALGORITHM);
	{ // ( ... )*
	for (;;) {
		switch ( LA(1)) {
		case DER:
		case END:
		case FALSE:
		case FOR:
		case IF:
		case INITIAL:
		case NOT:
		case TRUE:
		case UNSIGNED_REAL:
		case WHEN:
		case WHILE:
		case LPAR:
		case LBRACK:
		case LBRACE:
		case PLUS:
		case MINUS:
		case PLUS_EW:
		case MINUS_EW:
		case IDENT:
		case UNSIGNED_INTEGER:
		case STRING:
		{
			algorithm();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
			break;
		}
		case ANNOTATION:
		{
			annotation();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			match(SEMICOLON);
			break;
		}
		default:
		{
			goto _loop202;
		}
		}
	}
	_loop202:;
	} // ( ... )*
	if ( inputState->guessing==0 ) {
		code_initial_algorithm_clause_AST = RefMyAST(currentAST.root);
#line 788 "modelica_parser.g"
		
					code_initial_algorithm_clause_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_ALGORITHM,"INTIAL_ALGORITHM")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(code_initial_algorithm_clause_AST))));
				
#line 5719 "modelica_parser.cpp"
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
			RefMyAST tmp201_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp201_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp201_AST));
			}
			match(AND);
			logical_factor();
			if (inputState->guessing==0) {
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop208;
		}
		
	}
	_loop208:;
	} // ( ... )*
	logical_term_AST = RefMyAST(currentAST.root);
	returnAST = logical_term_AST;
}

void modelica_parser::logical_factor() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST logical_factor_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	switch ( LA(1)) {
	case NOT:
	{
		RefMyAST tmp202_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp202_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp202_AST));
		}
		match(NOT);
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
	case PLUS:
	case MINUS:
	case PLUS_EW:
	case MINUS_EW:
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
			RefMyAST tmp203_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp203_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp203_AST));
			}
			match(LESS);
			break;
		}
		case LESSEQ:
		{
			RefMyAST tmp204_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp204_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp204_AST));
			}
			match(LESSEQ);
			break;
		}
		case GREATER:
		{
			RefMyAST tmp205_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp205_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp205_AST));
			}
			match(GREATER);
			break;
		}
		case GREATEREQ:
		{
			RefMyAST tmp206_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp206_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp206_AST));
			}
			match(GREATEREQ);
			break;
		}
		case EQEQ:
		{
			RefMyAST tmp207_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp207_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp207_AST));
			}
			match(EQEQ);
			break;
		}
		case LESSGT:
		{
			RefMyAST tmp208_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp208_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp208_AST));
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
		break;
	}
	case AND:
	case ANNOTATION:
	case ELSE:
	case ELSEIF:
	case EXTENDS:
	case FOR:
	case IF:
	case LOOP:
	case OR:
	case THEN:
	case CONSTRAINEDBY:
	case RPAR:
	case RBRACK:
	case RBRACE:
	case EQUALS:
	case ASSIGN:
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
		if ((_tokenSet_31.member(LA(1)))) {
			{
			switch ( LA(1)) {
			case PLUS:
			{
				RefMyAST tmp209_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp209_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp209_AST));
				}
				match(PLUS);
				break;
			}
			case MINUS:
			{
				RefMyAST tmp210_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp210_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp210_AST));
				}
				match(MINUS);
				break;
			}
			case PLUS_EW:
			{
				RefMyAST tmp211_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp211_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp211_AST));
				}
				match(PLUS_EW);
				break;
			}
			case MINUS_EW:
			{
				RefMyAST tmp212_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp212_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp212_AST));
				}
				match(MINUS_EW);
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
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop219;
		}
		
	}
	_loop219:;
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
	RefMyAST t4_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST t5_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
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
#line 821 "modelica_parser.g"
			unary_arithmetic_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(UNARY_PLUS,"PLUS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(t1_AST))));
#line 6122 "modelica_parser.cpp"
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
#line 822 "modelica_parser.g"
			unary_arithmetic_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(UNARY_MINUS,"MINUS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(t2_AST))));
#line 6148 "modelica_parser.cpp"
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
	case PLUS_EW:
	{
		RefMyAST tmp221_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp221_AST = astFactory->create(LT(1));
		}
		match(PLUS_EW);
		term();
		if (inputState->guessing==0) {
			t3_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = RefMyAST(currentAST.root);
#line 823 "modelica_parser.g"
			unary_arithmetic_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(UNARY_PLUS_EW,"PLUS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(t3_AST))));
#line 6174 "modelica_parser.cpp"
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
	case MINUS_EW:
	{
		RefMyAST tmp222_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp222_AST = astFactory->create(LT(1));
		}
		match(MINUS_EW);
		term();
		if (inputState->guessing==0) {
			t4_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = RefMyAST(currentAST.root);
#line 824 "modelica_parser.g"
			unary_arithmetic_expression_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(UNARY_MINUS_EW,"MINUS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(t4_AST))));
#line 6200 "modelica_parser.cpp"
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
			t5_AST = returnAST;
		}
		if ( inputState->guessing==0 ) {
			unary_arithmetic_expression_AST = RefMyAST(currentAST.root);
#line 825 "modelica_parser.g"
				unary_arithmetic_expression_AST = t5_AST;	
#line 6232 "modelica_parser.cpp"
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
		if ((_tokenSet_32.member(LA(1)))) {
			{
			switch ( LA(1)) {
			case STAR:
			{
				RefMyAST tmp223_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp223_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp223_AST));
				}
				match(STAR);
				break;
			}
			case SLASH:
			{
				RefMyAST tmp224_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp224_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp224_AST));
				}
				match(SLASH);
				break;
			}
			case STAR_EW:
			{
				RefMyAST tmp225_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp225_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp225_AST));
				}
				match(STAR_EW);
				break;
			}
			case SLASH_EW:
			{
				RefMyAST tmp226_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				if ( inputState->guessing == 0 ) {
					tmp226_AST = astFactory->create(LT(1));
					astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp226_AST));
				}
				match(SLASH_EW);
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
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
		}
		else {
			goto _loop225;
		}
		
	}
	_loop225:;
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
	switch ( LA(1)) {
	case POWER:
	case POWER_EW:
	{
		{
		switch ( LA(1)) {
		case POWER:
		{
			RefMyAST tmp227_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp227_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp227_AST));
			}
			match(POWER);
			break;
		}
		case POWER_EW:
		{
			RefMyAST tmp228_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp228_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp228_AST));
			}
			match(POWER_EW);
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(LT(1), getFilename());
		}
		}
		}
		primary();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case AND:
	case ANNOTATION:
	case ELSE:
	case ELSEIF:
	case EXTENDS:
	case FOR:
	case IF:
	case LOOP:
	case OR:
	case THEN:
	case CONSTRAINEDBY:
	case RPAR:
	case RBRACK:
	case RBRACE:
	case EQUALS:
	case ASSIGN:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case PLUS_EW:
	case MINUS_EW:
	case STAR_EW:
	case SLASH_EW:
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
		RefMyAST tmp229_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp229_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp229_AST));
		}
		match(UNSIGNED_INTEGER);
		break;
	}
	case UNSIGNED_REAL:
	{
		RefMyAST tmp230_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp230_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp230_AST));
		}
		match(UNSIGNED_REAL);
		break;
	}
	case STRING:
	{
		RefMyAST tmp231_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp231_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp231_AST));
		}
		match(STRING);
		break;
	}
	case FALSE:
	{
		RefMyAST tmp232_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp232_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp232_AST));
		}
		match(FALSE);
		break;
	}
	case TRUE:
	{
		RefMyAST tmp233_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp233_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp233_AST));
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
		RefMyAST tmp234_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp234_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp234_AST));
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
		RefMyAST tmp235_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp235_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp235_AST));
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
		RefMyAST tmp237_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp237_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp237_AST));
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
		RefMyAST tmp240_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp240_AST = astFactory->create(LT(1));
			astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp240_AST));
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
		RefMyAST tmp242_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp242_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp242_AST));
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
		case IF:
		case LOOP:
		case OR:
		case THEN:
		case CONSTRAINEDBY:
		case RPAR:
		case RBRACK:
		case RBRACE:
		case EQUALS:
		case ASSIGN:
		case PLUS:
		case MINUS:
		case STAR:
		case SLASH:
		case POWER:
		case PLUS_EW:
		case MINUS_EW:
		case STAR_EW:
		case SLASH_EW:
		case POWER_EW:
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
		if ( inputState->guessing==0 ) {
			component_reference__function_call_AST = RefMyAST(currentAST.root);
#line 854 "modelica_parser.g"
			
						if (fc_AST != null)
						{
							component_reference__function_call_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(3))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(FUNCTION_CALL,"FUNCTION_CALL")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(cr_AST))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(fc_AST))));
						}
						else
						{
							component_reference__function_call_AST = cr_AST;
						}
					
#line 6670 "modelica_parser.cpp"
			currentAST.root = component_reference__function_call_AST;
			if ( component_reference__function_call_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				component_reference__function_call_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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
			component_reference__function_call_AST = RefMyAST(currentAST.root);
#line 864 "modelica_parser.g"
			
						component_reference__function_call_AST = RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(INITIAL_FUNCTION_CALL,"INITIAL_FUNCTION_CALL")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST))));
					
#line 6696 "modelica_parser.cpp"
			currentAST.root = component_reference__function_call_AST;
			if ( component_reference__function_call_AST!=RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) &&
				component_reference__function_call_AST->getFirstChild() != RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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

void modelica_parser::for_or_expression_list() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_or_expression_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST explist_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST forind_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if (((_tokenSet_33.member(LA(1))) && (_tokenSet_34.member(LA(2))))&&(LA(1)==IDENT && LA(2) == EQUALS|| LA(1) == RPAR)) {
	}
	else if ((_tokenSet_20.member(LA(1))) && (_tokenSet_35.member(LA(2)))) {
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
			RefMyAST tmp246_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			if ( inputState->guessing == 0 ) {
				tmp246_AST = astFactory->create(LT(1));
				astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp246_AST));
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
#line 905 "modelica_parser.g"
			
			if (forind_AST != null) {
			for_or_expression_list_AST =
			RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(FOR_ITERATOR,"FOR_ITERATOR")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(for_or_expression_list_AST))));
			}
			else {
			for_or_expression_list_AST =
			RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(EXPRESSION_LIST,"EXPRESSION_LIST")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(for_or_expression_list_AST))));
			}
			
#line 6786 "modelica_parser.cpp"
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
	switch ( LA(1)) {
	case IDENT:
	{
		named_arguments();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
#line 926 "modelica_parser.g"
		
					named_arguments_AST=RefMyAST(astFactory->make((new ANTLR_USE_NAMESPACE(antlr)ASTArray(2))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(astFactory->create(NAMED_ARGUMENTS,"NAMED_ARGUMENTS")))->add(ANTLR_USE_NAMESPACE(antlr)RefAST(named_arguments_AST))));
				
#line 6855 "modelica_parser.cpp"
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
	
	if (((_tokenSet_33.member(LA(1))) && (_tokenSet_34.member(LA(2))))&&(LA(2) == EQUALS)) {
		for_or_expression_list2_AST = RefMyAST(currentAST.root);
	}
	else if ((_tokenSet_20.member(LA(1))) && (_tokenSet_36.member(LA(2)))) {
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		switch ( LA(1)) {
		case COMMA:
		{
			match(COMMA);
			for_or_expression_list2();
			if (inputState->guessing==0) {
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
	switch ( LA(1)) {
	case COMMA:
	{
		match(COMMA);
		named_arguments2();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
	named_arguments2_AST = RefMyAST(currentAST.root);
	returnAST = named_arguments2_AST;
}

void modelica_parser::named_argument() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST named_argument_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST tmp249_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp249_AST = astFactory->create(LT(1));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp249_AST));
	}
	match(IDENT);
	RefMyAST tmp250_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	if ( inputState->guessing == 0 ) {
		tmp250_AST = astFactory->create(LT(1));
		astFactory->makeASTRoot(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp250_AST));
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
	switch ( LA(1)) {
	case COMMA:
	{
		match(COMMA);
		expression_list2();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	case RPAR:
	case RBRACK:
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
	expression_list2_AST = RefMyAST(currentAST.root);
	returnAST = expression_list2_AST;
}

void modelica_parser::subscript() {
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST subscript_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	switch ( LA(1)) {
	case CODE:
	case DER:
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
	case PLUS_EW:
	case MINUS_EW:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	{
		expression();
		if (inputState->guessing==0) {
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		subscript_AST = RefMyAST(currentAST.root);
		break;
	}
	case COLON:
	{
		RefMyAST tmp252_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		if ( inputState->guessing == 0 ) {
			tmp252_AST = astFactory->create(LT(1));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp252_AST));
		}
		match(COLON);
		subscript_AST = RefMyAST(currentAST.root);
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
	factory.setMaxNodeType(152);
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
	"\"constrainedby\"",
	"\"return\"",
	"\"break\"",
	"\"stream\"",
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
	"POWER",
	"PLUS_EW",
	"MINUS_EW",
	"STAR_EW",
	"SLASH_EW",
	"POWER_EW",
	"COMMA",
	"LESS",
	"LESSEQ",
	"GREATER",
	"GREATEREQ",
	"EQEQ",
	"LESSGT",
	"COLON",
	"SEMICOLON",
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
	"UNARY_MINUS_EW",
	"UNARY_PLUS_EW",
	"UNQUALIFIED",
	0
};

const unsigned long modelica_parser::_tokenSet_0_data_[] = { 1086327424UL, 8540224UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "encapsulated" "expandable" "function" "model" 
// "package" "partial" "record" "type" 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_0(_tokenSet_0_data_,6);
const unsigned long modelica_parser::_tokenSet_1_data_[] = { 1082133120UL, 8540224UL, 0UL, 1UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "expandable" "function" "model" "package" 
// "partial" "record" "type" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_1(_tokenSet_1_data_,8);
const unsigned long modelica_parser::_tokenSet_2_data_[] = { 1220545154UL, 276975680UL, 0UL, 0UL, 0UL, 0UL };
// EOF "block" "class" "connector" "encapsulated" "expandable" "final" 
// "function" "model" "package" "partial" "record" "type" "within" 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_2(_tokenSet_2_data_,6);
const unsigned long modelica_parser::_tokenSet_3_data_[] = { 1103104642UL, 8540224UL, 134217728UL, 1UL, 0UL, 0UL, 0UL, 0UL };
// EOF "block" "class" "connector" "encapsulated" "expandable" "extends" 
// "function" "model" "package" "partial" "record" "type" SEMICOLON IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_3(_tokenSet_3_data_,8);
const unsigned long modelica_parser::_tokenSet_4_data_[] = { 1220545152UL, 8540224UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "encapsulated" "expandable" "final" "function" 
// "model" "package" "partial" "record" "type" 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_4(_tokenSet_4_data_,6);
const unsigned long modelica_parser::_tokenSet_5_data_[] = { 64UL, 33554432UL, 134283268UL, 64UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "." RPAR STAR_EW SEMICOLON STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_5(_tokenSet_5_data_,8);
const unsigned long modelica_parser::_tokenSet_6_data_[] = { 16777280UL, 536870912UL, 134742030UL, 65UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "extends" "constrainedby" LPAR RPAR LBRACK COMMA SEMICOLON 
// IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_6(_tokenSet_6_data_,8);
const unsigned long modelica_parser::_tokenSet_7_data_[] = { 1541946064UL, 9435485UL, 1UL, 65UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "annotation" "block" "class" "connector" "constant" "discrete" 
// "end" "equation" "encapsulated" "expandable" "extends" "external" "final" 
// "flow" "function" "import" "initial" "inner" "input" "model" "outer" 
// "output" "package" "parameter" "partial" "protected" "public" "record" 
// "redeclare" "replaceable" "type" "stream" IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_7(_tokenSet_7_data_,8);
const unsigned long modelica_parser::_tokenSet_8_data_[] = { 268447744UL, 10256UL, 1UL, 1UL, 0UL, 0UL, 0UL, 0UL };
// "constant" "discrete" "flow" "input" "output" "parameter" "stream" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_8(_tokenSet_8_data_,8);
const unsigned long modelica_parser::_tokenSet_9_data_[] = { 1505770176UL, 9337177UL, 1UL, 1UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "block" "class" "connector" "constant" "discrete" "encapsulated" 
// "expandable" "extends" "final" "flow" "function" "import" "inner" "input" 
// "model" "outer" "output" "package" "parameter" "partial" "record" "redeclare" 
// "replaceable" "type" "stream" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_9(_tokenSet_9_data_,8);
const unsigned long modelica_parser::_tokenSet_10_data_[] = { 0UL, 33554432UL, 136UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "." LBRACK EQUALS 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_10(_tokenSet_10_data_,8);
const unsigned long modelica_parser::_tokenSet_11_data_[] = { 64UL, 0UL, 134283268UL, 64UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" RPAR STAR_EW SEMICOLON STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_11(_tokenSet_11_data_,8);
const unsigned long modelica_parser::_tokenSet_12_data_[] = { 36175888UL, 98308UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "end" "equation" "external" "initial" "protected" "public" 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_12(_tokenSet_12_data_,6);
const unsigned long modelica_parser::_tokenSet_13_data_[] = { 4293426896UL, 231733725UL, 134268459UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "annotation" "block" "class" "connect" "connector" "constant" 
// "discrete" "der" "end" "equation" "encapsulated" "expandable" "extends" 
// "external" "false" "final" "flow" "for" "function" "if" "import" "initial" 
// "inner" "input" "model" "not" "outer" "output" "package" "parameter" 
// "partial" "protected" "public" "record" "redeclare" "replaceable" "true" 
// "type" "unsigned_real" "when" "while" "stream" LPAR LBRACK LBRACE PLUS 
// MINUS PLUS_EW MINUS_EW SEMICOLON IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_13(_tokenSet_13_data_,8);
const unsigned long modelica_parser::_tokenSet_14_data_[] = { 2752005184UL, 88080516UL, 50730UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "connect" "der" "end" "false" "for" "if" "initial" "not" 
// "true" "unsigned_real" "when" LPAR LBRACK LBRACE PLUS MINUS PLUS_EW 
// MINUS_EW IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_14(_tokenSet_14_data_,8);
const unsigned long modelica_parser::_tokenSet_15_data_[] = { 2215133472UL, 54527108UL, 133693162UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "der" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real" 
// "." LPAR LBRACK LBRACE RBRACE EQUALS PLUS MINUS STAR SLASH POWER PLUS_EW 
// MINUS_EW STAR_EW SLASH_EW POWER_EW LESS LESSEQ GREATER GREATEREQ EQEQ 
// LESSGT COLON IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_15(_tokenSet_15_data_,8);
const unsigned long modelica_parser::_tokenSet_16_data_[] = { 67649536UL, 20971652UL, 50730UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "der" "end" "false" "initial" "not" "true" "unsigned_real" LPAR LBRACK 
// LBRACE PLUS MINUS PLUS_EW MINUS_EW IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_16(_tokenSet_16_data_,8);
const unsigned long modelica_parser::_tokenSet_17_data_[] = { 0UL, 33554432UL, 10UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "." LPAR LBRACK 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_17(_tokenSet_17_data_,8);
const unsigned long modelica_parser::_tokenSet_18_data_[] = { 2752004160UL, 222298244UL, 50730UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "annotation" "der" "end" "false" "for" "if" "initial" "not" "true" "unsigned_real" 
// "when" "while" LPAR LBRACK LBRACE PLUS MINUS PLUS_EW MINUS_EW IDENT 
// UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_18(_tokenSet_18_data_,8);
const unsigned long modelica_parser::_tokenSet_19_data_[] = { 2215133472UL, 54527108UL, 133693290UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "der" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real" 
// "." LPAR LBRACK LBRACE RBRACE ASSIGN PLUS MINUS STAR SLASH POWER PLUS_EW 
// MINUS_EW STAR_EW SLASH_EW POWER_EW LESS LESSEQ GREATER GREATEREQ EQEQ 
// LESSGT COLON IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_19(_tokenSet_19_data_,8);
const unsigned long modelica_parser::_tokenSet_20_data_[] = { 2215133440UL, 20971652UL, 50730UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "Code" "der" "end" "false" "if" "initial" "not" "true" "unsigned_real" 
// LPAR LBRACK LBRACE PLUS MINUS PLUS_EW MINUS_EW IDENT UNSIGNED_INTEGER 
// STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_20(_tokenSet_20_data_,8);
const unsigned long modelica_parser::_tokenSet_21_data_[] = { 2752005376UL, 88080516UL, 50730UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "Code" "connect" "der" "end" "false" "for" "if" "initial" "not" "true" 
// "unsigned_real" "when" LPAR LBRACK LBRACE PLUS MINUS PLUS_EW MINUS_EW 
// IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_21(_tokenSet_21_data_,8);
const unsigned long modelica_parser::_tokenSet_22_data_[] = { 2752005120UL, 88080516UL, 50730UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "connect" "der" "end" "false" "for" "if" "initial" "not" "true" "unsigned_real" 
// "when" LPAR LBRACK LBRACE PLUS MINUS PLUS_EW MINUS_EW IDENT UNSIGNED_INTEGER 
// STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_22(_tokenSet_22_data_,8);
const unsigned long modelica_parser::_tokenSet_23_data_[] = { 2752004352UL, 222298244UL, 50730UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "Code" "der" "end" "false" "for" "if" "initial" "not" "true" "unsigned_real" 
// "when" "while" LPAR LBRACK LBRACE PLUS MINUS PLUS_EW MINUS_EW IDENT 
// UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_23(_tokenSet_23_data_,8);
const unsigned long modelica_parser::_tokenSet_24_data_[] = { 2752004096UL, 222298244UL, 50730UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "der" "end" "false" "for" "if" "initial" "not" "true" "unsigned_real" 
// "when" "while" LPAR LBRACK LBRACE PLUS MINUS PLUS_EW MINUS_EW IDENT 
// UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_24(_tokenSet_24_data_,8);
const unsigned long modelica_parser::_tokenSet_25_data_[] = { 2215133472UL, 54527108UL, 133693038UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "der" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real" 
// "." LPAR RPAR LBRACK LBRACE RBRACE PLUS MINUS STAR SLASH POWER PLUS_EW 
// MINUS_EW STAR_EW SLASH_EW POWER_EW LESS LESSEQ GREATER GREATEREQ EQEQ 
// LESSGT COLON IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_25(_tokenSet_25_data_,8);
const unsigned long modelica_parser::_tokenSet_26_data_[] = { 0UL, 0UL, 386UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// LPAR EQUALS ASSIGN 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_26(_tokenSet_26_data_,8);
const unsigned long modelica_parser::_tokenSet_27_data_[] = { 2349383936UL, 21758084UL, 50734UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "Code" "der" "each" "end" "false" "final" "if" "initial" "not" "redeclare" 
// "replaceable" "true" "unsigned_real" LPAR RPAR LBRACK LBRACE PLUS MINUS 
// PLUS_EW MINUS_EW IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_27(_tokenSet_27_data_,8);
const unsigned long modelica_parser::_tokenSet_28_data_[] = { 1505770112UL, 9337177UL, 1UL, 1UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "constant" "discrete" "encapsulated" "expandable" 
// "extends" "final" "flow" "function" "import" "inner" "input" "model" 
// "outer" "output" "package" "parameter" "partial" "record" "redeclare" 
// "replaceable" "type" "stream" IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_28(_tokenSet_28_data_,8);
const unsigned long modelica_parser::_tokenSet_29_data_[] = { 1505770112UL, 42629464UL, 9UL, 1UL, 0UL, 0UL, 0UL, 0UL };
// "block" "class" "connector" "constant" "discrete" "encapsulated" "expandable" 
// "extends" "final" "flow" "function" "inner" "input" "model" "outer" 
// "output" "package" "parameter" "partial" "record" "replaceable" "type" 
// "." "stream" LBRACK IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_29(_tokenSet_29_data_,8);
const unsigned long modelica_parser::_tokenSet_30_data_[] = { 0UL, 32UL, 68UL, 1UL, 0UL, 0UL, 0UL, 0UL };
// "loop" RPAR RBRACE IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_30(_tokenSet_30_data_,8);
const unsigned long modelica_parser::_tokenSet_31_data_[] = { 0UL, 0UL, 50688UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// PLUS MINUS PLUS_EW MINUS_EW 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_31(_tokenSet_31_data_,8);
const unsigned long modelica_parser::_tokenSet_32_data_[] = { 0UL, 0UL, 202752UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// STAR SLASH STAR_EW SLASH_EW 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_32(_tokenSet_32_data_,8);
const unsigned long modelica_parser::_tokenSet_33_data_[] = { 0UL, 0UL, 68UL, 1UL, 0UL, 0UL, 0UL, 0UL };
// RPAR RBRACE IDENT 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_33(_tokenSet_33_data_,8);
const unsigned long modelica_parser::_tokenSet_34_data_[] = { 2701328480UL, 538969120UL, 268435412UL, 65UL, 0UL, 0UL, 0UL, 0UL };
// "and" "annotation" "else" "elseif" "extends" "for" "if" "loop" "or" 
// "then" "constrainedby" RPAR RBRACK RBRACE EQUALS ASSIGN PLUS MINUS STAR 
// SLASH POWER PLUS_EW MINUS_EW STAR_EW SLASH_EW POWER_EW COMMA LESS LESSEQ 
// GREATER GREATEREQ EQEQ LESSGT COLON SEMICOLON IDENT STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_34(_tokenSet_34_data_,8);
const unsigned long modelica_parser::_tokenSet_35_data_[] = { 2752004384UL, 54527108UL, 134217326UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "der" "end" "false" "for" "if" "initial" "not" "or" "true" 
// "unsigned_real" "." LPAR RPAR LBRACK LBRACE RBRACE PLUS MINUS STAR SLASH 
// POWER PLUS_EW MINUS_EW STAR_EW SLASH_EW POWER_EW COMMA LESS LESSEQ GREATER 
// GREATEREQ EQEQ LESSGT COLON IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_35(_tokenSet_35_data_,8);
const unsigned long modelica_parser::_tokenSet_36_data_[] = { 2215133472UL, 54527108UL, 134217326UL, 97UL, 0UL, 0UL, 0UL, 0UL };
// "and" "Code" "der" "end" "false" "if" "initial" "not" "or" "true" "unsigned_real" 
// "." LPAR RPAR LBRACK LBRACE RBRACE PLUS MINUS STAR SLASH POWER PLUS_EW 
// MINUS_EW STAR_EW SLASH_EW POWER_EW COMMA LESS LESSEQ GREATER GREATEREQ 
// EQEQ LESSGT COLON IDENT UNSIGNED_INTEGER STRING 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_parser::_tokenSet_36(_tokenSet_36_data_,8);



/* $ANTLR 2.7.3: "modelica_lexer.g" -> "modelica_lexer.cpp"$ */
#include "modelica_lexer.hpp"
#include <antlr/CharBuffer.hpp>
#include <antlr/TokenStreamException.hpp>
#include <antlr/TokenStreamIOException.hpp>
#include <antlr/TokenStreamRecognitionException.hpp>
#include <antlr/CharStreamException.hpp>
#include <antlr/CharStreamIOException.hpp>
#include <antlr/NoViableAltForCharException.hpp>

#line 1 "modelica_lexer.g"
#line 13 "modelica_lexer.cpp"
modelica_lexer::modelica_lexer(ANTLR_USE_NAMESPACE(std)istream& in)
	: ANTLR_USE_NAMESPACE(antlr)CharScanner(new ANTLR_USE_NAMESPACE(antlr)CharBuffer(in),true)
{
	initLiterals();
}

modelica_lexer::modelica_lexer(ANTLR_USE_NAMESPACE(antlr)InputBuffer& ib)
	: ANTLR_USE_NAMESPACE(antlr)CharScanner(ib,true)
{
	initLiterals();
}

modelica_lexer::modelica_lexer(const ANTLR_USE_NAMESPACE(antlr)LexerSharedInputState& state)
	: ANTLR_USE_NAMESPACE(antlr)CharScanner(state,true)
{
	initLiterals();
}

void modelica_lexer::initLiterals()
{
	literals["type"] = 54;
	literals["constant"] = 13;
	literals["public"] = 47;
	literals["initial"] = 33;
	literals["annotation"] = 6;
	literals["while"] = 57;
	literals["end"] = 19;
	literals["equation"] = 21;
	literals["overload"] = 40;
	literals["flow"] = 27;
	literals["then"] = 52;
	literals["unsigned_real"] = 55;
	literals["and"] = 5;
	literals["outer"] = 39;
	literals["not"] = 38;
	literals["package"] = 43;
	literals["external"] = 24;
	literals["boundary"] = 8;
	literals["replaceable"] = 50;
	literals["protected"] = 46;
	literals["output"] = 42;
	literals["when"] = 56;
	literals["class"] = 10;
	literals["inner"] = 34;
	literals["enumeration"] = 20;
	literals["function"] = 29;
	literals["each"] = 15;
	literals["redeclare"] = 49;
	literals["model"] = 37;
	literals["elseif"] = 17;
	literals["parameter"] = 44;
	literals["input"] = 35;
	literals["final"] = 26;
	literals["or"] = 41;
	literals["if"] = 30;
	literals["record"] = 48;
	literals["connector"] = 12;
	literals["connect"] = 11;
	literals["results"] = 51;
	literals["for"] = 28;
	literals["extends"] = 23;
	literals["loop"] = 36;
	literals["false"] = 25;
	literals["elsewhen"] = 18;
	literals["Code"] = 9;
	literals["encapsulated"] = 22;
	literals["partial"] = 45;
	literals["else"] = 16;
	literals["import"] = 31;
	literals["discrete"] = 14;
	literals["in"] = 32;
	literals["block"] = 7;
	literals["true"] = 53;
	literals["within"] = 58;
	literals["algorithm"] = 4;
}

ANTLR_USE_NAMESPACE(antlr)RefToken modelica_lexer::nextToken()
{
	ANTLR_USE_NAMESPACE(antlr)RefToken theRetToken;
	for (;;) {
		ANTLR_USE_NAMESPACE(antlr)RefToken theRetToken;
		int _ttype = ANTLR_USE_NAMESPACE(antlr)Token::INVALID_TYPE;
		resetText();
		try {   // for lexical and char stream error handling
			switch ( LA(1)) {
			case 0x28 /* '(' */ :
			{
				mLPAR(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x29 /* ')' */ :
			{
				mRPAR(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x5b /* '[' */ :
			{
				mLBRACK(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x5d /* ']' */ :
			{
				mRBRACK(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x7b /* '{' */ :
			{
				mLBRACE(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x7d /* '}' */ :
			{
				mRBRACE(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x2b /* '+' */ :
			{
				mPLUS(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x2d /* '-' */ :
			{
				mMINUS(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x2a /* '*' */ :
			{
				mSTAR(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x2e /* '.' */ :
			{
				mDOT(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x2c /* ',' */ :
			{
				mCOMMA(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x3b /* ';' */ :
			{
				mSEMICOLON(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x5e /* '^' */ :
			{
				mPOWER(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x9 /* '\t' */ :
			case 0xa /* '\n' */ :
			case 0xd /* '\r' */ :
			case 0x20 /* ' ' */ :
			{
				mWS(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x41 /* 'A' */ :
			case 0x42 /* 'B' */ :
			case 0x43 /* 'C' */ :
			case 0x44 /* 'D' */ :
			case 0x45 /* 'E' */ :
			case 0x46 /* 'F' */ :
			case 0x47 /* 'G' */ :
			case 0x48 /* 'H' */ :
			case 0x49 /* 'I' */ :
			case 0x4a /* 'J' */ :
			case 0x4b /* 'K' */ :
			case 0x4c /* 'L' */ :
			case 0x4d /* 'M' */ :
			case 0x4e /* 'N' */ :
			case 0x4f /* 'O' */ :
			case 0x50 /* 'P' */ :
			case 0x51 /* 'Q' */ :
			case 0x52 /* 'R' */ :
			case 0x53 /* 'S' */ :
			case 0x54 /* 'T' */ :
			case 0x55 /* 'U' */ :
			case 0x56 /* 'V' */ :
			case 0x57 /* 'W' */ :
			case 0x58 /* 'X' */ :
			case 0x59 /* 'Y' */ :
			case 0x5a /* 'Z' */ :
			case 0x5f /* '_' */ :
			case 0x61 /* 'a' */ :
			case 0x62 /* 'b' */ :
			case 0x63 /* 'c' */ :
			case 0x64 /* 'd' */ :
			case 0x65 /* 'e' */ :
			case 0x66 /* 'f' */ :
			case 0x67 /* 'g' */ :
			case 0x68 /* 'h' */ :
			case 0x69 /* 'i' */ :
			case 0x6a /* 'j' */ :
			case 0x6b /* 'k' */ :
			case 0x6c /* 'l' */ :
			case 0x6d /* 'm' */ :
			case 0x6e /* 'n' */ :
			case 0x6f /* 'o' */ :
			case 0x70 /* 'p' */ :
			case 0x71 /* 'q' */ :
			case 0x72 /* 'r' */ :
			case 0x73 /* 's' */ :
			case 0x74 /* 't' */ :
			case 0x75 /* 'u' */ :
			case 0x76 /* 'v' */ :
			case 0x77 /* 'w' */ :
			case 0x78 /* 'x' */ :
			case 0x79 /* 'y' */ :
			case 0x7a /* 'z' */ :
			{
				mIDENT(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x30 /* '0' */ :
			case 0x31 /* '1' */ :
			case 0x32 /* '2' */ :
			case 0x33 /* '3' */ :
			case 0x34 /* '4' */ :
			case 0x35 /* '5' */ :
			case 0x36 /* '6' */ :
			case 0x37 /* '7' */ :
			case 0x38 /* '8' */ :
			case 0x39 /* '9' */ :
			{
				mUNSIGNED_INTEGER(true);
				theRetToken=_returnToken;
				break;
			}
			case 0x22 /* '"' */ :
			{
				mSTRING(true);
				theRetToken=_returnToken;
				break;
			}
			default:
				if ((LA(1) == 0x3a /* ':' */ ) && (LA(2) == 0x3d /* '=' */ )) {
					mASSIGN(true);
					theRetToken=_returnToken;
				}
				else if ((LA(1) == 0x3c /* '<' */ ) && (LA(2) == 0x3d /* '=' */ )) {
					mLESSEQ(true);
					theRetToken=_returnToken;
				}
				else if ((LA(1) == 0x3e /* '>' */ ) && (LA(2) == 0x3d /* '=' */ )) {
					mGREATEREQ(true);
					theRetToken=_returnToken;
				}
				else if ((LA(1) == 0x3d /* '=' */ ) && (LA(2) == 0x3d /* '=' */ )) {
					mEQEQ(true);
					theRetToken=_returnToken;
				}
				else if ((LA(1) == 0x3c /* '<' */ ) && (LA(2) == 0x3e /* '>' */ )) {
					mLESSGT(true);
					theRetToken=_returnToken;
				}
				else if ((LA(1) == 0x2f /* '/' */ ) && (LA(2) == 0x2a /* '*' */ )) {
					mML_COMMENT(true);
					theRetToken=_returnToken;
				}
				else if ((LA(1) == 0x2f /* '/' */ ) && (LA(2) == 0x2f /* '/' */ )) {
					mSL_COMMENT(true);
					theRetToken=_returnToken;
				}
				else if ((LA(1) == 0x3d /* '=' */ ) && (true)) {
					mEQUALS(true);
					theRetToken=_returnToken;
				}
				else if ((LA(1) == 0x2f /* '/' */ ) && (true)) {
					mSLASH(true);
					theRetToken=_returnToken;
				}
				else if ((LA(1) == 0x3c /* '<' */ ) && (true)) {
					mLESS(true);
					theRetToken=_returnToken;
				}
				else if ((LA(1) == 0x3e /* '>' */ ) && (true)) {
					mGREATER(true);
					theRetToken=_returnToken;
				}
				else if ((LA(1) == 0x3a /* ':' */ ) && (true)) {
					mCOLON(true);
					theRetToken=_returnToken;
				}
			else {
				if (LA(1)==EOF_CHAR)
				{
					uponEOF();
					_returnToken = makeToken(ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE);
				}
				else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());}
			}
			}
			if ( !_returnToken )
				goto tryAgain; // found SKIP token

			_ttype = _returnToken->getType();
			_returnToken->setType(_ttype);
			return _returnToken;
		}
		catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& e) {
				throw ANTLR_USE_NAMESPACE(antlr)TokenStreamRecognitionException(e);
		}
		catch (ANTLR_USE_NAMESPACE(antlr)CharStreamIOException& csie) {
			throw ANTLR_USE_NAMESPACE(antlr)TokenStreamIOException(csie.io);
		}
		catch (ANTLR_USE_NAMESPACE(antlr)CharStreamException& cse) {
			throw ANTLR_USE_NAMESPACE(antlr)TokenStreamException(cse.getMessage());
		}
tryAgain:;
	}
}

void modelica_lexer::mLPAR(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = LPAR;
	int _saveIndex;
	
	match('(');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mRPAR(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = RPAR;
	int _saveIndex;
	
	match(')');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mLBRACK(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = LBRACK;
	int _saveIndex;
	
	match('[');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mRBRACK(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = RBRACK;
	int _saveIndex;
	
	match(']');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mLBRACE(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = LBRACE;
	int _saveIndex;
	
	match('{');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mRBRACE(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = RBRACE;
	int _saveIndex;
	
	match('}');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mEQUALS(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = EQUALS;
	int _saveIndex;
	
	match('=');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mASSIGN(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = ASSIGN;
	int _saveIndex;
	
	match(":=");
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mPLUS(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = PLUS;
	int _saveIndex;
	
	match('+');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mMINUS(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = MINUS;
	int _saveIndex;
	
	match('-');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mSTAR(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = STAR;
	int _saveIndex;
	
	match('*');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mSLASH(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = SLASH;
	int _saveIndex;
	
	match('/');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mDOT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = DOT;
	int _saveIndex;
	
	match('.');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mCOMMA(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = COMMA;
	int _saveIndex;
	
	match(',');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mLESS(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = LESS;
	int _saveIndex;
	
	match('<');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mLESSEQ(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = LESSEQ;
	int _saveIndex;
	
	match("<=");
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mGREATER(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = GREATER;
	int _saveIndex;
	
	match('>');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mGREATEREQ(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = GREATEREQ;
	int _saveIndex;
	
	match(">=");
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mEQEQ(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = EQEQ;
	int _saveIndex;
	
	match("==");
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mLESSGT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = LESSGT;
	int _saveIndex;
	
	match("<>");
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mCOLON(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = COLON;
	int _saveIndex;
	
	match(':');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mSEMICOLON(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = SEMICOLON;
	int _saveIndex;
	
	match(';');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mPOWER(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = POWER;
	int _saveIndex;
	
	match('^');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mWS(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = WS;
	int _saveIndex;
	
	{
	switch ( LA(1)) {
	case 0x20 /* ' ' */ :
	{
		match(' ');
		break;
	}
	case 0x9 /* '\t' */ :
	{
		match('\t');
		break;
	}
	case 0xa /* '\n' */ :
	case 0xd /* '\r' */ :
	{
		{
		if ((LA(1) == 0xd /* '\r' */ ) && (LA(2) == 0xa /* '\n' */ )) {
			match("\r\n");
		}
		else if ((LA(1) == 0xd /* '\r' */ ) && (true)) {
			match('\r');
		}
		else if ((LA(1) == 0xa /* '\n' */ )) {
			match('\n');
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());
		}
		
		}
		if ( inputState->guessing==0 ) {
#line 115 "modelica_lexer.g"
			newline();
#line 704 "modelica_lexer.cpp"
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());
	}
	}
	}
	if ( inputState->guessing==0 ) {
#line 117 "modelica_lexer.g"
		_ttype = antlr::Token::SKIP;
#line 717 "modelica_lexer.cpp"
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mML_COMMENT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = ML_COMMENT;
	int _saveIndex;
	
	match("/*");
	{ // ( ... )*
	for (;;) {
		if (((LA(1) == 0x2a /* '*' */ ) && ((LA(2) >= 0x3 /* '\3' */  && LA(2) <= 0xff)))&&(LA(2)!='/')) {
			match('*');
		}
		else if ((_tokenSet_0.member(LA(1)))) {
			mML_COMMENT_CHAR(false);
		}
		else {
			goto _loop29;
		}
		
	}
	_loop29:;
	} // ( ... )*
	match("*/");
	if ( inputState->guessing==0 ) {
#line 124 "modelica_lexer.g"
		_ttype = antlr::Token::SKIP;
#line 752 "modelica_lexer.cpp"
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mML_COMMENT_CHAR(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = ML_COMMENT_CHAR;
	int _saveIndex;
	
	if ((LA(1) == 0xa /* '\n' */  || LA(1) == 0xd /* '\r' */ )) {
		{
		switch ( LA(1)) {
		case 0xd /* '\r' */ :
		{
			match("\r\n");
			break;
		}
		case 0xa /* '\n' */ :
		{
			match('\n');
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());
		}
		}
		}
		if ( inputState->guessing==0 ) {
#line 128 "modelica_lexer.g"
			newline();
#line 789 "modelica_lexer.cpp"
		}
	}
	else if ((_tokenSet_1.member(LA(1)))) {
		{
		match(_tokenSet_1);
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());
	}
	
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mSL_COMMENT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = SL_COMMENT;
	int _saveIndex;
	
	match("//");
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_2.member(LA(1)))) {
			{
			match(_tokenSet_2);
			}
		}
		else {
			goto _loop36;
		}
		
	}
	_loop36:;
	} // ( ... )*
	if ( inputState->guessing==0 ) {
#line 134 "modelica_lexer.g"
		_ttype = antlr::Token::SKIP;
#line 832 "modelica_lexer.cpp"
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mIDENT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = IDENT;
	int _saveIndex;
	
	mNONDIGIT(false);
	{ // ( ... )*
	for (;;) {
		switch ( LA(1)) {
		case 0x41 /* 'A' */ :
		case 0x42 /* 'B' */ :
		case 0x43 /* 'C' */ :
		case 0x44 /* 'D' */ :
		case 0x45 /* 'E' */ :
		case 0x46 /* 'F' */ :
		case 0x47 /* 'G' */ :
		case 0x48 /* 'H' */ :
		case 0x49 /* 'I' */ :
		case 0x4a /* 'J' */ :
		case 0x4b /* 'K' */ :
		case 0x4c /* 'L' */ :
		case 0x4d /* 'M' */ :
		case 0x4e /* 'N' */ :
		case 0x4f /* 'O' */ :
		case 0x50 /* 'P' */ :
		case 0x51 /* 'Q' */ :
		case 0x52 /* 'R' */ :
		case 0x53 /* 'S' */ :
		case 0x54 /* 'T' */ :
		case 0x55 /* 'U' */ :
		case 0x56 /* 'V' */ :
		case 0x57 /* 'W' */ :
		case 0x58 /* 'X' */ :
		case 0x59 /* 'Y' */ :
		case 0x5a /* 'Z' */ :
		case 0x5f /* '_' */ :
		case 0x61 /* 'a' */ :
		case 0x62 /* 'b' */ :
		case 0x63 /* 'c' */ :
		case 0x64 /* 'd' */ :
		case 0x65 /* 'e' */ :
		case 0x66 /* 'f' */ :
		case 0x67 /* 'g' */ :
		case 0x68 /* 'h' */ :
		case 0x69 /* 'i' */ :
		case 0x6a /* 'j' */ :
		case 0x6b /* 'k' */ :
		case 0x6c /* 'l' */ :
		case 0x6d /* 'm' */ :
		case 0x6e /* 'n' */ :
		case 0x6f /* 'o' */ :
		case 0x70 /* 'p' */ :
		case 0x71 /* 'q' */ :
		case 0x72 /* 'r' */ :
		case 0x73 /* 's' */ :
		case 0x74 /* 't' */ :
		case 0x75 /* 'u' */ :
		case 0x76 /* 'v' */ :
		case 0x77 /* 'w' */ :
		case 0x78 /* 'x' */ :
		case 0x79 /* 'y' */ :
		case 0x7a /* 'z' */ :
		{
			mNONDIGIT(false);
			break;
		}
		case 0x30 /* '0' */ :
		case 0x31 /* '1' */ :
		case 0x32 /* '2' */ :
		case 0x33 /* '3' */ :
		case 0x34 /* '4' */ :
		case 0x35 /* '5' */ :
		case 0x36 /* '6' */ :
		case 0x37 /* '7' */ :
		case 0x38 /* '8' */ :
		case 0x39 /* '9' */ :
		{
			mDIGIT(false);
			break;
		}
		default:
		{
			goto _loop39;
		}
		}
	}
	_loop39:;
	} // ( ... )*
	_ttype = testLiteralsTable(_ttype);
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mNONDIGIT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = NONDIGIT;
	int _saveIndex;
	
	{
	switch ( LA(1)) {
	case 0x5f /* '_' */ :
	{
		match('_');
		break;
	}
	case 0x61 /* 'a' */ :
	case 0x62 /* 'b' */ :
	case 0x63 /* 'c' */ :
	case 0x64 /* 'd' */ :
	case 0x65 /* 'e' */ :
	case 0x66 /* 'f' */ :
	case 0x67 /* 'g' */ :
	case 0x68 /* 'h' */ :
	case 0x69 /* 'i' */ :
	case 0x6a /* 'j' */ :
	case 0x6b /* 'k' */ :
	case 0x6c /* 'l' */ :
	case 0x6d /* 'm' */ :
	case 0x6e /* 'n' */ :
	case 0x6f /* 'o' */ :
	case 0x70 /* 'p' */ :
	case 0x71 /* 'q' */ :
	case 0x72 /* 'r' */ :
	case 0x73 /* 's' */ :
	case 0x74 /* 't' */ :
	case 0x75 /* 'u' */ :
	case 0x76 /* 'v' */ :
	case 0x77 /* 'w' */ :
	case 0x78 /* 'x' */ :
	case 0x79 /* 'y' */ :
	case 0x7a /* 'z' */ :
	{
		matchRange('a','z');
		break;
	}
	case 0x41 /* 'A' */ :
	case 0x42 /* 'B' */ :
	case 0x43 /* 'C' */ :
	case 0x44 /* 'D' */ :
	case 0x45 /* 'E' */ :
	case 0x46 /* 'F' */ :
	case 0x47 /* 'G' */ :
	case 0x48 /* 'H' */ :
	case 0x49 /* 'I' */ :
	case 0x4a /* 'J' */ :
	case 0x4b /* 'K' */ :
	case 0x4c /* 'L' */ :
	case 0x4d /* 'M' */ :
	case 0x4e /* 'N' */ :
	case 0x4f /* 'O' */ :
	case 0x50 /* 'P' */ :
	case 0x51 /* 'Q' */ :
	case 0x52 /* 'R' */ :
	case 0x53 /* 'S' */ :
	case 0x54 /* 'T' */ :
	case 0x55 /* 'U' */ :
	case 0x56 /* 'V' */ :
	case 0x57 /* 'W' */ :
	case 0x58 /* 'X' */ :
	case 0x59 /* 'Y' */ :
	case 0x5a /* 'Z' */ :
	{
		matchRange('A','Z');
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());
	}
	}
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mDIGIT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = DIGIT;
	int _saveIndex;
	
	matchRange('0','9');
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mEXPONENT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = EXPONENT;
	int _saveIndex;
	
	{
	switch ( LA(1)) {
	case 0x65 /* 'e' */ :
	{
		match('e');
		break;
	}
	case 0x45 /* 'E' */ :
	{
		match('E');
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());
	}
	}
	}
	{
	switch ( LA(1)) {
	case 0x2b /* '+' */ :
	{
		match('+');
		break;
	}
	case 0x2d /* '-' */ :
	{
		match('-');
		break;
	}
	case 0x30 /* '0' */ :
	case 0x31 /* '1' */ :
	case 0x32 /* '2' */ :
	case 0x33 /* '3' */ :
	case 0x34 /* '4' */ :
	case 0x35 /* '5' */ :
	case 0x36 /* '6' */ :
	case 0x37 /* '7' */ :
	case 0x38 /* '8' */ :
	case 0x39 /* '9' */ :
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());
	}
	}
	}
	{ // ( ... )+
	int _cnt47=0;
	for (;;) {
		if (((LA(1) >= 0x30 /* '0' */  && LA(1) <= 0x39 /* '9' */ ))) {
			mDIGIT(false);
		}
		else {
			if ( _cnt47>=1 ) { goto _loop47; } else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());}
		}
		
		_cnt47++;
	}
	_loop47:;
	}  // ( ... )+
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mUNSIGNED_INTEGER(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = UNSIGNED_INTEGER;
	int _saveIndex;
	
	{
	bool synPredMatched53 = false;
	if ((((LA(1) >= 0x30 /* '0' */  && LA(1) <= 0x39 /* '9' */ )) && (_tokenSet_3.member(LA(2))))) {
		int _m53 = mark();
		synPredMatched53 = true;
		inputState->guessing++;
		try {
			{
			{ // ( ... )+
			int _cnt52=0;
			for (;;) {
				if (((LA(1) >= 0x30 /* '0' */  && LA(1) <= 0x39 /* '9' */ ))) {
					mDIGIT(false);
				}
				else {
					if ( _cnt52>=1 ) { goto _loop52; } else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());}
				}
				
				_cnt52++;
			}
			_loop52:;
			}  // ( ... )+
			match('.');
			}
		}
		catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
			synPredMatched53 = false;
		}
		rewind(_m53);
		inputState->guessing--;
	}
	if ( synPredMatched53 ) {
		{ // ( ... )+
		int _cnt55=0;
		for (;;) {
			if (((LA(1) >= 0x30 /* '0' */  && LA(1) <= 0x39 /* '9' */ ))) {
				mDIGIT(false);
			}
			else {
				if ( _cnt55>=1 ) { goto _loop55; } else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());}
			}
			
			_cnt55++;
		}
		_loop55:;
		}  // ( ... )+
		{
		match('.');
		{ // ( ... )*
		for (;;) {
			if (((LA(1) >= 0x30 /* '0' */  && LA(1) <= 0x39 /* '9' */ ))) {
				mDIGIT(false);
			}
			else {
				goto _loop58;
			}
			
		}
		_loop58:;
		} // ( ... )*
		}
		if ( inputState->guessing==0 ) {
#line 157 "modelica_lexer.g"
			
							_ttype = UNSIGNED_REAL; 
						
#line 1186 "modelica_lexer.cpp"
		}
	}
	else if (((LA(1) >= 0x30 /* '0' */  && LA(1) <= 0x39 /* '9' */ )) && (true)) {
		{ // ( ... )+
		int _cnt60=0;
		for (;;) {
			if (((LA(1) >= 0x30 /* '0' */  && LA(1) <= 0x39 /* '9' */ ))) {
				mDIGIT(false);
			}
			else {
				if ( _cnt60>=1 ) { goto _loop60; } else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());}
			}
			
			_cnt60++;
		}
		_loop60:;
		}  // ( ... )+
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());
	}
	
	}
	{
	if ((LA(1) == 0x45 /* 'E' */  || LA(1) == 0x65 /* 'e' */ )) {
		mEXPONENT(false);
		if ( inputState->guessing==0 ) {
#line 162 "modelica_lexer.g"
			_ttype = UNSIGNED_REAL;
#line 1216 "modelica_lexer.cpp"
		}
	}
	else {
	}
	
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mSTRING(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = STRING;
	int _saveIndex;
	
	_saveIndex = text.length();
	match('"');
	text.erase(_saveIndex);
	{ // ( ... )*
	for (;;) {
		if ((_tokenSet_4.member(LA(1)))) {
			mSCHAR(false);
		}
		else if ((LA(1) == 0x5c /* '\\' */ )) {
			mSESCAPE(false);
		}
		else {
			goto _loop64;
		}
		
	}
	_loop64:;
	} // ( ... )*
	_saveIndex = text.length();
	match('"');
	text.erase(_saveIndex);
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mSCHAR(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = SCHAR;
	int _saveIndex;
	
	switch ( LA(1)) {
	case 0xa /* '\n' */ :
	case 0xd /* '\r' */ :
	{
		{
		{
		switch ( LA(1)) {
		case 0xa /* '\n' */ :
		{
			match('\n');
			break;
		}
		case 0xd /* '\r' */ :
		{
			match("\r\n");
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());
		}
		}
		}
		}
		if ( inputState->guessing==0 ) {
#line 169 "modelica_lexer.g"
			newline();
#line 1297 "modelica_lexer.cpp"
		}
		break;
	}
	case 0x9 /* '\t' */ :
	{
		match('\t');
		break;
	}
	default:
		if ((_tokenSet_5.member(LA(1)))) {
			{
			match(_tokenSet_5);
			}
		}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());
	}
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mSESCAPE(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = SESCAPE;
	int _saveIndex;
	
	match('\\');
	{
	switch ( LA(1)) {
	case 0x5c /* '\\' */ :
	{
		match('\\');
		break;
	}
	case 0x22 /* '"' */ :
	{
		match('"');
		break;
	}
	case 0x27 /* '\'' */ :
	{
		match("'");
		break;
	}
	case 0x3f /* '?' */ :
	{
		match('?');
		break;
	}
	case 0x61 /* 'a' */ :
	{
		match('a');
		break;
	}
	case 0x62 /* 'b' */ :
	{
		match('b');
		break;
	}
	case 0x66 /* 'f' */ :
	{
		match('f');
		break;
	}
	case 0x6e /* 'n' */ :
	{
		match('n');
		break;
	}
	case 0x72 /* 'r' */ :
	{
		match('r');
		break;
	}
	case 0x74 /* 't' */ :
	{
		match('t');
		break;
	}
	case 0x76 /* 'v' */ :
	{
		match('v');
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());
	}
	}
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void modelica_lexer::mESC(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = ESC;
	int _saveIndex;
	
	match('\\');
	{
	switch ( LA(1)) {
	case 0x22 /* '"' */ :
	{
		match('"');
		break;
	}
	case 0x5c /* '\\' */ :
	{
		match('\\');
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine(), getColumn());
	}
	}
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}


const unsigned long modelica_lexer::_tokenSet_0_data_[] = { 4294967288UL, 4294966271UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// NULL_TREE_LOOKAHEAD "algorithm" "and" "annotation" "block" "boundary" 
// "Code" "class" "connect" "connector" "constant" "discrete" "each" "else" 
// "elseif" "elsewhen" "end" "enumeration" "equation" "encapsulated" "extends" 
// "external" "false" "final" "flow" "for" "function" "if" "import" "in" 
// "initial" "inner" "input" "loop" "model" "not" "outer" "overload" "or" 
// "package" "parameter" "partial" "protected" "public" "record" "redeclare" 
// "replaceable" "results" "then" "true" "type" "unsigned_real" "when" 
// "while" "within" LPAR RPAR LBRACK RBRACK LBRACE RBRACE EQUALS ASSIGN 
// PLUS MINUS STAR SLASH DOT COMMA LESS LESSEQ GREATER GREATEREQ EQEQ LESSGT 
// COLON SEMICOLON POWER WS ML_COMMENT ML_COMMENT_CHAR SL_COMMENT IDENT 
// NONDIGIT DIGIT EXPONENT UNSIGNED_INTEGER STRING SCHAR SESCAPE ESC 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_lexer::_tokenSet_0(_tokenSet_0_data_,16);
const unsigned long modelica_lexer::_tokenSet_1_data_[] = { 4294958072UL, 4294966271UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// NULL_TREE_LOOKAHEAD "algorithm" "and" "annotation" "block" "boundary" 
// "Code" "connect" "connector" "discrete" "each" "else" "elseif" "elsewhen" 
// "end" "enumeration" "equation" "encapsulated" "extends" "external" "false" 
// "final" "flow" "for" "function" "if" "import" "in" "initial" "inner" 
// "input" "loop" "model" "not" "outer" "overload" "or" "package" "parameter" 
// "partial" "protected" "public" "record" "redeclare" "replaceable" "results" 
// "then" "true" "type" "unsigned_real" "when" "while" "within" LPAR RPAR 
// LBRACK RBRACK LBRACE RBRACE EQUALS ASSIGN PLUS MINUS STAR SLASH DOT 
// COMMA LESS LESSEQ GREATER GREATEREQ EQEQ LESSGT COLON SEMICOLON POWER 
// WS ML_COMMENT ML_COMMENT_CHAR SL_COMMENT IDENT NONDIGIT DIGIT EXPONENT 
// UNSIGNED_INTEGER STRING SCHAR SESCAPE ESC 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_lexer::_tokenSet_1(_tokenSet_1_data_,16);
const unsigned long modelica_lexer::_tokenSet_2_data_[] = { 4294958072UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// NULL_TREE_LOOKAHEAD "algorithm" "and" "annotation" "block" "boundary" 
// "Code" "connect" "connector" "discrete" "each" "else" "elseif" "elsewhen" 
// "end" "enumeration" "equation" "encapsulated" "extends" "external" "false" 
// "final" "flow" "for" "function" "if" "import" "in" "initial" "inner" 
// "input" "loop" "model" "not" "outer" "overload" "or" "output" "package" 
// "parameter" "partial" "protected" "public" "record" "redeclare" "replaceable" 
// "results" "then" "true" "type" "unsigned_real" "when" "while" "within" 
// LPAR RPAR LBRACK RBRACK LBRACE RBRACE EQUALS ASSIGN PLUS MINUS STAR 
// SLASH DOT COMMA LESS LESSEQ GREATER GREATEREQ EQEQ LESSGT COLON SEMICOLON 
// POWER WS ML_COMMENT ML_COMMENT_CHAR SL_COMMENT IDENT NONDIGIT DIGIT 
// EXPONENT UNSIGNED_INTEGER STRING SCHAR SESCAPE ESC 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_lexer::_tokenSet_2(_tokenSet_2_data_,16);
const unsigned long modelica_lexer::_tokenSet_3_data_[] = { 0UL, 67059712UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "protected" "record" "redeclare" "replaceable" "results" "then" "true" 
// "type" "unsigned_real" "when" "while" 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_lexer::_tokenSet_3(_tokenSet_3_data_,10);
const unsigned long modelica_lexer::_tokenSet_4_data_[] = { 4294967288UL, 4294967291UL, 4026531839UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// NULL_TREE_LOOKAHEAD "algorithm" "and" "annotation" "block" "boundary" 
// "Code" "class" "connect" "connector" "constant" "discrete" "each" "else" 
// "elseif" "elsewhen" "end" "enumeration" "equation" "encapsulated" "extends" 
// "external" "false" "final" "flow" "for" "function" "if" "import" "in" 
// "initial" "input" "loop" "model" "not" "outer" "overload" "or" "output" 
// "package" "parameter" "partial" "protected" "public" "record" "redeclare" 
// "replaceable" "results" "then" "true" "type" "unsigned_real" "when" 
// "while" "within" LPAR RPAR LBRACK RBRACK LBRACE RBRACE EQUALS ASSIGN 
// PLUS MINUS STAR SLASH DOT COMMA LESS LESSEQ GREATER GREATEREQ EQEQ LESSGT 
// COLON SEMICOLON POWER WS ML_COMMENT ML_COMMENT_CHAR SL_COMMENT IDENT 
// NONDIGIT DIGIT EXPONENT UNSIGNED_INTEGER STRING SESCAPE ESC 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_lexer::_tokenSet_4(_tokenSet_4_data_,16);
const unsigned long modelica_lexer::_tokenSet_5_data_[] = { 4294957560UL, 4294967291UL, 4026531839UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// NULL_TREE_LOOKAHEAD "algorithm" "and" "annotation" "block" "boundary" 
// "connect" "connector" "discrete" "each" "else" "elseif" "elsewhen" "end" 
// "enumeration" "equation" "encapsulated" "extends" "external" "false" 
// "final" "flow" "for" "function" "if" "import" "in" "initial" "input" 
// "loop" "model" "not" "outer" "overload" "or" "output" "package" "parameter" 
// "partial" "protected" "public" "record" "redeclare" "replaceable" "results" 
// "then" "true" "type" "unsigned_real" "when" "while" "within" LPAR RPAR 
// LBRACK RBRACK LBRACE RBRACE EQUALS ASSIGN PLUS MINUS STAR SLASH DOT 
// COMMA LESS LESSEQ GREATER GREATEREQ EQEQ LESSGT COLON SEMICOLON POWER 
// WS ML_COMMENT ML_COMMENT_CHAR SL_COMMENT IDENT NONDIGIT DIGIT EXPONENT 
// UNSIGNED_INTEGER STRING SESCAPE ESC 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_lexer::_tokenSet_5(_tokenSet_5_data_,16);


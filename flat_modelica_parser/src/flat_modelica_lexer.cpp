/* $ANTLR 2.7.1: "flat_modelica_lexer.g" -> "flat_modelica_lexer.cpp"$ */
#include "flat_modelica_lexer.hpp"
#include "antlr/CharBuffer.hpp"
#include "antlr/TokenStreamException.hpp"
#include "antlr/TokenStreamIOException.hpp"
#include "antlr/TokenStreamRecognitionException.hpp"
#include "antlr/CharStreamException.hpp"
#include "antlr/CharStreamIOException.hpp"
#include "antlr/NoViableAltForCharException.hpp"

#line 1 "flat_modelica_lexer.g"

#line 14 "flat_modelica_lexer.cpp"
flat_modelica_lexer::flat_modelica_lexer(ANTLR_USE_NAMESPACE(std)istream& in)
	: ANTLR_USE_NAMESPACE(antlr)CharScanner(new ANTLR_USE_NAMESPACE(antlr)CharBuffer(in))
{
	setCaseSensitive(true);
	initLiterals();
}

flat_modelica_lexer::flat_modelica_lexer(ANTLR_USE_NAMESPACE(antlr)InputBuffer& ib)
	: ANTLR_USE_NAMESPACE(antlr)CharScanner(ib)
{
	setCaseSensitive(true);
	initLiterals();
}

flat_modelica_lexer::flat_modelica_lexer(const ANTLR_USE_NAMESPACE(antlr)LexerSharedInputState& state)
	: ANTLR_USE_NAMESPACE(antlr)CharScanner(state)
{
	setCaseSensitive(true);
	initLiterals();
}

void flat_modelica_lexer::initLiterals()
{
	literals["external"] = 23;
	literals["elsewhen"] = 17;
	literals["loop"] = 35;
	literals["for"] = 27;
	literals["class"] = 9;
	literals["block"] = 7;
	literals["redeclare"] = 47;
	literals["final"] = 25;
	literals["parameter"] = 42;
	literals["false"] = 24;
	literals["true"] = 51;
	literals["connect"] = 10;
	literals["and"] = 5;
	literals["boundary"] = 8;
	literals["results"] = 49;
	literals["import"] = 30;
	literals["end"] = 18;
	literals["outer"] = 38;
	literals["when"] = 54;
	literals["connector"] = 11;
	literals["record"] = 46;
	literals["within"] = 56;
	literals["algorithm"] = 4;
	literals["type"] = 52;
	literals["in"] = 31;
	literals["inner"] = 33;
	literals["extends"] = 22;
	literals["function"] = 28;
	literals["output"] = 40;
	literals["equation"] = 20;
	literals["elseif"] = 16;
	literals["each"] = 14;
	literals["while"] = 55;
	literals["unsigned_real"] = 53;
	literals["or"] = 39;
	literals["constant"] = 12;
	literals["replaceable"] = 48;
	literals["discrete"] = 13;
	literals["model"] = 36;
	literals["protected"] = 44;
	literals["annotation"] = 6;
	literals["encapsulated"] = 21;
	literals["initial"] = 32;
	literals["input"] = 34;
	literals["partial"] = 43;
	literals["if"] = 29;
	literals["enumeration"] = 19;
	literals["public"] = 45;
	literals["package"] = 41;
	literals["else"] = 15;
	literals["flow"] = 26;
	literals["not"] = 37;
	literals["then"] = 50;
}
bool flat_modelica_lexer::getCaseSensitiveLiterals() const
{
	return true;
}

ANTLR_USE_NAMESPACE(antlr)RefToken flat_modelica_lexer::nextToken()
{
	ANTLR_USE_NAMESPACE(antlr)RefToken theRetToken;
	for (;;) {
		ANTLR_USE_NAMESPACE(antlr)RefToken theRetToken;
		int _ttype = ANTLR_USE_NAMESPACE(antlr)Token::INVALID_TYPE;
		resetText();
		try {   // for char stream error handling
			try {   // for lexical error handling
				switch ( LA(1)) {
				case static_cast<unsigned char>('('):
				{
					mLPAR(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>(')'):
				{
					mRPAR(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>('['):
				{
					mLBRACK(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>(']'):
				{
					mRBRACK(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>('{'):
				{
					mLBRACE(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>('}'):
				{
					mRBRACE(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>('+'):
				{
					mPLUS(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>('-'):
				{
					mMINUS(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>('*'):
				{
					mSTAR(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>('.'):
				{
					mDOT(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>(','):
				{
					mCOMMA(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>(';'):
				{
					mSEMICOLON(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>('^'):
				{
					mPOWER(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>('\t'):
				case static_cast<unsigned char>('\n'):
				case static_cast<unsigned char>('\r'):
				case static_cast<unsigned char>(' '):
				{
					mWS(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>('A'):
				case static_cast<unsigned char>('B'):
				case static_cast<unsigned char>('C'):
				case static_cast<unsigned char>('D'):
				case static_cast<unsigned char>('E'):
				case static_cast<unsigned char>('F'):
				case static_cast<unsigned char>('G'):
				case static_cast<unsigned char>('H'):
				case static_cast<unsigned char>('I'):
				case static_cast<unsigned char>('J'):
				case static_cast<unsigned char>('K'):
				case static_cast<unsigned char>('L'):
				case static_cast<unsigned char>('M'):
				case static_cast<unsigned char>('N'):
				case static_cast<unsigned char>('O'):
				case static_cast<unsigned char>('P'):
				case static_cast<unsigned char>('Q'):
				case static_cast<unsigned char>('R'):
				case static_cast<unsigned char>('S'):
				case static_cast<unsigned char>('T'):
				case static_cast<unsigned char>('U'):
				case static_cast<unsigned char>('V'):
				case static_cast<unsigned char>('W'):
				case static_cast<unsigned char>('X'):
				case static_cast<unsigned char>('Y'):
				case static_cast<unsigned char>('Z'):
				case static_cast<unsigned char>('_'):
				case static_cast<unsigned char>('a'):
				case static_cast<unsigned char>('b'):
				case static_cast<unsigned char>('c'):
				case static_cast<unsigned char>('d'):
				case static_cast<unsigned char>('e'):
				case static_cast<unsigned char>('f'):
				case static_cast<unsigned char>('g'):
				case static_cast<unsigned char>('h'):
				case static_cast<unsigned char>('i'):
				case static_cast<unsigned char>('j'):
				case static_cast<unsigned char>('k'):
				case static_cast<unsigned char>('l'):
				case static_cast<unsigned char>('m'):
				case static_cast<unsigned char>('n'):
				case static_cast<unsigned char>('o'):
				case static_cast<unsigned char>('p'):
				case static_cast<unsigned char>('q'):
				case static_cast<unsigned char>('r'):
				case static_cast<unsigned char>('s'):
				case static_cast<unsigned char>('t'):
				case static_cast<unsigned char>('u'):
				case static_cast<unsigned char>('v'):
				case static_cast<unsigned char>('w'):
				case static_cast<unsigned char>('x'):
				case static_cast<unsigned char>('y'):
				case static_cast<unsigned char>('z'):
				{
					mIDENT(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>('0'):
				case static_cast<unsigned char>('1'):
				case static_cast<unsigned char>('2'):
				case static_cast<unsigned char>('3'):
				case static_cast<unsigned char>('4'):
				case static_cast<unsigned char>('5'):
				case static_cast<unsigned char>('6'):
				case static_cast<unsigned char>('7'):
				case static_cast<unsigned char>('8'):
				case static_cast<unsigned char>('9'):
				{
					mUNSIGNED_INTEGER(true);
					theRetToken=_returnToken;
					break;
				}
				case static_cast<unsigned char>('"'):
				{
					mSTRING(true);
					theRetToken=_returnToken;
					break;
				}
				default:
					if ((LA(1)==static_cast<unsigned char>(':')) && (LA(2)==static_cast<unsigned char>('='))) {
						mASSIGN(true);
						theRetToken=_returnToken;
					}
					else if ((LA(1)==static_cast<unsigned char>('<')) && (LA(2)==static_cast<unsigned char>('='))) {
						mLESSEQ(true);
						theRetToken=_returnToken;
					}
					else if ((LA(1)==static_cast<unsigned char>('>')) && (LA(2)==static_cast<unsigned char>('='))) {
						mGREATEREQ(true);
						theRetToken=_returnToken;
					}
					else if ((LA(1)==static_cast<unsigned char>('=')) && (LA(2)==static_cast<unsigned char>('='))) {
						mEQEQ(true);
						theRetToken=_returnToken;
					}
					else if ((LA(1)==static_cast<unsigned char>('<')) && (LA(2)==static_cast<unsigned char>('>'))) {
						mLESSGT(true);
						theRetToken=_returnToken;
					}
					else if ((LA(1)==static_cast<unsigned char>('/')) && (LA(2)==static_cast<unsigned char>('*'))) {
						mML_COMMENT(true);
						theRetToken=_returnToken;
					}
					else if ((LA(1)==static_cast<unsigned char>('/')) && (LA(2)==static_cast<unsigned char>('/'))) {
						mSL_COMMENT(true);
						theRetToken=_returnToken;
					}
					else if ((LA(1)==static_cast<unsigned char>('=')) && (true)) {
						mEQUALS(true);
						theRetToken=_returnToken;
					}
					else if ((LA(1)==static_cast<unsigned char>('/')) && (true)) {
						mSLASH(true);
						theRetToken=_returnToken;
					}
					else if ((LA(1)==static_cast<unsigned char>('<')) && (true)) {
						mLESS(true);
						theRetToken=_returnToken;
					}
					else if ((LA(1)==static_cast<unsigned char>('>')) && (true)) {
						mGREATER(true);
						theRetToken=_returnToken;
					}
					else if ((LA(1)==static_cast<unsigned char>(':')) && (true)) {
						mCOLON(true);
						theRetToken=_returnToken;
					}
				else {
					if (LA(1)==EOF_CHAR) {uponEOF(); _returnToken = makeToken(ANTLR_USE_NAMESPACE(antlr)Token::EOF_TYPE);}
				else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());}
				}
				}
				if ( !_returnToken ) goto tryAgain; // found SKIP token
				_ttype = _returnToken->getType();
				_returnToken->setType(_ttype);
				return _returnToken;
			}
			catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& e) {
				throw ANTLR_USE_NAMESPACE(antlr)TokenStreamRecognitionException(e);
			}
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

void flat_modelica_lexer::mLPAR(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = LPAR;
	int _saveIndex;
	
	match(static_cast<unsigned char>('('));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mRPAR(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = RPAR;
	int _saveIndex;
	
	match(static_cast<unsigned char>(')'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mLBRACK(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = LBRACK;
	int _saveIndex;
	
	match(static_cast<unsigned char>('['));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mRBRACK(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = RBRACK;
	int _saveIndex;
	
	match(static_cast<unsigned char>(']'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mLBRACE(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = LBRACE;
	int _saveIndex;
	
	match(static_cast<unsigned char>('{'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mRBRACE(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = RBRACE;
	int _saveIndex;
	
	match(static_cast<unsigned char>('}'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mEQUALS(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = EQUALS;
	int _saveIndex;
	
	match(static_cast<unsigned char>('='));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mASSIGN(bool _createToken) {
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

void flat_modelica_lexer::mPLUS(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = PLUS;
	int _saveIndex;
	
	match(static_cast<unsigned char>('+'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mMINUS(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = MINUS;
	int _saveIndex;
	
	match(static_cast<unsigned char>('-'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mSTAR(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = STAR;
	int _saveIndex;
	
	match(static_cast<unsigned char>('*'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mSLASH(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = SLASH;
	int _saveIndex;
	
	match(static_cast<unsigned char>('/'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mDOT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = DOT;
	int _saveIndex;
	
	match(static_cast<unsigned char>('.'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mCOMMA(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = COMMA;
	int _saveIndex;
	
	match(static_cast<unsigned char>(','));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mLESS(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = LESS;
	int _saveIndex;
	
	match(static_cast<unsigned char>('<'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mLESSEQ(bool _createToken) {
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

void flat_modelica_lexer::mGREATER(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = GREATER;
	int _saveIndex;
	
	match(static_cast<unsigned char>('>'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mGREATEREQ(bool _createToken) {
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

void flat_modelica_lexer::mEQEQ(bool _createToken) {
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

void flat_modelica_lexer::mLESSGT(bool _createToken) {
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

void flat_modelica_lexer::mCOLON(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = COLON;
	int _saveIndex;
	
	match(static_cast<unsigned char>(':'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mSEMICOLON(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = SEMICOLON;
	int _saveIndex;
	
	match(static_cast<unsigned char>(';'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mPOWER(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = POWER;
	int _saveIndex;
	
	match(static_cast<unsigned char>('^'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mWS(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = WS;
	int _saveIndex;
	
	{
	switch ( LA(1)) {
	case static_cast<unsigned char>(' '):
	{
		match(static_cast<unsigned char>(' '));
		break;
	}
	case static_cast<unsigned char>('\t'):
	{
		match(static_cast<unsigned char>('\t'));
		break;
	}
	case static_cast<unsigned char>('\n'):
	case static_cast<unsigned char>('\r'):
	{
		{
		if ((LA(1)==static_cast<unsigned char>('\r')) && (LA(2)==static_cast<unsigned char>('\n'))) {
			match("\r\n");
		}
		else if ((LA(1)==static_cast<unsigned char>('\r')) && (true)) {
			match(static_cast<unsigned char>('\r'));
		}
		else if ((LA(1)==static_cast<unsigned char>('\n'))) {
			match(static_cast<unsigned char>('\n'));
		}
		else {
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());
		}
		
		}
		if ( inputState->guessing==0 ) {
#line 113 "flat_modelica_lexer.g"
			newline();
#line 706 "flat_modelica_lexer.cpp"
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());
	}
	}
	}
	if ( inputState->guessing==0 ) {
#line 115 "flat_modelica_lexer.g"
		_ttype = antlr::Token::SKIP;
#line 719 "flat_modelica_lexer.cpp"
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mML_COMMENT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = ML_COMMENT;
	int _saveIndex;
	
	match("/*");
	{
	for (;;) {
		if (((LA(1)==static_cast<unsigned char>('*')) && ((LA(2) >= static_cast<unsigned char>('\3') && LA(2) <= static_cast<unsigned char>('\377'))))&&(LA(2)!='/')) {
			match(static_cast<unsigned char>('*'));
		}
		else if ((_tokenSet_0.member(LA(1)))) {
			mML_COMMENT_CHAR(false);
		}
		else {
			goto _loop29;
		}
		
	}
	_loop29:;
	}
	match("*/");
	if ( inputState->guessing==0 ) {
#line 122 "flat_modelica_lexer.g"
		_ttype = antlr::Token::SKIP;
#line 754 "flat_modelica_lexer.cpp"
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mML_COMMENT_CHAR(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = ML_COMMENT_CHAR;
	int _saveIndex;
	
	if ((LA(1)==static_cast<unsigned char>('\n')||LA(1)==static_cast<unsigned char>('\r'))) {
		{
		switch ( LA(1)) {
		case static_cast<unsigned char>('\r'):
		{
			match("\r\n");
			break;
		}
		case static_cast<unsigned char>('\n'):
		{
			match(static_cast<unsigned char>('\n'));
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());
		}
		}
		}
		if ( inputState->guessing==0 ) {
#line 126 "flat_modelica_lexer.g"
			newline();
#line 791 "flat_modelica_lexer.cpp"
		}
	}
	else if ((_tokenSet_1.member(LA(1)))) {
		{
		match(_tokenSet_1);
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());
	}
	
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mSL_COMMENT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = SL_COMMENT;
	int _saveIndex;
	
	match("//");
	{
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
	}
	if ( inputState->guessing==0 ) {
#line 132 "flat_modelica_lexer.g"
		_ttype = antlr::Token::SKIP;
#line 834 "flat_modelica_lexer.cpp"
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mIDENT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = IDENT;
	int _saveIndex;
	
	mNONDIGIT(false);
	{
	for (;;) {
		switch ( LA(1)) {
		case static_cast<unsigned char>('A'):
		case static_cast<unsigned char>('B'):
		case static_cast<unsigned char>('C'):
		case static_cast<unsigned char>('D'):
		case static_cast<unsigned char>('E'):
		case static_cast<unsigned char>('F'):
		case static_cast<unsigned char>('G'):
		case static_cast<unsigned char>('H'):
		case static_cast<unsigned char>('I'):
		case static_cast<unsigned char>('J'):
		case static_cast<unsigned char>('K'):
		case static_cast<unsigned char>('L'):
		case static_cast<unsigned char>('M'):
		case static_cast<unsigned char>('N'):
		case static_cast<unsigned char>('O'):
		case static_cast<unsigned char>('P'):
		case static_cast<unsigned char>('Q'):
		case static_cast<unsigned char>('R'):
		case static_cast<unsigned char>('S'):
		case static_cast<unsigned char>('T'):
		case static_cast<unsigned char>('U'):
		case static_cast<unsigned char>('V'):
		case static_cast<unsigned char>('W'):
		case static_cast<unsigned char>('X'):
		case static_cast<unsigned char>('Y'):
		case static_cast<unsigned char>('Z'):
		case static_cast<unsigned char>('_'):
		case static_cast<unsigned char>('a'):
		case static_cast<unsigned char>('b'):
		case static_cast<unsigned char>('c'):
		case static_cast<unsigned char>('d'):
		case static_cast<unsigned char>('e'):
		case static_cast<unsigned char>('f'):
		case static_cast<unsigned char>('g'):
		case static_cast<unsigned char>('h'):
		case static_cast<unsigned char>('i'):
		case static_cast<unsigned char>('j'):
		case static_cast<unsigned char>('k'):
		case static_cast<unsigned char>('l'):
		case static_cast<unsigned char>('m'):
		case static_cast<unsigned char>('n'):
		case static_cast<unsigned char>('o'):
		case static_cast<unsigned char>('p'):
		case static_cast<unsigned char>('q'):
		case static_cast<unsigned char>('r'):
		case static_cast<unsigned char>('s'):
		case static_cast<unsigned char>('t'):
		case static_cast<unsigned char>('u'):
		case static_cast<unsigned char>('v'):
		case static_cast<unsigned char>('w'):
		case static_cast<unsigned char>('x'):
		case static_cast<unsigned char>('y'):
		case static_cast<unsigned char>('z'):
		{
			mNONDIGIT(false);
			break;
		}
		case static_cast<unsigned char>('0'):
		case static_cast<unsigned char>('1'):
		case static_cast<unsigned char>('2'):
		case static_cast<unsigned char>('3'):
		case static_cast<unsigned char>('4'):
		case static_cast<unsigned char>('5'):
		case static_cast<unsigned char>('6'):
		case static_cast<unsigned char>('7'):
		case static_cast<unsigned char>('8'):
		case static_cast<unsigned char>('9'):
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
	}
	_ttype = testLiteralsTable(_ttype);
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mNONDIGIT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = NONDIGIT;
	int _saveIndex;
	
	{
	switch ( LA(1)) {
	case static_cast<unsigned char>('_'):
	{
		match(static_cast<unsigned char>('_'));
		break;
	}
	case static_cast<unsigned char>('a'):
	case static_cast<unsigned char>('b'):
	case static_cast<unsigned char>('c'):
	case static_cast<unsigned char>('d'):
	case static_cast<unsigned char>('e'):
	case static_cast<unsigned char>('f'):
	case static_cast<unsigned char>('g'):
	case static_cast<unsigned char>('h'):
	case static_cast<unsigned char>('i'):
	case static_cast<unsigned char>('j'):
	case static_cast<unsigned char>('k'):
	case static_cast<unsigned char>('l'):
	case static_cast<unsigned char>('m'):
	case static_cast<unsigned char>('n'):
	case static_cast<unsigned char>('o'):
	case static_cast<unsigned char>('p'):
	case static_cast<unsigned char>('q'):
	case static_cast<unsigned char>('r'):
	case static_cast<unsigned char>('s'):
	case static_cast<unsigned char>('t'):
	case static_cast<unsigned char>('u'):
	case static_cast<unsigned char>('v'):
	case static_cast<unsigned char>('w'):
	case static_cast<unsigned char>('x'):
	case static_cast<unsigned char>('y'):
	case static_cast<unsigned char>('z'):
	{
		matchRange(static_cast<unsigned char>('a'),static_cast<unsigned char>('z'));
		break;
	}
	case static_cast<unsigned char>('A'):
	case static_cast<unsigned char>('B'):
	case static_cast<unsigned char>('C'):
	case static_cast<unsigned char>('D'):
	case static_cast<unsigned char>('E'):
	case static_cast<unsigned char>('F'):
	case static_cast<unsigned char>('G'):
	case static_cast<unsigned char>('H'):
	case static_cast<unsigned char>('I'):
	case static_cast<unsigned char>('J'):
	case static_cast<unsigned char>('K'):
	case static_cast<unsigned char>('L'):
	case static_cast<unsigned char>('M'):
	case static_cast<unsigned char>('N'):
	case static_cast<unsigned char>('O'):
	case static_cast<unsigned char>('P'):
	case static_cast<unsigned char>('Q'):
	case static_cast<unsigned char>('R'):
	case static_cast<unsigned char>('S'):
	case static_cast<unsigned char>('T'):
	case static_cast<unsigned char>('U'):
	case static_cast<unsigned char>('V'):
	case static_cast<unsigned char>('W'):
	case static_cast<unsigned char>('X'):
	case static_cast<unsigned char>('Y'):
	case static_cast<unsigned char>('Z'):
	{
		matchRange(static_cast<unsigned char>('A'),static_cast<unsigned char>('Z'));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());
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

void flat_modelica_lexer::mDIGIT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = DIGIT;
	int _saveIndex;
	
	matchRange(static_cast<unsigned char>('0'),static_cast<unsigned char>('9'));
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mEXPONENT(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = EXPONENT;
	int _saveIndex;
	
	{
	switch ( LA(1)) {
	case static_cast<unsigned char>('e'):
	{
		match(static_cast<unsigned char>('e'));
		break;
	}
	case static_cast<unsigned char>('E'):
	{
		match(static_cast<unsigned char>('E'));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());
	}
	}
	}
	{
	switch ( LA(1)) {
	case static_cast<unsigned char>('+'):
	{
		match(static_cast<unsigned char>('+'));
		break;
	}
	case static_cast<unsigned char>('-'):
	{
		match(static_cast<unsigned char>('-'));
		break;
	}
	case static_cast<unsigned char>('0'):
	case static_cast<unsigned char>('1'):
	case static_cast<unsigned char>('2'):
	case static_cast<unsigned char>('3'):
	case static_cast<unsigned char>('4'):
	case static_cast<unsigned char>('5'):
	case static_cast<unsigned char>('6'):
	case static_cast<unsigned char>('7'):
	case static_cast<unsigned char>('8'):
	case static_cast<unsigned char>('9'):
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());
	}
	}
	}
	{
	int _cnt47=0;
	for (;;) {
		if (((LA(1) >= static_cast<unsigned char>('0') && LA(1) <= static_cast<unsigned char>('9')))) {
			mDIGIT(false);
		}
		else {
			if ( _cnt47>=1 ) { goto _loop47; } else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());}
		}
		
		_cnt47++;
	}
	_loop47:;
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mUNSIGNED_INTEGER(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = UNSIGNED_INTEGER;
	int _saveIndex;
	
	{
	bool synPredMatched53 = false;
	if ((((LA(1) >= static_cast<unsigned char>('0') && LA(1) <= static_cast<unsigned char>('9'))) && (_tokenSet_3.member(LA(2))))) {
		int _m53 = mark();
		synPredMatched53 = true;
		inputState->guessing++;
		try {
			{
			{
			int _cnt52=0;
			for (;;) {
				if (((LA(1) >= static_cast<unsigned char>('0') && LA(1) <= static_cast<unsigned char>('9')))) {
					mDIGIT(false);
				}
				else {
					if ( _cnt52>=1 ) { goto _loop52; } else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());}
				}
				
				_cnt52++;
			}
			_loop52:;
			}
			match(static_cast<unsigned char>('.'));
			}
		}
		catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException& pe) {
			synPredMatched53 = false;
		}
		rewind(_m53);
		inputState->guessing--;
	}
	if ( synPredMatched53 ) {
		{
		int _cnt55=0;
		for (;;) {
			if (((LA(1) >= static_cast<unsigned char>('0') && LA(1) <= static_cast<unsigned char>('9')))) {
				mDIGIT(false);
			}
			else {
				if ( _cnt55>=1 ) { goto _loop55; } else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());}
			}
			
			_cnt55++;
		}
		_loop55:;
		}
		{
		match(static_cast<unsigned char>('.'));
		{
		int _cnt58=0;
		for (;;) {
			if (((LA(1) >= static_cast<unsigned char>('0') && LA(1) <= static_cast<unsigned char>('9')))) {
				mDIGIT(false);
			}
			else {
				if ( _cnt58>=1 ) { goto _loop58; } else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());}
			}
			
			_cnt58++;
		}
		_loop58:;
		}
		}
		if ( inputState->guessing==0 ) {
#line 154 "flat_modelica_lexer.g"
			
							_ttype = UNSIGNED_REAL; 
						
#line 1190 "flat_modelica_lexer.cpp"
		}
	}
	else if (((LA(1) >= static_cast<unsigned char>('0') && LA(1) <= static_cast<unsigned char>('9'))) && (true)) {
		{
		int _cnt60=0;
		for (;;) {
			if (((LA(1) >= static_cast<unsigned char>('0') && LA(1) <= static_cast<unsigned char>('9')))) {
				mDIGIT(false);
			}
			else {
				if ( _cnt60>=1 ) { goto _loop60; } else {throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());}
			}
			
			_cnt60++;
		}
		_loop60:;
		}
	}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());
	}
	
	}
	{
	if ((LA(1)==static_cast<unsigned char>('E')||LA(1)==static_cast<unsigned char>('e'))) {
		mEXPONENT(false);
		if ( inputState->guessing==0 ) {
#line 159 "flat_modelica_lexer.g"
			_ttype = UNSIGNED_REAL;
#line 1220 "flat_modelica_lexer.cpp"
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

void flat_modelica_lexer::mSTRING(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = STRING;
	int _saveIndex;
	
	_saveIndex=text.length();
	match(static_cast<unsigned char>('"'));
	text.erase(_saveIndex);
	{
	for (;;) {
		if ((_tokenSet_4.member(LA(1)))) {
			mSCHAR(false);
		}
		else if ((LA(1)==static_cast<unsigned char>('\\'))) {
			mSESCAPE(false);
		}
		else {
			goto _loop64;
		}
		
	}
	_loop64:;
	}
	_saveIndex=text.length();
	match(static_cast<unsigned char>('"'));
	text.erase(_saveIndex);
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mSCHAR(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = SCHAR;
	int _saveIndex;
	
	switch ( LA(1)) {
	case static_cast<unsigned char>('\n'):
	case static_cast<unsigned char>('\r'):
	{
		{
		{
		switch ( LA(1)) {
		case static_cast<unsigned char>('\n'):
		{
			match(static_cast<unsigned char>('\n'));
			break;
		}
		case static_cast<unsigned char>('\r'):
		{
			match("\r\n");
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());
		}
		}
		}
		}
		if ( inputState->guessing==0 ) {
#line 166 "flat_modelica_lexer.g"
			newline();
#line 1301 "flat_modelica_lexer.cpp"
		}
		break;
	}
	case static_cast<unsigned char>('\t'):
	{
		match(static_cast<unsigned char>('\t'));
		break;
	}
	default:
		if ((_tokenSet_5.member(LA(1)))) {
			{
			match(_tokenSet_5);
			}
		}
	else {
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());
	}
	}
	if ( _createToken && _token==ANTLR_USE_NAMESPACE(antlr)nullToken && _ttype!=ANTLR_USE_NAMESPACE(antlr)Token::SKIP ) {
	   _token = makeToken(_ttype);
	   _token->setText(text.substr(_begin, text.length()-_begin));
	}
	_returnToken = _token;
	_saveIndex=0;
}

void flat_modelica_lexer::mSESCAPE(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = SESCAPE;
	int _saveIndex;
	
	match(static_cast<unsigned char>('\\'));
	{
	switch ( LA(1)) {
	case static_cast<unsigned char>('\\'):
	{
		match(static_cast<unsigned char>('\\'));
		break;
	}
	case static_cast<unsigned char>('"'):
	{
		match(static_cast<unsigned char>('"'));
		break;
	}
	case static_cast<unsigned char>('\''):
	{
		match("'");
		break;
	}
	case static_cast<unsigned char>('?'):
	{
		match(static_cast<unsigned char>('?'));
		break;
	}
	case static_cast<unsigned char>('a'):
	{
		match(static_cast<unsigned char>('a'));
		break;
	}
	case static_cast<unsigned char>('b'):
	{
		match(static_cast<unsigned char>('b'));
		break;
	}
	case static_cast<unsigned char>('f'):
	{
		match(static_cast<unsigned char>('f'));
		break;
	}
	case static_cast<unsigned char>('n'):
	{
		match(static_cast<unsigned char>('n'));
		break;
	}
	case static_cast<unsigned char>('r'):
	{
		match(static_cast<unsigned char>('r'));
		break;
	}
	case static_cast<unsigned char>('t'):
	{
		match(static_cast<unsigned char>('t'));
		break;
	}
	case static_cast<unsigned char>('v'):
	{
		match(static_cast<unsigned char>('v'));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());
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

void flat_modelica_lexer::mESC(bool _createToken) {
	int _ttype; ANTLR_USE_NAMESPACE(antlr)RefToken _token; int _begin=text.length();
	_ttype = ESC;
	int _saveIndex;
	
	match(static_cast<unsigned char>('\\'));
	{
	switch ( LA(1)) {
	case static_cast<unsigned char>('"'):
	{
		match(static_cast<unsigned char>('"'));
		break;
	}
	case static_cast<unsigned char>('\\'):
	{
		match(static_cast<unsigned char>('\\'));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltForCharException(LA(1), getFilename(), getLine());
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


const unsigned long flat_modelica_lexer::_tokenSet_0_data_[] = { 4294967288UL, 4294966271UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_lexer::_tokenSet_0(_tokenSet_0_data_,16);
const unsigned long flat_modelica_lexer::_tokenSet_1_data_[] = { 4294958072UL, 4294966271UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_lexer::_tokenSet_1(_tokenSet_1_data_,16);
const unsigned long flat_modelica_lexer::_tokenSet_2_data_[] = { 4294958072UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_lexer::_tokenSet_2(_tokenSet_2_data_,16);
const unsigned long flat_modelica_lexer::_tokenSet_3_data_[] = { 0UL, 67059712UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_lexer::_tokenSet_3(_tokenSet_3_data_,10);
const unsigned long flat_modelica_lexer::_tokenSet_4_data_[] = { 4294967288UL, 4294967291UL, 4026531839UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_lexer::_tokenSet_4(_tokenSet_4_data_,16);
const unsigned long flat_modelica_lexer::_tokenSet_5_data_[] = { 4294957560UL, 4294967291UL, 4026531839UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 4294967295UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_lexer::_tokenSet_5(_tokenSet_5_data_,16);


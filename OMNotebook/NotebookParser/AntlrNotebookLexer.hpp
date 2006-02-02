#ifndef INC_AntlrNotebookLexer_hpp_
#define INC_AntlrNotebookLexer_hpp_

#include <antlr/config.hpp>
/* $ANTLR 2.7.4: "lexer.g" -> "AntlrNotebookLexer.hpp"$ */
#include <antlr/CommonToken.hpp>
#include <antlr/InputBuffer.hpp>
#include <antlr/BitSet.hpp>
#include "notebookgrammarTokenTypes.hpp"
#include <antlr/CharScanner.hpp>
class CUSTOM_API AntlrNotebookLexer : public ANTLR_USE_NAMESPACE(antlr)CharScanner, public notebookgrammarTokenTypes
{
private:
	void initLiterals();
public:
	bool getCaseSensitiveLiterals() const
	{
		return true;
	}
public:
	AntlrNotebookLexer(ANTLR_USE_NAMESPACE(std)istream& in);
	AntlrNotebookLexer(ANTLR_USE_NAMESPACE(antlr)InputBuffer& ib);
	AntlrNotebookLexer(const ANTLR_USE_NAMESPACE(antlr)LexerSharedInputState& state);
	ANTLR_USE_NAMESPACE(antlr)RefToken nextToken();
	public: void mRBRACK(bool _createToken);
	public: void mLBRACK(bool _createToken);
	public: void mRCURLY(bool _createToken);
	public: void mLCURLY(bool _createToken);
	public: void mCOMMA(bool _createToken);
	public: void mTHICK(bool _createToken);
	public: void mCOMMENTSTART(bool _createToken);
	public: void mCOMMENTEND(bool _createToken);
	public: void mNUMBER(bool _createToken);
	protected: void mDIGIT(bool _createToken);
	protected: void mEXP(bool _createToken);
	public: void mID(bool _createToken);
	public: void mQSTRING(bool _createToken);
	public: void mWHITESPACE(bool _createToken);
	public: void mCOMMENT(bool _createToken);
private:
	
	static const unsigned long _tokenSet_0_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_0;
	static const unsigned long _tokenSet_1_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_1;
	static const unsigned long _tokenSet_2_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_2;
	static const unsigned long _tokenSet_3_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_3;
	static const unsigned long _tokenSet_4_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_4;
	static const unsigned long _tokenSet_5_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_5;
	static const unsigned long _tokenSet_6_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_6;
};

#endif /*INC_AntlrNotebookLexer_hpp_*/

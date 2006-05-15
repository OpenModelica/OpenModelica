#ifndef INC_modelica_lexer_hpp_
#define INC_modelica_lexer_hpp_

#include <antlr/config.hpp>
/* $ANTLR 2.7.5rc2 (20050108): "modelica_lexer.g" -> "modelica_lexer.hpp"$ */
#include <antlr/CommonToken.hpp>
#include <antlr/InputBuffer.hpp>
#include <antlr/BitSet.hpp>
#include "modelicaTokenTypes.hpp"
#include <antlr/CharScanner.hpp>
#line 1 "modelica_lexer.g"



#line 16 "modelica_lexer.hpp"
class CUSTOM_API modelica_lexer : public ANTLR_USE_NAMESPACE(antlr)CharScanner, public modelicaTokenTypes
{
#line 1 "modelica_lexer.g"
#line 20 "modelica_lexer.hpp"
private:
	void initLiterals();
public:
	bool getCaseSensitiveLiterals() const
	{
		return true;
	}
public:
	modelica_lexer(ANTLR_USE_NAMESPACE(std)istream& in);
	modelica_lexer(ANTLR_USE_NAMESPACE(antlr)InputBuffer& ib);
	modelica_lexer(const ANTLR_USE_NAMESPACE(antlr)LexerSharedInputState& state);
	ANTLR_USE_NAMESPACE(antlr)RefToken nextToken();
	public: void mLPAR(bool _createToken);
	public: void mRPAR(bool _createToken);
	public: void mLBRACK(bool _createToken);
	public: void mRBRACK(bool _createToken);
	public: void mLBRACE(bool _createToken);
	public: void mRBRACE(bool _createToken);
	public: void mEQUALS(bool _createToken);
	public: void mASSIGN(bool _createToken);
	public: void mPLUS(bool _createToken);
	public: void mMINUS(bool _createToken);
	public: void mSTAR(bool _createToken);
	public: void mSLASH(bool _createToken);
	public: void mCOMMA(bool _createToken);
	public: void mLESS(bool _createToken);
	public: void mLESSEQ(bool _createToken);
	public: void mGREATER(bool _createToken);
	public: void mGREATEREQ(bool _createToken);
	public: void mEQEQ(bool _createToken);
	public: void mLESSGT(bool _createToken);
	public: void mCOLON(bool _createToken);
	public: void mSEMICOLON(bool _createToken);
	public: void mPOWER(bool _createToken);
	public: void mYIELDS(bool _createToken);
	public: void mAMPERSAND(bool _createToken);
	public: void mPIPEBAR(bool _createToken);
	public: void mCOLONCOLON(bool _createToken);
	public: void mDASHES(bool _createToken);
	public: void mWS(bool _createToken);
	public: void mML_COMMENT(bool _createToken);
	protected: void mML_COMMENT_CHAR(bool _createToken);
	public: void mSL_COMMENT(bool _createToken);
	public: void mIDENT(bool _createToken);
	protected: void mNONDIGIT(bool _createToken);
	protected: void mDIGIT(bool _createToken);
	protected: void mQIDENT(bool _createToken);
	protected: void mQCHAR(bool _createToken);
	protected: void mSESCAPE(bool _createToken);
	protected: void mEXPONENT(bool _createToken);
	public: void mUNSIGNED_INTEGER(bool _createToken);
	public: void mSTRING(bool _createToken);
	protected: void mSCHAR(bool _createToken);
	protected: void mESC(bool _createToken);
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

#endif /*INC_modelica_lexer_hpp_*/

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef INC_FlatModelicaLexer_hpp_
#define INC_FlatModelicaLexer_hpp_

#include <antlr/config.hpp>
/* $ANTLR 2.7.3: "flat_modelica_lexer.g" -> "FlatModelicaLexer.hpp"$ */
#include <antlr/CommonToken.hpp>
#include <antlr/InputBuffer.hpp>
#include <antlr/BitSet.hpp>
#include "FlatModelicaTokenTypes.hpp"
#include <antlr/CharScanner.hpp>
#line 1 "flat_modelica_lexer.g"

    #ifdef WIN32
	#pragma warning( disable : 4267)  // Disable warning messages C4267
    #endif
	//disable: 'initializing' : conversion from 'size_t' to 'int', possible loss of data

#line 19 "FlatModelicaLexer.hpp"
class CUSTOM_API FlatModelicaLexer : public ANTLR_USE_NAMESPACE(antlr)CharScanner, public FlatModelicaTokenTypes
{
#line 1 "flat_modelica_lexer.g"
#line 23 "FlatModelicaLexer.hpp"
private:
	void initLiterals();
public:
	bool getCaseSensitiveLiterals() const
	{
		return true;
	}
public:
	FlatModelicaLexer(ANTLR_USE_NAMESPACE(std)istream& in);
	FlatModelicaLexer(ANTLR_USE_NAMESPACE(antlr)InputBuffer& ib);
	FlatModelicaLexer(const ANTLR_USE_NAMESPACE(antlr)LexerSharedInputState& state);
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
	public: void mDOT(bool _createToken);
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
	public: void mWS(bool _createToken);
	public: void mML_COMMENT(bool _createToken);
	protected: void mML_COMMENT_CHAR(bool _createToken);
	public: void mSL_COMMENT(bool _createToken);
	public: void mIDENT(bool _createToken);
	protected: void mNONDIGIT(bool _createToken);
	protected: void mDIGIT(bool _createToken);
	protected: void mEXPONENT(bool _createToken);
	public: void mUNSIGNED_INTEGER(bool _createToken);
	public: void mSTRING(bool _createToken);
	protected: void mSCHAR(bool _createToken);
	protected: void mSESCAPE(bool _createToken);
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
};

#endif /*INC_FlatModelicaLexer_hpp_*/

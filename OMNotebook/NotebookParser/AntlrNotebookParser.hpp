#ifndef INC_AntlrNotebookParser_hpp_
#define INC_AntlrNotebookParser_hpp_




#include <antlr/config.hpp>
/* $ANTLR 2.7.4: "parser.g" -> "AntlrNotebookParser.hpp"$ */
#include <antlr/TokenStream.hpp>
#include <antlr/TokenBuffer.hpp>
#include "AntlrNotebookParserTokenTypes.hpp"
#include <antlr/LLkParser.hpp>




class CUSTOM_API AntlrNotebookParser : public ANTLR_USE_NAMESPACE(antlr)LLkParser, public AntlrNotebookParserTokenTypes
{
public:
	void initializeASTFactory( ANTLR_USE_NAMESPACE(antlr)ASTFactory& factory );
protected:
	AntlrNotebookParser(ANTLR_USE_NAMESPACE(antlr)TokenBuffer& tokenBuf, int k);
public:
	AntlrNotebookParser(ANTLR_USE_NAMESPACE(antlr)TokenBuffer& tokenBuf);
protected:
	AntlrNotebookParser(ANTLR_USE_NAMESPACE(antlr)TokenStream& lexer, int k);
public:
	AntlrNotebookParser(ANTLR_USE_NAMESPACE(antlr)TokenStream& lexer);
	AntlrNotebookParser(const ANTLR_USE_NAMESPACE(antlr)ParserSharedInputState& state);
	int getNumTokens() const
	{
		return AntlrNotebookParser::NUM_TOKENS;
	}
	const char* getTokenName( int type ) const
	{
		if( type > getNumTokens() ) return 0;
		return AntlrNotebookParser::tokenNames[type];
	}
	const char* const* getTokenNames() const
	{
		return AntlrNotebookParser::tokenNames;
	}
	public: void document();
	public: void expr();
	public: void exprheader();
	public: void value();
	public: void attribute();
	public: void rule();
	public: void listbody();
public:
	ANTLR_USE_NAMESPACE(antlr)RefAST getAST()
	{
		return returnAST;
	}
	
protected:
	ANTLR_USE_NAMESPACE(antlr)RefAST returnAST;
private:
	static const char* tokenNames[];
#ifndef NO_STATIC_CONSTS
	static const int NUM_TOKENS = 109;
#else
	enum {
		NUM_TOKENS = 109
	};
#endif
	
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
};

#endif /*INC_AntlrNotebookParser_hpp_*/

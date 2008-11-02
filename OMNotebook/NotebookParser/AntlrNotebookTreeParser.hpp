#ifndef INC_AntlrNotebookTreeParser_hpp_
#define INC_AntlrNotebookTreeParser_hpp_

#include <antlr/config.hpp>
#include "AntlrNotebookTreeParserTokenTypes.hpp"
/* $ANTLR 2.7.7 (2006-11-01): "walker.g" -> "AntlrNotebookTreeParser.hpp"$ */
#include <antlr/TreeParser.hpp>


//STD Headers
#include <iostream>
//#include <string>
#include <sstream>
#include <cstdlib>
#include <vector>
#include <map>
#include <algorithm>

#include <QtCore/QString>

//IAEX Headers
#include "cell.h"
#include "rule.h"
#include "factory.h"
#include "stripstring.h"
#include "xmlnodename.h"

using namespace std;
using namespace IAEX;

typedef pair<string,string> rule_t;

typedef vector<rule_t> rules_t;

//typedef stringstream content_t;
//typedef pair<content_t, rules_t>  result_t;

///pair<stringstream,vector<pair<string,string> > > result_t

class result_t
{
public:
   result_t(ostringstream &f):first(f){}
   result_t(ostringstream &f, vector<rule_t> &s)
   :first(f), second(s){}

   ostringstream& first;
   vector<rule_t> second;
};


class CUSTOM_API AntlrNotebookTreeParser : public ANTLR_USE_NAMESPACE(antlr)TreeParser, public AntlrNotebookTreeParserTokenTypes
{

    //This is in NotebookTreeParser.hpp
    Factory *factory;
    Cell *workspace;
    ostringstream output;
    //This is not very nice.

    // AF
    bool imagePartOfText;
    bool convertingToONB;
    int readmode_;
public:
	AntlrNotebookTreeParser();
	static void initializeASTFactory( ANTLR_USE_NAMESPACE(antlr)ASTFactory& factory );
	int getNumTokens() const
	{
		return AntlrNotebookTreeParser::NUM_TOKENS;
	}
	const char* getTokenName( int type ) const
	{
		if( type > getNumTokens() ) return 0;
		return AntlrNotebookTreeParser::tokenNames[type];
	}
	const char* const* getTokenNames() const
	{
		return AntlrNotebookTreeParser::tokenNames;
	}
	public: void document(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
		Cell *ws, Factory *f, int readmode
	);
	public: void expr(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
		result_t &result
	);
	public: void exprheader(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
		result_t &result
	);
	public: string  value(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: string  attribute(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void rule(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
		rules_t &rules
	);
	public: void listelement(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
		result_t &list
	);
public:
	ANTLR_USE_NAMESPACE(antlr)RefAST getAST()
	{
		return returnAST;
	}

protected:
	ANTLR_USE_NAMESPACE(antlr)RefAST returnAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST _retTree;
private:
	static const char* tokenNames[];
#ifndef NO_STATIC_CONSTS
	static const int NUM_TOKENS = 179;
#else
	enum {
		NUM_TOKENS = 179
	};
#endif

	static const unsigned long _tokenSet_0_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_0;
};

#endif /*INC_AntlrNotebookTreeParser_hpp_*/

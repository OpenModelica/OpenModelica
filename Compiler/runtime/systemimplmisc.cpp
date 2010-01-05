
/* Miscellaneous C++ file for systemimpl. */


#include <string>

using namespace std;

void FindAndReplace( std::string& tInput, std::string tFind, std::string tReplace )
{
	size_t uPos = 0; size_t uFindLen = tFind.length(); size_t uReplaceLen = tReplace.length();

	if( uFindLen == 0 )
	{
	    return;
	}

	for( ;(uPos = tInput.find( tFind, uPos )) != std::string::npos; )
	{
	    tInput.replace( uPos, uFindLen, tReplace );
	    uPos += uReplaceLen;
	}

}


extern "C" {

#include <string.h>

	char* _replace(const char* source_str, const char* search_str, const char* replace_str)
	{
		string str(source_str);
		FindAndReplace(str,string(search_str),string(replace_str));

		char* res = strdup(str.c_str());
		return res;
	}

}



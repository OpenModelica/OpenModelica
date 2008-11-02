
#include "token_names.hpp"
#include <stdlib.h>

void token_names::read_token_names(std::istream& is)
{
    m_names.clear();
    std::string str;
    int lineno=0;

    while (!is.eof())
    {
	std::getline(is, str);
	lineno++;
	try
	{
	    //      cout << getId(str) << " = " << getName(str) << endl;
	    int id = extract_id(str);
	    m_names[id] = extract_name(str);
	}
	catch(int a)
	{
	    // ignore the line, = was not found
	    //std::cerr << "ignoring line: " << lineno << std::endl;
	}
    }

}

int token_names::extract_id(const std::string& str) const
{
    std::string::size_type pos;
    pos = str.rfind('=');
    if (pos != std::string::npos)
    {
	return atoi(str.substr(pos+1).c_str());
    }
    else
    {
	throw -1;
    }
}

std::string token_names::extract_name(const std::string& str) const
{
    std::string::size_type pos1, pos2;
    pos1 = str.find('=');
    pos2 = str.rfind('=');
    if (pos1 == std::string::npos)
    {
	throw -1;
    }
    else
    {
	return str.substr(0,pos1);
    }
}

std::string token_names::extract_text(const std::string& str) const
{
    std::string::size_type pos1, pos2;
    pos1 = str.find('=');
    pos2 = str.rfind('=');
    if (pos1 == std::string::npos)
    {
	throw -1;
    }
    else
    {
	if (pos1 == pos2)
	{
	    return str.substr(0,pos1);
	}
	else
	{
	    return str.substr(pos1+2,pos2-pos1-3); // 2 and 3 because of ""
	}
    }
}

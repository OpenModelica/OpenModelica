#ifndef TOKEN_NAMES_H_
#define TOKEN_NAMES_H_

#include <string>
#include <map>
#include <iostream>

class token_names  {

public:
    typedef std::map<int, std::string> id_name_map;
    typedef id_name_map::iterator iterator;

public:
    token_names() { }

    token_names(std::istream& is)
    {
	read_token_names(is);
    }

    std::string& name(int i)
    {
	return m_names[i];
    }

    iterator begin()
    {
	return m_names.begin();
    }

    iterator end()
    {
	return m_names.end();
    }

    void add_name(int i, std::string const& s)
    {
	m_names[i] = s;
    }

    void read_token_names(std::istream& is);

private:
    int extract_id(const std::string& str) const;
    std::string extract_name(std::string const& str) const;
    std::string extract_text(std::string const& str) const;

private:
    id_name_map m_names;

};



#endif

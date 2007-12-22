/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science, 
 * SE-58183 Linköping, Sweden. 
 * 
 * All rights reserved.
 * 
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC 
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF 
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC 
 * PUBLIC LICENSE. 
 * 
 * The OpenModelica software and the Open Source Modelica 
 * Consortium (OSMC) Public License (OSMC-PL) are obtained 
 * from Linköpings University, either from the above address, 
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 * 
 * This program is distributed  WITHOUT ANY WARRANTY; without 
 * even the implied warranty of  MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH 
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS 
 * OF OSMC-PL. 
 * 
 * See the full OSMC Public License conditions for more details.
 * 
 */

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

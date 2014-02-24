#pragma once
#ifndef id8073C0EB_D490_45E7_9F4AE20BF9C28736
#define id8073C0EB_D490_45E7_9F4AE20BF9C28736

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


/*
 Mahder.Gebremedhin@liu.se  2014-02-10
*/


#include <set>
#include <algorithm>
#include <sstream>


namespace openmodelica {
namespace parmodelica {

namespace utility {

#define newl "\n"

extern std::ostringstream log_stream;
std::ostream& test_log(const char* pref);
std::ostream& test_log();



template<typename InputIterator1, typename InputIterator2>
bool 
has_intersection(InputIterator1 first1, InputIterator1 last1,
    	     InputIterator2 first2, InputIterator2 last2)
{      
    for(; first1 != last1; ++first1) {
        std::set<std::string>::iterator loc = std::find(first2, last2, (*first1));
        if(loc != last2) {
            return true;
        }
    }
    
    return false;
}


template<typename SetType> 
bool set_find_anyof(const SetType& InSet1, const SetType& InSet2) {
    
    for(typename SetType::const_iterator iter = InSet1.begin(); iter != InSet1.end(); ++iter) {
        typename SetType::const_iterator loc = std::find(InSet2.begin(), InSet2.end(), (*iter));
        if(loc != InSet2.end()) {
            return true;
        }
    }
    
    return false;
    
}

} // utility
} // parmodelica
} // openmodelica



#endif // header
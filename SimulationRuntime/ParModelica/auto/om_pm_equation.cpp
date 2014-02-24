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




#include <iterator>
#include <sstream>

#include "om_pm_equation.hpp"
#include "pm_utility.hpp"


namespace openmodelica {
namespace parmodelica {


Equation::Equation() :
    TaskNode(),
    index(-1)
{
}

bool Equation::depends_on(const Equation& other) const {

    bool found_dep = false;
    
    // True dependency
    found_dep = utility::has_intersection(this->rhs.begin(),this->rhs.end(),
                            other.lhs.begin(), other.lhs.end());
    // Anti-dependency                        
    if(!found_dep)
        found_dep = utility::has_intersection(this->lhs.begin(),this->lhs.end(),
                            other.rhs.begin(), other.rhs.end());
    // output-dependency                        
    if(!found_dep)
        found_dep = utility::has_intersection(this->lhs.begin(),this->lhs.end(),
                            other.lhs.begin(), other.lhs.end()); 
                            
    return found_dep;
}


} // openmodelica
} // parmodelica




// Leave the stream operators in global namespace.
using namespace openmodelica::parmodelica;

std::ostream& operator<<(std::ostream& os, const Equation& eq) {
    os << eq.index << " : ";
    std::copy(eq.lhs.begin(),eq.lhs.end(), std::ostream_iterator<Ident>(os,", "));
    os << " : ";
    std::copy(eq.rhs.begin(),eq.rhs.end(), std::ostream_iterator<Ident>(os,", "));
    return os;
}


std::istream& operator>>(std::istream& is, Equation& eq) {
    // Unfortunatly back_inserter initalizes by copy.
    // So we have to clear the conainers here. This should be rewritten.
    // Remove istream_iterator altogether.
    eq.lhs.clear(); eq.rhs.clear();
    std::string line, var;

    if(!std::getline(is, line))
        return is;

    std::istringstream iss(line);
    iss >> eq.index;

    iss >> var;
    while(var != ":") {
        eq.lhs.insert(var);
        iss >> var;
    }	
    while(iss >> var) {
        eq.rhs.insert(var);
    }

    return is;
}


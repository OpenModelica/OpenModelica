#pragma once
#ifndef idA890A2D6_30B0_44AD_B07DF074DD9AC126
#define idA890A2D6_30B0_44AD_B07DF074DD9AC126


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




#include <iostream>
#include <set>
#include <vector>
#include <string>



namespace openmodelica {
namespace parmodelica {

struct TaskNode {
    TaskNode() : level(0) ,cost(0), comm_cost(0) {};

    long node_id;
    int level;
    double cost;
    double comm_cost;
    
    // bool depends_on(const TaskNode& other);
};

typedef std::string Ident;

struct Equation : public TaskNode {
    Equation();

    long index;
    std::set<Ident> lhs;
    std::set<Ident> rhs;
    std::string type;
    
    bool depends_on(const Equation& other) const;
    
};






} // openmodelica
} // parmodelica



#endif // header
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



#include <cstring>

#include <pugixml.hpp>


namespace openmodelica {
namespace parmodelica {

template<typename TaskTypeT>
void load_node(TaskTypeT& current_node, pugi::xml_node& xml_equ) {
    
    pugi::xml_node eq_type = xml_equ.first_child();
    current_node.type = eq_type.name();
    
    if( std::strcmp(eq_type.name(),"assign") == 0) { 
        
        pugi::xml_node current = eq_type.first_child();
        
        while(std::strcmp(current.name(),"defines") == 0) {
            current_node.lhs.insert(current.attribute("name").value());
            current = current.next_sibling();
        }
        
        
        while(std::strcmp(current.name(),"depends") == 0) {
            current_node.rhs.insert(current.attribute("name").value());
            current = current.next_sibling();
        }
        
        current_node.cost = 1;
    }
    else if( std::strcmp(eq_type.name(),"statement") == 0) { 
        
        pugi::xml_node current = eq_type.first_child();
        
        while(std::strcmp(current.name(),"defines") == 0) {
            current_node.lhs.insert(current.attribute("name").value());
            current = current.next_sibling();
        }
        
        
        while(std::strcmp(current.name(),"depends") == 0) {
            current_node.rhs.insert(current.attribute("name").value());
            current = current.next_sibling();
        }
        
        current_node.cost = 1;
    }
    else if( std::strcmp(eq_type.name(),"when") == 0) { 
        
        pugi::xml_node current = eq_type.first_child();
        current_node.rhs.insert(current.child_value());
        current = current.next_sibling();
        
        while(std::strcmp(current.name(),"defines") == 0) {
            current_node.lhs.insert(current.attribute("name").value());
            current = current.next_sibling();
        }
        
        
        while(std::strcmp(current.name(),"depends") == 0) {
            current_node.rhs.insert(current.attribute("name").value());
            current = current.next_sibling();
        }
        
        current_node.cost = 2;
    }
    else if( std::strcmp(eq_type.name(),"nonlinear") == 0) { 
        
        pugi::xml_node current = eq_type.first_child();
        
        while(std::strcmp(current.name(),"defines") == 0) {
            current_node.lhs.insert(current.attribute("name").value());
            current = current.next_sibling();
        }
        
        
        long nls_size = 0;
        while(std::strcmp(current.name(),"eq") == 0) {
            // current_node.eqs.push_back(current.attribute("index").as_int());
            current = current.next_sibling();
            ++nls_size;
        }
        
        // int nls_size = current_node.eqs.size();
        // EquationSystem::iterator iter = eq_system.end();
        // std::advance(iter, -nls_size);
        // for(int count = 0; count < nls_size; ++count) {
            // current_node.lhs.insert(iter->lhs.begin(), iter->lhs.end());
            // current_node.rhs.insert(iter->rhs.begin(), iter->rhs.end());
            // iter = eq_system.erase(iter);
        // }
        
        current_node.cost = nls_size;
        // This has been added already for each equation in prev steps!
        // total_cost += current_node.cost; 
        // Just add the extra cost here.
        
        for(int count = 0; count < nls_size; ++count) {
            xml_equ = xml_equ.next_sibling();
            typename TaskSystem<TaskTypeT>::TaskType nls_eq_node;
            load_node(nls_eq_node, xml_equ);
            current_node.lhs.insert(nls_eq_node.lhs.begin(), nls_eq_node.lhs.end());
            current_node.rhs.insert(nls_eq_node.rhs.begin(), nls_eq_node.rhs.end());
        }
        utility::test_log("Warning") << current_node.index << ": Non linear equations not fully handled yet: " << nls_size << newl;
        
        
    }
    
    else if( std::strcmp(eq_type.name(),"linear") == 0) { 
        
        pugi::xml_node current = eq_type.first_child();
        
        int ls_size = 0;
        while(std::strcmp(current.name(),"defines") == 0) {
            current_node.lhs.insert(current.attribute("name").value());
            current = current.next_sibling();
            ++ls_size;
        }
        
        while(std::strcmp(current.name(),"depends") == 0) {
            current_node.rhs.insert(current.attribute("name").value());
            current = current.next_sibling();
        }
        
        current_node.cost = ls_size;
        utility::test_log("Warning") << current_node.index << ": Linear equations not fully handled yet: " << ls_size << newl;
    }
    
    else {
        current_node.cost = 1;
        utility::test_log("Error") << current_node.index << ": Unknown Equation type." << eq_type.name() << newl; 
    }
    
    
}


template<typename TaskTypeT>
void TaskSystem<TaskTypeT>::load_from_xml(const std::string& file_name, const std::string& eq_to_read) {


    pugi::xml_document doc;
    pugi::xml_parse_result result = doc.load_file(file_name.c_str());
    pugi::xml_node xml_equs = doc.child("simcodedump").child(eq_to_read.c_str());
    
    long node_count = 0;
    
    
    for (pugi::xml_node xml_equ = xml_equs.first_child(); xml_equ; )
    {

        pugi::xml_attribute index = xml_equ.first_attribute();
        TaskType& current_node = this->add_node(index.as_int());
        
        load_node(current_node, xml_equ);
        ++node_count;

        total_cost += current_node.cost; 
        xml_equ = xml_equ.next_sibling();
    }
    
    
    utility::test_log("Info") << "Number of tasks      = " << node_count << newl;
    utility::test_log("Info") << "Total Cost of system = " << total_cost << newl;
    
    
} 



} // openmodelica
} // parmodelica



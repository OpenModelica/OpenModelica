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



#include "om_pm_model.hpp"

#include <cstring>
// #include <pugixml.hpp>

#include "json.hpp"



namespace openmodelica {
namespace parmodelica {

Equation::Equation() :
    TaskNode()
{
    index = -1;
    function_system = NULL;
    data = NULL;
    threadData = NULL;
}

bool Equation::depends_on(const TaskNode& other_b) const {

    const Equation& other = static_cast<const Equation&>(other_b);

    bool found_dep = false;

    // True dependency
    found_dep = utility::has_intersection(this->rhs.begin(),this->rhs.end(),
                            other.lhs.begin(), other.lhs.end());
    // Anti-dependency
    if(!found_dep) {
        found_dep = utility::has_intersection(this->lhs.begin(),this->lhs.end(),
                            other.rhs.begin(), other.rhs.end());
        if(found_dep)
            std::cout << "found anti-dep" << this->index << " and " << other.index << std::endl;
    }
    // output-dependency
    if(!found_dep) {
        found_dep = utility::has_intersection(this->lhs.begin(),this->lhs.end(),
                            other.lhs.begin(), other.lhs.end());
        if(found_dep)
            std::cout << "found output-dep" << this->index << " and " << other.index << std::endl;
    }

    return found_dep;
}


void Equation::execute() {
    function_system[task_id](data, threadData);
}


OMModel::OMModel(const std::string& in_name) :
    name(in_name)
    , INI_system(name)
    , INI_scheduler(INI_system)
    , DAE_system(name)
    , DAE_scheduler(DAE_system)
    , ODE_system(name)
    , ODE_scheduler(ODE_system)
    , ALG_system(name)
    , ALG_scheduler(ALG_system)
{
    intialized = false;
}



void OMModel::load_ODE_system() {

    if(intialized)
        return;

    load_system_timer.start_timer();
    load_from_json(ODE_system, "ode-equations", ode_system_funcs);
    load_system_timer.stop_timer();
    // ODE_system.construct_graph();
    // ODE_scheduler.set_up_executor(ode_system_funcs, data);
    // ODE_scheduler.schedule(4);


    intialized = true;

}


// void load_equation(Equation& current_node, pugi::xml_node& xml_equ) {

    // pugi::xml_node eq_type = xml_equ.first_child();
    // current_node.type = eq_type.name();

    // if( std::strcmp(eq_type.name(),"assign") == 0) {

        // pugi::xml_node current = eq_type.first_child();

        // while(std::strcmp(current.name(),"defines") == 0) {
            // current_node.lhs.insert(current.attribute("name").value());
            // current = current.next_sibling();
        // }


        // while(std::strcmp(current.name(),"depends") == 0) {
            // current_node.rhs.insert(current.attribute("name").value());
            // current = current.next_sibling();
        // }

        // current_node.cost = 1;
    // }
    // else if( std::strcmp(eq_type.name(),"statement") == 0) {

        // pugi::xml_node current = eq_type.first_child();

        // while(std::strcmp(current.name(),"defines") == 0) {
            // current_node.lhs.insert(current.attribute("name").value());
            // current = current.next_sibling();
        // }


        // while(std::strcmp(current.name(),"depends") == 0) {
            // current_node.rhs.insert(current.attribute("name").value());
            // current = current.next_sibling();
        // }

        // current_node.cost = 1;
    // }
    // else if( std::strcmp(eq_type.name(),"when") == 0) {

        // pugi::xml_node current = eq_type.first_child();
        // current_node.rhs.insert(current.child_value());
        // current = current.next_sibling();

        // while(std::strcmp(current.name(),"defines") == 0) {
            // current_node.lhs.insert(current.attribute("name").value());
            // current = current.next_sibling();
        // }


        // while(std::strcmp(current.name(),"depends") == 0) {
            // current_node.rhs.insert(current.attribute("name").value());
            // current = current.next_sibling();
        // }

        // current_node.cost = 2;
    // }

    // else if( std::strcmp(eq_type.name(),"linear") == 0) {

        // pugi::xml_node current = eq_type.first_child();

        // int ls_size = 0;
        // while(std::strcmp(current.name(),"defines") == 0) {
            // current_node.lhs.insert(current.attribute("name").value());
            // current = current.next_sibling();
            // ++ls_size;
        // }

        // while(std::strcmp(current.name(),"depends") == 0) {
            // current_node.rhs.insert(current.attribute("name").value());
            // current = current.next_sibling();
        // }

        // current_node.cost = ls_size;
        // utility::warning() << current_node.index << ": Linear equations not fully handled yet: " << ls_size << newl;
    // }

    // else if( std::strcmp(eq_type.name(),"nonlinear") == 0) {

        // pugi::xml_node current = eq_type.first_child();

        // int nls_size = 0;
        // while(std::strcmp(current.name(),"defines") == 0) {
            // current_node.lhs.insert(current.attribute("name").value());
            // current = current.next_sibling();
            // ++nls_size;
        // }

        // while(std::strcmp(current.name(),"depends") == 0) {
            // current_node.rhs.insert(current.attribute("name").value());
            // current = current.next_sibling();
        // }

        // current_node.cost = nls_size;
        // utility::warning() << current_node.index << ": Non linear equations not fully handled yet: " << nls_size << newl;
    // }

    // else if( std::strcmp(eq_type.name(),"mixed") == 0) {

        // int mix_size = eq_type.attribute("size").as_int();

        // pugi::xml_node current = eq_type.first_child();

        // while(std::strcmp(current.name(),"defines") == 0) {
            // current_node.lhs.insert(current.attribute("name").value());
            // current = current.next_sibling();
        // }

        // current_node.cost = mix_size;

        // for(int count = 0; count < mix_size; ++count) {
            // xml_equ = xml_equ.next_sibling();
            // Equation mix_eq_node;
            // load_node(mix_eq_node, xml_equ);
            // current_node.lhs.insert(mix_eq_node.lhs.begin(), mix_eq_node.lhs.end());
            // current_node.rhs.insert(mix_eq_node.rhs.begin(), mix_eq_node.rhs.end());
        // }

        // utility::warning() << current_node.index << ": Mixed equations not fully handled yet: " << mix_size << newl;
    // }

    // else {
        // current_node.cost = 1;
        // utility::error() << current_node.index << ": Unknown Equation type." << eq_type.name() << newl;
    // }


// }

// void OMModel::load_from_xml(TaskSystemT& task_system, const std::string& eq_to_read, FunctionType* function_system) {

    // std::string xml_file = model_name + "_tasks.xml";
    // utility::log("") << "Loading " << xml_file << std::endl;

    // pugi::xml_document doc;
    // if(!doc.load_file(xml_file.c_str())) {
        // std::cerr << "Error loading XML file '" << xml_file << "'." << std::endl;
        // exit(1);
    // }


    // pugi::xml_node xml_equs = doc.child("tasksystemdump").child(eq_to_read.c_str());

    // long node_count = 0;


    // for (pugi::xml_node xml_equ = xml_equs.first_child(); xml_equ; )
    // {

        // Equation current_node;
        // pugi::xml_attribute index = xml_equ.first_attribute();
        // current_node.index = index.as_int();

        // // Copy the pointers to the needed info from the Model
        // // to each equation node.
        // current_node.data = this->data;
        // current_node.threadData = this->threadData;
        // current_node.function_system = function_system;


        // load_equation(current_node, xml_equ);
        // ++node_count;

        // task_system.add_node(current_node);

        // xml_equ = xml_equ.next_sibling();
    // }


    // utility::log() << "Number of tasks      = " << node_count << newl;


// }


inline void check_tag(int index, const std::string& tag) {
    if (tag == "dummy"
        or tag == "assign"
        or tag == "residual"
        or tag == "tornsystem"
        or tag == "system"
        or tag == "algorithm")
        return;
    else {
      std::cerr << index << " : with unknown tag : " << tag << std::endl;
      exit(1);
    }
}

inline void check_container_dispaly(int index, const std::string& disp) {
    if (disp == "linear"
        or disp == "non-linear")
        return;
    else {
      std::cerr << index << " : container with unknown disp : " << disp << std::endl;
      exit(1);
    }
}

void load_simple_assign(Equation& current_node, const nlohmann::json& json_eq) {

#ifndef NDEBUG
    if (json_eq["defines"].size() != 1) {
        utility::eq_index_error(current_node.index, "Assign with more than one define!");
    }
#endif

    current_node.lhs.insert(json_eq["defines"].front().get<std::string>());

    for(auto use : json_eq["uses"]) {
        current_node.rhs.insert(use.get<std::string>());
    }
}



void load_simple_assign_check_local_define(Equation& current_node, const nlohmann::json& int_eq) {

#ifndef NDEBUG
    if (int_eq["defines"].size() != 1) {
        utility::eq_index_error(current_node.index, "Assign with more than one define!");
    }
#endif

    current_node.lhs.insert(int_eq["defines"].front().get<std::string>());

    for(auto& use : int_eq["uses"]) {
        auto var_s = use.get<std::string>();
        utility::indexed_dlog(current_node.index, "Checking if " + var_s + " is defined localy");
        auto local_defined = current_node.lhs.find(var_s) != current_node.lhs.end();

        // Disable me and see if graphs look different.
        if (!local_defined) {
            current_node.rhs.insert(use.get<std::string>());
            utility::indexed_dlog(current_node.index, ": added uses: " + use.get<std::string>() + " : due to " + std::to_string(int_eq["eqIndex"].get<int>()));
        }
        else{
            utility::indexed_dlog(current_node.index, ": skiped uses: " + use.get<std::string>() + " : due to local define");
        }
    }


}

void load_simple_residual(Equation& current_node, const nlohmann::json& json_eq) {
    for(auto use : json_eq["uses"]) {
        current_node.rhs.insert(use.get<std::string>());
    }
}


void load_linear_system(Equation& current_node, const nlohmann::json& json_eq) {

    for(auto& def : json_eq["defines"]) {
        current_node.lhs.insert(def.get<std::string>());
        utility::indexed_dlog(current_node.index, ": added own defines: " + def.get<std::string>());
    }

    for(auto& int_eq : json_eq["internal-equations"]) {

        int i_index = int_eq["eqIndex"];
        const std::string& i_tag = int_eq["tag"];

        if(i_tag == "assign") {
            load_simple_assign_check_local_define(current_node, int_eq);
        }

        else if(i_tag == "torn") {
            load_simple_assign_check_local_define(current_node, int_eq);
        }

        else if(i_tag == "residual") {
            load_simple_residual(current_node, int_eq);
        }

        else {
            utility::eq_index_fatal(i_index, "Internal Equation type not yet handled: " + i_tag);
        }

    }

    utility::indexed_dlog(current_node.index, "Total number of defines: " + std::to_string(current_node.lhs.size()));
    utility::indexed_dlog(current_node.index, "Total number of uses: " + std::to_string(current_node.rhs.size()));

}


void load_system_of_equations(Equation& current_node, const nlohmann::json& json_eq) {
    const std::string& display = json_eq["display"];
    const std::string& tag = json_eq["tag"];

    if(display == "linear") {
        load_linear_system(current_node, json_eq);
    }
    else if(display == "non-linear") {
        load_linear_system(current_node, json_eq);
    }
    else {
        utility::eq_index_fatal(current_node.index, "System (" + tag + ") Equation display not yet handled: " + display);
    }
}

void load_equation(Equation& current_node, const nlohmann::json& json_eq) {
    const std::string& tag = json_eq["tag"];

    if(tag == "assign") {
        load_simple_assign(current_node, json_eq);
        return;
    }

    else if(tag == "residual") {
        load_simple_residual(current_node, json_eq);
        return;
    }

    else if(tag == "tornsystem" || tag == "system") {
        load_system_of_equations(current_node, json_eq);
        return;
    }

    else {
        utility::eq_index_fatal(current_node.index, "Equation type not yet handled: " + tag);
    }
}


void OMModel::load_from_json(TaskSystemT& task_system, const std::string& eq_to_read, FunctionType* function_system) {
    std::string json_file = this->name + "_ode.json";
    // utility::log("") << "Loading " << json_file << std::endl;

    std::ifstream f_s(json_file);
    nlohmann::json jmodel_info;

    jmodel_info << f_s;

    long node_count = 0;
    for(auto& eq : jmodel_info[eq_to_read]) {

        int index = eq["eqIndex"];
        // skip the 'dummy' node in OpenModelica generated JSON file.
        if (index == 0) {
            continue;
        }

        if(eq["section"] != "regular") {
            utility::eq_index_fatal(index, "Unkown section!" + eq["section"].get<std::string>());
        }


        Equation current_node;
        current_node.index = index;
        // Copy the pointers to the needed info from the Model
        // to each equation node.
        current_node.data = this->data;
        current_node.threadData = this->threadData;
        current_node.function_system = function_system;

        load_equation(current_node, eq);

        ++node_count;
        task_system.add_node(current_node);

    }

    std::cout << "Number of tasks      = " << node_count << newl;
}


} // openmodelica
} // parmodelica

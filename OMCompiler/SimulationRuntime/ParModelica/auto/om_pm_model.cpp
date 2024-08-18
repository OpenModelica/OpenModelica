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
 Mahder.Gebremedhin@liu.se  2020-10-12
*/

// We need this to get the flag/option values passed to a simulation executable.
#include "simulation/options.h"

#include "om_pm_model.hpp"

#include <cstring>
#include <fstream>
// #include <pugixml.hpp>

#include "json.hpp"

namespace openmodelica { namespace parmodelica {

Equation::Equation() : TaskNode() {
    index = -1;
    function_system = NULL;
    data = NULL;
    threadData = NULL;
}

bool Equation::depends_on(const TaskNode& other_b) const {

    const Equation& other = static_cast<const Equation&>(other_b);

    bool found_dep = false;

    // True dependency
    found_dep = utility::has_intersection(this->rhs.begin(), this->rhs.end(), other.lhs.begin(), other.lhs.end());
    // Anti-dependency
    // if (!found_dep) {
    //     found_dep = utility::has_intersection(this->lhs.begin(), this->lhs.end(), other.rhs.begin(), other.rhs.end());
    //     if (found_dep)
    //         std::cout << "found anti-dep" << this->index << " and " << other.index << std::endl;
    // }
    // // output-dependency
    // if (!found_dep) {
    //     found_dep = utility::has_intersection(this->lhs.begin(), this->lhs.end(), other.lhs.begin(), other.lhs.end());
    //     if (found_dep)
    //         std::cout << "found output-dep" << this->index << " and " << other.index << std::endl;
    // }

    return found_dep;
}

void Equation::execute() {
    function_system[task_id](data, threadData);
}

OMModel::OMModel(const std::string& in_name, size_t mnt)
    : name(in_name)
    , max_num_threads(mnt)
    , tbb_system(mnt)
    , INI_system(name, mnt)
    , INI_scheduler(INI_system, mnt)
    , DAE_system(name, mnt)
    , DAE_scheduler(DAE_system, mnt)
    , ODE_system(name, mnt)
    , ODE_scheduler(ODE_system, mnt)
    , ALG_system(name, mnt)
    , ALG_scheduler(ALG_system, mnt) {
    intialized = false;
}

void OMModel::load_ODE_system() {

    if (intialized)
        return;

    load_system_timer.start_timer();
    load_from_json(ODE_system, "ode-equations", ode_system_funcs);
    load_system_timer.stop_timer();
    // ODE_system.construct_graph();
    // ODE_scheduler.set_up_executor(ode_system_funcs, data);
    // ODE_scheduler.schedule(4);

    intialized = true;
}

inline void check_tag(int index, const std::string& tag) {
    if (tag == "dummy" || tag == "assign" || tag == "residual" || tag == "tornsystem" || tag == "system" ||
        tag == "algorithm")
        return;
    else {
        utility::eq_index_fatal(index, "with unknown tag : " + tag);
    }
}

inline void check_container_dispaly(int index, const std::string& disp) {
    if (disp == "linear" || disp == "non-linear")
        return;
    else {
        utility::eq_index_fatal(index, "container with unknown disp : " + disp);
    }
}

void load_simple_assign(Equation& current_node, const nlohmann::json& json_eq) {

    if (json_eq["defines"].size() != 1) {
        utility::eq_index_fatal(current_node.index, "Assign with more than one define!");
    }

    current_node.lhs.insert(json_eq["defines"].front().get<std::string>());

    for (auto use : json_eq["uses"]) {
        current_node.rhs.insert(use.get<std::string>());
    }
}

void load_algorithm(Equation& current_node, const nlohmann::json& json_eq) {

    for (auto def : json_eq["defines"]) {
        current_node.lhs.insert(def.get<std::string>());
    }

    for (auto use : json_eq["uses"]) {
        current_node.rhs.insert(use.get<std::string>());
    }
}

void load_simple_assign_check_local_define(Equation& current_node, const nlohmann::json& int_eq) {

    if (int_eq["defines"].size() != 1) {
        utility::eq_index_error(current_node.index, "Assign with more than one define!");
    }

    current_node.lhs.insert(int_eq["defines"].front().get<std::string>());

    for (auto& use : int_eq["uses"]) {
        auto var_s = use.get<std::string>();
        utility::indexed_dlog(current_node.index, "Checking if " + var_s + " is defined locally");
        auto local_defined = current_node.lhs.find(var_s) != current_node.lhs.end();

        // Disable me and see if graphs look different.
        if (!local_defined) {
            current_node.rhs.insert(use.get<std::string>());
            utility::indexed_dlog(current_node.index, ": added uses: " + use.get<std::string>() + " : due to " +
                                                          std::to_string(int_eq["eqIndex"].get<int>()));
        }
        else {
            utility::indexed_dlog(current_node.index,
                                  ": skiped uses: " + use.get<std::string>() + " : due to local define");
        }
    }
}

void load_simple_residual(Equation& current_node, const nlohmann::json& json_eq) {
    for (auto use : json_eq["uses"]) {
        current_node.rhs.insert(use.get<std::string>());
    }
}

void load_linear_system(Equation& current_node, const nlohmann::json& json_eq) {

    for (auto& def : json_eq["defines"]) {
        current_node.lhs.insert(def.get<std::string>());
        utility::indexed_dlog(current_node.index, ": added own defines: " + def.get<std::string>());
    }

    for (auto& int_eq : json_eq["internal-equations"]) {

        int                i_index = int_eq["eqIndex"];
        const std::string& i_tag = int_eq["tag"];

        if (i_tag == "assign") {
            load_simple_assign_check_local_define(current_node, int_eq);
        }

        else if (i_tag == "torn") {
            load_simple_assign_check_local_define(current_node, int_eq);
        }

        else if (i_tag == "residual") {
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

    if (display == "linear") {
        load_linear_system(current_node, json_eq);
    }
    else if (display == "non-linear") {
        load_linear_system(current_node, json_eq);
    }
    else {
        utility::eq_index_fatal(current_node.index,
                                "System (" + tag + ") Equation display not yet handled: " + display);
    }
}

void load_equation(Equation& current_node, const nlohmann::json& json_eq) {
    const std::string& tag = json_eq["tag"];

    if (tag == "assign") {
        load_simple_assign(current_node, json_eq);
        return;
    }

    else if (tag == "residual") {
        load_simple_residual(current_node, json_eq);
        return;
    }

    else if (tag == "algorithm") {
        load_algorithm(current_node, json_eq);
        return;
    }

    else if (tag == "tornsystem" || tag == "system") {
        load_system_of_equations(current_node, json_eq);
        return;
    }

    else {
        utility::eq_index_fatal(current_node.index, "Equation type not yet handled: " + tag);
    }
}

void OMModel::load_from_json(TaskSystemT& task_system, const std::string& eq_to_read, FunctionType* function_system) {
    std::string json_file = this->name + "_ode.json";

    if (omc_flag[FLAG_INPUT_PATH]) {
      json_file = std::string(omc_flagValue[FLAG_INPUT_PATH]) + "/" + json_file;
    }

    // utility::log("") << "Loading " << json_file << std::endl;

    std::ifstream  f_s(json_file);
    if (!f_s.is_open()) {
        utility::error("Fatal") << "Could not open dependency json file '" << json_file << "'. Please make sure the file is generated in the correct place and is readable." << std::endl;
    }


    nlohmann::json jmodel_info;

    jmodel_info << f_s;

    long node_count = 0;
    for (auto& eq : jmodel_info[eq_to_read]) {

        int index = eq["eqIndex"];
        // skip the 'dummy' node in OpenModelica generated JSON file.
        if (index == 0) {
            continue;
        }

        if (eq["section"] != "regular") {
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

    std::cout << "Number of tasks      = " << node_count << std::endl;
}

}} // namespace openmodelica::parmodelica

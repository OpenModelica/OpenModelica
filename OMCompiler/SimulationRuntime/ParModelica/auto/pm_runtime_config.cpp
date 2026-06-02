/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#include "pm_runtime_config.hpp"

// Gives access to the simulation-executable command-line flags.
#include "simulation/options.h"

#include <cstdlib>

namespace openmodelica { namespace parmodelica {

/*! Returns the value of a command-line value-flag, or NULL if it was not given. */
static const char* flag_value_or_null(int flag) {
    return omc_flag[flag] ? omc_flagValue[flag] : 0;
}

const ParmodConfig& parmod_config() {
    static ParmodConfig cfg;
    static bool         initialized = false;
    if (initialized)
        return cfg;

    /* scheduler: flag, default "flow". */
    const char* scheduler = flag_value_or_null(FLAG_PARMOD_SCHEDULER);
    cfg.scheduler = scheduler ? scheduler : "flow";

    /* clustering: flag, else PARMOD_CLUSTERING env var, else "default". */
    const char* clustering = flag_value_or_null(FLAG_PARMOD_CLUSTERING);
    if (!clustering)
        clustering = std::getenv("PARMOD_CLUSTERING");
    cfg.clustering = clustering ? clustering : "default";

    /* clusters per level: flag, else PARMOD_CLUSTERS_PER_LEVEL env var, else 0 (=auto). */
    const char* clusters_per_level = flag_value_or_null(FLAG_PARMOD_CLUSTERS_PER_LEVEL);
    if (!clusters_per_level)
        clusters_per_level = std::getenv("PARMOD_CLUSTERS_PER_LEVEL");
    cfg.clusters_per_level = clusters_per_level ? std::atoi(clusters_per_level) : 0;

    cfg.dump_taskgraph = flag_value_or_null(FLAG_PARMOD_DUMP_TASKGRAPH);
    cfg.import_clustering = flag_value_or_null(FLAG_PARMOD_IMPORT_CLUSTERING);

    initialized = true;
    return cfg;
}

}} // namespace openmodelica::parmodelica

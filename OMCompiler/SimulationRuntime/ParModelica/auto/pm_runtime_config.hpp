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

#pragma once
#ifndef id_PARMOD_RUNTIME_CONFIG_HPP
#define id_PARMOD_RUNTIME_CONFIG_HPP

#include <string>

/*! Central, run-time configuration for the ParModelica auto runtime.

    The values are taken from the simulation-executable command-line flags
    (parmodScheduler, parmodClustering, parmodClustersPerLevel,
    parmodDumpTaskGraph, parmodImportClustering), with the older environment
    variables (PARMOD_CLUSTERING, PARMOD_CLUSTERS_PER_LEVEL) kept as a fallback.

    This header intentionally does NOT include the C runtime's options header, so
    the templated clustering/scheduler headers can read the configuration without
    pulling in the whole simulation runtime. The flags are read in the matching
    .cpp (which does include it). */
namespace openmodelica { namespace parmodelica {

struct ParmodConfig {
    std::string scheduler;         /*!< "flow" (default) or "level". */
    std::string clustering;        /*!< "default", "fixed_width_min_height" or "none". */
    int         clusters_per_level; /*!< <= 0 means "use the clustering's own default". */
    const char* dump_taskgraph;    /*!< output json path, or NULL. */
    const char* import_clustering; /*!< input json path, or NULL. */
    const char* dump_stages;       /*!< output json file-name prefix for the per-optimization
                                        before/after snapshots, or NULL. */
};

/*! Returns the (lazily initialized, cached) ParModelica auto configuration. */
const ParmodConfig& parmod_config();

}} // namespace openmodelica::parmodelica

#endif // header

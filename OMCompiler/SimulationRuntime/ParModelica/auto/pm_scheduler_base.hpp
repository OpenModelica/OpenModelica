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
#ifndef id_PARMOD_SCHEDULER_BASE_HPP
#define id_PARMOD_SCHEDULER_BASE_HPP

/*! Common runtime interface for the ParModelica auto schedulers (the flow-graph
    ClusterDynamicScheduler and the level-based StepLevels/LevelScheduler), so the
    scheduler can be selected at run time (parmodScheduler flag) instead of via a
    compile-time #define. OMModel holds these through a pointer to this base. */
namespace openmodelica { namespace parmodelica {

struct TaskGraphScheduler {
    virtual ~TaskGraphScheduler() {}

    /*! Evaluate the task graph once (schedules lazily on the first call). */
    virtual void execute() = 0;

    /*! Statistics used by the run summary (om_pm_interface.cpp dump_times). */
    virtual int    get_total_evaluations() const = 0;
    virtual int    get_sequential_evaluations() const = 0;
    virtual int    get_parallel_evaluations() const = 0;
    virtual double get_execution_time() = 0;
    virtual double get_clustering_time() = 0;
};

}} // namespace openmodelica::parmodelica

#endif // header

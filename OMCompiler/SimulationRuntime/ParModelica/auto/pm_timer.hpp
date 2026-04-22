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
#ifndef id5F620984_BA45_4016_B0EEF41D74ABE934
#define id5F620984_BA45_4016_B0EEF41D74ABE934

/*
 Mahder.Gebremedhin@liu.se  2020-10-12
*/

#ifdef _WIN32 // OS

#include <windows.h>

namespace openmodelica { namespace parmodelica {

struct PMStopWatch {
    LARGE_INTEGER start;
    LARGE_INTEGER stop;
};

class PMTimer {

  private:
    PMStopWatch   timer;
    LARGE_INTEGER total_time;
    LARGE_INTEGER frequency;
    double        LI_to_milli_secs(LARGE_INTEGER& LI);

  public:
    PMTimer();
    void   start_timer();
    void   stop_timer();
    void   reset_timer();
    double get_elapsed_time();
};

}} // namespace openmodelica::parmodelica

#else // if not _WIN32

#define BOOST_CHRONO_HEADER_ONLY
#include <boost/chrono.hpp>

namespace openmodelica { namespace parmodelica {

class PMTimer {

  private:
    boost::chrono::system_clock::duration   total_time;
    boost::chrono::system_clock::time_point started_at;

  public:
    PMTimer();
    void   start_timer();
    void   stop_timer();
    void   reset_timer();
    double get_elapsed_time();
};

}} // namespace openmodelica::parmodelica

#endif // OS

#endif // header

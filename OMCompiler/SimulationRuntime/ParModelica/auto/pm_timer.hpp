#pragma once
#ifndef id5F620984_BA45_4016_B0EEF41D74ABE934
#define id5F620984_BA45_4016_B0EEF41D74ABE934

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

#ifdef _WIN32 // OS

#include <windows.h>

namespace openmodelica {
namespace parmodelica {

struct PMStopWatch {
    LARGE_INTEGER start;
    LARGE_INTEGER stop;
};

class PMTimer {

private:
    PMStopWatch timer;
    LARGE_INTEGER total_time;
    LARGE_INTEGER frequency;
    double LI_to_milli_secs(LARGE_INTEGER &LI) ;
public:
    PMTimer();
    void start_timer();
    void stop_timer();
    void reset_timer();
    double get_elapsed_time();
};


} // parmodelica
} // openmodelica

#else // if not _WIN32


#define BOOST_CHRONO_HEADER_ONLY
#include <boost/chrono.hpp>


namespace openmodelica {
namespace parmodelica {

class PMTimer {

private:
    boost::chrono::system_clock::duration total_time;
    boost::chrono::system_clock::time_point started_at;
public:
    PMTimer();
    void start_timer();
    void stop_timer();
    void reset_timer();
    double get_elapsed_time();
};

} // parmodelica
} // openmodelica

#endif // OS



#endif // header

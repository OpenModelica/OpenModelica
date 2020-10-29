
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


#include "pm_timer.hpp"


namespace openmodelica {
namespace parmodelica {


double PMTimer::LI_to_milli_secs(LARGE_INTEGER &LI) {
    return (((double)LI.QuadPart*1000) /(double)frequency.QuadPart) ;
 }

PMTimer::PMTimer(){
    timer.start.QuadPart=0;
    timer.stop.QuadPart=0;
    total_time.QuadPart = 0;
    QueryPerformanceFrequency(&frequency);
}

void PMTimer::start_timer(){
    QueryPerformanceCounter(&timer.start) ;
}

void PMTimer::stop_timer(){
    QueryPerformanceCounter(&timer.stop) ;
    total_time.QuadPart += (timer.stop.QuadPart - timer.start.QuadPart);
}

void PMTimer::reset_timer(){
    timer.start.QuadPart=0;
    timer.stop.QuadPart=0;
    total_time.QuadPart = 0;
}

double PMTimer::get_elapsed_time(){
    return LI_to_milli_secs(total_time) ;
}

} // parmodelica
} // openmodelica


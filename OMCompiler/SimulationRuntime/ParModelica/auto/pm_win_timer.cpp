
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

/*
 Mahder.Gebremedhin@liu.se  2020-10-12
*/

#include "pm_timer.hpp"

namespace openmodelica { namespace parmodelica {

double PMTimer::LI_to_milli_secs(LARGE_INTEGER& LI) {
    return (((double)LI.QuadPart * 1000) / (double)frequency.QuadPart);
}

PMTimer::PMTimer() {
    timer.start.QuadPart = 0;
    timer.stop.QuadPart = 0;
    total_time.QuadPart = 0;
    QueryPerformanceFrequency(&frequency);
}

void PMTimer::start_timer() {
    QueryPerformanceCounter(&timer.start);
}

void PMTimer::stop_timer() {
    QueryPerformanceCounter(&timer.stop);
    total_time.QuadPart += (timer.stop.QuadPart - timer.start.QuadPart);
}

void PMTimer::reset_timer() {
    timer.start.QuadPart = 0;
    timer.stop.QuadPart = 0;
    total_time.QuadPart = 0;
}

double PMTimer::get_elapsed_time() {
    return LI_to_milli_secs(total_time);
}

}} // namespace openmodelica::parmodelica

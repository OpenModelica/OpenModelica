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

#include "pm_utility.hpp"

namespace openmodelica { namespace parmodelica { namespace utility {

std::ostringstream log_stream;
std::ostringstream warning_stream;
std::ostringstream error_stream;

std::ostream& log(const char* pref = "") {
    std::cout << pref << " : ";
    return std::cout;
}

std::ostream& log() {
    return std::cout;
}

void indexed_dlog(int index, const std::string& message) {
#ifdef OM_PM_LOG_VERBOSE
    std::cerr << "INFO: " << std::to_string(index) << " : " << message << std::endl;
#endif
}

std::ostream& warning(const char* pref = "") {
    warning_stream << pref << " : ";
    return warning_stream;
}

std::ostream& warning() {
    return warning_stream;
}

std::ostream& error(const char* pref = "") {
    // error_stream << pref << " : ";
    std::cerr << pref << " : ";
    return std::cerr;
}

std::ostream& error() {
    // return error_stream;
    return std::cerr;
}

void eq_index_error(int index, const std::string& message) {
    std::cerr << std::to_string(index) << " : " << message << std::endl;
}

void eq_index_fatal(int index, const std::string& message) {
    utility::eq_index_error(index, message);
    exit(1);
}

}}} // namespace openmodelica::parmodelica::utility

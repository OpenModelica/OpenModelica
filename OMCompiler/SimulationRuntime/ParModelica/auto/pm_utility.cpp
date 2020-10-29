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

#include "pm_utility.hpp"


namespace openmodelica {
namespace parmodelica {

namespace utility {

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
    std::cerr << "INFO: "<< std::to_string(index) << " : " << message << std::endl;
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

} // utility
} // parmodelica
} // openmodelica




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

#ifndef MOO_OM_LOG_H
#define MOO_OM_LOG_H

#include "util/omc_error.h"

#include "streamlog.h"


namespace OpenModelica {

// TODO: how to make the distinction between OMEdit target and console / .mos file target?

void create_set_logger() {
    // auto logger = std::make_unique<StreamLogger>();
    // Log::set_global_logger(std::move(logger));
    auto logger = std::make_unique<OMEditStreamLogger>();
    Log::set_global_logger(std::move(logger));
}

void StreamLogger::log(LogLevel lvl, std::string msg) {
    std::string formatted;
    switch (lvl) {
        case LogLevel::Info:
            formatted = fmt::format("{}\n", msg);
            infoStreamPrint(OMC_LOG_MOO, 0, "%s", formatted.c_str());
            break;
        case LogLevel::Success:
            formatted = fmt::format("{}\n", msg);
            infoStreamPrint(OMC_LOG_SUCCESS, 0, "%s", formatted.c_str());
            break;
        case LogLevel::Warning:
            formatted = fmt::format("{}\n", msg);
            warningStreamPrint(OMC_LOG_MOO, 0, "%s", formatted.c_str());
            break;
        case LogLevel::Error:
            formatted = fmt::format("{}\n", msg);
            errorStreamPrint(OMC_LOG_MOO, 0, "%s", formatted.c_str());
            break;
    }
}

// split the message into lines, preserving trailing newline as an empty line
void OMEditStreamLogger::log(LogLevel lvl, std::string msg) {
    std::vector<std::string> lines;
    size_t start = 0;
    size_t pos = 0;
    while ((pos = msg.find('\n', start)) != std::string::npos) {
        lines.push_back(msg.substr(start, pos - start));
        start = pos + 1;
    }

    // if msg ends with '\n', push an empty line to preserve the newline
    if (start <= msg.size()) lines.push_back(msg.substr(start));

    // print each line, first line normally, rest as sub-lines
    for (auto& line : lines) {
        switch (lvl) {
            case LogLevel::Info:
                infoStreamPrint(OMC_LOG_MOO, 0, "%s", line.c_str());
                break;
            case LogLevel::Success:
                infoStreamPrint(OMC_LOG_SUCCESS, 0, "%s", line.c_str());
                break;
            case LogLevel::Warning:
                warningStreamPrint(OMC_LOG_MOO, 0, "%s", line.c_str());
                break;
            case LogLevel::Error:
                errorStreamPrint(OMC_LOG_MOO, 0, "%s", line.c_str());
                break;
        }
    }
}

} // namespace OpenModelica

#endif // MOO_OM_LOG_H

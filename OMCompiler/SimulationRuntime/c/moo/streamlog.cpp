/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2025, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
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

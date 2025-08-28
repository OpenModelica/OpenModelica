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

#include <sstream>
#include <iomanip>

#include <base/util.h>

#include "debug.h"

namespace OpenModelica {

void print_real_var_names(DATA* data) {
    for (long idx = 0; idx < data->modelData->nVariablesReal; idx++)
        infoStreamPrint(OMC_LOG_MOO, 0, "%s", data->modelData->realVarsData[idx].info.name);
}

void print_parameters(DATA* data) { printParameters(data, 1); }

void print_real_var_names_values(DATA* data) {
    long maxNameLen = 2;

    for (long idx = 0; idx < data->modelData->nVariablesReal; idx++) {
        long nameLen = strlen(data->modelData->realVarsData[idx].info.name);
        if (nameLen > maxNameLen)
            maxNameLen = nameLen;
    }

    infoStreamPrint(OMC_LOG_MOO, 0, "Time :: %.17g", data->localData[0]->timeValue);
    infoStreamPrint(OMC_LOG_MOO, 0, "--------------------------------------------------");

    infoStreamPrint(OMC_LOG_MOO, 0, "%-8s :: %-*s :: %s", "Index", static_cast<int>(maxNameLen), "Name", "Value");
    infoStreamPrint(OMC_LOG_MOO, 0, "--------------------------------------------------");

    for (long idx = 0; idx < data->modelData->nVariablesReal; idx++) {
        infoStreamPrint(OMC_LOG_MOO, 0, "%-8ld :: %-*s :: %+.17e",
                        idx,
                        static_cast<int>(maxNameLen), data->modelData->realVarsData[idx].info.name,
                        data->localData[0]->realVars[idx]);
    }
}
void print_jacobian_sparsity(const JACOBIAN* jac, bool print_pattern, const char* name = nullptr) {
    if (!jac || !jac->sparsePattern) {
        errorStreamPrint(OMC_LOG_MOO, 0, "Invalid JACOBIAN or missing SPARSE_PATTERN");
        return;
    }

    const SPARSE_PATTERN* sp = jac->sparsePattern;
    const unsigned int nRows = jac->sizeRows;
    const unsigned int nCols = jac->sizeCols;

    infoStreamPrint(OMC_LOG_MOO, 0, "\n=== JACOBIAN SPARSITY INFO ===");
    if (name) {
        infoStreamPrint(OMC_LOG_MOO, 0, "Name: %s", name);
    }
    infoStreamPrint(OMC_LOG_MOO, 0, "Jacobian: %u rows x %u cols", nRows, nCols);
    infoStreamPrint(OMC_LOG_MOO, 0, "numberOfNonZeros: %u", sp->numberOfNonZeros);
    infoStreamPrint(OMC_LOG_MOO, 0, "sizeofIndex:      %u", sp->sizeofIndex);
    infoStreamPrint(OMC_LOG_MOO, 0, "maxColors:        %u", sp->maxColors);

    // leadindex
    {
        std::ostringstream oss;
        oss << "leadindex: ";
        for (unsigned int i = 0; i <= nCols; ++i) {
            oss << (sp->leadindex ? sp->leadindex[i] : 0) << " ";
        }
        infoStreamPrint(OMC_LOG_MOO, 0, "%s", oss.str().c_str());
    }

    // index
    {
        std::ostringstream oss;
        oss << "index:     ";
        for (unsigned int i = 0; i < sp->sizeofIndex; ++i) {
            oss << (sp->index ? sp->index[i] : 0) << " ";
        }
        infoStreamPrint(OMC_LOG_MOO, 0, "%s", oss.str().c_str());
    }

    // colorCols
    {
        std::ostringstream oss;
        oss << "colorCols: ";
        for (unsigned int i = 0; i < sp->maxColors; ++i) {
            oss << (sp->colorCols ? sp->colorCols[i] : 0) << " ";
        }
        infoStreamPrint(OMC_LOG_MOO, 0, "%s", oss.str().c_str());
    }

    if (!print_pattern) {
        infoStreamPrint(OMC_LOG_MOO, 0, "===============================");
        return;
    }

    infoStreamPrint(OMC_LOG_MOO, 0, "\n=== JACOBIAN SPARSITY PLOT ===");

    // column numbers
    {
        std::ostringstream oss;
        oss << "      ";
        for (unsigned int col = 0; col < nCols; col++)
            oss << (col % 10);
        infoStreamPrint(OMC_LOG_MOO, 0, "%s", oss.str().c_str());
    }

    // rows
    for (unsigned int row = 0; row < nRows; row++) {
        std::ostringstream oss;
        oss << std::setw(4) << row << ": ";
        for (unsigned int col = 0; col < nCols; col++) {
            bool found = false;
            for (unsigned int nz = sp->leadindex[col]; nz < sp->leadindex[col + 1]; nz++) {
                if (sp->index[nz] == row) {
                    found = true;
                    break;
                }
            }
            oss << (found ? '*' : ' ');
        }
        infoStreamPrint(OMC_LOG_MOO, 0, "%s", oss.str().c_str());
    }

    infoStreamPrint(OMC_LOG_MOO, 0, "================================");
}

void print_bounds_fixed_vector(FixedVector<Bounds>& vec) {
    int i = 0;
    for (const auto& b : vec) {
        infoStreamPrint(OMC_LOG_MOO, 0, "[%d] lb: %.17g, ub: %.17g", i++, b.lb, b.ub);
    }
}


void disable_omc_logs() {
    memset(omc_useStream, 0, OMC_SIM_LOG_MAX * sizeof(int));
}

} // namespace OpenModelica

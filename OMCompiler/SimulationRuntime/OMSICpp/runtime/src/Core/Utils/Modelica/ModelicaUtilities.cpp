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

/** @addtogroup coreUtils
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <ModelicaUtilities.h>
#include <stdexcept>
#include <exception>
#include <string>
#include <stdio.h>
#include <stdarg.h>
#include <sstream>
#ifdef __cplusplus
extern "C" {
#endif

void ModelicaMessage(const char* string)
{
    fprintf(stdout, "%s", string);
    fflush(stdout);
}

void ModelicaVFormatMessage(const char* string, va_list args)
{
    vfprintf(stdout, string, args);
    fflush(stdout);
}

void ModelicaFormatMessage(const char* string, ...)
{
    va_list args;
    va_start(args, string);
    ModelicaVFormatMessage(string, args);
    va_end(args);
}

void ModelicaWarning(const char* string)
{
    fprintf(stderr, "%s", string);
}

void ModelicaVFormatWarning(const char* string, va_list args)
{
    vfprintf(stderr, string, args);
}

void ModelicaFormatWarning(const char* string, ...)
{
    va_list args;
    va_start(args, string);
    ModelicaVFormatWarning(string, args);
    va_end(args);
}

void ModelicaError(const char* string)
{
    throw ModelicaSimulationError(UTILITY, string);
}

void ModelicaVFormatError(const char* string, va_list args)
{
    char buffer[256];
    vsnprintf(buffer, 256, string, args);
    ModelicaError(buffer);
}

void ModelicaFormatError(const char* string, ...)
{
    va_list args;
    va_start(args, string);
    ModelicaVFormatError(string, args);
    va_end(args);
}

static std::map<const char*, char*> _allocatedStrings;

char* ModelicaAllocateString(size_t len)
{
    char* res = new char[len + 1];
    if (!res)
        ModelicaFormatError("%s:%d: ModelicaAllocateString failed", __FILE__, __LINE__);
    _allocatedStrings[res] = res;
    res[len] = '\0';
    return res;
}

char* ModelicaAllocateStringWithErrorReturn(size_t len)
{
    char* res = new char[len + 1];
    if (res)
    {
        _allocatedStrings[res] = res;
        res[len] = '\0';
    }
    return res;
}

void _ModelicaFreeStringIfAllocated(const char* str)
{
    std::map<const char*, char*>::iterator it;
    it = _allocatedStrings.find(str);
    if (it != _allocatedStrings.end())
    {
        delete [] _allocatedStrings[str];
        _allocatedStrings.erase(it);
    }
}

#ifdef __cplusplus
}
#endif
/** @} */ // end of coreUtils

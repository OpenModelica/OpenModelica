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

/**
 * \file OMC.h
 * \brief Public C API of libOMCDLL: drive the OpenModelica Compiler (omc)
 *        in-process instead of talking to a separate omc executable.
 *
 * Typical use:
 * \code
 *   InitMetaOMC();
 *   OMCData *omc = NULL;
 *   InitOMC(&omc, "gcc", openModelicaHome);
 *   char *reply = NULL;
 *   SendCommand(omc, "loadModel(Modelica)", &reply);
 *   SendCommand(omc, "getVersion()", &reply);
 *   FreeOMC(omc);
 * \endcode
 *
 * Every call returns a status flag: > 0 on success, <= 0 on failure. On failure
 * use GetError() for a human-readable message. String results (\c char** result)
 * are owned by the omc instance and stay valid until the next call or FreeOMC().
 *
 * Each OMCData instance owns its own compiler state, so independent instances may
 * be used from different threads. A single instance is not thread-safe.
 */

#include "OMCAPI.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Opaque handle to one omc instance. */
typedef struct OMCData OMCData;

/** \deprecated Kept for source compatibility; use OMCData. */
typedef struct OMCData data;

/**
 * \brief Initialize the MetaModelica runtime and garbage collector.
 *
 * Must be called once per process before the first InitOMC().
 */
void OMC_DLL InitMetaOMC(void);

/**
 * \brief Allocate and initialize an omc instance.
 * \param [out] omcDataPtr      receives the new instance
 * \param [in]  compiler        target compiler for generated code, e.g. "gcc"
 * \param [in]  openModelicaHome OpenModelica installation directory (used on
 *                               Windows to locate the standard library; may be
 *                               "" to let omc locate itself)
 * \return status flag
 */
int OMC_DLL InitOMC(OMCData **omcDataPtr, const char *compiler, const char *openModelicaHome);

/**
 * \brief Like InitOMC(), but also configures the generated simulation to stream
 *        results over ZeroMQ (interactive simulation with the C++ runtime).
 * \param [out] omcDataPtr      receives the new instance
 * \param [in]  compiler        target compiler for generated code, e.g. "gcc"
 * \param [in]  codetarget      simCodeTarget, e.g. "Cpp"
 * \param [in]  openModelicaHome OpenModelica installation directory
 * \param [in]  zeromqOptions   extra flags, e.g.
 *                               "--useZeroMQInSim=true --zeroMQPubPort=<port> --zeroMQSubPort=<port>"
 * \param [in]  debug           non-zero to print the resulting option string
 * \return status flag
 */
int OMC_DLL InitOMCWithZeroMQ(OMCData **omcDataPtr, const char *compiler, const char *codetarget,
                              const char *openModelicaHome, const char *zeromqOptions, int debug);

/**
 * \brief Return the version of the omc instance (as reported by getVersion()).
 * \param [in]  omcData omc instance
 * \param [out] result  version string
 * \return status flag
 */
int OMC_DLL GetOMCVersion(OMCData *omcData, char **result);

/**
 * \brief Free an omc instance created by InitOMC() / InitOMCWithZeroMQ().
 * \param [in] omcData omc instance
 */
void OMC_DLL FreeOMC(OMCData *omcData);

/**
 * \brief Return the accumulated error/warning text of the last call.
 * \param [in]  omcData omc instance
 * \param [out] result  error text, empty if there was none
 * \return status flag
 */
int OMC_DLL GetError(OMCData *omcData, char **result);

/**
 * \brief Load a Modelica library from the OpenModelica library path,
 *        e.g. LoadModel(omc, "Modelica").
 * \param [in] omcData   omc instance
 * \param [in] className  library name
 * \return status flag
 */
int OMC_DLL LoadModel(OMCData *omcData, const char *className);

/**
 * \brief Load a Modelica .mo file.
 * \param [in] omcData  omc instance
 * \param [in] fileName path to the .mo file
 * \return status flag
 */
int OMC_DLL LoadFile(OMCData *omcData, const char *fileName);

/**
 * \brief Send an arbitrary scripting command to omc, e.g. "simulate(M)".
 * \param [in]  omcData    omc instance
 * \param [in]  expression command expression
 * \param [out] result     command result
 * \return status flag
 */
int OMC_DLL SendCommand(OMCData *omcData, const char *expression, char **result);

/**
 * \brief Apply a command-line option string, e.g. "-d=newInst" / "--simCodeTarget=Cpp".
 * \param [in] omcData    omc instance
 * \param [in] expression option string
 * \return status flag
 */
int OMC_DLL SetCommandLineOptions(OMCData *omcData, const char *expression);

/**
 * \brief Set the working directory of the omc instance (scripting cd()).
 * \param [in]  omcData   omc instance
 * \param [in]  directory new working directory
 * \param [out] result    the new working directory as reported by omc
 * \return status flag
 */
int OMC_DLL SetWorkingDirectory(OMCData *omcData, const char *directory, char **result);

#ifdef __cplusplus
}
#endif

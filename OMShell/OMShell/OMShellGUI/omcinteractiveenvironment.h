/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef _OMCINTERACTIVE_H
#define _OMCINTERACTIVE_H

#include <QtCore/QString>

#if defined(__EMSCRIPTEN__)
// Web build: omc is not linked in-process. It runs as a separate wasm module in
// a Web Worker (omc_worker.js); this environment bridges to it via postMessage.
// There is no MetaModelica runtime, so threadData is an empty carrier and the
// MMC try/init control flow is plain block structure, mirroring the no-op slice
// of omc_rust_embedding.h so main.cpp compiles unchanged.
struct threadData_s {};
typedef struct threadData_s threadData_t;
#define MMC_INIT(...)       ((void) 0)
#define MMC_TRY_TOP()       { threadData_t threadDataOnStack = {}; threadData_t *threadData = &threadDataOnStack; (void) threadData; {
#define MMC_CATCH_TOP(...)  } if (0) { __VA_ARGS__; } }
#elif defined(OMC_RUST_ABI)
#include "omc_rust_embedding.h"
#else
#include "meta/meta_modelica.h"
#endif

namespace IAEX
{
  class OmcInteractiveEnvironment
  {
  private:
    OmcInteractiveEnvironment(threadData_t *threadData);
    virtual ~OmcInteractiveEnvironment();

  public:
    threadData_t *threadData_;

    static OmcInteractiveEnvironment* getInstance(threadData_t *threadData = 0);
    virtual QString getResult();
    virtual QString getError();
    virtual int getErrorLevel();
    virtual void evalExpression(const QString expr);
#if defined(__EMSCRIPTEN__)
    // Queue a command on the omc worker without blocking the caller (used for the
    // startup MSL install; result/diagnostics are not returned).
    void startBackgroundCommand(const QString expr);
    // Current download progress as display text, or empty when nothing is
    // downloading; used to drive the status bar.
    QString progressText();
#endif
    static QString OMCVersion();
    static QString OpenModelicaHome();
    static QString TmpPath();

  private:
    static OmcInteractiveEnvironment* selfInstance;
    QString result_;
    QString error_;
    QString omcVersion_;
    int severity;
  };
}
#endif

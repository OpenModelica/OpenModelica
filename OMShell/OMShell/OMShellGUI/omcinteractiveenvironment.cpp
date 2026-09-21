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

//STD Headers
#include <exception>
#include <stdexcept>

//QT Headers
#include <QtGlobal>
#include <QtWidgets>

//IAEX Headers
#include "omcinteractiveenvironment.h"

#if defined(__EMSCRIPTEN__)

#include <cstdlib>
#include <QEventLoop>
#include <QTimer>
#include <emscripten.h>
#include <emscripten/em_js.h>

// The omc compiler runs as a separate wasm module in a dedicated Web Worker
// (omc_worker.js), the same one the egui/dioxus web clients use. The bridge
// spawns it and round-trips one command at a time. To keep the Qt UI responsive
// (repaint/resize) while a command runs, evalExpression does NOT block the call
// stack on the reply: it posts the command and spins a nested QEventLoop,
// polling omshell_reply_ready(). Module.__omshellSend serialises commands
// through a promise queue so a fire-and-forget startup task (the MSL install,
// see omshell_worker_eval_async) and later user commands cannot overlap on the
// worker's single reply channel. Download progress is reported back to Qt via
// omshell_progress_text() (shown in the status bar). The page lives in a
// subdirectory next to the shared worker at the web root, hence ../omc_worker.js.
EM_JS(void, omshell_worker_setup, (), {
  if (Module.__omshellWorker) return;
  const w = new Worker(new URL("../omc_worker.js", document.baseURI), { type: "module" });
  Module.__omshellWorker = w;
  Module.__omshellPending = null;
  Module.__omshellLastError = "";
  Module.__omshellReply = null;
  Module.__omshellProgress = null;

  // Serialise commands: each waits for the previous reply before being posted,
  // so the worker's order-based single reply channel stays unambiguous.
  Module.__omshellQueue = Promise.resolve();
  Module.__omshellSend = (msg) => {
    const run = () => new Promise((resolve) => {
      Module.__omshellPending = resolve;
      w.postMessage(msg);
    });
    const p = Module.__omshellQueue.then(run);
    Module.__omshellQueue = p.catch(() => {});
    return p;
  };

  w.onmessage = (e) => {
    const m = e.data;
    if (m && m.kind === "progress") {
      Module.__omshellProgress = m;
      return;
    }
    if (m && (m.kind === "ready" || m.kind === "done")) {
      Module.__omshellProgress = null;
      const resolve = Module.__omshellPending;
      Module.__omshellPending = null;
      if (resolve) resolve(m);
    }
  };
});

// Initialise the worker, returning the omc version. installMsl:false keeps this
// fast so the window appears first; OMShell installs the MSL afterwards. Runs
// before the event loop, so blocking the call stack here is fine.
EM_ASYNC_JS(char*, omshell_worker_init, (), {
  omshell_worker_setup();
  const reply = await Module.__omshellSend({ cmd: "init", installMsl: false });
  Module.__omshellLastError = reply.message || "";
  return stringToNewUTF8(reply.version || "");
});

// Post a command for evalExpression's nested-loop wait: stash the reply (and
// clear stale progress) when it arrives; the C++ side polls omshell_reply_ready.
EM_JS(void, omshell_worker_post_eval, (const char* src), {
  Module.__omshellReply = null;
  Module.__omshellProgress = null;
  Module.__omshellSend({ cmd: "eval", src: UTF8ToString(src) }).then((reply) => {
    Module.__omshellReply = reply;
  });
});

EM_JS(int, omshell_reply_ready, (), {
  return Module.__omshellReply ? 1 : 0;
});

// Hand the stashed reply to C++: return the result, keep its diagnostics for
// omshell_worker_last_error(), and clear the slot for the next command.
EM_JS(char*, omshell_take_result, (), {
  const reply = Module.__omshellReply || {};
  Module.__omshellLastError = reply.error || "";
  Module.__omshellReply = null;
  Module.__omshellProgress = null;
  return stringToNewUTF8(reply.result || "");
});

// Current download progress as display text, or "" when nothing is downloading.
EM_JS(char*, omshell_progress_text, (), {
  const p = Module.__omshellProgress;
  if (!p) return stringToNewUTF8("");
  const s = p.total > 0
    ? "Downloading " + p.file + "  " + Math.round(100 * p.done / p.total) + "%"
    : "Downloading " + p.file + "  " + Math.round(p.done / 1024) + " KiB";
  return stringToNewUTF8(s);
});

// Queue a command without waiting for its reply. Used at startup for the MSL
// install so the Qt window comes up first; its progress shows via the status bar
// poll (see OMS) and omshell_progress_text().
EM_JS(void, omshell_worker_eval_async, (const char* src), {
  Module.__omshellSend({ cmd: "eval", src: UTF8ToString(src) });
});

EM_JS(char*, omshell_worker_last_error, (), {
  return stringToNewUTF8(Module.__omshellLastError || "");
});

namespace IAEX
{
  OmcInteractiveEnvironment* OmcInteractiveEnvironment::selfInstance = NULL;
  OmcInteractiveEnvironment* OmcInteractiveEnvironment::getInstance(threadData_t *threadData)
  {
    if (selfInstance == NULL)
    {
      selfInstance = new OmcInteractiveEnvironment(threadData);
    }
    return selfInstance;
  }

  static QString takeCString(char *s)
  {
    QString result = QString::fromUtf8(s ? s : "");
    free(s);
    return result;
  }

  OmcInteractiveEnvironment::OmcInteractiveEnvironment(threadData_t *threadData):threadData_(threadData),result_(""),error_("")
  {
    omcVersion_ = takeCString(omshell_worker_init());
  }

  OmcInteractiveEnvironment::~OmcInteractiveEnvironment()
  {
  }

  QString OmcInteractiveEnvironment::getResult() { return result_; }
  QString OmcInteractiveEnvironment::getError() { return error_; }
  int OmcInteractiveEnvironment::getErrorLevel() { return severity; }

  void OmcInteractiveEnvironment::evalExpression(const QString expr)
  {
    error_.clear();
    // Wait for the worker reply without suspending the Qt call stack: a nested
    // event loop keeps the UI painting/resizing while a poll timer watches for
    // the reply. Without this the whole window freezes for the command's
    // duration (Asyncify would suspend the event loop itself).
    omshell_worker_post_eval(expr.toUtf8().constData());
    QEventLoop loop;
    QTimer poll;
    QObject::connect(&poll, &QTimer::timeout, &loop, [&loop]() {
      if (omshell_reply_ready()) loop.quit();
    });
    poll.start(30);
    loop.exec();
    result_ = takeCString(omshell_take_result()).trimmed();
    error_ = takeCString(omshell_worker_last_error()).trimmed();
    if( error_.size() > 2 ) {
      if (error_.contains("Error:")) {
        severity = 2;
      } else if (error_.contains("Warning:")) {
        severity = 1;
      } else {
        severity = 0;
      }
    } else {
      error_.clear();
      severity = 0;
    }
  }

  void OmcInteractiveEnvironment::startBackgroundCommand(const QString expr)
  {
    omshell_worker_eval_async(expr.toUtf8().constData());
  }

  QString OmcInteractiveEnvironment::progressText()
  {
    return takeCString(omshell_progress_text());
  }

  QString OmcInteractiveEnvironment::OMCVersion()
  {
    return OmcInteractiveEnvironment::getInstance()->omcVersion_;
  }

  QString OmcInteractiveEnvironment::OpenModelicaHome()
  {
    return QString();
  }

  QString OmcInteractiveEnvironment::TmpPath()
  {
    return QString("/tmp/OpenModelica/");
  }
}

#else

#ifndef WIN32
#include "omc_config.h"
#endif
#ifndef OMC_RUST_ABI
#include "gc.h"
#endif

extern "C" {
int omc_Main_handleCommand(void *threadData, void *imsg, void **omsg);
void* omc_Main_init(void *threadData, void *args);
void omc_System_initGarbageCollector(void *threadData);
#ifdef WIN32
void omc_Main_setWindowsPaths(threadData_t *threadData, void* _inOMHome);
#endif
}

namespace IAEX
{
  OmcInteractiveEnvironment* OmcInteractiveEnvironment::selfInstance = NULL;
  OmcInteractiveEnvironment* OmcInteractiveEnvironment::getInstance(threadData_t *threadData)
  {
    if (selfInstance == NULL)
    {
      selfInstance = new OmcInteractiveEnvironment(threadData);
    }
    return selfInstance;
  }

  /*! \class OmcInteractiveEnvironment
  *
  * \brief Implements evaluation for modelica code.
  */
  OmcInteractiveEnvironment::OmcInteractiveEnvironment(threadData_t *threadData):threadData_(threadData),result_(""),error_("")
  {
    // set the language by reading the OMEdit settings file.
    QSettings settings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omedit");
    QLocale settingsLocale = QLocale(settings.value("language").toString());
    settingsLocale = settingsLocale.name() == "C" ? settings.value("language").toLocale() : settingsLocale;
    void *args = mmc_mk_nil();
    QString locale = "+locale=" + settingsLocale.name();
    args = mmc_mk_cons(mmc_mk_scon(locale.toStdString().c_str()), args);
    // initialize garbage collector
    omc_System_initGarbageCollector(NULL);
    MMC_TRY_TOP_INTERNAL()
    omc_Main_init(threadData, args);
    threadData->plotClassPointer = 0;
    threadData->plotCB = 0;
    MMC_CATCH_TOP()
    // set the +d=initialization flag default.
    evalExpression(QString("setCommandLineOptions(\"+d=initialization\")"));
#ifdef WIN32
    evalExpression(QString("getInstallationDirectoryPath()"));
    QString result = getResult();
    result = result.remove( "\"" );
    MMC_TRY_TOP_INTERNAL()
    omc_Main_setWindowsPaths(threadData, mmc_mk_scon(result.toStdString().c_str()));
    MMC_CATCH_TOP()
#endif
  }

  OmcInteractiveEnvironment::~OmcInteractiveEnvironment()
  {
    //if (selfInstance)
    //  delete selfInstance;
#ifndef OMC_RUST_ABI
    GC_free(threadData_);
#endif
  }

  QString OmcInteractiveEnvironment::getResult()
  {
    return result_;
  }

  /*!
   * \author Anders FernstrÃ¶m
   * \date 2006-02-02
   *
   *\brief Method for get error message from OMC
   */
  QString OmcInteractiveEnvironment::getError()
  {
    return error_;
  }

  /*!
   * \author Hennning Kiel
   * \date 2017-05-24
   *
   *\brief Method to get error message severity from OMC
   */
  int OmcInteractiveEnvironment::getErrorLevel()
  {
    return severity;
  }

  // QMutex omcMutex;

  /*!
   * \author Ingemar Axelsson and Anders FernstrÃ¶m
   * \date 2006-02-02 (update)
   *
   * \brief Method for evaluationg expressions
   *
   * 2006-02-02 AF, Added try-catch statement
   */
  void OmcInteractiveEnvironment::evalExpression(const QString expr)
  {
    error_.clear(); // clear any error!
    // call OMC with expression
    void *reply_str = NULL;
    threadData_t *threadData = threadData_;
    MMC_TRY_TOP_INTERNAL()

    MMC_TRY_STACK()

    if (!omc_Main_handleCommand(threadData, mmc_mk_scon(expr.toStdString().c_str()), &reply_str)) {
      return;
    }
    result_ = QString::fromUtf8((char*)MMC_STRINGDATA(reply_str));
    result_ = result_.trimmed();
    reply_str = NULL;
    // see if there are any errors if the expr is not "quit()"
    if (!omc_Main_handleCommand(threadData, mmc_mk_scon("getErrorString()"), &reply_str)) {
      return;
    }
    error_ = QString::fromUtf8((char*)MMC_STRINGDATA(reply_str));
    error_ = error_.trimmed();
    if( error_.size() > 2 ) {
      if (error_.contains("Error:")) {
        severity = 2;
      } else if (error_.contains("Warning:")) {
        severity = 1;
      } else {
        severity = 0;
      }
    } else { // no errors, clear the error.
      error_.clear();
      severity = 0;
    }

    MMC_ELSE()
      result_ = "";
      error_ = "";
      severity = 3;
      fprintf(stderr, "Stack overflow detected and was not caught.\nSend us a bug report at https://trac.openmodelica.org/OpenModelica/newticket\n    Include the following trace:\n");
      printStacktraceMessages();
      fflush(NULL);
    MMC_CATCH_STACK()

    MMC_CATCH_TOP(result_ = "");
  }

  /*!
   * \author Anders FernstrÃ¶m
   * \date 2006-08-17
   *
   *\brief Ststic method for returning the version of omc
   */
  QString OmcInteractiveEnvironment::OMCVersion()
  {
    QString version( "(version)" );

    try
    {
      OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
      QString getVersion = "getVersion()";
      env->evalExpression( getVersion );
      version = env->getResult();
      version.remove( "\"" );
      //delete env;
    }
    catch( std::exception &e )
    {
      e.what();
      QMessageBox::critical( 0, QObject::tr("OMC Error"), QObject::tr("Unable to get OMC version, OMC is not started.") );
    }

    return version;
  }

  QString OmcInteractiveEnvironment::OpenModelicaHome()
  {
    OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
    env->evalExpression(QString("getInstallationDirectoryPath()"));
    QString result = env->getResult();
    result = result.remove( "\"" );
    return result;
  }

  QString OmcInteractiveEnvironment::TmpPath()
  {
    OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
    env->evalExpression(QString("getTempDirectoryPath()"));
    QString result = env->getResult();
    result = result.replace("\\", "/");
    result.remove( "\"" );
    return result+"/OpenModelica/";
  }
}

#endif

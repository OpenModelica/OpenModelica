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
#include <QJsonDocument>
#include <QJsonArray>
#include <emscripten.h>
#include <emscripten/em_js.h>

// omc runs as a separate wasm module in a dedicated Web Worker (omc_worker.js),
// the same one the egui/dioxus/OMShell-qt web clients use. The bridge spawns it
// and round-trips one command at a time. To keep the Qt UI responsive while a
// command runs, evalExpression posts the command and spins a nested QEventLoop
// polling omshell_reply_ready(), instead of suspending the call stack. Sends are
// serialised through a JS promise queue so the fire-and-forget startup MSL
// install and later user commands cannot overlap on the single reply channel.
// Download progress is reported back via omshell_progress_text(). The page lives
// in a subdirectory next to the shared worker at the web root (../omc_worker.js).
EM_JS(void, omshell_worker_setup, (), {
  if (Module.__omshellWorker) return;
  const w = new Worker(new URL("../omc_worker.js", document.baseURI), { type: "module" });
  Module.__omshellWorker = w;
  Module.__omshellPending = null;
  Module.__omshellLastError = "";
  Module.__omshellReply = null;
  Module.__omshellProgress = null;

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

EM_ASYNC_JS(char*, omshell_worker_init, (), {
  omshell_worker_setup();
  const reply = await Module.__omshellSend({ cmd: "init", installMsl: false });
  Module.__omshellLastError = reply.message || "";
  return stringToNewUTF8(reply.version || "");
});

EM_JS(void, omshell_worker_post_eval, (const char* src), {
  Module.__omshellReply = null;
  Module.__omshellProgress = null;
  Module.__omshellPlots = [];
  Module.__omshellSend({ cmd: "eval", src: UTF8ToString(src) }).then((reply) => {
    // Stage each plot's result file into this module's FS (so OMPlot can fopen
    // it) and keep its args for GraphCell. Set __omshellReply LAST so
    // omshell_reply_ready() only reports done once the files are in place.
    const plots = [];
    for (const p of (reply.plots || [])) {
      try {
        if (p.bytes && p.file) {
          const slash = p.file.lastIndexOf("/");
          if (slash > 0) FS.mkdirTree(p.file.substring(0, slash));
          FS.writeFile(p.file, p.bytes);
        }
        plots.push(p.args);
      } catch (e) {
        console.error("OMNotebook: staging plot result failed", e);
      }
    }
    Module.__omshellPlots = plots;
    Module.__omshellReply = reply;
  });
});

// Take (and clear) the staged plot arg lists as JSON (array of 18-string arrays).
EM_JS(char*, omshell_take_plots_json, (), {
  const plots = Module.__omshellPlots || [];
  Module.__omshellPlots = [];
  return stringToNewUTF8(JSON.stringify(plots));
});

EM_JS(int, omshell_reply_ready, (), {
  return Module.__omshellReply ? 1 : 0;
});

EM_JS(char*, omshell_take_result, (), {
  const reply = Module.__omshellReply || {};
  Module.__omshellLastError = reply.error || "";
  Module.__omshellReply = null;
  Module.__omshellProgress = null;
  return stringToNewUTF8(reply.result || "");
});

EM_JS(char*, omshell_progress_text, (), {
  const p = Module.__omshellProgress;
  if (!p) return stringToNewUTF8("");
  const s = p.total > 0
    ? "Downloading " + p.file + "  " + Math.round(100 * p.done / p.total) + "%"
    : "Downloading " + p.file + "  " + Math.round(p.done / 1024) + " KiB";
  return stringToNewUTF8(s);
});

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
    // A command runs a nested event loop; ignore evals triggered (e.g. from
    // another cell) while one is already in flight to keep the single worker
    // reply channel unambiguous.
    static bool active = false;
    if (active) { result_.clear(); error_.clear(); severity = 0; return; }
    active = true;

    error_.clear();
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
        error_ = QString( "OMC-ERROR: \n" ) + error_;
      } else if (error_.contains("Warning:")) {
        severity = 1;
        error_ = QString( "OMC-WARNING: \n" ) + error_;
      } else {
        severity = 0;
      }
    } else {
      error_.clear();
      severity = 0;
    }
    active = false;
  }

  void OmcInteractiveEnvironment::startBackgroundCommand(const QString expr)
  {
    omshell_worker_eval_async(expr.toUtf8().constData());
  }

  QList<QStringList> OmcInteractiveEnvironment::takePlotCommands()
  {
    QList<QStringList> out;
    QString json = takeCString(omshell_take_plots_json());
    QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8());
    if (doc.isArray()) {
      const QJsonArray cmds = doc.array();
      for (const QJsonValue &cmd : cmds) {
        QStringList args;
        const QJsonArray a = cmd.toArray();
        for (const QJsonValue &v : a) {
          args << v.toString();
        }
        out << args;
      }
    }
    return out;
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
    threadData_->plotClassPointer = 0;
    threadData_->plotCB = 0;
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
    result_ = MMC_STRINGDATA(reply_str);
    result_ = result_.trimmed();
    reply_str = NULL;
    // see if there are any errors if the expr is not "quit()"
    if (!omc_Main_handleCommand(threadData, mmc_mk_scon("getErrorString()"), &reply_str)) {
      return;
    }
    error_ = MMC_STRINGDATA(reply_str);
    error_ = error_.trimmed();
    if( error_.size() > 2 ) {
      if (error_.contains("Error:")) {
        severity = 2;
        error_ = QString( "OMC-ERROR: \n" ) + error_;
      } else if (error_.contains("Warning:")) {
        severity = 1;
        error_ = QString( "OMC-WARNING: \n" ) + error_;
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
    catch(std::exception &e )
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

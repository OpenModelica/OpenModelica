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

/*
 * @author John Tinnerholm
 */

#include "XMILETranslator.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"

#include <QCoreApplication>
#include <QFileInfo>
#include <QLibrary>
#include <QProcess>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>
#include <utility>
#include <vector>

namespace {
const char *translatorKey = "xmileImport/translator";
// The C interface of libxmile2mo (xmile2mo.h in XMILEToModelica.jl)
typedef int (*TranslateFunction)(const char *input, const char *output, int modular, const char *name,
                                 const char *const *excel, int nexcel);
typedef const char *(*ErrorFunction)();
}

/*!
 * \brief XMILETranslator::translator
 * The translator set by the user (remembered in the settings), else the one findTranslator finds.
 */
QString XMILETranslator::translator()
{
  QString path = savedTranslator();
  return path.isEmpty() ? findTranslator() : path;
}

QString XMILETranslator::savedTranslator()
{
  return Utilities::getApplicationSettings()->value(translatorKey).toString();
}

void XMILETranslator::setTranslator(const QString &path)
{
  Utilities::getApplicationSettings()->setValue(translatorKey, path);
}

/*!
 * \brief XMILETranslator::findTranslator
 * The environment variable XMILE2MO, libxmile2mo in OPENMODELICAHOME/lib, xmile2mo in OPENMODELICAHOME/bin,
 * or xmile2mo on the PATH; empty when there is none.
 */
QString XMILETranslator::findTranslator()
{
  QStringList candidates;
  candidates << QString::fromLocal8Bit(qgetenv("XMILE2MO"));
  const QStringList suffixes = {"dylib", "so", "dll"};
  for (const QString &suffix : suffixes) {
    candidates << QString("%1/lib/libxmile2mo.%2").arg(Helper::OpenModelicaHome, suffix);
  }
#ifdef Q_OS_WIN
  candidates << QString("%1/bin/xmile2mo.exe").arg(Helper::OpenModelicaHome);
#else
  candidates << QString("%1/bin/xmile2mo").arg(Helper::OpenModelicaHome);
#endif
  candidates << QStandardPaths::findExecutable("xmile2mo");
  for (const QString &candidate : std::as_const(candidates)) {
    if (!candidate.isEmpty() && QFileInfo(candidate).isFile()) {
      return candidate;
    }
  }
  return QString();
}

/*!
 * \brief XMILETranslator::modelName
 * A Modelica name from a file name: the base name with characters other than letters, digits and _ replaced by _.
 */
QString XMILETranslator::modelName(const QString &fileName)
{
  QString name = QFileInfo(fileName).completeBaseName();
  name.replace(QRegularExpression("[^A-Za-z0-9_]"), "_");
  if (name.isEmpty() || name.at(0).isDigit()) {
    name.prepend("_");
  }
  return name;
}

/*!
 * \brief XMILETranslator::translate
 * Translates options.input to options.output. Returns false and sets *pError when the translation failed.
 */
bool XMILETranslator::translate(const Options &options, QString *pError)
{
  QString path = translator();
  if (path.isEmpty()) {
    *pError = QCoreApplication::translate("XMILETranslator", "No XMILE translator found: set the path of libxmile2mo or xmile2mo "
                                          "(XMILEToModelica.jl) in the dialog or in the environment variable XMILE2MO.");
    return false;
  }
  if (!QFileInfo(path).isFile()) {
    *pError = QCoreApplication::translate("XMILETranslator", "The XMILE translator %1 does not exist.").arg(path);
    return false;
  }
  bool ok = QLibrary::isLibrary(path) ? translateWithLibrary(path, options, pError) : translateWithExecutable(path, options, pError);
  if (ok && !QFileInfo(options.output).isFile()) {
    *pError = QCoreApplication::translate("XMILETranslator", "The translator did not write %1.").arg(options.output);
    return false;
  }
  return ok;
}

/*!
 * \brief XMILETranslator::translateWithLibrary
 * Calls xmile2mo_translate in the shared library. The library starts the Julia runtime at its first call; a runtime
 * cannot be unloaded, so the library stays loaded and another library needs a restart of OMEdit.
 */
bool XMILETranslator::translateWithLibrary(const QString &library, const Options &options, QString *pError)
{
  static QLibrary *pLibrary = 0;
  static QString loadedLibrary;
  static TranslateFunction translateFunction = 0;
  static ErrorFunction errorFunction = 0;
  if (pLibrary && loadedLibrary != library) {
    *pError = QCoreApplication::translate("XMILETranslator", "The XMILE translator %1 is loaded. Restart OMEdit to use %2.")
              .arg(loadedLibrary, library);
    return false;
  }
  if (!pLibrary) {
    QLibrary *pNewLibrary = new QLibrary(library);
    if (!pNewLibrary->load()) {
      *pError = QCoreApplication::translate("XMILETranslator", "Unable to load %1: %2").arg(library, pNewLibrary->errorString());
      delete pNewLibrary;
      return false;
    }
    translateFunction = (TranslateFunction)pNewLibrary->resolve("xmile2mo_translate");
    errorFunction = (ErrorFunction)pNewLibrary->resolve("xmile2mo_error");
    if (!translateFunction || !errorFunction) {
      *pError = QCoreApplication::translate("XMILETranslator", "%1 has no xmile2mo_translate or xmile2mo_error.").arg(library);
      pNewLibrary->unload();
      delete pNewLibrary;
      return false;
    }
    pLibrary = pNewLibrary;
    loadedLibrary = library;
  }
  // Julia opens files with UTF-8 names on all platforms
  QByteArray input = options.input.toUtf8();
  QByteArray output = options.output.toUtf8();
  QByteArray name = options.name.toUtf8();
  std::vector<QByteArray> excel;
  std::vector<const char*> excelPointers;
  for (const QString &file : options.excel) {
    excel.push_back(file.toUtf8());
  }
  for (const QByteArray &file : excel) {
    excelPointers.push_back(file.constData());
  }
  int status = translateFunction(input.constData(), output.constData(), (int)options.form, name.constData(),
                                 excelPointers.empty() ? 0 : excelPointers.data(), (int)excelPointers.size());
  if (status != 0) {
    *pError = QString::fromUtf8(errorFunction());
    return false;
  }
  return true;
}

/*!
 * \brief XMILETranslator::translateWithExecutable
 * Runs xmile2mo [--modular [--sectors never|always]] --name NAME [--excel FILE]... -o OUTPUT INPUT.
 */
bool XMILETranslator::translateWithExecutable(const QString &executable, const Options &options, QString *pError)
{
  QStringList arguments;
  if (options.form != Flat) {
    arguments << "--modular";
  }
  if (options.form == BlocksWithoutSectors) {
    arguments << "--sectors" << "never";
  } else if (options.form == BlocksInSectors) {
    arguments << "--sectors" << "always";
  }
  if (!options.name.isEmpty()) {
    arguments << "--name" << options.name;
  }
  for (const QString &file : options.excel) {
    arguments << "--excel" << file;
  }
  arguments << "-o" << options.output << options.input;
  QProcess process;
  process.start(executable, arguments);
  if (!process.waitForStarted()) {
    *pError = QCoreApplication::translate("XMILETranslator", "Unable to run %1: %2").arg(executable, process.errorString());
    return false;
  }
  if (!process.waitForFinished(120000)) {
    process.kill();
    *pError = QCoreApplication::translate("XMILETranslator", "%1 did not finish within 120 s.").arg(executable);
    return false;
  }
  if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
    QString message = QString::fromUtf8(process.readAllStandardError()).trimmed();
    message.remove(QRegularExpression("^xmile2mo: "));
    *pError = message.isEmpty() ? QCoreApplication::translate("XMILETranslator", "%1 failed (exit code %2).")
                                  .arg(executable).arg(process.exitCode()) : message;
    return false;
  }
  return true;
}

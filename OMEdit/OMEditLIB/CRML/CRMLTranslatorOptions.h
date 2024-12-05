/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef CRMLTRANSLATOROPTIONS_H
#define CRMLTRANSLATOROPTIONS_H

#include "MainWindow.h"

#include <QString>
#include <QVariant>
#include <QStringList>

class CRMLTranslatorOptions
{
public:
  CRMLTranslatorOptions()
  {
    // General
    setMode("translateAs");
    setCompilerJar("");
    setRepositoryDirectory("");
    setCompilerCommandLineOptions("");
    setCompilerProcess("");
    setCRMLLibraryPaths("");
    setModelicaLibraryPaths("");
    setModelicaLibraries({});
  }

  // what functionality we need
  void setMode(const QString &mode) {mMode = mode;}
  QString getMode() const {return mMode;}

  // dynamic compiler options
  void setCRMLFile(const QString &file) {mCRMLFile = file;}
  QString getCRMLFile() const {return mCRMLFile;}
  void setOutputDirectory(const QString &directory) {mOutputDirectory = directory;}
  QString getOutputDirectory() const {return mOutputDirectory;}
  void setModelicaWithin(const QString &within) {mModelicaWithin = within;}
  QString getModelicaWithin() const {return mModelicaWithin;}

  // compiler options
  void setCompilerJar(const QString &compilerJar) {mCompilerJar = compilerJar;}
  QString getCompilerJar() const {return mCompilerJar;}
  void setRepositoryDirectory(const QString &repositoryDirectory) {mRepositoryDirectory = repositoryDirectory;}
  QString getRepositoryDirectory() const {return mRepositoryDirectory;}
  void setCompilerCommandLineOptions(const QString &compilerCommandLineOptions) {mCompilerCommandLineOptions = compilerCommandLineOptions;}
  QString getCompilerCommandLineOptions() const {return mCompilerCommandLineOptions;}
  void setCompilerProcess(const QString &process) {mCompilerProcess = process;}
  QString getCompilerProcess() const {return mCompilerProcess;}
  void setCRMLLibraryPaths(const QString &crmlLibraryPaths) {mCRMLLibraryPaths = crmlLibraryPaths;}
  QString getCRMLLibraryPaths() const {return mCRMLLibraryPaths;}
  void setModelicaLibraryPaths(const QString &modelicaLibraryPaths) {mModelicaLibraryPaths = modelicaLibraryPaths;}
  QString getModelicaLibraryPaths() const {return mModelicaLibraryPaths;}
  void setModelicaLibraries(const QStringList &modelicaLibraries) {mModelicaLibraries = modelicaLibraries;}
  QStringList getModelicaLibraries() const {return mModelicaLibraries;}
private:
  QString mMode;

  QString mCRMLFile;
  QString mOutputDirectory;
  QString mModelicaWithin;

  QString mCompilerJar;
  QString mRepositoryDirectory;
  QString mCompilerCommandLineOptions;
  QString mCompilerProcess;
  QString mCRMLLibraryPaths;
  QString mModelicaLibraryPaths;
  QStringList mModelicaLibraries;
};

#endif // CRMLTRANSLATOROPTIONS_H

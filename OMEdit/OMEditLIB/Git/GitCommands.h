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

#ifndef GITCOMMANDS_H
#define GITCOMMANDS_H


#include <QObject>
#include "QStandardItemModel"
#include "QTreeView"
#include "QPlainTextEdit"
#include "QCheckBox"
#include "QDialogButtonBox"
#include <QProcess>


class GitCommands : public QObject
{
  Q_OBJECT
private:
  // the only class that is allowed to create and destroy
  friend class MainWindow;

  static void create();
  static void destroy();
  GitCommands(QWidget *pParent = 0);
  static GitCommands *mpInstance;
  static QString getGitStdout(const QStringList &args);
  static QString getGitStdout(const QString &fileName, const QStringList &args);
public:
//  GitCommands(QObject *pParent = 0);
  static GitCommands* instance() {return mpInstance;}
  void logCurrentFile(QString currentFile);
  void stageCurrentFileForCommit(QString currentFile);
  void unstageCurrentFileFromCommit(QString currentFile);
  void cleanWorkingDirectory();
  void createGitRepository(QString reporitoryPath);
  void addStructuresToRepository(QString reporitoryPath);
  bool isGitInstalled();
  bool isSavedUnderGitRepository(QString filePath);
  QStringList getUntrackedFiles(QString workingDirectory);
  QStringList getChangedFiles(QString filePath);
  QString getSingleFileStatus(QString fileName);
  QString getRepositoryName(QString directory);
  QString getBranchName(QString directory);
  QString getAuthorName();
  QString getEmailName();
  QString getGitHash(QString fileName);
  void commitFiles(QString repositoryPath, QString commitMessage);
  QString commitAndGetFileHash(QString fileName, QString activity);
private:
  QString mGitProgram;
  QStringList mGitArguments;
  void runGitCommand(QString driectory, QStringList args);
private slots:
//  void gitProcessStarted();
//  void readGitStandardOutput();
//  void readGitStandardError();
//  void gitProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
//signals:
//  void sendGitProcessStarted();
//  void sendGitProcessOutput(QString, StringHandler::SimulationMessageType type);
//  void sendGitProcessFinished(int, QProcess::ExitStatus);
//  void sendGitProgress(int);
};

#endif // GITCOMMANDS_H

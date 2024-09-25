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

#ifndef FMUEXPORTOUTPUTWIDGET_H
#define FMUEXPORTOUTPUTWIDGET_H

#include <QPlainTextEdit>
#include <QProgressBar>
#include <QPushButton>
#include <QWidget>
#include <QProcess>
#include <QTabWidget>
#include "Modeling/LibraryTreeWidget.h"

class Label;
class OutputPlainTextEdit;

class FmuExportOutputWidget : public QWidget
{
  Q_OBJECT
public:
  FmuExportOutputWidget(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent = 0);
  ~FmuExportOutputWidget();
  QProgressBar* getProgressBar() {return mpProgressBar;}
  QTabWidget* getGeneratedFilesTabWidget() {return mpGeneratedFilesTabWidget;}
  QProcess* getCompilationProcess() {return mpCompilationProcess;}
  void setCompilationProcessKilled(bool killed) {mIsCompilationProcessKilled = killed;}
  bool isCompilationProcessKilled() {return mIsCompilationProcessKilled;}
  bool isCompilationProcessRunning() {return mIsCompilationProcessRunning;}
  QProcess* getPostCompilationProcess() {return mpPostCompilationProcess;}
  void setPostCompilationProcessKilled(bool killed) {mIsPostCompilationProcessKilled = killed;}
  bool isPostCompilationProcessKilled() {return mIsPostCompilationProcessKilled;}
  bool isPostCompilationProcessRunning() {return mIsPostCompilationProcessRunning;}
  QProcess* getZipCompilationProcess() {return mpZipCompilationProcess;}
  void setZipCompilationProcessKilled(bool killed) {mIsZipCompilationProcessKilled = killed;}
  bool isZipCompilationProcessKilled() {return mIsZipCompilationProcessKilled;}
  bool isZipCompilationProcessRunning() {return mIsZipCompilationProcessRunning;}
  QString getFMUPath() {return mFmuLocationPath;}
  void updateMessageTab(const QString &text);
  void updateMessageTabProgress();
  void compileModel();
private:
  QString mFmuTmpPath;
  QString mFMUName;
  QString mFmuLocationPath;
  LibraryTreeItem *mpLibraryTreeItem;
  Label *mpProgressLabel;
  QProgressBar *mpProgressBar;
  QPushButton *mpCancelButton;
  QTabWidget *mpGeneratedFilesTabWidget;
  OutputPlainTextEdit *mpCompilationOutputTextBox;
  OutputPlainTextEdit *mpPostCompilationOutputTextBox;
  QProcess *mpCompilationProcess;
  bool mIsCompilationProcessKilled;
  bool mIsCompilationProcessRunning;
  QProcess *mpPostCompilationProcess;
  bool mIsPostCompilationProcessKilled;
  bool mIsPostCompilationProcessRunning;
  QProcess *mpZipCompilationProcess;
  bool mIsZipCompilationProcessKilled;
  bool mIsZipCompilationProcessRunning;
  void runPostCompilation();
  void postCompilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus);
  void writeCompilationOutput(QString output, QColor color);
  void writePostCompilationOutput(QString output, QColor color);
  void compilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus);
  void zipFMU();
  void ZipCompilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus);
  void setDefaults();
private slots:
  void compilationProcessStarted();
  void readCompilationStandardOutput();
  void readCompilationStandardError();
  void compilationProcessError(QProcess::ProcessError error);
  void compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void postCompilationProcessStarted();
  void readPostCompilationStandardOutput();
  void readPostCompilationStandardError();
  void postCompilationProcessError(QProcess::ProcessError error);
  void postCompilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void ZipCompilationProcessStarted();
  void readZipCompilationStandardOutput();
  void readZipCompilationStandardError();
  void ZipCompilationProcessError(QProcess::ProcessError error);
  void ZipCompilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
public slots:
  void cancelCompilation();
signals:
  void updateText(const QString &text);
  void updateProgressBar(QProgressBar *pProgressBar);
};

#endif // FMUEXPORTOUTPUTWIDGET_H


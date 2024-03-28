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

#ifndef CRMLTRANSLATOROUTPUTWIDGET_H
#define CRMLTRANSLATOROUTPUTWIDGET_H

#include "CRMLTranslatorOptions.h"
#include "Util/StringHandler.h"

#include <QTreeView>
#include <QPlainTextEdit>
#include <QProgressBar>
#include <QPushButton>
#include <QTextBrowser>
#include <QProcess>
#include <QDateTime>
#include <QTcpServer>

class Label;
class OutputPlainTextEdit;
class CRMLTranslatorOutputWidget;
class SimulationMessage;

class CRMLTranslatorOutputWidget : public QWidget
{
  Q_OBJECT
public:
  CRMLTranslatorOutputWidget(CRMLTranslatorOptions simulationOptions, QWidget *pParent = 0);
  ~CRMLTranslatorOutputWidget();
  void start();
  CRMLTranslatorOptions getCRMLTranslatorOptions() {return mCRMLTranslatorOptions;}
  QProgressBar* getProgressBar() {return mpProgressBar;}
  QProcess* getCompilationProcess() {return mpCompilationProcess;}
  void setCompilationProcessKilled(bool killed) {mIsCompilationProcessKilled = killed;}
  bool isCompilationProcessKilled() {return mIsCompilationProcessKilled;}
  bool isCompilationProcessRunning() {return mIsCompilationProcessRunning;}
  void updateMessageTab(const QString &text);
  void updateMessageTabProgress();
private:
  CRMLTranslatorOptions mCRMLTranslatorOptions;
  Label *mpProgressLabel;
  QProgressBar *mpProgressBar;
  QPushButton *mpCancelButton;
  QTabWidget *mpGeneratedFilesTabWidget;
  QList<QString> mGeneratedFilesList;
  OutputPlainTextEdit *mpCompilationOutputTextBox;
  QString mSimulationStandardOutput;
  QString mSimulationStandardError;
  QProcess *mpCompilationProcess;
  bool mIsCompilationProcessKilled;
  bool mIsCompilationProcessRunning;

  void compileModel();
  void postCompilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus);
  void writeCompilationOutput(QString output, QColor color);
  void compilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus);
private slots:
  void compilationProcessStarted();
  void readCompilationStandardOutput();
  void readCompilationStandardError();
  void compilationProcessError(QProcess::ProcessError error);
  void compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
public slots:
  void cancelCompilation();
signals:
  void updateText(const QString &text);
  void updateProgressBar(QProgressBar *pProgressBar);
};

#endif // CRMLTRANSLATOROUTPUTWIDGET_H

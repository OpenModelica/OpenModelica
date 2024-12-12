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

#include <QProgressBar>
#include <QPushButton>
#include <QTabWidget>
#include <QProcess>

class Label;
class OutputPlainTextEdit;
class CRMLTranslatorOutputWidget;
class SimulationMessage;

class CRMLTranslatorOutputWidget : public QWidget
{
  Q_OBJECT
public:
  CRMLTranslatorOutputWidget(CRMLTranslatorOptions crmlTranslatorOptions, QWidget *pParent = 0);
  ~CRMLTranslatorOutputWidget();
  void start();
  CRMLTranslatorOptions getCRMLTranslatorOptions() {return mCRMLTranslatorOptions;}
  QProgressBar* getProgressBar() {return mpProgressBar;}
  void setTranslationProcessKilled(bool killed) {mIsTranslationProcessKilled = killed;}
  bool isTranslationProcessKilled() {return mIsTranslationProcessKilled;}
  bool isTranslationProcessRunning() {return mIsTranslationProcessRunning;}
  void updateMessageTab(const QString &text);
  void updateMessageTabProgress();
private:
  CRMLTranslatorOptions mCRMLTranslatorOptions;
  Label *mpProgressLabel;
  QProgressBar *mpProgressBar;
  QPushButton *mpCancelButton;
  QTabWidget *mpGeneratedFilesTabWidget;
  OutputPlainTextEdit *mpTranslationOutputTextBox;
  QProcess *mpTranslationProcess = nullptr;
  bool mIsTranslationProcessKilled = false;
  bool mIsTranslationProcessRunning = false;

  void translateModel();
  void writeTranslationOutput(QString output, QColor color);
  void translationProcessFinishedHelper();
private slots:
  void translationProcessStarted();
  void readTranslationStandardOutput();
  void readTranslationStandardError();
  void translationProcessError(QProcess::ProcessError error);
  void translationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
public slots:
  void cancelTranslation();
signals:
  void updateText(const QString &text);
  void updateProgressBar(QProgressBar *pProgressBar);
};

#endif // CRMLTRANSLATOROUTPUTWIDGET_H

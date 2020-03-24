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

#ifndef STACKFRAMESWIDGET_H
#define STACKFRAMESWIDGET_H

#include <QTreeWidget>
#include <QWidget>
#include <QComboBox>
#include <QToolButton>
#include <QStatusBar>

#include "Debugger/Parser/GDBMIParser.h"

using namespace GDBMIParser;
class StackFramesWidget;
class StackFramesTreeWidget;
class Label;

class StackFrameItem : public QTreeWidgetItem
{
public:
  StackFrameItem(QString level, QString address, QString function, QString line, QString file, QString fullName, StackFramesTreeWidget *pStackFramesTreeWidget);
  QString getLevel() {return mLevel;}
  QString getLine() {return mLine;}
  QString getFile() {return mFile;}
  QString getFullName() {return mFullName;}
  QString getFileName();
  void filterStackFrame();
private:
  StackFramesTreeWidget *mpStackFramesTreeWidget;
  QString mLevel;
  QString mAddress;
  QString mFunction;
  QString mLine;
  QString mFile;  /* file location. Often contains relative location. */
  QString mFullName;  /* full file location */

  QString cleanupFunction(const QString &function);
  QString cleanupFileName(const QString &fileName);
  char* omcHexToString(const char* str);
};

class StackFramesTreeWidget : public QTreeWidget
{
  Q_OBJECT
private:
  StackFramesWidget *mpStackFramesWidget;
  QAction *mpCreateFullBacktraceAction;
public:
  StackFramesTreeWidget(StackFramesWidget *pStackFramesWidget);
  StackFramesWidget* getStackFramesWidget();
  void clearStackFrames();
  void updateStackFrames();
  void setCurrentStackFrame(QTreeWidgetItem *pQTreeWidgetItem);
private:
  void createActions();
public slots:
  void createStackFrames(GDBMIValue *pGDBMIValue);
  void showContextMenu(QPoint point);
  void createFullBacktrace();
};

class StackFramesWidget : public QWidget
{
  Q_OBJECT
public:
  StackFramesWidget(QWidget *pParent = 0);
  QComboBox* getThreadsComboBox() {return mpThreadsComboBox;}
  StackFramesTreeWidget* getStackFramesTreeWidget() {return mpStackFramesTreeWidget;}
  void setSelectedThread(int thread) {mSelectedThread = thread;}
  int getSelectedThread() {return mSelectedThread;}
  void setSelectedFrame(int frame) {mSelectedFrame = frame;}
  int getSelectedFrame() {return mSelectedFrame;}
  void setStatusMessage(QString statusMessage);
private:
  QToolButton *mpResumeToolButton;
  QToolButton *mpInterruptToolButton;
  QToolButton *mpExitToolButton;
  QToolButton *mpStepIntoToolButton;
  QToolButton *mpStepOverToolButton;
  QToolButton *mpStepReturnToolButton;
  Label *mpThreadsLabel;
  QComboBox *mpThreadsComboBox;
  Label *mpStatusLabel;
  QStatusBar *mpStatusBar;
  StackFramesTreeWidget *mpStackFramesTreeWidget;
  int mSelectedThread;
  int mSelectedFrame;
public slots:
  void resumeButtonClicked();
  void interruptButtonClicked();
  void exitButtonClicked();
  void stepOverButtonClicked();
  void stepIntoButtonClicked();
  void stepReturnButtonClicked();
  void handleGDBProcessStarted();
  void handleGDBProcessFinished();
  void handleInferiorSuspended();
  void handleInferiorResumed();
  void threadChanged(int threadIndex);
  void fillThreadComboBox(GDBMIValue *pThreadsGDBMIValue, QString currentThreadId);
  void stackCurrentItemChanged(QTreeWidgetItem *pTreeWidgetItem);
};

#endif // STACKFRAMESWIDGET_H

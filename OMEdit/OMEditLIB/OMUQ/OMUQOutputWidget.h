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

#ifndef OMUQOUTPUTWIDGET_H
#define OMUQOUTPUTWIDGET_H

#include <QDockWidget>
#include <QJsonObject>
#include <QPointer>
#include <QProgressBar>
#include <QPushButton>
#include <QWidget>
#include <QProcess>

// The live view is shown inside OMEdit where QtWebEngine is available.
#if !defined(__EMSCRIPTEN__) && !defined(OM_OMEDIT_NO_WEBENGINE)
#define OMUQ_LIVE_VIEW_IN_OMEDIT
#endif

class Label;
class OutputPlainTextEdit;

/*!
 * \brief The options of one omuq activity run, see OMUQDialog.
 */
class OMUQRunOptions
{
public:
  enum LiveView {
    NoLiveView,
    LiveViewInOMEdit,
    LiveViewInBrowser
  };
  QString mPython;
  QString mPackage;      // the .ssp file omuq reads
  QString mModelName;
  int mStudy = 0;
  int mActivity = 0;
  QString mActivityLabel;
  QString mStopTime;     // empty means the activity's own grid
  QString mStepSize;
  int mReportEvery = 1;
  QString mDriver;
  QString mCsvFile;
  QString mResultsFile;  // empty means do not record the run
  LiveView mLiveView = NoLiveView;
};

class OMUQOutputWidget : public QWidget
{
  Q_OBJECT
public:
  OMUQOutputWidget(const OMUQRunOptions &options, QWidget *pParent = 0);
  ~OMUQOutputWidget();
  void start();
  bool isProcessRunning() const {return mIsProcessRunning;}
  void writeLiveViewConsoleMessage(const QString &message, bool error);
private:
  OMUQRunOptions mOptions;
  Label *mpProgressLabel;
  QProgressBar *mpProgressBar;
  QPushButton *mpCancelButton;
  OutputPlainTextEdit *mpOutputTextBox;
  // the live view window, like the Documentation Browser a dock that can float; closed by the user at any time
  QPointer<QDockWidget> mpLiveViewDockWidget;
  QProcess *mpProcess = nullptr;
  QByteArray mStandardOutputBuffer;
  bool mIsProcessRunning = false;
  bool mIsProcessKilled = false;
  bool mFinished = false;
  bool mIsModuleMissing = false;
  double mStartTime = 0;
  double mStopTime = 1;
  QString mCsvFile;
  QString mResultsFile;

  void writeOutput(const QString &output, const QColor &color);
  void setProgressText(const QString &text);
  void handleEvent(const QJsonObject &event);
  void showLiveView(const QString &url);
  void runFinished();
// Qt for WebAssembly has no QProcess, omuq cannot run there.
#if QT_CONFIG(process)
private slots:
  void processStarted();
  void readStandardOutput();
  void readStandardError();
  void processError(QProcess::ProcessError error);
  void processFinished(int exitCode, QProcess::ExitStatus exitStatus);
#endif
public slots:
  void cancel();
signals:
  void updateText(const QString &text);
  void updateProgressBar(QProgressBar *pProgressBar);
};

#endif // OMUQOUTPUTWIDGET_H

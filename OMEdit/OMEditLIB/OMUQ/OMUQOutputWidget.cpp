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

#include "OMUQOutputWidget.h"
#include "MainWindow.h"
#include "Modeling/MessagesWidget.h"
#include "Util/Helper.h"
#include "Util/OutputPlainTextEdit.h"
#include "Util/Utilities.h"

#include <QDesktopServices>
#include <QFileInfo>
#include <QGridLayout>
#include <QJsonArray>
#include <QJsonDocument>
#include <QUrl>
#ifdef OMUQ_LIVE_VIEW_IN_OMEDIT
#include <QWebEnginePage>
#include <QWebEngineView>

namespace {
/*!
 * \brief The live view's page.
 * QWebEnginePage writes the page's console messages to standard error, which OMEdit shows as errors
 * in the Messages Browser. Write the warnings and errors to the run's output instead, drop the rest.
 */
class OMUQLiveViewPage : public QWebEnginePage
{
public:
  OMUQLiveViewPage(OMUQOutputWidget *pOutputWidget, QObject *pParent)
    : QWebEnginePage(pParent), mpOutputWidget(pOutputWidget) {}
protected:
  void javaScriptConsoleMessage(JavaScriptConsoleMessageLevel level, const QString &message, int lineNumber, const QString &sourceID) override
  {
    Q_UNUSED(lineNumber);
    Q_UNUSED(sourceID);
    if (mpOutputWidget && level != QWebEnginePage::InfoMessageLevel) {
      mpOutputWidget->writeLiveViewConsoleMessage(message, level == QWebEnginePage::ErrorMessageLevel);
    }
  }
private:
  QPointer<OMUQOutputWidget> mpOutputWidget;
};
}
#endif

/*!
 * \class OMUQOutputWidget
 * \brief Runs one omuq activity as "python -m omuq run ... --json" and shows its progress.
 *
 * omuq prints one JSON event per line on standard output (start, sample, exit,
 * summary, artifacts, error) and its log on standard error.
 */
/*!
 * \brief OMUQOutputWidget::OMUQOutputWidget
 * \param options
 * \param pParent
 */
OMUQOutputWidget::OMUQOutputWidget(const OMUQRunOptions &options, QWidget *pParent)
  : QWidget(pParent), mOptions(options)
{
  mpProgressLabel = new Label;
  mpProgressLabel->setWordWrap(true);
  mpProgressLabel->setElideMode(Qt::ElideMiddle);
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setEnabled(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(cancel()));
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  mpProgressBar->setRange(0, 1000);
  mpProgressBar->setTextVisible(false);
  mpOutputTextBox = new OutputPlainTextEdit;
  mpOutputTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->addWidget(mpProgressLabel, 0, 0);
  pMainLayout->addWidget(mpProgressBar, 1, 0);
  pMainLayout->addWidget(mpCancelButton, 1, 1);
  pMainLayout->addWidget(mpOutputTextBox, 2, 0, 1, 2);
  setLayout(pMainLayout);
}

/*!
 * \brief OMUQOutputWidget::~OMUQOutputWidget
 */
OMUQOutputWidget::~OMUQOutputWidget()
{
#if QT_CONFIG(process)
  if (mpProcess && isProcessRunning()) {
    mpProcess->kill();
    mpProcess->waitForFinished(2000);
  }
#endif
}

/*!
 * \brief OMUQOutputWidget::start
 * Starts the omuq process.
 */
void OMUQOutputWidget::start()
{
#if QT_CONFIG(process)
  mpProcess = new QProcess(this);
  mpProcess->setWorkingDirectory(QFileInfo(mOptions.mPackage).absolutePath());
  connect(mpProcess, SIGNAL(started()), SLOT(processStarted()));
  connect(mpProcess, SIGNAL(readyReadStandardOutput()), SLOT(readStandardOutput()));
  connect(mpProcess, SIGNAL(readyReadStandardError()), SLOT(readStandardError()));
  connect(mpProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(processError(QProcess::ProcessError)));
  connect(mpProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(processFinished(int,QProcess::ExitStatus)));
  QStringList args = {"-m", "omuq", "run", mOptions.mPackage, "--json",
                      "--study", QString::number(mOptions.mStudy),
                      "--activity", QString::number(mOptions.mActivity),
                      "--driver", mOptions.mDriver,
                      "--every", QString::number(mOptions.mReportEvery),
                      "--csv", mOptions.mCsvFile};
  if (!mOptions.mStopTime.isEmpty()) {
    args << "--stop" << mOptions.mStopTime;
  }
  if (!mOptions.mStepSize.isEmpty()) {
    args << "--step" << mOptions.mStepSize;
  }
  if (!mOptions.mResultsFile.isEmpty()) {
    args << "--output" << mOptions.mResultsFile;
  }
  if (mOptions.mLiveView != OMUQRunOptions::NoLiveView) {
    args << "--ui";
  }
  // omuq's own log goes to standard error, keep it in step with the events
  QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
  environment.insert("PYTHONUNBUFFERED", "1");
  mpProcess->setProcessEnvironment(environment);
  writeOutput(QString("%1 %2\n").arg(mOptions.mPython, args.join(" ")), Qt::blue);
  setProgressText(tr("Starting omuq for %1.").arg(mOptions.mActivityLabel));
  mpProcess->start(mOptions.mPython, args);
#endif // QT_CONFIG(process)
}

/*!
 * \brief OMUQOutputWidget::writeOutput
 * Appends text to the output text box.
 * \param output
 * \param color
 */
void OMUQOutputWidget::writeOutput(const QString &output, const QColor &color)
{
  QTextCharFormat format;
  format.setForeground(color);
  mpOutputTextBox->appendOutput(output, format);
}

/*!
 * \brief OMUQOutputWidget::writeLiveViewConsoleMessage
 * Writes a console message of the live view's page to the output.
 * \param message
 * \param error
 */
void OMUQOutputWidget::writeLiveViewConsoleMessage(const QString &message, bool error)
{
  writeOutput(tr("Live view: %1\n").arg(message), error ? QColor(Qt::red) : QColor(Qt::darkGray));
}

/*!
 * \brief OMUQOutputWidget::setProgressText
 * Sets the progress label and updates the corresponding message tab.
 * \param text
 */
void OMUQOutputWidget::setProgressText(const QString &text)
{
  mpProgressLabel->setText(text);
  emit updateText(text);
  emit updateProgressBar(mpProgressBar);
}

/*!
 * \brief OMUQOutputWidget::handleEvent
 * Handles one JSON event printed by omuq.
 * \param event
 */
void OMUQOutputWidget::handleEvent(const QJsonObject &event)
{
  const QString name = event.value("event").toString();
  if (name == "start") {
    mStartTime = event.value("start").toDouble(0);
    mStopTime = event.value("stop").toDouble(1);
    QStringList domains;
    for (const QJsonValue &value : event.value("domains").toArray()) {
      const QJsonObject domain = value.toObject();
      if (domain.value("monitored").toBool()) {
        domains << domain.value("id").toString();
      } else {
        domains << tr("%1 (not monitored: %2)").arg(domain.value("id").toString(), domain.value("reason").toString());
      }
    }
    QStringList names;
    for (const QJsonValue &variable : event.value("names").toArray()) {
      names << variable.toString();
    }
    writeOutput(tr("Study %1, %2 from %3 to %4 with step %5, driver %6\n")
                .arg(event.value("study").toString(), mOptions.mActivityLabel)
                .arg(mStartTime).arg(mStopTime).arg(event.value("step").toDouble())
                .arg(event.value("driver").toString()), Qt::black);
    writeOutput(tr("Observed variables: %1\n").arg(names.join(", ")), Qt::black);
    writeOutput(tr("Monitored domains: %1\n").arg(domains.isEmpty() ? tr("none") : domains.join(", ")), Qt::black);
    const QString url = event.value("ui").toString();
    if (!url.isEmpty()) {
      writeOutput(tr("Live view: %1\n").arg(url), Qt::blue);
      showLiveView(url);
    }
    setProgressText(tr("Running %1 of %2.").arg(mOptions.mActivityLabel, mOptions.mModelName));
  } else if (name == "sample") {
    if (mStopTime > mStartTime) {
      const double fraction = (event.value("time").toDouble() - mStartTime) / (mStopTime - mStartTime);
      mpProgressBar->setValue(qBound(0, static_cast<int>(fraction * 1000), 1000));
      emit updateProgressBar(mpProgressBar);
    }
  } else if (name == "exit") {
    QStringList point;
    for (const QJsonValue &value : event.value("point").toArray()) {
      point << QString::number(value.toDouble());
    }
    writeOutput(tr("t = %1: left the domain %2 (%3) at (%4)\n")
                .arg(event.value("time").toDouble())
                .arg(event.value("domain").toString(), event.value("kind").toString(), point.join(", ")), Qt::red);
  } else if (name == "summary") {
    const bool ok = event.value("ok").toBool();
    writeOutput(event.value("text").toString() + "\n", ok ? QColor(0, 128, 0) : QColor(Qt::red));
  } else if (name == "artifacts") {
    mCsvFile = event.value("csv").toString();
    mResultsFile = event.value("results").toString();
    runFinished();
  } else if (name == "error") {
    writeOutput(event.value("message").toString() + "\n", Qt::red);
  }
}

/*!
 * \brief OMUQOutputWidget::showLiveView
 * Shows omuq's live view in a dock window of OMEdit or in the web browser.\n
 * The dock starts floating in a native window frame, so it can be moved to another screen.
 * \param url
 */
void OMUQOutputWidget::showLiveView(const QString &url)
{
#ifdef OMUQ_LIVE_VIEW_IN_OMEDIT
  if (mOptions.mLiveView == OMUQRunOptions::LiveViewInOMEdit) {
    static int liveViewNumber = 0;
    MainWindow *pMainWindow = MainWindow::instance();
    QWebEngineView *pLiveWebView = new QWebEngineView;
    pLiveWebView->setPage(new OMUQLiveViewPage(this, pLiveWebView));
    pLiveWebView->load(QUrl(url));
    mpLiveViewDockWidget = new QDockWidget(tr("%1 - %2 - Live View").arg(mOptions.mModelName, mOptions.mActivityLabel), pMainWindow);
    mpLiveViewDockWidget->setObjectName(QString("OMUQLiveView%1").arg(++liveViewNumber));
    mpLiveViewDockWidget->setAttribute(Qt::WA_DeleteOnClose);
    mpLiveViewDockWidget->setWidget(pLiveWebView);
    pMainWindow->addDockWidget(Qt::RightDockWidgetArea, mpLiveViewDockWidget);
    // A floating dock draws its own title bar and moves itself, which some window managers (e.g., WSLg) ignore.
    // Use a native window frame instead, so the window manager moves it, also to another screen.
    QDockWidget *pDockWidget = mpLiveViewDockWidget;
    connect(pDockWidget, &QDockWidget::topLevelChanged, pDockWidget, [pDockWidget](bool floating) {
      if (floating) {
        pDockWidget->setWindowFlags(Qt::Window | Qt::WindowTitleHint | Qt::WindowSystemMenuHint | Qt::WindowMinMaxButtonsHint | Qt::WindowCloseButtonHint);
        pDockWidget->show();
      }
    });
    mpLiveViewDockWidget->setFloating(true);
    mpLiveViewDockWidget->resize(1100, 750);
    mpLiveViewDockWidget->show();
    mpLiveViewDockWidget->raise();
    return;
  }
#endif
  QDesktopServices::openUrl(QUrl(url));
}

/*!
 * \brief OMUQOutputWidget::runFinished
 * Called when omuq reports its artifacts: loads the samples into the plotting view.\n
 * With the live view the process keeps serving it after this point.
 */
void OMUQOutputWidget::runFinished()
{
  mFinished = true;
  mpProgressBar->setValue(mpProgressBar->maximum());
  if (!mResultsFile.isEmpty()) {
    writeOutput(tr("The run is recorded in %1\n").arg(mResultsFile), Qt::blue);
  }
  if (!mCsvFile.isEmpty() && QFileInfo::exists(mCsvFile)) {
    MainWindow::instance()->openResultFile(mCsvFile);
    // loading the samples switches to the Plotting perspective, keep the live view in front
    if (mpLiveViewDockWidget) {
      mpLiveViewDockWidget->raise();
    }
  }
  if (mOptions.mLiveView != OMUQRunOptions::NoLiveView && mIsProcessRunning) {
    // omuq keeps serving the live view until it is stopped
    mpCancelButton->setText(tr("Stop Live View"));
    setProgressText(tr("%1 of %2 finished, the live view is still served.").arg(mOptions.mActivityLabel, mOptions.mModelName));
  } else {
    setProgressText(tr("%1 of %2 finished.").arg(mOptions.mActivityLabel, mOptions.mModelName));
  }
}

/*!
 * \brief OMUQOutputWidget::cancel
 * Kills the omuq process, either a running activity or the live view that outlives it.
 */
void OMUQOutputWidget::cancel()
{
#if QT_CONFIG(process)
  if (mpProcess && isProcessRunning()) {
    mIsProcessKilled = true;
    mpProcess->kill();
  }
#endif
  mpCancelButton->setEnabled(false);
  if (mFinished) {
    setProgressText(tr("%1 of %2 finished.").arg(mOptions.mActivityLabel, mOptions.mModelName));
  } else {
    mpProgressBar->setValue(0);
    setProgressText(tr("%1 of %2 is cancelled.").arg(mOptions.mActivityLabel, mOptions.mModelName));
  }
}

#if QT_CONFIG(process)
/*!
 * \brief OMUQOutputWidget::processStarted
 * Slot activated when the omuq process is started.
 */
void OMUQOutputWidget::processStarted()
{
  mIsProcessRunning = true;
  mpCancelButton->setEnabled(true);
}

/*!
 * \brief OMUQOutputWidget::readStandardOutput
 * Reads the JSON events, one per line.
 */
void OMUQOutputWidget::readStandardOutput()
{
  mStandardOutputBuffer.append(mpProcess->readAllStandardOutput());
  int newline;
  while ((newline = mStandardOutputBuffer.indexOf('\n')) >= 0) {
    const QByteArray line = mStandardOutputBuffer.left(newline).trimmed();
    mStandardOutputBuffer.remove(0, newline + 1);
    if (line.isEmpty()) {
      continue;
    }
    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(line, &parseError);
    if (parseError.error == QJsonParseError::NoError && document.isObject()) {
      handleEvent(document.object());
    } else {
      writeOutput(QString::fromUtf8(line) + "\n", Qt::black);
    }
  }
}

/*!
 * \brief OMUQOutputWidget::readStandardError
 * Shows omuq's log.
 */
void OMUQOutputWidget::readStandardError()
{
  const QString error = QString::fromUtf8(mpProcess->readAllStandardError());
  if (error.contains("No module named")) {
    mIsModuleMissing = true;
  }
  writeOutput(error, Qt::darkGray);
}

/*!
 * \brief OMUQOutputWidget::processError
 * \param error
 */
void OMUQOutputWidget::processError(QProcess::ProcessError error)
{
  /* this signal is also raised when the process is killed. */
  if (mIsProcessKilled) {
    return;
  }
  if (error == QProcess::FailedToStart) {
    mIsProcessRunning = false;
    writeOutput(tr("Failed to start %1: %2\nSet the Python executable that has omuq installed in "
                   "Tools > Options > OMSimulator/SSP.\n").arg(mOptions.mPython, mpProcess->errorString()), Qt::red);
    setProgressText(tr("%1 of %2 failed.").arg(mOptions.mActivityLabel, mOptions.mModelName));
  } else {
    writeOutput(mpProcess->errorString() + "\n", Qt::red);
  }
}

/*!
 * \brief OMUQOutputWidget::processFinished
 * \param exitCode
 * \param exitStatus
 */
void OMUQOutputWidget::processFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mIsProcessRunning = false;
  mpCancelButton->setEnabled(false);
  readStandardOutput();
  if (mFinished) {
    mpCancelButton->setText(Helper::cancel);
    setProgressText(tr("%1 of %2 finished.").arg(mOptions.mActivityLabel, mOptions.mModelName));
    return;
  } else if (mIsProcessKilled) {
    return;
  }
  QString message;
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    // omuq always reports its artifacts, a run without them did not complete
    message = tr("omuq finished without results for %1 of %2.").arg(mOptions.mActivityLabel, mOptions.mModelName);
  } else {
    message = tr("%1 of %2 failed. Exit code %3.").arg(mOptions.mActivityLabel, mOptions.mModelName, Utilities::formatExitCode(exitCode));
  }
  if (mIsModuleMissing) {
    message += " " + tr("Is omuq installed for %1?").arg(mOptions.mPython);
  }
  writeOutput(message + "\n", Qt::red);
  setProgressText(message);
}
#endif // QT_CONFIG(process)

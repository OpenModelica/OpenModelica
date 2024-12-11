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

#include "CRMLTranslatorOutputWidget.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ItemDelegate.h"
#include "Options/OptionsDialog.h"
#include "Util/OutputPlainTextEdit.h"
#include "Editors/TextEditor.h"

#include <QDesktopServices>
#include <QGridLayout>

/*!
 * \brief CRMLTranslatorOutputWidget::CRMLTranslatorOutputWidget
 * \param crmlTranslatorOptions
 * \param pParent
 */
CRMLTranslatorOutputWidget::CRMLTranslatorOutputWidget(CRMLTranslatorOptions crmlTranslatorOptions, QWidget *pParent)
  : QWidget(pParent), mCRMLTranslatorOptions(crmlTranslatorOptions)
{
  // progress label
  mpProgressLabel = new Label;
  mpProgressLabel->setWordWrap(true);
  mpProgressLabel->setElideMode(Qt::ElideMiddle);
  mpCancelButton = new QPushButton(tr("Cancel"));
  mpCancelButton->setEnabled(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(cancelTranslation()));
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  // Generated Files tab widget
  mpGeneratedFilesTabWidget = new QTabWidget;
  mpGeneratedFilesTabWidget->setDocumentMode(true);
  mpGeneratedFilesTabWidget->setMovable(true);
  // Translation Output TextBox
  mpTranslationOutputTextBox = new OutputPlainTextEdit;
  mpTranslationOutputTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  mpGeneratedFilesTabWidget->addTab(mpTranslationOutputTextBox, Helper::output);
  mpGeneratedFilesTabWidget->setTabEnabled(1, false);
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->addWidget(mpProgressLabel, 0, 0);
  pMainLayout->addWidget(mpProgressBar, 1, 0);
  pMainLayout->addWidget(mpCancelButton, 1, 1);
  pMainLayout->addWidget(mpGeneratedFilesTabWidget, 2, 0, 1, 2);
  setLayout(pMainLayout);
}

/*!
 * \brief CRMLTranslatorOutputWidget::~CRMLTranslatorOutputWidget
 */
CRMLTranslatorOutputWidget::~CRMLTranslatorOutputWidget()
{
  // translation process
  if (mpTranslationProcess && isTranslationProcessRunning()) {
    mpTranslationProcess->kill();
    mpTranslationProcess->deleteLater();
  }
}

/*!
 * \brief CRMLTranslatorOutputWidget::start
 * Starts the compilation/simulation.
 */
void CRMLTranslatorOutputWidget::start()
{
  translateModel();
}

/*!
 * \brief CRMLTranslatorOutputWidget::translateModel
 * Translates the CRML model.
 */
void CRMLTranslatorOutputWidget::translateModel()
{
  mpTranslationProcess = new QProcess;
  mpTranslationProcess->setWorkingDirectory(mCRMLTranslatorOptions.getWorkingDirectory());
  connect(mpTranslationProcess, SIGNAL(started()), SLOT(translationProcessStarted()));
  connect(mpTranslationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readTranslationStandardOutput()));
  connect(mpTranslationProcess, SIGNAL(readyReadStandardError()), SLOT(readTranslationStandardError()));
#if (QT_VERSION >= QT_VERSION_CHECK(5, 6, 0))
  connect(mpTranslationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(translationProcessError(QProcess::ProcessError)));
#else
  connect(mpTranslationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(translationProcessError(QProcess::ProcessError)));
#endif
  connect(mpTranslationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(translationProcessFinished(int,QProcess::ExitStatus)));
  QStringList args = {"-jar",
                      mCRMLTranslatorOptions.getCompilerJar(),
                      mCRMLTranslatorOptions.getCompilerCommandLineOptions()};
  // testsuite
  if (mCRMLTranslatorOptions.getMode().compare(QStringLiteral("testsuite")) == 0) {
    args << "--testsuite";
  } else if ((mCRMLTranslatorOptions.getMode().compare(QStringLiteral("translate")) == 0)
             || (mCRMLTranslatorOptions.getMode().compare(QStringLiteral("translateAs")) == 0)) {
    if (!mCRMLTranslatorOptions.getOutputDirectory().isEmpty()) {
      args << "-o";
      args << "\"" + mCRMLTranslatorOptions.getOutputDirectory() + "\"";
    }

    if (!mCRMLTranslatorOptions.getModelicaWithin().isEmpty()) {
      args << "--within";
      args << mCRMLTranslatorOptions.getModelicaWithin();
    }

    args << "\"" + mCRMLTranslatorOptions.getCRMLFile() + "\"";
  } else {
    qDebug() << "Unknown CRML mode type.";
  }
  args.removeAll(QString(""));
  writeTranslationOutput(QString("%1 %2\n").arg(mCRMLTranslatorOptions.getCompilerProcess()).arg(args.join(" ")), Qt::blue);
  mpTranslationProcess->start(mCRMLTranslatorOptions.getCompilerProcess(), args);
}

/*!
 * \brief CRMLTranslatorOutputWidget::updateMessageTab
 * Updates the corresponding MessageTab.
 */
void CRMLTranslatorOutputWidget::updateMessageTab(const QString &text)
{
  emit updateText(text);
  emit updateProgressBar(mpProgressBar);
}

/*!
 * \brief CRMLTranslatorOutputWidget::updateMessageTabProgress
 * Updates the progress bar of MessageTab
 */
void CRMLTranslatorOutputWidget::updateMessageTabProgress()
{
  emit updateProgressBar(mpProgressBar);
}

/*!
 * \brief CRMLTranslatorOutputWidget::writeTranslationOutput
 * Writes the compilation standard output to the compilation output text box.
 * \param output
 * \param color
 */
void CRMLTranslatorOutputWidget::writeTranslationOutput(QString output, QColor color)
{
  QTextCharFormat format;
  format.setForeground(color);
  mpTranslationOutputTextBox->appendOutput(output, format);
}

/*!
 * \brief CRMLTranslatorOutputWidget::translationProcessFinishedHelper
 * Helper function for CRMLTranslatorOutputWidget::translationProcessFinished\n
 * Writes the output after the translation process is finished.
 */
void CRMLTranslatorOutputWidget::translationProcessFinishedHelper()
{
  LibraryWidget *pLibraryWidget = MainWindow::instance()->getLibraryWidget();
  mpProgressBar->setValue(1);
  if (mCRMLTranslatorOptions.getMode().compare(QStringLiteral("testsuite")) == 0) {
    // here we need to find out the html file and open it in the QtBrowser
    QString file = mCRMLTranslatorOptions.getWorkingDirectory() + QDir::separator() + "build" + QDir::separator() + "test_report.html";
    QFileInfo fi(file);
    if (fi.exists()) {
      QUrl testsuiteUrl = QUrl::fromLocalFile(file);
      if (!QDesktopServices::openUrl(testsuiteUrl)) {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(testsuiteUrl.toString()),
                                                              Helper::scriptingKind, Helper::errorLevel));
      }
    } else {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(file),
                                                            Helper::scriptingKind, Helper::errorLevel));
    }
    mpProgressBar->setValue(2);
  } else if ((mCRMLTranslatorOptions.getMode().compare(QStringLiteral("translate")) == 0)
             || (mCRMLTranslatorOptions.getMode().compare(QStringLiteral("translateAs")) == 0)) {
    QStringList paths = mCRMLTranslatorOptions.getModelicaLibraries();
    foreach (QString path, paths) {
      path = path.replace("\\", "/");
      if (QFile::exists(path)) {
        // do not load it again if it exists already
        if (!pLibraryWidget->getLibraryTreeModel()->getLibraryTreeItemFromFile(path, 1)) {
          pLibraryWidget->openFile(path, Helper::utf8, false, true);
        }
      }
    }

    QString outputDirectory;
    if (mCRMLTranslatorOptions.getOutputDirectory().isEmpty()) {
      outputDirectory = mCRMLTranslatorOptions.getWorkingDirectory() + QDir::separator() + "generated";
    } else {
      outputDirectory = mCRMLTranslatorOptions.getOutputDirectory();
    }

    QFileInfo fi = QFileInfo(mCRMLTranslatorOptions.getCRMLFile());
    QString fileName = outputDirectory + QDir::separator() +  fi.baseName() + QDir::separator() + fi.baseName() + ".mo";
    fileName = fileName.replace("\\", "/");
    pLibraryWidget->openFile(fileName, Helper::utf8, false, true);
    // now open it if we can find it in the tree!
    LibraryTreeItem *pMOLibraryTreeItem = pLibraryWidget->getLibraryTreeModel()->getLibraryTreeItemFromFile(fileName, 1);
    if (pMOLibraryTreeItem) {
      pLibraryWidget->getLibraryTreeModel()->showModelWidget(pMOLibraryTreeItem);
    }
    mpProgressBar->setValue(2);
  } else {
    qDebug() << "Unknown CRML mode type.";
  }
}

/*!
 * \brief CRMLTranslatorOutputWidget::cancelTranslation
 * Slot activated when mpCancelButton clicked signal is raised.\n
 * Cancels a running compilaiton/simulation by killing the compilation/simulation process.
 */
void CRMLTranslatorOutputWidget::cancelTranslation()
{
  QString progressStr;
  QString msg = tr("Translation of the CRML file %1 is cancelled.").arg(mCRMLTranslatorOptions.getCRMLFile());
  if (isTranslationProcessRunning()) {
    setTranslationProcessKilled(true);
    mpTranslationProcess->kill();
    mIsTranslationProcessRunning = false;
    if (mCRMLTranslatorOptions.getMode().compare(QStringLiteral("testsuite")) == 0) {
      progressStr = tr("Testsuite run in directory %1 is cancelled.").arg(mCRMLTranslatorOptions.getWorkingDirectory());
    } else if (mCRMLTranslatorOptions.getMode().compare(QStringLiteral("translate")) == 0) {
      progressStr = msg;
    } else if (mCRMLTranslatorOptions.getMode().compare(QStringLiteral("translateAs")) == 0) {
      if (!mCRMLTranslatorOptions.getOutputDirectory().isEmpty() && !mCRMLTranslatorOptions.getModelicaWithin().isEmpty()) {
        progressStr = tr("Translation of the CRML file %1 with output directory %2 and within %3 is cancelled.").
                      arg(mCRMLTranslatorOptions.getCRMLFile(), mCRMLTranslatorOptions.getOutputDirectory(), mCRMLTranslatorOptions.getModelicaWithin());
      } else if (!mCRMLTranslatorOptions.getOutputDirectory().isEmpty() && mCRMLTranslatorOptions.getModelicaWithin().isEmpty()) {
        progressStr = tr("Translation of the CRML file %1 with output directory %2 is cancelled.").
                      arg(mCRMLTranslatorOptions.getCRMLFile(), mCRMLTranslatorOptions.getOutputDirectory());
      } else if (mCRMLTranslatorOptions.getOutputDirectory().isEmpty() && !mCRMLTranslatorOptions.getModelicaWithin().isEmpty()) {
        progressStr = tr("Translation of the CRML file %1 with within %2 is cancelled.").
                      arg(mCRMLTranslatorOptions.getCRMLFile(), mCRMLTranslatorOptions.getModelicaWithin());
      } else {
        progressStr = msg;
      }
    } else {
      qDebug() << "Unknown CRML mode type.";
    }
    mpProgressBar->setRange(0, 2);
    mpProgressBar->setValue(0);
    mpCancelButton->setEnabled(false);
  }
  mpProgressLabel->setText(progressStr);
  updateMessageTab(progressStr);
}

/*!
 * \brief CRMLTranslatorOutputWidget::translationProcessStarted
 * Slot activated when mpTranslationProcess started signal is raised.\n
 * Updates the progress label, bar and button controls.
 */
void CRMLTranslatorOutputWidget::translationProcessStarted()
{
  mIsTranslationProcessRunning = true;
  const QString progressStr = tr("CRML translator is running. Please wait for a while.");
  mpProgressLabel->setText(progressStr);
  mpProgressBar->setRange(0, 2);
  mpProgressBar->setTextVisible(false);
  updateMessageTab(progressStr);
  mpCancelButton->setText(Helper::cancel);
  mpCancelButton->setEnabled(true);
}

/*!
 * \brief CRMLTranslatorOutputWidget::readTranslationStandardOutput
 * Slot activated when mpTranslationProcess readyReadStandardOutput signal is raised.\n
 */
void CRMLTranslatorOutputWidget::readTranslationStandardOutput()
{
  writeTranslationOutput(QString(mpTranslationProcess->readAllStandardOutput()), Qt::black);
}

/*!
 * \brief CRMLTranslatorOutputWidget::readTranslationStandardError
 * Slot activated when mpTranslationProcess readyReadStandardError signal is raised.\n
 */
void CRMLTranslatorOutputWidget::readTranslationStandardError()
{
  writeTranslationOutput(QString(mpTranslationProcess->readAllStandardError()), Qt::red);
}

/*!
 * \brief CRMLTranslatorOutputWidget::translationProcessError
 * Slot activated when mpTranslationProcess errorOccurred signal is raised.\n
 * \param error
 */
void CRMLTranslatorOutputWidget::translationProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  mIsTranslationProcessRunning = false;
  /* this signal is raised when we kill the compilation process forcefully. */
  if (isTranslationProcessKilled()) {
    return;
  }
  writeTranslationOutput(mpTranslationProcess->errorString(), Qt::red);
}

/*!
 * \brief CRMLTranslatorOutputWidget::translationProcessFinished
 * Slot activated when mpTranslationProcess finished signal is raised.\n
 * \param exitCode
 * \param exitStatus
 */
void CRMLTranslatorOutputWidget::translationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mIsTranslationProcessRunning = false;
  mpCancelButton->setEnabled(false);

  QString messageFailed;
  QString msgFailed = tr("Translation of the CRML file %1 failed. Exit code %2").arg(mCRMLTranslatorOptions.getCRMLFile(), Utilities::formatExitCode(exitCode));
  QString messageSuccess;
  QString msgSuccess = tr("Translation of CRML file %1 finished. Now loading specified CRML Modelica libraries...").arg(mCRMLTranslatorOptions.getCRMLFile());
  if (mCRMLTranslatorOptions.getMode().compare(QStringLiteral("testsuite")) == 0) {
    messageFailed = tr("Testsuite run in directory %1 failed. Exit code %2.").arg(mCRMLTranslatorOptions.getWorkingDirectory(), Utilities::formatExitCode(exitCode));
    messageSuccess = tr("Testsuite run in directory %1 finished.").arg(mCRMLTranslatorOptions.getWorkingDirectory());
  } else if (mCRMLTranslatorOptions.getMode().compare(QStringLiteral("translate")) == 0) {
    messageFailed = msgFailed;
    messageSuccess = msgSuccess;
  } else if (mCRMLTranslatorOptions.getMode().compare(QStringLiteral("translateAs")) == 0) {
    if (!mCRMLTranslatorOptions.getOutputDirectory().isEmpty() && !mCRMLTranslatorOptions.getModelicaWithin().isEmpty()) {
      messageFailed = tr("Translation of the CRML file %1 with output directory %2 and within %3 failed. Exit code %4.").
                      arg(mCRMLTranslatorOptions.getCRMLFile(), mCRMLTranslatorOptions.getOutputDirectory(), mCRMLTranslatorOptions.getModelicaWithin(),
                          Utilities::formatExitCode(exitCode));
      messageSuccess = tr("Translation of CRML file %1 with output directory %2 and within %3 finished. Now loading specified CRML Modelica libraries...").
                       arg(mCRMLTranslatorOptions.getCRMLFile(), mCRMLTranslatorOptions.getOutputDirectory(), mCRMLTranslatorOptions.getModelicaWithin());
    } else if (!mCRMLTranslatorOptions.getOutputDirectory().isEmpty() && mCRMLTranslatorOptions.getModelicaWithin().isEmpty()) {
      messageFailed = tr("Translation of the CRML file %1 with output directory %2 failed. Exit code %3.").
                      arg(mCRMLTranslatorOptions.getCRMLFile(), mCRMLTranslatorOptions.getOutputDirectory(), Utilities::formatExitCode(exitCode));
      messageSuccess = tr("Translation of CRML file %1 with output directory %2 finished. Now loading specified CRML Modelica libraries...").
                       arg(mCRMLTranslatorOptions.getCRMLFile(), mCRMLTranslatorOptions.getOutputDirectory());
    } else if (mCRMLTranslatorOptions.getOutputDirectory().isEmpty() && !mCRMLTranslatorOptions.getModelicaWithin().isEmpty()) {
      messageFailed = tr("Translation of the CRML file %1 with within %2 failed. Exit code %3.").
                      arg(mCRMLTranslatorOptions.getCRMLFile(), mCRMLTranslatorOptions.getModelicaWithin(), Utilities::formatExitCode(exitCode));
      messageSuccess = tr("Translation of CRML file %1 with within %2 finished. Now loading specified CRML Modelica libraries...").
                       arg(mCRMLTranslatorOptions.getCRMLFile(), mCRMLTranslatorOptions.getModelicaWithin());
    } else {
      messageFailed = msgFailed;
      messageSuccess = msgSuccess;
    }
  } else {
    qDebug() << "Unknown CRML mode type.";
  }

  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    writeTranslationOutput(messageSuccess, Qt::blue);
    translationProcessFinishedHelper();
    mpProgressLabel->setText(messageSuccess);
    updateMessageTab(messageSuccess);
  } else if (mpTranslationProcess->error() == QProcess::UnknownError) {
    writeTranslationOutput(messageFailed, Qt::red);
    mpProgressLabel->setText(messageFailed);
    updateMessageTab(messageFailed);
  } else {
    writeTranslationOutput(mpTranslationProcess->errorString() + "\n" + messageFailed, Qt::red);
    mpProgressLabel->setText(messageFailed);
    updateMessageTab(messageFailed);
  }
}

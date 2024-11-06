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

#include "FMUExportOutputWidget.h"
#include "MainWindow.h"
#include "Modeling/ItemDelegate.h"
#include "Options/OptionsDialog.h"
#include "Util/OutputPlainTextEdit.h"
#include "Editors/CEditor.h"
#include "Editors/TextEditor.h"
#include "Git/CommitChangesDialog.h"
#include "meta/meta_modelica_builtin.h"
#include <QApplication>
#include <QObject>
#include <QHeaderView>
#include <QAction>
#include <QMenu>
#include <QMessageBox>
#include <QTextDocumentFragment>
#include <QGridLayout>
#include <QRegularExpression>

FmuExportOutputWidget::FmuExportOutputWidget(LibraryTreeItem* pLibraryTreeItem, QWidget *pParent)
  : QWidget(pParent)
{
  mTargetLanguage = OptionsDialog::instance()->getSimulationPage()->getTargetLanguageComboBox()->currentText();
  mpLibraryTreeItem = pLibraryTreeItem;

  // set the FMU name
  const QString fmuNameText = OptionsDialog::instance()->getFMIPage()->getFMUNameTextBox()->text();
  mFMUName = fmuNameText.isEmpty() ? mpLibraryTreeItem->getName() : fmuNameText;

  /*
   * set the fmuTmpPath
   * fix issue https://github.com/OpenModelica/OpenModelica/issues/12916,
   * use hashed string for fmu tmp directory
  */
  if (mTargetLanguage.compare("C") == 0) {
    QString hashedString = QString::number(stringHashDjb2(mmc_mk_scon(mFMUName.toUtf8().constData())));
    mFmuTmpPath = QDir::currentPath().append("/").append(hashedString.left(3)+".fmutmp");
  } else {
    mFmuTmpPath = QDir::currentPath();
  }

  // progress label
  mpProgressLabel = new Label;
  mpProgressLabel->setElideMode(Qt::ElideMiddle);
  mpCancelButton = new QPushButton(tr("Cancel Compilation"));
  mpCancelButton->setEnabled(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(cancelCompilation()));

  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  // Generated Files tab widget
  mpGeneratedFilesTabWidget = new QTabWidget;
  mpGeneratedFilesTabWidget->setDocumentMode(true);
  mpGeneratedFilesTabWidget->setMovable(true);

  // Compilation Output TextBox
  mpCompilationOutputTextBox = new OutputPlainTextEdit;
  mpCompilationOutputTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  mpGeneratedFilesTabWidget->addTab(mpCompilationOutputTextBox, tr("Configure"));

  mpPostCompilationOutputTextBox = new OutputPlainTextEdit;
  mpPostCompilationOutputTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  mpGeneratedFilesTabWidget->addTab(mpPostCompilationOutputTextBox, tr("Build"));
  mpGeneratedFilesTabWidget->setTabEnabled(1, false);

  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->addWidget(mpProgressLabel, 0, 0);
  pMainLayout->addWidget(mpProgressBar, 0, 1);
  pMainLayout->addWidget(mpCancelButton, 0, 2);
  pMainLayout->addWidget(mpGeneratedFilesTabWidget, 1, 0, 1, 5);
  setLayout(pMainLayout);

  mpCompilationProcess = 0;
  setCompilationProcessKilled(false);
  mIsCompilationProcessRunning = false;
  mpPostCompilationProcess = 0;
  setPostCompilationProcessKilled(false);
  mIsPostCompilationProcessRunning = false;
  mpZipCompilationProcess = 0;
  setZipCompilationProcessKilled(false);
  mIsZipCompilationProcessRunning = false;
}

/*!
 * \brief FmuExportOutputWidget::~FmuExportOutputWidget
 */
FmuExportOutputWidget::~FmuExportOutputWidget()
{
  // compilation process
  if (mpCompilationProcess && isCompilationProcessRunning()) {
    mpCompilationProcess->kill();
    mpCompilationProcess->deleteLater();
  }
  // post compilation process
  if (mpPostCompilationProcess && isPostCompilationProcessRunning()) {
    mpPostCompilationProcess->kill();
    mpPostCompilationProcess->deleteLater();
  }
  // Zip compilation process
  if (mpZipCompilationProcess && isZipCompilationProcessRunning()) {
    mpZipCompilationProcess->kill();
    mpZipCompilationProcess->deleteLater();
  }
}

/*!
 * \brief FmuExportOutputWidget::cancelCompilation
 * Slot activated when mpCancelButton clicked signal is raised.\n
 * Cancels a running compilaiton by killing the fmu export process.
 */
void FmuExportOutputWidget::cancelCompilation()
{
  QString progressStr;
  if (isCompilationProcessRunning()) {
    setCompilationProcessKilled(true);
    mpCompilationProcess->kill();
    mIsCompilationProcessRunning = false;
    progressStr = tr("Generating cmake target files of %1 is cancelled.").arg(mpLibraryTreeItem->getName());
    mpProgressBar->setRange(0, 1);
    mpProgressBar->setValue(0);
    mpCancelButton->setEnabled(false);
  } else if (isPostCompilationProcessRunning()) {
    setPostCompilationProcessKilled(true);
    mpPostCompilationProcess->kill();
    mIsPostCompilationProcessRunning = false;
    progressStr = tr("Building of %1 is cancelled.").arg(mpLibraryTreeItem->getName());
    mpCancelButton->setEnabled(false);
  } else if (isZipCompilationProcessRunning()) {
    setZipCompilationProcessKilled(true);
    mpZipCompilationProcess->kill();
    mIsZipCompilationProcessRunning = false;
    progressStr = tr("Zipping of FMU %1 is cancelled.").arg(mpLibraryTreeItem->getName());
    mpProgressBar->setRange(0, 1);
    mpProgressBar->setValue(0);
    mpCancelButton->setEnabled(false);
  }
  mpProgressLabel->setText(progressStr);
  updateMessageTab(progressStr);
}

/*!
 * \brief FmuExportOutputWidget::updateMessageTab
 * Updates the corresponsing MessageTab.
 */
void FmuExportOutputWidget::updateMessageTab(const QString &text)
{
  emit updateText(text);
  emit updateProgressBar(mpProgressBar);
}

/*!
 * \brief FmuExportOutputWidget::compileModel
 * generates cmake target files for the compiled model
 */
void FmuExportOutputWidget::compileModelCRuntime()
{
  mpCompilationProcess = new QProcess;
  connect(mpCompilationProcess, SIGNAL(started()), SLOT(compilationProcessStarted()));
  connect(mpCompilationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readCompilationStandardOutput()));
  connect(mpCompilationProcess, SIGNAL(readyReadStandardError()), SLOT(readCompilationStandardError()));
#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
  connect(mpCompilationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(compilationProcessError(QProcess::ProcessError)));
#else
  connect(mpCompilationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(compilationProcessError(QProcess::ProcessError)));
#endif
  connect(mpCompilationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(compilationProcessFinished(int,QProcess::ExitStatus)));

  QString cmakeBuildPath = QString("%1%2").arg(mFmuTmpPath, "/sources/build_cmake");
  if (!QDir().exists(cmakeBuildPath)) {
    QDir().mkpath(cmakeBuildPath);
  }

  // set the current directory to cmakebuild directory
  MainWindow::instance()->getOMCProxy()->changeDirectory(cmakeBuildPath);

  QString program = "cmake";
  QStringList arguments;

  QString CMAKE_BUILD_TYPE;
  // Set build type
  QString fmiFilter = OptionsDialog::instance()->getFMIPage()->getModelDescriptionFiltersComboBox()->currentText();
  if (fmiFilter.compare("blackBox")==0  || fmiFilter.compare("protected")==0) {
    CMAKE_BUILD_TYPE = "-DCMAKE_BUILD_TYPE=Release";
  } else if (OptionsDialog::instance()->getFMIPage()->getGenerateDebugSymbolsCheckBox()->isChecked()) {
    CMAKE_BUILD_TYPE = "-DCMAKE_BUILD_TYPE=Debug";
  } else {
    CMAKE_BUILD_TYPE = "-DCMAKE_BUILD_TYPE=RelWithDebInfo";
  }

#ifdef Q_OS_WIN
  arguments << "-G" << "MSYS Makefiles" << CMAKE_BUILD_TYPE << "-DCMAKE_C_COMPILER=clang" << "-DCMAKE_COLOR_MAKEFILE=OFF" << "..";
#else
  arguments << CMAKE_BUILD_TYPE << "-DCMAKE_C_COMPILER=clang" << "-DCMAKE_COLOR_MAKEFILE=OFF" << "..";
#endif

  writeCompilationOutput(QString("%1 %2\n").arg(program, arguments.join(" ")), Qt::blue);
  mpCompilationProcess->start(program, arguments);
}

/*!
 * \brief FmuExportOutputWidget::writeCompilationOutput
 * Writes the compilation standard output to the compilation output text box.
 * \param output
 * \param color
 */
void FmuExportOutputWidget::writeCompilationOutput(QString output, QColor color)
{
  QTextCharFormat format;
  format.setForeground(color);
  mpCompilationOutputTextBox->appendOutput(output, format);
}

/*!
 * \brief FmuExportOutputWidget::writeCompilationOutput
 * Writes the compilation standard output to the compilation output text box.
 * \param output
 * \param color
 */
void FmuExportOutputWidget::writePostCompilationOutput(QString output, QColor color)
{
  QTextCharFormat format;
  format.setForeground(color);
  mpPostCompilationOutputTextBox->appendOutput(output, format);
}

/*!
 * \brief FmuExportOutputWidget::readCompilationStandardOutput
 * Slot activated when mpCompilationProcess readyReadStandardOutput signal is raised.\n
 */
void FmuExportOutputWidget::readCompilationStandardOutput()
{
  writeCompilationOutput(QString(mpCompilationProcess->readAllStandardOutput()), Qt::black);
}

/*!
 * \brief FmuExportOutputWidget::readCompilationStandardError
 * Slot activated when mpCompilationProcess readyReadStandardError signal is raised.\n
 */
void FmuExportOutputWidget::readCompilationStandardError()
{
  writeCompilationOutput(QString(mpCompilationProcess->readAllStandardError()), Qt::red);
}

/*!
 * \brief FmuExportOutputWidget::compilationProcessStarted
* Slot activated when mpCompilationProcess started signal is raised.\n
 * Updates the progress label, bar and button controls.
 */
void FmuExportOutputWidget::compilationProcessStarted()
{
  mIsCompilationProcessRunning = true;
  const QString progressStr = tr("Generating cmake target files of %1. Please wait for a while.").arg(mpLibraryTreeItem->getName());
  mpProgressLabel->setText(progressStr);
  mpProgressBar->setRange(0, 1);
  mpProgressBar->setTextVisible(false);
  updateMessageTab(progressStr);
  mpCancelButton->setText(tr("Cancel Compilation"));
  mpCancelButton->setEnabled(true);
}

/*!
 * \brief FmuExportOutputWidget::compilationProcessFinished
 * Slot activated when mpCompilationProcess finished signal is raised.\n
 * If the mpCompilationProcess finished normally then run the cmake build.\n
 * \param exitCode
 * \param exitStatus
 */
void FmuExportOutputWidget::compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mIsCompilationProcessRunning = false;
  QString exitCodeStr = tr("Generated cmake target files failed. Exited with code %1.").arg(Utilities::formatExitCode(exitCode));
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    writeCompilationOutput(tr("Generated cmake target files successfully.\n"), Qt::blue);
    compilationProcessFinishedHelper(exitCode, exitStatus);
    runPostCompilation();
  } else if (mpCompilationProcess->error() == QProcess::UnknownError) {
    writeCompilationOutput(exitCodeStr, Qt::red);
    compilationProcessFinishedHelper(exitCode, exitStatus);
  } else {
    writeCompilationOutput(mpCompilationProcess->errorString() + "\n" + exitCodeStr, Qt::red);
    compilationProcessFinishedHelper(exitCode, exitStatus);
  }
}

/*!
 * \brief FmuExportOutputWidget::compilationProcessFinishedHelper
 * Slot activated when mpCompilationProcess finished signal is raised.\n
 * \param exitCode
 * \param exitStatus
 */
void FmuExportOutputWidget::compilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus)
{
  QString progressStr;
  mpProgressBar->setRange(0, 1);
  mpCancelButton->setEnabled(false);
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    mpProgressBar->setValue(1);
    progressStr = tr("Generating cmake target files of %1 finished.").arg(mpLibraryTreeItem->getName());
  } else {
    mpProgressBar->setValue(0);
    progressStr = tr("Generating cmake target files of %1 failed.").arg(mpLibraryTreeItem->getName());
  }
  mpProgressLabel->setText(progressStr);
  updateMessageTab(progressStr);
}

/*!
 * \brief FmuExportOutputWidget::compilationProcessError
 * Slot activated when mpCompilationProcess errorOccurred signal is raised.\n
 * \param error
 */
void FmuExportOutputWidget::compilationProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  mIsCompilationProcessRunning = false;
  /* this signal is raised when we kill the compilation process forcefully. */
  if (isCompilationProcessKilled()) {
    return;
  }
  writeCompilationOutput(mpCompilationProcess->errorString(), Qt::red);
}

/*!
 * \brief FmuExportOutputWidget::runPostCompilation
 * Runs the post compilation command after the compilation of the model.
 */
void FmuExportOutputWidget::runPostCompilation()
{
  mpPostCompilationProcess = new QProcess;
  connect(mpPostCompilationProcess, SIGNAL(started()), SLOT(postCompilationProcessStarted()));
  connect(mpPostCompilationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readPostCompilationStandardOutput()));
  connect(mpPostCompilationProcess, SIGNAL(readyReadStandardError()), SLOT(readPostCompilationStandardError()));
#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
  connect(mpPostCompilationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(postCompilationProcessError(QProcess::ProcessError)));
#else
  connect(mpPostCompilationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(postCompilationProcessError(QProcess::ProcessError)));
#endif
  connect(mpPostCompilationProcess, SIGNAL(finished(int, QProcess::ExitStatus)), SLOT(postCompilationProcessFinished(int, QProcess::ExitStatus)));

  QString program = "cmake";
  QStringList arguments;
  arguments  << "--build" << "."
             << "--parallel"
             << "--target" << "install";

  writePostCompilationOutput(QString("%1 %2\n").arg(program, arguments.join(" ")), Qt::blue);
  mpPostCompilationProcess->start(program, arguments);
  mpGeneratedFilesTabWidget->setTabEnabled(1, true);
  mpGeneratedFilesTabWidget->setCurrentIndex(1);
}

/*!
 * \brief FmuExportOutputWidget::compileModelCppRuntime
 * Runs the post compilation command after the compilation of the model.
 */
void FmuExportOutputWidget::compileModelCppRuntime()
{
  mpPostCompilationProcess = new QProcess;
  connect(mpPostCompilationProcess, SIGNAL(started()), SLOT(postCompilationProcessStarted()));
  connect(mpPostCompilationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readPostCompilationStandardOutput()));
  connect(mpPostCompilationProcess, SIGNAL(readyReadStandardError()), SLOT(readPostCompilationStandardError()));
#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
  connect(mpPostCompilationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(postCompilationProcessError(QProcess::ProcessError)));
#else
  connect(mpPostCompilationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(postCompilationProcessError(QProcess::ProcessError)));
#endif
  connect(mpPostCompilationProcess, SIGNAL(finished(int, QProcess::ExitStatus)), SLOT(postCompilationProcessFinished(int, QProcess::ExitStatus)));

  // set the current directory to makefile directory
  MainWindow::instance()->getOMCProxy()->changeDirectory(mFmuTmpPath);

  QString program = "make";
  QStringList arguments;
  arguments << "-f" << mFMUName + "_FMU.makefile" << "ZIP_FMU=OFF";

  writePostCompilationOutput(QString("%1 %2\n").arg(program, arguments.join(" ")), Qt::blue);
  mpPostCompilationProcess->start(program, arguments);
  mpGeneratedFilesTabWidget->setTabEnabled(1, true);
  mpGeneratedFilesTabWidget->setTabEnabled(0, false);
  mpGeneratedFilesTabWidget->setCurrentIndex(1);
}

/*!
 * \brief FmuExportOutputWidget::postCompilationProcessStarted
* Slot activated when mpPostCompilationProcess started signal is raised.\n
 * Updates the progress label, bar and button controls.
 */
void FmuExportOutputWidget::postCompilationProcessStarted()
{
  mIsPostCompilationProcessRunning = true;
  const QString progressStr = tr("Building %1").arg(mpLibraryTreeItem->getName());
  mpProgressLabel->setText(progressStr);
  mpProgressBar->setTextVisible(true);
  if (mTargetLanguage.compare("C")==0) {
    mpProgressBar->setMaximum(100);
  } else {
    mpProgressBar->setRange(0, 0);
  }
  updateMessageTab(progressStr);
  mpCancelButton->setText(tr("Cancel Compilation"));
  mpCancelButton->setEnabled(true);
}

/*!
 * \brief FmuExportOutputWidget::readPostCompilationStandardOutput
 * Slot activated when mpPostCompilationProcess readyReadStandardOutput signal is raised.\n
 */
void FmuExportOutputWidget::readPostCompilationStandardOutput()
{
  QString output = mpPostCompilationProcess->readAllStandardOutput();

  if (mTargetLanguage.compare("C")==0) {
    // Regular expression to capture progress percentage (e.g., "[ 12%]")
    QRegularExpression regex("\\[\\s*(\\d+)%\\]");
    QRegularExpressionMatch match = regex.match(output);
    if (match.hasMatch()) {
      int currentStep = match.captured(1).toInt();
      // Update the progress bar
      mpProgressBar->setValue(currentStep);
    }
  }
  writePostCompilationOutput(output, Qt::black);
}

/*!
 * \brief FmuExportOutputWidget::readPostCompilationStandardError
 * Slot activated when mpPostCompilationProcess readyReadStandardError signal is raised.\n
 */
void FmuExportOutputWidget::readPostCompilationStandardError()
{
  writePostCompilationOutput(QString(mpPostCompilationProcess->readAllStandardError()), Qt::red);
}

/*!
 * \brief FmuExportOutputWidget::postCompilationProcessError
 * Slot activated when mpPostCompilationProcess errorOccurred signal is raised.\n
 * \param error
 */
void FmuExportOutputWidget::postCompilationProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  mIsPostCompilationProcessRunning = false;
  /* this signal is raised when we kill the compilation process forcefully. */
  if (isPostCompilationProcessKilled()) {
   return;
  }
  writePostCompilationOutput(mpPostCompilationProcess->errorString(), Qt::red);
}

/*!
 * \brief FmuExportOutputWidget::postCompilationProcessFinished
 * Slot activated when mpPostCompilationProcess finished signal is raised.\n
 * If the mpPostCompilationProcess finished normally then run the zipFMU() to export the FMU.\n
 * \param exitCode
 * \param exitStatus
 */
void FmuExportOutputWidget::postCompilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mIsPostCompilationProcessRunning = false;
  QString exitCodeStr = tr("Post compilation process failed. Exited with code %1.").arg(Utilities::formatExitCode(exitCode));
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    writePostCompilationOutput(tr("Build finished successfully.\n"), Qt::blue);
    postCompilationProcessFinishedHelper(exitCode, exitStatus);
    zipFMU();
  } else if (mpCompilationProcess->error() == QProcess::UnknownError) {
    writePostCompilationOutput(exitCodeStr, Qt::red);
    postCompilationProcessFinishedHelper(exitCode, exitStatus);
  } else {
    writePostCompilationOutput(mpCompilationProcess->errorString() + "\n" + exitCodeStr, Qt::red);
    postCompilationProcessFinishedHelper(exitCode, exitStatus);
  }
}

/*!
 * \brief FmuExportOutputWidget::postCompilationProcessFinishedHelper
 * Slot activated when mpPostCompilationProcess finished signal is raised.\n
 * \param exitCode
 * \param exitStatus
 */
void FmuExportOutputWidget::postCompilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus)
{
  QString progressStr;
  mpCancelButton->setEnabled(false);
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    mpProgressBar->setValue(mpProgressBar->maximum());
    progressStr = tr("Build of %1 finished.").arg(mpLibraryTreeItem->getName());
  } else {
    progressStr = tr("Build of %1 failed.").arg(mpLibraryTreeItem->getName());
  }
  mpProgressLabel->setText(progressStr);
  updateMessageTab(progressStr);
}


/*!
 * \brief FmuExportOutputWidget::zipFMU
 * Runs the Zip compilation command after the post compilation of the model.
 */
void FmuExportOutputWidget::zipFMU()
{
  mpZipCompilationProcess = new QProcess;
  connect(mpZipCompilationProcess, SIGNAL(started()), SLOT(ZipCompilationProcessStarted()));
  connect(mpZipCompilationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readZipCompilationStandardOutput()));
  connect(mpZipCompilationProcess, SIGNAL(readyReadStandardError()), SLOT(readZipCompilationStandardError()));
#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
  connect(mpZipCompilationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(ZipCompilationProcessError(QProcess::ProcessError)));
#else
  connect(mpZipCompilationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(ZipCompilationProcessError(QProcess::ProcessError)));
#endif
  connect(mpZipCompilationProcess, SIGNAL(finished(int, QProcess::ExitStatus)), SLOT(ZipCompilationProcessFinished(int, QProcess::ExitStatus)));
  // check if FMU path is provided by user, otherwise generate the fmu in OMEDit working directory
  if (!mpLibraryTreeItem->getWhereToMoveFMU().isEmpty()){
    mFmuLocationPath = mpLibraryTreeItem->getWhereToMoveFMU() + "/" + mFMUName + ".fmu";
  } else {
    mFmuLocationPath = OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory() + "/" + mFMUName + ".fmu";
  }

  // change the directory to fmuTmpPath
  MainWindow::instance()->getOMCProxy()->changeDirectory(mFmuTmpPath);

  QString program = "zip";
  QStringList arguments;
  arguments << "-r" << mFmuLocationPath << ".";

  // check for fmiSources=false and do not export the source folder
  if (!OptionsDialog::instance()->getFMIPage()->getIncludeSourceCodeCheckBox()->isChecked()) {
#ifdef Q_OS_WIN
    arguments << "-x" << "'sources/*'";
#else
    arguments << "-x" << "sources/*";
#endif
  } else {
    // ignore the build_cmake directory
#ifdef Q_OS_WIN
    arguments << "-x" << "'sources/build_cmake/*'";
#else
    arguments << "-x" << "sources/build_cmake/*";
#endif
  }
  // remove the fmu if already exists.
  if (QFile::exists(mFmuLocationPath)) {
    if (!QFile::remove(mFmuLocationPath)) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                              GUIMessages::getMessage(GUIMessages::UNABLE_TO_DELETE_FILE).arg(mFmuLocationPath),
                                                              Helper::scriptingKind, Helper::warningLevel));
    }
  }

  writePostCompilationOutput(QString("%1 %2\n").arg(program, arguments.join(" ")), Qt::blue);
  mpZipCompilationProcess->start(program, arguments);
}

/*!
 * \brief FmuExportOutputWidget::ZipCompilationProcessStarted
* Slot activated when mpZipCompilationProcess started signal is raised.\n
 * Updates the progress label, bar and button controls.
 */
void FmuExportOutputWidget::ZipCompilationProcessStarted()
{
  mIsZipCompilationProcessRunning = true;
  const QString progressStr = tr("Zipping of %1").arg(mpLibraryTreeItem->getName());
  mpProgressLabel->setText(progressStr);
  mpProgressBar->setRange(0, 0);
  mpProgressBar->setTextVisible(false);
  updateMessageTab(progressStr);
  mpCancelButton->setText(tr("Cancel Compilation"));
  mpCancelButton->setEnabled(true);
}

/*!
 * \brief FmuExportOutputWidget::readZipCompilationStandardOutput
 * Slot activated when mpZipCompilationProcess readyReadStandardOutput signal is raised.\n
 */
void FmuExportOutputWidget::readZipCompilationStandardOutput()
{
  writePostCompilationOutput(QString(mpZipCompilationProcess->readAllStandardOutput()), Qt::black);
}

/*!
 * \brief FmuExportOutputWidget::readZipCompilationStandardError
 * Slot activated when mpZipCompilationProcess readyReadStandardError signal is raised.\n
 */
void FmuExportOutputWidget::readZipCompilationStandardError()
{
  writePostCompilationOutput(QString(mpZipCompilationProcess->readAllStandardError()), Qt::red);
}

/*!
 * \brief FmuExportOutputWidget::ZipCompilationProcessError
 * Slot activated when mpZipCompilationProcess errorOccurred signal is raised.\n
 * \param error
 */
void FmuExportOutputWidget::ZipCompilationProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  mIsZipCompilationProcessRunning = false;
  /* this signal is raised when we kill the compilation process forcefully. */
  if (isZipCompilationProcessKilled()) {
    return;
  }
  writePostCompilationOutput(mpZipCompilationProcess->errorString(), Qt::red);
}

/*!
 * \brief FmuExportOutputWidget::ZipCompilationProcessFinished
 * Slot activated when mpZipCompilationProcess finished signal is raised.\n
 * \param exitCode
 * \param exitStatus
 */
void FmuExportOutputWidget::ZipCompilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mIsZipCompilationProcessRunning = false;
  QString exitCodeStr = tr("Zip compilation process failed. Exited with code %1.").arg(Utilities::formatExitCode(exitCode));
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
      writePostCompilationOutput(tr("The FMU is generated at: %1").arg(mFmuLocationPath), Qt::blue);
    //trace export FMU
    if (OptionsDialog::instance()->getTraceabilityPage()->getTraceabilityGroupBox()->isChecked()) {
      //Push traceability information automaticaly to Daemon
      MainWindow::instance()->getCommitChangesDialog()->generateTraceabilityURI("fmuExport", mpLibraryTreeItem->getFileName(), mpLibraryTreeItem->getNameStructure(), mFmuLocationPath);
    }
    ZipCompilationProcessFinishedHelper(exitCode, exitStatus);
    setDefaults();
  } else if (mpCompilationProcess->error() == QProcess::UnknownError) {
    writePostCompilationOutput(exitCodeStr, Qt::red);
    ZipCompilationProcessFinishedHelper(exitCode, exitStatus);
    setDefaults();
  } else {
    writePostCompilationOutput(mpZipCompilationProcess->errorString() + "\n" + exitCodeStr, Qt::red);
    ZipCompilationProcessFinishedHelper(exitCode, exitStatus);
  }
}

/*!
 * \brief FmuExportOutputWidget::ZipCompilationProcessFinishedHelper
 * Slot activated when mpZipCompilationProcess finished signal is raised.\n
 * If the mpZipCompilationProcess finished normally then run the simulation executable.\n
 * \param exitCode
 * \param exitStatus
 */
void FmuExportOutputWidget::ZipCompilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus)
{
  QString progressStr;
  mpProgressBar->setRange(0, 1);
  mpCancelButton->setEnabled(false);
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    mpProgressBar->setValue(1);
    progressStr = tr("Export of FMU %1 finished.").arg(mpLibraryTreeItem->getName());
  } else {
    mpProgressBar->setValue(0);
    progressStr = tr("Export of FMU %1 failed.").arg(mpLibraryTreeItem->getName());
  }
  mpProgressLabel->setText(progressStr);
  updateMessageTab(progressStr);
}

/*!
 * \brief FmuExportOutputWidget::setDefaults
 * set the default working directory to user settings
 * after fmu export is success or failure
 */
void FmuExportOutputWidget::setDefaults()
{
  // unset the generate debug symbols flag
  if (OptionsDialog::instance()->getFMIPage()->getGenerateDebugSymbolsCheckBox()->isChecked()) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions(QString("-d=-gendebugsymbols"));
  }
  // change the work directory
  MainWindow::instance()->getOMCProxy()->changeDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
}

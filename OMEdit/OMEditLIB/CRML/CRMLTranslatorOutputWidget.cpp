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
#include <QApplication>
#include <QObject>
#include <QHeaderView>
#include <QAction>
#include <QMenu>
#include <QDesktopWidget>
#include <QTcpSocket>
#include <QMessageBox>
#include <QTextDocumentFragment>
#include <QClipboard>
#include <QDesktopServices>
#include <QGridLayout>

/*!
 * \brief CRMLTranslatorOutputWidget::CRMLTranslatorOutputWidget
 * \param simulationOptions
 * \param pParent
 */
CRMLTranslatorOutputWidget::CRMLTranslatorOutputWidget(CRMLTranslatorOptions simulationOptions, QWidget *pParent)
  : QWidget(pParent), mCRMLTranslatorOptions(simulationOptions)
{
  // progress label
  mpProgressLabel = new Label;
  mpProgressLabel->setElideMode(Qt::ElideMiddle);
  mpCancelButton = new QPushButton(tr("Cancel"));
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
  mpGeneratedFilesTabWidget->addTab(mpCompilationOutputTextBox, Helper::output);
  mpGeneratedFilesTabWidget->setTabEnabled(1, false);
  mGeneratedFilesList << "%1.mo";
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->addWidget(mpProgressLabel, 0, 0);
  pMainLayout->addWidget(mpProgressBar, 1, 1);
  pMainLayout->addWidget(mpCancelButton, 1, 2);
  pMainLayout->addWidget(mpGeneratedFilesTabWidget, 2, 0, 1, 5);
  setLayout(pMainLayout);
  mpCompilationProcess = 0;
  setCompilationProcessKilled(false);
  mIsCompilationProcessRunning = false;
}

/*!
 * \brief CRMLTranslatorOutputWidget::~CRMLTranslatorOutputWidget
 */
CRMLTranslatorOutputWidget::~CRMLTranslatorOutputWidget()
{
  // compilation process
  if (mpCompilationProcess && isCompilationProcessRunning()) {
    mpCompilationProcess->kill();
    mpCompilationProcess->deleteLater();
  }
}

/*!
 * \brief CRMLTranslatorOutputWidget::start
 * Starts the compilation/simulation.
 */
void CRMLTranslatorOutputWidget::start()
{
  compileModel();
}

/*!
 * \brief CRMLTranslatorOutputWidget::compileModel
 * Compiles the simulation model.
 */
void CRMLTranslatorOutputWidget::compileModel()
{
  mpCompilationProcess = new QProcess;
  mpCompilationProcess->setWorkingDirectory(mCRMLTranslatorOptions.getRepositoryDirectory());
  connect(mpCompilationProcess, SIGNAL(started()), SLOT(compilationProcessStarted()));
  connect(mpCompilationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readCompilationStandardOutput()));
  connect(mpCompilationProcess, SIGNAL(readyReadStandardError()), SLOT(readCompilationStandardError()));
#if (QT_VERSION >= QT_VERSION_CHECK(5, 6, 0))
  connect(mpCompilationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(compilationProcessError(QProcess::ProcessError)));
#else
  connect(mpCompilationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(compilationProcessError(QProcess::ProcessError)));
#endif
  connect(mpCompilationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(compilationProcessFinished(int,QProcess::ExitStatus)));
  QStringList args =
    {"-jar",
     mCRMLTranslatorOptions.getCompilerJar(),
     mCRMLTranslatorOptions.getCompilerCommandLineOptions()};
  // testsuite
  if (mCRMLTranslatorOptions.getMode().compare("testsuite") == 0) {
     args << "--testsuite";
  } else if (mCRMLTranslatorOptions.getMode().compare("translate") == 0) {
     args << "\"" + mCRMLTranslatorOptions.getCRMLFile() + "\"";
     QFileInfo fileInfo(mCRMLTranslatorOptions.getCRMLFile());
     mpCompilationProcess->setWorkingDirectory(fileInfo.absoluteDir().absolutePath());
  } else if (mCRMLTranslatorOptions.getMode().compare("translateAs") == 0) {
     if (!mCRMLTranslatorOptions.getOutputDirectory().isEmpty()) {
       args << "-o";
       args << "\"" + mCRMLTranslatorOptions.getOutputDirectory() + "\"";
       mpCompilationProcess->setWorkingDirectory(mCRMLTranslatorOptions.getOutputDirectory());
     }
     if (!mCRMLTranslatorOptions.getModelicaWithin().isEmpty()) {
       args << "--within";
       args << mCRMLTranslatorOptions.getModelicaWithin();
     }
     args << "\"" + mCRMLTranslatorOptions.getCRMLFile() + "\"";
  } else {
     // TODO fixme, error!
  }
  args.removeAll(QString(""));
  writeCompilationOutput(QString("%1 %2\n").arg(mCRMLTranslatorOptions.getCompilerProcess()).arg(args.join(" ")), Qt::blue);
  mpCompilationProcess->start(mCRMLTranslatorOptions.getCompilerProcess(), args);
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
 * \brief CRMLTranslatorOutputWidget::writeCompilationOutput
 * Writes the compilation standard output to the compilation output text box.
 * \param output
 * \param color
 */
void CRMLTranslatorOutputWidget::writeCompilationOutput(QString output, QColor color)
{
  QTextCharFormat format;
  format.setForeground(color);
  mpCompilationOutputTextBox->appendOutput(output, format);
}

void loadModelicaLibs(LibraryWidget *pLibraryWidget) {
  CRMLPage *ep = OptionsDialog::instance()->getCRMLPage();
  QStringList libs = ep->getModelicaLibraries()->list();
  for (const auto& l : libs) {
    QStringList paths = ep->getModelicaLibraryPaths()->text().split(QDir::listSeparator());
    for (const auto& p : paths) {
      QString fn(p + QDir::separator() + l);
      QFile f(fn);
      fn = fn.replace("\\", "/");
      if (f.exists()) {
        // do not load it again if it exists already
        if (!pLibraryWidget->getLibraryTreeModel()->getLibraryTreeItemFromFile(fn, 1))
          pLibraryWidget->openFile(fn, Helper::utf8, false, true);
      }
    }
  }
}

void CRMLTranslatorOutputWidget::compilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus)
{
  QString progressStr;
  mpProgressBar->setRange(0, 1);
  mpCancelButton->setEnabled(false);
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    LibraryWidget *pLibraryWidget = MainWindow::instance()->getLibraryWidget();
    mpProgressBar->setValue(1);
    if (mCRMLTranslatorOptions.getMode().compare("testsuite") == 0) {
      progressStr = tr("Testsuite run in directory %1 finished.").arg(mCRMLTranslatorOptions.getRepositoryDirectory());
      // here we need to find out the html file and open it in the QtBrowser
      QString file = mCRMLTranslatorOptions.getRepositoryDirectory() + QDir::separator() + "build" + QDir::separator() + "test_report.html";
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
    } else if (mCRMLTranslatorOptions.getMode().compare("translate") == 0) {
      progressStr = tr("Translation of CRML file %1 finished.").arg(mCRMLTranslatorOptions.getCRMLFile());

      QFileInfo fi = QFileInfo(mCRMLTranslatorOptions.getCRMLFile());

      loadModelicaLibs(pLibraryWidget);

      QString fileName = fi.absoluteDir().absolutePath() + QDir::separator() + "generated" + QDir::separator() + fi.fileName();
      fileName = fileName.remove(fileName.lastIndexOf(".crml"), 5);
      fileName += ".mo";
      fileName = fileName.replace("\\", "/");
      pLibraryWidget->openFile(fileName, Helper::utf8, false, true);
      // now open it if we can find it in the tree!
      LibraryTreeItem *pMOLibraryTreeItem = pLibraryWidget->getLibraryTreeModel()->getLibraryTreeItemFromFile(fileName, 1);
      if (pMOLibraryTreeItem) {
        pLibraryWidget->getLibraryTreeModel()->showModelWidget(pMOLibraryTreeItem);
      }
    } else if (mCRMLTranslatorOptions.getMode().compare("translateAs") == 0) {
      progressStr = tr("Translation of CRML file %1 with output directory %2 and within %3 finished.").
        arg(mCRMLTranslatorOptions.getCRMLFile(),
            mCRMLTranslatorOptions.getOutputDirectory(),
            mCRMLTranslatorOptions.getModelicaWithin());

      loadModelicaLibs(pLibraryWidget);

      QFileInfo fi = QFileInfo(mCRMLTranslatorOptions.getCRMLFile());
      QString outputDirectory = mCRMLTranslatorOptions.getOutputDirectory();

      QString fileName = outputDirectory + QDir::separator() +  fi.baseName() + QDir::separator() + fi.baseName() + ".mo";
      fileName = fileName.replace("\\", "/");
      pLibraryWidget->openFile(fileName, Helper::utf8, false, true);
      // now open it if we can find it in the tree!
      LibraryTreeItem *pMOLibraryTreeItem = pLibraryWidget->getLibraryTreeModel()->getLibraryTreeItemFromFile(fileName, 1);
      if (pMOLibraryTreeItem) {
        pLibraryWidget->getLibraryTreeModel()->showModelWidget(pMOLibraryTreeItem);
      }
    } else {
      // TODO fixme, error!
    }
  } else {
    mpProgressBar->setValue(0);
    if (mCRMLTranslatorOptions.getMode().compare("testsuite") == 0) {
      progressStr = tr("Testsuite run in directory %1 failed.").arg(mCRMLTranslatorOptions.getRepositoryDirectory());
    } else if (mCRMLTranslatorOptions.getMode().compare("translate") == 0) {
      progressStr = tr("Translation of the CRML %1 file failed.").arg(mCRMLTranslatorOptions.getCRMLFile());
    } else if (mCRMLTranslatorOptions.getMode().compare("translateAs") == 0) {
      progressStr = tr("Translation of the CRML file %1 with output directory %2 and within %3 finished.").
        arg(mCRMLTranslatorOptions.getCRMLFile(),
            mCRMLTranslatorOptions.getOutputDirectory(),
            mCRMLTranslatorOptions.getModelicaWithin()
            );
    } else {
      // TODO fixme, error!
    }
  }
  mpProgressLabel->setText(progressStr);
  updateMessageTab(progressStr);
}

/*!
 * \brief CRMLTranslatorOutputWidget::cancelCompilation
 * Slot activated when mpCancelButton clicked signal is raised.\n
 * Cancels a running compilaiton/simulation by killing the compilation/simulation process.
 */
void CRMLTranslatorOutputWidget::cancelCompilation()
{
  QString progressStr;
  if (isCompilationProcessRunning()) {
    setCompilationProcessKilled(true);
    mpCompilationProcess->kill();
    mIsCompilationProcessRunning = false;
    progressStr = tr("Testsuite run in directory %1 is cancelled.").arg(mCRMLTranslatorOptions.getRepositoryDirectory());
    mpProgressBar->setRange(0, 1);
    mpProgressBar->setValue(0);
    mpCancelButton->setEnabled(false);
  }
  mpProgressLabel->setText(progressStr);
  updateMessageTab(progressStr);
}

/*!
 * \brief CRMLTranslatorOutputWidget::compilationProcessStarted
* Slot activated when mpCompilationProcess started signal is raised.\n
 * Updates the progress label, bar and button controls.
 */
void CRMLTranslatorOutputWidget::compilationProcessStarted()
{
  mIsCompilationProcessRunning = true;
  const QString progressStr = tr("CRML compiler is running. Please wait for a while.");
  mpProgressLabel->setText(progressStr);
  mpProgressBar->setRange(0, 0);
  mpProgressBar->setTextVisible(false);
  updateMessageTab(progressStr);
  mpCancelButton->setText(tr("Cancel"));
  mpCancelButton->setEnabled(true);
}

/*!
 * \brief CRMLTranslatorOutputWidget::readCompilationStandardOutput
 * Slot activated when mpCompilationProcess readyReadStandardOutput signal is raised.\n
 */
void CRMLTranslatorOutputWidget::readCompilationStandardOutput()
{
  writeCompilationOutput(QString(mpCompilationProcess->readAllStandardOutput()), Qt::black);
}

/*!
 * \brief CRMLTranslatorOutputWidget::readCompilationStandardError
 * Slot activated when mpCompilationProcess readyReadStandardError signal is raised.\n
 */
void CRMLTranslatorOutputWidget::readCompilationStandardError()
{
  writeCompilationOutput(QString(mpCompilationProcess->readAllStandardError()), Qt::red);
}

/*!
 * \brief CRMLTranslatorOutputWidget::compilationProcessError
 * Slot activated when mpCompilationProcess errorOccurred signal is raised.\n
 * \param error
 */
void CRMLTranslatorOutputWidget::compilationProcessError(QProcess::ProcessError error)
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
 * \brief CRMLTranslatorOutputWidget::compilationProcessFinished
 * Slot activated when mpCompilationProcess finished signal is raised.\n
 * If the mpCompilationProcess finished normally then run the simulation executable.\n
 * Calls the Transformational Debugger or Algorithmic Debugger depending on the user selections.
 * \param exitCode
 * \param exitStatus
 */
void CRMLTranslatorOutputWidget::compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mIsCompilationProcessRunning = false;
  QString exitCodeStr = tr("Testsuite run process failed. Exited with code %1.").arg(Utilities::formatExitCode(exitCode));
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    writeCompilationOutput(tr("Testsuite run process finished successfully.\n"), Qt::blue);
    compilationProcessFinishedHelper(exitCode, exitStatus);
  } else if (mpCompilationProcess->error() == QProcess::UnknownError) {
    writeCompilationOutput(exitCodeStr, Qt::red);
    compilationProcessFinishedHelper(exitCode, exitStatus);
  } else {
    writeCompilationOutput(mpCompilationProcess->errorString() + "\n" + exitCodeStr, Qt::red);
    compilationProcessFinishedHelper(exitCode, exitStatus);
  }
}


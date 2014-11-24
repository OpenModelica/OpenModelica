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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "SimulationOutputWidget.h"
#include "VariablesWidget.h"

/*!
  \class SimulationOutputDialog
  \brief Creates a dialog that shows the current simulation output.
  */

/*!
  \param modelName - the name of the simulating model.
  \param pSimulationProcess - the simulation process.
  \param pParent - pointer to MainWindow.
  */
SimulationOutputWidget::SimulationOutputWidget(SimulationOptions simulationOptions, MainWindow *pMainWindow)
  : mSimulationOptions(simulationOptions), mpMainWindow(pMainWindow)
{
  setWindowTitle(QString("%1 - %2 %3").arg(Helper::applicationName).arg(mSimulationOptions.getClassName()).arg(tr("Simulation Output")));
  // progress label
  mpProgressLabel = new Label;
  mpProgressLabel->setTextFormat(Qt::RichText);
  mpCancelButton = new QPushButton(tr("Cancel Compilation"));
  mpCancelButton->setEnabled(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(cancelCompilationOrSimulation()));
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  // Generated Files tab widget
  mpGeneratedFilesTabWidget = new QTabWidget;
  mpGeneratedFilesTabWidget->setMovable(true);
  // Simulation Output TextBox
  mpSimulationOutputTextBrowser = new QTextBrowser;
  mpSimulationOutputTextBrowser->setFont(QFont(Helper::monospacedFontInfo.family()));
  mpSimulationOutputTextBrowser->setOpenLinks(false);
  mpSimulationOutputTextBrowser->setOpenExternalLinks(false);
  connect(mpSimulationOutputTextBrowser, SIGNAL(anchorClicked(QUrl)), SLOT(openTransformationBrowser(QUrl)));
  mpGeneratedFilesTabWidget->addTab(mpSimulationOutputTextBrowser, Helper::output);
  mpGeneratedFilesTabWidget->setTabEnabled(0, false);
  // Compilation Output TextBox
  mpCompilationOutputTextBox = new QPlainTextEdit;
  mpCompilationOutputTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  mpGeneratedFilesTabWidget->addTab(mpCompilationOutputTextBox, tr("Compilation"));
  mpGeneratedFilesTabWidget->setTabEnabled(1, false);
  if (mSimulationOptions.getShowGeneratedFiles()) {
    QString workingDirectory = mSimulationOptions.getWorkingDirectory();
    QString outputFile = mSimulationOptions.getOutputFileName();
    /* className.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append(".c"));
    /* className_01exo.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_01exo.c"));
    /* className_02nls.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_02nls.c"));
    /* className_03lsy.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_03lsy.c"));
    /* className_04set.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_04set.c"));
    /* className_05evt.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_05evt.c"));
    /* className_06inz.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_06inz.c"));
    /* className_07dly.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_07dly.c"));
    /* className_08bnd.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_08bnd.c"));
    /* className_09alg.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_09alg.c"));
    /* className_10asr.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_10asr.c"));
    /* className_11mix.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_11mix.c"));
    /* className_11mix.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_11mix.h"));
    /* className_12jac.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_12jac.c"));
    /* className_12jac.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_12jac.h"));
    /* className_13opt.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_13opt.c"));
    /* className_14lnz.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_14lnz.c"));
    /* className_functions.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_functions.c"));
    /* className_records.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_records.c"));
    /* className_11mix.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_11mix.h"));
    /* className_12jac.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_12jac.h"));
    /* className_13opt.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_13opt.h"));
    /* className_functions.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_functions.h"));
    /* className_includes.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_includes.h"));
    /* className_literals.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_literals.h"));
    /* className_model.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_model.h"));
    /* className_info.xml tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_info.xml"));
    /* className_init.xml tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_init.xml"));
  }
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->addWidget(mpProgressLabel, 0, 0, 1, 2);
  pMainLayout->addWidget(mpProgressBar, 1, 0);
  pMainLayout->addWidget(mpCancelButton, 1, 1);
  pMainLayout->addWidget(mpGeneratedFilesTabWidget, 2, 0, 1, 2);
  setLayout(pMainLayout);
  mIsCancelled = false;
  // create the thread
  mpSimulationProcessThread = new SimulationProcessThread(this);
  connect(mpSimulationProcessThread, SIGNAL(sendCompilationStarted()), SLOT(compilationProcessStarted()));
  connect(mpSimulationProcessThread, SIGNAL(sendCompilationOutput(QString,QColor)), SLOT(writeCompilationOutput(QString,QColor)));
  connect(mpSimulationProcessThread, SIGNAL(sendCompilationFinished(int,QProcess::ExitStatus)), SLOT(compilationProcessFinished(int,QProcess::ExitStatus)));
  connect(mpSimulationProcessThread, SIGNAL(sendSimulationStarted()), SLOT(simulationProcessStarted()));
  connect(mpSimulationProcessThread, SIGNAL(sendSimulationOutput(QString,QColor,bool)), SLOT(writeSimulationOutput(QString,QColor,bool)));
  connect(mpSimulationProcessThread, SIGNAL(sendSimulationFinished(int,QProcess::ExitStatus)), SLOT(simulationProcessFinished(int,QProcess::ExitStatus)));
  connect(mpSimulationProcessThread, SIGNAL(sendSimulationProgress(int)), mpProgressBar, SLOT(setValue(int)));
  mpSimulationProcessThread->start();
}

void SimulationOutputWidget::addGeneratedFileTab(QString fileName)
{
  QFile file(fileName);
  QFileInfo fileInfo(fileName);
  if (file.exists()) {
    file.open(QIODevice::ReadOnly);
    QPlainTextEdit *pPlainTextEdit = new QPlainTextEdit(QString(file.readAll()));
    pPlainTextEdit->setFont(QFont(Helper::monospacedFontInfo.family()));
    mpGeneratedFilesTabWidget->addTab(pPlainTextEdit, fileInfo.fileName());
    file.close();
  }
}

/*!
  Parses the xml output of simulation executable.
  \param output - output string
  \return list of messages
  */
/*
  <message stream="LOG_STATS" type="info" text="events">
    <message stream="LOG_STATS" type="info" text="    0 state events" />
    <message stream="LOG_STATS" type="info" text="    0 time events" />
  </message>
  <message stream="stdout" type="info" text="output text">
    <used index="2" />
  </message>
  */
QList<SimulationMessage> SimulationOutputWidget::parseXMLLogOutput(QString output)
{
//  output = "<root><message stream=\"LOG_STATS\" type=\"info\" text=\"### STATISTICS ###\" />";
//  output += "<message stream=\"LOG_STATS\" type=\"info\" text=\"events\">";
//  output += "<message stream=\"LOG_STATS\" type=\"info\" text=\"    0 state events\" />";
//  output += "<message stream=\"LOG_STATS\" type=\"info\" text=\"    0 time events\" />";
//  output += "</message></root>";

  QList<SimulationMessage> simulationMessages;
  QDomDocument xmlDocument;
  QString errorMsg;
  int errorLine, errorColumn;
  /*
    We should enclose the output in root tag because there can be only one top level element.
    */
  QString output1 = output;
  output1.prepend("<root>").append("</root>");
  if (!xmlDocument.setContent(output1, &errorMsg, &errorLine, &errorColumn)) {
    /* make the text color red */
    QTextCharFormat charFormat = mpSimulationOutputTextBrowser->currentCharFormat();
    charFormat.setForeground(Qt::red);
    mpSimulationOutputTextBrowser->setCurrentCharFormat(charFormat);
    /* print the parser error alongwith the actual output. */
    mpSimulationOutputTextBrowser->insertPlainText(tr("Error while parsing message xml %1 %2:%3\n").arg(errorMsg).arg(errorLine).arg(errorColumn));
    mpSimulationOutputTextBrowser->insertPlainText(output);
    return simulationMessages;
  }
  //Get the root element
  QDomElement documentElement = xmlDocument.documentElement();
  QDomNodeList messageNodes = documentElement.childNodes();
  for (int i = 0; i < messageNodes.size(); i++)
  {
    if (messageNodes.at(i).nodeName() == "message")
    {
      simulationMessages.append(parseXMLLogMessageTag(messageNodes.at(i), 0));
    }
  }
  return simulationMessages;
}

SimulationMessage SimulationOutputWidget::parseXMLLogMessageTag(QDomNode messageNode, int level)
{
  SimulationMessage simulationMessage;
  QDomElement messageElement = messageNode.toElement();
  simulationMessage.mStream = messageElement.attribute("stream");
  simulationMessage.mType = messageElement.attribute("type");
  simulationMessage.mText = messageElement.attribute("text");
  simulationMessage.mLevel = level;
  QDomNodeList childNodes = messageNode.childNodes();
  for (int i = 0; i < childNodes.size(); i++) {
    if (childNodes.at(i).nodeName() == "used") {
      simulationMessage.mIndex = childNodes.at(i).toElement().attribute("index");
    } else if (childNodes.at(i).nodeName() == "message") {
      simulationMessage.mChildren.append(parseXMLLogMessageTag(childNodes.at(i), simulationMessage.mLevel + 1));
    }
  }
  return simulationMessage;
}

void SimulationOutputWidget::writeSimulationMessage(SimulationMessage &simulationMessage)
{
  static QString lastSream;
  static QString lastType;
  /* format the error message */
  QString error = ((lastSream == simulationMessage.mStream && simulationMessage.mLevel > 0) ? "|" : simulationMessage.mStream) + "\t\t| ";
  error += ((lastSream == simulationMessage.mStream && lastType == simulationMessage.mType && simulationMessage.mLevel > 0) ? "|" : simulationMessage.mType) + "\t | ";
  for (int i = 0 ; i < simulationMessage.mLevel ; ++i)
    error += "| ";
  error += simulationMessage.mText;
  /* write the error message */
  mpSimulationOutputTextBrowser->insertPlainText(error);
  /* write the error link */
  if (!simulationMessage.mIndex.isEmpty()) {
    mpSimulationOutputTextBrowser->insertHtml("&nbsp;<a href=\"omedittransformationsbrowser://" + QUrl::fromLocalFile(mSimulationOptions.getWorkingDirectory() + "/" + mSimulationOptions.getFileNamePrefix() + "_info.xml").path() + "?index=" + simulationMessage.mIndex + "\">Debug more</a><br />");
  } else {
    mpSimulationOutputTextBrowser->insertPlainText("\n");
  }
  /* save the current stream & type as last */
  lastSream = simulationMessage.mStream;
  lastType = simulationMessage.mType;
  /* write the child messages */
  foreach (SimulationMessage s, simulationMessage.mChildren) {
    writeSimulationMessage(s);
  }
}

/*!
  Slot activated when SimulationProcessThread sendCompilationStarted signal is raised.\n
  Updates the progress label, bar and button controls.
  */
void SimulationOutputWidget::compilationProcessStarted()
{
  mpProgressLabel->setText(tr("Compiling <b>%1</b>. Please wait for a while.").arg(mSimulationOptions.getClassName()));
  mpProgressBar->setRange(0, 0);
  mpProgressBar->setTextVisible(false);
  mpCancelButton->setText(tr("Cancel Compilation"));
  mpCancelButton->setEnabled(true);
}


/*!
  Slot activated when SimulationProcessThread sendCompilationStandardOutput signal is raised.\n
  Writes the compilation standard output to the compilation output text box.
  */
void SimulationOutputWidget::writeCompilationOutput(QString output, QColor color)
{
  mpGeneratedFilesTabWidget->setTabEnabled(1, true);
  /* move the cursor down before adding to the logger. */
  QTextCursor textCursor = mpCompilationOutputTextBox->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpCompilationOutputTextBox->setTextCursor(textCursor);
  /* set the text color red */
  QTextCharFormat charFormat = mpCompilationOutputTextBox->currentCharFormat();
  charFormat.setForeground(color);
  mpCompilationOutputTextBox->setCurrentCharFormat(charFormat);
  /* append the output */
  mpCompilationOutputTextBox->insertPlainText(output);
  /* move the cursor */
  textCursor.movePosition(QTextCursor::End);
  mpCompilationOutputTextBox->setTextCursor(textCursor);
  /* make the compilation tab the current one */
  mpGeneratedFilesTabWidget->setCurrentIndex(1);
}

/*!
  Slot activated when SimulationProcessThread sendCompilationFinished signal is raised.\n
  Calls the Transformational Debugger or Algorithmic Debugger depending on the user selections.
  */
void SimulationOutputWidget::compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mpProgressLabel->setText(tr("Compilation of <b>%1</b> is finished.").arg(mSimulationOptions.getClassName()));
  mpProgressBar->setRange(0, 1);
  mpProgressBar->setValue(1);
  mpCancelButton->setEnabled(false);
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    /* show the Transformational Debugger */
    if (mpMainWindow->getOptionsDialog()->getDebuggerPage()->getAlwaysShowTransformationsCheckBox()->isChecked() ||
        mSimulationOptions.getLaunchTransformationalDebugger()) {
      mpMainWindow->showTransformationsWidget(mSimulationOptions.getWorkingDirectory() + "/" + mSimulationOptions.getOutputFileName() + "_info.xml");
    }
    // if not build only and launch the algorithmic debugger is true
    if (!mSimulationOptions.getBuildOnly() && mSimulationOptions.getLaunchAlgorithmicDebugger()) {
      QString fileName = mSimulationOptions.getOutputFileName();
      // start the executable
      fileName = QString(mSimulationOptions.getWorkingDirectory()).append("/").append(fileName);
      fileName = fileName.replace("//", "/");
      // run the simulation executable to create the result file
#ifdef WIN32
      fileName = fileName.append(".exe");
#endif
      // start the debugger
      if (mpMainWindow->getDebuggerMainWindow()->getGDBAdapter()->isGDBRunning()) {
        QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                                 GUIMessages::getMessage(GUIMessages::DEBUGGER_ALREADY_RUNNING), Helper::ok);
      } else {
        QString GDBPath = mpMainWindow->getOptionsDialog()->getDebuggerPage()->getGDBPath();
        GDBAdapter *pGDBAdapter = mpMainWindow->getDebuggerMainWindow()->getGDBAdapter();
        pGDBAdapter->launch(fileName, mSimulationOptions.getWorkingDirectory(), mSimulationOptions.getSimulationFlags(), GDBPath, this);
        mpMainWindow->showAlgorithmicDebugger();
      }
    }
  }
}

/*!
  Slot activated when SimulationProcessThread sendSimulationStarted signal is raised.\n
  Updates the progress label, bar and button controls.
  */
void SimulationOutputWidget::simulationProcessStarted()
{
  mpProgressLabel->setText(tr("Running simulation of <b>%1</b>. Please wait for a while.").arg(mSimulationOptions.getClassName()));
  mpProgressBar->setRange(0, 100);
  mpProgressBar->setTextVisible(true);
  mpCancelButton->setText(tr("Cancel Simulation"));
  mpCancelButton->setEnabled(true);
  // save the last modified datetime of result file.
  QFileInfo resultFileInfo(QString(mSimulationOptions.getWorkingDirectory()).append("/").append(mSimulationOptions.getResultFileName()));
  if (resultFileInfo.exists()) {
    mResultFileLastModifiedDateTime = resultFileInfo.lastModified();
  }
}


/*!
  Slot activated when SimulationProcessThread sendSimulationOutput signal is raised.\n
  Writes the simulation standard output to the simulation output text box.
  */
void SimulationOutputWidget::writeSimulationOutput(QString output, QColor color, bool textFormat)
{
  mpGeneratedFilesTabWidget->setTabEnabled(0, true);
  /* move the cursor down before adding to the logger. */
  QTextCursor textCursor = mpSimulationOutputTextBrowser->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpSimulationOutputTextBrowser->setTextCursor(textCursor);
  /* set the text color */
  QTextCharFormat charFormat = mpSimulationOutputTextBrowser->currentCharFormat();
  charFormat.setForeground(color);
  mpSimulationOutputTextBrowser->setCurrentCharFormat(charFormat);
  /* append the output */
  if (textFormat) {
    mpSimulationOutputTextBrowser->insertPlainText(output);
  } else {
    QList<SimulationMessage> simulationMessages = parseXMLLogOutput(output);
    foreach (SimulationMessage simulationMessage, simulationMessages) {
      writeSimulationMessage(simulationMessage);
    }
  }
  /* move the cursor */
  textCursor.movePosition(QTextCursor::End);
  mpSimulationOutputTextBrowser->setTextCursor(textCursor);
  /* make the compilation tab the current one */
  mpGeneratedFilesTabWidget->setCurrentIndex(0);
}

/*!
  Slot activated when SimulationProcessThread sendSimulationFinished signal is raised.\n
  Reads the result variables, populates the variables browser and shows the plotting view.
  */
void SimulationOutputWidget::simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mpProgressLabel->setText(tr("Simulation of <b>%1</b> is finished.").arg(mSimulationOptions.getClassName()));
  mpProgressBar->setValue(mpProgressBar->maximum());
  mpCancelButton->setEnabled(false);
  if (exitStatus == QProcess::NormalExit && exitCode == 0 && mSimulationOptions.getProfiling() != "none") {
    mpMainWindow->showTransformationsWidget(mSimulationOptions.getWorkingDirectory() + "/" + mSimulationOptions.getOutputFileName() + "_info.xml");
  }
  QString workingDirectory = mSimulationOptions.getWorkingDirectory();
  // read the result file
  QFileInfo resultFileInfo(QString(workingDirectory).append("/").append(mSimulationOptions.getResultFileName()));
  QRegExp regExp("\\b(mat|plt|csv)\\b");
  if (regExp.indexIn(mSimulationOptions.getResultFileName()) != -1 &&
      resultFileInfo.exists() && mResultFileLastModifiedDateTime <= resultFileInfo.lastModified()) {
    VariablesWidget *pVariablesWidget = mpMainWindow->getVariablesWidget();
    OMCProxy *pOMCProxy = mpMainWindow->getOMCProxy();
    QStringList list = pOMCProxy->readSimulationResultVars(mSimulationOptions.getResultFileName());
    // close the simulation result file.
    pOMCProxy->closeSimulationResultFile();
    if (list.size() > 0) {
      mpMainWindow->getPerspectiveTabBar()->setCurrentIndex(2);
      pVariablesWidget->insertVariablesItemsToTree(mSimulationOptions.getResultFileName(), workingDirectory, list, mSimulationOptions);
      mpMainWindow->getVariablesDockWidget()->show();
    }
  }
}

/*!
  Slot activated when GDBAdapter::mpGDBProcess started signal is raised.
  */
void SimulationOutputWidget::GDBProcessStarted()
{
  // save the last modified datetime of result file.
  QFileInfo resultFileInfo(QString(mSimulationOptions.getWorkingDirectory()).append("/").append(mSimulationOptions.getResultFileName()));
  if (resultFileInfo.exists()) {
    mResultFileLastModifiedDateTime = resultFileInfo.lastModified();
  }
}

/*!
  Slot activated when GDBAdapter::mpGDBProcess finished signal is raised.
  */
void SimulationOutputWidget::GDBProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  if (!mpMainWindow->getDebuggerMainWindow()->getGDBAdapter()->isGDBKilled()) {
    simulationProcessFinished(exitCode, exitStatus);
  }
}

/*!
  Slot activated when mpCancelButton clicked signal is raised.\n
  Cancels a running compilaiton/simulation by killing the compilation/simulation process.
  */
void SimulationOutputWidget::cancelCompilationOrSimulation()
{
  mIsCancelled = true;
  if (mpSimulationProcessThread->isCompilationProcessRunning()) {
    mpSimulationProcessThread->getCompilationProcess()->kill();
    mpProgressLabel->setText(tr("Compilation of <b>%1</b> is cancelled.").arg(mSimulationOptions.getClassName()));
    mpProgressBar->setRange(0, 1);
    mpProgressBar->setValue(1);
    mpCancelButton->setEnabled(false);
  } else if (mpSimulationProcessThread->isSimulationProcessRunning()) {
    mpSimulationProcessThread->getSimulationProcess()->kill();
    mpProgressLabel->setText(tr("Simulation of <b>%1</b> is cancelled.").arg(mSimulationOptions.getClassName()));
    mpProgressBar->setValue(mpProgressBar->maximum());
    mpCancelButton->setEnabled(false);
  }
}

/*!
  Slot activated when a link is clicked from simulation output and anchorClicked signal of mpSimulationOutputTextBrowser is raised.\n
  Parses the url and loads the TransformationsWidget with the used equation.
  \param url - the url that is clicked
  */
/*
  <a href="file://model_res.mat?path=working_directory&index=4></a>"
  */
void SimulationOutputWidget::openTransformationBrowser(QUrl url)
{
  /* read the file name */
  if (url.scheme() != "omedittransformationsbrowser") {
    /* TODO: Write error-message?! */
    return;
  }
  QString fileName = url.path();
#ifdef WIN32
  if (fileName.startsWith("/")) fileName.remove(0, 1);
#endif
  /* open the model_info.xml file */
  if (QFileInfo(fileName).exists()) {
    TransformationsWidget *pTransformationsWidget = mpMainWindow->showTransformationsWidget(fileName);
    int equationIndex = url.queryItemValue("index").toInt();
    QTreeWidgetItem *pTreeWidgetItem = pTransformationsWidget->findEquationTreeItem(equationIndex);
    if (pTreeWidgetItem)
    {
      pTransformationsWidget->getEquationsTreeWidget()->clearSelection();
      pTransformationsWidget->getEquationsTreeWidget()->setCurrentItem(pTreeWidgetItem);
    }
    pTransformationsWidget->fetchEquationData(equationIndex);
  } else {
    /* TODO: Display error-message */
  }
}

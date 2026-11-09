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

/*
 * @author adrian.pop@liu.se
 */

#include "OMSCalibrationDialog.h"
#include "omedit_config.h"
#include "MainWindow.h"
#include "OMSProxy.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Options/OptionsDialog.h"
#include "Util/Helper.h"
#include "Util/OutputPlainTextEdit.h"

#include <QGridLayout>

/*!
 * \class OMSCalibrationDialog
 * \brief Calibrates the parameters of an SSP model against reference data with OMSimulator.
 * The calibration problem is a Calibration activity of the UQ layered standard file of the SSP.
 */
/*!
 * \brief OMSCalibrationDialog::OMSCalibrationDialog
 * \param pLibraryTreeItem - the top level SSP model.
 * \param pParent
 */
OMSCalibrationDialog::OMSCalibrationDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent)
  : QDialog(pParent), mpLibraryTreeItem(pLibraryTreeItem), mpCalibrationProcess(0)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2 %3").arg(Helper::applicationName, tr("Calibrate"), mpLibraryTreeItem->getNameStructure()));
  setMinimumWidth(650);
  // heading
  mpHeadingLabel = Utilities::getHeadingLabel(QString("%1 - %2").arg(tr("Calibrate"), mpLibraryTreeItem->getNameStructure()));
  mpHeadingLabel->setElideMode(Qt::ElideMiddle);
  mpHorizontalLine = Utilities::getHeadingLine();
  // activity
  mpActivityLabel = new Label(tr("Calibration Activity:"));
  mpActivityTextBox = new QLineEdit;
  mpActivityTextBox->setPlaceholderText(tr("the only Calibration activity of the UQ file"));
  // UQ file
  mpUQFileLabel = new Label(tr("UQ File:"));
  mpUQFileTextBox = new QLineEdit;
  mpUQFileTextBox->setPlaceholderText(tr("the UQ file referenced by the SSP, e.g. extra/uq.xml"));
  // output file
  mpOutputFileLabel = new Label(tr("Calibrated Model:"));
  mpOutputFileTextBox = new QLineEdit(QString("%1/%2.calibrated.ssp").arg(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory(),
                                                                         mpLibraryTreeItem->getNameStructure()));
  mpBrowseOutputFileButton = new QPushButton(Helper::browse);
  mpBrowseOutputFileButton->setAutoDefault(false);
  connect(mpBrowseOutputFileButton, &QPushButton::clicked, this, &OMSCalibrationDialog::browseOutputFile);
  // calibration output
  mpOutputPlainTextEdit = new OutputPlainTextEdit;
  mpOutputPlainTextEdit->setFont(QFont(Helper::monospacedFontInfo.family()));
  // buttons
  mpCalibrateButton = new QPushButton(tr("Calibrate"));
  mpCalibrateButton->setAutoDefault(true);
  mpCalibrateButton->setEnabled(!mpLibraryTreeItem->isSystemLibrary());
  connect(mpCalibrateButton, &QPushButton::clicked, this, &OMSCalibrationDialog::calibrate);
  mpCloseButton = new QPushButton(Helper::close);
  mpCloseButton->setAutoDefault(false);
  connect(mpCloseButton, &QPushButton::clicked, this, &OMSCalibrationDialog::reject);
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpCalibrateButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCloseButton, QDialogButtonBox::ActionRole);
  // layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  pMainGridLayout->addWidget(mpHeadingLabel, 0, 0, 1, 3);
  pMainGridLayout->addWidget(mpHorizontalLine, 1, 0, 1, 3);
  pMainGridLayout->addWidget(mpActivityLabel, 2, 0);
  pMainGridLayout->addWidget(mpActivityTextBox, 2, 1, 1, 2);
  pMainGridLayout->addWidget(mpUQFileLabel, 3, 0);
  pMainGridLayout->addWidget(mpUQFileTextBox, 3, 1, 1, 2);
  pMainGridLayout->addWidget(mpOutputFileLabel, 4, 0);
  pMainGridLayout->addWidget(mpOutputFileTextBox, 4, 1);
  pMainGridLayout->addWidget(mpBrowseOutputFileButton, 4, 2);
  pMainGridLayout->addWidget(mpOutputPlainTextEdit, 5, 0, 1, 3);
  pMainGridLayout->addWidget(mpButtonBox, 6, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainGridLayout);
}

/*!
 * \brief OMSCalibrationDialog::~OMSCalibrationDialog
 * Stops a running calibration.
 */
OMSCalibrationDialog::~OMSCalibrationDialog()
{
  if (mpCalibrationProcess && mpCalibrationProcess->state() != QProcess::NotRunning) {
    mpCalibrationProcess->disconnect(this);
    mpCalibrationProcess->kill();
    mpCalibrationProcess->waitForFinished();
  }
}

void OMSCalibrationDialog::writeOutput(const QString &output, StringHandler::SimulationMessageType type)
{
  QTextCharFormat textCharFormat;
  textCharFormat.setForeground(OptionsDialog::instance()->getMessagesPage()->getColor(type));
  mpOutputPlainTextEdit->appendOutput(output, textCharFormat);
}

/*!
 * \brief OMSCalibrationDialog::browseOutputFile
 * Selects the SSP file the calibrated model is written to.
 */
void OMSCalibrationDialog::browseOutputFile()
{
  QString name = QFileInfo(mpOutputFileTextBox->text()).fileName();
  QString fileName = StringHandler::getSaveFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::saveFile), NULL,
                                                    "", NULL, "ssp", &name);
  if (!fileName.isEmpty()) {
    mpOutputFileTextBox->setText(fileName);
  }
}

/*!
 * \brief OMSCalibrationDialog::calibrate
 * Exports the model and runs the OMSimulator calibration on it.
 */
void OMSCalibrationDialog::calibrate()
{
  QString outputFile = mpOutputFileTextBox->text().trimmed();
  if (outputFile.isEmpty()) {
    writeOutput(tr("Select the file to write the calibrated model to.\n"), StringHandler::Error);
    return;
  }
  QString fileName = QString("%1/%2.calibration.ssp").arg(Utilities::tempDirectory(), mpLibraryTreeItem->getNameStructure());
  if (!OMSProxy::instance()->saveModel(mpLibraryTreeItem->getNameStructure(), fileName)) {
    writeOutput(tr("Failed to export %1 to %2.\n").arg(mpLibraryTreeItem->getNameStructure(), fileName), StringHandler::Error);
    return;
  }
  mpOutputPlainTextEdit->clear();
  mpCalibrateButton->setEnabled(false);
  delete mpCalibrationProcess;
  mpCalibrationProcess = new QProcess(this);
  mpCalibrationProcess->setWorkingDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
  connect(mpCalibrationProcess, &QProcess::readyReadStandardOutput, this, &OMSCalibrationDialog::readStandardOutput);
  connect(mpCalibrationProcess, &QProcess::readyReadStandardError, this, &OMSCalibrationDialog::readStandardError);
  connect(mpCalibrationProcess, &QProcess::errorOccurred, this, &OMSCalibrationDialog::calibrationProcessError);
  connect(mpCalibrationProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &OMSCalibrationDialog::calibrationProcessFinished);
  QStringList args;
  args << QString("--calibrate=%1").arg(mpActivityTextBox->text().trimmed());
  if (!mpUQFileTextBox->text().trimmed().isEmpty()) {
    args << QString("--uqFile=%1").arg(mpUQFileTextBox->text().trimmed());
  }
  args << QString("--calibrationOutput=%1").arg(outputFile);
  args << fileName;
  QString process;
#if defined(_WIN32)
  process = QString("python");
  args.prepend("OMSimulator");
  args.prepend("-m");
  QProcessEnvironment processEnvironment = QProcessEnvironment::systemEnvironment();
  QString OMHOME = QString(Helper::OpenModelicaHome);
  const QString omsLib = OMHOME + "/lib/" + HOST_SHORT + "/omc";
  processEnvironment.insert("PYTHONPATH",  OMHOME + "/bin;" + omsLib + ";" + processEnvironment.value("PYTHONPATH"));
  processEnvironment.insert("PATH",  OMHOME + "/bin;" + omsLib + ";" + processEnvironment.value("PATH"));
  mpCalibrationProcess->setProcessEnvironment(processEnvironment);
#else
  process = QString("%1/bin/OMSimulator").arg(Helper::OpenModelicaHome);
#endif
  writeOutput(QString("%1 %2\n").arg(process, args.join(" ")), StringHandler::OMEditInfo);
  mpCalibrationProcess->start(process, args);
}

void OMSCalibrationDialog::readStandardOutput()
{
  writeOutput(QString(mpCalibrationProcess->readAllStandardOutput()), StringHandler::Unknown);
}

void OMSCalibrationDialog::readStandardError()
{
  writeOutput(QString(mpCalibrationProcess->readAllStandardError()), StringHandler::Error);
}

void OMSCalibrationDialog::calibrationProcessError(QProcess::ProcessError error)
{
  writeOutput(mpCalibrationProcess->errorString() + "\n", StringHandler::Error);
  if (error == QProcess::FailedToStart) {
    mpCalibrateButton->setEnabled(true);
  }
}

void OMSCalibrationDialog::calibrationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mpCalibrateButton->setEnabled(true);
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    writeOutput(tr("The calibrated model is written to %1.\n").arg(mpOutputFileTextBox->text().trimmed()), StringHandler::OMEditInfo);
  } else {
    writeOutput(tr("The calibration failed with exit code %1.\n").arg(exitCode), StringHandler::Error);
  }
}

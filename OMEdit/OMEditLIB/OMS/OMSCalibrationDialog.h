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

#ifndef OMSCALIBRATIONDIALOG_H
#define OMSCALIBRATIONDIALOG_H

#include "Util/Utilities.h"
#include "Util/StringHandler.h"

#include <QDialog>
#include <QDialogButtonBox>
#include <QProcess>

class LibraryTreeItem;
class OutputPlainTextEdit;

class OMSCalibrationDialog : public QDialog
{
  Q_OBJECT
public:
  OMSCalibrationDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent = 0);
  ~OMSCalibrationDialog();
private:
  LibraryTreeItem *mpLibraryTreeItem;
  Label *mpHeadingLabel;
  QFrame *mpHorizontalLine;
  Label *mpActivityLabel;
  QLineEdit *mpActivityTextBox;
  Label *mpUQFileLabel;
  QLineEdit *mpUQFileTextBox;
  Label *mpOutputFileLabel;
  QLineEdit *mpOutputFileTextBox;
  QPushButton *mpBrowseOutputFileButton;
  OutputPlainTextEdit *mpOutputPlainTextEdit;
  QPushButton *mpCalibrateButton;
  QPushButton *mpCloseButton;
  QDialogButtonBox *mpButtonBox;
  QProcess *mpCalibrationProcess;

  void writeOutput(const QString &output, StringHandler::SimulationMessageType type);
private slots:
  void browseOutputFile();
  void calibrate();
  void readStandardOutput();
  void readStandardError();
  void calibrationProcessError(QProcess::ProcessError error);
  void calibrationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
};

#endif // OMSCALIBRATIONDIALOG_H

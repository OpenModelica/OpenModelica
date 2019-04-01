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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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
 * @author Alachew Mengist <alachew.mengist@liu.se>
 */

#ifndef IMPORTFMUMODELDESCRIPTIONDIALOG_H
#define IMPORTFMUMODELDESCRIPTIONDIALOG_H

#include <QDialog>
#include <QLineEdit>

class Label;
class ImportFMUModelDescriptionDialog : public QDialog
{
  Q_OBJECT
public:
  ImportFMUModelDescriptionDialog(QWidget *pParent = 0);
private:
  Label *mpFmuModelDescriptionLabel;
  QLineEdit *mpFmuModelDescriptionTextBox;
  QPushButton *mpBrowseFileButton;
  Label *mpOutputDirectoryLabel;
  QLineEdit *mpOutputDirectoryTextBox;
  Label *mpOutputDirectoryNoteLabel;
  QPushButton *mpBrowseDirectoryButton;
  QPushButton *mpImportButton;
private slots:
  void setSelectedFile();
  void setSelectedDirectory();
  void importFMUModelDescription();
};

#endif // IMPORTFMUMODELDESCRIPTIONDIALOG_H

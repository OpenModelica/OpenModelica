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

#ifndef FINDREPLACEDIALOG_H
#define FINDREPLACEDIALOG_H

#include <QtGui>
#include "Utilities.h"
#include "BaseEditor.h"

class FindReplaceDialog : public QDialog
{
  Q_OBJECT
public:
  FindReplaceDialog(QWidget *pParent);
  enum { MaxFindTexts = 20};
  void show();
  void setTextEdit(BaseEditor *pBaseEditor);
  void readFindTextFromSettings();
  void saveFindTextToSettings(QString textToFind);
private:
  BaseEditor *mpBaseEditor;
  Label *mpFindLabel;
  QComboBox *mpFindComboBox;
  Label *mpReplaceWithLabel;
  QLineEdit *mpReplaceWithTextBox;
  QGroupBox *mpDirectionGroupBox;
  QRadioButton *mpForwardRadioButton;
  QRadioButton *mpBackwardRadioButton;
  QGroupBox *mpOptionsBox;
  QCheckBox *mpCaseSensitiveCheckBox;
  QCheckBox *mpWholeWordCheckBox;
  QCheckBox *mpRegularExpressionCheckBox;
  QPushButton *mpFindButton;
  QPushButton *mpReplaceButton;
  QPushButton *mpReplaceAllButton;
  QPushButton *mpCloseButton;
  QSettings *mSettings;
public slots:
  void find();
  void findText(bool next);
  void replace();
  void replaceAll();
  void updateButtons();
protected slots:
  void validateRegularExpression(const QString &text);
  void regularExpressionSelected(bool selected);
  void textToFindChanged();
};

#endif // FINDREPLACEDIALOG_H

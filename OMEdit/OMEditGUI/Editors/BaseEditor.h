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

#ifndef BASEEDITOR_H
#define BASEEDITOR_H

#include <QtGui>
#include "Utilities.h"

class LineNumberArea;

class BaseEditor : public QPlainTextEdit
{
  Q_OBJECT
public:
  BaseEditor(QWidget *pParent);
  int lineNumberAreaWidth();
  void lineNumberAreaPaintEvent(QPaintEvent *event);
  void goToLineNumber(int lineNumber);
private:
  LineNumberArea *mpLineNumberArea;
protected:
  virtual void resizeEvent(QResizeEvent *pEvent);
public slots:
  void updateLineNumberAreaWidth(int newBlockCount);
  void updateLineNumberArea(const QRect &rect, int dy);
  void highlightCurrentLine();
};

class LineNumberArea : public QWidget
{
public:
  LineNumberArea(BaseEditor *pEditor)
    : QWidget(pEditor)
  {
    mpEditor = pEditor;
  }
  QSize sizeHint() const
  {
    return QSize(mpEditor->lineNumberAreaWidth(), 0);
  }
protected:
  virtual void paintEvent(QPaintEvent *event)
  {
    mpEditor->lineNumberAreaPaintEvent(event);
  }
private:
  BaseEditor *mpEditor;
};

class GotoLineDialog : public QDialog
{
  Q_OBJECT
public:
  GotoLineDialog(BaseEditor *pBaseEditor, QWidget *pParent = 0);
  void show();

  BaseEditor *mpBaseEditor;
private:
  Label *mpLineNumberLabel;
  QLineEdit *mpLineNumberTextBox;
  QPushButton *mpOkButton;
private slots:
  void goToLineNumber();
};

#endif // BASEEDITOR_H

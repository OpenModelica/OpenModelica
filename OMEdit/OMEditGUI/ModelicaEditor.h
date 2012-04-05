/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 * Contributors 2011: Abhinn Kothari
 */

/*
 * RCS: $Id$
 */

#ifndef MODELICAEDITOR_H
#define MODELICAEDITOR_H

#include "ProjectTabWidget.h"

class ProjectTab;
class LineNumberArea;

class ModelicaEditor : public QPlainTextEdit
{
  Q_OBJECT
public:
  ModelicaEditor(ProjectTab *pParent);
  QStringList getModelsNames();
  void findText(const QString &text, bool forward);
  bool validateText();
  void lineNumberAreaPaintEvent(QPaintEvent *event);
  int lineNumberAreaWidth();

  ProjectTab *mpParentProjectTab;
  QString mLastValidText;
  QString mErrorString;
  QWidget *mpFindWidget;
  QLabel *mpSearchLabelImage;
  QLabel *mpSearchLabel;
  QLineEdit *mpSearchTextBox;
  QToolButton *mpPreviuosButton;
  QToolButton *mpNextButton;
  QCheckBox *mpMatchCaseCheckBox;
  QCheckBox *mpMatchWholeWordCheckBox;
  QToolButton *mpCloseButton;
  LineNumberArea *mpLineNumberArea;
protected:
  virtual void resizeEvent(QResizeEvent *event);
signals:
  bool focusOut();
private slots:
  void updateLineNumberAreaWidth(int newBlockCount);
  void highlightCurrentLine();
  void updateLineNumberArea(const QRect &rect, int dy);
public slots:
  void setPlainText(const QString &text);
  void hasChanged();
  void hideFindWidget();
  void updateButtons();
  void findNextText();
  void findPreviuosText();
};

class ModelicaTextSettings;

class ModelicaTextHighlighter : public QSyntaxHighlighter
{
  Q_OBJECT
public:
  ModelicaTextHighlighter(ModelicaTextSettings *pSettings, QTextDocument *pParent = 0);
  void initializeSettings();
  void highlightMultiLine(const QString &text);

  ModelicaTextSettings *mpModelicaTextSettings;
protected:
  virtual void highlightBlock(const QString &text);
private:
  struct HighlightingRule
  {
    QRegExp mPattern;
    QTextCharFormat mFormat;
  };
  QVector<HighlightingRule> mHighlightingRules;

  QRegExp mCommentStartExpression;
  QRegExp mCommentEndExpression;
  QRegExp mStringStartExpression;
  QRegExp mStringEndExpression;

  QTextCharFormat mTextFormat;
  QTextCharFormat mKeywordFormat;
  QTextCharFormat mTypeFormat;
  QTextCharFormat mFunctionFormat;
  QTextCharFormat mQuotationFormat;
  QTextCharFormat mSingleLineCommentFormat;
  QTextCharFormat mMultiLineCommentFormat;
  QTextCharFormat mNumberFormat;
public slots:
  void settingsChanged();
};

class LineNumberArea : public QWidget
{
public:
  LineNumberArea(ModelicaEditor *pModelicaEditor)
    : QWidget(pModelicaEditor)
  {
    mpModelicaEditor = pModelicaEditor;
  }
  QSize sizeHint() const
  {
    return QSize(mpModelicaEditor->lineNumberAreaWidth(), 0);
  }
protected:
  virtual void paintEvent(QPaintEvent *event)
  {
    mpModelicaEditor->lineNumberAreaPaintEvent(event);
  }
private:
  ModelicaEditor *mpModelicaEditor;
};

class GotoLineWidget : public QDialog
{
  Q_OBJECT
public:
  GotoLineWidget(ModelicaEditor *pModelicaEditor);
  void show();

  ModelicaEditor *mpModelicaEditor;
private:
  QLabel *mpLineNumberLabel;
  QLineEdit *mpLineNumberTextBox;
  QPushButton *mpOkButton;
private slots:
  void goToLineNumber();
};

#endif // MODELICAEDITOR_H

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

#ifndef MODELICATEXTWIDGET_H
#define MODELICATEXTWIDGET_H

#include <QToolButton>
#include <QSyntaxHighlighter>
#include <QSettings>

#include "MainWindow.h"
#include "Helper.h"

class ModelWidget;
class LineNumberArea;
class ModelicaTextWidget;

class CommentDefinition
{
public:
  CommentDefinition();
  CommentDefinition &setAfterWhiteSpaces(const bool);
  CommentDefinition &setSingleLine(const QString &singleLine);
  CommentDefinition &setMultiLineStart(const QString &multiLineStart);
  CommentDefinition &setMultiLineEnd(const QString &multiLineEnd);
  bool isAfterWhiteSpaces() const;
  const QString &singleLine() const;
  const QString &multiLineStart() const;
  const QString &multiLineEnd() const;
  bool hasSingleLineStyle() const;
  bool hasMultiLineStyle() const;
  void clearCommentStyles();
private:
  bool m_afterWhiteSpaces;
  QString m_singleLine;
  QString m_multiLineStart;
  QString m_multiLineEnd;
};

class ModelicaTextEdit : public QPlainTextEdit
{
  Q_OBJECT
public:
  ModelicaTextEdit(ModelicaTextWidget *pParent);
  void createActions();
  void setLastValidText(QString validText);
  QStringList getClassNames(QString *errorString);
  bool validateModelicaText();
  void lineNumberAreaPaintEvent(QPaintEvent *event);
  int lineNumberAreaWidth();
private:
  ModelicaTextWidget *mpModelicaTextWidget;
  QString mLastValidText;
  bool mTextChanged;
  LineNumberArea *mpLineNumberArea;
  QAction *mpToggleCommentSelectionAction;
protected:
  virtual void resizeEvent(QResizeEvent *pEvent);
  virtual void keyPressEvent(QKeyEvent *pEvent);
signals:
  bool focusOut();
private slots:
  void updateLineNumberAreaWidth(int newBlockCount);
  void highlightCurrentLine();
  void updateCursorPosition();
  void updateLineNumberArea(const QRect &rect, int dy);
  void showContextMenu(QPoint point);
public slots:
  void setPlainText(const QString &text);
  void hasChanged();
  void setLineWrapping();
  void toggleCommentSelection();
};

class ModelicaTextSettings;
class ModelicaTextHighlighter : public QSyntaxHighlighter
{
  Q_OBJECT
public:
  ModelicaTextHighlighter(ModelicaTextSettings *pSettings, MainWindow *pMainWindow, QTextDocument *pParent = 0);
  void initializeSettings();
  void highlightMultiLine(const QString &text);
protected:
  virtual void highlightBlock(const QString &text);
private:
  ModelicaTextSettings *mpModelicaTextSettings;
  MainWindow *mpMainWindow;
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
  LineNumberArea(ModelicaTextEdit *pModelicaEditor)
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
  ModelicaTextEdit *mpModelicaEditor;
};

class GotoLineDialog : public QDialog
{
  Q_OBJECT
public:
  GotoLineDialog(ModelicaTextEdit *pModelicaEditor, MainWindow *pMainWindow);
  void show();

  ModelicaTextEdit *mpModelicaEditor;
private:
  Label *mpLineNumberLabel;
  QLineEdit *mpLineNumberTextBox;
  QPushButton *mpOkButton;
private slots:
  void goToLineNumber();
};

class ModelicaTextWidget : public QWidget
{
  Q_OBJECT
public:
  ModelicaTextWidget(ModelWidget *pParent);
  ModelWidget* getModelWidget();
  ModelicaTextEdit* getModelicaTextEdit();
private:
  ModelWidget *mpModelWidget;
  ModelicaTextEdit *mpModelicaTextEdit;
};

class FindReplaceDialog : public QDialog
{
  Q_OBJECT
public:
  FindReplaceDialog(QWidget *pParent);
  enum { MaxFindTexts = 20};
  void show();
  void setTextEdit(ModelicaTextEdit *pModelicaTextEdit);
  void readFindTextFromSettings();
  void saveFindTextToSettings(QString textToFind);
private:
  ModelicaTextEdit *mpModelicaTextEdit;
  Label *mpMessageLabel;
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
protected:
  void showError(const QString &error);
  void showMessage(const QString &message);
protected slots:
  void validateRegularExpression(const QString &text);
  void regularExpressionSelected(bool selected);
  void textToFindChanged();
};
#endif // MODELICATEXTWIDGET_H

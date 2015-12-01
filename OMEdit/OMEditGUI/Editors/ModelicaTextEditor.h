/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#ifndef MODELICATEXTEDITOR_H
#define MODELICATEXTEDITOR_H

#include <QSyntaxHighlighter>

#include "MainWindow.h"
#include "Helper.h"
#include "Utilities.h"
#include "BaseEditor.h"

class MainWindow;
class ModelWidget;

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

class ModelicaTextEditor : public BaseEditor
{
  Q_OBJECT
public:
  ModelicaTextEditor(ModelWidget *pParent);
  QString getLastValidText() {return mLastValidText;}
  QStringList getClassNames(QString *errorString);
  bool validateText();
  void setModelicaTextDocument(QTextDocument *document);
private:
  QString mLastValidText;
  bool mTextChanged;
  bool mForceSetPlainText;
private slots:
  virtual void showContextMenu(QPoint point);
public slots:
  void setPlainText(const QString &text);
  virtual void contentsHasChanged(int position, int charsRemoved, int charsAdded);
  virtual void toggleCommentSelection();
};

/**
 * @class ModelicaTextDocumentLayout
 * Implements a custom text layout for ModelciatextEditor to be able to
 * Works with QTextDocument::setDocumentLayout().
 */
class ModelicaTextDocumentLayout : public QPlainTextDocumentLayout
{
  Q_OBJECT
public:
  ModelicaTextDocumentLayout(QTextDocument *doc) : QPlainTextDocumentLayout(doc), mpHasBreakpoint(false) {}
  static TextBlockUserData *testUserData(const QTextBlock &block)
  {
    return static_cast<TextBlockUserData*>(block.userData());
  }
  static TextBlockUserData *userData(const QTextBlock &block)
  {
    TextBlockUserData *data = static_cast<TextBlockUserData*>(block.userData());
    if (!data && block.isValid()) {
      const_cast<QTextBlock&>(block).setUserData((data = new TextBlockUserData));
    }
    return data;
  }
  void emitDocumentSizeChanged() {emit documentSizeChanged(documentSize());}
  bool mpHasBreakpoint;
};

class ModelicaTextEditorPage;
class ModelicaTextHighlighter : public QSyntaxHighlighter
{
  Q_OBJECT
public:
  ModelicaTextHighlighter(ModelicaTextEditorPage *pModelicaTextEditorPage, QPlainTextEdit *pPlainTextEdit = 0);
  void initializeSettings();
  void highlightMultiLine(const QString &text);
protected:
  virtual void highlightBlock(const QString &text);
private:
  ModelicaTextEditorPage *mpModelicaTextEditorPage;
  QPlainTextEdit *mpPlainTextEdit;
  struct HighlightingRule
  {
    QRegExp mPattern;
    QTextCharFormat mFormat;
  };
  QVector<HighlightingRule> mHighlightingRules;
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

#endif // MODELICATEXTEDITOR_H

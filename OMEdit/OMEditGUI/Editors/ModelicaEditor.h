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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef MODELICAEDITOR_H
#define MODELICAEDITOR_H

#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Editors/BaseEditor.h"

#include <QSyntaxHighlighter>

class ModelWidget;
class LibraryTreeItem;

class ModelicaEditor : public BaseEditor
{
  Q_OBJECT
public:
  ModelicaEditor(QWidget *pParent);
  QString getLastValidText() {return mLastValidText;}
  QStringList getClassNames(QString *errorString);
  bool validateText(LibraryTreeItem **pLibraryTreeItem);
  QString removeLeadingSpaces(QString contents);
  void storeLeadingSpaces(QMap<int, int> leadingSpacesMap);
  QString getPlainText();
  void setTextChanged(bool changed) {mTextChanged = changed;}
  bool isTextChanged() {return mTextChanged;}
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

class ModelicaEditorPage;
class ModelicaHighlighter : public QSyntaxHighlighter
{
  Q_OBJECT
public:
  ModelicaHighlighter(ModelicaEditorPage *pModelicaEditorPage, QPlainTextEdit *pPlainTextEdit = 0);
  void initializeSettings();
  void highlightMultiLine(const QString &text);
protected:
  virtual void highlightBlock(const QString &text);
private:
  ModelicaEditorPage *mpModelicaEditorPage;
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

#endif // MODELICAEDITOR_H

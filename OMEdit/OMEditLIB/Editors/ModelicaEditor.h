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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef MODELICAEDITOR_H
#define MODELICAEDITOR_H

#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Editors/BaseEditor.h"
#include "LSP/LSPProtocol.h"

#include <QPoint>
#include <QPointer>
#include <QRegExp>
#include <QSyntaxHighlighter>

class ModelWidget;
class LibraryTreeItem;
class LSPClient;
class QAction;
class QTimer;
class QTextCursor;
class QTextBlock;

class ModelicaEditor : public BaseEditor
{
  Q_OBJECT
public:
  ModelicaEditor(QWidget *pParent);
  ~ModelicaEditor();
  QString getLastValidText() {return mLastValidText;}
  QStringList getClassNames(QString *errorString);
  bool validateText(LibraryTreeItem **pLibraryTreeItem);
  void storeLeadingSpaces(QMap<int, int> leadingSpacesMap);
  QString getPlainText();
  void setTextChanged(bool changed) {mTextChanged = changed;}
  bool isTextChanged() {return mTextChanged;}
  virtual void popUpCompleter() override;
  virtual QString wordUnderCursor() override;
  virtual void symbolAtPosition(const QPoint &pos) override;
  QString stringAfterWord(const QString &word);
  static LibraryTreeItem *deepResolve(LibraryTreeItem *pItem, QStringList nameComponents);
  static QList<LibraryTreeItem *> getCandidateContexts(LibraryTreeItem *pLibraryTreeItem, QStringList nameComponents);
  static void tryToCompleteInSingleContext(QStringList &result, LibraryTreeItem *pItem, QString lastPart);
  static void getCompletionSymbols(LibraryTreeItem *pLibraryTreeItem, QString word, QList<CompleterItem> &classes, QList<CompleterItem> &components);
  static LibraryTreeItem *getAnnotationCompletionRoot();
  static void getCompletionAnnotations(const QStringList &stack, QList<CompleterItem> &annotations);
  static bool getCompletionAnnotations(const QString &str, QList<CompleterItem> &annotations);
  static QList<CompleterItem> getCodeSnippets();
  bool eventFilter(QObject *pObject, QEvent *pEvent) override;
private:
  QString mLastValidText;
  bool mTextChanged;
  int mPendingHoverRequestId;
  int mPendingDefinitionRequestId;
  QPoint mLastToolTipGlobalPos;
  QPointer<LSPClient> mConnectedLSPClient;
  bool mLSPDocumentOpened;
  QString mLSPDocumentUri;
  QString mDefinitionFallbackWord;
  QTimer *mpContentChangeTimer;
  QTimer *mpDefinitionFallbackTimer;
  QString documentUri() const;
  QString documentText();
  void lspPositionForCursor(const QTextCursor &cursor, int &line, int &character);
  int leadingSpacesForBlock(const QTextBlock &block);
  bool ensureLanguageServerConnected();
  void notifyLanguageServerContentChanged();
  void flushPendingContentChange();
  void requestDefinitionAt(const QPoint &pos);
  bool navigateToLSPLocation(const LSP::Location &location);
  void navigateToClassFallback();
private slots:
  virtual void showContextMenu(QPoint point) override;
  void onLSPHoverResult(int requestId, const QString &content);
  void onLSPDefinitionResult(int requestId, const LSP::Location &location);
  void sendLanguageServerContentChange();
  void onDefinitionFallbackTimeout();
public slots:
  void setPlainText(const QString &text, bool useInserText = true);
  virtual void contentsHasChanged(int position, int charsRemoved, int charsAdded) override;
  virtual void toggleCommentSelection() override;
};

class ModelicaEditorPage;
class ModelicaHighlighter : public QSyntaxHighlighter
{
  Q_OBJECT
public:
  ModelicaHighlighter(ModelicaEditorPage *pModelicaEditorPage, QPlainTextEdit *pPlainTextEdit = 0);
  void initializeSettings();
  void highlightMultiLine(const QString &text);
  static QStringList getKeywords();
  static QStringList getTypes();
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

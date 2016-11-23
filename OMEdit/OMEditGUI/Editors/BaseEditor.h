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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef BASEEDITOR_H
#define BASEEDITOR_H

#include "Debugger/Breakpoints/BreakpointMarker.h"

#include <QDialog>
#include <QComboBox>
#include <QLineEdit>
#include <QCheckBox>
#include <QToolButton>

class ModelWidget;
class InfoBar;
class LineNumberArea;
class FindReplaceWidget;
class Label;

class TabSettings
{
public:
  enum TabPolicy {
    SpacesOnlyTabPolicy = 0,
    TabsOnlyTabPolicy = 1
  };
  TabSettings();
  void setTabPolicy(int tabPolicy) {mTabPolicy = (TabPolicy)tabPolicy;}
  TabPolicy getTabPolicy() const {return mTabPolicy;}
  void setTabSize(int tabSize) {mTabSize = tabSize;}
  int getTabSize() const {return mTabSize;}
  void setIndentSize(int indentSize) {mIndentSize = indentSize;}
  int getIndentSize() {return mIndentSize;}

  int lineIndentPosition(const QString &text) const;
  int columnAt(const QString &text, int position) const;
  int indentedColumn(int column, bool doIndent = true) const;
  QString indentationString(int startColumn, int targetColumn) const;

  static int firstNonSpace(const QString &text);
  static int spacesLeftFromPosition(const QString &text, int position);
  static bool cursorIsAtBeginningOfLine(const QTextCursor &cursor);
private:
  TabPolicy mTabPolicy;
  int mTabSize;
  int mIndentSize;
};

struct Parenthesis
{
  enum Type {Opened, Closed};
  inline Parenthesis() : type(Opened), pos(-1) {}
  inline Parenthesis(Type t, QChar c, int position)
      : type(t), chr(c), pos(position) {}
  Type type;
  QChar chr;
  int pos;
};
typedef QVector<Parenthesis> Parentheses;

/**
 * @class TextBlockUserData
 * Stores breakpoints for text block
 * Works with QTextBlock::setUserData().
 */
class TextBlockUserData : public QTextBlockUserData
{
public:
  inline TextBlockUserData()
    : mFoldingIndent(0)
    , mFolded(false)
    , mFoldingEndIncluded(false)
    , mFoldingState(false)
    , mLeadingSpaces(-1)
  {}
  ~TextBlockUserData();

  inline TextMarks marks() const { return _marks; }
  inline void addMark(ITextMark *mark) { _marks += mark; }
  inline bool removeMark(ITextMark *mark) { return _marks.removeAll(mark); }
  inline bool hasMark(ITextMark* mark) const { return _marks.contains(mark); }
  inline void clearMarks() { _marks.clear(); }
  inline void documentClosing()
  {
    foreach (ITextMark *tm, _marks) {
       tm->documentClosing();
    }
    _marks.clear();
  }

  void setParentheses(const Parentheses &parentheses) {mParentheses = parentheses;}
  Parentheses parentheses() {return mParentheses;}
  inline void clearParentheses() {mParentheses.clear();}
  inline bool hasParentheses() const {return !mParentheses.isEmpty();}
  enum MatchType {NoMatch, Match, Mismatch};
  static MatchType checkOpenParenthesis(QTextCursor *cursor, QChar c);
  static MatchType checkClosedParenthesis(QTextCursor *cursor, QChar c);
  static MatchType matchCursorBackward(QTextCursor *cursor);
  static MatchType matchCursorForward(QTextCursor *cursor);

  /* Set the code folding level.
   * A code folding marker will appear the line *before* the one where the indention
   * level increases. The code folding region will end in the last line that has the same
   * indention level (or higher).
   */
  inline int foldingIndent() const {return mFoldingIndent;}
  inline void setFoldingIndent(int indent) {mFoldingIndent = indent;}
  inline void setFolded(bool b) {mFolded = b;}
  inline bool folded() const {return mFolded;}
  // Set whether the last character of the folded region will show when the code is folded.
  inline void setFoldingEndIncluded(bool foldingEndIncluded) {mFoldingEndIncluded = foldingEndIncluded;}
  inline bool foldingEndIncluded() const {return mFoldingEndIncluded;}
  inline void setFoldingState(bool foldingState) {mFoldingState = foldingState;}
  inline bool foldingState() const {return mFoldingState;}

  inline void setLeadingSpaces(int leadingSpaces) {mLeadingSpaces = leadingSpaces;}
  inline int getLeadingSpaces() {return mLeadingSpaces;}
private:
  TextMarks _marks;
  Parentheses mParentheses;
  int mFoldingIndent;
  bool mFolded;
  bool mFoldingEndIncluded;
  bool mFoldingState;
  int mLeadingSpaces;
};

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

class BaseEditorDocumentLayout : public QPlainTextDocumentLayout
{
  Q_OBJECT
public:
  BaseEditorDocumentLayout(QTextDocument *document);
  static Parentheses parentheses(const QTextBlock &block);
  static bool hasParentheses(const QTextBlock &block);
  static void setFoldingIndent(const QTextBlock &block, int indent);
  static int foldingIndent(const QTextBlock &block);
  static bool canFold(const QTextBlock &block);
  static void foldOrUnfold(const QTextBlock& block, bool unfold);
  static bool isFolded(const QTextBlock &block);
  static void setFolded(const QTextBlock &block, bool folded);
  static TextBlockUserData *testUserData(const QTextBlock &block);
  static TextBlockUserData *userData(const QTextBlock &block);
  void emitDocumentSizeChanged() {emit documentSizeChanged(documentSize());}
  bool mHasBreakpoint;
};

class BaseEditor : public QWidget
{
  Q_OBJECT
private:
  class PlainTextEdit : public QPlainTextEdit
  {
  public:
    PlainTextEdit(BaseEditor *pBaseEditor);
    LineNumberArea* getLineNumberArea() {return mpLineNumberArea;}
    int lineNumberAreaWidth();
    void lineNumberAreaPaintEvent(QPaintEvent *event);
    void lineNumberAreaMouseEvent(QMouseEvent *event);
    void goToLineNumber(int lineNumber);
    void updateLineNumberAreaWidth(int newBlockCount);
    void updateLineNumberArea(const QRect &rect, int dy);
    void updateHighlights();
    void updateCursorPosition();
    void setLineWrapping();
    void toggleBreakpoint(const QString fileName, int lineNumber);
    void indentOrUnindent(bool doIndent);
    void moveCursorVisible(bool ensureVisible = true);
    void ensureCursorVisible();
  private:
    BaseEditor *mpBaseEditor;
    LineNumberArea *mpLineNumberArea;
    QTextCharFormat mParenthesesMatchFormat;
    QTextCharFormat mParenthesesMisMatchFormat;

    void highlightCurrentLine();
    void highlightParentheses();
    QString plainTextFromSelection(const QTextCursor &cursor) const;
    static QString convertToPlainText(const QString &txt);
  protected:
    virtual void resizeEvent(QResizeEvent *pEvent);
    virtual void keyPressEvent(QKeyEvent *pEvent);
    virtual QMimeData* createMimeDataFromSelection() const;
    virtual void focusInEvent(QFocusEvent *event);
    virtual void focusOutEvent(QFocusEvent *event);
    void paintEvent(QPaintEvent *e);
  };
public:
  BaseEditor(QWidget *pParent);
  ModelWidget *getModelWidget() {return mpModelWidget;}
  InfoBar* getInfoBar() {return mpInfoBar;}
  PlainTextEdit *getPlainTextEdit() {return mpPlainTextEdit;}
  FindReplaceWidget* getFindReplaceWidget() {return mpFindReplaceWidget;}
  void setCanHaveBreakpoints(bool canHaveBreakpoints);
  bool canHaveBreakpoints() {return mCanHaveBreakpoints;}
  QAction *getToggleBreakpointAction() {return mpToggleBreakpointAction;}
  DocumentMarker* getDocumentMarker() {return mpDocumentMarker;}
  void goToLineNumber(int lineNumber);
  void toggleBlockVisible(const QTextBlock &block);
private:
  void initialize();
  void createActions();
  void foldOrUnfold(bool unFold);
protected:
  ModelWidget *mpModelWidget;
  InfoBar *mpInfoBar;
  PlainTextEdit *mpPlainTextEdit;
  FindReplaceWidget *mpFindReplaceWidget;
  bool mCanHaveBreakpoints;
  QAction *mpFindReplaceAction;
  QAction *mpClearFindReplaceTextsAction;
  QAction *mpGotoLineNumberAction;
  QAction *mpShowTabsAndSpacesAction;
  QAction *mpToggleBreakpointAction;
  QAction *mpToggleCommentSelectionAction;
  QAction *mpFoldAllAction;
  QAction *mpUnFoldAllAction;
  DocumentMarker *mpDocumentMarker;

  QMenu* createStandardContextMenu();
private slots:
  virtual void showContextMenu(QPoint point) = 0;
public slots:
  void textSettingsChanged();
  void updateLineNumberAreaWidth(int newBlockCount);
  void updateLineNumberArea(const QRect &rect, int dy);
  void updateHighlights();
  void updateCursorPosition();
  virtual void contentsHasChanged(int position, int charsRemoved, int charsAdded) = 0;
  void showFindReplaceWidget();
  void clearFindReplaceTexts();
  void showGotoLineNumberDialog();
  void showTabsAndSpaces(bool On);
  void toggleBreakpoint();
  virtual void toggleCommentSelection();
  void foldAll();
  void unFoldAll();
};

class LineNumberArea : public QWidget
{
public:
  LineNumberArea(BaseEditor *pBaseEditor, QWidget *pParent)
    : QWidget(pParent)
  {
    mpBaseEditor = pBaseEditor;
  }
  QSize sizeHint() const
  {
    return QSize(mpBaseEditor->getPlainTextEdit()->lineNumberAreaWidth(), 0);
  }
protected:
  virtual void paintEvent(QPaintEvent *event)
  {
    mpBaseEditor->getPlainTextEdit()->lineNumberAreaPaintEvent(event);
  }
  virtual void mouseMoveEvent(QMouseEvent *event)
  {
    mpBaseEditor->getPlainTextEdit()->lineNumberAreaMouseEvent(event);
  }
  virtual void mousePressEvent(QMouseEvent *event)
  {
    mpBaseEditor->getPlainTextEdit()->lineNumberAreaMouseEvent(event);
  }
private:
  BaseEditor *mpBaseEditor;
};

class FindReplaceWidget : public QWidget
{
  Q_OBJECT
public:
  FindReplaceWidget(BaseEditor *pBaseEditor);
  enum {MaxFindTexts = 20};
  void show();
  void readFindTextFromSettings();
  void saveFindTextToSettings(QString textToFind);
private:
  BaseEditor *mpBaseEditor;
  Label *mpFindLabel;
  QComboBox *mpFindComboBox;
  QPushButton *mpFindPreviousButton;
  QPushButton *mpFindNextButton;
  QPushButton *mpCloseButton;
  Label *mpReplaceWithLabel;
  QLineEdit *mpReplaceWithTextBox;
  QCheckBox *mpCaseSensitiveCheckBox;
  QCheckBox *mpWholeWordCheckBox;
  QCheckBox *mpRegularExpressionCheckBox;
  QPushButton *mpReplaceButton;
  QPushButton *mpReplaceAllButton;

  void findText(bool next);
public slots:
  void findPrevious();
  void findNext();
  bool close();
  void replace();
  void replaceAll();
protected:
  virtual void keyPressEvent(QKeyEvent *pEvent);
protected slots:
  void validateRegularExpression(const QString &text);
  void regularExpressionSelected(bool selected);
  void textToFindChanged();
};

class GotoLineDialog : public QDialog
{
  Q_OBJECT
public:
  GotoLineDialog(BaseEditor *pBaseEditor);
private:
  BaseEditor *mpBaseEditor;
  Label *mpLineNumberLabel;
  QLineEdit *mpLineNumberTextBox;
  QPushButton *mpOkButton;
public slots:
  int exec();
private slots:
  void goToLineNumber();
};

class InfoBar : public QFrame
{
public:
  InfoBar(QWidget *pParent);
  void showMessage(QString message);
private:
  Label *mpInfoLabel;
  QToolButton *mpCloseButton;
};

#endif // BASEEDITOR_H

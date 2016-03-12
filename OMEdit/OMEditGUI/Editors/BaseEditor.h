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
 *
 */

#ifndef BASEEDITOR_H
#define BASEEDITOR_H

#include <QtGui>
#include "BreakpointMarker.h"
#include "Utilities.h"

class ModelWidget;
class LineNumberArea;
class FindReplaceWidget;

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
  inline TextBlockUserData() {mLeadingSpaces = -1;}
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
  inline void setLeadingSpaces(int leadingSpaces) {mLeadingSpaces = leadingSpaces;}
  inline int getLeadingSpaces() {return mLeadingSpaces;}
private:
  TextMarks _marks;
  QVector<Parenthesis> mParentheses;
  int mLeadingSpaces;
};

class BaseEditorDocumentLayout : public QPlainTextDocumentLayout
{
  Q_OBJECT
public:
  BaseEditorDocumentLayout(QTextDocument *document);
  static Parentheses parentheses(const QTextBlock &block);
  static bool hasParentheses(const QTextBlock &block);
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
  };
public:
  BaseEditor(MainWindow *pMainWindow);
  BaseEditor(ModelWidget *pModelWidget);
  ModelWidget *getModelWidget() {return mpModelWidget;}
  MainWindow* getMainWindow() {return mpMainWindow;}
  PlainTextEdit *getPlainTextEdit() {return mpPlainTextEdit;}
  FindReplaceWidget* getFindReplaceWidget() {return mpFindReplaceWidget;}
  void setCanHaveBreakpoints(bool canHaveBreakpoints);
  bool canHaveBreakpoints() {return mCanHaveBreakpoints;}
  QAction *getToggleBreakpointAction() {return mpToggleBreakpointAction;}
  DocumentMarker* getDocumentMarker() {return mpDocumentMarker;}
  void goToLineNumber(int lineNumber);
private:
  void initialize();
  void createActions();
protected:
  ModelWidget *mpModelWidget;
  MainWindow *mpMainWindow;
  PlainTextEdit *mpPlainTextEdit;
  FindReplaceWidget *mpFindReplaceWidget;
  bool mCanHaveBreakpoints;
  QAction *mpFindReplaceAction;
  QAction *mpClearFindReplaceTextsAction;
  QAction *mpGotoLineNumberAction;
  QAction *mpShowTabsAndSpacesAction;
  QAction *mpToggleBreakpointAction;
  QAction *mpToggleCommentSelectionAction;
  DocumentMarker *mpDocumentMarker;

  QMenu* createStandardContextMenu();
private slots:
  virtual void showContextMenu(QPoint point) = 0;
public slots:
  void updateLineNumberAreaWidth(int newBlockCount);
  void updateLineNumberArea(const QRect &rect, int dy);
  void updateHighlights();
  void updateCursorPosition();
  virtual void contentsHasChanged(int position, int charsRemoved, int charsAdded) = 0;
  void setLineWrapping();
  void showFindReplaceWidget();
  void clearFindReplaceTexts();
  void showGotoLineNumberDialog();
  void showTabsAndSpaces(bool On);
  void toggleBreakpoint();
  virtual void toggleCommentSelection() = 0;
};

class LineNumberArea : public QWidget
{
public:
  LineNumberArea(BaseEditor *pBaseEditor)
    : QWidget(pBaseEditor)
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

#endif // BASEEDITOR_H

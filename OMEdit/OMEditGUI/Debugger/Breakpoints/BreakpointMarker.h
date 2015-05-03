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
 * RCS: $Id: BreakpointMarker.h 22254 2014-09-10 12:36:43Z adeas31 $
 *
 */

#ifndef BREAKPOINTMARKER_H
#define BREAKPOINTMARKER_H

#include <QIcon>
#include <QFileInfo>
#include <QtGui/QTextBlockUserData>
#include <QtGui/QPlainTextDocumentLayout>

class ModelicaTextEditor;
class BreakpointsTreeModel;
class ITextMark : public QObject
{
  Q_OBJECT
public:
  ITextMark(QObject *parent = 0) : QObject(parent) { }
  virtual ~ITextMark() { }

  virtual QIcon icon() const = 0;
  virtual void updateLineNumber(int lineNumber) = 0;
  virtual void updateBlock(const QTextBlock &block) = 0;
  virtual void removeFromEditor() = 0;
  virtual void documentClosing() = 0;
};

typedef QList<ITextMark*> TextMarks;

class ITextMarkable : public QObject
{
  Q_OBJECT
public:
  ITextMarkable(QObject *parent = 0) : QObject(parent) { }
  virtual ~ITextMarkable() { }

  virtual bool addMark(ITextMark *mark, int line) = 0;
  virtual TextMarks marksAt(int line) const = 0;
  virtual void removeMark(ITextMark *mark) = 0;
  virtual bool hasMark(ITextMark *mark) const = 0;
  virtual void updateMark(ITextMark *mark) = 0;
};

class BreakpointMarker : public ITextMark
{
  Q_OBJECT
public:
  BreakpointMarker(const QString &fileName, int lineNumber, BreakpointsTreeModel *pBreakpointsTreeModel);

  // ITextMark
  // returns Breakpoint icon
  virtual QIcon icon() const;
  // called if the lineNumber changes
  virtual void updateLineNumber(int lineNumber);
  // called whenever the text of the block for the marker changed
  virtual void updateBlock(const QTextBlock &block);
  // called if the block containing this mark has been removed
  // if this also removes your mark call this->deleteLater();
  virtual void removeFromEditor();
  virtual void documentClosing();

  void setFilePath(QString filePath) {mpFileName = filePath;}
  inline QString filePath() const { return mpFileName; }
  inline QString fileName() const { return QFileInfo(mpFileName).fileName(); }
  inline QString path() const { return QFileInfo(mpFileName).path(); }
  inline QString lineText() const { return mpLineText; }
  void setLineNumber(int lineNumber) {mpLineNumber = lineNumber;}
  inline int lineNumber() const { return mpLineNumber; }
  void setEnabled(bool enable) {mEnabled = enable;}
  inline bool isEnabled() const {return mEnabled;}
  void setIgnoreCount(int ignoreCount) {mIgnoreCount = ignoreCount;}
  inline int getIgnoreCount() {return mIgnoreCount;}
  void setCondition(QString condition) {mCondition = condition;}
  inline QString getCondition() {return mCondition;}
private:
  BreakpointsTreeModel *mpBreakpointsTreeModel;
  QString mpFileName;
  int mpLineNumber;
  QString mpLineText;
  bool mEnabled;
  int mIgnoreCount;
  QString mCondition;
};

/**
 * @class TextBlockUserData
 * Stores breakpoints for text block
 * Works with QTextBlock::setUserData().
 */
class TextBlockUserData : public QTextBlockUserData
{
public:
  inline TextBlockUserData()
  { }
  ~TextBlockUserData();

  inline TextMarks marks() const { return _marks; }
  inline void addMark(ITextMark *mark) { _marks += mark; }
  inline bool removeMark(ITextMark *mark) { return _marks.removeAll(mark); }
  inline bool hasMark(ITextMark* mark) const { return _marks.contains(mark); }
  inline void clearMarks() { _marks.clear(); }
  inline void documentClosing()
  {
    foreach (ITextMark *tm, _marks)
    {
       tm->documentClosing();
    }
    _marks.clear();
  }
private:
  TextMarks _marks;
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
  ModelicaTextDocumentLayout(QTextDocument *doc);
  ~ModelicaTextDocumentLayout();

  static TextBlockUserData *testUserData(const QTextBlock &block)
  {
    return static_cast<TextBlockUserData*>(block.userData());
  }
  static TextBlockUserData *userData(const QTextBlock &block)
  {
    TextBlockUserData *data = static_cast<TextBlockUserData*>(block.userData());
    if (!data && block.isValid())
      const_cast<QTextBlock&>(block).setUserData((data = new TextBlockUserData));
    return data;
  }
  void emitDocumentSizeChanged() { emit documentSizeChanged(documentSize()); }
  bool mpHasBreakpoint;
};

class DocumentMarker : public ITextMarkable
{
  Q_OBJECT
public:
  DocumentMarker(QTextDocument *);

  // ITextMarkable
  bool addMark(ITextMark *mark, int line);
  TextMarks marksAt(int line) const;
  void removeMark(ITextMark *mark);
  bool hasMark(ITextMark *mark) const;
  void updateMark(ITextMark *mark);

  void updateBreakpointsLineNumber();
  void updateBreakpointsBlock(const QTextBlock &block);

private:
  QTextDocument *mpTextDocument;
};

#endif // BREAKPOINTMARKER_H


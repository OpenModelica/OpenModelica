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

#ifndef BREAKPOINTMARKER_H
#define BREAKPOINTMARKER_H

#include <QIcon>
#include <QFileInfo>

#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QTextBlockUserData>
#include <QPlainTextDocumentLayout>
#else
#include <QtGui/QTextBlockUserData>
#include <QtGui/QPlainTextDocumentLayout>
#endif

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


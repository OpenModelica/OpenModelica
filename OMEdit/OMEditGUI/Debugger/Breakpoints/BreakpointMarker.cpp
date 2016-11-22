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

#include "BreakpointMarker.h"
#include "BreakpointsWidget.h"
#include "Editors/BaseEditor.h"

BreakpointMarker::BreakpointMarker(const QString &fileName, int lineNumber, BreakpointsTreeModel *pBreakpointsTreeModel)
    : ITextMark()
    , mpBreakpointsTreeModel(pBreakpointsTreeModel)
    , mpFileName(fileName)
    , mpLineNumber(lineNumber)
    , mEnabled(true)
    , mIgnoreCount(0)
    , mCondition("")
{

}

QIcon BreakpointMarker::icon() const
{
  return isEnabled() ? QIcon(":/Resources/icons/breakpoint_enabled.svg") : QIcon(":/Resources/icons/breakpoint_disabled.svg");
}

void BreakpointMarker::updateLineNumber(int lineNumber)
{
  if (lineNumber != mpLineNumber) {
    mpBreakpointsTreeModel->updateBreakpoint(this, lineNumber);
    mpLineNumber = lineNumber;
  }
}

void BreakpointMarker::updateBlock(const QTextBlock &block)
{
  if (mpLineText != block.text()) {
    mpLineText = block.text();
  }
}

void BreakpointMarker::removeFromEditor()
{
  mpBreakpointsTreeModel->removeBreakpoint(this);
}

void BreakpointMarker::documentClosing()
{
  // todo: impl
}

//! @class DocumentMarker
DocumentMarker::DocumentMarker(QTextDocument *doc)
  : ITextMarkable(doc) , mpTextDocument(doc)
{

}

bool DocumentMarker::addMark(ITextMark *mark, int line)
{
  if (line >= 1) {
    int blockNumber = line - 1;
    BaseEditorDocumentLayout *docLayout = qobject_cast<BaseEditorDocumentLayout*>(mpTextDocument->documentLayout());
    if (!docLayout) {
      return false;
    }
    QTextBlock block = mpTextDocument->findBlockByNumber(blockNumber);
    if (block.isValid()) {
      TextBlockUserData *userData = BaseEditorDocumentLayout::userData(block);
      userData->addMark(mark);
      mark->updateLineNumber(blockNumber + 1);
      mark->updateBlock(block);
      docLayout->mHasBreakpoint = true;
      docLayout->requestUpdate();
      return true;
    }
  }
  return false;
}

TextMarks DocumentMarker::marksAt(int line) const
{
  if (line >= 1) {
    int blockNumber = line - 1;
    QTextBlock block = mpTextDocument->findBlockByNumber(blockNumber);
    if (block.isValid()) {
      if (TextBlockUserData *userData = BaseEditorDocumentLayout::testUserData(block)) {
        return userData->marks();
      }
    }
  }
  return TextMarks();
}

void DocumentMarker::removeMark(ITextMark *mark)
{
  bool needUpdate = false;
  QTextBlock block = mpTextDocument->begin();
  while (block.isValid()) {
    if (TextBlockUserData *data = static_cast<TextBlockUserData *>(block.userData())) {
      needUpdate |= data->removeMark(mark);
    }
    block = block.next();
  }
  if (needUpdate) {
    updateMark(0);
  }
}

bool DocumentMarker::hasMark(ITextMark *mark) const
{
  QTextBlock block = mpTextDocument->begin();
  while (block.isValid()) {
    if (TextBlockUserData *data = static_cast<TextBlockUserData *>(block.userData())) {
      if (data->hasMark(mark)) {
        return true;
      }
    }
    block = block.next();
  }
  return false;
}

void DocumentMarker::updateMark(ITextMark *mark)
{
  Q_UNUSED(mark)
  BaseEditorDocumentLayout *docLayout = qobject_cast<BaseEditorDocumentLayout*>(mpTextDocument->documentLayout());
  if (docLayout)
    docLayout->requestUpdate();
}

void DocumentMarker::updateBreakpointsLineNumber()
{
  QTextBlock block = mpTextDocument->begin();
  int blockNumber = 0;
  while (block.isValid()) {
    if (const TextBlockUserData *userData = BaseEditorDocumentLayout::testUserData(block))
      foreach (ITextMark *mrk, userData->marks()) {
        mrk->updateLineNumber(blockNumber + 1);
      }
    block = block.next();
    ++blockNumber;
  }
}

void DocumentMarker::updateBreakpointsBlock(const QTextBlock &block)
{
  if (const TextBlockUserData *userData = BaseEditorDocumentLayout::testUserData(block))
    foreach (ITextMark *mrk, userData->marks())
      mrk->updateBlock(block);
}

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

#include "OutputPlainTextEdit.h"
#include "Util/Helper.h"

#include <QScrollBar>

OutputPlainTextEdit::OutputPlainTextEdit(QWidget *parent)
  : QPlainTextEdit(parent), mTextCursor(document())
{
  mQueuedOutput.clear();
  mQueueTimer.setSingleShot(true);
  mQueueTimer.setInterval(10);
  connect(&mQueueTimer, SIGNAL(timeout()), SLOT(handleNextOutputChunk()));
  mUseTimer = true;
}

void OutputPlainTextEdit::appendOutput(const QString &output, const QTextCharFormat &format)
{
  if (mUseTimer) {
    if (mQueuedOutput.isEmpty() || mQueuedOutput.last().second != format) {
      mQueuedOutput << qMakePair(output, format);
    } else {
      mQueuedOutput.last().first.append(output);
    }
    if (!mQueueTimer.isActive()) {
      mQueueTimer.start();
    }
  } else {
    handleOutputChunk(output, format);
  }
}

void OutputPlainTextEdit::handleOutputChunk(const QString &output, const QTextCharFormat &format)
{
  // move the cursor down before adding the output
  const bool atBottom = verticalScrollBar()->value() == verticalScrollBar()->maximum();
  if (!mTextCursor.atEnd()) {
    mTextCursor.movePosition(QTextCursor::End);
  }
  // insert the text
  mTextCursor.beginEditBlock();
  if (format.isValid()) {
    mTextCursor.insertText(output, format);
  } else {
    mTextCursor.insertText(output);
  }
  mTextCursor.endEditBlock();
  // move the cursor
  if (atBottom) {
    verticalScrollBar()->setValue(verticalScrollBar()->maximum());
    // QPlainTextEdit destroys the first calls value in case of multiline
    // text, so make sure that the scroll bar actually gets the value set.
    // Is a noop if the first call succeeded.
    verticalScrollBar()->setValue(verticalScrollBar()->maximum());
  }
}

void OutputPlainTextEdit::handleNextOutputChunk()
{
  if (!mQueuedOutput.isEmpty()) {
    auto &chunk = mQueuedOutput.first();
    if (chunk.first.size() <= chunkSize) {
      handleOutputChunk(chunk.first, chunk.second);
      mQueuedOutput.remove(0);
    } else {
      handleOutputChunk(chunk.first.left(chunkSize), chunk.second);
      chunk.first.remove(0, chunkSize);
    }
    if (!mQueuedOutput.isEmpty()) {
      mQueueTimer.start();
    }
  }
}

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

#include "MessagesWidget.h"
#include "Helper.h"

/*!
  \class MessageItem
  \brief Holds the error message data.
  */

/*!
  \param filename - the error filename.
  \param readOnly - the error file readOnly state.
  \param lineStart - the index where the error starts.
  \param columnStart - the indexed column where the error starts.
  \param lineEnd - the index where the error ends.
  \param columnEnd - the indexed column where the error ends.
  \param message - the error message.
  \param kind - the error kind.
  \param level - the error level.
  \param id - the error id.
  */
MessageItem::MessageItem(QString filename, bool readOnly, int lineStart, int columnStart, int lineEnd, int columnEnd, QString message,
                         QString errorKind, QString errorType, int id)
{
  mTime = QTime::currentTime().toString();
  mFileName = filename;
  mReadOnly = readOnly;
  mLineStart = lineStart;
  mColumnStart = columnStart;
  mLineEnd = lineEnd;
  mColumnEnd = columnEnd;
  mMessage = message;
  mErrorKind = StringHandler::getErrorKind(errorKind);
  mErrorType = StringHandler::getErrorType(errorType);
  mId = id;
}

/*!
  Returns the location of the error message.
  */
QString MessageItem::getLocation()
{
  return QString("%1:%2-%3:%4")
      .arg(QString::number(mLineStart))
      .arg(QString::number(mColumnStart))
      .arg(QString::number(mLineEnd))
      .arg(QString::number(mColumnEnd));
}

/*!
  \class MessagesWidget
  \brief Shows warnings, notifications and error messages.
  */

/*!
  \param pMainWindow - defines a parent to the new instanced object. pMainWindow is the MainWindow object.
  */
MessagesWidget::MessagesWidget(MainWindow *pMainWindow)
  : QWidget(pMainWindow, Qt::WindowTitleHint)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Messages")));
  mpMainWindow = pMainWindow;
  mpMessagesTextBrowser = new QTextBrowser;
  mpMessagesTextBrowser->setOpenLinks(false);
  mpMessagesTextBrowser->setOpenExternalLinks(false);
  // since the QFrame::StyledPanel is not a grey rectangle around it so we need to put it in a QFrame.
  mpMessagesTextBrowser->setFrameStyle(QFrame::NoFrame);
  QFrame *pMessagesTextBrowserFrame = new QFrame;
  pMessagesTextBrowserFrame->setFrameStyle(QFrame::StyledPanel);
  mpMessagesTextBrowser->setContextMenuPolicy(Qt::CustomContextMenu);
  connect(mpMessagesTextBrowser, SIGNAL(anchorClicked(QUrl)), SLOT(openErrorMessageClass(QUrl)));
  connect(mpMessagesTextBrowser, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  // create actions
  mpSelectAllAction = new QAction(tr("Select All"), this);
  mpSelectAllAction->setShortcut(QKeySequence("Ctrl+a"));
  mpSelectAllAction->setStatusTip(tr("Selects all the Messages"));
  connect(mpSelectAllAction, SIGNAL(triggered()), mpMessagesTextBrowser, SLOT(selectAll()));
  mpCopyAction = new QAction(QIcon(":/Resources/icons/copy.svg"), Helper::copy, this);
  mpCopyAction->setShortcut(QKeySequence("Ctrl+c"));
  mpCopyAction->setStatusTip(tr("Copy the Message"));
  connect(mpCopyAction, SIGNAL(triggered()), mpMessagesTextBrowser, SLOT(copy()));
  mpClearAllAction = new QAction(tr("Clear All"), this);
  mpClearAllAction->setStatusTip(tr("clears the Messages Browser"));
  connect(mpClearAllAction, SIGNAL(triggered()), mpMessagesTextBrowser, SLOT(clear()));
  // set layout for MessagesTextBrowser frame
  QVBoxLayout *pMessagesTextBrowserLayout = new QVBoxLayout;
  pMessagesTextBrowserLayout->setContentsMargins(0, 0, 0, 0);
  pMessagesTextBrowserLayout->addWidget(mpMessagesTextBrowser);
  pMessagesTextBrowserFrame->setLayout(pMessagesTextBrowserLayout);
  // Main Layout
  QHBoxLayout *pMainLayout = new QHBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setSpacing(1);
  pMainLayout->addWidget(pMessagesTextBrowserFrame);
  setLayout(pMainLayout);
}

/*!
  Adds the error message.\n
  Moves to the most recent error message in the view.
  */
void MessagesWidget::addGUIMessage(MessageItem *pMessageItem)
{
  // move the cursor down before adding message.
  QTextCursor textCursor = mpMessagesTextBrowser->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpMessagesTextBrowser->setTextCursor(textCursor);
  static int errorCounter = 1;
  QString message;
  if (pMessageItem->getFileName().isEmpty()) { // if custom error message
    message = pMessageItem->getMessage();
  } else if (mpMainWindow->getOMCProxy()->existClass(pMessageItem->getFileName())) {
    // If the class is only loaded in AST then create link for the error message otherwise display filename to user where error occurred.
    message = QString("[%1: %2]: <a href=\"omeditmessagesbrowser:///%3?lineNumber=%4\">%5</a>")
        .arg(pMessageItem->getFileName())
        .arg(pMessageItem->getLocation())
        .arg(pMessageItem->getFileName())
        .arg(pMessageItem->getLineStart())
        .arg(pMessageItem->getMessage());
  } else {
    message = QString("[%1: %2]: %3")
        .arg(pMessageItem->getFileName())
        .arg(pMessageItem->getLocation())
        .arg(pMessageItem->getMessage());
  }
  QString errorString = QString("<span>"
                                "<b>[%1]</b> "
                                "<span style=\"color: #777777;\"><b>%2</b></span> "
                                "<b>%3 %4</b>"
                                "</span><br />"
                                "<span>"
                                "%5"
                                "</span><br /><br />")
      .arg(QString::number(errorCounter))
      .arg(QTime::currentTime().toString())
      .arg(StringHandler::getErrorKindString(pMessageItem->getErrorKind()))
      .arg(StringHandler::getErrorTypeDisplayString(pMessageItem->getErrorType()))
      .arg(message);
  mpMessagesTextBrowser->insertHtml(errorString);
  errorCounter++;
  // move the cursor down after adding message.
  textCursor.movePosition(QTextCursor::End);
  mpMessagesTextBrowser->setTextCursor(textCursor);
  emit MessageAdded();
  // remove the MessageItem
  pMessageItem->deleteLater();
}

/*!
  Slot activated when a link is clicked from MessagesWidget.\n
  Parses the url and loads the Modelica class with the line selected.
  \param url - the url that is clicked
  */
/*
  <a href="omeditmessagesbrowser:///className?lineNumber=4></a>"
  */
void MessagesWidget::openErrorMessageClass(QUrl url)
{
  if (url.scheme() != "omeditmessagesbrowser") {
    /*! @todo Write error-message?! */
    return;
  }
  QString className = url.path();
  if (className.startsWith("/")) className.remove(0, 1);
  LibraryTreeNode *pLibraryTreeNode = mpMainWindow->getLibraryTreeWidget()->getLibraryTreeNode(className);
  if (pLibraryTreeNode) {
    mpMainWindow->getLibraryTreeWidget()->showModelWidget(pLibraryTreeNode);
    ModelWidget *pModelWidget = pLibraryTreeNode->getModelWidget();
    if (pModelWidget && pModelWidget->getModelicaTextEditor()) {
      int lineNumber = url.queryItemValue("lineNumber").toInt();
      pModelWidget->showModelicaTextView(true);
      pModelWidget->getModelicaTextEditor()->goToLineNumber(lineNumber);
    }
  }
}

/*!
  Shows a context menu when user right click on the Messages tree.
  Slot activated when Message::customContextMenuRequested() signal is raised.
  */
void MessagesWidget::showContextMenu(QPoint point)
{
  QMenu menu(this);
  menu.addAction(mpSelectAllAction);
  menu.addAction(mpCopyAction);
  menu.addAction(mpClearAllAction);
  menu.exec(mpMessagesTextBrowser->viewport()->mapToGlobal(point));
}

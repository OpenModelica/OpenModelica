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

#include "MessagesWidget.h"
#include "MainWindow.h"
#include "LibraryTreeWidget.h"
#include "Util/Helper.h"
#include "Options/OptionsDialog.h"

#include <QMenu>

/*!
 * \class MessageItem
 * \brief Holds the error message data.
 */
/*!
 * \param filename - the error filename.
 * \param readOnly - the error file readOnly state.
 * \param lineStart - the index where the error starts.
 * \param columnStart - the indexed column where the error starts.
 * \param lineEnd - the index where the error ends.
 * \param columnEnd - the indexed column where the error ends.
 * \param message - the error message.
 * \param kind - the error kind.
 * \param level - the error level.
 */
MessageItem::MessageItem(MessageItemType type, QString filename, bool readOnly, int lineStart, int columnStart, int lineEnd, int columnEnd, QString message,
                         QString errorKind, QString errorType)
  : mMessageItemType(type)
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
 * \class MessagesWidget
 * \brief Shows warnings, notifications and error messages.
 */

MessagesWidget *MessagesWidget::mpInstance = 0;

/*!
 * \brief MessagesWidget::create
 */
void MessagesWidget::create()
{
  if (!mpInstance) {
    mpInstance = new MessagesWidget;
  }
}

/*!
 * \brief MessagesWidget::destroy
 */
void MessagesWidget::destroy()
{
  mpInstance->deleteLater();
}

/*!
 * \brief MessagesWidget::MessagesWidget
 * \param pParent
 */
MessagesWidget::MessagesWidget(QWidget *pParent)
  : QWidget(pParent)
{
  mMessageNumber = 1;
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
  applyMessagesSettings();
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
  connect(mpClearAllAction, SIGNAL(triggered()), SLOT(clearMessages()));
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
  Applies the Messages settings e.g size, font, color.
  */
void MessagesWidget::applyMessagesSettings()
{
  MessagesPage *pMessagesPage = OptionsDialog::instance()->getMessagesPage();
  // set the output size
  mpMessagesTextBrowser->document()->setMaximumBlockCount(pMessagesPage->getOutputSizeSpinBox()->value());
  // set the font
  QString fontFamily = pMessagesPage->getFontFamilyComboBox()->currentFont().family();
  double fontSize = pMessagesPage->getFontSizeSpinBox()->value();
  QFont font(fontFamily);
  font.setPointSizeF(fontSize);
  mpMessagesTextBrowser->setFont(font);
  // set the messages color by setting the style sheet
  QString messagesCSS = QString(".notification {color: %1}"
                                ".warning {color: %2}"
                                ".error {color: %3}")
      .arg(OptionsDialog::instance()->getMessagesPage()->getNotificationColor().name())
      .arg(OptionsDialog::instance()->getMessagesPage()->getWarningColor().name())
      .arg(OptionsDialog::instance()->getMessagesPage()->getErrorColor().name());
  mpMessagesTextBrowser->document()->setDefaultStyleSheet(messagesCSS);
  // move the cursor to end.
  QTextCursor textCursor = mpMessagesTextBrowser->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpMessagesTextBrowser->setTextCursor(textCursor);
}

/*!
  Adds the error message.\n
  Moves to the most recent error message in the view.
  */
void MessagesWidget::addGUIMessage(MessageItem messageItem)
{
  // move the cursor down before adding message.
  QTextCursor textCursor = mpMessagesTextBrowser->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpMessagesTextBrowser->setTextCursor(textCursor);
  // set the CSS class depending on message type
  QString messageCSSClass;
  switch (messageItem.getErrorType()) {
    case StringHandler::Warning:
      messageCSSClass = "warning";
      break;
    case StringHandler::OMError:
      messageCSSClass = "error";
      break;
    case StringHandler::Notification:
    default:
      messageCSSClass = "notification";
      break;
  }
  QString linkFormat = QString("[%1: %2]: <a href=\"omeditmessagesbrowser:///%3?lineNumber=%4\">%5</a>");
  QString errorMessage;
  QString message;
  if(messageItem.getMessageItemType()== MessageItem::Modelica) {
    // if message already have tags then just use it.
    if (Qt::mightBeRichText(messageItem.getMessage())) {
      message = messageItem.getMessage();
    } else {
      message = Qt::convertFromPlainText(messageItem.getMessage()).remove("<p>").remove("</p>");
    }
  } else if(messageItem.getMessageItemType()== MessageItem::MetaModel) {
    message = messageItem.getMessage().remove("<p>").remove("</p>");
  }
  if (messageItem.getFileName().isEmpty()) { // if custom error message
    errorMessage = message;
  } else if (messageItem.getMessageItemType()== MessageItem::MetaModel ||
             MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(messageItem.getFileName())) {
    // If the class is only loaded in AST via loadString then create link for the error message.
    errorMessage = linkFormat.arg(messageItem.getFileName())
        .arg(messageItem.getLocation())
        .arg(messageItem.getFileName())
        .arg(messageItem.getLineStart())
        .arg(message);
  } else {
    // Find the class name using the file name and line number.
    LibraryTreeItem *pLibraryTreeItem;
    pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->getLibraryTreeItemFromFile(messageItem.getFileName(),
                                                                                                                     messageItem.getLineStart().toInt());
    if (pLibraryTreeItem) {
      errorMessage = linkFormat.arg(pLibraryTreeItem->getNameStructure())
          .arg(messageItem.getLocation())
          .arg(pLibraryTreeItem->getNameStructure())
          .arg(messageItem.getLineStart())
          .arg(message);
    } else {
      // otherwise display filename to user where error occurred.
      errorMessage = QString("[%1: %2]: %3")
          .arg(messageItem.getFileName())
          .arg(messageItem.getLocation())
          .arg(message);
    }
  }
  QString errorString = QString("<div class=\"%1\">"
                                "<b>[%2] %3 %4 %5</b><br>"
                                "%6"
                                "</div><br>")
      .arg(messageCSSClass)
      .arg(QString::number(mMessageNumber))
      .arg(QTime::currentTime().toString())
      .arg(StringHandler::getErrorKindString(messageItem.getErrorKind()))
      .arg(StringHandler::getErrorTypeDisplayString(messageItem.getErrorType()))
      .arg(errorMessage);
  mpMessagesTextBrowser->insertHtml(errorString);
  mMessageNumber++;
  // move the cursor down after adding message.
  textCursor.movePosition(QTextCursor::End);
  mpMessagesTextBrowser->setTextCursor(textCursor);
  emit MessageAdded();
}

/*!
 * \brief MessagesWidget::openErrorMessageClass
 * Slot activated when a link e.g., "<a href="omeditmessagesbrowser:///className?lineNumber=4></a>" is clicked from MessagesWidget.\n
 * Parses the url and loads the Modelica class with the line selected.
 * \param url - the url that is clicked
 */
void MessagesWidget::openErrorMessageClass(QUrl url)
{
  if (url.scheme() != "omeditmessagesbrowser") {
    /*! @todo Write error-message?! */
    return;
  }
  QString className = url.path();
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
  QUrlQuery query(url);
  int lineNumber = query.queryItemValue("lineNumber").toInt();
#else /* Qt4 */
  int lineNumber = url.queryItemValue("lineNumber").toInt();
#endif
  if (className.startsWith("/")) {
    className.remove(0, 1);
  }
  // find the class that has the error
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
  /* the error could be in P.M but we get P as error class in this case we see if current class has the same file as P
   * and also contains the line number. If we have correct current class then no need to show root parent class i.e., P.
   */
  ModelWidget *pModelWidget = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget();
  if ((pModelWidget->getLibraryTreeItem()->getFileName().compare(pLibraryTreeItem->getFileName()) == 0) &&
      pModelWidget->getLibraryTreeItem()->inRange(lineNumber)) {
    pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
  }
  if (pLibraryTreeItem) {
    MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
    if (pLibraryTreeItem->getModelWidget() && pLibraryTreeItem->getModelWidget()->getEditor()) {
      pLibraryTreeItem->getModelWidget()->getTextViewToolButton()->setChecked(true);
      pLibraryTreeItem->getModelWidget()->getEditor()->goToLineNumber(lineNumber);
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

/*!
  Clears the Messages Browser and resets the messages number.
  Slot activated when mpClearAllAction triggered signal is raised.
  */
void MessagesWidget::clearMessages()
{
  resetMessagesNumber();
  mpMessagesTextBrowser->clear();
}

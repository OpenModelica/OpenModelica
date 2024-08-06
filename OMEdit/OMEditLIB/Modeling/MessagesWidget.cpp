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
#include "Modeling/ModelWidgetContainer.h"
#include "LibraryTreeWidget.h"
#include "Util/Helper.h"
#include "Options/OptionsDialog.h"
#include "Simulation/SimulationDialog.h"
#include "Simulation//SimulationOutputWidget.h"
#include "OMS/OMSSimulationOutputWidget.h"

#include <QMenu>
#include <QMessageBox>

const int fixedTabsCount = 4;

/*!
 * \class MessageItem
 * \brief Holds the error message data.
 */
/*!
 * \brief MessageItem::MessageItem
 */
MessageItem::MessageItem()
{
  mMessageItemType = MessageItem::Modelica;
  mTime = QTime::currentTime().toString();
  mFileName = "";
  mReadOnly = false;
  mLineStart = 0;
  mColumnStart = 0;
  mLineEnd = 0;
  mColumnEnd = 0;
  mMessage = "";
  mErrorKind = StringHandler::NoOMErrorKind;
  mErrorType = StringHandler::NoOMError;
}

/*!
 * \brief MessageItem::MessageItem
 * \param type
 * \param filename - the error filename.
 * \param readOnly - the error file readOnly state.
 * \param lineStart - the index where the error starts.
 * \param columnStart - the indexed column where the error starts.
 * \param lineEnd - the index where the error ends.
 * \param columnEnd - the indexed column where the error ends.
 * \param message - the error message.
 * \param errorKind - the error kind.
 * \param errorType - the error type.
 */
MessageItem::MessageItem(MessageItemType type, QString filename, bool readOnly, int lineStart, int columnStart, int lineEnd,
                         int columnEnd, QString message, QString errorKind, QString errorType)
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
 * \brief MessageItem::MessageItem
 * \param type
 * \param message - the error message.
 * \param errorKind - the error kind.
 * \param errorType - the error type.
 */
MessageItem::MessageItem(MessageItemType type, QString message, QString errorKind, QString errorType)
  : mMessageItemType(type)
{
  mTime = QTime::currentTime().toString();
  mFileName = "";
  mReadOnly = false;
  mLineStart = 0;
  mColumnStart = 0;
  mLineEnd = 0;
  mColumnEnd = 0;
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
 * \class MessageWidget
 * \brief Message widget with QTextBrowser for showing notifications, warning and error messages.
 */
/*!
 * \brief MessageWidget::MessageWidget
 * \param pParent
 */
MessageWidget::MessageWidget(QWidget *pParent)
  : QWidget(pParent)
{
  mMessageNumber = 1;
  mpMessagesTextBrowser = new QTextBrowser;
  mpMessagesTextBrowser->setOpenLinks(false);
  mpMessagesTextBrowser->setOpenExternalLinks(false);
  mpMessagesTextBrowser->setFrameStyle(QFrame::NoFrame);
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
  mpClearThisTabAction = new QAction(tr("Clear This Tab"), this);
  mpClearThisTabAction->setStatusTip(tr("clears the messages from this tab"));
  connect(mpClearThisTabAction, SIGNAL(triggered()), SLOT(clearThisTabMessages()));
  mpClearAllTabsAction = new QAction(tr("Clear All Tabs"), this);
  mpClearAllTabsAction->setStatusTip(tr("clears the messages from all tabs"));
  connect(mpClearAllTabsAction, SIGNAL(triggered()), SLOT(clearAllTabsMessages()));
  // Main Layout
  QHBoxLayout *pMainLayout = new QHBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpMessagesTextBrowser);
  setLayout(pMainLayout);
}

/*!
 * \brief MessageWidget::applyMessagesSettings
 * Applies the Messages settings e.g size, font, color.
 */
void MessageWidget::applyMessagesSettings()
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
 * \brief MessageWidget::addGUIMessage
 * Adds the message.\n
 * Moves to the most recent message in the view.
 * \param messageItem
 */
void MessageWidget::addGUIMessage(MessageItem messageItem)
{
  // move the cursor down before adding message.
  QTextCursor textCursor = mpMessagesTextBrowser->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpMessagesTextBrowser->setTextCursor(textCursor);
  // set the CSS class depending on message type
  QString messageCSSClass;
  switch (messageItem.getErrorType()) {
    case StringHandler::Internal:
      messageCSSClass = "error";
      break;
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
  } else if(messageItem.getMessageItemType()== MessageItem::CompositeModel) {
    message = messageItem.getMessage().remove("<p>").remove("</p>");
  }
  if (messageItem.getFileName().isEmpty()) { // if custom error message
    errorMessage = message;
  } else if (messageItem.getMessageItemType()== MessageItem::CompositeModel ||
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
}

/*!
 * \brief MessageWidget::openErrorMessageClass
 * Slot activated when a link e.g., "<a href="omeditmessagesbrowser:///className?lineNumber=4></a>" is clicked from MessagesWidget.\n
 * Parses the url and loads the Modelica class with the line selected.
 * \param url - the url that is clicked
 */
void MessageWidget::openErrorMessageClass(QUrl url)
{
  if (url.scheme() != "omeditmessagesbrowser") {
    /*! @todo Write error-message?! */
    return;
  }
  QString className = url.path();
  QUrlQuery query(url);
  int lineNumber = query.queryItemValue("lineNumber").toInt();
  if (className.startsWith("/")) {
    className.remove(0, 1);
  }
  // find the class that has the error
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
  if (pLibraryTreeItem) {
    /* the error could be in P.M but we get P as error class in this case we see if current class has the same file as P
     * and also contains the line number. If we have correct current class then no need to show root parent class i.e., P.
     */
    ModelWidget *pModelWidget = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget();
    if (pModelWidget /* Might be NULL */ && (pModelWidget->getLibraryTreeItem()->getFileName().compare(pLibraryTreeItem->getFileName()) == 0) &&
        pModelWidget->getLibraryTreeItem()->inRange(lineNumber)) {
      pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
    }
    MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
    if (pLibraryTreeItem->getModelWidget() && pLibraryTreeItem->getModelWidget()->getEditor()) {
      pLibraryTreeItem->getModelWidget()->getTextViewToolButton()->setChecked(true);
      pLibraryTreeItem->getModelWidget()->getEditor()->getPlainTextEdit()->goToLineNumber(lineNumber);
    }
  } else {
    QMessageBox::information(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                             GUIMessages::getMessage(GUIMessages::CLASS_NOT_FOUND)
                             .arg(className), QMessageBox::Ok);
  }
}

/*!
 * \brief MessageWidget::showContextMenu
 * Shows a context menu when user right click on the Messages tree.
 * Slot activated when mpMessagesTextBrowser customContextMenuRequested signal is raised.
 * \param point
 */
void MessageWidget::showContextMenu(QPoint point)
{
  QMenu menu(this);
  menu.addAction(mpSelectAllAction);
  menu.addAction(mpCopyAction);
  menu.addAction(mpClearThisTabAction);
  menu.addAction(mpClearAllTabsAction);
  menu.exec(mpMessagesTextBrowser->viewport()->mapToGlobal(point));
}

/*!
 * \brief MessageWidget::clearThisTabMessages
 * Clears the messages and resets the messages number from this tab.
 */
void MessageWidget::clearThisTabMessages()
{
  resetMessagesNumber();
  mpMessagesTextBrowser->clear();
}

/*!
 * \brief MessageWidget::clearAllTabsMessages
 * Clears the messages and resets the messages number from all tabs.
 */
void MessageWidget::clearAllTabsMessages()
{
  MessagesWidget::instance()->getAllMessageWidget()->resetMessagesNumber();
  MessagesWidget::instance()->getAllMessageWidget()->getMessagesTextBrowser()->clear();
  MessagesWidget::instance()->getNotificationMessageWidget()->resetMessagesNumber();
  MessagesWidget::instance()->getNotificationMessageWidget()->getMessagesTextBrowser()->clear();
  MessagesWidget::instance()->getWarningMessageWidget()->resetMessagesNumber();
  MessagesWidget::instance()->getWarningMessageWidget()->getMessagesTextBrowser()->clear();
  MessagesWidget::instance()->getErrorMessageWidget()->resetMessagesNumber();
  MessagesWidget::instance()->getErrorMessageWidget()->getMessagesTextBrowser()->clear();
}

/*!
 * \brief MessagesTabWidget::MessagesTabWidget
 * We need to subclass QTabWidget since tabBar() is protected function in Qt4.
 * \param pParent
 */
MessagesTabWidget::MessagesTabWidget(QWidget *pParent)
  : QTabWidget(pParent)
{
  setDocumentMode(true);
  setTabsClosable(true);
}

/*!
 * \brief MessagesTabWidget::removeCloseButtonfromFixedTabs
 * Removes the close button from first few fixed tabs.
 */
void MessagesTabWidget::removeCloseButtonfromFixedTabs()
{
  QTabBar::ButtonPosition closeSide = (QTabBar::ButtonPosition)style()->styleHint(QStyle::SH_TabBar_CloseButtonPosition, 0, tabBar());
  for (int i = 0; i < fixedTabsCount; ++i) {
    QWidget *pTabButtonWidget = tabBar()->tabButton(i, closeSide);
    if (pTabButtonWidget) {
      pTabButtonWidget->deleteLater();
    }
    tabBar()->setTabButton(i, closeSide, 0);
  }
}

/*!
 * \class MessagesWidget
 * \brief Tab widget for showing notifications, warning and error messages.
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
  /* We want to delete right away instead to clean stuff properly in beforeClosingMainWindow
   * So don not use deleteLater();
   */
  //mpInstance->deleteLater();
  delete mpInstance;
  mpInstance = 0;
}

/*!
 * \brief MessagesWidget::MessagesWidget
 * \param pParent
 */
MessagesWidget::MessagesWidget(QWidget *pParent)
  : QWidget(pParent)
{
  mpMessagesTabWidget = new MessagesTabWidget;
  mpAllMessageWidget = new MessageWidget;
  mpMessagesTabWidget->addTab(mpAllMessageWidget, tr("All"));
  mpNotificationMessageWidget = new MessageWidget;
  mpMessagesTabWidget->addTab(mpNotificationMessageWidget, tr("Notifications"));
  mpWarningMessageWidget = new MessageWidget;
  mpMessagesTabWidget->addTab(mpWarningMessageWidget, tr("Warnings"));
  mpErrorMessageWidget = new MessageWidget;
  mpMessagesTabWidget->addTab(mpErrorMessageWidget, tr("Errors"));
  // Remove the close button of first few fixed tabs
  mpMessagesTabWidget->removeCloseButtonfromFixedTabs();
  connect(mpMessagesTabWidget, SIGNAL(tabCloseRequested(int)), SLOT(closeTab(int)));
  mSuppressMessagesList.clear();
#ifdef Q_OS_WIN
  // nothing
#elif defined(Q_OS_MAC)
  mSuppressMessagesList << "modalSession has been exited prematurely*"; /* This warning is fixed in latest Qt versions but out OSX build still uses old Qt. */
#else
  mSuppressMessagesList << "libpng warning*" /* libpng warning comes from QWebView default images. */
                        << "Gtk-Message:*" /* Gtk warning comes when Qt tries to open the native dialogs. */;
#endif
  mPendingMessagesQueue.clear();
  mShowingPendingMessages = false;
  // Main Layout
  QHBoxLayout *pMainLayout = new QHBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpMessagesTabWidget);
  setLayout(pMainLayout);
}

/*!
 * \brief MessagesWidget::resetMessagesNumber
 * Resets the Message number of the appropriate message tab widget.
 */
void MessagesWidget::resetMessagesNumber()
{
  mpAllMessageWidget->resetMessagesNumber();
  mpNotificationMessageWidget->resetMessagesNumber();
  mpWarningMessageWidget->resetMessagesNumber();
  mpErrorMessageWidget->resetMessagesNumber();
}

/*!
 * \brief MessagesWidget::applyMessagesSettings
 * Applies the Messages settings to the appropriate message tab widget.
 */
void MessagesWidget::applyMessagesSettings()
{
  mpAllMessageWidget->applyMessagesSettings();
  mpNotificationMessageWidget->applyMessagesSettings();
  mpWarningMessageWidget->applyMessagesSettings();
  mpErrorMessageWidget->applyMessagesSettings();
}

/*!
 * \brief MessagesWidget::addSimulationOutputTab
 * Adds a simulation output tab.
 * \param pSimulationOutputTab
 * \param name
 * \param removeExisting - Removes all the tabs where simulation is finished.
 */
void MessagesWidget::addSimulationOutputTab(QWidget *pSimulationOutputTab, const QString &name, bool removeExisting)
{
  /* ticket:4406 Option to automatically close simulation tabs where simulation is done.
   * Close all completed simulation tabs.
   */
  if (removeExisting && OptionsDialog::instance()->getSimulationPage()->getCloseSimulationOutputWidgetsBeforeSimulationCheckBox()->isChecked()) {
    for (int i = fixedTabsCount; i < mpMessagesTabWidget->count(); ++i) {
      // move one step back if tab is removed successfully
      if (closeTab(i)) {
        --i;
      }
    }
  }
  // if tab already exists then just don't try to add it again.
  bool tabFound = false;
  for (int i = 0; i < mpMessagesTabWidget->count(); ++i) {
    if (mpMessagesTabWidget->widget(i) == pSimulationOutputTab) {
      mpMessagesTabWidget->setCurrentIndex(i);
      tabFound = true;
      break;
    }
  }
  // add the tab if it doesn't already exist
  if (!tabFound) {
    mpMessagesTabWidget->setCurrentIndex(mpMessagesTabWidget->addTab(pSimulationOutputTab, name));
    emit messageTabAdded(pSimulationOutputTab, name);
  }
}

/*!
 * \brief MessagesWidget::getSimulationOutputTabsSize
 * Returns the size of Simulation output tabs.
 * \return
 */
int MessagesWidget::getSimulationOutputTabsSize()
{
  return mpMessagesTabWidget->count() - fixedTabsCount;
}

/*!
 * \brief MessagesWidget::getSimulationOutputWidget
 * Finds and returns the SimulationOutputWidget
 * \param className
 * \return
 */
SimulationOutputWidget* MessagesWidget::getSimulationOutputWidget(const QString &className)
{
  for (int i = fixedTabsCount; i < mpMessagesTabWidget->count(); ++i) {
    SimulationOutputWidget *pSimulationOutputWidget = qobject_cast<SimulationOutputWidget*>(mpMessagesTabWidget->widget(i));
    if (pSimulationOutputWidget && pSimulationOutputWidget->getSimulationOptions().getClassName().compare(className) == 0) {
      return pSimulationOutputWidget;
    }
  }
  return 0;
}

/*!
 * \brief MessagesWidget::closeTab
 * Removes the tab from MessagesWidget.
 * Returns true if tab is removed.
 * \param index
 */
bool MessagesWidget::closeTab(int index)
{
  // Close SimulationOutputWidget
  SimulationOutputWidget *pSimulationOutputWidget = qobject_cast<SimulationOutputWidget*>(mpMessagesTabWidget->widget(index));
  if (pSimulationOutputWidget
      && !pSimulationOutputWidget->isCompilationProcessRunning()
      && !pSimulationOutputWidget->isPostCompilationProcessRunning()
      && !pSimulationOutputWidget->isSimulationProcessRunning()) {
    mpMessagesTabWidget->removeTab(index);
    emit messageTabClosed(index);
    return true;
  }
  // Close OMSSimulationOutputWidget
  OMSSimulationOutputWidget *pOMSSimulationOutputWidget = qobject_cast<OMSSimulationOutputWidget*>(mpMessagesTabWidget->widget(index));
  if (pOMSSimulationOutputWidget && !pOMSSimulationOutputWidget->isSimulationProcessRunning()) {
    mpMessagesTabWidget->removeTab(index);
    emit messageTabClosed(index);
    return true;
  }
  return false;
}

/*!
 * \brief MessagesWidget::addGUIMessage
 * Adds the error message to the appropriate message tab widget.
 * \param messageItem
 */
void MessagesWidget::addGUIMessage(MessageItem messageItem)
{
  // suppress the unnecessary qt warning messages
  foreach (QString suppressMessage, mSuppressMessagesList) {
    QRegExp rx(suppressMessage);
    rx.setPatternSyntax(QRegExp::Wildcard);
    if (rx.exactMatch(messageItem.getMessage())) {
      return;
    }
  }

  switch (messageItem.getErrorType()) {
    case StringHandler::Internal:
      mpErrorMessageWidget->addGUIMessage(messageItem);
      mpAllMessageWidget->addGUIMessage(messageItem);
      break;
    case StringHandler::Notification:
      mpNotificationMessageWidget->addGUIMessage(messageItem);
      mpAllMessageWidget->addGUIMessage(messageItem);
      break;
    case StringHandler::Warning:
      mpWarningMessageWidget->addGUIMessage(messageItem);
      mpAllMessageWidget->addGUIMessage(messageItem);
      break;
    case StringHandler::OMError:
      mpErrorMessageWidget->addGUIMessage(messageItem);
      mpAllMessageWidget->addGUIMessage(messageItem);
      break;
    default:
      mpAllMessageWidget->addGUIMessage(messageItem);
      break;
  }
  mpMessagesTabWidget->setCurrentWidget(mpAllMessageWidget);
  if (OptionsDialog::isCreated()) {
    if (!OptionsDialog::instance()->getMessagesPage()->getEnlargeMessageBrowserCheckBox()->isChecked()) {
      emit messageAdded();
    } else {
      MainWindow::instance()->markMessagesTabWidgetChangedForNewMessage(messageItem.getErrorType());
    }
  } else { // this block is called when some message appear during the startup. See #11985.
    emit messageAdded();
  }
}

/*!
 * \brief MessagesWidget::addPendingMessage
 * Adds the error message to the container of pending messages.
 * \param messageItem
 */
void MessagesWidget::addPendingMessage(MessageItem messageItem)
{
  QMutexLocker locker(&mPendingMessagesMutex);
  mPendingMessagesQueue.enqueue(messageItem);
}

/*!
 * \brief MessagesWidget::showPendingMessages
 * Shows the error messages from the container of pending messages.
 */
void MessagesWidget::showPendingMessages()
{
  QMutexLocker locker(&mPendingMessagesMutex);
  if (!mShowingPendingMessages) {
    mShowingPendingMessages = true;
    while (!mPendingMessagesQueue.isEmpty()) {
      MessageItem messageItem = mPendingMessagesQueue.dequeue();
      locker.unlock();
      addGUIMessage(messageItem);
      locker.relock();
    }
    mShowingPendingMessages = false;
  }
}

/*!
 * \brief MessagesWidget::clearMessages
 * Slot activated when mpClearAllAction triggered signal is raised.
 */
void MessagesWidget::clearMessages()
{
  mpAllMessageWidget->clearThisTabMessages();
  mpNotificationMessageWidget->clearThisTabMessages();
  mpWarningMessageWidget->clearThisTabMessages();
  mpErrorMessageWidget->clearThisTabMessages();
}

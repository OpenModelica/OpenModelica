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
 * RCS: $Id$
 *
 */

#include "MessagesWidget.h"
#include "Helper.h"

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
  // creates Messages tree widget
  mpMessagesTreeWidget = new MessagesTreeWidget(this);
  // create button for only showing notifications
  mpShowNotificationsToolButton = new QToolButton;
  QString showNotificationMsg = tr("Only Show Notifications");
  mpShowNotificationsToolButton->setIcon(QIcon(":/Resources/icons/notificationicon.png"));
  mpShowNotificationsToolButton->setText(showNotificationMsg);
  mpShowNotificationsToolButton->setToolTip(showNotificationMsg);
  mpShowNotificationsToolButton->setCheckable(true);
  mpShowNotificationsToolButton->setAutoRaise(true);
  connect(mpShowNotificationsToolButton, SIGNAL(clicked()), SLOT(showNotifications()));
  // create button for only showing warnings
  mpShowWarningsToolButton = new QToolButton;
  mpShowWarningsToolButton->setIcon(QIcon(":/Resources/icons/warningicon.png"));
  QString showWarningsMsg = tr("Only Show Warnings");
  mpShowWarningsToolButton->setText(showWarningsMsg);
  mpShowWarningsToolButton->setToolTip(showWarningsMsg);
  mpShowWarningsToolButton->setCheckable(true);
  mpShowWarningsToolButton->setAutoRaise(true);
  connect(mpShowWarningsToolButton, SIGNAL(clicked()), SLOT(showWarnings()));
  // create button for only showing errors
  mpShowErrorsToolButton = new QToolButton;
  mpShowErrorsToolButton->setIcon(QIcon(":/Resources/icons/erroricon.png"));
  QString showErrorsMsg = tr("Only Show Errors");
  mpShowErrorsToolButton->setText(showErrorsMsg);
  mpShowErrorsToolButton->setToolTip(showErrorsMsg);
  mpShowErrorsToolButton->setCheckable(true);
  mpShowErrorsToolButton->setAutoRaise(true);
  connect(mpShowErrorsToolButton, SIGNAL(clicked()), SLOT(showErrors()));
  // create button for showing all Messages
  mpShowAllMessagesToolButton = new QToolButton;
  mpShowAllMessagesToolButton->setIcon(QIcon(":/Resources/icons/messages.png"));
  QString showAllMessagesMsg = tr("Show All Messages");
  mpShowAllMessagesToolButton->setText(showAllMessagesMsg);
  mpShowAllMessagesToolButton->setToolTip(showAllMessagesMsg);
  mpShowAllMessagesToolButton->setCheckable(true);
  mpShowAllMessagesToolButton->setChecked(true);
  mpShowAllMessagesToolButton->setAutoRaise(true);
  connect(mpShowAllMessagesToolButton, SIGNAL(clicked()), SLOT(showAllMessages()));
  // create button group
  mpMessagesButtonGroup = new QButtonGroup;
  mpMessagesButtonGroup->setExclusive(true);
  mpMessagesButtonGroup->addButton(mpShowNotificationsToolButton);
  mpMessagesButtonGroup->addButton(mpShowWarningsToolButton);
  mpMessagesButtonGroup->addButton(mpShowErrorsToolButton);
  mpMessagesButtonGroup->addButton(mpShowAllMessagesToolButton);
  // horizontal line
  QFrame *horizontalLine = new QFrame;
  horizontalLine->setFrameShape(QFrame::HLine);
  horizontalLine->setFrameShadow(QFrame::Sunken);
  // create button for clearing Messages
  mpClearMessagesToolButton = new QToolButton;
  mpClearMessagesToolButton->setContentsMargins(0, 0, 0, 0);
  QString clearMessagesMsg = tr("Clear All Messages");
  mpClearMessagesToolButton->setIcon(QIcon(":/Resources/icons/clearmessages.png"));
  mpClearMessagesToolButton->setText(clearMessagesMsg);
  mpClearMessagesToolButton->setToolTip(clearMessagesMsg);
  mpClearMessagesToolButton->setAutoRaise(true);
  connect(mpClearMessagesToolButton, SIGNAL(clicked()), SLOT(clearMessages()));
  // layout for buttons
  QVBoxLayout *buttonsLayout = new QVBoxLayout;
  buttonsLayout->setAlignment(Qt::AlignBottom | Qt::AlignRight);
  buttonsLayout->setContentsMargins(0, 0, 0, 0);
  buttonsLayout->setSpacing(0);
  buttonsLayout->addWidget(mpShowNotificationsToolButton);
  buttonsLayout->addWidget(mpShowWarningsToolButton);
  buttonsLayout->addWidget(mpShowErrorsToolButton);
  buttonsLayout->addWidget(mpShowAllMessagesToolButton);
  buttonsLayout->addWidget(horizontalLine);
  buttonsLayout->addWidget(mpClearMessagesToolButton);
  // layout
  QHBoxLayout *layout = new QHBoxLayout;
  layout->setContentsMargins(0, 0, 0, 0);
  layout->setSpacing(1);
  layout->addWidget(mpMessagesTreeWidget);
  layout->addLayout(buttonsLayout);
  setLayout(layout);
}

/*!
  \return pointer to MessagesTreeWidget
  */
MessagesTreeWidget* MessagesWidget::getMessagesTreeWidget()
{
  return mpMessagesTreeWidget;
}

/*!
  Reimplementation of sizeHint function. Defines the minimum height.
  */
QSize MessagesWidget::sizeHint() const
{
  QSize size = QWidget::sizeHint();
  //Set very small height. A minimum apperantly stops at reasonable size. Giving the drawing area more space.
  size.rheight() = 100; //pixels
  return size;
}

/*!
  Adds the Message to the Messages tree.
  \param pMessageItem - is the Message to add.
  */
void MessagesWidget::addGUIMessage(MessagesTreeItem *pMessageItem)
{
  mpMessagesTreeWidget->addTopLevelItem(pMessageItem);
  mpMessagesTreeWidget->scrollToBottom();
  mpShowAllMessagesToolButton->setChecked(true);
  emit MessageAdded();
}

/*!
  Clears all the Messages.
  Slot activated when mpClearMessagesToolButton clicked signal is raised.
  */
void MessagesWidget::clearMessages()
{
  int i = 0;
  while(i < mpMessagesTreeWidget->topLevelItemCount())
  {
    qDeleteAll(mpMessagesTreeWidget->topLevelItem(i)->takeChildren());
    delete mpMessagesTreeWidget->topLevelItem(i);
    i = 0;   //Restart iteration
  }
}

/*!
  Filter the Messages tree and only show the notification type Messages.
  Slot activated when mpShowNotificationsToolButton clicked signal is raised.
  */
void MessagesWidget::showNotifications()
{
  QTreeWidgetItemIterator it(mpMessagesTreeWidget);
  while (*it)
  {
    MessagesTreeItem *pMessageItem = dynamic_cast<MessagesTreeItem*>(*it);
    if (pMessageItem->getType() == StringHandler::Notification)
      pMessageItem->setHidden(false);
    else
      pMessageItem->setHidden(true);
    ++it;
  }
}

/*!
  Filter the Messages tree and only show the warning type Messages.
  Slot activated when mpShowWarningsToolButton clicked signal is raised.
  */
void MessagesWidget::showWarnings()
{
  QTreeWidgetItemIterator it(mpMessagesTreeWidget);
  while (*it)
  {
    MessagesTreeItem *pMessageItem = dynamic_cast<MessagesTreeItem*>(*it);
    if (pMessageItem->getType() == StringHandler::Warning)
      pMessageItem->setHidden(false);
    else
      pMessageItem->setHidden(true);
    ++it;
  }
}

/*!
  Filter the Messages tree and only show the error type Messages.
  Slot activated when mpShowErrorsToolButton clicked signal is raised.
  */
void MessagesWidget::showErrors()
{
  QTreeWidgetItemIterator it(mpMessagesTreeWidget);
  while (*it)
  {
    MessagesTreeItem *pMessageItem = dynamic_cast<MessagesTreeItem*>(*it);
    if (pMessageItem->getType() == StringHandler::OMError)
      pMessageItem->setHidden(false);
    else
      pMessageItem->setHidden(true);
    ++it;
  }
}

/*!
  Shows all type of Messages.
  Slot activated when mpShowAllMessagesToolButton clicked signal is raised.
  */
void MessagesWidget::showAllMessages()
{
  QTreeWidgetItemIterator it(mpMessagesTreeWidget);
  while (*it)
  {
    MessagesTreeItem *pMessageItem = dynamic_cast<MessagesTreeItem*>(*it);
    pMessageItem->setHidden(false);
    ++it;
  }
}

/*!
  \class MessagesTreeWidget
  \brief A tree based structure for OMC error messages. Creates three types of messages i.e notification ,warning, error.
  */

/*!
  \param pMessagesWidget - defines a parent to the new instanced object. pMessagesWidget is the MessageWidget object.
  */
MessagesTreeWidget::MessagesTreeWidget(MessagesWidget *pMessagesWidget)
  : QTreeWidget(pMessagesWidget)
{
  mpMessagesWidget = pMessagesWidget;
  // set tree settings
  setItemDelegate(new ItemDelegate(this, true));
  setTextElideMode(Qt::ElideMiddle);
  setSelectionMode(QAbstractItemView::ExtendedSelection);
  setObjectName("MessagesTree");
  setIndentation(0);
  setColumnCount(4);
  setIconSize(QSize(12, 12));
  setContentsMargins(0, 0, 0, 0);
  QStringList labels;
  labels << tr("Kind") << tr("Time") << tr("Resource") << Helper::errorLocation << tr("Message");
  setHeaderLabels(labels);
  setContextMenuPolicy(Qt::CustomContextMenu);
  // create actions
  mpSelectAllAction = new QAction(tr("Select All"), this);
  mpSelectAllAction->setStatusTip(tr("Selects all the Messages"));
  connect(mpSelectAllAction, SIGNAL(triggered()), SLOT(selectAllMessages()));
  mpCopyAction = new QAction(QIcon(":/Resources/icons/copy.png"), Helper::copy, this);
  mpCopyAction->setStatusTip(tr("Copy the Message"));
  connect(mpCopyAction, SIGNAL(triggered()), SLOT(copyMessages()));
  mpRemoveAction = new QAction(QIcon(":/Resources/icons/delete.png"), Helper::remove, this);
  mpRemoveAction->setStatusTip(tr("Remove the Message"));
  connect(mpRemoveAction, SIGNAL(triggered()), SLOT(removeMessages()));
  // make Messages Tree connections
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
}

/*!
  Shows a context menu when user right click on the Messages tree.
  Slot activated when Message::customContextMenuRequested() signal is raised.
  */
void MessagesTreeWidget::showContextMenu(QPoint point)
{
  int adjust = 24;
  QTreeWidgetItem *item = 0;
  item = itemAt(point);

  if (item)
  {
    item->setSelected(true);
    QMenu menu(this);
    menu.addAction(mpSelectAllAction);
    menu.addAction(mpCopyAction);
    menu.addAction(mpRemoveAction);
    point.setY(point.y() + adjust);
    menu.exec(mapToGlobal(point));
  }
}

/*!
  Selects all the Messages.
  Slot activated when mpSelectAllAction triggered signal is raised.
  */
void MessagesTreeWidget::selectAllMessages()
{
  selectAll();
}

/*!
  Copy the selected Messages to the clipboard.
  Slot activated when mpCopyAction triggered signal is raised.
  */
void MessagesTreeWidget::copyMessages()
{
  QStringList textToCopy;
  foreach (QTreeWidgetItem *pItem, selectedItems())
  {
    MessagesTreeItem *pMessagesTreeItem = dynamic_cast<MessagesTreeItem*>(pItem);
    if (pMessagesTreeItem)
    {
      QString file = pMessagesTreeItem->text(2);
      QString line = pMessagesTreeItem->text(3);
      QString level = pMessagesTreeItem->getLevel();
      QString message = pMessagesTreeItem->getMessage();
      textToCopy.append(QString("[%1:%2] %3: %4").arg(file).arg(line).arg(level).arg(message));
    }
  }
  QApplication::clipboard()->setText(textToCopy.join("\n"));
}

/*!
  Removes the selected Messages.
  Slot activated when mpRemoveAction triggered signal is raised.
  */
void MessagesTreeWidget::removeMessages()
{
  foreach (QTreeWidgetItem *pItem, selectedItems())
  {
    qDeleteAll(pItem->takeChildren());
    delete pItem;
  }
}

/*!
  Reimplementation of keypressevent.
  Defines what to do for Ctrl+A, Ctrl+C and Del buttons.
  */
void MessagesTreeWidget::keyPressEvent(QKeyEvent *event)
{
  if (event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_A)
  {
    selectAll();
  }
  else if (event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_C)
  {
    copyMessages();
  }
  else if (event->key() == Qt::Key_Delete)
  {
    removeMessages();
  }
  else
  {
    QTreeWidget::keyPressEvent(event);
  }
}

/*!
  \class MessagesTreeItem
  \brief A tree widget item/node for MessagesTreeWidget.
  */

/*!
  \param pParent - pointer to MessagesTreeWidget.
   */
MessagesTreeItem::MessagesTreeItem(MessagesTreeWidget *pParent)
  : QTreeWidgetItem(pParent)
{
  mpMessagesTreeWidget = pParent;
  initialize();
}

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
  \param pParent - pointer to MessagesTreeWidget.
  */
MessagesTreeItem::MessagesTreeItem(QString filename, bool readOnly, int lineStart, int columnStart, int lineEnd, int columnEnd, QString message,
                         QString kind, QString level, int id, MessagesTreeWidget *pParent)
  : QTreeWidgetItem(pParent)
{
  mpMessagesTreeWidget = pParent;
  initialize();
  setFileName(filename);
  setReadOnly(readOnly);
  setLineStart(lineStart);
  setColumnStart(columnStart);
  setLineEnd(lineEnd);
  setColumnEnd(columnEnd);
  setMessage(message);
  setKind(kind);
  setLevel(level);
  setId(id);
  setColumnsText();
}

/*!
  Initializes the MessagesTreeItem.
  */
void MessagesTreeItem::initialize()
{
  // create error types map
  mErrorsMap.insert(Helper::notificationLevel, StringHandler::Notification);
  mErrorsMap.insert(Helper::warningLevel, StringHandler::Warning);
  mErrorsMap.insert(Helper::errorLevel, StringHandler::OMError);
  // create error kind map
  mErrorKindsMap.insert(Helper::syntaxKind, StringHandler::Syntax);
  mErrorKindsMap.insert(Helper::grammarKind, StringHandler::Grammar);
  mErrorKindsMap.insert(Helper::translationKind, StringHandler::Translation);
  mErrorKindsMap.insert(Helper::symbolicKind, StringHandler::Symbolic);
  mErrorKindsMap.insert(Helper::simulationKind, StringHandler::Simulation);
  mErrorKindsMap.insert(Helper::scriptingKind, StringHandler::Scripting);
}

/*!
  Sets the error filename.
  \param fileName - the error file name.
  */
void MessagesTreeItem::setFileName(QString fileName)
{
  mFileName = fileName;
}

/*!
  Returns the error filename.
  \return the error file name.
  */
QString MessagesTreeItem::getFileName()
{
  return mFileName;
}

/*!
  Sets the error file readOnly state.
  \param readOnly - the error file readOnly state.
  */
void MessagesTreeItem::setReadOnly(bool readOnly)
{
  mReadOnly = readOnly;
}

/*!
  Returns the error file readOnly state.
  \return the error file readOnly state.
  */
bool MessagesTreeItem::getReadOnly()
{
  return mReadOnly;
}

/*!
  Sets the error line start index.
  \param lineStart - the error start index.
  */
void MessagesTreeItem::setLineStart(int lineStart)
{
  mLineStart = lineStart;
}

/*!
  Returns the error start index.
  \return the error start index.
  */
int MessagesTreeItem::getLineStart()
{
  return mLineStart;
}

/*!
  Sets the error column start index.
  \param columnStart - the error column start index.
  */
void MessagesTreeItem::setColumnStart(int columnStart)
{
  mColumnStart = columnStart;
}

/*!
  Returns the error column start index.
  \return the error column start index.
  */
int MessagesTreeItem::getColumnStart()
{
  return mColumnStart;
}

/*!
  Sets the error line end index.
  \param lineEnd - the error end index.
  */
void MessagesTreeItem::setLineEnd(int lineEnd)
{
  mLineEnd = lineEnd;
}

/*!
  Returns the error end index.
  \return the error end index.
  */
int MessagesTreeItem::getLineEnd()
{
  return mLineEnd;
}

/*!
  Sets the error column end index.
  \param columnEnd - the error column end index.
  */
void MessagesTreeItem::setColumnEnd(int columnEnd)
{
  mColumnEnd = columnEnd;
}

/*!
  Returns the error column end index.
  \return the error column end index.
  */
int MessagesTreeItem::getColumnEnd()
{
  return mColumnEnd;
}

/*!
  Sets the error message.
  \param message - the error message to set.
  */
void MessagesTreeItem::setMessage(QString message)
{
  mMessage = message;
}

/*!
  Returns the error message.
  \return the error message.
  */
QString MessagesTreeItem::getMessage()
{
  return mMessage;
}

/*!
  Sets the error kind.
  \param kind - the error kind to set.
  */
void MessagesTreeItem::setKind(QString kind)
{
  mKind = kind;
  // set the error kinf
  QMap<QString, StringHandler::OpenModelicaErrorKinds>::iterator it;
  for (it = mErrorKindsMap.begin(); it != mErrorKindsMap.end(); ++it)
  {
    if (it.key().compare(kind) == 0)
    {
      mErrorKind = it.value();
      return;
    }
  }
  mErrorKind = StringHandler::NoOMErrorKind;
}

/*!
  Returns the error kind.
  \return the error kind.
  */
QString MessagesTreeItem::getKind()
{
  return mKind;
}

/*!
  Sets the error level.
  \param level - the error level to set.
  */
void MessagesTreeItem::setLevel(QString level)
{
  // set the error type
  QMap<QString, StringHandler::OpenModelicaErrors>::iterator it;

  for (it = mErrorsMap.begin(); it != mErrorsMap.end(); ++it)
  {
    if (it.key().compare(level) == 0)
    {
      mType = it.value();
      return;
    }
  }
  mType = StringHandler::NoOMError;
}

/*!
  Returns the error level.
  \return the error level.
  */
QString MessagesTreeItem::getLevel()
{
  return StringHandler::errorLevelToString[mType];
}

/*!
  Sets the error id.
  \param id - the error id to set.
  */
void MessagesTreeItem::setId(int id)
{
  mId = id;
}

/*!
  Returns the error id.
  \return the error id.
  */
int MessagesTreeItem::getId()
{
  return mId;
}

/*!
  Returns the error type.
  \return the error type.
  */
int MessagesTreeItem::getType()
{
  return mType;
}

/*!
  Returns the error error kind.
  \return the error error kind.
  */
int MessagesTreeItem::getErrorKind()
{
  return mErrorKind;
}

/*!
  Sets the Message complete text by reading all its attributes.
  Always call this method when Message attributes are set.
  */
void MessagesTreeItem::setColumnsText()
{
  switch (getType())
  {
    case StringHandler::Notification:
    {
      setIcon(0, QIcon(":/Resources/icons/notificationicon.png"));
      break;
    }
    case StringHandler::Warning:
    {
      setIcon(0, QIcon(":/Resources/icons/warningicon.png"));
      break;
    }
    case StringHandler::OMError:
    {
      setIcon(0, QIcon(":/Resources/icons/erroricon.png"));
      break;
    }
  }
  setText(0, StringHandler::getErrorKind(getErrorKind()));
  setToolTip(0, StringHandler::getErrorKind(getErrorKind()));
  setText(1, QTime::currentTime().toString());
  setToolTip(1, QTime::currentTime().toString());
  setText(2, getFileName());
  setToolTip(2, getFileName());
  QString line = QString::number(getLineStart()) + ":" + QString::number(getColumnStart()) + "-" + QString::number(getLineEnd())
      + ":" + QString::number(getColumnEnd());
  setText(3, line);
  setToolTip(3, line);
  if (getMessage().length() > 500)
  {
    setText(4, getMessage().left(500).append("..."));
    setToolTip(4, qApp->tr("The error message is very long. Copy & paste it to some text editor in order to view it."));
  }
  else
  {
    setText(4, getMessage());
    setToolTip(4, getMessage());
  }
}

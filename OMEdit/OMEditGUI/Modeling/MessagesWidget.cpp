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
  \brief A tree view item/node for MessagesTreeView.
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
  mpParentMessageItem = 0;
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
  Removes all the children.
  */
void MessageItem::removeChildren()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

/*!
  Removes a child.
  */
void MessageItem::removeChild(MessageItem *pMessageItem)
{
  mChildren.removeOne(pMessageItem);
}

int MessageItem::row() const
{
  if (mpParentMessageItem) {
    return mpParentMessageItem->mChildren.indexOf(const_cast<MessageItem*>(this));
  } else {
    return 0;
  }
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
  Returns the icon for the error message based on the error type.
  */
QIcon MessageItem::getIcon() const
{
  switch (mErrorType) {
    case StringHandler::Warning:
      return QIcon(":/Resources/icons/warningicon.svg");
    case StringHandler::OMError:
      return QIcon(":/Resources/icons/erroricon.svg");
    case StringHandler::Notification:
    default:
      return QIcon(":/Resources/icons/notificationicon.svg");
  }
}

/*!
  \class MessagesModel
  \brief Data model for error messages.
  */
/*!
  \param pParent - a pointer to QObject.
  */
MessagesModel::MessagesModel(QObject *pParent)
  : QAbstractItemModel(pParent)
{
  mpRootMessageItem = new MessageItem("", false, 0, 0, 0, 0, "", "", "", 0);
}

/*!
  Returns the data for the given role and section in the header with the specified orientation.
  */
QVariant MessagesModel::headerData(int section, Qt::Orientation orientation, int role) const
{
  if (orientation == Qt::Horizontal && role == Qt::DisplayRole) {
    switch (section) {
      case 0:
        return tr("Kind");
      case 1:
        return tr("Time");
      case 2:
        return tr("Resource");
      case 3:
        return Helper::errorLocation;
      case 4:
        return tr("Message");
      default:
        return "";
    }
  } else {
    return QVariant();
  }
}

/*!
  Returns the index of the item in the model specified by the given row, column and parent index.
  */
QModelIndex MessagesModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent)) {
    return QModelIndex();
  }

  MessageItem *pParentMessageItem = 0;
  if (!parent.isValid()) {
    pParentMessageItem = mpRootMessageItem;
  } else {
    pParentMessageItem = static_cast<MessageItem*>(parent.internalPointer());
  }
  MessageItem *pChildMessageItem = pParentMessageItem->child(row);
  if (pChildMessageItem) {
    return createIndex(row, column, pChildMessageItem);
  } else {
    return QModelIndex();
  }
}

/*!
  Returns the parent of the model item with the given index. If the item has no parent, an invalid QModelIndex is returned.
  */
QModelIndex MessagesModel::parent(const QModelIndex &child) const
{
  if (!child.isValid()) {
    return QModelIndex();
  }

  MessageItem *pChildMessageItem = static_cast<MessageItem*>(child.internalPointer());
  MessageItem *pParentMessageItem = pChildMessageItem->parent();
  if (pParentMessageItem == mpRootMessageItem) {
    return QModelIndex();
  } else {
    return createIndex(pParentMessageItem->row(), 0, pParentMessageItem);
  }
}

/*!
  Returns the number of rows under the given parent.\n
  When the parent is valid it means that rowCount is returning the number of children of parent.
  */
int MessagesModel::rowCount(const QModelIndex &parent) const
{
  MessageItem *pParentMessageItem;
  if (parent.column() > 0) {
    return 0;
  }

  if (!parent.isValid()) {
    pParentMessageItem = mpRootMessageItem;
  } else {
    pParentMessageItem = static_cast<MessageItem*>(parent.internalPointer());
  }
  return pParentMessageItem->children().size();
}

/*!
  Returns the number of columns of the model.
  */
int MessagesModel::columnCount(const QModelIndex &parent) const
{
  Q_UNUSED(parent);
  return 5;
}

/*!
  Returns the data stored under the given role for the item referred to by the index.
  */
QVariant MessagesModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid()) {
    return QVariant();
  }

  MessageItem *pMessageItem = static_cast<MessageItem*>(index.internalPointer());
  QVariant variant = QVariant();
  if (pMessageItem) {
    switch (index.column()) {
      case 0:
        switch (role) {
          case Qt::DecorationRole:
            variant = pMessageItem->getIcon();
            break;
          case Qt::DisplayRole:
          case Qt::ToolTipRole:
            variant = StringHandler::getErrorKindString(pMessageItem->getErrorKind());
            break;
          default:
            break;
        }
        break;
      case 1:
        switch (role) {
          case Qt::DisplayRole:
          case Qt::ToolTipRole:
            variant = pMessageItem->getTime();
            break;
          default:
            break;
        }
        break;
      case 2:
        switch (role) {
          case Qt::DisplayRole:
          case Qt::ToolTipRole:
            variant = pMessageItem->getFileName();
            break;
          default:
            break;
        }
        break;
      case 3:
        switch (role) {
          case Qt::DisplayRole:
          case Qt::ToolTipRole:
            variant = pMessageItem->getLocation();
            break;
          default:
            break;
        }
        break;
      case 4:
        switch (role) {
          case Qt::DisplayRole:
          case Qt::ToolTipRole:
            variant = pMessageItem->getMessage();
            break;
          default:
            break;
        }
        break;
    }
  }
  return variant;
}

/*!
  Returns the depth/level of the QModelIndex.\n
  Needed by ItemDelegate to properly word wrap the top level and child items.
  */
int MessagesModel::getDepth(const QModelIndex &index) const
{
  QModelIndex index1 = index;
  int depth = 1;
  while (index1.parent().isValid()) {
    index1 = index1.parent();
    MessageItem *pMessageItem = static_cast<MessageItem*>(index.internalPointer());
    if (pMessageItem == mpRootMessageItem) {
      break;
    }
    depth++;
  }
  return depth;
}

/*!
  Adds the error message to the model.
  */
void MessagesModel::addMessageItem(MessageItem *pMessageItem)
{
  if (pMessageItem) {
    int row = mpRootMessageItem->children().size();
    beginInsertRows(QModelIndex(), row, row);
    mpRootMessageItem->insertChild(row, pMessageItem);
    endInsertRows();
  }
}

/*!
  Removes the error message from the model.
  */
void MessagesModel::removeMessageItem(QModelIndex &index)
{
  MessageItem *pMessageItem = static_cast<MessageItem*>(index.internalPointer());
  if (pMessageItem) {
    beginRemoveRows(index, 0, pMessageItem->children().size());
    pMessageItem->removeChildren();
    MessageItem *pParentMessageItem = pMessageItem->parent();
    pParentMessageItem->removeChild(pMessageItem);
    endRemoveRows();
    pMessageItem->deleteLater();
  }
}

/*!
  \class MessagesProxyModel
  \brief Interface for sorting and filtering the error messages.
  */
MessagesProxyModel::MessagesProxyModel(QObject *parent)
  : QSortFilterProxyModel(parent)
{
  setDynamicSortFilter(true);
}

/*!
  Emits the QAbstractItemModel::layoutChanged which calls the ItemDelegate::sizeHint.\n
  This is needed for views which shows rich text using QTextDocument.\n
  The ItemDelegate then automatically word wraps the text and finds the optimal height for multiline items.
  */
void MessagesProxyModel::callLayoutChanged()
{
  emit layoutAboutToBeChanged();
  emit layoutChanged();
}

/*!
  Filters the error messages based on the error type filter.
  */
bool MessagesProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
  if (!filterRegExp().isEmpty()) {
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    if (index.isValid()) {
      MessageItem *pMessageItem = static_cast<MessageItem*>(index.internalPointer());
      if (pMessageItem) {
        QString errorType = StringHandler::getErrorTypeString(pMessageItem->getErrorType());
        return errorType.contains(filterRegExp());
      } else {
        return false;
      }
    }
  }
  return QSortFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent);
}

/*!
  \class MessagesTreeView
  \brief A tree based structure for OMC error messages. Creates three types of messages i.e notification ,warning, error.
  */
/*!
  \param pMessagesWidget - a pointer to MessagesWidget.
  */
MessagesTreeView::MessagesTreeView(MessagesWidget *pMessagesWidget)
  : QTreeView(pMessagesWidget), mpMessagesWidget(pMessagesWidget)
{
  setItemDelegate(new ItemDelegate(this, true));
  setTextElideMode(Qt::ElideMiddle);
  setSelectionMode(QAbstractItemView::ExtendedSelection);
  setIndentation(0);
  setExpandsOnDoubleClick(false);
  setIconSize(QSize(16, 16));
  setContentsMargins(0, 0, 0, 0);
  setContextMenuPolicy(Qt::CustomContextMenu);
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  connect(header(), SIGNAL(sectionResized(int,int,int)), SLOT(callLayoutChanged(int,int,int)));
  // create actions
  mpSelectAllAction = new QAction(tr("Select All"), this);
  mpSelectAllAction->setShortcut(QKeySequence("Ctrl+a"));
  mpSelectAllAction->setStatusTip(tr("Selects all the Messages"));
  connect(mpSelectAllAction, SIGNAL(triggered()), SLOT(selectAllMessages()));
  mpCopyAction = new QAction(QIcon(":/Resources/icons/copy.svg"), Helper::copy, this);
  mpCopyAction->setShortcut(QKeySequence("Ctrl+c"));
  mpCopyAction->setStatusTip(tr("Copy the Message"));
  connect(mpCopyAction, SIGNAL(triggered()), SLOT(copyMessages()));
  mpRemoveAction = new QAction(QIcon(":/Resources/icons/delete.svg"), Helper::remove, this);
  mpRemoveAction->setShortcut(QKeySequence::Delete);
  mpRemoveAction->setStatusTip(tr("Remove the Message"));
  connect(mpRemoveAction, SIGNAL(triggered()), SLOT(removeMessages()));
}

/*!
  Asks the model about the depth/level of QModelIndex.
  */
int MessagesTreeView::getDepth(const QModelIndex &index) const
{
  MessagesModel *pMessagesModel = qobject_cast<MessagesModel*>(model());
  if (pMessagesModel) {
    return pMessagesModel->getDepth(index);
  } else {
    return 1;
  }
}

/*!
  Shows a context menu when user right click on the Messages tree.
  Slot activated when Message::customContextMenuRequested() signal is raised.
  */
void MessagesTreeView::showContextMenu(QPoint point)
{
  QMenu menu(this);
  menu.addAction(mpSelectAllAction);
  menu.addAction(mpCopyAction);
  menu.addAction(mpRemoveAction);
  menu.exec(viewport()->mapToGlobal(point));
}

/*!
  Slot activated when QHeaderView sectionResized signal is raised.\n
  Tells the model to emit layoutChanged signal.\n
  \sa MessagesModel::callLayoutChanged()
  */
void MessagesTreeView::callLayoutChanged(int logicalIndex, int oldSize, int newSize)
{
  Q_UNUSED(logicalIndex);
  Q_UNUSED(oldSize);
  Q_UNUSED(newSize);
  mpMessagesWidget->getMessagesProxyModel()->callLayoutChanged();
}

/*!
  Selects all the Messages.
  Slot activated when mpSelectAllAction triggered signal is raised.
  */
void MessagesTreeView::selectAllMessages()
{
  selectAll();
}

/*!
  Copy the selected Messages to the clipboard.
  Slot activated when mpCopyAction triggered signal is raised.
  */
void MessagesTreeView::copyMessages()
{
  QStringList textToCopy;
  const QModelIndexList modelIndexes = selectionModel()->selectedRows();
  foreach (QModelIndex modelIndex, modelIndexes) {
    modelIndex = mpMessagesWidget->getMessagesProxyModel()->mapToSource(modelIndex);
    MessageItem *pMessageItem = static_cast<MessageItem*>(modelIndex.internalPointer());
    if (pMessageItem) {
      QString file = pMessageItem->getFileName();
      QString location = pMessageItem->getLocation();
      QString type = StringHandler::getErrorTypeDisplayString(pMessageItem->getErrorType());
      QString message = pMessageItem->getMessage();
      textToCopy.append(QString("[%1:%2] %3: %4").arg(file).arg(location).arg(type).arg(message));
    }
  }
  QApplication::clipboard()->setText(textToCopy.join("\n"));
}

/*!
  Removes the selected Messages.
  Slot activated when mpRemoveAction triggered signal is raised.
  */
void MessagesTreeView::removeMessages()
{
  int i = 0;
  while(i < selectionModel()->selectedRows().size()) {
    QModelIndex index = mpMessagesWidget->getMessagesProxyModel()->mapToSource(selectionModel()->selectedRows()[i]);
    mpMessagesWidget->getMessagesModel()->removeMessageItem(index);
    i = 0;   //Restart iteration
  }
}

/*!
  Reimplementation of keypressevent.
  Defines what to do for Ctrl+A, Ctrl+C and Del buttons.
  */
void MessagesTreeView::keyPressEvent(QKeyEvent *event)
{
  bool controlModifier = event->modifiers().testFlag(Qt::ControlModifier);
  if (controlModifier && event->key() == Qt::Key_A) {
    selectAllMessages();
  } else if (controlModifier && event->key() == Qt::Key_C) {
    copyMessages();
  } else if (event->key() == Qt::Key_Delete) {
    removeMessages();
  } else {
    QTreeView::keyPressEvent(event);
  }
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
  // creates Messages tree
  mpMessagesTreeView = new MessagesTreeView(this);
  mpMessagesModel = new MessagesModel(this);
  mpMessagesProxyModel = new MessagesProxyModel;
  mpMessagesProxyModel->setSourceModel(mpMessagesModel);
  mpMessagesTreeView->setModel(mpMessagesProxyModel);
  connect(mpMessagesModel, SIGNAL(rowsInserted(QModelIndex,int,int)), mpMessagesProxyModel, SLOT(invalidate()));
  connect(mpMessagesModel, SIGNAL(rowsRemoved(QModelIndex,int,int)), mpMessagesProxyModel, SLOT(invalidate()));
  // create button for only showing notifications
  mpShowNotificationsToolButton = new QToolButton;
  QString showNotificationMsg = tr("Only Show Notifications");
  mpShowNotificationsToolButton->setIcon(QIcon(":/Resources/icons/notificationicon.svg"));
  mpShowNotificationsToolButton->setText(showNotificationMsg);
  mpShowNotificationsToolButton->setToolTip(showNotificationMsg);
  mpShowNotificationsToolButton->setCheckable(true);
  mpShowNotificationsToolButton->setAutoRaise(true);
  connect(mpShowNotificationsToolButton, SIGNAL(clicked()), SLOT(showNotifications()));
  // create button for only showing warnings
  mpShowWarningsToolButton = new QToolButton;
  mpShowWarningsToolButton->setIcon(QIcon(":/Resources/icons/warningicon.svg"));
  QString showWarningsMsg = tr("Only Show Warnings");
  mpShowWarningsToolButton->setText(showWarningsMsg);
  mpShowWarningsToolButton->setToolTip(showWarningsMsg);
  mpShowWarningsToolButton->setCheckable(true);
  mpShowWarningsToolButton->setAutoRaise(true);
  connect(mpShowWarningsToolButton, SIGNAL(clicked()), SLOT(showWarnings()));
  // create button for only showing errors
  mpShowErrorsToolButton = new QToolButton;
  mpShowErrorsToolButton->setIcon(QIcon(":/Resources/icons/erroricon.svg"));
  QString showErrorsMsg = tr("Only Show Errors");
  mpShowErrorsToolButton->setText(showErrorsMsg);
  mpShowErrorsToolButton->setToolTip(showErrorsMsg);
  mpShowErrorsToolButton->setCheckable(true);
  mpShowErrorsToolButton->setAutoRaise(true);
  connect(mpShowErrorsToolButton, SIGNAL(clicked()), SLOT(showErrors()));
  // create button for showing all Messages
  mpShowAllMessagesToolButton = new QToolButton;
  mpShowAllMessagesToolButton->setIcon(QIcon(":/Resources/icons/messages.svg"));
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
  mpClearMessagesToolButton->setIcon(QIcon(":/Resources/icons/clear.svg"));
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
  layout->addWidget(mpMessagesTreeView);
  layout->addLayout(buttonsLayout);
  setLayout(layout);
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
  Tells the underlying data handler to add the error message.\n
  Moves to the most recent error message in the view.
  */
void MessagesWidget::addGUIMessage(MessageItem *pMessageItem)
{
  pMessageItem->setParent(mpMessagesModel->getRootMessageItem());
  mpMessagesModel->addMessageItem(pMessageItem);
  mpMessagesTreeView->scrollToBottom();
  mpShowAllMessagesToolButton->setChecked(true);
  emit MessageAdded();
}

/*!
  Clears all the Messages.
  Slot activated when mpClearMessagesToolButton clicked signal is raised.
  */
void MessagesWidget::clearMessages()
{
  mpMessagesTreeView->selectAllMessages();
  mpMessagesTreeView->removeMessages();
}

/*!
  Filter the Messages tree and only show the notification type Messages.
  Slot activated when mpShowNotificationsToolButton clicked signal is raised.
  */
void MessagesWidget::showNotifications()
{
  QRegExp regExp(Helper::notificationLevel, Qt::CaseSensitive, QRegExp::FixedString);
  mpMessagesProxyModel->setFilterRegExp(regExp);
}

/*!
  Filter the Messages tree and only show the warning type Messages.
  Slot activated when mpShowWarningsToolButton clicked signal is raised.
  */
void MessagesWidget::showWarnings()
{
  QRegExp regExp(Helper::warningLevel, Qt::CaseSensitive, QRegExp::FixedString);
  mpMessagesProxyModel->setFilterRegExp(regExp);
}

/*!
  Filter the Messages tree and only show the error type Messages.
  Slot activated when mpShowErrorsToolButton clicked signal is raised.
  */
void MessagesWidget::showErrors()
{
  QRegExp regExp(Helper::errorLevel, Qt::CaseSensitive, QRegExp::FixedString);
  mpMessagesProxyModel->setFilterRegExp(regExp);
}

/*!
  Shows all type of Messages.
  Slot activated when mpShowAllMessagesToolButton clicked signal is raised.
  */
void MessagesWidget::showAllMessages()
{
  mpMessagesProxyModel->setFilterRegExp(QRegExp(""));
}

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

#ifndef MESSAGESWIDGET_H
#define MESSAGESWIDGET_H

#include "MainWindow.h"

class MainWindow;
class StringHandler;

class MessagesWidget;

class MessageItem : public QObject
{
  Q_OBJECT
public:
  MessageItem* mpParentMessageItem;
  QString mTime;
  QString mFileName;
  bool mReadOnly;
  int mLineStart;
  int mColumnStart;
  int mLineEnd;
  int mColumnEnd;
  QString mMessage;
  QString mKind;
  StringHandler::OpenModelicaErrorKinds mErrorKind;
  StringHandler::OpenModelicaErrors mErrorType;
  int mId;
  QList<MessageItem*> mChildren;
public:
  MessageItem(QString filename, bool readOnly, int lineStart, int columnStart, int lineEnd, int columnEnd, QString message, QString errorKind,
              QString errorType, int id);
  void setParent(MessageItem *pParentMessageItem) {mpParentMessageItem = pParentMessageItem;}
  MessageItem *parent() {return mpParentMessageItem;}
  MessageItem *child(int row) {return mChildren.value(row);}
  QList<MessageItem*> children() const {return mChildren;}
  void insertChild(int position, MessageItem *pMessageItem) {mChildren.insert(position, pMessageItem);}
  void removeChildren();
  void removeChild(MessageItem *pMessageItem);
  int row() const;
  QString getTime() {return mTime;}
  QString getFileName() {return mFileName;}
  QString getLocation();
  QString getMessage() {return mMessage;}
  QIcon getIcon() const;
  StringHandler::OpenModelicaErrorKinds getErrorKind() {return mErrorKind;}
  StringHandler::OpenModelicaErrors getErrorType() {return mErrorType;}
};

class MessagesModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  MessagesModel(QObject *pParent);
  virtual QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const;
  virtual QModelIndex index(int row, int column, const QModelIndex &parent) const;
  virtual QModelIndex parent(const QModelIndex &child) const;
  virtual int rowCount(const QModelIndex &parent) const;
  virtual int columnCount(const QModelIndex &parent) const;
  virtual QVariant data(const QModelIndex &index, int role) const;
  MessageItem* getRootMessageItem() {return mpRootMessageItem;}
  int getDepth(const QModelIndex &index) const;
  void addMessageItem(MessageItem *pMessageItem);
  void removeMessageItem(QModelIndex &index);
private:
  MessageItem* mpRootMessageItem;
};

class MessagesProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT
public:
  MessagesProxyModel(QObject *parent = 0);
  void callLayoutChanged();
protected:
  virtual bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;
};

class MessagesTreeView : public QTreeView
{
  Q_OBJECT
private:
  MessagesWidget *mpMessagesWidget;
  QAction *mpSelectAllAction;
  QAction *mpCopyAction;
  QAction *mpRemoveAction;
public:
  MessagesTreeView(MessagesWidget *pMessagesWidget);
  MessagesWidget* getMessagesWidget() {return mpMessagesWidget;}
  int getDepth(const QModelIndex &index) const;
public slots:
  void showContextMenu(QPoint point);
  void callLayoutChanged(int logicalIndex, int oldSize, int newSize);
  void selectAllMessages();
  void copyMessages();
  void removeMessages();
protected:
  virtual void keyPressEvent(QKeyEvent *event);
};

class MessagesWidget : public QWidget
{
  Q_OBJECT
private:
  MainWindow *mpMainWindow;
  MessagesTreeView *mpMessagesTreeView;
  MessagesModel *mpMessagesModel;
  MessagesProxyModel *mpMessagesProxyModel;
  QToolButton *mpClearMessagesToolButton;
  QToolButton *mpShowNotificationsToolButton;
  QToolButton *mpShowWarningsToolButton;
  QToolButton *mpShowErrorsToolButton;
  QToolButton *mpShowAllMessagesToolButton;
  QButtonGroup *mpMessagesButtonGroup;
public:
  MessagesWidget(MainWindow *pMainWindow);
  MessagesModel* getMessagesModel() {return mpMessagesModel;}
  MessagesProxyModel* getMessagesProxyModel() {return mpMessagesProxyModel;}
  QSize sizeHint() const;
  void addGUIMessage(MessageItem *pMessageItem);
signals:
  void MessageAdded();
private slots:
  void clearMessages();
  void showNotifications();
  void showWarnings();
  void showErrors();
  void showAllMessages();
};

#endif // MESSAGESWIDGET_H

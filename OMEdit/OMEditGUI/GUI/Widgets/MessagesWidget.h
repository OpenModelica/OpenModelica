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

#ifndef MESSAGESWIDGET_H
#define MESSAGESWIDGET_H

#include "MainWindow.h"

class MainWindow;
class MessagesTreeWidget;
class MessagesTreeItem;
class StringHandler;

class MessagesWidget : public QWidget
{
  Q_OBJECT
private:
  MainWindow *mpMainWindow;
  MessagesTreeWidget *mpMessagesTreeWidget;
  QToolButton *mpClearMessagesToolButton;
  QToolButton *mpShowNotificationsToolButton;
  QToolButton *mpShowWarningsToolButton;
  QToolButton *mpShowErrorsToolButton;
  QToolButton *mpShowAllMessagesToolButton;
  QButtonGroup *mpMessagesButtonGroup;
public:
  MessagesWidget(MainWindow *pMainWindow);
  MessagesTreeWidget* getMessagesTreeWidget();
  QSize sizeHint() const;
  void addGUIMessage(MessagesTreeItem *pMessageItem);
signals:
  void MessageAdded();
private slots:
  void clearMessages();
  void showNotifications();
  void showWarnings();
  void showErrors();
  void showAllMessages();
};

class MessagesTreeWidget : public QTreeWidget
{
  Q_OBJECT
private:
  MessagesWidget *mpMessagesWidget;
  QAction *mpSelectAllAction;
  QAction *mpCopyAction;
  QAction *mpRemoveAction;
public:
  MessagesTreeWidget(MessagesWidget *pMessagesWidget);
private slots:
  void showContextMenu(QPoint point);
  void selectAllMessages();
  void copyMessages();
  void removeMessages();
protected:
  virtual void keyPressEvent(QKeyEvent *event);
};

class MessagesTreeItem : public QTreeWidgetItem
{
public:
  MessagesTreeItem(MessagesTreeWidget *pParent = 0);
  MessagesTreeItem(QString filename, bool readOnly, int lineStart, int columnStart, int lineEnd, int columnEnd, QString message, QString kind,
              QString level, int id, MessagesTreeWidget *pParent = 0);
  void initialize();
  void setFileName(QString fileName);
  QString getFileName();
  void setReadOnly(bool readOnly);
  bool getReadOnly();
  void setLineStart(int lineStart);
  int getLineStart();
  void setColumnStart(int columnStart);
  int getColumnStart();
  void setLineEnd(int lineEnd);
  int getLineEnd();
  void setColumnEnd(int columnEnd);
  int getColumnEnd();
  void setMessage(QString message);
  QString getMessage();
  void setKind(QString kind);
  QString getKind();
  void setLevel(QString level);
  QString getLevel();
  void setId(int id);
  int getId();
  int getType();
  int getErrorKind();
  void setColumnsText();
private:
  MessagesTreeWidget *mpMessagesTreeWidget;
  QString mFileName;
  bool mReadOnly;
  int mLineStart;
  int mColumnStart;
  int mLineEnd;
  int mColumnEnd;
  QString mMessage;
  QString mKind;
  QString mLevel;
  int mId;
  QMap<QString, StringHandler::OpenModelicaErrors> mErrorsMap;
  int mType;
  QMap<QString, StringHandler::OpenModelicaErrorKinds> mErrorKindsMap;
  int mErrorKind;
};

#endif // MESSAGESWIDGET_H

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

#ifndef MESSAGESWIDGET_H
#define MESSAGESWIDGET_H

#include "Util/StringHandler.h"

#include <QTextBrowser>

class MessageItem
{
public:
  enum MessageItemType {
    Modelica,   /* Used to represent error messages of Modelica models. */
    CompositeModel   /* Used to represent error messages of CompositeModel files. */
  };
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
public:
  MessageItem();
  MessageItem(MessageItemType type ,QString filename, bool readOnly, int lineStart, int columnStart, int lineEnd, int columnEnd, QString message, QString errorKind,
              QString errorType);
  MessageItemType getMessageItemType() {return mMessageItemType;}
  QString getTime() {return mTime;}
  QString getFileName() {return mFileName;}
  QString getLineStart() {return QString::number(mLineStart);}
  QString getLocation();
  QString getMessage() {return mMessage;}
  StringHandler::OpenModelicaErrorKinds getErrorKind() {return mErrorKind;}
  StringHandler::OpenModelicaErrors getErrorType() {return mErrorType;}
private:
  MessageItemType mMessageItemType;
};

class MessageWidget : public QWidget
{
  Q_OBJECT
private:
  int mMessageNumber;
  QTextBrowser *mpMessagesTextBrowser;
  QAction *mpSelectAllAction;
  QAction *mpCopyAction;
  QAction *mpClearThisTabAction;
  QAction *mpClearAllTabsAction;
public:
  MessageWidget(QWidget *pParent = 0);
  void resetMessagesNumber() {mMessageNumber = 1;}
  QTextBrowser* getMessagesTextBrowser() {return mpMessagesTextBrowser;}
  void applyMessagesSettings();
  void addGUIMessage(MessageItem messageItem);
private slots:
  void openErrorMessageClass(QUrl url);
  void showContextMenu(QPoint point);
public slots:
  void clearThisTabMessages();
  void clearAllTabsMessages();
};

class MessagesWidget : public QWidget
{
  Q_OBJECT
private:
  // the only class that is allowed to create and destroy
  friend class MainWindow;

  static void create();
  static void destroy();
  MessagesWidget(QWidget *pParent = 0);

  static MessagesWidget *mpInstance;
  QTabWidget *mpMessagesTabWidget;
  MessageWidget *mpAllMessageWidget;
  MessageWidget *mpNotificationMessageWidget;
  MessageWidget *mpWarningMessageWidget;
  MessageWidget *mpErrorMessageWidget;

  QStringList mSuppressMessagesList;

public:
  static MessagesWidget* instance() {return mpInstance;}
  MessageWidget* getAllMessageWidget() {return mpAllMessageWidget;}
  MessageWidget* getNotificationMessageWidget() {return mpNotificationMessageWidget;}
  MessageWidget* getWarningMessageWidget() {return mpWarningMessageWidget;}
  MessageWidget* getErrorMessageWidget() {return mpErrorMessageWidget;}
  void resetMessagesNumber();
  void applyMessagesSettings();
signals:
  void MessageAdded();
public slots:
  void addGUIMessage(MessageItem messageItem);
  void clearMessages();
};

#endif // MESSAGESWIDGET_H

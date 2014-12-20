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
public:
  MessageItem(QString filename, bool readOnly, int lineStart, int columnStart, int lineEnd, int columnEnd, QString message, QString errorKind,
              QString errorType, int id);
  QString getTime() {return mTime;}
  QString getFileName() {return mFileName;}
  QString getLineStart() {return QString::number(mLineStart);}
  QString getLocation();
  QString getMessage() {return mMessage;}
  StringHandler::OpenModelicaErrorKinds getErrorKind() {return mErrorKind;}
  StringHandler::OpenModelicaErrors getErrorType() {return mErrorType;}
};

class MessagesWidget : public QWidget
{
  Q_OBJECT
private:
  MainWindow *mpMainWindow;
  QTextBrowser *mpMessagesTextBrowser;
  QAction *mpSelectAllAction;
  QAction *mpCopyAction;
  QAction *mpClearAllAction;
public:
  MessagesWidget(MainWindow *pMainWindow);
  QTextBrowser* getMessagesTextBrowser() {return mpMessagesTextBrowser;}
  void applyMessagesSettings();
  void addGUIMessage(MessageItem *pMessageItem);
signals:
  void MessageAdded();
private slots:
  void openErrorMessageClass(QUrl url);
  void showContextMenu(QPoint point);
};

#endif // MESSAGESWIDGET_H

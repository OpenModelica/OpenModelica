/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 *
 */

/*
 * HopsanGUI
 * Fluid and Mechatronic Systems, Department of Management and Engineering, Linkoping University
 * Main Authors 2009-2010:  Robert Braun, Bjorn Eriksson, Peter Nordin
 * Contributors 2009-2010:  Mikael Axin, Alessandro Dell'Amico, Karl Pettersson, Ingo Staack
 */

#ifndef MESSAGEWIDGET_H
#define MESSAGEWIDGET_H

#include <QtCore>
#include <QtGui>
#include "mainwindow.h"

class MainWindow;
class Problem;
class ProblemItem;
class StringHandler;

class ProblemsWidget : public QWidget
{
    Q_OBJECT
public:
    ProblemsWidget(MainWindow *pParent);

    MainWindow *mpParentMainWindow;
    Problem *mpProblem;
    QToolButton *mpClearProblemsToolButton;
    QToolButton *mpShowNotificationsToolButton;
    QToolButton *mpShowWarningsToolButton;
    QToolButton *mpShowErrorsToolButton;
    QToolButton *mpShowAllProblemsToolButton;
    QButtonGroup *mpProblemsButtonGroup;

    QSize sizeHint() const;
    void addGUIProblem(ProblemItem *pProblemItem);
private slots:
    void clearProblems();
    void showNotifications();
    void showWarnings();
    void showErrors();
    void showAllProblems();
};

class Problem : public QTreeWidget
{
    Q_OBJECT
private:
    QAction *mpCopyAction;
    QAction *mpCopyAllAction;
    QAction *mpRemoveAction;
public:
    Problem(ProblemsWidget *pParent);

    ProblemsWidget *mpMessageWidget;
private slots:
    void showContextMenu(QPoint point);
    void copyProblems();
    void copyAllProblems();
    void removeProblems();
protected:
    virtual void keyPressEvent(QKeyEvent *event);
};

class ProblemItem : public QTreeWidgetItem
{
public:
    ProblemItem(Problem *pParent = 0);
    ProblemItem(QString filename, bool readOnly, int lineStart, int columnStart, int lineEnd, int columnEnd, QString message, QString kind,
                QString level, int id, Problem *pParent = 0);
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

    Problem *mpParentProblem;
private:
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
    QMap<QString, StringHandler::ModelicaErrors> mErrorsMap;
    int mType;
    QMap<QString, StringHandler::ModelicaErrorKinds> mErrorKindsMap;
    int mErrorKind;
};

#endif // MESSAGEWIDGET_H

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

#include "MessageWidget.h"
#include "mainwindow.h"

//! @class MessageWidget
//! @brief It creates a tab based messages window.
//! It contains three tabs General, Info, Problems.

//! Constructor
//! @param pParent defines a parent to the new instanced object. pParent is the MainWindow object.
MessageWidget::MessageWidget(MainWindow *pParent)
    : QTabWidget(pParent)
{
    setObjectName(tr("MessagesTab"));
    mpParentMainWindow = pParent;
    // creates general messages window
    mpGeneralMessages = new GeneralMessages(this);
    addTab(mpGeneralMessages, QString("General"));
    // creates info messages window
    mpInfoMessages = new InfoMessages(this);
    addTab(mpInfoMessages, QString("Info"));
    // creates Problems window
    mpProblem = new Problem(this);
    addTab(mpProblem, QString("Problems"));
    // create button for clearing problems
    mpClearProblemsToolButton = new QToolButton;
    mpClearProblemsToolButton->setContentsMargins(0, 0, 0, 0);
    mpClearProblemsToolButton->setText(Helper::clearProblems);
    mpClearProblemsToolButton->setIcon(QIcon(":/Resources/icons/clearproblems.png"));
    mpClearProblemsToolButton->setToolTip(Helper::clearProblems);
    mpClearProblemsToolButton->setAutoRaise(true);
    connect(mpClearProblemsToolButton, SIGNAL(clicked()), SLOT(clearProblems()));
    // create button for clearing info messages
    mpClearInfoMessagesToolButton = new QToolButton;
    mpClearInfoMessagesToolButton->setContentsMargins(0, 0, 0, 0);
    mpClearInfoMessagesToolButton->setText(Helper::clearInfoMessages);
    mpClearInfoMessagesToolButton->setIcon(QIcon(":/Resources/icons/clearinfo.png"));
    mpClearInfoMessagesToolButton->setToolTip(Helper::clearInfoMessages);
    mpClearInfoMessagesToolButton->setAutoRaise(true);
    connect(mpClearInfoMessagesToolButton, SIGNAL(clicked()), SLOT(clearInfoMessages()));
    // create button for clearing problems
    mpClearGeneralMessagesToolButton = new QToolButton;
    mpClearGeneralMessagesToolButton->setContentsMargins(0, 0, 0, 0);
    mpClearGeneralMessagesToolButton->setText(Helper::clearGeneralMessages);
    mpClearGeneralMessagesToolButton->setIcon(QIcon(":/Resources/icons/cleargeneral.png"));
    mpClearGeneralMessagesToolButton->setToolTip(Helper::clearGeneralMessages);
    mpClearGeneralMessagesToolButton->setAutoRaise(true);
    connect(mpClearGeneralMessagesToolButton, SIGNAL(clicked()), SLOT(clearGeneralMessages()));
    // create button for only showing notifications
    mpShowNotificationsToolButton = new QToolButton;
    mpShowNotificationsToolButton->setText(Helper::showNotifications);
    mpShowNotificationsToolButton->setIcon(QIcon(":/Resources/icons/notificationicon.png"));
    mpShowNotificationsToolButton->setToolTip(Helper::showNotifications);
    mpShowNotificationsToolButton->setCheckable(true);
    mpShowNotificationsToolButton->setAutoRaise(true);
    connect(mpShowNotificationsToolButton, SIGNAL(clicked()), SLOT(showNotifications()));
    // create button for only showing warnings
    mpShowWarningsToolButton = new QToolButton;
    mpShowWarningsToolButton->setText(Helper::showWarnings);
    mpShowWarningsToolButton->setIcon(QIcon(":/Resources/icons/warningicon.png"));
    mpShowWarningsToolButton->setToolTip(Helper::showWarnings);
    mpShowWarningsToolButton->setCheckable(true);
    mpShowWarningsToolButton->setAutoRaise(true);
    connect(mpShowWarningsToolButton, SIGNAL(clicked()), SLOT(showWarnings()));
    // create button for only showing errors
    mpShowErrorsToolButton = new QToolButton;
    mpShowErrorsToolButton->setText(Helper::showErrors);
    mpShowErrorsToolButton->setIcon(QIcon(":/Resources/icons/erroricon.png"));
    mpShowErrorsToolButton->setToolTip(Helper::showErrors);
    mpShowErrorsToolButton->setCheckable(true);
    mpShowErrorsToolButton->setAutoRaise(true);
    connect(mpShowErrorsToolButton, SIGNAL(clicked()), SLOT(showErrors()));
    // create button for showing all problems
    mpShowAllProblemsToolButton = new QToolButton;
    mpShowAllProblemsToolButton->setText(Helper::showAllProblems);
    mpShowAllProblemsToolButton->setIcon(QIcon(":/Resources/icons/problems.png"));
    mpShowAllProblemsToolButton->setToolTip(Helper::showAllProblems);
    mpShowAllProblemsToolButton->setCheckable(true);
    mpShowAllProblemsToolButton->setChecked(true);
    mpShowAllProblemsToolButton->setAutoRaise(true);
    connect(mpShowAllProblemsToolButton, SIGNAL(clicked()), SLOT(showAllProblems()));
    // create button group
    mpProblemsButtonGroup = new QButtonGroup;
    mpProblemsButtonGroup->setExclusive(true);
    mpProblemsButtonGroup->addButton(mpShowNotificationsToolButton);
    mpProblemsButtonGroup->addButton(mpShowWarningsToolButton);
    mpProblemsButtonGroup->addButton(mpShowErrorsToolButton);
    mpProblemsButtonGroup->addButton(mpShowAllProblemsToolButton);
    // create corner widget
    QFrame *pCornerWidget = new QFrame(this);
    pCornerWidget->resize(tabBar()->width(), tabBar()->height());
    QHBoxLayout *pCornerWidgetLayout = new QHBoxLayout;
    pCornerWidgetLayout->setContentsMargins(0, 0, 2, 1);
    pCornerWidgetLayout->setSpacing(2);
    pCornerWidgetLayout->addWidget(mpShowNotificationsToolButton);
    pCornerWidgetLayout->addWidget(mpShowWarningsToolButton);
    pCornerWidgetLayout->addWidget(mpShowErrorsToolButton);
    pCornerWidgetLayout->addWidget(mpShowAllProblemsToolButton);
    QFrame *verticalLine = new QFrame;
    verticalLine->setFrameShape(QFrame::VLine);
    verticalLine->setFrameShadow(QFrame::Sunken);
    pCornerWidgetLayout->addWidget(verticalLine);
    pCornerWidgetLayout->addWidget(mpClearGeneralMessagesToolButton);
    pCornerWidgetLayout->addWidget(mpClearInfoMessagesToolButton);
    pCornerWidgetLayout->addWidget(mpClearProblemsToolButton);
    pCornerWidget->setLayout(pCornerWidgetLayout);
    setCornerWidget(pCornerWidget);
    // set timers for blinking tabs
    QSignalMapper *pSingnalMapper = new QSignalMapper;
    mpGeneralTabTimer = new QTimer;
    mpGeneralTabTimer->setInterval(1000);
    pSingnalMapper->setMapping(mpGeneralTabTimer, mpGeneralMessages);
    mpInfoTabTimer = new QTimer;
    mpInfoTabTimer->setInterval(1000);
    pSingnalMapper->setMapping(mpInfoTabTimer, mpInfoMessages);
    mpProblemsTabTimer = new QTimer;
    mpProblemsTabTimer->setInterval(1000);
    pSingnalMapper->setMapping(mpProblemsTabTimer, mpProblem);
    connect(mpGeneralTabTimer, SIGNAL(timeout()), pSingnalMapper, SLOT(map()));
    connect(mpInfoTabTimer, SIGNAL(timeout()), pSingnalMapper, SLOT(map()));
    connect(mpProblemsTabTimer, SIGNAL(timeout()), pSingnalMapper, SLOT(map()));
    connect(pSingnalMapper, SIGNAL(mapped(QWidget*)), SLOT(startTitleBlink(QWidget*)));
    connect(this, SIGNAL(currentChanged(int)), SLOT(stopTitleBlink(int)));
}

//! Reimplementation of sizeHint function. Defines the minimum height.
QSize MessageWidget::sizeHint() const
{
    QSize size = QTabWidget::sizeHint();
    //Set very small height. A minimum apperantly stops at resonable size.
    size.rheight() = 125; //pixels
    return size;
}

//! Calls the GeneralMessage::printGUIMessage
//! @param message is the string that is passed.
void MessageWidget::printGUIMessage(QString message)
{
    mpGeneralMessages->printGUIMessage(message);
    if (!dynamic_cast<GeneralMessages*>(currentWidget()))
    {
        mpGeneralTabTimer->start();
    }
}

//! Calls the InfoMessage::printGUIMessage
//! @param message is the string that is passed.
void MessageWidget::printGUIInfoMessage(QString message)
{
    mpInfoMessages->printGUIMessage(message);
    if (!dynamic_cast<InfoMessages*>(currentWidget()))
    {
        mpInfoTabTimer->start();
    }
}

//! Adds the problem to the Problems tree.
//! If Problems tab is not selected then start blinking the tab.
//! @param pProblemItem is the Problem to add.
void MessageWidget::addGUIProblem(ProblemItem *pProblemItem)
{
    mpProblem->addTopLevelItem(pProblemItem);
    mpProblem->scrollToBottom();
    mpShowAllProblemsToolButton->setChecked(true);
    // if the Problems tab is not selected then start blinking it.
    if (!dynamic_cast<Problem*>(currentWidget()))
    {
        mpProblemsTabTimer->start();
    }
}

//! Clears all the problems.
//! Slot activated when mpClearProblemsToolButton clicked signal is raised.
void MessageWidget::clearProblems()
{
    int i = 0;
    while(i < mpProblem->topLevelItemCount())
    {
        qDeleteAll(mpProblem->topLevelItem(i)->takeChildren());
        delete mpProblem->topLevelItem(i);
        i = 0;   //Restart iteration
    }
}

//! Clears all the general messages.
//! Slot activated when mpClearGeneralMessagesToolButton clicked signal is raised.
void MessageWidget::clearGeneralMessages()
{
    mpGeneralMessages->clear();
}

//! Clears all the info messages.
//! Slot activated when mpClearInfoMessagesToolButton clicked signal is raised.
void MessageWidget::clearInfoMessages()
{
    mpInfoMessages->clear();
}

//! Filter the Problems tree and only show the notification type problems.
//! Slot activated when mpShowNotificationsToolButton clicked signal is raised.
void MessageWidget::showNotifications()
{
    QTreeWidgetItemIterator it(mpProblem);
    while (*it)
    {
        ProblemItem *pProblemItem = dynamic_cast<ProblemItem*>(*it);
        if (pProblemItem->getType() == StringHandler::NOTIFICATION)
            pProblemItem->setHidden(false);
        else
            pProblemItem->setHidden(true);
        ++it;
    }
}

//! Filter the Problems tree and only show the warning type problems.
//! Slot activated when mpShowWarningsToolButton clicked signal is raised.
void MessageWidget::showWarnings()
{
    QTreeWidgetItemIterator it(mpProblem);
    while (*it)
    {
        ProblemItem *pProblemItem = dynamic_cast<ProblemItem*>(*it);
        if (pProblemItem->getType() == StringHandler::WARNING)
            pProblemItem->setHidden(false);
        else
            pProblemItem->setHidden(true);
        ++it;
    }
}

//! Filter the Problems tree and only show the error type problems.
//! Slot activated when mpShowErrorsToolButton clicked signal is raised.
void MessageWidget::showErrors()
{
    QTreeWidgetItemIterator it(mpProblem);
    while (*it)
    {
        ProblemItem *pProblemItem = dynamic_cast<ProblemItem*>(*it);
        if (pProblemItem->getType() == StringHandler::OMERROR)
            pProblemItem->setHidden(false);
        else
            pProblemItem->setHidden(true);
        ++it;
    }
}

//! Shows all type of problems.
//! Slot activated when mpShowAllProblemsToolButton clicked signal is raised.
void MessageWidget::showAllProblems()
{
    QTreeWidgetItemIterator it(mpProblem);
    while (*it)
    {
        ProblemItem *pProblemItem = dynamic_cast<ProblemItem*>(*it);
        pProblemItem->setHidden(false);
        ++it;
    }
}

//! Starts blinking the tab text so that the user knows that some new message has been added.
//! Slot activated when the timer for any tab is timed out.
void MessageWidget::startTitleBlink(QWidget *pWidget)
{
    for (int i = 0; i < count() ; i++)
    {
        if (widget(i) == pWidget)
        {
            if (tabBar()->tabTextColor(i) == Qt::transparent)
                tabBar()->setTabTextColor(i, Qt::black);
            else
                tabBar()->setTabTextColor(i, Qt::transparent);
        }
    }
}

//! Stop blinking the tab text.
//! When the user selects the blinking tab we should stop blinking.
//! Slot activated when the MessageWidget::currentChanged() signal is raised.
void MessageWidget::stopTitleBlink(int element)
{
    if (dynamic_cast<Problem*>(widget(element)))
    {
        mpProblemsTabTimer->stop();
    }
    else if (dynamic_cast<GeneralMessages*>(widget(element)))
    {
        mpGeneralTabTimer->stop();
    }
    else if (dynamic_cast<InfoMessages*>(widget(element)))
    {
        mpInfoTabTimer->stop();
    }
    tabBar()->setTabTextColor(element, Qt::black);
}

//! @class Messages
//! @brief It is the base class for all types of messages.

//! Constructor
//! @param pParent defines a parent to the new instanced object. pParent is the MessageWidget object.
Messages::Messages(MessageWidget *pParent)
    : QTextEdit(pParent), mMessageCounter(0)
{
    setReadOnly(true);
    setObjectName(tr("MessagesTextBox"));

    mpMessageWidget = pParent;
}

//! Displays the message.
//! @param message is the string that is displayed.
void Messages::printGUIMessage(QString message)
{
    append(message + tr("\n"));
    ensureCursorVisible();
    //mpMessageWidget->setCurrentWidget(this);
}

//! @class GeneralMessages
//! @brief This class is inherited from Messages. It is used to display general messages.

//! Constructor
//! @param pParent defines a parent to the new instanced object. pParent is the MessageWidget object.
GeneralMessages::GeneralMessages(MessageWidget *pParent)
    : Messages(pParent)
{
    setTextColor("BLACK");
}

//! Reimplementation of Messages::printGUIMessage function.
void GeneralMessages::printGUIMessage(QString message)
{
    append(message);
}

//! @class InfoMessages
//! @brief This class is inherited from Messages. It is used to display info messages.

//! Constructor
//! @param pParent defines a parent to the new instanced object. pParent is the MessageWidget object.
InfoMessages::InfoMessages(MessageWidget *pParent)
    : Messages(pParent)
{
    setTextColor("GREEN");
}

//! Reimplementation of Messages::printGUIMessage function.
void InfoMessages::printGUIMessage(QString message)
{
    mMessageCounter++;
    append(QString("---- Info ").append(QString::number(mMessageCounter)).append(" : ")
           .append(QTime::currentTime().toString()).append(" ----"));

    Messages::printGUIMessage(message);
}

//! @class Problem
//! @brief A tree based structure for OMC error messages. Creates three types of problems i.e notification ,warning, error.

//! Constructor
//! @param pParent defines a parent to the new instanced object. pParent is the MessageWidget object.
Problem::Problem(MessageWidget *pParent)
    : QTreeWidget(pParent), mpSelectedProblemItem(0)
{
    mpMessageWidget = pParent;
    // set tree settings
    setObjectName(tr("ProblemsTree"));
    setIndentation(0);
    setColumnCount(4);
    setIconSize(QSize(12, 12));
    setContentsMargins(0, 0, 0, 0);
    setFrameStyle(QFrame::NoFrame);
    QStringList labels;
    labels << "Kind" << "Time" << "Resource" << "Location" << "Message";
    setHeaderLabels(labels);
    setContextMenuPolicy(Qt::CustomContextMenu);
    // create actions
    mpCopyAction = new QAction(QIcon(":/Resources/icons/copy.png"), tr("Copy"), this);
    mpCopyAction->setStatusTip(tr("Copy the Problem"));
    connect(mpCopyAction, SIGNAL(triggered()), SLOT(copyProblem()));
    mpCopyAllAction = new QAction(tr("Copy All"), this);
    mpCopyAllAction->setStatusTip(tr("Copy All the Problems"));
    connect(mpCopyAllAction, SIGNAL(triggered()), SLOT(copyAllProblems()));
    mpRemoveAction = new QAction(QIcon(":/Resources/icons/delete.png"), tr("Remove"), this);
    mpRemoveAction->setStatusTip(tr("Remove the Problem"));
    connect(mpRemoveAction, SIGNAL(triggered()), SLOT(removeProblem()));
    // make Problems Tree connections
    connect(this, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(openEditor(QTreeWidgetItem*,int)));
    connect(this, SIGNAL(currentItemChanged(QTreeWidgetItem*,QTreeWidgetItem*)), SLOT(closeEditor(QTreeWidgetItem*,QTreeWidgetItem*)));
    connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
}

//! Opens the text box for the user so that he can selelect the specific text.
//! Slot activated when Problem::itemDoubleClicked() signal is raised.
void Problem::openEditor(QTreeWidgetItem *item, int column)
{
    openPersistentEditor(item, column);
}

//! Closes the open text box.
//! Slot activated when Problem::currentItemChanged() signal is raised.
void Problem::closeEditor(QTreeWidgetItem *current, QTreeWidgetItem *previous)
{
    Q_UNUSED(current);
    if (previous)
        for (int i = 0 ; i < columnCount() ; i++)
            closePersistentEditor(previous, i);
}

//! Shows a context menu when user right click on the Problems tree.
//! Slot activated when Problem::customContextMenuRequested() signal is raised.
void Problem::showContextMenu(QPoint point)
{
    int adjust = 24;
    QTreeWidgetItem *item = 0;
    item = itemAt(point);

    if (item)
    {
        mpSelectedProblemItem = dynamic_cast<ProblemItem*>(item);
        QMenu menu(this);
        menu.addAction(mpCopyAction);
        menu.addAction(mpCopyAllAction);
        menu.addSeparator();
        menu.addAction(mpRemoveAction);
        point.setY(point.y() + adjust);
        menu.exec(mapToGlobal(point));
    }
}

//! Copy the selected problem to the clipboard.
//! Slot activated when mpCopyAction triggered signal is raised.
void Problem::copyProblem()
{
    if (mpSelectedProblemItem)
    {
        QString textToCopy;
        textToCopy.append(mpSelectedProblemItem->text(0)).append("\t");
        textToCopy.append(mpSelectedProblemItem->text(1)).append("\t");
        textToCopy.append(mpSelectedProblemItem->text(2)).append("\t");
        textToCopy.append(mpSelectedProblemItem->text(3)).append("\t");
        textToCopy.append(mpSelectedProblemItem->text(4));
        QApplication::clipboard()->setText(textToCopy);
    }
}

//! Copy all the problems to the clipboard.
//! Slot activated when mpCopyAllAction triggered signal is raised.
void Problem::copyAllProblems()
{
    QString textToCopy;
    QTreeWidgetItemIterator it(this);
    while (*it)
    {
        ProblemItem *pProblemItem = dynamic_cast<ProblemItem*>(*it);
        textToCopy.append(pProblemItem->text(0)).append("\t");
        textToCopy.append(pProblemItem->text(1)).append("\t");
        textToCopy.append(pProblemItem->text(2)).append("\t");
        textToCopy.append(pProblemItem->text(3)).append("\t");
        textToCopy.append(pProblemItem->text(4)).append("\n");
        ++it;
    }
    QApplication::clipboard()->setText(textToCopy);
}

//! Removes the selected problem.
//! Slot activated when mpRemoveAction triggered signal is raised.
void Problem::removeProblem()
{
    qDeleteAll(mpSelectedProblemItem->takeChildren());
    delete mpSelectedProblemItem;
}

//! @class ProblemItem
//! @brief A tree node for Problems Tree.

//! Constructor
//! @param pParent defines a parent to the new instanced object. pParent is the Problem object.
ProblemItem::ProblemItem(Problem *pParent)
    : QTreeWidgetItem(pParent)
{
    mpParentProblem = pParent;
    initialize();
}

//! Constructor
//! @param filename the problem filename.
//! @param readOnly the problem file readOnly state.
//! @param lineStart the index where the problem starts.
//! @param columnStart the indexed column where the problem starts.
//! @param lineEnd the index where the problem ends.
//! @param columnEnd the indexed column where the problem ends.
//! @param message the problem message.
//! @param kind the problem kind.
//! @param level the problem level.
//! @param id the problem id.
//! @param pParent defines a parent to the new instanced object. pParent is the Problem object.
ProblemItem::ProblemItem(QString filename, bool readOnly, int lineStart, int columnStart, int lineEnd, int columnEnd, QString message,
                         QString kind, QString level, int id, Problem *pParent)
    : QTreeWidgetItem(pParent)
{
    mpParentProblem = pParent;
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

//! Initializes the Problem Item.
void ProblemItem::initialize()
{
    // create error types map
    mErrorsMap.insert(Helper::notificationLevel, StringHandler::NOTIFICATION);
    mErrorsMap.insert(Helper::warningLevel, StringHandler::WARNING);
    mErrorsMap.insert(Helper::errorLevel, StringHandler::OMERROR);
    // create error kind map
    mErrorKindsMap.insert(Helper::syntaxKind, StringHandler::SYNTAX);
    mErrorKindsMap.insert(Helper::grammarKind, StringHandler::GRAMMAR);
    mErrorKindsMap.insert(Helper::translationKind, StringHandler::TRANSLATION);
    mErrorKindsMap.insert(Helper::symbolicKind, StringHandler::SYMBOLIC);
    mErrorKindsMap.insert(Helper::simulationKind, StringHandler::SIMULATION);
    mErrorKindsMap.insert(Helper::scriptingKind, StringHandler::SCRIPTING);
}

//! Sets the problem filename.
//! @param fileName the problem file name.
void ProblemItem::setFileName(QString fileName)
{
    mFileName = fileName;
}

//! Returns the problem filename.
//! @param QString the problem file name.
QString ProblemItem::getFileName()
{
    return mFileName;
}

//! Sets the problem file readOnly state.
//! @param readOnly the problem file readOnly state.
void ProblemItem::setReadOnly(bool readOnly)
{
    mReadOnly = readOnly;
}

//! Returns the problem file readOnly state.
//! @return bool the problem file readOnly state.
bool ProblemItem::getReadOnly()
{
    return mReadOnly;
}

//! Sets the problem line start index.
//! @param lineStart the problem start index.
void ProblemItem::setLineStart(int lineStart)
{
    mLineStart = lineStart;
}

//! Returns the problem start index.
//! @return int the problem start index.
int ProblemItem::getLineStart()
{
    return mLineStart;
}

//! Sets the problem column start index.
//! @param columnStart the problem column start index.
void ProblemItem::setColumnStart(int columnStart)
{
    mColumnStart = columnStart;
}

//! Returns the problem column start index.
//! @return int the problem column start index.
int ProblemItem::getColumnStart()
{
    return mColumnStart;
}

//! Sets the problem line end index.
//! @param lineEnd the problem end index.
void ProblemItem::setLineEnd(int lineEnd)
{
   mLineEnd = lineEnd;
}

//! Returns the problem end index.
//! @return int the problem end index.
int ProblemItem::getLineEnd()
{
    return mLineEnd;
}

//! Sets the problem column end index.
//! @param columnEnd the problem column end index.
void ProblemItem::setColumnEnd(int columnEnd)
{
    mColumnEnd = columnEnd;
}

//! Returns the problem column end index.
//! @return int the problem column end index.
int ProblemItem::getColumnEnd()
{
    return mColumnEnd;
}

//! Sets the problem message.
//! @param message the problem message to set.
void ProblemItem::setMessage(QString message)
{
    mMessage = message;
}

//! Returns the problem message.
//! @return QString the problem message.
QString ProblemItem::getMessage()
{
    return mMessage;
}

//! Sets the problem kind.
//! @param kind the problem kind to set.
void ProblemItem::setKind(QString kind)
{
    mKind = kind;
    // set the error kinf
    QMap<QString, StringHandler::ModelicaErrorKinds>::iterator it;
    for (it = mErrorKindsMap.begin(); it != mErrorKindsMap.end(); ++it)
    {
        if (it.key().compare(kind) == 0)
        {
            mErrorKind = it.value();
            return;
        }
    }
    mErrorKind = StringHandler::NOOMERRORKIND;
}

//! Returns the problem kind.
//! @return QString the problem kind.
QString ProblemItem::getKind()
{
    return mKind;
}

//! Sets the problem level.
//! @param level the problem level to set.
void ProblemItem::setLevel(QString level)
{
    mLevel = level;
    // set the error type
    QMap<QString, StringHandler::ModelicaErrors>::iterator it;
    for (it = mErrorsMap.begin(); it != mErrorsMap.end(); ++it)
    {
        if (it.key().compare(level) == 0)
        {
            mType = it.value();
            return;
        }
    }
    mType = StringHandler::NOOMERROR;
}

//! Returns the problem level.
//! @return QString the problem level.
QString ProblemItem::getLevel()
{
    return mLevel;
}

//! Sets the problem id.
//! @param id the problem id to set.
void ProblemItem::setId(int id)
{
    mId = id;
}

//! Returns the problem id.
//! @return int the problem id.
int ProblemItem::getId()
{
    return mId;
}

//! Returns the problem type.
//! @return int the problem type.
int ProblemItem::getType()
{
    return mType;
}

//! Returns the problem error kind.
//! @return int the problem error kind.
int ProblemItem::getErrorKind()
{
    return mErrorKind;
}

//! Sets the problem complete text by reading all its attributes.
//! Always call this method when Problem attributes are set.
void ProblemItem::setColumnsText()
{
    switch (getType())
    {
        case StringHandler::NOTIFICATION:
        {
            setIcon(0, QIcon(":/Resources/icons/notificationicon.png"));
            break;
        }
        case StringHandler::WARNING:
        {
            setIcon(0, QIcon(":/Resources/icons/warningicon.png"));
            break;
        }
        case StringHandler::OMERROR:
        {
            setIcon(0, QIcon(":/Resources/icons/erroricon.png"));
            break;
        }
    }
    setText(0, StringHandler::getErrorKind(getErrorKind()));
    setText(1, QTime::currentTime().toString());
    setText(2, getFileName());
    QString line = "line " + QString::number(getLineStart()) + ":" + QString::number(getColumnStart()) + "-" + QString::number(getLineEnd())
                   + ":" + QString::number(getColumnEnd());
    setText(3, line);
    setText(4, getMessage());
}

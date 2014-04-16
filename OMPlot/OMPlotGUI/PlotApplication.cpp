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
 * Main Author 2011: Adeel Asghar
 *
 */

#include "PlotApplication.h"
#include "PlotWindow.h"
#include <QTimer>

using namespace OMPlot;

PlotApplication::PlotApplication(int &argc, char *argv[], const QString uniqueKey)
    : QApplication(argc, argv)
{
    mSharedMemory.setKey(uniqueKey);

    if (mSharedMemory.attach())
        mIsRunning = true;
    else
    {
        mIsRunning = false;
        // attach data to shared memory.
        QByteArray byteArray("0"); // default value to note that no message is available.
        if (!mSharedMemory.create(4096))
        {
            printf("Unable to create shared memory for OMPlot.");
            return;
        }
        mSharedMemory.lock();
        char *to = (char*)mSharedMemory.data();
        const char *from = byteArray.data();
        memcpy(to, from, qMin(mSharedMemory.size(), byteArray.size()));
        mSharedMemory.unlock();
        // start checking for messages of other instances.
        mpTimer = new QTimer(this);
        connect(mpTimer, SIGNAL(timeout()), SLOT(checkForMessage()));
        mpTimer->start(100);        // after every 0.1 second we check the shared memory
    }
}

bool PlotApplication::isRunning()
{
    return mIsRunning;
}

void PlotApplication::sendMessage(QStringList arguments)
{
    QByteArray byteArray("1");
    byteArray.append(arguments.join(";").toUtf8());
    byteArray.append('\0'); // < should be as char here, not a string!
    mSharedMemory.lock();
    char *to = (char*)mSharedMemory.data();
    const char *from = byteArray.data();
    memcpy(to, from, qMin(mSharedMemory.size(), byteArray.size()));
    mSharedMemory.unlock();
}

void PlotApplication::launchNewApplication(QStringList arguments)
{
    QByteArray byteArray("2");
    byteArray.append(arguments.join(";").toUtf8());
    byteArray.append('\0'); // < should be as char here, not a string!
    mSharedMemory.lock();
    char *to = (char*)mSharedMemory.data();
    const char *from = byteArray.data();
    memcpy(to, from, qMin(mSharedMemory.size(), byteArray.size()));
    mSharedMemory.unlock();
}

bool PlotApplication::notify(QObject *receiver, QEvent *event)
{
    try
    {
        return QApplication::notify(receiver, event);
    }
    catch (PlotException &e)
    {
        QMessageBox *msgBox = new QMessageBox();
        msgBox->setWindowTitle(QString(tr("OMPlot - Error")));
        msgBox->setIcon(QMessageBox::Warning);
        msgBox->setText(QString(e.what()));
        msgBox->setStandardButtons(QMessageBox::Ok);
        msgBox->setDefaultButton(QMessageBox::Ok);
        msgBox->exec();
        return true;
    }
}

void PlotApplication::checkForMessage()
{
    mSharedMemory.lock();
    QByteArray byteArray = QByteArray((char*)mSharedMemory.constData(), mSharedMemory.size());
    mSharedMemory.unlock();
    if (byteArray.left(1) == "0")
        return;
    char type = byteArray.at(0);
    byteArray.remove(0, 1);        // remove the one we put at the start of the bytearray while writing to memory
    QStringList arguments = QString::fromUtf8(byteArray.constData()).split(";");
    // remove message from shared memory.
    byteArray = "0";
    mSharedMemory.lock();
    char *to = (char*)mSharedMemory.data();
    const char *from = byteArray.data();
    memcpy(to, from, qMin(mSharedMemory.size(), byteArray.size()));
    mSharedMemory.unlock();
    // if type is 1 send message to current tab
    // if type is 2 launch a new tab
    if (type == '2')
        emit newApplicationLaunched(arguments);
    else
        emit messageAvailable(arguments);
}

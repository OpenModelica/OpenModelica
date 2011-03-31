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
#include <QTimer>

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
        if (!mSharedMemory.create(byteArray.size()))
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
        startTimer();               // connect the timer to checkForMessage slot
        mpTimer->start(100);        // after every 0.1 second we check the shared memory
    }

    connect(this, SIGNAL(newApplicationLaunched()), SLOT(stopTimer()));
}

bool PlotApplication::isRunning()
{
    return mIsRunning;
}

bool PlotApplication::sendMessage(QStringList arguments)
{
    if (!mIsRunning)
        return false;
    QByteArray byteArray("1");
    byteArray.append(arguments.join(";").toUtf8());
    byteArray.append('\0'); // < should be as char here, not a string!
    mSharedMemory.lock();
    char *to = (char*)mSharedMemory.data();
    const char *from = byteArray.data();
    memcpy(to, from, qMin(mSharedMemory.size(), byteArray.size()));
    mSharedMemory.unlock();
    return true;
}

void PlotApplication::launchNewApplication()
{
    QByteArray byteArray("1");
    byteArray.append(tr("newomplotwindow").toUtf8());
    byteArray.append('\0'); // < should be as char here, not a string!
    mSharedMemory.lock();
    char *to = (char*)mSharedMemory.data();
    const char *from = byteArray.data();
    memcpy(to, from, qMin(mSharedMemory.size(), byteArray.size()));
    mSharedMemory.unlock();
    // new create timer for new app
    mpTimer = new QTimer(this);
    startTimer();               // connect the timer to checkForMessage slot
    mpTimer->start(100);        // after every 0.1 second we check the shared memory
}

void PlotApplication::checkForMessage()
{
    qDebug() << "looking for message";
    mSharedMemory.lock();
    QByteArray byteArray = QByteArray((char*)mSharedMemory.constData(), mSharedMemory.size());
    mSharedMemory.unlock();
    if (byteArray.left(1) == "0")
        return;
    byteArray.remove(0, 1);        // remove the one we put at the start of the bytearray while writing to memory
    // check if new application is launched or not
    if (QString::fromUtf8(byteArray.constData()).compare("newomplotwindow") == 0)
    {
        emit newApplicationLaunched();
    }
    else
    {
        QStringList arguments = QString::fromUtf8(byteArray.constData()).split(";");
        emit messageAvailable(arguments);
    }
    // remove message from shared memory.
    byteArray = "0";
    mSharedMemory.lock();
    char *to = (char*)mSharedMemory.data();
    const char *from = byteArray.data();
    memcpy(to, from, qMin(mSharedMemory.size(), byteArray.size()));
    mSharedMemory.unlock();
}

void PlotApplication::startTimer()
{
    connect(mpTimer, SIGNAL(timeout()), SLOT(checkForMessage()));
}

void PlotApplication::stopTimer()
{
    mpTimer->stop();
    qDebug() << "stopping timer";
}



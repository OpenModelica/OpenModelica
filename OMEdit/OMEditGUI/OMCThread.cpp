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

//! @file   OMCThread.cpp
//! @author Sonia Tariq <sonta273@student.liu.se>
//! @date   2010-07-09

//! @brief Used to send the command to Open Modelica Compiler in a thread.

#include "OMCThread.h"

//! @class OMCThread
//! @brief The OMCThread creats a thread for each request that is send to OMC.

//! Constructor
//! @param expression is the command that is needed to be send to OMC.
//! @param parent.
OMCThread::OMCThread(QString expression, OMCProxy *omcProxy, QObject *parent)
    : QThread(parent)
{
    this->mpOMCProxy = omcProxy;
    this->mExpression = expression;
    connect(this, SIGNAL(exceptionOccurred()), mpOMCProxy, SLOT(catchException()));
}

//! Destructor
OMCThread::~OMCThread()
{

}

void OMCThread::sleep(unsigned long secs)
{
    QThread::sleep(secs);
}

void OMCThread::run()
{
    try
    {
        mResult = this->mpOMCProxy->evalCommand(this->mExpression);
    }
    catch(CORBA::Exception& ex)
    {
        emit exceptionOccurred();
        this->exit();
    }
}

QString OMCThread::getResult()
{
    return mResult;
}

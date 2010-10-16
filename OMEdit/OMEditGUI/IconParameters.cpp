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

#include "IconParameters.h"

IconParameters::IconParameters(QString name, QString defaultValue)
{
    mName = name;
    mDefaultValue = defaultValue;
    mValue = defaultValue;
}

QString IconParameters::getName()
{
    return mName.trimmed();
}

QString IconParameters::getDefaultValue()
{
    return mDefaultValue.trimmed();
}

QString IconParameters::getValue()
{
    return mValue.trimmed();
}

QString IconParameters::getComment()
{
    return mComment.trimmed();
}

void IconParameters::setName(QString name)
{
    mName = name;
}

void IconParameters::setDefaultValue(QString defaultValue)
{
    mDefaultValue = defaultValue;
}

void IconParameters::setValue(QString value)
{
    mValue = value;
}

void IconParameters::setComment(QString comment)
{
    mComment = comment;
}

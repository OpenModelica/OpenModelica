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

#include "ComponentsProperties.h"
#include "StringHandler.h"

ComponentsProperties::ComponentsProperties(QString value)
{
    this->mClassName = "";
    this->mName = "";
    this->mComment = "";
    this->mIsProtected = false;
    this->mIsFinal = false;
    this->mIsFlow = false;
    this->mIsStream = false;
    this->mIsReplaceable = false;

    this->mVariabilityMap.insert("constant", "Constant");
    this->mVariabilityMap.insert("discrete", "discrete");
    this->mVariabilityMap.insert("parameter", "parameter");
    this->mVariabilityMap.insert("unspecified", "Default");

    this->mIsInner = false;
    this->mIsOuter = false;

    this->mCasualityMap.insert("input", "Input");
    this->mCasualityMap.insert("output", "Output");
    this->mCasualityMap.insert("unspecified", "None");

    parseString(value);
}

void ComponentsProperties::parseString(QString value)
{
    if (value.isEmpty())
        return;

    int index = 0;
    QStringList list = StringHandler::getStrings(value);

    if (list.size() > 0)
        this->mClassName = list.at(0);
    else
        return;

    if (list.size() > 1)
        this->mName = list.at(1);
    else
        return;

    if (list.size() > 2)
        this->mComment = list.at(2);
    else
        return;

    if (list.size() > 3)
        this->mIsProtected = StringHandler::removeFirstLastQuotes(list.at(3)).compare("protected");
    else
        return;

    if (list.size() > 4)
        this->mIsFinal = static_cast<QString>(list.at(4)).contains("true");
    else
        return;

    if (list.size() > 5)
        this->mIsFlow = static_cast<QString>(list.at(5)).contains("true");
    else
        return;

    if (list.size() > 10)
    {
        this->mIsStream = static_cast<QString>(list.at(6)).contains("true");
        index = 1;
    }

    if (list.size() > 6 + index)
        this->mIsReplaceable = static_cast<QString>(list.at(6 + index)).contains("true");
    else
        return;

    if (list.size() > 7 + index)
    {
        QMap<QString, QString>::iterator variability_it;
        for (variability_it = this->mVariabilityMap.begin(); variability_it != this->mVariabilityMap.end(); ++variability_it)
        {
            if (variability_it.key() == StringHandler::removeFirstLastQuotes(list.at(7 + index)));
            {
                this->mVariability = variability_it.value();
                break;
            }
        }
    }

    if (list.size() > 8 + index)
        this->mIsInner = static_cast<QString>(list.at(8 + index)).contains("inner");
    else
        return;

    if (list.size() > 8 + index)
        this->mIsOuter = static_cast<QString>(list.at(8 + index)).contains("outer");
    else
        return;

    if (list.size() > 9 + index)
    {
        QMap<QString, QString>::iterator casuality_it;
        for (casuality_it = this->mCasualityMap.begin(); casuality_it != this->mCasualityMap.end(); ++casuality_it)
        {
            if (casuality_it.key() == StringHandler::removeFirstLastQuotes(list.at(9 + index)));
            {
                this->mCasuality = casuality_it.value();
                break;
            }
        }
    }
}

QString ComponentsProperties::getClassName()
{
    return mClassName;
}

QString ComponentsProperties::getName()
{
    return mName;
}

QString ComponentsProperties::getComment()
{
    return mComment;
}

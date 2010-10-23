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

//! @file   StringHandler.cpp
//! @author Syed Adeel Asghar <syeas460@student.liu.se>
//! @date   2010-07-12

//! @brief Contains functions used for parsing results obtained from Open Modelica Compiler.

#include "StringHandler.h"

//! @class StringHandler
//! @brief The StringHandler class is used to manipulating and parsing the results get from OMC.

//! Constructor
StringHandler::StringHandler()
{

}

//! Destructor
StringHandler::~StringHandler()
{

}

//! Removes the first and last curly brackest {} from the string.
//! @param value is the string which is parsed.
QString StringHandler::removeFirstLastCurlBrackets(QString value)
{
    value = value.trimmed();
    if (value.length() > 1 && value.at(0) == '{' && value.at(value.length() - 1) == '}')
    {
        value = value.mid(1, (value.length() - 2));
    }
    return value;
}

//! Removes the first and last brackest () from the string.
//! @param value is the string which is parsed.
QString StringHandler::removeFirstLastBrackets(QString value)
{
    value = value.trimmed();
    if (value.length() > 1 && value.at(0) == '(' && value.at(value.length() - 1) == ')')
    {
        value = value.mid(1, (value.length() - 2));
    }
    return value;
}

//! Removes the first and last quotes "" from the string.
//! @param value is the string which is parsed.
QString StringHandler::removeFirstLastQuotes(QString value)
{
    value = value.trimmed();
    if (value.length() > 1 && value.at(0) == '\"' && value.at(value.length() - 1) == '\"')
    {
        value = value.mid(1, (value.length() - 2));
    }
    return value;
}

//! Returns the last word from a string.
//! @param value is the string which is parsed.
QString StringHandler::getSubStringFromDots(QString value)
{
    if (value.isEmpty())
    {
        return "";
    }
    value = value.trimmed();
    QStringList list = value.split(".", QString::SkipEmptyParts);
    return list.at(list.count() - 1);
}

//! Removes the last dot from the string.
//! @param value is the string which is parsed.
QString StringHandler::removeLastDot(QString value)
{
    if (value.isEmpty())
    {
        return "";
    }
    value = value.trimmed();
    return value.remove((value.length() - 1), 1);
}

QStringList StringHandler::getStrings(QString value)
{
    return getStrings(value, '{', '}');
}

QStringList StringHandler::getStrings(QString value, char start, char end)
{
    QStringList list;
    QStringList tokenizer = value.split(",", QString::SkipEmptyParts);

    QString t = "";
    int ele = 0;
    foreach (QString temp, tokenizer)
    {
        if (ele == 0)
        {
            if (t.length() > 0)
            {
                list.append(t.trimmed());
            }
            t = temp;
        }
        else
        {
            t = t.trimmed() + ", " + temp.trimmed();
        }

        for (int i = 0 ; i < temp.length() ; i++)
        {
            if (temp.at(i) == start)
            {
                ele++;
            }
            else if (temp.at(i) == end)
            {
                ele--;
            }
        }
    }
    if (t.length() > 0)
        list.append(t.trimmed());

    return list;
}

QString StringHandler::getLastWordAfterDot(QString value)
{
    if (value.isEmpty())
    {
        return "";
    }

    int pos = value.lastIndexOf('.');
    if (pos >= 0)
    {
        return value.mid((pos + 1), (value.length() - 1));
    }
    else
    {
        return value;
    }
}

QString StringHandler::removeLastSlashWord(QString value)
{
    if (value.isEmpty())
    {
        return "";
    }
    value = value.trimmed();

    int pos = value.lastIndexOf('/');
    if (pos >= 0)
    {
        return value.mid(0, (pos));
    }
    else
    {
        return value;
    }
}

QString StringHandler::removeLastDotWord(QString value)
{
    if (value.isEmpty())
    {
        return "";
    }
    value = value.trimmed();

    int pos = value.lastIndexOf('.');
    if (pos >= 0)
    {
        return value.mid(0, (pos));
    }
    else
    {
        return value;
    }
}

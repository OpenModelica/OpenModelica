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

#ifndef STRINGHANDLER_H
#define STRINGHANDLER_H

#include <QtCore>
#include <QtGui>

class StringHandler
{
public:
    StringHandler();
    ~StringHandler();
    enum ModelicaClasses {MODEL, PACKAGE, PRIMITIVE, CONNECTOR, RECORD, BLOCK, TYPE, FUNCTION, CLASS, PARAMETER,
                          CONSTANT, PROTECTED};
    static QString removeFirstLastCurlBrackets(QString value);
    static QString removeFirstLastBrackets(QString value);
    static QString removeFirstLastQuotes(QString value);
    static QString getSubStringFromDots(QString value);
    static QString removeLastDot(QString value);
    static QStringList getStrings(QString value);
    static QStringList getStrings(QString value, char start, char end);
    static QString getLastWordAfterDot(QString value);
    static QString removeLastSlashWord(QString value);
    static QString removeLastDotWord(QString value);
};

#endif // STRINGHANDLER_H

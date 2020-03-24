/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef COMMANDFACTORY_H
#define COMMANDFACTORY_H

#include <QString>

class CommandFactory
{
public:
  enum metaType {
    record_metaType = 0,
    list_metaType,
    option_metaType,
    tuple_metaType,
    array_metaType
  };
  CommandFactory() {}
  /* Setup Commands */
  static QByteArray GDBSet(QString command);
  static QByteArray attach(QString processID);
  static QByteArray changeStdStreamBuffer();
  /* Breakpoint Commands */
  static QByteArray breakInsert(QString fileName, int line, bool isDisabled = false, QString condition = "", int ignoreCount = 0,
                                bool isPending = true);
  static QByteArray breakDelete(QStringList breakpointIDs);
  static QByteArray breakEnable(QStringList breakpointIDs);
  static QByteArray breakDisable(QStringList breakpointIDs);
  static QByteArray breakAfter(QString breakpointID, int count);
  static QByteArray breakCondition(QString breakpointID, QString condition);
  /* Program Context Commands */
  static QByteArray execRun();
  static QByteArray execContinue();
  static QByteArray execNext();
  static QByteArray execStep();
  static QByteArray execFinish();
  /* Thread Commands */
  static QByteArray threadInfo();
  /* Stack Manipulation Commands */
  static QByteArray stackListFrames(int thread);
  static QByteArray stackListVariables(int thread, int frame, QString printValues);
  static QByteArray createFullBacktrace();
  /* Data Manipulation Commands */
  static QByteArray dataEvaluateExpression(int thread, int frame, QString expression);
  static QByteArray getTypeOfAny(int thread, int frame, QString expression, bool inRecord);
  static QByteArray anyString(int thread, int frame, QString expression);
  static QByteArray getMetaTypeElement(int thread, int frame, QString expression, int index, metaType mt);
  static QByteArray arrayLength(int thread, int frame, QString expression);
  static QByteArray listLength(int thread, int frame, QString expression);
  static QByteArray isOptionNone(int thread, int frame, QString expression);
  static QByteArray GDBExit();
};

#endif // COMMANDFACTORY_H

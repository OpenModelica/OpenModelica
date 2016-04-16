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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 *
 */

#include <QStringList>
#include "CommandFactory.h"

/*!
 * \brief CommandFactory::GDBSet
 * \param command
 * \return
 */
QByteArray CommandFactory::GDBSet(QString command)
{
  return QByteArray("-gdb-set ").append(command);
}

/*!
  Attach the process to GDB.
  \param processID - the process ID to attach.
  \return the command.
  */
QByteArray CommandFactory::attach(QString processID)
{
  return QByteArray("attach ").append(processID);
}

/*!
  Changes the stdout & stderr stream buffer.\n
  Sets them to NULL so that executable can flush the output as they receive it.
  \return the command.
  */
QByteArray CommandFactory::changeStdStreamBuffer()
{
  return QByteArray("-data-evaluate-expression changeStdStreamBuffer()");
}

/*!
  Creates the -break-insert command.\n
  \param fileName - the breakpoint location.
  \param line - the breakpoint line number.
  \param isPending - sets the breakpoint pending.
  \return the command.
  */
QByteArray CommandFactory::breakInsert(QString fileName, int line, bool isDisabled, QString condition, int ignoreCount, bool isPending)
{
  QStringList command;
  command.append("-break-insert");
  if (isPending) {
    command.append("-f");
  }
  if (isDisabled) {
    command.append("-d");
  }
  if (!condition.isEmpty()) {
    command.append("-c");
    command.append("\"\\\"" + condition + "\\\"\"");
  }
  if (ignoreCount > 0) {
    command.append("-i");
    command.append(QString::number(ignoreCount));
  }
  command.append("\"\\\"" + fileName + "\\\":" + QString::number(line) + "\"");
  return QByteArray(command.join(" ").toStdString().c_str());
}

/*!
  Creates the -break-delete command.\n
  \param breakpointIDs - the breakpoint ids to delete.
  \return the command.
  */
QByteArray CommandFactory::breakDelete(QStringList breakpointIDs)
{
  return QByteArray("-break-delete ").append(breakpointIDs.join(" "));
}

/*!
  Creates the -break-enable command.\n
  \param breakpointIDs - the breakpoint ids to enable.
  \return the command.
  */
QByteArray CommandFactory::breakEnable(QStringList breakpointIDs)
{
  return QByteArray("-break-enable ").append(breakpointIDs.join(" "));
}

/*!
  Creates the -break-disable command.\n
  \param breakpointIDs - the breakpoint ids to disable.
  \return the command.
  */
QByteArray CommandFactory::breakDisable(QStringList breakpointIDs)
{
  return QByteArray("-break-disable ").append(breakpointIDs.join(" "));
}

/*!
  Creates the -break-after command.\n
  \param breakpointID - the breakpoint id.
  \param count - the ignore count.
  \return the command.
  */
QByteArray CommandFactory::breakAfter(QString breakpointID, int count)
{
  return QByteArray("-break-after ").append(breakpointID).append(" ").append(QString::number(count));
}

/*!
  Creates the -break-condition command.\n
  \param breakpointID - the breakpoint id.
  \param condition - the conditional expression.
  \return the command.
  */
QByteArray CommandFactory::breakCondition(QString breakpointID, QString condition)
{
  return QByteArray("-break-condition ").append(breakpointID).append(" ").append("\"\\\"" + condition + "\\\"\"");
}

/*!
  Creates the -exec-run command.\n
  \return the command.
  */
QByteArray CommandFactory::execRun()
{
  return "-exec-run";
}

/*!
  Creates the -exec-continue command.\n
  \return the command.
  */
QByteArray CommandFactory::execContinue()
{
  return "-exec-continue";
}

/*!
  Creates the -exec-next command.\n
  \return the command.
  */
QByteArray CommandFactory::execNext()
{
  return "-exec-next";
}

/*!
  Creates the -exec-step command.\n
  \return the command.
  */
QByteArray CommandFactory::execStep()
{
  return "-exec-step";
}

/*!
  Creates the -exec-finish command.\n
  \return the command.
  */
QByteArray CommandFactory::execFinish()
{
  return "-exec-finish";
}

/*!
  Creates the -thread-info command.\n
  \return the command.
  */
QByteArray CommandFactory::threadInfo()
{
  return "-thread-info";
}

/*!
  Creates the -thread-select command.\n
  \param num - the thread number to select.
  \return the command.
  */
QByteArray CommandFactory::threadSelect(int num)
{
  return QByteArray("-thread-select ").append(QString::number(num));
}

/*!
  Creates the -stack-list-frames command.\n
  \return the command.
  */
QByteArray CommandFactory::stackListFrames()
{
  return "-stack-list-frames";
}

/*!
  Creates the -stack-select-frame command.\n
  \param num - the frame number to select.
  \return the command.
  */
QByteArray CommandFactory::stackSelectFrame(int num)
{
  return QByteArray("-stack-select-frame ").append(QString::number(num));
}

/*!
  Creates the -stack-list-variables command.\n
  \param printValues - defines the format how the values are printed.\n
  If print-values is 0 or --no-values, print only the names of the variables; if it is 1 or --all-values, print also their values;
  and if it is 2 or --simple-values, print the name, type and value for simple data types, and the name and type for arrays,
  structures and unions
  \return the command.
  */
QByteArray CommandFactory::stackListVariables(QString printValues)
{
  return QByteArray("-stack-list-variables ").append(printValues);
}

/*!
  Creates the "thread apply all bt full" command.\n
  Generates a full backtrace of the program.
  \return the command.
  */
QByteArray CommandFactory::createFullBacktrace()
{
  return "thread apply all bt full";
}

/*!
  Creates the -data-evaluate-expression "expr" command.\n
  \param expression - the expression to be evaluated.
  \return the command.
  */
QByteArray CommandFactory::dataEvaluateExpression(QString expression)
{
  return QByteArray("-data-evaluate-expression \"").append(expression).append("\"");
}

/*!
  Creates the -data-evaluate-expression "(char*)getTypeOfAny(expr)" command.\n
  \param expression - the expression to be evaluated.
  \return the command.
  */
QByteArray CommandFactory::getTypeOfAny(QString expression)
{
  return QByteArray("-data-evaluate-expression \"(char*)getTypeOfAny(").append(expression).append(")\"");
}

/*!
  Creates the -data-evaluate-expression "(char*)anyString(expr)" command.\n
  \param expression - the expression to be evaluated.
  \return the command.
  */
QByteArray CommandFactory::anyString(QString expression)
{
  return QByteArray("-data-evaluate-expression \"(char*)anyString(").append(expression).append(")\"");
}

/*!
  Creates the -data-evaluate-expression "(char*)getRecordElement(expr, index)" command.\n
  \param expression - the expression to find.
  \return the command.
  */
QByteArray CommandFactory::getMetaTypeElement(QString expression, int index, metaType mt)
{
  QByteArray cmd = QByteArray("-data-evaluate-expression \"(char*)getMetaTypeElement(").append(expression)
      .append(", ").append(QString::number(index)).append(", ").append(QString::number(mt)).append(")\"");
  return cmd;
}

/*!
  Creates the -data-evaluate-expression "(int)arrayLength(expr)" command.\n
  \param expression - the expression to find the array length.
  \return the command.
  */
QByteArray CommandFactory::arrayLength(QString expression)
{
  return QByteArray("-data-evaluate-expression \"(int)mmc_gdb_arrayLength(").append(expression).append(")\"");
}

/*!
  Creates the -data-evaluate-expression "(int)listLength(expr)" command.\n
  \param expression - the expression to find the list length.
  \return the command.
  */
QByteArray CommandFactory::listLength(QString expression)
{
  return QByteArray("-data-evaluate-expression \"(int)listLength(").append(expression).append(")\"");
}

/*!
  Creates the -data-evaluate-expression "(int)isOptionNone(expr)" command.\n
  \param expression - the expression to check if option is none.
  \return the command.
  */
QByteArray CommandFactory::isOptionNone(QString expression)
{
  return QByteArray("-data-evaluate-expression \"(int)isOptionNone(").append(expression).append(")\"");
}

/*!
  Creates the -gdb-exit command.\n
  \return the command.
  */
QByteArray CommandFactory::GDBExit()
{
  return "-gdb-exit";
}

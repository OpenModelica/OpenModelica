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

#include <QStringList>
#include "Debugger/GDB/CommandFactory.h"

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
 * \brief CommandFactory::attach
 * Attach the process to GDB.
 * \param processID - the process ID to attach.
 * \return the command.
 */
QByteArray CommandFactory::attach(QString processID)
{
  return QByteArray("attach ").append(processID);
}

/*!
 * \brief CommandFactory::changeStdStreamBuffer
 * Changes the stdout & stderr stream buffer.\n
 * Sets them to NULL so that executable can flush the output as they receive it.
 * \return
 */
QByteArray CommandFactory::changeStdStreamBuffer()
{
  return QByteArray("-data-evaluate-expression changeStdStreamBuffer()");
}

/*!
 * \brief CommandFactory::breakInsert
 * Creates the -break-insert command.\n
 * \param fileName - the breakpoint location.
 * \param line - the breakpoint line number.
 * \param isDisabled
 * \param condition
 * \param ignoreCount
 * \param isPending - sets the breakpoint pending.
 * \return
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
 * \brief CommandFactory::breakDelete
 * Creates the -break-delete command.\n
 * \param breakpointIDs - the breakpoint ids to delete.
 * \return
 */
QByteArray CommandFactory::breakDelete(QStringList breakpointIDs)
{
  return QByteArray("-break-delete ").append(breakpointIDs.join(" "));
}

/*!
 * \brief CommandFactory::breakEnable
 * Creates the -break-enable command.\n
 * \param breakpointIDs - the breakpoint ids to enable.
 * \return
 */
QByteArray CommandFactory::breakEnable(QStringList breakpointIDs)
{
  return QByteArray("-break-enable ").append(breakpointIDs.join(" "));
}

/*!
 * \brief CommandFactory::breakDisable
 * Creates the -break-disable command.\n
 * \param breakpointIDs - the breakpoint ids to disable.
 * \return
 */
QByteArray CommandFactory::breakDisable(QStringList breakpointIDs)
{
  return QByteArray("-break-disable ").append(breakpointIDs.join(" "));
}

/*!
 * \brief CommandFactory::breakAfter
 * Creates the -break-after command.\n
 * \param breakpointID - the breakpoint id.
 * \param count - the ignore count.
 * \param breakpointID
 * \param count
 * \return
 */
QByteArray CommandFactory::breakAfter(QString breakpointID, int count)
{
  return QByteArray("-break-after ").append(breakpointID).append(" ").append(QString::number(count));
}

/*!
 * \brief CommandFactory::breakCondition
 * Creates the -break-condition command.\n
 * \param breakpointID - the breakpoint id.
 * \param condition - the conditional expression.
 * \param breakpointID
 * \param condition
 * \return
 */
QByteArray CommandFactory::breakCondition(QString breakpointID, QString condition)
{
  return QByteArray("-break-condition ").append(breakpointID).append(" ").append("\"\\\"" + condition + "\\\"\"");
}

/*!
 * \brief CommandFactory::execRun
 * Creates the -exec-run command.\n
 * \return
 */
QByteArray CommandFactory::execRun()
{
  return "-exec-run";
}

/*!
 * \brief CommandFactory::execContinue
 * Creates the -exec-continue command.\n
 * \return
 */
QByteArray CommandFactory::execContinue()
{
  return "-exec-continue";
}

/*!
 * \brief CommandFactory::execNext
 * Creates the -exec-next command.\n
 * \return
 */
QByteArray CommandFactory::execNext()
{
  return "-exec-next";
}

/*!
 * \brief CommandFactory::execStep
 * Creates the -exec-step command.\n
 * \return
 */
QByteArray CommandFactory::execStep()
{
  return "-exec-step";
}

/*!
 * \brief CommandFactory::execFinish
 * Creates the -exec-finish command.\n
 * \return
 */
QByteArray CommandFactory::execFinish()
{
  return "-exec-finish";
}

/*!
 * \brief CommandFactory::threadInfo
 * Creates the -thread-info command.\n
 * \return
 */
QByteArray CommandFactory::threadInfo()
{
  return "-thread-info";
}

/*!
 * \brief CommandFactory::stackListFrames
 * Creates the -stack-list-frames --thread 1 command.\n
 * \param thread
 * \return
 */
QByteArray CommandFactory::stackListFrames(int thread)
{
  QString command = QString("-stack-list-frames --thread %1").arg(thread);
  return QByteArray(command.toStdString().c_str());
}

/*!
 * \brief CommandFactory::stackListVariables
 * Creates the -stack-list-variables command.\n
 * \param thread
 * \param frame
 * \param printValues - defines the format how the values are printed.\n
 * If print-values is 0 or --no-values, print only the names of the variables; if it is 1 or --all-values, print also their values;
 * and if it is 2 or --simple-values, print the name, type and value for simple data types, and the name and type for arrays,
 * structures and unions
 * \return
 */
QByteArray CommandFactory::stackListVariables(int thread, int frame, QString printValues)
{
  QString command = QString("-stack-list-variables --thread %1 --frame %2 %3").arg(thread).arg(frame).arg(printValues);
  return QByteArray(command.toStdString().c_str());
}

/*!
 * \brief CommandFactory::createFullBacktrace
 * Creates the "thread apply all bt full" command.\n
 * Generates a full backtrace of the program.
 * \return
 */
QByteArray CommandFactory::createFullBacktrace()
{
  return "thread apply all bt full";
}

/*!
 * \brief CommandFactory::dataEvaluateExpression
 * Creates the -data-evaluate-expression --thread 1 --frame 0 "expression" command.\n
 * \param expression - the expression to be evaluated.
 * \param thread
 * \param frame
 * \param expression
 * \return the command.
 */
QByteArray CommandFactory::dataEvaluateExpression(int thread, int frame, QString expression)
{
  QString command = QString("-data-evaluate-expression --thread %1 --frame %2 \"%3\"").arg(thread).arg(frame).arg(expression);
  return QByteArray(command.toStdString().c_str());
}

/*!
 * \brief CommandFactory::getTypeOfAny
 * * Creates the -data-evaluate-expression --thread 1 --frame 0 "(char*)getTypeOfAny(expression, inRecord)" command.\n
 * \param expression - the expression to be evaluated.
 * \param thread
 * \param frame
 * \param expression
 * \param inRecord
 * \return the command.
 */
QByteArray CommandFactory::getTypeOfAny(int thread, int frame, QString expression, bool inRecord)
{
  QString command = QString("-data-evaluate-expression --thread %1 --frame %2 \"(char*)getTypeOfAny(%3, %4)\"").arg(thread).arg(frame)
      .arg(expression).arg(inRecord ? "1" : "0");
  return QByteArray(command.toStdString().c_str());
}

/*!

  \return the command.
  */
/*!
 * \brief CommandFactory::anyString
 * Creates the -data-evaluate-expression --thread 1 --frame 0 "(char*)anyString(expr)" command.\n
 * \param expression - the expression to be evaluated.
 * \param thread
 * \param frame
 * \param expression
 * \return
 */
QByteArray CommandFactory::anyString(int thread, int frame, QString expression)
{
  QString command = QString("-data-evaluate-expression --thread %1 --frame %2 \"(char*)anyString(%3)\"").arg(thread).arg(frame)
      .arg(expression);
  return QByteArray(command.toStdString().c_str());
}

/*!

  \return the command.
  */
/*!
 * \brief CommandFactory::getMetaTypeElement
 * Creates the -data-evaluate-expression --thread 1 --frame 0 "(char*)getMetaTypeElement(expr, index)" command.\n
 * \param expression - the expression to find.
 * \param frame
 * \param expression
 * \param index
 * \param mt
 * \return
 */
QByteArray CommandFactory::getMetaTypeElement(int thread, int frame, QString expression, int index, metaType mt)
{
  QString command = QString("-data-evaluate-expression --thread %1 --frame %2 \"(char*)getMetaTypeElement(%3, %4, %5)\"").arg(thread)
      .arg(frame).arg(expression).arg(index).arg(mt);
  return QByteArray(command.toStdString().c_str());
}

/*!

  \return the command.
  */
/*!
 * \brief CommandFactory::arrayLength
 * Creates the -data-evaluate-expression --thread 1 --frame 0 "(int)mmc_gdb_arrayLength(expr)" command.\n
 * \param expression - the expression to find the array length.
 * \param thread
 * \param frame
 * \param expression
 * \return
 */
QByteArray CommandFactory::arrayLength(int thread, int frame, QString expression)
{
  QString command = QString("-data-evaluate-expression --thread %1 --frame %2 \"(int)mmc_gdb_arrayLength(%3)\"").arg(thread).arg(frame)
      .arg(expression);
  return QByteArray(command.toStdString().c_str());
}

/*!
 * \brief CommandFactory::listLength
 * Creates the -data-evaluate-expression --thread 1 --frame 0 "(int)listLength(expr)" command.\n
 * \param thread
 * \param frame
 * \param expression - the expression to find the list length.
 * \return
 */
QByteArray CommandFactory::listLength(int thread, int frame, QString expression)
{
  QString command = QString("-data-evaluate-expression --thread %1 --frame %2 \"(int)listLength(%3)\"").arg(thread).arg(frame).arg(expression);
  return QByteArray(command.toStdString().c_str());
}

/*!
 * \brief CommandFactory::isOptionNone
 * Creates the -data-evaluate-expression --thread 1 --frame 0 "(int)isOptionNone(expr)" command.\n
 * \param expression - the expression to check if option is none.
 * \param thread
 * \param frame
 * \param expression
 * \return
 */
QByteArray CommandFactory::isOptionNone(int thread, int frame, QString expression)
{
  QString command = QString("-data-evaluate-expression --thread %1 --frame %2 \"(int)isOptionNone(%3)\"").arg(thread).arg(frame)
      .arg(expression);
  return QByteArray(command.toStdString().c_str());
}

/*!
 * \brief CommandFactory::GDBExit
 * Creates the -gdb-exit command.\n
 * \return
 */
QByteArray CommandFactory::GDBExit()
{
  return "-gdb-exit";
}

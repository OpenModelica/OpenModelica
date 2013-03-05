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

/*
 * RCS: $Id$
 */

//! @file   StringHandler.cpp
//! @author Syed Adeel Asghar <syeas460@student.liu.se>
//! @date   2010-07-12

//! @brief Contains functions used for parsing results obtained from OpenModelica Compiler.

#include "StringHandler.h"
#include "Helper.h"

QString StringHandler::mLastOpenDir;

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

QString StringHandler::getModelicaClassType(int type)
{
  switch (type)
  {
    case StringHandler::MODEL:
      return "Model";
    case StringHandler::CLASS:
      return "Class";
    case StringHandler::CONNECTOR:
      return "Connector";
    case StringHandler::RECORD:
      return "Record";
    case StringHandler::BLOCK:
      return "Block";
    case StringHandler::FUNCTION:
      return "Function";
    case StringHandler::PACKAGE:
      return "Package";
    case StringHandler::TYPE:
      return "Type";
    case StringHandler::PRIMITIVE:
      return "Primitive";
    case StringHandler::PARAMETER:
      return "Parameter";
    case StringHandler::CONSTANT:
      return "Constant";
    case StringHandler::PROTECTED:
      return "Protected";
    default:
      // should never be reached
      return "";
  }
}

QString StringHandler::getViewType(int type)
{
  switch (type)
  {
    case StringHandler::ICON:
      return Helper::iconView;
    case StringHandler::DIAGRAM:
      return Helper::diagramView;
    case StringHandler::MODELICATEXT:
      return Helper::documentationView;
    default:
      // should never be reached
      return "";
  }
}

QString StringHandler::getErrorKind(int kind)
{
  switch (kind)
  {
    case StringHandler::SYNTAX:
      return "Syntax";
    case StringHandler::GRAMMAR:
      return "Grammar";
    case StringHandler::TRANSLATION:
      return "Translation";
    case StringHandler::SYMBOLIC:
      return "Symbolic";
    case StringHandler::SIMULATION:
      return "Simulation";
    case StringHandler::SCRIPTING:
      return "Scripting";
    default:
      // should never be reached
      return "";
  }
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
  bool mask = false;
  bool inString = false;
  char StringEnd;
  int begin = 0;
  int ele = 0;

  for (int i = 0 ; i < value.length() ; i++)
  {
    if (inString)
    {
      if (mask)
      {
        mask = false;
      }
      else
      {
        if (value.at(i) == '\\')
        {
          mask = true;
        }
        else if (value.at(i) == StringEnd)
        {
          inString = false;
        }
      }
    }
    else
    {
      if (value.at(i) == '"')
      {
          StringEnd = '"';
          inString = true;
      }
      else if (value.at(i) == '\'')
      {
          StringEnd = '\'';
          inString = true;
      }
      else if (value.at(i) == ',')
      {
        if (ele == 0)
        {
          list.append(value.mid(begin,i-begin).trimmed());
          begin = i+1;
        }
      }
      else if (value.at(i) == start)
      {
        ele++;
      }
      else if (value.at(i) == end)
      {
        ele--;
      }
    }
  }
  list.append(value.mid(begin,value.length()-begin).trimmed());

  return list;
}

static QString wordsBeforeAfterLastDot(QString value, bool lastWord)
{
  if (value.isEmpty())
  {
    return "";
  }
  value = value.trimmed();
  int pos;
  if (value.endsWith('\'')) {
    int i = value.size()-2;
    while (value[i] != '\'' && i>1 && value[i-1] != '\\') {
      i--;
    }
    pos = i-1 + (lastWord ? -1 : 0);
  } else {
    pos = value.lastIndexOf('.');
  }

  if (pos >= 0)
  {
    if (lastWord)
      return value.mid((pos + 1), (value.length() - 1));
    else
      return value.mid(0, (pos));
  }
  else
  {
    return value;
  }
}

QString StringHandler::getLastWordAfterDot(QString value)
{
  return wordsBeforeAfterLastDot(value,true);
}

QString StringHandler::removeLastWordAfterDot(QString value)
{
  return wordsBeforeAfterLastDot(value,false);
}

QString StringHandler::getFirstWordBeforeDot(QString value)
{
  if (value.isEmpty())
  {
    return "";
  }

  int pos = value.indexOf('.');
  if (pos >= 0)
  {
    return value.mid(0, (pos));
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

QString StringHandler::removeComment(QString value)
{
  if (value.isEmpty())
  {
    return "";
  }
  value = value.trimmed();

  int startPos = value.indexOf("/*");
  int endPos = value.indexOf("*/");
  // + 2 to remove */ from the string as well.
  return value.remove(startPos, (endPos - startPos) + 2);
}

QList<QString> StringHandler::getSimulationResultVars(QString value)
{
  QList<QString> list;
  QString str;
  bool startReading = false;

  for (int i=0; i < value.length(); i++)
  {
    if(startReading)
      str.append(value.at(i));

    if (value.at(i) == '"')
    {
      if (startReading)
      {
        if (value.at(i+1) == ',')
        {
          startReading = false;
          list.append(str.remove((str.length() - 1), 1));
          str.clear();
        }
        else if (value.at(i+1) == '}')
        {
          startReading = false;
          list.append(str.remove((str.length() - 1), 1));
          str.clear();
        }
      }
      else
        startReading = true;
    }
  }
  return list;
}

QString StringHandler::getModifierValue(QString value)
{
  int element = 0;
  for(int i = 0 ; i < value.length() ; i++)
  {
    if (value.at(i) == '(')
      element++;
    else if (value.at(i) == ')')
      element--;
    else if (value.at(i) == '=')
    {
      if (element == 0)
        return value.mid(i + 1);
    }
  }
  return "";
}

#define CONSUME_CHAR(value,res,i) \
  if (value.at(i) == '\\') { \
  i++; \
  switch (value[i].toAscii()) { \
  case '\'': res.append('\''); break; \
  case '"':  res.append('\"'); break; \
  case '?':  res.append('\?'); break; \
  case '\\': res.append('\\'); break; \
  case 'a':  res.append('\a'); break; \
  case 'b':  res.append('\b'); break; \
  case 'f':  res.append('\f'); break; \
  case 'n':  res.append('\n'); break; \
  case 'r':  res.append('\r'); break; \
  case 't':  res.append('\t'); break; \
  case 'v':  res.append('\v'); break; \
  } \
  } else { \
  res.append(value[i]); \
  }


QString StringHandler::unparse(QString value)
{
  QString res;
  value = value.trimmed();
  if (value.length() > 1 && value.at(0) == '\"' && value.at(value.length() - 1) == '\"') {
    value = value.mid(1, (value.length() - 2));
    for (int i=0; i < value.length(); i++) {
      CONSUME_CHAR(value,res,i);
    }
    return res;
  } else {
    return "";
  }
}

QStringList StringHandler::unparseStrings(QString value)
{
  QStringList lst;
  value = value.trimmed();
  if (value[0] != '{') return lst; // ERROR?
  int i=1;
  QString res;
  while (value[i] == '"') {
    i++;
    while (value.at(i) != '"') {
      CONSUME_CHAR(value,res,i);
      i++;
      /* if we have unexpected double quotes then, however omc should return \" */
      /* remove this block once fixed in omc */
      if (value[i] == '"' && value[i+1] != ',') {
        if (value[i+1] != '}') {
          CONSUME_CHAR(value,res,i);
          i++;
        }
      }
      /* remove this block once fixed in omc */
    }
    i++;
    if (value[i] == '}') {
      lst.append(res);
      return lst;
    }
    if (value[i] == ',') {
      lst.append(res);
      i++;
      res = "";
      while (value[i] == ' ')     // if we have space before next value e.g {"x", "y", "z"}
        i++;
      continue;
    }
    while (value[i] != '"' && value[i] != '\0') {
      i++;
      fprintf(stderr, "error? malformed string-list. skipping: %c\n", value[i].toAscii());
    }
  }
  return lst; // ERROR?
}

QStringList StringHandler::unparseArrays(QString value)
{
  QStringList lst;
  size_t qopen = 0;
  size_t qopenindex = 0;
  size_t braceopen = 0;
  size_t mainbraceopen = 0;
  size_t i = 0;
  value = StringHandler::removeFirstLastCurlBrackets(value);
  size_t length = value.size();
  int subbraceopen = 0;
  for (; i < length ; i++)
  {
    if (value.at(i) == ' ' || value.at(i) == ',') continue; // ignore any kind of space
    if (value.at(i) == '{' && qopen == 0 && braceopen == 0)
    {
      braceopen = 1;
      mainbraceopen = i;
      continue;
    }
    if (value.at(i) == '{')
    {
      subbraceopen = 1;
    }

    if (value.at(i) == '}' && braceopen == 1 && qopen == 0 && subbraceopen == 0)
    {
      //closing of a group
      int copylength = i- mainbraceopen+1;
      braceopen = 0;
      lst.append(value.mid(mainbraceopen, copylength));
      continue;
    }
    if (value.at(i) == '}')
      subbraceopen = 0;

    if (value.at(i) == '\"')
    {
      if (qopen == 0)
      {
        qopen = 1;
        qopenindex = i;
      }
      else
      {
        // its a closing quote
        qopen = 0;
      }
    }
  }
  return lst;
}

bool StringHandler::unparseBool(QString value)
{
  value = value.trimmed();
  return value == "true";
}

QString StringHandler::getSaveFileName(QWidget* parent, const QString &caption, QString * dir, const QString &filter, QString * selectedFilter,
                                       const QString &defaultSuffix, const QString *purposedName)
{
  QString dir_str;
  QString fileName;

  if (dir)
  {
    dir_str = *dir;
  }
  else
  {
    dir_str = mLastOpenDir.isEmpty() ? QDir::homePath() : mLastOpenDir;
  }

  if (purposedName)
    fileName = QFileDialog::getSaveFileName(parent, caption, QString(dir_str).append("/").append(*purposedName), filter, selectedFilter);
  else
    fileName = QFileDialog::getSaveFileName(parent, caption, dir_str, filter, selectedFilter);

  if (!fileName.isEmpty())
  {
    /* Qt is not reallllyyyy platform independent :(
     * In older versions of Qt QFileDialog::getSaveFileName doesn't return file extension on Linux.
     * But it works fine in Qt 4.8.
     */
    QFileInfo fileInfo(fileName);
#ifdef Q_OS_LINUX && QT_VERSION < 0x040800
    if (fileInfo.suffix() == QString(""))
      fileName.append(".").append(defaultSuffix);
#else
    Q_UNUSED(defaultSuffix);
#endif
    mLastOpenDir = fileInfo.absolutePath();
    return fileName;
  }
  return QString();
}

QString StringHandler::getOpenFileName(QWidget* parent, const QString &caption, QString * dir, const QString &filter, QString * selectedFilter)
{
  QString dir_str;

  if (dir)
  {
    dir_str = *dir;
  }
  else
  {
    dir_str = mLastOpenDir.isEmpty() ? QDir::homePath() : mLastOpenDir;
  }

  QString fileName = QFileDialog::getOpenFileName(parent, caption, dir_str, filter, selectedFilter);
  if (!fileName.isEmpty())
  {
    QFileInfo fileInfo(fileName);
    mLastOpenDir = fileInfo.absolutePath();
    return fileName;
  }
  return QString();
}

QString StringHandler::getExistingDirectory(QWidget *parent, const QString &caption, QString *dir)
{
  QString dir_str;

  if (dir)
  {
    dir_str = *dir;
  }
  else
  {
    dir_str = mLastOpenDir.isEmpty() ? QDir::homePath() : mLastOpenDir;
  }

  QString dirName = QFileDialog::getExistingDirectory(parent, caption, dir_str, QFileDialog::ShowDirsOnly);
  if (!dirName.isEmpty())
  {
    mLastOpenDir = dirName;
    return dirName;
  }
  return QString();
}

QString StringHandler::createTooltip(QStringList info, QString name, QString path)
{
  if (info.size() < 3)
    return path;
  else
  {
    QString tooltip = QString(Helper::type).append(": ").append(info[0]).append("\n")
        .append(Helper::name).append(" ").append(name).append("\n")
        .append(tr("Description")).append(": ").append(info[1]).append("\n");
    if (QString(info[2]).compare("<interactive>") == 0)
      tooltip.append(Helper::errorLocation).append(": ").append("\n");
    else
      tooltip.append(Helper::errorLocation).append(": ").append(info[2]).append("\n");
    tooltip.append(tr("Path")).append(": ").append(path);
    return tooltip;
  }
}

QString StringHandler::escape(QString str)
{
  return str.replace("\\", "\\\\").replace("\"", "\\\"");
}

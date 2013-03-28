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
 * RCS: $Id$
 *
 */

#include <QMdiArea>
#include <QThread>
#include <QLabel>
#include <QPlainTextEdit>
#include <QMessageBox>
#include <QCheckBox>

#ifndef UTIL_H
#define UTIL_H

class MainWindow;
class MdiArea : public QMdiArea
{
  Q_OBJECT
public:
  MdiArea(QWidget *pParent = 0);
  MainWindow* getMainWindow();
protected:
  MainWindow *mpMainWindow;
};

//! @brief Used to create platform independent sleep for the application.
class Sleep : public QThread
{
  Q_OBJECT
public:
  Sleep() {}
  ~Sleep() {}
  static void sleep(unsigned long secs) {QThread::sleep(secs);}
protected:
  void run() {}
};

class Label : public QLabel
{
public:
  Label(QWidget *parent = 0, Qt::WindowFlags f = 0) : QLabel(parent, f) {init();}
  Label(const QString &text, QWidget *parent = 0, Qt::WindowFlags f = 0) : QLabel(text, parent, f) {init();}
private:
  void init() {setTextInteractionFlags(Qt::TextSelectableByMouse);}
};

//! @struct RecentFile
/*! \brief It contains the recently opened file name and its encoding.
 * We must register this struct as a meta type since we need to use it as a QVariant.
 * This is used to store the recent files information in omedit.ini file.
 * The QDataStream also needed to be defined for this struct.
 */
struct RecentFile
{
  QString fileName;
  QString encoding;
  operator QVariant() const
  {
    return QVariant::fromValue(*this);
  }
};
Q_DECLARE_METATYPE(RecentFile)

inline QDataStream& operator<<(QDataStream& out, const RecentFile& recentFile)
{
  out << recentFile.fileName;
  out << recentFile.encoding;
  return out;
}

inline QDataStream& operator>>(QDataStream& in, RecentFile& recentFile)
{
  in >> recentFile.fileName;
  in >> recentFile.encoding;
  return in;
}

//! @struct FindText
/*! \brief It contains the recently searched text from find/replace dialog .
 * We must register this struct as a meta type since we need to use it as a QVariant.
 * This is used to store the recent texts information in omedit.ini file.
 * The QDataStream also needed to be defined for this struct.
 */
struct FindText
{
  QString text;
  operator QVariant() const
  {
    return QVariant::fromValue(*this);
  }
};
Q_DECLARE_METATYPE(FindText)

inline QDataStream& operator<<(QDataStream& out, const FindText& findText)
{
  out << findText.text;
  return out;
}

inline QDataStream& operator>>(QDataStream& in, FindText& findText)
{
  in >> findText.text;
  return in;
}

#endif // UTIL_H

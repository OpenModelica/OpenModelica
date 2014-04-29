/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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
#include <QDoubleSpinBox>
#include <QVariant>

#ifndef UTILITIES_H
#define UTILITIES_H

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

/*!
  \class Label
  \brief Creates a QLabel with elidable text. The default elide mode is Qt::ElideMiddle.Allows text selection via mouse.
  */
class Label : public QLabel
{
public:
  Label(QWidget *parent = 0, Qt::WindowFlags flags = 0);
  Label(const QString &text, QWidget *parent = 0, Qt::WindowFlags flags = 0);
  Qt::TextElideMode elideMode() const {return mElideMode;}
  void setElideMode(Qt::TextElideMode elideMode) {mElideMode = elideMode;}
  virtual QSize minimumSizeHint() const;
  virtual QSize sizeHint() const;
  void setText(const QString &text);
private:
  Qt::TextElideMode mElideMode;
  QString mText;
protected:
  virtual void resizeEvent(QResizeEvent *event);
};

//! @class DoubleSpinBox
/*! \brief Only keeping this class so that if in future we need to change the way QDoubleSpinBox works then we don't have to change the
 * forms controls again.
 */
/* Old Description */
/*! \brief It creates a double spinbox with a specified precision value.
 * If you want the precision value to be changed based on the global precision value defined in omedit.ini then connect this object with
 * the object of GeneralSettingsPage object right after creating this object. e.g,\n
 * connect(GeneralSettingsPage, SIGNAL(globalPrecisionValueChanged(int)), DoubleSpinBox, SLOT(handleGlobalPrecisionValueChange(int)));
 */
class DoubleSpinBox : public QDoubleSpinBox
{
  Q_OBJECT
public:
  DoubleSpinBox(QWidget *parent = 0) : QDoubleSpinBox(parent) {}
  /* old implementation
  DoubleSpinBox(int precision = 2, QWidget *parent = 0) : QDoubleSpinBox(parent) {setDecimals(precision);}
public slots:
  void handleGlobalPrecisionValueChange(int value) {setDecimals(value);}
  */
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

#endif // UTILITIES_H

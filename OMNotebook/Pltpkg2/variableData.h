/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
 */


#ifndef VARIABLEDATA_H
#define VARIABLEDATA_H

//Qt headers
#include <QList>
#include <QString>
#include <QColor>

enum {INTERPOLATION_NONE, INTERPOLATION_LINEAR, INTERPOLATION_CONSTANT};

class VariableData: public QList<qreal>
{
public:
	VariableData(QString name_, QColor color_ = Qt::color0)
  {
    currentIndex = 0;
    name = new QString(name_);
    color = color_;
  }
	VariableData(QString name_, QString id, QString data);
	~VariableData();

	QString variableName() {return *name;}
	void setVariableName(QString name_) {name = new QString(name_);}

	quint32 currentIndex;
	QColor color;

	int interpolation;
	bool drawPoints;

private:

	QString *name;

};

#endif

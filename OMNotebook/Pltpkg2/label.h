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

#ifndef LABEL_H
#define LABEL_H

//Qt headers
#include <QLabel>
#include <QString>

using namespace std;


class Label: public QLabel
{
public:
	Label(QWidget * parent = 0, Qt::WindowFlags f = 0 ): QLabel(parent, f)
	{

	}
	Label(const QString & text, QWidget * parent = 0, Qt::WindowFlags f = 0): QLabel(text, parent,f)
	{


	}
	~Label()
	{

	}

protected:
	void paintEvent ( QPaintEvent * event )
	{
		QPainter painter(this);
		render(&painter);
	}

public:
	void render(QPainter* painter, QPointF pos = QPointF())
	{
		painter->save();
		painter->translate(pos.x(), pos.y());

		painter->setFont(font());
		painter->drawText(rect(), Qt::AlignCenter, text());

		painter->restore();
	}
};

#endif


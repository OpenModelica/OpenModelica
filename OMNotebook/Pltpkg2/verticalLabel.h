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

#ifndef VERTICALLABEL_H
#define VERTICALLABEL_H

//Qt headers
#include <QLabel>
#include <QString>

using namespace std;

class VerticalLabel: public QLabel
{

public:
	VerticalLabel(QWidget * parent = 0, Qt::WindowFlags f = 0 ): QLabel(parent, f)
	{

	}

	VerticalLabel(const QString & text, QWidget * parent = 0, Qt::WindowFlags f = 0): QLabel(text, parent,f)
	{
		setText(text);
	}

	~VerticalLabel()
	{

	}

protected:
	void paintEvent ( QPaintEvent * event )
	{
		QPainter painter(this);
		render(&painter);
	}

public:
	void setText(const QString& text)
	{
		QLabel::setText(text);
		int h = fontMetrics().height();

		setMaximumWidth(h);
	}

	void render(QPainter* painter, QPointF pos = QPointF())
	{
		painter->save();
		painter->translate(pos.x(), pos.y());
		painter->translate(width() /2., height() /2.);

		painter->rotate(-90);
		painter->translate(height() /-2., width() /-2.);
		painter->setFont(font());

		painter->drawText(QRect(rect().left(), rect().top(), rect().height(),rect().width()), Qt::AlignCenter, text());
		painter->restore();
	}
};


#endif


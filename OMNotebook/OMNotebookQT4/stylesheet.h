/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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

// REMADE LARGE PART OF THIS CLASS 2005-10-26 /AF

/*!
* \file stylesheet.h
* \author Anders Fernström (and Ingemar Axelsson)
* \date 2005-10-26
*
* \brief Had to remake the class to be compatible with the richtext
* system that is used in QT4. The old file have been renamed to
* 'stylesheet.h.old' /AF
*/

#ifndef STYLESHEET_H
#define STYLESHEET_H


//STD Headers
#include <vector>

//QT Headers
#include <QtCore/QString>
#include <QtCore/QHash>
#include <QtXml/qdom.h>

//IAEX Headers
#include "cellstyle.h"


namespace IAEX
{
	class Stylesheet : public QObject
	{
		Q_OBJECT

	public:
		static Stylesheet *instance(const QString &filename);

		CellStyle getStyle(const QString &style);
		QHash<QString,CellStyle> getAvailableStyles() const;
		std::vector<QString> getAvailableStyleNames() const;

	protected:
		void initializeStyle();
		void traverseStyleSettings(QDomNode p, CellStyle *item) const;
		void parseBorderTag(QDomElement element, CellStyle *item) const;
		void parseAlignmentTag(QDomElement element, CellStyle *item) const;
		void parseFontTag(QDomElement element, CellStyle *item) const;
		void parseChapterLevelTag(QDomElement element, CellStyle *item) const;

	private:
		Stylesheet(const QString filename);

		QDomDocument *doc_;
		static Stylesheet *instance_;

		QHash<QString,CellStyle> styles_;
		std::vector<QString> styleNames_;
	};
}
#endif

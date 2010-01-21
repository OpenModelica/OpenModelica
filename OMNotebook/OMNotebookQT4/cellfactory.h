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

/*!
 * \file cellfactory.cpp
 * \author Ingemar Axelsson (and Anders Fernström)
 * \date 2005-10-28 (update)
 */

#ifndef CELLFACTORY_H
#define CELLFACTORY_H


//QT Headers
#include <QtCore/QString>

//IAEX Headers
#include "factory.h"
#include "document.h"
#include "cell.h"


namespace IAEX
{
	/*!
	 * \breif Interface for all cellfactories.
	 */
	class CellFactory : public Factory
	{
	public:
		CellFactory(Document *doc);
		virtual ~CellFactory();

		virtual Cell *createCell(const QString &style, Cell *parent=0);

	private:
		Document *doc_;
	};
}
#endif

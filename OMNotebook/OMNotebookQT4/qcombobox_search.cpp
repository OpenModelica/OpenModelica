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
 * \file qcombobox_search.cpp
 * \author Anders Fernström
 * \date 2006-08-24
 */


// QT Headers
#include <QtGui/QKeyEvent>

// IAEX Headers
#include "qcombobox_search.h"


namespace IAEX
{
	/*!
	 * \class ComboBoxSearch
	 * \author Anders Fernström
	 * \date 2006-08-24
	 *
    * \brief Reimplement the QComboBox to get more specified function
	 * on Qt's combo box for a serach box
	 */
	ComboBoxSearch::ComboBoxSearch( QWidget* parent )
		: QComboBox( parent )
	{
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-08-24
	 *
	 * \brief The class destructor
	 */
	ComboBoxSearch::~ComboBoxSearch()
	{
	}


	// REIMPLEMENTED FUNCTIONS
	// ------------------------------------------------------------------

	/*!
	 * \author Anders Fernström
	 * \date 2006-08-24
	 *
	 * \brief Reimplement what happen when a key event is sent to the combobox
	 */
	void ComboBoxSearch::keyPressEvent( QKeyEvent* event )
	{
		if( event->key() == Qt::Key_Return || event->key() == Qt::Key_Enter )
		{
			emit returnPressed();
		}
		else
			QComboBox::keyPressEvent( event );
	}

}

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
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

// FILE/CLASS ADDED 2005-11-04 /AF

/*!
 * \file otherdlg.h
 * \author Anders Fernström
 */

#ifndef OTHERDLG_H
#define OTHERDLG_H


#include "ui_OtherDlg.h"


namespace IAEX
{
	/*!
	 * \class OtherDlg
	 * \author Anders Fernström
	 * \date 2005-11-04
	 *
	 * \breif Class of opening a dialog window for entering av value...
	 */
	class OtherDlg : public QDialog
	{
	public:
		OtherDlg( QWidget *parent, int min, int max)
			: QDialog(parent), min_(min), max_(max)
		{
			ui.setupUi(this);

			QString minW;
			QString maxW;
			minW.setNum( min_ );
			maxW.setNum( max_ );

			QString text = QString("Enter value (") + minW +
				QString("-") + maxW + QString(")");

			ui.label->setText( text );

			//set fixed size
			setMinimumHeight( height() );
			setMaximumHeight( height() );
			setMinimumWidth( width() );
			setMaximumWidth( width() );
		}
		virtual ~OtherDlg(){}
		int value()
		{
			bool ok;
			int value = ui.lineEdit->text().toInt(&ok);

			if(ok)
				if( min_ <= value && value <= max_ )
					return value;

			return -1;
		}

	private:
		Ui::SelectDialog ui;
		int min_;
		int max_;
	};
}

#endif

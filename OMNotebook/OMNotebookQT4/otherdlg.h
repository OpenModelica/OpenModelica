/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    
	* Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

    * Neither the name of Linköpings universitet nor the names of its contributors
      may be used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
*/

// FILE/CLASS ADDED 2005-11-04 /AF

/*! 
 * \file otherdlg.h
 * \author Anders Fernström
 */

#ifndef OTHERDLG_H
#define OTHERDLG_H


#include "ui_otherdlg.h"


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

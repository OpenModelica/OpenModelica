/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet,
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

// FILE/CLASS ADDED 2005-11-20 /AF

/*! 
 * \file imagesizedlg.h
 * \author Anders Fernström
 */

#ifndef IMAGESIZEDLG_H
#define IMAGESIZEDLG_H


#include "ui_ImageSizeDlg.h"


namespace IAEX
{	
	/*! 
	 * \class ImageSizeDlg
	 * \author Anders Fernström
	 * \date 2005-11-20
	 * 
	 * \breif Class of opening a dialog window for selecting image size...
	 */
	class ImageSizeDlg : public QDialog
	{
	public:
		ImageSizeDlg( QWidget *parent, QImage *image)
			: QDialog(parent), image_(image) 
		{ 
			ui.setupUi(this);
			
			QString width;
			width.setNum( image->size().width() );
			ui.widthEdit->setText( width );

			QString height;
			height.setNum( image->size().height() );
			ui.heightEdit->setText( height );

			//set fixed size
			setMinimumHeight( this->height() );
			setMaximumHeight( this->height() );
			setMinimumWidth( this->width() );
			setMaximumWidth( this->width() );
		}
		virtual ~ImageSizeDlg(){}

		QSize value()
		{
			bool heightOK;
			bool widthOK;

			int height = ui.heightEdit->text().toInt( &heightOK );
			int width = ui.widthEdit->text().toInt( &widthOK );

			QSize size;
			if( heightOK && widthOK )
			{
				size.setHeight( height );
				size.setWidth( width );
			}
			else
			{
				size.setHeight( -1 );
				size.setWidth( -1 );
			}
			
			return size;
		}
		

	private:
		Ui::ImageDialog ui;
		QImage *image_;
	};
}

#endif

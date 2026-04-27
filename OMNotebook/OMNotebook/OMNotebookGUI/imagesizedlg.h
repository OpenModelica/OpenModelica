/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
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
   * \brief Class of opening a dialog window for selecting image size...
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

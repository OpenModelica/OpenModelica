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

#ifndef DOCUMENTVIEW_H
#define DOCUMENTVIEW_H

//QT Headers
#include <QtGui/QMainWindow>

//IAEX Headers
#include "document.h"


namespace IAEX
{

   /*!
    * \interface DocumentView
    *
    * \brief Describes what a documentView should implement.
    *
    * Base interface for document views.
    *
	* 2005-10-11 AF, Porting, changed from q3mainwindow to mainwindow
	* 2005-11-02 AF, Porting, changed Qt::WDestructiveClose in QMainWindow()
	* to setAttribute(Qt::WA_DeleteOnClose); inside QMainWindow().
    */
   class DocumentView : public QMainWindow
   {
      Q_OBJECT
   public:
      DocumentView(QWidget *parent=0)
	 : QMainWindow(parent){ setAttribute(Qt::WA_DeleteOnClose); }
      virtual ~DocumentView(){}

      virtual void update() = 0;
	  virtual Document* document() = 0;

   };
};

#endif

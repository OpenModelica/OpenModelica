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

#ifndef _CELLDOCUMENTVIEW_H
#define _CELLDOCUMENTVIEW_H

#include "documentview.h"

namespace IAEX
{

   /*!\class CellDocumentView
    * \brief Describes the document window.
    *
    * Describes how a document should look like. The application uses
    * the Single Document Interface. That is all documents has a
    * window that looks like the main window.
    *
    * \deprecated
    */
   class CellDocumentView : public QMainWindow, public DocumentView
   {
   public:
      CellDocumentView(Document *subject) : subject_(subject)
      {
		 //Connect view to document.

		  subject_->attach(this);
      }

      virtual ~CellDocumentView(){}

      void update()
      {
		 if(centralWidget())
		 {
			//remove currentwidget.
		 }

		 //Update with new widget.
		 setCentralWidget(subject_->getState());
      }

   private:
      Document *subject_;
   };
};

#endif

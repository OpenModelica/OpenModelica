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

#ifndef _OMCINTERACTIVE_H
#define _OMCINTERACTIVE_H

#include <QtCore/QString>

#include "omc_communicator.hpp"
#include "inputcelldelegate.h"

namespace IAEX
{
	class OmcInteractiveEnvironment : public InputCellDelegate
	{	
  private:
		OmcInteractiveEnvironment();
		virtual ~OmcInteractiveEnvironment();

  public:    
    static OmcInteractiveEnvironment* getInstance();
		virtual QString getResult();
		virtual QString getError();					// Added 2006-02-02 AF
		virtual void evalExpression(const QString expr);
		virtual void closeConnection();				// Added 2006-02-02 AF
		virtual void reconnect();					// Added 2006-02-02 AF
		virtual bool startDelegate();				// Added 2006-02-09 AF
		static bool startOMC();						// Added 2006-02-09 AF
		static QString OMCVersion();				// Added 2006-08-17 AF

	private:
    static OmcInteractiveEnvironment* selfInstance;
		OmcCommunicator &comm_;
		QString result_;
    QString error_;
	};
}
#endif

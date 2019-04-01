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

#ifndef _OMCINTERACTIVE_H
#define _OMCINTERACTIVE_H

#include <QtCore/QString>

#include "meta/meta_modelica.h"
#include "inputcelldelegate.h"

namespace IAEX
{
  class OmcInteractiveEnvironment : public InputCellDelegate
  {
  private:
    OmcInteractiveEnvironment(threadData_t *threadData);
    virtual ~OmcInteractiveEnvironment();

  public:
    threadData_t *threadData_;

    static OmcInteractiveEnvironment* getInstance(threadData_t *threadData = 0);
    virtual QString getResult();
    virtual QString getError();
    virtual int getErrorLevel();
    virtual void evalExpression(const QString expr);
    static QString OMCVersion();
    static QString OpenModelicaHome();
    static QString TmpPath();

  private:
    static OmcInteractiveEnvironment* selfInstance;
    QString result_;
    QString error_;
    int severity;
  };
}
#endif

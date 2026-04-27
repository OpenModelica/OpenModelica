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

#ifndef _GRAPHCELLDELEGATE_H
#define _GRAPHCELLDELEGATE_H

#include <QtCore/QObject>
#include <QtCore/QString>

namespace IAEX
{
   /*!
    * \interface InputCellDelegate
    *
    * \brief Describes what members a delegate to the inputcell should
    * implement.
    *
    * This interface should be subclassed in order to extend the
    * applications functionality to evaluate another type of
    * expressions. At the moment a Modelica environment is
    * implemented, and also a Standard ML environment is implemented.
    *
    */
   class GraphCellDelegate
   {
   public:
     virtual ~GraphCellDelegate() = default;
     virtual QString getResult() = 0;
     virtual QString getError() = 0;          // Added 2006-02-02 AF
     virtual void evalExpression(QString &expr) = 0;
     virtual void closeConnection() = 0;        // Added 2006-02-02 AF
     virtual void reconnect() = 0;            // Added 2006-02-02 AF
     virtual bool startDelegate() = 0;          // Added 2006-02-09 AF
   };

}
#endif

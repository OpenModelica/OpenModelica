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

/*! \file rule.h
 * \author Ingemar Axelsson
 *
 * \brief Describes a cell rule.
 */

#ifndef _RULE_H
#define _RULE_H

#include <string>
#include <iostream>


namespace IAEX
{
   /*! \class Rule
    *
    * \brief Record describing a formatrule.
    *
    * Rule is used to store formatting information for some cells. Also see Stylesheet
    */
   class Rule
   {
   public:
      typedef QString attribute_t;
      typedef QString value_t;
   public:
      Rule(attribute_t a, value_t v) : attribute_(a), value_(v){}
      virtual ~Rule(){}

      attribute_t attribute() const
      {
   return attribute_;
      }

      value_t value() const
      {
   return value_;
      }

    void setValue( value_t val )
    {
    value_ = val;
    }

   private:
      attribute_t attribute_;
      attribute_t value_;
   };
}

#endif

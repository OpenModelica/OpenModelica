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

/*! \file rule.h
 * \author Ingemar Axelsson
 *
 * \brief Describes a cell rule.
 */

#ifndef _RULE_H
#define _RULE_H

#include <string>
#include <iostream>

using namespace std;

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

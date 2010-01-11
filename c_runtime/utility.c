/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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
 */

#include "utility.h"

int in_range_integer(modelica_integer i,
		     modelica_integer start,
		     modelica_integer stop)
{
  if (start <= stop) if ((i >= start) && (i <= stop)) return 1;
  if (start > stop) if ((i >= stop) && (i <= start)) return 1;
  return 0;
}

int in_range_real(modelica_real i,
		  modelica_real start,
		  modelica_real stop)
{
  if (start <= stop) if ((i >= start) && (i <= stop)) return 1;
  if (start > stop) if ((i >= stop) && (i <= start)) return 1;
  return 0;
}

modelica_real modelica_div(modelica_real x, modelica_real y)
{
	return (modelica_real)((modelica_integer)(x/y));
}

modelica_real modelica_mod(modelica_real x, modelica_real y)
{
	return (x - floor(x/y) * y);
}

modelica_real rem(modelica_real x, modelica_real y)
{
	return fmod(x, y);
}


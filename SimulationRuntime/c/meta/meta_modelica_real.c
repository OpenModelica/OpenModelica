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
 */

#define __OPENMODELICA__METAMODELICA

#include "meta_modelica.h"
#include "meta_modelica_real.h"
#include "meta_modelica_builtin.h"
#include <limits.h>
#include <time.h>
#include <math.h>
#include <string.h>
#include <stdio.h>

#if defined(_MSC_VER)
#include <float.h>
#define isinf(d) (!_finite(d) && !_isnan(d))
#define isnan _isnan
#define snprintf _snprintf
#endif

modelica_metatype boxptr_realMin(modelica_metatype a,modelica_metatype b)
{
  return mmc_mk_rcon(fmin(mmc_unbox_real(a),mmc_unbox_real(b)));
}

modelica_metatype boxptr_realMax(modelica_metatype a,modelica_metatype b)
{
  return mmc_mk_rcon(fmax(mmc_unbox_real(a),mmc_unbox_real(b)));
}



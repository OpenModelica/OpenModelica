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

#include <stdio.h>

extern "C" {

void* SimulationResults_readPtolemyplotVariables(const char *filename, const char *visvars)
{
  fprintf(stderr, "SimulationResults_readPtolemyplotVariables NYI\n");
  throw 1;
}

void* SimulationResults_readPtolemyplotDataset(const char *filename, void *vars, int i)
{
  fprintf(stderr, "SimulationResults_readPtolemyplotDataset NYI\n");
  throw 1;
}

void* SimulationResults_readPtolemyplotDatasetSize(const char *filename)
{
  fprintf(stderr, "SimulationResults_readPtolemyplotDatasetSize NYI\n");
  throw 1;
}

}

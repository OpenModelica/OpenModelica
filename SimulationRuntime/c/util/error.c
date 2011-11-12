/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "error.h"

/* Global JumpBuffer */
jmp_buf globalJmpbuf;

const unsigned int LV_NONE          = 0;
const unsigned int LV_STATS         = (1<<0);
const unsigned int LV_INIT          = (1<<1);
const unsigned int LV_SOLVER        = (1<<2);
const unsigned int LV_JAC           = (1<<3);
const unsigned int LV_ENDJAC        = (1<<4);
const unsigned int LV_NONLIN_SYS    = (1<<5);
const unsigned int LV_EVENTS        = (1<<6);
const unsigned int LV_ZEROCROSSINGS = (1<<7);
const unsigned int LV_DEBUG         = (1<<8);
const unsigned int LV_LOG_RES_INIT  = (1<<0) | (1<<1);

unsigned int globalDebugFlags = 0;

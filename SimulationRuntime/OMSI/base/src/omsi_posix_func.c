/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/* Write own POSIX functions, since ANSI C does not has them. */

#ifndef POSIX

#include <omsi_posix_func.h>
#include <omsi_global.h>

omsi_char* omsi_strdup (const omsi_char *s) {
    omsi_char* d = (omsi_char*) global_callback->allocateMemory (strlen (s) + 1, sizeof(omsi_char));
    if (d == NULL) {
        return NULL;
    }
    strcpy (d,s);
    return d;
}

#else

omsi_char* omsi_strdup (const omsi_char *s) {
    return strdup(s);
}


#endif

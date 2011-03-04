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

#ifndef META_MODELICA_GC_PAGES_H_
#define META_MODELICA_GC_PAGES_H_

#include "modelica.h"

#if defined(__cplusplus)
extern "C" {
#endif

#define MMC_GC_PAGE_SIZE       128*1024*1024  /* default page size 64MB chunks, can be changed */
#define MMC_GC_NUMBER_OF_PAGES             2  /* default number of pages */

/* create the page list and add the first page */
mmc_List pages_create(long default_page_size, int default_number_of_pages);
/* create and allocate a page */
mmc_GC_free_slot page_create(long page_size);
/* add a page */
mmc_List pages_add(mmc_List list, mmc_GC_free_slot page);

#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_GC_PAGES_H_ */


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

#ifndef META_MODELICA_GC_COMMON_
#define META_MODELICA_GC_COMMON_

#if defined(__cplusplus)
extern "C" {
#endif

#include "modelica.h"

/***********************************************************************/
/***********************************************************************/
/***************************** SETTINGS ********************************/
/***********************************************************************/
/***********************************************************************/

/* roots settings */
#define MMC_GC_ROOTS_SIZE_INITIAL        8*1024  /* initial size of roots, reallocate on full */
#define MMC_GC_ROOTS_MARKS_SIZE_INITIAL  8*1024  /* initial size of roots marks, reallocate on full */


/* mark-and-sweep settings */
#define MMC_GC_NUMBER_OF_MARK_THREADS  6
#define MMC_GC_NUMBER_OF_SWEEP_THREADS 6

#define MMC_GC_PAGE_SIZE           64*1024*1024  /* default page size 160MB chunks, can be changed */
#define MMC_GC_NUMBER_OF_PAGES                1  /* default number of pages at start */
#define MMC_GC_PAGES_SIZE_INITIAL          1024  /* default size for pages array at start, realloc on full */

#define MMC_GC_FREE_SIZES                  1024  /* small object with size until max 101 */
#define MMC_GC_FREE_SLOTS_SIZE_INITIAL        1  /* for big objects */

#define MMC_GC_MARK   1
#define MMC_GC_UNMARK 0

/* generational settings */
#define MMC_EXIT_ON_FAILURE     0
#define MMC_NO_EXIT_ON_FAILURE  1

#define MMC_YOUNG_SIZE          (1024*1024*16)
#define MMC_C_HEAP_REGION_SIZE  (1024*1024) /*  4 Mwords */

#define MMC_SHARED_STRING_MAX 100   /* share only strings less than this */
#define MMC_STRING_CACHE_MAX 1000000 /* the maximum of strings kept in the cache between two garbage collections */


/* gc types */
#define MMC_GC_GENERATIONAL  0
#define MMC_GC_MARK_AND_SWEP 1

/* roots sizes */
#define MMC_GC_GLOBAL_ROOTS_SIZE 1024

struct mmc_GC_settings_type
{
  char      gc_type; /* one of the gc types above */
  /* generational settings */
  size_t    young_size; /* the size of the young generation */

  /* mark-and-sweep settings */
  size_t    number_of_pages;  /* the initial number of pages */
  size_t    pages_size;       /* the default pages array size */
  size_t    page_size;        /* the default page size */
  size_t    free_slots_size;  /* the default free slots array size */
  size_t    number_of_mark_threads;  /* the initial number of mark threads */
  size_t    number_of_sweep_threads; /* the initial number of sweep threads */

  /* general settings */
  size_t    roots_size;       /* the default size of the array of roots */
  size_t    roots_marks_size; /* the default size of marks in the array of roots */

  char      trace_enabled;  /* tracing flag */
  char      string_sharing; /* string sharing flag */
  char      debug;          /* flag for GC debugging */
};
typedef struct mmc_GC_settings_type mmc_GC_settings_type;

extern mmc_GC_settings_type mmc_GC_settings_default;

/* create the settings */
mmc_GC_settings_type settings_create(
  size_t    number_of_pages,
  size_t    pages_size,
  size_t    page_size,
  size_t    free_slots_size,
  size_t    roots_size,
  size_t    roots_marks_size,
  size_t    number_of_mark_threads,
  size_t    number_of_sweep_threads);

/***********************************************************************/
/***********************************************************************/
/***************************** STATISTICS ******************************/
/***********************************************************************/
/***********************************************************************/

/* GC statistics, add more here if needed */
struct mmc_GC_stats_type
{
  size_t allocated;    /* the total allocated memory */
  size_t collected;    /* the total collected memory */
  size_t collections;  /* the number of performed collections */
};
typedef struct mmc_GC_stats_type mmc_GC_stats_type;

/* create the statistics structure */
mmc_GC_stats_type stats_create(void);

/***********************************************************************/
/***********************************************************************/
/******************************* LISTS *********************************/
/***********************************************************************/
/***********************************************************************/

/*
 *
 */
struct mmc_GC_free_slot_type
{
  modelica_metatype start;
  size_t            size;
};
typedef struct mmc_GC_free_slot_type mmc_GC_free_slot_type;

struct mmc_GC_free_slots_type
{
  mmc_GC_free_slot_type*  start;
  size_t                  current;
  size_t                  limit;
};
typedef struct mmc_GC_free_slots_type mmc_GC_free_slots_type;

struct mmc_GC_free_slots_fixed_type
{
  modelica_metatype*  start;
  size_t              current;
  size_t              limit;
};
typedef struct mmc_GC_free_slots_fixed_type mmc_GC_free_slots_fixed_type;

struct mmc_GC_free_list_type
{
   mmc_GC_free_slots_fixed_type szSmall[MMC_GC_FREE_SIZES]; /* the array points to free slots of sizes equal to the index. */
   mmc_GC_free_slots_type       szLarge; /* for sizes bigger than the index in sizes */
};
typedef struct mmc_GC_free_list_type mmc_GC_free_list_type;

mmc_GC_free_list_type* list_create(size_t default_free_slots_size);
mmc_GC_free_list_type* list_add(mmc_GC_free_list_type* free, modelica_metatype p, size_t size);
size_t list_length(mmc_GC_free_list_type* free);
size_t list_size(mmc_GC_free_list_type* free);
modelica_metatype list_get(mmc_GC_free_list_type* free, size_t size);

/***********************************************************************/
/***********************************************************************/
/******************************* STACK *********************************/
/***********************************************************************/
/***********************************************************************/

/*
//struct mmc_GC_local_state_type // the structure of local GC state that is saved on stack
//{
//  const char* functionName; // the function name
//  size_t rootsMark;         // the roots mark
//  size_t rootsStackIndex;   // the index in the mark stack (basically the depth)
//};
//typedef struct mmc_GC_local_state_type mmc_GC_local_state_type;
*/

#define mmc_GC_local_state_type size_t

/* A stack as an array. */
struct mmc_stack_type
{
  mmc_GC_local_state_type  *start; /* the stack array of marks */
  size_t                   current; /* the current limit */
  size_t                   limit;   /* the limit of roots */
};
typedef struct mmc_stack_type  mmc_stack_type;

/* make an empty stack */
mmc_stack_type* stack_create(size_t default_stack_size);
/* check if stack is empty, nonzero */
int stack_empty(mmc_stack_type* stack);
/* peek stack  */
mmc_GC_local_state_type stack_peek(mmc_stack_type* stack);
/* pop the stack */
mmc_GC_local_state_type stack_pop(mmc_stack_type* stack);
/* push stack */
mmc_stack_type* stack_push(mmc_stack_type* stack, mmc_GC_local_state_type el);
/* stack decrease */
mmc_stack_type* stack_decrease(mmc_stack_type* stack, size_t default_stack_size);
/* delete stack */
mmc_stack_type* stack_clear(mmc_stack_type* stack);


/***********************************************************************/
/***********************************************************************/
/******************************* PAGES *********************************/
/***********************************************************************/
/***********************************************************************/


struct mmc_GC_page_type
{
  modelica_metatype       start;           /* the start of the page */
  size_t                  size;            /* the size of the page in words */
  mmc_GC_free_list_type  *free;            /* the free list in the page, classified */
  size_t                  maxFree;         /* the max size of all free slots */
};
typedef struct mmc_GC_page_type mmc_GC_page_type;


struct mmc_GC_pages_type
{
  mmc_GC_page_type*       start;           /* the start of the array of pages */
  size_t                  current;         /* the current limit */
  size_t                  limit;           /* the limit of pages */
};
typedef struct mmc_GC_pages_type mmc_GC_pages_type;

/* create the pages structure and allocate the default pages with default size */
mmc_GC_pages_type pages_create(size_t default_pages_size, size_t default_page_size, size_t default_number_of_pages, size_t default_free_slots_size);
/* add a new page */
mmc_GC_pages_type pages_add(mmc_GC_pages_type pages, mmc_GC_page_type page);
/* create a new page */
mmc_GC_page_type page_create(size_t default_page_size, size_t default_free_slots_size);
/* realloc and increase the pages structure */
mmc_GC_pages_type pages_increase(mmc_GC_pages_type pages, size_t default_pages_size);
/* realloc and decrease the pages structure */
mmc_GC_pages_type pages_decrease(mmc_GC_pages_type pages, size_t default_pages_size);
/* populate the free list with free space */
mmc_GC_page_type list_populate(mmc_GC_page_type page);

int is_in_free(modelica_metatype p);
int is_inside_page(modelica_metatype p);
size_t pages_list_length(mmc_GC_pages_type pages);
size_t pages_list_size(mmc_GC_pages_type pages);


#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_GC_COMMON_ */


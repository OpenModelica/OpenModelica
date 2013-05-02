/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2011, Linköping University,
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

/*
 * file:      Database.c
 * package:   Database (see Datatbase.mo)
 * description: This module contains functionality for creating and using SQlite databases.
 *
 * $Id: Database.c 8579 2011-04-11 09:17:03Z sjoelund.se $
 *
 * This package provides functionality for creating and using databases.
 * It is a wrapper to SQlite.
 */

#include <stdio.h>
#include <stdlib.h>
#include <sqlite3.h>

/* the SQLite error codes are 0 (success) until 101, so to be safe we start at 500 */
#define DATABASE_ERROR_DATABASE_INDEX_OVERFLOW  500
#define DATABASE_ERROR_NOT_INITIALIZED          501

// say we can have 1024 DBs active at any time.
#define DATABASE_MAX_DATABASES 1024
sqlite3 *DATABASES[1024] = {0};

static int callback(void *result, int argc, char **argv, char **azColName);

int checkIndex(int index)
{
  if (index >= DATABASE_MAX_DATABASES || index < 0)
    return DATABASE_ERROR_DATABASE_INDEX_OVERFLOW;
  if (!DATABASES[index])
    return DATABASE_ERROR_NOT_INITIALIZED;
  return 0;
}

void DatabaseImpl_init(void)
{
   sqlite3_libversion(); // Make sure we link against sqlite3 :)
   // do nothing for now
}

int DatabaseImpl_open(int index, const char* name)
{
  int rc = checkIndex(index);
  /* check the index */
  if (rc == DATABASE_ERROR_DATABASE_INDEX_OVERFLOW) return rc;

  //fprintf(stderr, "opendb: %s\n", name); fflush(stderr);

  rc = sqlite3_open(name, &DATABASES[index]);
  if( rc ) {
    fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(DATABASES[index])); fflush(stderr);
    sqlite3_close(DATABASES[index]);
    DATABASES[index] = 0;
    return rc;
  }

  //fprintf(stderr, "opendb: %s with index %d value %p rc %d\n", name, index, DATABASES[index], rc); fflush(stderr);

  return rc;
}

int DatabaseImpl_query(int index, const char* sqlStatement, void** result)
{
  char *zErrMsg = 0;
  sqlite3 *db = DATABASES[index];
  int rc = checkIndex(index);

  /* check the index */
  if (rc) return rc;

  //fprintf(stderr, "%s\n", sqlStatement); fflush(stderr);

  rc = sqlite3_exec(db, sqlStatement, callback, result, &zErrMsg);
  if( rc != SQLITE_OK ){
    fprintf(stderr, "SQL error: %s\n", zErrMsg); fflush(stderr);
    sqlite3_free(zErrMsg);
    sqlite3_close(db);
    DATABASES[index] = 0;
    return rc;
  }
  return rc;
}


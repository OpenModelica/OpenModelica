#include "openmodelica.h"
#include "modelica.h"
#include "meta_modelica.h"
#include "Database.c"

void Database_init(void)
{
   DatabaseImpl_init();
}

void Database__open(int index, const char* name)
{
  if (DatabaseImpl_open(index, name))
  {
    MMC_THROW();
  }
}

void* Database__query(int index, const char* sql)
{
  void* result = mmc_mk_nil();
  if (!DatabaseImpl_query(index, sql, &result))
  {
    return result;
  }
  MMC_THROW();
}

static int callback(void *result, int argc, char **argv, char **azColName){
  int i;
  void** res = (void**)result;
  for(i = 0; i < argc; i++)
  {
    /* the result is a list of string tuples (name, value)*/
    *res = mmc_mk_cons(mmc_mk_box2(0, mmc_mk_scon(azColName[i]), mmc_mk_scon(argv[i] ? argv[i] : "NULL")), *res);
  }
  return 0;
}

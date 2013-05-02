#include "meta_modelica.h"
#include "Database.c"

void Database_init(void)
{
  DatabaseImpl_init();
}

int Database_open(int index, const char* _name)
{
  return DatabaseImpl_open(index, _name);
}

void* Database_query(int index, const char* _sql)
{
  void* result = mmc_mk_nil();
  if (DatabaseImpl_query(index, _sql, &result))
    return mmc_mk_nil();
  return result;
}

static int callback(void *result, int argc, char **argv, char **azColName){
  int i;
  void** res = (void**)result;
  for(i = 0; i < argc; i++)
  {
    /* the result is a list of string tuples (name, value)*/
    *res = mmc_mk_cons(
       mmc_mk_box2(
         0,
         mmc_mk_scon(azColName[i]),
         mmc_mk_scon(argv[i] ? argv[i] : "NULL")),
       *res);
  }
  return 0;
}

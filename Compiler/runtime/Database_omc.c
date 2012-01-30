
#include "Database.c"

void Database_init(void)
{
  DatbaseImpl_init();
}

int Database_open(int index, const char* _name)
{
  return DatbaseImpl_open(index, _name);
}

void* Database_query(int index, const char* _sql)
{
  void* result = mk_nil();
  if (DatbaseImpl_query(index, _sql, &result))
    return mk_nil();
  return result;
}



#include "Database.c"

void Database_5finit(void)
{
   DatabaseImpl_init();
}

RML_BEGIN_LABEL(Database__open)
{
  int index = RML_UNTAGFIXNUM(rmlA0);
  const char* name = RML_STRINGDATA(rmlA1);
  if (!DatabaseImpl_open(index, name))
    RML_TAILCALLK(rmlSC);
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Database__query)
{
  int index = RML_UNTAGFIXNUM(rmlA0);
  const char* sql = RML_STRINGDATA(rmlA1);
  void* result = mk_nil();
  if (!DatabaseImpl_query(index, sql, &result))
  {
    rmlA0 = result;
    RML_TAILCALLK(rmlSC);
  }
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL


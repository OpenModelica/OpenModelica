#include <iostream>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <vector>


using namespace std;


extern "C"
{
#include <assert.h>

static void errormsg()
{
cerr << "MODPAR disabled. Configure with --with-BOOST=boostdir and --with-MODPAR and recompile for enabling." << endl;
}

extern int TaskGraphExt_newTask(const char* _inString)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_addEdge(int _inInteger1, int _inInteger2, const char* _inString3, int _inInteger4)

{
  errormsg();
  throw 1;
}

extern int TaskGraphExt_getTask(const char* _inString)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_storeResult(const char* _inString1, int _inInteger2, int _inBoolean3, const char* _inString4)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_dumpGraph(const char* _inString)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_dumpMergedGraph(const char* _inString)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_registerStartStop(int _inInteger1, int _inInteger2)
{
  errormsg();
  throw 1;
}

extern int TaskGraphExt__getStartTask()
{
  errormsg();
  throw 1;
}

extern int TaskGraphExt__getStopTask()
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_mergeTasks(double _inReal1, double _inReal2)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_setExecCost(int _inInteger, double _inReal)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_setCommCost(int _inInteger, double _inReal)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_schedule(int _inInteger)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_generateCode(int _inInteger1, int _inInteger2, int _inInteger3)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_addInitState(int _inInteger1, const char* _inString2, const char* _inString3)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_addInitParam(int _inInteger1, const char* _inString2, const char* _inString3)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_addInitVar(int _inInteger1, const char* _inString2, const char* _inString3)
{
  errormsg();
  throw 1;
}

extern void TaskGraphExt_setTaskType(int _inInteger1, int _inInteger2)
{
  errormsg();
  throw 1;
}

} // extern "C"

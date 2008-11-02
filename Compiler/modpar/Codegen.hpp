#ifndef _CODEGEN_HPP
#define _CODEGEN_HPP

#include <string>
#include "TaskGraph.hpp"
#include "Schedule.hpp"
using namespace std;



class EdgePrioCmp
{
public:
  EdgePrioCmp(TaskGraph*tg) : m_taskgraph(tg) {};
  bool operator()(EdgeID &e1,EdgeID &e2)
  {
    return getPriority(e1,m_taskgraph) > getPriority(e2,m_taskgraph);
  };
private:
  TaskGraph * m_taskgraph;
};

typedef priority_queue<EdgeID,vector<EdgeID>,EdgePrioCmp> EdgePrioQueue;

class Codegen
{

public:

  static const string* generateOperator(const char,int);

  Codegen(char* fileName1,char *fileName2, char* fileName3);

  ~Codegen();

  void initialize(TaskGraph*, TaskGraph*, Schedule *, ContainSetMap *,int nproc,
		  int nx, int ny, int np, VertexID start, VertexID stop, vector<double> initvars
		  ,vector<double> initstates, vector<double> initparams,
		  vector<string> varnames, vector<string> statenames, vector<string> paramnames);

  void generateCode();

private:

  void generateGlobals();

  void generateParallelMPIHeaders();
  void generateParallelMPIGlobals();

  void generateParallelFunctions();
  void generateParallelFunction(TaskList *tasks,
				map<VertexID,double>& levelMap,
				int procno);
  void generateParallelFunctionHeader(int procno);
  void generateParallelFunctionBody(TaskList *tasks,
				    map<VertexID,double>& levelMap,
				    int proc);
  void generateParallelFunctionPrologue(int procno);
  void generateParallelFunctionEpilogue(int procno);
  void generateParallelFunctionArgument(int procno, ofstream &os);

  void generateTemporaries();
  void generateParallelFunctionLocals(TaskList *tasks);

  // Generates the residual function for solving nonlinear equation systems.
  void generateNonLinearResidualFunc(VertexID task);

  void generateKillCommand();
  void generateTmpDeclarations();

  void generateRecvData(VertexID task, int proc);
  void generateTaskCode(VertexID task,
			map<VertexID,double>& levelMap);

  void generateSubTaskCode(VertexID task);
  void generateSendData(VertexID task, int proc,bool genQuit);
  void generateSendCommand(VertexID source, VertexID target,
			   int sourceproc,
			   int targetproc, bool genQuit);
  void generateRecvCommand(VertexID source, VertexID target,
			   int sourceproc,
			   int targetproc);

  void generateParallelCalls();
  void generateDynamic();
  void generateMain();

  void generateInitialConditions();

  int getParentSize(VertexID task, TaskGraph *tg);


  TaskGraph* m_tg;
  TaskGraph* m_merged_tg;
  Schedule*  m_schedule;
  ContainSetMap * m_cmap;

  char *m_fileName;
  char *m_fileNameFunc;
  char *m_fileNameInit;
  ofstream m_cstream;
  ofstream m_cstreamFunc;
  ofstream m_initstream;

  VertexID m_start; /* Start task, on processor 0*/
  VertexID m_stop; /* Stop task, on processor 0 */

  int m_nproc;	/* No of processors */

  int m_nx;	/* No of states */
  int m_ny;	/* No of alg. vars */
  int m_np;	/* No of parameters */

  vector<double> m_initvars; /* initial values for alg. variables */
  vector<double> m_initstates; /* initial values for state variables */
  vector<double> m_initparams; /* "initial values" for parameters */

  vector<string> m_varnames;
  vector<string> m_statenames;
  vector<string> m_paramnames;
};


#endif

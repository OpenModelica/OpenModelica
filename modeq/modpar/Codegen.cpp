#include "Codegen.hpp"

const string TAB = string("        ");

const string * Codegen::generateOperator(const char op ,int operands)
{
  string str;
  str=str+"%s";
  for (int i=0; i < operands-1; i++) {
    str = str+op+"%s";
  }
  return new string(str);
}



Codegen::Codegen(char *file1,char *file2)
{
  m_fileName = file1;
  m_fileNameFunc = file2;

  m_cstream.open(m_fileName);
  m_cstreamFunc.open(m_fileNameFunc);
}

Codegen::~Codegen()
{
  m_cstream.close();
  m_cstreamFunc.close();
}

void Codegen::generateMain() 
{
  //main function
  m_cstream << "int main(int argc, char* argv[])" << endl << "{" << endl;

  m_cstream << TAB << "MPI_Init(&argc,&argv);" << endl;
  m_cstream << TAB << "MPI_Comm_rank(MPI_COMM_WORLD,&rank);" << endl;
  m_cstream << TAB << "double start,stop,step;" << endl;
  m_cstream << TAB << "read_input(argc,argv,x,xd,y,p,&start,&stop,&step);" << endl;
  
  m_cstream << TAB << "MPI_Bcast(p,np,MPI_DOUBLE,0,MPI_COMM_WORLD); // broadcast parameters" << endl;

  generateParallelCalls();

  m_cstream << "return 0;"<<endl << "}" << endl << endl;  
}


void Codegen::generateParallelFunctions()  
{
  map<VertexID,double> level;

  // dfs needs unique index no for each vertex
  initialize_index(m_tg);

  //calculate level for nodes in orig taskgraph.  
  level_visitor vis(&level);
  depth_first_search(*m_tg,visitor(vis));

  // Generate temporary names
  generateTemporaries();
  
  for (int i=0; i < m_nproc; i++) {
    generateParallelFunction(m_schedule->get_tasklist(i),level,i);
  }  
}


void Codegen::generateTemporaries()
{
  VertexIterator v,v_end;
  
  for (tie(v,v_end)=vertices(*m_tg); v != v_end; v++) {
    if (getResultName(*v,m_tg)== "" && getTaskType(*v,m_tg) == TempVar) {
      setResultName(*v,*genTemp(),m_tg);
    }
  }
}
void Codegen::generateParallelFunction(TaskList *tasks, 
							  map<VertexID,double>& levelMap, 
							  int procno)
{
  generateParallelFunctionPrologue(procno);
  generateParallelFunctionHeader(procno);
 
  generateParallelFunctionBody(tasks, levelMap, procno);
  generateParallelFunctionEpilogue(procno);
}

void Codegen::generateParallelFunctionBody(TaskList *tasks, 
							      map<VertexID,double>& levelMap, 
							      int proc)
{
  m_cstream << endl << TAB << "/* Proc body */" << endl;
  generateParallelFunctionLocals(tasks);
  VertexID t;
  
  while(!tasks->empty()) {
    t = tasks->top(); 
    generateRecvData(t,proc);
    generateTaskCode(t,levelMap);
    generateSendData(t,proc);
    tasks->pop();
  }

}

void Codegen::generateParallelFunctionLocals(TaskList *tasks)
{

}

void Codegen::generateRecvData(VertexID task, int proc)
{
  ParentsIterator p,p_end;
  for (tie(p,p_end) = parents(task,*m_merged_tg); p != p_end; p++) {
    set<int> s= *m_schedule->getAssignedProcessors(*p); // copy 
    set<int>::iterator i;
    for (i = s.begin(); i != s.end(); i++) {
      if (!m_schedule->isAssignedTo(task,proc)) {
	m_cstream << TAB << "/* Recv from Task " << getTaskID(*p,m_tg) << "*/" 
		  << endl;
	generateRecvCommand(*p,task,proc,*i);
      }
    }
  }  
}


void Codegen::generateSendData(VertexID task, int proc)
{
  ChildrenIterator c,c_end;
  for (tie(c,c_end) = children(task,*m_merged_tg); c != c_end; c++) {
    set<int> s= *m_schedule->getAssignedProcessors(*c); // copy 
    set<int>::iterator i;
    for (i = s.begin(); i != s.end(); i++) {
      if (!m_schedule->isAssignedTo(task,proc)) {
	m_cstream << TAB << "/* Send to Task " << getTaskID(*c,m_tg) << "*/" << endl;
	generateSendCommand(task,*c,proc,*i);
      }
    }
  }    
}

void Codegen::generateSendCommand(VertexID source,
						     VertexID target,
						     int sourceproc,
						     int targetproc)
{
  EdgeID e; bool found;
  tie(e,found) = edge(source,target,*m_merged_tg);
  assert(found);

  ResultSet &res=getResultSet(e,m_merged_tg);  

  ResultSet::iterator vname; int i;
  for( vname= res.begin(), i=0; vname != res.end(); vname++,i++) {
    m_cstream << TAB << "sendbuf" << sourceproc << "[" << i << "]=" 
	      << *vname << ";" << endl;
  }  
  m_cstream << TAB << "MSEND(sendbuf" << sourceproc << "," 
	    << res.size() << "," << "MPI_REAL," << targetproc << "," 
	    << getTaskID(source,m_merged_tg) << ");" << endl;    
}

void Codegen::generateRecvCommand(VertexID source,
						     VertexID target,
						     int sourceproc,
						     int targetproc)
{
  EdgeID e; bool found;
  tie(e,found) = edge(source,target,*m_merged_tg);
  assert(found);
  
  ResultSet &res=getResultSet(e,m_merged_tg); 
 
  m_cstream << TAB << "MRECV(recvbuf" << sourceproc << "," 
	    << res.size() << "," << "MPI_REAL," << targetproc << "," 
	    << getTaskID(source,m_merged_tg) << ");" << endl;  

  ResultSet::iterator vname; int i;
  for( vname= res.begin(), i=0; vname != res.end(); vname++,i++) {
    m_cstream << TAB <<*vname << "=recvbuf" << sourceproc << "[" << i << "];" 
	      << endl;
  }  
}

void Codegen::generateTaskCode(VertexID task, 
						  map<VertexID,double>& levelMap)
{
  ContainSetMap::iterator taskmap;
  VertexID gentask;
  taskmap = m_cmap->find(task);
  if (taskmap == m_cmap->end()) {
    // No taskset => a node without subtasks.
    gentask= find_task(getTaskID(task,m_merged_tg),m_tg);
    generateSubTaskCode(gentask);
      
  } else {
    ContainSet::iterator t;
    
    InvQueue tasks(InvLevelCmp(m_tg,&levelMap));
    // Store internal tasks in a levelsorted queue to be able to generate 
    // code in correct order.
    m_cstream << TAB << TAB << "/* Task " << getTaskID(task,m_merged_tg) 
	      << " contains: ";
    for (t=(taskmap->second)->begin(); t != (taskmap->second)->end(); t++) {
      tasks.push(find_task(*t,m_tg));
      m_cstream << *t << " ";
    }
    m_cstream << "*/" << endl;
    while (!tasks.empty()) {
      gentask = tasks.top(); tasks.pop();
      generateSubTaskCode(gentask);
    }
  }
}

int Codegen::getParentSize(VertexID task, TaskGraph *tg)
{
  InEdgeIterator e,e_end;
  int size;
  for (tie(e,e_end) = in_edges(task,*tg),size=0; e != e_end; e++) {
    int resSize = getResultSet(*e,tg).size();
    size += resSize == 0 ? 1 : resSize;
  }
  return size;
}

void Codegen::generateSubTaskCode(VertexID task)
{
  InEdgeIterator e,e_end;
  int i;
  int parentSize = getParentSize(task,m_tg);
  vector<string> parentnames(parentSize);
  for (i=0,tie(e,e_end) = in_edges(task,*m_tg); e != e_end; e++) {
    ResultSet &s = getResultSet(*e,m_tg);
    // empty resultset, use Resultname instead.
    if (s.size() == 0) {
      parentnames[i++]=getResultName(source(*e,*m_tg),m_tg);
    } else {
      for (ResultSet::iterator j=s.begin(); j != s.end(); j++) {
	parentnames[i++]= *j;
      }
    }
  }
  switch(getTaskType(task,m_tg)) {
  case TempVar: 
    m_cstream << TAB << getResultName(task,m_tg) << "=" 
	      << insert_strings(getVertexName(task,m_tg),parentnames) 
	      << TAB << "// Task " << getTaskID(task,m_tg) << endl;
    break;
  case Begin:
    m_cstream << "        /* Begin */" << endl;
    break;
  case End:
    m_cstream << "        /* End */" << endl;
    break;
  case Assignment:
    m_cstream << TAB << insert_strings(getVertexName(task,m_tg),parentnames) 
	      << TAB << "// Task " << getTaskID(task,m_tg) << endl;    
    break;
  case LinSys:
    m_cstream << TAB << "/* Linear system*/" << endl;
    break;
  case NonLinSys:
    m_cstream << TAB << "/* NonLinear system*/" << endl;
    break;
  default:
    assert(false);    
  };
}

void Codegen::generateParallelFunctionHeader(int procno) 
{
  m_cstreamFunc << "void proc" << procno << "(";
  generateParallelFunctionArgument(procno,m_cstreamFunc);
  m_cstreamFunc << ");" << endl;
}

void Codegen::generateParallelFunctionPrologue(int procno) 
{
  m_cstream << "void proc" << procno << "(";
  generateParallelFunctionArgument(procno,m_cstream);
  m_cstream << ")" << endl;
  m_cstream << "{";
  
}

void Codegen::generateParallelFunctionArgument(int procno, ofstream &os)
{
  os << "time";
}

void Codegen::generateParallelFunctionEpilogue(int procno) 
{
  m_cstream << "}" << endl << endl;
  
}

void Codegen::generateParallelCalls()
{
  m_cstream << TAB << "switch (rank) {" << endl;
  m_cstream << TAB << "    case 0 : solver(x,xd,y,p,nx,ny,np,start,stop,step,&f);" << endl;
  m_cstream << TAB << TAB << "break;" << endl;
  for (int i = 1 ; i < m_nproc; i++) {
    m_cstream << TAB << "    case " << i << ": proc" << i << "(time);" << endl
	      << TAB << TAB << "break;" << endl;
  }
  m_cstream << TAB << "}" << endl << endl; 
}
 

void Codegen::generateDynamic()
{
  m_cstream << "void f(double *x,double *xd, double *y, double *p, " << endl
	    << "int nx, int ny, int np,double time)" << endl;
  m_cstream << "{" << endl;
  m_cstream << TAB << "proc0(x,xd,y,p,nx,ny,np,time);" << endl;
  m_cstream << "}" << endl<<endl;
}

void Codegen::initialize(TaskGraph* tg, TaskGraph* m_merged_tg,
			 Schedule* sched, ContainSetMap *cmap,
			 int nproc,
			 int nx,
			 int ny,
			 int np)
{
  m_tg = tg;
  m_merged_tg = m_merged_tg;
  m_schedule = sched;
  m_cmap = cmap;
  m_nproc = nproc;
  m_nx = nx;
  m_ny = ny;
  m_np = np;
}


void  Codegen::generateParallelMPIHeaders()
{

  m_cstreamFunc << "#define MSEND(buf,count,type,proc,tag) "
		<< "MPI_Send(buf,count,type,proc,tag,MPI_COMM_WORLD)" << endl;
  
  m_cstreamFunc << "#define MRECV(buf,count,type,proc,tag) " 
		<< "MPI_Recv(buf,count,type,proc,tag,MPI_COMM_WORLD,&status)" 
		<< endl;
  m_cstreamFunc << "#define BARRIER MPI_Barrier(MPI_COMM_WORLD)" << endl;

}

void  Codegen::generateParallelMPIGlobals()
{
  m_cstreamFunc  << "/* Declaration of MPI Global variables */" << endl;
  m_cstreamFunc  << "extern MPI_Status status;" << endl;
  m_cstreamFunc  << "extern MPI_Request request;" << endl;
  m_cstreamFunc  << "extern int rank;" << endl;

  m_cstream << "/* MPI Global variables */" << endl;
  m_cstream << "MPI_Status status;" << endl;
  m_cstream << "MPI_Request request;" << endl;
  m_cstream << "int rank;" << endl;

}

void Codegen::generateGlobals()
{
  int numsteps = 1000;
  m_cstream << "#include \"" << m_fileNameFunc << "\"" << endl << endl;
  m_cstream << "#include \"solvers.hpp\"" << endl;
  
  m_cstream << "/* Global variables */" << endl;
  m_cstream << "const int nx = " << m_nx << ";" << endl;
  m_cstream << "const int ny = " << m_ny << ";" << endl;
  m_cstream << "const int np = " << m_np << ";" << endl;
  m_cstream << "const int numsteps = " << numsteps << ";" << endl; 
  m_cstream << "double x[nx]; /* State vector */" << endl;
  m_cstream << "double xd[nx]; /* State derivative vector */" << endl;
  m_cstream << "double y[ny]; /* alg var vector */" << endl;
  m_cstream << "double p[np]; /* parameter vector */" << endl << endl;
  m_cstream << "double res[(nx+nx+ny+1)*numsteps]; /* Result */" << endl;

  m_cstream << "void (*solver)(double*, double*, double*, double*,double*,int,int,int, int, double,double,double,void (*)(double)) = &euler;" << endl;

  // put MPI globals
  generateParallelMPIGlobals();
}
  
void Codegen::generateCode()
{
  
  // put MPI defines
  generateParallelMPIHeaders();

  generateGlobals();
  
  generateMain();  

  generateDynamic();

  //Traverse taskgraph and generate code, one function per processor
  generateParallelFunctions();  
}

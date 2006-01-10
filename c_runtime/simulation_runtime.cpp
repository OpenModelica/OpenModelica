/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with OpenModelica; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

//#include <iostream>
#include <string>
#include <limits>
#include <list>
#include <math.h>
#include "simulation_runtime.h"
#include "options.h"

using namespace std;

static long current_pos;
static double* data;

static list<long> EventQueue;

long numpoints; // the number of points allocated for in data array
long actual_points=0; // the number of actual points saved
double t;

double* h_saved;
double* x_saved;
double* xd_saved;
double* y_saved;
double* gout;
long* zeroCrossingEnabled;

// dummy Jacobian
int dummyJacobianDASSL(double *t, double *y, double *yprime, double *pd, long *cj, double *rpar, long* ipar){
  return 0;
  //provides a dummy Jacobian to be used with DASSL
}


inline void dumpresult(double t, double y, long idid, double* rwork, long* iwork)
{
  int i;
  cout << t << "\t" << y << "\t" << idid;
  for (i=0;i<20; i++)
    cout << "\t" << iwork[i];
  for (i=0;i<20; i++)
    cout << "\t" << rwork[i];
  cout << endl;
}

// relation functions used in zero crossing detection
double Less(double a, double b) 
{
  return a-b;
}

double LessEq(double a, double b) 
{
  return a-b;
}

double Greater(double a, double b) 
{
  return b-a;
}

double GreaterEq(double a, double b) 
{
  return b-a;
}

double Sample(double t, double start ,double interval)
{
  double pipi = atan(1.0)*8.0;
  if (t<(start-interval*.25)) return -1.0;
  return sin(pipi*(t-start)/interval);
}

double sample(double start ,double interval)
{
  double sloop = 4.0/interval;
  int count = int((t - start) / interval);
  if (t < (start-interval*0.25)) return 0;
  if (( t-start-count*interval) < 0) return 0;
  if (( t-start-count*interval) > interval*0.5) return 0;
  return 1;
}

static int maxpoints;

inline double * initialize_simdata(long numpoints,long nx, long ny)
{
  maxpoints = numpoints;
  
  double *data = new double[numpoints*(nx*2+ny+1)];
  if (!data) {
    cerr << "Error allocating data of size " << numpoints *(nx*2+ny)
	      << endl;
    exit(-1);
  }
  current_pos = 0;
  return data;
}

inline double newTime(double t, double step)
{
  return (floor( (t+1e-10) / step) + 1.0)*step;
}

inline void calcEnabledZeroCrossings()
{
  int i;
  for (i=0;i<ng;i++) {
    zeroCrossingEnabled[i] = 1;
  }
  function_zeroCrossing(&nx,&t,x,&ng,gout,0,0);
  for (i=0;i<ng;i++) {
    if (gout[i] > 0)
      zeroCrossingEnabled[i] = 1;
    else if (gout[i] < 0)
      zeroCrossingEnabled[i] = -1;
    else
      zeroCrossingEnabled[i] = 0;
    //    cout << "e[" << i << "]=" << zeroCrossingEnabled[i] << endl;
  }
}

void emit()
{
  if (actual_points < maxpoints)
    add_result(data,t,x,xd,y,nx,ny,&actual_points);
  else
    cout << "To many points" << endl;
}

int euler_main(int, char **);
int dassl_main(int, char **);

int main(int argc, char**argv) 
{

  /* the main method identifies which solver to use and then calls 
     respecive solver main function*/
  if (!getFlagValue("m",argc,argv)) {
    return dassl_main(argc,argv);
  } else  if (*getFlagValue("m",argc,argv) == std::string("euler")) {
    return euler_main(argc,argv);
  }
  else if (*getFlagValue("m",argc,argv) == std::string("dassl")) {
    return dassl_main(argc,argv);
  } else {
    cout << "Unrecognized solver, using dassl." << endl;
    return dassl_main(argc,argv);    
  }
      return -1;
}


/* The main function for the explicit euler solver */

int euler_main(int argc,char** argv) {
  double start = 0.0; //default value
  double stop = 5;
  double step = 0.05;
  double sim_time;

  if (argc == 2 && flagSet("?",argc,argv)) {
    cout << "usage: " << argv[0]  << " <-f initfile> <-r result file> -m solver:{dassl, euler}" << endl;
    exit(0);
  }

  read_input(argc,argv,x,xd,y,p,nx,ny,np,&start,&stop,&step);
  
  long numpoints = long((stop-start)/step)+2;
  
  // load default initial values.
  data =  initialize_simdata(numpoints,nx,ny);
  
  // Calculate initial values from (fixed) start attributes and intial equation
  // sections
  initial_function(x,xd,y,p,nx,ny,np);
  
  int npts_per_result=int((stop-start)/(step*(numpoints-2)));
  long actual_points =0 ; // the number of actual points saved
  int pt=0;
  for(sim_time=start; sim_time <= stop; sim_time+=step,pt++) {

    euler(x,xd,y,p,data,nx,ny,np,&sim_time,&step,functionODE);

    /* Calculate the output variables */
    functionDAE_output(&sim_time,x,xd,y,p);

    if (pt % npts_per_result == 0 || sim_time+step > stop) { // store result
      add_result(data,sim_time,x,xd,y,nx,ny,&actual_points);
    }
  } 


  string * result_file =(string*)getFlagValue("r",argc,argv);
  const char * result_file_cstr;
  if (!result_file) {
    result_file_cstr = string(string(model_name)+string("_res.plt")).c_str();
  } else {
    result_file_cstr = result_file->c_str();
  }
  store_result(result_file_cstr,data,actual_points,nx,ny);

  return 0;
}

void euler ( double *x, double *xd, double *y, double *p, double *data,
	     int nx, int ny, int np, double *time, double *step,
	     int (*f)(double*,// x
		       double*,// xd
		       double*,// y
		       double*,// p
		       int,int,int, //nx,ny,np
		       double *) // time
	     )
{
  f(x,xd,y,p,nx,ny,np,time); // calculate equations
  for(int i=0; i < nx; i++) {
    x[i]=x[i]+xd[i]*(*step); // Based on that, calculate state variables.
  }
}


/* The main function for the dassl solver*/
int dassl_main(int argc, char **argv) 
{
  int status;
  double start = 0.0; //default value
  double stop = 5;
  double step = 0.05;
  
  long info[15];
  status = 0;
  double tout;
  double rtol = 1.0e-5;
  double atol = 1.0e-5;
  long idid = 0;

  //double rpar = 0.0;
  long ipar = 0;
  int i;

  for(i=0; i<15; i++) 
    info[i] = 0;
  for(i=0; i<liw; i++) 
    iwork[i] = 0;
  for(i=0; i<lrw; i++) 
    rwork[i] = 0.0;
  for(i=0; i<nhelp; i++)
    h[i] = 0;
  
  if (argc == 2 && flagSet("?",argc,argv)) {
    cout << "usage: " << argv[0]  << " <-f initfile> <-r result file> -m solver:{dassl, euler}" << endl;
    exit(0);
  }

  read_input(argc,argv,x,xd,y,p,nx,ny,np,&start,&stop,&step);
  
  numpoints = long((stop-start)/step)+2;

  // load default initial values.
  gout = new double[ng];
  h_saved = new double[nhelp];  
  x_saved = new double[nx];
  xd_saved = new double[nx];
  y_saved = new double[ny];
  zeroCrossingEnabled = new long[ng];
  data =  initialize_simdata(5*numpoints,nx,ny);

  // Calculate initial values from (fixed) start attributes and intial equation
  // sections
  initial_function(x,xd,y,p,nx,ny,np);
  
  t=start;
  tout = newTime(t, step); // TODO: check time events here. Maybe dassl should not be allowed to simulate past the scheduled time event.

  function_updateDependents(&t);
  saveall();
  emit();
  calcEnabledZeroCrossings();

  DDASRT(functionDAE_res, &nx,   &t, x, xd, &tout, info,&rtol, &atol, &idid,rwork,&lrw, iwork, &liw, y, &ipar, dummyJacobianDASSL, function_zeroCrossing, &ng, jroot);
  info[0] = 1;

  functionDAE_res(&t,x,xd,dummy_delta,0,0,0); // Since residual function calculates 
					      // alg vars too.
  functionDAE_output(&t,x,xd,y,p);

  tout += step;
  while(t<stop && idid>0) {
    // TODO: check here if time event has been reached.
    while (idid == 4) {
      emit();
      saveall();
      calcEnabledZeroCrossings();
      StateEventHandler(jroot, &t);
      CheckForNewEvents(&t);
      StartEventIteration(&t);
      saveall();

      // Restart simulation
      info[0] = 0;
      if (tout-t < atol) tout = newTime(t,step);
      calcEnabledZeroCrossings();
      DDASRT(functionDAE_res, &nx,   &t, x, xd, &tout, info,&rtol, &atol, 
	     &idid,rwork,&lrw, iwork, &liw, y, &ipar, dummyJacobianDASSL, 
	     function_zeroCrossing, &ng, jroot);

      functionDAE_res(&t,x,xd,dummy_delta,0,0,0); // Since residual function calculates 
					      // alg vars too.
      functionDAE_output(&t,x,xd,y,p);

      info[0] = 1;
    }
    
    emit();
    saveall();
    tout = newTime(t,step); // TODO: check time events here. Maybe dassl should not be allowed to simulate past the scheduled time event.
    calcEnabledZeroCrossings();
    DDASRT(functionDAE_res, &nx, &t, x, xd, &tout, info,&rtol, &atol, &idid,rwork,&lrw, iwork, &liw, y, &ipar, dummyJacobianDASSL, function_zeroCrossing, &ng, jroot);
    functionDAE_res(&t,x,xd,dummy_delta,0,0,0); // Since residual function calculates 
					      // alg vars too.
    functionDAE_output(&t,x,xd,y,p);  // descrete variables should probably be seperated so that the can be emited before and after the event.    
  }  
  emit();
  if (idid < 0 ) {
    cerr << "Error, simulation stopped at time: " << t << endl;
    cerr << "Result written to file." << endl;
	status = 1;
  }

  delete [] h_saved;
  delete [] x_saved;
  delete [] xd_saved;
  delete [] y_saved;
  delete [] gout;
  delete [] zeroCrossingEnabled;

  string * result_file =(string*)getFlagValue("r",argc,argv);
  const char * result_file_cstr;
  if (!result_file) {
    result_file_cstr = string(string(model_name)+string("_res.plt")).c_str();
  } else {
    result_file_cstr = result_file->c_str();
  }
  store_result(result_file_cstr,data,actual_points,nx,ny);

  return status;
}

void saveall()
{
  int i;
  for(i=0;i<nx; i++) {
    x_saved[i] = x[i];
    xd_saved[i] = xd[i];
  }
  for(i=0;i<ny; i++) {
    y_saved[i] = y[i];
  }
  for(i=0;i<nhelp; i++) {
    h_saved[i] = h[i];
  }
}





void save(double & var) 
{
  double* pvar = &var;
  long ind;


  ind = long(pvar - h);
  if (ind >= 0 && ind < nhelp) {
    h_saved[ind] = var;
    return;
  }
  ind = long(pvar - x);
  if (ind >= 0 && ind < nx) {
    x_saved[ind] = var;
    return;
  }
  ind = long(pvar - xd);
  if (ind >= 0 && ind < nx) {    
    xd_saved[ind] = var;
    return;
  }
  ind = long(pvar - y);
  if (ind >= 0 && ind < ny) {
    y_saved[ind] = var;
    return;
  }
  return;
}

double pre(double & var) 
{
  double* pvar = &var;
  long ind;

  ind = long(pvar - x);
  if (ind >= 0 && ind < nx) {
    return x_saved[ind];
  }
  ind = long(pvar - xd);
  if (ind >= 0 && ind < nx) {    
    return xd_saved[ind];
  }
  ind = long(pvar - y);
  if (ind >= 0 && ind < ny) {
    return y_saved[ind];
  }
  ind = long(pvar - h);
  return h_saved[ind];
}

bool edge(double& var) 
{
  return var && ! pre(var);
}

/* store_result
* stores the result of all variables for all timesteps on a file
* suitable for plotting, etc.
*/

void store_result(const char * filename, double*data,long numpoints, 
                  long nx, long ny)
{
  ofstream f(filename);
  if (!f)
  {
    cerr << "Error, couldn't create output file " << filename << endl;
    exit(-1);
  }

  // Rather ugly numbers than unneccessary rounding.
  f.precision(numeric_limits<double>::digits10 + 1);
  f << "#Ptolemy Plot file, generated by OpenModelica" << endl;
  f << "#IntervalSize=" << numpoints << endl;
  f << "TitleText: OpenModelica simulation plot" << endl;
  f << "XLabel: t" << endl << endl;



  int num_vars = 1+nx*2+ny;
  
  // time variable.
  f << "DataSet: time"  << endl;
  for(int i = 0; i < numpoints; ++i)
    f << data[i*num_vars] << ", " << data[i*num_vars]<< endl;
  f << endl;

  for(int var = 0; var < nx; ++var)
  {
    f << "DataSet: " << varnames[var] << endl;
    for(int i = 0; i < numpoints; ++i)
      f << data[i*num_vars] << ", " << data[i*num_vars + 1+var] << endl;
    f << endl;
  }
  
  for(int var = 0; var < nx; ++var)
  {
    f << "DataSet: " << varnames[var+nx] << endl;
    for(int i = 0; i < numpoints; ++i)
      f << data[i*num_vars] << ", " << data[i*num_vars + 1+nx+var] << endl;
    f << endl;
  }
  
  for(int var = 0; var < ny; ++var)
  {
    f << "DataSet: " << varnames[var+2*nx] << endl;
    for(int i = 0; i < numpoints; ++i)
      f << data[i*num_vars] << ", " << data[i*num_vars + 1+2*nx+var] << endl;
    f << endl;
  }

  f.close();
  if (!f)
  {
    cerr << "Error, couldn't write to output file " << filename << endl;
    exit(-1);
  }
}

/* add_result
 * add the values of one step for all variables to the data
 * array to be able to later store this on file.
 */

void add_result(double *data, double time,double *x, double *xd, double *y,
		long nx, long ny, long *actual_points)
{
  //save time first
  //cerr << "adding result for time: " << time;
  //cerr.flush();
  data[current_pos++] = time;
  // .. then states..
  for (int i = 0; i < nx; i++, current_pos++) {
    data[current_pos] = x[i];
  }
  // ..followed by derivatives..
  for (int i = 0; i < nx; i++, current_pos++) {
    data[current_pos] = xd[i];
  }
  // .. and last alg. vars.
  for (int i = 0; i < ny; i++, current_pos++) {
    data[current_pos] = y[i];
  }
  //cerr << "  ... done" << endl;
  (*actual_points)++;
}

  /* read_input
     Reads initial values from a text file.
     The textfile should be given as argument to the main function using 
     the -f file flag.
  */
  void read_input(int argc, char **argv,
		  double* x,double*xd,double*y,
		  double *p, int nx,int ny, int np,
		  double *start, double *stop,
		double *step)
{

  string *filename=(string*)getFlagValue("f",argc,argv);
  if (filename == NULL) { 
    filename = new string(string(model_name)+"_init.txt");  // model_name defined in generated code for model.
  }

  ifstream file(filename->c_str());
  if (!file) { 
    cerr << "Error, can not read file " << filename 
	 << " as indata to simulation." << endl; 
    exit(-1);
  }
  //  cerr << "opened file" << endl;
  read_commented_value(file,start);
  read_commented_value(file,stop);
  read_commented_value(file,step);
  int nxchk,nychk,npchk;
  read_commented_value(file,&nxchk);
  read_commented_value(file,&nychk);
  read_commented_value(file,&npchk);
  if (nxchk != nx || nychk != ny || npchk != np) {
    cerr << "Error, input data file does not match model." << endl;
    cerr << "nx from file: "<<nxchk<<endl;
    cerr << "ny from file: "<<nychk<<endl;
    cerr << "np from file: "<<npchk<<endl;
    exit(-1);
  }
  for(int i = 0; i < nx; i++) { // Read x initial values
    read_commented_value(file,&x[i]);
  }
 for(int i = 0; i < nx; i++) { // Read der(x) initial values
    read_commented_value(file,&xd[i]);
  }
 for(int i = 0; i < ny; i++) { // Read y initial values
    read_commented_value(file,&y[i]);
  }
 for(int i = 0; i < np; i++) { // Read parameter values
    read_commented_value(file,&p[i]);
  }
 file.close();
}


inline void read_commented_value( ifstream &f, double *res)
{
  string line;
//  f >> *res;   
  char c[160];
  f.getline(c,160);
  line = c;

  if (line.find("true") != line.npos) {
	  *res = 1.0;
  }
  else if (line.find("false") != line.npos) {
	  *res = 0.0;
  }
  else {
    *res = atof(c);
  }
}

inline void read_commented_value( ifstream &f, int *res)
{
  f >> *res; 
  char c[160];
  f.getline(c,160);
}


void StateEventHandler(long* jroot, double *t) 
{
  for(int i=0;i<ng;i++) {
    if (jroot[i] ) {
      handleZeroCrossing(i,t);
      function_updateDependents(t);
    }
  }
  emit();
}

int
checkForDiscreteVarChanges(double *t);
void AddEvent(long);

void CheckForNewEvents(double *t)
{
  // Check for changes in discrete variables
  checkForDiscreteVarChanges(t);

  function_zeroCrossing(&nx,t,x,&ng,gout,0,0);
  for (long i=0;i<ng;i++) {
    if (gout[i] < 0) {
       AddEvent(i);
    }
  }
}

void AddEvent(long index)
{
  list<long>::iterator i;
  for (i=EventQueue.begin(); i != EventQueue.end(); i++) {
    if (*i == index)
      return;
  }
  EventQueue.push_back(index);
  //  cout << "Adding Event:" << index << " queue length:" << EventQueue.size() << endl;
}

bool
ExecuteNextEvent(double *t)
{
  if (EventQueue.begin() != EventQueue.end()) {
    long nextEvent = EventQueue.front();
    //    calcEnabledZeroCrossings();
    if (nextEvent >= ng) {
      function_when(nextEvent-ng, t);
    }
    else {
      handleZeroCrossing(nextEvent, t);
      function_updateDependents(t);
    }
    //    CheckForNewEvents(t);
    emit();
    EventQueue.pop_front();
    return true;
  }
  return false;
}

void
StartEventIteration(double *t)
{
  while (EventQueue.begin() != EventQueue.end()) {
    calcEnabledZeroCrossings();
    while (ExecuteNextEvent(t)) {}
    for (unsigned int i = 0; i < nhelp; i++) save(h[i]);
    function_updateDependents(t);
    CheckForNewEvents(t);
  }
  //  cout << "EventIteration done" << endl;
}



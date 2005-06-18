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

#include <iostream>
#include <string>
#include <limits>
#include "simulation_runtime.h"
#include "options.h"

using namespace std;

// dummy zeroCrossing
int zeroCrossing(long *neqm, double *t, double *y, long *ng, double *gout, double *rpar, long* ipar){
  //Parameter adjustments
  double time = *t;
  --y;
  --gout;
  return 0;
}

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

inline double * initialize_simdata(long numpoints,long nx, long ny)
{
  
  double *data = new double[numpoints*(nx*2+ny+1)];
  if (!data) {
    cerr << "Error allocating data of size " << numpoints *(nx*2+ny)
	      << endl;
    exit(-1);
  }
  return data;
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

  double *data =  initialize_simdata(numpoints,nx,ny);

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
	     void (*f)(double*,// x
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
  long ng = 0;
  double t;
  double tout;
  double rtol = 1.0e-5;
  double atol = 1.0e-5;
  long idid = 0;

  //double rpar = 0.0;
  long ipar = 0;
  long jroot;
  int i;
  long numpoints; // the number of points allocated for in data array
  long actual_points=0; // the number of actual points saved
  

  for(i=0; i<15; i++) 
    info[i] = 0;
  for(i=0; i<liw; i++) 
    iwork[i] = 0;
  for(i=0; i<lrw; i++) 
    rwork[i] = 0.0;
  
  if (argc == 2 && flagSet("?",argc,argv)) {
    cout << "usage: " << argv[0]  << " <-f initfile> <-r result file> -m solver:{dassl, euler}" << endl;
    exit(0);
  }

  read_input(argc,argv,x,xd,y,p,nx,ny,np,&start,&stop,&step);
  
  numpoints = long((stop-start)/step)+2;

  double *data =  initialize_simdata(numpoints,nx,ny);
  
  t=start;
  tout = t+step;
  DDASRT(functionDAE_res, &nx,   &t, x, xd, &tout, info,&rtol, &atol, &idid,rwork,&lrw, iwork, &liw, y /* rpar */, &ipar, dummyJacobianDASSL, zeroCrossing, &ng, &jroot);
  functionDAE_res(&t,x,xd,dummy_delta,0,0,0); // Since residual function calculates 
					      // alg vars too.
  functionDAE_output(&t,x,xd,y,p);
  add_result(data,t,x,xd,y,nx,ny,&actual_points);
  info[0] = 1;
  //dumpresult(t,y,idid,rwork,iwork);
  tout += step;
  while(t<stop && idid>0) {
    DDASRT(functionDAE_res, &nx, &t, x, xd, &tout, info,&rtol, &atol, &idid,rwork,&lrw, iwork, &liw, y /*rpar */, &ipar, dummyJacobianDASSL, zeroCrossing, &ng, &jroot);
    functionDAE_res(&t,x,xd,dummy_delta,0,0,0); // Since residual function calculates 
					      // alg vars too.
    functionDAE_output(&t,x,xd,y,p);
    add_result(data,t,x,xd,y,nx,ny,&actual_points);
    //dumpresult(t,y,idid,rwork,iwork);
    tout += step;
  }  
  if (idid < 0 ) {
    cerr << "Error, simulation stopped at time: " << t << endl;
    cerr << "Result written to file." << endl;
	status = 1;
  }
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

/* store_result
* stores the result of all variables for all timesteps on a file
* suitable for plotting, etc.
*/

void store_result(const char * filename, double*data,long numpoints, long nx, long ny)
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
  static long current_pos = 0;
  
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


/* Implementation of numerical differential solvers for OpenModelica
   Copyright Peter Aronsson, Programming Environments laboratory
   Linköping University, Sweden
*/

/* Euler:
   discretization scheme:
   xn[n+1]=x[n]+f(x[n],y[t],t)*h
*/
#include "options.h"
#include "solvers.hpp"
#include <fstream>
#include <iostream>

using namespace std;


double sim_time;

void euler ( double *x, double *xd, double *y, double *p, double *res,
	     int nx, int ny, int np,
	     int numpoints,
	     double start,
	     double stop,
	     double step, void (*f)(double*,// x
			       double*,// xd
			       double*,// y
			       double*,// p
			       int,int,int, //nx,ny,np
			       double) // time
	     )
{

  int npts_per_result=int((stop-start)/(step*(numpoints-2)));
  //  cerr << "number of gridpoints per stored result: " << npts_per_result << endl;
  int j=0;
  int pt=0;
  for(sim_time=start; sim_time <= stop; sim_time+=step,pt++) {
    if (pt % npts_per_result == 0 || sim_time+step > stop) { // store result
      for (int i=0; i< nx; i++) {
	res[j++] = x[i];
	//cerr << "time=" << sim_time<< "  x["<<i<<"]="<<x[i]<< endl;
      }
      for (int i=0; i< nx; i++) {
	res[j++] = xd[i];
	//cerr << "time=" << sim_time<< "  xd["<<i<<"]="<<xd[i]<< endl;
      }
      for (int i=0; i< ny; i++) {
	res[j++] = y[i];
      }
      res[j++] = sim_time; //store time last.
      //      cerr << "storing result for time " << sim_time << " indx :" << j << endl;
    } 
    f(x,xd,y,p,nx,ny,np,sim_time); // calculate equations
    for(int i=0; i < nx; i++) {
      x[i]=x[i]+xd[i]*step; // Based on that, calculate state variables.
    }
  }
  write_result_txt("res.txt",nx,ny,numpoints,res);
}


inline void read_commented_value( ifstream &f, double *res);
inline void read_commented_value( ifstream &f, int *res);

void read_input(int argc, char **argv,
		double* x,double*xd,double*y,
		double *p, int nx,int ny, int np,
		double *start, double *stop,
		double *step)
{

  string *filename=(string*)getFlagValue("f",argc,argv);
  if (filename == NULL) { filename = new string("indata.txt"); }

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
  f >> *res;   
  char c[160];
  f.getline(c,160);
}

inline void read_commented_value( ifstream &f, int *res)
{
  f >> *res; 
  char c[160];
  f.getline(c,160);
}


/* Write the result of a simulation to a text file on a format suitable for reading into Mathematica.
   The data is stored as 
   { v1,v2,v3,...,vn} where each v is a vector.
*/

void write_result_txt(char *filename, int nx, int ny, int numpts,double *data)
{

  ofstream file(filename);
  file.setf(ios_base::fixed,ios_base::floatfield);
  file.precision(16);
  if (!file) { 
    cerr << "Error, can not write to file " << filename << endl;
    exit(-1);
  }
  file << "{" << endl;
  int numvars = nx*2+ny+1;
  for (int i =0; i < nx*2+ny+1; i++) {
    file << "{";
    for (int t=0; t < numpts; t++ ) {
      file << data[numvars*t+i];
      if (t != numpts-1) file << ", ";
    }
    if (i != nx*2+ny) { 
      file  << "}," << endl; 
    } else {
      file << "}" << endl;
    }
  }
  file << "}" << endl;
  file.close();
}

/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "simulation_init.h"
#include "simulation_runtime.h"
#include <math.h>

/* This function calculates the residual value as the sum of squared residual equations.
 */

void leastSquare(long *nz, double *z, double *funcValue)
{
  int ind, indAct, indz;
  for (ind=0, indAct=0, indz=0; ind<globalData->nStates; ind++)
  	if (globalData->initFixed[indAct++]==0)
          globalData->states[ind] = z[indz++];

  for (ind=0,indAct=2*globalData->nStates+globalData->nAlgebraic; ind<globalData->nParameters; ind++)
    if (globalData->initFixed[indAct++]==0)
      globalData->parameters[ind] = z[indz++];

  functionODE();
  functionDAE_output();
  functionDAE_output2();
/*  for (ind=0,indy=0,indAct=2*globalData->nStates; ind<globalData->nAlgebraic; ind++)
    if (globalData->initFixed[indAct++]==1)
      globalData->algebraics [ind] = static_y[indy++];
      
      Comment from Bernhard: Even though algebraic variables are "fixed", they are calculated from 
      the states, so they should be allowed to change when states vary, 
      and NOT be replaced by their initial values as above.
*/
  initial_residual();  

  for (ind=0, *funcValue=0; ind<globalData->nInitialResiduals; ind++)
    *funcValue += globalData->initialResiduals[ind]*globalData->initialResiduals[ind];	
    
  if (sim_verbose) {
  	cout << "initial residual: " << *funcValue << endl;
  }
}

/** function reportResidualValue
 **
 ** Returns -1 if residual is non-zero and prints appropriate error message.
 **/

int reportResidualValue(double funcValue)
{
	int i;
  if (funcValue > 1e-5) {
    std::cerr << "Error in initialization. System of initial equations are not consistent." << std::endl;
    std::cerr << "(Least Square function value is " << funcValue << ")" << std::endl;
    for (i=0; i<globalData->nInitialResiduals; i++) {
    	if (fabs(globalData->initialResiduals[i]) > 1e-6) {
    		cout << "residual[" << i << "] = " << globalData->initialResiduals[i] << endl;
    	}
    }
    return 0 /*-1*/;
  }
  return 0;
}

/** function: newuoa_initialization
 ** 
 ** This function performs initialization using the newuoa function, which is 
 ** a trust region method that forms quadratic models by interpolation.
 **/

int newuoa_initialization(long& nz,double *z)
{
  long IPRINT = sim_verbose? 2 : 0;
  long MAXFUN=50000;
  double RHOEND=1.0e-6;
  double RHOBEG=10; // This should be about one tenth of the greatest
		    // expected value of a variable. Perhaps the nominal 
		    // value can be used for this.
  long NPT = 2*nz+1;
  double *W = new double[(NPT+13)*(NPT+nz)+3*nz*(nz+3)/2];
  NEWUOA(&nz,&NPT,z,&RHOBEG,&RHOEND,&IPRINT,&MAXFUN,W,leastSquare);

  // Calculate the residual to verify that equations are consistent.
  double funcValue;
  leastSquare(&nz,z,&funcValue);
  delete [] W;
  return reportResidualValue(funcValue);
}

/** function: simplex_initialization.
 **
 ** This function performs initialization by using the simplex algorithm.
 ** This does not require a jacobian for the residuals.
 **/

int simplex_initialization(long& nz,double *z)
{
  int ind;
  double funcValue;
  double *STEP=(double*) malloc(nz*sizeof(double));
  double *VAR=(double*) malloc(nz*sizeof(double));

  /* Start with stepping .5 in each direction. */
  for (ind=0;ind<nz;ind++)
    STEP[ind]=.5;
    
   double STOPCR,SIMP;
   long IPRINT, NLOOP,IQUAD,IFAULT,MAXF;
//C  Set max. no. of function evaluations = 5000, print every 100.
 
      MAXF = 50000;
      IPRINT = sim_verbose? 100 : -1;
 
//C  Set value for stopping criterion.   Stopping occurs when the
//C  standard deviation of the values of the objective function at
//C  the points of the current simplex < stopcr.
 
      STOPCR = 1.e-3;
      NLOOP = 6000;//2*nz;
 
//C  Fit a quadratic surface to be sure a minimum has been found.
 
      IQUAD = 0;
 
//C  As function value is being evaluated in DOUBLE PRECISION, it
//C  should be accurate to about 15 decimals.   If we set simp = 1.d-6,
//C  we should get about 9 dec. digits accuracy in fitting the surface.
 
      SIMP = 1.e-6;
//C  Now call NELMEAD to do the work.
  NELMEAD(z,STEP,&nz,&funcValue,&MAXF,&IPRINT,&STOPCR,
           &NLOOP,&IQUAD,&SIMP,VAR,leastSquare,&IFAULT);
  if (IFAULT == 1) { 
    printf("Error in initialization. Solver iterated %d times without finding a solution\n",(int)MAXF);
    return -1;
  } else if(IFAULT == 2 ) {
    printf("Error in initialization. Inconsistent initial conditions.\n");
    return -1;
  } else if (IFAULT == 3) {
    printf("Error in initialization. Number of initial values to calculate < 1\n");
    return -1;
  } else if (IFAULT == 4) {
    printf("Error in initialization. Internal error, NLOOP < 1.\n");
    return -1;
  }
  return reportResidualValue(funcValue);
}

/* function: initialize
 *
 * Perform initialization of the problem. It reads the global variable
 * globalData->initFixed to find out which variables are fixed.
 * It uses the generated function initial_residual, which calcualtes the 
 * residual of all equations (both continuous time eqns and initial eqns).
 */

int initialize(const std::string*method)
{
  long nz;
  int ind, indAct, indz;
  std::string init_method;

  if (method == NULL) { 
   // init_method = std::string("newuoa");
    init_method = std::string("simplex");
  } else {
    init_method = *method;
  }

  for (ind=0, nz=0; ind<globalData->nStates; ind++){
    if (globalData->initFixed[ind]==0)
      nz++;
  }
  for (ind=2*globalData->nStates+globalData->nAlgebraic; 
       ind<2*globalData->nStates+globalData->nAlgebraic+globalData->nParameters; ind++){
    if (globalData->initFixed[ind]==0)
      nz++;
  }
	
	if (sim_verbose) {
		cout << "fixed attribute for states:" << endl;
		for(int i=0;i<globalData->nStates; i++) {
			cout <<	getName(&globalData->states[i]) << "(fixed=" << (globalData->initFixed[i]?"true":"false") << ")"
			<< endl; 
		}
		cout << "number of non-fixed variables: " << nz << endl;		
	}

  // No initial values to calculate.
  if (nz ==  0) {
  	if (sim_verbose) {
  		cout << "No initial values to calculate" << endl;
  	}
    return 0;
  } 

  double *z= new double[nz];
  if(z == NULL) {return -1;}
  /* Fill z with the non-fixed variables from x and p*/
  for (ind=0, indAct=0, indz=0; ind<globalData->nStates; ind++)
    {
      if (globalData->initFixed[indAct++]==0)
	{
	  z[indz++] = globalData->states[ind];
	}
  }
  for (ind=0,indAct=2*globalData->nStates+globalData->nAlgebraic; ind<globalData->nParameters; ind++) {
    if (globalData->initFixed[indAct++]==0)
      z[indz++] =  globalData->parameters[ind];
  }
  
  int retVal=0;
  if (init_method == std::string("simplex")) {
    retVal = simplex_initialization(nz,z);
  } else if (init_method == std::string("newuoa")) { // Better name ?
    retVal = newuoa_initialization(nz,z);
  } else {
    std::cerr << "unrecognized option -im " << init_method << std::endl;
    std::cerr << "current options are: simplex or newuoa" << std::endl;
    retVal= -1;
  }
  delete [] z;
  return retVal;
}


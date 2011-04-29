#pragma once
#define BOOST_EXTENSION_SOLVER_DECL BOOST_EXTENSION_IMPORT_DECL

#include "Solver/Implementation/SolverDefaultImplementation.h"

class IEulerSettings;

/*****************************************************************************/
/**

Euler method for the solution of a non-stiff initial value problem of a system 
of ordinary differantial equations of the form 

z' = f(t,z). 

Dense output may be used. Zero crossing are detected by bisection or linear
interpolation.

\date     01.09.2008
\author   


*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class  Euler : public IDAESolver, public SolverDefaultImplementation
{
public:
	 Euler(IDAESystem* system, ISolverSettings* settings);
  	 virtual ~Euler();

	/// Set start time for numerical solution
	virtual void setStartTime(const double& t);

	/// Set end time for numerical solution
	virtual void setEndTime(const double& t);

	/// Set the initial step size (needed for reinitialization after external zero search)
	 virtual void setInitStepSize(const double& h);

	/// (Re-) initialize the solver
	virtual void init();

	/// Approximation of the numerical solution in a given time interval
	virtual void solve(const SOLVERCALL command = UNDEF_CALL);

	/// Provides the status of the solver after returning
	const IDAESolver::SOLVERSTATUS getSolverStatus();

	/// Write out statistical information (statistical information of last simulation, e.g. time, number of steps, etc.)
	 virtual void writeSimulationInfo(ostream& outputStream);

	/// Indicates whether a solver error occurred during integration, returns type of error and provides error message
	 virtual const int reportErrorMessage(ostream& messageStream);


private:
	/// Solver call
	void doEulerForward(); 
    void doLinearEuler();
	/// Encapsulation of determination of right hand side
	void calcFunction(const double& t, const double* z, double* zDot);

	/// Output routine called after every sucessfull solver step (calls setZeroState() and writeToFile() in SolverDefaultImpl.) 
	void solverOutput(const int& stp, const double& t, double* z, const double& h);

	/// Output routine for dense output (Encapsulates interpolation, calls solverOutput() for output)
	void denseOutput(double* rhs); 
    
	/// Encapsulation of zero search
	void doZeroSearch(); 
    void doTimeEvents();
	/// Letzten gültigen Zustand (und entsprechenden Zeitpunkt) des Systems (als Kopie) speichern
	virtual void saveLastSuccessfullState();

	/// Letzten gültigen Zustand  (und entsprechenden Zeitpunkt) zurück ins System kopieren
	virtual void restoreLastSuccessfullState();
    /// Berechnung der Jacobimatrix
	void calcJac(double* pYhelp, double* pFhelp, const double* pF, double* T, const bool& flag);


	// Member variables
	//---------------------------------------------------------------
	IEulerSettings
		*_eulerSettings;							///< Settings for the solver

	long int
		_dimSys,									///< Temp 			- (total) Dimension of systems (=number of ODE)
		_idid;										///< Input, Output	- Status Flag

	int
		_outputStps;								///< Output			- Number of output steps

	double
		*_z,										///< Temp			- State vector
		*_zLeftBoundary,							///< Temp			- State vector at left boundary of intervall (old state vector)
		*_zRightBoundary,							///< Temp			- State vector at right boundary of intervall (new state vector)
		*_zLastSucess;								///< Temp			- State vector at last sucessfull time step (before zero crossing)

	double
		_hOutput,									///< Temp			- Ouput step size for dense output
		_hUplim,									///< Temp 			- Minimum step size
		_hLowlim;									///< Temp 			- Maximum step size

	double 
		_tOutput;									///< Temp			- Time for dense output

};

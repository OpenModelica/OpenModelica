#pragma once
/** @addtogroup solverCvode
 *
 *  @{
 */
#include "FactoryExport.h"
#include <Core/Solver/AlgLoopSolverDefaultImplementation.h>

#include "HybrjSettings.h"

#if defined(__MINGW32__) || defined(_MSC_VER) /* we have static libcminpack.a on MinGW and MSVC */
#define CMINPACK_NO_DLL
#endif

#include <minpack.h>
/*
 Hybrj solver from MINPACK: numerical library for function minimization and least-squares solutions
 see documentation: http://www.math.utah.edu/software/minpack/minpack/hybrj.html
*/

class Hybrj : public INonLinearAlgLoopSolver,  public AlgLoopSolverDefaultImplementation
{
public:

    Hybrj(INonLinSolverSettings* settings,shared_ptr<INonLinearAlgLoop> algLoop=shared_ptr<INonLinearAlgLoop>());

    virtual ~Hybrj();

    /// (Re-) initialize the solver
    virtual void initialize();


    /// Solution of a (non-)linear system of equations
    virtual void solve();
    //solve for a single instance call
    virtual void solve(shared_ptr<INonLinearAlgLoop> algLoop,bool first_solve = false);


    /// Returns the status of iteration
    virtual ITERATIONSTATUS getIterationStatus();
    virtual void stepCompleted(double time);
    virtual void restoreOldValues();
    virtual void restoreNewValues();

	virtual bool* getConditionsWorkArray();
    virtual bool* getConditions2WorkArray();
    virtual double* getVariableWorkArray();

private:
    /// Encapsulation of determination of residuals to given unknowns
    void calcFunction(const double* y, double* residual);
    void saveVars(double time);
    void extrapolateVars();
    /// Encapsulation of determination of Jacobian
    void calcJacobian(double* jac);
    static void fcn(const int *n, const double *x, double *fvec, double *fjac, const int *ldfjac, int *iflag,void* userdata);

    // Member variables
    //---------------------------------------------------------------
    INonLinSolverSettings
        *_newtonSettings;            ///< Settings for the solver

    shared_ptr<INonLinearAlgLoop> _algLoop;                    ///< Algebraic loop to be solved

    ITERATIONSTATUS
        _iterationStatus;            ///< Output        - Denotes the status of iteration



    bool
        _firstCall;                    ///< Temp        - Denotes the first call to the solver, initialize() is called

    long int* _iHelp;
    double
        *_x,                        ///< Temp        - Unknowns variables
        *_f,                        ///< Temp        - Residuals
        *_xHelp,                    ///< Temp        - Auxillary variables
        *_fHelp,                    ///< Temp        - Auxillary variables
        *_jac,                      ///< Temp        - Jacobian
        *_x0,                    //old unknown variables
        *_x1,                    //old unknown variables
        *_x2,
        *_x_restart,
        *_x_nom,                    //Nominal value of unknown variables
        *_x_ex,                 //extraplated unknown varibales
        *_x_scale,                 //current scale factor of unknown varibales
        *_x_old,
        *_x_new,
		_t0,             //old time
        _t1,            //old time
        _t2;              //old time
    bool _usescale;
    /*Hybrj MinPack variables */

    double*  _diag;                        ///DIAG is an array of length N.  If MODE = 1 (see below), DIAG is internally set.  If MODE = 2, DIAG must contain positive  entries that serve as multiplicative scale factors for the variables.
    double* _r;                              ///R is an output array of length LR which contains the upper  triangular matrix produced by the QR factorization of the final approximate Jacobian, stored rowwise.
    double* _qtf;                        ///  QTF is an output array of length N which contains the vector (Q transpose)*FVEC.
    double* _wa1;                        // work arrays of length N.
    double* _wa2;                        // work arrays of length N.
    double* _wa3;                        // work arrays of length N.
    double* _wa4;                        // work arrays of length N.
    void  *_data;                        ///User data. Contains pointer to Hybrj
    int _lr;                              //LR is a positive integer input variable not less than    (N*(N+1))/2.
    int _ldfjac;                        //LDFJAC is a positive integer input variable not less than N       which specifies the leading dimension of the array FJAC.
    int _mode;                              //MODE is an integer input variable.  If MODE = 1, the variables  will be scaled internally.  If MODE = 2, the scaling is specified by the input DIAG.  Other values of MODE are equivalent to MODE = 1.
    double      _xtol;                        //XTOL is a nonnegative input variable.  Termination occurs when the relative error between two consecutive iterates is at most XTOL.  Therefore, XTOL measures the relative error desired in the approximate solution.
    int _maxfev;                        //MAXFEV is a positive integer input variable.  Termination occurs  when the number of calls to FCN with IFLAG = 1 has reached  MAXFEV.
    double _factor;                        //FACTOR is a positive input variable used in determining the initial step bound.  This bound is set to the product of FACTOR and the Euclidean norm of DIAG*X if nonzero, or else to FACTOR itself.  In most cases FACTOR should lie in the interval (.1,100.).  100. is a generally recommended value.
    double _fnorm;                        //final l2 norm of the residuals
    int _nprint;                        //PRINT is an integer input variable that enables controlled printing of iterates if it is positive.  In this case, FCN is called with IFLAG = 0 at the beginning of the first iteration and every NPRINT iterations thereafter and immediately priorto return, with X and FVEC available for printing.  FVEC and FJAC should not be altered.  If NPRINT is not positive, no special calls of FCN with IFLAG = 0 are made.
    int _nfev;                              //NFEV is an integer output variable set to the number of calls to FCN with IFLAG = 1.
    int _njev;                              //NJEV is an integer output variable set to the number of calls to FCN with IFLAG = 2.
    const double _initial_factor;

};
/** @} */ // end of solverHybrj

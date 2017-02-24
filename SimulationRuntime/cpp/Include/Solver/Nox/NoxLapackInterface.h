//somehow this is not good...
#include <LOCA.H>
#include <LOCA_LAPACK.H>

class NoxLapackInterface : public LOCA::LAPACK::Interface {

  public:

    //! Constructor
    NoxLapackInterface(INonLinearAlgLoop *algLoop, int numberofhomotopytries);

    //! Destructor
    ~NoxLapackInterface();

    const NOX::LAPACK::Vector& getInitialGuess();

    bool computeF(NOX::LAPACK::Vector& f, const NOX::LAPACK::Vector &x);

    bool computeJacobian(NOX::LAPACK::Matrix<double>& J, const NOX::LAPACK::Vector & x);

	//! Sets parameters
	void setParams(const LOCA::ParameterVector& p);

	//! Prints solution after successful step
	void printSolution(const NOX::LAPACK::Vector &x, const double conParam);

  private:

	bool computeSimplifiedF(NOX::LAPACK::Vector& f, const NOX::LAPACK::Vector &x);
	bool computeActualF(NOX::LAPACK::Vector& f, const NOX::LAPACK::Vector &x);
	NOX::LAPACK::Vector applyMatrixtoVector(const NOX::LAPACK::Matrix<double> &A, const NOX::LAPACK::Vector &x);
	void checkdimensionof(const NOX::LAPACK::Vector &x);

    //! Initial guess
    Teuchos::RCP<NOX::LAPACK::Vector> _initialGuess;
	INonLinearAlgLoop *_algLoop;///< Algebraic loop to be solved, required to obtain value of f
	double *_yScale, *_fScale;
	int _dimSys;
	bool _generateoutput;
	bool _useDomainScaling;
	bool _useFunctionValueScaling;
	double _lambda;//homotopy parameter
	bool _computedinitialguess;
	int _numberofhomotopytries;
	bool _evaluatedJacobianAtInitialGuess;
	Teuchos::RCP<NOX::LAPACK::Matrix<double>> _J;//F'(x_0)
};

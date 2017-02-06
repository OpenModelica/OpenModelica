#include "NOX_LAPACK_Group.H"

class NoxLapackInterface : public NOX::LAPACK::Interface {

  public:

    //! Constructor
    NoxLapackInterface(INonLinearAlgLoop *algLoop);

    //! Destructor
    ~NoxLapackInterface();

    const NOX::LAPACK::Vector& getInitialGuess();

    bool computeF(NOX::LAPACK::Vector& f, const NOX::LAPACK::Vector &x);

    bool computeJacobian(NOX::LAPACK::Matrix<double>& J, const NOX::LAPACK::Vector & x);

  private:
    //! Initial guess
    Teuchos::RCP<NOX::LAPACK::Vector> _initialGuess;
	INonLinearAlgLoop *_algLoop;///< Algebraic loop to be solved, required to obtain value of f
	double *_yScale, *_fScale;
	int _dimSys;
	bool _generateoutput;
	bool _useDomainScaling;
	bool _useFunctionValueScaling;
};

#pragma once
class BOOST_EXTENSION_SIMVARS_DECL SimVars : public ISimVars
{
public: 
     /*
     Constructor for SimVars, stores all model variable in continuous block of memory
     @dim_real  number of all real variables (real algebraic vars,discrete algebraic vars, state vars, der state vars)
     @dim_int   number of all integer variables integer algebraic vars
     @dim_bool  number of all bool variables (boolean algebraic vars)
     @dim_pre_vars number of all pre variables (real algebraic vars,discrete algebraic vars, boolean algebraic vars, integer algebraic vars, state vars, der state vars)
     @dim_state_vars number of all state variables
     @state_index start index of state vector in real_vars list
     */
	 SimVars(size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_pre_vars,size_t dim_state_vars,size_t state_index);
	 virtual ~SimVars();
	 virtual double& initRealVar(size_t i);
	 virtual int& initIntVar(size_t i);
	 virtual bool& initBoolVar(unsigned int i);
	 virtual double* getStateVector();
     virtual double* getDerStateVector();
     virtual const double* getRealVarsVector() const; 
     virtual const int* getIntVarsVector() const;
     virtual const bool* getBoolVarsVector() const;
     virtual  void setRealVarsVector(const double* vars);
     virtual  void setIntVarsVector(const int* vars);
     virtual  void setBoolVarsVector(const bool* vars);
     
      virtual double* initRealArrayVar(size_t size,size_t start_index);
	 virtual int*    initIntArrayVar(size_t size,size_t start_index);
	 virtual bool*   initBoolArrayVar(size_t size,size_t start_index);
     virtual void savePreVariables();
     virtual void initPreVariables();
     virtual double& getPreVar(double& var);
     virtual double& getPreVar(int& var);
     virtual double& getPreVar(bool& var);
     virtual void setPreVar(double& var);
     virtual void setPreVar(int& var);
     virtual void setPreVar(bool& var);
private:
	 size_t _dim_real; //number of all real variables (real algebraic vars,discrete algebraic vars, state vars, der state vars)
	 size_t _dim_int; // number of all integer variables (integer algebraic vars)
	 size_t _dim_bool; // number of all bool variables (boolean algebraic vars)
     size_t _dim_pre_vars; //number of all pre variables (real algebraic vars,discrete algebraic vars, boolean algebraic vars, integer algebraic vars, state vars, der state vars)
     size_t _dim_z; // number of all state variables
     size_t _z_i; //start index of state vector in real_vars list
	 boost::shared_array<double> _real_vars; //array for all model real variables of size dim_real
	 boost::shared_array<int> _int_vars;    //array for all model int variables of size dim_int
	 boost::shared_array<bool> _bool_vars;  //array for all model bool variables of size dim_bool
	 //Stores all variables indices (maps a model variable address to an index in the simvars memory)
    unordered_map<const double* , unsigned int> _pre_real_vars_idx;
    unordered_map<const int* , unsigned int> _pre_int_vars_idx;
    unordered_map<const bool* , unsigned int> _pre_bool_vars_idx;
    //Stores all variables occurred before an event
    boost::shared_array<double> _pre_vars;
};
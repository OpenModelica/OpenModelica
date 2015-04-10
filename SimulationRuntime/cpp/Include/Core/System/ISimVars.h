#pragma once

/*
Class for SimVars, stores all model variable in continuous block of memory
*/
class ISimVars
{
public: 
	
	 virtual ~ISimVars() {};
    
      /*Methods for access model variables*/
     //returns state vector of size dim_z*/
     virtual double* getStateVector()= 0;
     //returns der state vector of size dim_z*/
     virtual double* getDerStateVector()= 0;
     //returns real vars vector of size dim_real
     virtual const double* getRealVarsVector() const= 0;
     //returns int vars vector of size dim_int
     virtual const int* getIntVarsVector() const= 0;
      //returns bool vars vector of size dim_bool
     virtual const bool* getBoolVarsVector() const= 0;
      //set real vars vector of size dim_real
     virtual  void setRealVarsVector(const double* vars) = 0;
     //set int vars vector of size dim_int
     virtual  void setIntVarsVector(const int* vars) = 0;
      //set bool vars vector of size dim_bool
     virtual  void setBoolVarsVector(const bool* vars) = 0;
     
     
     /*Methods for initialize model array variables in simvars memory*/
     virtual double* initRealArrayVar(size_t size,size_t start_index)= 0;
	 virtual int*    initIntArrayVar(size_t size,size_t start_index)= 0;
	 virtual bool*   initBoolArrayVar(size_t size,size_t start_index)= 0;
	  /*Methods for initialize scalar model variables in simvars memory*/
     virtual double& initRealVar(size_t i) = 0;
	 virtual int& initIntVar(size_t i)= 0;
	 virtual bool& initBoolVar(unsigned int i)= 0;
     
     /*Methods for pre- variables*/
     
     //copies all real vars,int vars, bool vars in pre- vars vector
     virtual void savePreVariables() = 0;
     //initilizes pre- vars vector
     virtual void initPreVariables()= 0;
     //access methods for pre-variable
     virtual double& getPreVar(double& var)=0;
     virtual double& getPreVar(int& var)=0;
     virtual double& getPreVar(bool& var)=0;
	 virtual void setPreVar(double& var)=0;
     virtual void setPreVar(int& var)=0;
     virtual void setPreVar(bool& var)=0;
};
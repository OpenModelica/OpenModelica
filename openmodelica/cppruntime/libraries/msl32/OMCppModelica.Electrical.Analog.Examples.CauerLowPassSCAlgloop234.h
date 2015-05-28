#pragma once
#if defined(__TRICORE__)
#define BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL
#define BOOST_EXTENSION_EVENTHANDLING_DECL
#else
#define BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL BOOST_EXTENSION_IMPORT_DECL
#define BOOST_EXTENSION_EVENTHANDLING_DECL BOOST_EXTENSION_IMPORT_DECL
#endif
#include "System/AlgLoopDefaultImplementation.h"

//class EventHandling;
class CauerLowPassSC;
class Functions;
class CauerLowPassSCAlgloop234: public IAlgLoop, public AlgLoopDefaultImplementation
{
public:
   //typedef for A- Matrix
  typedef StatArrayDim2<double,11,11> AMATRIX;

    CauerLowPassSCAlgloop234( CauerLowPassSC* system
                                      ,double* z,double* zDot, bool* conditions
                                     ,boost::shared_ptr<DiscreteEvents> discrete_events
                                    );
    virtual ~CauerLowPassSCAlgloop234();
    
         /// Provide number (dimension) of variables according to data type
         virtual int getDimReal() const;
         /// Provide number (dimension) of residuals according to data type
         virtual int getDimRHS() const;
          /// (Re-) initialize the system of equations
         virtual void initialize();
     
         template <typename T>
         void initialize(T *__A);
     
         /// Provide variables with given index to the system
         virtual void getReal(double* vars);
          /// Provide variables with given index to the system
         virtual void getNominalReal(double* vars);
         /// Set variables with given index to the system
         virtual void setReal(const double* vars);
         /// Update transfer behavior of the system of equations according to command given by solver
         virtual void evaluate();
         /// Provide the right hand side (according to the index)
         virtual void getRHS(double* vars);
         /// Output routine (to be called by the solver after every successful integration step)
         virtual void getSystemMatrix(double* A_matrix);
         virtual void getSystemMatrix(SparseMatrix* A_matrix);
         virtual bool isLinear();
         virtual bool isLinearTearing();
         virtual bool isConsistent();
         

    bool getUseSparseFormat();
    void setUseSparseFormat(bool value);
  float queryDensity();
  
protected:
 template <typename T>
 void evaluate(T* __A);
private:
  Functions* _functions;

  //states
  double* __z;
  //state derivatives
  double* __zDot;
  // A matrix
  //boost::multi_array<double,2> *__A; //dense
  
    boost::shared_ptr<AMATRIX> __A; //dense
   //b vector
   StatArrayDim1<double,11> __b;
  
  
  boost::shared_ptr<SparseMatrix> __Asparse; //sparse
  
  
  bool* _conditions;
  
   boost::shared_ptr<DiscreteEvents> _discrete_events;
   CauerLowPassSC* _system;
   
   bool _useSparseFormat;
 };
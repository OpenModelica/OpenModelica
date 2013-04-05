#define BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL BOOST_EXTENSION_EXPORT_DECL
#include "stdafx.h"
#include <System/AlgLoopDefaultImplementation.h>
 


AlgLoopDefaultImplementation::AlgLoopDefaultImplementation()
:_dimAEq         (0)
,    _constraintType(IAlgLoop::UNDEF)
{

}

AlgLoopDefaultImplementation::~AlgLoopDefaultImplementation()
{

}
/// Provide number (dimension) of variables according to data type
int AlgLoopDefaultImplementation::getDimVars() const    
{

    return _dimAEq;
};


/// Provide number (dimension) of residuals according to data type
int AlgLoopDefaultImplementation::getDimRHS() const
{
  return _dimAEq;
};


/// (Re-) initialize the system of equations
void AlgLoopDefaultImplementation::init()
{
  // Anfangswerte einlesen: InitialValue = ConstrValue
    // und Dimension der Bindungsgleichungen zur Lösung der Schleife bestimmen
    _dimAEq = 0;
    if(_constraintType ==IAlgLoop::REAL)
    {
        std::vector<double>::const_iterator 
            constr_iter = __xd.begin(),
            constr_iter_end = __xd.end();

        std::vector<double>::iterator 
            init_iter = _xd_init.begin();

        for (; constr_iter != constr_iter_end; ++constr_iter)
        {
            *init_iter++ = *constr_iter;
            ++_dimAEq;
        }
    }
    else if(_constraintType == IAlgLoop::INTEGER)
    {
        std::vector<int>::const_iterator 
            constr_iter = __xi.begin(),
            constr_iter_end = __xi.end();

        std::vector<int>::iterator 
            init_iter = _xi_init.begin();

        for (; constr_iter != constr_iter_end; ++constr_iter)
        {
            *init_iter++ = *constr_iter;
            ++_dimAEq;
        }
    }
    else if(_constraintType == IAlgLoop::BOOLEAN)
    {
        std::vector<bool>::const_iterator 
            constr_iter = __xb.begin(),
            constr_iter_end = __xb.end();

        std::vector<bool>::iterator 
            init_iter = _xb_init.begin();

        for (; constr_iter != constr_iter_end; ++constr_iter)
        {
            *init_iter++ = *constr_iter;
            ++_dimAEq;
        }
    }
    //nach default algloop verschieben
    // Prüfen ob min. eine Bindungsgleichung vorhanden
    if ( _dimAEq == 0 )
        throw std::invalid_argument("AlgLoop::init(): No constraint defined.");

   
};





/// Output routine (to be called by the solver after every successful integration step)
void AlgLoopDefaultImplementation::writeOutput(const IMixedSystem::OUTPUT command )
{
    if (_outputStream)
    {
        // Write head line
        if (command & IMixedSystem::HEAD_LINE)
        {
            for(int i=0; i<_dimAEq; ++i)
                *_outputStream << "\tdoubleUnknowns[" << i << "]"; 
            for(int i=0; i<_dimAEq; ++i)
                *_outputStream << "\tintUnknowns[" << i << "]"; 
            for(int i=0; i<_dimAEq; ++i)
                *_outputStream << "\tboolUnknowns[" << i << "]";
        }

    // Write the current values
    else
    {
      for(int i=0; i<_dimAEq; ++i)
        *_outputStream << __xd[i];

      for(int i=0; i<_dimAEq; ++i)
        *_outputStream << __xi[i];

      for(int i=0; i<_dimAEq; ++i)
        *_outputStream << __xb[i];
    }
  }
};


/// Set stream for output
void AlgLoopDefaultImplementation::setOutput(ostream* outputStream) 
{
    _outputStream = outputStream;
};


//in algloop default verschieben
void AlgLoopDefaultImplementation::setVars(const double* lambda)
{
   
    std::vector<double>::iterator 
            constr_iter = __xd.begin(),
            constr_iter_end = __xd.end();
        std::vector<double>::iterator 
            init_iter = _xd_init.begin();

        const double* lambda_iter = lambda;

        // lambda zuweisen: InitialValue = ConstrValue = lambda
        for (; constr_iter != constr_iter_end; ++constr_iter)
            *init_iter++ = *constr_iter = *lambda_iter++;
   
}
//in algloop default verschieben
void AlgLoopDefaultImplementation::setVars(const int* lambda)
{
   
        std::vector<int>::iterator  
            constr_iter = __xi.begin(),
            constr_iter_end = __xi.end();
        std::vector<int>::iterator 
            init_iter = _xi_init.begin();

        const int* lambda_iter = lambda;

        // lambda zuweisen: InitialValue = ConstrValue = lambda
        for (; constr_iter != constr_iter_end; ++constr_iter)
            *init_iter++ = *constr_iter = *lambda_iter++;
    
}
//in algloop default verschieben
void AlgLoopDefaultImplementation::setVars(const bool* lambda)
{
    
        std::vector<bool>::iterator  
            constr_iter = __xb.begin(),
            constr_iter_end = __xb.end();
        std::vector<bool>::iterator 
            init_iter = _xb_init.begin();

        const bool* lambda_iter = lambda;

        // lambda zuweisen: InitialValue = ConstrValue = lambda
        for (; constr_iter != constr_iter_end; ++constr_iter)
            *init_iter++ = *constr_iter = *lambda_iter++;
   
}
//in algloop default verschieben
void AlgLoopDefaultImplementation::giveVars(double* lambda)
{
    
        std::vector<double>::iterator 
            constr_iter = __xd.begin(),
            constr_iter_end = __xd.end();

        double* lambda_iter = lambda;

        // lambda zurückgeben: lambda = ConstrValue
        for (; constr_iter != constr_iter_end; ++constr_iter)
            *lambda_iter++ = *constr_iter;
    
}
//in algloop default verschieben
void AlgLoopDefaultImplementation::giveVars(int* lambda)
{
     std::vector<int>::iterator 
            constr_iter = __xi.begin(),
            constr_iter_end = __xi.end();

        int* lambda_iter = lambda;

        // lambda zurückgeben: lambda = ConstrValue
        for (; constr_iter != constr_iter_end; ++constr_iter)
            *lambda_iter++ = *constr_iter;
   
}
//in algloop default verschieben
void AlgLoopDefaultImplementation::giveVars(bool* lambda)
{
    std::vector<bool>::iterator  
            constr_iter = __xb.begin(),
            constr_iter_end = __xb.end();

        bool* lambda_iter = lambda;

        // lambda zurückgeben: lambda = ConstrValue
        for (; constr_iter != constr_iter_end; ++constr_iter)
            *lambda_iter++ = *constr_iter;
   
}
//in algloop default verschieben
void AlgLoopDefaultImplementation::giveRHS(double* res)
{
     std::vector<double>::iterator  
            constr_iter = __xd.begin(),
            constr_iter_end = __xd.end();
        std::vector<double>::iterator 
            init_iter = _xd_init.begin();

        double* res_iter = res;

        // resiudum zurückgeben: res = InitialValue - ResultValue
        for (; constr_iter != constr_iter_end; ++constr_iter)
            *res_iter++ = /**init_iter++ - */*constr_iter;
   
}
//in algloop default verschieben
void AlgLoopDefaultImplementation::giveRHS(int* res)
{
    
        std::vector<int>::iterator 
            constr_iter = __xi.begin(),
            constr_iter_end = __xi.end();
        std::vector<int>::iterator 
            init_iter = _xi_init.begin();

        int* res_iter = res;

        // resiudum zurückgeben: res = InitialValue - ResultValue
        for (; constr_iter != constr_iter_end; ++constr_iter)
            *res_iter++ = *init_iter++ - *constr_iter;
    
}

//in algloop default verschieben
void AlgLoopDefaultImplementation::giveRHS(bool* res)
{
    
        std::vector<bool>::iterator 
            constr_iter = __xb.begin(),
            constr_iter_end = __xb.end();
        std::vector<bool>::iterator 
            init_iter = _xb_init.begin();

        bool* res_iter = res;

        // resiudum zurückgeben: res = InitialValue XNOR ResultValue
        for (; constr_iter != constr_iter_end; ++constr_iter)
            *res_iter++ = !(*init_iter++ ^ *constr_iter);
    
}


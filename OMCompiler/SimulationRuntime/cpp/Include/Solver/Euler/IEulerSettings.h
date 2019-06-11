#pragma once
/** @addtogroup solverEuler
 *
 *  @{
 */


/*****************************************************************************/
/**

Encapsulation of settings for euler solver

\date     October, 1st, 2008
\author


*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class IEulerSettings
{

public:
    /// Enum to choose the integration method
    enum EULERMETHOD
    {
        EULERFORWARD    = 0,    ///< Explicit Euler
        EULERBACKWARD    = 1,    ///< Implicit Euler
        MIDPOINT        = 2,        ///< Midpoint rule

    };

    /// Enum to choose the method for zero search
    enum ZEROSEARCHMETHOD
    {
        NO_ZERO_SEARCH            = 0,    ///< Ignore zero functions
        BISECTION                = 1,    ///< Bisection method
        LINEAR_INTERPOLATION    = 2,    ///< Linear interpolation
    };
    virtual ~IEulerSettings()    {};

    /**
    Choise of solution method according to EULERMETHOD ([0,1,2,3,4,5]; default: 0)
    **/
    virtual unsigned int getEulerMethod() =0;
    virtual  void setEulerMetoh(unsigned int) =0;
    /**
     Choise of method for zero search according to ZEROSEARCHMETHOD ([0,1]; default: 0)
    */
    virtual unsigned int getZeroSearchMethod() =0;
        virtual void setZeroSearchMethod(unsigned int ) =0;

    /**
    Determination of number of zeros in one intervall (used only for methods [2,3]) ([true,false]; default: false)
    */
    virtual bool getUseSturmSequence() =0;
    virtual void setUseSturmSequence(bool) =0;
    /**
    For implicit methods only. Choise between fixpoint and newton-iteration  kann eine Newtoniteration gewählt werden. ([false,true]; default: false = Fixpunktiteration)
    */
    virtual bool getUseNewtonIteration() =0;
    virtual void setUseNewtonIteration(bool) =0;
    /**
    Equidistant output(by interpolation polynominal) ([true,false]; default: false)
    */
    virtual bool getDenseOutput() =0;
    virtual void setDenseOutput(bool) =0;
        /**
    Tolerance for newton iteration (used when _useNewtonIteration=true) (default: 1e-8)
    */
    virtual double getIterTol()=0;
    virtual void setIterTol(double)=0;
    virtual void load(std::string xml_file)=0;

};
/** @} */ // end of solverEuler
#pragma once
/** @addtogroup math
 *   @{
*/




#include <math.h>                        ///< mathematical expressions
#include <stdlib.h>
#include <limits>
#include <string>
#include <exception>
#include <Core/Math/OMAPI.h>    ///< For the use of DGESV, etc.
/*****************************************************************************/
/**

Auxillary functions for open modelica.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/

#define EPSILON    (std::numeric_limits<double>::epsilon( ))

#if defined(__vxworks) || defined(__TRICORE__)
#define BOOST_EXTENSION_EXPORT_DECL
#endif

/// Definition of Signum function
inline static int sgn (const double &c)
{
    return (c < 0) ? -1 : ((c == 0) ? 0 : 1);
}

/// Definition of Signum function
double BOOST_EXTENSION_EXPORT_DECL division (const double &a,const double &b, bool throwEx,const char * text);

inline static int modelica_mod_int(int v1, int v2)
{
    return v1 % v2;
}

inline static double semiLinear(double x,double positiveSlope,double negativeSlope)
{
 if(x>=0)
    return positiveSlope*x;
 else
    return negativeSlope*x;
}
/// Provides the maximum Norm
inline static double maxNorm(const int& length, const double* vector)
{
    double value = 0.0;

    for (int i=0; i<length; ++i)
        if(fabs(vector[i]) > value)
            value = fabs(vector[i]);

    return(value);
}


/// Provides the Euclidean norm
inline static double euclidNorm(const int& length, const double* vector)
{
    double value = 0.0;

    for (int i=0; i<length; ++i)
        value = value + (vector[i] * vector[i]);

    return(sqrt(value));
}

/// Provides the Euclidean norm of an integer array
inline static double euclidNorm(const int& length, const int* vector)
{
    int value = 0;

    for (int i=0; i<length; ++i)
        value = value + (vector[i] * vector[i]);

    return(sqrt((double)value));
}

/// Provides the scaled  errornorm (see Hairer, Norsett und Wanner; Section II.4 )
inline static double scaledErrNorm(const int& length, const double* vector, const double *tol)
{
    double value = 0.0;

    for (int i=0; i<length; ++i)
        value = value + ((vector[i]/tol[i]) * (vector[i]/tol[i]));

    return(sqrt(value / length));
}

///  Exponent(0 und negative exponents (Basis != 0) permitted)
inline static double Power(const double& basis, const int& exponent)
{
    double value = 1.0;

    for (int i=0; i<abs(exponent); i++)
        value *= basis;

    if (exponent >= 0)
        return value;
    else
        return (1.0/value);
}

/// Binominialcoefficients
inline static int binom(const int n, const int k)
{
    int kfak = 1, nfak = 1, nkfak =1;

    for(int i=0; i < n; ++i )
        nfak = nfak*(i+1);
    for(int i=0; i < k; ++i )
        kfak = kfak*(i+1);

    if(n-k>0)
    {
        for(int i=0; i < n-k; ++i )
            nkfak = nkfak*(i+1);
    }
    else
        return 0;

    nkfak = nfak/(kfak*nkfak);
    return nkfak;
}


/// Rounding function
inline static int round (const double &n)
{
    return (fabs(n)-floor(fabs(n)) < 0.5) ? (int)(sgn(n)*floor(fabs(n))) : (int)(sgn(n)*ceil(fabs(n)));
}

/// Modelica integer function
inline static int integer (const double &n)
{
    return floor(n);
}

/// Horner-Schema (William George Horner)
inline double Phorner(double &x, int degree_P, double* P)
{
    double h;

    if(degree_P > 0)
        h = Phorner(x,degree_P-1,P);
    else
        return P[degree_P];

    return h*x + P[degree_P];
}

template<class T >
inline bool in_range(T i,T start,T stop)
{
  if (start <= stop) if ((i >= start) && (i <= stop)) return true;
  if (start > stop) if ((i >= stop) && (i <= start)) return true;
  return false;
}



int BOOST_EXTENSION_EXPORT_DECL pivot( double *A, int n_rows, int n_cols, int *rowInd, int *colInd );


//  (C) Copyright Gennadiy Rozental 2001-2002.
//  Permission to copy, use, modify, sell and distribute this software
//  is granted provided this copyright notice appears in all copies.
//  This software is provided "as is" without express or implied warranty,
//  and with no claim as to its suitability for any purpose.

//  See http://www.boost.org for most recent version including documentation.
//
//  File        : $RCSfile: floating_point_comparison.hpp,v $
//
//  Version     : $Id: floating_point_comparison.hpp,v 1.6 2002/09/16 08:47:29 rogeeff Exp $
//
//  Description : defines algoirthms for comparing 2 floating point values
// ***************************************************************************
template<typename FPT>
inline FPT
fpt_abs( FPT arg )
{
    return arg < 0 ? -arg : arg;
}

// both f1 and f2 are unsigned here
template<typename FPT>
inline FPT
safe_fpt_division( FPT uf1, FPT uf2 )
{
   #undef max
  #undef min
  return  ( uf1 < 1 && uf1 > uf2 * std::numeric_limits<FPT>::max())
    ? std::numeric_limits<FPT>::max() :
  (((uf2 > 1 && uf1 < uf2 * std::numeric_limits<FPT>::min()) ||
    uf1 == 0)                                               ? 0                               :
    uf1/uf2 );
}

template<typename FPT>
class close_at_tolerance
{
public:
    explicit close_at_tolerance( FPT tolerance, bool strong_or_weak = true )
        : p_tolerance( tolerance ),m_strong_or_weak( strong_or_weak ) { };

    explicit    close_at_tolerance( int number_of_rounding_errors, bool strong_or_weak = true )
        : p_tolerance( std::numeric_limits<FPT>::epsilon() * number_of_rounding_errors/2 ),
        m_strong_or_weak( strong_or_weak ) {}

    bool        operator()( FPT left, FPT right ) const
    {
        FPT diff = fpt_abs( left - right );
        FPT d1   = safe_fpt_division( diff, fpt_abs( right ) );
        FPT d2   = safe_fpt_division( diff, fpt_abs( left ) );

        return m_strong_or_weak ? (d1 <= p_tolerance.get() && d2 <= p_tolerance.get())
            : (d1 <= p_tolerance.get() || d2 <= p_tolerance.get());
    }

    // Data members
    class p_tolerance_class
    {
    private:
        FPT f;
    public:
        p_tolerance_class(FPT _f=0):f(_f){};
        FPT  get() const{    return f;};
    };
    p_tolerance_class p_tolerance;
private:
    bool        m_strong_or_weak;
};

template <typename T>
inline bool IsEqual(T x, T y, T t)
{
    close_at_tolerance<T> comp( t /*std::numeric_limits<T>::epsilon()/2*10*/);
    return comp(fpt_abs(x),fpt_abs(y));
};

template <typename T>
inline bool IsEqual(T x, T y)
{
    return x == y;
};

template <>
inline bool IsEqual(double x, double y)
{
    return IsEqual(x, y, 1e-10);
};

template <>
inline bool IsEqual(std::string x, std::string y)
{
    return x.compare(y) == 0;
};

inline bool IsEqual(std::string x, const char* y)
{
    return x.compare(y) == 0;
};

template < typename T >
struct floatCompare {

    T val;
    T tol;
    floatCompare ( T const & t ,T const& tollerance)
        : val ( t ), tol(tollerance)
    {}

    template < typename Pair >
    bool operator() ( Pair const & p ) const {
        return ( IsEqual<T>(val,p.first,tol) );
    }

};
/** @} */ // end of math

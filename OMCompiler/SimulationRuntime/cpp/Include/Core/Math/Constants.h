#pragma once



#include <algorithm>        ///< use of min, max, etc.
#include <limits>
#include <math.h>      ///< mathematical expressions
//vxworks: #include <memory.h>      ///< use of memset, etc.
#undef min
#undef max
using std::min;
using std::max;

/*****************************************************************************/
/**

Constant factors for open modelica.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/

/// Machine presicion
#define UROUND    (std::numeric_limits<double>::epsilon( ))

/// Smalles possible number (represents -\inf)
#define MIN_DOUBLE    (std::numeric_limits<double>::min( ))

/// Largest possible number (represents +\inf)
#define MAX_DOUBLE    (std::numeric_limits<double>::max( ))

/// Pi
#define PI 3.141592653589793

/// Kelvin to Celsius
#define K2C    273.15

/// Degrees to Radians
#define DEG2RAD    0.017453292519943295769236907684886

/// Degrees to Radians
#define RAD2DEG    57.295779513082320876798154814105


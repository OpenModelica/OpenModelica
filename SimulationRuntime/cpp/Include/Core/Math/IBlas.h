#pragma once

/*************************
    copies a vector, x, to a vector, y.
    uses unrolled loops for increments equal to one.
    jack dongarra, linpack, 3/11/78.
    modified 12/3/93, array(1) declarations changed to array(*)
*************************/
extern "C" void DCOPY(long int* n, double* dx, long int* incx, double* dy, long int* incy);

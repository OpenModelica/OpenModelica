/** @addtogroup math
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Math/Functions.h>
#include <stdexcept>

#include <Core/Utils/numeric/bindings/ublas.hpp>
#include <Core/Utils/numeric/utils.h>
//#include <Core/Utils/extension/logger.hpp>
namespace bindings = boost::numeric::bindings;

/* Matrixes using column major order (as in Fortran) */
#ifndef set_matrix_elt
#define set_matrix_elt(A,r,c,n_rows,value) A[r + n_rows * c] = value
#endif

#ifndef get_matrix_elt
#define get_matrix_elt(A,r,c,n_rows) A[r + n_rows * c]
#endif

/* Matrixes using column major order (as in Fortran) */
/* colInd, rowInd, n_rows is added implicitly, makes code easier to read but may be considered bad programming style! */
#define set_pivot_matrix_elt(A,r,c,value) set_matrix_elt(A,rowInd[r],colInd[c],n_rows,value)
/* #define set_pivot_matrix_elt(A,r,c,value) set_matrix_elt(A,colInd[c],rowInd[r],n_cols,value) */
#define get_pivot_matrix_elt(A,r,c) get_matrix_elt(A,rowInd[r],colInd[c],n_rows)
/* #define get_pivot_matrix_elt(A,r,c) get_matrix_elt(A,colInd[c],rowInd[r],n_cols) */
#define swap(a,b) { int _swap=a; a=b; b=_swap; }

#ifndef min
#define min(a,b) ((a > b) ? (b) : (a))
#endif

double division(const double& a, const double& b, bool throwEx, const char* text)
{
    if (b != 0)
        return a / b;
    else
    {
        if (a == 0)
        {
            //LOGGER_WRITE("Division by Zero: Solver will try to handle division by zero with minimu norm  for" + string(text), LC_INIT, LL_DEBUG);
            return 0;
        }

        if (throwEx)
            throw ModelicaSimulationError(UTILITY, "Division by zero: " + string(text));
        else
        {
            //LOGGER_WRITE("Division: Solver will try to handle division by zero for" + string(text), LC_INIT, LL_DEBUG);
            return a;
        }
    }
}

/*
find the maximum element below (and including) line/row start
*/
int maxsearch(double* A, int start, int n_rows, int n_cols, int* rowInd, int* colInd, int* maxrow, int* maxcol,
              double* maxabsval)
{
    /* temporary variables */
    int row;
    int col;

    /* Initialization */
    int mrow = -1;
    int mcol = -1;
    double mabsval = 0.0;

    /* go through all rows and columns */
    for (row = start; row < n_rows; row++)
    {
        for (col = start; col < n_cols; col++)
        {
            double tmp = fabs(get_pivot_matrix_elt(A, row, col));
            /* Compare element to current maximum */
            if (tmp > mabsval)
            {
                mrow = row;
                mcol = col;
                mabsval = tmp;
            }
        }
    }

    /* assert that the matrix is not identical to zero */
    if ((mrow < 0) || (mcol < 0)) return -1;

    /* return result */
    *maxrow = mrow;
    *maxcol = mcol;
    *maxabsval = mabsval;
    return 0;
}

/*
pivot performs a full pivotization of a rectangular matrix A of dimension n_cols x n_rows
rowInd and colInd are vectors of length nrwos and n_cols respectively.
They hold the old (and new) pivoting information, such that
  A_pivoted[i,j] = A[rowInd[i], colInd[j]]
*/
int pivot(double* A, int n_rows, int n_cols, int* rowInd, int* colInd)
{
    /* parameter, determines how much larger an element should be before rows and columns are interchanged */
    const double fac = 1.125; /* approved by dymola ;) */

    /* temporary variables */
    int row;
    int i, j;
    int maxrow;
    int maxcol;
    double maxabsval;
    double pivot;

    /* go over all pivot elements */
    for (row = 0; row < min(n_rows, n_cols); row++)
    {
        /* get current pivot */
        pivot = fabs(get_pivot_matrix_elt(A, row, row));

        /* find the maximum element in matrix
           result is stored in maxrow, maxcol and maxabsval */
        if (maxsearch(A, row, n_rows, n_cols, rowInd, colInd, &maxrow, &maxcol, &maxabsval) != 0) return -1;


        /* compare max element and pivot (scaled by fac) */
        if (maxabsval > (fac * pivot))
        {
            /* row interchange */
            swap(rowInd[row], rowInd[maxrow]);
            /* column interchange */
            swap(colInd[row], colInd[maxcol]);
        }

        /* get pivot (without abs, may have changed because of row/column interchange */
        pivot = get_pivot_matrix_elt(A, row, row);
        /* internal error, pivot element should never be zero if maxsearch succeeded */
        if (pivot == 0)
            throw ModelicaSimulationError(UTILITY, "pivot element is zero ");

        /* perform one step of Gaussian Elimination */
        for (i = row + 1; i < n_rows; i++)
        {
            double leader = get_pivot_matrix_elt(A, i, row);
            if (leader != 0.0)
            {
                double scale = -leader / pivot;
                /* set leader to zero */
                set_pivot_matrix_elt(A, i, row, 0.0);
                /* subtract scaled equation from pivot row from current row */
                for (j = row + 1; j < n_cols; j++)
                {
                    double t1 = get_pivot_matrix_elt(A, i, j);
                    double t2 = get_pivot_matrix_elt(A, row, j);
                    double tmp = t1 + scale * t2;
                    set_pivot_matrix_elt(A, i, j, tmp);
                }
            }
        }
    }
    /* all fine */
    return 0;
}


/** @} */ // end of math

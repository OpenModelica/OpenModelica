#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#include <Core/Math/matrix_t.h>
#ifdef USE_UMFPACK
#include "umfpack.h"
#endif

#ifdef USE_UMFPACK
void sparse_matrix::build(sparse_inserter& ins) {
        if(n==-1) {
            n=ins.content.rbegin()->first.first+1;
        } else {
            if(n-1!=ins.content.rbegin()->first.first) {
                throw ModelicaSimulationError(MATH_FUNCTION,"size doesn't match");
            }
        }
        size_t n=ins.content.size();
        Ap.assign(this->n+1,0);
        Ai.resize(n);
        Ax.resize(n);
        unsigned int j=0;
        int rowold=1;
        for(map< pair<int,int>, double>::iterator it=ins.content.begin(); it!=ins.content.end(); it++) {
            if(it->first.first+1==rowold) {
                ++Ap[rowold];
            } else {
                Ap[it->first.first+1]=Ap[rowold]+1;
                rowold=it->first.first+1;
            }
            Ai[j]=it->first.second;
            Ax[j]=it->second;
            ++j;
        }
    }

int sparse_matrix::solve(const double* b, double * x) {
    int status, sys=0;
    double Control [UMFPACK_CONTROL], Info [UMFPACK_INFO] ;
    void *Symbolic, *Numeric ;
    umfpack_di_defaults (Control) ;
    status = umfpack_di_symbolic (sparse_matrix::n, sparse_matrix::n, &sparse_matrix::Ap[0], &sparse_matrix::Ai[0], &sparse_matrix::Ax[0], &Symbolic, Control, Info) ;
    status = umfpack_di_numeric (&sparse_matrix::Ap[0], &sparse_matrix::Ai[0], &sparse_matrix::Ax[0], Symbolic, &Numeric, Control, Info);
    status = umfpack_di_solve (sys, &sparse_matrix::Ap[0], &sparse_matrix::Ai[0], &sparse_matrix::Ax[0], x, b, Numeric, Control, Info);
    umfpack_di_free_symbolic (&Symbolic);
    umfpack_di_free_numeric (&Numeric);
    return status;
}
#else
void sparse_matrix::build(sparse_inserter& ins) {
        throw ModelicaSimulationError(MATH_FUNCTION,"no umfpack");
    }

int sparse_matrix::solve(const double* b, double * x) {
        throw ModelicaSimulationError(MATH_FUNCTION,"no umfpack");
}

#endif

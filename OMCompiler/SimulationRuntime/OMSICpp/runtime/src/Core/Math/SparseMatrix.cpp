/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

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
void sparse_matrix::build(sparse_inserter& ins)
{
    throw ModelicaSimulationError(MATH_FUNCTION, "no umfpack");
}

int sparse_matrix::solve(const double* b, double* x)
{
    throw ModelicaSimulationError(MATH_FUNCTION, "no umfpack");
}

#endif

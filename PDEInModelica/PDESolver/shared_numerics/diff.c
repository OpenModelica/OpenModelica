#include "diff.h";
#include <stdio.h>

int differentiateX(double* y, double* yp, double* x, int M, int dScheme){
    int iNode;
    switch  (dScheme)
    {
        case 0:
            //left boundary, right side second-order difference:
            yp[0] = (-3*y[0] + 4*y[1] - y[2])/(x[2] - x[0]);
            //loop over all inner grid nodes:
            for (iNode=1; iNode<M-1; iNode++){
                //lax_friedrichsX(mData, iState, iNode);
                yp[iNode] = (y[iNode + 1] - y[iNode - 1])/(x[iNode + 1] - x[iNode - 1]);
            }
            // right boundary: left side second-order difference:
            yp[M-1] = (3*y[M-1] - 4*y[M-2] + y[M-3])/(x[M-1] - x[M-3]);
            break;

        case 1:
            printf("this differential scheme is not implemented");
            //throw dSchemeE;
            return -1;

/*
        case 3:
            if (mData->isBc[0] == 0) {
                cout << "there must be boundary condition on left when forwardT_backwardS scheme is used for all states";
                throw dSchemeE;
            }
            for (int iNode = 1; iNode < M; iNode++){
                yp[iNode] = (y[iNode] - y[iNode - 1])/(x[iNode] - x[iNode - 1]);
            }
            break;
*/

        default:
            printf("this differential scheme is not implemented");
            //throw dSchemeE;
            return -1;
    }
    return 0;
}

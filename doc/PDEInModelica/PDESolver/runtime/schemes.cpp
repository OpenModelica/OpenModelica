//#include "schemes.h"
//#include "data.h"
//
//int lax_friedrichsX(DATA* data, int iState, int iNode){
//    int M = data->M;
//    if ((iNode <= 0 ) || (M-1 <= iNode))
//        throw 0;
//    data->stateFieldsDerSpace[iState*M + iNode] = (data->stateFields[iState*M + iNode + 1] - data->stateFields[iState*M + iNode - 1])/(data->spaceField[iState*M + iNode + 1] - data->spaceField[iState*M + iNode - 1]);
//    return 0;
//}
//
//int lax_friedrichsT(DATA* data, int iState, int iNode){
//    int M = data->M;
//    if ((iNode <= 0 ) || (M-1 <= iNode))
//        throw 0;
//    data->stateFields[iState*M + iNode] = (data->stateFields[iState*M + iNode + 1] - data->stateFields[iState*M + iNode - 1])/(data->spaceField[iState*M + iNode + 1] - data->spaceField[iState*M + iNode - 1]);
//    return 0;
//}
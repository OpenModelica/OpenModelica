#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Lapack.c"
#endif
#include "omc_simulation_settings.h"
#include "Lapack.h"
#include "util/modelica.h"
#include "Lapack_includes.h"
modelica_metatype omc_Lapack_dorgqr(threadData_t *threadData, modelica_integer _inM, modelica_integer _inN, modelica_integer _inK, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inTAU, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outWORK, modelica_integer *out_outINFO)
{
int _inM_ext;
int _inN_ext;
int _inK_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
modelica_metatype _inTAU_ext;
modelica_metatype _inWORK_ext;
int _inLWORK_ext;
modelica_metatype _outA_ext;
modelica_metatype _outWORK_ext;
int _outINFO_ext;
modelica_metatype _outA = NULL;
modelica_metatype _outWORK = NULL;
modelica_integer _outINFO;
_inM_ext = (int)_inM;
_inN_ext = (int)_inN;
_inK_ext = (int)_inK;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
_inTAU_ext = (modelica_metatype)_inTAU;
_inWORK_ext = (modelica_metatype)_inWORK;
_inLWORK_ext = (int)_inLWORK;
LapackImpl__dorgqr(_inM_ext, _inN_ext, _inK_ext, _inA_ext, _inLDA_ext, _inTAU_ext, _inWORK_ext, _inLWORK_ext, &_outA_ext, &_outWORK_ext, &_outINFO_ext);
_outA = (modelica_metatype)_outA_ext;
_outWORK = (modelica_metatype)_outWORK_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outWORK) { *out_outWORK = _outWORK; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outA;
}
modelica_metatype boxptr_Lapack_dorgqr(threadData_t *threadData, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inK, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inTAU, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer _outINFO;
modelica_metatype _outA = NULL;
tmp1 = mmc_unbox_integer(_inM);
tmp2 = mmc_unbox_integer(_inN);
tmp3 = mmc_unbox_integer(_inK);
tmp4 = mmc_unbox_integer(_inLDA);
tmp5 = mmc_unbox_integer(_inLWORK);
_outA = omc_Lapack_dorgqr(threadData, tmp1, tmp2, tmp3, _inA, tmp4, _inTAU, _inWORK, tmp5, out_outWORK, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outA;
}
modelica_metatype omc_Lapack_dgeqpf(threadData_t *threadData, modelica_integer _inM, modelica_integer _inN, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inJPVT, modelica_metatype _inWORK, modelica_metatype *out_outJPVT, modelica_metatype *out_outTAU, modelica_integer *out_outINFO)
{
int _inM_ext;
int _inN_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
modelica_metatype _inJPVT_ext;
modelica_metatype _inWORK_ext;
modelica_metatype _outA_ext;
modelica_metatype _outJPVT_ext;
modelica_metatype _outTAU_ext;
int _outINFO_ext;
modelica_metatype _outA = NULL;
modelica_metatype _outJPVT = NULL;
modelica_metatype _outTAU = NULL;
modelica_integer _outINFO;
_inM_ext = (int)_inM;
_inN_ext = (int)_inN;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
_inJPVT_ext = (modelica_metatype)_inJPVT;
_inWORK_ext = (modelica_metatype)_inWORK;
LapackImpl__dgeqpf(_inM_ext, _inN_ext, _inA_ext, _inLDA_ext, _inJPVT_ext, _inWORK_ext, &_outA_ext, &_outJPVT_ext, &_outTAU_ext, &_outINFO_ext);
_outA = (modelica_metatype)_outA_ext;
_outJPVT = (modelica_metatype)_outJPVT_ext;
_outTAU = (modelica_metatype)_outTAU_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outJPVT) { *out_outJPVT = _outJPVT; }
if (out_outTAU) { *out_outTAU = _outTAU; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outA;
}
modelica_metatype boxptr_Lapack_dgeqpf(threadData_t *threadData, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inJPVT, modelica_metatype _inWORK, modelica_metatype *out_outJPVT, modelica_metatype *out_outTAU, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer _outINFO;
modelica_metatype _outA = NULL;
tmp1 = mmc_unbox_integer(_inM);
tmp2 = mmc_unbox_integer(_inN);
tmp3 = mmc_unbox_integer(_inLDA);
_outA = omc_Lapack_dgeqpf(threadData, tmp1, tmp2, _inA, tmp3, _inJPVT, _inWORK, out_outJPVT, out_outTAU, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outA;
}
modelica_metatype omc_Lapack_dgetri(threadData_t *threadData, modelica_integer _inN, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inIPIV, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outWORK, modelica_integer *out_outINFO)
{
int _inN_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
modelica_metatype _inIPIV_ext;
modelica_metatype _inWORK_ext;
int _inLWORK_ext;
modelica_metatype _outA_ext;
modelica_metatype _outWORK_ext;
int _outINFO_ext;
modelica_metatype _outA = NULL;
modelica_metatype _outWORK = NULL;
modelica_integer _outINFO;
_inN_ext = (int)_inN;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
_inIPIV_ext = (modelica_metatype)_inIPIV;
_inWORK_ext = (modelica_metatype)_inWORK;
_inLWORK_ext = (int)_inLWORK;
LapackImpl__dgetri(_inN_ext, _inA_ext, _inLDA_ext, _inIPIV_ext, _inWORK_ext, _inLWORK_ext, &_outA_ext, &_outWORK_ext, &_outINFO_ext);
_outA = (modelica_metatype)_outA_ext;
_outWORK = (modelica_metatype)_outWORK_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outWORK) { *out_outWORK = _outWORK; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outA;
}
modelica_metatype boxptr_Lapack_dgetri(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inIPIV, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer _outINFO;
modelica_metatype _outA = NULL;
tmp1 = mmc_unbox_integer(_inN);
tmp2 = mmc_unbox_integer(_inLDA);
tmp3 = mmc_unbox_integer(_inLWORK);
_outA = omc_Lapack_dgetri(threadData, tmp1, _inA, tmp2, _inIPIV, _inWORK, tmp3, out_outWORK, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outA;
}
modelica_metatype omc_Lapack_dgetrs(threadData_t *threadData, modelica_string _inTRANS, modelica_integer _inN, modelica_integer _inNRHS, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inIPIV, modelica_metatype _inB, modelica_integer _inLDB, modelica_integer *out_outINFO)
{
int _inN_ext;
int _inNRHS_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
modelica_metatype _inIPIV_ext;
modelica_metatype _inB_ext;
int _inLDB_ext;
modelica_metatype _outB_ext;
int _outINFO_ext;
modelica_metatype _outB = NULL;
modelica_integer _outINFO;
_inN_ext = (int)_inN;
_inNRHS_ext = (int)_inNRHS;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
_inIPIV_ext = (modelica_metatype)_inIPIV;
_inB_ext = (modelica_metatype)_inB;
_inLDB_ext = (int)_inLDB;
LapackImpl__dgetrs(MMC_STRINGDATA(_inTRANS), _inN_ext, _inNRHS_ext, _inA_ext, _inLDA_ext, _inIPIV_ext, _inB_ext, _inLDB_ext, &_outB_ext, &_outINFO_ext);
_outB = (modelica_metatype)_outB_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outB;
}
modelica_metatype boxptr_Lapack_dgetrs(threadData_t *threadData, modelica_metatype _inTRANS, modelica_metatype _inN, modelica_metatype _inNRHS, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inIPIV, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer _outINFO;
modelica_metatype _outB = NULL;
tmp1 = mmc_unbox_integer(_inN);
tmp2 = mmc_unbox_integer(_inNRHS);
tmp3 = mmc_unbox_integer(_inLDA);
tmp4 = mmc_unbox_integer(_inLDB);
_outB = omc_Lapack_dgetrs(threadData, _inTRANS, tmp1, tmp2, _inA, tmp3, _inIPIV, _inB, tmp4, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outB;
}
modelica_metatype omc_Lapack_dgetrf(threadData_t *threadData, modelica_integer _inM, modelica_integer _inN, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype *out_outIPIV, modelica_integer *out_outINFO)
{
int _inM_ext;
int _inN_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
modelica_metatype _outA_ext;
modelica_metatype _outIPIV_ext;
int _outINFO_ext;
modelica_metatype _outA = NULL;
modelica_metatype _outIPIV = NULL;
modelica_integer _outINFO;
_inM_ext = (int)_inM;
_inN_ext = (int)_inN;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
LapackImpl__dgetrf(_inM_ext, _inN_ext, _inA_ext, _inLDA_ext, &_outA_ext, &_outIPIV_ext, &_outINFO_ext);
_outA = (modelica_metatype)_outA_ext;
_outIPIV = (modelica_metatype)_outIPIV_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outIPIV) { *out_outIPIV = _outIPIV; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outA;
}
modelica_metatype boxptr_Lapack_dgetrf(threadData_t *threadData, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype *out_outIPIV, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer _outINFO;
modelica_metatype _outA = NULL;
tmp1 = mmc_unbox_integer(_inM);
tmp2 = mmc_unbox_integer(_inN);
tmp3 = mmc_unbox_integer(_inLDA);
_outA = omc_Lapack_dgetrf(threadData, tmp1, tmp2, _inA, tmp3, out_outIPIV, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outA;
}
modelica_metatype omc_Lapack_dgesvd(threadData_t *threadData, modelica_string _inJOBU, modelica_string _inJOBVT, modelica_integer _inM, modelica_integer _inN, modelica_metatype _inA, modelica_integer _inLDA, modelica_integer _inLDU, modelica_integer _inLDVT, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outS, modelica_metatype *out_outU, modelica_metatype *out_outVT, modelica_metatype *out_outWORK, modelica_integer *out_outINFO)
{
int _inM_ext;
int _inN_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
int _inLDU_ext;
int _inLDVT_ext;
modelica_metatype _inWORK_ext;
int _inLWORK_ext;
modelica_metatype _outA_ext;
modelica_metatype _outS_ext;
modelica_metatype _outU_ext;
modelica_metatype _outVT_ext;
modelica_metatype _outWORK_ext;
int _outINFO_ext;
modelica_metatype _outA = NULL;
modelica_metatype _outS = NULL;
modelica_metatype _outU = NULL;
modelica_metatype _outVT = NULL;
modelica_metatype _outWORK = NULL;
modelica_integer _outINFO;
_inM_ext = (int)_inM;
_inN_ext = (int)_inN;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
_inLDU_ext = (int)_inLDU;
_inLDVT_ext = (int)_inLDVT;
_inWORK_ext = (modelica_metatype)_inWORK;
_inLWORK_ext = (int)_inLWORK;
LapackImpl__dgesvd(MMC_STRINGDATA(_inJOBU), MMC_STRINGDATA(_inJOBVT), _inM_ext, _inN_ext, _inA_ext, _inLDA_ext, _inLDU_ext, _inLDVT_ext, _inWORK_ext, _inLWORK_ext, &_outA_ext, &_outS_ext, &_outU_ext, &_outVT_ext, &_outWORK_ext, &_outINFO_ext);
_outA = (modelica_metatype)_outA_ext;
_outS = (modelica_metatype)_outS_ext;
_outU = (modelica_metatype)_outU_ext;
_outVT = (modelica_metatype)_outVT_ext;
_outWORK = (modelica_metatype)_outWORK_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outS) { *out_outS = _outS; }
if (out_outU) { *out_outU = _outU; }
if (out_outVT) { *out_outVT = _outVT; }
if (out_outWORK) { *out_outWORK = _outWORK; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outA;
}
modelica_metatype boxptr_Lapack_dgesvd(threadData_t *threadData, modelica_metatype _inJOBU, modelica_metatype _inJOBVT, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inLDU, modelica_metatype _inLDVT, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outS, modelica_metatype *out_outU, modelica_metatype *out_outVT, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer _outINFO;
modelica_metatype _outA = NULL;
tmp1 = mmc_unbox_integer(_inM);
tmp2 = mmc_unbox_integer(_inN);
tmp3 = mmc_unbox_integer(_inLDA);
tmp4 = mmc_unbox_integer(_inLDU);
tmp5 = mmc_unbox_integer(_inLDVT);
tmp6 = mmc_unbox_integer(_inLWORK);
_outA = omc_Lapack_dgesvd(threadData, _inJOBU, _inJOBVT, tmp1, tmp2, _inA, tmp3, tmp4, tmp5, _inWORK, tmp6, out_outS, out_outU, out_outVT, out_outWORK, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outA;
}
modelica_metatype omc_Lapack_dgbsv(threadData_t *threadData, modelica_integer _inN, modelica_integer _inKL, modelica_integer _inKU, modelica_integer _inNRHS, modelica_metatype _inAB, modelica_integer _inLDAB, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype *out_outIPIV, modelica_metatype *out_outB, modelica_integer *out_outINFO)
{
int _inN_ext;
int _inKL_ext;
int _inKU_ext;
int _inNRHS_ext;
modelica_metatype _inAB_ext;
int _inLDAB_ext;
modelica_metatype _inB_ext;
int _inLDB_ext;
modelica_metatype _outAB_ext;
modelica_metatype _outIPIV_ext;
modelica_metatype _outB_ext;
int _outINFO_ext;
modelica_metatype _outAB = NULL;
modelica_metatype _outIPIV = NULL;
modelica_metatype _outB = NULL;
modelica_integer _outINFO;
_inN_ext = (int)_inN;
_inKL_ext = (int)_inKL;
_inKU_ext = (int)_inKU;
_inNRHS_ext = (int)_inNRHS;
_inAB_ext = (modelica_metatype)_inAB;
_inLDAB_ext = (int)_inLDAB;
_inB_ext = (modelica_metatype)_inB;
_inLDB_ext = (int)_inLDB;
LapackImpl__dgbsv(_inN_ext, _inKL_ext, _inKU_ext, _inNRHS_ext, _inAB_ext, _inLDAB_ext, _inB_ext, _inLDB_ext, &_outAB_ext, &_outIPIV_ext, &_outB_ext, &_outINFO_ext);
_outAB = (modelica_metatype)_outAB_ext;
_outIPIV = (modelica_metatype)_outIPIV_ext;
_outB = (modelica_metatype)_outB_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outIPIV) { *out_outIPIV = _outIPIV; }
if (out_outB) { *out_outB = _outB; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outAB;
}
modelica_metatype boxptr_Lapack_dgbsv(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inKL, modelica_metatype _inKU, modelica_metatype _inNRHS, modelica_metatype _inAB, modelica_metatype _inLDAB, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype *out_outIPIV, modelica_metatype *out_outB, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer _outINFO;
modelica_metatype _outAB = NULL;
tmp1 = mmc_unbox_integer(_inN);
tmp2 = mmc_unbox_integer(_inKL);
tmp3 = mmc_unbox_integer(_inKU);
tmp4 = mmc_unbox_integer(_inNRHS);
tmp5 = mmc_unbox_integer(_inLDAB);
tmp6 = mmc_unbox_integer(_inLDB);
_outAB = omc_Lapack_dgbsv(threadData, tmp1, tmp2, tmp3, tmp4, _inAB, tmp5, _inB, tmp6, out_outIPIV, out_outB, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outAB;
}
modelica_metatype omc_Lapack_dgtsv(threadData_t *threadData, modelica_integer _inN, modelica_integer _inNRHS, modelica_metatype _inDL, modelica_metatype _inD, modelica_metatype _inDU, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype *out_outD, modelica_metatype *out_outDU, modelica_metatype *out_outB, modelica_integer *out_outINFO)
{
int _inN_ext;
int _inNRHS_ext;
modelica_metatype _inDL_ext;
modelica_metatype _inD_ext;
modelica_metatype _inDU_ext;
modelica_metatype _inB_ext;
int _inLDB_ext;
modelica_metatype _outDL_ext;
modelica_metatype _outD_ext;
modelica_metatype _outDU_ext;
modelica_metatype _outB_ext;
int _outINFO_ext;
modelica_metatype _outDL = NULL;
modelica_metatype _outD = NULL;
modelica_metatype _outDU = NULL;
modelica_metatype _outB = NULL;
modelica_integer _outINFO;
_inN_ext = (int)_inN;
_inNRHS_ext = (int)_inNRHS;
_inDL_ext = (modelica_metatype)_inDL;
_inD_ext = (modelica_metatype)_inD;
_inDU_ext = (modelica_metatype)_inDU;
_inB_ext = (modelica_metatype)_inB;
_inLDB_ext = (int)_inLDB;
LapackImpl__dgtsv(_inN_ext, _inNRHS_ext, _inDL_ext, _inD_ext, _inDU_ext, _inB_ext, _inLDB_ext, &_outDL_ext, &_outD_ext, &_outDU_ext, &_outB_ext, &_outINFO_ext);
_outDL = (modelica_metatype)_outDL_ext;
_outD = (modelica_metatype)_outD_ext;
_outDU = (modelica_metatype)_outDU_ext;
_outB = (modelica_metatype)_outB_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outD) { *out_outD = _outD; }
if (out_outDU) { *out_outDU = _outDU; }
if (out_outB) { *out_outB = _outB; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outDL;
}
modelica_metatype boxptr_Lapack_dgtsv(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inNRHS, modelica_metatype _inDL, modelica_metatype _inD, modelica_metatype _inDU, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype *out_outD, modelica_metatype *out_outDU, modelica_metatype *out_outB, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer _outINFO;
modelica_metatype _outDL = NULL;
tmp1 = mmc_unbox_integer(_inN);
tmp2 = mmc_unbox_integer(_inNRHS);
tmp3 = mmc_unbox_integer(_inLDB);
_outDL = omc_Lapack_dgtsv(threadData, tmp1, tmp2, _inDL, _inD, _inDU, _inB, tmp3, out_outD, out_outDU, out_outB, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outDL;
}
modelica_metatype omc_Lapack_dgglse(threadData_t *threadData, modelica_integer _inM, modelica_integer _inN, modelica_integer _inP, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype _inC, modelica_metatype _inD, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outB, modelica_metatype *out_outC, modelica_metatype *out_outD, modelica_metatype *out_outX, modelica_metatype *out_outWORK, modelica_integer *out_outINFO)
{
int _inM_ext;
int _inN_ext;
int _inP_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
modelica_metatype _inB_ext;
int _inLDB_ext;
modelica_metatype _inC_ext;
modelica_metatype _inD_ext;
modelica_metatype _inWORK_ext;
int _inLWORK_ext;
modelica_metatype _outA_ext;
modelica_metatype _outB_ext;
modelica_metatype _outC_ext;
modelica_metatype _outD_ext;
modelica_metatype _outX_ext;
modelica_metatype _outWORK_ext;
int _outINFO_ext;
modelica_metatype _outA = NULL;
modelica_metatype _outB = NULL;
modelica_metatype _outC = NULL;
modelica_metatype _outD = NULL;
modelica_metatype _outX = NULL;
modelica_metatype _outWORK = NULL;
modelica_integer _outINFO;
_inM_ext = (int)_inM;
_inN_ext = (int)_inN;
_inP_ext = (int)_inP;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
_inB_ext = (modelica_metatype)_inB;
_inLDB_ext = (int)_inLDB;
_inC_ext = (modelica_metatype)_inC;
_inD_ext = (modelica_metatype)_inD;
_inWORK_ext = (modelica_metatype)_inWORK;
_inLWORK_ext = (int)_inLWORK;
LapackImpl__dgglse(_inM_ext, _inN_ext, _inP_ext, _inA_ext, _inLDA_ext, _inB_ext, _inLDB_ext, _inC_ext, _inD_ext, _inWORK_ext, _inLWORK_ext, &_outA_ext, &_outB_ext, &_outC_ext, &_outD_ext, &_outX_ext, &_outWORK_ext, &_outINFO_ext);
_outA = (modelica_metatype)_outA_ext;
_outB = (modelica_metatype)_outB_ext;
_outC = (modelica_metatype)_outC_ext;
_outD = (modelica_metatype)_outD_ext;
_outX = (modelica_metatype)_outX_ext;
_outWORK = (modelica_metatype)_outWORK_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outB) { *out_outB = _outB; }
if (out_outC) { *out_outC = _outC; }
if (out_outD) { *out_outD = _outD; }
if (out_outX) { *out_outX = _outX; }
if (out_outWORK) { *out_outWORK = _outWORK; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outA;
}
modelica_metatype boxptr_Lapack_dgglse(threadData_t *threadData, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inP, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype _inC, modelica_metatype _inD, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outB, modelica_metatype *out_outC, modelica_metatype *out_outD, modelica_metatype *out_outX, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer _outINFO;
modelica_metatype _outA = NULL;
tmp1 = mmc_unbox_integer(_inM);
tmp2 = mmc_unbox_integer(_inN);
tmp3 = mmc_unbox_integer(_inP);
tmp4 = mmc_unbox_integer(_inLDA);
tmp5 = mmc_unbox_integer(_inLDB);
tmp6 = mmc_unbox_integer(_inLWORK);
_outA = omc_Lapack_dgglse(threadData, tmp1, tmp2, tmp3, _inA, tmp4, _inB, tmp5, _inC, _inD, _inWORK, tmp6, out_outB, out_outC, out_outD, out_outX, out_outWORK, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outA;
}
modelica_metatype omc_Lapack_dgesv(threadData_t *threadData, modelica_integer _inN, modelica_integer _inNRHS, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype *out_outIPIV, modelica_metatype *out_outB, modelica_integer *out_outINFO)
{
int _inN_ext;
int _inNRHS_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
modelica_metatype _inB_ext;
int _inLDB_ext;
modelica_metatype _outA_ext;
modelica_metatype _outIPIV_ext;
modelica_metatype _outB_ext;
int _outINFO_ext;
modelica_metatype _outA = NULL;
modelica_metatype _outIPIV = NULL;
modelica_metatype _outB = NULL;
modelica_integer _outINFO;
_inN_ext = (int)_inN;
_inNRHS_ext = (int)_inNRHS;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
_inB_ext = (modelica_metatype)_inB;
_inLDB_ext = (int)_inLDB;
LapackImpl__dgesv(_inN_ext, _inNRHS_ext, _inA_ext, _inLDA_ext, _inB_ext, _inLDB_ext, &_outA_ext, &_outIPIV_ext, &_outB_ext, &_outINFO_ext);
_outA = (modelica_metatype)_outA_ext;
_outIPIV = (modelica_metatype)_outIPIV_ext;
_outB = (modelica_metatype)_outB_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outIPIV) { *out_outIPIV = _outIPIV; }
if (out_outB) { *out_outB = _outB; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outA;
}
modelica_metatype boxptr_Lapack_dgesv(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inNRHS, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype *out_outIPIV, modelica_metatype *out_outB, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer _outINFO;
modelica_metatype _outA = NULL;
tmp1 = mmc_unbox_integer(_inN);
tmp2 = mmc_unbox_integer(_inNRHS);
tmp3 = mmc_unbox_integer(_inLDA);
tmp4 = mmc_unbox_integer(_inLDB);
_outA = omc_Lapack_dgesv(threadData, tmp1, tmp2, _inA, tmp3, _inB, tmp4, out_outIPIV, out_outB, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outA;
}
modelica_metatype omc_Lapack_dgelsy(threadData_t *threadData, modelica_integer _inM, modelica_integer _inN, modelica_integer _inNRHS, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype _inJPVT, modelica_real _inRCOND, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outB, modelica_metatype *out_outJPVT, modelica_integer *out_outRANK, modelica_metatype *out_outWORK, modelica_integer *out_outINFO)
{
int _inM_ext;
int _inN_ext;
int _inNRHS_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
modelica_metatype _inB_ext;
int _inLDB_ext;
modelica_metatype _inJPVT_ext;
double _inRCOND_ext;
modelica_metatype _inWORK_ext;
int _inLWORK_ext;
modelica_metatype _outA_ext;
modelica_metatype _outB_ext;
modelica_metatype _outJPVT_ext;
int _outRANK_ext;
modelica_metatype _outWORK_ext;
int _outINFO_ext;
modelica_metatype _outA = NULL;
modelica_metatype _outB = NULL;
modelica_metatype _outJPVT = NULL;
modelica_integer _outRANK;
modelica_metatype _outWORK = NULL;
modelica_integer _outINFO;
_inM_ext = (int)_inM;
_inN_ext = (int)_inN;
_inNRHS_ext = (int)_inNRHS;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
_inB_ext = (modelica_metatype)_inB;
_inLDB_ext = (int)_inLDB;
_inJPVT_ext = (modelica_metatype)_inJPVT;
_inRCOND_ext = (double)_inRCOND;
_inWORK_ext = (modelica_metatype)_inWORK;
_inLWORK_ext = (int)_inLWORK;
LapackImpl__dgelsy(_inM_ext, _inN_ext, _inNRHS_ext, _inA_ext, _inLDA_ext, _inB_ext, _inLDB_ext, _inJPVT_ext, _inRCOND_ext, _inWORK_ext, _inLWORK_ext, &_outA_ext, &_outB_ext, &_outJPVT_ext, &_outRANK_ext, &_outWORK_ext, &_outINFO_ext);
_outA = (modelica_metatype)_outA_ext;
_outB = (modelica_metatype)_outB_ext;
_outJPVT = (modelica_metatype)_outJPVT_ext;
_outRANK = (modelica_integer)_outRANK_ext;
_outWORK = (modelica_metatype)_outWORK_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outB) { *out_outB = _outB; }
if (out_outJPVT) { *out_outJPVT = _outJPVT; }
if (out_outRANK) { *out_outRANK = _outRANK; }
if (out_outWORK) { *out_outWORK = _outWORK; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outA;
}
modelica_metatype boxptr_Lapack_dgelsy(threadData_t *threadData, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inNRHS, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype _inJPVT, modelica_metatype _inRCOND, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outB, modelica_metatype *out_outJPVT, modelica_metatype *out_outRANK, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_real tmp6;
modelica_integer tmp7;
modelica_integer _outRANK;
modelica_integer _outINFO;
modelica_metatype _outA = NULL;
tmp1 = mmc_unbox_integer(_inM);
tmp2 = mmc_unbox_integer(_inN);
tmp3 = mmc_unbox_integer(_inNRHS);
tmp4 = mmc_unbox_integer(_inLDA);
tmp5 = mmc_unbox_integer(_inLDB);
tmp6 = mmc_unbox_real(_inRCOND);
tmp7 = mmc_unbox_integer(_inLWORK);
_outA = omc_Lapack_dgelsy(threadData, tmp1, tmp2, tmp3, _inA, tmp4, _inB, tmp5, _inJPVT, tmp6, _inWORK, tmp7, out_outB, out_outJPVT, &_outRANK, out_outWORK, &_outINFO);
if (out_outRANK) { *out_outRANK = mmc_mk_icon(_outRANK); }
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outA;
}
modelica_metatype omc_Lapack_dgelsx(threadData_t *threadData, modelica_integer _inM, modelica_integer _inN, modelica_integer _inNRHS, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype _inJPVT, modelica_real _inRCOND, modelica_metatype _inWORK, modelica_metatype *out_outB, modelica_metatype *out_outJPVT, modelica_integer *out_outRANK, modelica_integer *out_outINFO)
{
int _inM_ext;
int _inN_ext;
int _inNRHS_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
modelica_metatype _inB_ext;
int _inLDB_ext;
modelica_metatype _inJPVT_ext;
double _inRCOND_ext;
modelica_metatype _inWORK_ext;
modelica_metatype _outA_ext;
modelica_metatype _outB_ext;
modelica_metatype _outJPVT_ext;
int _outRANK_ext;
int _outINFO_ext;
modelica_metatype _outA = NULL;
modelica_metatype _outB = NULL;
modelica_metatype _outJPVT = NULL;
modelica_integer _outRANK;
modelica_integer _outINFO;
_inM_ext = (int)_inM;
_inN_ext = (int)_inN;
_inNRHS_ext = (int)_inNRHS;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
_inB_ext = (modelica_metatype)_inB;
_inLDB_ext = (int)_inLDB;
_inJPVT_ext = (modelica_metatype)_inJPVT;
_inRCOND_ext = (double)_inRCOND;
_inWORK_ext = (modelica_metatype)_inWORK;
LapackImpl__dgelsx(_inM_ext, _inN_ext, _inNRHS_ext, _inA_ext, _inLDA_ext, _inB_ext, _inLDB_ext, _inJPVT_ext, _inRCOND_ext, _inWORK_ext, &_outA_ext, &_outB_ext, &_outJPVT_ext, &_outRANK_ext, &_outINFO_ext);
_outA = (modelica_metatype)_outA_ext;
_outB = (modelica_metatype)_outB_ext;
_outJPVT = (modelica_metatype)_outJPVT_ext;
_outRANK = (modelica_integer)_outRANK_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outB) { *out_outB = _outB; }
if (out_outJPVT) { *out_outJPVT = _outJPVT; }
if (out_outRANK) { *out_outRANK = _outRANK; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outA;
}
modelica_metatype boxptr_Lapack_dgelsx(threadData_t *threadData, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inNRHS, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype _inJPVT, modelica_metatype _inRCOND, modelica_metatype _inWORK, modelica_metatype *out_outB, modelica_metatype *out_outJPVT, modelica_metatype *out_outRANK, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_real tmp6;
modelica_integer _outRANK;
modelica_integer _outINFO;
modelica_metatype _outA = NULL;
tmp1 = mmc_unbox_integer(_inM);
tmp2 = mmc_unbox_integer(_inN);
tmp3 = mmc_unbox_integer(_inNRHS);
tmp4 = mmc_unbox_integer(_inLDA);
tmp5 = mmc_unbox_integer(_inLDB);
tmp6 = mmc_unbox_real(_inRCOND);
_outA = omc_Lapack_dgelsx(threadData, tmp1, tmp2, tmp3, _inA, tmp4, _inB, tmp5, _inJPVT, tmp6, _inWORK, out_outB, out_outJPVT, &_outRANK, &_outINFO);
if (out_outRANK) { *out_outRANK = mmc_mk_icon(_outRANK); }
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outA;
}
modelica_metatype omc_Lapack_dgels(threadData_t *threadData, modelica_string _inTRANS, modelica_integer _inM, modelica_integer _inN, modelica_integer _inNRHS, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outB, modelica_metatype *out_outWORK, modelica_integer *out_outINFO)
{
int _inM_ext;
int _inN_ext;
int _inNRHS_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
modelica_metatype _inB_ext;
int _inLDB_ext;
modelica_metatype _inWORK_ext;
int _inLWORK_ext;
modelica_metatype _outA_ext;
modelica_metatype _outB_ext;
modelica_metatype _outWORK_ext;
int _outINFO_ext;
modelica_metatype _outA = NULL;
modelica_metatype _outB = NULL;
modelica_metatype _outWORK = NULL;
modelica_integer _outINFO;
_inM_ext = (int)_inM;
_inN_ext = (int)_inN;
_inNRHS_ext = (int)_inNRHS;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
_inB_ext = (modelica_metatype)_inB;
_inLDB_ext = (int)_inLDB;
_inWORK_ext = (modelica_metatype)_inWORK;
_inLWORK_ext = (int)_inLWORK;
LapackImpl__dgels(MMC_STRINGDATA(_inTRANS), _inM_ext, _inN_ext, _inNRHS_ext, _inA_ext, _inLDA_ext, _inB_ext, _inLDB_ext, _inWORK_ext, _inLWORK_ext, &_outA_ext, &_outB_ext, &_outWORK_ext, &_outINFO_ext);
_outA = (modelica_metatype)_outA_ext;
_outB = (modelica_metatype)_outB_ext;
_outWORK = (modelica_metatype)_outWORK_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outB) { *out_outB = _outB; }
if (out_outWORK) { *out_outWORK = _outWORK; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outA;
}
modelica_metatype boxptr_Lapack_dgels(threadData_t *threadData, modelica_metatype _inTRANS, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inNRHS, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outB, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer _outINFO;
modelica_metatype _outA = NULL;
tmp1 = mmc_unbox_integer(_inM);
tmp2 = mmc_unbox_integer(_inN);
tmp3 = mmc_unbox_integer(_inNRHS);
tmp4 = mmc_unbox_integer(_inLDA);
tmp5 = mmc_unbox_integer(_inLDB);
tmp6 = mmc_unbox_integer(_inLWORK);
_outA = omc_Lapack_dgels(threadData, _inTRANS, tmp1, tmp2, tmp3, _inA, tmp4, _inB, tmp5, _inWORK, tmp6, out_outB, out_outWORK, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outA;
}
modelica_metatype omc_Lapack_dgegv(threadData_t *threadData, modelica_string _inJOBVL, modelica_string _inJOBVR, modelica_integer _inN, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inB, modelica_integer _inLDB, modelica_integer _inLDVL, modelica_integer _inLDVR, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outALPHAI, modelica_metatype *out_outBETA, modelica_metatype *out_outVL, modelica_metatype *out_outVR, modelica_metatype *out_outWORK, modelica_integer *out_outINFO)
{
int _inN_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
modelica_metatype _inB_ext;
int _inLDB_ext;
int _inLDVL_ext;
int _inLDVR_ext;
modelica_metatype _inWORK_ext;
int _inLWORK_ext;
modelica_metatype _outALPHAR_ext;
modelica_metatype _outALPHAI_ext;
modelica_metatype _outBETA_ext;
modelica_metatype _outVL_ext;
modelica_metatype _outVR_ext;
modelica_metatype _outWORK_ext;
int _outINFO_ext;
modelica_metatype _outALPHAR = NULL;
modelica_metatype _outALPHAI = NULL;
modelica_metatype _outBETA = NULL;
modelica_metatype _outVL = NULL;
modelica_metatype _outVR = NULL;
modelica_metatype _outWORK = NULL;
modelica_integer _outINFO;
_inN_ext = (int)_inN;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
_inB_ext = (modelica_metatype)_inB;
_inLDB_ext = (int)_inLDB;
_inLDVL_ext = (int)_inLDVL;
_inLDVR_ext = (int)_inLDVR;
_inWORK_ext = (modelica_metatype)_inWORK;
_inLWORK_ext = (int)_inLWORK;
LapackImpl__dgegv(MMC_STRINGDATA(_inJOBVL), MMC_STRINGDATA(_inJOBVR), _inN_ext, _inA_ext, _inLDA_ext, _inB_ext, _inLDB_ext, _inLDVL_ext, _inLDVR_ext, _inWORK_ext, _inLWORK_ext, &_outALPHAR_ext, &_outALPHAI_ext, &_outBETA_ext, &_outVL_ext, &_outVR_ext, &_outWORK_ext, &_outINFO_ext);
_outALPHAR = (modelica_metatype)_outALPHAR_ext;
_outALPHAI = (modelica_metatype)_outALPHAI_ext;
_outBETA = (modelica_metatype)_outBETA_ext;
_outVL = (modelica_metatype)_outVL_ext;
_outVR = (modelica_metatype)_outVR_ext;
_outWORK = (modelica_metatype)_outWORK_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outALPHAI) { *out_outALPHAI = _outALPHAI; }
if (out_outBETA) { *out_outBETA = _outBETA; }
if (out_outVL) { *out_outVL = _outVL; }
if (out_outVR) { *out_outVR = _outVR; }
if (out_outWORK) { *out_outWORK = _outWORK; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outALPHAR;
}
modelica_metatype boxptr_Lapack_dgegv(threadData_t *threadData, modelica_metatype _inJOBVL, modelica_metatype _inJOBVR, modelica_metatype _inN, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype _inLDVL, modelica_metatype _inLDVR, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outALPHAI, modelica_metatype *out_outBETA, modelica_metatype *out_outVL, modelica_metatype *out_outVR, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer _outINFO;
modelica_metatype _outALPHAR = NULL;
tmp1 = mmc_unbox_integer(_inN);
tmp2 = mmc_unbox_integer(_inLDA);
tmp3 = mmc_unbox_integer(_inLDB);
tmp4 = mmc_unbox_integer(_inLDVL);
tmp5 = mmc_unbox_integer(_inLDVR);
tmp6 = mmc_unbox_integer(_inLWORK);
_outALPHAR = omc_Lapack_dgegv(threadData, _inJOBVL, _inJOBVR, tmp1, _inA, tmp2, _inB, tmp3, tmp4, tmp5, _inWORK, tmp6, out_outALPHAI, out_outBETA, out_outVL, out_outVR, out_outWORK, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outALPHAR;
}
modelica_metatype omc_Lapack_dgeev(threadData_t *threadData, modelica_string _inJOBVL, modelica_string _inJOBVR, modelica_integer _inN, modelica_metatype _inA, modelica_integer _inLDA, modelica_integer _inLDVL, modelica_integer _inLDVR, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outWR, modelica_metatype *out_outWI, modelica_metatype *out_outVL, modelica_metatype *out_outVR, modelica_metatype *out_outWORK, modelica_integer *out_outINFO)
{
int _inN_ext;
modelica_metatype _inA_ext;
int _inLDA_ext;
int _inLDVL_ext;
int _inLDVR_ext;
modelica_metatype _inWORK_ext;
int _inLWORK_ext;
modelica_metatype _outA_ext;
modelica_metatype _outWR_ext;
modelica_metatype _outWI_ext;
modelica_metatype _outVL_ext;
modelica_metatype _outVR_ext;
modelica_metatype _outWORK_ext;
int _outINFO_ext;
modelica_metatype _outA = NULL;
modelica_metatype _outWR = NULL;
modelica_metatype _outWI = NULL;
modelica_metatype _outVL = NULL;
modelica_metatype _outVR = NULL;
modelica_metatype _outWORK = NULL;
modelica_integer _outINFO;
_inN_ext = (int)_inN;
_inA_ext = (modelica_metatype)_inA;
_inLDA_ext = (int)_inLDA;
_inLDVL_ext = (int)_inLDVL;
_inLDVR_ext = (int)_inLDVR;
_inWORK_ext = (modelica_metatype)_inWORK;
_inLWORK_ext = (int)_inLWORK;
LapackImpl__dgeev(MMC_STRINGDATA(_inJOBVL), MMC_STRINGDATA(_inJOBVR), _inN_ext, _inA_ext, _inLDA_ext, _inLDVL_ext, _inLDVR_ext, _inWORK_ext, _inLWORK_ext, &_outA_ext, &_outWR_ext, &_outWI_ext, &_outVL_ext, &_outVR_ext, &_outWORK_ext, &_outINFO_ext);
_outA = (modelica_metatype)_outA_ext;
_outWR = (modelica_metatype)_outWR_ext;
_outWI = (modelica_metatype)_outWI_ext;
_outVL = (modelica_metatype)_outVL_ext;
_outVR = (modelica_metatype)_outVR_ext;
_outWORK = (modelica_metatype)_outWORK_ext;
_outINFO = (modelica_integer)_outINFO_ext;
if (out_outWR) { *out_outWR = _outWR; }
if (out_outWI) { *out_outWI = _outWI; }
if (out_outVL) { *out_outVL = _outVL; }
if (out_outVR) { *out_outVR = _outVR; }
if (out_outWORK) { *out_outWORK = _outWORK; }
if (out_outINFO) { *out_outINFO = _outINFO; }
return _outA;
}
modelica_metatype boxptr_Lapack_dgeev(threadData_t *threadData, modelica_metatype _inJOBVL, modelica_metatype _inJOBVR, modelica_metatype _inN, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inLDVL, modelica_metatype _inLDVR, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outWR, modelica_metatype *out_outWI, modelica_metatype *out_outVL, modelica_metatype *out_outVR, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer _outINFO;
modelica_metatype _outA = NULL;
tmp1 = mmc_unbox_integer(_inN);
tmp2 = mmc_unbox_integer(_inLDA);
tmp3 = mmc_unbox_integer(_inLDVL);
tmp4 = mmc_unbox_integer(_inLDVR);
tmp5 = mmc_unbox_integer(_inLWORK);
_outA = omc_Lapack_dgeev(threadData, _inJOBVL, _inJOBVR, tmp1, _inA, tmp2, tmp3, tmp4, _inWORK, tmp5, out_outWR, out_outWI, out_outVL, out_outVR, out_outWORK, &_outINFO);
if (out_outINFO) { *out_outINFO = mmc_mk_icon(_outINFO); }
return _outA;
}

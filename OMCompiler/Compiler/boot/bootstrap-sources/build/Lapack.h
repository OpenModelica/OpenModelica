#ifndef Lapack__H
#define Lapack__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_Lapack_dorgqr(threadData_t *threadData, modelica_integer _inM, modelica_integer _inN, modelica_integer _inK, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inTAU, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outWORK, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dorgqr(threadData_t *threadData, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inK, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inTAU, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dorgqr,2,0) {(void*) boxptr_Lapack_dorgqr,0}};
#define boxvar_Lapack_dorgqr MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dorgqr)
extern void LapackImpl__dorgqr(int /*_inM*/, int /*_inN*/, int /*_inK*/, modelica_metatype /*_inA*/, int /*_inLDA*/, modelica_metatype /*_inTAU*/, modelica_metatype /*_inWORK*/, int /*_inLWORK*/, modelica_metatype* /*_outA*/, modelica_metatype* /*_outWORK*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgeqpf(threadData_t *threadData, modelica_integer _inM, modelica_integer _inN, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inJPVT, modelica_metatype _inWORK, modelica_metatype *out_outJPVT, modelica_metatype *out_outTAU, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgeqpf(threadData_t *threadData, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inJPVT, modelica_metatype _inWORK, modelica_metatype *out_outJPVT, modelica_metatype *out_outTAU, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgeqpf,2,0) {(void*) boxptr_Lapack_dgeqpf,0}};
#define boxvar_Lapack_dgeqpf MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgeqpf)
extern void LapackImpl__dgeqpf(int /*_inM*/, int /*_inN*/, modelica_metatype /*_inA*/, int /*_inLDA*/, modelica_metatype /*_inJPVT*/, modelica_metatype /*_inWORK*/, modelica_metatype* /*_outA*/, modelica_metatype* /*_outJPVT*/, modelica_metatype* /*_outTAU*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgetri(threadData_t *threadData, modelica_integer _inN, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inIPIV, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outWORK, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgetri(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inIPIV, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgetri,2,0) {(void*) boxptr_Lapack_dgetri,0}};
#define boxvar_Lapack_dgetri MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgetri)
extern void LapackImpl__dgetri(int /*_inN*/, modelica_metatype /*_inA*/, int /*_inLDA*/, modelica_metatype /*_inIPIV*/, modelica_metatype /*_inWORK*/, int /*_inLWORK*/, modelica_metatype* /*_outA*/, modelica_metatype* /*_outWORK*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgetrs(threadData_t *threadData, modelica_string _inTRANS, modelica_integer _inN, modelica_integer _inNRHS, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inIPIV, modelica_metatype _inB, modelica_integer _inLDB, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgetrs(threadData_t *threadData, modelica_metatype _inTRANS, modelica_metatype _inN, modelica_metatype _inNRHS, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inIPIV, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgetrs,2,0) {(void*) boxptr_Lapack_dgetrs,0}};
#define boxvar_Lapack_dgetrs MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgetrs)
extern void LapackImpl__dgetrs(const char* /*_inTRANS*/, int /*_inN*/, int /*_inNRHS*/, modelica_metatype /*_inA*/, int /*_inLDA*/, modelica_metatype /*_inIPIV*/, modelica_metatype /*_inB*/, int /*_inLDB*/, modelica_metatype* /*_outB*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgetrf(threadData_t *threadData, modelica_integer _inM, modelica_integer _inN, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype *out_outIPIV, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgetrf(threadData_t *threadData, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype *out_outIPIV, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgetrf,2,0) {(void*) boxptr_Lapack_dgetrf,0}};
#define boxvar_Lapack_dgetrf MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgetrf)
extern void LapackImpl__dgetrf(int /*_inM*/, int /*_inN*/, modelica_metatype /*_inA*/, int /*_inLDA*/, modelica_metatype* /*_outA*/, modelica_metatype* /*_outIPIV*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgesvd(threadData_t *threadData, modelica_string _inJOBU, modelica_string _inJOBVT, modelica_integer _inM, modelica_integer _inN, modelica_metatype _inA, modelica_integer _inLDA, modelica_integer _inLDU, modelica_integer _inLDVT, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outS, modelica_metatype *out_outU, modelica_metatype *out_outVT, modelica_metatype *out_outWORK, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgesvd(threadData_t *threadData, modelica_metatype _inJOBU, modelica_metatype _inJOBVT, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inLDU, modelica_metatype _inLDVT, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outS, modelica_metatype *out_outU, modelica_metatype *out_outVT, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgesvd,2,0) {(void*) boxptr_Lapack_dgesvd,0}};
#define boxvar_Lapack_dgesvd MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgesvd)
extern void LapackImpl__dgesvd(const char* /*_inJOBU*/, const char* /*_inJOBVT*/, int /*_inM*/, int /*_inN*/, modelica_metatype /*_inA*/, int /*_inLDA*/, int /*_inLDU*/, int /*_inLDVT*/, modelica_metatype /*_inWORK*/, int /*_inLWORK*/, modelica_metatype* /*_outA*/, modelica_metatype* /*_outS*/, modelica_metatype* /*_outU*/, modelica_metatype* /*_outVT*/, modelica_metatype* /*_outWORK*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgbsv(threadData_t *threadData, modelica_integer _inN, modelica_integer _inKL, modelica_integer _inKU, modelica_integer _inNRHS, modelica_metatype _inAB, modelica_integer _inLDAB, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype *out_outIPIV, modelica_metatype *out_outB, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgbsv(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inKL, modelica_metatype _inKU, modelica_metatype _inNRHS, modelica_metatype _inAB, modelica_metatype _inLDAB, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype *out_outIPIV, modelica_metatype *out_outB, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgbsv,2,0) {(void*) boxptr_Lapack_dgbsv,0}};
#define boxvar_Lapack_dgbsv MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgbsv)
extern void LapackImpl__dgbsv(int /*_inN*/, int /*_inKL*/, int /*_inKU*/, int /*_inNRHS*/, modelica_metatype /*_inAB*/, int /*_inLDAB*/, modelica_metatype /*_inB*/, int /*_inLDB*/, modelica_metatype* /*_outAB*/, modelica_metatype* /*_outIPIV*/, modelica_metatype* /*_outB*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgtsv(threadData_t *threadData, modelica_integer _inN, modelica_integer _inNRHS, modelica_metatype _inDL, modelica_metatype _inD, modelica_metatype _inDU, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype *out_outD, modelica_metatype *out_outDU, modelica_metatype *out_outB, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgtsv(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inNRHS, modelica_metatype _inDL, modelica_metatype _inD, modelica_metatype _inDU, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype *out_outD, modelica_metatype *out_outDU, modelica_metatype *out_outB, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgtsv,2,0) {(void*) boxptr_Lapack_dgtsv,0}};
#define boxvar_Lapack_dgtsv MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgtsv)
extern void LapackImpl__dgtsv(int /*_inN*/, int /*_inNRHS*/, modelica_metatype /*_inDL*/, modelica_metatype /*_inD*/, modelica_metatype /*_inDU*/, modelica_metatype /*_inB*/, int /*_inLDB*/, modelica_metatype* /*_outDL*/, modelica_metatype* /*_outD*/, modelica_metatype* /*_outDU*/, modelica_metatype* /*_outB*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgglse(threadData_t *threadData, modelica_integer _inM, modelica_integer _inN, modelica_integer _inP, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype _inC, modelica_metatype _inD, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outB, modelica_metatype *out_outC, modelica_metatype *out_outD, modelica_metatype *out_outX, modelica_metatype *out_outWORK, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgglse(threadData_t *threadData, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inP, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype _inC, modelica_metatype _inD, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outB, modelica_metatype *out_outC, modelica_metatype *out_outD, modelica_metatype *out_outX, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgglse,2,0) {(void*) boxptr_Lapack_dgglse,0}};
#define boxvar_Lapack_dgglse MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgglse)
extern void LapackImpl__dgglse(int /*_inM*/, int /*_inN*/, int /*_inP*/, modelica_metatype /*_inA*/, int /*_inLDA*/, modelica_metatype /*_inB*/, int /*_inLDB*/, modelica_metatype /*_inC*/, modelica_metatype /*_inD*/, modelica_metatype /*_inWORK*/, int /*_inLWORK*/, modelica_metatype* /*_outA*/, modelica_metatype* /*_outB*/, modelica_metatype* /*_outC*/, modelica_metatype* /*_outD*/, modelica_metatype* /*_outX*/, modelica_metatype* /*_outWORK*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgesv(threadData_t *threadData, modelica_integer _inN, modelica_integer _inNRHS, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype *out_outIPIV, modelica_metatype *out_outB, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgesv(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inNRHS, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype *out_outIPIV, modelica_metatype *out_outB, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgesv,2,0) {(void*) boxptr_Lapack_dgesv,0}};
#define boxvar_Lapack_dgesv MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgesv)
extern void LapackImpl__dgesv(int /*_inN*/, int /*_inNRHS*/, modelica_metatype /*_inA*/, int /*_inLDA*/, modelica_metatype /*_inB*/, int /*_inLDB*/, modelica_metatype* /*_outA*/, modelica_metatype* /*_outIPIV*/, modelica_metatype* /*_outB*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgelsy(threadData_t *threadData, modelica_integer _inM, modelica_integer _inN, modelica_integer _inNRHS, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype _inJPVT, modelica_real _inRCOND, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outB, modelica_metatype *out_outJPVT, modelica_integer *out_outRANK, modelica_metatype *out_outWORK, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgelsy(threadData_t *threadData, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inNRHS, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype _inJPVT, modelica_metatype _inRCOND, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outB, modelica_metatype *out_outJPVT, modelica_metatype *out_outRANK, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgelsy,2,0) {(void*) boxptr_Lapack_dgelsy,0}};
#define boxvar_Lapack_dgelsy MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgelsy)
extern void LapackImpl__dgelsy(int /*_inM*/, int /*_inN*/, int /*_inNRHS*/, modelica_metatype /*_inA*/, int /*_inLDA*/, modelica_metatype /*_inB*/, int /*_inLDB*/, modelica_metatype /*_inJPVT*/, double /*_inRCOND*/, modelica_metatype /*_inWORK*/, int /*_inLWORK*/, modelica_metatype* /*_outA*/, modelica_metatype* /*_outB*/, modelica_metatype* /*_outJPVT*/, int* /*_outRANK*/, modelica_metatype* /*_outWORK*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgelsx(threadData_t *threadData, modelica_integer _inM, modelica_integer _inN, modelica_integer _inNRHS, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype _inJPVT, modelica_real _inRCOND, modelica_metatype _inWORK, modelica_metatype *out_outB, modelica_metatype *out_outJPVT, modelica_integer *out_outRANK, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgelsx(threadData_t *threadData, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inNRHS, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype _inJPVT, modelica_metatype _inRCOND, modelica_metatype _inWORK, modelica_metatype *out_outB, modelica_metatype *out_outJPVT, modelica_metatype *out_outRANK, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgelsx,2,0) {(void*) boxptr_Lapack_dgelsx,0}};
#define boxvar_Lapack_dgelsx MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgelsx)
extern void LapackImpl__dgelsx(int /*_inM*/, int /*_inN*/, int /*_inNRHS*/, modelica_metatype /*_inA*/, int /*_inLDA*/, modelica_metatype /*_inB*/, int /*_inLDB*/, modelica_metatype /*_inJPVT*/, double /*_inRCOND*/, modelica_metatype /*_inWORK*/, modelica_metatype* /*_outA*/, modelica_metatype* /*_outB*/, modelica_metatype* /*_outJPVT*/, int* /*_outRANK*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgels(threadData_t *threadData, modelica_string _inTRANS, modelica_integer _inM, modelica_integer _inN, modelica_integer _inNRHS, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inB, modelica_integer _inLDB, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outB, modelica_metatype *out_outWORK, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgels(threadData_t *threadData, modelica_metatype _inTRANS, modelica_metatype _inM, modelica_metatype _inN, modelica_metatype _inNRHS, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outB, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgels,2,0) {(void*) boxptr_Lapack_dgels,0}};
#define boxvar_Lapack_dgels MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgels)
extern void LapackImpl__dgels(const char* /*_inTRANS*/, int /*_inM*/, int /*_inN*/, int /*_inNRHS*/, modelica_metatype /*_inA*/, int /*_inLDA*/, modelica_metatype /*_inB*/, int /*_inLDB*/, modelica_metatype /*_inWORK*/, int /*_inLWORK*/, modelica_metatype* /*_outA*/, modelica_metatype* /*_outB*/, modelica_metatype* /*_outWORK*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgegv(threadData_t *threadData, modelica_string _inJOBVL, modelica_string _inJOBVR, modelica_integer _inN, modelica_metatype _inA, modelica_integer _inLDA, modelica_metatype _inB, modelica_integer _inLDB, modelica_integer _inLDVL, modelica_integer _inLDVR, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outALPHAI, modelica_metatype *out_outBETA, modelica_metatype *out_outVL, modelica_metatype *out_outVR, modelica_metatype *out_outWORK, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgegv(threadData_t *threadData, modelica_metatype _inJOBVL, modelica_metatype _inJOBVR, modelica_metatype _inN, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inB, modelica_metatype _inLDB, modelica_metatype _inLDVL, modelica_metatype _inLDVR, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outALPHAI, modelica_metatype *out_outBETA, modelica_metatype *out_outVL, modelica_metatype *out_outVR, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgegv,2,0) {(void*) boxptr_Lapack_dgegv,0}};
#define boxvar_Lapack_dgegv MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgegv)
extern void LapackImpl__dgegv(const char* /*_inJOBVL*/, const char* /*_inJOBVR*/, int /*_inN*/, modelica_metatype /*_inA*/, int /*_inLDA*/, modelica_metatype /*_inB*/, int /*_inLDB*/, int /*_inLDVL*/, int /*_inLDVR*/, modelica_metatype /*_inWORK*/, int /*_inLWORK*/, modelica_metatype* /*_outALPHAR*/, modelica_metatype* /*_outALPHAI*/, modelica_metatype* /*_outBETA*/, modelica_metatype* /*_outVL*/, modelica_metatype* /*_outVR*/, modelica_metatype* /*_outWORK*/, int* /*_outINFO*/);
DLLExport
modelica_metatype omc_Lapack_dgeev(threadData_t *threadData, modelica_string _inJOBVL, modelica_string _inJOBVR, modelica_integer _inN, modelica_metatype _inA, modelica_integer _inLDA, modelica_integer _inLDVL, modelica_integer _inLDVR, modelica_metatype _inWORK, modelica_integer _inLWORK, modelica_metatype *out_outWR, modelica_metatype *out_outWI, modelica_metatype *out_outVL, modelica_metatype *out_outVR, modelica_metatype *out_outWORK, modelica_integer *out_outINFO);
DLLExport
modelica_metatype boxptr_Lapack_dgeev(threadData_t *threadData, modelica_metatype _inJOBVL, modelica_metatype _inJOBVR, modelica_metatype _inN, modelica_metatype _inA, modelica_metatype _inLDA, modelica_metatype _inLDVL, modelica_metatype _inLDVR, modelica_metatype _inWORK, modelica_metatype _inLWORK, modelica_metatype *out_outWR, modelica_metatype *out_outWI, modelica_metatype *out_outVL, modelica_metatype *out_outVR, modelica_metatype *out_outWORK, modelica_metatype *out_outINFO);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lapack_dgeev,2,0) {(void*) boxptr_Lapack_dgeev,0}};
#define boxvar_Lapack_dgeev MMC_REFSTRUCTLIT(boxvar_lit_Lapack_dgeev)
extern void LapackImpl__dgeev(const char* /*_inJOBVL*/, const char* /*_inJOBVR*/, int /*_inN*/, modelica_metatype /*_inA*/, int /*_inLDA*/, int /*_inLDVL*/, int /*_inLDVR*/, modelica_metatype /*_inWORK*/, int /*_inLWORK*/, modelica_metatype* /*_outA*/, modelica_metatype* /*_outWR*/, modelica_metatype* /*_outWI*/, modelica_metatype* /*_outVL*/, modelica_metatype* /*_outVR*/, modelica_metatype* /*_outWORK*/, int* /*_outINFO*/);
#ifdef __cplusplus
}
#endif
#endif

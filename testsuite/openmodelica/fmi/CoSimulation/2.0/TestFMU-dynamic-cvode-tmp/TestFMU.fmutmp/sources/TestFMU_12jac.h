/* Jacobians */
static const REAL_ATTRIBUTE dummyREAL_ATTRIBUTE = omc_dummyRealAttribute;

#if defined(__cplusplus)
extern "C" {
#endif

/* Jacobian Variables */
#define TestFMU_INDEX_JAC_H 0
int TestFMU_functionJacH_column(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *thisJacobian, ANALYTIC_JACOBIAN *parentJacobian);
int TestFMU_initialAnalyticJacobianH(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian);


#define TestFMU_INDEX_JAC_F 1
int TestFMU_functionJacF_column(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *thisJacobian, ANALYTIC_JACOBIAN *parentJacobian);
int TestFMU_initialAnalyticJacobianF(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian);


#define TestFMU_INDEX_JAC_D 2
int TestFMU_functionJacD_column(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *thisJacobian, ANALYTIC_JACOBIAN *parentJacobian);
int TestFMU_initialAnalyticJacobianD(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian);


#define TestFMU_INDEX_JAC_C 3
int TestFMU_functionJacC_column(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *thisJacobian, ANALYTIC_JACOBIAN *parentJacobian);
int TestFMU_initialAnalyticJacobianC(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian);


#define TestFMU_INDEX_JAC_B 4
int TestFMU_functionJacB_column(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *thisJacobian, ANALYTIC_JACOBIAN *parentJacobian);
int TestFMU_initialAnalyticJacobianB(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian);


#define TestFMU_INDEX_JAC_A 5
int TestFMU_functionJacA_column(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *thisJacobian, ANALYTIC_JACOBIAN *parentJacobian);
int TestFMU_initialAnalyticJacobianA(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian);

#if defined(__cplusplus)
}
#endif


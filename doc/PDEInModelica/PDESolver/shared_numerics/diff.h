//enum DScheme {lax_friedrichs, forwardT_forwardS, forwardT_backwardS};

#ifdef __cplusplus
extern "C" {
#endif
extern int differentiateX(double* y, double* yp, struct MODEL_DATA* mData, int dScheme);
#ifdef __cplusplus
}
#endif

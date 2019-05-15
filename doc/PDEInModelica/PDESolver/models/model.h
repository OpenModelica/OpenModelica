#ifdef __cplusplus
extern "C" {
    extern int setupArrayDimensions(MODEL_DATA* mData);
    extern int setupModelParameters(struct MODEL_DATA* mData);
    extern int setupInitialState(struct MODEL_DATA* mData);
    extern double shapeFunction(struct MODEL_DATA *mData, double v);
    extern int functionPDE(struct MODEL_DATA *mData, int dScheme);
    extern int functionBC(struct MODEL_DATA *mData);
//    extern double eqSystemMaxEigenVal(MODEL_DATA* mData);
}
#endif


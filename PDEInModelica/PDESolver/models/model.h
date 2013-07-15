#ifdef __cplusplus
extern "C" {
  extern int setupArrayDimensions(DATA* data);
  extern int setupModel(struct DATA* data);
  extern double shapeFunction(struct DATA *data, double v);
  extern int functionPDE(struct DATA *data);
  extern int functionBC(struct DATA *data);
}
#endif


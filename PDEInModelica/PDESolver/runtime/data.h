
struct DoublePair {
  double v0;
  double v1;
};

struct DATA {
  int M;        //number of grid points
  int nStateFields;
  int nAlgebraicFields;
  int nParameterFields;
  int nParameters;
  int nDomainSegments;
  struct DoublePair* domainRange; //range of shape-function parameter forming the domain. First pair describes the interior, than follow the boundaries
  double* stateFields;//[M][nStatesPDE];
  double* stateFieldsDerTime;//[M][nStatesPDE];
  double* stateFieldsDerSpace;//[M][nStatesPDE];
  double* algebraicFields;//[M][nAlgebraicsPDE];
  double* parameterFields;//[M][nParametersPDE];
  double* spaceField;//[M];  space independent variable (x)
  int*   isBc;//[nStatesPDE][2];//[indexOfState][left-right] Is there a BC?
  double* parameters;//[nParameters];
  double time;
};


int initializeData(struct DATA *d);
int freeData(struct DATA *d);

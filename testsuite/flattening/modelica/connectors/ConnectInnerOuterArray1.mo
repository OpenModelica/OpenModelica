// name:     ConnectInnerOuterArray1
// keywords: connect inner outer array #2793
// status:   correct
//
// Checks that inner/outer works when connecting connectors in arrays.
//

connector C
  Real e;
  flow Real f;
end C;

model InnerOuterModel
  C c1;
  C c2;
equation
  connect(c1, c2);
end InnerOuterModel;

model LowerLevelModel
  outer InnerOuterModel innerOuterModel;
  C c;
equation
  connect(c, innerOuterModel.c1);
end LowerLevelModel;

model ConnectInnerOuterArray1
  inner InnerOuterModel innerOuterModel;
  LowerLevelModel[2] lowerLevelModel;
end ConnectInnerOuterArray1;

// Result:
// class ConnectInnerOuterArray1
//   Real innerOuterModel.c1.e;
//   Real innerOuterModel.c1.f;
//   Real innerOuterModel.c2.e;
//   Real innerOuterModel.c2.f;
//   Real lowerLevelModel[1].c.e;
//   Real lowerLevelModel[1].c.f;
//   Real lowerLevelModel[2].c.e;
//   Real lowerLevelModel[2].c.f;
// equation
//   innerOuterModel.c1.f + (-lowerLevelModel[2].c.f) + (-lowerLevelModel[1].c.f) = 0.0;
//   innerOuterModel.c2.f = 0.0;
//   innerOuterModel.c1.e = innerOuterModel.c2.e;
//   (-innerOuterModel.c1.f) + (-innerOuterModel.c2.f) = 0.0;
//   lowerLevelModel[2].c.f = 0.0;
//   lowerLevelModel[1].c.f = 0.0;
//   innerOuterModel.c1.e = lowerLevelModel[1].c.e;
//   innerOuterModel.c1.e = lowerLevelModel[2].c.e;
// end ConnectInnerOuterArray1;
// endResult

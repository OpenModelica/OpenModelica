// name:     ModifiedFiltersInSeries
// keywords: modification, equation
// status:   correct
//
// Drmodelica: 4.2 Hierarchical Modification (p. 124)
//

model LowPassFilter
  parameter Real T = 1;
  Real u;
  Real y(start = 1);
equation
  T*der(y) + y = u;
end LowPassFilter;

model FiltersInSeries
  LowPassFilter F1(T = 2);
  LowPassFilter F2(T = 3);
equation
  F1.u = sin(time);
  F2.u = F1.y;
end FiltersInSeries;

model ModifiedFiltersInSeries
  FiltersInSeries F12(F1(T = 6), F2(T = 11));
end ModifiedFiltersInSeries;


// Result:
// class ModifiedFiltersInSeries
//   parameter Real F12.F1.T = 6.0;
//   Real F12.F1.u;
//   Real F12.F1.y(start = 1.0);
//   parameter Real F12.F2.T = 11.0;
//   Real F12.F2.u;
//   Real F12.F2.y(start = 1.0);
// equation
//   F12.F1.T * der(F12.F1.y) + F12.F1.y = F12.F1.u;
//   F12.F2.T * der(F12.F2.y) + F12.F2.y = F12.F2.u;
//   F12.F1.u = sin(time);
//   F12.F2.u = F12.F1.y;
// end ModifiedFiltersInSeries;
// endResult

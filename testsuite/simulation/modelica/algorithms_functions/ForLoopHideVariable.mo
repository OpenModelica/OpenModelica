// name:     ForLoopHideVariable
// keywords: for statment
// status:   correct
//
// for statment handling
// Drmodelica: 9.1 for-Statement (p.288)
//

model HideVariable
  constant Integer k = 4;
  Real z[k + 1];
algorithm
  for k in 1:k+1 loop // The iteration variable k gets values 1, 2, 3, 4, 5
    z[k] := k;
  end for;
end HideVariable;

// class HideVariable
// constant Integer k = 4;
// Real z[1];
// Real z[2];
// Real z[3];
// Real z[4];
// Real z[5];
// algorithm
//   for k in {1,2,3,4,5} loop
//     z[k] := Real(k);
//   end for;
// end HideVariable;

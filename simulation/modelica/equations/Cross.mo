// name:     Cross
// keywords: equation, vector
// status:   correct
//
//

model Cross
  function myCrossReal "Shouldn't be elaborated to equations like cross sometimes is"
    input Real[3] x;
    input Real[3] y;
    output Real[3] z;
  algorithm
    z := cross(x,y);
  end myCrossReal;

  function myCrossInt "Shouldn't be elaborated to equations like cross sometimes is"
    input Integer[3] x;
    input Integer[3] y;
    output Real[3] z;
  algorithm
    z := cross(x,y);
  end myCrossInt;

  Real x[3] = {1,5,3};
  Real y1[3] = {2,10,6};
  Real y2[3] = {5,3,1};
  Real[3] z;
  Integer xi[3] = {1,5,3};
  Integer yi1[3] = {2,10,6};
  Integer yi2[3] = {5,3,1};
  discrete Real[3] zi; // Should really be an Integer[3], but we have bugs when calling functions (in DAELow, it's Real[3], but the result isn't converted)
equation
  z = myCrossReal(x,if time > 0.1 then y2 else y1);
  zi = myCrossInt(xi,if time > 0.1 then yi2 else yi1);
end Cross;

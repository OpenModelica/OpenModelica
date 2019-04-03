// name:     ArrayDim1
// keywords: algorithm, equation
// status:   correct
//
// Drmodelica:
//
package Modelica
  package SIunits
   type Voltage = ElectricPotential;
   type ElectricPotential = Real ( final quantity="ElectricPotential",
    final unit="V");
  end SIunits;
end Modelica;

model ArrayDim1
  import Modelica.SIunits.Voltage;
  parameter Integer n = 1;
  parameter Integer m = 2;
  parameter Integer k = 3;

  // 3-dimensional position vector
  Real[3] positionvector = {1, 2, 3};

  // transformation matrix
  Real[3,3] identitymatrix = {{1,0,0},{0,1,0},{0,0,1}};

  // A 3-dimensional array
  Integer[n,m,k] arr3d;

  // A boolean vector
  Boolean[2] truthvalues = {false, true};

  // A vector of voltage values
  Voltage[10] voltagevector;

equation
  voltagevector = {1,2,3,4,5,6,7,8,9,0};
  for i in 1:n loop
    for j in 1:m loop
      for l in 1:k loop
        arr3d[i,j,l] = i+j+l;
      end for;
    end for;
  end for;
end ArrayDim1;

// Result:
// class ArrayDim1
//   parameter Integer n = 1;
//   parameter Integer m = 2;
//   parameter Integer k = 3;
//   Real positionvector[1];
//   Real positionvector[2];
//   Real positionvector[3];
//   Real identitymatrix[1,1];
//   Real identitymatrix[1,2];
//   Real identitymatrix[1,3];
//   Real identitymatrix[2,1];
//   Real identitymatrix[2,2];
//   Real identitymatrix[2,3];
//   Real identitymatrix[3,1];
//   Real identitymatrix[3,2];
//   Real identitymatrix[3,3];
//   Integer arr3d[1,1,1];
//   Integer arr3d[1,1,2];
//   Integer arr3d[1,1,3];
//   Integer arr3d[1,2,1];
//   Integer arr3d[1,2,2];
//   Integer arr3d[1,2,3];
//   Boolean truthvalues[1];
//   Boolean truthvalues[2];
//   Real voltagevector[1](quantity = "ElectricPotential", unit = "V");
//   Real voltagevector[2](quantity = "ElectricPotential", unit = "V");
//   Real voltagevector[3](quantity = "ElectricPotential", unit = "V");
//   Real voltagevector[4](quantity = "ElectricPotential", unit = "V");
//   Real voltagevector[5](quantity = "ElectricPotential", unit = "V");
//   Real voltagevector[6](quantity = "ElectricPotential", unit = "V");
//   Real voltagevector[7](quantity = "ElectricPotential", unit = "V");
//   Real voltagevector[8](quantity = "ElectricPotential", unit = "V");
//   Real voltagevector[9](quantity = "ElectricPotential", unit = "V");
//   Real voltagevector[10](quantity = "ElectricPotential", unit = "V");
// equation
//   positionvector = {1.0, 2.0, 3.0};
//   identitymatrix = {{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}};
//   truthvalues = {false, true};
//   voltagevector[1] = 1.0;
//   voltagevector[2] = 2.0;
//   voltagevector[3] = 3.0;
//   voltagevector[4] = 4.0;
//   voltagevector[5] = 5.0;
//   voltagevector[6] = 6.0;
//   voltagevector[7] = 7.0;
//   voltagevector[8] = 8.0;
//   voltagevector[9] = 9.0;
//   voltagevector[10] = 0.0;
//   arr3d[1,1,1] = 3;
//   arr3d[1,1,2] = 4;
//   arr3d[1,1,3] = 5;
//   arr3d[1,2,1] = 4;
//   arr3d[1,2,2] = 5;
//   arr3d[1,2,3] = 6;
// end ArrayDim1;
// endResult

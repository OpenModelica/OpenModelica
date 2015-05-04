// name:     ArrayDim4
// keywords: algorithm, equation
// status:   correct
//
// Drmodelica:
//

model ArrayDim4
  parameter Integer n = 1;
  parameter Integer m = 2;
  parameter Integer k = 3;

  // 3-dimensional position vector
  Real positionvector[3] = {1, 2, 3};

  // transformation matrix
  Real identitymatrix[3,3] = {{1,0,0},{0,1,0},{0,0,1}};

  // A 3-dimensional array
  Integer arr3d[n,m,k];

  // A boolean vector
  Boolean truthvalues[2] = {false, true};

equation
  for i in 1:n loop
    for j in 1:m loop
      for l in 1:k loop
        arr3d[i,j,l] = i+j+l;
      end for;
    end for;
  end for;
end ArrayDim4;


// Result:
// class ArrayDim4
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
// equation
//   positionvector = {1.0, 2.0, 3.0};
//   identitymatrix = {{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}};
//   truthvalues = {false, true};
//   arr3d[1,1,1] = 3;
//   arr3d[1,1,2] = 4;
//   arr3d[1,1,3] = 5;
//   arr3d[1,2,1] = 4;
//   arr3d[1,2,2] = 5;
//   arr3d[1,2,3] = 6;
// end ArrayDim4;
// endResult

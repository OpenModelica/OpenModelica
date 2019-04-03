model TestMatrices
  import Matrices = Modelica.Math.Matrices;
  parameter Real A[3,3] = [1,2,3;
                           3,4,5;
                           2,1,4];
  Real eval[size(A, 1), 2];
  Real evec[size(A, 1), size(A, 1)];
algorithm
  (eval, evec) := Matrices.eigenValues(A);  // eval = [   8.0, 0;
                                            //         -0.618, 0;
                                            //          1.618, 0  ];
end TestMatrices;
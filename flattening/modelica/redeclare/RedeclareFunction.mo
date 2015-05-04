// name:     RedeclareFunction (Bug1432)
// keywords: redeclare function
// status:   correct
//
// Checks that it's possible to modify packages which have a constant that influences a function.
//
//

model RedeclareFunction
   package A
        constant Integer n = 2;
        function f
            input Real a[n];
            output Real b;
        algorithm
            b := a * (1:n);
        end f;
    end A;

    model B
        package A2 = A;
        package A3 = A(n = 3);

        Real nA2 = 2;
        Real nA3 = 3;

        Real x = A2.f(1:nA2);
        Real y = A3.f(1:nA3);
    end B;

    B b;
end RedeclareFunction;

// Result:
// function RedeclareFunction.B.A2.f
//   input Real[2] a;
//   output Real b;
// algorithm
//   b := {a[1], a[2]} * (1.0:2.0);
// end RedeclareFunction.B.A2.f;
//
// function RedeclareFunction.B.A3.f
//   input Real[3] a;
//   output Real b;
// algorithm
//   b := {a[1], a[2], a[3]} * (1.0:3.0);
// end RedeclareFunction.B.A3.f;
//
// class RedeclareFunction
//   Real b.nA2 = 2.0;
//   Real b.nA3 = 3.0;
//   Real b.x = RedeclareFunction.B.A2.f(1.0:b.nA2);
//   Real b.y = RedeclareFunction.B.A3.f(1.0:b.nA3);
// end RedeclareFunction;
// endResult

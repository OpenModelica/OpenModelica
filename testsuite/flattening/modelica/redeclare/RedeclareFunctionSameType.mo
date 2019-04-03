// name:     RedeclareFunctionSameType.mo [BUG: #2739]
// keywords: redeclare function
// status:   correct
//
// Checks that it's possible to uniquely modify packages in different components having the same type
//
//

model RedeclareFunctionSameType
    package A
        replaceable function f
            input Real a;
            input Real b;
            output Real c;
        end f;
    end A;

    package P
        constant Integer n = 2;
        function f1
            input Real a;
            input Real b;
            output Real c;
        algorithm
            c := a + b + n;
        end f1;

        function f2
            input Real a;
            input Real b;
            output Real c;
        algorithm
            c := a * b * n;
        end f2;
    end P;

    model C
      replaceable function fredecl = A.f;
      package Z = A(redeclare function f = fredecl);
      Real x = Z.f(2, 3);
    end C;

    model B "some comment"
        C c1(redeclare function fredecl = P.f1);
        C c2(redeclare function fredecl = P.f2);
    end B;

    B b;
end RedeclareFunctionSameType;

// Result:
// function RedeclareFunctionSameType.C$b$c1.Z.f
//   input Real a;
//   input Real b;
//   output Real c;
// algorithm
//   c := 2.0 + a + b;
// end RedeclareFunctionSameType.C$b$c1.Z.f;
//
// function RedeclareFunctionSameType.C$b$c2.Z.f
//   input Real a;
//   input Real b;
//   output Real c;
// algorithm
//   c := 2.0 * a * b;
// end RedeclareFunctionSameType.C$b$c2.Z.f;
//
// class RedeclareFunctionSameType
//   Real b.c1.x = 7.0;
//   Real b.c2.x = 12.0;
// end RedeclareFunctionSameType;
// endResult

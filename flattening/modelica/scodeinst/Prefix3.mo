// name: Prefix3
// keywords:
// status: correct
// cflags: -d=newInst -i=P.P2.Prefix3
//

package P
  package P2
    model Prefix3
      function f
        input Real x;
        output Real y;
      end f;

      Real x = f(time);
    end Prefix3;
  end P2;
end P;

// Result:
// function P.P2.Prefix3.f
//   input Real x;
//   output Real y;
// end P.P2.Prefix3.f;
//
// class P.P2.Prefix3
//   Real x = P.P2.Prefix3.f(time);
// end P.P2.Prefix3;
// endResult

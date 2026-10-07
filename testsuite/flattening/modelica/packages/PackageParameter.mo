// name: PackageParameter
// keywords: package
// status: incorrect
//
// Tests to make sure that a parameter cannot be used as modifier
//
//

package PackageParameter
  constant Real x = 2;
model m

  model n
    parameter Integer i = 2;
  end n;

  package P
    constant Integer C = 1;
    function f
      input Real[C] i;
      output Real[C] o;
    algorithm
      o := i;
    end f;
  end P;

  package P3 = P(C=n.i);
  parameter Real c[P3.C] = P3.f({1,2});

  package P2 = P(C=a);
  constant Integer a = n.i;
  parameter Real b[P2.C] = P2.f({1,2});

end m;

end PackageParameter;

model PackageParameterModel
 extends PackageParameter.m;
end PackageParameterModel;

// Result:
// Error processing file: PackageParameter.mo
// [flattening/modelica/packages/PackageParameter.mo:14:5-14:28:writable] Notification: From here:
// [flattening/modelica/packages/PackageParameter.mo:27:18-27:23:writable] Error: Class n does not satisfy the requirements for a package. Lookup is therefore restricted to encapsulated elements, but i is not encapsulated.
// [flattening/modelica/packages/PackageParameter.mo:28:3-28:39:writable] Error: Function P3.f not found in scope m.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult

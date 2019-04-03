// name:     TestRedeclareTypeWithArrayDimensions.mo [BUG: #2418]
// keywords: redeclare,type
// status:   correct
//
// Redeclaration with array dimensions
//

package RedeclareTypeWithArrayDimensions

  model foo
    replaceable type paramType = Real;
    input paramType u;
    output paramType y;
  equation
    y = sin(u);
  end foo;

  model bar
    parameter Real x[:,2] = [0, 1];
    foo bletch(u=x, redeclare type paramType = Real[size(x,1),2]);
  end bar;

end RedeclareTypeWithArrayDimensions;

model TestRedeclareTypeWithArrayDimensions
  extends RedeclareTypeWithArrayDimensions.bar;
end TestRedeclareTypeWithArrayDimensions;

// Result:
// class TestRedeclareTypeWithArrayDimensions
//   parameter Real x[1,1] = 0.0;
//   parameter Real x[1,2] = 1.0;
//   input Real bletch.u[1,1];
//   input Real bletch.u[1,2];
//   output Real bletch.y[1,1];
//   output Real bletch.y[1,2];
// equation
//   bletch.u = {{x[1,1], x[1,2]}};
//   bletch.y[1,1] = sin(bletch.u[1,1]);
//   bletch.y[1,2] = sin(bletch.u[1,2]);
// end TestRedeclareTypeWithArrayDimensions;
// endResult

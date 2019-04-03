// name:     ErrorNestedWhen
// keywords: when
// status:   incorrect
//
// Nested whens are not allowed
// Drmodelica:   8.2 Conditional Equations with when-Equations (p. 246)
//

model ErrorNestedWhen
  Real x, y1, y2;
equation
  when x > 2 then
    when x > 3 then         // Error: when-clauses cannot be nested
      y2 = sin(x);
    end when;
  end when;
end ErrorNestedWhen;

// class ErrorNestedWhen
// Real x;
// Real y1;
// Real y2;
// equation
//   when x > 2.0 then
//   when x > 3.0 then
//   y2 = sin(x);
//   end when;
//   end when;
// end ErrorNestedWhen;

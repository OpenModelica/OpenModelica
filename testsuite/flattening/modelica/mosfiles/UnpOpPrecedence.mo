model UnpOpPrecedence

equation
  X=not (A and (B or C));
  Y=not A and B or C;
end UnpOpPrecedence;

// name:     ZeroDimUnconnectedFlow2
// keywords: connect
// status:   correct
//
// Checks that equations for unconnected flow variables in arrays with zero dims
// are not generated.
//

connector C
  Real e;
  flow Real f;
end C;

model ZeroDimUnconnectedFlow2
  model M
    C c;
  end M;

  M m[0];
end ZeroDimUnconnectedFlow2;

// Result:
// class ZeroDimUnconnectedFlow2
// end ZeroDimUnconnectedFlow2;
// endResult

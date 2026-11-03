// name:     Lookup11
// keywords: scoping, lookup, bug1165
// status:   incorrect
//
// Checks that lookup fails to find P.B from A, since it is only allowed to look
// in the inner P package and not the outer.
//

package P
  model A
    P.B b;
  end A;

  model B
  end B;

  package P
  end P;
end P;

// Result:
// class P
// end P;
// endResult

// name:     Extends12
// keywords: extends
// status:   correct
//
// Testing extends clauses

package Package1
  model Model2
    Real x;
  end Model2;
end Package1;

model Model1
  package Package2 = Package1;
  extends Package2.Model2;
end Model1;

// Result:
// class Model1
//   Real x;
// end Model1;
// endResult

// name:     PartialFn7
// keywords: PartialFn
// status:   correct
// cflags:   -g=MetaModelica -d=gen
//
// Passing record constructors
//

model PartialFn7

record TestRecord
  Integer i;
  Real r;
end TestRecord;

function CreateTestRecord

  input Integer i;
  input Real r;
  input InRecordConstructor rc;
  output TestRecord tr;

  partial function InRecordConstructor
    input Integer i;
    input Real r;
    output TestRecord tr;
  end InRecordConstructor;

algorithm

  tr := rc(i, r);

end CreateTestRecord;

function TestCreateTestRecord

  input Integer i;
  input Real r;
  output Integer o;
protected
  TestRecord tr;

algorithm

  tr := CreateTestRecord(i, r, TestRecord);
  o := 2;

end TestCreateTestRecord;

constant Integer i=1;
constant Real r=2.0;
Integer tr;

equation
  tr = TestCreateTestRecord(i, r);
end PartialFn7;

// Result:
// function PartialFn7.CreateTestRecord
//   input Integer i;
//   input Real r;
//   input rc<function>(#Integer i, #Real r) => #PartialFn7.TestRecord rc;
//   output PartialFn7.TestRecord tr;
// algorithm
//   tr := mmc_unbox_record(rc(#(i), #(r)));
// end PartialFn7.CreateTestRecord;
//
// function PartialFn7.TestCreateTestRecord
//   input Integer i;
//   input Real r;
//   output Integer o;
//   protected PartialFn7.TestRecord tr;
// algorithm
//   tr := PartialFn7.CreateTestRecord(i, r, PartialFn7.TestRecord);
//   o := 2;
// end PartialFn7.TestCreateTestRecord;
//
// function PartialFn7.TestRecord "Automatically generated record constructor for PartialFn7.TestRecord"
//   input Integer i;
//   input Real r;
//   output TestRecord res;
// end PartialFn7.TestRecord;
//
// class PartialFn7
//   constant Integer i = 1;
//   constant Real r = 2.0;
//   Integer tr;
// equation
//   tr = 2;
// end PartialFn7;
// endResult

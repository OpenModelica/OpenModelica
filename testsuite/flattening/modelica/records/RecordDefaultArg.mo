// name:     RecordDefaultArg
// keywords: record, default argument, #2366
// status:   correct
//
// Tests default arguments in record constructors.
//

model RecordDefaultArg
  record R
    parameter Real x[:];
    parameter Real y[size(x,1)]=x;

    end R;
    R r=R(x=zeros(0));
end RecordDefaultArg;

// Result:
// class RecordDefaultArg
// end RecordDefaultArg;
// endResult

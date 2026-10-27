// status: correct

model MissingCast
record SomeData
  parameter Real[10] data={1,2,3,4,5,6,7,8,9,10}; /* Integer numbers */
end SomeData;

function getData
  input Real x;
  output Real y;
protected
  SomeData data = SomeData();
  Integer i;
  Boolean finished;
  Real[10] v;
algorithm
  v := data.data;
  /* Just some code to avoid evaluate */
  finished:=false;
  i:=1;
  while (not finished) and i<size(v,1) loop
    if x>data.data[i] then
       finished := true;
    end if;
    i:=i+1;
  end while;
  y:=v[i];
end getData;

Real value;

equation

value = getData(0);

  annotation(__OpenModelica_commandLineOptions="+d=nogen");
end MissingCast;
// Result:
// class MissingCast
//   Real value;
// equation
//   value = 10.0;
// end MissingCast;
// endResult

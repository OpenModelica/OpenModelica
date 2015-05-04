// status: correct
// cflags: +d=nogen

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

end MissingCast;
// Result:
// function MissingCast.SomeData "Automatically generated record constructor for MissingCast.SomeData"
//   input Real[10] data = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0};
//   output SomeData res;
// end MissingCast.SomeData;
//
// function MissingCast.getData
//   input Real x;
//   output Real y;
//   protected MissingCast.SomeData data = MissingCast.SomeData({1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0});
//   protected Integer i;
//   protected Boolean finished;
//   protected Real[10] v;
// algorithm
//   v := {data.data[1], data.data[2], data.data[3], data.data[4], data.data[5], data.data[6], data.data[7], data.data[8], data.data[9], data.data[10]};
//   finished := false;
//   i := 1;
//   while not finished and i < 10 loop
//     if x > data.data[i] then
//       finished := true;
//     end if;
//     i := 1 + i;
//   end while;
//   y := v[i];
// end MissingCast.getData;
//
// class MissingCast
//   Real value;
// equation
//   value = 10.0;
// end MissingCast;
// endResult

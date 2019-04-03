// name:     Algorithm1
// keywords: algorithm
// status:   correct
//
// Simple algorithms

model Algorithm1
  Real x, y, z, a;
equation
  y = sin(time);
protected
  Integer i;
algorithm
  i := 0;
  a := y-1.0;
  while ((i/10) < y) loop
    a := a + 0.5;
    i := i + 1;
  end while;
algorithm
  for i in 1:3 loop
    if i > 2 then
      x := x - i;
    end if;
    if i < 1 then
      x := 1.0;
    elseif i < 2 then
      x := 2.0;
    else
      x := 3.0;
    end if;
  end for;
algorithm
  when y>0.9 then
    z := 0.0;
  end when;
end Algorithm1;

// Result:
// class Algorithm1
//   Real x;
//   Real y;
//   Real z;
//   Real a;
//   protected Integer i;
// equation
//   y = sin(time);
// algorithm
//   i := 0;
//   a := -1.0 + y;
//   while 0.1 * /*Real*/(i) < y loop
//     a := 0.5 + a;
//     i := 1 + i;
//   end while;
// algorithm
//   for i in 1:3 loop
//     if i > 2 then
//       x := x - /*Real*/(i);
//     end if;
//     if i < 1 then
//       x := 1.0;
//     elseif i < 2 then
//       x := 2.0;
//     else
//       x := 3.0;
//     end if;
//   end for;
// algorithm
//   when y > 0.9 then
//     z := 0.0;
//   end when;
// end Algorithm1;
// endResult

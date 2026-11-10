// name:     ComponentFunctions.mo [BUG: #2854]
// keywords: function calls via component
// status:   correct
//
// function call via component

model N
  constant Real c;
  function x
    input Real r;
    output Real o = r;
  end x;
  function f
    input Real r;
    output Real o = x(sum(c*i for i in r:r+1));
  end f;
end N;

model ComponentFunctions
  N n1(c=1),n2(c=2);
  Real r1 = n1.f(time), r2 = n2.f(time);
end ComponentFunctions;

// Result:
// function ComponentFunctions.n1.f
//   input Real r;
//   output Real o = ComponentFunctions.n1.x(sum(i for i in r:r + 1.0));
// end ComponentFunctions.n1.f;
//
// function ComponentFunctions.n1.x
//   input Real r;
//   output Real o = r;
// end ComponentFunctions.n1.x;
//
// function ComponentFunctions.n2.f
//   input Real r;
//   output Real o = ComponentFunctions.n2.x(sum(2.0 * i for i in r:r + 1.0));
// end ComponentFunctions.n2.f;
//
// function ComponentFunctions.n2.x
//   input Real r;
//   output Real o = r;
// end ComponentFunctions.n2.x;
//
// class ComponentFunctions
//   constant Real n1.c = 1.0;
//   constant Real n2.c = 2.0;
//   Real r1 = ComponentFunctions.n1.f(time);
//   Real r2 = ComponentFunctions.n2.f(time);
// end ComponentFunctions;
// endResult

// cflags: +g=MetaModelica
// status: correct

model UnboundLocal
  function g
    input Real t;
    output Real x = 1;
    output Real y = 1;
  end g;
  function f
    input Real r;
    output Real o[1];
  protected
    Integer ix1,ix2,ix3,ix4,ix5,ix6,j;
    Real y,z;
  algorithm
    y := y;
    o[ix1] := o[1];
    o := {ix3};
    (y,z) := g(ix2);
    if r>y then
      ix4 := 1;
    elseif r>2*y then
      ix4 := ix4;
    end if;
    ix4 := ix4;
    if r>y then
      ix5 := 1;
    else
      ix5 := 2;
    end if;
    ix5 := ix5;
    for i in 1:3 loop
      o[ix6] := i;
    end for;
    z := match j
      local
        Integer i,i2;
      case _ then i;
      case i2
        then i2;
      case _ then i;
    end match;
  end f;
  Real r[:] = f(time);
end UnboundLocal;

// Result:
// function UnboundLocal.f
//   input Real r;
//   output Real[1] o;
//   protected Integer ix1;
//   protected Integer ix2;
//   protected Integer ix3;
//   protected Integer ix4;
//   protected Integer ix5;
//   protected Integer ix6;
//   protected Integer j;
//   protected Real y;
//   protected Real z;
// algorithm
//   y := y;
//   o[ix1] := o[1];
//   o := {/*Real*/(ix3)};
//   (y, z) := UnboundLocal.g(/*Real*/(ix2));
//   if r > y then
//     ix4 := 1;
//   elseif r > 2.0 * y then
//     ix4 := ix4;
//   end if;
//   ix4 := ix4;
//   if r > y then
//     ix5 := 1;
//   else
//     ix5 := 2;
//   end if;
//   ix5 := ix5;
//   for i in 1:3 loop
//     o[ix6] := /*Real*/(i);
//   end for;
//   z := /*Real*/(match (j)
//     case (_) then i;
//     case (i2) then i2;
//     case (_) then i;
//   end match);
// end UnboundLocal.f;
//
// function UnboundLocal.g
//   input Real t;
//   output Real x = 1.0;
//   output Real y = 1.0;
// end UnboundLocal.g;
//
// class UnboundLocal
//   Real r[1];
// equation
//   r = UnboundLocal.f(time);
// end UnboundLocal;
// [metamodelica/meta/UnboundLocal.mo:17:5-17:11:writable] Warning: y was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
// [metamodelica/meta/UnboundLocal.mo:18:5-18:19:writable] Warning: o was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
// [metamodelica/meta/UnboundLocal.mo:18:5-18:19:writable] Warning: ix1 was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
// [metamodelica/meta/UnboundLocal.mo:19:5-19:15:writable] Warning: ix3 was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
// [metamodelica/meta/UnboundLocal.mo:20:5-20:20:writable] Warning: ix2 was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
// [metamodelica/meta/UnboundLocal.mo:24:7-24:17:writable] Warning: ix4 was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
// [metamodelica/meta/UnboundLocal.mo:34:7-34:18:writable] Warning: ix6 was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
// [metamodelica/meta/UnboundLocal.mo:36:5-43:14:writable] Warning: j was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
// [metamodelica/meta/UnboundLocal.mo:39:14-40:7:writable] Warning: i was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
// [metamodelica/meta/UnboundLocal.mo:42:14-43:5:writable] Warning: i was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
//
// endResult

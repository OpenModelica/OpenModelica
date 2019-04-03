// status: correct

package Modelica_Noise
package Math
package Random
package Generators
package Xorshift64star
extends Interfaces.PartialGenerator(final nState = 2);

redeclare function extends initialState
protected
Real r;
constant Integer p = 10;
algorithm
if localSeed == 0 and globalSeed == 0 then
  state := {126247697, globalSeed};
else
  state := {localSeed, globalSeed};
end if;
for i in 1:p loop
  (r, state) := random(state);
end for;
end initialState;

redeclare function extends random
external "C" ModelicaRandom_xorshift64star(stateIn, stateOut, result) annotation(Include = "
#include <stdint.h>
#define ModelicaRandom_INVM64 5.42101086242752217004e-20 /* = 2^(-64) */
#define ModelicaRandom_RAND(INT64) ( (int64_t)(INT64) * ModelicaRandom_INVM64 + 0.5 )

void ModelicaRandom_xorshift64star(int state_in[], int state_out[], double* y) {
union s_tag {
int32_t  s32[2];
uint64_t s64;
} s;
int i;
uint64_t x;
for (i=0; i<sizeof(s)/sizeof(uint32_t); i++) {
s.s32[i] = state_in[i];
}
x = s.s64;
/* The actual algorithm */
x ^= x >> 12; /* a */
x ^= x << 25; /* b */
x ^= x >> 27; /* c */
#if defined(_MSC_VER)
x  = x * 2685821657736338717i64;
#else
x  = x * 2685821657736338717LL;
#endif
/* Convert outputs */
s.s64 = x;
for (i=0; i<sizeof(s)/sizeof(uint32_t); i++) {
state_out[i] = s.s32[i];
}
*y = ModelicaRandom_RAND(x);
}
");
end random;
end Xorshift64star;
end Generators;

package Interfaces
partial package PartialGenerator
constant Integer nState = 1;

replaceable partial function initialState
input Integer localSeed;
input Integer globalSeed;
output Integer[nState] state;
end initialState;

replaceable partial function random
input Integer[nState] stateIn;
output Real result;
output Integer[nState] stateOut;
end random;
end PartialGenerator;
end Interfaces;
end Random;
end Math;
end Modelica_Noise;

function f
  input Integer i[2];
  output Real r;
protected
  Integer io[:]; // : here is the culprit
algorithm
  (r,io) := Modelica_Noise.Math.Random.Generators.Xorshift64star.random(i);
end f;

model M
  constant Real r = f({1,2});
end M;

// Result:
// function Modelica_Noise.Math.Random.Generators.Xorshift64star.random
//   input Integer[2] stateIn;
//   output Real result;
//   output Integer[2] stateOut;
//
//   external "C" ModelicaRandom_xorshift64star(stateIn, stateOut, result);
// end Modelica_Noise.Math.Random.Generators.Xorshift64star.random;
//
// function f
//   input Integer[2] i;
//   output Real r;
//   protected Integer[:] io;
// algorithm
//   (r, io) := Modelica_Noise.Math.Random.Generators.Xorshift64star.random({i[1], i[2]});
// end f;
//
// class M
//   constant Real r = f({1, 2});
// end M;
// endResult

// name:     FunctionSimplex
// keywords: function,code generation,constant propagation
// status:   correct
//
// Constant evaluation of function calls. Result of a function call with
// constant arguments is inserted into flat modelica.
// Edited 2007-10-30 BZ
// Change it so that misc_simplex does not adress an array at size(array)+1


function pivot1
  input Real b[:,:];
  input Integer p;
  input Integer q;
  output Real a[size(b,1),size(b,2)];
protected
  Integer M;
  Integer N;
algorithm
  a := b;
  N := size(a,1)-1;
  M := size(a,2)-1;
  for j in 1:N loop
    for k in 1:M loop
      if j<>p and k<>q then
       a[j,k] := a[j,k]-0.3*j;
      end if;
    end for;
  end for;
  a[p,q] := 0.05;
end pivot1;

function misc_simplex1
  input Real matr[:,:];
  output Real x[size(matr,2)-1];
  output Real z;
  output  Integer q;
  output  Integer p;
protected
  Real a[size(matr,1),size(matr,2)];
  Integer M;
  Integer N;
algorithm
  N := size(a,1)-1;
  M := size(a,2)-1;
  a := matr;
  p:=0;q:=0;
  a := pivot1(a,p+1,q+1);
  while not (q==(M) or p==(N)) loop
    q := 0;
    while not (q == (M) or a[0+1,q+1]>1) loop
      q:=q+1;
    end while;
    p := 0;
    while not (p == (N) or a[p+1,q+1]>0.1) loop
      p:=p+1;
    end while;
    if (q < M) and (p < N) and(p>0) and (q>0) then
      a := pivot1(a,p,q);
    end if;
  if(p<=0) and (q<=0) then
     a := pivot1(a,p+1,q+1);
  end if;
  if(p<=0) and (q>0) then
     a := pivot1(a,p+1,q);
  end if;
  if(p>0) and (q<=0) then
     a := pivot1(a,p,q+1);
  end if;
  end while;
  z := a[1,M];
  x := {a[1,i] for i in 1:size(x,1)};
  for i in 1:10 loop
   for j in 1:M loop
    x[j] := x[j]+x[j]*0.01;
   end for;
  end for;
end misc_simplex1;


model FunctionSimplex
  constant Real a[6,31]={{-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0,
        -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0,
        -1.0, -1.0, -1.0, -1.0, -1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0},
       {0.429782, 0.00324764, 0.0144618, 0.100862, 0.0527577, 0.584675,
        0.211411, 0.228098, 0.432293, 0.789368, 0.0652431, 0.876985,
        0.675662, 0.482681, 0.995546, 0.0684201, 0.971113, 0.907947,
        0.345968, 0.435689, 0.903455, 0.0573776, 0.479507, 0.655294,
        0.473673, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0},
       {0.05413, 0.465045, 0.554433, 0.420916, 0.469455, 0.253635,
        0.326335, 0.988622, 0.680087, 0.188392, 0.44935, 0.312961,
        0.197407, 0.192846, 0.38093, 0.341848, 0.28946, 0.846878,
        0.945241, 0.438392, 0.232082, 0.367371, 0.289946, 0.964719,
        0.177952, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0},
       {0.902325, 0.735514, 0.543803, 0.708497, 0.64869, 0.409179,
        0.555181, 0.0284101, 0.460299, 0.959829, 0.24222, 0.831003,
        0.267453, 0.578899, 0.900373, 0.541543, 0.420575, 0.633658,
        0.46198, 0.309461, 0.0532044, 0.343712, 0.497262, 0.131509,
        0.150879, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0},
       {0.608198, 0.953458, 0.423011, 0.502189, 0.199019, 0.398278,
        0.394601, 0.04189, 0.23919, 0.156057, 0.563598, 0.774437,
        0.660292, 0.255684, 0.0220544, 0.353862, 0.0266335, 0.793704,
        0.712593, 0.300657, 0.682922, 0.296442, 0.581085, 0.149778,
        0.0747238, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0},
       {0.342984, 0.158073, 0.64759, 0.875705, 0.944707, 0.763472,
        0.6057, 0.636514, 0.788649, 0.199875, 0.831263, 0.976223,
        0.532965, 0.17782, 0.477401, 0.949589, 0.739261, 0.465227,
        0.176743, 0.266667, 0.442819, 0.884142, 0.026965, 0.191943,
        0.0998345, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0}
       };
  Real b[size(a,2)-1];
  Real z;
  Integer p;
  Integer q;
equation
  (b,z,p,q)=misc_simplex1(a);
end FunctionSimplex;

// Result:
// function misc_simplex1
//   input Real[:, :] matr;
//   output Real[-1 + size(matr, 2)] x;
//   output Real z;
//   output Integer q;
//   output Integer p;
//   protected Integer M;
//   protected Integer N;
//   protected Real[size(matr, 1), size(matr, 2)] a;
// algorithm
//   N := -1 + size(a, 1);
//   M := -1 + size(a, 2);
//   a := matr;
//   p := 0;
//   q := 0;
//   a := pivot1(a, 1 + p, 1 + q);
//   while not (q == M or p == N) loop
//     q := 0;
//     while not (q == M or a[1,1 + q] > 1.0) loop
//       q := 1 + q;
//     end while;
//     p := 0;
//     while not (p == N or a[1 + p,1 + q] > 0.1) loop
//       p := 1 + p;
//     end while;
//     if q < M and p < N and p > 0 and q > 0 then
//       a := pivot1(a, p, q);
//     end if;
//     if p <= 0 and q <= 0 then
//       a := pivot1(a, 1 + p, 1 + q);
//     end if;
//     if p <= 0 and q > 0 then
//       a := pivot1(a, 1 + p, q);
//     end if;
//     if p > 0 and q <= 0 then
//       a := pivot1(a, p, 1 + q);
//     end if;
//   end while;
//   z := a[1,M];
//   x := array(a[1,i] for i in 1:size(x, 1));
//   for i in 1:10 loop
//     for j in 1:M loop
//       x[j] := 1.01 * x[j];
//     end for;
//   end for;
// end misc_simplex1;
//
// function pivot1
//   input Real[:, :] b;
//   input Integer p;
//   input Integer q;
//   output Real[size(b, 1), size(b, 2)] a;
//   protected Integer M;
//   protected Integer N;
// algorithm
//   a := b;
//   N := -1 + size(a, 1);
//   M := -1 + size(a, 2);
//   for j in 1:N loop
//     for k in 1:M loop
//       if j <> p and k <> q then
//         a[j,k] := a[j,k] + (-0.3) * /*Real*/(j);
//       end if;
//     end for;
//   end for;
//   a[p,q] := 0.05;
// end pivot1;
//
// class FunctionSimplex
//   constant Real a[1,1] = -1.0;
//   constant Real a[1,2] = -1.0;
//   constant Real a[1,3] = -1.0;
//   constant Real a[1,4] = -1.0;
//   constant Real a[1,5] = -1.0;
//   constant Real a[1,6] = -1.0;
//   constant Real a[1,7] = -1.0;
//   constant Real a[1,8] = -1.0;
//   constant Real a[1,9] = -1.0;
//   constant Real a[1,10] = -1.0;
//   constant Real a[1,11] = -1.0;
//   constant Real a[1,12] = -1.0;
//   constant Real a[1,13] = -1.0;
//   constant Real a[1,14] = -1.0;
//   constant Real a[1,15] = -1.0;
//   constant Real a[1,16] = -1.0;
//   constant Real a[1,17] = -1.0;
//   constant Real a[1,18] = -1.0;
//   constant Real a[1,19] = -1.0;
//   constant Real a[1,20] = -1.0;
//   constant Real a[1,21] = -1.0;
//   constant Real a[1,22] = -1.0;
//   constant Real a[1,23] = -1.0;
//   constant Real a[1,24] = -1.0;
//   constant Real a[1,25] = -1.0;
//   constant Real a[1,26] = 0.0;
//   constant Real a[1,27] = 0.0;
//   constant Real a[1,28] = 0.0;
//   constant Real a[1,29] = 0.0;
//   constant Real a[1,30] = 0.0;
//   constant Real a[1,31] = 0.0;
//   constant Real a[2,1] = 0.429782;
//   constant Real a[2,2] = 0.00324764;
//   constant Real a[2,3] = 0.0144618;
//   constant Real a[2,4] = 0.100862;
//   constant Real a[2,5] = 0.0527577;
//   constant Real a[2,6] = 0.5846749999999999;
//   constant Real a[2,7] = 0.211411;
//   constant Real a[2,8] = 0.228098;
//   constant Real a[2,9] = 0.432293;
//   constant Real a[2,10] = 0.789368;
//   constant Real a[2,11] = 0.0652431;
//   constant Real a[2,12] = 0.876985;
//   constant Real a[2,13] = 0.675662;
//   constant Real a[2,14] = 0.482681;
//   constant Real a[2,15] = 0.995546;
//   constant Real a[2,16] = 0.0684201;
//   constant Real a[2,17] = 0.971113;
//   constant Real a[2,18] = 0.9079469999999999;
//   constant Real a[2,19] = 0.345968;
//   constant Real a[2,20] = 0.435689;
//   constant Real a[2,21] = 0.903455;
//   constant Real a[2,22] = 0.0573776;
//   constant Real a[2,23] = 0.479507;
//   constant Real a[2,24] = 0.655294;
//   constant Real a[2,25] = 0.473673;
//   constant Real a[2,26] = 1.0;
//   constant Real a[2,27] = 0.0;
//   constant Real a[2,28] = 0.0;
//   constant Real a[2,29] = 0.0;
//   constant Real a[2,30] = 0.0;
//   constant Real a[2,31] = 1.0;
//   constant Real a[3,1] = 0.05413;
//   constant Real a[3,2] = 0.465045;
//   constant Real a[3,3] = 0.554433;
//   constant Real a[3,4] = 0.420916;
//   constant Real a[3,5] = 0.469455;
//   constant Real a[3,6] = 0.253635;
//   constant Real a[3,7] = 0.326335;
//   constant Real a[3,8] = 0.988622;
//   constant Real a[3,9] = 0.680087;
//   constant Real a[3,10] = 0.188392;
//   constant Real a[3,11] = 0.44935;
//   constant Real a[3,12] = 0.312961;
//   constant Real a[3,13] = 0.197407;
//   constant Real a[3,14] = 0.192846;
//   constant Real a[3,15] = 0.38093;
//   constant Real a[3,16] = 0.341848;
//   constant Real a[3,17] = 0.28946;
//   constant Real a[3,18] = 0.846878;
//   constant Real a[3,19] = 0.945241;
//   constant Real a[3,20] = 0.438392;
//   constant Real a[3,21] = 0.232082;
//   constant Real a[3,22] = 0.367371;
//   constant Real a[3,23] = 0.289946;
//   constant Real a[3,24] = 0.964719;
//   constant Real a[3,25] = 0.177952;
//   constant Real a[3,26] = 0.0;
//   constant Real a[3,27] = 1.0;
//   constant Real a[3,28] = 0.0;
//   constant Real a[3,29] = 0.0;
//   constant Real a[3,30] = 0.0;
//   constant Real a[3,31] = 1.0;
//   constant Real a[4,1] = 0.902325;
//   constant Real a[4,2] = 0.735514;
//   constant Real a[4,3] = 0.543803;
//   constant Real a[4,4] = 0.708497;
//   constant Real a[4,5] = 0.64869;
//   constant Real a[4,6] = 0.409179;
//   constant Real a[4,7] = 0.555181;
//   constant Real a[4,8] = 0.0284101;
//   constant Real a[4,9] = 0.460299;
//   constant Real a[4,10] = 0.959829;
//   constant Real a[4,11] = 0.24222;
//   constant Real a[4,12] = 0.831003;
//   constant Real a[4,13] = 0.267453;
//   constant Real a[4,14] = 0.5788990000000001;
//   constant Real a[4,15] = 0.900373;
//   constant Real a[4,16] = 0.541543;
//   constant Real a[4,17] = 0.420575;
//   constant Real a[4,18] = 0.6336580000000001;
//   constant Real a[4,19] = 0.46198;
//   constant Real a[4,20] = 0.309461;
//   constant Real a[4,21] = 0.0532044;
//   constant Real a[4,22] = 0.343712;
//   constant Real a[4,23] = 0.497262;
//   constant Real a[4,24] = 0.131509;
//   constant Real a[4,25] = 0.150879;
//   constant Real a[4,26] = 0.0;
//   constant Real a[4,27] = 0.0;
//   constant Real a[4,28] = 1.0;
//   constant Real a[4,29] = 0.0;
//   constant Real a[4,30] = 0.0;
//   constant Real a[4,31] = 1.0;
//   constant Real a[5,1] = 0.608198;
//   constant Real a[5,2] = 0.953458;
//   constant Real a[5,3] = 0.423011;
//   constant Real a[5,4] = 0.502189;
//   constant Real a[5,5] = 0.199019;
//   constant Real a[5,6] = 0.398278;
//   constant Real a[5,7] = 0.394601;
//   constant Real a[5,8] = 0.04189;
//   constant Real a[5,9] = 0.23919;
//   constant Real a[5,10] = 0.156057;
//   constant Real a[5,11] = 0.563598;
//   constant Real a[5,12] = 0.774437;
//   constant Real a[5,13] = 0.660292;
//   constant Real a[5,14] = 0.255684;
//   constant Real a[5,15] = 0.0220544;
//   constant Real a[5,16] = 0.353862;
//   constant Real a[5,17] = 0.0266335;
//   constant Real a[5,18] = 0.793704;
//   constant Real a[5,19] = 0.712593;
//   constant Real a[5,20] = 0.300657;
//   constant Real a[5,21] = 0.682922;
//   constant Real a[5,22] = 0.296442;
//   constant Real a[5,23] = 0.581085;
//   constant Real a[5,24] = 0.149778;
//   constant Real a[5,25] = 0.07472380000000001;
//   constant Real a[5,26] = 0.0;
//   constant Real a[5,27] = 0.0;
//   constant Real a[5,28] = 0.0;
//   constant Real a[5,29] = 1.0;
//   constant Real a[5,30] = 0.0;
//   constant Real a[5,31] = 1.0;
//   constant Real a[6,1] = 0.342984;
//   constant Real a[6,2] = 0.158073;
//   constant Real a[6,3] = 0.64759;
//   constant Real a[6,4] = 0.875705;
//   constant Real a[6,5] = 0.944707;
//   constant Real a[6,6] = 0.763472;
//   constant Real a[6,7] = 0.6057;
//   constant Real a[6,8] = 0.636514;
//   constant Real a[6,9] = 0.788649;
//   constant Real a[6,10] = 0.199875;
//   constant Real a[6,11] = 0.831263;
//   constant Real a[6,12] = 0.976223;
//   constant Real a[6,13] = 0.532965;
//   constant Real a[6,14] = 0.17782;
//   constant Real a[6,15] = 0.477401;
//   constant Real a[6,16] = 0.949589;
//   constant Real a[6,17] = 0.7392609999999999;
//   constant Real a[6,18] = 0.465227;
//   constant Real a[6,19] = 0.176743;
//   constant Real a[6,20] = 0.266667;
//   constant Real a[6,21] = 0.442819;
//   constant Real a[6,22] = 0.884142;
//   constant Real a[6,23] = 0.026965;
//   constant Real a[6,24] = 0.191943;
//   constant Real a[6,25] = 0.09983450000000001;
//   constant Real a[6,26] = 0.0;
//   constant Real a[6,27] = 0.0;
//   constant Real a[6,28] = 0.0;
//   constant Real a[6,29] = 0.0;
//   constant Real a[6,30] = 1.0;
//   constant Real a[6,31] = 1.0;
//   Real b[1];
//   Real b[2];
//   Real b[3];
//   Real b[4];
//   Real b[5];
//   Real b[6];
//   Real b[7];
//   Real b[8];
//   Real b[9];
//   Real b[10];
//   Real b[11];
//   Real b[12];
//   Real b[13];
//   Real b[14];
//   Real b[15];
//   Real b[16];
//   Real b[17];
//   Real b[18];
//   Real b[19];
//   Real b[20];
//   Real b[21];
//   Real b[22];
//   Real b[23];
//   Real b[24];
//   Real b[25];
//   Real b[26];
//   Real b[27];
//   Real b[28];
//   Real b[29];
//   Real b[30];
//   Real z;
//   Integer p;
//   Integer q;
// equation
//   ({b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15], b[16], b[17], b[18], b[19], b[20], b[21], b[22], b[23], b[24], b[25], b[26], b[27], b[28], b[29], b[30]}, z, p, q) = ({0.05523110627056022, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, -1.104622125411205, 0.0, 0.0, 0.0, 0.0, 0.0}, 0.0, 30, 1);
// end FunctionSimplex;
// endResult

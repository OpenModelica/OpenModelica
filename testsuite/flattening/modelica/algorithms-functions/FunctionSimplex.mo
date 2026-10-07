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
// class FunctionSimplex
//   constant Real a[1,1] = 0.05;
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
//   constant Real a[2,2] = -0.59675236;
//   constant Real a[2,3] = -0.5855382;
//   constant Real a[2,4] = -0.49913799999999997;
//   constant Real a[2,5] = -0.5472423;
//   constant Real a[2,6] = -0.015325000000000033;
//   constant Real a[2,7] = -0.38858899999999996;
//   constant Real a[2,8] = -0.37190199999999995;
//   constant Real a[2,9] = -0.167707;
//   constant Real a[2,10] = 0.18936799999999998;
//   constant Real a[2,11] = -0.5347569;
//   constant Real a[2,12] = 0.27698500000000004;
//   constant Real a[2,13] = 0.07566200000000001;
//   constant Real a[2,14] = -0.11731899999999995;
//   constant Real a[2,15] = 0.39554600000000006;
//   constant Real a[2,16] = -0.5315799;
//   constant Real a[2,17] = 0.371113;
//   constant Real a[2,18] = 0.30794699999999997;
//   constant Real a[2,19] = -0.254032;
//   constant Real a[2,20] = -0.16431099999999998;
//   constant Real a[2,21] = 0.30345500000000003;
//   constant Real a[2,22] = -0.5426224;
//   constant Real a[2,23] = -0.12049299999999996;
//   constant Real a[2,24] = 0.055294000000000065;
//   constant Real a[2,25] = -0.12632699999999997;
//   constant Real a[2,26] = 0.4;
//   constant Real a[2,27] = -0.6;
//   constant Real a[2,28] = -0.6;
//   constant Real a[2,29] = -0.6;
//   constant Real a[2,30] = -0.6;
//   constant Real a[2,31] = 1.0;
//   constant Real a[3,1] = 0.05413;
//   constant Real a[3,2] = -0.4349549999999999;
//   constant Real a[3,3] = -0.34556699999999996;
//   constant Real a[3,4] = -0.4790839999999999;
//   constant Real a[3,5] = -0.4305449999999999;
//   constant Real a[3,6] = -0.6463649999999999;
//   constant Real a[3,7] = -0.5736649999999999;
//   constant Real a[3,8] = 0.08862200000000009;
//   constant Real a[3,9] = -0.21991299999999991;
//   constant Real a[3,10] = -0.7116079999999999;
//   constant Real a[3,11] = -0.4506499999999999;
//   constant Real a[3,12] = -0.5870389999999999;
//   constant Real a[3,13] = -0.7025929999999999;
//   constant Real a[3,14] = -0.707154;
//   constant Real a[3,15] = -0.5190699999999999;
//   constant Real a[3,16] = -0.558152;
//   constant Real a[3,17] = -0.6105399999999999;
//   constant Real a[3,18] = -0.05312199999999989;
//   constant Real a[3,19] = 0.04524100000000009;
//   constant Real a[3,20] = -0.4616079999999999;
//   constant Real a[3,21] = -0.6679179999999999;
//   constant Real a[3,22] = -0.5326289999999999;
//   constant Real a[3,23] = -0.6100539999999999;
//   constant Real a[3,24] = 0.06471900000000008;
//   constant Real a[3,25] = -0.7220479999999999;
//   constant Real a[3,26] = -0.8999999999999999;
//   constant Real a[3,27] = 0.10000000000000009;
//   constant Real a[3,28] = -0.8999999999999999;
//   constant Real a[3,29] = -0.8999999999999999;
//   constant Real a[3,30] = -0.8999999999999999;
//   constant Real a[3,31] = 1.0;
//   constant Real a[4,1] = 0.902325;
//   constant Real a[4,2] = -0.46448599999999995;
//   constant Real a[4,3] = -0.6561969999999999;
//   constant Real a[4,4] = -0.4915029999999999;
//   constant Real a[4,5] = -0.55131;
//   constant Real a[4,6] = -0.790821;
//   constant Real a[4,7] = -0.6448189999999999;
//   constant Real a[4,8] = -1.1715898999999999;
//   constant Real a[4,9] = -0.7397009999999999;
//   constant Real a[4,10] = -0.2401709999999999;
//   constant Real a[4,11] = -0.95778;
//   constant Real a[4,12] = -0.3689969999999999;
//   constant Real a[4,13] = -0.932547;
//   constant Real a[4,14] = -0.6211009999999999;
//   constant Real a[4,15] = -0.299627;
//   constant Real a[4,16] = -0.658457;
//   constant Real a[4,17] = -0.779425;
//   constant Real a[4,18] = -0.5663419999999999;
//   constant Real a[4,19] = -0.7380199999999999;
//   constant Real a[4,20] = -0.890539;
//   constant Real a[4,21] = -1.1467956;
//   constant Real a[4,22] = -0.8562879999999999;
//   constant Real a[4,23] = -0.702738;
//   constant Real a[4,24] = -1.0684909999999999;
//   constant Real a[4,25] = -1.049121;
//   constant Real a[4,26] = -1.2;
//   constant Real a[4,27] = -1.2;
//   constant Real a[4,28] = -0.19999999999999996;
//   constant Real a[4,29] = -1.2;
//   constant Real a[4,30] = -1.2;
//   constant Real a[4,31] = 1.0;
//   constant Real a[5,1] = 0.608198;
//   constant Real a[5,2] = -0.546542;
//   constant Real a[5,3] = -1.076989;
//   constant Real a[5,4] = -0.997811;
//   constant Real a[5,5] = -1.300981;
//   constant Real a[5,6] = -1.101722;
//   constant Real a[5,7] = -1.105399;
//   constant Real a[5,8] = -1.45811;
//   constant Real a[5,9] = -1.26081;
//   constant Real a[5,10] = -1.3439429999999999;
//   constant Real a[5,11] = -0.936402;
//   constant Real a[5,12] = -0.725563;
//   constant Real a[5,13] = -0.839708;
//   constant Real a[5,14] = -1.244316;
//   constant Real a[5,15] = -1.4779456;
//   constant Real a[5,16] = -1.146138;
//   constant Real a[5,17] = -1.4733665;
//   constant Real a[5,18] = -0.706296;
//   constant Real a[5,19] = -0.787407;
//   constant Real a[5,20] = -1.199343;
//   constant Real a[5,21] = -0.817078;
//   constant Real a[5,22] = -1.2035580000000001;
//   constant Real a[5,23] = -0.918915;
//   constant Real a[5,24] = -1.350222;
//   constant Real a[5,25] = -1.4252761999999999;
//   constant Real a[5,26] = -1.5;
//   constant Real a[5,27] = -1.5;
//   constant Real a[5,28] = -1.5;
//   constant Real a[5,29] = -0.5;
//   constant Real a[5,30] = -1.5;
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
//   constant Real a[6,17] = 0.739261;
//   constant Real a[6,18] = 0.465227;
//   constant Real a[6,19] = 0.176743;
//   constant Real a[6,20] = 0.266667;
//   constant Real a[6,21] = 0.442819;
//   constant Real a[6,22] = 0.884142;
//   constant Real a[6,23] = 0.026965;
//   constant Real a[6,24] = 0.191943;
//   constant Real a[6,25] = 0.0998345;
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
//   b[1] = 0.05523110627056022;
//   b[2] = -1.1046221254112043;
//   b[3] = -1.1046221254112043;
//   b[4] = -1.1046221254112043;
//   b[5] = -1.1046221254112043;
//   b[6] = -1.1046221254112043;
//   b[7] = -1.1046221254112043;
//   b[8] = -1.1046221254112043;
//   b[9] = -1.1046221254112043;
//   b[10] = -1.1046221254112043;
//   b[11] = -1.1046221254112043;
//   b[12] = -1.1046221254112043;
//   b[13] = -1.1046221254112043;
//   b[14] = -1.1046221254112043;
//   b[15] = -1.1046221254112043;
//   b[16] = -1.1046221254112043;
//   b[17] = -1.1046221254112043;
//   b[18] = -1.1046221254112043;
//   b[19] = -1.1046221254112043;
//   b[20] = -1.1046221254112043;
//   b[21] = -1.1046221254112043;
//   b[22] = -1.1046221254112043;
//   b[23] = -1.1046221254112043;
//   b[24] = -1.1046221254112043;
//   b[25] = -1.1046221254112043;
//   b[26] = 0.0;
//   b[27] = 0.0;
//   b[28] = 0.0;
//   b[29] = 0.0;
//   b[30] = 0.0;
//   z = 0.0;
//   p = 30;
//   q = 1;
// end FunctionSimplex;
// endResult

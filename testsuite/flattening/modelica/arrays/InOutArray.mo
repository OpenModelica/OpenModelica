// name: InOutArray
// keywords: <insert keywords here>
// status: correct

function sumInt
    input Integer[:] inVal;
    output Integer outSum;
algorithm
    outSum := 0;
    for i in 1:size(inVal,1) loop
        outSum := outSum + inVal[i];
    end for;
end sumInt;

function sumReal
    input Real[:] inVal;
    output Real outSum;
algorithm
    outSum := 0.0;
    for i in 1:size(inVal,1) loop
        outSum := outSum + inVal[i];
    end for;
end sumReal;

function addReal32
    input Real[3, 2] inVal;
    output Real[3, 2] outVal;
algorithm
    for i in 1:3 loop
        for j in 1:2 loop
            outVal[i, j] := inVal[i, j] + 2.0;
        end for;
    end for;
end addReal32;

function sumBool
    input Boolean[:] inVal;
    output Integer outSum;
algorithm
    outSum := 0;
    for i in 1:size(inVal,1) loop
        if inVal[i] then
            outSum := outSum + 1;
        end if;
    end for;
end sumBool;

class InOutArray
    constant Real A[5] = { 1.0, 2.0, 3.0, 4.0, 5.0 };
    Real Asum = sumReal(A);
    constant Integer B[3] = { 1, 2, 3 };
    Integer Bsum = sumInt(B);
    constant Boolean C[2] = { true, false };
    Integer Csum = sumBool(C);
    constant Real D[3, 2] = { { 1.0, 2.0 }, { 3.0, 4.0 }, { 5.0, 6.0 } };
    constant Real F[3, 2] = addReal32(D);
end InOutArray;

// Result:
// function addReal32
//   input Real[3, 2] inVal;
//   output Real[3, 2] outVal;
// algorithm
//   for i in 1:3 loop
//     for j in 1:2 loop
//       outVal[i,j] := 2.0 + inVal[i,j];
//     end for;
//   end for;
// end addReal32;
//
// function sumBool
//   input Boolean[:] inVal;
//   output Integer outSum;
// algorithm
//   outSum := 0;
//   for i in 1:size(inVal, 1) loop
//     if inVal[i] then
//       outSum := 1 + outSum;
//     end if;
//   end for;
// end sumBool;
//
// function sumInt
//   input Integer[:] inVal;
//   output Integer outSum;
// algorithm
//   outSum := 0;
//   for i in 1:size(inVal, 1) loop
//     outSum := outSum + inVal[i];
//   end for;
// end sumInt;
//
// function sumReal
//   input Real[:] inVal;
//   output Real outSum;
// algorithm
//   outSum := 0.0;
//   for i in 1:size(inVal, 1) loop
//     outSum := outSum + inVal[i];
//   end for;
// end sumReal;
//
// class InOutArray
//   constant Real A[1] = 1.0;
//   constant Real A[2] = 2.0;
//   constant Real A[3] = 3.0;
//   constant Real A[4] = 4.0;
//   constant Real A[5] = 5.0;
//   Real Asum = 15.0;
//   constant Integer B[1] = 1;
//   constant Integer B[2] = 2;
//   constant Integer B[3] = 3;
//   Integer Bsum = 6;
//   constant Boolean C[1] = true;
//   constant Boolean C[2] = false;
//   Integer Csum = 1;
//   constant Real D[1,1] = 1.0;
//   constant Real D[1,2] = 2.0;
//   constant Real D[2,1] = 3.0;
//   constant Real D[2,2] = 4.0;
//   constant Real D[3,1] = 5.0;
//   constant Real D[3,2] = 6.0;
//   constant Real F[1,1] = 3.0;
//   constant Real F[1,2] = 4.0;
//   constant Real F[2,1] = 5.0;
//   constant Real F[2,2] = 6.0;
//   constant Real F[3,1] = 7.0;
//   constant Real F[3,2] = 8.0;
// end InOutArray;
// endResult

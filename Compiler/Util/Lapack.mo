/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package Lapack
" file:        Lapack.mo
  package:     Lapack
  description: This file contains Lapack external functions.


  This package contains Lapack external functions which are used by
  CevalFunction to evaluate functions that use these Lapack functions. The
  input/output parameters to the functions are named according to the Lapack
  documentation, see e.g. the documentation in Modelica.Math.Matrices.LAPACK for
  a description."

public function dgeev
  input String inJOBVL;
  input String inJOBVR;
  input Integer inN;
  input list<list<Real>> inA;
  input Integer inLDA;
  input Integer inLDVL;
  input Integer inLDVR;
  input list<Real> inWORK;
  input Integer inLWORK;
  output list<list<Real>> outA;
  output list<Real> outWR;
  output list<Real> outWI;
  output list<list<Real>> outVL;
  output list<list<Real>> outVR;
  output list<Real> outWORK;
  output Integer outINFO;
  external "C" LapackImpl__dgeev(inJOBVL, inJOBVR, inN, inA, inLDA, inLDVL,
    inLDVR, inWORK, inLWORK, outA, outWR, outWI, outVL, outVR, outWORK, outINFO)
    annotation(Library = {"omcruntime", "Lapack"});
end dgeev;

public function dgegv
  input String inJOBVL;
  input String inJOBVR;
  input Integer inN;
  input list<list<Real>> inA;
  input Integer inLDA;
  input list<list<Real>> inB;
  input Integer inLDB;
  input Integer inLDVL;
  input Integer inLDVR;
  input list<Real> inWORK;
  input Integer inLWORK;
  output list<Real> outALPHAR;
  output list<Real> outALPHAI;
  output list<Real> outBETA;
  output list<list<Real>> outVL;
  output list<list<Real>> outVR;
  output list<Real> outWORK;
  output Integer outINFO;
  external "C" LapackImpl__dgegv(inJOBVL, inJOBVR, inN, inA, inLDA, inB, inLDB,
    inLDVL, inLDVR, inWORK, inLWORK, outALPHAR, outALPHAI, outBETA, outVL,
    outVR, outWORK, outINFO) annotation(Library = {"omcruntime", "Lapack"});
end dgegv;

public function dgels
  input String inTRANS;
  input Integer inM;
  input Integer inN;
  input Integer inNRHS;
  input list<list<Real>> inA;
  input Integer inLDA;
  input list<list<Real>> inB;
  input Integer inLDB;
  input list<Real> inWORK;
  input Integer inLWORK;
  output list<list<Real>> outA;
  output list<list<Real>> outB;
  output list<Real> outWORK;
  output Integer outINFO;
  external "C" LapackImpl__dgels(inTRANS, inM, inN, inNRHS, inA, inLDA, inB,
    inLDB, inWORK, inLWORK, outA, outB, outWORK, outINFO)
    annotation(Library = {"omcruntime", "Lapack"});
end dgels;

public function dgelsx
  input Integer inM;
  input Integer inN;
  input Integer inNRHS;
  input list<list<Real>> inA;
  input Integer inLDA;
  input list<list<Real>> inB;
  input Integer inLDB;
  input list<Integer> inJPVT;
  input Real inRCOND;
  input list<Real> inWORK;
  output list<list<Real>> outA;
  output list<list<Real>> outB;
  output list<Integer> outJPVT;
  output Integer outRANK;
  output Integer outINFO;
  external "C" LapackImpl__dgelsx(inM, inN, inNRHS, inA, inLDA, inB, inLDB,
      inJPVT, inRCOND, inWORK, outA, outB, outJPVT, outRANK, outINFO)
    annotation(Library = {"omcruntime", "Lapack"});
end dgelsx;

public function dgesv
  input Integer inN;
  input Integer inNRHS;
  input list<list<Real>> inA;
  input Integer inLDA;
  input list<list<Real>> inB;
  input Integer inLDB;
  output list<list<Real>> outA;
  output list<Integer> outIPIV;
  output list<list<Real>> outB;
  output Integer outINFO;
  external "C" LapackImpl__dgesv(inN, inNRHS, inA, inLDA, inB, inLDB,
    outA, outIPIV, outB, outINFO) annotation(Library = {"omcruntime", "Lapack"});
end dgesv;

public function dgglse
  input Integer inM;
  input Integer inN;
  input Integer inP;
  input list<list<Real>> inA;
  input Integer inLDA;
  input list<list<Real>> inB;
  input Integer inLDB;
  input list<Real> inC;
  input list<Real> inD;
  input list<Real> inWORK;
  input Integer inLWORK;
  output list<list<Real>> outA;
  output list<list<Real>> outB;
  output list<Real> outC;
  output list<Real> outD;
  output list<Real> outX;
  output list<Real> outWORK;
  output Integer outINFO;
  external "C" LapackImpl__dgglse(inM, inN, inP, inA, inLDA, inB, inLDB, inC,
    inD, inWORK, inLWORK, outA, outB, outC, outD, outX, outWORK, outINFO)
    annotation(Library = {"omcruntime", "Lapack"});
end dgglse;

public function dgtsv
  input Integer inN;
  input Integer inNRHS;
  input list<Real> inDL;
  input list<Real> inD;
  input list<Real> inDU;
  input list<list<Real>> inB;
  input Integer inLDB;
  output list<Real> outDL;
  output list<Real> outD;
  output list<Real> outDU;
  output list<list<Real>> outB;
  output Integer outINFO;
  external "C" LapackImpl__dgtsv(inN, inNRHS, inDL, inD, inDU, inB, inLDB,
    outDL, outD, outDU, outB, outINFO)
    annotation(Library = {"omcruntime", "Lapack"});
end dgtsv;

public function dgbsv
  input Integer inN;
  input Integer inKL;
  input Integer inKU;
  input Integer inNRHS;
  input list<list<Real>> inAB;
  input Integer inLDAB;
  input list<list<Real>> inB;
  input Integer inLDB;
  output list<list<Real>> outAB;
  output list<Integer> outIPIV;
  output list<list<Real>> outB;
  output Integer outINFO;
  external "C" LapackImpl__dgbsv(inN, inKL, inKU, inNRHS, inAB, inLDAB, inB,
    inLDB, outAB, outIPIV, outB, outINFO)
    annotation(Library = {"omcruntime", "Lapack"});
end dgbsv;

public function dgesvd
  input String inJOBU;
  input String inJOBVT;
  input Integer inM;
  input Integer inN;
  input list<list<Real>> inA;
  input Integer inLDA;
  input Integer inLDU;
  input Integer inLDVT;
  input list<Real> inWORK;
  input Integer inLWORK;
  output list<list<Real>> outA;
  output list<Real> outS;
  output list<list<Real>> outU;
  output list<list<Real>> outVT;
  output list<Real> outWORK;
  output Integer outINFO;
  external "C" LapackImpl__dgesvd(inJOBU, inJOBVT, inM, inN, inA, inLDA, inLDU,
    inLDVT, inWORK, inLWORK, outA, outS, outU, outVT, outWORK, outINFO)
    annotation(Library = {"omcruntime", "Lapack"});
end dgesvd;

public function dgetrf
  input Integer inM;
  input Integer inN;
  input list<list<Real>> inA;
  input Integer inLDA;
  output list<list<Real>> outA;
  output list<Integer> outIPIV;
  output Integer outINFO;
  external "C" LapackImpl__dgetrf(inM, inN, inA, inLDA, outA, outIPIV, outINFO)
    annotation(Library = {"omcruntime", "Lapack"});
end dgetrf;

public function dgetrs
  input String inTRANS;
  input Integer inN;
  input Integer inNRHS;
  input list<list<Real>> inA;
  input Integer inLDA;
  input list<Integer> inIPIV;
  input list<list<Real>> inB;
  input Integer inLDB;
  output list<list<Real>> outB;
  output Integer outINFO;
  external "C" LapackImpl__dgetrs(inTRANS, inN, inNRHS, inA, inLDA, inIPIV, inB,
    inLDB, outB, outINFO)
    annotation(Library = {"omcruntime", "Lapack"});
end dgetrs;

public function dgetri
  input Integer inN;
  input list<list<Real>> inA;
  input Integer inLDA;
  input list<Integer> inIPIV;
  input list<Real> inWORK;
  input Integer inLWORK;
  output list<list<Real>> outA;
  output list<Real> outWORK;
  output Integer outINFO;
  external "C" LapackImpl__dgetri(inN, inA, inLDA, inIPIV, inWORK, inLWORK,
    outA, outWORK, outINFO) annotation(Library = {"omcruntime", "Lapack"});
end dgetri;

public function dgeqpf
  input Integer inM;
  input Integer inN;
  input list<list<Real>> inA;
  input Integer inLDA;
  input list<Integer> inJPVT;
  input list<Real> inWORK;
  output list<list<Real>> outA;
  output list<Integer> outJPVT;
  output list<Real> outTAU;
  output Integer outINFO;
  external "C" LapackImpl__dgeqpf(inM, inN, inA, inLDA, inJPVT, inWORK, outA,
    outJPVT, outTAU, outINFO) annotation(Library = {"omcruntime", "Lapack"});
end dgeqpf;

public function dorgqr
  input Integer inM;
  input Integer inN;
  input Integer inK;
  input list<list<Real>> inA;
  input Integer inLDA;
  input list<Real> inTAU;
  input list<Real> inWORK;
  input Integer inLWORK;
  output list<list<Real>> outA;
  output list<Real> outWORK;
  output Integer outINFO;
  external "C" LapackImpl__dorgqr(inM, inN, inK, inA, inLDA, inTAU, inWORK, inLWORK,
    outA, outWORK, outINFO) annotation(Library = {"omcruntime", "Lapack"});
end dorgqr;

annotation(__OpenModelica_Interface="util");
end Lapack;

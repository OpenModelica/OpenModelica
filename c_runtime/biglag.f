      SUBROUTINE BIGLAG (N,NPT,XOPT,XPT,BMAT,ZMAT,IDZ,NDIM,KNEW,
     1  DELTA,D,ALPHA,HCOL,GC,GD,S,W)
      IMPLICIT REAL*8 (A-H,O-Z)
      DIMENSION XOPT(*),XPT(NPT,*),BMAT(NDIM,*),ZMAT(NPT,*),D(*),
     1  HCOL(*),GC(*),GD(*),S(*),W(*)
C
C     N is the number of variables.
C     NPT is the number of interpolation equations.
C     XOPT is the best interpolation point so far.
C     XPT contains the coordinates of the current interpolation points.
C     BMAT provides the last N columns of H.
C     ZMAT and IDZ give a factorization of the first NPT by NPT submatrix of H.
C     NDIM is the first dimension of BMAT and has the value NPT+N.
C     KNEW is the index of the interpolation point that is going to be moved.
C     DELTA is the current trust region bound.
C     D will be set to the step from XOPT to the new point.
C     ALPHA will be set to the KNEW-th diagonal element of the H matrix.
C     HCOL, GC, GD, S and W will be used for working space.
C
C     The step D is calculated in a way that attempts to maximize the modulus
C     of LFUNC(XOPT+D), subject to the bound ||D|| .LE. DELTA, where LFUNC is
C     the KNEW-th Lagrange function.
C
C     Set some constants.
C
      HALF=0.5D0
      ONE=1.0D0
      ZERO=0.0D0
      TWOPI=8.0D0*DATAN(ONE)
      DELSQ=DELTA*DELTA
      NPTM=NPT-N-1
C
C     Set the first NPT components of HCOL to the leading elements of the
C     KNEW-th column of H.
C
      ITERC=0
      DO 10 K=1,NPT
   10 HCOL(K)=ZERO
      DO 20 J=1,NPTM
      TEMP=ZMAT(KNEW,J)
      IF (J .LT. IDZ) TEMP=-TEMP
      DO 20 K=1,NPT
   20 HCOL(K)=HCOL(K)+TEMP*ZMAT(K,J)
      ALPHA=HCOL(KNEW)
C
C     Set the unscaled initial direction D. Form the gradient of LFUNC at
C     XOPT, and multiply D by the second derivative matrix of LFUNC.
C
      DD=ZERO
      DO 30 I=1,N
      D(I)=XPT(KNEW,I)-XOPT(I)
      GC(I)=BMAT(KNEW,I)
      GD(I)=ZERO
   30 DD=DD+D(I)**2
      DO 50 K=1,NPT
      TEMP=ZERO
      SUM=ZERO
      DO 40 J=1,N
      TEMP=TEMP+XPT(K,J)*XOPT(J)
   40 SUM=SUM+XPT(K,J)*D(J)
      TEMP=HCOL(K)*TEMP
      SUM=HCOL(K)*SUM
      DO 50 I=1,N
      GC(I)=GC(I)+TEMP*XPT(K,I)
   50 GD(I)=GD(I)+SUM*XPT(K,I)
C
C     Scale D and GD, with a sign change if required. Set S to another
C     vector in the initial two dimensional subspace.
C
      GG=ZERO
      SP=ZERO
      DHD=ZERO
      DO 60 I=1,N
      GG=GG+GC(I)**2
      SP=SP+D(I)*GC(I)
   60 DHD=DHD+D(I)*GD(I)
      SCALE=DELTA/DSQRT(DD)
      IF (SP*DHD .LT. ZERO) SCALE=-SCALE
      TEMP=ZERO
      IF (SP*SP .GT. 0.99D0*DD*GG) TEMP=ONE
      TAU=SCALE*(DABS(SP)+HALF*SCALE*DABS(DHD))
      IF (GG*DELSQ .LT. 0.01D0*TAU*TAU) TEMP=ONE
      DO 70 I=1,N
      D(I)=SCALE*D(I)
      GD(I)=SCALE*GD(I)
   70 S(I)=GC(I)+TEMP*GD(I)
C
C     Begin the iteration by overwriting S with a vector that has the
C     required length and direction, except that termination occurs if
C     the given D and S are nearly parallel.
C
   80 ITERC=ITERC+1
      DD=ZERO
      SP=ZERO
      SS=ZERO
      DO 90 I=1,N
      DD=DD+D(I)**2
      SP=SP+D(I)*S(I)
   90 SS=SS+S(I)**2
      TEMP=DD*SS-SP*SP
      IF (TEMP .LE. 1.0D-8*DD*SS) GOTO 160
      DENOM=DSQRT(TEMP)
      DO 100 I=1,N
      S(I)=(DD*S(I)-SP*D(I))/DENOM
  100 W(I)=ZERO
C
C     Calculate the coefficients of the objective function on the circle,
C     beginning with the multiplication of S by the second derivative matrix.
C
      DO 120 K=1,NPT
      SUM=ZERO
      DO 110 J=1,N
  110 SUM=SUM+XPT(K,J)*S(J)
      SUM=HCOL(K)*SUM
      DO 120 I=1,N
  120 W(I)=W(I)+SUM*XPT(K,I)
      CF1=ZERO
      CF2=ZERO
      CF3=ZERO
      CF4=ZERO
      CF5=ZERO
      DO 130 I=1,N
      CF1=CF1+S(I)*W(I)
      CF2=CF2+D(I)*GC(I)
      CF3=CF3+S(I)*GC(I)
      CF4=CF4+D(I)*GD(I)
  130 CF5=CF5+S(I)*GD(I)
      CF1=HALF*CF1
      CF4=HALF*CF4-CF1
C
C     Seek the value of the angle that maximizes the modulus of TAU.
C
      TAUBEG=CF1+CF2+CF4
      TAUMAX=TAUBEG
      TAUOLD=TAUBEG
      ISAVE=0
      IU=49
      TEMP=TWOPI/DFLOAT(IU+1)
      DO 140 I=1,IU
      ANGLE=DFLOAT(I)*TEMP
      CTH=DCOS(ANGLE)
      STH=DSIN(ANGLE)
      TAU=CF1+(CF2+CF4*CTH)*CTH+(CF3+CF5*CTH)*STH
      IF (DABS(TAU) .GT. DABS(TAUMAX)) THEN
          TAUMAX=TAU
          ISAVE=I
          TEMPA=TAUOLD
      ELSE IF (I .EQ. ISAVE+1) THEN
          TEMPB=TAU
      END IF
  140 TAUOLD=TAU
      IF (ISAVE .EQ. 0) TEMPA=TAU
      IF (ISAVE .EQ. IU) TEMPB=TAUBEG
      STEP=ZERO
      IF (TEMPA .NE. TEMPB) THEN
          TEMPA=TEMPA-TAUMAX
          TEMPB=TEMPB-TAUMAX
          STEP=HALF*(TEMPA-TEMPB)/(TEMPA+TEMPB)
      END IF
      ANGLE=TEMP*(DFLOAT(ISAVE)+STEP)
C
C     Calculate the new D and GD. Then test for convergence.
C
      CTH=DCOS(ANGLE)
      STH=DSIN(ANGLE)
      TAU=CF1+(CF2+CF4*CTH)*CTH+(CF3+CF5*CTH)*STH
      DO 150 I=1,N
      D(I)=CTH*D(I)+STH*S(I)
      GD(I)=CTH*GD(I)+STH*W(I)
  150 S(I)=GC(I)+GD(I)
      IF (DABS(TAU) .LE. 1.1D0*DABS(TAUBEG)) GOTO 160
      IF (ITERC .LT. N) GOTO 80
  160 RETURN
      END


      SUBROUTINE BIGDEN (N,NPT,XOPT,XPT,BMAT,ZMAT,IDZ,NDIM,KOPT,
     1  KNEW,D,W,VLAG,BETA,S,WVEC,PROD)
      IMPLICIT REAL*8 (A-H,O-Z)
      DIMENSION XOPT(*),XPT(NPT,*),BMAT(NDIM,*),ZMAT(NPT,*),D(*),
     1  W(*),VLAG(*),S(*),WVEC(NDIM,*),PROD(NDIM,*)
      DIMENSION DEN(9),DENEX(9),PAR(9)
C
C     N is the number of variables.
C     NPT is the number of interpolation equations.
C     XOPT is the best interpolation point so far.
C     XPT contains the coordinates of the current interpolation points.
C     BMAT provides the last N columns of H.
C     ZMAT and IDZ give a factorization of the first NPT by NPT submatrix of H.
C     NDIM is the first dimension of BMAT and has the value NPT+N.
C     KOPT is the index of the optimal interpolation point.
C     KNEW is the index of the interpolation point that is going to be moved.
C     D will be set to the step from XOPT to the new point, and on entry it
C       should be the D that was calculated by the last call of BIGLAG. The
C       length of the initial D provides a trust region bound on the final D.
C     W will be set to Wcheck for the final choice of D.
C     VLAG will be set to Theta*Wcheck+e_b for the final choice of D.
C     BETA will be set to the value that will occur in the updating formula
C       when the KNEW-th interpolation point is moved to its new position.
C     S, WVEC, PROD and the private arrays DEN, DENEX and PAR will be used
C       for working space.
C
C     D is calculated in a way that should provide a denominator with a large
C     modulus in the updating formula when the KNEW-th interpolation point is
C     shifted to the new position XOPT+D.
C
C     Set some constants.
C
      HALF=0.5D0
      ONE=1.0D0
      QUART=0.25D0
      TWO=2.0D0
      ZERO=0.0D0
      TWOPI=8.0D0*DATAN(ONE)
      NPTM=NPT-N-1
C
C     Store the first NPT elements of the KNEW-th column of H in W(N+1)
C     to W(N+NPT).
C
      DO 10 K=1,NPT
   10 W(N+K)=ZERO
      DO 20 J=1,NPTM
      TEMP=ZMAT(KNEW,J)
      IF (J .LT. IDZ) TEMP=-TEMP
      DO 20 K=1,NPT
   20 W(N+K)=W(N+K)+TEMP*ZMAT(K,J)
      ALPHA=W(N+KNEW)
C
C     The initial search direction D is taken from the last call of BIGLAG,
C     and the initial S is set below, usually to the direction from X_OPT
C     to X_KNEW, but a different direction to an interpolation point may
C     be chosen, in order to prevent S from being nearly parallel to D.
C
      DD=ZERO
      DS=ZERO
      SS=ZERO
      XOPTSQ=ZERO
      DO 30 I=1,N
      DD=DD+D(I)**2
      S(I)=XPT(KNEW,I)-XOPT(I)
      DS=DS+D(I)*S(I)
      SS=SS+S(I)**2
   30 XOPTSQ=XOPTSQ+XOPT(I)**2
      IF (DS*DS .GT. 0.99D0*DD*SS) THEN
          KSAV=KNEW
          DTEST=DS*DS/SS
          DO 50 K=1,NPT
          IF (K .NE. KOPT) THEN
              DSTEMP=ZERO
              SSTEMP=ZERO
              DO 40 I=1,N
              DIFF=XPT(K,I)-XOPT(I)
              DSTEMP=DSTEMP+D(I)*DIFF
   40         SSTEMP=SSTEMP+DIFF*DIFF
              IF (DSTEMP*DSTEMP/SSTEMP .LT. DTEST) THEN
                  KSAV=K
                  DTEST=DSTEMP*DSTEMP/SSTEMP
                  DS=DSTEMP
                  SS=SSTEMP
              END IF
          END IF
   50     CONTINUE
          DO 60 I=1,N
   60     S(I)=XPT(KSAV,I)-XOPT(I)
      END IF
      SSDEN=DD*SS-DS*DS
      ITERC=0
      DENSAV=ZERO
C
C     Begin the iteration by overwriting S with a vector that has the
C     required length and direction.
C
   70 ITERC=ITERC+1
      TEMP=ONE/DSQRT(SSDEN)
      XOPTD=ZERO
      XOPTS=ZERO
      DO 80 I=1,N
      S(I)=TEMP*(DD*S(I)-DS*D(I))
      XOPTD=XOPTD+XOPT(I)*D(I)
   80 XOPTS=XOPTS+XOPT(I)*S(I)
C
C     Set the coefficients of the first two terms of BETA.
C
      TEMPA=HALF*XOPTD*XOPTD
      TEMPB=HALF*XOPTS*XOPTS
      DEN(1)=DD*(XOPTSQ+HALF*DD)+TEMPA+TEMPB
      DEN(2)=TWO*XOPTD*DD
      DEN(3)=TWO*XOPTS*DD
      DEN(4)=TEMPA-TEMPB
      DEN(5)=XOPTD*XOPTS
      DO 90 I=6,9
   90 DEN(I)=ZERO
C
C     Put the coefficients of Wcheck in WVEC.
C
      DO 110 K=1,NPT
      TEMPA=ZERO
      TEMPB=ZERO
      TEMPC=ZERO
      DO 100 I=1,N
      TEMPA=TEMPA+XPT(K,I)*D(I)
      TEMPB=TEMPB+XPT(K,I)*S(I)
  100 TEMPC=TEMPC+XPT(K,I)*XOPT(I)
      WVEC(K,1)=QUART*(TEMPA*TEMPA+TEMPB*TEMPB)
      WVEC(K,2)=TEMPA*TEMPC
      WVEC(K,3)=TEMPB*TEMPC
      WVEC(K,4)=QUART*(TEMPA*TEMPA-TEMPB*TEMPB)
  110 WVEC(K,5)=HALF*TEMPA*TEMPB
      DO 120 I=1,N
      IP=I+NPT
      WVEC(IP,1)=ZERO
      WVEC(IP,2)=D(I)
      WVEC(IP,3)=S(I)
      WVEC(IP,4)=ZERO
  120 WVEC(IP,5)=ZERO
C
C     Put the coefficents of THETA*Wcheck in PROD.
C
      DO 190 JC=1,5
      NW=NPT
      IF (JC .EQ. 2 .OR. JC .EQ. 3) NW=NDIM
      DO 130 K=1,NPT
  130 PROD(K,JC)=ZERO
      DO 150 J=1,NPTM
      SUM=ZERO
      DO 140 K=1,NPT
  140 SUM=SUM+ZMAT(K,J)*WVEC(K,JC)
      IF (J .LT. IDZ) SUM=-SUM
      DO 150 K=1,NPT
  150 PROD(K,JC)=PROD(K,JC)+SUM*ZMAT(K,J)
      IF (NW .EQ. NDIM) THEN
          DO 170 K=1,NPT
          SUM=ZERO
          DO 160 J=1,N
  160     SUM=SUM+BMAT(K,J)*WVEC(NPT+J,JC)
  170     PROD(K,JC)=PROD(K,JC)+SUM
      END IF
      DO 190 J=1,N
      SUM=ZERO
      DO 180 I=1,NW
  180 SUM=SUM+BMAT(I,J)*WVEC(I,JC)
  190 PROD(NPT+J,JC)=SUM
C
C     Include in DEN the part of BETA that depends on THETA.
C
      DO 210 K=1,NDIM
      SUM=ZERO
      DO 200 I=1,5
      PAR(I)=HALF*PROD(K,I)*WVEC(K,I)
  200 SUM=SUM+PAR(I)
      DEN(1)=DEN(1)-PAR(1)-SUM
      TEMPA=PROD(K,1)*WVEC(K,2)+PROD(K,2)*WVEC(K,1)
      TEMPB=PROD(K,2)*WVEC(K,4)+PROD(K,4)*WVEC(K,2)
      TEMPC=PROD(K,3)*WVEC(K,5)+PROD(K,5)*WVEC(K,3)
      DEN(2)=DEN(2)-TEMPA-HALF*(TEMPB+TEMPC)
      DEN(6)=DEN(6)-HALF*(TEMPB-TEMPC)
      TEMPA=PROD(K,1)*WVEC(K,3)+PROD(K,3)*WVEC(K,1)
      TEMPB=PROD(K,2)*WVEC(K,5)+PROD(K,5)*WVEC(K,2)
      TEMPC=PROD(K,3)*WVEC(K,4)+PROD(K,4)*WVEC(K,3)
      DEN(3)=DEN(3)-TEMPA-HALF*(TEMPB-TEMPC)
      DEN(7)=DEN(7)-HALF*(TEMPB+TEMPC)
      TEMPA=PROD(K,1)*WVEC(K,4)+PROD(K,4)*WVEC(K,1)
      DEN(4)=DEN(4)-TEMPA-PAR(2)+PAR(3)
      TEMPA=PROD(K,1)*WVEC(K,5)+PROD(K,5)*WVEC(K,1)
      TEMPB=PROD(K,2)*WVEC(K,3)+PROD(K,3)*WVEC(K,2)
      DEN(5)=DEN(5)-TEMPA-HALF*TEMPB
      DEN(8)=DEN(8)-PAR(4)+PAR(5)
      TEMPA=PROD(K,4)*WVEC(K,5)+PROD(K,5)*WVEC(K,4)
  210 DEN(9)=DEN(9)-HALF*TEMPA
C
C     Extend DEN so that it holds all the coefficients of DENOM.
C
      SUM=ZERO
      DO 220 I=1,5
      PAR(I)=HALF*PROD(KNEW,I)**2
  220 SUM=SUM+PAR(I)
      DENEX(1)=ALPHA*DEN(1)+PAR(1)+SUM
      TEMPA=TWO*PROD(KNEW,1)*PROD(KNEW,2)
      TEMPB=PROD(KNEW,2)*PROD(KNEW,4)
      TEMPC=PROD(KNEW,3)*PROD(KNEW,5)
      DENEX(2)=ALPHA*DEN(2)+TEMPA+TEMPB+TEMPC
      DENEX(6)=ALPHA*DEN(6)+TEMPB-TEMPC
      TEMPA=TWO*PROD(KNEW,1)*PROD(KNEW,3)
      TEMPB=PROD(KNEW,2)*PROD(KNEW,5)
      TEMPC=PROD(KNEW,3)*PROD(KNEW,4)
      DENEX(3)=ALPHA*DEN(3)+TEMPA+TEMPB-TEMPC
      DENEX(7)=ALPHA*DEN(7)+TEMPB+TEMPC
      TEMPA=TWO*PROD(KNEW,1)*PROD(KNEW,4)
      DENEX(4)=ALPHA*DEN(4)+TEMPA+PAR(2)-PAR(3)
      TEMPA=TWO*PROD(KNEW,1)*PROD(KNEW,5)
      DENEX(5)=ALPHA*DEN(5)+TEMPA+PROD(KNEW,2)*PROD(KNEW,3)
      DENEX(8)=ALPHA*DEN(8)+PAR(4)-PAR(5)
      DENEX(9)=ALPHA*DEN(9)+PROD(KNEW,4)*PROD(KNEW,5)
C
C     Seek the value of the angle that maximizes the modulus of DENOM.
C
      SUM=DENEX(1)+DENEX(2)+DENEX(4)+DENEX(6)+DENEX(8)
      DENOLD=SUM
      DENMAX=SUM
      ISAVE=0
      IU=49
      TEMP=TWOPI/DFLOAT(IU+1)
      PAR(1)=ONE
      DO 250 I=1,IU
      ANGLE=DFLOAT(I)*TEMP
      PAR(2)=DCOS(ANGLE)
      PAR(3)=DSIN(ANGLE)
      DO 230 J=4,8,2
      PAR(J)=PAR(2)*PAR(J-2)-PAR(3)*PAR(J-1)
  230 PAR(J+1)=PAR(2)*PAR(J-1)+PAR(3)*PAR(J-2)
      SUMOLD=SUM
      SUM=ZERO
      DO 240 J=1,9
  240 SUM=SUM+DENEX(J)*PAR(J)
      IF (DABS(SUM) .GT. DABS(DENMAX)) THEN
          DENMAX=SUM
          ISAVE=I
          TEMPA=SUMOLD
      ELSE IF (I .EQ. ISAVE+1) THEN
          TEMPB=SUM
      END IF
  250 CONTINUE
      IF (ISAVE .EQ. 0) TEMPA=SUM
      IF (ISAVE .EQ. IU) TEMPB=DENOLD
      STEP=ZERO
      IF (TEMPA .NE. TEMPB) THEN
          TEMPA=TEMPA-DENMAX
          TEMPB=TEMPB-DENMAX
          STEP=HALF*(TEMPA-TEMPB)/(TEMPA+TEMPB)
      END IF
      ANGLE=TEMP*(DFLOAT(ISAVE)+STEP)
C
C     Calculate the new parameters of the denominator, the new VLAG vector
C     and the new D. Then test for convergence.
C
      PAR(2)=DCOS(ANGLE)
      PAR(3)=DSIN(ANGLE)
      DO 260 J=4,8,2
      PAR(J)=PAR(2)*PAR(J-2)-PAR(3)*PAR(J-1)
  260 PAR(J+1)=PAR(2)*PAR(J-1)+PAR(3)*PAR(J-2)
      BETA=ZERO
      DENMAX=ZERO
      DO 270 J=1,9
      BETA=BETA+DEN(J)*PAR(J)
  270 DENMAX=DENMAX+DENEX(J)*PAR(J)
      DO 280 K=1,NDIM
      VLAG(K)=ZERO
      DO 280 J=1,5
  280 VLAG(K)=VLAG(K)+PROD(K,J)*PAR(J)
      TAU=VLAG(KNEW)
      DD=ZERO
      TEMPA=ZERO
      TEMPB=ZERO
      DO 290 I=1,N
      D(I)=PAR(2)*D(I)+PAR(3)*S(I)
      W(I)=XOPT(I)+D(I)
      DD=DD+D(I)**2
      TEMPA=TEMPA+D(I)*W(I)
  290 TEMPB=TEMPB+W(I)*W(I)
      IF (ITERC .GE. N) GOTO 340
      IF (ITERC .GT. 1) DENSAV=DMAX1(DENSAV,DENOLD)
      IF (DABS(DENMAX) .LE. 1.1D0*DABS(DENSAV)) GOTO 340
      DENSAV=DENMAX
C
C     Set S to half the gradient of the denominator with respect to D.
C     Then branch for the next iteration.
C
      DO 300 I=1,N
      TEMP=TEMPA*XOPT(I)+TEMPB*D(I)-VLAG(NPT+I)
  300 S(I)=TAU*BMAT(KNEW,I)+ALPHA*TEMP
      DO 320 K=1,NPT
      SUM=ZERO
      DO 310 J=1,N
  310 SUM=SUM+XPT(K,J)*W(J)
      TEMP=(TAU*W(N+K)-ALPHA*VLAG(K))*SUM
      DO 320 I=1,N
  320 S(I)=S(I)+TEMP*XPT(K,I)
      SS=ZERO
      DS=ZERO
      DO 330 I=1,N
      SS=SS+S(I)**2
  330 DS=DS+D(I)*S(I)
      SSDEN=DD*SS-DS*DS
      IF (SSDEN .GE. 1.0D-8*DD*SS) GOTO 70
C
C     Set the vector W before the RETURN from the subroutine.
C
  340 DO 350 K=1,NDIM
      W(K)=ZERO
      DO 350 J=1,5
  350 W(K)=W(K)+WVEC(K,J)*PAR(J)
      VLAG(KOPT)=VLAG(KOPT)+ONE
      RETURN
      END


#include "qss_signal.h"

double minposroot(double *coeff, int order) {
  double mpr;
  switch (order) {
  case 0:
   mpr=INF;
       break;
  case 1:
    if (coeff[1]==0) {
      mpr=INF;
    } else {
      mpr=-coeff[0]/coeff[1];
    };
    if (mpr<0) mpr=INF;
    break;
  case 2:
  if (coeff[2]==0 || (1000*fabs(coeff[2]))<fabs(coeff[1])){
       if (coeff[1]==0) {
   mpr=INF;
       } else {
   mpr=-coeff[0]/coeff[1];
       };
       if (mpr<0) mpr=INF;
      } else {
       double disc;
       disc=coeff[1]*coeff[1]-4*coeff[2]*coeff[0];
       if (disc<0) {
   //no real roots
   mpr=INF;
       } else {
   double sd,r1;
   sd=sqrt(disc);
   r1=(-coeff[1]+sd)/2/coeff[2];
   if (r1>0) {
     mpr=r1;
   } else {
     mpr=INF;
   };
   r1=(-coeff[1]-sd)/2/coeff[2];
   if ((r1>0)&&(r1<mpr)) mpr=r1;
       };
      };
      break;

  case 3:
    if ((coeff[3]==0)||(1000*fabs(coeff[3])<fabs(coeff[2]))) {
      mpr=minposroot(coeff,2);
    } else {
      double q,r,disc;
      q=(3*coeff[3]*coeff[1]-coeff[2]*coeff[2])/9/coeff[3]/coeff[3];
      r=(9*coeff[3]*coeff[2]*coeff[1]-27*coeff[3]*coeff[3]*coeff[0]-2*coeff[2]*coeff[2]*coeff[2])/54/coeff[3]/coeff[3]/coeff[3];
      disc=q*q*q+r*r;
      mpr=INF;
      if (disc>=0) {
       //only one real root
       double sd,s,t,r1;
       sd=sqrt(disc);
       if (r+sd>0) {
   s=pow(r+sd,1.0/3);
       } else {
   s=-pow(fabs(r+sd),1.0/3);
       };
       if (r-sd>0) {
   t=pow(r-sd,1.0/3);
       } else {
   t=-pow(fabs(r-sd),1.0/3);
       };
       r1=s+t-coeff[2]/3/coeff[3];
       if (r1>0) mpr=r1;
      }  else {
       //three real roots
       double rho,th,rho13,costh3,sinth3,spt,smti32,r1;
  rho=sqrt(-q*q*q);
       th=acos(r/rho);
       rho13=pow(rho,1.0/3);
       costh3=cos(th/3);
       sinth3=sin(th/3);
       spt=rho13*2*costh3;
       smti32=-rho13*sinth3*sqrt(3);
       r1=spt-coeff[2]/3/coeff[3];
       if (r1>0) mpr=r1;
       r1=-spt/2-coeff[2]/3/coeff[3]+smti32;
       if ((r1>0)&&(r1<mpr)) mpr=r1;
       r1=r1-2*smti32;
       if ((r1>0)&&(r1<mpr)) mpr=r1;
      };

    };

    break;
  case 4:
    //Based on Ferrari's Method
    if ((coeff[4]==0)||(1000*fabs(coeff[4])<fabs(coeff[3]))) {
      mpr=minposroot(coeff,3);
    } else {
      double p,q,r,z0,b1,c1a,c1b,db1,dc1a,r1;
      p=-3*coeff[3]*coeff[3]/8/coeff[4]/coeff[4]+coeff[2]/coeff[4];
      q=coeff[3]*coeff[3]*coeff[3]/8/coeff[4]/coeff[4]/coeff[4]-coeff[3]*coeff[2]/2/coeff[4]/coeff[4]+coeff[1]/coeff[4];
      r=-3*pow(coeff[3],4)/256/pow(coeff[4],4)+coeff[2]*coeff[3]*coeff[3]/16/pow(coeff[4],3)-coeff[3]*coeff[1]/4/coeff[4]/coeff[4]+coeff[0]/coeff[4];
      double co[4];
      co[0]=-q*q;
      co[1]=p*p-4*r;
      co[2]=2*p;
      co[3]=1;
      z0=minposroot(&co[0],3);
      b1=-sqrt(z0);
      c1a=(p+z0)/2;
      c1b=-q/2/b1;
      db1=coeff[3]/2/coeff[4];
      dc1a=coeff[3]*coeff[3]/16/coeff[4]/coeff[4];
      mpr=INF;
      co[0]=c1a+c1b+b1/2*db1+dc1a;
      co[1]=b1+db1;
      co[2]=1;
      r1=minposroot(&co[0],2);
      if (r1>0) mpr=r1;
      co[0]=c1a-c1b-b1/2*db1+dc1a;
      co[1]=-b1+db1;
      r1=minposroot(&co[0],2);
      if ((r1>0)&&(r1<mpr))mpr=r1;

    };
    break;

  };
  return mpr;
}


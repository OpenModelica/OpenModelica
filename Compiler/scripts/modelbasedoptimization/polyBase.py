#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# This file is part of OpenModelica.
#
# Copyright (c) 1998-CurrentYear, Linköping University,
# Department of Computer and Information Science,
# SE-58183 Linköping, Sweden.
#
# All rights reserved.
#
# THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
# AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
# ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
# ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
#
# The OpenModelica software and the Open Source Modelica
# Consortium (OSMC) Public License (OSMC-PL) are obtained
# from Linköping University, either from the above address,
# from the URLs: http://www.ida.liu.se/projects/OpenModelica or
# http://www.openmodelica.org, and in the OpenModelica distribution.
# GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
#
# This program is distributed WITHOUT ANY WARRANTY; without
# even the implied warranty of  MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
# IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
# OF OSMC-PL.
#
# See the full OSMC Public License conditions for more details.
#
#

'''
Created on 04.12.2012

@authors: Vitalij Ruge 
'''
import numpy as NP

def Lpoly(points,j,t,m):
    return NP.prod([(t - points[i] )/(points[j] - points[i]) if i != j else 1.0 for i in xrange(m)])

def JacobiPolyRoots(a,b,n, legendre = False):
    ab = a + b
    ba = b - a
    d1 = lambda j: (ba)*ab / ((2.0*j + ab  ) * (2.0*(j+1.0) + ab  )) if j > 0 else (ba)/(2.0+ab) 
    d2 = lambda j: 2.0*NP.sqrt((j*(a+j)*(b+j)*(ab+j)) /((ab + 2.0*j-1.0)*(ab + 2*j)**2*(ab + 2.0*j +1.0)))
    
    dn = 0
    dn += 1 if b == 1 else 0 
    dn += 1 if a == 1 else 0
    
    D1 = [d1(j) for j in xrange(n-dn)]
    D2 = [d2(j) for j in xrange(1,n-dn)]
     
    J = NP.diag(D1) + NP.diag(D2, 1) + NP.diag(D2, -1)
    
    if legendre:
        r,v = NP.linalg.eigh(J)
        w = 2*v[0,:]**2
        return r,w
    else:
        if n - dn>0:
            r = NP.linalg.eigvalsh(J)
        else:
            r = []
        if a ==1:
            r = NP.hstack([r[:],1])
        if b ==1:
            r = NP.hstack([-1,r[:]])
        return r

def JacobiPolyWeigths(r):
    m = len(r)
    n = int(0.5*m)+1
    w = NP.zeros((m))
    tL, wL = JacobiPolyRoots(0, 0, n, True)
    
    for k in xrange(m):
        w[k] = NP.sum([ wL[j]*Lpoly(r,k,tL[j],m) for j in xrange(n)])
    return w


def RadauRootsWeights(n):
    r = JacobiPolyRoots(1,0,n)
    w = JacobiPolyWeigths(r)
    return r,w

def radauBase(m):
    r,w = RadauRootsWeights(m)
    r = 0.5*(r + 1.0)
    w *= 0.5
    
    m += 1
    r = NP.hstack([0.0 , r])
    w = NP.hstack([0.0 , w])
    P = NP.zeros((m-1,m))
    
    for j in xrange(m):
        for t in xrange(1,m):
            P[t-1,j] = sum([ 1.0/(r[j] - r[m1]) * 
                                   NP.prod( [ (r[t] - r[m2] )/(r[j] - r[m2]) 
                                             if m2 !=m1 and m2 != j else 1.0 for m2 in xrange(m)])
                                   if m1 != j else 0.0 for m1 in xrange(m)]
                                  )
    return r,w, P

def LobattoRootsWeights(n):
    r = JacobiPolyRoots(1,1,n)
    w = JacobiPolyWeigths(r)
    return r,w
    
def lobattoBase(m):
    Q = NP.zeros((m-1,m))
    r,w = LobattoRootsWeights(m)
    r = 0.5*(r + 1.0)
    w *= 0.5
    for j in xrange(m):
        for t in xrange(1,m):
            Q[t-1,j] = r[t]* sum([ w[i]*Lpoly(r,j,r[i]*r[t],m) for i in xrange(m)])
    return r,w, Q

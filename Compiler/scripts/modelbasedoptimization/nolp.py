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
Created on 05.12.2012

@authors: Vitalij Ruge, Bernhard Bachmann, Lennart Ochel, Willi Braun 
'''

import casADiEnv
from polyBase import radauBase, lobattoBase
import casadi as cas
import numpy as NP
from casADiInterface import xmlModel
from sys import exit, argv

class MPC():
    def __init__(self, Modell, NSI = 128, m = 3):
        """
        NSI = Number of subintervalls
        m = Number of collocation points
        """
        if m < 1:
            raise IOError('Number of collocation points must be bigger then 1.')
        
        self.m = m
        self.NSI = NSI
        self.md = Modell
        
        self.__create_auxiliary_value()
        self.__Bound_and_Init()
        self.__create_object_func()
        self.__create_constrains()
        
    def __create_auxiliary_value(self):
        self.mm = self.m + 1
        
        self.tau, self.qw, self.Q = radauBase(self.m)
        self.ltau, self.lqw, self.lQ = lobattoBase(self.mm)
        
        self.NSP = self.NSI + 1
        self.NSXP = (self.m*self.NSI + 1)
        self.NSUP = self.NSXP
        
        self.dt = (self.md.tf - self.md.t0)/self.NSI
        self.t = cas.ssym("t",(self.mm))
        
        self.X = cas.ssym("x",(self.md.nx, self.NSXP)) # state
        self.XA = cas.ssym("xa",(self.md.nxa, self.NSXP))
        
        self.U = cas.ssym("u",(self.md.nu, self.NSUP))
        self.P = cas.ssym("p",(self.md.np))
        
        self.T = cas.SXMatrix.zeros(self.NSI, self.mm)
        for i in xrange(1,self.NSI):
            for k in xrange(self.mm):
                self.T[i,k] = self.md.t0 + self.dt*i + self.tau[k]*self.dt
                
        for k in xrange(self.mm):
            self.T[0,k] = self.md.t0  + self.ltau[k]*self.dt
                
    def __Bound_and_Init(self):
        self.Xmin, self.Xmax, self.Xinit = self.__set_Bound_and_Init(self.md.nx, self.NSXP, self.md.xmin, self.md.xmax, self.md.xinit)
        self.XAmin, self.XAmax, self.XAinit = self.__set_Bound_and_Init(self.md.nxa, self.NSXP,self.md.xamin, self.md.xamax, self.md.xainit)
        self.Umin, self.Umax, self.Uinit = self.__set_Bound_and_Init(self.md.nu, self.NSUP, self.md.umin, self.md.umax, self.md.uinit)
        self.Pmin, self.Pmax, self.Pinit = self.__set_Bound_and_Init(self.md.np, 1, self.md.pmin, self.md.pmax, self.md.pinit)
        
        self.V = self.__old_veccat([self.X.T, self.XA.T, self.P.T, self.U.T])
        
    def __set_Bound_and_Init(self, n, m, vmin, vmax, vinit):
        VMin = NP.zeros((n, m))
        VMax = NP.zeros((n, m))
        Vinit = NP.zeros((n, m))
        for i in xrange(n):
            VMin[i,:] = NP.array(m*[vmin[i]])
            VMax[i,:] = NP.array(m*[vmax[i]])
            Vinit[i,:] = NP.array(m*[vinit[i]])
        return VMin, VMax, Vinit
    
    def __Lagrange_terms(self):
        if self.md.L is None:
            return cas.SXMatrix(0.0)
        
        Le = self.md.L.eval
        L = cas.SX(0.0)
        
        for j in xrange(0,self.mm):
            zj = self.__getZj(j)
            L += self.lqw[j]*Le([zj])[0]     
        
        objcL = L
        
        L = cas.SX(0.0)
        for j in xrange(1,self.mm):
            zj = self.__getZj(j)
            L += self.qw[j]*Le([zj])[0]
        
        Z0 = self.__getZi(0)
        LS = cas.SXFunction([Z0],[L])
        LS.init()
        LSe = LS.eval
        
        for i in xrange(1,self.NSI):
            ZiT = self.__getZiT(i)
            objcL += LSe([ZiT])[0]
            
        return objcL*self.dt
    
    def __Mayer_terms(self):
        if self.md.M is None:
            return cas.SXMatrix(0.0)
        Me = self.md.M.eval
        Zn = cas.veccat([self.md.tf,self.X[:,-1], self.XA[:,-1],self.P,self.U[:,-1]])
        return Me([Zn])[0]
    
    def __create_object_func(self):
        self.F = cas.SXFunction([self.V], [self.__Lagrange_terms() + self.__Mayer_terms()])
        self.F.init()
        
    def __create_modell_residual(self):
        ode = self.md.f.eval
        f = cas.SXMatrix(self.md.nx, self.m)
        
        for j in xrange(1,self.mm):
            Zj = self.__getZj(j)
            f[:,j-1] = ode([Zj])[0]
        
        P = cas.SXMatrix(self.Q)
        X1 = self.X[:,:self.mm]
        f_system = cas.mul(X1,P.T) - self.dt*f
        self.f_system_radau = cas.vec(f_system)
        
        f = cas.SXMatrix(self.md.nx, self.mm)
        for j in xrange(self.mm):
            Zj = self.__getZj(j)
            f[:,j] = ode([Zj])[0]
        Q = cas.SXMatrix(self.lQ)
        X0 = cas.reshape(cas.veccat(self.m*[ self.X[:,0]]),(self.m, self.md.nx))
        X1 = self.X[:,1:self.mm].T

        f_system = (X0 - X1) + self.dt*cas.mul(Q,f.T) 
        self.f_system_lobatto = cas.vec(f_system)
        
    def __create_constrains(self):
        self.__create_modell_residual()
        
        if self.md.nxa >1:
            algeval = self.md.alg.eval
            alg = cas.SXMatrix(self.md.nxa, self.m)
            for j in xrange(1,self.mm):
                Zj = self.__getZj(j,  j)
                alg[:,j-1] = algeval([Zj])[0]
            alg = cas.vec(alg)
            self.f_system_radau.append(alg)
            self.f_system_lobatto.append(alg)
        g = cas.SXMatrix()
        if not self.md.F0 is None:
            Z0 = self.__old_veccat([self.T[0,0],self.X[:,0], self.XA[:,0],self.P,self.U[:,0]])
            F0 = self.md.f.eval([Z0])[0]
            ZZ0 = self.__old_veccat([
                              self.T[0,0],self.X[:,0], self.XA[:,0],self.P,self.U[:,0],F0
                              ])
            g.append(self.md.F0.eval([ZZ0])[0])
            
        ZS = self.__getZi(0)
        fs = cas.SXFunction([ZS], [self.f_system_lobatto])
        fs.init()
        fe = fs.eval
        Z0 = self.__getZiT(0)
        g.append(fe([ZS])[0])
        
        fs = cas.SXFunction([ZS], [self.f_system_radau])
        fs.init()
        fe = fs.eval
        
        for i in xrange(1,self.NSI):
            ZS = self.__getZiT(i)
            g.append(fe([ZS])[0])
        
        self.g_max = NP.zeros(g.shape)
        self.g_min = NP.zeros(g.shape)
        
        if not self.md.pathc is None:
            patheval = self.md.pathc.eval
            path = cas.SXMatrix()
            
            for j in xrange(1,self.mm):
                Zj = self.__getZj(j)
                path.append(patheval([Zj])[0])
                
            path = cas.vec(path)
            ZS = self.__getZi(0)
            fs = cas.SXFunction([ZS], [path])
            
            fs.init()
            fe = fs.eval
            ub = NP.array(self.m * [self.md.gpub])
            lb = NP.array(self.m* [self.md.gplb])
            ub = cas.vec(ub.T)
            lb = cas.vec(lb.T)

            for i in xrange(0,self.NSI):
                ZS = self.__getZiT(i)
                g.append(fe([ZS])[0])
                self.g_max = NP.vstack([self.g_max,ub])
                self.g_min = NP.vstack([self.g_min,lb])
                
        self.G = cas.SXFunction([self.V],[g])
    
    def __call__(self,max_iter = 1000, Hessian = True):
        try:
            self.solver = cas.IpoptSolver(self.F, self.G)
            self.solver.setOption("max_iter",max_iter)
            self.solver.setOption("generate_hessian", Hessian)
            self.solver.setOption("print_level", 5)
        except:
            print("\n\n#######################################################")
            print("########### Warning: not find IpoptSolver ##############")
            print("#######################################################\n\n")
            tmp=raw_input('try SQPMethod?(y/n): ')
            if tmp != "y":
                exit(-1)
            tmp=raw_input('sure?(y/n): ')
            if tmp != "y":
                exit(-1)
            
            print("take a rest!!!")
            
            self.solver = cas.SQPMethod(self.F, self.G)
            self.solver.setOption("generate_hessian", Hessian)
            self.solver.setOption("qp_solver",cas.QPOasesSolver)
            self.solver.setOption("maxiter", max_iter/100)
            self.solver.setOption("qp_solver_options",{"printLevel" : "none"})
            self.solver.setOption("hessian_approximation","exact")
        self.solver.init()
        
        self.time = self.__old_veccat([cas.reshape(self.T[:,:-1], (1,self.m*self.NSI)) ,  cas.vec(self.T[-1,-1])])
        self.init = True
        return self
        
    def start(self):
        if not self.init:
            self.__call__()
        self.VMIN = cas.veccat([cas.vec(self.Xmin.T), cas.vec(self.XAmin.T), cas.vec(self.Pmin.T), cas.vec(self.Umin.T)])
        self.VMAX = cas.veccat([cas.vec(self.Xmax.T), cas.vec(self.XAmax.T), cas.vec(self.Pmax.T), cas.vec(self.Umax.T)])
        self.VINIT = cas.veccat([cas.vec(self.Xinit.T), cas.vec(self.XAinit.T), cas.vec(self.Pinit.T), cas.vec(self.Uinit.T)])
            
        self.solver.setInput(self.VMIN,  cas.NLP_LBX)
        self.solver.setInput(self.VMAX,  cas.NLP_UBX)
        self.solver.setInput(self.VINIT, cas.NLP_X_INIT)

        self.solver.setInput(self.g_min, cas.NLP_LBG)
        self.solver.setInput(self.g_max, cas.NLP_UBG)

        self.solver.solve()
        v_opt = self.solver.output(cas.NLP_X_OPT)
        
        tmp0 = 0
        tmp1 = self.md.nx*self.NSXP
        xopt = v_opt[tmp0:tmp1]
        tmp0 = tmp1
        tmp1 += self.md.nxa*self.NSXP
        xaopt = v_opt[tmp0:tmp1]
        tmp0 = tmp1
        tmp1 += self.md.np
        popt = v_opt[tmp0:tmp1]
        tmp0 = tmp1
        tmp1 += self.md.nu *self.NSUP
        uopt = v_opt[tmp0:tmp1]

        self.erg_opt = float(self.solver.output(cas.NLP_COST))
        self.xopt = cas.reshape(xopt,(self.md.nx,self.NSXP))

        if self.md.nxa >0:
            self.xaopt = cas.reshape(xaopt,(self.md.nxa,self.NSXP))
        else:
            self.xaopt = []

        if self.md.nu >0:
            self.uopt = cas.reshape(uopt,(self.md.nu,self.NSUP))
        else:
            self.uopt = []

        if self.md.np >0:
            self.popt = cas.reshape(popt,(self.md.np,1))
        else:
            self.popt = []
        
    def __getZj(self,j):
        return self.__old_veccat([self.t[j], self.X[:,j], self.XA[:,j],self.P,self.U[:, j]])
    
    def __getZi(self,i):
        return self.__old_veccat([self.t, self.X[:,i*self.m:i*self.m + self.mm] , self.XA[:,i*self.m:i*self.m + self.mm], self.P, self.U[:,i*self.m:i*self.m + self.mm]])
    
    def __getZiT(self,i):
        return self.__old_veccat([self.T[i,:], self.X[:,i*self.m:i*self.m + self.mm] , self.XA[:,i*self.m:i*self.m + self.mm], self.P, self.U[:,i*self.m:i*self.m + self.mm]])
        
    def __old_veccat(self, var_list):
        z = [cas.SXMatrix(var) for var in var_list]
        return cas.veccat(z)
    
    def __str__(self):
        print self.md
        return " "
    
    def plotState(self,k = None, saveName = None):
        import matplotlib.pyplot as plt
        plt.figure(1)
        plt.clf()
        plt.title('State')

        X = self.xopt.toArray ()
        time = self.time.toArray()

        if k is None:
            k = range(self.md.nx)
        elif len(k) == 1:
            k = [k[0]]

        for i in k:
            plt.plot(time,X[i,:],'-')

        plt.legend([name for  name in self.md.var_names['x']],loc=0)
        if saveName is None:
            plt.show()
        else:
            plt.savefig(saveName)
            
    def plotControl(self,k = None, saveName = None):
        import matplotlib.pyplot as plt
        if self.md.nu < 1:
            return None
        plt.figure(1)
        plt.clf()
        plt.title('Input')

        U = self.uopt.toArray ()
        if 0:
            time = NP.linspace(self.md.t0,self.md.tf,self.NSI)
        else:
            time = self.time

        if k is None:
            k = range(self.md.nu)
        elif len(k) == 1:
            k = [k[0]]

        for i in k:
            #plt.step(time,U[i,:],'-')
            plt.plot(time,U[i,:],'-')

        plt.legend([name for  name in self.md.var_names['u']],loc=0)
        if saveName is None:
            plt.show()
        else:
            plt.savefig(saveName)
            
    def make_results(self,saveName = "results.txt"):
        f = open(saveName, 'w')
        f.write("\nx=")
        f.write(str(self.xopt))
        f.write("\n\n\nu=")
        f.write(str(self.uopt))
        f.write("\n\n\nt=")
        f.write(str(self.time))
        f.close()

def CasIpopt(MPC):
    MPC.start()
    return MPC
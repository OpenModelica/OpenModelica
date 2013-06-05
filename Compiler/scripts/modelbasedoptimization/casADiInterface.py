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

@author: Vitalij Ruge
'''

import casADiEnv

from casadi import veccat, SXFunction, SymbolicOCP, var, der, SXMatrix
import numpy as NP

class xmlModel():
    def __init__(self,xml_name = None):
        """Load XML-Model-File"""
        if xml_name is None:
            raise IOError('No such file or directory.')
        self.ocp = SymbolicOCP()
        self.ocp.parseFMI(xml_name)
        print self.ocp
        self.ocp.makeExplicit()
        self.ocp.eliminateAlgebraic()
        self.__create_vars()
        self.__create_object()
        self.__create_modell_eq()
        
    def __create_vars(self):
        self.__load_objects_vars()
        self.__make_vars_symbolic()
        self.__set_vars_names()
        self.__set_vars_bounds()
        self.__initial_eq()
        self.__path_constraints()
        
        
    def __load_objects_vars(self):
        # object states
        self.ox = self.ocp.x
        # object (strong) algebraic vars # algebraic states
        self.oxa = self.ocp.z
        # dependent variables (e.g. alg + parameter)
        self.ow = self.ocp.y
        # independent parameters
        self.op = self.ocp.pf
        # control signals
        self.ou = self.ocp.u
    
    def __make_vars_symbolic(self):
        # differential state
        self.x = var(self.ox)
        self.dx = der(self.ox)
        # algebraic states
        self.xa = var(self.oxa)
        # dependent variables (e.g. alg + parameter)
        self.w = var(self.ow)
        # independent parameters
        self.p = var(self.op)
        # control signals
        self.u = var(self.ou)
        
        # time
        self.t = self.ocp.t
        self.t0 = self.ocp.t0
        self.tf = self.ocp.tf 
        
        self.__set_var_dim()
        
        # total var          
        self.z = self.__old_veccat([self.t, self.x, self.xa,self.p,self.u])
        
    def __old_veccat(self, var_list):
        z = [SXMatrix(var) for var in var_list]
        return veccat(z)
    
    def __set_var_dim(self):
        # Count variables
        self.nx = len(self.x)
        self.nxa = len(self.xa)
        self.nw = len(self.w)
        self.np = len(self.p)
        self.nu = len(self.u)
        
    def __set_vars_names(self):
        self.var_names = {}
        # differential state
        self.__set_var_names(self.x,'x')
        self.__set_var_names(self.dx, 'dx')
        
        # algebraic states
        self.__set_var_names(self.xa, 'xa')
        
        # dependent variables (e.g. alg + parameter)
        self.__set_var_names(self.w, 'w')
        
        # independent parameters
        self.__set_var_names(self.p, 'p')
        
        # control signals
        self.__set_var_names(self.u, 'u')
        
    def __set_var_names(self, var, name):
        self.var_names[name] = []
        for v in var:
            self.var_names[name].append(v.__str__())
            
    def __set_vars_bounds(self):
        #differential states
        self.xmin, self.xmax, self.xinit = self.__set_var_bounds(self.ox)
        
        #differential algebraic
        self.xamin, self.xamax, self.xainit = self.__set_var_bounds(self.oxa)
        
        #dependent variables (e.g. alg + parameter)
        self.wmin, self.wmax, self.winit = self.__set_var_bounds(self.ow)
        
        #independent parameters
        self.pmin, self.pmax, self.pinit = self.__set_var_bounds(self.op)
        
        #control signals
        self.umin, self.umax, self.uinit = self.__set_var_bounds(self.ou)
        
    
    def __set_var_bounds(self,ovar):
        maxvar = [val.getMax() if (not val is  None) else NP.inf for val in ovar]
        minvar = [val.getMin() if (not val is  None) else -NP.inf for val in ovar]
        initvar = [val.getInitialGuess() if (not val is  None) else 0 for val in ovar]
        
        return minvar ,maxvar , initvar
    
    def __create_object(self):
        # Mayer terms
        if self.ocp.mterm.numel() > 0:
            xtime  = [val.atTime(self.tf, True) for val in self.ox]
            xatime = [val.atTime(self.tf, True) for val in self.oxa]
            ptime  = [val.atTime(self.tf, True) for val in self.op]
            utime  = [val.atTime(self.tf, True) for val in self.ou]
            ztime  = self.__old_veccat([self.t, xtime, xatime, ptime, utime])
            
            M = SXFunction([ztime], [self.ocp.mterm])
            M.init()  
            M = M.eval([self.z])
            self.M = SXFunction([self.z], [M[0]])
            self.M.init()
            self.ocp.mterm = self.M.eval([self.z])[0]
            self.ocp.eliminateAlgebraic()
            self.M = SXFunction([self.z], [self.ocp.mterm])
            self.M.init()
        else:
            self.M = None
            
        # Lagrange terms
        self.L = self.__init_func(self.ocp.lterm, self.ocp.lterm.numel())
          
    def __create_modell_eq(self):
        # DAE
        self.f = self.__init_func(self.ocp.ode, self.nx)
        
        # Alg
        self.alg = self.__init_func(self.ocp.alg, self.nxa)
        
    def __init_func(self, func,n):
        if n > 0:
            F = SXFunction([self.z], [func])
            F.init()
        else:
            F = None
        return F
        
    def __initial_eq(self):
        if self.ocp.initial.numel() < 1:
            self.F0 = None
        else:
            self.F0 = SXFunction([self.__old_veccat([ self.t, self.x, self.xa, self.p, self.u,self.dx])], [self.ocp.initial])
            self.F0.init()
            
    def __path_constraints(self):
        path = self.ocp.path
        if path.numel() < 1:
            self.gplb = []
            self.gpub = []
        else:
            self.gplb = self.ocp.path_min
            self.gpub = self.ocp.path_max
            
        for k in xrange(self.nw):
            if self.wmin[k] != -NP.inf or self.wmax[k] != NP.Inf:
                path.append(self.ocp.dep[k])
                self.gplb.append(self.wmin[k])
                self.gpub.append(self.wmax[k])
                
        self.pathlen = path.shape[0]
        if self.pathlen:
            self.pathc = SXFunction([self.z], [path])
            self.pathc.init()
        else:
            self.pathc = None
    
    def __str__(self):
        if not self.f is None:
            print "\n***ODE***"
            var_list = self.f.eval([self.z])[0]
            for var in var_list:
                print var
            
        if not self.alg is None:
            print "\n***alg. loops***"
            var_list = self.alg.eval([self.z])[0]
            for var in var_list:
                print var
                
        if not self.M is None:
            print "\n***mayer terms***"
            print self.M.eval([self.z])[0]
            
        if not self.L is None:
            print "\n***lagrange terms***"
            print self.L.eval([self.z])[0]
        return ""       

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/*DugebeOptimization.c
 */

#include "../OptimizerData.h"
#include "../OptimizerLocalFunction.h"
#include "../../util/omc_file.h"


/*!
 *  generated csv-file with optimizer variabl in optimizer steps
 *  author: Vitalij Ruge
 **/
void debugeSteps(OptData * optData, modelica_real*vopt, modelica_real * lambda){
  FILE * pFile = NULL;
  char buffer[250];
  const int nv = optData->dim.nv;
  const int nx = optData->dim.nx;
  const int nu = optData->dim.nu;
  const int nsi = optData->dim.nsi;
  const int np = optData->dim.np;
  const int nJ = optData->dim.nJ;
  DATA*data = optData->data;
  char *name;

  int i,j,k,jj;

  char ** inputName = optData->dim.inputName;
  const modelica_real * vnom = optData->bounds.vnom;
  double tmp;

  sprintf(buffer, "%s_%d.csv", optData->ipop.csvOstep,optData->dim.iter);
  pFile = omc_fopen(buffer, "wt");

  fprintf(pFile, "%s", "\"time\"");
  for(i = 0; i < nx; ++i){
    name = (char*)data->modelData->realVarsData[i].info.name;
    fprintf(pFile, ",\"%s\"", name);
    fprintf(pFile, ",\"%s_lambda\"", name);
  }

  for(i = 0; i < nu; ++i){
    name = inputName[i];
    fprintf(pFile, ",\"%s\"", name);
  }
  for(j=0,k=0;j<nsi;++j){
  for(jj=0;jj<np;++jj, k += nJ){
    fprintf(pFile, "\n");
    tmp = (modelica_real) optData->time.t[j][jj];
    fprintf(pFile, "%lf", tmp);
    for(i = 0; i < nx; ++i){
      tmp = vopt[i + k]*vnom[i];
      fprintf(pFile, ",%lf", tmp);
      tmp = lambda[i+k];
      fprintf(pFile, ",%lf", tmp);
    }
    for(; i < nv; ++i){
      tmp = vopt[i + k]*vnom[i];
      fprintf(pFile, ",%lf", tmp);
    }
  }
 }
 fclose(pFile);
}



/*!
 *  generated csv and python script for jacobian
 *  author: Vitalij Ruge
 **/
void debugeJac(OptData * optData, ipnumber* vopt){
  int i,j,k, jj, kk ,ii;
  const int nv = optData->dim.nv;
  const int nx = optData->dim.nx;
  const int nu = optData->dim.nu;
  const int nsi = optData->dim.nsi;
  const int nJ = optData->dim.nJ;
  const int np = optData->dim.np;
  const int nc = optData->dim.nc;
  const int npv = np*nv;
  const int nt = optData->dim.nt;
  const int NRes = optData->dim.NRes;
  const int nReal = optData->dim.nReal;
  const int NV = optData->dim.NV;
  ipnumber vopt_shift[NV];
  long double h[nv][nsi][np];
  long double hh;
  const modelica_real * const vmax = optData->bounds.vmax;
  const modelica_real * const vmin = optData->bounds.vmin;
  const modelica_real * vnom = optData->bounds.vnom;
  modelica_real vv[nsi][np][nReal];
  FILE *pFile;
  char buffer[4096];
  long double *sdt;
  modelica_real JJ[nsi][np][nv][nx];
  modelica_boolean **sJ;
  modelica_real tmpJ;

  sJ = optData->s.JderCon;
  sprintf(buffer, "jac_ana_step_%i.csv", optData->iter_);
  pFile = omc_fopen(buffer, "wt");

  fprintf(pFile,"name;time;");
  for(j = 0; j < nx; ++j)
    fprintf(pFile,"%s;",optData->data->modelData->realVarsData[j].info.name);
  for(j = 0; j < nu; ++j)
    fprintf(pFile, "%s;", optData->dim.inputName[j]);
  fprintf(pFile,"\n");

  for(i=0;i < nsi; ++i){
    for(j = 0; j < np; ++j){
      for(k = 0; k < nx; ++k){
        fprintf(pFile,"%s;%f;",optData->data->modelData->realVarsData[k].info.name,(float)optData->time.t[i][j]);
        for(jj = 0; jj < nv; ++jj){
          tmpJ = (sJ[k][jj]) ? (optData->J[i][j][k][jj]) : 0.0;
          fprintf(pFile,"%lf;", tmpJ);
        }
        fprintf(pFile,"\n");
      }
    }
  }
  fclose(pFile);

  #define DF_STEP(v) (1e-5*fabsl(v) + 1e-7)
  memcpy(vopt_shift ,vopt, NV*sizeof(ipnumber));
  optData->index = 0;
  for(k=0; k < nv; ++k){
    for(i=0, jj=k; i < nsi; ++i){
      for(j = 0; j < np; ++j, jj += nv){
        hh = DF_STEP(vopt_shift[jj]);
        while(vopt_shift[jj]  + hh >=  vmax[k]){
         hh *= -1.0;
         if(vopt_shift[jj]  + hh <= vmin[k])
           hh *= 0.9;
         else
           break;
         if(fabsl(hh) < 1e-32){
           printf("\nWarning: StepSize for FD became very small!\n");
           break;
         }
        }
        vopt_shift[jj] += hh;
        h[k][i][j] = hh;
        memcpy(vv[i][j] , optData->v[i][j], nReal*sizeof(modelica_real));
      }
     }

     optData2ModelData(optData, vopt_shift, optData->index);
     memcpy(vopt_shift,vopt , NV*sizeof(modelica_real));

    for(i = 0; i < nsi; ++i){
      sdt = optData->bounds.scaldt[i];
      for(j = 0; j < np; ++j){
        for(kk = 0, ii = nx; kk<nx;++kk, ++ii){
           hh = h[k][i][j];
           JJ[i][j][kk][k] = (optData->v[i][j][ii] - vv[i][j][ii])*sdt[kk]/hh;
        }
        memcpy(optData->v[i][j] , vv[i][j], nReal*sizeof(modelica_real));
      }
     }
   }

  optData->index = 1;
#undef DF_STEP
  sprintf(buffer, "jac_num_step_%i.csv", optData->iter_);
  pFile = omc_fopen(buffer, "wt");

  fprintf(pFile,"name;time;");
  for(j = 0; j < nx; ++j)
    fprintf(pFile,"%s;",optData->data->modelData->realVarsData[j].info.name);
  for(j = 0; j < nu; ++j)
    fprintf(pFile, "%s;", optData->dim.inputName[j]);
  fprintf(pFile,"\n");

  for(i=0;i < nsi; ++i){
    for(j = 0; j < np; ++j){
      for(k = 0; k < nx; ++k){
        fprintf(pFile,"%s;%f;",optData->data->modelData->realVarsData[k].info.name,(float)optData->time.t[i][j]);
        for(jj = 0; jj < nv; ++jj){
          tmpJ = (sJ[k][jj]) ? (JJ[i][j][k][jj]) : 0.0;
          fprintf(pFile,"%lf;",tmpJ);
        }
        fprintf(pFile,"\n");
      }
    }
  }
  fclose(pFile);

  optData2ModelData(optData, vopt, optData->index);

  if(optData->iter_ < 2){
    pFile = omc_fopen("omc_check_jac.py", "wt");
    fprintf(pFile,"\"\"\"\nautomatically generated code for analyse derivatives\n\n");
    fprintf(pFile,"  Input i:\n");
    for(j = 0; j < nx; ++j)
      fprintf(pFile,"   i = %i -> der(%s)\n",j,optData->data->modelData->realVarsData[j].info.name);
    fprintf(pFile," Input j:\n");
    for(j = 0; j < nx; ++j)
      fprintf(pFile,"   j = %i -> %s\n",j,optData->data->modelData->realVarsData[j].info.name);
    for(j = 0; j < nu; ++j)
      fprintf(pFile,"   j = %i -> %s\n",nx+j,optData->dim.inputName[j]);
    fprintf(pFile,"\n\nVitalij Ruge, vruge@fh-bielefeld.de\n\"\"\"\n\n");

    fprintf(pFile,"%s\n%s\n%s\n\n","import numpy as np","import matplotlib.pyplot as plt","from numpy import linalg as LA");
    fprintf(pFile,"class OMC_JAC:\n  def __init__(self, filename):\n    self.filename = filename\n");
    fprintf(pFile,"    self.states = [");
    if(nx > 0)
     fprintf(pFile,"'%s'",optData->data->modelData->realVarsData[0].info.name);
    for(j = 1; j < nx; ++j)
      fprintf(pFile,",'%s'",optData->data->modelData->realVarsData[j].info.name);
    fprintf(pFile,"]\n");
    fprintf(pFile,"    self.inputs = [");
    if(nu > 0)
      fprintf(pFile,"'%s'",optData->dim.inputName[0]);
    for(j = 1; j < nu; ++j)
      fprintf(pFile,",'%s'",optData->dim.inputName[j]);

	  fprintf(pFile,"]\n");
    fprintf(pFile,"    self.number_of_states = %i\n",nx);
    fprintf(pFile,"    self.number_of_inputs = %i\n",nu);
    fprintf(pFile,"    self.number_of_constraints = %i\n",nc);
    fprintf(pFile,"    self.number_of_timepoints = %i\n",nt);
    fprintf(pFile,"    self.t = np.zeros(self.number_of_timepoints)\n");
    fprintf(pFile,"    self.dx = np.zeros(self.number_of_states)\n");
    fprintf(pFile,"    self.J = np.zeros([self.number_of_states, self.number_of_states + self.number_of_inputs, self.number_of_timepoints])\n");
    fprintf(pFile,"    self.__read_csv__()\n\n");
    fprintf(pFile,"  def __read_csv__(self):\n");
    fprintf(pFile,"    with open(self.filename,'r') as f:\n");
    fprintf(pFile,"%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n",
                  "      f.readline() # name",
                  "      for l in xrange(self.number_of_timepoints):",
                  "        for k in xrange(self.number_of_states):",
                  "          l1 = f.readline()",
                  "          l1 = l1.split(\";\")",
                  "          l1 = [e for e in l1]",
                  "          if len(l1) <= 1:",
                  "            break",
                  "          self.t[l] = float(l1[1])",
                  "          for n,r in enumerate(l1[2:-1]):",
                  "            self.J[k,n,l] = float(r)",
                  "      f.close()\n",
                  "  def __str__(self):",
                  "    print \"read file %s\"%self.filename","    print \"states: \", self.states",
                  "    print \"inputs: \", self.inputs","    print \"t0 = %g, t = %g\"%(self.t[0],self.t[-1])",
                  "    return \"\"\n");
    fprintf(pFile,"  def get_value_of_jacobian(self,i, j):\n\n");
    fprintf(pFile,"   return self.J[i,j,:]\n\n");
    fprintf(pFile,"  def plot_jacobian_element(self, i, j, filename):\n");
    fprintf(pFile,"%s\n","    J = self.get_value_of_jacobian(i, j)");
    fprintf(pFile,"%s\n","    plt.figure()");
    fprintf(pFile,"%s\n","    plt.show(False)");
    fprintf(pFile,"%s\n","    plt.plot(self.t, J)");
    fprintf(pFile,"%s\n","    if j < self.number_of_states:");
    fprintf(pFile,"%s\n","      plt_name = \"der(\" + self.states[i] + \")/\" + self.states[j]");
    fprintf(pFile,"%s\n","    else:");
    fprintf(pFile,"%s\n","      plt_name = \"der(\" + self.states[i] + \")/\" + self.inputs[j-self.number_of_states]");
    fprintf(pFile,"%s\n","    plt.legend([plt_name])");
    fprintf(pFile,"%s\n","    plt.xlabel('time')");
    fprintf(pFile,"%s\n\n\n","    plt.savefig(filename = filename, format='png')");


    fprintf(pFile,"%s\n","  def plot_jacian_elements_nz(self,i,filename):");
    fprintf(pFile,"%s\n","    for j in xrange(self.number_of_states):");
    fprintf(pFile,"%s\n","      J = self.get_value_of_jacobian(i, j)");
    fprintf(pFile,"%s\n","      if LA.norm(J) > 0:");
    fprintf(pFile,"%s\n","        plt.figure()");
    fprintf(pFile,"%s\n","        plt.plot(self.t, J)");
    fprintf(pFile,"%s\n","        plt_name = \"der(\" + self.states[i] + \")/\" + self.states[j]");
    fprintf(pFile,"%s\n","        plt.legend([plt_name])");
    fprintf(pFile,"%s\n","        plt.xlabel('time')");
    fprintf(pFile,"%s\n","        plt.savefig(filename = \"der_\"+ str(i) +\"_state\"+ str(j) + filename, format='png')\n");
    fprintf(pFile,"%s\n","    for j in xrange(self.number_of_inputs):");
    fprintf(pFile,"%s\n","      J = self.get_value_of_jacobian(i, j + self.number_of_states)");
    fprintf(pFile,"%s\n","      if LA.norm(J) > 0:");
    fprintf(pFile,"%s\n","        plt.figure()");
    fprintf(pFile,"%s\n","        plt.plot(self.t, J)");
    fprintf(pFile,"%s\n","        plt_name = \"der(\" + self.states[i] + \")/\" + self.inputs[j]");
    fprintf(pFile,"%s\n","        plt.legend([plt_name])");
    fprintf(pFile,"%s\n","        plt.xlabel('time')");
    fprintf(pFile,"%s\n\n\n","        plt.savefig(filename = \"der_\"+ str(i) +\"_input\"+ str(j) + filename, format='png')");

    fprintf(pFile,"%s\n","  def compare_plt_jac(self, i, J2, filename):");
    fprintf(pFile,"%s\n","    for j in xrange(self.number_of_states):");
    fprintf(pFile,"%s\n","      J = self.get_value_of_jacobian(i, j)");
    fprintf(pFile,"%s\n","      J_ = J2.get_value_of_jacobian(i, j)");
    fprintf(pFile,"%s\n","      if LA.norm(J-J_)> 0:");
    fprintf(pFile,"%s\n","        plt.figure()");
    fprintf(pFile,"%s\n","        plt.hold(False)");
    fprintf(pFile,"%s\n","        plt.plot(self.t, J,'r', self.t,J_,'k--', linewidth=2.0)");
    fprintf(pFile,"%s\n","        plt_name = \"der(\" + self.states[i] + \")/\" + self.states[j]");
    fprintf(pFile,"%s\n","        plt.legend([plt_name, plt_name + '_'])");
    fprintf(pFile,"%s\n","        plt.xlabel('time')");
    fprintf(pFile,"%s\n","        plt.savefig(filename = \"der_\"+ str(i) +\"_state\"+ str(j) + filename, format='png')\n");
    fprintf(pFile,"%s\n","    for j in xrange(self.number_of_inputs):");
    fprintf(pFile,"%s\n","      J = self.get_value_of_jacobian(i, j+self.number_of_states)");
    fprintf(pFile,"%s\n","      J_ = J2.get_value_of_jacobian(i, j+self.number_of_states)");
    fprintf(pFile,"%s\n","      if LA.norm(J-J_) > 0:");
    fprintf(pFile,"%s\n","        plt.figure()");
    fprintf(pFile,"%s\n","        plt.hold(False)");
    fprintf(pFile,"%s\n","        plt.plot(self.t, J,'r',self.t,J_,'k--',linewidth=2.0)");
    fprintf(pFile,"%s\n","        plt_name = \"der(\" + self.states[i] + \")/\" + self.inputs[j]");
    fprintf(pFile,"%s\n","        plt.legend([plt_name, plt_name + '_'])");
    fprintf(pFile,"%s\n","        plt.xlabel('time')");
    fprintf(pFile,"%s\n\n\n","        plt.savefig(filename = \"der_\"+ str(i) +\"_input\"+ str(j) + filename, format='png')");

    fprintf(pFile,"%s\n","J_ana = OMC_JAC('jac_ana_step_1.csv')");
    fprintf(pFile,"%s\n","#J_ana.plot_jacian_elements_nz(0,'pltJac_ana.png')");
    fprintf(pFile,"%s\n","J_num = OMC_JAC('jac_num_step_1.csv')");
    fprintf(pFile,"%s\n","#J_num.plot_jacian_elements_nz(0,'pltJac_num.png')");
    fprintf(pFile,"%s\n","for i  in xrange(J_ana.number_of_states):");
    fprintf(pFile,"%s\n","  J_ana.compare_plt_jac(i,J_num,'pltJac_compare.png')");


    fclose(pFile);
  }
}



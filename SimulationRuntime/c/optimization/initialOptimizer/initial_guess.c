/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * Developed by:
 * FH-Bielefeld
 * Developer: Vitalij Ruge
 * Contact: vitalij.ruge@fh-bielefeld.de
 */


#include "../localFunction.h"
#include "../ipoptODEstruct.h"
#include "../simulation/solver/radau.h"

#ifdef WITH_IPOPT

/*!
 *  create initial guess
 *  author: Vitalij Ruge
 **/
int initial_guess_ipopt(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo)
{
  double *u0, *u, *x, uu,tmp ,lhs, rhs;
  int i,j,k,ii,jj,id;
  int err;
  double *v;
  DATA* data = iData->data;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_INFO *sInfo = &(data->simulationInfo);
  KINODE *kinOde;

  u0 = iData->data->localData[1]->realVars + iData->index_u;
  u = iData->data->localData[0]->realVars + iData->index_u;
  x = iData->data->localData[0]->realVars;
  v = iData->v;

  for(ii=iData->nx,j=0; j < iData->nu; ++j, ++ii)
  {
    u0[j] = data->modelData.realVarsData[iData->index_u+j].attribute.start;
    u0[j] = fmin(fmax(u0[j],iData->umin[j]),iData->umax[j]);
    u[j] = u0[j];
    v[ii] = u0[j]*iData->scalVar[j + iData->nx];
  }

  solverInfo->solverData = calloc(1, sizeof(KINODE));
  kinOde = (KINODE*) solverInfo->solverData;
  refreshSimData(x, u, iData->tf, iData);
  allocateKinOde(data, solverInfo, 8, 1);

  if(ACTIVE_STREAM(LOG_IPOPT))
  {
    printf("\n****initial guess****");
      printf("\n #####done time[%i] = %f",0,iData->time[0]);
  }

  for(i=0, k=1, v=iData->v + iData->nv; i<iData->nsi; ++i)
  {
    for(jj=0; jj<iData->deg; ++jj, ++k)
    {
      solverInfo->currentStepSize = iData->time[k] - iData->time[k-1];
      iData->data->localData[1]->timeValue = iData->time[k];
      
      do
      {
        err = kinsolOde(solverInfo->solverData);

        if(err < 0)
        {
          solverInfo->currentStepSize *= 0.99;
          kinOde->kData->fnormtol *=10.0;
          kinOde->kData->scsteptol *=10.0;
          
          if(ACTIVE_STREAM(LOG_SOLVER))
          {
            printf("\n #####try time[%i] = %f",k,iData->time[k]);
          }
        }
        else
        {
          if(ACTIVE_STREAM(LOG_IPOPT))
            printf("\n #####done time[%i] = %f",k,iData->time[k]);
        }
      }while(err <0);
      
      kinOde->kData->fnormtol =iData->data->simulationInfo.tolerance;
      kinOde->kData->scsteptol =iData->data->simulationInfo.tolerance;

      for(j=0; j< iData->nx; ++j)
      {
        v[j] = sData->realVars[j] * iData->scalVar[j];
      }

      for(ii=iData->index_u; j< iData->nv; ++j, ++ii)
      {
        v[j] = sData->realVars[ii] * iData->scalVar[j];
      }

      v += iData->nv;
      /* updateContinuousSystem(iData->data); */
      rotateRingBuffer(iData->data->simulationData, 1, (void**) iData->data->localData);
    }
  }

  for(i = 0, id=0; i<iData->NV;i++,++id)
  {
    if(id >=iData->nv)
      id = 0;
      
    if(id <iData->nx)
    {
      iData->v[i] =fmin(fmax(iData->vmin[id],iData->v[i]),iData->vmax[id]);
    }
    else if(id< iData->nv)
    {
      iData->v[i] = fmin(fmax(iData->vmin[id],iData->v[i]),iData->vmax[id]);
    }
  }

  if(ACTIVE_STREAM(LOG_IPOPT))
    printf("\n*****initial guess done*****");
  freeKinOde(data, solverInfo, 8, 1);
  solverInfo->solverData = (void*)iData;

  return 0;
}

#endif

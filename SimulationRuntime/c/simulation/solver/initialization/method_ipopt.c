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

/*! \file ipopt_initialization.c
 */

#include "../../../../../Compiler/runtime/config.h"
#include "method_ipopt.h"
#include "simulation_data.h"
#include "util/omc_error.h"

#ifdef WITH_IPOPT
  #include "openmodelica.h"
  #include "openmodelica_func.h"
  #include "model_help.h"
  #include "read_matlab4.h"
  #include "events.h"

  #include <string.h>
  #include <stdio.h>
  #include <stdlib.h>
  #include <math.h>

  #include <coin/IpStdCInterface.h>

  typedef struct IPOPT_DATA
  {
    DATA *data;
    INIT_DATA *initData;
    int useScaling;
    int useSymbolic;
  } IPOPT_DATA;

  /*! \fn ipopt_f
   *
   *  \param [in]  [n]
   *  \param [in]  [x]
   *  \param [in]  [new_x]
   *  \param [out] [obj_value]
   *  \param [ref] [user_data]
   *
   *  \author lochel
   */
  static Bool ipopt_f(int n, double *x, Bool new_x, double *obj_value, void *user_data)
  {
    IPOPT_DATA *ipopt_data = (IPOPT_DATA*)user_data;

    setZ(ipopt_data->initData, x);
    *obj_value = leastSquareWithLambda(ipopt_data->initData, 1.0);

    return TRUE;
  }

  /*! \fn ipopt_grad_f
   *
   *  \param [in]  [n]
   *  \param [in]  [x]
   *  \param [in]  [new_x]
   *  \param [out] [grad_f]
   *  \param [ref] [user_data]
   *
   *  \author lochel
   */
  static Bool ipopt_grad_f(int n, double *x, Bool new_x, double *grad_f, void *user_data)
  {
    int i;
    double xp, xn;
    double h = 1e-6;
    double hh;

    for(i=0; i<n; ++i)
    {
      hh = (abs(x[i]) > 1e-3) ? h*abs(x[i]) : h;
      x[i] += hh;
      ipopt_f(n, x, new_x, &xp, user_data);
      x[i] -= 2.0*hh;
      ipopt_f(n, x, new_x, &xn, user_data);
      x[i] += hh;

      grad_f[i] = (xp-xn)/(2.0*hh);
    }

    return TRUE;
  }

  /*! \fn ipopt_g
   *
   *  \param [in]  [n]
   *  \param [in]  [x]
   *  \param [in]  [new_x]
   *  \param [out] [g]
   *  \param [ref] [user_data]
   *
   *  \author lochel
   */
  static Bool ipopt_g(int n, double *x, Bool new_x, int m, double *g, void *user_data)
  {
    int i;
    IPOPT_DATA *ipopt_data = (IPOPT_DATA*)user_data;

    double obj_value;
    ipopt_f(n, x, new_x, &obj_value, user_data);

    for(i=0; i<m; ++i)
      g[i] = ipopt_data->initData->initialResiduals[i];

    return TRUE;
  }

  /*! \fn ipopt_jac_g
   *
   *  \param [in]  [n]
   *  \param [in]  [x]
   *  \param [in]  [new_x]
   *  \param [in]  [m]
   *  \param [in]  [nele_jac]
   *  \param [out] [iRow]
   *  \param [out] [jCol]
   *  \param [out] [values]
   *  \param [ref] [user_data]
   *
   *  \author lochel
   */
  static Bool ipopt_jac_g(int n, double *x, Bool new_x, int m, int nele_jac,
                          int *iRow, int *jCol, double *values, void *user_data)
  {
    IPOPT_DATA *ipopt_data = (IPOPT_DATA*)user_data;
    DATA *data = ipopt_data->data;
    if(values == NULL)
    {
      int i, j;
      int idx = 0;

      /*
       * DENSE
       *
       */
      infoStreamPrint(LOG_INIT, 0, "ipopt using numeric dense jacobian G");
      idx = 0;
      for(i=0; i<n; ++i)
      {
        for(j=0; j<m; ++j)
        {
          jCol[idx] = i;
          iRow[idx] = j;
          idx++;
        }
      }

      assert(idx == nele_jac);
    }
    else
    {
      /* return the values of the jacobian of the constraints */
      infoStreamPrint(LOG_DEBUG, 0, "ipopt jacobian G");

      int i, j;
      int idx = 0;
      double h = 1e-6;
      double hh;

      double *gp = (double*)malloc(m * sizeof(double));
      double *gn = (double*)malloc(m * sizeof(double));

      for(i=0; i<n; ++i)
      {
        hh = (abs(x[i]) > 1e-3) ? h*abs(x[i]) : h;
        x[i] += hh;
        ipopt_g(n, x, new_x, m, gp, user_data);
        x[i] -= 2.0*hh;
        ipopt_g(n, x, new_x, m, gn, user_data);
        x[i] += hh;

        for(j=0; j<m; ++j)
        {
          values[idx] = (gp[j]-gn[j])/(2.0*hh);
          idx++;
        }
      }

      free(gp);
      free(gn);

      if(ACTIVE_STREAM(LOG_DEBUG))
      {
        int i, j;
        for(i=0; i<n; ++i)
        {
          printf("        | | column %3d: [ ", i+1);
          for(j=0; j<m; ++j)
            printf("%10.5g ", values[j*n+i]);
          printf("]\n");
        }
      }
    }
    return TRUE;
  }

  /*! \fn ipopt_h
   *
   *  \param [in]  [n]
   *  \param [in]  [x]
   *  \param [in]  [new_x]
   *  \param [in]  [obj_factor]
   *  \param [in]  [m]
   *  \param [in]  [lambda]
   *  \param [in]  [new_lambda]
   *  \param [in]  [nele_hess]
   *  \param [out] [iRow]
   *  \param [out] [jCol]
   *  \param [out] [values]
   *  \param [ref] [user_data]
   *
   *  \author lochel
   */
  static Bool ipopt_h(int n, double *x, Bool new_x, double obj_factor, int m, double *lambda, Bool new_lambda,
                      int nele_hess, int *iRow, int *jCol, double *values, void *user_data)
  {
    assert(0);
    return TRUE;
  }

  /*! \fn int ipopt_initialization(INIT_DATA *initData, int useScaling)
   *
   *  This function is used if ipopt is choosen for initialization.
   *
   *  \param [ref] [initData]
   *  \param [in]  [useScaling]
   *
   *  \author lochel
   */
  int ipopt_initialization(DATA *data,INIT_DATA *initData, int useScaling)
  {
    int n = initData->nVars;             /* number of variables */
    int m = (initData->nInitResiduals > initData->nVars) ? 0 : initData->nInitResiduals;    /* number of constraints */
    double* x_L = NULL;                  /* lower bounds on x */
    double* x_U = NULL;                  /* upper bounds on x */
    double* g_L = NULL;                  /* lower bounds on g */
    double* g_U = NULL;                  /* upper bounds on g */

    double* x = NULL;                    /* starting point and solution vector */
    double* mult_g = NULL;               /* constraint multipliers at the solution */
    double* mult_x_L = NULL;             /* lower bound multipliers at the solution */
    double* mult_x_U = NULL;             /* upper bound multipliers at the solution */
    double obj;                          /* objective value */
    int i;                               /* generic counter */

    int nele_jac = n*m;                  /* number of nonzeros in the Jacobian of the constraints */
    int nele_hess = 0;                   /* number of nonzeros in the Hessian of the Lagrangian (lower or upper triangual part only) */

    IpoptProblem nlp = NULL;             /* ipopt-problem */
    enum ApplicationReturnStatus status; /* solve return code */

    IPOPT_DATA ipopt_data;

    ipopt_data.data = data;
    ipopt_data.initData = initData;
    ipopt_data.useScaling = useScaling;
    ipopt_data.useSymbolic = 0;          /* lochel: obsolete */

    /* allocate space for the variable bounds */
    x_L = (double*)malloc(n * sizeof(double));
    x_U = (double*)malloc(n * sizeof(double));

    /* allocate space for the constraint bounds */
    if (m>0)
    {
        g_L = (double*)malloc(m * sizeof(double));
        g_U = (double*)malloc(m * sizeof(double));
    }

    /* allocate space for the initial point */
    x = (double*)malloc(n * sizeof(double));

    /* set values of optimization variable bounds */
    for(i=0; i<n; ++i)
    {
      x[i] = initData->start[i];
      x_L[i] = initData->min[i];
      x_U[i] = initData->max[i];
    }

    /* set values of constraint bounds */
    for(i=0; i<m; ++i)
    {
      g_L[i] = 0.0;
      g_U[i] = 0.0;
    }

    /* create the IpoptProblem */
    nlp = CreateIpoptProblem(
        n,              /* Number of optimization variables */
        x_L,            /* Lower bounds on variables */
        x_U,            /* Upper bounds on variables */
        m,              /* Number of constraints */
        g_L,            /* Lower bounds on constraints */
        g_U,            /* Upper bounds on constraints */
        nele_jac,       /* Number of non-zero elements in constraint Jacobian */
        nele_hess,      /* Number of non-zero elements in Hessian of Lagrangian */
        0,              /* indexing style for iRow & jCol; 0 for C style, 1 for Fortran style */
        &ipopt_f,       /* Callback function for evaluating objective function */
        &ipopt_g,       /* Callback function for evaluating constraint functions */
        &ipopt_grad_f,  /* Callback function for evaluating gradient of objective function */
        &ipopt_jac_g,   /* Callback function for evaluating Jacobian of constraint functions */
        &ipopt_h);      /* Callback function for evaluating Hessian of Lagrangian function */

    assertStreamPrint(data->threadData, 0 != nlp, "creating of ipopt problem has failed");

    /* We can free the memory now - the values for the bounds have been
       copied internally in CreateIpoptProblem */
    free(x_L);
    free(x_U);
    if (m>0)
    {
        free(g_L);
        free(g_U);
    }

    /* Set some options. Note the following ones are only examples,
       they might not be suitable for your problem. */
    AddIpoptNumOption(nlp, "tol", 1e-7);

    AddIpoptIntOption(nlp, "print_level", ACTIVE_STREAM(LOG_INIT) ? 5 : 0);
    AddIpoptIntOption(nlp, "max_iter", 5000);

    AddIpoptStrOption(nlp, "mu_strategy", "adaptive");
    AddIpoptStrOption(nlp, "hessian_approximation", "limited-memory");

    /* allocate space to store the bound multipliers at the solution */
    mult_g = (double*)malloc(m*sizeof(double));
    mult_x_L = (double*)malloc(n*sizeof(double));
    mult_x_U = (double*)malloc(n*sizeof(double));

    /* solve the problem */
    status = IpoptSolve(
        nlp,            /* Problem that is to be optimized */
        x,              /* Input: Starting point; Output: Optimal solution */
        NULL,           /* Values of constraint at final point */
        &obj,           /* Final value of objective function */
        mult_g,         /* Final multipliers for constraints */
        mult_x_L,       /* Final multipliers for lower variable bounds */
        mult_x_U,       /* Final multipliers for upper variable bounds */
        &ipopt_data);   /* Pointer to user data */

    setZ(initData, x);

    /* free allocated memory */
    FreeIpoptProblem(nlp);
    free(x);
    free(mult_g);
    free(mult_x_L);
    free(mult_x_U);

    /* debug output */
    dumpInitialization(data,initData);

    if(status != Solve_Succeeded && status != Solved_To_Acceptable_Level)
      throwStreamPrint(data->threadData, "ipopt failed. see last warning. use [-lv LOG_INIT] for more output.");

    /* return (int)status; */
    return reportResidualValue(initData);
  }
#else
  /*! \fn int ipopt_initialization(INIT_DATA *initData, int useScaling)
   *
   *  This function is used if no ipopt support is avaible but ipopt is choosen
   *  for initialization.
   *
   *  \param [ref] [initData]
   *  \param [in]  [useScaling]
   *
   *  \author lochel
   */
  int ipopt_initialization(DATA *data,INIT_DATA *initData, int useScaling)
  {
    throwStreamPrint(data->threadData,"no ipopt support activated");
    return 0;
  }
#endif

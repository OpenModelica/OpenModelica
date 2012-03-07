/*                                               -*- C -*- */
/**
 *  @file  wrapper.c
 *  @brief The wrapper adapts the interface of OpenTURNS and of the wrapped code
 *
 *  (C) Copyright 2005-2007 EDF-EADS-Phimeca
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License.
 *
 *  This library is distributed in the hope that it will be useful
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 *
 *  @author: $LastChangedBy: dutka $
 *  @date:   $LastChangedDate: 2008-08-28 17:36:47 +0200 (Thu, 28 Aug 2008) $
 *  Id:      $Id: wrapper.c 916 2008-08-28 15:36:47Z dutka $
 */

#include "WrapperCommon.h"
#include "WrapperMacros.h"

/* WARNING : Please read the following lines
 *
 * In this program, we make the assumption that the end user wishes to
 * call a function (aka NumericalMathFunction) named "OpenModelica" (OpenModelica stands
 * for wrapped code).
 * In order to individualize the wrapper to the user's needs, we encourage
 * you (as the developer of this wrapper) to renamed any occurence of "OpenModelica"
 * (in either case) to the real name of the function.
 * It will also avoid any confusion with other "OpenModelica"s written by other entities
 * or developers.
 */


/* If you plan to link this wrapper against a FORTRAN library,
 * remember to change the name WCODE for your actual FORTRAN subroutine name.
 * Otherwise you can ignore these lines.
 *
 * Remember that FORTRAN passes its arguments by reference, not by value as C and C++
 * usually do. So you need to pass the pointer to the arguments rather than its value.
 * This is true for single values (integers, reals, etc.) but not for arrays that are
 * already pointers in the C/C++ environment. Those ones can directly be passed as
 * "values" though they are pointers indeed.
 * Be careful that C and C++ arrays start from 0 and FORTRAN from 1!
 * Be also very careful with the size of the value your plan to pass. Integers in C/C++
 * are not INTEGER*8 in many cases. Float or doubles do not necessarily match REAL*4
 * or REAL*8 in FORTRAN.
 *
 * FORTRAN gives no clue for preventing const values from being altered. So you need to
 * protect them by copying them before calling the FORTRAN subroutine if this import
 * to you.
 *
 * Summary: there are only exceptions to the rule and you need to
 * know exactly what you are doing! You may be desappointed at first, but it will keep
 * you away from segmentation violation and other similar fantasies. ;-)
 */

/* If you want to customize this wrapper to your needs, you have to do the following :
 *  - change the current wrapper name 'OpenModelica' to any name you chooze. Be careful to respect
 *    the case everywhere you make the change.
 *  - adapt the signatures of the calls. This means that you may want to call :
 *     a) a C function : you have to write it yourself in this file or in another one and
 *        link the wrapper with the corresponding object file.
 *     b) a FORTRAN function : you have to write the function in another file and link
 *        the wrapper with the corresponding object file. But, due to some technical
 *        aspect of C/FORTRAN linking, you have to declare your FORTRAN function to C in
 *        a special manner and use the F77_FUNC macro below. Don't worry, it's easy !
 *        First, change the name 'OpenModelica' everywhere in the macro to the name of your FORTRAN
 *        subroutine. Second, declare the arguments passed to the subroutine in a prototype
 *        declaration. Remember that all FORTRAN argumets are passed as reference (aka pointers)
 *        conversely to C. Long and double in C match INTEGER*4 and REAL*8 in FORTRAN
 *        respectively. Avoid using strings.
 *     c) anything else : you are left alone but the preceding rules may help you.
 *  - call your C function or the FORTRAN macro in the execute function of your wrapper.
 */

/* The name of the wrapper's functions is defined in WRAPPERNAME macro */
/* adrpo: the wrapper name is given by a generated .h file */
#include "wrapper_name.h"
#include "model_name.h"

/*
 *  This is the declaration of function named 'OpenModelica' into the wrapper.
 */
#ifdef __cplusplus
extern "C" {
#endif

/*
*********************************************************************************
*                                                                               *
*                             OpenModelica function                             *
*                                                                               *
*********************************************************************************
*/

  /* The wrapper information informs the NumericalMathFunction object that loads the wrapper of the
   * signatures of the wrapper functions. In particular, it hold the size of the input
   * NumericalPoint (inSize_) and of the output NumericalPoint (outSize_).
   * Those information are also used by the gradient and hessian functions to set the correct size
   * of the returned matrix and tensor.
   */
  
  /* The getInfo function is optional */
  FUNC_INFO( WRAPPERNAME ,
  {
    GET_EXCHANGED_DATA_FROM( p_state );
    SET_INFORMATION_FROM_EXCHANGED_DATA( p_exchangedData );
  } )
    
  /* The state creation/deletion functions allow the wrapper to create or delete a memory location
   * that it will manage itself. It can save in this location any information it needs. The OpenTURNS
   * platform only ensures that the wrapper will receive the state (= the memory location) it works
   * with. If many wrappers are working simultaneously or if the same wrapper is called concurrently,
   * this mechanism will avoid any collision or confusion.
   * The consequence is that NO STATIC DATA should be used in the wrapper OR THE WRAPPER WILL BREAKE
   * one day. You may think that you can't do without static data, but in general this is the footprint
   * of a poor design. But if you persist to use static data, do your work correctly and make use
   * of mutex (for instance) to protect your data against concurrent access. But don't complain about
   * poor computational performance! 
   */
    
    
  /* The createState function is optional */
  FUNC_CREATESTATE( WRAPPERNAME ,
  {
    CHECK_WRAPPER_MODE( WRAPPER_STATICLINK );
    CHECK_WRAPPER_IN(   WRAPPER_ARGUMENTS  );
    CHECK_WRAPPER_OUT(  WRAPPER_ARGUMENTS  );     
    COPY_EXCHANGED_DATA_TO( p_p_state );
    PRINT( "Created state for OpenModelica simulation code invocation" );
  })
    
  /* The deleteState function is optional */
  FUNC_DELETESTATE( WRAPPERNAME ,
  {
    DELETE_EXCHANGED_DATA_FROM( p_state );
  })
  
  
  /* Any function declared into the wrapper may declare three actual function prefixed with
   * 'init_', 'exec_' and 'finalize_' folowed by the name of the function, here 'OpenModelica'.
   *
   * The 'init_' function is only called once when the NumericalMathFunction object is created.
   * It allows the wrapper to set some internal state, read some external file, prepare the function
   * to run, etc. It takes only one argument, the internal state as created by the 
   *
   * The 'exec_' function is intended to execute what the wrapper is done for: compute an mathematical
   * function or anything else. It takes the internal state pointer as its first argument, the input
   * NumericalPoint pointer as the second and the output NumericalPoint pointer as the third.
   *
   * The 'finalize_' function is only called once when the NumericalMathFunction object is destroyed.
   * It allows the wrapper to flush anything before unloading.
   *
   * Only the 'exec_' function is mandatory.
   */
    
    
  /**
   * Initialization function
   * This function is called once just before the wrapper first called to initialize
   * it, ie create a temparary subdirectory (remember that the wrapper may be called
   * concurrently), store exchanged data in some internal repository, do some
   * pre-computational operation, etc.
   */
  FUNC_INIT( WRAPPERNAME , {} )

  /**
   * Execution function
   * This function is called by the platform to do the real work of the wrapper. It may be
   * called concurrently, so be aware of not using shared or global data not protected by
   * a critical section.
   * This function has a mathematical meaning. It operates on one vector (aka point) and
   * returns another vector.
   */
  FUNC_EXEC( WRAPPERNAME,
  {
    /* myCFuntion returns a non-null value when it fails */
    int idx = 0;
    int exitCode = 0;
    char *openModelicaHome = getEnv("OPENMODELICA");
    char systemCommand[5000] = NULL;
    char *variableName = NULL;
    unsigned long variableType = 0;
    /* read the model name from the included model_name.h file */
    char *modelName = MODELNAME;
    char *modelInitFileName = NULL;
    char *newModelInitFileName = "OpenTurns_init.xml";
    char *errorMsg = 0;
    double variableValue = 0, stopTime = 0;
    struct WrapperExchangedData *pData = p_exchangedData;
    struct WrapperVariableList   *varLst = pData->variableList_;
    ModelicaMatReader* matReader = NULL;


    modelInitFileName = (char*)malloc(strlen(modelName)+strlen("_init.xml")+1);
    sprintf(modelInitFileName, "%s_init.xml", modelName);

    if (!openModelicaHome)
    {
      PRINT( "Error: OPENMODELICAHOME is not set!" );
      return WRAPPER_EXECUTION_ERROR;
    }

    /* for each of the input variables change the start in the OpenModelica_init.xml file */
    PRINT( "Creating OpenTurns_init.xml file with start values from OpenTurns and the rest from OpenModelica_init.xml file" );
    while (varLst)
    {
      variableName = varLst->variable_->id_;
      variableType = varLst->variable_->type_;
      /* filter the output variables */
      if (variableType == 0)
      {
        variableValue = inPoint->data_[idx];
        
        /* update the variable in OpenModelica_init.xml */
        sprintf(systemCommand, "%s/share/omc/scripts/replace-startValue %s %s %s > %s", openModelicaHome, variableName, variableValue, modelInitFileName, newModelInitFileName);
        modelInitFileName = newModelInitFileName;
        exitCode = system(systemCommand);
        if (!exitCode)
        {
          PRINT( "Error writing input values in OpenTurns_init.xml file, comman %s returned %d", systemCommand, exitCode );
          return WRAPPER_EXECUTION_ERROR;
        }
        idx++;
      }
      /* move to next */
      varLst = varLst->next_;
    }

    PRINT( "Running the simulation executable with OpenTurns_init.xml file as input" );
    sprintf(systemCommand, "OpenModelica -f %s", newModelInitFileName);
    exitCode = system(systemCommand);
    if (!exitCode)
    {
      PRINT( "Error writing input values in OpenTurns_init.xml file, comman %s returned %d", systemCommand, exitCode );
      return WRAPPER_EXECUTION_ERROR;
    }

    PRINT( "Reading the output values from OpenModelica_res.mat file" );
    
    errorMsg = omc_new_matlab4_reader("OpenModelica_res.mat", matReader);
    if (errorMsg)
    {
      PRINT( "Error in calling the OpenModelica simulation code" );
      return WRAPPER_EXECUTION_ERROR;
    }

    stopTime = omc_matlab4_stopTime(matReader);
    
    /* populate the outPoint! */
    while (varLst)
    {
      varLst = pData->variableList_;
      variableName = varLst->variable_->id_;
      variableType = varLst->variable_->type_;
      /* filter the output variables */
      if (variableType == 1)
      {
        /* read the variable at stop time */
        ModelicaMatVariable_t *matVar = omc_matlab4_find_var(matReader, variableName);
        omc_matlab4_val(&variableValue, matReader, matVar, stopTime);
        outPoint->data_[idx] = variableValue;
        idx++;
      }
      /* move to next */
      varLst = varLst->next_;
    }
    
    omc_free_matlab4_reader(matReader);

    if (rc) {
      PRINT( "Error in calling the OpenModelica simulation code" );
      return WRAPPER_EXECUTION_ERROR;
    }

   })

  /**
   * Finalization function
   * This function is called once just before the wrapper is unloaded. It is the place to flush
   * any output file or free any allocated memory. When this function returns, the wrapper is supposed
   * to have all its work done, so it is not possible to get anymore information from it after that.
   */
  FUNC_FINALIZE( WRAPPERNAME , {} )


#ifdef __cplusplus
    } /* end extern "C" */
#endif

/*                                               -*- C -*- */
/**
 *  @file  wrapper.c
 *  @brief The wrapper adapts the interface of OpenTURNS and of the wrapped code
 *
 */

#include "Wrapper.h"

#include "wrapper_name.h"
#include "model_name.h"
#include "read_matlab4.h"
#include <stdio.h>
#include <stdlib.h>

int callOpenModelicaModel(STATE p_state, INPOINT inPoint, OUTPOINT outPoint, EXCHANGEDDATA p_exchangedData, ERROR p_error)
{
    int idx = 0;
    int rc;
    int exitCode = 0;
    char *openModelicaHome = getenv("OPENMODELICAHOME");
    char systemCommand[5000] = {0};
    char *variableName = NULL;
    unsigned long variableType = 0;
    /* read the model name from the included model_name.h file */
    char *modelName = MODELNAMESTR;
    char *modelInitFileName = NULL;
    char *newModelInitFileName = "OpenTurns_init.xml";
    char *errorMsg = 0;
    double variableValue = 0, stopTime = 0;
    struct WrapperExchangedData const *pData = p_exchangedData;
    struct WrapperVariableList   *varLst = pData->variableList_;
    ModelicaMatReader* matReader = NULL;
    modelInitFileName = (char*)malloc(strlen(modelName)+strlen("_init.xml")+1);
    sprintf(modelInitFileName, "%s_init.xml", modelName);
    if (!openModelicaHome)
    {
      SETERROR( "Error: OPENMODELICAHOME is not set!" );
      return WRAPPER_EXECUTION_ERROR;
    }
    /* for each of the input variables change the start in the OpenModelica_init.xml file */
    SETERROR( "Creating OpenTurns_init.xml file with start values from OpenTurns and the rest from OpenModelica_init.xml file" );
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
          SETERROR( "Error writing input values in OpenTurns_init.xml file, comman %s returned %d", systemCommand, exitCode );
          return WRAPPER_EXECUTION_ERROR;
        }
        idx++;
      }
      /* move to next */
      varLst = varLst->next_;
    }
    SETERROR( "Running the simulation executable with OpenTurns_init.xml file as input" );
    sprintf(systemCommand, "OpenModelica -f %s", newModelInitFileName);
    exitCode = system(systemCommand);
    if (!exitCode)
    {
      SETERROR( "Error writing input values in OpenTurns_init.xml file, comman %s returned %d", systemCommand, exitCode );
      return WRAPPER_EXECUTION_ERROR;
    }
    SETERROR( "Reading the output values from OpenModelica_res.mat file" );
    errorMsg = (char*)omc_new_matlab4_reader("OpenModelica_res.mat", matReader);
    if (errorMsg)
    {
      SETERROR( "Error in calling the OpenModelica simulation code" );
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
    return rc;
}

BEGIN_C_DECLS
WRAPPER_BEGIN

/*
 *  This is the declaration of function named 'myWrapper' into the wrapper.
 */
  


/*
*********************************************************************************
*                                                                               *
*                             myWrapper function                                *
*                                                                               *
*********************************************************************************
*/

  /* The wrapper information informs the NumericalMathFunction object that loads the wrapper of the
   * signatures of the wrapper functions. In particular, it hold the size of the input
   * NumericalPoint (inSize_) and of the output NumericalPoint (outSize_).
   * Those information are also used by the gradient and hessian functions to set the correct size
   * of the returned matrix and tensor.
   */
  
  /* The getInfo function is optional. Except if you alter the description of the wrapper, you'd better
   * use the standard one automatically provided by the platform. Uncomment the following definition if
   * you want to provide yours instead. */
  /* FUNC_INFO( WRAPPERNAME , {} ) */
    
  /* The state creation/deletion functions allow the wrapper to create or delete a memory location
   * that it will manage itself. It can save in this location any information it needs. The OpenTURNS
   * platform only ensures that the wrapper will receive the state (= the memory location) it works
   * with. If many wrappers are working simultaneously or if the same wrapper is called concurrently,
   * this mechanism will avoid any collision or confusion.
   * The consequence is that NO STATIC DATA should be used in the wrapper OR THE WRAPPER WILL BREAKE
   * one day. You may think that you can't do without static data, but in general this is the case
   * of a poor design. But if you persist to use static data, do your work correctly and make use
   * of mutex (for instance) to protect your data against concurrent access. But don't complain about
   * difficulties or poor computational performance! 
   */
    
    
  /* The createState function is optional. If you need to manage an internal state, uncomment the following
   * definitions and adapt the source code to your needs. By default Open TURNS provides default ones. */
  /* FUNC_CREATESTATE( WRAPPERNAME , {
     CHECK_WRAPPER_MODE( WRAPPER_STATICLINK );
     CHECK_WRAPPER_IN(   WRAPPER_ARGUMENTS  );
     CHECK_WRAPPER_OUT(  WRAPPER_ARGUMENTS  );
     
     COPY_EXCHANGED_DATA_TO( p_p_state );
     
     PRINT( "My message is here" );
     } ) */
  
  /* The deleteState function is optional. See FUNC_CREATESTATE for explanation. */
  /* FUNC_DELETESTATE( WRAPPERNAME , {
     DELETE_EXCHANGED_DATA_FROM( p_state );
     } ) */

  /* Any function declared into the wrapper may declare three actual functions prefixed with
   * 'init_', 'exec_' and 'finalize_' followed by the name of the function, here 'myWrapper'.
   *
   * The 'init_' function is only called once when the NumericalMathFunction object is created.
   * It allows the wrapper to set some internal state, read some external file, prepare the function
   * to run, etc.
   *
   * The 'exec_' function is intended to execute what the wrapper is done for: compute an mathematical
   * function or anything else. It takes the internal state pointer as its first argument, the input
   * NumericalPoint pointer as the second and the output NumericalPoint pointer as the third.
   *
   * The 'finalize_' function is only called once when the NumericalMathFunction object is destroyed.
   * It allows the wrapper to flush anything before unloading.
   *
   * Only the 'exec_' function is mandatory because the other ones are automatically provided by the platform.
   */
    
    
  /**
   * Initialization function
   * This function is called once just before the wrapper first called to initialize
   * it, ie create a temparary subdirectory (remember that the wrapper may be called
   * concurrently), store exchanged data in some internal repository, do some
   * pre-computational operation, etc. Uncomment the following definition if you want to
   * do some pre-computation work.
   */
  /* FUNC_INIT( WRAPPERNAME , {} ) */
      

  /**
   * Execution function
   * This function is called by the platform to do the real work of the wrapper. It may be
   * called concurrently, so be aware of not using shared or global data not protected by
   * a critical section.
   * This function has a mathematical meaning. It operates on one vector (aka point) and
   * returns another vector.
   *
   * This definition is MANDATORY.
   */
  FUNC_EXEC( WRAPPERNAME , 
    {
      int rc = callOpenModelicaModel(p_state, inPoint, outPoint, p_exchangedData, p_error);
      if (rc) 
      {
        PRINT( "Error in calling the OpenModelica simulation code" );
        return WRAPPER_EXECUTION_ERROR;
      }
    })
  
  /**
   * Finalization function
   * This function is called once just before the wrapper is unloaded. It is the place to flush
   * any output file or free any allocated memory. When this function returns, the wrapper is supposed
   * to have all its work done, so it is not possible to get anymore information from it after that.
   * Uncomment the following definition if you need to do some post-computation work. See FUNC_INIT. */
  /* FUNC_FINALIZE( WRAPPERNAME , {} ) */


WRAPPER_END
END_C_DECLS



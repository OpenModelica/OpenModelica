#pragma once
/** @addtogroup solverCvode
 *
 *  @{
 */
#include "FactoryExport.h"
#include <Core/Solver/SolverSettings.h>


/*****************************************************************************/
/**

Encapsulation of settings for euler solver

\date     October, 1st, 2008
\author


*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class RTEulerSettings : public SolverSettings
{

public:
    RTEulerSettings(IGlobalSettings* globalSettings);

     virtual void load(std::string xml_file);
private:


};
/** @} */ // end of solverRteuler

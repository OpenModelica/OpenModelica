#pragma once
/** @defgroup coreSystem Core.System
 *  Core module for all algebraic and ode systems
 *  @{
 */
/*****************************************************************************/
/**

Services, which can be used by systems.
Implementation of standart functions (e.g. giveRHS(...), etc.).
Provision of member variables used by all systems.

Note:
The order of variables in the extended state vector perserved (see: "Sorting
variables by using the index" in "Design proposal for a general solver interface
for Open Modelica", September, 10 th, 2008
*/

//omsi header
#include <omsi.h>


#include <Core/System/SystemDefaultImplementation.h>

class BOOST_EXTENSION_EXTENDEDSYSTEM_DECL ExtendedSystem : public SystemDefaultImplementation
{
public:
    ExtendedSystem(shared_ptr<IGlobalSettings> globalSettings, string modelName,
                             size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars,
                                size_t dim_z, size_t z_i);
   
    ExtendedSystem(shared_ptr<IGlobalSettings> globalSettings, string modelName, omsi_t * omsu);
    
    ExtendedSystem(shared_ptr<IGlobalSettings> globalSettings);
    ExtendedSystem(ExtendedSystem & instance);
    virtual ~ExtendedSystem();

 

    shared_ptr<ISimData > getSimData();
 
protected:
   
    
    //optional OMSI instance
    omsi_t * _omsu;
   
    
};


/** @} */ // end of coreSystem

#ifndef OIS_FACTORY_H
#define OIS_FACTORY_H


shared_ptr<IMixedSystem> createOSU(shared_ptr<IGlobalSettings> globalSettings,omsi_t* omsu);
shared_ptr<IMixedSystem> createOSUSystem(shared_ptr<OMSIGlobalSettings> globalSettings,string instanceName, omsi_t* omsu);


#endif
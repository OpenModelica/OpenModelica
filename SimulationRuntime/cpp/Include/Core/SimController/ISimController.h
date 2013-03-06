#pragma once
#include  "ISimData.h"
class ISimController
{

public:
    /// Enumeration to control the time integration

    virtual ~ISimController()    {};


    /*
    Starts the simulation
    modelica_path: path to Modelica model library
    library_path: path runtime librires
    modelKey Modelica model name
    */
    virtual void Start(string modelica_path,string library_path, string modelKey,double startTime,double endTime, double stepSize,ISimData* simData) = 0;

    /// Stops the simulation
    virtual void Stop()= 0;
};

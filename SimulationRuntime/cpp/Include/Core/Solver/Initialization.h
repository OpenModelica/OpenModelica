#pragma once
#include <System/ISystemInitialization.h>
#include <System/IEvent.h>
#include <System/IContinuous.h>
class Initialization
{
public:
    Initialization(ISystemInitialization* system_initialization);
    ~Initialization(void);
    void initializeSystem(double start_time, double end_time);
private:

    ISystemInitialization* _system;

};


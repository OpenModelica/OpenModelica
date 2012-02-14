#pragma once
#include "System/Interfaces/ISystemInitialization.h"
#include "System/Interfaces/IEvent.h"
#include "System/Interfaces/IContinous.h"
class Initialization
{
public:
	Initialization(ISystemInitialization* system_initialization);
	~Initialization(void);
	void initializeSystem(double start_time, double end_time);
private:

	ISystemInitialization* _system;

};


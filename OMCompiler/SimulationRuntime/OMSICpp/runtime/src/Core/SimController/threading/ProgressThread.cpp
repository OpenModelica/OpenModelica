#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/SimController/threading/ProgressThread.h>

#include <Core/SimController/threading/Communicator.h>

#include <zmq.hpp>

 
	/**
	constructor
	*/
	ProgressThread::ProgressThread(Communicator* communicator)
		: _communicator(communicator)
		, _GUIUpdateRate(0.0625)
		,_realtime(false)
		,_delay_time(0.0)
	{

	}
	/**
	Destructor
	*/
	ProgressThread::~ProgressThread()
	{

	}
	void ProgressThread::Run()
	{
        _communicator->setGuiStarted();
        bool should_stop = false;
        double progress_time = 0;
        while (!should_stop)
        {

            
            should_stop = _communicator->waitForResults(progress_time);
            _communicator->notifyResults(progress_time);
            if (_communicator->shouldStop())
                _communicator->stopThreads();
            

        }
        _communicator->setGuiStoped();
	}
	void ProgressThread::setGUIUpdateRate(double GUIUpdateRate,bool realtime)
	{
			_GUIUpdateRate = GUIUpdateRate; 
			_realtime=realtime;
		

	};
	/**
	Sets the delay by simulation pauses
	*/
	void ProgressThread::setDelayTime(double time)
	{
		
		_delay_time=time;
	}
	/**
	Returns the current delay due to simulation pauses.
	*/
	double ProgressThread::getDelayTime()
	{
		
		return _delay_time;
	}
	

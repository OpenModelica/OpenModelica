/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

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
	

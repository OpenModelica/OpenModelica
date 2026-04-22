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

#pragma once

#include <string>






	
	/**
	Enum- Flag das die Benachrichtigunsarten an die GUI beschreibt 
	*/
	enum NotificationType
	{
		No_Notify=0,
		Net_Event=1,
		Console=2,
        ZeroMQ=3
	};
	/**
	 Interface to notify the client for new events
	 */
	class INotify
	{
	public:
		/**
		New simualtion results available for new solver step 
		*/
		virtual void NotifyResults(double time) = 0;
		
        
        /**
        Simulation waits for start simulation
        */
        virtual void NotifyWaitForStarting() = 0;
        /**
        Simulation has started
        */
        virtual void NotifyStarted() = 0;

        /**
		Simulation has finished
		*/
		virtual void NotifyFinish(bool success, string erro_message =  string("no error has occurred")) = 0;

		/**
		Simulation throws an exception
		*/
		virtual void NotifyException(std::string message) = 0;

        virtual bool AskForStop() = 0;
	};



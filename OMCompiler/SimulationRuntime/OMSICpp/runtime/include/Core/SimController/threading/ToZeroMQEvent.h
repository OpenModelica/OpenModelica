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
#include "INotify.h"
#include <zmq.hpp>


	/**
	Forwards the notification for new simulation results and simulation end with ZeroMQ.
	 */
	class ToZeroMQEvent: public INotify
	{
	public:
		ToZeroMQEvent(int pubPort, int subPort, string zeroMQJobiID, string zeroMQServerID, string zeroMQClientID);

		~ToZeroMQEvent();
        virtual void NotifyStarted();
		virtual void NotifyResults(double progress);
		virtual void NotifyFinish(bool success, string erro_message = string("no error has occurred"));
		virtual void NotifyException(std::string message);
        virtual void NotifyWaitForStarting();
        virtual bool AskForStop();
	private:
        zmq::context_t ctx_;
        zmq::socket_t publisher_;
        zmq::socket_t subscriber_;

        string _zeromq_job_id;
        string _zeromq_server_id;
        string _zeromq_client_id;
        int _progress;

      
	};
	

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
	

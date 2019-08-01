#pragma once
#include "INotify.h"
#include <zmq.hpp>


	/**
	Forwards the notification for new simulation results and simulation end with ZeroMQ.
	 */
	class ToZeroMQEvent: public INotify
	{
	public:
		ToZeroMQEvent( );

		~ToZeroMQEvent();
        virtual void NotifyStarted();
		virtual void NotifyResults(double progress);
		virtual void NotifyFinish();
		virtual void NotifyException(std::string message);
        virtual void NotifyWaitForStarting();
        virtual bool AskForStop();
	private:
        zmq::context_t ctx_;
        zmq::socket_t publisher_;
        zmq::socket_t subscriber_;

        std::string  _simulation_id;
        int _progress;

      
	};
	

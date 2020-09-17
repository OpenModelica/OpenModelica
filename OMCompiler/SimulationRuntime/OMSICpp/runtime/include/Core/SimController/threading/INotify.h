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



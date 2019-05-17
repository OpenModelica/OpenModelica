#pragma once



	class Communicator;
	///Thread der für die GUI nach neuen Simulationsergebnissen an DataPool fragt				
	class ProgressThread
	{
	public:
        ProgressThread(Communicator* communicator);
		virtual ~ProgressThread();
		
		void Run();

		void setGUIUpdateRate(double GUIUpdateRate,bool realtime);
		void setDelayTime(double time);
	private:
		double getDelayTime();
		///Objekt für Threadkommunikation
		Communicator* _communicator;
		///Updaterate der GUI
		double _GUIUpdateRate;
		double _delay_time;
		bool _realtime;
	};


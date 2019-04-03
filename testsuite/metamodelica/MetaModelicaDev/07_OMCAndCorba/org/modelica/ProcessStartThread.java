package org.modelica;

import java.io.File;

public class ProcessStartThread extends Thread
{
	String[] command;
	File workingDirectory;

	public ProcessStartThread(String[] command, File workingDirectory)
	{
		this.command = command;
		this.workingDirectory = workingDirectory;
	}

	public void run()
	{
		try
		{
			int result;
//			prepare buffers for process output and error streams
			//StringBuffer err=new StringBuffer();
			//StringBuffer out=new StringBuffer();		    	
			Process proc=Runtime.getRuntime().exec(command, null, workingDirectory);
			//create thread for reading inputStream (process' stdout)
			StreamReaderThread outThread= new StreamReaderThread(proc.getInputStream(),System.out);
			//create thread for reading errorStream (process' stderr)
			StreamReaderThread errThread= new StreamReaderThread(proc.getErrorStream(),System.err);
			//start both threads
			outThread.start();
			errThread.start();
			//wait for process to end
			result=proc.waitFor();
			//finish reading whatever's left in the buffers
			outThread.join();
			errThread.join();
		}
		catch(Exception e)
		{
			e.printStackTrace();
			OMCProxy.logOMCStatus("Error running command " + e.getMessage());
			OMCProxy.logOMCStatus("Unable to start OMC, giving up."); 
		}	    
	}
}

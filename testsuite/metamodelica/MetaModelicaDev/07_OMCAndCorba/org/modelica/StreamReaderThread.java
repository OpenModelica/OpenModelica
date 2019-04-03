package org.modelica;

import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintStream;

public class StreamReaderThread extends Thread
{
	PrintStream mOut;
	InputStreamReader mIn;

	public StreamReaderThread(InputStream in, PrintStream out)
	{
		mOut=out;
		mIn=new InputStreamReader(in);
	}

	public void run()
	{
		int ch;
		try 
		{
			while(-1 != (ch=mIn.read()))
			{
				mOut.append((char)ch);
				mOut.flush();
			}
		}
		catch (Exception e)
		{
			mOut.append("\nRead error:"+e.getMessage());
		}
	}
}
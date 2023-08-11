package org.modelica;

import javax.swing.*;

public class Main 
{
	public static void main(String[] args)
	{
		SwingUtilities.invokeLater(new Runnable()
		{
			public void run()
			{
				JFrame frame = new JFrame("OMC Communicator");
				OMCPane omcPane = new OMCPane();
				frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
				frame.setContentPane(omcPane);
				frame.pack();
				frame.setVisible(true);
			}
		});
	}
}

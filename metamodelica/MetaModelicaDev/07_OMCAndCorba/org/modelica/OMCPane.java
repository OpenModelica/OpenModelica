package org.modelica;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.JLabel;
import javax.swing.JButton;
import javax.swing.JTextArea;
import java.awt.GridLayout;
import javax.swing.event.*;
import java.awt.event.*;
import javax.swing.JSplitPane;
import javax.swing.JScrollPane;
import java.awt.Label;
import java.awt.GridBagLayout;
import java.awt.GridBagConstraints;
import java.awt.FlowLayout;
import javax.swing.BoxLayout;

public class OMCPane extends JPanel implements ActionListener
{

	private JTextField jTextField = null;
	private JButton jButton = null;
	private JTextArea jTextArea = null;
	private OMCProxy omc;
	private JPanel jPanel1 = null;
	private Label label = null;
	private JSplitPane jSplitPane = null;
	private JScrollPane jScrollPane = null;
	/**
	 * This is the default constructor
	 */
	public OMCPane() 
	{
		super(new GridLayout(1,0));
		initialize();
		this.omc = new OMCProxy();;
	}

	/**
	 * This method initializes this
	 * 
	 * @return void
	 */
	private void initialize() 
	{
		this.setSize(398, 260);
		this.add(getJSplitPane(), null);
	}

	/**
	 * This method initializes jTextField	
	 * 	
	 * @return javax.swing.JTextField	
	 */
	private JTextField getJTextField() 
	{
		if (jTextField == null) 
		{
			jTextField = new JTextField();
			jTextField.setName("Expression");
			jTextField.setColumns(20);
		}
		return jTextField;
	}

	/**
	 * This method initializes jButton	
	 * 	
	 * @return javax.swing.JButton	
	 */
	private JButton getJButton() 
	{
		if (jButton == null) 
		{
			jButton = new JButton();
			jButton.setText("Send");
			jButton.setActionCommand("send");
		}
		jButton.addActionListener(this);		
		return jButton;
	}

	/**
	 * This method initializes jTextArea	
	 * 	
	 * @return javax.swing.JTextArea	
	 */
	private JTextArea getJTextArea() 
	{
		if (jTextArea == null) 
		{
			jTextArea = new JTextArea();
			jTextArea.setColumns(25);
			jTextArea.setRows(9);
		}
		return jTextArea;
	}
	
	public void actionPerformed(ActionEvent e)
	{
		System.out.println("ActionCommand:" + e.getActionCommand());
		if (e.getActionCommand().equals("send"))
		{
			System.out.println("Expression:" + jTextField.getText());
			if (jTextField.getText() != null && 
				jTextField.getText().length() > 0)
			{
				String result = "";
				try
				{
					jTextArea.append("\nSending expression:" + jTextField.getText());
					result = omc.sendExpression(jTextField.getText());
					jTextArea.append("\nGot reply:" + result);					
				}
				catch(Exception ex)
				{
					jTextArea.append(
					  "\nError while sending expression: " + jTextField.getText() + "\n"+
					  ex.getMessage());
				}
				jTextField.setText("");
			}
			else
			{
				jTextArea.append("\nNo expression sent because is empty");
			}
		}
	}

	/**
	 * This method initializes jPanel1	
	 * 	
	 * @return javax.swing.JPanel	
	 */
	private JPanel getJPanel1() {
		if (jPanel1 == null) {
			label = new Label();
			label.setText("Expression:");
			jPanel1 = new JPanel();
			jPanel1.setLayout(new BoxLayout(getJPanel1(), BoxLayout.X_AXIS));
			jPanel1.add(label, null);
			jPanel1.add(getJTextField(), null);
			jPanel1.add(getJButton(), null);
		}
		return jPanel1;
	}

	/**
	 * This method initializes jSplitPane	
	 * 	
	 * @return javax.swing.JSplitPane	
	 */
	private JSplitPane getJSplitPane() {
		if (jSplitPane == null) {
			jSplitPane = new JSplitPane();
			jSplitPane.setOrientation(javax.swing.JSplitPane.VERTICAL_SPLIT);
			jSplitPane.setBottomComponent(getJScrollPane());
			jSplitPane.setTopComponent(getJPanel1());
		}
		return jSplitPane;
	}

	/**
	 * This method initializes jScrollPane	
	 * 	
	 * @return javax.swing.JScrollPane	
	 */
	private JScrollPane getJScrollPane() {
		if (jScrollPane == null) {
			jScrollPane = new JScrollPane();
			jScrollPane.setViewportView(getJTextArea());
		}
		return jScrollPane;
	}

}  //  @jve:decl-index=0:visual-constraint="10,10"

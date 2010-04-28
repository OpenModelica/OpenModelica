/* 
 * Simple client to test OMI. 
 *
 * Author: Per Östlund 
 * Last revision: 2010-02-23
 */

#include <iostream>
#include <string>

#include "thread.h"
#include "socket.h"

bool run = true;

void* threadServerControl(void*)
{
	Socket s1;

	s1.create();
	s1.bind(10500);
	s1.listen();

	std::cout << "Control server on: 127.0.0.1:10500" << std::endl;

	Socket s2;
	s1.accept(s2);

	while(run)
	{
		std::string message;

		if(!s2.recv(message))
		{
			std::cout << "threadServerControl: Failed to recieve message!" << std::endl;
			return 0;
		}

		std::cout << "Server recieved message: " << message << std::endl;
	}
}

void* threadServerTransfer(void*)
{
	Socket s1;

	s1.create();
	s1.bind(10502);
	s1.listen();

	std::cout << "Transfer server on: 127.0.0.1:10502" << std::endl;

	Socket s2;
	s1.accept(s2);

	while(run)
	{
		std::string message;

		if(!s2.recv(message))
		{
			std::cout << "threadServerTransfer: Failed to recieve message!" << std::endl;
			return 0;
		}

		std::cout << "Server recieved message: " << message << std::endl;
	}
}

void* threadControlClient(void*)
{
	Socket s1;

	s1.create();

	int retries_left = 5;

	for(; retries_left >= 0; --retries_left)
	{
		if(!s1.connect("127.0.0.1", 10501))
		{
			if(retries_left)
			{
				std::cout << "Connect failed, retrying to connect to 127.0.0.1:10501" << std::endl;
				continue;
			}
			else
			{
				std::cout << "Connect failed, max number of retries reached." << std::endl;
				run = false;
				return 0;
			}
		}

		break;
	}
	

	while(true)
	{
		std::string message;
		std::cout << "enter operation: " << std::endl;
		std::cin >> message;

		std::cout << message << std::endl;

		if(!s1.send(message))
		{
			std::cout << "Failed to send message!" << std::endl;
			break;
		}

		if(message == "end")
		{
			break;
		}

		usleep(500000);
	}

	run = false;
	return 0;
}

int main()
{
	Thread serverControl;
	Thread serverTransfer;
	Thread clientControl;

	serverControl.Create(threadServerControl);
	serverTransfer.Create(threadServerTransfer);
	clientControl.Create(threadControlClient);

	clientControl.Join();
	serverTransfer.Join();
	serverControl.Join();
}


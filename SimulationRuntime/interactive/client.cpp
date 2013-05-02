/*
 * Simple client to test OMI.
 *
 * Author: Per Östlund
 * Last revision: 2010-02-23
 */

#include <iostream>
#include <fstream>
#include <string>
#include <cstdlib>
#include <cstring>
#include <unistd.h>

#include "thread.h"
#include "socket.h"

static bool run = true;

using namespace std;

static string*   fileName = 0;
static fstream*  fileStream = 0;
static int shutDownInProgress = 0;


THREAD_RET_TYPE threadServerControl(void*)
{
  Socket s1;

  s1.create();
  s1.bind(10500);
  s1.listen();

  cout << "Control server on: 127.0.0.1:10500" << endl; fflush(stdout);

  Socket s2;
  s1.accept(s2);

  while(run)
  {
   string message;

   if(!s2.recv(message))
   {
          if (!shutDownInProgress)
          {
                 cout << "threadServerControl: Failed to recieve message!" << endl; fflush(stdout);
                 return 0;
          }
   }

   if (!shutDownInProgress)
   {
          cout << ("Server recieved message: " + message) << endl; fflush(stdout);
   }
  }
  return 0;
}

THREAD_RET_TYPE threadServerTransfer(void*)
{
  Socket s1;

  s1.create();
  s1.bind(10502);
  s1.listen();

  cout << "Transfer server on: 127.0.0.1:10502" << endl; fflush(stdout);

  Socket s2;
  s1.accept(s2);

  while(run)
  {
   string message;

   if(!s2.recv(message))
   {
          if (!shutDownInProgress)
          {
                 cout << "threadServerTransfer: Failed to recieve message!" << endl; fflush(stdout);
                 return 0;
          }
   }

   if (!shutDownInProgress)
   {
          cout << ("Server recieved message: " + message) << endl; fflush(stdout);
   }
  }
  return 0;
}

THREAD_RET_TYPE threadControlClient(void*)
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
                 cout << "Connect failed, retrying to connect to 127.0.0.1:10501 after 2 seconds" << endl; fflush(stdout);
                 delay(2000);
                 continue;
          }
          else
          {
                 cout << "Connect failed, max number of retries reached." << endl; fflush(stdout);
                 run = false;
                 cout << "Exiting..." << endl; fflush(stdout);
                 exit(1);
          }
   }

   break;
  }

  while(true)
  {
   string message;
   cout << "Enter operation to be sent to server: " << endl; fflush(stdout);
   if (!fileName) // no file, read from stdin
   {
          cin >> message;
   }
   else // some file, read from it
   {
          if (!fileStream->eof())
          {
                 (*fileStream) >> message;
          }
          else
          {
                 cout << "End of commands file: " << fileName->c_str() << " has been reached!" << endl; fflush(stdout);
                 cout << "Sending \"end\" to the server and exiting ..." << endl; fflush(stdout);
              message = "";
          }
   }

   if (!message.empty())
   {
          if (!message.compare(0,5,"delay")) // delay
          {
                 // we have a delay in the text, see how much
                 string delayTime = message.substr(5,message.size()-5);
                 cout << "Command to delay the client for: " << delayTime << " seconds." << endl; fflush(stdout);
                 delay(atoi(delayTime.c_str()) * 1000);
              cout << "End delay of " << delayTime << " seconds." << endl; fflush(stdout);
          }
          else // send the message
          {
                 cout << "Message to be send: " << message << endl; fflush(stdout);

                 // set the shutDownInProgress flag so we don't get failure on receive messages
                 // from the transfer thread and server control thread
                 if(message.compare(0, 8, "shutdown") == 0)
                 {
                        shutDownInProgress = 1;
                 }

                 if(!s1.send(message))
                 {
                        cout << "Failed to send message!" << endl; fflush(stdout);
                        break;
                 }

                 if(message.compare(0, 8, "shutdown") == 0)
                 {
                        cout << "Shuting down in 2 seconds .... due to shutdown message: " << message << endl; fflush(stdout);
                        shutDownInProgress = 1;
                        delay(2000);
                        break;
                 }
          }
   }
   else
   {
          cout << "Message: [is empty]" << endl; fflush(stdout);
   }
  }

  run = false;
  return 0;
}

int main(int argc, char **argv)
{
  if (argc == 2)
  {
   if (strcmp(argv[1], "-help") == 0 && strcmp(argv[1], "/?") == 0)
   {
          cout << "usage: client [file-with-commands.txt] [-help|/?]" << endl; fflush(stdout);
          exit(1);
   }
   fileName = new string(argv[1]);
   fileStream = new fstream(fileName->c_str(), fstream::in);
   if (fileStream->fail())
   {
          cout << "Unable to open file: " << fileName->c_str() << "!" << endl; fflush(stdout);
          cout << "usage: client [file-with-commands.txt] [-help|/?]" << endl; fflush(stdout);
          exit(1);
   }
  }

  Thread serverControl;
  Thread serverTransfer;
  Thread clientControl;

  serverControl.Create(threadServerControl);
  delay(1000);
  serverTransfer.Create(threadServerTransfer);
  delay(1000);
  clientControl.Create(threadControlClient);
  delay(1000);

  clientControl.Join();
  serverTransfer.Join();
  serverControl.Join();

  if (fileName)
  {
   fileStream->close();
  }

  return 0;
}


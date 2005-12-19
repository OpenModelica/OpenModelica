#ifndef ERRORMESSAGE_HPP
#define ERRORMESSAGE_HPP

#include <list>
#include <string>

class ErrorMessage {

public:
  ErrorMessage(long errorID,
	       std::string type,
	       std::string severity,
	       std::string message,
	       std::list<std::string> &tokens);

  ErrorMessage(long errorID,
	       std::string type,
	       std::string severity,
	       std::string message,
	       std::list<std::string> &tokens,
	       long lineNo,
	       long columnNo,
	       std::string filename);

  long getID() { return errorID_; };
  
  std::string getType() { return messageType_; };
  
  std::string getSeverity() { return severity_; };

  // Returns the expanded message with inserted tokens.
  const std::string getMessage();

  // Returns the complete message in string format corresponding to a Modeica vector.
  const std::string getFullMessage();

  long getLineNo() { return lineNo_; };

  long getColumnNo() { return lineNo_; };

private:
  long errorID_;
  std::string messageType_;
  std::string severity_;
  std::string message_;
  std::list<std::string> tokens_;
  
  long lineNo_;
  long columnNo_;
  std::string filename_;

};


#endif

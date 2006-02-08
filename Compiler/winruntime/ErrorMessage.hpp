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
	       long startLineNo,
	       long startColumnNo,
	       long endLineNo,
	       long endColumnNo,
	       bool isReadOnly,	       
	       std::string filename);

  long getID() { return errorID_; };
  
  std::string getType() { return messageType_; };
  
  std::string getSeverity() { return severity_; };

  // Returns the expanded message with inserted tokens.
  const std::string getMessage();

  // Returns the complete message in string format corresponding to a Modeica vector.
  const std::string getFullMessage();

  long getLineNo() { return startLineNo_; };
  long getColumnNo() { return startColumnNo_; };
  /* adrpo added these new ones */
  long getStartLineNo() { return startLineNo_; };
  long getStartColumnNo() { return startColumnNo_; };
  long getEndLineNo() { return endLineNo_; };
  long getEndColumnNo() { return endColumnNo_; };
  bool getIsFileReadOnly() { return isReadOnly_; };
  std::string getFileName() { return filename_; };

private:
  long errorID_;
  std::string messageType_;
  std::string severity_;
  std::string message_;
  std::list<std::string> tokens_;
  
  /* adrpo 2006-02-05 changed the ones below */
  long startLineNo_;
  long startColumnNo_;
  long endLineNo_;
  long endColumnNo_;
  bool isReadOnly_;
  std::string filename_;

};


#endif

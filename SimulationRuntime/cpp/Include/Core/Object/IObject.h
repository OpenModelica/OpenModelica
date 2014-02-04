// ObjectBase.h: Schnittstelle für die Klasse IObject.
//
//////////////////////////////////////////////////////////////////////

#pragma once




class IObject
{
public:

    virtual ~IObject()    {};

    virtual void destroy() = 0;

  virtual std::string getName() const  = 0;

    virtual void setName(const std::string name) = 0;


  /// (Re-)Initialisiert das Objekt und schließt den Aufbau ab
  virtual void initialize()  = 0;


};




/************************************************************************
File: modelicaxml.h
Created By: Adrian Pop adrpo@ida.liu.se 
Date:       2003-08-28 (PELAB Internal Conference)
Revised on 2003-10-26 17:58:42
Comments: some includes for the xercesc parser and a xml helper class 
************************************************************************/

#ifndef __FLATMODELICAXML_H_
#define __FLATMODELICAXML_H_

// ---------------------------------------------------------------------------
//  Includes
// ---------------------------------------------------------------------------
#include <xercesc/util/PlatformUtils.hpp>
#include <xercesc/util/XMLString.hpp>
#include <xercesc/dom/DOM.hpp>
#include <xercesc/dom/DOMWriter.hpp>
#include <xercesc/framework/LocalFileInputSource.hpp>
#include <xercesc/framework/LocalFileFormatTarget.hpp>
#include <xercesc/framework/StdOutFormatTarget.hpp>

XERCES_CPP_NAMESPACE_USE

// ---------------------------------------------------------------------------
//  This is a simple class that lets us do easy (though not terribly efficient)
//  trancoding of char* data to XMLCh data.
// ---------------------------------------------------------------------------
class XStr
{
public :
    // -----------------------------------------------------------------------
    //  Constructors and Destructor
    // -----------------------------------------------------------------------
    XStr(const char* const toTranscode)
    {
        // Call the private transcoding method
		fUnicodeForm = XMLString::transcode(toTranscode);
    }

    ~XStr()
    {
		XMLString::release(&fUnicodeForm);
    }


    // -----------------------------------------------------------------------
    //  Getter methods
    // -----------------------------------------------------------------------
	const XMLCh* unicodeForm() const
    {
        return fUnicodeForm;
    }

private :
    // -----------------------------------------------------------------------
    //  Private data members
    //
    //  fUnicodeForm
    //      This is the Unicode XMLCh format of the string.
    // -----------------------------------------------------------------------
	XMLCh*   fUnicodeForm;
};

#define X(str) XStr(str).unicodeForm()

#endif /* #ifndef _FLATMODELICAXML_ */
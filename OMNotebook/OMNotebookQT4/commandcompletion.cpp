/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

* Neither the name of Linköpings universitet nor the names of its contributors
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
*/

// FILE/CLASS ADDED 2005-12-12 /AF

/*! 
* \file commandcompetion.h
* \author Anders Fernström
* \date 2005-12-12
*/


//STD Headers
#include <exception>
#include <iostream>
#include <cstdlib>

//QT Headers
#include <QtCore/QFile>

//IAEX Headers
#include "commandcompletion.h"


using namespace std;

namespace IAEX
{
	/*! 
	 * \class CommandCompletion 
	 * \author Anders Fernström
	 * \date 2005-12-12
	 * 
	 * \brief Reads a command file and creates omc command object for
	 * commandcompetion in inputcells
	 */

	/*! 
	 * \author Anders Fernström
	 * \date 2005-12-12
	 *
	 * \brief The class constructor
	 *
	 * \brief Reads a given file and construct a DOM tree from that file.
	 * If the file is corrupt a exception will be throwed.
	 *
	 * \param filename The file that will be read.
	 */
	CommandCompletion::CommandCompletion( const QString &filename )
		: currentCommand_( -1 ),
		currentField_( -1 ),
		currentList_( 0 ),
		commandStartPos_( 0 ),
		commandEndPos_( 0 )
	{		
		//read a command file.
		doc_ = new QDomDocument( "OMCCommand" );

		QFile file( filename );
		if(!file.open(QIODevice::ReadOnly))
		{
			string tmp = "Could not open file: " + filename.toStdString();
			throw exception( tmp.c_str() );
		}
 
		if( !doc_->setContent(&file) )
		{
			file.close();
			string tmp = "Could not read content from file: " + 
				filename.toStdString() + 
				" Probably some syntax error in the xml file";
			throw exception( tmp.c_str() );
		}
		file.close();

		// initialize all commands in the command file
		initializeCommands();
	}

	CommandCompletion *CommandCompletion::instance_ = 0;

	/*
	 * \author Anders Fernström
	 * \date 2005-12-12
	 *
	 * \brief Instance the CommandCompetion object.
	 *
	 * \param filename The file that will be read.
	 * \return The CommandCompetion object
	 */
	CommandCompletion *CommandCompletion::instance( const QString &filename )
	{
		if( !instance_ )	 
			instance_ = new CommandCompletion( filename );

		return instance_;
	}

	/*
	 * \author Anders Fernström
	 * \date 2005-12-12
	 * \date 2005-12-15 (update)
	 *
	 * \brief Insert a command into the text, if the text match a command
	 *
	 * 2005-12-15 AF, implemented function
	 *
	 * \param cursor The text cursor to the text where the command should
	 * be inserted
	 * \return TURE if a command is inserted
	 */
	bool CommandCompletion::insertCommand( QTextCursor &cursor )
	{
		// check if cursor is okej
		if( !cursor.isNull() )
		{
			// first remove any old currentList_
			if( currentList_ )
			{
				delete currentList_;
				currentList_ = 0;
			}

			// reset currentCommand_ && currentField_
			currentCommand_ = -1;
			currentField_ = -1;

			// find current word in text
			cursor.movePosition( QTextCursor::StartOfWord, QTextCursor::KeepAnchor );
			QString command = cursor.selectedText();

			if( !command.isNull() && !command.isEmpty() )
			{
				// check if any comman match the current word in the text
				currentList_ = new QStringList();
				for( int i = 0; i < commandList_.size(); ++i )
				{ 
					if( 0 == commandList_.at(i).indexOf( command, 0, Qt::CaseInsensitive ))
						currentList_->append( commandList_.at(i) );
				}

				//cout << "Found commands (" << command.toStdString() << "):" << endl;
				//for( int i = 0; i < currentList_->size(); ++i )
				//	cout << " >" << currentList_->at(i).toStdString() << endl;

				// found one or more commands that match the word
				if( currentList_->size() > 0 )
				{
					currentCommand_ = 0;

					commandStartPos_ = cursor.position();
					cursor.insertText( currentList_->at( currentCommand_ ));
					commandEndPos_ = cursor.position();

					// select first field, if any
					nextField( cursor );

					return true;
				}
				else
				{
					delete currentList_;
					currentList_ = 0;
				}
			}
		}
		
		return false;
	}

	/*
	 * \author Anders Fernström
	 * \date 2005-12-12
	 *
	 * \brief Insert the next possible command into the text, that match 
	 * a command
	 *
	 * \param cursor The text cursor to the text where the command should
	 * be inserted
	 * \return TURE if a command is inserted
	 */
	bool CommandCompletion::nextCommand( QTextCursor &cursor )
	{
		// check if cursor is okej
		if( !cursor.isNull() )
		{
			// check if currentList_ exists
			if( currentCommand_ >= 0 && currentList_ )
			{
				// if no more commands existes, restart
				if( currentCommand_ >= (currentList_->size()-1) )
					currentCommand_ = -1;
				
				// reset currentField_
				currentField_ = -1;

				//next command
				currentCommand_++;
				cursor.setPosition( commandStartPos_ );
				cursor.setPosition( commandEndPos_, QTextCursor::KeepAnchor );
				cursor.insertText( currentList_->at( currentCommand_ ));
				commandEndPos_ = cursor.position();

				// select first field, if any
				nextField( cursor );

				return true;
			}
		}

		return false;
	}

	/*
	 * \author Anders Fernström
	 * \date 2005-12-12
	 *
	 * \brief Returns the help text to the current command
	 *
	 * \return Helpt text to current command
	 */
	QString CommandCompletion::helpCommand()
	{
		if( currentCommand_ >= 0 )
		{
			if( currentList_->size() > currentCommand_ )
			{
				QString command = currentList_->at( currentCommand_ );
				if( commands_.contains( command ))
					return commands_[command]->helptext();
			}
		}

		return QString::null;
	}

	/*
	 * \author Anders Fernström
	 * \date 2005-12-12
	 * \date 2005-12-15 (update)
	 *
	 * \brief Select next (if any) field in current command
	 * 
	 * 2005-12-15 AF, implemented function
	 *
	 * \return TURE if a field is selected
	 */
	bool CommandCompletion::nextField( QTextCursor &cursor )
	{
		// check if cursor is okej
		if( !cursor.isNull() )
		{
			if( currentCommand_ >= 0 && currentCommand_ < currentList_->size() )
			{
				QString command = currentList_->at( currentCommand_ );

				if( commands_.contains( command ))
				{
					if( currentField_ < (commands_[command]->numbersField() - 1) )
					{
						//next field
						currentField_++;				
						QString fieldID;
						fieldID.setNum( currentField_ );
						fieldID = "$" + fieldID;
						QString field = commands_[command]->datafield( fieldID );

						if( !field.isNull() )
						{
							// get text in editor
							cursor.setPosition( commandStartPos_ );
							cursor.movePosition( QTextCursor::EndOfBlock, QTextCursor::KeepAnchor );
							QString text = cursor.selectedText();

							int pos = text.indexOf( field, 0 );
							if( pos >= 0 )
							{
								// select field
								cursor.setPosition( commandStartPos_ + pos );
								cursor.setPosition( commandStartPos_ + pos + field.size(), QTextCursor::KeepAnchor );
								return true;
							}
						}
					}
				}
			}
		}

		return false;
	}

	/*! 
	 * \example from commands.xml
	 *
	 * <command name="simulate($1|, startTime=$2|, stopTime=$3|, numberOfIntervals=$4|)">
	 *	<field name="$1|">modelname</field>
	 *	<field name="$2|">&lt;Real></field>
	 *	<field name="$3|">&lt;Real></field>
	 *	<field name="$4|">&lt;Integer></field>
	 *	<helptext>Translates a model and simulates it. Ex: simulate(dcmotor). Ex: simulate(dcmotor,startTime=0, stopTime=10, numberOfIntervals=1000).</helptext>
	 * </command>
	 *
	 */

	/*
	 * \author Anders Fernström
	 * \date 2005-12-12
	 *
	 * \brief loop through the DOM tree and creates CommandUnit after
	 * specified commands.
	 */
	void CommandCompletion::initializeCommands()
	{
		QDomElement root = doc_->documentElement();
		QDomNode node = root.firstChild();

		// loop through the DOM tree
		while( !node.isNull() )
		{
			QDomElement element = node.toElement();
			if( !element.isNull() )
			{
				if( element.tagName() == "command" )
				{
					CommandUnit *unit = new CommandUnit( element.attribute( "name" ));
					QDomNode n = element.firstChild();
					parseCommand( n, unit );

					commands_.insert( unit->fullName(), unit );
					commandList_.append( unit->fullName() );
				}
			}
			node = node.nextSibling();
		}
	}

	/*
	 * \author Anders Fernström
	 * \date 2005-12-12
	 *
	 * \brief parse through a command tag in the DOM tree
	 */
	void CommandCompletion::parseCommand( QDomNode node, CommandUnit *item ) const
	{
		if( !item )
			throw exception( "ParseCommand... No ITEM set" );

		while( !node.isNull() )
		{
			QDomElement element = node.toElement();

			if( element.tagName() == "field" )
				item->addDataField( element.attribute( "name" ), element.text() );
			else if( element.tagName() == "helptext" )
				item->setHelptext( element.text() );
			else
				cout << "Tag not known" << element.tagName().toStdString();

			node = node.nextSibling();
		}
	}

}

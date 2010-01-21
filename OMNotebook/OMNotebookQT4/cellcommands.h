/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
 */

/*!
 * \file cellcommands.h
 * \author Ingemar Axelsson and Anders Fernström
 *
 * \brief Describes different cell commands
 */

#ifndef CELLCOMMANDS_H
#define CELLCOMMANDS_H

//STD Headers
#include <vector>

//IAEX Headers
#include "command.h"
#include "factory.h"
#include "cellcursor.h"
#include "document.h"
#include "cellapplication.h"


using namespace std;

namespace IAEX
{
	class AddCellCommand : public Command
	{
	public:
		AddCellCommand(){}
		virtual ~AddCellCommand(){}
		virtual QString commandName(){ return QString("AddCellCommand");}
		void execute();
	};


	class CreateNewCellCommand : public Command
	{
	public:
		CreateNewCellCommand(const QString &style) : style_(style){}
		virtual ~CreateNewCellCommand(){}
		virtual QString commandName(){ return QString("CreateNewCellCommand");}
		void execute();
	private:
		QString style_;
	};


	//\todo rename to cut command instead.o
	class DeleteCurrentCellCommand : public Command
	{
	public:
		DeleteCurrentCellCommand(){}
		virtual ~DeleteCurrentCellCommand(){}
		void execute();
		virtual QString commandName(){ return QString("DeleteCurrentCellCommand");}
	};


	class PasteCellsCommand : public Command
	{
	public:
		PasteCellsCommand(){}
		virtual ~PasteCellsCommand(){}
		void execute();
		QString commandName(){return QString("PasteCellsCommand");}
	private:
		void pasteCell( Cell *cell, CellGroup *groupcell = 0 );
	};


	class CopySelectedCellsCommand : public Command
	{
	public:
		CopySelectedCellsCommand(){}
		virtual ~CopySelectedCellsCommand(){}
		void execute();
		QString commandName(){return QString("CopySelectedCellsCommand");}
	private:
	};


	class DeleteSelectedCellsCommand : public Command
	{
	public:
		DeleteSelectedCellsCommand(){}
		virtual ~DeleteSelectedCellsCommand(){}
		void execute();
		virtual QString commandName(){ return QString("DeleteSelectedCellsCommand");}
	};


	// Made changes to this class, see cellcommands.cpp /AF
	class ChangeStyleOnSelectedCellsCommand : public Command
	{
	public:
		ChangeStyleOnSelectedCellsCommand(CellStyle style):style_(style){}
		virtual ~ChangeStyleOnSelectedCellsCommand(){}
		void execute();
		virtual QString commandName(){ return QString("ChangeStyleOnSelectedCellsCommand");}
	private:
		CellStyle style_;
	};

	class ChangeStyleOnCurrentCellCommand : public Command
	{
	public:
		ChangeStyleOnCurrentCellCommand(const QString &style):style_(style){}
		virtual ~ChangeStyleOnCurrentCellCommand(){}
		void execute();
		virtual QString commandName(){ return QString("ChangeStyleOnCurrentCellCommand");}
	private:
		QString style_;
	};

	/*! Makes a groupcell of current cell. Just move the cell down.
	*
	* \todo Create a command for converting selected cells into a
	* groupcell.(Ingemar Axelsson)
	*
	* \todo Create commands for moving a cell.(Ingemar Axelsson)
	*
	* \todo Implement DRAG and DROP with cells.(Ingemar Axelsson)
	*/
	class MakeGroupCellCommand : public Command
	{
	public:
		MakeGroupCellCommand(){}
		virtual ~MakeGroupCellCommand(){}
		void execute();
	};

	// 2006-04-26 AF, UNGROUP
	class UngroupCellCommand : public Command
	{
	public:
		UngroupCellCommand(){}
		virtual ~UngroupCellCommand(){}
		virtual QString commandName(){ return QString("UngroupCellCommand");}
		void execute();
	};

	// 2006-04-26 AF, SPLIT CELL
	class SplitCellCommand : public Command
	{
	public:
		SplitCellCommand(){}
		virtual ~SplitCellCommand(){}
		virtual QString commandName(){ return QString("SplitCellCommand");}
		void execute();
	};

};
#endif

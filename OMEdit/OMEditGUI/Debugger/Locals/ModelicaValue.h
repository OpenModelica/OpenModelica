/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef MODELICAVALUE_H
#define MODELICAVALUE_H

#include <QObject>

class LocalsTreeItem;
class ModelicaValue : public QObject
{
  Q_OBJECT
public:
  ModelicaValue(LocalsTreeItem *pLocalsTreeItem);
  LocalsTreeItem* getLocalsTreeItem() {return mpLocalsTreeItem;}
  void setValue(QString value) {mValue = value;}
  QString getValue() {return mValue;}
  virtual QString getValueString() = 0;
  virtual void retrieveChildrenSize() = 0;
  virtual void setChildrenSize(QString size) = 0;
  virtual bool hasChildren() = 0;
  virtual void retrieveChildren() = 0;
protected:
  LocalsTreeItem *mpLocalsTreeItem;
  QString mValue;
};

class ModelicaCoreValue : public ModelicaValue
{
  Q_OBJECT
public:
  ModelicaCoreValue(LocalsTreeItem *pLocalsTreeItem);
  QString getValueString();
  void retrieveChildrenSize() {}
  void setChildrenSize(QString size) {Q_UNUSED(size);}
  bool hasChildren() {return false;}
  void retrieveChildren() {}
};

class ModelicaRecordValue : public ModelicaValue
{
  Q_OBJECT
public:
  ModelicaRecordValue(LocalsTreeItem *pLocalsTreeItem);
  void setRecordElements(int elements) {mRecordElements = elements;}
  int getRecordElements() {return mRecordElements;}
  void retrieveChildrenSize();
  QString getValueString();
  void setChildrenSize(QString size);
  bool hasChildren() {return mRecordElements > 1;}
  void retrieveChildren();
private:
  int mRecordElements;
};

class ModelicaListValue : public ModelicaValue
{
  Q_OBJECT
public:
  ModelicaListValue(LocalsTreeItem *pLocalsTreeItem);
  void setListLength(int length) {mListLength = length;}
  int getListLength() {return mListLength;}
  void retrieveChildrenSize();
  QString getValueString();
  void setChildrenSize(QString size);
  bool hasChildren() {return mListLength > 0;}
  void retrieveChildren();
private:
  int mListLength;
};

class ModelicaOptionValue : public ModelicaValue
{
  Q_OBJECT
public:
  ModelicaOptionValue(LocalsTreeItem *pLocalsTreeItem);
  void setOptionNone(bool none) {mIsOptionNone = none;}
  bool isOptionNone() {return mIsOptionNone;}
  void retrieveChildrenSize();
  QString getValueString();
  void setChildrenSize(QString size);
  bool hasChildren() {return !isOptionNone();}
  void retrieveChildren();
private:
  bool mIsOptionNone;
};

class ModelicaTupleValue : public ModelicaValue
{
  Q_OBJECT
public:
  ModelicaTupleValue(LocalsTreeItem *pLocalsTreeItem);
  void setTupleElements(int elements) {mTupleElements = elements;}
  int getTupleElements() {return mTupleElements;}
  void retrieveChildrenSize();
  QString getValueString();
  void setChildrenSize(QString size);
  bool hasChildren() {return mTupleElements > 0;}
  void retrieveChildren();
private:
  int mTupleElements;
};

class MetaModelicaArrayValue : public ModelicaValue
{
  Q_OBJECT
public:
  MetaModelicaArrayValue(LocalsTreeItem *pLocalsTreeItem);
  void setArrayLength(int elements) {mArrayLength = elements;}
  int getArrayLength() {return mArrayLength;}
  void retrieveChildrenSize();
  QString getValueString();
  void setChildrenSize(QString size);
  bool hasChildren() {return mArrayLength > 0;}
  void retrieveChildren();
private:
  int mArrayLength;
};

#endif // MODELICAVALUE_H

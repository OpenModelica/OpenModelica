/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef PROCESSLISTMODEL_H
#define PROCESSLISTMODEL_H

#include <QAbstractItemModel>
#include <QSortFilterProxyModel>

class ProcessItem
{
public:
  ProcessItem() : mProcessId(0) {}
  bool operator<(const ProcessItem &other) const;

  int mProcessId;
  QString mProcessName;
  QString mProcessPath;
};

class ProcessListModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  ProcessListModel(QObject *pParent = 0);
  qint64 getSelfProcessID() {return mSelfProcessId;}
  static QList<ProcessItem> getLocalProcesses();
  QString processIdAt(const QModelIndex &index) const;
  void updateProcessList();
private:
  const qint64 mSelfProcessId;
  QList<ProcessItem> mProcesses;

  QModelIndex index(int row, int column, const QModelIndex &parent) const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  int columnCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
  virtual Qt::ItemFlags flags(const QModelIndex &index) const override;
  QModelIndex parent(const QModelIndex &) const override;
  bool hasChildren(const QModelIndex &parent) const override;
};

class ProcessListFilterModel : public QSortFilterProxyModel
{
public:
  ProcessListFilterModel();
  bool lessThan(const QModelIndex &left, const QModelIndex &right) const;
};

#endif // PROCESSLISTMODEL_H

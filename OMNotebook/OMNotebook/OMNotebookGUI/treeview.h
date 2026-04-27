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

/*! \file treeview.h
 *  \author Ingemar Axelsson
 */
#ifndef TREEVIEW_H
#define TREEVIEW_H

#include <QtGlobal>
#include <QtWidgets>

namespace IAEX
{

   /*! \class TreeView
    * \brief Class describing how the treeview should be drawn.
    * \author Ingemar Axelsson
    *
    * TreeView is responsible for drawing the treestructure for each
    * cell.
    *
    * \todo Find a way to easily extend a cell with multiple
    * treeviews. It should be easy to change the treeview to a more
    * goodlooking view if someone wants to do that.(Ingemar Axelsson)
    */
   class TreeView : public QWidget
   {
      Q_OBJECT
   public:
      TreeView(QWidget *parent=0);

      void setBackgroundColor(const QColor col);

      const bool selected() const;
      const bool isClosed() const;

   public slots:
      void setClosed(const bool closed);
      void setSelected(const bool sel);

   protected:
      void paintEvent(QPaintEvent *event);
      //void mousePressedEvent(QMouseEvent *event);
      //void mouseReleaseEvent(QMouseEvent *event);
      QColor selectedColor() const;
      QColor backgroundColor() const;

   private:
      bool selected_;
      bool closed_; //This is not a good way, but it works for now!
      QColor selectedColor_;
      QColor backgroundColor_;
   };

   class InputTreeView : public TreeView
   {
   public:
      InputTreeView(QWidget *parent=0);
   protected:
      void paintEvent(QPaintEvent *event);
   };
}
#endif

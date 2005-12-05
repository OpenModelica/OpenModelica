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

#include <stdexcept>


#include "imagecell.h"

using namespace std;

namespace IAEX
{
   /*! \class ImageCell
    * \brief Shows an image in the celltree.
    *
    * This class is responsible for cells that displays images. It can
    * display jpeg images and some other formats, see Qt documentation
    * at trolltech for more information.
    *
    * \todo Implement scaling and more appropriate sizes for images.
    *
    * \todo Implement margins so images is displayed at the center of 
	* the widget. 
    */
   ImageCell::ImageCell(const QString &filename, QWidget *parent, const char *name)
      : Cell(parent, name), filename_(filename)
   {
      if(!picture_.load(filename_))
	 throw runtime_error("could not load pixmap");

      setHeight(picture_.height());
   }

   ImageCell::~ImageCell()
   {
   }   

   const QString ImageCell::filename() const
   {
      return filename_;
   }

   void ImageCell::accept(Visitor &v)
   {
      v.visitImageCellNodeBefore(this);

      if(hasChilds())
	 child()->accept(v);

      v.visitImageCellNodeAfter(this);

      //Move along.
      if(hasNext())
	 next()->accept(v);
   }
   
   
   /*!
    * \todo Move image into the center. Then change it to the correct
    * size. Scale down if needed.
    */
   void ImageCell::paintEvent(QPaintEvent *event)
   {
      QPainter p(this);
      
      //if(picture_.width() < width())
      //scale down picture to width.    
      
      p.drawPixmap(0,0, picture_);
   }
}

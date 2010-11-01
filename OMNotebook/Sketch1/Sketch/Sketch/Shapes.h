#ifndef SHAPES_H
#define SHAPES_H

#include "basic.h"
#include "Label.h"

using namespace std;

class Shapes:public QWidget
{
        Q_OBJECT
    public:
        Shapes(QWidget *parent=0);
        void draw_rect();
        void draw_line();
        void draw_rubber_rect();
        void draw_rubber();
        vector<Label> shapes;
    protected:
         void mousePressEvent(QMouseEvent *);
         void mouseMoveEvent(QMouseEvent *);
         void mouseReleaseEvent(QMouseEvent *);
         void paintEvent(QPaintEvent *);

    private:
         QImage image,image2;
         QPixmap pixmap;
         QPoint strt_pnt;
         QPoint last_pnt;
         QLabel *label,*label1;
         QPainter painter;
         QRubberBand *rubber_rect;
         int state;
         bool button_state,rubber_state;
         Label shape;

};

#endif // SHAPES_H

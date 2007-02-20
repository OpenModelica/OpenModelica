#ifndef VERTICALLABEL_H
#define VERTICALLABEL_H
#include <QLabel>
#include <QString>
//#include <QColor>
using namespace std;


class VerticalLabel: public QLabel
{
public:
	VerticalLabel(QWidget * parent = 0, Qt::WindowFlags f = 0 ): QLabel(parent, f)
	{

	}
	VerticalLabel(const QString & text, QWidget * parent = 0, Qt::WindowFlags f = 0): QLabel(text, parent,f)
	{


	}
	~VerticalLabel()
	{

	}

protected:



	void paintEvent ( QPaintEvent * event )
	{

		QPainter painter(this);
		painter.translate(width() /2., height() /2.);
		painter.rotate(-90);
		painter.translate(width() /-2., height() /-2.);
		painter.setFont(font());
		painter.drawText(rect(), Qt::AlignCenter, text());

	}


};


#endif
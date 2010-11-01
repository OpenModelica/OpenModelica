#ifndef TOOLS_H
#define TOOLS_H

#include "basic.h"
#include "Graph_Scene.h"

#include "document.h"
#include "command.h"
#include "application.h"
#include "documentview.h"


class Tools:public QMainWindow
{
    Q_OBJECT
    public:
          Tools(Document *,DocumentView *);
		  void open(const QString filename);
		  void open();
		  void getCells(const QVector<Cell*> cells);
		  void getFileName(const QString &FileName);

		  void SaveSketchImage();
		  void readXml();
		  void writeXml();


        private slots:
           void draw_arc();
           void draw_rect();
           void draw_round_rect();
           void draw_line();
           void draw_ellipse();
           void draw_polyline();

           void draw_new();
           void draw_save();
           void draw_open();
           void draw_shapes();
           void msg_save_file();
           void msg_dnt_save_file();

           void draw_xml_save();
           void draw_image_save();

           void draw_copy();
           void draw_cut();
           void draw_paste();

    protected:
           void mousePressEvent(QMouseEvent *);
		   void closeEvent(QCloseEvent* event);//function to close the window
          
        private:
           void button_action();
           void action();
           void menu();

           void openFile();

		
       QString application;
       QString file_name,onb_file_name;

       QToolBar *tool_bar;
       QToolButton *rect;
       QMenu *fileMenu,*editMenu,*toolMenu;
       QAction *arc,*rectangle,*round_rectangle,*line,*ellipse,*polyline,*new_scene,*save_scene,*open_scene;
       //Action for file items
       QAction *file_new,*file_open,*file_save,*file_close,*file_xml_save,*file_image_save;

       //Action for copy,cut and paste
       QAction *copy,*cut,*paste;

       //Action for shapes
       QAction *shapes;

       //File dialog box
       QFileDialog *file_dialog;
       //Message Box
       QMessageBox *msg;
       //Message buttons
       QPushButton *msg_save,*msg_dnt_save,*msg_cancle;
       //Xml Message buttons
       QPushButton *msg_xml_save;
       //Message Box buttons Action
       QAction *msg_bt_save,*msg_bt_dnt_save;
       QLabel *label;
       QLayout *layout;
       QVBoxLayout *main_layout;
       QHBoxLayout *hlayout;
       QWidget *main_widget;
       QFrame *frame;
       Graph_Scene *scene;
       QGraphicsView *view;

	   QVector<QString> filenames;
	   QVector<QString> onbfilenames;
	   QVector<QString> imagefilenames;
	   QVector<QString> positions;
	   QVector<QString> texts;
	   QVector<QString> cellIds;
	   QVector<Cell*> cells;

	   //Return the present cellId
	   void getCellId(const Cell* cell,int &id);//Added by jhansi 

       QTextEdit *textEdit;
       QTextCharFormat *textFormat;

	   
	   Document *document;
	   DocumentView *doc_view;

	   bool edit;

	   bool isSaved;
	   
};

#endif // TOOLS_H

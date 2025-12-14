//+------------------------------------------------------------------+
//|                                               ControlsButton.mq5 |
//|                         Copyright 2000-2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Control Panels and Dialogs. Demonstration class CButton"

#include <Controls\Button.mqh>

CButton           m_button1;
CButton           m_button2;

// CreateButton1

//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//--- indents and gaps
#define INDENT_LEFT                         (11)      // indent from left (with allowance for border width)
#define INDENT_TOP                          (11)      // indent from top (with allowance for border width)
#define INDENT_RIGHT                        (11)      // indent from right (with allowance for border width)
#define INDENT_BOTTOM                       (11)      // indent from bottom (with allowance for border width)
#define CONTROLS_GAP_X                      (5)       // gap by X coordinate
#define CONTROLS_GAP_Y                      (5)       // gap by Y coordinate
//--- for buttons
#define BUTTON_WIDTH                        (100)     // size by X coordinate
#define BUTTON_HEIGHT                       (20)      // size by Y coordinate
//--- for the indication area
#define EDIT_HEIGHT                         (20)      // size by Y coordinate
//--- for group controls
#define GROUP_WIDTH                         (150)     // size by X coordinate
#define LIST_HEIGHT                         (179)     // size by Y coordinate
#define RADIO_HEIGHT                        (56)      // size by Y coordinate
#define CHECK_HEIGHT                        (93)      // size by Y coordinate

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   Print("On Init ... 555 ");

//--- coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP+(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_button1.Create(0,"Button1",0,x1,y1,x2,y2))
      return(false);
   if(! m_button1.Size(200, 100))
      return false;
   if(!m_button1.Text("Button1"))
      return(false);

   if(!m_button2.Create(0,"Button2",0,x1,y1+120,x2,y2))
      return(false);
   if(! m_button2.Size(200, 100))
      return false;
   if(!m_button2.Text("Button2"))
      return(false);


   ChartRedraw(0);

//--- succeed
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

// Print("hello OnTick");

  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- clear comments
   Comment("");

  }
//+------------------------------------------------------------------+
//| Expert chart event function                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // event ID
                  const long& lparam,   // event parameter of the long type
                  const double& dparam, // event parameter of the double type
                  const string& sparam) // event parameter of the string type
  {

   if(id == CHARTEVENT_OBJECT_CLICK)
     {

      // Print("hello");

      if(sparam==m_button2.Name())
        {
         Print("132456");

         datetime server_time = TimeCurrent();
         Print("Server Time (formatted): ", TimeToString(server_time, TIME_DATE|TIME_SECONDS)); // yyyy.mm.dd hh:mi:ss
  
         

         m_button2.Text(TimeToString(server_time, TIME_SECONDS));
         
         // ?
         ChartRedraw(0);

        }

     }

   // Print("hello");
   
   //MqlDateTime time2_;
   //TimeGMT(time2_);
   //m_button2.Text(time2_);

  }
//+------------------------------------------------------------------+

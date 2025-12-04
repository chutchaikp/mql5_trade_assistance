//+------------------------------------------------------------------+
//|                                                    EX_PANEL2.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.10"

// https://www.mql5.com/en/articles/16084
// https://www.mql5.com/en/articles/16146

#define Btn_MAIN "Btn_MAIN"

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>


CButton obj_Btn_MAIN;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---

   obj_Btn_MAIN.Create(0, Btn_MAIN, 0, 30, 30, 0, 0); //--- Create the main button at specified coordinates
   obj_Btn_MAIN.Width(120); //---  Set width of the main button
   obj_Btn_MAIN.Height(120); //---  Set height of the main button
//   obj_Btn_MAIN.Size(310, 300);
//
//   obj_Btn_MAIN.ColorBackground(C'070,070,070'); //--- Set background color of the main button
//   obj_Btn_MAIN.ColorBorder(clrBlack); //--- Set border color of the main button


   ChartRedraw(0); //--- Redraw the chart to update the panel

//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---




}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---

}
//+------------------------------------------------------------------+

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {

}
//+------------------------------------------------------------------+

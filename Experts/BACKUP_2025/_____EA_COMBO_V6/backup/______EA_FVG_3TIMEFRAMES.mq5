//+------------------------------------------------------------------+
//|                                                EA_FVG_3LEVEL.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.06"

// TODO:

// - H4 FVG(shift=0)
// - m5 FVG(shift=0)
// - m1 FVG(shift=1) confirm  <---------------- start here
// - m5 ADX or m1 ADX ?       <---------------- optimize this

// - m5 ADX or m1 ADX ?       <---------------- optimize this


// ADX slope must > 0.5

//How to Use
//GetADXSlope() will return a positive value for a rising ADX line (increasing trend strength).
//A negative value means the ADX line is falling (weakening trend).


#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

#include <_ICT6.2\HELPER.mqh>
#include <_ICT6.2\UI.mqh>
//#include <_ICT6.2\ANALYSER_HELPER.mqh>

CSymbolInfo                   m_symbol;
//CPositionInfo               m_position;
//CTrade                      trade;

//______________________________________________________________________
//_______________________________<INPUTS>_______________________________

input bool                                         USE_IS_NEW_BAR=true;

//input ENUM_TIMEFRAMES                              HIGHER_TIMEFRAME=PERIOD_H4;
//input ENUM_TIMEFRAMES                              CURRENT_TIMEFRAME=PERIOD_M5;
//input ENUM_TIMEFRAMES                              LOWER_TIMEFRAME=PERIOD_M1;


input ENUM_ADX_THRESHOLD                           ADX_THRESHOLD=ADX_THRESHOLD20;

ENUM_STORSI_KLINE                            KPeriodSelect=KPERIOD14;

//input bool                                         NOTIFY_BOOL=false;
//input bool                                         USE_FIBO_BOOL=true;


// USE_ATR -> SL_FROM_SWING_OR_ATR
//input int                                          SL_FROM_SWING_OR_ATR=-1;         //SL_FROM_SWING_OR_ATR(-1:prev swing high TF 0:curr swing high TF 1:ATRmul)
input double                                       ATR_multiplier=2;                  //ATRmult(8-48)
//input bool                          LIMIT_trade_time        =false;
bool                                         LIMIT_TRADE_TIME_BOOL=false;
//input bool                          hold_on_WEEKEND         =false;
bool                                         HOLD_ON_WEEKEND_BOOL=false;
//int                     ATR_shift=0; // ATR shift(0 or 1)

int                     BALANCE_MINIMUM_ALLOWED=500;

input int                                          MAX_BUY_TOTAL_INT=10;
input int                                          MAX_SELL_TOTAL_INT=10;

//input bool                                         USE_CUTOFF_LOSS_BOOL=false;
//input bool                                         USE_CUTOFF_PROFIT_BOOL=false;

//+------------------------------------------------------------------+
input double                                       POSITION_SIZE_DOUBLE=1;
//+------------------------------------------------------------------+
//input double                                       CUTOFF_LOSS_USD=-10; // CUTOFF LOSS USD
//input double                                       CUTOFF_PROFIT_USD=80; // CUTOFF PROFIT USD

// 1-waitconfitm, 0-nowait
//input int                                          FVG_SHIFT_INT=0; // FVG shift(0 OR 1)

//input int                                             RSI_TIMER_UPDATE_INTERVAL_INT=480;
//input int                                          STORSI_TIMER_UPDATE_INTERVAL_INT=30;

//input ENUM_TIMEFRAMES                              STORSI_TIMEFRAME=PERIOD_H3;
//input bool                                         STORSI_WHEN_OVERBOUGHT_OVERSOLD=false;

// input bool                                         WHEN_OVERBOUGHT_OVERSOLD=true;

//input ENUM_TIMEFRAMES                              FIBONACCI_TIMEFRAME=PERIOD_H1;
//input ENUM_TIMEFRAMES                              ANALYSER_TIMEFRAME=PERIOD_H4;

// bool     USE_TRAILING_BOOL=true;
// double RR=1; // RR 1=1:1, 1.5=1:1.5
// CAL TP FROM FIBONACCI EXTENSION ?

//      double tp127 = retrace + (diff * 1.272);
//      double tp1618 = retrace + (diff * 1.618);
// input bool                                         USE_FIBONACCI_EXTENSION_BOOL=true;
// USE_FIBONACCI_EXTENSION_OPTION -> TP_FIBONACCI_EXTENSION_OPTIONS

//input int                                          TP_FROM_FIBONACCI_EXTENSION_OPTIONS=0;    //TP.FROM.FIBO.EXT(0:ATR,1:FIBOEXT1.272,2:FIBOEXT1.618)
//input int                                          SL_FROM_SWING_OR_ATR=1;                  //SL.FROM.SWING.OR.ATR(-1:prev.swing,0:curr.swing,1:ATR)

//_______________________________</INPUTS>_______________________________


//// -------- STORSI -------------
//// int KPeriod = 14;
////int KPeriod = 3;
//// int KPeriod = 5;
//input int                        KPeriodSelect=2; // KPeriod(1: "3", 2: "5", 3: "14")
//int DPeriod = 3;
//int RSI_Period = 14;
//double STORSI_OVER_BOUGHT = 80.0;
//double STORSI_OVER_SOLD  = 20.0;


// input bool                          ASYNC_MODE=true;

bool                             SHOW_FVG_MARKER=false;
bool                             SHOW_COMMENT=false;

bool                             USE_DYNAMIC_ATR=true; // USE DYNAMIC ATR
//setup trade time
int                              hour_start=8;  // Start Hour (utc+2)
int                              hour_end=18;   // End Hour (utc+2)

FVG fvg = {FVG_NONE, 0, 0, __DATETIME__, 0};

datetime                         lastbar_timeopen=__DATETIME__; // IS NEW BAR, LOR_;

bool IS_FRIDAYNIGHT_SATURDAY_SUNDAY = false;

long allows_account[]               = { 1,2,332463240,98377677 };
// bool is_authorized                  =false;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---

//| ------ ACCOUNT MANAGE ------ |
   string accoutn_name = AccountInfoString(ACCOUNT_NAME);
   long account_login = AccountInfoInteger(ACCOUNT_LOGIN);
   int index_=FindInArray(allows_account,account_login);  // if ( accoutn_name == "Tester" || index_ >= 0  )
   if(index_ >= 0) {
      Comment(StringFormat("Welcome     %s login : %d  ", accoutn_name, account_login)); // is_authorized=true;
   } else {
      Comment("Unauthorized!");
      ExpertRemove();
   }


   ResetLastError();

   InitIndicatorCustom(KPeriodSelect);

   // EventSetTimer(TIMER_UPDATE_INTERVAL_INT);

   CreateLabel_Generic();

//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   Comment("");

   EventKillTimer();

   ObjectsDeleteAll(0);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
// - HIGHER TIMEFRAME/CURRENT TIMEFRAME/LOWER TIMEFRAME ?
//+------------------------------------------------------------------+
void OnTick() {

   if(HOLD_ON_WEEKEND_BOOL==false && IsFridayNightSaturdaySunday()==true) {
      if(PositionsTotal() > 0) {
         PositionCloseAllV1();
      }
      return;
   }

   if(InTimeRange_Generic() == false && LIMIT_TRADE_TIME_BOOL==true ) {
      if(PositionsTotal() > 0) {
         PositionCloseAllV1();
      }
      return;
   }


   //if(IsNewBar(lastbar_timeopen)) {
   //   OrderConditions();
   //}

   if (USE_IS_NEW_BAR==true) {
      if (IsNewBar(lastbar_timeopen)) {
         OrderConditions();
      }
   } else {
      OrderConditions();
   }

}
//+------------------------------------------------------------------+

datetime last_position_time = 0;
int n_ = 0;

void OrderConditions() {

   datetime time_  = iTime(_Symbol,PERIOD_CURRENT, 0);
   if (time_<=last_position_time) {
      return;
   }

   // start new trend ?

    FVG htf_bullish_fvg, ctf_bullish_fvg, ltf_bullish_fvg;   
   bool is_htf_bullish_fvg = IsBullishFVG_Generic(htf_bullish_fvg,PERIOD_H4,0,false);  // not confirm fvg from higher timeframe (H1 or H4)
   bool is_ctf_bullish_fvg = IsBullishFVG_Generic(ctf_bullish_fvg,PERIOD_M5,0,false);  // not confirm fvg from current timeframe (m5 or m10)
   bool is_ltf_bullish_fvg_confirmed = IsBullishFVG_Generic(ltf_bullish_fvg,PERIOD_M1,1,false);  // confirmed fvg from m1

//   string str_ = StringFormat(" %s %s %s %i ", (string)is_htf_bullish_fvg, (string)is_ctf_bullish_fvg, (string)is_ltf_bullish_fvg_confirmed, n_);
//   ObjectSetString(0, labelLeftLower0, OBJPROP_TEXT, str_);
//
   //if (is_htf_bullish_fvg==true && is_ctf_bullish_fvg==true && is_ltf_bullish_fvg_confirmed==true) {
   //   n_ = n_ + 1;
   //   ObjectSetInteger(0, labelLeftLower0, OBJPROP_COLOR, clrYellow);
   //   Print("hi");
   //} else {
   //   ObjectSetInteger(0, labelLeftLower0, OBJPROP_COLOR, clrRed);
   //   return;
   //}


   // lower timeframe fvg confirmed + current timeframe idx_slope > 0.5
   
   if (is_ltf_bullish_fvg_confirmed==false) {
      return;
   }

   ADXCUSTOM_VALUES adxcustom_;
   iADXCUSTOMGet_Generic(adxcustom_);

   double adx_[];
   double diplus_[];
   double diminus_[];

   // reverse array first ?

   ArrayCopy(adx_, adxcustom_.adx_value);
   ArrayCopy(diplus_, adxcustom_.di_plus);
   ArrayCopy(diminus_, adxcustom_.di_minus);

   double adx_slope_=iADXCUSTOMGetSlope_Generic();


   // 0=no, 1=buy, 2=sell
   int adx_condition_state=0;

   // get adx_slope in onTimer ???
   // check crossup adx line -> move to HELPER

   if (adx_slope_ < 0.5 || adx_[0] < ADX_THRESHOLD) {
      adx_condition_state=0;
      return;
   }

   // - adx drossover
   if (adx_[1] < ADX_THRESHOLD && adx_[0] > ADX_THRESHOLD ) {
      if (diplus_[0] > diminus_[0] ) {
         // "BUY NOW 1 "
         adx_condition_state=1;
      } else {
         // SELL NOW 2 "
         adx_condition_state=2;
      }
   }

   // - while adx is over threshold
   if (adx_condition_state==0 && adx_[0] > ADX_THRESHOLD) {
      if (diplus_[1] > diplus_[0] && diminus_[1] < diminus_[0] && diplus_[0] < diminus_[0] && diplus_[1] > diminus_[1] ) {
         // "SELL NOW 3 "
         adx_condition_state=2;
      } else if ( diplus_[1] < diplus_[0] && diminus_[1] > diminus_[0] && diplus_[0] > diminus_[0] && diplus_[1] < diminus_[1] ) {
         // "BUY NOW 4 "
         adx_condition_state=1;
      }
   }

   if (adx_condition_state==0) {
      return;
   }


   int sell_total = SellTotal();
   int buy_total = BuyTotal();

   if (adx_condition_state==1 && buy_total<MAX_BUY_TOTAL_INT  ) {
      double atr_ = iATRGet_Generic(0);
      double lots_ = LotSize_Generic(POSITION_SIZE_DOUBLE);
      if (atr_<=0 || lots_<=0) {
         return;
      }

      Order_Generic(ORDER_TYPE_BUY, lots_, atr_, ATR_multiplier);

      // mark as this openprice alreay open new position
      last_position_time = iTime(_Symbol,PERIOD_CURRENT, 0);

      double code_=trade.ResultRetcode();
      //if (code_>0) {
      //   ClearStoSignalState();
      //}
      int err_ = GetLastError();
      if (err_>0) {
         Print(err_);
         return;
      }
      return;
   } else if (adx_condition_state==2 && sell_total<MAX_SELL_TOTAL_INT  ) {
      double atr_ = iATRGet_Generic(0);
      double lots_ = LotSize_Generic(POSITION_SIZE_DOUBLE);
      if (atr_<=0 || lots_<=0) {
         return;
      }

      Order_Generic(ORDER_TYPE_SELL, lots_, atr_, ATR_multiplier);

      last_position_time = iTime(_Symbol,PERIOD_CURRENT, 0);

      double code_=trade.ResultRetcode();
      //if (code_) {
      //   ClearStoSignalState();
      //}

      int err_ = GetLastError();
      if (err_>0) {
         Print(err_);
         return;
      }
      return;
   }

   return;



}

void UI() {

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                EA_STORSI_2EMA_V2.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "6.446"

#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

#include <_ICT6.2\HELPER.mqh>
#include <_ICT6.2\ANALYSER_HELPER.mqh>

CSymbolInfo m_symbol;

// INPUTS ...

input bool                                         USE_IS_NEW_BAR=false;
//input bool                                         TRADE_ONE_DIRECTION_BOOL=true;
input bool                                         ONE_WAY_TRADING_BOOL=true;
input ENUM_CONDITION_COMBO                         CONDITION_COMBO=CONDITION_COMBO_EMA_STO_ADX;

input double                                       POSITION_SIZE_DOUBLE=5;

input bool                                         HOLD_ON_WEEKEND_BOOL=false;
input bool                                         LIMIT_TRADE_TIME_BOOL=false;

input int                                          MAX_BUY_TOTAL_INT=1;
input int                                          MAX_SELL_TOTAL_INT=1;

//int            TIMER_UPDATE_INTERVAL_INT=10; // check every 5 secs


// DEPEND ON ASSET - 0.05 0.10
// ************************
// GOLD# 0.5 - 2.0
// GBPJPY# 0.002 - 0.003 --------- 0.001 - 0.005
// EMA_THRESHOLD=0.05; // EMA THRESHOLD GOLD(0.05-0.10)?
// =0.003;


// GOLD#          0.5   - 3.0 or 0.3 - 2.0
// GBPJPY#        0.001 - 0.005

input double                                       EMA_THRESHOLD=0.5;
input ENUM_ADX_THRESHOLD                           ADX_THRESHOLD=ADX_THRESHOLD20;
// 1.5 or 10 10 50
input double                                       ATR_multiplier=10;

// BIAS ( Filtering with Key Level ? )
// input bool                                         USE_KEYLEVEL_BOOL=true;

//// INTERNAL VARS
//double                           ATR_buffer[]; // array for the indicator iATR
//int                              ATR_handle;      // handle of the indicator iATR
//// bool                             AsSeries = true;
//
//
//// EMA
//double                        MA_buffer[];      // array for the indicator iMA
//int                           MA_handle;        // handle of the indicator iMA
//bool                          AsSeries = true;
//// Scalping: use shorter EMAs like 8/21 on M5
//input int                     EMA_LENGTH=21;// EMA_LENGTH (SCALPING: 21, SWING: 50)

//double                        STORSI_buffer[];
//int                           STORSI_handle;
//
//double                        STORSI_KEYLEVEL_buffer[];
//int                           STORSI_KEYLEVEL_handle;


//input ENUM_TIMEFRAMES                              STO_TIMEFRAME=PERIOD_M5;
// STORSI
// int KPeriod = 14;
//int KPeriod = 3;
// int KPeriod = 5;
// input int                                          KPeriodSelect=3; // KPeriod(1: "3", 2: "5", 3: "14")
input ENUM_STORSI_KLINE        KPeriodSelect=KPERIOD3;
//int DPeriod = 3;
//int RSI_Period = 14;
//double STORSI_OVER_BOUGHT = 80.0;
//double STORSI_OVER_SOLD  = 20.0;

datetime lastbar_timeopen=__DATETIME__; // IS NEW BAR, LOR_;
// FVG fvg = {FVG_NONE, 0, 0, __DATETIME__, 0};
STO_SIGNAL_STATE sto_signal_state_ = { STO_CROSS_NONE, 0};

long allows_account[]               = { 1,2,332463240,98377677 };

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

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

   CreateButton();

   // InitIndicatorAll( STO_TIMEFRAME, KPeriodSelect);
   InitIndicatorAll(true,true,true,true,KPeriodSelect);

   //EventSetTimer(TIMER_UPDATE_INTERVAL_INT);

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

   Comment("");

   //EventKillTimer();

   ObjectsDeleteAll(0);

   // https://www.mql5.com/en/forum/294751/page2
   // IndicatorRelease()
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick() {


   if(HOLD_ON_WEEKEND_BOOL==false && IsFridayNightSaturdaySunday()==true) {
      if(PositionsTotal() > 0) {
         PositionCloseAllV1();
      }
      return;
   }

   // if LIMIT_TRADE_TIME_BOOL is false - not run InTimeRange_Generic
   if(InTimeRange_Generic() == false && LIMIT_TRADE_TIME_BOOL==true ) {
      if(PositionsTotal() > 0) {
         PositionCloseAllV1();
      }
      return;
   }

   // if(IsNewBar(lastbar_timeopen)) {
   // OrderConditions();
   // }
   // bool confirmedBullishFVG = FVG_DetectBullishFVG();

   if (USE_IS_NEW_BAR==true) {
      if (IsNewBar(lastbar_timeopen)) {
         PRE_OrderCondition();
      }

   } else {
      PRE_OrderCondition();
   }

}
//+------------------------------------------------------------------+

datetime last_execute_time = 0;

void PRE_OrderCondition() {

   MqlTick tick;
   if (SymbolInfoTick(_Symbol, tick)==false) {
      return;
   }

   int secs_diff = (int)(tick.time-last_execute_time);
   //double minutes_diff = secs_diff / 60.0;

   // need m1 fvg confirming
   // 60 120 ?

   if (secs_diff>66) {
      last_execute_time=tick.time;
   } else {
      return;
   }

   // ENUM_TREND sto_signal = STO_DetectStochasticCross_Generic(); //_Symbol, PERIOD_M5 );

   //MqlTick tick;
   //if (SymbolInfoTick(_Symbol, tick)==false) {
   //   return;
   //}

   bool confirmedBullishFVG = FVG_DetectBullishFVG();
   bool confirmedBearighFVG = FVG_DetectBearishFVG();

   //int secs_diff = (int)(tick.time-sto_signal_state_.update_time_);
   //double minutes_diff = secs_diff / 60.0;

   // within 5 minutes m1 fvg should be occured - changed
   // within 10 minutes m1 fvg should be occured

   // open multiple positions ?


   //| ------------------------------------------------- ADX FILTERING ------------------------------------------------- |
   // TODO: OPEN BUY MULTIPLE POSITION/OPEN SELL MULTIPLE POSITION / EVERY TIME FOUND CONFIRM FVG IN M5 (TIME DIFF MUST > 5 MINS)
   // TODO: CLOSE POSITION WHEN STRONG TREND (ADX+STO) CHANGE DIRECTION


//   if (confirmedBullishFVG==true) {
//      OrderConditions(confirmedBullishFVG, confirmedBearighFVG);
//   }
//
//   if (confirmedBearighFVG==true) {
//      OrderConditions(confirmedBullishFVG, confirmedBearighFVG);
//   }

   if (confirmedBullishFVG==true || confirmedBearighFVG==true) {
      //if (USE_ADX==true) {
      //   OrderConditions(confirmedBullishFVG, confirmedBearighFVG,true);
      //} else {
      //   OrderConditions(confirmedBullishFVG, confirmedBearighFVG);
      //}
      OrderConditions(confirmedBullishFVG, confirmedBearighFVG);
   }

}

//// COMBO ?
//// IS VALID CONDITION
//// return  0 - NO ACTION, 1 - BUY, 2 - SELL
//int IsValidCondition() {
//
//   if (CONDITION_COMBO==CONDITION_COMBO_EMA_STO) {
//      ENUM_TREND ema_trend = EMA_DetectStrongTrend_Generic(EMA_THRESHOLD);
//      if (ema_trend==TREND_SIDEWAYS) {
//         return 0;
//      }
//      ENUM_TREND sto_signal = STO_DetectTrend_Generic();
//      if (sto_signal==TREND_SIDEWAYS) {
//         return 0;
//      }
//      if ( ema_trend==TREND_UPTREND && sto_signal==TREND_UPTREND) {
//         return 1;
//      } else if ( ema_trend==TREND_DOWNTREND && sto_signal==TREND_DOWNTREND) {
//         return 2;
//      }
//
//   } else if ( CONDITION_COMBO==CONDITION_COMBO_EMA_ADX ) {
//      ENUM_TREND ema_trend = EMA_DetectStrongTrend_Generic(EMA_THRESHOLD);
//      if (ema_trend==TREND_SIDEWAYS) {
//         return 0;
//      }
//      //ENUM_ADX_DIRECTION adx_direction=iADXGet();
//      ENUM_ADX_DIRECTION adx_direction=iADXGetDirection_Generic(ADX_THRESHOLD);
//      if (adx_direction==ADX_DIRECTION_NONE) {
//         return 0;
//      }
//      if (adx_direction==ADX_DIRECTION_BULLISH && ema_trend==TREND_UPTREND ) {
//         return 1;
//      } else if (adx_direction==ADX_DIRECTION_BEARISH && ema_trend==TREND_DOWNTREND) {
//         return 2;
//      }
//
//   } else if ( CONDITION_COMBO==CONDITION_COMBO_STO_ADX ) {
//      ENUM_TREND sto_signal = STO_DetectTrend_Generic();
//      if (sto_signal==TREND_SIDEWAYS) {
//         return 0;
//      }
//      //ENUM_ADX_DIRECTION adx_direction=iADXGet();
//      ENUM_ADX_DIRECTION adx_direction=iADXGetDirection_Generic(ADX_THRESHOLD);
//      if (adx_direction==ADX_DIRECTION_NONE) {
//         return 0;
//      }
//      if (adx_direction==ADX_DIRECTION_BULLISH && sto_signal==TREND_UPTREND) {
//         return 1;
//      } else if (adx_direction==ADX_DIRECTION_BEARISH && sto_signal==TREND_DOWNTREND) {
//         return 2;
//      }
//
//   } else if ( CONDITION_COMBO==CONDITION_COMBO_EMA_STO_ADX ) {
//      ENUM_TREND ema_trend = EMA_DetectStrongTrend_Generic(EMA_THRESHOLD);
//      if (ema_trend==TREND_SIDEWAYS) {
//         return 0;
//      }
//      ENUM_TREND sto_signal = STO_DetectTrend_Generic();
//      if (sto_signal==TREND_SIDEWAYS) {
//         return 0;
//      }
//      // ENUM_ADX_DIRECTION adx_direction=iADXGet();
//      ENUM_ADX_DIRECTION adx_direction=iADXGetDirection_Generic(ADX_THRESHOLD);
//      if (adx_direction==ADX_DIRECTION_NONE) {
//         return 0;
//      }
//      if (adx_direction==ADX_DIRECTION_BULLISH && ema_trend==TREND_UPTREND && sto_signal==TREND_UPTREND) {
//         return 1;
//      } else if (adx_direction==ADX_DIRECTION_BEARISH && ema_trend==TREND_DOWNTREND && sto_signal==TREND_DOWNTREND) {
//         return 2;
//      }
//   }
//
//   return 0;
//}

void OrderConditions(bool confirmedBullishFVG_, bool confirmedBearighFVG_) {

   int sell_total = SellTotal();
   int buy_total = BuyTotal();

   // int condition = IsValidCondition();
   int condition = IsValidCondition_Generic(CONDITION_COMBO,ADX_THRESHOLD,EMA_THRESHOLD);
   
   if (ONE_WAY_TRADING_BOOL==true && condition>0) {
      if (confirmedBullishFVG_==true && condition==1 && sell_total>0) {
         // close short position
         PositionCloseAll(POSITION_TYPE_SELL);
      }
      if (confirmedBearighFVG_==true && condition==2 && buy_total>0) {
         // close long position
         PositionCloseAll(POSITION_TYPE_BUY);
      }      
   } 

   // SIDEWAYS NO TRADE ?

   if (confirmedBullishFVG_==true && buy_total<MAX_BUY_TOTAL_INT && condition==1  ) {
      double atr_ = iATRGet_Generic(0);
      double lots_ = LotSize_Generic(POSITION_SIZE_DOUBLE);
      if (atr_<=0 || lots_<=0) {
         return;
      }      
      Order_Generic(ORDER_TYPE_BUY, lots_, atr_, ATR_multiplier);

      //if (trade.ResultRetcode()>0) {
      //   ClearStoSignalState();
      //}

      int err_ = GetLastError();
      if (err_>0) {
         Print(err_);
         return;
      }      
   } else if ( confirmedBearighFVG_==true && sell_total<MAX_SELL_TOTAL_INT &&  condition==2) {
      double atr_ = iATRGet_Generic(0);
      double lots_ = LotSize_Generic(POSITION_SIZE_DOUBLE);
      if (atr_<=0 || lots_<=0) {
         return;
      }

      Order_Generic(ORDER_TYPE_SELL, lots_, atr_, ATR_multiplier);

      //if (trade.ResultRetcode()) {
      //   ClearStoSignalState();
      //}

      int err_ = GetLastError();
      if (err_>0) {
         Print(err_);
         return;
      }
   }

}


////+------------------------------------------------------------------+
////|                           TREND                                  |
////+------------------------------------------------------------------+
//ENUM_TREND DetectTrendByEMA(double &slp,string symbol, ENUM_TIMEFRAMES tf, int emaPeriod, double threshold = 0.0003) {
//   return DetectTrendByEMAGeneric(slp, _Symbol, tf, emaPeriod, threshold );
//}

//double iMAGet(const int index) {
//   return iMAGet_Generic(index);
//}
//+------------------------------------------------------------------+


//// | STORSI GET |
//// %K line (fast-moving) - BLUE
//// %D line (signal line) - ORANGE
//double iSTORSI_KLINEGet(int shift=0) {   
//   return iSTORSI_KLINEGet_Generic(shift);
//}

//// L LINE = SIGNAL LINE = ORANGE ?
//double iSTORSI_DLINEGet(int shift=0) {   
//   return iSTORSI_DLINEGet_Generic(shift);
//}

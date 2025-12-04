//+------------------------------------------------------------------+
//|                                                     EA_COMBO.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "666.666"

#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

#include <_ICT6.2\HELPER.mqh>
#include <_ICT6.2\ANALYSER_HELPER.mqh>

CSymbolInfo m_symbol;

// INPUTS ...

input bool                                         USE_IS_NEW_BAR=false;
input ENUM_CONDITION_COMBO                         CONDITION_COMBO=CONDITION_COMBO_EMA_STO_ADX;

// optimize this
//input ENUM_TIMEFRAMES                              STO_TIMEFRAME=PERIOD_M5;
input double                                       POSITION_SIZE_DOUBLE=1;

// input ENUM_TIMEFRAMES                              STORSI_TIMEFRAME=PERIOD_M5;
// input ENUM_TIMEFRAMES                              STORSI_KEYLEVEL_TIMEFRAME=PERIOD_D1;

input bool                                         HOLD_ON_WEEKEND_BOOL=false;
input bool                                         LIMIT_TRADE_TIME_BOOL=true;

input int                                          MAX_BUY_TOTAL_INT=10;
input int                                          MAX_SELL_TOTAL_INT=10;

int            TIMER_UPDATE_INTERVAL_INT=10; // check every 5 secs



// DEPEND ON ASSET - 0.05 0.10
// ************************
// GOLD# 0.5 - 2.0
// GBPJPY# 0.002 - 0.003 --------- 0.001 - 0.005
// EMA_THRESHOLD=0.05; // EMA THRESHOLD GOLD(0.05-0.10)?
// =0.003;


// GOLD#          0.5   - 3.0
// GBPJPY#        0.001 - 0.005

input double                                       EMA_THRESHOLD=0.5;
input ENUM_ADX_THRESHOLD                           ADX_THRESHOLD=ADX_THRESHOLD20;
input double                                       ATR_multiplier=1.5;

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

   EventKillTimer();

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

// COMBO ?
// IS VALID CONDITION
// return  0 - NO ACTION, 1 - BUY, 2 - SELL
int IsValidCondition() {

   if (CONDITION_COMBO==CONDITION_COMBO_EMA_STO) {
      ENUM_TREND ema_trend = EMA_DetectStrongTrend_Generic(EMA_THRESHOLD);
      if (ema_trend==TREND_SIDEWAYS) {
         return 0;
      }
      ENUM_TREND sto_signal = STO_DetectTrend_Generic();
      if (sto_signal==TREND_SIDEWAYS) {
         return 0;
      }
      if ( ema_trend==TREND_UPTREND && sto_signal==TREND_UPTREND) {
         return 1;
      } else if ( ema_trend==TREND_DOWNTREND && sto_signal==TREND_DOWNTREND) {
         return 2;
      }

   } else if ( CONDITION_COMBO==CONDITION_COMBO_EMA_ADX ) {
      ENUM_TREND ema_trend = EMA_DetectStrongTrend_Generic(EMA_THRESHOLD);
      if (ema_trend==TREND_SIDEWAYS) {
         return 0;
      }
      //ENUM_ADX_DIRECTION adx_direction=iADXGet();
      ENUM_ADX_DIRECTION adx_direction=iADXGetDirection_Generic(ADX_THRESHOLD);
      if (adx_direction==ADX_DIRECTION_NONE) {
         return 0;
      }
      if (adx_direction==ADX_DIRECTION_BULLISH && ema_trend==TREND_UPTREND ) {
         return 1;
      } else if (adx_direction==ADX_DIRECTION_BEARISH && ema_trend==TREND_DOWNTREND) {
         return 2;
      }

   } else if ( CONDITION_COMBO==CONDITION_COMBO_STO_ADX ) {
      ENUM_TREND sto_signal = STO_DetectTrend_Generic();
      if (sto_signal==TREND_SIDEWAYS) {
         return 0;
      }
      //ENUM_ADX_DIRECTION adx_direction=iADXGet();
      ENUM_ADX_DIRECTION adx_direction=iADXGetDirection_Generic(ADX_THRESHOLD);
      if (adx_direction==ADX_DIRECTION_NONE) {
         return 0;
      }
      if (adx_direction==ADX_DIRECTION_BULLISH && sto_signal==TREND_UPTREND) {
         return 1;
      } else if (adx_direction==ADX_DIRECTION_BEARISH && sto_signal==TREND_DOWNTREND) {
         return 2;
      }

   } else if ( CONDITION_COMBO==CONDITION_COMBO_EMA_STO_ADX ) {
      ENUM_TREND ema_trend = EMA_DetectStrongTrend_Generic(EMA_THRESHOLD);
      if (ema_trend==TREND_SIDEWAYS) {
         return 0;
      }
      ENUM_TREND sto_signal = STO_DetectTrend_Generic();
      if (sto_signal==TREND_SIDEWAYS) {
         return 0;
      }
      // ENUM_ADX_DIRECTION adx_direction=iADXGet();
      ENUM_ADX_DIRECTION adx_direction=iADXGetDirection_Generic(ADX_THRESHOLD);
      if (adx_direction==ADX_DIRECTION_NONE) {
         return 0;
      }
      if (adx_direction==ADX_DIRECTION_BULLISH && ema_trend==TREND_UPTREND && sto_signal==TREND_UPTREND) {
         return 1;
      } else if (adx_direction==ADX_DIRECTION_BEARISH && ema_trend==TREND_DOWNTREND && sto_signal==TREND_DOWNTREND) {
         return 2;
      }
   }

   return 0;
}

void OrderConditions(bool confirmedBullishFVG_, bool confirmedBearighFVG_) {

   int sell_total = SellTotal();
   int buy_total = BuyTotal();

   int condition = IsValidCondition();

   // SIDEWAYS NO TRADE ?

   // if ( adx_direction==ADX_DIRECTION_BULLISH && ema_trend==TREND_UPTREND && sto_signal==TREND_UPTREND && buy_total<MAX_BUY_TOTAL_INT && confirmedBullishFVG_==true ) {
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

      // } else if( ema_trend==TREND_DOWNTREND && sto_signal==TREND_DOWNTREND && buy_total<MAX_SELL_TOTAL_INT ) { <---------------- ? WHAT IS BUGS ?
      // } else if( adx_direction==ADX_DIRECTION_BEARISH && ema_trend==TREND_DOWNTREND && sto_signal==TREND_DOWNTREND && sell_total<MAX_SELL_TOTAL_INT && confirmedBearighFVG_==true ) {
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


//void OrderConditions_1(bool confirmedBullishFVG_=false, bool confirmedBearighFVG_=false) {
//
//   int sell_total = SellTotal();
//   int buy_total = BuyTotal();
//
//   // double slope = 0;
//
//   ENUM_TREND ema_trend = EMA_DetectStrongTrend_Generic(EMA_THRESHOLD); //  DetectTrendByEMA(slope, _Symbol, PERIOD_M5, 21, EMA_THRESHOLD);    // FOR SCALPING TRADE
//   Print("EMA: ", EnumToString(ema_trend));
//   if (ema_trend==TREND_SIDEWAYS) {
//      return;
//   }
//
//   ENUM_TREND sto_signal = STO_DetectTrend_Generic(); // DetectStochasticCross(_Symbol, PERIOD_M5 ); // PERIOD_M15);
//   Print("STO: ", EnumToString(sto_signal));
//   if (sto_signal==TREND_SIDEWAYS) {
//      return;
//   }
//
//   // string str_ = StringFormat("ema: %s sto: %s slope: %f",  EnumToString(ema_trend), EnumToString(sto_signal), slope );
//   // ObjectSetString(0, buttonEmaThreadhold, OBJPROP_TEXT, str_);
//
//   // SIDEWAYS NO TRADE ?
//
//   if ( ema_trend==TREND_UPTREND && sto_signal==TREND_UPTREND && buy_total<MAX_BUY_TOTAL_INT && confirmedBullishFVG_==true ) {
//      double atr_ = iATRGet_Generic(0);
//      double lots_ = LotSize_Generic(POSITION_SIZE_DOUBLE);
//      if (atr_<=0 || lots_<=0) {
//         return;
//      }
//
//      Order_Generic(ORDER_TYPE_BUY, lots_, atr_, ATR_multiplier);
//
//      //if (trade.ResultRetcode()>0) {
//      //   ClearStoSignalState();
//      //}
//
//      int err_ = GetLastError();
//      if (err_>0) {
//         Print(err_);
//         return;
//      }
//
//      // } else if( ema_trend==TREND_DOWNTREND && sto_signal==TREND_DOWNTREND && buy_total<MAX_SELL_TOTAL_INT ) { <---------------- ? WHAT IS BUGS ?
//   } else if( ema_trend==TREND_DOWNTREND && sto_signal==TREND_DOWNTREND && sell_total<MAX_SELL_TOTAL_INT && confirmedBearighFVG_==true ) {
//      double atr_ = iATRGet_Generic(0);
//      double lots_ = LotSize_Generic(POSITION_SIZE_DOUBLE);
//      if (atr_<=0 || lots_<=0) {
//         return;
//      }
//
//      Order_Generic(ORDER_TYPE_SELL, lots_, atr_, ATR_multiplier);
//
//      //if (trade.ResultRetcode()) {
//      //   ClearStoSignalState();
//      //}
//
//      int err_ = GetLastError();
//      if (err_>0) {
//         Print(err_);
//         return;
//      }
//   }
//
//}

//void OrderConditions_2(bool confirmedBullishFVG_, bool confirmedBearighFVG_, bool useADX) {
//
//   int sell_total = SellTotal();
//   int buy_total = BuyTotal();
//
//   // double slope = 0;
//
//   ENUM_TREND ema_trend = EMA_DetectStrongTrend_Generic(EMA_THRESHOLD); //  DetectTrendByEMA(slope, _Symbol, PERIOD_M5, 21, EMA_THRESHOLD);    // FOR SCALPING TRADE
//   Print("EMA: ", EnumToString(ema_trend));
//   if (ema_trend==TREND_SIDEWAYS) {
//      return;
//   }
//
//   ENUM_TREND sto_signal = STO_DetectTrend_Generic(); // DetectStochasticCross(_Symbol, PERIOD_M5 ); // PERIOD_M15);
//   Print("STO: ", EnumToString(sto_signal));
//   if (sto_signal==TREND_SIDEWAYS) {
//      return;
//   }
//
//   ENUM_ADX_DIRECTION adx_direction=iADXGet();
//
//   // SIDEWAYS NO TRADE ?
//
//   if ( adx_direction==ADX_DIRECTION_BULLISH && ema_trend==TREND_UPTREND && sto_signal==TREND_UPTREND && buy_total<MAX_BUY_TOTAL_INT && confirmedBullishFVG_==true ) {
//      double atr_ = iATRGet_Generic(0);
//      double lots_ = LotSize_Generic(POSITION_SIZE_DOUBLE);
//      if (atr_<=0 || lots_<=0) {
//         return;
//      }
//
//      Order_Generic(ORDER_TYPE_BUY, lots_, atr_, ATR_multiplier);
//
//      //if (trade.ResultRetcode()>0) {
//      //   ClearStoSignalState();
//      //}
//
//      int err_ = GetLastError();
//      if (err_>0) {
//         Print(err_);
//         return;
//      }
//
//      // } else if( ema_trend==TREND_DOWNTREND && sto_signal==TREND_DOWNTREND && buy_total<MAX_SELL_TOTAL_INT ) { <---------------- ? WHAT IS BUGS ?
//   } else if( adx_direction==ADX_DIRECTION_BEARISH && ema_trend==TREND_DOWNTREND && sto_signal==TREND_DOWNTREND && sell_total<MAX_SELL_TOTAL_INT && confirmedBearighFVG_==true ) {
//      double atr_ = iATRGet_Generic(0);
//      double lots_ = LotSize_Generic(POSITION_SIZE_DOUBLE);
//      if (atr_<=0 || lots_<=0) {
//         return;
//      }
//
//      Order_Generic(ORDER_TYPE_SELL, lots_, atr_, ATR_multiplier);
//
//      //if (trade.ResultRetcode()) {
//      //   ClearStoSignalState();
//      //}
//
//      int err_ = GetLastError();
//      if (err_>0) {
//         Print(err_);
//         return;
//      }
//   }
//
//}

//// CHECK ADX DI+ DI- 
//ENUM_ADX_DIRECTION iADXGet() {
//
//   ADXCUSTOM_VALUES adxcustom_;
//   iADXCUSTOMGet_Generic(adxcustom_,1);
//
//   double adx_[];
//   double diplus_[];
//   double diminus_[];
//   ArrayCopy(adx_, adxcustom_.adx_value);
//   ArrayCopy(diplus_, adxcustom_.di_plus);
//   ArrayCopy(diminus_, adxcustom_.di_minus);
//
//   // 0=no, 1=buy, 2=sell
//   //int condition_state=0;
//   
//   // add slope must > 0.5   
//   double adx_slope_=iADXCUSTOMGetSlope_Generic();   
//   if (adx_slope_ < 0.5 || adx_[0] < ADX_THRESHOLD) {    
//      return ADX_DIRECTION_NONE;
//   }
//   
//   // WRONG ?
//   if ( diplus_[0] > diminus_[0] ) {
//      return ADX_DIRECTION_BULLISH;
//   } else if ( diplus_[0] < diminus_[0] ) {
//      return ADX_DIRECTION_BEARISH;
//   }
//
//   return ADX_DIRECTION_NONE;
//
////   // - adx drossover
////   if (adx_[1] < ADX_THRESHOLD && adx_[0] > ADX_THRESHOLD ) {
////      if (diplus_[0] > diminus_[0] ) {
////         // "BUY NOW 1 "
////         condition_state=1;
////         return ADX_DIRECTION_BULLISH;
////      } else {
////         // SELL NOW 2 "
////         condition_state=2;
////         return ADX_DIRECTION_BEARISH;
////      }
////   }
////
////   // - while adx is over threshold
////   if (condition_state==0 && adx_[0] > ADX_THRESHOLD) {
////      if (diplus_[1] > diplus_[0] && diminus_[1] < diminus_[0] && diplus_[0] < diminus_[0] && diplus_[1] > diminus_[1] ) {
////         // "SELL NOW 3 "
////         condition_state=2;
////         return ADX_DIRECTION_BEARISH;
////      } else if ( diplus_[1] < diplus_[0] && diminus_[1] > diminus_[0] && diplus_[0] > diminus_[0] && diplus_[1] < diminus_[1] ) {
////         // "BUY NOW 4 "
////         condition_state=1;
////         return ADX_DIRECTION_BULLISH;
////      }
////   }
////
////   if (condition_state==0) {
////      return ADX_DIRECTION_NONE;
////   }
////   return ADX_DIRECTION_NONE;
//}


//// GENERIC LOT SIZE CALCULATION
//double LotSize_() {
//
//
//// US30Cash
//   string sym_name = _Symbol;
//   if(StringToUpper(sym_name)) {
//
//// BALANCE 10000
//// GOLD                 -> ? 1 lots(winrate > 90% ?)
//// BTCUSD               -> 4 - 5 LOTS
//// US30CASH US100CASH   -> 1 - 2 LOTS
//
//      if (sym_name=="US30CASH" || sym_name=="US100CASH" || sym_name=="BTCUSD#" ) {
//         return POSITION_SIZE_DOUBLE;
//      }
//
//   }
//
//// #ifdef not DEBUG
//   if(SYMBOL_VOLUME_MIN_ < 0.1) {
//      return POSITION_SIZE_DOUBLE;
//   } else {
//      return SYMBOL_VOLUME_MIN_;
//   }
////#endif
//
//   double percentage_to_lose = 5; //   SELL_BU sell_buy_percent;
//// double entry_price, double stop_loss_price, double percentage_to_lose
//
//// Get Symbol Info
//   double lots_maximum = SYMBOL_VOLUME_MAX_; // SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
//   double lots_minimum = SYMBOL_VOLUME_MIN_; // SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
//   double volume_step = SYMBOL_VOLUME_STEP_; // SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
//   double tick_size = SYMBOL_TRADE_TICK_SIZE_; // SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
//   double tick_value = SYMBOL_TRADE_TICK_VALUE_; // SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
//
//// Get trade basic info
//   double available_capital = fmin(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)), AccountInfoDouble(ACCOUNT_MARGIN_FREE));
//   double amount_to_risk = available_capital * percentage_to_lose / 100;
//
//// double sl_distance = MathAbs(entry_price - stop_loss_price); // Get the Abs since it might be a short (EP < SL)
//// ATR ?
//// XX ONDEMAND ATR?
//
//   double sl_distance = 100/_Point; // fvg.atr_ * 1; //ATR_multiplier;
//
//// Calculate steps and lots
//   double money_step = sl_distance / tick_size * tick_value * volume_step;
//   double lots = fmin(lots_maximum, fmax(lots_minimum, NormalizeDouble(amount_to_risk / money_step * volume_step, 2)));
//// The number 2 is due to my brokers volume step, depends on the currency pair
//// double normal_lots = NormalizeDouble(lots, 2);
//
//// https://www.mql5.com/en/forum/189533
////double normal_lots = ((int)MathFloor(lots * 100)) / 100;
//   int lot_digits = 3;
//   if(lots_minimum == 0.001)
//      lot_digits = 3;
//   if(lots_minimum == 0.01)
//      lot_digits = 2;
//   if(lots_minimum == 0.1)
//      lot_digits = 1;
//
//   double double_lots_ = lots * 100;
//   int int_lots_ = (int)double_lots_;
//   double normal_lots_ = (double)int_lots_ / 100;
//   double real_lots = NormalizeDouble(normal_lots_, lot_digits);
//
//   if(real_lots < 0.01) {
//      return 0.01;
//   }
//
//   return(real_lots);
//}


//+------------------------------------------------------------------+
//| Detect Trend: Returns "Uptrend", "Downtrend", or "Sideways"      |
//+------------------------------------------------------------------+

//Scalping: use shorter EMAs like 8/21 on M5
//Swing trading: use 20/50 or 50/200 on H1 or H4

//+------------------------------------------------------------------+
//|                           TREND                                  |
//+------------------------------------------------------------------+
ENUM_TREND DetectTrendByEMA(double &slp,
                            string symbol, ENUM_TIMEFRAMES tf, int emaPeriod, double threshold = 0.0003) {
//   double emaNow = iMAGet(0); // iMA(symbol, tf, emaPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
//   double emaPrev = iMAGet(1); // iMA(symbol, tf, emaPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
//   double price = iClose(symbol, tf, 0);
//
//   double slope = emaNow - emaPrev;
//   double priceDistance = MathAbs(price - emaNow);
//
//   //PrintFormat(" slope: %f price_distance: %f ", slope, priceDistance);
//   Print("");
//   PrintFormat(" slope: %f ", slope);
//   slp = slope;
//
//   if (price > emaNow && slope > threshold)
//      return TREND_UPTREND; // "Uptrend";
//
//   if (price < emaNow && slope < -threshold)
//      return TREND_DOWNTREND; // "Downtrend";
//
//   return TREND_SIDEWAYS; //"Sideways";
   return DetectTrendByEMAGeneric(slp, _Symbol, tf, emaPeriod, threshold );
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//double iMAGet(const int index) {
//   double MA[1];
//   ResetLastError();
//   if(CopyBuffer(MA_handle, 0, index, 1, MA_buffer) < 0) {
//      int err_ = GetLastError();
//      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
//   } else {
//      return MA_buffer[0];
//   }
//
//// ZeroMemory(MA_buffer);
////   ResetLastError();
//
//   return -1;
//}
double iMAGet(const int index) {
   // return iMAGet(MA_buffer, MA_handle, index);
   return iMAGet_Generic(index);
}
//+------------------------------------------------------------------+


// | STORSI GET |
// %K line (fast-moving) - BLUE
// %D line (signal line) - ORANGE
double iSTORSI_KLINEGet(int shift=0) {
   //ResetLastError();
   //int res=CopyBuffer(STORSI_handle,0,shift,1, STORSI_buffer);
   //if(res<0) {
   //   PrintFormat("Failed to copy data from the iRSI indicator, error code %d",GetLastError());
   //   return(0.0);
   //}
   //return(STORSI_buffer[0]);
   return iSTORSI_KLINEGet_Generic(shift);
}

// L LINE = SIGNAL LINE = ORANGE ?
double iSTORSI_DLINEGet(int shift=0) {
   //ResetLastError();
   //int res=CopyBuffer(STORSI_handle,1,shift,1, STORSI_buffer);
   //if(res<0) {
   //   PrintFormat("Failed to copy data from the iRSI indicator, error code %d",GetLastError());
   //   return(0.0);
   //}
   //return(STORSI_buffer[0]);
   return iSTORSI_DLINEGet_Generic(shift);
}

//// FOR KEYLEVEL
//double iSTORSI_KEYLEVEL_KLINEGet(int shift=0) {
//   //ResetLastError();
//   //int res=CopyBuffer(STORSI_KEYLEVEL_handle,0,shift,1, STORSI_KEYLEVEL_buffer);
//   //if(res<0) {
//   //   PrintFormat("_KEYLEVEL Failed to copy data from the iRSI indicator, error code %d",GetLastError());
//   //   return(0.0);
//   //}
//   //return(STORSI_KEYLEVEL_buffer[0]);
//   return iSTORSI_KEYLEVEL_KLINEGet_Generic(shift);
//}
//// L LINE = SIGNAL LINE = ORANGE ?
//double iSTORSI_KEYLEVEL_DLINEGet(int shift=0) {
//   //ResetLastError();
//   //int res=CopyBuffer(STORSI_KEYLEVEL_handle,1,shift,1, STORSI_KEYLEVEL_buffer);
//   //if(res<0) {
//   //   PrintFormat("_KEYLEVEL Failed to copy data from the iRSI indicator, error code %d",GetLastError());
//   //   return(0.0);
//   //}
//   //return(STORSI_KEYLEVEL_buffer[0]);
//   return iSTORSI_KEYLEVEL_DLINEGet_Generic(shift);
//}

//// FOR ENTRY .................
////+------------------------------------------------------------------+
////| Detects Stochastic K and D line cross                           |
////| Returns: 1 = Bullish Cross (K crosses above D)                  |
////|         -1 = Bearish Cross (K crosses below D)                  |
////|          0 = No cross                                           |
////+------------------------------------------------------------------+
//ENUM_TREND DetectStochasticCross(string symbol, ENUM_TIMEFRAMES tf, int kPeriod = 14, int dPeriod = 3, int slowing = 3) {
//   double kCurrent = iSTORSI_KLINEGet(0); // iStochastic(symbol, tf, kPeriod, dPeriod, slowing, MODE_SMA, 0, MODE_MAIN, 0);
//   double dCurrent = iSTORSI_DLINEGet(0); // iStochastic(symbol, tf, kPeriod, dPeriod, slowing, MODE_SMA, 0, MODE_SIGNAL, 0);
//
//   double kPrevious = iSTORSI_KLINEGet(1); // iStochastic(symbol, tf, kPeriod, dPeriod, slowing, MODE_SMA, 0, MODE_MAIN, 1);
//   double dPrevious = iSTORSI_DLINEGet(1); // iStochastic(symbol, tf, kPeriod, dPeriod, slowing, MODE_SMA, 0, MODE_SIGNAL, 1);
//
//   if (kPrevious < dPrevious && kCurrent > dCurrent) {
//      // return 1; // Bullish cross
//      return TREND_UPTREND;
//   }
//
//   if (kPrevious > dPrevious && kCurrent < dCurrent) {
//      // return -1; // Bearish cross
//      return TREND_DOWNTREND;
//   }
//
//   // return 0; // No cross
//   return TREND_SIDEWAYS;
//}

//+------------------------------------------------------------------+

//// BIAS WITH KEYLEVEL TIMEFRAME
//// ENUM_TREND DetectKeylevelStochasticTrend(ENUM_TIMEFRAMES tf=PERIOD_D1, int kPeriod = 14, int dPeriod = 3, int slowing = 3) {
//ENUM_TREND DetectKeylevelStochasticTrend() {
////   double kCurrent = iSTORSI_KEYLEVEL_KLINEGet(0); // iStochastic(symbol, tf, kPeriod, dPeriod, slowing, MODE_SMA, 0, MODE_MAIN, 0);
////   double dCurrent = iSTORSI_KEYLEVEL_DLINEGet(0); // iStochastic(symbol, tf, kPeriod, dPeriod, slowing, MODE_SMA, 0, MODE_SIGNAL, 0);
////
////   if (kCurrent > dCurrent) {
////      return TREND_UPTREND;
////   }
////
////   if (kCurrent < dCurrent) {
////      return TREND_DOWNTREND;
////   }
////
////   return TREND_SIDEWAYS;
//   // DetectKeylevelStochasticTrend_Generic
//   return KeyLevelTrend();
//}

////+------------------------------------------------------------------+
////|                                                                  |
////+------------------------------------------------------------------+
//double iATRGet(int shift=0) {
////   // int index = ATR_shift;
////   double ATR[1];
////   ResetLastError();
////   if(CopyBuffer(ATR_handle, 0, shift, 1, ATR_buffer) < 0) {
////      int err_ = GetLastError();
////      PrintFormat("Failed to copy data from the iATR indicator, error code %d",GetLastError());
////   } else {
////      // fvg.atr_ = ATR_buffer[0];
////      return(ATR_buffer[0]);
////   }
////// ObjectSetString(0, buttonATR, OBJPROP_TEXT, StringFormat("ATR: %.3f", NormalizeDouble(fvg.atr_, _Digits)));
////   return 0;
//   return iATRGet_Generic(shift);
//}
//+------------------------------------------------------------------+

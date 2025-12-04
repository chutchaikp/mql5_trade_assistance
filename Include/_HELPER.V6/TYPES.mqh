//+------------------------------------------------------------------+
//|                                                        TYPES.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link "https://www.mql5.com"

// OPTIONCOMBO

//-- option 1
//ema_trend
//sto_signal
//
//-- option 2
//ema_trend
//adx_direction
//
//-- option 3
//sto_signal
//adx_direction
//
//-- option 4
//ema_trend
//sto_signal
//adx_direction

// NORMALIZE SLOPE
/*enum ENUM_EMA_SET {
   EMA_SET_8_21                   =1,
   EMA_SET_20_50                  =2
};*/

// (1.272 or 1.618)
enum ENUM_TP_OPTION {
   TP_OPTION_FIBONACCI_1272          =1, // TP with FIBO 1.272
   TP_OPTION_FIBONACCI_1618          =2, // TP with FIBO 1.618
   TP_OPTION_ATR                     =3  // TP with ATR*multiplier
};

enum ENUM_CONDITION_COMBO {
   CONDITION_COMBO_EMA_STO                =1,      // EMA+STO
   CONDITION_COMBO_EMA_ADX                =2,      // EMA+ADX
   CONDITION_COMBO_STO_ADX                =3,      // STO+ADX
   CONDITION_COMBO_EMA_STO_ADX            =4       // EMA+STO+ADX 
   
   //,      // EMA+STO+ADX   
   //// TODO:
   //CONDITION_COMBO_EMA_STO_FIBONACCI       =5,     // EMA+STO+FIBONACCI
   //CONDITION_COMBO_EMA_ADX_FIBONACCI       =6,     // EMA+ADX+FIBONACCI
   //CONDITION_COMBO_STO_ADX_FIBONACCI       =7,     // STO+ADX+FIBONACCI
   //CONDITION_COMBO_EMA_STO_ADX_FIBONACCI   =8      // EMA+STO+ADX+FIBONACCI
};

enum ENUM_STO_CROSS {
   STO_CROSS_NONE       = 0,     // No cross
   STO_CROSS_UP         = 0x1,   // Crossup
   STO_CROSS_DOWN       = 0x2    // Crossdown
};

enum ENUM_TREND {
   TREND_SIDEWAYS          = 0,
   TREND_UPTREND           = 0x1,
   TREND_DOWNTREND         = 0x2
};

enum ENUM_CANDLESTICK {
   CANDLESTICK_NOWARD,
   CANDLESTICK_UPWARD,
   CANDLESTICK_DOWNWARD,
};

enum ENUM_STORSI_KLINE {
   KPERIOD3             =3,    // Kline is 3
   KPERIOD5             =5,    // Kline is 5
   KPERIOD14            =14    // Kline is 14
};

enum ENUM_STORSI_LINE {
   NOLINE          = 0,
   KLINE           = 0x1,
   DLINE           = 0x2
};

enum ENUM_ADX_THRESHOLD {
   ADX_THRESHOLD20      =20,
   ADX_THRESHOLD25      =25,
   ADX_THRESHOLD30      =30
};

enum ENUM_ADX_DIRECTION {
   ADX_DIRECTION_NONE             =0,
   ADX_DIRECTION_BULLISH          =1,
   ADX_DIRECTION_BEARISH          =2
};

enum ENUM_FVGS {
   FVG_NONE       = 0,
   FVG_BULLISH    = 0x1,
   FVG_BEARISH    = 0x2
};

// time usage
//datetime currentTime = TimeCurrent();
//Print("Current server time: ", TimeToString(currentTime, TIME_DATE | TIME_SECONDS));

//double adx     = adxBuffer[0];
//  double plusDI  = plusDIBuffer[0];
//  double minusDI = minusDIBuffer[0];

 struct CONDITION_INFO {
   double            ema_slope;
   double            adx_slope;
   
   double            current_price;
   double            vwap_value;
   double            vwap_is_over_price;
 };

struct ADX_VALUES {
   double            adx_value_0;
   double            adx_value_1;
   double            adx_value_2;
   double            di_plus;
   double            di_minus;
};

struct ADXCUSTOM_VALUES {
   double            adx_value[];
   double            di_plus[];
   double            di_minus[];
};

struct STO_SIGNAL_STATE {
   ENUM_STO_CROSS    cross_type_;
   datetime          cross_time_;
   datetime          update_time_;
   int               wait_state_;
};

struct ANALYSER_FVG_RSI {
   int            type_; // ENUM_FVGS
   double         top_;
   double         bottom_;
   datetime       time_;
   double         major_sl_; // for update sl - trailing stop.
   double         atr_;

   int            last_fvg_type_;      // ENUM_FVGS
   datetime       last_fvg_time_; //

   double         rsi_0;
   double         rsi_1;

   string            last_rsi_over_under;       // ENUM_RSIS_OVER_UNDER
   datetime       last_rsi_over_under_time;
};

struct FVG {
   int               type_; // ENUM_FVGS
   double            top_;
   double            bottom_;
   datetime          time_;
   double            atr_;

   ENUM_FVGS         rsi_significance_state_;
   ENUM_FVGS         storsi_significance_state_;

   // STORSI ?
   double            storsi_kline_prev_;
   double            storsi_dline_prev_;

   ENUM_STORSI_LINE  storsi_kline_dline_is_above_prev_;
};



//enum ENUM_FVGS
//{
//   FVG_NONE       = 0,
//   FVG_BULLISH    = 0x1,
//   FVG_BEARISH    = 0x2
//};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FvgTypeToString(int type_) {
   if (type_ == FVG_NONE) {
      return "NONE";
   } else if (type_ == FVG_BULLISH) {
      return "BULL";
   } else {
      return "BEAR";
   }
}

enum ENUM_RSIS {
   RSI_NONE          =0,
   RSI_OVERBOUGHT    =0x1,
   RSI_OVERSOLD      =0x2
};
//+------------------------------------------------------------------+

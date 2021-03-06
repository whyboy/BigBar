//+------------------------------------------------------------------+
//|                                                Beginners RSI.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

input int InpRSIPeriods = 14;
input ENUM_APPLIED_PRICE InpRSIPrice = PRICE_CLOSE;

input double InpOversoldLevel = 20.0;
input double InpOverboughtLevel = 80.0;


input double InpTakeProfit = 0.01;
input double InpStopLoss = 0.01;


input double InpOrderSize = 0.01;
input string InpTradeComment = "Beginners RSI";
input int InpMagicNumber = 212121;



int OnInit()
  {
  
   ENUM_INIT_RETCODE result = INIT_SUCCEEDED;
   
   result = CheckInput();
   
   if (result != INIT_SUCCEEDED) return result;
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  
  
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
      static bool oversold = false;
      static bool overbought = false;
      if (!NewBar()) return;
      
      double rsi = iRSI(Symbol(), Period(), InpRSIPeriods, InpRSIPrice, 1);
      double direction = iClose(Symbol(), Period(),1)-iOpen(Symbol(), Period(), 1);
      if(rsi > 50)
      {
         oversold = false;
      }
      if (rsi < 50)
      {
         overbought = false;
      }
      
      if (rsi > InpOverboughtLevel) overbought = true;
      if (rsi < InpOversoldLevel) oversold = true;
      
      int ticket = 0;
      if (oversold && (rsi > InpOversoldLevel) && direction > 0)
      {
         ticket = OrderOpen(ORDER_TYPE_BUY, InpStopLoss, InpTakeProfit);
         oversold = false;
      }
      if (overbought && (rsi < InpOverboughtLevel) && direction < 0)
      {
         ticket = OrderOpen(ORDER_TYPE_SELL, InpStopLoss, InpTakeProfit);
         overbought = false;
      }
      
      return;
   
  }


 

//+------------------------------------------------------------------+

ENUM_INIT_RETCODE CheckInput()
{
   if (InpRSIPeriods<=0) return INIT_PARAMETERS_INCORRECT;
   return INIT_SUCCEEDED;
}

bool NewBar()
{
   datetime currentTime = iTime(Symbol(), Period(), 0);
   static datetime priorTime = currentTime;
   bool result = (currentTime != priorTime);
   priorTime = currentTime;
   return result;
}


int OrderOpen(ENUM_ORDER_TYPE orderType, double stopLoss, double takeProfit)
{
   int ticket;
   double openPrice;
   double stopLossPrice;
   double takeProfitPrice;
   
   if (orderType == ORDER_TYPE_BUY)
   {
      openPrice = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits());
      stopLossPrice = (stopLoss == 0.0) ? 0.0 : NormalizeDouble(openPrice - stopLoss, Digits());
      takeProfitPrice = (stopLoss == 0.0) ? 0.0 : NormalizeDouble(openPrice + stopLoss, Digits());
   }
   else if (orderType == ORDER_TYPE_SELL)
   {
      openPrice = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits());
      stopLossPrice = (stopLoss == 0.0) ? 0.0 : NormalizeDouble(openPrice + takeProfit, Digits()); 
      takeProfitPrice = (stopLoss == 0.0) ? 0.0 : NormalizeDouble(openPrice - stopLoss, Digits());
   }
   else
   {
      return -1;
   }
   
   ticket = OrderSend(Symbol(), orderType, InpOrderSize, openPrice, 0, stopLossPrice, takeProfitPrice, InpTradeComment, InpMagicNumber);
   
   return ticket;
}
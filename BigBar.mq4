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

input int BarCount_PriceZone = 96;
input int BarCount_Avg = 20;
input int BarCount_Anchor = 5;
input int BarCount_AfterBigBar_Upper = 5;
input int Slippage = 3;

int BarCount_AfterBigBar = 0;

double PriceZone_Max = 0;
double PriceZone_Min = 0;
double Avg_Price = 0;
double Anchor_AvgChange = 0;

// 说明：
// 若某个Bar的(Hight-low)/Anchor_AvgChange >= 1.68, 当前的Bar被认为是BigBar
double Ratio = 1.68;

// 表示相对高位回调比例（基于过去96个bar的区间）
double Ration_CallBack = 1.0/8;

// 说明：用于表示在出现 BigBar后的跟踪价格阈值
double TrackPrice_AfterBigBar = 0;
double TrackPrice_AfterTrade = 0;


// 说明：保存在交易后的最大值与最小值
double MaxPrice_AfterTrade = 0;
double MinPrice_AfterTrade = 0;

// 说明：
// 1)若BigBar_State == 0， 说明暂时未出现BigBar
// 2)若BigBar_State == 1， 说明已经出现 Buy型的BigBar
// 3)若BigBar_State == -1， 说明已经出现 Sell型的BigBar
int BigBar_State = 0;

// 说明：
// 1)若Account_State == 0， 说明暂时空仓
// 2)若Account_State == 1， 说明暂时持有多头仓位
// 3)若Account_State == -1， 说明暂时持有空头仓位
int Account_State = 0;


int index = 0;

// 定义 买入&&卖出 数量
input double OrderSize = 0.1;
input string TradeComment = "Big Bar";
input int MagicNumber = 212121;


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

void BuyPosition(double openPrice)
{
   // double openPrice = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits());
   int ticket = OrderSend(Symbol(), ORDER_TYPE_BUY, OrderSize, openPrice, Slippage, 0, 0, TradeComment, MagicNumber);
   if(ticket<0)
   {
      Print("OrderSend failed with error #",GetLastError());
   }
   
   // 更新止损价格
   TrackPrice_AfterTrade = TrackPrice_AfterBigBar;
   Account_State = 1;
   return;
}

void SellPosition(double openPrice)
{
   // double openPrice = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits());
   int ticket = OrderSend(Symbol(), ORDER_TYPE_SELL, OrderSize, openPrice, Slippage, 0, 0, TradeComment, MagicNumber);
   if(ticket<0)
   {
      Print("OrderSend failed with error #",GetLastError());
   }
   
   // 更新止损价格
   TrackPrice_AfterTrade = TrackPrice_AfterBigBar;
   Account_State = -1;
   return;
}


void ClosePosition()
{
   for(int x=OrdersTotal();x>=0;x--)
   {
      if(OrderSelect(x,SELECT_BY_POS)==true)
      {
         if(Account_State == 1)
         {
            // 如果当前持仓为多头，需要以买方的价格卖出
            OrderClose(OrderTicket(),OrderLots(),Bid,3,clrNONE);
         }
         else if(Account_State == -1)
         {
            // 如果当前持仓为空头，需要以卖方的价格买入
            OrderClose(OrderTicket(),OrderLots(),Ask,3,clrNONE);
         }
         else
         {
            Print("Error, No orders can to be colsed!");
         }
      }
   }
   
   Account_State = 0;
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
      static bool oversold = false;
      static bool overbought = false;
      // Print("tick");
      
      
      if (Bars < BarCount_PriceZone)
      {
         return;
      }
      
      // 如果过去一段时间Bar数目过少，则跳过
      // Print("The Bars:", Bars);
      double curPrice = MarketInfo(Symbol(), MODE_BID);
      // Print("CurPrice: ", curPrice);
      
      /*
      if(Account_State == 1)
      {
         // 如果当前持有多头，且高位回调超过 1/8 * (PriceZone_Max-PriceZone_Min), 则平仓
         if(curPrice < TrackPrice_Threshold)
         {
            //进行平仓操作
            ClosePosition();
            // ShowCommentOnBar(string(curPrice < TrackPrice_Threshold));
            ShowCommentOnBar("回调平仓", White);
         }
      }
      else if(Account_State == -1)
      {
         if(curPrice > TrackPrice_Threshold)
         {
            //进行平仓操作
            ClosePosition();
            ShowCommentOnBar("回调平仓", White);
         }
      }
      */
      
      /*
      double threshold = Ration_CallBack * (PriceZone_Max-PriceZone_Min);
      if(Account_State == 1)
      {
         // 如果当前持有多头，且高位回调超过 1/8 * (PriceZone_Max-PriceZone_Min), 则平仓
         if(MaxPrice_AfterTrade-curPrice > threshold)
         {
            //进行平仓操作
            ClosePosition();
         }   
      }
      else if(Account_State == -1)
      {
         if(curPrice-MinPrice_AfterTrade > threshold)
         {
            //进行平仓操作
            ClosePosition();
         }
      }*/
       
      if (!NewBar()) return;
      if (Bars <= BarCount_PriceZone) return;
      
      // 计算过去一段时间的平均值
      Avg_Price = iMA(Symbol(),Period(),20,0,MODE_SMA,PRICE_CLOSE,1);
      // Print("Avg:", Avg_Price);
      
      
      // 1. 计算过去96个bar的最高值与最低值
      for (int i = 1; i <= BarCount_PriceZone; ++i)
      {
         // Print("volume[",i,"]", Volume[i]);
         PriceZone_Max = fmax(High[i], PriceZone_Max);
         PriceZone_Min = fmin(Low[i], PriceZone_Min);
      }
      
      
      // 2. 计算前一个Bar是否为BigBar， 进而更新BigBar_State
      int preBar_State = Get_PreBarState();
      if(preBar_State == 1) ShowArrowUp();
      if(preBar_State == -1) ShowArrowDown();
      
      // 只有preBar_State != 0 时且与当前 BigBar_State状态不同时，需要进行更新操作
      if(preBar_State != 0)
      {
         // 当前帐户有持仓，当出现新的BigBar与过去的BigBar相同状态时，止损价格要进行下移
         if(Account_State == 1 && preBar_State == 1) TrackPrice_AfterTrade = Low[1]+(High[1]-Low[1]) * 1/3;
         if(Account_State == -1 && preBar_State == -1) TrackPrice_AfterTrade = High[1]-(High[1]-Low[1]) * 1/3;
         
         if(preBar_State != BigBar_State)
         {
            if(preBar_State==1)
            {
               // 如果出现了 BigBar_Buy, 计算后期的Track Price阈值
               TrackPrice_AfterBigBar = Low[1] + (High[1]-Low[1]) * 1/3;
               // TrackPrice_AfterBigBar = Low[1];
               ShowCommentOnBar(string(TrackPrice_AfterBigBar));
               BarCount_AfterBigBar = -1;
            }
            else if(preBar_State==-1)
            {
               // 如果出现了 BigBar_Sell, 计算后期的Track Price阈值
               TrackPrice_AfterBigBar = High[1] - (High[1]-Low[1]) * 1/3;
               // TrackPrice_AfterBigBar = High[1];
               BarCount_AfterBigBar = -1; 
            }
         }
         BigBar_State = preBar_State;
      }
      
      if(BigBar_State != 0)
      {
         BarCount_AfterBigBar += 1;
      }
      
      ShowCommentOnBar(string(BarCount_AfterBigBar));
      
      // 如果前期收盘价低于TrackPrice_Threshold，则进行平仓
      if(Account_State == 1 && Close[1]<= TrackPrice_AfterTrade)
      {
         ClosePosition();
      }
      else if(Account_State == -1 && Close[1]>= TrackPrice_AfterTrade)
      {
         ClosePosition();
      }
      
      // 2. 查看BigBar是否已经出现，若出现，看是否满足入场条件或者清场条件
      if(BigBar_State == 1)
      {
         // 出现Buy BigBar后跟踪价格低于阈值价格，则说明 BigBar无效
         
         // string comment = StringFormat("%.4f | %.4f %s", TrackPrice_Threshold, Low[1], string(Low[1] < TrackPrice_Threshold));
         // ShowCommentOnBar(comment, White);
         
         // if(Low[1] < TrackPrice_AfterBigBar)
         if(Close[1] < TrackPrice_AfterBigBar)
         {
            
            BigBar_State = 0;
            BarCount_AfterBigBar = -1;
         }
         else
         {
            // BarCount_AfterBigBar += 1;
            
            // comment = StringFormat("%d", BarCount_AfterBigBar);
            // ShowCommentOnBar(comment, Green);
            
            if(BarCount_AfterBigBar > BarCount_AfterBigBar_Upper)
            {
               //说明此时到了 买点与卖点
               if(Account_State == 0)
               {
                  // 买入
                  double openPrice = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits());
                  BuyPosition(openPrice);
                  MaxPrice_AfterTrade = openPrice;
                  MinPrice_AfterTrade = openPrice; 
                  BigBar_State = 0;
                  BarCount_AfterBigBar = -1;
               }
               else if(Account_State == -1)
               {  
                  // 平仓
                  // ShowCommentOnBar("平仓买多");
                  ClosePosition();
                  
                  // 反手进行买入操作
                  double openPrice = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits());
                  BuyPosition(openPrice);
                  
                  // openPrice = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits());
                  MaxPrice_AfterTrade = 0;
                  MinPrice_AfterTrade = 0;
                  BigBar_State = 0;
                  BarCount_AfterBigBar = -1;
               }
               
               // if Account_State == 1, 则不进行操作（已经持多仓不加仓）
            }
         }
      }
      
      else if(BigBar_State == -1)
      {
         // 出现Sell BigBar后跟踪价格低于阈值价格，则说明 BigBar无效
         // if(High[1] > TrackPrice_AfterBigBar)
         if(Close[1] > TrackPrice_AfterBigBar)
         {
            BigBar_State = 0;
            BarCount_AfterBigBar = -1;
         }
         else
         {
            // BarCount_AfterBigBar += 1;
            if(BarCount_AfterBigBar > BarCount_AfterBigBar_Upper)
            {
               //说明此时到了 买点与卖点
               if(Account_State == 0)
               {
                  // 买空
                  double openPrice = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits());
                  SellPosition(openPrice);
                  
                  MaxPrice_AfterTrade =  openPrice;
                  MinPrice_AfterTrade = openPrice; 
                  BigBar_State = 0;
                  BarCount_AfterBigBar = -1;
               }
               else if(Account_State == 1)
               {  
                  // 平仓
                  ClosePosition();
                  ShowCommentOnBar("平仓买空");
                  
                  // 反手进行卖出操作
                  double openPrice = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits());
                  SellPosition(openPrice);
                  
                  // openPrice = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits());
                  MaxPrice_AfterTrade = 0;
                  MinPrice_AfterTrade = 0;
                  BigBar_State = 0;
                  BarCount_AfterBigBar = -1;
               }
               
               // if Account_State == -1, 则不进行操作（已经持空仓不加仓）
            }
         }
      }
      
      // 更新持仓后的MaxPrice_AfterTrade 与 MinPrice_AfterTrade
      if(Account_State != 0 && BarCount_AfterBigBar != -1)
      {
         MaxPrice_AfterTrade = fmax(MaxPrice_AfterTrade, High[1]);
         MinPrice_AfterTrade = fmin(MinPrice_AfterTrade, Low[1]);
      }
      
      return;   
  }



// Get the pre-bar state
int Get_PreBarState()
{
   int state = 0;
   if(Bars <= BarCount_Anchor)
   {
      return state;
   }
   
   double sum = 0;
   for (int i = 2; i < BarCount_Anchor + 2; ++i)
   {
      sum += (High[i] - Low[i]);
   }
   
   if ((High[1]-Low[1])* BarCount_Anchor/sum >= Ratio)
   {
      double PriceChange = Close[1]-Open[1];
      if (PriceChange > 0) state = 1;
      else if(PriceChange == 0) state = 0;
      else state = -1;
   }
   
   return state;
}

void ShowCommentOnBar(string comment, color text_color=White)
{
   index += 1;
   string name = string(index);
   ObjectCreate(name,OBJ_TEXT,0,Time[1],High[1]);
   ObjectSet(name, OBJPROP_ANGLE, 90);
   ObjectSetText(name, comment, 8, "Times New Roman", text_color);
}

void ShowArrowUp()
{
   index += 1;
   string name = string(index);
   ObjectCreate(name, OBJ_ARROW_UP, 0,Time[1], High[1]);
   ObjectSet(name, OBJPROP_COLOR,Yellow);   
}

void ShowArrowDown()
{
   index += 1;
   string name = string(index);
   ObjectCreate(name, OBJ_ARROW_DOWN, 0,Time[1], High[1]);  
   ObjectSet(name, OBJPROP_COLOR, Red);
}

//+------------------------------------------------------------------+

ENUM_INIT_RETCODE CheckInput()
{
   return INIT_SUCCEEDED;
}

bool NewBar()
{
   datetime currentTime = iTime(Symbol(), Period(), 0);
   static datetime priorTime = currentTime;
   bool result = (currentTime != priorTime);
   
   if (result)
   {
      Print(currentTime);
      Print("A new bar generated.");
      Comment("Here");
      
      ObjectCreate ("AtOpen",OBJ_TEXT,0,0,0);
      ObjectCreate("AtOpen", OBJ_TEXT, 0,Time[1], Close[1] );
      ObjectSetText ("AtOpen", "Opn:",10,"Calibri",clrWhite);
   }
   
   priorTime = currentTime;
   return result;
}



/*
bool StoreHistoryData()
{
      // 对历史数据进行存储
      MqlRates rates[];
      ArraySetAsSeries(rates,true);
      int copied=CopyRates(Symbol(),0,0,100,rates);
      if(copied>0)
      {
         Print("Bars copied: "+copied);
         string format="open = %G, high = %G, low = %G, close = %G, volume = %d";
         string out;
         int size=fmin(copied,10);
         for(int i=0;i<size;i++)
           {
            out=i+":"+TimeToString(rates[i].time);
            out=out+" "+StringFormat(format,
                                     rates[i].open,
                                     rates[i].high,
                                     rates[i].low,
                                     rates[i].close,
                                     rates[i].tick_volume);
            Print(out);
           }
      }
      else Print("Failed to get history data for the symbol ",Symbol());
}
*/
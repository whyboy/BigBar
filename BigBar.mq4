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
input int BarCount_AfterBigBar = 8;

double PriceZone_Max = 0;
double PriceZone_Min = 0;
double Avg_Price = 0;
double Anchor_AvgChange = 0;

// 说明：
// 若某个Bar的(Hight-low)/Anchor_AvgChange >= 1.68, 当前的Bar被认为是BigBar
double Ratio = 1.68;

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
      Print("tick");
      if (!NewBar()) return;
      
      // 如果过去一段时间Bar数目过少，则跳过
      Print("The Bars:", Bars);
      if (Bars < BarCount_PriceZone)
      {
         return;
      }
      
      // 计算过去一段时间的平均值
      Avg_Price = iMA(Symbol(),Period(),20,0,MODE_SMA,PRICE_CLOSE,1);
      Print("Avg:", Avg_Price);
      
      /*
      index += 1;
      name = string(index);
      ObjectCreate(name, OBJ_ARROW, 0,Time[0], High[1]);
      // ObjectSetText(name, "Hello world!", 10, "Times New Roman", Green);//---
      */
      
      // 计算过去96个bar的最高值与最低值
      for (int i = 1; i <= BarCount_PriceZone; ++i)
      {
         // Print("volume[",i,"]", Volume[i]);
         PriceZone_Max = fmax(High[i], PriceZone_Max);
         PriceZone_Min = fmin(Low[i], PriceZone_Min);
      }
      
      // 计算前一个Bar是否为BigBar
      double sum = 0;
      for (int i = 2; i < BarCount_Anchor + 2; ++i)
      {
         sum += (High[i] - Low[i]);
      }
      
      if ((High[1]-Low[1])*5/sum >= Ratio)
      {
         double PriceChange = Close[1]-Open[1];
         if (PriceChange > 0) BigBar_State = 1;
         else if(PriceChange == 0) BigBar_State = 0;
         else BigBar_State = -1;
         if(BigBar_State == 1)
         {
            ShowArrowUp();
         }
         else if(BigBar_State==-1)
         {
            ShowArrowDown();
         }
      }
      
      
      
      
      /*
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
      */
      
      return;   
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
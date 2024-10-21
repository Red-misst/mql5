//+------------------------------------------------------------------+
//|                                               scalping_robot.mq5 |
//|                                  Copyright 2024, Isaac Muigai. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright " Copyright 2024, Isaac Muigai. "
#property link      "https://www.mql5.com"
#property version   "4.00"

#include <Trade/Trade.mqh>

CTrade trade;
CPositionInfo pos;
COrderInfo ord;

input int BarsN = 10; // number of bars to look back
input int Tppoints =230;  // take profit (10 points = 1 pip)
input int Slpoints = 25;      // stoploss points (10 points = 1 pip)
input int TslTriggerPoints = 25; // points in profit before trailing SL is activated
input int TslPoints = 10;      // trailing stoploss (10 points = 1 pip)
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT; // timeframe to run
input int InpMagic = 292929;   // EA identification number
input string TradeComment = "scalping robot";
input int MaxTrades = 10;// maximum number of open positions



// Start Hour and End Hour enumerations
enum StartHour {inactive = 0, _0100 = 1, _0200 = 2, _0300 = 3, _0400 = 4, _0500 = 5, _0600 = 6,
                _0700 = 7, _0800 = 8, _0900 = 9, _1000 = 10, _1100 = 11, _1200 = 12,
                _1300 = 13, _1400 = 14, _1500 = 15, _1600 = 16, _1700 = 17,
                _1800 = 18, _1900 = 19, _2000 = 20, _2100 = 21, _2200 = 22, _2300 = 23
               };

input StartHour SHInput = 10; //time to start trading

enum EndHour {inactive =0,
              _0100=1,
              _0200=2,
              _0300=3,
              _0400=4,
              _0500=5,
              _0600=6,
              _0700=7,
              _0800=8,
              _0900=9,
              _1000=10,
              _1100=11,
              _1200=12,
              _1300=13,
              _1400=14,
              _1500=15,
              _1600=16,
              _1700=17,
              _1800=18,
              _1900=19,
              _2000=20,
              _2100=21,
              _2200=22,
              _2300=23
             };

input EndHour EHInput = 22; //time to stop trading


int ExpirationBars = 200;
int OrderDistPoints = 100;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
// Set magic number
   trade.SetExpertMagicNumber(InpMagic);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!isNewBar())
     {
      return;
     }

   MqlDateTime time;
   TimeToStruct(TimeCurrent(), time);
   int Hournow = time.hour;

// Check trading hours
   if(Hournow < SHInput || (Hournow >= EHInput && EHInput != 0))
     {
      CloseAllOrders();
      return;
     }

   int BuyTotal = 0;
   int SellTotal = 0;

// Count open positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i))   // Ensure position selection is successful
        {
         if(pos.Symbol() == _Symbol && pos.Magic() == InpMagic)
           {
            if(pos.PositionType() == POSITION_TYPE_BUY)
               BuyTotal++;
            else
               if(pos.PositionType() == POSITION_TYPE_SELL)
                  SellTotal++;
           }
        }
     }

// Count pending orders
   int PendingBuyTotal = 0;
   int PendingSellTotal = 0;
   for(int j = OrdersTotal() - 1; j >= 0; j--)
     {
      if(ord.SelectByIndex(j))   // Ensure order selection is successful
        {
         if(ord.Symbol() == _Symbol && ord.Magic() == InpMagic)
           {
            if(ord.OrderType() == ORDER_TYPE_BUY_LIMIT || ord.OrderType() == ORDER_TYPE_BUY_STOP)
               PendingBuyTotal++;
            else
               if(ord.OrderType() == ORDER_TYPE_SELL_LIMIT || ord.OrderType() == ORDER_TYPE_SELL_STOP)
                  PendingSellTotal++;
           }
        }
     }

// Attempt to send buy or sell orders
   if(BuyTotal + PendingBuyTotal < MaxTrades)   // Allow up to 2 positions
     {
      double high = findHigh();
      if(high > 0)
        {
         SendBuyOrder(high);
        }
     }

   if(SellTotal + PendingSellTotal < MaxTrades)   // Allow up to 2 positions
     {
      double low = findLow();
      if(low > 0)
        {
         SendSellOrder(low);
        }
     }

// Optional: Implement trailing stop logic
   TrailStop();
  }

//+------------------------------------------------------------------+
//| Find highest high over last 200 bars                             |
//+------------------------------------------------------------------+
double findHigh()
  {
   double highestHigh = 0;
   for(int i = 0; i < 200; i++)
     {
      double high = iHigh(_Symbol, Timeframe, i);
      if(i > BarsN && iHighest(_Symbol, Timeframe, MODE_HIGH, BarsN * 2 + 1, i - BarsN) == i)
        {
         highestHigh = MathMax(high, highestHigh);
         return highestHigh; // Return immediately if condition met
        }
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| Find lowest low over last 200 bars                               |
//+------------------------------------------------------------------+
double findLow()
  {
   double lowestLow = DBL_MAX;
   for(int i = 0; i < 200; i++)
     {
      double low = iLow(_Symbol, Timeframe, i);
      if(i > BarsN && iLowest(_Symbol, Timeframe, MODE_LOW, BarsN * 2 + 1, i - BarsN) == i)
        {
         lowestLow = MathMin(low, lowestLow);
         return lowestLow; // Return immediately if condition met
        }
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| Check if a new bar has been formed                               |
//+------------------------------------------------------------------+
bool isNewBar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol, Timeframe, 0);
   if(previousTime != currentTime)
     {
      previousTime = currentTime;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Send buy stop order                                              |
//+------------------------------------------------------------------+
void SendBuyOrder(double entry)
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(ask > entry - OrderDistPoints * _Point)
      return;

   double tp = entry + Tppoints * _Point;
   double sl = entry - Slpoints * _Point;
   double lots =  calcLots(sl - entry) ;

   datetime expiration = iTime(_Symbol, Timeframe, 0) + ExpirationBars * PeriodSeconds(Timeframe);
   trade.BuyStop(lots, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration);
  }

//+------------------------------------------------------------------+
//| Send sell stop order                                             |
//+------------------------------------------------------------------+
void SendSellOrder(double entry)
  {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid < entry + OrderDistPoints * _Point)
      return;

   double tp = entry - Tppoints * _Point;
   double sl = entry + Slpoints * _Point;
   double lots =  calcLots(entry - sl) ;

   datetime expiration = iTime(_Symbol, Timeframe, 0) + ExpirationBars * PeriodSeconds(Timeframe);
   trade.SellStop(lots, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration);
  }

//+------------------------------------------------------------------+
//| Close all orders for the current symbol                          |
//+------------------------------------------------------------------+
void CloseAllOrders()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ord.SelectByIndex(i);
      if(ord.Symbol() == _Symbol && ord.Magic() == InpMagic)
        {
         trade.OrderDelete(ord.Ticket());
        }
     }
  }

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//+------------------------------------------------------------------+
double calcLots(double slPoints)
  {

   double lots = AccountInfoDouble(ACCOUNT_BALANCE) * 0.0004;
   if(lots > 95)
     {
      return NormalizeDouble(95, 2);
     }
   else
     {
      return NormalizeDouble(lots, 2);
     }


  }

//+------------------------------------------------------------------+
//| Implement trailing stop                                          |
//+------------------------------------------------------------------+
void TrailStop()
  {
   double sl = 0;
   double tp = 0;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Magic() == InpMagic && pos.Symbol() == _Symbol)
        {
         ulong ticket = pos.Ticket();

         if(pos.PositionType() == POSITION_TYPE_BUY)
           {
            if(bid - pos.PriceOpen() > TslTriggerPoints * _Point)
              {
               tp = pos.TakeProfit();
               sl = bid - (TslPoints * _Point);
               if(sl > pos.StopLoss() && sl != 0)
                 {
                  trade.PositionModify(ticket, sl, tp);
                 }
              }
           }
         else
            if(pos.PositionType() == POSITION_TYPE_SELL)
              {
               if(ask + (TslTriggerPoints * _Point) < pos.PriceOpen())
                 {
                  tp = pos.TakeProfit();
                  sl = ask + (TslPoints * _Point);
                  if(sl < pos.StopLoss() && sl != 0)
                    {
                     trade.PositionModify(ticket, sl, tp);
                    }
                 }
              }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                  setupHunter.mq4 |
//|                                                    Matej Ocovsky |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Matej Ocovsky"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


input double lotSize=0.01;                              //Initial lot size for trades
input int rmiPeriod=30;                               //Rmi period
input double rmiBuyLevel=30;                          //Rmi buy level
input double rmiSellLevel=70;                         //Rmi sell level
input int tpPips=15;                                  //Take profit value in pips
input int slPips=200;                                  //Stop loss value in pips
input int magicNum=6446;                                //Magic number for trades
input double martingaleCoefficient=15;                //Martingale multiply coefficient
input double lotLimit=0.15;                             //Maximum lot size for trade


double our_buffer[];
int ticket;

double   open1,//first candle Open price
open2,    //second candle Open price
close1,   //first candle Close price
close2,   //second candle Close price
low1,     //first candle Low price
low2,     //second candle Low price
high1,    //first candle High price
high2;    //second candle High price

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      SetIndexBuffer(0,our_buffer,INDICATOR_DATA);
      ResetLastError();
      
      
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
      if(!is_new_bar())
      {
         return;
      }
      
      double rmiValue = iCustom(_Symbol,_Period,"RMI",rmiPeriod,5,0,1);
      
      
      double closePrice = NormalizeDouble(iClose(Symbol(), Period(), 1), Digits);
      
      bool buyCondition = rmiValue < rmiBuyLevel && is_bullish_inside_bar();
      
      bool sellCondition = rmiValue > rmiSellLevel && is_bearish_inside_bar();
      

      if(!trades_on_symbol(_Symbol))
      {
         if(buyCondition) 
         {
            // if we have buy trades on symbol -> do nothing
            if(!buy_trades_on_symbol(_Symbol))
            {
               bool closedAllOrders = close_all();
               Print("Closed all orders? :" + closedAllOrders);
               Print("buy asking price: " + Ask);
               
               ticket=OrderSend(Symbol(),OP_BUY,lotSize,Ask,3,Ask-slPips*10*Point,Ask+tpPips*10*Point,"setupHunter",16384,0,Blue);
               if(ticket>0)
                 {
                  if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                     Print("BUY order opened : ",OrderOpenPrice());
                 }
               else
                  Print("Error opening BUY order : ",GetLastError());
               return;
            }
         }
         
         if(sellCondition) 
         {
            if(!sell_trades_on_symbol(_Symbol))
            {
               bool closedAllOrders = close_all();
               Print("Closed all orders? :" + closedAllOrders);
               Print("sell sking price: " + Bid);
               
               ticket=OrderSend(Symbol(),OP_SELL,lotSize,Bid,3,Bid+slPips*10*Point,Bid-tpPips*10*Point,"setupHunter",16384,0,Red);
               if(ticket>0)
                 {
                  if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                     Print("SELL order opened : ",OrderOpenPrice());
                 }
               else 
                  Print("Error opening SELL order : ",GetLastError());
               return;
            }
         }
      }
  }
  
//+------------------------------------------------------------------+
//| Check for new bar                                                |
//+------------------------------------------------------------------+
bool is_new_bar()
{
   static datetime lastbar;
   datetime curbar = (datetime)SeriesInfoInteger(_Symbol,_Period,SERIES_LASTBAR_DATE);
   if(lastbar != curbar)
   {
      lastbar = curbar;
      return true;
   }
   return false;
}
  
  
//+------------------------------------------------------------------+
//| Check if there are any open trades on the symbol                 |
//+------------------------------------------------------------------+  
bool trades_on_symbol(string symbol)
{
   for(int i=OrdersTotal()-1;OrderSelect(i,SELECT_BY_POS);i--)
      if(OrderSymbol()==symbol && OrderType()<2)
         return true;
   return false;
}

//+------------------------------------------------------------------+
//| Check if there are any open sell trades on the symbol            |
//+------------------------------------------------------------------+  
bool sell_trades_on_symbol(string symbol)
{
   for(int i=OrdersTotal()-1;OrderSelect(i,SELECT_BY_POS);i--)
      if(OrderSymbol()==symbol && OrderType() == OP_SELL)
         return true;
   return false;
}

//+------------------------------------------------------------------+
//| Check if there are any open buy trades on the symbol             |
//+------------------------------------------------------------------+  
bool buy_trades_on_symbol(string symbol)
{
   for(int i=OrdersTotal()-1;OrderSelect(i,SELECT_BY_POS);i--)
      if(OrderSymbol()==symbol && OrderType() == OP_BUY)
         return true;
   return false;
}
 

//+------------------------------------------------------------------+
//| Close all trades                                                 |
//+------------------------------------------------------------------+    
bool close_all()
{
   bool result = true;
   for(int i=OrdersTotal()-1; i>=0; i--){
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == _Symbol){
         if(OrderType() < 2){
            if(!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 10)){
               result = false;
            }
         }
         else if(!OrderDelete(OrderTicket())){
            result = false;
         }
      }
   }
   return result;
}

//+------------------------------------------------------------------+
//| Check for bearish engulfing pattern                              |
//+------------------------------------------------------------------+
bool is_bearish_engulfing()
{
   open1 = NormalizeDouble(iOpen(Symbol(), Period(), 1), Digits);
   open2 = NormalizeDouble(iOpen(Symbol(), Period(), 2), Digits);
   close1 = NormalizeDouble(iClose(Symbol(), Period(), 1), Digits);
   close2 = NormalizeDouble(iClose(Symbol(), Period(), 2), Digits);
   low1 = NormalizeDouble(iLow(Symbol(), Period(), 1), Digits);
   low2 = NormalizeDouble(iLow(Symbol(), Period(), 2), Digits);
   high1 = NormalizeDouble(iHigh(Symbol(), Period(), 1), Digits);
   high2 = NormalizeDouble(iHigh(Symbol(), Period(), 2), Digits);

   if(
      low1 < low2 &&// First bar's Low is below second bar's Low
      high1 > high2 &&// First bar's High is above second bar's High
      close1 < open2 &&	//First bar's Close price is below second bar's Open
      open1 > close1 && //First bar is a bearish bar
      open2 < close2 //Second bar is a bullish bar
   )	
   {
      return true;
   }
     
   return false;
}

//+------------------------------------------------------------------+
//| Check for bullish engulfing pattern                              |
//+------------------------------------------------------------------+
bool is_bullish_engulfing()
{
   open1 = NormalizeDouble(iOpen(Symbol(), Period(), 1), Digits);
   open2 = NormalizeDouble(iOpen(Symbol(), Period(), 2), Digits);
   close1 = NormalizeDouble(iClose(Symbol(), Period(), 1), Digits);
   close2 = NormalizeDouble(iClose(Symbol(), Period(), 2), Digits);
   low1 = NormalizeDouble(iLow(Symbol(), Period(), 1), Digits);
   low2 = NormalizeDouble(iLow(Symbol(), Period(), 2), Digits);
   high1 = NormalizeDouble(iHigh(Symbol(), Period(), 1), Digits);
   high2 = NormalizeDouble(iHigh(Symbol(), Period(), 2), Digits);

   if(
      low1 < low2 &&// First bar's Low is below second bar's Low 
      high1 > high2 &&// First bar's High is above second bar's High
      close1 > open2 && //First bar's Close price is higher than second bar's Open
      open1 < close1 && //First bar is a bullish bar
      open2 > close2 //Second bar is a bearish bar
   )   
   {   
      return true;
   }
     
   return false;
}

//+------------------------------------------------------------------+
//| Check for bearish inside bar pattern                             |
//+------------------------------------------------------------------+
bool is_bearish_inside_bar()
{
   open1        = NormalizeDouble(iOpen(Symbol(), Period(), 1), Digits);
   open2        = NormalizeDouble(iOpen(Symbol(), Period(), 2), Digits);
   close1       = NormalizeDouble(iClose(Symbol(), Period(), 1), Digits);
   close2       = NormalizeDouble(iClose(Symbol(), Period(), 2), Digits);
   low1         = NormalizeDouble(iLow(Symbol(), Period(), 1), Digits);
   low2         = NormalizeDouble(iLow(Symbol(), Period(), 2), Digits);
   high1        = NormalizeDouble(iHigh(Symbol(), Period(), 1), Digits);
   high2        = NormalizeDouble(iHigh(Symbol(), Period(), 2), Digits);

   if(
      open2 < close2 && //the second bar is bullish
      close1 < open1 && //the first bar is bearish
      high2 > high1 &&  //the bar 2 High exceeds the first one's High
      open2 < close1 && //the second bar's Open exceeds the first bar's Close
      low2 < low1 //the second bar's Low is lower than the first bar's Low
   )      
   {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for bullish inside bar pattern                             |
//+------------------------------------------------------------------+
bool is_bullish_inside_bar()
{
   open1        = NormalizeDouble(iOpen(Symbol(), Period(), 1), Digits);
   open2        = NormalizeDouble(iOpen(Symbol(), Period(), 2), Digits);
   close1       = NormalizeDouble(iClose(Symbol(), Period(), 1), Digits);
   close2       = NormalizeDouble(iClose(Symbol(), Period(), 2), Digits);
   low1         = NormalizeDouble(iLow(Symbol(), Period(), 1), Digits);
   low2         = NormalizeDouble(iLow(Symbol(), Period(), 2), Digits);
   high1        = NormalizeDouble(iHigh(Symbol(), Period(), 1), Digits);
   high2        = NormalizeDouble(iHigh(Symbol(), Period(), 2), Digits);

   if(
      open2 > close2 && //the second bar is bearish
      close1 > open1 && //the first bar is bullish
      high2 > high1 &&  //the bar 2 High exceeds the first one's High
      open2 > close1 && //the second bar's Open exceeds the first one's Close
      low2 < low1)      //the second bar's Low is lower than the first one's Low
         
   {
      return true;
   }
   
   return false;
}
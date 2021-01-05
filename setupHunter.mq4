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
      
      bool buyCondition = (closePrice > filterMa) && (signalLine < macdLine) && (signalLinePrevious >= macdLinePrevious) && (signalLine < 0 && macdLine < 0);
      
      bool sellCondition = (closePrice < filterMa) && (signalLine > macdLine) && (signalLinePrevious <= macdLinePrevious) && (signalLine > 0 && macdLine > 0);
      

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
               
               ticket=OrderSend(Symbol(),OP_BUY,lotSize,Ask,3,Ask-(ATRPoints*InpSLfactor),Ask+(ATRPoints*InpTPfactor),"macd sample",16384,0,Green);
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
               
               ticket=OrderSend(Symbol(),OP_SELL,lotSize,Bid,3,Ask+(ATRPoints*InpSLfactor),Ask-(ATRPoints*InpTPfactor),"macd sample",16384,0,Red);
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
  
  
  
bool trades_on_symbol(string symbol)
{
   for(int i=OrdersTotal()-1;OrderSelect(i,SELECT_BY_POS);i--)
      if(OrderSymbol()==symbol && OrderType()<2)
         return true;
   return false;
}

bool sell_trades_on_symbol(string symbol)
{
   for(int i=OrdersTotal()-1;OrderSelect(i,SELECT_BY_POS);i--)
      if(OrderSymbol()==symbol && OrderType() == OP_SELL)
         return true;
   return false;
}

bool buy_trades_on_symbol(string symbol)
{
   for(int i=OrdersTotal()-1;OrderSelect(i,SELECT_BY_POS);i--)
      if(OrderSymbol()==symbol && OrderType() == OP_BUY)
         return true;
   return false;
}
  
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

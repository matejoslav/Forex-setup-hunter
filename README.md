# Nexus_EA

## How it works
This ea is using a combination of candlestick patterns and indicators.

Indicators used: 
- [RMI](https://www.marketvolume.com/technicalanalysis/relativemomentumindex.asp)
- SuperTrend -> acts as filter on the daily timeframe

Candlestick patterns observed:
- Engulfing pattern (Bullish/Bearish)
- Inside Bar pattern (Bullish/Bearish)
- Hammer/Shooting star pattern (Coming soon)

## Buy entry
These are the checks that the ea is using before placing a BUY order:
- SuperTrend on daily timeframe indicates that market is trending up
- RMI value is below 30
- Bullish Engulfing/Inside Bar pattern is formed on the chart

## Sell entry
These are the checks that the ea is using before placing a SELL order:
- SuperTrend on daily timeframe indicates that market is trending down
- RMI value is above 70
- Bearish Engulfing/Inside Bar pattern is formed on the chart

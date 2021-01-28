using MarketData
using Dates

"""
Utility function to get stock data
"""
function GetStock(ticker, min_date, max_date)
    ticker_symb = Symbol(ticker)
    time_hist = yahoo(ticker_symb)
    time_hist = time_hist[Date(min_date):Day(1):Date(max_date)].AdjClose
    return time_hist

end

"""
Utility function to merge time series
"""
function MergeSeries(tickers)
    # this is basically just a "merge(ticker, merge(ticker, merge(...))) psuedo recursion
    ticker = popfirst!(tickers).AdjClose
        while length(tickers) != 0
               ticker = merge(ticker, popfirst!(tickers).AdjClose)
        end
    return ticker
end

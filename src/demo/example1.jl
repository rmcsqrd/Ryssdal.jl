### OVERVIEW OF EXAMPLES
# example1() : example of api calls
# example2( Window_Size, "Symbol" ) : plots volatility curves for stock
# example3(p, c ) : plots kelly criterion (p = prob win, c = winning odds, assumes c:1)

function example1()
    # API CALL DEMO
    # list of stocks you want in a dictionary
    # cointegrated-looking pairs (MCD, YUM), (UBER,LYFT)
    # NOTE: more than 5 API calls per minute will exceed free API limits
    stockIDs = ["TSLA",
                #"GOOG",
                "GOLD",
                #"AMZN",
                #"UBER",
               "ZM",
               "LYFT",
               "AAPL"]
    API_call_params = API_Types("Daily_Adjusted")

    # [min, max], must follow "YYYY-MM-DD" format (also can be "max" for all data)
    dateRange = ["2019-01-01","2020-10-19"]


    # make API call based on IDs/params
    stockDict = Dict()  # intialize empty dictionary
    for stockID in stockIDs
        stockDict["$stockID"] = AlphaVantage_API_call(API_call_params.function_name, stockID,API_call_params.output_size)
    end
    print("API Call Complete","\n")


    # process data to be massaged
    timehistoryDict = ProcessJSON(stockDict,
                                  stockIDs, 
                                  API_call_params.time_type, 
                                  dateRange)
    print("JSON Massaging Complete","\n")
    PlotStockPrices(timehistoryDict)
    print("Plotting Complete","\n")
    return timehistoryDict


    
end

function example2(WIN_SIZE, TICKER)
    # FUNCTION THAT DOES SIMPLE ROLLING AVERAGE
    # TICKER = something from stockIDs
    # WIN_SIZE = look behind int
    
    timehistoryDict = example1()


    # print mean, std dev
    series = []
    for date in sort(collect(keys(timehistoryDict[TICKER])))
        push!(series, parse(Float64, timehistoryDict[TICKER][date]))
    end
    (mean_error, stddev) = TimeSeriesStatistics(series, WIN_SIZE, type="normal")

    # plot stuff
    plot(mean_error, label="μ", legend=:bottomleft)
    plot!(mean_error+2*stddev, label="+/-2σ", color="red")
    plot!(mean_error-2*stddev, label="", color="red")
    plot!(series, label="Stock Price of $TICKER")
    title!("Plot of $TICKER with window size $WIN_SIZE")
    xlabel!("Days")
    ylabel!("$TICKER Price (\$)")

end

function example3(p, c)
    # function to show kelly criterion
    KellyCriterion(p,c)

end

function example4(TICKER, p)
    timehistoryDict = example1()

    series = []
    for date in sort(collect(keys(timehistoryDict[TICKER])))
        push!(series, parse(Float64, timehistoryDict[TICKER][date]))
    end

    # do AR-net stuff
    ARnet(series, p)
end

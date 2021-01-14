### OVERVIEW OF EXAMPLES
# example1() : example of api calls
# example2( Window_Size, "Symbol" ) : plots volatility curves for stock
# example3(p, c ) : plots kelly criterion (p = prob win, c = winning odds, assumes c:1)


#function example2(WIN_SIZE, TICKER)
#    # FUNCTION THAT DOES SIMPLE ROLLING AVERAGE
#    # TICKER = something from stockIDs
#    # WIN_SIZE = look behind int
#    
#    timehistoryDict = example1()
#
#
#    # print mean, std dev
#    series = []
#    for date in sort(collect(keys(timehistoryDict[TICKER])))
#        push!(series, parse(Float64, timehistoryDict[TICKER][date]))
#    end
#    (mean_error, stddev) = TimeSeriesStatistics(series, WIN_SIZE, type="normal")
#
#    # plot stuff
#    plot(mean_error, label="μ", legend=:bottomleft)
#    plot!(mean_error+2*stddev, label="+/-2σ", color="red")
#    plot!(mean_error-2*stddev, label="", color="red")
#    plot!(series, label="Stock Price of $TICKER")
#    title!("Plot of $TICKER with window size $WIN_SIZE")
#    xlabel!("Days")
#    ylabel!("$TICKER Price (\$)")
#
#end

function example3(p, c)
    # function to show kelly criterion
    KellyCriterion(p,c)

end

function example4(TICKERS, p)
    # example input in REPL
    #   ryssdal.example4(["TSLA", "AAPL"], 10)
    
    timehistoryDict = example1()
    
    # determine shortest history
    minlen = Inf
    for symbol in TICKERS
        if length(keys(timehistoryDict[symbol])) < minlen
            minlen = length(keys(timehistoryDict[symbol]))
        end
    end

    # initialize (n x k_min) empty array to store vals (k_min is minlen)
    # loop through ticker symbols, then loop through dates in dict
    series = zeros(length(TICKERS), minlen)
    for (tick_id, tick_symb) in enumerate(TICKERS)
        dates = sort(collect(keys(timehistoryDict[tick_symb])))

        # reverse operations trade of O(n) operations to avoid
        #   index cluster precipitated by different dict lengths
        reverse!(dates)  
        
        for (cnt, date) in enumerate(dates)
            if cnt <= minlen
                series[tick_id, cnt] = parse(Float64, timehistoryDict[tick_symb][date])
            end
        end
        series[tick_id, :] = reverse(series[tick_id, :])
    end

    # do AR-net stuff
    w_i, c, data = ARnet(series, p)
    println(w_i)
    println(c)
    
    # compute stuff from VAR(p) process
    n = length(TICKERS)
    k = size(series)[2]
    VARp_data = zeros(n, k-p)
    # I think you need to let the process run from the initial point
    for (k, item) in enumerate(data)
        #println(w_i)
        #println(item[1])
        #println(c, "\n")
        y_t = zeros(n)
        y_t += c
        for i in 1:size(item[1])[2]
            y_i = item[1][:, i]
            y_t += w_i[i]*y_i
        end
        VARp_data[:, k] = y_t
    end
    
    #truth_data = series[:, 1:p]
    #VARp_data = [truth_data VARp_data]
    #for i in 1:k-p
    #    data = VARp_data[:, i:i+p-1]
    #    y_t = zeros(n)
    #    y_t += c
    #    for (j, data_j) in enumerate(data)
    #        y_t .+= w_i[j]*data_j
    #    end
    #    VARp_data[:, i+p] = y_t
    #end


    # plot stuff
    plt = plot()
    for (tick_id, tick_symb) in enumerate(TICKERS)
        plot!(series[tick_id,:], label=tick_symb, legend=:topleft)
        plot!(VARp_data[tick_id,:], label="$tick_symb VAR(p)")
    end
    display(plt)
    
end

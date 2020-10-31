using Plots
using Dates

"""
    Wrapper function that accepts nested dict of time history data for plotting.

    truncate = (bool) True: truncate to shortest time history length
                      False: do not truncate data (some time histories will be longer than others)
"""
function PlotStockPrices(timehistory; truncate=false)
    
    # figure out which is longest time series
    time_series_length = []
    for key in keys(timehistory)
        push!(time_series_length, (key, length(keys(timehistory[key]))))
    end

    # sort by length (large to small)
    sort!(time_series_length, by=x->x[2])
    reverse!(time_series_length)
    min_series_length = time_series_length[length(time_series_length)][2]

    
    # plot stuff
    # initialize plot params
    numxticks = 0  # arbitrary magic number for scaling
    pa = plot(title="Stock Price Time History",
             xrotation=-60,
             tickfontsize=6,
             legend=:topleft)

    # loop through ticker symbols
    for item in time_series_length
        ticker_symbol = item[1]
        plot_data = []
        date_data = []
        ticker_time_history = timehistory[ticker_symbol]

        # truncate data (lazily) if required
        if truncate == true
            truncate_cnt = item[2] - min_series_length
            for date in sort(collect(keys(ticker_time_history)))
                if truncate_cnt != 0
                    delete!(timehistory[ticker_symbol], date)
                    truncate_cnt -= 1
                end
            end
        end
        
        # loop through dates within ticker
        for date in sort(collect(keys(ticker_time_history)))
            push!(plot_data, parse(Float64, ticker_time_history[date]))
            push!(date_data, date)
        end
        plot!(pa, date_data, plot_data, label=ticker_symbol)
        numxticks = max(numxticks, convert(Int, floor(length(date_data)*0.1)))  
    end
    plot!(xticks = numxticks)
    xlabel!("Date")
    ylabel!("Split Adjusted Share Price (\$)")
    display(pa)
end

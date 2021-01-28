using DataFrames
using CSV
using ProgressMeter
using Dates
using Plots

# df = DataFrame(CSV.File("aux/data/WSB_POSTS_MAX1611770383_MIN1580147972.csv"))

mutable struct StockCounter
    symbol::String
    total_hits::Int
    hit_time_hist
end

function ParseWSBData(path)
    
    # load in NYSE symbols and WSB data
    root_dir = string(@__DIR__,"/../../")
    nyse_path = string(root_dir, "aux/data/NYSE.csv")
    nyse_df = DataFrame(CSV.File(nyse_path))
    df = DataFrame(CSV.File(path))

    # create reference lists for shorter search times. Instead of searching through
    #   nyse list every time, make sub lists for popular stocks
    # also, maintain a dictionary that we keep updated with stock counts
    stock_list = []
    not_stock_list = ["I","RH", "A", "FOR", "IT", "ARE", "IM", "CEO"]  # seed with common values
    nyse_ticker_list = nyse_df.ACTSymbol
    stock_counter_dict = Dict()

    # create time history container for hits
    max_time = Date(unix2datetime(df.created_utc[1]))
    min_time = Date(unix2datetime(df.created_utc[length(df.created_utc)]))
    time_range = min_time:Day(1):max_time

    # top level loop: loop through all title content
    @showprogress for post in eachrow(df)
        candidate_list = TitleParse(post.title)
        post_date = Date(unix2datetime(post.created_utc))
        
        # loop through candidate list
        for word in candidate_list

            # next loop: loop through list of known stock ticker entities
            if word in stock_list
                stock_counter_dict[word].total_hits += 1
                stock_counter_dict[word].hit_time_hist[post_date] += 1

            # next: loop through list of known non-stock ticker entities
            elseif word in not_stock_list
                # do nothing
                
            # finally: loop through nyse ticker symbols
            else
                # if word isn't in the list, banish it to never be searched for again
                if word in nyse_ticker_list
                    push!(stock_list, word)
                    hit_time_hist_dict = Dict(zip(time_range, [0 for x in time_range]))
                    stock_counter_dict[word] = StockCounter(word, 1, hit_time_hist_dict) 
                    stock_counter_dict[word].hit_time_hist[post_date] += 1
                else
                    push!(not_stock_list, word)
                end
            end
        end
    end
   
    # put into timearray struct for easy plotting
    for (key, value) in sort(collect(stock_counter_dict), by=x->x[2].total_hits)
        hits = [value.hit_time_hist[date] for date in time_range]
        data = (date_time = [date for date in time_range],
                hits = hits)
        time_array = TimeArray(data; timestamp = :date_time, meta = "Time history")
        value.hit_time_hist = time_array
    end

    # unpack information from WSB
    #tickers = ["AMC", "GME", "BB", "NOK"]
    tickers = ["GME", "AMC"]
    WSB_labels = PlotLabels("r/WSB Mentions", "Date", "# of Mentions in Post Titles")
    stock_labels = PlotLabels("r/WSB Mentions vs Stock Price", "Date", "AdjClose Stock Price (Log)")
    series_list = [stock_counter_dict[ticker].hit_time_hist for ticker in tickers]
    
    # get stock data from API, put into list
    stock_data = [GetStock(ticker, min_time, max_time) for ticker in tickers]

    # plot stuff WSB stuff first
    PlotWSBData(series_list, tickers, WSB_labels)  
    # stock data
    PlotStockData(stock_data,
                          [string(ticker, " Stock Price") for ticker in tickers],
                          stock_labels,
                         )  
end

function TitleParse(title)
    punc_strip = replace(title, Regex("[,.?;!:()*'`~/\$-%]") => "")
    checkupper(word) = all(c->isuppercase(c), word)
    potential_stocks = [word for word in split(punc_strip) if checkupper(word)]
    
    return potential_stocks
end

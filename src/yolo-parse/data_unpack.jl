using DataFrames
using CSV
using ProgressMeter
using Dates

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
    max_time = floor(unix2datetime(df.created_utc[1]), Day(1))
    min_time = floor(unix2datetime(df.created_utc[length(df.created_utc)]), Day(1))
    time_range = min_time:Day(1):max_time
    time_array = Dict(zip(time_range, [0 for x in time_range]))

    # top level loop: loop through all title content
    @showprogress for post in eachrow(df)#bone, remove this
        candidate_list = TitleParse(post.title)
        post_date = floor(unix2datetime(post.created_utc), Day(1))
        
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
                    stock_counter_dict[word] = StockCounter(word, 1, time_array) 
                    stock_counter_dict[word].hit_time_hist[post_date] += 1
                else
                    push!(not_stock_list, word)
                end
            end
        end
    end
   
    # put into timearray struct for easy plotting

    # this will need to be in a loop for each struct
    for (key, value) in sort(collect(stock_counter_dict), by=x->x[2].total_hits)
        # BONE - something in here is what is screwing up
        # data = (date_time= [date for date in keys(value.hit_time_hist)], 
                            #hits=[val for val in values(value.hit_time_hist)])
        # println(data)
        # time_array = TimeArray(data; timestamp = :date_time, meta = "Time history")
        # value.hit_time_hist = time_array
        println(key,"  ", value.hit_time_hist)
    end

end

function TitleParse(title)
    punc_strip = replace(title, Regex("[,.?;!:()*'`~/\$-%]") => "")
    checkupper(word) = all(c->isuppercase(c), word)
    potential_stocks = [word for word in split(punc_strip) if checkupper(word)]
    
    return potential_stocks
end

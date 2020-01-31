# imports
using Pkg
Pkg.add("HTTP")
Pkg.add("JSON")
# Pkg.add("PyPlot")
using HTTP
using JSON
using Plots
using Dates
# using PyPlot



function AlphaVantage_API_call(datafunction, symbol, outputsize)
    dataDir = "/Users/riomcmahon/Programming/ryssdal_jl/stockdata"
    dataDirContents = readdir(dataDir)
    notSaved = false

    # check if stock data directory is empty
    if size(dataDirContents)[1] == 0
        notSaved = true
    end

    # loop through contents of directory to see if file is saved in there
    for file in dataDirContents
        if occursin("$symbol", String(file))
            data = JSON_File_Process(dataDir*"/data"*"$symbol"*".json", "r", "none")
            return data
        else
            notSaved = true
        end
    end

    # make API call if data is not saved
    if notSaved == true
        url="https://www.alphavantage.co/query?function=$datafunction&symbol=$symbol&outputsize=$outputsize&apikey=dog"
        try

            response=HTTP.get(url)
            response=String(response.body)
            JSON_File_Process(dataDir*"/data"*"$symbol"*".json", "w", response)
            responseJSON=JSON.parse(response)
            return responseJSON # returns dictionary object  ls
        catch e
            return "Error occurred : $e"
        end
    end
end

function JSON_File_Process(location, type, data)
    if type == "w"
        open(location, type) do f
            write(f, data)
        end
    elseif type == "r"
        data = JSON.parsefile(location)
        return data
    end
end

function ProcessJSON(stockDict, stockIDs, position)
    # determine which data set is largest
    seriesParam = collect(keys(stockDict[stockIDs[1]]))[1] # will return something like "Time Series (Daily)"
    stockSize = []
    for stock in stockIDs
        push!(stockSize, size(collect(keys(stockDict[stock][seriesParam])))[1])
    end
    bigStock = findall(stockSize .==maximum(stockSize))
    bigStock = stockIDs[bigStock][1]

    # create dictionary that has array of data for each date key. Array is organized per stockIDs
    combinedStockData = Dict()
    for key in stockDict[bigStock][seriesParam]
        temparray = []
        tempkey = collect(key)[1]
        for (cnt, ID) in enumerate(stockIDs)
            try
                value = stockDict[stockIDs[cnt]][seriesParam][tempkey][position]
                push!(temparray, parse(Float64,value))
            catch e
                value = NaN
                push!(temparray, value)
            end
        end
        combinedStockData[String(tempkey)] = temparray
    end
    return combinedStockData
end

function PlotStockPrices(timehistory, stockIDs)
    # this function basically accepts a dictionary based on date and IDs for labeling
    # to
    # initialize empty array for plotting and add dict data in
    keyarray = keys(timehistory)
    plotdim = [length(keyarray), size(stockIDs)[1]]
    plotarray = Array{Any}(undef, plotdim[1], plotdim[2])
    step = range(1,step=1,length = plotdim[1])

    # generate data to plot
    for (k, key) in enumerate(sort(collect(keys(timehistory))))
        temparray = timehistory[key]
        plotarray[k,:] = temparray
    end

    # generate labels
    plotvect = []
    labels = Array{Any}(undef, 1, plotdim[2])
    for (k,) in enumerate(stockIDs)
        push!(plotvect, plotarray[:,k])
        labels[1,k] = stockIDs[k]
    end

    # generate dates for x-axis
    dates = []
    for key in sort(collect(keys(timehistory)))
        push!(dates, Date(key))
    end

    numxticks = convert(Int, floor(length(dates)*0.1))
    pa = plot(dates, plotvect, title="Stock Price Time History",
             label=labels,
             xticks=numxticks,
             xrotation=-60,
             tickfontsize=6)
    ylabel!("Stock Value (\$)")
    xlabel!("Date")
    display(pa)



end

function main()
    # list of stocks you want in a dictionary
    stockIDs = ["GLD",
                "GDX"]

    # parameters to pass to API call, reference https://www.alphavantage.co/documentation/ for alternate params
    API_call_params = ["TIME_SERIES_DAILY",
                        "full",
                        "4. close"]

    # make API call based on IDs/params
    stockDict = Dict()  # intialize empty dictionary
    for stockID in stockIDs
        stockDict["$stockID"] = AlphaVantage_API_call(API_call_params[1], stockID, API_call_params[2])
    end

    # process data to be massaged
    timehistoryDict = ProcessJSON(stockDict, stockIDs, API_call_params[3])
    PlotStockPrices(timehistoryDict, stockIDs)

end

main()

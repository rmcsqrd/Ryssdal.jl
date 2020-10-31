using HTTP
using JSON
using Random


"""
    This function makes an API call to AlphaVantage using API key (usually a dummy one)

    INPUT:
    datafunction = (string) type of time series data you want (eg "TIME_SERIES_INTRADAY")
    symbol = (string) ticker symbol
    outputsize = (string) size of data ("full" for full time series, "compact" for last 100)
    apikey = (string, optional) apikey used for access, so far it works with dummy keys
    newcall = (bool, optional) if set to false, will resuse data. Will make new call if not

    OUTPUT:
    responseJSON = (JSON of data) results to be unpacked
"""
function AlphaVantage_API_call(datafunction, symbol, outputsize; apikey="RANDOM", newcall=false)
    dataDir = string(@__DIR__,"/stockdata")
    dataDirContents = readdir(dataDir)
    notSaved = false

    # check if stock data directory is empty
    if size(dataDirContents)[1] == 0 
        notSaved = true
    end

    # loop through contents of directory to see if file is saved in there
    for file in dataDirContents
        if occursin("$symbol", String(file)) && newcall == false
            data = JSON_File_Process(dataDir*"/data"*"$symbol"*".json", "r", "none")
            return data
        else
            notSaved = true
        end
    end

    if apikey == "RANDOM"
        apikey = randstring(10)
    end

    # make API call if data is not saved
    if notSaved == true 
        url=string("https://www.alphavantage.co/query?function=$datafunction&symbol=$symbol&outputsize=$outputsize&apikey=",apikey)
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

"""
    Helper function for packing/unpacking JSON data
"""
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


"""
    Function for unpacking returned JSON data from AlphaVantage API call

    INPUT:
    stockDict = (Dict) A dict of API JSON files. Keys are ticker symbol, values are the returned JSON files from API call
    stockIDs = (Array) Array of ticker symbols used for API call. Corresponds to stockDict keys
    positionParam = (string) Parameter of interest to parse from JSON file (eg "4. close")
    dateRange = (array, optional) Beginning and ending dates of range of interest for time series

    OUTPUT:
    timeHistoryDict = (Dict, time series data) a nested dictionary of time history data
        top level dict: keys = ticker symbols, values = time history data for ticker symbols
        time history level: keys = dates, value = ticker price on that date based on positionParam
"""
function ProcessJSON(stockDict::Any, stockIDs::Any, positionParam::String, dateRange::Array=["none"])
    
    #   use the longest time series to dictate size of all time series, then use NaN for non-entries
    seriesParam = collect(keys(stockDict[stockIDs[1]]))[1] # will return something like "Time Series (Daily)"
    # create array of dicts with ticker symbols as dict keys
    timeHistoryDict = Dict()  # key = ticker symbol, value = dict of time history
    for id in stockIDs
        stockTimeHistory = stockDict[id][seriesParam]
        idDict = Dict()  # key = date, value = stock price at date based on seriesParam (usually close)
        for date_key in keys(stockTimeHistory)

            if dateRange[1] == "none"
                idDict[date_key] = stockTimeHistory[date_key][positionParam]
            else
                if Dates.Date(date_key)>Dates.Date(dateRange[1]) && Dates.Date(date_key)<Dates.Date(dateRange[2])
                    idDict[date_key] = stockTimeHistory[date_key][positionParam]
                end
            end
        end
        timeHistoryDict[id] = idDict
    end

    return timeHistoryDict
end

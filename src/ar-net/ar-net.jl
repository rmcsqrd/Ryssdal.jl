using Flux
using Flux.Optimise
using Flux.Losses
using TimeSeries
using MarketData
using ProgressMeter
using DataFrames
using Plots
using LinearAlgebra
using Markdown

"""
`ARnet()` is the wrapper function for the ARnet implementation. It takes in the list of ticker symbols and trains the weights/intercepts of an AR(p) model (p is the number of lags). 
    `symb_list`: an array of ticker symbols
    `p`: number of lags for AR(p) process
    `start_date`: start date for the time series data in API call
    `end_date`: end date for time series data in API call
    '
"""
function ARnet(symb_list::Array{Symbol};
                      p=1,
                      num_iters=10,
                      start_date=Date(2020,1,1),
                      end_date=Date(2021,1,11),
                     )
    
    # get marketdata and store dataframes in a list
    mdata_list = []
    for symb in symb_list

        # get market data
        mdata = yahoo(symb)

        # truncate data according to date range
        series_max = maximum(timestamp(mdata))
        series_min = minimum(timestamp(mdata))
        if series_max < end_date || series_min > start_date
            error("Specified date range outside of time history")
        end
        mdata = to(from(mdata, start_date), end_date)
        push!(mdata_list, mdata)
    end

    # create AR(p) data
    ARdata = ARdataPrep(mdata_list, p)
    
    # create list of data by zipping lag/result values
    data = collect(zip(ARdata.LagValues, ARdata.ResultValues))
    
    # train model
    w_i, c = ARnetTrain(data, p, num_iters=num_iters)

    # BONE - break this out into a "reconstitute" function and a plot util function
    # reconstitute data
    sim_data = ARnetReconstitute(mdata_list, w_i, c, p)

    # combine sim data with market data, create labels, and plot
    push!(mdata_list, sim_data)
    labels = [string(symb) for symb in symb_list]
    push!(labels, "AR($p) simulated data")
    TimeSeriesPlot(mdata_list, labels)

    # BONE - stuff below this is fucked

    # plot stuff - this is percent change
    plt = plot(percentchange(mdata).AdjClose)
    dates = timestamp(mdata)
    data = (datetime = dates,
            Open = zeros(length(mdata)),
            High = zeros(length(mdata)),
            Low = zeros(length(mdata)),
            Close = zeros(length(mdata)),
            AdjClose = [zeros(p); sim_data])
    ts = TimeArray(data; timestamp = :datetime, meta = "Example")
    plot!(ts.AdjClose, label="AdjClose from AR($p) Simulation")
    display(plt)

    # plot stuff - this is AR simulation into real numbers
    truth_data = values(mdata.AdjClose)
    ARdata = []
    for i in 1:p
        append!(ARdata, 0)
    end
    append!(ARdata, truth_data[1])
    for (cnt, val) in enumerate(values(ts.AdjClose))
        append!(ARdata, ARdata[cnt+p]+ARdata[cnt+p]*val)  # bone, idk if this is right
    end
    plt = plot(truth_data)
    plot!(ARdata)
    display(plt)



end

@doc doc"""
`ARdataPrep()` is a helper function that takes in time history data and returns a data frame with data points at time \$x_t\$ and the corresponding \$x_{t-1}, \hdots, x_{t-p\$ lag values.
    `mdata_list`: list of time histories for symbols in ARnet() function
    `p`: number of lags 
"""
function ARdataPrep(mdata_list, p) 

    # NOTATION:
    #   p = # of lags
    #   k = length of timehistory/timestamps
    #   n = number of symbols/items to track

    # STEP 1: Get lag dates/result dates
    # start by getting date (timestamp) data from first element in list and writing into an array
    # all elements of list should have same length and dates
    
    # initialize empty lists that contain the p-lags of date data and the associated resultant data
    # add lags and associated "result" date
    # these lists are date only so will be lists of (1 x p) and (1 x 1)
    # this will result in two ordered lists: the ith entry of lag_dates is some date in the time series. The ith entry in result_dates is the corresponding list of p lag dates.
    
    # we want to deal with percent change (pc) data
    pc_mdata_list = []
    for mdata in mdata_list
        push!(pc_mdata_list, percentchange(mdata))
    end

    lag_dates = []
    result_dates = []
    rev_timestamps = reverse(timestamp(pc_mdata_list[1]))
    
    for date_index in 1:length(rev_timestamps)-p
        push!(lag_dates, reverse(rev_timestamps[date_index+1:date_index+p]))  # "de-reverse"
        push!(result_dates, rev_timestamps[date_index])
    end


    # STEP 2: Get lag data/result data
    # at this point we have a list of lag dates and associated result dates
    # now we loop through the lists of dates and the different time series sets to create new lists of the time series data that reflects the lists of dates.
    
    lag_values = []
    result_values = []

    n = length(mdata_list)
    
    for i in 1:length(lag_dates)  # loop through list of dates
        pc_result_value = zeros(n, 1)  # pc=percent change, nx1 array of time series value
        pc_lag_value = zeros(n, p)  # pc = percent change, nxp array of corresponding lag values

        for j in 1:n  # loop through time histories 1:n
            lag_date = lag_dates[i]
            result_date = result_dates[i]
            
            # get adjusted close value of time series j at specific date.
            # 1 index is because result is stored in array
            pc_result_value[j, 1] = values(pc_mdata_list[j][result_date].AdjClose)[1] 

            for (date_idx, date) in enumerate(lag_date)
                pc_lag_value[j, date_idx] = values(pc_mdata_list[j][date].AdjClose)[1]  
            end
        end
        push!(lag_values, pc_lag_value)
        push!(result_values, pc_result_value)

    end

    # create data frame with data
    # note that the date data is added for inspection only
    ar_df = DataFrame(LagDates=lag_dates,
                      ResultDates=result_dates,
                      LagValues=lag_values,
                      ResultValues=result_values)
    return ar_df
end


function ARnetTrain(data, p; num_iters=1000)
    # set model hyper params
    learn_rate = 0.0001
    noise_scale = 0.1

    # setup model components
    #opt = Descent(learn_rate)
    opt = ADAM(learn_rate, (0.9, 0.8))
    n, k = size(data[1][1])

    # setup ar-net stuff
    function ar_eval(y_thist)
        y_t = zeros(size(c_intercept))
        y_t += c_intercept
        for k in 1:size(w_i)[1]
            y_t += w_i[k,:,:]*y_thist[:, k]
        end
        y_t += randn(n)*noise_scale  # noise ~ N(0,1*scale) (AWGN)
        return y_t
    end

    # initialize lag weights and intercept
    w_i = rand(p, n, n)
    c_intercept = rand(n)

    # set loss function
    function loss(y_thist,y_res)
        yhat = ar_eval(y_thist)
        lossval = sum((y_res .- yhat).^2)
        lossval = mse(yhat, y_res)
        return lossval
    end

    # train weights and intercept
    @showprogress for iter in 1:num_iters
        train!(loss, params(w_i, c_intercept), data, opt)
    end

    return w_i, c_intercept
end

function ARnetReconstitute(mdata_list, w_i, c, p)

    # BONE - I haven't touched this yet
    
    # weights/intercept were trained on percent change (pc) data so we want to reconstitute the same
    pc_mdata_list = []
    for mdata in mdata_list
        push!(pc_mdata_list, percentchange(mdata))
    end
    
    # figure out number of series included (n) and length of raw time series (k)
    n = length(pc_mdata_list)
    k = length(pc_mdata_list[1])  # all pc_mdata series have same length

    # reconstitute data
    #   first, create empty container to populate
    #   next, get first p time series data points as seed data
    #   finally, simulate forward
    sim_data = zeros(n, k)

    for (mdata_idx, pc_mdata) in enumerate(pc_mdata_list)
        sim_data[mdata_idx,1:p] = values(pc_mdata[1:p].AdjClose)
    end

    # loop through lag data
    for t in p+1:k

        # get lag data and create lazy temporary container
        # do lazy weight multiplication in a for loop
        lag_data = sim_data[:, t-p:t-1]
        for p_i in 1:p
            sim_data[:, t] += w_i[p_i, :, :]*lag_data[:, p_i]
        end
        sim_data[:, t] += c
    end

    # create list of time histories with data
    sim_timestamps = timestamp(pc_mdata_list[1])
    sim_data_list = []
    for i in 1:n
        data = (date = sim_timestamps, 
                AdjClose = sim_data[i,:]
                )
        push!(sim_data_list, TimeArray(data; timestamp=:date, meta="Example"))
    end
    return sim_data_list
end

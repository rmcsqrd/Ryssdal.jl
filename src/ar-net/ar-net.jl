using Flux
using Flux.Optimise
using Flux.Losses
using TimeSeries, MarketData
using ProgressMeter
using DataFrames
using Plots
using LinearAlgebra

"""
"""
function ARnetWrapper(symb::Symbol, p)
    
    # get marketdata
    mdata = yahoo(symb)
    #truncate mdata BONE
    mdata = mdata[length(mdata)-300:length(mdata)]

    # create AR(p) data
    ARdata = ARdataPrep(mdata, p)
    
    # create list of data by zipping lag/result values
    data = collect(zip(ARdata.LagValues, ARdata.ResultValues))
    
    # train model
    w_i, c = ARnet(data, p)

    # reconstitute data
    sim_data = zeros(length(mdata)-p)  # bone, this is 1D vect, not array. this is going to be huge pita for multivariate
    for i in 1:length(mdata)-p
        seed_data = values(percentchange(mdata)[i:p+i-1].AdjClose)
        sim_data[i] = dot(seed_data, w_i)+c[1]
    end
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
        println(val)
        println(ARdata[cnt])
        append!(ARdata, ARdata[cnt+p]+ARdata[cnt+p]*val)  # bone, idk if this is right
    end
    println(ARdata)
    plt = plot(truth_data)
    plot!(ARdata)
    display(plt)



end

function ARdataPrep(mdata, p) # bone add in min/max functionality to truncate data
    # get data in terms of percent change in adjusted closing price
    pc_data = percentchange(mdata).AdjClose

    # initialize empty lists that contain the p-lags of date data and the associated resultant data
    # add lags and associated "result" date
    lag_dates = []
    result_dates = []

    rev_timestamps = reverse(timestamp(pc_data))
    
    for date_index in 1:length(rev_timestamps)-p
        push!(lag_dates, reverse(rev_timestamps[date_index+1:date_index+p]))  # "de-reverse"
        push!(result_dates, rev_timestamps[date_index])
    end

    # take dates and get associated values
    lag_values = []
    result_values = []

    for lag_date_set in lag_dates
        temp_res_array = zeros(1, p)  #BONE, this only works for univariate
        for (idx, date) in enumerate(lag_date_set)
            # [1] index is because we only pass one date and want a scalar, not an array
            temp_res_array[idx] = values(pc_data[date])[1]
        end
        
        push!(lag_values, temp_res_array)
    end

    for res_date in result_dates
        push!(result_values, values(pc_data[res_date])[1])
    end

    # create data frame with data
    # note that the date data is added for inspection only
    ar_df = DataFrame(LagDates=lag_dates,
                      ResultDates=result_dates,
                      LagValues=lag_values,
                      ResultValues=result_values)
    return ar_df
end

function ARnet(data, p)
    # set model hyper params
    num_iters = 1000
    learn_rate = 0.0001
    noise_scale = 0.1

    # setup model components
    #opt = Descent(learn_rate)
    opt = ADAM(learn_rate, (0.9, 0.8))
    n = 1
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

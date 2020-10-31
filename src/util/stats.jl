using Statistics

"""
    Function for computing std deviation of a 1-dimensional (single variable) time series

    INPUT: 
    series (1xn Array): values in a time series (usually stock prices)
    look_behind (int): number of days to look behind
      
    
"""
function TimeSeriesStatistics(series, look_behind; type="normal")
    u = Array{Float64}(undef,length(series))
    mean_error = Array{Float64}(undef,length(series))
    n = length(series)
    tau = n/252  # 252 trading days in a year approx

    for i in max(2,n-look_behind):n
        if type == "log"
            u[i] = log(series[i]/series[i-1])  # we use log returns because it reflects continuous componed interest
        else
            u[i] = series[i]/series[i-1]
        end
    end
    u_bar = mean(u)
    
    for i in max(2,n-look_behind):n
        mean_error[i] = (u[i]-u_bar)^2
    end

    std_dev = sqrt(1/(n-1)*sum(mean_error))/sqrt(tau)

    # BONE stuff above is not working properly need to compute rolling mean
    u = Array{Float64}(undef,length(series))
    mean_error = Array{Float64}(undef,length(series))
    stddev = Array{Float64}(undef,length(series))
    n = length(series)
    tau = n/252  # 252 trading days in a year approx

    for i in look_behind+1:n

        # do mean stuff
        temp_series = series[i-look_behind:i]
        window_mean = mean(temp_series)
        mean_error[i] = window_mean
        
        # do stddev stuff
        temp_mean = Array{Float64}(undef, length(temp_series))
        for j in 1:length(temp_mean)
            temp_mean[j] = (temp_series[j]-window_mean)^2
        end
        stddev[i] = sqrt((1/length(temp_mean))*sum(temp_mean))

    end

    return mean_error, stddev

end

function BlackScholes_Euro(S, X, r, Tmax, std_dev, opttype="Call")
    
    # compute params
    
end

function KellyCriterion(p, c)
    # p = probability
    # c = winning ration, assumes c:1 odds
    f = 0:0.001:1 
    Ereturn = zeros(size(f))
    for i in 1:length(Ereturn)
       Ereturn[i] = p*log(1+c*f[i])+(1-p)*log(1-f[i])
    end

   

    # truncate because we want to get rid of -inf divergence on plot
    Ereturn_plot = Ereturn[Ereturn .> -0.1]
    f_plot = f[1:length(Ereturn_plot)]
    plot(f_plot, Ereturn_plot, label="p=$p, c=$c")
    xlabel!("Ratio of bet to total bankroll (%)")
    ylabel!("Expected Wealth Return")
end


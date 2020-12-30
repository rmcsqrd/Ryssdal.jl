using Flux
using Flux.Optimise
using Flux.Losses
using ProgressMeter

"""
"""
function ARnetWrapper(timehist, p)
    
    # prep data
    data = TimehistDataPrep(timehist, p)

    # train model
    w_i, c = ARnet(data, p)

    # return weights and intercept
    return w_i, c, data

end

function ARnet(data, p)
    # set model hyper params
    num_iters = 1000
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

function TimehistDataPrep(timehist, p)
    # prepare data - timehist is (n x k) array
    #   n = number of variables
    #   k = number of steps in timehist
    # this gets put into a (k-p-1 x n x p) training data array
    # the truth data is a  (k-p-1 x n x 1) result array
    if length(size(timehist)) == 1 # implies k dim vect, not array
        timehist = reshape(timehist, (1,size(timehist)[1]))
    end
                                                         
    n = size(timehist)[1]
    k = size(timehist)[2]

    # check that number of lags is valid
    if p >= k
        error("p must be < k")
    end

    # initialize empty containers
    train_data = zeros(k-p, n, p)
    train_result = zeros(k-p, n, 1)
    
    # pack containers
    for i in 1:k-p
        train_data[i,:,:] = timehist[:, i:i+p-1]
        train_result[i,:,:] = timehist[:, i+p]
    end
    
    # process data and return
    dataset = []
    for i in 1:size(train_data)[1]
        push!(dataset, (train_data[i,:,:], train_result[i,:,:]))
    end
    return dataset
end

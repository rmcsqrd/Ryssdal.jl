using Flux

"""
"""
function ARnet(timehist, p)
    
    # prepare data - timehist is (n x k) array
    #   n = number of variables
    #   k = number of steps in timehist
    # this gets put into a (k-p-1 x n x p) training data array
    # the truth data is a  (k-p-1 x n x 1) result array
    if length(size(timehist)) == 1 # implies k dim vect, not array
        k = size(timehist)[1]
        n = 1
    else
        n = size(timehist)[1]
        k = size(timehist)[2]
    end

    train_data = zeros(k-p, n, p)
    train_result = zeros(k-p, n, 1)

    println("k=$k, n=$n, p=$p")
    #println("train_data=\n$train_data")
    #println("train_result=\n$train_result")
    #println("timehist=\n$timehist")
    #println(size(train_data))
    #for i in 1:size(train_data)[1]
        #end
    for i in 1:k-p
        train_data[i,:,:] = timehist[:, i:i+p-1]
        train_result[i,:,:] = timehist[:, i+p]
    end

    for i in 1:size(train_data)[1]
        println(train_data[i, :, :])
        println(train_result[i, :, :])
        println()
    end



    


end

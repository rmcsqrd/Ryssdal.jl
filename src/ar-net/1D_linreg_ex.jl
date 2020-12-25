using Flux
using Flux.Optimise
using Flux.Losses

# inspired by https://www.dianacai.com/blog/2020/04/13/machine-learning-julia-flux-autodiff/

function trainexample()
    x = Vector(1:10)
    y = x .* 2

    predict(x) = A*x+b
    A = rand(1)
    b = rand(1)

    function loss(x,y)
        ypred = predict(x)
        sum((y .- ypred).^2)
    end

    optimizer = Descent(0.01)

    # in the below loop, the "train!(...)" section is equivalent to
    #   for i in 1:length(x)
    #       grads = gradient(() -> loss(x[i], y[i]), params(A,b))
    #       for p in (A, b)
    #           update!(optimizer, p, grads[p])
    #       end
    #   end

    for iter in 1:1000
        train!(loss, params(A,b), zip(x,y), optimizer)
    end
    println("x = ", x)
    println("y = ", y)
    println("y=Ax+b, computed A = ", A)
    println("computed b = ", b)
end

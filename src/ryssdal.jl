module ryssdal

using Revise

## internal

include("api/api_call.jl")
include("api/api_types.jl")
include("demo/example1.jl")
include("util/plot_wrapper.jl")
include("util/stats.jl")
include("ar-net/1D_linreg_ex.jl")
include("ar-net/ar-net.jl")



end # module

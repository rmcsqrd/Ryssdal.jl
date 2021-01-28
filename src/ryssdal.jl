module ryssdal

using Revise

## internal

# example stuff
include("demo/example1.jl")
include("demo/1D_linreg_ex.jl")

# ARnet training stuff
include("ar-net/ar-net.jl")

# data packaging
include("yolo-parse/data_unpack.jl")

# utilities
include("util/stats.jl")
include("util/plot_utils.jl")

end # module

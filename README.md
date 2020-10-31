# Ryssdal.jl
Statistics/modeling toolset geared towards financial modeling.

[Installation](#installationusage)  
[API Access](#api-access)  
[Examples](#examples)  

![Example Time History Plot](https://raw.githubusercontent.com/rmcsqrd/Ryssdal.jl/master/aux/README/stocks.png)


## Installation/Usage
```
    $ cd path/to/your/directory
    $ git clone https://github.com/rmcsqrd/Ryssdal.jl.git
    $ cd Ryssdal.jl
    $ julia
    julia> ]
    (v1.x) pkg> activate .
    julia> using ryssdal
    julia> ryssdal.[command]([inputs])  // execute commands this way
```

## API Access
This package uses the [Alphavantage stock API](https://www.alphavantage.co/documentation/) for collecting historical stock data. The `api_call.jl` file contains functionality for making API calls. It uses a dummy API key (at the time of writing the API did not verify if the API key was valid or not). The `api_types.jl` file contains common API call types (time series daily, time series daily adjusted, etc) for convenience when interacting with the API.

## Examples
Several examples have been written to demonstrate usage. Example functions can be found in the `/demo` folder.

#### Example 1
__Usage:__
```
    julia> ryssdal.example1()
```

__What is happening__  
This function is an example of a Alphavantage API call - stock prices/call types are set in the example1() function. It also demonstrates how to unpack the returned json file and interface with the time history plotting functions. The returned data is then stored locally to reduce the number of times the API needs to be called.

#### Example 2
__Usage:__
```
    julia> ryssdal.example2(10, "TSLA")
```

__What is happening__  
In the above code we pass in two inputs:
- Window Size
- Ticker Symbol

This function the processes the returned data and computes a rolling average based on the previous number of entries specified by the "Window Size" parameter. It also computes the standard deviation.

![Example Time History Plot](https://raw.githubusercontent.com/rmcsqrd/Ryssdal.jl/master/aux/README/stddev.png)


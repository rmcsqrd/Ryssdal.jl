## Package Functionality
- fix absolute positioning for dataDir variable in AlphaVantage_API_Call
- when it reads if the file or not compare the time stamp of the most recent data vs current state
	maybe use the date in the filename and compare it to Dates.today() because Julia is sick and 
	allows for comparisons like that
- add market cap viewing option
- fix graphing max date because it goes past data values
- add in error handling if you exceed API free limits (5 calls per minute)
- move API to yahoo via https://github.com/JuliaQuant/MarketData.jl- add in fred API via https://github.com/markushhh/FredApi.jl
- figure out if TimeSeries.jl is useful

## Math Stuff
- look at stats for different stocks (mean, covariance, etc) and plot that
- augmented Dickey-Fuller Test
- Johanssen test
- PPP, REER, BEER convergence models
- maybe some sort of basket trading KF that uses several correlated stocks as the measurement step to define an unobservable state space. 
	would be tricky to define F matrix but maybe you could use some sort of ML algorithm. You could even run it at each time step in case
	the "dynamics" are time variant. 
- pairs trading
- basket trading

## Cosmetic Stuff
- subplots with stationarity, etc (maybe display on main plot as well with shaded areas and stuff)
- some sort of nice looking gui interface with drop downs and such



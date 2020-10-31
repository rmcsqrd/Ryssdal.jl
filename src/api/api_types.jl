
"""
    Helper function to return a struct used for common API calls
    INPUT (string): API call you want. Types:
                        "Daily_Adjusted": daily close price adjusted (accounts for stock splits)
                        "Daily": daily close price (doesn't account for splits)
    RETURN (struct): API call struct based on input
"""
# parameters to pass to API call, reference https://www.alphavantage.co/documentation/ for alternate params
struct alphavantage_api_struct_t
    function_name::String
    output_size::String
    time_type::String
end


function API_Types(type)

    # define types of calls
    alphavantage_daily_adjusted = alphavantage_api_struct_t(
                                                            "TIME_SERIES_DAILY_ADJUSTED",
                                                            "full",
                                                            "5. adjusted close")
    alphavantage_daily = alphavantage_api_struct_t(
                                                   "TIME_SERIES_DAILY",
                                                   "full",
                                                   "4. close")

    # return appropriate struct
    if type == "Daily_Adjusted"
        return alphavantage_daily_adjusted
    elseif type == "Daily"
        return alphavantage_daily
    end
end

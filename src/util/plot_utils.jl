struct PlotLabels
    title::String
    xlabel::String
    ylabel::String
end

function TimeSeriesARSimPlot(timeseries_list, label_list, plot_labels)
    n = length(timeseries_list)
    plot(layout = (n,1), show=true)
    for subplot_id in 1:n
        for (ts_idx, timeseries) in enumerate(timeseries_list[subplot_id])
            plot!(timeseries.AdjClose, 
                  label=label_list[subplot_id][ts_idx],
                  subplot=subplot_id
                 )
        end
    end
end

function PlotWSBData(timeseries_list, label_list, plot_labels; overwrite=true)
    if overwrite == true
        plot(layout=(1,1))
    end
    for (ts_idx, timeseries) in enumerate(timeseries_list)
        plot!(timeseries,
              label=label_list[ts_idx],
              #seriestype=:scatter,  # looks okay
              seriestype=:bar,  # too dense with year of data
              fillalpha=0.25,
              #seriestype=:line,  # looks okay for smaller time intervals
              #marker=:circle,
              #markeralpha=0.75,
              #markersize=2,
              legend=:topleft,
             )
    end
    title!(plot_labels.title)
    xlabel!(plot_labels.xlabel)
    ylabel!(plot_labels.ylabel)
end

function PlotStockData(timeseries_list, label_list, plot_labels)
    combined_series = MergeSeries(timeseries_list)
    plot!(twinx(), 
          combined_series,
          legend=:top,
          label="",
          yaxis=:log,
          ylabel=plot_labels.ylabel,
         )
    title!(plot_labels.title)
end

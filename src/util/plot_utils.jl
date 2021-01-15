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

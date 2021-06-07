using DataFrames, Dash, DashHtmlComponents, DashCoreComponents, PlotlyJS, Statistics
#using EconoSim

include("loreco_sim.jl")

function balanceConsumers(a::Actor)::Union{Missing, Number}
    if in(:consumer, getproperty(a, :types)) return sumsy_balance(a.balance)
    else return missing
    end
end

function balanceBakers(a::Actor)::Union{Missing, Number}
    if in(:baker, getproperty(a, :types)) return sumsy_balance(a.balance)
    else return missing
    end
end

function balanceTVMerchants(a::Actor)::Union{Missing, Number}
    if in(:tv_merchant, getproperty(a, :types)) return sumsy_balance(a.balance)
    else return missing
    end
end

function balanceGovernance(a::Actor)::Union{Missing, Number}
    if in(:governance, getproperty(a, :types)) return sumsy_balance(a.balance)
    else return missing
    end
end



function missMinimum(values) return isempty(skipmissing(values)) ? NaN : minimum(skipmissing(values)) end
function missMaximum(values) return isempty(skipmissing(values)) ? NaN : maximum(skipmissing(values)) end
function miss5thPercentile(values) return isempty(skipmissing(values)) ? NaN : quantile(skipmissing(values), 0.05) end
function miss95thPercentile(values) return isempty(skipmissing(values)) ? NaN : quantile(skipmissing(values), 0.95) end
function missMean(values) return isempty(skipmissing(values)) ? NaN : mean(skipmissing(values)) end
function missMedian(values) return isempty(skipmissing(values)) ? NaN : median(skipmissing(values)) end


app = dash()

app.layout = html_div() do
    html_h1("Per period SumSy balance"),
    dcc_graph(id = "totalsumsy"),
    #dcc_graph(id = "spreadsumsy"),
    html_label(children="Gegarandeerd inkomen"),
    dcc_input(id="sumsy_gincome", type="number", min=0, step=100, value=2000),
    html_label(children="Demurragevrije buffer"),
    dcc_input(id="sumsy_demfree", type="number", min=0, step=500, value=25000),
    html_label(children="Demurrage percentage"),
    dcc_input(id="sumsy_dem", type="number", min=0, step=0.05,max = 100, value=0.1),
    html_label(children="Periode interval"),
    dcc_input(id="sumsy_interval", type="number", min=1, value=30),
    html_label(children="Start sumsybedrag"),
    dcc_input(id="sumsy_seed", type="number", min=0, step=100, value=5000),
    html_label(children="Aantal consumenten"),
    dcc_input(id="n_consumers", type="number", min=1, value=380),
    html_label(children="Aantal bakkerijen"),
    dcc_input(id="n_bakers", type="number",  min=1, value=15),
    html_label(children="Aantal tv handelaren"),
    dcc_input(id="n_tv_merchants", type="number",  min=1, value=5),
    html_label(children="Aantal periodes"),
    dcc_input(id="n_periods", type="number",  min=10, step=10, value=10),
    html_button(id = "submit-button-state", children = "Run", n_clicks = 0)
end

callback!(
    app,
    Output("totalsumsy", "figure"),
    #Output("spreadsumsy", "figure"),
    Input("submit-button-state", "n_clicks"),
    State("n_periods", "value"),
    State("sumsy_gincome", "value"),
    State("sumsy_demfree", "value"),
    State("sumsy_dem", "value"),
    State("sumsy_interval", "value"),
    State("sumsy_seed", "value"),
    State("n_consumers", "value"),
    State("n_bakers", "value"),
    State("n_tv_merchants", "value"),
) do n_clicks, n_periods, sumsy_gincome, sumsy_demfree, sumsy_dem, sumsy_interval, sumsy_seed, n_consumers, n_bakers, n_tv_merchants
    adata= [(balanceConsumers, missMinimum), (balanceConsumers, missMaximum), (balanceConsumers, miss5thPercentile) , (balanceConsumers, miss95thPercentile), (balanceConsumers, missMean), (balanceConsumers, missMedian),
        (balanceBakers, missMinimum), (balanceBakers, missMaximum), (balanceBakers, miss5thPercentile) , (balanceBakers, miss95thPercentile), (balanceBakers, missMean), (balanceBakers, missMedian),
        (balanceTVMerchants, missMinimum), (balanceTVMerchants, missMaximum), (balanceTVMerchants, miss5thPercentile) , (balanceTVMerchants, miss95thPercentile), (balanceTVMerchants, missMean), (balanceTVMerchants, missMedian),
        (balanceGovernance, missMinimum), (balanceGovernance, missMaximum), (balanceGovernance, miss5thPercentile) , (balanceGovernance, miss95thPercentile), (balanceGovernance, missMean), (balanceGovernance, missMedian)]
    #adata = [(balance,minimum),(balance,sum),(balance,maximum), (balance, mean),(balance, median), (balance, std)]
    model = init_loreco_model(SuMSy(sumsy_gincome, sumsy_demfree, sumsy_dem, sumsy_interval, seed = sumsy_seed),
    n_consumers, n_bakers, n_tv_merchants)
    data, _ = run!(model, actor_step!, econo_model_step!, n_periods; adata)
    print(data[1:5,:])

    dataC = stack(data, [:missMinimum_balanceConsumers, :missMaximum_balanceConsumers, :miss5thPercentile_balanceConsumers, :miss95thPercentile_balanceConsumers, :missMean_balanceConsumers, :missMedian_balanceConsumers], :step)
    dataB = stack(data, [:missMinimum_balanceBakers, :missMaximum_balanceBakers, :miss5thPercentile_balanceBakers, :miss95thPercentile_balanceBakers, :missMean_balanceBakers, :missMedian_balanceBakers], :step)
    dataT = stack(data, [:missMinimum_balanceTVMerchants, :missMaximum_balanceTVMerchants, :miss5thPercentile_balanceTVMerchants, :miss95thPercentile_balanceTVMerchants, :missMean_balanceTVMerchants, :missMedian_balanceTVMerchants], :step)
    dataG = stack(data, [:missMinimum_balanceGovernance, :missMaximum_balanceGovernance, :miss5thPercentile_balanceGovernance, :miss95thPercentile_balanceGovernance, :missMean_balanceGovernance, :missMedian_balanceGovernance], :step)

    #print(data1[:,:])
    plotConsumers = Plot(dataC, x = :step, y = :value, group = :variable ,mode="lines")
    plotBakers = Plot(dataB, x = :step, y = :value, group = :variable ,mode="lines")
    plotTVMerchants = Plot(dataT, x = :step, y = :value, group = :variable ,mode="markers")
    plotGovernance = Plot(dataG, x = :step, y = :value, group = :variable ,mode="markers")
    return ([plotConsumers plotBakers
     plotTVMerchants plotGovernance])

end

#run_server(app, "0.0.0.0", parse(Int,ARGS[1]); debug = true)
run_server(app, "0.0.0.0"; debug = true)

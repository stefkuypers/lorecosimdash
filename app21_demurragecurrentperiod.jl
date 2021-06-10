using DataFrames, Dash, DashHtmlComponents, DashCoreComponents, PlotlyJS, Statistics
#using EconoSim

include("loreco_sim.jl")
include("loreco_app.jl")

app = dash()

app.layout = html_div() do
    html_h1("Per period SumSy balance"),
    dcc_graph(id = "totalsumsy"),
    #dcc_graph(id = "spreadsumsy"),
    html_label(children="Gegarandeerd inkomen"),
    dcc_input(id="sumsy_gincome", type="number", min=0, step=100, value=2000),
    html_label(children="Demurragevrije buffer"),
    dcc_input(id="sumsy_demfree", type="number", min=0, step=500, value=0),
    html_label(children="Demurrage percentage"),
    dcc_input(id="sumsy_dem", type="number", min=0, step=0.05,max = 100, value=0.1),
    html_label(children="Periode interval"),
    dcc_input(id="sumsy_interval", type="number", min=1, value=2),
    html_label(children="Start sumsybedrag"),
    dcc_input(id="sumsy_seed", type="number", min=0, step=100, value=5000),
    html_label(children="Aantal consumenten"),
    dcc_input(id="n_consumers", type="number", min=1, value=10),
    html_label(children="Aantal bakkerijen"),
    dcc_input(id="n_bakers", type="number",  min=1, value=5),
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
) do n_clicks, n_periods, guaranteed_income, dem_free, dem, interval, seed, consumers, bakers, tv_merchants

    model = init_loreco_model_sumsy(;guaranteed_income, dem_free,dem, interval, seed, consumers, bakers, tv_merchants)
    adata = [(balance,sum), (demurragecurrentperiod, sum)]
    mdata = [demurrageviamodel]
    data, modeldata = run!(model, actor_step!, econo_model_step!, n_periods; adata, mdata)
    println(data[:,:])
    println(modeldata[:,:])
    #println(model.step)
    data1 = stack(data, [:sum_balance, :sum_demurragecurrentperiod], :step)
    #print(data1[:,:])
    pMin = Plot(data1, x = :step, y = :value, group = :variable ,mode="markers")
    return pMin
end

function demurrageviamodel(model)

    #println(typeof(model))
    sumdemurrageC::Float64 = 0
    mindemurrageC::Float64 = 999999999
    maxdemurrageC::Float64 = 0
    meandemurrageC::Float64 = 0
    mediandemurrageC::Float64 = 0

    sumdemurrageCngi::Float64 = 0
    mindemurrageCngi::Float64 = 0
    maxdemurrageCngi::Float64 = 0
    meandemurrageCngi::Float64 = 0
    mediandemurrageCngi::Float64 = 0

    sumdemurrageB::Float64 = 0
    mindemurrageB::Float64 = 0
    maxdemurrageB::Float64 = 0
    meandemurrageB::Float64 = 0
    mediandemurrageB::Float64 = 0

    sumdemurrageT::Float64 = 0
    mindemurrageT::Float64 = 0
    maxdemurrageT::Float64 = 0
    meandemurrageT::Float64 = 0
    mediandemurrageT::Float64 = 0

    sumdemurrage::Float64 = 0

    #println(filter(consumer, allagents(model)))
    #println(allagents(model))
    consumers = Iterators.filter(consumer, allagents(model))
    println(typeof(consumers))
    for x in allagents(model)

    #    print(typeof(x))
        demurrages = filter(tuple-> let (time, type, entry, amount, comment)=tuple; isCurrentDemurTransaction(comment, time, model.step) end,
                      collect(x.balance.transactions))
        if !isempty(demurrages)
            sumdemurrage = sumdemurrage - demurrages[1][4]
            if consumer(x)
                sumdemurrageC = sumdemurrageC - demurrages[1][4]
                if (-demurrages[1][4] < mindemurrageC) mindemurrageC = -demurrages[1][4] end
                if (-demurrages[1][4] > maxdemurrageC) maxdemurrageC = -demurrages[1][4] end
            elseif consumerngi(x)
                sumdemurrageCngi = sumdemurrageCngi - demurrages[1][4]
            elseif baker(x)
                sumdemurrageB = sumdemurrageB - demurrages[1][4]
            elseif tvmerchant(x)
                sumdemurrageT = sumdemurrageT - demurrages[1][4]
            end
        end
        #println(string(": ",demurrages))
    end
    #println(string(": ",sumdemurrage))
    #peek(allagents(model))
#    demurrages = filter(tuple-> let (time, type, entry, amount, comment)=tuple; isDemurTransaction(comment, time) end,
#              collect(balance.transactions))
    #println(model.step)
    return [sumdemurrageC sumdemurrageCngi sumdemurrageB sumdemurrageT]
end

function isCurrentDemurTransaction(comment::String, time::Integer, modelstep::Integer)::Bool
    if startswith(comment, "Demurrage") & isequal(time, modelstep)
        return true
    else return false
    end
end
#run_server(app, "0.0.0.0", parse(Int,ARGS[1]); debug = true)
run_server(app, "0.0.0.0"; debug = true)

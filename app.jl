using DataFrames, Dash, DashHtmlComponents, DashCoreComponents, DashBootstrapComponents, PlotlyJS, Statistics
using EconoSim

include("loreco_sim.jl")
include("loreco_app.jl")

app = dash(external_stylesheets=[dbc_themes.BOOTSTRAP])

demurfree = 25000
tiersvec = [(25000,10.0), (30000,15.0), (40000,20.0)]


app.layout = dbc_container(html_div([
    dbc_row(dbc_col([
        #html_div("A single column"),
        html_h1("LoREco Simulation"),
        dbc_alert("Input parameters", color="success"),
        html_div([
            dbc_row([
                dbc_col([
                    html_label(children="Gegarandeerd inkomen "),
                    dcc_input(id="sumsy_gincome", type="number", min=0, step=100, value=2000),
                    html_br(),
                    html_label(children="Startbedrag deelnemers "),
                    dcc_input(id="sumsy_seed", type="number", min=0, step=100, value=5000),
                ], width=12),
                dbc_col([
                    html_label(children="Aantal consumenten met gegarandeerd inkomen "),
                    dcc_input(id="n_consumers_gi", type="number", min=1, value=200),
                    html_br(),
                    html_label(children="Aantal consumenten zonder gegarandeerd inkomen "),
                    dcc_input(id="n_consumers_notgi", type="number", min=0, value=180),
                    html_br(),
                    html_label(children="Aantal bakkerijen "),
                    dcc_input(id="n_bakers", type="number",  min=1, value=15),
                    html_br(),
                    html_label(children="Aantal tv handelaren "),
                    dcc_input(id="n_tv_merchants", type="number",  min=1, value=5),
                    html_br()

                ], width=12),
            ], className="border"),
            dbc_row([
                dbc_col([
                    html_div([
                        html_div(id = "bufferdiv", children = [
                            html_label(children="Demurragevrije buffer"),
                            dcc_input(id="sumsy_demfree", type="number", min=0, step=500, value=25000),
                            html_button(id = "set_sumsy_demfree",  children = "Set buffer", n_clicks = 0),
                            html_label(id="buffernotification")
                            ]),
                        html_div(id = "addtierdiv", children = [
                            html_label("Add tier:"),
                            dcc_input(id="addtiervalue", type="number", min=500, step=500, value=1000, placeholder="Bedrag"),
                            dcc_input(id="addtierperc", type="number",  min=0, step=0.25, max=100, value = 5, placeholder="Percentage"),
                            html_button(id = "addtier",  children = "voeg tier toe", n_clicks = 0),
                            html_label(id="tiernotification")
                        ]),
                        html_div(id = "tiersoverviewdiv", children = [
                            html_label("Tiers set:"),
                            html_ul(id="tiersul")
                        ])
                    ])
                ], width=12,  className="border"),
                dbc_col([
                    html_label(children="Inflow common good"),
                    dcc_input(id="commongood_perc", type="number", min=0, step=0.25,max = 100, value=50),
                    html_br(),
                    html_label(children="Frequency common good project decision (in months)"),
                    dcc_input(id="projectdecision_periods", type="number", min=1, step=1, value=4),
                    html_br(),
                    html_label(children="Allowed project per decision"),
                    dcc_input(id="projects_count", type="number", min=1, step=1, value=4),
                ], width=12, className="border")
            ] ),
            dbc_row([
                dbc_col([
                    html_label(children="Simulatieduur in aantal maanden "),
                    dcc_input(id="n_periods", type="number",  min=1, step=1, value=2),
                    html_button(id = "submit-button-state", children = "Run", n_clicks = 0),
                ], width=12, className="border")
            ])
        ])
    ])),
    html_br(),
    dbc_alert("Data visualizations", color="success"),
    dbc_row([
        dbc_col([html_h3("Per period SumSy balance"), dcc_graph(id = "totalsumsy")], width=12),
        dbc_col([html_h3("Per period Consumers SumSy balance"), dcc_graph(id = "sumsyconsumers")], width=12),
        dbc_col([html_h3("Per period Consumers without GI SumSy balance"), dcc_graph(id = "sumsyconsumersngi")], width=12),
        dbc_col([html_h3("Per period Bakers SumSy balance"), dcc_graph(id = "sumsybakers")], width=12),
        dbc_col([html_h3("Per period TV Merchants SumSy balance"), dcc_graph(id = "sumsytvmerchants")], width=12),
        dbc_col([html_h3("Per period Governance balance"), dcc_graph(id = "sumsygovernance")], width=12),
    ]),
    dbc_row([
        dbc_col([html_h3("Per period SumSy Demurrage"), dcc_graph(id = "totaldemurrage")], width=12),
        dbc_col([html_h3("Per period Consumers SumSy Demurrage"), dcc_graph(id = "demurrageconsumers")], width=12),
        dbc_col([html_h3("Per period Consumers without GI SumSy Demurrage"), dcc_graph(id = "demurrageconsumersngi")], width=12),
        dbc_col([html_h3("Per period Bakers SumSy Demurrage"), dcc_graph(id = "demurragebakers")], width=12),
        dbc_col([html_h3("Per period TV Merchants SumSy Demurrage"), dcc_graph(id = "demurragetvmerchants")], width=12),
        dbc_col([html_h3("Per period Governance Demurrage"), dcc_graph(id = "demurragegovernance")], width=12),
    ]),
]), className="p-5")

callback!(app, Output("tiersul", "children"),  Output("sumsy_demfree","value"), Output("buffernotification", "children"), Output("tiernotification", "children"), Input((type= "removetier_", index= ALL), "n_clicks"), Input("set_sumsy_demfree", "n_clicks"), Input("addtier", "n_clicks"),State("sumsy_demfree","value"), State("addtiervalue", "value"), State("addtierperc", "value")) do removetiers, set_sumsy_demfree, addtier, sumsy_demfree, addtiervalue, addtierperc
    #println("starting")

    if !isempty(getfield(callback_context(), :triggered))
        trig = getfield(callback_context(), :triggered)[1][:prop_id]
        value = getfield(callback_context(), :triggered)[1][:value]
    else
        trig=""
    end
    #println("triggered by: " * trig)
    buffernotification = ""
    if trig == "set_sumsy_demfree.n_clicks"
        println("setting sumsy demfree")
        setdemur(sumsy_demfree)
    end
    tiernotification = ""
    if trig == "addtier.n_clicks"
        println("adding sumsy tier")
        println(addtiervalue)
        println(addtierperc)
        println(typeof(addtiervalue))
        println(typeof(addtierperc))
        if !isnothing(addtiervalue) && !isnothing(addtierperc)
            addatier2(addtiervalue, addtierperc)
            tiernotification = ""
        else
            tiernotification = "Bedrag en/of percentage zijn niet gegeven of incorrect."
        end
    end
    if occursin("removetier_",trig)
        removetier(removetiers)
    end

    sort!(tiersvec, by=first)
    #println(typeof(tiersvec))
    #println(tiersvec)
    demurli = html_li(children = [html_label("Vanaf 0: demurragevrij")])
    #tiersli = [html_li(children = [html_label("Vanaf " * string(i[1]) * ": " * string(i[2]) * "% ") html_button(id = "removetier" * string(i[1]), children = "verwijder tier", n_clicks = 0)]) for i in tiersvec]
    tiersli = [html_li(children = [html_label("Vanaf " * string(i[1]) * ": " * string(i[2]) * "% ") html_button(id = (type="removetier_", index = i[1]), children = "verwijder tier", n_clicks = 0)]) for i in tiersvec]
    tiersul_children = [demurli; tiersli]
    return (tiersul_children, !isempty(tiersvec) ? tiersvec[1][1] : "" , buffernotification, tiernotification)
end

callback!(
    app,
    Output("totalsumsy", "figure"),
    Output("sumsyconsumers", "figure"),
    Output("sumsyconsumersngi", "figure"),
    Output("sumsybakers", "figure"),
    Output("sumsytvmerchants", "figure"),
    Output("sumsygovernance", "figure"),
    Output("totaldemurrage", "figure"),
    Output("demurrageconsumers", "figure"),
    Output("demurrageconsumersngi", "figure"),
    Output("demurragebakers", "figure"),
    Output("demurragetvmerchants", "figure"),
    Output("demurragegovernance", "figure"),
    Input("submit-button-state", "n_clicks"),
    State("n_periods", "value"),
    State("sumsy_gincome", "value"),
    State("sumsy_demfree", "value"),
#    State("sumsy_dem", "value"),#TODO: in stead the vector of tiers should be in a hidden field
    State("sumsy_seed", "value"),
    State("n_consumers_gi", "value"),
    State("n_consumers_notgi", "value"),
    State("n_bakers", "value"),
    State("n_tv_merchants", "value"),
    State("commongood_perc", "value"),
    State("projectdecision_periods", "value"),
    State("projects_count", "value"),
) do n_clicks, n_periods, guaranteed_income, dem_free, seed, n_consumers_gi, n_consumers_notgi, bakers, tv_merchants, commongood_perc, projectdecision_periods, projects_count
    if isempty(getfield(callback_context(), :triggered)) throw(PreventUpdate()) end
    adata= [(balance,sum), (demurrage, sum), (balance, sum, governance), (demurrage, sum, governance),
        (balance, minimum, consumer), (balance, maximum, consumer), (balance, mean, consumer), (balance, median, consumer),
        (balance, minimum, consumerngi), (balance, maximum, consumerngi), (balance, mean, consumerngi), (balance, median, consumerngi),
        (balance, minimum, baker), (balance, maximum, baker), (balance, mean, baker), (balance, median, baker),
        (balance, minimum, tvmerchant), (balance, maximum, tvmerchant), (balance, mean, tvmerchant), (balance, median, tvmerchant),
        (demurrage, minimum, consumer), (demurrage, maximum, consumer), (demurrage, mean, consumer), (demurrage, median, consumer),
        (demurrage, minimum, consumerngi), (demurrage, maximum, consumerngi), (demurrage, mean, consumerngi), (demurrage, median, consumerngi),
        (demurrage, minimum, baker), (demurrage, maximum, baker), (demurrage, mean, baker), (demurrage, median, baker),
        (demurrage, minimum, tvmerchant), (demurrage, maximum, tvmerchant), (demurrage, mean, tvmerchant), (demurrage, median, tvmerchant)]
    #adata = [(balance,minimum),(balance,sum),(balance,maximum), (balance, mean),(balance, median), (balance, std)]

    #dem = dem / 100
    interval = 30
    consumers = n_consumers_gi
    consumersngi = n_consumers_notgi
    #println(consumers)
    #println(consumersngi)
    #model = init_loreco_model_sumsy(;guaranteed_income, dem_free,dem, interval, seed, consumers, bakers, tv_merchants)
    #model = init_loreco_model_sumsy_tiers(;guaranteed_income, dem_free,tiersvec, interval, seed, consumers, bakers, tv_merchants)
    model = init_loreco_model_sumsy_tiers_consumersngi(;guaranteed_income, dem_free,tiersvec, interval, seed, consumers, consumersngi, bakers, tv_merchants)
    data, _ = run!(model, actor_step!, econo_model_step!, n_periods*30; adata)
    #print(data[1:5,:])

    dataM = stack(data, :sum_balance, :step)
    dataMC = stack(data, [:minimum_balance_consumer, :maximum_balance_consumer, :mean_balance_consumer, :median_balance_consumer], :step)
    dataMCngi = stack(data, [:minimum_balance_consumerngi, :maximum_balance_consumerngi, :mean_balance_consumerngi, :median_balance_consumerngi], :step)
    dataMB = stack(data, [:minimum_balance_baker, :maximum_balance_baker, :mean_balance_baker, :median_balance_baker], :step)
    dataMT = stack(data, [:minimum_balance_tvmerchant, :maximum_balance_tvmerchant, :mean_balance_tvmerchant, :median_balance_tvmerchant], :step)
    dataMG = stack(data, :sum_balance_governance, :step)
    dataD = stack(data, :sum_demurrage, :step)
    dataDC = stack(data, [:minimum_demurrage_consumer, :maximum_demurrage_consumer, :mean_demurrage_consumer, :median_demurrage_consumer], :step)
    dataDCngi = stack(data, [:minimum_demurrage_consumerngi, :maximum_demurrage_consumerngi, :mean_demurrage_consumerngi, :median_demurrage_consumerngi], :step)
    dataDB = stack(data, [:minimum_demurrage_baker, :maximum_demurrage_baker, :mean_demurrage_baker, :median_demurrage_baker], :step)
    dataDT = stack(data, [:minimum_demurrage_tvmerchant, :maximum_demurrage_tvmerchant, :mean_demurrage_tvmerchant, :median_demurrage_tvmerchant], :step)
    dataDG = stack(data, :sum_demurrage_governance, :step)

    #print(dataG[:,:])
    plotMoney = Plot(dataM, x = :step, y = :value, group = :variable ,mode="lines")
    plotMoneyConsumers = Plot(dataMC, x = :step, y = :value, group = :variable ,mode="lines")
    plotMoneyConsumersNGI = Plot(dataMCngi, x = :step, y = :value, group = :variable ,mode="lines")
    plotMoneyBakers = Plot(dataMB, x = :step, y = :value, group = :variable ,mode="lines")
    plotMoneyTVMerchants = Plot(dataMT, x = :step, y = :value, group = :variable ,mode="lines")
    plotMoneyGovernance = Plot(dataMG, x = :step, y = :value, group = :variable ,mode="lines")
    plotDemurrage = Plot(dataD, x = :step, y = :value, group = :variable ,mode="lines")
    plotDemurrageConsumers = Plot(dataDC, x = :step, y = :value, group = :variable ,mode="lines")
    plotDemurrageConsumersNGI = Plot(dataDCngi, x = :step, y = :value, group = :variable ,mode="lines")
    plotDemurrageBakers = Plot(dataDB, x = :step, y = :value, group = :variable ,mode="lines")
    plotDemurrageTVMerchants = Plot(dataDT, x = :step, y = :value, group = :variable ,mode="lines")
    plotDemurrageGovernance = Plot(dataDG, x = :step, y = :value, group = :variable ,mode="lines")
    return (plotMoney, plotMoneyConsumers, plotMoneyConsumersNGI, plotMoneyBakers, plotMoneyTVMerchants, plotMoneyGovernance,
        plotDemurrage, plotDemurrageConsumers, plotDemurrageConsumersNGI, plotDemurrageBakers, plotDemurrageTVMerchants, plotDemurrageGovernance)

end



function setdemur(value)
    #if (value < 0) throw(PreventUpdate())
    demurfree = value
    for i = 1:length(tiersvec)
        println(tiersvec[i][1])
    end
    while(true)
        if !isempty(tiersvec) && tiersvec[1][1] < value
            splice!(tiersvec, 1)
        else
            break
        end
    end
    if value != 0 && !isempty(tiersvec) tiersvec[1] = (value,tiersvec[1][2]) end
end

function addatier2(tier, perc)
    for i = 1:length(tiersvec)
        if tiersvec[i][1] == tier
            splice!(tiersvec, i)
            break
        end
    end
#    if (tier < demurfree) demurfree = tier end
    append!(tiersvec, [(tier, perc)])
end

function removetier(removetiers)
    println(removetiers)
    i = 1
    while(i <= length(removetiers))
        #println(removetiers[i])
        if removetiers[i] == 1
            splice!(tiersvec, i)
            break
        end
        i += 1
    end
    println(tiersvec)
end



run_server(app, "0.0.0.0", parse(Int,ARGS[1]); debug = true)
#run_server(app, "0.0.0.0"; debug = true)

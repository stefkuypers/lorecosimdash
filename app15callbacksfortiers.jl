using DataStructures, DataFrames, Dash, DashHtmlComponents, DashCoreComponents, PlotlyJS, Statistics
#using EconoSim

#include("loreco_sim.jl")

app = dash(suppress_callback_exceptions = true)



demfreeyesno = [
    Dict("label" => "Nee", "value" => "false"),
    Dict("label" => "Ja", "value" => "true")
]

demurfree = 25000

tiersvec = [(25000,10.0), (30000,15.0), (40000,20.0)]

app.layout = html_div() do
    html_div(id = "bufferdiv", children = [
        html_label(children="Demurragevrije buffer"),
        dcc_input(id="sumsy_demfree", type="number", min=0, step=500, value=25000),
        html_button(id = "set_sumsy_demfree",  children = "Set buffer", n_clicks = 0),
        html_label(id="buffernotification")
        ]),
    html_div(id = "addtierdiv", children = [
        html_label("Add tier:"),
        dcc_input(id="addtiervalue", type="number", min=0, step=500, placeholder="Bedrag"),
        dcc_input(id="addtierperc", type="number",  min=0, step=0.25, max=100, placeholder="Percentage"),
        html_button(id = "addtier",  children = "voeg tier toe", n_clicks = 0),
        html_label(id="tiernotification")
    ]),
    html_div(id = "tiersoverviewdiv", children = [
        html_label("Tiers set:"),
        html_ul(id="tiersul")
    ]),
    html_div(id = "empty")
end
#=
callback!(app, [Output("empty", "children")], ) do removetiers
    println(getfield(callback_context(), :triggered))
    println(removetiers)
    if !isempty(getfield(callback_context(), :triggered))
        println("removing")

    end
    return ["Ok"]
end
=#
callback!(app, Output("tiersul", "children"),  Output("buffernotification", "children"), Output("tiernotification", "children"), Input((type= "removetier_", index= ALL), "n_clicks"), Input("set_sumsy_demfree", "n_clicks"), Input("addtier", "n_clicks"),State("sumsy_demfree","value"), State("addtiervalue", "value"), State("addtierperc", "value")) do removetiers, set_sumsy_demfree, addtier, sumsy_demfree, addtiervalue, addtierperc
    println("starting")

    if !isempty(getfield(callback_context(), :triggered))
        trig = getfield(callback_context(), :triggered)[1][:prop_id]
        value = getfield(callback_context(), :triggered)[1][:value]
    else
        trig=""
    end
    println("triggered by: " * trig)
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
        if !isnothing(addtiervalue) && !isnothing(addtierperc)
            addtier(addtiervalue, addtierperc)
            tiernotification = ""
        else
            tiernotification = "Bedrag en/of percentage zijn niet gegeven."
        end
    end
    if occursin("removetier_",trig)
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
    #if getfield(callback_context(), :triggered)[0]
    #=if sumsy_demfree_yesno == "true"
        sumsy_demfree_type = "number"
        tiersvec[1] = (sumsy_demfree, tiersvec[1][2])
    else
        sumsy_demfree_type = "hidden"
        tiersvec[1] = (0, tiersvec[1][2])
    end=#


    sort!(tiersvec, by=first)

    demurli = html_li(children = [html_label("Vanaf 0: demurragevrij")])
    #tiersli = [html_li(children = [html_label("Vanaf " * string(i[1]) * ": " * string(i[2]) * "% ") html_button(id = "removetier" * string(i[1]), children = "verwijder tier", n_clicks = 0)]) for i in tiersvec]
    tiersli = [html_li(children = [html_label("Vanaf " * string(i[1]) * ": " * string(i[2]) * "% ") html_button(id = (type="removetier_", index = i[1]), children = "verwijder tier", n_clicks = 0)]) for i in tiersvec]
    tiersul_children = [demurli; tiersli]
    return (tiersul_children, buffernotification, tiernotification)
end

function setdemur(value)
    #if (value < 0) throw(PreventUpdate())
    demurfree = value
    if !isempty(tiersvec) tiersvec[1] = (value,tiersvec[1][2]) end
end
function addtier(value, perc)
    append!(tiersvec, [(value, perc)])
end
function removetier()

end
#=
callback!(app, Output("sumsy_demfree", "type"), Input("sumsy_demfree_yesno", "value")) do sumsy_demfree_yesno
    print(sumsy_demfree_yesno)
    if sumsy_demfree_yesno == "true"
        return "number"
    else
        return "hidden"
    end
end
=#


run_server(app, "0.0.0.0", debug=true)

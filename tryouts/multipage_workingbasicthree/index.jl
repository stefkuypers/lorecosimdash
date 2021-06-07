using DashHtmlComponents, DashCoreComponents

include("app.jl")
include("layouts.jl")
include("callbacks.jl")


app.layout = html_div() do
    dcc_location(id="url"),
    html_div(id="page-content")
end



callback!(app, Output("page-content", "children"), Input("url", "pathname")) do pathname
    #println(pathname)
    if pathname == "/app1"
        layout1
    elseif pathname == "/app2"
        layout2
    elseif pathname == "/app3"
        layout3
    elseif pathname =="/"
        html_div() do
            dcc_link("Parameter space", href="app1"),
            html_br(),
            dcc_link("ABM run", href="app2"),
            html_br(),
            dcc_link("ABM multi-run", href="app3")
        end
    else
        "404"
    end
end



#run_server(app, "0.0.0.0", parse(Int64,ARGS[1]))
run_server(app, "0.0.0.0", debug=true)

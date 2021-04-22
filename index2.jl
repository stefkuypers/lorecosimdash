using DashHtmlComponents, DashCoreComponents

include("app8.jl")
include("layouts.jl")
include("callbacks.jl")


app.layout = html_div() do
    dcc_location(id="url"),
    html_div(id="page-content")
end



callback!(app, Output("page-content", "children"), Input("url", "pathname")) do pathname
    println(pathname)
    if pathname == "/app1"
        layout1
    elseif pathname == "/app2"
        layout2
    elseif pathname =="/"
        html_div() do
            dcc_link("Navigate to /page-1", href="app1"),
            html_br(),
            dcc_link("Navigate to /page-2", href="app2")
        end
    else
        "404"
    end
end


run_server(app, "0.0.0.0", parse(Int,ARGS[1]); debug = true)
#run_server(app, "0.0.0.0", debug=true)

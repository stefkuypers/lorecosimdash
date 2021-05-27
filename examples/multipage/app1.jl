module app1
using DashHtmlComponents, DashCoreComponents

include("app8.jl")

layout = html_div() do
    #dcc_input(id = "input-3", value = "initial value", type = "text"),
    #html_div(id="output-1")
    html_h3("App 1_"),
    # represents the URL bar, doesn't render anything
    dcc_input(id = "input-3", value = "initial value", type = "text"),
    html_div(id="output-1"),


    dcc_link("Navigate to /", href="/"),
    html_br(),
    dcc_link("Navigate to /page-2", href="app2")

    # content will be rendered in this element
    #html_div(id="page-content")


end

callback!(app, Output("output-1", "children"), Input("input-3", "value")) do input_value
    print("test")
    return "You've entered $(input_value)"
end

end

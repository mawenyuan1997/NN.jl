type SequentialNet <: ANN
    layers :: Array{Layer}
    lossfn :: LossCriteria
    function SequentialNet(layers::Array{Layer}, lossfn::LossCriteria)
        return new(layers, lossfn)
    end
end

function forward(net::SequentialNet, x::Array{Float64}, label::Array; kwargs...)
    local inp = x
    for i = 1:length(net.layers)
        inp = forward(net.layers[i], inp; kwargs...)
    end
    loss, pred = forward(net.lossfn, inp, label; kwargs...)
    # println("Network bastract loss:$(loss)")
    return loss, pred
end

function backward(net::SequentialNet, label)
    local dldy = backward(net.lossfn, label)
    for i = length(net.layers):-1:1
        dldy = backward(net.layers[i], dldy)
    end
    return dldy
end
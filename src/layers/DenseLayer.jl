# Define the Fully Connected layers
type DenseLayer <: Layer
    i           :: Int64
    W           :: Array{Float64}
    last_input  :: Array{Float64}
    last_output :: Array{Float64}
    last_dldy   :: Array{Float64}
    last_loss   :: Array{Float64}
    last_diff   :: Array{Float64}
    gradi       :: Array{Float64}

    function DenseLayer(i::Int64, o::Int64; init_type = "Uniform")
        # Use Glorot initialization: http://lasagne.readthedocs.io/en/latest/modules/init.html#r5
        #local newW = zeros(i+1,o)
        local newW
        if init_type == "Uniform"
            local a    = sqrt(12. / (i + o))
            newW = rand(i+1,o)* 2 * a - a
        elseif init_type == "Normal"
            local sigma = sqrt(2. / (i + o))
            newW  = randn(i+1,o) * sqrt(sigma)
        elseif init_type == "Random"
            newW = rand(i+1,o) - 0.5
        end
        newW[i+1,:] = zeros(o)
        # save the original input size
        return new(i, newW, zeros(i), zeros(o), zeros(o), zeros(i),
                   zeros(i+1, o), zeros(i+1, o))
    end
end

verbose = 0

function forward(l::DenseLayer, X::Union{SubArray{Float64,2},Array{Float64,2}}; kwargs...)
    # X      : NxI matrix, N is the mini batch size, I is the input size
    # Output : NxO matrix
    @assert size(X)[2] == l.i

    if size(l.last_input,1)  != size(X,1) ||
       size(l.last_output,1) != size(X,1)
      l.last_input = Array{Float64}(size(X,1), l.i + 1)
      l.last_output = Array{Float64}(size(X,1), size(l.W,2))
    end
    # Pad one at the end of the vector
    l.last_input[:,1:l.i] = X
    l.last_input[:,l.i+1] = 1

    # Multiplication inplaces
    A_mul_B!(l.last_output, l.last_input, l.W)
    return l.last_output
end

function backward(l::DenseLayer, DLDY::Union{SubArray{Float64,2},Array{Float64,2}}; kwargs...)
    @assert size(DLDY,2) == size(l.W,2)
    if size(l.last_loss,1) != size(DLDY,1)
      l.last_dldy = Array{Float64}(size(DLDY,1),size(DLDY,2))
      l.last_loss = Array{Float64}(size(DLDY,1),l.i+1)
    end
    l.last_dldy = DLDY
    A_mul_Bt!(l.last_loss, DLDY, l.W)
    return view(l.last_loss, :, 1:l.i)
end

function gradient(l::DenseLayer)
  At_mul_B!(l.gradi, l.last_input, l.last_dldy)
  return l.gradi
end

function getParam(l::DenseLayer)
    return l.W
end

function setParam!(l::DenseLayer, theta::Array{Float64})
    @assert size(l.W) == size(theta)
    broadcast!(-, l.last_diff, theta, l.W)
    # l.last_diff = theta - l.W
    l.W = theta
end

function getVelocity(l::DenseLayer)
    return l.last_diff
end

# l = DenseLayer(784, 800)
# X = rand(500, 784) #input size 784, batch size 500
# Y = rand(500, 800)
#
# println("First time (compiling...)")
# @time forward(l,X)
# @time backward(l,Y)
# @time gradient(l)
#
# println("Second time (profiling...)")
# @time begin
#   for i = 1:1000
#     forward(l,X)
#   end
# end
# @time begin
#   for i = 1:1000
#     backward(l,Y)
#   end
# end
# @time begin
#   for i = 1:1000
#     gradient(l)
#   end
# end

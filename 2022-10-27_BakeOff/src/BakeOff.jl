module BakeOff

using CairoMakie
using CSV
using DataFrames
using KernelDensity: kde
using Statistics: quantile

include("readData.jl")
include("plot_functions.jl")

end

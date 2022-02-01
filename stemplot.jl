using Plots, MAT, Sound; default(markerstrokecolor=:auto, label="")
using Statistics

file = "proj1.mat"
x = vec(matread(file)["song"]); S = 7999; sound(x, S)
n = 2:length(x)-1;
c2 = (x[n .+ 1] + x[n .- 1]) ./ 2x[n];
y = reshape([0; c2; 0], 2000, :)[2:end-1,:]
freqs = (S/2pi) * acos.(y);
f4 = vec(mean(freqs, dims=1));
freqs = unique(round.(f4, digits=2))
@show midi = 69 .+ round.(Int, 12 * log2.(freqs/440))

V = [0 .5 .75 1 1.25 1.5 1.75 2 2.5 2.75 3 3.25 3.5 4 4.25 4.5];
v = V[midi .- 63]


plot(v, line=:stem, marker=:circle, markersize = 10, color=:black)
plot!(size = (800,200)) # size of plot
plot!(widen=true) # try not to cut off the markers
plot!(xticks = [], ylims = (-0.7,4.7)) # for staff
yticks!(0:4, ["E", "G", "B", "D", "F"]) # helpful labels for staff lines
#plot!(axis=nothing, border=:none) # ignore this
plot!(yforeground_color_grid = :blue) # blue staff, just for fun
plot!(foreground_color_border = :white) # make border "invisible"
plot!(gridlinewidth = 1.5)
plot!(gridalpha = 0.9) # make grid lines more visible
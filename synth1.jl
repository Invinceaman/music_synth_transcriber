using Gtk
using Sound: sound
using MAT
using Statistics
using Plots; default(markerstrokecolor=:auto, label="")

# initialize two global variables used throughout
S = 7999 # sampling rate (samples/second) for this low-fi project
song = Float32[] # initialize "song" as an empty vector

function miditone(midi::Int; nsample::Int = 2000)
    f = 440 * 2^((midi-69)/12) # compute frequency from midi number - FIXED!
    x = cos.(2pi*(1:nsample)*f/S) # generate sinusoidal tone
    sound(x, S) # play note so that user can hear it immediately
    global song = [song; x] # append note to the (global) song vector
    return nothing
end

# define the white and black keys and their midi numbers - FIXED
white = ["G" 67; "A" 69; "B" 71; "C" 72; "D" 74; "E" 76; "F" 77; "G" 79]
black = ["G" 68 2; "A" 70 4; "C" 73 8; "D" 75 10; "F" 78 14]

g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)

# define the "style" of the black keys
sharp = GtkCssProvider(data="#wb {color:white; background:black;}")
end_style = GtkCssProvider(data="#wr {color:black; background:red;}")
clear_style = GtkCssProvider(data="#wc {color:black; background:yellow;}")
transcribe_style = GtkCssProvider(data="#tc {color:white; background:blue;}")
# FIXED add a style for the end button

for i in 1:size(white,1) # add the white keys to the grid
    key, midi = white[i,1:2]
    b = GtkButton(key) # make a button for this key
    signal_connect((w) -> miditone(midi), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 2] = b # put the button in row 2 of the grid
end
for i in 1:size(black,1) # add the black keys to the grid
    key, midi, start = black[i,1:3]
    b = GtkButton(key * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> miditone(midi), b, "clicked") # callback
    g[start .+ (0:1), 1] = b # put the button in row 1 of the grid
end


function end_button_clicked(w) # callback function for "end" button
    println("The end button")
    sound(song, S) # play the entire song when user clicks "end"
    matwrite("proj1.mat", Dict("song" => song); compress=true) # save song to file
end

ebutton = GtkButton("end") # make an "end" button
push!(GAccessor.style_context(ebutton), GtkStyleProvider(end_style), 600)
set_gtk_property!(ebutton, :name , "wr")
g[1:5, 3] = ebutton # fill up entire row 3 of grid - why not?
signal_connect(end_button_clicked, ebutton, "clicked") # callback
# FIXED set style of the "end" button

function clear_button_clicked(w)
    println("clear button pressed")
    global song = Float32[]
    return nothing
end

clearbutton = GtkButton("clear")
push!(GAccessor.style_context(clearbutton), GtkStyleProvider(clear_style), 600)
set_gtk_property!(clearbutton, :name , "wc")
g[6:10, 3] = clearbutton
signal_connect(clear_button_clicked, clearbutton, "clicked")

function transcribe_button_clicked(w)
    println("transcribing")
    matwrite("proj1.mat", Dict("song" => song); compress=true) # stores the song in a mat file
    file = "proj1.mat"
    x = vec(matread(file)["song"]); sound(x, S) # reads the song from the file and plays the song
    n = 2:length(x)-1;
    c2 = (x[n .+ 1] + x[n .- 1]) ./ 2x[n]; # calculates all of the differences for the arccos formula
    y = reshape([0; c2; 0], 2000, :)[2:end-1,:] #divides them into sections for every 2 seconds for processing
    freqs = (S/2pi) * acos.(y); # runs these samples through the arccos formula
    f4 = vec(mean(freqs, dims=1)); #creates a list of frequencies for each of the notes in the song
    freqs = round.(f4, digits=2) 
    midinum = 69 .+ round.(Int, 12 * log2.(freqs/440)) #converts the frequency to a MIDI number

    V = [0 .5 .75 1 1.25 1.5 1.75 2 2.5 2.75 3 3.25 3.5 4 4.25 4.5]; #heights of different notes for plotting
    v = V[midinum .- 63] #creates the list of notes ready for plotting


    p = plot(v, line=:stem, marker=:circle, markersize = 10, color=:black)
    plot!(size = (800,200)) # size of plot
    plot!(widen=true) # try not to cut off the markers
    plot!(xticks = [], ylims = (-0.7,4.7)) # for staff
    yticks!(0:4, ["E", "G", "B", "D", "F"]) # helpful labels for staff lines
    #plot!(axis=nothing, border=:none) # ignore this
    plot!(yforeground_color_grid = :blue) # blue staff, just for fun
    plot!(foreground_color_border = :white) # make border "invisible"
    plot!(gridlinewidth = 1.5)
    plot!(gridalpha = 0.9) # make grid lines more visible
    display(p)
end

transcribe_button = GtkButton("transcribe")
push!(GAccessor.style_context(transcribe_button), GtkStyleProvider(transcribe_style), 600)
set_gtk_property!(transcribe_style, :name , "tc")
g[11:16, 3] = transcribe_button
signal_connect(transcribe_button_clicked, transcribe_button, "clicked")


win = GtkWindow("gtk3", 400, 300) # 400×300 pixel window for all the buttons
push!(win, g) # put button grid into the window
showall(win); # display the window full of buttons

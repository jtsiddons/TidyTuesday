using Downloads: download
using DataFrames, CSV								# Packages for reading data
using Dates, Statistics
using CairoMakie, Colors, ElectronDisplay			# Plotting

include("../gruv_theme.jl");
set_theme!(theme_gruvbox_light());

@info "Done with loading packages"

 # Load data
 href = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2022/2022-03-22/babynames.csv";
 df = CSV.File(download(href), stringtype=String) |> DataFrame;
 
 # Summary table
@show describe(df)

# Data Scientists love to use copies.
dfc = copy(df);
dfc.name = String.(strip.(dfc.name));

# Let's see which name is most popular in each year
#
# I'll do a descending sort on `n`, then I can just pick the
# first row for each subdataframe from year and sex
dfcPopularName = combine(
						 groupby(
								 sort(dfc, :n, rev=true), 
								 [:year, :sex]),
						 first
						 );

@show dfcPopularName

# What is the most popular name of all time (for each sex - this is the name for the column & 
# I am going to assume that it corresponds to the sex assigned at birth)
MostPopularNames = combine(
						   groupby(dfc, [:name, :sex]),
						  :n => sum => :n
						  )
sort!(MostPopularNames, :n, rev=true);
MostPopularNames = combine(
						   groupby(MostPopularNames, :sex),
						   first
						   );
@show MostPopularNames
# James and Mary are the most common names for M & F respectively. 
#
# How do the number of babies with these names change over time?
dfcJamesMary = filter(r -> r.name ∈	MostPopularNames.name, dfc)

# Here I immediately notice a problem, I need to clean the names in dfc - some have leading or trailing spaces - I've added a line above to correct this. Having done this, I realise that there are instances of female James and male Mary. This isn't an issue, I can filter these out. 

filter!(
		(r -> 
			(r.name == "James" && r.sex == "M") | 
			(r.name == "Mary" && r.sex == "F")
		),
		dfcJamesMary)

FJM = Figure(resolution = (900, 400));
AJM = Axis(FJM[1,1], ylabel="Count", xlabel="Year")

dfcJames = filter(r -> r.name == "James", dfcJamesMary)
dfcMary  = filter(r -> r.name == "Mary",  dfcJamesMary)

lines!(AJM, 
	   dfcJames.year, dfcJames.n
	   )

lines!(AJM, 
	   dfcMary.year,  dfcMary.n
	   ) 

text!(AJM, 
	  "James", 
	  position = (dfcJames.year[end]+1, dfcJames.n[end]), 
	  align=(:left, :center))

text!(AJM, 
	  "Mary", 
	  position = (dfcMary.year[end]+1, dfcMary.n[end]), 
	  align=(:left, :center))

xlims!(AJM, (minimum(dfc.year)-5, maximum(dfc.year)+15));
AJM.ytickformat = "{:d}"
AJM.xticks = 1890:20:2010
AJM.title = "Number of babies named James or Mary each year";

save("James_Mary_per_year.png",FJM)

# Which year is each of these most popular?
@show combine(
			  groupby(
					  sort(dfcJamesMary, :n, rev=true), :name),
			  first)

# James and Mary were had the highest number of babies in 1947 and 1921 respectively, with 5-6% of all M & F babies in that year with those names.

# For fun, let's look at my name
nms = ["Joseph", "Terence"]
dfcMe = filter(r -> r.name ∈ nms, dfc[dfc.sex .== "M",:])

dfcMe = combine(
				groupby(dfcMe, :year),
				:n => sum => :n
				)

Fme = Figure(resolution = (900, 400))
Ame = Axis(Fme[1,1], xlabel = "Year", ylabel = "Count", title = "Number of babies named Joseph or Terence in each year")
lines!(Ame, dfcMe.year, dfcMe.n)
vlines!(Ame, [1988], color=colorant"#cc241d")
Ame.ytickformat = "{:d}"
Ame.xticks = 1890:20:2010
save("JT_per_year.png",Fme)

# Plot to see distribution of top 10 baby names for each sex over years.
# Sort of a violin plot with males ↑ and females ↓.

# We have a frequency table. A quick function to get median year for
# vertical lines on plot - show median year for each name
function getmedyear(yr, ns)
	opts = []
	for (y, n) in zip(yr, ns)
		opts = vcat(opts, ones(n).*y)
	end
	return median(opts)
end
	
# Get top 10 names for each sex
f10(x) = first(x, 10);
n10 = combine(
			  groupby(dfc, [:name, :sex]),
			  :n => sum => :n)
mn10 = f10(sort(n10[n10.sex .== "M",:], :n, rev=true)).name
fn10 = f10(sort(n10[n10.sex .== "F",:], :n, rev=true)).name

# Colour specifications for the plots - consistent with above.
bl = colorant"#458588"
rd = colorant"#cc241d"

F = Figure(resolution=(900, 1000));
Label(F[1,:], "Baby Names!", tellwidth=false, tellheight=true, textsize=30, justification=:left, halign=:left)
A = Axis(F[2,1], xlabel="Year", title="When the babies with 10 most popular names were born.\nMedian year for each name is solid black line.\nMost popular names are James and Mary, although both are on decline.\n\n", titlesize=18);

tks = []
tklbs = []

mmx = maximum(dfc[dfc.sex .== "M",:].n)
fmx = maximum(dfc[dfc.sex .== "F",:].n)

yrng = [minimum(dfc.year), maximum(dfc.year)]

for i in 1:10
	j = 11 - i
	tm = filter(r->(r.name == mn10[i] && r.sex == "M"), dfc)
	tf = filter(r->(r.name == fn10[i] && r.sex == "F"), dfc)
	
	myr = getmedyear(tm.year, tm.n)
	fyr = getmedyear(tf.year, tf.n)

	# Normalise count by maximum (for all names)
	tm.n = tm.n ./ (3*mmx) .+ j
	tf.n = j .- tf.n ./ (3*fmx)

	# Get upper/lower limit on "violin" for median year
	if isinteger(myr)
		myr_y = tm.n[findfirst(==(myr), tm.year)]
	else
		myr_y = mean([
					  tm.n[findfirst(==(round(myr, RoundUp)), tm.year)],
					  tm.n[findfirst(==(round(myr, RoundDown)), tm.year)]
					  ])
	end

	if isinteger(fyr)
		fyr_y = tf.n[findfirst(==(fyr), tf.year)]
	else
		fyr_y = mean([
					  tf.n[findfirst(==(round(fyr, RoundUp)), tf.year)],
					  tf.n[findfirst(==(round(fyr, RoundDown)), tf.year)]
					  ])
	end

	lines!(A, yrng, [j,j], color=colorant"#282828", linewidth=1) 

	aval = 0.08*j + 0.1
	# Violins - have transparency and borders
	band!(A, tm.year, j.*ones(nrow(tm)), tm.n, color=(bl, aval))
	band!(A, tf.year, tf.n, j.*ones(nrow(tf)), color=(rd, aval))	
	lines!(A, tm.year, tm.n, color=bl, linedstyle=:solid)
	lines!(A, tf.year, tf.n, color=rd, linedstyle=:solid)

	# Median Years
	lines!(A, [myr, myr], [j, myr_y], color=colorant"#282828", linestyle=:solid)
	lines!(A, [fyr, fyr], [fyr_y, j], color=colorant"#282828", linestyle=:solid)
	
	# Add names for yticks
	push!(tks, j+1/6, j-1/6)
	push!(tklbs, mn10[i], fn10[i])
	
end
A.yticks = (tks, tklbs)
A.xticks = 1890:20:2010

save("top10_baby_names_per_year.png", F)

using BakeOff
using Cascadia
using CSV
using DataFrames
using HTTP
using Gumbo

df = csv_to_df("./data/bakers.csv")
url = "https://en.wikipedia.org/wiki/"

## Automatically Find Longitude and Latitude for each hometown

# lon = Vector{Float64}(undef, nrow(df))
# lat = Vector{Float64}(undef, nrow(df))

# for (i, location) in enumerate(df.hometown)
#   
#     println(i, " | ", location)
#     location = split(location, "/")[1]
#     location1 = split(location, ",")[1]
#     location1 = replace(location1, " "=>"_")
#     location = replace(location, " "=>"_")
#     # # location1 = replace(location1, r"^_"=>"")
#     # # location1 = replace(location1, r"_$"=>"")
#     println(location1)

#     r = HTTP.get(url*location1)
#     body = String(r.body) |> parsehtml
#     tag = Selector(".geo")
#     matches = eachmatch(tag, body.root[2])
#     if length(matches) == 0
#         @info "Not found match for " * location1 ". Trying " * location
#         sleep(2)
#         r = HTTP.get(url*location)
#         body = String(r.body) |> parsehtml
#         matches = eachmatch(tag, body.root[2])
#     end
#     if length(matches) == 0
#         @info "Not found match for " * location * ". Setting to -0.7, 51.3 (London) and continuing"
#         lat[i] = 51.3
#         lon[i] = -0.7
#         continue
#     end
#     lat[i], lon[i] = matches[1].children[1].text |> x -> split(x, ";") .|> x -> parse(Float64, x)
#     println(location1, " | ", lon[i], " : ", lat[i])
#     sleep(2)
# end

# df.lon = lon
# df.lat = lat

## Manually fixing the rest

s = select(df, [:hometown, :lon, :lat])
not_found = findall(row -> row.lon == -0.7 && row.lat == 51.3, eachrow(df))
for i in not_found
    println(i, " | ", s.hometown[i], " | ", s.lon[i], " : ", s.lat[i])
end

# Durham
# 54.7761; -1.5733
df.lon[79] = -1.5733
df.lat[79] = 54.7761
df.lon[113] = -1.5733
df.lat[113] = 54.7761

# North London
# 51.52604; -0.103475 (Clerkenwell - Just need an approx location!)
df.lon[89] = -0.103475
df.lat[89] = 51.52604
df.lon[95] = -0.103475
df.lat[95] = 51.52604

# County Tyrone
# 54.598; -7.309 (Omagh - County Town)
df.lon[99] = -7.309
df.lat[99] = 54.598

# Newport
# 51.583; -3.000
df.lon[100] = -3.0
df.lat[100] = 51.583

# West Midlands
# 52.48000; -1.90250 (Birmingham)
df.lon[107] = -1.90250
df.lat[107] = 52.48

# Halifax
# 53.725; -1.863
df.lon[109] = 53.725
df.lat[109] = -1.893

# Rainham
# 51.36; 0.61 (Assuming Kent not London)\
df.lon[117] = 0.61
df.lat[117] = 51.36

CSV.write("./data/bakers.csv", df)
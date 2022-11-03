using BakeOff
using CSV
using Cascadia
using DataFrames
using Gumbo
using HTTP

df = csv_to_df("./data/bakers.csv")
url = "https://thegreatbritishbakeoff.co.uk/bakers/"
dest = "./data/baker_img/"

# Baker name is in format of `baker`. If baker is an instance of a name that 
# has already occurred then `-n` is added, from 2 onwards.

processed_names = Dict{String,Int64}()

tag = Selector("img.attachment-baker-profile")

for row in eachrow(df)
    local name = row.baker
    local season = row.series
    @info "Processing baker: " * name * ". From season: " * string(season) * "."
    local local_filename = dest * name * "_" * string(season) * ".jpg"
    if haskey(processed_names, name)
        processed_names[name] += 1
        name *= "-" * string(processed_names[name])
        @info "Modified to: " * name
    else
        processed_names[name] = 1
    end

    if isfile(local_filename)
        @info "Already have image for " * name * ". Continuing to next baker."
        continue
    end
    r = HTTP.get(url * name)
    body = String(r.body) |> parsehtml
    matches = eachmatch(tag, body.root[2])
    image_www = matches[1].attributes["src"]
    HTTP.download(image_www, local_filename)
    sleep(2 + rand())
end

using Downloads: download

url = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2022/2022-10-25/"
files_www = [
            "bakers.csv",
            "challenges.csv",
            "episodes.csv",
            "ratings.csv"
            ]

for file in files_www
    download(url * file, "./data/" * file)
end

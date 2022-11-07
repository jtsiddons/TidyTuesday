import pandas as pd
import numpy as np
import seaborn as sns
import seaborn.objects as so
import matplotlib.pylab as plt

file = "./data/horror_movies.csv"
df = pd.read_csv(file, parse_dates=["release_date"])

# Filter the data
df = df.query("vote_count >= 10")
# For convenient selecting of films. Select only films within collection with dominant Language of collection.
df["collection_lang"] = df["collection_name"] + "_" + df["original_language"]

selected_films = df["collection_lang"].value_counts().head(15).index.values

# Select films
df = df[df["collection_lang"].isin(selected_films)]

# Clean names
df["collection_name"] = (
    df["collection_name"].str.replace(" Collection", "").str.replace(" Series", "")
)

# Expand languages
df["original_language"] = df["original_language"].replace(
    {
        "en": "English",
        "ja": "Japanese",
        "ko": "Korean",
        "ru": "Russian",
        "it": "Italian",
        "es": "Spanish",
        "hi": "Hindi",
    }
)

## Plot colours
white = "#ebdbb2"
black = "#282828"
gray = "#928374"

gruv = [
    "#458588",
    "#cc241d",
    "#d79921",
    "#98971a",
    "#b16286",
    "#689d61",
    "#a89984",
]

ax = (
    so.Plot(
        df,
        x="vote_average",
        y="collection_name",
        text="collection_name",
        color="original_language",
    )
    .add(so.Bar(edgecolor=white, edgewidth=2, alpha=1), so.Agg("median"))
    .scale(color=gruv)
    .add(
        so.Text(color=black, halign="right", fontsize=20, offset=10),
        so.Agg(lambda x: x.quantile(0.25)),
    )
    .add(
        so.Range(color=white),
        so.Est(errorbar=lambda x: (x.quantile(0.25), x.quantile(0.75))),
    )
    .label(
        title="Ratings of Horror Films Within Collections",
        x="Median Film Rating",
        y="Collection",
        color="Original Language\nof Collection",
    )
    .scale(y=so.Nominal())
    .theme(
        {
            "figure.figsize": (16, 9),
            "figure.facecolor": black,
            "figure.edgecolor": white,
            "grid.color": white,
            "grid.linestyle": "dashed",
            "grid.alpha": 0.5,
            "xtick.labelcolor": white,
            "ytick.labelleft": False,
            "axes.facecolor": black,
            "axes.titlecolor": white,
            "axes.titlesize": 30,
            "axes.titleweight": "bold",
            "axes.titlepad": 20,
            "axes.labelcolor": white,
            "axes.edgecolor": white,
            "axes.spines.right": False,
            "axes.spines.top": False,
            "axes.spines.bottom": False,
            "axes.spines.left": False,
            "legend.facecolor": white,
            "legend.labelcolor": black,
            "legend.framealpha": 1,
            "legend.edgecolor": white,
        }
    )
)

# ax.show()
ax.save("./figs/collection_rating.png", bbox_inches="tight")

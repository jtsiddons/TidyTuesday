# Tidy Tuesday: 2022-05-24

This week I will be working in R.

## Women's Rugby

Copied from [TT](https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2022/2022-05-24/readme.md)

The data this week comes from [ScrumQueens](https://www.scrumqueens.com/page/results-dashboard) by way of [Jacquie Tran](https://github.com/rfordatascience/tidytuesday/issues/439).

Scrumqueen can be found on Twitter [@ScrumQueens](https://twitter.com/ScrumQueens)

> We write about women's rugby & women in rugby. Volunteers with a passion for equality in our brilliant sport - by [@alidonnelly](https://twitter.com/alidonnelly) &  [@johnlbirch](https://twitter.com/johnlbirch).

[Per Wikipedia](https://en.wikipedia.org/wiki/World_Rugby_Women%27s_Sevens_Series)

> The series, the women's counterpart to the World Rugby Sevens Series, provides elite-level women's competition between rugby nations. As with the men's Sevens World Series, teams compete for the title by accumulating points based on their finishing position in each tournament.

### Data Dictionary

#### `sevens.csv`

|variable   |class     |description |
|:----------|:---------|:-----------|
|row_id     |double    | Row ID for each observation |
|date       |double    | ISO date|
|team_1     |character | Team 1 |
|score_1    |character | Score for Team 1|
|score_2    |character | Score for team 2 |
|team_2     |character | Team 2 |
|venue      |character | Location of game |
|tournament |character | Tournament name |
|stage      |character | Stage of tournament   |
|t1_game_no |double    | Team 1 game number |
|t2_game_no |double    | Team 2 game number |
|series     |double    | Series number |
|margin     |double    | Margin of victory (diff between score 1/2)|
|winner     |character | Winner of match |
|loser      |character | Loser of match |
|notes      |character | Misc notes|

#### `fifteens.csv`

|variable          |class     |description |
|:-----------------|:---------|:-----------|
|test_no           |double    | Test number |
|date              |double    | ISO date |
|team_1            |character | Team 1 name  |
|score_1           |double    | Score for team 1  |
|score_2           |double    | Score for team 2|
|team_2            |character | Team 2 name |
|venue             |character | Location of tournament |
|home_test_no      |double    | Home number |
|away_test_no      |double    | Away game number |
|series_no         |double    | Series number |
|tournament        |character | Tournament type |
|margin_of_victory |double    | Margin of victory (diff of score 1/2) |
|home_away_win     |character | Home or away team won |
|winner            |character | Winner name |
|loser             |character | Loser name |

### Cleaning Script

``` r
library(tidyverse)

raw_df <- read_csv("2022/2022-05-24/Scrumqueens-data-2022-05-23.csv")

clean_df <- raw_df |> 
  janitor::clean_names() |> 
  glimpse() |> 
  rename(row_id = x1)

clean_df |> 
  write_csv('2022/2022-05-24/sevens.csv')

raw_15 <- read_csv("2022/2022-05-24/Scrumqueens-data-2022-05-23 (1).csv")

clean_15 <- raw_15 |> 
  janitor::clean_names() 

clean_15 |> 
  write_csv('2022/2022-05-24/fifteens.csv')

create_tidytuesday_dictionary(clean_df)
```

### Get the data

```sh
mkdir data
cd data
wget https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2022/2022-05-24/sevens.csv
wget https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2022/2022-05-24/fifteens.csv
cd ..
```

## Questions?

* Do teams with a strong 15s squad also have a strong 7s squad?
* Is there a significant benefit being the `home` team?
* Who has the highest win:loss ratio?
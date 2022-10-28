export csv_to_df

"""
    csv_to_df(file_name::String)::DataFrame

Loads the csv file given by `file_name` into a DataFrame.
"""
function csv_to_df(file_name::String)::DataFrame
    return CSV.File(file_name, stringtype=String) |> DataFrame
end


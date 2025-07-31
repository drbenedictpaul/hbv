# ===================================================================
# FILE: preprocess_data.jl (Definitive, Corrected Version)
# ===================================================================
module DataPreprocessor

export preprocess_data

using DataFrames, Statistics, CSV

function preprocess_data(filepath::String)
    println("\n--- Starting Final Data Preprocessing ---")
    df_raw = CSV.read(filepath, DataFrame)
    println("Loaded $(nrow(df_raw)) patient records.")

    # --- Step 1: Column Selection ---
    features_to_keep = [
        :Age, :Gender, Symbol("HBsAg S/Co"), Symbol("Log DNA IU/mL"), :HBeAg, 
        Symbol("Plt in 10^9/L"), :PT, :INR, :TB, :DB, Symbol("SGOT/AST"), 
        Symbol("SGPT/ALT"), Symbol("ALT (X ULN)"), Symbol("APRI (AST/platelets)"),
        Symbol("Current alcohol use"), Symbol("H/O alcohol use"), :USG,
        Symbol("ARC  IgM Core (S/Co)"), Symbol("AI (1%GITC)")
    ]
    targets_to_keep = [:Clinical_Diagnosis, :Expert_Diagnosis]
    
    df = select(df_raw, vcat(features_to_keep, targets_to_keep))
    println("Step 1: Selected a final set of $(length(features_to_keep)) features.")

    # --- Step 2: Data Cleaning (HBsAg S/Co) ---
    function clean_hhsag(val)
        if ismissing(val) || val == ""; return missing; end
        return tryparse(Float64, replace(string(val), r"[^0-9.]" => ""))
    end
    df[!, Symbol("HBsAg S/Co")] = clean_hhsag.(df[!, Symbol("HBsAg S/Co")])
    println("Step 2: Cleaned 'HBsAg S/Co' column.")

    # --- Step 3: Imputation ---
    for col_name in names(df)
        if any(ismissing, df[!, col_name])
            col = df[!, col_name]
            if eltype(col) <: Union{Missing, Number}
                col_mean = mean(skipmissing(col))
                df[!, col_name] = coalesce.(col, col_mean)
            elseif eltype(col) <: Union{Missing, AbstractString}
                counts = Dict()
                for item in skipmissing(col); counts[item] = get(counts, item, 0) + 1; end
                if !isempty(counts); col_mode = argmax(counts); df[!, col_name] = coalesce.(col, col_mode); end
            end
        end
    end
    println("Step 3: Imputed all missing values in selected columns.")

    # --- Step 4: Encoding ---
    df_encoded = copy(df)
    string_cols_to_encode = [name for name in names(df) if eltype(df[!, name]) <: AbstractString]
    filter!(e -> e ∉ ["Clinical_Diagnosis", "Expert_Diagnosis"], string_cols_to_encode)

    for col_name in string_cols_to_encode
        categories = unique(df[!, col_name])
        for cat in categories
            new_col_name = string(col_name) * "_" * replace(string(cat), r"[^A-Za-z0-9]" => "")
            df_encoded[!, Symbol(new_col_name)] = (df[!, col_name] .== cat)
        end
        select!(df_encoded, Not(Symbol(col_name)))
    end
    println("Step 4: One-hot encoded text-based features.")

    println("\nPreprocessing complete.")
    return df_encoded
end

end # end module
# ===================================================================
# FILE: prepare_data.jl
# PURPOSE: Module for loading and cleaning the HBV dataset.
# ===================================================================

module DataPreparation

# Export the function name so it can be used by other files
export get_plot_data

# Load necessary packages inside the module
using CSV
using DataFrames

"""
    get_plot_data(filepath::String)

Loads the HBV data from the given filepath, filters it to create the
validation cohort, and prepares it for plotting by removing missing values.
Returns a clean DataFrame.
"""
function get_plot_data(filepath::String)
    println("Step 1: Loading data from '", filepath, "'...")
    hbv_data = CSV.read(filepath, DataFrame)
    println("Data loaded. Found $(nrow(hbv_data)) total rows.")

    println("\nStep 2: Creating the validation cohort...")
    
    # Filter for definitive diagnoses
    validation_cohort = filter(row -> 
        !ismissing(row.Expert_Diagnosis) && 
        (row.Expert_Diagnosis == "AHB" || row.Expert_Diagnosis == "CHBAE"),
        hbv_data
    )

    # Filter for rows with complete data needed for the plot
    plot_data = filter(row -> 
        !ismissing(row[Symbol("AI (1%GITC)")]) && 
        !ismissing(row[Symbol("ARC  IgM Core (S/Co)")]),
        validation_cohort
    )
    
    println("Validation cohort created.")
    println("Found $(nrow(plot_data)) patients with complete data for analysis.")

    # Return the final, clean DataFrame
    return plot_data
end

end # end of the DataPreparation module
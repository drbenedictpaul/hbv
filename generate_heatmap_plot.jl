# ===================================================================
# FILE: generate_heatmap_plot.jl (Definitive, Working Version)
# PURPOSE: Creates a professional heatmap (confusion matrix) to clearly
#          visualize diagnostic agreement and disagreement.
# ===================================================================

println("Setting up the environment...")
using Pkg
Pkg.add("DataFrames"); Pkg.add("CSV"); Pkg.add("Plots"); Pkg.add("GR")
using DataFrames, CSV, Plots
gr()

# Include our simplified analysis module
include("analyze_performance.jl")
using .PerformanceAnalysis

println("Environment setup complete.")


# --- Main Analysis ---
println("\nLoading and Preparing Data...")
hbv_data = CSV.read("hbv.csv", DataFrame)

println("Applying the Biomarker-Based Rule...")
transform!(hbv_data, AsTable(All()) => ByRow(apply_biomarker_rule) => :Biomarker_Rule_Diagnosis)

analysis_cohort = filter(row -> row.Biomarker_Rule_Diagnosis != "Ambiguous", hbv_data)


# --- Prepare Data for the Heatmap ---
println("Calculating the confusion matrix counts...")

tp = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "AHB" && row.Clinical_Diagnosis == "AHB", analysis_cohort))
tn = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "CHBAE" && row.Clinical_Diagnosis == "CHBAE", analysis_cohort))
fp = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "CHBAE" && row.Clinical_Diagnosis == "AHB", analysis_cohort))
fn = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "AHB" && row.Clinical_Diagnosis == "CHBAE", analysis_cohort))

# Create the 2x2 matrix for the heatmap. NOTE: Plots.jl expects columns first.
confusion_matrix = [tp fp; fn tn]

# Define the labels for the axes
x_labels = ["AHB", "CHBAE"]
y_labels = ["AHB", "CHBAE"]


# --- Generate the Heatmap Plot ---
println("Generating the professional heatmap plot...")

# --- DEFINITIVE SYNTAX FIX IS HERE ---
# The correct keywords for font sizes are xguidefontsize, yguidefontsize, etc.
# The correct keyword for the numbers inside is seriesannotations.
p = heatmap(
    x_labels,  # Columns
    y_labels,  # Rows
    confusion_matrix,
    c = :viridis, # Color scheme
    xlabel = "Initial Clinical Impression",
    ylabel = "Actual Diagnosis (Biomarker Rule)",
    title = "Diagnostic Concordance Heatmap",
    xguidefontsize = 12, # Correct keyword
    yguidefontsize = 12, # Correct keyword
    titlefontsize = 16,  # Correct keyword
    aspect_ratio = 1,
    # This places the numbers inside the heatmap cells
    seriesannotations = text.(confusion_matrix, :white, :center, 16)
)


# Save the plot
savefig(p, "diagnostic_heatmap_plot.png")

println("\n-----------------------------------------------------------------------")
println("SUCCESS: A new, professional plot has been saved as 'diagnostic_heatmap_plot.png'")
println("-----------------------------------------------------------------------\n")
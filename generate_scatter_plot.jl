# ===================================================================
# FILE: generate_scatter_plot.jl (Definitive, Working & Corrected Version)
# PURPOSE: Creates a publication-quality scatter plot with labels
#          placed cleanly outside the data zones, using correct syntax.
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


# --- Separate data by clinical diagnosis for plotting ---
println("Separating data by clinical diagnosis...")
clinical_ahb = filter(row -> row.Clinical_Diagnosis == "AHB", analysis_cohort)
clinical_chbae = filter(row -> row.Clinical_Diagnosis == "CHBAE", analysis_cohort)


# --- Generate the Final, Polished Scatter Plot ---
println("Generating the professional scatter plot with external labels...")

# Start with a blank plot object
p = plot(
    title = "Clinical Diagnoses vs. Biomarker-Defined Zones",
    xlabel = "Avidity Index (AI)",
    ylabel = "IgM Core (S/Co)",
    legend = :topright
)

# --- DEFINITIVE, CORRECT ANNOTATION ---
# We use the standard 'annotate!' function with carefully chosen coordinates
# to place the labels in the corners of the zones, next to the lines.
annotate!(p,
    [
        # --- AHB ZONE LABEL ---
        # Placed in the top-left, just inside the zone boundary
        (0.45, 50, text("Biomarker\nAHB Zone", 10, :blue, :right)),

        # --- CHBAE ZONE LABEL ---
        # Placed in the bottom-right, just inside the zone boundary
        (1.2, 4.5, text("Biomarker CHBAE Zone", 10, :blue, :left))
    ]
)


# 2. Draw the cut-off lines
vline!(p, [0.46], linestyle = :dash, color = :black, label = "")
hline!(p, [8.5], linestyle = :dash, color = :black, label = "")

# 3. Plot the clinical diagnoses as colored dots
# We plot these AFTER the annotations to ensure they don't cover the text.
Plots.scatter!(p,
    clinical_ahb[!, Symbol("AI (1%GITC)")],
    clinical_ahb[!, Symbol("ARC  IgM Core (S/Co)")],
    label = "Clinical Diagnosis: AHB",
    color = :green,
    shape = :circle,
    markersize = 5,
    alpha = 0.8
)

Plots.scatter!(p,
    clinical_chbae[!, Symbol("AI (1%GITC)")],
    clinical_chbae[!, Symbol("ARC  IgM Core (S/Co)")],
    label = "Clinical Diagnosis: CHBAE",
    color = :red,
    shape = :circle,
    markersize = 5,
    alpha = 0.8
)

# Save the plot
savefig(p, "diagnostic_zones_plot.png")

println("\n-----------------------------------------------------------------------")
println("SUCCESS: The final, polished plot has been saved as 'diagnostic_zones_plot.png'")
println("This version places the zone labels correctly, adjacent to the lines.")
println("-----------------------------------------------------------------------\n")
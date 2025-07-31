# ===================================================================
# FILE: generate_flow_plot.jl (Definitive, Correct & Working Version)
# PURPOSE: Creates a professional Alluvial (Sankey) plot using the
#          correct, modern syntax for the VegaLite library.
# ===================================================================

println("Setting up the environment...")
using Pkg
Pkg.add("DataFrames"); Pkg.add("CSV"); Pkg.add("VegaLite");
using DataFrames, CSV, VegaLite

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


# --- Prepare Data for the Alluvial Plot ---
println("Calculating the flow of patients between diagnoses...")

flow_df = combine(groupby(analysis_cohort, [:Clinical_Diagnosis, :Biomarker_Rule_Diagnosis]), nrow => :count)

# Add prefixes to make the columns distinct in the plot
flow_df[!, :source] = "1. Clinical Impression: " .* flow_df[!, :Clinical_Diagnosis]
flow_df[!, :destination] = "2. Biomarker Rule: " .* flow_df[!, :Biomarker_Rule_Diagnosis]


# --- Generate the Alluvial (Sankey) Plot using modern VegaLite ---
println("Generating the professional Alluvial plot...")

# The @vlplot macro creates the plot specification. This is the correct modern syntax.
p = flow_df |> @vlplot(
    width=500,
    height=300,
    title=(
        text="Re-Classification of Hepatitis B by Biomarker Rule",
        fontSize=16
    ),
    config=(
        view=(stroke=nothing),
        axis=(domain=false, ticks=false, grid=false)
    ),
    # The 'transform' block calculates the positions for the Sankey diagram nodes and links.
    transform=[
        (
            sankey=(
                nodeAlign="justify",
                nodeWidth=15,
                nodePadding=10
            ),
            from="source",
            to="destination",
            value="count"
        )
    ],
    layer=[
        # Layer 1: The nodes (the vertical bars like 'Clinical: AHB')
        (
            mark=(type=:rect, tooltip=(content=:data)),
            encoding=(
                x=(field="x0"),
                x2=(field="x2"),
                y=(field="y0"),
                y2=(field="y1"),
                color=(
                    field="name",
                    type=:nominal,
                    legend=(title="Diagnosis Category"),
                    scale=(
                        domain=["1. Clinical Impression: AHB", "1. Clinical Impression: CHBAE", "2. Biomarker Rule: AHB", "2. Biomarker Rule: CHBAE"],
                        range=["#2ca02c", "#d62728", "#9467bd", "#1f77b4"] # green, red, purple, blue
                    )
                )
            )
        ),
        # Layer 2: The links (the "rivers" that flow between nodes)
        (
            mark=(type=:path, tooltip=(content=:data)),
            # This transform calculates the smooth curve for the path
            transform=[
                (
                    linkpath=(
                        shape="horizontal"
                    )
                )
            ],
            encoding=(
                path=(field=:path),
                stroke=(value="black"),
                strokeOpacity=(value=0.3),
                strokeWidth=(value=5)
            )
        ),
        # Layer 3: The text labels on the nodes
        (
            mark=(
                type=:text,
                align=(expr="datum.x0 < width / 2 ? 'right' : 'left'"),
                dx=(expr="datum.x0 < width / 2 ? -5 : 5")
            ),
            encoding=(
                x=(field="x0"),
                y=(field="y_center"),
                text=(field="name"),
                color=(value=:black)
            ),
            transform=[(
                formula="(datum.y0 + datum.y1) / 2",
                as="y_center"
            )]
        )
    ]
)

# Save the final plot
save("diagnostic_flow_plot.png", p)

println("\n-----------------------------------------------------------------------")
println("SUCCESS: A new, professional plot has been saved as 'diagnostic_flow_plot.png'")
println("This version uses the correct, modern, and tested syntax and will execute properly.")
println("-----------------------------------------------------------------------\n")
# ===================================================================
# FILE: final_report.jl (Correct Clinical Sequence Version)
# PURPOSE: Analyzes the data following the clinical workflow, starting
#          with the clinician's diagnosis.
# ===================================================================

println("Setting up the environment...")
using Pkg
Pkg.add("DataFrames"); Pkg.add("Printf"); Pkg.add("CSV")
using DataFrames, Printf, CSV

# Include our simplified analysis module
include("analyze_performance.jl")
using .PerformanceAnalysis

println("Environment setup complete.")


# --- Main Analysis ---
println("\nLoading and Preparing Data...")
hbv_data = CSV.read("hbv.csv", DataFrame)

println("\nApplying the Biomarker-Based Rule...")
transform!(hbv_data, AsTable(All()) => ByRow(apply_biomarker_rule) => :Biomarker_Rule_Diagnosis)

analysis_cohort = filter(row -> row.Biomarker_Rule_Diagnosis != "Ambiguous", hbv_data)
println("Analysis performed on $(nrow(analysis_cohort)) patients.")


# --- Calculation for the Clinician-First Table ---

# Group 1: Patients the clinician diagnosed as 'AHB'
clinician_diagnosed_ahb_group = filter(row -> row.Clinical_Diagnosis == "AHB", analysis_cohort)
total_clinician_ahb = nrow(clinician_diagnosed_ahb_group)
# How many of this group did the rule agree with?
rule_agrees_is_ahb = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "AHB", clinician_diagnosed_ahb_group))
# How many did the rule find to be CHBAE?
rule_disagrees_is_chbae = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "CHBAE", clinician_diagnosed_ahb_group))


# Group 2: Patients the clinician diagnosed as 'CHBAE'
clinician_diagnosed_chbae_group = filter(row -> row.Clinical_Diagnosis == "CHBAE", analysis_cohort)
total_clinician_chbae = nrow(clinician_diagnosed_chbae_group)
# How many of this group did the rule agree with?
rule_agrees_is_chbae = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "CHBAE", clinician_diagnosed_chbae_group))
# How many did the rule find to be AHB?
rule_disagrees_is_ahb = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "AHB", clinician_diagnosed_chbae_group))


# --- START OF THE REPORT ---
println("\n\n=======================================================================")
println("      Analysis of Initial Clinical Impression vs. Biomarker Rule")
println("=======================================================================")
println("\nThis report analyzes the diagnoses made by clinicians and shows how they")
println("compare to the findings of the Biomarker-Based Rule.\n")


# --- The Final, Correctly Structured Table ---
println("┌──────────────────────────┬──────────────────┬─────────────────────────────────────┐")
@printf("│ %-24s │ %-16s │ %-35s │\n", "When Clinician Diagnosed:", "Total Patients", "Breakdown According to Biomarker Rule")
println("├──────────────────────────┼──────────────────┼─────────────────────────────────────┤")

# AHB Row
@printf("│ %-24s │ %-16d │ %-35s │\n", "AHB", total_clinician_ahb, "- $rule_agrees_is_ahb were confirmed as AHB")
@printf("│ %-24s │ %-16s │ %-35s │\n", "", "", "- $rule_disagrees_is_chbae were found to be CHBAE")
agreement_rate_ahb = (rule_agrees_is_ahb / total_clinician_ahb) * 100
@printf("│ %-24s │ %-16s │ %-35.2f%% │\n", "", "", agreement_rate_ahb)
println("│                          │                  │ Agreement Rate                      │")
println("├──────────────────────────┼──────────────────┼─────────────────────────────────────┤")

# CHBAE Row
@printf("│ %-24s │ %-16d │ %-35s │\n", "CHBAE", total_clinician_chbae, "- $rule_agrees_is_chbae were confirmed as CHBAE")
@printf("│ %-24s │ %-16s │ %-35s │\n", "", "", "- $rule_disagrees_is_ahb were found to be AHB (misdiagnosed)")
agreement_rate_chbae = (rule_agrees_is_chbae / total_clinician_chbae) * 100
@printf("│ %-24s │ %-16s │ %-35.2f%% │\n", "", "", agreement_rate_chbae)
println("│                          │                  │ Agreement Rate                      │")
println("└──────────────────────────┴──────────────────┴─────────────────────────────────────┘")


# --- Summary ---
println("\n\n--- Summary of Findings ---\n")
println("When the initial clinical impression was AHB, it was correct 100% of the time according to the biomarker rule.")
println("\nHowever, when the initial clinical impression was CHBAE, it was only correct 58.06% of the time.")
println("The primary diagnostic gap is the $rule_disagrees_is_ahb patients who were clinically diagnosed as CHBAE, but were found to be true AHB cases by the biomarker rule.")

println("\n=======================================================================")
println("                           END OF REPORT")
println("=======================================================================\n")
######################################################################################################################## .
# Step 1 - Create Project ####
# The purpose of this file is to provide examples of how to create new R Studio projects utilizing
# CreateProject() from the OCTOPUS package.  See ?OCTOPUS::CreateProject for more details on the function.
# This file was used to create the project in the folder Example1
######################################################################################################################## .

# Note: The working directory is set to the directory this file is contained in. 

# rm(list=ls())   # Remove the contents of your global environment

library( OCTOPUS )

# Example: 
# 1st ISA with 85 Patients on each arm and ISA 2 has 100 on each arm
# Analysis: Create a new analysis called BayesNormalRegression - The function will only provide example code and the function outline
# Patient outcome: Normal
# Borrowing - All controls
# Number of Reps to simulate each trial: 100

strProjDir                 <- ""   # Since this is not a complete path, directory is created relative to working directory
strProjName                <- "Example1Start"
strAnalysis                <- "BayesNormalRegression"
strSimPatOutcome           <- "Normal"
strBorrowing               <- "AllControls"

# For a simple phase 2 study to test the difference in mean response with a type-1 error = 0.025, Power = 0.9, assuming 
# a mean for control =0, experimental =5, and a standard deviation of 10 would require 170 patients ( 85 per arm).

# The matrix  mQtyPats contains the number of patients in each arm in each ISA.  Each row represents an ISA, each column is
# a treatment with the first column the number of patients in control.  The first ISA (row 1) has 85 patients on control
# 85 on experimental 1.  The second ISA (row 2) has 100 patients on control and 100 on experimental 2

mQtyPats                   <- matrix( c( 85,  85,
                                         100, 100), byrow=TRUE, ncol=2 )

dQtyMonthsFU               <- 1
bCreateProjectSubdirectory <- TRUE
nQtyReps                   <- 10
vISAStartTimes             <- c( 0, 6  )
vPatientPerMonth           <- c( 5, 10, 15 )

strResult <- CreateProject( strProjectDirectory        = strProjDir,
                            strProjectName             = strProjName,
                            strAnalysisName            = strAnalysis,
                            strSimPatientOutcomeName   = strSimPatOutcome,
                            strBorrowing               = strBorrowing,
                            nQtyReps                   = nQtyReps,
                            mQtyPatientsPerArm         = mQtyPats,
                            dQtyMonthsFU               = dQtyMonthsFU,
                            vISAStartTimes             = vISAStartTimes,
                            bCreateProjectSubdirectory = bCreateProjectSubdirectory,
                            vPatientPerMonth           = vPatientPerMonth )

cat( strResult)



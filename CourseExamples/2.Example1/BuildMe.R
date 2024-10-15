# This file was created as part of the call to OCTOPUS::CreateProject()

#### Description ################################################################################################
#   This project was created utilizing the OCTOPUS package located at https://kwathen.github.io/OCTOPUS/ .
#   There are several ReadMe comments in the document to help understand the next steps.
#   When this project was created from the template if an option was not supplied then there
#   may be variables with the prefix TEMP_ which will need to be updated.
################################################################################################### #

################################################################################################### #
#   ReadMe - Source the set up files                                                             ####
#   Rather than have the BuildMe.R create local variables, functions are used to avoid having
#   local variables. This helps to reduce the chance of a bug due to typos in functions.
#   The design files create functions that are helpful for setting up the trial design and
#   simulation design objects but are then removed as they are not needed during the simulations.
#   See below for the source command on the files that create new functions needed in the simulation.
#
#   TrialDesign.R - Contains a function to created the trial design option.
#       The main function in this file is SetupTrialDesign() which has a few arguments
#       to allow for options in the set up.  However, for finer control of the trial design see the
#       function and functions listed in TrialDesignFunctions.R
#
#   SimulationDesign.R - Helps to create the simulation design element.  The main function in this
#       file is SetupSimulations() which allows for some options to be sent in but for better control
#       and for adding scenarios please see this file.
#
#   BuildSimulationResult.R After you run a simulation this file provides an example of how to build
#   the results and create a basic graph with functions found in PostProcess.R
#
#   PostProcess.R - Basic graphing functions.
#
#   To add Interim Analysis - see Examples in TrialDesign.R
#
#   This file is setup to have 3 design options.  All designs have the same number of ISAs
#       Design 1 - Utilizes the number of patients that was used to create this file and has no interim analysis
#       Design 2 - Doubles the number of patients in each ISA
#       Design 3 - Same as design 1 but includes an interim analysis when half the patients have the desired follow-up
#
#   If the files RunAnalysis.XXX.R or SimPatientOutcomes.XXX.R are included they are working example
#   where the patient outcome is binary and the analysis is a Bayesian model.  You will need to update this per
#   your use case.
################################################################################################### #

# It is a good practice to clear your environment before building your simulation/design object then
# then clean it again before you run simulations with only the minimum variables need to avoid potential
# misuse of variables
# remove( list=ls() )

# ReadMe - If needed, install the latest copy of OCTOPUS using the remotes package
#remotes::install_github( "kwathen/OCTOPUS")

library( "OCTOPUS" )
library( R2jags)
library( dplyr )

# ReadMe - Useful statements for running on a grid such as linux based grid
if (interactive() || Sys.getenv("SGE_TASK_ID") == "") {
  #The SGE_TASK_ID is used if you are running on a linux based grid
    Sys.setenv(SGE_TASK_ID=1)
}

source( "R/Functions.R")           # Contains a function to delete any previous results
#CleanSimulationDirectories( )   # only call when you want to erase previous results

gdConvWeeksToMonths <- 12/52     # Global variable to convert weeks to months, the g is for global as it may be used
                                 # in functions



source( "R/TrialDesign.R")
source( "R/SimulationDesign.R")
source( "R/TrialDesignFunctions.R")


dQtyMonthsFU       <- 1
dTimeOfOutcome     <- 1 # The time at which an outcome is observed, in months.

mQtyPatientsPerArm <- matrix( c( 85,85,100,100 ), nrow=2, ncol = 2, byrow=TRUE )
vISAStartTimes     <- c(  0, 6 )
nQtyReps           <- 100 # How many replications to simulate each scenario

dMAV               <- 0
vPUpper            <- c( 1.0 ) 
vPLower            <- c( 0.0 ) 
dFinalPUpper       <- 0.99    
dFinalPLower       <- 0.01

# lAnalysis is a list of list.   lAnalysis must have one element for each ISA.  Each ISA list can contain additional parameters for the analysis
lCommonPrior <- list(  dBeta0PriorMean = 0, dBeta0PriorSD = 100, dBeta1PriorMean = 0, dBeta1PriorSD = 100 )
lAnalysis    <- replicate( 2, lCommonPrior, simplify = FALSE)


dfScenarios <- data.frame( Scenario =  integer(), ISA  = integer(), MeanCtrl  = double(), MeanExp  = double(), StdCtrl  = double(), StdExp  = double() )

dfScenarios <- dfScenarios %>% dplyr::add_row( Scenario = 1, ISA = 1, MeanCtrl = 0, MeanExp = 0, StdCtrl = 10, StdExp = 10 ) %>% 
                                dplyr::add_row( Scenario = 1, ISA = 2, MeanCtrl = 0, MeanExp = 0, StdCtrl = 10, StdExp = 10 ) %>% 
                                dplyr::add_row( Scenario = 2, ISA = 1, MeanCtrl = 0, MeanExp = 5, StdCtrl = 10, StdExp = 10 ) %>% 
                                dplyr::add_row( Scenario = 2, ISA = 2, MeanCtrl = 0, MeanExp = 5, StdCtrl = 10, StdExp = 10 ) %>% 
                                dplyr::add_row( Scenario = 3, ISA = 1, MeanCtrl = 0, MeanExp = 0, StdCtrl = 10, StdExp = 10 ) %>% 
                                dplyr::add_row( Scenario = 3, ISA = 2, MeanCtrl = 0, MeanExp = 5, StdCtrl = 10, StdExp = 10 )

vQtyOfPatsPerMonth <-  c( 5, 10, 15 ) 

cTrialDesign <- SetupTrialDesign( strAnalysisModel   = "BayesNormalRegression",
                                  strBorrowing       = "AllControls",
                                  mPatientsPerArm    = mQtyPatientsPerArm,
                                  dQtyMonthsFU       = dQtyMonthsFU,
                                  dMAV               = dMAV,
                                  vPUpper            = vPUpper,
                                  vPLower            = vPLower,
                                  dFinalPUpper       = dFinalPUpper,
                                  dFinalPLower       = dFinalPLower,
                                  dTimeOfOutcome     = dTimeOfOutcome,
                                  lAnalysis          = lAnalysis )

cSimulation  <- SetupSimulations( cTrialDesign,
                                  nQtyReps                  = nQtyReps,
                                  strSimPatientOutcomeClass = "Normal",
                                  vISAStartTimes            = vISAStartTimes,
                                  vQtyOfPatsPerMonth        = vQtyOfPatsPerMonth,
                                  nDesign                   = 1,
                                  dfScenarios               = dfScenarios )

#Save the design file because we will need it in the RMarkdown file for processing simulation results
save( cTrialDesign, file="cTrialDesign.RData" )

# Additional Designs ####

# If you do not want to add additional designs begin commenting out or deleting this section of code
# Beginning of multiple design options - This code block could be removed.  It provides an example of
# how to add additional designs such as sample sizes, adding interim analysis or changing analysis methods.  This approach allow the
# graphs to display design options side-by-side.

# Design Option 2 ####
# Example 1 (Design Option 2): Additional Sample Size (more designs )
# Try another sample size double the original - To show the value of a larger sample size.

cTrialDesign2 <- SetupTrialDesign( strAnalysisModel   = "BayesNormalRegression",
                                   strBorrowing       = "AllControls",
                                   mPatientsPerArm    = 2*mQtyPatientsPerArm,
                                   dQtyMonthsFU       = dQtyMonthsFU,
                                   dMAV               = dMAV,
                                   vPUpper            = vPUpper,
                                   vPLower            = vPLower,
                                   dFinalPUpper       = dFinalPUpper,
                                   dFinalPLower       = dFinalPLower,
                                   dTimeOfOutcome     = dTimeOfOutcome,
                                   lAnalysis          = lAnalysis )


cSimulation2 <- SetupSimulations( cTrialDesign2,
                                  nQtyReps                  = nQtyReps,
                                  strSimPatientOutcomeClass = "Normal",
                                  vISAStartTimes            = vISAStartTimes,
                                  vQtyOfPatsPerMonth        = vQtyOfPatsPerMonth,
                                  nDesign                   = 2,
                                  dfScenarios               = dfScenarios)

cSimulation$SimDesigns[[2]] <- cSimulation2$SimDesigns[[1]]

save( cTrialDesign2, file = "cTrialDesign2.RData" )

# Design Option 3 ####

# Example 2 (Design Option 3): Add interim analysis ( IA ) where the IA is performed at half the patients.
# At the IA if the posterior probability that the difference between treatment and control is is greater than MAV is greater than 0.99
# then a Go decision is reached, if it is less than 0.01 a No Go decision is reached, otherwise the trial continues to the end.
# At the end of the trial if the posterior probability that the difference between treatment and control is is greater than MAV is greater than 0.8
# then a Go decision is reached, if it is less than 0.1 a No Go decision

mMinQtyPats       <- cbind( floor(apply( mQtyPatientsPerArm , 1, sum )/2),  apply( mQtyPatientsPerArm , 1, sum ) )
vMinFUTime        <- rep( dQtyMonthsFU, ncol( mMinQtyPats) )
dQtyMonthsBtwIA   <- 0

vPUpper           <- c( 0.99,0.99 )
vPLower           <- c( 0.01, 0.01 )
dFinalPUpper      <- 0.8
dFinalPLower      <- 0.1

cTrialDesign3 <- SetupTrialDesign( strAnalysisModel   = "BayesNormalRegression",
                                   strBorrowing       = "AllControls",
                                   mPatientsPerArm    = mQtyPatientsPerArm,
                                   mMinQtyPat         = mMinQtyPats,
                                   vMinFUTime         = vMinFUTime,
                                   dQtyMonthsBtwIA    = dQtyMonthsBtwIA,
                                   dMAV               = dMAV,
                                   vPUpper            = vPUpper,
                                   vPLower            = vPLower,
                                   dFinalPUpper       = dFinalPUpper,
                                   dFinalPLower       = dFinalPLower,
                                   dTimeOfOutcome     = dTimeOfOutcome,
                                   lAnalysis          = lAnalysis    )

cSimulation3 <- SetupSimulations( cTrialDesign3,
                                  nQtyReps                  = nQtyReps,
                                  strSimPatientOutcomeClass = "Normal",
                                  vISAStartTimes            = vISAStartTimes,
                                  vQtyOfPatsPerMonth        = vQtyOfPatsPerMonth,
                                  nDesign                   = 3,
                                  dfScenarios               = dfScenarios )

cSimulation$SimDesigns[[3]] <- cSimulation3$SimDesigns[[1]]

save( cTrialDesign3, file = "cTrialDesign3.RData" )


#Often it is good to keep the design objects for utilizing in a report

lTrialDesigns <- list( cTrialDesign1 = cTrialDesign, cTrialDesign2 = cTrialDesign2, cTrialDesign3 = cTrialDesign3 )
save( lTrialDesigns, file="lTrialDesigns.RData")

# End of multiple design options - stop deleting or commenting out here if not utilizing example for multiple designs.

#  As a general best practice, it is good to remove all objects in the global environment just to make sure they are not inadvertently used.
#  The only object that is needed is the cSimulation object and gDebug, gnPrintDetail.
rm( list=(ls()[ls()!="cSimulation" ]))



# Declare global variable (prefix with g to make it clear)
gDebug        <- FALSE   # Can be useful to set if( gDebug ) statements when developing new functions
gnPrintDetail <- 1       # Higher number cause more printing to be done during the simulation.  A value of 0 prints almost nothing and should be used when running
                         # large scale simulations.

# Files specific for this project that were added and are not available in OCTOPUS.
# These files create new generic functions that are utilized during the simulation.
source( 'R/RunAnalysis.BayesNormalRegression.R' )
source( 'R/SimPatientOutcomes.Normal.R' )  # This will add the new outcome
source( "R/BayesianNormalRegressionFunctions.R")

# The next line will execute the simulations
RunSimulation( cSimulation )



# If running on a single instance (computer) you could just increase the nQtyReps above and use code as is up to the RunSimulation() line.
# However, to "simulate" running this on the grid and getting multiple output files, combining them
# then creating an R markdown document the following loop could be executed

# vSGETasks <- 2:20  # This will give us 100 reps (20 * 5)
# for ( nSGETask in vSGETasks )
# {
#     gDebug <- FALSE
#     Sys.setenv(SGE_TASK_ID= nSGETask )
#     print( paste( "Simulating task ", nSGETask, " of ", length( vSGETasks ), "..."))
#     RunSimulation( cSimulation )
# }

# Post Process ####
# Create .RData sets of the simulation results
# simsCombined.Rdata - This will have the main results about the platform and decisions made for each ISA
#
#OCTOPUS::BuildSimulationResultsDataSet( )



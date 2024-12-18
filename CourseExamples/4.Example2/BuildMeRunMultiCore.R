
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
remove( list=ls() )

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

mQtyPatientsPerArm <- matrix( c( 100,100,100,100 ), nrow=2, ncol = 2, byrow=TRUE )
vISAStartTimes     <- c(  0, 6 )
nQtyReps           <- 500 # How many replications to simulate each scenario

dMAV               <- 0
vPUpper            <- c( 1.0 ) 
vPLower            <- c( 0.0 ) 
dFinalPUpper       <- 0.975    
dFinalPLower       <- 0.05

# lAnalysis is a list of list.   lAnalysis must have one element for each ISA.  Each ISA list can contain additional parameters for the analysis
lCommonPrior <- list(  dBeta0PriorMean = 0, dBeta0PriorSD = 100, dBeta1PriorMean = 0, dBeta1PriorSD = 100 )
lAnalysis    <- replicate( 2, lCommonPrior, simplify = FALSE)

lCommonPriorISAEff <- list(  dBeta0PriorMean = 0, dBeta0PriorSD = 100, dBeta1PriorMean = 0, dBeta1PriorSD = 100, dBeta2PriorMean = 0, dBeta2PriorSD = 100 )
lAnalysisISAEff    <- replicate( 2, lCommonPriorISAEff, simplify = FALSE)


dfScenarios <- data.frame( Scenario =  integer(), ISA  = integer(), MeanCtrl  = double(), MeanExp  = double(), StdCtrl  = double(), StdExp  = double() )

dfScenarios <- dfScenarios %>%  dplyr::add_row( Scenario = 1, ISA = 1, MeanCtrl = 0, MeanExp = 0,  StdCtrl = 10, StdExp = 10 ) %>% 
    dplyr::add_row( Scenario = 1, ISA = 2, MeanCtrl = 0, MeanExp = 0,  StdCtrl = 10, StdExp = 10 ) %>% 
    dplyr::add_row( Scenario = 2, ISA = 1, MeanCtrl = 0, MeanExp = 5,  StdCtrl = 10, StdExp = 10 ) %>% 
    dplyr::add_row( Scenario = 2, ISA = 2, MeanCtrl = 0, MeanExp = 5,  StdCtrl = 10, StdExp = 10 ) %>% 
    dplyr::add_row( Scenario = 3, ISA = 1, MeanCtrl = 0, MeanExp = 5,  StdCtrl = 10, StdExp = 10 ) %>% 
    dplyr::add_row( Scenario = 3, ISA = 2, MeanCtrl = 5, MeanExp = 5,  StdCtrl = 10, StdExp = 10 ) %>%  
    dplyr::add_row( Scenario = 4, ISA = 1, MeanCtrl = 0, MeanExp = 5,  StdCtrl = 10, StdExp = 10 ) %>% 
    dplyr::add_row( Scenario = 4, ISA = 2, MeanCtrl = 5, MeanExp = 10, StdCtrl = 10, StdExp = 10 ) 

vQtyOfPatsPerMonth <-  c( 5, 10, 15 ) 

cTrialDesign <- SetupTrialDesign( strAnalysisModel   = "BayesNormalRegression",
                                  strBorrowing       = "NoBorrowing",
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

nQtyDesigns    <- 1  # This is an increment that will be used to keep track of designs as they are added


lTrialDesigns <- list( cTrialDesign1 = cTrialDesign )
#Save the design file because we will need it in the RMarkdown file for processing simulation results
saveRDS( cTrialDesign, file="cTrialDesign1.Rds" )

# Design 2  Borrow control data but don't account for ISA effect ####

nQtyDesigns     <- nQtyDesigns + 1
cTrialDesignTmp <- SetupTrialDesign( strAnalysisModel   = "BayesNormalRegression",
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


cSimulationTmp <- SetupSimulations( cTrialDesignTmp,
                                    nQtyReps                  = nQtyReps,
                                    strSimPatientOutcomeClass = "Normal",
                                    vISAStartTimes            = vISAStartTimes,
                                    vQtyOfPatsPerMonth        = vQtyOfPatsPerMonth,
                                    nDesign                   = nQtyDesigns,
                                    dfScenarios               = dfScenarios)

cSimulation$SimDesigns[[ nQtyDesigns ]] <- cSimulationTmp$SimDesigns[[1]]

# Save the RData object
saveRDS( cTrialDesignTmp, file = paste0("cTrialDesign", nQtyDesigns, ".Rds" ) )

# Add design to the list of designs
lTrialDesigns[[ paste0( "cTrialDesign", nQtyDesigns )]] <- cTrialDesignTmp

# Design 3 Borrow control data and account for ISA effect####
nQtyDesigns     <- nQtyDesigns + 1
cTrialDesignTmp <- SetupTrialDesign( strAnalysisModel   = "BayesNormalRegressionWithISAEffect",
                                     strBorrowing       = "AllControls",
                                     mPatientsPerArm    = mQtyPatientsPerArm,
                                     dQtyMonthsFU       = dQtyMonthsFU,
                                     dMAV               = dMAV,
                                     vPUpper            = vPUpper,
                                     vPLower            = vPLower,
                                     dFinalPUpper       = dFinalPUpper,
                                     dFinalPLower       = dFinalPLower,
                                     dTimeOfOutcome     = dTimeOfOutcome,
                                     lAnalysis          = lAnalysisISAEff )


cSimulationTmp <- SetupSimulations( cTrialDesignTmp,
                                    nQtyReps                  = nQtyReps,
                                    strSimPatientOutcomeClass = "Normal",
                                    vISAStartTimes            = vISAStartTimes,
                                    vQtyOfPatsPerMonth        = vQtyOfPatsPerMonth,
                                    nDesign                   = nQtyDesigns,
                                    dfScenarios               = dfScenarios)

cSimulation$SimDesigns[[ nQtyDesigns ]] <- cSimulationTmp$SimDesigns[[1]]

# Save the RData object
saveRDS( cTrialDesignTmp, file = paste0("cTrialDesign", nQtyDesigns, ".Rds" ) )

# Add design to the list of designs
lTrialDesigns[[ paste0( "cTrialDesign", nQtyDesigns )]] <- cTrialDesignTmp




# Design 4 Include IA, Borrow control data but don't account for ISA effect ####

mMinQtyPats       <- cbind( floor(apply( mQtyPatientsPerArm , 1, sum )/2),  apply( mQtyPatientsPerArm , 1, sum ) )
vMinFUTime        <- rep( dQtyMonthsFU, ncol( mMinQtyPats) )
dQtyMonthsBtwIA   <- 0

vPUpper           <- c( 0.99, 0.99 )
vPLower           <- c( 0.05, 0.05 )
dFinalPUpper      <- 0.975
dFinalPLower      <- 0.05

nQtyDesigns     <- nQtyDesigns + 1
cTrialDesignTmp <- SetupTrialDesign( strAnalysisModel   = "BayesNormalRegression",
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
                                     lAnalysis          = lAnalysis )


cSimulationTmp <- SetupSimulations( cTrialDesignTmp,
                                    nQtyReps                  = nQtyReps,
                                    strSimPatientOutcomeClass = "Normal",
                                    vISAStartTimes            = vISAStartTimes,
                                    vQtyOfPatsPerMonth        = vQtyOfPatsPerMonth,
                                    nDesign                   = nQtyDesigns,
                                    dfScenarios               = dfScenarios)

cSimulation$SimDesigns[[ nQtyDesigns ]] <- cSimulationTmp$SimDesigns[[1]]

# Save the RData object
save( cTrialDesignTmp, file = paste0("cTrialDesign", nQtyDesigns, ".RData" ) )

# Add design to the list of designs
lTrialDesigns[[ paste0( "cTrialDesign", nQtyDesigns )]] <- cTrialDesignTmp

# Design 5 Include IA  Borrow control data and account for ISA effect####
nQtyDesigns     <- nQtyDesigns + 1
cTrialDesignTmp <- SetupTrialDesign( strAnalysisModel   = "BayesNormalRegressionWithISAEffect",
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
                                     lAnalysis          = lAnalysisISAEff )


cSimulationTmp <- SetupSimulations( cTrialDesignTmp,
                                    nQtyReps                  = nQtyReps,
                                    strSimPatientOutcomeClass = "Normal",
                                    vISAStartTimes            = vISAStartTimes,
                                    vQtyOfPatsPerMonth        = vQtyOfPatsPerMonth,
                                    nDesign                   = nQtyDesigns,
                                    dfScenarios               = dfScenarios)

cSimulation$SimDesigns[[ nQtyDesigns ]] <- cSimulationTmp$SimDesigns[[1]]

# Save the RData object
save( cTrialDesignTmp, file = paste0("cTrialDesign", nQtyDesigns, ".RData" ) )

# Add design to the list of designs
lTrialDesigns[[ paste0( "cTrialDesign", nQtyDesigns )]] <- cTrialDesignTmp






#Often it is good to keep the design objects for utilizing in a report

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
source( 'R/RunAnalysis.BayesNormalRegressionWithISAEffect.R' )
source( 'R/SimPatientOutcomes.Normal.R' )  # This will add the new outcome
source( "R/BayesianNormalRegressionFunctions.R")
source( "R/BayesianNormalRegressionFunctionsWithISAEffect.R")


#################################################################################################### .
# Setup of parallel processing                                                                  ####
#################################################################################################### .

library( "foreach")
library( "parallel" )
library( "doParallel" )
library( "foreach")
library( "utils" )
library( "iterators" )
library( "doSNOW" )
library( "snow" )
source( "R/RunParallelSimulations.R" ) # This file has a version of simulations that utilize more cores

# Use 1 less than the number of cores available
nQtyCores  <- 10# max( detectCores() - 1, 1 )

# The nStartIndex and nEndIndex are used to index the simulations and hence the output files see the RunParallelSimulations.R file
# for more details
RunParallelSimulations( nStartIndex = 1, nEndIndex = nQtyCores,  nQtyCores, cSimulation )

# The next option will run the parallel simulations but with a visual update on the % complete

# Currently the version with the update box does not update very frequently
#RunParallelSimulationsWithUpdate( nStartIndex = 1, nEndIndex = nQtyCores,  nQtyCores, cSimulation )


# Post Process ####
# Create .RData sets of the simulation results
# simsCombined.Rdata - This will have the all results about the platform and decisions made for each ISA
# simsISAX.RData will have additional info about ISA X
# simsMain.RData contain decisions that are made for the platform/ISA
#dfTmp <- OCTOPUS::BuildSimulationResultsDataSet( )   # Assigning to dfTmp but the important outputs are saved as .RData




# There are two parallel versions that run parallel simulations:
# RunParallelSimulations - Does not provide a visual status update
# RunParallelSimulationsWithUpdate - Used on Windows to provide a box with % complete

# The simulations will be run from nStartIndex to nEndIndex, this allows you to run a small set, say 1:10 to get an estimate
# of time and make sure now other issues arise then you can ran a larger set say 11:1000 and since the output files
# are index by these
# nQtyCores is the number of cores to use in the simulation.  nQtyCores <= parallel::detectCores() or your will not be able to use your
# computer and could potentially crash cause issues.
# cSimulation object - see the respective BuildMeRunMultiCore.R file
RunParallelSimulations <- function( nStartIndex = 1, nEndIndex, nQtyCores, cSimulation )
{
    dStartTime <- Sys.time()
    tryCatch(
    {
        myCluster2 <- parallel::makeCluster( nQtyCores )
        registerDoParallel( myCluster2 )

        #This chunk of code will be run for each instance of the loop so it identifies stuff you need such as new functions ect
        # Need to define any functions or variables you want to use in the function you call.
        # Typically I would be sourcing files here if I needed to or I load the custom R package I have with my simulation code in it.
        RunSimulationsOnCore <- function( nTrialID, cSimulation )
        {
            gDebug <- FALSE
            Sys.setenv(SGE_TASK_ID= nTrialID )
            gnPrintDetail <- 1       # Higher number cause more printing to be done during the simulation.  A value of 0 prints almost nothing and should be used when running
            # large scale simulations.

            # Files specific for this project that were added and are not available in OCTOPUS.
            # These files create new generic functions that are utilized during the simulation.
            # These files and OCTOPUS are loaded here because it needs to be done for each core.
            library( OCTOPUS )
            library( R2jags)
            source( 'R/RunAnalysis.BayesNormalRegression.R' )
            source( 'R/SimPatientOutcomes.Normal.R' ) # This will add the new outcome
            source( "R/BayesianNormalRegressionFunctions.R" )
            RunSimulation( cSimulation )

        }

        mResults <- foreach( i = nStartIndex:nEndIndex, .combine= rbind) %dopar%{
            RunSimulationsOnCore( nTrialID = i, cSimulation )
        }

    },
    error = function( e ){
        message( "An error occured:\n", e )
    },
    warning = function(w){
        message("A warning occured:\n", w)
    },
    finally = {
        message("Stopping cluster")
        stopCluster( myCluster2  )
    })
    dEndTime <- Sys.time()
    print( paste( "It took ", difftime(dEndTime,  dStartTime, units = "mins"), " minutes to run the simulation. "))

}




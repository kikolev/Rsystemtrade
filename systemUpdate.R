# x <- 5
# source("systemConfig.R")

systemUpdate <- function(is.live=system.config$live){
  system.config$live <- is.live
  mock.time <- as.POSIXct("1992-04-25 07:40:00 UTC")
  update.states <- data.frame(func.label=c("quarters","months","weeks","days","hours","minutes"),
                              unit=c( "months","months","weeks","days","hours","minutes"),
                             interval=c(3, 1, 1, 1, 1, 15.0),
                             last.updated=rep(mock.time, 6),
                             locked=rep(FALSE, 6))
  
  if(file.exists("update_states.RDS")){
    update.states <- readRDS("update_states.RDS")
  }
  
  for (i in 1:nrow(update.states)){
    current.time <- Sys.time()
    test.int <- as.interval(difftime(current.time, update.states[i,"last.updated"], units="mins"), start=update.states[i,"last.updated"])
    is.due <- (as.period(test.int) %/% do.call(as.character(update.states[i, "unit"]), list(1))) >= update.states[i,"interval"]
    is.locked <- update.states[i, "locked"]
    if(is.due && !is.locked){
      update.states[i, "locked"] <- TRUE
      saveRDS(update.states, "update_states.RDS")
      intervalFunc <- paste0(update.states[i, "func.label"], "Function")
      running.alert <- paste0("Running ",intervalFunc)
      actionNotify(running.alert)
      
      func.successful <- try(runParallelFunc(parallel.func.name = intervalFunc))
      actionNotify(func.successful)
      if(!inherits(func.successful, "try-error")){update.states[i, "last.updated"] <- current.time}
      update.states[i, "locked"] <- FALSE
      saveRDS(update.states, "update_states.RDS")
    }
  }
}

runParallelFunc <- function(parallel.func.name, args=list()){
  cl <- makeCluster(detectCores()) # -!system.config$live
  registerDoParallel(cl)
  clusterEvalQ(cl,source("sources.R"))
  clusterExport(cl, c("system.config"))
  
  func.successful <- try(do.call(parallel.func.name, args=args))
  
  stopCluster(cl)
  registerDoSEQ()
  return(func.successful)
}

testFunction <- function(){return("Test Successful")}

minutesFunction <- function(){
  # update & note account value
  account.value <- recordAccountValue()
  # check in on open orders and adjust accordingly
  open.orders <- updateOpenOrders()
  updateCurrentPositions()
  return(list(account.value,
              open.orders))
}

hoursFunction <- function(){
  # cancel open orders
  # refreshVolatility (not forecasts or anything else)
  # determine trades to make
  # make trades
  canceling.orders <- NULL
  if(system.config$live){canceling.orders <- cancelAllOrders()}
  
  refreshed.pricing <- refreshPortfolioPricing()
  updateCurrentPositions()
  updateRefPrices()
  updateInstrumentVolatilities()
  updateSubsystemPositions()
  updateOptimalPositions()
  
  trades.to.make <- tradesToMake()
  trades.made <- NULL
  if(system.config$live){trades.made <- makeTrades()}
  return(list(refreshed.pricing,
              canceling.orders,
              trades.to.make,
              trades.made))
}

daysFunction <- function(){
  # volatilityTargetChecking()
  # reporting
  # update pricing
  # cancel open trades
  canceling.orders <- NULL
  if(system.config$live){canceling.orders <- cancelAllOrders()}
  # refresh forecasts and volatility
  refreshed.pricing <- refreshPortfolioPricing()
  updateCurrentPositions()
  updateRefPrices()
  updateInstrumentVolatilities()
  updateInstrumentForecasts()
  updateSubsystemPositions()
  updateOptimalPositions()
  
  trades.to.make <- tradesToMake()
  trades.made <- NULL
  if(system.config$live){trades.made <- makeTrades()}
  return(list(refreshed.pricing,
              canceling.orders,
              trades.to.make,
              trades.made))
}

weeksFunction <- function(){
  refreshed.pricing <- refreshAllPricing()
  refreshed.pairs <- refreshPortfolioPairs()
  simulated.forecasts <- simulateForecasts()
  raw.forecast.weights <- rawForecastWeights()
  smoothed.forecast.weights <- smoothedForecastWeights()
  simulated.subsystems <- simulateSubsystems()
  raw.instrument.weights <- rawInstrumentWeights()
  smoothed.instrument.weights <- smoothedInstrumentWeights()
  
  updateInstrumentWeights()
  
  return(list(refreshed.pricing,
              refreshed.pairs,
              simulated.forecasts,
              raw.forecast.weights,
              smoothed.forecast.weights,
              simulated.subsystems,
              raw.instrument.weights,
              smoothed.instrument.weights))
}

monthsFunction <- function(){
  return.temp <- "Nothing in this function yet"
  return(return.temp)
}

quartersFunction <- function(){
  # distributions
  return.temp <- "Nothing in this function yet"
  return(list(return.temp))
}
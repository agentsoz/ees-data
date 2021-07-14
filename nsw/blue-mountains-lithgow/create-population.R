N <- 1000
addressesFile <- 'blue-mountains-lithgow-addresses-epsg7855.csv'
pHasDependents <- .2

popn <- data.frame(
  # java class for modelled behaviour
  BDIAgentType = character(N),
  # daily activities locations
  homeX = double(N),
  homeY = double(N),
  # evacuation related locations
  EvacLocationPreference = character(N),
  InvacLocationPreference = character(N),
  # for those with dependants
  HasDependents = character(N),
  HasDependentsAtLocation = character(N),
  WillGoHomeAfterVisitingDependents = character(N),
  # for those without dependants
  WillGoHomeBeforeLeaving = character(N),
  # those determined to stay
  WillStay = character(N),
  # response thresholds
  ResponseThresholdInitial = double(N),
  ResponseThresholdFinal = double(N),
  # deliberation times
  LagTimeInMinsForFinalResponse = double(N),
  LagTimeInMinsForInitialResponse = double(N),
  # impact values
  ImpactFromFireDangerIndexRating = double(N),
  ImpactFromImmersionInSmoke = double(N),
  ImpactFromMessageAdvice = double(N),
  ImpactFromMessageEmergencyWarning = double(N),
  ImpactFromMessageEvacuateNow = double(N),
  ImpactFromMessageRespondersAttending = double(N),
  ImpactFromMessageWatchAndAct = double(N),
  ImpactFromSocialMessage = double(N),
  ImpactFromVisibleEmbers = double(N),
  ImpactFromVisibleFire = double(N),
  ImpactFromVisibleResponders = double(N),
  ImpactFromVisibleSmoke = double(N)
)

popn$BDIAgentType <- rep("io.github.agentsoz.ees.agents.archetype.ArchetypeAgent",N)

csv <- read.csv(addressesFile)
idx <- sample(nrow(csv), N, replace = (N > nrow(csv)))
df <- csv[idx,]
popn$homeX <- df$X
popn$homeY <- df$Y


popn$EvacLocationPreference <- "Cranebrook,845070,6263955"
popn$InvacLocationPreference <- "Cranebrook,845070,6263955"
popn$HasDependents <- runif(100) < pHasDependents
idx <- sample(nrow(csv), length(popn$HasDependents), replace = (N > nrow(csv)))
# now combine xy and assign 
# popn$HasDependentsAtLocation <- 
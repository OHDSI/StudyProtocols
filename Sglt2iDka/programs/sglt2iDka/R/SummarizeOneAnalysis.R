#' @export
summarizeOneAnalysis <- function(outcomeModel) {

  result <- data.frame(rr = 0,
                       ci95lb = 0,
                       ci95ub = 0,
                       p = 1,
                       treated = 0,
                       comparator = 0,
                       treatedDays = NA,
                       comparatorDays = NA,
                       eventsTreated = 0,
                       eventsComparator = 0,
                       logRr = 0,
                       seLogRr = 0)

  result$rr <- if (is.null(coef(outcomeModel)))
    NA else exp(coef(outcomeModel))
  result$ci95lb <- if (is.null(coef(outcomeModel)))
    NA else exp(confint(outcomeModel)[1])
  result$ci95ub <- if (is.null(coef(outcomeModel)))
    NA else exp(confint(outcomeModel)[2])
  if (is.null(coef(outcomeModel))) {
    result$p <- NA
  } else {
    z <- coef(outcomeModel)/outcomeModel$outcomeModelTreatmentEstimate$seLogRr
    result$p <- 2 * pmin(pnorm(z), 1 - pnorm(z))
  }
  result$treated <- outcomeModel$populationCounts$treatedPersons
  result$comparator <- outcomeModel$populationCounts$comparatorPersons
  if (outcomeModel$outcomeModelType %in% c("cox", "poisson")) {
    result$treatedDays <- outcomeModel$timeAtRisk$treatedDays
    result$comparatorDays <- outcomeModel$timeAtRisk$comparatorDays
  }
  result$eventsTreated <- outcomeModel$outcomeCounts$treatedOutcomes
  result$eventsComparator <- outcomeModel$outcomeCounts$comparatorOutcomes
  result$logRr <- if (is.null(coef(outcomeModel)))
    NA else coef(outcomeModel)
  result$seLogRr <- if (is.null(coef(outcomeModel)))
    NA else outcomeModel$outcomeModelTreatmentEstimate$seLogRr

  return(result)
}

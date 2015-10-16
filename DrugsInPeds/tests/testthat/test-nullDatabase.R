library(testthat)

test_that("Fail to connect", {

    expect_error(execute(dbms = "",
                         user = "",
                         password = "",
                         server = "",
                         cdmSchema = "",
                         resultsScheme = ""), regexp = "Failed to connect")
})

test_that("Execute against empty OMOP CDM databases", {

    executeResultSize <- 2 # Set to count of objects generated in execute()

    result1 <- execute(dbms = "postgresql",
                       server="jenkins.ohdsi.org/sandbox",
                       user = "patrick",
                       password = "gh_56Fd8L",
                       port = 5432,
                       cdmSchema = "CDMV5",
                       resultsScheme = "patrick")

    expect_equal(length(result1),executeResultSize)

    result2 <- execute(dbms = "sql server",
                       server="jenkins.ohdsi.org",
                       user = "patrick",
                       password = "gh_56Fd8L",
                       port = 1433,
                       cdmSchema = "CDMV5",
                       resultsScheme = "patrick")

    expect_equal(length(result2),executeResultSize)

    result3 <- execute(dbms = "oracle",
                       server="jenkins.ohdsi.org/XE",
                       user = "patrick",
                       password = "gh_56Fd8L",
                       #port = 1521,
                       cdmSchema = "CDMV5",
                       resultsScheme = "patrick")

    expect_equal(length(result3),executeResultSize)
})

library(testthat)

test_that("Execute again an empty OMOP CDM database", {
    
    executeResultSize <- 2 # Set to count of objects generated in execute()

    result <- execute(dbms = "",
                      user = "",
                      password = "",
                      server = "",
                      cdmSchema = "")
    
    expect_equal(length(result),executeResultSize) 
    
    
})
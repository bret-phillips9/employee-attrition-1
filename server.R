server <- function(input, output, session) {
  selected_employee <- reactive({
    test[input$employee, ]
  })

  output$prediction <- renderPrint({
    emp <- selected_employee()
    pred <- predict(model, emp, type = "prob")
    paste0("Probability of Attrition: ", round(pred[2] * 100, 2), "%")
  })

  observeEvent(input$explain, {
    emp <- selected_employee()
    input_data <- emp %>% select(Age, JobSatisfaction, MonthlyIncome, OverTime, TotalWorkingYears, YearsAtCompany)
    prompt <- paste("Explain why this employee might leave:", toJSON(input_data, auto_unbox = TRUE))

    # Call OpenAI (replace with your actual API key)
    res <- POST("https://api.openai.com/v1/chat/completions",
                add_headers(Authorization = paste("Bearer", Sys.getenv("OPENAI_API_KEY"))),
                content_type_json(),
                body = list(
                  model = "gpt-4",
                  messages = list(
                    list(role = "system", content = "You are an HR analytics expert."),
                    list(role = "user", content = prompt)
                  )
                ), encode = "json")

    explanation <- content(res)$choices[[1]]$message$content
    output$llm_explanation <- renderText(explanation)
  })
}

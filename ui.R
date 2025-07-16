# theme definition
appTheme <- bs_theme(
  version = 5,
  bootswatch = "minty"
)

# sidebar for user input and explain button
appSidebar <- sidebar(
  h4("Input Data"),
  selectInput("employee", "Select Employee ID:", choices = test$EmployeeNumber),
  actionButton("explain", "Explain Prediction")
)

# main body 
appMain <- mainPanel(
  tabsetPanel(
    tabPanel("Individual Prediction",
             includeMarkdown("instructions.md"),
             textOutput("emp_head"),
             textOutput("prediction"),
             textOutput("llm_explanation")
    ),
    tabPanel("Confusion Matrix",
             includeMarkdown("confusion.md"),
             verbatimTextOutput("confusion_matrix")
    ),
    tabPanel("Feature Importance",
             includeMarkdown("importance.md"),
             plotOutput("var_importance")
    )
  )
)

# main page code
page_sidebar(
  title = "Attrition Insights with ChatGPT",
  sidebar = appSidebar,
  theme = appTheme,
  appMain
)


require(mxnet)
require(imager)
require(shiny)
require(jpeg)
require(png)

shinyUI(pageWithSidebar(
  headerPanel(title = 'Image Classification using MXNetR', 
              windowTitle = 'Image Classification using MXNetR'),
  
  sidebarPanel(
    includeCSS('boot.css'),
    helpText("Upload Image"),
    fileInput('file1', 'Upload a PNG / JPEG File:')
  ),
  
  mainPanel(
    tabPanel(
      "Let's do this!",
      h3("Image"),
      tags$hr(),
      imageOutput("originImage", height = "auto"),
      tags$hr(),
      h3("What is in it?"),
      tags$hr(),
      verbatimTextOutput("res")
    )
  )
))

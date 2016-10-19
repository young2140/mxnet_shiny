require(mxnet)
require(imager)
require(shiny)
require(jpeg)
require(png)

if (!file.exists("synset.txt")) {
  download.file("http://data.dmlc.ml/mxnet/models/imagenet/inception-bn.tar.gz", destfile = "inception-bn.tar.gz")
  untar("Inception.zip")
}

model <<- mx.model.load("./Inception-BN", iteration = 126)

synsets <<- readLines("synset.txt")

preproc.image <- function(im, mean.image) {
  # crop the image
  shape <- dim(im)
  short.edge <- min(shape[1:2])
  xx <- floor((shape[1] - short.edge) / 2)
  yy <- floor((shape[2] - short.edge) / 2) 
  croped <- crop.borders(im, xx, yy)
  # resize to 224 x 224, needed by input of the model.
  resized <- resize(croped, 224, 224)
  # convert to array (x, y, channel)
  arr <- as.array(resized) * 255
  dim(arr) <- c(224, 224, 3)
  # substract the mean
  normed <- arr - 117
  # Reshape to format needed by mxnet (width, height, channel, num)
  dim(normed) <- c(224, 224, 3, 1)
  return(normed)
}

shinyServer(function(input, output) {
  ntext <- eventReactive(input$goButton, {
    print(input$url)
    if (input$url == "http://") {
      NULL
    } else {
      tmp_file <- tempfile()
      download.file(input$url, destfile = tmp_file)
      tmp_file
    }
  })
  
  output$originImage = renderImage({
    list(src = if (input$tabs == "Upload Image") {
      if (is.null(input$file1)) {
        if (input$goButton == 0 || is.null(ntext())) {
          'cthd.jpg'
        } else {
          ntext()
        }
      } else {
        input$file1$datapath
      }
    } else {
      if (input$goButton == 0 || is.null(ntext())) {
        if (is.null(input$file1)) {
          'cthd.jpg'
        } else {
          input$file1$datapath
        }
      } else {
        ntext()
      }
    },
    title = "Original Image")
  }, deleteFile = FALSE)
  
  output$res <- renderText({
    src = if (input$tabs == "Upload Image") {
      if (is.null(input$file1)) {
        if (input$goButton == 0 || is.null(ntext())) {
          'cthd.jpg'
        } else {
          ntext()
        }
      } else {
        input$file1$datapath
      }
    } else {
      if (input$goButton == 0 || is.null(ntext())) {
        if (is.null(input$file1)) {
          'cthd.jpg'
        } else {
          input$file1$datapath
        }
      } else {
        ntext()
      }
    }
    
    im <- load.image(src)
    normed <- preproc.image(im, mean.img)
    prob <- predict(model, X = normed)
    max.idx <- order(prob[,1], decreasing = TRUE)[1:5]
    result <- synsets[max.idx]
    res_str <- ""
    for (i in 1:5) {
      tmp <- strsplit(result[i], " ")[[1]]
      for (j in 2:length(tmp)) {
        res_str <- paste0(res_str, tmp[j])
      }
      res_str <- paste0(res_str, "\n")
    }
    res_str
  })
  
})

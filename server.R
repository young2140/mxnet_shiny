require(mxnet)
require(imager)
require(shiny)
require(jpeg)
require(png)

if (!file.exists("Inception/synset.txt")) {
  download.file("http://webdocs.cs.ualberta.ca/~bx3/data/Inception.zip", destfile="Inception.zip")
  unzip("Inception.zip")
}

model <<- mx.model.load("Inception/Inception_BN", iteration = 39)

synsets <<- readLines("Inception/synset.txt")

mean.img <<- as.array(mx.nd.load("Inception/mean_224.nd")[["mean_img"]])

preproc.image <- function(im, mean.image) {
  # crop the image
  shape <- dim(im)
  short.edge <- min(shape[1:2])
  yy <- floor((shape[1] - short.edge) / 2) + 1
  yend <- yy + short.edge - 1
  xx <- floor((shape[2] - short.edge) / 2) + 1
  xend <- xx + short.edge - 1
  croped <- im[yy:yend, xx:xend,,]
  # resize to 224 x 224, needed by input of the model.
  resized <- resize(croped, 224, 224)
  # convert to array (x, y, channel)
  arr <- as.array(resized)
  dim(arr) = c(224, 224, 3)
  # substract the mean
  normed <- arr - mean.img
  # Reshape to format needed by mxnet (width, height, channel, num)
  dim(normed) <- c(224, 224, 3, 1)
  return(normed)
}

shinyServer(function(input, output) {
  output$originImage = renderImage({
    list(src = if (is.null(input$file1))
      'cthd.jpg'
      else
        input$file1$datapath,
      title = "Original Image")
    
  }, deleteFile = FALSE)
  
  output$svdImage = renderImage({
    result2 = doRecovery()
    
    list(src = result2$out,
         title = paste("Compressed Image with k = ", as.character(result2$k)))
  })
  
  output$res <- renderText({
    src = if (is.null(input$file1)) 'cthd.jpg' else input$file1$datapath
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

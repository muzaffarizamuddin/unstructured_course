install.packages("imager")
library(imager)
file <- system.file('extdata/parrots.png',package='imager')
parrots <- load.image(file)
plot(parrots) #Parrots
rose <- load.image("C:/Users/PC03/Desktop/Unstructured - Muz/Image/Rose.PNG") #Load image
plot(rose) #Rose
save.image(rose,"Rose.jpeg") #save image
parrots.blurry <- isoblur(parrots,10) #Blurry parrots
parrots.xedges <- deriche(parrots,2,order=2,axis="x") #Edge detector along x-axis
parrots.yedges <- deriche(parrots,2,order=2,axis="y") #Edge detector along y-axis
gray.parrots <- grayscale(parrots) #Make grayscale
plot(gray.parrots)

#Denoising
birds <- load.image(system.file('extdata/Leonardo_Birds.jpg',package='imager'))
birds.noisy <- (birds + .5*rnorm(prod(dim(birds))))
layout(t(1:2))
plot(birds.noisy,main="Original")
isoblur(birds.noisy,5) %>% plot(main="Blurred")
plot(birds.noisy,main="Original")
blur_anisotropic(birds.noisy,ampl=1e3,sharp=.3) %>% plot(main="Blurred (anisotropic)")

#Resize, rotate, ext.
thmb <- resize(parrots,round(width(parrots)/10),round(height(parrots)/10))
plot(thmb,main="Thumbnail") #Pixellated parrots
thmb <- resize(parrots,-10,-10)
imrotate(parrots,30) %>% plot(main="Rotating") #Rotate
imshift(parrots,40,20) %>% plot(main="Shifting") #Shift
imshift(parrots,100,100,boundary=2) %>% plot(main="Shifting (circular)") #Shift circular
#Histogram equalisations
plot(boats)
grayscale(boats) %>% hist(main="Luminance values in boats picture")
R(boats) %>% hist(main="Red channel values in boats picture")
library(ggplot2)
library(dplyr)
bdf <- as.data.frame(boats)
head(bdf,3)
bdf <- mutate(bdf,channel=factor(cc,labels=c('R','G','B')))
ggplot(bdf,aes(value,col=channel))+geom_histogram(bins=30)+facet_wrap(~ channel)

#Normalizing
x <- rnorm(100)
layout(t(1:2))
hist(x,main="Histogram of x")
f <- ecdf(x)
hist(f(x),main="Histogram of ecdf(x)")
boats.g <- grayscale(boats)
f <- ecdf(boats.g)
plot(f,main="Empirical CDF of luminance values")
f(boats.g) %>% hist(main="Transformed luminance values")
f(boats.g) %>% str
f(boats.g) %>% as.cimg(dim=dim(boats.g)) %>% plot(main="With histogram equalisation")
#Morphological operations
im <- load.example("birds")
plot(im)
im.g <- grayscale(im)
plot(im.g)
layout(t(1:3))
threshold(im.g,"20%") %>% plot
threshold(im.g,"15%") %>% plot
threshold(im.g,"10%") %>% plot
layout(t(1:1))

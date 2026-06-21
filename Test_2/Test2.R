#Name: Muzaffar Izamuddin bin Daud
#Matrix number: P166246
# Question 3 R code

install.packages('tuneR')
install.packages('seewave')
library(tuneR)
library(seewave)

plot.frequency.spectrum <- function(X.k, xlimits=c(0,length(X.k))) {
    plot.data <- cbind(0:(length(X.k)-1), Mod(X.k))
    plot.data[2:length(X.k),2] <- 2*plot.data[2:length(X.k),2]   # scale (all except DC bin)
    plot(plot.data, t="h", lwd=2, main="",
    xlab="Frequency (Hz)", ylab="Strength",
    xlim=xlimits, ylim=c(0,max(Mod(plot.data[,2]))))
}

z <- readWave("C:/Users/PC03/Desktop/Unstructured - Muz/Test_2/audio.wav")
play(z)

timer(z, f=22050, threshold=25, msmooth=c(1500,0)) #question 3a

install.packages('rpanel') 
library(rpanel)
spectro(z)   #question 3b

Zk <- fft(z@left) #question 3c
plot.frequency.spectrum(Zk)
plot.frequency.spectrum(Zk[1:40000])      #question 3d
title("Frequency Spectrum Plot of audio.wav")


layout(t(1:1))                        
windows(10,10)
dynspec(z, wl=1024, osc=T)     #supporting for question 3e                                  
meanspec(z)  #not used in this test, but plots an average of the frequency spectrum

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

z <- readWave("C:/Users/PC03/Desktop/Unstructured - Muz/Audio/babycry.wav")
play(z)

timer(z, f=22050, threshold=20, msmooth=c(50,0))

Zk <- fft(z@left)
plot.frequency.spectrum(Zk)
plot.frequency.spectrum(Zk[1:20000])      


layout(t(1:1))                        
# reset layout before dynspec
install.packages('rpanel')
library(rpanel)
windows(10,10)
dynspec(z, wl=1024, osc=T)            
spectro(z)                             
meanspec(z)  

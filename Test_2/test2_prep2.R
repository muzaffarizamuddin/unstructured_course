library(tuneR)
library(seewave)
z1 <- readWave("C:/Users/PC03/Desktop/Unstructured - Muz/Audio/babycry.wav")
play(z1)
z2 <- readWave("C:/Users/PC03/Desktop/Unstructured - Muz/Audio1.wav")# Side-by-side spectrogramspar(mfrow=c(1,2))
play(z2)

plot.frequency.spectrum <- function(X.k, xlimits=c(0,length(X.k))) {
    plot.data <- cbind(0:(length(X.k)-1), Mod(X.k))
    plot.data[2:length(X.k),2] <- 2*plot.data[2:length(X.k),2]   # scale (all except DC bin)
    plot(plot.data, t="h", lwd=2, main="",
    xlab="Frequency (Hz)", ylab="Strength",
    xlim=xlimits, ylim=c(0,max(Mod(plot.data[,2]))))
}


spectro(z1, main="Before")
spectro(z2, main="After")# Side-by-side mean spectrapar
(mfrow=c(2,1))
meanspec(z1, main="Before")
meanspec(z2, main="After")# FFT comparison
layout(t(1:1))
Zk1 <- fft(z1@left)
Zk2 <- fft(z2@left)
par(mfrow=c(2,1))
plot.frequency.spectrum(Zk1[1:20000])
title("Before")
plot.frequency.spectrum(Zk2[1:20000])
title("After")

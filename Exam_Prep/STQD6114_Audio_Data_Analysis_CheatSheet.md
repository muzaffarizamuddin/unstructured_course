# STQD6114 — Audio Data Analysis: Theory Cheat Sheet
### 20 Likely Theory Questions with Model Answers

---

## Q1. What is an audio signal, and what is the audible frequency range for humans?

**Model Answer:**
An **audio signal** is the representation of sound in the form of digital or analog signals. Sound frequencies range between **20 Hz and 20,000 Hz (20 kHz)** — this is the lower and upper limit of the human ear. The human auditory system is **most sensitive between 500 Hz and 5,000 Hz**.

---

## Q2. Can sound below 20 Hz affect humans even if it cannot be heard? Explain, referencing infrasound.

**Model Answer:**
Yes. Sound under 20 Hz (infrasound) cannot be consciously heard but can still physically affect the ear/body. **Infrasound at 7 Hz is especially dangerous** because this frequency is close to the characteristic (resonant) frequencies of organs in the human body, and it may disturb heart or brain activity.

---

## Q3. Define Digital Signal Processing (DSP) and define what a "signal" is.

**Model Answer:**
**Digital Signal Processing (DSP)** is concerned with the representation of signals by a sequence of numbers or symbols, and the processing of these sequences.

A **signal** is a function that conveys information, generally about the state or behavior of a physical system. Mathematically, signals are represented as functions of one or more independent variables (e.g., amplitude as a function of time, A(t)).

---

## Q4. Differentiate between continuous-time (analog) signals and discrete-time signals.

**Model Answer:**

| Type | Definition |
|---|---|
| **Analog (continuous-time) signal** | A signal for which **both time and amplitude are continuous** (defined at every instant) |
| **Discrete-time signal** | A signal that is **defined only at discrete units of time** (sampled at specific time points) |

Digital signal processing works with discrete-time signals, which are obtained by sampling a continuous analog signal.

---

## Q5. Differentiate Analog Signal Processing and Digital Signal Processing.

**Model Answer:**

| Aspect | Analog Signal Processing | Digital Signal Processing |
|---|---|---|
| Signal type processed | Analog signals | Discrete (digitized) signals |
| Processing hardware | Electrical networks of active and passive components | General-purpose computers, ASICs, FPGAs, DSP chips, etc. |

Signal processing overall involves **analyzing, modifying, and synthesizing** signals to extract meaning from them.

---

## Q6. Draw/describe the block diagram of a digital signal processing (DSP) system and explain each block.

**Model Answer:**
The typical block diagram flow is:

**Analog Input Signal → Pre-Filter → ADC → DSP → DAC → Post-Filter → Analog Output Signal**

| Block | Function |
|---|---|
| **Pre-Filter** | Filters out unwanted high-frequency components from the raw analog input signal |
| **ADC** (Analog-to-Digital Converter) | Converts the analog signal into a digital signal |
| **DSP** (Digital Signal Processor) | The digital signal is analyzed and processed; the synthesized output is fed to the DAC |
| **DAC** (Digital-to-Analog Converter) | Converts the processed digital signal back into an analog signal |
| **Post-Filter** | Filters out unwanted high-frequency components in the generated (reconstructed) analog signal |

---

## Q7. List the main applications of digital signal processing systems.

**Model Answer:**
- Speech and audio processing
- Image and video processing
- Military and telecommunication
- Healthcare and biomedical sector
- Consumer electronics

---

## Q8. List the advantages and disadvantages of digital signal processing systems.

**Model Answer:**

**Advantages:**
- Flexibility
- Error detection and correction features
- Easier data storage
- Low cost

**Disadvantages:**
- Higher power consumption
- A higher learning curve is required for operation

---

## Q9. Explain three important concepts in digital signal processing: Fourier Transforms, Noise, and Filters.

**Model Answer:**

| Concept | Explanation |
|---|---|
| **Fourier Transforms** | Signal processing often involves looking at the **frequency representation** of a signal, for both insight (understanding what frequencies are present) and computation |
| **Noise** | Any signal that is **not desired**. A large part of signal processing is understanding how noise affects the data and how to efficiently remove or manage it |
| **Filters** | Tools that allow removal of specific portions of a signal (e.g., certain frequency bands) at once, or allow removal of noise from a signal |

---

## Q10. In a signal/sound wave, differentiate between frequency, wavelength, and amplitude.

**Model Answer:**
- **Frequency**: the number of wave cycles that pass a point per unit time (related to pitch for sound). A **short wavelength** means many waves pass by in a given time → **high frequency**. A **long wavelength** means fewer waves pass by → **low frequency**.
- **Wavelength**: the physical length of one complete wave cycle; it is inversely related to frequency (waves travel at approximately the same speed, so shorter wavelength = higher frequency).
- **Amplitude**: the height (magnitude) of the wave, corresponding to the loudness/volume of a sound. A wave with a smaller amplitude represents a softer sound than a wave with a larger amplitude at the same frequency.

---

## Q11. What is the difference between pitch and loudness?

**Model Answer:**
- **Pitch** of a sound depends on the **frequency** of the sound wave — higher frequency = higher pitch; lower frequency = lower pitch.
- **Loudness** of a sound depends on the **amplitude** of the sound wave — higher amplitude = louder sound; lower amplitude = softer sound.

These two properties are independent: a sound can increase in pitch (frequency ↑) while loudness (amplitude) stays constant, or vice versa.

---

## Q12. What is a Fourier Transform? Who developed it, and what does it do to a signal?

**Model Answer:**
A **Fourier Transform** is a reversible mathematical transform developed by **Joseph Fourier** in the early 1800s. It breaks apart a time series (signal) into a sum of a finite series of **sine and cosine functions** — i.e., any signal can be decomposed into a series of sine and cosine curves of different frequencies and amplitudes. Being reversible means the original time-domain signal can be reconstructed from its frequency components.

---

## Q13. What is the Discrete Fourier Transform (DFT), and what does it allow you to do?

**Model Answer:**
The **Discrete Fourier Transform (DFT)** is a specific form of the Fourier Transform applied to a discretized time wave (a digitized signal). The DFT allows you to switch from working in the **time domain** to the **frequency domain**, by using the amplitude and frequency information of the signal to build the **frequency spectrum** of the original time wave (i.e., showing how much of each frequency is present in the signal).

---

## Q14. What is "window length/size" in the context of applying a Fourier Transform, and what trade-off does it involve?

**Model Answer:**
To apply a Fourier Transform to a signal, a **window size** (window length) must be chosen — this controls the length/duration of signal used for each transform computation.

**Trade-off:**
- **Increasing** the window size **increases frequency resolution** (better able to distinguish close frequencies), but it **decreases time accuracy**, because more of the signal (a longer time span) is being combined into a single transform, blurring exactly *when* in time a frequency occurred.
- Computing a single Fourier Transform over an entire sound (or one long segment) may therefore not give enough time-localized information — this motivates computing the transform over successive short sections instead (see Q15).

---

## Q15. What is a Short-Time Fourier Transform (STFT)? How does it work?

**Model Answer:**
Rather than computing one Fourier Transform over an entire signal, the **Short-Time Fourier Transform (STFT)** computes the DFT repeatedly on **successive short sections** along the whole signal: a window is "**slided**" (moved incrementally) along the signal, and a DFT is computed at each position of the window.

This method allows the signal to be represented in the **frequency spectrum** while also **retaining most of the time-dimension information** — i.e., it shows how the frequency content of a signal changes over time.

---

## Q16. What is a spectrogram, and why is it useful?

**Model Answer:**
A **spectrogram** is a plot of the results of an STFT — typically with **time on the x-axis, frequency on the y-axis**, and color/intensity representing the amplitude/strength at each time-frequency point.

**Why useful:** A spectrogram is especially useful in bioacoustics, acoustics, and ecoacoustics because it allows **three variables (time, frequency, amplitude) to be represented in a single 2D plot**, avoiding the need for a less-appealing/harder-to-read 3D representation.

---

## Q17. Describe the three categories of digitized sound files that can be handled in R, and their trade-offs.

**Model Answer:**

| Format | File type | Description |
|---|---|---|
| `.wav` | Uncompressed format | Full information is stored, resulting in a **heavy (large) file** |
| `.mp3` | Lossy compressed format | Information is **reduced**; time, amplitude, and frequency parameters can be impaired/degraded |
| `.flac` | Losslessly compressed format | The **full information is preserved** but stored in a **reduced-size** file |

All three formats ultimately generate **binary files**, with sound encoded as a succession of 0s and 1s.

---

## Q18. Name key R packages used for audio/sound analysis and describe their general purpose.

**Model Answer:**

| Package | Purpose |
|---|---|
| **tuneR** | Reading/writing/creating audio (`Wave` objects), generating waveforms (`sine`, `square`, `pulse`, `sawtooth`, `noise`), playing audio (`play`), reading/writing `.wav` files (`readWave`, `writeWave`) |
| **seewave** | Analysis and visualization of sound: `spectro()` (spectrogram), `meanspec()` (average spectrum across the whole duration), `dynspec()` (dynamic/interactive spectrogram), `timer()` (detect/measure signal vs. silence sections) |

Both packages work together — e.g., a `Wave` object created or read in via `tuneR` can be passed directly into `seewave` functions such as `spectro()` or `meanspec()` for analysis.

---

## Q19. Explain, conceptually, how a synthetic sine wave audio signal is constructed (sampling rate, time vector, frequency).

**Model Answer:**
To construct a synthetic tone (e.g., a 440 Hz sine wave) digitally:
1. Choose a **sampling rate (sr)** — the number of samples taken per second (e.g., 8000 Hz), which determines how finely time is discretized.
2. Build a **time vector**, t, of evenly spaced time points based on the sampling rate and the desired duration (e.g., from 0 to 2 seconds in steps of 1/sr).
3. Compute the signal's amplitude at each time point using the sine function scaled to the desired frequency and amplitude range, e.g., y = A·sin(2π·f·t), where f is the desired tone frequency (e.g., 440 Hz) and A scales the amplitude to fit the bit-depth range (e.g., 2¹⁵−1 for 16-bit audio).
4. Wrap the numeric vector into a `Wave` object together with the sampling rate and bit depth, which can then be played back or saved as a `.wav` file.

This illustrates the core sampling/quantization idea from DSP: the **sampling rate** controls time resolution, and the **bit depth** controls amplitude resolution, directly paralleling image sampling and quantization.

---

## Q20. Explain why only "half" of an FFT/DFT output spectrum is typically plotted (mirroring), and what a spectrogram function like `spectro()` shows compared to `meanspec()`.

**Model Answer:**
When a Fast Fourier Transform (FFT/DFT) is applied to a real-valued audio signal, the resulting frequency spectrum is **symmetric (mirrored)** about the midpoint — the second half of the output duplicates (mirrors) the information in the first half. Therefore, in practice, analysts plot and interpret **only the first half** of the FFT output (e.g., `Ticok[1:(length(Ticok)/2)]`) since the second half carries no additional information.

Regarding visualization functions:
- **`spectro()`** produces a full **spectrogram**: a 2D time–frequency plot (via STFT) showing how the frequency content of the signal changes **over time**.
- **`meanspec()`** produces the **average (mean) frequency spectrum** computed across the **entire duration** of the signal, collapsing the time dimension to show only the overall frequency profile.

---
---

# PART 2 — Applied / "Importance of..." Style Questions

*The lecturer noted that exam questions tend to be **less technical/mathematical** and more about explaining the **importance, relevance, and real-world impact** of a concept. The 10 questions below are written in that style — no formulas required, just clear, well-organized explanations.*

---

## Q21. Why is audio data analysis important in today's applications?

**Model Answer:**
Audio is one of the fastest-growing forms of unstructured data, driven by voice assistants (Siri, Alexa), call center recordings, podcasts, music streaming, and voice-based authentication. Audio data analysis is important because it allows organizations to extract meaningful information from sound — transcribing speech, detecting emotions in a customer service call, identifying a speaker, or monitoring machinery for early signs of failure through unusual sounds. As voice interfaces and smart devices become more common in daily life, the ability to process and interpret audio signals has moved from a specialized engineering skill to a mainstream data analytics requirement.

---

## Q22. Discuss the importance of understanding the human hearing frequency range (20 Hz–20 kHz) in product design.

**Model Answer:**
Knowing that humans hear between roughly 20 Hz and 20,000 Hz, and are most sensitive between 500 Hz and 5,000 Hz, is important for designing audio products efficiently. Headphone and speaker manufacturers use this range to decide what frequencies are worth reproducing accurately, hearing aid designers use it to know which frequency bands most need amplification for a hearing-impaired user, and noise-control engineers use it to identify which frequencies are actually perceptible and disruptive to people (e.g., in offices or near construction sites). It also explains safety concerns — sound outside this range, like 7 Hz infrasound, can still affect the body even though it can't be consciously heard, which matters for occupational health and building/vehicle vibration standards.

---

## Q23. Why is digital signal processing important compared to relying on analog processing in modern devices?

**Model Answer:**
Digital signal processing is important because it brings flexibility, accuracy, and reliability that analog systems struggle to match — digital systems can be reprogrammed with new algorithms, include error detection/correction, and store data far more easily and cheaply than analog equivalents. This is why nearly all modern audio devices — phones, hearing aids, streaming platforms, voice assistants — rely on digital rather than purely analog processing. The trade-off (higher power consumption and a steeper learning curve for engineers) is generally outweighed by the huge gains in functionality, consistency, and the ability to apply complex analysis (like noise reduction or speech recognition) that would be impractical with analog circuitry alone.

---

## Q24. Discuss the importance of noise reduction and filtering in real-world audio applications.

**Model Answer:**
Real-world audio is rarely clean — background chatter, wind, static, or electrical interference can all corrupt a recording. Effective noise reduction and filtering are important because they directly affect whether the *useful* part of a signal can still be understood or analyzed. For example, filtering background noise improves the accuracy of speech-to-text systems and voice assistants, helps forensic audio analysts recover intelligible speech from noisy recordings, and allows hearing aids to boost speech while suppressing background noise for the user. Without good noise handling, most downstream audio applications (transcription, biometric voice ID, medical diagnostics using sound) would perform poorly or unreliably.

---

## Q25. Why are the Fourier Transform and spectrogram important tools for analyzing sound, beyond the math itself?

**Model Answer:**
The Fourier Transform and the resulting spectrogram are important because they turn an otherwise hard-to-interpret waveform into a visual, frequency-based picture of what is actually happening in a sound over time. This is valuable across many fields: bioacousticians use spectrograms to identify bird or animal calls by their distinctive frequency patterns, speech scientists use them to study how vowels and consonants differ, doctors use frequency analysis of heart or lung sounds to detect abnormalities, and audio engineers use them to isolate and remove unwanted frequency bands (like hum or hiss). In short, they make the "invisible" frequency content of sound visible and analyzable, which is foundational to almost all serious audio analysis work.

---

## Q26. Discuss the importance of choosing the right audio file format (.wav, .mp3, .flac) for different real-world use cases.

**Model Answer:**
Choosing the right audio format matters because each involves a different trade-off between file size and audio quality. Uncompressed `.wav` files are important when the absolute full quality is needed (e.g., professional music production or scientific bioacoustic recordings that will be analyzed in detail), lossy `.mp3` is important for everyday consumer use like music streaming or podcasts where smaller file size and easy distribution matter more than perfect fidelity, and lossless `.flac` is important as a middle ground — for archiving important recordings (e.g., legal evidence, medical recordings, or master music tracks) where both quality preservation and reasonable file size are required. Making the wrong choice can mean either wasting storage/bandwidth unnecessarily or losing information that later analysis depends on.

---

## Q27. Why is audio data analysis relevant to a data scientist, even outside dedicated audio engineering roles?

**Model Answer:**
As more business and research problems involve unstructured data beyond text and numbers, a data scientist who understands the basics of audio analysis is better positioned to contribute to projects like analyzing customer call center recordings for sentiment or complaint patterns, building voice-based products, or working with sensor/vibration data that behaves like an audio signal (e.g., predictive maintenance from machinery sound). Even without deep DSP expertise, understanding core ideas like sampling rate, noise, and frequency analysis helps a data scientist ask the right questions, evaluate whether an audio-based solution is feasible, and communicate effectively with specialized signal-processing engineers.

---

## Q28. Discuss the importance of sampling rate and bit depth choices when digitizing audio.

**Model Answer:**
The sampling rate (how often the signal is measured per second) and bit depth (how finely each measurement is quantized) directly determine the quality and file size of a digitized recording. This matters practically because using a higher sampling rate/bit depth than necessary wastes storage and bandwidth (important for streaming services managing millions of files), while using too low a sampling rate or bit depth can degrade quality to the point that important information is lost — for example, a phone call sampled too coarsely may lose the subtle acoustic cues needed for accurate speaker or emotion recognition. Understanding this trade-off allows organizations to make sensible choices for their specific use case, rather than defaulting to "more is always better."

---

## Q29. Why is understanding the difference between pitch and loudness important in fields such as music, hearing health, or acoustic monitoring?

**Model Answer:**
Recognizing that pitch (frequency) and loudness (amplitude) are separate, independent properties of sound is important because many real-world problems depend on correctly identifying which one is actually changing. In music, this understanding underlies tuning and composition. In hearing health, audiologists must distinguish whether a patient's hearing loss is frequency-specific (certain pitches are harder to hear) versus volume-related (everything needs to be louder), which changes how a hearing aid should be configured. In acoustic/environmental monitoring, distinguishing a genuinely loud event from simply a different-pitched one can be the difference between correctly detecting a hazard (e.g., a machine fault with a distinct pitch signature) and generating a false alarm based on volume alone.

---

## Q30. Discuss ethical and privacy considerations relevant to audio data analysis.

**Model Answer:**
Audio recordings can capture highly personal and identifying information — a person's voice can be used for biometric identification, and recorded conversations may contain sensitive personal, medical, or business information. As audio analysis becomes more powerful (e.g., detecting emotion, identifying speakers, or even cloning voices), it raises real ethical concerns around consent (was the person aware they were being recorded/analyzed?), data security (how is sensitive voice data stored and protected?), and misuse (such as voice deepfakes used for fraud or impersonation). This means anyone working with audio data analysis has a responsibility to consider not just what is technically possible, but what is appropriate and legally compliant, particularly in sensitive contexts like healthcare, call centers, or surveillance.

---
---

# PART 3 — Quick Definitions / Glossary-Style Questions

*Short, direct "what is...?" style questions — the kind that test basic recall of terminology rather than full explanations. Keep these answers brief and precise.*

---

## Q31. What is a sound wave?

**Model Answer:**
A **sound wave** is a vibration that travels through a medium (like air) as variations in pressure over time, which we perceive as sound. It is typically represented as a waveform showing amplitude plotted against time.

---

## Q32. What is frequency?

**Model Answer:**
**Frequency** is the number of complete wave cycles that occur per second, measured in Hertz (Hz). In sound, frequency determines the **pitch** — a higher frequency is heard as a higher-pitched sound, and a lower frequency as a lower-pitched sound.

---

## Q33. What is amplitude?

**Model Answer:**
**Amplitude** is the magnitude (height) of a wave, representing how much a signal deviates from its baseline. In sound, amplitude determines the **loudness/volume** — a larger amplitude produces a louder sound, and a smaller amplitude produces a softer sound.

---

## Q34. What is wavelength?

**Model Answer:**
**Wavelength** is the physical distance between two corresponding points of consecutive wave cycles (e.g., peak to peak). Since sound waves travel at roughly the same speed, a **shorter wavelength** corresponds to a **higher frequency** (more waves passing a point per second), and a **longer wavelength** corresponds to a lower frequency.

---

## Q35. What is pitch?

**Model Answer:**
**Pitch** is the perceived highness or lowness of a sound, and it is determined by the **frequency** of the sound wave — higher frequency is perceived as higher pitch.

---

## Q36. What is loudness?

**Model Answer:**
**Loudness** is the perceived strength or volume of a sound, and it is determined by the **amplitude** of the sound wave — higher amplitude is perceived as louder sound.

---

## Q37. What is sampling rate?

**Model Answer:**
**Sampling rate** is the number of samples (measurements) taken of an analog signal per second when converting it to a digital signal, usually measured in Hz (e.g., 8000 Hz means 8000 samples per second). It determines the **time resolution** of the digitized signal — a higher sampling rate captures the original waveform more accurately.

---

## Q38. What is noise (in a signal)?

**Model Answer:**
**Noise** is any unwanted signal that is mixed in with the desired signal, degrading its quality — for example, static, hiss, or background interference in an audio recording. A major goal of signal processing is understanding, reducing, or removing noise.

---

## Q39. What is a filter (in signal processing)?

**Model Answer:**
A **filter** is a tool/technique used to remove or isolate specific portions of a signal — for example, removing unwanted high-frequency noise, or keeping only a certain frequency band of interest. Filters are applied in both the pre-processing (pre-filter) and post-processing (post-filter) stages of a DSP system.

---

## Q40. What is a spectrogram?

**Model Answer:**
A **spectrogram** is a visual plot showing how the frequency content of a signal changes over time, with time on one axis, frequency on the other, and color/intensity representing amplitude/strength. It is generated using the Short-Time Fourier Transform (STFT) and is widely used in speech, music, and bioacoustic analysis.


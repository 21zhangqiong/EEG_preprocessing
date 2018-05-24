The codes were for EEG data pre-processing in the following paper: 
Zhang, Q., Walsh, M. M., & Anderson, J. R. (2017). The effects of probe similarity on retrieval and comparison processes in associative recognition. Journal of cognitive neuroscience, 29(2), 352-367.


Procedures in pre-processing the EEG dataset:
1. step0 - prepare data for pre-processing
INPUT: .bdf
OUTPUT: **Step1.set
a) remove offset
b) find reference channels
c) low/high pass filtering
d) trim edges of files
Note: running subject2-4, subject5-21 separately due to different event coding

2. step1 - artifact rejection and ICA
INPUT: **Step1.set
OUTOUT: **Step2fast_50.set
a)remove bad channels across all windows
b)remove bad windows across all channels
c) run ICA using fastICA algorithm 
Note: for outlier channel/window identification, 4.5SD is used other than in subject 2 and 6 with 3SD

3. step2 - epoching and downsampling 
INPUT: **Step2fast_50.set
OUTPUT: **Step3fast_50s_100b.set
a) remove eye blink components (using ‘VEOG’ only)
b) remove auxillary sensors
c) interpolate signals from bad channels
d) epoch data into [-0.2s,5s]
e) clean epoched data (4.5SD)
f) reject epochs based on extreme values of central sensors (73,84,95,40,50)
g) downsample (with interpolation) data from 512Hz to 100Hz

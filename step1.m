clear all
close all
clc
%addpath('/Users/mwalsh/Desktop/Desktop/MATLAB/Support/My Functions/eeglab13_4_4b/','-end')
addpath('/home/qiongz/Desktop/eeglab13/','-end')
addpath('/home/qiongz/Desktop/eeganalysis/','-end')
addpath('/home/qiongz/Desktop/eeganalysis/private','-end')
addpath('/home/qiongz/Desktop/eeganalysis/ica_linux','-end')
addpath('/home/qiongz/Desktop/eeganalysis/FastICA','-end')
addpath('/share/volume0/qiongz/eegdata/','-end')
addpath('/home/qiongz/Desktop/eeganalysis/FastICA','-end')
eeglab;
close all

pop_editoptions('option_single', false, 'option_savetwofiles', false);

corr = zeros(1,20);
for subject = 2:21
    subject
    fname = char(['/share/volume0/qiongz/eegdata/subj' int2str(subject) 'Step1.set']);
    EEG = pop_loadset('filename',fname);
    EEG = eeg_checkset( EEG );

    fer(subject) = EEG.nbchan;
    
    %%remove bad channels
    image_name = char(['Subject' int2str(subject)]);
    if(subject==2|subject==6)
        [EEG corr(subject-1)]= clean_channels_mmw(EEG,2,.75,3,3,0.6277,image_name);
    else 
        [EEG corr(subject-1)]= clean_channels_mmw(EEG,2,.75,4.5,4.5,0.6277,image_name);
    end
    EEG = eeg_checkset( EEG );
    %     fname = char(['/Users/mwalsh/Desktop/Desktop/MATLAB/John/Experiment_16Jun2015/DATA/EEG/AUTO/subj' int2str(subject) 'Step1A.set']);
    %     pop_saveset( EEG, 'filename',fname);
    
    %remove bad windows
    image_name = char(['Epochs, Subject ', int2str(subject)]);
    
    if(subject==2|subject==6)
        EEG = clean_windows_mmw(EEG,2,.75,3,3,3,image_name);
    else
        EEG = clean_windows_mmw(EEG,2,.75,4.5,4.5,4.5,image_name);
    end
    EEG = eeg_checkset( EEG );
    
    fname = char(['/share/volume0/qiongz/eegdata/subj' int2str(subject) 'Step1B_50.set']);
    pop_saveset( EEG, 'filename',fname,'version','7.3');
    
    %run ICA
    good_chans = find((EEG.etc.clean_channel_mask == 0));
    %EEG = pop_runica(EEG, 'extended',0,'interupt','on','chanind',good_chans);
    EEG = pop_runica(EEG, 'icatype','fastica','chanind',good_chans);
    %EEG = binica(EEG, 'extended',0,'interupt','on','chanind',good_chans);
    %EEG = eeg_checkset( EEG );
    
    fname = char(['/share/volume0/qiongz/eegdata/subj' int2str(subject) 'Step2fast_50.set']);
    pop_saveset( EEG, 'filename',fname,'version','7.3');
    
    close all
    %clc
end
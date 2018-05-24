clear all
close all
clc

ct = zeros(20,2);
%addpath('/Users/mwalsh/Desktop/Desktop/MATLAB/Support/My Functions/eeglab13_4_4b/','-end')
addpath('/home/qiongz/Desktop/eeglab13/','-end')
addpath('/home/qiongz/Desktop/eeganalysis/','-end')
addpath('/share/volume0/qiongz/eegdata/','-end')

eeglab;
close all
12
pop_editoptions('option_single', false, 'option_savetwofiles', false);


 for subject = 2:21
    subject
    fname = char(['/share/volume0/qiongz/eegdata/subj' int2str(subject) 'Step2fast_50.set']);
    
    %%%Load file
    EEG = pop_loadset('filename',fname);
    EEG = eeg_checkset( EEG );
    labels = {EEG.chanlocs.labels};
    
    HEOG = [find(strcmp(labels,'LO1')) find(strcmp(labels,'LO2'))];
    VEOG = [find(strcmp(labels,'SO1')) find(strcmp(labels,'IO1'))];
    
    X = EEG.data;
    HEOG_BI = X(HEOG(1),:)-X(HEOG(2),:);
    VEOG_BI = X(VEOG(1),:)-X(VEOG(2),:);
    
    X(HEOG(1),:) = HEOG_BI;
    X(VEOG(1),:) = VEOG_BI;
    
    EEG.data = X;
    EEG.chanlocs(HEOG(1)).labels = 'HEOG';
    EEG.chanlocs(VEOG(1)).labels = 'VEOG';
    EEG = eeg_checkset( EEG );

    %%%Remove artifact components
    EEG = clean_components_mmw(EEG,30,.5,.4,.4);
    EEG = eeg_checkset( EEG );
    
    %%%Remove auxillary sensors
    EEG = pop_select( EEG,'nochannel',{'HEOG', 'VEOG', 'M1', 'M2', 'LO2','IO1','IO2','ECG'});
    EEG = eeg_checkset( EEG );
    
    %%%Interpolate signal from bad channels
    badchans = find(EEG.etc.clean_channel_mask);
    badchans = badchans(badchans < 128);
    
    EEG = eeg_interp(EEG,badchans);
    EEG = eeg_checkset( EEG );

%     for i = 1:total_events %%%Remaining events (including some boundaries)
%         index = event(i); %%% meaningful event index
%         
%         %%% Update code
%         if index < 9999
%             EEG.event(i).type = codes(index,sub); %%% corresponding definition of event
%         end
%         
%     end

    EEG = eeg_checkset( EEG );
    
    %%%Epoch data
    EEG = pop_epoch( EEG, {  }, [-0.102 5.002], 'newname', 'Epoched', 'epochinfo', 'yes');
    EEG = eeg_checkset( EEG );
    
    %%%Remove baseline
    EEG = pop_rmbase( EEG, [-100 0]);
    EEG = eeg_checkset( EEG );
    
    %%%Clean epoched windows
    EEG = clean_epochs_mmw(EEG,4.5,4.5,4.5);
    EEG = eeg_checkset( EEG );
    
    %%reject extreme values for each epoch, but the central sensors
    EEG = pop_eegthresh(EEG,1,[73,84,95,40,50] ,-125,125,-0.102,5.002,0,1);
    
    % downsampling from 512 to 100
    [EEG] = pop_resample(EEG,100);
    
    
    fname = char(['/share/volume0/qiongz/eegdata/subj' int2str(subject) 'Step3fast_50s_100b.set']);
    pop_saveset( EEG, 'filename',fname,'version','7.3');
    
    
%     %%Compute average reference
%     signal = EEG.data;
%     ref = repmat(mean(signal),size(signal,1),1,1);
%     EEG.data = signal - ref;
%     EEG = eeg_checkset( EEG );
%     fname = char(['/share/volume0/qiongz/eegdata/subj' int2str(subject) 'Step3fastAvr_50.set']);
%     pop_saveset( EEG, 'filename',fname,'version','7.3'); 
%     

    
    close all
    clc
end
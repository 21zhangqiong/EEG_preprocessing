clear all
close all
clc
%addpath('/Users/mwalsh/Desktop/Desktop/MATLAB/Support/My Functions/eeglab13_4_4b/','-end')
addpath('/home/qiongz/Desktop/eeglab13/','-end')
addpath('/home/qiongz/Desktop/eeganalysis/','-end')
addpath('/share/volume0/qiongz/eegdata/','-end')

eeglab;
close all

pop_editoptions('option_single', false, 'option_savetwofiles', false);

for subject = 2:4
    %create file names
    fname1 = char(['/share/volume0/qiongz/eegdata/Triple_Subject', int2str(subject), '.bdf']);
    
    %%load file
    EEG = pop_biosig(fname1);
    EEG = eeg_checkset( EEG );
    
    event_fname = char(['/share/volume0/qiongz/eegdata/Subject' int2str(subject) '.txt']);
    EEG = pop_importevent( EEG, 'append','no','event',event_fname,'fields',{'latency' 'type'},'skipline',1,'timeunit',1/512);
    EEG = eeg_checkset( EEG );
    
    %%remove offset
    for numChans = 1:size(EEG.data,1);
        EEG.data(numChans, :) = EEG.data(numChans, :) - mean(EEG.data(numChans, :));
    end
    EEG = eeg_checkset( EEG );
    
    %%import channel locations
    EEG = pop_chanedit(EEG, 'lookup','/home/qiongz/Desktop/eeglab13/plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp');
    EEG = eeg_checkset( EEG );
    
    %%rereference (mastoids)
    EEG = pop_reref( EEG, [129 130],'keepref','on');
    EEG = eeg_checkset( EEG );
    
    removed_channels = zeros(EEG.nbchan,1);
    removed_channels(129:end) = 5;
    
    EEG.etc.clean_channel_mask = removed_channels;
    EEG = eeg_checkset( EEG );
    
    events = cell2mat({EEG.event.type});
    first_fixation = find(events == 11,1,'first');
    
    if first_fixation > 1
        EEG = pop_editeventvals(EEG,'delete',(1:first_fixation-1));
        EEG = eeg_checkset( EEG );
        
        for i = 1:size({EEG.event.urevent},2)
            EEG.event(i).urevent = i;
        end
    end

    %%high pass filter
    EEG = pop_eegfiltnew(EEG, [], 0.1, 16896, true, [], 0);
    EEG = eeg_checkset( EEG );
    
    %%low pass filter
    EEG = pop_eegfiltnew(EEG, [], 50);
    EEG = eeg_checkset( EEG );
    
    %%trim edges of file
    latency = cell2mat({EEG.event.latency});
    start = max(1,latency(1)-5*EEG.srate);
    stop = min(EEG.pnts,latency(end)+5*EEG.srate);
    
    EEG = eeg_eegrej(EEG, [1 start; stop EEG.pnts]);
    EEG = eeg_checkset(EEG);
    
    %%save
    fname = char(['/share/volume0/qiongz/eegdata/subj' int2str(subject) 'Step1.set']);
    pop_saveset( EEG, 'filename',fname,'version','7.3');
        
    close all
    clc
end
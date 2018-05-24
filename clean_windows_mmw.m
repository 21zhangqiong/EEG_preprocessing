function signal = clean_windows_mmw(signal,window_len,window_overlap,noise_sig,deviation_sig,drift_sig,image_name)

% handle inputs
if ~exist('window_len','var') || isempty(window_len); window_len = 5; end
if ~exist('window_overlap','var') || isempty(window_overlap); window_overlap = .5; end
if ~exist('noise_sig','var') || isempty(noise_sig); noise_sig = 4; end
if ~exist('deviation_sig','var') || isempty(deviation_sig); deviation_sig = 4; end
if ~exist('drift_sig','var') || isempty(drift_sig); drift_sig = 4; end

clean_channel_mask = signal.etc.clean_channel_mask;
clean_channel_mask = logical(clean_channel_mask); %%1s mean channel will be deleted
good_channels = find(clean_channel_mask == 0);
nb_chan = length(good_channels);

signal.data = double(signal.data);
[C,S] = size(signal.data);
N = window_len*signal.srate;
wnd = 0:N-1;
offsets = round(1:N*(1-window_overlap):S-N);

fprintf('Scanning for bad windows...');

B = design_fir(100,[2*[0 45 50]/signal.srate 1],[1 1 0 0]);

channel_noise = zeros(C,size(offsets,2));
channel_deviation = zeros(C,size(offsets,2));
channel_drift = zeros(C,size(offsets,2));

% for each channel...
parfor c = 1 : nb_chan

    X = signal.data(good_channels(c),:);
    X = X(bsxfun(@plus,offsets,wnd'));
    
    %%%Test 1: High frequency noise
    freq = filtfilt_fast(B,1,signal.data(good_channels(c),:)');
    freq = freq(bsxfun(@plus,offsets,wnd'));

    channel_noise(c,:) = mad(X - freq,1)./mad(freq,1);
    
    %%%Test 2: Extreme values
    channel_deviation(c,:) = 1.4826*mad(X,1);
    
    %%%Test 3: Drift
    channel_drift(c,:) = median(X) - median(median(X));
end

epoch_noise = mean(channel_noise);
epoch_noise = log(epoch_noise);

epoch_deviation = mean(channel_deviation);
epoch_deviation = log(epoch_deviation);

epoch_drift = mean(channel_drift);

noise_threshold = median(epoch_noise) + mad(epoch_noise)*1.4826*noise_sig;
deviation_threshold = median(epoch_deviation) + mad(epoch_deviation)*1.4826*deviation_sig;
drift_threshold = median(epoch_drift) + mad(epoch_drift)*1.4826*drift_sig;

figure(2)
set(gcf,'units','inches','position',[1 1 8 4],'papersize',[8 4])

subplot(1,3,1)
hold on
title(char(['log Channel Noise, ', int2str(size(offsets,2)), ' Values']))
hist(epoch_noise,30)
plot([noise_threshold noise_threshold],[0 max(hist(epoch_noise))],'r')

subplot(1,3,2)
hold on
title(char(['Channel Deviation, ', int2str(size(offsets,2)), ' Values']))
hist(epoch_deviation,30)
plot([deviation_threshold deviation_threshold],[0 max(hist(epoch_deviation))],'r')

subplot(1,3,3)
hold on
title(char(['log Channel Drift, ', int2str(size(offsets,2)), ' Values']))
hist(epoch_drift,30)
plot([drift_threshold drift_threshold],[0 max(hist(epoch_drift))],'r')

drawnow
% pause
print(image_name,'-djpeg')

remove_mask = false(1,size(offsets,2));
remove_mask(epoch_noise > noise_threshold) = true;
remove_mask(epoch_deviation > deviation_threshold) = true;
remove_mask(abs(epoch_drift) > drift_threshold) = true;

culprit = [(epoch_noise > noise_threshold)' (epoch_deviation > deviation_threshold)' (abs(epoch_drift) > drift_threshold)'];

removed_windows = find(remove_mask);
culprit = culprit(remove_mask,:);

removed_boundaries = [offsets(removed_windows)' offsets(removed_windows)'+length(wnd) culprit];
removed_boundaries(:,2) = removed_boundaries(:,2);

for i = size(removed_boundaries,1):-1:2
    if (removed_boundaries(i,1) - removed_boundaries(i-1,2)) <= 2*length(wnd)
        removed_boundaries(i-1,2) = removed_boundaries(i,2);
        removed_boundaries(i,:) = [];
    end
end

signal = eeg_eegrej(signal, removed_boundaries(:,1:2));
signal = eeg_checkset(signal);

record = [removed_boundaries(:,1:2)./signal.srate removed_boundaries(:,3:5)];
signal.etc.record = record;

function Y = mad(X,flag) %#ok<INUSD>
Y = median(abs(bsxfun(@minus,X,median(X))));
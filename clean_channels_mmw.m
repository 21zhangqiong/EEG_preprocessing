function [signal correlation_threshold] = clean_channels_mmw(signal,window_len,window_overlap,noise_sig,dev_sig,corr_sig,image_name)

if ~exist('window_len','var') || isempty(window_len); window_len = 5; end
if ~exist('window_overlap','var') || isempty(window_overlap); window_overlap = .5; end
if ~exist('noise_sig','var') || isempty(noise_sig); noise_sig = 5; end
if ~exist('dev_sig','var') || isempty(dev_sig); dev_sig = 5; end
if ~exist('corr_sig','var') || isempty(corr_sig); corr_sig = 5; end

clean_channel_mask = signal.etc.clean_channel_mask;
clean_channel_mask = logical(clean_channel_mask); %%1s mean channel will be deleted
good_channels = find(clean_channel_mask == 0);
nb_chan = length(good_channels);

signal.data = double(signal.data);
[C,S] = size(signal.data);
N = window_len*signal.srate;
wnd = 0:N-1;
offsets = round(1:N*(1-window_overlap):S-N);

W = length(offsets);
channel_labels = {signal.chanlocs.labels};

fprintf('Scanning for bad channels...\n');

%%%Test 1. High Frequency Noise
% remove signal content above 50Hz
B = design_fir(100,[2*[0 45 50]/signal.srate 1],[1 1 0 0]);
parfor c = 1 : nb_chan
    X(:,c) = filtfilt_fast(B,1,signal.data(good_channels(c),:)');
end
channelNoise = mad(signal.data(good_channels,:)' - X)./mad(X,1);
% gf = gamfit(channelNoise);
% noise_threshold = gaminv(.99,gf(1),gf(2));
channelNoise = log(channelNoise);
noise_threshold = median(channelNoise) + mad(channelNoise,1)*1.4826*noise_sig;

%%%Test 2. Extreme Values
channelDeviation = 1.4826*mad(signal.data(good_channels,:)'); % Robust estimate of SD
% gf = gamfit(channelDeviation);
% deviation_threshold = gaminv(.99,gf(1),gf(2));
channelDeviation = log(channelDeviation);
deviation_threshold = median(channelDeviation) + mad(channelDeviation,1)*1.4826*dev_sig;

%%%%Test 3. Max correlation
parfor c = 1 : W
    XX = signal.data(good_channels,offsets(c)+wnd)';
    cmat = corr(XX)
    cmat = sort(cmat);
    cmat(end,:) = [];
    channelCorrs(c,:) = cmat(end,:);
end

channelCorrs = mean(channelCorrs);
%correlation_threshold = median(channelCorrs) - mad(channelCorrs,1)*1.4826*corr_sig;
correlation_threshold = corr_sig;

figure(1)
set(gcf,'units','inches','position',[1 1 8 4],'papersize',[8 4])

subplot(1,3,1)
hold on
xv = linspace(min(channelNoise),max(channelNoise),50);
hist(channelNoise,xv)
plot([noise_threshold noise_threshold],[0 10],'r')
title('log Channel Noise')

xv = linspace(min(channelDeviation),max(channelDeviation),50);
subplot(1,3,2)
hold on
title('log Channel Deviations')
hist(channelDeviation,xv)
plot([deviation_threshold deviation_threshold],[0 10],'r')

xv = linspace(min(channelCorrs),max(channelCorrs),50);
subplot(1,3,3)
hold on
title('Channel Correlation')
hist(channelCorrs,xv)
plot([correlation_threshold correlation_threshold],[0 10],'r')

drawnow
% pause
print(image_name,'-djpeg')

noise_mask = channelNoise > noise_threshold;
deviation_mask = channelDeviation > deviation_threshold;
correlation_mask = channelCorrs < correlation_threshold;

removed_channels = zeros(C,1);
removed_channels(noise_mask) = 1;
removed_channels(deviation_mask) = 2;
removed_channels(correlation_mask) = 3;
removed_channels(clean_channel_mask) = 5;

signal.etc.clean_channel_mask = removed_channels;

field = {'Noise';'Deviation';'Correlation'};

notes = struct(field{1},{channel_labels(noise_mask)},field{2},{channel_labels(deviation_mask)},field{3},{channel_labels(correlation_mask)});
signal.etc.notes = notes;

function Y = mad(X,flag) %#ok<INUSD>
Y = median(abs(bsxfun(@minus,X,median(X))));
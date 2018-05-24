function signal = clean_epochs_mmw(signal,deviation_sig,drift_sig,range_sig)

% handle inputs
if ~exist('deviation_sig','var') || isempty(deviation_sig); deviation_sig = 5; end
if ~exist('correlation_sig','var') || isempty(drift_sig); drift_sig = 5; end
if ~exist('range_sig','var') || isempty(range_sig); range_sig = 5; end

signal.data = double(signal.data);
default = pop_select( signal ,'trial',1);
default = eeg_checkset( default );

[C,~,T] = size(signal.data);

bad_epochs = zeros(C,1);

fprintf('Scanning for bad channels during epochs...\n');
XX = signal.data;

%%%Test 2. Extreme Values
guilt = zeros(1,3);
m_vals = median(median(XX,3),2);

for i = 1:T
    X = XX(:,:,i);
    
    channelDeviation = 1.4826*mad(X,0,2); % Robust estimate of SD
    channelDeviation = log(channelDeviation);
    deviation_threshold = median(channelDeviation) + mad(channelDeviation,1)*1.4826*deviation_sig;
    
    channelDrift = max(abs(X)');
    channelDrift = log(channelDrift);
    drift_threshold = median(channelDrift) + mad(channelDrift)*1.4826*drift_sig;
    
    channelRange = max(X') - min(X');
    channelRange = log(channelRange)';
    range_threshold = median(channelRange) + mad(channelRange,1)*1.4826*range_sig;
    
    bad_channels = zeros(C,1);
    bad_channels(channelDeviation > deviation_threshold) = 1;
    bad_channels(channelDrift > drift_threshold) = 1;
    bad_channels(channelRange > range_threshold) = 1;
    bad_channels = find(bad_channels);
    
    default.data = X;
    if bad_channels
        default = eeg_interp(default, bad_channels);
        XX(:,:,i) = default.data;
        bad_epochs(bad_channels) = bad_epochs(bad_channels) + 1;
    end
end

signal.data = XX;
signal.etc.clean_epochs = bad_epochs;
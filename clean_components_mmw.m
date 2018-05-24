function signal = clean_components_mmw(signal,window_len,window_overlap,VEOG_corr,HEOG_corr)

if ~exist('window_len','var') || isempty(window_len); window_len = 5; end
if ~exist('window_overlap','var') || isempty(window_overlap); window_overlap = .5; end
if ~exist('VEOG_corr','var') || isempty(VEOG_corr); VEOG_corr = .8; end
if ~exist('HEOG_corr','var') || isempty(HEOG_corr); HEOG_corr = .8; end

signal.data = double(signal.data);
[~,S] = size(signal.data);
N = window_len*signal.srate;
wnd = 0:N-1;
offsets = round(1:N*(1-window_overlap):S-N);

W = length(offsets);

fprintf('Scanning for bad components...\n');

labs = {signal.chanlocs.labels};
VEOG = find(strcmp(labs,'VEOG'));
VEOG = signal.data(VEOG,:);

HEOG = find(strcmp(labs,'HEOG'));
HEOG = find(strcmp(labs,'HEOG'));
HEOG = signal.data(HEOG,:);

for c = 1 : W
    c
   % offsets(c)+wnd
    %size(signal.icaact)
    XX = signal.icaact(:,offsets(c)+wnd)';
    
    HX = HEOG(offsets(c)+wnd)';
    VX = VEOG(offsets(c)+wnd)';
    
    HCORR = corr(HX,XX);
    VCORR = corr(VX,XX);
    
    HMAT(c,:) = HCORR;
    VMAT(c,:) = VCORR;
end

HMAT = abs(mean(HMAT));
VMAT = abs(mean(VMAT));

v_mask = find(VMAT > VEOG_corr);
h_mask = find(HMAT > HEOG_corr);
n_mask = [];

signal = pop_subcomp( signal, v_mask,0);% h_mask], 0);
signal = eeg_checkset( signal );

field = {'VEOG';'HEOG';'Noise'};

ICAnotes = struct(field{1},{v_mask},field{2},{h_mask},field{3},{n_mask});
signal.etc.ICAnotes = ICAnotes;
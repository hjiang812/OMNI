function generate_recording(templatesMat, probeMat, outMat,Params)
%SYNTHESIZE_MULTICHANNEL_DATA (NO time mapping)
% (1) Parameters:
%     numSamples = 30000
%     noiseType = Gaussian
%     SNR = 0.15   (RMS(signal)/RMS(noise))
%     numChannels = 1024
%     influenceRange = 30
% (2) Generate 1024-ch Gaussian noise
% (3) Add template activity at EXACT firing times (no linear mapping):
%     - If firing time t0 = 3000 => spike placed at data(3000, :)
%     - Only affects channels within influenceRange
%     - Weight ~ 1/(distance^2), normalized to max=1 (avoid d=0 blow-up)
% (4) Scale signal to hit target SNR
% (5) Save to .mat

if nargin < 1 || isempty(templatesMat), templatesMat = 'templates_cell.mat'; end
if nargin < 2 || isempty(probeMat),     probeMat = 'probe_coords_32x32.mat'; end
if nargin < 3 || isempty(outMat),       outMat = 'synthetic_data.mat'; end

%% ---------------- Parameters ----------------
numSamples     = Params.sample_frequency * Params.length;
numChannels    = Params.numChannels;
noiseType      = Params.noiseType;
SNR_target     = Params.SNR_target;     % RMS(signal)/RMS(noise)
influenceRange = Params.influenceRange;      % coordinate units (same as probe/template)
waveLen = 50;    

%% ---------------- Load templates & probe ----------------
S1 = load(templatesMat, 'templates');
if ~isfield(S1, 'templates'), error('Missing variable "templates" in %s', templatesMat); end
templates = S1.templates;
if ~iscell(templates), error('"templates" must be a cell array.'); end

S2 = load(probeMat, 'coords');
if ~isfield(S2, 'coords'), error('Missing variable "coords" (1024x2) in %s', probeMat); end
probeCoords = S2.coords;

if size(probeCoords,1) ~= numChannels || size(probeCoords,2) ~= 2
    error('probe coords must be %dx2, got %dx%d', numChannels, size(probeCoords,1), size(probeCoords,2));
end

   % waveform length

Ntemplates = numel(templates);
fprintf('Loaded %d templates; channels=%d; samples=%d\n', Ntemplates, numChannels, numSamples);

%% ---------------- (2) Generate noise ----------------
switch lower(noiseType)
    case 'gaussian'
        noise = single(randn(numSamples, numChannels));
    otherwise
        error('Unsupported noise type: %s', noiseType);
end

%% ---------------- (3) Build signal-only matrix ----------------
signalOnly = single(zeros(numSamples, numChannels));

meta = struct();
meta.params.numSamples = numSamples;
meta.params.numChannels = numChannels;
meta.params.noiseType = noiseType;
meta.params.SNR_target = SNR_target;
meta.params.influenceRange = influenceRange;
meta.params.waveLen = waveLen;
meta.source.templatesMat = templatesMat;
meta.source.probeMat = probeMat;

templateInfo = struct([]);
droppedSpikesTotal = 0;
keptSpikesTotal = 0;

for i = 1:Ntemplates
    tpl = templates{i};
    if ~iscell(tpl) || numel(tpl) < 3
        error('templates{%d} must be {wf, ft, pos}.', i);
    end

    wf  = single(tpl{1}(:));      % waveLen x 1
    ft  = tpl{2};
    pos = tpl{3};

    if numel(wf) ~= waveLen
        error('Template %d waveform length is %d, expected %d.', i, numel(wf), waveLen);
    end
    if ~isnumeric(pos) || numel(pos) ~= 2
        error('Template %d pos must be [x y].', i);
    end

    ft = ft(:).';                 % 1 x K
    ft = round(ft);               % ensure integer indices
    ft = unique(ft);              % optional: avoid duplicates

    % Determine affected channels within influenceRange
    dx = probeCoords(:,1) - pos(1);
    dy = probeCoords(:,2) - pos(2);
    d  = sqrt(dx.^2 + dy.^2);

    affected = find(d <= influenceRange);

    % Prepare weights
    weights = [];
    if ~isempty(affected)
        d2 = d(affected).^2;
        eps2 = 1e-6;
        weights = 1 ./ (d2 + eps2);
        weights = weights / max(weights);  % max=1
        weights = single(weights(:)).';    % 1 x nCh
    end

    % Place spikes at EXACT times (no mapping)
    keptTimes = [];
    dropped = 0;

    if ~isempty(ft) && ~isempty(affected)
        for k = 1:numel(ft)
            t0 = ft(k);

            % Spike snippet is [t0 .. t0+waveLen-1]
            if t0 < 1 || (t0 + waveLen - 1) > numSamples
                dropped = dropped + 1;
                continue;
            end

            seg = t0:(t0 + waveLen - 1);

            % Add to affected channels: wf(:) * weights(:)'
            signalOnly(seg, affected) = signalOnly(seg, affected) + (wf * weights);

            keptTimes(end+1) = t0; %#ok<AGROW>
        end
    else
        % If no affected channels or no spikes, nothing to add
        keptTimes = [];
    end

    droppedSpikesTotal = droppedSpikesTotal + dropped;
    keptSpikesTotal = keptSpikesTotal + numel(keptTimes);

    % Store info for visualization
    templateInfo(i).pos = pos(:).';
    templateInfo(i).affectedChannels = affected(:).';
    templateInfo(i).weights = double(weights);     % store as double for convenience
    templateInfo(i).ftUsed = keptTimes(:).';       % times actually inserted into data
    templateInfo(i).ftDroppedCount = dropped;
end

if droppedSpikesTotal > 0
    warning('Dropped %d spikes because they were outside [1..%d-waveLen+1]. Kept %d spikes.', ...
        droppedSpikesTotal, numSamples, keptSpikesTotal);
end

meta.spikes.kept = keptSpikesTotal;
meta.spikes.dropped = droppedSpikesTotal;

%% ---------------- (4) Scale signal to match SNR_target ----------------
% SNR = RMS(signalOnlyScaled) / RMS(noise)
rmsNoise  = sqrt(mean(noise(:).^2));
rmsSignal = sqrt(mean(signalOnly(:).^2));

if rmsSignal < 1e-12
    warning('Signal-only RMS is ~0; output will be noise only.');
    scaleFactor = single(0);
else
    scaleFactor = single((SNR_target * rmsNoise) / rmsSignal);
end

signalOnlyScaled = signalOnly * scaleFactor;
data = noise + signalOnlyScaled;

meta.scaling.rmsNoise_before = double(rmsNoise);
meta.scaling.rmsSignal_before = double(rmsSignal);
meta.scaling.scaleFactor = double(scaleFactor);
meta.scaling.SNR_achieved = double( sqrt(mean(signalOnlyScaled(:).^2)) / sqrt(mean(noise(:).^2)) );

fprintf('RMS(noise)=%.4f, RMS(signal)=%.4f, scale=%.4f, achieved SNR=%.4f\n', ...
    meta.scaling.rmsNoise_before, meta.scaling.rmsSignal_before, ...
    meta.scaling.scaleFactor, meta.scaling.SNR_achieved);

%% ---------------- (5) Save ----------------
save(outMat, 'data', 'noise', 'signalOnlyScaled', 'meta', 'templateInfo', '-v7.3');
fprintf('Saved synthetic data to: %s\n', fullfile(pwd, outMat));

end

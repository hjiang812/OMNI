
view_spike_snippet(1,2);

function view_spike_snippet(N, K, dataMatFile, preSamp, postSamp)
%VIEW_SPIKE_SNIPPET_STACKED
% Show the N-th template's K-th spike (EXACT time, no mapping),
% plotting all affected channels as separated (stacked) traces with channel labels.
%
% Inputs:
%   N, K        : template index and spike index (within templateInfo(N).ftUsed)
%   dataMatFile : (optional) default 'synthetic_data.mat'
%   preSamp     : (optional) samples before spike time, default 50
%   postSamp    : (optional) samples after spike time, default 50
%
% Requires in dataMatFile:
%   data (numSamples x numChannels)
%   templateInfo(N).ftUsed
%   templateInfo(N).affectedChannels
%   templateInfo(N).weights (optional but recommended for sorting)

if nargin < 3 || isempty(dataMatFile)
    dataMatFile = 'synthetic_data.mat';
end
if nargin < 4 || isempty(preSamp)
    preSamp = 50;
end
if nargin < 5 || isempty(postSamp)
    postSamp = 50;
end

S = load(dataMatFile, 'data', 'templateInfo');
if ~isfield(S, 'data') || ~isfield(S, 'templateInfo')
    error('MAT file must contain variables "data" and "templateInfo".');
end

data = S.data;
templateInfo = S.templateInfo;

numSamples = size(data, 1);
numChannels = size(data, 2);

if N < 1 || N > numel(templateInfo)
    error('N out of range. N must be in [1..%d].', numel(templateInfo));
end

info = templateInfo(N);

if ~isfield(info, 'ftUsed') || isempty(info.ftUsed)
    error('Template %d has no spikes inserted into the data (ftUsed is empty).', N);
end
if K < 1 || K > numel(info.ftUsed)
    error('K out of range. Template %d has %d usable spikes (ftUsed).', N, numel(info.ftUsed));
end

t0 = info.ftUsed(K);  % EXACT spike time in the synthetic data

if ~isfield(info, 'affectedChannels') || isempty(info.affectedChannels)
    error('Template %d has no affected channels.', N);
end

ch = info.affectedChannels(:)';

% Weights may not exist in edge cases; handle robustly
if isfield(info, 'weights') && ~isempty(info.weights)
    w = info.weights(:)';
    if numel(w) ~= numel(ch)
        % If mismatch, ignore sorting by weights
        w = [];
    end
else
    w = [];
end

% Sort channels by weight (closest first) if available
if ~isempty(w)
    [~, sortIdx] = sort(w, 'descend');
    ch = ch(sortIdx);
    w  = w(sortIdx);
end

% Window bounds
t1 = t0 - preSamp;
t2 = t0 + postSamp;
if t1 < 1 || t2 > numSamples
    error('Requested window [%d..%d] exceeds data bounds [1..%d]. Try smaller pre/post.', t1, t2, numSamples);
end

seg = t1:t2;
x = -preSamp:postSamp;

snippet = data(seg, ch);        % (windowLen x nCh)
windowLen = size(snippet, 1);
nCh = numel(ch);

% Compute a reasonable vertical spacing
maxAmp = max(abs(snippet(:)));
if maxAmp < 1e-12
    maxAmp = 1;
end
offsetStep = 1.8 * maxAmp;      % increase if you want more separation

% ---- Plot stacked traces ----
figure('Name', sprintf('Template %d Spike %d @ t=%d (stacked)', N, K, t0), 'Color', 'w');
hold on;

for iCh = 1:nCh
    offset = (nCh - iCh) * offsetStep;   % top trace highest offset
    y = double(snippet(:, iCh)) + offset;

    plot(x, y, 'k-', 'LineWidth', 1);

    % Channel label on the left, aligned to its baseline
    text(x(1) - 5, offset, sprintf('Ch %d', ch(iCh)), ...
        'VerticalAlignment', 'middle', ...
        'HorizontalAlignment', 'right', ...
        'FontSize', 8);

    % Optional: show weight next to channel
    % if ~isempty(w)
    %     text(x(1) - 5, offset - 0.35*offsetStep, sprintf('w=%.3f', w(iCh)), ...
    %         'VerticalAlignment','middle','HorizontalAlignment','right','FontSize',7);
    % end
end

% Mark spike center at x=0
yl = ylim;
plot([0 0], yl, 'r--', 'LineWidth', 1);

% Cosmetics
xlabel('Samples relative to spike time');
ylabel('Channels (stacked)');
title(sprintf('Template %d - Spike %d (t=%d), affected=%d channels', N, K, t0, nCh));
set(gca, 'YTick', []);
grid on;
box on;
hold off;

% Console info
fprintf('Template N=%d | Spike K=%d | t0=%d\n', N, K, t0);
fprintf('Window: [%d..%d] (len=%d), Channels shown: %d / %d\n', t1, t2, windowLen, nCh, numChannels);

end


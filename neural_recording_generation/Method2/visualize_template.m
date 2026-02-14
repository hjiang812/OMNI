function visualize_template(matFile)
%VISUALIZE_TEMPLATES Load templates (cell) and visualize:
% (1) Raster plot of firing times
% (2) Waveforms of each template
% (3) 2D scatter of neuron positions
%
% matFile: e.g., 'templates_cell.mat'
% The .mat file should contain variable named "templates"

if nargin < 1 || isempty(matFile)
    matFile = 'templates_cell.mat';
end

S = load(matFile, 'templates');
if ~isfield(S, 'templates')
    error('The MAT file does not contain variable "templates".');
end
templates = S.templates;

if ~iscell(templates)
    error('"templates" must be a cell array.');
end

N = numel(templates);
fprintf('Loaded %d templates from %s\n', N, matFile);

% Extract for convenience
waveforms = cell(N, 1);
firingTimes = cell(N, 1);
positions = nan(N, 2);

for i = 1:N
    tpl = templates{i};
    if ~iscell(tpl) || numel(tpl) < 3
        error('templates{%d} must be a cell with at least 3 elements: {wf, ft, pos}.', i);
    end

    waveforms{i} = tpl{1};
    firingTimes{i} = tpl{2};
    pos = tpl{3};

    if isnumeric(pos) && numel(pos) == 2
        positions(i, :) = pos(:).';
    else
        positions(i, :) = [NaN NaN];
    end
end

% ---------- (1) Raster plot ----------
plot_raster(firingTimes);

% ---------- (2) Waveforms ----------
plot_waveforms(waveforms);

% ---------- (3) 2D positions ----------
plot_positions(positions);

end

%% ===================== Helper plots =====================

function plot_raster(firingTimes)
N = numel(firingTimes);

figure('Name','Raster Plot (Firing Times)','Color','w');
hold on;

% Raster: each spike is a short vertical line at (t, neuronIndex)
for i = 1:N
    ft = firingTimes{i};
    if isempty(ft), continue; end
    ft = ft(:)'; % row

    % draw vertical ticks: from i-0.4 to i+0.4
    y0 = (i - 0.4) * ones(size(ft));
    y1 = (i + 0.4) * ones(size(ft));
    for k = 1:numel(ft)
        plot([ft(k) ft(k)], [y0(k) y1(k)], 'k-');
    end
end

xlabel('Time');
ylabel('Template index');
title('Raster plot of firing times');
ylim([0, N+1]);
grid on;
hold off;
end

function plot_waveforms(waveforms)
N = numel(waveforms);

figure('Name','Spike Waveforms','Color','w');
hold on;

% Plot all waveforms in one figure (overlay)
for i = 1:N
    wf = waveforms{i};
    if isempty(wf), continue; end
    wf = wf(:)'; % row
    plot(1:numel(wf), wf, '-');
end

xlabel('Sample (1..50)');
ylabel('Amplitude (normalized)');
title('Template spike waveforms (overlay)');
grid on;
hold off;

% If you prefer: each waveform in its own figure, uncomment below:
% for i = 1:N
%     wf = waveforms{i}; if isempty(wf), continue; end
%     figure('Name',sprintf('Waveform %d',i),'Color','w');
%     plot(1:numel(wf), wf, '-');
%     xlabel('Sample'); ylabel('Amplitude');
%     title(sprintf('Template %d waveform', i));
%     grid on;
% end
end

function plot_positions(positions)
figure('Name','Template Positions','Color','w');

valid = all(isfinite(positions), 2);
scatter(positions(valid,1), positions(valid,2), 25, 'filled');
xlabel('x');
ylabel('y');
title('2D positions of templates');
xlim([0 500]);
ylim([0 500]);
axis equal;
grid on;

% Optionally label indices (can be cluttered if N large)
% hold on;
% idx = find(valid);
% for k = 1:numel(idx)
%     i = idx(k);
%     text(positions(i,1)+5, positions(i,2)+5, num2str(i), 'FontSize', 8);
% end
% hold off;
end
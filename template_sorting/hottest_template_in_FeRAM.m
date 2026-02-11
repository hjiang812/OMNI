clc;
clear;

%% =========================================================
%% 1. Generate 9600 integers
%%    50 integers have frequency >80
%%    Others have frequency <80
%% =========================================================

total_samples = 9600;
value_range = 16000;
num_high_freq = 50;
min_high_freq = 81;   % strictly greater than 200

% Randomly select 30 heavy hitter values
high_values = randperm(value_range, num_high_freq);

% Assign minimum frequency 201 to each
high_counts = ones(1, num_high_freq) * min_high_freq;

current_total = sum(high_counts);
remaining = total_samples - current_total;

% Distribute remaining samples randomly among heavy hitters
while remaining > 0
    idx = randi(num_high_freq);
    high_counts(idx) = high_counts(idx) + 1;
    remaining = remaining - 1;
end

% Build dataset
data = [];

% Add heavy hitter samples
for i = 1:num_high_freq
    data = [data, repmat(high_values(i), 1, high_counts(i))];
end

% Shuffle data
data = data(randperm(length(data)));

%% =========================================================
%% 2. Exact Frequency Counting (Ground Truth)
%% =========================================================

true_freq = zeros(1, value_range);

for i = 1:length(data)
    true_freq(data(i)) = true_freq(data(i)) + 1;
end

[true_sorted_counts, true_sorted_indices] = sort(true_freq, 'descend');
true_top50_values = true_sorted_indices(1:50);
true_top50_counts = true_sorted_counts(1:50);

%% =========================================================
%% 3. Space-Saving Algorithm (k = 50)
%% =========================================================

k = 50;
candidates = zeros(1, k);
counts = zeros(1, k);

for i = 1:length(data)
    
    value = data(i);
    
    idx = find(candidates == value, 1);
    
    if ~isempty(idx)
        counts(idx) = counts(idx) + 1;
    else
        empty_idx = find(counts == 0, 1);
        
        if ~isempty(empty_idx)
            candidates(empty_idx) = value;
            counts(empty_idx) = 1;
        else
            [min_count, min_idx] = min(counts);
            candidates(min_idx) = value;
            counts(min_idx) = min_count + 1;
        end
    end
end

% Sort Space-Saving result
[ss_sorted_counts, ss_sort_idx] = sort(counts, 'descend');
ss_top50_values = candidates(ss_sort_idx);
ss_top50_counts = ss_sorted_counts;

%% =========================================================
%% 4. Compare Top-K Overlap
%% =========================================================

K_list = [10, 20, 30, 40, 50];
overlap_counts = zeros(size(K_list));
overlap_rates = zeros(size(K_list));

for t = 1:length(K_list)
    
    K = K_list(t);
    
    true_topK = true_top50_values(1:K);
    ss_topK   = ss_top50_values(1:K);
    
    overlap_counts(t) = length(intersect(true_topK, ss_topK));
    overlap_rates(t) = overlap_counts(t) / K;
    
end

%% =========================================================
%% 5. Display Results
%% =========================================================

disp('==============================================');
disp('Overlap between Space-Saving Top-K and True Top-K');
disp('==============================================');

for t = 1:length(K_list)
    fprintf('Top-%d overlap = %d  (%.2f%%)\n', ...
        K_list(t), ...
        overlap_counts(t), ...
        100 * overlap_rates(t));
end

disp('==============================================');

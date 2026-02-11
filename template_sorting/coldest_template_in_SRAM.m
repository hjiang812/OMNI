%% (1) Generate 1600 random positive integers between 1 and 10000
% Simulate firing rates stored in SRAM
sram = randi([1, 10000], 1, 1600);

%% (2) Create a register file with depth 50 initialized to zeros
reg = zeros(1, 50);

%% (3) Sequentially read 1600 values
for i = 1:1600
    x = sram(i);
    
    if i <= 50
        % Directly write the first 50 values into the register file
        reg(i) = x;
    else
        % Find the maximum value and its index in the register file
        [max_val, max_idx] = max(reg);
        
        % If the new value is smaller than the current maximum,
        % replace the maximum value
        if x < max_val
            reg(max_idx) = x;
        end
    end
end

%% Verification: Check if register file contains the 50 smallest values
% Sort the original SRAM data
sorted_sram = sort(sram);

% Extract the 50 smallest values
true_smallest_50 = sorted_sram(1:50);

% Sort register file for fair comparison
sorted_reg = sort(reg);

% Compare
is_correct = isequal(sorted_reg, true_smallest_50);

%% Display results
disp('Final register file (unsorted):');
disp(reg);

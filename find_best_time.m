function [time, col] = find_best_time(J, p)
    total_durations = zeros(1, size(p, 2)); 
    %disp('Calculations'); 
    
    % loops on all columns
    for col = 1:size(p, 2)
        temp = 0; 
        %fprintf('Calculating for the column %d:\n', col); 
        
        for i = 1:length(J)
            %fprintf('Adding processing time for the job %d: %d\n', J(i), p(J(i), col));
            
            temp = temp + p(J(i), col); % Aggiungi il tempo corrente
            %fprintf('Accumulated value per column %d: %d\n', col, temp);
        end
        
        total_durations(col) = temp; 
        %disp(['Total duration per column ', num2str(col), ': ', num2str(temp)]); 
    end
    
    % Find the minimum duration and corresponding column
    [time, col] = min(total_durations); 
    %disp(['Minimum total duration: ', num2str(len), ' of the column ', num2str(min_col)]); 
end

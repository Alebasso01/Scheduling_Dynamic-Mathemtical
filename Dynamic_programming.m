%% Database connection

conn = database('industrialautomation','industrial','Automation1234');
 
query = ['SELECT * FROM [industrialautomation].[dbo].[Batch]'];
data = fetch(conn,query);
close(conn);
clear conn query;

%% Dynamic Programming Scheduling

n_jobs = length(data.arrival_time);

% generating all possible job combinations
combinations = cell(n_jobs, 1);  
for k = 1:n_jobs
    combinations{k} = nchoosek(1:n_jobs, k);  
end

p=[data.processing_time1, data.processing_time2, data.processing_time3];
d=data.due_date;

% all jobs have been scheduled -> only one combination
stati(n_jobs) = size(combinations{n_jobs}, 1);
G_last = 0; % initializing the optimal final cost

% loop for each state from n-1 to the initial one
for step = n_jobs-1:-1:1
    stati(step) = size(combinations{step}, 1); % number of states for the current step

    % G initialized with infinite value 
    G = 10000 * ones(stati(step), stati(step + 1)); 

    % loop for all combinations of that state
    for i = 1:stati(step)

        [start_time, col_index] = find_best_time(combinations{step}(i,:), p);

        % fprintf('\nCombination at step %d, state %d: ', step, i);
        % disp(combinations{step}(i,:))
        
        % loop on following states
        for j = 1:stati(step + 1)

            % if the current combination is a subset of the next -> valid combination
            if all(ismember(combinations{step}(i,:), combinations{step + 1}(j,:)))

                additional_job = setdiff(combinations{step + 1}(j,:), combinations{step}(i,:)); 

                % disp(combinations{step + 1}(j,:));
                % disp(additional_job);
                
                G(i,j) = G_last(j) + (start_time + p(additional_job, col_index) - d(additional_job));    
            end
        end
        
        G_min(step, i) = min(G(i,:));

    end
    
    % G last update for subsequent iterations
    G_last = G_min(step, :);

end

% Step 0: initial state with no job assigned and initial cost 0
G0 = zeros(1, stati(1));

% fprintf('\n--- Calculating Initial Costs (G0) ---\n');


for i = 1:stati(1)
    job_index = combinations{1}(i);

    % calculating the penalty (delay)
    penalty = max((p(job_index, :) - d(job_index)), 0);  

    G0(i) = G_min(1, i) + min(penalty);  

    % fprintf('State %d (combination): ', i);
    % disp(combinations{1}(i));
    % fprintf('Penalty: %.2f\n', sum(penalty));  
end

% taking the initial state with lower cost
G0_min = min(G0);


%% Calculating of optimal sequence and completion times with parallel execution


[~, idx] = min(G0);


optimal_sequence = [];

optimal_sequence = [optimal_sequence, combinations{1}(idx, :)];

start_time = zeros(n_jobs, 1);
completion_time = zeros(n_jobs, 1);
lateness = zeros(n_jobs, 1);

n_resources = 3;  

% each machine is initially available at time 0
resource_available_time = zeros(n_resources, 1); 
job_on_resource = -1 * ones(n_jobs, 1);  % -1 = non assegnato

start_time(optimal_sequence(1)) = data.arrival_time(optimal_sequence(1));


% calculating completion times on all machines
completion_time_candidates = start_time(optimal_sequence(1)) + p(optimal_sequence(1), :);
[completion_time(optimal_sequence(1)), machine_idx] = min(completion_time_candidates);  


% assigning the first job to the corresponding machine
resource_available_time(machine_idx) = completion_time(optimal_sequence(1)); 
job_on_resource(optimal_sequence(1)) = machine_idx;  

lateness(optimal_sequence(1)) = max(0, completion_time(optimal_sequence(1)) - d(optimal_sequence(1)));

% reconstructing the optimal sequence from step 1 to step n_jobs-1
for step = 2:n_jobs

    
    for j = 1:stati(step)

        
        if all(ismember(optimal_sequence, combinations{step}(j,:)))
            possible_jobs = setdiff(combinations{step}(j,:), optimal_sequence);
            
            % selecting the job with the closest due_date
            [~, min_index] = min(d(possible_jobs));
            new_job = possible_jobs(min_index);

            
            if ~isempty(new_job)

                optimal_sequence = [optimal_sequence, new_job];

                
                best_resource_idx = -1; 
                min_lateness = inf;      
                
                completion_times = zeros(1, n_resources);

                % evaluating all resources 
                for resource_idx = 1:n_resources

                    start_time_new_job = max(resource_available_time(resource_idx), data.arrival_time(new_job));


                    switch resource_idx
                        case 1
                            p_current = data.processing_time1(new_job);
                        case 2
                            p_current = data.processing_time2(new_job);
                        case 3
                            p_current = data.processing_time3(new_job);
                    end

                    completion_time_new_job = start_time_new_job + p_current;
                    completion_times(resource_idx) = completion_time_new_job; 

                    lateness_new_job = max(0, completion_time_new_job - d(new_job));


                    % better resource update if lateness is lower
                
                    if lateness_new_job < min_lateness
                        min_lateness = lateness_new_job;
                        best_resource_idx = resource_idx;
                    end
                end

                if best_resource_idx ~= -1

                    %fprintf('Chosen resource: %d with lower lateness: %.2f\n', best_resource_idx, min_lateness);
                    
                    % Assegna il job alla risorsa selezionata
                    start_time(new_job) = max(resource_available_time(best_resource_idx), data.arrival_time(new_job));
                    completion_time(new_job) = completion_times(best_resource_idx); % Usa il tempo di completamento salvato
                    lateness(new_job) = min_lateness;  % using the minimum lateness found

                    
                    resource_available_time(best_resource_idx) = completion_time(new_job);

                    %fprintf('Time of availability of the resource %d updated at: %.2f\n', best_resource_idx, resource_available_time(best_resource_idx));
                    
                    job_on_resource(new_job) = best_resource_idx;

                    %fprintf('Job %d run on the resource: %d\n', new_job, best_resource_idx);
                else
                    %fprintf('No resource available for the job %d.\n', new_job);
                end
            end
            break; % exit from cycle for j after processing new job
        end
    end
end






% verifying that each job has been assigned to a resource
for i = 1:n_jobs
    if job_on_resource(i) == -1

        %error("The job %d has not been assigned to a resource correctly.", i);
    end
end

makespan_dp = max(completion_time);  
jobs_late_dp = sum(lateness > 0);  
total_late_time_dp = sum(lateness(lateness > 0));  

%% Sort jobs by completion time

[~, order] = sort(completion_time);  % sort by completion time
sorted_batch_id = data.batch_id(order);  % sort batch_id according to order of completion
sorted_start_time = start_time(order);   % sort start_time
sorted_job_on_resource = job_on_resource(order);  % laser cutter on which the job was executed
sorted_completion_time = completion_time(order);   % sort the completion time
sorted_lateness = lateness(order);  % sort lateness

% print sorted results
fprintf('\n--- Dynamic Programming ---\n');
fprintf('Job\tStart \tCompletion \tLateness\tLaser\n');
for i = 1:length(order)
    fprintf('%d\t%.2f\t%.2f\t\t%.2f\t\t%d\n', ...
        sorted_batch_id(i), sorted_start_time(i), ...
        sorted_completion_time(i), sorted_lateness(i), sorted_job_on_resource(i));
end


%% Database connection and save data into DB

conn = database('industrialautomation','industrial','Automation1234');
 
% deleting DP table before saving new data
query=strcat("delete from [industrialautomation].[dbo].[DP]"); 
exec(conn,query); 

% inserting sorted data 
for i = 1:n_jobs
    query = strcat("INSERT INTO [industrialautomation].[dbo].[DP] (batch_id, start_time, completion_time, late_time, resource) VALUES ('", ...
        string(sorted_batch_id(i)), "','", ...
         string(sorted_start_time(i)), "','", ...
         string(completion_time(order(i))), "','", ...
         string(lateness(order(i))), "','", ...
        string(sorted_job_on_resource(i)), "')");
     exec(conn, query);
end
 

%% GANTT SCHEDULING

n_jobs = length(sorted_batch_id);
n_machines = 3;  

startTime = zeros(n_jobs, n_machines);
completionTime = zeros(n_jobs, n_machines);

for i = 1:n_jobs
    resource_idx = sorted_job_on_resource(i);
    startTime(i, resource_idx) = sorted_start_time(i);
    completionTime(i, resource_idx) = completion_time(order(i));
end

graph_title = 'Gantt Chart for Job Scheduling';

gantt_scheduling(startTime, completionTime, n_machines, n_jobs, graph_title);
 
 
max_time = max(completionTime(:)); 
xticks(1:max_time); 
yticks(1:n_machines);
yticklabels(arrayfun(@(x) sprintf('Laser Cutter %d', x), 1:n_machines, 'UniformOutput', false));
 
ax = gca;
ax.YGrid = 'on';  
ax.XGrid = 'on'; 
% 
legend('show'); 
legend('-DynamicLegend'); 
 
for i = 1:n_jobs
    resource_idx = sorted_job_on_resource(i);
    start_x = startTime(i, resource_idx);
    end_x = completionTime(i, resource_idx);
 
    text_x = (start_x + end_x) / 2;  
    text_y = resource_idx;    

    job_name = sprintf('Job %d', sorted_batch_id(i)); 
    text(text_x, text_y, job_name, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10);
end
 
lines = findobj(gca, 'Type', 'Line');
for i = 1:length(lines)
    lines(i).LineWidth = 60; 
end



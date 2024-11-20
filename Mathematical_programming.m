%% Mathematical Programming Algorithm 

batch_id=data{:,1};
arrival_time=double(data{:,2});
due_date=double(data{:,3});
processing_time=double(data{:,4:6});
n_jobs = length(arrival_time);
n_laser=3;
M=10000;

prob=optimproblem('ObjectiveSense','min');

% decision variables 
S=optimvar('S',n_jobs,'LowerBound',0);                  % start time

C=optimvar('C',n_jobs,'LowerBound',0);                  % completion time

y=optimvar('y',n_jobs,...                               % ritardo
    'Type','integer','LowerBound',0,'UpperBound',1);
z=optimvar('z',n_jobs,n_laser,...                       % assegnamento job-laser
    'Type','integer','LowerBound',0,'UpperBound',1);
x=optimvar('x',n_jobs,n_jobs,...                        % jobs
    'Type','integer','LowerBound',0,'UpperBound',1);
t_late=optimvar('c_rit',n_jobs,'LowerBound',0);         % time lateness

alpha=1000;

% Objective function 
prob.Objective = alpha*sum(y) + sum(t_late);

%% Constraints

% start time greater than or equal to arrival time
cons1 = optimconstr(n_jobs);
for i=1:n_jobs
    cons1(i)=S(i)>=arrival_time(i);
end
prob.Constraints.cons1=cons1;

% completion time = start time + processing time
cons2 = optimconstr(n_jobs);
for i=1:n_jobs
    somma=0;
    for k=1:n_laser
        sum=sum+z(i,k)*processing_time(i,k);
    end
    cons2(i)=C(i)==S(i)+sum;
end
prob.Constraints.cons2=cons2;

% each job can be assigned to only one laser cutter
cons3 = optimconstr(n_jobs);
for i=1:n_jobs
    sum=0;
    for k=1:n_laser
        sum=sum+z(i,k);
    end
    cons3(i)=sum==1;
end
prob.Constraints.cons3=cons3;

% if the work is completed after the due-date, the work is late
cons4 = optimconstr(n_jobs);
for i=1:n_jobs
    cons4(i)=(C(i)-due_date(i))-M*y(i)<=0;
end
prob.Constraints.cons4=cons4;

% priority constraints
cons5 = optimconstr((n_jobs*n_jobs-n_jobs)*n_laser);
cons6 = optimconstr((n_jobs*n_jobs-n_jobs)*n_laser);
count=0;
for i=1:n_jobs
    for j=1:n_jobs
        if(i~=j)
            for k=1:n_laser
                count=count+1;

                % i preceding j
                cons5(count)=S(j)>=C(i)-M*(1-x(i,j))-M*(1-z(i,k))-M*(1-z(j,k));

                % j preceding i
                cons6(count)=S(i)>=C(j)-M*x(i,j)-M*(1-z(i,k))-M*(1-z(j,k));
            end
        end
    end
end
prob.Constraints.cons5=cons5;
prob.Constraints.cons6=cons6;

% late time y(i)=1
cons7 = optimconstr(n_jobs);
for i=1:n_jobs
    cons7(i)=t_late(i)+M*(1-y(i))>=C(i)-due_date(i);
end
prob.Constraints.cons7=cons7;

% problem solving 
options = optimoptions('intlinprog','MaxTime',120);
sol = solve(prob,'Options',options);

% extraction of results from the solver
start_time_math = round(sol.S);
completion_time_math = round(sol.C);
lateness_math = round(sol.c_rit);

makespan_math = max(completion_time_math);  % makespan
jobs_late_math = sum(lateness_math > 0);  % number of late jobs 
total_late_time_math = sum(lateness_math(lateness_math > 0));  % total late time

%% Printing the scheduling sequence for the mathematical programming algorithm

[~, order_math] = sort(completion_time_math);  
sorted_batch_id_math = batch_id(order_math);  
sorted_start_time_math = start_time_math(order_math);
sorted_completion_time_math = completion_time_math(order_math);  

% finding which resource each job was run on
sorted_job_on_resource_math = zeros(n_jobs, 1);
for i = 1:n_jobs
    for k = 1:n_laser
        if round(sol.z(order_math(i), k)) == 1  
            sorted_job_on_resource_math(i) = k;
            break;
        end
    end
end


fprintf('\n--- Mathematical Programming ---\n');
fprintf('Job\tStart\tCompletion\tLateness\tLaser\n');
for i = 1:n_jobs
    fprintf('%d\t%.2f\t%.2f\t\t%.2f\t\t%d\n', ...
        sorted_batch_id_math(i), sorted_start_time_math(i), ...
        sorted_completion_time_math(i), lateness_math(order_math(i)), ...
        sorted_job_on_resource_math(i));
end


%% Database connection and save data into DB
 
conn = database('industrialautomation', 'industrial', 'Automation1234');

% deleting MP table before saving new data
query = "DELETE FROM [industrialautomation].[dbo].[MP]"; % query per eliminare tutti i record
exec(conn, query);

% inserting sorted data 
for i = 1:n_jobs
    query = strcat("INSERT INTO [industrialautomation].[dbo].[MP] (batch_id, start_time, completion_time, late_time, resource) VALUES ('", ...
        string(sorted_batch_id_math(i)), "','", ...
        string(sorted_start_time_math(i)), "','", ...
        string(sorted_completion_time_math(i)), "','", ...
        string(lateness_math(order_math(i))), "','", ...
        string(sorted_job_on_resource_math(i)), "')");
    exec(conn, query);
end
 
% close database connection
close(conn);




% %% GANTT SCHEDULING
% 
% J = n_jobs;
% M = n_laser;
% 
% startTime = zeros(J, M);
% completionTime = zeros(J, M);
% 
% for i = 1:J
%     resource = sorted_job_on_resource_math(i);
%     startTime(i, resource) = sorted_start_time_math(i);
%     completionTime(i, resource) = sorted_completion_time_math(i);
% end
% 
% graph_title = 'Diagramma di Gantt - Distribuzione dei Job sui Laser Cutter';
% 
% gantt_scheduling(startTime, completionTime, M, J, graph_title);
% 
% 
% max_time = max(completionTime(:)); 
% xticks(1:max_time); 
% yticks(1:M);
% yticklabels(arrayfun(@(x) sprintf('Laser %d', x), 1:M, 'UniformOutput', false));
% 
% ax = gca;
% ax.YGrid = 'on';  
% ax.XGrid = 'on'; 
% 
% for i = 1:J
%     resource_idx = sorted_job_on_resource_math(i);
%     start_x = startTime(i, resource_idx);
%     end_x = completionTime(i, resource_idx);
% 
%     text_x = (start_x + end_x) / 2;  
%     text_y = resource_idx;    
% 
%     job_name = sprintf('Job %d', i); 
%     text(text_x, text_y, job_name, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10);
% end
% 
% lines = findobj(gca, 'Type', 'Line');
% for i = 1:length(lines)
%     lines(i).LineWidth = 60; 
% end




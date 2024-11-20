% Inizialization
n_jobs = 5;

batch_id = (1:n_jobs)';
arrival_time = randi([1,20], n_jobs, 1);
due_date = arrival_time + randi([2, 20], n_jobs, 1);
processing_time1 = randi([2, 20], n_jobs, 1);
processing_time2 = randi([2, 20], n_jobs, 1);
processing_time3 = randi([2, 20], n_jobs, 1);

data = table(batch_id, arrival_time, due_date, processing_time1, processing_time2, processing_time3);
% disp(data);

%% Save data into DB

conn = database('industrialautomation','industrial','Automation1234');
query=strcat("delete from [industrialautomation].[dbo].[Batch]");
exec(conn,query) 

for i=1:n_jobs
    query=strcat("insert into [industrialautomation].[dbo].[Batch] values('", ...
        string(batch_id(i)),"','", ...
        string(arrival_time(i)),"','", ...
        string(due_date(i)),"','", ...
        string(processing_time1(i)),"','", ...
        string(processing_time2(i)),"','", ...
        string(processing_time3(i)),"')");
    exec(conn,query)
end

%% Close connection to database
close(conn)
clear conn query

%% Comparison of Results

fprintf('Comparison of Dynamic Programming and Mathematical Programming:\n');
fprintf('Metric\t\t\t Dynamic \t Mathematical \n');
fprintf('Makespan\t\t %.2f\t\t %.2f\n', makespan_dp, makespan_math);
fprintf('Jobs Late\t\t %d\t\t %d\n', jobs_late_dp, jobs_late_math);
fprintf('Total Late \t\t %.2f\t\t %.2f\n', total_late_time_dp, total_late_time_math);
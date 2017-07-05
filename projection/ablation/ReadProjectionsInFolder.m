function [ metric1_per_seed, acc_per_seed, projection_filenames, file_date ] = ReadProjectionsInFolder( root_folder, task, file_date )
    %% check params
    if ~exist('root_folder','var')
        error('Please define a root folder as first param');
    end
    CheckIsChar(root_folder);
    if ~exist('task','var')
        error('Please define a task name as second param');
    end
    CheckIsChar(task);
    if ~exist('file_date','var')
        file_date = date;
    end
    CheckIsChar(file_date);
    %% get files form folder according to prefix
    projection_file_prefix = ['projection_result_' task '_' file_date];
    projection_filenames = FindAllFilesOfPrefix(projection_file_prefix,root_folder);
    n_projs = numel(projection_filenames);
    if n_projs == 0
       error(['Found no file with prefix: ' projection_file_prefix]); 
    end
    disp(['Found ' num2str(n_projs) ' files with prefix: ' projection_file_prefix]);
    n_seeds_ablation = zeros(1,n_projs);
    %% read all projections in root_folder for the task and file date
    for i=1:n_projs
        aux = projection_filenames{i}(numel(projection_file_prefix)+2:end);
        aux = strsplit(aux,'_');
        n_seeds_ablation(i) = str2double(aux{1});
    end   
    %% sort filenames per number of seeds (ascend)
    [n_seeds_ablation,n_seeds_ixs] = sort(n_seeds_ablation,'ascend');
    projection_filenames = projection_filenames(n_seeds_ixs);
    metric1_per_seed = zeros(1,n_projs);
    acc_per_seed = zeros(1,n_projs);
    for ix_ablation=1:n_projs        
        load([root_folder projection_filenames{ix_ablation}]);
        metric1_per_seed(ix_ablation) = curr_metric1;
        acc_per_seed(ix_ablation) = curr_acc;
        disp(['Processed file #' num2str(ix_ablation) ' that used ' num2str(n_seeds_ablation(ix_ablation)) ' seeds; metric1' char(9) num2str(metric1_per_seed(ix_ablation)) ' and accuracy' char(9) num2str(acc_per_seed(ix_ablation))]);
    end
    %% plot metirc1
    figure;
    plot(metric1_per_seed);
    title('Metric1 per number of seeds');
    ax = gca;
    ax.XTickLabel = n_seeds_ablation;
    ax.YLim = [0 1];
    %% plot accuracy
    figure;
    plot(acc_per_seed);
    title('Accuracy per number of seeds');
    ax = gca;
    ax.XTickLabel = n_seeds_ablation;
    ax.YLim = [0 1];
end


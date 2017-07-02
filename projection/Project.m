function [best_scores, best_categ_scores, best_ptools, best_ptool_maps, Ps, gpr_scores, tools_gt, test_pcls_filenames, accuracy_best,accuracy_categs,metric_1,metric_2] = Project( task, test_folder, gpr )
    %% get all test pcls
    test_pcls_filenames = FindAllFilesOfType( {'ply'}, test_folder );
    %% get groundtruth for existing tools
    [ ~, tool_masses, tools_gt ] = ReadGroundTruth([test_folder 'groundtruth_' task '.csv']);
    gpr_scores = zeros(1,numel(test_pcls_filenames));
    tot_toc = 0;
    best_scores = zeros(1,numel(test_pcls_filenames));
    best_ptools =  zeros(numel(test_pcls_filenames),25);
    best_ptool_maps = zeros(numel(test_pcls_filenames),6);
    Ps = cell(1,numel(test_pcls_filenames));
    %% get ideal ptool (from maximum of gpr prediction over its training data)
    [~,max_gpr_ix] = max(gpr.predict(gpr.ActiveSetVectors));
    ideal_ptool = gpr.ActiveSetVectors(max_gpr_ix,:);
    [ ~, n_seeds] = ProjectionHyperParams();
    disp(['Projecting ' num2str(numel(test_pcls_filenames)) ' tools on ' test_folder ' using ' num2str(n_seeds) ' seeds']);
    
    for i=1:numel(test_pcls_filenames)
        tic; 
        try
            P = ReadPointCloud([test_folder test_pcls_filenames{i}],100);
            [ best_scores(i), best_ptools(i,:), best_ptool_maps(i,:) ] = SeedProjection( ideal_ptool, P, tool_masses(i), task, @TaskFunctionGPR, gpr, 1 ); 
        catch E
           disp(['Error on tool  ' test_pcls_filenames{i} ' (maybe memory?)']);
           disp(E.message);
        end
        msg = ['Projected ' test_pcls_filenames{i} char(9) char(9) num2str(best_scores(i)) char(9) char(9) num2str(TaskCategorisation(best_scores(i),task)) char(9) char(9) num2str(tools_gt(i)) char(9)];
        tot_toc = DisplayEstimatedTimeOfLoop(tot_toc+toc,i,numel(test_pcls_filenames),msg);
        save([test_folder 'projection_result_' task '.mat'])
    end
    best_categ_scores = TaskCategorisation(best_scores,task);
    [accuracy_best,accuracy_categs,metric_1,metric_2] = PlotTestResults( best_scores, best_categ_scores, tools_gt, test_pcls_filenames );
    disp(['Saving results: ' test_folder 'projection_result_' task '.mat']);
    save([test_folder 'projection_result_' task '.mat']);
end


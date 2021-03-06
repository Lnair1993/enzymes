%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% By Paulo Abelha (p.abelha@abdn.ac.uk) 2017
%
%% Script to run a demo for fitting superquadrics/superparaboloids to point clouds
%   script will fit SQs to the pcls and also create pcls fot the fitted SQs
%   and save them to a ply file
%
% I learned superquadrics mainly from the bible: Segmentation and Recovery of Superquadrics - Ales Jacklic et al
% I derived the superparaboloid myself in order to model container parts
%
% pcl is short for point cloud
% SQ is short for superquadric/superparaboloid
% segms is short for segments

disp('Running demo for SQ fitting:');
%% get root folder
script_fullpath = mfilename('fullpath');
root_folder = script_fullpath(1:end-size(mfilename,2));
%% get pcl filenames
pcl_filenames = {...
    'bowl_2_3dwh.ply', ...
    'tableknife_s_3dwh_1.ply','rollingpin_w_3dwh_2.ply', ...
    'breadknife_w5s_3dwh_3.ply', ...
    'fryingpan_p2a_3dwh_2.ply', ...
    'mallet_w_3dwh_1.ply'};
pcl_masses = [0.1022 0.487 0.2759 0.7785 0.9183];
%% fit SQs to each pcl
tot_toc = 0;
for i=1:numel(pcl_filenames)
    tic;
    pcl_filepath = [root_folder pcl_filenames{i}];
    disp([char(9) 'Reading pointcloud: ' pcl_filepath])
    P = ReadPointCloud(pcl_filepath);
    figure;
    disp([char(9) 'Point cloud has ' num2str(numel(P.segms)) ' segment(s)'])
    disp([char(9) 'Fitting superquadric(s)...'])
    [ SQs, TOT_ERROR, SEGM_ERRORS, SEGM_ERRORS_PCL_SQ, SEGM_ERRORS_SQ_PCL ] = PCL2SQ( P, 2, 1, 0, [1 1 1 0 1] );   
    title('SQs fitted to the pcl');
    figure;
    title('SQs only');
    PlotSQs(SQs);    
    tot_toc = DisplayEstimatedTimeOfLoop(tot_toc+toc,i,numel(pcl_filenames));    
end
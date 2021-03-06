% plot a 21-dimensional ptool vector (returns both pcls)
function [ Ps ] = PlotPtools( ptools, task_name, plot_faces, colours )
    if ~exist('plot_faces','var')
        plot_faces = 0;
    end
    if ~exist('colours','var')
        colours = -1;
    end
    % convert list of ptools to a matrix N x 21
    ptools = PTool2Matrix(ptools);
    % check for task plot
    if ~exist('task_name','var')
        task_name = '';
    end
    Ps = cell(1,size(ptools,1));
    %% get grasp and action SQs
    for i=1:size(ptools,1)
        % get pcl from ptool
        figure; 
        P = PTool2PCL( ptools(i,:), task_name );
        if plot_faces
            F = P.f;
            F = F + 1;
            %figure;
            trisurf(F, P.v(:,1),P.v(:,2),P.v(:,3)); axis equal;
        else
            PlotPCLSegments(P,-1,-1,colours);
        end
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        Ps{i} = P;
    end    
    if size(ptools,1) == 1
        Ps = Ps{1};
    end
end


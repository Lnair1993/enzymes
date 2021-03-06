function [ SQs_Ps, P ] = PlotSQs( SQs, downsample, invert_colours, colours, plot_fig )
    if ~exist('downsample','var') || downsample < 0
       downsample = 10000; 
    end
    if ~exist('invert_colours','var') || invert_colours < 0
       invert_colours = 0; 
    end
    if ~exist('plot_fig','var')
       plot_fig = 1; 
    end
    temp = [];
    if iscell(SQs)
        for i=1:size(SQs,2)
            if ~isempty(SQs{i})
                temp(end+1,:) = SQs{i};
            end
        end
        SQs = temp;
    end    
    if ~exist('colours','var') || (isreal(colours) && colours < 1)
        basic_colours = {'.r' '.g' '.b' '.y' '.m' '.c'}; 
        colours = {};
        i=1; j=1;
        while i <= size(SQs,1)
            while j <= size(basic_colours,2) && j <= size(SQs,1)
                colours{end+1} = basic_colours{j};
                j = j + 1;
            end
            j = 1;
            i = i + 1;
        end
        if invert_colours
            colours = fliplr(colours);
        end
    end
    SQs_Ps = cell(1,size(SQs,1));    
    if plot_fig
        hold on;
        axis equal;
    end
    P.v = [];
    P.n = [];
    P.u = [];
    for i=1:size(SQs,1)
        Q = SQ2PCL( SQs(i,:), downsample );
        P.segms{i} = Q;    
        SQs_Ps{i} = Q; 
        P.v = [P.v; Q.v];
        P.n = [P.n; Q.n];
        P.u = [P.u; repmat(i,downsample,1)];
        if plot_fig
            scatter3(Q.v(:,1),Q.v(:,2),Q.v(:,3),200,colours{min(size(colours,2),i)});   
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
        end
    end
    P = AddColourToSegms(P);
    if size(SQs,1) == 1
        SQs_Ps = SQs_Ps{1};
    end
    if plot_fig
        hold off;
    end
end


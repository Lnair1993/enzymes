function [ ix_seeds, seeds, seeds_pcls ] = PlantSeedsPCL( P, n_seeds, seeds_radii, plot_fig )
    % max number of seeds to plot
    MAX_PLOT_N_SEEDS = 100;
    if ~exist('plot_fig','var')
        plot_fig = 0;
    end
    % downsample pcl    
    %% get seeds over target pcl
    ix_seeds = randi(size(P.v,1),n_seeds,1);
    seeds = P.v(ix_seeds,:);    
    %% get seed pcls
    seeds_pcls = cell(1,n_seeds*numel(seeds_radii));
    ix = 1;
    MIN_N_PCL_PTS = 100;
    for i=1:n_seeds
        for j=1:numel(seeds_radii)
            seed_radius = seeds_radii(j);
            center = seeds(i,:);
            F = ((P.v(:,1)-center(1))/seed_radius).^2 + ((P.v(:,2)-center(2))/seed_radius).^2  + ((P.v(:,3)-center(3))/seed_radius).^2;
            add_func = 0;
            ixs_seed_pcl = F<=1+add_func;
            seeds_pcls{ix} = P.v(ixs_seed_pcl,:);
            while size(seeds_pcls{ix},1) < MIN_N_PCL_PTS
                ixs_seed_pcl = F<=1+add_func;
                seeds_pcls{ix} = P.v(ixs_seed_pcl,:);
                add_func = add_func + 0.1;
            end
            ix = ix + 1;
        end
    end
    if plot_fig
        figure;
%         scatter3(P.v(:,1),P.v(:,2),P.v(:,3),'.k');
        axis equal;
        hold on;
        title(['Pcl with #' num2str(n_seeds)  ' seeds and #' num2str(numel(seeds_radii)) ' radii; max #seeds=' num2str(MAX_PLOT_N_SEEDS) '']);        
        pcl_ixs = randi(numel(seeds_pcls),1,min(numel(seeds_pcls),MAX_PLOT_N_SEEDS));        
        PlotPCLS(seeds_pcls(pcl_ixs));
        hold off;        
    end
end


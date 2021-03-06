% By Paulo Abelha
%
% Uniformly samples a superellipsoid
% This function will approximate "thin" superellipsoids to be 2D)
% A thin SQ is defined in terms of metric units (m)
% A SQ is thin if its smallest scale over largest is smaller than 0.1 
% Inputs:
%   lambda: 1x5 array with the parameters [a1,a2,a3,eps1,eps2]
%   plot_fig: whether to plot
%
% Outputs:
%   pcl: Nx3 array with the uniform point cloud
%   etas: the u parameters for the superparabola
%   omegas: the omega parameters for the superellipse
function [ pcl, normals, etas, omegas, faces ] = superellipsoid( lambda, in_max_n_pts, plot_fig, colour, D )        
    %% max number of points for pcl
    MAX_N_PTS = 1e7;
    %% max number of cross sampling of angles (etas x omegas) - for memory issues
    MAX_N_CROSS_ANGLES = MAX_N_PTS/2;
    %% check params
    if ~exist('plot_fig','var')
        plot_fig = 0;
    end
    if ~exist('colour','var')
        colour = '.k';
    end
    %% check whether to plot
    if ~exist('in_max_n_pts','var')
        in_max_n_pts = Inf;
    end
    %% deal with thin SQs
    [ thin_SQ, scale_sort, scale_sort_ixs, prop_thin ] = IsThinSQ( lambda );
    if thin_SQ
        [pcl, normals, vol_mult, omegas] = Get2DSuperellipsoid(lambda, scale_sort,scale_sort_ixs);
        etas = [];
    else
        % deal with SQs with a scale number less than 1
        % this is too deal with arbitrarly small SQs and 
        % still being able to sample
        [ vol_mult, lambda ] = GetVolMult( lambda );  
        %% get parameters
        a1 = lambda(1);
        a2 = lambda(2);
        a3 = lambda(3);
        eps1 = lambda(4);
        eps2 = lambda(5);
        Kx = lambda(9);
        Ky = lambda(10);
        k_bend = lambda(11);        
        %% uniformly sample a superparabola and a superellipse
        % arclength constant
        if ~exist('D','var')
            [ ~, etas ] = superellipse( 1, a3, eps1);
            [ ~, omegas ] = superellipse( a1, a2, eps2); 
        else
            [ ~, etas ] = superellipse( 1, a3, eps1, D);
            [ ~, omegas ] = superellipse( a1, a2, eps2, D); 
        end        
        omegas = sort(omegas);
        etas = sort(etas);
        etas = etas';
        n_cross_angles = size(etas,2) * size(omegas,1);
        if n_cross_angles > MAX_N_CROSS_ANGLES
            error(['Too many (' num2str(n_cross_angles) ') angles were sampled. maximum is ' num2str(MAX_N_CROSS_ANGLES) ' angles were sampled. Aborting due to possible freezing due to lack of RAM. Check SQ scale param']);
        end
        %% get the points with the superparaboloid parametric equation
        pcl = zeros(n_cross_angles*8,3);
        normals = pcl;
        ix_end=0;
        for i=-1:2:1
            for j=-1:2:1
                for k=-1:2:1
                    ix_beg=ix_end+1;
                    ix_end=(ix_beg+n_cross_angles)-1;
                    % get permutated sampled angles
                    cos_j_omegas = cos(j*omegas);
                    sin_j_omegas = sin(j*omegas);
                    cos_k_etas = cos(k*etas);
                    sin_k_etas = sin(k*etas);
                    %% get points
                    X = a1*i*signedpow(cos_j_omegas,eps2)*signedpow(cos_k_etas,eps1); X=X(:);
                    Y = a2*i*signedpow(sin_j_omegas,eps2)*signedpow(cos_k_etas,eps1); Y=Y(:);             
                    Z = a3*i*ones(size(omegas,1),1)*signedpow(sin_k_etas,eps1); Z=Z(:);
                    %% get normals                    
                    nx = (cos_j_omegas.^2)*cos_k_etas.^2; nx = nx(:);
                    ny = (sin_j_omegas.^2)*cos_k_etas.^2; ny = ny(:);
                    nz = ones(size(omegas,1),1)*sin_k_etas.^2; nz = nz(:); nz(nz<1e-10) = 0;
                    one_over_X = 1./X; one_over_X(X==0) = 0;
                    one_over_Y = 1./Y; one_over_Y(Y==0) = 0;
                    one_over_Z = 1./Z; one_over_Z(Z==0) = 0;
                    normals(ix_beg:ix_end,:) = [one_over_X.*nx one_over_Y.*ny one_over_Z.*nz];
                    %% apply tapering
                    if Kx || Ky
                        f_x_ofz = ((Kx.*Z)/a3) + 1; 
                        X = X.*f_x_ofz;
                        f_y_ofz = ((Ky.*Z)/a3) + 1;
                        Y = Y.*f_y_ofz; 
                    end
                    %% apply bending
                    if k_bend
                        X = X + (k_bend - sqrt(k_bend^2 + Z.^2));
                    end
                    pcl(ix_beg:ix_end,:) = [X Y Z];                    
                    %% apply tapering transformation to the normals
                    if Kx || Ky
                        nx = normals(ix_beg:ix_end,1).*f_y_ofz;
                        ny = normals(ix_beg:ix_end,2).*f_x_ofz;
                        f_prime_x_ofz = (Kx/a3).*X;
                        f_prime_y_ofz = (Ky/a3).*Y;
                        z_x_taper_factor = -f_prime_x_ofz.*f_y_ofz;
                        z_y_taper_factor = -f_prime_y_ofz.*f_x_ofz;
                        nz = z_x_taper_factor.*normals(ix_beg:ix_end,1) + z_y_taper_factor.*normals(ix_beg:ix_end,2) + f_x_ofz.*f_y_ofz.*normals(ix_beg:ix_end,3);
                        normals(ix_beg:ix_end,:) = [nx ny nz];
                    end
                    %% apply bending transformation to the normals
                    if k_bend
                        bend_T = Z./sqrt(k_bend^2 + Z.^2);
                        normals(ix_beg:ix_end,3) = bend_T.*normals(ix_beg:ix_end,1) + normals(ix_beg:ix_end,3);
                    end
                    normals(ix_beg:ix_end,:) = normr(normals(ix_beg:ix_end,:));
                end
            end
        end
    end
    faces = [];
    % get experimental faces
%     s1 = 35;
%     s2 = 35;
%     M = size(omegas,1);
%     N = size(etas,2);
%     F1 = [1; interleave(1+s1:s1:M,1+s1:s1:M)]; F1 = F1(1:end-1);
%     F2 = interleave(1+M*s2:s1:M*(s2+1)-s1,1+M*s2:s1:M*(s2+1)-s1);
%     F3 = interleave(1+s1:s1:M,[1+s1:s1:M] + M*s2);
%     faces = [F1 F2 F3];
%     ix = 0;
%     faces_orig = faces;
%     for i=1:s2:N-s1
%         ix = ix+1;
%         faces = [faces; faces_orig+(ix*faces(1,2))];
%     end
%     faces_orig = faces;
%     for i=2:3
%         faces = [faces; faces_orig.*i];
%     end
    %% deal with low cubic vol SQs
    pcl = pcl./vol_mult;
    %% get final points and normals    
    MAX_N_PTS = min(MAX_N_PTS,in_max_n_pts);
    ixs = randsample(1:size(pcl,1),min(size(pcl,1),MAX_N_PTS));
%     ixs = logical(ones(size(pcl,1),1));
    %% get ixs according to downsampling
%     a=1:size(pcl,1);
%     ixs=zeros(size(pcl,1),1);
%     n_mod = round(size(pcl,1)/MAX_N_PTS);
%     ixs(mod(a,n_mod)==0) = 1;
%     ixs = logical(ixs);
    %% downsample pcl and normals
    pcl = pcl(ixs,:); 
%     pcl = pcl(abs(sum(ixs)-MAX_N_PTS)+1:end,:);
    normals = normals(ixs,:);
    %% get transformations
    rot_mtx = GetEulRotMtx(lambda(6:8));    
    T = [[rot_mtx lambda(end-2:end)']; lambda(end-2:end) 1];
    %% transform points and normals
    pcl = [T*[pcl'; ones(1,size(pcl,1))]]';
    pcl = pcl(:,1:3);
    normals = [rot_mtx*normals']';
    %% plot
    if plot_fig        
        scatter3(pcl(:,1),pcl(:,2),pcl(:,3),10,colour); axis equal;   
    end
end

function [final_pcl, final_normals, vol_mult, omegas] = Get2DSuperellipsoid(lambda, scale_sort, scale_sort_ixs)
    % decide on which eps for the 2D sq
    eps = 1;
    if scale_sort_ixs(1) == 3
        eps = lambda(5);
    end
    % deal with SQs with a scale number less than 1
    % this is too deal with arbitrarly small SQs and 
    % still being able to sample
    vol_mult = 1;
    if any(scale_sort(2:3) < 1)
        vol_mult = 1/min(scale_sort(2:3));
        scale_sort(2:3) = scale_sort(2:3)*vol_mult;
        lambda(1:3) = lambda(1:3)*vol_mult;
    end 
    a=lambda(1:3);
    a=a(a>min(a));
    [pcl, omegas] = superellipse( a(1), a(2), eps);        
    ixs = randsample(1:size(pcl,1),min(1000,size(pcl,1)));
    pcl = pcl(ixs,:);
    n_iter = floor(min(1000,max(scale_sort(2:3))/0.001));
    n_pts = size(pcl,1);
    final_pcl = zeros(n_pts+n_pts*n_iter,2);
    final_pcl(1:n_pts,:) = pcl;
    for i=2:n_iter+1
        multiplier = 1-(i/n_iter);
        pcl_to_add = pcl*multiplier;
        beg = ((i-1)*n_pts)+1;
        final_pcl(beg:(beg-1)+size(pcl_to_add,1),:) = pcl_to_add;
    end
    final_pcl = [final_pcl zeros(size(final_pcl,1),1)];
    final_normals = repmat([0 0 -1],size(final_pcl,1),1); 
    final_pcl = [final_pcl; final_pcl+scale_sort(1)];
    final_normals = [final_normals; repmat([0 0 1],size(final_pcl,1),1)];
    % translate and rotate points
    % get a previous rotation to apply because sampling is done in the XY plane
    rot_prev = eye(3);
    if scale_sort_ixs(1) == 1
        rot_prev = GetRotMtx(pi/2,2);
    end
    if scale_sort_ixs(1) == 2
        rot_prev = GetRotMtx(pi/2,1);
    end
    rot_SQ = GetEulRotMtx(lambda(6:8));
    final_pcl = RotateAndTranslatePoints( final_pcl, rot_SQ*rot_prev, lambda(end-2:end)' );    
    % translate and rotate points
    final_normals = RotateAndTranslatePoints( final_normals, rot_SQ, zeros(3,1) );
end


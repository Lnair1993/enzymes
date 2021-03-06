% By Paulo Abelha (p.abelha at abdn ac uk )
% based on [PiluFisher95] Pilu, Maurizio, and Robert B. Fisher. �Equal-distance sampling of superellipse models.� DAI RESEARCH PAPER (1995)
function [ final_pcl, final_normals, omegas, etas] = UniformSQSampling3D( SQ, calc_normals_in, downsample_in, plot_in, recursive_sampling_in  )
    %% if SQ is a paraboloid, revert to paraboloid2pcl funciton
    if SQ(5) < 0
        if ~exist('plot_in','var')
            plot_in = 0;
        end
        [final_pcl, omegas] = Paraboloid2PCL(SQ, downsample_in, plot_in);
        final_normals = [];
        etas = [];
        return;
    end
    %% check SQ proportion
    % if SQ has a very small proportion between min and max scale param
    %   AND the other 2 have a big enough proportion
    % try to sample in 2D
    MIN_PROP_SCALE_FOR_3D = 0.04;
    [sorted_scale,sorted_scale_ixs] = sort(SQ(1:3));
    if sorted_scale(1)/sorted_scale(2) < MIN_PROP_SCALE_FOR_3D || sorted_scale(1)/sorted_scale(3) < MIN_PROP_SCALE_FOR_3D        
        [~,min_scale_ix] = min(SQ(1:3));
        if min_scale_ix == 3
            shape_ix = 5;
        else
            shape_ix = 4;
        end
        orig_scale = SQ(1:3);
        new_scale = [0 0];
        ix=0;
        for i=1:3
            if i ~= sorted_scale_ixs(1)                
                ix=ix+1;
                new_scale(ix) = orig_scale(i);
            end
        end
        SQ_2d = [new_scale max(SQ(shape_ix),0.2)];
        final_pcl = UniformSQSampling2D( SQ_2d, MIN_PROP_SCALE_FOR_3D/500 );
        n_iter = 100;
%         SQ_2d_orig = SQ_2d;
        if exist('downsample_in','var')
            downsample = downsample_in;
        end
        for i=1:n_iter
            multiplier = 1-(i/n_iter);
%             SQ_2d(1:2) = SQ_2d_orig(1:2).*multiplier; 
%             pcl_to_add = UniformSQSampling2D( SQ_2d, MIN_PROP_SCALE_FOR_3D/500 );%final_pcl*multiplier;
            pcl_to_add = final_pcl*multiplier;
            ixs = randsample(1:size(pcl_to_add,1),min(round(1000*multiplier),size(pcl_to_add,1)));
            pcl_to_add = pcl_to_add(ixs,:);
            final_pcl = [final_pcl; pcl_to_add];
        end
        final_pcl_Zs = normrnd(0,0.0001,size(final_pcl,1),1);
        final_pcl = [final_pcl final_pcl_Zs];
        % downsample if required
        if downsample
            ixs = randsample(1:size(final_pcl,1),min(downsample,size(final_pcl,1)));
            final_pcl = final_pcl(ixs,:);
        end                   
        % translate and rotate points
        % get a previous rotation to apply because sampling is done in the XY plane
        rot_prev = eye(3);
        if sorted_scale_ixs(1) == 1
            rot_prev1 = GetRotMtx(pi/2,2);
            rot_prev = GetRotMtx(pi/2,1)*rot_prev1;
        end
        if sorted_scale_ixs(1) == 2
            rot_prev = GetRotMtx(pi/2,1);
        end
        rot_SQ = GetEulRotMtx(SQ(6:8));
        final_pcl = RotateAndTranslatePoints( final_pcl, rot_SQ*rot_prev, SQ(end-2:end)' );
        % translate and rotate points
        final_normals = RotateAndTranslatePoints( repmat([0 0 1],size(final_pcl,1),1), rot_SQ, zeros(3,1) );
        % plot if required
        if exist('plot_in','var') && plot_in
            scatter3(final_pcl(:,1),final_pcl(:,2),final_pcl(:,3),'.k'); axis equal
            % plot dual superquadric
            % figure; scatter3(final_normals(:,1),final_normals(:,2),final_normals(:,3)); axis equal
        end 
        return;
    end
    if SQ(12) < SQ(3)
        SQ(12) = 0;
    else
        CheckSQParams( SQ );
    end
    % get flag for calculating normals (default is not calculating normals)  
    final_normals = [];
    calc_normals = 0;    
    if nargin > 1
        calc_normals = calc_normals_in;       
    end
    % get flag for downsampling (default is not downsampling)
    downsample = 0;
    if nargin > 2
        downsample = downsample_in;
    end
    % get flag for plotting (default is not plotting)
    plot = 0;
    if nargin > 3
        plot = plot_in;
    end
    recursive_sampling = 0;
    if nargin > 4
        recursive_sampling = recursive_sampling_in;
    end
    % get SQ params
    a1 = SQ(1);
    a2 = SQ(2);
    a3 = SQ(3);
    a4 = 0;
    tor = 0;
    e1 = SQ(4);   
    e2 = SQ(5); 
    eul1 = SQ(6);
    eul2 = SQ(7);
    eul3 = SQ(8);
    Kx = SQ(9);   
    Ky = SQ(10);
    k_bend = SQ(11);
    alpha = SQ(12);    
    x_c = SQ(13);
    y_c = SQ(14);
    z_c = SQ(15);    
    % if supertoroid    
    if size(SQ,2) == 16
        tor = 1;
        a4  = SQ(4);
        e1 = SQ(5);   
        e2 = SQ(6);
        eul1 = SQ(7);
        eul2 = SQ(8);
        eul3 = SQ(9);
        Kx = SQ(10);   
        Ky = SQ(11);
        k_bend = SQ(12);
        alpha = SQ(13);
        x_c = SQ(14);
        y_c = SQ(15);
        z_c = SQ(16); 
        if a4 <= 1
            if a4 == 0
                tor=0;
            else
                a4 = (1/a4)-1;
            end
            a1 = a1/(a4+1);
            a2 = a2/(a4+1);
        end        
    end
    % try to estimate D_theta
    approx_vol = a1*a2*a3;
    rescaling_happened = 0;
    if approx_vol < 1
        %warning('Superquadric has volume smaller than 1. Rescaling superquadric to estimate D_theta.');
        rescaling_happened = 1;
        rescaling_factor = 2;
        orig_as = [a1 a2 a3 k_bend];
        while approx_vol < 1
            a1 = orig_as(1)*rescaling_factor;
            a2 = orig_as(2)*rescaling_factor;
            a3 = orig_as(3)*rescaling_factor;
            k_bend = orig_as(4)*rescaling_factor;
            rescaling_factor = rescaling_factor*2;
            approx_vol = a1*a2*a3;
        end        
    end
    % use magic number to estimate D_theta
    magic_num = max(0.05,0.1-max(0.95,abs(min(1.9,min(e1,e2))-1))/10);
    D_theta = max(0.05,max(magic_num,log(approx_vol)*0.012));
%     D_theta = 0.002;
    % sample etas
    max_iter = 1e5;
    if recursive_sampling
        etas = UniformSQAngleSampling( 0, [], 1, 1, a3, a4, tor, e1, 0, D_theta );
    else
        thetas = zeros(1,10^4);
        theta_increasing = 1;
        ix_eta = 1;
        while (thetas(ix_eta) > -eps(1))
            if ix_eta > max_iter
                disp(['Angle eta sampling reach the maximum number of iterations ' num2str(max_iter)]);
                error(num2str(SQ));
            end
            % if theta got close enough to pi/2 start decreasing it down to 0        
            if (thetas(ix_eta)  > pi/2 - eps(1))
              thetas(ix_eta)  = max(pi/2 - thetas(ix_eta) , 0);
              theta_increasing = -1;
            end             
            % update angle
            thetas(ix_eta+1) = thetas(ix_eta) + theta_increasing*UpdateTheta(1, a3, a4, tor, e1, thetas(ix_eta), D_theta);    
            ix_eta = ix_eta +1;
        end
        etas = thetas(1:ix_eta-1);        
    end    
    % sample omegas
    if recursive_sampling
        omegas = UniformSQAngleSampling( 0, [], 1, a1, a2, a4, tor, e2, 0, D_theta ); 
    else
        thetas = zeros(1,10^4);
        theta_increasing = 1;
        ix_omega = 1;
        while (thetas(ix_omega) > -eps(1))
            if ix_omega > max_iter
                disp(['Angle eta sampling reach the maximum number of iterations ' num2str(max_iter)]);
                error(num2str(SQ));
            end
            % if theta got close enough to pi/2 start decreasing it down to 0        
            if (thetas(ix_omega)  > pi/2 - eps(1))
              thetas(ix_omega)  = max(pi/2 - thetas(ix_omega) , 0);
              theta_increasing = -1;
            end             
            % update angle
            thetas(ix_omega+1) = thetas(ix_omega) + theta_increasing*UpdateTheta(a1, a2, a4, tor, e2, thetas(ix_omega), D_theta);    
            ix_omega = ix_omega +1;
        end
        omegas = thetas(1:ix_omega-1); 
    end    
    
    % get size of sampled angles as variable for effiency
    n_sampled_angles = size(etas,2) * size(omegas,2);  
    
    % downsample the angles in order to preserve memory
    while n_sampled_angles > 1e6
        ixs_etas = randsample(1:size(etas,2),round(.8*size(etas,2)));
        etas = etas(ixs_etas);
        ixs_omegas = randsample(1:size(omegas,2),round(.8*size(omegas,2)));
        omegas = omegas(ixs_omegas);
        n_sampled_angles = size(etas,2) * size(omegas,2); 
    end
    % initialize final pcl
    final_pcl = zeros((n_sampled_angles)*8,3);
    % initialize normals
    if calc_normals
        final_normals = zeros(size(final_pcl));
    end
    % perform permutation of signs in order to rotate the sampled points and get the whole pcl
    ix=0;
    for i=-1:2:1
        for j=-1:2:1
            for k=-1:2:1
                cos_j_omegas = cos(j*omegas);
                sin_j_omegas = sin(j*omegas);
                x = a1.*i*signedpow(cos_j_omegas,e2)'*(a4+signedpow(cos(k*etas),e1));
                y = a2.*i*signedpow(sin_j_omegas,e2)'*(a4+signedpow(cos(k*etas),e1));
                sin_k_etas = sin(k*etas);
                ones_size_omegas = ones(size(omegas,2),1);
                z = a3.*ones_size_omegas*i*signedpow(sin_k_etas,e1); 
                pcl = [x(:) y(:) z(:)];
                if calc_normals                    
                    x_y_norm_factor = signedpow(cos(etas),2);
                    x_normals = signedpow(cos(omegas),2)'*x_y_norm_factor;
                    x_normals = (1./pcl(:,1)).*x_normals(:);
                    y_normals = signedpow(sin(omegas),2)'*x_y_norm_factor;
                    y_normals = (1./pcl(:,2)).*y_normals(:);
                    z_normals = ones_size_omegas*signedpow(sin(etas),2);
                    z_normals = (1./pcl(:,3)).*z_normals(:); 
                    normals = [x_normals(:) y_normals(:) z_normals(:)];
                    normals = normr(normals);
                end
                % apply tapering
                if Kx || Ky
                    f_x_ofz = ((Kx.*pcl(:,3))/a3) + 1; 
                    pcl(:,1) = pcl(:,1).*f_x_ofz;
                    f_y_ofz = ((Ky.*pcl(:,3))/a3) + 1;
                    pcl(:,2) = pcl(:,2).*f_y_ofz; 
                end
                % apply bending
                if k_bend
                    pcl(:,1) = pcl(:,1) + (k_bend - sqrt(k_bend^2 - pcl(:,3).^2));
                end
                % get current pcl into final_pcl
                final_pcl((ix*n_sampled_angles)+1:((ix+1)*n_sampled_angles),:) = pcl;
                % calculate normals
                if calc_normals           
                    % apply tapering transformation to the normals
                    if Kx || Ky
                        f_prime_x_ofz = (Kx/a3).*x(:);
                        f_prime_y_ofz = (Ky/a3).*y(:);
                        z_x_taper_factor = -f_prime_x_ofz.*f_y_ofz;
                        z_y_taper_factor = -f_prime_y_ofz.*f_x_ofz;
                        normals_x = normals(:,1).*f_y_ofz;
                        normals_y = normals(:,2).*f_x_ofz;
                        normals_z = z_x_taper_factor.*normals(:,1) + z_y_taper_factor.*normals(:,2) + f_x_ofz.*f_y_ofz.*normals(:,3);
                        normals = [normals_x normals_y normals_z];
                    end
                    % apply bending transformation to the normals
                    if k_bend
                        bend_j = -(pcl(:,3)./sqrt(k_bend^2 - pcl(:,3).^2));
                        normals(:,3) = normals(:,3) + bend_j.*normals(:,1);
                    end
                    final_normals((ix*n_sampled_angles)+1:((ix+1)*n_sampled_angles),:) = normr(normals);
                end
                ix=ix+1;
            end
        end
    end
    if rescaling_happened
        for i=1:3
            final_pcl(:,i) = final_pcl(:,i)/(0.5*rescaling_factor);
        end       
    end
    % downsample if required
    if downsample
        ixs = randsample(1:size(final_pcl,1),min(downsample,size(final_pcl,1)));
        final_pcl = final_pcl(ixs,:);
        if calc_normals
            final_normals = final_normals(ixs,:);
        end        
    end
    % translate and rotate
    R = eul2rotm_([eul1 eul2 eul3],'ZYZ');
    T = [R [x_c y_c z_c]';0 0 0 1];
    final_pcl = [final_pcl ones(size(final_pcl,1),1)];
    final_pcl = T*final_pcl';
    final_pcl = final_pcl(1:3,:)';
    % plot if required
    if plot
        scatter3(final_pcl(:,1),final_pcl(:,2),final_pcl(:,3),'.k'); axis equal
        % plot dual superquadric
        % figure; scatter3(final_normals(:,1),final_normals(:,2),final_normals(:,3)); axis equal
    end  
end
% By Paulo Abelha (p.abelha at abdn ac uk )
% based on [PiluFisher95] Pilu, Maurizio, and Robert B. Fisher. �Equal-distance sampling of superellipse models.� DAI RESEARCH PAPER (1995)
% 
% Recursive implementation of the angle sampling equation
% Iterations will stop in case of too many calls (wrong parametrization may lead to infinite regression).
function [ thetas, theta_increasing, safe_rec ] = UniformSQAngleSampling( safe_rec, thetas, theta_increasing, a, b, a4, tor, epsilon, theta, D_  )
    if safe_rec > 10^5;
        error('Recursion went too deep for sampling angles (> 10^5).');
    end
    if (theta <= -eps(1))
        return;
    else
        % if theta got close enough to pi/2 start decreasing it down to 0        
        if (theta > pi/2 - eps(1))
          theta = max(pi/2 - theta, 0);
          theta_increasing = -1;
        end             
        % update angle
        thetas(end+1) = theta + theta_increasing*UpdateTheta(a, b, a4, tor, epsilon, theta, D_);
        % assign to array of sampled angles
        [ thetas, theta_increasing, safe_rec ] = UniformSQAngleSampling( safe_rec+1, thetas, theta_increasing, a, b, a4, tor, epsilon, thetas(end), D_ );     
    end  
end


%% Calculates the MOI by fitting SQs to the pcl
% If SQs is a path or a struct it will be considered a pcl path or P struct
%   and the function will fit SQs to the this pcl
% If SQs is a cell array it will be considered as a list of SQs
%
% The outputs are:
%   centre of mass
%   The I inertial matrix)
%   inertial (6x1 array) holding both centre of mass and inertia diagonal
%   the read pcl P is SQs was a path to a pcl file or a P struct 
%
% Currently this is a very crude approximation sicne it does not consider
% bending, tpaering nor superparaboloids. In the future I hope I have time 
% to add these :(
%
% Thanks to Benjamin Nougier who contribute to the code
%% By Paulo Abelha
function [ I, centre_mass, total_volume, SQs, vol_SQs, masses ] = CalcCompositeMomentInertia(Param1, masses, flag_density)
    %% try to parse masses as strings
    if exist('masses','var') && ischar(masses)            
        % try to parse target object contact point
        masses_split = strsplit(masses,' ');
        if numel(masses_split) == 1
            masses = str2double(masses);
        else
            masses = zeros(1,numel(masses_split));
            for i=1:numel(masses_split)
                masses(i) = str2double(masses_split{i});
            end
        end
    end    
    %% deal with density flag
    if exist('flag_density','var') && ischar(flag_density)
        flag_density_num = str2double(flag_density);
        if flag_density_num ~= 0 || flag_density_num ~= 1
            error(['Flag density must be either 0 or 1; got ''' flag_density ''' instead']);
        end
        flag_density = flag_density_num;
    end
    %% deal with first argument being a PCL
    try
        CheckIsPointCloudStruct(Param1);
        SQs = PCL2SQ(Param1);
    catch 
        if ischar(Param1)
            P = ReadPointCloud(Param1);
            SQs = PCL2SQ(P);
        else
            %% deal with SQs param
            SQs = Param1;
            % deal with when param is a single SQ
            if ~iscell(SQs) && size(SQs,1) == 1
                SQs = {SQs};
            end
        end
    end
    %% deal with density flag
    if ~exist('flag_density','var')
        flag_density = 0;
    end
    %% calcualte volume of SQs
    vol_SQs = zeros(1,numel(SQs));
    for i=1:numel(SQs)
        vol_SQs(i) = VolumeSQ(SQs{i});
    end
    %% deal with a possible list of masses
    if ~exist('masses','var')
        warning('No mass provided. Assuming density of water: 1000 kg / m^3');
        flag_density = 1;
        masses = zeros(1,numel(SQs));
        for i=1:numel(SQs)
            masses(i) = vol_SQs(i)*1e3;
        end    
    end 
    if numel(masses) ~= numel(SQs)
        error('List of masses must have same elements as number of segments in point cloud or superquadrics given'); 
    end
    %% get centre of mass
    centre_mass = CentreOfMass( SQs );
    %% start MOI calculation
    %% calculate the individual moments of inertia for each SQ
    Iparts = zeros(numel(SQs),3,3);
    for i=1:numel(SQs)
        if flag_density
            density = masses(i);
        else
            density = masses(i)/vol_SQs(i);
        end
        Iparts(i,:,:) = MomentInertiaSQ(SQs{i})*density;
    end    
    %% Get projection distances of SQs centers on axis passing by center of mass
    d = zeros(size(SQs,2),3);
    for i=1:numel(SQs) % == length(SQs)
        SQ_center_coord = SQs{i}(end-2:end);
        for proj_axis=1:3 
            % ( if 1 = "x axis" for example, then 2 = y axis, and 3 = z axis)
            % To get the distance to the axis, we use Pythagoras theorem. 
            % This distance is then given by : (on x axis for example)
            %
            % dist_to_x_axis_passing_by_centerOfMass = sqrt(SQ_coord(y)^2+SQ_coord(z)^2)
            % 
            % In order to be generic, we use the modulo to get the next
            % axis id (1, 2 or 3). for example, if axis_1 has the value 2,
            % next axis (axis_2) will get 3 and the last one will get 1.
            % Since the modulo 3 gives us 0,1 or 2, we first apply the
            % modulo then add 1 to the resulting id.
            axis_1 = proj_axis;
            axis_2 = mod(axis_1,3)+1;
            axis_3 = mod(axis_1+1,3)+1;
            d(i, axis_1) = sqrt( (SQ_center_coord(axis_2)^2) + (SQ_center_coord(axis_3)^2) );
        end
    end
    %% Get total volume
    total_volume = 0;
    for  i=1:numel(SQs)
        total_volume = total_volume + vol_SQs(i);
    end
    %% Get MOI
    % For each axis, sum moment of inertia of each SQ projected on this axis
    I=zeros(3,3);
    %% Get MOI
    % For each axis, sum moment of inertia of each SQ projected on this axis
    I=zeros(3,3);
    for proj_axis1=1:3
        for proj_axis2=1:3
            sum=0; 
            for i=1:numel(SQs)          
                SQ_volume = vol_SQs(i);
                SQ_vol_contribution = (SQ_volume/total_volume);
                sum=sum+Iparts(i,proj_axis1,proj_axis2)+(SQ_vol_contribution*(d(i,proj_axis1)^2));
            end
            I(proj_axis1,proj_axis2) = sum;
        end
    end 
    disp('begin_inertia_info');
    disp('# moment of inertia in M * L^2');
    disp('inertia')
    disp(I);
    disp('centre_mass');
    disp(centre_mass);
    disp('tot_vol');
    disp(total_volume);
    disp('vol_per_sq');
    str_ = '';
    for i=1:numel(SQs)        
        str_ = [str_ num2str(vol_SQs(i)) ' '];
    end
    disp(str_);
    disp('sqs');
    for i=1:numel(SQs)
        disp(SQs{i});
    end
    disp('masses');
    disp(masses);
    disp('end_inertia_info');
end
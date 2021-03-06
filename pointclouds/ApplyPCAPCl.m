function [ P, pcl_pca ] = ApplyPCAPCl( P, pcl_pca )
    CheckIsPointCloudStruct(P);
    if ~exist('pcl_pca','var')
        pcl_pca = pca(P.v);
    end
    P.v = P.v - repmat(mean(P.v),size(P.v,1),1);
    P.v = P.v*pcl_pca;
    if ~isempty(P.n)
        P.n = P.n*pcl_pca;
    end
    for i=1:size(P.segms,2)
        P.segms{i}.v = P.segms{i}.v - repmat(mean(P.segms{i}.v),size(P.segms{i}.v,1),1);
        P.segms{i}.v = P.segms{i}.v*pcl_pca;
        if isfield(P.segms{i},'n') && ~isempty(P.segms{i}.n)
            P.segms{i}.n = P.segms{i}.n*pcl_pca;
        end
    end
end


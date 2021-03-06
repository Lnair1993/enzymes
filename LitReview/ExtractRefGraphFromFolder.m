function [ ref_titles, all_ref_titles, set_all_ref_titles, citation_count ] = ExtractRefGraphFromFolder( root_folder )
    papers = FindAllFilesOfType( {'pdf'}, root_folder );
    ref_titles = cell(1,numel(papers));
    tot_toc = 0;
    for i=1:numel(papers)
        tic;
        try
            [ref_title, ref_strs] = ExtractTitleAndReferences( root_folder, papers{i} );
            if isempty(ref_title)
                warning('Ref title is empty');
                ref_titles{i} = ref_strs;
            else
                ref_titles{i} = ref_title;
            end
        catch
           warning(['Error reading file: ' root_folder papers{i}]); 
        end
        tot_toc = DisplayEstimatedTimeOfLoop(tot_toc+toc,i,numel(papers));
    end
    all_ref_titles = {};
    for i=1:numel(ref_titles)
        for j=1:numel(ref_titles{i})
            all_ref_titles{end+1} = ref_titles{i}{j};
        end
    end
    set_all_ref_titles = {};
    citation_count = [];
    if isempty(all_ref_titles)
        warning('No proper references found');
    else
        set_all_ref_titles{1} = all_ref_titles{1};
        for i=2:numel(all_ref_titles)
            title_proc = lower(all_ref_titles{i});
            title_proc = replace(title_proc,' ','');
            found_title = 0;
            for j=1:numel(set_all_ref_titles)
                set_title_proc = lower(set_all_ref_titles{j});
                set_title_proc = replace(set_title_proc,' ','');
                if strcmp(title_proc,set_title_proc)
                    found_title = 1;
                    break;
                end
            end
            if ~found_title
                set_all_ref_titles{end+1} = all_ref_titles{i};
            end
        end
        citation_count = zeros(1,numel(set_all_ref_titles));
        for i=1:numel(all_ref_titles)
            title_proc = lower(all_ref_titles{i});
            title_proc = replace(title_proc,' ','');
            for j=1:numel(set_all_ref_titles)
                set_title_proc = lower(set_all_ref_titles{j});
                set_title_proc = replace(set_title_proc,' ','');
                if strcmp(title_proc,set_title_proc)
                    citation_count(j) = citation_count(j) + 1;
                    break;
                end
            end
        end
    end
end


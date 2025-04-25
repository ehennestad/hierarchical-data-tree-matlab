function demo_dataTreeViewer(filePath)
% demo_dataTreeViewer - Demonstrate the FileContentTree component
%
%   This function creates a simple application that demonstrates the
%   FileContentTree component. It allows users to open different file types
%   and browse their contents.
%
%   Usage:
%       demo_dataTreeViewer()
%
%   See also FileContentTree, ContentAdapter, TreeNodeProvider

    % Create figure

    arguments
        filePath (1,1) string {mustBeFile}
    end

    f = uifigure('Name', 'File Content Tree Demo', 'Position', [100 100 800 600]);
    
    % Create layout
    mainGrid = uigridlayout(f, [1 2]);
    mainGrid.RowHeight = {25, '1x'};
    mainGrid.ColumnWidth = {'1x', '2x'};

    % Create preview text area
    treeLabel = uilabel(mainGrid);
    treeLabel.Layout.Row = 1;
    treeLabel.Layout.Column = 1;
    treeLabel.FontWeight = 'bold';
    treeLabel.Text = 'File content tree:';
    
    % Create preview text area
    previewLabel = uilabel(mainGrid);
    previewLabel.Layout.Row = 1;
    previewLabel.Layout.Column = 2;
    previewLabel.FontWeight = 'bold';
    previewLabel.Text = 'Data preview:';

    % Create tree panel
    glTree = uigridlayout(mainGrid, [1 1]);
    glTree.Layout.Row = 2;
    glTree.Layout.Column = 1;
    glTree.Padding = 0;

    % Create file content tree
    tree = datatree.ui.FileContentTree(glTree, ...
        'AllowMultipleSelection', false, ...
        'FilePath', filePath, ...
        'ExpandAllOnCreation', "on");

    % Create preview text area
    previewText = uitextarea(mainGrid);
    previewText.Layout.Row = 2;
    previewText.Layout.Column = 2;
    previewText.Value = 'Select a node to preview its contents';

    % Create toolbar
    tb = uitoolbar(f);
    
    % Add open button
    openButton = uipushtool(tb, 'Icon', fullfile(matlabroot, 'toolbox', 'matlab', 'icons', 'file_open.png'));
    openButton.Tooltip = 'Open File';
    openButton.ClickedCallback = @(src, event) openFile();
    
    % Add open directory button
    openDirButton = uipushtool(tb, 'Icon', fullfile(matlabroot, 'toolbox', 'matlab', 'icons', 'foldericon.gif'));
    openDirButton.Tooltip = 'Open Directory';
    openDirButton.ClickedCallback = @(src, event) openDirectory();
       
    % Set selection callback
    tree.NodeSelectionChangedFcn = @(src, event) previewNode(event.SelectedNodes);
    
    % Open file callback
    function openFile()
        % Get supported extensions
        extensions = datatree.utility.ContentAdapterFactory.getSupportedExtensions();
        extensions(strcmp(extensions, 'folder')) = [];
        
        % Create filter spec for uigetfile
        filterSpec = cell(numel(extensions), 2);
        for i = 1:length(extensions)
            ext = extensions{i};
    
            filterSpec{i, 1} = ['*' ext];
            filterSpec{i, 2} = ['*' ext ' files'];
        end
        
        % Add all files option
        filterSpec{end+1} = '*.*';
        filterSpec{end+1} = 'All files';
        
        filterSpec = reshape(filterSpec, 2, [])';
    
        % Show file dialog
        [fileName, filePath] = uigetfile(filterSpec, 'Select a file');
        
        % Check if user cancelled
        if isequal(fileName, 0)
            return;
        end
        
        % Create full file path
        fullPath = fullfile(filePath, fileName);
        
        % Create adapter
        try
            adapter = datatree.utility.ContentAdapterFactory.createAdapter(fullPath);
            tree.loadFile(fullPath, adapter);
            
            % Update preview
            previewText.Value = sprintf('Opened file: %s\n\nSelect a node to preview its contents', fullPath);
        catch ME
            % Show error message
            errordlg(['Error opening file: ' ME.message], 'File Open Error');
        end
    end
    
    % Open directory callback
    function openDirectory()
        % Show directory dialog
        dirPath = uigetdir('', 'Select a directory');
        
        % Check if user cancelled
        if isequal(dirPath, 0)
            return;
        end
        
        % Create adapter
        try
            adapter = datatree.FileSystemAdapter();
            tree.loadFile(dirPath, adapter);
            
            % Update preview
            previewText.Value = sprintf('Opened directory: %s\n\nSelect a node to preview its contents', dirPath);
        catch ME
            % Show error message
            errordlg(['Error opening directory: ' ME.message], 'Directory Open Error');
        end
    end
    
    % Preview node callback
    function previewNode(nodes)
        if isempty(nodes)
            previewText.Value = 'No node selected';
            return;
        end
        
        % Get first selected node
        if isa(nodes, 'cell')
            node = nodes{1};
        else
            node = nodes;
        end
        
        assert(isa(node, 'struct'), ...
            'DATATREE:DemoPreview:NodeMustBeStruct', ...
            'Expected node to be a structure.')
        
        % Get node data
        data = tree.Model.getNodeData(node);
        
        % Preview based on data type
        if isstruct(data)
            % Show structure fields
            fields = fieldnames(data);
            preview = sprintf('Node: %s\nType: %s\nPath: %s\n\nStructure with %d fields:\n\n', ...
                node.Name, node.Type, node.Path, length(fields));

            numPreviews = min(length(fields), 20);

            for i = 1:numPreviews
                fieldValue = data.(fields{i});
                if ischar(fieldValue) && numel(fieldValue) < 50
                    fieldPreview = [fields{i}, ': ', fieldValue, '\n'];
                elseif isnumeric(fieldValue) && isscalar(fieldValue)
                    fieldPreview = [fields{i}, ': ', num2str(fieldValue), '\n'];
                else
                    fieldPreview = [fields{i}, ': [', class(fieldValue), ']\n'];
                end
                preview = [preview, fieldPreview]; %#ok<AGROW>
            end
            if length(fields) > 20
                preview = [preview, '...\n'];
            end
        elseif iscell(data)
            % Show cell array info
            preview = sprintf('Node: %s\nType: %s\nPath: %s\n\nCell array of size %s\n', ...
                node.Name, node.Type, node.Path, mat2str(size(data)));
            
            % Show cell contents for small cell arrays
            if numel(data) <= 10
                preview = [preview, '\nContents:\n'];
                for i = 1:numel(data)
                    cellValue = data{i};
                    if ischar(cellValue) && numel(cellValue) < 50
                        fieldPreview = [sprintf('Cell {%d}: %s\n', i, cellValue)];
                    elseif isnumeric(cellValue) && isscalar(cellValue)
                        fieldPreview = [sprintf('Cell {%d}: %g\n', i, cellValue)];
                    else
                        fieldPreview = [sprintf('Cell {%d}: [%s]\n', i, class(cellValue))];
                    end
                    preview = [preview, fieldPreview]; %#ok<AGROW>
                end
            end
        elseif isnumeric(data)
            % Show numeric array info
            preview = sprintf('Node: %s\nType: %s\nPath: %s\n\nNumeric array (%s) of size %s\n', ...
                node.Name, node.Type, node.Path, class(data), mat2str(size(data)));
            
            % Show small arrays
            if numel(data) <= 100
                preview = [preview, '\n', mat2str(data)];
            end
        elseif ischar(data)
            % Show text
            preview = sprintf('Node: %s\nType: %s\nPath: %s\n\nCharacter array:\n\n%s', ...
                node.Name, node.Type, node.Path, data);
        else
            % Generic preview
            preview = sprintf('Node: %s\nType: %s\nPath: %s\n\nData of type %s\n', ...
                node.Name, node.Type, node.Path, class(data));
        end


        
        previewText.Value = sprintf(preview);
    end
end

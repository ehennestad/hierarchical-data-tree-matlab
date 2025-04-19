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
    f = uifigure('Name', 'File Content Tree Demo', 'Position', [100 100 800 600]);
    
    % Create layout
    gl = uigridlayout(f, [1 2]);
    gl.ColumnWidth = {'1x', '2x'};
    
    % Create tree panel
    % treePanel = uipanel(gl);
    % treePanel.Layout.Column = 1;
    
    % Create preview panel
    previewPanel = uipanel(gl);
    previewPanel.Layout.Column = 2;
    
    % Create preview text area
    previewText = uitextarea(previewPanel);
    previewText.Position = [10 10 previewPanel.Position(3)-20 previewPanel.Position(4)-20];
    previewText.Value = 'Select a node to preview its contents';
    
    glTree = uigridlayout(gl, [1 1]);
    glTree.Layout.Row = 1;
    glTree.Layout.Column = 1;


    % Create file content tree
    tree = datatree.ui.FileContentTree(glTree, ...
        'AllowMultipleSelection', false, ...
        'FilePath', filePath, ...
        'ExpandAllOnCreation', "on");
    keyboard

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
    
    % Open file callback
    function openFile()
        % Get supported extensions
        extensions = datatree.utility.ContentAdapterFactory.getSupportedExtensions();
        
        % Create filter spec for uigetfile
        filterSpec = cell(0,2);
        for i = 1:length(extensions)
            ext = extensions{i};
            if strcmp(ext, 'folder')
                continue; % Skip folder for file dialog
            end
            filterSpec{end+1} = ['*' ext];
            filterSpec{end+1} = ['*' ext ' files'];
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
    
    % Set selection callback
    tree.NodeSelectionChangedFcn = @(src, event) previewNode(event.SelectedNodes);
    
    % Preview node callback
    function previewNode(nodes)
        if isempty(nodes)
            previewText.Value = 'No node selected';
            return;
        end
        
        % Get first selected node
        node = nodes{1};
        
        % Get node data
        data = tree.Model.getNodeData(node);
        
        % Preview based on data type
        if isstruct(data)
            % Show structure fields
            fields = fieldnames(data);
            preview = sprintf('Node: %s\nType: %s\nPath: %s\n\nStructure with %d fields:\n\n', ...
                node.Name, node.Type, node.Path, length(fields));
            for i = 1:min(length(fields), 20)
                fieldValue = data.(fields{i});
                if ischar(fieldValue) && numel(fieldValue) < 50
                    preview = [preview, fields{i}, ': ', fieldValue, '\n'];
                elseif isnumeric(fieldValue) && isscalar(fieldValue)
                    preview = [preview, fields{i}, ': ', num2str(fieldValue), '\n'];
                else
                    preview = [preview, fields{i}, ': [', class(fieldValue), ']\n'];
                end
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
                        preview = [preview, sprintf('Cell {%d}: %s\n', i, cellValue)];
                    elseif isnumeric(cellValue) && isscalar(cellValue)
                        preview = [preview, sprintf('Cell {%d}: %g\n', i, cellValue)];
                    else
                        preview = [preview, sprintf('Cell {%d}: [%s]\n', i, class(cellValue))];
                    end
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
        
        previewText.Value = preview;
    end
end

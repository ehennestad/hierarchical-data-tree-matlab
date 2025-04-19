%% Test Script for FileContentTree
% This script demonstrates how to use the FileContentTree component
% with different file types.

%% Create a test MAT file
% First, let's create a test MAT file with some nested structures

% Create a struct with nested fields
testStruct = struct();
testStruct.name = 'Test Structure';
testStruct.value = 42;
testStruct.array = rand(10, 10);
testStruct.nested = struct('a', 1, 'b', 'text', 'c', {{'cell1', 'cell2'}});

% Create a cell array
testCell = {'string', 123, rand(5), struct('x', 1, 'y', 2)};

% Create a numeric array
testArray = rand(100, 100);

% Save to MAT file
testMatFile = fullfile(tempdir, 'test_file_content_tree.mat');
save(testMatFile, 'testStruct', 'testCell', 'testArray');

fprintf('Created test MAT file: %s\n', testMatFile);

%% Test with MAT file
% Now let's create a FileContentTree to view the MAT file

% Create a figure
f1 = uifigure('Name', 'MAT File Test', 'Position', [100 100 800 600]);

% Create a panel for the tree
treePanel = uipanel(f1, 'Units', 'normalized', 'Position', [0 0 1 1]);

% Create the FileContentTree
matTree = datatree.ui.FileContentTree(treePanel);

% Load the MAT file
matTree.loadFile(testMatFile);

% Set selection callback
matTree.NodeSelectionChangedFcn = @(src, event) displayNodeInfo(event.SelectedNodes, 'MAT');

%% Test with file system
% Now let's create a FileContentTree to view a directory

% Create a figure
f2 = uifigure('Name', 'File System Test', 'Position', [200 200 800 600]);

% Create a panel for the tree
treePanel = uipanel(f2, 'Units', 'normalized', 'Position', [0 0 1 1]);

% Create the FileContentTree
fsTree = datatree.ui.FileContentTree(treePanel);

% Load a directory (using the current directory)
fsTree.loadFile(pwd);

% Set selection callback
fsTree.NodeSelectionChangedFcn = @(src, event) displayNodeInfo(event.SelectedNodes, 'FS');

%% Callback function to display node info
function displayNodeInfo(nodes, source)
    if isempty(nodes)
        return;
    end
    
    % Get the first selected node
    node = nodes(1);
    
    % Display node info
    fprintf('\n--- %s Node Selected ---\n', source);
    fprintf('Name: %s\n', node.Name);
    fprintf('Path: %s\n', node.Path);
    fprintf('Type: %s\n', node.Type);
    
    % Display data info based on type
    data = node.Data;
    if isstruct(data)
        fprintf('Data: Structure with %d fields\n', length(fieldnames(data)));
    elseif iscell(data)
        fprintf('Data: Cell array of size %s\n', mat2str(size(data)));
    elseif isnumeric(data)
        fprintf('Data: Numeric array (%s) of size %s\n', class(data), mat2str(size(data)));
    elseif ischar(data)
        if length(data) > 50
            fprintf('Data: Character array of length %d\n', length(data));
        else
            fprintf('Data: "%s"\n', data);
        end
    else
        fprintf('Data: %s\n', class(data));
    end
end

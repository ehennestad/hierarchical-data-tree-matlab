# File Content Viewer Framework

This package provides a general framework for displaying the contents of files that contain multiple nested items, such as MAT files, HDF5 files, and file system directories.

## Overview

The framework is designed with the following principles:

1. **Modularity**: The tree component can be easily embedded in different viewers
2. **Separation of Concerns**: UI, data model, and file access are cleanly separated
3. **Extensibility**: New file types can be supported by adding new adapters
4. **Reusability**: The same component can be used for different file types
5. **Customizability**: Callbacks allow parent components to respond to user interactions

## Architecture

The framework consists of the following components:

- **ContentAdapter**: Interface for adapters that read nested content from files
- **ContentTreeModel**: Model for tree-based content representation
- **FileContentTree**: Tree component for browsing nested file contents
- **MatFileAdapter**: Adapter for MAT files
- **Hdf5FileAdapter**: Adapter for HDF5 files
- **FileSystemAdapter**: Adapter for file system directories
- **ContentAdapterFactory**: Factory for creating adapters based on file type

## Usage

### Basic Usage

```matlab
% Create a file content tree for a MAT file
parent = uifigure;
tree = nansen.ui.fileviewer.FileContentTree(parent);
tree.loadFile('data.mat');

% Set selection callback
tree.NodeSelectionChangedFcn = @(src, event) disp(['Selected: ' event.SelectedNodes{1}.Name]);
```

### Using in a Custom Viewer

```matlab
classdef MyFileViewer < handle
    properties
        Figure
        ContentTree
        PreviewPanel
    end
    
    methods
        function obj = MyFileViewer(filePath)
            % Create UI
            obj.Figure = uifigure('Name', 'File Viewer');
            
            % Create layout
            gl = uigridlayout(obj.Figure, [1 2]);
            gl.ColumnWidth = {'1x', '2x'};
            
            % Create tree panel
            treePanel = uipanel(gl);
            treePanel.Layout.Column = 1;
            
            % Create preview panel
            obj.PreviewPanel = uipanel(gl);
            obj.PreviewPanel.Layout.Column = 2;
            
            % Create content tree
            adapter = nansen.ui.fileviewer.ContentAdapterFactory.createAdapter(filePath);
            obj.ContentTree = nansen.ui.fileviewer.FileContentTree(treePanel, 'Adapter', adapter, ...
                'FilePath', filePath, 'AllowMultipleSelection', false);
            
            % Set callbacks
            obj.ContentTree.NodeSelectionChangedFcn = @(src, event) obj.onNodeSelected(src, event);
        end
        
        function onNodeSelected(obj, ~, event)
            % Handle node selection
            if ~isempty(event.SelectedNodes)
                node = event.SelectedNodes{1};
                obj.displayNodeContent(node);
            end
        end
        
        function displayNodeContent(obj, node)
            % Display node content in preview panel
            % Implementation depends on node type and data
            % ...
        end
    end
end
```

### Running the Demo

To see the framework in action, run the included demo:

```matlab
demo_dataTreeViewer()
```

## Extending the Framework

### Adding Support for a New File Type

To add support for a new file type, create a new adapter class that implements the ContentAdapter interface:

```matlab
classdef MyNewAdapter < nansen.ui.fileviewer.ContentAdapter
    % Implement required methods:
    %   - open
    %   - getRoot
    %   - getChildren
    %   - hasChildren
    %   - getNodeData
    %   - close
end
```

Then register the adapter in the ContentAdapterFactory:

```matlab
% In ContentAdapterFactory.createAdapter:
switch lower(ext)
    case '.mat'
        adapter = nansen.ui.fileviewer.MatFileAdapter();
    case {'.h5', '.hdf5', '.nwb'}
        adapter = nansen.ui.fileviewer.Hdf5FileAdapter();
    case '.mynewext'
        adapter = nansen.ui.fileviewer.MyNewAdapter();
    otherwise
        error('ContentAdapterFactory:UnsupportedFileType', ...
            'Unsupported file type: %s', ext);
end
```

## Node Structure

Each node in the tree has a consistent structure:

```matlab
% Node structure
node = struct(...
    'Name', '',     % Display name
    'Path', '',     % Path or identifier within the file
    'Type', '',     % Type identifier (e.g., 'directory', 'file', 'group', 'dataset', 'struct', 'cell')
    'Data', []      % The actual data or reference to it
);
```

## Callbacks

The FileContentTree component provides the following callbacks:

- **NodeSelectionChangedFcn**: Called when the selection changes
- **NodeExpandedFcn**: Called when a node is expanded
- **NodeCollapsedFcn**: Called when a node is collapsed

## Properties

The FileContentTree component has the following properties:

- **AllowMultipleSelection**: Whether to allow multiple selection
- **ShowIcons**: Whether to show icons for nodes

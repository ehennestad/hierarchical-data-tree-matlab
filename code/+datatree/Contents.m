% FILEVIEWER - Framework for displaying nested file contents
%
% The hierarchical data tree package provides a general framework for 
% displaying the contents of data structures that contain multiple nested 
% items, such as MAT files, HDF5 files, and file system directories.
%
% Core Classes:
%   datatree.adapter.ContentAdapter         - Interface for adapters that read nested content from files
%   datatree.model.TreeNodeProvider         - Model for tree-based content representation
%   datatree.ui.FileContentTree             - Tree component for browsing nested file contents
%   ContentAdapterFactory  - Factory for creating adapters based on file type
%
% File Adapters:
%   datatree.adapter.MatFileAdapter         - Adapter for MAT files
%   datatree.adapter.Hdf5FileAdapter        - Adapter for HDF5 files
%   datatree.adapter.FileSystemAdapter      - Adapter for file system directories
%
% Examples and Documentation:
%   demo_dataTreeViewer    - Demonstrate the FileContentTree component
%   test_FileContentTree   - Test script for FileContentTree
%   README                 - Package documentation
%
% Example:
%   % Create a file content tree for a MAT file
%   parent = uifigure;
%   tree = datatree.ui.FileContentTree(parent);
%   tree.loadFile('data.mat');
%
%   % Set selection callback
%   tree.NodeSelectionChangedFcn = @(src, event) disp(['Selected: ' event.SelectedNodes{1}.Name]);
%
%   % Run the demo
%   demo_dataTreeViewer()
%
% See also: datatree.ui.FileContentTree, datatree.adapter.ContentAdapter

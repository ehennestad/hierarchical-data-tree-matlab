classdef Hdf5FileAdapter < datatree.adapter.ContentAdapter
    % Hdf5FileAdapter - Adapter for HDF5 files
    %
    %   This class implements the ContentAdapter interface for HDF5 files.
    %   It provides methods to browse the contents of an HDF5 file as a tree.
    %
    %   Example:
    %       adapter = Hdf5FileAdapter();
    %       adapter.open('data.h5');
    %       rootNodes = adapter.getRoot();
    %
    %   See also ContentAdapter, FileContentTree
    
    properties
        FilePath % Path to the HDF5 file
        FileInfo % HDF5 file info structure
    end
    
    methods
        function obj = Hdf5FileAdapter(filePath)
            % Constructor
            obj.FilePath = filePath;
        end
        
        function open(obj, filePath)
            % Open an HDF5 file
            % filePath: Path to the HDF5 file
            
            obj.FilePath = filePath;
            try
                % Get file info
                obj.FileInfo = h5info(filePath);
            catch ME
                error('Hdf5FileAdapter:OpenError', 'Error opening HDF5 file: %s', ME.message);
            end
        end
        
        function nodes = getRoot(obj)
            % Get root nodes (top-level groups and datasets in the HDF5 file)
            
            if isempty(obj.FileInfo)
                nodes = {};
                return;
            end
            
            % Create root node
            rootNode = struct(...
                'Name', '/', ...
                'Path', '/', ...
                'Type', 'group', ...
                'Info', obj.FileInfo ...
            );
            
            nodes = {rootNode};
        end
        
        function nodes = getChildren(~, node)
            % Get children of a node
            % node: Parent node
            
            if ~strcmp(node.Type, 'group')
                % Only groups have children
                nodes = {};
                return;
            end
            
            % Get group info
            info = node.Info;
            
            % Count children (groups and datasets)
            numGroups = length(info.Groups);
            numDatasets = length(info.Datasets);
            numAttributes = length(info.Attributes);
            
            % Create nodes array
            nodes = cell(numGroups + numDatasets + numAttributes, 1);
            nodeIdx = 1;
            
            % Add groups
            for i = 1:numGroups
                group = info.Groups(i);
                [~, name] = fileparts(group.Name);
                if isempty(name)
                    % Handle root group
                    name = group.Name;
                end
                
                nodes{nodeIdx} = struct(...
                    'Name', name, ...
                    'Path', group.Name, ...
                    'Type', 'group', ...
                    'Info', group ...
                );
                nodeIdx = nodeIdx + 1;
            end
            
            % Add datasets
            for i = 1:numDatasets
                dataset = info.Datasets(i);
                [~, name] = fileparts(dataset.Name);
                
                % Create node
                nodes{nodeIdx} = struct(...
                    'Name', name, ...
                    'Path', dataset.Name, ...
                    'Type', 'dataset', ...
                    'Info', dataset ...
                );
                nodeIdx = nodeIdx + 1;
            end
            
            % Add attributes
            for i = 1:numAttributes
                attribute = info.Attributes(i);
                
                % Create node
                nodes{nodeIdx} = struct(...
                    'Name', ['@' attribute.Name], ...
                    'Path', [node.Path '#' attribute.Name], ...
                    'Type', 'attribute', ...
                    'Info', attribute ...
                );
                nodeIdx = nodeIdx + 1;
            end
        end
        
        function tf = hasChildren(~, node)
            % Check if a node has children
            % node: Node to check
            
            if strcmp(node.Type, 'group')
                % Groups have children if they contain groups, datasets, or attributes
                info = node.Info;
                tf = ~isempty(info.Groups) || ~isempty(info.Datasets) || ~isempty(info.Attributes);
            elseif strcmp(node.Type, 'dataset')
                % Datasets have children if they have attributes
                info = node.Info;
                tf = ~isempty(info.Attributes);
            else
                % Attributes don't have children
                tf = false;
            end
        end
        
        function data = getNodeData(obj, node)
            % Get data associated with a node
            % node: Node to get data for
            
            if strcmp(node.Type, 'dataset')
                % Read dataset data
                try
                    data = h5read(obj.FilePath, node.Path);
                catch ME
                    warning('Hdf5FileAdapter:ReadError', 'Error reading dataset: %s', ME.message);
                    data = [];
                end
            elseif strcmp(node.Type, 'attribute')
                % Get attribute value
                % Extract parent path and attribute name
                [parentPath, attrName] = strtok(node.Path, '#');
                attrName = attrName(2:end); % Remove the '#'
                
                % Find attribute in parent's attributes
                if strcmp(parentPath, '/')
                    % Root group
                    parentInfo = obj.FileInfo;
                else
                    % Get parent info
                    try
                        parentInfo = h5info(obj.FilePath, parentPath);
                    catch
                        warning('Hdf5FileAdapter:AttributeError', 'Error getting parent info for attribute');
                        data = [];
                        return;
                    end
                end
                
                % Find attribute
                attrIdx = find(strcmp({parentInfo.Attributes.Name}, attrName));
                if isempty(attrIdx)
                    warning('Hdf5FileAdapter:AttributeError', 'Attribute not found');
                    data = [];
                else
                    data = parentInfo.Attributes(attrIdx).Value;
                end
            else
                % Return info for groups
                data = node.Info;
            end
        end
        
        function close(obj)
            % Close the file and clean up resources
            
            obj.FileInfo = [];
            obj.FilePath = '';
        end
    end
end

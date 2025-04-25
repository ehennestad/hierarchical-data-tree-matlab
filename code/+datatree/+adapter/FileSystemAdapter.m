classdef FileSystemAdapter < datatree.adapter.ContentAdapter
    % FileSystemAdapter - Adapter for file system directories
    %
    %   This class implements the ContentAdapter interface for file system
    %   directories. It provides methods to browse the contents of a directory
    %   as a tree.
    %
    %   Example:
    %       adapter = datatree.adapter.FileSystemAdapter();
    %       adapter.open('/path/to/directory');
    %       rootNodes = adapter.getRoot();
    %
    %   See also ContentAdapter, FileContentTree
    
    properties
        RootPath % Root directory path
    end
    
    methods
        function obj = FileSystemAdapter()
            % Constructor
        end
        
        function open(obj, dirPath)
            % Open a directory
            % dirPath: Path to the directory
            
            if ~isfolder(dirPath)
                error('FileSystemAdapter:NotADirectory', 'Path is not a directory: %s', dirPath);
            end
            
            obj.RootPath = dirPath;
        end
        
        function nodes = getRoot(obj)
            % Get root node (the directory itself)
            
            if isempty(obj.RootPath)
                nodes = {};
                return;
            end
            
            % Get directory info
            dirInfo = dir(obj.RootPath);
            
            % Find the directory entry for the root directory itself
            rootIdx = find(strcmp({dirInfo.name}, '.'));
            if isempty(rootIdx)
                % If not found, create a dummy entry
                rootInfo = struct('name', '.', 'folder', fileparts(obj.RootPath), ...
                    'date', '', 'bytes', 0, 'isdir', true, 'datenum', datetime("now"));
            else
                rootInfo = dirInfo(rootIdx);
            end
            
            % Create root node
            [~, name] = fileparts(obj.RootPath);
            if isempty(name)
                % Handle root directory
                name = obj.RootPath;
            end
            
            rootNode = struct(...
                'Name', name, ...
                'Path', obj.RootPath, ...
                'Type', 'directory', ...
                'Info', rootInfo ...
            );
            
            nodes = {rootNode};
        end
        
        function nodes = getChildren(~, node)
            % Get children of a node
            % node: Parent node
            
            if ~strcmp(node.Type, 'directory')
                % Only directories have children
                nodes = {};
                return;
            end
            
            % List directory contents
            dirContents = dir(node.Path);
            
            % Remove '.' and '..'
            dirContents = dirContents(~ismember({dirContents.name}, {'.', '..'}));
            
            % Create nodes
            numItems = length(dirContents);
            nodes = cell(numItems, 1);
            
            for i = 1:numItems
                item = dirContents(i);
                
                % Determine type
                if item.isdir
                    type = 'directory';
                else
                    % Get file extension
                    [~, ~, ext] = fileparts(item.name);
                    if isempty(ext)
                        type = 'file';
                    else
                        type = lower(ext(2:end)); % Remove leading dot
                    end
                end
                
                % Create node
                nodes{i} = struct(...
                    'Name', item.name, ...
                    'Path', fullfile(node.Path, item.name), ...
                    'Type', type, ...
                    'Info', item ...
                );
            end
        end
        
        function tf = hasChildren(~, node)
            % Check if a node has children
            % node: Node to check
            
            % Only directories have children
            tf = strcmp(node.Type, 'directory');
            
            if tf
                % Check if directory is empty
                dirContents = dir(node.Path);
                
                % Remove '.' and '..'
                dirContents = dirContents(~ismember({dirContents.name}, {'.', '..'}));
                
                % Directory has children if it contains any files or subdirectories
                tf = ~isempty(dirContents);
            end
        end
        
        function data = getNodeData(~, node)
            % Get data associated with a node
            % node: Node to get data for
            
            % Return file/directory info
            data = node.Info;
        end
        
        function close(obj)
            % Close the directory and clean up resources
            
            obj.RootPath = '';
        end
    end
end

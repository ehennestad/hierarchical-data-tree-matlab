classdef TreeNodeProvider < handle
    % TreeNodeProvider - Model for tree-based content representation
    %
    %   This class manages the tree structure and interfaces with a ContentAdapter
    %   to provide data for a tree-based viewer.
    %
    %   Example:
    %       adapter = MatFileAdapter();
    %       model = TreeNodeProvider(adapter);
    %       model.Adapter.open('data.mat');
    %       rootNodes = model.getRoot();
    %
    %   See also ContentAdapter, FileContentTree
    
    properties
        Adapter % ContentAdapter instance
    end
    
    methods
        function obj = TreeNodeProvider(adapter)
            % Constructor
            % adapter: ContentAdapter instance (optional)
            if nargin > 0 && ~isempty(adapter)
                obj.Adapter = adapter;
            end
        end
        
        function nodes = getRoot(obj)
            % Get root nodes from adapter
            if isempty(obj.Adapter)
                error('TreeNodeProvider:NoAdapter', 'No adapter set');
            end
            nodes = obj.Adapter.getRoot();
        end
        
        function nodes = getChildren(obj, node)
            % Get children of a node from adapter
            if isempty(obj.Adapter)
                error('TreeNodeProvider:NoAdapter', 'No adapter set');
            end
            nodes = obj.Adapter.getChildren(node);
        end
        
        function tf = hasChildren(obj, node)
            % Check if a node has children
            if isempty(obj.Adapter)
                error('TreeNodeProvider:NoAdapter', 'No adapter set');
            end
            tf = obj.Adapter.hasChildren(node);
        end
        
        function data = getNodeData(obj, node)
            % Get data associated with a node
            if isempty(obj.Adapter)
                error('TreeNodeProvider:NoAdapter', 'No adapter set');
            end
            data = obj.Adapter.getNodeData(node);
        end
    end
end

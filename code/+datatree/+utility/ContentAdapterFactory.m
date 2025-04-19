classdef ContentAdapterFactory
    % ContentAdapterFactory - Factory for creating content adapters
    %
    %   This class provides methods to create the appropriate ContentAdapter
    %   instance based on the file type.
    %
    %   Example:
    %       adapter = ContentAdapterFactory.createAdapter('data.mat');
    %       adapter.open('data.mat');
    %       rootNodes = adapter.getRoot();
    %
    %   See also ContentAdapter, MatFileAdapter, Hdf5FileAdapter, FileSystemAdapter
    
    methods (Static)
        function adapter = createAdapter(filePath)
            % Create appropriate adapter based on file extension or type
            % filePath: Path to the file or directory
            
            % Check if path is a directory
            if isfolder(filePath)
                adapter = datatree.adapter.FileSystemAdapter();
                return;
            end
            
            % Get file extension
            [~, ~, ext] = fileparts(filePath);
            
            % Create adapter based on extension
            switch lower(ext)
                case '.mat'
                    adapter = datatree.adapter.MatFileAdapter();
                case {'.h5', '.hdf5', '.nwb'}
                    adapter = datatree.adapter.Hdf5FileAdapter();
                otherwise
                    error('ContentAdapterFactory:UnsupportedFileType', ...
                        'Unsupported file type: %s', ext);
            end
        end
        
        function adapters = listAvailableAdapters()
            % List all available adapters
            
            adapters = {
                'datatree.adapter.MatFileAdapter', ...
                'datatree.adapter.Hdf5FileAdapter', ...
                'datatree.adapter.FileSystemAdapter'
            };
        end
        
        function extensions = getSupportedExtensions()
            % Get list of supported file extensions
            
            extensions = {
                '.mat', ...  % MATLAB data files
                '.h5', ...   % HDF5 files
                '.hdf5', ... % HDF5 files
                '.nwb', ...  % Neurodata Without Borders files (HDF5-based)
                'folder'     % Directories
            };
        end
        
        function [adapter, filePath] = createAdapterFromDialog()
            % Create adapter by prompting user to select a file
            
            % Get supported extensions for file dialog
            extensions = ContentAdapterFactory.getSupportedExtensions();
            
            % Create filter spec for uigetfile
            filterSpec = {};
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
            
            % Show file dialog
            [fileName, filePath] = uigetfile(filterSpec, 'Select a file');
            
            % Check if user cancelled
            if isequal(fileName, 0)
                adapter = [];
                filePath = '';
                return;
            end
            
            % Create full file path
            filePath = fullfile(filePath, fileName);
            
            % Create adapter
            adapter = ContentAdapterFactory.createAdapter(filePath);
        end
    end
end

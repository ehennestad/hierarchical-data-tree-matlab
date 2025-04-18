function codecheckToolbox()
    installMatBox()
    projectRootDirectory = hdtreetools.projectdir();
    matbox.tasks.codecheckToolbox(projectRootDirectory)
end
function codecheckToolbox()
    installMatBox()
    projectRootDirectory = datatreetools.projectdir();
    matbox.tasks.codecheckToolbox(projectRootDirectory)
end
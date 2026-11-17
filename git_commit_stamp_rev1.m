function S=git_commit_stamp_rev1(folder)
%git_commit_stamp_rev1  Commit hash and tracked-file state of the code folder.
%
%   S=git_commit_stamp_rev1(folder) returns a struct with
%     .commit   full hash of HEAD, or "unknown" when git can't run
%     .dirty    true when a tracked file differs from HEAD (or git can't run)
%     .ok       true when git ran
%   FOLDER defaults to the folder that holds this file. Written so every run
%   log names the code that made it (review R5MET-3); the batch driver
%   refuses to start on a dirty or unknown state.
%
%   Built-ins considered: gitrepo (Mapping Toolbox; R2025b) reads a repository
%   but has no status call, and a shell call to git is what the batch driver
%   uses, so the two agree.

arguments
    folder (1,1) string = string(fileparts(mfilename('fullpath')))
end
S.commit="unknown";
S.dirty=true;
S.ok=false;
[status,out]=system(sprintf('cd "%s" && git rev-parse HEAD',folder));
if status~=0
    warning('shipgis:git','git rev-parse failed in %s; the run log will not name a commit.',folder);
    return
end
S.commit=string(strtrim(out));
[status,out]=system(sprintf('cd "%s" && git status --porcelain --untracked-files=no',folder));
if status~=0
    warning('shipgis:git','git status failed in %s.',folder);
    return
end
S.dirty=~isempty(strtrim(out));
S.ok=true;
end

panvimdoc.sh \
	--project-name 'pilot' \
	--input-file 'docs/pilot.md' \
	--vim-version 'NVIM v0.12.0' \
	--description 'Run your projects and files with powerful command placeholders' \
	--toc 'true' \
	--treesitter 'true'

nvim --headless -u NONE -c 'helptags doc' -c 'qa'

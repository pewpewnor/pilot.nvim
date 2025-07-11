# change the panvimdoc command with the correct path to the bash script
panvimdoc \
	--project-name pilot \
	--input-file ./docs/pilot.md \
	--toc true \
	--description "A code runner plugin for Neovim with placeholder support" \
	--dedup-subheadings true \
	--treesitter true \
	--demojify true \
	--ignore-rawblocks true \
	--doc-mapping true \
	--doc-mapping-project-name true \
	--shift-heading-level-by 0 \
	--increment-heading-level-by 0

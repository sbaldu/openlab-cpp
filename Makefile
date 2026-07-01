all:
	marp cpp.md --pdf

cpp:
	npx @marp-team/marp-cli -w -p --html cpp.md 

cuda:
	npx @marp-team/marp-cli -w -p --html cuda.md 
